--
-- The Domino Half Adder -- Babbage's Hall
--
-- A computer made of nothing but dominoes standing on a table: it adds two
-- one-bit numbers, A and B, and shows the answer, CARRY and SUM, as two
-- tiles that fall over to show a 1. Push the first domino (GO); about four
-- seconds later the answer is there:
--     0 + 0 = 00     0 + 1 = 01     1 + 0 = 01     1 + 1 = 10
--
-- HOW IT COMPUTES. A falling wave is a 1; no wave is a 0. Each input has a
-- SWITCH: two dominoes, standing (1) or taken out (0) -- a gap no wave can
-- jump. Then three tricks, each checked here before it was used:
--   * Waves meeting head-on stop each other. A and B strike the two ends
--     of one line; if both come, they meet in the middle and stop.
--   * A branch off a line is taken only by a wave running toward it. Near
--     each end of that line a branch leads to SUM: the right one is taken
--     by A's wave (running right), the left one by B's. So SUM falls if A
--     or B came, but not both: SUM = A XOR B.
--   * A wave can cut another line: its last domino knocks one out of that
--     line from the side, leaving a gap. A's carry branch is a long delay
--     line (the serpentine on the left); a branch of SUM cuts it before A's
--     own wave gets there. So the carry runs through only when A came and
--     SUM didn't: A AND NOT (A XOR B) = A AND B.
--
-- KEYS
--   T  the tour: 0+0, 0+1, 1+0, 1+1, one after the other (it starts with it)
--   A  input A: 1 <-> 0 (the board is set up again)
--   B  input B: 1 <-> 0
--   G  GO: push the first domino
--   R  set the board up again, the inputs as they are
--   Z  slow motion (1/4) <-> real time
--
-- EVERY PART CAN BE PRINTED: see parts/ and README.md. The dominoes are the
-- standard 48 x 24 x 7.5 mm; they stand in the pockets of a printed
-- template (tiles 1.6 mm thick), whose walls are in the simulation too.
--
-- PHYSICS: 268 dominoes, boxes of 8 g, friction 0.4 (0.3 to 0.5 checked),
-- no bounce; the template's pocket walls as fixed boxes; 2400 steps a
-- second. Checked: all four sums right at friction 0.3, 0.4 and 0.5, with
-- every domino misplaced at random within its pocket (0.3 mm, 1.5 deg).
-- The printed dominoes' edges are rounded 0.8 mm; the simulation's are
-- square.
--
-- Units: centimetres, kilograms, seconds.
-- Headless: DA_IN="AB" (the inputs that are 1), DA_TOUR=0 (no tour: one
-- run of DA_IN), DA_RUN=seconds per sum, DA_FRICTION, DA_JIT=cm and
-- DA_SEED (every domino misplaced at random within its pocket),
-- DA_DEBUG=1 (which lines fell), DA_EXPORT=parts/layout.scad (write the
-- layout for the printed parts).
--

local common = require "common"
local function envnum(n, d) return tonumber(os.getenv(n) or "") or d end

-- ---------------------------------------------------------------------
-- this exhibit's folder, and the layout
-- ---------------------------------------------------------------------
local DIR
for _, d in ipairs({ "", "demo/WyomingWill/BabbagesHall/exhibits/DominoAdder/" }) do
  local f = io.open(d .. "domino-lines.lua", "r")
  if f then f:close(); DIR = d; break end
end
assert(DIR, "Domino Half Adder: can't find its folder")
local L = dofile(DIR .. "domino-lines.lua")
local LINES, STARTS, INFO = dofile(DIR .. "domino-layout.lua")(L).machine()
local W, H, T = L.W, L.H, L.T
local MASS = 0.008
local G = 981

-- the parts file, by its full path (for OpenSCAD, which runs elsewhere)
local SCAD
do
  local path = DIR .. "parts/domino-adder.scad"
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
  assert(f, "Domino Half Adder: can't find its parts file at " .. path)
  f:close()
  SCAD = path
end
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
local SCAD_SUM = checksum({ SCAD })
local function part(call, mass)
  return OpenSCAD("// " .. SCAD_SUM .. "\ninclude <" .. SCAD .. ">\nscale(0.1) " .. call .. ";\n", mass or 0, false)
end

-- ---------------------------------------------------------------------
-- the board: the layout's x, z (z away from you) to the exhibit's world
-- (z toward you), centred on the table
-- ---------------------------------------------------------------------
local ORDER = { "GO", "Ain", "Bin", "A", "B", "C", "Tl", "Tr", "SUM", "INH", "A3" }
local TELL = INFO.tell
local xmin, xmax, zmin, zmax = 1e9, -1e9, 1e9, -1e9
for _, n in ipairs(ORDER) do
  for _, p in ipairs(LINES[n]) do
    xmin, xmax = math.min(xmin, p.x), math.max(xmax, p.x)
    zmin, zmax = math.min(zmin, p.z), math.max(zmax, p.z)
  end
end
local XC, ZC = (xmin + xmax) / 2, (zmin + zmax) / 2
local function world(p) return p.x - XC, ZC - p.z, math.pi - p.h end

-- the printed parts' layout (DA_EXPORT): every pocket, in mm, from the
-- template's corner; and how many 200 mm tiles it takes
local MARGIN = 3
if os.getenv("DA_EXPORT") then
  local f = assert(io.open(os.getenv("DA_EXPORT"), "w"))
  f:write("// made by domino-adder.lua (DA_EXPORT): every pocket of the template, in mm\n")
  f:write("// [x, y, heading in degrees, kind: 0 domino, 1 switch domino, 2 tell-tale]\n")
  f:write("DOMINOES = [\n")
  local sw = {}
  for n, idx in pairs(INFO.switch) do sw[n] = {}; for _, i in ipairs(idx) do sw[n][i] = true end end
  local function put(p, kind)
    f:write(string.format("  [%.2f, %.2f, %.3f, %d],\n", (p.x - xmin + MARGIN) * 10, (p.z - zmin + MARGIN) * 10,
                          math.deg(p.h), kind))
  end
  for _, n in ipairs(ORDER) do
    for i, p in ipairs(LINES[n]) do put(p, (sw[n] and sw[n][i]) and 1 or 0) end
  end
  put(TELL.CARRY, 2); put(TELL.SUM, 2)
  f:write("];\n")
  f:write(string.format("TILES_X = %d;\nTILES_Y = %d;\n", math.ceil((xmax - xmin + 2 * MARGIN) / 20),
                        math.ceil((zmax - zmin + 2 * MARGIN + 8) / 20)))
  f:close()
  print("DOMINO ADDER: layout written to " .. os.getenv("DA_EXPORT"))
end

-- ---------------------------------------------------------------------
-- sliders, timing, the pause at every start
-- ---------------------------------------------------------------------
v:addParam("friction", envnum("DA_FRICTION", 0.4), 0.3, 0.5, 0.05, "domino on domino, and on the table (0.3 to 0.5 checked)")
v:addParam("speed", 1, 0.05, 2, 0.05, "simulated seconds per real second (Z: 1/4 <-> 1)")
v:addParam("steps", 2400, 1200, 4800, 600, "physics steps per simulated second")

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
v.gravity = btVector3(0, -G, 0)

-- ---------------------------------------------------------------------
-- the table
-- ---------------------------------------------------------------------
local TW, TD = (xmax - xmin) + 2 * MARGIN + 16, (zmax - zmin) + 2 * MARGIN + 24
local top = Cube(TW, 4, TD, 0)
top.pos = btVector3(0, -2, 0)
top.col = "#5b3a1e"
top.friction = 1.0          -- (Bullet multiplies the two: the slider is what counts)
v:add(top)
for _, sx in ipairs({ -1, 1 }) do
  for _, sz in ipairs({ -1, 1 }) do
    local leg = Cylinder(3, 71, 0)
    leg.trans = btTransform(btQuaternion(btVector3(1, 0, 0), math.pi / 2), btVector3(sx * (TW / 2 - 8), -4 - 35.5, sz * (TD / 2 - 8)))
    leg.col = "#2a2a2a"
    leg.collides = false
    v:add(leg)
  end
end
local floor = Plane(0, 1, 0, -75, 400)
floor.col = "#3b3f45"
v:add(floor)

-- ---------------------------------------------------------------------
-- the template's pocket walls (fixed), and the dominoes
-- ---------------------------------------------------------------------
local ALL = {}
for _, n in ipairs(ORDER) do for _, p in ipairs(LINES[n]) do ALL[#ALL + 1] = p end end
local TELL_W, TELL_H, TELL_T = 4, 6, 0.4
local tellPoses = { { x = TELL.CARRY.x, z = TELL.CARRY.z, h = TELL.CARRY.h, w = TELL_W, t = TELL_T },
                    { x = TELL.SUM.x, z = TELL.SUM.z, h = TELL.SUM.h, w = TELL_W, t = TELL_T } }
do
  local poses = {}
  for _, p in ipairs(ALL) do poses[#poses + 1] = p end
  for _, p in ipairs(tellPoses) do poses[#poses + 1] = p end
  local walls = L.pocketWalls(poses)
  for _, w in ipairs(walls) do
    local x, z, h = world(w)
    local c = Cube(w.sx, L.WALL_H, w.sz, 0)
    c.trans = btTransform(btQuaternion(btVector3(0, 1, 0), h), btVector3(x, L.WALL_H / 2, z))
    c.col = "#8a6d3b"
    c.friction = 1.0
    pcall(function() c.castShadow = false end)
    v:add(c)
  end
end

local ROLE = {
  GO = "#9b1c1c", SUM = "#2f5d8c", INH = "#2f5d8c", A3 = "#2e5e3e",
}
local IVORY, BRASS = "#ede3c8", "#c9a227"
local dominoes, byLine, KEY = {}, {}, {}
local switchSet = {}
for n, idx in pairs(INFO.switch) do for _, i in ipairs(idx) do switchSet[n .. i] = true end end
for _, n in ipairs(ORDER) do
  byLine[n] = {}
  for i, p in ipairs(LINES[n]) do
    local c = Cube(W, H, T, MASS)
    local x, z, h = world(p)
    c.trans = btTransform(btQuaternion(btVector3(0, 1, 0), h), btVector3(x, H / 2, z))
    c.col = switchSet[n .. i] and BRASS or (ROLE[n] or IVORY)
    v:add(c)
    c.body:setActivationState(4)
    local d = { obj = c, line = n, i = i, x = x, z = z, h = h, switch = switchSet[n .. i] }
    dominoes[#dominoes + 1] = d
    byLine[n][i] = d
    if objectKey then KEY[objectKey(c)] = d end
  end
end

-- the tell-tales: a box to the physics, the printed tile to the eye, and
-- its two digits (inlays) carried along with it
local tells = {}
for _, k in ipairs({ "CARRY", "SUM" }) do
  local p = TELL[k]
  local x, z, h = world(p)
  local m = part("tell()")
  local shape = btBoxShape(btVector3(TELL_W / 2, TELL_H / 2, TELL_T / 2))
  local mass = 0.010
  local inertia = btVector3(mass * (TELL_H ^ 2 + TELL_T ^ 2) / 12, mass * (TELL_W ^ 2 + TELL_T ^ 2) / 12,
                            mass * (TELL_W ^ 2 + TELL_H ^ 2) / 12)
  local body = btRigidBody(mass, btDefaultMotionState(btTransform(btQuaternion(btVector3(0, 1, 0), h),
                           btVector3(x, TELL_H / 2, z))), shape, inertia)
  m.body = body
  m.col = "#1d1712"
  v:add(m)
  body:setActivationState(4)
  local d0, d1 = part('inlay("0")'), part('inlay("1")')
  d0.col, d1.col = IVORY, "#e0b84a"
  for _, d in ipairs({ d0, d1 }) do d.collides = false; v:add(d) end
  tells[k] = { obj = m, body = body, x = x, z = z, h = h, inlays = { d0, d1 } }
  if objectKey then KEY[objectKey(m)] = { tell = k } end
end
local function carryInlays()
  for _, t in ipairs({ tells.CARRY, tells.SUM }) do
    local tr = t.body:getCenterOfMassTransform()
    for _, d in ipairs(t.inlays) do d.trans = tr end
  end
end

-- the signs
local function sign(text, p, dx, dz)
  local x, z = world(p)
  local s = part('sign("' .. text .. '")')
  s.trans = btTransform(btQuaternion(0, 0, 0, 1), btVector3(x + (dx or 0), 0, z + (dz or 0)))
  s.col = "#b8932e"
  s.collides = false
  v:add(s)
  return s
end
do
  local k = INFO.switch.Ain[1]
  sign("A", LINES.Ain[k], -9, 0)
  sign("B", LINES.Bin[k], 9, 0)
  sign("GO", LINES.GO[1], 0, 7)
  sign("CARRY", TELL.CARRY, 0, -8)
  sign("SUM", TELL.SUM, 0, -8)
end

-- ---------------------------------------------------------------------
-- setting up, switches, GO
-- ---------------------------------------------------------------------
local inputs = { A = 1, B = 1 }
do
  local s = os.getenv("DA_IN")
  if s then inputs.A = s:find("A") and 1 or 0; inputs.B = s:find("B") and 1 or 0 end
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
  for _, d in ipairs(dominoes) do d.obj.body:setFriction(f); d.obj.body:setRestitution(0) end
  for _, t in pairs(tells) do t.body:setFriction(f); t.body:setRestitution(0) end
end

local JIT = envnum("DA_JIT", 0)            -- cm (the pocket allows 0.04)
if JIT > 0 then math.randomseed(envnum("DA_SEED", 1)) end
local t, running, goPending, reported = 0, false, false, false
local fell = {}
local function setUp()
  for _, d in ipairs(dominoes) do
    local on = not d.switch or inputs[d.line:sub(1, 1)] == 1
    if on then
      -- (DA_JIT: each one misplaced at random within its pocket, as by hand)
      local jx, jz, jh = 0, 0, 0
      if JIT > 0 then
        jx, jz = (math.random() * 2 - 1) * JIT, (math.random() * 2 - 1) * JIT
        jh = (math.random() * 2 - 1) * math.rad(1.5)
      end
      place(d.obj.body, btTransform(btQuaternion(btVector3(0, 1, 0), d.h + jh), btVector3(d.x + jx, H / 2, d.z + jz)))
    else
      -- taken out: laid flat on the table beside its pocket, out of the way
      -- (across the line, on the side toward you; the two side by side)
      local ax, az = math.cos(d.h), -math.sin(d.h)
      if az < 0 then ax, az = -ax, -az end
      local off = 9 + (d.i % 2) * 6
      local q = btQuaternion(btVector3(0, 1, 0), d.h) * btQuaternion(btVector3(1, 0, 0), math.pi / 2)
      place(d.obj.body, btTransform(q, btVector3(d.x + off * ax, T / 2 + 0.01, d.z + off * az)))
    end
  end
  for _, tl in pairs(tells) do
    place(tl.body, btTransform(btQuaternion(btVector3(0, 1, 0), tl.h), btVector3(tl.x, TELL_H / 2, tl.z)))
  end
  carryInlays()
  applyFriction()
  fell, t, running, reported = {}, 0, false, false
  goPending = true
  holdStart()
end

local function push()
  local d = byLine.GO[1]
  local h, w = d.h, 4
  d.obj.body:setAngularVelocity(btVector3(w * math.cos(h), 0, -w * math.sin(h)))
  d.obj.body:setLinearVelocity(btVector3(w * H / 2 * math.sin(h), w * T / 2, w * H / 2 * math.cos(h)))
  running, t = true, 0
end

-- ---------------------------------------------------------------------
-- the tour, and reading the answer
-- ---------------------------------------------------------------------
local RUN_S = envnum("DA_RUN", 6.5)
local TOUR = { { 0, 0 }, { 0, 1 }, { 1, 0 }, { 1, 1 } }
local tour = (os.getenv("DA_TOUR") or "1") ~= "0" and 1 or nil
local table_ = {}

local function down(body)
  return body:getCenterOfMassTransform():getBasis():getColumn(1).y < math.cos(math.rad(45))
end
local function answer()
  return down(tells.CARRY.body) and 1 or 0, down(tells.SUM.body) and 1 or 0
end
local function report()
  local c, s = answer()
  local want = inputs.A + inputs.B
  local ok = (2 * c + s) == want
  print(string.format("  %d + %d  ->  CARRY %d  SUM %d   (%d%d in binary: %d)  %s", inputs.A, inputs.B, c, s, c, s,
                      2 * c + s, ok and "right" or "WRONG"))
  if os.getenv("DA_DEBUG") then
    local parts = {}
    for _, n in ipairs(ORDER) do
      local k, str = 0, ""
      for _, d in ipairs(byLine[n]) do
        local f = down(d.obj.body)
        if f then k = k + 1 end
        str = str .. (f and "x" or ".")
      end
      parts[#parts + 1] = string.format("%s %d/%d %s", n, k, #byLine[n], #str <= 30 and str or "")
    end
    print("    fell: " .. table.concat(parts, " | "))
  end
  return ok
end

local function startCase()
  if tour then inputs.A, inputs.B = TOUR[tour][1], TOUR[tour][2] end
  setUp()
end
if tour then print("\nDOMINO HALF ADDER -- the tour: all four sums") end

v:preSim(function(N)
  if holdPre() then return end
  for k = 1, NSTEPS - 1 do v:stepSimulation(STEP, 0, STEP) end
end)

local fails = 0
v:postSim(function(N)
  carryInlays()
  if holdNow then return end
  if goPending then goPending = false; push(); return end
  if not running then return end
  t = t + FRAME_DT
  if t >= RUN_S and not reported then
    reported, running = true, false
    if not report() then fails = fails + 1 end
    if tour then
      tour = tour + 1
      if tour > #TOUR then
        tour = nil
        print(fails == 0 and "  all four right." or string.format("  %d WRONG.", fails))
        print("RESULT domino-adder tour: " .. (fails == 0 and "PASS" or "FAIL"))
      else
        startCase()
      end
    end
  end
end)

-- ---------------------------------------------------------------------
-- keys, sliders, help
-- ---------------------------------------------------------------------
v:addShortcut("T", function() tour = 1; fails = 0; print("\nthe tour: all four sums"); startCase() end)
v:addShortcut("A", function() tour = nil; inputs.A = 1 - inputs.A; setUp() end)
v:addShortcut("B", function() tour = nil; inputs.B = 1 - inputs.B; setUp() end)
v:addShortcut("G", function() if not running then goPending = false; push() end end)
v:addShortcut("R", function() tour = nil; setUp(); goPending = false end)
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
    "THE DOMINO HALF ADDER  (Babbage's Hall)",
    "",
    "A computer of dominoes: it adds two one-bit numbers, A and B. The",
    "answer is the two tiles at the far end, CARRY and SUM: each shows 0,",
    "and falls over to show 1.   0+0=00  0+1=01  1+0=01  1+1=10",
    "",
    "WHAT TO WATCH",
    "  The brass dominoes are the SWITCHES: standing, that input is 1;",
    "  laid aside, it is 0. The red one is GO.",
    "  A and B strike the two ends of the line across the middle. Alone,",
    "  a wave runs right along it and takes the branch up to SUM (blue).",
    "  Together, the two waves meet in the middle and stop: no SUM.",
    "  The carry (green) is A's long way round. When SUM falls, a branch of",
    "  it cuts the carry before A's wave gets there -- so the carry",
    "  finishes only when both inputs were 1: A AND B.",
    "",
    "KEYS",
    "  T  the tour: all four sums      G  GO",
    "  A  input A: 1 <-> 0             B  input B: 1 <-> 0",
    "  R  stand them all up again      Z  slow motion <-> real time",
    "",
    "Every part can be 3D printed: see the README in this exhibit's folder.",
  }, "\n"))
end)

if v.onHover then
  local WHAT = {
    GO = "GO: push this one and the sum begins",
    Ain = "input A: the brass pair is its switch (standing: A = 1)",
    Bin = "input B: the brass pair is its switch (standing: B = 1)",
    A = "A's feeder: it strikes the left end of the collision line",
    B = "B's feeder: it strikes the right end of the collision line",
    C = "the collision line: A's wave runs right, B's left; together they meet and stop",
    Tl = "taken only by a wave running LEFT along the collision line (B's): to SUM",
    Tr = "taken only by a wave running RIGHT along the collision line (A's): to SUM",
    SUM = "SUM = A XOR B",
    INH = "a branch of SUM: it cuts the carry line before A's wave arrives",
    A3 = "the carry: A's long way round (a delay line), cut by SUM -- so A AND B",
  }
  v:onHover(function(N, obj, x, y, z)
    local d = KEY[objectKey(obj)]
    if not d then return nil end
    if d.tell then
      local c, s = answer()
      local val = (d.tell == "CARRY") and c or s
      return string.format("the %s tell-tale: it shows %d\n(%d + %d = %d%d in binary)", d.tell, val,
                           inputs.A, inputs.B, c, s)
    end
    return WHAT[d.line] .. string.format("\n(input A = %d, B = %d)", inputs.A, inputs.B)
  end)
end

common.setCamera(btVector3(0, 95, TD / 2 + 70), btVector3(0, 0, -5))
startCase()
