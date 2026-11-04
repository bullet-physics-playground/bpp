--
-- ch13/Ring-Ground.lua -- Ch. 13's dumbbell agent on the Pioneer 3-AT
-- (ground/vehicle.lua): the camera ring and the three-point turn
-- (§13.4.1.2, PDF 464; book/ch13.md E10, E11b; HANDOFF.md §7, Ch. 13
-- step 2)
--
-- THE AGENT is ch13/dumbbell.lua (Eqs. 13.19-13.23, the forces and
-- torques of the ring, our choices stated there). Ten times a second (the
-- book's outer loop) each robot senses its own pose (its rotation centre
-- and heading, exactly) and the others' cameras, runs the dumbbell and
-- sends (u, Omega) to its wheels (ground/vehicle.lua drive(): Eqs.
-- 13.4-13.6, wheels 0 or 0.1-0.5 m/s). Bullet moves the robots (250 Hz),
-- with their contacts. The plane's (x, y) is the world's (x, -z), so a
-- left turn is + in both.
--
-- CASES (slider case, or RING_CASE):
--   0  the camera ring: n robots (3-5) round the attractor (the white
--      marker at the origin), the cameras (front particles, the red bars)
--      on a circle of R = 2 m, pointing in. start 0: each at a random
--      bearing 5-8 m out, random heading; start 1: a line 1 m apart, 10 m
--      out on +x, random headings (one group, as unloaded together)
--   1  the three-point turn: one robot at the origin heading +x, the
--      attractor 5 m directly behind it (+ the angle `behind` to its left)
--
-- SPREAD (slider spread, s; 0 = off, the default): for the first `spread`
--   seconds the pointing spring is weak (dumbbell.lua's kappaSpread,
--   0.01, a thirteenth of kappa), so the robots can turn along the ring and
--   spread; then it is kappa. Measured (ch13/README.md): with one kappa a
--   robot on the ring cannot move along it (its axle lies along the ring:
--   a neighbour's push has nothing to drive), so the robots stay at the
--   bearings they arrived at; a weak spring spreads them but leaves the
--   cameras 40 deg off; spreading first, then pointing, does both.
--
-- DEFINITIONS (status line and result line; metres, seconds, degrees):
--   t        simulated time, s
--   radius   largest |camera distance from the attractor - R|, m
--   point    largest angle between a robot's heading and the bearing from
--            its camera to the attractor, deg (0 = pointing at it)
--   gap      largest angular gap between neighbours on the ring, over the
--            even gap 360 / n (1 = even; case 0 only)
--   near     least distance between two robots' centres, m (case 0)
--   moving   robots with a wheel commanded (not 0) now
--   passes   changes of sign of u, all robots (back and forth; the book:
--            "two or three passes" with static friction, PDF 465)
--   bumps    new robot-robot contacts
--   formed   case 0: the time from which radius < 0.1 m, point < 5 deg
--            and gap < 1.25 held to the end of the run (-1 if not at the
--            end); case 1: radius < 0.1 m and point < 5 deg
--   case 1 adds the segments of travel (F@t forwards from t s, B@t
--   backwards; a three-point turn is B then F) and the camera's largest
--   distance from the straight line from its start to the attractor
--   result line, at the end (limit seconds, default 300):
--     Ring case c n N seed s start S spread T Formed f Radius r Point p
--     Gap g Near d Moving m Passes k Bumps b [Segments ... Dev x] Wall w
--
-- Run (headless), from the ArtificialPhysics folder:
--   RING_N=4 RING_SEED=1 RING_SPREAD=60 RING_EXIT=1 bpp -f ch13/Ring-Ground.lua -n 100000
--   (RING_CASE, RING_START, RING_BEHIND, RING_LIMIT seconds; RING_EXIT=1
--   ends BPP when the run ends; RING_SET="g=0.05 G=2" overrides
--   dumbbell.lua's parameters, for sweeps)
--

local function exists(f) local h = io.open(f); if h then h:close() end; return h ~= nil end
local HOME = exists("ch13/dumbbell.lua") and "." or ".."
package.path = HOME .. "/?.lua;" .. package.path
local common = require "common"
local status = require "lib.status"
local rng    = require "lib.rng"
local DB     = require "ch13.dumbbell"
local Veh    = require "ground.vehicle"

local function env(name, default)
  local s = os.getenv(name)
  if s == nil or s == "" then return default end
  return tonumber(s) or s
end
local LIMIT = env("RING_LIMIT", 300)
local EXIT = env("RING_EXIT", 0) == 1

v:addParam("case", env("RING_CASE", 0), 0, 1, 1, "0 = camera ring, 1 = three-point turn (Setup, R)")
v:addParam("robots", env("RING_N", 4), 1, 8, 1, "robots n, case 0 (Setup, R)")
v:addParam("seed", env("RING_SEED", 1), 1, 1000, 1, "starts (Setup, R)")
v:addParam("start", env("RING_START", 0), 0, 1, 1, "case 0: 0 = random bearings 5-8 m out, 1 = a line 10 m out (Setup, R)")
v:addParam("spread", env("RING_SPREAD", 0), 0, 300, 10, "seconds with a weak pointing spring first (0 = off; Setup, R)")
v:addParam("behind", env("RING_BEHIND", 0), -90, 90, 5, "case 1: the attractor's angle off dead astern, deg, + left (Setup, R)")

local DT, SUB, TICK = 1 / 250, 8, 1 / DB.P.hz
common.setTiming(DT, 1, DT)
common.gravity(-9.81)
local ground = Plane(0, 1, 0, 0, 100)
ground.col = "#6a7a6a"
v:add(ground)
local Y0 = Veh.planeY()
local marker = Cube(0.15, 0.6, 0.15, 0)
marker.col = "#ffffff"
marker.collides = false
v:add(marker)

local P = {}
for k, val in pairs(DB.P) do P[k] = val end
for k, val in tostring(env("RING_SET", "")):gmatch("(%w+)=([%d%.%-e]+)") do P[k] = tonumber(val) end
local o, robots, agents, objToRobot = nil, {}, {}, {}
local t, nextTick, finished, wall0, lastBad = 0, 0, false, 0, 0
local bumps, touching, passes, segs, lastSeg, dev = 0, {}, 0, {}, 0, 0
local cx, cy, sx, sy, L = 0, 0, 0, 0, 1

local atan2 = math.atan2 or function(y, x) return math.atan(y, x) end
local function pose(d) return d.px, -d.pz, atan2(-d.hz, d.hx) end

local function setup()
  for _, d in ipairs(robots) do Veh.remove(d) end
  robots, agents, objToRobot = {}, {}, {}
  o = { case = math.floor(v:getParam("case")), n = math.floor(v:getParam("robots")),
        seed = math.floor(v:getParam("seed")), start = math.floor(v:getParam("start")),
        spread = v:getParam("spread"), behind = v:getParam("behind") }
  local s = rng.new(o.seed)
  local starts = {}
  if o.case == 1 then
    o.n = 1
    local b = math.rad(o.behind)
    cx, cy = -5 * math.cos(b), 5 * math.sin(b)
    starts[1] = { 0, 0, 0 }
  else
    cx, cy = 0, 0
    for i = 1, o.n do
      if o.start == 1 then starts[i] = { 10, (i - (o.n + 1) / 2) * 1.0, s:random() * 2 * math.pi }
      else
        local a, r = s:random() * 2 * math.pi, 5 + 3 * s:random()
        starts[i] = { r * math.cos(a), r * math.sin(a), s:random() * 2 * math.pi }
      end
    end
  end
  marker.pos = btVector3(cx, 0.3, -cy)
  for i, st in ipairs(starts) do
    local d = Veh.new(st[1], -st[2], Y0)
    d.body:setCenterOfMassTransform(btTransform(btQuaternion(btVector3(0, 1, 0), st[3]), btVector3(st[1], Y0, -st[2])))
    d.hx, d.hz = math.cos(st[3]), -math.sin(st[3])
    robots[i], agents[i] = d, DB.new(st[1], st[2], st[3])
    objToRobot[d.obj] = i
  end
  t, nextTick, finished, wall0, lastBad = 0, 0, false, os.time(), 0
  bumps, touching, passes, segs, lastSeg, dev = 0, {}, 0, {}, 0, 0
  P.kappaPoint = P.kappaPoint or P.kappa
  sx, sy = DB.particles(agents[1], P)
  L = math.max(1e-9, math.sqrt((cx - sx) ^ 2 + (cy - sy) ^ 2))
  print(string.format("Ch. 13 dumbbell on ground robots: case %d, n %d, seed %d, start %d, spread %g s",
    o.case, o.n, o.seed, o.start, o.spread))
end

local function measure()
  local m = DB.measure(agents, cx, cy, P)
  if o.n < 2 then m.gap, m.near = 1, 0 end
  local moving = 0
  for _, d in ipairs(robots) do if d.cl ~= 0 or d.cr ~= 0 then moving = moving + 1 end end
  m.moving = moving
  return m
end

local function apTick()
  P.kappa = (t < o.spread) and P.kappaSpread or P.kappaPoint
  for i, d in ipairs(robots) do
    local a = agents[i]
    a.x, a.y, a.psi = pose(d)
  end
  local F = DB.ring(agents, cx, cy, P)
  for i, d in ipairs(robots) do
    local a = agents[i]
    local u0 = a.u
    local u, om = DB.update(a, F[i][1], F[i][2], F[i][3], P)
    if u * u0 < 0 then passes = passes + 1 end
    Veh.drive(d, u, om)
  end
  if o.case == 1 then
    local u = agents[1].u
    local sg = (u > 1e-3) and 1 or (u < -1e-3) and -1 or 0
    if sg ~= 0 and sg ~= lastSeg then segs[#segs + 1] = string.format("%s@%.1f", sg > 0 and "F" or "B", t); lastSeg = sg end
    local fx, fy = DB.particles(agents[1], P)
    dev = math.max(dev, math.abs((cx - sx) * (sy - fy) - (sx - fx) * (cy - sy)) / L)
  end
  local m = measure()
  if not (m.radius < 0.1 and m.point < 5 and m.gap < 1.25) then lastBad = t end
end

local function checkContacts()
  local now = {}
  v:eachContact(function(a, b, x, y, z, nx, ny, nz, dist)
    if dist > 0.005 then return end
    local ra, rb = objToRobot[a], objToRobot[b]
    if not (ra and rb) then return end
    local key = math.min(ra, rb) * 1000 + math.max(ra, rb)
    if not now[key] then
      now[key] = true
      if not touching[key] then bumps = bumps + 1 end
    end
  end)
  touching = now
end

local function result()
  local m = measure()
  local formed = (lastBad < t - TICK * 1.5) and lastBad or -1
  print(string.format("Ring case %d n %d seed %d start %d spread %g Formed %.1f Radius %.3f Point %.2f Gap %.3f Near %.2f Moving %d Passes %d Bumps %d%s Wall %d",
    o.case, o.n, o.seed, o.start, o.spread, formed, m.radius, m.point, m.gap, m.near, m.moving, passes, bumps,
    o.case == 1 and string.format(" Segments %s Dev %.2f", table.concat(segs, ","), dev) or "", os.time() - wall0))
end

local function showStatus()
  local m = measure()
  local f = { "Ch. 13 dumbbell " .. (o.case == 1 and "turn" or "ring"),
    status.num("t", t, 1, false, 6, "s"),
    status.num("radius", m.radius, 3, false, 6, "m"),
    status.num("point", m.point, 1, false, 5, "deg") }
  if o.case == 0 then
    f[#f + 1] = status.num("gap", m.gap, 2, false, 5)
    f[#f + 1] = status.num("near", m.near, 2, false, 5, "m")
  end
  f[#f + 1] = status.int("moving", m.moving, 2)
  f[#f + 1] = status.int("passes", passes, 5)
  f[#f + 1] = status.int("bumps", bumps, 4)
  if o.spread > 0 and t < o.spread then f[#f + 1] = "spreading" end
  status.show(f)
end

local function physicsStep()
  if t >= nextTick - 1e-9 then apTick(); nextTick = nextTick + TICK end
  for _, d in ipairs(robots) do Veh.step(d, DT) end
  t = t + DT
end

setup()
common.setCamera(btVector3(0, 14, -12), btVector3(0, 0, 0))
v:addShortcut("R", function(N) setup() end)

v:preSim(function(N)
  if finished then return end
  for _ = 1, SUB - 1 do physicsStep(); v:stepSimulation(DT, 1, DT) end
  physicsStep()
end)
v:postSim(function(N)
  if finished then return end
  for _, d in ipairs(robots) do Veh.sync(d) end
  checkContacts()
  if N % 15 == 0 then showStatus() end
  if t >= LIMIT then
    finished = true
    showStatus()
    result()
    if EXIT then os.exit(0) end
  end
end)
v:preStop(function()
  if not finished and o then print(string.format("(stopped at %.1f s)", t)); result() end
end)
