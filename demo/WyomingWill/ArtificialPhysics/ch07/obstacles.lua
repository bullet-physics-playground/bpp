--
-- ch07/obstacles.lua -- obstacles for Kerr's gas (ch07/kerr.lua), ours: the
-- book's theory runs had them (Figs. 7.5-7.8, 0-50% of the area), but the
-- code that ran them is not in William's archive (FINDINGS F94), so their
-- layout is Kerr's own 2005 generator and the rule at their faces is one
-- of three candidates, chosen per run.
--
-- LAYOUT (Kerr's ObstacleGenerator.generate, 2005 robot code, in William's
-- archive): a grid of G x G cells over the L x L box (G = 40); until the
-- covered share reaches pct, pick a cell at random and, if free, fill the
-- block from it to (i + s, j + s) inclusive, cut at the grid's edge (s = 5
-- below 30% coverage, 10 from 30%), cell by cell, stopping at pct; free
-- cells cut off from the largest free region are filled too and counted.
-- Kerr ran the cut-off test after every cell; we run it after every block
-- (the same layouts up to the order of filling). The grid is periodic
-- along y, as the channel is (kerr.lua's fix.periodic), and cut at x = 0
-- and L, the walls. Its own random numbers (Park and Miller's, seeded
-- separately), so the gas's stream is not touched.
--
-- FACES: a particle whose step ends inside an obstacle cell is put back to
-- where its path entered (found by bisection), given a new velocity by the
-- rule, and flown on with it for the rest of the step (as Garcia's wall);
-- if that lands inside again it stays just outside the face. The face is
-- the one between the last free cell and the first full one (at a corner,
-- the x face if the cell beside it along x is full, else the y face).
--   "rest"      Garcia's thermal wall at rest: normal speed
--               mpv sqrt(-ln(1-U)) out of the face, tangential sqrt(kT/m) N
--               (Kerr's 2004 SquareObstacle, without its one-way tangent)
--   "couette"   the same, but faces parallel to the flow (normal along x)
--               move at the wall speed V, as Couette walls: Kerr's robots
--               cannot tell such a face from a Couette wall and treat it as
--               one (PDF 229; KTRobot)
--   "specular"  a mirror: the normal velocity reversed, nothing else
--
-- DEFINITIONS:
--   O.attach(m, { pct = share of the box, seed = layout seed,
--                 rule = "rest" | "couette" | "specular", G = 40 })
--     adds the obstacles to a "couette" model made with fix.periodic and
--     length 1; moves particles that start inside one; returns the layout
--   lay.occ[jy * G + jx]  true where a cell is full; lay.cover its share
--

local O = {}
local floor, sqrt, log = math.floor, math.sqrt, math.log
local K = require "ch07.kerr"

local A, M = 16807, 2147483647
local function urand(r) r.seed = (A * r.seed) % M; return r.seed / M end

-- Kerr's generator on a G x G grid, periodic in y
function O.generate(pct, seed, G)
  G = G or 40
  local r = { seed = seed }
  local occ, total, count = {}, G * G, 0
  for c = 0, total - 1 do occ[c] = false end
  local s = pct < 0.3 and 5 or 10
  local function pocketsFill()
    -- label free regions (4-neighbour; y periodic, x cut); fill all but the largest
    local lab, sizes, best, nl = {}, {}, 0, 0
    for c = 0, total - 1 do
      if not occ[c] and not lab[c] then
        nl = nl + 1
        local stack, n = { c }, 0
        lab[c] = nl
        while #stack > 0 do
          local q = table.remove(stack)
          n = n + 1
          local jx, jy = q % G, floor(q / G)
          local nb = { jx > 0 and q - 1 or nil, jx < G - 1 and q + 1 or nil,
                       ((jy + 1) % G) * G + jx, ((jy - 1) % G) * G + jx }
          for k = 1, 4 do
            local p = nb[k]
            if p and not occ[p] and not lab[p] then lab[p] = nl; stack[#stack + 1] = p end
          end
        end
        sizes[nl] = n
        if best == 0 or n > sizes[best] then best = nl end
      end
    end
    for c = 0, total - 1 do
      if not occ[c] and lab[c] ~= best then occ[c] = true; count = count + 1 end
    end
  end
  while count / total < pct do
    local i = floor(urand(r) * G)        -- row (y)
    local j = floor(urand(r) * G)        -- column (x)
    if not occ[i * G + j] then
      local right = math.min(j + s, G - 1)
      for k = i, i + s do
        for l = j, right do
          if count / total >= pct then break end
          local c = (k % G) * G + l
          if not occ[c] then occ[c] = true; count = count + 1 end
        end
      end
      pocketsFill()
    end
  end
  return { occ = occ, G = G, cover = count / total }
end

function O.attach(m, o)
  assert(m.variant == "couette" and m.fix.periodic and m.length == 1,
         "obstacles need the couette variant, fix.periodic and length 1")
  local lay = O.generate(o.pct, o.seed or 1, o.G or 40)
  local G, occ, L = lay.G, lay.occ, K.L
  local h = L / G
  local function cell(x, y)
    local jx = floor(x / h); if jx < 0 then jx = 0 elseif jx > G - 1 then jx = G - 1 end
    local jy = floor(y / h) % G
    return jx, jy
  end
  local function full(x, y) local jx, jy = cell(x, y); return occ[jy * G + jx] end
  lay.full = full
  -- particles that start inside an obstacle are drawn again (gas stream)
  for i = 0, m.n - 1 do
    while full(m.x[i], m.y[i]) do m.x[i], m.y[i] = L * K.rand(m), L * K.rand(m) end
  end
  local rule, mpv, stdev = o.rule or "rest", m.mpv, m.mpv / sqrt(2.0)
  local V = m.dir1 * m.VR
  m.obstacle = function(m, i)
    local X, Y, VX, VY, XO, YO = m.x, m.y, m.vx, m.vy, m.xo, m.yo
    for _ = 1, 4 do
      if not full(X[i], Y[i]) then return end
      if full(XO[i], YO[i]) then X[i], Y[i] = XO[i], YO[i]; return end
      local a, b = 0, 1                    -- the path's entry, by bisection
      for _ = 1, 40 do
        local t = 0.5 * (a + b)
        if full(XO[i] + t * (X[i] - XO[i]), YO[i] + t * (Y[i] - YO[i])) then b = t else a = t end
      end
      local xa, ya = XO[i] + a * (X[i] - XO[i]), YO[i] + a * (Y[i] - YO[i])
      local xb, yb = XO[i] + b * (X[i] - XO[i]), YO[i] + b * (Y[i] - YO[i])
      local ax, ay = cell(xa, ya)
      local bx, by = cell(xb, yb)
      local xface
      if ax ~= bx and ay == by then xface = true
      elseif ay ~= by and ax == bx then xface = false
      else xface = occ[ay * G + bx] end
      local nx, ny = 0, 0
      if xface then nx = (bx > ax) and -1 or 1 else
        local dy = (by - ay) % G
        ny = (dy == 1) and -1 or 1
      end
      if rule == "specular" then
        if xface then VX[i] = -VX[i] else VY[i] = -VY[i] end
      else
        local vn = sqrt(-log(1.0 - K.rand(m))) * mpv
        local vt = stdev * K.randn(m)
        if xface then
          VX[i], VY[i] = nx * vn, vt + (rule == "couette" and V or 0)
        else
          VX[i], VY[i] = vt, ny * vn
        end
      end
      local f = 1 - a
      XO[i], YO[i] = xa, ya                -- the strike point is the new start
      X[i] = xa + VX[i] * m.tau * f
      Y[i] = ya + VY[i] * m.tau * f
      if X[i] <= 0 or X[i] >= L then X[i], Y[i] = xa, ya end
    end
    if full(X[i], Y[i]) then X[i], Y[i] = XO[i], YO[i] end
  end
  m.obstacles = lay
  return lay
end

return O
