--
-- ch11/maxim.lua -- Maxim's coverage simulator (Ch. 11, Table 11.1) as
-- plain Lua, operation for operation as maxim/src/coverage_simulation.c
--
-- One robot in a polygonal environment tiled with square cells
-- (maxim/<name>.environment/environment_<size>.ini: the wall's vertices,
-- the cells' lower-left corners, the cell size). Every time step
-- (move_agent, then record_cell_visits):
--   * the robot's one sensor looks RESPONSE_RANGE (1) ahead; if that line
--     crosses a wall (any edge of the closed polygon), or the step count
--     equals floor(cell size x f) (f = 0.6, the "magic constant" on the
--     command line; the book's mean free path), it takes a new heading,
--     uniform on [0, 2 pi), and looks again, until the way is clear; the
--     step count goes back to 0 on every turn;
--   * it moves 1 along its heading;
--   * it is counted in the cell of highest index whose lower-left corner is
--     at or below and left of it (the cells are listed by x, then y).
-- The robot starts at the centre of a cell next to a randomly chosen wall
-- (the "side" start), heading pi / 2.
--
-- DEFINITIONS:
--   KL   the Kullback-Leibler divergence of the visit shares p_i from the
--        uniform 1/C, sum p_i ln(p_i C) (natural log), C cells (Sec.
--        11.2.3); 0 is uniform
--
-- EXACTNESS: the random numbers are Bourke's RandomUniform (Marsaglia and
-- Zaman's generator, maxim/src/randomlib.c), exact in doubles on any
-- machine; the C keeps positions as GLfloat (single precision), so they
-- are rounded to single precision where the C stores them. The C seeds
-- the generator with RandomInitialise(1, time(NULL)), and since time()
-- is far above the generator's limit of 30081 it falls back to the fixed
-- seeds (1802, 9373): every run of the C, Maxim's included, draws the
-- same stream. seed = { ij, kl } chooses another.
--

local M = {}
local floor, sqrt, cos, sin = math.floor, math.sqrt, math.cos, math.sin

-- round to single precision (IEEE binary32, to nearest even)
local f32
if string.pack then
  f32 = function(x) return (string.unpack("f", string.pack("f", x))) end
else
  local frexp, ldexp = math.frexp, math.ldexp
  f32 = function(x)
    if x == 0 then return x end
    local m, e = frexp(x)                          -- 0.5 <= |m| < 1
    local s = m * 16777216                         -- 24 bits
    local r = floor(s)
    local d = s - r
    if d > 0.5 or (d == 0.5 and r % 2 == 1) then r = r + 1 end
    return ldexp(r / 16777216, e)
  end
end
M.f32 = f32

-- Bourke's RandomInitialise / RandomUniform
local function newRandom(ij, kl)
  if ij < 0 or ij > 31328 or kl < 0 or kl > 30081 then ij, kl = 1802, 9373 end
  local i = floor(ij / 177) % 177 + 2
  local j = ij % 177 + 2
  local k = floor(kl / 169) % 178 + 1
  local l = kl % 169
  local u = {}
  for ii = 1, 97 do
    local s, t = 0.0, 0.5
    for _ = 1, 24 do
      local m = (((i * j) % 179) * k) % 179
      i, j, k = j, k, m
      l = (53 * l + 1) % 169
      if (l * m) % 64 >= 32 then s = s + t end
      t = t * 0.5
    end
    u[ii] = s
  end
  local R = { u = u, c = 362436.0 / 16777216.0, cd = 7654321.0 / 16777216.0, cm = 16777213.0 / 16777216.0,
              i97 = 97, j97 = 33 }
  return function()
    local uu = R.u
    local uni = uu[R.i97] - uu[R.j97]
    if uni <= 0.0 then uni = uni + 1 end
    uu[R.i97] = uni
    R.i97 = R.i97 - 1; if R.i97 == 0 then R.i97 = 97 end
    R.j97 = R.j97 - 1; if R.j97 == 0 then R.j97 = 97 end
    R.c = R.c - R.cd
    if R.c < 0.0 then R.c = R.c + R.cm end
    uni = uni - R.c
    if uni < 0.0 then uni = uni + 1 end
    return uni
  end
end
M.newRandom = newRandom

-- the environment file: { walls = { {x, y}, ... }, cells = { {x, y}, ... }, size }
function M.readEnvironment(path)
  local f = assert(io.open(path, "r"))
  local tok = {}
  for line in f:lines() do
    local a, b = line:match("^%s*(%S+)%s+(%S+)")
    if a then tok[#tok + 1] = { a, b } end
  end
  f:close()
  local e, q = { walls = {}, cells = {} }, 1
  assert(tok[q][1] == "vertix_number")
  local nv = tonumber(tok[q][2]); q = q + 1
  for i = 1, nv do e.walls[i] = { f32(tonumber(tok[q][1])), f32(tonumber(tok[q][2])) }; q = q + 1 end
  assert(tok[q][1] == "cell_number")
  local nc = tonumber(tok[q][2]); q = q + 1
  for i = 1, nc do e.cells[i] = { f32(tonumber(tok[q][1])), f32(tonumber(tok[q][2])) }; q = q + 1 end
  assert(tok[q][1] == "cell_size")
  e.size = tonumber(tok[q][2])
  return e
end

-- intersect() of the C: segments m-n and o-p
local function intersect(x1, y1, x2, y2, a1, b1, a2, b2)
  local dx, dy, da, db = x2 - x1, y2 - y1, a2 - a1, b2 - b1
  local den = da * dy - db * dx
  if den == 0 then return false end
  local s = (dx * (b1 - y1) + dy * (x1 - a1)) / den
  local t = (da * (y1 - b1) + db * (a1 - x1)) / (db * dx - da * dy)
  return s >= 0.0 and s <= 1.0 and t >= 0.0 and t <= 1.0
end

local PI = 3.141592653589793238462643
local RESPONSE = 1.0

-- A simulation. o: env (from readEnvironment), f (0.6), seed ({ij, kl};
-- default the C's fallback)
function M.new(o)
  local e = o.env
  local rnd = o.rnd or newRandom((o.seed or { 1, 2 ^ 31 })[1], (o.seed or { 1, 2 ^ 31 })[2])
  local m = { env = e, rnd = rnd, f = o.f or 0.6, counts = {}, steps = 0, moveCounter = 0,
              heading = PI / 2 }
  for i = 1, #e.cells do m.counts[i] = 0 end
  local W = e.walls
  m.x, m.y = f32(W[1][1] + 1), f32(W[1][2] + 1)
  -- find_cell (the first cell holding the point, edges included)
  local function findCell(x, y)
    for i, c in ipairs(e.cells) do
      if x >= c[1] and x <= c[1] + e.size and y >= c[2] and y <= c[2] + e.size then return i end
    end
  end
  -- change_starting_position, "side": the middle of a random wall, then
  -- the centre of its cell
  local nv = #W
  local r = floor((nv - 1) * rnd())                -- 0-based, as the C
  local A, Bv = W[r + 1], W[(r + 1) % nv + 1]
  local cell
  if A[1] == Bv[1] then
    local ty
    if A[2] > Bv[2] then ty = (A[2] - Bv[2]) / 2 + Bv[2] else ty = (Bv[2] - A[2]) / 2 + A[2] end
    ty = f32(ty); ty = ty >= 0 and floor(ty) or -floor(-ty)          -- (int)
    cell = findCell(A[1], ty)
  else
    local tx
    if A[1] > Bv[1] then tx = (A[1] - Bv[1]) / 2 + Bv[1] else tx = (Bv[1] - A[1]) / 2 + A[1] end
    tx = f32(tx); tx = tx >= 0 and floor(tx) or -floor(-tx)
    cell = findCell(tx, A[2])
  end
  assert(cell, "no side starting position")
  local half = floor(e.size / 2)                   -- params.cell_size / 2, unsigned
  m.x, m.y = f32(e.cells[cell][1] + half), f32(e.cells[cell][2] + half)
  -- impulse_agent(0): two draws, the velocity they set is not used
  rnd(); rnd()
  return m
end

-- does the sensor, along the current heading, cross a wall?
local function blocked(m)
  local W = m.env.walls
  local x, y = m.x, m.y
  local sx = f32(cos(0 + m.heading) * RESPONSE + x)
  local sy = f32(sin(0 + m.heading) * RESPONSE + y)
  local n = #W
  for v = 1, n do
    local a, b = W[v], W[v == n and 1 or v + 1]
    if intersect(x, y, sx, sy, a[1], a[2], b[1], b[2]) then return true end
  end
  return false
end

function M.run(m, steps)
  local cells, counts = m.env.cells, m.counts
  local limit = floor(m.env.size * m.f)
  local rnd = m.rnd
  local nc = #cells
  for _ = 1, steps do
    -- move_agent
    local flag = blocked(m)
    m.moveCounter = m.moveCounter + 1
    while flag or m.moveCounter == limit do
      m.heading = rnd() * PI * 2
      m.moveCounter = 0
      flag = blocked(m)
    end
    m.x = f32(m.x + f32(cos(m.heading)))
    m.y = f32(m.y + f32(sin(m.heading)))
    m.steps = m.steps + 1
    -- record_cell_visits
    local x, y = m.x, m.y
    for i = nc, 1, -1 do
      local c = cells[i]
      if x >= c[1] and y >= c[2] then counts[i] = counts[i] + 1; break end
    end
  end
end

function M.kl(counts)
  local tot, n = 0, #counts
  for i = 1, n do tot = tot + counts[i] end
  local s = 0
  for i = 1, n do
    if counts[i] > 0 then local p = counts[i] / tot; s = s + p * math.log(p * n) end
  end
  return s
end

-- Maxim's output files: the cell list, then for every sampling step the
-- time step and each cell's visits. Returns { {t, counts}, ... }
function M.readOutput(path)
  local f = assert(io.open(path, "r"))
  local lines = {}
  for l in f:lines() do lines[#lines + 1] = l end
  f:close()
  local n = tonumber(lines[8])
  local out, cur = {}, nil
  for q = 8 + n + 4, #lines do
    local a, b = lines[q]:match("^%s*(%d+)%s+(%d+)%s*$")
    if a then
      cur.counts[tonumber(a) + 1] = tonumber(b)
    else
      local t = lines[q]:match("^%s*(%d+)%s*$")
      if t then
        cur = { t = tonumber(t), counts = {} }
        for i = 1, n do cur.counts[i] = 0 end
        out[#out + 1] = cur
      end
    end
  end
  return out
end

return M
