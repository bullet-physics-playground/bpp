--
-- checks/terrain.lua -- the world generator's terrain and water
-- (lib/terrain.lua, the five realistic presets in lib/places.lua)
--
-- DEFINITIONS (printed values, all in metres unless stated):
--   slope along the grid  rise over run between neighbouring nodes in the
--                         8 grid directions, between dry nodes
--   steepest triangle     the steepest dry triangle's slope (all 3 nodes dry)
--   sinuosity             channel length / straight distance between ends
--   wavelength            meander wavelength along the valley: twice the
--                         straight distance per bend, in channel widths
--   depth                 water level - ground
--
-- Run from the ArtificialPhysics folder (about 10 s):
--   lua5.1 checks/terrain.lua
-- or inside BPP: bpp -f checks/terrain.lua -n 1
--

local here = (arg and arg[0] and arg[0]:match("^(.*)[/\\]checks[/\\][^/\\]*$"))
if here then package.path = here .. "/?.lua;" .. package.path
else package.path = "./?.lua;../?.lua;" .. package.path end
local World = require "lib.world"
local Terrain = require "lib.terrain"
local Places = require "lib.places"
local rng = require "lib.rng"

local fails, count = 0, 0
local function check(name, ok, detail)
  count = count + 1
  if not ok then fails = fails + 1 end
  print(string.format("%s %-58s %s", ok and "ok  " or "FAIL", name, detail or ""))
end
local abs, sqrt, max, min = math.abs, math.sqrt, math.max, math.min
local atan2 = math.atan2 or function(y, x) return math.atan(y, x) end

print("terrain: " .. _VERSION .. ", presets: " .. table.concat(Places.names(), ", "))

-- J0 and the sine-generated curve's sinuosity.
check("J0(1) and J0(1.1) (tables: 0.7651977, 0.7196220)",
      abs(Terrain.J0(1) - 0.7651977) < 1e-7 and abs(Terrain.J0(1.1) - 0.7196220) < 1e-7,
      string.format("1/J0(1.1) = %.4f", 1 / Terrain.J0(1.1)))

-- Build every preset once (two seeds), keep seed 1.
local worlds, t0 = {}, os.clock()
local okRepeat, okDiffer, times = true, true, {}
for _, name in ipairs(Places.names()) do
  local c0 = os.clock()
  local w = World.preset(name, { seed = 1 })
  times[#times + 1] = string.format("%s %.2f", name, os.clock() - c0)
  worlds[name] = w
  if World.preset(name, { seed = 1 }).terrain:checksum() ~= w.terrain:checksum() then okRepeat = false end
  if World.preset(name, { seed = 2 }).terrain:checksum() == w.terrain:checksum() then okDiffer = false end
end
check("the same seed repeats each preset exactly", okRepeat)
check("different seeds give different terrain", okDiffer, "s: " .. table.concat(times, ", "))

do
  rng.seed(42)
  local a = rng.random()
  rng.seed(42)
  World.preset("rural", { seed = 9 })
  check("building terrain leaves the shared random stream alone", rng.random() == a)
end

-- ground() is the drawn surface: exact at nodes, and on random points the
-- plane through the corners of the triangle holding them.
do
  local t = worlds["harbour-town"].terrain
  local s, worst = rng.new(5), 0
  for _ = 1, 20000 do
    local x = t.x0 + (t.x1 - t.x0) * s:random()
    local y = t.y0 + (t.y1 - t.y0) * s:random()
    local i, j = math.floor((x - t.x0) / t.cell), math.floor((y - t.y0) / t.cell)
    local xa, ya = t.x0 + i * t.cell, t.y0 + j * t.cell
    local k = t:index(i, j)
    -- the triangle (i,j)-(i+1,j)-(i+1,j+1) or (i,j)-(i+1,j+1)-(i,j+1)
    local P
    if (x - xa) >= (y - ya) then
      P = { { xa, ya, t.h[k] }, { xa + t.cell, ya, t.h[k + 1] }, { xa + t.cell, ya + t.cell, t.h[k + t.stride + 1] } }
    else
      P = { { xa, ya, t.h[k] }, { xa + t.cell, ya + t.cell, t.h[k + t.stride + 1] }, { xa, ya + t.cell, t.h[k + t.stride] } }
    end
    -- barycentric weights
    local d = (P[2][2] - P[3][2]) * (P[1][1] - P[3][1]) + (P[3][1] - P[2][1]) * (P[1][2] - P[3][2])
    local l1 = ((P[2][2] - P[3][2]) * (x - P[3][1]) + (P[3][1] - P[2][1]) * (y - P[3][2])) / d
    local l2 = ((P[3][2] - P[1][2]) * (x - P[3][1]) + (P[1][1] - P[3][1]) * (y - P[3][2])) / d
    local z = l1 * P[1][3] + l2 * P[2][3] + (1 - l1 - l2) * P[3][3]
    worst = max(worst, abs(z - t:ground(x, y)))
  end
  local atNodes = true
  for k = 1, t.stride * (t.ny + 1), 37 do
    local x, y = t:nodeXY(k)
    if abs(t:ground(x, y) - t.h[k]) > 1e-9 then atNodes = false end
  end
  check("ground() is the mesh: exact at nodes, planar on triangles", atNodes and worst < 1e-9,
        string.format("worst %.1e m over 20,000 points", worst))
end

-- The slope rule: no dry slope along the grid above MAX_SLOPE; a dry
-- triangle at most sqrt(2) x steeper.
do
  local okGrid, okTri, lines = true, true, {}
  for _, name in ipairs(Places.names()) do
    local t = worlds[name].terrain
    local S, s, c = t.maxSlope, t.stride, t.cell
    local worst = 0
    for j = 0, t.ny do
      for i = 0, t.nx do
        local k = j * s + i + 1
        if not t.wl[k] then
          for _, d in ipairs({ { 1, 0 }, { 0, 1 }, { 1, 1 }, { -1, 1 } }) do
            local i2, j2 = i + d[1], j + d[2]
            if i2 >= 0 and i2 <= t.nx and j2 <= t.ny then
              local q = j2 * s + i2 + 1
              if not t.wl[q] then
                worst = max(worst, abs(t.h[q] - t.h[k]) / (c * sqrt(d[1] ^ 2 + d[2] ^ 2)))
              end
            end
          end
        end
      end
    end
    local st = t:stats()
    if worst > S + 1e-9 then okGrid = false end
    if st.maxSlope > sqrt(2) * S + 1e-9 then okTri = false end
    lines[#lines + 1] = string.format("%s %.1f/%.1f%%", name, 100 * worst, 100 * st.maxSlope)
  end
  check("dry slopes along the grid within 15% (every preset)", okGrid, table.concat(lines, ", "))
  check("steepest dry triangle within sqrt(2) x 15% = 21.2%", okTri, "(grid / triangle)")
end

-- Rivers: the level never rises downstream; the channel is width/12 deep
-- at its centre (the deepest river node reaches it, none goes deeper).
do
  local okFall, okDepth, lines = true, true, {}
  for _, name in ipairs(Places.names()) do
    local t = worlds[name].terrain
    for _, r in ipairs(t.rivers) do
      for q = 2, #r.level do if r.level[q] > r.level[q - 1] + 1e-12 then okFall = false end end
      local deepest = 0
      for k = 1, t.stride * (t.ny + 1) do
        if t.kind[k] == "river" then deepest = max(deepest, t.wl[k] - t.h[k]) end
      end
      if deepest < 0.95 * r.depth or deepest > r.depth + 1e-9 then okDepth = false end
      lines[#lines + 1] = string.format("%s %.2f of %.2f", name, deepest, r.depth)
    end
  end
  check("river levels never rise downstream", okFall)
  check("deepest river node = width/12, none deeper", okDepth, table.concat(lines, ", "))
end

-- A long river on flat ground: sinuosity 1/J0(1.1) and meander wavelength
-- 11 widths (Langbein and Leopold 1966; Leopold and Wolman 1960).
do
  local t = Terrain.generate({ bounds = { 0, 0, 30000, 4000 }, cell = 10, seed = 3,
                               land = { height = 30, rise = 0, relief = 0 },
                               rivers = { { from = { 0, 2000 }, to = { 30000, 2000 }, width = 20 } } })
  local r = t.rivers[1]
  local p = r.pts
  -- bends = sign changes of the heading's deviation from the valley (east)
  local bends, last = 0, 0
  for q = 1, #p / 2 - 1 do
    local dev = atan2(p[2 * q + 2] - p[2 * q], p[2 * q + 1] - p[2 * q - 1])
    local sgn = dev > 0.05 and 1 or (dev < -0.05 and -1 or 0)
    if sgn ~= 0 and sgn ~= last then
      if last ~= 0 then bends = bends + 1 end
      last = sgn
    end
  end
  local sin_ = r.length / r.straight
  local theory = 1 / Terrain.J0(Terrain.OMEGA)
  local wave = 2 * r.straight / bends / r.width
  check("long river: sinuosity 1/J0(1.1) = 1.390 within 2%", abs(sin_ / theory - 1) < 0.02,
        string.format("%.3f over %.1f km", sin_, r.length / 1000))
  check("long river: meander wavelength 11 widths within 10%", abs(wave / Terrain.MEANDER - 1) < 0.1,
        string.format("%.1f widths, %d bends", wave, bends))
end

-- The harbour town's river reaches the sea at level 0.
do
  local t = worlds["harbour-town"].terrain
  local r = t.rivers[1]
  local L, _, kind = t:water(r.pts[#r.pts - 1], r.pts[#r.pts])
  check("harbour town: the river runs into the bay at sea level",
        r.level[#r.level] == 0 and kind == "sea" and L == 0)
end

-- Ponds hold their water: the rim stands above the level all round.
do
  local ok, n = true, 0
  for _, name in ipairs(Places.names()) do
    local t = worlds[name].terrain
    for _, p in ipairs(t.ponds) do
      n = n + 1
      for a = 0, 71 do
        local ang = a * math.pi / 36
        if t:ground(p.x + 1.3 * p.r * math.cos(ang), p.y + 1.3 * p.r * math.sin(ang)) < p.level then ok = false end
      end
      local L, d = t:water(p.x, p.y)
      if not L or d < 0.5 * p.depth then ok = false end
    end
  end
  check("ponds: water at the centre, rim above the level all round", ok and n >= 4, n .. " ponds")
end

-- The sea: all ground below sea level is sea; depth grows offshore.
do
  local okBelow = true
  for _, name in ipairs(Places.names()) do
    local t = worlds[name].terrain
    for k = 1, t.stride * (t.ny + 1) do
      if t.h[k] < 0 and t.kind[k] ~= "sea" then okBelow = false end
    end
    if (t.raised or 0) ~= 0 then okBelow = false end
  end
  check("no ground below sea level outside the sea (none raised)", okBelow)
  local t = worlds["industrial-port"].terrain
  local x, ys = 200, { 700, 500, 300, 100 }
  local okShelf, prev, parts = true, 0, {}
  for _, y in ipairs(ys) do
    local _, d = t:water(x, y)
    d = d or 0
    if d <= prev then okShelf = false end
    prev = d
    parts[#parts + 1] = string.format("%.1f", d)
  end
  local expect = 0.0125 * (t.coastY(x) - 100)
  check("industrial port: the shelf deepens offshore at 1:80", okShelf and abs(prev - expect) < 0.5,
        "depths " .. table.concat(parts, ", ") .. string.format(" m (expected %.1f at the edge)", expect))
end

-- Dredging: depths, 1:3 sides, vertical quay walls.
do
  local t = worlds["industrial-port"].terrain
  local function depth(x, y) local _, d = t:water(x, y); return d or 0 end
  local h = worlds["harbour-town"].terrain
  local function depthH(x, y) local _, d = h:water(x, y); return d or 0 end
  local a, b = depth(1000, 60), depth(1000, 400)
  local a2, m2, b2 = depthH(1500, 200), depthH(1500, 620), depthH(1500, 900)
  check("approach 24 m, main channel 16 m, turning basin 16 m",
        abs(a - 24) < 1e-6 and abs(b - 16) < 1e-6 and abs(a2 - 24) < 1e-6 and abs(m2 - 16) < 1e-6
        and abs(b2 - 16) < 1e-6,
        string.format("port %.1f, %.1f; town %.1f, %.1f, %.1f", a, b, a2, m2, b2))
  -- the approach's side at the south edge (clear of the turning basin's):
  -- from 110 m off its centre, the ground rises 1 m per 3 m
  local g1, g2 = t:ground(1000 + 110 + 12, 4), t:ground(1000 + 110 + 24, 4)
  check("dredged sides slope 1:3", abs((g2 - g1) / 12 - 1 / 3) < 0.01,
        string.format("%.3f", (g2 - g1) / 12))
  -- the west basin's west wall at x = 610 lies between the nodes at 608
  -- (deck) and 616 (basin floor)
  local outside, inside = t.h[t:index(76, 125)], t.h[t:index(77, 125)]
  check("quay walls vertical: deck to basin floor between neighbouring nodes",
        abs(inside + 16) < 1e-6 and outside > 3.5,
        string.format("%.1f m to %.1f m across one 8 m cell", outside, inside))
end

-- The world cut at a height, for the 2D ports and Zarzhitsky's tools.
do
  local w = worlds["harbour-town"]
  local t = w.terrain
  local x, y = 1500, 300                       -- in the turning basin
  check("blockedAt: under the seabed blocked, in the water and above open",
        w:blockedAt(x, y, t:ground(x, y) - 0.1) and not w:blockedAt(x, y, -1) and not w:blockedAt(x, y, 50)
        and w:blockedAt(-10, y, 50))
  local path = os.tmpname()
  local share = w:writeCPT(path, 150, 125, { z = 10 })
  -- the same share from the nodes: ground above 10 m
  local above, n = 0, 0
  for k = 1, t.stride * (t.ny + 1), 3 do
    n = n + 1
    if t.h[k] > 10 then above = above + 1 end
  end
  local rows = 0
  for line in io.lines(path) do rows = rows + 1 end
  os.remove(path)
  check("writeCPT at z = 10 m: ground above 10 m blocked", rows == 150 and abs(share - above / n) < 0.02,
        string.format("%.1f%% blocked (nodes above 10 m: %.1f%%)", 100 * share, 100 * above / n))
end

print(string.format("all presets built in %.1f s", os.clock() - t0))
if fails == 0 then print(string.format("PASS terrain: %d tests", count))
else print(string.format("FAIL terrain: %d of %d tests failed", fails, count)) end
if not rawget(_G, "v") then os.exit(fails == 0 and 0 or 1) end
