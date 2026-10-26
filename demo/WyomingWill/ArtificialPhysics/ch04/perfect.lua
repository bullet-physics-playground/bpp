--
-- ch04/perfect.lua -- Ch. 4.1's perfect formations: formation_perfect.nlogo
-- (netlogo/, PDF 124-130, Listing 4.1, book/ch04.md) as plain Lua,
-- operation for operation
--
-- THE MODEL. The split Newtonian law of formation_newton.nlogo (Ch. 3), plus
-- an attribute (m, n) for every particle, its slot in the lattice: a
-- particle with the smaller m belongs to the left, the smaller n below
-- (a shared compass gives every particle the same x and y axes). Every
-- particle holds two attributes, (squarem, squaren) and (hexm, hexn),
-- from its number "who" (init-m-n, ported as written). Inside D a pair
-- normally repels, but it ATTRACTS (twice as hard) when the two are on the
-- wrong sides of each other in x or y for their attributes, or share a row
-- (column) but sit more than cy D (cx D) apart across it; for the triangle,
-- a pair in different rows that is closer than cy D in y is pushed apart
-- in y only (three times as hard), and likewise in x: those two forces are
-- equal and opposite but not along the line between the pair, so they
-- break Newton's third law in its strong form and do not conserve angular
-- momentum (PDF 128-130).
--
-- THE STEP (run-and-monitor): every particle slows by friction, v <- (1 -
-- FR) v, sums the forces from all others where they stand now, v <- v + dt
-- F / m; then every particle moves x <- x + dt v (the model's "fd" along
-- the heading atan(dx, dy) by the length of (dx, dy): the same move).
--
-- DEFINITIONS (NetLogo's units: patches, ticks; mass 1):
--   split law   F = G m_i m_j / r^p, capped at Fmax, for r < view D
--   square      like-parity pairs (who mod 2 equal) measure r / sqrt 2
--               with view 1.3, the others r with view 1.7, and the
--               direction is (dx, dy) / r with the r used (F74); cx = cy
--               = 0.5
--   triangle    view 1.5, true r; cx = 0.25, cy = 0.433
--   ideal       the lattice the attributes describe: square, particle at
--               D (squarem, squaren); triangle, at (D / 2 hexm, D sqrt 3 / 2
--               hexn) (hexm steps by 2 along a row; checked in
--               checks/ch04_perfect.lua)
--   slot error  RMS distance of the particles from their slots in the ideal
--               lattice, fitted to them (moved, turned and scaled; M.fit),
--               in units of D (0 is perfect); "formed" when every particle
--               is within 0.25 D of its slot
--   momenta     linear momentum sum m v; angular momentum sum of r x m v
--               about the centre of mass of the last tick (the model's
--               lever arm; it writes r m v sin(theta), the same number)
--   defaults    the sliders: 100 particles, G 1000, p 2.5, Fmax 1,
--               friction 0.5, dt 1, D 25, square first; a start in a
--               cluster, a normal deviate of sd 20 per axis, at rest
--
-- r ^ p is computed by Lua's ^ as the model does; for p = 2 use r * r
-- (Lua 5.1-5.2's pow() and 5.3+'s differ in the last bit; F74's note).
-- The world (+-200) wraps in NetLogo; the formations stay well inside it,
-- so positions are not wrapped.
--
package.path = "../?.lua;" .. package.path
local rng = require "lib.rng"

local M = {}
local sqrt, floor = math.sqrt, math.floor
local atan2 = math.atan2 or math.atan        -- (5.3+: math.atan(y, x))
local SQ2 = sqrt(2)

-- init-m-n, as written ("good up to 126 particles" for the triangle)
function M.attributes(who)
  local a = {}
  local ring = 1 + floor(sqrt(who / 4))
  local index = who - ((ring - 1) * (ring - 1) * 4)
  if index < 2 * ring - 1 then a.squarem = 1 + index - ring
  elseif index <= 4 * ring - 2 then a.squarem = ring
  elseif index < 6 * ring - 3 then a.squarem = 5 * ring - index - 2
  else a.squarem = 1 - ring end
  if index < 2 * ring then a.squaren = ring - 1
  elseif index < 4 * ring - 2 then a.squaren = 3 * ring - 2 - index
  elseif index < 6 * ring - 2 then a.squaren = 0 - ring
  else a.squaren = index - 7 * ring + 3 end

  if who == 0 then ring = 1 elseif who < 7 then ring = 2 elseif who < 19 then ring = 3
  elseif who < 37 then ring = 4 elseif who < 61 then ring = 5 elseif who < 91 then ring = 6 else ring = 7 end
  if who == 0 then index = 0 else index = who - ((3 * ring * ring) - (9 * ring) + 7) end

  if index < ring then a.hexm = 2 * index - (ring - 1)
  elseif (3 * ring - 3) <= index and index <= (4 * ring - 4) then a.hexm = (8 * ring) - 8 - (2 * index) - (ring - 1)
  elseif ring <= index and index < (2 * ring - 2) then a.hexm = index
  elseif index == 2 * ring - 2 then a.hexm = 2 * ring - 2
  elseif (2 * ring - 2) < index and index < (3 * ring - 3) then a.hexm = (4 * ring) - index - 4
  elseif (4 * ring - 4) < index and index < (5 * ring - 5) then a.hexm = 3 * ring - index - 3
  elseif (5 * ring - 5) < index then a.hexm = index - (7 * ring) + 7
  elseif index == 5 * ring - 5 then a.hexm = 2 - 2 * ring end
  -- (NetLogo leaves hexm at 0 if no case applies; none is missed for who < 127)
  a.hexm = a.hexm or 0

  if index < ring then a.hexn = ring - 1
  elseif (3 * ring - 3) <= index and index <= (4 * ring - 4) then a.hexn = 1 - ring
  elseif ring <= index and index < (3 * ring - 3) then a.hexn = 2 * ring - index - 2
  elseif index > 4 * ring - 4 then a.hexn = index + 5 - 5 * ring end
  a.hexn = a.hexn or 0
  return a
end

-- A model. o: n (100), G (1000), p (2.5), Fmax (1), friction (0.5), dt (1),
-- D (25), square (true), seed, spread (20), thirdLaw (false; ours: the
-- triangle's two special cases repulse along the line between the pair,
-- like every other case, so Newton's third law holds: the author's open
-- question (a), PDF 130)
function M.new(o)
  o = o or {}
  local m = {
    G = o.G or 1000, p = o.p or 2.5, Fmax = o.Fmax or 1, FR = o.friction or 0.5, dt = o.dt or 1, D = o.D or 25,
    square = o.square ~= false, thirdLaw = o.thirdLaw, s = rng.new(o.seed or 1), ps = {}, nextWho = 0, ticks = 0,
  }
  local spread = o.spread or 20
  for _ = 1, o.n or 100 do M.add(m, m.s:gauss() * spread, m.s:gauss() * spread) end
  m.comx, m.comy = M.centre(m)
  return m
end

function M.add(m, x, y)
  local a = M.attributes(m.nextWho)
  a.x, a.y, a.vx, a.vy, a.mass, a.who = x, y, 0, 0, 1, m.nextWho
  m.nextWho = m.nextWho + 1
  m.ps[#m.ps + 1] = a
  return a
end

function M.centre(m)
  local sx, sy, sm = 0, 0, 0
  for _, a in ipairs(m.ps) do sx, sy, sm = sx + a.x * a.mass, sy + a.y * a.mass, sm + a.mass end
  return sx / sm, sy / sm
end

-- ap-particles: the force on a from all others (Listing 4.1)
local function force(m, a)
  local Fx, Fy = 0, 0
  local D, G, p, Fmax, square = m.D, m.G, m.p, m.Fmax, m.square
  local pm, pn, cx, cy
  if square then pm, pn, cx, cy = a.squarem, a.squaren, 0.5, 0.5 else pm, pn, cx, cy = a.hexm, a.hexn, 0.25, 0.433 end
  for _, b in ipairs(m.ps) do
    if b ~= a then
      local dx, dy = b.x - a.x, b.y - a.y
      local r = sqrt(dx * dx + dy * dy)
      local view = 1.5
      if square then
        if a.who % 2 == b.who % 2 then view = 1.3; r = r / SQ2 else view = 1.7 end
      end
      local km, kn
      if square then km, kn = b.squarem, b.squaren else km, kn = b.hexm, b.hexn end
      if r < view * D then
        local F = G * a.mass * b.mass / (p == 2 and r * r or r ^ p)
        if F > Fmax then F = Fmax end
        local wx, wy, sign
        if r > D then wx, wy, sign = 1, 1, 1
        elseif (dx < 0 and pm < km and dy < 0 and pn < kn) or (dx > 0 and pm > km and dy > 0 and pn > kn) then
          wx, wy, sign = 2, 2, 1
        elseif (dx < 0 and pm < km) or (dx > 0 and pm > km) then wx, wy, sign = 2, 2, 1
        elseif (dy < 0 and pn < kn) or (dy > 0 and pn > kn) then wx, wy, sign = 2, 2, 1
        elseif (pn == kn and math.abs(dy) > cy * D) or (pm == km and math.abs(dx) > cx * D) then wx, wy, sign = 2, 2, 1
        elseif not square and pn ~= kn and math.abs(dy) < cy * D then
          if m.thirdLaw then wx, wy, sign = 1, 1, -1 else wx, wy, sign = 0, 3, -1 end
        elseif not square and pm ~= km and math.abs(dx) < cx * D then
          if m.thirdLaw then wx, wy, sign = 1, 1, -1 else wx, wy, sign = 3, 0, -1 end
        else wx, wy, sign = 1, 1, -1 end
        Fx = Fx + sign * wx * F * (dx / r)
        Fy = Fy + sign * wy * F * (dy / r)
      end
    end
  end
  return Fx, Fy
end

function M.step(m)
  local f = 1 - m.FR
  local F = {}
  for i, a in ipairs(m.ps) do F[i] = { force(m, a) } end
  for i, a in ipairs(m.ps) do
    a.vx = f * a.vx + m.dt * (F[i][1] / a.mass)
    a.vy = f * a.vy + m.dt * (F[i][2] / a.mass)
  end
  -- move: the lever arm is taken from the centre of mass of the last tick
  local L, px, py = 0, 0, 0
  for _, a in ipairs(m.ps) do
    a.x, a.y = a.x + m.dt * a.vx, a.y + m.dt * a.vy
    px, py = px + a.mass * a.vx, py + a.mass * a.vy
    L = L + a.mass * ((a.x - m.comx) * a.vy - (a.y - m.comy) * a.vx)
  end
  m.comx, m.comy = M.centre(m)
  m.lmx, m.lmy, m.L = px, py, L
  m.ticks = m.ticks + 1
end

function M.run(m, ticks) for _ = 1, ticks do M.step(m) end end

-- the buttons
function M.toggle(m) m.square = not m.square end
function M.born(m)                       -- one-is-born: a clone of a random particle, D/2 away
  local a = m.ps[m.s:random(#m.ps)]
  local b = M.add(m, a.x + m.s:gauss() * m.D / 2, a.y + m.s:gauss() * m.D / 2)
  b.vx, b.vy = a.vx, a.vy                -- (hatch copies the velocity)
  return b
end

-- the ideal position of a particle (in units of D) for the current lattice
function M.ideal(m, a)
  if m.square then return a.squarem, a.squaren end
  return a.hexm / 2, a.hexn * sqrt(3) / 2
end

-- the fit of the ideal lattice to the particles (least squares, Procrustes):
-- the ideal lattice is moved to the particles' centre, turned by an angle
-- and scaled. Returns the RMS and the largest distance of a particle from
-- its slot (in D), the angle (degrees, counter-clockwise) and the fitted
-- spacing (in D). rotate = false fits no angle. pos: positions to use
-- instead of the particles' own ({x, y} per particle, in order).
function M.fit(m, rotate, pos)
  local n, cx, cy, ix, iy = #m.ps, 0, 0, 0, 0
  local P = {}
  for i, a in ipairs(m.ps) do
    local x, y = a.x, a.y
    if pos then x, y = pos[i][1], pos[i][2] end
    local u, v = M.ideal(m, a)
    P[i] = { x, y, u * m.D, v * m.D }
    cx, cy, ix, iy = cx + x, cy + y, ix + u * m.D, iy + v * m.D
  end
  cx, cy, ix, iy = cx / n, cy / n, ix / n, iy / n
  local sxx, sxy = 0, 0
  for _, q in ipairs(P) do
    local ax, ay, bx, by = q[1] - cx, q[2] - cy, q[3] - ix, q[4] - iy
    sxx, sxy = sxx + ax * bx + ay * by, sxy + ay * bx - ax * by
  end
  local th = 0
  if rotate ~= false then th = atan2(sxy, sxx) end
  local c, s = math.cos(th), math.sin(th)
  local num, den = 0, 0
  for _, q in ipairs(P) do
    local bx, by = q[3] - ix, q[4] - iy
    local rx, ry = c * bx - s * by, s * bx + c * by
    num, den = num + (q[1] - cx) * rx + (q[2] - cy) * ry, den + rx * rx + ry * ry
  end
  local k = num / den
  local e, worst = 0, 0
  for _, q in ipairs(P) do
    local bx, by = q[3] - ix, q[4] - iy
    local ex, ey = (q[1] - cx) - k * (c * bx - s * by), (q[2] - cy) - k * (s * bx + c * by)
    local e2 = ex * ex + ey * ey
    e = e + e2
    if e2 > worst then worst = e2 end
  end
  return sqrt(e / n) / m.D, sqrt(worst) / m.D, math.deg(th), k
end

-- the largest speed (has the formation stopped?)
function M.speed(m)
  local v = 0
  for _, a in ipairs(m.ps) do v = math.max(v, sqrt(a.vx * a.vx + a.vy * a.vy)) end
  return v
end

return M
