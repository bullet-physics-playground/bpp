--
-- checks/triangle.lua -- Ch. 13's triangle of death (ch13/triangle.lua,
-- book/ch13.md E6, PDF 454-456) on the kinematic Pioneer (the wheels of
-- ground/vehicle.lua, no contacts); the Bullet runs are in
-- ch13/triangle_runs.txt (ch13/README.md)
--
-- DEFINITIONS (as ch13/triangle.lua; metres, degrees, 120 s runs, the
-- pull parallel to robot 3's axle):
--   moved     robot 3's move toward the pull's point, m
--   turned    robot 3's heading change, deg
--   centroid  how far the triangle's centroid moved, m
--
-- Tests:
--   law       Fig. 13.8's values: 0 at D, +100 N at 0.5 m, about -50 at
--             2 m, -25 just inside D_max = 4 m, 0 beyond
--   rest      no pull: nothing moves (every pair at the law's zero)
--   escape    pull 25 N: robot 3 drives off and drags the others (moved
--             and centroid > 8 m), with the particle at the centre and
--             0.4 m ahead of it
--   stall     pull 10 N, stop threshold 5 N: robot 3 turns and stops in
--             its new orientation (moved < 0.3 m), turning less with its
--             particle 0.4 m ahead (< 15 deg) than at the centre (> 40
--             deg): the book's first failure, and the offset's part in it
--   no stop   pull 10 N without the stop threshold: it escapes again
--             (moved > 8 m) at offsets 0 and 0.4
--
-- Run from the ArtificialPhysics folder (about 1 s in Lua 5.1):
--   lua5.1 checks/triangle.lua   or inside BPP: bpp -f checks/triangle.lua -n 1
--
local here = (arg and arg[0] and arg[0]:match("^(.*)[/\\]checks[/\\][^/\\]*$"))
if here then package.path = here .. "/?.lua;" .. package.path
else package.path = "./?.lua;../?.lua;" .. package.path end
local T = require "ch13.triangle"

local fails, count = 0, 0
local function check(name, ok, detail)
  count = count + 1
  if not ok then fails = fails + 1 end
  print(string.format("%s %-8s %s", ok and "ok  " or "FAIL", name, detail or ""))
end
print("triangle: " .. _VERSION)

local l05, l1, l2, l4, l5 = T.law(0.5), T.law(1), T.law(2), T.law(3.999), T.law(5)
check("law", math.abs(l05 - 100) < 1e-9 and math.abs(l1) < 1e-12 and l2 < -45 and l2 > -55
  and math.abs(l4 + 25) < 0.1 and l5 == 0,
  string.format("F(0.5) %.0f, F(1) %.0f, F(2) %.1f, F(4-) %.1f, F(5) %.0f N", l05, l1, l2, l4, l5))

local function run(pull, stop, offset)
  T.GOAL, T.STOP = pull, stop
  local r = T.runKin(offset, 0, 120)
  T.GOAL, T.STOP = 25, 5
  r.turned = math.deg(r.turned)
  return r
end

local r = run(0, 5, 0.2)
check("rest", math.abs(r.moved) < 1e-9 and r.centroid < 1e-9, string.format("moved %.1e m, centroid %.1e m", r.moved, r.centroid))

local a, b = run(25, 5, 0), run(25, 5, 0.4)
check("escape", a.moved > 8 and a.centroid > 8 and b.moved > 8 and b.centroid > 8,
  string.format("moved %.1f / %.1f m, centroid %.1f / %.1f m (offset 0 / 0.4)", a.moved, b.moved, a.centroid, b.centroid))

a, b = run(10, 5, 0), run(10, 5, 0.4)
check("stall", a.moved < 0.3 and b.moved < 0.3 and math.abs(a.turned) > 40 and math.abs(b.turned) < 15,
  string.format("moved %.2f / %.2f m, turned %.0f / %.0f deg (offset 0 / 0.4)", a.moved, b.moved, a.turned, b.turned))

a, b = run(10, 0, 0), run(10, 0, 0.4)
check("no stop", a.moved > 8 and b.moved > 8, string.format("moved %.1f / %.1f m (offset 0 / 0.4)", a.moved, b.moved))

print(string.format("triangle: %d checks, %d failed", count, fails))
print(fails == 0 and ("PASS triangle: " .. count .. " tests") or "FAIL triangle")
