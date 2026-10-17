--
-- checks/world.lua -- the world generator's core and its book presets
--
-- Run from the ArtificialPhysics folder (about half a minute):
--   lua5.1 checks/world.lua
-- or inside BPP: bpp -f checks/world.lua -n 1
--

local here = (arg and arg[0] and arg[0]:match("^(.*)[/\\]checks[/\\][^/\\]*$"))
if here then package.path = here .. "/?.lua;" .. package.path
else package.path = "./?.lua;../?.lua;" .. package.path end
local World = require "lib.world"
local rng = require "lib.rng"

local fails, count = 0, 0
local function check(name, ok, detail)
  count = count + 1
  if not ok then fails = fails + 1 end
  print(string.format("%s %-52s %s", ok and "ok  " or "FAIL", name, detail or ""))
end

print("world: " .. _VERSION .. ", presets: " .. table.concat(World.presets(), ", "))

-- Point tests on each kind of piece.
do
  local w = World.new({ bounds = { -10, -10, 10, 10 } })
  w:disc(0, 0, 2)
  w:rect(5, 5, 4, 2, math.pi / 2)          -- turned upright: 2 wide, 4 tall
  w:tri(-8, -8, -4, -8, -6, -4)
  local ok = w:blocked(0, 1.9) and not w:blocked(0, 2.1)
     and w:blocked(5, 6.9) and not w:blocked(6.5, 5) and w:blocked(5.9, 5)
     and w:blocked(-6, -7) and not w:blocked(-4.2, -4.5)
     and w:blocked(20, 0) and not w:blocked(20, 0, "obstacle")
  check("point tests: disc, turned rectangle, triangle, bounds", ok)
end

-- Ch. 3: the 12 discs of Figs. 3.25-3.26.
do
  local w = World.preset("ch03-obstacles")
  local n, minGap = 0, math.huge
  for i, a in ipairs(w.pieces) do
    n = n + 1
    for j = i + 1, #w.pieces do
      local b = w.pieces[j]
      minGap = math.min(minGap, math.sqrt((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2) - a.r - b.r)
    end
  end
  check("ch03: 12 discs of radius 10", n == 12 and w.pieces[1].r == 10, w:summary())
  check("ch03: narrowly spaced at radius 10 (gaps > 0)", minGap > 0 and minGap < 10,
        string.format("smallest gap %.1f patches", minGap))
  local big = World.preset("ch03-obstacles", { radius = 50 })
  local frac = big:obstacleFraction(300)
  check("ch03: at radius 50 the discs merge into one wall", big:blocked(48, -7) and frac > 0.15,
        string.format("covers %.0f%% of the world", 100 * frac))
  check("ch03: goal and start clear of the field",
        not w:blocked(w.regions.goal.x, w.regions.goal.y, "obstacle")
        and not w:blocked(120, 0, "obstacle"))
end

-- Ch. 4: the nine-cell coverage box.
do
  local w = World.preset("ch04-coverage")
  local g = w.grid
  check("ch04: 3 x 3 cells of 26 2/3 on +-40", g.nx == 3 and g.ny == 3 and math.abs(g.dx - 80 / 3) < 1e-12,
        w:summary())
  -- the same cell for random points as Uniform_Coverage.lua's monitorAgent
  local s, agree = rng.new(3), true
  local B1, B2 = (2 * 40) / 3 - 40, (4 * 40) / 3 - 40
  for _ = 1, 100000 do
    local x, y = (s:random() * 2 - 1) * 40, (s:random() * 2 - 1) * 40
    local cx = x < B1 and 0 or (x <= B2 and 1 or 2)
    local cy = y < B1 and 0 or (y <= B2 and 1 or 2)
    if w:cellOf(x, y) ~= cx + 3 * cy + 1 then agree = false; break end
  end
  check("ch04: cellOf matches Uniform Coverage's cells", agree, "100,000 random points")
  check("ch04: walls just outside +-40", w:blocked(40.5, 0) and not w:blocked(39.9, 0, "wall"))
  local nl = World.preset("ch04-coverage", { netlogo = true })
  check("ch04: NetLogo variant keeps the cells, moves the walls to 42",
        nl.grid.x0 == -40 and nl:blocked(42, 0) and not nl:blocked(41.4, 0, "wall"))
end

-- Ch. 7: the corridor at several obstacle percentages, two seeds each.
do
  local t0 = os.clock()
  local okFrac, okClear, okRepeat, okDiffer, okShadow = true, true, true, true, true
  local lines = {}
  for _, pct in ipairs({ 0, 10, 20, 30, 40 }) do
    local sums = {}
    for seed = 1, 2 do
      local w = World.preset("ch07-corridor", { percent = pct, seed = seed })
      local again = World.preset("ch07-corridor", { percent = pct, seed = seed })
      if w:checksum() ~= again:checksum() then okRepeat = false end
      sums[seed] = w:checksum()
      local measured = w:obstacleFraction(300)
      if math.abs(measured - pct / 100) > 0.01 then okFrac = false end
      for _, x in ipairs({ 100, 300, 500, 700, 900 }) do
        if w:blocked(x, 100, "obstacle") or w:blocked(x, 4900, "obstacle") then okClear = false end
      end
      local _, nShadow = w:shadowCells()
      if pct > 0 and nShadow == 0 then okShadow = false end
      if seed == 1 then
        local n = 0
        for _, p in ipairs(w.pieces) do if p.tag == "obstacle" then n = n + 1 end end
        lines[#lines + 1] = string.format("%d%%: %.1f%% (%d obstacles, %d shadow cells)",
                                          pct, 100 * measured, n, nShadow)
      end
    end
    if pct > 0 and sums[1] == sums[2] then okDiffer = false end
  end
  check("ch07: obstacles cover the asked share (within 1%)", okFrac, table.concat(lines, "; "))
  check("ch07: start and goal strips stay clear", okClear)
  check("ch07: the same seed repeats the world exactly", okRepeat)
  check("ch07: different seeds give different worlds", okDiffer)
  check("ch07: shadow cells found behind obstacles", okShadow)
  check("ch07: 50 x 250 cells of 20 inches", (function()
    local g = World.preset("ch07-corridor", { percent = 0 }).grid
    return g.nx == 50 and g.ny == 250 and g.dx == 20 and g.dy == 20 end)(),
    string.format("all corridors built in %.1f s", os.clock() - t0))
end

-- A world does not touch the shared stream (agents' numbers stay put).
do
  rng.seed(42)
  local a = rng.random()
  rng.seed(42)
  World.preset("ch07-corridor", { percent = 20, seed = 9 })
  check("building a world leaves the shared random stream alone", rng.random() == a)
end

-- The grid file.
do
  local w = World.preset("ch07-corridor", { percent = 30, seed = 1 })
  local path = os.tmpname()
  w:writeGrid(path)
  local rows, hash = 0, 0
  for line in io.lines(path) do
    if line:sub(1, 1) ~= "#" then
      rows = rows + 1
      if #line == 50 then hash = hash + select(2, line:gsub("#", "")) end
    end
  end
  os.remove(path)
  check("writeGrid: 250 rows of 50 cells", rows == 250, string.format("%d obstacle cells", hash))
end

-- Zarzhitsky's map format: nx lines of ny characters, ' ' or 'b', as his
-- PlumeGen's read_map_file expects; any size (a long one too).
do
  local w = World.new({ bounds = { 0, 0, 128, 128 } })
  w:rect(60, 40, 20, 10, 0.3); w:disc(90, 90, 8)
  local path = os.tmpname()
  local share = w:writeCPT(path, 128)
  local rows, okLines, nb = 0, true, 0
  for line in io.lines(path) do
    rows = rows + 1
    if #line ~= 128 or line:find("[^ b]") then okLines = false end
    nb = nb + select(2, line:gsub("b", ""))
  end
  os.remove(path)
  local area = (20 * 10 + math.pi * 64) / (128 * 128)
  check("writeCPT: 128 lines of 128 ' '/'b' characters", rows == 128 and okLines,
        string.format("blocked %.2f%% (shapes' area %.2f%%)", 100 * share, 100 * area))
  check("writeCPT: blocked share matches the shapes", math.abs(share - area) < 0.003 and nb == math.floor(share * 128 * 128 + 0.5))
  local c = World.preset("ch07-corridor", { percent = 30, seed = 1 })
  local p2 = os.tmpname()
  c:writeCPT(p2, 250, 1250)                          -- 4-inch cells, not square, over 1024
  local r2, ok2 = 0, true
  for line in io.lines(p2) do r2 = r2 + 1; if #line ~= 1250 then ok2 = false end end
  os.remove(p2)
  check("writeCPT: any size (250 x 1250 corridor)", r2 == 250 and ok2)
end

if fails == 0 then print(string.format("PASS world: %d tests", count))
else print(string.format("FAIL world: %d of %d tests failed", fails, count)) end
if not rawget(_G, "v") then os.exit(fails == 0 and 0 or 1) end
