--
-- Pendulums with a Twist -- Euler's Cabinet of Curiosities
--
-- Three more pendulums that don't do what you'd guess.
--
--   left    THE FLIP ROW. Nine double pendulums, let go from rest with
--           both rods at the same angle: 60 degrees on the left, up to
--           120 on the right. Can the lower rod swing right over the top?
--           Energy says it can't unless 3 cos(angle) < 1: below 70.5
--           degrees, never. Above that line it's allowed -- but allowed
--           isn't the same as happens: at 72 and 76 it doesn't, for as
--           long as you watch; at 80 it takes 11 seconds; at 90, three. A
--           bob turns red when its rod first goes over (the upper rod's
--           own line is 109.5 degrees).
--
--   middle  THE SWINGING ATWOOD MACHINE. A cord over two pulleys: on the
--           left a heavy weight that only goes up and down, on the right
--           a light one that swings. Let go from 60 degrees, the light one
--           swings in and out, the cord paying in and out, and its path
--           (the dotted trail) is a tangle. Three machines, the heavy
--           weight 2.8, 3.0 and 3.2 times the light one. They look alike,
--           and from this gentle start all three swing in an orderly way.
--           The difference is hidden: only at exactly 3 does the motion
--           keep a second constant, besides its energy (Casasayas, Nunes
--           and Tufillaro, 1990), so that at 3 it can never become chaotic,
--           however it's started. The dial in front of each shows that
--           quantity: at 3 its needle never moves; at 2.8 and 3.2 it
--           wanders.
--
--   right   THE SWINGING SPRING. A weight on a spring, set bouncing
--           straight up and down, the merest swing to start with. On the
--           left the spring's bounce is tuned to exactly twice its swing's
--           frequency: the bounce drains away into a swing that grows to
--           11 degrees -- then swings back into a bounce, and again. On
--           the right, tuned 2.4 times: it just bounces.
--
-- Theory, and what the console checks:
--   The flip row: energy, from rest at angle a, is -3 m g l cos a; the
--   lower rod over the top needs at least -m g l (the upper hanging), so
--   cos a <= 1/3; the upper rod over needs +m g l, cos a <= -1/3. The
--   console gives when each goes over, and the energy, steady to 1e-8 of m g l.
--   The Atwood machine: with r the swinging side's length, theta its
--   angle, mu the ratio, (1 + mu) r'' = r theta'^2 - g (mu - cos theta)
--   and r theta'' = -2 r' theta' - g sin theta. At mu = 3, in coordinates
--   r = (xi^2 + eta^2) / 2, tan(theta / 2) = (xi^2 - eta^2) / (2 xi eta),
--   I = p_xi^2 / 8 - E xi^2 + 2 xi^4 (in units of the starting length and
--   g) stays constant; at 2.8 and 3.2 there is no such thing. The console
--   gives I's range for each.
--   The spring: bouncing Z about its stretched length l, the swing grows
--   (at first) as exp(s t), with s = (3/4)(Z / l) w, w = sqrt(g / l) the
--   swing's frequency -- to first order; exactly, from the bounce's effect
--   over one bounce (Floquet). Tuned 2.4:1, exactly no growth. The console
--   gives both and the growth measured.
--
-- PHYSICS: each worked out from its exact equations (Lagrange's) by
-- Bulirsch-Stoer (tenth order), 240 steps a second (the Atwood machines
-- 480); Bullet only draws them.
--
-- Keys
--   R   let them all go again
--   Z   slow motion (1/4) <-> real time
--
-- Units: centimetres, kilograms, seconds.
-- Headless testing: PT_SPEED, PT_CYCLE (seconds between restarts).
--

local common = require "common"

local DIR = "twist-meshes/"
for _, dir in ipairs({ DIR, "demo/WyomingWill/PendulumsTwist/" .. DIR }) do
  local f = io.open(dir .. "dial-top.obj", "r")
  if f then f:close(); DIR = dir; break end
end

local G = 981
local function envnum(n, d) return tonumber(os.getenv(n) or "") or d end
v:addParam("speed", envnum("PT_SPEED", 1), 0.05, 2, 0.05, "simulated seconds per real second (Z: 1/4 <-> 1)")
local CYCLE = envnum("PT_CYCLE", 60)

local FRAME_DT = 1 / 60
local function applyTiming()
  FRAME_DT = v:getParam("speed") / 60
  v.animationPeriod = 16
  common.setTiming(1 / 240, 0, 1 / 240)
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

local sin, cos, sqrt, abs, pi = math.sin, math.cos, math.sqrt, math.abs, math.pi
local Q0 = btQuaternion(0, 0, 0, 1)
local HIDDEN = btTransform(Q0, btVector3(0, -500, 0))
local function block(sx, sy, sz, x, y, z, col)
  local c = Cube(sx, sy, sz, 0)
  c.trans = btTransform(Q0, btVector3(x, y, z))
  c.col = col
  c.collides = false
  v:add(c)
  return c
end
local function ball(r, col)
  local s = Sphere(r, 0)
  s.col = col
  s.collides = false
  s.trans = HIDDEN
  v:add(s)
  return s
end
local function at(o, x, y, z) o.trans = btTransform(Q0, btVector3(x, y, z)) end
local function rodTrans(x0, y0, x1, y1, z)
  local th = math.atan2(x1 - x0, y1 - y0)
  return btTransform(btQuaternion(btVector3(0, 0, 1), -th) * btQuaternion(btVector3(1, 0, 0), pi / 2),
                     btVector3((x0 + x1) / 2, (y0 + y1) / 2, z))
end
local KEYS = {}

-- ---------------------------------------------------------------------
-- Bulirsch-Stoer for a state of four (a, b, a', b'), given f returning
-- the two accelerations
-- ---------------------------------------------------------------------
local SEQ = { 2, 4, 6, 8, 10 }
local T1, T2, T3, T4 = {}, {}, {}, {}
local function gbs(p, H, f)
  local a, b, u, w = p[1], p[2], p[3], p[4]
  local fa, fb = f(p, a, b, u, w)
  for j, n in ipairs(SEQ) do
    local h = H / n
    local x1, x2, x3, x4 = a, b, u, w
    local y1, y2, y3, y4 = a + h * u, b + h * w, u + h * fa, w + h * fb
    for _ = 1, n - 1 do
      local ga, gb = f(p, y1, y2, y3, y4)
      x1, x2, x3, x4, y1, y2, y3, y4 = y1, y2, y3, y4, x1 + 2 * h * y3, x2 + 2 * h * y4, x3 + 2 * h * ga, x4 + 2 * h * gb
    end
    local ga, gb = f(p, y1, y2, y3, y4)
    T1[j], T2[j] = 0.5 * (x1 + y1 + h * y3), 0.5 * (x2 + y2 + h * y4)
    T3[j], T4[j] = 0.5 * (x3 + y3 + h * ga), 0.5 * (x4 + y4 + h * gb)
  end
  local k = #SEQ
  for j = 2, k do
    for i = k, j, -1 do
      local r = 1 / ((SEQ[i] / SEQ[i - j + 1]) ^ 2 - 1)
      T1[i], T2[i] = T1[i] + (T1[i] - T1[i - 1]) * r, T2[i] + (T2[i] - T2[i - 1]) * r
      T3[i], T4[i] = T3[i] + (T3[i] - T3[i - 1]) * r, T4[i] + (T4[i] - T4[i - 1]) * r
    end
  end
  p[1], p[2], p[3], p[4] = T1[k], T2[k], T3[k], T4[k]
end

-- ---------------------------------------------------------------------
-- the table
-- ---------------------------------------------------------------------
local TABLE_Y = 0
block(360, 3, 60, 2, TABLE_Y - 1.5, 0, "#7a4a24")
for _, x in ipairs({ -174, 178 }) do
  for _, z in ipairs({ -26, 26 }) do block(3, 72, 3, x, TABLE_Y - 3 - 36, z, "#4e2e15") end
end
local floor_ = Plane(0, 1, 0, TABLE_Y - 75, 400)
floor_.col = "#3b3f45"
v:add(floor_)

-- =====================================================================
-- the flip row
-- =====================================================================
local FL_L, FL_Y = 7, TABLE_Y + 40
local FL_ANG = { 60, 66, 70, 72, 76, 80, 90, 100, 120 }
local FL = {}
local A_LOW, A_UP = math.deg(math.acos(1 / 3)), math.deg(math.acos(-1 / 3))
block(156, 2.5, 3, -95, FL_Y + 1.25, -5, "#4e2e15")
for _, x in ipairs({ -172, -18 }) do block(3, FL_Y + 2.5 - TABLE_Y, 3, x, (FL_Y + 2.5 + TABLE_Y) / 2, -5, "#4e2e15") end
local function flAcc(p, t1, t2, w1, w2)
  local l = FL_L
  local d = t1 - t2
  local sd, cd = sin(d), cos(d)
  local den = l * (3 - cos(2 * d))
  return (-3 * G * sin(t1) - G * sin(t1 - 2 * t2) - 2 * sd * l * (w2 * w2 + w1 * w1 * cd)) / den,
         2 * sd * (2 * l * w1 * w1 + 2 * G * cos(t1) + l * w2 * w2 * cd) / den
end
local function flEnergy(p)
  local l = FL_L
  return l * l * (p[3] ^ 2 + 0.5 * p[4] ^ 2 + p[3] * p[4] * cos(p[1] - p[2])) - G * l * (2 * cos(p[1]) + cos(p[2]))
end
for k, a in ipairs(FL_ANG) do
  local p = { x = -163 + (k - 1) * 17, z = (k % 2 == 0) and 0 or 2, ang = a }
  block(1, 1, 7, p.x, FL_Y, -2, "#8a8f96")
  p.rod1, p.rod2 = Cylinder(0.15, FL_L - 0.8, 0), Cylinder(0.15, FL_L - 0.8, 0)
  for _, r in ipairs({ p.rod1, p.rod2 }) do r.col = "#c8cdd4"; r.collides = false; v:add(r) end
  p.bob1, p.bob2 = ball(0.8, "#c8a04a"), ball(0.8, "#c8a04a")
  KEYS[objectKey(p.bob1)], KEYS[objectKey(p.bob2)] = p, p
  FL[k] = p
end

-- =====================================================================
-- the swinging Atwood machines
-- =====================================================================
local SA_Y, SA_R0, SA_S, SA_GAP = TABLE_Y + 72, 18, 50, 8
local SA_TH0 = math.rad(60)
local SA_MU = { 2.8, 3.0, 3.2 }
local SA = {}
local SA_TRAIL = 260
local function saAcc(p, r, t, rd, td)
  return (r * td * td - G * (p.mu - cos(t))) / (1 + p.mu), -(2 * rd * td + G * sin(t)) / r
end
block(3, SA_Y + 3 - TABLE_Y, 3, -5, (SA_Y + 3 + TABLE_Y) / 2, -6, "#4e2e15")
block(3, SA_Y + 3 - TABLE_Y, 3, 115, (SA_Y + 3 + TABLE_Y) / 2, -6, "#4e2e15")
block(123, 3, 3, 55, SA_Y + 3, -6, "#4e2e15")
for k, mu in ipairs(SA_MU) do
  local x = 15 + (k - 1) * 40
  local p = { mu = mu, x = x, z = (k - 2) * 1.5, px = x + SA_GAP / 2, cx = x - SA_GAP / 2, dots = {}, cord = {} }
  for _, xx in ipairs({ p.cx, p.px }) do
    local w = Cylinder(1.2, 0.6, 0)
    w.col = "#8a8f96"
    w.collides = false
    w.trans = btTransform(Q0, btVector3(xx, SA_Y, p.z))
    v:add(w)
    block(0.6, 3, 0.6, xx, SA_Y + 1.5, p.z - 0.8, "#4e2e15")
  end
  -- the cord between the pulleys, fixed
  local top = Cylinder(0.08, SA_GAP, 0)
  top.col = "#e8e2d0"
  top.collides = false
  top.trans = btTransform(btQuaternion(btVector3(0, 1, 0), pi / 2), btVector3(x, SA_Y + 1.2, p.z))
  v:add(top)
  -- the counterweight: as tall as its mass
  p.cw = Cylinder(1.6, 1.0 * mu, 0)
  p.cw.col = "#6f747c"
  p.cw.collides = false
  v:add(p.cw)
  p.bob = ball(1.2, "#c8a04a")
  for i = 1, 60 do p.cord[i] = ball(0.09, "#e8e2d0") end
  for i = 1, SA_TRAIL do p.dots[i] = ball(0.35, k == 2 and "#3a8ae8" or "#e8743a") end
  KEYS[objectKey(p.bob)], KEYS[objectKey(p.cw)] = p, p
  SA[k] = p
end
-- in front of each, a dial: its needle shows the second constant (how far
-- the quantity I below is from where it started, 0.5 a full sweep of 120
-- degrees each way), straight up at the start
local DIAL_Y, DIAL_Z, DIAL_R = TABLE_Y + 9, 10, 5
for k, p in ipairs(SA) do
  block(14, 17, 0.6, p.x, DIAL_Y, DIAL_Z - 0.4, "#1d2228")
  local face = Cylinder(DIAL_R, 0.2, 0)
  face.col = "#e9e2cf"
  face.collides = false
  face.trans = btTransform(Q0, btVector3(p.x, DIAL_Y, DIAL_Z))
  v:add(face)
  block(0.25, 1.0, 0.2, p.x, DIAL_Y + DIAL_R - 0.6, DIAL_Z + 0.15, "#1d2228")     -- the zero mark
  for _, a in ipairs({ -120, -60, 60, 120 }) do
    local ra = math.rad(a)
    block(0.2, 0.6, 0.2, p.x + (DIAL_R - 0.5) * sin(ra), DIAL_Y + (DIAL_R - 0.5) * cos(ra), DIAL_Z + 0.15, "#8a8f96")
  end
  p.needle = Cylinder(0.14, DIAL_R - 0.8, 0)
  p.needle.col = (k == 2) and "#2a6fd0" or "#d0402a"
  p.needle.collides = false
  v:add(p.needle)
  local hub = Sphere(0.4, 0)
  hub.col = "#1d2228"
  hub.collides = false
  hub.trans = btTransform(Q0, btVector3(p.x, DIAL_Y, DIAL_Z + 0.2))
  v:add(hub)
  for _, lab in ipairs({ { "dial-top", DIAL_Y + 6.6 }, { ({ "ratio-28", "ratio-30", "ratio-32" })[k], DIAL_Y - 7.6 } }) do
    local m = Mesh(DIR .. lab[1] .. ".obj", 0, false)
    m.col = "#d4af37"
    m.collides = false
    m.trans = btTransform(Q0, btVector3(p.x, lab[2], DIAL_Z - 0.05))
    v:add(m)
  end
  KEYS[objectKey(face)] = p
end

-- the mu = 3 constant, from r, theta and their rates (in units of the
-- starting length and g)
local function saI(p, E)
  local r, t = p[1] / SA_R0, p[2]
  local rd, td = p[3] / sqrt(G * SA_R0), p[4] * sqrt(SA_R0 / G)
  -- xi = sqrt(2 r) cos(c), eta = sqrt(2 r) sin(c), c = (pi / 2 - t / 2) / 2
  local s, c = sqrt(2 * r), (pi / 2 - t / 2) / 2
  local sd, cd = rd / s, -td / 4
  local xi = s * cos(c)
  local xid = sd * cos(c) - s * sin(c) * cd
  local pxi = 4 * xid * (2 * r)
  return pxi * pxi / 8 - E * xi * xi + 2 * xi ^ 4
end
local function saEnergy(p)       -- in units of m g r0
  local r, t = p[1] / SA_R0, p[2]
  local rd, td = p[3] / sqrt(G * SA_R0), p[4] * sqrt(SA_R0 / G)
  return 0.5 * (1 + p.mu) * rd * rd + 0.5 * r * r * td * td + r * (p.mu - cos(t))
end

-- =====================================================================
-- the swinging springs
-- =====================================================================
local SP_Y, SP_L, SP_Z = TABLE_Y + 66, 20, 2
local SP_TH0 = math.rad(0.05)
local SP_RATIO = { 2.0, 2.4 }
local SP = {}
local SP_TRAIL = 200
block(3, SP_Y + 3 - TABLE_Y, 3, 125, (SP_Y + 3 + TABLE_Y) / 2, -6, "#4e2e15")
block(3, SP_Y + 3 - TABLE_Y, 3, 178, (SP_Y + 3 + TABLE_Y) / 2, -6, "#4e2e15")
block(56, 3, 3, 151.5, SP_Y + 3, -6, "#4e2e15")
local function spAcc(p, r, t, rd, td)
  return r * td * td - p.k * (r - p.L0) + G * cos(t), -(2 * rd * td + G * sin(t)) / r
end
for k, ratio in ipairs(SP_RATIO) do
  local x = 138 + (k - 1) * 27
  local wp2 = G / SP_L
  local p = { ratio = ratio, x = x, k = ratio * ratio * wp2, coil = {}, dots = {} }
  p.L0 = SP_L - G / p.k
  block(1.5, 1.5, 7, x, SP_Y, -2.5, "#8a8f96")
  for i = 1, 70 do p.coil[i] = ball(0.28, "#b9bec6") end
  p.bob = ball(1.6, "#c8a04a")
  for i = 1, SP_TRAIL do p.dots[i] = ball(0.3, k == 1 and "#3a8ae8" or "#e8743a") end
  KEYS[objectKey(p.bob)] = p
  SP[k] = p
end
-- the exact growth: the swing's linear equation over one bounce (Floquet)
local function spFloquet(p)
  local ws = sqrt(p.k)
  local T, n = 2 * pi / ws, 2000
  local h = T / n
  local function f(tt, th, thd)
    local r = SP_L + SP_Z * cos(ws * tt)
    local rd = -SP_Z * ws * sin(ws * tt)
    return thd, -(2 * rd * thd + G * th) / r
  end
  local M = {}
  for c = 1, 2 do
    local y1, y2 = (c == 1) and 1 or 0, (c == 2) and 1 or 0
    local tt = 0
    for _ = 1, n do
      local a1, b1 = f(tt, y1, y2)
      local a2, b2 = f(tt + h / 2, y1 + h / 2 * a1, y2 + h / 2 * b1)
      local a3, b3 = f(tt + h / 2, y1 + h / 2 * a2, y2 + h / 2 * b2)
      local a4, b4 = f(tt + h, y1 + h * a3, y2 + h * b3)
      y1, y2 = y1 + h / 6 * (a1 + 2 * a2 + 2 * a3 + a4), y2 + h / 6 * (b1 + 2 * b2 + 2 * b3 + b4)
      tt = tt + h
    end
    M[c] = { y1, y2 }
  end
  local tr = M[1][1] + M[2][2]
  local det = M[1][1] * M[2][2] - M[2][1] * M[1][2]
  local disc = tr * tr / 4 - det
  if disc <= 0 then return 0 end
  local lam = abs(tr / 2) + sqrt(disc)
  return math.log(lam) / T
end
for _, p in ipairs(SP) do p.sigma = spFloquet(p) end
local SIGMA1 = 0.75 * (SP_Z / SP_L) * sqrt(G / SP_L)

-- =====================================================================
-- letting go, stepping, drawing
-- =====================================================================
local t = 0
local function letGo()
  holdStart()
  t = 0
  print(string.format("\n--- let go (again every %d s) ---", CYCLE))
  print(string.format("  The flip row: rods %d cm, let go from rest, both rods at one angle. Energy lets the lower rod over the top" ..
                      "\n    only from above %.2f degrees (3 cos a < 1), the upper only from above %.2f (3 cos a < -1)",
                      FL_L, A_LOW, A_UP))
  for _, p in ipairs(FL) do
    local a = math.rad(p.ang)
    p[1], p[2], p[3], p[4] = a, a, 0, 0
    p.E0, p.dE, p.flip1, p.flip2 = flEnergy(p), 0, nil, nil
    p.bob1.col, p.bob2.col = "#c8a04a", "#c8a04a"
  end
  print(string.format("  The swinging Atwood machines: let go from %.0f degrees, the swinging side %d cm; the heavy weight %s times" ..
                      "\n    the light one. From this start all three swing in an orderly way; only at 3 is there a second constant" ..
                      "\n    (Casasayas, Nunes & Tufillaro), I = p_xi^2/8 - E xi^2 + 2 xi^4: the dials show it", math.deg(SA_TH0), SA_R0, table.concat(SA_MU, ", ")))
  for _, p in ipairs(SA) do
    p[1], p[2], p[3], p[4] = SA_R0, SA_TH0, 0, 0
    p.E0 = saEnergy(p)
    p.I0 = saI(p, p.E0)
    p.Imin, p.Imax, p.dE, p.rmin, p.nd, p.hit = p.I0, p.I0, 0, SA_R0, 0, false
    for _, d in ipairs(p.dots) do d.trans = HIDDEN end
  end
  print(string.format("  The swinging springs: stretched length %d cm, bouncing %d cm, swinging %.2f degrees to start with." ..
                      "\n    Tuned %.1f:1, the swing grows as exp(s t): s = (3/4)(Z/l) w = %.3f/s to first order, %.3f/s exactly" ..
                      " (Floquet);\n    tuned %.1f:1, exactly: %s",
                      SP_L, SP_Z, math.deg(SP_TH0), SP_RATIO[1], SIGMA1, SP[1].sigma, SP_RATIO[2],
                      SP[2].sigma > 1e-6 and string.format("%.3f/s", SP[2].sigma) or "no growth at all"))
  for _, p in ipairs(SP) do
    p[1], p[2], p[3], p[4] = SP_L + SP_Z, SP_TH0, 0, 0
    p.E0 = 0.5 * p.k * (p[1] - p.L0) ^ 2 - G * p[1] * cos(p[2])
    p.dE, p.peaks, p.prev1, p.prev2, p.amax, p.tmax, p.nd, p.grown = 0, {}, 0, 0, 0, 0, 0, nil
    p.bounceMin = 1e9
    for _, d in ipairs(p.dots) do d.trans = HIDDEN end
  end
end

v:preSim(function(N_)
  if holdPre() then return end
  local H = FRAME_DT / 4
  for j = 1, 4 do
    local te = t + j * H
    for _, p in ipairs(FL) do
      gbs(p, H, flAcc)
      if not p.flip2 and abs(p[2]) > pi then
        p.flip2 = te
        p.bob2.col = "#e04a3a"
        print(string.format("    flip row, let go at %d degrees: the lower rod goes over the top at %.2f s", p.ang, te))
      end
      if not p.flip1 and abs(p[1]) > pi then
        p.flip1 = te
        p.bob1.col = "#e04a3a"
        print(string.format("    flip row, let go at %d degrees: the upper rod goes over the top at %.2f s", p.ang, te))
      end
    end
    for _, p in ipairs(SA) do
      if not p.hit then
        gbs(p, H / 2, saAcc)
        gbs(p, H / 2, saAcc)
        p.rmin = math.min(p.rmin, p[1])
        if p[1] < 0.03 * SA_R0 then p.hit = te end
        local I = saI(p, p.E0)
        p.Imin, p.Imax = math.min(p.Imin, I), math.max(p.Imax, I)
      end
    end
    for _, p in ipairs(SP) do
      gbs(p, H, spAcc)
      local a = abs(p[2])
      -- the swing's peaks while it first grows (to 3 degrees)
      if p.prev1 > p.prev2 and p.prev1 > a and not p.grown then
        p.peaks[#p.peaks + 1] = { te - H, p.prev1 }
        if p.prev1 > math.rad(3) then p.grown = te end
      end
      p.prev2, p.prev1 = p.prev1, a
      if a > p.amax then p.amax, p.tmax = a, te end
    end
  end
  t = t + FRAME_DT
end)

local function report()
  print(string.format("  After %d s:", CYCLE))
  local never, parts = {}, {}
  local worst = 0
  for _, p in ipairs(FL) do
    worst = math.max(worst, p.dE / (G * FL_L))
    if p.flip2 then
      parts[#parts + 1] = string.format("%d: %.1f s%s", p.ang, p.flip2, p.flip1 and string.format(" (upper %.1f s)", p.flip1) or "")
    else
      never[#never + 1] = tostring(p.ang)
    end
  end
  print(string.format("    the flip row: the lower rod over the top -- %s; never: %s degrees (below %.2f it can't;" ..
                      " above, it may)\n      energy steady to %.1e of m g l", table.concat(parts, ", "),
                      table.concat(never, ", "), A_LOW, worst))
  for _, p in ipairs(SA) do
    print(string.format("    Atwood, %.1f times: I between %.10f and %.10f (%s); energy steady to %.1e; closest to its pulley %.1f cm%s",
                        p.mu, p.Imin, p.Imax, p.mu == 3 and "constant, as at 3 it must be" or "no such constant here",
                        p.dE, p.rmin, p.hit and string.format(" (it hit it at %.1f s)", p.hit) or ""))
  end
  for _, p in ipairs(SP) do
    local n, sx, sy, sxx, sxy = 0, 0, 0, 0, 0
    for _, q in ipairs(p.peaks) do
      if q[2] > math.rad(0.2) and q[2] < math.rad(3) then
        local y = math.log(q[2])
        n, sx, sy, sxx, sxy = n + 1, sx + q[1], sy + y, sxx + q[1] * q[1], sxy + q[1] * y
      end
    end
    local grow = (n > 3) and (n * sxy - sx * sy) / (n * sxx - sx * sx) or nil
    print(string.format("    spring, %.1f:1: the swing %s; at most %.1f degrees; energy steady to %.1e",
                        p.ratio, grow and string.format("grew at %.3f/s, from 0.2 to 3 degrees (theory %.3f exactly, %.3f to first" ..
                        " order)", grow, p.sigma, SIGMA1) or "never grew", math.deg(p.amax), p.dE))
  end
end

v:postSim(function(N_)
  if holdNow then return end
  -- the flip row
  for _, p in ipairs(FL) do
    local x1, y1 = p.x + FL_L * sin(p[1]), FL_Y - FL_L * cos(p[1])
    local x2, y2 = x1 + FL_L * sin(p[2]), y1 - FL_L * cos(p[2])
    p.rod1.trans = rodTrans(p.x, FL_Y, x1, y1, p.z)
    p.rod2.trans = rodTrans(x1, y1, x2, y2, p.z)
    at(p.bob1, x1, y1, p.z)
    at(p.bob2, x2, y2, p.z)
    p.dE = math.max(p.dE, abs(flEnergy(p) - p.E0))
  end
  -- the Atwood machines
  for _, p in ipairs(SA) do
    local r, th = p[1], p[2]
    local bx, by = p.px + r * sin(th), SA_Y - r * cos(th)
    at(p.bob, bx, by, p.z)
    local c = SA_S - r
    local cy = SA_Y - c
    p.cw.trans = btTransform(btQuaternion(btVector3(1, 0, 0), pi / 2), btVector3(p.cx, cy - 0.5 * p.mu, p.z))
    local nc = #p.cord
    local half = nc / 2
    for i = 1, nc do
      if i <= half then
        local f = i / half
        at(p.cord[i], p.cx, SA_Y - c * f, p.z)
      else
        local f = (i - half) / half
        at(p.cord[i], p.px + (bx - p.px) * f, SA_Y + (by - SA_Y) * f, p.z)
      end
    end
    if N_ % 3 == 0 then
      p.nd = p.nd % SA_TRAIL + 1
      at(p.dots[p.nd], bx, by, p.z - 0.5)
    end
    p.dE = math.max(p.dE, abs(saEnergy(p) - p.E0) / p.E0)
    local phi = math.rad(math.max(-135, math.min(135, (saI(p, p.E0) - p.I0) / 0.5 * 120)))
    local hl = (DIAL_R - 0.8) / 2
    p.needle.trans = btTransform(btQuaternion(btVector3(0, 0, 1), -phi) * btQuaternion(btVector3(1, 0, 0), pi / 2),
                                 btVector3(p.x + hl * sin(phi), DIAL_Y + hl * cos(phi), DIAL_Z + 0.3))
  end
  -- the springs
  for _, p in ipairs(SP) do
    local r, th = p[1], p[2]
    local ux, uy = sin(th), -cos(th)
    local bx, by = p.x + r * ux, SP_Y + r * uy
    at(p.bob, bx, by, 0)
    local nc = #p.coil
    local turns = 14
    for i = 1, nc do
      local f = i / nc
      local ang = 2 * pi * turns * f
      local s = r * f * 0.94
      local ox, oz = 1.1 * cos(ang), 1.1 * sin(ang)
      at(p.coil[i], p.x + ux * s + ox * (-uy), SP_Y + uy * s + ox * ux, oz)
    end
    if N_ % 3 == 0 then
      p.nd = p.nd % SP_TRAIL + 1
      at(p.dots[p.nd], bx, by, -0.6)
    end
    local E = 0.5 * (p[3] ^ 2 + p[1] ^ 2 * p[4] ^ 2) + 0.5 * p.k * (p[1] - p.L0) ^ 2 - G * p[1] * cos(p[2])
    p.dE = math.max(p.dE, abs(E - p.E0) / abs(p.E0))
  end
  if t >= CYCLE - 1e-9 then report(); letGo() end
end)

-- ---------------------------------------------------------------------
-- keys, help
-- ---------------------------------------------------------------------
common.setCamera(btVector3(5, 75, 330), btVector3(5, 45, 0))
v:addShortcut("R", function(N_) letGo() end)
v:addShortcut("Z", function(N_)
  local sp = v:getParam("speed") < 0.5 and 1 or 0.25
  v:addParam("speed", sp, 0.05, 2, 0.05, "simulated seconds per real second (Z: 1/4 <-> 1)")
  applyTiming()
end)
v:onParamChanged(function(N_, name, value)
  if name == "speed" then applyTiming() end
end)
v:setHelpText(table.concat({
  "Pendulums with a twist (Euler's Cabinet of Curiosities)",
  "",
  "Left: nine double pendulums let go from 60 to 120 degrees.",
  "Below 70.5 the lower rod can't go over the top; above, it",
  "may -- or may not. A bob turns red when its rod goes over.",
  "Middle: swinging Atwood machines, weights 2.8, 3.0, 3.2 to 1.",
  "From this start all three swing in an orderly way; only at",
  "3 is there a hidden second constant (so at 3 it can never be",
  "chaotic, however started). Each dial shows that quantity:",
  "at 3 the needle stays still; at 2.8 and 3.2 it wanders.",
  "Right: springs bouncing; tuned 2:1, the bounce turns into",
  "a swing and back. Tuned 2.4:1, it just bounces.",
  "",
  "R   let them all go again",
  "Z   slow motion (1/4) <-> real time",
}, "\n"))
if v.onHover then
  v:onHover(function(N_, obj, x, y, z)
    local p = KEYS[objectKey(obj)]
    if not p then return nil end
    if p.ang then
      return string.format("Flip row: let go at %d degrees (%s)", p.ang,
                           p.ang < A_LOW and "its lower rod can never go over the top" or "its lower rod may go over the top")
    elseif p.mu then
      return string.format("Swinging Atwood machine: the heavy weight %.1f times the light one%s", p.mu,
                           p.mu == 3 and " -- the one that keeps a second constant: its dial never moves" or
                           " -- no second constant here: its dial wanders")
    else
      return string.format("Swinging spring: its bounce %.1f times its swing's frequency", p.ratio)
    end
  end)
end

letGo()
