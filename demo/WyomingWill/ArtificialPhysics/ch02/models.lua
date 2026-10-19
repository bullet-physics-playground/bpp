--
-- ch02/models.lua -- Ch. 2's three NetLogo models on the book's integrator
--
-- spring1D.nlogo, spring2D.nlogo and solar_system.nlogo (PDF 58-85,
-- book/ch02.md) as plain Lua on lib/monitors.lua, which implements the
-- models' step (friction first, all forces from one snapshot, then
-- semi-implicit Euler, Listings 2.1-2.6). Used by the BPP scenes in this
-- folder and by checks/ch02.lua.
--
-- Each constructor takes the book's sliders (defaults as in the book's
-- figures) and returns a model { ps, law, dt, ... }:
--   m.ps   the particles (x, y, z, vx, vy, vz, m); the book's 2D plane is
--          our x-y here, drawn in BPP as x and -z (lib/world.lua's mapping)
--   m.law  forces and potential for lib/monitors.lua (> 0 repels)
--   m.dt   the time step
--   M.step(m) advances one step; M.measure(m) gives the monitors.
--
-- Where the book's text is silent, the .nlogo models decide (also in
-- ch02/README.md):
--   * spring1D: particle 0 (mass 1) starts 1 + random(D/2) to the right of
--     the origin (heading 90), particle 1 (Mass_Ratio) as far to the left.
--   * spring2D: each particle takes a random heading (0-359 degrees,
--     NetLogo's: 0 = +y, clockwise) and moves 1 + random(D) from the
--     origin; then vx = Angular_Motion for particle 0, -AM/Mass_Ratio for 1.
--     random(n) is NetLogo's integer 0..n-1. (If both land on the same
--     point the force is undefined, as in NetLogo; about 1 seed in 18,000.)
--   * spring3D (ours, not in the book): spring2D with a third axis. Each
--     particle takes a random direction, uniform on the sphere (the 3D
--     version of a random heading), and moves 1 + random(D) from the
--     origin; vx as in spring2D, plus vz = Angular_Motion_Z for particle 0
--     and -AMz/Mass_Ratio for particle 1.
--   * solar_system's velocity cap scales the velocity down to Vmax,
--     keeping its direction (solar_system.nlogo line 99); speedCapPerAxis =
--     true clips each component instead, as an experiment (FINDINGS F15).
--   * tetra, planets, lattice (ours): truly 3D models with three or more
--     bodies; see their constructors below.
--   * With a force cap, the potential is the one that matches the capped
--     force: -G m1 m2 / r outside the cap radius rc = sqrt(G m1 m2 / Fmax),
--     and Fmax (r - rc) - G m1 m2 / rc inside it, so the energy monitor
--     stays meaningful when the cap is on.
--

package.path = "../?.lua;" .. package.path    -- lib/ when run from ch02/
local mon = require "lib.monitors"
local rng = require "lib.rng"

local M = {}

local function spring(k, D)
  return {
    pair = function(r) return -k * (r - D) end,
    potential = function(r) return 0.5 * k * (r - D) ^ 2 end,
  }
end

-- spring1D (Fig. 2.1 defaults). opts: massRatio 1, k 10, friction 0,
-- dt 0.001, D 50, seed (for the starting offsets; nil = the shared stream).
function M.spring1D(o)
  o = o or {}
  local D = o.D or 50
  local s = o.seed and rng.new(o.seed) or rng.shared
  local function off() return 1 + s:random(0, math.ceil(D / 2) - 1) end
  local m = { kind = "spring1D", D = D, k = o.k or 10, dt = o.dt or 0.001 }
  m.ps = { { x = off(), m = 1 }, { x = -off(), m = o.massRatio or 1 } }
  m.law = spring(m.k, D)
  m.law.friction = o.friction or 0
  return m
end

-- spring2D (Fig. 2.9 defaults). opts: angularMotion 200, massRatio 10,
-- k 10, friction 0, dt 0.001, D 50, seed.
function M.spring2D(o)
  o = o or {}
  local D = o.D or 50
  local s = o.seed and rng.new(o.seed) or rng.shared
  local function place()          -- heading random 360, fd (1 + random D)
    local h = math.rad(s:random(0, 359))
    local d = 1 + s:random(0, math.ceil(D) - 1)
    return d * math.sin(h), d * math.cos(h)
  end
  local mr, am = o.massRatio or 10, o.angularMotion or 200
  local m = { kind = "spring2D", D = D, k = o.k or 10, dt = o.dt or 0.001 }
  local x1, y1 = place()
  local x2, y2 = place()
  m.ps = { { x = x1, y = y1, vx = am, m = 1 }, { x = x2, y = y2, vx = -am / mr, m = mr } }
  m.law = spring(m.k, D)
  m.law.friction = o.friction or 0
  return m
end

-- The capped inverse-square law and its matching potential.
local function gravity(G, fmax)
  local law = {}
  law.pair = function(r, a, b) return -G * a.m * b.m / (r * r) end
  if fmax then law.forceMax = fmax end
  law.potential = function(r, a, b)
    local gm = G * a.m * b.m
    if fmax then
      local rc = math.sqrt(gm / fmax)
      if r < rc then return fmax * (r - rc) - gm / rc end
    end
    return -gm / r
  end
  return law
end

-- spring3D (ours; spring2D's defaults). opts as spring2D, plus
-- angularMotionZ (default 0).
function M.spring3D(o)
  o = o or {}
  local D = o.D or 50
  local s = o.seed and rng.new(o.seed) or rng.shared
  local function place()          -- a direction uniform on the sphere, 1 + random D away
    local cz = 2 * s:random() - 1
    local a = 2 * math.pi * s:random()
    local sz = math.sqrt(1 - cz * cz)
    local d = 1 + s:random(0, math.ceil(D) - 1)
    return d * sz * math.cos(a), d * sz * math.sin(a), d * cz
  end
  local mr, am, amz = o.massRatio or 10, o.angularMotion or 200, o.angularMotionZ or 0
  local m = { kind = "spring3D", D = D, k = o.k or 10, dt = o.dt or 0.001 }
  local x1, y1, z1 = place()
  local x2, y2, z2 = place()
  m.ps = { { x = x1, y = y1, z = z1, vx = am, vz = amz, m = 1 },
           { x = x2, y = y2, z = z2, vx = -am / mr, vz = -amz / mr, m = mr } }
  m.law = spring(m.k, D)
  m.law.friction = o.friction or 0
  return m
end

-- solar_system (Fig. 2.11 defaults). opts: angularMotion 15, sunMass 100,
-- G 20, forceMax 1e6 (effectively off), speedMax 1000 (off), dt 0.1.
-- Sun at the origin moving -AM/Msun along y, planet (mass 1) at (15, 0)
-- moving +AM along y, so the total momentum is 0.
function M.solar(o)
  o = o or {}
  local am, ms = o.angularMotion or 15, o.sunMass or 100
  local m = { kind = "solar", dt = o.dt or 0.1, G = o.G or 20 }
  m.ps = { { x = 0, vy = -am / ms, m = ms, name = "sun" }, { x = 15, vy = am, m = 1, name = "planet" } }
  local fmax = o.forceMax or 1e6
  m.law = gravity(m.G, fmax < 1e6 and fmax or nil)
  m.law.speedMax = (o.speedMax or 1000) < 1000 and o.speedMax or nil
  m.law.speedCapPerAxis = o.speedCapPerAxis   -- clip each component (F15)
  return m
end

------------------------------------------------------------------------
-- Three truly 3D models (ours, not in the book; HANDOFF §7). Two bodies
-- always move in one plane (spring3D); these need three or more.
------------------------------------------------------------------------

local sqrt = math.sqrt

-- springs on a list of bonds, each with its own rest length bond.rest
local function bondSprings(k)
  return {
    pair = function(r, a, b, bd) return -k * (r - bd.rest) end,
    potential = function(r, a, b, bd) return 0.5 * k * (r - bd.rest) ^ 2 end,
  }
end

local function com(ps)
  local mt, cx, cy, cz = 0, 0, 0, 0
  for _, p in ipairs(ps) do
    local mm = p.m or 1
    mt, cx, cy, cz = mt + mm, cx + mm * (p.x or 0), cy + mm * (p.y or 0), cz + mm * (p.z or 0)
  end
  return cx / mt, cy / mt, cz / mt, mt
end

-- inertia tensor about the centre of mass, as a 3x3 table
function M.inertia(ps)
  local cx, cy, cz = com(ps)
  local I = { { 0, 0, 0 }, { 0, 0, 0 }, { 0, 0, 0 } }
  for _, p in ipairs(ps) do
    local mm, r = p.m or 1, { (p.x or 0) - cx, (p.y or 0) - cy, (p.z or 0) - cz }
    local r2 = r[1] ^ 2 + r[2] ^ 2 + r[3] ^ 2
    for i = 1, 3 do
      for j = 1, 3 do
        I[i][j] = I[i][j] + mm * ((i == j and r2 or 0) - r[i] * r[j])
      end
    end
  end
  return I
end

-- eigenvalues (ascending) and unit eigenvectors of a symmetric 3x3 matrix,
-- by Jacobi rotations; vecs[k] is the k-th eigenvector {x, y, z}
function M.eigen3(A)
  local a = { { A[1][1], A[1][2], A[1][3] }, { A[2][1], A[2][2], A[2][3] }, { A[3][1], A[3][2], A[3][3] } }
  local V = { { 1, 0, 0 }, { 0, 1, 0 }, { 0, 0, 1 } }
  for _ = 1, 60 do
    local off = a[1][2] ^ 2 + a[1][3] ^ 2 + a[2][3] ^ 2
    if off < 1e-30 then break end
    for p = 1, 2 do
      for q = p + 1, 3 do
        if math.abs(a[p][q]) > 1e-300 then
          local th = (a[q][q] - a[p][p]) / (2 * a[p][q])
          local t = (th >= 0 and 1 or -1) / (math.abs(th) + sqrt(th * th + 1))
          local c = 1 / sqrt(t * t + 1)
          local sn = t * c
          for k = 1, 3 do          -- columns p, q
            local akp, akq = a[k][p], a[k][q]
            a[k][p], a[k][q] = c * akp - sn * akq, sn * akp + c * akq
          end
          for k = 1, 3 do          -- rows p, q
            local apk, aqk = a[p][k], a[q][k]
            a[p][k], a[q][k] = c * apk - sn * aqk, sn * apk + c * aqk
          end
          for k = 1, 3 do
            local vkp, vkq = V[k][p], V[k][q]
            V[k][p], V[k][q] = c * vkp - sn * vkq, sn * vkp + c * vkq
          end
        end
      end
    end
  end
  local idx = { 1, 2, 3 }
  table.sort(idx, function(i, j) return a[i][i] < a[j][j] end)
  local vals, vecs = {}, {}
  for k, i in ipairs(idx) do
    vals[k] = a[i][i]
    vecs[k] = { V[1][i], V[2][i], V[3][i] }
  end
  return vals, vecs
end

local function cross(a, b) return { a[2] * b[3] - a[3] * b[2], a[3] * b[1] - a[1] * b[3], a[1] * b[2] - a[2] * b[1] } end

-- set every velocity to the rigid rotation om x (r - c)
local function spinAbout(ps, om)
  local cx, cy, cz = com(ps)
  for _, p in ipairs(ps) do
    local v = cross(om, { p.x - cx, p.y - cy, p.z - cz })
    p.vx, p.vy, p.vz = v[1], v[2], v[3]
  end
end

-- tetra: four masses 1, 2, 3, 4 at the corners of a regular tetrahedron of
-- edge D, on six springs of rest length D (every pair). Unequal masses make
-- an asymmetric top: three different principal moments of inertia. It is
-- set spinning at `spin` (radians per unit time) about principal axis
-- `axis` (1 smallest moment, 2 middle, 3 largest), tilted by `tilt`
-- degrees toward the next axis. About axes 1 and 3 the spin is stable;
-- about axis 2 it is not, and the body flips over and back again and again
-- (the tennis-racket or Dzhanibekov effect) while L stays fixed.
-- opts: spin 0.5, axis 2, tilt 2, k 10, D 50, dt 0.001, friction 0.
function M.tetra(o)
  o = o or {}
  local D, k = o.D or 50, o.k or 10
  local m = { kind = "tetra", D = D, k = k, dt = o.dt or 0.001 }
  local a = D / (2 * sqrt(2))
  local corners = { { 1, 1, 1 }, { 1, -1, -1 }, { -1, 1, -1 }, { -1, -1, 1 } }
  m.ps = {}
  for i, c in ipairs(corners) do
    m.ps[i] = { x = a * c[1], y = a * c[2], z = a * c[3], m = i }
  end
  local cx, cy, cz = com(m.ps)
  for _, p in ipairs(m.ps) do p.x, p.y, p.z = p.x - cx, p.y - cy, p.z - cz end
  local vals, vecs = M.eigen3(M.inertia(m.ps))
  m.moments = vals
  local ax = math.max(1, math.min(3, math.floor((o.axis or 2) + 0.5)))
  local e, f = vecs[ax], vecs[ax % 3 + 1]
  local t = math.rad(o.tilt or 2)
  local w = o.spin or 0.5
  local om = { w * (math.cos(t) * e[1] + math.sin(t) * f[1]), w * (math.cos(t) * e[2] + math.sin(t) * f[2]),
               w * (math.cos(t) * e[3] + math.sin(t) * f[3]) }
  spinAbout(m.ps, om)
  -- the chosen axis, fixed in the body: its coefficients on the first
  -- three corners' positions (relative to the centre of mass), so
  -- M.bodyAxis can follow it as the body turns
  local r = {}
  for i = 1, 3 do r[i] = { m.ps[i].x, m.ps[i].y, m.ps[i].z } end
  local det = r[1][1] * (r[2][2] * r[3][3] - r[2][3] * r[3][2]) - r[2][1] * (r[1][2] * r[3][3] - r[1][3] * r[3][2])
            + r[3][1] * (r[1][2] * r[2][3] - r[1][3] * r[2][2])
  -- solve c1 r1 + c2 r2 + c3 r3 = e by Cramer's rule
  local function detWith(col)
    local cols = { r[1], r[2], r[3] }
    cols[col] = e
    local A, B, C = cols[1], cols[2], cols[3]
    return A[1] * (B[2] * C[3] - B[3] * C[2]) - B[1] * (A[2] * C[3] - A[3] * C[2]) + C[1] * (A[2] * B[3] - A[3] * B[2])
  end
  m.axisCoef = { detWith(1) / det, detWith(2) / det, detWith(3) / det }
  m.bonds = {}
  for i = 1, 4 do for j = i + 1, 4 do m.bonds[#m.bonds + 1] = { i, j, rest = D } end end
  m.law = bondSprings(k)
  m.law.bonds = m.bonds
  m.law.friction = o.friction or 0
  return m
end

-- the tetrahedron's chosen axis now (unit vector, body-fixed)
function M.bodyAxis(m)
  local cx, cy, cz = com(m.ps)
  local x, y, z = 0, 0, 0
  for i = 1, 3 do
    local p, c = m.ps[i], m.axisCoef[i]
    x, y, z = x + c * (p.x - cx), y + c * (p.y - cy), z + c * (p.z - cz)
  end
  local n = sqrt(x * x + y * y + z * z)
  return x / n, y / n, z / n
end

-- planets: a sun and n planets, the book's solar_system law (G m1 m2 /
-- r^2, no caps) and units (G 20, sun 100). Planet i's orbit has
-- semi-major axis r1 ratio^(i-1) and eccentricity `ecc` (0 = circular); it
-- starts at its farthest point, at a random phase, in a plane tilted by a
-- random angle up to `tilt` degrees about a random line through the sun.
-- The centre of mass starts at rest. The spacing follows from `gap`, the
-- outer orbit's nearest point over the inner orbit's farthest point:
-- ratio = gap (1 + ecc) / (1 - ecc); 1.8 is what keeps circles stable, and
-- the same gap keeps ellipses stable (FINDINGS F57, F58).
-- opts: n 4, planetMass 0.1, tilt 10, ecc 0, gap 1.8 (or ratio), r1 15,
-- G 20, sunMass 100, dt 0.01, seed.
function M.planets(o)
  o = o or {}
  local s = o.seed and rng.new(o.seed) or rng.shared
  local G, ms, mp = o.G or 20, o.sunMass or 100, o.planetMass or 0.1
  local e0 = o.ecc or 0
  local n, r1 = math.floor(o.n or 4), o.r1 or 15
  local ratio = o.ratio or (o.gap or 1.8) * (1 + e0) / (1 - e0)
  local tmax = math.rad(o.tilt or 10)
  local m = { kind = "planets", dt = o.dt or 0.01, G = G }
  m.ps = { { x = 0, y = 0, z = 0, vx = 0, vy = 0, vz = 0, m = ms, name = "sun" } }
  for i = 1, n do
    local r = r1 * ratio ^ (i - 1)
    local ph, node, inc = 2 * math.pi * s:random(), 2 * math.pi * s:random(), tmax * s:random()
    -- r is the orbit's semi-major axis a; with eccentricity e the planet
    -- starts at its farthest point a (1 + e), moving at the speed that
    -- gives that ellipse, sqrt(G M (1 - e) / (a (1 + e))) (e = 0: circular)
    local e = o.ecc or 0
    local v = sqrt(G * (ms + mp) * (1 - e) / (r * (1 + e)))
    r = r * (1 + e)
    -- in the orbit's own plane, then tilted by inc about the line at angle
    -- `node` in the x-y plane
    local px, py = r * math.cos(ph), r * math.sin(ph)
    local qx, qy = -v * math.sin(ph), v * math.cos(ph)
    local ux, uy = math.cos(node), math.sin(node)        -- the tilt axis
    local function tiltv(x, y)
      local along = x * ux + y * uy                       -- component along the axis
      local ax_, ay_ = along * ux, along * uy
      local wx, wy = x - ax_, y - ay_                      -- perpendicular part, rotated up
      local wl = sqrt(wx * wx + wy * wy)
      local sg = (wx * -uy + wy * ux) >= 0 and 1 or -1      -- which side of the axis
      return ax_ + wx * math.cos(inc), ay_ + wy * math.cos(inc), sg * wl * math.sin(inc)
    end
    local x, y, z = tiltv(px, py)
    local vx, vy, vz = tiltv(qx, qy)
    m.ps[#m.ps + 1] = { x = x, y = y, z = z, vx = vx, vy = vy, vz = vz, m = mp, name = "planet" .. i }
  end
  local px, py, pz, mt = 0, 0, 0, 0
  for _, p in ipairs(m.ps) do px, py, pz, mt = px + p.m * p.vx, py + p.m * p.vy, pz + p.m * p.vz, mt + p.m end
  for _, p in ipairs(m.ps) do p.vx, p.vy, p.vz = p.vx - px / mt, p.vy - py / mt, p.vz - pz / mt end
  m.law = gravity(G, nil)
  return m
end

-- The time step the planets need: about 50 steps across the innermost
-- orbit's nearest-point pass, whose time scale is sqrt(rp^3 / (G M)), rp =
-- r1 (1 - ecc). Fewer, and the fast pass is under-sampled (F58).
function M.planetsTimeStep(o)
  o = o or {}
  local rp = (o.r1 or 15) * (1 - (o.ecc or 0))
  return math.sqrt(rp ^ 3 / ((o.G or 20) * ((o.sunMass or 100) + (o.planetMass or 0.1)))) / 50
end

-- planet i's orbit: distance from the sun, and the tilt (degrees) of its
-- orbital plane -- the angle between its angular momentum about the sun
-- and the total angular momentum L (the "invariable plane")
function M.planetOrbit(m, i, L)
  local s, p = m.ps[1], m.ps[i + 1]
  local rx, ry, rz = p.x - s.x, p.y - s.y, p.z - s.z
  local vx, vy, vz = p.vx - s.vx, p.vy - s.vy, p.vz - s.vz
  local h = cross({ rx, ry, rz }, { vx, vy, vz })
  local hl, Ll = sqrt(h[1] ^ 2 + h[2] ^ 2 + h[3] ^ 2), sqrt(L[1] ^ 2 + L[2] ^ 2 + L[3] ^ 2)
  local c = (h[1] * L[1] + h[2] * L[2] + h[3] * L[3]) / (hl * Ll)
  return sqrt(rx * rx + ry * ry + rz * rz), math.deg(math.acos(math.max(-1, math.min(1, c))))
end

-- lattice: an n x n x n cube of unit masses, spacing D, with a spring of
-- rest length equal to the starting distance between every pair closer
-- than 1.5 D -- the cube's edges (D) and its faces' diagonals (D sqrt 2);
-- edges alone would let the cube shear flat. Each mass is displaced at
-- random by up to `jitter` x D, and the whole is set spinning at `spin`
-- about a random axis, so it rotates and rings. With friction it settles
-- back into the perfect cube.
-- opts: n 3, jitter 0.1, spin 0.3, k 10, D 50, dt 0.001, friction 0, seed.
function M.lattice(o)
  o = o or {}
  local s = o.seed and rng.new(o.seed) or rng.shared
  local n, D, k = math.floor(o.n or 3), o.D or 50, o.k or 10
  local m = { kind = "lattice", D = D, k = k, dt = o.dt or 0.001, n = n }
  m.ps = {}
  local h = (n - 1) / 2
  for i = 0, n - 1 do for j = 0, n - 1 do for l = 0, n - 1 do
    m.ps[#m.ps + 1] = { x = (i - h) * D, y = (j - h) * D, z = (l - h) * D, m = 1 }
  end end end
  m.bonds = {}
  for i = 1, #m.ps do
    for j = i + 1, #m.ps do
      local r = mon.dist(m.ps[i], m.ps[j])
      if r < 1.5 * D then m.bonds[#m.bonds + 1] = { i, j, rest = r } end
    end
  end
  local jit = (o.jitter or 0.1) * D
  for _, p in ipairs(m.ps) do
    p.x, p.y, p.z = p.x + jit * (2 * s:random() - 1), p.y + jit * (2 * s:random() - 1), p.z + jit * (2 * s:random() - 1)
  end
  local cz = 2 * s:random() - 1
  local az = 2 * math.pi * s:random()
  local sz = sqrt(1 - cz * cz)
  local w = o.spin or 0.3
  spinAbout(m.ps, { w * sz * math.cos(az), w * sz * math.sin(az), w * cz })
  m.law = bondSprings(k)
  m.law.bonds = m.bonds
  m.law.friction = o.friction or 0
  return m
end

-- the bonds' strain: mean |r - rest| / rest over all bonds (0 = perfect)
function M.strain(m)
  local sum = 0
  for _, bd in ipairs(m.bonds) do
    sum = sum + math.abs(mon.dist(m.ps[bd[1]], m.ps[bd[2]]) - bd.rest) / bd.rest
  end
  return sum / #m.bonds
end

function M.step(m) mon.step(m.ps, m.dt, m.law) end

-- Monitors: the lib/monitors.lua measurement plus the separation (and, for
-- the solar system, the planet's distance from the sun and its speed).
function M.measure(m)
  local r = mon.measure(m.ps, m.law)
  r.sep = mon.dist(m.ps[1], m.ps[2])
  local p = m.ps[2]
  r.speed2 = math.sqrt((p.vx or 0) ^ 2 + (p.vy or 0) ^ 2 + (p.vz or 0) ^ 2)
  return r
end

-- Changing a law setting mid-run (as the book does with D and k).
function M.setSpring(m, k, D)
  m.k, m.D = k or m.k, D or m.D
  local fr = m.law.friction
  m.law = spring(m.k, m.D)
  m.law.friction = fr
end

return M
