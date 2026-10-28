--
-- The Digi-Comp II -- Babbage's Hall (step 2c: counting, adding, multiplying, subtracting, dividing)
--
-- E.S.R.'s Digi-Comp II (1968) was a computer of marbles: a sloping
-- two-level board of flip-flops and switches that balls roll down one at a
-- time, and that counts, adds, subtracts, multiplies and divides in binary.
-- Built so far: the ACCUMULATOR (seven flip-flops, 0 to 127), the MEMORY
-- (four switches), the MQ (three flip-flops), the DISTRIBUTOR (three), the
-- START feeder, the switches MULTIPLY, CLEAR and COUNT, and COMPLEMENT. It
-- counts, clears, adds, multiplies, complements, subtracts and divides.
-- (AUTO comes next.)
--
-- THE FLIP-FLOP is a rocker on a pin, its centre of mass a little up the
-- slope from the pin, so it falls over to one side or the other and stays
-- there, its tail on a stop peg. Apex to the right reads 1, to the left 0.
-- A ball rolling straight down meets the roof on its raised side, rolls into
-- that cup, and its weight takes the rocker over; at the end of the swing
-- the cup tips it out. Found at 0, the rocker is set to 1 and the ball
-- leaves to the right; found at 1, it is set to 0 and the ball leaves to
-- the left. All thirteen are alike; where each side leads makes the register:
--   A: right, through a done hole to the lower level; left, the carry, on
--      to the next (out of A7, the overflow). So each ball adds one at the
--      place it comes in.
--   D: a tree. D1 sends the balls to D2 and D3 by turns, each of them by
--      turns to its two sides: four balls, four ways.
--   MQ: a staircase like A's, read the other way (1 with the apex left), so
--      each ball takes one away; a borrow out of MQ3 drops through STOP.
--
-- CLEAR: under each of A's rockers, on the lower level, is its foot, a wedge
-- that leans into the clear lane when the rocker reads 1. A ball sent down
-- the clear lane pushes every wedge it meets out of its way, which turns
-- that rocker to 0, and passes the rockers already at 0.
--
-- MULTIPLY on sends the balls to the distributor: the first of every four
-- through the MQ and on to M4, the others to M1, M3, M2. A memory switch at
-- 1 sends its ball into A at its place; at 0 it drops. So every four balls
-- add the memory to A, once for each count of the MQ; then a ball drops
-- through STOP and the hand stops. ADD is the same with the MQ at 1.
--
-- COMPLEMENT: A1 .. A6's done holes have shutters, all on one bar. Closed,
-- a ball that sets a flip-flop to 1 rolls over its hole and down a lane into
-- the next, so it turns over every flip-flop from where it came in to A7.
-- One ball with COUNT on makes A 127 - A; COMPLEMENT off, one more adds 1:
-- 128 - A, the two's complement. Adding it subtracts (the carry out of A7
-- is lost). Dividing: the divisor added to the dividend's complement, cycle
-- by cycle, the MQ counting, until A overflows (the hand watches OVERFLOW,
-- and stops at the end of that cycle).
--
-- THE SWITCHES are flaps, set by hand: each closes one of its two outlets,
-- and a ball only presses it harder against that wall.
--
-- KEYS
--   Space  START: a quarter turn of the feeder's knob, one ball
--   M, C, N  MULTIPLY, CLEAR, COUNT on <-> off (by hand)
--   1..7   set a flip-flop of A over by hand (1 is the 1s, 7 the 64s)
--   H J K L  the memory's 1s, 2s, 4s, 8s    8 9 0  the MQ's 1s, 2s, 4s
--   D      set the distributor to start a cycle
--   X      COMPLEMENT on <-> off
--   G      run the program chosen with the "program" slider (G again: stop;
--          see PROGRAMS, below)
--   T      the tour: every program in the library, in turn (it starts with it)
--   R      set it back: the balls to the top, all to 0, COUNT on, the rest off
--   Z      slow motion (1/4) <-> real time
--
-- EVERY PART CAN BE PRINTED: see parts/ and README.md. What is printed is
-- what is simulated: every wall, peg, hole, rocker, foot, flap and the wheel
-- are the shapes in digicomp2-geometry.lua, from which parts/geometry.scad
-- is written.
--
-- PHYSICS: 1/2 inch steel balls (8.35 g); PLA rockers with a 1/4 inch steel
-- ball pressed into each and a PLA foot (5.45 g in all), friction 0.3, no
-- bounce, the board at 15 degrees, 2400 steps a second. The rockers and
-- flaps turn on their pins against a friction torque (DC_PF, 0.4 kg
-- cm^2/s^2: see FINDINGS.md). The feeder's knob is turned by the hand (a
-- motor: the operator's), and the hand sets the switches and flip-flops,
-- puts balls from the collector back into the input when it runs low, and
-- stops at STOP.
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
-- between a reading and the next ball in the tour, 1), DC_SHOW (s the next
-- ball's path is shown before it is let go, 1.5), DC_STEP (begin the tour
-- at that program of the library), DC_PROGRAM (one program, or "all"),
-- DC_REST=0.
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
-- (the sign's letters from sign.scad alone: changing the machine leaves them
-- in bpp's cache)
local SIGN = (SCAD:gsub("digicomp2%.scad$", "sign.scad"))
local SIGN_SUM = checksum({ SIGN })
local function signPart(call)
  local m = OpenSCAD("// " .. SIGN_SUM .. "\ninclude <" .. SIGN .. ">\nscale(0.1) " .. call .. ";\n", 0, false)
  m.collides = false
  return m
end

-- ---------------------------------------------------------------------
-- sliders, timing, the pause at every start
-- ---------------------------------------------------------------------
local G_ = 981
v:addParam("friction", envnum("DC_FRICTION", 0.3), 0.1, 0.6, 0.05, "ball on wall, rocker and board (0.2 to 0.6 checked)")
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
                   done = "#d9d4c5", overflow = "#9b1c1c", clear = "#2f8c5a", drop = "#c9a14a", collector = "#7a5a3a",
                   lane = "#d9d4c5", doneLane = "#b9b2d6", guide = "#d9d4c5", router = "#9fb7cc", stop = "#9b1c1c", ["return"] = "#8a8f96" }
local ROLE_TEXT = {
  housing = "the feeder's housing: it holds the balls in the wheel's notches",
  queue = "the INPUT channel: the balls waiting at the feeder",
  rim = "the board's rim",
  switch = "a switch's channels: its flap sends a ball out of one outlet or the other",
  done = "a done hole: a ball that set its flip-flop to 1 drops through it to the lower level",
  overflow = "OVERFLOW: a carry out of the 64s (the 128th ball) drops through here",
  clear = "the clear lane (lower level): a ball here pushes every flip-flop at 1 back to 0",
  drop = "a drop hole: the ball goes down to the lower level and counts nothing",
  lane = "a lane: it carries the ball on to the next part",
  guide = "a guide: it keeps a carry, falling to the next flip-flop, from drifting out past its funnel",
  doneLane = "a done lane: with COMPLEMENT on (the done hole covered) it carries the ball on into the next flip-flop",
  router = "the distributor's and the MQ's channels and funnels",
  stop = "STOP: a borrow out of the MQ (it was 0) drops through here, and the hand stops turning the knob",
  ["return"] = "the return lane (lower level): what the memory drops, and STOP's ball, roll down it to the collector",
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
-- the flip-flops: rocker, steel ball, stem and foot, one body on its pin;
-- thirteen alike: A1 .. A7, D1 .. D3, MQ1 .. MQ3
-- ---------------------------------------------------------------------
local PF = envnum("DC_PF", 0.4)        -- the pins' friction (kg cm^2/s^2): see FINDINGS
local flips, flip = {}, {}
local yc = F.Y0 + F.H / 2
local flipPieces = {}
for _, pc in ipairs(F.pieces) do flipPieces[#flipPieces + 1] = { pc, F.Y0, F.H } end
for _, l in ipairs(F.lower) do flipPieces[#flipPieces + 1] = l end
local LEAN = math.rad(F.ALPHA - 0.3)              -- (set by hand: just short of its stop, then it settles)
local function flipPose(t, b) return poseAt(t.x, t.z, F.cx, yc, F.cz, b == 1 and -LEAN or LEAN) end
for i, t in ipairs(G.rockers) do
  local tr = flipPose(t, 0)
  local body = btRigidBody(F.mass, btDefaultMotionState(tr), piecesShape(flipPieces, F.cx, yc, F.cz), btVector3(F.I, F.I, F.I))
  local frame = string.format("translate([%.4f, %.4f, %.4f])", -F.cx * 10, -yc * 10, -F.cz * 10)
  local o = part(frame .. " rocker()")
  o.body = body
  o.col = t.kind == "A" and "#f4ecd6" or (t.kind == "D" and "#d7e4ef" or "#efd9d2")
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
  foot.col = t.kind == "A" and "#2f8c5a" or "#8a8f96"
  v:add(foot)
  -- its pin (drawn only: the hinge is the pin), from the lower board up
  local pin = Cylinder(F.PIN_R, F.Y0 + F.H + 0.1 - YL, 0)
  pin.collides = false
  pin.col = "#b8bcc2"
  v:add(pin)
  pin.trans = btTransform(BQ * zToY, W3(t.x, (YL + F.Y0 + F.H + 0.1) / 2, t.z))
  flips[i] = { t = t, name = t.name, body = body, hinge = h, obj = o, riders = { wt, foot } }
  flip[t.name] = flips[i]
  key(o, { flip = t.name }); key(foot, { foot = t.name })
end
-- a flip-flop's lean: 1 with its apex to the right (a clockwise lean as you
-- look), and the lean in degrees
local function lean(name)
  local a = flip[name].body:getCenterOfMassTransform():getBasis():getColumn(0)
  local bz = -a.y * sT + a.z * cT
  return bz > 0 and 1 or 0, math.deg(math.atan2(bz, a.x))
end
local function bitOf(n, k) return math.floor(n / 2 ^ (k - 1)) % 2 end
local function bit(k) return (lean("A" .. k)) end
-- the accumulator; the MQ (read the other way: 1 with the apex left)
local function count()
  local n = 0
  for k = 1, G.NBITS do n = n + bit(k) * 2 ^ (k - 1) end
  return n
end
local function mq()
  local n = 0
  for k = 1, 3 do n = n + (1 - lean("MQ" .. k)) * 2 ^ (k - 1) end
  return n
end
local function binary(n, w)
  local s = ""
  for k = (w or G.NBITS) - 1, 0, -1 do s = s .. math.floor(n / 2 ^ k) % 2 end
  return s
end
local function bits() return binary(count()) end

-- ---------------------------------------------------------------------
-- the switches: flaps on pins, set by hand
-- ---------------------------------------------------------------------
-- (a flap against its RIGHT wall sends the ball left. Each switch's "on"
-- sends the ball one way: MULTIPLY left, to the distributor; CLEAR right,
-- into the clear lane; COUNT left, into A1; the memory's right, into A)
local SW = G.SWITCH
local switches = {}
local swAng = math.rad(SW.ANG - 0.5)
local scz = -SW.FL / 2
local syc = SW.Y0 + SW.H / 2
local flapPieces = { { { { -SW.FT / 2, -SW.FL }, { SW.FT / 2, -SW.FL }, { SW.FT / 2, 0 }, { -SW.FT / 2, 0 } }, SW.Y0, SW.H } }
local function swPose(s, on)
  local left = (on and s.on == -1) or (not on and s.on == 1)      -- (the ball goes left)
  return poseAt(s.x, s.z, 0, syc, scz, left and -swAng or swAng)
end
for _, s in ipairs(G.switchList) do
  local tr = swPose(s, false)
  local body = btRigidBody(SW.mass, btDefaultMotionState(tr), piecesShape(flapPieces, 0, syc, scz), btVector3(SW.I, SW.I, SW.I))
  local o = part(string.format("translate([0, %.4f, %.4f]) flap()", -syc * 10, -scz * 10))
  o.body = body
  o.col = s.name:sub(1, 1) == "M" and s.name ~= "MULTIPLY" and "#b5543c" or "#c9a14a"
  o.collides = true
  v:add(o)
  body:setCenterOfMassTransform(tr)
  body:setActivationState(4)
  local h = pinned(body, s.x, syc, s.z, 0, scz)
  if PF > 0 then h:enableAngularMotor(true, 0, PF * STEP) end
  switches[s.name] = { s = s, body = body, hinge = h, obj = o, name = s.name }
  key(o, { switch = s.name })
end
-- is a switch on (its flap sending the ball its "on" way)?
local function isOn(name)
  local sw = switches[name]
  local a = sw.body:getCenterOfMassTransform():getBasis():getColumn(2)   -- (its z axis: from its end to its pin)
  local left = a.x < 0
  return (left and sw.s.on == -1) or (not left and sw.s.on == 1)
end
-- the memory, as its switches are set
local function mem()
  local n = 0
  for k = 1, 4 do if isOn("M" .. k) then n = n + 2 ^ (k - 1) end end
  return n
end

-- ---------------------------------------------------------------------
-- COMPLEMENT: the six shutters over A1 .. A6's done holes, their pins and
-- the bar joining them: one rigid thing, slid across by hand (X). To the
-- left (on), every done hole is covered, and a ball turns over every
-- flip-flop below where it came in; to the right (off), they are open
-- ---------------------------------------------------------------------
local SHT = G.SHUTTER
local comp = { on = false }
do
  local pcs = {}
  local function circ(x, z, r, n)
    local c = {}
    for j = 0, n - 1 do local a = 2 * math.pi * j / n; c[#c + 1] = { x + r * math.cos(a), z + r * math.sin(a) } end
    return c
  end
  for _, sh in ipairs(G.shutters) do
    pcs[#pcs + 1] = { sh.pieces[1], -SHT.T, SHT.T }
    pcs[#pcs + 1] = { circ(sh.pin[1], sh.pin[2], SHT.PIN[2], 8), 0, SHT.BAR_Y0 }
  end
  pcs[#pcs + 1] = { SHT.bar, SHT.BAR_Y0, SHT.BAR_H }
  pcs[#pcs + 1] = { circ(SHT.knob[1], SHT.knob[2], SHT.KNOB_R, 12), SHT.BAR_Y0 + SHT.BAR_H, SHT.KNOB_H }
  local tr = btTransform(BQ, W3(SHT.TRAVEL, 0, 0))
  local body = btRigidBody(0, btDefaultMotionState(tr), piecesShape(pcs, 0, 0, 0), btVector3(0, 0, 0))
  local o = part("union() { for (i = [0 : len(SHUTTERS) - 1]) shutter(i); complementBar(); compKnob(); }")
  o.body = body
  o.col = "#6c7a89"
  o.collides = true
  v:add(o)
  o.trans = tr
  fixed[#fixed + 1] = o
  comp.obj, comp.body = o, body
  key(o, { comp = true })
end
local function setComplement(on)
  comp.on = on
  comp.obj.trans = btTransform(BQ, W3(on and 0 or SHT.TRAVEL, 0, 0))
end
local function isComplement() return comp.on end

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
-- waiting at the feeder: in the INPUT channel or the wheel
local function waiting(b)
  local x, y, z = ballAt(b)
  return y > -PT and math.abs(x - WH.x) < 1.6 and z < WH.z + 0.5
end

-- ---------------------------------------------------------------------
-- the hand: sets the flip-flops and the switches, turns the knob, puts the
-- balls back
-- ---------------------------------------------------------------------
local function setFlip(name, b) place(flip[name].body, flipPose(flip[name].t, b)) end
local function setBit(k, b) setFlip("A" .. k, b) end
local function setA(n) for k = 1, G.NBITS do setBit(k, bitOf(n, k)) end end
local function setMQ(n) for k = 1, 3 do setFlip("MQ" .. k, 1 - bitOf(n, k)) end end
-- the distributor set to begin a cycle: the first ball of every four goes to the MQ
local D_START = { 1, 1, 0 }
local function setD() for k = 1, 3 do setFlip("D" .. k, D_START[k]) end end
local function setSwitch(name, on) local s = switches[name]; place(s.body, swPose(s.s, on)) end
local function setM(n) for k = 1, 4 do setSwitch("M" .. k, bitOf(n, k) == 1) end end
local function reload()
  place(wheel.body, btTransform(BQ, W3(WH.x, wheel.y, WH.z)))
  wheel.turned, wheel.target, wheel.last = 0, 0, wheel.hinge:getHingeAngle()
  for i, b in ipairs(balls) do place(b.body, btTransform(ident, ballHome(i))) end
end
-- when the INPUT runs low, the hand takes balls from the collector and puts
-- them in at its top (as you would: there are twelve balls, and a multiply
-- can take more)
local REFILL_AT = 4
local refilled = 0
local function refill()
  local w, top = 0, WH.z - WH.ballR
  for _, b in ipairs(balls) do
    if waiting(b) then local _, _, z = ballAt(b); w = w + 1; top = math.min(top, z) end
  end
  if w >= REFILL_AT then return false end
  local n = 0
  for _, b in ipairs(balls) do
    if collected(b) and w + n < 10 then
      n = n + 1
      place(b.body, btTransform(ident, W3(WH.x, G.R + 0.002, top - n * (2 * G.R + 0.005))))
    end
  end
  refilled = refilled + n
  return n > 0
end

-- ---------------------------------------------------------------------
-- the sign beside it, the exhibit's (not the machine's): what the
-- registers read. The machine shows them by its rockers' lean and its
-- switches (and the 0 and 1 printed beside them); the script reads them
-- for the sign. Under them, THIS BALL: what the next ball will do, and
-- what the accumulator was and will be (worked out from the readings, as
-- you would: see "where the next ball goes", below).
-- ---------------------------------------------------------------------
local sign, say
local SAYINGS = {
  count = "COUNT: into A1, it adds 1",
  clear = "CLEAR: down the clear lane, A to 0",
  none = "both off: it drops out, adds nothing",
  M4 = "D1, D2, the MQ less one, M4: adds 8",
  M4z = "D1, D2, the MQ less one, M4 is 0",
  M1 = "D1, D3, M1: adds 1",
  M1z = "D1, D3, M1 is 0: adds nothing",
  M3 = "D1, D2, M3: adds 4",
  M3z = "D1, D2, M3 is 0: adds nothing",
  M2 = "D1, D3, M2: adds 2",
  M2z = "D1, D3, M2 is 0: adds nothing",
  stop = "D1, D2, the MQ is 0: STOP",
  countC = "COMPLEMENT: into A1, it turns every bit over",
  M4C = "D1, D2, the MQ less one, M4: turns over the 8s and up",
  M1C = "D1, D3, M1: turns over every bit",
  M3C = "D1, D2, M3: turns over the 4s and up",
  M2C = "D1, D3, M2: turns over the 2s and up",
}
do
  -- (laid out at a size, then everything drawn K times as large)
  local K = 1.35
  local SW_, SH_ = 24, 23
  local SX, SZ, TILT = -(BW / 2 + 1.2 + SW_ * K / 2), BD / 2 - 30, math.rad(-25)   -- (on the table, left of the board)
  local q = btQuaternion(btVector3(1, 0, 0), TILT)
  local back = Cube(SW_ * K, SH_ * K, 0.8, 0)
  back.col = "#1d1712"
  v:add(back)
  local up = btVector3(0, math.cos(TILT), math.sin(TILT))      -- (the sign's own up, leaning back)
  local function at(u, w, d)                                    -- (across, up, out of its face)
    return btVector3(SX + u * K, SH_ * K / 2 + 2 + up.y * w * K, SZ + up.z * w * K + d * math.cos(TILT))
  end
  back.trans = btTransform(q, at(0, 0, 0))
  local stem = Cube(2, 4, 2, 0)
  stem.col = "#2b2b2b"; stem.collides = false
  v:add(stem)
  stem.trans = btTransform(ident, btVector3(SX, 2, SZ))
  key(back, "the exhibit's sign, not the machine's: the script reads the rockers and switches for it")
  local L0 = -SW_ / 2 + 1.0
  local function line(t, size, u, w)
    local m = signPart(string.format('signText("%s", %d)', t, math.floor(size * K + 0.5)))
    m.col = "#efe6cf"
    v:add(m)
    m.trans = btTransform(q, at(u, w, 0.45))
    return m
  end
  line("THE DIGI-COMP II", 10, L0, 9.4)
  local AWAY = btTransform(ident, btVector3(0, -500, 0))
  -- a cell that shows one of several characters
  local function cell(chars, size, u, w)
    local c = { parts = {}, shown = nil, tr = btTransform(q, at(u, w, 0.45)) }
    for i = 1, #chars do
      local ch = chars:sub(i, i)
      local m = signPart(string.format('signText("%s", %d)', ch, math.floor(size * K + 0.5)))
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
  -- a register: its name, its bits, "=", the number
  local function register(name, nb, nd, size, w)
    line(name, size, L0, w)
    local p = size / 9
    local bc, dc = {}, {}
    local u = L0 + 3.2 * p
    for i = 1, nb do bc[i] = cell("01", size, u + (i - 1) * 1.15 * p, w) end
    u = u + nb * 1.15 * p + 0.3
    line("=", size, u, w)
    for i = 1, nd do dc[i] = cell("0123456789", size, u + 1.6 * p + (i - 1) * 1.15 * p, w) end
    return function(n)
      local b = binary(n, nb)
      for i = 1, nb do bc[i].show(b:sub(i, i)) end
      local d = string.format("%" .. nd .. "d", n)
      for i = 1, nd do local ch = d:sub(i, i); dc[i].show(ch ~= " " and ch or nil) end
    end
  end
  local showA = register("A", G.NBITS, 3, 10, 6.3)
  local showM = register("M", 4, 2, 8, 3.2)
  local showQ = register("MQ", 3, 1, 8, 0.6)
  local bal = { cell("0123456789", 7, L0 + 8.2, -2.0), cell("0123456789", 7, L0 + 9.0, -2.0) }
  line("balls in:", 7, L0, -2.0)
  local rule = Cube((SW_ - 2) * K, 0.12, 0.1, 0)
  rule.col = "#c9a14a"; rule.collides = false
  v:add(rule)
  rule.trans = btTransform(q, at(0, -3.6, 0.45))
  line("THIS BALL", 7, L0, -5.0)
  -- (each saying a part of its own, shown in its place when it is the one)
  local says, shown = {}, nil
  local sayTr = btTransform(q, at(L0, -7.6, 0.45))
  for k, t in pairs(SAYINGS) do
    local m = signPart(string.format('signText("%s", %d)', t, math.floor(6 * K + 0.5)))
    m.col = "#f2c94c"
    v:add(m)
    m.trans = AWAY
    says[k] = m
  end
  line("A was", 6, L0, -10.1)
  line("and will be", 6, L0 + 6.2, -10.1)
  local was, will = {}, {}
  for i = 1, 3 do
    was[i] = cell("0123456789", 6, L0 + 3.4 + (i - 1) * 0.75, -10.1)
    will[i] = cell("0123456789", 6, L0 + 11.6 + (i - 1) * 0.75, -10.1)
  end
  local function digits(cs, n)
    local d = n and string.format("%3d", n) or "   "
    for i = 1, 3 do local ch = d:sub(i, i); cs[i].show(ch ~= " " and ch or nil) end
  end
  sign = function(n, m, q_, nb)
    showA(n); showM(m); showQ(q_)
    local e = string.format("%2d", math.min(nb, 99))
    bal[1].show(e:sub(1, 1) ~= " " and e:sub(1, 1) or nil); bal[2].show(e:sub(2, 2))
  end
  -- what the next ball will do (key: one of SAYINGS; nil clears it)
  say = function(k, a0, a1)
    if shown ~= k then
      if shown then says[shown].trans = AWAY end
      if k then says[k].trans = sayTr end
      shown = k
    end
    digits(was, k and a0); digits(will, k and a1)
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

-- STOP: the hand watches for a ball dropping through it
local stopSeen = false
local function watchStop()
  for _, b in ipairs(balls) do
    local x, y, z = ballAt(b)
    if y < 0 and math.abs(x - G.stop[1]) < 1.2 and math.abs(z - G.stop[2]) < 1.2 then stopSeen = true end
  end
end

-- OVERFLOW: the hand watches for a ball dropping through it too (dividing,
-- it stops at the end of that cycle; see the tour)
local overSeen = false
local function watchOverflow()
  for _, b in ipairs(balls) do
    local x, y, z = ballAt(b)
    if y < 0 and math.abs(x - G.overflow[1]) < 1.2 and math.abs(z - G.overflow[2]) < 1.2 then overSeen = true end
  end
end

local dropped = 0
local function feed() queue = queue + 1 end
local function setUp()
  setA(0); setMQ(0); setD(); setM(0)
  setSwitch("MULTIPLY", false); setSwitch("CLEAR", false); setSwitch("COUNT", true)
  setComplement(false)
  reload()
  applyFriction()
  dropped, refilled, stopSeen, overSeen = 0, 0, false, false
  handMoved()
  holdStart()
end

-- ---------------------------------------------------------------------
-- the tour: the program library (programs/; see PROGRAMS, below), one
-- after another, every ball checked against what the machine should do
-- ---------------------------------------------------------------------
local LOG = os.getenv("DC_LOG")
local TOUR_AT_START = (os.getenv("DC_TOUR") or "1") ~= "0"
local TOUR_PAUSE = envnum("DC_PAUSE", 1.0)
local SHOW_S = envnum("DC_SHOW", 1.5)          -- (s: the next ball's path shown before it is let go)
local CONTACTS = tonumber(os.getenv("DC_CONTACTS") or "")
local frameNow = 0
-- what the machine reads now, and what one more ball should make of it
local function reading()
  return { A = count(), MQ = mq(), d = { (lean("D1")), (lean("D2")), (lean("D3")) }, M = mem(),
           mult = isOn("MULTIPLY"), clear = isOn("CLEAR"), count = isOn("COUNT"), comp = isComplement() }
end
-- (a ball into A at place k: counting on, or with COMPLEMENT on, turning
-- over every flip-flop from k up; over, if it goes out of A7 to the left)
local function intoA(a, k, c)
  if c then
    local over = bitOf(a, G.NBITS) == 1
    for j = k, G.NBITS do a = a + (1 - 2 * bitOf(a, j)) * 2 ^ (j - 1) end
    return a, over
  end
  local n = a + 2 ^ (k - 1)
  return n % 128, n >= 128
end
local function predict(s)
  local p = { A = s.A, MQ = s.MQ, d = { s.d[1], s.d[2], s.d[3] }, stop = false, over = false }
  if s.mult then
    -- (a flip-flop at 1 sends the ball left and goes to 0; at 0, right and to 1)
    local out
    if p.d[1] == 1 then
      p.d[1] = 0
      if p.d[2] == 1 then p.d[2] = 0; out = "MQ" else p.d[2] = 1; out = 3 end
    else
      p.d[1] = 1
      if p.d[3] == 1 then p.d[3] = 0; out = 2 else p.d[3] = 1; out = 1 end
    end
    if out == "MQ" then
      if p.MQ == 0 then p.MQ, p.stop, out = 7, true, nil else p.MQ, out = p.MQ - 1, 4 end
    end
    if out and bitOf(s.M, out) == 1 then p.A, p.over = intoA(p.A, out, s.comp) end
  elseif s.clear then p.A = 0
  elseif s.count then p.A, p.over = intoA(p.A, 1, s.comp) end
  return p
end
-- ---------------------------------------------------------------------
-- where the next ball goes: worked out from what the machine reads now (as
-- you would, from the rockers and the switches), drawn on the board as a
-- path, and said on the sign. The exhibit's, not the machine's: the ball
-- goes where the rockers send it, and the tour checks that it went there.
-- ---------------------------------------------------------------------
local RT = F.A + 1.4 + G.R + F.RUN                -- a flip-flop's run: its top, up from the pin
local function swTop(s) return { s.x, s.z - SW.FL - SW.DROP } end
local function swPin(s) return { s.x, s.z - 0.4 } end
local function swOut(s, side) return { s.x + side * SW.OX, s.z + SW.OUT } end
local function route(s)
  local up, low = {}, {}                          -- (points on the upper level; then on the lower)
  local key
  local function add(p) up[#up + 1] = p end
  local function into(t) add({ t.x, t.z - RT }); add({ t.x, t.z - F.A - G.R * 0.5 }) end
  local function out(t, side) add({ t.x + side * 2.3, t.z + 0.2 }) end
  local function lane(name, from)
    for i, p in ipairs(G.lanes[name]) do if i >= (from or 1) then add(p) end end
  end
  local function drop(p) add(p); low = { p, { p[1], p[2] + 1.5 } } end
  -- into A at place k: on through every 1 (the carry), out at the first 0;
  -- with COMPLEMENT on, through every flip-flop to the end (a 0's done lane
  -- leads on to the next)
  local function intoA(k)
    while true do
      local t = G.rocker["A" .. k]
      into(t)
      if bitOf(s.A, k) == 0 then
        out(t, 1)
        if not s.comp or k == G.NBITS then drop(t.done); return end
        add(t.done); lane("done " .. k, 2)
      else
        out(t, -1)
        if k == G.NBITS then drop(G.overflow); return end
      end
      k = k + 1
    end
  end
  -- a memory switch: at 1, into A; at 0, it drops
  local function memory(k)
    local m = G.switches["M" .. k]
    add(swPin(m))
    if bitOf(s.M, k) == 1 then add(swOut(m, 1)); intoA(k); key = "M" .. k .. (s.comp and "C" or "")
    else drop(m.dropHole); key = "M" .. k .. "z" end
  end
  local Wd = WH.ballR
  add({ WH.x, WH.z - Wd }); add({ WH.x + Wd, WH.z }); add({ WH.x, WH.z + Wd })
  local mu = G.switches.MULTIPLY
  add(swTop(mu)); add(swPin(mu))
  if s.mult then
    add(swOut(mu, -1))
    local R_ = G.rocker
    into(R_.D1)
    if s.d[1] == 1 then
      out(R_.D1, -1); into(R_.D2)
      if s.d[2] == 1 then
        out(R_.D2, -1)
        -- the MQ: a borrow on to the left while it finds its apex right
        local k = 1
        while true do
          local t = R_["MQ" .. k]
          into(t)
          if bitOf(s.MQ, k) == 0 then
            out(t, -1)
            if k == 3 then drop(G.stop); key = "stop"; return up, low, key end
            k = k + 1
          else
            out(t, 1)
            for j = k, 2 do lane("MQ" .. j .. " on"); add({ R_["MQ" .. (j + 1)].x + G.DX, R_["MQ" .. (j + 1)].z + G.DZ - RT }) end
            lane("MQ to M4", k == 3 and 1 or 2)
            break
          end
        end
        memory(4)
      else
        out(R_.D2, 1); lane("D2 to M3"); memory(3)
      end
    else
      out(R_.D1, 1); lane("D1 to D3"); into(R_.D3)
      if s.d[3] == 1 then out(R_.D3, -1); lane("D3 to M2"); memory(2)
      else out(R_.D3, 1); lane("D3 to M1"); memory(1) end
    end
  else
    add(swOut(mu, 1)); lane("MULTIPLY off", 2)
    local c = G.switches.CLEAR
    add(swPin(c))
    if s.clear then
      add(swOut(c, 1)); add(G.clearDrop)
      low = {}
      for _, p in ipairs(G.clearLane) do low[#low + 1] = p end
      key = "clear"
    else
      add(swOut(c, -1))
      local n = G.switches.COUNT
      add(swPin(n))
      if s.count then add(swOut(n, -1)); intoA(1); key = s.comp and "countC" or "count"
      else add(swOut(n, 1)); drop(G.countOffDrop); key = "none" end
    end
  end
  return up, low, key
end
-- the path, drawn: a dashed line a little over the plate (and over the
-- lower level), not part of the machine (nothing touches it). The dashes
-- are all alike, so the same few hundred serve every path.
local DASH, GAPD, DASH_N = 0.55, 0.35, 360
local dashes = {}
local DASH_AWAY = btTransform(ident, btVector3(0, -500, 0))
local function showPath(up, low)
  local n = 0
  local function line(P, y)
    local carry = 0                                 -- (how far along the next dash starts)
    for i = 1, #(P or {}) - 1 do
      local a, b = P[i], P[i + 1]
      local dx, dz = b[1] - a[1], b[2] - a[2]
      local len = math.sqrt(dx * dx + dz * dz)
      if len > 1e-6 then
        local q = yq(math.atan2(-dz, dx))
        local t = carry
        while t + DASH / 2 <= len do
          n = n + 1
          if n > DASH_N then return end
          local c = dashes[n]
          if not c then
            c = Cube(DASH, 0.04, 0.4, 0)
            c.collides = false
            c.col = "#ffd23f"
            v:add(c)
            dashes[n] = c
          end
          local f = (t + DASH / 2) / len
          c.trans = btTransform(q, W3(a[1] + dx * f, y, a[2] + dz * f))
          t = t + DASH + GAPD
        end
        carry = t - len
      end
    end
  end
  line(up, 0.04)
  line(low, YL + 0.04)
  for i = n + 1, #dashes do dashes[i].trans = DASH_AWAY end
end
local function hidePath() showPath(nil, nil); say(nil) end
-- before a ball: where it will go, on the board and the sign
local function preview()
  local s = reading()
  local up, low, k = route(s)
  local p = predict(s)
  showPath(up, low)
  say(k, s.A, p.A)
  local text = SAYINGS[k] .. string.format(" (A %d -> %d)", s.A, p.A)
  return text
end

local function checkBall(t)
  local now = reading()
  local p = predict(t.before)
  local c = nCollected()
  local ok = now.A == p.A and now.MQ == p.MQ and now.d[1] == p.d[1] and now.d[2] == p.d[2] and now.d[3] == p.d[3]
             and stopSeen == p.stop and t.overNow == p.over and c + refilled == dropped
  local why = ok and "right" or string.format("WRONG: should be A %d, MQ %d, D %d%d%d%s%s", p.A, p.MQ, p.d[1], p.d[2], p.d[3],
                                              p.stop and ", STOP" or "", p.over and ", OVERFLOW" or "")
  if LOG == "3" then
    for _, b in ipairs(balls) do local x, y, z = ballAt(b); print(string.format("      ball %d at %.1f %.1f %.1f%s", b.n, x, y, z, collected(b) and " (collected)" or "")) end
  end
  local an = {}
  if LOG then for _, fl in ipairs(flips) do local _, a = lean(fl.name); an[#an + 1] = string.format("%s %.0f", fl.name, a) end end
  print(string.format("    ball %d:  A %s = %d, MQ %d, D %d%d%d%s%s  (%d in the collector)  %s%s", dropped, bits(), now.A, now.MQ,
                      now.d[1], now.d[2], now.d[3], stopSeen and ", STOP" or "", t.overNow and ", OVERFLOW" or "", c, why,
                      LOG and ("\n      leans " .. table.concat(an, ", ")) or ""))
  return ok
end

-- ---------------------------------------------------------------------
-- PROGRAMS: what the operator does, written down and run by the hand, line
-- by line. A program is a text file in programs/ (the library: the files
-- listed in programs/LIBRARY, in order). Each line holds steps, the same
-- keys as on the keyboard, and ';' begins a comment. The first comment
-- line is its title. Steps:
--   R                  reset: A, M and MQ 0, D set to start, COUNT on, the
--                      other switches off, COMPLEMENT off
--   1 .. 7             turn A1 .. A7 over by hand
--   H J K L            M1 .. M4 over         8 9 0   MQ1 .. MQ3 over
--   D                  set the distributor to start a cycle
--   M C N X            MULTIPLY, CLEAR, COUNT, COMPLEMENT on <-> off
--   Space              START: one ball
--   SET A n, SET M n, SET MQ n     set a register to n by hand
--   UNTIL STOP         balls until one drops through STOP
--   UNTIL OVERFLOW     balls until one drops through OVERFLOW
--   UNTIL CYCLE        balls until the next would begin a cycle (D1 and D2
--                      read 1); none if it would already
--   CHECK A n, CHECK M n, CHECK MQ n   say whether the register reads n
-- While it runs, the listing is in the help (Shortcuts) pane with an arrow
-- at the line being done, the line itself in the status bar, and every
-- ball is shown before it goes (the dashed line, the sign) and checked
-- after, as in the tour. G runs the program chosen with the "program"
-- slider (G again stops it); DC_PROGRAM=name (or "all") runs one headless.
-- ---------------------------------------------------------------------
local refillWait = 0                  -- (s: the hand has just put balls back; see stepping)
-- (the programs' state and functions, in one table: PR.prog the program
-- running, PR.run the ones DC_PROGRAM runs, PR.fails how they went, PR.help
-- the exhibit's help, below, under the listing)
local PR = { prog = nil, run = nil, fails = 0, help = "" }
do
local PROG_DIR = DIR .. "programs/"
local function readLines(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local t = {}
  for l in f:lines() do t[#t + 1] = (l:gsub("\r$", "")) end
  f:close()
  return t
end
local KEY_STEP = { R = true, ["1"] = true, ["2"] = true, ["3"] = true, ["4"] = true, ["5"] = true, ["6"] = true,
                   ["7"] = true, H = true, J = true, K = true, L = true, ["8"] = true, ["9"] = true, ["0"] = true,
                   D = true, M = true, C = true, N = true, X = true }
local REGISTER = { A = true, M = true, MQ = true }
local UNTIL = { STOP = true, OVERFLOW = true, CYCLE = true }
local function parseProgram(file)
  local lines = readLines(PROG_DIR .. file)
  if not lines then return nil, "can't read programs/" .. file end
  local p = { file = file, lines = lines, ops = {}, title = file }
  local titled = false
  for i, line in ipairs(lines) do
    local code, comment = line, nil
    local c = line:find(";", 1, true)
    if c then code, comment = line:sub(1, c - 1), line:sub(c + 1) end
    if not titled and comment and code:match("^%s*$") then
      p.title = comment:match("^%s*(.-)%s*$"); titled = true
    end
    local toks = {}
    for w in code:gmatch("%S+") do toks[#toks + 1] = w end
    local j = 1
    local function bad(what) return nil, string.format("programs/%s, line %d: %s", file, i, what) end
    while j <= #toks do
      local W = toks[j]:upper()
      if W == "SPACE" then p.ops[#p.ops + 1] = { line = i, op = "ball" }
      elseif W == "SET" or W == "CHECK" then
        local reg, n = (toks[j + 1] or ""):upper(), tonumber(toks[j + 2] or "")
        if not REGISTER[reg] or not n then return bad(W .. " wants a register (A, M or MQ) and a number") end
        p.ops[#p.ops + 1] = { line = i, op = W:lower(), reg = reg, n = n }
        j = j + 2
      elseif W == "UNTIL" then
        local what = (toks[j + 1] or ""):upper()
        if not UNTIL[what] then return bad("UNTIL wants STOP, OVERFLOW or CYCLE") end
        p.ops[#p.ops + 1] = { line = i, op = "until", what = what }
        j = j + 1
      elseif KEY_STEP[W] then p.ops[#p.ops + 1] = { line = i, op = "key", key = W }
      else return bad("what is \"" .. toks[j] .. "\"?") end
      j = j + 1
    end
  end
  return p
end
-- the library
local library = {}
do
  for _, l in ipairs(readLines(PROG_DIR .. "LIBRARY") or {}) do
    local f = l:gsub(";.*", ""):match("^%s*(.-)%s*$")
    if f ~= "" then
      local p, err = parseProgram(f)
      if p then library[#library + 1] = p else print("DIGI-COMP II: " .. err) end
    end
  end
end
local function libraryText(sel)
  local t = { "PROGRAMS (the \"program\" slider chooses, G runs it):" }
  for i, p in ipairs(library) do t[#t + 1] = string.format("%s%2d  %s", i == sel and "->" or "  ", i, p.title) end
  return table.concat(t, "\n")
end
local function listing(p, cur)
  local t = {}
  -- (the pane may show only a few lines: the one being done, and the next,
  -- come first; the whole listing after them)
  if cur then
    t[#t + 1] = string.format("PROGRAM: %s, line %d of %d", p.title, cur, #p.lines)
    t[#t + 1] = string.format("->%3d  %s", cur, p.lines[cur])
    for i = cur + 1, #p.lines do
      if p.lines[i]:match("%S") then t[#t + 1] = string.format("  %3d  %s", i, p.lines[i]); break end
    end
    t[#t + 1] = ""
  end
  t[#t + 1] = string.format("PROGRAM: %s   (programs/%s)", p.title, p.file)
  for i, l in ipairs(p.lines) do t[#t + 1] = string.format("%s%3d  %s", i == cur and "->" or "  ", i, l) end
  return table.concat(t, "\n")
end
local function setStatus(t) pcall(function() v.statusText = t end) end
local function showProgram(p, cur)
  v:setHelpText(listing(p, cur) .. "\n\n" .. PR.help)
  local l = cur and p.lines[cur]
  setStatus(l and string.format("%s, line %d:  %s", p.title, cur, l:match("^%s*(.-)%s*$")) or "")
end
-- the hand does one key's step
local function handKey(k)
  if k == "R" then setUp(); hidePath()
  elseif k:match("^[1-7]$") then local b = tonumber(k); setBit(b, 1 - bit(b))
  elseif k == "H" or k == "J" or k == "K" or k == "L" then
    local m = "M" .. ({ H = 1, J = 2, K = 3, L = 4 })[k]
    setSwitch(m, not isOn(m))
  elseif k == "8" or k == "9" or k == "0" then
    local q = "MQ" .. ({ ["8"] = 1, ["9"] = 2, ["0"] = 3 })[k]
    setFlip(q, 1 - lean(q))
  elseif k == "D" then setD()
  elseif k == "M" then setSwitch("MULTIPLY", not isOn("MULTIPLY"))
  elseif k == "C" then setSwitch("CLEAR", not isOn("CLEAR"))
  elseif k == "N" then setSwitch("COUNT", not isOn("COUNT"))
  elseif k == "X" then setComplement(not isComplement()) end
  handMoved()
end
local function regValue(r) if r == "A" then return count() elseif r == "M" then return mem() else return mq() end end
local function startProgram(p)
  queue = 0
  PR.prog = { p = p, i = 1, phase = "next", wait = 0 }
  print(string.format("\nDIGI-COMP II -- program: %s (programs/%s)", p.title, p.file))
  showProgram(p, nil)
end
local function stopProgram(why)
  local p = PR.prog.p
  if why then print("    " .. why) end
  print(string.format("  program %s: %s", p.file, PR.prog.fails == nil and "done" or (PR.prog.fails == 0 and "all right" or (PR.prog.fails .. " WRONG"))))
  PR.fails = PR.fails + (PR.prog.fails or 0)
  PR.prog = nil
  showProgram(p, nil)
  setStatus(p.title .. ": done")
  hidePath()
  -- (headless, DC_PROGRAM=all: the next one)
  if PR.run then
    PR.run.i = PR.run.i + 1
    if PR.run.list[PR.run.i] then startProgram(PR.run.list[PR.run.i])
    else
      print(string.format("  %s (frame %d)", PR.fails == 0 and "all right" or (PR.fails .. " WRONG"), frameNow))
      print("RESULT digicomp2 " .. (PR.run.tour and "tour" or "programs") .. ": " .. (PR.fails == 0 and "PASS" or "FAIL"))
      PR.run = nil
    end
  end
end
-- each frame, while a program runs
local function progStep()
  local P = PR.prog
  P.wait = P.wait + FRAME_DT
  P.fails = P.fails or 0
  local op = P.p.ops[P.i]
  local function nextOp() P.i, P.phase, P.wait = P.i + 1, "next", 0 end
  local function ball()
    P.phase, P.wait = "show", 0
    print("      next: " .. preview())
  end
  if P.phase == "next" then
    if P.wait < 0.15 or busy() then return end
    if not op then stopProgram(); return end
    showProgram(P.p, op.line)
    if op.op == "key" then
      print(string.format("    line %d: %s", op.line, op.key))
      handKey(op.key); P.phase, P.wait = "after", 0
    elseif op.op == "set" then
      print(string.format("    line %d: SET %s %d", op.line, op.reg, op.n))
      if op.reg == "A" then setA(op.n) elseif op.reg == "M" then setM(op.n) else setMQ(op.n) end
      handMoved(); P.phase, P.wait = "after", 0
    elseif op.op == "check" then
      local got = regValue(op.reg)
      local ok = got == op.n
      if not ok then P.fails = P.fails + 1 end
      print(string.format("    line %d: CHECK %s %d: it reads %d  %s", op.line, op.reg, op.n, got, ok and "right" or "WRONG"))
      P.phase, P.wait = "after", 0
    elseif op.op == "ball" then
      print(string.format("    line %d: Space", op.line))
      P.balls = nil; ball()
    elseif op.op == "until" then
      print(string.format("    line %d: UNTIL %s", op.line, op.what))
      P.balls = 0
      if op.what == "CYCLE" then
        local r = reading()
        if r.d[1] == 1 and r.d[2] == 1 then print("      (the next ball would begin a cycle: none)"); nextOp(); return end
      end
      ball()
    end
  elseif P.phase == "after" then
    if P.wait > 0.6 and not busy() then nextOp() end
  elseif P.phase == "show" then
    if P.wait > SHOW_S then
      P.phase, P.wait = "ball", 0; P.before = reading(); stopSeen = false
      P.overBefore = overSeen; feed()
    end
  elseif P.phase == "ball" then
    if not busy() and refillWait <= 0 and P.wait > 0.5 and (still > 0.4 or P.wait > 15) then
      P.overNow = overSeen and not P.overBefore
      if not checkBall(P) then P.fails = P.fails + 1 end
      if op.op == "ball" then P.phase, P.wait = "pause", 0; return end
      P.balls = P.balls + 1
      local done
      if op.what == "STOP" then done = stopSeen
      elseif op.what == "OVERFLOW" then done = P.overNow
      else local r = reading(); done = r.d[1] == 1 and r.d[2] == 1 end
      if stopSeen and op.what ~= "STOP" then
        P.fails = P.fails + 1
        stopProgram(string.format("WRONG: a ball dropped through STOP (UNTIL %s, line %d)", op.what, op.line))
        return
      end
      if done then
        print(string.format("      UNTIL %s: %d ball%s", op.what, P.balls, P.balls == 1 and "" or "s"))
        P.phase, P.wait = "pause", 0
      elseif P.balls >= 64 then
        P.fails = P.fails + 1
        stopProgram(string.format("WRONG: UNTIL %s, line %d: 64 balls and not yet", op.what, op.line))
      else
        P.phase, P.wait = "again", 0
      end
    end
  elseif P.phase == "again" then
    if P.wait > TOUR_PAUSE then ball() end
  elseif P.phase == "pause" then
    if P.wait > TOUR_PAUSE then nextOp() end
  end
end

PR.step, PR.start, PR.stopIt, PR.library, PR.libraryText, PR.listing, PR.setStatus =
  progStep, startProgram, stopProgram, library, libraryText, listing, setStatus
end

-- the tour: every program in the library, in turn
local function startTour()
  print("\nDIGI-COMP II -- the tour: the program library, one after another")
  PR.fails = 0
  local list = {}
  -- (DC_STEP: begin at that program, for testing)
  for i = math.max(1, math.floor(envnum("DC_STEP", 1))), #PR.library do list[#list + 1] = PR.library[i] end
  setUp()
  if #list > 0 then PR.run = { list = list, i = 1, tour = true }; PR.start(list[1]) end
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
  if PR.prog then PR.prog.wait = 0 end
end

v:postSim(function(N)
  frameNow = N
  carryRiders()
  sign(count(), mem(), mq(), dropped)
  if CONTACTS and N == CONTACTS then
    local names = {}
    for _, fl in ipairs(flips) do names[fl.obj] = fl.name end
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
  watchStop()
  watchOverflow()
  if refillWait > 0 then refillWait = refillWait - FRAME_DT end
  if queue > 0 and not handBusy and refillWait <= 0 then
    if refill() then refillWait = 0.6; handMoved() else startTurn() end
  end
  if LOG == "2" and N % 15 == 0 then
    local t = {}
    for _, b in ipairs(balls) do
      if b.body:getLinearVelocity():length() > REST_V then local x, y, z = ballAt(b); t[#t + 1] = string.format("%d (%.1f %.1f %.1f)", b.n, x, y, z) end
    end
    if #t > 0 then print(string.format("  frame %d: A %s; moving: %s", N, bits(), table.concat(t, ", "))) end
  end
  if PR.prog then PR.step() end
end)

-- ---------------------------------------------------------------------
-- keys, sliders, help, hover
-- ---------------------------------------------------------------------
local function byHand(fn) return function() if not PR.prog then fn(); hidePath(); handMoved() end end end
v:addShortcut("Space", function() if not PR.prog then stopSeen = false; preview(); feed() end end)
v:addShortcut("M", byHand(function() setSwitch("MULTIPLY", not isOn("MULTIPLY")) end))
v:addShortcut("C", byHand(function() setSwitch("CLEAR", not isOn("CLEAR")) end))
v:addShortcut("N", byHand(function() setSwitch("COUNT", not isOn("COUNT")) end))
for k = 1, G.NBITS do v:addShortcut(tostring(k), byHand(function() setBit(k, 1 - bit(k)) end)) end
for k, key_ in ipairs({ "H", "J", "K", "L" }) do
  v:addShortcut(key_, byHand(function() setSwitch("M" .. k, not isOn("M" .. k)) end))
end
for k, key_ in ipairs({ "8", "9", "0" }) do
  v:addShortcut(key_, byHand(function() setFlip("MQ" .. k, 1 - lean("MQ" .. k)) end))
end
v:addShortcut("D", byHand(setD))
v:addShortcut("X", byHand(function() setComplement(not isComplement()) end))
v:addShortcut("T", function() PR.prog = nil; PR.run = nil; startTour() end)
v:addShortcut("R", function() PR.prog = nil; PR.run = nil; queue = 0; setUp(); hidePath(); PR.setStatus("") end)
-- programs: the slider chooses, G runs it (G again: stop)
local progSel = 1
if #PR.library > 0 then
  v:addParam("program", 1, 1, #PR.library, 1, "a program from the library (programs/): G runs it")
end
v:addShortcut("G", function()
  if PR.prog then PR.run = nil; PR.stopIt("stopped by hand"); return end
  local p = PR.library[progSel]
  if p then PR.start(p) end
end)
v:addShortcut("Z", function()
  local sp = v:getParam("speed") < 0.5 and 1 or 0.25
  v:addParam("speed", sp, 0.05, 2, 0.05, "simulated seconds per real second (Z: 1/4 <-> 1)")
  applyTiming()
end)
v:onParamChanged(function(N, name, value)
  if name == "program" then
    progSel = math.max(1, math.min(#PR.library, math.floor(value + 0.5)))
    if not PR.prog and PR.library[progSel] then
      v:setHelpText(PR.libraryText(progSel) .. "\n\n" .. PR.listing(PR.library[progSel], nil) .. "\n\n" .. PR.help)
    end
    return
  end
  if name == "speed" or name == "steps" then applyTiming()
  elseif name == "friction" then applyFriction() end
end)

pcall(function()
  PR.help = table.concat({
    "THE DIGI-COMP II  (Babbage's Hall) -- counting, adding, multiplying, subtracting, dividing",
    "",
    "A computer of rolling balls, after E.S.R.'s Digi-Comp II (1968). The rockers",
    "are flip-flops: each leans one way or the other and stays. Apex right is 1,",
    "left 0 (the MQ's the other way round). The seven down the right, read bottom",
    "(64s) to top (1s), are the accumulator, A: 0 to 127.",
    "",
    "WHAT TO WATCH",
    "  COUNT on: a ball meets the 1s rocker on its raised side and tips it over.",
    "  Found at 0, it is set to 1 and the ball drops through the hole on its",
    "  right: done. Found at 1, it is set to 0 and the ball goes on to the next:",
    "  the carry. So every ball adds one.",
    "  CLEAR on: the ball runs down the green lane on the lower level, pushing",
    "  every foot of a rocker at 1 out of its way: all go to 0.",
    "  MULTIPLY on: the balls go to the distributor (D1, D2, D3), which sends",
    "  them four ways by turns: the first of every four through the MQ, which",
    "  takes one away, and on to the memory's 8s; the others to its 1s, 2s, 4s.",
    "  A memory switch at 1 sends its ball into the accumulator at that place.",
    "  So every four balls add the memory to A, once for each count of the MQ;",
    "  when the MQ is used up the next ball drops through STOP. ADD is the same",
    "  with the MQ at 1.",
    "  COMPLEMENT on (X): the done holes of the 1s to the 32s are covered, and a",
    "  ball rolls on over its hole and down a lane into the next rocker: so it",
    "  turns over every rocker below where it came in. With COUNT on, one ball",
    "  turns over all seven: 127 - A. COMPLEMENT off, one more ball adds 1:",
    "  128 - A, the complement, which subtracts when it is added. Dividing is",
    "  adding the divisor to the dividend's complement until A overflows.",
    "  Before each ball, a yellow dashed line on the board shows where it will",
    "  go, and the sign beside it (THIS BALL) says what it will do and what the",
    "  accumulator was and will be. Then watch it do that (Z: slow motion).",
    "",
    "KEYS",
    "  Space  START: one ball     M  MULTIPLY    C  CLEAR    N  COUNT  (on/off)",
    "  X      COMPLEMENT on/off (the shutters over the done holes)",
    "  G      run the program the \"program\" slider chooses (G again: stop)",
    "  1..7   set a rocker of A over by hand (1 = the 1s ... 7 = the 64s)",
    "  H J K L  the memory's 1s, 2s, 4s, 8s    8 9 0  the MQ's 1s, 2s, 4s",
    "  D      set the distributor to start a cycle",
    "  T      the tour: the library, in turn   R  set it back   Z  slow motion",
    "",
    "Every part can be 3D printed: see the README in this exhibit's folder.",
  }, "\n")
  v:setHelpText((#PR.library > 0 and (PR.libraryText(progSel) .. "\n\n") or "") .. PR.help)
end)

local MEM_KEY = { "H", "J", "K", "L" }
local MQ_KEY = { "8", "9", "0" }
if v.onHover then
  v:onHover(function(N, obj, x, y, z)
    local d = KEY[objectKey(obj)]
    if not d then return nil end
    if type(d) == "string" then return d end
    if d.flip then
      local name = d.flip
      local b = lean(name)
      local k = tonumber(name:match("%d+$"))
      local goes = b == 1 and "left, and sets it to 0" or "right, and sets it to 1"
      if name:sub(1, 1) == "A" then
        return string.format("%s, the accumulator's %ds: it reads %d (apex %s)\nthe next ball here goes %s\nthe accumulator: %s = %d",
                             name, 2 ^ (k - 1), b, b == 1 and "right" or "left",
                             b == 1 and "left, to the next flip-flop (a carry), and sets it to 0" or
                                        "right, through its done hole, and sets it to 1", bits(), count())
      elseif name:sub(1, 2) == "MQ" then
        return string.format("%s, the MQ's %ds (key %s): it reads %d (apex %s: the MQ reads the other way)\n" ..
                             "the next ball here goes %s%s\nthe MQ: %s = %d", name, 2 ^ (k - 1), MQ_KEY[k], 1 - b,
                             b == 1 and "right" or "left", goes,
                             b == 1 and (k < 3 and " (a borrow, to the next)" or " (a borrow out of the MQ: STOP)") or " (done: on to the memory's 8s)",
                             binary(mq(), 3), mq())
      else
        local outs = { D1 = { "D2", "D3" }, D2 = { "the MQ", "the memory's 4s" }, D3 = { "the memory's 2s", "the memory's 1s" } }
        local o = outs[name]
        return string.format("%s, the distributor (D sets it to start): it reads %d (apex %s)\nthe next ball here goes %s",
                             name, b, b == 1 and "right" or "left", b == 1 and ("left, to " .. o[1]) or ("right, to " .. o[2]))
      end
    end
    if d.foot then
      if d.foot:sub(1, 1) == "A" then
        return string.format("%s's foot, on the lower level: when the rocker reads 1 its wedge leans\n" ..
                             "into the clear lane, and a clear ball pushes it back to 0 (now: %d)", d.foot, lean(d.foot))
      end
      return string.format("%s's foot: every flip-flop is the same part; only the accumulator's\nhave a clear lane beside them", d.foot)
    end
    if d.switch then
      local n = d.switch
      local on = isOn(n)
      local what = {
        MULTIPLY = { "M", "the ball goes to the distributor, and from it to the MQ and the memory",
                     "the ball goes down to CLEAR and COUNT" },
        CLEAR = { "C", "the ball drops into the clear lane, which sets every flip-flop of A to 0", "the ball goes on to COUNT" },
        COUNT = { "N", "the ball goes into A1 and adds one", "the ball drops to the lower level and counts nothing" },
      }
      local w = what[n]
      if not w then
        local k = tonumber(n:sub(2))
        return string.format("the memory's %ds (%s, key %s): it reads %d\n%s", 2 ^ (k - 1), n, MEM_KEY[k], on and 1 or 0,
                             on and string.format("a ball from the distributor goes into A%d: it adds %d", k, 2 ^ (k - 1))
                                or "a ball from the distributor drops through its hole and adds nothing")
      end
      return string.format("the %s switch (%s: %s to change it by hand)\n%s", n, on and "ON" or "OFF", w[1], on and w[2] or w[3])
    end
    if d.comp then
      return string.format("COMPLEMENT (X): six shutters on one bar, now %s\n%s", isComplement() and "ON" or "OFF",
                           isComplement() and "the done holes of A1 to A6 are covered: a ball rolls on down each one's lane\n" ..
                                              "into the next flip-flop, and turns over every one below where it came in"
                                          or "the done holes are open: a ball that sets a flip-flop to 1 drops through, done")
    end
    if d.ball then return string.format("a ball: 1/2 inch steel, 8.35 g\n%d let in; the accumulator reads %d", dropped, count()) end
    return nil
  end)
end

common.setCamera(btVector3(-6, 185, 135), btVector3(-6, 6, -8))
-- (DC_PROGRAM=name: that program from the library, headless; "all": each in turn)
local DC_PROGRAM = os.getenv("DC_PROGRAM")
if DC_PROGRAM then
  local list = {}
  for _, p in ipairs(PR.library) do
    if DC_PROGRAM == "all" or p.file == DC_PROGRAM or p.file == DC_PROGRAM .. ".dc2" then list[#list + 1] = p end
  end
  setUp()
  if #list > 0 then PR.run = { list = list, i = 1 }; PR.start(list[1])
  else print("DIGI-COMP II: no program " .. DC_PROGRAM .. " in programs/LIBRARY") end
elseif TOUR_AT_START then startTour() else setUp() end
