--
-- lib/vegetation.lua -- the world generator's trees and hedges (BOOK.md
-- G21, §6)
--
-- Built last, on the zones, streets, buildings and mission features:
--
--   WOODS        zone A is a canopy: the ground is covered up to the
--                canopy's height (CANOPY m, varying +-25% with a noise
--                field); one volume, not tens of thousands of trees.
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
-- top), both World pieces tagged "tree", so vehicles pass under crowns.
-- Trees and hedges keep off buildings, streets (but a street tree's crown
-- may hang over its street), water and launch pads. Trees block sight and
-- sound; for air they are porous (the plume code will treat the tags
-- "tree", "hedge" and the canopy as porous, not solid).
--
-- FIXED CONSTANTS (stated, not knobs):
--   CANOPY 20 m          temperate woodland canopy height (typically 15-30 m)
--   STREET_SPACING 12 m  street trees 25-40 ft apart in common city
--                        guidelines; we take 12 m (40 ft)
--   GARDEN 0.6           share of houses with a tree behind
--   PARK_SPACING 15 m    open parkland, a tree per ~225 m^2
--   FIELD 250 m          fields about 6 ha, within the common 4-10 ha
--   heights: street trees 7-13 m, garden 5-11 m, park 10-18 m
--
-- RANDOMNESS: its own stream, rng.new(seed + 4000).
--

local rng = require "lib.rng"
local B = require "lib.buildings"
local Land = require "lib.terrain"

local V = {}

local floor, sqrt, abs, min, max, cos, sin, pi = math.floor, math.sqrt, math.abs, math.min, math.max,
  math.cos, math.sin, math.pi

V.CANOPY = 20
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
  for i = -1, 1 do
    for j = -1, 1 do
      for _, p in ipairs(idx[(floor(x / 50) + i) * 100003 + floor(y / 50) + j] or {}) do
        if B.partDist(d, p) <= 0 then return false end
      end
    end
  end
  return true
end

local function addTree(W, x, y, h, kind)
  local g = W.terrain:ground(x, y)
  W.trees[#W.trees + 1] = { x = x, y = y, h = h, r = 0.3 * h, g = g, kind = kind }
end

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
  -- woods: a canopy over zone A
  local W2, H2 = t.x1 - t.x0, t.y1 - t.y0
  local noise = Land.newNoise(s, W2, H2, 150, 2)
  W.canopy = function(x, y)
    if town:zone(x, y) ~= "A" then return 0 end
    return V.CANOPY * (1 + 0.25 * Land.fbm(noise, x - t.x0, y - t.y0))
  end
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
  W.buildTimeVegetation = os.clock() - t0
end

-- Trees (trunk and crown) and hedges as World pieces tagged "tree" and
-- "hedge", drawn by V.toBPP.
function V.addPieces(W)
  for _, tr in ipairs(W.trees or {}) do
    local trunk = W:disc(tr.x, tr.y, 0.3, "tree", 0.4 * tr.h + 0.3)
    trunk.base, trunk.inMesh = tr.g - 0.3, true
    local crown = W:disc(tr.x, tr.y, tr.r, "tree", 0.6 * tr.h)
    crown.base, crown.inMesh = tr.g + 0.4 * tr.h, true
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

-- One mesh: crowns as 8-sided double cones (a point at the top and one at
-- the crown's base), trunks as 4-sided prisms, hedges as boxes, and the
-- woods' canopy over zone A (the terrain's triangles lifted by the
-- canopy's height, walled at its edges).
function V.toBPP(W, viewer, opts)
  opts = opts or {}
  local S, base = opts.scale or 1, opts.base or 0
  local mesh = Terrain()
  local cols, n = {}, 0
  local function P(x, y, h) return btVector3(x * S, base + h * S, -y * S) end
  local function tri(a, b, c, col) mesh:addTriangle(a, b, c); cols[n] = col; n = n + 1 end
  local leaf = { { 62, 110, 52 }, { 74, 124, 58 }, { 54, 98, 46 } }
  local bark = { 96, 74, 52 }
  for i, tr in ipairs(W.trees or {}) do
    local col = leaf[i % 3 + 1]
    local g, h, r = tr.g, tr.h, tr.r
    local z0, zm, z1 = g + 0.4 * h, g + 0.6 * h, g + h
    for k = 0, 7 do
      local a0, a1 = k * pi / 4, (k + 1) * pi / 4
      local x0, y0 = tr.x + r * cos(a0), tr.y + r * sin(a0)
      local x1, y1 = tr.x + r * cos(a1), tr.y + r * sin(a1)
      tri(P(x0, y0, zm), P(x1, y1, zm), P(tr.x, tr.y, z1), col)
      tri(P(x1, y1, zm), P(x0, y0, zm), P(tr.x, tr.y, z0), col)
    end
    for k = 0, 3 do
      local a0, a1 = k * pi / 2 + pi / 4, (k + 1) * pi / 2 + pi / 4
      local x0, y0 = tr.x + 0.3 * cos(a0), tr.y + 0.3 * sin(a0)
      local x1, y1 = tr.x + 0.3 * cos(a1), tr.y + 0.3 * sin(a1)
      tri(P(x0, y0, g - 0.3), P(x1, y1, g - 0.3), P(x1, y1, z0), bark)
      tri(P(x0, y0, g - 0.3), P(x1, y1, z0), P(x0, y0, z0), bark)
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
  -- the canopy: each terrain triangle whose centre is in zone A, lifted
  local t = W.terrain
  if W.canopy then
    local woods = {}
    local s = t.stride
    local function key(k, upper) return upper and k or -k end
    t:eachTriangle(function(k, upper, a, b2, c)
      local xa, ya = t:nodeXY(a)
      local xb, yb = t:nodeXY(b2)
      local xc, yc = t:nodeXY(c)
      if W.town:zone((xa + xb + xc) / 3, (ya + yb + yc) / 3) == "A" then woods[key(k, upper)] = { a, b2, c } end
    end)
    local cache = {}
    local function H(k)
      if not cache[k] then
        local x, y = t:nodeXY(k)
        local c = W.canopy(x, y)
        if c == 0 then c = V.CANOPY end            -- an edge node outside zone A
        cache[k] = t.h[k] + c
      end
      return cache[k]
    end
    local canopyCol = { 50, 92, 44 }
    local edgeCol = { 44, 80, 38 }
    for kk, tr3 in pairs(woods) do
      local a, b2, c = tr3[1], tr3[2], tr3[3]
      local xa, ya = t:nodeXY(a)
      local xb, yb = t:nodeXY(b2)
      local xc, yc = t:nodeXY(c)
      tri(P(xa, ya, H(a)), P(xb, yb, H(b2)), P(xc, yc, H(c)), canopyCol)
    end
    -- walls on the edges between a wooded triangle and one that is not:
    -- an edge is shared by two triangles; count each edge's wooded owners
    local edges = {}
    for _, tr3 in pairs(woods) do
      for e = 1, 3 do
        local p, q = tr3[e], tr3[e % 3 + 1]
        local kx = p < q and (p .. ":" .. q) or (q .. ":" .. p)
        local rec = edges[kx]
        if rec then rec.n = rec.n + 1 else edges[kx] = { n = 1, p = p, q = q } end
      end
    end
    for _, e in pairs(edges) do
      if e.n == 1 then
        local xp, yp = t:nodeXY(e.p)
        local xq, yq = t:nodeXY(e.q)
        tri(P(xp, yp, t.h[e.p]), P(xq, yq, t.h[e.q]), P(xq, yq, H(e.q)), edgeCol)
        tri(P(xp, yp, t.h[e.p]), P(xq, yq, H(e.q)), P(xp, yp, H(e.p)), edgeCol)
      end
    end
  end
  if n == 0 then return nil end
  mesh:build()
  mesh.col = "#3e6e34"
  for i = 0, n - 1 do mesh:setTriangleColor(i, cols[i][1], cols[i][2], cols[i][3]) end
  viewer:add(mesh)
  if not opts.contact then pcall(function() mesh.body:setCollisionFlags(CF_STATIC + CF_NO_CONTACT) end) end
  return mesh
end

return V
