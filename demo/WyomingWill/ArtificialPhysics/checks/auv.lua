--
-- checks/auv.lua -- the torpedo-shaped AUV (auv/model.lua) and Ch. 13's
-- laws on it (ch13/auv.lua): one AUV, one attractor (ch13/README.md)
--
-- DEFINITIONS (metres, seconds, radians; R = R_MIN = 6.03 m; 600 s runs
-- measured from 60 s, as ch13/auv.lua's run):
--   closest, passes, near, speed, power   ch13/auv.lua's measures
--
-- Tests:
--   prestero  his model's steady turn (auv/model.lua steadyTurn): at
--             full fin (13.6 deg) a radius of 6.03 m (6.0-6.1), the same
--             at 0.5 and 2.3 m/s (within 1 mm); at 4 deg and 1.54 m/s,
--             9.5-10.5 deg/s (his sea trials: "roughly ten degrees per
--             second", §8.3)
--   limits    speed clipped to [0.5, 2.3] m/s, turn rate to +-u / R
--   circle    a full-rate turn at the slowest and at top speed: back at
--             its start within 1 mm after 2 pi R / u, never farther than
--             2R: the same circle at every speed
--   inside    the attractor at (0, R/2), inside the left unreachable
--             zone: never closer than R - R/2 = R/2 (within 1%), with
--             either law and with the speed fixed or free: slowing down
--             does not shrink the zone
--   behind    the attractor 2R dead astern: the gravity law flies away
--             (> 900 m at fixed speed; with the speed channel it slows to
--             0.5 m/s and still leaves, > 250 m); the torque law turns
--             round (>= 5 passes within 2 m)
--   speed     attractor outside the zones, torque law: the speed channel
--             keeps the share of time within R of it (within 0.05 of the
--             fixed speed's) at under 70% of cruise's drag power
--
-- Run from the ArtificialPhysics folder (about 1 s in Lua 5.1):
--   lua5.1 checks/auv.lua   or inside BPP: bpp -f checks/auv.lua -n 1
--
local here = (arg and arg[0] and arg[0]:match("^(.*)[/\\]checks[/\\][^/\\]*$"))
if here then package.path = here .. "/?.lua;" .. package.path
else package.path = "./?.lua;../?.lua;" .. package.path end
local A = require "auv.model"
local U = require "ch13.auv"

local fails, count = 0, 0
local function check(name, ok, detail)
  count = count + 1
  if not ok then fails = fails + 1 end
  print(string.format("%s %-8s %s", ok and "ok  " or "FAIL", name, detail or ""))
end
print("auv: " .. _VERSION)
local R = A.R_MIN

local _, r4 = A.steadyTurn(math.rad(4), 1.54)
local _, _, Rlo = A.steadyTurn(A.DELTA_MAX, A.U_MIN)
local _, _, Rhi = A.steadyTurn(A.DELTA_MAX, A.U_MAX)
check("prestero", R > 6.0 and R < 6.1 and math.abs(Rlo - R) < 1e-3 and math.abs(Rhi - R) < 1e-3
  and math.deg(math.abs(r4)) > 9.5 and math.deg(math.abs(r4)) < 10.5,
  string.format("full fin: R %.3f m (%.3f at 0.5 m/s, %.3f at 2.3); 4 deg at 1.54 m/s: %.2f deg/s", R, Rlo, Rhi, math.deg(math.abs(r4))))

local a = A.new(0, 0, 0)
local u1, o1 = A.command(a, 5, 9)
local u2, o2 = A.command(a, 0, -9)
check("limits", u1 == A.U_MAX and math.abs(o1 - A.U_MAX / R) < 1e-12 and u2 == A.U_MIN
  and math.abs(o2 + A.U_MIN / R) < 1e-12,
  string.format("(5, 9) -> (%.2f m/s, %.4f rad/s); (0, -9) -> (%.2f, %.4f)", u1, o1, u2, o2))

local worst, far = 0, 0
for _, u in ipairs({ A.U_MIN, A.U_MAX }) do
  local b = A.new(0, 0, 0, u)
  A.command(b, u, 1)
  local T, steps = 2 * math.pi * R / u, 2000
  for _ = 1, steps do
    A.advance(b, T / steps)
    far = math.max(far, math.sqrt(b.x * b.x + b.y * b.y))
  end
  worst = math.max(worst, math.sqrt(b.x * b.x + b.y * b.y))
end
check("circle", worst < 1e-3 and far <= 2 * R + 1e-6, string.format("back within %.1e m, farthest %.2f m (2R %.1f)", worst, far, 2 * R))

local function run(law, fixed, tx, ty)
  return U.run(U.newWorld({ law = law, fixedSpeed = fixed, auvs = { A.new(0, 0, 0) },
                            targets = { { x = tx, y = ty } } }), 600, 60)
end

local ok, lo, hi = true, math.huge, 0
for _, law in ipairs({ "gravity", "torque" }) do for _, fixed in ipairs({ true, false }) do
  local r = run(law, fixed, 0, R / 2)
  lo, hi = math.min(lo, r.closest), math.max(hi, r.closest)
  ok = ok and math.abs(r.closest - R / 2) < 0.01 * R / 2
end end
check("inside", ok, string.format("closest %.3f-%.3f m (R/2 = %.2f), both laws, speed fixed or free", lo, hi, R / 2))

local gf, gv, tv = run("gravity", true, -2 * R, 0), run("gravity", false, -2 * R, 0), run("torque", false, -2 * R, 0)
check("behind", gf.final > 900 and gv.final > 250 and math.abs(gv.speed - A.U_MIN) < 0.01 and tv.passes >= 5,
  string.format("gravity %.0f m away (fixed) / %.0f m at %.2f m/s (free); torque %d passes", gf.final, gv.final, gv.speed, tv.passes))

local tf, tfree = run("torque", true, 1.5 * R, 1.5 * R), run("torque", false, 1.5 * R, 1.5 * R)
check("speed", math.abs(tf.near - tfree.near) < 0.05 and tfree.power < 0.7,
  string.format("near %.3f (fixed) / %.3f (free), mean speed %.2f m/s, power %.2f of cruise", tf.near, tfree.near, tfree.speed, tfree.power))

print(string.format("auv: %d checks, %d failed", count, fails))
print(fails == 0 and ("PASS auv: " .. count .. " tests") or "FAIL auv")
