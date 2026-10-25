--
-- checks/ch04.lua -- Ch. 4.3's uniform coverage (book/ch04.md, PDF
-- 139-147) on ch04/coverage.lua, uniform.nlogo and uniform_mfpl.nlogo's
-- own step
--
-- Table 4.2 (the deviation falls with more agents), Fig. 4.17 (one agent
-- without a mean free path favours the cells with more walls), Fig. 4.19
-- (the deviation against the mean free path: good below ~17, poor above
-- ~30, with a dip for one agent near 53-65). Each line says what the book
-- (or William's NetLogo runs, ch04/uniform_data.txt) reports and what we
-- get. The runs here are short (5 x 10^6 agent steps for one agent, 10^7
-- for 100); ch04/README.md has the full sweep, run to 2 x 10^8.
--
-- DEFINITIONS (printed values):
--   deviation  sqrt( sum over the 9 cells of (p_k - 1/9)^2 ), p_k the
--              share of the agent-ticks spent in cell k (Eq. 4.1); 0 is
--              uniform, 0.9428 all in one cell
--   MFP        Mean_Free_Path_Length (steps); "none" is uniform.nlogo
--   corner, edge, centre   the mean share of the 4 corner cells, the 4
--              edge cells and the centre cell
--
-- Run from the ArtificialPhysics folder (about 40 s):
--   lua5.1 checks/ch04.lua
--

local here = (arg and arg[0] and arg[0]:match("^(.*)[/\\]checks[/\\][^/\\]*$"))
if here then package.path = here .. "/?.lua;" .. package.path
else package.path = "./?.lua;../?.lua;" .. package.path end
local U = require "ch04.coverage"

local fails, count = 0, 0
local function check(name, ok, detail)
  count = count + 1
  if not ok then fails = fails + 1 end
  print(string.format("%s %-58s %s", ok and "ok  " or "FAIL", name, detail or ""))
end
local t0 = os.clock()
print("ch04: " .. _VERSION)

local m0 = U.new({ n = 1, seed = 1 })
check("Fig. 4.15: the deviation starts at 0.9428 (all in one cell)", math.abs(U.deviation(m0) - 0.9428) < 1e-4,
  string.format("%.4f", U.deviation(m0)))

local function one(mfp)
  local m = U.new({ n = 1, mfp = mfp, seed = 1 })
  U.run(m, 5e6)
  return U.deviation(m), m
end
local dNone, mNone = one(nil)
local p = U.shares(mNone)
local corner, edge, centre = (p[1] + p[3] + p[7] + p[9]) / 4, (p[2] + p[4] + p[6] + p[8]) / 4, p[5]
check("Table 4.2: one agent, no mean free path, 0.027", dNone > 0.024 and dNone < 0.030, string.format("%.4f", dNone))
check("Fig. 4.17: corners, then edges, then the centre", corner > edge and edge > centre,
  string.format("corner %.4f, edge %.4f, centre %.4f (1/9 = 0.1111)", corner, edge, centre))
local d17, d50, d65, d80 = one(17), one(50), one(65), one(80)
check("Fig. 4.19: MFP 17 (the theory's 17 1/3) is good", d17 < 0.006, string.format("%.4f (NetLogo runs: 0.0038)", d17))
check("Fig. 4.19: MFP 50 is poor", d50 > 0.020 and d50 < 0.026, string.format("%.4f (NetLogo runs: 0.023)", d50))
check("Fig. 4.19: one agent's dip near 53-65", d65 < 0.3 * d50 and d65 < 0.3 * d80,
  string.format("MFP 65: %.4f, against %.4f at 50 and %.4f at 80", d65, d50, d80))
local m = U.new({ n = 100, seed = 1 })
U.run(m, 1e5)
local d100 = U.deviation(m)
check("Table 4.2: 100 agents, no mean free path, 0.016", d100 > 0.014 and d100 < 0.019, string.format("%.4f", d100))
check("Table 4.2: more agents, better coverage", d100 < 0.7 * dNone, string.format("%.4f against %.4f", d100, dNone))

print(string.format("ch04: %d checks, %d failed, %.0f s", count, fails, os.clock() - t0))
print(fails == 0 and "PASS ch04: " .. count .. " tests" or "FAIL ch04")
