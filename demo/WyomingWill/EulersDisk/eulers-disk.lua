--
-- Euler's Disk -- Euler's Cabinet of Curiosities
--
-- A heavy steel disc, set spinning on its edge on a mirror, rolls round and
-- round in place, leaning further and further over as it loses energy: and
-- the further it leans, the faster it goes round -- faster and faster, until
-- it suddenly stops, flat. (Joseph Bendik's toy, 1990s; a spinning coin on
-- a table does the same.)
--
-- Theory: rolling round in place (its centre still), leaning at alpha to
-- the mirror, the disc's axis goes round the upright at W, where
--     W^2 = m g a (a cos alpha - h sin alpha) / (sin alpha (I1 a cos alpha - I3 h sin alpha))
-- (a the radius of its bottom edge, which it rolls on, h that edge's
-- distance below its centre along its axis, I1 and I3 its moments of
-- inertia across and about its axis; for a thin disc, W^2 = 4 g / (a sin
-- alpha)). Its energy, above lying flat, is (3/2) m g a alpha, near enough,
-- when alpha is small: so as it loses energy alpha goes to nothing and W
-- grows without limit. Losing it to rolling resistance (a moment delta m g
-- against its rolling), it gets there at a definite time t0, and near the
-- end
--     W (t0 - t) = 3 a / delta
-- whatever its mass or moment of inertia. The console gives W against the
-- first as it leans over, and W (t0 - t) against the second at the end.
--
-- THE DISC: steel, 7.6 cm across, 1.2 cm thick, 430 g -- the size of the
-- toy -- rolling on the edge of its bottom face. Rolling resistance 30
-- microns. Set going at 30 degrees.
--
-- PHYSICS: the disc rolls without slipping, all the way; so its motion is
-- worked out here from the rolling equations, exactly (not by Bullet's
-- contacts, whose small errors in a contact going round a rim 60 times a
-- second add energy as fast as the rolling resistance takes it): Newton's
-- and Euler's equations for the disc, with the force at its contact point
-- whatever keeps that point still, solved for the turning each moment, and
-- stepped (RK4) 9600 times a second. Its energy stays put to a few parts in
-- a million with no rolling resistance. A light drag on its centre's
-- sideways motion (10 per second: the air, and the mirror's grip not being
-- perfect) keeps it rolling in place; without it, as it loses energy, its
-- centre drifts into circles a few millimetres across, and it goes round up
-- to a fifth slower than rolling in place would.
--
-- Keys
--   R   set it going again
--   Z   slow motion (1/4) <-> real time
--
-- Units: centimetres, kilograms, seconds.
-- Headless testing: ED_SPEED, ED_STEPS, ED_TILT (degrees), ED_DELTA
-- (microns), ED_LOG=file.csv.
--

local common = require "common"

local DIR = "eulers-disk-meshes/"
for _, dir in ipairs({ DIR, "demo/WyomingWill/EulersDisk/" .. DIR }) do
  local f = io.open(dir .. "disc.obj", "r")
  if f then f:close(); DIR = dir; break end
end

local G = 981
local function envnum(n, d) return tonumber(os.getenv(n) or "") or d end
local function param(...) v:addParam(...) end
param("rolling", envnum("ED_DELTA", 30), 1, 60, 1, "rolling resistance, microns (sets it going again)")
param("speed", envnum("ED_SPEED", 1), 0.05, 2, 0.05, "simulated seconds per real second (Z: 1/4 <-> 1)")
param("steps", envnum("ED_STEPS", 9600), 4800, 19200, 1200, "physics steps per simulated second")

local STEP, NSTEPS, FRAME_DT = 1 / 9600, 160, 1 / 60
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
-- all stands still for HOLD_S seconds (2), so you see how it begins --
-- bpp's own physics step stopped too (a zero time step) -- and then it
-- carries on from there, exactly as if there had been no pause
-- ---------------------------------------------------------------------
local HOLD_FRAMES = math.floor(envnum("HOLD_S", 2) * 60 + 0.5)
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

local Q0 = btQuaternion(0, 0, 0, 1)
local function block(sx, sy, sz, x, y, z, col)
  local c = Cube(sx, sy, sz, 0)
  c.trans = btTransform(Q0, btVector3(x, y, z))
  c.col = col
  c.collides = false
  v:add(c)
  return c
end

-- ---------------------------------------------------------------------
-- the table, the mirror
-- ---------------------------------------------------------------------
local TABLE_Y = 0
block(80, 3, 60, 0, TABLE_Y - 1.5, 0, "#7a4a24")
for _, x in ipairs({ -36, 36 }) do
  for _, z in ipairs({ -26, 26 }) do block(3, 72, 3, x, TABLE_Y - 3 - 36, z, "#4e2e15") end
end
local floor = Plane(0, 1, 0, TABLE_Y - 75, 300)
floor.col = "#3b3f45"
v:add(floor)
local MIRROR_Y = TABLE_Y + 2.5
do
  local base = Cylinder(17, 2.0, 0)
  base.trans = btTransform(btQuaternion(btVector3(1, 0, 0), math.pi / 2), btVector3(0, MIRROR_Y - 1.0 - 0.05, 0))
  base.col = "#2a2d33"
  base.collides = false
  v:add(base)
  local glass = Cylinder(16, 0.1, 0)
  glass.trans = btTransform(btQuaternion(btVector3(1, 0, 0), math.pi / 2), btVector3(0, MIRROR_Y - 0.05, 0))
  glass.col = "#c9d6de"
  glass.collides = false
  v:add(glass)
end

-- ---------------------------------------------------------------------
-- the disc: its axis its own y; it rolls on the circle of radius A, H below
-- its centre along the axis (the edge of its bottom face)
-- ---------------------------------------------------------------------
local A, W = 3.8, 1.2
local H = W / 2
local RHO = 0.00785
local MASS = RHO * math.pi * A * A * W
local I1 = MASS * (A * A / 4 + W * W / 12)
local I3 = MASS * A * A / 2
local disc = Mesh(DIR .. "disc.obj", 0, false)
disc.col = "#c9ced6"
disc.collides = false
v:add(disc)
local mark = Mesh(DIR .. "disc-mark.obj", 0, false)
mark.col = "#2a4d8a"
mark.collides = false
v:add(mark)

-- ---------------------------------------------------------------------
-- the rolling equations
-- ---------------------------------------------------------------------
-- state: R (its axes in the world, columns c1 c2 c3; c2 the axis), w (its
-- turning, in the world), C (its centre)
local DELTA
local KD = envnum("ED_DRAG", 10)            -- a drag on the centre's sideways motion, per second
local function cross(a, b) return { a[2] * b[3] - a[3] * b[2], a[3] * b[1] - a[1] * b[3], a[1] * b[2] - a[2] * b[1] } end
local function dot(a, b) return a[1] * b[1] + a[2] * b[2] + a[3] * b[3] end
-- the contact point, from the centre: A along the disc's "down", H down its axis
local function contact(n)
  -- (down in the disc's plane: -z less its part along the axis, made unit)
  local u = { n[2] * n[1], -1 + n[2] * n[2], n[2] * n[3] }
  local ul = math.sqrt(dot(u, u))
  local d = { u[1] / ul, u[2] / ul, u[3] / ul }
  return { A * d[1] - H * n[1], A * d[2] - H * n[2], A * d[3] - H * n[3] }, d, u, ul
end
-- the rate of change of the contact vector, as the axis turns (ndot = w x n)
local function contactRate(n, nd, d, ul)
  local ud = { nd[2] * n[1] + n[2] * nd[1], 2 * n[2] * nd[2], nd[2] * n[3] + n[2] * nd[3] }
  local k = dot(d, ud)
  local dd = { (ud[1] - d[1] * k) / ul, (ud[2] - d[2] * k) / ul, (ud[3] - d[3] * k) / ul }
  return { A * dd[1] - H * nd[1], A * dd[2] - H * nd[2], A * dd[3] - H * nd[3] }
end
local function inertiaWorld(R)
  -- I = sum_i I_i c_i c_i^T
  local Iv = { I1, I3, I1 }
  local M = { { 0, 0, 0 }, { 0, 0, 0 }, { 0, 0, 0 } }
  for k = 1, 3 do
    local c = R[k]
    for i = 1, 3 do for j = 1, 3 do M[i][j] = M[i][j] + Iv[k] * c[i] * c[j] end end
  end
  return M
end
local function solve3(M, b)
  local a, bb, c = M[1], M[2], M[3]
  local det = a[1] * (bb[2] * c[3] - bb[3] * c[2]) - a[2] * (bb[1] * c[3] - bb[3] * c[1]) + a[3] * (bb[1] * c[2] - bb[2] * c[1])
  local function col(v_, i)
    local m = { { a[1], a[2], a[3] }, { bb[1], bb[2], bb[3] }, { c[1], c[2], c[3] } }
    for r = 1, 3 do m[r][i] = v_[r] end
    return m[1][1] * (m[2][2] * m[3][3] - m[2][3] * m[3][2]) - m[1][2] * (m[2][1] * m[3][3] - m[2][3] * m[3][1])
           + m[1][3] * (m[2][1] * m[3][2] - m[2][2] * m[3][1])
  end
  return { col(b, 1) / det, col(b, 2) / det, col(b, 3) / det }
end
-- the derivatives: (R, w, C) -> (Rdot, wdot, Cdot)
local function deriv(R, w)
  local n = R[2]
  local r, d, u, ul = contact(n)
  local nd = cross(w, n)
  local rd = contactRate(n, nd, d, ul)
  local Iw = inertiaWorld(R)
  local L = { dot(Iw[1], w), dot(Iw[2], w), dot(Iw[3], w) }
  -- (I + m (r.r - r r^T)) wdot = -w x I w + m r x (g up - w x rdot) + the rolling resistance's moment
  local rr = dot(r, r)
  local M = {}
  for i = 1, 3 do
    M[i] = {}
    for j = 1, 3 do M[i][j] = Iw[i][j] + MASS * ((i == j and rr or 0) - r[i] * r[j]) end
  end
  local wl = cross(w, L)
  local wrd = cross(w, rd)
  local q = { -wrd[1], G - wrd[2], -wrd[3] }
  local rq = cross(r, q)
  local b = { -wl[1] + MASS * rq[1], -wl[2] + MASS * rq[2], -wl[3] + MASS * rq[3] }
  -- rolling resistance: DELTA m g against the turning about a level axis
  local wh = math.sqrt(w[1] * w[1] + w[3] * w[3])
  if DELTA > 0 and wh > 1e-9 then
    b[1] = b[1] - DELTA * MASS * G * w[1] / wh
    b[3] = b[3] - DELTA * MASS * G * w[3] / wh
  end
  -- the drag on its centre's sideways motion, -KD m v: the contact's force
  -- is less by it, so its moment about the centre is r x (-F) less
  if KD > 0 then
    local vC = cross(r, w)
    local F = { -KD * MASS * vC[1], 0, -KD * MASS * vC[3] }
    local rf = cross(r, F)
    b[1], b[2], b[3] = b[1] - rf[1], b[2] - rf[2], b[3] - rf[3]
  end
  local wd = solve3(M, b)
  local Rd = { cross(w, R[1]), cross(w, R[2]), cross(w, R[3]) }
  local Cd = cross(r, w)                           -- -w x r: the contact point still
  return Rd, wd, Cd
end
local S = {}
local function rk4(h)
  local function add(R, w, C, Rd, wd, Cd, s)
    local R2 = {}
    for k = 1, 3 do R2[k] = { R[k][1] + s * Rd[k][1], R[k][2] + s * Rd[k][2], R[k][3] + s * Rd[k][3] } end
    return R2, { w[1] + s * wd[1], w[2] + s * wd[2], w[3] + s * wd[3] }, { C[1] + s * Cd[1], C[2] + s * Cd[2], C[3] + s * Cd[3] }
  end
  local R, w, C = S.R, S.w, S.C
  local R1d, w1d, C1d = deriv(R, w)
  local Ra, wa, Ca = add(R, w, C, R1d, w1d, C1d, h / 2)
  local R2d, w2d, C2d = deriv(Ra, wa)
  local Rb, wb, Cb = add(R, w, C, R2d, w2d, C2d, h / 2)
  local R3d, w3d, C3d = deriv(Rb, wb)
  local Rc, wc, Cc = add(R, w, C, R3d, w3d, C3d, h)
  local R4d, w4d, C4d = deriv(Rc, wc)
  for k = 1, 3 do
    for i = 1, 3 do
      R[k][i] = R[k][i] + h / 6 * (R1d[k][i] + 2 * R2d[k][i] + 2 * R3d[k][i] + R4d[k][i])
    end
  end
  for i = 1, 3 do
    w[i] = w[i] + h / 6 * (w1d[i] + 2 * w2d[i] + 2 * w3d[i] + w4d[i])
    C[i] = C[i] + h / 6 * (C1d[i] + 2 * C2d[i] + 2 * C3d[i] + C4d[i])
  end
  -- (keep its axes square and unit: Gram-Schmidt)
  local c2 = R[2]
  local l = math.sqrt(dot(c2, c2)); c2[1], c2[2], c2[3] = c2[1] / l, c2[2] / l, c2[3] / l
  local c1 = R[1]
  local k = dot(c1, c2); c1[1], c1[2], c1[3] = c1[1] - k * c2[1], c1[2] - k * c2[2], c1[3] - k * c2[3]
  l = math.sqrt(dot(c1, c1)); c1[1], c1[2], c1[3] = c1[1] / l, c1[2] / l, c1[3] / l
  R[3] = cross(c1, c2)
  -- (and the centre where the contact puts it: its height from the mirror)
  local r = contact(c2)
  C[2] = MIRROR_Y - r[2]
end
local function energy()
  local Iw = inertiaWorld(S.R)
  local w = S.w
  local L = { dot(Iw[1], w), dot(Iw[2], w), dot(Iw[3], w) }
  local v_ = cross(contact(S.R[2]), w)
  return 0.5 * dot(w, L) + 0.5 * MASS * dot(v_, v_) + MASS * G * S.C[2]
end
local function quatFromBasis(xx, xy, xz, yx, yy, yz, zx, zy, zz)
  local tr = xx + yy + zz
  local w, x, y, z
  if tr > 0 then
    local s_ = math.sqrt(tr + 1) * 2
    w, x, y, z = 0.25 * s_, (yz - zy) / s_, (zx - xz) / s_, (xy - yx) / s_
  elseif xx > yy and xx > zz then
    local s_ = math.sqrt(1 + xx - yy - zz) * 2
    w, x, y, z = (yz - zy) / s_, 0.25 * s_, (yx + xy) / s_, (zx + xz) / s_
  elseif yy > zz then
    local s_ = math.sqrt(1 + yy - xx - zz) * 2
    w, x, y, z = (zx - xz) / s_, (yx + xy) / s_, 0.25 * s_, (zy + yz) / s_
  else
    local s_ = math.sqrt(1 + zz - xx - yy) * 2
    w, x, y, z = (xy - yx) / s_, (zx + xz) / s_, (zy + yz) / s_, 0.25 * s_
  end
  return btQuaternion(x, y, z, w)
end
local function show()
  local R, C = S.R, S.C
  local tr = btTransform(quatFromBasis(R[1][1], R[1][2], R[1][3], R[2][1], R[2][2], R[2][3], R[3][1], R[3][2], R[3][3]),
                         btVector3(C[1], C[2], C[3]))
  disc.trans = tr
  mark.trans = tr
end

-- ---------------------------------------------------------------------
-- the theory: going round in place at a lean alpha
-- ---------------------------------------------------------------------
local function omegaSteady(alpha)
  local sn, cs = math.sin(alpha), math.cos(alpha)
  return math.sqrt(MASS * G * A * (A * cs - H * sn) / (sn * (I1 * A * cs - I3 * H * sn)))
end

local t, t0, flat, restartAt
local samples = {}
local function setGoing()
  holdStart()
  t, t0, flat, restartAt = 0, nil, false, nil
  samples = {}
  DELTA = v:getParam("rolling") * 1e-4
  local alpha = math.rad(envnum("ED_TILT", 30))
  local Om = omegaSteady(alpha)
  -- its axis tilted alpha from the upright, toward -x (its low side toward -x)
  local ca, sa = math.cos(alpha), math.sin(alpha)
  local n = { -sa, ca, 0 }
  local ex = { ca, sa, 0 }                         -- in its plane, up the lean
  S.R = { { ex[1], ex[2], ex[3] }, n, { 0, 0, 1 } }
  S.R[3] = cross(S.R[1], S.R[2])
  local r = contact(n)
  S.C = { 0, MIRROR_Y - r[2], 0 }
  -- turning: along the line from the contact to the centre, so the centre
  -- stays still; its size such that the axis goes round at Om
  local cp = { -r[1], -r[2], -r[3] }
  local l = Om * sa / A                            -- (its part along ex is Om sin(alpha))
  S.w = { l * cp[1], l * cp[2], l * cp[3] }
  -- (scale so the part along ex is exactly Om sin alpha)
  local k = Om * sa / dot(S.w, ex)
  S.w = { S.w[1] * k, S.w[2] * k, S.w[3] * k }
  S.E0 = energy()
  S.phiAcc, S.prevPhi, S.win, S.checks = 0, nil, nil, {}
  show()
  print(string.format("\n--- set going: leaning %.0f degrees, going round %.2f times a second; rolling resistance %.0f microns ---",
                      math.deg(alpha), Om / (2 * math.pi), DELTA * 1e4))
  print(string.format("  the disc: %.0f g, %.1f cm across, %.1f cm thick; I1 %.3f, I3 %.3f kg cm^2", MASS * 1000, 2 * A, W, I1, I3))
end

-- the lean, and the axis's heading
local function leanAndPhi()
  local n = S.R[2]
  return math.acos(math.min(1, math.abs(n[2]))), math.atan2(n[3], n[1])
end
local CHECK_AT = { 25, 20, 15, 10, 6, 4, 2, 1 }
local LOGF = os.getenv("ED_LOG") and io.open(os.getenv("ED_LOG"), "w")
if LOGF then LOGF:write("t,alpha_deg,Omega,Omega_theory,energy,cx,cz\n") end
v:preSim(function(N_)
  if holdPre() then return end
  if flat then return end
  for k = 1, NSTEPS do
    rk4(STEP)
    -- the axis's heading, unwrapped, step by step
    local _, phi = leanAndPhi()
    if S.prevPhi then
      local d = phi - S.prevPhi
      d = (d + math.pi) % (2 * math.pi) - math.pi
      S.phiAcc = S.phiAcc + d
    end
    S.prevPhi = phi
  end
end)
v:postSim(function(N_)
  if holdNow then return end
  t = t + FRAME_DT
  if flat then
    if restartAt and t > restartAt then setGoing() end
    return
  end
  show()
  local alpha = leanAndPhi()
  -- how fast it goes round: over a quarter of a second at a time
  S.win = S.win or { t = t, acc = S.phiAcc, asum = 0, n = 0 }
  S.win.asum, S.win.n = S.win.asum + alpha, S.win.n + 1
  if t - S.win.t >= 0.25 then
    local Om = math.abs((S.phiAcc - S.win.acc) / (t - S.win.t))
    local am = S.win.asum / S.win.n
    samples[#samples + 1] = { t = (t + S.win.t) / 2, a = am, W = Om }
    if LOGF then
      LOGF:write(string.format("%.3f,%.4f,%.3f,%.3f,%.4f,%.4f,%.4f\n", (t + S.win.t) / 2, math.deg(am), Om, omegaSteady(am), energy(),
                               S.C[1], S.C[3]))
    end
    local crossed
    for _, c in ipairs(CHECK_AT) do
      if not S.checks[c] and math.deg(am) <= c then S.checks[c] = true; crossed = true end
    end
    if crossed then
      do
        local th = omegaSteady(am)
        print(string.format("  t=%6.2f s  leaning %5.2f degrees: going round %6.2f times a second (theory, going round in place: %6.2f; %+.2f%%)",
                            t, math.deg(am), Om / (2 * math.pi), th / (2 * math.pi), (Om / th - 1) * 100))
      end
    end
    S.win = { t = t, acc = S.phiAcc, asum = 0, n = 0 }
  end
  -- flat: it has stopped
  if alpha < math.rad(0.3) then
    flat = true
    t0 = t
    print(string.format("  t=%6.2f s  it stops, flat, leaning %.2f degrees, going round %.0f times a second", t,
                        math.deg(alpha), (samples[#samples] and samples[#samples].W or 0) / (2 * math.pi)))
    -- near the end, sqrt(alpha) falls at a steady rate: a straight line
    -- through the last samples (under 2 degrees) finds where it would reach
    -- nothing, t0
    local n, sx, sy, sxx, sxy = 0, 0, 0, 0, 0
    for _, sm in ipairs(samples) do
      if sm.a < math.rad(2) then
        local y = math.sqrt(sm.a)
        n, sx, sy, sxx, sxy = n + 1, sx + sm.t, sy + y, sxx + sm.t * sm.t, sxy + sm.t * y
      end
    end
    if n > 5 then
      local slope = (n * sxy - sx * sy) / (n * sxx - sx * sx)
      local icpt = (sy - slope * sx) / n
      local tz = -icpt / slope
      local kap = math.sqrt(MASS * G * A / I1)
      print(string.format("             sqrt(alpha) falling at %.5f a second (theory, near the end: delta sqrt(m g a / I1) / (3 a) = %.5f);" ..
                          "\n             so it would lie flat at t0 = %.1f s, going round infinitely fast", -slope, DELTA * kap / (3 * A), tz))
      local shown = 0
      for k = #samples, 1, -1 do
        local sm = samples[k]
        if sm.a < math.rad(2) and (shown == 0 or math.abs(sm.t - shown) >= 4) then
          shown = sm.t
          print(string.format("             t=%6.2f s, leaning %.2f degrees: W (t0 - t) = %.0f (theory: 3 a / delta = %.0f)",
                              sm.t, math.deg(sm.a), sm.W * (tz - sm.t), 3 * A / DELTA))
        end
      end
    end
    -- lie it flat
    S.R = { { 1, 0, 0 }, { 0, 1, 0 }, { 0, 0, 1 } }
    S.C = { S.C[1], MIRROR_Y + H, S.C[3] }
    show()
    restartAt = t + 4
  end
  if t > 600 then setGoing() end
end)

-- ---------------------------------------------------------------------
-- keys, help
-- ---------------------------------------------------------------------
common.setCamera(btVector3(0, 26, 42), btVector3(0, 3, 0))
v:addShortcut("R", function(N_) setGoing() end)
v:addShortcut("Z", function(N_)
  local sp = v:getParam("speed") < 0.5 and 1 or 0.25
  v:addParam("speed", sp, 0.05, 2, 0.05, "simulated seconds per real second (Z: 1/4 <-> 1)")
  applyTiming()
end)
v:onParamChanged(function(N_, name, value)
  if name == "speed" or name == "steps" then applyTiming() end
  if name == "rolling" then setGoing() end
end)
v:setHelpText(table.concat({
  "Euler's disk (Euler's Cabinet of Curiosities)",
  "",
  "A steel disc rolls round and round in place on a mirror,",
  "leaning further over and going round faster and faster,",
  "until it stops, flat. Going round in place at a lean",
  "alpha: W^2 = 4 g / (a sin alpha), for a thin disc.",
  "",
  "R   set it going again",
  "Z   slow motion (1/4) <-> real time",
  "",
  "Sliders: rolling (resistance, microns), speed, steps.",
}, "\n"))
if v.onHover then
  local key = objectKey(disc)
  v:onHover(function(N_, obj, x, y, z)
    if objectKey(obj) ~= key then return nil end
    local alpha = leanAndPhi()
    return string.format("Euler's disk\nleaning %.1f degrees; going round in place there takes W = %.1f turns a second (theory)",
                         math.deg(alpha), omegaSteady(alpha) / (2 * math.pi))
  end)
end

setGoing()
