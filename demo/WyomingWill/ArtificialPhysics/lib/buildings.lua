--
-- lib/buildings.lua -- the world generator's lots and buildings (BOOK.md
-- G21, §6)
--
-- The third realistic layer, on a preset's zones and streets
-- (lib/town.lua):
--
--   LOTS       frontage first: along each side of each street, lots one
--              after another, as wide as the zone's frontage and as deep
--              as its lot depth, turned to the street; a lot that would
--              cross a street, water, the edge or an earlier lot is made
--              as deep as fits (bisection, down to the setbacks plus 6 m),
--              or skipped. Each cul-de-sac also gets a lot at its head,
--              beyond the turning circle.
--   BUILDINGS  one per lot (a farmstead has three), inside the setbacks:
--              a rectangle, L, T or U footprint, or for heavy industry
--              sometimes a row of tanks; whole floors FLOOR high, drawn
--              from a lognormal (heavy tail), clamped to the zone's range;
--              sheds and tanks have heights, not floors.
--   GAPS       two buildings either touch (the gap is closed, as party
--              walls are) or leave at least MIN_GAP: the Android app's
--              rule that gaps fit an agent or are closed. A building that
--              breaks it is made shallower (85%, 70%), then narrower too,
--              then left out. Compact zones' rear setback is MIN_GAP / 2,
--              so lots meeting back to back leave exactly MIN_GAP.
--
-- Each built zone's numbers are in TYPES, calibrated so that the measured
-- building fraction and mean height fall inside the zone's published
-- ranges (Stewart and Oke 2012; lib/town.lua's Town.LCZ, checks/
-- buildings.lua).
--
-- UNITS AND AXES: metres; x east, y north. A lot's u axis runs along its
-- street, v into the lot from the street's edge.
--
-- DEFINITIONS:
--   building fraction  share of a zone's plan area under buildings
--                      (Stewart and Oke's "building surface fraction")
--   height             roof above the highest ground under the building;
--                      floors x FLOOR for floored buildings
--   mean height        over a zone's buildings, each counted once
--   gap                shortest distance between two buildings' footprints
--
-- FIXED CONSTANTS (stated, not knobs):
--   FLOOR 3.5 m     floor to floor (Schlapfer et al. 2015: one-storey
--                   buildings peak at 3.5 m, two-storey at 6.5 m)
--   MIN_GAP 3 m     the narrowest gap left open: two 1.5 m (5 ft) side
--                   setbacks, the smallest in common US codes; anything
--                   narrower is closed
--   SAGITTA 1 m     how far a lot's own (curved) street may cut its front
--                   corners
--
-- RANDOMNESS: its own stream, rng.new(seed + 2000).
--

local rng = require "lib.rng"

local B = {}

local floor, sqrt, abs, min, max, cos, sin, exp, log, pi = math.floor, math.sqrt, math.abs, math.min,
  math.max, math.cos, math.sin, math.exp, math.log, math.pi

local atan2 = math.atan2 or function(y, x) return math.atan(y, x) end -- Lua 5.3+ dropped atan2

B.FLOOR = 3.5
B.MIN_GAP = 3
B.SAGITTA = 1

-- Per built zone: frontage (m, uniform), depth (m), setbacks front, side,
-- rear (m); footprint as fractions of the buildable width and depth;
-- floors (lognormal median, sigma, min, max) or height = { min, max } m;
-- shapes and their weights; colours (walls, roof). LCZ 4 and 7 are not
-- used by any preset and have no type. "farm" is a farmstead on open land
-- (zone D) along rural roads, one every 400-900 m.
B.TYPES = {
  ["1"] = { frontage = { 30, 60 }, depth = 40, front = 0, side = 0, rear = 1.5, fw = { 1, 1 }, fd = { 0.9, 1 },
            floors = { 14, 0.5, 8, 60 }, shapes = { rect = 6, L = 2, U = 2 }, walls = "#8ea2b4", roof = "#5f6b76" },
  ["2"] = { frontage = { 12, 35 }, depth = 40, front = 0, side = 0, rear = 1.5, fw = { 1, 1 }, fd = { 0.9, 1 },
            floors = { 5, 0.35, 3, 9 }, shapes = { rect = 6, L = 2, U = 1 }, walls = "#a7785a", roof = "#6e5446" },
  ["3"] = { frontage = { 7, 15 }, depth = 38, front = 0, side = 0, rear = 1.5, fw = { 1, 1 }, fd = { 0.9, 1 },
            floors = { 2, 0.3, 1, 3 }, shapes = { rect = 6, L = 4 }, walls = "#c9a982", roof = "#7a4e3c" },
  ["5"] = { frontage = { 30, 60 }, depth = 31, front = 3, side = 4, rear = 3, fw = { 0.75, 0.95 }, fd = { 0.7, 1 },
            floors = { 5, 0.3, 3, 9 }, shapes = { rect = 5, L = 3, T = 2 }, walls = "#c4bdb0", roof = "#6f6a64" },
  ["6"] = { frontage = { 15, 24 }, depth = 32, front = 4, side = 1.5, rear = 4, fw = { 0.9, 1 }, fd = { 0.9, 1 },
            floors = { 1.5, 0.35, 1, 2 }, shapes = { rect = 5, L = 4, T = 1 }, walls = "#ddd1bb", roof = "#8c5a45" },
  ["8"] = { frontage = { 60, 150 }, depth = 120, front = 8, side = 6, rear = 6, fw = { 0.8, 1 }, fd = { 0.75, 0.95 },
            height = { 6, 10 }, shapes = { rect = 1 }, walls = "#c3c4c6", roof = "#9a9ca0" },
  ["9"] = { frontage = { 25, 45 }, depth = 40, front = 8, side = 3, rear = 8, fw = { 0.65, 0.95 }, fd = { 0.65, 0.95 },
            floors = { 1.5, 0.35, 1, 2 }, shapes = { rect = 5, L = 4, T = 1 }, walls = "#ddd1bb", roof = "#8c5a45" },
  ["10"] = { frontage = { 60, 140 }, depth = 110, front = 12, side = 8, rear = 10, fw = { 0.75, 0.95 }, fd = { 0.65, 0.9 },
             height = { 6, 14 }, tanks = 0.3, shapes = { rect = 1 }, walls = "#b0aa9e", roof = "#7f7a70" },
  farm = { frontage = { 70, 90 }, depth = 80, front = 25, side = 5, rear = 5, every = { 400, 900 },
           walls = "#d8c9a8", roof = "#7b3f30" },
}

--------------------------------------------------------------------------
-- Geometry: oriented rectangles and discs
--------------------------------------------------------------------------

-- A rectangle part: centre, unit axis (ux, uy), half sizes hu (along u)
-- and hv (along v = (-uy, ux)).
local function rectPart(cx, cy, ux, uy, hu, hv)
  local vx, vy = -uy, ux
  return { kind = "rect", x = cx, y = cy, ux = ux, uy = uy, hu = hu, hv = hv,
           c = { cx + ux * hu + vx * hv, cy + uy * hu + vy * hv, cx - ux * hu + vx * hv, cy - uy * hu + vy * hv,
                 cx - ux * hu - vx * hv, cy - uy * hu - vy * hv, cx + ux * hu - vx * hv, cy + uy * hu - vy * hv } }
end

local function discPart(x, y, r) return { kind = "disc", x = x, y = y, r = r } end

local function segDist(px, py, ax, ay, bx, by)
  local dx, dy = bx - ax, by - ay
  local L2 = dx * dx + dy * dy
  local t = L2 > 0 and max(0, min(1, ((px - ax) * dx + (py - ay) * dy) / L2)) or 0
  local qx, qy = ax + t * dx - px, ay + t * dy - py
  return sqrt(qx * qx + qy * qy)
end

local function inRect(p, x, y, inset)
  local dx, dy = x - p.x, y - p.y
  return abs(dx * p.ux + dy * p.uy) <= p.hu - (inset or 0) and abs(-dx * p.uy + dy * p.ux) <= p.hv - (inset or 0)
end

-- Do two rectangles overlap by more than `inset` (separating axes)?
local function rectsOverlap(a, b, inset)
  inset = inset or 0
  local ac, bc = a.c, b.c
  -- the four axes, in the same order as before: a's u, a's v, b's u, b's v
  for n = 1, 4 do
    local R = n <= 2 and a or b
    local x, y
    if n % 2 == 1 then x, y = R.ux, R.uy else x, y = -R.uy, R.ux end
    local amin, amax, bmin, bmax = math.huge, -math.huge, math.huge, -math.huge
    for k = 1, 7, 2 do
      local pa = ac[k] * x + ac[k + 1] * y
      local pb = bc[k] * x + bc[k + 1] * y
      amin, amax, bmin, bmax = min(amin, pa), max(amax, pa), min(bmin, pb), max(bmax, pb)
    end
    if amax - inset <= bmin or bmax - inset <= amin then return false end
  end
  return true
end

-- Shortest distance between two parts' footprints (0 if they touch or
-- overlap).
local function partDist(a, b)
  if a.kind == "disc" and b.kind == "disc" then
    return max(0, sqrt((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2) - a.r - b.r)
  end
  if a.kind == "disc" then a, b = b, a end
  if b.kind == "disc" then                       -- rectangle a, disc b
    if inRect(a, b.x, b.y) then return 0 end
    local d = math.huge
    for k = 1, 7, 2 do
      local k2 = (k + 1) % 8 + 1
      d = min(d, segDist(b.x, b.y, a.c[k], a.c[k + 1], a.c[k2], a.c[k2 + 1]))
    end
    return max(0, d - b.r)
  end
  if rectsOverlap(a, b, 0) then return 0 end
  local d = math.huge
  for _, P in ipairs({ { a, b }, { b, a } }) do
    local p, q = P[1], P[2]
    for k = 1, 7, 2 do
      for m = 1, 7, 2 do
        local m2 = (m + 1) % 8 + 1
        d = min(d, segDist(p.c[k], p.c[k + 1], q.c[m], q.c[m + 1], q.c[m2], q.c[m2 + 1]))
      end
    end
  end
  return d
end
B.partDist = partDist

local function partBox(p)
  if p.kind == "disc" then return p.x - p.r, p.y - p.r, p.x + p.r, p.y + p.r end
  local c = p.c
  return min(c[1], c[3], c[5], c[7]), min(c[2], c[4], c[6], c[8]), max(c[1], c[3], c[5], c[7]), max(c[2], c[4], c[6], c[8])
end

local function partArea(p) return p.kind == "disc" and pi * p.r * p.r or 4 * p.hu * p.hv end

-- A bucket index of parts (or lots), 50 m buckets.
local BUCKET = 50
local function newIndex() return {} end
local function indexAdd(idx, item, x0, y0, x1, y1)
  for i = floor(x0 / BUCKET), floor(x1 / BUCKET) do
    for j = floor(y0 / BUCKET), floor(y1 / BUCKET) do
      local k = i * 100003 + j
      idx[k] = idx[k] or {}
      local l = idx[k]
      l[#l + 1] = item
    end
  end
end
local function indexNear(idx, x0, y0, x1, y1, fn)
  local seen = {}
  for i = floor(x0 / BUCKET), floor(x1 / BUCKET) do
    for j = floor(y0 / BUCKET), floor(y1 / BUCKET) do
      local l = idx[i * 100003 + j]
      if l then
        for _, it in ipairs(l) do
          if not seen[it] then seen[it] = true; if fn(it) then return true end end
        end
      end
    end
  end
  return false
end

--------------------------------------------------------------------------
-- Lots
--------------------------------------------------------------------------

-- Distance from the segment (ax, ay)-(bx, by) to a rectangle part (0 if
-- they meet): in the rectangle's own axes, the segment against the box.
local function segRectDist(R, ax, ay, bx, by)
  -- (written without tables or closures: it is the generator's innermost
  -- test; the arithmetic is the same, so the results are the same bits)
  local Rx, Ry, Rux, Ruy, hu, hv = R.x, R.y, R.ux, R.uy, R.hu, R.hv
  local dx, dy = ax - Rx, ay - Ry
  local u0, v0 = dx * Rux + dy * Ruy, -dx * Ruy + dy * Rux
  dx, dy = bx - Rx, by - Ry
  local u1, v1 = dx * Rux + dy * Ruy, -dx * Ruy + dy * Rux
  -- does the segment cross the box? (clip it, Liang-Barsky)
  local t0, t1 = 0, 1
  local du, dv = u1 - u0, v1 - v0
  local crosses = true
  for c = 1, 4 do
    local p, q
    if c == 1 then p, q = -du, u0 + hu
    elseif c == 2 then p, q = du, hu - u0
    elseif c == 3 then p, q = -dv, v0 + hv
    else p, q = dv, hv - v0 end
    if p == 0 then
      if q < 0 then crosses = false; break end
    else
      local r = q / p
      if p < 0 then if r > t1 then crosses = false; break elseif r > t0 then t0 = r end
      else if r < t0 then crosses = false; break elseif r < t1 then t1 = r end end
    end
  end
  if crosses then return 0 end
  local qu, qv = max(abs(u0) - hu, 0), max(abs(v0) - hv, 0)
  local d = sqrt(qu * qu + qv * qv)
  qu, qv = max(abs(u1) - hu, 0), max(abs(v1) - hv, 0)
  d = min(d, sqrt(qu * qu + qv * qv))
  local c = R.c
  for k = 1, 7, 2 do d = min(d, segDist(c[k], c[k + 1], ax, ay, bx, by)) end
  return d
end

-- wetCounter(t)(x0, y0, x1, y1): is any node wet (t.wl) among those that
-- are the nearest node (t:water's rounding) of some point in the box? A
-- table of running counts of wet nodes answers it in four lookups.
local function wetCounter(t)
  local nx, ny, wl = t.nx, t.ny, t.wl
  local W1 = nx + 2
  local C = {}                                    -- C[j * W1 + i]: wet nodes in [0, i) x [0, j)
  for i = 0, nx + 1 do C[i] = 0 end
  for j = 0, ny do
    local run = 0
    C[(j + 1) * W1] = 0
    for i = 0, nx do
      if wl[j * t.stride + i + 1] then run = run + 1 end
      C[(j + 1) * W1 + i + 1] = C[j * W1 + i + 1] + run
    end
  end
  return function(x0, y0, x1, y1)
    local i0 = max(0, floor((x0 - t.x0) / t.cell + 0.5))
    local j0 = max(0, floor((y0 - t.y0) / t.cell + 0.5))
    local i1 = min(nx, floor((x1 - t.x0) / t.cell + 0.5))
    local j1 = min(ny, floor((y1 - t.y0) / t.cell + 0.5))
    if i0 > i1 or j0 > j1 then return false end
    return C[(j1 + 1) * W1 + i1 + 1] - C[j0 * W1 + i1 + 1] - C[(j1 + 1) * W1 + i0] + C[j0 * W1 + i0] > 0
  end
end

-- Does the lot (a rectangle part) fit: inside the area, its zone the
-- lot's type, dry (sampled every half terrain cell, to its edges), clear
-- of every street's right of way and turning circle, and not overlapping
-- an earlier lot? Exact against the streets, except that its own street
-- may cut its front corners by up to SAGITTA: a rectangle set on a
-- curve's tangent meets the curve's edge w^2 / 8 rho short of its corners
-- (0.7 m for a 24 m lot on our collectors' tightest bends, rho ~ 100 m).
local function lotFits(W, lot, zone, own)
  local town, t = W.town, W.terrain
  local b = W.bounds
  local c = lot.c
  for k = 1, 7, 2 do
    if c[k] < b.x0 or c[k] > b.x1 or c[k + 1] < b.y0 or c[k + 1] > b.y1 then return false end
  end
  if town:zone(lot.x, lot.y) ~= zone then return false end
  local nu, nv = math.ceil(4 * lot.hu / t.cell), math.ceil(4 * lot.hv / t.cell)
  -- (t:water looks at the node nearest each point: with no wet node among
  -- those nearest any point of the lot's box, every sample is dry)
  local bx0, by0, bx1, by1 = partBox(lot)
  if W._wet and not W._wet(bx0, by0, bx1, by1) then nu, nv = -1, -1 end
  for a = 0, nu do
    for e = 0, nv do
      local fu, fv = (a / nu * 2 - 1) * lot.hu, (e / nv * 2 - 1) * lot.hv
      if t:water(lot.x + lot.ux * fu - lot.uy * fv, lot.y + lot.uy * fu + lot.ux * fv) then return false end
    end
  end
  local x0, y0, x1, y1 = partBox(lot)
  -- (a segment whose bounding box is farther from the lot's than the
  -- clearance cannot be nearer the lot itself: skipped without the exact
  -- test, which would say the same; 1e-6 m covers rounding)
  local function far(sx0, sy0, sx1, sy1, r)
    local gx = max(0, sx0 - x1, x0 - sx1)
    local gy = max(0, sy0 - y1, y0 - sy1)
    return gx * gx + gy * gy > (r + 1e-6) * (r + 1e-6)
  end
  local hit = town:near(x0 - 20, y0 - 20, x1 + 20, y1 + 20, function(st, ax, ay, bx, by)
    if ax then
      local r = st.width / 2 - (st == own and B.SAGITTA or 1e-6)
      if r > 0 and far(min(ax, bx), min(ay, by), max(ax, bx), max(ay, by), r) then return false end
      return segRectDist(lot, ax, ay, bx, by) < r
    end
    local bl = st.bulb
    local r = bl[3] - 1e-6
    if r > 0 and far(bl[1], bl[2], bl[1], bl[2], r) then return false end
    return segRectDist(lot, bl[1], bl[2], bl[1], bl[2]) < r
  end)
  if hit then return false end
  return not indexNear(W.lotIndex, x0, y0, x1, y1, function(o)
    -- (rectangles whose bounding boxes are apart are apart too)
    local ox0, oy0, ox1, oy1 = partBox(o)
    if ox0 > x1 or ox1 < x0 or oy0 > y1 or oy1 < y0 then return false end
    return rectsOverlap(lot, o, 0.05)
  end)
end

-- Points and tangents along a polyline: returns a function s -> x, y, ux, uy
-- and the length.
local function walker(p)
  local cum = { 0 }
  for q = 1, #p - 3, 2 do cum[#cum + 1] = cum[#cum] + sqrt((p[q + 2] - p[q]) ^ 2 + (p[q + 3] - p[q + 1]) ^ 2) end
  local L = cum[#cum]
  return function(s)
    local k = 1
    while k < #cum - 1 and cum[k + 1] < s do k = k + 1 end
    local q = 2 * k - 1
    local seg = cum[k + 1] - cum[k]
    local f = seg > 0 and (s - cum[k]) / seg or 0
    local dx, dy = p[q + 2] - p[q], p[q + 3] - p[q + 1]
    local len = sqrt(dx * dx + dy * dy)
    if len == 0 then len = 1 end
    return p[q] + f * dx, p[q + 1] + f * dy, dx / len, dy / len
  end, L
end

--------------------------------------------------------------------------
-- Buildings
--------------------------------------------------------------------------

local function pick(s, weights)
  local total = 0
  for _, w in pairs(weights) do total = total + w end
  local r, names = s:random() * total, {}
  for k in pairs(weights) do names[#names + 1] = k end
  table.sort(names)                               -- the same order on every Lua
  for _, k in ipairs(names) do
    r = r - weights[k]
    if r <= 0 then return k end
  end
  return names[#names]
end

-- The parts of a footprint W wide (along u) and D deep (along v), its
-- front edge centred at (fx, fy) facing the street (v points away from
-- it). Shapes: rect; L (a front bar 60% deep, one side wing full depth);
-- T (a front bar 45% deep, a middle stem); U (a front bar 40% deep, two
-- side wings full depth, the court behind).
local function footprint(shape, fx, fy, ux, uy, W, D, flip)
  local vx, vy = -uy, ux
  local parts = {}
  local function box(u0, u1, v0, v1)
    if flip then u0, u1 = -u1, -u0 end
    local cu, cv = (u0 + u1) / 2, (v0 + v1) / 2
    parts[#parts + 1] = rectPart(fx + ux * cu + vx * cv, fy + uy * cu + vy * cv, ux, uy, (u1 - u0) / 2, (v1 - v0) / 2)
  end
  local h = W / 2
  if shape == "L" then
    box(-h, h, 0, 0.6 * D); box(-h, -h + 0.4 * W, 0.6 * D, D)
  elseif shape == "T" then
    box(-h, h, 0, 0.45 * D); box(-0.2 * W, 0.2 * W, 0.45 * D, D)
  elseif shape == "U" then
    box(-h, h, 0, 0.4 * D); box(-h, -h + 0.3 * W, 0.4 * D, D); box(h - 0.3 * W, h, 0.4 * D, D)
  else
    box(-h, h, 0, D)
  end
  return parts
end

-- Does a candidate's every part keep the gap rule with every building
-- placed so far: touching (closed) or at least MIN_GAP apart?
local function gapOK(W, parts, self)
  for _, p in ipairs(parts) do
    local x0, y0, x1, y1 = partBox(p)
    local g = B.MIN_GAP
    local bad = indexNear(W.partIndex, x0 - g, y0 - g, x1 + g, y1 + g, function(o)
      if o.building == self then return false end
      -- (bounding boxes MIN_GAP apart: the parts are too, so no breach)
      local ox0, oy0, ox1, oy1 = partBox(o)
      local gx, gy = max(0, ox0 - x1, x0 - ox1), max(0, oy0 - y1, y0 - oy1)
      if gx * gx + gy * gy > (g + 1e-6) * (g + 1e-6) then return false end
      local d = partDist(p, o)
      return d > 1e-6 and d < B.MIN_GAP
    end)
    if bad then return false end
  end
  return true
end

local function lognormalFloors(s, f)
  local n = floor(exp(log(f[1]) + f[2] * s:gauss()) + 0.5)
  return min(f[4], max(f[3], n))
end

-- Ground under a building: lowest and highest under its parts' corners
-- and centres.
local function groundRange(t, parts)
  local lo, hi = math.huge, -math.huge
  for _, p in ipairs(parts) do
    local pts = p.kind == "disc" and { p.x - p.r, p.y, p.x + p.r, p.y, p.x, p.y - p.r, p.x, p.y + p.r, p.x, p.y }
                or { p.c[1], p.c[2], p.c[3], p.c[4], p.c[5], p.c[6], p.c[7], p.c[8], p.x, p.y }
    for k = 1, #pts, 2 do
      local g = t:ground(pts[k], pts[k + 1])
      lo, hi = min(lo, g), max(hi, g)
    end
  end
  return lo, hi
end

-- Places a building (parts, its height above the highest ground, floors
-- or nil) if it keeps the gap rule; returns it or nil.
local function place(W, parts, height, floors, zone, color)
  local bld = { parts = parts, zone = zone, floors = floors, height = height, color = color }
  if not gapOK(W, parts, bld) then return nil end
  local lo, hi = groundRange(W.terrain, parts)
  bld.base, bld.top = lo - 0.3, hi + height
  for _, p in ipairs(parts) do
    p.building = bld
    indexAdd(W.partIndex, p, partBox(p))
  end
  W.buildings[#W.buildings + 1] = bld
  return bld
end

-- One lot's building(s), narrowed (85%, 70%) if the gap rule needs it.
local function buildOnLot(W, lot, T, zone, s)
  local ux, uy = lot.ux, lot.uy
  local vx, vy = -uy, ux
  -- buildable area: the lot less its setbacks
  local bw = 2 * lot.hu - 2 * T.side
  local bd = 2 * lot.hv - T.front - T.rear
  if bw < 4 or bd < 4 then return end
  -- the lot's street edge centre, and the front of the buildable area
  local ex, ey = lot.x - vx * lot.hv, lot.y - vy * lot.hv
  local fx, fy = ex + vx * T.front, ey + vy * T.front
  local tint = 0.92 + 0.16 * s:random()
  if zone == "farm" then
    -- a house by the road, a barn behind it, a shed
    local specs = { { -0.25, 0, 12, 10, 2 * B.FLOOR, 2 }, { 0.2, 0.35, 30, 16, 9 }, { -0.3, 0.6, 18, 10, 5 } }
    for _, sp in ipairs(specs) do
      local W_, D_ = min(sp[3], bw), min(sp[4], bd * 0.4)
      local cu, cv = sp[1] * bw, sp[2] * bd
      local parts = footprint("rect", fx + ux * cu + vx * cv, fy + uy * cu + vy * cv, ux, uy, W_, D_)
      place(W, parts, sp[5], sp[6], zone, { T.walls, T.roof, tint })
    end
    return
  end
  local shape = pick(s, T.shapes)
  local fw = T.fw[1] + (T.fw[2] - T.fw[1]) * s:random()
  local fd = T.fd[1] + (T.fd[2] - T.fd[1]) * s:random()
  local flip = s:random() < 0.5
  local floors, height
  if T.floors then floors = lognormalFloors(s, T.floors); height = floors * B.FLOOR
  else height = T.height[1] + (T.height[2] - T.height[1]) * s:random() end
  if T.tanks and s:random() < T.tanks then
    -- a row of tanks across the lot
    local r = min(bd / 2, 6 + 6 * s:random())
    local n = max(1, floor(bw / (2 * r + B.MIN_GAP)))
    local th = 10 + 6 * s:random()
    for k = 1, n do
      local cu = -bw / 2 + (k - 0.5) * bw / n
      local cx, cy = fx + ux * cu + vx * (r + 1), fy + uy * cu + vy * (r + 1)
      place(W, { discPart(cx, cy, r) }, th, nil, zone, { "#d4d4d0", "#bdbdb8", tint })
    end
    return
  end
  -- shallower first (a rear wall too near a neighbour's), then narrower
  for _, k in ipairs({ { 1, 1 }, { 1, 0.85 }, { 1, 0.7 }, { 0.85, 0.7 }, { 0.7, 0.7 } }) do
    local parts = footprint(shape, fx, fy, ux, uy, bw * fw * k[1], bd * fd * k[2], flip)
    if place(W, parts, height, floors, zone, { T.walls, T.roof, tint }) then return end
  end
end

-- Lays lots and buildings on a World with zones and streets (w.town).
-- Order: grid streets, arterials, collectors, locals, cul-de-sacs.
function B.build(W, seed)
  local t0 = os.clock()
  local s = rng.new((seed or 1) + 2000)
  W.lots, W.buildings = {}, {}
  W.lotIndex, W.partIndex = newIndex(), newIndex()
  W._wet = wetCounter(W.terrain)            -- (for lotFits; dropped at the end)
  local order = { grid = 1, arterial = 2, collector = 3, ["local"] = 4, culdesac = 5 }
  local streets = {}
  for _, st in ipairs(W.town.streets) do if order[st.kind] then streets[#streets + 1] = st end end
  table.sort(streets, function(a, b)
    if order[a.kind] ~= order[b.kind] then return order[a.kind] < order[b.kind] end
    return a.pts[1] + a.pts[2] * 1e-3 < b.pts[1] + b.pts[2] * 1e-3
  end)
  -- A lot whose street edge is centred at (ex, ey), u along the street,
  -- v = (-uy, ux) into the lot, wl wide: as deep as T.depth, or the
  -- deepest that fits (bisection), or nil.
  local function tryLot(ex, ey, lux, luy, wl, T, zone, st)
    local lvx, lvy = -luy, lux
    local function at(d)
      local lot = rectPart(ex + lvx * d / 2, ey + lvy * d / 2, lux, luy, wl / 2, d / 2)
      if lotFits(W, lot, zone == "farm" and "D" or zone, st) then return lot end
    end
    local lot = at(T.depth)
    if lot then return lot end
    local lo, hi = T.front + T.rear + 6, T.depth
    lot = at(lo)
    if not lot then return nil end
    for _ = 1, 5 do
      local mid = (lo + hi) / 2
      local l2 = at(mid)
      if l2 then lo, lot = mid, l2 else hi = mid end
    end
    return lot
  end
  local function keep(lot, T, zone, st)
    lot.zone, lot.street = zone, st
    W.lots[#W.lots + 1] = lot
    indexAdd(W.lotIndex, lot, partBox(lot))
    buildOnLot(W, lot, T, zone, s)
  end
  for _, st in ipairs(streets) do
    local at, L = walker(st.pts)
    for _, side in ipairs({ 1, -1 }) do
      local pos = 2 + 6 * s:random()
      while pos < L - 4 do
        local x, y, ux, uy = at(pos)
        local nx, ny = -uy * side, ux * side
        local zone = W.town:zone(x + nx * (st.width / 2 + 15), y + ny * (st.width / 2 + 15))
        if zone == "D" then zone = "farm" end
        local T = B.TYPES[zone]
        if not T or (zone == "farm" and st.kind ~= "arterial") then
          pos = pos + 10
        else
          local wl = T.frontage[1] + (T.frontage[2] - T.frontage[1]) * s:random()
          if pos + wl > L - 2 then                -- the last lot takes what is left:
            wl = L - 2 - pos                       -- 6 m will do with party walls
            if wl < (T.side == 0 and 6 or T.frontage[1]) then break end
          end
          local mx, my, mux, muy = at(pos + wl / 2)
          -- lot axes: u along the street (reversed on side -1), v into the lot
          local lux, luy = mux * side, muy * side
          local lot = tryLot(mx - luy * st.width / 2, my + lux * st.width / 2, lux, luy, wl, T, zone, st)
          if lot then
            keep(lot, T, zone, st)
            pos = pos + wl
            if T.every then pos = pos + T.every[1] + (T.every[2] - T.every[1]) * s:random() end
          else
            pos = pos + 5
          end
        end
      end
    end
    if st.bulb then
      -- the head lot: beyond the turning circle, facing back along the street
      local bx, by, r = st.bulb[1], st.bulb[2], st.bulb[3]
      local _, _, ux, uy = at(L)
      local zone = W.town:zone(bx + ux * (r + 15), by + uy * (r + 15))
      local T = B.TYPES[zone]
      if T and zone ~= "farm" then
        local wl = T.frontage[2]
        local lot = tryLot(bx + ux * r, by + uy * r, uy, -ux, wl, T, zone, st)
        if lot then keep(lot, T, zone, st) end
      end
    end
  end
  for id, bld in ipairs(W.buildings) do bld.id = id end
  W._wet = nil
  W.buildTimeBuildings = os.clock() - t0
end

-- Every building's parts as World pieces, so blocked(), blockedAt() and
-- writeCPT() see them; drawn by B.toBPP as one mesh, not piece by piece.
-- A part spans its own z0..z1 if it has them (a roof slab, a ship's hull),
-- else its building's base..top; its tag is the building's (default
-- "building"). Called once the features (lib/features.lua) are in.
function B.addPieces(W)
  for id, bld in ipairs(W.buildings) do
    bld.id = id
    for _, p in ipairs(bld.parts) do
      local z0, z1 = p.z0 or bld.base, p.z1 or bld.top
      local piece
      if p.kind == "disc" then piece = W:disc(p.x, p.y, p.r, bld.tag or "building", z1 - z0)
      else piece = W:rect(p.x, p.y, 2 * p.hu, 2 * p.hv, atan2(p.uy, p.ux), bld.tag or "building", z1 - z0) end
      piece.base, piece.inMesh, piece.building = z0, true, id
    end
  end
end

B.rectPart, B.discPart, B.rectsOverlap, B.footprint, B.partBox, B.segRectDist =
  rectPart, discPart, rectsOverlap, footprint, partBox, segRectDist

--------------------------------------------------------------------------
-- Measures
--------------------------------------------------------------------------

-- Per zone: building fraction and the share under lots (sampled on an
-- m x m grid, default 400), mean height and count of its buildings; the
-- zone's share of the area.
function B.stats(W, m)
  m = m or 400
  local b = W.bounds
  local inZone, built, inLot = {}, {}, {}
  local dx, dy = (b.x1 - b.x0) / m, (b.y1 - b.y0) / m
  for i = 0, m - 1 do
    for j = 0, m - 1 do
      local x, y = b.x0 + (i + 0.5) * dx, b.y0 + (j + 0.5) * dy
      local z = W.town:zone(x, y)
      inZone[z] = (inZone[z] or 0) + 1
      if W:blocked(x, y, "building") then built[z] = (built[z] or 0) + 1 end
      if indexNear(W.lotIndex, x, y, x, y, function(l) return inRect(l, x, y) end) then
        inLot[z] = (inLot[z] or 0) + 1
      end
    end
  end
  local out = {}
  for z, n in pairs(inZone) do
    out[z] = { share = n / (m * m), built = (built[z] or 0) / n, lots = (inLot[z] or 0) / n, n = 0, hsum = 0 }
  end
  for _, bld in ipairs(W.buildings) do
    local p = bld.parts[1]
    local z = W.town:zone(p.x, p.y)
    if out[z] then
      out[z].n = out[z].n + 1
      out[z].hsum = out[z].hsum + bld.height
    end
  end
  for _, o in pairs(out) do o.height = o.n > 0 and o.hsum / o.n or 0 end
  return out
end

--------------------------------------------------------------------------
-- BPP geometry
--------------------------------------------------------------------------

local function rgb(hex) return tonumber(hex:sub(2, 3), 16), tonumber(hex:sub(4, 5), 16), tonumber(hex:sub(6, 7), 16) end
local CF_STATIC, CF_NO_CONTACT = 1, 4

-- Every building as one mesh: walls from the base to the roof, flat roofs;
-- tanks as 16-sided prisms. Colours by type with a small tint per building.
function B.toBPP(W, viewer, opts)
  opts = opts or {}
  local S, base = opts.scale or 1, opts.base or 0
  if #W.buildings == 0 then return nil end
  local mesh = Terrain()
  local cols, n = {}, 0
  local function V(x, y, h) return btVector3(x * S, base + h * S, -y * S) end
  local function tri(a, b, c, col) mesh:addTriangle(a, b, c); cols[n] = col; n = n + 1 end
  for _, bld in ipairs(W.buildings) do
    local wr, wg, wb = rgb(bld.color[1])
    local rr, rg, rb = rgb(bld.color[2])
    local k = bld.color[3]
    local wall = { min(255, floor(wr * k)), min(255, floor(wg * k)), min(255, floor(wb * k)) }
    local roof = { min(255, floor(rr * k)), min(255, floor(rg * k)), min(255, floor(rb * k)) }
    local shade = { floor(wall[1] * 0.82), floor(wall[2] * 0.82), floor(wall[3] * 0.82) }
    for _, p in ipairs(bld.parts) do
      local lo, hi = p.z0 or bld.base, p.z1 or bld.top
      local wall, roof, shade = wall, roof, shade
      if p.color then                              -- a part's own colour (a ship's hull)
        local r, g, b2 = rgb(p.color)
        wall, roof = { r, g, b2 }, { r, g, b2 }
        shade = { floor(r * 0.82), floor(g * 0.82), floor(b2 * 0.82) }
      end
      local ring = {}
      if p.kind == "disc" then
        for a = 0, 15 do ring[#ring + 1] = p.x + p.r * cos(a * pi / 8); ring[#ring + 1] = p.y + p.r * sin(a * pi / 8) end
      else
        ring = { p.c[1], p.c[2], p.c[3], p.c[4], p.c[5], p.c[6], p.c[7], p.c[8] }
      end
      -- make the ring counter-clockwise seen from above
      local area = 0
      for q = 1, #ring - 1, 2 do
        local q2 = (q + 1) % #ring + 1
        area = area + ring[q] * ring[q2 + 1] - ring[q2] * ring[q + 1]
      end
      if area < 0 then
        local rev = {}
        for q = #ring - 1, 1, -2 do rev[#rev + 1] = ring[q]; rev[#rev + 1] = ring[q + 1] end
        ring = rev
      end
      local m = #ring / 2
      for q = 1, m do
        local a, b = 2 * q - 1, 2 * (q % m) + 1
        local col = (q % 2 == 0) and shade or wall
        tri(V(ring[a], ring[a + 1], lo), V(ring[b], ring[b + 1], lo), V(ring[b], ring[b + 1], hi), col)
        tri(V(ring[a], ring[a + 1], lo), V(ring[b], ring[b + 1], hi), V(ring[a], ring[a + 1], hi), col)
      end
      for q = 2, m - 1 do
        tri(V(ring[1], ring[2], hi), V(ring[2 * q - 1], ring[2 * q], hi), V(ring[2 * q + 1], ring[2 * q + 2], hi), roof)
      end
    end
  end
  mesh:build()
  mesh.col = "#c8c0b0"
  for i = 0, n - 1 do mesh:setTriangleColor(i, cols[i][1], cols[i][2], cols[i][3]) end
  viewer:add(mesh)
  if not opts.contact then pcall(function() mesh.body:setCollisionFlags(CF_STATIC + CF_NO_CONTACT) end) end
  return mesh
end

return B
