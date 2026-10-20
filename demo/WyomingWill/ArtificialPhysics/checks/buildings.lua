--
-- checks/buildings.lua -- the world generator's lots and buildings
-- (lib/buildings.lua, on the five realistic presets of lib/places.lua)
--
-- DEFINITIONS (printed values, metres unless stated):
--   built       building fraction: share of a zone's plan area under
--               buildings, sampled on a 300 x 300 grid
--   height      mean height of a zone's buildings (roof above the highest
--               ground under each), each building counted once
--   LCZ range   Stewart and Oke's (2012) published range for the zone
--   gap         shortest distance between two buildings' footprints
--   ring        buildings whose first part lies 0-150, 150-300, ... m from
--               the city's centre
--
-- The presets are built to their buildings and features (layers = 3).
--
-- Run from the ArtificialPhysics folder (about 30 s):
--   lua5.1 checks/buildings.lua
-- or inside BPP: bpp -f checks/buildings.lua -n 1
--

local here = (arg and arg[0] and arg[0]:match("^(.*)[/\\]checks[/\\][^/\\]*$"))
if here then package.path = here .. "/?.lua;" .. package.path
else package.path = "./?.lua;../?.lua;" .. package.path end
local World = require "lib.world"
local Town = require "lib.town"
local B = require "lib.buildings"
local Places = require "lib.places"
local rng = require "lib.rng"

local fails, count = 0, 0
local function check(name, ok, detail)
  count = count + 1
  if not ok then fails = fails + 1 end
  print(string.format("%s %-58s %s", ok and "ok  " or "FAIL", name, detail or ""))
end
local abs, sqrt, max, min, floor = math.abs, math.sqrt, math.max, math.min, math.floor

print("buildings: " .. _VERSION .. ", presets: " .. table.concat(Places.names(), ", "))
local t0 = os.clock()
local worlds = {}
for _, name in ipairs(Places.names()) do worlds[name] = World.preset(name, { seed = 1, layers = 3 }) end

local function bsum(w)
  local s = 0
  for i, b in ipairs(w.buildings) do
    for _, p in ipairs(b.parts) do s = (s + (p.x + 3 * p.y) * (i % 97 + 1) + b.height) % 1e9 end
  end
  return s
end

-- Calibration: every built zone covering at least 3% of a preset falls in
-- its published ranges.
do
  local okB, okH, lines = true, true, {}
  for _, name in ipairs(Places.names()) do
    local st = B.stats(worlds[name], 300)
    local keys = {}
    for z in pairs(st) do keys[#keys + 1] = z end
    table.sort(keys)
    for _, z in ipairs(keys) do
      local o, L = st[z], Town.LCZ[z]
      if L and L.built and o.share >= 0.03 then
        if o.built < L.built[1] or o.built > L.built[2] then okB = false end
        if o.height < L.height[1] or o.height > L.height[2] then okH = false end
        lines[#lines + 1] = string.format("%s %s %.0f%%/%.0f m", name, z, 100 * o.built, o.height)
      end
    end
  end
  check("building fraction within each zone's LCZ range", okB, "")
  check("mean height within each zone's LCZ range", okH, "")
  for k = 1, #lines, 4 do print("        " .. table.concat(lines, "; ", k, min(#lines, k + 3))) end
end

-- Whole floors; sheds and tanks within their ranges (the mission
-- features, b.kind, are checked by checks/features.lua).
do
  local ok, nf, nh = true, 0, 0
  for _, name in ipairs(Places.names()) do
    for _, b in ipairs(worlds[name].buildings) do
      local T = B.TYPES[b.zone]
      if b.kind then
      elseif b.floors then
        nf = nf + 1
        if b.height ~= b.floors * B.FLOOR then ok = false end
        if T.floors and (b.floors < T.floors[3] or b.floors > T.floors[4]) then ok = false end
      else
        nh = nh + 1
        if b.parts[1].kind == "disc" then
          if b.height < 10 or b.height > 16 then ok = false end
        elseif T.height and (b.height < T.height[1] or b.height > T.height[2]) then ok = false end
      end
    end
  end
  check("whole floors of 3.5 m; sheds and tanks in their ranges", ok,
        string.format("%d floored, %d sheds and tanks", nf, nh))
end

-- The city's skyline: a heavy tail, and heights falling from the centre
-- to the open mid-rise, then level.
do
  -- a heavy right tail: skewness over 3 (a normal distribution's is 0) and
  -- the tallest at least 5 x the median; seeds 1-4 measure 4.1-5.7 and
  -- 6.6-10 x (the 99th percentile, 3.4-4.8 x, rests on a few dozen towers
  -- and is too unsteady to test)
  local w = worlds["city-centre"]
  local h, mean = {}, 0
  for _, b in ipairs(w.buildings) do if not b.kind then h[#h + 1] = b.height; mean = mean + b.height end end
  table.sort(h)
  mean = mean / #h
  local m2, m3 = 0, 0
  for _, v in ipairs(h) do m2, m3 = m2 + (v - mean) ^ 2, m3 + (v - mean) ^ 3 end
  local skew = (m3 / #h) / (m2 / #h) ^ 1.5
  local med = h[floor(#h / 2)]
  check("city: heavy tail (skewness > 3, tallest >= 5 x the median)", skew > 3 and h[#h] >= 5 * med,
        string.format("median %.1f m, tallest %.1f m, skewness %.1f", med, h[#h], skew))
  local c = w.town.centres[1]
  local ring = {}
  for _, b in ipairs(w.buildings) do
    local p = b.parts[1]
    local r = floor(sqrt((p.x - c.x) ^ 2 + (p.y - c.y) ^ 2) / 150) + 1
    ring[r] = ring[r] or { 0, 0 }
    ring[r][1], ring[r][2] = ring[r][1] + b.height, ring[r][2] + 1
  end
  local means, ok = {}, true
  for r = 1, 7 do means[r] = ring[r] and ring[r][1] / ring[r][2] or 0 end
  if not (means[1] > means[2] and means[2] > means[3]) then ok = false end
  for r = 4, 7 do if means[r] > 1.1 * means[3] then ok = false end end
  local parts = {}
  for r = 1, 7 do parts[#parts + 1] = string.format("%.0f", means[r]) end
  check("city: mean height falls outward, then levels", ok, "rings of 150 m: " .. table.concat(parts, ", ") .. " m")
end

-- The gap rule: buildings that touch make one obstacle (a row of houses,
-- a block of container stacks); two obstacles stand at least 3 m apart.
do
  local ok, n, closed, worst = true, 0, 0, math.huge
  for _, name in ipairs(Places.names()) do
    local w = worlds[name]
    local cells, owner, parent = {}, {}, {}
    local function key(i, j) return i * 100003 + j end
    local function root(b) while parent[b] ~= b do parent[b] = parent[parent[b]]; b = parent[b] end return b end
    for _, b in ipairs(w.buildings) do
      parent[b] = b
      for _, p in ipairs(b.parts) do
        owner[p] = b
        local i, j = floor(p.x / 100), floor(p.y / 100)
        cells[key(i, j)] = cells[key(i, j)] or {}
        table.insert(cells[key(i, j)], p)
      end
    end
    local pairs_ = {}
    for _, b in ipairs(w.buildings) do
      for _, p in ipairs(b.parts) do
        local i, j = floor(p.x / 100), floor(p.y / 100)
        for di = -1, 1 do
          for dj = -1, 1 do
            for _, q in ipairs(cells[key(i + di, j + dj)] or {}) do
              local c = owner[q]
              if c ~= b and c.id > b.id then
                local d = B.partDist(p, q)
                if d < 10 then
                  n = n + 1
                  if d <= 1e-6 then
                    closed = closed + 1
                    parent[root(b)] = root(c)              -- touching: one obstacle
                  else
                    pairs_[#pairs_ + 1] = { b, c, d }
                  end
                end
              end
            end
          end
        end
      end
    end
    for _, pr in ipairs(pairs_) do
      if root(pr[1]) ~= root(pr[2]) then
        worst = min(worst, pr[3])
        if pr[3] < B.MIN_GAP - 1e-9 then ok = false end
      end
    end
  end
  check("gap rule: obstacles touch (closed) or stand 3 m+ apart", ok,
        string.format("%d close pairs, %d touching, narrowest open gap %.2f m", n, closed, worst))
end

-- Buildings off the streets and out of the water, inside their lots'
-- setbacks from the street.
do
  local okS, okW, worst = true, true, math.huge
  for _, name in ipairs(Places.names()) do
    local w = worlds[name]
    for _, b in ipairs(w.buildings) do
      -- a ship, piers and the drain's headwall (at the shore) stand in the
      -- water by design
      for _, p in ipairs((b.kind == "ship" or b.kind == "pier" or b.kind == "outfall") and {} or b.parts) do
        local pts = p.kind == "disc" and { p.x + p.r, p.y, p.x - p.r, p.y, p.x, p.y + p.r, p.x, p.y - p.r, p.x, p.y }
                    or { p.c[1], p.c[2], p.c[3], p.c[4], p.c[5], p.c[6], p.c[7], p.c[8], p.x, p.y }
        for k = 1, #pts, 2 do
          local d = w.town:streetDistance(pts[k], pts[k + 1], 100)
          worst = min(worst, d)
          if d < -B.SAGITTA then okS = false end
          if w.terrain:water(pts[k], pts[k + 1]) then okW = false end
        end
      end
    end
  end
  check("buildings off the streets (a curve's sagitta, 1 m, at most)", okS,
        string.format("closest corner %.2f m from a street's edge", worst))
  check("buildings never in the water", okW)
end

-- Farmsteads along the rural roads.
do
  local n = 0
  for _, l in ipairs(worlds["rural"].lots) do if l.zone == "farm" then n = n + 1 end end
  check("rural: farmsteads along the roads (one per 400-900 m a side)", n >= 8 and n <= 30, n .. " farmsteads")
end

-- Seeds, and the shared stream.
do
  local okR, okD = true, true
  for _, name in ipairs({ "suburban", "harbour-town" }) do
    local a = bsum(worlds[name])
    if bsum(World.preset(name, { seed = 1, layers = 3 })) ~= a then okR = false end
    if bsum(World.preset(name, { seed = 2, layers = 3 })) == a then okD = false end
  end
  check("the same seed repeats the buildings; another seed changes them", okR and okD)
  rng.seed(42)
  local a = rng.random()
  rng.seed(42)
  World.preset("industrial-port", { seed = 9, layers = 3 })
  check("building lots and buildings leaves the shared stream alone", rng.random() == a)
end

-- Buildings block: inside the tallest tower below its roof, not above it;
-- the city cut at 30 m keeps only the towers.
do
  local w = worlds["city-centre"]
  local tall
  for _, b in ipairs(w.buildings) do if not tall or b.height > tall.height then tall = b end end
  local p = tall.parts[1]
  check("blockedAt: inside a tower below its roof, open above it",
        w:blockedAt(p.x, p.y, tall.top - 1) and not w:blockedAt(p.x, p.y, tall.top + 1),
        string.format("tallest %.1f m, %d floors", tall.height, tall.floors))
  local path = os.tmpname()
  local share = w:writeCPT(path, 160, 160, { z = w.terrain:ground(800, 1000) + 30 })
  os.remove(path)
  check("writeCPT at 30 m above the centre: only the towers block", share > 0.002 and share < 0.05,
        string.format("%.1f%% blocked", 100 * share))
end

print(string.format("all presets built in %.1f s", os.clock() - t0))
if fails == 0 then print(string.format("PASS buildings: %d tests", count))
else print(string.format("FAIL buildings: %d of %d tests failed", fails, count)) end
if not rawget(_G, "v") then os.exit(fails == 0 and 0 or 1) end
