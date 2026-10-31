--
-- checks/ch07.lua -- Ch. 7's theory checks (book/ch07.md, PDF 239-243) on
-- Kerr's own simulator: ch07/kerr.lua, his 2004 Java (ch07/kerr/) in Lua
--
-- 1. The Lua is his Java: four runs (one per experiment, from fixed seeds)
--    end in the state ch07/kerr_reference.txt has from the Java, the same
--    collisions and every value to 1e-9 (mostly bit for bit; the maths
--    libraries' logarithms can differ in the last bit).
-- 2. His code as it is (FINDINGS F92, F93): the gas in the speed box runs ~4%
--    hot, which his drivers report as ~1% (divided by the fastest speed
--    met; Fig. 7.6's level); the density box piles the gas into one corner
--    (his error ~0.19 of his own kind); the one-sided profile in his window
--    gives his file's error (~0.11 at Mach 1.2) and 30-60% by the book's.
-- 3. Why (F93): his fixes, ours, switched on: the three together bring the
--    speed to theory; the box's walls at y put right make the density
--    uniform; the open channel lets the gas drift out of the cells.
-- 4. Obstacles (ours, F94): with Kerr's 2005 layouts the gas loses most of
--    its flow at 10% coverage, where Fig. 7.8 loses 6%.
-- 5. The corridor sweep: Kerr's 2005 thesis logs give Figs. 7.11-7.13, and
--    his Java, rerun, gives his logs (F96, F97).
-- The full sweeps are ch07/sweep.sh's (ch07/theory_runs.txt, ch07/README.md).
--
-- DEFINITIONS (printed values): those of ch07/theory.lua (err, kerr, v2,
-- book), and
--   ref      largest |Lua - Java| / max(|Java|, 1e-300) over x, y, vx, vy
--   out      share of the channel's particles beyond its cells (y > 10 L)
--
-- Run from the ArtificialPhysics folder (about 30 s):
--   lua5.1 checks/ch07.lua
--

local here = (arg and arg[0] and arg[0]:match("^(.*)[/\\]checks[/\\][^/\\]*$"))
if here then package.path = here .. "/?.lua;" .. package.path
else package.path = "./?.lua;../?.lua;" .. package.path; here = "." end
local K = require "ch07.kerr"
local T = require "ch07.theory"

local fails, count = 0, 0
local function check(name, ok, detail)
  count = count + 1
  if not ok then fails = fails + 1 end
  print(string.format("%s %-58s %s", ok and "ok  " or "FAIL", name, detail or ""))
end
local t0 = os.clock()
print("ch07: " .. _VERSION)
local fmt = string.format

-- 1. the reference runs of the Java
local runs, cur = {}, nil
local f = io.open(here .. "/ch07/kerr_reference.txt") or io.open("ch07/kerr_reference.txt")
for line in f:lines() do
  local h = line:match("^# (.*)$")
  if h then
    local w = {}
    for x in h:gmatch("%S+") do w[#w + 1] = x end
    cur = { variant = w[1], seed = tonumber(w[2]), a = { select(3, (unpack or table.unpack)(w)) }, rows = {} }
    runs[#runs + 1] = cur
  elseif line:match("^colsum") then cur.colsum = tonumber(line:match("%d+"))
  else
    local i, x, y, vx, vy = line:match("^(%d+) (%S+) (%S+) (%S+) (%S+)$")
    if i then cur.rows[#cur.rows + 1] = { tonumber(i), tonumber(x), tonumber(y), tonumber(vx), tonumber(vy) } end
  end
end
f:close()
for _, r in ipairs(runs) do
  local a = r.a
  local m = K.new({ variant = r.variant, npart = tonumber(a[1]), ncell_x = tonumber(a[2]), ncell_y = tonumber(a[3]),
                    length = tonumber(a[4]), T = tonumber(a[5]), VLm = tonumber(a[6]), VRm = tonumber(a[7]),
                    dir0 = tonumber(a[8]), dir1 = tonumber(a[9]), seed = r.seed })
  K.step(m, tonumber(a[11]))
  local worst = 0
  for _, row in ipairs(r.rows) do
    local i = row[1]
    local mine = { m.x[i], m.y[i], m.vx[i], m.vy[i] }
    for k = 1, 4 do
      local d = math.abs(mine[k] - row[k + 1]) / math.max(math.abs(row[k + 1]), 1e-300)
      if d > worst then worst = d end
    end
  end
  check(fmt("Lua = Java: %s, %s steps, seed %d", r.variant, a[11], r.seed),
        m.colSum == r.colsum and worst < 1e-9,
        fmt("collisions %d / Java %d, ref %.1e", m.colSum, r.colsum, worst))
end

-- 2 and 3. speed (Exp. 2), T = 273, 2,000 steps
local s0 = T.speed(273, 1, {})
check("speed: his gas runs hot, err +2.5..+5%", s0.err > 0.025 and s0.err < 0.05,
      fmt("err %+.4f v2 %.3f", s0.err, s0.v2))
check("speed: his metric (/ fastest speed) makes it ~1%", s0.kerr > 0.005 and s0.kerr < 0.015,
      fmt("kerr %.4f", s0.kerr))
check("speed: the Maxwellian's shape is kept (0.8862)", math.abs(s0.shape - 0.8862) < 0.01,
      fmt("shape %.4f", s0.shape))
local s3 = T.speed(273, 1, T.fixes("iso,walls,garcia"))
check("speed: iso, walls, garcia: err within 1%, v2 within 2%", math.abs(s3.err) < 0.01 and math.abs(s3.v2 - 1) < 0.02,
      fmt("err %+.4f v2 %.3f", s3.err, s3.v2))

-- density (Exp. 1): 2,000 particles, 3,000 steps
local d0 = T.density(2000, 1, {}, 3000)
local g = d0.grid
local corner = g[4] / 200 / (2000 / 25)
check("density: his walls at y pile the gas at (x = L, y = 0)", corner > 2,
      fmt("corner cell %.2f x N/C, kerr %.3f book %.3f", corner, d0.kerr, d0.book))
local d1 = T.density(2000, 1, T.fixes("walls"), 3000)
check("density: with the walls put right, uniform (book < 10%)", d1.book < 0.10 and d1.book < d0.book / 3,
      fmt("kerr %.3f book %.3f", d1.kerr, d1.book))

-- profile (Exp. 3): one-sided, Mach 1.2, his window (steps 1-2,000)
local kerr, book = 0, 0
for seed = 1, 3 do
  local p = T.profile("one", 1.2, seed, {}, 2000, 1)
  kerr, book = kerr + p.kerr / 3, book + p.book / 3
end
check("profile: his window, his metric = his file's 0.115", math.abs(kerr - 0.115) < 0.02,
      fmt("kerr %.3f", kerr))
check("profile: the book's metric on the same runs: 30-60%", book > 0.3 and book < 0.6,
      fmt("book %.3f", book))
local m = K.new({ variant = "couette", npart = 500, ncell_x = 7, ncell_y = 70, length = 10, T = 273,
                  VLm = 0, VRm = 1.2, dir0 = -1, dir1 = 1, seed = 1 })
K.step(m, 2000)
local out = 0
for i = 0, m.n - 1 do if m.y[i] > 10 * K.L or m.y[i] < 0 then out = out + 1 end end
check("profile: the open channel's gas has left its cells", out / m.n > 0.8,
      fmt("out %.2f at step 2,000", out / m.n))

-- obstacles (ours; F94): Kerr's 2005 layouts in his gas, put right and
-- periodic; Fig. 7.8's setting, V = Mach 4, steps 2,001-4,000
local O = require "ch07.obstacles"
local lay = O.generate(0.3, 1, 40)
local f0 = T.flow("one", 4, 0, "none", 1, 1, 4000, 2001)
check("flow: no obstacles, one-sided linear, slope ~Fig. 7.8's 0.80", f0.slope > 0.7 and f0.slope < 0.85,
      fmt("slope %.3f rel %.3f; layout cover %.3f", f0.slope, f0.rel, lay.cover))
local f1 = T.flow("two", 4, 0.1, "couette", 1, 1, 4000, 2001)
check("flow: 10% obstacles stop most of it (Fig. 7.8: 0.84 V)", f1.rel < 0.5 and math.abs(lay.cover - 0.3) < 1e-9,
      fmt("two-sided, faces moving: rel %.3f, back %.2f", f1.rel, f1.back))

-- 5. The corridor sweep (7.5-7.6; F96, F97): Kerr's 2005 thesis logs
--    (ch07/kerr2005/log/thesis/, 100 runs per setting) are the book's
--    Figs. 7.11-7.13; his robot-number sweep ran at 20% obstacles (the book
--    says 30%); his Java, rerun here (ch07/kerr2005.sh, 5-10 runs per
--    setting, ch07/kerr2005_runs.txt), agrees with his logs.
local function readRuns(path)
  local f = io.open(here .. "/" .. path) or io.open(path)
  if not f then return nil end
  local runs = {}
  for line in f:lines() do
    if line:match(" Run ") then
      local r = { ctl = line:match("^(%S+)") }
      for k, v in line:gmatch("(%a+) (%S+)") do r[k] = tonumber(v) or v end
      runs[#runs + 1] = r
    end
  end
  f:close()
  return runs
end
local function mean(runs, key)
  local s, s2, n = 0, 0, #runs
  for _, r in ipairs(runs) do s, s2 = s + r[key], s2 + r[key] ^ 2 end
  local m = s / n
  return m, math.sqrt(math.max(s2 / n - m * m, 0) * n / math.max(n - 1, 1)), n
end
local L = "ch07/kerr2005/log/thesis/"
local function his(ctl, set) return readRuns(L .. ctl .. "_" .. set .. ".txt") end
local kt0, kt10, kt20, kt30, kt40 = his("KTRobot", "0"), his("KTRobot", "10"), his("KTRobot", "20"), his("KTRobot", "30"), his("KTRobot", "40")
local function m1(r, k) return (mean(r, k)) end
check("Fig. 7.12: KT's total 77% at 0%, 88-90% at 10-40%",
      math.abs(m1(kt0, "Total") - 76.9) < 0.1 and m1(kt10, "Total") > 88 and m1(kt40, "Total") < 90,
      fmt("%.1f %.1f %.1f %.1f %.1f", m1(kt0, "Total"), m1(kt10, "Total"), m1(kt20, "Total"), m1(kt30, "Total"), m1(kt40, "Total")))
check("Fig. 7.13: KT's shadow 68, 81, 76, 78%",
      math.abs(m1(kt10, "Behind") - 68.2) < 0.1 and math.abs(m1(kt20, "Behind") - 81.4) < 0.1
      and math.abs(m1(kt30, "Behind") - 75.7) < 0.1 and math.abs(m1(kt40, "Behind") - 77.7) < 0.1,
      fmt("%.1f %.1f %.1f %.1f", m1(kt10, "Behind"), m1(kt20, "Behind"), m1(kt30, "Behind"), m1(kt40, "Behind")))
local ant5, ant30 = his("AntRobot", "N5"), his("AntRobot", "N30")
check("Fig. 7.11: KT 4,848 steps at 0% to 52,672 at 40%; Ant 126k (N 5) to 57k",
      math.abs(m1(kt0, "Time") - 4848) < 1 and math.abs(m1(kt40, "Time") - 52672) < 1
      and m1(ant5, "Time") > 120000 and m1(ant30, "Time") < 60000,
      fmt("KT %.0f .. %.0f, Ant %.0f .. %.0f", m1(kt0, "Time"), m1(kt40, "Time"), m1(ant5, "Time"), m1(ant30, "Time")))
local n25 = his("KTRobot", "N25")
check("Exp. 2 ran at 20% obstacles, not the book's 30%",
      math.abs(m1(n25, "Behind") - m1(kt20, "Behind")) < 1 and math.abs(m1(n25, "Behind") - m1(kt30, "Behind")) > 4,
      fmt("N 25 shadow %.1f; 25 robots at 20%%: %.1f, at 30%%: %.1f", m1(n25, "Behind"), m1(kt20, "Behind"), m1(kt30, "Behind")))
local ours = readRuns("ch07/kerr2005_runs.txt")
local groups, worst, nset = {}, 0, 0
for _, r in ipairs(ours) do
  local set = (r.Pct == 20 and r.N ~= 25) and ("N" .. r.N) or tostring(r.Pct)
  local k = r.ctl .. "_" .. set
  groups[k] = groups[k] or {}
  table.insert(groups[k], r)
end
local worstName = ""
for k, g in pairs(groups) do
  local h = readRuns(L .. k .. ".txt")
  nset = nset + 1
  for _, key in ipairs({ "Total", "Behind" }) do
    local ma, sa, na = mean(h, key)
    local mb, sb, nb = mean(g, key)
    local se = math.sqrt(sa * sa / na + sb * sb / nb)
    local z = se > 0 and math.abs(mb - ma) / se or 0
    if z > worst then worst, worstName = z, k .. " " .. key end
  end
end
check("his Java rerun agrees with his logs (all settings, < 3 SE)", worst < 3 and nset == 25,
      fmt("%d settings, %d runs; worst %.1f SE (%s)", nset, #ours, worst, worstName))

print(fmt("ch07: %d checks, %d failed, %.0f s", count, fails, os.clock() - t0))
print(fails == 0 and "PASS ch07: " .. count .. " tests" or "FAIL ch07")
