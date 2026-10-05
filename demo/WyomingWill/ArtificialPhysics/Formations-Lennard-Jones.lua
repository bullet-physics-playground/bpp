--
-- AP: Lennard-Jones -- 3D, with switchable dimension
--
-- A Bullet Physics Playground port of the Android app "AP: Lennard-Jones"
-- (package com.example.ap_lj): particles, a goal, and obstacles are
-- spheres free to move along x, y and z, interacting through a smooth
-- Lennard-Jones-style pairwise force.
--
-- This is one half of a split: this file was previously combined with a
-- Newtonian force law in one script with an N key to switch between
-- them. Splitting them into dedicated files removes that dispatch/toggle
-- machinery entirely -- there's exactly one force law here, so every
-- slider and code path in this file is about it specifically. See
-- ap-newtonian.lua for the other half; everything else (2D/3D switching,
-- square/triangle formation, goal, obstacles, cursor, neighbor lines,
-- momentum tracking, speed controls) is unchanged between the two
-- files.
--
-- THE FORCE LAW: a smooth dual-power-law curve -- short-range repulsion,
-- longer-range attraction, tuned to settle at "desiredSeparation" -- and,
-- unlike the Newtonian law, its magnitude is independent of the
-- particles' own masses (mass only enters later, via F=ma). The curve's
-- zero-crossing (attractive <-> repulsive) is exactly desiredSeparation
-- by construction, so it always tracks that slider correctly on its own
-- -- no separate "true equilibrium distance" constant to keep in sync
-- with it (unlike Newtonian's rad, which is a genuinely separate fixed
-- constant in that reference app). desiredSeparation defaults to 50, not
-- the original Android app's own default of 20: that app's slider really
-- was 2-30 default 20 (not a bug on this port's part), but running this
-- script and the Newtonian one side by side at very different absolute
-- scales made switching between them visually inconsistent, so this was
-- deliberately rescaled to match -- verified to still settle cleanly at
-- the larger scale with lennardJonesConstant/power/forceMaximum
-- unchanged, precisely because of that self-scaling zero-crossing.
--
-- DIMENSION, 2/3 to switch: 2 confines every entity to the y=0 plane
-- (matching the original 2D app), 3 restores full 3D motion. Both trigger
-- a fresh Setup, and the camera switches to match (straight-down "pseudo
-- orthogonal" for 2D, isometric for 3D -- an oblique camera on a flat
-- swarm foreshortens depth relative to breadth and makes a physically
-- symmetric arrangement look stretched). The "square formation" trick's
-- same-spin distance divisor is sqrt(2) in both 2D and 3D (a face
-- diagonal is always sqrt(2) x the edge, in any dimension -- see the full
-- explanation and the fix for the 3D case, which needed more than just
-- the divisor, near squareFormationParams() below). Entities never need
-- explicit 2D-vs-3D branching in the force math
-- itself: every y stays exactly 0 in 2D mode (never jittered at
-- creation, never perturbed by a force since every dy between two y=0
-- points is itself 0), so the same 3D formulas simply degenerate to the
-- 2D case on their own.
--
-- ANGULAR MOMENTUM IS A VECTOR IN 3D MODE: unlike a 2D-only simulation,
-- where angular momentum is a single number (the z-component of a 2D
-- cross product), here it's computed the direct way: L = sum(m*(r x v)).
-- In 2D mode this naturally comes out with only its z-component nonzero
-- -- consistent with a 2D result, just expressed as a 3-vector.
--
-- Every Object is Bullet mass 0 and hand-positioned each tick (mass in
-- this script means mass in the hand-rolled F=ma, not Bullet's own
-- rigid-body mass); obstacle spheres are drawn at exactly the obstacle's
-- repulsion radius, matching the force threshold exactly; every body
-- carries CF_NO_CONTACT_RESPONSE since Bullet's own collision detection
-- isn't used for anything here.
--
-- CONTROLS:
--   S       - start/stop the simulation (built into BPP; "Start"/"Stop")
--   A       - toggle world axis display (built into BPP; handy in 3D)
--   R       - Setup: re-scatter numParticles particles + one goal
--   2  / 3  - switch to 2D / 3D mode (re-scatters + switches the camera)
--   ]  / [  - Add / Remove a particle
--   D       - Disable a random active particle
--   F       - toggle "square" (see the caveat above) formation
--   G       - toggle goal attraction
--   C       - clear all obstacles
--   Left/Right (or J/L)  - move the cursor along world x
--   Up/Down    (or I/K)  - move the cursor along world z
--   Y  / H                - move the cursor along world y (3D mode only)
--   O       - drop an obstacle at the cursor's current position
--   .  / ,  - decrease / increase delayMs (speed up / slow down playback)
--   =  / -  - increase / decrease ticksPerFrame (fast-forward the sim)
--   V       - toggle neighbor-connection lines
--
-- Typed into the GUI's command line, for exact obstacle placement:
--   addObstacleAt(x, y, z)
--
-- numParticles, lennardJonesConstant, power, forceMaximum,
-- desiredSeparation, range, friction, timeStep, goalForce, obstacleSize,
-- delayMs and ticksPerFrame are all GUI sliders.
--

local common = require "common"

common.setTiming(1 / 30, 1, 1 / 30)
common.gravity(0) -- every body here is hand-positioned; no forces needed

-- math.atan2 was folded into a 2-argument math.atan in Lua 5.3+; kept for
-- completeness even though the 3D angular-momentum code below no longer
-- needs it.
local atan2 = math.atan2 or function(y, x) return math.atan(y, x) end

-- btCollisionObject::CollisionFlags. Nothing here needs Bullet's own
-- collision detection -- every interaction is the hand-rolled force law
-- below -- so every body gets NO_CONTACT_RESPONSE; bodies repositioned
-- each tick (particles, the goal, obstacles, the center-of-mass marker,
-- the cursor) are also flagged KINEMATIC_OBJECT rather than left static.
local CF_STATIC_OBJECT       = 1
local CF_KINEMATIC_OBJECT    = 2
local CF_NO_CONTACT_RESPONSE = 4

local function noCollideStatic(obj)
  obj.body:setCollisionFlags(CF_STATIC_OBJECT + CF_NO_CONTACT_RESPONSE)
  return obj
end

local function noCollideKinematic(obj)
  obj.body:setCollisionFlags(CF_KINEMATIC_OBJECT + CF_NO_CONTACT_RESPONSE)
  return obj
end

local function randomElement(t)
  if #t == 0 then return nil end
  return t[math.random(#t)]
end

--------------------------------------------------------------------------
-- World -- WORLD_WIDTH only ever sizes the initial cluster/goal offset
-- (the simulation itself is never clamped to it, in Kotlin or here);
-- kept purely so setup()'s initial placement matches the original app's
-- proportions.
--------------------------------------------------------------------------
local WORLD_WIDTH = 700.0

--------------------------------------------------------------------------
-- GUI parameters
--------------------------------------------------------------------------
local PARAM_INFO = {
  numParticles         = { min = 1,    max = 100, step = 1,
                           comment = "particles created the next time Setup (R) is pressed" },
  lennardJonesConstant = { min = 1,    max = 50,  step = 1,
                           comment = "overall strength of the particle-particle force" },
  power                = { min = 1,    max = 10,  step = 0.1,
                           comment = "steepness of the force curve" },
  forceMaximum         = { min = 1,    max = 5,   step = 0.1,
                           comment = "hard cap on the repulsive force magnitude" },
  desiredSeparation    = { min = 2,    max = 100, step = 1,
                           comment = "particle-particle equilibrium distance" },
  range                = { min = 1.0,  max = 5.0, step = 0.1,
                           comment = "interaction cutoff, as a multiple of desiredSeparation" },
  friction             = { min = 0,    max = 1,   step = 0.01,
                           comment = "fraction of velocity removed each tick (drag)" },
  timeStep             = { min = 0.01, max = 1,   step = 0.01,
                           comment = "simulated seconds integrated per tick" },
  goalForce            = { min = 0,    max = 1,   step = 0.01,
                           comment = "constant-magnitude attraction toward/from the goal" },
  obstacleSize         = { min = 0,    max = 100, step = 1,
                           comment = "obstacle repulsion radius (and its drawn radius)" },
  delayMs              = { min = 0,    max = 100, step = 1,
                           comment = "ms to wait between simulation steps (0 = as fast as possible)" },
  ticksPerFrame        = { min = 1,    max = 100, step = 1,
                           comment = "algorithm ticks run per rendered frame; raise to fast-forward" },
}

local function setParam(name, value)
  local info = PARAM_INFO[name]
  value = math.max(info.min, math.min(info.max, value))
  v:addParam(name, value, info.min, info.max, info.step, info.comment)
  return value
end

setParam("numParticles", 50)
setParam("lennardJonesConstant", 10)
setParam("power", 6)
setParam("forceMaximum", 1)
setParam("desiredSeparation", 50) -- see the header note on why 50, not the app's original 20
setParam("range", 1.5)
setParam("friction", 0.5)
setParam("timeStep", 1)
setParam("goalForce", 0.25)
setParam("obstacleSize", 10)
setParam("delayMs", 16) -- matches the app's delay(16), ~60 fps
setParam("ticksPerFrame", 1)

--------------------------------------------------------------------------
-- Colors -- matches SimulationView's Paint colors.
--------------------------------------------------------------------------
local COL_WHITE  = "#ffffff"
local COL_YELLOW = "#ffff00"
local COL_VIOLET = "#8a2be2" -- Color.rgb(138, 43, 226)
local COL_GOAL   = "#87ceeb" -- sky blue
local COL_OBS    = "#00ff00"
local COL_COM    = "#ff0000"
local COL_CURSOR = "#ff8800"
local COL_AXIS_X = "#ff4444"
local COL_AXIS_Y = "#44ff44"
local COL_AXIS_Z = "#4488ff"
local COL_LINE   = "#888888"

--------------------------------------------------------------------------
-- Simulation state -- each entity is a plain Lua table { x,y,z, vx,vy,vz,
-- fx,fy,fz, mass, id, obj, [color] }; x/y/z map directly onto this
-- scene's world axes.
--------------------------------------------------------------------------
local particles = {}
local goals = {}
local obstacles = {}
local nextId = 0

local isSquareFormation = false
local isGoalEnabled = false
local is3D = true
local disabledCount = 0

local centerOfMassX, centerOfMassY, centerOfMassZ = 0.0, 0.0, 0.0
local totalLinearMomentumX, totalLinearMomentumY, totalLinearMomentumZ = 0.0, 0.0, 0.0
local totalAngularMomentumX, totalAngularMomentumY, totalAngularMomentumZ = 0.0, 0.0, 0.0

local comMarker = Sphere(2.0, 0)
comMarker.col = COL_COM
comMarker.pos = btVector3(0, 0, 0)
v:add(comMarker)
noCollideKinematic(comMarker)

--------------------------------------------------------------------------
-- Cursor -- the tap-replacement for placing obstacles (BPP's Lua API has
-- no mouse-click hook). A bright marker plus a small RGB axis gizmo (X
-- red, Y green, Z blue) sits at (cursorX, cursorY, cursorZ); the arrow
-- keys / IJKL slide it across x/z, Y/H slide it along y, and O drops an
-- obstacle there. The gizmo is rebuilt on every move rather than reused
-- -- cheap, since moving the cursor is a discrete keypress.
--------------------------------------------------------------------------
local CURSOR_STEP = 15
local CURSOR_TICK = 10

local cursorX, cursorY, cursorZ = 0.0, 0.0, 0.0
local cursorMarker = nil
local cursorAxes = {}

local function drawCursor()
  if cursorMarker then v:remove(cursorMarker) end
  for _, o in ipairs(cursorAxes) do v:remove(o) end
  cursorAxes = {}

  cursorMarker = Sphere(2.5, 0)
  cursorMarker.col = COL_CURSOR
  cursorMarker.pos = btVector3(cursorX, cursorY, cursorZ)
  v:add(cursorMarker)
  noCollideKinematic(cursorMarker)

  local function tick(dx, dy, dz, col)
    local cy = common.placeCylinder(
      btVector3(cursorX, cursorY, cursorZ),
      btVector3(cursorX + dx, cursorY + dy, cursorZ + dz),
      0.35, col)
    noCollideStatic(cy)
    cursorAxes[#cursorAxes + 1] = cy
  end
  tick(CURSOR_TICK, 0, 0, COL_AXIS_X)
  if is3D then tick(0, CURSOR_TICK, 0, COL_AXIS_Y) end
  tick(0, 0, CURSOR_TICK, COL_AXIS_Z)
end

local function moveCursor(dx, dy, dz)
  cursorX = cursorX + dx
  cursorY = is3D and (cursorY + dy) or 0
  cursorZ = cursorZ + dz
  drawCursor()
end

drawCursor()

local function particleColorHex(p)
  if p.mass > 1 then return COL_VIOLET end
  if p.color == 0 then return COL_WHITE end
  return COL_YELLOW
end

local function newEntity(x, y, z, mass)
  local e = { x = x, y = y, z = z, vx = 0, vy = 0, vz = 0,
              fx = 0, fy = 0, fz = 0, mass = mass, id = nextId }
  nextId = nextId + 1
  return e
end

-- Square-formation view/modifiedR parameters -- factored out so both the
-- force computation below AND the neighbor-line visualization agree on
-- exactly what counts as a "neighbor" for the force law.
-- Square-formation view/modifiedR parameters -- factored out so both the
-- force computation below AND the neighbor-line visualization agree on
-- exactly what counts as a "neighbor" for the force law.
--
-- The same-spin divisor is sqrt(2) in BOTH 2D and 3D: a face diagonal is
-- always sqrt(2) x the edge length, in any dimension, since it's the same
-- 2D Pythagorean relationship regardless of which face it's embedded in.
-- An earlier version of this used 2^(1/3) in 3D, reasoned from a
-- "dimensional scaling" heuristic (2D uses a 1/2 power, so 3D should use
-- a 1/3 power) that doesn't correspond to any real cube geometry -- it
-- modeled the face-diagonal equilibrium at desiredSeparation*2^(1/3)
-- (63.0 for desiredSeparation=50) instead of the true
-- desiredSeparation*sqrt(2) (70.7), an 11% error that measurably distorts
-- the lattice even under LJ's smooth force curve (verified directly: the
-- same setup with the old divisor peaks its second shell at ~61-63; with
-- the corrected one, sharply at ~70).
--
-- The 3D view thresholds are NOT scaled by the general "range" slider the
-- way 2D's are. In 3D, "different spin" under a binary checkerboard
-- coloring contains BOTH face-adjacent pairs (true distance =
-- desiredSeparation, what we WANT to attract at) AND body-diagonal pairs
-- (true distance = desiredSeparation*sqrt(3), which a 2-label spin can't
-- tell apart from face-adjacent -- see the header note on why a binary
-- spin can't build a true cube). If body-diagonal pairs are allowed to
-- interact at all, they get pulled toward the wrong, too-short
-- equilibrium meant for face-adjacent pairs. The fix is to exclude them
-- from the interaction range entirely rather than trying to target them
-- correctly. At the default range=1.5, the old proportional cutoff
-- (diffView*desiredSeparation = 85 for desiredSeparation=50) sat only
-- 1.9% below the true body-diagonal distance (86.6) -- since particles
-- never sit exactly on ideal lattice positions while still
-- self-organizing, body-diagonal pairs constantly flickered in and out
-- of that razor-thin margin, which is exactly the instability that kept
-- a clean cube from forming. Fixed 3D-only constants instead, centered
-- with real margin on both sides (comfortably above the
-- desiredSeparation-scale equilibrium, comfortably below
-- desiredSeparation*sqrt(3)).
--------------------------------------------------------------------------
local CUBIC_VIEW_3D = 1.3 -- 3D square-formation view multiplier (both same- and different-spin)

local function squareFormationParams(p)
  local divisor = math.sqrt(2)
  local sameView, diffView
  if is3D then
    sameView, diffView = CUBIC_VIEW_3D, CUBIC_VIEW_3D
  else
    sameView = p.range * (1.3 / 1.5)
    diffView = p.range * (1.7 / 1.5)
  end
  return divisor, sameView, diffView
end

local function neighborViewAndR(id1, id2, r, p, divisor, sameView, diffView)
  local view = p.range
  local modifiedR = r
  if isSquareFormation then
    if (id1 % 2) == (id2 % 2) then
      view = sameView
      modifiedR = r / divisor
    else
      view = diffView
    end
  end
  return view, modifiedR
end

--------------------------------------------------------------------------
-- Physics -- every entity's force/velocity/delta is computed against
-- everyone ELSE's *current* position; nothing actually moves until
-- moveAll(), matching a proper compute-then-move pass (not sequential
-- mutation mid-loop).
--------------------------------------------------------------------------
local function updateParticles(p)
  local squareDivisor, squareSameView, squareDiffView = squareFormationParams(p)

  for _, particle in ipairs(particles) do
    particle.fx, particle.fy, particle.fz = 0, 0, 0
    particle.vx = particle.vx * (1 - p.friction)
    particle.vy = particle.vy * (1 - p.friction)
    particle.vz = particle.vz * (1 - p.friction)

    for _, other in ipairs(particles) do
      if other.id ~= particle.id then
        local dx = other.x - particle.x
        local dy = other.y - particle.y
        local dz = other.z - particle.z
        local r = math.sqrt(dx * dx + dy * dy + dz * dz)
        if r < 0.1 then r = 0.1 end

        local view, modifiedR = neighborViewAndR(particle.id, other.id, r, p,
                                                   squareDivisor, squareSameView, squareDiffView)

        if modifiedR < view * p.desiredSeparation then
          -- Smooth dual-power curve, mass-independent, that crosses zero
          -- (attractive -> repulsive) at desiredSeparation on its own.
          local dp2 = p.desiredSeparation ^ (2 * p.power)
          local rp1 = modifiedR ^ (2 * p.power + 1)
          local dp  = p.desiredSeparation ^ p.power
          local rp  = modifiedR ^ (p.power + 1)
          local f = p.lennardJonesConstant * ((dp2 / rp1) - (dp / rp))
          if f > p.forceMaximum then f = p.forceMaximum end

          particle.fx = particle.fx - f * (dx / r)
          particle.fy = particle.fy - f * (dy / r)
          particle.fz = particle.fz - f * (dz / r)
        end
      end
    end

    for _, obs in ipairs(obstacles) do
      local dx = obs.x - particle.x
      local dy = obs.y - particle.y
      local dz = obs.z - particle.z
      local r = math.sqrt(dx * dx + dy * dy + dz * dz)
      if r <= p.obstacleSize then
        local f = p.obstacleSize - r
        particle.fx = particle.fx - f * (dx / r)
        particle.fy = particle.fy - f * (dy / r)
        particle.fz = particle.fz - f * (dz / r)
      end
    end

    if isGoalEnabled then
      for _, goal in ipairs(goals) do
        local dx = goal.x - particle.x
        local dy = goal.y - particle.y
        local dz = goal.z - particle.z
        local r = math.sqrt(dx * dx + dy * dy + dz * dz)
        if r > 0.1 then
          local f = p.goalForce
          particle.fx = particle.fx + f * (dx / r)
          particle.fy = particle.fy + f * (dy / r)
          particle.fz = particle.fz + f * (dz / r)
        end
      end
    end

    local dvx = p.timeStep * (particle.fx / particle.mass)
    local dvy = p.timeStep * (particle.fy / particle.mass)
    local dvz = p.timeStep * (particle.fz / particle.mass)
    particle.vx = particle.vx + dvx
    particle.vy = particle.vy + dvy
    particle.vz = particle.vz + dvz

    particle.dx = p.timeStep * particle.vx
    particle.dy = p.timeStep * particle.vy
    particle.dz = p.timeStep * particle.vz
  end
end

local function updateGoals(p)
  for _, goal in ipairs(goals) do
    goal.fx, goal.fy, goal.fz = 0, 0, 0
    goal.vx = goal.vx * (1 - p.friction)
    goal.vy = goal.vy * (1 - p.friction)
    goal.vz = goal.vz * (1 - p.friction)

    for _, particle in ipairs(particles) do
      local dx = particle.x - goal.x
      local dy = particle.y - goal.y
      local dz = particle.z - goal.z
      local r = math.sqrt(dx * dx + dy * dy + dz * dz)
      if r > 0.1 then
        local f = p.goalForce
        goal.fx = goal.fx + f * (dx / r)
        goal.fy = goal.fy + f * (dy / r)
        goal.fz = goal.fz + f * (dz / r)
      end
    end

    local dvx = p.timeStep * (goal.fx / goal.mass)
    local dvy = p.timeStep * (goal.fy / goal.mass)
    local dvz = p.timeStep * (goal.fz / goal.mass)
    goal.vx = goal.vx + dvx
    goal.vy = goal.vy + dvy
    goal.vz = goal.vz + dvz

    goal.dx = p.timeStep * goal.vx
    goal.dy = p.timeStep * goal.vy
    goal.dz = p.timeStep * goal.vz
  end
end

local function updateObstacles(p)
  for _, obs in ipairs(obstacles) do
    obs.fx, obs.fy, obs.fz = 0, 0, 0
    obs.vx = obs.vx * (1 - p.friction)
    obs.vy = obs.vy * (1 - p.friction)
    obs.vz = obs.vz * (1 - p.friction)

    for _, particle in ipairs(particles) do
      local dx = particle.x - obs.x
      local dy = particle.y - obs.y
      local dz = particle.z - obs.z
      local r = math.sqrt(dx * dx + dy * dy + dz * dz)
      if r <= p.obstacleSize then
        local f = p.obstacleSize - r
        obs.fx = obs.fx - f * (dx / r)
        obs.fy = obs.fy - f * (dy / r)
        obs.fz = obs.fz - f * (dz / r)
      end
    end

    local dvx = p.timeStep * (obs.fx / obs.mass)
    local dvy = p.timeStep * (obs.fy / obs.mass)
    local dvz = p.timeStep * (obs.fz / obs.mass)
    obs.vx = obs.vx + dvx
    obs.vy = obs.vy + dvy
    obs.vz = obs.vz + dvz

    obs.dx = p.timeStep * obs.vx
    obs.dy = p.timeStep * obs.vy
    obs.dz = p.timeStep * obs.vz
  end
end

local function moveAll()
  for _, e in ipairs(particles) do e.x = e.x + e.dx; e.y = e.y + e.dy; e.z = e.z + e.dz end
  for _, e in ipairs(goals) do e.x = e.x + e.dx; e.y = e.y + e.dy; e.z = e.z + e.dz end
  for _, e in ipairs(obstacles) do e.x = e.x + e.dx; e.y = e.y + e.dy; e.z = e.z + e.dz end
end

local function updateCenterOfMass()
  local totalMassX, totalMassY, totalMassZ, totalMass = 0.0, 0.0, 0.0, 0.0
  local function accumulate(list)
    for _, e in ipairs(list) do
      totalMassX = totalMassX + e.x * e.mass
      totalMassY = totalMassY + e.y * e.mass
      totalMassZ = totalMassZ + e.z * e.mass
      totalMass = totalMass + e.mass
    end
  end
  accumulate(particles)
  if isGoalEnabled then accumulate(goals) end
  accumulate(obstacles)

  if totalMass == 0 then return end
  centerOfMassX = totalMassX / totalMass
  centerOfMassY = totalMassY / totalMass
  centerOfMassZ = totalMassZ / totalMass
end

-- Angular momentum is a genuine 3-vector: L = sum(m * (r x v)), with r
-- measured from the center of mass. A cross product needs no epsilon
-- guards since it's perfectly well-defined (and simply contributes zero)
-- at zero speed or zero lever arm.
local function updateMomentum()
  totalLinearMomentumX, totalLinearMomentumY, totalLinearMomentumZ = 0.0, 0.0, 0.0
  totalAngularMomentumX, totalAngularMomentumY, totalAngularMomentumZ = 0.0, 0.0, 0.0

  local function accumulate(list)
    for _, e in ipairs(list) do
      totalLinearMomentumX = totalLinearMomentumX + e.mass * e.vx
      totalLinearMomentumY = totalLinearMomentumY + e.mass * e.vy
      totalLinearMomentumZ = totalLinearMomentumZ + e.mass * e.vz

      local rx = e.x - centerOfMassX
      local ry = e.y - centerOfMassY
      local rz = e.z - centerOfMassZ

      totalAngularMomentumX = totalAngularMomentumX + e.mass * (ry * e.vz - rz * e.vy)
      totalAngularMomentumY = totalAngularMomentumY + e.mass * (rz * e.vx - rx * e.vz)
      totalAngularMomentumZ = totalAngularMomentumZ + e.mass * (rx * e.vy - ry * e.vx)
    end
  end

  accumulate(particles)
  if isGoalEnabled then accumulate(goals) end
  accumulate(obstacles)
end

local function readParams()
  return {
    lennardJonesConstant = v:getParam("lennardJonesConstant"),
    power = v:getParam("power"),
    forceMaximum = v:getParam("forceMaximum"),
    desiredSeparation = v:getParam("desiredSeparation"),
    range = v:getParam("range"),
    friction = v:getParam("friction"),
    timeStep = v:getParam("timeStep"),
    goalForce = v:getParam("goalForce"),
    obstacleSize = v:getParam("obstacleSize"),
  }
end

local function simUpdate()
  local p = readParams()
  updateParticles(p)
  updateGoals(p)
  updateObstacles(p)
  moveAll()
  updateCenterOfMass()
  updateMomentum()
end

--------------------------------------------------------------------------
-- Neighbor lines -- draws a thin cylinder between every particle pair
-- currently connected, matching Physics.java's own neighbors() function
-- (the one that drives its "Connect" checkbox) rather than the force
-- law's own neighbor definition. Same-spin ("diagonal") pairs in square
-- formation still feel a force -- that's what holds the diagonal spacing
-- correct -- but this deliberately excludes them from the drawn graph
-- for SQUARE formation (only "edge" pairs are connected), using the RAW
-- distance with a flat cutoff, no same-spin discount and no
-- formation-dependent view multiplier. Reusing the force law's own
-- neighbor set here would draw both edges AND diagonals, which is
-- exactly the "crossed-out square" clutter this avoids. Toggle with V.
--------------------------------------------------------------------------
local showNeighborLines = true
local MAX_NEIGHBOR_LINES_PER_PARTICLE = 12
local LINE_RADIUS = 0.15
local neighborLineObjs = {}

local function clearNeighborLines()
  for _, cy in ipairs(neighborLineObjs) do v:remove(cy) end
  neighborLineObjs = {}
end

-- Cylinders can't be resized/re-endpointed in place (only translated), so
-- unlike sphere positions this genuinely has to remove-and-recreate every
-- update -- cheap for a modest particle count, but see the V toggle and
-- the frame-throttling in postSim below if it becomes a bottleneck.
local function updateNeighborLines(p)
  clearNeighborLines()
  if not showNeighborLines then return end

  -- Matches whatever the force law's own different-spin cutoff actually
  -- is for the current mode -- CUBIC_VIEW_3D*desiredSeparation for 3D
  -- square (fixed, decoupled from the range slider, see
  -- squareFormationParams()), otherwise range*desiredSeparation as
  -- before.
  local cutoff = (is3D and isSquareFormation) and (CUBIC_VIEW_3D * p.desiredSeparation)
                                               or (p.range * p.desiredSeparation)

  for _, particle in ipairs(particles) do
    local count = 0
    for _, other in ipairs(particles) do
      if other.id > particle.id and count < MAX_NEIGHBOR_LINES_PER_PARTICLE then
        local include = true
        if isSquareFormation then
          include = (particle.id % 2) ~= (other.id % 2) -- SQUARE: edges only, no diagonals
        end
        if include then
          local dx = other.x - particle.x
          local dy = other.y - particle.y
          local dz = other.z - particle.z
          local r = math.sqrt(dx * dx + dy * dy + dz * dz)
          if r < cutoff then
            local cy = common.placeCylinder(
              btVector3(particle.x, particle.y, particle.z),
              btVector3(other.x, other.y, other.z),
              LINE_RADIUS, COL_LINE)
            noCollideStatic(cy)
            neighborLineObjs[#neighborLineObjs + 1] = cy
            count = count + 1
          end
        end
      end
    end
  end
end

--------------------------------------------------------------------------
-- Entity <-> Object bookkeeping
--------------------------------------------------------------------------
local function spawnParticleObj(pt)
  local obj = Sphere(1.0, 0)
  obj.col = particleColorHex(pt)
  obj.pos = btVector3(pt.x, pt.y, pt.z)
  v:add(obj)
  noCollideKinematic(obj)
  pt.obj = obj
end

local lastObstacleSize = v:getParam("obstacleSize")

-- Obstacle spheres are drawn at exactly obstacleSize, matching the force
-- threshold (r <= obstacleSize) exactly. Since Bullet shapes can't be
-- resized in place, changing the obstacleSize slider rebuilds existing
-- obstacles (see postSim below); cheap since it's a rare user action.
local function spawnObstacleObj(obs)
  local radius = v:getParam("obstacleSize")
  local obj = Sphere(math.max(radius, 0.5), 0)
  obj.col = COL_OBS
  obj.pos = btVector3(obs.x, obs.y, obs.z)
  v:add(obj)
  noCollideKinematic(obj)
  obs.obj = obj
end

--------------------------------------------------------------------------
-- setup() -- re-scatters a genuine 3D (or flat 2D) cluster.
--------------------------------------------------------------------------
function setup(n)
  for _, e in ipairs(particles) do v:remove(e.obj) end
  for _, e in ipairs(goals) do v:remove(e.obj) end
  for _, e in ipairs(obstacles) do v:remove(e.obj) end
  clearNeighborLines() -- else stale lines from before a reset linger while stopped
  particles, goals, obstacles = {}, {}, {}
  disabledCount = 0
  nextId = 0

  -- Initial scatter width is 2x desiredSeparation -- without this,
  -- particles start packed far closer together than their actual
  -- equilibrium spacing and violently fly apart the instant the sim
  -- starts.
  local jitter = 2 * v:getParam("desiredSeparation")

  for i = 0, n - 1 do
    local x = WORLD_WIDTH / 3 + math.random() * jitter - jitter / 2
    local y = is3D and (math.random() * jitter - jitter / 2) or 0
    local z = math.random() * jitter - jitter / 2
    local pt = newEntity(x, y, z, 1)
    pt.color = (i % 2 == 0) and 0 or 1
    particles[#particles + 1] = pt
    spawnParticleObj(pt)
  end

  local goal = newEntity(-WORLD_WIDTH / 3, 0, 0, 100000)
  goals[#goals + 1] = goal
  local gobj = Sphere(3.0, 0)
  gobj.col = COL_GOAL
  gobj.pos = btVector3(goal.x, goal.y, goal.z)
  v:add(gobj)
  noCollideKinematic(gobj)
  goal.obj = gobj

  updateCenterOfMass()
  updateMomentum()

  print(string.format("setup: %d particles", n))
end

--------------------------------------------------------------------------
-- Actions -- global on purpose, so they double as GUI shortcuts AND as
-- commands typeable into the GUI's command line (see v:onCommand below).
--------------------------------------------------------------------------
function toggleFormation()
  isSquareFormation = not isSquareFormation
  updateCenterOfMass()
  updateMomentum()
  print("alternate-packing formation = " .. tostring(isSquareFormation))
end

function toggleGoal()
  isGoalEnabled = not isGoalEnabled
  updateCenterOfMass()
  updateMomentum()
  print("goal enabled = " .. tostring(isGoalEnabled))
end

-- Switches between 2D (every entity pinned to y=0) and 3D. Re-scatters
-- via setup() so no stale off-plane/on-plane positions linger, and
-- switches the camera to match.
function setDimension(want3D)
  is3D = want3D
  cursorY = is3D and cursorY or 0
  updateCamera()
  setup(math.floor(v:getParam("numParticles")))
  drawCursor()
  print("dimension = " .. (is3D and "3D" or "2D"))
end

-- BPP's Lua API has no mouse-click hook, so this takes (x, y, z) directly
-- -- type "addObstacleAt(50, 0, -30)" into the GUI's command line for
-- exact placement, or use the O shortcut for the cursor's current
-- position. In 2D mode, y is always snapped to 0.
function addObstacleAt(x, y, z)
  if not is3D then y = 0 end
  local obs = newEntity(x, y, z, 100000)
  obstacles[#obstacles + 1] = obs
  spawnObstacleObj(obs)
  updateCenterOfMass()
  updateMomentum()
end

function clearObstacles()
  for _, e in ipairs(obstacles) do v:remove(e.obj) end
  obstacles = {}
  updateCenterOfMass()
  updateMomentum()
end

function addParticle()
  if #particles == 0 then return end
  local sep = v:getParam("desiredSeparation")
  local template = randomElement(particles)
  local x = template.x + math.random() * sep / 2 - sep / 4
  local y = is3D and (template.y + math.random() * sep / 2 - sep / 4) or 0
  local z = template.z + math.random() * sep / 2 - sep / 4
  local pt = newEntity(x, y, z, 1)
  pt.color = (nextId % 2 == 0) and 0 or 1
  particles[#particles + 1] = pt
  spawnParticleObj(pt)
  updateCenterOfMass()
  updateMomentum()
end

function removeParticle()
  local active = {}
  for _, e in ipairs(particles) do
    if e.mass == 1 then active[#active + 1] = e end
  end
  if #active > 1 then
    local victim = randomElement(active)
    for i, e in ipairs(particles) do
      if e.id == victim.id then
        v:remove(e.obj)
        table.remove(particles, i)
        break
      end
    end
    updateCenterOfMass()
    updateMomentum()
  end
end

function disableParticle()
  local active = {}
  for _, e in ipairs(particles) do
    if e.mass == 1 then active[#active + 1] = e end
  end
  if #active > 1 then
    local victim = randomElement(active)
    victim.mass = 100000
    victim.obj.col = COL_VIOLET
    disabledCount = disabledCount + 1
    updateCenterOfMass()
    updateMomentum()
  end
end

--------------------------------------------------------------------------
-- GUI shortcuts
--------------------------------------------------------------------------
v:addShortcut("R", function(N) setup(math.floor(v:getParam("numParticles"))) end)
v:addShortcut("2", function(N) setDimension(false) end)
v:addShortcut("3", function(N) setDimension(true) end)
v:addShortcut("]", function(N) addParticle() end)
v:addShortcut("[", function(N) removeParticle() end)
v:addShortcut("D", function(N) disableParticle() end)
v:addShortcut("F", function(N) toggleFormation() end)
v:addShortcut("G", function(N) toggleGoal() end)
v:addShortcut("C", function(N) clearObstacles() end)

v:addShortcut("V", function(N)
  showNeighborLines = not showNeighborLines
  if not showNeighborLines then clearNeighborLines() end
  print("neighbor lines = " .. tostring(showNeighborLines))
end)


v:addShortcut("O", function(N)
  addObstacleAt(cursorX, cursorY, cursorZ)
end)

-- x/z via arrows or IJKL, y via a Y/H pair (Y sits directly above H on a
-- QWERTY keyboard -- up/down).
v:addShortcut("Left",  function(N) moveCursor(-CURSOR_STEP, 0, 0) end)
v:addShortcut("Right", function(N) moveCursor(CURSOR_STEP, 0, 0) end)
v:addShortcut("Up",    function(N) moveCursor(0, 0, -CURSOR_STEP) end)
v:addShortcut("Down",  function(N) moveCursor(0, 0, CURSOR_STEP) end)
v:addShortcut("J", function(N) moveCursor(-CURSOR_STEP, 0, 0) end)
v:addShortcut("L", function(N) moveCursor(CURSOR_STEP, 0, 0) end)
v:addShortcut("I", function(N) moveCursor(0, 0, -CURSOR_STEP) end)
v:addShortcut("K", function(N) moveCursor(0, 0, CURSOR_STEP) end)
v:addShortcut("Y", function(N) moveCursor(0, CURSOR_STEP, 0) end)
v:addShortcut("H", function(N) moveCursor(0, -CURSOR_STEP, 0) end)

local DELAY_STEP = 5
v:addShortcut(".", function(N)
  local d = setParam("delayMs", math.floor(v:getParam("delayMs")) - DELAY_STEP)
  print(string.format("delayMs = %d", d))
end)
v:addShortcut(",", function(N)
  local d = setParam("delayMs", math.floor(v:getParam("delayMs")) + DELAY_STEP)
  print(string.format("delayMs = %d", d))
end)

local TICKS_PER_FRAME_STEP = 1
v:addShortcut("=", function(N)
  local t = setParam("ticksPerFrame", math.floor(v:getParam("ticksPerFrame")) + TICKS_PER_FRAME_STEP)
  print(string.format("ticksPerFrame = %d", t))
end)
v:addShortcut("-", function(N)
  local t = setParam("ticksPerFrame", math.floor(v:getParam("ticksPerFrame")) - TICKS_PER_FRAME_STEP)
  print(string.format("ticksPerFrame = %d", t))
end)

-- Lets the GUI's command line run typed Lua, e.g. addObstacleAt(50,0,-30).
v:onCommand(function(N, cmd)
  local f = assert(loadstring(cmd))
  f(v)
end)

--------------------------------------------------------------------------
-- Per-frame update
--------------------------------------------------------------------------
local STATS_EVERY = 30
local LINE_UPDATE_EVERY = 3
local lineFrameCounter = 0
local lastStepWallTime = os.clock()
local frameTicks = 0

v:preStart(function(N)
  print("AP: Lennard-Jones 3D -- R: setup  2/3: dimension  ]/[: add/remove  D: disable  F: formation")
  print("  G: goal  C: clear  cursor: arrows/IJKL (x/z) Y/H (y)  O: obstacle  S: start/stop")
  print("  ,/. and =/-: speed  V: lines  A: axes")
end)

v:postSim(function(N)
  local delayMs = v:getParam("delayMs")
  local now = os.clock()
  if delayMs > 0 and (now - lastStepWallTime) * 1000.0 < delayMs then
    return
  end
  lastStepWallTime = now

  local batch = math.max(1, math.floor(v:getParam("ticksPerFrame")))
  local ticksBefore = frameTicks

  for _ = 1, batch do
    simUpdate()
    frameTicks = frameTicks + 1
  end

  local obstacleSize = v:getParam("obstacleSize")
  if obstacleSize ~= lastObstacleSize then
    lastObstacleSize = obstacleSize
    for _, obs in ipairs(obstacles) do
      v:remove(obs.obj)
      spawnObstacleObj(obs)
    end
  end

  for _, e in ipairs(particles) do e.obj.pos = btVector3(e.x, e.y, e.z) end
  for _, e in ipairs(goals) do e.obj.pos = btVector3(e.x, e.y, e.z) end
  for _, e in ipairs(obstacles) do e.obj.pos = btVector3(e.x, e.y, e.z) end
  comMarker.pos = btVector3(centerOfMassX, centerOfMassY, centerOfMassZ)

  lineFrameCounter = lineFrameCounter + 1
  if lineFrameCounter % LINE_UPDATE_EVERY == 0 then
    updateNeighborLines(readParams())
  end

  if math.floor(frameTicks / STATS_EVERY) > math.floor(ticksBefore / STATS_EVERY) then
    print(string.format(
      "particles=%d disabled=%d obstacles=%d dim=%s square=%s goal=%s P=(%.2f,%.2f,%.2f) L=(%.2f,%.2f,%.2f)",
      #particles, disabledCount, #obstacles, (is3D and "3D" or "2D"),
      tostring(isSquareFormation), tostring(isGoalEnabled),
      totalLinearMomentumX, totalLinearMomentumY, totalLinearMomentumZ,
      totalAngularMomentumX, totalAngularMomentumY, totalAngularMomentumZ))
  end
end)

--------------------------------------------------------------------------
-- Camera -- switches with dimension. 3D: symmetric isometric-style view,
-- equally inclined to all three axes so no axis is foreshortened more
-- than another. 2D: straight-down, narrow-FOV "pseudo orthogonal" view.
--------------------------------------------------------------------------
function updateCamera()
  if is3D then
    common.setCamera(btVector3(400, 320, 400), btVector3(0, 0, 0))
  else
    common.setCamera(btVector3(0, 3000, 0), btVector3(0, 0, 0), 0.3,
                      { horizontal = true, up = btVector3(0, 0, -1) })
  end
end

--------------------------------------------------------------------------
-- Shortcuts panel text -- sent to BPP's native "Shortcuts" dock (see
-- v:setHelpText() in viewer.h/gui.cpp) if that panel exists, so the
-- controls are visible immediately on load, before pressing S, in a
-- persistent panel rather than only a scrolling console print. pcall'd
-- since setHelpText() is a newer addition to BPP itself -- running this
-- script against a BPP build that predates it should just skip the panel
-- update rather than fail to load the whole script; preStart's console
-- print (further up) remains the fallback either way.
--------------------------------------------------------------------------
local HELP_TEXT = [[
AP: Lennard-Jones 3D

S        start/stop the simulation
A        toggle world axis display
R        Setup: re-scatter agents + goal
2 / 3    switch to 2D / 3D mode

]        Add a particle
[        Remove a particle
D        Disable a random active particle
F        toggle square formation
G        toggle goal attraction
C        clear all obstacles

Cursor (for placing obstacles):
  Left/Right or J/L   move along x
  Up/Down    or I/K   move along z
  Y / H               move along y (3D only)
  O                   drop an obstacle here

.  /  ,   faster / slower playback (delayMs)
=  /  -   more / fewer ticks per frame
V         toggle neighbor-connection lines
]]

pcall(function() v:setHelpText(HELP_TEXT) end)

math.randomseed(os.time())
updateCamera()
setup(math.floor(v:getParam("numParticles")))

-- EOF
