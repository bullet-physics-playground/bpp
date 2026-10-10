--
-- The Tippe Top -- Euler's Cabinet of Curiosities
--
-- A tippe top is a ball with a stem, its weight a little below the ball's
-- centre. Spin it on its ball, stem up, and within a few seconds it turns
-- itself upside down and spins on its stem, its centre of mass now higher
-- than where it started. Friction at the table does it: the ball slides
-- as it spins, and the drag of the table on the sliding ball tips it over.
-- Niels Bohr and Wolfgang Pauli are said to have been photographed
-- watching one.
--
-- Three tops, each in its own dish:
--   left   (red)     spun fast: turns over in a few seconds and stands up on
--                    its stem; twenty-odd seconds later, slowing down, it
--                    sinks back and ends where it began, stem up
--   middle (blue)    the same top, spun slowly: it turns over as far as
--                    lying on its ball and stem, but hasn't the spin to stand
--                    up on the stem; as it slows it rights itself again
--   right  (green)   looks the same, but its weight is at the ball's centre:
--                    it never turns over
-- The white bands show the spin. R spins them again. It's all over in
-- about a minute and a half.
--
-- THE TOP: a ball 3 cm across with a short stem; 15 g, hollow (its moment
-- of inertia about the stem 2/3 m r^2, across it 0.9 of that); its centre of
-- mass 4.5 mm below the ball's centre (0.3 of the radius). A top turns over
-- only if 1 - 0.3 < 0.9 < 1 + 0.3, which this one passes. The green one's
-- centre of mass is 0.6 mm off centre: 0.9 is outside 1 -/+ 0.04, so it
-- can't. To stay up on its stem it then needs about 100 rad/s or more
-- (a solid ball needed so much spin that it never managed it).
--
-- PHYSICS, as in the other exhibits:
--  * Bullet's gyroscopic term is off; each top's spin is advanced by
--    Euler's equations (RK4) before every physics step.
--  * Contact: a true sphere for the ball and a capsule for the stem (a
--    compound shape); sliding friction 0.2 (the friction slider).
--  * Spin friction: a small deceleration of the spin about the upright
--    (0.5 rad/s^2), so a top on its stem slows down and in the end falls
--    over. (Without it, the red one spins on its stem for ever.)
--  * Rolling resistance: a constant moment delta*m*g against rolling, as in
--    the other exhibits, 30 microns. It settles the tops at the end; at 100
--    microns the red one doesn't turn over at all.
--  * 4800 physics steps a second (it spins at 40 turns a second).
--
-- Keys
--   R   spin them again
--   Z   slow motion (1/4) <-> real time
--
-- Units: centimetres, kilograms, seconds.
-- Headless testing: TT_FAST, TT_SLOW (turns/s), TT_MU, TT_LOG=file.csv.
--

local common = require "common"

local DIR = "tippe-top-meshes/"
for _, dir in ipairs({ DIR, "demo/WyomingWill/TippeTop/" .. DIR }) do
  local f = io.open(dir .. "tippe-top-ball.obj", "r")
  if f then f:close(); DIR = dir; break end
end

local G = 981
local R, RS, LS = 1.5, 0.6, 0.6            -- ball radius, stem-tip radius, how far the tip stands out
local MASS = 0.015
local I3 = (2 / 3) * MASS * R * R          -- about the stem
local I1 = 0.9 * I3                        -- across it
local IV = { I1, I3, I1 }
local INERTIA = btVector3(I1, I3, I1)

local function envnum(n, d) return tonumber(os.getenv(n) or "") or d end
local function param(...) v:addParam(...) end
param("fast spin", envnum("TT_FAST", 40), 10, 60, 1, "turns per second for the red and green tops")
param("slow spin", envnum("TT_SLOW", 15), 5, 40, 1, "turns per second for the blue top")
param("friction", envnum("TT_MU", 0.2), 0.05, 0.6, 0.05, "sliding friction at the table")
param("spin friction", envnum("TT_SPINF", 0.5), 0, 5, 0.1, "slowing of the spin about the upright, rad/s^2")
param("rolling", envnum("TT_ROLL", 30), 0, 100, 1, "rolling resistance lever arm, microns")
param("speed", 1, 0.05, 2, 0.05, "simulated seconds per real second (Z: 1/4 <-> 1)")
param("steps", 4800, 2400, 9600, 600, "physics steps per simulated second")

local STEP, NSTEPS, FRAME_DT = 1 / 4800, 80, 1 / 60
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
-- the table and three dishes
-- ---------------------------------------------------------------------
local TABLE_Y = 0
local SPACING, DISH_R = 37, 16.5
local function block(sx, sy, sz, x, y, z, col, solid, q)
  local c = Cube(sx, sy, sz, 0)
  c.trans = btTransform(q or btQuaternion(0, 0, 0, 1), btVector3(x, y, z))
  c.col = col
  if solid then c.friction = 1.0 else c.collides = false end
  v:add(c)
  return c
end
block(118, 3, 44, 0, TABLE_Y - 1.5, 0, "#7a4a24", true)                 -- the top
for _, x in ipairs({ -54, 54 }) do
  for _, z in ipairs({ -18, 18 }) do block(3, 72, 3, x, TABLE_Y - 3 - 36, z, "#4e2e15") end
end
local floor = Plane(0, 1, 0, TABLE_Y - 75, 300)
floor.col = "#3b3f45"
v:add(floor)
-- each dish: a dark felt disc and a low rim of 24 blocks, round the spot
-- the top starts on (it wanders a little as it spins)
local DISH_COL = "#1f3a4d"
for k = -1, 1 do
  local cx = k * SPACING
  local felt = Cylinder(DISH_R, 0.2, 0)
  felt.trans = btTransform(btQuaternion(btVector3(1, 0, 0), math.pi / 2), btVector3(cx, TABLE_Y + 0.1, 0))
  felt.col = DISH_COL
  felt.collides = false
  v:add(felt)
  for i = 0, 23 do
    local a = 2 * math.pi * i / 24
    block(4.2, 1.6, 1.0, cx + DISH_R * math.cos(a), TABLE_Y + 0.8, DISH_R * math.sin(a), "#b8932e", true,
          btQuaternion(btVector3(0, 1, 0), -a + math.pi / 2))
  end
end
common.setCamera(btVector3(0, 31, 56), btVector3(0, 0, 3))

-- ---------------------------------------------------------------------
-- the tops
-- ---------------------------------------------------------------------
local TOPS = {
  { name = "Left (red), spun fast -- turns over, stands on its stem",          short = "Left",   x = -SPACING,
    col = "#d8282f", kind = "tippe-top", A = 0.45, spin = "fast spin" },
  { name = "Middle (blue), spun slowly -- gets halfway, can't stand up",       short = "Middle", x = 0,
    col = "#2f5fd0", kind = "tippe-top", A = 0.45, spin = "slow spin" },
  { name = "Right (green), weight at the centre -- never turns over",        short = "Right",  x = SPACING,
    col = "#2f9a4a", kind = "centred", A = 0.06, spin = "fast spin" },
}
local SHAPES = {}
local function shapeFor(A)
  if SHAPES[A] then return SHAPES[A] end
  local s = btCompoundShape(true)
  s:addChildShape(btTransform(btQuaternion(0, 0, 0, 1), btVector3(0, A, 0)), btSphereShape(R))
  -- the stem: a capsule from inside the ball (0.6 R above its centre) to its tip
  local y0, y1 = A + 0.6 * R, A + R + LS
  s:addChildShape(btTransform(btQuaternion(0, 0, 0, 1), btVector3(0, (y0 + y1) / 2, 0)),
                  btCapsuleShape(RS, (y1 - y0) - 2 * RS))
  SHAPES[A] = s
  return s
end
-- the angle at which the stem's tip meets the table with the ball still on it
local THETA_BOTH = math.deg(math.acos(-(R - RS) / (R + LS - RS)))

local KEYS = {}
for _, t in ipairs(TOPS) do
  local m = Mesh(DIR .. t.kind .. "-ball.obj", 0, false)
  local body = btRigidBody(MASS, btDefaultMotionState(btTransform(btQuaternion(0, 0, 0, 1),
                           btVector3(t.x, TABLE_Y + R - t.A, 0))), shapeFor(t.A), INERTIA)
  m.body = body
  m.col = t.col
  v:add(m)
  body:setActivationState(4)
  body:setDamping(0, 0)
  body:setRestitution(0)
  body:setFlags(0)                         -- gyroscopic term: Euler's equations below
  body:setContactProcessingThreshold(0.001)
  local stem = Mesh(DIR .. t.kind .. "-stem.obj", 0, false)
  stem.col = "#5a3418"
  stem.collides = false
  v:add(stem)
  local stripe = Mesh(DIR .. t.kind .. "-stripe.obj", 0, false)
  stripe.col = "#f4f0e6"
  stripe.collides = false
  v:add(stripe)
  t.m, t.body, t.stem, t.stripe = m, body, stem, stripe
end
local function applyMaterials()
  for _, t in ipairs(TOPS) do t.body:setFriction(v:getParam("friction")) end
end
applyMaterials()

local function basis(b)
  local B = b:getCenterOfMassTransform():getBasis()
  return { B:getColumn(0), B:getColumn(1), B:getColumn(2) }
end

local t = 0
-- spun by hand: stem up, tilted 12 degrees (each its own way), spinning
-- about its stem
local function spinThem()
  t = 0
  print(string.format("\n--- spun: fast %.0f turns/s, slow %.0f turns/s ---",
                      v:getParam("fast spin"), v:getParam("slow spin")))
  for i, top in ipairs(TOPS) do
    local tilt = math.rad(12)
    local dir = 2 * math.pi * (i - 1) / 3 + math.random() * 0.5
    local axis = btVector3(math.cos(dir), 0, math.sin(dir))
    local q = btQuaternion(axis, tilt)
    -- the ball's centre a radius above the table; the centre of mass A below
    -- it along the stem (the stem's direction read back from the body)
    local b = top.body
    b:setCenterOfMassTransform(btTransform(q, btVector3(top.x, TABLE_Y + R, 0)))
    local c = basis(b)[2]
    b:setCenterOfMassTransform(btTransform(q, btVector3(top.x - c.x * top.A, TABLE_Y + R - c.y * top.A, -c.z * top.A)))
    local W = 2 * math.pi * v:getParam(top.spin)
    b:setLinearVelocity(btVector3(0, 0, 0))
    b:setAngularVelocity(btVector3(c.x * W, c.y * W, c.z * W))
    b:clearForces()
    b:activate(true)
    top.state, top.since, top.events = "spinning on its ball", 0, {}
    print("  " .. top.name)
  end
end

-- ---------------------------------------------------------------------
-- before every physics step: Euler's equations, then spin friction
-- ---------------------------------------------------------------------
local function deriv(w)
  return { (IV[2] - IV[3]) * w[2] * w[3] / IV[1], (IV[3] - IV[1]) * w[3] * w[1] / IV[2],
           (IV[1] - IV[2]) * w[1] * w[2] / IV[3] }
end
local function plus(a, d, s) return { a[1] + s * d[1], a[2] + s * d[2], a[3] + s * d[3] } end
local SPIN_DECEL, DELTA = 0.5, 0.001
local function prestep(h)
  for _, top in ipairs(TOPS) do
    local b = top.body
    local c = basis(b)
    local W = b:getAngularVelocity()
    local w = { c[1].x * W.x + c[1].y * W.y + c[1].z * W.z, c[2].x * W.x + c[2].y * W.y + c[2].z * W.z,
                c[3].x * W.x + c[3].y * W.y + c[3].z * W.z }
    local k1 = deriv(w); local k2 = deriv(plus(w, k1, h / 2)); local k3 = deriv(plus(w, k2, h / 2)); local k4 = deriv(plus(w, k3, h))
    for i = 1, 3 do w[i] = w[i] + h / 6 * (k1[i] + 2 * k2[i] + 2 * k3[i] + k4[i]) end
    local wx = c[1].x * w[1] + c[2].x * w[2] + c[3].x * w[3]
    local wy = c[1].y * w[1] + c[2].y * w[2] + c[3].y * w[3]
    local wz = c[1].z * w[1] + c[2].z * w[2] + c[3].z * w[3]
    -- spin friction: the spin about the upright slows a little
    if SPIN_DECEL > 0 then
      local d = math.min(math.abs(wy), SPIN_DECEL * h)
      wy = wy - (wy > 0 and d or -d)
    end
    -- rolling resistance: a constant moment delta*m*g against rolling (the
    -- horizontal part of the spin), about the contact, as in the other
    -- exhibits (the contact taken straight below the centre of mass)
    local V = b:getLinearVelocity()
    local vx, vy, vz = V.x, V.y, V.z
    local wh = math.sqrt(wx * wx + wz * wz)
    if DELTA > 0 and wh > 0 then
      local _, rr, _ = getPosXYZ(top.m)
      rr = rr - TABLE_Y
      local ax, az = wx / wh, wz / wh
      local d = ax * c[2].x + az * c[2].z
      local Ih = I1 + (I3 - I1) * d * d
      local dw = math.min(wh, DELTA * MASS * G / (Ih + MASS * rr * rr) * h)
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
-- after every frame: the stem and stripes follow, and what each is doing
-- ---------------------------------------------------------------------
local function tiltOf(top)
  local c = basis(top.body)[2]
  return math.deg(math.acos(math.max(-1, math.min(1, c.y))))
end
local function stateOf(top, th)
  local _, y, _ = getPosXYZ(top.m)
  local c = basis(top.body)[2]
  local ballLow = y + c.y * top.A - R          -- the bottom of the ball, above the table
  if th < 60 then return "spinning on its ball" end
  if th < THETA_BOTH - 3 then return "on its side" end
  if ballLow > 0.02 then return "up on its stem" end
  return "on its ball and stem"
end
local LOGF = os.getenv("TT_LOG") and io.open(os.getenv("TT_LOG"), "w")
if LOGF then LOGF:write("t,which,tilt_deg,spin_up_rad_s,com_y\n") end
v:postSim(function(N)
  t = t + FRAME_DT
  for k, top in ipairs(TOPS) do
    copyTrans(top.stem, top.m)
    copyTrans(top.stripe, top.m)
    local th = tiltOf(top)
    top.tilt = th
    local s = stateOf(top, th)
    -- (a new state counts once it has lasted a third of a second)
    if s ~= top.state then
      if top.pending ~= s then top.pending, top.pendingSince = s, t end
      if t - top.pendingSince >= 0.33 then
        top.state, top.since, top.pending = s, top.pendingSince, nil
        print(string.format("  %-6s %s at %5.1f s (stem %.0f deg from up)", top.short, s, top.since, th))
      end
    else
      top.pending = nil
    end
    if LOGF and N % 4 == 0 then
      local _, y, _ = getPosXYZ(top.m)
      local px, _, pz = getPosXYZ(top.m)
      LOGF:write(string.format("%.4f,%d,%.2f,%.2f,%.4f,%.2f,%.2f\n", t, k, th, top.body:getAngularVelocity().y, y, px - top.x, pz))
    end
  end
  if N % 120 == 0 then
    local parts = {}
    for _, top in ipairs(TOPS) do
      parts[#parts + 1] = string.format("%s %3.0f deg %4.1f t/s", top.short, top.tilt,
                                        math.abs(top.body:getAngularVelocity().y) / (2 * math.pi))
    end
    print(string.format("t=%5.1fs  stem from up, spin: %s", t, table.concat(parts, " | ")))
  end
  if LOGF and N % 60 == 0 then LOGF:flush() end
end)

-- ---------------------------------------------------------------------
-- keys, sliders
-- ---------------------------------------------------------------------
v:addShortcut("R", function(N) spinThem() end)
v:addShortcut("Z", function(N)
  local sp = v:getParam("speed") < 0.5 and 1 or 0.25
  v:addParam("speed", sp, 0.05, 2, 0.05, "simulated seconds per real second (Z: 1/4 <-> 1)")
  applyTiming()
end)
v:onParamChanged(function(N, name, value)
  if name == "speed" or name == "steps" then applyTiming() end
  if name == "friction" then applyMaterials() end
  if name == "spin friction" then SPIN_DECEL = value end
  if name == "rolling" then DELTA = value * 1e-4 end
end)
SPIN_DECEL = v:getParam("spin friction")
DELTA = v:getParam("rolling") * 1e-4

v:setHelpText(table.concat({
  "The tippe top (Euler's Cabinet of Curiosities)",
  "",
  "Spun on its ball, stem up, a tippe top turns itself over",
  "and spins on its stem, raising its centre of mass.",
  "Sliding friction at the table does it.",
  "",
  "Left (red):    spun fast -- turns over and stands up on",
  "               its stem; slowing down, it sinks back",
  "Middle (blue): spun slowly -- turns over as far as lying",
  "               on ball and stem, but can't stand up",
  "Right (green): weight at the ball's centre -- never turns",
  "",
  "All three end stem up again in about a minute and a half.",
  "",
  "R   spin them again",
  "Z   slow motion (1/4) <-> real time",
  "",
  "Sliders: fast spin, slow spin (turns/s), friction,",
  "spin friction (how fast it slows), rolling, speed, steps.",
  "Rest the mouse on a top to see what it's doing.",
}, "\n"))

-- mouse hover (needs a bpp with v:onHover): rest the mouse on a top
if v.onHover then
  for _, top in ipairs(TOPS) do KEYS[objectKey(top.m)] = top end
  v:onHover(function(N, obj, x, y, z)
    local top = KEYS[objectKey(obj)]
    if not top then return nil end
    return string.format("%s\n%s for %.1f s\nstem %.0f deg from up, spinning %.1f turns/s",
                         top.name, top.state or "?", t - (top.since or 0), top.tilt or 0,
                         math.abs(top.body:getAngularVelocity().y) / (2 * math.pi))
  end)
end

spinThem()
