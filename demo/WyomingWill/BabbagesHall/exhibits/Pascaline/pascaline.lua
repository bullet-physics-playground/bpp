--
-- The Pascaline -- Babbage's Hall
--
-- Blaise Pascal's adding machine of 1642, three digits, with his carry.
-- Each digit is a wheel of ten pins; behind it, a snail cam. As a digit
-- counts from 0 up to 9 its cam lifts a weighted lever, the SAUTOIR
-- ("jumper"), a little at each step. As the digit passes 9 the cam drops
-- away, the sautoir falls, and the pawl hanging from it strikes a pin of
-- the next digit and drives it on by one. Going back up, the pawl swings
-- aside over the pins and falls back to its stop by its own weight.
--
-- Pascal's idea was that the carry's energy is stored as the digit counts
-- -- the lifted weight -- and spent all at once, so a carry never has to
-- be forced through by the hand: 99 + 1 sends the units' sautoir down,
-- which drives the tens past 9, which sends the tens' sautoir down, which
-- drives the hundreds on. Here it does exactly that, by contact and gravity.
--
-- DRIVING IT, as Pascal's was: a stylus in the dial's hole beside the
-- plate's number n, turned clockwise to the finger stop, adds n.
--   the mouse  rest it on a hole: the stylus goes in, and the tooltip says
--              what it will add; Space turns it to the stop
--   U/T/H      choose the units / tens / hundreds (a brass mark below it)
--   1 to 9     add that much to the chosen wheel, in one stroke
--   D     the tour: 7, + 8 = 15, + 84 = 99, + 1 = 100 (it starts with it)
--   R     set it back to 000
--   Z     slow motion (1/4) <-> real time
--
-- EVERY PART CAN BE PRINTED: see parts/ and README.md.
--
-- PHYSICS: the digits' pins and cams, the sautoirs and their pawls are the
-- printed parts' own primitives (pascaline-geometry.lua); they push each
-- other only by contact. A digit is turned by a hand (a motor steered to
-- where the keys put it), forward only; between turns it is held by its
-- detent, a printed PLA leaf spring whose nose rests between two pins
-- (simulated as a body on a hinge at the leaf's root, turned back by the
-- leaf's own stiffness, worked out from PLA's). The sautoir's weight is
-- 60 g of steel; the pawl's tail, 8 g. Friction 0.3 (a slider:
-- 0.15 to 0.45 checked), 2400 steps a second.
--
-- Units: centimetres, kilograms, seconds.
-- Headless: PA_TOUR=0 (no tour), PA_FRICTION, PA_RATE (the hand's speed,
-- turns a second); the tour prints RESULT pascaline tour: PASS or FAIL.
--

local common = require "common"
local function envnum(n, d) return tonumber(os.getenv(n) or "") or d end

-- ---------------------------------------------------------------------
-- this exhibit's folder; its geometry; the parts file by its full path
-- ---------------------------------------------------------------------
local DIR
for _, d in ipairs({ "", "demo/WyomingWill/BabbagesHall/exhibits/Pascaline/" }) do
  local f = io.open(d .. "pascaline-geometry.lua", "r")
  if f then f:close(); DIR = d; break end
end
assert(DIR, "The Pascaline: can't find its folder")
local G = dofile(DIR .. "pascaline-geometry.lua")
-- (PA_DET_T_MM: the detents' leaves this thick instead, in mm, for trying)
if os.getenv("PA_DET_T_MM") then G.DET_T = tonumber(os.getenv("PA_DET_T_MM")) / 10 end
local ND = G.ND

-- geometry.scad: the primitives, for OpenSCAD (written from the geometry,
-- so the printed parts and the simulation's are the same)
local function scadPrims(P)
  local out = {}
  for _, p in ipairs(P) do
    if p[1] == "hull" then
      local pts = {}
      for _, q in ipairs(p[2]) do pts[#pts + 1] = string.format("[%.4f,%.4f,%.4f]", q[1], q[2], q[3]) end
      out[#out + 1] = string.format('["hull",[%s],%.5f,%.4f,%.4f,%.4f]', table.concat(pts, ","), p[3], p[4], p[5], p[6])
    else
      local nums = {}
      for k = 2, #p do nums[#nums + 1] = string.format("%.5f", p[k]) end
      out[#out + 1] = '["' .. p[1] .. '",' .. table.concat(nums, ",") .. "]"
    end
  end
  return "[" .. table.concat(out, ",\n  ") .. "]"
end
local function writeGeometry(path)
  local f = assert(io.open(path, "w"))
  f:write("// made by pascaline.lua from pascaline-geometry.lua: do not edit (cm)\n")
  for _, k in ipairs({ "ND", "D", "Y0", "STEP", "RP", "PIN_R", "PZ0", "PZ1", "CZ0", "CZ1", "R0", "R1", "PA",
                       "DET_NR", "DET_L", "DET_T", "DET_Z0", "DET_Z1", "DET_PRE", "STYLUS_R", "STOP_A" }) do
    f:write(string.format("%s = %s;\n", k, tostring(G[k])))
  end
  f:write("DIGIT_CAM = " .. scadPrims(G.digit(0)) .. ";\n")
  f:write("DIGIT_PLAIN = " .. scadPrims(G.digit(ND - 1)) .. ";\n")
  local L, Pw, LP, PH, WA = {}, {}, {}, {}, {}
  for i = 0, ND - 2 do
    local lp, piv, hinge = G.lever(i)
    L[#L + 1] = scadPrims(lp)
    Pw[#Pw + 1] = scadPrims((G.pawl(i)))
    LP[#LP + 1] = string.format("[%.4f,%.4f,%.4f]", piv.x, piv.y, piv.z)
    PH[#PH + 1] = string.format("[%.4f,%.4f,%.4f]", hinge.x, hinge.y, hinge.z)
    WA[#WA + 1] = string.format("[%.4f,%.4f,%.4f]", lp[4][2], lp[4][3], lp[4][4])
  end
  f:write("LEVERS = [" .. table.concat(L, ",\n") .. "];\n")
  f:write("PAWLS = [" .. table.concat(Pw, ",\n") .. "];\n")
  f:write("LEVER_PIVOTS = [" .. table.concat(LP, ",") .. "];\n")
  f:write("PAWL_HINGES = [" .. table.concat(PH, ",") .. "];\n")
  f:write("WEIGHT_AT = [" .. table.concat(WA, ",") .. "];\n")
  local DT, DR = {}, {}
  for i = 0, ND - 1 do
    local dp, root = G.detent(i)
    DT[#DT + 1] = scadPrims(dp)
    DR[#DR + 1] = string.format("[%.4f,%.4f,%.4f]", root.x, root.y, root.z)
  end
  f:write("DETENTS = [" .. table.concat(DT, ",\n") .. "];\n")
  f:write("DETENT_ROOTS = [" .. table.concat(DR, ",") .. "];\n")
  f:close()
end
do
  local path = DIR .. "parts/geometry.scad"
  local f = io.open(path, "r")
  if f then f:close() end
  if not f or os.getenv("PA_EXPORT") then writeGeometry(path); print("PASCALINE: wrote " .. path) end
end

local SCAD
do
  local path = DIR .. "parts/pascaline.scad"
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
local SCAD_SUM = checksum({ SCAD, (SCAD:gsub("pascaline%.scad$", "geometry.scad")) })
local function part(call, solid)
  local m = OpenSCAD("// " .. SCAD_SUM .. "\ninclude <" .. SCAD .. ">\nscale(0.1) " .. call .. ";\n", 0, false)
  if not solid then m.collides = false end
  return m
end

-- ---------------------------------------------------------------------
-- sliders, timing, the pause at every start
-- ---------------------------------------------------------------------
v:addParam("friction", envnum("PA_FRICTION", 0.3), 0.15, 0.45, 0.05, "pin, cam, pawl and nose (0.15 to 0.45 checked)")
v:addParam("speed", 1, 0.05, 2, 0.05, "simulated seconds per real second (Z: 1/4 <-> 1)")
v:addParam("turn rate", envnum("PA_RATE", 0.3), 0.1, 0.6, 0.05, "how fast the hand turns a digit, turns a second")
local STEP_DT, NSTEPS, FRAME_DT = 1 / 2400, 40, 1 / 60
local function applyTiming()
  local speed = v:getParam("speed")
  NSTEPS = math.max(1, math.floor(2400 * speed / 60 + 0.5))
  FRAME_DT = speed / 60
  STEP_DT = FRAME_DT / NSTEPS
  v.animationPeriod = 16
  common.setTiming(STEP_DT, 0, STEP_DT)
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
-- the table; the machine on it (its frame: the units' axle at MO)
-- ---------------------------------------------------------------------
local ident = btQuaternion(0, 0, 0, 1)
local MO = btVector3(11, 8.0, 0)            -- (the units' axle, above the table top at y = 0)
local function W(x, y, z) return btVector3(MO.x + x, MO.y + y, MO.z + z) end

-- the table, by the hall's standard (exhibit-table.lua: 100 cm high, the
-- machine's footprint plus 30 cm all round)
local TABLE
do
  local f = assert(loadfile(DIR .. "../../exhibit-table.lua"))
  if setfenv then setfenv(f, getfenv(1)) end
  TABLE = f()
end
TABLE.build(46, 11, { x = -1, z = 0.7, floor = 300 })   -- (the frame: x -24 to 22, z -4.8 to 6.2)

local pointers = part("pointers()")
pointers.col = "#d4af37"
v:add(pointers)
pointers.trans = btTransform(ident, MO)
-- the plate's numbers round each dial (which hole to put the stylus in),
-- and the finger stops it is turned to
local plateNums = part("plateNumbers()")
plateNums.col = "#efe6cf"
v:add(plateNums)
plateNums.trans = btTransform(ident, MO)
for i = 0, G.ND - 1 do
  local st = part("stop(" .. i .. ")")
  st.col = "#3c3c40"
  v:add(st)
  st.trans = btTransform(ident, MO)
end
local frame = part("frame(false)")
frame.col = "#3a2a1a"
pcall(function() frame.transparency = 0.35 end)        -- (to see the works through it)
v:add(frame)
frame.trans = btTransform(ident, MO)

local anchor = Cube(0.01, 0.01, 0.01, 0)     -- (only for the hinges to hold to: too small to see)
anchor.collides = false
v:add(anchor)
anchor.trans = btTransform(ident, btVector3(0, 0, 0))

-- ---------------------------------------------------------------------
-- bodies from primitives: the origin at their centre of mass
-- ---------------------------------------------------------------------
local MARGIN = 0.01
local function shapeOf(p)
  local s
  if p[1] == "box" then s = btBoxShape(btVector3(p[5] / 2, p[6] / 2, p[7] / 2))
  elseif p[1] == "cylz" then s = btCylinderShapeZ(btVector3(p[5], p[5], p[6] / 2))
  else
    s = btConvexHullShape()
    for _, q in ipairs(p[2]) do s:addPoint(btVector3(q[1], q[2], q[3]), false) end
    s:recalcLocalAabb()
  end
  s:setMargin(MARGIN)
  return s
end
-- prims in the machine's frame -> a body (and its centre of mass, there)
local function bodyOf(P, visualCall, col)
  local M, cx, cy, cz = 0, 0, 0, 0
  for _, p in ipairs(P) do
    local x, y, z, m = G.centre(p)
    M = M + m; cx = cx + m * x; cy = cy + m * y; cz = cz + m * z
  end
  cx, cy, cz = cx / M, cy / M, cz / M
  local c = btCompoundShape(true)
  local Ix, Iy, Iz = 0, 0, 0
  for _, p in ipairs(P) do
    local x, y, z, m = G.centre(p)
    local s = shapeOf(p)
    if p[1] == "hull" then
      -- (a hull's points are where they are: shift them by the centre of mass)
      local h = btConvexHullShape()
      for _, q in ipairs(p[2]) do h:addPoint(btVector3(q[1] - cx, q[2] - cy, q[3] - cz), false) end
      h:recalcLocalAabb(); h:setMargin(MARGIN)
      c:addChildShape(btTransform(ident, btVector3(0, 0, 0)), h)
    else
      c:addChildShape(btTransform(ident, btVector3(x - cx, y - cy, z - cz)), s)
    end
    local dx, dy, dz = x - cx, y - cy, z - cz
    Ix = Ix + m * (dy * dy + dz * dz + 0.01); Iy = Iy + m * (dx * dx + dz * dz + 0.01); Iz = Iz + m * (dx * dx + dy * dy + 0.01)
  end
  local com = W(cx, cy, cz)
  local o = part(string.format("translate([%.3f, %.3f, %.3f]) %s", -10 * cx, -10 * cy, -10 * cz, visualCall), true)
  local body = btRigidBody(M, btDefaultMotionState(btTransform(ident, com)), c, btVector3(Ix, Iy, Iz))
  o.body = body
  o.col = col
  v:add(o)
  o.trans = btTransform(ident, com)
  body:setCenterOfMassTransform(btTransform(ident, com))
  body:setActivationState(4)
  return body, { x = cx, y = cy, z = cz }, o
end

-- the digits: each in its own frame (the axle at its origin); a hinge to the frame
local digits = {}
for i = 0, ND - 1 do
  local c = btCompoundShape(true)
  for _, p in ipairs(G.digit(i)) do
    if p[1] == "hull" then c:addChildShape(btTransform(ident, btVector3(0, 0, 0)), shapeOf(p))
    else c:addChildShape(btTransform(ident, btVector3(p[2], p[3], p[4])), shapeOf(p)) end
  end
  local pos = W(G.xd(i), G.Y0, 0)
  local o = part(i < ND - 1 and "digit(true)" or "digit(false)", true)
  local body = btRigidBody(G.DIGIT_MASS, btDefaultMotionState(btTransform(ident, pos)), c, btVector3(0.05, 0.05, 0.1))
  o.body = body
  o.col = "#c8a456"
  v:add(o)
  o.trans = btTransform(ident, pos)
  body:setCenterOfMassTransform(btTransform(ident, pos))
  body:setActivationState(4)
  local h = btHingeConstraint(anchor.body, body, btTransform(ident, pos), btTransform(ident, btVector3(0, 0, 0)))
  v:addConstraint(h)
  digits[i] = { body = body, hinge = h, obj = o, pos = pos }
end
-- each digit's dial, drawn apart so its numbers can be dark on a light face
-- (printed, it is one piece: paint the raised numbers); they go round with it
local dials = {}
for i = 0, ND - 1 do
  for _, d in ipairs({ { "dial(false)", "#efe6cf" }, { "dialNumbers()", "#1e1812" } }) do
    local m = part(d[1])
    m.col = d[2]
    v:add(m)
    m.trans = btTransform(ident, digits[i].pos)
    dials[#dials + 1] = { obj = m, i = i }
  end
end
-- the stylus: drawn in the hole the hand uses, going round with the digit
-- until it meets the stop; between moves it lies on the table in front.
-- (It is drawn: the hand that turns the digit is the motor, as before.)
local stylus = part("stylus()")
stylus.col = "#2a2622"
v:add(stylus)
local STYLUS_PARK = btTransform(btQuaternion(btVector3(0, 1, 0), math.pi / 2), W(-15, -G.Y0 - 8 + 0.4, 9))
stylus.trans = STYLUS_PARK
local stylusOn = nil                       -- { digit, its place in the digit's frame }
local chosen = nil                         -- { digit, n }: the hole the mouse chose (Space turns it)
local function moveDials()
  for _, d in ipairs(dials) do d.obj.trans = digits[d.i].body:getCenterOfMassTransform() end
  if stylusOn then
    local tr = btTransform()
    tr:mult(digits[stylusOn.i].body:getCenterOfMassTransform(), stylusOn.local_)
    stylus.trans = tr
  else
    stylus.trans = STYLUS_PARK
  end
end

-- the sautoirs and their pawls
local levers = {}
for i = 0, ND - 2 do
  local lp, piv, hinge = G.lever(i)
  local body, com = bodyOf(lp, "lever(" .. i .. ")", "#6e6e72")
  local h = btHingeConstraint(anchor.body, body, btTransform(ident, W(piv.x, piv.y, piv.z)),
                              btTransform(ident, btVector3(piv.x - com.x, piv.y - com.y, piv.z - com.z)))
  v:addConstraint(h)
  local pp = G.pawl(i)
  local pbody, pcom = bodyOf(pp, "pawl(" .. i .. ")", "#b5893a")
  local ph = btHingeConstraint(body, pbody, btTransform(ident, btVector3(hinge.x - com.x, hinge.y - com.y, hinge.z - com.z)),
                               btTransform(ident, btVector3(hinge.x - pcom.x, hinge.y - pcom.y, hinge.z - pcom.z)))
  ph:setLimit(math.rad(G.PAWL_LO), math.rad(G.PAWL_HI), 0.9, 0.3, 1.0)
  v:addConstraint(ph)
  levers[i] = { body = body, hinge = h, pawl = pbody, pawlHinge = ph, rest = btTransform(ident, W(com.x, com.y, com.z)),
                prest = btTransform(ident, W(pcom.x, pcom.y, pcom.z)) }
end
-- the detents: each a body (its nose and leaf) on a hinge at the leaf's
-- root; the leaf's stiffness turns it back (see steer). Its root block,
-- screwed to the front plate, doesn't move: drawn with the frame.
local detents = {}
local DET_K = G.detentStiffness()
local DET_PRE_A = G.DET_PRE / G.DET_L           -- (the preload, as a turn of the leaf about its root)
for i = 0, ND - 1 do
  local dp, root = G.detent(i)
  local body, com = bodyOf(dp, "detentMoving(" .. i .. ")", "#ddd3b8")
  local h = btHingeConstraint(anchor.body, body, btTransform(ident, W(root.x, root.y, root.z)),
                              btTransform(ident, btVector3(root.x - com.x, root.y - com.y, root.z - com.z)))
  v:addConstraint(h)
  pcall(function() body:setDamping(0, 0.5) end)
  detents[i] = { body = body, hinge = h, rest = btTransform(ident, W(com.x, com.y, com.z)) }
  local r = part("detentRoot(" .. i .. ")")
  r.col = "#ddd3b8"
  v:add(r)
  r.trans = btTransform(ident, MO)
end
pcall(function() v.showConstraints = false end)

local function applyFriction()
  local f = v:getParam("friction")
  for i = 0, ND - 1 do digits[i].body:setFriction(f) end
  for i = 0, ND - 2 do levers[i].body:setFriction(f); levers[i].pawl:setFriction(f) end
  for i = 0, ND - 1 do detents[i].body:setFriction(f) end
end
applyFriction()

-- ---------------------------------------------------------------------
-- reading the digits; the hand; the detents
-- ---------------------------------------------------------------------
-- (Bullet's hinge angle here counts clockwise as you see it: the way the
-- digits count)
local function value(i)
  local d = digits[i]
  local x = d.hinge:getHingeAngle()
  if d.last then
    local dd = x - d.last
    if dd > math.pi then dd = dd - 2 * math.pi elseif dd < -math.pi then dd = dd + 2 * math.pi end
    d.acc = d.acc + dd
  else d.acc = x end
  d.last = x
  return d.acc / math.rad(G.STEP)
end
local function shown(i) return math.floor(value(i) + 0.5) % 10 end
local function number() return 100 * shown(2) + 10 * shown(1) + shown(0) end

local hand, handTarget = nil, nil          -- the digit the hand is turning, and to where (in units, unwrapped)
local queue = {}                           -- moves still to make: { digit, steps }
local function steer()
  local rate = v:getParam("turn rate") * 2 * math.pi
  for i = 0, ND - 1 do
    local d = digits[i]
    local x = value(i)
    if hand == i then
      local err = (handTarget - x) * math.rad(G.STEP)
      d.hinge:enableAngularMotor(true, math.max(-rate, math.min(rate, 8 * err)), 1)
    else
      d.hinge:enableAngularMotor(false, 0, 0)       -- (free: its detent holds it)
    end
  end
  -- each detent's leaf, bent, pushes its nose back in (Bullet's hinge angle
  -- counts clockwise as you see it: the nose's way in)
  for i = 0, ND - 1 do
    local dt = detents[i]
    dt.body:applyTorque(btVector3(0, 0, DET_K * (dt.hinge:getHingeAngle() - DET_PRE_A)))
  end
end

-- setting it back to 000: everything put where it began
local function reset()
  for i = 0, ND - 1 do
    local b = digits[i].body
    b:setCenterOfMassTransform(btTransform(ident, digits[i].pos))
    b:setLinearVelocity(btVector3(0, 0, 0)); b:setAngularVelocity(btVector3(0, 0, 0))
    digits[i].last, digits[i].acc = nil, 0
  end
  for i = 0, ND - 2 do
    local L = levers[i]
    L.body:setCenterOfMassTransform(L.rest); L.pawl:setCenterOfMassTransform(L.prest)
    for _, b in ipairs({ L.body, L.pawl }) do b:setLinearVelocity(btVector3(0, 0, 0)); b:setAngularVelocity(btVector3(0, 0, 0)) end
  end
  for i = 0, ND - 1 do
    local b = detents[i].body
    b:setCenterOfMassTransform(detents[i].rest)
    b:setLinearVelocity(btVector3(0, 0, 0)); b:setAngularVelocity(btVector3(0, 0, 0))
  end
  for i = 0, ND - 1 do value(i) end
  hand, queue, stylusOn = nil, {}, nil
  holdStart()
end

-- ---------------------------------------------------------------------
-- the tour
-- ---------------------------------------------------------------------
local TOUR = {
  { moves = { { 0, 7 } }, want = 7, say = "dial 7 on the units" },
  { moves = { { 0, 8 } }, want = 15, say = "add 8: the units pass 9, their sautoir drops and carries one to the tens" },
  { moves = { { 0, 4 }, { 1, 8 } }, want = 99, say = "add 84: 4 on the units, 8 on the tens" },
  { moves = { { 0, 1 } }, want = 100, say = "add 1: the units carry, the tens pass 9 and carry too -- 100" },
}
local tour = (os.getenv("PA_TOUR") or "1") ~= "0" and 1 or nil
local fails, wait, started = 0, 0, false
local function tourStep()
  local s = TOUR[tour]
  print(s.say)
  for _, m in ipairs(s.moves) do queue[#queue + 1] = { m[1], m[2] } end
end
if tour then print("\nTHE PASCALINE -- the tour") end

-- (the moving parts, for telling when they've stopped)
local restBodies = {}
for i = 0, ND - 1 do restBodies[#restBodies + 1] = digits[i].body end
for i = 0, ND - 2 do restBodies[#restBodies + 1] = levers[i].body; restBodies[#restBodies + 1] = levers[i].pawl end
for i = 0, ND - 1 do restBodies[#restBodies + 1] = detents[i].body end
-- ---------------------------------------------------------------------
-- at rest: once the hand has nothing to do and nothing has moved for
-- REST_S, the simulation stops stepping. Nothing would change but the
-- processor's work (a machine at rest, stepped 2400 times a second, costs
-- as much as one running). The next thing for the hand to do starts it
-- again. (PA_REST=0: never rest; PA_REST_LOG=1: print the fastest
-- part's speeds each second while the hand is idle, to set REST_V, REST_W)
-- ---------------------------------------------------------------------
local REST_S = 0.5
local REST_V, REST_W = 0.05, 0.02   -- cm/s and rad/s: "not moving" (just above what is left when it has settled)
local REST_ON = os.getenv("PA_REST") ~= "0"
local REST_LOG = os.getenv("PA_REST_LOG")
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
  if (hand ~= nil or #queue > 0) then
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
  if (hand ~= nil or #queue > 0) then restFor = 0; return end
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
  for k = 1, NSTEPS do
    steer()
    if k < NSTEPS then v:stepSimulation(STEP_DT, 0, STEP_DT) end
  end
end)

v:postSim(function(N)
  moveDials()
  if holdNow then return end
  restPost()
  if not started then started = true; if tour then tourStep() end end
  -- the hand: the next move when it is free
  if not hand and #queue > 0 then
    local m = table.remove(queue, 1)
    hand = m[1]; handTarget = math.floor(value(hand) + 0.5) + m[2]
    chosen = nil
    -- the stylus into the hole by the plate's number m[2] (that many steps
    -- short of the stop), in the digit's own frame (turned clockwise by its
    -- value)
    local a = math.rad(G.STOP_A - G.STEP * m[2] - G.STEP * value(hand))
    stylusOn = { i = hand, local_ = btTransform(ident, btVector3(G.STYLUS_R * math.sin(a), G.STYLUS_R * math.cos(a), 0)) }
  end
  if hand and math.abs(value(hand) - handTarget) < 0.02 then
    wait = wait + FRAME_DT
    if wait > 0.3 then hand, wait, stylusOn = nil, 0, nil end
  end
  -- the tour: when the hand is done and everything has settled, read it
  if tour and not hand and #queue == 0 then
    wait = wait + FRAME_DT
    if wait > 1.0 then
      wait = 0
      local n, want = number(), TOUR[tour].want
      local ok = (n == want)
      if not ok then fails = fails + 1 end
      print(string.format("  it reads %03d   (%s)", n, ok and "right" or ("WRONG: " .. want)))
      if os.getenv("PA_DEBUG") then
        local parts = {}
        for i = ND - 1, 0, -1 do parts[#parts + 1] = string.format("%.2f", value(i)) end
        local lv = {}
        for i = 0, ND - 2 do
          local q = levers[i].body:getCenterOfMassTransform():getBasis():getColumn(0)
          lv[#lv + 1] = string.format("sautoir%d %+.1f deg, pawl %+.1f", i, math.deg(math.atan2(q.y, q.x)), math.deg(levers[i].pawlHinge:getHingeAngle()))
        end
        print("    digits (h t u) " .. table.concat(parts, " ") .. "   " .. table.concat(lv, "   "))
      end
      tour = tour + 1
      if tour > #TOUR then
        tour = nil
        print("RESULT pascaline tour: " .. (fails == 0 and "PASS" or "FAIL"))
      else
        tourStep()
      end
    end
  end
end)

-- ---------------------------------------------------------------------
-- keys, sliders, help
-- ---------------------------------------------------------------------
-- the wheel the keys turn, marked below it on the plate
local WHEEL = { "the units", "the tens", "the hundreds" }
local sel = 0
local selMark = part("selMarker()")
selMark.col = "#d4af37"
v:add(selMark)
local function showSel() selMark.trans = btTransform(ident, W(G.xd(sel), 0, 0)) end
showSel()
for i, key in ipairs({ "U", "T", "H" }) do
  v:addShortcut(key, function() sel = i - 1; showSel(); print("PASCALINE: " .. WHEEL[i] .. " chosen") end)
end
-- 1 to 9: that much onto the chosen wheel, one stroke of the stylus
for n = 1, 9 do
  v:addShortcut(tostring(n), function() tour = nil; queue[#queue + 1] = { sel, n } end)
end
-- the mouse: resting on a hole puts the stylus in it (see onHover, below);
-- Space turns it to the stop
v:addShortcut("Space", function()
  if chosen and not hand and #queue == 0 then
    tour = nil
    queue[#queue + 1] = { chosen[1], chosen[2] }
    chosen = nil
  end
end)
v:addShortcut("R", function() tour = nil; chosen = nil; reset() end)
v:addShortcut("D", function() reset(); chosen = nil; tour = 1; fails = 0; started = false; print("\nthe tour") end)
v:addShortcut("Z", function()
  local sp = v:getParam("speed") < 0.5 and 1 or 0.25
  v:addParam("speed", sp, 0.05, 2, 0.05, "simulated seconds per real second (Z: 1/4 <-> 1)")
  applyTiming()
end)
v:onParamChanged(function(N, name, value_)
  if name == "speed" then applyTiming()
  elseif name == "friction" then applyFriction() end
end)
pcall(function()
  v:setHelpText(table.concat({
    "THE PASCALINE  (Babbage's Hall)",
    "",
    "Pascal's adding machine, 1642. Each digit is a wheel of pins with a snail",
    "cam behind it. Counting up from 0 to 9, the cam lifts a weighted lever,",
    "the SAUTOIR, a little at each step. Passing 9, the cam drops away, the",
    "sautoir falls, and its pawl drives the next digit on by one.",
    "",
    "WHAT TO WATCH",
    "  The grey levers behind the wheels are the sautoirs; the brass hooks",
    "  hanging from them, their pawls. Watch the pawl swing aside over a pin",
    "  as its sautoir rises, and strike it as it falls.",
    "  99 + 1: the units' sautoir drives the tens past 9, which drops the",
    "  tens' sautoir, which drives the hundreds -- the carry ripples along,",
    "  paid for by weights lifted earlier.",
    "",
    "DRIVING IT, as Pascal's was",
    "  Each dial has ten holes; round it, the plate has the numbers 1 to 9",
    "  and a finger stop. A stylus in the hole beside the plate's n, turned",
    "  clockwise to the stop, adds n, whatever the dial showed.",
    "  The mouse: rest it on a hole -- the stylus goes in, and the tooltip",
    "  says what it will add. Space turns it to the stop.",
    "  The keys: U / T / H choose the units, tens or hundreds (a brass mark",
    "  below the dial); 1 to 9 add that much to it, in one stroke.",
    "",
    "KEYS",
    "  U T H  choose a wheel     1-9  add to it     Space  turn the chosen hole",
    "  D  the tour      R  back to 000      Z  slow motion",
  }, "\n"))
end)
if v.onHover then
  local KEY = {}
  for i = 0, ND - 1 do KEY[objectKey(digits[i].obj)] = ({ "the units", "the tens", "the hundreds" })[i + 1] end
  v:onHover(function(N, obj, x, y, z)
    -- over a dial's ring of holes? the hole by the plate's n (the holes turn
    -- with the dial: at each unit they stand by the plate's numbers)
    for i = 0, ND - 1 do
      local c = W(G.xd(i), G.Y0, 0)
      local dx, dy = x - c.x, y - c.y
      local r = math.sqrt(dx * dx + dy * dy)
      if r < 4.6 and z > c.z + 1.4 then
        if math.abs(r - G.STYLUS_R) > 0.9 then
          return string.format("%s, reading %d (the machine: %03d)\nrest the mouse on one of its holes to put the stylus in it",
                               WHEEL[i + 1], shown(i), number())
        end
        if hand or #queue > 0 then return "the stylus is busy: wait for the dial to stop" end
        local a = math.deg(math.atan2(dx, dy)) % 360             -- (clockwise from the top)
        local n = math.floor((G.STOP_A - a) / G.STEP + 0.5) % 10
        if n == 0 then
          chosen, stylusOn = nil, nil
          return "this hole is at the finger stop: it adds nothing"
        end
        chosen = { i, n }
        local ang = math.rad(G.STOP_A - G.STEP * n - G.STEP * value(i))
        stylusOn = { i = i, local_ = btTransform(ident, btVector3(G.STYLUS_R * math.sin(ang), G.STYLUS_R * math.cos(ang), 0)) }
        return string.format("the stylus in the hole by the plate's %d: add %d to %s\n%03d becomes %03d -- press Space to turn it to the stop",
                             n, n, WHEEL[i + 1], number(), (number() + n * 10 ^ i) % 1000)
      end
    end
    local s = KEY[objectKey(obj)]
    if not s then return nil end
    return string.format("%s: a wheel of ten pins, its cam behind\nthe machine reads %03d", s, number())
  end)
end

common.setCamera(btVector3(-2, 30, 55), btVector3(-2, 6, 0))
holdStart()
