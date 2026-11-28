--
-- Linkages That Compute -- Babbage's Hall
--
-- Hinged bars, flat on a board, that compute as they move.
--
-- THREE WAYS (LN_WAY; in the hall, Tab steps through them)
--   inverter   (the default) Peaucellier's inverter (1864): two arms from a
--              fixed pin O hold the corners of a rhombus whose other corners
--              P and Q stay on a line through O, and OP x OQ is always the
--              same, here 100. Set P at x on the scale; Q stops at 100 / x.
--   line       Peaucellier's straight line: P on a crank whose circle passes
--              through O. Q, the inverse of that circle, moves along a
--              straight line, and its pen draws it: the first linkage that
--              drew an exact straight line, which James Watt's could not.
--   multiply   a multiplier: a slotted lever through a fixed pin; the
--              b carriage, across the board at a fixed distance, tilts it;
--              the bridge, set at a along the board, carries a cross
--              carriage whose pin rides the slot too: it stands at a x b.
--
-- KEYS
--   0 - 9  .  -  a number                  Space  between two numbers (multiplying: a b)
--   Return       set it (the line: turn the crank across and back)
--   Backspace    a figure off               R  a number at random
--   T            the tour                    H  the manual (MANUAL.pdf)
--
-- PHYSICS: every bar, carriage, block and the lever and bridge is a body;
-- the pins are hinges (Bullet's btHingeConstraint), the slots sliders. Each
-- joint where more than two parts meet has a hub (one part the others are
-- hinged to); bars hinged together lie in different planes, 7 mm apart,
-- and never touch (the Walker Room's rules, demo/WyomingWill/WalkerRoom).
-- The board lies flat, so the bars' weight is across their plane of motion,
-- never in it. The hinges are stiff (no softening), and the solver works
-- every joint 80 times a step (10 is too few for the multiplier and the
-- straight line; 20 is enough in the sweeps; 80 leaves room: FINDINGS.md). The operator's hand
-- moves the input carriages (a motor on each slider: the hand's speed, no
-- more than 5 N) or turns the crank (a motor on its hinge); every reading
-- is taken from where the output pin is. The slate and the scales are the
-- script's. 600 steps a second.
--
-- EVERY PART CAN BE PRINTED: parts/linkages.scad, README.md.
--
-- Units: centimetres, kilograms, seconds.
-- Headless: LN_WAY (inverter, line, multiply), LN_TOUR=0, LN_SET="6.25" (multiplying "3 4"),
-- LN_LOG=1, LN_HAND (cm/s, or degrees/s for the crank), LN_HZ, LN_ITER (solver iterations),
-- LN_RANDOM=n and LN_SEED (n more settings at random in the tour).
--
local common = require "common"
local function envnum(n, d) return tonumber(os.getenv(n) or "") or d end
local WAY = os.getenv("LN_WAY") or "inverter"
if WAY ~= "line" and WAY ~= "multiply" then WAY = "inverter" end

-- ---------------------------------------------------------------------
-- this exhibit's folder; the parts file by its full path (OpenSCAD)
-- ---------------------------------------------------------------------
local DIR
for _, d in ipairs({ "", "demo/WyomingWill/BabbagesHall/exhibits/Linkages/" }) do
  local f = io.open(d .. "parts/linkages.scad", "r")
  if f then f:close(); DIR = d; break end
end
assert(DIR, "Linkages That Compute: can't find its folder")
local SCAD
do
  local path = DIR .. "parts/linkages.scad"
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
local SUM
do
  local f, sum = io.open(SCAD, "rb"), 0
  if f then
    local data = f:read("*a"); f:close()
    for i = 1, #data, 7 do sum = (sum * 31 + data:byte(i)) % 2147483647 end
    sum = (sum + #data) % 2147483647
  end
  SUM = sum
end
local function part(call, solid)
  local m = OpenSCAD("// " .. SUM .. "\ninclude <" .. SCAD .. ">\nscale(0.1) " .. call .. ";\n", 0, false)
  if not solid then m.collides = false end
  return m
end
local function pic(name)
  local p = DIR .. "slate/" .. name .. ".png"
  if hallPath then p = hallPath(p) end
  return p
end

-- the sizes (cm), as in linkages.scad
local G = {
  BOARD_T = 1.0, GAP = 0.7, THICK = 0.3, BAR_W = 0.8,
  OX = -13.0, L = 15.052, S = 11.25, C = 3.5,
  MOX = -15.0, MD = 6.0, LEVER_L = 25, BRIDGE_Z0 = -13.5, BRIDGE_Z1 = 13.5,
  PSCALE_X = 10.6, INDEX_X0 = -8.2,   -- (the product's scale, and its index rod's left end)
  BX0 = -16.5, BX1 = 12.5,
}
G.K2 = G.L * G.L - G.S * G.S            -- 100.0
local function planeY(k) return G.BOARD_T + 0.6 + k * G.GAP end

-- ---------------------------------------------------------------------
-- sliders, timing, the pause at every start
-- ---------------------------------------------------------------------
v:addParam("hand", envnum("LN_HAND", WAY == "line" and 40 or 2), WAY == "line" and 5 or 0.5, WAY == "line" and 120 or 8,
  WAY == "line" and 5 or 0.5, WAY == "line" and "how fast the hand turns the crank, degrees a second" or "how fast the hand moves a carriage, cm a second")
v:addParam("speed", 1, 0.05, 2, 0.05, "simulated seconds per real second")
local HZ = envnum("LN_HZ", 600)
local STEP, NSTEPS, FRAME_DT = 1 / HZ, 10, 1 / 60
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
local ITER = envnum("LN_ITER", 80)
pcall(function() v:setSolverIterations(ITER) end)

local ident = btQuaternion(0, 0, 0, 1)
local AXIS = btVector3(0, 1, 0)
local function qa(ax, ay, az, deg) return btQuaternion(btVector3(ax, ay, az), math.rad(deg)) end
local SX, SZ = -2, -16.5                -- the slate: its middle across, its face

local TABLE
do
  local path, f = DIR .. "../../exhibit-table.lua"
  if setfenv then f = assert(loadfile(path)); setfenv(f, getfenv(1))
  else f = assert(loadfile(path, "t", _ENV)) end
  TABLE = f()
end
TABLE.build(30, 34, { x = -2, z = -2, floor = 300 })

local O = {}                            -- the drawn parts, by name (for hover)
local function still(call, col, tr)
  local m = part(call, false)
  m.col = col
  v:add(m)
  m.trans = tr or btTransform(ident, btVector3(0, 0, 0))
  return m
end
O.board = still(string.format('board("%s")', WAY), "#c9a46a")
O.slate = still("slate()", "#22282a", btTransform(ident, btVector3(SX, 0, SZ)))
O.slateFrame = still("slateFrame()", "#6b4423", btTransform(ident, btVector3(SX, 0, SZ)))
local anchor = Cube(0.01, 0.01, 0.01, 0); anchor.collides = false; v:add(anchor)
anchor.trans = btTransform(ident, btVector3(0, 0, 0))

-- ---------------------------------------------------------------------
-- building: bars, carriages, hinges, sliders
-- ---------------------------------------------------------------------
local RHO = 0.00124                     -- PLA, kg a cm^3
local BAR_COL = { "#8e5a2b", "#a0692f", "#6f4a26", "#b07a3c", "#7d5530" }
local parts = {}                        -- every moving part: { obj, body, name }
local function dyn(obj, body, name)
  obj.body = body
  obj.collides = true
  v:add(obj)
  body:setActivationState(4)
  parts[#parts + 1] = { obj = obj, body = body, name = name }
  return obj
end
-- a bar from p1 to p2 (points {x, z}) on a plane; its own x runs from p1
-- to p2, its middle its origin. Returns the body and its ends (local).
local function bar(p1, p2, plane, name)
  local dx, dz = p2.x - p1.x, p2.z - p1.z
  local len = math.sqrt(dx * dx + dz * dz)
  local q = btQuaternion(AXIS, math.atan2(-dz, dx))
  local tr = btTransform(q, btVector3((p1.x + p2.x) / 2, planeY(plane), (p1.z + p2.z) / 2))
  local m = RHO * len * G.BAR_W * G.THICK
  local o = part(string.format("translate([%g, 0, 0]) barFlat(%g)", -len * 5, len * 10), true)
  o.col = BAR_COL[(plane % #BAR_COL) + 1]
  local shape = btBoxShape(btVector3(len / 2 + G.BAR_W / 2, G.THICK / 2, G.BAR_W / 2))
  local b = btRigidBody(m, btDefaultMotionState(tr), shape, btVector3(m * len * len / 12, m * len * len / 12, m * len * len / 12))
  dyn(o, b, name)
  o.trans = tr
  b:setCenterOfMassTransform(tr)
  return { obj = o, body = b, len = len, plane = plane, a = btVector3(-len / 2, 0, 0), b = btVector3(len / 2, 0, 0), name = name }
end
-- a carriage on a plane at (x, z): a block with a pin and a knob
local function carriage(x, z, plane, name, mass)
  local tr = btTransform(ident, btVector3(x, planeY(plane), z))
  local o = part("carriage()", true)
  o.col = "#5a6b78"
  local m = mass or 0.01
  local b = btRigidBody(m, btDefaultMotionState(tr), btBoxShape(btVector3(0.7, 0.2, 0.7)), btVector3(m, m, m))
  dyn(o, b, name)
  o.trans = tr
  b:setCenterOfMassTransform(tr)
  return { obj = o, body = b, plane = plane, name = name }
end
-- a hinge (an upright pin) between two parts: pa on A, pb on B, each in its
-- own frame at its own plane's height; A's point is raised (or lowered) to
-- B's plane, on the same upright axis (a hinge pins its points together in
-- all three directions)
local hinges = {}
local function hinge(A, B, pa, pb, name)
  local pa2 = btVector3(pa.x, pa.y + planeY(B.plane) - planeY(A.plane), pa.z)
  local h = btHingeConstraint(A.body, B.body, pa2, pb, AXIS, AXIS)
  v:addConstraint(h)
  hinges[#hinges + 1] = { h = h, A = A, B = B, pa = pa2, pb = pb, name = name }
  return h
end
-- a slider: B along the line through A's point fa, direction dir ("x" or "z")
local QZ = qa(0, 1, 0, -90)             -- (a slider's axis is its frame's x: QZ turns it to z)
local function slider(A, B, fa, dir, lo, hi)
  local q = dir == "z" and QZ or ident
  local s = btSliderConstraint(A.body, B.body, btTransform(q, fa), btTransform(q, btVector3(0, 0, 0)), true)
  s:setLowerLinLimit(lo); s:setUpperLinLimit(hi)
  s:setLowerAngLimit(0); s:setUpperAngLimit(0)
  v:addConstraint(s)
  return s
end
local function handMotor(s) s:setPoweredLinMotor(true); s:setTargetLinMotorVelocity(0); s:setMaxLinMotorForce(500) end
local BASE = { body = anchor.body, plane = 0 }   -- (the board, as a part: its pins are fixed)
pcall(function() v.showConstraints = false end)

-- a part's point in the world (its full rotation, by Rodrigues' formula)
local function world(body, p)
  local q, c = body:getCenterOfMassTransform():getRotation(), body:getCenterOfMassPosition()
  local th = q:getAngle()
  if th < 1e-9 then return { x = c.x + p.x, y = c.y + p.y, z = c.z + p.z } end
  local k = q:getAxis()
  local ct, st = math.cos(th), math.sin(th)
  local kx, ky, kz = k.y * p.z - k.z * p.y, k.z * p.x - k.x * p.z, k.x * p.y - k.y * p.x
  local kd = k.x * p.x + k.y * p.y + k.z * p.z
  return { x = c.x + p.x * ct + kx * st + k.x * kd * (1 - ct), y = c.y + p.y * ct + ky * st + k.y * kd * (1 - ct),
           z = c.z + p.z * ct + kz * st + k.z * kd * (1 - ct) }
end
local function hingeGap(hg)
  local a, b = world(hg.A.body, hg.pa), world(hg.B.body, hg.pb)
  return math.sqrt((a.x - b.x) ^ 2 + (a.z - b.z) ^ 2)
end

-- ---------------------------------------------------------------------
-- the mechanism, by the way
-- ---------------------------------------------------------------------
local M = {}                            -- what the jobs need: inputs, the reading
if WAY == "inverter" or WAY == "line" then
  -- Peaucellier: O, P on the x axis through O, Q at K2 / OP; A and B over
  -- the middle of P-Q. Planes: the carriage (or crank) 0, OA 1, OB 2,
  -- PA and QB 3, QA and PB 4 (opposite sides of a rhombus never meet).
  local function joints(px, pz)
    local op = math.sqrt(px * px + pz * pz)
    local ux, uz = px / op, pz / op
    local oq = G.K2 / op
    local m = (op + oq) / 2
    local h = math.sqrt(G.S * G.S - ((oq - op) / 2) ^ 2)
    local Ox = G.OX
    return { O = { x = Ox, z = 0 }, P = { x = Ox + px, z = pz }, Q = { x = Ox + ux * oq, z = uz * oq },
             A = { x = Ox + ux * m + uz * h, z = uz * m - ux * h }, B = { x = Ox + ux * m - uz * h, z = uz * m + ux * h } }
  end
  local p0x, p0z = 7, 0
  if WAY == "line" then
    local phi = math.rad(-60)            -- (the crank, from P on the axis at 2C)
    p0x, p0z = G.C + G.C * math.cos(phi), G.C * math.sin(phi)
  end
  local J = joints(p0x, p0z)
  local OA = bar(J.O, J.A, 1, "arm OA")
  local OB = bar(J.O, J.B, 2, "arm OB")
  local PA = bar(J.P, J.A, 3, "side PA")
  local QB = bar(J.Q, J.B, 3, "side QB")
  local QA = bar(J.Q, J.A, 4, "side QA")
  local PB = bar(J.P, J.B, 4, "side PB")
  local Obase = { body = anchor.body, plane = 0 }
  -- (the board's points are world points, at plane 0's height)
  hinge(Obase, OA, btVector3(G.OX, planeY(0), 0), OA.a, "O")
  hinge(Obase, OB, btVector3(G.OX, planeY(0), 0), OB.a, "O")
  hinge(OA, PA, OA.b, PA.b, "A"); hinge(OA, QA, OA.b, QA.b, "A")
  hinge(OB, QB, OB.b, QB.b, "B"); hinge(OB, PB, OB.b, PB.b, "B")
  hinge(QA, QB, QA.a, QB.a, "Q")
  local Phub
  if WAY == "inverter" then
    local car = carriage(J.P.x, 0, 0, "the input carriage")
    local s = slider(BASE, car, btVector3(G.OX, planeY(0), 0), "x", 4.6, 9.4)
    handMotor(s)
    Phub = car
    M.inputs = { { s = s, get = function() return s:getLinearPos() end } }
    M.knob = function() return car.body:getCenterOfMassPosition() end
  else
    local crank = bar({ x = G.OX + G.C, z = 0 }, J.P, 0, "the crank")
    local hc = hinge({ body = anchor.body, plane = 0 }, crank, btVector3(G.OX + G.C, planeY(0), 0), crank.a, "C")
    hc:enableAngularMotor(true, 0, 50)
    Phub = crank
    M.crank, M.crankBar = hc, crank
    -- (the crank's angle, from its two ends)
    M.crankAngle = function()
      local a, b = world(crank.body, crank.a), world(crank.body, crank.b)
      return math.deg(math.atan2(b.z - a.z, b.x - a.x))
    end
    M.knob = function() local p = world(crank.body, crank.b); return btVector3(p.x, p.y, p.z) end
  end
  -- P: the carriage (or the crank's end) the hub
  local pP = Phub.body and (Phub.len and Phub.b or btVector3(0, 0, 0))
  hinge(Phub, PA, pP, PA.a, "P"); hinge(Phub, PB, pP, PB.a, "P")
  M.Q = function() return world(QA.body, QA.a) end
  M.bars = { OA = OA, OB = OB, PA = PA, PB = PB, QA = QA, QB = QB }
  -- the output's pointer (a pin cap at Q) and, for the line, the pen
  M.qcap = part("knob()"); M.qcap.col = "#c0392b"; v:add(M.qcap)
else
  -- the multiplier: the lever from O; the b carriage across at O + D (its
  -- block below the lever); the bridge along (its block above). Planes:
  -- the b carriage 0, its block 1, the lever 2, the cross carriage's block
  -- 3, the cross carriage 4; the bridge 1 (always beyond the b carriage).
  local Ox, D = G.MOX, G.MD
  local a0, b0 = 3, 2
  local X0, Y0 = 4 * a0, 0.75 * b0
  local ang = math.atan2(Y0, D)
  local qlev = btQuaternion(AXIS, -ang)
  local L = G.LEVER_L
  local lever
  do
    local tr = btTransform(qlev, btVector3(Ox + L / 2 * math.cos(ang), planeY(2), L / 2 * math.sin(ang)))
    local m = RHO * L * 1.4 * G.THICK
    local o = part(string.format("translate([%g, 0, 0]) leverFlat()", -L * 5), true)
    o.col = "#8e5a2b"
    local b = btRigidBody(m, btDefaultMotionState(tr), btBoxShape(btVector3(L / 2 + 0.7, G.THICK / 2, 0.7)),
      btVector3(m * L * L / 12, m * L * L / 12, m * L * L / 12))
    dyn(o, b, "the lever")
    o.trans = tr
    b:setCenterOfMassTransform(tr)
    lever = { obj = o, body = b, plane = 2, a = btVector3(-L / 2, 0, 0) }
  end
  hinge({ body = anchor.body, plane = 0 }, lever, btVector3(Ox, planeY(0), 0), lever.a, "O")
  local function block(car, px, pz, plane)
    local tr = btTransform(qlev, btVector3(px, planeY(plane), pz))
    local o = part("block()", true)
    o.col = "#3a4a56"
    local m = 0.004
    local b = btRigidBody(m, btDefaultMotionState(tr), btBoxShape(btVector3(0.6, 0.15, 0.4)), btVector3(m, m, m))
    dyn(o, b, "a block in the lever's slot")
    o.trans = tr
    b:setCenterOfMassTransform(tr)
    local blk = { obj = o, body = b, plane = plane }
    hinge(car, blk, btVector3(0, 0, 0), btVector3(0, 0, 0), "a block's pin")
    local s = btSliderConstraint(lever.body, b, btTransform(ident, btVector3(-L / 2, planeY(plane) - planeY(2), 0)),
      btTransform(ident, btVector3(0, 0, 0)), true)
    s:setLowerLinLimit(1.0); s:setUpperLinLimit(L - 0.5)
    s:setLowerAngLimit(0); s:setUpperAngLimit(0)
    v:addConstraint(s)
    return blk
  end
  local ycar = carriage(Ox + D, Y0, 0, "the b carriage")
  local ys = slider(BASE, ycar, btVector3(Ox + D, planeY(0), 0), "z", -3.9, 3.9)
  handMotor(ys)
  block(ycar, Ox + D, Y0, 1)
  local BM = RHO * 1.2 * 0.4 * (G.BRIDGE_Z1 - G.BRIDGE_Z0) * 3
  local bridge
  do
    local tr = btTransform(ident, btVector3(Ox + X0, planeY(1), 0))
    local o = part("bridge()", true)
    o.col = "#6f4a26"
    local b = btRigidBody(BM, btDefaultMotionState(tr), btBoxShape(btVector3(0.6, 0.2, (G.BRIDGE_Z1 - G.BRIDGE_Z0) / 2)),
      btVector3(BM * 20, BM * 20, BM * 20))
    dyn(o, b, "the bridge")
    o.trans = tr
    b:setCenterOfMassTransform(tr)
    bridge = { obj = o, body = b, plane = 1 }
  end
  local xs = slider(BASE, bridge, btVector3(Ox, planeY(1), 0), "x", 7.6, 20.4)
  handMotor(xs)
  local Z0 = X0 * Y0 / D
  local zcar = carriage(Ox + X0, Z0, 4, "the cross carriage")
  local zs = slider(bridge, zcar, btVector3(0, planeY(4) - planeY(1), Z0), "z", G.BRIDGE_Z0 + 0.8 - Z0, G.BRIDGE_Z1 - 0.8 - Z0)
  block(zcar, Ox + X0, Z0, 3)
  -- (the inputs: a = X / 4 along, b = Y / 0.75 across; the reading a b = 2 Z)
  M.inputs = { { s = xs, get = function() return xs:getLinearPos() end },
               { s = ys, get = function() return ys:getLinearPos() end } }
  M.product = function() return 2 * zcar.body:getCenterOfMassPosition().z end
  M.knobs = { function() return bridge.body:getCenterOfMassPosition() end, function() return ycar.body:getCenterOfMassPosition() end }
  M.bridge, M.zcar = bridge, zcar
end

-- ---------------------------------------------------------------------
-- the scales (make-slate.py): on the board, and on the bridge
-- ---------------------------------------------------------------------
local QUP = qa(1, 0, 0, -90)            -- (a tile lying face up, its top away from you)
local function tile(w, h, x, y, z, picture, q)
  local c = Cube(w, h, 0.01, 0)
  c.collides = false
  c.tex = pic(picture)
  v:add(c)
  c.trans = btTransform(q or ident, btVector3(x, y, z))
  return c
end
local BOARD_Y = G.BOARD_T + 0.006
if WAY == "inverter" then
  tile(21.0, 1.6, G.OX + 4.0 + 10.5, BOARD_Y, 1.4, "scale-inverter", QUP)
elseif WAY == "line" then
  -- (a ruled line where the pen should go, and its label)
  tile(0.08, 26, G.OX + G.K2 / (2 * G.C), BOARD_Y, 0, "rule", QUP)
  tile(5.0, 0.9, G.OX + G.K2 / (2 * G.C) + 3.2, BOARD_Y, 12.6, "label-the-line", QUP)
else
  tile(14.8, 1.6, G.MOX + 14.0, BOARD_Y, 12.0, "scale-a", QUP)
  tile(1.6, 8.6, G.MOX + G.MD - 1.6, BOARD_Y, 0, "scale-b", QUP)
  -- (the product's scale is fixed at the board's right edge, clear of the
  -- lever and the bridge; a rod rides across the board with the cross
  -- carriage, as in the build, where the carriage grips a rod that slides
  -- across in a guide at the edge, and its tip points at the product)
  tile(1.8, 26.0, G.PSCALE_X + 0.9, BOARD_Y, 0, "scale-product", QUP)
  M.indexRod = Cube(G.PSCALE_X - G.INDEX_X0, 0.15, 0.2, 0)
  M.indexRod.collides = false; M.indexRod.col = "#7a2a1a"; v:add(M.indexRod)
  -- (at the scale it drops to the paper, and a red line across the scale
  -- marks the reading: read from above, the raised rod would be seen
  -- against the wrong mark)
  M.indexDrop = Cube(0.12, planeY(5) - BOARD_Y, 0.12, 0)
  M.indexDrop.collides = false; M.indexDrop.col = "#7a2a1a"; v:add(M.indexDrop)
  M.indexLine = tile(1.8, 0.05, G.PSCALE_X + 0.9, BOARD_Y + 0.003, 0, "rule", QUP)
end

-- ---------------------------------------------------------------------
-- the slate (make-slate.py): three labelled numbers and a line of what
-- the hand is doing
-- ---------------------------------------------------------------------
local slate = { rows = {} }
local SLZ = SZ + 0.03
slate.say = tile(20.6, 2.0, SX, 17.4, SLZ, "say-" .. WAY .. "-ready")
local ROWY = { 14.9, 12.1, 9.3 }
for r = 1, 3 do
  slate.rows[r] = { label = tile(12.0, 0.8, SX - 3.6, ROWY[r], SLZ, "label-blank"), d = {} }
  for k = 1, 7 do slate.rows[r].d[k] = tile(1.0, 1.4, SX + 3.2 + (k - 1) * 1.1, ROWY[r], SLZ, "ch-blank") end
end
local shown = {}
local function show(t, picture) if shown[t] ~= picture then shown[t] = picture; t.tex = pic(picture) end end
local CH = { ["."] = "dot", ["-"] = "minus", [" "] = "blank" }
local function showNumber(r, s, green)
  s = s or ""
  local row = slate.rows[r]
  local pad = 7 - #s
  for k = 1, 7 do
    local c = k > pad and s:sub(k - pad, k - pad) or " "
    local n = CH[c] or c
    show(row.d[k], "ch-" .. n .. ((green and n ~= "blank") and "-green" or ""))
  end
end
local LABELS = WAY == "inverter" and { "label-x", "label-q", "label-worked" }
  or WAY == "line" and { "label-crank", "label-off", "label-worst" }
  or { "label-a", "label-b", "label-ab" }
for r = 1, 3 do show(slate.rows[r].label, LABELS[r]) end
local function sayIt(s) show(slate.say, "say-" .. WAY .. "-" .. s) end

-- ---------------------------------------------------------------------
-- the hand (drawn): its finger on the knob of what it moves
-- ---------------------------------------------------------------------
local finger = part("finger()"); finger.col = "#e0b896"; v:add(finger)
local QFING = qa(1, 0, 0, -55)            -- (from its tip on the knob up and toward you)
local REST = btVector3(G.BX1 + 2, 3, 9)
local fingerAt = REST
local function placeFinger(p) fingerAt = p; finger.trans = btTransform(QFING, btVector3(p.x, p.y + 2.1, p.z + 0.2)) end
placeFinger(REST)
local knobs = {}
local function knobFor(i)
  if not knobs[i] then knobs[i] = part("knob()"); knobs[i].col = "#2b1e14"; v:add(knobs[i]) end
  return knobs[i]
end
local function placeKnobs()
  if WAY == "inverter" then
    local p = M.knob(); knobFor(1).trans = btTransform(ident, btVector3(p.x, planeY(0) + 0.4, p.z))
  elseif WAY == "line" then
    local p = M.knob(); knobFor(1).trans = btTransform(ident, btVector3(p.x, planeY(0) + 0.2, p.z))
  else
    local p = M.knobs[1](); knobFor(1).trans = btTransform(ident, btVector3(p.x, planeY(1) + 0.2, G.BRIDGE_Z1 - 0.6))
    p = M.knobs[2](); knobFor(2).trans = btTransform(ident, btVector3(p.x, planeY(0) + 0.4, p.z))
    if M.indexRod then
      local zp = M.zcar.body:getCenterOfMassPosition()
      M.indexRod.trans = btTransform(ident, btVector3((G.INDEX_X0 + G.PSCALE_X) / 2, planeY(5), zp.z))
      M.indexDrop.trans = btTransform(ident, btVector3(G.PSCALE_X - 0.06, (planeY(5) + BOARD_Y) / 2, zp.z))
      M.indexLine.trans = btTransform(QUP, btVector3(G.PSCALE_X + 0.9, BOARD_Y + 0.003, zp.z))
    end
  end
  if M.Q then
    local q = M.Q(); M.qcap.trans = btTransform(ident, btVector3(q.x, planeY(4) + 0.2, q.z))
  end
end

-- ---------------------------------------------------------------------
-- the pen's line (the straight-line way): a dot every so often, drawn
-- ---------------------------------------------------------------------
local pen = { dots = {}, worst = 0, last = nil }
local function penClear()
  for _, d in ipairs(pen.dots) do v:remove(d) end
  pen.dots, pen.worst, pen.last = {}, 0, nil
end
local function penDot(q)
  if pen.last and (q.x - pen.last.x) ^ 2 + (q.z - pen.last.z) ^ 2 < 0.09 then return end
  pen.last = q
  local c = Cube(0.16, 0.02, 0.16, 0)
  c.collides = false
  c.col = "#1a1a1a"
  v:add(c)
  c.trans = btTransform(ident, btVector3(q.x, G.BOARD_T + 0.02, q.z))
  pen.dots[#pen.dots + 1] = c
end

-- ---------------------------------------------------------------------
-- the jobs
-- ---------------------------------------------------------------------
local LOG = os.getenv("LN_LOG")
local queue, job = {}, nil
local S = { entry = "", result = nil }
local function idle() return job == nil and #queue == 0 end
local function fmt(x, n) return string.format("%." .. (n or 2) .. "f", x) end
-- (the input carriages' positions for the numbers set)
local function targetsFor(vals)
  if WAY == "inverter" then return { vals[1] } end
  return { 4 * vals[1], 0.75 * vals[2] }
end
local TOL = WAY == "multiply" and 0.02 or 0.01     -- (0.1 mm; the product reads twice the cross carriage's place)
local function stepJob(dt)
  if not job then
    if #queue == 0 then return end
    job = { q = table.remove(queue, 1), t = 0 }
    if job.q.say then sayIt(job.q.say) end
  end
  local q = job.q
  job.t = job.t + dt
  if q.wait then
    if job.t >= q.wait then job = nil end
  elseif q.set then
    -- the hand moves each input carriage to its place, slowly at the end
    local tg = targetsFor(q.vals)
    local done = true
    local speed = v:getParam("hand")
    for i, inp in ipairs(M.inputs) do
      local d = tg[i] - inp.get()
      inp.s:setTargetLinMotorVelocity(math.max(-speed, math.min(speed, d * 5)))
      if math.abs(d) > 0.0015 then done = false end
    end
    local kp = WAY == "inverter" and M.knob() or M.knobs[(math.abs(tg[1] - M.inputs[1].get()) > 0.0015) and 1 or 2]()
    placeFinger(btVector3(kp.x, kp.y, kp.z))
    if WAY == "inverter" then showNumber(1, fmt(M.inputs[1].get()))
    else showNumber(1, fmt(M.inputs[1].get() / 4)); showNumber(2, fmt(M.inputs[2].get() / 0.75)) end
    job.still = done and (job.still or 0) + dt or 0
    if job.still >= 0.4 or job.t > 30 then
      for _, inp in ipairs(M.inputs) do inp.s:setTargetLinMotorVelocity(0) end
      job = nil
    end
  elseif q.read then
    local got, want, text
    if WAY == "inverter" then
      local x = M.inputs[1].get()
      got = M.Q().x - G.OX
      want = G.K2 / x
      text = string.format("x %s: Q stops at %.4f, 100 / x is %.4f", fmt(x, 3), got, want)
      showNumber(2, fmt(got)); showNumber(3, fmt(want))
    else
      local a, b = M.inputs[1].get() / 4, M.inputs[2].get() / 0.75
      got = M.product()
      want = a * b
      text = string.format("a %s, b %s: the cross carriage reads %.4f, a b is %.4f", fmt(a, 3), fmt(b, 3), got, want)
      showNumber(3, fmt(got))
    end
    local ok = math.abs(got - want) < TOL
    local worstGap = 0
    for _, hg in ipairs(hinges) do worstGap = math.max(worstGap, hingeGap(hg)) end
    print(string.format("  %s: off by %.4f (%s); the pins open %.4f cm at most", text, got - want, ok and "right" or "WRONG", worstGap))
    S.result = ok
    if WAY == "inverter" then showNumber(2, fmt(got), ok) else showNumber(3, fmt(got), ok) end
    sayIt(ok and "done" or "wrong")
    job = nil
  elseif q.sweep then
    -- the hand turns the crank to each angle in turn; the pen marks Q
    if not job.i then job.i = 1; penClear(); job.worst = 0; job.lineX = G.OX + G.K2 / (2 * G.C) end
    local want = q.angles[job.i]
    local a = M.crankAngle()
    local d = want - a
    local speed = math.rad(v:getParam("hand"))
    -- (the hand speeds up and slows down over a third of a second: turned
    -- back at once, the crank jerks the cell, and the pen swings 0.05 mm
    -- off the line for a moment)
    local w = math.max(-speed, math.min(speed, math.rad(d) * 5))
    local dw = speed * dt / 0.3
    job.w = math.max((job.w or 0) - dw, math.min((job.w or 0) + dw, w))
    M.crank:enableAngularMotor(true, job.w, 50)
    local qp = M.Q()
    penDot(qp)
    local off = math.abs(qp.x - job.lineX)
    if job.t > 0.5 then job.worst = math.max(job.worst, off) end
    showNumber(1, fmt(a, 1)); showNumber(2, fmt(off * 10, 3)); showNumber(3, fmt(job.worst * 10, 3))
    local kp = M.knob(); placeFinger(btVector3(kp.x, kp.y, kp.z))
    if math.abs(d) < 0.3 then
      job.i = job.i + 1
      if not q.angles[job.i] then
        M.crank:enableAngularMotor(true, 0, 50)
        local worstGap = 0
        for _, hg in ipairs(hinges) do worstGap = math.max(worstGap, hingeGap(hg)) end
        local ok = job.worst < 0.005
        print(string.format("  the crank from %g to %g degrees and back: the pen %.4f mm off the line at most, %d marks (%s); the pins open %.4f cm at most",
          q.angles[1], q.angles[2], job.worst * 10, #pen.dots, ok and "straight" or "NOT straight", worstGap))
        S.result = ok
        showNumber(3, fmt(job.worst * 10, 3), ok)
        sayIt(ok and "done" or "wrong")
        job = nil
      end
    end
    if job and job.t > 60 then print("  the crank didn't get there"); S.result = false; job = nil end
  elseif q.home then
    placeFinger(REST)
    job = nil
  elseif q.call then
    q.call(); job = nil
  else
    job = nil
  end
end
local function queueSet(vals)
  queue[#queue + 1] = { say = "setting", set = true, vals = vals }
  queue[#queue + 1] = { say = "reading", wait = 0.4 }
  queue[#queue + 1] = { read = true }
  queue[#queue + 1] = { home = true }
end
local function queueSweep(a0, a1)
  queue[#queue + 1] = { say = "turning", sweep = true, angles = { a0, a1, a0 } }
  queue[#queue + 1] = { home = true }
end
local function parse(s)
  local t = {}
  for n in s:gmatch("%-?[%d%.]+") do t[#t + 1] = tonumber(n) end
  return t
end
local function clampVals(t)
  if WAY == "inverter" then
    local x = t[1]; if not x then return nil end
    return { math.max(5, math.min(9, x)) }
  end
  local a, b = t[1], t[2]; if not a or not b then return nil end
  return { math.max(2, math.min(5, a)), math.max(-5, math.min(5, b)) }
end

-- ---------------------------------------------------------------------
-- the tour
-- ---------------------------------------------------------------------
local TOUR = WAY == "inverter" and { { 5 }, { 6.25 }, { 8 }, { 9 } }
  or WAY == "multiply" and { { 3, 4 }, { 2.5, 2.5 }, { 4.5, -2 }, { 5, 5 } }
  or { { -80, 80 } }
do
  local n = envnum("LN_RANDOM", 0)
  if n > 0 then
    math.randomseed(envnum("LN_SEED", 1))
    for i = 1, n do
      if WAY == "inverter" then TOUR[#TOUR + 1] = { 5 + 4 * math.random() }
      elseif WAY == "multiply" then TOUR[#TOUR + 1] = { 2 + 3 * math.random(), -5 + 10 * math.random() }
      else local a = 30 + 50 * math.random(); TOUR[#TOUR + 1] = { -a, a } end
    end
  end
end
local touring, fails = nil, 0
local function tourStart()
  touring, fails = 1, 0
  print(string.format("\nLINKAGES THAT COMPUTE (%s) -- the tour: %d %s", WAY, #TOUR,
    WAY == "line" and (#TOUR == 1 and "sweep" or "sweeps") or "settings"))
end
local function tourNext()
  if not touring or not idle() then return end
  if touring > 1 and S.result ~= true then fails = fails + 1 end
  if touring > #TOUR then
    touring = nil
    print("RESULT linkages " .. WAY .. " tour: " .. (fails == 0 and "PASS" or "FAIL")
          .. string.format("  (%d %s, %d wrong; frame %d)", #TOUR,
             WAY == "line" and (#TOUR == 1 and "sweep" or "sweeps") or "settings", fails, G.frame or 0))
    return
  end
  local t = TOUR[touring]
  touring = touring + 1
  S.result = nil
  queue[#queue + 1] = { wait = touring == 2 and 0.3 or 1.0 }
  if WAY == "line" then queueSweep(t[1], t[2]) else queueSet(t) end
end

-- ---------------------------------------------------------------------
-- stepping; resting when idle
-- ---------------------------------------------------------------------
local REST_ON = os.getenv("LN_REST") ~= "0"
local restFor, resting = 0, false
local function moving()
  for _, p in ipairs(parts) do if p.body:getLinearVelocity():length() > 0.02 then return true end end
  return false
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
  if REST_ON and restFor >= 0.5 then resting = true; v.timeStep = 0 end
end
v:preSim(function(N)
  if holdPre() then return end
  if restPre() then return end
  for k = 1, NSTEPS - 1 do v:stepSimulation(STEP, 0, STEP) end
end)
local started = false
v:postSim(function(N)
  G.frame = N
  placeKnobs()
  if holdNow then return end
  if not started then
    started = true
    local s = os.getenv("LN_SET")
    if s and s:match("%d") then
      local t = parse(s)
      if WAY == "line" then if t[1] then queueSweep(-math.abs(t[1]), math.abs(t[1])) end
      else local vals = clampVals(t); if vals then queueSet(vals) end end
    end
    if (os.getenv("LN_TOUR") or "1") ~= "0" then tourStart() end
  end
  stepJob(FRAME_DT)
  tourNext()
  restPost()
end)

-- ---------------------------------------------------------------------
-- keys, help, hover
-- ---------------------------------------------------------------------
local function showEntry()
  local t = parse(S.entry)
  if WAY == "inverter" then showNumber(1, S.entry)
  elseif WAY == "multiply" then
    local a, b = S.entry:match("^(%S*)%s*(%S*)$")
    showNumber(1, a or ""); showNumber(2, b or "")
  end
  sayIt("ready")
end
local function typed(c)
  touring = nil
  if #S.entry < 12 then S.entry = S.entry .. c end
  showEntry()
end
for d = 0, 9 do v:addShortcut(tostring(d), function() typed(tostring(d)) end) end
for _, k in ipairs({ ".", "Period" }) do pcall(function() v:addShortcut(k, function() typed(".") end) end) end
for _, k in ipairs({ "-", "Minus" }) do pcall(function() v:addShortcut(k, function() typed("-") end) end) end
pcall(function() v:addShortcut("Space", function() typed(" ") end) end)
v:addShortcut("Backspace", function() S.entry = S.entry:sub(1, -2); showEntry() end)
local function enter()
  touring = nil
  if WAY == "line" then
    local a = tonumber(S.entry) or 80
    S.entry = ""
    a = math.max(10, math.min(80, math.abs(a)))
    queueSweep(-a, a)
    return
  end
  local vals = clampVals(parse(S.entry))
  S.entry = ""
  if vals then queueSet(vals) end
end
v:addShortcut("Return", enter)
v:addShortcut("Enter", enter)
v:addShortcut("R", function()
  touring = nil
  S.entry = ""
  if WAY == "inverter" then queueSet({ 5 + 4 * math.random() })
  elseif WAY == "multiply" then queueSet({ 2 + 3 * math.random(), -5 + 10 * math.random() })
  else local a = 30 + 50 * math.random(); queueSweep(-a, a) end
end)
v:addShortcut("T", function() tourStart() end)
if not hallPath then
  local MANUAL = dofile(DIR .. "../../open-manual.lua")
  for _, k in ipairs({ "H", "F1" }) do v:addShortcut(k, function() MANUAL.open(DIR, "the linkages' manual") end) end
end
v:onParamChanged(function(N, name, value) if name == "speed" then applyTiming() end end)
pcall(function()
  local HELP = {
    inverter = {
      "PEAUCELLIER'S INVERTER (1864)",
      "Two arms from the fixed pin O hold the corners A and B of a rhombus; its",
      "other corners P and Q stay on a line through O, and OP x OQ is always 100.",
      "Type x, from 5 to 9 (a point for the decimals), and Return: the hand sets P",
      "at x on the scale, and Q stops at 100 / x.",
    },
    line = {
      "PEAUCELLIER'S STRAIGHT LINE",
      "The same linkage, P on a crank whose circle passes through O. Q, the",
      "inverse of a circle through O, moves along a straight line, and its pen",
      "draws it. Return turns the crank from -80 to 80 degrees and back (type a",
      "smaller angle first for less); the slate shows how far the pen is off the line.",
    },
    multiply = {
      "A MULTIPLIER",
      "A slotted lever through the fixed pin O. The b carriage, across the board at",
      "a fixed distance from O, tilts it; the bridge, at a along the board, carries",
      "a cross carriage whose pin rides the slot too: it stands at a x b. Type a",
      "(2 to 5), Space, b (-5 to 5), and Return. a = b squares.",
    },
  }
  local t = HELP[WAY]
  local lines = { "LINKAGES THAT COMPUTE: " .. t[1], "" }
  for i = 2, #t do lines[#lines + 1] = t[i] end
  for _, l in ipairs({ "",
    "KEYS: 0-9 . - Space a number; Return set it; Backspace; R at random; T the tour;",
    "H the manual. In the hall, Tab: the inverter, the straight line, the multiplier.",
    "",
    "Every bar, carriage and block is a body, every pin a hinge, every slot a",
    "slider; the hand moves the inputs; every reading is where the output pin is.",
    "The slate and the scales are the script's." }) do lines[#lines + 1] = l end
  v:setHelpText(table.concat(lines, "\n"))
end)
if v.onHover then
  local KEY = {}
  if objectKey then
    KEY[objectKey(O.board)] = "the board: the fixed pins are in it, and the slots the carriages run in"
    KEY[objectKey(O.slate)] = "the slate: what is set, what is read, and what the hand is doing (the script's)"
    KEY[objectKey(finger)] = "the operator's hand (the script's): it moves the inputs, and reads the output"
    for _, p in ipairs(parts) do KEY[objectKey(p.obj)] = p.name end
    if M.qcap then KEY[objectKey(M.qcap)] = "Q, the output: its distance from O is 100 over P's" end
  end
  v:onHover(function(N, obj) local k = objectKey and objectKey(obj); return k and KEY[k] end)
end

if WAY == "multiply" then
  -- (higher, to see the whole board: the a scale at its front, the
  -- product's at its right edge)
  common.setCamera(btVector3(-1, 42, 33), btVector3(-1, 3, -4))
else
  common.setCamera(btVector3(-2, 31, 29), btVector3(-2, 5, -4))
end
holdStart()
