--
-- ch13/dumbbell.lua -- Ch. 13's dumbbell agent (Apker and Potter, §13.4,
-- Eqs. 13.19-13.23, PDF 462-465; book/ch13.md E10, E11) and the camera
-- ring it was built for: 3-5 Pioneer 3-ATs round one attractor, front
-- cameras pointing in (§13.4.1.2, PDF 464)
--
-- DEFINITIONS (metres, seconds, radians; x, y in the plane, + angle =
-- counter-clockwise = a left turn):
--   centre      the robot's rotation centre (x, y); psi its heading
--   t           (cos psi, sin psi), the heading; the robot moves only along it
--   p_front     the front particle, rFront ahead of the centre (the camera)
--   p_back      the back particle, rBack behind it
--   u           forward speed command, m/s (+ forwards, - backwards)
--   Omega       turn-rate command, rad/s (+ left)
--   F_f, F_b    the summed forces on p_front and p_back (> 0 along a pair's
--               line = repulsion, as everywhere in this folder)
--   T           the summed torque-law torques on the heading (Eq. 13.16)
--   theta       bearing from p_front to a point less psi, wrapped to
--               (-pi, pi]: 0 dead ahead, + on the left
--
-- THE AGENT, once a tick (10 Hz, the book's outer loop; m = I = 1, the
-- book's 1 : 1, PDF 464; Eqs. 13.21-13.22 have no dt, it is in m and I):
--   F = F_f + F_b                                            (13.19)
--   M = T + r_f x F_f + r_b x F_b,  r_f = rFront t, r_b = -rBack t,
--       a x b = a_x b_y - a_y b_x                            (13.20)
--   u_new = (u + F . t / m) (1 - mu_u)                       (13.21)
--   Omega_new = (Omega + M / I) (1 - mu_O)                   (13.22)
--   both clipped to u_max 0.5 m/s, Omega_max 0.4 rad/s (PDF 464); then
--   each mu by Eq. 13.23 (lib/ch13.lua adaptMu), used from the next tick:
--   mu + kMore (1 - mu) if the command changed sign, else mu - kLess mu.
--   STATIC FRICTION (Eq. 13.25 corrected, lib/ch13.lua staticMoves; g > 0,
--   off by default): u is 0 unless mu_u m g < |F . t|, Omega is 0 unless
--   mu_O I g < |M|. Without it a robot that has arrived creeps back and
--   forth at the minimum wheel speed for ever (its commands decay but
--   never reach 0); g 0.05 stops it (ch13/README.md).
--   u and Omega are the agent's own (the commands it sent), as the book's
--   integrators; the vehicle is told them (ground/vehicle.lua drive()).
--
-- THE RING (forces and torques; the book gives none of the numbers):
--   attractor  on p_front only: the split law of Fig. 13.8 (Eq. 13.9's
--              eta, band 2R), f = G / r eta, repelling inside R, attracting
--              outside, r = |p_front - c|; so the cameras sit on a circle
--              of radius R round the attractor c
--   pointing   a torsion spring from the heading to c (Eq. 13.15): T =
--              kappa theta_c, turning the camera toward c
--   robots     each camera (p_front) repels the other robots' cameras
--              within range: f = Gr / r^2
--   OUR CHOICES (ch13/README.md has the measurements):
--   R 2 m; rFront = rBack = 0.25 m (the Pioneer's bumpers); G 5;
--   kappa 0.4 / pi (no single spring asks for more than Omega_max per
--   tick, the book's rule for the UAVs, PDF 466); kappaSpread 0.01, the
--   weak spring a scene may use first so the robots can spread
--   (Ring-Ground.lua's spread); Gr 0.3, range 5 m; kMore 0.25, kLess
--   0.02 (kMore / kLess = 12.5 > 10, PDF 464); g 0 (static friction off).
--
--   M.P                        the agent's parameters (above)
--   M.new(x, y, psi)           an agent's controller state
--   M.particles(a [, P])       fx, fy, bx, by: its two particles
--   M.update(a, Ff, Fb, T [, P])  one tick of Eqs. 13.19-13.23 and 13.25
--                              (Ff, Fb = {x, y}); returns u, Omega
--   M.ring(agents, cx, cy, P)  the ring's forces and torques for every
--                              agent: a list of {Ff, Fb, T}
--   M.measure(agents, cx, cy, P)  the ring's quality now:
--     radius   largest |r - R| of the cameras, m
--     point    largest |theta_c| of the cameras, degrees
--     gap      largest angular gap between neighbours on the ring over
--              the even gap 360 / n (1 = even)
--     near     least distance between two robots' centres, m
--
-- THE KINEMATIC PIONEER (for checks without Bullet): wheels as
-- ground/vehicle.lua's (its V.drive: Eqs. 13.4-13.6, the 0.1 m/s minimum
-- rounded up, wheel acceleration 1 m/s^2), integrated exactly as a
-- unicycle; no contacts.
--   M.kin(x, y, psi)           a robot; M.kinStep(k, dt) moves it
--
-- Plain Lua 5.1-5.4: used by ch13/Ring-Ground.lua and checks/dumbbell.lua.
--

local C13 = require "lib.ch13"
local Veh = require "ground.vehicle"

local M = {}
local pi = math.pi
local atan2 = math.atan2 or function(y, x) return math.atan(y, x) end
local function wrap(a)
  a = (a + pi) % (2 * pi) - pi
  if a <= -pi then a = a + 2 * pi end
  return a
end
M.wrap = wrap
local function clamp(x, lo, hi) if x < lo then return lo elseif x > hi then return hi end return x end

M.P = {
  hz = 10,                       -- outer loop, Hz (book)
  rFront = 0.25, rBack = 0.25,   -- m
  m = 1, I = 1,                  -- book's 1 : 1
  uMax = 0.5, omegaMax = 0.4,    -- m/s, rad/s (book)
  kMore = 0.25, kLess = 0.02,    -- Eq. 13.23 (ratio > 10, book)
  R = 2.0,                       -- ring radius of the cameras, m
  G = 5,                         -- attractor's law
  kappa = 0.4 / pi,              -- pointing spring
  kappaSpread = 0.01,            -- the pointing spring while spreading
  Gr = 0.3, range = 5.0,         -- camera-camera repulsion
  g = 0,                         -- static friction (Eq. 13.25): 0 = off
}

function M.new(x, y, psi)
  return { x = x, y = y, psi = psi, u = 0, omega = 0, muU = 0, muO = 0 }
end

function M.particles(a, P)
  P = P or M.P
  local c, s = math.cos(a.psi), math.sin(a.psi)
  return a.x + P.rFront * c, a.y + P.rFront * s, a.x - P.rBack * c, a.y - P.rBack * s
end

function M.update(a, Ff, Fb, T, P)
  P = P or M.P
  local tx, ty = math.cos(a.psi), math.sin(a.psi)
  local ft = (Ff[1] + Fb[1]) * tx + (Ff[2] + Fb[2]) * ty                 -- (13.19) . t
  local mom = T + P.rFront * (tx * Ff[2] - ty * Ff[1])                   -- (13.20)
                - P.rBack * (tx * Fb[2] - ty * Fb[1])
  local u = clamp((a.u + ft / P.m) * (1 - a.muU), -P.uMax, P.uMax)       -- (13.21)
  local om = clamp((a.omega + mom / P.I) * (1 - a.muO), -P.omegaMax, P.omegaMax)   -- (13.22)
  if P.g and P.g > 0 then                                                 -- (13.25)
    if not C13.staticMoves(a.muU, P.m, P.g, ft) then u = 0 end
    if not C13.staticMoves(a.muO, P.I, P.g, mom) then om = 0 end
  end
  a.muU = C13.adaptMu(a.muU, u, a.u, P.kMore, P.kLess)                   -- (13.23)
  a.muO = C13.adaptMu(a.muO, om, a.omega, P.kMore, P.kLess)
  a.u, a.omega, a.ft, a.mom = u, om, ft, mom
  return u, om
end

function M.ring(agents, cx, cy, P)
  P = P or M.P
  local parts, out = {}, {}
  for i, a in ipairs(agents) do
    local fx, fy, bx, by = M.particles(a, P)
    parts[i] = { { fx, fy }, { bx, by } }
  end
  for i, a in ipairs(agents) do
    local Ff, Fb = { 0, 0 }, { 0, 0 }
    local pf = parts[i][1]
    -- attractor on the camera: Fig. 13.8's law
    local dx, dy = pf[1] - cx, pf[2] - cy
    local r = math.sqrt(dx * dx + dy * dy)
    if r > 1e-9 then
      local f = C13.damp((r < P.R) and P.G / r or -P.G / r, r, P.R, 1, 1)
      Ff[1], Ff[2] = f * dx / r, f * dy / r
    end
    -- pointing: theta to the attractor from the camera
    local T = P.kappa * wrap(atan2(cy - pf[2], cx - pf[1]) - a.psi)
    -- robots
    for j = 1, #agents do
      if j ~= i then
        local q = parts[j][1]
        local ex, ey = pf[1] - q[1], pf[2] - q[2]
        local r2 = ex * ex + ey * ey
        if r2 > 1e-12 and r2 < P.range * P.range then
          local rr = math.sqrt(r2)
          local f = P.Gr / r2
          Ff[1], Ff[2] = Ff[1] + f * ex / rr, Ff[2] + f * ey / rr
        end
      end
    end
    out[i] = { Ff, Fb, T }
  end
  return out
end

function M.measure(agents, cx, cy, P)
  P = P or M.P
  local radius, point, near, ang = 0, 0, math.huge, {}
  for i, a in ipairs(agents) do
    local fx, fy = M.particles(a, P)
    local r = math.sqrt((fx - cx) ^ 2 + (fy - cy) ^ 2)
    radius = math.max(radius, math.abs(r - P.R))
    point = math.max(point, math.abs(wrap(atan2(cy - fy, cx - fx) - a.psi)))
    ang[i] = atan2(fy - cy, fx - cx)
    for j = i + 1, #agents do
      near = math.min(near, math.sqrt((a.x - agents[j].x) ^ 2 + (a.y - agents[j].y) ^ 2))
    end
  end
  table.sort(ang)
  local n, gap = #ang, 0
  for i = 1, n do
    local g = (i < n) and ang[i + 1] - ang[i] or ang[1] + 2 * pi - ang[n]
    gap = math.max(gap, g)
  end
  return { radius = radius, point = point * 180 / pi, gap = gap / (2 * pi / n), near = near }
end

-- the kinematic Pioneer
function M.kin(x, y, psi)
  return { x = x, y = y, psi = psi, wl = 0, wr = 0, cl = 0, cr = 0 }
end
function M.kinStep(k, dt)
  local P, a = Veh.P, Veh.P.wheelAcc * dt
  k.wr = k.wr + clamp(k.cr - k.wr, -a, a)
  k.wl = k.wl + clamp(k.cl - k.wl, -a, a)
  local u, om = (k.wr + k.wl) / 2, (k.wr - k.wl) / (2 * P.rDiff)
  if math.abs(om) < 1e-12 then
    k.x, k.y = k.x + u * dt * math.cos(k.psi), k.y + u * dt * math.sin(k.psi)
  else                                    -- exact arc
    local p2 = k.psi + om * dt
    k.x = k.x + u / om * (math.sin(p2) - math.sin(k.psi))
    k.y = k.y - u / om * (math.cos(p2) - math.cos(k.psi))
    k.psi = p2
  end
end

return M
