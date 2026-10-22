--
-- checks/features.lua -- the world generator's mission features, trees and
-- outputs (lib/features.lua, lib/vegetation.lua, World:raster, sight,
-- traps), on the harbour town (the capstone's world), the industrial port
-- and the rural and suburban presets
--
-- DEFINITIONS (printed values, metres unless stated):
--   under-keel clearance  seabed below the ship's keel, the least over its
--                         hull's corners and centre
--   cover                 ground minus the culvert's roof
--   flooded               length of culvert whose invert is below sea level
--   open / blocked        World:blockedAt at the point
--   trap                  open ground unreachable from a street (2 m raster)
--
-- Run from the ArtificialPhysics folder (about 25 s):
--   lua5.1 checks/features.lua
-- or inside BPP: bpp -f checks/features.lua -n 1
--

local here = (arg and arg[0] and arg[0]:match("^(.*)[/\\]checks[/\\][^/\\]*$"))
if here then package.path = here .. "/?.lua;" .. package.path
else package.path = "./?.lua;../?.lua;" .. package.path end
local World = require "lib.world"
local F = require "lib.features"
local V = require "lib.vegetation"
local rng = require "lib.rng"

local fails, count = 0, 0
local function check(name, ok, detail)
  count = count + 1
  if not ok then fails = fails + 1 end
  print(string.format("%s %-58s %s", ok and "ok  " or "FAIL", name, detail or ""))
end
local abs, sqrt, max, min, floor = math.abs, math.sqrt, math.max, math.min, math.floor

print("features: " .. _VERSION)
local t0 = os.clock()
local H = World.preset("harbour-town", { seed = 1 })
local P = World.preset("industrial-port", { seed = 1 })
local R = World.preset("rural", { seed = 1 })
local Sb = World.preset("suburban", { seed = 1 })

local function find(w, kind)
  local out = {}
  for _, b in ipairs(w.buildings) do if b.kind == kind then out[#out + 1] = b end end
  return out
end

-- The ship: afloat at its berth, the leak at its side on the water.
do
  local ok, parts = true, {}
  for _, w in ipairs({ H, P }) do
    local ship = find(w, "ship")[1]
    local hull = ship.parts[1]
    local ukc = math.huge
    local pts = { hull.x, hull.y, hull.c[1], hull.c[2], hull.c[3], hull.c[4], hull.c[5], hull.c[6], hull.c[7], hull.c[8] }
    for k = 1, #pts, 2 do
      local L = w:waterAt(pts[k], pts[k + 1])
      if L ~= 0 then ok = false end
      ukc = min(ukc, hull.z0 - w:groundAt(pts[k], pts[k + 1]))
    end
    if ukc < 1 then ok = false end
    local L = w.leak
    local lv = w:waterAt(L.x, L.y)
    if lv ~= 0 or L.z ~= 0 then ok = false end
    local dx, dy = L.x - hull.x, L.y - hull.y
    local v = abs(-dx * hull.uy + dy * hull.ux)
    if abs(v - hull.hv - 0.5) > 1e-6 then ok = false end
    parts[#parts + 1] = string.format("%s: keel %.0f m, clearance %.1f m", w.name, hull.z0, ukc)
  end
  check("ship afloat (keel 1 m+ over the seabed); leak at its side", ok, table.concat(parts, "; "))
end

-- Piers over the water on piles reaching the seabed.
do
  local ok, n = true, 0
  for _, pier in ipairs(find(H, "pier")) do
    n = n + 1
    local deck = pier.parts[1]
    local wet, k = 0, 0
    for f = -0.9, 0.9, 0.1 do
      k = k + 1
      if H:waterAt(deck.x + deck.ux * f * deck.hu, deck.y + deck.uy * f * deck.hu) then wet = wet + 1 end
    end
    if wet / k < 0.8 then ok = false end
    for q = 2, #pier.parts do
      local p = pier.parts[q]
      if p.z0 > H:groundAt(p.x, p.y) or p.z1 ~= 2.5 then ok = false end
    end
  end
  check("piers: decks over the water, piles to the seabed", ok and n == 2, n .. " piers")
end

-- Warehouses: as many as asked, or as the zone has sheds left once the
-- yard has its lot; a doorway in every wall, open inside, roofed.
do
  local ok, n = true, 0
  for _, w in ipairs({ H, P }) do
    if not w.warehouses or #w.warehouses == 0 then ok = false end
    for _, b in ipairs(w.warehouses or {}) do
      n = n + 1
      local roof = b.parts[#b.parts]
      local g = w:groundAt(roof.x, roof.y)
      if w:blockedAt(roof.x, roof.y, g + 3) then ok = false end          -- inside
      if not w:blockedAt(roof.x, roof.y, b.top - 0.25) then ok = false end -- the roof
      local c = roof.c
      for q = 1, 7, 2 do
        local q2 = (q + 1) % 8 + 1
        local mx, my = (c[q] + c[q2]) / 2, (c[q + 1] + c[q2 + 1]) / 2
        local qx, qy = c[q] + 0.25 * (c[q2] - c[q]), c[q + 1] + 0.25 * (c[q2 + 1] - c[q + 1])
        local gm, gq = w:groundAt(mx, my), w:groundAt(qx, qy)
        if w:blockedAt(mx, my, gm + 2) then ok = false end                -- the doorway
        if not w:blockedAt(qx, qy, gq + 2) then ok = false end             -- the wall
      end
    end
  end
  check("warehouses: a doorway in each wall, open inside, roofed", ok,
        string.format("%d in the harbour town, %d in the port", #(H.warehouses or {}), #(P.warehouses or {})))
end

-- The container yard: whole boxes, pockets open from above.
do
  local ok, parts = true, {}
  for _, w in ipairs({ H, P }) do
    local stacks = find(w, "container")
    for _, b in ipairs(stacks) do
      local n = (b.top - b.base - 0.2) / F.TEU[3]
      if abs(n - floor(n + 0.5)) > 1e-9 or n < 1 - 1e-9 or n > 5 + 1e-9 then ok = false end
      local p = b.parts[1]
      if abs(2 * p.hu - F.TEU[1]) > 1e-9 or abs(2 * p.hv - F.TEU[2]) > 1e-9 then ok = false end
    end
    local y = w.yard
    if not y or y.pockets ~= 2 * y.blocks or y.stacks ~= #stacks then ok = false end
    parts[#parts + 1] = string.format("%s: %d blocks, %d stacks, %d pockets", w.name, y.blocks, y.stacks, y.pockets)
  end
  check("container yard: 20 ft boxes 1-5 high, two pockets a block", ok, table.concat(parts, "; "))
end

-- The storm drain.
do
  local d = H.tunnels[1]
  local okFall, okCover = true, true
  local p = d.pts
  for k = 2, #d.inv do if d.inv[k] > d.inv[k - 1] + 1e-12 then okFall = false end end
  for k = 1, #d.inv do
    if d.inv[k] + d.h > H:groundAt(p[2 * k - 1], p[2 * k]) - F.COVER + 1e-9 then okCover = false end
  end
  check("drain: the invert never rises downstream", okFall,
        string.format("%.0f m, invert %.1f to %.1f m", d.length, d.inv[1], d.inv[#d.inv]))
  check("drain: at least 1 m of cover all the way", okCover,
        string.format("last %.0f m below sea level (tide-locked outfall)", d.flooded))
  -- open inside, solid beside it
  local k = floor(#d.inv / 2)
  local x, y = p[2 * k - 1], p[2 * k]
  local dx, dy = p[2 * k + 1] - x, p[2 * k + 2] - y
  local L = sqrt(dx * dx + dy * dy)
  local sx, sy = -dy / L, dx / L
  local z = d.inv[k] + 1
  check("drain: open inside the culvert, ground beside it", not H:blockedAt(x, y, z)
        and H:blockedAt(x + sx * (d.w / 2 + 0.5), y + sy * (d.w / 2 + 0.5), z))
  local last = #d.inv
  local ex, ey = p[2 * last - 1], p[2 * last]
  check("drain: the outfall at the shore", not H:waterAt(ex, ey) and H:waterAt(ex + dx / L * 8, ey + dy / L * 8) ~= nil)
end

-- Launch pads: dry, level, clear.
do
  local ok, n = true, 0
  for _, w in ipairs({ H, P }) do
    for _, pad in ipairs(w.pads or {}) do
      n = n + 1
      local lo, hi = math.huge, -math.huge
      for i = -5, 5 do
        for j = -5, 5 do
          local x, y = pad.x + i * pad.size / 10 * 0.99, pad.y + j * pad.size / 10 * 0.99
          if w:waterAt(x, y) or w.town:streetDistance(x, y, 60) < 0 then ok = false end
          local g = w:groundAt(x, y)
          if w:blockedAt(x, y, g + 1) then ok = false end
          lo, hi = min(lo, g), max(hi, g)
        end
      end
      if hi - lo > 1.5 then ok = false end
    end
  end
  check("launch pads: 30 m squares, dry, level, clear", ok and n == 3, n .. " pads")
end

-- Vegetation.
do
  -- woods: trees at WOOD_DENSITY a hectare, open under the crowns, closed above
  local w = R
  local b = w.bounds
  local nWood, okWhere = 0, true
  for _, tr in ipairs(w.trees) do
    if tr.kind == "wood" then
      nWood = nWood + 1
      if w:zoneAt(tr.x, tr.y) ~= "A" or w:waterAt(tr.x, tr.y) or w.town:streetDistance(tr.x, tr.y, 20) <= 1 then
        okWhere = false
      end
    end
  end
  local inA = 0
  for x = b.x0 + 5, b.x1, 10 do
    for y = b.y0 + 5, b.y1, 10 do
      if w:zoneAt(x, y) == "A" and not w:waterAt(x, y) then inA = inA + 1 end
    end
  end
  local perHa = nWood / (inA * 100 / 1e4)
  check("woods: trees at WOOD_DENSITY a hectare", perHa > 0.85 * V.WOOD_DENSITY and perHa <= 1.03 * V.WOOD_DENSITY,
        string.format("%d trees over %.0f ha of zone A: %.0f a hectare (%d)", nWood, inA / 100, perHa, V.WOOD_DENSITY))
  check("woods: trunks in zone A, off water and streets", okWhere, nWood .. " trees")
  -- below every crown (the lowest is at WOOD_BASE x 0.75 x 0.85 x CANOPY
  -- = 6.4 m) only trunks block: nearly all open; at 70% of the canopy's
  -- height the crowns cover most of the ground
  local low, high, tested = 0, 0, 0
  local zl, zh = 5, 0.7 * V.CANOPY
  for i = 1, 60 do
    for j = 1, 60 do
      local x, y = b.x0 + i * 49, b.y0 + j * 49
      if w:zoneAt(x, y) == "A" and not w:waterAt(x, y) and w.town:streetDistance(x, y, 20) > 8 then
        tested = tested + 1
        local g = w:groundAt(x, y)
        if w:blockedAt(x, y, g + zl) then low = low + 1 end
        if w:blockedAt(x, y, g + zh) then high = high + 1 end
      end
    end
  end
  check("woods: open between the trunks, closed above", tested > 100 and low / tested < 0.03 and high / tested > 0.5,
        string.format("%d points: %.1f%% blocked at %g m, %.0f%% at %g m", tested, 100 * low / tested, zl, 100 * high / tested, zh))
  -- trees: zones, clear of buildings and other streets; crowns over open trunks
  local okZ, okClear, okUnder, n = true, true, true, 0
  for _, ww in ipairs({ Sb, H }) do
    for _, tr in ipairs(ww.trees) do
      n = n + 1
      if tr.kind == "park" and ww:zoneAt(tr.x, tr.y) ~= "B" then okZ = false end
      if ww:blocked(tr.x, tr.y, "building") then okClear = false end
    end
  end
  check("trees: parks' in zone B, none in a building", okZ and okClear, n .. " trees in the suburb and harbour town")
  -- street trees' crowns (pieces tagged "tree" wider than a trunk) start
  -- at 40% of the tree's height, at least 2.8 m up, so a vehicle passes
  local low = math.huge
  for _, ww in ipairs({ Sb, H }) do
    local byXY = {}
    for _, tr in ipairs(ww.trees) do if tr.kind == "street" then byXY[tr.x .. ":" .. tr.y] = tr end end
    for _, pc in ipairs(ww.pieces) do
      if pc.tag == "tree" and pc.r > 0.3 then
        local tr = byXY[pc.x .. ":" .. pc.y]
        if tr then
          low = min(low, pc.base - tr.g)
          if abs(pc.base - (tr.g + 0.4 * tr.h)) > 1e-9 then okUnder = false end
        end
      end
    end
  end
  check("street trees: crowns from 40% of their height (2.8 m+)", okUnder and low >= 2.8 - 1e-9,
        string.format("lowest crown %.1f m over the ground", low))
  local okH = true
  for _, hd in ipairs(R.hedges) do if R:zoneAt(hd.part.x, hd.part.y) ~= "D" then okH = false end end
  check("hedgerows only on open land (zone D)", okH and #R.hedges > 500, #R.hedges .. " hedges of 25 m")
end

-- Outputs: rasters, sight, traps.
do
  local w = H
  local rg = w:raster("ground", 50)
  local rd = w:raster("depth", 50)
  local ro = w:raster("occupancy", 50, { z = 10, above = true })
  local okR = true
  for j = 0, rg.ny - 1 do
    for i = 0, rg.nx - 1 do
      local k = j * rg.nx + i + 1
      local x, y = rg.x0 + (i + 0.5) * 50, rg.y0 + (j + 0.5) * 50
      if rg.v[k] ~= w:groundAt(x, y) then okR = false end
      local _, d = w:waterAt(x, y)
      if rd.v[k] ~= (d or 0) then okR = false end
      if (ro.v[k] == 1) ~= w:blockedAt(x, y, w:groundAt(x, y) + 10) then okR = false end
    end
  end
  local path = os.tmpname()
  w:writeRaster(path, "zone", 100)
  local rows = 0
  for line in io.lines(path) do if line:sub(1, 1) ~= "#" then rows = rows + 1 end end
  os.remove(path)
  check("rasters: ground, depth, occupancy match the world; zone file", okR and rows == 25,
        string.format("%d x %d cells of 50 m", rg.nx, rg.ny))
  local clear = w:sight(1300, 700, 5, 1700, 700, 5)
  local tall
  for _, b in ipairs(w.buildings) do if not b.kind and (not tall or b.height > tall.height) then tall = b end end
  local p = tall.parts[1]
  local z = tall.base + tall.height / 2
  local seen, at = w:sight(p.x - 60 * p.ux, p.y - 60 * p.uy, z, p.x + 60 * p.ux, p.y + 60 * p.uy, z)
  check("sight: clear across the bay, blocked by a building", clear and not seen and at <= 60,
        string.format("blocked after %.0f m", at or -1))
  local traps, n, nOpen = w:traps(2, { area = { 1100, 1150, 1500, 1550 } })
  local okT = true
  for k in pairs(traps) do
    if not traps[k] then okT = false end
  end
  check("traps: enclosed open ground in the old town (2 m raster)", okT and n < nOpen,
        string.format("%d of %d open cells (%.2f%%)", n, nOpen, 100 * n / nOpen))
end

-- Seeds and the shared stream.
do
  local function sum(w)
    local s = 0
    for i, tr in ipairs(w.trees) do s = (s + (tr.x + 2 * tr.y + tr.h) * (i % 89 + 1)) % 1e9 end
    for i, b in ipairs(w.buildings) do if b.kind then s = (s + (b.parts[1].x + b.top) * (i % 83 + 1)) % 1e9 end end
    return s
  end
  local a = sum(H)
  check("the same seed repeats the trees and features", sum(World.preset("harbour-town", { seed = 1 })) == a)
  rng.seed(42)
  local r1 = rng.random()
  rng.seed(42)
  World.preset("rural", { seed = 3 })
  check("building trees and features leaves the shared stream alone", rng.random() == r1)
end

print(string.format("all built in %.1f s", os.clock() - t0))
if fails == 0 then print(string.format("PASS features: %d tests", count))
else print(string.format("FAIL features: %d of %d tests failed", fails, count)) end
if not rawget(_G, "v") then os.exit(fails == 0 and 0 or 1) end
