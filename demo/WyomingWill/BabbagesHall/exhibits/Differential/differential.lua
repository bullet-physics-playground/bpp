--
-- The Differential -- Babbage's Hall
--
-- Gears that add. Two side gears, A and B, face each other on one axis; two
-- spider gears between them turn on a pin across the carrier, the ring
-- round the middle. Turn A and hold B, and the spiders roll round B,
-- taking the carrier with them -- half as far as A turned. Turn both the
-- same way and the whole cluster turns as one; turn them opposite ways and
-- the carrier stays still. Always:
--
--     carrier = (A + B) / 2
--
-- The inputs' drums count ten units a turn; the carrier's ring has twenty
-- numbers round it, so it reads A + B. Turn them the opposite way and it
-- subtracts. Every fire-control computer of the Second World War had dozens
-- of these, and so does the back axle of a car: it lets the wheels turn at
-- different speeds round a corner, the carrier being driven by the engine.
--
-- KEYS
--   T  the tour: 3 + 4, then add 5 (12), then take 2 away from A (10),
--      then back to 0 + 0 (it starts with it)
--   1 / Q   input A: one unit forward / back
--   2 / W   input B: one unit forward / back
--   0       turn both back to 0
--
-- EVERY PART CAN BE PRINTED: see parts/ and README.md. The gears turn each
-- other by their teeth alone, in the simulation as on the bench.
--
-- PHYSICS: the four bevel gears are the printed ones (16 teeth, 60 mm,
-- PLA at 0.8 g/cm^3), each simulated as convex pieces -- its body and its
-- sixteen teeth, cut from the same OpenSCAD shapes (parts/make-hulls.py);
-- Bullet's contacts between two meshes jammed and slipped (see
-- FINDINGS.md). The inputs are turned by a hand (a motor) to where the
-- keys put them; the carrier and the spiders move only as the teeth push
-- them. Friction 0.3 on the teeth, 2400 steps a second.
--
-- Units: centimetres, kilograms, seconds.
-- Headless: DF_TOUR=0 (no tour), DF_A, DF_B (turn the inputs to these
-- units), DF_FRICTION, DF_RATE (the hand's speed, turns a second), DF_LOG=1
-- (print A, B and the carrier every second; 2: and the gears' spins).
--

local common = require "common"
local function envnum(n, d) return tonumber(os.getenv(n) or "") or d end

-- ---------------------------------------------------------------------
-- this exhibit's folder; the parts file, by its full path (for OpenSCAD)
-- ---------------------------------------------------------------------
local DIR
for _, d in ipairs({ "", "demo/WyomingWill/BabbagesHall/exhibits/Differential/" }) do
  local f = io.open(d .. "parts/differential.scad", "r")
  if f then f:close(); DIR = d; break end
end
assert(DIR, "The Differential: can't find its folder")
local GH = dofile(DIR .. "parts/gear-hulls.lua")
local SCAD
do
  local path = DIR .. "parts/differential.scad"
  if hallPath then path = hallPath(path) end
  if path:sub(1, 1) ~= "/" and not path:match("^%a:[/\\]") then
    local cwd
    local p = io.popen and io.popen("cd")
    if p then cwd = p:read("*l"); p:close() end
    if not cwd or cwd == "" or not (cwd:sub(1, 1) == "/" or cwd:match("^%a:")) then
      p = io.popen and io.popen("pwd")
      if p then cwd = p:read("*l"); p:close() end
    end
    path = (cwd or os.getenv("PWD") or ".") .. "/" .. path
  end
  SCAD = path
end
-- (only to see, unless 'solid': a part's collisions are fixed when it is
-- added to the world, so this is decided here)
-- (bpp keeps each OpenSCAD part by the text asked for, not by what the
-- parts file says: a checksum of the files in the text makes a changed file
-- count as new)
local function checksum(paths)
  local sum = 0
  for _, path in ipairs(paths) do
    local f = io.open(path, "rb")
    if f then
      local data = f:read("*a"); f:close()
      for i = 1, #data, 7 do sum = (sum * 31 + data:byte(i)) % 2147483647 end
      sum = (sum + #data) % 2147483647
    end
  end
  return sum
end
local SCAD_SUM = checksum({ SCAD, (SCAD:gsub("differential%.scad$", "gearsv50.scad")) })
local function part(call, solid)
  local m = OpenSCAD("// " .. SCAD_SUM .. "\ninclude <" .. SCAD .. ">\nscale(0.1) " .. call .. ";\n", 0, false)
  if not solid then m.collides = false end
  return m
end

-- the machine's sizes (cm), as in differential.scad
local APEX = 3.0                      -- the gears' backs, from the centre
local N = 16
local HUB_L = 4.0
local DRUM_X = APEX + 2.5
local CRANK_X = APEX + 4.5 + 1.0
local RING_R = math.sqrt(2) * (APEX + 0.2) + 0.4
local AXIS_H = RING_R + 0.6 + 2.2     -- the axis above the frame's base
local Y0 = AXIS_H + 0.8               -- ... and above the table

-- ---------------------------------------------------------------------
-- sliders, timing, the pause at every start
-- ---------------------------------------------------------------------
v:addParam("friction", envnum("DF_FRICTION", 0.3), 0.05, 0.6, 0.05, "tooth on tooth")
v:addParam("speed", 1, 0.05, 2, 0.05, "simulated seconds per real second")
v:addParam("turn rate", envnum("DF_RATE", 0.4), 0.1, 1, 0.05, "how fast the hand turns an input, turns a second")
local STEP, NSTEPS, FRAME_DT = 1 / 2400, 40, 1 / 60
local function applyTiming()
  local speed = v:getParam("speed")
  NSTEPS = math.max(1, math.floor(2400 * speed / 60 + 0.5))
  FRAME_DT = speed / 60
  STEP = FRAME_DT / NSTEPS
  v.animationPeriod = 16
  common.setTiming(STEP, 0, STEP)
end
local HOLD_FRAMES = math.floor(envnum("HOLD_S", 0.5) * 60 + 0.5)
local holdArm, holdLeft, holdNow = false, 0, false
local function holdStart() holdArm, holdLeft = true, 0 end
local function holdPre()
  if holdLeft > 0 then holdLeft = holdLeft - 1; holdNow = true; v.timeStep = 0; return true end
  if holdNow then holdNow = false; applyTiming() end
  if holdArm then holdArm, holdLeft = false, HOLD_FRAMES end
  return false
end
applyTiming()
v.gravity = btVector3(0, -981, 0)
pcall(function() v:setSolverIterations(20) end)

-- ---------------------------------------------------------------------
-- the table and the frame
-- ---------------------------------------------------------------------
local ident = btQuaternion(0, 0, 0, 1)
local function qa(ax, ay, az, deg) return btQuaternion(btVector3(ax, ay, az), math.rad(deg)) end
local O = btVector3(0, Y0, 0)                 -- the gears' common centre

local top = Cube(40, 3, 30, 0)
top.pos = btVector3(0, -1.5, 0)
top.col = "#5b3a1e"
v:add(top)
for _, sx in ipairs({ -1, 1 }) do
  for _, sz in ipairs({ -1, 1 }) do
    local leg = Cylinder(1.6, 72, 0)
    leg.trans = btTransform(qa(1, 0, 0, 90), btVector3(sx * 17, -3 - 36, sz * 12))
    leg.col = "#2a2a2a"
    leg.collides = false
    v:add(leg)
  end
end
local floor = Plane(0, 1, 0, -75, 300)
floor.col = "#3b3f45"
v:add(floor)

local frame = part("frame(false)")
frame.col = "#2f3b3a"
v:add(frame)
frame.trans = btTransform(ident, O)
local pointers = part("pointers()")
pointers.col = "#d4af37"
v:add(pointers)
pointers.trans = btTransform(ident, O)

-- ---------------------------------------------------------------------
-- the gears: the printed meshes to see; convex pieces to the physics
-- ---------------------------------------------------------------------
local MARGIN = 0.005
local function hull(pts)
  local h = btConvexHullShape()
  for i = 1, #pts, 3 do h:addPoint(btVector3(pts[i], pts[i + 1], pts[i + 2]), false) end
  h:recalcLocalAabb()
  h:setMargin(MARGIN)
  return h
end
local TOOTH, BODY = hull(GH.tooth), hull(GH.body)
local function gearShape()
  local c = btCompoundShape(true)
  c:addChildShape(btTransform(ident, btVector3(0, 0, 0)), BODY)
  for i = 0, N - 1 do c:addChildShape(btTransform(qa(0, 0, 1, i * 360 / N), btVector3(0, 0, 0)), TOOTH) end
  return c
end
local function body(obj, props, shape, tr, noContact)
  local I = props.inertia
  local b = btRigidBody(props.mass, btDefaultMotionState(tr), shape, btVector3(I[1], I[2], I[3]))
  obj.body = b
  v:add(obj)
  obj.trans = tr
  b:setCenterOfMassTransform(tr)
  b:setActivationState(4)
  b:setDamping(0, 0.02)
  if noContact then b:setCollisionFlags(4) end             -- (the carrier: it touches nothing)
  return b
end

-- each gear's own frame: its axis z, its back at z = 0, the apex at z = APEX
local G = {}
local function gear(name, call, props, base, pos, col)
  local m = part(call, true)
  m.col = col
  local tr = btTransform(base, pos)
  G[name] = { obj = m, base = base, pos = pos, body = body(m, props, gearShape(), tr) }
  return G[name]
end
local qA, qB = qa(0, 1, 0, 90), qa(0, 1, 0, -90)             -- z -> +x, z -> -x
local qS1, qS2 = qa(1, 0, 0, -90), qa(1, 0, 0, 90)           -- z -> +y, z -> -y
local HALF = 360 / N / 2                                      -- (the spiders' teeth meet the sides' gaps)
gear("A", "side()", GH.side, qA, O + btVector3(-APEX, 0, 0), "#c9a06a")
gear("B", "side()", GH.side, qB, O + btVector3(APEX, 0, 0), "#c9a06a")
gear("S1", "spider()", GH.spider, qS1 * qa(0, 0, 1, HALF), O + btVector3(0, -APEX, 0), "#b8862b")
gear("S2", "spider()", GH.spider, qS2 * qa(0, 0, 1, HALF), O + btVector3(0, APEX, 0), "#b8862b")

-- the carrier: the printed ring and cage, touching nothing (it rides on the
-- hubs, which the simulation leaves out); the spiders turn on it
local carrierObj = part("carrier(false)")
carrierObj.col = "#7a4a24"
local carrier = body(carrierObj, GH.carrier, btSphereShape(0.5), btTransform(ident, O), true)
local ringNumbers = part("carrierNumbers()")
ringNumbers.col = "#f2e6c4"
v:add(ringNumbers)

-- the hinges: everything turns about the axis (world x) through O, the
-- spiders about their pin. A hinge's frames have their z along its axis.
local anchor = Cube(0.01, 0.01, 0.01, 0)     -- (only for the hinges to hold to: too small to see)
anchor.collides = false
v:add(anchor)
anchor.trans = btTransform(ident, O)
local zToX = qa(0, 1, 0, 90)
local function axisHinge(b, frameInB)
  local h = btHingeConstraint(anchor.body, b, btTransform(zToX, btVector3(0, 0, 0)), frameInB)
  v:addConstraint(h)
  return h
end
local hA = axisHinge(G.A.body, btTransform(ident, btVector3(0, 0, APEX)))
local hB = axisHinge(G.B.body, btTransform(qa(0, 1, 0, 180), btVector3(0, 0, APEX)))
local hC = axisHinge(carrier, btTransform(zToX, btVector3(0, 0, 0)))
for _, s in ipairs({ { G.S1, qS1, -1 }, { G.S2, qS2, 1 } }) do
  local h = btHingeConstraint(carrier, s[1].body, btTransform(s[2], btVector3(0, s[3] * APEX, 0)),
                              btTransform(ident, btVector3(0, 0, 0)))
  v:addConstraint(h)
end
pcall(function() v.showConstraints = false end)

-- the parts that go round with the inputs: rods, drums, cranks (to see)
local riders = {}
local function rider(call, gname, offset, col)
  local m = part(call)
  m.col = col
  v:add(m)
  riders[#riders + 1] = { obj = m, g = gname, off = offset }
end
for _, k in ipairs(os.getenv("DF_NORIDERS") and {} or { "A", "B" }) do
  local s = (k == "A") and -1 or 1
  -- (in the gear's own frame: its axis z points in toward the centre)
  rider("rotate([0, 0, 0]) cylinder(d = 5, h = " .. (CRANK_X - APEX + 1.6) * 10 .. ", $fn = 16)", k,
        btTransform(qa(1, 0, 0, 180), btVector3(0, 0, 0.5)), "#c0c0c0")
  rider("drum(false)", k, btTransform(qa(0, 1, 0, s * 90), btVector3(0, 0, -(DRUM_X - APEX))), "#ede3c8")
  rider("drumNumbers()", k, btTransform(qa(0, 1, 0, s * 90), btVector3(0, 0, -(DRUM_X - APEX))), "#2a2018")
  -- (the crank's handle along its own +x: turned so that it points outward on both sides)
  rider("crank()", k, btTransform(qa(0, 1, 0, 90), btVector3(0, 0, -(CRANK_X - APEX))), "#333333")
end
-- the cross pin the spiders turn on, going round with the carrier
local crossPin = part("crossPin()")
crossPin.col = "#9a9da3"
v:add(crossPin)
local function moveRiders()
  ringNumbers.trans = carrier:getCenterOfMassTransform()
  crossPin.trans = carrier:getCenterOfMassTransform()
  for _, r in ipairs(riders) do
    local tr = btTransform()
    tr:mult(G[r.g].body:getCenterOfMassTransform(), r.off)        -- (the gear's, then the offset)
    r.obj.trans = tr
  end
end

-- ---------------------------------------------------------------------
-- the hands on the inputs: each input is turned to where the keys put it
-- (a motor, steered toward that angle), and held there
-- ---------------------------------------------------------------------
local acc, last = {}, {}
local function angle(h)          -- the turn about +x (right-handed), unwrapped
  local x = -h:getHingeAngle()  -- (Bullet's hinge angle runs the other way here)
  if last[h] then
    local d = x - last[h]
    if d > math.pi then d = d - 2 * math.pi elseif d < -math.pi then d = d + 2 * math.pi end
    acc[h] = acc[h] + d
  else acc[h] = x end
  last[h] = x
  return acc[h]
end
local UNIT = 2 * math.pi / 10                      -- an input unit: a tenth of a turn
local target = { A = envnum("DF_A", 0), B = envnum("DF_B", 0) }        -- in units
local zero = {}
-- One hand: it turns one input at a time (A first), holding the other where
-- it is -- as a person turns one crank at a time. (Both turned at once and
-- then one stopped, the load jumps across the teeth's backlash all at once,
-- and the simulated teeth can jam: see FINDINGS.md.)
local busy                                   -- the input the hand is on
local function steer()
  local rate = v:getParam("turn rate") * 2 * math.pi
  local errs = {}
  for k, h in pairs({ A = hA, B = hB }) do errs[k] = target[k] * UNIT - (angle(h) - zero[k]) end
  if not busy or math.abs(errs[busy]) < 0.005 * UNIT then
    busy = nil
    for _, k in ipairs({ "A", "B" }) do
      if not busy and math.abs(errs[k]) > 0.01 * UNIT then busy = k end
    end
  end
  for k, h in pairs({ A = hA, B = hB }) do
    -- (the other held where it was set: steered back gently if the load
    -- creeps it)
    local cap = (k == busy) and rate or 0.2
    local w = math.max(-cap, math.min(cap, 6 * errs[k]))
    h:enableAngularMotor(true, -w, envnum("DF_IMP", 2))     -- (the hinge's sense: see angle())
  end
end
local function reading()
  local a = (angle(hA) - zero.A) / UNIT
  local b = (angle(hB) - zero.B) / UNIT
  local c = 2 * (angle(hC) - zero.C) / UNIT          -- (the carrier turns half as far)
  return a, b, c
end
zero.A, zero.B, zero.C = angle(hA), angle(hB), angle(hC)

local function applyFriction()
  local f = v:getParam("friction")
  for _, g in pairs(G) do g.body:setFriction(f); g.body:setRestitution(0) end
end
applyFriction()

-- ---------------------------------------------------------------------
-- the tour
-- ---------------------------------------------------------------------
local TOUR = {
  { 3, 4, "3 + 4: turn A to 3 and B to 4 -- the ring reads 7" },
  { 3, 9, "add 5 to B: 3 + 9 = 12" },
  { 1, 9, "take 2 from A: 1 + 9 = 10" },
  { 0, 0, "and back to 0 + 0" },
}
local tour = (os.getenv("DF_TOUR") or "1") ~= "0" and 1 or nil
local tWait, t = 0, 0
local function settled()
  local a, b = reading()
  return math.abs(a - target.A) < 0.02 and math.abs(b - target.B) < 0.02
end
local function say()
  local a, b, c = reading()
  print(string.format("  A %5.2f   B %5.2f   ->  ring %5.2f   (A + B = %5.2f)", a, b, c, a + b))
end
local function tourStep()
  local s = TOUR[tour]
  target.A, target.B = s[1], s[2]
  print(s[3])
end
if tour then print("\nTHE DIFFERENTIAL -- the tour"); end

-- ---------------------------------------------------------------------
-- stepping
-- ---------------------------------------------------------------------
local LOG = os.getenv("DF_LOG")
local fails = 0
local started = false
-- (the moving parts, for telling when they've stopped; and whether the
-- hand has anything left to do: an input not yet where it's set)
local restBodies = { carrier }
for _, g in pairs(G) do restBodies[#restBodies + 1] = g.body end
local function handBusy()
  if busy then return true end
  local a, b = reading()
  return math.abs(a - target.A) > 0.01 or math.abs(b - target.B) > 0.01
end
-- ---------------------------------------------------------------------
-- at rest: once the hand has nothing to do and nothing has moved for
-- REST_S, the simulation stops stepping. Nothing would change but the
-- processor's work (a machine at rest, stepped 2400 times a second, costs
-- as much as one running). The next thing for the hand to do starts it
-- again. (DF_REST=0: never rest; DF_REST_LOG=1: print the fastest
-- part's speeds each second while the hand is idle, to set REST_V, REST_W)
-- ---------------------------------------------------------------------
local REST_S = 0.5
local REST_V, REST_W = 0.1, 0.05   -- cm/s and rad/s: "not moving" (just above what is left when it has settled)
local REST_ON = os.getenv("DF_REST") ~= "0"
local REST_LOG = os.getenv("DF_REST_LOG")
local restFor, resting, restLogT = 0, false, 0
local function fastest()
  local mv, mw = 0, 0
  for _, b in ipairs(restBodies) do
    mv = math.max(mv, b:getLinearVelocity():length())
    mw = math.max(mw, b:getAngularVelocity():length())
  end
  return mv, mw
end
-- (in preSim: true while at rest, and the step is skipped)
local function restPre()
  if not resting then return false end
  if handBusy() then
    resting, restFor = false, 0
    applyTiming()
    if REST_LOG then print('  (stepping again)') end
    return false
  end
  v.timeStep = 0
  return true
end
-- (in postSim, after a stepped frame)
local function restPost()
  if resting then return end
  if handBusy() then restFor = 0; return end
  local mv, mw = fastest()
  if REST_LOG then
    restLogT = restLogT + FRAME_DT
    if restLogT >= 1 then restLogT = 0; print(string.format("  at rest? fastest part %.4f cm/s, %.4f rad/s", mv, mw)) end
  end
  if mv < REST_V and mw < REST_W then restFor = restFor + FRAME_DT else restFor = 0 end
  if REST_ON and restFor >= REST_S then
    resting = true
    v.timeStep = 0
    if REST_LOG then print('  (at rest: not stepping)') end
  end
end

v:preSim(function(N)
  if holdPre() then return end
  if restPre() then return end
  steer()
  for k = 1, NSTEPS - 1 do v:stepSimulation(STEP, 0, STEP); steer() end
end)
v:postSim(function(N)
  moveRiders()
  if holdNow then return end
  restPost()
  t = t + FRAME_DT
  if not started then
    started = true
    if tour then tourStep() end
  end
  if LOG and math.floor(t * 60 + 0.5) % 60 == 0 then
    say()
    if LOG == "2" then
      local wc = carrier:getAngularVelocity()
      local parts = {}
      for _, n in ipairs({ "A", "B", "S1", "S2" }) do
        local w = G[n].body:getAngularVelocity()
        local ax = G[n].body:getCenterOfMassTransform():getBasis():getColumn(2)
        parts[#parts + 1] = string.format("%s %+.2f", n, (w.x - wc.x) * ax.x + (w.y - wc.y) * ax.y + (w.z - wc.z) * ax.z)
      end
      print("    spins rel. carrier: " .. table.concat(parts, "  "))
    end
  end
  if tour then
    if settled() then
      tWait = tWait + FRAME_DT
      if tWait > 1.0 then
        say()
        local a, b, c = reading()
        local ok = math.abs(c - (a + b)) < 0.05
        if not ok then fails = fails + 1 end
        print(ok and "    right" or "    WRONG")
        tWait = 0
        tour = tour + 1
        if tour > #TOUR then
          tour = nil
          print("RESULT differential tour: " .. (fails == 0 and "PASS" or "FAIL"))
        else
          tourStep()
        end
      end
    else
      tWait = 0
    end
  end
end)

-- ---------------------------------------------------------------------
-- keys, sliders, help
-- ---------------------------------------------------------------------
local function nudge(k, d) tour = nil; target[k] = target[k] + d end
v:addShortcut("1", function() nudge("A", 1) end)
v:addShortcut("Q", function() nudge("A", -1) end)
v:addShortcut("2", function() nudge("B", 1) end)
v:addShortcut("W", function() nudge("B", -1) end)
v:addShortcut("0", function() tour = nil; target.A, target.B = 0, 0 end)
v:addShortcut("T", function() tour = 1; fails = 0; print("\nthe tour"); tourStep() end)
v:onParamChanged(function(N, name, value)
  if name == "speed" then applyTiming()
  elseif name == "friction" then applyFriction() end
end)
pcall(function()
  v:setHelpText(table.concat({
    "THE DIFFERENTIAL  (Babbage's Hall)",
    "",
    "Gears that add. The carrier -- the ring round the middle -- always turns",
    "half as far as the two inputs, A and B, put together:",
    "    carrier = (A + B) / 2",
    "Its ring has twenty numbers to the inputs' ten, so it reads A + B.",
    "",
    "WHAT TO WATCH",
    "  Turn A alone: the spiders (the gears on the cross pin) roll round B,",
    "  and carry the ring half as far.",
    "  Turn both the same way: the whole cluster turns as one.",
    "  Turn them opposite ways: the spiders spin and the ring stays still.",
    "",
    "KEYS",
    "  1 / Q  A: one unit forward / back     2 / W  B: one unit forward / back",
    "  0      both back to 0                 T      the tour",
    "",
    "The gears turn each other by their teeth alone, as printed.",
  }, "\n"))
end)
if v.onHover then
  local KEY = {}
  KEY[objectKey(G.A.obj)] = "input A: a side gear"
  KEY[objectKey(G.B.obj)] = "input B: a side gear"
  KEY[objectKey(G.S1.obj)] = "a spider gear, on the carrier's cross pin"
  KEY[objectKey(G.S2.obj)] = "a spider gear, on the carrier's cross pin"
  KEY[objectKey(carrierObj)] = "the carrier: it turns (A + B) / 2; its ring reads A + B"
  v:onHover(function(N, obj, x, y, z)
    local s = KEY[objectKey(obj)]
    if not s then return nil end
    local a, b, c = reading()
    return s .. string.format("\nA %.2f + B %.2f = %.2f;  the ring reads %.2f", a, b, a + b, c)
  end)
end

common.setCamera(btVector3(0, Y0 + 14, 30), btVector3(0, Y0 - 1, 0))
moveRiders()
holdStart()
