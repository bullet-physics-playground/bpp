--
-- The Spinning Egg -- Euler's Gallery
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
--                        its end within a second, spins there, and leans
--                        further and further as it slows, till it's back on
--                        its side
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
--  * The rise: while the egg slides, Moffatt and Shimomura's gyroscopic
--    balance gives J dtheta/dt = -mu M g h^2 (theta its axis from upright, h
--    the height of its centre): the console times the rise from 60 to 30
--    degrees and compares (spin friction taking J as it goes).
--  * Energy: all the energy lost goes to friction at the table (the console
--    adds up the work friction did, and compares).
--  * Jumps: Shimomura and colleagues (2006) measured spinning eggs leaving
--    the table, a fraction of a millimetre for up to a few hundredths of a
--    second, spun at about 2000 turns a minute. Here the egg jumps when spun
--    faster than about 30 turns a second (1800 a minute).
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
--    table), and friction (0.3) at that point: enough to stop it slipping,
--    if it can, and otherwise sliding friction against the slip (Coulomb),
--    solved together a few times over, as Bullet solves its contacts. The
--    dish's rim the same way.
--  * Spin friction: a small moment against the spin about the upright
--    (0.01 cm times the push of the table). Rolling resistance: a moment
--    against rolling (0.01 cm times the push). Both in the same solve.
--  * The step is second-order and the same run backwards as forwards (see
--    "THE STEP" below): no slipping where the egg touches half a step on,
--    where Bullet's move is centred; the gyroscopic term and sliding
--    friction taken at the mean of before and after. So a rolling egg
--    keeps its energy (with no spin friction or rolling resistance, to
--    0.002 microjoules over 9 s) and the run is the same at any step.
--  * The raw egg: its shell is the rigid body; the liquid that has to move
--    when the shell turns about an axis across it (the shell isn't round) is
--    added to it; the rest of the liquid is a second body inside, free to
--    turn, dragged round by the shell with a time constant of 1.5 s.
--  * Each egg starts on its side tipped up 6 degrees, spun about the
--    upright. Nearer level, friction can hold the point of contact still:
--    the egg then rolls on its side without sliding and never rises (at 25
--    turns a second and friction 0.3, from 3 degrees or less; the faster
--    the spin or the less the friction, the nearer level). Near that edge,
--    when the egg breaks free and rises depends a little on the step: from
--    3 degrees the left egg never rises, at any step from 2400 to 38400 a
--    second; from 3.5 it rises at 0.38 s with 4800 steps a second, 0.42 s
--    with 19200. From 6 degrees it slides from the start and rises the same
--    way at any step.
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
-- EG_SPEED, EG_STEPS, EG_TILT (degrees up from level at the start), EG_BALANCED=1 (start
-- the hard-boiled eggs in gyroscopic balance), EG_TOUCH_AT (s), EG_LOG=file.csv,
-- EG_STATE=time:file (the left egg's state then, for reconstruction/rolling-check.py).
--

local common = require "common"

local DIR = "spinning-egg-meshes/"
for _, dir in ipairs({ DIR, "demo/WyomingWill/EulersGallery/exhibits/SpinningEgg/" .. DIR }) do
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
-- tipped up from level at the start (see PHYSICS)
local TILT0 = envnum("EG_TILT", 6)
local BALANCED = (os.getenv("EG_BALANCED") or "") ~= ""
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

-- ---------------------------------------------------------------------
-- a pause at every start: one frame to put everything in place, then it
-- all stands still for HOLD_S seconds (half a second), so you see how it begins --
-- bpp's own physics step stopped too (a zero time step) -- and then it
-- carries on from there, exactly as if there had been no pause
-- ---------------------------------------------------------------------
local HOLD_FRAMES = math.floor(envnum("HOLD_S", 0.5) * 60 + 0.5)
local holdArm, holdLeft, holdNow = false, 0, false
local function holdStart() holdArm, holdLeft = true, 0 end
local function holdPre()            -- first thing before each step: true while it stands still
  if holdLeft > 0 then
    holdLeft = holdLeft - 1
    holdNow = true
    v.timeStep = 0
    return true
  end
  if holdNow then holdNow = false; applyTiming() end
  if holdArm then holdArm, holdLeft = false, HOLD_FRAMES end
  return false
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
-- the same, its long axis along (px, py, pz) (for a spheroid that's all it
-- takes)
local function supportAx(px, py, pz, dx, dy, dz)
  local d2 = px * dx + py * dy + pz * dz
  local n = math.sqrt(B * B * (dx * dx + dy * dy + dz * dz - d2 * d2) + A * A * d2 * d2)
  local k = (A * A - B * B) * d2
  return (B * B * dx + k * px) / n, (B * B * dy + k * py) / n, (B * B * dz + k * pz) / n
end
-- its long axis half a step on, turning at (wx, wy, wz) (as Bullet turns it)
local function midAxis(e, h, wx, wy, wz)
  local wl = math.sqrt(wx * wx + wy * wy + wz * wz)
  if wl < 1e-12 then return e.c2x, e.c2y, e.c2z end
  local kx, ky, kz = wx / wl, wy / wl, wz / wl
  local c, s = math.cos(wl * h / 2), math.sin(wl * h / 2)
  local px, py, pz = e.c2x, e.c2y, e.c2z
  local kp = (kx * px + ky * py + kz * pz) * (1 - c)
  return px * c + (ky * pz - kz * py) * s + kx * kp, py * c + (kz * px - kx * pz) * s + ky * kp,
         pz * c + (kx * py - ky * px) * s + kz * kp
end
-- a contact, normal n (out of the surface it touches), gap. The impulses
-- act at r (from the centre: where it touches now); it mustn't go into the
-- surface, nor (if friction can stop it) slip, at b (where it will touch
-- half a step on: see "the step", below; b = r for the rim). Sequential
-- impulses, the normal one never pulling. If mu times the normal impulse
-- can't stop the slip, it slides, and friction is mu times the normal
-- impulse against the slip at r at the time of the kick: the mean of the
-- slip before the step (e.pv, e.pw: the velocities it started with) and
-- after. With moments: spin friction and rolling resistance too, in the
-- same solve, so that the egg rolls after them. Returns the normal impulse,
-- the friction impulse, and the moments' angular impulse.
local ITER = 6
local function contact(e, rx, ry, rz, nx, ny, nz, gap, h, bx, by, bz, moments)
  bx, by, bz = bx or rx, by or ry, bz or rz
  -- (all in plain numbers, for speed: the egg's velocities, and its inverse
  -- moment of inertia in the world as a matrix)
  local vx, vy, vz, wx, wy, wz = e.vx, e.vy, e.vz, e.wx, e.wy, e.wz
  local pvx, pvy, pvz, pwx, pwy, pwz = e.pvx, e.pvy, e.pvz, e.pwx, e.pwy, e.pwz
  local c1x, c1y, c1z, c2x, c2y, c2z, c3x, c3y, c3z = e.c1x, e.c1y, e.c1z, e.c2x, e.c2y, e.c2z, e.c3x, e.c3y, e.c3z
  local I = e.I
  local i1, i2, i3 = 1 / I[1], 1 / I[2], 1 / I[3]
  local m11 = c1x * c1x * i1 + c2x * c2x * i2 + c3x * c3x * i3
  local m12 = c1x * c1y * i1 + c2x * c2y * i2 + c3x * c3y * i3
  local m13 = c1x * c1z * i1 + c2x * c2z * i2 + c3x * c3z * i3
  local m22 = c1y * c1y * i1 + c2y * c2y * i2 + c3y * c3y * i3
  local m23 = c1y * c1z * i1 + c2y * c2z * i2 + c3y * c3z * i3
  local m33 = c1z * c1z * i1 + c2z * c2z * i2 + c3z * c3z * i3
  local im = 1 / MASS
  -- two directions along the surface
  local tx, ty, tz
  if math.abs(ny) > 0.7 then tx, ty, tz = 1, 0, 0 else tx, ty, tz = 0, 1, 0 end
  local d = tx * nx + ty * ny + tz * nz
  tx, ty, tz = tx - d * nx, ty - d * ny, tz - d * nz
  local tl = math.sqrt(tx * tx + ty * ty + tz * tz)
  tx, ty, tz = tx / tl, ty / tl, tz / tl
  local sx, sy, sz = ny * tz - nz * ty, nz * tx - nx * tz, nx * ty - ny * tx
  -- the turning a unit impulse at r gives, along n, t and s
  local qx, qy, qz = ry * nz - rz * ny, rz * nx - rx * nz, rx * ny - ry * nx
  local anx, any, anz = m11 * qx + m12 * qy + m13 * qz, m12 * qx + m22 * qy + m23 * qz, m13 * qx + m23 * qy + m33 * qz
  qx, qy, qz = ry * tz - rz * ty, rz * tx - rx * tz, rx * ty - ry * tx
  local atx, aty, atz = m11 * qx + m12 * qy + m13 * qz, m12 * qx + m22 * qy + m23 * qz, m13 * qx + m23 * qy + m33 * qz
  qx, qy, qz = ry * sz - rz * sy, rz * sx - rx * sz, rx * sy - ry * sx
  local asx, asy, asz = m11 * qx + m12 * qy + m13 * qz, m12 * qx + m22 * qy + m23 * qz, m13 * qx + m23 * qy + m33 * qz
  -- the change of velocity at b (and at r), along n, t, s, for unit impulses
  local function k(ax, ay, az, px, py, pz, ex, ey, ez)
    return (ay * pz - az * py) * ex + (az * px - ax * pz) * ey + (ax * py - ay * px) * ez
  end
  local Kn = im + k(anx, any, anz, bx, by, bz, nx, ny, nz)
  local a11 = im + k(atx, aty, atz, bx, by, bz, tx, ty, tz)
  local a12 = k(asx, asy, asz, bx, by, bz, tx, ty, tz)
  local a21 = k(atx, aty, atz, bx, by, bz, sx, sy, sz)
  local a22 = im + k(asx, asy, asz, bx, by, bz, sx, sy, sz)
  local det = a11 * a22 - a12 * a21
  local b11 = im + k(atx, aty, atz, rx, ry, rz, tx, ty, tz)
  local b12 = k(asx, asy, asz, rx, ry, rz, tx, ty, tz)
  local b21 = k(atx, aty, atz, rx, ry, rz, sx, sy, sz)
  local b22 = im + k(asx, asy, asz, rx, ry, rz, sx, sy, sz)
  local ux0 = pvx + pwy * rz - pwz * ry
  local uy0 = pvy + pwz * rx - pwx * rz
  local uz0 = pvz + pwx * ry - pwy * rx
  local s0t, s0s = ux0 * tx + uy0 * ty + uz0 * tz, ux0 * sx + uy0 * sy + uz0 * sz
  -- (the moments: at most what stops the turning, about the upright and
  -- about the level)
  local ycap, hcap
  if moments then
    ycap = math.abs(wy) / m22
    hcap = math.sqrt(pwx * pwx + pwz * pwz)
  end
  -- (closing a gap in one step is allowed; a little overlap is pushed out
  -- gently)
  local bias = gap < 0 and (-0.2 * gap / h) or (-gap / h)
  local jn, jt, js, mx, my, mz = 0, 0, 0, 0, 0, 0
  for _ = 1, ITER do
    local un = (vx + wy * bz - wz * by) * nx + (vy + wz * bx - wx * bz) * ny + (vz + wx * by - wy * bx) * nz
    local jnew = jn + (bias - un) / Kn
    if jnew < 0 then jnew = 0 end
    local dj = jnew - jn
    jn = jnew
    if dj ~= 0 then
      vx, vy, vz = vx + dj * nx * im, vy + dj * ny * im, vz + dj * nz * im
      wx, wy, wz = wx + dj * anx, wy + dj * any, wz + dj * anz
    end
    if moments and jn > 0 then
      -- spin friction against the turning about the upright, kappa times
      -- the push; rolling resistance against the level part of the turning
      -- (the mean of before and after), delta times the push
      local ny_ = KAPPA * jn
      if ny_ > ycap then ny_ = ycap end
      if pwy > 0 then ny_ = -ny_ end
      local nx_, nz_ = 0, 0
      local hx, hz = (pwx + wx) / 2, (pwz + wz) / 2
      local wh = math.sqrt(hx * hx + hz * hz)
      if wh > 1e-9 then
        local ux_, uz_ = hx / wh, hz / wh
        local tq = DELTA * jn
        local cap = hcap / ((m11 * ux_ + m13 * uz_) * ux_ + (m13 * ux_ + m33 * uz_) * uz_)
        if tq > cap then tq = cap end
        nx_, nz_ = -tq * ux_, -tq * uz_
      end
      local dx, dy, dz = nx_ - mx, ny_ - my, nz_ - mz
      if dx ~= 0 or dy ~= 0 or dz ~= 0 then
        wx = wx + m11 * dx + m12 * dy + m13 * dz
        wy = wy + m12 * dx + m22 * dy + m23 * dz
        wz = wz + m13 * dx + m23 * dy + m33 * dz
        mx, my, mz = nx_, ny_, nz_
      end
    end
    local ux, uy, uz = vx + wy * bz - wz * by, vy + wz * bx - wx * bz, vz + wx * by - wy * bx
    local ut, us = ux * tx + uy * ty + uz * tz, ux * sx + uy * sy + uz * sz
    local nt = jt - (a22 * ut - a12 * us) / det
    local ns = js - (-a21 * ut + a11 * us) / det
    local nl = math.sqrt(nt * nt + ns * ns)
    local lim = MU * jn
    if nl > lim then
      -- sliding: against the mean slip at r, before and after (a few
      -- rounds, as "after" depends on the impulse)
      nt, ns = nt * lim / nl, ns * lim / nl
      ux, uy, uz = vx + wy * rz - wz * ry, vy + wz * rx - wx * rz, vz + wx * ry - wy * rx
      local ct, cs = ux * tx + uy * ty + uz * tz, ux * sx + uy * sy + uz * sz
      for _ = 1, 3 do
        local mt = s0t + ct + b11 * (nt - jt) + b21 * (ns - js)
        local ms = s0s + cs + b12 * (nt - jt) + b22 * (ns - js)
        local ml = math.sqrt(mt * mt + ms * ms)
        if ml > 0 then nt, ns = -lim * mt / ml, -lim * ms / ml end
      end
    end
    local dt_, ds_ = nt - jt, ns - js
    jt, js = nt, ns
    if dt_ ~= 0 or ds_ ~= 0 then
      vx, vy, vz = vx + (dt_ * tx + ds_ * sx) * im, vy + (dt_ * ty + ds_ * sy) * im, vz + (dt_ * tz + ds_ * sz) * im
      wx, wy, wz = wx + dt_ * atx + ds_ * asx, wy + dt_ * aty + ds_ * asy, wz + dt_ * atz + ds_ * asz
    end
  end
  e.vx, e.vy, e.vz, e.wx, e.wy, e.wz = vx, vy, vz, wx, wy, wz
  return jn, jt * tx + js * sx, jt * ty + js * sy, jt * tz + js * sz, mx, my, mz
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
-- the change in w over h from Euler's equations, the gyroscopic term taken
-- at (ox, oy, oz) (with the mean of w before and after: the implicit
-- midpoint rule, which keeps the free egg's energy and angular momentum
-- exactly)
local function eulerMid(e, h, ox, oy, oz)
  local I1, I2, I3 = e.I[1], e.I[2], e.I[3]
  local w1 = e.c1x * ox + e.c1y * oy + e.c1z * oz
  local w2 = e.c2x * ox + e.c2y * oy + e.c2z * oz
  local w3 = e.c3x * ox + e.c3y * oy + e.c3z * oz
  local k1, k2, k3 = h * (I2 - I3) / I1 * w2 * w3, h * (I3 - I1) / I2 * w3 * w1, h * (I1 - I2) / I3 * w1 * w2
  return e.c1x * k1 + e.c2x * k2 + e.c3x * k3, e.c1y * k1 + e.c2y * k2 + e.c3y * k3,
         e.c1z * k1 + e.c2z * k2 + e.c3z * k3
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

-- the rise by Moffatt and Shimomura's gyroscopic balance: sliding, J dtheta/dt
-- = -mu M g h^2, h the height of the centre; spin friction takes J at kappa M g
-- h. The time from theta1 to theta2 (from upright), starting with J.
local function msRise(J, th1, th2)
  local n, T = 600, 0
  local dth = (th1 - th2) / n
  for i = 1, n do
    local th = th1 - (i - 0.5) * dth
    local hh = math.sqrt((A * math.cos(th)) ^ 2 + (B * math.sin(th)) ^ 2)
    local dt = J * dth / (MU * MASS * G * hh * hh)
    J = J - KAPPA * MASS * G * hh * dt
    T = T + dt
  end
  return T
end

local t = 0
local COS30 = math.cos(math.rad(30))
local function step(e, h)
  load(e)
  -- the rise, timed from 60 to 30 degrees from upright (the hard-boiled eggs)
  if not e.raw and not e.r30 then
    local cy = math.abs(e.c2y)
    if not e.r60 then
      if cy > 0.5 then e.r60, e.J60 = e.tt, (jellett(e)) end
    elseif cy > COS30 then
      e.r30 = e.tt
    end
  end
  -- THE STEP. Bullet then moves the egg on with the velocities this leaves:
  -- the centre by h v, and turns it by h w. So those velocities belong to
  -- the middle of Bullet's move, half a step on, and that's where the egg
  -- must roll without slipping: at the lowest point half a step on. (Until
  -- 17 Oct 2026 it was the lowest point now: that's only first-order right,
  -- and up on its end, where the egg rolls, the error tipped it slowly
  -- upright, faster the bigger the step.) The impulses act now, at the
  -- lowest point now; Euler's gyroscopic term is taken at the mean of the
  -- turning before and after (so is sliding friction, in contact()). Each
  -- step is then the same run backwards as forwards, and second-order
  -- right, rolling or sliding. The "after" isn't known until the contact
  -- is solved: so solve it once with a first guess (Euler's equations by
  -- RK4), then again from the start with the turning that gave.
  e.pvx, e.pvy, e.pvz, e.pwx, e.pwy, e.pwz = e.vx, e.vy, e.vz, e.wx, e.wy, e.wz
  e.vy = e.vy - G * h
  euler(e, h)
  -- the raw egg: the shell drags the liquid round, and the liquid the shell
  local lx, ly, lz = 0, 0, 0
  if e.raw then
    local f = e.wf
    local tx, ty, tz = C_LIQ * (f[1] - e.wx), C_LIQ * (f[2] - e.wy), C_LIQ * (f[3] - e.wz)
    lx, ly, lz = iinv(e, tx * h, ty * h, tz * h)
    e.wx, e.wy, e.wz = e.wx + lx, e.wy + ly, e.wz + lz
    f[1], f[2], f[3] = f[1] - tx * h / I_LIQ, f[2] - ty * h / I_LIQ, f[3] - tz * h / I_LIQ
  end
  -- held by a finger: kept from moving along the table or turning
  if e.held then e.vx, e.vz, e.wx, e.wy, e.wz = 0, 0, 0, 0, 0 end
  -- the table, at its lowest point
  local rx, ry, rz = support(e, 0, -1, 0)
  local gap = e.gy + ry - TABLE_Y
  local N = 0
  -- (the impulses, for the work they did: table, its friction, the moments;
  -- the rim's, and where)
  local tjn, tfx, tfy, tfz, tmx, tmy, tmz = 0, 0, 0, 0, 0, 0, 0
  local rjx, rjy, rjz, rqx, rqy, rqz = 0, 0, 0, 0, 0, 0
  if gap < 0.05 then
    local vx, vy, vz = e.vx, e.vy, e.vz
    local px, py, pz = midAxis(e, h, e.wx, e.wy, e.wz)
    local bx, by, bz = supportAx(px, py, pz, 0, -1, 0)
    contact(e, rx, ry, rz, 0, 1, 0, gap, h, bx, by, bz, true)
    -- (again, from the start)
    local ox, oy, oz = e.wx, e.wy, e.wz
    local gx, gy, gz = eulerMid(e, h, (e.pwx + ox) / 2, (e.pwy + oy) / 2, (e.pwz + oz) / 2)
    e.vx, e.vy, e.vz = vx, vy, vz
    e.wx, e.wy, e.wz = e.pwx + gx + lx, e.pwy + gy + ly, e.pwz + gz + lz
    if e.held then e.vx, e.vz, e.wx, e.wy, e.wz = 0, 0, 0, 0, 0 end
    px, py, pz = midAxis(e, h, ox, oy, oz)
    bx, by, bz = supportAx(px, py, pz, 0, -1, 0)
    tjn, tfx, tfy, tfz, tmx, tmy, tmz = contact(e, rx, ry, rz, 0, 1, 0, gap, h, bx, by, bz, true)
    N = tjn / h
    -- (spin friction's and rolling resistance's part in Jellett's J: their
    -- moment, along G - P)
    e.Jc = e.Jc - (tmx * rx + tmy * ry + tmz * rz)
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
      local jn, fx, fy, fz = contact(e, qx, qy, qz, -hx, 0, -hz, rgap, h)
      rjx, rjy, rjz, rqx, rqy, rqz = -hx * jn + fx, fy, -hz * jn + fz, qx, qy, qz
      -- (and the rim's part in J: its moment about the centre, along G - P)
      local mx, my, mz = qy * rjz - qz * rjy, qz * rjx - qx * rjz, qx * rjy - qy * rjx
      e.Jc = e.Jc - (mx * rx + my * ry + mz * rz)
      if jn > 0 then e.bumped = true end
    end
  end
  -- the work the impulses did: each impulse times the velocity where it
  -- acts, the mean of the step's start and end (with Euler's term taken at
  -- that mean, that's exactly what they did to the egg's energy)
  local mvx, mvy, mvz = (e.pvx + e.vx) / 2, (e.pvy + e.vy) / 2, (e.pvz + e.vz) / 2
  local mwx, mwy, mwz = (e.pwx + e.wx) / 2, (e.pwy + e.wy) / 2, (e.pwz + e.wz) / 2
  if tjn > 0 then
    local ux, uy, uz = mvx + mwy * rz - mwz * ry, mvy + mwz * rx - mwx * rz, mvz + mwx * ry - mwy * rx
    e.Wf = e.Wf + tfx * ux + tfy * uy + tfz * uz + tmx * mwx + tmy * mwy + tmz * mwz
    e.Wn = e.Wn + tjn * uy
  end
  if rjx ~= 0 or rjy ~= 0 or rjz ~= 0 then
    local ux, uy, uz = mvx + mwy * rqz - mwz * rqy, mvy + mwz * rqx - mwx * rqz, mvz + mwx * rqy - mwy * rqx
    e.Wrim = e.Wrim + rjx * ux + rjy * uy + rjz * uz
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
local function turns(w) return w / (2 * math.pi) end
local MICROJ = 10                          -- kg cm^2/s^2 in a microjoule

local function spinThem()
  holdStart()
  t = 0
  print(string.format("\n--- spun: left and right %.0f turns/s, middle %.0f turns/s; friction %.2f ---",
                      v:getParam("spin"), v:getParam("fast spin"), MU))
  for i, e in ipairs(EGGS) do
    -- on its side (its long axis level), tipped up TILT0 degrees, each its
    -- own way round; spun about the upright
    local yaw = 2 * math.pi * (i - 1) / 3 + 0.4
    local q = btQuaternion(btVector3(0, 1, 0), yaw) * btQuaternion(btVector3(0, 0, 1), math.pi / 2 - math.rad(TILT0))
    e.b:setCenterOfMassTransform(btTransform(q, btVector3(e.x, 0, 0)))
    load(e)
    local _, ry, _ = support(e, 0, -1, 0)
    e.b:setCenterOfMassTransform(btTransform(q, btVector3(e.x, TABLE_Y - ry, 0)))
    e.m.trans = btTransform(q, btVector3(e.x, TABLE_Y - ry, 0))
    local W = 2 * math.pi * v:getParam(e.spin)
    e.b:setLinearVelocity(btVector3(0, 0, 0))
    e.b:setAngularVelocity(btVector3(0, W, 0))
    if BALANCED and not e.raw then
      -- (headless testing: started in Moffatt and Shimomura's gyroscopic
      -- balance, C n = A W cos(theta), n its spin about its long axis: a
      -- little more spin about that axis, and no wobble to start with)
      load(e)
      local ps = (IA / IC - 1) * W * e.c2y
      e.b:setAngularVelocity(btVector3(ps * e.c2x, W + ps * e.c2y, ps * e.c2z))
    end
    e.wf = { 0, 0, 0 }
    load(e)
    e.W0, e.E0 = W, energy(e)
    e.J0 = jellett(e)
    e.Jc, e.Wf, e.Wrim, e.Wn = 0, 0, 0, 0
    e.tt, e.air, e.held, e.bumped = 0, nil, nil, false
    e.r60, e.r30, e.J60 = nil, nil, nil
    e.jumps = { n = 0, longest = 0, highest = 0 }
    e.state, e.since, e.pending, e.stood, e.spunAt = "spinning on its side", 0, nil, nil, 0
    e.touch, e.shared = nil, nil
    print("  " .. e.name)
    if not e.raw then
      print(string.format("         Jellett's J = %.2f (A b W0 = %.2f lying level); standing up it should spin W0 A b / (C a) = %.2f turns/s (x %.3f)",
                          e.J0, IA * B * W, turns(W * IA * B / (IC * A)), IA * B / (IC * A)))
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
-- (EG_STATE=time:file: the left egg's state at that time, for
-- reconstruction/rolling-check.py)
local STATE_T, STATE_F = (os.getenv("EG_STATE") or ""):match("^([%d.]+):(.+)$")
STATE_T = tonumber(STATE_T)
local restAll = 0
v:postSim(function(N_)
  if holdNow then return end
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
          if e.r30 then
            local T = msRise(e.J60, math.rad(60), math.rad(30))
            extra = extra .. string.format("\n         it rose from 60 to 30 deg in %.3f s; by J dtheta/dt = mu M g h^2 (sliding) it should take %.3f (%+.1f%%)",
                                           e.r30 - e.r60, T, (e.r30 - e.r60 - T) / T * 100)
          end
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
    if STATE_T and k == 1 and t >= STATE_T - 1e-9 then
      local f = io.open(STATE_F, "w")
      f:write(string.format(string.rep("%.17g ", 19) .. "\n", t, e.gx - e.x, e.gy - TABLE_Y, e.gz, e.vx, e.vy, e.vz,
                            e.wx, e.wy, e.wz, e.c1x, e.c1y, e.c1z, e.c2x, e.c2y, e.c2z, e.c3x, e.c3y, e.c3z))
      f:close()
      STATE_T = nil
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
  if holdPre() then return end
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
  "The spinning egg (Euler's Gallery)",
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
