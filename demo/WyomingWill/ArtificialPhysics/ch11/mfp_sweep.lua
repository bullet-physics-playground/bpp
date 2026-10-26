--
-- ch11/mfp_sweep.lua -- Maxim's environments over the mean free path
--
--   lua5.4 ch11/mfp_sweep.lua [kl|dev] [STEPS]     (from ArtificialPhysics/)
--
-- Ch. 4.3's question (PDF 144-146) on Ch. 11's simulator: the theory's
-- 0.65 x cell size is an UPPER BOUND on the mean free path; below it one
-- robot should, given time, cover as evenly as a swarm, above it coverage
-- gets much worse and stays so. One run per environment and turn length K
-- (seed 1: the time average stands for the ensemble, Sec. 11.2.6), cell
-- size 20, Maxim's C with FINDINGS F81's fix and a seed argument
-- (ch11/maxim_fixed.diff), run 1.6 x 10^8 steps (the 3x3 to 3.2 x 10^8,
-- every K from 1 to 80).
--
-- Prints one row per environment, one column per K (f = K / 20 below it),
-- the KL (default) or the deviation at STEPS (default the run's last
-- checkpoint), and the row's floor: the smallest value at f <= 0.5.
--
-- DEFINITIONS:
--   K     the robot turns to a new uniform heading after K steps without a
--         wall (the C's (int)(cell size x f), run with f = (K + 0.5) / 20)
--   f     K / cell size, the mean free path in cell widths; the theory's
--         bound is 0.65 (0.6079 with the wall buffer, Sec. 11.3)
--   KL    sum over the C cells of p_i ln(p_i C) (Sec. 11.2.3); the book's
--         target for simulation is 0.001
--   dev   sqrt(sum (p_i - 1/C)^2), Eq. 4.1, Ch. 4's measure
-- FILE: ch11/mfp_sweep_counts.txt, "env size K t c1 .. cn", the counts at
-- 10^7, 4 x 10^7, 8 x 10^7, 1.6 x 10^8 (and 3.2 x 10^8) steps.
--
package.path = "./?.lua;" .. package.path
local X = require "ch11.maxim"
local what = (arg and arg[1]) or "kl"
local at = tonumber(arg and arg[2] or "")

local function dev(c)
  local tot, n, s = 0, #c, 0
  for i = 1, n do tot = tot + c[i] end
  for i = 1, n do local d = c[i] / tot - 1 / n; s = s + d * d end
  return math.sqrt(s)
end

local ENVS = { "3x1", "4cell.L", "4cell.roll", "7cell.dumbbell", "3x3", "15cell", "22cell", "35cell", "6x6", "10x10",
  "spiral82", "84cell" }
local data, Ks = {}, {}
for line in io.lines("ch11/mfp_sweep_counts.txt") do
  local w = {}
  for v in line:gmatch("%S+") do w[#w + 1] = v end
  local env, K, t = w[1], tonumber(w[3]), tonumber(w[4])
  if not at or t == at then
    local c = {}
    for i = 5, #w do c[#c + 1] = tonumber(w[i]) end
    data[env] = data[env] or {}
    local r = data[env][K]
    if not r or t > r.t then data[env][K] = { t = t, v = what == "dev" and dev(c) or X.kl(c) } end
  end
end
local GRID = { 1, 2, 3, 4, 6, 8, 10, 12, 13, 14, 16, 18, 19, 20, 22, 24, 26, 30, 36, 40, 48, 60, 80 }
local head = { "| env" }
for _, K in ipairs(GRID) do head[#head + 1] = string.format("%.2f", K / 20) end
head[#head + 1] = "floor (f <= 0.5) |"
print(table.concat(head, " | "))
print("|" .. string.rep(" --- |", #GRID + 2))
for _, e in ipairs(ENVS) do
  if data[e] then
    local row, floor = { "| " .. e }, math.huge
    for _, K in ipairs(GRID) do
      local r = data[e][K]
      row[#row + 1] = r and string.format(what == "dev" and "%.4f" or "%.5f", r.v) or ""
      if r and K <= 10 then floor = math.min(floor, r.v) end
    end
    row[#row + 1] = string.format(what == "dev" and "%.4f |" or "%.5f |", floor)
    print(table.concat(row, " | "))
  end
end
