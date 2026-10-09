--
-- The Rattleback -- Euler's Cabinet of Curiosities
--
-- A rattleback (or celt) is a boat-shaped stone or block that spins smoothly
-- one way -- but spun the other way it slows, starts to rock, and turns
-- round to spin the way it prefers. Tap one end while it lies still, and it
-- starts spinning, its favourite way, all by itself.
--
-- The trick is a skew: its mass is turned a few degrees away from the
-- lines of its hull. Then rocking and spinning are coupled -- spinning the
-- "wrong" way feeds a pitching rock, and the rock, pushing against the
-- table through that skewed hull, turns the spin round.
--
-- Three identical rattlebacks (12 x 3 x 1.2 cm, plastic, hull turned 8
-- degrees from the mass axes) on a table:
--   left   (amber)    spun CLOCKWISE (seen from above) -- the wrong way: it
--                     rocks, stops, and spins back anticlockwise
--   middle (teal)     spun ANTICLOCKWISE -- its own way: it just spins down
--   right  (magenta)  "the restless one": spun clockwise on a table that
--                     takes almost no energy (rolling 5 microns instead of
--                     50): wobble, spin, wobble, spin the other way, again
--                     and again (some real rattlebacks do this)
-- T taps all three on the end from rest: they start spinning anticlockwise.
-- The Shortcuts pane explains what to watch for.
--
-- PHYSICS, as in the other exhibits:
--  * Bullet's gyroscopic term is off; each rattleback's spin is advanced by
--    Euler's equations (RK4) before every physics step. (Bullet's default
--    drains spin energy, which hides half the rattleback's behaviour.)
--  * Rolling resistance: a constant moment delta*m*g against rolling, at the
--    contact, before every step (as in Gomboc Drop C). It matters here:
--    checked against an independent model (a rigid ellipsoid rolling without
--    slipping, energy exactly conserved), this rattleback is unstable in BOTH
--    directions -- strongly the wrong way (growth 8.5/s at 1 turn/s), weakly
--    its own way (1.7/s). Real rattlebacks reverse only one way because small
--    losses at the table damp the weak instability; with no losses at all
--    this one reverses both ways for ever. Rolling 20-100 microns gives the
--    one-way rattleback; at 200 neither way reverses. Default 50.
--  * Contact: convex hull of 3073 points of the half-ellipsoid, 0.1 mm
--    margin, 10-micron contact processing threshold.
--  * Control check: with the skew set to 0 nothing ever reverses.
--
-- Keys
--   R   spin them again (left clockwise, right anticlockwise)
--   T   stop them, then tap both on the end
--   Z   slow motion (1/4) <-> real time
--
-- Sliders: spin (turns per second), wobble (the hand's rock when spun,
-- rad/s), rolling (microns), friction, speed, steps.
--
-- Units: centimetres, kilograms, seconds.
-- Headless testing: RB_SPIN, RB_ROLL, RB_START=tap, RB_LOG=file.csv.
--

local common = require "common"

local DIR = "rattleback-meshes/"
local function loadData()
  for _, dir in ipairs({ DIR, "demo/rattleback/" .. DIR }) do
    local ok, data = pcall(dofile, dir .. "rattleback-data.lua")
    if ok and data then DIR = dir; return data end
  end
  error("rattleback-data.lua not found")
end
local R = loadData()
local MASS, IV = R.mass, R.inertia
local INERTIA = btVector3(IV[1], IV[2], IV[3])
local G = 981
local MARGIN = 0.01

local HULL = btConvexHullShape()
do
  local p = R.hull
  for i = 1, #p, 3 do HULL:addPoint(btVector3(p[i], p[i + 1], p[i + 2]), false) end
  HULL:recalcLocalAabb()
  HULL:setMargin(MARGIN)
end

-- ---------------------------------------------------------------------
-- sliders, timing
-- ---------------------------------------------------------------------
local function envnum(n, d) return tonumber(os.getenv(n) or "") or d end
local function param(...) v:addParam(...) end
param("spin", envnum("RB_SPIN", 1.0), 0.2, 3, 0.1, "turns per second")
param("wobble", 1.0, 0, 3, 0.1, "the hand's rock when it is spun, rad/s")
param("rolling", envnum("RB_ROLL", 50), 0, 300, 5, "rolling resistance lever arm, microns (left and middle)")
param("restless rolling", envnum("RB_RROLL", 5), 0, 300, 1, "rolling resistance for the restless one, microns")
param("friction", 0.6, 0.1, 1.0, 0.05, "friction coefficient (1 = grippiest)")
param("speed", 1, 0.05, 2, 0.05, "simulated seconds per real second (Z: 1/4 <-> 1)")
param("steps", 1200, 300, 4800, 300, "physics steps per simulated second")

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
v.gravity = btVector3(0, -G, 0)

-- ---------------------------------------------------------------------
-- the table
-- ---------------------------------------------------------------------
local TABLE_Y = 0
local top = Cube(80, 3, 40, 0)
top.pos = btVector3(0, TABLE_Y - 1.5, 0)
top.col = "#7a4a24"
top.friction = 1.0
v:add(top)
for _, x in ipairs({ -36, 36 }) do
  for _, z in ipairs({ -16, 16 }) do
    local leg = Cube(3, 72, 3, 0)
    leg.pos = btVector3(x, TABLE_Y - 3 - 36, z)
    leg.col = "#4e2e15"
    leg.collides = false
    v:add(leg)
  end
end
local floor = Plane(0, 1, 0, TABLE_Y - 75, 300)
floor.col = "#3b3f45"
v:add(floor)
common.setCamera(btVector3(0, 44, 48), btVector3(0, 0, 0))

-- ---------------------------------------------------------------------
-- the rattlebacks
-- ---------------------------------------------------------------------
local RB = {
  { name = "Left (amber), spun clockwise -- the wrong way",              short = "Left",     x = -21, col = "#f0a020", dir = -1 },
  { name = "Middle (teal), spun anticlockwise -- its own way",           short = "Middle",   x = 0,   col = "#20a0a0", dir = 1 },
  { name = "Right (magenta), spun clockwise, almost no losses -- restless", short = "Restless", x = 21, col = "#d040c0", dir = -1,
    restless = true },
}
local REST = R.restHeight + MARGIN

for _, r in ipairs(RB) do
  local m = Mesh(DIR .. "rattleback.obj", 0, false)
  local body = btRigidBody(MASS, btDefaultMotionState(btTransform(btQuaternion(0, 0, 0, 1),
                           btVector3(r.x, TABLE_Y + REST, 0))), HULL, INERTIA)
  m.body = body
  m.col = r.col
  v:add(m)
  body:setActivationState(4)
  body:setDamping(0, 0)
  body:setRestitution(0)
  body:setFlags(0)                         -- gyroscopic term: Euler's equations below
  body:setContactProcessingThreshold(0.001)
  r.m, r.body = m, body
end

local function applyMaterials()
  for _, r in ipairs(RB) do r.body:setFriction(v:getParam("friction")) end
end
applyMaterials()

local function basis(b)
  local B = b:getCenterOfMassTransform():getBasis()
  return { B:getColumn(0), B:getColumn(1), B:getColumn(2) }
end
local function toWorld(c, w)
  return btVector3(c[1].x * w[1] + c[2].x * w[2] + c[3].x * w[3],
                   c[1].y * w[1] + c[2].y * w[2] + c[3].y * w[3],
                   c[1].z * w[1] + c[2].z * w[2] + c[3].z * w[3])
end

local t = 0
local function place(r, wbody)
  local b = r.body
  b:setCenterOfMassTransform(btTransform(btQuaternion(btVector3(0, 1, 0), 0), btVector3(r.x, TABLE_Y + REST, 0)))
  b:setLinearVelocity(btVector3(0, 0, 0))
  b:setAngularVelocity(toWorld(basis(b), wbody))
  b:clearForces()
  b:activate(true)
  r.sign, r.reversals, r.maxRock, r.lastPrint = nil, 0, 0, -1
end

local function spinThem()
  t = 0
  local W = 2 * math.pi * v:getParam("spin")
  local wob = v:getParam("wobble")
  print(string.format("\n--- spun at %.1f turns/s with a %.1f rad/s wobble ---", v:getParam("spin"), wob))
  for _, r in ipairs(RB) do
    place(r, { wob, r.dir * W, 0 })         -- (body x = its length: the wobble is a side-to-side rock)
    print("  " .. r.name)
  end
end

local function tapThem()
  t = 0
  print("\n--- all three tapped on the end, from rest ---")
  for _, r in ipairs(RB) do place(r, { 0, 0, 3.0 }) end   -- a pitching rock (about its width)
end

-- ---------------------------------------------------------------------
-- before every physics step: Euler's equations, then rolling resistance
-- ---------------------------------------------------------------------
local function deriv(w)
  return { (IV[2] - IV[3]) * w[2] * w[3] / IV[1], (IV[3] - IV[1]) * w[3] * w[1] / IV[2],
           (IV[1] - IV[2]) * w[1] * w[2] / IV[3] }
end
local function plus(a, d, s) return { a[1] + s * d[1], a[2] + s * d[2], a[3] + s * d[3] } end

local function applyRolling()
  for _, r in ipairs(RB) do
    r.delta = v:getParam(r.restless and "restless rolling" or "rolling") * 1e-4   -- microns -> cm
  end
end
applyRolling()

local function prestep(h)
  for _, r in ipairs(RB) do
    local b = r.body
    -- Euler's equations for the free rotation part
    local c = basis(b)
    local W = b:getAngularVelocity()
    local w = { c[1].x * W.x + c[1].y * W.y + c[1].z * W.z, c[2].x * W.x + c[2].y * W.y + c[2].z * W.z,
                c[3].x * W.x + c[3].y * W.y + c[3].z * W.z }
    local k1 = deriv(w); local k2 = deriv(plus(w, k1, h / 2)); local k3 = deriv(plus(w, k2, h / 2)); local k4 = deriv(plus(w, k3, h))
    for i = 1, 3 do w[i] = w[i] + h / 6 * (k1[i] + 2 * k2[i] + 2 * k3[i] + k4[i]) end
    W = toWorld(c, w)
    -- rolling resistance about the contact (taken straight below the COM)
    local wx, wy, wz = W.x, W.y, W.z
    local V = b:getLinearVelocity()
    local vx, vy, vz = V.x, V.y, V.z
    local _, py, _ = getPosXYZ(r.m)
    local rr = py - TABLE_Y - MARGIN
    local wh = math.sqrt(wx * wx + wz * wz)
    local DELTA = r.delta
    if DELTA > 0 and wh > 0 and rr > 0 and rr < 3 then
      local ax, az = wx / wh, wz / wh
      local k2s = 0
      for i = 1, 3 do local d = ax * c[i].x + az * c[i].z; k2s = k2s + IV[i] / MASS * d * d end
      local dw = math.min(wh, DELTA * G / (k2s + rr * rr) * h)
      local dwx, dwz = -dw * ax, -dw * az
      wx, wz = wx + dwx, wz + dwz
      vx, vz = vx - dwz * rr, vz + dwx * rr
    end
    b:setAngularVelocity(btVector3(wx, wy, wz))
    b:setLinearVelocity(btVector3(vx, vy, vz))
  end
end

v:preSim(function(N)
  for k = 1, NSTEPS - 1 do
    prestep(STEP)
    v:stepSimulation(STEP, 0, STEP)
  end
  prestep(STEP)
end)

-- ---------------------------------------------------------------------
-- watching
-- ---------------------------------------------------------------------
local LOGF = os.getenv("RB_LOG") and io.open(os.getenv("RB_LOG"), "w")
if LOGF then LOGF:write("t,which,spin_rad_s,rock_deg,pitch_deg\n") end
local function dirName(w) return w > 0 and "anticlockwise" or "clockwise" end

v:postSim(function(N)
  t = t + FRAME_DT
  for k, r in ipairs(RB) do
    local W = r.body:getAngularVelocity()
    local c = basis(r.body)
    local rock = math.deg(math.asin(math.max(-1, math.min(1, c[3].y))))     -- side to side
    local pitch = math.deg(math.asin(math.max(-1, math.min(1, c[1].y))))    -- end to end
    r.maxRock = math.max(r.maxRock, math.abs(rock), math.abs(pitch))
    local w = W.y
    if math.abs(w) > 0.3 then
      local sg = w > 0 and 1 or -1
      if r.sign and sg ~= r.sign then
        r.reversals = r.reversals + 1
        print(string.format("  %-5s REVERSED at %5.2f s: now spinning %s (rocking up to %.0f deg)",
                            r.short, t, dirName(w), r.maxRock))
      elseif not r.sign then
        print(string.format("  %-5s spinning %s at %5.2f s", r.short, dirName(w), t))
      end
      r.sign = sg
    end
    if LOGF and N % 4 == 0 then
      LOGF:write(string.format("%.4f,%d,%.5f,%.3f,%.3f\n", t, k, w, rock, pitch))
    end
  end
  if N % 120 == 0 then
    local parts = {}
    for _, r in ipairs(RB) do
      local w = r.body:getAngularVelocity().y
      parts[#parts + 1] = string.format("%s %+5.2f", r.short, w / (2 * math.pi))
    end
    print(string.format("t=%5.1fs  turns/s: %s   (+ = anticlockwise)", t, table.concat(parts, "  ")))
  end
  if LOGF and N % 60 == 0 then LOGF:flush() end
end)

-- ---------------------------------------------------------------------
-- keys, sliders
-- ---------------------------------------------------------------------
v:addShortcut("R", function(N) spinThem() end)
v:addShortcut("T", function(N) tapThem() end)
v:addShortcut("Z", function(N)
  local sp = v:getParam("speed") < 0.5 and 1 or 0.25
  v:addParam("speed", sp, 0.05, 2, 0.05, "simulated seconds per real second (Z: 1/4 <-> 1)")
  applyTiming()
end)
v:onParamChanged(function(N, name, value)        -- bpp passes (frame, name, value)
  if name == "speed" or name == "steps" then applyTiming()
  elseif name == "rolling" or name == "restless rolling" then applyRolling()
  elseif name == "friction" then applyMaterials()
  elseif name == "spin" or name == "wobble" then spinThem() end
end)
pcall(function()
  v:setHelpText(table.concat({
    "THE RATTLEBACK  (Euler's Cabinet of Curiosities)",
    "",
    "A rattleback spins happily one way -- spun the other way it rocks,",
    "stops, and turns round. Tap one end and it starts spinning by itself.",
    "",
    "WHAT TO WATCH",
    "  Left (amber)    spun clockwise, its WRONG way: within a second it",
    "                  starts to rock end to end, stops, and spins back",
    "                  anticlockwise.",
    "  Middle (teal)   spun anticlockwise, its OWN way: it just spins down.",
    "  Right (magenta) THE RESTLESS ONE: the same shape, on a table that",
    "                  takes almost no energy. Wobble, spin, wobble, spin",
    "                  the other way -- again and again, until it runs out.",
    "",
    "WHY",
    "  Its weight is turned 8 degrees away from the lines of its hull (the",
    "  two studs on top mark the twist). Spinning then feeds a rock, and the",
    "  rock, pushing on the table through the twisted hull, turns the spin.",
    "  This shape is unstable BOTH ways: strongly clockwise, weakly",
    "  anticlockwise. A little rolling resistance at the table damps the weak",
    "  one -- a one-way rattleback (left and middle). With almost none, both",
    "  win in turn -- the restless one. Try the 'rolling' sliders.",
    "",
    "KEYS",
    "  R  spin them again          T  stop, then tap all three on the end",
    "  Z  slow motion <-> real time",
    "",
    "The console reports every reversal and the spins every 2 s",
    "(+ = anticlockwise, seen from above).",
  }, "\n"))
end)


if os.getenv("RB_START") == "tap" then tapThem() else spinThem() end
