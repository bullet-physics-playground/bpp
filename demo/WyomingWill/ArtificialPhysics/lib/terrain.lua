--
-- lib/terrain.lua -- the world generator's ground and water (BOOK.md G21, §6)
--
-- The first realistic layer: a heightfield of the ground, and the water on
-- it (sea, rivers, ponds) with depth, built in a fixed order from a
-- preset's parameter table (lib/places.lua has the five presets):
--
--   1. land     a coastal plain rising inland, with rolling hills on it
--               (fractal value noise, 0 to `relief` above the plain) that
--               fade out toward the coast
--   2. fill     raised platforms (reclaimed quays), with sloped edges
--   3. rivers   a meandering channel cut to a water level that only falls
--               downstream, on a floodplain just above it
--   4. ponds    bowls below their own rim
--   5. dredge   approach and main channels, turning basin: cut to their
--               depth with 1:3 sides
--   6. slope    every dry slope limited to MAX_SLOPE, so ground vehicles
--               can drive anywhere on land; this one rule also shapes the
--               river valleys' walls, the ponds' banks and the dry part of
--               a dredged cut
--   7. quays    basins and berths cut with vertical walls (after the
--               slope rule, so they stay vertical)
--   8. sea      water at level 0 wherever the ground is below 0 and
--               connected to the open boundary
--
-- UNITS AND AXES: metres. x east, y north (the book's (x, y)), z up;
-- elevation is above sea level (the datum, 0), so the seabed is negative.
-- In BPP, (x, y, z) becomes (x, z, -y) (lib/world.lua's mapping).
--
-- DEFINITIONS:
--   ground(x, y)   elevation of the ground or seabed, m; linear on the
--                  mesh's triangles, so it is exactly the surface drawn
--                  and collided with
--   level(x, y)    elevation of the water surface, m (sea 0); nil if dry
--   depth          level - ground, m (> 0 in water)
--   slope          rise over run (0.15 = 15%) of a triangle's steepest
--                  direction; "along the grid" means between neighbouring
--                  nodes in the 8 grid directions
--   sinuosity      a river's length along its channel over the straight
--                  distance between its ends
--
-- FIXED CONSTANTS (stated, not knobs; a preset may override MAX_SLOPE):
--   MAX_SLOPE 0.15     steepest dry slope along the grid. 15% is about the
--                      steepest grade of ordinary hilly residential
--                      streets; a triangle can be up to sqrt(2) x steeper
--                      across the grid (checks/terrain.lua measures it)
--   WIDTH_DEPTH 12     a river's width over its depth (lowland rivers 10-20)
--   MEANDER 11         meander wavelength along the valley over the width
--                      (Leopold and Wolman 1960: 10-14)
--   OMEGA 1.1 rad      the sine-generated curve's largest angle to the
--                      valley (Langbein and Leopold 1966); its sinuosity is
--                      1 / J0(OMEGA) = 1.39
--   BEND_SPREAD 0.3    each bend's length varies by up to +-30% (uniform),
--                      so meanders are not all alike; a bend's sinuosity
--                      does not depend on its length, so it stays 1.39
--   BANK 0.5 m         floodplain above the river's water
--   FLOODPLAIN 2       floodplain on each side, in channel widths
--   POND_BANK 0.3 m    a pond's rim above its water
--   DREDGE_RUN 3       dredged side slopes, horizontal over vertical (1:3)
--
-- RANDOMNESS: one stream per terrain, rng.new(seed), never the shared one,
-- so the same seed gives the same terrain and building it does not shift
-- the agents' random numbers.
--
--   local Terrain = require "lib.terrain"
--   local t = Terrain.generate(spec)    -- spec: lib/places.lua
--   t:ground(x, y); t:water(x, y)       -- -> level, depth, kind or nil
--   t:slope(x, y); t:stats(); t:checksum()
--   t:toBPP(v, opts)                    -- ground and water meshes
--

local rng = require "lib.rng"

local T = {}
T.__index = T

local floor, sqrt, abs, min, max, sin, cos, pi = math.floor, math.sqrt, math.abs, math.min, math.max,
  math.sin, math.cos, math.pi
local atan2 = math.atan2 or function(y, x) return math.atan(y, x) end -- Lua 5.3+ dropped atan2

T.MAX_SLOPE = 0.15
T.WIDTH_DEPTH = 12
T.MEANDER = 11
T.OMEGA = 1.1
T.BEND_SPREAD = 0.3
T.BANK = 0.5
T.FLOODPLAIN = 2
T.POND_BANK = 0.3
T.DREDGE_RUN = 3

-- Bessel J0 by its series (|x| < 3 is all we need): the sine-generated
-- curve's sinuosity is 1 / J0(omega).
function T.J0(x)
  local s, term, k = 0, 1, 0
  repeat
    s = s + term
    k = k + 1
    term = -term * (x / 2) ^ 2 / (k * k)
  until abs(term) < 1e-15
  return s
end

--------------------------------------------------------------------------
-- Fractal value noise
--------------------------------------------------------------------------

-- A lattice of random values in [-1, 1], one per octave, with smooth
-- (quintic) interpolation between them. fbm() sums octaves of halving
-- amplitude and doubling frequency, normalised so |fbm| <= 1.
local function fade(t) return t * t * t * (t * (t * 6 - 15) + 10) end

local function newNoise(s, width, height, wavelength, octaves)
  local n = { octaves = {} }
  local amp, total = 1, 0
  for o = 1, octaves do
    local lam = wavelength / 2 ^ (o - 1)
    local nu, nv = floor(width / lam) + 3, floor(height / lam) + 3
    local L = {}
    for k = 1, nu * nv do L[k] = 2 * s:random() - 1 end
    -- a random offset, so octaves do not share lattice points
    n.octaves[o] = { L = L, nu = nu, lam = lam, amp = amp, du = s:random(), dv = s:random() }
    total = total + amp
    amp = amp / 2
  end
  n.total = total
  return n
end

local function fbm(n, x, y)  -- x, y measured from the area's low corner
  local sum = 0
  for _, o in ipairs(n.octaves) do
    local u, v = x / o.lam + o.du, y / o.lam + o.dv
    local i, j = floor(u), floor(v)
    local fu, fv = fade(u - i), fade(v - j)
    local L, k = o.L, j * o.nu + i + 1
    local a, b, c, d = L[k], L[k + 1], L[k + o.nu], L[k + o.nu + 1]
    sum = sum + o.amp * (a + (b - a) * fu + (c - a) * fv + (a - b - c + d) * fu * fv)
  end
  return sum / n.total
end

local function smoothstep(e0, e1, x)
  local t = min(1, max(0, (x - e0) / (e1 - e0)))
  return t * t * (3 - 2 * t)
end

--------------------------------------------------------------------------
-- Shapes for fill and dredging: signed distance, negative inside
--------------------------------------------------------------------------

local function segDist(px, py, ax, ay, bx, by)
  local dx, dy = bx - ax, by - ay
  local L2 = dx * dx + dy * dy
  local t = L2 > 0 and max(0, min(1, ((px - ax) * dx + (py - ay) * dy) / L2)) or 0
  local qx, qy = ax + t * dx - px, ay + t * dy - py
  return sqrt(qx * qx + qy * qy), t
end
T.segDist = segDist

-- shape = { kind = "rect", x, y, sx, sy, a } | { kind = "disc", x, y, r }
--       | { kind = "strip", pts = { x1, y1, x2, y2, ... }, w = width }
function T.shapeDist(sh, x, y)
  if sh.kind == "disc" then
    local dx, dy = x - sh.x, y - sh.y
    return sqrt(dx * dx + dy * dy) - sh.r
  elseif sh.kind == "rect" then
    local c, s = cos(sh.a or 0), sin(sh.a or 0)
    local dx, dy = x - sh.x, y - sh.y
    local qx = abs(dx * c + dy * s) - sh.sx / 2
    local qy = abs(-dx * s + dy * c) - sh.sy / 2
    local ox, oy = max(qx, 0), max(qy, 0)
    return sqrt(ox * ox + oy * oy) + min(max(qx, qy), 0)
  else
    local p, best = sh.pts, math.huge
    for k = 1, #p - 3, 2 do best = min(best, (segDist(x, y, p[k], p[k + 1], p[k + 2], p[k + 3]))) end
    return best - sh.w / 2
  end
end

--------------------------------------------------------------------------
-- The grid
--------------------------------------------------------------------------

-- Nodes (i, j), i = 0..nx, j = 0..ny, at (x0 + i cell, y0 + j cell);
-- node index k = j (nx + 1) + i + 1. Each cell is two triangles split
-- along its (i, j)-(i+1, j+1) diagonal, the same split for drawing,
-- collision and ground().
local function newGrid(spec)
  local b = spec.bounds
  local t = setmetatable({}, T)
  t.name = spec.name or "terrain"
  t.cell = spec.cell or 10
  t.x0, t.y0 = b[1], b[2]
  t.nx = math.ceil((b[3] - b[1]) / t.cell)
  t.ny = math.ceil((b[4] - b[2]) / t.cell)
  t.x1, t.y1 = t.x0 + t.nx * t.cell, t.y0 + t.ny * t.cell
  t.stride = t.nx + 1
  t.h, t.wl, t.kind = {}, {}, {}   -- ground; water level; "sea" | "river" | "pond"
  t.maxSlope = spec.maxSlope or T.MAX_SLOPE
  t.rivers, t.ponds, t.dredged, t.notes = {}, {}, {}, {}
  return t
end

function T:index(i, j) return j * self.stride + i + 1 end
function T:nodeXY(k)
  local i, j = (k - 1) % self.stride, floor((k - 1) / self.stride)
  return self.x0 + i * self.cell, self.y0 + j * self.cell, i, j
end

-- Interpolate a node array on the cell's triangle holding (x, y).
local function interp(t, arr, x, y)
  local u, v = (x - t.x0) / t.cell, (y - t.y0) / t.cell
  local i, j = floor(u), floor(v)
  if i < 0 then i = 0 elseif i > t.nx - 1 then i = t.nx - 1 end
  if j < 0 then j = 0 elseif j > t.ny - 1 then j = t.ny - 1 end
  local fu, fv = min(1, max(0, u - i)), min(1, max(0, v - j))
  local k = j * t.stride + i + 1
  local h00, h11 = arr[k], arr[k + t.stride + 1]
  if fu >= fv then
    local h10 = arr[k + 1]
    return h00 + (h10 - h00) * fu + (h11 - h10) * fv
  else
    local h01 = arr[k + t.stride]
    return h00 + (h11 - h01) * fu + (h01 - h00) * fv
  end
end

function T:ground(x, y) return interp(self, self.h, x, y) end

-- Water at (x, y): its level, depth and kind, or nil if the nearest node
-- is dry.
function T:water(x, y)
  local i = floor((x - self.x0) / self.cell + 0.5)
  local j = floor((y - self.y0) / self.cell + 0.5)
  if i < 0 or j < 0 or i > self.nx or j > self.ny then return nil end
  local k = j * self.stride + i + 1
  local L = self.wl[k]
  if not L then return nil end
  return L, L - self:ground(x, y), self.kind[k]
end

-- Steepest slope of the triangle holding (x, y).
local function triSlope(t, k, upper)
  local s, c = t.stride, t.cell
  local h00, h11 = t.h[k], t.h[k + s + 1]
  local gx, gy
  if upper then local h10 = t.h[k + 1]; gx, gy = h10 - h00, h11 - h10
  else local h01 = t.h[k + s]; gx, gy = h11 - h01, h01 - h00 end
  return sqrt(gx * gx + gy * gy) / c
end

function T:slope(x, y)
  local u, v = (x - self.x0) / self.cell, (y - self.y0) / self.cell
  local i = min(self.nx - 1, max(0, floor(u)))
  local j = min(self.ny - 1, max(0, floor(v)))
  return triSlope(self, j * self.stride + i + 1, (u - i) >= (v - j))
end

-- Calls fn(k, upper, kA, kB, kC) for every triangle (kA..kC its nodes).
function T:eachTriangle(fn)
  local s = self.stride
  for j = 0, self.ny - 1 do
    for i = 0, self.nx - 1 do
      local k = j * s + i + 1
      fn(k, true, k, k + 1, k + s + 1)
      fn(k, false, k, k + s + 1, k + s)
    end
  end
end

--------------------------------------------------------------------------
-- The layers
--------------------------------------------------------------------------

-- 1. Land. spec.land = { height (m at the coast, or at the south edge
-- without one), rise (gradient inland, per m), relief (m, the hills'
-- greatest height above the plain), wavelength (m, the largest hills),
-- octaves, flatNearCoast (m over which the hills fade in from the
-- shore) }. Hills stand on the plain and never dig below it, so the land
-- never sinks under the sea.
-- spec.coast = { y, wobble (m), wavelength (m), shelf (seabed gradient
-- offshore), bay = { x, depth (m inland), width (m, Gaussian sd) } } or nil.
-- Distance from the coast is measured north-south (coastY), which keeps
-- the plain and the shelf parallel to the shore away from steep bends.
local function layLand(t, spec, s)
  local land, coast = spec.land or {}, spec.coast
  local W, H = t.x1 - t.x0, t.y1 - t.y0
  local relief = newNoise(s, W, H, land.wavelength or 1000, land.octaves or 3)
  local coastNoise = coast and newNoise(s, W, 1, coast.wavelength or 800, 2)
  if coast then
    local bay = coast.bay
    t.coastY = function(x)
      local y = coast.y + (coast.wobble or 0) * fbm(coastNoise, x - t.x0, 0.5)
      if bay then y = y + bay.depth * math.exp(-0.5 * ((x - bay.x) / bay.width) ^ 2) end
      return y
    end
  end
  local h0, rise, A = land.height or 0, land.rise or 0, land.relief or 0
  local flat = land.flatNearCoast or 300
  local shelf = coast and (coast.shelf or 0.01)
  for j = 0, t.ny do
    for i = 0, t.nx do
      local x, y = t.x0 + i * t.cell, t.y0 + j * t.cell
      local k = j * t.stride + i + 1
      if coast then
        local d = y - t.coastY(x)                 -- > 0 inland
        if d >= 0 then
          t.h[k] = h0 + rise * d + A * smoothstep(0, flat, d) * (fbm(relief, x - t.x0, y - t.y0) + 1) / 2
        else
          t.h[k] = shelf * d                      -- the shelf: depth grows offshore
        end
      else
        t.h[k] = h0 + rise * (y - t.y0) + A * (fbm(relief, x - t.x0, y - t.y0) + 1) / 2
      end
    end
  end
end

local function forNodesNear(t, x0, y0, x1, y1, fn)
  local c = t.cell
  for j = max(0, floor((y0 - t.y0) / c)), min(t.ny, math.ceil((y1 - t.y0) / c)) do
    for i = max(0, floor((x0 - t.x0) / c)), min(t.nx, math.ceil((x1 - t.x0) / c)) do
      fn(j * t.stride + i + 1, t.x0 + i * c, t.y0 + j * c)
    end
  end
end

local function shapeBox(sh, margin)
  if sh.kind == "disc" then return sh.x - sh.r - margin, sh.y - sh.r - margin, sh.x + sh.r + margin, sh.y + sh.r + margin end
  if sh.kind == "rect" then
    local c, s = abs(cos(sh.a or 0)), abs(sin(sh.a or 0))
    local hx, hy = (sh.sx * c + sh.sy * s) / 2 + margin, (sh.sx * s + sh.sy * c) / 2 + margin
    return sh.x - hx, sh.y - hy, sh.x + hx, sh.y + hy
  end
  local p = sh.pts
  local a, b, c2, d = math.huge, math.huge, -math.huge, -math.huge
  for k = 1, #p, 2 do a, b, c2, d = min(a, p[k]), min(b, p[k + 1]), max(c2, p[k]), max(d, p[k + 1]) end
  local m = sh.w / 2 + margin
  return a - m, b - m, c2 + m, d + m
end

-- 2. Fill: { shape, height, run } raises the ground to height inside the
-- shape, sloping down at 1:run outside it (run 0: a vertical edge).
local function layFill(t, f)
  local run = f.run or 2
  local margin = run * max(0, f.height + 30)
  local bx0, by0, bx1, by1 = shapeBox(f.shape, margin)
  forNodesNear(t, bx0, by0, bx1, by1, function(k, x, y)
    local d = T.shapeDist(f.shape, x, y)
    local target = d <= 0 and f.height or (run > 0 and f.height - d / run or -math.huge)
    if target > t.h[k] then t.h[k] = target end
  end)
end

-- The centreline of a river: a sine-generated curve (direction to the
-- valley omega sin(phi), phi advancing 2 pi per meander length M) steered
-- toward its end, each bend (half a meander) M x (1 +- BEND_SPREAD) long.
-- Ends where it reaches the end point or leaves the area.
local function riverLine(t, r, s)
  local w = r.width
  local lambda = T.MEANDER * w                 -- along the valley
  local M = lambda / T.J0(T.OMEGA)             -- along the channel
  local ds = min(t.cell, w) / 2
  local x, y = r.from[1], r.from[2]
  local ex, ey = r.to[1], r.to[2]
  local phi = s:random() * 2 * pi
  local bend, bendM = -1, M
  local pts, sAcc = { x, y }, 0
  local margin = 4 * t.cell
  for _ = 1, 200000 do
    local dx, dy = ex - x, ey - y
    if dx * dx + dy * dy < (2 * ds) ^ 2 then break end
    if floor(phi / pi) ~= bend then                -- a new bend: its own length
      bend = floor(phi / pi)
      bendM = M * (1 + T.BEND_SPREAD * (2 * s:random() - 1))
    end
    local th = atan2(dy, dx) + T.OMEGA * sin(phi)
    x, y = x + ds * cos(th), y + ds * sin(th)
    phi = phi + 2 * pi * ds / bendM
    sAcc = sAcc + ds
    pts[#pts + 1] = x; pts[#pts + 1] = y
    if x < t.x0 - margin or x > t.x1 + margin or y < t.y0 - margin or y > t.y1 + margin then break end
  end
  return pts, sAcc
end

-- 3. Rivers: { from = {x, y}, to = {x, y}, width (m) }. The water level
-- falls only downstream: at each point it is the lowest of (ground - BANK)
-- upstream, and never below the end's level (0 at the sea). The channel
-- is parabolic, WIDTH_DEPTH times wider than deep; a floodplain BANK above
-- the water spans FLOODPLAIN widths on each side. The valley walls come
-- from the slope rule (layer 5).
local function layRiver(t, r, s)
  local w = r.width
  local depth = w / T.WIDTH_DEPTH
  local pts, len = riverLine(t, r, s)
  local n = #pts / 2
  -- water level along the line
  local lv, run = {}, math.huge
  local endLevel = t.coastY and 0 or (t:ground(pts[#pts - 1], pts[#pts]) - T.BANK - depth)
  for q = 1, n do
    local g = t:ground(pts[2 * q - 1], pts[2 * q])
    run = min(run, g - T.BANK)
    lv[q] = max(endLevel, run)
  end
  local reach = w / 2 + T.FLOODPLAIN * w
  -- bucket the segments, so each node looks only at nearby ones
  local B, size = {}, reach
  for q = 1, n - 1 do
    local ax, ay, bx, by = pts[2 * q - 1], pts[2 * q], pts[2 * q + 1], pts[2 * q + 2]
    for bi = floor((min(ax, bx) - reach) / size), floor((max(ax, bx) + reach) / size) do
      for bj = floor((min(ay, by) - reach) / size), floor((max(ay, by) + reach) / size) do
        local key = bi * 100003 + bj
        B[key] = B[key] or {}
        local list = B[key]
        list[#list + 1] = q
      end
    end
  end
  for j = 0, t.ny do
    for i = 0, t.nx do
      local x, y = t.x0 + i * t.cell, t.y0 + j * t.cell
      local list = B[floor(x / size) * 100003 + floor(y / size)]
      if list then
        local best, bq, bt = math.huge, nil, 0
        for _, q in ipairs(list) do
          local d, tt = segDist(x, y, pts[2 * q - 1], pts[2 * q], pts[2 * q + 1], pts[2 * q + 2])
          if d < best then best, bq, bt = d, q, tt end
        end
        if best <= reach then
          local L = lv[bq] + (lv[bq + 1] - lv[bq]) * bt
          local k = j * t.stride + i + 1
          if best < w / 2 then
            local bed = L - depth * (1 - (2 * best / w) ^ 2)
            if bed < t.h[k] then t.h[k] = bed end
            if t.h[k] < L - 0.01 and (not t.wl[k] or L < t.wl[k]) then t.wl[k], t.kind[k] = L, "river" end
          elseif L + T.BANK < t.h[k] then
            t.h[k] = L + T.BANK
          end
        end
      end
    end
  end
  -- straight distance between the ends of the part inside the area
  local fx, fy, lx, ly
  for q = 1, n do
    local x, y = pts[2 * q - 1], pts[2 * q]
    if x >= t.x0 and x <= t.x1 and y >= t.y0 and y <= t.y1 then
      if not fx then fx, fy = x, y end
      lx, ly = x, y
    end
  end
  t.rivers[#t.rivers + 1] = { pts = pts, width = w, depth = depth, length = len, level = lv,
                              straight = fx and sqrt((lx - fx) ^ 2 + (ly - fy) ^ 2) or 0 }
end

-- Distance from (x, y) to the nearest river centreline (math.huge if none).
function T:riverDistance(x, y)
  local best = math.huge
  for _, r in ipairs(self.rivers) do
    local p = r.pts
    for q = 1, #p - 3, 2 do best = min(best, (segDist(x, y, p[q], p[q + 1], p[q + 2], p[q + 3]))) end
  end
  return best
end

-- 4. Ponds: spec.ponds = { count, radius = { min, max }, depth } placed at
-- random on dry, fairly level ground away from rivers and the sea (or at
-- given centres, { x, y, r }). The water stands POND_BANK below the lowest
-- ground on a ring of 1.3 radii, so the rim holds it.
local function layPond(t, x, y, R, depth)
  local level = math.huge
  for a = 0, 35 do
    local ang = a * pi / 18
    level = min(level, t:ground(x + 1.3 * R * cos(ang), y + 1.3 * R * sin(ang)))
  end
  level = level - T.POND_BANK
  forNodesNear(t, x - 1.3 * R, y - 1.3 * R, x + 1.3 * R, y + 1.3 * R, function(k, nx, ny)
    local r = sqrt((nx - x) ^ 2 + (ny - y) ^ 2)
    if r < R then
      local bed = level - depth * (1 - (r / R) ^ 2)
      if bed < t.h[k] then t.h[k] = bed end
      if t.h[k] < level - 0.01 then t.wl[k], t.kind[k] = level, "pond" end
    elseif r < 1.3 * R and level + T.POND_BANK < t.h[k] then
      t.h[k] = level + T.POND_BANK
    end
  end)
  t.ponds[#t.ponds + 1] = { x = x, y = y, r = R, depth = depth, level = level }
end

local function layPonds(t, p, s)
  for _, c in ipairs(p.at or {}) do layPond(t, c[1], c[2], c[3], p.depth or 2) end
  local placed, tries = 0, 0
  while placed < (p.count or 0) and tries < 2000 do
    tries = tries + 1
    local R = p.radius[1] + (p.radius[2] - p.radius[1]) * s:random()
    local m = 1.5 * R + 2 * t.cell
    local x = t.x0 + m + (t.x1 - t.x0 - 2 * m) * s:random()
    local y = t.y0 + m + (t.y1 - t.y0 - 2 * m) * s:random()
    local ok = not (t.coastY and y - t.coastY(x) < 4 * R + 200) and t:riverDistance(x, y) > 3 * R + 50
    for _, q in ipairs(t.ponds) do
      if sqrt((q.x - x) ^ 2 + (q.y - y) ^ 2) < 3 * (q.r + R) then ok = false end
    end
    if ok then                                   -- fairly level: < 6 m across the site
      local lo, hi = math.huge, -math.huge
      for a = 0, 11 do
        local g = t:ground(x + 1.3 * R * cos(a * pi / 6), y + 1.3 * R * sin(a * pi / 6))
        lo, hi = min(lo, g), max(hi, g)
      end
      ok = hi - lo < 6 and t:ground(x, y) > 1
    end
    if ok then layPond(t, x, y, R, p.depth or 2); placed = placed + 1 end
  end
end

-- 5. The slope rule. Water nodes (and the seabed) are fixed at their water
-- level (0 for the sea); every dry node is lowered until no dry slope
-- along the grid exceeds maxSlope: h = min(h, h_nb + maxSlope * dist) over
-- the 8 neighbours, swept forward and back until nothing changes. The
-- result is the highest ground under the original with that property;
-- nothing is raised.
local function limitSlope(t)
  local s, c, S = t.stride, t.cell, t.maxSlope
  local d1, d2 = S * c, S * c * sqrt(2)
  local h, wl = t.h, t.wl
  local val, fixed = {}, {}
  for k = 1, s * (t.ny + 1) do
    if wl[k] then fixed[k], val[k] = true, wl[k]
    elseif h[k] < 0 then fixed[k], val[k] = true, 0
    else val[k] = h[k] end
  end
  local nx, ny = t.nx, t.ny
  for _ = 1, 50 do
    local changed = false
    for j = 0, ny do                               -- forward: from below and the left
      for i = 0, nx do
        local k = j * s + i + 1
        if not fixed[k] then
          local v = val[k]
          if i > 0 and val[k - 1] + d1 < v then v = val[k - 1] + d1 end
          if j > 0 then
            if val[k - s] + d1 < v then v = val[k - s] + d1 end
            if i > 0 and val[k - s - 1] + d2 < v then v = val[k - s - 1] + d2 end
            if i < nx and val[k - s + 1] + d2 < v then v = val[k - s + 1] + d2 end
          end
          if v < val[k] then val[k] = v; changed = true end
        end
      end
    end
    for j = ny, 0, -1 do                           -- backward: from above and the right
      for i = nx, 0, -1 do
        local k = j * s + i + 1
        if not fixed[k] then
          local v = val[k]
          if i < nx and val[k + 1] + d1 < v then v = val[k + 1] + d1 end
          if j < ny then
            if val[k + s] + d1 < v then v = val[k + s] + d1 end
            if i < nx and val[k + s + 1] + d2 < v then v = val[k + s + 1] + d2 end
            if i > 0 and val[k + s - 1] + d2 < v then v = val[k + s - 1] + d2 end
          end
          if v < val[k] then val[k] = v; changed = true end
        end
      end
    end
    if not changed then break end
  end
  for k = 1, s * (t.ny + 1) do if not fixed[k] then h[k] = val[k] end end
end

-- 6. Dredging: { shape, depth, run = DREDGE_RUN, name } lowers the ground
-- to -depth inside the shape and up at 1:run outside it (run 0: a
-- vertical quay wall). Named cuts are kept in t.dredged for the checks
-- and for placing ships later.
local function layDredge(t, d)
  local run = d.run or T.DREDGE_RUN
  local margin = run * (d.depth + 30)
  local bx0, by0, bx1, by1 = shapeBox(d.shape, margin)
  forNodesNear(t, bx0, by0, bx1, by1, function(k, x, y)
    local sd = T.shapeDist(d.shape, x, y)
    local target = sd <= 0 and -d.depth or (run > 0 and -d.depth + sd / run or math.huge)
    if target < t.h[k] then t.h[k] = target end
  end)
  t.dredged[#t.dredged + 1] = d
end

-- 7. The sea: every node below 0 that is connected (4-neighbours) to a
-- boundary node below 0 gets water at level 0. Ground below 0 that is
-- not connected (a dip behind the shore) is raised to 0.2 m, so all water
-- below sea level is sea.
local function laySea(t)
  local s = t.stride
  local stack = {}
  for i = 0, t.nx do
    for _, j in ipairs({ 0, t.ny }) do stack[#stack + 1] = j * s + i + 1 end
  end
  for j = 0, t.ny do
    for _, i in ipairs({ 0, t.nx }) do stack[#stack + 1] = j * s + i + 1 end
  end
  local sea = {}
  while #stack > 0 do
    local k = table.remove(stack)
    if not sea[k] and t.h[k] < 0 then
      sea[k] = true
      t.wl[k], t.kind[k] = 0, "sea"
      local i, j = (k - 1) % s, floor((k - 1) / s)
      if i > 0 then stack[#stack + 1] = k - 1 end
      if i < t.nx then stack[#stack + 1] = k + 1 end
      if j > 0 then stack[#stack + 1] = k - s end
      if j < t.ny then stack[#stack + 1] = k + s end
    end
  end
  local raised = 0
  for k = 1, s * (t.ny + 1) do
    if t.h[k] < 0 and not sea[k] then t.h[k] = 0.2; raised = raised + 1 end
  end
  t.raised = raised
end

-- Builds a terrain from a spec (see lib/places.lua):
-- { name, bounds = { x0, y0, x1, y1 }, cell, seed, maxSlope, land, coast,
--   fill = { ... }, rivers = { ... }, ponds = { ... }, dredge = { ... } }
function T.generate(spec)
  local t0 = os.clock()
  local t = newGrid(spec)
  local s = rng.new(spec.seed or 1)
  t.seed = spec.seed or 1
  layLand(t, spec, s)
  for _, f in ipairs(spec.fill or {}) do layFill(t, f) end
  for _, r in ipairs(spec.rivers or {}) do layRiver(t, r, s) end
  if spec.ponds then layPonds(t, spec.ponds, s) end
  -- sloped cuts before the slope rule, which then eases their dry part;
  -- quay walls (run 0) after it, so they stay vertical
  for _, d in ipairs(spec.dredge or {}) do if (d.run or T.DREDGE_RUN) > 0 then layDredge(t, d) end end
  limitSlope(t)
  for _, d in ipairs(spec.dredge or {}) do if (d.run or T.DREDGE_RUN) == 0 then layDredge(t, d) end end
  laySea(t)
  t.buildTime = os.clock() - t0
  return t
end

--------------------------------------------------------------------------
-- Measures
--------------------------------------------------------------------------

-- Shares of the area (by node) that are dry, sea, river, pond; the
-- deepest water; the steepest dry triangle and the 99.9th percentile of
-- dry triangles' slopes. A triangle is dry when all three nodes are.
function T:stats()
  local n, counts, deepest = 0, { sea = 0, river = 0, pond = 0 }, 0
  local s = self.stride
  for k = 1, s * (self.ny + 1) do
    n = n + 1
    local kd = self.kind[k]
    if kd then
      counts[kd] = counts[kd] + 1
      deepest = max(deepest, self.wl[k] - self.h[k])
    end
  end
  local slopes = {}
  self:eachTriangle(function(k, upper, a, b, c)
    if not (self.wl[a] or self.wl[b] or self.wl[c]) then slopes[#slopes + 1] = triSlope(self, k, upper) end
  end)
  table.sort(slopes)
  local wet = counts.sea + counts.river + counts.pond
  return { land = 1 - wet / n, sea = counts.sea / n, river = counts.river / n, pond = counts.pond / n,
           deepest = deepest, maxSlope = slopes[#slopes] or 0,
           slope999 = slopes[max(1, floor(0.999 * #slopes))] or 0, triangles = 2 * self.nx * self.ny }
end

function T:checksum()
  local sum = 0
  for k = 1, self.stride * (self.ny + 1) do
    sum = (sum + self.h[k] * ((k % 97) + 1) + (self.wl[k] or 0) * ((k % 89) + 3)) % 1e9
  end
  return sum
end

--------------------------------------------------------------------------
-- BPP geometry
--------------------------------------------------------------------------

-- Colours by what the ground is: seabed and beds darken with depth, a
-- beach within 1.5 m of the sea, grass that browns with height and with
-- slope near the limit.
local function rgb(hex) return tonumber(hex:sub(2, 3), 16), tonumber(hex:sub(4, 5), 16), tonumber(hex:sub(6, 7), 16) end
local function mix(a, b, f)
  f = min(1, max(0, f))
  return a[1] + (b[1] - a[1]) * f, a[2] + (b[2] - a[2]) * f, a[3] + (b[3] - a[3]) * f
end
local C = { sand = { rgb("#d6c48c") }, deep = { rgb("#1d3550") }, bed = { rgb("#6f6550") },
            low = { rgb("#6f9a4c") }, high = { rgb("#8b8a5e") }, steep = { rgb("#9a8466") } }

function T:triangleColor(a, b, c, hiRef)
  local h, wl = self.h, self.wl
  local hm = (h[a] + h[b] + h[c]) / 3
  local wet = wl[a] or wl[b] or wl[c]
  if wet then
    local L = (wl[a] or wl[b] or wl[c])
    local depth = L - hm
    if (self.kind[a] or self.kind[b] or self.kind[c]) == "sea" then
      return mix(C.sand, C.deep, (depth - 1) / 20)
    end
    return mix(C.bed, C.deep, depth / 6)
  end
  if hm < 1.5 and self.nearSea and (self.nearSea[a] or self.nearSea[b] or self.nearSea[c]) then
    return C.sand[1], C.sand[2], C.sand[3]
  end
  local r, g, bl = mix(C.low, C.high, (hm - self.loRef) / max(1, hiRef - self.loRef))
  return r, g, bl
end

local CF_STATIC, CF_NO_CONTACT = 1, 4

-- The ground as one static mesh (per-triangle colours) and the water as
-- one translucent mesh: a plane at 0 over the whole area for the sea (dry
-- ground stands above it) and a flat quad at the water level for every
-- river or pond cell. opts: scale (m -> BPP units, default 1), base (BPP
-- y of sea level, default 0), contact = true to let bodies collide with
-- the ground (default: no contact response, like the rest of lib/world).
-- Returns { ground, water }.
function T:toBPP(viewer, opts)
  opts = opts or {}
  local S, base = opts.scale or 1, opts.base or 0
  local s = self.stride
  local function V(k, hh)
    local x, y = self:nodeXY(k)
    return btVector3(x * S, base + (hh or self.h[k]) * S, -y * S)
  end
  -- which dry nodes touch the sea (for the beach colour)
  self.nearSea = {}
  local lo, hi = math.huge, -math.huge
  for k = 1, s * (self.ny + 1) do
    if self.kind[k] == "sea" then
      local i = (k - 1) % s
      for _, d in ipairs({ -1, 1, -s, s, -s - 1, -s + 1, s - 1, s + 1 }) do
        local q = k + d
        if self.h[q] and abs(((q - 1) % s) - i) <= 1 then
          self.nearSea[q] = self.nearSea[q] or (not self.wl[q])
        end
      end
    elseif not self.wl[k] then
      lo, hi = min(lo, self.h[k]), max(hi, self.h[k])
    end
  end
  -- spread "near the sea" two nodes inland, so beaches are a band
  for _ = 1, 2 do
    local add = {}
    for k in pairs(self.nearSea) do
      for _, d in ipairs({ -1, 1, -s, s }) do
        local q = k + d
        if self.h[q] and not self.wl[q] and self.h[q] < 1.5 then add[q] = true end
      end
    end
    for k in pairs(add) do self.nearSea[k] = true end
  end
  self.loRef = lo
  local ground = Terrain()
  local idx = 0
  local colours = {}
  self:eachTriangle(function(k, upper, a, b, c)
    -- (x, y, z) -> (x, z, -y) is a rotation, so the corners keep their
    -- order and faces point up
    ground:addTriangle(V(a), V(b), V(c))
    local r, g, bl = self:triangleColor(a, b, c, hi)
    colours[idx] = { r, g, bl }
    idx = idx + 1
  end)
  ground:build()
  ground.col = "#6f9a4c"
  for i = 0, idx - 1 do
    local col = colours[i]
    ground:setTriangleColor(i, floor(col[1] + 0.5), floor(col[2] + 0.5), floor(col[3] + 0.5))
  end
  viewer:add(ground)
  if not opts.contact then pcall(function() ground.body:setCollisionFlags(CF_STATIC + CF_NO_CONTACT) end) end

  local water = Terrain()
  local nWater = 0
  local anySea = false
  for k = 1, s * (self.ny + 1) do if self.kind[k] == "sea" then anySea = true; break end end
  if anySea then
    local x0, y0, x1, y1 = self.x0 * S, self.y0 * S, self.x1 * S, self.y1 * S
    local A, B = btVector3(x0, base, -y0), btVector3(x1, base, -y0)
    local Cc, D = btVector3(x1, base, -y1), btVector3(x0, base, -y1)
    water:addTriangle(A, B, Cc); water:addTriangle(A, Cc, D)
    nWater = 2
  end
  for j = 0, self.ny - 1 do
    for i = 0, self.nx - 1 do
      local k = j * s + i + 1
      local sum, n = 0, 0
      for _, q in ipairs({ k, k + 1, k + s, k + s + 1 }) do
        local kd = self.kind[q]
        if kd == "river" or kd == "pond" then sum, n = sum + self.wl[q], n + 1 end
      end
      if n > 0 then
        local L = sum / n
        local a, b, c, d = V(k, L), V(k + 1, L), V(k + s + 1, L), V(k + s, L)
        water:addTriangle(a, b, c); water:addTriangle(a, c, d)
        nWater = nWater + 2
      end
    end
  end
  local objs = { ground = ground }
  if nWater > 0 then
    water:build()
    water.col = opts.waterColor or "#2f6fa8"
    water.transparency = opts.waterTransparency or 0.45
    water.castShadow = false
    viewer:add(water)
    pcall(function() water.body:setCollisionFlags(CF_STATIC + CF_NO_CONTACT) end)
    objs.water = water
  end
  return objs
end

return T
