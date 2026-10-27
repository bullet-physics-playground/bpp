--
-- lib/pointmass.lua -- the point-mass vehicle with limits (BOOK.md G5),
-- behind the vehicle interface (lib/swarm.lua, G18)
--
-- A vehicle with no shape and no Bullet body, only the three limits that
-- decide how well a real vehicle follows AP (Ch. 13's point mass,
-- book/ch13.md): a top speed, a top acceleration and a lag. It costs
-- almost nothing, so it stands in for vehicles when a swarm is large.
--
-- COMMAND  command(d, w, T, t): reach the point w (m) in T s. The desired
--          velocity is the leg's, u = (w - p) / T (m/s), for T s, then 0
--          (it stops where it is, as the ideal vehicle stops at w).
-- MOTION   every physics step (dt = 1/250 s):
--            a = (u - v) / max(pmLag, dt)       the lag: v follows u with
--                                               time constant pmLag (s)
--            |a| <= pmAccel                     (m/s^2, the vector's size)
--            v = v + a dt,  |v| <= pmSpeed      (m/s)
--            p = p + v dt
--          With pmLag 0 and both caps out of reach it is the ideal
--          vehicle (lib/ideal.lua): v = u for the leg, so it arrives at w.
-- VELOCITY velocity(d, v, t) (G4): the desired velocity is v (m/s) until
--          the next command, with the same lag and caps.
-- HOLD     D: the desired velocity is 0; it brakes at pmAccel.
-- DEPLOY   placed at its starting height on Setup, ready at once.
-- Nothing touches it (particles in the originals overlap freely), so
-- nothing is lost; a sphere is drawn at its position.
--
-- DEFINITIONS (its sliders; d.px, d.py, d.pz in m and d.vx, d.vy, d.vz in
-- m/s are its state, read by the harness and the probes):
--   pmSpeed  top speed (m/s)
--   pmAccel  top acceleration (m/s^2)
--   pmLag    time constant of the velocity's response (s; 0 = none)
--
-- The 2D plane is at PLANE_Y (as the drones' default altitude); the 3D
-- lattice is centred on it.
--

local V = {}

V.name    = "point mass"
V.noun    = "point masses"
V.moving  = "moving"
V.can3D   = true
V.fragile = false
V.floorY  = 0

local PLANE_Y = 12          -- m
local RADIUS = 0.2          -- m, drawn size only

-- Defaults: the quadcopter's (lib/README.md): its flight controller's
-- horizontal speed limit (vMaxH, quadcopter/flight.lua), its 35 degree
-- tilt limit (g tan 35 = 6.87 m/s^2), and the lag that best fits its
-- response to AP's commands (0.45 s; RMS 6.5% of the commanded speed at
-- 1, 2 and 4 m/s, the rest being the drone's ~0.15 s dead time)
V.params = {
  { "pmSpeed", 6.0,  0.1, 10, 0.1,  "point mass: top speed (m/s)" },
  { "pmAccel", 6.87, 0.1, 20, 0.01, "point mass: top acceleration (m/s^2)" },
  { "pmLag",   0.45, 0,   2,  0.05, "point mass: time constant of its velocity's response (s; 0 = none)" },
}

-- the limits, read from the sliders at every command when there are any
-- (V.limits() sets them directly, for a check or a probe without sliders)
local LIM = { speed = 6.0, accel = 6.87, lag = 0.45 }
function V.limits(speed, accel, lag)
  if speed then LIM.speed, LIM.accel, LIM.lag = speed, accel, lag end
  return LIM.speed, LIM.accel, LIM.lag
end
local function readLimits()
  if rawget(_G, "v") and v.getParam then
    local ok, s = pcall(function() return v:getParam("pmSpeed") end)
    if ok and s then
      LIM.speed, LIM.accel, LIM.lag = s, v:getParam("pmAccel"), v:getParam("pmLag")
    end
  end
end

function V.planeY() return PLANE_Y end

function V.new(x, z, toAlt)
  local o = Sphere(RADIUS, 0)
  o.col = "#ffffff"
  o.collides = false
  o.pos = btVector3(x, toAlt, z)
  v:add(o)
  return { obj = o, px = x, py = toAlt, pz = z, vx = 0, vy = 0, vz = 0,
           ux = 0, uy = 0, uz = 0, legLeft = 0 }
end

function V.remove(d) v:remove(d.obj) end
function V.setColor(d, col) d.obj.col = col end
function V.sync(d) d.obj.pos = btVector3(d.px, d.py, d.pz) end

local function stopLeg(d) d.ux, d.uy, d.uz, d.legLeft = 0, 0, 0, 0 end
function V.join(d, simTime) stopLeg(d) end
function V.hold(d) stopLeg(d) end

function V.command(d, wx, wy, wz, T, simTime)
  readLimits()
  d.ux, d.uy, d.uz = (wx - d.px) / T, (wy - d.py) / T, (wz - d.pz) / T
  d.legLeft = T
end

function V.velocity(d, vx, vy, vz, simTime)
  readLimits()
  d.ux, d.uy, d.uz = vx, vy, vz
  d.legLeft = math.huge
end

-- one step of the motion (also used by checks): dt in s
function V.advance(d, dt)
  local ux, uy, uz = 0, 0, 0
  if d.legLeft > 1e-9 then ux, uy, uz = d.ux, d.uy, d.uz; d.legLeft = d.legLeft - dt end
  local tau = math.max(LIM.lag, dt)
  local ax, ay, az = (ux - d.vx) / tau, (uy - d.vy) / tau, (uz - d.vz) / tau
  local a = math.sqrt(ax * ax + ay * ay + az * az)
  if a > LIM.accel then local k = LIM.accel / a; ax, ay, az = ax * k, ay * k, az * k end
  local vx, vy, vz = d.vx + ax * dt, d.vy + ay * dt, d.vz + az * dt
  local s = math.sqrt(vx * vx + vy * vy + vz * vz)
  if s > LIM.speed then local k = LIM.speed / s; vx, vy, vz = vx * k, vy * k, vz * k end
  d.vx, d.vy, d.vz = vx, vy, vz
  d.px, d.py, d.pz = d.px + vx * dt, d.py + vy * dt, d.pz + vz * dt
end

function V.guide(d, st, simTime, dt)
  if st == "takeoff" then
    d.ready = true
  elseif st == "ap" or st == "hold" then
    V.advance(d, dt)
  end
end

function V.step(d, dt) end

return V
