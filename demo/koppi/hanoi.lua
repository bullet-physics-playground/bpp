--
-- Towers of Hanoi
--
-- A port of qthanoi (Jakob Flierl, 2000) to BPP.
--
-- WHAT CARRIED OVER: the iterative (explicit-stack, non-recursive) Hanoi
-- solver from HanoiDoc::makeMove() in qthanoi/hanoidoc.cpp -- the same
-- case_flag 1/2/3 state machine, SP-indexed shadow stack, and from/to/with
-- peg-swapping trick that lets the algorithm advance one moveStone() call
-- per invocation instead of recursing all the way to the next move.
--
-- WHAT CHANGED: qthanoi's HanoiView::paintMovingStone() flew each stone
-- along a single hand-rolled cubic Bezier (see hanoiview.cpp), computed
-- inline. Here it's a 3-phase path built from the shared demo/module/
-- bezier.lua module: a straight vertical bezier.Linear() rise up the
-- source peg, a bezier.Cubic() hop across the (shared) peg-top height,
-- then a straight vertical bezier.Linear() fall down the destination peg.
-- Keeping the rise/fall segments exactly vertical (fixed x/z) means a
-- stone never drifts sideways while still low enough to clip a peg's
-- side -- all horizontal motion happens strictly at peg-top height, clear
-- of every peg. Stones are rainbow-colored (colormaps' "hsv" map) hollow
-- cylinders pierced with a hole the size of the peg diameter, their outer
-- edge minkowski-rounded and given a classic POV-Ray "plastic" (phong
-- highlight, no reflection) finish, instead of the original's flat-shaded
-- solid placeholder quad. The whole tower stands, fixed, on a
-- wood-textured platform (a flat Cylinder, see woods.inc's T_Wood32)
-- that rests on a static pedestal ring -- a torus generated at load time
-- via OpenSCAD's rotate_extrude(), not loaded from a mesh file. Instead
-- of the scene spinning, the camera slowly orbits it (see rotateY() in
-- the postSim callback below). The camera is pseudo-orthogonal (parked
-- far away with a small matching FOV, see demo/basic/06-mesh.lua) and
-- frames the full scene.
--
-- Params:
--   numStones (3..16, default 5) -- number of disks. Changing it restarts
--   the puzzle immediately (same as pressing R).
--
-- Usage: bpp demo/koppi/hanoi.lua
--

local common    = require "common"
local bezier    = require "bezier"
local colormaps = require "colormaps"

common.setTiming(1 / 25, 10, 1 / 60)

-- Predefined POV-Ray wood texture (see /usr/share/povray-3.8/include/
-- woods.inc) used on the platform below.
v.pre_sdl = [[
#include "woods.inc"
]]

--------------------------------------------------------------------------
-- Dimensions. The platform and pedestal are sized once for MAX_STONES and
-- never rebuilt. The 3 pegs, like the stones, are rebuilt by setup(n) each
-- time numStones changes, their length matching the current tower height
-- instead of staying oversized for MAX_STONES.
--------------------------------------------------------------------------
local MIN_STONES = 3
local MAX_STONES = 16

local STONE_BASE_R = 0.45
local STONE_STEP_R = 0.15
local STONE_H      = 0.3

local function stoneRadius(id)
  return STONE_BASE_R + id * STONE_STEP_R
end

local MAX_STONE_R = stoneRadius(MAX_STONES - 1)

local PEG_R             = 0.15
local PEG_SPACING       = MAX_STONE_R * 2 + 0.8
local PEG_CLEARANCE     = 2.0  -- how far a peg pokes up above its tallest possible stack
local STONE_HOLE_MARGIN = 0.03 -- clearance so the hole doesn't touch the peg surface
local STONE_HOLE_R      = PEG_R + STONE_HOLE_MARGIN
local STONE_FILLET_R    = STONE_H * 0.35 -- outer-edge rounding radius

local function pegHeightFor(n)
  return n * STONE_H + PEG_CLEARANCE
end

local TORUS_TUBE_R  = 0.4
local TORUS_MAJOR_R = (PEG_SPACING + MAX_STONE_R) * 0.55

local PLATFORM_R = PEG_SPACING + MAX_STONE_R + 0.6
local PLATFORM_H = 0.5

local TORUS_Y    = TORUS_TUBE_R
local PLATFORM_Y = 2 * TORUS_TUBE_R + PLATFORM_H / 2
local BASE_Y     = 2 * TORUS_TUBE_R + PLATFORM_H -- top surface pegs/stones stand on

local pegX = { -PEG_SPACING, 0, PEG_SPACING }

local function slotWorldY(slot) -- slot is a 0-based stack height
  return BASE_Y + STONE_H / 2 + slot * STONE_H
end

--------------------------------------------------------------------------
-- Orientation. The scene itself is static -- rotateY() (see
-- common.rotateY()) is instead reused below to orbit the camera around
-- it, in the postSim callback near the bottom of this file.
--------------------------------------------------------------------------
local rotateY = common.rotateY

-- Rotates a Cylinder/OpenSCAD object's default local +Z axis to world +Y,
-- so it stands up with its axis vertical (see common.orientBetween).
local VERTICAL_ROT = common.orientBetween(btVector3(0, 0, 0), btVector3(0, 1, 0))

local function poseFlat(obj, localPos, extraSpin)
  local q = btQuaternion(btVector3(0, 1, 0), extraSpin or 0) * VERTICAL_ROT
  obj.trans = btTransform(q, localPos)
end

--------------------------------------------------------------------------
-- Static scenery: floor, pedestal torus (built via OpenSCAD, not a mesh
-- file), and the platform. The three pegs are built by setup() below,
-- since their length depends on numStones.
--------------------------------------------------------------------------
local floor = Plane(0, 1, 0, 0, PLATFORM_R * 2)
floor.col = "#1a1a1a"
v:add(floor)

local torus = OpenSCAD(string.format([[
rotate_extrude($fn = 96)
  translate([%.4f, 0])
    circle(r = %.4f, $fn = 48);
]], TORUS_MAJOR_R, TORUS_TUBE_R), 0, false)
torus.col = "#2b2b2b"
torus.trans = btTransform(VERTICAL_ROT, btVector3(0, TORUS_Y, 0))
v:add(torus)

local platform = Cylinder(PLATFORM_R, PLATFORM_H, 0)
platform.col = "#3a3a3a"
platform.sdl = [[
  texture { T_Wood16 scale 16 }
]]
v:add(platform)

local pegs    = {} -- pegs[1..3] = <Cylinder>, rebuilt by setup()
local pegY    = 0  -- current peg center height (local), set by setup()
local pegTopY = 0  -- current peg top height (local), set by setup()

-- A stone is a cylinder with a hole through its center (built via OpenSCAD,
-- like the torus), sized so it could slide over a peg -- STONE_HOLE_R
-- matches the peg diameter (PEG_R radius) plus a small clearance margin.
-- Its outer edge is rounded off by STONE_FILLET_R: minkowski-summing a
-- smaller core cylinder with a sphere blows the core back out to the
-- full (outerR, STONE_H) footprint, but with the corner where the flat
-- top/bottom meets the side now a smooth fillet instead of a sharp edge.
local function stoneMesh(id)
  local outerR = stoneRadius(id)
  local coreR  = outerR - STONE_FILLET_R
  local coreH  = STONE_H - 2 * STONE_FILLET_R
  return OpenSCAD(string.format([[
difference() {
  minkowski() {
    cylinder(r = %.4f, h = %.4f, center = true, $fn = 64);
    sphere(r = %.4f, $fn = 16);
  }
  cylinder(r = %.4f, h = %.4f, center = true, $fn = 32);
}
]], coreR, coreH, STONE_FILLET_R, STONE_HOLE_R, STONE_H + 0.2), 0, false)
end

-- Classic POV-Ray "plastic" look for a stone: its rainbow pigment plus a
-- phong highlight -- POV-Ray's own docs describe phong specifically as
-- simulating a plastic-like surface, as opposed to specular/reflection
-- (metal) or an ior (glass). A non-empty .sdl replaces the object's
-- default pigment-from-.col entirely (see Object::toPOV in object.cpp),
-- so the matching rgb is embedded here directly rather than relying on
-- .col to show through.
local function stoneTexture(r, g, b)
  return string.format([[
  texture {
    pigment { color rgb <%.4f, %.4f, %.4f> }
    finish {
      phong 0.9
      phong_size 60
      ambient 0.15
      diffuse 0.6
    }
  }
]], r, g, b)
end

v:addParam("numStones", 5, MIN_STONES, MAX_STONES, 1,
  "number of disks on the tower (press R to rebuild)")

--------------------------------------------------------------------------
-- Hanoi algorithm state -- reset by setup() below.
--------------------------------------------------------------------------
local stones = {}       -- stones[id] = { obj = <Cylinder> }, id 0 (smallest) .. n-1 (largest)
local tower  = { {}, {}, {} } -- tower[peg] = { id, id, ... } bottom .. top

local height, from, with, to, moves
local SP, case_flag, done
local heightStack, fromStack, toStack, withStack, returnAddr

local animating = false
local solved    = false
local flight    = nil

local ANIM_FRAMES = 20 -- simulation steps a single stone flight takes

-- Flight is split into three phases so all horizontal motion happens
-- strictly at/above the (shared) peg-top height -- a stone never moves
-- sideways while it's still low enough to clip a peg's side.
local UP_FRAC, ACROSS_FRAC, DOWN_FRAC = 0.28, 0.44, 0.28

-- Builds the flight path for the stone now leaving pegFrom for pegTo:
-- a straight vertical rise up its own peg (bezier.Linear -- x/z fixed, so
-- it can't drift into the peg), a cubic Bezier hop across the peg tops
-- (see demo/module/bezier.lua), then a straight vertical fall down the
-- destination peg.
local function beginFlight(id, pegFrom, pegTo, fromSlot, toSlot)
  local pStart   = { x = pegX[pegFrom], y = slotWorldY(fromSlot), z = 0 }
  local pTopFrom = { x = pegX[pegFrom], y = pegTopY,              z = 0 }
  local pTopTo   = { x = pegX[pegTo],   y = pegTopY,              z = 0 }
  local pEnd     = { x = pegX[pegTo],   y = slotWorldY(toSlot),   z = 0 }

  local bulgeY   = pegTopY + STONE_H * 2
  local acrossP1 = { x = pTopFrom.x + (pTopTo.x - pTopFrom.x) / 3, y = bulgeY, z = 0 }
  local acrossP2 = { x = pTopFrom.x + (pTopTo.x - pTopFrom.x) * 2 / 3, y = bulgeY, z = 0 }

  flight = {
    id     = id,
    up     = bezier.Linear(pStart, pTopFrom),
    across = bezier.Cubic(pTopFrom, acrossP1, acrossP2, pTopTo),
    down   = bezier.Linear(pTopTo, pEnd),
    dir    = (pegFrom < pegTo) and 1 or -1,
    frame  = 0,
  }
  animating = true
end

local function advanceFlight()
  flight.frame = flight.frame + 1
  local blend = math.min(flight.frame / ANIM_FRAMES, 1)

  local p, spin
  if blend < UP_FRAC then
    p = flight.up:eval(blend / UP_FRAC)
    spin = 0
  elseif blend < UP_FRAC + ACROSS_FRAC then
    local at = (blend - UP_FRAC) / ACROSS_FRAC
    p = flight.across:eval(at)
    spin = flight.dir * at * math.pi -- half a turn while airborne over the gap
  else
    local dt = (blend - UP_FRAC - ACROSS_FRAC) / DOWN_FRAC
    p = flight.down:eval(dt)
    spin = flight.dir * math.pi
  end

  poseFlat(stones[flight.id].obj, btVector3(p.x, p.y, p.z), spin)
  if blend >= 1 then
    animating = false
    flight = nil
  end
end

-- Mirrors HanoiDoc::moveStone(): pop the top of pegFrom, push it onto
-- pegTo, then kick off its flight.
local function performMove(pegFrom, pegTo)
  local id = table.remove(tower[pegFrom])
  table.insert(tower[pegTo], id)
  moves = moves + 1

  local fromSlot = #tower[pegFrom]
  local toSlot   = #tower[pegTo] - 1

  beginFlight(id, pegFrom, pegTo, fromSlot, toSlot)
end

-- Direct port of HanoiDoc::makeMove() (hanoidoc.cpp): the iterative
-- (explicit-stack) rewrite of the recursive Hanoi solver
--   hanoi(h,from,to,with): if h>0 then hanoi(h-1,from,with,to); moveStone(from,to); hanoi(h-1,with,to,from)
-- case 1 is the descent into "hanoi(h-1,from,with,to)", case 2 performs the
-- move and descends into the mirrored call, case 3 unwinds the shadow
-- stack until either another case-2 move is due or the stack is empty.
local function makeMove()
  local moved = false
  repeat
    if case_flag == 1 then
      while height > 0 do
        SP = SP + 1
        heightStack[SP] = height
        fromStack[SP]   = from
        toStack[SP]     = to
        withStack[SP]   = with
        returnAddr[SP]  = 2
        height = height - 1
        to, with = with, to
      end
      case_flag = 3
    elseif case_flag == 2 then
      performMove(from, to)
      SP = SP + 1
      heightStack[SP] = height
      fromStack[SP]   = from
      toStack[SP]     = to
      withStack[SP]   = with
      returnAddr[SP]  = 3
      height = height - 1
      from, with = with, from
      case_flag = 1
      moved = true
    elseif case_flag == 3 then
      if SP >= 0 then
        while SP >= 0 and case_flag == 3 do
          height    = heightStack[SP]
          from      = fromStack[SP]
          to        = toStack[SP]
          with      = withStack[SP]
          case_flag = returnAddr[SP]
          SP = SP - 1
        end
      else
        done = not done
      end
    end
  until moved or done

  if not moved and not solved then
    solved = true
    print(string.format("hanoi: solved in %d moves", moves))
  end
end

local function updateRestingStonePoses()
  for p = 1, 3 do
    for slot = 1, #tower[p] do
      local id = tower[p][slot]
      if not (animating and flight.id == id) then
        poseFlat(stones[id].obj, btVector3(pegX[p], slotWorldY(slot - 1), 0), 0)
      end
    end
  end
end

local function updatePegsAndPlatform()
  poseFlat(platform, btVector3(0, PLATFORM_Y, 0), 0)
  for p = 1, 3 do
    poseFlat(pegs[p], btVector3(pegX[p], pegY, 0), 0)
  end
end

-- (Re)builds the pegs and stones and resets the solver -- the "Setup"
-- step, same role as qthanoi's -n command-line option / HanoiDoc's
-- constructor. Peg length is recomputed here too, so it always matches
-- the tallest possible stack for the current numStones.
local function setup(n)
  for _, s in pairs(stones) do v:remove(s.obj) end
  stones = {}
  tower = { {}, {}, {} }

  for id = n - 1, 0, -1 do
    local obj = stoneMesh(id)
    local t = id / (n - 1)
    obj.col = colormaps.sample_hex("hsv", t)
    obj.sdl = stoneTexture(colormaps.sample("hsv", t))
    v:add(obj)
    stones[id] = { obj = obj }
    table.insert(tower[1], id)
  end

  for _, peg in ipairs(pegs) do v:remove(peg) end
  pegs = {}
  local pegHeight = pegHeightFor(n)
  pegY    = BASE_Y + pegHeight / 2
  pegTopY = BASE_Y + pegHeight
  for p = 1, 3 do
    local peg = Cylinder(PEG_R, pegHeight, 0)
    peg.col = "#c0c0c0"
    v:add(peg)
    pegs[p] = peg
  end

  height, from, with, to, moves = n, 1, 3, 2, 0
  SP, case_flag, done = -1, 1, false
  heightStack, fromStack, toStack, withStack, returnAddr = {}, {}, {}, {}, {}
  animating, flight, solved = false, nil, false

  updateRestingStonePoses()
  updatePegsAndPlatform()
  print(string.format("hanoi: %d stones, peg 1 -> peg 2 (via peg 3)", n))
end

setup(math.floor(v:getParam("numStones")))

v:addShortcut("R", function(N)
  setup(math.floor(v:getParam("numStones")))
end)

-- Changing numStones restarts the puzzle immediately, same as pressing R.
v:onParamChanged(function(N, name, value)
  if name == "numStones" then
    setup(math.floor(value))
  end
end)

-- Pseudo-orthogonal camera (see demo/basic/06-mesh.lua and
-- demo/koppi/gears.lua): parked far enough away that perspective
-- distortion flattens out into a near-parallel projection.
--
-- setHorizontalFieldOfView() fixes the horizontal FOV exactly, but
-- QGLViewer then derives the vertical FOV as 2*atan(tan(hfov/2)/aspect) --
-- on a wide (landscape) viewport that's *smaller* than hfov, so sizing the
-- FOV from the platform's horizontal radius alone can clip the tops of
-- tall pegs even though the platform itself is framed. Lua has no way to
-- read the live viewport aspect ratio, so instead: aim the camera at the
-- vertical midpoint of the whole scene (floor to peg top, so the required
-- vertical half-angle is minimized and symmetric), and pick whichever of
-- the horizontal or vertical requirement is larger -- the vertical one
-- pre-inflated by CAMERA_MAX_ASPECT, the widest viewport shape this still
-- has to hold up under -- as the horizontal FOV to request.
local CAMERA_PEG_HEIGHT = pegHeightFor(MAX_STONES) -- tallest possible peg, so framing doesn't jump on rebuild
local CAMERA_MAX_ASPECT = 2.0 -- guards against ultrawide (up to ~2:1) viewports
local SCENE_R     = PLATFORM_R * 1.5 -- platform radius plus a little margin
local SCENE_TOP_Y = BASE_Y + CAMERA_PEG_HEIGHT + STONE_H * 2 -- + in-flight bulge margin
local SCENE_LOOK_Y = SCENE_TOP_Y / 2 - 3-- vertical midpoint of the whole scene, floor to peg top

local camPos   = btVector3(SCENE_R * 9, SCENE_R * 11, SCENE_R * 9)
local camDist  = math.sqrt(camPos.x ^ 2 + camPos.y ^ 2 + camPos.z ^ 2)
local camNeed  = math.max(SCENE_R, SCENE_LOOK_Y * CAMERA_MAX_ASPECT)
local camFov   = 2 * math.atan(camNeed / camDist)
local camLook  = btVector3(0, SCENE_LOOK_Y, 0)

common.setCamera(
  camPos,
  camLook,
  camFov,
  { horizontal = true, noMove = false }
)

-- The scene itself never moves; instead the camera orbits around it each
-- step (rotateY() on the original camPos, about the scene's own vertical
-- axis) at a fixed distance/height, so framing (camFov above) stays valid
-- at every point on the orbit. .look and .up are reassigned every step
-- too -- Cam:setLookAt() just orients the camera once at assignment time
-- (see Cam::setLookAt in cam.cpp), it doesn't keep tracking a point (or
-- an upright orientation) on its own, so both have to be pinned again
-- each time .pos moves, or the view would drift/roll off-center.
local CAMERA_ORBIT_SPEED = 0.005 -- radians the camera orbits per simulation step
local cameraAngle = 0

v:postSim(function(N)
  if animating then
    advanceFlight()
  elseif not solved then
    makeMove()
  end

  updateRestingStonePoses()
  updatePegsAndPlatform()

  cameraAngle = cameraAngle + CAMERA_ORBIT_SPEED

common.setCamera(
  rotateY(camPos, cameraAngle), camLook, camFov, { horizontal = true, noMove = false } )
end)

-- EOF
