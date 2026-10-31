--
-- ch07/Corridor-Ground.lua -- Ch. 7's corridor sweep (entries 7.5-7.6,
-- Figs. 7.11-7.13) on BPP's ground robots (ground/vehicle.lua, the
-- Pioneer 3-AT): Kerr's 2005 controllers (ch07/kerr2005.lua: KT, Ant,
-- Default) drive real wheels through Bullet (HANDOFF.md §7, step 3b)
--
-- THE GEOMETRY is Kerr's (ch07/kerr2005.lua) scaled to the Pioneer: his
-- 6" robot is 0.5 m, so every length is x 3.28 and one of his inches is
-- S = 0.5 / 6 m (1/12 m). His corridor 1000" x 5000" is 83.3 x 416.7 m,
-- his sonar range 60" is 5 m, his move 6" a step is 0.5 m, his cells 20"
-- are 1.67 m, his collision zone 15" is 1.25 m. His x (across) is the
-- world's x and his y (along, toward the goal) the world's z; his bearings
-- (degrees, from +x toward +y) are measured the same way in the x-z plane
-- (so the world is his mirror image, seen from above; nothing physical
-- depends on the handedness).
-- The walls (1 m thick) and his course's rectangles
-- (ch07/kerr2005/data/course_P_k.txt) are static boxes 1 m tall.
--
-- ONE KT STEP A SECOND (a robot length at the Pioneer's 0.5 m/s; a vehicle
-- follows KT only if its lag is shorter than a KT tick, F91). Every step:
--   1. each robot's ACTUAL position (its rotation centre) is sensed, in
--      his inches;
--   2. his step runs unchanged but for the move (kerr2005.lua's
--      R.step(w, true): his move order, his controller, his messages):
--      each robot senses and decides a heading and a distance (his safe
--      distance: 6" if the sonar that way reads more than 6" ...);
--   3. each robot is told to drive that distance along that heading in
--      the step: KT by a velocity command (velocity(), G4; distance / 1 s
--      along the heading until the next step), Ant and Default by a
--      waypoint (command(): be there in 1 s). The wheels, the 0.1 m/s
--      minimum wheel speed and the 0.4 rad/s turn cap do the rest; a
--      robot that has to turn first gets less far.
-- The controllers keep their own bearings (the heading they last chose),
-- as KT keeps its own velocities on vehicles (F88): a robot still turning
-- is not told to go where it happens to point.
--
-- SENSING, done locally:
--   sonar   24 rays every 15 degrees from the robot's chosen heading, cast
--           through Bullet (v:rayTest) from its centre at its centre's
--           height, 5.25 m (63") long, against the walls, the obstacles
--           and the other robots (its own body left out). Reading = the
--           hit's distance from the centre less the robot's radius 3"
--           (0.25 m), in inches, 0 to 60; 60 when nothing is hit. (His
--           code takes 3" off an obstacle, 6" off a robot, nothing off a
--           wall.)
--   robots  his localisation (RodSensor): every robot within 60" (5 m),
--           centre to centre, its distance less 3" and bearing in the
--           robot's frame; their speed and heading by his messages
--           (kerr2005.lua, unchanged).
--   goal    the bearing to +z (90 degrees less the heading); done after 10
--           steps within 120" (10 m) of the goal end, then it stops (and
--           stays, an obstacle to the others), as his.
-- Coverage: his 50 x 250 grid (cells 1.67 m), a cell covered when a
-- robot's centre is in it, checked every frame (his: after each move);
-- shadow cells as his (the row just past each obstacle's far edge).
-- Random numbers: his (java.util.Random from his drivers' seed 100 + 10
-- course + run: start bearings, move order, the controllers' draws), so a
-- run is set by (controller, N, pct, course, run). Starts as his: a grid
-- 40" (3.33 m) apart from (10", 10").
--
-- BUMPS: contacts are counted, not losses (ground robots carry on).
-- Bullet's contact points, once a frame: a robot touching another robot,
-- or a wall or obstacle, that was not touching it the frame before is one
-- bump.
-- JAMS (backOff, off by default; on in the sweep, FINDINGS F102): his
-- robots are points that move along a sonar ray, a Pioneer is a 0.5 m box
-- that turns as it goes, so a corner can catch an obstacle the ray
-- misses, and a KT robot (whose velocity changes only in collisions)
-- then pushes there for ever. With backOff a jammed robot backs off
-- (ground/vehicle.lua's backOff: wheels driven, robot still for 2 s), and
-- a KT robot that backed off has a wall collision at its next step (his
-- wall rule, kerr2005.lua's robots[i].bumped): the bump is a collision.
--
-- DEFINITIONS (sliders, status line, the result line):
--   controller  KT | Ant | Default (KTRobot, AntRobot, Simple2)
--   robots      N; pct  obstacles (0, or 10-40: his course files);
--   course      k = 0-9; run  r = 0-9 (seed 100 + 10 k + r);
--   fix         kerr2005.lua's switches (seeds, messages, wallfit), a
--               comma list; empty = his code (all applied at Setup, R)
--   backOff     JAMS above (Setup, R)
--   step        KT steps taken (= simulated seconds)
--   total       % of the cells not inside obstacles covered (Fig. 7.12)
--   shadow      % of the shadow cells covered (Fig. 7.13; 0 if none)
--   done        robots done (stopped near the goal end)
--   bumps       robot-robot + robot-wall/obstacle contacts so far
--   moved       the robots' actual path / the path they were told, over
--               the run (1 = every step's distance driven in the step;
--               less when they turn first; a back-off counts as driven)
--   result line, at the end (every robot done, or 150,000 steps), his
--   log line (kerr2005.lua's R.line; ch07/kerr2005_figs.lua reads it) and:
--     Bumps b RobotBumps rr WallBumps rw Moved m BackOff 0|1 BackOffs n Wall s
--   (n = back-offs, all robots; s = wall seconds)
--   and every 1,000 steps, on stderr (BPP holds its printed lines until
--   it ends), "STEP t total % shadow % done n bumps b", with the robots not
--   done (id@(x,z) m) once there are 5 or fewer
--
-- Run (headless), from the ArtificialPhysics folder:
--   KERR_CTL=KT KERR_N=25 KERR_PCT=20 KERR_COURSE=0 KERR_RUN=0 KERR_BACKOFF=1 \
--     KERR_EXIT=1 bpp -f ch07/Corridor-Ground.lua -n 5000000
--   (KERR_FIX=seeds,messages,wallfit for the book's version; KERR_LIMIT
--   steps instead of 150,000; KERR_EXIT=1 ends BPP when the run ends)
-- ch07/corridor_ground_sweep.sh runs the sweep; ch07/README.md has the
-- results.
--

-- the ArtificialPhysics folder: here (headless runs) or one up (the GUI
-- runs a script from its own folder)
local function exists(f) local h = io.open(f); if h then h:close() end; return h ~= nil end
local HOME = exists("ch07/kerr2005.lua") and "." or ".."
package.path = HOME .. "/?.lua;" .. package.path
local common = require "common"
local status = require "lib.status"
local K      = require "ch07.kerr2005"
local Veh    = require "ground.vehicle"

local function env(name, default)
  local s = os.getenv(name)
  if s == nil or s == "" then return default end
  return tonumber(s) or s
end
local LIMIT = env("KERR_LIMIT", 150000)
local EXIT = env("KERR_EXIT", 0) == 1

v:addParam("controller", env("KERR_CTL", "KT"), "KT, Ant or Default (Setup, R)")
v:addParam("robots", env("KERR_N", 25), 1, 100, 1, "robots N (Setup, R)")
v:addParam("pct", env("KERR_PCT", 20), 0, 40, 10, "obstacles, % (0, or 10-40: Kerr's courses; Setup, R)")
v:addParam("course", env("KERR_COURSE", 0), 0, 9, 1, "Kerr's course k (Setup, R)")
v:addParam("run", env("KERR_RUN", 0), 0, 9, 1, "run r: seed 100 + 10 k + r, as his drivers (Setup, R)")
v:addParam("fix", env("KERR_FIX", ""), "kerr2005.lua's switches: seeds,messages,wallfit (empty = his code; Setup, R)")
v:addParam("backOff", env("KERR_BACKOFF", 0) == 1, "a jammed robot backs off (ground/vehicle.lua's backOff; Setup, R)")

local S = 0.5 / 6                 -- m per inch of Kerr's world
local STEP = 1.0                  -- s per KT step
local HW = 1.0                    -- wall and obstacle height, m
local REACH = 63 * S              -- the sonar ray, m (60" + the 3" rim)
local D2R = math.pi / 180
local DT, SUB = 1 / 250, 8
common.setTiming(DT, 1, DT)
common.gravity(-9.81)
local ground = Plane(0, 1, 0, 0, 500)
ground.col = "#6a7a6a"
v:add(ground)
local Y0 = Veh.planeY()

local names = { KT = "KTRobot", Ant = "AntRobot", Default = "Simple2",
                KTRobot = "KTRobot", AntRobot = "AntRobot", Simple2 = "Simple2" }
local w, o, agents, statics, objToRobot, staticObj = nil, nil, {}, {}, {}, {}
local t, nextTick, finished, wall0 = 0, 0, false, 0
local bumps, rbumps, touching = 0, 0, {}
local told, moved, lastX, lastZ = 0, 0, {}, {}

local function box(x1, z1, x2, z2, col)       -- a static box, metres
  local b = Cube(x2 - x1, HW, z2 - z1, 0)
  b.pos = btVector3((x1 + x2) / 2, HW / 2, (z1 + z2) / 2)
  b.col = col
  v:add(b)
  statics[#statics + 1] = b
  staticObj[b] = true
end

-- the sonar, through Bullet (kerr2005.lua's ray() calls it: w.sonar)
local function sonar(w, id, angle)
  local d = agents[id + 1]
  local a = (w.b[id] + angle) * D2R
  local c, s = math.cos(a), math.sin(a)
  local f = v:rayTest(btVector3(d.px, Y0, d.pz), btVector3(d.px + REACH * c, Y0, d.pz + REACH * s), d.obj)
  if f >= 1 then return 60 end
  local r = f * REACH / S - 3
  if r < 0 then return 0 elseif r > 60 then return 60 end
  return r
end

local function setup()
  for _, d in ipairs(agents) do Veh.remove(d) end
  for _, b in ipairs(statics) do v:remove(b) end
  agents, statics, objToRobot, staticObj = {}, {}, {}, {}
  local ctl = names[v:getParam("controller")] or error("controller: KT, Ant or Default")
  local k, r, pct = math.floor(v:getParam("course")), math.floor(v:getParam("run")), math.floor(v:getParam("pct"))
  local fix, fixNames = {}, {}
  for f in tostring(v:getParam("fix")):gmatch("[^,%s]+") do fix[f] = true; fixNames[#fixNames + 1] = f end
  o = { controller = ctl, n = math.floor(v:getParam("robots")), pct = pct, k = k, run = r,
        seed = 100 + 10 * k + r, fix = fix, fixNames = fixNames,
        course = K.coursePath(HOME .. "/ch07/kerr2005/data", pct, k) }
  Veh.backOff = v:getParam("backOff")
  w = K.new(o)
  w.sonar = sonar
  local Wm, Hm = w.width * S, w.height * S
  box(-1, -1, 0, Hm + 1, "#909090"); box(Wm, -1, Wm + 1, Hm + 1, "#909090")
  box(0, -1, Wm, 0, "#909090"); box(0, Hm, Wm, Hm + 1, "#d0c040")    -- the goal end yellow
  for _, ob in ipairs(w.obs) do box(ob[1] * S, ob[2] * S, ob[3] * S, ob[4] * S, "#8a6a50") end
  for i = 0, w.n - 1 do
    local d = Veh.new(w.x[i] * S, w.y[i] * S, Y0)
    d.body:setCenterOfMassTransform(btTransform(btQuaternion(btVector3(0, 1, 0), -w.b[i] * D2R),
                                                btVector3(w.x[i] * S, Y0, w.y[i] * S)))
    Veh.join(d, 0)
    agents[i + 1] = d
    objToRobot[d.obj] = i + 1
    lastX[i + 1], lastZ[i + 1] = d.px, d.pz
  end
  t, nextTick, finished, wall0 = 0, 0, false, os.time()
  bumps, rbumps, touching, told, moved = 0, 0, {}, 0, 0
  print(string.format("Ch. 7 corridor on ground robots: %s, N %d, %d%% obstacles, course %d, run %d, seed %d%s%s",
    ctl, o.n, pct, k, r, o.seed, #fixNames > 0 and (", fix " .. table.concat(fixNames, ",")) or "",
    Veh.backOff and ", backOff" or ""))
end

local function countDone()
  local n = 0
  for i = 0, w.n - 1 do if w.robots[i].done then n = n + 1 end end
  return n
end

local function backOffs()
  local n = 0
  for _, d in ipairs(agents) do n = n + (d.backs or 0) end
  return n
end

local function result()
  local res = K.result(w)
  print(K.line(res, o) .. (#o.fixNames > 0 and (" Fix " .. table.concat(o.fixNames, ",")) or "")
    .. string.format(" Bumps %d RobotBumps %d WallBumps %d Moved %.4f BackOff %d BackOffs %d Wall %d",
       bumps, rbumps, bumps - rbumps, told > 0 and moved / told or 0, Veh.backOff and 1 or 0, backOffs(), os.time() - wall0))
end

-- one KT step: sense, decide (his step without the move), tell the robots
local function ktTick()
  for i = 0, w.n - 1 do
    local d = agents[i + 1]
    w.x[i], w.y[i] = d.px / S, d.pz / S
    if (d.backs or 0) > (d.backsSeen or 0) then   -- it jammed and backed off: a bump
      w.robots[i].bumped, d.backsSeen = true, d.backs
    end
  end
  K.step(w, true)
  local kt = o.controller == "KTRobot"
  for i = 0, w.n - 1 do
    local d, r = agents[i + 1], w.robots[i]
    local b, dist = w.b[i] * D2R, r.distance * S
    local cx, cz = math.cos(b), math.sin(b)
    if kt then Veh.velocity(d, dist / STEP * cx, 0, dist / STEP * cz, t)
    else Veh.command(d, d.px + dist * cx, Y0, d.pz + dist * cz, STEP, t) end
    told = told + dist
  end
  if w.time % 1000 == 0 then
    local res = K.result(w)
    local left = {}                 -- the robots not done, when few: id@(x,z) m
    if w.n - countDone() <= 5 then
      for i = 0, w.n - 1 do
        if not w.robots[i].done then left[#left + 1] = string.format(" %d@(%.1f,%.1f)", i, w.x[i] * S, w.y[i] * S) end
      end
    end
    io.stderr:write(string.format("STEP %d total %.2f shadow %.2f done %d bumps %d%s\n",
      w.time, res.total, res.behind, countDone(), bumps, table.concat(left)))
  end
end

-- bumps: new robot-robot and robot-static contacts (once a frame)
local function checkContacts()
  local now = {}
  v:eachContact(function(a, b, x, y, z, nx, ny, nz, dist)
    if dist > 0.005 then return end
    local ra, rb = objToRobot[a], objToRobot[b]
    if not ra and not rb then return end
    local key
    if ra and rb then key = math.min(ra, rb) * 1000 + math.max(ra, rb)
    elseif staticObj[a] or staticObj[b] then key = tostring(ra or rb) .. ":" .. tostring(ra and b or a)
    else return end
    if not now[key] then
      now[key] = true
      if not touching[key] then
        bumps = bumps + 1
        if ra and rb then rbumps = rbumps + 1 end
      end
    end
  end)
  touching = now
end

local function physicsStep()
  if t >= nextTick - 1e-9 then ktTick(); nextTick = nextTick + STEP end
  for _, d in ipairs(agents) do Veh.guide(d, "ap", t, DT) end
  for _, d in ipairs(agents) do Veh.step(d, DT) end
  t = t + DT
end

local function showStatus()
  if not w then return end
  local res = K.result(w)
  status.show({ "Ch. 7 " .. o.controller .. " on robots",
    status.int("step", w.time, 7),
    status.num("total", res.total, 1, false, 5, "%"),
    status.num("shadow", res.behind, 1, false, 5, "%"),
    status.int("done", countDone(), 3),
    status.int("bumps", bumps, 6),
    status.num("moved", told > 0 and moved / told or 0, 3, false, 5) })
end

setup()
common.setCamera(btVector3(w.width * S / 2, 60, -25), btVector3(w.width * S / 2, 0, 30))
v:addShortcut("R", function(N) setup() end)

v:preSim(function(N)
  if finished then return end
  for _ = 1, SUB - 1 do physicsStep(); v:stepSimulation(DT, 1, DT) end
  physicsStep()
end)
v:postSim(function(N)
  if finished then return end
  for i, d in ipairs(agents) do
    Veh.sync(d)
    K.cover(w, d.px / S, d.pz / S)
    local dx, dz = d.px - lastX[i], d.pz - lastZ[i]
    moved = moved + math.sqrt(dx * dx + dz * dz)
    lastX[i], lastZ[i] = d.px, d.pz
  end
  checkContacts()
  if N % 15 == 0 then showStatus() end
  if not K.going(w) or w.time >= LIMIT then
    finished = true
    showStatus()
    result()
    if EXIT then os.exit(0) end
  end
end)
v:preStop(function()
  if not finished and w then print("(stopped at step " .. w.time .. ")"); result() end
end)
