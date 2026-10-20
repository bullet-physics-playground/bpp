--
-- lib/town.lua -- the world generator's zones and streets (BOOK.md G21, §6)
--
-- The second realistic layer, built on a preset's terrain (lib/terrain.lua)
-- from its parameter table (lib/places.lua):
--
--   ZONES   Density falls exponentially with distance from each centre
--           (Clark 1951): intensity u = max over centres of
--           peak exp(-d / r). A preset's ladder maps bands of u to Local
--           Climate Zones (Stewart and Oke 2012), each with a street style;
--           districts (port, park, industry) override the ladder inside
--           their shapes; water is zone G; woods (A) cover a stated share
--           of the open land (D), where a noise field is highest (the cut
--           is the noise's quantile over the open land).
--   STREETS One hierarchy, so the network is connected:
--           arterials  winding roads through everything, bridging rivers;
--           grids      in the zones whose style is "grid", at a preset's
--                      block spacing and widths (Manhattan, Chicago);
--           collectors curving roads on a coarse warped grid in the zones
--                      whose style is "collectors" (suburbs);
--           cul-de-sacs off collectors and arterials in those zones, bent,
--                      each ending in a turning circle.
--           Then one rule: every street must connect to the arterials
--           (or, with none, to the largest network); the rest are dropped.
--
-- UNITS AND AXES: metres; x east, y north (lib/terrain.lua).
--
-- DEFINITIONS:
--   u            zone intensity, 0..1 (1 at a centre with peak 1)
--   LCZ          Local Climate Zone code: "1".."10" built types, "A".."G"
--                land covers (Town.LCZ has the names and the published
--                ranges of building fraction and mean height)
--   width        a street's right of way, m (building line to building
--                line in a compact core; carriageway and pavements)
--   street kind  "arterial", "grid", "collector", "culdesac", "bridge"
--
-- FIXED CONSTANTS (stated, not knobs):
--   BRIDGE_MAX 150 m      longest water a street may bridge (arterials, a
--                         grid's long family and one in four of its short
--                         family); collectors bridge up to 60 m (creeks);
--                         cul-de-sacs never
--   CUL_LENGTH 150 m      a cul-de-sac's longest run (US subdivision rules;
--                         the fire code allows dead ends to 750 ft, 229 m,
--                         with a 96 ft, 29.3 m, turnaround: radius 15 m)
--   CUL_BEND 0.5 rad      a cul-de-sac turns by up to this much along it
--   CUL_SPACING 90 m      stations along a road, alternating sides
--   CLEARANCE 80 m        between a new cul-de-sac and any other street:
--                         two suburban lots (32 m deep) back to back plus a
--                         15 m right of way
--   MIN_RUN 30 m          shorter street pieces are dropped
--
-- RANDOMNESS: its own stream, rng.new(seed + 1000), never the shared one.
--

local rng = require "lib.rng"
local Land = require "lib.terrain"   -- (not "Terrain": that is BPP's mesh class)

local Town = {}
Town.__index = Town

local floor, sqrt, abs, min, max, sin, cos, exp, pi = math.floor, math.sqrt, math.abs, math.min,
  math.max, math.sin, math.cos, math.exp, math.pi
local segDist = Land.segDist
local atan2 = math.atan2 or function(y, x) return math.atan(y, x) end -- Lua 5.3+ dropped atan2

Town.BRIDGE_MAX = 150
Town.COLLECTOR_BRIDGE_MAX = 60
Town.CUL_LENGTH = 150
Town.CUL_RADIUS = 15
Town.CUL_BEND = 0.5
Town.CUL_SPACING = 90
Town.CLEARANCE = 80
Town.MIN_RUN = 30

-- Local Climate Zones (Stewart and Oke 2012, Table 3): building surface
-- fraction (share of the zone's plan area under buildings) and the mean
-- height of the buildings, m. The land covers A-G have no buildings.
local INF = math.huge
Town.LCZ = {
  ["1"] = { name = "compact high-rise", built = { 0.40, 0.60 }, height = { 25, INF }, color = "#7d7872" },
  ["2"] = { name = "compact mid-rise", built = { 0.40, 0.70 }, height = { 10, 25 }, color = "#8a837a" },
  ["3"] = { name = "compact low-rise", built = { 0.40, 0.70 }, height = { 3, 10 }, color = "#958b7c" },
  ["4"] = { name = "open high-rise", built = { 0.20, 0.40 }, height = { 25, INF }, color = "#7f8a70" },
  ["5"] = { name = "open mid-rise", built = { 0.20, 0.40 }, height = { 10, 25 }, color = "#86956c" },
  ["6"] = { name = "open low-rise", built = { 0.20, 0.40 }, height = { 3, 10 }, color = "#7fa35a" },
  ["7"] = { name = "lightweight low-rise", built = { 0.60, 0.90 }, height = { 2, 4 }, color = "#9c8f70" },
  ["8"] = { name = "large low-rise", built = { 0.30, 0.50 }, height = { 3, 10 }, color = "#9d9b96" },
  ["9"] = { name = "sparsely built", built = { 0.10, 0.20 }, height = { 3, 10 }, color = "#88aa58" },
  ["10"] = { name = "heavy industry", built = { 0.20, 0.30 }, height = { 5, 15 }, color = "#8e877c" },
  A = { name = "dense trees", color = "#3d6a33" },
  B = { name = "scattered trees", color = "#68ad4b" },
  C = { name = "bush, scrub", color = "#7d9550" },
  D = { name = "low plants", color = "#a8b866" },
  E = { name = "bare rock or paved", color = "#aeaaa2" },
  F = { name = "bare soil or sand", color = "#cdbb8a" },
  G = { name = "water", color = "#2f6fa8" },
}

local function rgb(hex) return tonumber(hex:sub(2, 3), 16), tonumber(hex:sub(4, 5), 16), tonumber(hex:sub(6, 7), 16) end

--------------------------------------------------------------------------
-- Zones
--------------------------------------------------------------------------

-- Zone intensity at (x, y): Clark's exponential fall from each centre.
function Town:intensity(x, y)
  local u = 0
  for _, c in ipairs(self.centres) do
    local d = sqrt((x - c.x) ^ 2 + (y - c.y) ^ 2)
    u = max(u, (c.peak or 1) * exp(-d / c.r))
  end
  return u
end

-- The zone entry at (x, y): { lcz, streets = "grid"|"collectors"|nil,
-- grid = frame }. ignoreWater: the entry the land there would have (for
-- deciding where streets bridge).
function Town:entry(x, y, ignoreWater)
  if not ignoreWater and self.terrain:water(x, y) then return self.waterEntry end
  for k = #self.districts, 1, -1 do
    local d = self.districts[k]
    if Land.shapeDist(d.shape, x, y) <= 0 then return d end
  end
  local u = self:intensity(x, y)
  local e = self.openEntry
  for _, l in ipairs(self.ladder) do
    if u >= l.u then e = l; break end
  end
  if e.lcz == "D" and self.woodsCut and Land.fbm(self.woodsNoise, x - self.x0, y - self.y0) > self.woodsCut then
    return self.woodsEntry
  end
  return e
end

function Town:zone(x, y) return self:entry(x, y).lcz end

--------------------------------------------------------------------------
-- A spatial index of street segments
--------------------------------------------------------------------------

local BUCKET = 50

local function newIndex() return { cells = {} } end

local function indexAdd(idx, street)
  local p = street.pts
  for q = 1, #p - 3, 2 do
    local x0, y0, x1, y1 = min(p[q], p[q + 2]), min(p[q + 1], p[q + 3]), max(p[q], p[q + 2]), max(p[q + 1], p[q + 3])
    for i = floor(x0 / BUCKET), floor(x1 / BUCKET) do
      for j = floor(y0 / BUCKET), floor(y1 / BUCKET) do
        local key = i * 100003 + j
        local list = idx.cells[key]
        if not list then list = {}; idx.cells[key] = list end
        list[#list + 1] = { street, q }
      end
    end
  end
end

-- Nearest street centreline within r of (x, y) (skipping `skip`):
-- distance and the street, or math.huge.
local function indexNearest(idx, x, y, r, skip)
  local best, bs = math.huge, nil
  for i = floor((x - r) / BUCKET), floor((x + r) / BUCKET) do
    for j = floor((y - r) / BUCKET), floor((y + r) / BUCKET) do
      local list = idx.cells[i * 100003 + j]
      if list then
        for _, e in ipairs(list) do
          local s, q = e[1], e[2]
          if s ~= skip then
            local p = s.pts
            local d = segDist(x, y, p[q], p[q + 1], p[q + 2], p[q + 3])
            if d < best then best, bs = d, s end
          end
        end
      end
    end
  end
  return best, bs
end

-- Distance from (x, y) to the nearest street's edge (negative on the
-- street), and the street; math.huge beyond r (default 200 m).
function Town:streetDistance(x, y, r)
  r = r or 200
  local best, bs = math.huge, nil
  for i = floor((x - r) / BUCKET), floor((x + r) / BUCKET) do
    for j = floor((y - r) / BUCKET), floor((y + r) / BUCKET) do
      local list = self.index.cells[i * 100003 + j]
      if list then
        for _, e in ipairs(list) do
          local s, q = e[1], e[2]
          local p = s.pts
          local d = segDist(x, y, p[q], p[q + 1], p[q + 2], p[q + 3]) - s.width / 2
          if d < best then best, bs = d, s end
        end
      end
    end
  end
  for _, s in ipairs(self.streets) do
    if s.bulb then
      local d = sqrt((x - s.bulb[1]) ^ 2 + (y - s.bulb[2]) ^ 2) - s.bulb[3]
      if d < best then best, bs = d, s end
    end
  end
  return best, bs
end

--------------------------------------------------------------------------
-- Tracing a street along a line
--------------------------------------------------------------------------

-- Samples P(s) for s in [s0, s1] every ds and cuts it into street pieces:
-- runs where pred(x, y) holds on dry land, with water inside a run bridged
-- when it is no longer than bridgeMax (0: never) and split otherwise.
-- straight = true keeps only the pieces' ends. Returns a list of
-- { pts, kind } with kind "bridge" for the bridges.
local function trace(town, P, s0, s1, ds, pred, bridgeMax, straight)
  local b = town.bounds
  local S = {}
  local s = s0
  while s <= s1 + 1e-9 do
    local x, y = P(s)
    local inb = x >= b[1] and x <= b[3] and y >= b[2] and y <= b[4]
    local ok = inb and pred(x, y)
    S[#S + 1] = { x = x, y = y, ok = ok, wet = ok and town.terrain:water(x, y) ~= nil }
    s = s + ds
  end
  local out = {}
  local function emit(i0, i1, kind)
    if (i1 - i0) * ds < (kind == "bridge" and 0 or Town.MIN_RUN) then return end
    local pts = {}
    for i = i0, i1 do
      if not straight or i == i0 or i == i1 then
        pts[#pts + 1] = S[i].x; pts[#pts + 1] = S[i].y
      end
    end
    out[#out + 1] = { pts = pts, kind = kind }
  end
  local i, n = 1, #S
  while i <= n do
    if S[i].ok and not S[i].wet then
      -- a run of ok samples; walk it, bridging short water
      local start, j = i, i
      local lastDry = i
      while j + 1 <= n and S[j + 1].ok do
        j = j + 1
        if not S[j].wet then
          local gap = j - lastDry - 1
          if gap > 0 then                           -- water between lastDry and j
            if bridgeMax > 0 and gap * ds <= bridgeMax then
              emit(start, lastDry, nil)
              emit(lastDry, j, "bridge")
              start = j
            else
              emit(start, lastDry, nil)
              start = j
            end
          end
          lastDry = j
        end
      end
      emit(start, lastDry, nil)
      i = j + 1
    else
      i = i + 1
    end
  end
  return out
end

local function addStreet(town, pts, width, kind)
  local s = { pts = pts, width = width, kind = kind }
  town.streets[#town.streets + 1] = s
  indexAdd(town.index, s)
  return s
end

local function addTraced(town, pieces, width, kind)
  for _, p in ipairs(pieces) do
    addStreet(town, p.pts, width, p.kind or kind)
  end
end

--------------------------------------------------------------------------
-- The street layers
--------------------------------------------------------------------------

-- Arterials: { pts = { x1, y1, x2, y2, ... }, width, wander (m),
-- wavelength (m) }: the polyline, wandering sideways by up to `wander`
-- (fractal noise, faded to 0 over 300 m at each end so the ends stay put).
local function layArterial(town, a, s)
  local p = a.pts
  -- the polyline's length and a point at arc length t
  local cum = { 0 }
  for q = 1, #p - 3, 2 do cum[#cum + 1] = cum[#cum] + sqrt((p[q + 2] - p[q]) ^ 2 + (p[q + 3] - p[q + 1]) ^ 2) end
  local L = cum[#cum]
  local noise = Land.newNoise(s, L + 10, 1, a.wavelength or 600, 2)
  local function P(t)
    local k = 1
    while k < #cum - 1 and cum[k + 1] < t do k = k + 1 end
    local q = 2 * k - 1
    local seg = cum[k + 1] - cum[k]
    local f = seg > 0 and (t - cum[k]) / seg or 0
    local dx, dy = p[q + 2] - p[q], p[q + 3] - p[q + 1]
    local len = sqrt(dx * dx + dy * dy)
    local nx, ny = -dy / len, dx / len
    local fade = min(1, t / 300, (L - t) / 300)
    local off = (a.wander or 0) * fade * Land.fbm(noise, t, 0.5)
    return p[q] + f * dx + off * nx, p[q + 1] + f * dy + off * ny
  end
  addTraced(town, trace(town, P, 0, L, 10, function() return true end, Town.BRIDGE_MAX, false),
            a.width or 30, "arterial")
end

-- A grid: frame = { x, y, angle, spacing = { a, b }, widths = { wa, wb } }.
-- Family 1 runs along the angle, its lines a apart; family 2 across it,
-- b apart. Lines exist where the zone's grid is this frame.
local function layGrid(town, F)
  local c, sn = cos(F.angle or 0), sin(F.angle or 0)
  local b = town.bounds
  local R = sqrt((b[3] - b[1]) ^ 2 + (b[4] - b[2]) ^ 2)
  local pred = function(x, y) return town:entry(x, y, true).grid == F end
  for fam = 1, 2 do
    local sp, width = F.spacing[fam], F.widths[fam]
    -- direction along the line, and across it
    local ex, ey = (fam == 1) and c or -sn, (fam == 1) and sn or c
    local nx, ny = -ey, ex
    local N = math.ceil(R / sp)
    for i = -N, N do
      local ox, oy = F.x + i * sp * nx, F.y + i * sp * ny
      local P = function(t) return ox + t * ex, oy + t * ey end
      local bridge = (fam == 2 or i % 4 == 0) and Town.BRIDGE_MAX or 0
      addTraced(town, trace(town, P, -R, R, 4, pred, bridge, true), width, "grid")
    end
  end
end

-- Collectors: frame = { angle, spacing, warp (m), wavelength (m), width }:
-- a grid of lines `spacing` apart, each bent sideways by up to `warp`.
local function layCollectors(town, C, s)
  local c, sn = cos(C.angle or 0), sin(C.angle or 0)
  local b = town.bounds
  local cx, cy = (b[1] + b[3]) / 2, (b[2] + b[4]) / 2
  local R = sqrt((b[3] - b[1]) ^ 2 + (b[4] - b[2]) ^ 2) / 2 + 50
  local N = math.ceil(R / C.spacing)
  local lam = C.wavelength or 500
  local noise = Land.newNoise(s, 2 * R + 10, (2 * N + 3) * 4 * lam, lam, 2)
  local pred = function(x, y) return town:entry(x, y, true).streets == "collectors" end
  for fam = 1, 2 do
    local ex, ey = (fam == 1) and c or -sn, (fam == 1) and sn or c
    local nx, ny = -ey, ex
    for i = -N, N do
      local row = ((fam - 1) * (2 * N + 1) + i + N) * 2 * lam + 0.5
      local P = function(t)
        local off = i * C.spacing + (C.warp or 0) * Land.fbm(noise, t + R, row)
        return cx + t * ex + off * nx, cy + t * ey + off * ny
      end
      addTraced(town, trace(town, P, -R, R, 10, pred, Town.COLLECTOR_BRIDGE_MAX, false),
                C.width or 20, "collector")
    end
  end
end

-- Cul-de-sacs off the collectors and arterials, where the zone's style is
-- "collectors": every CUL_SPACING along the road, alternating sides; each
-- runs from the road's edge, turning steadily by up to CUL_BEND, and stops
-- at CUL_LENGTH, at water, out of the zone, or CLEARANCE from any other
-- street; kept if at least 50 m long.
local function layCulDeSacs(town, width, s)
  local roads = {}
  for _, st in ipairs(town.streets) do
    if st.kind == "collector" or st.kind == "arterial" then roads[#roads + 1] = st end
  end
  local b = town.bounds
  for _, road in ipairs(roads) do
    local p = road.pts
    local acc, nextAt, side = 0, Town.CUL_SPACING / 2, 1
    for q = 1, #p - 3, 2 do
      local dx, dy = p[q + 2] - p[q], p[q + 3] - p[q + 1]
      local len = sqrt(dx * dx + dy * dy)
      while len > 0 and acc + len >= nextAt do
        local f = (nextAt - acc) / len
        local x, y = p[q] + f * dx, p[q + 1] + f * dy
        local nx, ny = -dy / len * side, dx / len * side
        nextAt = nextAt + Town.CUL_SPACING / 2
        side = -side
        local e = town:entry(x + nx * (road.width / 2 + 10), y + ny * (road.width / 2 + 10))
        if e.streets == "collectors" then
          local heading = atan2(ny, nx)
          local bend = Town.CUL_BEND * (2 * s:random() - 1)
          local px, py = x + nx * road.width / 2, y + ny * road.width / 2
          local pts, L = { px, py }, 0
          while L < Town.CUL_LENGTH do
            local th = heading + bend * (L / Town.CUL_LENGTH)
            local qx, qy = px + 10 * cos(th), py + 10 * sin(th)
            local m = Town.CUL_RADIUS + 15
            if qx < b[1] + m or qx > b[3] - m or qy < b[2] + m or qy > b[4] - m then break end
            local ez = town:entry(qx, qy)
            if ez.streets ~= "collectors" then break end
            local d = indexNearest(town.index, qx, qy, Town.CLEARANCE, road)
            if d < Town.CLEARANCE then break end
            px, py, L = qx, qy, L + 10
            pts[#pts + 1] = px; pts[#pts + 1] = py
          end
          if L >= 50 then
            local st = addStreet(town, pts, width, "culdesac")
            st.bulb = { px, py, Town.CUL_RADIUS }
            st.parent = road
          end
        end
      end
      acc = acc + len
    end
  end
end

-- The connection rule. Two streets touch when their centrelines come
-- within half the wider one's width (a cul-de-sac starts at its road's
-- edge; a crossing passes through). Keeps the streets connected to an
-- arterial, or with no arterial the largest connected set.
local function connect(town)
  local S = town.streets
  local n = #S
  local box = {}
  for k, s in ipairs(S) do
    local p = s.pts
    local a, b2, c, d = INF, INF, -INF, -INF
    for q = 1, #p, 2 do a, b2, c, d = min(a, p[q]), min(b2, p[q + 1]), max(c, p[q]), max(d, p[q + 1]) end
    box[k] = { a - s.width, b2 - s.width, c + s.width, d + s.width }
  end
  local function touch(A, B)
    local tol = max(A.width, B.width) / 2 + 1
    local pa, pb = A.pts, B.pts
    for q = 1, #pa - 1, 2 do
      local d = indexNearest({ cells = B.cells }, pa[q], pa[q + 1], tol)
      if d <= tol then return true end
    end
    for q = 1, #pb - 1, 2 do
      local d = indexNearest({ cells = A.cells }, pb[q], pb[q + 1], tol)
      if d <= tol then return true end
    end
    -- crossing segments without a vertex near the other
    for q = 1, #pa - 3, 2 do
      for r = 1, #pb - 3, 2 do
        local x1, y1, x2, y2 = pa[q], pa[q + 1], pa[q + 2], pa[q + 3]
        local x3, y3, x4, y4 = pb[r], pb[r + 1], pb[r + 2], pb[r + 3]
        local d1 = (x4 - x3) * (y1 - y3) - (y4 - y3) * (x1 - x3)
        local d2 = (x4 - x3) * (y2 - y3) - (y4 - y3) * (x2 - x3)
        local d3 = (x2 - x1) * (y3 - y1) - (y2 - y1) * (x3 - x1)
        local d4 = (x2 - x1) * (y4 - y1) - (y2 - y1) * (x4 - x1)
        if d1 * d2 < 0 and d3 * d4 < 0 then return true end
      end
    end
    return false
  end
  for _, s in ipairs(S) do s.cells = newIndex().cells; indexAdd({ cells = s.cells }, s) end
  local adj = {}
  for i = 1, n do adj[i] = {} end
  for i = 1, n do
    for j = i + 1, n do
      local A, B = box[i], box[j]
      if A[1] <= B[3] and B[1] <= A[3] and A[2] <= B[4] and B[2] <= A[4] and touch(S[i], S[j]) then
        adj[i][#adj[i] + 1] = j; adj[j][#adj[j] + 1] = i
      end
    end
  end
  local comp, ncomp, sizes, hasArt = {}, 0, {}, {}
  for i = 1, n do
    if not comp[i] then
      ncomp = ncomp + 1
      sizes[ncomp], hasArt[ncomp] = 0, false
      local stack = { i }
      comp[i] = ncomp
      while #stack > 0 do
        local k = table.remove(stack)
        sizes[ncomp] = sizes[ncomp] + 1
        if S[k].kind == "arterial" then hasArt[ncomp] = true end
        for _, j in ipairs(adj[k]) do
          if not comp[j] then comp[j] = ncomp; stack[#stack + 1] = j end
        end
      end
    end
  end
  local anyArt, biggest = false, 1
  for c = 1, ncomp do
    if hasArt[c] then anyArt = true end
    if sizes[c] > sizes[biggest] then biggest = c end
  end
  local keep, dropped = {}, 0
  for i = 1, n do
    local c = comp[i]
    if (anyArt and hasArt[c]) or (not anyArt and c == biggest) then keep[#keep + 1] = S[i]
    else dropped = dropped + 1 end
    S[i].cells = nil
  end
  town.streets = keep
  town.dropped = dropped
  town.index = newIndex()
  for _, s in ipairs(keep) do indexAdd(town.index, s) end
end

--------------------------------------------------------------------------
-- Building it
--------------------------------------------------------------------------

-- spec.zones = { centres = { { x, y, r, peak } }, ladder = { { u, lcz,
--   streets, grid } }, open = lcz below the ladder (default "D"),
--   districts = { { shape, lcz, streets, grid } } or function(terrain),
--   woods = share of open land under woods, woodsWavelength (m) }
-- spec.streets = { arterials = { ... } or function(terrain), grid =
--   frame (the ladder's grid), collectors = frame, local width (m) }
function Town.build(terrain, spec)
  local t0 = os.clock()
  local Z, St = spec.zones or {}, spec.streets or {}
  local town = setmetatable({}, Town)
  town.terrain = terrain
  town.bounds = { terrain.x0, terrain.y0, terrain.x1, terrain.y1 }
  town.x0, town.y0 = terrain.x0, terrain.y0
  local s = rng.new((spec.seed or 1) + 1000)
  town.centres = Z.centres or {}
  town.ladder = {}
  for _, e in ipairs(Z.ladder or {}) do
    local copy = { u = e.u, lcz = e.lcz, streets = e.streets, grid = e.grid }
    if copy.streets == "grid" and not copy.grid then copy.grid = St.grid end
    town.ladder[#town.ladder + 1] = copy
  end
  local d = Z.districts or {}
  if type(d) == "function" then d = d(terrain) end
  town.districts = d
  town.waterEntry = { lcz = "G" }
  town.openEntry = { lcz = Z.open or "D" }
  town.woodsEntry = { lcz = "A" }
  if (Z.woods or 0) > 0 then
    local W, H = terrain.x1 - terrain.x0, terrain.y1 - terrain.y0
    town.woodsNoise = Land.newNoise(s, W, H, Z.woodsWavelength or 400, 3)
    -- the cut that puts the stated share of the open land (zone D) above
    -- it, from a 150 x 150 sample
    local v = {}
    for i = 0, 149 do
      for j = 0, 149 do
        local x, y = terrain.x0 + (i + 0.5) * W / 150, terrain.y0 + (j + 0.5) * H / 150
        if town:entry(x, y).lcz == "D" then v[#v + 1] = Land.fbm(town.woodsNoise, x - town.x0, y - town.y0) end
      end
    end
    table.sort(v)
    if #v > 0 then town.woodsCut = v[min(#v, floor((1 - Z.woods) * #v) + 1)] end
  end
  town.streets, town.index = {}, newIndex()
  local arts = St.arterials or {}
  if type(arts) == "function" then arts = arts(terrain) end
  for _, a in ipairs(arts) do layArterial(town, a, s) end
  -- every grid frame in the ladder or the districts, once each
  local frames, seen = {}, {}
  for _, e in ipairs(town.ladder) do if e.grid and not seen[e.grid] then seen[e.grid] = true; frames[#frames + 1] = e.grid end end
  for _, e in ipairs(town.districts) do if e.grid and not seen[e.grid] then seen[e.grid] = true; frames[#frames + 1] = e.grid end end
  for _, F in ipairs(frames) do layGrid(town, F) end
  if St.collectors then layCollectors(town, St.collectors, s) end
  layCulDeSacs(town, St["local"] or 15, s)
  connect(town)
  town.buildTime = os.clock() - t0
  return town
end

--------------------------------------------------------------------------
-- Measures
--------------------------------------------------------------------------

-- Shares of the area by zone, from an m x m sample (default 200), and the
-- street length by kind (km).
function Town:stats(m)
  m = m or 200
  local b = self.bounds
  local share, n = {}, 0
  for i = 0, m - 1 do
    for j = 0, m - 1 do
      local z = self:zone(b[1] + (i + 0.5) * (b[3] - b[1]) / m, b[2] + (j + 0.5) * (b[4] - b[2]) / m)
      share[z] = (share[z] or 0) + 1
      n = n + 1
    end
  end
  for k, v in pairs(share) do share[k] = v / n end
  local km = {}
  for _, st in ipairs(self.streets) do
    local p, L = st.pts, 0
    for q = 1, #p - 3, 2 do L = L + sqrt((p[q + 2] - p[q]) ^ 2 + (p[q + 3] - p[q + 1]) ^ 2) end
    km[st.kind] = (km[st.kind] or 0) + L / 1000
  end
  return { share = share, km = km, streets = #self.streets, dropped = self.dropped }
end

--------------------------------------------------------------------------
-- BPP geometry
--------------------------------------------------------------------------

-- The ground's colour by zone, for lib/terrain.lua's toBPP (dry ground).
function Town:groundColor()
  local cache = {}
  for k, z in pairs(Town.LCZ) do cache[k] = { rgb(z.color) } end
  return function(x, y)
    local c = cache[self:zone(x, y)]
    if c then return c[1], c[2], c[3] end
  end
end

local CF_STATIC, CF_NO_CONTACT = 1, 4
local STREET_COLOR = { arterial = "#3a3a3c", grid = "#46464a", collector = "#404044",
                       culdesac = "#4c4c50", bridge = "#76706a" }

-- All streets as one mesh draped 0.3 m over the ground (subdivided to
-- half a terrain cell so it follows the ground), bridges as flat decks
-- between their banks' heights (at least 2 m over the water), cul-de-sac
-- turning circles as discs. opts: scale, base, contact. Returns the mesh.
function Town:toBPP(viewer, opts)
  opts = opts or {}
  local S, base = opts.scale or 1, opts.base or 0
  local t = self.terrain
  local mesh = Terrain()
  local colours, n = {}, 0
  local function V(x, y, h) return btVector3(x * S, base + h * S, -y * S) end
  local function tri(a, b, c, col)
    mesh:addTriangle(a, b, c)
    colours[n] = col
    n = n + 1
  end
  local LIFT = 0.3
  for _, st in ipairs(self.streets) do
    local col = { rgb(STREET_COLOR[st.kind] or "#46464a") }
    local p = st.pts
    -- resample to at most half a cell
    local P = {}
    for q = 1, #p - 3, 2 do
      local dx, dy = p[q + 2] - p[q], p[q + 3] - p[q + 1]
      local k = math.max(1, math.ceil(sqrt(dx * dx + dy * dy) / (t.cell / 2)))
      for i = 0, k - 1 do P[#P + 1] = { p[q] + dx * i / k, p[q + 1] + dy * i / k } end
    end
    P[#P + 1] = { p[#p - 1], p[#p] }
    local h0, h1
    if st.kind == "bridge" then
      h0, h1 = t:ground(P[1][1], P[1][2]), t:ground(P[#P][1], P[#P][2])
    end
    local hw = st.width / 2
    local L, Ls = {}, 0
    for i = 1, #P do
      if i > 1 then Ls = Ls + sqrt((P[i][1] - P[i - 1][1]) ^ 2 + (P[i][2] - P[i - 1][2]) ^ 2) end
      L[i] = Ls
    end
    local prev
    for i = 1, #P do
      local a = P[max(1, i - 1)]
      local b = P[min(#P, i + 1)]
      local dx, dy = b[1] - a[1], b[2] - a[2]
      local len = sqrt(dx * dx + dy * dy)
      if len > 0 then
        local nx, ny = -dy / len * hw, dx / len * hw
        local lx, ly, rx, ry = P[i][1] + nx, P[i][2] + ny, P[i][1] - nx, P[i][2] - ny
        local hl, hr
        if st.kind == "bridge" then
          local f = Ls > 0 and L[i] / Ls or 0
          local deck = h0 + (h1 - h0) * f
          local wl = t:water(P[i][1], P[i][2])
          if wl and deck < wl + 2 then deck = wl + 2 end
          hl, hr = deck, deck
        else
          hl, hr = t:ground(lx, ly) + LIFT, t:ground(rx, ry) + LIFT
          local hc = t:ground(P[i][1], P[i][2]) + LIFT
          hl, hr = max(hl, hc), max(hr, hc)
        end
        local cur = { V(lx, ly, hl), V(rx, ry, hr) }
        if prev then
          tri(prev[2], cur[2], cur[1], col)
          tri(prev[2], cur[1], prev[1], col)
        end
        prev = cur
      end
    end
    if st.bulb then
      local bx, by, r = st.bulb[1], st.bulb[2], st.bulb[3]
      local hc = t:ground(bx, by) + LIFT + 0.02
      local K = 16
      for k = 0, K - 1 do
        local a0, a1 = 2 * pi * k / K, 2 * pi * (k + 1) / K
        local x0, y0 = bx + r * cos(a0), by + r * sin(a0)
        local x1, y1 = bx + r * cos(a1), by + r * sin(a1)
        tri(V(bx, by, hc), V(x0, y0, max(hc, t:ground(x0, y0) + LIFT)), V(x1, y1, max(hc, t:ground(x1, y1) + LIFT)), col)
      end
    end
  end
  if n == 0 then return nil end
  mesh:build()
  mesh.col = "#46464a"
  for i = 0, n - 1 do
    local c = colours[i]
    mesh:setTriangleColor(i, c[1], c[2], c[3])
  end
  viewer:add(mesh)
  if not opts.contact then pcall(function() mesh.body:setCollisionFlags(CF_STATIC + CF_NO_CONTACT) end) end
  return mesh
end

return Town
