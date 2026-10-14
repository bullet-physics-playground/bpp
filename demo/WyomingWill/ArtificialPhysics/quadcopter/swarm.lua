--
-- quadcopter/swarm.lua -- Artificial Physics formations flown by quadcopters
--
-- The shared harness behind Formations-Newtonian-Quadcopter.lua and
-- Formations-Lennard-Jones-Quadcopter.lua. Everything about the formation
-- -- the force laws, the square-formation "spin" trick with its sqrt(2)
-- same-spin divisor and the fixed 3D cubic view, goal attraction,
-- obstacle repulsion, friction, the F = m a update, the dimension and
-- formation defaults -- is the code of Formations-Newtonian.lua /
-- Formations-Lennard-Jones.lua, unchanged in meaning. What is new is who
-- the particles are:
--
-- EVERY PARTICLE IS A QUADCOPTER (quadcopter/flight.lua): a 1.5 kg rigid
-- body with four rotors, motor lag, drag and a PX4-style cascaded flight
-- controller, colliding for real with the ground, obstacles and each other.
--
-- ARTIFICIAL PHYSICS PICKS THE WAYPOINTS, as on real physicomimetic robots.
-- At apHz (5 Hz by default) each drone "senses" every other drone's
-- ACTUAL position, the AP force law runs on those positions exactly as in
-- the original files, and the particle's displacement for that tick,
-- dx = timeStep * v, becomes the drone's next waypoint:
--     waypoint = sensed position + dx
-- The flight controller is then handed a straight-line trajectory from
-- where the drone is to that waypoint, arriving at the next AP tick
-- (position setpoint plus velocity feed-forward), and has to fly it --
-- accelerating, tilting up to 35 degrees, fighting wind and the downwash
-- of drones above. Whatever the drone actually achieves is what AP senses
-- next time, so tracking errors, saturation and collisions feed straight
-- back into the formation. AP's own velocity state (v, with friction) is
-- the commanded velocity, as on the robots; AP never teleports anything.
--
-- WHY 5 Hz: with timeStep = 1, AP's commanded speed is (displacement per
-- tick) x apHz. At 10 Hz that is up to ~1.5 m/s with instant reversals,
-- faster than a 1.5 kg quad can follow (it needs ~0.5 m to stop from
-- 2 m/s); squeezing past obstacles then costs collisions, and the
-- Newtonian lattice never sharpens. At 5 Hz the same swarm takes twice as
-- long but flies gently (tilt under ~15 deg) and, in testing, collision-free.
--
-- SCALE. metersPerUnit (default 0.06) maps AP units to metres, so the
-- original rad / desiredSeparation of 50 is a 3 m lattice. AP's x/z become
-- the world's x/z; AP's y is altitude around `altitude` (3D mode), or
-- everyone flies at `altitude` (2D mode). A geofence keeps every waypoint
-- between MIN_ALT and MAX_ALT.
--
-- LIFE CYCLE OF A DRONE:
--   ground   on the launch grid, motors off
--   takeoff  straight up to its starting altitude (sensed by others, not
--            yet driven by AP)
--   ap       flying AP waypoints
--   hold     "disabled" (D): position hold where it is; AP mass 100000,
--            exactly the original's disabled particle
--   landing  "removed" ([): straight down at 1 m/s, still sensed so the
--            drones below get out of the way
--   landed   parked on the ground, motors off
--   crashed  prop strike (touched another drone, an obstacle, or the
--            ground while flying) or tilt failsafe: motors off, it falls,
--            and it is dropped from AP. Falling drones take out whatever
--            they land on. Turn propStrikes off to let hulls just bounce.
-- The formation starts once every drone has reached its takeoff altitude.
--
-- OBSTACLES are real: in 2D a pole from the ground through the formation
-- plane (AP's 2D repulsion disc, extruded), in 3D a sphere. AP repels
-- inside obstacleSize; the solid object is a third of that radius. The
-- margin matters: AP's particles stop dead the moment the repulsion says
-- so, but a drone arriving at ~2 m/s needs about half a metre to brake
-- (35 degree tilt limit plus control lag) -- with only half the radius as
-- margin, drones flew into the poles.
--
-- AIR: wind (steady, along +z) with optional gusts, and a downwash model:
-- each drone's wake is a widening downward jet (centre speed from momentum
-- theory, 2 sqrt(T / 2 rho A), spreading 0.15 m per m below, Gaussian
-- profile) that any drone underneath flies in -- which costs it thrust
-- through the flight model's axial-inflow term. Stacked 3D lattices feel
-- this, as real ones do. Scale it with the `downwash` slider.
--

local common = require "common"
local Quad   = require "quadcopter.flight"

local M = {}

function M.run(cfg)

--------------------------------------------------------------------------
-- timing: a fixed physics/controller rate, several steps per frame
--------------------------------------------------------------------------
local PHYS_HZ = 250
local DT = 1 / PHYS_HZ
local STEPS_PER_FRAME = math.floor(PHYS_HZ / 30 + 0.5)   -- ~1/30 s of flight a frame
common.setTiming(DT, 1, DT)
common.gravity(-9.81)

local SEP = cfg.sepParam            -- "rad" or "desiredSeparation"
local WORLD_WIDTH = 700.0           -- AP units, as in the originals
local MIN_ALT, MAX_ALT = 2.0, 60.0  -- geofence for waypoints (m)
local CLIMB_RATE = 1.5              -- m/s, takeoff
local LAND_RATE = 1.0               -- m/s, landing
local HOLD_MASS = 100000

--------------------------------------------------------------------------
-- GUI parameters: the force law's own (from cfg), then the shared ones
--------------------------------------------------------------------------
local PARAM_INFO = {}
local PARAM_ORDER = {}
local function defParam(name, value, mn, mx, step, comment)
  PARAM_INFO[name] = { min = mn, max = mx, step = step, comment = comment }
  PARAM_ORDER[#PARAM_ORDER + 1] = name
  v:addParam(name, value, mn, mx, step, comment)
end
local function setParam(name, value)
  local info = PARAM_INFO[name]
  value = math.max(info.min, math.min(info.max, value))
  v:addParam(name, value, info.min, info.max, info.step, info.comment)
  return value
end

defParam("numDrones", 50, 1, 100, 1, "drones on the launch grid the next time Setup (R) is pressed")
for _, prm in ipairs(cfg.params) do defParam(prm[1], prm[2], prm[3], prm[4], prm[5], prm[6]) end
defParam("range",        1.5,  1.0, 5.0,  0.1,  "interaction cutoff, as a multiple of " .. SEP)
defParam("friction",     cfg.friction, 0, 1, 0.01, "fraction of AP velocity removed each AP tick")
defParam("timeStep",     1.0,  0.01, 1,   0.01, "AP time per AP tick: waypoint offset = timeStep * v")
defParam("goalForce",    0.25, 0,   1,    0.01, "constant-magnitude attraction toward the goal")
defParam("obstacleSize", 40,   0,   100,  1,    "obstacle repulsion radius (AP units); the solid obstacle is a third of it")
defParam("metersPerUnit", 0.06, 0.02, 0.2, 0.01, "metres per AP unit (0.06: rad 50 = 3 m spacing)")
defParam("apHz",         5,    1,   50,   1,    "AP sensing/waypoint rate (Hz); higher = faster swarm, harder flying")
defParam("altitude",     12,   4,   40,   1,    "formation altitude (m): the 2D plane, or the 3D centre")
defParam("windSpeed",    0,    0,   15,   0.5,  "steady wind along +z (m/s)")
defParam("gust",         0,    0,   5,    0.25, "gust strength, std dev (m/s)")
defParam("downwash",     1,    0,   2,    0.1,  "downwash strength (0 = off, 1 = momentum theory)")
defParam("padSpacing",   3.0,  0.8, 6,    0.1,  "launch grid spacing (m), used by the next Setup (R)")
defParam("simSpeed",     1,    1,   8,    1,    "flight time per rendered frame, in 1/30 s units (fast-forward)")
v:addParam("propStrikes", true, "drones touching another drone, an obstacle, or the ground in flight lose their props and fall")

local function readParams()
  local p = {}
  for _, n in ipairs(PARAM_ORDER) do p[n] = v:getParam(n) end
  p.sep = p[SEP]
  return p
end

--------------------------------------------------------------------------
-- colours
--------------------------------------------------------------------------
local COL_WHITE, COL_YELLOW, COL_VIOLET = "#ffffff", "#ffff00", "#8a2be2"
local COL_CRASHED, COL_LANDED = "#ff2020", "#707070"
local COL_GOAL, COL_OBS, COL_COM, COL_CURSOR = "#87ceeb", "#00c000", "#ff0000", "#ff8800"
local COL_AXIS_X, COL_AXIS_Y, COL_AXIS_Z = "#ff4444", "#44ff44", "#4488ff"
local COL_LINE, COL_WP = "#9a9a9a", "#00ffff"

--------------------------------------------------------------------------
-- scene objects that never collide (markers, lines): out of every
-- collision group so Bullet never pairs them with anything
--------------------------------------------------------------------------
local function ghost(obj, col)
  obj.col = col
  obj.collides = false
  v:add(obj)
  return obj
end
local function ghostCylinder(x1, y1, z1, x2, y2, z2, radius, col)
  local rot, len, mid = common.orientBetween(btVector3(x1, y1, z1), btVector3(x2, y2, z2))
  if len < 1e-6 then return nil end
  local cy = Cylinder(radius, len, 0)
  cy.trans = btTransform(rot, mid)
  return ghost(cy, col)
end

local ground = Plane(0, 1, 0, 0, 120)
ground.col = "#2c3a2c"
v:add(ground)

--------------------------------------------------------------------------
-- state
--------------------------------------------------------------------------
local drones = {}       -- each: Quad fields + id, state, spin, ax/ay/az, avx.., trajectory
local goals = {}        -- AP entities (x,y,z in AP units)
local obstacles = {}
local nextId = 0
local isSquareFormation, isGoalEnabled, is3D = false, false, cfg.start3D ~= false
local apEngaged = false
local simTime, nextApTime, nextAirTime = 0, 0, 0
local gustX, gustZ = 0, 0
local stats = { contacts = 0, satSteps = 0, steps = 0, maxTilt = 0, trackSum = 0, trackN = 0 }
local objToDrone = {}   -- frame object -> drone (for contact lookups)
local obstacleObjs = {} -- solid obstacle objects

local function S() return v:getParam("metersPerUnit") end
local function ALT() return v:getParam("altitude") end

-- AP units <-> world metres
local function toWorld(ax, ay, az)
  local s = S()
  return ax * s, ALT() + ay * s, az * s
end
local function toAP(x, y, z)
  local s = S()
  return x / s, is3D and (y - ALT()) / s or 0, z / s
end

local function droneColor(d)
  if d.state == "crashed" then return COL_CRASHED end
  if d.state == "landed" then return COL_LANDED end
  if d.state == "hold" then return COL_VIOLET end
  return (d.id % 2 == 0) and COL_WHITE or COL_YELLOW
end
local function setState(d, s)
  d.state = s
  Quad.setColor(d, droneColor(d))
end

local function sensed(d)    -- airborne and visible to the other drones' AP
  local s = d.state
  return s == "ap" or s == "hold" or s == "landing" or s == "takeoff"
end

--------------------------------------------------------------------------
-- markers: centre of mass, goal, cursor
--------------------------------------------------------------------------
local comMarker = ghost(Sphere(0.15, 0), COL_COM)

local CURSOR_STEP, CURSOR_TICK = 15, 10      -- AP units, as in the originals
local cursorX, cursorY, cursorZ = 0.0, 0.0, 0.0
local cursorObjs = {}
local function drawCursor()
  for _, o in ipairs(cursorObjs) do v:remove(o) end
  cursorObjs = {}
  local x, y, z = toWorld(cursorX, cursorY, cursorZ)
  local t = CURSOR_TICK * S()
  cursorObjs[1] = ghost(Sphere(0.12, 0), COL_CURSOR); cursorObjs[1].pos = btVector3(x, y, z)
  cursorObjs[#cursorObjs + 1] = ghostCylinder(x, y, z, x + t, y, z, 0.02, COL_AXIS_X)
  if is3D then cursorObjs[#cursorObjs + 1] = ghostCylinder(x, y, z, x, y + t, z, 0.02, COL_AXIS_Y) end
  cursorObjs[#cursorObjs + 1] = ghostCylinder(x, y, z, x, y, z + t, 0.02, COL_AXIS_Z)
end
local function moveCursor(dx, dy, dz)
  cursorX = cursorX + dx
  cursorY = is3D and (cursorY + dy) or 0
  cursorZ = cursorZ + dz
  drawCursor()
end

--------------------------------------------------------------------------
-- obstacles: an AP entity plus a solid pole (2D) or sphere (3D)
--------------------------------------------------------------------------
local function buildObstacleObj(obs)
  if obs.obj then v:remove(obs.obj); obstacleObjs[obs.obj] = nil end
  local r = math.max(0.05, v:getParam("obstacleSize") * S() / 3)
  local x, y, z = toWorld(obs.x, obs.y, obs.z)
  local o
  if is3D then
    o = Sphere(r, 0)
    o.pos = btVector3(x, y, z)
  else
    local h = ALT() + 6
    o = Cylinder(r, h, 0)
    o.trans = btTransform(btQuaternion(btVector3(1, 0, 0), math.pi / 2), btVector3(x, h / 2, z))  -- local z -> up
  end
  o.col = COL_OBS
  v:add(o)
  obs.obj = o
  obstacleObjs[o] = true
end

function addObstacleAt(x, y, z)
  if not is3D then y = 0 end
  local obs = { x = x, y = y, z = z, mass = HOLD_MASS }
  obstacles[#obstacles + 1] = obs
  buildObstacleObj(obs)
end

function clearObstacles()
  for _, o in ipairs(obstacles) do v:remove(o.obj) end
  obstacles = {}
  obstacleObjs = {}
end

--------------------------------------------------------------------------
-- the square-formation "spin" machinery, verbatim from the originals
--------------------------------------------------------------------------
local CUBIC_VIEW_3D = 1.3

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
  local view, modifiedR = p.range, r
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
-- one AP tick: sense, compute forces, update AP velocity, issue waypoints
--------------------------------------------------------------------------
local function apTick(p)
  local s = p.metersPerUnit
  local T = 1 / p.apHz

  -- sense: every airborne drone's actual position, in AP units
  local seen = {}
  for _, d in ipairs(drones) do
    if sensed(d) then
      d.ax, d.ay, d.az = toAP(d.px, d.py, d.pz)
      d.apMass = (d.state == "hold") and HOLD_MASS or 1
      seen[#seen + 1] = d
    end
  end

  local divisor, sameView, diffView = squareFormationParams(p)
  for _, d in ipairs(seen) do
    if d.state == "ap" then
      local fx, fy, fz = 0, 0, 0
      d.avx, d.avy, d.avz = d.avx * (1 - p.friction), d.avy * (1 - p.friction), d.avz * (1 - p.friction)

      for _, o in ipairs(seen) do
        if o ~= d then
          local dx, dy, dz = o.ax - d.ax, o.ay - d.ay, o.az - d.az
          local r = math.sqrt(dx * dx + dy * dy + dz * dz)
          if r < 0.1 then r = 0.1 end
          local view, modifiedR = neighborViewAndR(d.id, o.id, r, p, divisor, sameView, diffView)
          if modifiedR < view * p.sep then
            local f = cfg.force(modifiedR, p, d.apMass, o.apMass)   -- > 0 repels
            fx, fy, fz = fx - f * dx / r, fy - f * dy / r, fz - f * dz / r
          end
        end
      end

      for _, obs in ipairs(obstacles) do
        local dx, dy, dz = obs.x - d.ax, obs.y - d.ay, obs.z - d.az
        local r = math.sqrt(dx * dx + dy * dy + dz * dz)
        if r <= p.obstacleSize and r > 0 then
          local f = p.obstacleSize - r
          fx, fy, fz = fx - f * dx / r, fy - f * dy / r, fz - f * dz / r
        end
      end

      if isGoalEnabled then
        for _, g in ipairs(goals) do
          local dx, dy, dz = g.x - d.ax, g.y - d.ay, g.z - d.az
          local r = math.sqrt(dx * dx + dy * dy + dz * dz)
          if r > 0.1 then
            fx, fy, fz = fx + p.goalForce * dx / r, fy + p.goalForce * dy / r, fz + p.goalForce * dz / r
          end
        end
      end

      if not is3D then fy = 0 end
      d.avx = d.avx + p.timeStep * fx / d.apMass
      d.avy = d.avy + p.timeStep * fy / d.apMass
      d.avz = d.avz + p.timeStep * fz / d.apMass

      -- the waypoint: sensed position + this tick's AP displacement
      local wx, wy, wz = toWorld(d.ax + p.timeStep * d.avx, d.ay + p.timeStep * d.avy, d.az + p.timeStep * d.avz)
      if wy < MIN_ALT then wy = MIN_ALT elseif wy > MAX_ALT then wy = MAX_ALT end
      d.wpx, d.wpy, d.wpz = wx, wy, wz
      -- straight-line trajectory from here to there, arriving next tick
      d.t0, d.trT = simTime, T
      d.sx, d.sy, d.sz = d.px, d.py, d.pz
      d.vfx, d.vfy, d.vfz = (wx - d.px) / T, (wy - d.py) / T, (wz - d.pz) / T

      -- tracking error: how far the drone was from where it was told to be
      if d.lastSpx then
        local ex, ey, ez = d.px - d.lastSpx, d.py - d.lastSpy, d.pz - d.lastSpz
        stats.trackSum = stats.trackSum + math.sqrt(ex * ex + ey * ey + ez * ez)
        stats.trackN = stats.trackN + 1
      end
      d.lastSpx, d.lastSpy, d.lastSpz = wx, wy, wz
    end
  end

  -- the goal drifts toward the swarm, as in the originals (mass 100000)
  if isGoalEnabled then
    for _, g in ipairs(goals) do
      g.vx, g.vy, g.vz = g.vx * (1 - p.friction), g.vy * (1 - p.friction), g.vz * (1 - p.friction)
      local fx, fy, fz = 0, 0, 0
      for _, d in ipairs(seen) do
        local dx, dy, dz = d.ax - g.x, d.ay - g.y, d.az - g.z
        local r = math.sqrt(dx * dx + dy * dy + dz * dz)
        if r > 0.1 then fx, fy, fz = fx + p.goalForce * dx / r, fy + p.goalForce * dy / r, fz + p.goalForce * dz / r end
      end
      g.vx, g.vy, g.vz = g.vx + p.timeStep * fx / g.mass, g.vy + p.timeStep * fy / g.mass, g.vz + p.timeStep * fz / g.mass
      g.x, g.y, g.z = g.x + p.timeStep * g.vx, g.y + p.timeStep * g.vy, g.z + p.timeStep * g.vz
    end
  end
end

--------------------------------------------------------------------------
-- air: wind + gusts + downwash, refreshed at 50 Hz
--------------------------------------------------------------------------
local function airTick(p, dtAir)
  -- gusts: an Ornstein-Uhlenbeck process (2 s correlation), shared by all
  local a = math.exp(-dtAir / 2.0)
  local sg = p.gust * math.sqrt(1 - a * a)
  local function gauss() return math.sqrt(-2 * math.log(math.random() + 1e-12)) * math.cos(2 * math.pi * math.random()) end
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

--------------------------------------------------------------------------
-- per-drone mission logic, every physics step
--------------------------------------------------------------------------
local function guide(d)
  local st = d.state
  if d.failed and st ~= "crashed" then setState(d, "crashed"); st = "crashed" end

  if st == "takeoff" then
    d.holdVertI = d.py < 0.3
    if d.spy < d.toAlt then
      d.spy = math.min(d.toAlt, d.spy + CLIMB_RATE * DT)
      d.vfy = CLIMB_RATE
    else
      d.vfy = 0
      d.climbed = math.abs(d.py - d.toAlt) < 0.3 and math.abs(d.vy) < 0.3
      if d.climbed and apEngaged then
        setState(d, "ap")
        d.avx, d.avy, d.avz = 0, 0, 0
        d.wpx, d.wpy, d.wpz = d.px, d.py, d.pz
        d.t0, d.trT, d.sx, d.sy, d.sz = simTime, 1e9, d.px, d.py, d.pz
        d.vfx, d.vfy, d.vfz = 0, 0, 0
      end
    end
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
    d.spy = math.max(Quad.GROUND_Y - 0.2, d.spy - LAND_RATE * DT)
    d.vfy = (d.spy > Quad.GROUND_Y) and -LAND_RATE or 0
    if d.py < Quad.GROUND_Y + 0.05 and math.abs(d.vy) < 0.2 then
      d.armed = false
      setState(d, "landed")
    end
  end
end

local function physicsStep(p)
  -- AP and air on their own clocks
  if apEngaged and simTime >= nextApTime then
    apTick(p)
    nextApTime = simTime + 1 / p.apHz
  end
  if simTime >= nextAirTime then
    airTick(p, 0.02)
    nextAirTime = simTime + 0.02
  end

  for _, d in ipairs(drones) do
    guide(d)
    Quad.step(d, DT)
    if d.armed and d.py > 0.5 then
      if d.tilt > stats.maxTilt then stats.maxTilt = d.tilt end
      if d.saturated then stats.satSteps = stats.satSteps + 1 end
      stats.steps = stats.steps + 1
    end
  end
  simTime = simTime + DT

  -- start AP once every drone that took off has reached its altitude
  if not apEngaged then
    local all, any = true, false
    for _, d in ipairs(drones) do
      if d.state == "takeoff" then any = true; if not d.climbed then all = false end end
    end
    if any and all then
      apEngaged = true
      nextApTime = simTime
      print(string.format("t=%.1f s: all drones at altitude -- Artificial Physics engaged", simTime))
    end
  end
end

--------------------------------------------------------------------------
-- launching drones
--------------------------------------------------------------------------
local function launch(x, z, toAlt)
  local d = Quad.new(x, Quad.GROUND_Y, z)
  d.id = nextId; nextId = nextId + 1
  d.toAlt = toAlt
  d.avx, d.avy, d.avz = 0, 0, 0
  d.ax, d.ay, d.az = toAP(x, toAlt, z)
  d.armed = true
  d.spx, d.spy, d.spz = x, Quad.GROUND_Y, z
  setState(d, "takeoff")
  drones[#drones + 1] = d
  objToDrone[d.obj] = d
  return d
end

function setup(n)
  for _, d in ipairs(drones) do Quad.remove(d) end
  for _, g in ipairs(goals) do v:remove(g.obj) end
  clearObstacles()
  clearNeighborLines()
  clearWaypointMarkers()
  drones, goals = {}, {}
  objToDrone = {}
  nextId = 0
  apEngaged = false
  stats = { contacts = 0, satSteps = 0, steps = 0, maxTilt = 0, trackSum = 0, trackN = 0 }

  -- launch grid, centred under the originals' starting cluster (x = WORLD_WIDTH/3)
  local s = S()
  local cx = WORLD_WIDTH / 3 * s
  local LAUNCH_SPACING = v:getParam("padSpacing")
  local cols = math.ceil(math.sqrt(n))
  local rows = math.ceil(n / cols)
  local jitter = 2 * v:getParam(SEP) * s          -- the originals' scatter width
  for i = 0, n - 1 do
    local c, r = i % cols, math.floor(i / cols)
    local x = cx + (c - (cols - 1) / 2) * LAUNCH_SPACING + (math.random() - 0.5) * 0.3
    local z = (r - (rows - 1) / 2) * LAUNCH_SPACING + (math.random() - 0.5) * 0.3
    local alt = ALT()
    if is3D then alt = alt + (math.random() - 0.5) * jitter end
    launch(x, z, math.max(MIN_ALT, alt))
  end

  local goal = { x = -WORLD_WIDTH / 3, y = 0, z = 0, vx = 0, vy = 0, vz = 0, mass = HOLD_MASS }
  goal.obj = ghost(Sphere(0.4, 0), COL_GOAL)
  goals[1] = goal
  print(string.format("setup: %d drones on the launch grid (%s)", n, is3D and "3D" or "2D"))
end

--------------------------------------------------------------------------
-- neighbour lines and waypoint markers (drawn at actual drone positions)
--------------------------------------------------------------------------
local showNeighborLines, showWaypoints = true, false
local MAX_NEIGHBOR_LINES_PER_PARTICLE = 12
local neighborLineObjs, wpObjs = {}, {}

function clearNeighborLines()
  for _, o in ipairs(neighborLineObjs) do v:remove(o) end
  neighborLineObjs = {}
end
function clearWaypointMarkers()
  for _, o in ipairs(wpObjs) do v:remove(o) end
  wpObjs = {}
end

local function updateNeighborLines(p)
  clearNeighborLines()
  if not showNeighborLines then return end
  local cutoff = ((is3D and isSquareFormation) and CUBIC_VIEW_3D or p.range) * p.sep * p.metersPerUnit
  for i, a in ipairs(drones) do
    if a.state == "ap" or a.state == "hold" then
      local count = 0
      for j = i + 1, #drones do
        local b = drones[j]
        if count < MAX_NEIGHBOR_LINES_PER_PARTICLE and (b.state == "ap" or b.state == "hold")
           and (not isSquareFormation or (a.id % 2) ~= (b.id % 2)) then
          local dx, dy, dz = b.px - a.px, b.py - a.py, b.pz - a.pz
          if dx * dx + dy * dy + dz * dz < cutoff * cutoff then
            local cy = ghostCylinder(a.px, a.py, a.pz, b.px, b.py, b.pz, 0.015, COL_LINE)
            if cy then neighborLineObjs[#neighborLineObjs + 1] = cy; count = count + 1 end
          end
        end
      end
    end
  end
end

local function updateWaypointMarkers()
  if not showWaypoints then
    if #wpObjs > 0 then clearWaypointMarkers() end
    return
  end
  local k = 0
  for _, d in ipairs(drones) do
    if d.state == "ap" and d.wpx then
      k = k + 1
      if not wpObjs[k] then wpObjs[k] = ghost(Sphere(0.06, 0), COL_WP) end
      wpObjs[k].pos = btVector3(d.wpx, d.wpy, d.wpz)
    end
  end
  for i = #wpObjs, k + 1, -1 do v:remove(wpObjs[i]); wpObjs[i] = nil end
end

--------------------------------------------------------------------------
-- camera: follows the swarm (T toggles), P cycles the view
--------------------------------------------------------------------------
local followCam = true
local camMode = 1            -- 1 overview, 2 top-down, 3 close-up on one drone
local camTarget = nil
local camX, camY, camZ = WORLD_WIDTH / 3 * 0.06, 6, 0

local function centroid()
  local n, x, y, z = 0, 0, 0, 0
  for _, d in ipairs(drones) do
    if d.state ~= "crashed" and d.state ~= "landed" then n = n + 1; x, y, z = x + d.px, y + d.py, z + d.pz end
  end
  if n == 0 then return nil end
  return x / n, y / n, z / n
end

function updateCamera()
  if not followCam then return end
  if camMode == 3 then
    if not camTarget or camTarget.state == "crashed" or camTarget.state == "landed" then
      camTarget = nil
      for _, d in ipairs(drones) do if d.state == "ap" or d.state == "takeoff" then camTarget = d; break end end
    end
    if camTarget then
      local d = camTarget
      common.setCamera(btVector3(d.px - 2.2, d.py + 1.2, d.pz + 2.2), btVector3(d.px, d.py, d.pz), 0.9)
      return
    end
  end
  local x, y, z = centroid()
  if not x then return end
  local a = 0.08                                  -- smoothing
  camX, camY, camZ = camX + (x - camX) * a, camY + (y - camY) * a, camZ + (z - camZ) * a
  if camMode == 2 then
    common.setCamera(btVector3(camX, camY + 70, camZ), btVector3(camX, camY, camZ), 0.6,
                     { up = btVector3(0, 0, -1) })
  elseif is3D then
    common.setCamera(btVector3(camX + 22, camY + 15, camZ + 22), btVector3(camX, camY, camZ), 0.8)
  else
    common.setCamera(btVector3(camX + 4, camY + 26, camZ + 24), btVector3(camX, camY, camZ), 0.8)
  end
end

--------------------------------------------------------------------------
-- actions (global, so they can also be typed into the command line)
--------------------------------------------------------------------------
local function applyDefaults()
  if not cfg.defaultsByMode then return end
  local key = (is3D and "3D" or "2D") .. (isSquareFormation and "Square" or "Triangle")
  local dflt = cfg.defaultsByMode[key]
  for k, val in pairs(dflt) do setParam(k, val) end
  print("defaults (" .. key .. ") applied")
end

function toggleFormation()
  isSquareFormation = not isSquareFormation
  applyDefaults()
  print("square formation = " .. tostring(isSquareFormation))
end

function toggleGoal()
  isGoalEnabled = not isGoalEnabled
  print("goal enabled = " .. tostring(isGoalEnabled))
end

function setDimension(want3D)
  is3D = want3D
  cursorY = is3D and cursorY or 0
  applyDefaults()
  setup(math.floor(v:getParam("numDrones")))
  drawCursor()
  print("dimension = " .. (is3D and "3D" or "2D"))
end

local function pick(filter)
  local c = {}
  for _, d in ipairs(drones) do if filter(d) then c[#c + 1] = d end end
  if #c == 0 then return nil end
  return c[math.random(#c)]
end

-- ]: launch one more drone from the ground under a random flying one
function addDrone()
  local t = pick(function(d) return d.state == "ap" end)
  if not t then return end
  local sep = v:getParam(SEP) * S()
  local x = t.px + (math.random() - 0.5) * sep
  local z = t.pz + (math.random() - 0.5) * sep
  for _, d in ipairs(drones) do       -- keep clear of anything parked there
    if d.py < 1 and (d.px - x) ^ 2 + (d.pz - z) ^ 2 < 1 then x = x + 1.2 end
  end
  launch(x, z, math.max(MIN_ALT, t.py))
  print("launched drone " .. (nextId - 1))
end

-- [: one drone leaves the formation and lands
function removeDrone()
  local n = 0
  for _, d in ipairs(drones) do if d.state == "ap" then n = n + 1 end end
  if n <= 1 then return end
  local d = pick(function(x) return x.state == "ap" end)
  d.spx, d.spy, d.spz = d.px, d.py, d.pz
  setState(d, "landing")
  print("drone " .. d.id .. " landing")
end

-- D: a drone stops following AP and holds position (the original's disable)
function disableDrone()
  local d = pick(function(x) return x.state == "ap" end)
  if not d then return end
  d.spx, d.spy, d.spz, d.vfx, d.vfy, d.vfz = d.px, d.py, d.pz, 0, 0, 0
  setState(d, "hold")
  print("drone " .. d.id .. " disabled (holding position)")
end

--------------------------------------------------------------------------
-- keys
--------------------------------------------------------------------------
v:addShortcut("R", function() setup(math.floor(v:getParam("numDrones"))) end)
v:addShortcut("2", function() setDimension(false) end)
v:addShortcut("3", function() setDimension(true) end)
v:addShortcut("]", function() addDrone() end)
v:addShortcut("[", function() removeDrone() end)
v:addShortcut("D", function() disableDrone() end)
v:addShortcut("F", function() toggleFormation() end)
v:addShortcut("G", function() toggleGoal() end)
v:addShortcut("C", function() clearObstacles() end)
v:addShortcut("O", function() addObstacleAt(cursorX, cursorY, cursorZ) end)
v:addShortcut("V", function()
  showNeighborLines = not showNeighborLines
  if not showNeighborLines then clearNeighborLines() end
  print("neighbor lines = " .. tostring(showNeighborLines))
end)
v:addShortcut("W", function() showWaypoints = not showWaypoints; print("waypoints = " .. tostring(showWaypoints)) end)
v:addShortcut("T", function() followCam = not followCam; print("follow camera = " .. tostring(followCam)) end)
v:addShortcut("P", function()
  camMode = camMode % 3 + 1; camTarget = nil; followCam = true
  print("camera: " .. ({ "overview", "top-down", "close-up" })[camMode])
end)
v:addShortcut("Left",  function() moveCursor(-CURSOR_STEP, 0, 0) end)
v:addShortcut("Right", function() moveCursor(CURSOR_STEP, 0, 0) end)
v:addShortcut("Up",    function() moveCursor(0, 0, -CURSOR_STEP) end)
v:addShortcut("Down",  function() moveCursor(0, 0, CURSOR_STEP) end)
v:addShortcut("J", function() moveCursor(-CURSOR_STEP, 0, 0) end)
v:addShortcut("L", function() moveCursor(CURSOR_STEP, 0, 0) end)
v:addShortcut("I", function() moveCursor(0, 0, -CURSOR_STEP) end)
v:addShortcut("K", function() moveCursor(0, 0, CURSOR_STEP) end)
v:addShortcut("Y", function() moveCursor(0, CURSOR_STEP, 0) end)
v:addShortcut("H", function() moveCursor(0, -CURSOR_STEP, 0) end)
v:addShortcut("=", function() print("simSpeed = " .. setParam("simSpeed", v:getParam("simSpeed") + 1)) end)
v:addShortcut("-", function() print("simSpeed = " .. setParam("simSpeed", v:getParam("simSpeed") - 1)) end)

v:onCommand(function(N, cmd)
  local f = assert(loadstring(cmd))
  f(v)
end)

-- obstacle size / scale / altitude changes rebuild the solid obstacles
local lastObsKey = ""
local function obstacleKey() return v:getParam("obstacleSize") .. "/" .. S() .. "/" .. ALT() end

--------------------------------------------------------------------------
-- prop strikes, from Bullet's own contact points (once a frame)
--------------------------------------------------------------------------
local function inFlight(d) return d.state == "ap" or d.state == "hold" end

local function strike(d, why)
  if not d.armed then return end          -- already down, or parked
  d.armed, d.failed = false, true
  setState(d, "crashed")
  print(string.format("t=%.1f s: drone %d down -- %s", simTime, d.id, why))
end

local touching = {}
local function checkContacts(strikesOn)
  local now = {}
  v:eachContact(function(a, b, x, y, z, nx, ny, nz, dist)
    if dist > 0.005 then return end
    local da, db = objToDrone[a], objToDrone[b]
    if da and db then
      local key = math.min(da.id, db.id) * 100000 + math.max(da.id, db.id)
      if not now[key] then
        now[key] = true
        if not touching[key] then stats.contacts = stats.contacts + 1 end
        if strikesOn then
          strike(da, "collided with drone " .. db.id)
          strike(db, "collided with drone " .. da.id)
        end
      end
    elseif da or db then
      local d, other = da or db, da and b or a
      if strikesOn and obstacleObjs[other] then strike(d, "hit an obstacle")
      elseif strikesOn and other == ground and inFlight(d) then strike(d, "hit the ground") end
    end
  end)
  touching = now
end

--------------------------------------------------------------------------
-- formation statistics (printed about once a second of flight)
--------------------------------------------------------------------------
local function formationStats(p)
  local sepM = p.sep * p.metersPerUnit
  local bonds, sum, sq = 0, 0, 0
  local nb6, flying, n = 0, 0, {}
  local counts = { ap = 0, hold = 0, takeoff = 0, landing = 0, landed = 0, crashed = 0, ground = 0 }
  local speed = 0
  for _, d in ipairs(drones) do
    counts[d.state] = (counts[d.state] or 0) + 1
    if d.state == "ap" or d.state == "hold" then
      flying = flying + 1
      speed = speed + math.sqrt(d.vx * d.vx + d.vy * d.vy + d.vz * d.vz)
    end
  end
  for i, a in ipairs(drones) do
    if a.state == "ap" or a.state == "hold" then
      local c = 0
      for j, b in ipairs(drones) do
        if i ~= j and (b.state == "ap" or b.state == "hold") then
          local dx, dy, dz = a.px - b.px, a.py - b.py, a.pz - b.pz
          local r = math.sqrt(dx * dx + dy * dy + dz * dz)
          if r < 1.2 * sepM then
            c = c + 1
            if j > i then bonds = bonds + 1; sum = sum + r / sepM; sq = sq + (r / sepM) ^ 2 end
          end
        end
      end
      if c == 6 then nb6 = nb6 + 1 end
    end
  end
  local mean = bonds > 0 and sum / bonds or 0
  local sd = bonds > 0 and math.sqrt(math.max(0, sq / bonds - mean * mean)) or 0
  return string.format(
    "t=%6.1fs ap=%d hold=%d takeoff=%d landing=%d landed=%d crashed=%d | bonds=%d len=%.3fR sd=%.3fR six-nb=%d | speed=%.2fm/s track=%.2fm tilt<=%.0fdeg sat=%.1f%% contacts=%d",
    simTime, counts.ap, counts.hold, counts.takeoff, counts.landing, counts.landed, counts.crashed,
    bonds, mean, sd, nb6, flying > 0 and speed / flying or 0,
    stats.trackN > 0 and stats.trackSum / stats.trackN or 0, math.deg(stats.maxTilt),
    stats.steps > 0 and 100 * stats.satSteps / stats.steps or 0, stats.contacts)
end

--------------------------------------------------------------------------
-- the frame: STEPS_PER_FRAME x simSpeed physics steps, the last of which
-- is the viewer's own step
--------------------------------------------------------------------------
local nextStats = 1.0
local frameCount = 0

v:preSim(function(N)
  local p = readParams()
  local k = STEPS_PER_FRAME * math.max(1, math.floor(p.simSpeed))
  for _ = 1, k - 1 do
    physicsStep(p)
    v:stepSimulation(DT, 1, DT)
  end
  physicsStep(p)
end)

v:postSim(function(N)
  local p = readParams()
  frameCount = frameCount + 1
  for _, d in ipairs(drones) do Quad.sync(d) end
  checkContacts(v:getParam("propStrikes"))

  local key = obstacleKey()
  if key ~= lastObsKey then
    lastObsKey = key
    for _, o in ipairs(obstacles) do buildObstacleObj(o) end
  end
  for _, g in ipairs(goals) do
    local x, y, z = toWorld(g.x, g.y, g.z)
    g.obj.pos = btVector3(x, y, z)
  end
  local cx, cy, cz = centroid()
  if cx then comMarker.pos = btVector3(cx, cy, cz) end

  if frameCount % 3 == 0 then updateNeighborLines(p) end
  updateWaypointMarkers()
  updateCamera()

  if simTime >= nextStats then
    nextStats = simTime + 1.0
    print(formationStats(p))
    stats.maxTilt, stats.satSteps, stats.steps, stats.trackSum, stats.trackN = 0, 0, 0, 0, 0
  end
end)

v:preStart(function(N)
  print(cfg.title .. " -- S: start/stop  R: setup  2/3: dimension  ]/[: launch/land  D: hold  F: formation")
  print("  G: goal  C: clear  cursor: arrows/IJKL Y/H  O: obstacle  V: lines  W: waypoints  T/P: camera  =/-: speed")
end)

local HELP_TEXT = cfg.title .. [[


S        start/stop the simulation
R        Setup: new drones on the launch grid
2 / 3    2D / 3D formation (re-launches)

]        launch one more drone
[        a drone leaves and lands
D        a drone stops and holds position
F        toggle square formation
G        toggle goal attraction
C        clear all obstacles

Cursor (for placing obstacles):
  Left/Right or J/L   move along x
  Up/Down    or I/K   move along z
  Y / H               move along y (3D only)
  O                   drop an obstacle here

V        neighbour lines
W        waypoint markers
T        follow camera on/off
P        camera: overview / top-down / close-up
= / -    faster / slower (simSpeed)

Colours: white/yellow = spin 0/1, violet = holding,
red = crashed, grey = landed.]]
pcall(function() v:setHelpText(HELP_TEXT) end)

math.randomseed(cfg.seed or os.time())
applyDefaults()
setup(math.floor(v:getParam("numDrones")))
drawCursor()
updateCamera()

-- for scripted (command-line) runs
M.state = function() return { drones = drones, simTime = simTime, apEngaged = apEngaged } end
M.formationStats = function() return formationStats(readParams()) end

end -- M.run

return M
