-- Threads, shown: a scene built so that v:setThreads helps all it can (November 2026).
--
-- 32 chains hang from a frame, each 30 links joined by ball joints; each starts level and swings. Every chain is
-- an island of its own (nothing joins or touches another: the links are out of collision detection altogether,
-- and the frame's blocks are fixed), every chain costs the same to solve, the solver runs all its iterations
-- (no early stop), and there is no Lua to speak of each frame. So nearly all the work is solving the chains,
-- which is what threads share out: one chain to a thread at a time, side by side.
--
-- The Threads slider sets v:setThreads while it runs. The chains move exactly the same with any number of threads;
-- only the speed changes. The status bar shows what the physics costs a frame, what speed that allows, and how
-- many times faster it is than with no threads (once Threads has been 0 at the current Iterations); each line also
-- goes to the terminal bpp was started from, where it can be copied. The picture
-- can't run faster than real time; the physics figure can, so turn Iterations up to keep the picture slower
-- than real time and see the speed-up in the motion too.
--
-- Needs bpp built with Bullet with threads (scripts/bullet-threads.sh, then qmake CONFIG+=bundled_bullet); with
-- the system Bullet the status bar says so and Threads does nothing.

local CHAINS_X, CHAINS_Z = 8, 4      -- the chains, in rows (32: four to a thread at 8 threads)
local LINKS = LINKS or 30            -- links a chain
local LINK = 5                       -- a link's length, cm
local THICK = 2.5                    -- its thickness, cm
local GAP = 40                       -- between the chains' tops, cm
local TOP = 220                      -- the tops' height, cm
local ITER = ITER or 600             -- solver iterations a step
local FRAME, STEP = 1 / 60, 1 / 240  -- a frame, a physics step (4 a frame), s
local MAXT = 16                      -- the slider's top

v:setSolver("si")
v:setSolverIterations(ITER)
v:setSolverInfo("residual", 0)       -- (all the iterations, every chain: no early stop)
v.timeStep = FRAME
v.animationPeriod = math.floor(FRAME * 1000)
v.fixedTimeStep = STEP
v.maxSubSteps = math.ceil(FRAME / STEP)
v.gravity = btVector3(0, -981, 0)

-- does this bpp have threads? (setThreads returns how many it uses; 0 with the system Bullet, quietly for 1)
local HAS_THREADS = v:setThreads(1) > 0
v:setThreads(0)

-- the floor and the frame: to look at only (out of collision detection, like the links)
local floor = Cube(CHAINS_X * GAP + 80, 2, CHAINS_Z * GAP + 80, 0)
floor.pos = btVector3(0, -1, 0)
floor.col = "#d8d4cc"
floor.collides = false
v:add(floor)

local function hue(h)   -- a bright colour round the colour wheel, h from 0 to 1
  local function c(o) return math.floor(255 * (0.55 + 0.45 * math.cos(2 * math.pi * (h - o)))) end
  return string.format("#%02x%02x%02x", c(0), c(1 / 3), c(2 / 3))
end

for iz = 1, CHAINS_Z do            -- a bar along each row, for the chains to hang from (to look at)
  local bar = Cube(CHAINS_X * GAP, 3, 3, 0)
  bar.pos = btVector3(0, TOP + 3.5, (iz - (CHAINS_Z + 1) / 2) * GAP)
  bar.col = "#444444"
  bar.collides = false
  v:add(bar)
end

local n = 0
for ix = 1, CHAINS_X do
  for iz = 1, CHAINS_Z do
    n = n + 1
    local x0, z0 = (ix - (CHAINS_X + 1) / 2) * GAP, (iz - (CHAINS_Z + 1) / 2) * GAP
    local top = Cube(4, 4, 4, 0)    -- a fixed block for the chain to hang from
    top.pos = btVector3(x0, TOP, z0)
    top.col = "#555555"
    top.collides = false
    v:add(top)
    -- each chain starts level, pointing its own way round, so they swing every which way
    local a = 2 * math.pi * (n - 1) / (CHAINS_X * CHAINS_Z) * 5
    local q = btQuaternion(0, math.sin(a / 2), 0, math.cos(a / 2))   -- (a turn of a about the vertical)
    local dx, dz = math.cos(a), -math.sin(a)
    local prev, prevPivot = top, btVector3(0, 0, 0)
    for i = 1, LINKS do
      local link = Cube(LINK, THICK, THICK, 1)
      local d = (i - 0.5) * LINK
      link.trans = btTransform(q, btVector3(x0 + dx * d, TOP, z0 + dz * d))
      link.col = hue((n - 1) / (CHAINS_X * CHAINS_Z))
      link.collides = false
      v:add(link)
      v:addConstraint(btPoint2PointConstraint(prev.body, link.body, prevPivot, btVector3(-LINK / 2, 0, 0)))
      prev, prevPivot = link, btVector3(LINK / 2, 0, 0)
    end
  end
end

v.cam.pos = btVector3(0, 230, 470)
v.cam.look = btVector3(0, 135, 0)
v.cam.up = btVector3(0, 1, 0)

v:addParam("Threads", 0, 0, MAXT, 1, "threads solving the chains (0: as without threads)")
v:addParam("Iterations", ITER, 20, 2000, 10, "solver iterations a step: the work each chain costs")

-- the speed: the physics's wall time a frame, from just before the step to just after; and the picture's
local threads, iter = 0, ITER
local t0, spent, frames, shown, wall0 = 0, 0, 0, 0, v:getTime()
local base = nil                     -- the physics's time a frame with no threads, at this many iterations
local status = ""
local function update()
  local per = spent / frames                       -- s of wall time a frame, physics only
  local now = v:getTime()
  local seen = frames * FRAME / (now - wall0)      -- simulated s a wall s, as you see it
  if threads == 0 then base = per end
  local line
  if not HAS_THREADS and threads > 0 then
    line = "this bpp has no threads: build it with scripts/bullet-threads.sh and qmake CONFIG+=bundled_bullet"
  else
    line = string.format("threads %d | physics %.1f ms a frame: %.2fx real time | you see %.2fx", threads,
      per * 1000, FRAME / per, seen)
    if base and threads > 0 then line = line .. string.format(" | %.1fx as fast as no threads", base / per) end
    if not base then line = line .. " | set Threads to 0 for a while to measure it without" end
  end
  status = line
  v.statusText = line
  io.stdout:write("Testing_Threads: ", line, "\n")   -- (and in the terminal bpp was started from, to copy)
  io.stdout:flush()
  spent, frames, wall0 = 0, 0, now
end

v:preSim(function(N) t0 = v:getTime() end)
v:postSim(function(N)
  spent = spent + (v:getTime() - t0)
  frames = frames + 1
  if frames >= 60 then update() end                -- (about once a second when it keeps up)
end)

v:onParamChanged(function(N, name, value)
  if name == "Threads" then
    threads = math.floor(value + 0.5)
    v:setThreads(threads)
    spent, frames, wall0 = 0, 0, v:getTime()
  elseif name == "Iterations" then
    iter = math.floor(value + 0.5)
    v:setSolverIterations(iter)
    base = nil                                       -- (measure no threads again at this many)
    spent, frames, wall0 = 0, 0, v:getTime()
  end
end)

v:setHelpText([[
<h3>Threads</h3>
<p>32 chains of 30 links, each swinging on its own: built so that threads help all they can.
Each chain is solved on its own, so with more threads more chains are solved at once.</p>
<p><b>Threads</b>: 0 is bpp as without threads. Slide it up and watch the chains speed up, and the
status bar: what the physics costs a frame, and how many times faster than with no threads.
The chains move exactly the same with any number of threads.</p>
<p><b>Iterations</b>: the work each chain costs a step. The picture can't run faster than real
time, so if it reaches real time, turn this up.</p>
<p>Needs bpp built with Bullet with threads (scripts/bullet-threads.sh, qmake CONFIG+=bundled_bullet).</p>
]])
