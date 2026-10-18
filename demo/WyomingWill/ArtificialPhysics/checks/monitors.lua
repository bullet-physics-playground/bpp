--
-- checks/monitors.lua -- the integrator and monitors against closed forms
--
-- Tests lib/monitors.lua on two-body problems whose answers are known,
-- with the Ch. 2 default settings where the book gives them
-- (book/ch02.md). The Ch. 2 scenes themselves, and the book's own
-- results, come in ch02/; this checks the machinery they stand on.
--
-- DEFINITIONS (printed values): |P| total linear momentum; L, Ly angular
-- momentum about the centre of mass (lib/monitors.lua); relE relative
-- energy change (E - E0)/|E0|; "relative drift" of L is |L - L0| / |L0|;
-- periods are measured between upward crossings of the rest length (springs)
-- or full turns of the planet about the sun (Kepler); mu = m1 m2/(m1 + m2)
-- is the reduced mass, a = -G m1 m2 / (2E) the orbit's semi-major axis.
--
-- Run from the ArtificialPhysics folder (a few seconds):
--   lua5.1 checks/monitors.lua
-- or inside BPP: bpp -f checks/monitors.lua -n 1
--

local here = (arg and arg[0] and arg[0]:match("^(.*)[/\\]checks[/\\][^/\\]*$"))
if here then package.path = here .. "/?.lua;" .. package.path
else package.path = "./?.lua;../?.lua;" .. package.path end
local mon = require "lib.monitors"

local pi, sqrt, abs = math.pi, math.sqrt, math.abs
local atan2 = math.atan2 or function(y, x) return math.atan(y, x) end -- Lua 5.3+ dropped atan2
local fails, count = 0, 0
local function check(name, ok, detail)
  count = count + 1
  if not ok then fails = fails + 1 end
  print(string.format("%s %-48s %s", ok and "ok  " or "FAIL", name, detail or ""))
end

-- Times at which the separation crosses D upward (linear interpolation).
local function upCrossings(ps, dt, steps, opts, D)
  local times, prev = {}, mon.dist(ps[1], ps[2]) - D
  for s = 1, steps do
    mon.step(ps, dt, opts)
    local cur = mon.dist(ps[1], ps[2]) - D
    if prev < 0 and cur >= 0 then times[#times + 1] = (s - 1 + prev / (prev - cur)) * dt end
    prev = cur
  end
  return times
end
local function meanPeriod(times)
  if #times < 2 then return nil end
  return (times[#times] - times[1]) / (#times - 1)
end

-- Spring between two masses: f = k (r - D) attracts when stretched.
local function spring(k, D)
  return {
    pair = function(r) return -k * (r - D) end,          -- > 0 repels
    potential = function(r) return 0.5 * k * (r - D) ^ 2 end,
  }
end

print("monitors: " .. _VERSION)

-- 1. spring1D, book defaults: k 10, D 50, dt 0.001, masses 1 and 1.
do
  local k, D, dt = 10, 50, 0.001
  local opts = spring(k, D)
  local ps = { { x = -30, m = 1 }, { x = 30, m = 1 } }       -- stretched by 10
  local t = mon.tracker(ps, opts)
  local mu = 1 * 1 / (1 + 1)
  local T = 2 * pi * sqrt(mu / k)
  local P = meanPeriod(upCrossings(ps, dt, 20000, opts, D))
  local d = t:drift()
  check("spring1D: momentum stays 0", d.now.p <= 1e-12, string.format("|P| = %.2g", d.now.p))
  check("spring1D: centre of mass stays put", d.com <= 1e-9, string.format("drift %.2g", d.com))
  check("spring1D: period 2 pi sqrt(mu/k)", P and abs(P - T) / T < 1e-3,
        string.format("%.5f vs %.5f", P or 0, T))
  check("spring1D: energy flat at dt 0.001", abs(d.relE) < 2e-3, string.format("relE %.2g", d.relE))
end

-- 2. Mass ratio 10: the heavy mass barely moves; period uses the reduced mass.
do
  local k, D, dt = 10, 50, 0.001
  local opts = spring(k, D)
  local ps = { { x = -30, m = 1 }, { x = 30, m = 10 } }
  local first = mon.measure(ps)
  local mu = 10 / 11
  local T = 2 * pi * sqrt(mu / k)
  local P = meanPeriod(upCrossings(ps, dt, 30000, opts, D))
  local m = mon.measure(ps)
  check("mass ratio 10: period with the reduced mass", P and abs(P - T) / T < 1e-3,
        string.format("%.5f vs %.5f", P or 0, T))
  check("mass ratio 10: COM stays put", abs(m.cx - first.cx) < 1e-9,
        string.format("COM %.6f (heavy mass at %.2f)", m.cx, ps[2].x))
end

-- 3. Energy error shrinks with dt (symplectic Euler: first order).
do
  local function maxErr(dt)
    local opts = spring(10, 50)
    local ps = { { x = -30 }, { x = 30 } }
    local t, worst = mon.tracker(ps, opts), 0
    for _ = 1, math.floor(10 / dt) do
      mon.step(ps, dt, opts)
      worst = math.max(worst, abs(t:drift().relE))
    end
    return worst
  end
  local e1, e2 = maxErr(0.01), maxErr(0.001)
  check("energy error falls about 10x per 10x smaller dt", e1 / e2 > 7 and e1 / e2 < 13,
        string.format("%.3g (dt 0.01) / %.3g (dt 0.001) = %.1f", e1, e2, e1 / e2))
end

-- 4. Friction: v <- (1 - FR) v per step; energy decays like exp(-2 gamma t).
do
  local fr, dt = 0.001, 0.001
  local opts = spring(10, 50)
  opts.friction = fr
  local ps = { { x = -30 }, { x = 30 } }
  local t = mon.tracker(ps, opts)
  local steps = 3000
  for _ = 1, steps do mon.step(ps, dt, opts) end
  local ratio = t:drift().now.e / t.first.e
  local gamma = mon.frictionRate(fr, dt)
  -- energy swaps between KE (damped) and PE (not), so on average it decays
  -- at half the rate of a purely kinetic system: exp(-gamma t)
  local expectAvg = math.exp(-gamma * steps * dt)
  check("friction drains energy at the expected rate",
        ratio < 1 and abs(math.log(ratio) / math.log(expectAvg) - 1) < 0.1,
        string.format("E/E0 %.4f, exp(-gamma t) %.4f (gamma %.4f/s)", ratio, expectAvg, gamma))
  check("friction keeps momentum 0", t:drift().now.p < 1e-12)
end

-- 5. spring2D, book defaults: Angular_Motion 200, Mass_Ratio 10, k 10,
--    D 50, dt 0.001; masses apart along z, moving along x (the x-z plane).
do
  local opts = spring(10, 50)
  local ps = { { z = -25, vx = 200, m = 1 }, { z = 25, vx = -200 / 10, m = 10 } }
  local t = mon.tracker(ps, opts)
  local sum, n, maxSep = 0, 0, 0
  for _ = 1, 20000 do
    mon.step(ps, 0.001, opts)
    local r = mon.dist(ps[1], ps[2])
    sum, n, maxSep = sum + r, n + 1, math.max(maxSep, r)
  end
  local d = t:drift()
  check("spring2D: linear momentum stays 0", d.now.p < 1e-9, string.format("|P| = %.2g", d.now.p))
  check("spring2D: angular momentum conserved", d.dl / t.first.l < 1e-10,
        string.format("L %.6g, relative drift %.2g", t.first.l, d.dl / t.first.l))
  check("spring2D: L only about the plane's normal", abs(d.now.lx) + abs(d.now.lz) < 1e-9,
        string.format("Ly %.6g", d.now.ly))
  check("spring2D: centrifugal stretch, mean separation > D", sum / n > 50,
        string.format("mean %.1f, max %.1f", sum / n, maxSep))
end

-- 6. Kepler: sun 100 at the origin, planet 1 at (15, 0), G 20, AM 15
--    (the solar_system defaults), dt 0.001. The two-body orbit is a closed
--    ellipse with a = -G m1 m2 / (2E) and T = 2 pi sqrt(a^3 / (G (m1 + m2))).
do
  local G, Ms, AM, dt = 20, 100, 15, 0.001
  local opts = {
    pair = function(r, a, b) return -G * a.m * b.m / (r * r) end,
    potential = function(r, a, b) return -G * a.m * b.m / r end,
  }
  local ps = { { x = 0, vz = -AM / Ms, m = Ms }, { x = 15, vz = AM, m = 1 } }
  local t = mon.tracker(ps, opts)
  local E = t.first.e
  local a = -G * Ms * 1 / (2 * E)
  local T = 2 * pi * sqrt(a ^ 3 / (G * (Ms + 1)))
  -- period from the planet's angle about the sun
  local angle, turns, prev = 0, {}, 0
  local steps = math.floor(3.2 * T / dt)
  for s = 1, steps do
    mon.step(ps, dt, opts)
    local ang = atan2(ps[2].z - ps[1].z, ps[2].x - ps[1].x)
    local da = ang - prev
    if da > pi then da = da - 2 * pi elseif da < -pi then da = da + 2 * pi end
    angle, prev = angle + da, ang
    if abs(angle) >= 2 * pi * (#turns + 1) then turns[#turns + 1] = s * dt end
  end
  local d = t:drift()
  local P = #turns >= 2 and (turns[#turns] - turns[1]) / (#turns - 1) or nil
  check("Kepler: bound orbit, energy < 0", E < 0, string.format("E %.4g, a %.3f", E, a))
  check("Kepler: period matches the closed form", P and abs(P - T) / T < 1e-3,
        string.format("%.4f vs %.4f", P or 0, T))
  check("Kepler: energy conserved", abs(d.relE) < 1e-3, string.format("relE %.2g", d.relE))
  check("Kepler: angular momentum conserved", d.dl / t.first.l < 1e-9,
        string.format("relative drift %.2g", d.dl / t.first.l))
  check("Kepler: momentum 0, COM still", d.now.p < 1e-9 and d.com < 1e-6,
        string.format("|P| %.2g, COM drift %.2g", d.now.p, d.com))
end

-- 7. An external force moves the centre of mass at F/M, whatever the
--    internal forces do.
do
  local opts = spring(10, 50)
  opts.external = function(p) return 2, 0, 0 end      -- 2 on each of 2 masses of 1 and 3
  local ps = { { x = -30, m = 1 }, { x = 30, m = 3 } }
  local first = mon.measure(ps)
  local dt, steps = 0.001, 5000
  for _ = 1, steps do mon.step(ps, dt, opts) end
  local m = mon.measure(ps)
  local tt = steps * dt
  local expect = 4 / 4 * tt            -- total force 4, total mass 4
  check("external force: COM velocity F t / M", abs(m.vcx - expect) < 1e-9,
        string.format("%.6f vs %.6f", m.vcx, expect))
  check("external force: COM moves F t^2 / 2M", abs((m.cx - first.cx) - 0.5 * tt * tt) / (0.5 * tt * tt) < 1e-3,
        string.format("%.4f vs %.4f", m.cx - first.cx, 0.5 * tt * tt))
end

-- 8. A law that breaks Newton's third law shows up in the momentum monitor.
do
  local opts = {
    asymmetric = true,
    pair = function(r, a, b) return a.id == 1 and -1 or 0 end,  -- only particle 1 is pulled
  }
  local ps = { { id = 1, x = -30 }, { id = 2, x = 30 } }
  local t = mon.tracker(ps, opts)
  for _ = 1, 1000 do mon.step(ps, 0.001, opts) end
  check("asymmetric law: momentum drift detected", t:drift().dp > 0.9,
        string.format("dp %.3f (expected about 1)", t:drift().dp))
end

-- 9. The caps hold.
do
  local opts = spring(10, 50)
  opts.forceMax, opts.speedMax = 5, 3
  local ps = { { x = -300 }, { x = 300 } }
  local maxF, maxV = 0, 0
  for _ = 1, 2000 do
    mon.step(ps, 0.01, opts)
    for _, p in ipairs(ps) do
      maxF = math.max(maxF, sqrt(p.fx ^ 2 + p.fy ^ 2 + p.fz ^ 2))
      maxV = math.max(maxV, sqrt(p.vx ^ 2 + p.vy ^ 2 + p.vz ^ 2))
    end
  end
  check("force cap and speed cap hold", maxF <= 5 + 1e-12 and maxV <= 3 + 1e-12,
        string.format("max |F| %.4f, max speed %.4f", maxF, maxV))
end

if fails == 0 then
  print(string.format("PASS monitors: %d tests", count))
else
  print(string.format("FAIL monitors: %d of %d tests failed", fails, count))
end
if not rawget(_G, "v") then os.exit(fails == 0 and 0 or 1) end
