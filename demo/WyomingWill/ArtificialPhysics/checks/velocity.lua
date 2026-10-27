--
-- checks/velocity.lua -- velocity commands (BOOK.md G4): every vehicle
-- that has velocity() flies the velocity it is given (called by
-- checks/vehicles.sh)
--
-- For VMOD = the vehicle module (lib.ideal, lib.pointmass,
-- quadcopter.vehicle, boat.vehicle): the vehicle deploys (the drone takes
-- off to 12 m), holds 2 s, is told velocity (0.4, 0, -0.3) m/s once, and
-- then nothing for 8 s; then velocity 0 for 6 s.
--   follows  its mean velocity over the last 3 s of the 8 is within
--            2 cm/s of the command in x and z (|u| = 0.5 m/s)
--   height   the drone holds its height within 0.3 m (the command's
--            vy = 0; nothing pulls it back to 12 m)
--   stops    after velocity 0 its speed is below 1 cm/s at the end
--
-- Run from the ArtificialPhysics folder, inside BPP:
--   VMOD=boat.vehicle bpp -f checks/velocity.lua -n 700
-- Prints ok/FAIL lines and ends with PASS or FAIL.
--
local common = require "common"
v:addParam("altitude", 12, 4, 40, 1, "the drone's flight height (m)")
local which = os.getenv("VMOD") or "lib.pointmass"
local V = require(which)
local DT, STEPS = 1 / 250, 8
common.setTiming(DT, 1, DT)
common.gravity(-9.81)
v:add(Plane(0, 1, 0, V.floorY or 0, 50))

local UX, UZ = 0.4, -0.3
local t, phase, tMark = 0, "deploy", 0
local d = V.new(0, 0, V.planeY())
local sx, sz, n, y0 = 0, 0, 0, nil
local fails, nTests, done = 0, 0, false
local function check(name, ok, detail)
  nTests = nTests + 1
  if not ok then fails = fails + 1 end
  print(string.format("%s %s %s: %s", ok and "ok  " or "FAIL", which, name, detail))
end

local function physicsStep()
  if phase == "deploy" then
    V.guide(d, "takeoff", t, DT)
    if d.ready then V.join(d, t); phase = "hold"; tMark = t + 2 end
  else
    if phase == "hold" and t >= tMark then
      phase = "go"; tMark = t + 8; y0 = d.py
      V.velocity(d, UX, 0, UZ, t)
    elseif phase == "go" and t >= tMark then
      check("follows", math.abs(sx / n - UX) < 0.02 and math.abs(sz / n - UZ) < 0.02,
        string.format("mean velocity (%.3f, %.3f) m/s over 3 s, told (%.1f, %.1f)", sx / n, sz / n, UX, UZ))
      if which == "quadcopter.vehicle" then
        check("height", math.abs(d.py - y0) < 0.3, string.format("height changed %.3f m in 8 s", d.py - y0))
      end
      phase = "stop"; tMark = t + 6
      V.velocity(d, 0, 0, 0, t)
    elseif phase == "stop" and t >= tMark and not done then
      local sp = math.sqrt(d.vx * d.vx + d.vz * d.vz)
      check("stops", sp < 0.01, string.format("speed %.4f m/s 6 s after velocity 0", sp))
      done = true
    end
    if phase == "go" and t >= tMark - 3 then sx, sz, n = sx + d.vx, sz + d.vz, n + 1 end
    V.guide(d, "ap", t, DT)
  end
  V.step(d, DT)
  t = t + DT
end

v:preSim(function(N)
  for _ = 1, STEPS - 1 do physicsStep(); v:stepSimulation(DT, 1, DT) end
  physicsStep()
end)
v:preStop(function()
  if not done then print("FAIL " .. which .. ": the run ended before the checks (give more frames)"); fails = fails + 1 end
  if fails == 0 then print(string.format("PASS velocity %s: %d tests", which, nTests))
  else print(string.format("FAIL velocity %s: %d of %d failed", which, fails, nTests)) end
end)
