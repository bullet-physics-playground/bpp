--
-- ch13/uav.lua -- Ch. 13's fixed-wing experiments (Apker and Potter,
-- §13.2.3-13.4.2, PDF 457-467; book/ch13.md E8, E9, E12): constant-speed
-- UAVs (fixedwing/model.lua) steered by the point-mass ("gravity") law or
-- by the heading-particle torque law
--
-- DEFINITIONS (metres, seconds, radians; + = counter-clockwise / left):
--   bearing     the direction from the UAV to another particle
--   theta       bearing minus the UAV's heading, wrapped to (-pi, pi]:
--               0 dead ahead, +pi/2 on the left, pi behind
--   n           the UAV's left normal (cos(psi + pi/2), sin(psi + pi/2))
--
-- GRAVITY (POINT-MASS) LAW. Each target attracts with F = G / r^2 (no
-- attract-repel boundary: targets always attract), each other UAV within
-- REP_RANGE repels with G / r^2; the UAV has constant speed, so only the
-- turning equation acts (Eq. 13.8, PDF 453):
--   Omega_new = (Omega_old + (sum F) . n / m) mu
-- clipped to Omega_max. mu is the book's retention factor (1 = no
-- friction).
--
-- TORQUE LAW (§13.3, Eqs. 13.15-13.18, PDF 460-462). A virtual torsion
-- spring to each particle: a target gives torque kappa theta (turning the
-- UAV toward it), a UAV within REP_RANGE gives kappa theta' with theta' =
-- wrap(theta + pi), the angle to the direction straight away from it
-- (turning the UAV away; the printed "+kappa theta" is zero for a
-- neighbour dead ahead, the one place a repulsion must act). Then
-- Eqs. 13.16-13.18, with Eq. 13.22's friction factor available:
--   Omega_new = (Omega_old + (sum tau) dt / I) (1 - muOmega)
-- clipped to Omega_max; muOmega = 0 (the default) is Eq. 13.18 exactly.
-- kappa dt / I = Omega_max / pi for every pair, the book's rule that no
-- single pair can command more than the turn limit (PDF 466).
--
-- OUR CHOICES (the book gives none of these numbers; book/ch13.md E12):
--   G 20000 (m = 1)   a target 400 m away already asks for ~Omega_max
--                     (0.13 rad/s), so the law is bang-bang as the book
--                     says (PDF 458)
--   mu 0.5            gravity law's retention
--   muOmega 0         torque law: Eq. 13.18 as printed. With any friction
--                     (0.01-0.05) a UAV leaving with the targets straight
--                     behind it stays on course: the springs to targets
--                     just left and just right of its tail cancel, a
--                     stable balance (3-4 runs in 20; FINDINGS F76)
--   REP_RANGE 50 m    UAV-UAV repulsion, both laws (half a turn radius)
--   10 targets uniform in a 60 x 80 m rectangle at the origin; 5 UAVs
--   start on a 400 m circle round it, heading for it +- 30 deg
--
--   M.newWorld(opts)   { uavs, targets, law = "gravity"|"torque", t }
--                      opts: law, seed (lib/rng stream), n (5), nTargets
--                      (10), or uavs / targets given explicitly
--   M.step(w)          one outer-loop tick (1/10 s): commands, then flight
--   M.run(w, secs, from) runs secs seconds; measures from time `from`:
--     over     share of (UAV, tick) samples inside the targets' rectangle
--     omega    mean |Omega|, rad/s (the book's "energy")
--     spread   RMS distance from the targets' centroid, m
--     minSep   least distance between two UAVs, m
--
-- Plain Lua (5.1-5.4): used by UAV-Targets.lua, UAV-Attractor.lua and
-- checks/fixedwing.lua.
--

local FW = require "fixedwing.model"
local rng = require "lib.rng"

local M = {}
M.G, M.MU, M.MU_OMEGA, M.REP_RANGE = 20000, 0.5, 0, 50
M.RECT = { w = 60, h = 80 }

local pi = math.pi
local atan2 = math.atan2 or function(y, x) return math.atan(y, x) end
local function wrap(a)
  a = (a + pi) % (2 * pi) - pi
  if a <= -pi then a = a + 2 * pi end
  return a
end
M.wrap = wrap

-- Omega asked of UAV u by one law, from the targets and the other UAVs
local function gravity(w, u)
  local nx, ny = -math.sin(u.psi), math.cos(u.psi)
  local fn = 0
  for _, tg in ipairs(w.targets) do
    local dx, dy = tg.x - u.x, tg.y - u.y
    local r2 = dx * dx + dy * dy
    if r2 > 1e-9 then
      local r = math.sqrt(r2)
      fn = fn + M.G / r2 * (dx * nx + dy * ny) / r
    end
  end
  for _, o in ipairs(w.uavs) do
    if o ~= u then
      local dx, dy = o.x - u.x, o.y - u.y
      local r2 = dx * dx + dy * dy
      if r2 > 1e-9 and r2 < M.REP_RANGE ^ 2 then
        local r = math.sqrt(r2)
        fn = fn - M.G / r2 * (dx * nx + dy * ny) / r
      end
    end
  end
  return (u.omega + fn) * M.MU
end

local function torque(w, u)
  local k = FW.OMEGA_MAX / pi                 -- kappa dt / I, one pair
  local s = 0
  for _, tg in ipairs(w.targets) do
    s = s + k * wrap(atan2(tg.y - u.y, tg.x - u.x) - u.psi)
  end
  for _, o in ipairs(w.uavs) do
    if o ~= u then
      local dx, dy = o.x - u.x, o.y - u.y
      if dx * dx + dy * dy < M.REP_RANGE ^ 2 then s = s + k * wrap(atan2(dy, dx) - u.psi + pi) end
    end
  end
  return (u.omega + s) * (1 - M.MU_OMEGA)
end

function M.newWorld(opts)
  opts = opts or {}
  local s = rng.new(opts.seed or 1)
  local w = { law = opts.law or "torque", t = 0, uavs = {}, targets = {} }
  if opts.targets then w.targets = opts.targets
  else
    for _ = 1, opts.nTargets or 10 do
      w.targets[#w.targets + 1] = { x = (s:random() - 0.5) * M.RECT.w, y = (s:random() - 0.5) * M.RECT.h }
    end
  end
  if opts.uavs then w.uavs = opts.uavs
  else
    for _ = 1, opts.n or 5 do
      local a = s:random() * 2 * pi
      local x, y = 400 * math.cos(a), 400 * math.sin(a)
      w.uavs[#w.uavs + 1] = FW.new(x, y, wrap(a + pi + (s:random() - 0.5) * pi / 3))
    end
  end
  return w
end

function M.step(w)
  local dt = 1 / FW.HZ
  local want = {}
  for i, u in ipairs(w.uavs) do
    want[i] = (w.law == "gravity") and gravity(w, u) or torque(w, u)
  end
  for i, u in ipairs(w.uavs) do FW.command(u, want[i]); FW.advance(u, dt) end
  w.t = w.t + dt
end

function M.run(w, secs, from)
  local n, inside, om, d2, minSep = 0, 0, 0, 0, math.huge
  local cx, cy = 0, 0
  for _, tg in ipairs(w.targets) do cx, cy = cx + tg.x / #w.targets, cy + tg.y / #w.targets end
  local steps = math.floor(secs * FW.HZ + 0.5)
  for _ = 1, steps do
    M.step(w)
    if w.t >= (from or 0) then
      for i, u in ipairs(w.uavs) do
        n = n + 1
        if math.abs(u.x) <= M.RECT.w / 2 and math.abs(u.y) <= M.RECT.h / 2 then inside = inside + 1 end
        om = om + math.abs(u.omega)
        d2 = d2 + (u.x - cx) ^ 2 + (u.y - cy) ^ 2
        for j = i + 1, #w.uavs do
          local o = w.uavs[j]
          minSep = math.min(minSep, math.sqrt((u.x - o.x) ^ 2 + (u.y - o.y) ^ 2))
        end
      end
    end
  end
  if n == 0 then return {} end
  return { over = inside / n, omega = om / n, spread = math.sqrt(d2 / n), minSep = minSep }
end

return M
