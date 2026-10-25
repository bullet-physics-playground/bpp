--
-- ch04/coverage.lua -- uniform.nlogo and uniform_mfpl.nlogo (Ch. 4.3,
-- PDF 139-147; Ch. 11) as plain Lua, operation for operation
--
-- THE WORLD (the models' GRAPHICS-WINDOW): patches -42..42 in x and y,
-- wrapping; the patches on the border (|pxcor| or |pycor| = 42) are the
-- yellow wall. Nine cells split -40..40 (boundary = max-pxcor - 2) at
-- b1 = -13 1/3 and b2 = 13 1/3; an agent is in column 0 if x < b1, 1 if
-- x <= b2, else 2 (rows the same in y), so the outer cells reach the wall.
--
-- THE STEP (go): every tick the agents move one at a time, in a new random
-- order (ask turtles), each seeing the others where they are now. An
-- agent adds 1 to its step count, then up to nine times: if the patch 1
-- ahead, or the patch 2 ahead at 45 degrees left or right, is wall, or
-- another agent is within 3 patches and 15 degrees of its heading
-- (in-cone 3 30), or its step count equals the mean free path, it takes a
-- new heading, random 360 (an integer, 0 = +y, clockwise), and sets its
-- step count to 0; if a try is left (fewer than 10 tries) it moves 1
-- forward. Then it counts itself in the cell where it stands (monitor).
--
-- DEFINITIONS:
--   deviation  sqrt( sum over the 9 cells of (p_k - 1/9)^2 ), p_k the
--              share of all counts (agents x ticks, the setup's count
--              included) in cell k: the models' "Deviation from
--              Uniformity" (Eq. 4.1); 0 is uniform, 0.9428 one cell
--   mfp        Mean_Free_Path_Length, steps; nil = uniform.nlogo (none)
--   start      setxy (15 random-xcor / 16) (15 random-ycor / 16), with
--              random-xcor uniform on [-42.5, 42.5); a random integer
--              heading (create-turtles)
--
-- Patches: a point's patch is (floor(x + 0.5), floor(y + 0.5)), wrapped.
--

package.path = "../?.lua;" .. package.path    -- lib/ when run from ch04/
local rng = require "lib.rng"

local M = {}
local floor, sqrt, sin, cos, rad = math.floor, math.sqrt, math.sin, math.cos, math.rad

local MAX = 42
local B1, B2 = (2 * (MAX - 2)) / 3 - (MAX - 2), (4 * (MAX - 2)) / 3 - (MAX - 2)
M.B1, M.B2 = B1, B2

-- sin and cos of every integer heading (headings stay integers)
local S, Cs = {}, {}
for h = 0, 359 do S[h], Cs[h] = sin(rad(h)), cos(rad(h)) end
local COS15 = cos(rad(15))

local function wrapP(p) return (p + MAX) % (2 * MAX + 1) - MAX end
local function wall(x, y)
  local px, py = wrapP(floor(x + 0.5)), wrapP(floor(y + 0.5))
  return px == MAX or px == -MAX or py == MAX or py == -MAX
end

local function cell(x, y)
  local cx = (x < B1) and 0 or ((x <= B2) and 1 or 2)
  local cy = (y < B1) and 0 or ((y <= B2) and 1 or 2)
  return cx + 3 * cy + 1
end

-- o: n (number of agents), mfp (nil: none), seed
function M.new(o)
  local m = { n = o.n or 1, mfp = o.mfp, s = rng.new(o.seed or 1), counts = {}, ticks = 0,
              x = {}, y = {}, h = {}, steps = {}, order = {} }
  for k = 1, 9 do m.counts[k] = 0 end
  local s = m.s
  for i = 1, m.n do
    -- crt: a random integer heading; then setxy (15 random-xcor / 16) ...
    m.h[i] = s:random(0, 359)
    m.x[i] = 15 * (s:random() * (2 * MAX + 1) - (MAX + 0.5)) / 16
    m.y[i] = 15 * (s:random() * (2 * MAX + 1) - (MAX + 0.5)) / 16
    m.steps[i] = 0
    m.order[i] = i
    local k = cell(m.x[i], m.y[i]); m.counts[k] = m.counts[k] + 1     -- monitor
  end
  m.ticks = 1                                                         -- setup ends with tick
  return m
end

-- another agent within 3 patches and 15 degrees of agent i's heading
-- (a 3-patch bucket grid; agents at the same point count, as in NetLogo)
local function blocked(m, i, grid)
  local x, y, h = m.x[i], m.y[i], m.h[i]
  local hx, hy = S[h], Cs[h]
  local gx, gy = floor(x / 3), floor(y / 3)
  for a = gx - 1, gx + 1 do
    for b = gy - 1, gy + 1 do
      local list = grid[a * 1000 + b]
      if list then
        for _, j in ipairs(list) do
          if j ~= i then
            local dx, dy = m.x[j] - x, m.y[j] - y
            local d2 = dx * dx + dy * dy
            if d2 <= 9 and (d2 == 0 or (dx * hx + dy * hy) >= COS15 * sqrt(d2)) then return true end
          end
        end
      end
    end
  end
  return false
end

local function gridMove(grid, i, x0, y0, x1, y1)
  local k0, k1 = floor(x0 / 3) * 1000 + floor(y0 / 3), floor(x1 / 3) * 1000 + floor(y1 / 3)
  if k0 == k1 then return end
  local l = grid[k0]
  for q = 1, #l do if l[q] == i then table.remove(l, q); break end end
  local t = grid[k1]
  if not t then t = {}; grid[k1] = t end
  t[#t + 1] = i
end

function M.run(m, ticks)
  local s, n, mfp = m.s, m.n, m.mfp
  local X, Y, H, ST, counts, order = m.x, m.y, m.h, m.steps, m.counts, m.order
  local grid
  if n > 1 then
    grid = {}
    for i = 1, n do
      local k = floor(X[i] / 3) * 1000 + floor(Y[i] / 3)
      grid[k] = grid[k] or {}
      table.insert(grid[k], i)
    end
  end
  for _ = 1, ticks do
    if n > 1 then                                    -- ask turtles: a random order
      for i = n, 2, -1 do local j = s:random(i); order[i], order[j] = order[j], order[i] end
    end
    for q = 1, n do
      local i = order[q]
      local tries = 1
      local st = ST[i] + 1
      while tries < 10 do
        local x, y, h = X[i], Y[i], H[i]
        local hl, hr = (h + 315) % 360, (h + 45) % 360
        if wall(x + S[h], y + Cs[h]) or wall(x + 2 * S[hl], y + 2 * Cs[hl]) or wall(x + 2 * S[hr], y + 2 * Cs[hr])
           or (grid and blocked(m, i, grid)) or st == mfp then
          H[i] = s:random(0, 359); st = 0
          tries = tries + 1
        else
          break
        end
      end
      ST[i] = st
      if tries < 10 then
        local x0, y0 = X[i], Y[i]
        local x1, y1 = x0 + S[H[i]], y0 + Cs[H[i]]
        X[i], Y[i] = x1, y1
        if grid then gridMove(grid, i, x0, y0, x1, y1) end
      end
      local k = cell(X[i], Y[i]); counts[k] = counts[k] + 1
    end
    m.ticks = m.ticks + 1
  end
end

function M.deviation(m)
  local total, sum = m.ticks * m.n, 0
  for k = 1, 9 do sum = sum + (m.counts[k] / total - 1 / 9) ^ 2 end
  return sqrt(sum)
end

-- the shares of the nine cells (bottom left first, as the models' bins)
function M.shares(m)
  local total, p = m.ticks * m.n, {}
  for k = 1, 9 do p[k] = m.counts[k] / total end
  return p
end

return M
