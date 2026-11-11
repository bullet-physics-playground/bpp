--
-- auv/model.lua -- a torpedo-shaped AUV (BOOK.md G11; Ch. 13's design
-- procedure, §13.5, PDF 466-468) as a kinematic model at one depth: it
-- cannot hover, reverse or move sideways
--
-- THE VEHICLE is the REMUS of Prestero's model (T. Prestero, Verification
-- of a Six-Degree of Freedom Simulation Model for the REMUS Autonomous
-- Underwater Vehicle, MS thesis, MIT/WHOI, 2001): 1.33 m long, 0.191 m
-- across, 30.5 kg (W = 299 N), operating speed 1.54 m/s (3 knots) (his
-- Tables 2.1, 2.3, 8.1). Its top speed, 2.3 m/s (4.5 knots), is the maker's
-- for the REMUS 100. An inner loop holds depth, speed and turn rate; the
-- 10 Hz outer loop (the book's, as for its UAV) commands a speed and a
-- turn rate.
--   R_MIN   the smallest turn radius: the steady turn of his horizontal-
--           plane model (sway and yaw with his Appendix B coefficients,
--           adjusted to his sea trials) at his maximum fin angle, 13.6 deg
--           (Table 2.2): M.steadyTurn solves it, 6.03 m. Every term of his
--           model grows with speed squared, so the radius is the same at
--           every speed and the turn-rate limit is
--             Omega_max(u) = u / R_MIN
--           (0.38 rad/s at top speed, 0.083 at U_MIN). Unlike the book's
--           UAV (Eq. 13.14, Omega_max ~ 1 / v), slowing down does not
--           tighten a turn; it only makes it take longer. Check: 4 deg of
--           fin at 1.54 m/s turns at 10.0 deg/s, his sea trials' "roughly
--           ten degrees per second" (his Section 8.3, Fig. 7-7).
--   U_MIN   0.5 m/s, ASSUMED (his model has no lower limit; a real
--           vehicle's fins lose authority against disturbances when slow):
--           the slowest speed at which the vehicle steers, so it never
--           goes slower (it cannot hover or reverse); swept 0.25-1.0
-- Speed and turn-rate changes are instantaneous within the limits, as
-- the book's UAV's (§13.2.3).
--
-- REACHABLE SPACE in one tick (dt = 0.1 s; the book's Fig. 13.12 for the
-- UAV): speed u in [U_MIN, U_MAX], heading change within +-u dt / R_MIN, a
-- wedge that does not reach u = 0: M.reachable() gives its corners.
--
-- DEFINITIONS (metres, seconds, radians; the plane's (x, y) is drawn in BPP
-- as (x, -z)):
--   x, y   position, m; psi heading, rad, counter-clockwise from +x
--   u      speed, m/s, in [U_MIN, U_MAX]
--   omega  turn rate, rad/s, + = left, within +-u / R_MIN
--
--   M.new(x, y, psi [, u])     an AUV (speed U_CRUISE if not given)
--   M.command(a, u, omega)     set speed and turn rate for the next tick
--                              (clipped; returns the values used)
--   M.advance(a, dt)           go dt seconds: an exact arc
--   M.omegaMax(u)              u / R_MIN
--   M.reachable()              {uMin, uMax, dPsiAtMin, dPsiAtMax} per tick
--   M.steadyTurn(delta, u)     his model's steady turn at fin angle delta
--                              (rad) and speed u: sway v (m/s), yaw rate r
--                              (rad/s, his sign: + = right), radius u / |r|
--
-- Plain Lua 5.1-5.4, no BPP: used by ch13/auv.lua, its scene and
-- checks/auv.lua.
--

local M = {}

M.LENGTH, M.WIDTH, M.MASS = 1.33, 0.191, 299 / 9.81   -- m, m, kg (Prestero)
M.U_CRUISE, M.U_MAX = 1.54, 2.3                -- m/s (Prestero; maker)
M.U_MIN = 0.5                                  -- m/s, ASSUMED
M.DELTA_MAX = math.rad(13.6)                   -- maximum fin angle (Prestero)
M.HZ = 10                                      -- outer loop (book)

-- his horizontal-plane coefficients (Appendix B, Tables B.1-B.2)
local C = { Yvv = -1310, Yrr = 0.632, Yuv = -28.6, Yur = 5.22, Yd = 9.64,
            Nvv = -3.18, Nrr = -94.0, Nuv = -24.0, Nur = -2.00, Nd = -6.15 }
M.PRESTERO = C

-- steady turn: m u r = Y and 0 = N, his simulator's sway and yaw
-- equations with v' = r' = 0 and the centre of gravity on the axis,
-- solved by Newton's method from a small turn
function M.steadyTurn(delta, u)
  local m = M.MASS
  local function f(v, r)
    return C.Yvv * v * math.abs(v) + C.Yrr * r * math.abs(r) + C.Yuv * u * v + (C.Yur - m) * u * r + C.Yd * u * u * delta,
           C.Nvv * v * math.abs(v) + C.Nrr * r * math.abs(r) + C.Nuv * u * v + C.Nur * u * r + C.Nd * u * u * delta
  end
  local v, r = 0.01 * u, -0.1 * u
  for _ = 1, 60 do
    local f1, f2 = f(v, r)
    local h = 1e-7
    local a1, a2 = f(v + h, r)
    local b1, b2 = f(v, r + h)
    local j11, j21, j12, j22 = (a1 - f1) / h, (a2 - f2) / h, (b1 - f1) / h, (b2 - f2) / h
    local det = j11 * j22 - j12 * j21
    v, r = v - (j22 * f1 - j12 * f2) / det, r - (-j21 * f1 + j11 * f2) / det
  end
  return v, r, u / math.abs(r)
end

M.R_MIN = select(3, M.steadyTurn(M.DELTA_MAX, M.U_CRUISE))   -- 6.03 m

function M.omegaMax(u) return u / M.R_MIN end

function M.new(x, y, psi, u) return { x = x, y = y, psi = psi, u = u or M.U_CRUISE, omega = 0 } end

function M.command(a, u, omega)
  if u > M.U_MAX then u = M.U_MAX elseif u < M.U_MIN then u = M.U_MIN end
  local om = M.omegaMax(u)
  if omega > om then omega = om elseif omega < -om then omega = -om end
  a.u, a.omega = u, omega
  return u, omega
end

function M.advance(a, dt)
  local w, s = a.omega, a.u
  if math.abs(w) < 1e-12 then
    a.x, a.y = a.x + s * dt * math.cos(a.psi), a.y + s * dt * math.sin(a.psi)
  else
    local p1 = a.psi + w * dt
    a.x = a.x + s / w * (math.sin(p1) - math.sin(a.psi))
    a.y = a.y - s / w * (math.cos(p1) - math.cos(a.psi))
    a.psi = p1
  end
  if a.psi > math.pi then a.psi = a.psi - 2 * math.pi elseif a.psi <= -math.pi then a.psi = a.psi + 2 * math.pi end
end

function M.reachable()
  local dt = 1 / M.HZ
  return { uMin = M.U_MIN, uMax = M.U_MAX,
           dPsiAtMin = M.U_MIN * dt / M.R_MIN, dPsiAtMax = M.U_MAX * dt / M.R_MIN }
end

return M
