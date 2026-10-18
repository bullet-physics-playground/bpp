--
-- lib/lattice.lua -- lattice-quality metrics (BOOK.md G16; Ch. 16.9)
--
-- DEFINITIONS (every function takes a list of points {x=, y=} or, for the
-- 3D measures, {x=, y=, z=}, in any one length unit):
--
--   delaunay2D(pts)     the Delaunay triangulation (Bowyer-Watson) of the
--                       points in the x-y plane: a list of triangles {i, j, k}
--                       and a list of unique edges {i, j} (indices into pts)
--   delaunayCV(pts, f)  Ch. 16.9's lattice quality (PDF 556): keep the nodes
--                       within f (default 0.8) of the swarm's maximum radius
--                       from its centroid; over the Delaunay edges with both
--                       ends kept, CV = sd / mean of the edge lengths
--                       (population sd; dimensionless; 0 = every edge equal).
--                       Returns cv, mean edge length, number of edges.
--   nnCV(pts)           CV of each point's distance to its nearest
--                       neighbour (2D or 3D; z = 0 if absent): sd / mean.
--                       The cheaper proxy for 3D lattices (book/ch16.md).
--                       Returns cv, mean nn distance, n.
--   bondCV(pts, sep, k) CV of the lengths of all pairs closer than k x sep
--                       (default 1.2), the swarm harness's "bonds".
--                       Returns cv, mean bond length / sep, number of bonds.
--
-- A perfect triangular lattice gives delaunayCV 0. A square lattice is
-- degenerate (four points on a circle), so its diagonals make the
-- Delaunay CV about 0.17 even when perfect: compare like with like.
--
-- Plain Lua 5.1-5.4, no dependencies; checks/lattice.lua tests it.
--

local M = {}

local function z(p) return p.z or 0 end

-- Bowyer-Watson. Points that coincide (within 1e-12 of the scale) are
-- skipped; collinear sets give no triangles.
function M.delaunay2D(pts)
  local n = #pts
  if n < 3 then return {}, {} end
  local minx, miny, maxx, maxy = math.huge, math.huge, -math.huge, -math.huge
  for _, p in ipairs(pts) do
    if p.x < minx then minx = p.x end; if p.x > maxx then maxx = p.x end
    if p.y < miny then miny = p.y end; if p.y > maxy then maxy = p.y end
  end
  local span = math.max(maxx - minx, maxy - miny, 1e-9)
  local mx, my = (minx + maxx) / 2, (miny + maxy) / 2
  -- vertices: the points, then a super-triangle far outside them. It must
  -- be very large: at 40 x the span, 32 of 200 random sets lost a triangle
  -- on the convex hull; at 10^4 x, none did (checks/lattice.lua).
  local X, Y = {}, {}
  local K = 1e4 * span
  for i, p in ipairs(pts) do X[i], Y[i] = p.x, p.y end
  X[n + 1], Y[n + 1] = mx - K, my - K
  X[n + 2], Y[n + 2] = mx + K, my - K
  X[n + 3], Y[n + 3] = mx, my + K

  local function circum(a, b, c)
    local ax, ay, bx, by, cx, cy = X[a], Y[a], X[b], Y[b], X[c], Y[c]
    local d = 2 * (ax * (by - cy) + bx * (cy - ay) + cx * (ay - by))
    if math.abs(d) < 1e-300 then return nil end
    local a2, b2, c2 = ax * ax + ay * ay, bx * bx + by * by, cx * cx + cy * cy
    local ux = (a2 * (by - cy) + b2 * (cy - ay) + c2 * (ay - by)) / d
    local uy = (a2 * (cx - bx) + b2 * (ax - cx) + c2 * (bx - ax)) / d
    return ux, uy, (ax - ux) ^ 2 + (ay - uy) ^ 2
  end

  local tris = {}
  local function addTri(a, b, c)
    local ux, uy, r2 = circum(a, b, c)
    if ux then tris[#tris + 1] = { a, b, c, ux, uy, r2 } end
  end
  addTri(n + 1, n + 2, n + 3)

  local eps = (1e-12 * span) ^ 2
  for i = 1, n do
    local px, py = X[i], Y[i]
    local dup = false
    for j = 1, i - 1 do
      if (X[j] - px) ^ 2 + (Y[j] - py) ^ 2 <= eps then dup = true; break end
    end
    if not dup then
      local keep, edges = {}, {}
      for _, t in ipairs(tris) do
        local d2 = (px - t[4]) ^ 2 + (py - t[5]) ^ 2
        if d2 < t[6] * (1 - 1e-12) then
          -- bad triangle: its edges bound the cavity unless shared
          for _, e in ipairs({ { t[1], t[2] }, { t[2], t[3] }, { t[3], t[1] } }) do
            local a, b = math.min(e[1], e[2]), math.max(e[1], e[2])
            local key = a * 1048576 + b
            if edges[key] then edges[key] = false else edges[key] = { a, b } end
          end
        else
          keep[#keep + 1] = t
        end
      end
      tris = keep
      for _, e in pairs(edges) do
        if e then addTri(e[1], e[2], i) end
      end
    end
  end

  local out, edgeList, seen = {}, {}, {}
  for _, t in ipairs(tris) do
    if t[1] <= n and t[2] <= n and t[3] <= n then
      out[#out + 1] = { t[1], t[2], t[3] }
      for _, e in ipairs({ { t[1], t[2] }, { t[2], t[3] }, { t[3], t[1] } }) do
        local a, b = math.min(e[1], e[2]), math.max(e[1], e[2])
        local key = a * 1048576 + b
        if not seen[key] then seen[key] = true; edgeList[#edgeList + 1] = { a, b } end
      end
    end
  end
  return out, edgeList
end

local function meanSd(list)
  local n = #list
  if n == 0 then return nil, nil end
  local s, q = 0, 0
  for _, x in ipairs(list) do s = s + x end
  local m = s / n
  for _, x in ipairs(list) do q = q + (x - m) ^ 2 end   -- two passes: no cancellation
  return m, math.sqrt(q / n)
end

function M.delaunayCV(pts, frac)
  frac = frac or 0.8
  local n = #pts
  if n < 3 then return nil, nil, 0 end
  local cx, cy = 0, 0
  for _, p in ipairs(pts) do cx, cy = cx + p.x, cy + p.y end
  cx, cy = cx / n, cy / n
  local rmax, rr = 0, {}
  for i, p in ipairs(pts) do
    rr[i] = math.sqrt((p.x - cx) ^ 2 + (p.y - cy) ^ 2)
    if rr[i] > rmax then rmax = rr[i] end
  end
  local _, edges = M.delaunay2D(pts)
  local lens = {}
  for _, e in ipairs(edges) do
    local a, b = e[1], e[2]
    if rr[a] <= frac * rmax and rr[b] <= frac * rmax then
      lens[#lens + 1] = math.sqrt((pts[a].x - pts[b].x) ^ 2 + (pts[a].y - pts[b].y) ^ 2)
    end
  end
  local m, sd = meanSd(lens)
  if not m or m == 0 then return nil, m, #lens end
  return sd / m, m, #lens
end

function M.nnCV(pts)
  local nn = {}
  for i, a in ipairs(pts) do
    local best = math.huge
    for j, b in ipairs(pts) do
      if i ~= j then
        local r2 = (a.x - b.x) ^ 2 + (a.y - b.y) ^ 2 + (z(a) - z(b)) ^ 2
        if r2 < best then best = r2 end
      end
    end
    if best < math.huge then nn[#nn + 1] = math.sqrt(best) end
  end
  local m, sd = meanSd(nn)
  if not m or m == 0 then return nil, m, #nn end
  return sd / m, m, #nn
end

function M.bondCV(pts, sep, k)
  k = k or 1.2
  local lens = {}
  for i = 1, #pts do
    local a = pts[i]
    for j = i + 1, #pts do
      local b = pts[j]
      local r = math.sqrt((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2 + (z(a) - z(b)) ^ 2)
      if r < k * sep then lens[#lens + 1] = r end
    end
  end
  local m, sd = meanSd(lens)
  if not m or m == 0 then return nil, m, #lens end
  return sd / m, m / sep, #lens
end

return M
