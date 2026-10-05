--
-- PINBALL MACHINE A -- a playable pinball table in the style of Williams'
-- 1983 "Time Fantasy": Bullet physics for the ball, flippers, bumpers and
-- slingshots; a small rules engine for the game; a seven-segment scoreboard
-- in the backbox; and hooks for sound effects.
--
-- FILES
--   pinball-machine-a.lua          this table
--   pinball-machine-a-rules.lua    the game rules: points, target banks, bonus,
--                             extra balls, which sound file plays when.
--                             Edit it and press R to reload.
--   pinball-machine-a-sounds/      put sound files here (names are listed in the
--                             rules file); missing ones are simply skipped
--
-- THE LAYOUT is an approximation: no drawing of the real playfield was
-- available, so it was built from the machine's switch list -- five top
-- rollover lanes, three pop bumpers, the seven F-A-N-T-A-S-Y targets, six
-- 10-point standups, a ramp target, a left orbit, two slingshots,
-- inlanes/outlanes and two flippers -- and most of it can be adjusted.
-- A ramp was added later (the real machine has none).
--
-- LAYOUT EDITOR: until the first ball is launched you can move parts of
-- the table. The Shortcuts pane lists the keys and the current positions:
--   L                select the rollover lanes (as a group)
--   1 / 2 / 3 ...    select pop bumper 1 (left), 2 (right), 3 (bottom), or
--                    one you added
--   B                add a pop bumper (numbered 4, 5, ...; up to 9 in all)
--   Delete           remove the selected added bumper
--   A                select the top arch: Up/Down raise or lower its top
--                    (the rollover lanes come with it), Left/Right shift
--                    its flat top section sideways (one corner tightens as
--                    the other widens). The shooter lane gate and the top
--                    of the orbit wall follow it.
--   O                select the orbit entrance: the inner orbit wall, its
--                    entrance post and the four targets on it
--   X                select the orbit exit: the lower end of the angled
--                    wall at the bottom of the orbit. Over the outlane,
--                    balls coming down the orbit drain; over the inlane,
--                    they come back to the flipper.
--   F                select the flippers, inlane guides and slingshots,
--                    which move together
--   M                select the ramp: the arrows move its entrance, and
--                    , and . turn it (the rest of it follows)
--   arrow keys       move the selection: a tap moves 0.5 cm; holding one
--                    slides it, speeding up the longer it's held
--   0                put the selection back where it is in the default layout
--   R                reset the whole layout to the default (a saved layout
--                    is kept until editing ends; reload to get it back)
--   E                finish editing and save (launching the ball also does)
-- A move that would make parts collide or trap the ball is refused, and
-- the Shortcuts pane says why. The layout is saved in bpp's settings and
-- restored the next time the table is run.
--
-- PLAY KEYS (click the 3D view first so it has keyboard focus):
--   Return           hold to draw the plunger back, release to launch
--                    (launching with no game running starts one)
--   Left/Right Shift flippers (also Z and / )
--   Space            shake (nudge) the machine -- too often and it tilts
--   1                start a new game (when no game is running)
--   P                the computer plays, learning as it goes (see
--                    pinball-machine-a-ai.lua); P again to stop
--   V                the view: the player's, or the whole machine
--
-- UNITS: centimetres, seconds, kilograms. The playfield lies flat in the
-- world's X-Z plane and gravity is tilted 6.5 degrees toward the player
-- instead of tilting the geometry. Layout is written in table coordinates
-- (u = right, w = up the table, 0 at the player's end) and mapped to world
-- (x = u, z = -w) by P() below.
--
-- Needs the v:onKey() keyboard hook added to bpp alongside this table.
--

local common = require "common"

-- ---------------------------------------------------------------------
-- rules
-- ---------------------------------------------------------------------

local RULES_FILE = "pinball-machine-a-rules.lua"
local SOUND_DIR = "pinball-machine-a-sounds/"

local rules
do
  local ok, r = pcall(dofile, RULES_FILE)
  if ok and type(r) == "table" then
    rules = r
  else
    print("Could not load " .. RULES_FILE .. " (" .. tostring(r) ..
          ") -- playing without scoring rules")
    rules = {}
  end
  rules.points = rules.points or {}
  rules.banks = rules.banks or {}
  rules.sounds = rules.sounds or {}
  rules.multiplier = rules.multiplier or { max = 5 }
  rules.ballsPerGame = rules.ballsPerGame or 3
  -- (for rules files written before the machine could be shaken)
  if rules.ramp == nil then rules.ramp = { switch = "rampMade", start = 5000, step = 5000, max = 25000 } end
  rules.tilt = rules.tilt or {}
  rules.tilt.nudge = rules.tilt.nudge or 35       -- cm/s the ball gets, up the table
  if rules.tilt.warnings == nil then rules.tilt.warnings = 2 end   -- per ball, before a tilt
  rules.tilt.sway = rules.tilt.sway or 2.5        -- the tilt bob swings this far (shoves)...
  rules.tilt.settle = rules.tilt.settle or 1.0    -- ...and settles this much a second
  for event, file in pairs({ nudge = "nudge.wav", tiltWarning = "tilt_warning.wav", tilt = "tilt.wav",
                              ramp = "ramp_enter.wav", rampMade = "ramp_made.wav" }) do
    if rules.sounds[event] == nil then rules.sounds[event] = file end
  end
end

-- ---------------------------------------------------------------------
-- settings
-- ---------------------------------------------------------------------

local G, SLOPE = 981, math.rad(6.5)
local FRAME = 1 / 60

local BALL_R, BALL_MASS = 1.35, 0.08
local TABLE_W, TABLE_L = 51, 107
local WALL_H = 3.4                   -- just clears the glass
local GLASS_Y = 2 * BALL_R + 0.25    -- underside of the glass

local FLIP_LEN, FLIP_THICK, FLIP_H, FLIP_MASS = 7.6, 1.6, 2.2, 0.12
local FLIP_REST = math.rad(30)       -- below horizontal at rest
local FLIP_STROKE = math.rad(58)
local FLIP_UP_VEL, FLIP_UP_IMPULSE = 85, 60
local FLIP_DN_VEL, FLIP_DN_IMPULSE = 25, 12

local BUMPER_R, BUMPER_KICK = 2.6, 180
local SLING_KICK = 160
local PLUNGER_MIN, PLUNGER_MAX, PLUNGER_PULL_TIME = 120, 520, 1.0

local SWITCH_HOLD_FRAMES = 4         -- a switch can't re-trigger within this
local SERVE_DELAY = 90               -- frames from a drain to the next ball
local BALL_SEARCH_FRAMES = 300       -- a ball still this long gets nudged free

-- ---------------------------------------------------------------------
-- world
-- ---------------------------------------------------------------------

v.timeStep = FRAME
v.fixedTimeStep = 1 / 600
v.maxSubSteps = 12
v.gravity = btVector3(0, -G * math.cos(SLOPE), G * math.sin(SLOPE))
if v.animationPeriod then v.animationPeriod = 16 end

local function P(u, w, y) return btVector3(u, y or 0, -w) end

local yAxis = btVector3(0, 1, 0)
local function yRot(angle) return btQuaternion(yAxis, angle) end
local UPRIGHT = btQuaternion(btVector3(1, 0, 0), math.pi / 2)  -- cylinder axis vertical

local L, R = -TABLE_W / 2, TABLE_W / 2   -- -25.5 .. 25.5
local LANE_IN = 21.2                      -- shooter-lane inner wall (centre)

-- While `collect` is set to a list, the builders below also append each
-- part they make to it ({obj, q, u, w, y}), so the layout editor can move
-- a whole group of parts later.
local collect = nil
local function collectPart(obj, q, u, w, y, isLamp)
  if collect then
    collect[#collect + 1] = { obj = obj, q = q, u = u, w = w, y = y, col0 = obj.col,
                              isLamp = isLamp }
  end
end

-- Remove every part in a list (for things rebuilt when the layout changes).
local function removeParts(list)
  for _, part in ipairs(list) do v:remove(part.obj) end
end

-- A static wall along the segment (u1,w1)-(u2,w2).
local function wall(u1, w1, u2, w2, opts)
  opts = opts or {}
  local du, dw = u2 - u1, w2 - w1
  local len = math.sqrt(du * du + dw * dw)
  local h = opts.h or WALL_H
  local c = Cube(len + (opts.thick or 0.6), h, opts.thick or 0.6, 0)
  local q = yRot(math.atan2(dw, du))
  c.trans = btTransform(q, P((u1 + u2) / 2, (w1 + w2) / 2, h / 2))
  c.col = opts.col or "#6b4f3a"
  c.friction = 0.3
  c.restitution = opts.restitution or 0.55
  v:add(c)
  collectPart(c, q, (u1 + u2) / 2, (w1 + w2) / 2, h / 2)
  return c
end

-- A chain of walls through a list of {u, w} points.
local function wallPath(pts, opts)
  for i = 1, #pts - 1 do
    wall(pts[i][1], pts[i][2], pts[i + 1][1], pts[i + 1][2], opts)
  end
end

-- Points along a circular arc (angles in degrees, table coordinates).
local function arc(cu, cw, r, a1, a2, n)
  local pts = {}
  for i = 0, n do
    local a = math.rad(a1 + (a2 - a1) * i / n)
    pts[#pts + 1] = { cu + r * math.cos(a), cw + r * math.sin(a) }
  end
  return pts
end

local function post(u, w, r, col)
  local c = Cylinder(r, WALL_H, 0)
  c.trans = btTransform(UPRIGHT, P(u, w, WALL_H / 2))
  c.col = col or "#d8d0c0"
  c.restitution = 0.6
  v:add(c)
  collectPart(c, UPRIGHT, u, w, WALL_H / 2)
  return c
end

-- A lamp insert: a flat disc in the playfield the ball rolls over (it has
-- no collision response). lamp.set(on) lights it.
local CF_NO_CONTACT_RESPONSE = 4
local function lamp(u, w, onCol, offCol, r)
  local c = Cylinder(r or 0.75, 0.12, 0)
  c.trans = btTransform(UPRIGHT, P(u, w, 0.02))
  c.col = offCol
  v:add(c)
  c.body:setCollisionFlags(c.body:getCollisionFlags() + CF_NO_CONTACT_RESPONSE)
  collectPart(c, UPRIGHT, u, w, 0.02, true)
  local lp = { obj = c, on = false }
  lp.set = function(on)
    if on ~= lp.on then
      c.col = on and onCol or offCol
      lp.on = on
    end
  end
  return lp
end

local LAMP_COLS = {
  letter = { "#ff9f1c", "#3d2a12" },
  lane = { "#ffe066", "#3a3413" },
  mult = { "#ffffff", "#2b2b2b" },
  red = { "#ff3b3b", "#3a1414" },
}

-- playfield and glass. The playfield runs from w = -9 to PF_TOP, leaving
-- room above the arch (top at w = 108) for the layout editor to raise it.
local PF_TOP = 117
local PF_BOTTOM = -16            -- the playfield's front edge (room for the plunger)
local floor = Cube(TABLE_W + 1, 2, PF_TOP - PF_BOTTOM, 0)
floor.pos = P(0, (PF_TOP + PF_BOTTOM) / 2, -1)
floor.col = "#1d3557"
floor.friction = 0.2
floor.restitution = 0.2
v:add(floor)

local glass = Cube(TABLE_W + 1, 0.4, PF_TOP - PF_BOTTOM, 0)
glass.pos = P(0, (PF_TOP + PF_BOTTOM) / 2, GLASS_Y + 0.2)
glass.col = "#ffffff"
glass.transparency = 0.95
glass.pov_export = false
v:add(glass)

-- ---------------------------------------------------------------------
-- switches: every switch is a segment or a circle in table coordinates,
-- tested against the ball's path over the last frame (so a fast ball can't
-- skip one between frames). Each has a name (used by the rules file) and a
-- sound category.
-- ---------------------------------------------------------------------

local switches = {}      -- list of switch records
local switchByName = {}

local function addSwitch(s)
  switches[#switches + 1] = s
  switchByName[s.name] = s
  return s
end

local function lineSwitch(name, cat, u1, w1, u2, w2)
  return addSwitch({ name = name, cat = cat, kind = "line", a = { u1, w1 }, b = { u2, w2 } })
end

local function faceSwitch(name, cat, u1, w1, u2, w2, reach)
  return addSwitch({ name = name, cat = cat, kind = "face", a = { u1, w1 }, b = { u2, w2 },
                     reach = reach or (BALL_R + 0.45) })
end

local function circleSwitch(name, cat, u, w, r)
  return addSwitch({ name = name, cat = cat, kind = "circle", c = { u, w }, r = r })
end

-- A standup target: a static block whose front face is a switch. With
-- `rec` it rebuilds an existing target (same switch) at a new place.
-- `lampCols` puts a lamp on the playfield in front of it.
local function standup(name, u, w, facing, col, depth, lampCols, rec)
  local width = 3.0
  depth = depth or 0.8
  local nu, nw = math.cos(math.rad(facing)), math.sin(math.rad(facing))
  local tu, tw = -nw, nu
  if rec and rec.obj then v:remove(rec.obj) end
  local c = Cube(width, 3.2, depth, 0)
  local q = yRot(math.atan2(tw, tu))
  c.trans = btTransform(q, P(u, w, 1.6))
  c.col = col or "#f4d35e"
  c.restitution = 0.35
  v:add(c)
  collectPart(c, q, u, w, 1.6)
  local fu, fw = u + nu * depth / 2, w + nw * depth / 2
  local a = { fu - tu * width / 2, fw - tw * width / 2 }
  local b = { fu + tu * width / 2, fw + tw * width / 2 }
  if rec then
    rec.a, rec.b = a, b
  else
    rec = faceSwitch(name, "target", a[1], a[2], b[1], b[2])
  end
  rec.obj = c
  if lampCols then
    rec.lamp = lamp(u + nu * 2.6, w + nw * 2.6, lampCols[1], lampCols[2])
  end
  return rec
end

-- Everything the layout editor can move is an "item": parts, the switches
-- that go with them, and an offset (du, dw). See the LAYOUT EDITOR section.
local editItems = {}

-- ---------------------------------------------------------------------
-- the top arch, shooter lane and orbit wall top
-- ---------------------------------------------------------------------

-- The top arch sweeps a plunged ball from the shooter lane leftward across
-- the top of the table and on round into the left orbit. Its shape comes
-- from the arch item's offset: dw raises or lowers the top (from w = 108),
-- and du shifts the flat top section sideways, so the right corner's
-- radius becomes 16 - du and the left corner's 16 + du. The side walls run
-- up to where the corners begin. Its pieces change length as it's
-- reshaped, so it's rebuilt each time -- and it takes the shooter lane's
-- inner wall and gate (which must stay below the right corner) and the
-- orbit wall's top (below the left corner) with it.
local ARCH_H0, ARCH_R0 = 108, 16
local GATE_W0 = 86               -- the gate's low end, when the arch allows
local ORBIT_TOP0 = 86            -- the inner orbit wall's top, likewise
local ORBIT_TOP_MIN = 84         -- ...but never below the targets on it
local arch = { key = "arch", label = "top arch", parts = {}, switches = {}, du = 0, dw = 0 }
local orbit = { key = "orbit", label = "orbit entrance", parts = {}, switches = {},
                du = 0, dw = 0 }
local orbitTop = { parts = {} }  -- the orbit wall's upper section (rebuilt)

local function archShapeFor(du, dw)
  return ARCH_H0 + dw, ARCH_R0 + du, ARCH_R0 - du   -- top, left radius, right radius
end
local function archShape() return archShapeFor(arch.du, arch.dw) end

-- The height of the arch's inner face above u.
local function archUndersideFor(u, du, dw)
  local H, rL, rR = archShapeFor(du, dw)
  if u > R - rR then
    local d = math.min(u - (R - rR), rR)
    return H - rR + math.sqrt(rR * rR - d * d) - 0.3
  elseif u < L + rL then
    local d = math.min((L + rL) - u, rL)
    return H - rL + math.sqrt(rL * rL - d * d) - 0.3
  end
  return H - 0.3
end

local function gateWFor(du, dw)
  local H, rL, rR = archShapeFor(du, dw)
  return math.min(GATE_W0, H - rR - 6)
end

-- shooter lane: the ball rests on the plunger's tip, whose face is at
-- w = -5.7; the lane runs on down to w = -13 so the plunger can draw back
local LANE_BOTTOM = -13
wall(LANE_IN, LANE_BOTTOM, R, LANE_BOTTOM)   -- back of the plunger housing
local SHOOT_U, SHOOT_W = (LANE_IN + R) / 2, -6 + BALL_R + 0.4

-- One-way gate across the top of the shooter lane: a flap hinged along its
-- top edge that a rising ball swings open. It crosses the lane at an angle,
-- low end at the inner wall, so a ball falling back onto the closed flap
-- rolls off it into the playfield instead of resting there. mountGate()
-- puts it (on a new hinge) with its low end at w = gw.
local GATE_OPEN = math.rad(85)
local GATE_H = GLASS_Y - 0.3
local gate = { hinge = nil }
do
  local len = math.sqrt((R - 0.3 - (LANE_IN + 0.3)) ^ 2 + 3.5 ^ 2)
  -- 0.9 short of the gap so its corners clear both walls as it swings
  gate.obj = Cube(len - 0.9, GATE_H, 0.3, 0.01)
  gate.obj.col = "#c0c0c0"
  v:add(gate.obj)
  gate.obj.body:setActivationState(4)   -- DISABLE_DEACTIVATION
end
local function mountGate(gw)
  local gIn, gOut = { LANE_IN + 0.3, gw }, { R - 0.3, gw + 3.5 }
  if gate.hinge then v:removeConstraint(gate.hinge) end
  gate.obj.trans = btTransform(yRot(math.atan2(gOut[2] - gIn[2], gOut[1] - gIn[1])),
                               P((gIn[1] + gOut[1]) / 2, (gIn[2] + gOut[2]) / 2, GATE_H / 2 + 0.1))
  gate.obj.vel = btVector3(0, 0, 0)
  gate.obj.body:setAngularVelocity(btVector3(0, 0, 0))
  local hinge = btHingeConstraint(gate.obj.body, btVector3(0, GATE_H / 2, 0), btVector3(1, 0, 0))
  -- a one-body hinge's zero angle depends on the body's orientation, so
  -- limit relative to wherever this one reads at rest
  local a0 = hinge:getHingeAngle()
  hinge:setLimit(a0, a0 + GATE_OPEN, 0.9, 0.3, 1.0)
  v:addConstraint(hinge)
  gate.hinge = hinge
end

-- The inner orbit wall's upper section: from the orbit item's angled
-- entrance piece up to ORBIT_TOP0, or less if the arch's left corner
-- comes lower.
local function buildOrbitTop()
  removeParts(orbitTop.parts)
  orbitTop.parts = {}
  local H, rL = archShape()
  local u = -21.5 + orbit.du
  local top = math.min(ORBIT_TOP0 + orbit.dw, H - rL - 1.5)
  collect = orbitTop.parts
  wall(u, 58 + orbit.dw, u, top)
  collect = nil
  orbitTop.built = true
end

local function buildArch()
  removeParts(arch.parts)
  arch.parts = {}
  local H, rL, rR = archShape()
  local gw = gateWFor(arch.du, arch.dw)
  collect = arch.parts
  wall(R, LANE_BOTTOM, R, H - rR)           -- right side: shooter lane outer wall
  wallPath(arc(R - rR, H - rR, rR, 0, 90, 8))
  if (R - rR) - (L + rL) > 0.05 then wall(R - rR, H, L + rL, H) end
  wallPath(arc(L + rL, H - rL, rL, 90, 180, 8))
  wall(L, H - rL, L, 44)                    -- left side: orbit outer wall
  wall(LANE_IN, LANE_BOTTOM, LANE_IN, gw)   -- shooter lane inner wall
  collect = nil
  mountGate(gw)
  -- the switch that sees a ball go over the top, at the flat section's left end
  local su = L + rL
  if arch.topSwitch then
    arch.topSwitch.a, arch.topSwitch.b = { su, H - 8 }, { su, H }
  else
    arch.topSwitch = lineSwitch("topLoop", "rollover", su, H - 8, su, H)
  end
  buildOrbitTop()
  arch.built = true
end
buildArch()
editItems.arch = arch

-- ---------------------------------------------------------------------
-- top rollover lanes 1-5
-- ---------------------------------------------------------------------

-- LANE_W0 is where the lanes start. Measured with the plunger at every
-- strength: with the lanes' tops 3-5 cm below the arch a plunged ball
-- riding the arch drops into a lane; any lower and it rides on round into
-- the left orbit, any higher and it bounces off the lane posts.
local LANE_W0 = 95.5
local laneEdges = { -17.0, -12.2, -7.4, -2.6, 2.2, 7.0 }
local lanes = { key = "lanes", label = "rollover lanes", parts = {}, switches = {},
                umin = laneEdges[1] - 0.5, umax = laneEdges[#laneEdges] + 0.5,
                wmin = LANE_W0, wmax = LANE_W0 + 8.5 }
collect = lanes.parts
for _, u in ipairs(laneEdges) do
  wall(u, LANE_W0, u, LANE_W0 + 8, { thick = 0.5, col = "#d8d0c0" })
  post(u, LANE_W0 + 8, 0.5)
end
for i = 1, 5 do
  local s = lineSwitch("top" .. i, "rollover", laneEdges[i], LANE_W0 + 3, laneEdges[i + 1], LANE_W0 + 3)
  s.lamp = lamp((laneEdges[i] + laneEdges[i + 1]) / 2, LANE_W0 + 1.2, LAMP_COLS.lane[1], LAMP_COLS.lane[2])
  lanes.switches[i] = s
end
collect = nil
editItems.lanes = lanes

-- ---------------------------------------------------------------------
-- left orbit: a lane up the left side, entered from the lower playfield
-- and joining the top arch
-- ---------------------------------------------------------------------

-- The inner orbit wall's entrance, its post and the targets mounted on it
-- form the "orbit entrance" editor item (its upper section is rebuilt by
-- buildOrbitTop). The entrance and loop switches span from the fixed outer
-- wall to the inner wall, so only their inner end moves (fixA).
collect = orbit.parts
wall(-19.2, 50, -21.5, 58)
post(-19.2, 50, 0.6)
collect = nil
orbit.switches[1] = lineSwitch("orbitEntrance", "rollover", L, 50, -19.2, 50)
orbit.switches[2] = lineSwitch("leftLoop", "loop", L, 66, -21.5, 66)
orbit.switches[1].fixA, orbit.switches[2].fixA = true, true
orbit.extra = orbitTop
editItems.orbit = orbit

-- ---------------------------------------------------------------------
-- pop bumpers
-- ---------------------------------------------------------------------

local bumpers = {}
local function bumper(name, u, w, label, num)
  local b = { name = name, u = u, w = w, flash = 0 }
  local item = { key = "bumper" .. num, label = label, parts = {}, switches = {}, num = num,
                 umin = u - BUMPER_R - 0.6, umax = u + BUMPER_R + 0.6,
                 wmin = w - BUMPER_R - 0.6, wmax = w + BUMPER_R + 0.6,
                 bumper = b, underArch = true }
  collect = item.parts
  local base = Cylinder(BUMPER_R, 3.0, 0)
  base.trans = btTransform(UPRIGHT, P(u, w, 1.5))
  base.col = "#e63946"
  base.restitution = 0.7
  v:add(base)
  collectPart(base, UPRIGHT, u, w, 1.5)
  local cap = Cylinder(BUMPER_R + 0.6, 0.6, 0)
  cap.trans = btTransform(UPRIGHT, P(u, w, 3.3))
  cap.col = "#f1faee"
  v:add(cap)
  collectPart(cap, UPRIGHT, u, w, 3.3)
  collect = nil
  b.cap = cap
  item.switches[1] = circleSwitch(name, "bumper", u, w, BUMPER_R + BALL_R + 0.3)
  bumpers[#bumpers + 1] = b
  editItems[item.key] = item
  return b
end
bumper("leftBumper", -9.0, 78, "pop bumper 1 (left)", 1)
bumper("rightBumper", 3.0, 78, "pop bumper 2 (right)", 2)
bumper("bottomBumper", -3.0, 69, "pop bumper 3 (bottom)", 3)

-- ---------------------------------------------------------------------
-- targets
-- ---------------------------------------------------------------------

-- F-A-N-T on the right side
for i, name in ipairs({ "F", "A1", "N", "T" }) do
  standup(name, 20.4, 37 + 4 * i, 180, "#ff7f50", nil, LAMP_COLS.letter)
end
-- A-S-Y and the upper-left standup sit on the orbit's inner wall, so they
-- move with the orbit entrance item
collect = orbit.parts
for _, t in ipairs({ { "A2", 70, "#ff7f50", LAMP_COLS.letter }, { "S", 74, "#ff7f50", LAMP_COLS.letter },
                     { "Y", 78, "#ff7f50", LAMP_COLS.letter }, { "upperLeftStandup", 82 } }) do
  orbit.switches[#orbit.switches + 1] = standup(t[1], -20.8, t[2], 0, t[3], nil, t[4])
end
collect = nil
-- the other 10-point standups (the lower-left one is on the orbit exit wall)
standup("lowerRightStandup", 20.4, 36.5, 180)
standup("rightStandup1", 20.4, 68, 180)
standup("rightStandup2", 20.4, 64, 180)
standup("rightStandup3", 20.4, 60, 180)
-- ramp target, upper right, facing down toward the flippers; its lamp
-- shows a lit extra ball
local ramp = standup("rampTarget", 13.5, 82, 235, "#8ecae6", nil, LAMP_COLS.red)

-- ---------------------------------------------------------------------
-- lower playfield: slingshots, inlanes/outlanes, flippers, drain
-- ---------------------------------------------------------------------

local FLIP_PIVOT_U, FLIP_PIVOT_W = 9.0, 14.5
local GUIDE_U, GUIDE_TOP = 17.6, 32
local SLING_BACK_U, SLING_TOP = 13.5, 31.5

-- The inlane guides, slingshots and flippers form the "flippers &
-- slingshots" editor item (the flippers are re-mounted by its afterMove).
local lower = { key = "lower", label = "flippers & slingshots", parts = {}, switches = {},
                du = 0, dw = 0 }
collect = lower.parts

local slings = {}
for _, side in ipairs({ -1, 1 }) do
  -- inlane guide: vertical, then angled in to the flipper pivot
  wall(side * GUIDE_U, GUIDE_TOP, side * GUIDE_U, 20, { thick = 0.5 })
  -- ends just above the flipper's pivot end, so the ball steps down onto
  -- the bat (a guide ending level with or below the bat leaves a notch
  -- the ball can rest in)
  wall(side * GUIDE_U, 20, side * (FLIP_PIVOT_U + 0.8), FLIP_PIVOT_W + 1.0, { thick = 0.5 })
  post(side * GUIDE_U, GUIDE_TOP, 0.4)

  -- slingshot triangle: back edge, bottom edge, and the kicking face
  local back1, back2 = { side * SLING_BACK_U, 22.5 }, { side * SLING_BACK_U, SLING_TOP }
  local tip = { side * 9.8, 21.5 }
  wall(back1[1], back1[2], back2[1], back2[2], { restitution = 0.4 })
  wall(back1[1], back1[2], tip[1], tip[2], { restitution = 0.4 })
  wall(back2[1], back2[2], tip[1], tip[2], { col = "#f1faee", restitution = 0.6 })
  post(back2[1], back2[2], 0.4)
  post(tip[1], tip[2], 0.4)
  post(back1[1], back1[2], 0.4)
  -- kick direction: the face normal pointing into the playfield
  local du, dw = tip[1] - back2[1], tip[2] - back2[2]
  local len = math.sqrt(du * du + dw * dw)
  local nu, nw = -dw / len, du / len
  if nu * side > 0 then nu, nw = -nu, -nw end
  local offs = 0.3   -- the face wall's half thickness
  local name = side < 0 and "leftSling" or "rightSling"
  lower.switches[#lower.switches + 1] =
    faceSwitch(name, "sling", back2[1] + nu * offs, back2[2] + nw * offs,
               tip[1] + nu * offs, tip[2] + nw * offs, BALL_R + 0.5)
  slings[#slings + 1] = { name = name, nu = nu, nw = nw }

  -- inlane and outlane rollovers
  local sideName = side < 0 and "left" or "right"
  lower.switches[#lower.switches + 1] =
    lineSwitch(sideName .. "Inlane", "rollover", side * SLING_BACK_U, 25, side * GUIDE_U, 25)
  local outlane = lineSwitch(sideName .. "Outlane", "outlane", side * GUIDE_U, 12, side * LANE_IN, 12)
  outlane.fixB = true   -- its outer end stays on the (fixed) outer wall
  lower.switches[#lower.switches + 1] = outlane
end
collect = nil

-- outlane outer walls (the right one is the shooter lane's inner wall)
wall(-LANE_IN, 32, -LANE_IN, 0)

-- drain funnel below the flippers, ending in the outhole pocket
wall(-LANE_IN, 3, -2.2, -3.5)
wall(LANE_IN, 3, 2.2, -3.5)
wall(-2.2, -3.5, -2.2, -6)
wall(2.2, -3.5, 2.2, -6)
wall(-2.2, -6, 2.2, -6)
local function inOuthole(u, w) return w < -2.5 and math.abs(u) < 2.2 end

-- flippers
local flippers = {}

-- Put flipper f at rest with its pivot at (pu, pw), on a new hinge there.
-- A one-body hinge is anchored to the world where the body was when it was
-- made, so moving a flipper means replacing its hinge.
local function mountFlipper(f, pu, pw)
  local side = f.side
  -- Bullet's one-body hinge measures its angle as the bar's absolute yaw,
  -- so the limits below are absolute too. The bar's local +X always points
  -- to the right: pivot-to-tip for the left flipper, tip-to-pivot for the
  -- right one. That keeps both bars' yaw near 0 (at rest -30 and +30
  -- degrees) instead of wrapping past 180 for the right one.
  local ang = side * FLIP_REST
  local du, dw = math.cos(ang), math.sin(ang)
  local cu, cw = pu - side * du * FLIP_LEN / 2, pw - side * dw * FLIP_LEN / 2
  if f.hinge then v:removeConstraint(f.hinge) end
  f.body.trans = btTransform(yRot(ang), P(cu, cw, FLIP_H / 2 + 0.15))
  f.body.vel = btVector3(0, 0, 0)
  f.body.body:setAngularVelocity(btVector3(0, 0, 0))
  -- hinge about the world's vertical axis through the pivot
  local hinge = btHingeConstraint(f.body.body, btVector3(side * FLIP_LEN / 2, 0, 0),
                                  btVector3(0, 1, 0))
  if side < 0 then
    hinge:setLimit(-FLIP_REST, -FLIP_REST + FLIP_STROKE, 0.9, 0.3, 1.0)
  else
    hinge:setLimit(FLIP_REST - FLIP_STROKE, FLIP_REST, 0.9, 0.3, 1.0)
  end
  v:addConstraint(hinge)
  f.hinge, f.pu, f.pw = hinge, pu, pw
end

for _, side in ipairs({ -1, 1 }) do
  local body = Cube(FLIP_LEN, FLIP_H, FLIP_THICK, FLIP_MASS)
  body.col = "#f8f9fa"
  body.friction = 0.6
  body.restitution = 0.45
  local f = { side = side, body = body, pressed = false, col0 = body.col }
  v:add(body)
  body.body:setActivationState(4)
  mountFlipper(f, side * FLIP_PIVOT_U, FLIP_PIVOT_W)
  flippers[side] = f
end
lower.flippers = flippers
editItems.lower = lower

-- ---------------------------------------------------------------------
-- the orbit exit: the angled wall from the bottom of the orbit's outer
-- wall (L, 44) down to (EXIT_U0 + du, EXIT_W0 + dw). Built where it ends
-- on the outlane's outer wall, so a ball coming down the orbit rides it
-- straight into the outlane; moved right over the inlane, it returns such
-- balls to the flipper. When its end is right of the outlane's outer
-- wall, a short wall closes the gap below it. The lower-left standup is
-- set into it and moves along with it.
-- ---------------------------------------------------------------------

local EXIT_U0, EXIT_W0 = -LANE_IN, 32
local exitWall = { key = "exit", label = "orbit exit", parts = {}, switches = {}, du = 0, dw = 0 }
local function exitEndFor(du, dw) return EXIT_U0 + du, EXIT_W0 + dw end
local function exitLineWFor(u, du, dw)          -- the wall's w above u
  local eu, ew = exitEndFor(du, dw)
  return 44 + (ew - 44) * (u - L) / (eu - L)
end
local exitStandup = nil

local function buildExit()
  removeParts(exitWall.parts)
  exitWall.parts = {}
  local eu, ew = exitEndFor(exitWall.du, exitWall.dw)
  collect = exitWall.parts
  wall(L, 44, eu, ew)
  post(eu, ew, 0.3, "#6b4f3a")
  if eu > -LANE_IN + 0.05 then
    wall(-LANE_IN, 32, -LANE_IN, exitLineWFor(-LANE_IN, exitWall.du, exitWall.dw))
  end
  -- the standup, flush in the wall about half way along
  local du, dw = eu - L, ew - 44
  local len = math.sqrt(du * du + dw * dw)
  local nu, nw = -dw / len, du / len               -- normal, toward the playfield
  if nu < 0 then nu, nw = -nu, -nw end
  collect = nil
  -- (not collected: standup() removes and replaces its own block). Its
  -- face sits just inside the wall's face (0.12 + 0.15 < 0.3): standing
  -- proud of a wall this steep, it would catch a ball rolling down it.
  local t = 0.52
  local su, sw = L + du * t + nu * 0.12, 44 + dw * t + nw * 0.12
  exitStandup = standup("lowerLeftStandup", su, sw, math.deg(math.atan2(nw, nu)), nil, 0.3,
                        nil, exitStandup)
  exitWall.built = true
end
buildExit()
editItems.exit = exitWall

-- ---------------------------------------------------------------------
-- the ramp: a clear plastic ramp that a ball shot from the left flipper
-- climbs, turning left over the top of the pop bumpers and running back
-- down the left side to drop the ball into the left inlane. Its entrance
-- can be moved and turned in the layout editor (M); the rest of it follows
-- (its far end always drops into the left inlane, wherever the flippers
-- are).
--
-- The glass lies just above the ball everywhere else, so a ball on the
-- ramp would hit it. While the ball is on the ramp -- or up in the air
-- dropping off its end -- the glass lets it through; the ramp has its own
-- clear cover. Switches know whether the ball is up on the ramp or down on
-- the playfield, so a ball on the ramp doesn't trip the targets under it.
-- ---------------------------------------------------------------------

local rampway = { key = "ramp", label = "ramp", parts = {}, switches = {}, du = 0, dw = 0,
                  da = 0, built = false, pts = nil, glassOff = false }
do
  local RW = rampway
  RW.E0 = { 10.5, 56 }       -- the entrance mouth's centre, as built
  RW.A0 = 15                 -- its heading, degrees right of straight up the table
  RW.WIDTH = 3.6             -- between the rails (the ball is 2.7 across)...
  RW.FLARE, RW.FLARE_LEN = 5.0, 16  -- ...plus this much wider at the mouth, narrowing
                                    -- over its first 16 cm, so it's a fair target
  RW.RAIL_T = 0.3
  RW.RAIL_H = 4.0            -- the rails' height; the cover sits on them (well above
                             -- the ball: one pinched between cover and floor stops dead)
  RW.PLATE = 0.3             -- the floor's thickness
  RW.LOW = 14                -- it climbs to H1 over the first 14 cm: from there
  RW.H1 = 4.2                -- on, everything on the playfield passes under it
  RW.CLIMB2 = 1              -- and no higher: the ball already has the tilted table
  RW.HTOP = RW.H1            -- to climb as it goes round, so the lower the better
  RW.HEND = 4.0              -- its far end, where the ball drops off
  RW.STEP = 1.5              -- segment length
  RW.TURN_GAP = 8            -- the turn at the top starts this far past the climb...
  RW.TURN_H = 8              -- ...and rises this much further up the table as it goes round
  RW.CAP_TOP = 3.35          -- under the entrance the floor meets the glass's height here:
                             -- a wall closes the space under the ramp below that
  RW.floorCol, RW.railCol, RW.coverCol = "#7fc8f8", "#d9dde2", "#ffffff"
  RW.EXIT_SPEED = 110        -- the last stretch slows the ball to this (cm/s), as a
                             -- real ramp's wire return does, so it drops into the
                             -- inlane rather than flying at the posts

  -- where it drops the ball: over the top of the left inlane
  function RW.exitPoint()
    return -(GUIDE_U + SLING_BACK_U) / 2 + lower.du, GUIDE_TOP + lower.dw + 7
  end

  -- the centreline's control points for entrance offsets (du, dw) and turn da
  function RW.controls(du, dw, da)
    local eu, ew = RW.E0[1] + du, RW.E0[2] + dw
    local a = math.rad(RW.A0 + da)
    local hu, hw = math.sin(a), math.cos(a)
    local xu, xw = RW.exitPoint()
    local lu, lw = eu + hu * RW.LOW, ew + hw * RW.LOW
    -- (it turns soon after the climb: every cm further up the tilted table
    -- is more for the ball to climb)
    local tw = lw + RW.TURN_GAP
    local top = tw + RW.TURN_H
    return {
      { eu, ew }, { eu + hu * 6, ew + hw * 6 }, { lu, lw },
      { lu, tw }, { lu - 0.3 * (lu - xu), top }, { xu + 0.3 * (lu - xu), top },
      { xu, tw }, { xu, (tw + xw) / 2 }, { xu, xw },
    }
  end

  -- The floor's height (top) at distance s along it, of total length S;
  -- sD is where the run down the left side begins.
  function RW.heightAt(s, S, sD)
    -- (an S-shaped climb, level at both ends: a ball meeting a sudden
    -- slope, or one that suddenly levels off, loses much of its speed --
    -- the second throws it into the air)
    if s <= RW.LOW then
      local x = s / RW.LOW
      return RW.H1 * x * x * (3 - 2 * x)
    end
    if s <= RW.LOW + RW.CLIMB2 then return RW.H1 + (RW.HTOP - RW.H1) * (s - RW.LOW) / RW.CLIMB2 end
    if s <= sD then return RW.HTOP end
    return RW.HTOP + (RW.HEND - RW.HTOP) * (s - sD) / math.max(1, S - sD)
  end

  -- The centreline, every STEP cm: { u, w, h, s, tu, tw (tangent), nu, nw
  -- (normal, to the left) }, and the length.
  function RW.path(du, dw, da)
    local c = RW.controls(du, dw, da)
    local n = #c
    local dense, len = { { c[1][1], c[1][2], 0 } }, 0
    local sD = nil
    for k = 1, n - 1 do
      if k == 7 then sD = len end
      local p0, p1, p2, p3 = c[math.max(1, k - 1)], c[k], c[k + 1], c[math.min(n, k + 2)]
      for i = 1, 24 do
        local t = i / 24
        local t2, t3 = t * t, t * t * t
        local function cr(a0, a1, a2, a3)
          return 0.5 * (2 * a1 + (-a0 + a2) * t + (2 * a0 - 5 * a1 + 4 * a2 - a3) * t2
                        + (-a0 + 3 * a1 - 3 * a2 + a3) * t3)
        end
        local u, w = cr(p0[1], p1[1], p2[1], p3[1]), cr(p0[2], p1[2], p2[2], p3[2])
        local last = dense[#dense]
        len = len + math.sqrt((u - last[1]) ^ 2 + (w - last[2]) ^ 2)
        dense[#dense + 1] = { u, w, len }
      end
    end
    -- resample at even spacing
    local pts, j = {}, 1
    local count = math.max(2, math.floor(len / RW.STEP + 0.5))
    for i = 0, count do
      local s = len * i / count
      while j < #dense - 1 and dense[j + 1][3] < s do j = j + 1 end
      local a, b = dense[j], dense[j + 1]
      local f = (b[3] > a[3]) and (s - a[3]) / (b[3] - a[3]) or 0
      pts[#pts + 1] = { u = a[1] + (b[1] - a[1]) * f, w = a[2] + (b[2] - a[2]) * f, s = s,
                        h = RW.heightAt(s, len, sD or len) }
    end
    for i, p in ipairs(pts) do
      local a, b = pts[math.max(1, i - 1)], pts[math.min(#pts, i + 1)]
      local tu, tw = b.u - a.u, b.w - a.w
      local tl = math.sqrt(tu * tu + tw * tw)
      p.tu, p.tw = tu / tl, tw / tl
      p.nu, p.nw = -p.tw, p.tu
    end
    return pts, len
  end

  -- Is the ramp with this entrance possible? True, or false and why.
  -- With `shapeOnly`, just the ramp's own shape (on the playfield, not too
  -- tight, not crossing itself), not what it's near.
  function RW.check(du, dw, da, shapeOnly)
    local pts, len = RW.path(du, dw, da)
    local half = RW.WIDTH / 2 + RW.RAIL_T
    local e = pts[1]
    if da < -30 or da > 30 then return false, "it can't turn any further" end
    if e.w < 40 + lower.dw then return false, "the entrance would reach the slingshots" end
    if e.w + RW.LOW + RW.TURN_GAP + RW.TURN_H + 3 > PF_TOP - 12 then return false, "the entrance is as high as it goes" end
    local _, xw = RW.exitPoint()
    if e.w + RW.LOW + RW.TURN_GAP < xw + 12 then return false, "the entrance is as low as it goes" end
    for i, p in ipairs(pts) do
      for _, side in ipairs({ -1, 1 }) do
        local u, w = p.u + side * half * p.nu, p.w + side * half * p.nw
        if u < L + 1.0 or u > R - 1.0 or w > PF_TOP - 2 then
          return false, "the ramp would leave the playfield"
        end
      end
      -- tight turns: the heading may change by no more than STEP / 5.5 cm radius
      if i > 1 then
        local q = pts[i - 1]
        local cross = q.tu * p.tw - q.tw * p.tu
        if math.abs(cross) > RW.STEP / 5.5 then return false, "the ramp would turn too tightly" end
      end
      -- it mustn't run into itself
      for k = i + 12, #pts do
        local o = pts[k]
        if (o.u - p.u) ^ 2 + (o.w - p.w) ^ 2 < (2 * half + 0.4) ^ 2 then
          return false, "the ramp would run into itself"
        end
      end
    end
    if shapeOnly then return true end
    -- the low end, near the entrance, stands on the playfield: it must be
    -- clear of everything there, with room for the ball to pass (or none)
    -- a gap is fine if it's too narrow for the ball to get into, or wide
    -- enough for it to roll through; one about the ball's size traps it
    local function gapOK(gap)
      return (gap >= 0.1 and gap < 2 * BALL_R - 0.1) or gap >= 2 * BALL_R + 0.3
    end
    -- the narrowest gap to each thing near the low end
    local gaps = {}
    local function gap(key, g)
      if not gaps[key] or g < gaps[key] then gaps[key] = g end
    end
    for _, p in ipairs(pts) do
      if p.s > RW.LOW + 0.5 then break end
      local hf = RW.widthAt(p.s) / 2 + RW.RAIL_T
      for k = -2, 2 do
        local u, w = p.u + p.nu * hf * k / 2, p.w + p.nw * hf * k / 2
        if u > R - 1.0 then return false, "the ramp would reach the shooter lane" end
        if w > 34 and w < 72 then gap("the right-hand targets", (20.4 - 0.4) - u) end
        if w > 48 then gap("the orbit wall", u - (-21.5 + orbit.du + 0.3)) end
        for _, b in ipairs(bumpers) do
          gap("a pop bumper", math.sqrt((b.u - u) ^ 2 + (b.w - w) ^ 2) - (BUMPER_R + 0.6))
        end
        gap("the blue target", math.sqrt((13.5 - u) ^ 2 + (82 - w) ^ 2) - 2.0)
        gap("the orbit entrance", math.sqrt((-19.2 + orbit.du - u) ^ 2 + (50 + orbit.dw - w) ^ 2) - 0.6)
        if u > lanes.umin + lanes.du - 3 and u < lanes.umax + lanes.du + 3
           and w > lanes.wmin + lanes.dw - 3 then
          return false, "the ramp would reach the rollover lanes"
        end
      end
    end
    for what, g in pairs(gaps) do
      if g < 0.1 then return false, "the ramp would run into " .. what end
      if not gapOK(g) then return false, "the ball could get stuck between the ramp and " .. what end
    end
    -- where it drops the ball must be clear of the orbit exit wall
    local xu, xw = RW.exitPoint()
    local eu, ew = exitEndFor(exitWall.du, exitWall.dw)
    local su, sw = eu - L, ew - 44
    local t = math.max(0, math.min(1, ((xu - L) * su + (xw - 44) * sw) / (su * su + sw * sw)))
    if math.sqrt((L + su * t - xu) ^ 2 + (44 + sw * t - xw) ^ 2) < BALL_R + 1.5 then
      return false, "the ramp drops the ball onto the orbit exit wall"
    end
    return true
  end

  -- the width between the rails at distance s along it
  function RW.widthAt(s)
    if s >= RW.FLARE_LEN then return RW.WIDTH end
    local f = 1 - s / RW.FLARE_LEN
    return RW.WIDTH + RW.FLARE * f * f
  end

  -- A box from (u1,w1,y1) to (u2,w2,y2): `across` wide, `thick` deep (up
  -- and down), tilted to follow the slope. `level`: don't tilt it (its
  -- height is then y1..y2 as given, standing on the playfield).
  local zAxis = btVector3(0, 0, 1)
  -- `ext`: how far it runs on past each end (default 0.1, so the pieces
  -- of the floor overlap; the rails' pieces meet exactly, at round posts).
  function RW.slab(u1, w1, y1, u2, w2, y2, across, thick, col, transp, level, ext)
    local du, dw = u2 - u1, w2 - w1
    local lh = math.sqrt(du * du + dw * dw)
    local q, c
    ext = ext or 0.1
    if level then
      q = yRot(math.atan2(dw, du))
      c = Cube(lh + 2 * ext, math.abs(y2 - y1), across, 0)
      c.trans = btTransform(q, P((u1 + u2) / 2, (w1 + w2) / 2, (y1 + y2) / 2))
    else
      local pitch = math.atan2(y2 - y1, lh)
      q = yRot(math.atan2(dw, du)) * btQuaternion(zAxis, pitch)
      c = Cube(math.sqrt(lh * lh + (y2 - y1) ^ 2) + 2 * ext, thick, across, 0)
      c.trans = btTransform(q, P((u1 + u2) / 2, (w1 + w2) / 2, (y1 + y2) / 2))
    end
    c.col = col
    if transp then c.transparency = transp end
    c.friction = 0.2
    c.restitution = 0.3
    if col == RW.railCol or col == RW.coverCol then c.friction = 0.02 end   -- (smooth rails and cover)
    v:add(c)
    collectPart(c, q, (u1 + u2) / 2, (w1 + w2) / 2, (y1 + y2) / 2)
    return c
  end

  function RW.build()
    removeParts(RW.parts)
    RW.parts = {}
    local pts, len = RW.path(RW.du, RW.dw, RW.da)
    RW.pts, RW.len = pts, len
    local W, T, PL = RW.WIDTH, RW.RAIL_T, RW.PLATE
    collect = RW.parts
    local capDone = false
    for i = 1, #pts - 1 do
      local a, b = pts[i], pts[i + 1]
      -- the floor
      local Wa, Wb = RW.widthAt(a.s), RW.widthAt(b.s)
      RW.slab(a.u, a.w, a.h - PL / 2, b.u, b.w, b.h - PL / 2, math.max(Wa, Wb) + 2 * T, PL, RW.floorCol, 0.35)
      -- the rails: down to the playfield where the floor is low, so no ball
      -- can get in under it from the side
      local low = (a.h + b.h) / 2 < RW.CAP_TOP + PL
      for _, side in ipairs({ -1, 1 }) do
        local oa, ob = side * (Wa / 2 + T / 2), side * (Wb / 2 + T / 2)
        local au, aw = a.u + a.nu * oa, a.w + a.nw * oa
        local bu, bw = b.u + b.nu * ob, b.w + b.nw * ob
        if low then
          RW.slab(au, aw, 0, bu, bw, math.max(a.h, b.h) + RW.RAIL_H, T, nil, RW.railCol, nil, true, 0)
        else
          RW.slab(au, aw, a.h + (RW.RAIL_H - PL) / 2, bu, bw, b.h + (RW.RAIL_H - PL) / 2,
                  T, RW.RAIL_H + PL, RW.railCol, nil, nil, 0)
        end
        -- a round post where two pieces of rail meet, so the ball can't
        -- catch on a corner
        if i > 1 then
          local bot = low and 0 or (a.h - PL)
          local top = a.h + RW.RAIL_H
          local c = Cylinder(T / 2, top - bot, 0)
          c.trans = btTransform(UPRIGHT, P(au, aw, (bot + top) / 2))
          c.col = RW.railCol
          c.friction, c.restitution = 0.05, 0.3
          v:add(c)
          collectPart(c, UPRIGHT, au, aw, (bot + top) / 2)
        end
      end
      -- the clear cover
      RW.slab(a.u, a.w, a.h + RW.RAIL_H + 0.15, b.u, b.w, b.h + RW.RAIL_H + 0.15,
              math.max(Wa, Wb) + 2 * T, 0.3, RW.coverCol, 0.9)
      -- the wall that closes the space under the entrance
      if not capDone and not low then
        capDone = true
        local cu, cw = a.u + a.nu * (W / 2), a.w + a.nw * (W / 2)
        local du2, dw2 = a.u - a.nu * (W / 2), a.w - a.nw * (W / 2)
        RW.slab(cu, cw, 0, du2, dw2, a.h - PL, 0.4, nil, RW.railCol, nil, true)
      end
    end
    collect = nil
    -- its switches: going in, and making it (near the far end)
    local function across(s)
      local best
      for _, p in ipairs(pts) do
        if not best or math.abs(p.s - s) < math.abs(best.s - s) then best = p end
      end
      local hw = W / 2
      return { best.u + best.nu * hw, best.w + best.nw * hw }, { best.u - best.nu * hw, best.w - best.nw * hw }, best
    end
    local a1, b1, at1 = across(5)
    local a2, b2 = across(len - 8)
    if RW.decorate then collect = RW.parts; RW.decorate(pts); collect = nil end   -- (its chevrons)
    if not RW.enterSwitch then
      RW.enterSwitch = lineSwitch("rampEntrance", "ramp", a1[1], a1[2], b1[1], b1[2])
      RW.madeSwitch = lineSwitch("rampMade", "rampMade", a2[1], a2[2], b2[1], b2[2])
      RW.enterSwitch.elevated, RW.madeSwitch.elevated = true, true
      RW.enterSwitch.upOnly = true        -- (not a ball rolling back out)
    else
      RW.enterSwitch.a, RW.enterSwitch.b = a1, b1
      RW.madeSwitch.a, RW.madeSwitch.b = a2, b2
    end
    RW.enterSwitch.tu, RW.enterSwitch.tw = at1.tu, at1.tw
    local umin, umax, wmin, wmax = math.huge, -math.huge, math.huge, -math.huge
    for _, p in ipairs(pts) do
      umin, umax = math.min(umin, p.u), math.max(umax, p.u)
      wmin, wmax = math.min(wmin, p.w), math.max(wmax, p.w)
    end
    RW.box = { umin - 3, umax + 3, wmin - 3, wmax + 3 }
    RW.built = true
  end

  -- Is a ball at (u, w), centre height y, riding the ramp?
  -- (and the point of the centreline it's at)
  function RW.carrying(u, w, y)
    local pts, bx = RW.pts, RW.box
    if not pts or u < bx[1] or u > bx[2] or w < bx[3] or w > bx[4] then return false end
    local best, bd = nil, math.huge
    for _, p in ipairs(pts) do
      local d = (p.u - u) ^ 2 + (p.w - w) ^ 2
      if d < bd then best, bd = p, d end
    end
    return math.sqrt(bd) < RW.widthAt(best.s) / 2 + RW.STEP and y > best.h + BALL_R - 0.7, best
  end

  -- Every frame: the glass lets the ball through while it's on the ramp
  -- or up in the air (a ball on the playfield can't be: the glass is just
  -- above it); back once it's down under the glass's height again.
  -- Is a ball at (u, w) just in front of the mouth, where it may be on the
  -- ramp by the next frame? (A fast ball goes 7 cm a frame: the glass must
  -- already be open when it gets there, or it's wedged under it.)
  function RW.atMouth(u, w)
    local p = RW.pts and RW.pts[1]
    if not p then return false end
    local du, dw = u - p.u, w - p.w
    local along, lat = du * p.tu + dw * p.tw, du * p.nu + dw * p.nw
    return along > -10 and along < 2 and math.abs(lat) < RW.widthAt(0) / 2 + 1.5
  end

  function RW.glassTick(u, w, y)
    local on, at = RW.carrying(u, w, y)
    if on and at.s > RW.len - 10 then
      local vel = RW.ball.vel
      local sp = math.sqrt(vel.x * vel.x + vel.z * vel.z)
      if sp > RW.EXIT_SPEED then
        local k = RW.EXIT_SPEED / sp
        RW.ball.vel = btVector3(vel.x * k, vel.y, vel.z * k)
      end
    end
    -- (a ball that has left the ramp is still let through until it's down;
    -- one on the playfield never is, however hard it presses on the glass)
    if on then RW.fromRamp = true
    elseif y < GLASS_Y - BALL_R - 0.02 then RW.fromRamp = false end
    local off = on or RW.fromRamp or (y < BALL_R + 0.3 and RW.atMouth(u, w))
    if off ~= RW.glassOff then
      RW.glassOff = off
      local flags = glass.body:getCollisionFlags()
      if off then flags = flags + CF_NO_CONTACT_RESPONSE else flags = flags - CF_NO_CONTACT_RESPONSE end
      glass.body:setCollisionFlags(flags)
    end
  end

  -- the layout editor
  -- A move of the ramp is refused if it would make it clash with
  -- something -- unless it clashes already (a layout saved before the ramp
  -- existed, say), when it may go anywhere its shape allows, so it can be
  -- moved clear.
  function RW.moveOK(du, dw, da)
    local ok, why = RW.check(du, dw, da)
    if ok or RW.check(RW.du, RW.dw, RW.da) then return ok, why end
    return RW.check(du, dw, da, true)
  end
  RW.valid = function(it, du, dw) return RW.moveOK(du, dw, it.da) end
  RW.applyFn = function(it) it.built = false end
  RW.describe = function(it)
    local e = RW.E0
    local text = string.format("entrance %.1f across, %.1f up, aimed %.1f deg right of straight up",
                               e[1] + it.du, e[2] + it.dw, RW.A0 + it.da)
    local ok, why = RW.check(it.du, it.dw, it.da)
    if not ok then text = text .. " -- NEEDS MOVING: " .. why end
    return text
  end
  -- turn it by dA degrees (the "," and "." keys)
  -- (like a move, a turn that lands where the ball could get stuck carries
  -- on to the next safe angle, a step or two on)
  function RW.turn(dA)
    local ok, why
    for k = 1, 3 do
      ok, why = RW.moveOK(RW.du, RW.dw, RW.da + k * dA)
      if ok then RW.da = RW.da + k * dA; RW.built = false; return true end
      if not (why and why:find("stuck")) then break end
    end
    return ok, why
  end
  RW.umin, RW.umax, RW.wmin, RW.wmax = 8, 13, 54, 58    -- (roughly; for the editor's lists)
end
rampway.build()
editItems.ramp = rampway

-- ---------------------------------------------------------------------
-- other lamps: bonus multiplier (2x-5x), extra ball lit is the ramp
-- target's own lamp, shoot again between the flippers
-- ---------------------------------------------------------------------

local multLamps = {}
for i, n in ipairs({ 2, 3, 4, 5 }) do
  multLamps[n] = lamp(-4.5 + 3 * (i - 1), 40.5, LAMP_COLS.mult[1], LAMP_COLS.mult[2], 0.9)
end
local shootAgainLamp = lamp(0, 6.5, LAMP_COLS.red[1], LAMP_COLS.red[2], 1.0)

-- ---------------------------------------------------------------------
-- the ball
-- ---------------------------------------------------------------------

local ball = Sphere(BALL_R, BALL_MASS)
ball.pos = P(SHOOT_U, SHOOT_W, BALL_R)
ball.col = "#e9ecef"
ball.friction = 0.2
ball.restitution = 0.4
ball.damp_lin = 0.02
ball.damp_ang = 0.05
v:add(ball)
ball.body:setActivationState(4)
ball.body:setCcdMotionThreshold(BALL_R * 0.5)
ball.body:setCcdSweptSphereRadius(BALL_R * 0.8)
rampway.ball = ball            -- (the ramp slows it at its far end)

local function ballUW()
  local p = ball.pos
  return p.x, -p.z
end

-- ---------------------------------------------------------------------
-- the plunger: a rubber tip the ball rests on, a chrome rod and a knob
-- outside the cabinet. Holding Return draws it back (the ball rolls back
-- with it); releasing snaps it forward and launches the ball. The rod and
-- knob are only for show (no collision); the tip is solid.
-- ---------------------------------------------------------------------

local plunger = {
  TIP_W = -5.7,          -- the tip's face at rest
  PULL_MAX = 5,          -- cm drawn back at full strength
  pull = 0,              -- 0 at rest .. 1 fully drawn
  pulledAt = nil,        -- time Return went down
  parts = {},
}
do
  local laneW = (R - 0.3) - (LANE_IN + 0.3)
  local function part(obj, col, dw, solid)
    obj.col = col
    v:add(obj)
    if not solid then
      obj.body:setCollisionFlags(obj.body:getCollisionFlags() + CF_NO_CONTACT_RESPONSE)
    end
    plunger.parts[#plunger.parts + 1] = { obj = obj, dw = dw }
  end
  -- (a Cylinder's axis is world Z, which is along the table -- just right)
  part(Cube(laneW - 0.5, 2.0, 1.0, 0), "#a0522d", -0.5, true)            -- tip
  part(Cylinder(0.35, 9.6, 0), "#c8c8c8", -0.5 - 1.0 / 2 - 9.6 / 2)      -- rod
  part(Cylinder(1.2, 1.6, 0), "#b0171f", -0.5 - 1.0 / 2 - 9.6 - 0.8)     -- knob
end
function plunger.place()
  local w0 = plunger.TIP_W - plunger.PULL_MAX * plunger.pull
  for _, p in ipairs(plunger.parts) do
    p.obj.pos = P(SHOOT_U, w0 + p.dw, 1.1)
  end
end
plunger.place()

-- set when the script moves the ball, so the switch check doesn't treat the
-- jump as a path the ball rolled along
local ballTeleported = false

local function placeBall(u, w)
  ballTeleported = true
  ball.pos = P(u, w, BALL_R + 0.05)
  ball.vel = btVector3(0, 0, 0)
  ball.body:setAngularVelocity(btVector3(0, 0, 0))
end

-- ---------------------------------------------------------------------
-- sounds: rules.sounds maps an event (or a switch name) to a file in
-- SOUND_DIR. Files that aren't there are skipped.
-- ---------------------------------------------------------------------

local soundIds = {}
do
  local found, missing = 0, {}
  for event, file in pairs(rules.sounds) do
    local f = io.open(SOUND_DIR .. file, "rb")
    if f then
      f:close()
      local id = v.loadSound and v:loadSound(SOUND_DIR .. file) or -1
      if id >= 0 then soundIds[event] = id; found = found + 1 end
    else
      missing[#missing + 1] = file
    end
  end
  table.sort(missing)
  if #missing > 0 then
    print(string.format("Sounds: %d loaded; not found in %s: %s", found, SOUND_DIR,
                        table.concat(missing, ", ")))
  end
end

local function playSound(event, switchName)
  local id = (switchName and soundIds[switchName]) or soundIds[event]
  if id then v:playSound(id) end
end

-- ---------------------------------------------------------------------
-- scoreboard: seven-segment digits in the backbox
-- ---------------------------------------------------------------------

local board, CHARS, SEG_BITS
do
local BOX_W, BOX_Y = PF_TOP + 3, 20
local backbox = Cube(TABLE_W + 4, 26, 1, 0)
backbox.pos = btVector3(0, BOX_Y, -BOX_W - 0.6)
backbox.col = "#101418"
v:add(backbox)

-- segment bits a..g as used by the character table below
SEG_BITS = { 1, 2, 4, 8, 16, 32, 64 }
CHARS = {
  ["0"] = 63, ["1"] = 6, ["2"] = 91, ["3"] = 79, ["4"] = 102, ["5"] = 109,
  ["6"] = 125, ["7"] = 7, ["8"] = 127, ["9"] = 111,
  A = 119, B = 124, C = 57, D = 94, E = 121, F = 113, G = 61, H = 118, I = 48,
  J = 30, L = 56, M = 55, N = 84, O = 63, P = 115, R = 80, S = 109, T = 120, U = 62,
  Y = 110, ["-"] = 64, [" "] = 0,
}

-- A row of seven-segment digits. With `showOff`, unlit segments are drawn
-- dim (an LED display); without, only lit ones exist (a printed label).
local function segDisplay(x0, y, count, scale, onCol, offCol, showOff)
  local W, H, T = 1.9 * scale, 3.2 * scale, 0.32 * scale
  local pitch = 3.0 * scale
  local segs = {   -- a..g: {dx, dy, width, height}
    { 0, H / 2, W - T, T }, { W / 2, H / 4, T, H / 2 - T }, { W / 2, -H / 4, T, H / 2 - T },
    { 0, -H / 2, W - T, T }, { -W / 2, -H / 4, T, H / 2 - T }, { -W / 2, H / 4, T, H / 2 - T },
    { 0, 0, W - T, T },
  }
  local d = { digits = {}, count = count }
  for k = 1, count do
    local x = x0 + (k - 1) * pitch
    local cubes = {}
    for s, g in ipairs(segs) do
      local c = Cube(g[3], g[4], 0.3, 0)
      c.pos = btVector3(x + g[1], y + g[2], -BOX_W)
      c.col = offCol
      c.pov_export = false
      if showOff then v:add(c) end
      cubes[s] = { obj = c, added = showOff, on = false }
    end
    d.digits[k] = cubes
  end
  -- show text, right-aligned if `right`
  d.set = function(text, right)
    text = tostring(text):upper()
    if #text > count then text = text:sub(-count) end
    if right then text = string.rep(" ", count - #text) .. text end
    for k = 1, count do
      local bits = CHARS[text:sub(k, k)] or 0
      for s, seg in ipairs(d.digits[k]) do
        local on = bits % (2 * SEG_BITS[s]) >= SEG_BITS[s]
        if on ~= seg.on then
          if not showOff and on and not seg.added then v:add(seg.obj); seg.added = true end
          seg.obj.col = on and onCol or offCol
          seg.on = on
        end
      end
    end
  end
  return d
end

local LABEL_COL, LABEL_OFF = "#d9d9d9", "#101418"
local LED_ON, LED_OFF = "#ff6a00", "#2a1408"
board = {
  scoreLabel = segDisplay(-24.5, 29, 5, 0.6, LABEL_COL, LABEL_OFF, false),
  score = segDisplay(-7.5, 28.5, 8, 1.4, LED_ON, LED_OFF, true),
  ballLabel = segDisplay(-24.5, 21, 4, 0.6, LABEL_COL, LABEL_OFF, false),
  ball = segDisplay(-12.5, 21, 1, 0.9, LED_ON, LED_OFF, true),
  bonusLabel = segDisplay(-8.5, 21, 5, 0.6, LABEL_COL, LABEL_OFF, false),
  bonus = segDisplay(2.5, 21, 6, 0.9, LED_ON, LED_OFF, true),
  mult = segDisplay(14.5, 14.5, 4, 0.9, "#ffffff", LABEL_OFF, true),
  highLabel = segDisplay(-24.5, 14.5, 2, 0.6, LABEL_COL, LABEL_OFF, false),
  high = segDisplay(-19.0, 14.5, 8, 0.9, LED_ON, LED_OFF, true),
  message = segDisplay(-16.5, 9, 12, 0.9, "#7cfc00", "#16240a", true),
}
board.scoreLabel.set("SCORE")
board.ballLabel.set("BALL")
board.bonusLabel.set("BONUS")
board.highLabel.set("HI")
-- the marquee above the scores
local marquee = Cube(TABLE_W + 4, 15, 1, 0)
marquee.pos = btVector3(0, 40.5, -BOX_W - 0.6)
marquee.col = "#2b0a3d"
v:add(marquee)
segDisplay(-13.5, 43.6, 7, 1.5, "#ffd60a", "#2b0a3d", false).set("PINBALL")
segDisplay(-11.4, 37.3, 9, 0.95, "#ff2d95", "#2b0a3d", false).set("MACHINE A")
end

-- ---------------------------------------------------------------------
-- the cabinet and the artwork: an arcade cabinet on four chrome legs
-- (side art, side rails, lockdown bar, coin door, start and flipper
-- buttons) with the backbox on top and a lit marquee; on the playfield a
-- sunburst behind the bumpers, a diamond above the flippers, chevron
-- arrows into the ramp and the orbit, and the apron with the machine's
-- name. All of it is only for show -- nothing here touches the ball -- and
-- some of it flashes (board.artTick, every frame).
-- ---------------------------------------------------------------------

do
  local art = { chase = {}, rays = {}, bulbs = {} }
  board.art = art
  local ident = btQuaternion(0, 0, 0, 1)
  local xAxisV = btVector3(1, 0, 0)

  -- add an object that's only for show
  local function vis(obj, col)
    obj.col = col
    local ok = pcall(function() obj.collides = false end)
    v:add(obj)
    if not ok then obj.body:setCollisionFlags(obj.body:getCollisionFlags() + CF_NO_CONTACT_RESPONSE) end
    return obj
  end
  -- a box in world coordinates
  local function wbox(x, y, z, sx, sy, sz, col, q)
    local c = Cube(sx, sy, sz, 0)
    c.trans = btTransform(q or ident, btVector3(x, y, z))
    return vis(c, col)
  end
  -- flat art on the playfield: a strip centred at (u, w), `len` long at
  -- angle `ang` (radians, from +u toward +w), `wid` wide; `layer` stacks
  -- pieces that overlap (0 lowest)
  local function flat(u, w, len, wid, ang, col, layer)
    local c = Cube(len, 0.02, wid, 0)
    local q = yRot(ang)
    local y = 0.004 + 0.004 * (layer or 0)
    c.trans = btTransform(q, P(u, w, y))
    vis(c, col)
    collectPart(c, q, u, w, y, true)
    return c
  end
  local function flatDisc(u, w, r, col, layer)
    local c = Cylinder(r, 0.02, 0)
    local y = 0.004 + 0.004 * (layer or 0)
    c.trans = btTransform(UPRIGHT, P(u, w, y))
    vis(c, col)
    collectPart(c, UPRIGHT, u, w, y, true)
    return c
  end
  -- a chevron pointing along angle `ang`, tip at (u, w)
  local function chevron(u, w, ang, size, col, layer)
    local arms = {}
    for _, side in ipairs({ -1, 1 }) do
      local a = ang + side * math.rad(135)       -- back from the tip, out to one side
      local hu, hw = math.cos(a), math.sin(a)
      arms[#arms + 1] = flat(u + hu * size / 2, w + hw * size / 2, size, 0.7, a, col, layer)
    end
    return arms
  end
  -- seven-segment letters lying on a surface at height y
  local function flatText(text, u0, w0, y, scale, col)
    local W, H, T = 1.9 * scale, 3.2 * scale, 0.36 * scale
    local pitch = 3.0 * scale
    local segs = {   -- a..g: {du, dw, width across, depth up the table}
      { 0, H / 2, W - T, T }, { W / 2, H / 4, T, H / 2 - T }, { W / 2, -H / 4, T, H / 2 - T },
      { 0, -H / 2, W - T, T }, { -W / 2, -H / 4, T, H / 2 - T }, { -W / 2, H / 4, T, H / 2 - T },
      { 0, 0, W - T, T },
    }
    for k = 1, #text do
      local bits = CHARS[text:sub(k, k)] or 0
      for s, g in ipairs(segs) do
        if bits % (2 * SEG_BITS[s]) >= SEG_BITS[s] then
          local c = Cube(g[3], 0.05, g[4], 0)
          c.pos = P(u0 + (k - 1) * pitch + g[1], w0 + g[2], y)
          vis(c, col)
        end
      end
    end
  end

  local HOT, PURPLE, YELLOW, CYAN, ORANGE = "#ff2d95", "#6a1fd0", "#ffd60a", "#22d3ee", "#ff7b00"
  local DIM = "#3a2a10"

  -- the sunburst behind the bumpers
  local SU, SW = -1, 84
  for i = 0, 15 do
    local a = 2 * math.pi * i / 16
    local col = (i % 2 == 0) and HOT or PURPLE
    art.rays[#art.rays + 1] = { obj = flat(SU + math.cos(a) * 13, SW + math.sin(a) * 13, 18, 2.6, a, col, i % 2),
                                a = HOT, b = PURPLE, even = (i % 2 == 0) }
  end
  flatDisc(SU, SW, 6.5, YELLOW, 2)
  flatDisc(SU, SW, 4.5, ORANGE, 3)
  flatDisc(SU, SW, 2.2, YELLOW, 4)

  -- the diamond above the flippers, and a band behind the multiplier lamps
  flat(0, 32, 6.5, 6.5, math.rad(45), HOT, 0)
  flat(0, 32, 4.2, 4.2, math.rad(45), CYAN, 1)
  flat(0, 32, 1.8, 1.8, math.rad(45), YELLOW, 2)
  flat(0, 40.5, 15, 3.4, 0, "#101828", 0)
  flat(0, 42.35, 15, 0.3, 0, YELLOW, 1)
  flat(0, 38.65, 15, 0.3, 0, YELLOW, 1)

  -- chevrons leading into the orbit (they move with the orbit entrance)
  collect = orbit.parts
  for k = 1, 3 do
    local tipU, tipW = -21.8 + 1.1 * k, 47 - 4.2 * k
    art.chase[#art.chase + 1] = { arms = chevron(tipU, tipW, math.rad(105), 2.6, DIM, 1), k = k, on = ORANGE }
  end
  collect = nil

  -- chevrons leading into the ramp: built with the ramp, so they follow it
  art.rampChase = {}
  rampway.decorate = function(pts)
    art.rampChase = {}
    local p = pts[1]
    local ang = math.atan2(p.tw, p.tu)
    for k = 1, 3 do
      local d = 3 + 4.2 * k
      art.rampChase[k] = { arms = chevron(p.u - p.tu * d, p.w - p.tw * d, ang, 3.0, DIM, 1), k = k, on = CYAN }
    end
  end
  rampway.built = false            -- (rebuilt with its chevrons when the layout loads)

  -- the apron: the plastic below the flippers, with the machine's name
  local function apron(u1, u2, w1, w2)
    local c = Cube(u2 - u1, 0.5, w2 - w1, 0)
    c.pos = P((u1 + u2) / 2, (w1 + w2) / 2, 0.25)
    vis(c, "#f4ecd8")
  end
  apron(-25.2, -3.6, -15.5, -4.6)
  apron(3.6, 20.8, -15.5, -4.6)
  flatText("PINBALL", -22.4, -6.9, 0.52, 0.85, "#c1121f")
  flatText("MACHINE", -22.4, -11.4, 0.52, 0.85, "#1d3557")
  -- and a big A on a yellow disc: two legs and a bar
  local ac = Cylinder(4.3, 0.05, 0)
  ac.trans = btTransform(UPRIGHT, P(12.2, -9.6, 0.52))
  vis(ac, YELLOW)
  local function strip(u1, w1, u2, w2, col)
    local du, dw = u2 - u1, w2 - w1
    local c = Cube(math.sqrt(du * du + dw * dw), 0.06, 0.75, 0)
    c.trans = btTransform(yRot(math.atan2(dw, du)), P((u1 + u2) / 2, (w1 + w2) / 2, 0.56))
    vis(c, col)
  end
  strip(10.0, -12.4, 12.2, -6.8, "#c1121f")
  strip(14.4, -12.4, 12.2, -6.8, "#c1121f")
  strip(10.9, -10.2, 13.5, -10.2, "#c1121f")

  -- the cabinet: body, side art, rails, lockdown bar
  local X0 = TABLE_W / 2 + 3.5            -- the body's sides
  local Z0, Z1 = -131, -PF_BOTTOM + 0.2   -- its back and front
  local BODY = "#16181d"
  wbox(0, -16, (Z0 + Z1) / 2, 2 * X0, 28, Z1 - Z0, BODY)
  for _, sx in ipairs({ -1, 1 }) do
    local x = sx * (X0 + 0.06)
    -- three stripes the length of the cabinet
    for i, s in ipairs({ { -7.5, YELLOW }, { -10.5, ORANGE }, { -13.5, HOT } }) do
      wbox(x, s[1], (Z0 + Z1) / 2, 0.1, 2.2, Z1 - Z0, s[2])
    end
    -- and slashes toward the front
    for k = 0, 4 do
      local z = -40 + 11 * k
      wbox(x, -21, z, 0.12, 12, 2.2, (k % 2 == 0) and CYAN or PURPLE,
           btQuaternion(xAxisV, math.rad(-35)))
    end
    -- chrome side rail along the top edge
    wbox(sx * (X0 - 1.6), 1, (-121 + Z1) / 2, 3.6, 6, Z1 + 121, "#c8ccd2")
    -- the flipper button
    local fb = Cylinder(0.9, 0.8, 0)
    fb.trans = btTransform(yRot(math.pi / 2), btVector3(sx * (X0 + 0.4), -5, 11))
    vis(fb, "#f1f1f1")
  end
  wbox(0, 0.5, Z1 - 1.1, 2 * X0 + 0.4, 5, 2.2, "#c8ccd2")      -- lockdown bar
  -- the coin door and start button
  wbox(0, -18, Z1 + 0.25, 18, 18, 0.5, "#2a2a2e")
  for _, f in ipairs({ { 0, -9.2, 18.6, 0.6 }, { 0, -26.8, 18.6, 0.6 }, { -9.1, -18, 0.6, 18 }, { 9.1, -18, 0.6, 18 } }) do
    wbox(f[1], f[2], Z1 + 0.55, f[3], f[4], 0.3, "#c8ccd2")
  end
  art.coin = {}
  for _, x in ipairs({ -4, 4 }) do
    wbox(x, -12.3, Z1 + 0.6, 1.4, 0.3, 0.3, "#050505")               -- the slot
    art.coin[#art.coin + 1] = wbox(x, -15.2, Z1 + 0.6, 2.4, 3.6, 0.3, "#ff2020")   -- lit price insert
  end
  wbox(0, -23.5, Z1 + 0.6, 3.5, 2.2, 0.3, "#050505")                -- coin return
  local sb = Cylinder(1.1, 1.0, 0)
  sb.pos = btVector3(-X0 + 4.5, -5, Z1 + 0.5)
  art.start = vis(sb, "#ff2020")

  -- legs, levellers, and the floor of the arcade
  for _, x in ipairs({ -X0 + 2.2, X0 - 2.2 }) do
    for _, z in ipairs({ Z0 + 4, Z1 - 4 }) do
      wbox(x, -32, z, 5.5, 4, 5.5, "#9aa0a8")                        -- the bracket
      wbox(x, -63, z, 3.6, 62, 3.6, "#c8ccd2")                       -- the leg
      local lv = Cylinder(1.8, 1.2, 0)
      lv.trans = btTransform(UPRIGHT, btVector3(x, -94.4, z))
      vis(lv, "#6b7078")
    end
  end
  for i = -5, 5 do
    for j = -6, 5 do
      wbox(i * 30, -95.6, -57 + j * 30, 30, 0.4, 30, ((i + j) % 2 == 0) and "#1b1b24" or "#262633")
    end
  end

  -- the backbox: its head around the scoreboard, and the marquee
  wbox(0, 24, -126.1, 2 * X0, 52, 10, BODY)
  wbox(0, 49.3, -120.9, 2 * X0, 1.2, 0.6, "#c8ccd2")
  for _, sx in ipairs({ -1, 1 }) do wbox(sx * (X0 - 0.6), 24, -120.9, 1.2, 52, 0.6, "#c8ccd2") end
  -- bulbs round the marquee, chasing
  local n = 0
  for i = 0, 17 do
    for _, y in ipairs({ 47.4, 34.4 }) do
      n = n + 1
      local b = Cylinder(0.55, 0.4, 0)
      b.pos = btVector3(-25.5 + i * 3, y, -119.9)
      art.bulbs[#art.bulbs + 1] = { obj = vis(b, DIM), i = i }
    end
  end

  -- a moment of light: chevrons chase toward the ramp and the orbit, the
  -- marquee's bulbs run round, the sunburst swaps its colours, and the
  -- coin inserts and start button blink while no game is running
  local phase = {}
  function board.artTick(N, gameOn)
    local c = math.floor(N / 7) % 4               -- chevrons: 1, 2, 3 lit in turn, then a rest
    if c ~= phase.c then
      phase.c = c
      for _, list in ipairs({ art.chase, art.rampChase }) do
        for _, ch in ipairs(list) do
          local col = (c < 3 and ch.k == 3 - c) and ch.on or DIM   -- (the farthest first)
          for _, arm in ipairs(ch.arms) do if arm.col ~= col then arm.col = col end end
        end
      end
    end
    local b = math.floor(N / 5) % 3
    if b ~= phase.b then
      phase.b = b
      for _, bulb in ipairs(art.bulbs) do
        bulb.obj.col = ((bulb.i + b) % 3 == 0) and YELLOW or (((bulb.i + b) % 3 == 1) and "#ffffff" or DIM)
      end
    end
    local r = math.floor(N / 40) % 2
    if r ~= phase.r then
      phase.r = r
      for _, ray in ipairs(art.rays) do
        ray.obj.col = ((ray.even and r == 0) or (not ray.even and r == 1)) and ray.a or ray.b
      end
    end
    local blink = gameOn and 1 or (math.floor(N / 30) % 2)
    if blink ~= phase.blink then
      phase.blink = blink
      local col = (blink == 1) and "#ff2020" or "#5a0808"
      art.start.col = col
      for _, coin in ipairs(art.coin) do coin.col = col end
    end
  end

  -- two views: the player's (at the lockdown bar), and the whole machine
  board.views = {
    { pos = btVector3(0, 92, 78), look = btVector3(0, 7, -42) },
    { pos = btVector3(105, 70, 95), look = btVector3(0, -22, -45) },
  }
  board.view = 1
  function board.setView(k)
    board.view = k
    local vw = board.views[k]
    common.setCamera(vw.pos, vw.look, 0.8, { up = btVector3(0, 1, 0) })
  end
end

-- ---------------------------------------------------------------------
-- the game: state and rules
-- ---------------------------------------------------------------------

-- Saved layouts and the high score live in bpp's settings under this
-- prefix. OLD_PREFS_PREFIX is where they were kept before the table was
-- named Pinball Machine A; they're read from there if not found here.
local PREFS_PREFIX, OLD_PREFS_PREFIX = "pinball-machine-a/", "time-fantasy/"
local frame = 0
local helpDirty = true   -- the Shortcuts pane needs refreshing

local game = {
  active = false,        -- a game is in progress
  score = 0, ball = 0, bonus = 0, multiplier = 1,
  extraBallLit = false, shootAgain = 0,
  ballsPerGame = rules.ballsPerGame,
  high = 0,
  serveAt = nil,         -- frame to serve the next ball, after a drain
  tilted = false,        -- this ball is tilted: flippers and coils dead
  warnings = 0,          -- tilt warnings this ball
  sway = 0, swayAt = 0,  -- the tilt bob's swing
  messageText = nil, messageUntil = 0,
}
do
  local ok, h = pcall(function()
    return v:loadPrefs(PREFS_PREFIX .. "highScore", v:loadPrefs(OLD_PREFS_PREFIX .. "highScore", "0"))
  end)
  game.high = tonumber(ok and h or "0") or 0
end

-- The banks from the rules, each with its switches and their lamps.
local banks = {}
for _, def in ipairs(rules.banks) do
  local bank = { def = def, members = {}, lit = {} }
  for i, name in ipairs(def.switches or {}) do
    bank.members[i] = switchByName[name]
    bank.lit[i] = false
  end
  banks[#banks + 1] = bank
end
local bankOf = {}     -- switch name -> bank, index
for _, bank in ipairs(banks) do
  for i, sw in ipairs(bank.members) do
    if sw then bankOf[sw.name] = { bank = bank, index = i } end
  end
end

-- Report rule entries that name a switch this table doesn't have.
do
  local unknown = {}
  local function check(name, where)
    if name and not switchByName[name] then unknown[#unknown + 1] = name .. " (" .. where .. ")" end
  end
  for name in pairs(rules.points) do
    if name ~= "addedBumper" and not name:match("^bumper%d+$") then check(name, "points") end
  end
  for _, def in ipairs(rules.banks) do
    for _, name in ipairs(def.switches or {}) do check(name, "bank " .. tostring(def.name)) end
  end
  if rules.extraBall then check(rules.extraBall.collectAt, "extraBall") end
  if rules.loop then check(rules.loop.switch, "loop") end
  if rules.ramp then check(rules.ramp.switch, "ramp") end
  if #unknown > 0 then
    print("Rules name switches this table doesn't have: " .. table.concat(unknown, ", "))
  end
end

-- the engine's entry points used by the rest of the table
local showLamps, message, serveBall, startGame, onSwitch, rotateBanks, ballDrained, nextBall
do
showLamps = function()
  for _, bank in ipairs(banks) do
    for i, sw in ipairs(bank.members) do
      if sw and sw.lamp then sw.lamp.set(bank.lit[i]) end
    end
  end
  for n, lp in pairs(multLamps) do lp.set(game.multiplier >= n) end
  if ramp.lamp then ramp.lamp.set(game.extraBallLit) end
  shootAgainLamp.set(game.shootAgain > 0)
end

message = function(text, seconds)
  game.messageText = text
  game.messageUntil = frame + math.floor((seconds or 3) / FRAME)
end

local function addScore(n) if game.active then game.score = game.score + n end end
local function addBonus(n) if game.active then game.bonus = game.bonus + n end end

local function advanceMultiplier()
  if game.multiplier < (rules.multiplier.max or 5) then
    game.multiplier = game.multiplier + 1
    message("BONUS " .. game.multiplier .. "X")
    playSound("multiplier")
  end
end

local function lightExtraBall()
  if not game.extraBallLit then
    game.extraBallLit = true
    message("HIT BLUE")
    playSound("extraBallLit")
  end
end

local function awardExtraBall()
  game.shootAgain = game.shootAgain + 1
  message("SHOOT AGAIN")
  playSound("extraBall")
end

-- The interface the rules file's onSwitch() sees.
local api = {
  addScore = addScore, addBonus = addBonus, advanceMultiplier = advanceMultiplier,
  lightExtraBall = lightExtraBall, awardExtraBall = awardExtraBall,
  playSound = function(event) playSound(event) end, message = message,
}
local function refreshApi()
  api.score, api.ball, api.bonus, api.multiplier = game.score, game.ball, game.bonus, game.multiplier
  api.ballsPerGame = game.ballsPerGame
end

local function resetBallState()
  game.bonus, game.multiplier = 0, 1
  game.tilted, game.warnings, game.sway = false, 0, 0
  game.loopValue = rules.loop and rules.loop.start or 0
  game.rampValue = rules.ramp and rules.ramp.start or 0
  for _, bank in ipairs(banks) do
    for i in ipairs(bank.lit) do bank.lit[i] = false end
  end
end

serveBall = function()
  placeBall(SHOOT_U, SHOOT_W)
  playSound("ballServe")
end

startGame = function()
  game.active = true
  helpDirty = true
  game.score, game.ball, game.shootAgain = 0, 1, 0
  game.extraBallLit = false
  game.serveAt = nil
  resetBallState()
  message("BALL 1", 2)
  playSound("gameStart")
end

local function endGame()
  game.active = false
  helpDirty = true
  if game.score > game.high then
    game.high = game.score
    pcall(function() v:savePrefs(PREFS_PREFIX .. "highScore", tostring(game.high)) end)
    message("HIGH SCORE", 6)
    playSound("highScore")
  else
    message("END  PRESS 1", 600)
    playSound("gameOver")
  end
end

local function completeBank(bank)
  local def = bank.def
  addScore(def.completePoints or 0)
  playSound("bankComplete")
  if def.onComplete == "advanceMultiplier" then advanceMultiplier()
  elseif def.onComplete == "lightExtraBall" then lightExtraBall()
  elseif def.onComplete == "extraBall" then awardExtraBall() end
  for i in ipairs(bank.lit) do bank.lit[i] = false end
end

-- A switch was hit. Plays its sound always; scores only during a game.
onSwitch = function(sw)
  if game.tilted then return end        -- a tilted machine is dead
  local name = sw.name
  playSound(sw.cat, name)
  if not game.active then return end
  addScore(rules.points[name]
           or (sw.cat == "bumper" and (rules.points.addedBumper or 100)) or 0)
  local b = bankOf[name]
  if b then
    local def = b.bank.def
    if b.bank.lit[b.index] then
      addScore(def.repeatPoints or 0)
    else
      b.bank.lit[b.index] = true
      addScore(def.litPoints or 0)
      addBonus(def.bonusPerLit or 0)
      local all = true
      for _, lit in ipairs(b.bank.lit) do all = all and lit end
      if all then completeBank(b.bank) end
    end
  end
  if rules.extraBall and name == rules.extraBall.collectAt and game.extraBallLit then
    game.extraBallLit = false
    awardExtraBall()
  end
  if rules.loop and name == rules.loop.switch then
    addScore(game.loopValue)
    message("LOOP " .. game.loopValue, 2)
    game.loopValue = math.min(game.loopValue + (rules.loop.step or 0), rules.loop.max or math.huge)
  end
  if rules.ramp and name == rules.ramp.switch then
    addScore(game.rampValue)
    message("RAMP " .. game.rampValue, 2)
    game.rampValue = math.min(game.rampValue + (rules.ramp.step or 0), rules.ramp.max or math.huge)
  end
  if rules.onSwitch then
    refreshApi()
    local ok, err = pcall(rules.onSwitch, api, name)
    if not ok then print("rules onSwitch: " .. tostring(err)) end
  end
end

-- A flipper button was pressed: banks with flippersRotate shift their lit
-- lamps one place (left flipper left, right flipper right).
rotateBanks = function(side)
  if not game.active then return end
  for _, bank in ipairs(banks) do
    if bank.def.flippersRotate then
      local lit, n = bank.lit, #bank.lit
      local rotated = {}
      for i = 1, n do
        local from = side < 0 and (i % n) + 1 or ((i - 2) % n) + 1
        rotated[i] = lit[from]
      end
      bank.lit = rotated
    end
  end
end

ballDrained = function()
  playSound("drain")
  if not game.active then return end
  local total = game.tilted and 0 or game.bonus * game.multiplier   -- (no bonus after a tilt)
  if total > 0 then
    addScore(total)
    message("BONUS " .. total, 2)
    playSound("bonusCount")
  end
  game.serveAt = frame + SERVE_DELAY
end

-- called SERVE_DELAY frames after a drain
nextBall = function()
  game.serveAt = nil
  if game.shootAgain > 0 then
    game.shootAgain = game.shootAgain - 1
    resetBallState()
    message("SHOOT AGAIN", 2)
    serveBall()
  elseif game.ball < game.ballsPerGame then
    game.ball = game.ball + 1
    resetBallState()
    message("BALL " .. game.ball, 2)
    serveBall()
  else
    endGame()
  end
end

end

-- ---------------------------------------------------------------------
-- geometry helpers
-- ---------------------------------------------------------------------

local function distPointSeg(pu, pw, au, aw, bu, bw)
  local du, dw = bu - au, bw - aw
  local l2 = du * du + dw * dw
  local t = l2 > 0 and ((pu - au) * du + (pw - aw) * dw) / l2 or 0
  t = math.max(0, math.min(1, t))
  local qu, qw = au + t * du - pu, aw + t * dw - pw
  return math.sqrt(qu * qu + qw * qw)
end

local function cross(ou, ow, au, aw, bu, bw)
  return (au - ou) * (bw - ow) - (aw - ow) * (bu - ou)
end

-- distance between segments p0-p1 and a-b (0 if they cross)
local function distSegSeg(p0u, p0w, p1u, p1w, au, aw, bu, bw)
  local d1, d2 = cross(au, aw, bu, bw, p0u, p0w), cross(au, aw, bu, bw, p1u, p1w)
  local d3, d4 = cross(p0u, p0w, p1u, p1w, au, aw), cross(p0u, p0w, p1u, p1w, bu, bw)
  if d1 * d2 < 0 and d3 * d4 < 0 then return 0 end
  return math.min(distPointSeg(p0u, p0w, au, aw, bu, bw),
                  distPointSeg(p1u, p1w, au, aw, bu, bw),
                  distPointSeg(au, aw, p0u, p0w, p1u, p1w),
                  distPointSeg(bu, bw, p0u, p0w, p1u, p1w))
end

-- ---------------------------------------------------------------------
-- coils: bumpers and slingshots kick the ball when it touches them
-- ---------------------------------------------------------------------

-- Replace the ball's velocity component along (nu, nw) with an outward kick.
local function kick(nu, nw, speed)
  local vel = ball.vel
  local vu, vw = vel.x, -vel.z
  local along = vu * nu + vw * nw
  if along < 0 then vu, vw = vu - along * nu, vw - along * nw end
  vu, vw = vu + nu * speed, vw + nw * speed
  ball.vel = btVector3(vu, vel.y, -vw)
end

local function fireBumper(b)
  local u, w = ballUW()
  local du, dw = u - b.u, w - b.w
  local d = math.sqrt(du * du + dw * dw)
  if d > 1e-3 then kick(du / d, dw / d, BUMPER_KICK) end
  b.flash = 6
  b.cap.col = "#ffd60a"
end

local function driveFlippers()
  -- (the motors' impulses are per simulation step, tuned at 600 steps a
  -- second; run faster -- the rec room runs at 900 -- they're scaled down
  -- so the flippers feel the same)
  local k = 600 * (v.fixedTimeStep or (1 / 600))
  for side, f in pairs(flippers) do
    local dir = (side < 0) and 1 or -1
    if f.pressed and not game.tilted then
      f.hinge:enableAngularMotor(true, dir * FLIP_UP_VEL, FLIP_UP_IMPULSE * k)
    else
      f.hinge:enableAngularMotor(true, -dir * FLIP_DN_VEL, FLIP_DN_IMPULSE * k)
    end
  end
end

-- ---------------------------------------------------------------------
-- LAYOUT EDITOR: until the first ball is launched, parts of the table can
-- be moved with the keyboard (see the Shortcuts pane). Moving an item
-- moves its parts and its switches together. The layout is saved in bpp's
-- settings when editing ends and restored on the next run.
-- ---------------------------------------------------------------------

local EDIT_ORDER = { "lanes", "bumper1", "bumper2", "bumper3", "arch", "orbit", "exit", "lower", "ramp" }
local EDIT_KEYS = { M = "ramp", L = "lanes", ["1"] = "bumper1", ["2"] = "bumper2", ["3"] = "bumper3",
                    A = "arch", O = "orbit", X = "exit", F = "lower" }
-- Arrow keys: a tap moves EDIT_STEP; holding one slides the selection,
-- starting after EDIT_HOLD seconds at EDIT_SLIDE cm/s and speeding up to
-- EDIT_SLIDE_MAX. It runs on real time, not frames, so it moves at the
-- same speed however fast or slow bpp is drawing.
local EDIT_STEP = 0.5          -- cm per arrow tap
local EDIT_HOLD = 0.3          -- seconds held before sliding starts
local EDIT_SLIDE = 10          -- cm/s when sliding starts
local EDIT_SLIDE_MAX = 40      -- cm/s after holding a while
local EDIT_ACCEL = 20          -- cm/s gained per second of sliding
local EDIT_REPEAT_GAP = 0.04   -- a release and press closer than this is
                               -- one held key (some systems send held keys
                               -- as rapid release/press pairs)
local function now()
  if TF and TF.clock then return TF.clock() end    -- scripted tests' clock
  return v.getTime and v:getTime() or frame * FRAME
end

-- ---------------------------------------------------------------------
-- shaking the machine (Space). A shove on the front of the cabinet: the
-- ball gets a push up the table (and a little to one side or the other),
-- and the view jolts. Each shove swings the tilt bob; swing it too far
-- and it's a warning (DANGER), and after the rules' number of warnings in
-- one ball the next is a TILT: flippers, bumpers and slingshots go dead,
-- nothing scores, and the ball is lost with no bonus.
-- ---------------------------------------------------------------------

local nudger = { shake = nil }    -- shake: the view's jolt in progress { pos, look, frames }

function nudger.nudge()
  local vel = ball.vel
  local side = (math.random() - 0.5) * 0.6
  ball.vel = btVector3(vel.x + side * rules.tilt.nudge, vel.y, vel.z - rules.tilt.nudge)
  playSound("nudge")
  if nudger.shake then nudger.shake.frames = 0
  else pcall(function() nudger.shake = { pos = v.cam.pos, look = v.cam.look, frames = 0 } end) end
  if not (game.active and rules.tilt.warnings and not game.tilted) then return end
  local t = now()
  game.sway = math.max(0, game.sway - rules.tilt.settle * (t - game.swayAt)) + 1
  game.swayAt = t
  if game.sway > rules.tilt.sway then
    game.sway = 0
    game.warnings = game.warnings + 1
    if game.warnings > rules.tilt.warnings then
      game.tilted = true
      for _, f in pairs(flippers) do f.pressed = false end
      message("TILT", 3)
      playSound("tilt")
    else
      message("DANGER", 2)
      playSound("tiltWarning")
    end
  end
end

-- the jolt: the view moves forward and back over a fifth of a second
function nudger.tick()
  local shake = nudger.shake
  if not shake then return end
  shake.frames = shake.frames + 1
  local k = shake.frames
  if k >= 12 then
    pcall(function() v.cam.pos = shake.pos; v.cam.look = shake.look end)
    nudger.shake = nil
    return
  end
  local a = 0.9 * math.sin(k * math.pi / 3) * (1 - k / 12)
  local p, l = shake.pos, shake.look
  pcall(function()
    v.cam.pos = btVector3(p.x + 0.3 * a, p.y + 0.2 * a, p.z - a)
    v.cam.look = btVector3(l.x + 0.3 * a, l.y + 0.2 * a, l.z - a)
  end)
end

-- the area the lanes and bumpers must stay inside (table coordinates, cm)
local EDIT_AREA = { umin = L + 1.0, umax = LANE_IN - 0.8, wmin = 36 }
local ARROWS = { Left = { -1, 0 }, Right = { 1, 0 }, Up = { 0, 1 }, Down = { 0, -1 } }

local editing = true
local selected = nil           -- key into editItems
local heldArrows = {}          -- arrow key name -> time it was pressed
local releasedArrows = {}      -- arrow key name -> { at = time, since = press time }
local lastSlideAt = nil        -- time of the last slide step
local blockedMsg = nil         -- why the last move was refused
local editState = {}           -- odds and ends: rebuiltAt, ...

-- The default layout, as offsets from where each item is built: lower
-- flippers, which keep the ball in play (and off the left side) better,
-- with the bumpers and ramp entrance to suit. A layout with no saved
-- settings starts here, and 0 and R in the editor come back here. (It was
-- worked out in play: the computer player averaged 80-90,000 on it against
-- about 57,000 with everything where it's built.)
editState.HOME = {
  lanes = { 4.5, 0 }, bumper1 = { 4.9, -28.8 }, bumper2 = { -1.4, -0.5 }, bumper3 = { -5.1, -1.3 },
  arch = { 2.5, 1.5 }, orbit = { 2.5, 0 }, exit = { 0, 0 }, lower = { 0, -5 },
  ramp = { -0.6, -9.9, 0 },
}
function editState.home(key)
  local h = editState.HOME[key] or { 0, 0 }
  return h[1], h[2], h[3] or 0
end

-- Record where an item was built, so offsets are measured from there.
function editState.initItem(item)
  item.du, item.dw = 0, 0
  for _, sw in ipairs(item.switches) do
    sw.base = { a = sw.a and { sw.a[1], sw.a[2] }, b = sw.b and { sw.b[1], sw.b[2] },
                c = sw.c and { sw.c[1], sw.c[2] } }
  end
  if item.bumper then item.u0, item.w0 = item.bumper.u, item.bumper.w end
end
for _, key in ipairs(EDIT_ORDER) do editState.initItem(editItems[key]) end

local function clamp(x, lo, hi) return math.max(lo, math.min(hi, x)) end
local setOffsetRef   -- setOffset, for hooks defined before it

-- Does a ball fit between the orbit exit wall and a post at (pu, pw)
-- (radius pr)? Joined (touching or overlapping) is fine too; a gap
-- narrower than the ball is a trap.
local function exitClearOf(pu, pw, pr, du, dw)
  local eu, ew = exitEndFor(du, dw)
  local gap = distPointSeg(pu, pw, L, 44, eu, ew) - pr - 0.3
  return gap <= 0.1 or gap >= 2 * BALL_R + 0.1
end

-- Is the exit wall clear of the inlane guide's and the slingshot's top
-- posts, for these exit and lower-group offsets?
local function exitCheck(exDu, exDw, loDu, loDw)
  if not exitClearOf(-GUIDE_U + loDu, GUIDE_TOP + loDw, 0.4, exDu, exDw) then
    return false, "the ball could get stuck between the orbit exit and the inlane guide's post"
  end
  if not exitClearOf(-SLING_BACK_U + loDu, SLING_TOP + loDw, 0.4, exDu, exDw) then
    return false, "the ball could get stuck between the orbit exit and the slingshot"
  end
  return true
end

-- Limits for the items whose parts depend on each other. Each returns
-- true, or false and the reason.
-- Where the arch slopes (its corners), a ball rolling down it can wedge
-- between the arch and a lane post or bumper below if the gap is just
-- about the ball's size: measured, gaps of 2.9-3.1 cm trapped it, while
-- narrower gaps (the ball can't get in) and wider ones (it rolls through)
-- didn't. So under a corner a gap from 2.7 to 3.3 cm is refused.
local function underCorner(u, du, dw)
  local H, rL, rR = archShapeFor(du, dw)
  return u > R - rR or u < L + rL
end
local function gapOK(gap, corner)
  return not corner or gap < 2 * BALL_R or gap > 2 * BALL_R + 0.6
end

local function lanesFitUnderArch(laneDu, laneDw, archDu, archDw)
  local top = LANE_W0 + 8 + laneDw + 0.5
  for _, u0 in ipairs(laneEdges) do
    local u = u0 + laneDu
    local gap = archUndersideFor(u, archDu, archDw) - top
    if gap < -1 or not gapOK(gap, underCorner(u, archDu, archDw)) then return false end
  end
  return true
end

-- Does a bumper at (u, w) stay clear of the arch without a trapping gap?
local function bumperFitsUnderArch(u, w, archDu, archDw)
  local rr = BUMPER_R + 0.6
  local minGap, corner = math.huge, false
  for k = -4, 4 do
    local uu = u + rr * k / 4
    local top = w + math.sqrt(math.max(0, rr * rr - (uu - u) ^ 2))
    local gap = archUndersideFor(uu, archDu, archDw) - top
    if gap < minGap then minGap, corner = gap, underCorner(uu, archDu, archDw) end
  end
  return minGap > 0.2 and gapOK(minGap, corner)
end

arch.valid = function(it, du, dw)
  local H, rL, rR = archShapeFor(du, dw)
  if H > PF_TOP - 1 then return false, "the arch is at the top of the playfield" end
  if rL < 6 or rR < 6 then return false, "a corner can't be tighter than 6 cm" end
  if H - rR < 76 then return false, "the shooter lane can't get any shorter" end
  if H - rL - 1.5 < ORBIT_TOP_MIN + orbit.dw then
    return false, "the left corner would reach the orbit's targets (move the orbit down first)"
  end
  -- the lanes ride up and down with the arch (see arch.carry)
  local laneDw = lanes.dw + (dw - arch.dw)
  if lanes.wmin + laneDw < EDIT_AREA.wmin then return false, "the lanes can't go any lower" end
  if not lanesFitUnderArch(lanes.du, laneDw, du, dw) then
    return false, "the ball could get stuck between the arch and the rollover lanes (move them first)"
  end
  for _, key in ipairs({ "bumper1", "bumper2", "bumper3" }) do
    local b = editItems[key].bumper
    if not bumperFitsUnderArch(b.u, b.w, du, dw) then
      return false, "the ball could get stuck between the arch and " .. editItems[key].label
    end
  end
  return true
end
orbit.valid = function(it, du, dw)
  local H, rL = archShape()
  if du < -0.3 then return false, "the orbit can't get narrower than this" end
  if du > 9 then return false, "the orbit wall is as far out as it goes" end
  if dw < -4 then return false, "the entrance would meet the angled wall below it" end
  if ORBIT_TOP_MIN + dw > H - rL - 1.5 then
    return false, "the orbit's targets would reach the arch (raise the arch first)"
  end
  return true
end
lanes.valid = function(it, du, dw)
  if lanes.umin + du < EDIT_AREA.umin or lanes.umax + du > EDIT_AREA.umax then
    return false, "that's as far as the lanes go"
  end
  if lanes.wmin + dw < EDIT_AREA.wmin then return false, "that's as low as the lanes go" end
  if not lanesFitUnderArch(du, dw, arch.du, arch.dw) then
    return false, "the ball could get stuck between the lanes and the arch"
  end
  return true
end
exitWall.valid = function(it, du, dw)
  local eu, ew = exitEndFor(du, dw)
  if eu < -LANE_IN then return false, "the exit can't end left of the outlane" end
  if eu > -10.5 then return false, "that's as far right as the exit goes" end
  if ew < 24 then return false, "that's as low as the exit goes" end
  if ew > 42 then return false, "that's as high as the exit goes" end
  return exitCheck(du, dw, lower.du, lower.dw)
end

-- The outlanes lie between the (fixed) outer walls and the inlane guides,
-- which move with the lower group; a ball is 2.7 cm across.
local function outlaneWidths(du)
  local faceL, faceR = -LANE_IN + 0.3, LANE_IN - 0.3        -- outer walls' inner faces
  return (-GUIDE_U + du - 0.25) - faceL, faceR - (GUIDE_U + du + 0.25)
end
lower.valid = function(it, du, dw)
  local wl, wr = outlaneWidths(du)
  if wl < 0.2 then return false, "the left inlane guide would hit the outer wall" end
  if wr < 0.2 then return false, "the right inlane guide would hit the shooter lane wall" end
  if dw < -5 then return false, "the flippers would reach the drain" end
  if dw > 12 then return false, "that's as high as they go" end
  return exitCheck(exitWall.du, exitWall.dw, du, dw)
end
lower.afterMove = function(it)
  for side, f in pairs(it.flippers) do
    mountFlipper(f, side * FLIP_PIVOT_U + it.du, FLIP_PIVOT_W + it.dw)
  end
end
arch.applyFn = function(it) it.built = false end       -- rebuilt by editorTick
-- Raising or lowering the arch takes the rollover lanes with it, keeping
-- the gap that feeds plunged balls into them.
arch.carry = function(it, ddu, ddw)
  if ddw ~= 0 then setOffsetRef(lanes, lanes.du, lanes.dw + ddw, true) end
end
exitWall.applyFn = function(it) it.built = false end   -- likewise
orbit.afterMove = function(it) orbitTop.built = false end   -- rebuilt by editorTick

-- descriptions for the Shortcuts pane
local function itemCentre(item)
  return (item.umin + item.umax) / 2 + item.du, (item.wmin + item.wmax) / 2 + item.dw
end
arch.describe = function(it)
  local H, rL, rR = archShape()
  return string.format("top %.1f up, corners %.1f (left) / %.1f (right) cm radius", H, rL, rR)
end
orbit.describe = function(it)
  return string.format("entrance post %.1f across, %.1f up; lane %.1f wide",
                       -19.2 + it.du, 50 + it.dw, (-21.5 + it.du) - L)
end
exitWall.describe = function(it)
  local eu, ew = exitEndFor(it.du, it.dw)
  local guide = -GUIDE_U + lower.du
  local over = eu <= -LANE_IN + 0.3 and "on the outlane wall: orbit balls drain"
            or eu < guide and "over the outlane"
            or eu < -SLING_BACK_U + lower.du and "over the inlane: orbit balls return"
            or "past the inlane"
  return string.format("ends %.1f across, %.1f up (%s)", eu, ew, over)
end
lower.describe = function(it)
  local wl, wr = outlaneWidths(it.du)
  local function lane(wd) return wd < 2 * BALL_R + 0.1 and "closed" or string.format("%.1f wide", wd) end
  return string.format("flipper pivots %.1f / %.1f across, %.1f up; outlanes: left %s, right %s",
                       -FLIP_PIVOT_U + it.du, FLIP_PIVOT_U + it.du, FLIP_PIVOT_W + it.dw,
                       lane(wl), lane(wr))
end
local function describe(item)
  if item.describe then return item.describe(item) end
  local u, w = itemCentre(item)
  return string.format("%.1f across, %.1f up", u, w)
end

-- Set an item's offset and move everything in it. Returns false and the
-- reason if a limit refuses it (unless `force`, used to restore a saved
-- layout, which was valid when it was saved).
local function setOffset(item, du, dw, force)
  if not force then
    if item.valid then
      local ok, why = item.valid(item, du, dw)
      if not ok then return false, why end
    else
      du = clamp(du, EDIT_AREA.umin - item.umin, EDIT_AREA.umax - item.umax)
      dw = clamp(dw, EDIT_AREA.wmin - item.wmin, PF_TOP - item.wmax)
      if item.underArch and not bumperFitsUnderArch(item.u0 + du, item.w0 + dw, arch.du, arch.dw) then
        return false, "the ball could get stuck between it and the arch"
      end
    end
  end
  -- (whatever moves mustn't make the ramp clash with it -- if the ramp
  -- clashes with something already, that's for moving the ramp to fix)
  if not force and item ~= rampway and rampway.check(rampway.du, rampway.dw, rampway.da) then
    local odu, odw = item.du, item.dw
    local ob = item.bumper and { item.bumper.u, item.bumper.w }
    item.du, item.dw = du, dw
    if ob then item.bumper.u, item.bumper.w = item.u0 + du, item.w0 + dw end
    local ok, why = rampway.check(rampway.du, rampway.dw, rampway.da)
    item.du, item.dw = odu, odw
    if ob then item.bumper.u, item.bumper.w = ob[1], ob[2] end
    if not ok then return false, why .. " (move the ramp first: M)" end
  end
  if not force and item.carry then item.carry(item, du - item.du, dw - item.dw) end
  item.du, item.dw = du, dw
  if item.applyFn then
    item.applyFn(item)
  else
    for _, part in ipairs(item.parts) do
      part.obj.trans = btTransform(part.q, P(part.u + item.du, part.w + item.dw, part.y))
    end
    for _, sw in ipairs(item.switches) do
      for _, k in ipairs({ "a", "b", "c" }) do
        if sw.base[k] then
          local fixU = (k == "a" and sw.fixA) or (k == "b" and sw.fixB)
          sw[k] = { sw.base[k][1] + (fixU and 0 or item.du), sw.base[k][2] + item.dw }
        end
      end
    end
  end
  if item.bumper then
    item.bumper.u, item.bumper.w = item.u0 + item.du, item.w0 + item.dw
  end
  if item.afterMove then item.afterMove(item) end
  -- the ramp drops balls into the left inlane, wherever that is
  if item == lower or item == exitWall then rampway.built = false end
  helpDirty = true
  return true
end

setOffsetRef = setOffset

local function highlight(item, on)
  local function paint(parts)
    for _, part in ipairs(parts) do
      if not part.isLamp then part.obj.col = on and "#7cfc00" or part.col0 end
    end
  end
  paint(item.parts)
  if item.extra then paint(item.extra.parts) end
  for _, f in pairs(item.flippers or {}) do
    f.body.col = on and "#7cfc00" or f.col0
  end
end

local function selectItem(key)
  blockedMsg = nil
  if selected then highlight(editItems[selected], false) end
  selected = key
  if selected then highlight(editItems[selected], true) end
  helpDirty = true
end

-- A move that lands in a spot where the ball could get trapped (a gap
-- about the ball's size) is carried on in the same direction, up to
-- EDIT_SKIP cm, to the first safe spot -- so such spots are stepped over
-- rather than acting as walls. A real limit still stops the move.
local EDIT_SKIP = 3.5
local function moveSelected(du, dw)
  if not selected then return end
  local item = editItems[selected]
  local ok, why = setOffset(item, item.du + du, item.dw + dw)
  if not ok and why and why:find("stuck") then
    local len = math.sqrt(du * du + dw * dw)
    local k = 1
    while not ok and len * k < EDIT_SKIP do
      k = k + 1
      ok = setOffset(item, item.du + du * k, item.dw + dw * k)
    end
    if ok then why = nil end
  end
  if not ok and why ~= blockedMsg then
    blockedMsg, helpDirty = why, true
  elseif ok and blockedMsg then
    blockedMsg, helpDirty = nil, true
  end
end

-- rebuild whatever an edit left unbuilt (the arch and the orbit exit)
local function rebuildPending()
  if not arch.built then buildArch()                 -- (includes the orbit top)
  elseif not orbitTop.built then buildOrbitTop() end
  if not exitWall.built then buildExit() end
  if not rampway.built then rampway.build() end
  if selected then highlight(editItems[selected], true) end
end

-- ---------------------------------------------------------------------
-- added pop bumpers (B adds one, Delete removes the selected one)
-- ---------------------------------------------------------------------

local MAX_BUMPERS = 9          -- keys 1-9

-- Is (u, w) a sensible place for a new bumper: on the playfield, under
-- the arch, below the lanes, clear of the side targets, and far enough
-- from every other bumper for the ball to pass between them?
function editState.bumperSpotFree(u, w, except)
  local rr = BUMPER_R + 0.6
  if u - rr < EDIT_AREA.umin or u + rr > EDIT_AREA.umax or math.abs(u) > 15 then return false end
  if w - rr < EDIT_AREA.wmin or w + rr > lanes.wmin + lanes.dw - 3 then return false end
  if not bumperFitsUnderArch(u, w, arch.du, arch.dw) then return false end
  for _, b in ipairs(bumpers) do
    if b ~= except and math.sqrt((b.u - u) ^ 2 + (b.w - w) ^ 2) < 2 * rr + 2 * BALL_R + 0.6 then
      return false
    end
  end
  return true
end

-- Add pop bumper number `num` at (u, w), or at the free spot nearest the
-- middle of the playfield. Returns its item key, or nil and the reason.
function editState.addBumper(num, u, w)
  if not num then
    for n = 4, MAX_BUMPERS do
      if not editItems["bumper" .. n] then num = n; break end
    end
    if not num then return nil, "there are already " .. MAX_BUMPERS .. " bumpers" end
  end
  if not u then
    local best, bestD
    for cu = -14, 14, 2 do
      for cw = 44, 90, 2 do
        if editState.bumperSpotFree(cu, cw) then
          local d = (cu + 3) ^ 2 + (cw - 60) ^ 2
          if not bestD or d < bestD then best, bestD = { cu, cw }, d end
        end
      end
    end
    if not best then return nil, "there's no free space for another bumper" end
    u, w = best[1], best[2]
  end
  bumper("bumper" .. num, u, w, "pop bumper " .. num .. " (added)", num)
  local key = "bumper" .. num
  local item = editItems[key]
  item.added = true
  editState.initItem(item)
  -- keep bumpers together in the order, by number
  local at = 1
  for i, k in ipairs(EDIT_ORDER) do
    local other = editItems[k]
    if other.num and other.num < num then at = i + 1 end
  end
  table.insert(EDIT_ORDER, at, key)
  EDIT_KEYS[tostring(num)] = key
  return key
end

function editState.removeBumper(key)
  local item = editItems[key]
  if not item or not item.added then return end
  if selected == key then selected = nil end
  removeParts(item.parts)
  local b, sw = item.bumper, item.switches[1]
  for i, x in ipairs(bumpers) do if x == b then table.remove(bumpers, i); break end end
  for i, x in ipairs(switches) do if x == sw then table.remove(switches, i); break end end
  switchByName[sw.name] = nil
  for i, k in ipairs(EDIT_ORDER) do if k == key then table.remove(EDIT_ORDER, i); break end end
  EDIT_KEYS[tostring(item.num)] = nil
  editItems[key] = nil
end

-- R: everything back where it was built, and added bumpers removed. (What
-- was saved stays saved until editing ends, so reloading the table brings
-- a saved layout back.)
function editState.resetLayout()
  selectItem(nil)
  local keys = {}
  for _, key in ipairs(EDIT_ORDER) do keys[#keys + 1] = key end
  for _, key in ipairs(keys) do
    if editItems[key].added then editState.removeBumper(key) end
  end
  rampway.da = select(3, editState.home("ramp"))
  for _, key in ipairs(EDIT_ORDER) do
    local hu, hw = editState.home(key)
    setOffset(editItems[key], hu, hw, true)
  end
  rebuildPending()
  blockedMsg = "layout reset to the default"
  helpDirty = true
end

local function saveLayout()
  local added = {}
  for _, key in ipairs(EDIT_ORDER) do
    local item = editItems[key]
    local value
    if item.added then
      -- an added bumper is saved where it is, and rebuilt there
      added[#added + 1] = tostring(item.num)
      value = string.format("@%.2f,%.2f", item.bumper.u, item.bumper.w)
    elseif item == rampway then
      value = string.format("%.2f,%.2f,%.2f", item.du, item.dw, item.da)   -- (and its turn)
    else
      value = string.format("%.2f,%.2f", item.du, item.dw)
    end
    pcall(function() v:savePrefs(PREFS_PREFIX .. key, value) end)
  end
  pcall(function() v:savePrefs(PREFS_PREFIX .. "addedBumpers", table.concat(added, ",")) end)
end

local function loadLayout()
  local function pref(key)
    local ok, saved = pcall(function()
      return v:loadPrefs(PREFS_PREFIX .. key, v:loadPrefs(OLD_PREFS_PREFIX .. key, ""))
    end)
    return ok and saved or ""
  end
  for n in pref("addedBumpers"):gmatch("%d+") do
    local u, w = pref("bumper" .. n):match("^@(%-?[%d.]+),(%-?[%d.]+)$")
    if u then editState.addBumper(tonumber(n), tonumber(u), tonumber(w)) end
  end
  for _, key in ipairs(EDIT_ORDER) do
    if not editItems[key].added then
      local du, dw, da = pref(key):match("^(%-?[%d.]+),(%-?[%d.]+),?(%-?[%d.]*)$")
      local hu, hw, ha = editState.home(key)          -- (nothing saved: the default)
      if key == "ramp" then rampway.da = tonumber(da) or (du and 0 or ha) end
      setOffset(editItems[key], tonumber(du) or hu, tonumber(dw) or hw, true)
    end
  end
  rebuildPending()
end

-- ---------------------------------------------------------------------
-- the Shortcuts pane
-- ---------------------------------------------------------------------

local PLAY_HELP = [[
PLAY
  Return              hold to pull the plunger, release to launch
                      (launching with no game running starts one)
  Left/Right Shift    flippers (Z and / also work)
  Space               shake (nudge) the machine: a push up the table.
                      Too often and you get DANGER, then TILT (the ball is lost)
  1                   start a new game (when no game is running)
  P                   the computer plays, learning as it goes (P again to stop)
  V                   the view: the player's, or the whole machine
Rules: ]] .. RULES_FILE .. [[  (edit, then reload the table: R during play, or Ctrl+R)
Sounds: put files in ]] .. SOUND_DIR

local function commas(n)
  local s = tostring(math.floor(n))
  while true do
    local t, k = s:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
    s = t
    if k == 0 then return s end
  end
end

local function helpText()
  local lines = {}
  if editing then
    local status = "nothing selected -- press L, a bumper's number, A, O, X, F or M"
    if selected then
      status = editItems[selected].label .. ": " .. describe(editItems[selected])
      if blockedMsg then status = status .. "  -- can't go further: " .. blockedMsg end
    elseif blockedMsg then
      status = status .. "  (" .. blockedMsg .. ")"
    end
    local nums = {}
    for _, key in ipairs(EDIT_ORDER) do
      if editItems[key].num then nums[#nums + 1] = tostring(editItems[key].num) end
    end
    lines[#lines + 1] = "LAYOUT EDITOR: " .. status .. "   (E = done)"
    lines[#lines + 1] = "  L          select the rollover lanes (as a group)"
    lines[#lines + 1] = string.format("  %-10s select that pop bumper (1 left, 2 right, 3 bottom, 4+ added)",
                                      table.concat(nums, " "))
    lines[#lines + 1] = "  B          add a pop bumper (it appears selected, ready to move)"
    lines[#lines + 1] = "  Delete     remove the selected added bumper"
    lines[#lines + 1] = "  A          select the top arch: Up/Down raise or lower it (the rollover lanes"
    lines[#lines + 1] = "             come with it), Left/Right shift its flat top (one corner"
    lines[#lines + 1] = "             tightens, the other widens)"
    lines[#lines + 1] = "  O          select the orbit entrance: its inner wall, post and targets"
    lines[#lines + 1] = "  X          select the orbit exit: move its lower end over the inlane"
    lines[#lines + 1] = "             to return balls coming down the orbit, or the outlane to drain them"
    lines[#lines + 1] = "  F          select the flippers, inlane guides and slingshots (together)"
    lines[#lines + 1] = "  M          select the ramp: the arrows move its entrance, , and . turn it"
    lines[#lines + 1] = "             (the rest follows; it always drops the ball into the left inlane)"
    lines[#lines + 1] = "  arrows     move the selection: tap = 0.5 cm; hold to slide (speeds up as you hold)"
    lines[#lines + 1] = "  0          put the selection back where it is in the default layout"
    lines[#lines + 1] = "  R          reset the whole layout to the default (added bumpers go too;"
    lines[#lines + 1] = "             your saved layout is kept until you press E -- reload to get it back)"
    lines[#lines + 1] = "  E          finish editing and save the layout (launching the ball also finishes)"
    lines[#lines + 1] = ""
    lines[#lines + 1] = "All positions, cm (across from the centre line, up from the bottom):"
    for _, key in ipairs(EDIT_ORDER) do
      local item = editItems[key]
      lines[#lines + 1] = string.format("  %s %-22s %s",
                                        key == selected and ">" or " ", item.label, describe(item))
    end
    lines[#lines + 1] = ""
  else
    local status
    if game.active then
      status = string.format("SCORE %s   BALL %d of %d   BONUS %s x%d   HIGH %s",
                             commas(game.score), game.ball, game.ballsPerGame,
                             commas(game.bonus), game.multiplier, commas(game.high))
      if game.extraBallLit then status = status .. "   (extra ball lit)" end
      if game.shootAgain > 0 then status = status .. "   (shoot again)" end
    else
      status = string.format("GAME OVER -- press 1 to play   HIGH %s", commas(game.high))
    end
    lines[#lines + 1] = status
  end
  if TF and TF.ai then lines[#lines + 1] = TF.ai.statusText() end
  lines[#lines + 1] = PLAY_HELP
  return table.concat(lines, "\n")
end

local lastStatus = nil
local function showHelp()
  if v.setHelpText then v:setHelpText(helpText()) end
  helpDirty = false
end

-- ---------------------------------------------------------------------
-- editor keys
-- ---------------------------------------------------------------------

local function finishEditing()
  if not editing then return end
  rebuildPending()
  selectItem(nil)
  editing = false
  heldArrows = {}
  saveLayout()
  local parts = {}
  for _, key in ipairs(EDIT_ORDER) do
    parts[#parts + 1] = editItems[key].label .. ": " .. describe(editItems[key])
  end
  print("Layout saved -- " .. table.concat(parts, "; "))
  helpDirty = true
end

-- Handles a key while the editor is active. Returns true if it used the key.
local function editorKey(key, down)
  if ARROWS[key] then
    local t = now()
    if down then
      local r = releasedArrows[key]
      if r and t - r.at < EDIT_REPEAT_GAP then
        heldArrows[key] = r.since            -- the same hold, continuing
      else
        heldArrows[key] = t
        moveSelected(ARROWS[key][1] * EDIT_STEP, ARROWS[key][2] * EDIT_STEP)
      end
      releasedArrows[key] = nil
    elseif heldArrows[key] then
      releasedArrows[key] = { at = t, since = heldArrows[key] }
      heldArrows[key] = nil
    end
    return true
  end
  if key == "B" or key == "R" or key == "Del" or key == "Delete" or key == "Backspace" then
    if down then
      if key == "B" then
        local added, why = editState.addBumper()
        if added then selectItem(added) else blockedMsg = "can't add a bumper: " .. why end
      elseif key == "R" then
        editState.resetLayout()
      elseif selected and editItems[selected].added then
        editState.removeBumper(selected)
        blockedMsg = "bumper removed"
      else
        blockedMsg = "select an added bumper (4 and up) to remove it"
      end
      helpDirty = true
    end
    return true
  end
  if key:match("^%d$") and key ~= "0" then
    if down then
      if EDIT_KEYS[key] then selectItem(EDIT_KEYS[key])
      else blockedMsg = "there's no pop bumper " .. key .. " (B adds one)"; helpDirty = true end
    end
    return true
  end
  if selected == "ramp" and (key == "," or key == "." or key == "<" or key == ">") then
    if down then
      local ok, why = rampway.turn((key == "," or key == "<") and -2.5 or 2.5)
      blockedMsg = (not ok) and why or nil
      helpDirty = true
    end
    return true
  end
  if EDIT_KEYS[key] or key == "0" or key == "E" then
    if down then
      if EDIT_KEYS[key] then selectItem(EDIT_KEYS[key])
      elseif key == "0" then
        if selected == "ramp" then rampway.turn(select(3, editState.home("ramp")) - rampway.da) end
        if selected then
          local hu, hw = editState.home(selected)
          local ok, why = setOffset(editItems[selected], hu, hw)
          blockedMsg = (not ok) and ("can't reset yet: " .. why) or nil
          helpDirty = true
        end
      elseif key == "E" then finishEditing() end
    end
    return true
  end
  if (key == "Return" or key == "Enter") and down then
    finishEditing()
  end
  return false
end

-- Called every frame: slides the selection while an arrow is held and
-- rebuilds the arch/exit (at most ~15 times a second while sliding).
local function editorTick(N)
  local t = now()
  local dt = lastSlideAt and math.min(t - lastSlideAt, 0.1) or 0
  lastSlideAt = t
  if editing and selected and dt > 0 then
    local mu, mw = 0, 0
    for key, t0 in pairs(heldArrows) do
      local held = t - t0
      if held >= EDIT_HOLD then
        local speed = math.min(EDIT_SLIDE + EDIT_ACCEL * (held - EDIT_HOLD), EDIT_SLIDE_MAX)
        mu, mw = mu + ARROWS[key][1] * speed, mw + ARROWS[key][2] * speed
      end
    end
    if mu ~= 0 or mw ~= 0 then moveSelected(mu * dt, mw * dt) end
  end
  if (not arch.built or not exitWall.built or not orbitTop.built or not rampway.built)
     and (next(heldArrows) == nil or t - (editState.rebuiltAt or 0) > 0.07) then
    rebuildPending()
    editState.rebuiltAt = t
  end
end

-- ---------------------------------------------------------------------
-- keyboard
-- ---------------------------------------------------------------------


local FLIPPER_KEYS = {
  LShift = -1, Z = -1,
  RShift = 1, ["/"] = 1,
}

local function onKey(N, key, down)
  if key == "V" then            -- the view: the player's, or the whole machine
    if down then board.setView(board.view % 2 + 1) end
    return true
  end
  if key == "P" then            -- the computer player (pinball-machine-a-ai.lua)
    if down and TF.ai then TF.ai.toggle() end
    return true
  end
  if editing and editorKey(key, down) then return true end
  local side = FLIPPER_KEYS[key]
  if side then
    if down and game.tilted then return true end   -- (dead after a tilt)
    if down ~= flippers[side].pressed then
      flippers[side].pressed = down
      playSound(down and "flipperUp" or "flipperDown")
      if down then rotateBanks(side) end
    end
    return true
  end
  if key == "Space" then
    if down then nudger.nudge() end
    return true
  end
  if key == "Return" or key == "Enter" then
    if down then
      if not plunger.pulledAt then
        plunger.pulledAt = now()
        playSound("plungerPull")
      end
    elseif plunger.pulledAt then
      local strength = math.min(1, (now() - plunger.pulledAt) / PLUNGER_PULL_TIME)
      local u, w = ballUW()
      if u > LANE_IN and w < 10 then
        if not game.active and not game.serveAt then startGame() end
        local speed = PLUNGER_MIN + (PLUNGER_MAX - PLUNGER_MIN) * strength
        ball.vel = btVector3(0, 0, -speed)
        playSound("launch")
      end
      plunger.pulledAt = nil
      plunger.snapping = true        -- springs forward over the next frames
    end
    return true
  end
  if key == "1" and down and not editing then
    if not game.active then
      startGame()
      serveBall()
    end
    return true
  end
  return false
end
if v.onKey then v:onKey(onKey) end

-- exposed for scripted testing (bpp -f runs have no keyboard)
TF = { onKey = function(key, down) return onKey(frame, key, down) end, gate = gate,
       ballUW = ballUW, placeBall = placeBall, flippers = flippers,
       frame = function() return frame end,
       switchLog = {}, game = game, banks = banks, board = board,
       editItems = editItems, isEditing = function() return editing end,
       setOffsetForce = function(it, du, dw) setOffset(it, du, dw, true); rebuildPending() end,
       blockedMsg = function() return blockedMsg end,
       ballVel = function(vu, vw) ball.vel = btVector3(vu, 0, -vw) end,
       bumpers = bumpers, switchByName = switchByName, soundIds = soundIds,
       editOrder = function() return EDIT_ORDER end, plunger = plunger,
       hit = function(name) onSwitch(switchByName[name]) end,
       drain = function() ballDrained() end, startGame = startGame, nudge = function() nudger.nudge() end,
       -- for the computer player
       now = function() return now() end, laneIn = LANE_IN, inOuthole = function(u, w) return inOuthole(u, w) end,
       ballVelUW = function() local bv = ball.vel return bv.x, -bv.z end,
       ballY = function() return ball.pos.y end, ramp = rampway,
       ballVel3 = function() return ball.vel end,
       glassOff = function() return rampway.glassOff end,
       -- testing only: put the arch and lanes somewhere without the limits
       forceLayout = function(adu, adw, ldw)
         setOffset(editItems.arch, adu, adw, true)
         setOffset(editItems.lanes, editItems.lanes.du, ldw, true)
         rebuildPending()
         local top = LANE_W0 + 8 + ldw + 0.5
         TF.gap = archUndersideFor(laneEdges[1], adu, adw) - top
         TF.archu = function(u) return archUndersideFor(u, adu, adw) end
       end }

-- ---------------------------------------------------------------------
-- per-frame loop
-- ---------------------------------------------------------------------

local prevU, prevW = ballUW()
local swUntil = {}       -- switch name -> frame it can trigger again
local wasDrained = false
-- ball search: like a real machine pulsing its coils when the ball hasn't
-- moved for a while, a ball that comes to rest anywhere but the shooter
-- lane or the outhole gets a small nudge
local stillSince, stillU, stillW = 0, 0, 0
local shown = {}         -- what the scoreboard last showed

local function updateBoard()
  local msg
  if game.messageText and frame < game.messageUntil then msg = game.messageText
  elseif game.tilted then msg = "TILT"
  elseif editing then msg = "EDIT LAYOUT"
  elseif not game.active then msg = "PRESS 1"
  else msg = "" end
  local want = {
    score = (game.active or game.score > 0) and tostring(game.score) or "",
    ball = game.active and tostring(game.ball) or "",
    bonus = game.active and tostring(game.bonus * game.multiplier) or "",
    mult = "2345",
    high = tostring(game.high),
    message = msg,
  }
  for k, text in pairs(want) do
    if shown[k] ~= text then
      shown[k] = text
      if k == "mult" then
        -- each multiplier digit lights once reached
        local d = board.mult
        for i, n in ipairs({ 2, 3, 4, 5 }) do
          local bits = CHARS[tostring(n)]
          for s, seg in ipairs(d.digits[i]) do
            local inDigit = bits % (2 * SEG_BITS[s]) >= SEG_BITS[s]
            -- the digit's own segments: dim grey until reached, then white;
            -- the rest blend into the backbox
            seg.obj.col = not inDigit and "#101418" or (game.multiplier >= n and "#ffffff" or "#3a3a3a")
          end
        end
      elseif k == "message" then
        board.message.set(text, false)
      else
        board[k].set(text, true)
      end
    end
  end
  if shown.multValue ~= game.multiplier then shown.multValue = game.multiplier; shown.mult = nil end
end

v:preSim(function(N)
  driveFlippers()
  -- the plunger follows Return: drawn back while held, snapping forward
  if plunger.pulledAt then
    plunger.pull = math.min(1, (now() - plunger.pulledAt) / PLUNGER_PULL_TIME)
    plunger.place()
  elseif plunger.snapping then
    plunger.pull = math.max(0, plunger.pull - 0.34)
    plunger.place()
    plunger.snapping = plunger.pull > 0
  end
end)

-- The editor and the Shortcuts pane run from the draw loop, so they work
-- whether or not the simulation is running.
-- Memory: bpp stops Lua's garbage collector (so it can't free a Bullet
-- object C++ still points to), so the temporary vectors made every frame
-- were never freed. Everything the table creates that C++ holds is added
-- to the world or kept in the script's tables, so collecting frees only
-- garbage: every 120 calls, collect, then stop the collector again.
TF.gcTick = function()
  -- (a bpp that collects garbage itself, BPP_GC_AUTO, needs none of this)
  if BPP_GC_AUTO then return end
  TF.gcCalls = (TF.gcCalls or 0) + 1
  if TF.gcCalls >= 120 then
    TF.gcCalls = 0
    collectgarbage("collect")
    collectgarbage("stop")
  end
end

v:preDraw(function(N)
  TF.gcTick()
  editorTick(N)
  if helpDirty and not game.active then
    local text = helpText()
    if text ~= lastStatus then
      lastStatus = text
      if v.setHelpText then v:setHelpText(text) end
    end
    helpDirty = false
  end
end)

v:postSim(function(N)
  frame = N
  local u, w = ballUW()
  if ballTeleported then
    prevU, prevW = u, w
    ballTeleported = false
  end
  local ballY = ball.pos.y
  rampway.glassTick(u, w, ballY)
  local up = ballY > BALL_R + 0.65         -- up on the ramp (or in the air)

  -- switches the ball's path touched this frame
  for _, s in ipairs(switches) do
    local hit
    if (s.elevated or false) ~= up then
      hit = false                          -- (a switch on the ramp, or under it)
    elseif s.upOnly and (u - prevU) * s.tu + (w - prevW) * s.tw <= 0 then
      hit = false                          -- (only going one way)
    elseif s.kind == "circle" then
      hit = distPointSeg(s.c[1], s.c[2], prevU, prevW, u, w) < s.r
    elseif s.kind == "face" then
      hit = distSegSeg(prevU, prevW, u, w, s.a[1], s.a[2], s.b[1], s.b[2]) < s.reach
    else
      hit = distSegSeg(prevU, prevW, u, w, s.a[1], s.a[2], s.b[1], s.b[2]) < 0.6
    end
    if hit then
      if (swUntil[s.name] or 0) <= frame and not game.tilted then   -- (tilted: all dead)
        TF.switchLog[#TF.switchLog + 1] = { frame = frame, sw = s.name }
        for _, b in ipairs(bumpers) do
          if b.name == s.name then fireBumper(b) end
        end
        for _, sl in ipairs(slings) do
          if sl.name == s.name then kick(sl.nu, sl.nw, SLING_KICK) end
        end
        onSwitch(s)
      end
      swUntil[s.name] = frame + SWITCH_HOLD_FRAMES
    end
  end

  -- bumper caps flash when they fire
  for _, b in ipairs(bumpers) do
    if b.flash > 0 then
      b.flash = b.flash - 1
      if b.flash == 0 then b.cap.col = "#f1faee" end
    end
  end

  -- ball search
  if math.abs(u - stillU) + math.abs(w - stillW) > 0.3 then
    stillSince, stillU, stillW = frame, u, w
  elseif frame - stillSince > BALL_SEARCH_FRAMES and not (u > LANE_IN and w < 10)
         and not inOuthole(u, w) then
    local a = math.random() * 2 * math.pi
    ball.vel = btVector3(60 * math.cos(a), 0, -60 * math.abs(math.sin(a)))
    stillSince = frame
  end

  -- the outhole
  local drained = inOuthole(u, w)
  if drained and not wasDrained then ballDrained() end
  wasDrained = drained
  if game.serveAt and frame >= game.serveAt then nextBall() end

  showLamps()
  updateBoard()
  if game.active or helpDirty then
    if helpDirty or N % 15 == 0 then
      local text = helpText()
      if text ~= lastStatus then
        lastStatus = text
        if v.setHelpText then v:setHelpText(text) end
      end
      helpDirty = false
    end
  end

  nudger.tick()
  board.artTick(N, game.active)
  prevU, prevW = u, w
  if TF.ai then TF.ai.tick(N) end
  TF.gcTick()
end)

-- restore the layout saved by a previous run, then show the editor's keys
loadLayout()
showHelp()
placeBall(SHOOT_U, SHOOT_W)

-- the computer player, if its file is here
do
  local ok, mod = pcall(dofile, "pinball-machine-a-ai.lua")
  if ok and type(mod) == "function" then TF.ai = mod(TF)
  elseif not ok then print("Computer player not loaded: " .. tostring(mod)) end
end

-- camera: standing at the front of the cabinet, looking up the table
board.setView(1)
