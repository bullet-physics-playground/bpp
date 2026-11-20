--
-- The Combination Lock -- Babbage's Hall
--
-- A lock that tests a number. The dial turns the drive cam; behind it three
-- wheels turn loose on a post, each with a gate (a notch) in its rim. A pin
-- in the cam's back, and one through each wheel, give the lost motion:
-- turning the dial, the cam comes round to wheel 3 and carries it, wheel 3
-- carries wheel 2, wheel 2 wheel 1. So the dialling rules set one wheel at
-- a time: left four times to the first number (all three picked up; wheel
-- 1, at the back, left there), right three times to the second (wheel 1
-- left behind; wheel 2 set), left twice to the third (wheel 3 set). A
-- lever pivoted on the bolt lays a steel rod, the fence, across all three
-- rims and the cam. Only when every gate is under it does it fall, into the
-- cam's notch; turning right, the notch's wall then pulls the fence, the
-- lever and the bolt. This is Sargent & Greenleaf's arrangement, as in a
-- safe's door, made big and open.
--
-- KEYS
--   0 - 9      a combination: six figures (31 72 46), then Return dials it
--              and tries to open           Backspace  a figure off
--   L, R       the dial one number left, right
--   Space      right until the dial stops (open, if the fence can fall)
--   C          close: left two turns (the bolt thrown, the wheels scrambled)
--   M          the camera close to the dial; G close to the gates; again: back
--   T          the tour
--   H          the manual (MANUAL.pdf) in the PDF viewer
--
-- PHYSICS: the dial's body (dial, spindle, cam and its pin), the three
-- wheels (each with its pin), the bolt and the lever (its rod) are bodies;
-- the wheels and the dial on hinges, the bolt on a slider. Each wheel is
-- the outline of the printed one cut into convex pieces (lock.lua), and
-- every push is a contact: pin on pin, the fence on the rims and in the
-- gates, the fence in the cam's notch. The wheels and the bolt are held
-- where they are left by friction (a hinge's or a slider's motor at no
-- speed: the wheels' wave washer, the bolt's guides); the lever is pressed
-- down by a torsion spring on its pivot pin (a steady torque). The operator's hand is the
-- script's: it turns the dial as a person does, slowing to stop on a
-- number. The slate (the dial's reading, where each gate stands from the
-- fence) is the script's too. 1200 steps a second.
--
-- EVERY PART CAN BE PRINTED but the pins, the fence and the spindle (steel
-- rod) and the wave washer: README.md.
--
-- Units: centimetres, kilograms, seconds.
-- Headless: LK_COMBO (the lock's combination, 31-72-46), LK_TOUR=0,
-- LK_LOG=1 (each move and the gates after it), LK_HAND (the hand's speed,
-- numbers a second), LK_WHEEL_DRAG (each wheel's friction, kg cm^2/s^2),
-- LK_BOLT_DRAG (the bolt's, kg cm/s^2), LK_PRESS (the lever's spring at
-- the fence, kg cm/s^2), LK_FRICTION (the parts' surfaces), LK_HZ,
-- LK_TRY=31-72-51 (one combination tried instead of the tour, as the model
-- expects; for testing, fractions: 31-72-47.5), LK_RANDOM=n (n random
-- combinations near the lock's), LK_SEED, LK_TRACE=1 (each frame near the
-- notch: the dial, the fence, the bolt, the gates).
--

local common = require "common"
local function envnum(n, d) return tonumber(os.getenv(n) or "") or d end

-- ---------------------------------------------------------------------
-- this exhibit's folder; the parts files by their full paths (for OpenSCAD)
-- ---------------------------------------------------------------------
local DIR
for _, d in ipairs({ "", "demo/WyomingWill/BabbagesHall/exhibits/CombinationLock/" }) do
  local f = io.open(d .. "parts/combination-lock.scad", "r")
  if f then f:close(); DIR = d; break end
end
assert(DIR, "The Combination Lock: can't find its folder")
local L = dofile(DIR .. "lock.lua")
local SAYS = dofile(DIR .. "slate/says.lua")
local G = L.G
local function fullPath(path)
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
  return path
end
local SCAD = fullPath(DIR .. "parts/combination-lock.scad")
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
local SCAD_SUM = checksum({ SCAD, fullPath(DIR .. "parts/lock-geometry.scad") })
local function part(call, solid)
  local m = OpenSCAD("// " .. SCAD_SUM .. "\ninclude <" .. SCAD .. ">\nscale(0.1) " .. call .. ";\n", 0, false)
  if not solid then m.collides = false end
  return m
end
local function pic(name)
  local p = DIR .. name .. ".png"
  if hallPath then p = hallPath(p) end
  return p
end

-- the lock's combination, and its wheels' gates
local function parseCombo(s)                  -- ("31-72-46"; for testing, "31-72-47.2")
  local a, b, c = (s or ""):match("^%s*([%d%.]+)[^%d%.]+([%d%.]+)[^%d%.]+([%d%.]+)%s*$")
  a, b, c = tonumber(a), tonumber(b), tonumber(c)
  if a and b and c and a < L.N and b < L.N and c < L.N then return { a, b, c } end
end
local COMBO = parseCombo(os.getenv("LK_COMBO")) or { 31, 72, 46 }
local GATES = L.gates(COMBO[1], COMBO[2], COMBO[3])       -- (numbers, each wheel's own frame)

-- ---------------------------------------------------------------------
-- sliders, timing, the pause at every start
-- ---------------------------------------------------------------------
v:addParam("hand", envnum("LK_HAND", 70), 10, 150, 5, "how fast the hand turns the dial, numbers a second (100: a turn a second)")
v:addParam("wheel drag", envnum("LK_WHEEL_DRAG", 40), 5, 200, 5, "each wheel's friction on the post: the torque it takes to turn it, kg cm^2/s^2 (100 is 1 N cm)")
v:addParam("speed", 1, 0.05, 2, 0.05, "simulated seconds per real second")
local BOLT_DRAG = envnum("LK_BOLT_DRAG", G.BOLT_DRAG * 100)       -- kg cm/s^2
local PRESS = envnum("LK_PRESS", G.LEVER_PRESS * 100)           -- kg cm/s^2, at the fence
local FRICTION = envnum("LK_FRICTION", 0.45)                    -- (PLA; the steel parts 0.45 too: pairs multiply, 0.2)
local HZ = envnum("LK_HZ", 1200)
local STEP, NSTEPS, FRAME_DT = 1 / HZ, 20, 1 / 60
local function applyTiming()
  local speed = v:getParam("speed")
  NSTEPS = math.max(1, math.floor(HZ * speed / 60 + 0.5))
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
pcall(function() v:setSolverIterations(30) end)

-- ---------------------------------------------------------------------
-- where things are: the lock's frame (mm, x right, y up, z toward you, its
-- origin on the spindle's axis at the back plate) in the exhibit's (cm)
-- ---------------------------------------------------------------------
local MM = 0.1
local OX, OZ = 4.5, -1.0                      -- (the lock and its slate centred on the table)
local AXIS = G.AXIS_H * MM
local ident = btQuaternion(0, 0, 0, 1)
local function P(x, y, z) return btVector3(OX + x * MM, AXIS + y * MM, OZ + z * MM) end
local LOCK_TR = btTransform(ident, P(0, 0, 0))

local TABLE
do
  local path, f = DIR .. "../../exhibit-table.lua"
  if setfenv then f = assert(loadfile(path)); setfenv(f, getfenv(1))
  else f = assert(loadfile(path, "t", _ENV)) end
  TABLE = f()
end
TABLE.build(34, 16, { z = 0.5 })               -- (the lock, 21 x 9 cm, and its slate, 34 cm wide, behind it)

local function still(call, col, tr)
  local m = part(call)
  m.col = col
  v:add(m)
  m.trans = tr or LOCK_TR
  return m
end
local FRAME_COL, BRASS, STEEL = "#2f3a34", "#c9a24a", "#b0b4b8"
local frameObj = still("union() { base(); backPlate(); guides(); }", FRAME_COL)
local standObj = still("standard()", FRAME_COL)
local keeperObj = still("keeper()", "#4a3a2a")
local washerObj = still("washers()", "#9a9da3")
local slateObj = still("slate()", "#22282a")
local slateFrameObj = still("union() { slateFrame(); slateStand(); }", "#6b4423")

-- ---------------------------------------------------------------------
-- the bodies
-- ---------------------------------------------------------------------
local MARGIN = 0.002                          -- cm: Bullet's collision margin (0.02 mm)
local function anchorAt(p)
  local a = Cube(0.01, 0.01, 0.01, 0)         -- (only for a constraint to hold to: too small to see)
  a.collides = false
  v:add(a)
  a.trans = btTransform(ident, p)
  return a
end
-- a compound of the pieces (lock.lua's 2D outlines, mm) as prisms of thickness t (mm)
local function prisms(c, pieces, t)
  for _, p in ipairs(pieces) do
    local h = btConvexHullShape()
    for _, q in ipairs(p) do
      for _, z in ipairs({ -t / 2, t / 2 }) do h:addPoint(btVector3(q[1] * MM, q[2] * MM, z * MM), false) end
    end
    h:recalcLocalAabb()
    h:setMargin(MARGIN)
    c:addChildShape(btTransform(ident, btVector3(0, 0, 0)), h)
  end
end
-- a pin, where it meets the next part's pin: a sphere of its radius in the
-- gap's middle plane (z, mm, from the body's origin). Two pins touch only
-- there, so their contact is as the cylinders' in that plane; Bullet's
-- cylinder-on-cylinder contacts came out with false normals whose friction
-- dragged a resting wheel along (FINDINGS.md).
local function pinSphere(c, z)
  local s = btSphereShape(G.PIN_D / 2 * MM)
  local a = math.rad(G.PIN_AT)
  c:addChildShape(btTransform(ident, btVector3(G.PIN_R * math.cos(a) * MM, G.PIN_R * math.sin(a) * MM, z * MM)), s)
end
-- the gaps' middle planes, where the pins meet: wheel 1 / wheel 2, wheel 2 / wheel 3, wheel 3 / the cam (mm)
local GAP_Z = { (G.Z_W[1] + G.T_W + G.Z_W[2]) / 2, (G.Z_W[2] + G.T_W + G.Z_W[3]) / 2, (G.Z_W[3] + G.T_W + G.Z_C) / 2 }
local hingeFriction = {}                      -- (hinge -> its friction torque, kg cm^2/s^2, when not driven)
local function onAxis(obj, shape, mass, Iz, z, turnNum)
  local tr = btTransform(btQuaternion(btVector3(0, 0, 1), math.rad(turnNum * L.DEG)), P(0, 0, z))
  local b = btRigidBody(mass, btDefaultMotionState(tr), shape, btVector3(Iz * 0.6, Iz * 0.6, Iz))
  obj.body = b
  obj.collides = true                          -- (before it is added: a body's collisions are fixed then)
  v:add(obj)
  obj.trans = tr
  b:setCenterOfMassTransform(tr)
  b:setActivationState(4)
  b:setFriction(FRICTION)
  b:setRestitution(0)
  local h = btHingeConstraint(anchorAt(P(0, 0, z)).body, b, btTransform(ident, btVector3(0, 0, 0)), btTransform(ident, btVector3(0, 0, 0)))
  v:addConstraint(h)
  return b, h
end

-- where the dial and the wheels start (the wheels scrambled; their pins kept
-- apart as the model has them)
local START = L.new(envnum("LK_DIAL0", 0), { 13, 58, 91 })

-- the dial's body: the cam and its pin (what touches), with the spindle, the
-- dial and its knob; its origin at the cam's middle
local CAM_MID = G.Z_C + G.T_C / 2
local dialShape = btCompoundShape(true)
prisms(dialShape, L.camPieces(), G.T_C)
pinSphere(dialShape, GAP_Z[3] - CAM_MID)
-- (PLA cam 7.6 cm^3, dial and knob 34 cm^3, steel spindle 6.5 cm^3: 103 g)
local camObj = part("cam()")
camObj.col = "#9a7434"
local dial = {}
dial.body, dial.hinge = onAxis(camObj, dialShape, 0.103, 0.103 * 3.4 ^ 2 / 2, CAM_MID, START.D)
dial.obj = camObj
local dialRiders = {}
for _, r in ipairs({ { "dialFace()", "#1d1d1f" }, { "dialMarks()", "#e8d48a" }, { "union() { camPin(); spindle(); }", STEEL } }) do
  local m = part(r[1]); m.col = r[2]; v:add(m); dialRiders[#dialRiders + 1] = m
end
local fingersObj = part("fingers()")
fingersObj.col = "#e0b896"
v:add(fingersObj)

-- the wheels: wheel 1 at the back holds the first number
local wheels = {}
for i = 1, 3 do
  local gateDeg = GATES[i] * L.DEG
  local c = btCompoundShape(true)
  prisms(c, L.wheelPieces(gateDeg), G.T_W)
  local zmid = G.Z_W[i] + G.T_W / 2
  if i > 1 then pinSphere(c, GAP_Z[i - 1] - zmid) end             -- (meeting the pin of the wheel behind)
  pinSphere(c, GAP_Z[i] - zmid)                                    -- (and the next's: wheel 3's, the cam's)
  local m = part(string.format("wheel(%.4f, %d)", gateDeg, i))
  m.col = BRASS
  -- (PLA 22.4 cm^3 and its pin: 28.5 g)
  local z = G.Z_W[i] + G.T_W / 2
  local b, h = onAxis(m, c, 0.0285, 0.0285 * (4.0 ^ 2 + 0.62 ^ 2) / 2 * 0.85, z, L.wheel(START, i))
  local pinObj = part("rotate([0, 0, PIN_AT]) translate([PIN_R, 0, 0]) pin()"); pinObj.col = STEEL; v:add(pinObj)
  local markObj = part(string.format("gateMark(%.4f)", gateDeg)); markObj.col = "#c0161a"; v:add(markObj)
  wheels[i] = { obj = m, body = b, hinge = h, riders = { pinObj, markObj }, gate = GATES[i] }
  hingeFriction[h] = function() return v:getParam("wheel drag") end
end

-- the bolt: on a slider along x (0 thrown, BOLT_TRAVEL drawn back); its
-- origin at the lever's pivot. It touches nothing: the guides and the keeper
-- are its slider and its limits.
local boltObj = part("bolt()")
boltObj.col = "#b8bcc0"
local PIVOT = P(G.PIVOT_X, G.ROD_Y, 0)
local boltTr = btTransform(ident, PIVOT)
local boltShape = btCompoundShape(true)
do
  local bx = btBoxShape(btVector3((G.PIVOT_X - G.BOLT_END) / 2 * MM, G.BOLT_W / 2 * MM, (G.BOLT_Z1 - G.BOLT_Z0) / 2 * MM))
  boltShape:addChildShape(btTransform(ident, btVector3((G.BOLT_END - G.PIVOT_X) / 2 * MM, 0, (G.BOLT_Z0 + G.BOLT_Z1) / 2 * MM)), bx)
end
local bolt = {}
do
  local mass = 0.025                          -- (PLA, 20 cm^3)
  local b = btRigidBody(mass, btDefaultMotionState(boltTr), boltShape, btVector3(0.5, 3, 3))
  boltObj.body = b
  boltObj.collides = false
  v:add(boltObj)
  boltObj.trans = boltTr
  b:setCenterOfMassTransform(boltTr)
  b:setActivationState(4)
  local c = btSliderConstraint(anchorAt(PIVOT).body, b, btTransform(ident, btVector3(0, 0, 0)), btTransform(ident, btVector3(0, 0, 0)), true)
  c:setLowerLinLimit(0); c:setUpperLinLimit(G.BOLT_TRAVEL * MM)
  c:setLowerAngLimit(0); c:setUpperAngLimit(0)
  c:setPoweredLinMotor(true); c:setTargetLinMotorVelocity(0); c:setMaxLinMotorForce(BOLT_DRAG)
  v:addConstraint(c)
  bolt.obj, bolt.body, bolt.slider = boltObj, b, c
end
local function boltAt() return bolt.slider:getLinearPos() / MM end     -- mm drawn back

-- the lever: pinned to the bolt, the fence (a 4 mm steel rod) at its right
-- end. Only the fence touches anything. Its origin at its centre of mass.
local LEV = {}
do
  -- (the plate: PLA, 2.9 g, its middle 30 mm from the pivot; the fence: steel, 4.7 g, 60 mm out)
  local mp, mr = 0.0029, 0.0047
  local zp, zr = (G.LEVER_Z0 + G.LEVER_Z1) / 2, (G.ROD_Z0 + G.ROD_Z1) / 2
  local cx = (mp * 30 + mr * -G.PIVOT_X) / (mp + mr)
  local cz = (mp * zp + mr * zr) / (mp + mr)
  LEV.com = { cx, 0, cz }
  LEV.mass = mp + mr
end
local leverObj = part(string.format("translate([%g, 0, %g]) lever()", -LEV.com[1], -LEV.com[3]))
leverObj.col = "#3d4a42"
local rodObj = part(string.format("translate([%g, 0, %g]) { rod(); pivotPin(); torsionSpring(); }", -LEV.com[1], -LEV.com[3]))
rodObj.col = "#d0d4d8"
local lever = {}
do
  local c = btCompoundShape(true)
  local s = btCylinderShapeZ(btVector3(G.ROD_D / 2 * MM, G.ROD_D / 2 * MM, (G.ROD_Z1 - G.ROD_Z0) / 2 * MM))
  s:setMargin(MARGIN)
  c:addChildShape(btTransform(ident, btVector3((-G.PIVOT_X - LEV.com[1]) * MM, 0, ((G.ROD_Z0 + G.ROD_Z1) / 2 - LEV.com[3]) * MM)), s)
  local tr = btTransform(ident, P(G.PIVOT_X + LEV.com[1], G.ROD_Y, LEV.com[3]))
  local b = btRigidBody(LEV.mass, btDefaultMotionState(tr), c, btVector3(0.012, 0.012, 0.02))
  leverObj.body = b
  leverObj.collides = true
  v:add(leverObj)
  leverObj.trans = tr
  b:setCenterOfMassTransform(tr)
  b:setActivationState(4)
  b:setFriction(FRICTION)
  b:setRestitution(0)
  local zpiv = (G.LEVER_Z0 + G.LEVER_Z1) / 2
  local h = btHingeConstraint(bolt.body, b, btTransform(ident, btVector3(0, 0, zpiv * MM)),
    btTransform(ident, btVector3(-LEV.com[1] * MM, 0, (zpiv - LEV.com[3]) * MM)))
  v:addConstraint(h)
  lever.obj, lever.body, lever.hinge = leverObj, b, h
end
v:add(rodObj)
pcall(function() v.showConstraints = false end)
-- how far the fence has fallen from resting on the cam (mm): its centre,
-- from the lever's place and angle (it turns only about z)
local fenceFall
do
  local LR = (-G.PIVOT_X - LEV.com[1]) * MM
  fenceFall = function()
    local c = lever.body:getCenterOfMassTransform():getBasis():getColumn(0)
    local p = lever.body:getCenterOfMassPosition()
    local y = p.y + LR * c.y - AXIS
    return G.ROD_Y - y / MM
  end
end

-- each frame: the riders follow their bodies
local function follow()
  local tr = dial.body:getCenterOfMassTransform()
  for _, m in ipairs(dialRiders) do m.trans = btTransform(tr:getRotation(), dial.body:getCenterOfMassPosition()) end
  for _, w in ipairs(wheels) do
    local wt = btTransform(w.body:getCenterOfMassTransform():getRotation(), w.body:getCenterOfMassPosition())
    for _, m in ipairs(w.riders) do m.trans = wt end
  end
  rodObj.trans = btTransform(lever.body:getCenterOfMassTransform():getRotation(), lever.body:getCenterOfMassPosition())
end

-- turns, unwrapped, in numbers (anticlockwise as you face the dial: left)
local function turnReader(body, start)
  local last, turn = nil, start
  return function()
    local c = body:getCenterOfMassTransform():getBasis():getColumn(0)
    local a = math.deg(math.atan2(c.y, c.x)) / L.DEG
    if last then
      local d = a - last
      if d > L.N / 2 then d = d - L.N elseif d < -L.N / 2 then d = d + L.N end
      turn = turn + d
    else turn = start + L.centred(a - start) end
    last = a
    return turn
  end
end
dial.read = turnReader(dial.body, START.D)
for i, w in ipairs(wheels) do w.read = turnReader(w.body, L.wheel(START, i)) end
local Dnow, Wnow = START.D, { 0, 0, 0 }
local function readAll()
  Dnow = dial.read()
  for i, w in ipairs(wheels) do Wnow[i] = w.read() end
end
readAll()
local function gateOffsets()
  local e = {}
  for i = 1, 3 do e[i] = L.centred(Wnow[i] + GATES[i] - L.TOP) end
  return e
end
local function dialSpeed()                    -- numbers a second, left +
  return dial.body:getAngularVelocity().z * 180 / math.pi / L.DEG
end

-- ---------------------------------------------------------------------
-- the slate: pictures swapped in (make-slate.py made them)
-- ---------------------------------------------------------------------
local SZ = OZ + (-60 + 6) * MM + 0.004        -- (its face: slate() in the parts file)
local SX, SY = OX - 4.5, 14                   -- (its middle across; its board's foot above the table)
local HIDE = btVector3(SX, 10, SZ - 3)
local function tile(w, h, x, y, name)
  local c = Cube(w, h, 0.01, 0)
  c.collides = false
  c.tex = pic("slate/" .. name)
  v:add(c)
  c.trans = btTransform(ident, btVector3(SX + x, SY + y, SZ))
  return c
end
local shown = {}
local function show(t, name) if shown[t] ~= name then shown[t] = name; t.tex = pic("slate/" .. name) end end
local GLYPH = { ["-"] = "dash", ["+"] = "plus", ["m"] = "minus", ["."] = "point", [" "] = "blank", ["_"] = "under" }
local NARROW = { ["."] = true }
local GW, GN, GH = 0.85, 0.45, 1.1
local function glyphRow(n, x0, y)
  local row = { x0 = x0, y = y, wide = {}, narrow = {} }
  for k = 1, n do
    row.wide[k] = tile(GW, GH, 0, 0, "g-blank")
    row.narrow[k] = tile(GN, GH, 0, 0, "g-blank")
    row.wide[k].trans = btTransform(ident, HIDE)
    row.narrow[k].trans = btTransform(ident, HIDE)
  end
  return row
end
local function showGlyphs(row, text)
  text = text or ""
  if row.text == text then return end
  row.text = text
  local x = row.x0
  for k = 1, #row.wide do
    local ch = text:sub(k, k)
    local w, n = row.wide[k], row.narrow[k]
    if ch == "" then
      w.trans = btTransform(ident, HIDE); n.trans = btTransform(ident, HIDE)
    else
      local use, other, width = w, n, GW
      if NARROW[ch] then use, other, width = n, w, GN end
      show(use, "g-" .. (GLYPH[ch] or ch))
      use.trans = btTransform(ident, btVector3(SX + x + width / 2, SY + row.y, SZ))
      other.trans = btTransform(ident, HIDE)
      x = x + width + 0.02
    end
  end
end
-- (the board: 34 cm across, 15 cm tall)
local slate = {}
slate.setL = tile(5.6, 1.1, -13.8, 13.6, "label-set")
slate.set = glyphRow(8, -10.8, 13.6)
slate.tryL = tile(5.6, 1.1, -13.8, 12.0, "label-try")
slate.try = glyphRow(8, -10.8, 12.0)
slate.state = tile(11, 2.6, 10.5, 12.8, "state-locked")
slate.say = tile(32, 3.0, 0, 8.9, "say-ready")
slate.dialL = tile(5.6, 1.1, -13.8, 5.6, "label-dial")
slate.dial = glyphRow(5, -10.8, 5.6)
slate.gatesL = tile(16, 1.1, 6.6, 5.6, "label-gates")
slate.gate = {}
for i = 1, 3 do
  local x = -13.6 + (i - 1) * 10.4
  tile(2.6, 1.1, x + 1.3, 3.4, "label-wheel" .. i)
  slate.gate[i] = glyphRow(5, x + 2.9, 3.4)
end
slate.foot = tile(32, 1.0, 0, 1.6, "foot")
local function comboText(c)
  local function f(x) return (x == math.floor(x)) and string.format("%02d", x) or string.format("%04.1f", x) end
  return f(c[1]) .. "-" .. f(c[2]) .. "-" .. f(c[3])
end
showGlyphs(slate.set, comboText(COMBO))
local function signed(x)
  local s = string.format("%.1f", math.abs(x))
  if s == "0.0" then return " 0.0" end
  return (x < 0 and "m" or "+") .. s
end
local slateEvery = 0
local function slateLive(force)
  slateEvery = slateEvery - 1
  if not force and slateEvery > 0 then return end
  slateEvery = 6
  local r = L.wrap(Dnow)
  local t = string.format("%.1f", r)
  if t == "100.0" then t = "0.0" end
  showGlyphs(slate.dial, t)
  local e = gateOffsets()
  for i = 1, 3 do showGlyphs(slate.gate[i], signed(e[i])) end
  show(slate.state, boltAt() > G.BOLT_TRAVEL - 1 and "state-open" or (boltAt() > 1 and "state-moving" or "state-locked"))
end

-- ---------------------------------------------------------------------
-- the hand: turns the dial to a place (numbers, unwrapped), slowing to stop
-- on it; or right until the dial stops. Between, it lets go: the dial's own
-- friction holds it.
-- ---------------------------------------------------------------------
local LOG = os.getenv("LK_LOG")
local DIAL_DRAG = 30                          -- kg cm^2/s^2: the dial's spindle in its bearing
local HAND_TORQUE = 3000                      -- kg cm^2/s^2 (30 N cm): the most the hand turns it with
local TOL = 0.04                              -- numbers: how near the hand stops on a number
local GAIN = 6                                -- 1/s: it slows over the last (speed / GAIN) numbers
local MOTOR_SIGN = 1                          -- (a hinge motor's speed against our left +: measured at the start)
local held = false
local function setFrictions()
  for h, f in pairs(hingeFriction) do h:enableAngularMotor(true, 0, f() * STEP) end
  if not held then dial.hinge:enableAngularMotor(true, 0, DIAL_DRAG * STEP) end
end
local cmdSpeed = 0                            -- numbers a second, left +
local function drive(speed, torque)
  held = true
  cmdSpeed = speed
  dial.hinge:enableAngularMotor(true, MOTOR_SIGN * speed * L.DEG * math.pi / 180, (torque or HAND_TORQUE) * STEP)
end
local function letGo()
  held = false
  cmdSpeed = 0
  dial.hinge:enableAngularMotor(true, 0, DIAL_DRAG * STEP)
end
local FINGERS_AWAY = btVector3(OX + 30, AXIS + 20, OZ + 20)
local function showFingers()
  if held then fingersObj.trans = btTransform(dial.body:getCenterOfMassTransform():getRotation(), dial.body:getCenterOfMassPosition())
  else fingersObj.trans = btTransform(ident, FINGERS_AWAY) end
end

local queue = {}           -- { say = key } { to = D, say } { open = true } { wait = s } { call = fn }
local job
local function push(q) queue[#queue + 1] = q end
local function startJob()
  local q = table.remove(queue, 1)
  if not q then job = nil; return end
  if q.say then
    show(slate.say, "say-" .. q.say)
    local w = SAYS[q.say]
    if w then print(string.format("  %s   (%s)", w[1], w[2])) end
    job = { wait = q.waitS or 1.2 }
    return
  end
  if q.wait then job = { wait = q.wait }; return end
  if q.call then job = nil; q.call(); if not job then job = { wait = 0 } end; return end
  if q.to then
    local vmax = math.min(v:getParam("hand"), q.vmax or 1e9)
    job = { to = q.to, t = 0, near = 0, vmax = q.vmax, tmax = math.abs(q.to - Dnow) / vmax * 1.6 + 4, done = q.done }
    return
  end
  if q.open then
    -- right until the dial stops, or until it is well past where the bolt
    -- would have been drawn back
    job = { open = true, t = 0, still = 0, from = Dnow, limit = L.toOpen(Dnow) - L.PULL - 4, done = q.done }
    return
  end
end
-- each simulation step: the dial's motor
local function steer()
  local j = job
  if not j then return end
  if j.to then
    local err = j.to - Dnow
    local vmax = math.min(v:getParam("hand"), j.vmax or 1e9)
    drive(math.max(-vmax, math.min(vmax, GAIN * err)))
  elseif j.open then
    drive(-0.6 * v:getParam("hand"))
  end
end
local function stepJob(dt)
  local j = job
  if not j then startJob(); return end
  if j.wait then
    j.wait = j.wait - dt
    if j.wait <= 0 then job = nil; startJob() end
    return
  end
  j.t = j.t + dt
  if j.to then
    if math.abs(j.to - Dnow) < TOL and math.abs(dialSpeed()) < 0.5 then j.near = j.near + dt else j.near = 0 end
    if j.near > 0.08 or j.t > j.tmax then
      if j.t > j.tmax then print(string.format("  (the dial stopped %.2f numbers short)", j.to - Dnow)) end
      letGo()
      local d = j.done
      job = nil
      if d then d() end
      startJob()
    end
  elseif j.open then
    local moved = j.from - Dnow
    if moved > 1 and math.abs(dialSpeed()) < 1.5 then j.still = j.still + dt else j.still = 0 end
    local stopped = j.still > 0.25
    if stopped or Dnow <= j.limit or j.t > 20 then
      letGo()
      local d = j.done
      job = nil
      if d then d(stopped) end
      startJob()
    end
  end
end
local function idle() return job == nil and #queue == 0 end

-- ---------------------------------------------------------------------
-- trying a combination: the four moves, the gates checked after each
-- against the model's, and the verdict from the bolt
-- ---------------------------------------------------------------------
local fails, tried = 0, 0
local model                                   -- (the model, turned as the dial is planned)
local function logGates(what)
  if not LOG then return end
  local e = gateOffsets()
  local m = L.gateOffsets(model, GATES)
  print(string.format("    %s: dial %.2f; the gates from the fence %+.2f %+.2f %+.2f (the model %+.2f %+.2f %+.2f); fence fallen %.2f mm, bolt %.2f mm",
    what, L.wrap(Dnow), e[1], e[2], e[3], m[1], m[2], m[3], fenceFall(), boltAt()))
end
-- what the model says: "open" if the fence falls in by itself (every gate
-- near enough under it, and nothing carried off), "locked" if a gate is 2
-- or more numbers off (the fence can't reach it), "either" between: there
-- the round fence, pressed on a gate's edge, may turn that wheel the last
-- bit itself (FINDINGS.md: it does from 1.5 below to 1.8 above)
local wheelPieces = {}
for i = 1, 3 do wheelPieces[i] = L.wheelPieces(GATES[i] * L.DEG) end
local camPieces = L.camPieces()
local BAND = 2.0
local function modelSays(s)
  local t = L.copy(s)
  L.turn(t, L.toOpen(t.D) - t.D)
  local fall = L.rodFall(t, GATES, wheelPieces, camPieces)
  local e = L.gateOffsets(t, GATES)
  local moved = L.turn(t, -L.PULL)
  if moved[3] ~= 0 then return "locked" end
  if fall >= L.HOOK_DROP then return "open" end
  for i = 1, 3 do if math.abs(e[i]) >= BAND then return "locked" end end
  return "either"
end
local function warnings(c)
  local w = {}
  if L.wrap(c[2] - c[1]) <= 11 then w[#w + 1] = "warn-12" end
  if L.wrap(c[2] - c[3]) <= 7 then w[#w + 1] = "warn-23" end
  if L.wrap(c[3] - L.OPEN_AT) >= L.N - 10 then w[#w + 1] = "warn-zone" end
  return w
end
local function try(c, intro, expect)
  push({ call = function()
    showGlyphs(slate.try, comboText(c))
    print(string.format("\nTRYING %s on the lock set to %s", L.text(c[1], c[2], c[3]), L.text(COMBO[1], COMBO[2], COMBO[3])))
    model = L.new(Dnow, Wnow)
  end })
  if intro then push({ say = intro, waitS = 2.2 }) end
  for _, w in ipairs(warnings(c)) do push({ say = w, waitS = 2.6 }) end
  local plan
  push({ call = function()
    plan = L.plan(Dnow, c[1], c[2], c[3])
    for k, m in ipairs(plan) do
      push({ say = m.say, waitS = 0.9 })
      push({ to = m.to, done = function() L.turn(model, m.to - model.D); logGates("after move " .. k) end })
    end
    push({ call = function()
      local says = modelSays(model)
      if expect == nil then
        if says == "open" then expect = true elseif says == "locked" then expect = false end
      end
      push({ say = "open", waitS = 0.9 })
      push({ open = true, done = function(stopped)
        readAll()
        local open = boltAt() > G.BOLT_TRAVEL - 1
        tried = tried + 1
        local ok = (expect == nil) or (open == expect)
        if not ok then fails = fails + 1 end
        logGates("turning right")
        print(string.format("  %s: the dial %s at %.1f; the bolt drawn back %.1f mm of %d, the fence fallen %.1f mm  (%s, the model says %s)%s",
          open and "OPEN" or "LOCKED", stopped and "stopped" or "turned on", L.wrap(Dnow), boltAt(), G.BOLT_TRAVEL, fenceFall(),
          expect == nil and "either expected" or (expect and "expected open" or "expected locked"), says, ok and "" or "  -- WRONG"))
        show(slate.say, open and "say-opened" or "say-locked")
        slateLive(true)
      end })
      push({ wait = 2.0 })
    end })
  end })
end
-- close: left two turns. The first 20 numbers steadily (at most 40 a
-- second): the cam's notch throwing the bolt back out by the fence. Faster,
-- the knock on the notch's wall lifted the fence out before the bolt was
-- fully thrown (FINDINGS.md).
local CLOSE_SLOW, CLOSE_V = 20, 40
local function close()
  push({ say = "close", waitS = 0.9 })
  push({ call = function()
    local D0 = Dnow
    push({ to = D0 + CLOSE_SLOW, vmax = CLOSE_V })
    push({ to = D0 + 2 * L.N, done = function()
      print(string.format("  closed: the bolt %.1f mm drawn back, the fence fallen %.1f mm", boltAt(), fenceFall()))
    end })
  end })
end

-- the tour: the lock's own combination; one number off by five; every number off by one
local TOUR = {
  { COMBO, "t-own", true },
  "close",
  { { COMBO[1], COMBO[2], (COMBO[3] + 5) % L.N }, "t-wrong", false },
  { { (COMBO[1] + 1) % L.N, (COMBO[2] - 1) % L.N, (COMBO[3] + 1) % L.N }, "t-near", true },
  "close",
}
local tryOne = parseCombo(os.getenv("LK_TRY"))
if tryOne then TOUR = { { tryOne } } end
local RANDOM_N = envnum("LK_RANDOM", 0)
if RANDOM_N > 0 then
  math.randomseed(envnum("LK_SEED", 1))
  TOUR = {}
  for k = 1, RANDOM_N do
    local c
    repeat
      c = { (COMBO[1] + math.random(-2, 2)) % L.N, (COMBO[2] + math.random(-2, 2)) % L.N, (COMBO[3] + math.random(-2, 2)) % L.N }
    until #warnings(c) == 0
    TOUR[#TOUR + 1] = { c }
    if k < RANDOM_N then TOUR[#TOUR + 1] = "close" end
  end
end
local touring = nil
local frame = 0
local function tourStart()
  touring, fails, tried = 1, 0, 0
  queue, job = {}, nil
  letGo()
  print("\nTHE COMBINATION LOCK -- the tour: the lock is set to " .. L.text(COMBO[1], COMBO[2], COMBO[3]) ..
    (tryOne and "; trying " .. L.text(tryOne[1], tryOne[2], tryOne[3]) or
     (RANDOM_N > 0 and ("; " .. RANDOM_N .. " combinations near it") or "; its own combination, one number five off, every number one off")))
end
local function tourNext()
  if not touring or not idle() then return end
  if touring > #TOUR then
    touring = nil
    print(string.format("RESULT combination lock tour: %s  (%d tried, %d not as expected; frame %d)",
      (fails == 0 and tried > 0) and "PASS" or "FAIL", tried, fails, frame))
    show(slate.say, "say-ready")
    return
  end
  local t = TOUR[touring]
  touring = touring + 1
  push({ wait = touring == 2 and 0.3 or 0.6 })
  if t == "close" then close() else try(t[1], t[2], t[3]) end
end

-- ---------------------------------------------------------------------
-- stepping: the lever's spring and the hand each step; resting when nothing
-- moves
-- ---------------------------------------------------------------------
local LEVER_TORQUE = function() return PRESS * (-G.PIVOT_X * MM) end    -- kg cm^2/s^2 about the pivot
local function springs()
  local t = LEVER_TORQUE()
  lever.body:applyTorque(btVector3(0, 0, -t))
  bolt.body:applyTorque(btVector3(0, 0, t))
end
local function stepOnce()
  springs()
  readAll()
  steer()
end
local REST_S = 0.5
local REST_ON = os.getenv("LK_REST") ~= "0"
local restFor, resting = 0, false
local function moving()
  if math.abs(dialSpeed()) > 0.05 then return true end
  for _, w in ipairs(wheels) do if math.abs(w.body:getAngularVelocity().z) > 0.002 then return true end end
  return lever.body:getAngularVelocity():length() > 0.002 or bolt.body:getLinearVelocity():length() > 0.002
end
local function restPre()
  if not resting then return false end
  if not idle() or touring then resting, restFor = false, 0; applyTiming(); return false end
  v.timeStep = 0
  return true
end
local function restPost()
  if resting then return end
  if not idle() or touring or moving() then restFor = 0; return end
  restFor = restFor + FRAME_DT
  if REST_ON and restFor >= REST_S then resting = true; v.timeStep = 0 end
end

-- the close views: the dial (M) and the gates under the fence (G). They
-- stand 30 cm off with a narrow view (in the hall, a 42 m scene, bpp clips
-- nearer than about 21 cm); bpp leaves the view at pi/4: put back.
local FOV = math.pi / 4
local closeView, camBack = nil, nil
local VIEWS = {
  dial = { pos = P(0, 105, 360), look = P(0, 22, 71), fov = 0.36 },
  gates = { pos = P(-90, 270, 130), look = P(0, 38, 22), fov = 0.42 },
}
local function viewOff(putBack)
  if not closeView then return end
  closeView = nil
  local cam = v.cam
  pcall(function() cam:setFieldOfView(FOV) end)
  cam:setUpVector(btVector3(0, 1, 0), true)
  if putBack and camBack then cam.pos = camBack.pos; cam.look = camBack.look end
  camBack = nil
end
local function viewOn(name)
  if closeView == name then viewOff(true); return end
  local cam = v.cam
  if not closeView then camBack = { pos = cam.pos, look = cam.look } end
  closeView = name
  local w = VIEWS[name]
  pcall(function() cam:setFieldOfView(w.fov) end)
  cam:setUpVector(btVector3(0, 1, 0), true)
  cam.pos = w.pos
  cam.look = w.look
end

-- (which way a hinge's motor turns, against our left +: tried for one step
-- at the start, the dial put back after)
local measured = false
local function measureMotor()
  local tr = dial.body:getCenterOfMassTransform()
  local keep = btTransform(tr:getRotation(), dial.body:getCenterOfMassPosition())
  dial.hinge:enableAngularMotor(true, 1, 1000 * STEP)
  v:stepSimulation(STEP, 0, STEP)
  local w = dial.body:getAngularVelocity().z
  MOTOR_SIGN = (w >= 0) and 1 or -1
  dial.body:setCenterOfMassTransform(keep)
  dial.body:setAngularVelocity(btVector3(0, 0, 0))
  dial.body:setLinearVelocity(btVector3(0, 0, 0))
  letGo()
  measured = true
end

v:preSim(function(N)
  if holdPre() then return end
  if not measured then measureMotor() end
  if restPre() then return end
  setFrictions()
  stepOnce()
  for k = 1, NSTEPS - 1 do v:stepSimulation(STEP, 0, STEP); stepOnce() end
end)
local started = false
local TRACE = os.getenv("LK_TRACE")
v:postSim(function(N)
  frame = frame + 1
  readAll()
  if TRACE and job and (job.to or job.open) and math.abs(L.centred(Dnow - L.OPEN_AT)) < 8 then
    local e = gateOffsets()       -- (each frame near the notch: where everything is)
    print(string.format("T f%d dial %.2f fence fallen %.3f mm, bolt %.3f mm, gates %+.2f %+.2f %+.2f",
      frame, L.wrap(Dnow), fenceFall(), boltAt(), e[1], e[2], e[3]))
  end
  follow()
  showFingers()
  slateLive()
  if holdNow then return end
  if not started then
    started = true
    if (os.getenv("LK_TOUR") or "1") ~= "0" then tourStart() end
  end
  stepJob(FRAME_DT)
  tourNext()
  restPost()
end)

-- ---------------------------------------------------------------------
-- keys, help, hover
-- ---------------------------------------------------------------------
local entry = ""
local function showEntry()
  local t = entry .. string.rep("_", 6 - #entry)
  showGlyphs(slate.try, t:sub(1, 2) .. "-" .. t:sub(3, 4) .. "-" .. t:sub(5, 6))
end
local function stopTour() touring = nil end
local function busy() return not idle() end
for d = 0, 9 do
  v:addShortcut(tostring(d), function()
    stopTour()
    if #entry < 6 then entry = entry .. d end
    showEntry()
    show(slate.say, "say-ready")
  end)
end
v:addShortcut("Backspace", function() entry = entry:sub(1, -2); showEntry() end)
local function enter()
  if busy() then return end
  stopTour()
  if #entry ~= 6 then print("  (six figures: 31 72 46, then Return)"); return end
  local c = { tonumber(entry:sub(1, 2)), tonumber(entry:sub(3, 4)), tonumber(entry:sub(5, 6)) }
  entry = ""
  try(c)
end
v:addShortcut("Return", enter)
v:addShortcut("Enter", enter)
v:addShortcut("L", function() if not busy() then stopTour(); push({ to = Dnow + 1 }) end end)
v:addShortcut("R", function() if not busy() then stopTour(); push({ to = Dnow - 1 }) end end)
v:addShortcut("Space", function()
  if busy() then return end
  stopTour()
  push({ say = "open", waitS = 0.6 })
  push({ open = true, done = function(stopped)
    local open = boltAt() > G.BOLT_TRAVEL - 1
    show(slate.say, open and "say-opened" or "say-locked")
    print(string.format("  %s (the dial %s at %.1f)", open and "OPEN" or "LOCKED", stopped and "stopped" or "turned on", L.wrap(Dnow)))
  end })
end)
v:addShortcut("C", function() if not busy() then stopTour(); close() end end)
v:addShortcut("T", function() tourStart() end)
v:addShortcut("M", function() viewOn("dial") end)
v:addShortcut("G", function() viewOn("gates") end)
if not hallPath then
  local MANUAL = dofile(DIR .. "../../open-manual.lua")
  for _, k in ipairs({ "H", "F1" }) do v:addShortcut(k, function() MANUAL.open(DIR, "the combination lock's manual") end) end
end
pcall(function() v:onLeave(function() viewOff(false) end) end)
v:onParamChanged(function(N, name, value)
  if name == "speed" then applyTiming() end
end)
pcall(function()
  local h = {
    "THE COMBINATION LOCK  (Babbage's Hall)",
    "",
    "KEYS",
    "  0 - 9  a combination, six figures (31 72 46); Return dials it and tries to open",
    "  Backspace  a figure off      L, R  the dial one number left, right",
    "  Space  right until the dial stops      C  close (left two turns)      T  the tour",
    "  M  the camera close to the dial      G  close to the gates; again: back",
    "  H  the manual (MANUAL.pdf, in your PDF viewer)",
    "",
    "Three wheels turn loose behind the cam; a pin in each makes it carry the",
    "next after nearly a turn. Left four times to the first number picks all",
    "three up and leaves wheel 1 there; right three times to the second leaves",
    "wheel 2; left twice to the third, wheel 3. If every gate is then under the",
    "fence, it falls into the cam's notch, and turning right draws the bolt.",
    "The lock is set to " .. L.text(COMBO[1], COMBO[2], COMBO[3]) .. "; a number one off still opens it.",
    "",
    "The wheels, the cam, the fence and the bolt are bodies, and every push is a",
    "contact. The hand turning the dial and the slate are the script's.",
  }
  v:setHelpText(table.concat(h, "\n"))
end)
if v.onHover then
  local KEY = {}
  if objectKey then
    KEY[objectKey(camObj)] = "the drive cam, on the spindle: its pin carries wheel 3; its notch takes the fence"
    for _, m in ipairs(dialRiders) do KEY[objectKey(m)] = "the dial: 100 numbers; turning it left brings higher numbers to the index" end
    for i, w in ipairs(wheels) do
      local s = string.format("wheel %d: it holds the %s number; its gate is the notch with the red line", i, ({ "first", "second", "third" })[i])
      KEY[objectKey(w.obj)] = s
      for _, m in ipairs(w.riders) do KEY[objectKey(m)] = s end
    end
    KEY[objectKey(leverObj)] = "the lever, pivoted on the bolt; a spring on its pin presses the fence down onto the cam"
    KEY[objectKey(rodObj)] = "the fence: a steel rod across the three wheels' rims and the cam"
    KEY[objectKey(boltObj)] = "the bolt: thrown into the keeper, the door is locked"
    KEY[objectKey(keeperObj)] = "the keeper, on the door's frame: the bolt goes into it"
    KEY[objectKey(standObj)] = "the front standard (the door): the dial's bearing, and the index at its top"
    KEY[objectKey(slateObj)] = "the slate (the script's): the combination tried, the dial, and where each gate stands from the fence"
    KEY[objectKey(fingersObj)] = "the operator's fingers (the script's)"
  end
  v:onHover(function(N, obj, x, y, z)
    local k = objectKey and objectKey(obj)
    local s = k and KEY[k]
    if not s then return nil end
    local e = gateOffsets()
    return s .. string.format("\nThe dial reads %.1f. The gates from the fence: %+.1f, %+.1f, %+.1f numbers. The bolt is %s.",
      L.wrap(Dnow), e[1], e[2], e[3], boltAt() > G.BOLT_TRAVEL - 1 and "drawn back: open" or "out: locked")
  end)
end

common.setCamera(P(-120, 330, 340), P(-35, 75, -15))
holdStart()
