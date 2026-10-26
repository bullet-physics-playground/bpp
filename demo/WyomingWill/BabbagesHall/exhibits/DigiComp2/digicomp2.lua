--
-- The Digi-Comp II -- Babbage's Hall (step 2a: the accumulator)
--
-- E.S.R.'s Digi-Comp II (1968) was a computer of marbles: a sloping
-- two-level board of flip-flops and switches that balls roll down one at a
-- time, and that counts, adds, subtracts, multiplies and divides in binary.
-- This is its first part: the ACCUMULATOR, seven flip-flops that hold a
-- number from 0 to 127, with the START feeder at the top and two of its
-- switches, CLEAR and COUNT. With COUNT on, each ball adds one; with CLEAR
-- on, one ball sets the whole accumulator to 0. (Memory, the multiplier and
-- the distributor, for adding and multiplying, come next; then complement,
-- for subtracting and dividing.)
--
-- THE FLIP-FLOP is a rocker on a pin, its centre of mass a little up the
-- slope from the pin, so it falls over to one side or the other and stays
-- there, its tail on a stop peg. Apex to the right reads 1, to the left 0.
-- A ball rolling straight down meets the roof on its raised side, rolls into
-- that cup, and its weight takes the rocker over; at the end of the swing
-- the cup tips it out. Found at 0, the rocker is set to 1 and the ball drops
-- through a hole on its right to the lower level: done. Found at 1, it is
-- set to 0 and the ball goes left, down to the next flip-flop: the carry.
-- So each ball adds one, carrying as far as it must. A carry out of the last
-- (the 64s) drops through the overflow hole.
--
-- CLEAR: under each rocker, on the lower level, is its foot, a wedge that
-- leans into the clear lane when the rocker reads 1. A ball sent down the
-- clear lane pushes every wedge it meets out of its way, which turns that
-- rocker to 0, and passes the rockers already at 0.
--
-- THE SWITCHES are flaps, set by hand: each closes one of its two outlets,
-- and a ball only presses it harder against that wall.
--
-- KEYS
--   Space  START: a quarter turn of the feeder's knob, one ball
--   C      CLEAR on <-> off (by hand)      N  COUNT on <-> off (by hand)
--   1..7   set that flip-flop over by hand (1 is the 1s, 7 the 64s)
--   T      the tour (it starts with it)
--   R      set it back: the balls to the top, A to 0, COUNT on, CLEAR off
--   Z      slow motion (1/4) <-> real time
--
-- EVERY PART CAN BE PRINTED: see parts/ and README.md. What is printed is
-- what is simulated: every wall, peg, hole, rocker, foot, flap and the wheel
-- are the shapes in digicomp2-geometry.lua, from which parts/geometry.scad
-- is written.
--
-- PHYSICS: 1/2 inch steel balls (8.35 g); PLA rockers with a 1/4 inch steel
-- ball pressed into each and a PLA foot (5.9 g in all), friction 0.3, no
-- bounce, the board at 15 degrees, 2400 steps a second. The rockers and
-- flaps turn on their pins against a friction torque (DC_PF, 0.4 kg
-- cm^2/s^2: see FINDINGS.md). The feeder's knob is turned by the hand (a
-- motor: the operator's), and the hand sets the switches and flip-flops.
--
-- Units: centimetres, kilograms, seconds.
-- Headless: DC_TOUR=0 (no tour), DC_FRICTION, DC_PF (pivot friction,
-- kg cm^2/s^2), DC_TH (the slope, degrees), DC_HZ (steps a second),
-- DC_ROLL (degrees: the table not level across, down to the right),
-- DC_HAND (the hand's torque), DC_EXPORT=1 (write parts/geometry.scad),
-- DC_LOG=1 (each ball's reading and the rockers' leans), DC_LOG=2 (also
-- every moving ball four times a second), DC_LOG=3 (where every ball is at
-- each reading), DC_CONTACTS=frame (every contact
-- of the balls, flaps and wheel at that frame: what jams), DC_PAUSE (s
-- between a reading and the next ball in the tour, 1), DC_REST=0.
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
local B, LB = G.board, G.lower
local YL, PT = G.YL, G.PT
local OX = -(LB.x0 + LB.x1) / 2
local OY = G.FOOT + (-YL + G.BACK) * cT + LB.z1 * sT
local OZ = -(LB.z0 + LB.z1) / 2 * cT
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
local BW, BD = LB.x1 - LB.x0, (LB.z1 - LB.z0) * cT
local top = TABLE.build(BW, BD, { floor = 400 })

-- ---------------------------------------------------------------------
-- the fixed parts: the two levels, their walls, the pegs, the posts
-- ---------------------------------------------------------------------
local KEY = {}
local fixed = {}
local function key(obj, what) if objectKey then KEY[objectKey(obj)] = what end end
local function box(x0, x1, y0, y1, z0, z1, col, tr)
  local c = Cube(x1 - x0, y1 - y0, z1 - z0, 0)
  c.trans = btTransform(BQ, W3((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2))
  c.col = col
  if tr then pcall(function() c.transparency = tr end) end
  v:add(c)
  fixed[#fixed + 1] = c
  return c
end
-- the upper plate: boxes round its holes (it is drawn a little see-through,
-- so the lower level shows)
-- (the boxes are for the physics and not drawn; the plate is drawn as printed)
local PLATE_COL, PLATE_TR = "#1f3b4d", 1.0
do
  local holes = G.holes
  local zs = { B.z0, B.z1 }
  for _, h in ipairs(holes) do zs[#zs + 1] = h[3]; zs[#zs + 1] = h[4] end
  table.sort(zs)
  for i = 1, #zs - 1 do
    local a, b = zs[i], zs[i + 1]
    if b - a > 1e-6 then
      local cuts = {}
      for _, h in ipairs(holes) do if h[3] <= a + 1e-6 and h[4] >= b - 1e-6 then cuts[#cuts + 1] = h end end
      table.sort(cuts, function(p, q) return p[1] < q[1] end)
      local x = B.x0
      for _, h in ipairs(cuts) do
        if h[1] > x + 1e-6 then key(box(x, h[1], -PT, 0, a, b, PLATE_COL, PLATE_TR), "the upper plate: the balls compute on it") end
        x = math.max(x, h[2])
      end
      if B.x1 > x + 1e-6 then key(box(x, B.x1, -PT, 0, a, b, PLATE_COL, PLATE_TR), "the upper plate: the balls compute on it") end
    end
  end
end
local plateView = part("plateView()")
plateView.col = "#1f3b4d"
pcall(function() plateView.transparency = 0.35 end)
v:add(plateView)
plateView.trans = btTransform(BQ, W3(0, 0, 0))
key(plateView, "the upper plate: the balls compute on it (drawn see-through, so the lower level shows)")
local lowerBoard = box(LB.x0, LB.x1, YL - G.BACK, YL, LB.z0, LB.z1, "#e9e2cf")
key(lowerBoard, "the lower board: balls that are done roll down it to the collector")
-- (the stand: four feet under the lower board, drawn only)
local stand = part("stand()")
stand.col = "#7a5a3a"
v:add(stand)
stand.trans = btTransform(BQ, W3(0, 0, 0))

local WALL_COL = { housing = "#9b1c1c", queue = "#9b1c1c", rim = "#7a5a3a", switch = "#c9a14a",
                   done = "#d9d4c5", overflow = "#9b1c1c", clear = "#2f8c5a", drop = "#c9a14a", collector = "#7a5a3a" }
local ROLE_TEXT = {
  housing = "the feeder's housing: it holds the balls in the wheel's notches",
  queue = "the INPUT channel: the balls waiting at the feeder",
  rim = "the board's rim",
  switch = "a switch's channels: its flap sends a ball out of one outlet or the other",
  done = "a done hole: a ball that set its flip-flop to 1 drops through it to the lower level",
  overflow = "OVERFLOW: a carry out of the 64s (the 128th ball) drops through here",
  clear = "the clear lane (lower level): a ball here pushes every flip-flop at 1 back to 0",
  drop = "COUNT off: the ball drops to the lower level and counts nothing",
  collector = "the COLLECTOR: every ball ends here",
}
local function addWall(w, y0, y1)
  local dx, dz = w[3] - w[1], w[4] - w[2]
  local len = math.sqrt(dx * dx + dz * dz) + G.WALL_T
  local c = Cube(len, y1 - y0, G.WALL_T, 0)
  c.trans = btTransform(yq(math.atan2(-dz, dx)), W3((w[1] + w[3]) / 2, (y0 + y1) / 2, (w[2] + w[4]) / 2))
  c.col = WALL_COL[w.role] or "#d9d4c5"
  v:add(c)
  fixed[#fixed + 1] = c
  key(c, ROLE_TEXT[w.role] or "a channel: it brings the ball straight down onto the flip-flop's apex")
end
for _, w in ipairs(G.walls) do addWall(w, 0, G.WALL_H) end
for _, w in ipairs(G.lwalls) do addWall(w, YL, YL + w[5]) end
local function post(x, z, r, y0, y1, col, what)
  local c = Cylinder(r, y1 - y0, 0)               -- (bpp's Cylinder: along z; stood up)
  c.trans = btTransform(BQ * zToY, W3(x, (y0 + y1) / 2, z))
  c.col = col
  v:add(c)
  fixed[#fixed + 1] = c
  key(c, what)
end
for _, p in ipairs(G.pegs) do post(p[1], p[2], p[3], 0, G.WALL_H, "#9a9da3", "a stop peg: the flip-flop's tail rests on it") end
for _, p in ipairs(G.posts) do post(p[1], p[2], 0.5, YL, -PT, "#7a5a3a", "a post: it holds the upper plate over the lower level") end
-- the lettering on the board
local marks = part("boardMarks()")
marks.col = "#efe6cf"
v:add(marks)
marks.trans = btTransform(BQ, W3(0, 0, 0))

local anchor = Cube(0.01, 0.01, 0.01, 0)          -- (only for the hinges to hold to: too small to see)
anchor.collides = false
v:add(anchor)
anchor.trans = btTransform(ident, btVector3(0, 0, 0))

-- a body's shape: convex pieces { outline { {x, z}, ... }, y0, h } about (cx, cy, cz)
local function piecesShape(pieces, cx, cy, cz)
  local s = btCompoundShape(true)
  for _, pc in ipairs(pieces) do
    local hs = btConvexHullShape()
    for _, p in ipairs(pc[1]) do
      hs:addPoint(btVector3(p[1] - cx, pc[2] - cy, p[2] - cz), false)
      hs:addPoint(btVector3(p[1] - cx, pc[2] + pc[3] - cy, p[2] - cz), false)
    end
    hs:recalcLocalAabb()
    hs:setMargin(0.005)
    s:addChildShape(btTransform(ident, btVector3(0, 0, 0)), hs)
  end
  return s
end
-- a body on a pin at (x, z), turned phi right-handed about the board's normal
local function poseAt(x, z, cx, cy, cz, phi)
  local c, s = math.cos(phi), math.sin(phi)
  return btTransform(yq(phi), W3(x + c * cx + s * cz, cy, z - s * cx + c * cz))
end
local function pinned(body, x, y, z, cx, cz)
  local h = btHingeConstraint(anchor.body, body, btTransform(BQ * zToY, W3(x, y, z)),
                              btTransform(zToY, btVector3(-cx, 0, -cz)))
  v:addConstraint(h)
  return h
end

-- ---------------------------------------------------------------------
-- the flip-flops: rocker, steel ball, stem and foot, one body on its pin
-- ---------------------------------------------------------------------
local PF = envnum("DC_PF", 0.4)        -- the pins' friction (kg cm^2/s^2): see FINDINGS
local flips = {}
local yc = F.Y0 + F.H / 2
local flipPieces = {}
for _, pc in ipairs(F.pieces) do flipPieces[#flipPieces + 1] = { pc, F.Y0, F.H } end
for _, l in ipairs(F.lower) do flipPieces[#flipPieces + 1] = l end
local LEAN = math.rad(F.ALPHA - 0.3)              -- (set by hand: just short of its stop, then it settles)
local function flipPose(t, b) return poseAt(t.x, t.z, F.cx, yc, F.cz, b == 1 and -LEAN or LEAN) end
for k, t in ipairs(G.toggles) do
  local tr = flipPose(t, 0)
  local body = btRigidBody(F.mass, btDefaultMotionState(tr), piecesShape(flipPieces, F.cx, yc, F.cz), btVector3(F.I, F.I, F.I))
  local frame = string.format("translate([%.4f, %.4f, %.4f])", -F.cx * 10, -yc * 10, -F.cz * 10)
  local o = part(frame .. " rocker()")
  o.body = body
  o.col = "#f4ecd6"
  o.collides = true
  v:add(o)
  body:setCenterOfMassTransform(tr)
  body:setActivationState(4)
  local h = pinned(body, t.x, yc, t.z, F.cx, F.cz)
  if PF > 0 then h:enableAngularMotor(true, 0, PF * STEP) end
  local wt = part(frame .. " rockerWeight()")
  wt.col = "#9a9da3"
  v:add(wt)
  local foot = part(frame .. " foot()")
  foot.col = "#2f8c5a"
  v:add(foot)
  -- its pin (drawn only: the hinge is the pin), from the lower board up
  local pin = Cylinder(F.PIN_R, F.Y0 + F.H + 0.1 - YL, 0)
  pin.collides = false
  pin.col = "#b8bcc2"
  v:add(pin)
  pin.trans = btTransform(BQ * zToY, W3(t.x, (YL + F.Y0 + F.H + 0.1) / 2, t.z))
  flips[k] = { t = t, body = body, hinge = h, obj = o, weight = 2 ^ (k - 1), riders = { wt, foot } }
  key(o, { flip = k }); key(foot, { foot = k })
end
local function bit(k)
  -- (1: its apex to the right, a clockwise lean as you look)
  local a = flips[k].body:getCenterOfMassTransform():getBasis():getColumn(0)
  local bz = -a.y * sT + a.z * cT
  return bz > 0 and 1 or 0, math.deg(math.atan2(bz, a.x))
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
local function binary(n)
  local s = ""
  for k = G.NBITS - 1, 0, -1 do s = s .. math.floor(n / 2 ^ k) % 2 end
  return s
end

-- ---------------------------------------------------------------------
-- the switches: CLEAR and COUNT, flaps on pins, set by hand
-- ---------------------------------------------------------------------
-- (a flap closing its LEFT outlet sends the ball right. CLEAR on sends it
-- left, into the clear lane; COUNT on sends it left, into A1)
local SW = G.SWITCH
local switches = {}
local swAng = math.rad(SW.ANG - 0.5)
local scz = -SW.FL / 2
local syc = SW.Y0 + SW.H / 2
local flapPieces = { { { { -SW.FT / 2, -SW.FL }, { SW.FT / 2, -SW.FL }, { SW.FT / 2, 0 }, { -SW.FT / 2, 0 } }, SW.Y0, SW.H } }
local function swPose(s, on)
  -- on: the flap against the RIGHT wall (closing the right outlet): the ball goes left
  return poseAt(s.x, s.z, 0, syc, scz, on and -swAng or swAng)
end
for _, name in ipairs({ "CLEAR", "COUNT" }) do
  local s = G.switches[name]
  local on = name == "COUNT"
  local tr = swPose(s, on)
  local body = btRigidBody(SW.mass, btDefaultMotionState(tr), piecesShape(flapPieces, 0, syc, scz), btVector3(SW.I, SW.I, SW.I))
  local o = part(string.format("translate([0, %.4f, %.4f]) flap()", -syc * 10, -scz * 10))
  o.body = body
  o.col = "#c9a14a"
  o.collides = true
  v:add(o)
  body:setCenterOfMassTransform(tr)
  body:setActivationState(4)
  local h = pinned(body, s.x, syc, s.z, 0, scz)
  if PF > 0 then h:enableAngularMotor(true, 0, PF * STEP) end
  switches[name] = { s = s, body = body, hinge = h, obj = o, name = name }
  key(o, { switch = name })
end
-- which way a flap leans: on (its end against the right wall)?
local function isOn(name)
  local a = switches[name].body:getCenterOfMassTransform():getBasis():getColumn(2)   -- (its z axis: from its end to its pin)
  return a.x < 0
end

-- ---------------------------------------------------------------------
-- the feeder: a wheel of four notches on a pin, turned by the knob (START)
-- ---------------------------------------------------------------------
local wheel
do
  local wy = WH.Y0 + WH.H / 2
  local wp = {}
  for _, pc in ipairs(WH.pieces) do wp[#wp + 1] = { pc, WH.Y0, WH.H } end
  local tr = btTransform(BQ, W3(WH.x, wy, WH.z))
  local body = btRigidBody(WH.mass, btDefaultMotionState(tr), piecesShape(wp, 0, wy, 0), btVector3(WH.I, WH.I, WH.I))
  local o = part(string.format("translate([0, %.4f, 0]) wheel()", -wy * 10))
  o.body = body
  o.col = "#c9a14a"
  o.collides = true
  v:add(o)
  body:setCenterOfMassTransform(tr)
  body:setActivationState(4)
  local h = pinned(body, WH.x, wy, WH.z, 0, 0)
  local knob = part(string.format("translate([0, %.4f, 0]) knob()", -wy * 10))
  knob.col = "#2a2622"
  v:add(knob)
  wheel = { body = body, hinge = h, obj = o, knob = knob, y = wy, turned = 0, target = 0, last = 0 }
  key(o, "START: the feeder. Each quarter turn of its knob (Space) carries one ball round and lets it out")
  key(knob, "START: the feeder's knob. Space turns it a quarter turn: one ball")
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
-- (the hinge's angle and its motor's speed both count clockwise as you look:
-- measured in step 1, a negative speed took the balls the other way round)
local function handPre()
  local a = wheelAngle()
  local left = wheel.target - a
  if math.abs(left) > 0.01 then
    local w = math.min(TURN_W, math.abs(left) * 20 + 0.5)
    wheel.hinge:enableAngularMotor(true, left > 0 and w or -w, HAND_T * STEP)
    return true
  end
  wheel.hinge:enableAngularMotor(true, 0, HAND_T * STEP)    -- (the hand holds the knob still)
  return false
end
local function carryRiders()
  wheel.knob.trans = wheel.body:getCenterOfMassTransform()
  for _, fl in ipairs(flips) do
    local tr = fl.body:getCenterOfMassTransform()
    for _, r in ipairs(fl.riders) do r.trans = tr end
  end
end

-- ---------------------------------------------------------------------
-- the balls
-- ---------------------------------------------------------------------
local NBALLS = 12
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
  if i == 1 then return W3(WH.x + wr, G.R + 0.002, WH.z)
  elseif i == 2 then return W3(WH.x, G.R + 0.002, WH.z - wr) end
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
  for _, s in pairs(switches) do s.body:setFriction(f); s.body:setRestitution(0) end
  wheel.body:setFriction(f); wheel.body:setRestitution(0)
  for _, c in ipairs(fixed) do c.body:setFriction(1.0); c.body:setRestitution(0) end   -- (Bullet multiplies the two: the slider is what counts)
end
local function ballAt(b) return L3(b.obj.pos) end
local function collected(b)
  local x, y, z = ballAt(b)
  return y < -PT and z > G.ZCOL - 3
end
local function nCollected()
  local n = 0
  for _, b in ipairs(balls) do if collected(b) then n = n + 1 end end
  return n
end

-- ---------------------------------------------------------------------
-- the hand: sets a flip-flop or a switch, puts the balls back
-- ---------------------------------------------------------------------
local function setBit(k, b) place(flips[k].body, flipPose(flips[k].t, b)) end
local function setA(n) for k = 1, G.NBITS do setBit(k, math.floor(n / 2 ^ (k - 1)) % 2) end end
local function setSwitch(name, on) local s = switches[name]; place(s.body, swPose(s.s, on)) end
local function reload()
  place(wheel.body, btTransform(BQ, W3(WH.x, wheel.y, WH.z)))
  wheel.turned, wheel.target, wheel.last = 0, 0, wheel.hinge:getHingeAngle()
  for i, b in ipairs(balls) do place(b.body, btTransform(ident, ballHome(i))) end
end

-- ---------------------------------------------------------------------
-- the sign beside it, the exhibit's (not the machine's): what the
-- accumulator reads, in binary and as a number. The machine shows it by its
-- rockers' lean (and the 0 and 1 printed either side of each apex); the
-- script reads them for the sign.
-- ---------------------------------------------------------------------
local sign
do
  local SX, SZ, TILT = -(BW / 2 + 14), BD / 2 - 30, math.rad(-25)
  local q = btQuaternion(btVector3(1, 0, 0), TILT)
  local SW_, SH_ = 20, 11
  local back = Cube(SW_, SH_, 0.8, 0)
  back.col = "#1d1712"
  v:add(back)
  local up = btVector3(0, math.cos(TILT), math.sin(TILT))      -- (the sign's own up, leaning back)
  local function at(u, w, d)                                    -- (across, up, out of its face)
    return btVector3(SX + u, SH_ / 2 + 2 + up.y * w, SZ + up.z * w + d * math.cos(TILT))
  end
  back.trans = btTransform(q, at(0, 0, 0))
  local stem = Cube(2, 4, 2, 0)
  stem.col = "#2b2b2b"; stem.collides = false
  v:add(stem)
  stem.trans = btTransform(ident, btVector3(SX, 2, SZ))
  key(back, "the exhibit's sign, not the machine's: the script reads the rockers for it")
  local function line(t, size, u, w)
    local m = part(string.format('signText("%s", %d)', t, size))
    m.col = "#efe6cf"
    v:add(m)
    m.trans = btTransform(q, at(u, w, 0.45))
    return m
  end
  line("THE ACCUMULATOR", 10, -SW_ / 2 + 1.0, 3.4)
  local AWAY = btTransform(ident, btVector3(0, -500, 0))
  -- a cell that shows one of several characters
  local function cell(chars, size, u, w)
    local c = { parts = {}, shown = nil, tr = btTransform(q, at(u, w, 0.45)) }
    for i = 1, #chars do
      local ch = chars:sub(i, i)
      local m = part(string.format('signText("%s", %d)', ch, size))
      m.col = "#efe6cf"
      v:add(m)
      m.trans = AWAY
      c.parts[ch] = m
    end
    function c.show(ch)
      if c.shown == ch then return end
      if c.shown then c.parts[c.shown].trans = AWAY end
      if ch then c.parts[ch].trans = c.tr end
      c.shown = ch
    end
    return c
  end
  local bitCells, decCells = {}, {}
  for i = 1, G.NBITS do bitCells[i] = cell("01", 11, -SW_ / 2 + 1.0 + (i - 1) * 1.25, 0) end
  line("=", 11, -SW_ / 2 + 10.2, 0)
  for i = 1, 3 do decCells[i] = cell("0123456789", 11, -SW_ / 2 + 12.0 + (i - 1) * 1.25, 0) end
  local bal = { cell("0123456789", 7, -SW_ / 2 + 9.2, -3.6), cell("0123456789", 7, -SW_ / 2 + 10.0, -3.6) }
  line("balls in:", 7, -SW_ / 2 + 1.0, -3.6)
  sign = function(n, nb)
    local b = binary(n)
    for i = 1, G.NBITS do bitCells[i].show(b:sub(i, i)) end
    local d = string.format("%3d", n)
    for i = 1, 3 do local ch = d:sub(i, i); decCells[i].show(ch ~= " " and ch or nil) end
    local e = string.format("%2d", math.min(nb, 99))
    bal[1].show(e:sub(1, 1) ~= " " and e:sub(1, 1) or nil); bal[2].show(e:sub(2, 2))
  end
end

-- ---------------------------------------------------------------------
-- at rest: once the hand has nothing to do and nothing has moved for
-- REST_S, the simulation stops stepping (nothing would change but the
-- processor's work). The next thing for the hand to do starts it again.
-- ---------------------------------------------------------------------
local restBodies = { wheel.body }
for _, fl in ipairs(flips) do restBodies[#restBodies + 1] = fl.body end
for _, s in pairs(switches) do restBodies[#restBodies + 1] = s.body end
for _, b in ipairs(balls) do restBodies[#restBodies + 1] = b.body end
local REST_S = 0.5
local REST_V = 0.2
local REST_ON = os.getenv("DC_REST") ~= "0"
local restFor, resting = 0, false
local function fastest()
  local mv = 0
  for _, b in ipairs(restBodies) do mv = math.max(mv, b:getLinearVelocity():length()) end
  return mv
end
local handBusy = false
local queue = 0                       -- quarter turns asked for and not yet begun
local wake = 0                        -- (s: the hand has just moved something)
local function busy() return handBusy or queue > 0 or wake > 0 end
local function restPre()
  if not resting then return false end
  if busy() then resting, restFor = false, 0; applyTiming(); return false end
  v.timeStep = 0
  return true
end
local still = 0                       -- how long nothing has moved (s)
local function restPost()
  local mv = fastest()
  if mv < REST_V then still = still + FRAME_DT else still = 0 end
  if resting then return end
  if busy() then restFor = 0; return end
  if mv < REST_V then restFor = restFor + FRAME_DT else restFor = 0 end
  if REST_ON and restFor >= REST_S then resting = true; v.timeStep = 0 end
end
local function handMoved() wake, still = 0.3, 0 end

local dropped = 0
local function feed() queue = queue + 1 end
local function setUp()
  setA(0)
  setSwitch("COUNT", true); setSwitch("CLEAR", false)
  reload()
  applyFriction()
  dropped = 0
  handMoved()
  holdStart()
end

-- ---------------------------------------------------------------------
-- the tour: counting, a carry right through and the overflow, CLEAR, and
-- a ball with both switches off; every reading checked
-- ---------------------------------------------------------------------
local LOG = os.getenv("DC_LOG")
local TOUR = {
  { say = "COUNT on, from 0: four balls", A = 0, COUNT = true, CLEAR = false, balls = 4 },
  { say = "125 set by hand: three balls carry through to 126, 127, and over to 0", A = 125, balls = 3 },
  { say = "90 set by hand, CLEAR on: one ball clears it", A = 90, CLEAR = true, balls = 1 },
  { say = "127 set by hand: one ball clears all seven", A = 127, balls = 1 },
  { say = "CLEAR again, at 0: nothing changes", balls = 1 },
  { say = "5 set by hand, both switches off: the ball counts nothing", A = 5, COUNT = false, CLEAR = false, balls = 1 },
}
local tour = (os.getenv("DC_TOUR") or "1") ~= "0" and { i = 0 } or nil
local TOUR_PAUSE = envnum("DC_PAUSE", 1.0)
local CONTACTS = tonumber(os.getenv("DC_CONTACTS") or "")
local fails = 0
local function startTour()
  print("\nDIGI-COMP II -- the tour: the accumulator")
  tour = { i = 0, wait = 0 }
  fails = 0
  setUp()
end
local function nextStep()
  tour.i = tour.i + 1
  local s = TOUR[tour.i]
  if not s then
    print(fails == 0 and "  all right." or string.format("  %d WRONG.", fails))
    print("RESULT digicomp2 tour: " .. (fails == 0 and "PASS" or "FAIL"))
    tour = nil
    return
  end
  print("  " .. s.say)
  if s.A then setA(s.A) end
  if s.COUNT ~= nil then setSwitch("COUNT", s.COUNT) end
  if s.CLEAR ~= nil then setSwitch("CLEAR", s.CLEAR) end
  -- (what the machine should read after each ball)
  tour.left = s.balls
  tour.expect = s.A or count()
  tour.phase, tour.wait = "settle", 0
  handMoved()
end
local function checkBall()
  local clear, cnt = isOn("CLEAR"), isOn("COUNT")
  local want = clear and 0 or (cnt and (tour.expect + 1) % 128 or tour.expect)
  tour.expect = want
  local n = count()
  local c = nCollected()
  local ok = n == want and c == dropped
  local an = {}
  if LOG then for k = 1, G.NBITS do local _, a = bit(k); an[#an + 1] = string.format("%.0f", a) end end
  if LOG == "3" then
    for _, b in ipairs(balls) do local x, y, z = ballAt(b); print(string.format("      ball %d at %.1f %.1f %.1f%s", b.n, x, y, z, collected(b) and " (collected)" or "")) end
  end
  print(string.format("    ball %d:  reads %s = %d  (%d in the collector)  %s%s", dropped, bits(), n, c,
                      ok and "right" or ("WRONG: should be " .. want), LOG and ("   leans " .. table.concat(an, " ")) or ""))
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
  dropped = dropped + 1
  still = 0
  if tour then tour.wait = 0 end
end

v:postSim(function(N)
  carryRiders()
  sign(count(), dropped)
  if CONTACTS and N == CONTACTS then
    local names = {}
    for k, fl in ipairs(flips) do names[fl.obj] = "flip" .. k end
    for n, s in pairs(switches) do names[s.obj] = n end
    names[wheel.obj] = "wheel"
    for i, b in ipairs(balls) do names[b.obj] = "ball" .. i end
    v:eachContact(function(a, b, x, y, z, nx, ny, nz, d, imp)
      local na, nb = names[a] or "?", names[b] or "?"
      if na ~= "?" or nb ~= "?" then
        local lx, ly, lz = L3(btVector3(x, y, z))
        print(string.format("contact %s - %s at %.2f %.2f %.2f  d %.3f  imp %.2g", na, nb, lx, ly, lz, d, imp))
      end
    end)
  end
  if holdNow then return end
  if wake > 0 then wake = wake - FRAME_DT end
  restPost()
  if queue > 0 and not handBusy then startTurn() end
  if LOG == "2" and N % 15 == 0 then
    local t = {}
    for _, b in ipairs(balls) do
      if b.body:getLinearVelocity():length() > REST_V then local x, y, z = ballAt(b); t[#t + 1] = string.format("%d (%.1f %.1f %.1f)", b.n, x, y, z) end
    end
    if #t > 0 then print(string.format("  frame %d: reads %s; moving: %s", N, bits(), table.concat(t, ", "))) end
  end
  if tour then
    tour.wait = (tour.wait or 0) + FRAME_DT
    if tour.i == 0 then
      if tour.wait > 0.6 then nextStep() end
    elseif tour.phase == "settle" then
      if tour.wait > 0.6 and not busy() then
        if tour.left > 0 then tour.phase, tour.wait = "ball", 0; feed() else nextStep() end
      end
    elseif tour.phase == "ball" then
      if not busy() and tour.wait > 0.5 and (still > 0.4 or tour.wait > 8) then
        if not checkBall() then fails = fails + 1 end
        tour.left = tour.left - 1
        tour.phase, tour.wait = "pause", 0
      end
    elseif tour.phase == "pause" then
      if tour.wait > TOUR_PAUSE then
        if tour.left > 0 then tour.phase, tour.wait = "ball", 0; feed() else nextStep() end
      end
    end
  end
end)

-- ---------------------------------------------------------------------
-- keys, sliders, help, hover
-- ---------------------------------------------------------------------
v:addShortcut("Space", function() if not tour then feed() end end)
v:addShortcut("C", function() if not tour then setSwitch("CLEAR", not isOn("CLEAR")); handMoved() end end)
v:addShortcut("N", function() if not tour then setSwitch("COUNT", not isOn("COUNT")); handMoved() end end)
for k = 1, G.NBITS do
  v:addShortcut(tostring(k), function() if not tour then setBit(k, 1 - bit(k)); handMoved() end end)
end
v:addShortcut("T", function() startTour() end)
v:addShortcut("R", function() tour = nil; queue = 0; setUp() end)
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
    "THE DIGI-COMP II  (Babbage's Hall) -- the accumulator",
    "",
    "A computer of rolling balls, after E.S.R.'s Digi-Comp II (1968). The seven",
    "rockers are flip-flops: each leans one way or the other and stays. Apex",
    "right is 1, left 0; together, bottom (64s) to top (1s), they read the",
    "accumulator in binary, 0 to 127.",
    "",
    "WHAT TO WATCH",
    "  COUNT on: a ball meets the 1s rocker on its raised side and tips it over.",
    "  Found at 0, it is set to 1 and the ball drops through the hole on its",
    "  right: done. Found at 1, it is set to 0 and the ball goes on to the next:",
    "  the carry. So every ball adds one.",
    "  CLEAR on: the ball drops to the lower level and runs down the green lane,",
    "  pushing every foot of a rocker at 1 out of its way: all go to 0.",
    "  The switches are flaps the hand sets; a ball only presses them harder.",
    "",
    "KEYS",
    "  Space  START: one ball          C  CLEAR on/off    N  COUNT on/off",
    "  1..7   set a rocker over by hand (1 = the 1s ... 7 = the 64s)",
    "  T      the tour                  R  set it back     Z  slow motion",
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
      return string.format("A%d, the %ds flip-flop: it reads %d (apex %s)\n" ..
                           "the next ball here goes %s\nthe accumulator: %s = %d", d.flip, flips[d.flip].weight, b,
                           b == 1 and "right" or "left",
                           b == 1 and "left, to the next flip-flop (a carry), and sets it to 0" or
                                      "right, through its done hole, and sets it to 1", bits(), count())
    end
    if d.foot then
      return string.format("A%d's foot, on the lower level: when the rocker reads 1 its wedge leans\n" ..
                           "into the clear lane, and a clear ball pushes it back to 0 (now: %d)", d.foot, bit(d.foot))
    end
    if d.switch then
      local on = isOn(d.switch)
      local what = d.switch == "CLEAR" and "the ball drops into the clear lane, which sets every flip-flop to 0"
                                        or "the ball goes into A1 and adds one"
      return string.format("the %s switch (%s: %s to change it by hand)\non: %s", d.switch, on and "ON" or "OFF",
                           d.switch == "CLEAR" and "C" or "N", what)
    end
    if d.ball then return string.format("a ball: 1/2 inch steel, 8.35 g\n%d let in; the accumulator reads %d", dropped, count()) end
    return nil
  end)
end

common.setCamera(btVector3(-6, 112, 78), btVector3(-6, 6, -6))
if tour then startTour() else setUp() end
