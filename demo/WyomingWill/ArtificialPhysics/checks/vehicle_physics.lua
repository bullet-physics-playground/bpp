--
-- checks/vehicle_physics.lua -- one vehicle at a time against its stated
-- specification (BOOK.md G10, G11; called by checks/vehicles.sh)
--
--   VEH=ground  ground/vehicle.lua, the book's Pioneer 3-AT (Ch. 13):
--     straight  told to go far ahead: top speed u_max = 0.5 m/s
--               (0.48-0.505), keeping its line (drift < 2 cm)
--     turn      told to go to a point 5 m to its left in 10 s: turns
--               left, peak turn rate Omega_max = 0.4 rad/s (0.38-0.41),
--               ending pointed at it (within 5 deg) with no swing back
--               faster than 0.1 rad/s
--     gap       told to move 4 cm in 1 s: does not move (< 5 mm), since
--               the wheels would need less than the 0.1 m/s minimum
--   VEH=boat    boat/vehicle.lua, the Ch. 6 ASV:
--     float     dropped 5 cm high: floats at its draft (centre within
--               2 mm of planeY, |v_y| < 1 cm/s after 3 s)
--     speed     told to go far ahead: top speed 0.75-0.85 m/s (the drag
--               balance at 12 N thrust gives 0.79)
--     righting  started heeled 20 deg: upright within 1 deg after 4 s
--     sideways  told to go 90 deg to the side: moves that way (> 3 m in
--               10 s) without turning (yaw < 2 deg) or drifting (< 5 cm)
--
-- Run from the ArtificialPhysics folder, inside BPP:
--   VEH=ground bpp -f checks/vehicle_physics.lua -n 1300
--   VEH=boat   bpp -f checks/vehicle_physics.lua -n 1600
-- Prints ok/FAIL lines and ends with PASS or FAIL.
--
local common = require "common"
local which = os.getenv("VEH") or "ground"
local V = require(which .. ".vehicle")

local DT = 1 / 250
local STEPS = 8                       -- per frame, as lib/swarm.lua
common.setTiming(DT, 1, DT)
common.gravity(-9.81)
local floor = Plane(0, 1, 0, V.floorY or 0, 50)
v:add(floor)

local t, fails, nTests = 0, 0, 0
local function check(name, ok, detail)
  nTests = nTests + 1
  if not ok then fails = fails + 1 end
  print(string.format("%s %s %s: %s", ok and "ok  " or "FAIL", which, name, detail))
end
local function yawOf(d)               -- heading angle in the xz plane (ground: local x)
  local q = d.body:getOrientation()
  local qx, qy, qz, qw = q:x(), q:y(), q:z(), q:w()
  return math.atan2(2 * (qx * qz - qy * qw), 1 - 2 * (qy * qy + qz * qz))
end
local function tiltOf(d)              -- boat: angle of the hull's axis (local z) from vertical
  local q = d.body:getOrientation()
  local qx, qy, qz, qw = q:x(), q:y(), q:z(), q:w()
  local uy = 2 * (qy * qz - qx * qw)          -- world y of the hull's axis
  return math.deg(math.acos(math.max(-1, math.min(1, uy))))
end

-- each test: start(d) after creation, during(d) every step, finish(d)
local Y0 = V.planeY()
local tests = {}
if which == "ground" then
  tests = {
    { name = "straight", secs = 25, start = function(d, s) s.vmax = 0; V.command(d, d.px + 100, Y0, d.pz, 40, t) end,
      during = function(d, s) local sp = math.sqrt(d.vx * d.vx + d.vz * d.vz); if sp > s.vmax then s.vmax = sp end end,
      finish = function(d, s) check("straight", s.vmax >= 0.48 and s.vmax <= 0.505 and math.abs(d.pz) < 0.02,
        string.format("top speed %.3f m/s (u_max 0.5), drift %.3f m", s.vmax, math.abs(d.pz))) end },
    { name = "turn", secs = 8, start = function(d, s) s.wmax, s.wmin, s.tx, s.tz = 0, 0, d.px, d.pz - 5; V.command(d, d.px, Y0, d.pz - 5, 10, t) end,
      during = function(d, s) s.wmax = math.max(s.wmax, d.omega or 0); s.wmin = math.min(s.wmin, d.omega or 0)
        if os.getenv("TRACE") then print(string.format("TR t=%.2f om=%.3f h=(%.2f,%.2f) wl=%.2f wr=%.2f cl=%.2f cr=%.2f dir=%d p=(%.2f,%.2f)", t, d.omega, d.hx, d.hz, d.wl, d.wr, d.cl, d.cr, d.dir, d.px, d.pz)) end end,
      finish = function(d, s)
        local err = math.deg(math.abs(math.atan2(d.hx * (s.tz - d.pz) - d.hz * (s.tx - d.px), d.hx * (s.tx - d.px) + d.hz * (s.tz - d.pz))))
        check("turn", s.wmax >= 0.38 and s.wmax <= 0.41 and s.wmin > -0.1 and err < 5,
        string.format("peak turn rate %.3f rad/s left (Omega_max 0.4), %.3f back; %.1f deg off the target", s.wmax, -s.wmin, err)) end },
    { name = "gap", secs = 5, start = function(d, s) s.x0 = d.px; V.command(d, d.px + 0.04, Y0, d.pz, 1, t) end,
      finish = function(d, s) check("gap", math.abs(d.px - s.x0) < 0.005,
        string.format("moved %.4f m of 0.04 (wheels below 0.1 m/s stay still)", d.px - s.x0)) end },
  }
else
  tests = {
    { name = "float", secs = 3, y = 0.05, start = function() end,
      finish = function(d) check("float", math.abs(d.py - Y0) < 0.002 and math.abs(d.vy) < 0.01,
        string.format("centre %.4f m (afloat %.4f; draft %.3f m), v_y %.4f m/s", d.py, Y0, V.DRAFT, d.vy)) end },
    { name = "speed", secs = 30, start = function(d, s) s.vmax = 0; V.command(d, d.px + 100, Y0, d.pz, 40, t) end,
      during = function(d, s) local sp = math.sqrt(d.vx * d.vx + d.vz * d.vz); if sp > s.vmax then s.vmax = sp end end,
      finish = function(d, s) check("speed", s.vmax >= 0.75 and s.vmax <= 0.85, string.format("top speed %.3f m/s", s.vmax)) end },
    { name = "righting", secs = 4, heel = 20, start = function(d, s) s.t0 = tiltOf(d) end,
      finish = function(d, s) check("righting", tiltOf(d) < 1, string.format("heel %.1f deg -> %.2f deg after 4 s", s.t0, tiltOf(d))) end },
    { name = "sideways", secs = 10, start = function(d, s) s.x0, s.z0, s.y0 = d.px, d.pz, yawOf(d); V.command(d, d.px, Y0, d.pz + 50, 20, t) end,
      finish = function(d, s)
        local yaw = math.deg(math.abs(yawOf(d) - s.y0))
        check("sideways", d.pz - s.z0 > 3 and yaw < 2 and math.abs(d.px - s.x0) < 0.05,
          string.format("moved %.2f m sideways, turned %.2f deg, drifted %.3f m", d.pz - s.z0, yaw, math.abs(d.px - s.x0))) end },
  }
end

local cur, curD, curS, endT = 0, nil, nil, 0
local function nextTest()
  if curD then tests[cur].finish(curD, curS); V.remove(curD) end
  cur = cur + 1
  local T = tests[cur]
  if not T then curD = nil; return end
  curD, curS = V.new(cur * 10, 0, Y0), {}
  if T.y or T.heel then
    local q = T.heel and btQuaternion(btVector3(1, 0, 0), -math.pi / 2 + math.rad(T.heel))
                     or curD.body:getOrientation()
    curD.body:setCenterOfMassTransform(btTransform(q, btVector3(cur * 10, Y0 + (T.y or 0), 0)))
  end
  V.step(curD, DT)                     -- read the state
  V.guide(curD, "takeoff", t, DT)
  V.join(curD, t)
  T.start(curD, curS)
  endT = t + T.secs
end

local function physicsStep()
  if curD then
    if t >= endT then nextTest() end
  end
  if curD then
    V.guide(curD, "ap", t, DT)
    V.step(curD, DT)
    if tests[cur].during then tests[cur].during(curD, curS) end
  end
  t = t + DT
end

nextTest()
v:preSim(function(N)
  for _ = 1, STEPS - 1 do physicsStep(); v:stepSimulation(DT, 1, DT) end
  physicsStep()
end)
v:preStop(function(N)
  if curD then print("FAIL " .. which .. ": the run ended during test " .. tests[cur].name .. " (give more frames)"); fails = fails + 1 end
  if fails == 0 then print(string.format("PASS vehicle_physics %s: %d tests", which, nTests))
  else print(string.format("FAIL vehicle_physics %s: %d of %d failed", which, fails, nTests)) end
end)
