--
-- The Double Pendulum -- Euler's Cabinet of Curiosities
--
-- A pendulum hung from the bottom of another: two bobs, two light rods.
-- Simple to build, and it defies the intuition three ways.
--
--   left    THE BUTTERFLY. Seven double pendulums on one pivot, let go
--           together from the same place -- except that each starts a
--           billionth of a radian further round than the one before: its
--           bottom bob an atom's width (2 angstroms) further along. For
--           five seconds they swing as one. Then, all at once, they fly
--           apart, and never come together again. (Chaos: a difference
--           doubles about every fifth of a second, so a billionth becomes
--           everything in six seconds.)
--
--   middle  THE TWO PURE SWINGS. The same pendulum can swing for ever in
--           just two simple ways: both rods together, the lower swinging
--           sqrt 2 times as far (slow); or the rods opposed (fast, 2.4
--           times as often -- an irrational ratio). Started any other way
--           it does both at once, and never repeats. Left: the slow swing;
--           centre: the fast one; right: let go with only the top rod
--           pulled aside -- half of each.
--
--   right   UPSIDE DOWN. Three double pendulums stood on their heads on
--           pivots shaken up and down 40 times a second. Shaken 0.6 cm,
--           it falls. Shaken 1.0 cm, the floppy two-rod chain stands up,
--           rocking slowly. Shaken 1.6 cm -- harder -- the shaking pumps
--           up a sway, as legs pump a swing, that throws it over and it
--           tumbles. (Kapitza's trick, next door, works for a
--           chain of rods too, but only in a window: David Acheson, 1993.)
--
-- Theory, and what the console checks:
--   The butterfly: energy stays put (to about 1e-9 of the swing's) in each
--   pendulum; the same pendulum stepped twice as finely stays with the
--   first long after the seven have parted -- what you see is the atom's
--   width, not the arithmetic; and how fast nearby swings part (the
--   Lyapunov exponent, Benettin's method) gives when they should part,
--   against when they do.
--   The pure swings (equal bobs, equal rods l, small swings):
--       w^2 = (g / l) (2 -+ sqrt 2),   lower rod / upper = +- sqrt 2
--   and the mixed one moves as the sum of the two, half of each.
--   Upside down: averaged over the shaking (as for Kapitza's pendulum) the
--   chain stands if
--       a w > sqrt((2 + sqrt 2) g l)        (one rod: sqrt(2 g l))
--   and rocks then at the slow frequencies of the averaged forces; the
--   exact answer -- the shaking's effect over one shake, worked out from
--   the swing's equations (Floquet) -- also gives the top of the window,
--   where shaking harder throws it off again. The console gives both, and
--   the rocking's period measured against them.
--
-- THE PENDULUMS: equal bobs on light rods; rods 20 cm (the butterfly), 12
-- cm (the pure swings), 10 cm (upside down).
--
-- PHYSICS: the swing's exact equations (Lagrange's), stepped here: the
-- shaken ones by RK4, 4800 times a second; the others by Bulirsch-Stoer
-- (tenth order), 240 times a second: stepped twice as finely, the
-- butterfly's bottom bob is a few femtometres off after a second, a
-- hundred-thousandth of the atom's width it starts with. Bullet only draws
-- them.
--
-- Keys
--   R   let them all go again
--   Z   slow motion (1/4) <-> real time
--
-- Units: centimetres, kilograms, seconds.
-- Headless testing: DP_SPEED, DP_STEPS, DP_CYCLE (seconds between
-- restarts), DP_LOG=file.csv (the butterfly's spread).
--

local common = require "common"

local G = 981
local function envnum(n, d) return tonumber(os.getenv(n) or "") or d end
local function param(...) v:addParam(...) end
param("gentle", envnum("DP_A1", 0.6), 0.1, 2.5, 0.05, "the first upside-down pendulum's shaking, cm")
param("right", envnum("DP_A2", 1.0), 0.1, 2.5, 0.05, "the second's shaking, cm")
param("hard", envnum("DP_A3", 1.6), 0.1, 2.5, 0.05, "the third's shaking, cm")
param("speed", envnum("DP_SPEED", 1), 0.05, 2, 0.05, "simulated seconds per real second (Z: 1/4 <-> 1)")
param("steps", envnum("DP_STEPS", 4800), 2400, 9600, 1200, "RK4 steps per simulated second, for the shaken ones")
local CYCLE = envnum("DP_CYCLE", 30)

local STEP, NSTEPS, FRAME_DT, NBIG = 1 / 4800, 80, 1 / 60, 4
local function applyTiming()
  local speed = v:getParam("speed")
  NSTEPS = math.max(1, math.floor(v:getParam("steps") * speed / 60 + 0.5))
  NBIG = math.max(1, math.floor(240 * speed / 60 + 0.5))
  FRAME_DT = speed / 60
  STEP = FRAME_DT / NSTEPS
  v.animationPeriod = 16
  common.setTiming(STEP, 0, STEP)
end
applyTiming()
v.gravity = btVector3(0, -G, 0)

local sin, cos, sqrt, abs, pi = math.sin, math.cos, math.sqrt, math.abs, math.pi
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
-- the swing's equations: equal bobs, rods l, angles from hanging straight
-- down, the pivot's own upward acceleration added to g (ge)
-- ---------------------------------------------------------------------
local function accel(t1, t2, w1, w2, l, ge)
  local d = t1 - t2
  local sd, cd = sin(d), cos(d)
  local den = l * (3 - cos(2 * d))
  return (-3 * ge * sin(t1) - ge * sin(t1 - 2 * t2) - 2 * sd * l * (w2 * w2 + w1 * w1 * cd)) / den,
         2 * sd * (2 * l * w1 * w1 + 2 * ge * cos(t1) + l * w2 * w2 * cd) / den
end
-- one RK4 step of a pendulum p (fields t1 t2 w1 w2 l; shaken: a, om) from
-- time tt
local function rk4(p, h, tt)
  local l, t1, t2, w1, w2 = p.l, p.t1, p.t2, p.w1, p.w2
  local ge0, ge1, ge2 = G, G, G
  if p.a then
    local k = p.a * p.om * p.om
    ge0, ge1, ge2 = G - k * cos(p.om * tt), G - k * cos(p.om * (tt + h / 2)), G - k * cos(p.om * (tt + h))
  end
  local a1, b1 = accel(t1, t2, w1, w2, l, ge0)
  local h2 = h / 2
  local a2, b2 = accel(t1 + h2 * w1, t2 + h2 * w2, w1 + h2 * a1, w2 + h2 * b1, l, ge1)
  local a3, b3 = accel(t1 + h2 * (w1 + h2 * a1), t2 + h2 * (w2 + h2 * b1), w1 + h2 * a2, w2 + h2 * b2, l, ge1)
  local a4, b4 = accel(t1 + h * (w1 + h2 * a2), t2 + h * (w2 + h2 * b2), w1 + h * a3, w2 + h * b3, l, ge2)
  local w1b, w1c, w1d = w1 + h2 * a1, w1 + h2 * a2, w1 + h * a3
  local w2b, w2c, w2d = w2 + h2 * b1, w2 + h2 * b2, w2 + h * b3
  p.t1 = t1 + h / 6 * (w1 + 2 * w1b + 2 * w1c + w1d)
  p.t2 = t2 + h / 6 * (w2 + 2 * w2b + 2 * w2c + w2d)
  p.w1 = w1 + h / 6 * (a1 + 2 * a2 + 2 * a3 + a4)
  p.w2 = w2 + h / 6 * (b1 + 2 * b2 + 2 * b3 + b4)
end
-- one Bulirsch-Stoer step (Gragg's modified midpoint with 2, 4, 6, 8 and
-- 10 substeps, extrapolated to none: tenth order) of a pendulum on a fixed
-- pivot. Some 25,000 times as accurate as RK4 at 2400 steps a second, for
-- fewer evaluations.
local GBS_N = { 2, 4, 6, 8, 10 }
local GT1, GT2, GW1, GW2 = {}, {}, {}, {}
local function gbs(p, H)
  local l, t1, t2, w1, w2 = p.l, p.t1, p.t2, p.w1, p.w2
  local fa, fb = accel(t1, t2, w1, w2, l, G)
  for j, n in ipairs(GBS_N) do
    local h = H / n
    local x1, x2, x3, x4 = t1, t2, w1, w2
    local y1, y2, y3, y4 = t1 + h * w1, t2 + h * w2, w1 + h * fa, w2 + h * fb
    for _ = 1, n - 1 do
      local a, b = accel(y1, y2, y3, y4, l, G)
      x1, x2, x3, x4, y1, y2, y3, y4 = y1, y2, y3, y4, x1 + 2 * h * y3, x2 + 2 * h * y4, x3 + 2 * h * a, x4 + 2 * h * b
    end
    local a, b = accel(y1, y2, y3, y4, l, G)
    GT1[j], GT2[j] = 0.5 * (x1 + y1 + h * y3), 0.5 * (x2 + y2 + h * y4)
    GW1[j], GW2[j] = 0.5 * (x3 + y3 + h * a), 0.5 * (x4 + y4 + h * b)
  end
  -- Neville, in h^2
  local k = #GBS_N
  for j = 2, k do
    for i = k, j, -1 do
      local r = (GBS_N[i] / GBS_N[i - j + 1]) ^ 2 - 1
      GT1[i] = GT1[i] + (GT1[i] - GT1[i - 1]) / r
      GT2[i] = GT2[i] + (GT2[i] - GT2[i - 1]) / r
      GW1[i] = GW1[i] + (GW1[i] - GW1[i - 1]) / r
      GW2[i] = GW2[i] + (GW2[i] - GW2[i - 1]) / r
    end
  end
  p.t1, p.t2, p.w1, p.w2 = GT1[k], GT2[k], GW1[k], GW2[k]
end
-- energy per unit bob mass (fixed pivot)
local function energy(p)
  local l = p.l
  return l * l * (p.w1 * p.w1 + 0.5 * p.w2 * p.w2 + p.w1 * p.w2 * cos(p.t1 - p.t2)) - G * l * (2 * cos(p.t1) + cos(p.t2))
end
-- the bobs, relative to the pivot
local function bobs(p)
  local l = p.l
  local x1, y1 = l * sin(p.t1), -l * cos(p.t1)
  return x1, y1, x1 + l * sin(p.t2), y1 - l * cos(p.t2)
end

-- ---------------------------------------------------------------------
-- the table
-- ---------------------------------------------------------------------
local TABLE_Y = 0
block(340, 3, 50, 5, TABLE_Y - 1.5, 0, "#7a4a24")
for _, x in ipairs({ -160, 170 }) do
  for _, z in ipairs({ -21, 21 }) do block(3, 72, 3, x, TABLE_Y - 3 - 36, z, "#4e2e15") end
end
local floor = Plane(0, 1, 0, TABLE_Y - 75, 400)
floor.col = "#3b3f45"
v:add(floor)

-- a drawn pendulum: two rods, two bobs
local KEYS = {}
local function drawn(p, rb, rr, colRod, colBob)
  local d = {}
  for i = 1, 2 do
    local rod = Cylinder(rr, p.l - rb, 0)
    rod.col = colRod
    rod.collides = false
    v:add(rod)
    local bob = Sphere(rb, 0)
    bob.col = colBob
    bob.collides = false
    v:add(bob)
    d[i] = { rod = rod, bob = bob }
    KEYS[objectKey(bob)] = p
    KEYS[objectKey(rod)] = p
  end
  p.draw = d
end
local function rodTrans(x0, y0, x1, y1, z)
  local th = math.atan2(x1 - x0, y1 - y0)
  return btTransform(btQuaternion(btVector3(0, 0, 1), -th) * btQuaternion(btVector3(1, 0, 0), pi / 2),
                     btVector3((x0 + x1) / 2, (y0 + y1) / 2, z))
end
local function show(p, px, py)
  local x1, y1, x2, y2 = bobs(p)
  local d, z = p.draw, p.z
  d[1].rod.trans = rodTrans(px, py, px + x1, py + y1, z)
  d[2].rod.trans = rodTrans(px + x1, py + y1, px + x2, py + y2, z)
  d[1].bob.trans = btTransform(Q0, btVector3(px + x1, py + y1, z))
  d[2].bob.trans = btTransform(Q0, btVector3(px + x2, py + y2, z))
end

-- ---------------------------------------------------------------------
-- the butterfly: seven on one pivot
-- ---------------------------------------------------------------------
local BF_X, BF_Y, BF_L = -112, TABLE_Y + 62, 20
local BF_T0 = math.rad(120)
local BF_D = 1e-9
local BF_COLS = { "#e8e8e8", "#e84a3c", "#f0a030", "#e8d84a", "#4ac85a", "#3a8ae8", "#a04ae8" }
local BF = {}
block(3, BF_Y + 2 - TABLE_Y, 3, BF_X, (BF_Y + 2 + TABLE_Y) / 2, -12, "#4e2e15")
block(3, 3, 14, BF_X, BF_Y + 0.5, -5.5, "#4e2e15")
block(1.2, 1.2, 6, BF_X, BF_Y, 0, "#8a8f96")
for k = 1, 7 do
  local p = { l = BF_L, z = (4 - k) * 0.3, name = "the butterfly", k = k }
  drawn(p, 1.3, 0.25, "#c8cdd4", BF_COLS[k])
  BF[k] = p
end
-- the same as the first, stepped twice as finely; and the first's shadow,
-- for the Lyapunov exponent (neither drawn)
local TWIN, SHADOW = { l = BF_L }, { l = BF_L }
local SH_D0 = 1e-8
local OM0 = sqrt(G / BF_L)

-- ---------------------------------------------------------------------
-- the two pure swings
-- ---------------------------------------------------------------------
local MD_Y, MD_L, MD_A = TABLE_Y + 42, 12, math.rad(5)
local S2 = sqrt(2)
local W_SLOW = sqrt(G / MD_L * (2 - S2))
local W_FAST = sqrt(G / MD_L * (2 + S2))
-- the swing's size changes its period a little: averaging the next terms
-- of the swing's equations (the fourth powers of the angles) over the pure
-- swings gives the first correction (Lindstedt; the normal form). With J
-- each pure swing's action, the averaged extra energy <H4> = -<L4> is a
-- quadratic a J1^2 + b J1 J2 + c J2^2, and each swing goes round faster by
-- its derivative. (For one pendulum this gives the period's familiar
-- 1 + A^2 / 16.)
local MV = { { 1, S2 }, { 1, -S2 } }
local W0 = { W_SLOW, W_FAST }
local MMOD = {}
for k = 1, 2 do
  local a, b = MV[k][1], MV[k][2]
  MMOD[k] = 2 * a * a + 2 * a * b + b * b
end
local function ampOf(k, J) return sqrt(2 * J / (W0[k] * MD_L * MD_L * MMOD[k])) end
local function actionOf(k, A) return 0.5 * W0[k] * MD_L * MD_L * MMOD[k] * A * A end
local function H4avg(J1, J2)
  local A1, A2 = ampOf(1, J1), ampOf(2, J2)
  local N, sum = 8, 0
  for i = 0, N - 1 do
    for j = 0, N - 1 do
      local c1, s1, c2, s2 = cos(2 * pi * i / N), sin(2 * pi * i / N), cos(2 * pi * j / N), sin(2 * pi * j / N)
      local th1 = A1 * c1 + A2 * c2
      local th2 = S2 * (A1 * c1 - A2 * c2)
      local d1 = -A1 * W0[1] * s1 - A2 * W0[2] * s2
      local d2 = -S2 * (A1 * W0[1] * s1 - A2 * W0[2] * s2)
      local D = th1 - th2
      sum = sum - 0.5 * MD_L * MD_L * d1 * d2 * D * D + G * MD_L * (2 * th1 ^ 4 + th2 ^ 4) / 24
    end
  end
  return -sum / (N * N)
end
local H4a, H4c = H4avg(1, 0), H4avg(0, 1)
local H4b = H4avg(1, 1) - H4a - H4c
-- the two frequencies, swinging A1 and A2 (the top rod's share of each)
local function swingW(A1, A2)
  local J1, J2 = actionOf(1, A1), actionOf(2, A2)
  return W_SLOW + 2 * H4a * J1 + H4b * J2, W_FAST + H4b * J1 + 2 * H4c * J2
end
local MODES = {
  { x = -55, name = "the slow pure swing: both rods together", short = "Slow swing", r = S2, w = W_SLOW, mode = 1 },
  { x = -25, name = "the fast pure swing: the rods opposed", short = "Fast swing", r = -S2, w = W_FAST, mode = 2 },
  { x = 5, name = "let go with the top rod pulled aside: half of each pure swing", short = "Mixed", mixed = true },
}
block(80, 3, 3, -25, MD_Y + 1.5, -6, "#4e2e15")
for _, x in ipairs({ -66, 16 }) do block(3, MD_Y + 3 - TABLE_Y, 3, x, (MD_Y + 3 + TABLE_Y) / 2, -6, "#4e2e15") end
for _, m in ipairs(MODES) do
  m.l, m.z = MD_L, 0
  block(1.2, 1.2, 7, m.x, MD_Y, -2.5, "#8a8f96")
  drawn(m, 1.1, 0.22, "#c8cdd4", m.mixed and "#3a8ae8" or "#c8a04a")
end

-- ---------------------------------------------------------------------
-- upside down: three shaken pivots
-- ---------------------------------------------------------------------
local SH_F = 40
local SH_OM = 2 * pi * SH_F
local SH_Y, SH_L = TABLE_Y + 35, 10
local SHAKEN = {
  { x = 45, param = "gentle", short = "0.6 cm" },
  { x = 95, param = "right", short = "1.0 cm" },
  { x = 145, param = "hard", short = "1.6 cm" },
}
for _, s in ipairs(SHAKEN) do
  s.l, s.z, s.om = SH_L, 0, SH_OM
  block(10, 10, 10, s.x, TABLE_Y + 5, 0, "#3a3f46")
  s.blockDraw = block(2.4, 2.4, 2.4, s.x, SH_Y, 0, "#8a8f96")
  s.shaft = block(0.8, SH_Y - TABLE_Y - 10, 0.8, s.x, 0, 0, "#c8cdd4")
  drawn(s, 1.0, 0.2, "#d0d4da", "#c8a04a")
end

-- the averaged forces (Kapitza, Acheson): with s = a^2 w^2 / (2 g l) the
-- stiffness about upright, over m g l, is [[4s-2, -2s], [-2s, 2s-1]] and
-- the inertia, over m l^2, [[2, 1], [1, 1]]: its slow frequencies, squared
local function averagedW2(a)
  local s = a * a * SH_OM * SH_OM / (2 * G * SH_L)
  -- inverse inertia [[1,-1],[-1,2]] times stiffness
  local k11, k12, k22 = 4 * s - 2, -2 * s, 2 * s - 1
  local A, B, C, D = k11 - k12, k12 - k22, -k11 + 2 * k12, -k12 + 2 * k22
  local tr, det = A + D, A * D - B * C
  local disc = sqrt(math.max(0, tr * tr / 4 - det))
  return (tr / 2 - disc) * G / SH_L, (tr / 2 + disc) * G / SH_L
end
local A_AVG = sqrt((2 + S2) * G * SH_L) / SH_OM
-- exact: the small swings about upright over one shake (the monodromy
-- matrix, by RK4), its traces giving the Floquet multipliers. Returns
-- stable, and the two slow frequencies if so
local function floquet(a)
  local T = 1 / SH_F
  local n = 400
  local h = T / n
  local k = a * SH_OM * SH_OM
  local function f(tt, y)
    local ge = (G - k * cos(SH_OM * tt)) / SH_L
    return { y[3], y[4], ge * (2 * y[1] - y[2]), ge * (-2 * y[1] + 2 * y[2]) }
  end
  local Mo = {}
  for c = 1, 4 do
    local y = { 0, 0, 0, 0 }
    y[c] = 1
    local tt = 0
    for _ = 1, n do
      local k1 = f(tt, y)
      local y2 = {}
      for i = 1, 4 do y2[i] = y[i] + h / 2 * k1[i] end
      local k2 = f(tt + h / 2, y2)
      for i = 1, 4 do y2[i] = y[i] + h / 2 * k2[i] end
      local k3 = f(tt + h / 2, y2)
      for i = 1, 4 do y2[i] = y[i] + h * k3[i] end
      local k4 = f(tt + h, y2)
      for i = 1, 4 do y[i] = y[i] + h / 6 * (k1[i] + 2 * k2[i] + 2 * k3[i] + k4[i]) end
      tt = tt + h
    end
    Mo[c] = y      -- column c
  end
  local tr, tr2 = 0, 0
  for i = 1, 4 do
    tr = tr + Mo[i][i]
    for j = 1, 4 do tr2 = tr2 + Mo[j][i] * Mo[i][j] end
  end
  -- symplectic: lambda + 1/lambda = mu, mu^2 - tr mu + (b - 2) = 0
  local b = (tr * tr - tr2) / 2
  local disc = tr * tr - 4 * (b - 2)
  if disc < 0 then return false end
  local m1, m2 = (tr - sqrt(disc)) / 2, (tr + sqrt(disc)) / 2
  if abs(m1) >= 2 - 1e-9 or abs(m2) >= 2 - 1e-9 then return false end
  return true, math.acos(m2 / 2) / T, math.acos(m1 / 2) / T
end
local function edge(lo, hi)     -- stable at one end, not the other
  local sLo = floquet(lo)
  for _ = 1, 40 do
    local mid = (lo + hi) / 2
    if (floquet(mid)) == sLo then lo = mid else hi = mid end
  end
  return (lo + hi) / 2
end
local A_LO, A_HI = edge(0.3, 1.0), edge(1.0, 2.5)

-- ---------------------------------------------------------------------
-- letting them go
-- ---------------------------------------------------------------------
local t = 0
local BFR      -- the butterfly's record
local LOGF = os.getenv("DP_LOG") and io.open(os.getenv("DP_LOG"), "w")
if LOGF then LOGF:write("t,next_cm,farthest_cm,twin_cm\n") end
local function setp(p, t1, t2)
  p.t1, p.t2, p.w1, p.w2 = t1, t2, 0, 0
end
local function letGo()
  t = 0
  print(string.format("\n--- let go (again every %d s) ---", CYCLE))
  -- the butterfly
  for k, p in ipairs(BF) do setp(p, BF_T0 + (k - 1) * BF_D, BF_T0); p.E0 = energy(p); p.dE = 0 end
  setp(TWIN, BF_T0, BF_T0)
  setp(SHADOW, BF_T0 + SH_D0, BF_T0)
  BFR = { lyap = 0, nextSec = 1, parted = {}, twinParted = nil }
  print(string.format("  The butterfly: seven double pendulums, rods %d cm, let go from %.0f degrees, each a billionth of a radian" ..
                      "\n  further round than the last (its bottom bob %.1f angstroms further along)", BF_L, math.deg(BF_T0),
                      BF_L * BF_D * 1e8))
  -- the pure swings
  print(string.format("  The pure swings, rods %d cm, let go at %.0f degrees: theory (small swings) the slow one %.4f s, lower rod" ..
                      "\n  sqrt 2 = %.4f times as far, the same way; the fast one %.4f s, -sqrt 2 times; the mixed one their sum." ..
                      "\n  Swinging A radians, a little slower: the slow one by 1 + %.4f A^2, the fast one by 1 + %.4f A^2", MD_L,
                      math.deg(MD_A), 2 * pi / W_SLOW, S2, 2 * pi / W_FAST,
                      -(swingW(1e-3, 0) - W_SLOW) / W_SLOW * 1e6, -(select(2, swingW(0, 1e-3)) - W_FAST) / W_FAST * 1e6))
  for _, m in ipairs(MODES) do
    if m.mixed then setp(m, MD_A, 0) else setp(m, MD_A, m.r * MD_A) end
    m.cross, m.prev, m.max1, m.max2, m.dev, m.dev0, m.reported = {}, nil, 0, 0, 0, 0, false
    if m.mixed then m.ws, m.wf = swingW(MD_A / 2, MD_A / 2) end
  end
  -- upside down
  print(string.format("  Upside down, rods %d cm, shaken at %d Hz, tilted 4 degrees:" ..
                      "\n    averaged over the shaking (Kapitza, Acheson) it stands if a w > sqrt((2 + sqrt 2) g l): a > %.3f cm" ..
                      "\n    exactly (Floquet), it stands if %.3f cm < a < %.3f cm", SH_L, SH_F, A_AVG, A_LO, A_HI))
  for _, s in ipairs(SHAKEN) do
    s.a = v:getParam(s.param)
    -- tilted along the slow rocking: the lower rod sqrt 2 times as far
    setp(s, pi + math.rad(4), pi + S2 * math.rad(4))
    s.cycSum, s.cycN, s.cyc, s.lastMean, s.cross, s.fell, s.maxDev, s.reported = 0, 0, nil, nil, {}, nil, 0, false
    local st, f1 = floquet(s.a)
    s.stable = st
    local short = string.format("shaken %.2f cm", s.a)
    if st then
      local w2a = averagedW2(s.a)
      s.Tex, s.Tavg = 2 * pi / f1, (w2a > 0) and 2 * pi / sqrt(w2a) or nil
      print(string.format("    %s: it should stand, rocking slowly with a period of %.3f s (exact; averaged: %s)", short, s.Tex,
                          s.Tavg and string.format("%.3f s", s.Tavg) or "it falls"))
    else
      print(string.format("    %s: it should %s", short, s.a < A_LO and "fall: not shaken hard enough"
                          or "be thrown over: shaken too hard, the shaking pumps up a sway"))
    end
  end
end

-- ---------------------------------------------------------------------
-- stepping
-- ---------------------------------------------------------------------
local function wrap(x) return (x + pi) % (2 * pi) - pi end
v:preSim(function(N_)
  for k = 1, NSTEPS do
    local tt = t + (k - 1) * STEP
    -- the shaken ones: every step
    for _, s in ipairs(SHAKEN) do
      rk4(s, STEP, tt)
      -- the angle from upright averaged over each shake
      local th = wrap(s.t1 - pi)
      s.cycSum, s.cycN = s.cycSum + th, s.cycN + 1
      local cyc = math.floor((tt + STEP) * SH_F + 1e-9)
      if s.cyc and cyc ~= s.cyc then
        local mean = s.cycSum / s.cycN
        s.cycSum, s.cycN = 0, 0
        local tc = s.cyc / SH_F + 0.5 / SH_F
        if not s.fell and (abs(mean) > pi / 2 or abs(wrap(s.t2 - pi)) > pi / 2) then
          s.fell = tc
          print(string.format("    shaken %.2f cm: %s at %.2f s", s.a, s.a > A_HI and "the shaking pumps up a sway and throws it over" or "falls", tc))
        end
        if not s.fell then
          s.maxDev = math.max(s.maxDev, abs(mean))
          if s.lastMean and s.lastMean < 0 and mean >= 0 then
            s.cross[#s.cross + 1] = tc - (1 / SH_F) * mean / (mean - s.lastMean)
          end
        end
        s.lastMean = mean
      end
      s.cyc = cyc
    end
  end
  -- the others: Bulirsch-Stoer, NBIG steps a frame
  local h = FRAME_DT / NBIG
  for j = 1, NBIG do
    local te = t + j * h
    for _, p in ipairs(BF) do gbs(p, h) end
    gbs(TWIN, h / 2)
    gbs(TWIN, h / 2)
    gbs(SHADOW, h)
    for _, m in ipairs(MODES) do
      gbs(m, h)
      -- the pure swing's own measure: its share of the motion
      local q = m.mode and (m.t1 + m.t2 / m.r) / 2 or m.t1
      if m.prev and m.prev < 0 and q >= 0 then
        m.cross[#m.cross + 1] = te - h * q / (q - m.prev)
      end
      m.prev = q
      if te < 20 then
        m.max1, m.max2 = math.max(m.max1, abs(m.t1)), math.max(m.max2, abs(m.t2))
        if m.mixed and te < 10 + 1e-9 then
          local c1, c2 = cos(m.ws * te), cos(m.wf * te)
          local p1, p2 = MD_A / 2 * (c1 + c2), MD_A / 2 * S2 * (c1 - c2)
          m.dev = math.max(m.dev, abs(m.t1 - p1), abs(m.t2 - p2))
          c1, c2 = cos(W_SLOW * te), cos(W_FAST * te)
          p1, p2 = MD_A / 2 * (c1 + c2), MD_A / 2 * S2 * (c1 - c2)
          m.dev0 = math.max(m.dev0, abs(m.t1 - p1), abs(m.t2 - p2))
        end
      end
    end
  end
end)

local function spread(p, q)
  local _, _, ax, ay = bobs(p)
  local _, _, bx, by = bobs(q)
  return sqrt((ax - bx) ^ 2 + (ay - by) ^ 2)
end
local function fmtLen(cm)
  local mtr = cm / 100
  if mtr < 1e-12 then return string.format("%.3g fm", mtr * 1e15)
  elseif mtr < 1e-10 then return string.format("%.1f pm", mtr * 1e12)
  elseif mtr < 1e-9 then return string.format("%.1f angstroms", mtr * 1e10)
  elseif mtr < 1e-6 then return string.format("%.1f nm", mtr * 1e9)
  elseif mtr < 1e-3 then return string.format("%.1f microns", mtr * 1e6)
  elseif mtr < 1e-2 then return string.format("%.2f mm", mtr * 1e3)
  else return string.format("%.1f cm", cm) end
end

v:postSim(function(N_)
  t = t + FRAME_DT
  -- the butterfly
  for _, p in ipairs(BF) do
    show(p, BF_X, BF_Y)
    p.dE = math.max(p.dE, abs(energy(p) - p.E0))
  end
  -- its shadow, pulled back every quarter second
  if not BFR.lastRenorm or t - BFR.lastRenorm >= 0.25 - 1e-9 then
    local d1, d2 = SHADOW.t1 - BF[1].t1, SHADOW.t2 - BF[1].t2
    local d3, d4 = (SHADOW.w1 - BF[1].w1) / OM0, (SHADOW.w2 - BF[1].w2) / OM0
    local d = sqrt(d1 * d1 + d2 * d2 + d3 * d3 + d4 * d4)
    if BFR.lastRenorm then BFR.lyap = BFR.lyap + math.log(d / SH_D0) end
    local f = SH_D0 / d
    SHADOW.t1, SHADOW.t2 = BF[1].t1 + d1 * f, BF[1].t2 + d2 * f
    SHADOW.w1, SHADOW.w2 = BF[1].w1 + d3 * f * OM0, BF[1].w2 + d4 * f * OM0
    BFR.lastRenorm = t
  end
  local nxt, far, twin = spread(BF[1], BF[2]), spread(BF[1], BF[7]), spread(BF[1], TWIN)
  if LOGF then LOGF:write(string.format("%.4f,%.6e,%.6e,%.6e\n", t, nxt, far, twin)) end
  if t >= BFR.nextSec - 1e-9 and BFR.nextSec <= 8 then
    print(string.format("    t=%d s  the bottom bobs: the next one %s apart, the farthest %s  (the first, stepped twice as finely: %s)",
                        BFR.nextSec, fmtLen(nxt), fmtLen(far), fmtLen(twin)))
    BFR.nextSec = BFR.nextSec + 1
  end
  if not BFR.splitAt and nxt > 1 then BFR.splitAt = t end
  if not BFR.twinAt and twin > 1 then BFR.twinAt = t end
  -- the pure swings
  for _, m in ipairs(MODES) do
    show(m, m.x, MD_Y)
    if not m.reported and t >= 20 then
      m.reported = true
      if m.mixed then
        print(string.format("  Mixed: over the first 10 s it moves as half of each pure swing, each at its own period for its size," ..
                            "\n    to within %.4f degrees (%.2f%% of its %.0f; with the small-swing periods, %.2f degrees)",
                            math.deg(m.dev), m.dev / MD_A * 100, math.deg(MD_A), math.deg(m.dev0)))
      else
        local n = #m.cross - 1
        local per = (m.cross[#m.cross] - m.cross[1]) / n
        local th0 = 2 * pi / m.w
        local wA = m.mode == 1 and swingW(MD_A, 0) or select(2, swingW(0, MD_A))
        local th = 2 * pi / wA
        print(string.format("  %s: a period of %.5f s over %d swings (theory %.5f s for its size, %+.3f%%; small swings %.5f s);" ..
                            "\n    lower rod / upper %.4f (theory %+.4f)",
                            m.short, per, n, th, (per / th - 1) * 100, th0, (m.r > 0 and 1 or -1) * m.max2 / m.max1, m.r))
      end
    end
  end
  -- upside down
  for _, s in ipairs(SHAKEN) do
    local py = SH_Y + s.a * cos(SH_OM * t)
    s.blockDraw.trans = btTransform(Q0, btVector3(s.x, py, 0))
    s.shaft.trans = btTransform(Q0, btVector3(s.x, (py - 1.2 + TABLE_Y + 10) / 2, 0))
    show(s, s.x, py)
    if not s.reported and t >= 12 then
      s.reported = true
      if s.fell then
        print(string.format("    shaken %.2f cm: it %s (%s)", s.a, s.a > A_HI and "was thrown over by the sway the shaking pumped up" or "fell",
                            s.stable and "it shouldn't have" or "as it should"))
      elseif #s.cross >= 3 then
        local n = #s.cross - 1
        local per = (s.cross[#s.cross] - s.cross[1]) / n
        print(string.format("    shaken %.2f cm: it stands, rocking up to %.1f degrees: a period of %.3f s over %d rocks" ..
                            " (exact %.3f s, %+.1f%%; averaged %s)", s.a, math.deg(s.maxDev), per, n, s.Tex,
                            (per / s.Tex - 1) * 100, s.Tavg and string.format("%.3f s, %+.1f%%", s.Tavg, (per / s.Tavg - 1) * 100)
                            or "-"))
      else
        print(string.format("    shaken %.2f cm: it stands (%s)", s.a, s.stable and "as it should" or "it shouldn't have"))
      end
    end
  end
  if t >= CYCLE - 1e-9 then
    -- the butterfly's summing up
    local worst = 0
    for _, p in ipairs(BF) do worst = math.max(worst, p.dE / (G * BF_L)) end
    local lam = BFR.lyap / (BFR.lastRenorm or t)
    local start = BF_L * BF_D
    print(string.format("  The butterfly, over %d s: energy steady in all seven to %.1e of m g l;" ..
                        "\n    nearby swings part at %.2f per second (Lyapunov, Benettin's method): doubling every %.3f s," ..
                        "\n    so %s grows to 1 cm in about ln(1 cm / %s) / %.2f = %.1f s; the next one got there at %s" ..
                        "\n    and the first, stepped twice as finely, only at %s", CYCLE, worst, lam, math.log(2) / lam,
                        fmtLen(start), fmtLen(start), lam, math.log(1 / start) / lam,
                        BFR.splitAt and string.format("%.1f s", BFR.splitAt) or "-",
                        BFR.twinAt and string.format("%.1f s", BFR.twinAt) or "not at all"))
    letGo()
  end
end)

-- ---------------------------------------------------------------------
-- keys, help
-- ---------------------------------------------------------------------
common.setCamera(btVector3(10, 52, 235), btVector3(10, 42, 0))
v:addShortcut("R", function(N_) letGo() end)
v:addShortcut("Z", function(N_)
  local sp = v:getParam("speed") < 0.5 and 1 or 0.25
  v:addParam("speed", sp, 0.05, 2, 0.05, "simulated seconds per real second (Z: 1/4 <-> 1)")
  applyTiming()
end)
v:onParamChanged(function(N_, name, value)
  if name == "speed" or name == "steps" then applyTiming() end
  if name == "gentle" or name == "right" or name == "hard" then letGo() end
end)
v:setHelpText(table.concat({
  "The double pendulum (Euler's Cabinet of Curiosities)",
  "",
  "Left: the butterfly. Seven let go a billionth of a radian",
  "apart swing as one for five seconds, then fly apart.",
  "Middle: the two pure swings, slow and fast, and a mix.",
  "Right: upside down on shaken pivots: shaken too little it",
  "falls, just right it stands; too hard, the shaking pumps",
  "up a sway that throws it over.",
  "",
  "R   let them all go again",
  "Z   slow motion (1/4) <-> real time",
  "",
  "Sliders: gentle, right, hard (the shaking, cm), speed, steps.",
}, "\n"))
if v.onHover then
  v:onHover(function(N_, obj, x, y, z)
    local p = KEYS[objectKey(obj)]
    if not p then return nil end
    if p.k then
      return string.format("The butterfly: pendulum %d of 7, let go %d billionths of a radian further round than the white one",
                           p.k, p.k - 1)
    elseif p.om then
      return string.format("Upside down, shaken %.2f cm at %d Hz: it stands if %.2f < a < %.2f cm", p.a, SH_F, A_LO, A_HI)
    else
      return p.name
    end
  end)
end

letGo()
