--
-- checks/ch04_couette.lua -- Ch. 4.4's Couette flow (book/ch04.md, PDF
-- 147-156) on ch04/couette.lua, kt.nlogo's own step
--
-- 1. The Lua is ch04/couette1.c (the C used for the long runs) to the last
--    bit: two short runs against ch04/couette1_reference.txt.
-- 2. Fig. 4.23: walls moving at +-V make a linear profile, slope near
--    V/6, correlation near 1; the momenta stay near 0.
-- 3. FINDINGS F85: the .nlogo's wall emits hotter than the Rayleigh it
--    draws (a particle still in the wall zone is drawn again every tick),
--    so its slope sits ~2% above V/6; thermalising only particles moving
--    into the wall (o.inward) emits the Rayleigh and gives V/6, as the
--    book's Fig. 4.23 does.
-- The runs here are short (4,000 ticks, Resample at 2,000; steady by
-- then to ~0.5%); ch04/README.md has the full Figs. 4.23 and 4.24 from
-- ch04/couette1.c at the book's lengths.
--
-- DEFINITIONS (printed values):
--   slope, corr  least-squares slope (units/tick per column) and
--                correlation of the 13 bars (mean vy per column, since
--                Resample) against column 0..12; theory V/6 and 1
--   ratio        slope / (V/6)
--   P            mean vx, mean vy (the model's momentum monitors, m = 1);
--                "near 0" is within 3 standard errors, sqrt(<v^2>/N) each
--   exit         mean |vx| / sqrt(T) of particles leaving a wall zone;
--                the Rayleigh the wall draws has 1.2533
--
-- Run from the ArtificialPhysics folder (about 70 s):
--   lua5.1 checks/ch04_couette.lua
--

local here = (arg and arg[0] and arg[0]:match("^(.*)[/\\]checks[/\\][^/\\]*$"))
if here then package.path = here .. "/?.lua;" .. package.path
else package.path = "./?.lua;../?.lua;" .. package.path; here = "." end
local C = require "ch04.couette"

local fails, count = 0, 0
local function check(name, ok, detail)
  count = count + 1
  if not ok then fails = fails + 1 end
  print(string.format("%s %-58s %s", ok and "ok  " or "FAIL", name, detail or ""))
end
local t0 = os.clock()
print("ch04_couette: " .. _VERSION)

-- 1. the reference runs of the C
local ref, cur = {}, nil
local f = io.open(here .. "/ch04/couette1_reference.txt") or io.open("ch04/couette1_reference.txt")
for line in f:lines() do
  local w = line:match("^# %./couette1 .* (%d)$")
  if w then cur = {}; ref[tonumber(w)] = cur
  elseif cur and not line:match("^#") then
    local key, rest = line:match("^(%a+) (.*)$")
    cur[key] = rest
  end
end
f:close()
local function g(x) return string.format("%.17g", x) end
for w = 0, 1 do
  local m = C.new({ V = 1, T = 0.01, seed = 7, split = true, inward = w == 1 })
  C.run(m, 150); C.resample(m); C.run(m, 150)
  local sl, r = C.stats(m)
  local sp = C.meanSpeed(m)
  local ws, is, sh = C.splitSpeeds(m)
  local e1, e2, en = C.exitStats(m)
  local px, py = C.momentum(m)
  local p, bars = C.profile(m), {}
  for k = 0, 12 do bars[#bars + 1] = g(p[k]) end
  local mine = {
    slope = g(sl) .. " corr " .. g(r),
    speed = g(sp) .. " ratio " .. g(sp / math.sqrt(m.T)),
    wall = g(ws) .. " in " .. g(is) .. " share " .. g(sh),
    exit = g(e1) .. " " .. g(e2) .. " n " .. en,
    px = g(px) .. " py " .. g(py),
    bars = table.concat(bars, " "),
  }
  local same = true
  for _, k in ipairs({ "slope", "speed", "wall", "exit", "px", "bars" }) do
    if mine[k] ~= ref[w][k] then same = false; print("     " .. k .. ": " .. mine[k] .. " / C " .. tostring(ref[w][k])) end
  end
  check("the Lua is couette1.c to the last bit (" .. (w == 1 and "inward" or ".nlogo") .. ")", same,
    "300 ticks, slope " .. string.format("%.6f", sl))
end

-- 2 and 3. Fig. 4.23 at V = 1
local function fig423(inward)
  local m = C.new({ V = 1, T = 0.01, seed = 1, inward = inward })
  C.run(m, 2000); C.resample(m); C.run(m, 2000)
  return m
end
local m = fig423(false)
local sl, r = C.stats(m)
local p = C.profile(m)
local mono = true
for k = 1, 12 do if p[k] <= p[k - 1] then mono = false end end
check("Fig. 4.23: the bars rise from the yellow wall to the red", mono and p[0] < -0.9 and p[12] > 0.9,
  string.format("%.3f ... %.3f ... %.3f", p[0], p[6], p[12]))
check("Fig. 4.23: linear, correlation > 0.995 (book > 0.999)", r > 0.995, string.format("%.5f", r))
check("F85: the .nlogo's slope is ~2% above V/6", sl * 6 > 1.005 and sl * 6 < 1.04,
  string.format("slope %.5f, ratio %.4f (steady, 10 seeds: 1.024)", sl, sl * 6))
local px, py = C.momentum(m)
local sx, sy = 0, 0                       -- a mean of N velocities has standard error sqrt(<v^2>/N)
for i = 1, m.n do sx, sy = sx + m.vx[i] ^ 2, sy + m.vy[i] ^ 2 end
sx, sy = math.sqrt(sx / m.n / m.n), math.sqrt(sy / m.n / m.n)
check("Fig. 4.22: the momenta stay near 0 (within 3 standard errors)", math.abs(px) < 3 * sx and math.abs(py) < 3 * sy,
  string.format("P = (%.4f, %.4f), standard errors (%.4f, %.4f)", px, py, sx, sy))
local mi = fig423(true)
local sli, ri = C.stats(mi)
check("F85: walls thermalising inward only give V/6 (Fig. 4.23)", math.abs(sli * 6 - 1) < 0.015 and ri > 0.995,
  string.format("slope %.5f, ratio %.4f, corr %.5f", sli, sli * 6, ri))

-- 3. the wall's emission, walls at rest
local function emission(inward)
  local w = C.new({ V = 0, T = 0.04, seed = 1, split = true, inward = inward })
  C.run(w, 2000)
  return C.exitStats(w)
end
local eN, e2N = emission(false)
check("F85: the .nlogo's wall emits hotter than its Rayleigh", eN > 1.36,
  string.format("exit |vx|/sqrtT %.4f, vx^2/T %.3f (Rayleigh 1.2533, 2)", eN, e2N))
local eI, e2I = emission(true)
check("F85: inward, the emission is close to the Rayleigh", math.abs(eI / 1.2533 - 1) < 0.04,
  string.format("exit |vx|/sqrtT %.4f, vx^2/T %.3f", eI, e2I))

print(string.format("ch04_couette: %d checks, %d failed, %.0f s", count, fails, os.clock() - t0))
print(fails == 0 and "PASS ch04_couette: " .. count .. " tests" or "FAIL ch04_couette")
