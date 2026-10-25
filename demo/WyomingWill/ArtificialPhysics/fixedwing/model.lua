--
-- fixedwing/model.lua -- the book's fixed-wing UAV (Ch. 13, BOOK.md G12)
-- as a kinematic model: constant speed, a turn-rate limit, nothing else
--
-- THE AIRCRAFT (book §13.2.3, PDF 457-458; book/ch13.md E7): an inner loop
-- (>= 50 Hz) holds speed and altitude and limits the bank angle to
-- PHI_MAX; bank changes are instantaneous; lift equals weight. The
-- physicomimetic outer loop runs at 10 Hz and can only command a turn
-- rate. The book's turn-rate limit is Eq. 13.14,
--   Omega_max = g sin(PHI_MAX) / (2 v)
-- = 9.81 x sin 20 deg / 26 = 0.129 rad/s at v = 13 m/s: a smallest turn
-- radius v / Omega_max = 101 m, which matches the ~100 m loops of the
-- book's Fig. 13.16. (A coordinated turn would allow g tan(PHI) / v =
-- 0.275 rad/s, radius 47 m; the book's factor 2 is unexplained. We follow
-- the book, as its figures do; FINDINGS F76.)
--
-- DEFINITIONS (metres, seconds, radians; the plane is the book's (x, y),
-- drawn in BPP as (x, -z), lib/world.lua's mapping):
--   x, y     position, m
--   psi      heading, rad, counter-clockwise from +x
--   omega    turn rate, rad/s, + = left (counter-clockwise); always within
--            [-OMEGA_MAX, OMEGA_MAX]
--   SPEED    13 m/s, fixed: the aircraft cannot stop, slow or reverse
--
--   M.new(x, y, psi)        a UAV
--   M.command(u, omega)     set the turn rate for the next outer-loop tick
--                           (clipped to the limit; returns the value used)
--   M.advance(u, dt)        fly dt seconds at the commanded turn rate:
--                           an exact circular arc (a straight line at 0)
--   M.radius()              the smallest turn radius, SPEED / OMEGA_MAX
--
-- Plain Lua (5.1-5.4), no BPP: used by ch13/uav.lua, its scenes and
-- checks/fixedwing.lua.
--

local M = {}

M.SPEED = 13                          -- m/s (book)
M.PHI_MAX = math.rad(20)              -- bank limit (book)
M.G = 9.81
M.OMEGA_MAX = M.G * math.sin(M.PHI_MAX) / (2 * M.SPEED)   -- Eq. 13.14, rad/s
M.HZ = 10                             -- outer-loop rate (book)

function M.new(x, y, psi) return { x = x, y = y, psi = psi, omega = 0 } end

function M.command(u, omega)
  if omega > M.OMEGA_MAX then omega = M.OMEGA_MAX elseif omega < -M.OMEGA_MAX then omega = -M.OMEGA_MAX end
  u.omega = omega
  return omega
end

function M.advance(u, dt)
  local w, s = u.omega, M.SPEED
  if math.abs(w) < 1e-12 then
    u.x, u.y = u.x + s * dt * math.cos(u.psi), u.y + s * dt * math.sin(u.psi)
  else
    local p1 = u.psi + w * dt
    u.x = u.x + s / w * (math.sin(p1) - math.sin(u.psi))
    u.y = u.y - s / w * (math.cos(p1) - math.cos(u.psi))
    u.psi = p1
  end
  -- heading kept in (-pi, pi]
  if u.psi > math.pi then u.psi = u.psi - 2 * math.pi elseif u.psi <= -math.pi then u.psi = u.psi + 2 * math.pi end
end

function M.radius() return M.SPEED / M.OMEGA_MAX end

return M
