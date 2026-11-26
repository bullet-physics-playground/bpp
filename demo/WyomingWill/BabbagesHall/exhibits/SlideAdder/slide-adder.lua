--
-- The Slide Adder -- Babbage's Hall
--
-- Adding by moving bands with a stylus: Louis Troncet's arithmographe
-- (1889) and, after it, the Addiator (1920), millions of them sold. Each
-- column is a band behind a cover, with a row of pegs a step apart along
-- its edge and the digits 0 to 9 on its face, one showing in the column's
-- window. To add d, put the stylus between the pegs beside the d on the
-- cover and draw it down to the bottom of the slot: the band goes down d
-- steps and the window shows d more. When the gap beside the d is red, the
-- band is too far down for d more: push it up to the top instead (up 10 - d
-- steps: d more, less ten), then round the hook into the next column and
-- one step down. That is the carry; the hook is the whole trick.
--
-- TWO WAYS (SA_WAY; in the hall, Tab steps through them)
--   add        (the default) Return adds the number typed
--   subtract   Return subtracts it: up from the digits on the slot's other
--              side, and where the gap is not red, down and round the
--              bottom hook to borrow; + adds (to put the first number in)
--
-- KEYS
--   0 - 9      a number (up to six figures)     Backspace  a figure off
--   Return     add it (subtract it, in the other way)
--   +  -       add it; subtract it               C          the bar: every band to 0
--   R          a number at random               T          the tour
--   H          the manual (MANUAL.pdf)
--
-- PHYSICS: the bands are bodies, each on a slider, held where they are left
-- by friction (a motor at no speed and a little force: they stand upright,
-- so it must be more than their weight). The cover's slots and channels are
-- a fixed body; the stylus is a body (a ball among the pegs, a ball in the
-- slot) moved by the operator's hand, a force toward where the hand means it
-- to be, no more than a hand's. Every band moves only because the stylus
-- pushes a peg; a carry gets into the next column only along the top
-- channel. The zeroing bar is a body on a slider, lifted by its tab. The
-- operator is the script: it reads the windows (and so whether a gap is
-- red), chooses the moves a person would make, and feels when the stylus
-- will go no further (a 9 that can't take a carry). The slate and the
-- labels are the script's. 600 steps a second.
--
-- EVERY PART CAN BE PRINTED: parts/slide-adder.scad, README.md.
--
-- Units: centimetres, kilograms, seconds.
-- Headless: SA_WAY (add, subtract), SA_TOUR=0 (no tour), SA_NUMS="47295+85358"
-- (a sum at the start: + and - between numbers; it starts from 0), SA_LOG=1,
-- SA_HAND (the hand's speed, cm/s), SA_FRICTION (a band in its groove, kg cm/s^2),
-- SA_FORCE (the most the hand pushes with, kg cm/s^2), SA_HZ (steps a second),
-- SA_RANDOM=n and SA_SEED (n more sums at random in the tour).
--
local common = require "common"
local function envnum(n, d) return tonumber(os.getenv(n) or "") or d end
local WAY = os.getenv("SA_WAY") == "subtract" and "subtract" or "add"

-- ---------------------------------------------------------------------
-- this exhibit's folder; the parts file by its full path (OpenSCAD)
-- ---------------------------------------------------------------------
local DIR
for _, d in ipairs({ "", "demo/WyomingWill/BabbagesHall/exhibits/SlideAdder/" }) do
  local f = io.open(d .. "parts/slide-adder.scad", "r")
  if f then f:close(); DIR = d; break end
end
assert(DIR, "The Slide Adder: can't find its folder")
local SCAD
do
  local path = DIR .. "parts/slide-adder.scad"
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

-- the sizes (cm), as in slide-adder.scad
local G = {
  NCOL = 6, P = 0.8, RP = 0.2, NPEG = 21, W = 2.4, S = 0.4, Y0 = 12.0,
  BODY_Z0 = -0.6, BODY_Z1 = -0.35, PEG_Z0 = -0.35, PEG_Z1 = 0, COVER_Z0 = 0.05, COVER_Z1 = 0.35,
  BAND_X0 = -0.25, BAND_X1 = 1.95, DIGIT_X = 1.0,
}
G.YT = G.Y0 + 10 * G.P
G.YW = G.Y0 - 1.6
G.YB = G.YW - 0.6
G.YBT = G.Y0 + (G.NPEG - 0.5) * G.P + 0.3
G.TRAVEL = 9 * G.P
G.YBAR = G.YB - G.TRAVEL - 0.6
G.XL, G.XR = -7.5, 9.0
G.YCB, G.YCT = G.YB - G.TRAVEL - 1.8, G.YBT + 0.6
G.TIPZ = -0.17                          -- the stylus's tip ball, among the pegs (its shank's ball in the slot)
local function colX(j) return ((G.NCOL + 1) / 2 - j) * G.W end

-- ---------------------------------------------------------------------
-- sliders, timing, the pause at every start
-- ---------------------------------------------------------------------
v:addParam("hand", envnum("SA_HAND", 6), 1, 15, 0.5, "how fast the hand moves the stylus, cm a second")
v:addParam("friction", envnum("SA_FRICTION", 20), 13, 60, 1, "a band in its groove, kg cm/s^2 (its weight is 11.8: less, and it slides down)")
v:addParam("speed", 1, 0.05, 2, 0.05, "simulated seconds per real second")
local HZ = envnum("SA_HZ", 600)
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
pcall(function() v:setSolverIterations(20) end)

local ident = btQuaternion(0, 0, 0, 1)
local function qa(ax, ay, az, deg) return btQuaternion(btVector3(ax, ay, az), math.rad(deg)) end
local SX, SZ = 19.5, -2.5                 -- the slate: its middle across, its face

local TABLE
do
  local path, f = DIR .. "../../exhibit-table.lua"
  if setfenv then f = assert(loadfile(path)); setfenv(f, getfenv(1))
  else f = assert(loadfile(path, "t", _ENV)) end
  TABLE = f()
end
TABLE.build(40, 20, { x = 10, z = -1, floor = 300 })

local function still(call, col)
  local m = part(call, false)
  m.col = col
  v:add(m)
  m.trans = btTransform(ident, btVector3(0, 0, 0))
  return m
end
local O = {}                            -- the drawn parts, by name (for hover)
O.cover = still("cover()", "#2f3a40")
O.back = still("back()", "#4a3b2c")
O.footL = still("foot(-1)", "#6b4423")
O.footR = still("foot(1)", "#6b4423")
O.slate = still("slate()", "#22282a"); O.slate.trans = btTransform(ident, btVector3(SX, 0, SZ))
O.slateFrame = still("slateFrame()", "#6b4423"); O.slateFrame.trans = btTransform(ident, btVector3(SX, 0, SZ))

-- the cover's slots and channels, as a fixed body: boxes round them
local anchor = Cube(0.01, 0.01, 0.01, 0); anchor.collides = false; v:add(anchor)
anchor.trans = btTransform(ident, btVector3(0, 0, 0))
do
  local c = btCompoundShape(true)
  local function box(x0, x1, y0, y1)
    c:addChildShape(btTransform(ident, btVector3((x0 + x1) / 2, (y0 + y1) / 2, (G.COVER_Z0 + G.COVER_Z1) / 2)),
      btBoxShape(btVector3((x1 - x0) / 2, (y1 - y0) / 2, (G.COVER_Z1 - G.COVER_Z0) / 2)))
  end
  local h, xN, x1 = G.S / 2, colX(G.NCOL), colX(1)
  box(G.XL, xN - h, G.YCB, G.YCT)                       -- left of the last slot
  box(x1 + h, G.XR, G.YCB, G.YCT)                       -- right of the first
  box(xN - h, x1 + h, G.YT + h, G.YCT)                  -- above the top channel
  box(xN - h, x1 + h, G.YCB, G.Y0 - h)                  -- below the bottom one
  for j = 1, G.NCOL - 1 do box(colX(j + 1) + h, colX(j) - h, G.Y0 + h, G.YT - h) end   -- between the slots
  local o = Cube(0.01, 0.01, 0.01, 0); o.collides = false
  o.body = btRigidBody(0, btDefaultMotionState(btTransform(ident, btVector3(0, 0, 0))), c, btVector3(0, 0, 0))
  o.collides = true; v:add(o); o.trans = btTransform(ident, btVector3(0, 0, 0))
  G.coverBody = o.body
end

-- ---------------------------------------------------------------------
-- the bands: each a body on a slider (its pegs, and its body for the bar),
-- held by friction; reading 0 at the top, 9 at the bottom
-- ---------------------------------------------------------------------
local QY = qa(0, 0, 1, 90)              -- (a slider's axis is its frame's x: here up)
local BAND_M = 0.012                    -- kg (PLA)
local YMID = (G.YB + G.YBT) / 2         -- (a band's middle, reading 0: its body's origin)
local bands = {}
local function tile(w, h, x, y, z, picture, q)
  local c = Cube(w, h, 0.01, 0)
  c.collides = false
  c.tex = pic(picture)
  v:add(c)
  c.trans = btTransform(q or ident, btVector3(x, y, z))
  return c
end
for j = 1, G.NCOL do
  local x = colX(j)
  local c = btCompoundShape(true)
  for i = 0, G.NPEG - 1 do
    c:addChildShape(btTransform(ident, btVector3(0, G.Y0 + (i - 0.5) * G.P - YMID, (G.PEG_Z0 + G.PEG_Z1) / 2 - G.BODY_Z0 - 0.125)),
      btCylinderShapeZ(btVector3(G.RP, G.RP, (G.PEG_Z1 - G.PEG_Z0) / 2)))
  end
  local bx = (G.BAND_X0 + G.BAND_X1) / 2
  c:addChildShape(btTransform(ident, btVector3(bx, 0, 0)),
    btBoxShape(btVector3((G.BAND_X1 - G.BAND_X0) / 2, (G.YBT - G.YB) / 2, (G.BODY_Z1 - G.BODY_Z0) / 2)))
  -- (the body's origin: the band's middle, at its body's middle depth)
  local tr = btTransform(ident, btVector3(x, YMID, G.BODY_Z0 + 0.125))
  local o = part(string.format("translate([%g, %g, %g]) band()", 0, -YMID * 10, -(G.BODY_Z0 + 0.125) * 10), true)
  o.col = "#e8dcc0"
  o.body = btRigidBody(BAND_M, btDefaultMotionState(tr), c, btVector3(BAND_M * 3, BAND_M * 0.3, BAND_M * 3))
  o.collides = true
  v:add(o)
  o.trans = tr
  local b = o.body
  b:setCenterOfMassTransform(tr)
  b:setActivationState(4)
  b:setFriction(0.3)
  b:setRestitution(0)
  local sl = btSliderConstraint(anchor.body, b, btTransform(QY, btVector3(x, YMID, G.BODY_Z0 + 0.125)), btTransform(QY, btVector3(0, 0, 0)), true)
  sl:setLowerLinLimit(-G.TRAVEL); sl:setUpperLinLimit(0)
  sl:setLowerAngLimit(0); sl:setUpperAngLimit(0)
  sl:setPoweredLinMotor(true); sl:setTargetLinMotorVelocity(0); sl:setMaxLinMotorForce(v:getParam("friction"))
  v:addConstraint(sl)
  -- (riders: the red behind the gaps 10 and over, and the digits)
  local red = part(string.format("translate([%g, %g, 0]) bandRed()", 0, 0))
  red.col = "#c0392b"; v:add(red)
  local digits = tile(0.9, 8.0, x + G.DIGIT_X, G.YW + 4.5 * G.P, G.BODY_Z1 + 0.003, "band-digits")
  bands[j] = { obj = o, body = b, sl = sl, red = red, digits = digits, x = x }
end
pcall(function() v.showConstraints = false end)
local function bandPos(j) return -bands[j].sl:getLinearPos() / G.P end        -- 0 .. 9, a step a unit
local function bandRead(j) return math.floor(bandPos(j) + 0.5) % 10 end
local function placeRiders()
  for j, bd in ipairs(bands) do
    local dy = bd.sl:getLinearPos()
    bd.red.trans = btTransform(ident, btVector3(bd.x, dy, 0))
    bd.digits.trans = btTransform(ident, btVector3(bd.x + G.DIGIT_X, G.YW + 4.5 * G.P + dy, G.BODY_Z1 + 0.003))
  end
end
local function applyFriction()
  for _, bd in ipairs(bands) do bd.sl:setMaxLinMotorForce(v:getParam("friction")) end
end

-- the labels on the cover: beside each slot, the digits to add (right,
-- going up) and to subtract (left, going down)
for j = 1, G.NCOL do
  tile(0.5, 7.2, colX(j) + 0.55, G.Y0 + 4.0, G.COVER_Z1 + 0.003, "labels-add")
  tile(0.5, 7.2, colX(j) - 0.55, G.Y0 + 4.0, G.COVER_Z1 + 0.003, "labels-sub")
end
tile(12.4, 0.7, -0.1, G.YT + 0.75, G.COVER_Z1 + 0.003, "cover-top")
for j = 1, G.NCOL do tile(1.6, 0.4, colX(j) + G.DIGIT_X, G.YW - 0.65, G.COVER_Z1 + 0.003, "window-" .. j) end

-- ---------------------------------------------------------------------
-- the zeroing bar: a body on a slider under the bands' feet, lifted by
-- its tab (a motor: the hand)
-- ---------------------------------------------------------------------
local bar = {}
do
  local BAR_M = 0.02
  local x0, x1 = colX(G.NCOL) + G.BAND_X0, colX(1) + G.BAND_X1
  local tr = btTransform(ident, btVector3((x0 + x1) / 2, G.YBAR - 0.2, (G.BODY_Z0 + G.BODY_Z1) / 2))
  local shape = btBoxShape(btVector3((x1 - x0) / 2, 0.2, (G.BODY_Z1 - G.BODY_Z0) / 2))
  local o = part(string.format("translate([%g, %g, %g]) bar()", -(x0 + x1) / 2 * 10, -(G.YBAR - 0.2) * 10, -(G.BODY_Z0 + G.BODY_Z1) / 2 * 10), true)
  o.col = "#8a6d3b"
  o.body = btRigidBody(BAR_M, btDefaultMotionState(tr), shape, btVector3(BAR_M, BAR_M, BAR_M))
  o.collides = true
  v:add(o)
  o.trans = tr
  local b = o.body
  b:setCenterOfMassTransform(tr)
  b:setActivationState(4)
  local sl = btSliderConstraint(anchor.body, b, btTransform(QY, btVector3((x0 + x1) / 2, G.YBAR - 0.2, (G.BODY_Z0 + G.BODY_Z1) / 2)), btTransform(QY, btVector3(0, 0, 0)), true)
  sl:setLowerLinLimit(0); sl:setUpperLinLimit(G.YB - G.YBAR)
  sl:setLowerAngLimit(0); sl:setUpperAngLimit(0)
  -- (the hand on the tab: up to 10 N, enough for six bands at the friction slider's top, 6 x (60 + 12))
  sl:setPoweredLinMotor(true); sl:setTargetLinMotorVelocity(0); sl:setMaxLinMotorForce(1000)
  v:addConstraint(sl)
  bar.obj, bar.body, bar.sl = o, b, sl
  O.bar = o
end

-- ---------------------------------------------------------------------
-- the stylus: a body (a ball among the pegs, a ball in the slot), moved by
-- the hand's force toward where the hand means it to be
-- ---------------------------------------------------------------------
local ST = {}
do
  local SM = 0.05                       -- kg: the stylus with the hand's fingers on it
  local c = btCompoundShape(true)
  c:addChildShape(btTransform(ident, btVector3(0, 0, 0)), btSphereShape(0.15))
  c:addChildShape(btTransform(ident, btVector3(0, 0, 0.37)), btSphereShape(0.15))
  ST.rest = btVector3(colX(1) + 3.5, G.Y0 - 3, 4)
  local tr = btTransform(ident, ST.rest)
  local o = part("stylus()", true)
  o.col = "#c8c8c8"
  o.body = btRigidBody(SM, btDefaultMotionState(tr), c, btVector3(1, 1, 1))
  o.collides = true
  v:add(o)
  o.trans = tr
  local b = o.body
  b:setCenterOfMassTransform(tr)
  b:setActivationState(4)
  b:setAngularFactor(0)
  b:setGravity(btVector3(0, 0, 0))
  b:setFriction(0.3)
  ST.obj, ST.body, ST.m = o, b, SM
  ST.K = 1000                           -- the hand's stiffness, kg/s^2: 0.03 cm off for a band's friction
  ST.C = 2 * math.sqrt(ST.K * SM)
  ST.FMAX = envnum("SA_FORCE", 200)     -- kg cm/s^2: 2 N, a hand on a stylus
  ST.target = btVector3(ST.rest.x, ST.rest.y, ST.rest.z)
  O.stylus = o
end
local finger = part("finger()"); finger.col = "#e0b896"; v:add(finger)
local QFING = qa(1, 1, 0, 45)            -- (from the stylus's shank down to the right, toward you)
local function placeFinger()
  local p = ST.body:getCenterOfMassPosition()
  finger.trans = btTransform(QFING, btVector3(p.x + 0.45, p.y - 0.1, p.z + 1.9))
end
local function handForce()
  local p, vel, t = ST.body:getCenterOfMassPosition(), ST.body:getLinearVelocity(), ST.target
  local fx = ST.K * (t.x - p.x) - ST.C * vel.x
  local fy = ST.K * (t.y - p.y) - ST.C * vel.y
  local fz = ST.K * (t.z - p.z) - ST.C * vel.z
  local f = math.sqrt(fx * fx + fy * fy + fz * fz)
  if f > ST.FMAX then fx, fy, fz = fx * ST.FMAX / f, fy * ST.FMAX / f, fz * ST.FMAX / f end
  ST.body:applyCentralForce(btVector3(fx, fy, fz))
end

-- ---------------------------------------------------------------------
-- the slate (make-slate.py)
-- ---------------------------------------------------------------------
local slate = { a = {}, b = {} }
local SLZ = SZ + 0.03
slate.say = tile(16.6, 2.2, SX, 20.0, SLZ, "say-ready")
slate.labelA = tile(14.0, 0.75, SX - 1.0, 17.9, SLZ, "label-register")
slate.labelB = tile(14.0, 0.75, SX - 1.0, 13.4, SLZ, "label-typed")
for k = 1, G.NCOL do
  slate.a[k] = tile(1.6, 2.1, SX + 5.0 - (k - 1) * 2.0, 15.9, SLZ, "digit-0")
  slate.b[k] = tile(1.6, 2.1, SX + 5.0 - (k - 1) * 2.0, 11.4, SLZ, "digit-blank")
end
slate.sign = tile(1.6, 2.1, SX - 7.0, 11.4, SLZ, "digit-blank")
local shown = {}
local function show(t, picture) if shown[t] ~= picture then shown[t] = picture; t.tex = pic(picture) end end
local S = { entry = {}, op = nil, num = nil, result = nil, green = false }
local function sayIt(s) show(slate.say, "say-" .. s) end
local function showSlate()
  for k = 1, G.NCOL do
    show(slate.a[k], "digit-" .. bandRead(k) .. (S.green and "-green" or ""))
  end
  -- (the number being added or subtracted, else the one typed)
  local n, sign = S.num, S.op
  if not n and #S.entry > 0 then n, sign = table.concat(S.entry), nil end
  for k = 1, G.NCOL do
    local d = n and n:sub(-k, -k) or ""
    show(slate.b[k], d ~= "" and ("digit-" .. d) or "digit-blank")
  end
  show(slate.sign, sign == "+" and "digit-plus" or sign == "-" and "digit-minus" or "digit-blank")
  show(slate.labelB, sign == "+" and "label-adding" or sign == "-" and "label-subtracting" or "label-typed")
end

-- ---------------------------------------------------------------------
-- the operator: a coroutine that yields each move for the hand and is
-- resumed with how it went ("there", or "stopped" short of it)
-- ---------------------------------------------------------------------
local LOG = os.getenv("SA_LOG")
local PUSH = 0.1                        -- past a slot's end: the hand presses it home
local OVER = 0.06                       -- past one step, for the stylus's play between the pegs
local OUT, IN = 1.5, G.TIPZ
local function move(x, y, z, why) return coroutine.yield({ x = x, y = y, z = z, why = why }) end
local function here() local t = ST.target; return t.x, t.y, t.z end
local function lift() local x, y = here(); move(x, y, OUT, "lift") end
local function insert(j, y)
  local x, yy, z = here()
  if z < OUT - 0.01 then lift() end
  move(colX(j), y, OUT, "over")
  return move(colX(j), y, IN, "in")
end
local function sayNow(s) coroutine.yield({ say = s }) end
local OPS = {}
-- a carry into column k: along the top channel, one step down; if the band
-- there is at 9 it won't go: add one there, and carry on
function OPS.carryInto(k)
  if k > G.NCOL then
    local x, y = here()
    move(colX(G.NCOL) - G.W, y, IN, "past the last column")
    sayNow("full")
    S.full = true
    lift()
    return
  end
  local x, y = here()
  move(colX(k), y, IN, "along the top")
  local r = move(colX(k), G.YT - G.P - OVER, IN, "one down")
  if r == "stopped" then
    sayNow("chain")
    lift()
    insert(k, G.Y0 + G.P)
    move(colX(k), G.YT + PUSH, IN, "up")
    return OPS.carryInto(k + 1)
  end
  lift()
end
-- a borrow from column k: along the bottom channel, one step up; if the
-- band there is at 0 it won't go: take one there, and borrow on
function OPS.borrowFrom(k)
  if k > G.NCOL then
    local x, y = here()
    move(colX(G.NCOL) - G.W, y, IN, "past the last column")
    sayNow("negative")
    S.negative = true
    lift()
    return
  end
  local x, y = here()
  move(colX(k), y, IN, "along the bottom")
  local r = move(colX(k), G.Y0 + G.P + OVER, IN, "one up")
  if r == "stopped" then
    sayNow("chain-borrow")
    lift()
    insert(k, G.Y0 + 9 * G.P)
    move(colX(k), G.Y0 - PUSH, IN, "down")
    return OPS.borrowFrom(k + 1)
  end
  lift()
end
function OPS.addDigit(j, d)
  if d == 0 then return end
  local red = bandRead(j) + d >= 10               -- (the gap beside the d is red)
  insert(j, G.Y0 + d * G.P)
  if not red then
    sayNow("adding")
    move(colX(j), G.Y0 - PUSH, IN, "down")
    lift()
  else
    sayNow("carry")
    move(colX(j), G.YT + PUSH, IN, "up")
    OPS.carryInto(j + 1)
  end
end
function OPS.subDigit(j, d)
  if d == 0 then return end
  local red = bandRead(j) - d >= 0                -- (the gap beside the d, on the left, is red)
  insert(j, G.Y0 + (10 - d) * G.P)
  if red then
    sayNow("subtracting")
    move(colX(j), G.YT + PUSH, IN, "up")
    lift()
  else
    sayNow("borrow")
    move(colX(j), G.Y0 - PUSH, IN, "down")
    OPS.borrowFrom(j + 1)
  end
end
local function operate(op, n)
  local s = tostring(n)
  for k = 1, #s do
    local d = tonumber(s:sub(-k, -k))
    if op == "+" then OPS.addDigit(k, d) else OPS.subDigit(k, d) end
  end
  move(ST.rest.x, ST.rest.y, ST.rest.z, "home")
end

-- ---------------------------------------------------------------------
-- the jobs: a queue of steps, one at a time
-- ---------------------------------------------------------------------
local queue, job = {}, nil
local function idle() return job == nil and #queue == 0 end
local function startJob(q)
  job = { q = q, t = 0 }
  if q.say then sayIt(q.say) end
end
local function readRegister()
  local n = 0
  for j = G.NCOL, 1, -1 do n = n * 10 + bandRead(j) end
  return n
end
local MOD = 10 ^ G.NCOL
local function stepJob(dt)
  if not job then
    if #queue == 0 then return end
    startJob(table.remove(queue, 1))
  end
  local q = job.q
  job.t = job.t + dt
  if q.wait then
    if job.t >= q.wait then job = nil end
  elseif q.zero then
    -- the bar up under every foot, until it can go no higher; then down
    local pos = bar.sl:getLinearPos()
    if not job.down then
      bar.sl:setTargetLinMotorVelocity(6)
      if pos >= G.YB - G.YBAR - 0.02 or job.t > 6 then job.down = true end
    else
      bar.sl:setTargetLinMotorVelocity(-6)
      if pos <= 0.02 or job.t > 12 then bar.sl:setTargetLinMotorVelocity(0); job = nil end
    end
  elseif q.operate then
    -- the operator's coroutine, and the hand carrying out each move
    if not job.co then
      job.co = coroutine.create(function() operate(q.op, q.n) end)
      S.op, S.num, S.full, S.negative = q.op, tostring(q.n), false, false
      job.res = nil
    end
    if not job.mv then
      local ok, m = coroutine.resume(job.co, job.res)
      if not ok then print("THE SLIDE ADDER: " .. tostring(m)); job = nil; return end
      if coroutine.status(job.co) == "dead" then
        S.num, S.op = nil, nil
        job = nil
        return
      end
      if m.say then sayIt(m.say); job.res = nil; job.pause = 0.25; return end
      local t = ST.target
      job.mv = m
      job.from = btVector3(t.x, t.y, t.z)
      job.mt, job.still = 0, 0
    end
    if job.pause then
      job.pause = job.pause - dt
      if job.pause > 0 then return end
      job.pause = nil
    end
    local m, f = job.mv, job.from
    local dx, dy, dz = m.x - f.x, m.y - f.y, m.z - f.z
    local L = math.sqrt(dx * dx + dy * dy + dz * dz)
    local speed = v:getParam("hand") * ((m.z > 0.5 and f.z > 0.5) and 2 or 1)   -- (quicker in the air)
    job.mt = job.mt + dt
    local u = L > 0 and math.min(1, job.mt * speed / L) or 1
    ST.target = btVector3(f.x + dx * u, f.y + dy * u, f.z + dz * u)
    if u >= 1 then
      local p, vel = ST.body:getCenterOfMassPosition(), ST.body:getLinearVelocity()
      local e = math.sqrt((m.x - p.x) ^ 2 + (m.y - p.y) ^ 2 + (m.z - p.z) ^ 2)
      job.still = vel:length() < 0.3 and job.still + dt or 0
      if e < 0.15 or job.still > 0.15 then
        local res = e < 0.15 and "there" or "stopped"
        if res == "stopped" then
          -- (the hand feels it won't go, and eases off where it stopped)
          ST.target = btVector3(p.x, p.y, p.z)
          if LOG then print(string.format("  the stylus stops %.2f cm short (%s)", e, m.why or "")) end
        end
        job.res, job.mv = res, nil
      end
    end
  elseif q.read then
    local got = readRegister()
    local want = q.want % MOD
    local ok = got == want
    for j = 1, G.NCOL do
      local p = bandPos(j)
      if math.abs(p - math.floor(p + 0.5)) > 0.25 then ok = false end
    end
    S.result = ok
    S.green = ok
    local says
    if q.want < 0 then says = string.format("%d (the windows show %06d: %d less than nothing)", q.want, got, -q.want)
    else says = string.format("%d", q.want) end
    print(string.format("  %s = %s; the windows read %06d (%s)", q.text, says, got, ok and "right" or "WRONG"))
    if LOG then
      local s = {}
      for j = G.NCOL, 1, -1 do s[#s + 1] = string.format("%.3f", bandPos(j)) end
      print("    the bands: " .. table.concat(s, " "))
    end
    sayIt(ok and (q.want < 0 and "negative-done" or "done") or "wrong")
    job = nil
  elseif q.call then
    q.call()
    job = nil
  else
    job = nil
  end
end

-- a sum: the bar first (every band to 0), then each number in turn
local function sumOf(list)
  local total, text = 0, {}
  for i, it in ipairs(list) do
    total = total + (it.op == "-" and -it.n or it.n)
    text[#text + 1] = (i == 1 and "" or (it.op .. " ")) .. it.n
  end
  return total, table.concat(text, " ")
end
local function queueZero()
  queue[#queue + 1] = { call = function() S.green = false end }
  queue[#queue + 1] = { say = "zeroing", zero = true }
end
local function queueOp(op, n)
  queue[#queue + 1] = { call = function() S.green = false end }
  queue[#queue + 1] = { operate = true, op = op, n = n }
end
local function queueSum(list)
  queueZero()
  for i, it in ipairs(list) do
    if i == 1 and WAY == "subtract" then queue[#queue + 1] = { say = "entering", wait = 0.6 } end
    queueOp(it.op, it.n)
  end
  local total, text = sumOf(list)
  queue[#queue + 1] = { read = true, want = total, text = text }
end
local function parseSum(s)
  local list = {}
  for op, n in ("+" .. s):gmatch("([%+%-])%s*(%d+)") do list[#list + 1] = { op = op, n = tonumber(n) % MOD } end
  return list
end

-- ---------------------------------------------------------------------
-- the tour
-- ---------------------------------------------------------------------
local TOUR = WAY == "add" and {
  "47295 + 85358",                   -- carries in three columns
  "99999 + 1",                       -- one carry that runs through five nines
  "1889 + 2026",                     -- (Troncet's year, and this one's)
} or {
  "132653 - 85358",                  -- borrows in three columns
  "100000 - 1",                      -- one borrow that runs through five noughts
  "853 - 4729",                      -- less than nothing: the windows show 1000000 less it
}
do
  local n = envnum("SA_RANDOM", 0)
  if n > 0 then
    math.randomseed(envnum("SA_SEED", 1))
    for i = 1, n do
      local a, b = math.random(0, 99999), math.random(0, 99999)
      if WAY == "add" then TOUR[#TOUR + 1] = a .. " + " .. b
      else TOUR[#TOUR + 1] = (a + b) .. " - " .. b end
    end
  end
end
local touring, fails = nil, 0
local function tourStart()
  touring, fails = 1, 0
  print(string.format("\nTHE SLIDE ADDER (%s) -- the tour: %d sums, from 0 each time", WAY, #TOUR))
end
local function tourNext()
  if not touring or not idle() then return end
  if touring > 1 and S.result ~= true then fails = fails + 1 end
  if touring > #TOUR then
    touring = nil
    print("RESULT slide adder " .. WAY .. " tour: " .. (fails == 0 and "PASS" or "FAIL")
          .. string.format("  (%d sums, %d wrong; frame %d)", #TOUR, fails, G.frame or 0))
    return
  end
  local t = TOUR[touring]
  touring = touring + 1
  S.result = nil
  queue[#queue + 1] = { wait = touring == 2 and 0.3 or 1.5 }
  queueSum(parseSum(t))
end

-- ---------------------------------------------------------------------
-- stepping: the hand's force on the stylus each step; resting when idle
-- ---------------------------------------------------------------------
local REST_ON = os.getenv("SA_REST") ~= "0"
local restFor, resting = 0, false
local function moving()
  if ST.body:getLinearVelocity():length() > 0.05 then return true end
  for _, bd in ipairs(bands) do if bd.body:getLinearVelocity():length() > 0.05 then return true end end
  return bar.body:getLinearVelocity():length() > 0.05
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
  for k = 1, NSTEPS - 1 do handForce(); v:stepSimulation(STEP, 0, STEP) end
  handForce()
end)
local started = false
v:postSim(function(N)
  G.frame = N
  placeRiders()
  placeFinger()
  if holdNow then return end
  if not started then
    started = true
    local s = os.getenv("SA_NUMS")
    if s and s:match("%d") then
      local list = parseSum(s)
      if #list > 0 then queueSum(list) end
    end
    if (os.getenv("SA_TOUR") or "1") ~= "0" then tourStart() end
  end
  stepJob(FRAME_DT)
  showSlate()
  tourNext()
  restPost()
end)

-- ---------------------------------------------------------------------
-- keys, help, hover
-- ---------------------------------------------------------------------
local function typed(d)
  touring = nil
  if #S.entry < G.NCOL and not (#S.entry == 0 and d == 0) then S.entry[#S.entry + 1] = d end
  S.green = false
  sayIt("ready")
end
for d = 0, 9 do v:addShortcut(tostring(d), function() typed(d) end) end
local function doOp(op)
  touring = nil
  if #S.entry == 0 then return end
  local n = tonumber(table.concat(S.entry))
  S.entry = {}
  queueOp(op, n)
  queue[#queue + 1] = { call = function() sayIt("ready") end }
end
local function enter() doOp(WAY == "add" and "+" or "-") end
v:addShortcut("Return", enter)
v:addShortcut("Enter", enter)
for _, k in ipairs({ "+", "Plus", "=" }) do pcall(function() v:addShortcut(k, function() doOp("+") end) end) end
for _, k in ipairs({ "-", "Minus" }) do pcall(function() v:addShortcut(k, function() doOp("-") end) end) end
v:addShortcut("Backspace", function() S.entry[#S.entry] = nil end)
v:addShortcut("C", function()
  touring = nil
  S.entry = {}
  queueZero()
  queue[#queue + 1] = { call = function() sayIt("ready") end }
end)
v:addShortcut("R", function()
  touring = nil
  S.entry = {}
  queueOp(WAY == "add" and "+" or "-", math.random(1, 99999))
  queue[#queue + 1] = { call = function() sayIt("ready") end }
end)
v:addShortcut("T", function() tourStart() end)
if not hallPath then
  local MANUAL = dofile(DIR .. "../../open-manual.lua")
  for _, k in ipairs({ "H", "F1" }) do v:addShortcut(k, function() MANUAL.open(DIR, "the slide adder's manual") end) end
end
v:onParamChanged(function(N, name, value)
  if name == "speed" then applyTiming()
  elseif name == "friction" then applyFriction() end
end)
pcall(function()
  v:setHelpText(table.concat({
    "THE SLIDE ADDER  (Troncet's arithmographe, 1889; the Addiator, 1920)" .. (WAY == "subtract" and ": subtracting" or ""),
    "",
    "KEYS",
    "  0 - 9   a number (up to six figures)",
    "  Return  " .. (WAY == "add" and "add it" or "subtract it") .. "     + add it     - subtract it",
    "  C       the bar: every band to 0     R  a number at random     T  the tour",
    "",
    "Each column is a band with pegs a step apart and the digits 0 to 9; its",
    "window shows one. To add d: the stylus between the pegs beside the d, down",
    "to the bottom of the slot; the band goes down d steps. If that gap is red,",
    "push it up to the top instead (10 - d steps up: d more, less ten), then",
    "round the hook into the next column and one step down: the carry. If that",
    "column shows 9 it won't go down: add one there, and carry on.",
    "Subtracting: the digits on the slot's left, up to the top; where the gap",
    "isn't red, down to the bottom and round the bottom hook, one step up: borrow.",
    "",
    "The bands, the stylus and the zeroing bar are bodies; the stylus moves a",
    "band only by its pegs, and a carry gets over only along the channel. The",
    "operator (the script) reads the windows, makes the moves a person would,",
    "and feels when the stylus will go no further. The slate is the script's.",
    "",
    "H: the manual (MANUAL.pdf, in your PDF viewer).",
  }, "\n"))
end)
if v.onHover then
  local KEY = {}
  if objectKey then
    KEY[objectKey(O.cover)] = "the cover: a slot over each band's pegs, joined at the top and the bottom by the hooks' channels; a window for each column"
    KEY[objectKey(O.back)] = "the back, with a rib between each band and the next"
    KEY[objectKey(O.bar)] = "the zeroing bar: lifted by its tab, it puts every band to 0 (C)"
    KEY[objectKey(O.stylus)] = "the stylus: its tip goes between two pegs and takes the band with it"
    KEY[objectKey(finger)] = "the operator's hand (the script's): it reads the windows and makes the moves"
    KEY[objectKey(O.slate)] = "the slate: what the windows read, the number being added or subtracted, and what the hand is doing (the script's)"
    KEY[objectKey(O.footL)] = "a foot: the adder stands upright"
    KEY[objectKey(O.footR)] = "a foot: the adder stands upright"
    for j, bd in ipairs(bands) do
      KEY[objectKey(bd.obj)] = j
      KEY[objectKey(bd.digits)] = j
      KEY[objectKey(bd.red)] = j
    end
  end
  local NAMES = { "units", "tens", "hundreds", "thousands", "ten thousands", "hundred thousands" }
  v:onHover(function(N, obj, x, y, z)
    local k = objectKey and objectKey(obj)
    local s = k and KEY[k]
    if type(s) == "number" then
      return string.format("the %s' band: it reads %d (%.2f steps down from 0); its gaps 10 and over are red", NAMES[s], bandRead(s), bandPos(s))
    end
    return s
  end)
end

common.setCamera(btVector3(6, 18, 33), btVector3(6, 14.5, -1))
showSlate()
holdStart()
