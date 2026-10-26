--
-- checks/ch11.lua -- Ch. 11's Table 11.1 (book/ch11.md, Sec. 11.8): Maxim's
-- coverage simulator (ch11/maxim/src/coverage_simulation.c) and its Lua
-- copy, ch11/maxim.lua
--
-- 1. The Lua copy reproduces the C exactly: the visit counts of five short
--    runs of the C (2 x 10^5 steps each, ch11/c_reference.txt) to the last
--    visit.
-- 2. The C falls back to fixed seeds: RandomInitialise(1, time(NULL)) gets
--    a kl above 30081 and uses (1802, 9373), so every run draws the same
--    numbers.
-- 3. Table 11.1 comes from Maxim's own output files: the KL of the counts
--    he saved (ch11/maxim_counts.txt) gives every entry of the table, at
--    10^7 steps, except 6x6, 82cell and 84cell, which come from 4 x 10^7,
--    and 10x10 size 20, a misprint (0.00009 for his 0.00053).
-- 4. Our 40-million-step runs of the C (ch11/runs_counts.txt) are Maxim's
--    2009 runs (6x6, 82cell, 84cell), visit for visit at 10-40 million.
--
-- DEFINITIONS (printed values):
--   KL   sum over the C cells of p_i ln(p_i C), p_i the share of the time
--        steps spent in cell i (Sec. 11.2.3); 0 is uniform
--   size the cell size in the environment's files (10-30); the robot
--        moves 1 a step and turns after floor(0.6 x size) steps
--
-- Run from the ArtificialPhysics folder (about 30 s):
--   lua5.1 checks/ch11.lua
--

local here = (arg and arg[0] and arg[0]:match("^(.*)[/\\]checks[/\\][^/\\]*$"))
if here then package.path = here .. "/?.lua;" .. package.path
else package.path = "./?.lua;../?.lua;" .. package.path; here = "." end
local X = require "ch11.maxim"

local fails, count = 0, 0
local function check(name, ok, detail)
  count = count + 1
  if not ok then fails = fails + 1 end
  print(string.format("%s %-58s %s", ok and "ok  " or "FAIL", name, detail or ""))
end
local t0 = os.clock()
print("ch11: " .. _VERSION)

-- "label size t c1 .. cn" lines
local function readCounts(path)
  local out = {}
  for line in io.lines(path) do
    local w = {}
    for v in line:gmatch("%S+") do w[#w + 1] = v end
    local c = {}
    for i = 4, #w do c[#c + 1] = tonumber(w[i]) end
    out[#out + 1] = { label = w[1], size = tonumber(w[2]), t = tonumber(w[3]), counts = c }
  end
  return out
end

-- 1. the Lua copy against the C
for _, r in ipairs(readCounts(here .. "/ch11/c_reference.txt")) do
  local env = X.readEnvironment(string.format("%s/ch11/maxim/%s.environment/environment_%d.ini", here, r.label, r.size))
  local m = X.new({ env = env, f = 0.6 })
  X.run(m, r.t)
  local same = #m.counts == #r.counts
  for i = 1, #r.counts do same = same and m.counts[i] == r.counts[i] end
  check(string.format("the Lua copy is the C: %s, size %d, %d steps", r.label, r.size, r.t), same,
    string.format("KL %.5f (C %.5f)", X.kl(m.counts), X.kl(r.counts)))
end

-- 2. the fallback seeds
local a, b = X.newRandom(1, 1761400000), X.newRandom(1802, 9373)
local same = true
for _ = 1, 1000 do same = same and a() == b() end
check("RandomInitialise(1, time()) is RandomInitialise(1802, 9373)", same, "1000 draws")

-- 3. Table 11.1 from Maxim's files
local BOOK = {   -- Table 11.1, sizes 10, 15, 20, 25, 30; the directory of Maxim's files
  { "3x1", "3x1.results", { 0.00011, 0.00005, 0.00003, 0.00003, 0.00002 } },
  { "4cellL", "4cell.L.results", { 0.00026, 0.00022, 0.00019, 0.00016, 0.00022 } },
  { "4cellRoll", "4cell.roll.results", { 0.00090, 0.00082, 0.00068, 0.00066, 0.00071 } },
  { "7cell", "7cell.dumbell.results", { 0.00078, 0.00075, 0.00064, 0.00056, 0.00061 } },
  { "3x3", "3x3.results", { 0.00018, 0.00010, 0.00007, 0.00007, 0.00006 } },
  { "15cell", "15cell.results", { 0.00019, 0.00010, 0.00015, 0.00016, 0.00019 } },
  { "22cell", "22cell.results", { 0.00088, 0.00124, 0.00188, 0.00137, 0.00145 } },
  { "35cell", "35cell.results", { 0.00138, 0.00079, 0.00067, 0.00067, 0.00106 } },
  { "6x6", "6x6.newresults", { 0.00021, 0.00011, 0.00009, 0.00008, 0.00009 }, 4e7 },
  { "82cell", "spiral82.new.results", { 0.00223, 0.00114, 0.00269, 0.00097, 0.00059 }, 4e7 },
  { "84cell", "84cell.newresults", { 0.00210, 0.00309, 0.00067, 0.00156, 0.00064 }, 4e7 },
  { "10x10", "10x10.results", { 0.00051, 0.00057, 0.00009, 0.00057, 0.00065 } },
}
local files = readCounts(here .. "/ch11/maxim_counts.txt")
for _, e in ipairs(BOOK) do
  local T = e[4] or 1e7
  local bad, got = {}, {}
  for i, size in ipairs({ 10, 15, 20, 25, 30 }) do
    local k
    for _, f in ipairs(files) do
      if f.label:match("^[^:]+") == e[2] and f.size == size and f.t == T then k = X.kl(f.counts); break end
    end
    got[i] = k and string.format("%.5f", k) or "none"
    -- the book rounds to 5 places, a few entries are cut instead (0.0006773 is 0.00067)
    local b = e[3][i] * 1e5
    if not k or (math.floor(k * 1e5 + 0.5) ~= math.floor(b + 0.5) and math.floor(k * 1e5) ~= math.floor(b + 0.5)) then bad[#bad + 1] = string.format("size %d: book %.5f", size, e[3][i]) end
  end
  if e[1] == "10x10" then
    check("Table 11.1 from Maxim's files: 10x10 (size 20 is a misprint)", #bad == 1 and bad[1]:match("^size 20"),
      table.concat(got, " ") .. " at " .. T .. " steps; " .. table.concat(bad, ", "))
  else
    check("Table 11.1 from Maxim's files: " .. e[1], #bad == 0,
      table.concat(got, " ") .. " at " .. T .. " steps" .. (#bad > 0 and "; " .. table.concat(bad, ", ") or ""))
  end
end

-- 4. our runs of the C (ch11/runs_counts.txt) are Maxim's 2009 runs, visit for visit
local ours = readCounts(here .. "/ch11/runs_counts.txt")
local DIRS = { ["6x6"] = "6x6.newresults", spiral82 = "spiral82.new.results", ["84cell"] = "84cell.newresults" }
local n, bad = 0, 0
for _, f in ipairs(files) do
  local env = f.label:match("^([^.]+)")
  if DIRS[env] and f.label:match("^[^:]+") == DIRS[env] then
    for _, o in ipairs(ours) do
      if o.label == env and o.size == f.size and o.t == f.t then
        n = n + 1
        for i = 1, #f.counts do if o.counts[i] ~= f.counts[i] then bad = bad + 1; break end end
      end
    end
  end
end
check("our runs of the C are Maxim's 2009 runs (6x6, 82cell, 84cell)", n == 60 and bad == 0,
  string.format("%d samples (10-40M steps) compared, %d differ", n, bad))

print(string.format("ch11: %d checks, %d failed, %.0f s", count, fails, os.clock() - t0))
print(fails == 0 and "PASS ch11: " .. count .. " tests" or "FAIL ch11")
