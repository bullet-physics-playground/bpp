--
-- ch13/auv.lua -- Ch. 13's laws on the torpedo-shaped AUV (auv/model.lua):
-- one AUV and one attractor, the AUV's counterpart of the UAV's Fig. 13.13
-- (ch13/uav.lua; book/ch13.md E8, E9; §13.5's design procedure)
--
-- DEFINITIONS (metres, seconds, radians; + = counter-clockwise = left):
--   theta   bearing to the attractor less the AUV's heading, wrapped to
--           (-pi, pi]: 0 dead ahead, +pi/2 on the left
--   t, n    the AUV's heading and its left normal
--   F       the attractor's pull, G / r^2 toward it (no attract-repel
--           boundary: it always attracts), m = 1
--
-- THE AGENT has one heading particle (§13.5: a vehicle that can only turn
-- forwards needs one), ten ticks a second:
--   speed    Eq. 13.21's channel: u_new = (u + F . t / m)(1 - MU_U),
--            clipped to [U_MIN, U_MAX]; or u fixed at cruise (fixedSpeed,
--            the book's UAV)
--   heading  law "gravity": Eq. 13.8, Omega_new = (Omega + F . n / m) MU
--            law "torque":  Eqs. 13.15-13.18, Omega_new = Omega + kappa
--            theta dt / I, with kappa dt / I = Omega_max(u) / pi (no pair
--            asks for more than the turn limit, the book's rule, PDF 466)
--            both clipped to +-u / R_MIN
-- OUR CHOICES (the book has no AUV): G = 8000 (a target 60 m ahead already
-- asks for top speed, so the speed channel is near bang-bang: full ahead
-- when the target is ahead, the slowest when it is behind); MU = 0.5 (as
-- the UAV's gravity law); MU_U = 0.5.
--
--   M.newWorld(opts)   { auvs, targets, law, fixedSpeed, t }; opts: law,
--                      fixedSpeed, auvs, targets
--   M.step(w)          one tick (1/10 s): commands, then motion
--   M.run(w, secs, from)   runs secs seconds, measuring from time `from`:
--     closest  least distance to the (first) target, m
--     passes   times within PASS m of it (counted again after leaving to
--              3 PASS m)
--     near     share of the time within R_MIN of it
--     speed    mean speed, m/s; nearSpeed the mean speed while near
--     power    mean (u / U_CRUISE)^3: the propulsive power against drag
--              (~ u^3) relative to cruising (1 at fixed cruise speed)
--     final    distance at the end, m
--
-- Plain Lua 5.1-5.4: used by ch13/AUV-Attractor.lua and checks/auv.lua.
--

local A = require "auv.model"

local M = {}
M.G, M.MU, M.MU_U, M.PASS = 8000, 0.5, 0.5, 2.0

local pi = math.pi
local atan2 = math.atan2 or function(y, x) return math.atan(y, x) end
local function wrap(a)
  a = (a + pi) % (2 * pi) - pi
  if a <= -pi then a = a + 2 * pi end
  return a
end
M.wrap = wrap

function M.newWorld(opts)
  opts = opts or {}
  return { law = opts.law or "torque", fixedSpeed = opts.fixedSpeed or false, t = 0,
           auvs = opts.auvs or { A.new(0, 0, 0) }, targets = opts.targets or { { x = 0, y = 0 } } }
end

local function command(w, a)
  local fx, fy, s = 0, 0, 0
  for _, tg in ipairs(w.targets) do
    local dx, dy = tg.x - a.x, tg.y - a.y
    local r2 = dx * dx + dy * dy
    if r2 > 1e-9 then
      local r = math.sqrt(r2)
      fx, fy = fx + M.G / r2 * dx / r, fy + M.G / r2 * dy / r
    end
    s = s + wrap(atan2(dy, dx) - a.psi)
  end
  local c, sn = math.cos(a.psi), math.sin(a.psi)
  local u = w.fixedSpeed and A.U_CRUISE or (a.u + (fx * c + fy * sn)) * (1 - M.MU_U)
  local om
  if w.law == "gravity" then om = (a.omega + (-fx * sn + fy * c)) * M.MU
  else om = a.omega + A.omegaMax(a.u) / pi * s end
  return u, om
end

function M.step(w)
  local dt = 1 / A.HZ
  local want = {}
  for i, a in ipairs(w.auvs) do want[i] = { command(w, a) } end
  for i, a in ipairs(w.auvs) do A.command(a, want[i][1], want[i][2]); A.advance(a, dt) end
  w.t = w.t + dt
end

function M.run(w, secs, from)
  local tg, a = w.targets[1], w.auvs[1]
  local closest, passes, isNear, n, near, us, nearU, pw = math.huge, 0, false, 0, 0, 0, 0, 0
  for _ = 1, math.floor(secs * A.HZ + 0.5) do
    M.step(w)
    local d = math.sqrt((a.x - tg.x) ^ 2 + (a.y - tg.y) ^ 2)
    closest = math.min(closest, d)
    if d < M.PASS and not isNear then passes, isNear = passes + 1, true elseif d > 3 * M.PASS then isNear = false end
    if w.t >= (from or 0) then
      n, us, pw = n + 1, us + a.u, pw + (a.u / A.U_CRUISE) ^ 3
      if d < A.R_MIN then near, nearU = near + 1, nearU + a.u end
    end
  end
  return { closest = closest, passes = passes, near = n > 0 and near / n or 0, speed = n > 0 and us / n or 0,
           nearSpeed = near > 0 and nearU / near or 0, power = n > 0 and pw / n or 0,
           final = math.sqrt((a.x - tg.x) ^ 2 + (a.y - tg.y) ^ 2) }
end

return M
