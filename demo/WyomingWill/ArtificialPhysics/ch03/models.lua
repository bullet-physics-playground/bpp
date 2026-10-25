--
-- ch03/models.lua -- Ch. 3's formation models as plain Lua, operation for
-- operation as the .nlogo files do them
--
-- formation_newton.nlogo (split Newtonian, triangular and square lattices),
-- honeycomb.nlogo (the honeycomb and its switching), formation_hooke.nlogo
-- (Hooke's law) and formation_goal_obs.nlogo (goal, obstacles, Disable One) from netlogo/ (PDF 96-121, book/ch03.md). Used
-- by checks/ch03.lua. Our 3D version adds a z axis to the split Newtonian
-- model (the book's models are 2D).
--
-- THE STEP (each model's run-and-monitor): every particle first slows by
-- friction, v <- (1 - FR) v, then sums the forces from every other body
-- where they all stand now, then v <- v + dt F / m; when all have done
-- so, every body moves x <- x + dt v. Goal and obstacles are bodies too
-- (mass HEAVY), pulled and pushed by the particles as in the models.
--
-- DEFINITIONS (NetLogo's units: patches, ticks; mass 1):
--   split Newtonian  F = G m_i m_j / r^p, capped at Fmax, repulsive for
--                    r <= D, attractive for D < r < view D, 0 beyond;
--                    view 1.5. Square lattice: particles of the same
--                    parity of their number ("who") measure r / sqrt 2
--                    with view 1.3, the others r with view 1.7. The
--                    direction is (dx, dy) / r with the r used, so a
--                    same-parity pair's force is sqrt 2 times longer, as
--                    in the model
--                    (rawDirection: the unit vector of the true distance,
--                    as Formations-Newtonian.lua and the Java app do).
--                    Honeycomb (honeycomb.nlogo): like pairs measure
--                    r / sqrt 3 instead, the views as for the square
--   switching        honeycomb.nlogo's cure for particles trapped at a
--                    cell's centre: each particle keeps a counter that
--                    goes up by one per neighbour it looks at, in a new
--                    random order every tick, and uses the square rule
--                    while it runs 0..100 and the honeycomb rule while it
--                    runs -100..0 (switch = "nlogo"); with 200 neighbours
--                    that is both rules every tick, each for a random
--                    half of the pairs. switch = N (ours): every particle
--                    on the square rule for N ticks, then the honeycomb
--                    rule for N ticks, and so on
--   Hooke            F = k (r - D) for r < range D (range 1.5), capped at
--                    Fmax on the attractive side only, as in the model
--   goal             a constant force goalF toward it at any range (off
--                    until goalOn), the goal a body of mass HEAVY
--   obstacle         F = obstacleF - r away from it within r <= obstacleF
--   disabled         a particle given mass HEAVY: it barely moves, and its
--                    pull on others is G HEAVY / r^p, so always Fmax
--   start            each particle at (cx, 0) + a normal deviate of sd
--                    `spread` (20) per axis; velocity 0
--   HEAVY            100000, the models' value
--
-- r^2 is computed as r * r, as Lua 5.3+ does for ^ 2 and Lua 5.1-5.2's
-- pow() need not, so the runs are the same on every Lua (the split law
-- is chaotic: a last-bit difference changes a run).
--
-- Positions are not wrapped: the models' worlds (+-200 patches) wrap, but
-- their formations stay well inside them.
--

package.path = "../?.lua;" .. package.path    -- lib/ when run from ch03/
local rng = require "lib.rng"

local M = {}
local sqrt, floor = math.sqrt, math.floor
local HEAVY = 100000
M.HEAVY = HEAVY

-- G_t of Eq. 3.4 (triangle) and Eq. 3.5 (square), as the models compute it
function M.Gt(Fmax, D, p, square)
  if square then return Fmax * D ^ p / (2 * sqrt(2) + 2) end
  return Fmax * D ^ p / (2 * sqrt(3))
end

-- A model. o: law ("newton" or "hooke"), n (50), G (400), p (2), Fmax (1),
-- friction (0.5), dt (1; Hooke's figure 0.5), D (30), k (0.5), view (1.5:
-- the split law's range in D; Hooke's range), square (false), dim (2 or
-- 3), spread (20), cx (0), seed, goalF (0.25), obstacleF (10), goal = {x,
-- y} to have a goal body (as formation_goal_obs: at -world-width / 4).
function M.new(o)
  o = o or {}
  local m = {
    law = o.law or "newton", G = o.G or 400, p = o.p or 2, Fmax = o.Fmax or 1,
    FR = o.friction or 0.5, dt = o.dt or 1, D = o.D or 30, k = o.k or 0.5,
    view = o.view or 1.5, square = o.square or false, dim = o.dim or 2, rawDirection = o.rawDirection,
    honeycomb = o.honeycomb or false, switch = o.switch,
    goalF = o.goalF or 0.25, obstacleF = o.obstacleF or 10, goalOn = false,
    s = rng.new(o.seed or 1), ps = {}, obstacles = {}, nextWho = 0, ticks = 0,
  }
  for _ = 1, o.n or 50 do M.add(m, (o.cx or 0) + m.s:gauss() * (o.spread or 20), m.s:gauss() * (o.spread or 20),
                                 m.dim == 3 and m.s:gauss() * (o.spread or 20) or 0) end
  if o.goal then m.goal = { x = o.goal[1], y = o.goal[2], z = 0, vx = 0, vy = 0, vz = 0, mass = HEAVY } end
  return m
end

function M.add(m, x, y, z)
  local p = { x = x, y = y, z = z or 0, vx = 0, vy = 0, vz = 0, mass = 1, who = m.nextWho }
  m.nextWho = m.nextWho + 1
  m.ps[#m.ps + 1] = p
  return p
end

function M.addObstacle(m, x, y)
  m.obstacles[#m.obstacles + 1] = { x = x, y = y, z = 0, vx = 0, vy = 0, vz = 0, mass = HEAVY }
end

local SQ2, SQ3 = sqrt(2), sqrt(3)

-- the force on particle a from all the others (and obstacles, goal)
local function force(m, a)
  local Fx, Fy, Fz = 0, 0, 0
  local D, G, p, Fmax = m.D, m.G, m.p, m.Fmax
  local newton = m.law == "newton"
  local order = m.ps
  if m.switch == "nlogo" then                      -- [who] of other particles: a random order
    order = {}
    for i, b in ipairs(m.ps) do order[i] = b end
    for i = #order, 2, -1 do local j = m.s:random(i); order[i], order[j] = order[j], order[i] end
  end
  local periodSquare = type(m.switch) == "number" and math.floor(m.ticks / m.switch) % 2 == 0
  for _, b in ipairs(order) do
    if b ~= a then
      local dx, dy, dz = b.x - a.x, b.y - a.y, b.z - a.z
      local r = sqrt(dx * dx + dy * dy + dz * dz)
      if newton then
        local view = m.view
        local square, honey = m.square, m.honeycomb
        if m.switch == "nlogo" then
          a.counter = a.counter or 0
          if a.counter == 0 then a.sq = true end
          if a.counter > 100 then a.sq = false; a.counter = -100 end
          a.counter = a.counter + 1
          square, honey = a.sq or false, not a.sq
        elseif type(m.switch) == "number" then
          square, honey = periodSquare, not periodSquare
        end
        if square then
          if a.who % 2 == b.who % 2 then view = 1.3; r = r / SQ2 else view = 1.7 end
        elseif honey then
          if a.who % 2 == b.who % 2 then view = 1.3; r = r / SQ3 else view = 1.7 end
        end
        if r < view * D then
          local F = G * a.mass * b.mass / (p == 2 and r * r or r ^ p)
          if F > Fmax then F = Fmax end
          if r <= D then F = -F end
          local u = m.rawDirection and sqrt(dx * dx + dy * dy + dz * dz) or r
          Fx, Fy, Fz = Fx + F * (dx / u), Fy + F * (dy / u), Fz + F * (dz / u)
        end
      elseif r < m.view * D then                   -- Hooke
        local F = m.k * (r - D)
        if F > Fmax then F = Fmax end
        Fx, Fy, Fz = Fx + F * (dx / r), Fy + F * (dy / r), Fz + F * (dz / r)
      end
    end
  end
  for _, b in ipairs(m.obstacles) do
    local dx, dy, dz = b.x - a.x, b.y - a.y, b.z - a.z
    local r = sqrt(dx * dx + dy * dy + dz * dz)
    if r <= m.obstacleF then
      local F = m.obstacleF - r
      Fx, Fy, Fz = Fx - F * (dx / r), Fy - F * (dy / r), Fz - F * (dz / r)
    end
  end
  if m.goal and m.goalOn then
    local g = m.goal
    local dx, dy, dz = g.x - a.x, g.y - a.y, g.z - a.z
    local r = sqrt(dx * dx + dy * dy + dz * dz)
    Fx, Fy, Fz = Fx + m.goalF * (dx / r), Fy + m.goalF * (dy / r), Fz + m.goalF * (dz / r)
  end
  return Fx, Fy, Fz
end

-- the goal's and an obstacle's own step: pulled (goal) or pushed
-- (obstacle) by every particle, as ap-goals and ap-obstacles do
local function bodyForce(m, b, isGoal)
  local Fx, Fy, Fz = 0, 0, 0
  for _, a in ipairs(m.ps) do
    local dx, dy, dz = a.x - b.x, a.y - b.y, a.z - b.z
    local r = sqrt(dx * dx + dy * dy + dz * dz)
    if isGoal then
      Fx, Fy, Fz = Fx + m.goalF * (dx / r), Fy + m.goalF * (dy / r), Fz + m.goalF * (dz / r)
    elseif r <= m.obstacleF then
      local F = m.obstacleF - r
      Fx, Fy, Fz = Fx - F * (dx / r), Fy - F * (dy / r), Fz - F * (dz / r)
    end
  end
  return Fx, Fy, Fz
end

local function kick(m, b, Fx, Fy, Fz)
  local f = 1 - m.FR
  b.vx, b.vy, b.vz = f * b.vx + m.dt * (Fx / b.mass), f * b.vy + m.dt * (Fy / b.mass), f * b.vz + m.dt * (Fz / b.mass)
end

function M.step(m)
  local F = {}
  for i, a in ipairs(m.ps) do F[i] = { force(m, a) } end
  local bodies = {}
  if m.goal and m.goalOn then bodies[#bodies + 1] = { m.goal, { bodyForce(m, m.goal, true) } } end
  for _, o in ipairs(m.obstacles) do bodies[#bodies + 1] = { o, { bodyForce(m, o, false) } } end
  for i, a in ipairs(m.ps) do kick(m, a, F[i][1], F[i][2], F[i][3]) end
  for _, e in ipairs(bodies) do kick(m, e[1], e[2][1], e[2][2], e[2][3]) end
  for _, a in ipairs(m.ps) do a.x, a.y, a.z = a.x + m.dt * a.vx, a.y + m.dt * a.vy, a.z + m.dt * a.vz end
  for _, e in ipairs(bodies) do local b = e[1]; b.x, b.y, b.z = b.x + m.dt * b.vx, b.y + m.dt * b.vy, b.z + m.dt * b.vz end
  m.ticks = m.ticks + 1
end

function M.run(m, ticks) for _ = 1, ticks do M.step(m) end end

-- the models' buttons
local function anyMobile(m)
  local list = {}
  for i, p in ipairs(m.ps) do if p.mass == 1 then list[#list + 1] = i end end
  return list
end
function M.kill(m)                                   -- one-dies
  local l = anyMobile(m)
  if #l > 1 then table.remove(m.ps, l[m.s:random(#l)]) end
end
function M.born(m)                                   -- one-is-born: a clone, D/2 away
  local l = anyMobile(m)
  if #l == 0 then return end
  local a = m.ps[l[m.s:random(#l)]]
  local b = M.add(m, a.x + m.s:gauss() * m.D / 2, a.y + m.s:gauss() * m.D / 2, a.z)
  b.vx, b.vy, b.vz = a.vx, a.vy, a.vz                -- (hatch copies the velocity)
  return b
end
function M.disable(m)                                -- one-is-disabled
  local l = anyMobile(m)
  if #l > 1 then local a = m.ps[l[m.s:random(#l)]]; a.mass = HEAVY; return a end
end

--------------------------------------------------------------------------
-- Measures
--------------------------------------------------------------------------

-- centre of mass of the particles of mass 1, total linear momentum of all
-- particles (|P|), and angular momentum about that centre (z component)
function M.momenta(m)
  local n, cx, cy, px, py = 0, 0, 0, 0, 0
  for _, a in ipairs(m.ps) do
    if a.mass == 1 then n = n + 1; cx, cy = cx + a.x, cy + a.y end
    px, py = px + a.mass * a.vx, py + a.mass * a.vy
  end
  cx, cy = cx / n, cy / n
  local L = 0
  for _, a in ipairs(m.ps) do L = L + a.mass * ((a.x - cx) * a.vy - (a.y - cy) * a.vx) end
  return cx, cy, sqrt(px * px + py * py), L
end

-- clusters: particles closer than eps (default D / 3) are at one lattice
-- node (union-find). Returns the number of nodes and the share of the
-- particles that share a node with another.
function M.nodes(m, eps)
  eps = eps or m.D / 3
  local n, parent = #m.ps, {}
  for i = 1, n do parent[i] = i end
  local function find(i) while parent[i] ~= i do parent[i] = parent[parent[i]]; i = parent[i] end return i end
  for i = 1, n do
    local a = m.ps[i]
    for j = i + 1, n do
      local b = m.ps[j]
      local dx, dy, dz = a.x - b.x, a.y - b.y, a.z - b.z
      if dx * dx + dy * dy + dz * dz < eps * eps then parent[find(i)] = find(j) end
    end
  end
  local size = {}
  for i = 1, n do local r = find(i); size[r] = (size[r] or 0) + 1 end
  local nodes, shared = 0, 0
  for _, c in pairs(size) do nodes = nodes + 1; if c > 1 then shared = shared + c end end
  return nodes, shared / n
end

-- the lattice: mean distance to the nearest particle at another node, over
-- D, and the share of particles with at least `want` such neighbours
-- within 0.9-1.1 D (6 for a triangular lattice inside it; the edge has
-- fewer), and the spread (radius of gyration) of the particles
function M.lattice(m)
  local n, sum, gx, gy, gz = #m.ps, 0, 0, 0, 0
  for _, a in ipairs(m.ps) do gx, gy, gz = gx + a.x, gy + a.y, gz + a.z end
  gx, gy, gz = gx / n, gy / n, gz / n
  local rg, eps = 0, m.D / 3
  local good = 0
  for _, a in ipairs(m.ps) do
    rg = rg + (a.x - gx) ^ 2 + (a.y - gy) ^ 2 + (a.z - gz) ^ 2
    local best, bonds = math.huge, 0
    for _, b in ipairs(m.ps) do
      if b ~= a then
        local d = sqrt((a.x - b.x) ^ 2 + (a.y - b.y) ^ 2 + (a.z - b.z) ^ 2)
        if d > eps and d < best then best = d end
        if d > 0.9 * m.D and d < 1.1 * m.D then bonds = bonds + 1 end
      end
    end
    sum = sum + best
    if bonds >= 1 then good = good + 1 end
  end
  return sum / n / m.D, good / n, sqrt(rg / n)
end

-- the honeycomb: the share of particles with exactly 3 neighbours within
-- 0.85-1.15 D (a perfect honeycomb's inside), and the share with two such
-- neighbours less than 90 degrees apart, seen from it (in a perfect
-- honeycomb they are 120 degrees apart; a particle at a cell's centre
-- makes 60: McLurkin's test, Sec. 3.2.4)
function M.honeycombQuality(m)
  local n, three, bad = #m.ps, 0, 0
  local lo, hi = 0.85 * m.D, 1.15 * m.D
  for _, a in ipairs(m.ps) do
    local nb = {}
    for _, b in ipairs(m.ps) do
      if b ~= a then
        local dx, dy = b.x - a.x, b.y - a.y
        local d = sqrt(dx * dx + dy * dy)
        if d > lo and d < hi then nb[#nb + 1] = { dx / d, dy / d } end
      end
    end
    if #nb == 3 then three = three + 1 end
    local close = false
    for i = 1, #nb do for j = i + 1, #nb do
      if nb[i][1] * nb[j][1] + nb[i][2] * nb[j][2] > 0 then close = true end   -- under 90 degrees
    end end
    if close then bad = bad + 1 end
  end
  return three / n, bad / n
end

-- mean speed of the particles of mass 1
function M.speed(m)
  local n, s = 0, 0
  for _, a in ipairs(m.ps) do
    if a.mass == 1 then n = n + 1; s = s + sqrt(a.vx * a.vx + a.vy * a.vy + a.vz * a.vz) end
  end
  return s / n
end

return M
