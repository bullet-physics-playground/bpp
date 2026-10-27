--
-- probes/step_response.lua -- one vehicle's response to a velocity step,
-- commanded as AP commands it: a leg every 1/apHz s (T = 0.2 s, 5 Hz) to
-- the point p + u T, with u along +x for 8 s, then 0. How lib/pointmass.lua's
-- defaults were fitted to the quadcopter (lib/README.md, FINDINGS F87).
--
-- Environment:
--   VMOD   the vehicle module (default quadcopter.vehicle; lib.pointmass)
--   U      the commanded speed, m/s (default 2)
--   LAG    lib.pointmass only: set its limits to the drone's 6 m/s and
--          6.87 m/s^2 and this lag (s), without sliders
-- The vehicle takes off (if it must), holds 3 s, then gets the step.
--
-- DEFINITIONS (printed): one line "STEP t vx y" every 0.1 s from the step
-- (t s since the step, vx its velocity along x m/s, y its height m), then
-- a summary: t63 and t90, the times to 63% and 90% of U (s); peak and
-- steady (mean over 5-8 s) speed (m/s); amax, the largest change of vx
-- over 0.1 s, / 0.1 s (m/s^2); stop37, stop10: the times after the stop
-- to fall to 37% and 10% of U (s).
--
-- Run from the ArtificialPhysics folder (about 20 s of flight):
--   U=2 bpp -f probes/step_response.lua -n 700
--   VMOD=lib.pointmass LAG=0.45 U=2 bpp -f probes/step_response.lua -n 700
--
local common = require "common"
v:addParam("altitude", 12, 4, 40, 1, "the drone's flight height (m)")
local V = require(os.getenv("VMOD") or "quadcopter.vehicle")
local U = tonumber(os.getenv("U") or "2")
if V.limits and os.getenv("LAG") then V.limits(6.0, 6.87, tonumber(os.getenv("LAG"))) end
local DT, STEPS, T = 1 / 250, 8, 0.2
common.setTiming(DT, 1, DT)
common.gravity(-9.81)
v:add(Plane(0, 1, 0, V.floorY or 0, 50))

local t, phase, tStep, nextAp = 0, "takeoff", 0, 0
local d = V.new(0, 0, V.planeY())
local log = {}
local function physicsStep()
  if phase == "takeoff" then
    V.guide(d, "takeoff", t, DT)
    if d.ready then V.join(d, t); phase = "settle"; tStep = t + 3 end
  else
    if phase == "settle" and t >= tStep then phase = "go"; tStep = t; nextAp = t end
    if phase == "go" and t >= nextAp then
      local u = (t - tStep < 8) and U or 0
      V.command(d, d.px + u * T, V.planeY(), d.pz, T, t)
      nextAp = nextAp + T
    end
    V.guide(d, "ap", t, DT)
  end
  V.step(d, DT)
  if phase == "go" then log[#log + 1] = { t - tStep, d.vx, d.py } end
  t = t + DT
end
v:preSim(function(N)
  for _ = 1, STEPS - 1 do physicsStep(); v:stepSimulation(DT, 1, DT) end
  physicsStep()
end)
v:preStop(function()
  local s = {}
  for i = 1, #log, 25 do
    s[#s + 1] = log[i]
    print(string.format("STEP %.2f %.4f %.3f", log[i][1], log[i][2], log[i][3]))
  end
  if #s < 100 then print("step_response: run longer (-n 700) for the summary"); return end
  local function cross(level, from, up)
    for _, r in ipairs(s) do
      if r[1] >= from and ((up and r[2] >= level) or (not up and r[2] <= level)) then return r[1] - from end
    end
    return -1
  end
  local peak, amax, sum, n = 0, 0, 0, 0
  for i, r in ipairs(s) do
    peak = math.max(peak, r[2])
    if i > 1 then amax = math.max(amax, math.abs(r[2] - s[i - 1][2]) / (r[1] - s[i - 1][1])) end
    if r[1] > 5 and r[1] < 8 then sum, n = sum + r[2], n + 1 end
  end
  print(string.format("step_response: U %.2f t63 %.2f s t90 %.2f s peak %.3f steady %.3f amax %.2f stop37 %.2f s stop10 %.2f s",
    U, cross(0.632 * U, 0, true), cross(0.9 * U, 0, true), peak, sum / n, amax,
    cross(0.368 * U, 8, false), cross(0.1 * U, 8, false)))
end)
