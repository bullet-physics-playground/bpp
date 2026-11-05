--
-- ch13/Triangle-Ground.lua -- Ch. 13's "triangle of death" (§13.2.2,
-- PDF 454-456, Figs. 13.9-13.11; book/ch13.md E6; HANDOFF.md §7, Ch. 13
-- step 3) on BPP's Pioneer 3-ATs (ground/vehicle.lua, in Bullet)
--
-- THE SETUP AND THE CONTROLLER are ch13/triangle.lua's (stated there):
-- three robots on an equilateral triangle of side D = 1 m, axles through
-- its centre, Fig. 13.8's law between their particles, the point-mass
-- controller of Eqs. 13.7-13.8 with the book's stop threshold, and a
-- constant pull on robot 3 (the one lower left) toward a point 10 m out
-- along its axle, turned by `angle`. Ten times a second each robot's pose
-- is sensed exactly from Bullet (its rotation centre and heading), its
-- particle put `offset` metres ahead of the centre, and (u, Omega) sent
-- to its wheels (drive()). The plane's (x, y) is the world's (x, -z).
--
-- THE BOOK'S CLAIM (PDF 454-455): with the particle at the rotation
-- centre robot 3 turns to face the pull and drives off, dragging the
-- others; with the particle off the centre, turning moves it into an
-- opposing turning force, and the robot stops in its new orientation or
-- turns back and forth at the minimum speed for ever.
--
-- SLIDERS (and the environment, for headless runs):
--   offset     m, the particle ahead of the rotation centre (TRI_OFFSET)
--   angle      deg, the pull turned from robot 3's axle toward the way it
--              faces (0 = parallel to the axle, Fig. 13.11) (TRI_ANGLE)
--   pull       N, the pull on robot 3 (TRI_PULL; 25 = the law's weakest
--              attraction)
--   stop       N, the book's stop threshold (TRI_STOP; 5, triangle.lua's
--              STOP; 0 = never stop)
--   roundDown  wheels commanded below 0.1 m/s stop instead of turning at
--              0.1 m/s (ground/vehicle.lua's roundDown, off by default;
--              the reading before F72) (TRI_DOWN=1)
--
-- DEFINITIONS (status line and result line; metres, seconds, degrees):
--   t        simulated time, s
--   moved    robot 3's move toward the pull's point since the start, m
--   turned   robot 3's heading change since the start, deg (+ = left)
--   escaped  the time robot 3 first moved 1 m toward the point (-1: not
--            yet)
--   flips    changes of sign of robot 3's turn command Omega
--   moving   robots with a wheel commanded (not 0) now
--   bumps    new robot-robot contacts
--   result line, at the end (limit seconds, default 120):
--     Triangle offset d angle a pull p roundDown 0|1 stop s Escaped e Moved m
--     Turned t Flips f Moving n Bumps b Wall w
--
-- Run (headless), from the ArtificialPhysics folder:
--   TRI_OFFSET=0.2 TRI_EXIT=1 bpp -f ch13/Triangle-Ground.lua -n 100000
--   (TRI_LIMIT seconds; TRI_EXIT=1 ends BPP when the run ends)
--

local function exists(f) local h = io.open(f); if h then h:close() end; return h ~= nil end
local HOME = exists("ch13/triangle.lua") and "." or ".."
package.path = HOME .. "/?.lua;" .. package.path
local common = require "common"
local status = require "lib.status"
local T      = require "ch13.triangle"
local Veh    = require "ground.vehicle"

local function env(name, default)
  local s = os.getenv(name)
  if s == nil or s == "" then return default end
  return tonumber(s) or s
end
local LIMIT = env("TRI_LIMIT", 120)
local EXIT = env("TRI_EXIT", 0) == 1

v:addParam("offset", env("TRI_OFFSET", 0), 0, 0.4, 0.05, "particle ahead of the rotation centre, m (Setup, R)")
v:addParam("angle", env("TRI_ANGLE", 0), -90, 90, 5, "pull turned from robot 3's axle toward its heading, deg (Setup, R)")
v:addParam("pull", env("TRI_PULL", 25), 0, 100, 5, "pull on robot 3, N (Setup, R)")
v:addParam("stop", env("TRI_STOP", 5), 0, 20, 1, "stop threshold, N: |F| below it stops the robot (0 = never; Setup, R)")
v:addParam("roundDown", env("TRI_DOWN", 0) == 1, "wheels below 0.1 m/s stop (ground/vehicle.lua's roundDown; Setup, R)")

local DT, SUB, TICK = 1 / 250, 8, 1 / T.HZ
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

local atan2 = math.atan2 or function(y, x) return math.atan(y, x) end
local o, w, bots, objToRobot = nil, nil, {}, {}
local t, nextTick, finished, wall0 = 0, 0, false, 0
local bumps, touching, flips, lastSg, escaped = 0, {}, 0, 0, -1
local x0, y0, psi0, gx, gy = 0, 0, 0, 1, 0

local function setup()
  for _, d in ipairs(bots) do Veh.remove(d) end
  bots, objToRobot = {}, {}
  o = { offset = v:getParam("offset"), angle = v:getParam("angle"), pull = v:getParam("pull"),
        down = v:getParam("roundDown"), stop = v:getParam("stop") }
  T.GOAL, T.STOP = o.pull, o.stop
  Veh.roundDown = o.down
  w = T.new(o.offset, math.rad(o.angle))
  marker.pos = btVector3(w.goal[1], 0.3, -w.goal[2])
  for i, r in ipairs(w.robots) do
    local d = Veh.new(r.x, -r.y, Y0)
    d.body:setCenterOfMassTransform(btTransform(btQuaternion(btVector3(0, 1, 0), r.psi), btVector3(r.x, Y0, -r.y)))
    d.hx, d.hz = math.cos(r.psi), -math.sin(r.psi)
    if i == 3 then Veh.setColor(d, "#e0c040") end
    bots[i] = d
    objToRobot[d.obj] = i
  end
  local r3 = w.robots[3]
  x0, y0, psi0 = r3.x, r3.y, r3.psi
  gx, gy = w.goal[1] - x0, w.goal[2] - y0
  local g = math.sqrt(gx * gx + gy * gy); gx, gy = gx / g, gy / g
  t, nextTick, finished, wall0 = 0, 0, false, os.time()
  bumps, touching, flips, lastSg, escaped = 0, {}, 0, 0, -1
  print(string.format("Ch. 13 triangle of death on ground robots: offset %g m, angle %g deg, pull %g N, stop %g N%s",
    o.offset, o.angle, o.pull, o.stop, o.down and ", roundDown" or ""))
end

local function measure()
  local r3 = w.robots[3]
  local moving = 0
  for _, d in ipairs(bots) do if d.cl ~= 0 or d.cr ~= 0 then moving = moving + 1 end end
  local turned = (r3.psi - psi0 + math.pi) % (2 * math.pi) - math.pi
  return (r3.x - x0) * gx + (r3.y - y0) * gy, math.deg(turned), moving
end

local function apTick()
  for i, d in ipairs(bots) do
    local r = w.robots[i]
    r.x, r.y, r.psi = d.px, -d.pz, atan2(-d.hz, d.hx)
  end
  T.tick(w)
  for i, d in ipairs(bots) do Veh.drive(d, w.robots[i].u, w.robots[i].omega) end
  local om = w.robots[3].omega
  local sg = (om > 0) and 1 or (om < 0) and -1 or 0
  if sg ~= 0 and lastSg ~= 0 and sg ~= lastSg then flips = flips + 1 end
  if sg ~= 0 then lastSg = sg end
  local moved = measure()
  if escaped < 0 and moved >= 1 then escaped = t end
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
  local moved, turned, moving = measure()
  print(string.format("Triangle offset %g angle %g pull %g roundDown %d stop %g Escaped %.1f Moved %.3f Turned %.1f Flips %d Moving %d Bumps %d Wall %d",
    o.offset, o.angle, o.pull, o.down and 1 or 0, o.stop, escaped, moved, turned, flips, moving, bumps, os.time() - wall0))
end

local function showStatus()
  local moved, turned, moving = measure()
  status.show({ "Ch. 13 triangle of death",
    status.num("t", t, 1, false, 6, "s"),
    status.num("moved", moved, 2, true, 6, "m"),
    status.num("turned", turned, 0, true, 5, "deg"),
    status.num("escaped", escaped, 1, false, 6, "s"),
    status.int("flips", flips, 4),
    status.int("moving", moving, 2),
    status.int("bumps", bumps, 3) })
end

local function physicsStep()
  if t >= nextTick - 1e-9 then apTick(); nextTick = nextTick + TICK end
  for _, d in ipairs(bots) do Veh.step(d, DT) end
  t = t + DT
end

setup()
common.setCamera(btVector3(-2, 9, -8), btVector3(-2, 0, 1))
v:addShortcut("R", function(N) setup() end)

v:preSim(function(N)
  if finished then return end
  for _ = 1, SUB - 1 do physicsStep(); v:stepSimulation(DT, 1, DT) end
  physicsStep()
end)
v:postSim(function(N)
  if finished then return end
  for _, d in ipairs(bots) do Veh.sync(d) end
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
  if not finished and w then print(string.format("(stopped at %.1f s)", t)); result() end
end)
