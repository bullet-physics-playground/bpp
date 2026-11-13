--
-- The Galton board -- Babbage's Hall
--
-- Francis Galton's quincunx (made for him by Tisley and Spiller, London, 1873;
-- described in 1877 and in his "Natural Inheritance", 1889):
-- balls falling through rows of pins, each pin sending a ball left or right,
-- pile up in the bins below in the bell of the normal curve. With twelve
-- rows each ball makes twelve choices; the bin it ends in counts how many
-- went right, and if every pin were a fair coin the bins would fill as the
-- binomial distribution: 1, 12, 66, 220, 495, 792, 924, ... in 4096. The
-- lines engraved in the bins are where 150 balls would come to then.
--
-- Two metering wheels at the foot of the hopper, mirror images geared
-- together and turned by one crank, let the balls in one at a time, through
-- a funnel and neck over the first pin; a slide under the bins lets
-- them down into a drawer, and the operator tips the drawer back into the
-- hopper. The sign beside it (the exhibit's) shows the run, how many balls
-- are in the bins, their mean bin and their spread (the standard deviation),
-- against 6 and 1.73 for fair coins.
--
-- KEYS
--   Space  turn the crank: run the balls through (again: stop)
--   E      empty the bins into the drawer and pour it back into the hopper
--   T      the tour: a run, empty and pour back, a second run
--
-- EVERY PART CAN BE PRINTED: see parts/ and README.md. The balls, the pins
-- and the walls are the printed board's; the wheels turn by the crank.
--
-- PHYSICS: 150 steel balls (6 mm, 0.88 g) between a printed back plate and a
-- clear front sheet 7 mm apart; 4 mm pins 12 mm apart; restitution 0.4 and
-- friction 0.3, ball on board (the "bounce" and "friction" sliders); 2400
-- steps a second. The hand on the crank is a motor at a steady speed (the
-- gears, a lock holding both wheels to the crank's turn); the
-- operator's other jobs (the slide, the drawer) are done by the drawn hand,
-- and the pouring moves the balls from the drawer to the hopper's top a few
-- at a time.
--
-- Units: centimetres, kilograms, seconds (the board's sizes in mm, from
-- galton-geometry.lua).
-- Headless: GB_TOUR=0 (no tour), GB_BALLS (how many), GB_CRANK (turns a
-- second), GB_BOUNCE, GB_FRICTION, GB_LOG=1 (a line every 5 s), GB_REST=0
-- (never rest), GB_HAND=0 (no hand drawn), GB_PATHS=<file> (each ball's
-- path through the pins, for paths.py: FINDINGS section 6).
--

local common = require "common"
local function envnum(n, d) return tonumber(os.getenv(n) or "") or d end
local LOG = os.getenv("GB_LOG")

-- ---------------------------------------------------------------------
-- this exhibit's folder; the parts files, by their full paths (for OpenSCAD)
-- ---------------------------------------------------------------------
local DIR
for _, d in ipairs({ "", "demo/WyomingWill/BabbagesHall/exhibits/GaltonBoard/" }) do
  local f = io.open(d .. "galton-geometry.lua", "r")
  if f then f:close(); DIR = d; break end
end
assert(DIR, "The Galton board: can't find its folder")
local G = dofile(DIR .. "galton-geometry.lua")
do   -- (GB_GEO="CHUTE_X=-1.5 S=13": sizes to try, headless; not for the printed board)
  local o, any = {}, false
  for k, x in (os.getenv("GB_GEO") or ""):gmatch("([%w_]+)=([%d.-]+)") do o[k] = tonumber(x); any = true end
  if any then G = G.build(o); GB_TRYING = true end
end
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
local SCAD = fullPath(DIR .. "parts/galton.scad")
local HAND_SCAD = fullPath(DIR .. "parts/hand.scad")

-- geometry.scad: the sizes, for OpenSCAD (written from the geometry when it
-- has changed; make-stls.sh uses it too)
do
  local L = { "// made by galton.lua from galton-geometry.lua: do not edit (millimetres)" }
  local keys = {}
  for k, x in pairs(G) do if type(x) == "number" then keys[#keys + 1] = k end end
  table.sort(keys)
  for _, k in ipairs(keys) do L[#L + 1] = string.format("%s = %.6g;", k, G[k]) end
  local function pts(list)
    local s = {}
    for _, p in ipairs(list) do s[#s + 1] = string.format("[%.4f, %.4f]", p[1], p[2]) end
    return "[" .. table.concat(s, ", ") .. "]"
  end
  local function nums(list)
    local s = {}
    for _, x in ipairs(list) do s[#s + 1] = string.format("%.4f", x) end
    return "[" .. table.concat(s, ", ") .. "]"
  end
  local fill = {}
  for k = 1, G.NBINS do fill[k] = G.fill(G.expected(G.NBALLS, k)) end
  L[#L + 1] = "PINS = " .. pts(G.pins) .. ";"
  L[#L + 1] = "BUMPS = " .. pts(G.bumps) .. ";"
  L[#L + 1] = "DIVIDERS = " .. nums(G.dividers) .. ";"
  L[#L + 1] = "BINS = " .. nums(G.bins) .. ";"
  L[#L + 1] = "SLOT_ANGLES = " .. nums(G.slotAngles) .. ";"
  L[#L + 1] = "CUTS = " .. nums(G.CUTS) .. ";"
  L[#L + 1] = "EXPECTED = " .. nums(fill) .. ";      // the fill heights for NBALLS fair coins"
  L[#L + 1] = "MAIN = " .. pts(G.spaces.main) .. ";"
  L[#L + 1] = "HOPPER = " .. pts(G.spaces.hopper) .. ";"
  local text = table.concat(L, "\n") .. "\n"
  local path = DIR .. "parts/geometry.scad"
  local f = io.open(path, "r")
  local old = f and f:read("*a")
  if f then f:close() end
  if old ~= text and not GB_TRYING then
    f = io.open(path, "w")
    if f then f:write(text); f:close() end
  end
end

-- (bpp keeps each OpenSCAD part by the text asked for, not by what the
-- parts files say: a checksum of the files in the text makes a changed file
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
local SCAD_SUM = checksum({ SCAD, (SCAD:gsub("galton%.scad$", "geometry.scad")) })
local HAND_SUM = checksum({ HAND_SCAD })
-- (only to see: the contact shapes are the simulation's own, from the same sizes)
local function part(call, file, sum)
  local m = OpenSCAD("// " .. (sum or SCAD_SUM) .. "\ninclude <" .. (file or SCAD) .. ">\nscale(0.1) " .. call .. ";\n", 0, false)
  m.collides = false
  return m
end

-- ---------------------------------------------------------------------
-- sliders, timing, the pause at every start
-- ---------------------------------------------------------------------
v:addParam("crank", envnum("GB_CRANK", 0.5), 0.25, 0.75, 0.05, "the crank's speed, turns a second (twelve slots a turn; faster, two balls can meet over the neck and jam: FINDINGS)")
v:addParam("bounce", envnum("GB_BOUNCE", 0.4), 0, 0.9, 0.05, "restitution, ball on board")
v:addParam("friction", envnum("GB_FRICTION", 0.3), 0, 0.8, 0.05, "ball on board")
v:addParam("speed", 1, 0.05, 2, 0.05, "simulated seconds per real second")
local HZ = 2400
local STEP, NSTEPS, FRAME_DT = 1 / HZ, 40, 1 / 60
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
pcall(function() v:setSolverIterations(envnum("GB_ITER", 20)) end)

-- ---------------------------------------------------------------------
-- where things are: the board's frame (mm) in the world (cm). The board
-- stands in its stand on the table, its middle (through its thickness)
-- over the table's centre line; the sign stands to its right.
-- ---------------------------------------------------------------------
local MM = 0.1
local ident = btQuaternion(0, 0, 0, 1)
local function qa(ax, ay, az, deg) return btQuaternion(btVector3(ax, ay, az), math.rad(deg)) end
local BX = -9                                    -- the board's centre line, cm from the table's middle
local ZMID = (G.GAP + G.FRONT_T - G.BACK_T) / 2
local BASE = btVector3(BX, (G.FOOT_T - G.OUT_Y0) * MM, -ZMID * MM)
local function W3(x, y, z) return btVector3(BASE.x + x * MM, BASE.y + y * MM, BASE.z + (z or 0) * MM) end
local function boardXY(p) return (p.x - BASE.x) / MM, (p.y - BASE.y) / MM end

-- the table, by the hall's standard (exhibit-table.lua): the stand's foot
-- and the sign
local TABLE
do
  local path, f = DIR .. "../../exhibit-table.lua"
  if setfenv then f = assert(loadfile(path)); setfenv(f, getfenv(1))
  else f = assert(loadfile(path, "t", _ENV)) end
  TABLE = f()
end
local SIGN_W, SIGN_H = 200, 150                  -- mm
local SIGN_X = BX + G.FOOT_W / 2 * MM + 3        -- cm: its left edge
TABLE.build(SIGN_X + SIGN_W * MM - (BX - G.FOOT_W / 2 * MM), G.FOOT_D * MM,
            { x = ((BX - G.FOOT_W / 2 * MM) + SIGN_X + SIGN_W * MM) / 2, floor = 300 })

-- ---------------------------------------------------------------------
-- the board: the printed parts to see; its contact shapes from the
-- geometry, one fixed body
-- ---------------------------------------------------------------------
local boardTr = btTransform(ident, BASE)
local function still(call, col, file, sum)
  local m = part(call, file, sum)
  m.col = col
  v:add(m)
  m.trans = boardTr
  return m
end
local boardObj = still("board()", "#5b3a22")
local marksObj = still("marks(0.05)", "#e2c35a")
local pinsObj = still("pinsDrawn()", "#c8a24e")      -- (the board's pins, drawn in brass so they show)
local standObj = still("stand()", "#3b2a1a")
local frontObj = still("front()", "#eef6fa")
pcall(function() frontObj.transparency = 0.93 end)
local drawerObj = still("drawer()", "#6e4a2c")

local MARGIN = 0.004
local function tree(items)
  local level = items
  while #level > 1 do
    local up = {}
    for k = 1, #level, 12 do
      local c = btCompoundShape(true)
      for j = k, math.min(k + 11, #level) do c:addChildShape(level[j][2], level[j][1]) end
      up[#up + 1] = { c, btTransform(ident, btVector3(0, 0, 0)) }
    end
    level = up
  end
  return level[1][1]
end
local boardBody
do
  local items = {}
  local function add(shape, x, y, z, q)
    shape:setMargin(MARGIN)
    items[#items + 1] = { shape, btTransform(q or ident, btVector3(x * MM, y * MM, z * MM)) }
  end
  local zc = G.GAP / 2                          -- (the ball space's middle)
  local yc = (G.OUT_Y0 + G.OUT_Y1) / 2
  add(btBoxShape(btVector3(G.OUT_W / 2 * MM, G.OUT_H / 2 * MM, G.BACK_T / 2 * MM)), 0, yc, -G.BACK_T / 2)
  add(btBoxShape(btVector3(G.OUT_W / 2 * MM, G.OUT_H / 2 * MM, G.FRONT_T / 2 * MM)), 0, yc, G.GAP + G.FRONT_T / 2)
  local function cyl(x, y, d) add(btCylinderShapeZ(btVector3(d / 2 * MM, d / 2 * MM, G.GAP / 2 * MM)), x, y, zc) end
  for _, p in ipairs(G.pins) do cyl(p[1], p[2], G.PIN_D) end
  for _, p in ipairs(G.bumps) do cyl(p[1], p[2], G.PIN_D) end
  for _, w in ipairs(G.walls) do
    if not w.slide then
      local dx, dy = w[3] - w[1], w[4] - w[2]
      local L = math.sqrt(dx * dx + dy * dy)
      local ux, uy = dx / L, dy / L
      local nx, ny = uy, -ux                    -- (away from the balls: they are on the left)
      local T = w.t or 3
      local cx, cy = (w[1] + w[3]) / 2 + nx * T / 2, (w[2] + w[4]) / 2 + ny * T / 2
      add(btBoxShape(btVector3(L / 2 * MM, T / 2 * MM, G.GAP / 2 * MM)), cx, cy, zc, btQuaternion(btVector3(0, 0, 1), math.atan2(uy, ux)))
    end
  end
  for _, x in ipairs(G.dividers) do
    add(btBoxShape(btVector3(G.DIV_T / 2 * MM, (G.Y_DIV - G.Y_FLOOR) / 2 * MM, G.GAP / 2 * MM)), x, (G.Y_DIV + G.Y_FLOOR) / 2, zc)
    cyl(x, G.Y_DIV, G.DIV_T)
  end
  local c = Cube(1, 1, 1, 0)
  c.body = btRigidBody(0, btDefaultMotionState(boardTr), tree(items), btVector3(0, 0, 0))
  c.collides = true
  v:add(c)
  c.trans = boardTr
  pcall(function() c.transparency = 1 end)
  boardBody = c.body
end

-- the slide: a fixed box under the bins; pulled out, it touches nothing
local slideObj = part("slide()")
slideObj.col = "#8a6a3a"
v:add(slideObj)
local SLIDE_AT = btVector3(0, G.Y_FLOOR - G.SLIDE_T / 2, 0)
local slideBox = Cube(2 * G.W * MM, G.SLIDE_T * MM, G.GAP * MM, 0)
slideBox.collides = true
v:add(slideBox)
slideBox.trans = btTransform(ident, W3(0, SLIDE_AT.y, G.GAP / 2))
pcall(function() slideBox.transparency = 1 end)
local slideOut = 0                               -- mm the slide is pulled out (drawn)
local function placeSlide() slideObj.trans = btTransform(ident, W3(slideOut, SLIDE_AT.y, 0.2)) end
local slideIsOpen = false
local function setSlideOpen(open) slideIsOpen = open; slideBox.body:setCollisionFlags(open and 5 or 1) end
placeSlide()

-- ---------------------------------------------------------------------
-- the metering wheel: the printed wheel to see; its contact shape the hub
-- and the six pieces between the slots, from the same sizes
-- ---------------------------------------------------------------------
-- the two wheels (left: side -1, turning clockwise as you face it; right:
-- side 1, anticlockwise), each a body on a hinge. The gears behind the board
-- make them turn alike: here each is driven toward the same turn (counted
-- each in its own sense) as the crank's, which holds them together as the
-- gears would. The right wheel starts half a slot behind.
local wheels = {}
local HALF_SLOT = math.pi / G.SLOTS
local function makeWheel(side)
  local R, SD, SW = G.WHEEL_R, G.SLOT_D, G.SLOT_W
  local c = btCompoundShape(true)
  local hub = btCylinderShapeZ(btVector3((R - SD) * MM, (R - SD) * MM, G.WHEEL_T / 2 * MM))
  hub:setMargin(MARGIN)
  c:addChildShape(btTransform(ident, btVector3(0, 0, 0)), hub)
  local da = math.deg(math.asin(SW / 2 / R))
  local s = math.sqrt(R * R - (SW / 2) ^ 2)
  for k = 1, G.SLOTS do
    local a = math.rad(G.slotAngles[k])
    local b = math.rad(G.slotAngles[k % G.SLOTS + 1] + (k == G.SLOTS and 360 or 0))
    local ua, na = { math.cos(a), math.sin(a) }, { -math.sin(a), math.cos(a) }
    local ub, nb = { math.cos(b), math.sin(b) }, { -math.sin(b), math.cos(b) }
    local pts = { { 0, 0 },
      { (R - SD) * ua[1] + SW / 2 * na[1], (R - SD) * ua[2] + SW / 2 * na[2] },
      { s * ua[1] + SW / 2 * na[1], s * ua[2] + SW / 2 * na[2] } }
    local a0, a1 = math.deg(a) + da, math.deg(b) - da
    for i = 1, 5 do local t = math.rad(a0 + (a1 - a0) * i / 6); pts[#pts + 1] = { R * math.cos(t), R * math.sin(t) } end
    pts[#pts + 1] = { s * ub[1] - SW / 2 * nb[1], s * ub[2] - SW / 2 * nb[2] }
    pts[#pts + 1] = { (R - SD) * ub[1] - SW / 2 * nb[1], (R - SD) * ub[2] - SW / 2 * nb[2] }
    local h = btConvexHullShape()
    for _, p in ipairs(pts) do
      for _, z in ipairs({ -G.WHEEL_T / 2, G.WHEEL_T / 2 }) do h:addPoint(btVector3(p[1] * MM, p[2] * MM, z * MM), false) end
    end
    h:recalcLocalAabb()
    h:setMargin(MARGIN)
    c:addChildShape(btTransform(ident, btVector3(0, 0, 0)), h)
  end
  local wh = { side = side, turn = 0, last = nil }
  local m = part("wheel()")
  m.col = "#c08a3e"
  local Iz = G.WHEEL_MASS * (R * MM) ^ 2 / 2
  local at = W3(side * G.WHEEL_X, G.WHEEL_Y, G.GAP / 2)
  -- (the right wheel half a slot behind: turned clockwise, against its own way)
  local tr = btTransform(side > 0 and btQuaternion(btVector3(0, 0, 1), -HALF_SLOT) or ident, at)
  local b = btRigidBody(G.WHEEL_MASS, btDefaultMotionState(tr), c, btVector3(Iz / 2, Iz / 2, Iz))
  m.body = b
  m.collides = true                              -- (before it is added: a body's collisions are fixed then)
  v:add(m)
  m.trans = tr
  b:setCenterOfMassTransform(tr)
  b:setActivationState(4)
  b:setDamping(0, 0.05)
  wh.obj, wh.body = m, b
  local anchor = Cube(0.01, 0.01, 0.01, 0)     -- (only for the hinge to hold to: too small to see)
  anchor.collides = false
  v:add(anchor)
  anchor.trans = btTransform(ident, at)
  wh.hinge = btHingeConstraint(anchor.body, b, btTransform(ident, btVector3(0, 0, 0)), btTransform(ident, btVector3(0, 0, 0)))
  v:addConstraint(wh.hinge)
  -- the axle and the gear go round with it (to see); the crank on the left
  wh.axle = part(side < 0 and "axle(true)" or "axle(false)"); wh.axle.col = "#9a9da3"; v:add(wh.axle)
  wh.gear = part("gear()"); wh.gear.col = "#8a6a3a"; v:add(wh.gear)
  if side < 0 then wh.crank = part("crank()"); wh.crank.col = "#2e2a26"; v:add(wh.crank) end
  return wh
end
wheels[1], wheels[2] = makeWheel(-1), makeWheel(1)
pcall(function() v.showConstraints = false end)
local wheel = wheels[1]                         -- (the one with the crank)
local CRANK_Z = G.GAP + G.FRONT_T + 0.5           -- the crank's back, in front of the sheet
local GEAR_Z = -G.BACK_T - 1 - G.GEAR_T           -- the gears' back, behind the back plate
local function moveRiders()
  for _, wh in ipairs(wheels) do
    local tr = wh.body:getCenterOfMassTransform()
    local a = btTransform(); a:mult(tr, btTransform(ident, btVector3(0, 0, -G.GAP / 2 * MM)))
    wh.axle.trans = a
    local g = btTransform(); g:mult(tr, btTransform(ident, btVector3(0, 0, (GEAR_Z - G.GAP / 2) * MM)))
    wh.gear.trans = g
    if wh.crank then
      local c = btTransform(); c:mult(tr, btTransform(ident, btVector3(0, 0, (CRANK_Z - G.GAP / 2) * MM)))
      wh.crank.trans = c
    end
  end
end
-- each wheel's turn in its own sense (the left's clockwise, the right's
-- anticlockwise), unwrapped
local function turnOf(wh)
  local c = wh.body:getCenterOfMassTransform():getBasis():getColumn(0)
  local a = math.atan2(c.y, c.x)
  if wh.last then
    local d = a - wh.last
    if d > math.pi then d = d - 2 * math.pi elseif d < -math.pi then d = d + 2 * math.pi end
    wh.turn = wh.turn + (wh.side < 0 and -d or d)
  end
  wh.last = a
  return wh.turn
end
local function wheelAngle() return turnOf(wheels[1]) end
local function spinOf(wh) return wh.body:getAngularVelocity().z * (wh.side < 0 and -1 or 1) end
for _, wh in ipairs(wheels) do turnOf(wh) end

-- ---------------------------------------------------------------------
-- the balls
-- ---------------------------------------------------------------------
local NBALLS = math.floor(envnum("GB_BALLS", G.NBALLS))
local R = G.BALL_D / 2
local function distSeg(px, py, w)
  local dx, dy = w[3] - w[1], w[4] - w[2]
  local t = math.max(0, math.min(1, ((px - w[1]) * dx + (py - w[2]) * dy) / (dx * dx + dy * dy)))
  return math.sqrt((px - w[1] - t * dx) ^ 2 + (py - w[2] - t * dy) ^ 2)
end
local function inPoly(px, py, poly)
  local inside, j = false, #poly
  for i = 1, #poly do
    local a, b = poly[i], poly[j]
    if ((a[2] > py) ~= (b[2] > py)) and (px < (b[1] - a[1]) * (py - a[2]) / (b[2] - a[2]) + a[1]) then inside = not inside end
    j = i
  end
  return inside
end
-- the places in the hopper the balls start from, lowest first
local SPOTS = {}
do
  local y, row = G.WHEEL_Y + G.HOUSING + R + 0.5, 0
  while #SPOTS < NBALLS and y < G.Y_TOP - R do
    local off = (row % 2) * 3.2
    for x = -G.W + off, G.W, 6.4 do
      local ok = #SPOTS < NBALLS and inPoly(x, y, G.spaces.hopper)
      if ok then for _, w in ipairs(G.walls) do if distSeg(x, y, w) < R + 0.4 then ok = false; break end end end
      if ok then SPOTS[#SPOTS + 1] = { x, y } end
    end
    y, row = y + 5.6, row + 1
  end
  assert(#SPOTS == NBALLS, "The Galton board: the hopper holds only " .. #SPOTS .. " balls")
end
local balls = {}
local function place(b, x, y)
  local tr = btTransform(ident, W3(x, y, G.GAP / 2))
  b.body:setCenterOfMassTransform(tr)
  b.body:setLinearVelocity(btVector3(0, 0, 0))
  b.body:setAngularVelocity(btVector3(0, 0, 0))
  b.body:clearForces()
  b.obj.trans = tr
end
for i = 1, NBALLS do
  local s = Sphere(R * MM, G.BALL_MASS)
  s.col = "#b9bec6"
  v:add(s)
  s.body:setActivationState(4)
  balls[i] = { obj = s, body = s.body }
  place(balls[i], SPOTS[i][1], SPOTS[i][2])
end
local function applyContacts()
  local e, f = v:getParam("bounce"), v:getParam("friction")
  -- (Bullet multiplies the two bodies' values: the board's are 1, so the
  -- balls' are ball on board; ball on ball is their square)
  for _, b in ipairs(balls) do b.body:setRestitution(e); b.body:setFriction(f) end
  for _, b in ipairs({ boardBody, slideBox.body, wheels[1].body, wheels[2].body }) do b:setRestitution(1); b:setFriction(1) end
end
applyContacts()

-- where the balls are: in the hopper (above the wheel's housing), in the
-- bins, in the drawer, or on their way
local chuteLog = { n = 0, x = 0, vx = 0, left = 0, prevY = {} }
local function census()
  local c = { hopper = 0, bins = 0, drawer = 0, between = 0, counts = {}, maxv = 0 }
  for k = 1, G.NBINS do c.counts[k] = 0 end
  for _, b in ipairs(balls) do
    local x, y = boardXY(b.body:getCenterOfMassPosition())
    c.maxv = math.max(c.maxv, b.body:getLinearVelocity():length())
    if LOG == "3" then
      local py = chuteLog.prevY[b]
      if py and py >= G.CHUTE_Y and y < G.CHUTE_Y and math.abs(x) < G.CHUTE then
        local vx = b.body:getLinearVelocity().x
        chuteLog.n = chuteLog.n + 1; chuteLog.x = chuteLog.x + x; chuteLog.vx = chuteLog.vx + vx
      end
      if py and py >= -3 and y < -3 and math.abs(x) < 7 then chuteLog.left = chuteLog.left + (x < 0 and 1 or 0); chuteLog.m = (chuteLog.m or 0) + 1 end
      chuteLog.prevY[b] = y
    end
    if y > G.WHEEL_Y + G.HOUSING * 0.5 and math.abs(x) <= G.W then c.hopper = c.hopper + 1
    elseif y < G.Y_FLOOR - G.SLIDE_T then c.drawer = c.drawer + 1
    elseif y < G.Y_DIV and y > G.Y_FLOOR - 1 then c.bins = c.bins + 1; local k = G.binOf(x); c.counts[k] = c.counts[k] + 1
    else c.between = c.between + 1 end
  end
  local n, s1, s2 = 0, 0, 0
  for k = 1, G.NBINS do n = n + c.counts[k]; s1 = s1 + c.counts[k] * (k - 1); s2 = s2 + c.counts[k] * (k - 1) ^ 2 end
  c.mean = n > 0 and s1 / n or nil
  c.sd = n > 1 and math.sqrt(math.max(0, s2 / n - (s1 / n) ^ 2)) or nil
  return c
end
-- GB_PATHS=<file>: each ball's path through the pins, for testing whether
-- its choices are independent. At the level halfway below each row, the gap
-- it passes, in half-pitches from the middle (u = 2 x / S), at its first
-- downward crossing; written out at the end of each run, a line a ball
local PATHS = os.getenv("GB_PATHS")
local paths = {}
local levels = {}
for r = G.TOP, G.ROWS - 1 do levels[#levels + 1] = -(r - G.TOP) * G.V - G.V / 2 end
local function trackPaths()
  for i, b in ipairs(balls) do
    local p = b.body:getCenterOfMassPosition()
    local x, y = (p.x - BASE.x) / MM, (p.y - BASE.y) / MM
    local rec = paths[i]
    if not rec then rec = { n = 0, u = {} }; paths[i] = rec end
    if rec.py and rec.n < #levels then
      local L = levels[rec.n + 1]
      if rec.py >= L and y < L then
        local t = (rec.py - L) / (rec.py - y)
        rec.n = rec.n + 1
        rec.u[rec.n] = 2 * (rec.px + (x - rec.px) * t) / G.S
      end
    end
    if y > G.CHUTE_Y + G.NECK_L + 5 then rec.n = 0; rec.u = {} end      -- (back above the pins: a new path)
    rec.px, rec.py = x, y
  end
end
local function writePaths()
  local f = io.open(PATHS, "a")
  if not f then return end
  for i = 1, #balls do
    local rec = paths[i]
    if rec and rec.n == #levels then
      local t = {}
      for k = 1, rec.n do t[k] = string.format("%.2f", rec.u[k]) end
      f:write(table.concat(t, " "), "\n")
    end
  end
  f:close()
end
local FAIR_MEAN, FAIR_SD = G.DECISIONS / 2, math.sqrt(G.DECISIONS) / 2

-- ---------------------------------------------------------------------
-- the sign beside it (the exhibit's): the run, the balls in the bins, their
-- mean bin and their spread, on drums like a counter's
-- ---------------------------------------------------------------------
local SIGN
do
  local W, H = SIGN_W, SIGN_H
  local DW, PITCH = 9, 10
  local ROW = { 125, 88, 51, 14 }
  local wins, labels, drums = {}, {}, {}
  local function label(t, x, row, size) labels[#labels + 1] = string.format('["%s", %.1f, %.1f, %.1f]', t, x, ROW[row], size or 7) end
  local function digits(name, x, row, n, gaps)
    local d = {}
    local cx = x
    for k = 1, n do
      wins[#wins + 1] = string.format("[%.1f, %.1f, %.1f]", cx, ROW[row], DW)
      d[k] = { x = cx, y = ROW[row], w = DW }
      cx = cx + PITCH + ((gaps and gaps[k]) or 0)
    end
    drums[name] = d
  end
  label("RUN", 8, 1); digits("run", 70, 1, 2)
  label("IN THE BINS", 8, 2, 6); digits("balls", 100, 2, 3); label("OF " .. NBALLS, 136, 2, 6)
  label("MEAN BIN", 8, 3, 6); digits("mean", 100, 3, 3, { 6 }); label(".", 109.5, 3, 7)
  label(string.format("FAIR: %.2f", FAIR_MEAN), 140, 3, 5)
  label("SPREAD", 8, 4, 6); digits("sd", 100, 4, 3, { 6 }); label(".", 109.5, 4, 7)
  label(string.format("FAIR: %.2f", FAIR_SD), 140, 4, 5)
  local tr = btTransform(qa(0, 1, 0, -12), btVector3(SIGN_X, 1.5, -2))
  local box = part(string.format("signBox(%.1f, %.1f, [%s])", W, H, table.concat(wins, ",")))
  box.col = "#3a2818"
  v:add(box)
  box.trans = tr
  local lab = part(string.format("signLabels([%s])", table.concat(labels, ",")))
  lab.col = "#e8d7a8"
  v:add(lab)
  lab.trans = tr
  for _, list in pairs(drums) do
    for _, d in ipairs(list) do
      d.body = part(string.format("drumBody(%.1f)", d.w)); d.body.col = "#efe6cf"; v:add(d.body)
      d.face = part("drumDigits()"); d.face.col = "#1e1812"; v:add(d.face)
      d.cur, d.want = 10, 10                     -- (the blank face)
    end
  end
  SIGN = { tr = tr, drums = drums, box = box, labels = lab, zc = -(3.5 + 17) * MM }
end
local DRUM_A = 360 / 11
local function placeDrum(d)
  local t = btTransform()
  t:mult(SIGN.tr, btTransform(qa(1, 0, 0, -d.cur * DRUM_A), btVector3(d.x * MM, d.y * MM, SIGN.zc)))
  d.body.trans = t
  d.face.trans = t
end
local function turnDrums()
  for _, list in pairs(SIGN.drums) do
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
-- a whole number on a run of drums, right-aligned (nil: blank); digits
-- shows leading zeros
local function showNumber(name, value, zeros)
  local list = SIGN.drums[name]
  local s = value and string.format(zeros and ("%0" .. #list .. "d") or "%d", math.floor(value + 0.5)) or ""
  if #s > #list then s = string.rep("9", #list) end
  for k = 1, #list do
    local j = #s - (#list - k)
    list[k].want = (j >= 1) and tonumber(s:sub(j, j)) or 10
  end
end
for _, list in pairs(SIGN.drums) do for _, d in ipairs(list) do placeDrum(d) end end
local runNo = 0
local function showStats(c)
  showNumber("run", runNo > 0 and runNo or nil)
  showNumber("balls", c.bins)
  showNumber("mean", c.mean and c.mean * 100, true)
  showNumber("sd", c.sd and c.sd * 100, true)
end

-- ---------------------------------------------------------------------
-- the operator's hand (drawn: it touches nothing). It goes to the crank and
-- turns it, to the slide and pulls it, to the drawer and carries it up to
-- the filling slot. A pointing hand, the finger's tip at the thing it
-- works, the palm to the right of it.
-- ---------------------------------------------------------------------
local HAND_ON = os.getenv("GB_HAND") ~= "0"
local hand = { pos = nil, target = nil, SPEED = 40 }
-- (its finger into the board, its palm to the left of the finger, away from
-- the wheels and the pins (the crank is on the left wheel): its x, y, z to
-- the world's -y, z, -x)
local HAND_Q = btQuaternion(btVector3(1, -1, -1), 2 * math.pi / 3)
if HAND_ON then
  hand.obj = part("hand()", HAND_SCAD, HAND_SUM)
  hand.obj.col = "#e0b896"
  v:add(hand.obj)
  pcall(function() hand.obj.transparency = 0.45 end)     -- (half see-through: it hides little)
end
-- places, in the board's frame (mm)
local function crankTip()
  -- (the crank's handle along the wheel's own +x)
  local c = wheel.body:getCenterOfMassTransform():getBasis():getColumn(0)
  return { -G.WHEEL_X + c.x * G.CRANK_R, G.WHEEL_Y + c.y * G.CRANK_R, CRANK_Z + 22 }
end
local HAND_HOME = { -G.W - 60, G.WHEEL_Y - 40, 60 }
local function slideTip() return { G.W + G.RIM + 8 + slideOut, G.Y_FLOOR - G.SLIDE_T / 2, G.GAP + 6 } end
local function drawerTip() return { G.W + G.RIM + 7, (G.Y_DRAWER + G.Y_FLOOR) / 2, G.GAP + 6 } end
local FILL_AT = { 0, G.OUT_Y1 + 30, ZMID }
function hand.go(p) hand.target = p end
function hand.arrived() return hand.pos and hand.target and
  math.abs(hand.pos[1] - hand.target[1]) + math.abs(hand.pos[2] - hand.target[2]) + math.abs(hand.pos[3] - hand.target[3]) < 1 end
function hand.update(dt)
  if not hand.pos then hand.pos = { HAND_HOME[1], HAND_HOME[2], HAND_HOME[3] } end
  local t = hand.target or HAND_HOME
  local d = { t[1] - hand.pos[1], t[2] - hand.pos[2], t[3] - hand.pos[3] }
  local L = math.sqrt(d[1] ^ 2 + d[2] ^ 2 + d[3] ^ 2)
  local step = hand.SPEED / MM * dt                   -- (mm this frame)
  if L <= step or L < 0.01 then hand.pos = { t[1], t[2], t[3] }
  else for i = 1, 3 do hand.pos[i] = hand.pos[i] + d[i] * step / L end end
  -- (resting at home with nothing to do: out of sight, under the floor)
  local away = not hand.target or hand.target == HAND_HOME
  if hand.obj then
    if away and L <= step then hand.obj.trans = btTransform(HAND_Q, btVector3(BX, -400, 0))
    else hand.obj.trans = btTransform(HAND_Q, W3(hand.pos[1], hand.pos[2], hand.pos[3])) end
  end
end
-- the drawer, carried up and tipped over the filling slot (drawn)
local drawerUp = 0                                    -- 0 in its bay, 1 tipped over the slot
local function placeDrawer()
  if drawerUp <= 0 then drawerObj.trans = boardTr; return end
  -- (from its bay to over the slot, tipped by up to 100 degrees round z)
  local y0 = (G.Y_DRAWER + G.Y_FLOOR) / 2
  local y = y0 + (G.OUT_Y1 + 50 - y0) * math.min(1, drawerUp * 1.25)
  local tip = math.max(0, drawerUp - 0.8) / 0.2 * 100
  local t = btTransform()
  t:mult(btTransform(qa(0, 0, 1, tip), W3(0, y, 0)), btTransform(ident, btVector3(0, -y0 * MM, 0)))
  drawerObj.trans = t
end

-- ---------------------------------------------------------------------
-- what the operator is doing: nothing, running the balls through
-- (cranking), or emptying the bins and pouring them back. Each step waits
-- for the hand to get there.
-- ---------------------------------------------------------------------
local mode = "idle"
local modeT, quietT = 0, 0
local cranking, backing = false, 0
local stallT, backs, knocks = 0, 0, 0
local tour = (os.getenv("GB_TOUR") or "1") ~= "0" and 1 or nil
local tourFails, tourRuns = 0, {}
local t = 0
local lastCensus = census()
local function say(s) print(s) end
local QUIET_V = 8

local function startRun()
  mode, modeT, quietT = "run", 0, 0
  runNo = runNo + 1
  backs = 0
  hand.go(crankTip())
  say(string.format("RUN %d: turning the crank, %.2f turns a second", runNo, v:getParam("crank")))
end
local function stopRun() cranking = false; mode = "idle"; hand.go(HAND_HOME) end
local function startEmpty()
  mode, modeT, quietT = "empty", 0, 0
  cranking = false
  hand.go(slideTip())
  say("EMPTY: the slide out, the balls down into the drawer; then poured back into the hopper")
end
local pourNext = 1
local function endOfRun(c)
  local ok = c.bins == NBALLS and c.mean and math.abs(c.mean - FAIR_MEAN) < 0.6 and c.sd > 1.4 and c.sd < 2.6
  say(string.format("  bins: %s", table.concat(c.counts, " ")))
  local fair = {}
  for k = 1, G.NBINS do fair[k] = string.format("%.0f", G.expected(c.bins, k)) end
  say(string.format("  fair: %s", table.concat(fair, " ")))
  say(string.format("  %d of %d balls in the bins; mean bin %.2f (fair: %.2f), spread %.2f (fair: %.2f); %d backs of the crank; %.1f s",
                    c.bins, NBALLS, c.mean or 0, FAIR_MEAN, c.sd or 0, FAIR_SD, backs, modeT))
  say(ok and "    as expected" or "    NOT AS EXPECTED")
  if PATHS then writePaths() end
  if chuteLog.n > 0 then
    say(string.format("  leaving the chute: %d balls, mean x %.2f mm, mean vx %.2f cm/s; past the middle pin: %d of %d to the left",
                      chuteLog.n, chuteLog.x / chuteLog.n, chuteLog.vx / chuteLog.n, chuteLog.left, chuteLog.m or 0))
    chuteLog.n, chuteLog.x, chuteLog.vx, chuteLog.left, chuteLog.m = 0, 0, 0, 0, 0
  end
  return ok
end

-- (every frame, after the steps)
local function operate(dt)
  local c = census()
  lastCensus = c
  modeT = modeT + dt
  -- (still: under 8 cm/s; balls low in a tall stack in a bin jitter at 5 or 6,
  -- the solver's, not a movement: FINDINGS)
  if c.maxv < QUIET_V then quietT = quietT + dt else quietT = 0 end
  if mode == "run" then
    if not cranking then
      hand.go(crankTip())
      if hand.arrived() then cranking = true end
    else
      hand.go(crankTip()); hand.pos = crankTip()       -- (the hand turns with it)
      -- jammed? (the wheel held still against the hand): back it half a slot
      local w = math.min(spinOf(wheels[1]), spinOf(wheels[2]))
      if backing <= 0 and w < 0.2 * v:getParam("crank") * 2 * math.pi then stallT = stallT + dt else stallT = 0 end
      if stallT > 0.3 then backing, stallT, backs = 0.15, 0, backs + 1 end
    end
    -- done: the hopper empty, nothing on its way, everything still
    if c.hopper == 0 and c.between == 0 and quietT > 0.5 then
      cranking = false
      hand.go(HAND_HOME)
      local ok = endOfRun(c)
      mode = "idle"
      if tour then
        tourRuns[#tourRuns + 1] = ok
        if not ok then tourFails = tourFails + 1 end
      end
    elseif modeT > 150 then
      say("  the run has stopped: " .. c.hopper .. " balls still in the hopper, " .. c.between .. " on their way")
      cranking = false; hand.go(HAND_HOME); mode = "idle"
      if tour then tourRuns[#tourRuns + 1] = false; tourFails = tourFails + 1 end
    end
  elseif mode == "empty" then
    hand.go(slideTip())
    if hand.arrived() and slideOut == 0 and c.drawer < NBALLS then setSlideOpen(true) end
    if slideIsOpen then
      if c.drawer < NBALLS and slideOut < 2 * G.W + 10 then slideOut = math.min(2 * G.W + 10, slideOut + 400 * dt) end
      -- balls left wedged in a bin (a zigzag stack can brace itself against
      -- the walls when its floor goes): the operator knocks the board. The
      -- knock is idealised: the balls in the bins get the jolt it would give
      -- them, a few cm/s up
      if c.bins > 0 and quietT > 1 and slideOut >= 2 * G.W + 10 then
        knocks = knocks + 1
        quietT = 0
        for _, b in ipairs(balls) do
          local _, y = boardXY(b.body:getCenterOfMassPosition())
          if y > G.Y_FLOOR - 1 and y < G.Y_DIV then
            local lv = b.body:getLinearVelocity()
            b.body:setLinearVelocity(btVector3(lv.x, lv.y + 15, lv.z))
          end
        end
        if knocks == 1 or LOG then
          say(string.format("  %d balls wedged in the bins: the operator knocks the board", c.bins))
          if LOG then
            for _, b in ipairs(balls) do
              local x, y = boardXY(b.body:getCenterOfMassPosition())
              if y > G.Y_FLOOR - 1 and y < G.Y_DIV then say(string.format("    wedged at x %.2f y %.2f (the slide's top %.2f)", x, y, G.Y_FLOOR)) end
            end
          end
        end
      end
      if c.drawer == NBALLS and quietT > 0.3 then
        setSlideOpen(false)
        mode = "closing"
      end
    end
  elseif mode == "closing" then
    hand.go(slideTip())
    slideOut = math.max(0, slideOut - 400 * dt)
    if slideOut == 0 then mode, pourNext = "carry", 1; hand.go(drawerTip()) end
  elseif mode == "carry" then
    hand.go(drawerTip())
    if drawerUp > 0 or hand.arrived() then
      drawerUp = math.min(1, drawerUp + dt / 1.5)
      local y0 = (G.Y_DRAWER + G.Y_FLOOR) / 2
      local y = y0 + (G.OUT_Y1 + 50 - y0) * math.min(1, drawerUp * 1.25)
      hand.go({ G.W + G.RIM + 7, y, G.GAP + 6 }); hand.pos = { G.W + G.RIM + 7, y, G.GAP + 6 }
      if drawerUp >= 1 then mode = "pour" end
    end
  elseif mode == "pour" then
    -- the drawer tipped over the filling slot: its balls into the hopper's
    -- top, a row at a time, where there's room
    local top = G.Y_TOP - R - 0.5
    local placed = 0
    for x = -G.W + R + 1, G.W - R - 1, 6.6 do
      if pourNext <= NBALLS and placed < 24 then
        local free = true
        for _, b in ipairs(balls) do
          local bx, by = boardXY(b.body:getCenterOfMassPosition())
          if (bx - x) ^ 2 + (by - top) ^ 2 < (G.BALL_D + 0.4) ^ 2 then free = false; break end
        end
        if free then
          -- (the next ball still in the drawer)
          while pourNext <= NBALLS do
            local _, by = boardXY(balls[pourNext].body:getCenterOfMassPosition())
            if by < G.Y_FLOOR - G.SLIDE_T then break end
            pourNext = pourNext + 1
          end
          if pourNext <= NBALLS then
            place(balls[pourNext], x + ((pourNext * 7919) % 100) / 100 - 0.5, top)
            balls[pourNext].body:setLinearVelocity(btVector3(0, -20, 0))
            pourNext = pourNext + 1
            placed = placed + 1
          end
        end
      end
    end
    if pourNext > NBALLS and c.drawer == 0 then mode = "return" end
  elseif mode == "return" then
    drawerUp = math.max(0, drawerUp - dt / 1.2)
    local y0 = (G.Y_DRAWER + G.Y_FLOOR) / 2
    local y = y0 + (G.OUT_Y1 + 50 - y0) * math.min(1, drawerUp * 1.25)
    hand.go({ G.W + G.RIM + 7, y, G.GAP + 6 }); hand.pos = { G.W + G.RIM + 7, y, G.GAP + 6 }
    if drawerUp <= 0 and quietT > 0.3 then
      mode = "idle"
      hand.go(HAND_HOME)
      say(string.format("  poured back: %d balls in the hopper", c.hopper))
    end
  end
  placeSlide()
  placeDrawer()
  hand.update(dt)
  showStats(c)
  turnDrums()
end

-- the tour: a run, empty and pour back, a run (GB_RUNS: more runs)
local RUNS = math.max(1, math.floor(envnum("GB_RUNS", 2)))
local function tourPlan(full)
  local p = full and {} or { "empty" }
  for k = 1, RUNS do p[#p + 1] = "run"; if k < RUNS then p[#p + 1] = "empty" end end
  return p
end
local TOUR = tourPlan(true)
local function tourStep()
  local s = TOUR[tour]
  if s == "run" then startRun() else startEmpty() end
end
local function tourNext()
  if not tour or mode ~= "idle" or (hand.target and not hand.arrived()) then return end
  tour = tour + 1
  if tour > #TOUR then
    tour = nil
    say("RESULT galton tour: " .. ((tourFails == 0 and #tourRuns == RUNS) and "PASS" or "FAIL"))
  else tourStep() end
end

-- ---------------------------------------------------------------------
-- at rest: once the operator has nothing to do and nothing has moved for
-- REST_S, the simulation stops stepping (nothing would change but the
-- processor's work); the next thing to do starts it again
-- ---------------------------------------------------------------------
local REST_S = 0.5
local REST_ON = os.getenv("GB_REST") ~= "0"
local restFor, resting = 0, false
local function busy() return mode ~= "idle" or tour ~= nil or (hand.target and not hand.arrived()) end
local function restPre()
  if not resting then return false end
  if busy() then resting, restFor = false, 0; applyTiming(); return false end
  v.timeStep = 0
  return true
end
local function restPost(dt)
  if resting then return end
  if busy() then restFor = 0; return end
  local mv = lastCensus.maxv
  local mw = math.max(math.abs(spinOf(wheels[1])), math.abs(spinOf(wheels[2])))
  if mv < QUIET_V and mw < 0.05 then restFor = restFor + dt else restFor = 0 end
  if REST_ON and restFor >= REST_S then resting = true; v.timeStep = 0 end
end

-- ---------------------------------------------------------------------
-- stepping
-- ---------------------------------------------------------------------
-- the crank's turn: where the gears hold both wheels
local crankTurn = 0
local LOCK = 40                                   -- (1/s: how hard the gears hold a wheel to the crank's turn)
local function crankMotor()
  local omega = cranking and v:getParam("crank") * 2 * math.pi or 0
  if backing > 0 then omega = -omega end
  crankTurn = crankTurn + omega * STEP
  for _, wh in ipairs(wheels) do
    local w = omega + LOCK * (crankTurn - turnOf(wh))
    -- (a hinge's motor speed counts as its angle, clockwise about +z: a
    -- positive speed turns a wheel clockwise as you face it)
    wh.hinge:enableAngularMotor(true, wh.side < 0 and w or -w, (cranking and 5 or 0.5) * STEP * 60)
  end
end
local started = false
v:preSim(function(N)
  if holdPre() then return end
  if restPre() then return end
  if backing > 0 then backing = backing - FRAME_DT end
  for k = 1, NSTEPS do
    crankMotor()
    v:stepSimulation(STEP, 0, STEP)
    if PATHS then trackPaths() end
  end
end)
v:postSim(function(N)
  moveRiders()
  wheelAngle()
  if holdNow then hand.update(0); return end
  if resting then return end
  t = t + FRAME_DT
  if not started then
    started = true
    if tour then print("\nTHE GALTON BOARD -- the tour"); tourStep() end
  end
  operate(FRAME_DT)
  tourNext()
  restPost(FRAME_DT)
  if LOG and math.floor(t * 60 + 0.5) % 300 == 0 then
    local c = lastCensus
    print(string.format("  t %.0f  %s  hopper %d  on the way %d  bins %d  drawer %d  crank %.1f turns  fastest %.2f cm/s  mean %s  spread %s",
                        t, mode, c.hopper, c.between, c.bins, c.drawer, wheels[1].turn / (2 * math.pi), c.maxv,
                        c.mean and string.format("%.2f", c.mean) or "-", c.sd and string.format("%.2f", c.sd) or "-"))
    if LOG == "2" and c.hopper == 0 then
      for i, b in ipairs(balls) do
        local x, y = boardXY(b.body:getCenterOfMassPosition())
        if y >= G.Y_DIV and y <= G.WHEEL_Y + G.HOUSING * 0.5 then print(string.format("    on its way: ball %d at %.2f %.2f, %.2f cm/s", i, x, y, b.body:getLinearVelocity():length())) end
      end
    end
    if LOG == "2" then
      local fb, fv = nil, -1
      for i, b in ipairs(balls) do local s = b.body:getLinearVelocity():length(); if s > fv then fb, fv = i, s end end
      local p = balls[fb].body:getCenterOfMassPosition()
      local x, y = boardXY(p)
      local lv = balls[fb].body:getLinearVelocity()
      print(string.format("    fastest: ball %d at x %.2f y %.2f z %.2f mm, v %.2f %.2f %.2f", fb, x, y, (p.z - BASE.z) / MM, lv.x, lv.y, lv.z))
    end
  end
end)

-- ---------------------------------------------------------------------
-- keys, sliders, help
-- ---------------------------------------------------------------------
v:addShortcut("Space", function()
  tour = nil
  if mode == "run" then stopRun() elseif mode == "idle" then
    if lastCensus.hopper == 0 then say("the hopper is empty: E empties the bins and pours them back") else startRun() end
  end
end)
v:addShortcut("E", function() tour = nil; if mode == "idle" then startEmpty() end end)
v:addShortcut("T", function()
  if mode ~= "idle" then return end
  tour, tourFails, tourRuns = 1, 0, {}
  print("\nthe tour")
  TOUR = tourPlan(lastCensus.hopper == NBALLS)
  tourStep()
end)
v:onParamChanged(function(N, name, value)
  if name == "speed" then applyTiming()
  elseif name == "bounce" or name == "friction" then applyContacts() end
end)
pcall(function()
  v:setHelpText(table.concat({
    "THE GALTON BOARD  (Babbage's Hall)",
    "",
    "KEYS",
    "  Space  turn the crank: run the balls through (again: stop)",
    "  E      empty the bins into the drawer, pour it back into the hopper",
    "  T      the tour: a run, empty and pour back, a second run",
    "",
    "Each ball meets twelve pins on its way down, and at each goes left or",
    "right. Its bin counts how many times it went right. If every pin were a",
    "fair coin, 150 balls would fill the bins to the gold lines: the binomial",
    "distribution, which for many rows is the normal curve.",
    "",
    "WHAT TO WATCH",
    "  The metering wheel under the hopper lets one ball in at a time.",
    "  The bins fill in a bell; the sign beside it keeps the count, the mean",
    "  bin (6 for fair coins) and the spread, the standard deviation (1.73).",
    "  Real balls bounce: the spread comes out a little wider than fair coins'.",
  }, "\n"))
end)
if v.onHover then
  local KEY = {}
  KEY[objectKey(boardObj)] = "the Galton board: twelve rows of pins over thirteen bins"
  KEY[objectKey(marksObj)] = "where 150 balls would come to if every pin were a fair coin"
  KEY[objectKey(pinsObj)] = "the pins: 4 mm, 12 mm apart, printed with the board"
  for _, wh in ipairs(wheels) do
    KEY[objectKey(wh.obj)] = "a metering wheel: each slot carries one ball from the hopper to the funnel over the first pin; the two are mirror images, geared together"
    KEY[objectKey(wh.gear)] = "the gears behind the board: they turn the wheels alike, opposite ways"
  end
  KEY[objectKey(wheels[1].crank)] = "the crank (turned by the operator's hand)"
  KEY[objectKey(slideObj)] = "the slide under the bins: pulled out, the balls drop into the drawer"
  KEY[objectKey(drawerObj)] = "the drawer: tipped into the filling slot at the top, it refills the hopper"
  KEY[objectKey(SIGN.box)] = "the sign (the exhibit's): the run, the balls in the bins, their mean and spread"
  KEY[objectKey(SIGN.labels)] = KEY[objectKey(SIGN.box)]
  for _, b in ipairs(balls) do KEY[objectKey(b.obj)] = "a steel ball, 6 mm" end
  v:onHover(function(N, obj, x, y, z)
    local s = KEY[objectKey(obj)]
    if not s then return nil end
    local c = lastCensus
    local fair = {}
    for k = 1, G.NBINS do fair[k] = string.format("%.0f", G.expected(math.max(c.bins, 1), k)) end
    return s .. string.format("\nthe bins: %s\nfair coins: %s\nmean bin %s (fair %.2f), spread %s (fair %.2f)",
      table.concat(c.counts, " "), table.concat(fair, " "),
      c.mean and string.format("%.2f", c.mean) or "-", FAIR_MEAN, c.sd and string.format("%.2f", c.sd) or "-", FAIR_SD)
  end)
end

common.setCamera(btVector3(BX + 9, 40, 98), btVector3(BX + 9, 28, 0))
moveRiders()
hand.update(0)
holdStart()
