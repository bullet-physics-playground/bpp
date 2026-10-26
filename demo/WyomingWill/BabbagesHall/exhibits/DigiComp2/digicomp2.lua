--
-- The Digi-Comp II -- Babbage's Hall (step 1: the counter)
--
-- E.S.R.'s Digi-Comp II (1968) was a computer of marbles: a sloping board
-- of plastic flip-flops that balls roll down, one at a time, and that count,
-- add and multiply in binary. This is its heart, the counter: three
-- flip-flops down a staircase, and a feeder that lets the balls in one at a
-- time. Turn the feeder's knob a quarter turn (Space) and a ball rolls down;
-- the three flip-flops then read how many have come, from 0 to 7, in binary.
--
-- THE FLIP-FLOP is a rocker on a pin, printed in one piece: a roof with a
-- cup at each end, its centre of mass a little up the slope from the pin, so
-- it falls over to one side or the other and stays there, its tail on a stop
-- peg. A ball rolling straight down meets the roof on its raised side, rolls
-- into that cup, and its weight takes the rocker over to the other side; at
-- the end of the swing the cup tips it out. The next ball meets the other
-- side. Nothing else holds it or turns it: its shape and its weight alone.
--   Leaning with its apex to the right, it reads 1; to the left, 0.
--   A ball that finds it at 0 sets it to 1 and goes right, into its bin:
--   done. One that finds it at 1 sets it to 0 and goes left, down to the next
--   flip-flop: the carry. So each ball adds one, carrying as far as it must.
--   The eighth ball carries out of the last one, into the overflow, and all
--   three read 0 again.
--
-- KEYS
--   Space  turn the feeder's knob a quarter turn: one ball
--   T      the tour: from 0, eight balls, one at a time (it starts with it)
--   R      set it back: the balls to the top, the flip-flops to 0 (by hand)
--   Z      slow motion (1/4) <-> real time
--
-- EVERY PART CAN BE PRINTED: see parts/ and README.md. What is printed is
-- what is simulated: the walls, pegs, rockers and wheel are the shapes in
-- digicomp2-geometry.lua, from which parts/geometry.scad is written.
--
-- PHYSICS: 1/2 inch steel balls (8.35 g), PLA rockers (2.5 g, and a 1/4
-- inch steel ball pressed into each: 3.6 g), friction 0.3, no bounce, the
-- board at 15 degrees, 2400 steps a second. The rockers turn on their pins
-- against a friction torque (DC_PF, 0.4 kg cm^2/s^2: see FINDINGS.md). The
-- feeder's knob is turned by the hand (a motor: the operator's).
--
-- Units: centimetres, kilograms, seconds.
-- Headless: DC_TOUR=0 (no tour), DC_FRICTION, DC_PF (pivot friction,
-- kg cm^2/s^2), DC_TH (the slope, degrees), DC_HZ (steps a second),
-- DC_BALLS (balls in the tour), DC_ROLL (degrees: the table not level
-- across, down to the right), DC_HAND (the hand's torque), DC_EXPORT=1 (write parts/geometry.scad),
-- DC_LOG=1 (the rockers' leans at each reading), DC_LOG=2 (also every
-- ball's place four times a second), DC_CONTACTS=frame (every contact of
-- the balls and the wheel at that frame: what jams), DC_PAUSE (s between a
-- reading and the next ball in the tour, 1).
--

local common = require "common"
local function envnum(n, d) return tonumber(os.getenv(n) or "") or d end

-- ---------------------------------------------------------------------
-- this exhibit's folder, its geometry and its parts file
-- ---------------------------------------------------------------------
local DIR
for _, d in ipairs({ "", "demo/WyomingWill/BabbagesHall/exhibits/DigiComp2/" }) do
  local f = io.open(d .. "digicomp2-geometry.lua", "r")
  if f then f:close(); DIR = d; break end
end
assert(DIR, "Digi-Comp II: can't find its folder")
local G = dofile(DIR .. "digicomp2-geometry.lua")
if os.getenv("DC_TH") then G.TH = envnum("DC_TH", G.TH) end
local F, WH = G.FLIP, G.WHEEL
do
  local path = DIR .. "parts/geometry.scad"
  local f = io.open(path, "r")
  if f then f:close() end
  if not f or os.getenv("DC_EXPORT") then G.writeScad(path); print("DIGI-COMP II: wrote " .. path) end
end

local SCAD
do
  local path = DIR .. "parts/digicomp2.scad"
  if hallPath then path = hallPath(path) end
  if path:sub(1, 1) ~= "/" and not path:match("^%a:[/\\]") then
    -- (the folder bpp is really in: it may have moved into the script's own,
    -- which $PWD doesn't know)
    local cwd
    local p = io.popen and io.popen("cd")
    if p then cwd = p:read("*l"); p:close() end
    if not cwd or cwd == "" or not (cwd:sub(1, 1) == "/" or cwd:match("^%a:")) then
      p = io.popen and io.popen("pwd")
      if p then cwd = p:read("*l"); p:close() end
    end
    path = (cwd or os.getenv("PWD") or ".") .. "/" .. path
  end
  local f = io.open(path, "r")
  assert(f, "Digi-Comp II: can't find its parts file at " .. path)
  f:close()
  SCAD = path
end
-- (bpp keeps each OpenSCAD part by the text asked for, not by what the files
-- say: a checksum of them in the text makes a changed file count as new)
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
local SCAD_SUM = checksum({ SCAD, (SCAD:gsub("digicomp2%.scad$", "geometry.scad")) })
local function part(call)
  local m = OpenSCAD("// " .. SCAD_SUM .. "\ninclude <" .. SCAD .. ">\nscale(0.1) " .. call .. ";\n", 0, false)
  m.collides = false
  return m
end

-- ---------------------------------------------------------------------
-- sliders, timing, the pause at every start
-- ---------------------------------------------------------------------
local G_ = 981
v:addParam("friction", envnum("DC_FRICTION", 0.3), 0.1, 0.6, 0.05, "ball on wall, rocker and board (0.1 to 0.6 checked)")
v:addParam("speed", 1, 0.05, 2, 0.05, "simulated seconds per real second (Z: 1/4 <-> 1)")
v:addParam("steps", envnum("DC_HZ", 2400), 1200, 4800, 600, "physics steps per simulated second")

local STEP, NSTEPS, FRAME_DT = 1 / 2400, 40, 1 / 60
local function applyTiming()
  local speed = v:getParam("speed")
  NSTEPS = math.max(1, math.floor(v:getParam("steps") * speed / 60 + 0.5))
  FRAME_DT = speed / 60
  STEP = FRAME_DT / NSTEPS
  v.animationPeriod = 16
  common.setTiming(STEP, 0, STEP)
end
-- (as in Euler's Gallery: everything stands still for HOLD_S seconds when it
-- starts, so you see how it begins; the physics is stopped too)
local HOLD_FRAMES = math.floor(envnum("HOLD_S", 0.5) * 60 + 0.5)
local holdArm, holdLeft, holdNow = false, 0, false
local function holdStart() holdArm, holdLeft = true, 0 end
local function holdPre()
  if holdLeft > 0 then
    holdLeft = holdLeft - 1
    holdNow = true
    v.timeStep = 0
    return true
  end
  if holdNow then holdNow = false; applyTiming() end
  if holdArm then holdArm, holdLeft = false, HOLD_FRAMES end
  return false
end
applyTiming()
-- (DC_ROLL: the table not level across, by that many degrees: down to the right)
do
  local r = math.rad(envnum("DC_ROLL", 0))
  v.gravity = btVector3(G_ * math.sin(r), -G_ * math.cos(r), 0)
end

-- ---------------------------------------------------------------------
-- the board's frame in the exhibit's world, and the table
-- ---------------------------------------------------------------------
local ident = btQuaternion(0, 0, 0, 1)
local TH = math.rad(G.TH)
local cT, sT = math.cos(TH), math.sin(TH)
local BQ = btQuaternion(btVector3(1, 0, 0), TH)
local B = G.board
local BACK, FOOT = G.BACK, G.FOOT                 -- the backing sheet; the front edge's height
local OX = -(B.x0 + B.x1) / 2
local OY = FOOT + (G.BOARD_T + BACK) * cT + B.z1 * sT
local OZ = -(B.z0 + B.z1) / 2 * cT
-- board (x, y, z) -> the exhibit's world, and back
local function W3(x, y, z) return btVector3(OX + x, OY + y * cT - z * sT, OZ + y * sT + z * cT) end
local function L3(p)
  local x, y, z = p.x - OX, p.y - OY, p.z - OZ
  return x, y * cT + z * sT, -y * sT + z * cT
end
local function yq(psi) return BQ * btQuaternion(btVector3(0, 1, 0), psi) end
local zToY = btQuaternion(btVector3(1, 0, 0), -math.pi / 2)

local TABLE
do
  -- (into this exhibit's own environment: Lua 5.1 sets it after loading,
  -- 5.2 and later give it to loadfile)
  local path, f = DIR .. "../../exhibit-table.lua"
  if setfenv then f = assert(loadfile(path)); setfenv(f, getfenv(1))
  else f = assert(loadfile(path, "t", _ENV)) end
  TABLE = f()
end
local BW, BD = B.x1 - B.x0, (B.z1 - B.z0) * cT
local top = TABLE.build(BW, BD, { floor = 300 })

-- ---------------------------------------------------------------------
-- the board, its walls and pegs (fixed): the board drawn as printed, the
-- walls and pegs as the simple shapes they are
-- ---------------------------------------------------------------------
local KEY = {}
local fixed = {}
local function key(obj, what) if objectKey then KEY[objectKey(obj)] = what end end
local boardBox = Cube(BW, G.BOARD_T, B.z1 - B.z0, 0)
boardBox.trans = btTransform(BQ, W3((B.x0 + B.x1) / 2, -G.BOARD_T / 2, (B.z0 + B.z1) / 2))
boardBox.col = "#1f3b4d"
v:add(boardBox)
fixed[#fixed + 1] = boardBox
key(boardBox, "the board: printed in tiles, glued to a backing sheet, sloping at " .. G.TH .. " degrees")
local backing = Cube(BW, BACK, B.z1 - B.z0, 0)
backing.collides = false
backing.col = "#7a5a3a"
v:add(backing)
backing.trans = btTransform(BQ, W3((B.x0 + B.x1) / 2, -G.BOARD_T - BACK / 2, (B.z0 + B.z1) / 2))
-- (the stand: two side frames under the board, drawn only)
local stand = part("stand()")
stand.col = "#7a5a3a"
v:add(stand)
stand.trans = btTransform(BQ, W3(0, 0, 0))

local WALL_COL = { lane = "#c9a14a", bins = "#c9a14a", housing = "#9b1c1c", queue = "#9b1c1c", rim = "#7a5a3a" }
local ROLE_TEXT = {
  lane = "a lane: a ball that set its flip-flop to 1 rolls down it to the bins",
  bins = "the bins: every ball ends here",
  housing = "the feeder's housing: it holds the balls in the wheel's notches",
  queue = "the channel of balls waiting at the feeder",
  rim = "the board's rim",
}
for _, w in ipairs(G.walls) do
  local dx, dz = w[3] - w[1], w[4] - w[2]
  local len = math.sqrt(dx * dx + dz * dz) + G.WALL_T
  local c = Cube(len, G.WALL_H, G.WALL_T, 0)
  c.trans = btTransform(yq(math.atan2(-dz, dx)), W3((w[1] + w[3]) / 2, G.WALL_H / 2, (w[2] + w[4]) / 2))
  c.col = WALL_COL[w.role] or "#d9d4c5"
  v:add(c)
  fixed[#fixed + 1] = c
  key(c, ROLE_TEXT[w.role] or "a channel: it brings the ball straight down onto the flip-flop's apex")
end
for _, p in ipairs(G.pegs) do
  local c = Cylinder(p[3], G.WALL_H, 0)               -- (bpp's Cylinder: along z; stood up)
  c.trans = btTransform(BQ * zToY, W3(p[1], G.WALL_H / 2, p[2]))
  c.col = "#9a9da3"
  v:add(c)
  fixed[#fixed + 1] = c
  key(c, "a stop peg: the flip-flop's tail rests on it")
end
-- the lettering on the board: each flip-flop's 0 and 1, and what it counts
local marks = part("boardMarks()")
marks.col = "#efe6cf"
v:add(marks)
marks.trans = btTransform(BQ, W3(0, 0, 0))

-- the sign beside it, the exhibit's (not the machine's): how many balls
-- have been let in, and what the flip-flops read. The machine shows the
-- count by its rockers' lean; the script reads them for the sign.
local sign
do
  local SX, SZ, TILT = -(BW / 2 + 13), BD / 2 - 22, math.rad(-25)
  local q = btQuaternion(btVector3(1, 0, 0), TILT)
  local SW, SH = 17, 10
  local back = Cube(SW, SH, 0.8, 0)
  back.col = "#1d1712"
  v:add(back)
  local up = btVector3(0, math.cos(TILT), math.sin(TILT))      -- (the sign's own up, leaning back)
  local function at(u, w, d)                                    -- (across, up, out of its face)
    return btVector3(SX + u, SH / 2 + 2 + up.y * w, SZ + up.z * w + d * math.cos(TILT))
  end
  back.trans = btTransform(q, at(0, 0, 0))
  local post = Cube(2, 4, 2, 0)
  post.col = "#2b2b2b"; post.collides = false
  v:add(post)
  post.trans = btTransform(ident, btVector3(SX, 2, SZ))
  key(back, "the exhibit's sign, not the machine's: the script reads the rockers for it")
  local function line(t, size)
    local m = part(string.format('signText("%s", %d)', t, size))
    m.col = "#efe6cf"
    v:add(m)
    return m
  end
  local head = line("THE COUNT", 11)
  head.trans = btTransform(q, at(-SW / 2 + 1.2, 3.0, 0.45))
  local balls, reads = {}, {}
  for n = 0, 8 do balls[n] = line("balls let in: " .. n, 9) end
  for n = 0, 7 do
    local b = ""
    for k = 2, 0, -1 do b = b .. math.floor(n / 2 ^ k) % 2 end
    reads[n] = line("reads " .. b .. " = " .. n, 9)
  end
  local AWAY = btTransform(ident, btVector3(0, -500, 0))
  for n = 0, 8 do balls[n].trans = AWAY end
  for n = 0, 7 do reads[n].trans = AWAY end
  local shown = {}
  sign = function(nBalls, nRead)
    nBalls = math.min(nBalls, 8)
    if shown.b ~= nBalls then
      if shown.b then balls[shown.b].trans = AWAY end
      balls[nBalls].trans = btTransform(q, at(-SW / 2 + 1.2, 0, 0.45)); shown.b = nBalls
    end
    if shown.r ~= nRead then
      if shown.r then reads[shown.r].trans = AWAY end
      reads[nRead].trans = btTransform(q, at(-SW / 2 + 1.2, -2.8, 0.45)); shown.r = nRead
    end
  end
end

local anchor = Cube(0.01, 0.01, 0.01, 0)          -- (only for the hinges to hold to: too small to see)
anchor.collides = false
v:add(anchor)
anchor.trans = btTransform(ident, btVector3(0, 0, 0))

-- ---------------------------------------------------------------------
-- the flip-flops: each a compound of its convex pieces on a hinge (its pin)
-- ---------------------------------------------------------------------
local PF = envnum("DC_PF", 0.4)        -- the pin's friction (kg cm^2/s^2): see FINDINGS
local flips = {}
local yc = F.Y0 + F.H / 2
-- a body's shape: its convex pieces { {x, z}, ... }, h high, about (cx, cz)
local function piecesShape(pieces, h, cx, cz)
  local s = btCompoundShape(true)
  for _, pc in ipairs(pieces) do
    local hs = btConvexHullShape()
    for _, p in ipairs(pc) do
      hs:addPoint(btVector3(p[1] - cx, -h / 2, p[2] - cz), false)
      hs:addPoint(btVector3(p[1] - cx, h / 2, p[2] - cz), false)
    end
    hs:recalcLocalAabb()
    hs:setMargin(0.005)
    s:addChildShape(btTransform(ident, btVector3(0, 0, 0)), hs)
  end
  return s
end
local function flipShape() return piecesShape(F.pieces, F.H, F.cx, F.cz) end
-- a rocker's pose, turned phi (right-handed about the board's normal) on its pin
local function flipPose(t, phi)
  local c, s = math.cos(phi), math.sin(phi)
  local x, z = c * F.cx + s * F.cz, -s * F.cx + c * F.cz
  return btTransform(yq(phi), W3(t.x + x, yc, t.z + z))
end
local LEAN0 = math.rad(F.ALPHA - 0.3)              -- (set by hand: just short of its stop, then it settles)
for k, t in ipairs(G.toggles) do
  local tr = flipPose(t, LEAN0)
  local body = btRigidBody(F.mass, btDefaultMotionState(tr), flipShape(), btVector3(F.I, F.I, F.I))
  local o = part(string.format("translate([%.4f, 0, %.4f]) translate([0, %.4f, 0]) rocker()", -F.cx * 10, -F.cz * 10, -yc * 10))
  o.body = body
  o.col = "#f4ecd6"
  o.collides = true
  v:add(o)
  body:setCenterOfMassTransform(tr)
  body:setActivationState(4)
  local h = btHingeConstraint(anchor.body, body, btTransform(BQ * zToY, W3(t.x, yc, t.z)),
                              btTransform(zToY, btVector3(-F.cx, 0, -F.cz)))
  v:addConstraint(h)
  if PF > 0 then h:enableAngularMotor(true, 0, PF * STEP) end
  local wt = part(string.format("translate([%.4f, 0, %.4f]) translate([0, %.4f, 0]) rockerWeight()", -F.cx * 10, -F.cz * 10, -yc * 10))
  wt.col = "#9a9da3"
  v:add(wt)
  flips[k] = { t = t, body = body, hinge = h, obj = o, weight = 2 ^ (k - 1), wt = wt }
  -- its pin (drawn only: the hinge is the pin)
  local pin = Cylinder(F.PIN_R, F.Y0 + F.H + 0.1, 0)
  pin.collides = false
  pin.col = "#b8bcc2"
  v:add(pin)
  pin.trans = btTransform(BQ * zToY, W3(t.x, (F.Y0 + F.H + 0.1) / 2, t.z))
  key(o, { flip = k })
end
local function bit(k)
  -- (1: its apex to the right, a clockwise lean as you look)
  local tr = flips[k].body:getCenterOfMassTransform()
  local a = tr:getBasis():getColumn(0)           -- its x axis, in the world
  -- its x axis's z in the board's frame: positive when it leans clockwise
  local bx = a.x
  local bz = -a.y * sT + a.z * cT
  return bz > 0 and 1 or 0, math.deg(math.atan2(bz, bx))
end
local function count()
  local n = 0
  for k = 1, G.NBITS do n = n + bit(k) * flips[k].weight end
  return n
end
local function bits()
  local s = ""
  for k = G.NBITS, 1, -1 do s = s .. bit(k) end
  return s
end

-- ---------------------------------------------------------------------
-- the feeder: a wheel of four notches on a pin, turned by the knob
-- ---------------------------------------------------------------------
local wheel
do
  local wy = WH.Y0 + WH.H / 2
  local s = piecesShape(WH.pieces, WH.H, 0, 0)
  local tr = btTransform(BQ, W3(WH.x, wy, WH.z))
  local body = btRigidBody(WH.mass, btDefaultMotionState(tr), s, btVector3(WH.I, WH.I, WH.I))
  local o = part(string.format("translate([0, %.4f, 0]) wheel()", -wy * 10))
  o.body = body
  o.col = "#c9a14a"
  o.collides = true
  v:add(o)
  body:setCenterOfMassTransform(tr)
  body:setActivationState(4)
  local h = btHingeConstraint(anchor.body, body, btTransform(BQ * zToY, W3(WH.x, wy, WH.z)),
                              btTransform(zToY, btVector3(0, 0, 0)))
  v:addConstraint(h)
  local knob = part(string.format("translate([0, %.4f, 0]) knob()", -wy * 10))
  knob.col = "#2a2622"
  v:add(knob)
  wheel = { body = body, hinge = h, obj = o, knob = knob, y = wy, turned = 0, target = 0, last = 0 }
  key(o, "the feeder: each quarter turn of its knob (Space) carries one ball round and lets it out")
  key(knob, "the feeder's knob: Space turns it a quarter turn")
end
-- how far it has turned (radians, clockwise as you look: the way it is turned)
local function wheelAngle()
  local a = wheel.hinge:getHingeAngle()
  local d = a - wheel.last
  if d > math.pi then d = d - 2 * math.pi elseif d < -math.pi then d = d + 2 * math.pi end
  wheel.last = a
  wheel.turned = wheel.turned + d
  return wheel.turned
end
local TURN_W = 6.0                    -- the hand's turn, radians a second
local HAND_T = envnum("DC_HAND", 50)  -- the most the hand turns it with (kg cm^2/s^2: 0.005 N m)
local turnSign = 1                    -- (found below: which hinge sense is clockwise)
local function handPre()
  local a = wheelAngle()
  local left = wheel.target - a
  if math.abs(left) > 0.01 then
    local w = math.min(TURN_W, math.abs(left) * 20 + 0.5)
    wheel.hinge:enableAngularMotor(true, turnSign * (left > 0 and w or -w), HAND_T * STEP)
    return true
  end
  wheel.hinge:enableAngularMotor(true, 0, HAND_T * STEP)    -- (the hand holds the knob still)
  return false
end
local function carryKnob()
  wheel.knob.trans = wheel.body:getCenterOfMassTransform()
  for _, fl in ipairs(flips) do fl.wt.trans = fl.body:getCenterOfMassTransform() end
end

-- ---------------------------------------------------------------------
-- the balls
-- ---------------------------------------------------------------------
local NBALLS = 8
local balls = {}
for i = 1, NBALLS do
  local b = Sphere(G.R, G.BALL_MASS)
  b.col = "#9aa0a8"
  v:add(b)
  b.body:setActivationState(4)
  balls[i] = { obj = b, body = b.body, n = i }
  key(b, { ball = i })
end
-- where the hand puts them: one in the notch about to come to the bottom,
-- one in the top notch, the rest in the channel above
local function ballHome(i)
  local wr = WH.ballR
  if i == 1 then
    -- the notch at the right (it comes to the bottom on the first quarter turn)
    return W3(WH.x + wr, G.R + 0.002, WH.z)
  elseif i == 2 then
    return W3(WH.x, G.R + 0.002, WH.z - wr)
  end
  return W3(WH.x, G.R + 0.002, WH.z - wr - (i - 2) * (2 * G.R + 0.005))
end

local function place(body, tr)
  body:setCenterOfMassTransform(tr)
  body:setLinearVelocity(btVector3(0, 0, 0))
  body:setAngularVelocity(btVector3(0, 0, 0))
  body:clearForces()
  body:activate(true)
end
local function applyFriction()
  local f = v:getParam("friction")
  for _, b in ipairs(balls) do b.body:setFriction(f); b.body:setRestitution(0) end
  for _, fl in ipairs(flips) do fl.body:setFriction(f); fl.body:setRestitution(0) end
  wheel.body:setFriction(f); wheel.body:setRestitution(0)
  for _, c in ipairs(fixed) do c.body:setFriction(1.0); c.body:setRestitution(0) end   -- (Bullet multiplies the two: the slider is what counts)
end

-- ---------------------------------------------------------------------
-- following each ball: which flip-flops it passed, and where it ended
-- ---------------------------------------------------------------------
local LOG = os.getenv("DC_LOG")
local dropped, fed = 0, 0
local function binOf(x)
  local best, bd = nil, 1e9
  for k, t in ipairs(G.toggles) do
    local d = math.abs(x - t.lane); if d < bd then best, bd = k, d end
  end
  if math.abs(x - G.overflow) < bd then best = G.NBITS + 1 end
  return best
end
local function ballAt(b) return L3(b.obj.pos) end
local function inBin(b)
  local x, y, z = ballAt(b)
  return z > G.BIN_Z - 8 and z < G.BIN_Z and y > 0 and y < 2, x
end

local function setUp()
  for k, fl in ipairs(flips) do place(fl.body, flipPose(fl.t, LEAN0)) end
  place(wheel.body, btTransform(BQ, W3(WH.x, wheel.y, WH.z)))
  wheel.turned, wheel.target, wheel.last = 0, 0, wheel.hinge:getHingeAngle()
  for i, b in ipairs(balls) do place(b.body, btTransform(ident, ballHome(i))) end
  applyFriction()
  dropped, fed = 0, 0
  holdStart()
end

-- ---------------------------------------------------------------------
-- at rest: once the hand has nothing to do and nothing has moved for
-- REST_S, the simulation stops stepping (nothing would change but the
-- processor's work). The next thing for the hand to do starts it again.
-- (DC_REST=0: never rest)
-- ---------------------------------------------------------------------
local restBodies = { wheel.body }
for _, fl in ipairs(flips) do restBodies[#restBodies + 1] = fl.body end
for _, b in ipairs(balls) do restBodies[#restBodies + 1] = b.body end
local REST_S = 0.5
local REST_V, REST_W = 0.2, 0.05
local REST_ON = os.getenv("DC_REST") ~= "0"
local restFor, resting = 0, false
local function fastest()
  local mv, mw = 0, 0
  for _, b in ipairs(restBodies) do
    mv = math.max(mv, b:getLinearVelocity():length())
    mw = math.max(mw, b:getAngularVelocity():length())
  end
  return mv, mw
end
local handBusy = false
local queue = 0                       -- quarter turns asked for and not yet begun
local function busy() return handBusy or queue > 0 end
local function restPre()
  if not resting then return false end
  if busy() then resting, restFor = false, 0; applyTiming(); return false end
  v.timeStep = 0
  return true
end
local still = 0                       -- how long nothing has moved (s), whether resting is on or not
local function restPost()
  local mv, mw = fastest()
  -- (the balls roll: their spin counts as moving only through their speed)
  if mv < REST_V and mw < 1.0 then still = still + FRAME_DT else still = 0 end
  if resting then return end
  if busy() then restFor = 0; return end
  if mv < REST_V and mw < 1.0 then restFor = restFor + FRAME_DT else restFor = 0 end
  if REST_ON and restFor >= REST_S then resting = true; v.timeStep = 0 end
end

-- one ball: a quarter turn of the knob
local function feed() queue = queue + 1 end

-- ---------------------------------------------------------------------
-- the tour: from 0, one ball at a time, the reading checked after each
-- ---------------------------------------------------------------------
local TOUR_N = envnum("DC_BALLS", NBALLS)
local tour = (os.getenv("DC_TOUR") or "1") ~= "0" and 0 or nil
local fails, tourWait = 0, 0
local TOUR_PAUSE = envnum("DC_PAUSE", 1.0)        -- s between a reading and the next ball
local pause = nil
local CONTACTS = tonumber(os.getenv("DC_CONTACTS") or "")
local binCount = {}
local function readBins()
  local c = {}
  for k = 1, G.NBITS + 1 do c[k] = 0 end
  for _, b in ipairs(balls) do
    local ok, x = inBin(b)
    if ok then local k = binOf(x); c[k] = c[k] + 1 end
  end
  return c
end
-- (where ball n should go: past every flip-flop that reads 1 before it)
local function expectBin(n)
  local m, k = n - 1, 1
  while k <= G.NBITS and m % 2 == 1 do m = math.floor(m / 2); k = k + 1 end
  return k
end
local function startTour()
  print("\nDIGI-COMP II -- the tour: eight balls, one at a time, from 0")
  tour, fails, tourWait, pause = 0, 0, 0, nil
  setUp()
end
local function check()
  local n = count()
  local c = readBins()
  local want = dropped % (2 ^ G.NBITS)
  local wb = expectBin(dropped)
  local ok = n == want and c[wb] == (binCount[wb] or 0) + 1
  binCount = c
  local cs = {}
  for k = 1, G.NBITS + 1 do cs[#cs + 1] = tostring(c[k]) end
  local an = {}
  for k = 1, G.NBITS do local _, a = bit(k); an[#an + 1] = string.format("%.1f", a) end
  print(string.format("  ball %d:  reads %s = %d  (bins 1s,2s,4s,overflow: %s)  %s%s", dropped, bits(), n,
                      table.concat(cs, " "), ok and "right" or "WRONG",
                      LOG and ("   leans " .. table.concat(an, " ")) or ""))
  return ok
end

-- ---------------------------------------------------------------------
-- stepping
-- ---------------------------------------------------------------------
v:preSim(function(N)
  if holdPre() then return end
  if restPre() then return end
  for k = 1, NSTEPS - 1 do
    handBusy = handPre()
    v:stepSimulation(STEP, 0, STEP)
  end
  handBusy = handPre()
end)

local function startTurn()
  queue = queue - 1
  wheel.target = wheel.target + math.pi / 2
  fed = fed + 1
  dropped = dropped + 1
  still, tourWait = 0, 0
  if LOG then print(string.format("  (a quarter turn: ball %d)", dropped)) end
end

v:postSim(function(N)
  sign(dropped, count())
  if CONTACTS and N == CONTACTS then
    -- (DC_CONTACTS=frame: every contact of the balls and the wheel then: what jams)
    local names = {}
    for k, fl in ipairs(flips) do names[fl.obj] = "flip" .. k end
    names[wheel.obj] = "wheel"; names[boardBox] = "board"
    for i, b in ipairs(balls) do names[b.obj] = "ball" .. i end
    v:eachContact(function(a, b, x, y, z, nx, ny, nz, d, imp)
      local na, nb = names[a] or "?", names[b] or "?"
      if na:match("ball") or nb:match("ball") or na == "wheel" or nb == "wheel" then
        local lx, ly, lz = L3(btVector3(x, y, z))
        print(string.format("contact %s - %s at %.2f %.2f %.2f  d %.3f  imp %.2g", na, nb, lx, ly, lz, d, imp))
      end
    end)
  end
  carryKnob()
  if holdNow then return end
  restPost()
  if queue > 0 and not handBusy then startTurn() end
  if tour then
    tourWait = tourWait + FRAME_DT
    if LOG == "2" and N % 15 == 0 then
      local t = {}
      for i = 1, NBALLS do local x, y, z = ballAt(balls[i]); t[#t + 1] = string.format("(%.1f %.1f %.1f)", x, y, z) end
      print(string.format("  frame %d: ball %s; queue %d, hand %s, still %.2f s, wheel %.2f of %.2f rad, reads %s; balls %s", N, tostring(tour), queue,
        tostring(handBusy), still, wheel.turned, wheel.target, bits(), table.concat(t, " ")))
    end
    if tour == 0 then
      if tourWait > 0.6 then tour, tourWait = 1, 0; binCount = readBins(); feed() end
    elseif pause then
      -- (a pause after each reading, so it can be seen before the next ball)
      pause = pause - FRAME_DT
      if pause <= 0 then pause = nil; tour, tourWait = tour + 1, 0; feed() end
    elseif not busy() and tourWait > 0.5 and (still > 0.4 or tourWait > 8) then
      if not check() then fails = fails + 1 end
      if tour >= TOUR_N then
        print(fails == 0 and "  all right." or string.format("  %d WRONG.", fails))
        print("RESULT digicomp2 tour: " .. (fails == 0 and "PASS" or "FAIL"))
        tour = nil
      else
        pause = TOUR_PAUSE
      end
    end
  end
end)

-- ---------------------------------------------------------------------
-- keys, sliders, help, hover
-- ---------------------------------------------------------------------
v:addShortcut("Space", function() if not tour then feed() end end)
v:addShortcut("T", function() startTour() end)
v:addShortcut("R", function() tour, pause = nil, nil; queue = 0; setUp() end)
v:addShortcut("Z", function()
  local sp = v:getParam("speed") < 0.5 and 1 or 0.25
  v:addParam("speed", sp, 0.05, 2, 0.05, "simulated seconds per real second (Z: 1/4 <-> 1)")
  applyTiming()
end)
v:onParamChanged(function(N, name, value)
  if name == "speed" or name == "steps" then applyTiming()
  elseif name == "friction" then applyFriction() end
end)

pcall(function()
  v:setHelpText(table.concat({
    "THE DIGI-COMP II  (Babbage's Hall) -- the counter",
    "",
    "A computer of rolling balls, after E.S.R.'s Digi-Comp II (1968). The",
    "three rockers are flip-flops: each leans one way or the other and stays.",
    "Apex to the right is 1, to the left 0; together they read the count in",
    "binary (4s, 2s, 1s), from 0 to 7.",
    "",
    "WHAT TO WATCH",
    "  A ball meets a rocker on its raised side and tips it over: it flips.",
    "  Found at 0, it is set to 1 and the ball goes right, to its bin: done.",
    "  Found at 1, it is set to 0 and the ball goes left, to the next one:",
    "  the carry. So every ball adds one. The eighth goes to the overflow.",
    "  Nothing turns the rockers but the balls: their shape and weight do it.",
    "",
    "KEYS",
    "  Space  one ball (a quarter turn of the feeder's knob)",
    "  T      the tour: eight balls from 0     R  set it back (by hand)",
    "  Z      slow motion <-> real time",
    "",
    "Every part can be 3D printed: see the README in this exhibit's folder.",
  }, "\n"))
end)

if v.onHover then
  v:onHover(function(N, obj, x, y, z)
    local d = KEY[objectKey(obj)]
    if not d then return nil end
    if type(d) == "string" then return d end
    if d.flip then
      local b = bit(d.flip)
      return string.format("the %ds flip-flop: it reads %d (apex %s)\n" ..
                           "the next ball here goes %s\ncount: %s = %d", flips[d.flip].weight, b,
                           b == 1 and "right" or "left",
                           b == 1 and "left, to the next flip-flop (a carry), and sets it to 0" or
                                      "right, to its bin, and sets it to 1", bits(), count())
    end
    if d.ball then return string.format("a ball: 1/2 inch steel, 8.35 g\n%d dropped so far; the count is %d", dropped, count()) end
    return nil
  end)
end

-- ---------------------------------------------------------------------
-- which way the motor turns the wheel clockwise (as you look), and start
-- ---------------------------------------------------------------------
do
  -- the wheel goes clockwise as you look (top to right). The hinge's angle
  -- and its motor's speed count the same way about its axis (the board's
  -- normal), and both are clockwise-positive as you look (measured: a
  -- negative speed took the balls the other way round)
  turnSign = 1
end
common.setCamera(btVector3(0, 58, 36), btVector3(0, 5, -2))
if tour then startTour() else setUp() end
