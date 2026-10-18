--
-- checks/ch13.lua -- lib/ch13.lua against Ch. 13's figures
--
-- DEFINITIONS (printed values): F(r) is Fig. 13.3's split-Newtonian law,
-- 100/r repelling (> 0) inside D = 1 m and attracting (< 0) out to
-- Dmax = 4 m (book/ch13.md E2: the figure's numbers fit 100/r, not 1/r^2);
-- F_eta(r) = F(r) x eta(r), with eta from Eq. 13.9 at p_d = 1 (Fig. 13.8).
-- Forces in the figure's units; r in metres.
--
-- Run from the ArtificialPhysics folder:
--   lua5.1 checks/ch13.lua      or inside BPP: bpp -f checks/ch13.lua -n 1
--

local here = (arg and arg[0] and arg[0]:match("^(.*)[/\\]checks[/\\][^/\\]*$"))
if here then package.path = here .. "/?.lua;" .. package.path
else package.path = "./?.lua;../?.lua;" .. package.path end
local C13 = require "lib.ch13"

local fails, count = 0, 0
local function check(name, ok, detail)
  count = count + 1
  if not ok then fails = fails + 1 end
  print(string.format("%s %-56s %s", ok and "ok  " or "FAIL", name, detail or ""))
end
local function near(a, b, tol) return math.abs(a - b) <= tol end

local D, DMAX = 1, 4
local function F(r)                       -- Fig. 13.3, > 0 repels
  if r > DMAX then return 0 end
  return (r < D) and 100 / r or -100 / r
end
local function Feta(r) return C13.damp(F(r), r, D, 1) end

-- Fig. 13.3: +200 at 0.5, +100 just inside D, -100 just outside, -25 at 4.
check("Fig. 13.3: F(0.5) = +200, F(1-) = +100, F(1+) = -100, F(4) = -25",
  near(F(0.5), 200, 1e-9) and near(F(1 - 1e-9), 100, 1e-6) and near(F(1 + 1e-9), -100, 1e-6)
  and near(F(4), -25, 1e-9),
  string.format("%.0f %.0f %.0f %.0f", F(0.5), F(1 - 1e-9), F(1 + 1e-9), F(4)))

-- Fig. 13.8 (book/ch13.md E5): eta 0.5 and F +100 at r = 0.5; F = 0 at D;
-- minimum about -50 at r = 2; -25 at r = 4; eta = 1 from 2D on.
check("Fig. 13.8: eta(0.5) = 0.5 and F_eta(0.5) = +100",
  near(C13.eta(0.5, D, 1), 0.5, 1e-12) and near(Feta(0.5), 100, 1e-9),
  string.format("eta %.3f F %.1f", C13.eta(0.5, D, 1), Feta(0.5)))
check("Fig. 13.8: smooth through D (|F_eta| <= 2e-4 within 1e-6 of D)",
  math.abs(Feta(1 - 1e-6)) <= 2e-4 and math.abs(Feta(1 + 1e-6)) <= 2e-4 and Feta(1) == 0,
  string.format("%.2g %.2g", Feta(1 - 1e-6), Feta(1 + 1e-6)))
local rmin, fmin = 0, math.huge
for i = 1, 4000 do
  local r = i / 1000
  if Feta(r) < fmin then rmin, fmin = r, Feta(r) end
end
check("Fig. 13.8: minimum -50 at r = 2 (figure: about -45 to -50)",
  near(fmin, -50, 1e-6) and near(rmin, 2, 1e-9), string.format("min %.2f at r = %.3f", fmin, rmin))
check("Fig. 13.8: eta = 1 for r >= 2D, F_eta(4) = -25",
  C13.eta(2, D, 1) == 1 and C13.eta(3.5, D, 1) == 1 and near(Feta(4), -25, 1e-9))
check("Fig. 13.8: continuous at 2D (eta -> 1 from below)",
  near(C13.eta(2 - 1e-9, D, 1), 1, 1e-8))
check("Fig. 13.8: repulsion still grows inward (F_eta(0.25) > F_eta(0.5) > F_eta(0.75))",
  Feta(0.25) > Feta(0.5) and Feta(0.5) > Feta(0.75), string.format("%.1f %.1f %.1f", Feta(0.25), Feta(0.5), Feta(0.75)))

-- Switched off: pd = 0 (or nil) leaves the law exactly as it was.
local same = true
for i = 1, 400 do
  local r = i / 100
  if C13.damp(F(r), r, D, 0) ~= F(r) or C13.damp(F(r), r, D, nil) ~= F(r) then same = false end
end
check("eta off (p_d = 0 or nil): the force is unchanged, bit for bit", same)

-- Higher p_d damps harder near D and is unchanged at r = 0 and from 2D on.
check("p_d = 2.2 (the 2D drone law): eta(0.5D) = 0.5^2.2, eta(1.5D) = 0.5^2.2",
  near(C13.eta(25, 50, 2.2), 0.5 ^ 2.2, 1e-12) and near(C13.eta(75, 50, 2.2), 0.5 ^ 2.2, 1e-12),
  string.format("%.4f", C13.eta(25, 50, 2.2)))

-- The band (etaWidth w): w = 1 is Eq. 13.9 exactly; a narrower band
-- ramps over |D - r| < w D and leaves the force alone outside it.
local sameW = true
for i = 1, 400 do
  local r = i / 100
  if C13.eta(r, D, 1, 1) ~= C13.eta(r, D, 1) then sameW = false end
end
check("band w = 1 is the book's Eq. 13.9, bit for bit", sameW)
check("band w = 0.2: eta(D +- 0.1 D) = 0.5, eta = 1 outside the band",
  near(C13.eta(0.9, D, 1, 0.2), 0.5, 1e-12) and near(C13.eta(1.1, D, 1, 0.2), 0.5, 1e-12)
  and C13.eta(0.79, D, 1, 0.2) == 1 and C13.eta(1.25, D, 1, 0.2) == 1 and C13.eta(0.5, D, 1, 0.2) == 1)

-- Adaptive friction, Eq. 13.23.
check("Eq. 13.23: a sign change grows mu by kMore (1 - mu)",
  near(C13.adaptMu(0.2, -1, 1, 0.5, 0.05), 0.6, 1e-12) and near(C13.adaptMu(0, 1, -2, 0.2, 0.02), 0.2, 1e-12))
check("Eq. 13.23: same sign or a zero command shrinks mu by kLess mu",
  near(C13.adaptMu(0.5, 1, 2, 0.5, 0.1), 0.45, 1e-12) and near(C13.adaptMu(0.5, 0, 2, 0.5, 0.1), 0.45, 1e-12)
  and near(C13.adaptMu(0.5, 0, 0, 0.5, 0.1), 0.45, 1e-12))
do
  -- a command that flips sign every tick drives mu toward 1; a steady
  -- one drives it to 0; mu stays in [0, 1]
  local mu, ok = 0, true
  for i = 1, 400 do
    mu = C13.adaptMu(mu, (i % 2 == 0) and 1 or -1, (i % 2 == 0) and -1 or 1, 0.2, 0.02)
    if mu < 0 or mu > 1 then ok = false end
  end
  local mu2 = mu
  for _ = 1, 400 do mu2 = C13.adaptMu(mu2, 1, 1, 0.2, 0.02) end
  check("Eq. 13.23: oscillating command -> mu near 1; steady -> mu near 0",
    ok and mu > 0.99 and mu2 < 1e-3, string.format("%.4f then %.2g", mu, mu2))
  check("adaptive friction off (kMore = kLess = 0): mu stays 0",
    C13.adaptMu(0, -1, 1, 0, 0) == 0 and C13.adaptMu(0, 1, 1, 0, 0) == 0)
end

-- The stop rule.
check("stop rule: |F| below the threshold stops, at or above it does not",
  C13.stopped(3, 4, 0, 5.5) and not C13.stopped(3, 4, 0, 5) and not C13.stopped(3, 0, 4, 4.5)
  and C13.stopped(0, 0, 0.01, 0.02))
check("stop rule off (threshold 0 or nil) never stops",
  not C13.stopped(0, 0, 0, 0) and not C13.stopped(0, 0, 0, nil))

-- The 2D particle replica of the drone law (Formations-Newtonian.lua's 2D
-- defaults: G 1500, power 2.2, forceMax 1.5, rad D 50, friction 0.6,
-- timeStep 1): N particles start uniform in a square 2D wide and run the
-- AP update (friction, then every pair force from one snapshot, then
-- v += F, x += v). Reported: bond = mean length / D of pairs closer than
-- 1.2 D; speed = mean |v| in AP units per tick at the end.
local rng = require "lib.rng"
local D50 = 50
local function particles(etaP, range, N, ticks, seed, etaFrom, w)
  local G, P, FMAX, FR = 1500, 2.2, 1.5, 0.6
  local s = rng.new(seed)
  local x, y, vx, vy = {}, {}, {}, {}
  for i = 1, N do x[i], y[i], vx[i], vy[i] = (s:random() * 2 - 1) * D50, (s:random() * 2 - 1) * D50, 0, 0 end
  for tick = 1, ticks do
    local pd = (tick > (etaFrom or 0)) and etaP or 0   -- eta on from tick etaFrom
    local fx, fy = {}, {}
    for i = 1, N do
      fx[i], fy[i] = 0, 0
      for j = 1, N do
        if j ~= i then
          local dx, dy = x[j] - x[i], y[j] - y[i]
          local r = math.sqrt(dx * dx + dy * dy)
          if r < 0.1 then r = 0.1 end
          if r < range * D50 then
            local f = G / r ^ P
            if f > FMAX then f = FMAX end
            if r > D50 then f = -f end
            f = C13.damp(f, r, D50, pd, w)
            fx[i], fy[i] = fx[i] - f * dx / r, fy[i] - f * dy / r
          end
        end
      end
    end
    for i = 1, N do
      vx[i], vy[i] = vx[i] * (1 - FR) + fx[i], vy[i] * (1 - FR) + fy[i]
      x[i], y[i] = x[i] + vx[i], y[i] + vy[i]
    end
  end
  local sum, n, sp = 0, 0, 0
  for i = 1, N do
    sp = sp + math.sqrt(vx[i] ^ 2 + vy[i] ^ 2)
    for j = i + 1, N do
      local r = math.sqrt((x[i] - x[j]) ^ 2 + (y[i] - y[j]) ^ 2)
      if r < 1.2 * D50 then sum, n = sum + r, n + 1 end
    end
  end
  return sum / n / D50, sp / N
end
do
  local N, T = 40, 1500
  local b0, s0 = particles(0, 1.5, N, T, 1)
  check("particles, no eta: lattice at D but dithering (speed > 0.1/tick)",
    math.abs(b0 - 1) < 0.02 and s0 > 0.1, string.format("bond %.3f D, speed %.3f", b0, s0))
  local b1, s1 = particles(1, 1.5, N, T, 1)
  check("particles, eta p=1, range 1.5: settled, compressed to ~0.8 D",
    s1 < 0.01 and b1 > 0.78 and b1 < 0.88, string.format("bond %.3f D, speed %.2g", b1, s1))
  local b2, s2 = particles(1, 1.25, N, T, 1)
  check("particles, eta p=1, range 1.25: settled at D",
    s2 < 0.01 and math.abs(b2 - 1) < 0.03, string.format("bond %.3f D, speed %.2g", b2, s2))
  -- eta switched on only once the lattice has formed (FINDINGS F49): it
  -- settles where it is, at D, not at 0.8 D -- two resting states
  local b3, s3 = particles(1, 1.5, N, T + 1500, 1, T)
  check("particles, eta p=1 switched on after forming, range 1.5: settled at D",
    s3 < 0.01 and math.abs(b3 - 1) < 0.03, string.format("bond %.3f D, speed %.2g", b3, s3))
  -- eta in a narrow band round D (etaWidth 0.2): no trap, even from the
  -- launch (FINDINGS F50)
  local b4, s4 = particles(1, 1.5, N, T, 1, nil, 0.2)
  check("particles, eta p=1 in a band w=0.2 from the launch: settled at D",
    s4 < 0.01 and math.abs(b4 - 1) < 0.03, string.format("bond %.3f D, speed %.2g", b4, s4))
  -- the infinite-lattice balance (FINDINGS F45): x = (1 + c) / (1 + sqrt(3) c),
  -- c = 3^((1 - power) / (2 p_eta)), for second neighbours inside the range
  local c = 3 ^ ((1 - 2.2) / 2)
  local xinf = (1 + c) / (1 + math.sqrt(3) * c)
  check("infinite-lattice balance 0.800 D <= the finite swarm's bond",
    math.abs(xinf - 0.8003) < 1e-3 and b1 >= xinf, string.format("x* %.4f", xinf))
end

if fails == 0 then print(string.format("PASS ch13: %d tests", count))
else print(string.format("FAIL ch13: %d of %d tests failed", fails, count)) end
if not rawget(_G, "v") then os.exit(fails == 0 and 0 or 1) end
