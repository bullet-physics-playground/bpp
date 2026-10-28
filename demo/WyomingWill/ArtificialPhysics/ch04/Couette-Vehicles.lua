--
-- ch04/Couette-Vehicles.lua -- Couette flow (kt.nlogo, Ch. 4.4) flown by
-- vehicles through velocity commands (BOOK.md G4)
--
-- Kinetic theory decides velocities, not points, so each agent is told
-- "fly this velocity" (the vehicle interface's velocity(), lib/swarm.lua).
-- Every KT tick (apHz, 5 Hz) the scene:
--   1. senses every vehicle's ACTUAL position and velocity, in kt.nlogo's
--      units (position / metersPerUnit; velocity / (metersPerUnit apHz),
--      units per tick);
--   2. adds the ACTUAL velocities to the 13-column profile
--      (ch04/couette.lua's monitor: mean vy per column, mean speed);
--   3. runs one tick of kt.nlogo's collisions and walls on the actual
--      positions and on KT's OWN velocities, the ones it commanded
--      (ch04/couette.lua's collide, with the same switches);
--   4. commands each vehicle its new velocity, in m/s, plus a pull back to
--      the plane's height (vy = planeY - y, per s; drones only drift).
-- The first command, when all are deployed, is kt.nlogo's setup velocity.
-- KT keeps its own velocities as the formation harness keeps AP's (and as
-- Kerr's robots carry theirs, exchanging them by message): a vehicle's lag
-- moves it late, not with another velocity in the theory's books.
-- senseVelocity (off by default) collides the SENSED velocities instead;
-- with lag, a vehicle sensed part-way to its new velocity then takes that
-- mix into its next collision, which loses energy like an inelastic
-- collision and cools the gas (ch04/README.md).
--
-- THE WORLD is kt.nlogo's (85 x 85 units, walls at |x| beyond ~39, 13
-- columns, wrapping), laid on the ground plane: kt's x is the world's x,
-- kt's y the world's z, at the vehicle's plane height. With metersPerUnit
-- 0.5 the corridor is 42.5 m wide, the collision range 1 m and Wall_Velocity
-- 1 is 2.5 m/s at 5 Hz. The corridor wraps along its length, as the model
-- does, by moving a vehicle that leaves one end to the other (state kept).
-- A vehicle that overshoots a wall past the world's edge comes out at the
-- other wall, as in the model's torus: counted as `crossed`.
--
-- VEHICLE (environment): lib.pointmass (default), lib.ideal,
-- quadcopter.vehicle, boat.vehicle (any vehicle with velocity()). Drones
-- start at least 2 units (1 m) apart and take off first; nothing breaks
-- on contact here (touches are not counted).
--
-- DEFINITIONS (sliders; status line; the result line):
--   particles   N, vehicles at the next Setup (R)
--   wallVelocity  V, units per tick (x metersPerUnit x apHz = m/s)
--   temperature   T, units^2 per tick^2
--   inward      ch04/couette.lua's switch: walls thermalise only vehicles
--               moving into them (Kerr's rule, the default; F85); false
--               = kt.nlogo's wall (the runs in ch04/README.md used false)
--   senseVelocity  collide the vehicles' sensed velocities instead of
--               KT's own (above); false = KT's own
--   separate    collisions always end with the pair moving apart (the
--               random angle's relative velocity flipped if it would
--               close them; ch04/couette.lua, F90); false = kt.nlogo's
--   collisionRange  the collision distance, units (2 = kt.nlogo's)
--   lost        vehicles that failed (drones: prop strike or tilt
--               failsafe), at the end
--   apHz, metersPerUnit  the KT rate (Hz) and the scale (m per unit).
--               A vehicle tracks KT only if its lag is shorter than a KT
--               tick (F91): drones (lag ~0.65 s) at 1 Hz, with the scale
--               raised to keep speeds in m/s (5 Hz x 0.5 = 1 Hz x 2.5)
--   resampleAt  KT ticks after which the profile restarts (Resample)
--   slope, corr the 13 bars' least-squares slope (units/tick per column)
--               and correlation (compute-stats); ratio = slope / (V/6)
--   speed       mean sensed speed / sqrt(T) (theory 1.2533 at V = 0)
--   lag         mean |sensed velocity - commanded velocity| at sensing,
--               over the mean commanded speed: how far the vehicles are
--               from what the last tick asked (0 for the ideal vehicle)
--   crossed     vehicles that came out at the other wall (per 1000 ticks)
--   result line (printed every 1000 ticks and at the end):
--     COUETTE vehicle=... n=... V=... T=... inward=... sense=... separate=...
--     range=... ticks=... slope=... ratio=... corr=... speed=... lag=...
--     crossed=... lost=...
--
-- Run (headless), from the ArtificialPhysics folder:
--   VEHICLE=lib.pointmass KT_N=1000 KT_TICKS=10000 bpp -f ch04/Couette-Vehicles.lua -n 62600
--   (KT_N, KT_V, KT_T, KT_INWARD, KT_SENSE, KT_SEPARATE, KT_RANGE, KT_HZ,
--   KT_MPU, KT_TICKS, KT_LAG set the parameters)
--   without the GUI; it stops stepping after KT_TICKS, Resample at half)
--

package.path = "./?.lua;" .. package.path
local common = require "common"
local rng    = require "lib.rng"
local status = require "lib.status"
local C      = require "ch04.couette"

local VEHICLE = os.getenv("VEHICLE")
if not VEHICLE or VEHICLE == "" then VEHICLE = "lib.pointmass" end
local Veh = require(VEHICLE)
assert(Veh.velocity, VEHICLE .. " has no velocity(): it cannot fly kinetic theory")

local function env(name, default)
  local s = os.getenv(name)
  if s == nil or s == "" then return default end
  if s == "true" then return true elseif s == "false" then return false end
  return tonumber(s) or s
end
local TICKS = env("KT_TICKS", nil)           -- headless: stop after this many KT ticks

rng.init(v, 1)
v:addParam("particles", env("KT_N", 100), 1, 1000, 1, "vehicles at the next Setup (R)")
v:addParam("wallVelocity", env("KT_V", 1.0), 0, 2, 0.1, "Wall_Velocity V (units per tick; x metersPerUnit x apHz = m/s)")
v:addParam("temperature", env("KT_T", 0.01), 0.001, 0.04, 0.001, "Temperature T (units^2 per tick^2)")
v:addParam("inward", env("KT_INWARD", true), "walls thermalise only vehicles moving into them (Kerr's rule, F85); off = kt.nlogo's wall")
v:addParam("senseVelocity", env("KT_SENSE", false), "collide the vehicles' sensed velocities, not KT's own (cools the gas when vehicles lag)")
v:addParam("separate", env("KT_SEPARATE", false), "collisions always end with the pair moving apart (F90); off = kt.nlogo's random angle")
v:addParam("collisionRange", env("KT_RANGE", 2), 1, 10, 0.5, "collision distance (units; 2 = kt.nlogo's), used by the next Setup (R)")
v:addParam("apHz", env("KT_HZ", 5), 1, 20, 1, "kinetic-theory ticks per second")
v:addParam("metersPerUnit", env("KT_MPU", 0.5), 0.1, 5, 0.05, "metres per kt.nlogo unit")
v:addParam("resampleAt", TICKS and math.floor(TICKS / 2) or 2500, 0, 1e6, 100, "KT ticks after which the profile restarts (Resample)")
for _, prm in ipairs(Veh.params or {}) do
  local val = prm[2]
  if prm[1] == "pmLag" then val = env("KT_LAG", val) end   -- the point mass's lag, headless
  if type(val) == "boolean" then v:addParam(prm[1], val, prm[3])
  else v:addParam(prm[1], val, prm[3], prm[4], prm[5], prm[6]) end
end

local DT, STEPS = 1 / 250, 8
common.setTiming(DT, 1, DT)
common.gravity(-9.81)
local floor = Plane(0, 1, 0, Veh.floorY or 0, 120)
floor.col = Veh.groundColor or "#6a7a6a"
v:add(floor)
if Veh.scene then Veh.scene() end

-- the two walls, drawn only (kt's x 39.5-42.5 and -42.5 to -39.5)
local function wallStrip(x0, col)
  local s = v:getParam("metersPerUnit")
  local b = Cube(3 * s, 0.05, 85 * s, 0)
  b.pos = btVector3(x0 * s, (Veh.floorY or 0) + 0.03, 0)
  b.col, b.collides = col, false
  v:add(b)
end
wallStrip(41, "#d03030")
wallStrip(-41, "#e0c020")

local m, agents, t, nextTick, phase, mpu, hz
local lagSum, cmdSum, crossed, crossedMark = 0, 0, 0, 0
local W = 85

local function setup()
  rng.reseed()
  for _, d in ipairs(agents or {}) do Veh.remove(d) end
  mpu, hz = v:getParam("metersPerUnit"), v:getParam("apHz")
  local n = math.floor(v:getParam("particles"))
  m = C.new({ n = n, V = v:getParam("wallVelocity"), T = v:getParam("temperature"),
              seed = rng.getSeed() or 1, inward = v:getParam("inward"),
              separate = v:getParam("separate"), range = v:getParam("collisionRange") })
  if Veh.fragile then                        -- drones: start at least 2 units apart
    for i = 2, n do
      local ok = false
      while not ok do
        ok = true
        for j = 1, i - 1 do
          if (m.x[i] - m.x[j]) ^ 2 + (m.y[i] - m.y[j]) ^ 2 < 4 then ok = false; break end
        end
        if not ok then
          m.x[i] = 7 * (m.s:random() * W - 42.5) / 8
          m.y[i] = 7 * (m.s:random() * W - 42.5) / 8
        end
      end
    end
  end
  agents = {}
  for i = 1, n do agents[i] = Veh.new(m.x[i] * mpu, m.y[i] * mpu, Veh.planeY()) end
  t, nextTick, phase = 0, nil, "deploy"
  lagSum, cmdSum, crossed, crossedMark = 0, 0, 0, 0
  print(string.format("Couette on %s: %d vehicles, V %.2f, T %.4f, inward %s, %d Hz, %.2f m/unit, seed %d",
    VEHICLE, n, m.V, m.T, tostring(m.inward), hz, mpu, rng.getSeed() or 0))
end

local function wrapAgent(d, i)
  -- along the corridor (world z = kt y): always; across it (x): counted
  local lim = 42.5 * mpu
  local dx, dz = 0, 0
  if d.pz >= lim then dz = -W * mpu elseif d.pz < -lim then dz = W * mpu end
  if d.px >= lim then dx = -W * mpu; crossed = crossed + 1 elseif d.px < -lim then dx = W * mpu; crossed = crossed + 1 end
  if dx == 0 and dz == 0 then return end
  d.px, d.pz = d.px + dx, d.pz + dz
  if d.body then
    local o = d.body:getCenterOfMassPosition()
    d.body:setCenterOfMassTransform(btTransform(d.body:getOrientation(), btVector3(o.x + dx, o.y, o.z + dz)))
  end
  if d.spx then d.spx, d.spz = d.spx + dx, d.spz + dz end
end

local function result(tag)
  local sl, r = C.stats(m)
  local lost = 0
  for _, d in ipairs(agents) do if d.failed then lost = lost + 1 end end
  local line = string.format("COUETTE vehicle=%s n=%d V=%g T=%g inward=%s sense=%s separate=%s range=%g ticks=%d slope=%.5f ratio=%.4f corr=%.5f speed=%.4f lag=%.4f crossed=%.2f lost=%d",
    VEHICLE, m.n, m.V, m.T, tostring(m.inward), tostring(v:getParam("senseVelocity")), tostring(m.separate), m.range, m.ticks, sl, m.V > 0 and sl * 6 / m.V or 0, r,
    C.meanSpeed(m) / math.sqrt(m.T), cmdSum > 0 and lagSum / cmdSum or 0, crossed * 1000 / math.max(1, m.ticks), lost)
  print(line .. (tag or ""))
end

local ownX, ownY = {}, {}
local function ktTick()
  local k = 1 / (mpu * hz)
  local X, Y, VX, VY, SP = m.x, m.y, m.vx, m.vy, m.v
  local sense = v:getParam("senseVelocity")
  -- 1. sense, and how far each vehicle is from its last command
  for i, d in ipairs(agents) do
    local vx, vy = d.vx * k, d.vz * k
    if m.ticks > 0 then
      lagSum = lagSum + math.sqrt((vx - VX[i]) ^ 2 + (vy - VY[i]) ^ 2)
      cmdSum = cmdSum + math.sqrt(VX[i] ^ 2 + VY[i] ^ 2)
    end
    ownX[i], ownY[i] = VX[i], VY[i]                -- KT's own (commanded) velocities
    X[i], Y[i], VX[i], VY[i] = d.px / mpu, d.pz / mpu, vx, vy
    SP[i] = math.sqrt(vx * vx + vy * vy)
  end
  -- 2. the profile of the actual velocities (Resample at resampleAt)
  m.ticks = m.ticks + 1
  if m.ticks == math.floor(v:getParam("resampleAt")) + 1 then C.resample(m) end
  C.monitor(m)
  if not sense then
    for i = 1, m.n do VX[i], VY[i] = ownX[i], ownY[i] end
  end
  -- 3. collisions and walls; 4. the commands
  m.V, m.T, m.inward = v:getParam("wallVelocity"), v:getParam("temperature"), v:getParam("inward")
  m.separate = v:getParam("separate")
  C.collide(m)
  for i, d in ipairs(agents) do
    Veh.velocity(d, VX[i] / k, Veh.planeY() - d.py, VY[i] / k, t)
  end
  if m.ticks % 1000 == 0 then result() end
end

local function physicsStep()
  if phase == "deploy" then
    local all = true
    for _, d in ipairs(agents) do
      Veh.guide(d, "takeoff", t, DT)
      if not d.ready then all = false end
    end
    if all then                              -- kt.nlogo's setup velocities, as the first command
      local k = mpu * hz
      for i, d in ipairs(agents) do
        Veh.join(d, t)
        Veh.velocity(d, m.vx[i] * k, 0, m.vy[i] * k, t)
      end
      phase, nextTick = "kt", t + 1 / hz
    end
  else
    if t >= nextTick then ktTick(); nextTick = nextTick + 1 / hz end
    for i, d in ipairs(agents) do Veh.guide(d, "ap", t, DT); wrapAgent(d, i) end
  end
  for _, d in ipairs(agents) do Veh.step(d, DT) end
  t = t + DT
end

local function showStatus()
  if not m then return end
  local sl, r = 0, 0
  if m.sample > 1 then sl, r = C.stats(m) end
  status.show({ "Couette on " .. Veh.noun,
    status.int("ticks", m.ticks, 7),
    status.num("slope", sl, 4, false, 7),
    status.num("ratio", m.V > 0 and sl * 6 / m.V or 0, 3, false, 6),
    status.num("corr", r, 4, false, 7),
    status.num("speed", m.sample > 0 and C.meanSpeed(m) / math.sqrt(m.T) or 0, 3, false, 6),
    status.num("lag", cmdSum > 0 and lagSum / cmdSum or 0, 3, false, 6) })
end

setup()
common.setCamera(btVector3(0, 70 * mpu, 35 * mpu), btVector3(0, 0, 0))

v:onParamChanged(function(N, name, value)
  if rng.isSeedChange(name) or name == "particles" or name == "metersPerUnit" or name == "collisionRange" then setup() end
end)
v:addShortcut("R", function(N) setup() end)

-- headless: the run stops stepping after KT_TICKS (give bpp -n at least
-- (KT_TICKS / apHz + deploy time) x 31.25 frames; the drones' takeoff
-- takes ~8 s), and the result line ends with final=1
local done = false
v:preSim(function(N)
  if done then return end
  for _ = 1, STEPS - 1 do physicsStep(); v:stepSimulation(DT, 1, DT) end
  physicsStep()
  if TICKS and m.ticks >= TICKS then result(" final=1"); done = true end
end)
v:preStop(function()
  if TICKS and not done then result(" final=0 (stopped before KT_TICKS)") end
end)
v:postSim(function(N)
  for _, d in ipairs(agents) do Veh.sync(d) end
  if N % 15 == 0 then showStatus() end
end)
