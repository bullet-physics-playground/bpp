--
-- ch07/kerr2005_figs.lua -- Figs. 7.11-7.13 from the full sweep on the
-- Lua port (ch07/kerr2005_sweep.sh, ch07/kerr2005_sweep_runs.txt), against
-- Kerr's thesis logs (ch07/kerr2005/log/thesis/, 100 runs per setting).
-- Works on a partial sweep (n says how many runs each mean has). Any Lua
-- 5.1-5.4 or LuaJIT; from the ArtificialPhysics folder:
--   lua5.1 ch07/kerr2005_figs.lua [RUNS_FILE]
--
-- DEFINITIONS (columns): setting "P%" = 25 robots at P% obstacles (Exp. 1),
-- "N n" = n robots at 20% (Exp. 2); for each of time (steps until every
-- robot is done, at most 150,000; Fig. 7.11), total (% of free cells
-- covered; Fig. 7.12) and shadow (% of shadow cells covered; Fig. 7.13):
--   his    the mean of his logs
--   code   our mean with his code (switches off) +- the 95% interval
--          (1.96 standard errors, as the book's figures), and n runs
--   z      (code - his) / the standard error of the difference
--   book   our mean with the book's version (KT: seeds, messages, wallfit;
--          Ant: seeds; Default has no switch) +- the 95% interval
--
local here = (arg and arg[0] and arg[0]:match("^(.*)[/\\]ch07[/\\][^/\\]*$")) or "."
local path = arg[1] or (here .. "/ch07/kerr2005_sweep_runs.txt")
local function read(p)
  local f = io.open(p)
  if not f then return {} end
  local runs, seen = {}, {}
  for line in f:lines() do
    if line:match(" Run ") then
      local r = { ctl = line:match("^(%S+)") }
      for k, v in line:gmatch("(%a+) (%S+)") do r[k] = tonumber(v) or v end
      local key = table.concat({ r.ctl, tostring(r.N), tostring(r.Pct), tostring(r.Course), tostring(r.Run), r.Fix or "" }, " ")
      if not seen[key] then seen[key] = true; runs[#runs + 1] = r end -- a run done twice counts once
    end
  end
  f:close()
  return runs
end
local function set(r) return (r.Pct == 20 and r.N ~= 25) and ("N" .. r.N) or tostring(r.Pct) end
local function stats(runs, key)
  local n, s, s2 = #runs, 0, 0
  if n == 0 then return nil end
  for _, r in ipairs(runs) do s, s2 = s + r[key], s2 + r[key] ^ 2 end
  local m = s / n
  local sd = math.sqrt(math.max(s2 / n - m * m, 0) * n / math.max(n - 1, 1))
  return m, sd / math.sqrt(n), n
end
local ours, groups = read(path), {}
for _, r in ipairs(ours) do
  local k = r.ctl .. "_" .. set(r) .. "_" .. (r.Fix and "book" or "code")
  groups[k] = groups[k] or {}
  table.insert(groups[k], r)
end
print(string.format("%s: %d runs", path, #ours))
local sets = { "0", "10", "20", "30", "40", "N5", "N10", "N15", "N20", "N30" }
local labels = { ["0"] = "0%", ["10"] = "10%", ["20"] = "20%", ["30"] = "30%", ["40"] = "40%",
                 N5 = "N 5", N10 = "N 10", N15 = "N 15", N20 = "N 20", N30 = "N 30" }
for _, fig in ipairs({ { "Time", "Fig. 7.11, sweep time (steps)", "%.0f" },
                       { "Total", "Fig. 7.12, total coverage (%)", "%.1f" },
                       { "Behind", "Fig. 7.13, shadow coverage (%)", "%.1f" } }) do
  local key, title, nf = fig[1], fig[2], fig[3]
  print("\n" .. title)
  print(string.format("%-9s %-6s %10s %22s %6s %18s", "ctl", "set", "his", "code (n)", "z", "book (n)"))
  for _, ctl in ipairs({ "KTRobot", "AntRobot", "Simple2" }) do
    for _, s in ipairs(sets) do
      local h = read(here .. "/ch07/kerr2005/log/thesis/" .. ctl .. "_" .. s .. ".txt")
      local hm, hse = stats(h, key)
      local cm, cse, cn = stats(groups[ctl .. "_" .. s .. "_code"] or {}, key)
      local bm, bse, bn = stats(groups[ctl .. "_" .. s .. "_book"] or {}, key)
      local function pm(m, se, n) return m and string.format(nf .. " +- " .. nf .. " (%d)", m, 1.96 * se, n) or "-" end
      local z = (hm and cm and (hse ^ 2 + cse ^ 2) > 0) and string.format("%.1f", (cm - hm) / math.sqrt(hse ^ 2 + cse ^ 2)) or "-"
      print(string.format("%-9s %-6s %10s %22s %6s %18s", ctl, labels[s], hm and string.format(nf, hm) or "-",
                          pm(cm, cse, cn), z, pm(bm, bse, bn)))
    end
  end
end
