--
-- ch13/triangle.lua -- Ch. 13's "triangle of death" (Apker and Potter,
-- §13.2.2, PDF 454-456, Figs. 13.9-13.11; book/ch13.md E6): three
-- differential-drive robots on an equilateral triangle, axles pointing at
-- its centre, under the point-mass controller of Eqs. 13.7-13.10; one of
-- them is pulled along its axle
--
-- DEFINITIONS (metres, seconds, radians; x, y in the plane, + angle =
-- counter-clockwise = a left turn; forces in the book's virtual newtons,
-- > 0 along a pair's line = repulsion):
--   centre    a robot's rotation centre (x, y); psi its heading;
--             t = (cos psi, sin psi), n = (-sin psi, cos psi) (its left,
--             along the axle)
--   particle  the point AP senses and moves: offset metres ahead of the
--             centre (0 = at the centre; the book's failing case has it
--             off the centre, e.g. a laser at the front, Fig. 13.11)
--   law       Fig. 13.8's: f = A / r eta, eta = |D - r| / D for r < 2D
--             (Eq. 13.9, p_d = 1), repelling inside D, attracting out to
--             D_max, 0 beyond; A = 100 N m, D = 1 m, D_max = 4 m (the
--             figure's values)
--   pull      a constant force of GOAL newtons toward a far point, on
--             robot 3 only ("forces that affect only one of them",
--             PDF 454); GOAL = 25 N, the law's weakest attraction (at
--             D_max). The point is 10 m from the triangle's centre, out
--             along robot 3's axle, plus `angle` (rad, + = toward the
--             way robot 3 faces), so at angle 0 the pull is parallel to
--             robot 3's axle, as Fig. 13.11's
--
-- THE CONTROLLER (Eqs. 13.7-13.8, PDF 454; mu the book's retention
-- factor), every robot, 10 Hz, from the summed force F on its particle:
--   u_new = (u + F . t / m) mu,   Omega_new = (Omega + F . n / m) mu
--   clipped to 0.5 m/s and 0.4 rad/s, and both 0 while |F| < STOP (the
--   book's preset threshold, PDF 454: the robot stops). Our choices: m =
--   100 (25 N gives 0.25 m/s or rad/s a tick), mu = 0.5, STOP = 5 N (a
--   fifth of the pull). The wheels: ground/vehicle.lua drive() (0 or
--   0.1-0.5 m/s, Eqs. 13.4-13.6).
--
-- THE START: the particles on the triangle with sides D (every pair at
-- the law's zero, so nothing moves without the pull), each robot's axle
-- through the centre, headings counter-clockwise round it. Robot 1 at the
-- top, 2 lower right, 3 lower left (Fig. 13.9).
--
--   M.law(r)                  Fig. 13.8's force at distance r, N
--   M.new(offset, angle)      a world { robots, goal } (robots with x, y,
--                             psi, u, omega and a kinematic Pioneer kin)
--   M.forces(w)               the summed force on each robot's particle
--   M.tick(w)                 one controller tick: commands to the wheels
--   M.particle(r)             a robot's particle (x, y)
--   M.result(w, x0, y0, cx0, cy0)  how robot 3 did: moved (m toward the
--                             goal) and the centroid's move (m)
--   M.runKin(offset, angle, secs)   the whole run on the kinematic Pioneer
--                             (ch13/dumbbell.lua's kin); returns result +
--                             turned (robot 3's heading change, rad) and
--                             flips (changes of sign of its Omega command
--                             in the last 30 s)
--
-- Plain Lua 5.1-5.4: used by ch13/Triangle-Ground.lua and
-- checks/triangle.lua.
--

local DB = require "ch13.dumbbell"
local Veh = require "ground.vehicle"

local M = {}
M.A, M.D, M.DMAX, M.GOAL = 100, 1.0, 4.0, 25
M.MASS, M.MU, M.STOP, M.HZ = 100, 0.5, 5, 10
M.UMAX, M.OMAX = 0.5, 0.4
local pi = math.pi
local function clamp(x, lo, hi) if x < lo then return lo elseif x > hi then return hi end return x end

function M.law(r)
  if r >= M.DMAX or r < 1e-9 then return 0 end
  local eta = (r < 2 * M.D) and math.abs(M.D - r) / M.D or 1
  return ((r < M.D) and M.A / r or -M.A / r) * eta
end

function M.particle(r)
  return r.x + r.offset * math.cos(r.psi), r.y + r.offset * math.sin(r.psi)
end

function M.new(offset, angle)
  local w = { robots = {} }
  local R = M.D / math.sqrt(3)
  for i, a in ipairs({ pi / 2, -pi / 6, 7 * pi / 6 }) do
    local psi = a + pi / 2                               -- counter-clockwise
    local px, py = R * math.cos(a), R * math.sin(a)      -- the particle
    local r = { x = px - offset * math.cos(psi), y = py - offset * math.sin(psi), psi = psi,
                u = 0, omega = 0, offset = offset }
    r.kin = DB.kin(r.x, r.y, r.psi)
    w.robots[i] = r
  end
  -- the far point: out along robot 3's axle, turned by angle toward its heading
  local a3 = 7 * pi / 6 + (angle or 0)
  w.goal = { 10 * math.cos(a3), 10 * math.sin(a3) }
  return w
end

function M.forces(w)
  local F = {}
  for i, r in ipairs(w.robots) do
    local px, py = M.particle(r)
    local fx, fy = 0, 0
    for j, o in ipairs(w.robots) do
      if j ~= i then
        local qx, qy = M.particle(o)
        local dx, dy = px - qx, py - qy
        local d = math.sqrt(dx * dx + dy * dy)
        if d > 1e-9 then
          local f = M.law(d)
          fx, fy = fx + f * dx / d, fy + f * dy / d
        end
      end
    end
    if i == 3 then
      local gx, gy = w.goal[1] - px, w.goal[2] - py
      local g = math.sqrt(gx * gx + gy * gy)
      fx, fy = fx + M.GOAL * gx / g, fy + M.GOAL * gy / g
    end
    F[i] = { fx, fy }
  end
  return F
end

function M.tick(w)
  local F = M.forces(w)
  for i, r in ipairs(w.robots) do
    local fx, fy = F[i][1], F[i][2]
    if fx * fx + fy * fy < M.STOP * M.STOP then
      r.u, r.omega = 0, 0
    else
      local c, s = math.cos(r.psi), math.sin(r.psi)
      r.u = clamp((r.u + (fx * c + fy * s) / M.MASS) * M.MU, -M.UMAX, M.UMAX)          -- (13.7)
      r.omega = clamp((r.omega + (-fx * s + fy * c) / M.MASS) * M.MU, -M.OMAX, M.OMAX)  -- (13.8)
    end
  end
  return F
end

function M.result(w, x0, y0, cx0, cy0)
  local r = w.robots[3]
  local gx, gy = w.goal[1] - x0, w.goal[2] - y0
  local g = math.sqrt(gx * gx + gy * gy)
  local cx, cy = 0, 0
  for _, o in ipairs(w.robots) do cx, cy = cx + o.x / 3, cy + o.y / 3 end
  return { moved = ((r.x - x0) * gx + (r.y - y0) * gy) / g,
           centroid = math.sqrt((cx - cx0) ^ 2 + (cy - cy0) ^ 2) }
end

function M.runKin(offset, angle, secs)
  local w = M.new(offset, angle)
  local r3 = w.robots[3]
  local x0, y0, psi0 = r3.x, r3.y, r3.psi
  local cx0, cy0 = 0, 0
  for _, o in ipairs(w.robots) do cx0, cy0 = cx0 + o.x / 3, cy0 + o.y / 3 end
  local flips, last, turned = 0, 0, 0
  for tick = 1, secs * M.HZ do
    for _, r in ipairs(w.robots) do r.x, r.y, r.psi = r.kin.x, r.kin.y, r.kin.psi end
    M.tick(w)
    for _, r in ipairs(w.robots) do Veh.drive(r.kin, r.u, r.omega) end
    local sg = (r3.omega > 0) and 1 or (r3.omega < 0) and -1 or 0
    if tick > (secs - 30) * M.HZ and sg ~= 0 and last ~= 0 and sg ~= last then flips = flips + 1 end
    if sg ~= 0 then last = sg end
    for _ = 1, 25 do for _, r in ipairs(w.robots) do DB.kinStep(r.kin, 1 / (25 * M.HZ)) end end
  end
  for _, r in ipairs(w.robots) do r.x, r.y, r.psi = r.kin.x, r.kin.y, r.kin.psi end
  local res = M.result(w, x0, y0, cx0, cy0)
  res.turned = DB.wrap(r3.psi - psi0)
  res.flips = flips
  return res
end

return M
