--
-- checks/lattice.lua -- lib/lattice.lua: Delaunay triangulation and the
-- lattice-quality measures of Ch. 16.9
--
-- DEFINITIONS (printed values): E = Delaunay edges, T = triangles, h =
-- points on the convex hull; for n points in general position
-- E = 3n - 3 - h and T = 2n - 2 - h (Euler). CV = sd / mean of edge or
-- nearest-neighbour lengths (dimensionless), as in lib/lattice.lua.
--
-- Run from the ArtificialPhysics folder:
--   lua5.1 checks/lattice.lua      or inside BPP: bpp -f checks/lattice.lua -n 1
--

local here = (arg and arg[0] and arg[0]:match("^(.*)[/\\]checks[/\\][^/\\]*$"))
if here then package.path = here .. "/?.lua;" .. package.path
else package.path = "./?.lua;../?.lua;" .. package.path end
local L = require "lib.lattice"
local rng = require "lib.rng"

local fails, count = 0, 0
local function check(name, ok, detail)
  count = count + 1
  if not ok then fails = fails + 1 end
  print(string.format("%s %-56s %s", ok and "ok  " or "FAIL", name, detail or ""))
end

-- convex hull size (monotone chain), for Euler's formula
local function hullSize(pts)
  local P = {}
  for i, p in ipairs(pts) do P[i] = p end
  table.sort(P, function(a, b) return a.x < b.x or (a.x == b.x and a.y < b.y) end)
  local function cross(o, a, b) return (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x) end
  local lower, upper = {}, {}
  for _, p in ipairs(P) do
    while #lower >= 2 and cross(lower[#lower - 1], lower[#lower], p) <= 0 do lower[#lower] = nil end
    lower[#lower + 1] = p
  end
  for i = #P, 1, -1 do
    local p = P[i]
    while #upper >= 2 and cross(upper[#upper - 1], upper[#upper], p) <= 0 do upper[#upper] = nil end
    upper[#upper + 1] = p
  end
  return #lower + #upper - 2
end

-- Random points: Euler's counts, and the empty-circumcircle property.
do
  local s = rng.new(11)
  local okEuler, okEmpty, detail, bad = true, true, "", 0
  for trial = 1, 200 do
    local n = 20 + trial % 100
    local pts = {}
    for i = 1, n do pts[i] = { x = s:random() * 100, y = s:random() * 60 } end
    local tris, edges = L.delaunay2D(pts)
    local h = hullSize(pts)
    if #edges ~= 3 * n - 3 - h or #tris ~= 2 * n - 2 - h then okEuler = false; bad = bad + 1 end
    for _, t in ipairs(trial <= 5 and tris or {}) do       -- (circumcircles: the first 5 sets)
      local a, b, c = pts[t[1]], pts[t[2]], pts[t[3]]
      local d = 2 * (a.x * (b.y - c.y) + b.x * (c.y - a.y) + c.x * (a.y - b.y))
      local a2, b2, c2 = a.x ^ 2 + a.y ^ 2, b.x ^ 2 + b.y ^ 2, c.x ^ 2 + c.y ^ 2
      local ux = (a2 * (b.y - c.y) + b2 * (c.y - a.y) + c2 * (a.y - b.y)) / d
      local uy = (a2 * (c.x - b.x) + b2 * (a.x - c.x) + c2 * (b.x - a.x)) / d
      local r2 = (a.x - ux) ^ 2 + (a.y - uy) ^ 2
      for k, p in ipairs(pts) do
        if k ~= t[1] and k ~= t[2] and k ~= t[3] and (p.x - ux) ^ 2 + (p.y - uy) ^ 2 < r2 * (1 - 1e-9) then
          okEmpty = false
        end
      end
    end
    detail = string.format("%d sets wrong; last n=%d h=%d E=%d T=%d", bad, n, h, #edges, #tris)
  end
  check("random points: E = 3n-3-h and T = 2n-2-h (200 sets)", okEuler, detail)
  check("random points: no point inside any circumcircle (5 sets)", okEmpty)
end

-- A perfect triangular lattice (spacing 3), cut as a disc of radius 6
-- spacings so the 80% subset is all interior: every Delaunay edge equal.
do
  local pts = {}
  for row = -8, 8 do
    for col = -8, 8 do
      local x, y = 3 * (col + 0.5 * (row % 2)), 3 * row * math.sqrt(3) / 2
      if x * x + y * y <= 18 * 18 then pts[#pts + 1] = { x = x, y = y } end
    end
  end
  local cv, m, ne = L.delaunayCV(pts)
  check("perfect triangular lattice: Delaunay CV 0, edge = spacing",
    cv < 1e-9 and math.abs(m - 3) < 1e-9, string.format("cv=%.2g mean=%.4f edges=%d", cv, m, ne))
  local ncv, nm = L.nnCV(pts)
  check("perfect triangular lattice: nearest-neighbour CV 0", ncv < 1e-9 and math.abs(nm - 3) < 1e-9)
  local bcv, bm, nb = L.bondCV(pts, 3)
  check("perfect triangular lattice: bond CV 0, bond = 1.000 sep", bcv < 1e-9 and math.abs(bm - 1) < 1e-9,
    string.format("bonds=%d", nb))
  -- jitter it: the CV rises with the jitter
  local s = rng.new(3)
  local prev = 0
  local rising = true
  for _, amp in ipairs({ 0.05, 0.15, 0.4 }) do
    local q = {}
    for i, p in ipairs(pts) do q[i] = { x = p.x + amp * (s:random() - 0.5), y = p.y + amp * (s:random() - 0.5) } end
    local c = L.delaunayCV(q)
    if c <= prev then rising = false end
    prev = c
  end
  check("jittered triangular lattice: CV rises with the jitter", rising, string.format("cv(0.4)=%.3f", prev))
end

-- A square lattice: degenerate (cocircular), diagonals give CV ~0.171.
do
  local pts = {}
  for i = -5, 5 do for j = -5, 5 do pts[#pts + 1] = { x = i * 2, y = j * 2 } end end
  local cv = L.delaunayCV(pts)
  -- interior: per node two sides (length a) and one diagonal (a sqrt 2)
  local m = (2 + math.sqrt(2)) / 3
  local want = math.sqrt((2 + 2) / 3 - m * m) / m
  check("perfect square lattice: Delaunay CV = 0.171 (sides + one diagonal)",
    math.abs(cv - want) < 0.01, string.format("cv=%.4f expected %.4f", cv, want))
end

-- 3D: a simple cubic block has nearest-neighbour CV 0; points in z count.
do
  local pts = {}
  for i = 0, 3 do for j = 0, 3 do for k = 0, 3 do pts[#pts + 1] = { x = i, y = j, z = k } end end end
  local cv, m = L.nnCV(pts)
  check("3D cubic block: nearest-neighbour CV 0, distance 1", cv < 1e-12 and math.abs(m - 1) < 1e-12)
  local bcv, bm, nb = L.bondCV(pts, 1)
  check("3D cubic block: 144 bonds of 1.000 sep", nb == 144 and bcv < 1e-12 and math.abs(bm - 1) < 1e-12,
    string.format("bonds=%d", nb))
end

-- Small and degenerate inputs do not fail.
do
  local ok = pcall(function()
    L.delaunay2D({})
    L.delaunay2D({ { x = 0, y = 0 }, { x = 1, y = 0 } })
    L.delaunay2D({ { x = 0, y = 0 }, { x = 1, y = 0 }, { x = 2, y = 0 } })        -- collinear
    L.delaunay2D({ { x = 0, y = 0 }, { x = 0, y = 0 }, { x = 1, y = 1 }, { x = 1, y = 0 } }) -- duplicate
    L.delaunayCV({ { x = 0, y = 0 } })
  end)
  local t = L.delaunay2D({ { x = 0, y = 0 }, { x = 1, y = 0 }, { x = 2, y = 0 } })
  check("empty, two-point, collinear and duplicate inputs", ok and #t == 0)
end

if fails == 0 then print(string.format("PASS lattice: %d tests", count))
else print(string.format("FAIL lattice: %d of %d tests failed", fails, count)) end
if not rawget(_G, "v") then os.exit(fails == 0 and 0 or 1) end
