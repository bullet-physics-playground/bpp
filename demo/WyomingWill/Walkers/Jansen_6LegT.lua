--
-- Jansen Walker on its own terrain. The mechanism itself (the body and
-- six legs, and the notes on why it is built the way it is) is in
-- Jansen_6Leg_build.lua; this file adds the terrain, sliders, trail,
-- camera and physics settings around it.
--

local common = require "common"
local Jansen = dofile("Jansen_6Leg_build.lua")   -- bpp runs a script from its own folder

-- ---------------------------------------------------------------------
-- SLIDERS, per direct request ("Add sliders for speed and terrain
-- amplitude, and maxsubsteps"). Speed and maxSubSteps are LIVE (applied
-- in place every tick, no rebuild) -- neither changes any geometry.
-- TerrainAmp REBUILDS the scene -- it changes the floor's own shape and,
-- through O_MOUNT_Y, how high the whole walker starts, so a live-only
-- update would leave the floor and the walker's starting height out of
-- sync with each other.
-- ---------------------------------------------------------------------

local PARAM_INFO = {
  Speed = { min = 0, max = 8, step = 0.1,
            comment = "crank motor target angular speed, all 6 legs (live)" },
  maxSubSteps = { min = 1, max = 1000, step = 1,
            comment = "Bullet max substeps per tick (live)" },
  TerrainAmp = { min = 0, max = 30, step = 0.5,
            comment = "terrain bump height (rebuilds the scene)" },
}

local function setParam(name, value)
  local info = PARAM_INFO[name]
  value = math.max(info.min, math.min(info.max, value))
  v:addParam(name, value, info.min, info.max, info.step, info.comment)
end

local builtObjects, builtConstraints = {}, {}
function track(obj)
  v:add(obj)
  obj.body:setActivationState(4)   -- DISABLE_DEACTIVATION -- a sleeping body ignores its own motor's torque
  builtObjects[#builtObjects + 1] = obj
  return obj
end
function trackConstraint(con)
  v:addConstraint(con)
  builtConstraints[#builtConstraints + 1] = con
  return con
end
function teardownScene()
  for _, con in ipairs(builtConstraints) do v:removeConstraint(con) end
  for _, obj in ipairs(builtObjects) do v:remove(obj) end
  builtObjects, builtConstraints = {}, {}
end

common.setTiming(1/20, 60, 1/240)   -- maxSubSteps arg here is just Bullet's
                                     -- own ceiling for a single tick -- the
                                     -- REAL live value comes from the
                                     -- maxSubSteps slider (v.maxSubSteps=...
                                     -- below) -- set generously high (60)
                                     -- so the slider's own max (60) is never
                                     -- silently clamped by this one

function buildScene()
-- the floor is centred on the walker's middle row of legs, and the walker
-- is mounted to clear the terrain's tallest bump (Jansen.build below)
CUBE_CENTER_X  = Jansen.CUBE_CENTER_X   -- GLOBAL, read by the trail-marker preSim hook outside buildScene()
FLOOR_TOP_Y    = 0.0   -- baseline (flat-average) floor height -- GLOBAL, read by the trail-marker hook -- real terrain bulges above/below this by up to TERRAIN_AMP, see terrainHeight() near the floor code below
local TERRAIN_AMP = v:getParam("TerrainAmp")   -- GUI slider -- max bump height above/below FLOOR_TOP_Y -- the three sine terms in terrainHeight() sum to a max combined amplitude of exactly 1.0, so this is a direct multiplier

-- FLOOR: bumpy terrain mesh (real hills, using terrainHeight(x,z)) on
-- top of a solid thick backstop box, per direct request ("replace that
-- floor with my terrain floor and make sure the feet... do not sink").
-- Two-part design, not just a plain mesh: this file's own CFM softening
-- is a GLOBAL v:setCfm(0.1) call (see that line's own comment above),
-- which -- confirmed elsewhere in this file series -- silently softens
-- terrain CONTACT resolution along with the leg hinges, letting a fast-
-- moving foot tunnel straight through a zero-thickness mesh regardless
-- of the mesh's own shape. Rather than touch the CFM approach this file
-- already has working (not asked for here), the backstop box gives
-- real physical thickness underneath the visual bumps -- exactly the
-- same fix this file's OWN header comment already documents needing
-- for its original flat floor ("a thin floor let a foot tunnel...").
--
-- terrainHeight(): three sine terms, amplitudes 0.5/0.3/0.2 summing to
-- a max combined amplitude of exactly 1.0, so TERRAIN_AMP above is a
-- direct multiplier on real bump height. Frequencies scaled down 10x
-- from the smaller-scale version elsewhere in this file series, to
-- keep bump WAVELENGTH proportional at this file's much larger native
-- Jansen units (roughly 8x bigger, given the other version's own
-- 0.1226 rescale factor).
function terrainHeight(x, z)
  return TERRAIN_AMP * (
    0.5 * math.sin(x * 0.030 + z * 0.021) +
    0.3 * math.sin(x * 0.011 - z * 0.044 + 1.7) +
    0.2 * math.sin(x * 0.053 + z * 0.007 + 4.1))
end

-- floor_w/floor_d/terrain_nx/terrain_nz/floor_x0/floor_z0 (below) are
-- globals, not locals -- same "GLOBAL, read by the trail-marker preSim
-- hook outside buildScene()" convention CUBE_CENTER_X already uses
-- above, needed so the trail code past the end of buildScene() can
-- convert a world (x,z) back to a terrain triangle index using these
-- exact same values, instead of only the code inside this function
-- being able to see them.
floor_w, floor_d = 10000, 10000
--local terrain_nx, terrain_nz = 100, 50   -- grid resolution -- 20-unit cells, proportionate to this file's own ~40-65-unit link lengths
terrain_nx, terrain_nz = 300, 200   -- grid resolution -- 20-unit cells, proportionate to this file's own ~40-65-unit link lengths

-- backstop: solid, thick, flat -- positioned BELOW the lowest possible
-- bump trough (FLOOR_TOP_Y-TERRAIN_AMP) so it never clips through and
-- shows past the visual mesh above it, with the SAME 40-unit thickness
-- this file's own header note already found necessary.
--local backstop_th = 40.0
--local backstop_top_y = FLOOR_TOP_Y - TERRAIN_AMP
--backstop = Cube(floor_w, backstop_th, floor_d, 0)   -- mass 0 -> static
--backstop.col = "#4a3308"
--backstop.pos = btVector3(CUBE_CENTER_X, backstop_top_y - backstop_th/2, 0)
--backstop.friction = 0.8
--track(backstop)

-- bumpy mesh: the real, visible/tactile terrain -- same triangle-strip
-- construction technique used elsewhere in this file series.
floor = Terrain()
floor_x0, floor_z0 = CUBE_CENTER_X - floor_w/2, -floor_d/2
for i = 0, terrain_nx - 1 do
  for j = 0, terrain_nz - 1 do
    local xa, xb = floor_x0 + i*(floor_w/terrain_nx), floor_x0 + (i+1)*(floor_w/terrain_nx)
    local za, zb = floor_z0 + j*(floor_d/terrain_nz), floor_z0 + (j+1)*(floor_d/terrain_nz)
    local yaa, yab = FLOOR_TOP_Y + terrainHeight(xa, za), FLOOR_TOP_Y + terrainHeight(xa, zb)
    local yba, ybb = FLOOR_TOP_Y + terrainHeight(xb, za), FLOOR_TOP_Y + terrainHeight(xb, zb)
    floor:addTriangle(btVector3(xa, yaa, za), btVector3(xa, yab, zb), btVector3(xb, yba, za))
    floor:addTriangle(btVector3(xb, yba, za), btVector3(xa, yab, zb), btVector3(xb, ybb, zb))
  end
end
floor:build()
floor.col = "#694811"
floor.friction = 0.8
track(floor)

-- the walker: cube body and six legs, built on the terrain above
local w = Jansen.build{
  add = track, addConstraint = trackConstraint,
  groundTop = FLOOR_TOP_Y + TERRAIN_AMP,
  speed = v:getParam("Speed"),
}
cube = w.cube   -- GLOBAL, read by the trail-marker hook and the camera
legs = w.legs   -- GLOBAL, read by the live-update preSim hook
end   -- closes buildScene()

setParam("Speed", 2.5)
setParam("maxSubSteps", 12)
setParam("TerrainAmp", 8.0)
buildScene()
v.maxSubSteps = v:getParam("maxSubSteps")

v:onParamChanged(function(N, name, value)
  if name == "TerrainAmp" then
    teardownScene()
    buildScene()
    floor:clearTriangleColors()   -- one call resets the whole floor to its base .col -- the walker just snapped back to its starting position, so an old trail from before the rebuild would otherwise misleadingly show a path it never walked from here
    print(string.format("TerrainAmp = %.2f (scene rebuilt)", value))
  elseif name == "Speed" then
    for _, lk in ipairs(legs) do
      lk.motorHinge:enableAngularMotor(true, -value, 3000.0)   -- negated, matching MOTOR_SPEED's own convention inside buildJansenLeg
    end
    print(string.format("Speed = %.2f", value))
  elseif name == "maxSubSteps" then
    v.maxSubSteps = math.floor(value)
  end
end)

-- ---------------------------------------------------------------------
-- centroid trail -- colors the terrain triangle under the cube's
-- current (x,z) every TRAIL_INTERVAL frames, to visualize the walker's
-- trajectory over time.
--
-- REWORKED, per direct request, to color existing terrain triangles
-- instead of spawning a Cube marker per trail point: a long run drops a
-- lot of markers (every 0.5s), and each one was a genuine extra static
-- rigid body PLUS an extra draw call for the rest of the run -- the
-- count only ever grows, so a long walk visibly slowed down over time.
-- Terrain:setTriangleColor() (added to the engine for this) recolors a
-- triangle that's already part of the one floor body and already being
-- drawn every frame -- no new bodies, no growing draw-call count, no
-- matter how long the walk runs or how fine TRAIL_INTERVAL is set. This
-- also means there's nothing to v:remove() any more -- see the
-- floor:clearTriangleColors() call in the "TerrainAmp" rebuild handler
-- above, which replaces the old trailMarkers-list cleanup.
--
-- floor_x0/floor_z0/floor_w/floor_d/terrain_nx/terrain_nz are the exact
-- same values the floor-building loop above used to place its
-- triangles -- converting a world (x,z) back to that loop's own (i,j)
-- cell indices, then to the triangle index Bullet assigns in
-- addTriangle() call order (2 triangles per cell, added in row-major
-- i,j order: cell (i,j)'s first triangle is index 2*(i*terrain_nz+j),
-- its second is that +1), recolors the exact cell the mechanism is over.
-- A position outside the floor's own extent is skipped rather than
-- clamped -- clamping would misleadingly paint the floor's edge cell for
-- a walker that's actually run off the mesh entirely, instead of just
-- not drawing anything.
-- ---------------------------------------------------------------------

local TRAIL_INTERVAL = 30
local trail_frame_count = 0

local function colorTrailAt(x, z)
  local i = math.floor((x - floor_x0) / (floor_w / terrain_nx))
  local j = math.floor((z - floor_z0) / (floor_d / terrain_nz))
  if i < 0 or i >= terrain_nx or j < 0 or j >= terrain_nz then
    return   -- off the floor's own extent -- nothing to color
  end
  local triIndex = 2 * (i * terrain_nz + j)
  floor:setTriangleColor(triIndex, 255, 0, 0)       -- "red", matching the old marker color
  floor:setTriangleColor(triIndex + 1, 255, 0, 0)   -- both triangles of the cell, not just one half of it
end

-- SINGLE v:preSim registration, covering both the Speed/maxSubSteps live
-- sync AND the trail marker -- this engine only supports one v:preSim
-- callback; a second registration would silently replace the first
-- rather than run alongside it.
v:preSim(function(N)
  v.maxSubSteps = math.floor(v:getParam("maxSubSteps"))
  local speed = v:getParam("Speed")
  for _, lk in ipairs(legs) do
    lk.motorHinge:enableAngularMotor(true, -speed, 3000.0)
  end

  trail_frame_count = trail_frame_count + 1
  if trail_frame_count >= TRAIL_INTERVAL then
    trail_frame_count = 0
    colorTrailAt(cube.pos.x, cube.pos.z)
  end
end)

-- ---------------------------------------------------------------------
-- camera -- follow the walker's center, same fixed-offset chase style as
-- cheby_normal6.lua, scaled up for Jansen's much larger native units.
-- ---------------------------------------------------------------------
common.setCamera(btVector3(cube.pos.x - 500, cube.pos.y + 200, cube.pos.z + 500), btVector3(cube.pos.x, cube.pos.y - 50, cube.pos.z), 0.5)


v:postSim(function(N)
  --common.setCamera(btVector3(cube.pos.x - 500, cube.pos.y + 200, cube.pos.z + 500),
  --btVector3(cube.pos.x, cube.pos.y - 50, cube.pos.z), 0.5)
end)

common.gravity(-9.8)

-- EOF
