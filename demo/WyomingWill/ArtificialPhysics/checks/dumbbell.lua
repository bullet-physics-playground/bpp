--
-- checks/dumbbell.lua -- Ch. 13's dumbbell agent (ch13/dumbbell.lua,
-- Eqs. 13.19-13.23, 13.25) on the kinematic Pioneer (the wheels of
-- ground/vehicle.lua, no contacts): the equations, the three-point turn
-- and the camera ring (book/ch13.md E10, E11b; ch13/README.md)
--
-- DEFINITIONS (metres, seconds, degrees; as ch13/dumbbell.lua):
--   radius, point, gap   dumbbell.lua's measures at the end of a run
--   segments  the runs of travel: B backwards, F forwards (|u| > 1 mm/s)
--   passes    changes of sign of u
--   still     both wheels commanded 0 at the end
--
-- Tests:
--   equations  one tick by hand: a force ahead on the front particle gives
--              u = F (m 1), a force to the left on it turns left by
--              rFront F, the same on the back particle turns right; the
--              (1 - mu) factors; the caps; mu grows on a change of sign
--              (Eq. 13.23) and decays otherwise; static friction (g > 0)
--              holds a command whose force is under mu m g
--   turn       the attractor 5 m dead astern: backs while turning, then
--              forwards (segments start B, F: the three-point turn,
--              PDF 464), camera on the ring and pointing in (radius
--              < 0.1 m, point < 5 deg) within 20 s
--   no spring  the same with kappa 0 (force law only): backs straight
--              to it and ends pointing away (point > 170 deg): the torque
--              law is what points the camera
--   no friction  the same with kMore 0 (mu stays 0): still swinging at
--              60 s (|u| > 0.3 m/s at some tick of the last 10 s)
--   static     the same with g 0.05: still at 60 s, fewer than a tenth
--              of the passes without it (without, it creeps back and
--              forth at the minimum wheel speed for ever)
--   ring       4 robots, seeds 1-5, random bearings 5-8 m out, 300 s:
--              plain (spread 0): mean gap > 1.6 (they stay at the
--              bearings they arrived at); spread 60 s: mean gap < 1.35
--              and mean point < 6 deg, every radius < 0.15 m
--
-- Run from the ArtificialPhysics folder (about 3 s in Lua 5.1):
--   lua5.1 checks/dumbbell.lua   or inside BPP: bpp -f checks/dumbbell.lua -n 1
--
local here = (arg and arg[0] and arg[0]:match("^(.*)[/\\]checks[/\\][^/\\]*$"))
if here then package.path = here .. "/?.lua;" .. package.path
else package.path = "./?.lua;../?.lua;" .. package.path end
local DB = require "ch13.dumbbell"
local Veh = require "ground.vehicle"
local rng = require "lib.rng"

local fails, count = 0, 0
local function check(name, ok, detail)
  count = count + 1
  if not ok then fails = fails + 1 end
  print(string.format("%s %-12s %s", ok and "ok  " or "FAIL", name, detail or ""))
end
print("dumbbell: " .. _VERSION)

local function params(over)
  local P = {}
  for k, val in pairs(DB.P) do P[k] = val end
  for k, val in pairs(over or {}) do P[k] = val end
  return P
end

-- equations, one tick each, heading +x
local P = params()
local a = DB.new(0, 0, 0)
local u1 = DB.update(a, { 0.2, 0 }, { 0, 0 }, 0, P)
local b = DB.new(0, 0, 0)
local _, om1 = DB.update(b, { 0, 0.2 }, { 0, 0 }, 0, P)
local c = DB.new(0, 0, 0)
local _, om2 = DB.update(c, { 0, 0 }, { 0, 0.2 }, 0, P)
local d = DB.new(0, 0, 0); d.u, d.muU = 0.1, 0.5
local u3 = DB.update(d, { 0.1, 0 }, { 0, 0 }, 0, P)
local e = DB.new(0, 0, 0)
local u4, om4 = DB.update(e, { 9, 0 }, { 0, 0 }, 9, P)
local f = DB.new(0, 0, 0); f.u, f.muU = 0.2, 0.1
DB.update(f, { -0.5, 0 }, { 0, 0 }, 0, P)
local g = DB.new(0, 0, 0); g.u, g.muU = 0.2, 0.1
DB.update(g, { 0.1, 0 }, { 0, 0 }, 0, P)
local h = DB.new(0, 0, 0); h.muU = 0.5
local u5 = DB.update(h, { 0.02, 0 }, { 0, 0 }, 0, params({ g = 0.05 }))
check("equations", math.abs(u1 - 0.2) < 1e-12 and math.abs(om1 - P.rFront * 0.2) < 1e-12
  and math.abs(om2 + P.rBack * 0.2) < 1e-12 and math.abs(u3 - 0.1) < 1e-12
  and u4 == P.uMax and om4 == P.omegaMax
  and math.abs(f.muU - (0.1 + P.kMore * 0.9)) < 1e-12 and math.abs(g.muU - 0.1 * (1 - P.kLess)) < 1e-12
  and u5 == 0,
  string.format("u %.3f, Omega %+.3f / %+.3f, (1-mu) %.3f, caps %.1f %.1f, mu %.4f / %.4f, static %g",
    u1, om1, om2, u3, u4, om4, f.muU, g.muU, u5))

-- one or more kinematic Pioneers for secs seconds; spread: seconds of the
-- weak pointing spring
local function run(starts, cx, cy, secs, P, spread)
  local ag, kin = {}, {}
  for i, st in ipairs(starts) do kin[i] = DB.kin(st[1], st[2], st[3]); ag[i] = DB.new(st[1], st[2], st[3]) end
  local kappa = P.kappa
  local segs, last, passes, late = {}, 0, 0, 0
  for tick = 1, secs * P.hz do
    P.kappa = (tick <= (spread or 0) * P.hz) and P.kappaSpread or kappa
    for i, x in ipairs(ag) do x.x, x.y, x.psi = kin[i].x, kin[i].y, kin[i].psi end
    local F = DB.ring(ag, cx, cy, P)
    for i, x in ipairs(ag) do
      local u0 = x.u
      local u, om = DB.update(x, F[i][1], F[i][2], F[i][3], P)
      if u * u0 < 0 then passes = passes + 1 end
      if i == 1 then
        local sg = (u > 1e-3) and 1 or (u < -1e-3) and -1 or 0
        if sg ~= 0 and sg ~= last then segs[#segs + 1] = sg > 0 and "F" or "B"; last = sg end
        if tick > (secs - 10) * P.hz then late = math.max(late, math.abs(u)) end
      end
      Veh.drive(kin[i], u, om)
    end
    for _ = 1, 25 do for i = 1, #kin do DB.kinStep(kin[i], 1 / (25 * P.hz)) end end
  end
  P.kappa = kappa
  for i, x in ipairs(ag) do x.x, x.y, x.psi = kin[i].x, kin[i].y, kin[i].psi end
  local m = DB.measure(ag, cx, cy, P)
  m.segs, m.passes, m.late = table.concat(segs), passes, late
  m.still = kin[1].cl == 0 and kin[1].cr == 0
  return m
end

local m = run({ { 0, 0, 0 } }, -5, 0, 20, params())
check("turn", m.segs:sub(1, 2) == "BF" and m.radius < 0.1 and m.point < 5,
  string.format("segments %s..., radius %.3f m, point %.1f deg at 20 s", m.segs:sub(1, 4), m.radius, m.point))
local plain = run({ { 0, 0, 0 } }, -5, 0, 60, params())
m = run({ { 0, 0, 0 } }, -5, 0, 60, params({ kappa = 0 }))
check("no spring", m.segs:sub(1, 1) == "B" and m.point > 170,
  string.format("segments %s..., point %.1f deg", m.segs:sub(1, 4), m.point))
m = run({ { 0, 0, 0 } }, -5, 0, 60, params({ kMore = 0 }))
check("no friction", m.late > 0.3, string.format("|u| up to %.2f m/s in the last 10 s, %d passes", m.late, m.passes))
m = run({ { 0, 0, 0 } }, -5, 0, 60, params({ g = 0.05 }))
check("static", m.still and m.passes * 10 < plain.passes,
  string.format("%d passes (%d without), still %s, radius %.3f m, point %.1f deg", m.passes, plain.passes,
    tostring(m.still), m.radius, m.point))

local res = {}
for _, spread in ipairs({ 0, 60 }) do
  local gap, point, worst = 0, 0, 0
  for seed = 1, 5 do
    local s, starts = rng.new(seed), {}
    for i = 1, 4 do
      local an, r = s:random() * 2 * math.pi, 5 + 3 * s:random()
      starts[i] = { r * math.cos(an), r * math.sin(an), s:random() * 2 * math.pi }
    end
    m = run(starts, 0, 0, 300, params(), spread)
    gap, point, worst = gap + m.gap / 5, point + m.point / 5, math.max(worst, m.radius)
  end
  res[spread] = { gap = gap, point = point, worst = worst }
  print(string.format("     spread %2d s: mean gap %.2f, mean point %.1f deg, worst radius %.3f m", spread, gap, point, worst))
end
check("ring", res[0].gap > 1.6 and res[60].gap < 1.35 and res[60].point < 6 and res[60].worst < 0.15,
  string.format("gap %.2f -> %.2f, point %.1f deg, radius <= %.3f m (plain -> spread 60 s)",
    res[0].gap, res[60].gap, res[60].point, res[60].worst))

print(string.format("dumbbell: %d checks, %d failed", count, fails))
print(fails == 0 and ("PASS dumbbell: " .. count .. " tests") or "FAIL dumbbell")
