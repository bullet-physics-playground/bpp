--
-- lib/monitors.lua -- verification monitors and a Lua integrator (BOOK.md G1)
--
-- Ch. 2 sets the rule that every AP simulation should be checked for
-- centre-of-mass drift and conservation of linear momentum, angular
-- momentum and energy (book/ch02.md). This module gives:
--
--   * M.measure(ps, opts): centre of mass, its velocity, linear momentum P,
--     angular momentum L about the centre of mass (a 3D vector; a 2D run in
--     the x-z plane has only L.y), kinetic, potential and total energy.
--   * M.tracker(ps, opts): remembers the first measurement and reports how
--     far each quantity has drifted from it.
--   * M.step(ps, dt, opts): one step of the book's integrator with a time
--     step you choose (Bullet's own step is fixed at 1/60 s substeps), so
--     the Ch. 2 Delta-t experiments can be reproduced.
--
-- DEFINITIONS (fields of M.measure and of tracker:drift()):
--   mass                total mass M = sum m
--   cx, cy, cz          centre of mass, sum m r / M
--   vcx, vcy, vcz       its velocity, P / M
--   px, py, pz, p       total linear momentum P = sum m v, and |P|
--   lx, ly, lz, l       total angular momentum about the centre of mass,
--                       L = sum m (r - c) x v, and |L|; a motion in the
--                       x-y plane has only lz, a motion in x-z only ly
--   ke, pe, e           kinetic sum m v^2 / 2, potential (sum of
--                       law.potential over pairs, 0 without it), total
--   drift: com          distance the centre of mass has moved since the start
--          dp, dl       |P - P0|, |L - L0|
--          de, relE     E - E0, and (E - E0) / |E0|
--
-- Particles are tables with x, y, z, vx, vy, vz and m (mass, default 1);
-- missing coordinates count as 0. Each particle also gets fx, fy, fz (the
-- last force) from M.step.
--
-- THE STEP (Listings 2.1-2.6, PDF 64-75), in the book's order:
--   1. friction:  v <- (1 - friction) v           (per step, as NetLogo)
--   2. forces:    every force from the same snapshot (synchronous update)
--   3. velocity:  v <- v + dt F / m, then the speed cap if any
--   4. position:  x <- x + dt v
-- That is semi-implicit (symplectic) Euler.
--
-- FORCES: opts.pair(r, a, b) returns the magnitude of the force between
-- particles a and b at distance r, with the sign convention used by
-- quadcopter/swarm.lua: > 0 repels, < 0 attracts. By default each pair is
-- evaluated once and applied equally and oppositely (Newton's third law),
-- so linear momentum is conserved to rounding. opts.asymmetric = true
-- evaluates pair(r, a, b) as the force on a only, for laws that break the
-- third law (Ch. 4.1's triangle); the momentum monitor then shows it.
-- opts.forceMax caps |F| per pair (Listing 2.8's Force_Maximum);
-- opts.speedMax caps each speed (Sec. 2.3d's Velocity_Maximum);
-- opts.external(p) returns an extra force (fx, fy, fz) on one particle.
--
-- POTENTIAL ENERGY: opts.potential(r, a, b) for each pair, if given
-- (spring: k (r - D)^2 / 2; gravity: -G m1 m2 / r). Without it PE is 0 and
-- E is the kinetic energy only.
--

local M = {}

local sqrt = math.sqrt

local function comp(p)
  return p.x or 0, p.y or 0, p.z or 0, p.vx or 0, p.vy or 0, p.vz or 0, p.m or 1
end

-- Centre of mass, momentum, angular momentum, energy.
function M.measure(ps, opts)
  opts = opts or {}
  local mt, cx, cy, cz, px, py, pz, ke = 0, 0, 0, 0, 0, 0, 0, 0
  for _, p in ipairs(ps) do
    local x, y, z, vx, vy, vz, m = comp(p)
    mt = mt + m
    cx, cy, cz = cx + m * x, cy + m * y, cz + m * z
    px, py, pz = px + m * vx, py + m * vy, pz + m * vz
    ke = ke + 0.5 * m * (vx * vx + vy * vy + vz * vz)
  end
  if mt > 0 then cx, cy, cz = cx / mt, cy / mt, cz / mt end
  -- L about the centre of mass: sum m (r - c) x v
  local lx, ly, lz = 0, 0, 0
  for _, p in ipairs(ps) do
    local x, y, z, vx, vy, vz, m = comp(p)
    local rx, ry, rz = x - cx, y - cy, z - cz
    lx = lx + m * (ry * vz - rz * vy)
    ly = ly + m * (rz * vx - rx * vz)
    lz = lz + m * (rx * vy - ry * vx)
  end
  local pe = 0
  if opts.potential then
    for i = 1, #ps do
      local a = ps[i]
      local ax, ay, az = comp(a)
      for j = i + 1, #ps do
        local b = ps[j]
        local bx, by, bz = comp(b)
        local r = sqrt((bx - ax) ^ 2 + (by - ay) ^ 2 + (bz - az) ^ 2)
        pe = pe + opts.potential(r, a, b)
      end
    end
  end
  return {
    n = #ps, mass = mt,
    cx = cx, cy = cy, cz = cz,
    vcx = mt > 0 and px / mt or 0, vcy = mt > 0 and py / mt or 0, vcz = mt > 0 and pz / mt or 0,
    px = px, py = py, pz = pz, p = sqrt(px * px + py * py + pz * pz),
    lx = lx, ly = ly, lz = lz, l = sqrt(lx * lx + ly * ly + lz * lz),
    ke = ke, pe = pe, e = ke + pe,
  }
end

-- Drift since the first measurement.
--   local t = M.tracker(ps, opts); ... ; local d = t:drift()
-- d.com      distance the centre of mass has moved
-- d.dp       |P - P0|           d.dl  |L - L0|
-- d.de       E - E0             d.relE  (E - E0) / |E0| (nil if E0 = 0)
-- d.now      the current measurement; t.first the first one.
function M.tracker(ps, opts)
  local t = { ps = ps, opts = opts or {} }
  t.first = M.measure(ps, t.opts)
  function t:drift()
    local m, f = M.measure(self.ps, self.opts), self.first
    local d = {
      now = m,
      com = sqrt((m.cx - f.cx) ^ 2 + (m.cy - f.cy) ^ 2 + (m.cz - f.cz) ^ 2),
      dp = sqrt((m.px - f.px) ^ 2 + (m.py - f.py) ^ 2 + (m.pz - f.pz) ^ 2),
      dl = sqrt((m.lx - f.lx) ^ 2 + (m.ly - f.ly) ^ 2 + (m.lz - f.lz) ^ 2),
      de = m.e - f.e,
    }
    if f.e ~= 0 then d.relE = d.de / math.abs(f.e) end
    return d
  end
  return t
end

-- Add the force between a and b to a (and the opposite to b if not
-- asymmetric). f > 0 repels.
local function pairForce(a, b, opts, both)
  local dx, dy, dz = (b.x or 0) - (a.x or 0), (b.y or 0) - (a.y or 0), (b.z or 0) - (a.z or 0)
  local r = sqrt(dx * dx + dy * dy + dz * dz)
  if r == 0 then return end              -- coincident: direction undefined
  local f = opts.pair(r, a, b)
  local cap = opts.forceMax
  if cap then
    if f > cap then f = cap elseif f < -cap then f = -cap end
  end
  -- unit vector from a to b; repulsion pushes a away from b
  local s = -f / r
  a.fx, a.fy, a.fz = a.fx + s * dx, a.fy + s * dy, a.fz + s * dz
  if both then b.fx, b.fy, b.fz = b.fx - s * dx, b.fy - s * dy, b.fz - s * dz end
end

-- One integrator step of size dt (see the header).
function M.step(ps, dt, opts)
  opts = opts or {}
  local fr = opts.friction or 0
  local n = #ps
  for i = 1, n do
    local p = ps[i]
    p.vx, p.vy, p.vz = p.vx or 0, p.vy or 0, p.vz or 0
    if fr ~= 0 then
      p.vx, p.vy, p.vz = (1 - fr) * p.vx, (1 - fr) * p.vy, (1 - fr) * p.vz
    end
    p.fx, p.fy, p.fz = 0, 0, 0
  end
  if opts.pair then
    if opts.asymmetric then
      for i = 1, n do
        for j = 1, n do
          if i ~= j then pairForce(ps[i], ps[j], opts, false) end
        end
      end
    else
      for i = 1, n do
        for j = i + 1, n do pairForce(ps[i], ps[j], opts, true) end
      end
    end
  end
  if opts.external then
    for i = 1, n do
      local p = ps[i]
      local ex, ey, ez = opts.external(p)
      p.fx, p.fy, p.fz = p.fx + (ex or 0), p.fy + (ey or 0), p.fz + (ez or 0)
    end
  end
  local vmax = opts.speedMax
  for i = 1, n do
    local p = ps[i]
    local m = p.m or 1
    p.vx = p.vx + dt * p.fx / m
    p.vy = p.vy + dt * p.fy / m
    p.vz = p.vz + dt * p.fz / m
    if vmax then
      local s = sqrt(p.vx * p.vx + p.vy * p.vy + p.vz * p.vz)
      if s > vmax then
        local k = vmax / s
        p.vx, p.vy, p.vz = p.vx * k, p.vy * k, p.vz * k
      end
    end
    p.x = (p.x or 0) + dt * p.vx
    p.y = (p.y or 0) + dt * p.vy
    p.z = (p.z or 0) + dt * p.vz
  end
end

-- Distance between two particles (handy for the separation plots).
function M.dist(a, b)
  return sqrt(((b.x or 0) - (a.x or 0)) ^ 2 + ((b.y or 0) - (a.y or 0)) ^ 2 + ((b.z or 0) - (a.z or 0)) ^ 2)
end

-- The continuous damping rate equivalent to the book's per-step friction:
-- v <- (1 - FR) v each step of dt is v' = -gamma v with gamma = -ln(1 - FR)/dt.
-- It depends on dt, so changing dt with the same FR changes the damping.
function M.frictionRate(fr, dt)
  return -math.log(1 - fr) / dt
end

-- A one-line summary of a drift record (for print or a batch row).
function M.format(d)
  return string.format("com=%.3g dp=%.3g dl=%.3g de=%.3g relE=%s",
    d.com, d.dp, d.dl, d.de, d.relE and string.format("%.3g", d.relE) or "-")
end

return M
