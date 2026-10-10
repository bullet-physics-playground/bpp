--
-- Chebyshev-Spears walker (diagonal crossbars) on its own terrain. The
-- mechanism itself (the body, four linkages, diagonal crossbars and
-- feet, and the notes on why it is built the way it is) is in
-- Chebyshev_Spears_diag_parts.lua; this file adds the terrain, sliders, trail,
-- camera and physics settings around it.
--
local common = require "common"
v.shadows = false   -- no shadows: with them bpp redraws the big terrain's shadow every frame, and the walker slows down
local Walker = dofile("Chebyshev_Spears_diag_parts.lua")   -- bpp runs a script from its own folder

common.setTiming(1/10, 20, 1/480)
--v.timeStep = 1/10 --1/40 -- 1/200 -- 1/60
--v.fixedTimeStep = 1/480 --1/960 -- 1/480

-- ---------------------------------------------------------------------
-- GUI sliders. All six apply live, no Restart needed -- Restart
-- Simulation can't help here anyway (see the REBUILD SUPPORT comment
-- above buildScene() further down for why: it wipes v's own param
-- table and reruns this script from its literal hardcoded defaults).
-- maxSubSteps and motorSpeed are applied in place via v:onParamChanged
-- (plus a redundant per-tick re-apply in the v:preSim hook near the
-- bottom, shared with the trail-marker code -- this engine only allows
-- one v:preSim and one v:onParamChanged registration each, so
-- everything for both funnels through those two single callbacks).
-- cube_d, cubeMass, terrainAmp and linkageSpacing instead tear down
-- and rebuild the whole scene (cube, terrain, all 4 legs) via
-- teardownScene()/buildScene(), also from v:onParamChanged -- see that
-- registration, right after buildScene()'s definition further down,
-- for the full picture. Since a rebuild snaps the walker back to its
-- starting position, that same handler also clears the red centroid-
-- trail markers (clearTrail(), defined next to the trail-marker code
-- near the bottom) so an old trail from before the rebuild doesn't
-- linger and misrepresent where the walker has actually been since.
-- ---------------------------------------------------------------------
local PARAM_INFO = {
  maxSubSteps = { min = 1,   max = 2000, step = 1,
                  comment = "Bullet max substeps per tick (live)" },
  motorSpeed  = { min = 0,   max = 8,   step = 0.1,
                  comment = "hip hinge motor target angular speed, all 4 legs (live)" },
  cube_d      = { min = 1,   max = 10,  step = 0.1,
                  comment = "cube's own depth / Z (rebuilds the scene)" },
  cubeMass    = { min = 1,   max = 200, step = 1,
                  comment = "cube body mass (rebuilds the scene)" },
  terrainAmp  = { min = 0,   max = 3,   step = 0.05,
                  comment = "terrain bump height (rebuilds the scene)" },
  linkageSpacing = { min = 10,  max = 40,  step = 0.5,
                  comment = "distance between the two front (and two back) leg mounts (rebuilds the scene)" },
}

local function setParam(name, value)
  local info = PARAM_INFO[name]
  value = math.max(info.min, math.min(info.max, value))
  v:addParam(name, value, info.min, info.max, info.step, info.comment)
  return value
end

setParam("maxSubSteps", 20)
setParam("motorSpeed", 2.6)
setParam("cube_d", 4.5)
setParam("cubeMass", 50.0)
setParam("terrainAmp", 0.0)
setParam("linkageSpacing", 18)

v.maxSubSteps = v:getParam("maxSubSteps")

--local common = require "common"

--common.setTiming(1/10, 20, 1/480)

-- ---------------------------------------------------------------------
-- floor: an uneven terrain mesh (Terrain, backed by
-- btBvhTriangleMeshShape -- Bullet's BVH-accelerated static concave
-- shape) instead of a flat Cube. floor_top_y is still the mechanism's
-- own baseline reach, DERIVED from p_len exactly as before (4.6 - p_len
-- comes from the crank/rocker/coupler loop's own lowest point,
-- independent of p_len, minus the foot's half-thickness and a small
-- margin); terrainHeight(x,z) adds a small undulation ON TOP of that
-- baseline, so a foot still finds ~floor_top_y on average but has real
-- bumps to step over/into instead of a perfectly flat surface.
-- terrain_amp is on the order of the crank length driving the whole
-- gait (a_len=1.0) and well past the foot's own half-thickness (0.15),
-- so bumps are a real obstacle the feet have to climb, not just surface
-- texture -- worth watching on the first run, same honest caveat as the
-- top crossbars above.
-- (Terrain was tried here before via btGImpactMeshShape -- tiles,
-- scattered patches -- but reverted: GImpact is built for shapes that
-- might move, and is markedly slower/less stable than it needs to be
-- for a shape that never does. btBvhTriangleMeshShape builds its BVH
-- tree once, at construction, and is ONLY ever valid for a static body
-- -- exactly what the floor already was, so nothing about "static,
-- never moves" had to change, just the shape type backing it.)
-- ---------------------------------------------------------------------

local floor_top_y = Walker.FLOOR_TOP_Y

-- ---------------------------------------------------------------------
-- REBUILD SUPPORT for cube_d/cubeMass/terrainAmp: every object and
-- constraint buildScene() creates is tracked here so a later call can
-- tear the whole thing down cleanly (v:remove / v:removeConstraint)
-- before rebuilding it with a new slider value. Restart Simulation
-- can't do this for us -- checked the actual BPP source
-- (Viewer::restartSim -> parse(_scriptContent)): parse() calls
-- Viewer::clear(), which does `_params.clear()`, wiping every GUI
-- param, then reruns this whole script from scratch -- so a slider
-- dragged before Restart is gone; the script just reasserts whatever
-- literal default setParam() was called with. The onParamChanged
-- handler below drives a live rebuild instead, without needing Restart
-- at all.
-- ---------------------------------------------------------------------
local builtObjects, builtConstraints = {}, {}

function track(obj)
  v:add(obj)
  builtObjects[#builtObjects + 1] = obj
  return obj
end

function trackConstraint(con)
  v:addConstraint(con)
  builtConstraints[#builtConstraints + 1] = con
  return con
end

function teardownScene()
  for i = 1, #builtConstraints do
    v:removeConstraint(builtConstraints[i])
  end
  builtConstraints = {}
  for i = 1, #builtObjects do
    v:remove(builtObjects[i])
  end
  builtObjects = {}
end

function buildScene()
-- Read early (also used by the floor section further down) so the
-- walker's starting height can already account for it -- see
-- terrain_lift below.
local terrain_amp = v:getParam("terrainAmp")  -- bump height -- GUI slider

-- the walker: cube body, four linkages, diagonal crossbars and feet. It
-- is lifted by terrain_amp to clear the tallest bump (see terrain_lift
-- in Chebyshev_Spears_diag_parts.lua).
local w = Walker.build{
  add = track, addConstraint = trackConstraint,
  terrainLift = terrain_amp * 1.0,
  cube_d = v:getParam("cube_d"), cubeMass = v:getParam("cubeMass"),
  linkageSpacing = v:getParam("linkageSpacing"),
  motorSpeed = v:getParam("motorSpeed"),
}
cube = w.cube   -- GLOBAL, read by the trail-marker hook and the camera
linkage1, linkage2, linkage3, linkage4 = w.linkage1, w.linkage2, w.linkage3, w.linkage4   -- GLOBAL, read by the motorSpeed slider's live sync
local cube_center_x = w.cubeCenterX   -- the floor is centred on the walker

--local floor_top_y = -0.6 - p_len
-- floor_w/floor_d/terrain_nx/terrain_nz/floor_x0/floor_z0 (below) are
-- globals, not locals -- same "REBUILD SUPPORT" convention already used
-- for cube/floor themselves, needed so the trail code past the end of
-- buildScene() can convert a world (x,z) back to a terrain triangle
-- index using these exact same values, instead of only the code inside
-- this function being able to see them.
floor_w, floor_d = 600, 600
terrain_nx, terrain_nz = 120, 60   -- grid resolution: 2.5-unit cells in both X and Z

-- Smooth, deterministic pseudo-noise: three sine waves at different
-- frequencies/phases/axes summed together. Each term alone is perfectly
-- smooth (a sine has no discontinuities), so neighboring grid points are
-- always close in height -- no cliff edge a foot could catch a corner on
-- -- while the SUM of three incommensurate frequencies isn't simply
-- periodic the way a single sine would be, so the walker's path crosses
-- real bump-to-bump variation rather than a uniform ripple.
function terrainHeight(x, z)
  return terrain_amp * (
    0.5 * math.sin(x * 0.30 + z * 0.21) +
    0.3 * math.sin(x * 0.11 - z * 0.44 + 1.7) +
    0.2 * math.sin(x * 0.53 + z * 0.07 + 4.1))
end

floor = Terrain()
floor_x0, floor_z0 = cube_center_x - floor_w/2, -floor_d/2
for i = 0, terrain_nx - 1 do
  for j = 0, terrain_nz - 1 do
    local xa, xb = floor_x0 + i*(floor_w/terrain_nx), floor_x0 + (i+1)*(floor_w/terrain_nx)
    local za, zb = floor_z0 + j*(floor_d/terrain_nz), floor_z0 + (j+1)*(floor_d/terrain_nz)
    local yaa, yab = floor_top_y + terrainHeight(xa, za), floor_top_y + terrainHeight(xa, zb)
    local yba, ybb = floor_top_y + terrainHeight(xb, za), floor_top_y + terrainHeight(xb, zb)
    floor:addTriangle(btVector3(xa, yaa, za), btVector3(xa, yab, zb), btVector3(xb, yba, za))
    floor:addTriangle(btVector3(xb, yba, za), btVector3(xa, yab, zb), btVector3(xb, ybb, zb))
  end
end
floor:build()
floor.col = "#694811"
floor.friction = 0.8
track(floor)
end   -- closes buildScene()

buildScene()

-- ---------------------------------------------------------------------
-- GUI SLIDER LIVE SYNC: v:onParamChanged fires whenever a slider is
-- dragged (or setParam() is called from Lua), exactly like the GUI's
-- own drag handler updates a param -- see uniform-coverage7.lua's
-- onParamChanged for the reference pattern. Only one v:onParamChanged
-- may be registered for the whole file (same single-callback rule as
-- v:preSim), so every param's handling lives in this one function.
--
-- maxSubSteps and motorSpeed apply immediately in place. cube_d,
-- cubeMass, terrainAmp and linkageSpacing instead tear down and
-- rebuild the whole scene (cube, terrain, all 4 legs) via
-- teardownScene()/buildScene() -- see the REBUILD SUPPORT comment
-- above buildScene() for why Restart Simulation can't do this for us,
-- so this handler has to.
-- ---------------------------------------------------------------------
v:onParamChanged(function(N, name, value)
  if name == "maxSubSteps" then
    v.maxSubSteps = math.floor(value)
  elseif name == "motorSpeed" then
    linkage1.hingeO2:enableAngularMotor(true, value, 8.0)
    linkage2.hingeO2:enableAngularMotor(true, value, 8.0)
    linkage3.hingeO2:enableAngularMotor(true, value, 8.0)
    linkage4.hingeO2:enableAngularMotor(true, value, 8.0)
    print(string.format("motorSpeed = %.2f", value))
  elseif name == "cube_d" or name == "cubeMass" or name == "terrainAmp" or name == "linkageSpacing" then
    teardownScene()
    buildScene()
    clearTrail()   -- the walker just snapped back to its starting position -- an old trail from before the rebuild would misleadingly show a path it never walked from here
    print(string.format("%s = %s (scene rebuilt)", name, tostring(value)))
  end
end)

-- GUI SLIDER LIVE SYNC, redundant safety net for maxSubSteps/motorSpeed:
-- also re-applied every tick in the SINGLE v:preSim hook further down
-- (with the trail-marker code) -- this file only supports one v:preSim
-- registration, so a second one here would silently replace it instead
-- of running alongside it.


-- ---------------------------------------------------------------------
-- CENTROID TRAIL: colors the terrain triangle under the mechanism's
-- current (x,z) position every TRAIL_INTERVAL frames, to visualize its
-- trajectory over time (turning, drifting, straight-line travel, etc.).
--
-- Uses the CUBE's position as a practical stand-in for the true mass-
-- weighted centroid, rather than summing every body in the mechanism
-- every frame -- the cube alone is close to half the total mass, so
-- its path should closely track the true centroid's shape without
-- that bookkeeping.
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
-- also means there's nothing to v:remove() any more -- see clearTrail()
-- below.
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
--
-- TRAIL_INTERVAL=30 was tuned as "0.5s at 60fps" in Cheby, which
-- actually undershoots there since Cheby's own v.timeStep is 1/10 --
-- but Spears' v.timeStep IS 1/60, so 30 frames really is 0.5s here,
-- matching the original comment's intent exactly. (Still true after
-- this rework -- TRAIL_INTERVAL only ever gated how often colorTrailAt()
-- fires, unrelated to what it does once it fires.)
-- ---------------------------------------------------------------------

local TRAIL_INTERVAL = 30   -- frames between markers (0.5s at 60fps) -- lower = finer trail, more markers over a long run
local trail_frame_count = 0
function clearTrail()
  floor:clearTriangleColors()   -- one call resets the whole floor to its base .col -- no per-marker list to walk any more
  trail_frame_count = 0
end

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

v:preSim(function(N)
  -- GUI SLIDER LIVE SYNC: maxSubSteps and motorSpeed can be dragged
  -- while the sim is running. maxSubSteps is just re-assigned onto v
  -- each tick; motorSpeed is re-applied to all four hip hinges' motor
  -- target via enableAngularMotor (torque/maxImpulse stays fixed at
  -- 8.0, matching each hinge's original construction-time call).
  v.maxSubSteps = math.floor(v:getParam("maxSubSteps"))
  local motorSpeed = v:getParam("motorSpeed")
  linkage1.hingeO2:enableAngularMotor(true, motorSpeed, 8.0)
  linkage2.hingeO2:enableAngularMotor(true, motorSpeed, 8.0)
  linkage3.hingeO2:enableAngularMotor(true, motorSpeed, 8.0)
  linkage4.hingeO2:enableAngularMotor(true, motorSpeed, 8.0)

  trail_frame_count = trail_frame_count + 1
  if trail_frame_count >= TRAIL_INTERVAL then
    trail_frame_count = 0
    colorTrailAt(cube.pos.x, cube.pos.z)
  end
end)

-- ---------------------------------------------------------------------
-- camera + gravity
-- ---------------------------------------------------------------------
local CAM_SCALE = 20 / 15

common.setCamera(btVector3(cube.pos.x - 120*CAM_SCALE, cube.pos.y, cube.pos.z + 120*CAM_SCALE),               btVector3(cube.pos.x, cube.pos.y, cube.pos.z), 0.15)

--v.cam.pos  = btVector3(26, 6, 30)
--v.cam.look = btVector3(5, -3, 0)
--v.cam.up   = btVector3(0, 1, 0)

v.gravity = btVector3(0, -9.8, 0)
