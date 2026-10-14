--
-- The Falling Slinky -- Euler's Cabinet of Curiosities
--
-- A Slinky hangs from a hand, stretched out by its own weight; beside its
-- bottom, a steel ball hangs from a thread. The hand lets go of both at the
-- same moment. The ball falls at once. The Slinky's bottom doesn't: it hangs
-- there in mid-air, quite still, while the top comes down -- coil after coil
-- closing up -- and only when the collapsing coils reach it does the bottom
-- move, and the whole Slinky falls together.
--
-- Why: what holds the bottom up is the stretch of the coils just above it,
-- and that stretch can't change until news of the release gets there. The
-- news travels down the spring as the collapse itself. Until it arrives,
-- the bottom feels exactly what it felt before: gravity, and the same pull
-- up. (Its centre of mass falls just as the ball does, all the while: the
-- top falls the faster, to make up.)
--
-- Theory (a spring with no pre-tension): after the hand lets go, nothing
-- acts on the Slinky but gravity, so its momentum is M g t; all of it is in
-- the collapsed coils at the top, the rest being still. Following the
-- collapse down the hanging spring with that, the bottom stays put for
--   sqrt( M / 3k )
-- M its mass, k its stiffness. There's no g in it -- on the Moon it would
-- hang for just as long -- and the closed-up length drops out too. The
-- console gives what it does and what it should, each drop: 86 coils make
-- it about 1% longer than the smooth spring of the theory (the more coils,
-- the closer).
--
-- THE SLINKY: the original metal one -- 215 g, 86 coils 7 cm across, 5.6 cm
-- tall closed up -- with no pre-tension, stiffness 1.76 N/m: hung up, it
-- stretches 60 cm, and the bottom should stay put for 0.202 s.
--
-- PHYSICS
--  * Each coil is a rigid body (2.5 g), joined to the next by a slide along
--    the Slinky's axis: the slide stops the coils at their closed-up
--    spacing (coils hitting coils, with no bounce), and keeps them square
--    to each other. Between neighbours, a spring force (k times 85: 85
--    springs in a row make k) whenever they're apart, applied before every
--    step.
--  * It starts exactly as it hangs (each coil's stretch set from the weight
--    below it), held for two seconds (on screen), then let go.
--  * 4800 physics steps a second; it runs at a tenth of real speed (Z: real
--    speed).
--
-- Keys
--   R   hang it up again (and let go)
--   Z   a tenth of real speed <-> real speed
--
-- Units: centimetres, kilograms, seconds.
-- Headless testing: SL_COILS, SL_K (N/m), SL_MASS (g), SL_SPEED, SL_LOG=file.csv.
--

local common = require "common"

local G = 981
local function envnum(n, d) return tonumber(os.getenv(n) or "") or d end
local function param(...) v:addParam(...) end
param("speed", envnum("SL_SPEED", 0.1), 0.02, 1, 0.02, "simulated seconds per real second (Z: 1/10 <-> 1)")
param("steps", 4800, 2400, 9600, 600, "physics steps per simulated second")
param("stiffness", envnum("SL_K", 1.76), 1.2, 5, 0.02, "the Slinky's stiffness, N/m (hangs it up again)")
param("mass", envnum("SL_MASS", 215), 100, 300, 5, "the Slinky's mass, g (hangs it up again)")
param("hold", 2.0, 0.5, 6, 0.5, "seconds (on screen) it hangs before the hand lets go")

local STEP, NSTEPS, FRAME_DT = 1 / 4800, 8, 1 / 600
local function applyTiming()
  local speed = v:getParam("speed")
  NSTEPS = math.max(1, math.floor(v:getParam("steps") * speed / 60 + 0.5))
  FRAME_DT = speed / 60
  STEP = FRAME_DT / NSTEPS
  v.animationPeriod = 16
  common.setTiming(STEP, 0, STEP)
end
applyTiming()
v.gravity = btVector3(0, -G, 0)
v:setSolverIterations(60)
v.showConstraints = false

local Q0 = btQuaternion(0, 0, 0, 1)
local floor = Plane(0, 1, 0, 0, 400)
floor.col = "#6b4a2e"
floor.friction = 0.6
v:add(floor)

-- ---------------------------------------------------------------------
-- the stand: a post, an arm, the hand at its end
-- ---------------------------------------------------------------------
local N = math.floor(envnum("SL_COILS", 86))
local R = 3.4                           -- the coil's radius (to the wire's middle)
local CLOSED = 5.6                      -- closed-up height
local PITCH0 = CLOSED / N               -- a coil's closed-up spacing
local TOP_Y = 165                       -- the top coil, in the hand
local BALL_X, BALL_R = 14, 1.5
local WOOD, DARK, STEEL, BRASS = "#5a3418", "#3a2412", "#9a9ca3", "#b8932e"
local function vis(o, col, tr)
  o.col = col
  o.collides = false
  if tr then o.trans = tr end
  v:add(o)
  return o
end
local UPQ = btQuaternion(btVector3(1, 0, 0), math.pi / 2)
local function post(r, y0, y1, x, z, col)
  return vis(Cylinder(r, y1 - y0, 0), col, btTransform(UPQ, btVector3(x, (y0 + y1) / 2, z)))
end
post(1.2, 0, TOP_Y + 8, -25, -10, DARK)
vis(Cube(39, 3, 3, 0), DARK, btTransform(Q0, btVector3(-5.5, TOP_Y + 8, -10)))
vis(Cube(3, 3, 13, 0), DARK, btTransform(Q0, btVector3(0, TOP_Y + 8, -3.5)))       -- (out over the Slinky)
vis(Cube(3, 3, 13, 0), DARK, btTransform(Q0, btVector3(BALL_X, TOP_Y + 8, -3.5)))  -- (and over the ball)
vis(Cube(30, 1, 30, 0), DARK, btTransform(Q0, btVector3(-25, 0.5, -10)))
-- the hand: a clamp over the top coil, and a hook for the ball's thread
local hand = vis(Cube(9, 3, 9, 0), BRASS, btTransform(Q0, btVector3(0, TOP_Y + 2.2, 0)))
vis(Cube(2, 3, 2, 0), BRASS, btTransform(Q0, btVector3(0, TOP_Y + 5, 0)))

-- ---------------------------------------------------------------------
-- the coils
-- ---------------------------------------------------------------------
local coils = {}          -- { obj, body }
local slides = {}
local holds = {}
local anchor = Sphere(0.1, 0)
anchor.pos = btVector3(0, TOP_Y, 0)
anchor.collides = false
v:add(anchor)
local ballAnchor = Sphere(0.1, 0)
ballAnchor.collides = false
v:add(ballAnchor)

-- each coil's shape: a thin square plate as wide as the coil, so the
-- bottom one lands flat on the floor (neighbours, joined by their slide,
-- don't collide; the next but one is always further off than the plate is
-- thick)
local SHAPE = btBoxShape(btVector3(R + 0.2, math.max(0.004, PITCH0 * 0.3), R + 0.2))
SHAPE:setMargin(0.002)
local M, K, m, kseg
for i = 1, N do
  local o = Sphere(0.05, 0)       -- (each coil's own object: drawn as the wire, below)
  o.col = STEEL
  o.collides = true
  coils[i] = { obj = o }
end

-- the wire, drawn: 8 straight pieces a coil, following a helix from each
-- coil's height to the next one's
local PIECES = 8
local CHORD = 2 * R * math.sin(math.pi / PIECES)
local wire = {}
for k = 1, (N - 1) * PIECES do
  wire[k] = vis(Cube(CHORD + 0.12, 0.07, 0.28, 0), STEEL)
end

-- the ball and its thread
local BALL_M = 0.05
local ball = Sphere(BALL_R, BALL_M)
ball.col = "#5b5f66"
v:add(ball)
local thread         -- (made to length as it's hung)

local function addBodies()
  M = v:getParam("mass") / 1000
  K = v:getParam("stiffness")          -- N/m = kg/s^2, the same in centimetres
  m = M / N
  kseg = K * (N - 1)
  local ring = m * R * R
  for i, c in ipairs(coils) do
    if c.body then v:remove(c.obj); c.obj = Sphere(0.05, 0); c.obj.col = STEEL end
    local body = btRigidBody(m, btDefaultMotionState(btTransform(Q0, btVector3(0, TOP_Y, 0))), SHAPE,
                             btVector3(ring / 2, ring, ring / 2))
    c.obj.body = body
    v:add(c.obj)
    body:setActivationState(4)
    body:setDamping(0, 0)
    body:setFriction(0.5)
    body:setRestitution(0)
    c.body = body
  end
end

local t, released, bottomMoved, frontAt, landedAt
local reportedBottom, bottomBallY
local shown = 0          -- frames on screen since it was hung
local function theory() return math.sqrt(M / (3 * K)) end
local function clearConstraints()
  for _, s in ipairs(slides) do v:removeConstraint(s) end
  for _, h in pairs(holds) do v:removeConstraint(h) end
  slides, holds = {}, {}
end

-- hang it up: each coil where it hangs at rest, the top one in the hand
local XY = btQuaternion(btVector3(0, 0, 1), -math.pi / 2)    -- a slide's axis (x) turned to point down
local function hang()
  clearConstraints()
  addBodies()
  local y = TOP_Y
  for i, c in ipairs(coils) do
    local tr = btTransform(Q0, btVector3(0, y, 0))
    c.obj.trans = tr
    c.body:setCenterOfMassTransform(tr)
    c.body:setLinearVelocity(btVector3(0, 0, 0))
    c.body:setAngularVelocity(btVector3(0, 0, 0))
    c.y0 = y
    -- the gap below: closed up, plus the stretch the weight of the rest makes
    if i < N then y = y - (PITCH0 + (N - i) * m * G / kseg) end
  end
  for i = 1, N - 1 do
    -- the slide: coil i+1 along coil i's axis, pointing down, between closed
    -- up (PITCH0) and any stretch
    local s = btSliderConstraint(coils[i].body, coils[i + 1].body, btTransform(XY, btVector3(0, 0, 0)),
                                 btTransform(XY, btVector3(0, 0, 0)), true)
    s:setLowerLinLimit(PITCH0)
    s:setUpperLinLimit(1e4)
    s:setLowerAngLimit(0)
    s:setUpperAngLimit(0)
    s:setRestitutionLimLin(0)
    v:addConstraint(s)
    slides[i] = s
  end
  holds.top = btFixedConstraint(anchor.body, coils[1].body, btTransform(Q0, btVector3(0, 0, 0)),
                                btTransform(Q0, btVector3(0, 0, 0)))
  v:addConstraint(holds.top)
  -- the ball: beside the Slinky's bottom, its centre level with it
  local by = coils[N].y0
  ballAnchor.pos = btVector3(BALL_X, by + BALL_R, 0)
  local btr = btTransform(Q0, btVector3(BALL_X, by, 0))
  ball.trans = btr
  ball.body:setCenterOfMassTransform(btr)
  ball.body:setLinearVelocity(btVector3(0, 0, 0))
  ball.body:setAngularVelocity(btVector3(0, 0, 0))
  ball.body:setActivationState(4)
  holds.ball = btFixedConstraint(ballAnchor.body, ball.body, btTransform(Q0, btVector3(0, 0, 0)),
                                 btTransform(Q0, btVector3(0, BALL_R, 0)))
  v:addConstraint(holds.ball)
  if thread then v:remove(thread) end
  local top = TOP_Y + 6.5
  thread = vis(Cylinder(0.05, top - (by + BALL_R), 0), "#e8e0c8",
               btTransform(UPQ, btVector3(BALL_X, (top + by + BALL_R) / 2, 0)))
  t, released, bottomMoved, frontAt, landedAt, reportedBottom = 0, nil, nil, nil, nil, nil
  shown = 0
  print(string.format("\n--- hung up: %.0f g, %d coils, stiffness %.2f N/m; %.1f cm long hanging (%.1f cm closed up); the bottom should stay put for %.3f s ---",
                      M * 1000, N, K, TOP_Y - coils[N].y0 + PITCH0, CLOSED, theory()))
end

local function letGo()
  for _, h in pairs(holds) do v:removeConstraint(h) end
  holds = {}
  released = t
  print(string.format("t=%6.3fs  let go", t))
end

-- ---------------------------------------------------------------------
-- before every physics step: the springs between neighbours
-- ---------------------------------------------------------------------
local function springs()
  local ys = {}
  for i, c in ipairs(coils) do ys[i] = c.body:getCenterOfMassPosition().y end
  for i = 1, N - 1 do
    local s = ys[i] - ys[i + 1] - PITCH0
    if s > 0 then
      local f = kseg * s
      coils[i].body:applyCentralForce(btVector3(0, -f, 0))
      coils[i + 1].body:applyCentralForce(btVector3(0, f, 0))
    end
  end
end

-- (the moment the bottom starts to move is caught to the physics step)
local function watchBottom(tNow)
  if released and not bottomMoved and math.abs(coils[N].body:getLinearVelocity().y) > 1.0 then
    bottomMoved = tNow - released
    bottomBallY = ball.body:getCenterOfMassPosition().y
  end
end
v:preSim(function(N_)
  for k = 1, NSTEPS - 1 do
    springs()
    v:stepSimulation(STEP, 0, STEP)
    watchBottom(t + k * STEP)
  end
  springs()
end)

-- ---------------------------------------------------------------------
-- after every frame: draw the wire, the thread; watch the bottom
-- ---------------------------------------------------------------------
local function quatFromBasis(xx, xy, xz, yx, yy, yz, zx, zy, zz)
  -- the rotation whose columns are x, y, z
  local tr = xx + yy + zz
  local w, x, y, z
  if tr > 0 then
    local s = math.sqrt(tr + 1) * 2
    w, x, y, z = 0.25 * s, (yz - zy) / s, (zx - xz) / s, (xy - yx) / s
  elseif xx > yy and xx > zz then
    local s = math.sqrt(1 + xx - yy - zz) * 2
    w, x, y, z = (yz - zy) / s, 0.25 * s, (yx + xy) / s, (zx + xz) / s
  elseif yy > zz then
    local s = math.sqrt(1 + yy - xx - zz) * 2
    w, x, y, z = (zx - xz) / s, (yx + xy) / s, 0.25 * s, (zy + yz) / s
  else
    local s = math.sqrt(1 + zz - xx - yy) * 2
    w, x, y, z = (xy - yx) / s, (zx + xz) / s, (zy + yz) / s, 0.25 * s
  end
  return btQuaternion(x, y, z, w)
end
local function drawWire()
  local cx, _, cz = getPosXYZ(coils[1].obj)
  local k = 0
  for i = 1, N - 1 do
    local _, y0, _ = getPosXYZ(coils[i].obj)
    local _, y1, _ = getPosXYZ(coils[i + 1].obj)
    for j = 0, PIECES - 1 do
      local a0, a1 = 2 * math.pi * j / PIECES, 2 * math.pi * (j + 1) / PIECES
      local p0y, p1y = y0 + (y1 - y0) * j / PIECES, y0 + (y1 - y0) * (j + 1) / PIECES
      local p0x, p0z = R * math.cos(a0), R * math.sin(a0)
      local p1x, p1z = R * math.cos(a1), R * math.sin(a1)
      local dx, dy, dz = p1x - p0x, p1y - p0y, p1z - p0z
      local L = math.sqrt(dx * dx + dy * dy + dz * dz)
      dx, dy, dz = dx / L, dy / L, dz / L
      -- across: outward at the piece's middle; up: across x along
      local am = (a0 + a1) / 2
      local zx, zy, zz = math.cos(am), 0, math.sin(am)
      local yx, yy, yz = zy * dz - zz * dy, zz * dx - zx * dz, zx * dy - zy * dx
      local n = math.sqrt(yx * yx + yy * yy + yz * yz)
      yx, yy, yz = yx / n, yy / n, yz / n
      zx, zy, zz = dy * yz - dz * yy, dz * yx - dx * yz, dx * yy - dy * yx
      k = k + 1
      wire[k].trans = btTransform(quatFromBasis(dx, dy, dz, yx, yy, yz, zx, zy, zz),
                                  btVector3(cx + (p0x + p1x) / 2, (p0y + p1y) / 2, cz + (p0z + p1z) / 2))
    end
  end
  -- the thread: from the arm to the ball, while it hangs
  if released and thread then v:remove(thread); thread = nil end
end

local LOGF = os.getenv("SL_LOG") and io.open(os.getenv("SL_LOG"), "w")
if LOGF then LOGF:write("t,top_y,bottom_y,bottom_vy,ball_y,com_y\n") end
local restartIn
v:postSim(function(N_)
  if restartIn then
    restartIn = restartIn - 1
    if restartIn <= 0 then restartIn = nil; hang(); drawWire(); return end
  end
  t = t + FRAME_DT
  shown = shown + 1
  if not released and shown >= v:getParam("hold") * 60 then letGo() end
  drawWire()
  local _, ytop, _ = getPosXYZ(coils[1].obj)
  local _, ybot, _ = getPosXYZ(coils[N].obj)
  local vb = coils[N].body:getLinearVelocity().y
  if released then
    local since = t - released
    watchBottom(t)
    if bottomMoved and not reportedBottom then
      reportedBottom = true
      print(string.format("t=%6.3fs  the bottom starts to move, %.4f s after letting go (it should, by theory: %.4f s); the ball had fallen %.1f cm",
                          released + bottomMoved, bottomMoved, theory(), coils[N].y0 - bottomBallY))
    end
    if not landedAt and ybot < PITCH0 * 0.3 + 0.5 then
      landedAt = since
      print(string.format("t=%6.3fs  the Slinky lands, %.3f s after letting go", t, since))
    end
  end
  if LOGF then
    local com = 0
    for _, c in ipairs(coils) do com = com + select(2, getPosXYZ(c.obj)) end
    LOGF:write(string.format("%.5f,%.3f,%.3f,%.3f,%.3f,%.3f\n", t, ytop, ybot, vb, select(2, getPosXYZ(ball)), com / N))
  end
end)

-- ---------------------------------------------------------------------
-- keys, sliders, help
-- ---------------------------------------------------------------------
v:addShortcut("R", function(N_) hang(); drawWire() end)
v:addShortcut("Z", function(N_)
  local sp = v:getParam("speed") < 0.5 and 1 or 0.1
  v:addParam("speed", sp, 0.02, 1, 0.02, "simulated seconds per real second (Z: 1/10 <-> 1)")
  applyTiming()
end)
v:onParamChanged(function(N_, name, value)
  if name == "speed" or name == "steps" then applyTiming() end
  -- stiffness and mass: hang it up again with them, once the slider has
  -- been still for half a second (and not if it's what's hanging: bpp's
  -- Restart puts every slider back as it was)
  if (name == "stiffness" and K and math.abs(K - value) > 1e-6) or
     (name == "mass" and M and math.abs(M * 1000 - value) > 1e-6) then restartIn = 30 end
end)

v:setHelpText(table.concat({
  "The falling Slinky (Euler's Cabinet of Curiosities)",
  "",
  "A Slinky hangs from a hand, a steel ball beside its bottom.",
  "The hand lets go of both. The ball falls at once; the",
  "Slinky's bottom hangs still in mid-air until the coils",
  "collapsing from the top reach it. Theory: it waits",
  "sqrt(M/3k) -- no g in it.",
  "",
  "R   hang it up again (it lets go after two seconds)",
  "Z   a tenth of real speed <-> real speed",
  "",
  "Sliders: stiffness (N/m), mass (g) -- both hang it up",
  "again -- hold (s), speed, steps.",
}, "\n"))

common.setCamera(btVector3(envnum("SL_CX", 28), envnum("SL_CY", 110), envnum("SL_CZ", 210)),
                 btVector3(envnum("SL_LX", 2), envnum("SL_LY", 88), envnum("SL_LZ", 0)))
hang()
drawWire()
