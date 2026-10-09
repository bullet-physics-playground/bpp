--
-- Gomboc Drop, version C: as realistic as we can make it
--
-- A gomboc (Gömböc) is a convex body of uniform density with exactly one
-- stable and one unstable resting point: set it down any way you like and
-- it rocks and rolls back to the same upright pose. This table drops a
-- handful of them at random orientations and races them: the console says
-- when each one is upright and when it has come completely to rest.
--
-- Scene, colours, race and sliders come from version B ("Gomboc Drop").
-- What is different is the shape and the physics, chosen to be realistic
-- rather than tuned:
--
-- SHAPE -- the GOMBOC900 SolidWorks CAD model (Kiss Attila, 2013), scaled to
--   9 cm. Its exact surfaces were checked to have one stable and one
--   unstable equilibrium. The physics shape is the convex hull of a fine
--   tessellation of those surfaces (13,476 points, all on the true surface);
--   its flat facets add tiny extra resting faces, but all lie within 16 deg
--   of the true resting point and the deepest needs only a 0.53 micron lift
--   to leave. No hand correction is needed. (Version B's printable STL
--   differs from this shape by up to 2.2 mm; even after B's corrections its
--   hull keeps 27 resting faces deeper than 5 microns, some 50-115 deg from
--   upright.) Centre of mass and inertia are the exact CAD values.
--
-- ENERGY LOSS -- a real gomboc loses energy at the table, not in the air:
--   * rolling resistance: a constant moment  M = delta * m * g  opposing the
--     rolling, at the contact, whenever the gomboc is on the table (any tilt).
--     delta is the rolling-resistance lever arm (slider, microns). A constant
--     moment, unlike speed-proportional damping, brings motion to a complete
--     stop in finite time -- as real rolling resistance does.
--   * spin friction: a constant moment opposing spinning about the vertical.
--   * air drag: Bullet's velocity damping, default 0 (real air drag on a
--     9 cm gomboc is hundreds of times smaller than any useful setting).
--   Both moments are applied before EVERY physics step (this script steps
--   the world itself, see stepWorld), not once per frame.
--
-- NO TAPS by default: nothing pushes a gomboc home. (Version B's taps are
-- available with the "taps" slider, for comparison.)
--
-- Timestep: a gomboc's resting valley is so flat that small errors in each
-- contact step can feed it energy (see demo/mesh/gomboc-test.lua). The
-- "steps" slider sets physics steps per simulated second. At 1200 (the
-- default), with every loss switched off, a lone gomboc's energy stays
-- level, with no steady gain, so the losses above are what bring it to rest.
-- 2400 was no better.
--
-- What to expect (defaults, 6 gombocs; tested with 3 drops + 2 headstands):
--   * all upright within about 15 s, all at rest within 16-22 s;
--   * they stop 0.3-7 deg short of exactly upright. That is real: a
--     constant rolling-resistance moment holds a gomboc wherever gravity's
--     pull home is weaker than it, and this gomboc's resting valley is so
--     flat that gravity's pull stays tiny for several degrees. More
--     "rolling" = quicker to stop, further from exactly upright;
--   * gombocs that roll into each other can stay propped together for a
--     long time, as real ones do (the console says "touching ...");
--   * at rest, the contact solver still lets one creep by up to ~0.3 deg
--     and ~0.7 mm per minute -- invisible, but it is there.
--
-- Units are centimetres, kilograms and seconds.
--
-- Re-drop: once a gomboc has been at rest for `redrop` seconds (slider,
-- default 5; 0 = off), it is lifted away and a new one of the same colour
-- is dropped in its place, so the table keeps going. The console reports
-- each gomboc's times from its own drop, and a tally every minute.
--
-- Keys
--   R   drop them all again, at random orientations
--   U   stand them all on their heads (the unstable point) and let go
--   K   kick: toss them all up with a spin
--   ]   one more gomboc (and drop)      [   one fewer
--
-- Sliders: count, speed, steps, friction, restitution, rolling (microns),
--          spin friction, air drag, taps, redrop.
--
-- Speed: the physics is the cost (the 13,476-point hull, 1200 steps/s);
-- on a 2.1 GHz server core six gombocs run at about 1/5 of real time
-- without graphics. Lowering "steps" to 600 halves the cost; with every
-- loss off, 600 also showed no steady energy gain. Thinning the hull
-- instead would bring back deep false resting spots (tested: at 1.4 mm
-- spacing, 6 deeper than 1 micron, some up to 103 deg from upright).
--
-- For headless testing (bpp -f ... -n FRAMES), environment variables set
-- the starting values: GC_SEED, GC_COUNT, GC_STEPS, GC_ROLL, GC_SPIN,
-- GC_DRAG, GC_REST, GC_TAPS, GC_REDROP, GC_CPT, GC_START=headstand, and GC_LOG=file.csv
-- logs every gomboc twice a second.
--

local common = require "common"

-- ---------------------------------------------------------------------
-- the gomboc's hull and mass properties
-- ---------------------------------------------------------------------

local MESH_DIR = "gomboc-meshes/"

local function loadHull()
  local tried = {}
  for _, dir in ipairs({ MESH_DIR, "demo/gomboc/" .. MESH_DIR, "demo/WyomingWill/Gomboc-C/" .. MESH_DIR }) do
    local ok, data = pcall(dofile, dir .. "gomboc-hull.lua")
    if ok and data then MESH_DIR = dir; return data end
    tried[#tried + 1] = dir
  end
  error("gomboc-hull.lua not found in " .. table.concat(tried, ", "))
end
local HULL = loadHull()

local G = 981                             -- cm/s^2
local DENSITY = 0.0012                    -- kg/cm^3: a resin print, 1.2 g/cm^3
local MASS = HULL.volume * DENSITY        -- about 0.32 kg
local K2 = HULL.inertia                   -- squared radii of gyration, cm^2
local INERTIA = btVector3(K2[1] * MASS, K2[2] * MASS, K2[3] * MASS)
local MARGIN = 0.04                       -- cm

-- one hull shape, shared by every gomboc (Bullet allows sharing shapes)
local HULL_SHAPE = btConvexHullShape()
do
  local p = HULL.points
  for i = 1, #p, 3 do
    HULL_SHAPE:addPoint(btVector3(p[i], p[i + 1], p[i + 2]), false)
  end
  HULL_SHAPE:recalcLocalAabb()
  -- (the margin grows the hull evenly all round, which lifts every resting
  -- height by the same amount -- so it can't add or remove a resting point)
  HULL_SHAPE:setMargin(MARGIN)
end

-- ---------------------------------------------------------------------
-- world
-- ---------------------------------------------------------------------

common.gravity(-G)

local MAX_COUNT = 12
local function param(name, value, lo, hi, step, info)
  v:addParam(name, value, lo, hi, step, info)
end
local function envnum(name, default) return tonumber(os.getenv(name) or "") or default end
param("count", envnum("GC_COUNT", 6), 1, MAX_COUNT, 1, "how many gombocs to drop")
param("speed", 1, 0.25, 4, 0.25, "simulated seconds per real second")
param("steps", envnum("GC_STEPS", 1200), 300, 4800, 300, "physics steps per simulated second")
param("friction", 0.5, 0.05, 1.0, 0.05, "friction coefficient, 1 = grippiest (Bullet multiplies it by the table's 0.8)")
param("restitution", envnum("GC_REST", 0.1), 0.0, 0.8, 0.05, "bounciness")
param("rolling", envnum("GC_ROLL", 150), 0, 300, 5,
      "rolling resistance lever arm, microns (constant moment, any tilt)")
param("spin friction", envnum("GC_SPIN", 0.7), 0, 5, 0.1,
      "deceleration of spin about the vertical, rad/s^2")
param("air drag", envnum("GC_DRAG", 0), 0, 1.5, 0.05,
      "Bullet velocity damping; real air drag is ~0")
param("taps", envnum("GC_TAPS", 0), 0, 1, 1, "1: nudge stalled gombocs home (version B's taps)")
param("redrop", envnum("GC_REDROP", 5), 0, 30, 1,
      "seconds at rest before a gomboc is lifted away and a new one of its colour dropped (0 = off)")

-- Timing: 60 frames a second; each frame simulates `speed` sixtieths of a
-- second in `steps`-per-second physics steps. The script takes all but the
-- last step itself (stepWorld) so it can apply rolling resistance before
-- each one; bpp takes the last, exactly one step long (maxSubSteps 0).
local STEP, NSTEPS, FRAME_DT = 1 / 1200, 20, 1 / 60
local function applyTiming()
  local speed = v:getParam("speed")
  NSTEPS = math.max(1, math.floor(v:getParam("steps") * speed / 60 + 0.5))
  FRAME_DT = speed / 60
  STEP = FRAME_DT / NSTEPS
  v.animationPeriod = 16
  common.setTiming(STEP, 0, STEP)
end
applyTiming()

-- The table: version B's tray. A flat wooden middle, a band sloping gently
-- up all round it, and a low rim.
local SPACING = 27                         -- cm between drop spots
local GRID_COLS, GRID_ROWS = 4, 3
local FLAT_W = GRID_COLS * SPACING + 30    -- cm: the flat middle
local FLAT_D = GRID_ROWS * SPACING + 30
local RAMP_W, RAMP_DEG = 14, 8             -- the sloping band: width (cm), slope
local TABLE_W = FLAT_W + 2 * RAMP_W        -- inside the rim
local TABLE_D = FLAT_D + 2 * RAMP_W
local RAMP_TOP = RAMP_W * math.tan(math.rad(RAMP_DEG))

local WOOD, RIM_WOOD = "#7a4a24", "#4e2e15"
local function slab(sx, sy, sz, x, y, z, col, rot)
  local c = Cube(sx, sy, sz, 0)
  c.trans = btTransform(rot or btQuaternion(0, 0, 0, 1), btVector3(x, y, z))
  c.col = col
  c.friction = 0.8
  c.restitution = 0.2
  v:add(c)
  return c
end
slab(FLAT_W, 4, FLAT_D, 0, -2, 0, WOOD)                         -- top at y = 0

local T = 4                                                     -- slab thickness
local a = math.rad(RAMP_DEG)
local function ramp(nx, nz, len)              -- (nx, nz): the outward direction
  local half = (nx ~= 0) and FLAT_W / 2 or FLAT_D / 2
  local cx = half + RAMP_W / 2
  local cy = RAMP_W / 2 * math.tan(a)
  local tilt = btQuaternion(btVector3(-nz, 0, nx), a)            -- tips the outer edge up
  local w = RAMP_W / math.cos(a)
  local ox, oy = -math.sin(a) * T / 2, -math.cos(a) * T / 2
  if nx ~= 0 then
    slab(w, T, len, nx * (cx - ox), cy + oy, 0, WOOD, tilt)
  else
    slab(len, T, w, 0, cy + oy, nz * (cx - ox), WOOD, tilt)
  end
end
ramp(1, 0, TABLE_D); ramp(-1, 0, TABLE_D); ramp(0, 1, TABLE_W); ramp(0, -1, TABLE_W)

local RIM_H, RIM_T = 4, 3
local rimY, rimH = (RAMP_TOP + RIM_H - 4) / 2, RAMP_TOP + RIM_H + 4
slab(TABLE_W + 2 * RIM_T, rimH, RIM_T, 0, rimY, TABLE_D / 2 + RIM_T / 2, RIM_WOOD)
slab(TABLE_W + 2 * RIM_T, rimH, RIM_T, 0, rimY, -TABLE_D / 2 - RIM_T / 2, RIM_WOOD)
slab(RIM_T, rimH, TABLE_D, TABLE_W / 2 + RIM_T / 2, rimY, 0, RIM_WOOD)
slab(RIM_T, rimH, TABLE_D, -TABLE_W / 2 - RIM_T / 2, rimY, 0, RIM_WOOD)

local floor = Plane(0, 1, 0, -80, 400)
floor.col = "#3b3f45"
v:add(floor)

-- height of the tray's surface under (x, z)
local TAN_A = math.tan(a)
local function tableHeight(x, z)
  local ex = math.max(0, math.abs(x) - FLAT_W / 2)
  local ez = math.max(0, math.abs(z) - FLAT_D / 2)
  return math.min(RAMP_W, math.max(ex, ez)) * TAN_A
end

common.setCamera(btVector3(0, 105, 140), btVector3(0, 0, 6))

-- ---------------------------------------------------------------------
-- the gombocs
-- ---------------------------------------------------------------------

local COLOURS = { "#e6194b", "#3cb44b", "#ffe119", "#4363d8", "#f58231", "#911eb4",
                  "#42d4f4", "#f032e6", "#bfef45", "#fabed4", "#469990", "#dcbeff" }
local NAMES = { "Red", "Green", "Yellow", "Blue", "Orange", "Purple",
                "Cyan", "Magenta", "Lime", "Pink", "Teal", "Lavender" }

local function hex(c)
  return tonumber(c:sub(2, 3), 16), tonumber(c:sub(4, 5), 16), tonumber(c:sub(6, 7), 16)
end
-- 11 shades per gomboc, from dark (tipped over) to its full colour (upright)
local SHADES = {}
for i, c in ipairs(COLOURS) do
  local r, g, b = hex(c)
  SHADES[i] = {}
  for k = 0, 10 do
    local f = 0.25 + 0.75 * k / 10
    SHADES[i][k] = string.format("#%02x%02x%02x", math.floor(r * f), math.floor(g * f),
                                 math.floor(b * f))
  end
end

local gombocs = {}

local function newGomboc(i)
  local m = Mesh(MESH_DIR .. "gomboc.obj", 0, false)   -- (already centred on its COM)
  local ms = btDefaultMotionState(btTransform(btQuaternion(0, 0, 0, 1), btVector3(0, -50, 0)))
  local body = btRigidBody(MASS, ms, HULL_SHAPE, INERTIA)
  m.body = body
  m.col = SHADES[i][0]
  body:setActivationState(4)              -- DISABLE_DEACTIVATION: never doze off mid-rock
  -- (from version B) only contact points within 10 microns of the table
  -- are handed to the solver; this quietens the buzzing of a gomboc at rest
  -- about 4x here (median 0.30 -> 0.07 deg/s)
  body:setContactProcessingThreshold(envnum("GC_CPT", 0.001))
  v:add(m)
  return { obj = m, body = body, i = i, shade = 0 }
end

local function applyMaterials()
  local f, r, d = v:getParam("friction"), v:getParam("restitution"), v:getParam("air drag")
  for _, g in ipairs(gombocs) do
    g.body:setFriction(f)
    g.body:setRestitution(r)
    g.body:setDamping(d, d)
  end
end

-- a uniformly random orientation (Shoemake's method)
local function randomQuat()
  local u1, u2, u3 = math.random(), 2 * math.pi * math.random(), 2 * math.pi * math.random()
  local a, b = math.sqrt(1 - u1), math.sqrt(u1)
  return btQuaternion(a * math.sin(u2), a * math.cos(u2), b * math.sin(u3), b * math.cos(u3))
end

local function place(g, q, x, y, z, vel, spin)
  local b = g.body
  b:setCenterOfMassTransform(btTransform(q, btVector3(x, y, z)))
  b:setLinearVelocity(vel or btVector3(0, 0, 0))
  b:setAngularVelocity(spin or btVector3(0, 0, 0))
  b:clearForces()
  b:activate(true)
end

-- drop spots: a grid SPACING apart, centred on the table, a little jittered
local function spots(n)
  local cols = math.min(GRID_COLS, math.ceil(math.sqrt(n * GRID_COLS / GRID_ROWS)))
  local rows = math.ceil(n / cols)
  local out = {}
  for k = 0, n - 1 do
    local c, r = k % cols, math.floor(k / cols)
    local inRow = math.min(cols, n - r * cols)
    out[#out + 1] = { (c - (inRow - 1) / 2) * SPACING + (math.random() - 0.5) * 3,
                      (r - (rows - 1) / 2) * SPACING + (math.random() - 0.5) * 3 }
  end
  return out
end

-- ---------------------------------------------------------------------
-- rolling resistance and spin friction, before every physics step
-- ---------------------------------------------------------------------
-- On the table (centre of mass no higher above the surface than the
-- gomboc's tip), each step:
--   * the rolling part of the spin (about horizontal axes) loses
--       alpha = delta * g / (k^2 + r^2)
--     per second, where r is the centre of mass's height above the table,
--     k^2 the squared radius of gyration about the rolling axis, so
--     k^2 + r^2 is the moment of inertia (per unit mass) about the contact:
--     a constant moment delta*m*g about the contact point. The centre of
--     mass's velocity changes to match (rolling about the contact point
--     below it), so the contact point itself isn't made to slide.
--   * the spin about the vertical loses `spin friction` per second.
-- Neither can reverse the motion: below one step's bite it stops.
-- (Approximations: the contact point is taken straight below the centre of
-- mass, and "vertical" is world up even on the 8-degree slopes.)
local ROLL_DELTA, SPIN_DECEL = 0.005, 0.7     -- cm, rad/s^2 (set from sliders)

local function resist(dt)
  if ROLL_DELTA <= 0 and SPIN_DECEL <= 0 then return end
  for _, g in ipairs(gombocs) do
    local px, py, pz = getPosXYZ(g.obj)
    local r = py - tableHeight(px, pz) - MARGIN
    if r < HULL.topHeight + 0.05 and r > 0 then
      local wx, wy, wz = getAngVelXYZ(g.obj)
      local vx, vy, vz = getVelXYZ(g.obj)
      local w = math.sqrt(wx * wx + wz * wz)
      if w > 0 and ROLL_DELTA > 0 then
        -- squared radius of gyration about the rolling axis (body frame)
        local B = g.body:getCenterOfMassTransform():getBasis()
        local ax, az = wx / w, wz / w
        local k2 = 0
        for c = 0, 2 do
          local e = B:getColumn(c)                     -- body axis c in the world
          local d = ax * e.x + az * e.z
          k2 = k2 + K2[c + 1] * d * d
        end
        local alpha = ROLL_DELTA * G / (k2 + r * r)
        local dw = math.min(w, alpha * dt)
        local dwx, dwz = -dw * ax, -dw * az
        wx, wz = wx + dwx, wz + dwz
        -- keep the contact point (r straight below) from sliding:
        -- dv = dw x (0, r, 0)
        vx, vz = vx - dwz * r, vz + dwx * r
      end
      if SPIN_DECEL > 0 then
        local dws = math.min(math.abs(wy), SPIN_DECEL * dt)
        wy = wy - (wy > 0 and dws or -dws)
      end
      setAngVelXYZ(g.obj, wx, wy, wz)
      setVelXYZ(g.obj, vx, vy, vz)
    end
  end
end

-- ---------------------------------------------------------------------
-- the race: upright, then at rest
-- ---------------------------------------------------------------------

-- Upright: within UPRIGHT_DEG of upright for HOLD seconds (as version B).
-- At rest: has not turned more than REST_TURN nor moved more than REST_MOVE
-- in any REST_HOLD-second window. (Judged by where it is, not by its speed:
-- the contact solver makes a gomboc at rest buzz in place -- brief speed
-- spikes that never add up to visible movement, though they do let it creep
-- about 0.1 mm per 10 s.)
local UPRIGHT_DEG, HOLD = 15, 2.0
local REST_TURN = math.rad(0.2)           -- rad
local REST_MOVE = 0.02                    -- cm
local REST_HOLD = 2.0
local RACE_LIMIT = 300                    -- s: give up reporting after this

-- version B's taps (only with the "taps" slider on)
local TAP_AFTER = 3.0
local CLEAR = 5.5
local HOP = 15
local HOP_UP = 20
local TAP_SPIN = 1.0
local SLOW_SPIN = 0.15

local race = { t = 0, running = false, nextReport = 1, nextTally = 60, label = "", done = {} }

-- a fresh run for one gomboc: its clock starts now
local function resetGomboc(g)
  g.t0 = race.t
  g.restSince, g.rightedAt, g.anchorT, g.restedAt, g.restSeenAt = nil, nil, nil, nil, nil
  g.best, g.bestAt, g.taps, g.touching, g.shade = 180, race.t, 0, nil, -1
end

local function resetRace(label)
  race.t, race.running, race.nextReport, race.nextTally, race.label, race.done =
    0, true, 1, 60, label, {}
  for _, g in ipairs(gombocs) do
    resetGomboc(g)
    g.run = 1
  end
  print(string.format("\n--- %s: %d gomboc%s ---", label, #gombocs, #gombocs == 1 and "" or "s"))
end

-- "Red", or "Red #3" from its third drop on
local function label(g)
  return g.run > 1 and string.format("%s #%d", NAMES[g.i], g.run) or NAMES[g.i]
end

-- tilt of the gomboc's own up axis from world up, in degrees
local function tiltDeg(b)
  local q = b:getOrientation()
  local x, z = q:getX(), q:getZ()
  local c = math.max(-1, math.min(1, 1 - 2 * (x * x + z * z)))
  return math.deg(math.acos(c))
end

local function standings()
  local done = {}
  for _, g in ipairs(gombocs) do if g.restedAt then done[#done + 1] = g end end
  table.sort(done, function(a, b) return a.restedAt - a.t0 < b.restedAt - b.t0 end)
  for k, g in ipairs(done) do
    local taps = g.taps > 0 and string.format("  (%d tap%s)", g.taps, g.taps == 1 and "" or "s") or ""
    print(string.format("  %2d. %-9s upright %s, at rest %6.2f s, %4.1f deg off upright%s%s",
                        k, label(g), g.rightedAt and string.format("%6.2f s", g.rightedAt - g.t0) or "  never ",
                        g.restedAt - g.t0, g.tilt, taps, g.touching and ("  (touching " .. g.touching .. ")") or ""))
  end
end

local function obstacle(g)
  local px, _, pz = getPosXYZ(g.obj)
  local ax, az, why = 0, 0, nil
  if TABLE_W / 2 - math.abs(px) < CLEAR then ax = -px / math.abs(px); why = "the rim" end
  if TABLE_D / 2 - math.abs(pz) < CLEAR then az = -pz / math.abs(pz); why = "the rim" end
  for _, o in ipairs(gombocs) do
    if o ~= g then
      local ox, _, oz = getPosXYZ(o.obj)
      local dx, dz = px - ox, pz - oz
      local d = math.sqrt(dx * dx + dz * dz)
      if d < 2 * CLEAR and d > 0 then ax, az, why = ax + dx / d, az + dz / d, NAMES[o.i] end
    end
  end
  local n = math.sqrt(ax * ax + az * az)
  if not why or n == 0 then return nil end
  return ax / n, az / n, why
end

-- what it may be resting against: a neighbour whose centre is closer than
-- the two gombocs' largest radii (4.6 cm each), or the rim
local function touching(g)
  local px, _, pz = getPosXYZ(g.obj)
  if TABLE_W / 2 - math.abs(px) < HULL.topHeight or TABLE_D / 2 - math.abs(pz) < HULL.topHeight then
    return "the rim"
  end
  for _, o in ipairs(gombocs) do
    if o ~= g then
      local ox, _, oz = getPosXYZ(o.obj)
      if math.sqrt((px - ox) ^ 2 + (pz - oz) ^ 2) < 2 * HULL.topHeight then return NAMES[o.i] end
    end
  end
  return nil
end

local function maybeTap(g, tilt)
  if v:getParam("taps") < 0.5 then return end
  local wx, wy, wz = getAngVelXYZ(g.obj)
  local ax, az, why = obstacle(g)
  if math.sqrt(wx * wx + wy * wy + wz * wz) > SLOW_SPIN or (not ax and tilt < g.best - 1) then
    g.best, g.bestAt = tilt, race.t
    return
  end
  if race.t - g.bestAt < TAP_AFTER then return end
  local _, h, _ = getPosXYZ(g.obj)
  local rx, rz
  if ax then
    rx, rz = ax, az
  else
    local q = g.body:getOrientation()
    local x, y, z, w = q:getX(), q:getY(), q:getZ(), q:getW()
    local ux, uz = 2 * (x * y - w * z), 2 * (y * z + w * x)
    local a = math.atan2(-uz, -ux) + math.rad((math.random() - 0.5) * 60)
    if ux * ux + uz * uz < 1e-6 then a = math.random() * 2 * math.pi end
    rx, rz = math.cos(a), math.sin(a)
  end
  local s = ax and HOP or TAP_SPIN * h
  setAngVelXYZ(g.obj, rz * s / h, 0, -rx * s / h)
  setVelXYZ(g.obj, rx * s, ax and HOP_UP or 0, rz * s)
  g.taps, g.best, g.bestAt = g.taps + 1, tilt, race.t
  print(string.format("  %-9s tap! (%s)", NAMES[g.i],
                      ax and ("leaning on " .. why) or string.format("dawdling at %.0f deg", tilt)))
end

-- ---------------------------------------------------------------------
-- the moves
-- ---------------------------------------------------------------------

local function setCount(n)
  n = math.max(1, math.min(MAX_COUNT, math.floor(n)))
  while #gombocs > n do v:remove(table.remove(gombocs).obj) end
  while #gombocs < n do gombocs[#gombocs + 1] = newGomboc(#gombocs + 1) end
  applyMaterials()
end

local function randomSpin()
  return btVector3((math.random() - 0.5) * 6, (math.random() - 0.5) * 6, (math.random() - 0.5) * 6)
end

local function drop()
  setCount(v:getParam("count"))
  local s = spots(#gombocs)
  for k, g in ipairs(gombocs) do
    g.spot = s[k]
    place(g, randomQuat(), s[k][1], 12 + 4 * k + math.random() * 6, s[k][2], nil, randomSpin())
  end
  resetRace("Drop")
end

-- Lift a resting gomboc away and drop a new one of its colour: over its
-- own drop spot if that is clear, otherwise over a clear spot on the flat.
local function clearOf(g, x, z)
  for _, o in ipairs(gombocs) do
    if o ~= g then
      local ox, _, oz = getPosXYZ(o.obj)
      if math.sqrt((x - ox) ^ 2 + (z - oz) ^ 2) < 12 then return false end
    end
  end
  return true
end

local function redrop(g)
  local x, z = g.spot and g.spot[1] or 0, g.spot and g.spot[2] or 0
  for try = 1, 40 do
    if clearOf(g, x, z) then break end
    x = (math.random() - 0.5) * (FLAT_W - 20)
    z = (math.random() - 0.5) * (FLAT_D - 20)
  end
  race.done[#race.done + 1] = { name = NAMES[g.i], upright = g.rightedAt and g.rightedAt - g.t0,
                                rest = g.restedAt - g.t0, tilt = g.tilt }
  g.run = g.run + 1
  place(g, randomQuat(), x, 14 + math.random() * 8, z, nil, randomSpin())
  resetGomboc(g)
  print(string.format("  %-9s lifted away after %g s at rest; dropping %s", NAMES[g.i],
                      v:getParam("redrop"), label(g)))
end

-- every minute while re-dropping: how the finished runs went
local function tally()
  local n = #race.done
  if n == 0 then return end
  local rests, notUp = {}, 0
  for _, d in ipairs(race.done) do
    rests[#rests + 1] = d.rest
    if d.tilt >= UPRIGHT_DEG then notUp = notUp + 1 end
  end
  table.sort(rests)
  print(string.format("=== %.0f s: %d finished run%s; time to rest: median %.1f s, fastest %.1f s, " ..
                      "slowest %.1f s; %d came to rest not upright ===", race.t, n, n == 1 and "" or "s",
                      rests[math.floor((n + 1) / 2)], rests[1], rests[n], notUp))
end

-- on its head: the unstable point straight down, nudged a degree or three
local function headstand()
  setCount(v:getParam("count"))
  local s = spots(#gombocs)
  for k, g in ipairs(gombocs) do
    local yaw = btQuaternion(btVector3(0, 1, 0), math.random() * 2 * math.pi)
    local flip = btQuaternion(btVector3(1, 0, 0), math.pi)
    local a = math.random() * 2 * math.pi
    local nudge = btQuaternion(btVector3(math.cos(a), 0, math.sin(a)), math.rad(1 + 2 * math.random()))
    g.spot = s[k]
    place(g, nudge * yaw * flip, s[k][1], HULL.topHeight + MARGIN + 0.1, s[k][2])
  end
  resetRace("Headstand")
end

local function kick()
  for _, g in ipairs(gombocs) do
    g.body:setLinearVelocity(btVector3((math.random() - 0.5) * 40, 120 + math.random() * 80,
                                       (math.random() - 0.5) * 40))
    g.body:setAngularVelocity(btVector3((math.random() - 0.5) * 30, (math.random() - 0.5) * 10,
                                        (math.random() - 0.5) * 30))
    g.body:activate(true)
  end
  resetRace("Kick")
end

v:addShortcut("R", function(N) drop() end)
v:addShortcut("U", function(N) headstand() end)
v:addShortcut("K", function(N) kick() end)
v:addShortcut("]", function(N)
  v:addParam("count", math.min(MAX_COUNT, v:getParam("count") + 1), 1, MAX_COUNT, 1, "how many gombocs to drop")
  drop()
end)
v:addShortcut("[", function(N)
  v:addParam("count", math.max(1, v:getParam("count") - 1), 1, MAX_COUNT, 1, "how many gombocs to drop")
  drop()
end)

local function applyResistance()
  ROLL_DELTA = v:getParam("rolling") * 1e-4          -- microns -> cm
  SPIN_DECEL = v:getParam("spin friction")
end
applyResistance()

v:onParamChanged(function(N, name, value)   -- bpp passes (frame, name, value)
  if name == "count" then
    if math.floor(tonumber(value)) ~= #gombocs then drop() end
  elseif name == "speed" or name == "steps" then
    applyTiming()
  elseif name == "rolling" or name == "spin friction" then
    applyResistance()
  else
    applyMaterials()
  end
end)

pcall(function()
  v:setHelpText(
    "Gomboc Drop C (realistic)\n" ..
    "  R  drop at random orientations\n" ..
    "  U  stand them on their heads\n" ..
    "  K  kick them up with a spin\n" ..
    "  ]  one more     [  one fewer\n" ..
    "Dark = tipped over, bright = upright.\n" ..
    "The console reports upright and at-rest times.\n" ..
    "At rest for 'redrop' s: lifted away, a new one dropped.")
end)

-- ---------------------------------------------------------------------
-- every frame: our own physics steps, then shading and the race
-- ---------------------------------------------------------------------

-- all but the last step of the frame; bpp takes the last one after this
v:preSim(function(N)
  for k = 1, NSTEPS - 1 do
    resist(STEP)
    v:stepSimulation(STEP, 0, STEP)
  end
  resist(STEP)
end)

local LOGF = os.getenv("GC_LOG") and io.open(os.getenv("GC_LOG"), "w")
if LOGF then LOGF:write("t,idx,name,tilt_deg,angvel_deg_s,speed_cm_s,y,x,z,qx,qy,qz,qw\n") end
local simT = 0

v:postSim(function(N)
  simT = simT + FRAME_DT
  if LOGF and N % 15 == 0 then
    for _, g in ipairs(gombocs) do
      local wx, wy, wz = getAngVelXYZ(g.obj)
      local vx, vy, vz = getVelXYZ(g.obj)
      local _, py, _ = getPosXYZ(g.obj)
      local px, _, pz = getPosXYZ(g.obj)
      local q = g.body:getOrientation()
      LOGF:write(string.format("%.2f,%d,%s,%.3f,%.5f,%.5f,%.5f,%.5f,%.5f,%.6f,%.6f,%.6f,%.6f\n", simT, g.i, NAMES[g.i],
        tiltDeg(g.body), math.deg(math.sqrt(wx*wx+wy*wy+wz*wz)), math.sqrt(vx*vx+vy*vy+vz*vz), py,
        px, pz, q:getX(), q:getY(), q:getZ(), q:getW()))
    end
    LOGF:flush()
  end

  if not race.running then return end
  race.t = race.t + FRAME_DT
  local upright, rested = 0, 0
  for _, g in ipairs(gombocs) do
    local tilt = tiltDeg(g.body)
    g.tilt = tilt

    local k = g.rightedAt and 10 or math.floor(10 * math.max(0, 1 - tilt / 90) + 0.5)
    if k ~= g.shade then g.shade = k; g.obj.col = SHADES[g.i][k] end

    if tilt < UPRIGHT_DEG then
      upright = upright + 1
      g.restSince = g.restSince or race.t
      if not g.rightedAt and race.t - g.restSince >= HOLD then
        g.rightedAt = g.restSince
        print(string.format("  %-9s upright after %6.2f s", label(g), g.rightedAt - g.t0))
      end
    else
      g.restSince = nil
      if not g.rightedAt then maybeTap(g, tilt) end
    end

    -- at rest: hasn't moved in the last REST_HOLD-second window
    local q = g.body:getOrientation()
    local qx, qy, qz, qw = q:getX(), q:getY(), q:getZ(), q:getW()
    local px, py, pz = getPosXYZ(g.obj)
    local moved = true
    if g.anchorT then
      local dot = math.abs(qx * g.aq[1] + qy * g.aq[2] + qz * g.aq[3] + qw * g.aq[4])
      local turn = 2 * math.acos(math.min(1, dot))
      local dx, dy, dz = px - g.ap[1], py - g.ap[2], pz - g.ap[3]
      moved = turn > REST_TURN or math.sqrt(dx * dx + dy * dy + dz * dz) > REST_MOVE
    end
    if not moved and race.t - g.anchorT >= REST_HOLD then
      -- still for a whole window: (now) at rest; start the next window here
      g.anchorT, g.aq, g.ap = race.t, { qx, qy, qz, qw }, { px, py, pz }
      if not g.restedAt then
        g.restedAt, g.restSeenAt = race.t - REST_HOLD, race.t
        local why = touching(g)
        g.touching = why
        print(string.format("  %-9s at rest after %6.2f s, %.1f deg off upright%s%s",
                            label(g), g.restedAt - g.t0, tilt,
                            tilt < UPRIGHT_DEG and "" or "  ** NOT UPRIGHT **",
                            why and ("  -- touching " .. why) or ""))
      end
    elseif moved then
      g.anchorT, g.aq, g.ap = race.t, { qx, qy, qz, qw }, { px, py, pz }
      g.restedAt, g.restSeenAt = nil, nil          -- (it moved again)
    end
    if g.restedAt then rested = rested + 1 end
  end

  -- re-drop the ones that have been at rest long enough
  local wait = v:getParam("redrop")
  if wait > 0 then
    for _, g in ipairs(gombocs) do
      if g.restSeenAt and race.t - g.restSeenAt >= wait then
        rested = rested - 1
        redrop(g)
      end
    end
    if race.t >= race.nextTally then
      race.nextTally = race.nextTally + 60
      tally()
    end
  end

  if race.t >= race.nextReport then
    race.nextReport = race.nextReport + (race.t < 20 and 1 or 5)
    local tilts = {}
    for _, g in ipairs(gombocs) do tilts[#tilts + 1] = string.format("%3.0f", g.tilt) end
    print(string.format("t=%5.1fs  upright %d/%d  at rest %d/%d  tilt(deg): %s", race.t,
                        upright, #gombocs, rested, #gombocs, table.concat(tilts, " ")))
  end

  if wait <= 0 and (rested == #gombocs or race.t >= RACE_LIMIT) then
    race.running = false
    if rested == #gombocs then
      print(string.format("--- all %d at rest after %.2f s ---", #gombocs, race.t))
    else
      print(string.format("--- %d of %d at rest after %.0f s; stopped watching ---",
                          rested, #gombocs, race.t))
    end
    standings()
    print("R: drop again   U: headstands   K: kick")
  end
end)

math.randomseed(envnum("GC_SEED", os.time()))
if os.getenv("GC_START") == "headstand" then headstand() else drop() end
