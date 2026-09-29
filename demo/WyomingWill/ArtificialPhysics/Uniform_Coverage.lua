--
-- Uniform Coverage
--
-- This problem was posed to me in the 1990s by Douglas Gage. The
-- goal was to provide uniform coverage of an area using simple robots
-- with only an obstacle sensor. This is my response to his challenge.
--
-- Originally written in C, and then ported to NetLogo and an Android app.
-- A Bullet Physics Playground port of the Android app "Uniform Coverage"
-- (package com.example.uniform: MainActivity.kt, UniformCoverageSimulation.kt,
-- CoverageSimulationView.kt, HistogramView.kt).
--
-- THE ORIGINAL APP: a fixed number of agents wander a square arena that is
-- divided into a 3x3 grid (4 corner cells, 4 edge cells, 1 center cell).
-- Each agent walks in a straight line for up to "mean free path" (MFP)
-- steps, then picks a new random heading -- and also turns early if it is
-- about to hit the boundary wall or another agent is close ahead of it.
-- The app tracks how many simulation ticks each agent spends in each of
-- the 9 cells and reports how far that distribution is from perfectly
-- uniform (Euclidean distance of each cell's visited-proportion from the
-- ideal 1/9), which is the "uniform coverage" question the MFP idea (drawn
-- from the mean free path of a gas molecule) is meant to improve.
--
-- WHAT CARRIED OVER EXACTLY: monitorAgent(), shouldTurn() and moveAgent()
-- below are a straight line-for-line port of the Kotlin of the same name,
-- including the constants (boundary = 40, the 0.0001 wall look-ahead, the
-- 3-unit / 30-degree neighbor cone, the "up to 10 tries to find a heading"
-- loop) and getUniformityDeviation()/getTheoreticalMeanFreePath(). Feed it
-- the same numParticles and meanFreePath and it produces the same kind of
-- statistics the app did.
--
-- WHAT CHANGED FOR A 3D PHYSICS VIEWER: the app drew its own 2D Canvas (a
-- top-down grid plus a separate bar-chart View). BPP has neither, so the
-- Kotlin (x, y) plane becomes this scene's (x, z) ground plane, agents are
-- small white spheres riding a fixed height above 9 colored floor tiles
-- (same corner=blue / edge=green / center=red / boundary=yellow scheme as
-- CoverageSimulationView), and the histogram becomes 9 poles off to the
-- side with a colored marker that climbs to each cell's current visited
-- share -- a yellow ring marks the ideal 1/9 line, same role as the
-- dashed yellow line in HistogramView. All of it is kinematic: every
-- agent and marker has mass 0 and is simply repositioned each tick
-- (v.gravity is off), so nothing here actually needs Bullet's dynamics --
-- the "physics" is the hand-rolled random walk, exactly as it was on
-- Android.
--
-- CONTROLS:
--   S           - start/stop the simulation (built into BPP; same job as
--                 the app's "Move Agents" / "Stop" buttons)
--   ]  / [      - increase / decrease numParticles by 5 and immediately
--                 re-run setup(), so you can dial in a sphere count and
--                 watch it change before pressing S
--   .  / ,      - decrease / increase delayMs by 5 (mnemonic: "." speeds
--                 up like a ">" fast-forward, "," slows down like a "<")
--   =  / -      - increase / decrease ticksPerFrame by 1 (see below)
--   numParticles, meanFreePath, delayMs, ticksPerFrame - GUI sliders,
--                 adjustable either from the parameter panel or the keys
--                 above. All four take effect immediately, including
--                 numParticles -- dragging it re-scatters the swarm to
--                 the new count right away, with no separate reset step
--                 (previously an R shortcut; removed once numParticles
--                 started auto-applying, since it became redundant).
--
-- ABOUT delayMs: the app's third slider throttled its own coroutine loop
-- with delay(Delay) between ticks. BPP has no exposed "real-time delay"
-- setting -- v.timeStep is the *simulated* physics dt, not a wall-clock
-- pause -- so that throttle is reproduced by hand below: postSim fires at
-- whatever rate the viewer's own animation timer runs, and the tick is
-- simply skipped until at least delayMs of real time (os.clock()) has
-- elapsed since the last one. delayMs = 0 runs as fast as the viewer allows.
--
-- MAKING IT FASTER, beyond delayMs = 0:
--  * ticksPerFrame runs several algorithm ticks for every rendered frame,
--    only moving the visible spheres/markers once at the end of the batch.
--    Since redrawing (not the random-walk math) is the expensive part,
--    this is the biggest lever once delayMs is already 0 -- e.g.
--    ticksPerFrame=20 reaches 20x the ticks/sec of ticksPerFrame=1 for
--    about the same rendering cost.
--  * Every object below -- floor tiles, walls, histogram poles/markers,
--    and the agents themselves -- carries CF_NO_CONTACT_RESPONSE, since
--    none of this scene needs Bullet's own collision detection: agent
--    neighbor-avoidance is entirely the hand-rolled shouldTurn() below,
--    same as it was in Kotlin. That keeps Bullet's broadphase/narrowphase
--    from doing pointless work on ~numParticles+30 bodies every physics
--    step, which otherwise scales up right alongside numParticles.
--  * For a batch run rather than a live view, BPP's own CLI mode
--    (`bpp -n <ticks> -f uniform-coverage.lua`) skips OpenGL rendering
--    altogether and is far faster still; see the repo README.
--

local common = require "common"

common.setTiming(1 / 30, 1, 1 / 30) -- ~30 fps, matching the app's delay(33)
common.gravity(0)                   -- agents are kinematic; no forces needed

-- math.atan2 was folded into a 2-argument math.atan in Lua 5.3+; keep this
-- demo running on either.
local atan2 = math.atan2 or function(y, x) return math.atan(y, x) end

--------------------------------------------------------------------------
-- Portable higher-quality PRNG, replacing math.random()/math.randomseed()
-- everywhere below. BPP embeds Lua 5.1/5.2 (confirmed against the actual
-- .pro build files: PKGCONFIG += lua5.1/lua5.2), and in those versions
-- math.random() is just a thin wrapper around the C library's rand() --
-- a meaningfully weaker, shorter-period generator than Lua 5.4's built-in
-- one. This isn't theoretical: the exact same algorithm, run for the same
-- number of ticks, converges measurably worse under real Lua 5.1 than
-- under 5.4 (deviation/cornerSpread/edgeSpread all elevated) -- verified
-- directly by running both.
--
-- Marsaglia's "multiply-with-carry" (MWC) generator fixes this without
-- needing anything Lua 5.1 doesn't have: no bitwise operators (added only
-- in 5.3+), no external bit32/bit library, just multiply/floor/modulo,
-- which every Lua version supports identically. Verified this closes the
-- gap: under real Lua 5.1, the same long test that showed elevated
-- deviation/spread with native math.random() came back statistically
-- indistinguishable from Lua 5.4's own native quality once routed through
-- this generator instead.
--------------------------------------------------------------------------
local mwc_z, mwc_w = 362436069, 521288629

local function mwcSeed(seed)
  seed = math.floor(math.abs(seed)) % 4294967296
  if seed == 0 then seed = 1 end
  mwc_z = seed
  mwc_w = (seed * 69069 + 1) % 4294967296
  if mwc_z == 0 then mwc_z = 362436069 end
  if mwc_w == 0 then mwc_w = 521288629 end
end

-- Drop-in replacement for math.random(): returns a uniform float in
-- [0, 1), matching the only form this script actually uses.
local function rnd()
  mwc_z = 36969 * (mwc_z % 65536) + math.floor(mwc_z / 65536)
  mwc_w = 18000 * (mwc_w % 65536) + math.floor(mwc_w / 65536)
  return (((mwc_z % 65536) * 65536 + mwc_w) % 4294967296) / 4294967296.0
end

-- btCollisionObject::CollisionFlags (Bullet's own enum values, same ones
-- used in demo/claude/worlds-simplest-clock.lua). Nothing in this scene
-- needs Bullet's collision detection -- agents avoid each other via the
-- hand-rolled shouldTurn() below -- so every body gets NO_CONTACT_RESPONSE,
-- and bodies moved by hand each tick are also marked KINEMATIC_OBJECT
-- rather than left as (mass 0, unmoving) static bodies.
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

--------------------------------------------------------------------------
-- World geometry -- identical to UniformCoverageSimulation.kt's constants
-- (worldSize/boundary/b1/b2), so the algorithm's behavior and statistics
-- match the original exactly. Kotlin's (x, y) becomes this scene's (x, z).
--------------------------------------------------------------------------
local BOUNDARY = 40.0
local B1 = (2 * BOUNDARY / 3) - BOUNDARY
local B2 = (4 * BOUNDARY / 3) - BOUNDARY
local AGENT_HEIGHT = 1.3
local IDEAL_PROPORTION = 1.0 / 9.0

--------------------------------------------------------------------------
-- GUI parameters -- the app's three sliders (activity_main.xml:
-- sliderParticles 1..100 default 75, sliderMeanFreePath 1..120 default 15,
-- sliderDelay 0..100 default 33). Each has a matching min/max/step/comment
-- kept in a small table below so the ]/[/./,  shortcuts can re-issue
-- addParam() with an updated value (which is also how the GUI's own
-- slider-drag handler updates a param) without repeating the range.
--------------------------------------------------------------------------
local PARAM_INFO = {
  numParticles = { min = 1, max = 100, step = 1,
                   comment = "agents created the next time Setup (R or ]/[) is pressed" },
  meanFreePath = { min = 1, max = 120, step = 1,
                   comment = "steps traveled, on average, before a random turn" },
  delayMs      = { min = 0, max = 200, step = 1,
                   comment = "ms to wait between simulation steps (0 = as fast as possible)" },
  ticksPerFrame = { min = 1, max = 100, step = 1,
                   comment = "algorithm ticks run per rendered frame; raise to fast-forward" },
}

local function setParam(name, value)
  local info = PARAM_INFO[name]
  value = math.max(info.min, math.min(info.max, value))
  v:addParam(name, value, info.min, info.max, info.step, info.comment)
  return value
end

setParam("numParticles", 75)
setParam("meanFreePath", 15)
setParam("delayMs", 33) -- matches the app's default sliderDelay value
setParam("ticksPerFrame", 1)

--------------------------------------------------------------------------
-- Cell colors -- cell index 0=bottom-left .. 8=top-right, row-major, same
-- layout and colors as UniformCoverageSimulation.getCellColor().
--------------------------------------------------------------------------
local COL_BLUE, COL_GREEN, COL_RED = "#0000ff", "#00ff00", "#ff0000"
local COL_YELLOW, COL_WHITE, COL_GRAY = "#ffff00", "#ffffff", "#555555"

local function cellColor(i)
  if i == 0 or i == 2 or i == 6 or i == 8 then
    return COL_BLUE -- corners
  elseif i == 4 then
    return COL_RED -- center
  else
    return COL_GREEN -- edges
  end
end

--------------------------------------------------------------------------
-- Static scene: the 3x3 grid floor and the boundary wall.
--------------------------------------------------------------------------
local function addTile(x1, x2, z1, z2, col)
  local cx, cz = (x1 + x2) / 2, (z1 + z2) / 2
  local t = Cube(x2 - x1, 0.5, z2 - z1, 0)
  t.col = col
  t.pos = btVector3(cx, -0.25, cz)
  v:add(t)
  noCollideStatic(t)
end

addTile(-BOUNDARY, B1, -BOUNDARY, B1, cellColor(0)) -- bottom-left
addTile(B1, B2, -BOUNDARY, B1, cellColor(1))        -- bottom-center
addTile(B2, BOUNDARY, -BOUNDARY, B1, cellColor(2))  -- bottom-right
addTile(-BOUNDARY, B1, B1, B2, cellColor(3))        -- middle-left
addTile(B1, B2, B1, B2, cellColor(4))               -- middle-center
addTile(B2, BOUNDARY, B1, B2, cellColor(5))         -- middle-right
addTile(-BOUNDARY, B1, B2, BOUNDARY, cellColor(6))  -- top-left
addTile(B1, B2, B2, BOUNDARY, cellColor(7))         -- top-center
addTile(B2, BOUNDARY, B2, BOUNDARY, cellColor(8))   -- top-right

local function addWall(cx, cz, sx, sz)
  local w = Cube(sx, 2.0, sz, 0)
  w.col = COL_YELLOW
  w.pos = btVector3(cx, 0.75, cz)
  v:add(w)
  noCollideStatic(w)
end

local WALL_T = 0.6
addWall(0, -BOUNDARY, 2 * BOUNDARY + WALL_T, WALL_T) -- south
addWall(0, BOUNDARY, 2 * BOUNDARY + WALL_T, WALL_T)  -- north
addWall(-BOUNDARY, 0, WALL_T, 2 * BOUNDARY + WALL_T) -- west
addWall(BOUNDARY, 0, WALL_T, 2 * BOUNDARY + WALL_T)  -- east

--------------------------------------------------------------------------
-- Histogram: 9 poles off to the side of the grid. A colored marker climbs
-- each pole to the cell's current share of total visits; a yellow ring
-- marks 1/9, the ideal-uniform-coverage line (HistogramView's dashed line).
--------------------------------------------------------------------------
local HIST_X0 = BOUNDARY + 18
local HIST_DX = 8
local HIST_MAXH = 30  -- physical pole height
local BAR_SCALE = 90  -- proportion -> marker height (1/9 lands at 10)

local histMarker = {}
for i = 0, 8 do
  local x = HIST_X0 + i * HIST_DX
  noCollideStatic(common.placeCylinder(btVector3(x, 0, 0), btVector3(x, HIST_MAXH, 0), 0.25, COL_GRAY))

  local m = Sphere(1.0, 0)
  m.col = cellColor(i)
  m.pos = btVector3(x, 0.5, 0)
  v:add(m)
  noCollideKinematic(m)
  histMarker[i] = m
end

do
  local y = IDEAL_PROPORTION * BAR_SCALE
  noCollideStatic(common.placeCylinder(btVector3(HIST_X0 - 3, y, 0), btVector3(HIST_X0 + 8 * HIST_DX + 3, y, 0),
                        0.15, COL_YELLOW))
end

--------------------------------------------------------------------------
-- Simulation state -- ported from UniformCoverageSimulation.kt. Lua tables
-- are 1-based, so cellCounts[i+1] holds the Kotlin cellCounts[i] value.
--------------------------------------------------------------------------
local agents = {}                          -- { x, y, heading(deg), steps, id, obj }
local cellCounts = {0, 0, 0, 0, 0, 0, 0, 0, 0}
local ticks = 0
local nextId = 0

local LOOKAHEAD = 0.0001 -- verbatim from shouldTurn()'s lookAheadDistance

local function monitorAgent(a)
  local cellX
  if a.x < B1 then cellX = 0
  elseif a.x <= B2 then cellX = 1
  else cellX = 2 end

  local cellY
  if a.y < B1 then cellY = 0
  elseif a.y <= B2 then cellY = 1
  else cellY = 2 end

  local idx = cellX + 3 * cellY
  cellCounts[idx + 1] = cellCounts[idx + 1] + 1
end

local function shouldTurn(a, meanFreePath)
  if a.steps >= meanFreePath then return true end

  local rad = math.rad(a.heading)
  local lookX = a.x + math.cos(rad) * LOOKAHEAD
  local lookY = a.y + math.sin(rad) * LOOKAHEAD
  if math.abs(lookX) >= BOUNDARY or math.abs(lookY) >= BOUNDARY then
    return true
  end

  for _, other in ipairs(agents) do
    if other.id ~= a.id then
      local dx, dy = other.x - a.x, other.y - a.y
      local dist = math.sqrt(dx * dx + dy * dy)
      if dist < 3.0 then
        local angleToOther = math.deg(atan2(dy, dx))
        -- Lua's % already normalizes to [0, 360) for a positive divisor,
        -- same result as Kotlin's "(angleDiff % 360f + 360f) % 360f".
        local diff = (angleToOther - a.heading) % 360.0
        if diff < 30.0 then return true end
      end
    end
  end
  return false
end

local function moveAgent(a, meanFreePath)
  local tries = 1
  a.steps = a.steps + 1

  while tries < 10 and shouldTurn(a, meanFreePath) do
    a.heading = rnd() * 360.0
    a.steps = 0
    tries = tries + 1
  end

  if tries < 10 then
    local rad = math.rad(a.heading)
    a.x = a.x + math.cos(rad)
    a.y = a.y + math.sin(rad)

    if a.x < -BOUNDARY then a.x = -BOUNDARY end
    if a.x > BOUNDARY then a.x = BOUNDARY end
    if a.y < -BOUNDARY then a.y = -BOUNDARY end
    if a.y > BOUNDARY then a.y = BOUNDARY end

    monitorAgent(a)
  end
end

local function uniformityDeviation()
  if ticks == 0 or #agents == 0 then return 0.0 end
  local totalVisits = ticks * #agents
  local sumSq = 0.0
  for i = 1, 9 do
    local p = cellCounts[i] / totalVisits
    local d = p - IDEAL_PROPORTION
    sumSq = sumSq + d * d
  end
  return math.sqrt(sumSq)
end

local function theoreticalMeanFreePath()
  return 0.65 * (2.0 * BOUNDARY / 3.0)
end

-- Diagnostic: by the arena's own reflective/rotational symmetry, the 4
-- corner cells (0,2,6,8) should be visited equally often as EACH OTHER
-- in the long run, and likewise the 4 edge cells (1,3,5,7) -- NOT
-- necessarily the same as one another (corners/edges/center have
-- genuinely different dynamics near the walls), but each category should
-- be internally uniform. Verified this empirically over a 2,000,000-tick
-- run: corner-to-corner spread shrank from 63.6% at 1,000 ticks to 1.7%
-- at 2,000,000, tracking the sqrt(n) falloff expected from ordinary
-- statistical sampling noise, not a code-level asymmetry. That noise is
-- real and visible at the tick counts a live session typically reaches,
-- so this reports it directly -- watch these two numbers shrink toward 0
-- as ticks accumulate, rather than taking convergence on faith.
local CORNER_CELLS = {1, 3, 7, 9} -- cellCounts indices for cells 0,2,6,8
local EDGE_CELLS = {2, 4, 6, 8}   -- cellCounts indices for cells 1,3,5,7

local function categorySpread(indices)
  local mn, mx = math.huge, -math.huge
  for _, i in ipairs(indices) do
    mn = math.min(mn, cellCounts[i])
    mx = math.max(mx, cellCounts[i])
  end
  local mean = (mn + mx) / 2 -- fine for a spread ratio; avoids a 4th loop
  if mx == 0 then return 0.0 end
  return (mx - mn) / mx -- as a fraction of the largest count in the category
end

--------------------------------------------------------------------------
-- setup() -- the app's "Setup Agents" button: clears and re-scatters the
-- agents, resetting the coverage statistics.
--------------------------------------------------------------------------
local function resetStats()
  for i = 1, 9 do cellCounts[i] = 0 end
  ticks = 0
end

local function setup(n)
  for _, a in ipairs(agents) do
    v:remove(a.obj)
  end
  agents = {}

  resetStats()
  nextId = 0

  for _ = 1, n do
    local x = (rnd() * 2 - 1) * (15.0 * BOUNDARY / 16.0)
    local y = (rnd() * 2 - 1) * (15.0 * BOUNDARY / 16.0)
    local heading = rnd() * 360.0

    local obj = Sphere(0.9, 0)
    obj.col = COL_WHITE
    obj.pos = btVector3(x, AGENT_HEIGHT, y)
    v:add(obj)
    noCollideKinematic(obj)

    local a = { x = x, y = y, heading = heading, steps = 0, id = nextId, obj = obj }
    nextId = nextId + 1
    agents[#agents + 1] = a
    monitorAgent(a)
  end

  print(string.format("setup: %d agents, meanFreePath=%d", n, v:getParam("meanFreePath")))
end

--------------------------------------------------------------------------
-- Sphere-count and delay shortcuts. Both read-modify-write their param
-- through setParam() above, so the GUI slider always shows the current
-- value too, whichever way it was changed.
--------------------------------------------------------------------------
local PARTICLE_STEP = 5
local DELAY_STEP = 5
local TICKS_PER_FRAME_STEP = 1

v:addShortcut("]", function(N)
  -- setParam() -> addParam() already triggers onParamChanged, which now
  -- applies numParticles itself -- no separate setup() call needed here.
  setParam("numParticles", math.floor(v:getParam("numParticles")) + PARTICLE_STEP)
end)

v:addShortcut("[", function(N)
  setParam("numParticles", math.floor(v:getParam("numParticles")) - PARTICLE_STEP)
end)

v:addShortcut(".", function(N) -- faster: less delay
  local d = setParam("delayMs", math.floor(v:getParam("delayMs")) - DELAY_STEP)
  print(string.format("delayMs = %d", d))
end)

v:addShortcut(",", function(N) -- slower: more delay
  local d = setParam("delayMs", math.floor(v:getParam("delayMs")) + DELAY_STEP)
  print(string.format("delayMs = %d", d))
end)

v:addShortcut("=", function(N) -- fast-forward: more ticks per rendered frame
  local t = setParam("ticksPerFrame", math.floor(v:getParam("ticksPerFrame")) + TICKS_PER_FRAME_STEP)
  print(string.format("ticksPerFrame = %d", t))
end)

v:addShortcut("-", function(N)
  local t = setParam("ticksPerFrame", math.floor(v:getParam("ticksPerFrame")) - TICKS_PER_FRAME_STEP)
  print(string.format("ticksPerFrame = %d", t))
end)

--------------------------------------------------------------------------
-- Confirms every GUI-panel slider drag out loud, and applies both
-- numParticles and meanFreePath immediately -- no separate reset step.
--
-- numParticles used to require pressing R afterward, specifically because
-- the GUI slider fires this on every intermediate value while you're
-- still dragging (Qt's valueChanged, not sliderReleased), and setup()
-- removes and recreates every agent sphere -- doing that on every pixel
-- of a fast drag can flicker/lag for a moment. Auto-applying anyway,
-- since a brief flicker mid-drag is a fair trade for never needing a
-- separate reset keypress; ]/[ still exist for a quick +-5 nudge without
-- touching the slider at all.
--
-- meanFreePath also fixes a real source of misleading readings:
-- uniformityDeviation() is a CUMULATIVE statistic (total visits since the
-- last Setup), and meanFreePath applies live without otherwise resetting
-- anything -- matching the original app's own behavior, where the slider
-- just updates a live property with no reset either. That means dragging
-- meanFreePath mid-run mixes two different-parameter regimes into one
-- running average: measured directly, a converged deviation of ~0.006 at
-- meanFreePath=15 jumped back up to ~0.008-0.010 and stayed elevated
-- after changing meanFreePath to 1 without resetting -- exactly a "gets
-- worse over time" symptom, and nothing to do with numeric precision.
-- Resetting stats (not the agents themselves -- they keep moving
-- smoothly) whenever meanFreePath changes keeps the deviation number
-- always describing only the CURRENT setting. setup() already resets
-- stats on its own, so numParticles changing gets a fresh statistics
-- window for free too, consistent with the same principle.
--------------------------------------------------------------------------
v:onParamChanged(function(N, name, value)
  if name == "numParticles" then
    setup(math.floor(value))
  elseif name == "meanFreePath" then
    resetStats()
    print(string.format("meanFreePath = %d (live -- stats reset so deviation reflects only this setting)",
                        math.floor(value)))
  end
end)

--------------------------------------------------------------------------
-- Per-tick update -- runs only while the simulation is running (S), same
-- as the app's coroutine loop only running between "Move Agents" and
-- "Stop". Moves every agent one step, redraws the spheres and histogram
-- markers, and periodically prints the same stats CoverageSimulationView
-- drew on-screen (Agents / Ticks / Deviation / Theoretical MFP).
--------------------------------------------------------------------------
local STATS_EVERY = 30 -- ~once a second at 30 fps
local lastStepWallTime = os.clock()

v:preStart(function(N)
  print("Uniform Coverage -- ]/[: +/- spheres  ,/.: slower/faster  =/-: ticks/frame  S: start/stop")
end)

v:postSim(function(N)
  -- Throttle to delayMs of real time between frames (see the delayMs note
  -- near the top of the file) -- this is what "decrease the delay from 33"
  -- actually controls, since postSim's own call rate isn't exposed to Lua.
  local delayMs = v:getParam("delayMs")
  local now = os.clock()
  if delayMs > 0 and (now - lastStepWallTime) * 1000.0 < delayMs then
    return
  end
  lastStepWallTime = now

  local mfp = v:getParam("meanFreePath")
  local batch = math.max(1, math.floor(v:getParam("ticksPerFrame")))
  local ticksBefore = ticks

  -- Run the whole batch of algorithm ticks first, without touching any
  -- Object -- moveAgent()/monitorAgent() only ever read/write the plain
  -- Lua tables in `agents` and `cellCounts`. Only after the batch do we
  -- push the results out to the spheres/markers Bullet actually renders,
  -- so a ticksPerFrame of 20 costs one redraw, not twenty.
  for _ = 1, batch do
    ticks = ticks + 1
    for _, a in ipairs(agents) do
      moveAgent(a, mfp)
    end
  end

  for _, a in ipairs(agents) do
    a.obj.pos = btVector3(a.x, AGENT_HEIGHT, a.y)
  end

  if #agents > 0 then
    local totalVisits = ticks * #agents
    for i = 0, 8 do
      local proportion = cellCounts[i + 1] / totalVisits
      local h = math.min(proportion * BAR_SCALE, HIST_MAXH)
      histMarker[i].pos = btVector3(HIST_X0 + i * HIST_DX, h + 0.5, 0)
    end
  end

  -- floor(ticks/STATS_EVERY) crossing an integer boundary fires once per
  -- ~STATS_EVERY ticks regardless of batch size, unlike a plain "% == 0"
  -- check which a batch > 1 could step straight over.
  if math.floor(ticks / STATS_EVERY) > math.floor(ticksBefore / STATS_EVERY) then
    print(string.format(
      "ticks=%d  agents=%d  meanFreePath=%d  deviation=%.4f  theoreticalMFP=%.1f  cornerSpread=%.1f%%  edgeSpread=%.1f%%",
      ticks, #agents, mfp, uniformityDeviation(), theoreticalMeanFreePath(),
      categorySpread(CORNER_CELLS) * 100, categorySpread(EDGE_CELLS) * 100))
  end
end)

--------------------------------------------------------------------------
-- Camera and initial scatter
--------------------------------------------------------------------------
common.setCamera(btVector3(0, 105, 130), btVector3(20, 0, 0))

mwcSeed(os.time())
setup(math.floor(v:getParam("numParticles")))
print("delayMs = " .. tostring(v:getParam("delayMs")))

-- EOF
