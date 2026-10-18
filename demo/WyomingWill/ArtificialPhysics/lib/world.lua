--
-- lib/world.lua -- the world generator's core (BOOK.md G21)
--
-- One description of a world, built from simple pieces, gives every output a
-- port needs: BPP geometry, an occupancy grid, and masks for the metrics. It
-- is our own; nothing in it comes from the old map makers of Zarzhitsky's CPT
-- code (MakeMap.c for Textron, MapGen.c). M0 has the core and the book's
-- presets; the harbour features (BOOK.md section 6) come with the
-- milestones that use them.
--
-- A world is 2D footprints with heights, in the book's own units (NetLogo
-- patches, inches, ...): discs, rotated rectangles, triangles and walls
-- (thin rectangles), plus named regions (start, goal) and an optional cell
-- tiling for the metrics. Book (x, y) maps to BPP (x, -z), with y up, so a
-- camera looking down -z sees the world as the book's figures draw it;
-- toBPP() scales it. world.bppZ(y, scale) gives the same mapping.
--
--   local World = require "lib.world"
--   local w = World.preset("ch07-corridor", { percent = 30, seed = 4 })
--   w:blocked(x, y)          -- inside an obstacle or wall?
--   w:cellOf(x, y)           -- index into the cell tiling, or nil
--   w:occupancy()            -- per-cell obstacle fraction (sampled)
--   w:obstacleFraction()     -- share of the interior covered
--   w:shadowCells()          -- Ch. 7's cells just downstream of obstacles
--   w:toBPP(v, { scale = 0.1 })   -- builds static, non-colliding objects
--   w:writeGrid(path)        -- the occupancy grid as text
--   w:checksum()             -- a number that changes if any piece changes
--
-- RANDOM WORLDS draw from their own stream (rng.new(seed)), never the shared
-- one, so building a world does not change the agents' random numbers, and
-- the same seed always gives the same world.
--
-- writeCPT() writes Zarzhitsky's map format, so his PlumeGen and TraceGen
-- (CPT code, kept outside the repo) can run on our worlds as a check. His
-- map makers (MakeMap.c for Textron, MapGen.c) are not used.
--

local rng = require "lib.rng"

local World = {}
World.__index = World

local sqrt, floor, abs, cos, sin, pi = math.sqrt, math.floor, math.abs, math.cos, math.sin, math.pi
local atan2 = math.atan2 or function(y, x) return math.atan(y, x) end -- Lua 5.3+ dropped atan2

-- A new, empty world. opts: name, units, bounds = { x0, y0, x1, y1 } (the
-- interior agents may use), height (default obstacle height), seed.
function World.new(opts)
  opts = opts or {}
  local w = setmetatable({}, World)
  w.name = opts.name or "world"
  w.units = opts.units or "units"
  local b = opts.bounds or { -50, -50, 50, 50 }
  w.bounds = { x0 = b[1], y0 = b[2], x1 = b[3], y1 = b[4] }
  w.height = opts.height or 10
  w.seed = opts.seed
  w.pieces = {}            -- { kind = "disc"|"rect"|"tri", tag, ... }
  w.regions = {}           -- name -> { x0, y0, x1, y1 } or { x, y }
  w.notes = {}             -- choices made where the book is silent
  return w
end

local function add(w, piece)
  piece.tag = piece.tag or "obstacle"
  piece.h = piece.h or w.height
  w.pieces[#w.pieces + 1] = piece
  return piece
end

function World:disc(x, y, r, tag, h)
  return add(self, { kind = "disc", x = x, y = y, r = r, tag = tag, h = h })
end

-- Rectangle centred at (cx, cy), size sx by sy, turned by angle (radians).
function World:rect(cx, cy, sx, sy, angle, tag, h)
  return add(self, { kind = "rect", x = cx, y = cy, sx = sx, sy = sy, a = angle or 0, tag = tag, h = h })
end

function World:tri(x1, y1, x2, y2, x3, y3, tag, h)
  return add(self, { kind = "tri", p = { x1, y1, x2, y2, x3, y3 }, tag = tag, h = h })
end

-- A wall from (x0, y0) to (x1, y1) of the given thickness (a thin rect).
function World:wall(x0, y0, x1, y1, thick, h)
  local dx, dy = x1 - x0, y1 - y0
  local len = sqrt(dx * dx + dy * dy)
  return self:rect((x0 + x1) / 2, (y0 + y1) / 2, len, thick or 1, atan2(dy, dx), "wall", h)
end

-- Walls just outside the bounds, so the interior is exactly the bounds.
function World:boxWalls(thick, h)
  local b, t = self.bounds, thick or 1
  self:wall(b.x0 - t, b.y0 - t / 2, b.x1 + t, b.y0 - t / 2, t, h)
  self:wall(b.x0 - t, b.y1 + t / 2, b.x1 + t, b.y1 + t / 2, t, h)
  self:wall(b.x0 - t / 2, b.y0, b.x0 - t / 2, b.y1, t, h)
  self:wall(b.x1 + t / 2, b.y0, b.x1 + t / 2, b.y1, t, h)
end

function World:region(name, x0, y0, x1, y1)
  if x1 then self.regions[name] = { x0 = x0, y0 = y0, x1 = x1, y1 = y1 }
  else self.regions[name] = { x = x0, y = y0 } end
end

-- The cell tiling for the metrics: nx by ny cells over the bounds (or over
-- the rectangle given).
function World:cells(nx, ny, x0, y0, x1, y1)
  local b = self.bounds
  self.grid = { nx = nx, ny = ny, x0 = x0 or b.x0, y0 = y0 or b.y0, x1 = x1 or b.x1, y1 = y1 or b.y1 }
  self.grid.dx = (self.grid.x1 - self.grid.x0) / nx
  self.grid.dy = (self.grid.y1 - self.grid.y0) / ny
end

-- Index (1-based, row-major from the low corner) of the cell holding (x, y).
-- Points on an inner boundary go to the higher cell, except at the top edge.
function World:cellOf(x, y)
  local g = self.grid
  if not g or x < g.x0 or x > g.x1 or y < g.y0 or y > g.y1 then return nil end
  local i = math.min(g.nx - 1, floor((x - g.x0) / g.dx))
  local j = math.min(g.ny - 1, floor((y - g.y0) / g.dy))
  return j * g.nx + i + 1, i, j
end

-- Point tests for each kind of piece.
local function inPiece(p, x, y)
  if p.kind == "disc" then
    local dx, dy = x - p.x, y - p.y
    return dx * dx + dy * dy <= p.r * p.r
  elseif p.kind == "rect" then
    local c, s = cos(-p.a), sin(-p.a)
    local dx, dy = x - p.x, y - p.y
    local u, v = dx * c - dy * s, dx * s + dy * c
    return abs(u) <= p.sx / 2 and abs(v) <= p.sy / 2
  else
    local q = p.p
    local function side(ax, ay, bx, by) return (bx - ax) * (y - ay) - (by - ay) * (x - ax) end
    local d1 = side(q[1], q[2], q[3], q[4])
    local d2 = side(q[3], q[4], q[5], q[6])
    local d3 = side(q[5], q[6], q[1], q[2])
    local neg = d1 < 0 or d2 < 0 or d3 < 0
    local pos = d1 > 0 or d2 > 0 or d3 > 0
    return not (neg and pos)
  end
end

-- Bounding box of a piece (for fast rejection and placement).
local function bbox(p)
  if p.kind == "disc" then return p.x - p.r, p.y - p.r, p.x + p.r, p.y + p.r end
  if p.kind == "rect" then
    local c, s = abs(cos(p.a)), abs(sin(p.a))
    local hx, hy = (p.sx * c + p.sy * s) / 2, (p.sx * s + p.sy * c) / 2
    return p.x - hx, p.y - hy, p.x + hx, p.y + hy
  end
  local q = p.p
  return math.min(q[1], q[3], q[5]), math.min(q[2], q[4], q[6]), math.max(q[1], q[3], q[5]), math.max(q[2], q[4], q[6])
end
World.bbox = bbox

-- A bucket index of the pieces (rebuilt when pieces are added), so point
-- tests look only at nearby pieces.
local function index(w)
  if w.idx and w.idx.n == #w.pieces then return w.idx end
  local b = w.bounds
  local size = math.max(b.x1 - b.x0, b.y1 - b.y0) / 64
  local idx = { n = #w.pieces, size = size, x0 = b.x0 - size, y0 = b.y0 - size, cells = {} }
  for k, p in ipairs(w.pieces) do
    p.bb = { bbox(p) }
    local bb = p.bb
    for i = floor((bb[1] - idx.x0) / size), floor((bb[3] - idx.x0) / size) do
      for j = floor((bb[2] - idx.y0) / size), floor((bb[4] - idx.y0) / size) do
        local key = i * 100003 + j
        local list = idx.cells[key]
        if not list then list = {}; idx.cells[key] = list end
        list[#list + 1] = k
      end
    end
  end
  w.idx = idx
  return idx
end

-- Is (x, y) inside any piece (or outside the bounds)? tag limits the test to
-- pieces with that tag (and then the bounds don't count).
function World:blocked(x, y, tag)
  local b = self.bounds
  if not tag and (x < b.x0 or x > b.x1 or y < b.y0 or y > b.y1) then return true end
  local idx = index(self)
  local list = idx.cells[floor((x - idx.x0) / idx.size) * 100003 + floor((y - idx.y0) / idx.size)]
  if not list then return false end
  for _, k in ipairs(list) do
    local p = self.pieces[k]
    if not tag or p.tag == tag then
      local bb = p.bb
      if x >= bb[1] and x <= bb[3] and y >= bb[2] and y <= bb[4] and inPiece(p, x, y) then return true end
    end
  end
  return false
end

-- Per-cell obstacle fraction of the cell tiling, sampled on k x k points per
-- cell (default 8). Returns a table indexed like cellOf().
function World:occupancy(k)
  local g = assert(self.grid, "world has no cell tiling (cells())")
  k = k or 8
  local occ = {}
  for j = 0, g.ny - 1 do
    for i = 0, g.nx - 1 do
      local n = 0
      for a = 0, k - 1 do
        for b = 0, k - 1 do
          local x = g.x0 + (i + (a + 0.5) / k) * g.dx
          local y = g.y0 + (j + (b + 0.5) / k) * g.dy
          if self:blocked(x, y, "obstacle") then n = n + 1 end
        end
      end
      occ[j * g.nx + i + 1] = n / (k * k)
    end
  end
  return occ
end

-- Share of the interior covered by obstacles (walls excluded), on an
-- m x m sample grid (default 400).
function World:obstacleFraction(m)
  m = m or 400
  local b, n = self.bounds, 0
  local dx, dy = (b.x1 - b.x0) / m, (b.y1 - b.y0) / m
  for a = 0, m - 1 do
    for c = 0, m - 1 do
      if self:blocked(b.x0 + (a + 0.5) * dx, b.y0 + (c + 0.5) * dy, "obstacle") then n = n + 1 end
    end
  end
  return n / (m * m)
end

-- Ch. 7's "shadow" cells (Fig. 7.9B-C): free cells just downstream of an
-- obstacle cell, downstream meaning toward the goal along +y. A cell counts
-- as an obstacle cell when more than half of it is covered. Returns a set
-- of cell indices and their count.
function World:shadowCells(occ)
  local g = assert(self.grid, "world has no cell tiling (cells())")
  occ = occ or self:occupancy()
  local set, n = {}, 0
  for j = 1, g.ny - 1 do
    for i = 0, g.nx - 1 do
      local here, up = j * g.nx + i + 1, (j - 1) * g.nx + i + 1
      if occ[here] <= 0.5 and occ[up] > 0.5 then set[here] = true; n = n + 1 end
    end
  end
  return set, n
end

-- A number that changes if any piece changes (to check that a seed
-- repeats its world exactly).
function World:checksum()
  local s = 0
  for i, p in ipairs(self.pieces) do
    local vals = p.kind == "tri" and p.p or { p.x, p.y, p.r or 0, p.sx or 0, p.sy or 0, p.a or 0 }
    for k, val in ipairs(vals) do s = (s + val * (i * 31 + k * 7)) % 1e9 end
  end
  return s
end

function World:summary()
  local counts = {}
  for _, p in ipairs(self.pieces) do counts[p.tag .. " " .. p.kind] = (counts[p.tag .. " " .. p.kind] or 0) + 1 end
  local parts = {}
  for k, n in pairs(counts) do parts[#parts + 1] = n .. " " .. k end
  table.sort(parts)
  local b = self.bounds
  return string.format("%s: %g x %g %s, %s%s", self.name, b.x1 - b.x0, b.y1 - b.y0, self.units,
    table.concat(parts, ", "), self.grid and string.format(", %d x %d cells", self.grid.nx, self.grid.ny) or "")
end

-- The occupancy grid as text: one row per line from the top, '#' for a
-- cell more than half covered, '.' otherwise (for reading; writeCPT gives
-- Zarzhitsky's format).
function World:writeGrid(path, occ)
  local g = assert(self.grid, "world has no cell tiling (cells())")
  occ = occ or self:occupancy()
  local f = assert(io.open(path, "w"))
  f:write(string.format("# %s\n# %d x %d cells of %g x %g %s; '#' = obstacle (> half covered)\n",
    self:summary(), g.nx, g.ny, g.dx, g.dy, self.units))
  for j = g.ny - 1, 0, -1 do
    local row = {}
    for i = 0, g.nx - 1 do row[#row + 1] = occ[j * g.nx + i + 1] > 0.5 and "#" or "." end
    f:write(table.concat(row), "\n")
  end
  f:close()
end

-- Zarzhitsky's map format, as read by his PlumeGen and TraceGen (CPT code,
-- MapUtils.h, PlumeGen.c read_map_file): a text file of nx lines of ny
-- characters, ' ' open and 'b' blocked, line i holding x cell i and
-- character j y cell j (MAP.world[i * ny + j]). This lets his plume and
-- tracing programs run on our worlds as an independent check of our port;
-- we do not use his map makers.
-- Any size: our worlds have no size limit. His reader as shipped accepts
-- only square maps up to 1024 (#define MAX_WORLD_WIDTH and a square check
-- in read_map_file, PlumeGen.c), and his Scenario.h expects 128 with the
-- emitter at cell (12, 39); for other sizes change those in a copy of his
-- code.
-- opts: x0, y0 (low corner) and dx (cell size; default: the bounds split
-- into nx by ny cells), k = samples per cell side (default 3). A cell is
-- blocked when more than half its samples are; cells outside the bounds
-- are blocked. Returns the blocked share.
function World:writeCPT(path, nx, ny, opts)
  opts = opts or {}
  local b = self.bounds
  nx = nx or 128
  ny = ny or nx
  local x0, y0 = opts.x0 or b.x0, opts.y0 or b.y0
  local dx = opts.dx or (b.x1 - b.x0) / nx
  local dy = opts.dy or opts.dx or (b.y1 - b.y0) / ny
  local k = opts.k or 3
  local f = assert(io.open(path, "w"))
  local blocked = 0
  for i = 0, nx - 1 do
    local row = {}
    for j = 0, ny - 1 do
      local hits = 0
      for a = 0, k - 1 do
        for c = 0, k - 1 do
          if self:blocked(x0 + (i + (a + 0.5) / k) * dx, y0 + (j + (c + 0.5) / k) * dy) then hits = hits + 1 end
        end
      end
      local isB = hits * 2 > k * k
      if isB then blocked = blocked + 1 end
      row[#row + 1] = isB and "b" or " "
    end
    f:write(table.concat(row), "\n")
  end
  f:close()
  return blocked / (nx * ny)
end

--------------------------------------------------------------------------
-- Random obstacle fields
--------------------------------------------------------------------------

-- Scatter random obstacles until they cover `fraction` of a rectangle
-- (opts.area = { x0, y0, x1, y1 }, default the bounds). opts: seed, shapes
-- (a list of "rect", "tri", "disc"), size = { min, max } (a shape's
-- extent), keep = rectangles to keep clear (start, goal), tolerance
-- (default 0.0025). Overlaps are allowed and coverage is measured on the
-- union, on a raster of square cells (opts.resolution across, default
-- 250). A candidate that would overshoot the target by more than the
-- tolerance is rejected, so the result lands within it. Returns the
-- fraction reached.
function World:scatter(fraction, opts)
  opts = opts or {}
  local s = rng.new(opts.seed or self.seed or 1)
  local function U(a, b) return a + (b - a) * s:random() end
  local area = opts.area or { self.bounds.x0, self.bounds.y0, self.bounds.x1, self.bounds.y1 }
  local shapes = opts.shapes or { "rect", "tri", "disc" }
  local smin, smax = (opts.size or {})[1] or 20, (opts.size or {})[2] or 100
  local keep, tol = opts.keep or {}, opts.tolerance or 0.0025
  local ax0, ay0, ax1, ay1 = area[1], area[2], area[3], area[4]
  local mx = opts.resolution or 250
  local cell = (ax1 - ax0) / mx
  local my = math.ceil((ay1 - ay0) / cell)
  local covered, ncov = {}, 0
  local total = mx * my
  -- raster cells a piece covers that are not covered yet
  local function newCells(p)
    local list = {}
    local bx0, by0, bx1, by1 = bbox(p)
    for i = math.max(0, floor((bx0 - ax0) / cell)), math.min(mx - 1, floor((bx1 - ax0) / cell)) do
      for j = math.max(0, floor((by0 - ay0) / cell)), math.min(my - 1, floor((by1 - ay0) / cell)) do
        local idx = j * mx + i
        if not covered[idx] and inPiece(p, ax0 + (i + 0.5) * cell, ay0 + (j + 0.5) * cell) then
          list[#list + 1] = idx
        end
      end
    end
    return list
  end
  local function commit(list)
    for _, idx in ipairs(list) do covered[idx] = true end
    ncov = ncov + #list
  end
  for _, p in ipairs(self.pieces) do if p.tag == "obstacle" then commit(newCells(p)) end end
  local function clear(p)
    local bx0, by0, bx1, by1 = bbox(p)
    for _, k in ipairs(keep) do
      if bx1 >= k[1] and bx0 <= k[3] and by1 >= k[2] and by0 <= k[4] then return false end
    end
    return bx0 >= ax0 and bx1 <= ax1 and by0 >= ay0 and by1 <= ay1
  end
  local tries = 0
  while ncov / total < fraction - tol and tries < 200000 do
    tries = tries + 1
    local kind = shapes[floor(s:random() * #shapes) + 1]
    local size = U(smin, smax)
    local cx, cy = U(ax0, ax1), U(ay0, ay1)
    local p
    if kind == "disc" then
      p = { kind = "disc", x = cx, y = cy, r = size / 2 }
    elseif kind == "rect" then
      p = { kind = "rect", x = cx, y = cy, sx = size, sy = U(0.3, 1) * size, a = U(0, pi) }
    else
      local a0, r, pts = U(0, 2 * pi), size / 2, {}
      for k = 0, 2 do
        local ang = a0 + k * 2 * pi / 3 + U(-0.4, 0.4)
        pts[#pts + 1] = cx + r * cos(ang); pts[#pts + 1] = cy + r * sin(ang)
      end
      p = { kind = "tri", p = pts }
    end
    p.tag, p.h = "obstacle", self.height
    if clear(p) then
      local list = newCells(p)
      if #list > 0 and (ncov + #list) / total <= fraction + tol then
        commit(list)
        self.pieces[#self.pieces + 1] = p
      end
    end
  end
  return ncov / total
end

--------------------------------------------------------------------------
-- Building BPP geometry
--------------------------------------------------------------------------

-- Static objects with no contact response, so agents moved by hand never
-- collide with them unless a port asks for it. opts: scale (world units ->
-- BPP units, default 1), base (BPP y of the floor, default 0), floor = true
-- to lay a floor, cellFloor = true to colour the cell tiling as
-- Uniform_Coverage does, mask = a set of cell indices to highlight, colors.
-- Returns the list of objects (to remove with v:remove later).
local CF_STATIC, CF_NO_CONTACT = 1, 4

function World:toBPP(viewer, opts)
  opts = opts or {}
  local S = opts.scale or 1
  local base = opts.base or 0
  local col = opts.colors or {}
  local objs = {}
  local function put(o, c)
    o.col = c
    viewer:add(o)
    pcall(function() o.body:setCollisionFlags(CF_STATIC + CF_NO_CONTACT) end)
    objs[#objs + 1] = o
    return o
  end
  local hS = function(p) return (p.h or self.height) * S end
  -- book y -> BPP -z, so a camera looking down -z with y up sees the world
  -- as the book draws it (x to the right, y up the page)
  local function Z(y) return -y * S end
  for k, p in ipairs(self.pieces) do
    local c = (p.tag == "wall") and (col.wall or "#ffff00") or (col[p.tag] or col.obstacle or "#888888")
    -- overlapping pieces of one height would share a top face and flicker
    -- (z-fighting), so the drawn height is staggered by under 1%
    local h = hS(p) * (1 + 0.0013 * (k % 7))
    if p.kind == "disc" then
      local o = Cylinder(p.r * S, h, 0)
      o.trans = btTransform(btQuaternion(btVector3(1, 0, 0), pi / 2), btVector3(p.x * S, base + h / 2, Z(p.y)))
      put(o, c)
    elseif p.kind == "rect" then
      local o = Cube(p.sx * S, h, p.sy * S, 0)
      -- with y -> -z, a turn by a about book-up is +a about BPP y
      o.trans = btTransform(btQuaternion(btVector3(0, 1, 0), p.a), btVector3(p.x * S, base + h / 2, Z(p.y)))
      put(o, c)
    else
      local q = p.p
      local function V(k, y) return btVector3(q[2 * k - 1] * S, y, Z(q[2 * k])) end
      local top, bot = base + h, base
      put(Triangle(V(1, top), V(2, top), V(3, top), 0), c)
      for k = 1, 3 do
        local k2 = k % 3 + 1
        put(Triangle(V(k, bot), V(k2, bot), V(k2, top), 0), c)
        put(Triangle(V(k, bot), V(k2, top), V(k, top), 0), c)
      end
    end
  end
  if opts.cellFloor and self.grid then
    local g = self.grid
    for j = 0, g.ny - 1 do
      for i = 0, g.nx - 1 do
        local idx = j * g.nx + i + 1
        local c
        if opts.mask and opts.mask[idx] then c = col.mask or "#ff00ff"
        elseif opts.cellColor then c = opts.cellColor(i, j, idx)
        else c = ((i + j) % 2 == 0) and (col.cellA or "#2a2a3a") or (col.cellB or "#3a3a4a") end
        local o = Cube(g.dx * S, 0.02 * (g.dx * S), g.dy * S, 0)
        o.pos = btVector3((g.x0 + (i + 0.5) * g.dx) * S, base - 0.01 * g.dx * S, Z(g.y0 + (j + 0.5) * g.dy))
        put(o, c)
      end
    end
  elseif opts.floor ~= false then
    local b = self.bounds
    local o = Cube((b.x1 - b.x0) * S, 0.5, (b.y1 - b.y0) * S, 0)
    o.pos = btVector3((b.x0 + b.x1) / 2 * S, base - 0.25, Z((b.y0 + b.y1) / 2))
    put(o, col.floor or "#303038")
  end
  for name, r in pairs(self.regions) do
    local c = col[name] or (name == "goal" and "#3070ff" or "#40c040")
    if r.x then
      local o = Sphere((opts.markerSize or 2) * S, 0)
      o.pos = btVector3(r.x * S, base + (opts.markerSize or 2) * S, Z(r.y))
      put(o, c)
    else
      local o = Cube((r.x1 - r.x0) * S, 0.04 * (r.x1 - r.x0) * S, (r.y1 - r.y0) * S, 0)
      o.pos = btVector3((r.x0 + r.x1) / 2 * S, base + 0.01, Z((r.y0 + r.y1) / 2))
      put(o, c)
    end
  end
  return objs
end

--------------------------------------------------------------------------
-- The book's worlds
--------------------------------------------------------------------------

-- The 12 obstacle discs of Fig. 3.25 (PDF 120), relative to their centroid,
-- in NetLogo patches. Measured from the figure: the discs are 42 px across at
-- 300 dpi and drawn at size 2 x obstacleF = 20, so 2.11 px per patch; both
-- panels give the same layout to within a pixel. The scale is confirmed
-- independently by the formation: its nodes are 63.3 px apart, D = 30
-- patches (G 400 is above G_t 259.8, so particles pair up at nodes).
World.CH03_DISCS = {
  { -47.7, 3.9 }, { -35.6, 49.6 }, { -33.8, -25.7 }, { -16.4, -49.2 },
  { -10.4, 61.0 }, { -3.1, 25.0 }, { -1.1, -22.6 }, { 12.4, 0.6 },
  { 25.7, 38.6 }, { 27.5, -48.1 }, { 37.7, -3.3 }, { 44.8, -29.8 },
}

-- The book-to-BPP mapping toBPP uses, for ports placing their own agents.
function World.bppZ(y, scale) return -y * (scale or 1) end

local presets = {}

-- Ch. 3.6 (formation_goal_obs.nlogo): a formation crossing a field of 12
-- discs to a goal. opts.radius = obstacleF (10 in Fig. 3.25, 50 in Fig.
-- 3.26, where the discs merge into a wall).
presets["ch03-obstacles"] = function(o)
  local w = World.new({ name = "ch03-obstacles", units = "patches",
                        bounds = { -152, -152, 152, 152 }, height = o.height or 10 })
  local r = o.radius or 10
  local cx, cy = o.cx or 48, o.cy or -7
  for _, d in ipairs(World.CH03_DISCS) do w:disc(cx + d[1], cy + d[2], r) end
  w:region("goal", o.goalX or -119, o.goalY or 4)
  w:region("start", 90, -40, 150, 40)
  w.notes[#w.notes + 1] = "disc layout, goal (-119, 4) and the field's centre (48, -7) measured from Fig. 3.25 (about +-2 patches); world size from the figure's scale (305 patches), not stated in the book"
  w.notes[#w.notes + 1] = "start region: the particles start as a cloud on the right (text); its size is our choice"
  return w
end

-- Fig. 3.26 (PDF 121) is a different field, not Fig. 3.25's discs enlarged:
-- obstacles are placed by mouse clicks. Six discs fitted to its outline
-- (Hough circles plus a search for one hidden behind the others; together
-- they cover the grey to within 4%), radius 95 px = 45 patches at the same
-- 2.11 px per patch, in world patches with the goal at (-119, 4) as in Fig.
-- 3.25. The text says obstacle size 50; the figure measures 45.
World.CH03_WALL_DISCS = {
  { -0.6, -55.5 }, { -7.7, 45.9 }, { 51.6, -51.7 },
  { 64.8, -14.3 }, { 33.6, 19.8 }, { 10.3, -21.9 },
}

-- Ch. 3.6, Fig. 3.26: the obstacles merged into a wall that the formation
-- rotates around. opts.radius (default 45, as measured).
presets["ch03-wall"] = function(o)
  local w = World.new({ name = "ch03-wall", units = "patches",
                        bounds = { -152, -152, 152, 152 }, height = o.height or 10 })
  local r = o.radius or 45
  for _, d in ipairs(World.CH03_WALL_DISCS) do w:disc(d[1], d[2], r) end
  w:region("goal", -119, 4)
  w:region("start", 90, -40, 150, 40)
  w.notes[#w.notes + 1] = "Fig. 3.26's own layout: 6 discs of radius 45 measured from the figure (the text says size 50); goal as Fig. 3.25"
  return w
end

-- Ch. 4.3 / Ch. 11 (uniform.nlogo, uniform_mfpl.nlogo): the 84 x 84 coverage
-- box in nine cells. BPP and the Android app keep agents inside +-40 and
-- tile that (FIXES.md 36); opts.netlogo = true puts the wall ring at +-42
-- as NetLogo draws it (the cells stay on +-40, as NetLogo's are).
presets["ch04-coverage"] = function(o)
  local half = o.netlogo and 41.5 or 40
  local w = World.new({ name = "ch04-coverage", units = "patches",
                        bounds = { -half, -half, half, half }, height = o.height or 2 })
  w:boxWalls(1, o.height or 2)
  w:cells(3, 3, -40, -40, 40, 40)
  w.notes[#w.notes + 1] = o.netlogo and "NetLogo walls: yellow ring at |patch| = 42, cells from boundary = max-pxcor - 2 = 40"
    or "Android/BPP walls at +-40 (FIXES.md 36); cells 26 2/3 on a side"
  return w
end

-- Ch. 7 (Kerr): the 1000" x 5000" corridor with random obstacles covering
-- opts.percent of it, on the 50 x 250 grid of 20" cells, start at y = 0 and
-- goal at y = 5000. Shapes are rectangles, triangles and circles (Fig. 7.2).
presets["ch07-corridor"] = function(o)
  local w = World.new({ name = "ch07-corridor", units = "inches", bounds = { 0, 0, 1000, 5000 },
                        height = o.height or 40, seed = o.seed or 1 })
  w:boxWalls(10, o.height or 40)
  w:cells(50, 250)
  w:region("start", 0, 0, 1000, 200)
  w:region("goal", 0, 4800, 1000, 5000)
  local frac = (o.percent or 30) / 100
  if frac > 0 then
    w.reached = w:scatter(frac, { seed = o.seed or 1, size = o.size or { 60, 240 },
                                  keep = { { 0, 0, 1000, 200 }, { 0, 4800, 1000, 5000 } } })
  end
  w.notes[#w.notes + 1] = "obstacle sizes 60-240 inches, overlaps allowed, and 200-inch clear strips at both ends are our choices; the book gives only the shapes and the covered percentage"
  w.notes[#w.notes + 1] = "shadow cells: free cells whose upstream neighbour (toward the start) is more than half obstacle"
  return w
end

-- World.preset(name, opts) builds one of the book's worlds.
function World.preset(name, opts)
  local f = presets[name]
  if not f then
    local names = {}
    for k in pairs(presets) do names[#names + 1] = k end
    table.sort(names)
    error("lib/world: no preset '" .. tostring(name) .. "' (have: " .. table.concat(names, ", ") .. ")", 2)
  end
  return f(opts or {})
end

function World.presets()
  local names = {}
  for k in pairs(presets) do names[#names + 1] = k end
  table.sort(names)
  return names
end

return World
