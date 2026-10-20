--
-- lib/features.lua -- the world generator's mission features (BOOK.md §6,
-- the capstone's harbour)
--
-- Built after the lots and buildings, from a preset's `features` table
-- (lib/places.lua):
--
--   SHIP         a ship at a berth, standing off the quay by one terrain
--                cell (the mesh draws a vertical quay wall as a slope one
--                cell wide) and 1 m of fenders: a hull from its keel (-draft) to its
--                deck (+freeboard) and a bridge house at the stern; the
--                leak (the capstone's source) on its seaward side at the
--                waterline: w.leak = { x, y, z }, region "leak".
--   PIERS        decks 2.5-3.5 m above the water on piles every 8 m along
--                both edges, from the shore out over the water.
--   WAREHOUSES   the largest sheds of the given zone (up to the count; as
--                many as are left once the yard has its lot) turned into shells
--                with doorways: walls 0.4 m thick, a 0.5 m roof slab, one
--                door 6 m wide and 5 m high (over the ground there) in the
--                middle of each wall,
--                so ground robots can drive in (a chain relay into a
--                warehouse).
--   CONTAINER    the largest lot of the given zone cleared and filled with
--   YARD         blocks of container stacks: 20 ft boxes (6.1 x 2.44 m,
--                2.59 m high), 6 rows by up to 20 bays a block, stacks 1-5
--                high; lanes 15 m wide between blocks; and pockets: in each
--                block two bays emptied 2-4 rows deep from a lane, U-shaped
--                dead ends (the cul-de-sacs of BOOK.md §7).
--   STORM DRAIN  a box culvert 2.4 m wide and 2 m high under the streets,
--                from inland down to an outfall at the shore: its invert
--                falls linearly, kept at least 1 m (cover) under the
--                ground and never rising downstream; manholes every 60 m;
--                a headwall with an opening at the outfall. w.tunnels holds
--                it, and blockedAt() treats its inside as open. Where the
--                shore is low, 1 m of cover takes the culvert below sea
--                level before it reaches the sea: that stretch is flooded
--                (a tide-locked outfall), and the drain records its length
--                (flooded, m).
--   LAUNCH PADS  30 x 30 m clear, level squares (drone launch), found
--                nearest a target point clear of buildings, streets and
--                water; regions "pad1", "pad2", ...; trees keep off them.
--
-- UNITS: metres, x east, y north, z elevation above sea level.
-- Every feature keeps the gap rule with its neighbours by construction
-- (stacks touch within a block; lanes, pockets and doors are wider than
-- 3 m).
--
-- DEFINITIONS:
--   invert   the floor of the culvert, m above sea level
--   cover    ground minus the culvert's roof, m
--

local rng = require "lib.rng"
local B = require "lib.buildings"

local F = {}

local floor, sqrt, abs, min, max, cos, sin, atan2 = math.floor, math.sqrt, math.abs, math.min, math.max,
  math.cos, math.sin, math.atan2 or function(y, x) return math.atan(y, x) end

F.TEU = { 6.1, 2.44, 2.59 }       -- a 20 ft container: length, width, height
F.CULVERT = { 2.4, 2.0 }          -- the storm drain's width and height
F.COVER = 1
F.PAD = 30

local function newBuilding(W, parts, base, top, color, zone, tag, kind)
  local b = { parts = parts, base = base, top = top, height = top - base, color = color, zone = zone,
              tag = tag, kind = kind }
  W.buildings[#W.buildings + 1] = b
  return b
end

-- A wall from (ax, ay) to (bx, by), thick, from z0 to z1, with a door
-- (width dw, height dh) in its middle if dw: up to three parts.
local function wallParts(ax, ay, bx, by, thick, z0, z1, dw, dh)
  local dx, dy = bx - ax, by - ay
  local L = sqrt(dx * dx + dy * dy)
  local ux, uy = dx / L, dy / L
  local parts = {}
  local function seg(s0, s1, za, zb)
    local c = (s0 + s1) / 2
    local p = B.rectPart(ax + ux * c, ay + uy * c, ux, uy, (s1 - s0) / 2, thick / 2)
    p.z0, p.z1 = za, zb
    parts[#parts + 1] = p
  end
  if dw and dw < L - 2 then
    local d0, d1 = (L - dw) / 2, (L + dw) / 2
    seg(0, d0, z0, z1); seg(d1, L, z0, z1); seg(d0, d1, z0 + dh, z1)
  else
    seg(0, L, z0, z1)
  end
  return parts
end

-- The ship: { x, y, length, beam, draft, freeboard, angle (of its length,
-- from east), seaward = +1 or -1 (which side the leak is on, to the left
-- of the length's direction for +1) }.
local function layShip(W, s)
  local a = s.angle or 0
  local ux, uy = cos(a), sin(a)
  local vx, vy = -uy, ux
  local hull = B.rectPart(s.x, s.y, ux, uy, s.length / 2, s.beam / 2)
  hull.z0, hull.z1, hull.color = -s.draft, s.freeboard, "#5a2a26"
  local bx, by = s.x - ux * (s.length / 2 - 12), s.y - uy * (s.length / 2 - 12)
  local house = B.rectPart(bx, by, ux, uy, 9, s.beam / 2 - 2)
  house.z0, house.z1, house.color = s.freeboard, s.freeboard + 16, "#e8e8e4"
  newBuilding(W, { hull, house }, -s.draft, s.freeboard + 16, { "#5a2a26", "#e8e8e4", 1 }, "G", "ship", "ship")
  local side = s.seaward or 1
  W.leak = { x = s.x + vx * side * (s.beam / 2 + 0.5), y = s.y + vy * side * (s.beam / 2 + 0.5), z = 0 }
  W:region("leak", W.leak.x, W.leak.y)
  W:region("ship", s.x - s.length / 2, s.y - s.beam / 2, s.x + s.length / 2, s.y + s.beam / 2)
end

-- A pier: { from = { x, y }, to = { x, y }, width }: the deck at 2.5-3.5 m
-- and piles every 8 m along both edges, down to the ground.
local function layPier(W, p)
  local t = W.terrain
  local dx, dy = p.to[1] - p.from[1], p.to[2] - p.from[2]
  local L = sqrt(dx * dx + dy * dy)
  local ux, uy = dx / L, dy / L
  local vx, vy = -uy, ux
  local deck = B.rectPart((p.from[1] + p.to[1]) / 2, (p.from[2] + p.to[2]) / 2, ux, uy, L / 2, p.width / 2)
  deck.z0, deck.z1 = 2.5, 3.5
  local parts = { deck }
  for s = 4, L - 4, 8 do
    for _, side in ipairs({ -1, 1 }) do
      local x = p.from[1] + ux * s + vx * side * (p.width / 2 - 0.5)
      local y = p.from[2] + uy * s + vy * side * (p.width / 2 - 0.5)
      local pile = B.discPart(x, y, 0.3)
      pile.z0, pile.z1 = t:ground(x, y) - 0.5, 2.5
      parts[#parts + 1] = pile
    end
  end
  newBuilding(W, parts, -30, 3.5, { "#8a7a66", "#9c8b74", 1 }, "G", "pier", "pier")
end

-- The k largest buildings of a zone, largest first (deterministic: by
-- area, then position).
local function largest(W, zone, k, kind)
  local list = {}
  for _, b in ipairs(W.buildings) do
    if b.zone == zone and not b.kind and #b.parts == 1 and b.parts[1].kind == "rect" then list[#list + 1] = b end
  end
  table.sort(list, function(a, c)
    local pa, pc = a.parts[1], c.parts[1]
    local aa, ac = pa.hu * pa.hv, pc.hu * pc.hv
    if aa ~= ac then return aa > ac end
    return pa.x + pa.y * 1e-3 < pc.x + pc.y * 1e-3
  end)
  local out = {}
  for i = 1, min(k, #list) do out[i] = list[i] end
  return out
end

-- Warehouses: the k largest sheds of `zone` become shells with doorways.
local function layWarehouses(W, zone, k)
  for _, b in ipairs(largest(W, zone, k)) do
    local p = b.parts[1]
    local c = p.c
    local z0, z1 = b.base, b.top
    local parts = {}
    for q = 1, 7, 2 do
      local q2 = (q + 1) % 8 + 1
      -- each door 5 m high over the ground at the door (the walls start
      -- 0.3 m under the lowest ground, and a site may slope)
      local gd = W.terrain:ground((c[q] + c[q2]) / 2, (c[q + 1] + c[q2 + 1]) / 2)
      for _, w in ipairs(wallParts(c[q], c[q + 1], c[q2], c[q2 + 1], 0.4, z0, z1, 6, gd + 5 - z0)) do
        parts[#parts + 1] = w
      end
    end
    local roof = B.rectPart(p.x, p.y, p.ux, p.uy, p.hu, p.hv)
    roof.z0, roof.z1 = z1 - 0.5, z1
    parts[#parts + 1] = roof
    b.parts, b.kind = parts, "warehouse"
    W.warehouses = W.warehouses or {}
    W.warehouses[#W.warehouses + 1] = b
  end
end

-- A container yard on the largest lot of `zone`: its buildings removed,
-- then blocks of stacks over the lot's buildable area.
local function layYard(W, zone, s)
  local lot
  for _, l in ipairs(W.lots) do
    if l.zone == zone and (not lot or l.hu * l.hv > lot.hu * lot.hv) then lot = l end
  end
  if not lot then return end
  -- remove the lot's buildings
  local keep = {}
  for _, b in ipairs(W.buildings) do
    local p = b.parts[1]
    local dx, dy = p.x - lot.x, p.y - lot.y
    local inside = abs(dx * lot.ux + dy * lot.uy) <= lot.hu and abs(-dx * lot.uy + dy * lot.ux) <= lot.hv
    if not (inside and not b.kind) then keep[#keep + 1] = b end
  end
  W.buildings = keep
  local T = B.TYPES[zone]
  local L, Wd, H = F.TEU[1], F.TEU[2], F.TEU[3]
  local lane = 15
  local u0, u1 = -lot.hu + T.side + 2, lot.hu - T.side - 2
  local v0, v1 = -lot.hv + T.front + 2, lot.hv - T.rear - 2
  local ux, uy, vx, vy = lot.ux, lot.uy, -lot.uy, lot.ux
  local nbay = min(20, floor((u1 - u0) / L))
  local blockLen, blockWid = nbay * L, 6 * Wd
  local colours = { "#b03a2e", "#2e5fa8", "#2f8a4c", "#d07a26", "#8a8a8a", "#c9b02a" }
  local yard = { blocks = 0, stacks = 0, pockets = 0 }
  local u = u0
  while u + L * 4 <= u1 do
    local nb = min(nbay, floor((u1 - u) / L))
    local v = v0
    while v + blockWid <= v1 do
      yard.blocks = yard.blocks + 1
      -- two pockets: a bay emptied 2-4 rows deep from one long side
      local pockets = {}
      for _ = 1, 2 do
        local bay = 2 + floor(s:random() * max(1, nb - 3))
        local depth = 2 + floor(s:random() * 3)
        local fromLow = s:random() < 0.5
        pockets[#pockets + 1] = { bay = bay, depth = depth, low = fromLow }
      end
      yard.pockets = yard.pockets + #pockets
      for bay = 1, nb do
        for row = 1, 6 do
          local empty = false
          for _, pk in ipairs(pockets) do
            if bay == pk.bay and ((pk.low and row <= pk.depth) or (not pk.low and row > 6 - pk.depth)) then empty = true end
          end
          if not empty then
            local n = ({ 1, 2, 2, 3, 3, 3, 4, 4, 4, 5 })[1 + floor(s:random() * 10)]
            local cu, cv = u + (bay - 0.5) * L, v + (row - 0.5) * Wd
            local x, y = lot.x + ux * cu + vx * cv, lot.y + uy * cu + vy * cv
            local p = B.rectPart(x, y, ux, uy, L / 2, Wd / 2)
            local g = W.terrain:ground(x, y)
            local col = colours[1 + floor(s:random() * #colours)]
            p.z0, p.z1, p.color = g - 0.2, g + n * H, col
            newBuilding(W, { p }, g - 0.2, g + n * H, { col, col, 1 }, zone, "building", "container")
            yard.stacks = yard.stacks + 1
          end
        end
      end
      v = v + blockWid + lane
    end
    u = u + nb * L + lane
  end
  yard.lot = lot
  W.yard = yard
end

-- The storm drain: { pts = { x1, y1, ... } } from inland to the shore; the
-- last point is moved to where the line first reaches water (the outfall).
local function layDrain(W, d)
  local t = W.terrain
  local p = d.pts
  -- dense samples along the line, cut at the water
  local S = {}
  for q = 1, #p - 3, 2 do
    local dx, dy = p[q + 2] - p[q], p[q + 3] - p[q + 1]
    local n = math.ceil(sqrt(dx * dx + dy * dy) / 5)
    for i = 0, n - 1 do S[#S + 1] = { p[q] + dx * i / n, p[q + 1] + dy * i / n } end
  end
  S[#S + 1] = { p[#p - 1], p[#p] }
  local last = #S
  for i, sp in ipairs(S) do if t:water(sp[1], sp[2]) then last = i - 1; break end end
  local pts, inv, acc, cum = {}, {}, 0, {}
  for i = 1, last do
    if i > 1 then acc = acc + sqrt((S[i][1] - S[i - 1][1]) ^ 2 + (S[i][2] - S[i - 1][2]) ^ 2) end
    cum[i] = acc
  end
  local w, h = F.CULVERT[1], F.CULVERT[2]
  local zA = t:ground(S[1][1], S[1][2]) - F.COVER - h - 2
  local zB = 0.5
  local run = math.huge
  for i = 1, last do
    pts[#pts + 1] = S[i][1]; pts[#pts + 1] = S[i][2]
    local lin = zA + (zB - zA) * cum[i] / acc
    local z = min(lin, t:ground(S[i][1], S[i][2]) - F.COVER - h)
    run = min(run, z)                              -- never rising downstream
    inv[i] = run
  end
  -- below sea level the culvert is flooded (a tide-locked outfall)
  local flooded = 0
  for i = 2, last do
    if inv[i] < 0 then flooded = flooded + (cum[i] - cum[i - 1]) end
  end
  local drain = { pts = pts, inv = inv, w = w, h = h, length = acc, flooded = flooded }
  W.tunnels = W.tunnels or {}
  W.tunnels[#W.tunnels + 1] = drain
  -- the headwall: a concrete wall across the outfall with the culvert's
  -- opening in it, 1 m thick, from the invert to 0.5 m over the ground
  local n = last
  local ex, ey = S[n][1], S[n][2]
  local dx, dy = S[n][1] - S[n - 1][1], S[n][2] - S[n - 1][2]
  local L = sqrt(dx * dx + dy * dy)
  local ux, uy = dx / L, dy / L
  local vx, vy = -uy, ux
  local top = t:ground(ex, ey) + 0.5
  local z0 = inv[n] - 0.5
  local parts = wallParts(ex - vx * (w / 2 + 2), ey - vy * (w / 2 + 2), ex + vx * (w / 2 + 2), ey + vy * (w / 2 + 2),
                          1, z0, top, w, h + 0.5)
  newBuilding(W, parts, z0, top, { "#a8a49c", "#bdb9b0", 1 }, "E", "building", "outfall")
  W:region("outfall", ex, ey)
  -- manholes every 60 m (drawn; access shafts are not modelled)
  drain.manholes = {}
  for i = 1, last, 12 do drain.manholes[#drain.manholes + 1] = { S[i][1], S[i][2] } end
end

-- Is the point (x, y, z) inside a tunnel? (for World:blockedAt)
function F.inTunnel(W, x, y, z)
  for _, d in ipairs(W.tunnels or {}) do
    local p = d.pts
    for q = 1, #p - 3, 2 do
      local ax, ay, bx, by = p[q], p[q + 1], p[q + 2], p[q + 3]
      local dx, dy = bx - ax, by - ay
      local L2 = dx * dx + dy * dy
      local f = L2 > 0 and max(0, min(1, ((x - ax) * dx + (y - ay) * dy) / L2)) or 0
      local qx, qy = ax + f * dx - x, ay + f * dy - y
      if qx * qx + qy * qy <= (d.w / 2) ^ 2 then
        local k = (q + 1) / 2
        local zi = d.inv[k] + f * (d.inv[k + 1] - d.inv[k])
        if z >= zi and z <= zi + d.h then return true end
      end
    end
  end
  return false
end

-- A launch pad: the nearest 30 x 30 m square (axis-aligned) to (x, y),
-- searched outward every 10 m, that is dry, level (ground within 1.5 m
-- across it) and clear of buildings and streets.
local function layPad(W, name, x, y)
  local t, town = W.terrain, W.town
  local h = F.PAD / 2
  local function clear(cx, cy)
    local b = W.bounds
    if cx - h < b.x0 or cx + h > b.x1 or cy - h < b.y0 or cy + h > b.y1 then return false end
    local lo, hi = math.huge, -math.huge
    for i = -3, 3 do
      for j = -3, 3 do
        local px, py = cx + i * h / 3, cy + j * h / 3
        if t:water(px, py) then return false end
        local g = t:ground(px, py)
        lo, hi = min(lo, g), max(hi, g)
      end
    end
    if hi - lo > 1.5 then return false end
    local box = B.rectPart(cx, cy, 1, 0, h, h)
    if town:near(cx - h - 20, cy - h - 20, cx + h + 20, cy + h + 20, function(st, ax, ay, bx2, by2)
      if not ax then return B.segRectDist(box, st.bulb[1], st.bulb[2], st.bulb[1], st.bulb[2]) < st.bulb[3] + 1 end
      return B.segRectDist(box, ax, ay, bx2, by2) < st.width / 2 + 1
    end) then return false end
    for _, b in ipairs(W.buildings) do
      for _, p in ipairs(b.parts) do
        if B.partDist(box, p) < 3 then return false end
      end
    end
    return true
  end
  for r = 0, 600, 10 do
    local steps = r == 0 and 1 or floor(2 * math.pi * r / 10)
    for k = 0, steps - 1 do
      local a = 2 * math.pi * k / steps
      local cx, cy = x + r * cos(a), y + r * sin(a)
      if clear(cx, cy) then
        W:region(name, cx - h, cy - h, cx + h, cy + h)
        W.pads = W.pads or {}
        W.pads[#W.pads + 1] = { name = name, x = cx, y = cy, z = t:ground(cx, cy), size = F.PAD }
        return true
      end
    end
  end
  return false
end

-- spec.features = { ship = {...}, piers = { ... } or function(terrain),
--   warehouses = { zone, count }, yard = { zone }, drain = { pts } or
--   function(terrain), pads = { { x, y }, ... } }
function F.build(W, spec)
  local f = spec.features
  if not f then return end
  local s = rng.new((spec.seed or 1) + 3000)
  if f.yard then layYard(W, f.yard.zone, s) end
  if f.warehouses then layWarehouses(W, f.warehouses.zone, f.warehouses.count) end
  if f.ship then layShip(W, f.ship) end
  local piers = f.piers
  if type(piers) == "function" then piers = piers(W.terrain) end
  for _, p in ipairs(piers or {}) do layPier(W, p) end
  local drain = f.drain
  if type(drain) == "function" then drain = drain(W.terrain) end
  if drain then layDrain(W, drain) end
  local pads = f.pads
  if type(pads) == "function" then pads = pads(W.terrain) end
  for i, p in ipairs(pads or {}) do layPad(W, "pad" .. i, p[1], p[2]) end
end

-- The pads (pale concrete with a dark H) and the drain's manholes (dark
-- discs on the ground), as one mesh; the rest of the features are
-- buildings (lib/buildings.lua draws them).
function F.toBPP(W, viewer, opts)
  opts = opts or {}
  local S, base = opts.scale or 1, opts.base or 0
  local t = W.terrain
  local mesh = Terrain()
  local cols, n = {}, 0
  local function P(x, y, h) return btVector3(x * S, base + h * S, -y * S) end
  local function quad(x0, y0, x1, y1, z, col)
    mesh:addTriangle(P(x0, y0, z), P(x1, y0, z), P(x1, y1, z)); cols[n] = col; n = n + 1
    mesh:addTriangle(P(x0, y0, z), P(x1, y1, z), P(x0, y1, z)); cols[n] = col; n = n + 1
  end
  for _, pad in ipairs(W.pads or {}) do
    local h, z = pad.size / 2, pad.z + 0.4
    quad(pad.x - h, pad.y - h, pad.x + h, pad.y + h, z, { 200, 198, 190 })
    local a, w = 0.3 * h, 0.08 * pad.size
    quad(pad.x - a - w / 2, pad.y - a, pad.x - a + w / 2, pad.y + a, z + 0.02, { 50, 50, 54 })
    quad(pad.x + a - w / 2, pad.y - a, pad.x + a + w / 2, pad.y + a, z + 0.02, { 50, 50, 54 })
    quad(pad.x - a, pad.y - w / 2, pad.x + a, pad.y + w / 2, z + 0.02, { 50, 50, 54 })
  end
  if W.leak then                                   -- a red marker, 2 m across, at the leak
    local L = W.leak
    local top, bot = { L.x, L.y, L.z + 2 }, { L.x, L.y, L.z - 2 }
    for k = 0, 3 do
      local a0, a1 = k * math.pi / 2, (k + 1) * math.pi / 2
      local x0, y0 = L.x + 1.5 * cos(a0), L.y + 1.5 * sin(a0)
      local x1, y1 = L.x + 1.5 * cos(a1), L.y + 1.5 * sin(a1)
      mesh:addTriangle(P(x0, y0, L.z), P(x1, y1, L.z), P(top[1], top[2], top[3])); cols[n] = { 230, 30, 30 }; n = n + 1
      mesh:addTriangle(P(x1, y1, L.z), P(x0, y0, L.z), P(bot[1], bot[2], bot[3])); cols[n] = { 230, 30, 30 }; n = n + 1
    end
  end
  for _, d in ipairs(W.tunnels or {}) do
    for _, m in ipairs(d.manholes) do
      local z = t:ground(m[1], m[2]) + 0.35
      for k = 0, 7 do
        local a0, a1 = k * math.pi / 4, (k + 1) * math.pi / 4
        mesh:addTriangle(P(m[1], m[2], z), P(m[1] + 0.8 * cos(a0), m[2] + 0.8 * sin(a0), z),
                         P(m[1] + 0.8 * cos(a1), m[2] + 0.8 * sin(a1), z))
        cols[n] = { 30, 30, 32 }; n = n + 1
      end
    end
  end
  if n == 0 then return nil end
  mesh:build()
  mesh.col = "#c8c6be"
  for i = 0, n - 1 do mesh:setTriangleColor(i, cols[i][1], cols[i][2], cols[i][3]) end
  viewer:add(mesh)
  pcall(function() mesh.body:setCollisionFlags(1 + 4) end)
  return mesh
end

return F
