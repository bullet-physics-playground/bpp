--
-- The Spinning Egg -- Euler's Cabinet of Curiosities
--
-- Spin a hard-boiled egg fast on its side and it rises up onto its end,
-- raising its centre of mass, and spins there like a top. Friction does it,
-- as with the tippe top: the egg slides on the table as it spins, and the
-- drag of the table at the sliding point tips it up. A raw egg, spun the
-- same way, won't: the liquid inside doesn't turn with the shell, and the
-- egg barely spins at all.
--
-- Three eggs, each in its own dish:
--   left   (red band)    hard-boiled, spun at 25 turns a second: rises onto
--                        its end within a second or so, spins there, and
--                        falls back once it has slowed down enough
--   middle (blue band)   hard-boiled, spun at 40 turns a second: rises the
--                        same way, and as it rises it jumps -- leaves the
--                        table for a hundredth of a second or two, a
--                        fraction of a millimetre (its lamp lights when it's
--                        off the table)
--   right  (green band)  raw, spun at 25 turns a second: the inside takes up
--                        the spin, the egg slows to a few turns a second and
--                        stays on its side. Two seconds in, a finger stops it
--                        for a moment: let go, it starts turning again by
--                        itself (the inside is still turning)
--
-- Theory, printed as each egg stands up:
--  * Jellett's constant. The egg's angular momentum about its centre of
--    mass, dotted with the line from its contact point to the centre, J =
--    L . (G - P), hardly changes as the egg rises (Moffatt and Shimomura,
--    2002: it's kept while the spin is fast). Spinning on its side, J = A b
--    W0 (A the moment of inertia across the egg, b its half-width); standing
--    up, J = C a W (C about its long axis, a its half-length). So standing
--    up it spins at  W = W0 A b / (C a): 4% faster than it started, though
--    it has lost a fifth of its energy to friction and raised its centre.
--  * Energy: all the energy lost goes to friction at the table (the console
--    adds up the work friction did, and compares).
--  * Jumps: Shimomura and colleagues (2006) measured spinning eggs leaving
--    the table, a fraction of a millimetre for up to a few hundredths of a
--    second, spun at about 2000 turns a minute. Here the egg jumps when spun
--    faster than about 32 turns a second (1900 a minute).
--
-- THE EGG: a spheroid 5.7 cm long and 4.3 cm across, 58 g (the shape the
-- theory has; a real egg is a little fatter at one end). The raw one: a
-- shell 0.35 mm thick, 10% of the mass; the liquid inside.
--
-- PHYSICS
--  * Bullet moves each egg (a rigid body); everything else is done here,
--    before every physics step: Euler's equations for its spin (Bullet's
--    gyroscopic term off), gravity, and its contact with the table, worked
--    out exactly for the spheroid: its lowest point, an impulse that stops
--    it going into the table (and none pulling it down: so it can leave the
--    table), and sliding friction (0.3) at that point, solved together a few
--    times over, as Bullet solves its contacts. The dish's rim the same way.
--  * Spin friction: a small moment against the spin about the upright
--    (0.01 cm times the push of the table). Rolling resistance: a moment
--    against rolling (0.01 cm times the push).
--  * The raw egg: its shell is the rigid body; the liquid that has to move
--    when the shell turns about an axis across it (the shell isn't round) is
--    added to it; the rest of the liquid is a second body inside, free to
--    turn, dragged round by the shell with a time constant of 1.5 s.
--  * 4800 physics steps a second.
--
-- Keys
--   R   spin them again
--   S   stop all three with a finger for a moment, then let go
--   V   views: all three; the left, middle and right egg close up
--   Z   slow motion (1/4) <-> real time
--
-- Units: centimetres, kilograms, seconds.
-- Headless testing: EG_SPIN, EG_FAST (turns/s), EG_MU, EG_KAPPA, EG_DELTA (microns),
-- EG_SPEED, EG_STEPS, EG_TOUCH_AT (s), EG_LOG=file.csv.
--

local common = require "common"

local DIR = "spinning-egg-meshes/"
for _, dir in ipairs({ DIR, "demo/WyomingWill/SpinningEgg/" .. DIR }) do
  local f = io.open(dir .. "egg-shell.obj", "r")
  if f then f:close(); DIR = dir; break end
end

local G = 981
local A, B = 2.85, 2.15                    -- half-length, half-width
local MASS = 0.058
local IA = MASS * (A * A + B * B) / 5      -- across the long axis
local IC = 2 * MASS * B * B / 5            -- about it
-- the raw egg
local SHELL_T, SHELL_FRAC, TAU_C = 0.035, 0.10, 1.5

local function envnum(n, d) return tonumber(os.getenv(n) or "") or d end
local function param(...) v:addParam(...) end
param("spin", envnum("EG_SPIN", 25), 5, 50, 1, "turns per second for the left (hard-boiled) and right (raw) eggs")
param("fast spin", envnum("EG_FAST", 40), 5, 50, 1, "turns per second for the middle egg")
param("friction", envnum("EG_MU", 0.3), 0.05, 0.8, 0.05, "sliding friction at the table")
param("spin friction", envnum("EG_KAPPA", 100), 0, 400, 10, "moment against the spin about the upright, microns x push")
param("rolling", envnum("EG_DELTA", 100), 0, 400, 10, "rolling resistance lever arm, microns")
param("speed", envnum("EG_SPEED", 1), 0.05, 2, 0.05, "simulated seconds per real second (Z: 1/4 <-> 1)")
param("steps", envnum("EG_STEPS", 4800), 2400, 9600, 600, "physics steps per simulated second")

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
local MU, KAPPA, DELTA

-- ---------------------------------------------------------------------
-- the table and three dishes
-- ---------------------------------------------------------------------
local TABLE_Y = 0
local SPACING, DISH_R = 37, 16.5
local Q0 = btQuaternion(0, 0, 0, 1)
local function block(sx, sy, sz, x, y, z, col, q)
  local c = Cube(sx, sy, sz, 0)
  c.trans = btTransform(q or Q0, btVector3(x, y, z))
  c.col = col
  c.collides = false
  v:add(c)
  return c
end
block(118, 3, 44, 0, TABLE_Y - 1.5, 0, "#7a4a24")                     -- the top
for _, x in ipairs({ -54, 54 }) do
  for _, z in ipairs({ -18, 18 }) do block(3, 72, 3, x, TABLE_Y - 3 - 36, z, "#4e2e15") end
end
local floor = Plane(0, 1, 0, TABLE_Y - 75, 300)
floor.col = "#3b3f45"
v:add(floor)
-- each dish: a dark felt disc and a low rim (the rim's inside at DISH_R)
local DISH_COL, RIM_COL, RIM_H = "#1f3a4d", "#b8932e", 2.5
local LAMP_OFF, LAMP_ON = "#4a4232", "#fff6b0"
local lamps = {}
for k = -1, 1 do
  local cx = k * SPACING
  local felt = Cylinder(DISH_R, 0.2, 0)
  felt.trans = btTransform(btQuaternion(btVector3(1, 0, 0), math.pi / 2), btVector3(cx, TABLE_Y - 0.09, 0))
  felt.col = DISH_COL
  felt.collides = false
  v:add(felt)
  for i = 0, 23 do
    local a = 2 * math.pi * i / 24
    block(4.4, RIM_H, 0.6, cx + (DISH_R + 0.3) * math.cos(a), TABLE_Y + RIM_H / 2, (DISH_R + 0.3) * math.sin(a), RIM_COL,
          btQuaternion(btVector3(0, 1, 0), -a + math.pi / 2))
  end
  -- the lamp behind the dish: lit while the egg is off the table
  block(0.8, 5, 0.8, cx + 12, TABLE_Y + 2.5, -DISH_R - 4, "#5a3418")
  local lamp = Sphere(1.3, 0)
  lamp.trans = btTransform(Q0, btVector3(cx + 12, TABLE_Y + 6.2, -DISH_R - 4))
  lamp.col = LAMP_OFF
  lamp.collides = false
  v:add(lamp)
  lamps[k + 2] = lamp
end
-- the views (V): all three; each egg close up
local VIEW = 0
local function setView()
  if VIEW == 0 then
    common.setCamera(btVector3(0, 42, 78), btVector3(0, 0, 2))
  else
    local x = (VIEW - 2) * SPACING
    common.setCamera(btVector3(x, 10, 21), btVector3(x, 2.5, 0))
  end
end
setView()

-- ---------------------------------------------------------------------
-- the eggs
-- ---------------------------------------------------------------------
-- the raw egg's shell and liquid (a thin shell: its moments by summing
-- over its surface)
local function shellMoments(a, b, m)
  local n, area, Sax, Str = 2000, 0, 0, 0
  for i = 1, n do
    local u = math.pi * (i - 0.5) / n
    local rho, y = b * math.sin(u), a * math.cos(u)
    local ds = math.sqrt((b * math.cos(u)) ^ 2 + (a * math.sin(u)) ^ 2) * math.pi / n
    local dA = 2 * math.pi * rho * ds
    area = area + dA
    Sax = Sax + dA * rho * rho                   -- x^2 + z^2 averaged round: rho^2
    Str = Str + dA * (y * y + rho * rho / 2)     -- y^2 + z^2: z^2 averages rho^2/2
  end
  return m * Str / area, m * Sax / area
end
local MS, MF = MASS * SHELL_FRAC, MASS * (1 - SHELL_FRAC)
local AI, BI = A - SHELL_T, B - SHELL_T
local IS_T, IS_A = shellMoments(A - SHELL_T / 2, B - SHELL_T / 2, MS)
local I_ADD = MF / 5 * (AI * AI - BI * BI) ^ 2 / (AI * AI + BI * BI)   -- liquid that must move as the shell turns across
local I_LIQ = MF / 5 * 4 * AI * AI * BI * BI / (AI * AI + BI * BI)    -- the rest: free to turn (across the egg)
local C_LIQ = I_LIQ / TAU_C

local EGGS = {
  { name = "Left (red), hard-boiled, spun at 25 turns a second -- stands up on its end", short = "Left", x = -SPACING,
    band = "#c8282f", shell = "#f6eedf", raw = false, spin = "spin" },
  { name = "Middle (blue), hard-boiled, spun at 40 turns a second -- stands up, jumping as it rises", short = "Middle", x = 0,
    band = "#2f5fd0", shell = "#f6eedf", raw = false, spin = "fast spin" },
  { name = "Right (green), raw, spun at 25 turns a second -- stays on its side", short = "Right", x = SPACING,
    band = "#2f9a4a", shell = "#ead6b8", raw = true, spin = "spin" },
}
local KEYS = {}
for i, e in ipairs(EGGS) do
  if e.raw then e.I = { IS_T + I_ADD, IS_A, IS_T + I_ADD } else e.I = { IA, IC, IA } end
  local m = Mesh(DIR .. "egg-shell.obj", 0, false)
  local body = btRigidBody(MASS, btDefaultMotionState(btTransform(Q0, btVector3(e.x, 10, 0))), btSphereShape(B),
                           btVector3(e.I[1], e.I[2], e.I[3]))
  m.body = body
  m.col = e.shell
  m.collides = false                       -- (its contacts are worked out below)
  v:add(m)
  body:setActivationState(4)
  body:setDamping(0, 0)
  body:setFlags(1)                         -- no world gravity, no gyroscopic term: both below
  body:setGravity(btVector3(0, 0, 0))
  local bands = Mesh(DIR .. "egg-bands.obj", 0, false)
  bands.col = e.band
  bands.collides = false
  v:add(bands)
  -- the finger that stops it (out of sight till then)
  local finger = Cylinder(0.85, 7, 0)
  finger.trans = btTransform(btQuaternion(btVector3(1, 0, 0), math.pi / 2), btVector3(e.x, -500, 0))
  finger.col = "#e2b493"
  finger.collides = false
  v:add(finger)
  local tip = Sphere(0.85, 0)
  tip.trans = btTransform(Q0, btVector3(e.x, -500, 0))
  tip.col = "#e2b493"
  tip.collides = false
  v:add(tip)
  e.tip = tip
  e.m, e.b, e.bands, e.lamp, e.finger = m, body, bands, lamps[i], finger
  e.wf = { 0, 0, 0 }                       -- the raw egg's liquid: its turning
end

-- ---------------------------------------------------------------------
-- before every physics step
-- ---------------------------------------------------------------------
-- (each egg's state is unpacked into plain numbers in the table e: the
-- basis c1..c3 (its axes in the world, the long axis c2), v, w, its
-- centre g)
local function load(e)
  local b = e.b
  local Bm = b:getCenterOfMassTransform():getBasis()
  local c1, c2, c3 = Bm:getColumn(0), Bm:getColumn(1), Bm:getColumn(2)
  e.c1x, e.c1y, e.c1z = c1.x, c1.y, c1.z
  e.c2x, e.c2y, e.c2z = c2.x, c2.y, c2.z
  e.c3x, e.c3y, e.c3z = c3.x, c3.y, c3.z
  local W, V, P = b:getAngularVelocity(), b:getLinearVelocity(), b:getCenterOfMassPosition()
  e.wx, e.wy, e.wz = W.x, W.y, W.z
  e.vx, e.vy, e.vz = V.x, V.y, V.z
  e.gx, e.gy, e.gz = P.x, P.y, P.z
end
-- the inverse moment of inertia, in the world, times (x, y, z)
local function iinv(e, x, y, z)
  local I = e.I
  local s1 = (e.c1x * x + e.c1y * y + e.c1z * z) / I[1]
  local s2 = (e.c2x * x + e.c2y * y + e.c2z * z) / I[2]
  local s3 = (e.c3x * x + e.c3y * y + e.c3z * z) / I[3]
  return s1 * e.c1x + s2 * e.c2x + s3 * e.c3x, s1 * e.c1y + s2 * e.c2y + s3 * e.c3y, s1 * e.c1z + s2 * e.c2z + s3 * e.c3z
end
local function imul(e, x, y, z)
  local I = e.I
  local s1 = (e.c1x * x + e.c1y * y + e.c1z * z) * I[1]
  local s2 = (e.c2x * x + e.c2y * y + e.c2z * z) * I[2]
  local s3 = (e.c3x * x + e.c3y * y + e.c3z * z) * I[3]
  return s1 * e.c1x + s2 * e.c2x + s3 * e.c3x, s1 * e.c1y + s2 * e.c2y + s3 * e.c3y, s1 * e.c1z + s2 * e.c2z + s3 * e.c3z
end
-- the point of the egg furthest along (dx, dy, dz), from its centre
local function support(e, dx, dy, dz)
  local d1 = e.c1x * dx + e.c1y * dy + e.c1z * dz
  local d2 = e.c2x * dx + e.c2y * dy + e.c2z * dz
  local d3 = e.c3x * dx + e.c3y * dy + e.c3z * dz
  local s1, s2, s3 = B * d1, A * d2, B * d3
  local n = math.sqrt(s1 * s1 + s2 * s2 + s3 * s3)
  local x1, x2, x3 = B * s1 / n, A * s2 / n, B * s3 / n
  return x1 * e.c1x + x2 * e.c2x + x3 * e.c3x, x1 * e.c1y + x2 * e.c2y + x3 * e.c3y, x1 * e.c1z + x2 * e.c2z + x3 * e.c3z
end
-- an impulse (jx, jy, jz) at r from the centre
local function apply(e, rx, ry, rz, jx, jy, jz)
  e.vx, e.vy, e.vz = e.vx + jx / MASS, e.vy + jy / MASS, e.vz + jz / MASS
  local ax, ay, az = iinv(e, ry * jz - rz * jy, rz * jx - rx * jz, rx * jy - ry * jx)
  e.wx, e.wy, e.wz = e.wx + ax, e.wy + ay, e.wz + az
  -- (its part in Jellett's J, if it isn't the table's)
  return ry * jz - rz * jy, rz * jx - rx * jz, rx * jy - ry * jx
end
-- the change of velocity at r for a unit impulse along (dx, dy, dz), along (ex, ey, ez)
local function resp(e, rx, ry, rz, dx, dy, dz, ex, ey, ez)
  local ax, ay, az = iinv(e, ry * dz - rz * dy, rz * dx - rx * dz, rx * dy - ry * dx)
  local ux, uy, uz = ay * rz - az * ry, az * rx - ax * rz, ax * ry - ay * rx
  return (dx / MASS + ux) * ex + (dy / MASS + uy) * ey + (dz / MASS + uz) * ez
end
local function velAt(e, rx, ry, rz)
  return e.vx + e.wy * rz - e.wz * ry, e.vy + e.wz * rx - e.wx * rz, e.vz + e.wx * ry - e.wy * rx
end
-- a contact at r (from the centre), normal n (out of the surface it
-- touches), gap: sequential impulses, the normal one never pulling, the
-- friction one within mu times it. Returns the normal impulse, and the work
-- friction did.
local ITER = 6
local function contact(e, rx, ry, rz, nx, ny, nz, gap, h)
  -- two directions along the surface
  local tx, ty, tz
  if math.abs(ny) > 0.7 then tx, ty, tz = 1, 0, 0 else tx, ty, tz = 0, 1, 0 end
  local d = tx * nx + ty * ny + tz * nz
  tx, ty, tz = tx - d * nx, ty - d * ny, tz - d * nz
  local tl = math.sqrt(tx * tx + ty * ty + tz * tz)
  tx, ty, tz = tx / tl, ty / tl, tz / tl
  local sx, sy, sz = ny * tz - nz * ty, nz * tx - nx * tz, nx * ty - ny * tx
  local Kn = resp(e, rx, ry, rz, nx, ny, nz, nx, ny, nz)
  local a11 = resp(e, rx, ry, rz, tx, ty, tz, tx, ty, tz)
  local a12 = resp(e, rx, ry, rz, sx, sy, sz, tx, ty, tz)
  local a21 = resp(e, rx, ry, rz, tx, ty, tz, sx, sy, sz)
  local a22 = resp(e, rx, ry, rz, sx, sy, sz, sx, sy, sz)
  local det = a11 * a22 - a12 * a21
  -- (closing a gap in one step is allowed; a little overlap is pushed out
  -- gently)
  local bias = gap < 0 and (-0.2 * gap / h) or (-gap / h)
  local jn, jt, js, W, Wn = 0, 0, 0, 0, 0
  for _ = 1, ITER do
    local ux, uy, uz = velAt(e, rx, ry, rz)
    local un = ux * nx + uy * ny + uz * nz
    local jnew = math.max(0, jn + (bias - un) / Kn)
    local dj = jnew - jn
    jn = jnew
    if dj ~= 0 then apply(e, rx, ry, rz, dj * nx, dj * ny, dj * nz) end
    ux, uy, uz = velAt(e, rx, ry, rz)
    Wn = Wn + dj * (un + ux * nx + uy * ny + uz * nz) / 2
    local ut, us = ux * tx + uy * ty + uz * tz, ux * sx + uy * sy + uz * sz
    local nt = jt - (a22 * ut - a12 * us) / det
    local ns = js - (-a21 * ut + a11 * us) / det
    local nl = math.sqrt(nt * nt + ns * ns)
    local lim = MU * jn
    if nl > lim then nt, ns = nt * lim / nl, ns * lim / nl end
    local dt_, ds_ = nt - jt, ns - js
    jt, js = nt, ns
    if dt_ ~= 0 or ds_ ~= 0 then
      apply(e, rx, ry, rz, dt_ * tx + ds_ * sx, dt_ * ty + ds_ * sy, dt_ * tz + ds_ * sz)
      local vx, vy, vz = velAt(e, rx, ry, rz)
      W = W + dt_ * (ut + (vx * tx + vy * ty + vz * tz)) / 2 + ds_ * (us + (vx * sx + vy * sy + vz * sz)) / 2
    end
  end
  return jn, W, Wn, jt * tx + js * sx, jt * ty + js * sy, jt * tz + js * sz
end

-- Euler's equations, torque-free (RK4), for the egg's own spin
local function euler(e, h)
  local I1, I2, I3 = e.I[1], e.I[2], e.I[3]
  local w1 = e.c1x * e.wx + e.c1y * e.wy + e.c1z * e.wz
  local w2 = e.c2x * e.wx + e.c2y * e.wy + e.c2z * e.wz
  local w3 = e.c3x * e.wx + e.c3y * e.wy + e.c3z * e.wz
  local p, q, r = (I2 - I3) / I1, (I3 - I1) / I2, (I1 - I2) / I3
  local k11, k12, k13 = p * w2 * w3, q * w3 * w1, r * w1 * w2
  local a1, a2, a3 = w1 + h / 2 * k11, w2 + h / 2 * k12, w3 + h / 2 * k13
  local k21, k22, k23 = p * a2 * a3, q * a3 * a1, r * a1 * a2
  a1, a2, a3 = w1 + h / 2 * k21, w2 + h / 2 * k22, w3 + h / 2 * k23
  local k31, k32, k33 = p * a2 * a3, q * a3 * a1, r * a1 * a2
  a1, a2, a3 = w1 + h * k31, w2 + h * k32, w3 + h * k33
  local k41, k42, k43 = p * a2 * a3, q * a3 * a1, r * a1 * a2
  w1 = w1 + h / 6 * (k11 + 2 * k21 + 2 * k31 + k41)
  w2 = w2 + h / 6 * (k12 + 2 * k22 + 2 * k32 + k42)
  w3 = w3 + h / 6 * (k13 + 2 * k23 + 2 * k33 + k43)
  e.wx = e.c1x * w1 + e.c2x * w2 + e.c3x * w3
  e.wy = e.c1y * w1 + e.c2y * w2 + e.c3y * w3
  e.wz = e.c1z * w1 + e.c2z * w2 + e.c3z * w3
end

local t = 0
local function step(e, h)
  load(e)
  e.vy = e.vy - G * h
  euler(e, h)
  -- the raw egg: the shell drags the liquid round, and the liquid the shell
  if e.raw then
    local f = e.wf
    local tx, ty, tz = C_LIQ * (f[1] - e.wx), C_LIQ * (f[2] - e.wy), C_LIQ * (f[3] - e.wz)
    local ax, ay, az = iinv(e, tx * h, ty * h, tz * h)
    e.wx, e.wy, e.wz = e.wx + ax, e.wy + ay, e.wz + az
    f[1], f[2], f[3] = f[1] - tx * h / I_LIQ, f[2] - ty * h / I_LIQ, f[3] - tz * h / I_LIQ
  end
  -- held by a finger: kept from moving along the table or turning
  if e.held then e.vx, e.vz, e.wx, e.wy, e.wz = 0, 0, 0, 0, 0 end
  -- the table, at its lowest point
  local rx, ry, rz = support(e, 0, -1, 0)
  local gap = e.gy + ry - TABLE_Y
  local N = 0
  if gap < 0.05 then
    local jn, W, Wn = contact(e, rx, ry, rz, 0, 1, 0, gap, h)
    e.Wf, e.Wn = e.Wf + W, e.Wn + Wn
    N = jn / h
    if N > 0 then
      -- spin friction and rolling resistance: moments against turning about
      -- the upright and about a level axis
      local o0x, o0y, o0z = e.wx, e.wy, e.wz
      local _, Iy, _ = iinv(e, 0, 1, 0)
      local ty = math.min(math.abs(e.wy) / Iy, KAPPA * N * h)
      ty = e.wy > 0 and -ty or ty
      local tx, tz = 0, 0
      local wh = math.sqrt(e.wx * e.wx + e.wz * e.wz)
      if wh > 1e-9 then
        local ux, uz = e.wx / wh, e.wz / wh
        local px, _, pz = iinv(e, ux, 0, uz)
        local tq = math.min(wh / (px * ux + pz * uz), DELTA * N * h)
        tx, tz = -tq * ux, -tq * uz
      end
      local ax, ay, az = iinv(e, tx, ty, tz)
      e.wx, e.wy, e.wz = e.wx + ax, e.wy + ay, e.wz + az
      e.Wf = e.Wf + tx * (o0x + e.wx) / 2 + ty * (o0y + e.wy) / 2 + tz * (o0z + e.wz) / 2
      -- (their part in Jellett's J: the moment, along G - P)
      e.Jc = e.Jc - (tx * rx + ty * ry + tz * rz)
    end
  end
  e.N, e.gap = N, gap
  -- the dish's rim: the egg's furthest point out from the dish's middle
  local hx, hz = e.gx - e.x, e.gz
  local hl = math.sqrt(hx * hx + hz * hz)
  if hl > DISH_R - 2 * A then
    hx, hz = hx / hl, hz / hl
    local qx, qy, qz = support(e, hx, 0, hz)
    local out = hl + qx * hx + qz * hz
    local rgap = DISH_R - out
    if rgap < 0.05 and e.gy + qy < TABLE_Y + RIM_H then
      local jn, W, Wn, fx, fy, fz = contact(e, qx, qy, qz, -hx, 0, -hz, rgap, h)
      e.Wrim = e.Wrim + W + Wn
      -- (and the rim's part in J: its moment about the centre, along G - P)
      local jx, jy, jz = -hx * jn + fx, fy, -hz * jn + fz
      local mx, my, mz = qy * jz - qz * jy, qz * jx - qx * jz, qx * jy - qy * jx
      e.Jc = e.Jc - (mx * rx + my * ry + mz * rz)
      if jn > 0 then e.bumped = true end
    end
  end
  e.b:setLinearVelocity(btVector3(e.vx, e.vy, e.vz))
  e.b:setAngularVelocity(btVector3(e.wx, e.wy, e.wz))
  -- off the table? (no push from it, and a gap under it)
  e.tt = e.tt + h
  if N == 0 and gap > 1e-5 then
    if not e.air then e.air = { t0 = e.tt, hmax = 0 } end
    e.air.hmax = math.max(e.air.hmax, gap)
    e.airFrame = true
  elseif e.air then
    local dur = e.tt - e.air.t0
    if dur > 2e-4 and e.spunAt then
      local J = e.jumps
      J.n = J.n + 1
      J.first = J.first or e.air.t0
      J.last = e.tt
      J.longest = math.max(J.longest, dur)
      J.highest = math.max(J.highest, e.air.hmax)
    end
    e.air = nil
  end
end

-- ---------------------------------------------------------------------
-- what each egg is doing
-- ---------------------------------------------------------------------
local function tiltOf(e)
  return math.deg(math.acos(math.min(1, math.abs(e.c2y))))
end
local function energy(e)
  local Lx, Ly, Lz = imul(e, e.wx, e.wy, e.wz)
  local E = 0.5 * (Lx * e.wx + Ly * e.wy + Lz * e.wz) + 0.5 * MASS * (e.vx * e.vx + e.vy * e.vy + e.vz * e.vz)
            + MASS * G * (e.gy - TABLE_Y)
  if e.raw then E = E + 0.5 * I_LIQ * (e.wf[1] ^ 2 + e.wf[2] ^ 2 + e.wf[3] ^ 2) end
  return E
end
-- Jellett's J = L . (G - P), and what it says the spin about the upright
-- should be at this tilt (the egg turning about the upright)
local function jellett(e)
  local rx, ry, rz = support(e, 0, -1, 0)
  local Lx, Ly, Lz = imul(e, e.wx, e.wy, e.wz)
  local J = -(Lx * rx + Ly * ry + Lz * rz)
  local nx, ny, nz = imul(e, 0, 1, 0)
  return J, -(nx * rx + ny * ry + nz * rz)
end
local function turns(w) return w / (2 * math.pi) end
local MICROJ = 10                          -- kg cm^2/s^2 in a microjoule

local function spinThem()
  t = 0
  print(string.format("\n--- spun: left and right %.0f turns/s, middle %.0f turns/s; friction %.2f ---",
                      v:getParam("spin"), v:getParam("fast spin"), MU))
  for i, e in ipairs(EGGS) do
    -- on its side (its long axis level), tipped up 3 degrees, each its own
    -- way round; spun about the upright
    local yaw = 2 * math.pi * (i - 1) / 3 + 0.4
    local q = btQuaternion(btVector3(0, 1, 0), yaw) * btQuaternion(btVector3(0, 0, 1), math.pi / 2 - math.rad(3))
    e.b:setCenterOfMassTransform(btTransform(q, btVector3(e.x, 0, 0)))
    load(e)
    local _, ry, _ = support(e, 0, -1, 0)
    e.b:setCenterOfMassTransform(btTransform(q, btVector3(e.x, TABLE_Y - ry, 0)))
    e.m.trans = btTransform(q, btVector3(e.x, TABLE_Y - ry, 0))
    local W = 2 * math.pi * v:getParam(e.spin)
    e.b:setLinearVelocity(btVector3(0, 0, 0))
    e.b:setAngularVelocity(btVector3(0, W, 0))
    e.wf = { 0, 0, 0 }
    load(e)
    e.W0, e.E0 = W, energy(e)
    e.J0 = jellett(e)
    e.Jc, e.Wf, e.Wrim, e.Wn = 0, 0, 0, 0
    e.tt, e.air, e.held, e.bumped = 0, nil, nil, false
    e.jumps = { n = 0, longest = 0, highest = 0 }
    e.state, e.since, e.pending, e.stood, e.spunAt = "spinning on its side", 0, nil, nil, 0
    e.touch, e.shared = nil, nil
    print("  " .. e.name)
    if not e.raw then
      print(string.format("         Jellett's J = A b W0 = %.2f; standing up it should spin W0 A b / (C a) = %.2f turns/s (x %.3f)",
                          e.J0, turns(W * IA * B / (IC * A)), IA * B / (IC * A)))
    else
      local Iy = e.I[1]
      print(string.format("         its shell is spun, not the liquid: sharing the spin, they should turn at %.1f turns/s (I shell %.4f, liquid %.4f)",
                          turns(W * Iy / (Iy + I_LIQ)), Iy, I_LIQ))
    end
  end
end

-- a finger stops an egg (its shell) for a moment
local TOUCH, TOUCH_AT = 0.3, envnum("EG_TOUCH_AT", 2.0)
local function touch(e)
  e.held = true
  e.touch = { t0 = t, wf = e.raw and e.wf[2] or 0 }
end

local function stateOf(e, th)
  if e.held then return "held still by a finger" end
  local sp = math.sqrt(e.wx * e.wx + e.wy * e.wy + e.wz * e.wz)
  local vv = math.sqrt(e.vx * e.vx + e.vy * e.vy + e.vz * e.vz)
  if sp < 0.5 and vv < 0.5 then return "at rest" end
  if th < 15 then return "standing on its end" end
  if th < 60 then return e.stood and "falling back" or "rising" end
  return e.stood and "back on its side" or "spinning on its side"
end

local LOGF = os.getenv("EG_LOG") and io.open(os.getenv("EG_LOG"), "w")
if LOGF then LOGF:write("t,egg,tilt_deg,spin_up_turns,N_over_mg,gap_um,J,E,x,z\n") end
local restAll = 0
v:postSim(function(N_)
  t = t + FRAME_DT
  local allRest = true
  for k, e in ipairs(EGGS) do
    load(e)
    e.tt = t
    copyTrans(e.bands, e.m)
    -- the lamp: lit while the egg is off the table (held a few frames, so
    -- a jump shows)
    if e.airFrame then e.lampOn = 6 end
    e.airFrame = false
    local on = (e.lampOn or 0) > 0
    if on ~= e.lampWas then e.lamp.col = on and LAMP_ON or LAMP_OFF; e.lampWas = on end
    if e.lampOn then e.lampOn = e.lampOn - 1 end
    -- the finger: on the egg's top while it holds it
    if e.held then
      local _, ty, _ = support(e, 0, 1, 0)
      e.finger.trans = btTransform(btQuaternion(btVector3(1, 0, 0), math.pi / 2), btVector3(e.gx, e.gy + ty + 4.35, e.gz))
      e.tip.trans = btTransform(Q0, btVector3(e.gx, e.gy + ty + 0.85, e.gz))
      e.fingerShown = true
    elseif e.fingerShown then
      e.finger.trans = btTransform(btQuaternion(btVector3(1, 0, 0), math.pi / 2), btVector3(e.x, -500, 0))
      e.tip.trans = btTransform(Q0, btVector3(e.x, -500, 0))
      e.fingerShown = nil
    end
    -- the finger lets go
    if e.held and t - e.touch.t0 >= TOUCH then
      e.held = nil
      e.touch.released = t
      e.touch.wf = e.raw and e.wf[2] or 0
      e.touch.peak = 0
      if e.raw then
        local Iy = e.I[1]
        e.touch.expect = e.touch.wf * I_LIQ / (Iy + I_LIQ)
      end
    end
    if e.touch and e.touch.released and not e.touch.done then
      e.touch.peak = math.max(e.touch.peak, math.abs(e.wy))
      if t - e.touch.released > 1.5 then
        e.touch.done = true
        if e.raw then
          print(string.format("  %-6s stopped by a finger for %.1f s and let go: the liquid inside was still turning at %.1f turns/s,\n" ..
                              "         and the egg starts turning again by itself, up to %.2f turns/s (sharing the liquid's spin, it would\n" ..
                              "         be %.2f with no spin friction at the table)",
                              e.short, TOUCH, turns(e.touch.wf), turns(e.touch.peak), turns(e.touch.expect)))
        else
          print(string.format("  %-6s stopped by a finger for %.1f s and let go: it stays stopped (%.2f turns/s)",
                              e.short, TOUCH, turns(e.touch.peak)))
        end
      end
    end
    -- the raw egg: once its liquid has taken up the spin
    if e.raw and not e.shared and t >= 1.2 then
      e.shared = true
      print(string.format("  %-6s at %.1f s: the egg turns at %.2f turns/s, the liquid inside at %.2f (the table's spin friction slowing both)",
                          e.short, t, turns(e.wy), turns(e.wf[2])))
    end
    local th = tiltOf(e)
    e.tilt = th
    local s = stateOf(e, th)
    if s ~= "at rest" then allRest = false end
    if s ~= e.state then
      if e.pending ~= s then e.pending, e.pendingSince = s, t end
      if t - e.pendingSince >= 0.25 then
        e.state, e.since, e.pending = s, e.pendingSince, nil
        local extra = ""
        if s == "standing on its end" and not e.stood then
          e.stood = true
          local J, Iup = jellett(e)
          local Jkept = e.J0 + e.Jc
          local lost, fr = e.E0 - energy(e), -(e.Wf + e.Wrim + e.Wn)
          extra = string.format("\n         spinning %.2f turns/s; by Jellett's J it should be %.2f (J %.2f, from %.2f%s: %+.2f%%)" ..
                                "\n         energy lost %.2f microjoules; friction took %.2f, landings %.2f: %.2f (%.2f%% apart)",
                                turns(math.abs(e.wy)), turns(Jkept / Iup), J, e.J0,
                                math.abs(e.Jc) > 0.005 * e.J0 and string.format(", %.2f with spin friction", Jkept) or "",
                                (J - Jkept) / Jkept * 100, lost / MICROJ, -(e.Wf + e.Wrim) / MICROJ, -e.Wn / MICROJ, fr / MICROJ,
                                (lost - fr) / fr * 100)
          if e.bumped then extra = extra .. "\n         (it touched the dish's rim)" end
          local Jp = e.jumps
          if Jp.n > 0 then
            extra = extra .. string.format("\n         it jumped %d times as it rose (%.2f to %.2f s): longest %.1f ms, highest %.2f mm off the table",
                                           Jp.n, Jp.first, Jp.last, Jp.longest * 1000, Jp.highest * 10)
          elseif not e.raw then
            extra = extra .. "\n         it never left the table"
          end
        end
        print(string.format("  %-6s %s at %5.2f s (tilt %.0f deg, spinning %.1f turns/s)%s", e.short, s, e.since, th,
                            turns(math.abs(e.wy)), extra))
      end
    else
      e.pending = nil
    end
    if LOGF and N_ % 2 == 0 then
      LOGF:write(string.format("%.4f,%d,%.3f,%.4f,%.4f,%.2f,%.4f,%.4f,%.3f,%.3f\n", t, k, th, turns(e.wy), e.N / (MASS * G),
                               math.max(0, e.gap) * 1e4, (jellett(e)), energy(e), e.gx - e.x, e.gz))
    end
  end
  -- the raw egg is touched by a finger 2 s in
  if math.abs(t - TOUCH_AT) < FRAME_DT / 2 then touch(EGGS[3]) end
  -- all at rest a while (or a minute gone): again
  restAll = allRest and restAll + FRAME_DT or 0
  if restAll > 3 or t > 90 then spinThem() end
end)

v:preSim(function(N_)
  for k = 1, NSTEPS - 1 do
    for _, e in ipairs(EGGS) do step(e, STEP) end
    v:stepSimulation(STEP, 0, STEP)
  end
  for _, e in ipairs(EGGS) do step(e, STEP) end
end)

-- ---------------------------------------------------------------------
-- keys, sliders, help
-- ---------------------------------------------------------------------
local function applyMaterials()
  MU = v:getParam("friction")
  KAPPA = v:getParam("spin friction") * 1e-4
  DELTA = v:getParam("rolling") * 1e-4
end
applyMaterials()
v:addShortcut("R", function(N_) spinThem() end)
v:addShortcut("V", function(N_) VIEW = (VIEW + 1) % 4; setView() end)
v:addShortcut("S", function(N_) for _, e in ipairs(EGGS) do touch(e) end end)
v:addShortcut("Z", function(N_)
  local sp = v:getParam("speed") < 0.5 and 1 or 0.25
  v:addParam("speed", sp, 0.05, 2, 0.05, "simulated seconds per real second (Z: 1/4 <-> 1)")
  applyTiming()
end)
v:onParamChanged(function(N_, name, value)
  if name == "speed" or name == "steps" then applyTiming() end
  if name == "friction" or name == "spin friction" or name == "rolling" then applyMaterials() end
end)

v:setHelpText(table.concat({
  "The spinning egg (Euler's Cabinet of Curiosities)",
  "",
  "Spun fast on its side, a hard-boiled egg rises onto its",
  "end. Friction at the table does it. A raw egg won't.",
  "",
  "Left (red):    hard-boiled, 25 turns/s -- stands up",
  "Middle (blue): hard-boiled, 40 turns/s -- stands up, and",
  "               jumps as it rises (its lamp lights when",
  "               it's off the table)",
  "Right (green): raw, 25 turns/s -- slows and stays down.",
  "               A finger stops it at 2 s: let go, it",
  "               starts again (the inside still turns)",
  "",
  "R   spin them again",
  "S   stop all three with a finger for a moment",
  "V   views: all three; each egg close up",
  "Z   slow motion (1/4) <-> real time",
  "",
  "Sliders: spin, fast spin (turns/s), friction, spin",
  "friction, rolling, speed, steps.",
  "Rest the mouse on an egg to see what it's doing.",
}, "\n"))

if v.onHover then
  for _, e in ipairs(EGGS) do KEYS[objectKey(e.m)] = e; KEYS[objectKey(e.bands)] = e end
  v:onHover(function(N_, obj, x, y, z)
    local e = KEYS[objectKey(obj)]
    if not e then return nil end
    local s = string.format("%s\n%s for %.1f s\ntilted %.0f deg from upright, spinning %.1f turns/s",
                            e.name, e.state or "?", t - (e.since or 0), e.tilt or 0, turns(math.abs(e.wy or 0)))
    if e.raw then s = s .. string.format("\nthe liquid inside: %.1f turns/s", turns(e.wf[2])) end
    return s
  end)
end

spinThem()
