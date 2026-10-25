--
-- lib/vegetation.lua -- the world generator's trees and hedges (BOOK.md
-- G21, §6)
--
-- Built last, on the zones, streets, buildings and mission features:
--
--   WOODS        zone A is trees: WOOD_DENSITY trunks a hectare on a
--                jittered grid (each point moved up to 30% of the spacing
--                either way), each as tall as the canopy there (CANOPY m,
--                varying +-25% with a noise field) times 0.85-1.15; their
--                crowns (radius WOOD_CROWN x height, from WOOD_BASE x
--                height up) just touch, so the canopy is closed above and
--                open below, between the trunks. Trunks keep 1 m off the
--                streets (crowns may hang over them), off water, pads and
--                buildings (with their crowns). From their own random
--                stream, so the other trees and hedges are unchanged.
--   STREET TREES every STREET_SPACING along both sides of the streets in
--                the built zones but the compact ones (1, 2, 3) and
--                industry (8, 10), 1.5 m inside the right of way's edge.
--   GARDENS      one tree behind each house (zones 6 and 9), with
--                probability GARDEN.
--   PARKS        zone B: a tree every PARK_SPACING on a jittered grid.
--   HEDGEROWS    on open land (zone D): along field boundaries a field
--                FIELD m apart (a grid at a random angle, each line moved
--                up to a fifth of a field), in 25 m lengths, one in seven
--                left out as a gap or gate; 2 m wide, 3 m high.
--
-- A tree is a trunk (radius 0.3 m, from the ground to the crown) and a
-- crown (a disc of radius 0.3 x its height, from 40% of its height to the
-- top; a wood's tree: WOOD_CROWN, from WOOD_BASE), both World pieces
-- tagged "tree", so vehicles pass under crowns.
-- Trees and hedges keep off buildings, streets (but a street tree's crown
-- may hang over its street), water and launch pads. Trees block sight and
-- sound; for air they are porous (the plume code will treat the tags
-- "tree" and "hedge" as porous, not solid).
--
-- FIXED CONSTANTS (stated, not knobs):
--   CANOPY 20 m          temperate woodland canopy height (typically 15-30 m)
--   WOOD_DENSITY 300/ha  trunks per hectare (William, 2026-10-22; mature
--                        temperate woodland has roughly 200-400): 5.8 m
--                        apart on the grid
--   WOOD_CROWN 0.15      crown radius / height in a closed stand: ~3 m at
--                        20 m, so neighbours' crowns just touch (open-grown
--                        trees' crowns are wider: 0.3)
--   WOOD_BASE 0.5        crowns from half the height (trees in a dense
--                        stand lose their lower branches): ~10 m of clear
--                        air under a 20 m canopy
--   STREET_SPACING 12 m  street trees 25-40 ft apart in common city
--                        guidelines; we take 12 m (40 ft)
--   GARDEN 0.6           share of houses with a tree behind
--   PARK_SPACING 15 m    open parkland, a tree per ~225 m^2
--   FIELD 250 m          fields about 6 ha, within the common 4-10 ha
--   heights: street trees 7-13 m, garden 5-11 m, park 10-18 m
--
-- RANDOMNESS: its own stream, rng.new(seed + 4000); the woods' trees
-- rng.new(seed + 4100).
--
-- SPEED: inside BPP the woods' meshes are made by BPP's compiled helpers
-- (geo.woods, src/geo.cpp), corner for corner as the Lua below makes them
-- (checks/geo.lua compares the two); under plain Lua the Lua runs.
--

local rng = require "lib.rng"
local B = require "lib.buildings"
local Land = require "lib.terrain"

local V = {}
local geo = rawget(_G, "geo")         -- BPP's compiled helpers, or nil

local floor, sqrt, abs, min, max, cos, sin, pi = math.floor, math.sqrt, math.abs, math.min, math.max,
  math.cos, math.sin, math.pi

V.CANOPY = 20
V.WOOD_DENSITY = 300
V.WOOD_CROWN = 0.15
V.WOOD_BASE = 0.5
V.STREET_SPACING = 12
V.GARDEN = 0.6
V.PARK_SPACING = 15
V.FIELD = 250
V.HEDGE = { 2, 3 }

local STREET_ZONES = { ["5"] = true, ["6"] = true, ["9"] = true }

-- Is a disc (x, y, r) clear of buildings (by 0.5 m), pads and water?
local function clearOf(W, x, y, r, idx)
  if W.terrain:water(x, y) then return false end
  for _, pad in ipairs(W.pads or {}) do
    if abs(x - pad.x) < pad.size / 2 + r and abs(y - pad.y) < pad.size / 2 + r then return false end
  end
  local d = B.discPart(x, y, r + 0.5)
  local R = r + 0.5 + 1e-6
  for i = -1, 1 do
    for j = -1, 1 do
      for _, p in ipairs(idx[(floor(x / 50) + i) * 100003 + floor(y / 50) + j] or {}) do
        -- (a part whose bounding box is farther than the disc's radius
        -- cannot touch it)
        local x0, y0, x1, y1 = B.partBox(p)
        if x - R <= x1 and x + R >= x0 and y - R <= y1 and y + R >= y0 and B.partDist(d, p) <= 0 then return false end
      end
    end
  end
  return true
end

local function addTree(W, x, y, h, kind, r)
  local g = W.terrain:ground(x, y)
  W.trees[#W.trees + 1] = { x = x, y = y, h = h, r = r or 0.3 * h, g = g, kind = kind }
end

-- Where a tree's crown starts, as a fraction of its height.
local function crownBase(tr) return tr.kind == "wood" and V.WOOD_BASE or 0.4 end

function V.build(W, spec)
  local t0 = os.clock()
  local s = rng.new((spec.seed or 1) + 4000)
  local town, t = W.town, W.terrain
  W.trees, W.hedges = {}, {}
  -- buildings' parts by 50 m bucket, for the clearance tests
  local idx = {}
  for _, b in ipairs(W.buildings) do
    for _, p in ipairs(b.parts) do
      local x0, y0, x1, y1 = B.partBox(p)
      for i = floor(x0 / 50), floor(x1 / 50) do
        for j = floor(y0 / 50), floor(y1 / 50) do
          local k = i * 100003 + j
          idx[k] = idx[k] or {}
          table.insert(idx[k], p)
        end
      end
    end
  end
  -- the woods' height (their trees are placed last, below)
  local W2, H2 = t.x1 - t.x0, t.y1 - t.y0
  local noise = Land.newNoise(s, W2, H2, 150, 2)
  local function canopy(x, y) return V.CANOPY * (1 + 0.25 * Land.fbm(noise, x - t.x0, y - t.y0)) end
  -- street trees
  for _, st in ipairs(town.streets) do
    if st.kind ~= "bridge" then
      local p, acc, nextAt = st.pts, 0, V.STREET_SPACING / 2
      for q = 1, #p - 3, 2 do
        local dx, dy = p[q + 2] - p[q], p[q + 3] - p[q + 1]
        local L = sqrt(dx * dx + dy * dy)
        while L > 0 and acc + L >= nextAt do
          local f = (nextAt - acc) / L
          local cx, cy = p[q] + f * dx, p[q + 1] + f * dy
          for _, side in ipairs({ 1, -1 }) do
            local off = st.width / 2 - 1.5
            local x, y = cx - dy / L * off * side, cy + dx / L * off * side
            if STREET_ZONES[town:zone(x - dy / L * side * 6, y + dx / L * side * 6)] then
              local h = 7 + 6 * s:random()
              -- the trunk must stand clear of every other street and turning circle
              local onOther = town:near(x - 20, y - 20, x + 20, y + 20, function(o, ax, ay, bx2, by2)
                if o == st then return false end
                if not ax then return sqrt((x - o.bulb[1]) ^ 2 + (y - o.bulb[2]) ^ 2) < o.bulb[3] + 1 end
                return Land.segDist(x, y, ax, ay, bx2, by2) < o.width / 2 + 1
              end)
              if not onOther and clearOf(W, x, y, 0.3 * h, idx) then addTree(W, x, y, h, "street") end
            end
          end
          nextAt = nextAt + V.STREET_SPACING
        end
        acc = acc + L
      end
    end
  end
  -- garden trees: behind each house, centred, 4 m inside the rear line
  for _, lot in ipairs(W.lots) do
    if (lot.zone == "6" or lot.zone == "9") and s:random() < V.GARDEN then
      local h = 5 + 6 * s:random()
      local vx, vy = -lot.uy, lot.ux
      local back = lot.hv - 0.3 * h - 1
      local x, y = lot.x + vx * back, lot.y + vy * back
      if town:streetDistance(x, y, 40) > 0.3 * h and clearOf(W, x, y, 0.3 * h, idx) then addTree(W, x, y, h, "garden") end
    end
  end
  -- parks: a jittered grid over zone B
  local b = W.bounds
  for x = b.x0 + V.PARK_SPACING / 2, b.x1, V.PARK_SPACING do
    for y = b.y0 + V.PARK_SPACING / 2, b.y1, V.PARK_SPACING do
      local jx, jy = x + (s:random() - 0.5) * V.PARK_SPACING * 0.6, y + (s:random() - 0.5) * V.PARK_SPACING * 0.6
      local h = 10 + 8 * s:random()
      if town:zone(jx, jy) == "B" and town:streetDistance(jx, jy, 40) > 0.3 * h and clearOf(W, jx, jy, 0.3 * h, idx) then
        addTree(W, jx, jy, h, "park")
      end
    end
  end
  -- hedgerows along field boundaries on open land
  local a = s:random() * pi
  local ux, uy = cos(a), sin(a)
  local nx, ny = -uy, ux
  local cx, cy = (b.x0 + b.x1) / 2, (b.y0 + b.y1) / 2
  local R = sqrt((b.x1 - b.x0) ^ 2 + (b.y1 - b.y0) ^ 2) / 2
  local N = math.ceil(R / V.FIELD)
  for fam = 1, 2 do
    local ex, ey = fam == 1 and ux or nx, fam == 1 and uy or ny
    local ox, oy = -ey, ex
    for i = -N, N do
      local off = i * V.FIELD + (s:random() - 0.5) * 0.4 * V.FIELD
      for tt = -R, R - 25, 25 do
        local x0, y0 = cx + ox * off + ex * tt, cy + oy * off + ey * tt
        local x1, y1 = x0 + ex * 25, y0 + ey * 25
        local mx, my = (x0 + x1) / 2, (y0 + y1) / 2
        if s:random() >= 1 / 7 and mx > b.x0 + 15 and mx < b.x1 - 15 and my > b.y0 + 15 and my < b.y1 - 15
           and town:zone(x0, y0) == "D" and town:zone(x1, y1) == "D" and town:zone(mx, my) == "D" then
          local p = B.rectPart(mx, my, ex, ey, 12.5, V.HEDGE[1] / 2)
          local ok = not t:water(x0, y0) and not t:water(x1, y1)
          ok = ok and not town:near(mx - 30, my - 30, mx + 30, my + 30, function(st, ax, ay, bx2, by2)
            if not ax then return B.segRectDist(p, st.bulb[1], st.bulb[2], st.bulb[1], st.bulb[2]) < st.bulb[3] + 2 end
            return B.segRectDist(p, ax, ay, bx2, by2) < st.width / 2 + 2
          end)
          if ok and clearOf(W, mx, my, 13, idx) then
            W.hedges[#W.hedges + 1] = { part = p, g = min(t:ground(x0, y0), t:ground(x1, y1)) }
          end
        end
      end
    end
  end
  -- woods: trees on a jittered grid over zone A
  local sw = rng.new((spec.seed or 1) + 4100)
  local sp = sqrt(10000 / V.WOOD_DENSITY)
  for x = b.x0 + sp / 2, b.x1, sp do
    for y = b.y0 + sp / 2, b.y1, sp do
      local jx, jy = x + (sw:random() - 0.5) * sp * 0.6, y + (sw:random() - 0.5) * sp * 0.6
      local f = 0.85 + 0.3 * sw:random()          -- (three draws at every point, in or out)
      if town:zone(jx, jy) == "A" and not t:water(jx, jy) then
        local h = canopy(jx, jy) * f
        local r = V.WOOD_CROWN * h
        if town:streetDistance(jx, jy, 20) > 1 and clearOf(W, jx, jy, r, idx) then
          addTree(W, jx, jy, h, "wood", r)
        end
      end
    end
  end
  W.buildTimeVegetation = os.clock() - t0
end

-- Trees (trunk and crown) and hedges as World pieces tagged "tree" and
-- "hedge", drawn by V.toBPP.
function V.addPieces(W)
  for _, tr in ipairs(W.trees or {}) do
    local cb = crownBase(tr)
    local trunk = W:disc(tr.x, tr.y, 0.3, "tree", cb * tr.h + 0.3)
    trunk.base, trunk.inMesh = tr.g - 0.3, true
    local crown = W:disc(tr.x, tr.y, tr.r, "tree", (1 - cb) * tr.h)
    crown.base, crown.inMesh = tr.g + cb * tr.h, true
  end
  for _, hd in ipairs(W.hedges or {}) do
    local p = hd.part
    local piece = W:rect(p.x, p.y, 2 * p.hu, 2 * p.hv, math.atan2 and math.atan2(p.uy, p.ux) or math.atan(p.uy, p.ux),
                         "hedge", V.HEDGE[2] + 0.3)
    piece.base, piece.inMesh = hd.g - 0.3, true
  end
end

--------------------------------------------------------------------------
-- BPP geometry
--------------------------------------------------------------------------

local CF_STATIC, CF_NO_CONTACT = 1, 4

-- Trees and hedges in one mesh: crowns as 8-sided double cones (a point
-- at the top and one at the crown's base, the widest ring a third of the
-- way up the crown), trunks as 4-sided prisms, hedges as boxes. The woods'
-- trees, tens of thousands of them, are lighter: 6-sided crowns and
-- 3-sided trunks, in four meshes of one colour each (three greens and
-- bark), so no triangle needs a colour of its own. Each tree's corners are
-- made once and shared by its triangles (the meshes copy them). Returns
-- the meshes (a list), or nil.
function V.toBPP(W, viewer, opts)
  opts = opts or {}
  local S, base = opts.scale or 1, opts.base or 0
  local function P(x, y, h) return btVector3(x * S, base + h * S, -y * S) end
  local leaf = { { 62, 110, 52 }, { 74, 124, 58 }, { 54, 98, 46 } }
  local bark = { 96, 74, 52 }
  local function circle(m, turn)
    local c, sn = {}, {}
    for k = 0, m - 1 do c[k] = cos(k * 2 * pi / m + turn); sn[k] = sin(k * 2 * pi / m + turn) end
    return c, sn
  end
  -- adds a tree to crown mesh `cm` and trunk mesh `tm` (with colours if
  -- `tri` records them): an mc-sided crown, an mt-sided trunk
  local function tree(tr, mc, Cc, Sc, mt, Ct, St, crownTri, trunkTri)
    local g, h, r = tr.g, tr.h, tr.r
    local cb = crownBase(tr)
    local z0 = g + cb * h
    local zm, z1 = z0 + (1 - cb) * h / 3, g + h
    local ring = {}
    for k = 0, mc - 1 do ring[k] = P(tr.x + r * Cc[k], tr.y + r * Sc[k], zm) end
    local top, bot = P(tr.x, tr.y, z1), P(tr.x, tr.y, z0)
    for k = 0, mc - 1 do
      local k1 = (k + 1) % mc
      crownTri(ring[k], ring[k1], top)
      crownTri(ring[k1], ring[k], bot)
    end
    local lo, hi = {}, {}
    for k = 0, mt - 1 do
      lo[k] = P(tr.x + 0.3 * Ct[k], tr.y + 0.3 * St[k], g - 0.3)
      hi[k] = P(tr.x + 0.3 * Ct[k], tr.y + 0.3 * St[k], z0)
    end
    for k = 0, mt - 1 do
      local k1 = (k + 1) % mt
      trunkTri(lo[k], lo[k1], hi[k1])
      trunkTri(lo[k], hi[k1], hi[k])
    end
  end
  local out = {}
  local function finish(mesh, n, col, cols)
    if n == 0 then return end
    mesh:build()
    mesh.col = col
    if cols then for i = 0, n - 1 do mesh:setTriangleColor(i, cols[i][1], cols[i][2], cols[i][3]) end end
    viewer:add(mesh)
    if not opts.contact then pcall(function() mesh.body:setCollisionFlags(CF_STATIC + CF_NO_CONTACT) end) end
    out[#out + 1] = mesh
  end

  -- the street, garden and park trees and the hedges: one mesh, coloured
  local mesh, cols, n = Terrain(), {}, 0
  local function tri(a, b, c, col) mesh:addTriangle(a, b, c); cols[n] = col; n = n + 1 end
  local C8, S8 = circle(8, 0)
  local C4, S4 = circle(4, pi / 4)
  local col
  local function crownTri(a, b, c) tri(a, b, c, col) end
  local function trunkTri(a, b, c) tri(a, b, c, bark) end
  for i, tr in ipairs(W.trees or {}) do
    if tr.kind ~= "wood" then
      col = leaf[i % 3 + 1]
      tree(tr, 8, C8, S8, 4, C4, S4, crownTri, trunkTri)
    end
  end
  local hedge = { 70, 112, 50 }
  for _, hd in ipairs(W.hedges or {}) do
    local c = hd.part.c
    local lo, hi = hd.g - 0.3, hd.g + V.HEDGE[2]
    for q = 1, 7, 2 do
      local q2 = (q + 1) % 8 + 1
      tri(P(c[q], c[q + 1], lo), P(c[q2], c[q2 + 1], lo), P(c[q2], c[q2 + 1], hi), hedge)
      tri(P(c[q], c[q + 1], lo), P(c[q2], c[q2 + 1], hi), P(c[q], c[q + 1], hi), hedge)
    end
    tri(P(c[1], c[2], hi), P(c[3], c[4], hi), P(c[5], c[6], hi), hedge)
    tri(P(c[1], c[2], hi), P(c[5], c[6], hi), P(c[7], c[8], hi), hedge)
  end
  finish(mesh, n, "#3e6e34", cols)

  -- the woods' trees: three crown meshes (one green each) and one of trunks
  -- (written out: tens of thousands of trees, 18 triangles each)
  local crowns, nc = { Terrain(), Terrain(), Terrain() }, { 0, 0, 0 }
  local trunks, nt = Terrain(), 0
  local add = trunks.addTriangle                   -- (fetched once)
  local C6, S6 = circle(6, 0)
  local C3, S3 = circle(3, pi / 6)
  local ring, lo, hi = {}, {}, {}
  if geo and type(trunks) == "userdata" then       -- (not a stand-in mesh)
    nc[1], nc[2], nc[3], nt = geo.woods(W.trees or {}, crowns[1], crowns[2], crowns[3], trunks, S, base,
                                        V.WOOD_BASE, C6, S6, C3, S3)
  else
    for i, tr in ipairs(W.trees or {}) do
      if tr.kind == "wood" then
        local which = i % 3 + 1
        local cm = crowns[which]
        local x, y, g, h, r = tr.x, tr.y, tr.g, tr.h, tr.r
        local z0 = g + V.WOOD_BASE * h
        local zm, z1 = z0 + (1 - V.WOOD_BASE) * h / 3, g + h
        for k = 0, 5 do ring[k] = P(x + r * C6[k], y + r * S6[k], zm) end
        local top, bot = P(x, y, z1), P(x, y, z0)
        for k = 0, 5 do
          local k1 = k < 5 and k + 1 or 0
          add(cm, ring[k], ring[k1], top)
          add(cm, ring[k1], ring[k], bot)
        end
        nc[which] = nc[which] + 12
        for k = 0, 2 do
          lo[k] = P(x + 0.3 * C3[k], y + 0.3 * S3[k], g - 0.3)
          hi[k] = P(x + 0.3 * C3[k], y + 0.3 * S3[k], z0)
        end
        for k = 0, 2 do
          local k1 = k < 2 and k + 1 or 0
          add(trunks, lo[k], lo[k1], hi[k1])
          add(trunks, lo[k], hi[k1], hi[k])
        end
        nt = nt + 6
      end
    end
  end
  local function hex(c) return string.format("#%02x%02x%02x", c[1], c[2], c[3]) end
  for k = 1, 3 do finish(crowns[k], nc[k], hex(leaf[k])) end
  finish(trunks, nt, hex(bark))
  if #out == 0 then return nil end
  return out
end

return V
