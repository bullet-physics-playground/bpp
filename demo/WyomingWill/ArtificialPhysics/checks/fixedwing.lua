--
-- checks/fixedwing.lua -- the fixed-wing UAV (fixedwing/model.lua) and
-- Ch. 13's UAV experiments (ch13/uav.lua) against the book
--
-- DEFINITIONS (metres, seconds, radians):
--   Omega_max   Eq. 13.14, g sin(20 deg) / (2 x 13 m/s) = 0.1290 rad/s
--   radius      13 m/s / Omega_max = 100.7 m, the smallest turn
--   closest     the least distance from the UAV to the attractor, m
--   pass        coming within 10 m of the attractor (counted again after
--               moving 30 m away)
--   over, spread, |Omega|   ch13/uav.lua's measures, from 120 to 600 s,
--               20 seeds per law
--
-- Tests:
--   limit       Omega_max = 0.1290 and radius 100.7 m; a command of 1 rad/s
--               is clipped to it
--   circle      a full-rate turn returns to its start after 2 pi / Omega_max
--               (within 1 mm) and never strays more than 2 x radius
--   behind      (E8, gravity law) an attractor 200 m directly behind: no
--               sideways force, the UAV flies away (> 1500 m after 120 s)
--   outside     (E8) an attractor outside the unreachable zones, (150, 150):
--               overflown again and again (>= 5 passes in 600 s)
--   inside      (E8) an attractor inside the left zone, (0, 50): orbited
--               for ever, never closer than 101 - 51 = 50 m (49.5-50.5 m)
--   torque behind  the torque law turns round for an attractor behind and
--               overflies it (>= 5 passes)
--   targets     (E12) the torque law keeps the UAVs over the targets more
--               (mean over higher than the gravity law's) and closer
--               (mean spread lower), with no UAV leaving (every run's
--               spread < 400 m); |Omega| is printed, not tested (FINDINGS
--               F76: both laws turn at nearly the limit)
--
-- Run from the ArtificialPhysics folder (about 6 s): lua5.1 checks/fixedwing.lua
-- or inside BPP: bpp -f checks/fixedwing.lua -n 1
--
local here = (arg and arg[0] and arg[0]:match("^(.*)[/\\]checks[/\\][^/\\]*$"))
if here then package.path = here .. "/?.lua;" .. package.path
else package.path = "./?.lua;../?.lua;" .. package.path end
local FW = require "fixedwing.model"
local U = require "ch13.uav"

local fails, count = 0, 0
local function check(name, ok, detail)
  count = count + 1
  if not ok then fails = fails + 1 end
  print(string.format("%s %-44s %s", ok and "ok  " or "FAIL", name, detail or ""))
end
print("fixedwing: " .. _VERSION)

local u = FW.new(0, 0, 0)
local used = FW.command(u, 1)
check("limit", math.abs(FW.OMEGA_MAX - 0.1290) < 5e-5 and math.abs(FW.radius() - 100.7) < 0.05 and used == FW.OMEGA_MAX,
  string.format("Omega_max %.4f rad/s, radius %.1f m, 1 rad/s -> %.4f", FW.OMEGA_MAX, FW.radius(), used))

local far, T = 0, 2 * math.pi / FW.OMEGA_MAX
local n = 1000
for _ = 1, n do FW.advance(u, T / n); far = math.max(far, math.sqrt(u.x * u.x + u.y * u.y)) end
check("circle", math.sqrt(u.x * u.x + u.y * u.y) < 1e-3 and far <= 2 * FW.radius() + 1e-6,
  string.format("back within %.1e m after %.1f s, farthest %.1f m", math.sqrt(u.x * u.x + u.y * u.y), T, far))

local function single(law, tx, ty, secs)
  local w = U.newWorld({ law = law, uavs = { FW.new(0, 0, 0) }, targets = { { x = tx, y = ty } } })
  local closest, passes, near, late = math.huge, 0, false, math.huge
  for _ = 1, secs * FW.HZ do
    U.step(w)
    local a = w.uavs[1]
    local d = math.sqrt((a.x - tx) ^ 2 + (a.y - ty) ^ 2)
    closest = math.min(closest, d)
    if w.t > 60 then late = math.min(late, d) end
    if d < 10 and not near then passes, near = passes + 1, true elseif d > 30 then near = false end
  end
  local a = w.uavs[1]
  return { closest = closest, passes = passes, late = late, final = math.sqrt((a.x - tx) ^ 2 + (a.y - ty) ^ 2) }
end

local r = single("gravity", -200, 0, 120)
check("behind (gravity)", r.final > 1500, string.format("%.0f m away after 120 s, closest %.0f m", r.final, r.closest))
r = single("gravity", 150, 150, 600)
check("outside (gravity)", r.passes >= 5, string.format("%d passes within 10 m in 600 s, closest %.2f m", r.passes, r.closest))
r = single("gravity", 0, 50, 600)
check("inside (gravity)", r.closest >= 49.5 and r.closest <= 50.5 and r.late >= 49.5,
  string.format("closest %.2f m (101 - 51 = 50), after 60 s %.2f m", r.closest, r.late))
r = single("torque", -200, 0, 600)
check("torque behind", r.passes >= 5, string.format("turned round: %d passes within 10 m, closest %.2f m", r.passes, r.closest))

local agg = {}
for _, law in ipairs({ "gravity", "torque" }) do
  local a = { over = 0, spread = 0, omega = 0, worst = 0, minSep = math.huge }
  for seed = 1, 20 do
    local m = U.run(U.newWorld({ law = law, seed = seed }), 600, 120)
    a.over, a.spread, a.omega = a.over + m.over / 20, a.spread + m.spread / 20, a.omega + m.omega / 20
    a.worst, a.minSep = math.max(a.worst, m.spread), math.min(a.minSep, m.minSep)
  end
  agg[law] = a
  print(string.format("     %-8s over %.3f  spread %.0f m (worst run %.0f)  |Omega| %.3f rad/s  least separation %.2f m",
    law, a.over, a.spread, a.worst, a.omega, a.minSep))
end
check("targets (E12)", agg.torque.over > agg.gravity.over and agg.torque.spread < agg.gravity.spread
  and agg.torque.worst < 400 and agg.gravity.worst < 400,
  string.format("over %.3f vs %.3f, spread %.0f vs %.0f m (torque vs gravity)", agg.torque.over, agg.gravity.over,
    agg.torque.spread, agg.gravity.spread))

print(string.format("fixedwing: %d checks, %d failed", count, fails))
print(fails == 0 and ("PASS fixedwing: " .. count .. " tests") or "FAIL fixedwing")
