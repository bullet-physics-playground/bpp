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
-- KEYS
--   T     the tour: 7, + 8 = 15, + 84 = 99, + 1 = 100 (it starts with it)
--   1/2/3 turn the units / tens / hundreds on by one, as with Pascal's stylus
--   R     set it back to 000
--   Z     slow motion (1/4) <-> real time
--
-- EVERY PART CAN BE PRINTED: see parts/ and README.md.
--
-- PHYSICS: the digits' pins and cams, the sautoirs and their pawls are the
-- printed parts' own primitives (pascaline-geometry.lua); they push each
-- other only by contact. A digit is turned by a hand (a motor steered to
-- where the keys put it), forward only; between turns it sits in its click
-- (a spring detent, here a weak pull to the nearest unit). The sautoir's
-- weight is 60 g of steel; the pawl's tail, 8 g. Friction 0.3 (a slider:
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
  for _, k in ipairs({ "ND", "D", "Y0", "STEP", "RP", "PIN_R", "PZ0", "PZ1", "CZ0", "CZ1", "R0", "R1", "PA" }) do
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

local top = Cube(70, 3, 40, 0)
top.pos = btVector3(0, -1.5, 0)
top.col = "#5b3a1e"
v:add(top)
for _, sx in ipairs({ -1, 1 }) do
  for _, sz in ipairs({ -1, 1 }) do
    local leg = Cylinder(1.6, 72, 0)
    leg.trans = btTransform(btQuaternion(btVector3(1, 0, 0), math.pi / 2), btVector3(sx * 32, -3 - 36, sz * 17))
    leg.col = "#2a2a2a"
    leg.collides = false
    v:add(leg)
  end
end
local floor = Plane(0, 1, 0, -75, 300)
floor.col = "#3b3f45"
v:add(floor)

local pointers = part("pointers()")
pointers.col = "#d4af37"
v:add(pointers)
pointers.trans = btTransform(ident, MO)
local frame = part("frame(false)")
frame.col = "#3a2a1a"
pcall(function() frame.transparency = 0.35 end)        -- (to see the works through it)
v:add(frame)
frame.trans = btTransform(ident, MO)

local anchor = Cube(1, 1, 1, 0)
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
local function moveDials()
  for _, d in ipairs(dials) do d.obj.trans = digits[d.i].body:getCenterOfMassTransform() end
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
pcall(function() v.showConstraints = false end)

local function applyFriction()
  local f = v:getParam("friction")
  for i = 0, ND - 1 do digits[i].body:setFriction(f) end
  for i = 0, ND - 2 do levers[i].body:setFriction(f); levers[i].pawl:setFriction(f) end
end
applyFriction()

-- ---------------------------------------------------------------------
-- reading the digits; the hand; the clicks
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
      local err = (math.floor(x + 0.5) - x) * math.rad(G.STEP)
      d.hinge:enableAngularMotor(true, G.CLICK_K * err, G.CLICK_IMP)
    end
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
  for i = 0, ND - 1 do value(i) end
  hand, queue = nil, {}
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
  end
  if hand and math.abs(value(hand) - handTarget) < 0.02 then
    wait = wait + FRAME_DT
    if wait > 0.3 then hand, wait = nil, 0 end
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
for i, key in ipairs({ "1", "2", "3" }) do
  v:addShortcut(key, function() tour = nil; queue[#queue + 1] = { i - 1, 1 } end)
end
v:addShortcut("R", function() tour = nil; reset() end)
v:addShortcut("T", function() reset(); tour = 1; fails = 0; started = false; print("\nthe tour") end)
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
    "KEYS",
    "  1 / 2 / 3  turn the units / tens / hundreds on by one",
    "  T  the tour      R  back to 000      Z  slow motion",
  }, "\n"))
end)
if v.onHover then
  local KEY = {}
  for i = 0, ND - 1 do KEY[objectKey(digits[i].obj)] = ({ "the units", "the tens", "the hundreds" })[i + 1] end
  v:onHover(function(N, obj, x, y, z)
    local s = KEY[objectKey(obj)]
    if not s then return nil end
    return string.format("%s: a wheel of ten pins, its cam behind\nthe machine reads %03d", s, number())
  end)
end

common.setCamera(btVector3(-2, 30, 55), btVector3(-2, 6, 0))
holdStart()
