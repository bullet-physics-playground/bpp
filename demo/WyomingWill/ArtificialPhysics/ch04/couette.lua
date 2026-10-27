--
-- ch04/couette.lua -- kt.nlogo (Ch. 4.4, Couette flow, PDF 147-156) as
-- plain Lua, operation for operation
--
-- Kinetic theory: no forces. Each particle carries a velocity (vx, vy);
-- collisions and the walls change it, and it moves by it every tick.
--
-- THE WORLD (the model's GRAPHICS-WINDOW): patches -42..42 in x and y,
-- wrapping in both, so x and y run over [-42.5, 42.5). The patches with
-- pxcor 40, 41, 42 are the red wall (moves up, +y); -42, -41, -40 the
-- yellow wall (moves down). Only the walls' boundary condition uses the
-- wall velocity; nothing moves. Distances are the torus's, as NetLogo's.
--
-- THE STEP (go): every tick
--   1. the particles, one at a time in a new random order (ask turtles),
--      each seeing the others' current velocities:
--      a. collision: if any other particle is within 2 (in-radius 2), pick
--         one of them at random; rel = |v - v_f|, v_cm = (v + v_f)/2,
--         theta = random 360 (integer degrees),
--         v_rel = rel (sin theta, cos theta); v = v_cm + v_rel/2,
--         v_f = v_cm - v_rel/2. Momentum and relative speed are kept.
--      b. walls: if a red patch centre is within 1 (in-radius 1),
--         vx = -sqrt(2T) sqrt(-ln U), vy = sqrt(T) N(0,1) + V;
--         then if a yellow one is, vx = +sqrt(2T) sqrt(-ln U),
--         vy = sqrt(T) N(0,1) - V (so yellow wins where both are near,
--         which happens across the wrap at x >= 42).
--   2. every particle moves by (vx, vy) (move: fd |v| along atan vx vy),
--      wrapping.
--   3. monitor: the 13 columns, column i = -42 + i 84/13 < x <
--      -42 + (i+1) 84/13 (strict; x beyond +-42 is in none); each
--      non-empty column adds its mean vy to its sum; the speeds' sum is
--      added to sum_vel; sample + 1. Setup ends with one monitor too.
--
-- DEFINITIONS (what the functions return):
--   profile(m)  the 13 bars: column i's sum / sample (mean vy, AP units
--               per tick; + is up, the red wall's way)
--   stats(m)    slope = least-squares slope of the bars against
--               i = 0..12 (units per tick per column), and corr, their
--               correlation coefficient (compute-stats). Theory: slope
--               2V/12 = V/6 (PDF 150), corr 1
--   meanSpeed(m) sum_vel / (sample N): the mean particle speed |v| over
--               the samples (units per tick). The .nlogo sums it but has
--               no monitor; the book adds one (PDF 154). Theory for walls
--               at rest: 1.2533 sqrt(T) (Eq. 4.5)
--   momentum(m) mean vx, mean vy over the particles (the model's two
--               "Linear Momentum" monitors, m = 1); stay near 0
--   resample(m) the Resample button: sample = 0, so the next monitor
--               clears the sums
--   start       heading = random 360, speed sqrt(T) 1.2533,
--               vx = v cos h, vy = v sin h; setxy (7 random-xcor / 8)
--               (7 random-ycor / 8), random-xcor uniform on [-42.5, 42.5)
--
-- One choice of ours: -ln U is drawn as -ln(1 - u), u in [0, 1), which
-- has the same distribution and cannot reach ln 0 (lib/rng.lua's floats
-- are multiples of 2^-32; a sweep draws ~10^9 of them).
--
-- o.split (ours, default false): measure the mean speed inside and
-- outside the wall zones, and the vx of each particle as it leaves a wall
-- zone (splitSpeeds, exitStats; ch04/README.md); it changes nothing in
-- the model.
--
-- o.inward (ours, default false = the .nlogo): a wall thermalises a
-- particle only while it moves into that wall (red: vx >= 0; yellow:
-- vx <= 0). In the .nlogo a particle still inside the wall zone after
-- its draw is drawn again every tick until it is out, so the wall emits
-- hotter than the Rayleigh it draws (FINDINGS F85); with inward the
-- emission is the Rayleigh and Fig. 4.23 comes out as the book's.
--

package.path = "../?.lua;" .. package.path    -- lib/ when run from ch04/
local rng = require "lib.rng"

local M = {}
local floor, sqrt, sin, cos, rad, log = math.floor, math.sqrt, math.sin, math.cos, math.rad, math.log

local MAX = 42
local W = 2 * MAX + 1                          -- 85, the torus's width
local NC = 42                                  -- grid cells a side, each 85/42 >= 2 wide
local CW = W / NC
M.MAX = MAX

local S, Cs = {}, {}
for h = 0, 359 do S[h], Cs[h] = sin(rad(h)), cos(rad(h)) end

local function wrap(x) return (x + MAX + 0.5) % W - (MAX + 0.5) end

-- distance in x from x to the nearest of the wall patches' centres
-- (red: 40..42; yellow: -42..-40), on the torus
local function dxRed(x)
  if x >= 40 and x <= 42 then return 0 end
  if x < 40 then return math.min(40 - x, x + W - 42) end
  return x - 42
end
local function dxYellow(x)
  if x >= -42 and x <= -40 then return 0 end
  if x > -40 then return math.min(x + 40, -42 + W - x) end
  return -42 - x
end
-- in-radius 1 of a wall patch: the nearest patch row is within 0.5 in y
local function nearWall(dx, y)
  local dy = y - floor(y + 0.5)
  return dx * dx + dy * dy <= 1
end
M.nearRed = function(x, y) return nearWall(dxRed(x), y) end
M.nearYellow = function(x, y) return nearWall(dxYellow(x), y) end

local B = {}                                   -- column boundaries
for i = 0, 13 do B[i] = -MAX + i * 2 * MAX / 13 end
M.columnEdges = B

-- o: n (1000), V (wall velocity, 1.0), T (temperature, 0.010), seed, split, inward
function M.new(o)
  local m = { n = o.n or 1000, V = o.V or 1.0, T = o.T or 0.010, s = rng.new(o.seed or 1),
              x = {}, y = {}, vx = {}, vy = {}, v = {}, order = {}, ticks = 0,
              hist = {}, sumVel = 0, sample = 0, split = o.split, inward = o.inward,
              exitSum = 0, exitSum2 = 0, exitCount = 0 }
  local s = m.s
  for i = 1, m.n do
    local h = s:random(0, 359)
    local v = sqrt(m.T) * 1.2533
    m.v[i], m.vx[i], m.vy[i] = v, v * cos(rad(h)), v * sin(rad(h))
    m.x[i] = 7 * (s:random() * W - (MAX + 0.5)) / 8
    m.y[i] = 7 * (s:random() * W - (MAX + 0.5)) / 8
    m.order[i] = i
  end
  for k = 0, 12 do m.hist[k] = 0 end
  M.monitor(m)
  return m
end

function M.resample(m) m.sample = 0 end

function M.monitor(m)
  local hist, X, VY, V, n = m.hist, m.x, m.vy, m.v, m.n
  if m.sample == 0 then
    m.sumVel = 0
    for k = 0, 12 do hist[k] = 0 end
    if m.split then m.wallSum, m.wallCount, m.inSum, m.inCount = 0, 0, 0, 0 end
  end
  local sum, cnt = {}, {}
  for k = 0, 12 do sum[k], cnt[k] = 0, 0 end
  local sv = 0
  for i = 1, n do
    local x = X[i]
    if x > B[0] and x < B[13] then
      local k = floor((x - B[0]) * 13 / (2 * MAX))
      if k > 12 then k = 12 end
      if x > B[k] and x < B[k + 1] then sum[k] = sum[k] + VY[i]; cnt[k] = cnt[k] + 1 end
    end
    sv = sv + V[i]
  end
  for k = 0, 12 do if cnt[k] > 0 then hist[k] = hist[k] + sum[k] / cnt[k] end end
  m.sumVel = m.sumVel + sv
  if m.split then                                -- ours: speeds in and out of the wall zones
    for i = 1, n do
      local x, y = X[i], m.y[i]
      if M.nearRed(x, y) or M.nearYellow(x, y) then m.wallSum, m.wallCount = m.wallSum + V[i], m.wallCount + 1
      else m.inSum, m.inCount = m.inSum + V[i], m.inCount + 1 end
    end
  end
  m.sample = m.sample + 1
end

function M.run(m, ticks)
  local s, n, T, V, inward, split = m.s, m.n, m.T, m.V, m.inward, m.split
  local X, Y, VX, VY, SP, order = m.x, m.y, m.vx, m.vy, m.v, m.order
  local s2T, sT = sqrt(2 * T), sqrt(T)
  local cellOf, grid, near = {}, {}, {}
  for _ = 1, ticks do
    -- positions do not change while the particles collide, so the
    -- neighbours within 2 are found once per tick (a torus grid)
    for k = 0, NC * NC - 1 do grid[k] = nil end
    for i = 1, n do
      local k = floor((X[i] + MAX + 0.5) / CW) % NC + NC * (floor((Y[i] + MAX + 0.5) / CW) % NC)
      cellOf[i] = k
      local l = grid[k]; if not l then l = {}; grid[k] = l end
      l[#l + 1] = i
    end
    for i = n, 2, -1 do local j = s:random(i); order[i], order[j] = order[j], order[i] end
    for q = 1, n do
      local i = order[q]
      local x, y = X[i], Y[i]
      -- a. collision with one of the particles within 2
      local k = cellOf[i]
      local cx, cy = k % NC, floor(k / NC)
      local cntN = 0
      for a = -1, 1 do
        for b = -1, 1 do
          local l = grid[(cx + a) % NC + NC * ((cy + b) % NC)]
          if l then
            for _, j in ipairs(l) do
              if j ~= i then
                local dx, dy = X[j] - x, Y[j] - y
                if dx > MAX + 0.5 then dx = dx - W elseif dx < -(MAX + 0.5) then dx = dx + W end
                if dy > MAX + 0.5 then dy = dy - W elseif dy < -(MAX + 0.5) then dy = dy + W end
                if dx * dx + dy * dy <= 4 then cntN = cntN + 1; near[cntN] = j end
              end
            end
          end
        end
      end
      if cntN > 0 then
        local f = near[s:random(cntN)]
        local dvx, dvy = VX[i] - VX[f], VY[i] - VY[f]
        local rel = sqrt(dvx * dvx + dvy * dvy)
        local cmx, cmy = 0.5 * (VX[i] + VX[f]), 0.5 * (VY[i] + VY[f])
        local th = s:random(0, 359)
        local rx, ry = rel * S[th], rel * Cs[th]
        VX[i], VY[i] = cmx + 0.5 * rx, cmy + 0.5 * ry
        VX[f], VY[f] = cmx - 0.5 * rx, cmy - 0.5 * ry
      end
      -- b. the walls
      if nearWall(dxRed(x), y) and not (inward and VX[i] < 0) then
        VX[i] = -s2T * sqrt(-log(1 - s:random()))
        VY[i] = s:gauss() * sT + V
      end
      if nearWall(dxYellow(x), y) and not (inward and VX[i] > 0) then
        VX[i] = s2T * sqrt(-log(1 - s:random()))
        VY[i] = s:gauss() * sT - V
      end
    end
    -- 2. move
    for i = 1, n do
      local vx, vy = VX[i], VY[i]
      local was = split and (M.nearRed(X[i], Y[i]) or M.nearYellow(X[i], Y[i]))
      SP[i] = sqrt(vx * vx + vy * vy)
      X[i], Y[i] = wrap(X[i] + vx), wrap(Y[i] + vy)
      if was and not (M.nearRed(X[i], Y[i]) or M.nearYellow(X[i], Y[i])) then
        m.exitSum, m.exitSum2, m.exitCount = m.exitSum + math.abs(vx), m.exitSum2 + vx * vx, m.exitCount + 1
      end
    end
    m.ticks = m.ticks + 1
    M.monitor(m)
  end
end

function M.profile(m)
  local p = {}
  for k = 0, 12 do p[k] = m.hist[k] / m.sample end
  return p
end

-- compute-stats: slope and correlation of the bars against 0..12
function M.stats(m)
  local p = M.profile(m)
  local ybar = 0
  for k = 0, 12 do ybar = ybar + p[k] end
  ybar = ybar / 13
  local sxy, sx, sy = 0, 0, 0
  for k = 0, 12 do
    sxy = sxy + (k - 6) * (p[k] - ybar)
    sx = sx + (k - 6) ^ 2
    sy = sy + (p[k] - ybar) ^ 2
  end
  return sxy / sx, sxy / (sqrt(sx) * sqrt(sy))
end

function M.meanSpeed(m) return m.sumVel / (m.sample * m.n) end

function M.momentum(m)
  local px, py = 0, 0
  for i = 1, m.n do px, py = px + m.vx[i], py + m.vy[i] end
  return px / m.n, py / m.n
end

-- ours (o.split): mean speed in the wall zones, outside them, and the
-- share of particle-samples in the wall zones
function M.splitSpeeds(m)
  return m.wallSum / m.wallCount, m.inSum / m.inCount, m.wallCount / (m.wallCount + m.inCount)
end

-- ours (o.split): over all ticks, the mean |vx| / sqrt(T) and vx^2 / T of
-- the particles leaving a wall zone (Rayleigh: 1.2533 and 2), and how many
function M.exitStats(m)
  return m.exitSum / m.exitCount / sqrt(m.T), m.exitSum2 / m.exitCount / m.T, m.exitCount
end

return M
