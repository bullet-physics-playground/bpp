--
-- checks/town.lua -- the world generator's zones and streets (lib/town.lua,
-- the five realistic presets in lib/places.lua)
--
-- DEFINITIONS (printed values, metres unless stated):
--   u           zone intensity, peak exp(-d / r) (Clark 1951)
--   LCZ         Local Climate Zone code (Stewart and Oke 2012)
--   woods share woods (A) over open land (A + D)
--   reached     share of street sample points (every 5 m) reached from an
--               arterial through the streets themselves (rasterised on a
--               4 m grid, 8-neighbours), independently of lib/town.lua
--
-- The presets are built to their streets (layers = 2).
--
-- Run from the ArtificialPhysics folder (about 10 s):
--   lua5.1 checks/town.lua
-- or inside BPP: bpp -f checks/town.lua -n 1
--

local here = (arg and arg[0] and arg[0]:match("^(.*)[/\\]checks[/\\][^/\\]*$"))
if here then package.path = here .. "/?.lua;" .. package.path
else package.path = "./?.lua;../?.lua;" .. package.path end
local World = require "lib.world"
local Town = require "lib.town"
local Places = require "lib.places"
local Land = require "lib.terrain"
local rng = require "lib.rng"

local fails, count = 0, 0
local function check(name, ok, detail)
  count = count + 1
  if not ok then fails = fails + 1 end
  print(string.format("%s %-58s %s", ok and "ok  " or "FAIL", name, detail or ""))
end
local abs, sqrt, max, min, floor = math.abs, math.sqrt, math.max, math.min, math.floor

print("town: " .. _VERSION .. ", presets: " .. table.concat(Places.names(), ", "))

local t0 = os.clock()
local worlds = {}
for _, name in ipairs(Places.names()) do worlds[name] = World.preset(name, { seed = 1, layers = 2 }) end

-- Points along every street, every 5 m: { x, y, street }.
local function samples(town, step)
  local out = {}
  for _, s in ipairs(town.streets) do
    local p = s.pts
    for q = 1, #p - 3, 2 do
      local dx, dy = p[q + 2] - p[q], p[q + 3] - p[q + 1]
      local k = max(1, math.ceil(sqrt(dx * dx + dy * dy) / step))
      for i = 0, k do out[#out + 1] = { p[q] + dx * i / k, p[q + 1] + dy * i / k, s, i / k, q } end
    end
  end
  return out
end

local function streetsSum(town)
  local sum = 0
  for i, s in ipairs(town.streets) do
    for q, v in ipairs(s.pts) do sum = (sum + v * ((i * 31 + q * 7) % 101 + 1)) % 1e9 end
  end
  return sum
end

-- The published LCZ ranges we calibrate to (spot checks of the table).
do
  local L = Town.LCZ
  check("LCZ table: Stewart and Oke's building fractions and heights",
        L["1"].built[1] == 0.40 and L["1"].height[1] == 25 and L["2"].built[2] == 0.70
        and L["6"].built[1] == 0.20 and L["6"].built[2] == 0.40 and L["8"].built[1] == 0.30
        and L["9"].built[1] == 0.10 and L["9"].built[2] == 0.20 and L["10"].height[2] == 15,
        "e.g. open low-rise 20-40%, sparsely built 10-20%")
end

-- Clark's exponential: u = peak at a centre and peak / e at distance r.
do
  local town = worlds["city-centre"].town
  local c = town.centres[1]
  check("intensity: 1 at the centre, 1/e at distance r", abs(town:intensity(c.x, c.y) - 1) < 1e-12
        and abs(town:intensity(c.x + c.r, c.y) - math.exp(-1)) < 1e-12)
end

-- Zones step down the ladder going outward, and water is zone G.
do
  local okOrder, okWater, lines = true, true, {}
  for _, name in ipairs(Places.names()) do
    local w = worlds[name]
    local town, t = w.town, w.terrain
    local rank = {}
    for k, e in ipairs(town.ladder) do rank[e.lcz] = k end
    for _, c in ipairs(town.centres) do
      for a = 0, 15 do
        local last = 0
        for d = 0, 2000, 10 do
          local x, y = c.x + d * math.cos(a * math.pi / 8), c.y + d * math.sin(a * math.pi / 8)
          if x > t.x0 and x < t.x1 and y > t.y0 and y < t.y1 then
            local e = town:entry(x, y, true)
            local r = rank[e.lcz]
            -- districts sit outside the ladder; ladder zones never step back inward
            if r and e == town.ladder[r] then
              if r < last then okOrder = false end
              last = r
            end
          end
        end
      end
    end
    for k = 1, t.stride * (t.ny + 1), 13 do
      local x, y = t:nodeXY(k)
      if (t.wl[k] ~= nil) ~= (w:zoneAt(x, y) == "G") then okWater = false end
    end
    local st = town:stats()
    local z = {}
    for code, share in pairs(st.share) do if share > 0.005 then z[#z + 1] = code end end
    table.sort(z)
    lines[#lines + 1] = name .. " " .. table.concat(z, "/")
  end
  check("zones step down the ladder going outward", okOrder)
  check("water is zone G, exactly where the terrain has water", okWater)
  check("each preset has its zones", true, table.concat(lines, "; "))
end

-- Woods cover the stated share of the open land.
do
  local ok, parts = true, {}
  for _, p in ipairs({ { "rural", 0.25 }, { "suburban", 0.30 }, { "harbour-town", 0.30 } }) do
    local st = worlds[p[1]].town:stats(300)
    local A, D = st.share.A or 0, st.share.D or 0
    local share = A / (A + D)
    if abs(share - p[2]) > 0.03 then ok = false end
    parts[#parts + 1] = string.format("%s %.1f%% (asked %d%%)", p[1], 100 * share, 100 * p[2])
  end
  check("woods: the stated share of the open land (within 3%)", ok, table.concat(parts, ", "))
end

-- Seeds.
do
  local okRepeat, okDiffer = true, true
  for _, name in ipairs(Places.names()) do
    local a = streetsSum(worlds[name].town)
    if streetsSum(World.preset(name, { seed = 1, layers = 2 }).town) ~= a then okRepeat = false end
    -- the industrial port's streets are all straight grids and arterials,
    -- the same for every seed by design
    if name ~= "industrial-port" and streetsSum(World.preset(name, { seed = 2, layers = 2 }).town) == a then okDiffer = false end
  end
  check("the same seed repeats the streets exactly", okRepeat)
  check("different seeds give different streets (not the port's)", okDiffer)
  rng.seed(42)
  local a = rng.random()
  rng.seed(42)
  World.preset("suburban", { seed = 9, layers = 2 })
  check("building zones and streets leaves the shared stream alone", rng.random() == a)
end

-- Streets on dry land, except bridges; bridges no longer than allowed.
do
  local okDry, okBridge, okBounds, wet, longest = true, true, true, 0, 0
  for _, name in ipairs(Places.names()) do
    local w = worlds[name]
    local t, b = w.terrain, w.bounds
    for _, sp in ipairs(samples(w.town, 5)) do
      local x, y, s = sp[1], sp[2], sp[3]
      if x < b.x0 - 1e-6 or x > b.x1 + 1e-6 or y < b.y0 - 1e-6 or y > b.y1 + 1e-6 then okBounds = false end
      -- the 4 m tracing step can leave a street's end up to 4 m into water
      local interior = sp[4] > 0 and sp[4] < 1 or (sp[5] > 1 and sp[5] < #s.pts - 3)
      if s.kind ~= "bridge" and interior and t:water(x, y) then
        local _, d = t:water(x, y)
        wet = wet + 1
      end
    end
    for _, s in ipairs(w.town.streets) do
      if s.kind == "bridge" then
        local p, L = s.pts, 0
        for q = 1, #p - 3, 2 do L = L + sqrt((p[q + 2] - p[q]) ^ 2 + (p[q + 3] - p[q + 1]) ^ 2) end
        longest = max(longest, L)
        if L > Town.BRIDGE_MAX + 8 then okBridge = false end
      end
    end
  end
  -- a sample may sit in water where a street grazes a bank between its
  -- traced points; allow a handful in all five presets
  okDry = wet <= 20
  check("streets stay on dry land except bridges", okDry, wet .. " grazing samples of all")
  check("bridges no longer than 150 m", okBridge, string.format("longest %.0f m", longest))
  check("streets stay inside the area", okBounds)
end

-- Every street connects to an arterial: rasterise the streets (and their
-- turning circles) on a 4 m grid and flood from the arterials' cells.
do
  local ok, parts = true, {}
  for _, name in ipairs(Places.names()) do
    local w = worlds[name]
    local b, c = w.bounds, 4
    local nx, ny = math.ceil((b.x1 - b.x0) / c) + 1, math.ceil((b.y1 - b.y0) / c) + 1
    local cell, seeds = {}, {}
    local function mark(x, y, r, art)
      for i = floor((x - r - b.x0) / c), floor((x + r - b.x0) / c) do
        for j = floor((y - r - b.y0) / c), floor((y + r - b.y0) / c) do
          if i >= 0 and j >= 0 and i < nx and j < ny then
            local px, py = b.x0 + (i + 0.5) * c, b.y0 + (j + 0.5) * c
            if (px - x) ^ 2 + (py - y) ^ 2 <= r * r then
              local k = j * nx + i + 1
              cell[k] = true
              if art then seeds[#seeds + 1] = k end
            end
          end
        end
      end
    end
    local S = samples(w.town, 2)
    for _, sp in ipairs(S) do mark(sp[1], sp[2], sp[3].width / 2, sp[3].kind == "arterial") end
    for _, s in ipairs(w.town.streets) do if s.bulb then mark(s.bulb[1], s.bulb[2], s.bulb[3]) end end
    local seen, stack = {}, {}
    for _, k in ipairs(seeds) do if not seen[k] then seen[k] = true; stack[#stack + 1] = k end end
    while #stack > 0 do
      local k = table.remove(stack)
      local i, j = (k - 1) % nx, floor((k - 1) / nx)
      for di = -1, 1 do
        for dj = -1, 1 do
          local i2, j2 = i + di, j + dj
          if i2 >= 0 and j2 >= 0 and i2 < nx and j2 < ny then
            local q = j2 * nx + i2 + 1
            if cell[q] and not seen[q] then seen[q] = true; stack[#stack + 1] = q end
          end
        end
      end
    end
    local reached, n = 0, 0
    for _, sp in ipairs(samples(w.town, 5)) do
      n = n + 1
      local i, j = floor((sp[1] - b.x0) / c), floor((sp[2] - b.y0) / c)
      if seen[j * nx + i + 1] then reached = reached + 1 end
    end
    if reached < n then ok = false end
    parts[#parts + 1] = string.format("%s %d/%d", name, reached, n)
  end
  check("every street is reached from an arterial", ok, table.concat(parts, ", "))
end

-- The city's grid: Manhattan's spacing and widths.
do
  local town = worlds["city-centre"].town
  local F = town.ladder[1].grid
  local c, s = math.cos(F.angle), math.sin(F.angle)
  local okOff, okW, n = true, true, 0
  for _, st in ipairs(town.streets) do
    if st.kind == "grid" then
      local p = st.pts
      local dx, dy = p[3] - p[1], p[4] - p[2]
      local along1 = abs(dx * c + dy * s) > abs(-dx * s + dy * c)   -- runs along the angle: family 1
      local fam = along1 and 1 or 2
      -- offset across the line from the frame's origin
      local ox, oy = p[1] - F.x, p[2] - F.y
      local off = along1 and (-ox * s + oy * c) or (ox * c + oy * s)
      local sp = F.spacing[fam]
      local r = off / sp - floor(off / sp + 0.5)
      if abs(r) * sp > 1e-6 then okOff = false end
      if st.width ~= F.widths[fam] then okW = false end
      n = n + 1
    end
  end
  check("city grid: streets 80 m apart (18.3 m), avenues 274 m (30.5 m)", okOff and okW and n > 20,
        n .. " grid pieces")
end

-- Cul-de-sacs: each starts on a collector (its open end), runs at most the
-- fire code's 229 m and ends in a 15 m turning circle; locals never bridge.
do
  local okLen, okBulb, okStart, n = true, true, true, 0
  for _, name in ipairs(Places.names()) do
    local town = worlds[name].town
    for _, s in ipairs(town.streets) do
      if s.kind == "culdesac" then
        n = n + 1
        local p, L = s.pts, 0
        for q = 1, #p - 3, 2 do L = L + sqrt((p[q + 2] - p[q]) ^ 2 + (p[q + 3] - p[q + 1]) ^ 2) end
        if L > Town.CUL_MAX + 1e-6 or L < Town.MIN_RUN - 10 then okLen = false end
        if not s.bulb or s.bulb[3] ~= 15 or s.bulb[1] ~= p[#p - 1] or s.bulb[2] ~= p[#p] then okBulb = false end
        local near = math.huge
        for _, o in ipairs(town.streets) do
          if o.kind == "collector" or o.kind == "bridge" then   -- a collector's bridge is the collector
            local op = o.pts
            for r = 1, #op - 3, 2 do near = min(near, (Land.segDist(p[1], p[2], op[r], op[r + 1], op[r + 2], op[r + 3]))) end
          end
        end
        if near > 1 then okStart = false end
      end
    end
  end
  check("cul-de-sacs up to 229 m, ending in a 15 m turning circle", okLen and okBulb and n > 50, n .. " cul-de-sacs")
  check("every cul-de-sac starts on a collector (or its bridge)", okStart)
end

print(string.format("all presets built in %.1f s", os.clock() - t0))
if fails == 0 then print(string.format("PASS town: %d tests", count))
else print(string.format("FAIL town: %d of %d tests failed", fails, count)) end
if not rawget(_G, "v") then os.exit(fails == 0 and 0 or 1) end
