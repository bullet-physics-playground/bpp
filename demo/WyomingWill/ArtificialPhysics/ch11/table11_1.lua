--
-- ch11/table11_1.lua -- Table 11.1 (Sec. 11.8) from the saved visit counts
--
--   lua5.4 ch11/table11_1.lua [TOL]               (from ArtificialPhysics/)
--
-- Prints, for each of the 12 environments and 5 cell sizes: the book's
-- KL, the KL of Maxim's own file at the length the book used, and ours:
-- Maxim's C (ch11/maxim/src/coverage_simulation.c, built as it is) run for
-- 40 million steps, then 160 million where 40 had not settled, with the
-- KL at 10, 20, 40, 80 and 160 million steps.
--
-- STOPPING RULE: an entry has settled at T (40, 80 or 160 million) when
-- |KL(T) - KL(T/2)| <= TOL x KL(T), TOL 0.05 unless given; the table's
-- value is KL at the first such T, or at the longest run, marked *, if
-- none. Where the robot got stuck on a wall (FINDINGS F81; ch11/wedge.lua)
-- the run ends at the last sample before it, marked w.
--
-- DEFINITIONS:
--   KL    sum over the C cells of p_i ln(p_i C), p_i the share of the
--         steps spent in cell i (Sec. 11.2.3); 0 is uniform
--   size  the cell size of the environment's file; the robot moves 1 a
--         step and turns after floor(0.6 x size) steps
-- FILES: ch11/maxim_counts.txt (Maxim's files), ch11/runs_counts.txt
-- (ours), both "label size t c1 .. cn", one line a sample kept.
--
package.path = "./?.lua;" .. package.path
local X = require "ch11.maxim"
local TOL = tonumber(arg and arg[1] or "") or 0.05

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

-- Table 11.1's name, the environment's directory, Maxim's results directory,
-- the length the book's entry used, and the book's values for sizes 10-30
local ENVS = {
  { "3x1", "3x1", "3x1.results", 1e7, { 0.00011, 0.00005, 0.00003, 0.00003, 0.00002 } },
  { "4cellL", "4cell.L", "4cell.L.results", 1e7, { 0.00026, 0.00022, 0.00019, 0.00016, 0.00022 } },
  { "4cellRoll", "4cell.roll", "4cell.roll.results", 1e7, { 0.00090, 0.00082, 0.00068, 0.00066, 0.00071 } },
  { "7cell", "7cell.dumbbell", "7cell.dumbell.results", 1e7, { 0.00078, 0.00075, 0.00064, 0.00056, 0.00061 } },
  { "3x3", "3x3", "3x3.results", 1e7, { 0.00018, 0.00010, 0.00007, 0.00007, 0.00006 } },
  { "15cell", "15cell", "15cell.results", 1e7, { 0.00019, 0.00010, 0.00015, 0.00016, 0.00019 } },
  { "22cell", "22cell", "22cell.results", 1e7, { 0.00088, 0.00124, 0.00188, 0.00137, 0.00145 } },
  { "35cell", "35cell", "35cell.results", 1e7, { 0.00138, 0.00079, 0.00067, 0.00067, 0.00106 } },
  { "6x6", "6x6", "6x6.newresults", 4e7, { 0.00021, 0.00011, 0.00009, 0.00008, 0.00009 } },
  { "82cell", "spiral82", "spiral82.new.results", 4e7, { 0.00223, 0.00114, 0.00269, 0.00097, 0.00059 } },
  { "84cell", "84cell", "84cell.newresults", 4e7, { 0.00210, 0.00309, 0.00067, 0.00156, 0.00064 } },
  { "10x10", "10x10", "10x10.results", 1e7, { 0.00051, 0.00057, 0.00009, 0.00057, 0.00065 } },
}
local SIZES = { 10, 15, 20, 25, 30 }
local WEDGED = { ["4cell.roll 10"] = true, ["4cell.L 10"] = true, ["15cell 20"] = true, ["22cell 15"] = true,
  ["35cell 10"] = true, ["spiral82 15"] = true }

local maxim, ours = readCounts("ch11/maxim_counts.txt"), readCounts("ch11/runs_counts.txt")
local function find(list, label, size, t)
  for _, f in ipairs(list) do
    if f.label:match("^[^:]+") == label and f.size == size and (not t or f.t == t) then return f end
  end
end

print(string.format("| Environment | Size | Book | Maxim's file | Ours at 10M | 20M | 40M | 80M | 160M | Ours (run length) |"))
print("| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |")
for _, e in ipairs(ENVS) do
  for i, s in ipairs(SIZES) do
    local m = find(maxim, e[3], s, e[4])
    local k, last = {}, 0
    for _, f in ipairs(ours) do
      if f.label == e[2] and f.size == s then k[f.t] = X.kl(f.counts); if f.t > last then last = f.t end end
    end
    local value, mark, at
    for _, T in ipairs({ 4e7, 8e7, 16e7 }) do
      if k[T] and k[T / 2] and math.abs(k[T] - k[T / 2]) <= TOL * k[T] then value, at = k[T], T; break end
    end
    if not value then value, at, mark = k[last], last, WEDGED[e[2] .. " " .. s] and "w" or "*" end
    local cols = {}
    for _, T in ipairs({ 1e7, 2e7, 4e7, 8e7, 16e7 }) do cols[#cols + 1] = k[T] and string.format("%.5f", k[T]) or "" end
    local len = at >= 1e7 and string.format("%gM", math.floor(at / 1e5) / 10) or string.format("%.2fM", at / 1e6)
    print(string.format("| %s | %d | %.5f | %s | %s | %.5f%s (%s) |", e[1], s, e[5][i],
      m and string.format("%.5f", X.kl(m.counts)) or "", table.concat(cols, " | "), value, mark or "", len))
  end
end
