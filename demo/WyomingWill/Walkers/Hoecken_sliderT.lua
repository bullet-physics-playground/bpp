--
-- Hoecken walker (slider) on its own terrain. The mechanism itself (the
-- body, four slider-crank linkages, crossbars and feet, and the notes
-- on why it is built the way it is) is in Hoecken_slider_parts.lua;
-- this file adds the terrain, sliders, trail, camera and physics
-- settings around it.
--

local common = require "common"
v.shadows = false   -- no shadows: with them bpp redraws the big terrain's shadow every frame, and the walker slows down
local Walker = dofile("Hoecken_slider_parts.lua")   -- bpp runs a script from its own folder

common.setTiming(1/10, 20, 1/480)

-- ---------------------------------------------------------------------
-- shared geometry / constants
-- ---------------------------------------------------------------------


-- ---------------------------------------------------------------------
-- GUI sliders. All seven apply live, no Restart needed -- Restart
-- Simulation wipes v's own param table and reruns this script from its
-- literal hardcoded defaults (checked the actual BPP source,
-- Viewer::restartSim -> parse(_scriptContent) -> Viewer::clear() ->
-- _params.clear()), so it can't preserve a dragged value either way.
-- maxSubSteps, "Left Speed" and "Right Speed" are applied in place via
-- v:onParamChanged (plus a redundant per-tick re-apply in the v:preSim
-- hook near the bottom, shared with the trail-marker code -- this
-- engine only allows one v:preSim and one v:onParamChanged
-- registration each, so everything for both funnels through those two
-- single callbacks). "Left Speed" drives linkage1/linkage2 (the front
-- legs); "Right Speed" drives linkage3/linkage4 (the back legs) -- two
-- independent motors instead of one shared speed. cube_d, cubeMass,
-- terrainAmp and linkageSpacing instead tear down and rebuild the
-- whole scene (cube, terrain, all 4 legs) via teardownScene()/
-- buildScene(), also from v:onParamChanged -- see that registration,
-- right after buildScene()'s definition further down, for the full
-- picture. Since a rebuild snaps the walker back to its starting
-- position, that same handler also clears the red centroid-trail
-- markers (clearTrail(), defined next to the trail-marker code near
-- the bottom) so an old trail from before the rebuild doesn't linger
-- and misrepresent where the walker has actually been since.
-- ---------------------------------------------------------------------
local PARAM_INFO = {
  maxSubSteps = { min = 1,   max = 2000, step = 1,
                  comment = "Bullet max substeps per tick (live)" },
  ["Left Speed"]  = { min = 0,   max = 8,   step = 0.1,
                  comment = "front hip hinge motor target angular speed, linkage1/2 (live)" },
  ["Right Speed"] = { min = 0,   max = 8,   step = 0.1,
                  comment = "back hip hinge motor target angular speed, linkage3/4 (live)" },
  cube_d      = { min = 1,   max = 10,  step = 0.1,
                  comment = "cube's own depth / Z (rebuilds the scene)" },
  cubeMass    = { min = 1,   max = 300, step = 1,
                  comment = "cube body mass (rebuilds the scene)" },
  terrainAmp  = { min = 0,   max = 3,   step = 0.05,
                  comment = "terrain bump height (rebuilds the scene)" },
  linkageSpacing = { min = 5,   max = 30,  step = 0.5,
                  comment = "distance between the two leg mounts on each face (rebuilds the scene)" },
}

local function setParam(name, value)
  local info = PARAM_INFO[name]
  value = math.max(info.min, math.min(info.max, value))
  v:addParam(name, value, info.min, info.max, info.step, info.comment)
  return value
end

setParam("maxSubSteps", 20)
setParam("Left Speed", 2.6)
setParam("Right Speed", 2.6)
setParam("cube_d", 4.5)
setParam("cubeMass", 100.0)
setParam("terrainAmp", 0.0)
setParam("linkageSpacing", 10)

v.maxSubSteps = v:getParam("maxSubSteps")

-- ---------------------------------------------------------------------
-- REBUILD SUPPORT for cube_d/cubeMass/terrainAmp/linkageSpacing: every
-- object and constraint buildScene() creates is tracked here so a
-- later call can tear the whole thing down cleanly (v:remove /
-- v:removeConstraint) before rebuilding it with a new slider value --
-- see the GUI sliders comment above for why Restart Simulation can't
-- do this for us.
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

local floor_top_y = Walker.FLOOR_TOP_Y

function buildScene()
-- Read early (also used by the floor section further down) so the
-- walker's starting height can already account for it -- see
-- terrain_lift below.
local terrain_amp = v:getParam("terrainAmp")  -- bump height -- GUI slider

-- the walker: the body, four slider-crank linkages, crossbars and feet.
-- It is lifted by terrain_amp to clear the tallest bump (see
-- terrain_lift in Hoecken_slider_parts.lua).
local w = Walker.build{
  add = track, addConstraint = trackConstraint,
  terrainLift = terrain_amp * 1.0,
  cube_d = v:getParam("cube_d"), cubeMass = v:getParam("cubeMass"),
  linkageSpacing = v:getParam("linkageSpacing"),
  leftSpeed = v:getParam("Left Speed"), rightSpeed = v:getParam("Right Speed"),
}
cube, cube_w = w.cube, w.cube_w   -- GLOBAL, read by the trail-marker hook and the camera
linkage1, linkage2, linkage3, linkage4 = w.linkage1, w.linkage2, w.linkage3, w.linkage4   -- GLOBAL, read by the speed sliders' live sync
local cube_center_x = w.cubeCenterX   -- the floor is centred on the walker

-- ---------------------------------------------------------------------
-- floor: an uneven terrain mesh (Terrain, backed by
-- btBvhTriangleMeshShape -- Bullet's BVH-accelerated static concave
-- shape) instead of a flat Cube. floor_top_y is still the mechanism's
-- own baseline reach, DERIVED from p_len (the baseline below comes from
-- the bar-and-slider loop's own lowest point, independent of p_len,
-- minus the foot's half-thickness and a small margin);
-- terrainHeight(x,z) adds a small undulation ON TOP of that baseline,
-- so a foot still finds ~floor_top_y on average but has real bumps to
-- step over/into instead of a perfectly flat surface. terrain_amp is
-- on the order of the crank length driving the whole gait (a_len=1.0)
-- and well past the foot's own half-thickness (0.15), so bumps are a
-- real obstacle the feet have to climb, not just surface texture --
-- worth watching on the first run, same honest caveat as the top
-- crossbars above.
-- (Terrain was tried here before via btGImpactMeshShape -- tiles,
-- scattered patches -- but reverted: GImpact is built for shapes that
-- might move, and is markedly slower/less stable than it needs to be
-- for a shape that never does. btBvhTriangleMeshShape builds its BVH
-- tree once, at construction, and is ONLY ever valid for a static body
-- -- exactly what the floor already was, so nothing about "static,
-- never moves" had to change, just the shape type backing it.)
-- ---------------------------------------------------------------------
-- The bar's own tip B stays HIGH (y in roughly [9.19, 11.25]) over a
-- full crank rotation at this scale, same as Chebyshev's own B stayed
-- high (~4.8-6.0) in the original file -- checked numerically (Lua
-- sweep, no NaNs/degenerate geometry across a full rotation for both
-- x_offset=0 and x_offset=10), not from a live physics run.
--
-- floor_top_y is DELIBERATELY NOT re-derived from the current p_len.
-- Back when p_len first went 10.0 -> 12.0, the foot (B.y - p_len) had
-- worked out to roughly [-0.82, +1.25] at p_len=10.0, and floor_top_y=
-- -1.02 sat just under that low point (8.98 was that original baseline,
-- i.e. B.ymin(9.185) minus a small margin). Keeping floor_top_y pinned
-- there while p_len grew meant the cube's resting height rises instead
-- of just tracking the floor down to match -- see that earlier change
-- for the full reasoning. p_len is now 14.0 (+2 more, this time to
-- clear the cube's own body -- at p_len=12.0 the foot's own high point,
-- -0.75, landed exactly on the cube's bottom face, also at y=-0.75).
-- This latest +2 is a clearance fix, not a "raise the body" one, so
-- floor_top_y stays exactly where it was rather than moving again.
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
-- ---------------------------------------------------------------------
-- floor: static, placed just below the lowest point any foot reaches
-- over a full crank rotation. Checked numerically (same kind of sweep
-- as the earlier clearance check) -- every linkage cycles through the
-- same B.y range regardless of its phase offset, and the lowest point
-- across that whole range is about y=-5.33 (foot's bottom surface).
-- The floor's top sits at -5.4, a small margin below that, so nothing
-- starts out already penetrating it.
-- ---------------------------------------------------------------------

--local floor_top_y = -5.4
--local floor_w, floor_th, floor_d = 600, 1.0, 600

--floor = Cube(floor_w, floor_th, floor_d, 0)   -- mass 0 -> static
--floor.col = "#694811"
--floor.pos = btVector3(cube_center_x, floor_top_y - floor_th/2, 0)
--floor.friction = 0.8
--v:add(floor)

end   -- closes buildScene()


buildScene()

-- ---------------------------------------------------------------------
-- GUI SLIDER LIVE SYNC: v:onParamChanged fires whenever a slider is
-- dragged (or setParam() is called from Lua), exactly like the GUI's
-- own drag handler updates a param. Only one v:onParamChanged may be
-- registered for the whole file (same single-callback rule as
-- v:preSim), so every param's handling lives in this one function.
--
-- maxSubSteps, "Left Speed" and "Right Speed" apply immediately in
-- place. cube_d, cubeMass, terrainAmp and linkageSpacing instead tear
-- down and rebuild the whole scene (cube, terrain, all 4 legs) via
-- teardownScene()/buildScene(), then clear the centroid trail since
-- the walker just snapped back to its starting position.
-- ---------------------------------------------------------------------
v:onParamChanged(function(N, name, value)
  if name == "maxSubSteps" then
    v.maxSubSteps = math.floor(value)
  elseif name == "Left Speed" then
    linkage1.hingeO2:enableAngularMotor(true, value, 150.0)
    linkage2.hingeO2:enableAngularMotor(true, value, 150.0)
    print(string.format("Left Speed = %.2f", value))
  elseif name == "Right Speed" then
    linkage3.hingeO2:enableAngularMotor(true, value, 150.0)
    linkage4.hingeO2:enableAngularMotor(true, value, 150.0)
    print(string.format("Right Speed = %.2f", value))
  elseif name == "cube_d" or name == "cubeMass" or name == "terrainAmp" or name == "linkageSpacing" then
    teardownScene()
    buildScene()
    clearTrail()   -- the walker just snapped back to its starting position -- an old trail from before the rebuild would misleadingly show a path it never walked from here
    print(string.format("%s = %s (scene rebuilt)", name, tostring(value)))
  end
end)

-- GUI SLIDER LIVE SYNC, redundant safety net for maxSubSteps/"Left
-- Speed"/"Right Speed": also re-applied every tick in the SINGLE
-- v:preSim hook further down (with the trail-marker code) -- this file
-- only supports one v:preSim registration, so a second one here would
-- silently replace it instead of running alongside it.

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
  -- GUI SLIDER LIVE SYNC: maxSubSteps, "Left Speed" and "Right Speed"
  -- can be dragged while the sim is running. maxSubSteps is just
  -- re-assigned onto v each tick; the two speeds are re-applied to
  -- their own pair of hip hinges via enableAngularMotor (maxMotorImpulse
  -- stays fixed at 150.0, matching each hinge's original construction-
  -- time call -- this file's much heavier bar+pendant+foot chain needs
  -- far more torque headroom than the flat 8.0 used elsewhere in this
  -- series).
  v.maxSubSteps = math.floor(v:getParam("maxSubSteps"))
  local leftSpeed = v:getParam("Left Speed")
  local rightSpeed = v:getParam("Right Speed")
  linkage1.hingeO2:enableAngularMotor(true, leftSpeed, 150.0)
  linkage2.hingeO2:enableAngularMotor(true, leftSpeed, 150.0)
  linkage3.hingeO2:enableAngularMotor(true, rightSpeed, 150.0)
  linkage4.hingeO2:enableAngularMotor(true, rightSpeed, 150.0)

  trail_frame_count = trail_frame_count + 1
  if trail_frame_count >= TRAIL_INTERVAL then
    trail_frame_count = 0
    colorTrailAt(cube.pos.x, cube.pos.z)
  end
end)

-- ---------------------------------------------------------------------
-- camera
-- ---------------------------------------------------------------------
  local CAM_SCALE = cube_w / 15

  common.setCamera(btVector3(cube.pos.x - 120*CAM_SCALE, cube.pos.y, cube.pos.z + 120*CAM_SCALE),               btVector3(cube.pos.x, cube.pos.y, cube.pos.z), 0.15)

common.gravity(-9.8)
