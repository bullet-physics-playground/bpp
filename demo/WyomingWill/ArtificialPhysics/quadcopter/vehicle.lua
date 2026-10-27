--
-- quadcopter/vehicle.lua -- the quadcopter behind the vehicle interface
-- (BOOK.md G18; lib/swarm.lua says what every vehicle provides)
--
-- Artificial Physics (lib/swarm.lua) decides where each agent should be at
-- the next AP tick; this file is how a quadcopter gets there. Everything
-- here was in quadcopter/swarm.lua before the harness served more than one
-- kind of vehicle (milestone M2), unchanged in meaning:
--
--   COMMAND  command(d, wx, wy, wz, T, t): reach the waypoint w (m) in T s.
--            The drone is handed a straight-line trajectory from where it
--            is to w, arriving at the next AP tick: position setpoint
--            sp = start + vf (t - t0) with velocity feed-forward
--            vf = (w - start) / T (m/s), then it holds w. Its PX4-style
--            flight controller (quadcopter/flight.lua) flies it.
--   VELOCITY velocity(d, vx, vy, vz, t) (G4): fly this velocity (m/s)
--            until the next command, as PX4's velocity mode: the position
--            setpoint follows the drone (no position error), the
--            feed-forward is the velocity. Height is the caller's to hold.
--   DEPLOY   takeoff: straight up at CLIMB_RATE (1.5 m/s) to its starting
--            altitude; ready (d.ready) once within 0.3 m of it and slower
--            than 0.3 m/s vertically.
--   LAND     [: straight down at LAND_RATE (1 m/s); parked (d.parked) on
--            the ground with motors off.
--   HOLD     D: position hold where it is.
--   AIR      at 50 Hz: wind (steady, along +z, windSpeed m/s), gusts (an
--            Ornstein-Uhlenbeck process, std dev gust m/s, 2 s
--            correlation, shared by all), and downwash: each drone's wake
--            is a widening downward jet (centre speed from momentum
--            theory, 2 sqrt(T / 2 rho A), spreading 0.15 m per m below,
--            Gaussian profile, drifting with the wind) that any drone
--            underneath flies in, scaled by `downwash`.
--   PLANE    2D: everyone flies at `altitude` (m); 3D: AP's y is height
--            around it. Waypoints are kept between 2 m and 60 m.
--   FRAGILE  a drone that touches another drone, an obstacle, or the
--            ground in flight loses its props (propStrikes).
--   SOUND    quadcopter/sound.lua, from the motor speeds.
--

local Quad  = require "quadcopter.flight"
local Sound = require "quadcopter.sound"
local rng   = require "lib.rng"

local V = {}

V.name   = "quadcopter"
V.noun   = "drones"          -- what the agents are called in messages
V.moving = "flying"          -- the status line's word for agents under AP
V.can3D  = true
V.fragile = true             -- contact = crash (with propStrikes on)
V.floorY = 0                 -- the ground plane's height (m)
V.geofence = { min = 2.0, max = 60.0 }   -- waypoint heights kept inside (m)

local CLIMB_RATE = 1.5       -- m/s, takeoff
local LAND_RATE = 1.0        -- m/s, landing

-- sliders this vehicle adds to the harness's (name, default, min, max,
-- step, comment; or name, boolean, comment)
V.params = {
  { "altitude",     12,   4,   40,   1,    "formation altitude (m): the 2D plane, or the 3D centre" },
  { "windSpeed",    0,    0,   15,   0.5,  "steady wind along +z (m/s)" },
  { "gust",         0,    0,   5,    0.25, "gust strength, std dev (m/s)" },
  { "downwash",     1,    0,   2,    0.1,  "downwash strength (0 = off, 1 = momentum theory)" },
  { "launchOrder",  0,    0,   4,    1,    "how Setup (R) launches: 0 all at once, 1 thirds top level first, 2 thirds bottom level first, 3 thirds at random heights, 4 one at a time" },
  { "launchGap",    15,   2,   60,   1,    "seconds between launch waves (one at a time: the same total time, spread evenly)" },
}
V.lateParams = {             -- (after the shared display sliders, as before)
  { "propStrikes", true, "drones touching another drone, an obstacle, or the ground in flight lose their props and fall" },
  { "soundVolume",  0.5,  0,   1,    0.05, "rotor sound from the camera's point of view (0 = silent; M mutes)" },
  { "soundEmphasis", 0.7, 0,   1,    0.05, "0 = the physical sound; higher = busy drones louder and voiced on their own, a settled swarm quieter" },
}

-- the 2D plane's height (or the 3D formation's centre), m
function V.planeY() return v:getParam("altitude") end

function V.new(x, z, toAlt)
  local d = Quad.new(x, Quad.GROUND_Y, z)
  d.toAlt = toAlt
  d.armed = true
  d.spx, d.spy, d.spz = x, Quad.GROUND_Y, z
  return d
end

V.remove   = Quad.remove
V.setColor = Quad.setColor
V.sync     = Quad.sync
V.step     = Quad.step

-- hand over to AP: hold where it is until the first command
function V.join(d, simTime)
  d.velMode = false
  d.wpx, d.wpy, d.wpz = d.px, d.py, d.pz
  d.t0, d.trT, d.sx, d.sy, d.sz = simTime, 1e9, d.px, d.py, d.pz
  d.vfx, d.vfy, d.vfz = 0, 0, 0
end

-- AP's command: reach (wx, wy, wz) in T s, by a straight-line trajectory
function V.command(d, wx, wy, wz, T, simTime)
  d.velMode = false
  d.wpx, d.wpy, d.wpz = wx, wy, wz
  d.t0, d.trT = simTime, T
  d.sx, d.sy, d.sz = d.px, d.py, d.pz
  d.vfx, d.vfy, d.vfz = (wx - d.px) / T, (wy - d.py) / T, (wz - d.pz) / T
end

-- G4: fly this velocity until the next command
function V.velocity(d, vx, vy, vz, simTime)
  d.velMode = true
  d.vfx, d.vfy, d.vfz = vx, vy, vz
end

-- D: position hold where it is
function V.hold(d)
  d.velMode = false
  d.spx, d.spy, d.spz, d.vfx, d.vfy, d.vfz = d.px, d.py, d.pz, 0, 0, 0
end

-- [: start landing where it is
function V.land(d)
  d.spx, d.spy, d.spz = d.px, d.py, d.pz
end

-- every physics step, by state: sets d.ready (takeoff done) and d.parked
-- (landing done)
function V.guide(d, st, simTime, dt)
  if st == "takeoff" then
    d.holdVertI = d.py < 0.3
    if d.spy < d.toAlt then
      d.spy = math.min(d.toAlt, d.spy + CLIMB_RATE * dt)
      d.vfy = CLIMB_RATE
    else
      d.vfy = 0
      d.ready = math.abs(d.py - d.toAlt) < 0.3 and math.abs(d.vy) < 0.3
    end
  elseif st == "ap" and d.velMode then
    d.spx, d.spy, d.spz = d.px, d.py, d.pz        -- velocity mode: no position error
  elseif st == "ap" then
    -- follow the current AP leg: sp = start + vff * (t - t0), until the waypoint
    local u = simTime - d.t0
    if u >= d.trT then
      d.spx, d.spy, d.spz = d.wpx, d.wpy, d.wpz
      d.vfx, d.vfy, d.vfz = 0, 0, 0
    else
      d.spx, d.spy, d.spz = d.sx + d.vfx * u, d.sy + d.vfy * u, d.sz + d.vfz * u
    end
  elseif st == "landing" then
    d.vfx, d.vfz = 0, 0
    d.spy = math.max(Quad.GROUND_Y - 0.2, d.spy - LAND_RATE * dt)
    d.vfy = (d.spy > Quad.GROUND_Y) and -LAND_RATE or 0
    if d.py < Quad.GROUND_Y + 0.05 and math.abs(d.vy) < 0.2 then
      d.armed = false
      d.parked = true
    end
  end
end

-- air: wind + gusts + downwash, refreshed at 50 Hz by the harness
local gustX, gustZ = 0, 0
function V.air(drones, p, dtAir)
  -- gusts: an Ornstein-Uhlenbeck process (2 s correlation), shared by all
  local a = math.exp(-dtAir / 2.0)
  local sg = p.gust * math.sqrt(1 - a * a)
  local function gauss() return math.sqrt(-2 * math.log(rng.random() + 1e-12)) * math.cos(2 * math.pi * rng.random()) end
  gustX, gustZ = gustX * a + sg * gauss(), gustZ * a + sg * gauss()

  local wx, wz = gustX, p.windSpeed + gustZ
  for _, d in ipairs(drones) do d.airx, d.airy, d.airz = wx, 0, wz end
  if p.downwash <= 0 then return end

  local R0 = Quad.DISC_RADIUS
  for _, up in ipairs(drones) do
    if up.thrust > 1 then
      local w0 = Quad.wakeSpeed(up.thrust) * p.downwash
      for _, dn in ipairs(drones) do
        if dn ~= up then
          local dy = up.py - dn.py
          if dy > 0.15 and dy < 10 then
            -- the wake drifts with the wind: the jet centre at depth dy
            local tFall = dy / math.max(w0 * 0.5, 0.5)
            local cx, cz = up.px + wx * tFall, up.pz + wz * tFall
            local rw = R0 + 0.15 * dy
            local hx, hz = dn.px - cx, dn.pz - cz
            local h2 = hx * hx + hz * hz
            if h2 < 9 * rw * rw then
              dn.airy = dn.airy - w0 * (R0 / rw) ^ 2 * math.exp(-h2 / (rw * rw))
            end
          end
        end
      end
    end
  end
end

function V.sound(drones, simTime)
  Sound.update(drones, v:getParam("soundVolume"), v:getParam("soundEmphasis"), simTime)
end
V.soundAvailable = Sound.available

return V
