--
-- Lehmer's number sieve -- Babbage's Hall
--
-- Derrick Lehmer's machines (1926 and 1932) found numbers that pass several
-- tests at once: one loop for each test, its length the test's modulus,
-- all turning together, marked where a number passes (rods on bicycle
-- chains, then holes in gears). Where every loop is marked at the reading
-- place, the number passes every test, and the machine stops.
--
-- Here: four wheels on one axle, of 9, 8, 7 and 5 places, one above the
-- other. One turn of the handle moves every wheel on by one place (each is
-- a Geneva star, driven by a pin on the drive shaft beside them, and
-- locked between turns by a disc on the shaft). So after x turns from 0,
-- the hole under the probe on the wheel of m places is the one marked
-- x mod m. Pegs close the holes of the numbers that fail. A probe above
-- the stack, at the reading place, is lifted by a cam on the shaft while
-- the wheels move and let down when they have stopped: it falls through as
-- many wheels as have an open hole under it, and when they all do, right
-- through to the bell at the bottom. The hand stops turning when it falls
-- right through, as Lehmer's motor was stopped.
--
-- THE BOARD on the table beside it shows what an operator would write up:
-- N and x, each wheel's hole under the probe (green open, red pegged), how
-- far the probe went, and at a stop x*x - N, whether it is a square, and
-- the factors. It is the exhibit's: nothing in the machine drives it. The
-- scale on the probe's guide is the machine's own (printed): the pointer on
-- the probe's top reads how many wheels it went through.
--
-- WHAT IT SIEVES: Fermat's way of factoring N. Look for x with x^2 - N a
-- square, y^2: then N = (x - y)(x + y). A square leaves only certain
-- remainders when divided by m, so x^2 - N can be a square only if x mod m
-- is one of a few: those holes are open, the rest pegged. The sieve finds
-- the x that pass all four tests at once; each is then tried by hand
-- (is x^2 - N a square?). Most fail -- the sieve only says "maybe" -- and
-- the machine is turned on.
--
--   1241:  x from 36. Stops at 39 (39^2 - 1241 = 280: no), then 45
--          (45^2 - 1241 = 784 = 28^2): 1241 = 17 x 73
--
-- KEYS
--   Space  one turn of the handle
--   G      go: turn until the probe falls right through (G again: stop)
--   N      choose the next number to factor (re-pegs the wheels and sets
--          them to its first x): 1241, 1679, 1157, 2813
--   R      set the wheels back to the first x
--   T      the tour for the number chosen (it starts with 1241's)
--   Z      slow motion (1/4) <-> real time
--
-- EVERY PART CAN BE PRINTED: see parts/ and README.md. The wheels, the
-- drive's pins and locking discs, the cam and the probe are the printed
-- parts' own outlines (parts/make-geometry.py writes both); they move each
-- other only by contact.
--
-- PHYSICS: the drive shaft is turned by a hand (a motor, steered to where
-- the keys put it); the wheels move only as its pins push them, and are
-- held only by its locking discs; the probe falls under its own weight and
-- is lifted only by the cam. Friction 0.25, 2400 steps a second.
--
-- Units: centimetres, kilograms, seconds.
-- Headless: LS_TOUR=0 (no tour), LS_N (the number to factor), LS_FRICTION,
-- LS_RATE (the hand's speed, turns a second), LS_LOG=1 (each turn's
-- reading); the tour prints RESULT lehmer-sieve tour: PASS or FAIL.
--

local common = require "common"
local function envnum(n, d) return tonumber(os.getenv(n) or "") or d end

-- ---------------------------------------------------------------------
-- this exhibit's folder; its geometry; the parts file by its full path
-- ---------------------------------------------------------------------
local DIR
for _, d in ipairs({ "", "demo/WyomingWill/BabbagesHall/exhibits/LehmerSieve/" }) do
  local f = io.open(d .. "sieve-geometry.lua", "r")
  if f then f:close(); DIR = d; break end
end
assert(DIR, "Lehmer's sieve: can't find its folder")
local G = dofile(DIR .. "sieve-geometry.lua")
local NW = #G.MODS

local SCAD
do
  local path = DIR .. "parts/lehmer-sieve.scad"
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
local SCAD_SUM = checksum({ SCAD, (SCAD:gsub("lehmer%-sieve%.scad$", "geometry.scad")) })
-- (the parts file is in cm, as the simulation; only to see: the shapes the
-- simulation touches with are built below from the same outlines)
local function part(call)
  local m = OpenSCAD("// " .. SCAD_SUM .. "\ninclude <" .. SCAD .. ">\n" .. call .. ";\n", 0, false)
  m.collides = false
  return m
end

-- ---------------------------------------------------------------------
-- sliders, timing, the pause at every start
-- ---------------------------------------------------------------------
v:addParam("friction", envnum("LS_FRICTION", 0.25), 0.1, 0.4, 0.05, "pin, slot, locking disc, cam and probe")
v:addParam("speed", 1, 0.05, 2, 0.05, "simulated seconds per real second (Z: 1/4 <-> 1)")
v:addParam("turn rate", envnum("LS_RATE", 0.5), 0.2, 1, 0.05, "how fast the hand turns the handle, turns a second")
local HZ = envnum("LS_HZ", 2400)               -- steps a simulated second
local STEP, NSTEPS, FRAME_DT = 1 / HZ, HZ / 60, 1 / 60
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
pcall(function() v:setSolverIterations(math.floor(envnum("LS_ITER", 20))) end)

-- ---------------------------------------------------------------------
-- the table, the frame
-- ---------------------------------------------------------------------
local ident = btQuaternion(0, 0, 0, 1)
local function qa(ax, ay, az, deg) return btQuaternion(btVector3(ax, ay, az), math.rad(deg)) end
local TABLE
do
  -- (into this exhibit's own environment: Lua 5.1 sets it after loading,
  -- 5.2 and later give it to loadfile)
  local path, f = DIR .. "../../exhibit-table.lua"
  if setfenv then f = assert(loadfile(path)); setfenv(f, getfenv(1))
  else f = assert(loadfile(path, "t", _ENV)) end
  TABLE = f()
end
-- (the base: x -12 to 15, z -9.5 to 9.5; the board, on its left, from x -44)
TABLE.build(59, 19, { x = -14.5, floor = 300 })

local function still(call, col, tr)
  local m = part(call)
  m.col = col
  v:add(m)
  m.trans = btTransform(ident, btVector3(0, 0, 0))
  if tr then pcall(function() m.transparency = tr end) end
  return m
end
local frame = still("base(); feet(); bearing(); shaftWasher(); guide()", "#4a3524")
still("axle(); axleTop()", "#9a9da3")
still("washers()", "#c9a14a")
local bell = still("bell()", "#d4af37")
local scaleMarks = still("depthScaleNumbers()", "#efe6cf")

local anchor = Cube(0.01, 0.01, 0.01, 0)     -- (only for the hinges to hold to: too small to see)
anchor.collides = false
v:add(anchor)
anchor.trans = btTransform(ident, btVector3(0, 0, 0))
local zToY = qa(1, 0, 0, -90)                -- a hinge's frame: its z up

-- ---------------------------------------------------------------------
-- bodies from convex pieces (in the machine's frame), their origin at the
-- centre of mass
-- ---------------------------------------------------------------------
local MARGIN = 0.005
local function hull(pts, c)
  local h = btConvexHullShape()
  for k = 1, #pts, 3 do h:addPoint(btVector3(pts[k] - c[1], pts[k + 1] - c[2], pts[k + 2] - c[3]), false) end
  h:recalcLocalAabb()
  h:setMargin(MARGIN)
  return h
end
-- a compound of many shapes, as a tree of small ones: bpp's Lua gives a
-- compound only a few dozen children (each one is kept alive by a
-- dependency of the compound's, and luabind has room for few), and small
-- groups of neighbours keep each group's bounds tight. items: { shape,
-- transform, sort key }
local FAN = 12
local function tree(items)
  table.sort(items, function(a, b) return a[3] < b[3] end)
  local level = items
  while true do
    local up = {}
    for k = 1, #level, FAN do
      local c = btCompoundShape(true)
      for j = k, math.min(k + FAN - 1, #level) do c:addChildShape(level[j][2], level[j][1]) end
      up[#up + 1] = { c, btTransform(ident, btVector3(0, 0, 0)), 0 }
    end
    if #up == 1 then return up[1][1] end
    level = up
  end
end
-- where a piece is, for grouping: by height, then round the axis (ax, az)
local function sortKey(pts, ax, az)
  local x, y, z, n = 0, 0, 0, 0
  for k = 1, #pts, 3 do x = x + pts[k]; y = y + pts[k + 1]; z = z + pts[k + 2]; n = n + 1 end
  x, y, z = x / n, y / n, z / n
  return math.floor(y * 2) * 10 + (math.atan2(z - az, x - ax) + math.pi) / (2 * math.pi)
end
local function body(obj, mass, com, inertia, shape)
  local tr = btTransform(ident, btVector3(com[1], com[2], com[3]))
  local b = btRigidBody(mass, btDefaultMotionState(tr), shape, btVector3(inertia[1], inertia[2], inertia[3]))
  obj.body = b
  obj.collides = true          -- (before it is added: a body's collisions are fixed then)
  v:add(obj)
  obj.trans = tr
  b:setCenterOfMassTransform(tr)
  b:setActivationState(4)
  b:setDamping(0, 0.05)
  return b
end

-- the wheels: each a Geneva star with its ring of holes; pegs close some
local wheels = {}
for i = 1, NW do
  local W = G.wheels[i]
  local items = {}
  for _, pts in ipairs(W.pieces) do items[#items + 1] = { hull(pts, W.com), btTransform(ident, btVector3(0, 0, 0)), sortKey(pts, 0, 0) } end
  -- the pegs: a group of their own, one for each hole; a peg not wanted is
  -- put inside the wheel's own hub, where it touches nothing
  local pegGroup = btCompoundShape(true)
  local hub = btTransform(zToY, btVector3(0, (W.y0 + W.y1) / 2 - W.com[2], 0))
  for k = 1, W.m do
    local ps = btCylinderShapeZ(btVector3(G.HOLE_R - 0.02, G.HOLE_R - 0.02, G.STAR_T / 2))
    ps:setMargin(MARGIN)
    pegGroup:addChildShape(hub, ps)
  end
  local c = btCompoundShape(true)
  c:addChildShape(btTransform(ident, btVector3(0, 0, 0)), tree(items))
  c:addChildShape(btTransform(ident, btVector3(0, 0, 0)), pegGroup)
  local o = part(string.format("translate([%.4f, %.4f, %.4f]) wheel(%d)", -W.com[1], -W.com[2], -W.com[3], i - 1))
  o.col = ({ "#b5893a", "#c39a4c", "#d0ab5e", "#ddbc70" })[i]
  local b = body(o, W.mass, W.com, W.inertia, c)
  local h = btHingeConstraint(anchor.body, b, btTransform(zToY, btVector3(W.com[1], W.com[2], W.com[3])),
                              btTransform(zToY, btVector3(0, 0, 0)))
  v:addConstraint(h)
  local nums = part(string.format("translate([%.4f, %.4f, %.4f]) wheelNumbers(%d)", -W.com[1], -W.com[2], -W.com[3], i - 1))
  nums.col = "#1e1812"
  v:add(nums)
  -- the pegs: one for each hole, in it or put away (inside the base, out of
  -- sight); and the shape the probe meets, added to the wheel's
  local pegs = {}
  for k = 1, W.m do
    local hx, hz = W.holes[k][1], W.holes[k][2]
    local p = part("pegShape()")
    p.col = "#a8322a"
    v:add(p)
    pegs[k] = { obj = p, off = btTransform(ident, btVector3(hx - W.com[1], W.y0 - W.com[2], hz - W.com[3])),
                at = btTransform(zToY, btVector3(hx - W.com[1], (W.y0 + W.y1) / 2 - W.com[2], hz - W.com[3])),
                away = btTransform(ident, btVector3(-9 + 1.2 * k, G.BASE_TOP - 1.0, -7 + 1.4 * i)) }
    p.trans = pegs[k].away
  end
  wheels[i] = { m = W.m, body = b, hinge = h, obj = o, nums = nums, pegs = pegs, shape = c, com = W.com,
                pegGroup = pegGroup, hub = hub,
                step = 360 / W.m, y0 = W.y0, y1 = W.y1 }
end

-- the detents: each a body (its nose and leaf) on a hinge at the leaf's
-- root, turned back by the leaf's own stiffness (3EI/L, from PLA's
-- modulus); a stop keeps the nose from going in further than DET_STOP
local detents = {}
for i = 1, NW do
  local D = G.detents[i]
  local n, r = D.nose, D.root
  -- (its centre of mass: the nose, and the leaf half way to the root)
  local mN = D.mass * 0.7
  local cx = (mN * n[1] + (D.mass - mN) * (n[1] + r[1]) / 2) / D.mass
  local cz = (mN * n[2] + (D.mass - mN) * (n[2] + r[2]) / 2) / D.mass
  local cy = (D.y0 + D.y1) / 2
  local c = btCompoundShape(true)
  local nose = btCylinderShapeZ(btVector3(G.DET_NR, G.DET_NR, G.STAR_T / 2))
  nose:setMargin(MARGIN)
  c:addChildShape(btTransform(zToY, btVector3(n[1] - cx, 0, n[2] - cz)), nose)
  local o = part(string.format("translate([%.4f, %.4f, %.4f]) detent(%d)", -cx, -cy, -cz, i - 1))
  o.col = "#e8dcc0"
  local L2 = (n[1] - r[1]) ^ 2 + (n[2] - r[2]) ^ 2
  local I = D.mass * L2 / 3 + 1e-5
  local b = body(o, D.mass, { cx, cy, cz }, { I, I, I }, c)
  b:setDamping(0, 0.9)
  local h = btHingeConstraint(anchor.body, b, btTransform(zToY, btVector3(r[1], cy, r[2])),
                              btTransform(zToY, btVector3(r[1] - cx, 0, r[2] - cz)))
  -- which way a right-handed turn about +y takes the nose: out (+1) or in
  local dx, dz = n[1] - r[1], n[2] - r[2]
  local nl = math.sqrt(n[1] * n[1] + n[2] * n[2])
  local s = ((dz) * n[1] / nl + (-dx) * n[2] / nl) > 0 and 1 or -1
  -- the stop: the nose no further in than DET_STOP (getHingeAngle counts
  -- the other way to a right-handed turn: see the drive's motor)
  local stopIn = G.DET_STOP / G.DET_L
  if s > 0 then h:setLimit(-0.6, stopIn, 0.9, 0.3, 1.0) else h:setLimit(-stopIn, 0.6, 0.9, 0.3, 1.0) end
  v:addConstraint(h)
  local mount = part(string.format("detentMount(%d)", i - 1))
  mount.col = "#4a3524"
  v:add(mount)
  mount.trans = btTransform(ident, btVector3(0, 0, 0))
  detents[i] = { body = b, hinge = h, obj = o, s = s, com = { cx, cy, cz }, st = {} }
end
local DET_PRE_A = G.DET_PRE / G.DET_L          -- (the preload, as a turn of the leaf about its root)

-- the drive: the shaft, the cranks and their pins, the locking discs, the cam
local drive
do
  local D = G.drive
  local items = {}
  for _, pts in ipairs(D.pieces) do items[#items + 1] = { hull(pts, D.com), btTransform(ident, btVector3(0, 0, 0)), sortKey(pts, G.C, 0) } end
  for _, cy in ipairs(D.cylinders) do
    local r, y0, y1, x, z = cy[1], cy[2], cy[3], cy[4], cy[5]
    local s = btCylinderShapeZ(btVector3(r, r, (y1 - y0) / 2))      -- (bpp's Lua has the cylinders along x and z: one along z, stood up)
    s:setMargin(MARGIN)
    items[#items + 1] = { s, btTransform(zToY, btVector3(x - D.com[1], (y0 + y1) / 2 - D.com[2], z - D.com[3])), 1e6 + #items }
  end
  local c = tree(items)
  local calls = {}
  for i = 0, NW - 1 do calls[#calls + 1] = string.format("crank(%d); lock(%d)", i, i) end
  local o = part(string.format("translate([%.4f, %.4f, %.4f]) { %s; }", -D.com[1], -D.com[2], -D.com[3],
                               table.concat(calls, "; ")))
  o.col = "#3c4146"
  local b = body(o, D.mass, D.com, D.inertia, c)
  local h = btHingeConstraint(anchor.body, b, btTransform(zToY, btVector3(G.C, D.com[2], 0)),
                              btTransform(zToY, btVector3(G.C - D.com[1], 0, -D.com[3])))
  v:addConstraint(h)
  local pins = part(string.format("translate([%.4f, %.4f, %.4f]) { %s }", -D.com[1], -D.com[2], -D.com[3],
                                  "pin(0); pin(1); pin(2); pin(3); shaft();"))
  pins.col = "#a8acb2"
  v:add(pins)
  local handle = part(string.format("translate([%.4f, %.4f, %.4f]) handle()", -D.com[1], -D.com[2], -D.com[3]))
  handle.col = "#2a2622"
  v:add(handle)
  local camObj = part(string.format("translate([%.4f, %.4f, %.4f]) cam()", -D.com[1], -D.com[2], -D.com[3]))
  camObj.col = "#b8892e"
  pcall(function() camObj.transparency = 0.3 end)      -- (to see the drive through it)
  v:add(camObj)
  drive = { body = b, hinge = h, obj = o, riders = { pins, handle, camObj } }
end

-- the probe: its rod and the ball the cam lifts; it slides up and down in
-- its guide (a slider), and comes to rest on a wheel, or on the bell
local probe
do
  local P = G.probe
  local c = btCompoundShape(true)
  local rodY = G.TIP_HIGH + G.PROBE_LEN / 2
  local rod = btCylinderShapeZ(btVector3(G.PROBE_R, G.PROBE_R, G.PROBE_LEN / 2))
  rod:setMargin(MARGIN)
  c:addChildShape(btTransform(zToY, btVector3(P.x - P.com[1], rodY - P.com[2], -P.com[3])), rod)
  local ball = btSphereShape(G.FOLLOW_R)
  c:addChildShape(btTransform(ident, btVector3(P.xf - P.com[1], P.yf - P.com[2], -P.com[3])), ball)
  local o = part(string.format("translate([%.4f, %.4f, %.4f]) probeRod()", -P.com[1], -P.com[2], -P.com[3]))
  o.col = "#c0c4c8"
  local b = body(o, P.mass, P.com, P.inertia, c)
  b:setDamping(0.2, 0.2)
  local xToY = qa(0, 0, 1, 90)
  local s = btSliderConstraint(anchor.body, b, btTransform(xToY, btVector3(P.com[1], P.com[2], P.com[3])),
                               btTransform(xToY, btVector3(0, 0, 0)), true)
  s:setLowerLinLimit(G.TIP_LOW - G.TIP_HIGH)
  s:setUpperLinLimit(1.0)
  s:setLowerAngLimit(0); s:setUpperAngLimit(0)
  v:addConstraint(s)
  local arm = part(string.format("translate([%.4f, %.4f, %.4f]) { probeArm(); }", -P.com[1], -P.com[2], -P.com[3]))
  arm.col = "#6e5a3a"
  v:add(arm)
  local ballObj = part(string.format("translate([%.4f, %.4f, %.4f]) ball()", -P.com[1], -P.com[2], -P.com[3]))
  ballObj.col = "#d8dadc"
  v:add(ballObj)
  local pointer = part(string.format("translate([%.4f, %.4f, %.4f]) probePointer()", -P.com[1], -P.com[2], -P.com[3]))
  pointer.col = "#c9a14a"
  v:add(pointer)
  probe = { body = b, slider = s, obj = o, riders = { arm, ballObj, pointer }, com = P.com }
end
pcall(function() v.showConstraints = false end)

local function applyFriction()
  local f = v:getParam("friction")
  for _, w in ipairs(wheels) do w.body:setFriction(f); w.body:setRestitution(0) end
  drive.body:setFriction(f); drive.body:setRestitution(0)
  probe.body:setFriction(f); probe.body:setRestitution(0)
  for _, d in ipairs(detents) do d.body:setFriction(f); d.body:setRestitution(0) end
end
applyFriction()

local function moveRiders()
  for _, w in ipairs(wheels) do
    local tr = w.body:getCenterOfMassTransform()
    w.nums.trans = tr
    for _, p in ipairs(w.pegs) do
      if p.on then local t = btTransform(); t:mult(tr, p.off); p.obj.trans = t else p.obj.trans = p.away end
    end
  end
  local td = drive.body:getCenterOfMassTransform()
  for _, r in ipairs(drive.riders) do r.trans = td end
  local tp = probe.body:getCenterOfMassTransform()
  for _, r in ipairs(probe.riders) do r.trans = tp end
end

-- ---------------------------------------------------------------------
-- the board: what the operator would write up, on drums like a counter's
-- (the exhibit's, not the machine's: nothing in the machine drives it).
-- N and x; the hole under the probe on each wheel, green if open, red if
-- pegged; how many wheels the probe went through; at a stop, x*x - N and
-- whether it is a square; and, when it is, y and the factors.
-- ---------------------------------------------------------------------
local BOARD
do
  local W, H = 25, 18
  local DW, PITCH = 0.8, 0.9                   -- a digit drum's width, and their spacing
  local ROW = { 15.2, 11.1, 7.0, 2.9 }
  local wins, labels, drums = {}, {}, {}
  local function label(t, x, row, size) labels[#labels + 1] = string.format('["%s", %.2f, %.2f, %.2f]', t, x, ROW[row], size or 0.75) end
  -- a run of n digit drums, left to right from x
  local function digits(name, x, row, n)
    local d = {}
    for k = 1, n do
      local cx = x + (k - 1) * PITCH
      wins[#wins + 1] = string.format("[%.2f, %.2f, %.2f]", cx, ROW[row], DW)
      d[k] = { x = cx, y = ROW[row], w = DW, words = false }
    end
    drums[name] = d
  end
  label("N", 0.8, 1); digits("N", 2.6, 1, 4)
  label("x", 8.0, 1); digits("x", 9.8, 1, 3)
  for j, m in ipairs({ 5, 7, 8, 9 }) do
    label("mod " .. m, 0.8 + (j - 1) * 4.4, 2, 0.6); digits("r" .. m, 4.1 + (j - 1) * 4.4, 2, 1)
  end
  label("through", 18.2, 2, 0.6); digits("through", 22.1, 2, 1); label("of 4", 22.9, 2, 0.6)
  label("x\\u00b2\\u2212N", 0.8, 3); digits("xsq", 3.7, 3, 5)
  wins[#wins + 1] = string.format("[%.2f, %.2f, %.2f]", 11.9, ROW[3], 6.6)
  drums.verdict = { { x = 11.9, y = ROW[3], w = 6.6, words = true } }
  label("y", 15.9, 3); digits("y", 17.5, 3, 3)
  label("factors", 0.8, 4); digits("f1", 4.7, 4, 3); label("\\u00d7", 7.5, 4); digits("f2", 8.9, 4, 3)
  -- where it stands: turned 20 degrees toward the machine, its front bottom
  -- left corner here
  local q = qa(0, 1, 0, 20)
  local tr = btTransform(q, btVector3(-42.5, 1.5, 6))
  local box = part(string.format("boardBox(%.2f, %.2f, [%s])", W, H, table.concat(wins, ",")))
  box.col = "#3a2818"
  v:add(box)
  box.trans = tr
  local lab = part(string.format("boardLabels([%s])", table.concat(labels, ",")))
  lab.col = "#e8d7a8"
  v:add(lab)
  lab.trans = tr
  local ZC = -0.35 - 1.7                       -- (a drum's axis behind the face: DRUM_R in lehmer-sieve.scad)
  for _, list in pairs(drums) do
    for _, d in ipairs(list) do
      d.body = part(string.format("drumBody(%.2f)", d.w))
      d.body.col = "#efe6cf"
      v:add(d.body)
      d.face = part(d.words and "drumWords()" or "drumDigits()")
      d.face.col = "#1e1812"
      v:add(d.face)
      d.cur, d.want = 10, 10                    -- (the blank face; the word drum's is 0)
      if d.words then d.cur, d.want = 0, 0 end
    end
  end
  BOARD = { tr = tr, drums = drums, box = box, labels = lab, zc = ZC }
end
local DRUM_A = 360 / 11
local function placeDrum(d)
  local t = btTransform()
  t:mult(BOARD.tr, btTransform(qa(1, 0, 0, -d.cur * DRUM_A), btVector3(d.x, d.y, BOARD.zc)))
  d.body.trans = t
  d.face.trans = t
end
-- each drum turns forward to its new face, as a counter's do
local function turnDrums()
  for _, list in pairs(BOARD.drums) do
    for _, d in ipairs(list) do
      if d.cur ~= d.want then
        local delta = (d.want - d.cur) % 11
        local step = math.max(0.08, delta * 0.2)
        if delta <= step then d.cur = d.want else d.cur = (d.cur + step) % 11 end
        placeDrum(d)
      end
    end
  end
end
-- a number on a run of drums, right-aligned (nil: blank)
local function showNumber(name, value)
  local list = BOARD.drums[name]
  local s = value and tostring(math.floor(value)) or ""
  if #s > #list then s = string.rep("9", #list) end
  for k = 1, #list do
    local j = #s - (#list - k)
    list[k].want = (j >= 1) and tonumber(s:sub(j, j)) or 10
  end
end
local function showWords(k) BOARD.drums.verdict[1].want = k end
for _, list in pairs(BOARD.drums) do for _, d in ipairs(list) do placeDrum(d) end end

-- ---------------------------------------------------------------------
-- reading the machine
-- ---------------------------------------------------------------------
-- a body's turn about +y (right-handed), unwrapped from its last
local function turnOf(b, st)
  local x = b:getCenterOfMassTransform():getBasis():getColumn(0)
  local a = math.atan2(-x.z, x.x)
  if st.last then
    local d = a - st.last
    if d > math.pi then d = d - 2 * math.pi elseif d < -math.pi then d = d + 2 * math.pi end
    st.acc = st.acc + d
  else st.acc = a end
  st.last = a
  return st.acc
end
local driveSt = {}
local function driveTurns() return (turnOf(drive.body, driveSt) - driveSt.zero) / (2 * math.pi) end
-- a wheel's places moved on (it turns the other way to the drive)
local function wheelPlaces(i)
  local w = wheels[i]
  w.st = w.st or {}
  return -(turnOf(w.body, w.st) - w.st.zero) / math.rad(w.step)
end
-- the hole under the probe: x mod m, as the wheel stands
local function residue(i) return math.floor(wheelPlaces(i) + 0.5) % wheels[i].m end
-- the probe's tip, and how many wheels it has fallen through (from the top)
-- (btTransform has no getOrigin in bpp's Lua: the tip from the slider)
local function tipY() return G.TIP_HIGH + probe.slider:getLinearPos() end
local function through()
  local y, n = tipY(), 0
  for i = NW, 1, -1 do
    if y < wheels[i].y0 - 0.05 then n = n + 1 else break end
  end
  return n
end

-- ---------------------------------------------------------------------
-- the numbers to factor; the pegs for each
-- ---------------------------------------------------------------------
local PROBLEMS = { 1241, 1679, 1157, 2813 }
local function isqrt(n) local r = math.floor(math.sqrt(n)); while r * r > n do r = r - 1 end; while (r + 1) * (r + 1) <= n do r = r + 1 end; return r end
local function squaresMod(m) local s = {}; for k = 0, m - 1 do s[(k * k) % m] = true end; return s end
-- the holes open on the wheel of m places, for N: x mod m with x^2 - N a
-- square mod m
local function openHoles(N, m)
  local sq, o = squaresMod(m), {}
  for r = 0, m - 1 do o[r] = sq[(r * r - N) % m] or false end
  return o
end
local N, X0
local OPEN = {}
local function setPegs()
  for i, w in ipairs(wheels) do
    OPEN[i] = openHoles(N, w.m)
    for k = 1, w.m do
      local p = w.pegs[k]
      local want = not OPEN[i][k - 1]
      w.pegGroup:updateChildTransform(k - 1, want and p.at or w.hub, true)
      p.on = want
    end
    w.shape:updateChildTransform(1, btTransform(ident, btVector3(0, 0, 0)), true)   -- (the pegs' group: its bounds again)
  end
end
local function holesText(i)
  local t = {}
  for r = 0, wheels[i].m - 1 do if OPEN[i][r] then t[#t + 1] = tostring(r) end end
  return table.concat(t, " ")
end

-- set the wheels to x (by hand: each lifted and turned to the place
-- marked x mod m), the drive at rest, the probe down on them
local turnsDone, X                           -- the turns since the start, and x
local function setTo(x)
  for i, w in ipairs(wheels) do
    local r = x % w.m
    local q = qa(0, 1, 0, -r * w.step)
    w.body:setCenterOfMassTransform(btTransform(q, btVector3(w.com[1], w.com[2], w.com[3])))
    w.body:setLinearVelocity(btVector3(0, 0, 0)); w.body:setAngularVelocity(btVector3(0, 0, 0))
    w.st = { }
    turnOf(w.body, w.st); w.st.zero = w.st.acc + r * math.rad(w.step)
  end
  local D = G.drive
  drive.body:setCenterOfMassTransform(btTransform(ident, btVector3(D.com[1], D.com[2], D.com[3])))
  drive.body:setLinearVelocity(btVector3(0, 0, 0)); drive.body:setAngularVelocity(btVector3(0, 0, 0))
  driveSt = {}; turnOf(drive.body, driveSt); driveSt.zero = driveSt.acc
  for _, d in ipairs(detents) do
    d.body:setCenterOfMassTransform(btTransform(ident, btVector3(d.com[1], d.com[2], d.com[3])))
    d.body:setLinearVelocity(btVector3(0, 0, 0)); d.body:setAngularVelocity(btVector3(0, 0, 0))
    d.st = {}; turnOf(d.body, d.st); d.st.zero = d.st.acc
  end
  local P = probe.com
  probe.body:setCenterOfMassTransform(btTransform(ident, btVector3(P[1], P[2], P[3])))
  probe.body:setLinearVelocity(btVector3(0, 0, 0)); probe.body:setAngularVelocity(btVector3(0, 0, 0))
  turnsDone, X = 0, x
end
-- the board, from the machine as it stands (stopped: what the probe found)
local function boardShow(n)
  showNumber("N", N)
  showNumber("x", X)
  for i, w in ipairs(wheels) do
    local r = residue(i)
    local d = BOARD.drums["r" .. w.m][1]
    d.want = r
    d.body.col = OPEN[i][r] and "#9fd29a" or "#e39b93"
  end
  showNumber("through", n)
  if n == NW then
    local y2 = X * X - N
    local y = isqrt(y2)
    showNumber("xsq", y2)
    if y * y == y2 then
      showWords(2); showNumber("y", y); showNumber("f1", X - y); showNumber("f2", X + y)
    else
      showWords(1); showNumber("y", nil)
    end
  else
    showNumber("xsq", nil); showWords(0); showNumber("y", nil)
  end
end
-- while the wheels turn: only N and x stay up
local function boardTurning()
  showNumber("through", nil); showNumber("xsq", nil); showWords(0); showNumber("y", nil)
end
local function boardClear()
  boardTurning(); showNumber("f1", nil); showNumber("f2", nil)
  for _, w in ipairs(wheels) do BOARD.drums["r" .. w.m][1].body.col = "#efe6cf" end
end
local function setProblem(n)
  N = n
  X0 = isqrt(N); if X0 * X0 < N then X0 = X0 + 1 end
  setPegs()
  setTo(X0)
  boardClear()
  showNumber("N", N); showNumber("x", X0)
  print(string.format("LEHMER'S SIEVE: N = %d; x from %d (the first whose square is past N)", N, X0))
  for i = NW, 1, -1 do print(string.format("  the wheel of %d: open at %s", wheels[i].m, holesText(i))) end
end
setProblem(math.floor(envnum("LS_N", PROBLEMS[1])))

-- ---------------------------------------------------------------------
-- the hand: it turns the handle to where the keys put it, a whole turn at
-- a time, and holds it there
-- ---------------------------------------------------------------------
local target = 0                              -- in turns from the start
local running = false                         -- G: turning until the probe falls through
local turning = false                         -- a turn under way (its end not yet read)
local readIn = nil                            -- seconds until the wheels are read where they stand (at the start)
-- (Bullet's hinge motor turns the other way to a right-handed turn about
-- the hinge's axis, as getHingeAngle counts: measured)
local SIGN = -1
local function steer()
  -- each detent's leaf, bent, pushes its nose back in
  for _, d in ipairs(detents) do
    local out = d.s * (turnOf(d.body, d.st) - d.st.zero)
    d.body:applyTorque(btVector3(0, -d.s * G.DET_K * (out + DET_PRE_A), 0))
  end
  local rate = v:getParam("turn rate") * 2 * math.pi
  local err = (target - driveTurns()) * 2 * math.pi
  local w = math.max(-rate, math.min(rate, 8 * err))
  drive.hinge:enableAngularMotor(true, SIGN * w, 5)
end
local function handBusy() return math.abs(target - driveTurns()) > 0.002 end

-- ---------------------------------------------------------------------
-- the tour, and what is said at each turn's end
-- ---------------------------------------------------------------------
local tour = (os.getenv("LS_TOUR") or "1") ~= "0" and 1 or nil
local LOG = os.getenv("LS_LOG")
local fails, wait, started = 0, 0, false
local function crt()
  -- the x the wheels show, from their places alone: x mod 2520
  for x = 0, 2519 do
    local ok = true
    for i = 1, NW do if x % wheels[i].m ~= residue(i) then ok = false; break end end
    if ok then return x end
  end
end
local function expectedThrough(x)
  local n = 0
  for i = NW, 1, -1 do if OPEN[i][x % wheels[i].m] then n = n + 1 else break end end
  return n
end
-- at the end of a turn: read it, check it, say it
local found = nil
local function endOfTurn()
  local n, want = through(), expectedThrough(X)
  boardShow(n)
  local shows = crt()
  local ok = (n == want) and (shows == X % 2520)
  if not ok then fails = fails + 1 end
  if LOG or tour or not ok then
    local ws = {}
    for i = NW, 1, -1 do
      local r = residue(i)
      ws[#ws + 1] = string.format("mod %d: %d %s", wheels[i].m, r, OPEN[i][r] and "open" or "pegged")
    end
    print(string.format("  x = %d   %s   -> the probe through %d of %d%s", X, table.concat(ws, ", "), n, NW,
                        ok and "" or string.format("   WRONG (it should be %d; the wheels show x = %s)", want, tostring(shows))))
  end
  if n == NW then
    local y2 = X * X - N
    local y = isqrt(y2)
    if y * y == y2 then
      found = { X - y, X + y }
      print(string.format("  the probe falls right through, and the bell rings: x = %d. %d^2 - %d = %d = %d^2,", X, X, N, y2, y))
      print(string.format("  so %d = (%d - %d)(%d + %d) = %d x %d", N, X, y, X, y, X - y, X + y))
    else
      print(string.format("  the probe falls right through: x = %d. But %d^2 - %d = %d is not a square (%d^2 = %d):",
                          X, X, N, y2, y, y * y))
      print("  the sieve only says it might be. Turn on.")
    end
  end
  return n == NW
end
if tour then print("\nLEHMER'S NUMBER SIEVE -- the tour: factoring " .. N .. " by Fermat's way") end

-- ---------------------------------------------------------------------
-- at rest: once the hand has nothing to do and nothing has moved for
-- REST_S, the simulation stops stepping (LS_REST=0: never; LS_REST_LOG=1:
-- say so, and print the fastest part's speeds each second)
-- ---------------------------------------------------------------------
local restBodies = { drive.body, probe.body }
for _, w in ipairs(wheels) do restBodies[#restBodies + 1] = w.body end
for _, d in ipairs(detents) do restBodies[#restBodies + 1] = d.body end
local REST_S = 0.5
local REST_V, REST_W = 0.05, 0.02
local REST_ON = os.getenv("LS_REST") ~= "0"
local REST_LOG = os.getenv("LS_REST_LOG")
local restFor, resting, restLogT = 0, false, 0
local function fastest()
  local mv, mw = 0, 0
  for _, b in ipairs(restBodies) do
    mv = math.max(mv, b:getLinearVelocity():length())
    mw = math.max(mw, b:getAngularVelocity():length())
  end
  return mv, mw
end
local function wantsWork() return handBusy() or running or (tour ~= nil) or turning or not started end
local function restPre()
  if not resting then return false end
  if wantsWork() then
    resting, restFor = false, 0
    applyTiming()
    if REST_LOG then print("  (stepping again)") end
    return false
  end
  v.timeStep = 0
  return true
end
local function restPost()
  if resting then return end
  if wantsWork() then restFor = 0; return end
  local mv, mw = fastest()
  if REST_LOG then
    restLogT = restLogT + FRAME_DT
    if restLogT >= 1 then restLogT = 0; print(string.format("  at rest? fastest part %.4f cm/s, %.4f rad/s", mv, mw)) end
  end
  if mv < REST_V and mw < REST_W then restFor = restFor + FRAME_DT else restFor = 0 end
  if REST_ON and restFor >= REST_S then
    resting = true
    v.timeStep = 0
    if REST_LOG then print("  (at rest: not stepping)") end
  end
end

-- ---------------------------------------------------------------------
-- stepping
-- ---------------------------------------------------------------------
local logT = 0
local boardCleared = true
local PAUSE = 0.6                         -- (seconds between turns when it goes on by itself: time to read the depth)
local function oneTurn()
  if turning then return end
  turning = true
  target = target + 1
  wait = 0
  boardCleared = false                    -- (the depth stays up until the cam starts to lift the probe)
end
-- after a reading: stop if the probe fell right through; the tour goes on
-- past a false stop, and ends at the true one
local function afterReading(stop)
  if stop then running = false end
  if tour and stop and found then
    tour = nil
    local okF = found[1] * found[2] == N and found[1] > 1
    if not okF then fails = fails + 1 end
    print("RESULT lehmer-sieve tour: " .. ((fails == 0 and okF) and "PASS" or "FAIL"))
  elseif tour then
    running = true
    if stop then wait = -1.5 end            -- (a moment to look)
  end
  if running and wait >= 0 then wait = -PAUSE end
end
v:preSim(function(N_)
  if holdPre() then return end
  if restPre() then return end
  for k = 1, NSTEPS do
    steer()
    if k < NSTEPS then v:stepSimulation(STEP, 0, STEP) end
  end
end)
v:postSim(function(N_)
  moveRiders()
  turnDrums()
  if holdNow then return end
  restPost()
  if LOG == "2" then
    logT = (logT or 0) + FRAME_DT
    if logT >= envnum("LS_LOGDT", 0.5) then
      logT = 0
      local ps = {}
      for i = NW, 1, -1 do ps[#ps + 1] = string.format("%d: %.3f", wheels[i].m, wheelPlaces(i)) end
      local ds = {}
      for i = NW, 1, -1 do local d = detents[i]; ds[#ds + 1] = string.format("%.2f", 10 * G.DET_L * d.s * (turnOf(d.body, d.st) - d.st.zero)) end
      print(string.format("    the handle %.3f turns (to %d); the wheels' places %s; the probe's tip %.2f; the detents' noses out %s mm",
                          driveTurns(), target, table.concat(ps, "  "), tipY(), table.concat(ds, " ")))
    end
  end
  if not started then
    started = true
    readIn = 0.5                          -- (the probe settles on the wheels first)
  end
  if readIn then
    readIn = readIn - FRAME_DT
    if readIn <= 0 then
      readIn = nil
      local stop = endOfTurn()
      if os.getenv("LS_GO") then running = true end
      afterReading(stop)
    end
    return
  end
  -- the board: the depth and the working blanked once the cam begins to
  -- lift the probe (the reading they showed no longer stands)
  if turning and not boardCleared and driveTurns() - (target - 1) > G.RISE[1] / 360 then
    boardCleared = true
    boardTurning()
  end
  -- the hand: done with a turn when the handle is back at rest and it has
  -- had a moment to settle; then the next, if it is going on
  if turning and math.abs(driveTurns() - target) < 0.003 then
    wait = wait + FRAME_DT
    if wait > 0.3 then
      turning, wait = false, 0
      turnsDone = turnsDone + 1
      X = X0 + turnsDone
      afterReading(endOfTurn())
    end
  end
  if running and not turning then
    if wait < 0 then wait = wait + FRAME_DT else oneTurn() end
  end
end)

-- ---------------------------------------------------------------------
-- keys, sliders, help
-- ---------------------------------------------------------------------
local function stopTour() tour = nil end
v:addShortcut("Space", function() stopTour(); running = false; oneTurn() end)
v:addShortcut("G", function()
  stopTour()
  running = not running
  print(running and "LEHMER'S SIEVE: turning until the probe falls through" or "LEHMER'S SIEVE: stopped")
end)
local function restart(n, tourToo)
  running, turning, found, wait = false, false, nil, 0
  target = 0
  if tourToo then tour = 1; fails = 0; print("\nthe tour: factoring " .. n .. " by Fermat's way") end
  setProblem(n)
  started, resting = false, false            -- (the wheels are read again where they now stand)
  holdStart()
end
v:addShortcut("N", function()
  stopTour()
  local k = 1
  for j, p in ipairs(PROBLEMS) do if p == N then k = j % #PROBLEMS + 1 end end
  restart(PROBLEMS[k])
end)
v:addShortcut("R", function() stopTour(); restart(N) end)
v:addShortcut("T", function() restart(N, true) end)       -- (the tour for the number N chose)
v:addShortcut("Z", function()
  local sp = v:getParam("speed") < 0.5 and 1 or 0.25
  v:addParam("speed", sp, 0.05, 2, 0.05, "simulated seconds per real second (Z: 1/4 <-> 1)")
  applyTiming()
end)
v:onParamChanged(function(N_, name, value)
  if name == "speed" then applyTiming()
  elseif name == "friction" then applyFriction() end
end)
pcall(function()
  v:setHelpText(table.concat({
    "LEHMER'S NUMBER SIEVE  (Babbage's Hall)",
    "",
    "Four wheels of 9, 8, 7 and 5 places. One turn of the handle moves every",
    "wheel on by one place, so after x turns the hole under the probe on the",
    "wheel of m places is the one marked x mod m. Pegs close the holes of the",
    "numbers that fail a test. When every wheel has an open hole under it,",
    "the probe falls right through, the bell rings, and the hand stops.",
    "",
    "IT FACTORS N, by Fermat's way: it looks for x with x*x - N a square",
    "y*y, for then N = (x - y)(x + y). A square leaves only some remainders",
    "when divided by m, so only some x mod m can do: those holes are open.",
    "Each x the sieve finds is tried by hand; most aren't squares after all.",
    "",
    "WHAT TO WATCH",
    "  Each wheel is a Geneva star: the drive's pin enters a slot and turns",
    "  it one place, and the locking disc holds it between turns.",
    "  The cam lifts the probe before the wheels move, and lets it down after.",
    "",
    "KEYS",
    "  Space  one turn         G  turn until the probe falls through",
    "  N      choose the next number (1241, 1679, 1157, 2813)",
    "  T      the tour for that number   R  back to its first x",
    "  Z      slow motion",
    "",
    "THE BOARD on the left shows N and x; the hole under the probe on each",
    "wheel (green: open, red: pegged); how many wheels the probe went through;",
    "and at a stop, x*x - N, whether it is a square, and the factors.",
    "The scale beside the probe's top reads how many wheels it went through.",
  }, "\n"))
end)
if v.onHover then
  local KEY = {}
  for i, w in ipairs(wheels) do KEY[objectKey(w.obj)] = i; KEY[objectKey(w.nums)] = i end
  local P_KEY = {}
  P_KEY[objectKey(probe.obj)] = "probe"
  for _, r in ipairs(probe.riders) do P_KEY[objectKey(r)] = "probe" end
  P_KEY[objectKey(drive.obj)] = "drive"
  for _, r in ipairs(drive.riders) do P_KEY[objectKey(r)] = "drive" end
  P_KEY[objectKey(bell)] = "bell"
  P_KEY[objectKey(BOARD.box)] = "board"; P_KEY[objectKey(BOARD.labels)] = "board"
  for _, list in pairs(BOARD.drums) do for _, d in ipairs(list) do P_KEY[objectKey(d.body)] = "board"; P_KEY[objectKey(d.face)] = "board" end end
  P_KEY[objectKey(scaleMarks)] = "scale"
  v:onHover(function(N_, obj, x, y, z)
    local i = KEY[objectKey(obj)]
    local head = string.format("N = %d, x = %d (x*x - N = %d)", N, X, X * X - N)
    if i then
      local w = wheels[i]
      return string.format("the wheel of %d places: x mod %d = %d (%s)\nopen for N = %d at %s\n%s",
                           w.m, w.m, residue(i), OPEN[i][residue(i)] and "open" or "pegged", N, holesText(i), head)
    end
    local k = P_KEY[objectKey(obj)]
    if k == "probe" then
      return string.format("the probe: through %d of the %d wheels\n%s", through(), NW, head)
    elseif k == "drive" then
      return "the drive: each turn of the handle moves every wheel on one place;\n" ..
             "the cam on top lifts the probe while they move\n" .. head
    elseif k == "bell" then
      return "the bell: the probe reaches it only through an open hole in every wheel\n" .. head
    elseif k == "board" then
      return "the board (the exhibit's, not the machine's): N and x; the hole under the probe on\n" ..
             "each wheel, green if open, red if pegged; how many wheels the probe went through;\n" ..
             "at a stop, x*x - N, whether it is a square, and the factors. N chooses the number, T its tour."
    elseif k == "scale" then
      return string.format("the depth scale: the pointer on the probe's top reads how many wheels\n" ..
                           "it has gone through (4: right through, onto the bell). Now %d.\n%s", through(), head)
    end
    return nil
  end)
end

common.setCamera(btVector3(-19, 30, 60), btVector3(-15.5, 7, 0))
moveRiders()
holdStart()
