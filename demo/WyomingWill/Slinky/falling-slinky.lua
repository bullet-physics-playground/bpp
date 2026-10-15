--
-- The Falling Slinky, and the Slinky on the stairs -- Euler's Cabinet of
-- Curiosities
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
-- console gives what it does and what it should, each drop: 1.0% longer,
-- 0.6% for the 86 separate coils (a chain of them, worked out exactly,
-- waits 0.2030 s; the more coils, the closer) and 0.4% for the step (at
-- 19200 steps a second, 0.2031 s).
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
--    below it), held for half a second (on screen), then let go.
--  * A twentieth of a second after it lands, it's laid to rest, closed up
--    where it landed (86 thin coils piled up don't keep still in Bullet).
--  * 4800 physics steps a second; it runs at a tenth of real speed (Z: real
--    speed).
--
-- THE STAIRS: right beside it, the same Slinky walks down seven steps
-- (12 cm up, 13 cm deep). It starts as a hand would set it going: half of
-- it closed up in a pile at the top step's edge, the rest lifted over in an
-- arch, its end set down on the next step. The pile pours over into the
-- arch, the far end becomes a pile, and the Slinky turns end over end down
-- the stairs -- each end landing a step lower than the other did -- to the
-- floor, about 0.4 s a step. Then it starts again. Like a
-- real one it's sensitive: nearly one walk in two goes wrong (21 in a row:
-- 12 clean, 4 galloped, skipping a step, 3 stopped short, 2 never got
-- going).
--  * Built in the plane of the drawing: 43 pieces of two coils each,
--    capsules that touch each other (closed up) and the stairs. Each
--    piece's two sides are joined to the next piece's by a spring that only
--    pulls (half of k times 42 each), with a little damping; a stiff spring
--    keeps the pieces in line. The same mass and stiffness as the falling
--    one (the sliders set both).
--
-- Keys
--   R   hang it up again (and let go)
--   V   views: both Slinkys; the falling one close up; the stairs close up
--   W   set the Slinky on the stairs going again, from the top
--   Z   a tenth of real speed <-> real speed
--
-- Units: centimetres, kilograms, seconds.
-- Headless testing: SL_COILS, SL_K (N/m), SL_MASS (g), SL_SPEED, SL_STEPS,
-- SL_LOG=file.csv.
--

local common = require "common"

local DIR = "slinky-meshes/"
for _, dir in ipairs({ DIR, "demo/WyomingWill/Slinky/" .. DIR }) do
  local f = io.open(dir .. "coil.obj", "r")
  if f then f:close(); DIR = dir; break end
end
local COIL = DIR .. "coil.obj"     -- (a coil of the Slinky on the stairs)

local G = 981
local function envnum(n, d) return tonumber(os.getenv(n) or "") or d end
local function param(...) v:addParam(...) end
param("speed", envnum("SL_SPEED", 0.1), 0.02, 1, 0.02, "simulated seconds per real second (Z: 1/10 <-> 1)")
param("steps", envnum("SL_STEPS", 4800), 2400, 9600, 600, "physics steps per simulated second")
param("stiffness", envnum("SL_K", 1.76), 1.2, 5, 0.02, "the Slinky's stiffness, N/m (hangs it up again)")
param("mass", envnum("SL_MASS", 215), 100, 300, 5, "the Slinky's mass, g (hangs it up again)")
param("hold", 0.5, 0.5, 6, 0.5, "seconds (on screen) it hangs before the hand lets go")

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

local t, released, bottomMoved, frontAt, landedAt, rested
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
  t, released, bottomMoved, frontAt, landedAt, reportedBottom, rested = 0, nil, nil, nil, nil, nil, nil
  shown = 0
  print(string.format("\n--- hung up: %.0f g, %d coils, stiffness %.2f N/m; %.1f cm long hanging (%.1f cm closed up); the bottom should stay put for %.3f s ---",
                      M * 1000, N, K, TOP_Y - coils[N].y0 + PITCH0, CLOSED, theory()))
end

-- once it has landed (a twentieth of a second on), it's laid to rest: a
-- closed-up pile where it landed, still. (86 thin coils piled on each other
-- don't keep still in Bullet: they jostle, and now and then fly apart.)
local REST_AFTER = 0.05
local function layToRest()
  rested = true
  for _, s in ipairs(slides) do v:removeConstraint(s) end
  slides = {}
  local bx, _, bz = getPosXYZ(coils[N].obj)
  local h0 = math.max(0.004, PITCH0 * 0.3) + 0.002
  for i, c in ipairs(coils) do
    local tr = btTransform(Q0, btVector3(bx, h0 + (N - i) * PITCH0, bz))
    c.obj.trans = tr
    c.body:setCenterOfMassTransform(tr)
    c.body:setLinearVelocity(btVector3(0, 0, 0))
    c.body:setAngularVelocity(btVector3(0, 0, 0))
    c.body:forceActivationState(5)       -- (out of the simulation till it's hung up again)
  end
  print(string.format("t=%6.3fs  laid to rest, closed up where it landed", t))
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
  if rested then return end
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
-- ---------------------------------------------------------------------
-- the stairs, and a second Slinky that walks down them
-- ---------------------------------------------------------------------
-- (the same Slinky, built as 43 pieces of two coils each, moving in the
-- plane of the drawing: x and y, turning about z)
local NW = 43
local ST_X0 = 48                        -- the top step's front edge... less a tread
local RISE, TREAD, NST = 12, 13, 7
local ST_TOP = RISE * NST               -- the top step, 84 cm up (the floor is the eighth)
local STAIR_COL = { "#7a4a24", "#6a3e1c" }
local stepTop = {}
do
  local function solid(sx, sy, sz, x, y, z, col)
    local b = Cube(sx, sy, sz, 0)
    b.trans = btTransform(Q0, btVector3(x, y, z))
    b.col = col
    b.friction = 0.6
    v:add(b)
  end
  -- the landing behind the top step, then the steps down toward +x
  solid(20, ST_TOP, 30, ST_X0 - 10, ST_TOP / 2, 0, STAIR_COL[1])
  for k = 0, NST - 1 do
    local yt = ST_TOP - k * RISE
    stepTop[k + 1] = yt
    solid(TREAD, yt, 30, ST_X0 + (k + 0.5) * TREAD, yt / 2, 0, STAIR_COL[k % 2 + 1])
  end
end
local function stepOf(x)
  local k = math.floor((x - ST_X0) / TREAD) + 1
  return math.max(0, math.min(NST + 1, k))
end

local W = { coils = {} }
-- (each piece is drawn as a coil, and a second coil drawn half way to the
-- next piece)
local wmid = {}
for k = 1, NW - 1 do wmid[k] = vis(Mesh(COIL, 0, false), STEEL) end
local function buildWalker()
  local c = CLOSED / NW
  local rc = c / 2
  local m = M / NW
  W.c, W.rc, W.m = c, rc, m
  W.kside = K * (NW - 1) / 2           -- each side of a piece: half of it
  W.ksh = 10 * K * (NW - 1)            -- sideways stiffness between pieces
  W.cd = 0.05                          -- a little damping on each side spring
  local shape = btCapsuleShapeX(rc, 2 * R)
  for i = 1, NW do
    local cc = W.coils[i]
    if cc then v:remove(cc.o) end
    local o = Mesh(COIL, 0, false)
    o.col = STEEL
    local b = btRigidBody(m, btDefaultMotionState(btTransform(Q0, btVector3(0, -100, 0))), shape,
                          btVector3(m * R * R / 2, m * R * R, m * R * R / 2))
    o.body = b
    v:add(o)
    b:setActivationState(4)
    b:setDamping(0, 0)
    b:setFriction(0.6)
    b:setRestitution(0)
    b:setLinearFactor(btVector3(1, 1, 0))
    b:setAngularFactor(btVector3(0, 0, 1))
    W.coils[i] = { o = o, b = b }
  end
end
local function wPlace(i, x, y, ang)
  local tr = btTransform(btQuaternion(btVector3(0, 0, 1), ang), btVector3(x, y, 0))
  local cc = W.coils[i]
  cc.o.trans = tr
  cc.b:setCenterOfMassTransform(tr)
  cc.b:setLinearVelocity(btVector3(0, 0, 0))
  cc.b:setAngularVelocity(btVector3(0, 0, 0))
end
-- set it going as a hand would: half of it closed up in a pile at the top
-- step's front edge, the other half lifted over in an arch and its end set
-- down on the next step
local function walkStart()
  buildWalker()
  local c, rc = W.c, W.rc
  local NA = math.floor(NW / 2)
  local xa = ST_X0 + TREAD - R - 0.5
  for i = 1, NA do wPlace(i, xa, stepTop[1] + rc + (i - 1) * c, 0) end
  local x1, y1 = xa, stepTop[1] + rc + (NA - 1) * c
  local x2, y2 = ST_X0 + TREAD + R + 4, stepTop[2] + rc
  local H = 12
  local xm, a = (x1 + x2) / 2, (x2 - x1) / 2
  local pts, n = {}, 400
  for k = 0, n do
    local th = math.pi * (1 - k / n)
    pts[#pts + 1] = { xm + a * math.cos(th), y1 + (y2 - y1) * k / n + H * math.sin(th) }
  end
  local L = 0
  for k = 2, #pts do L = L + math.sqrt((pts[k][1] - pts[k - 1][1]) ^ 2 + (pts[k][2] - pts[k - 1][2]) ^ 2) end
  local function at(sv)
    local acc = 0
    for k = 2, #pts do
      local d = math.sqrt((pts[k][1] - pts[k - 1][1]) ^ 2 + (pts[k][2] - pts[k - 1][2]) ^ 2)
      if acc + d >= sv or k == #pts then
        local u = math.min(1, (sv - acc) / d)
        return pts[k - 1][1] + u * (pts[k][1] - pts[k - 1][1]), pts[k - 1][2] + u * (pts[k][2] - pts[k - 1][2]),
               math.atan2(pts[k][2] - pts[k - 1][2], pts[k][1] - pts[k - 1][1])
      end
      acc = acc + d
    end
  end
  for i = NA + 1, NW - 1 do
    local x, y, tang = at((i - NA) * L / (NW - NA))
    wPlace(i, x, y, tang - math.pi / 2)
  end
  wPlace(NW, x2, y2, math.pi)          -- (the end lies flat on the step, the other way up)
  W.t, W.landed, W.still, W.done = 0, { [1] = { 1 }, [NW] = { 2 } }, 0, nil
  W.lastLand = 0
  print(string.format("--- stairs: the second Slinky set going down %d steps (%.0f cm up, %.0f cm deep) ---", NST, RISE, TREAD))
end

-- before every step: the springs between the pieces. Each piece's two
-- sides (its ends, R either side of its middle) are joined to the next
-- piece's by a spring that pulls when they're apart (closed up, the pieces
-- touch: their shapes meet); and a stiff spring keeps the pieces in line.
-- All of them act along the line between the two points they join, so the
-- forces are equal and opposite and turn nothing on the whole.
local function walkForces(dt)
  local P, X, V, Wz, F = {}, {}, {}, {}, {}
  local cs = W.coils
  for i = 1, NW do
    local o = cs[i].o
    local px, py = getPosXYZ(o)
    local vx, vy = getVelXYZ(o)
    local _, _, wz = getAngVelXYZ(o)
    local q = cs[i].b:getOrientation()
    local a = 2 * math.atan2(q:getZ(), q:getW())        -- (it turns about z only)
    P[i] = { px, py }; X[i] = { math.cos(a), math.sin(a) }; V[i] = { vx, vy }; Wz[i] = wz
    F[i] = { 0, 0, 0 }
  end
  local c, kside, cd, ksh = W.c, W.kside, W.cd, W.ksh
  for i = 1, NW - 1 do
    local j = i + 1
    local Fi, Fj = F[i], F[j]
    for s = -1, 1, 2 do
      local rax, ray = s * R * X[i][1], s * R * X[i][2]
      local rbx, rby = s * R * X[j][1], s * R * X[j][2]
      local dx, dy = P[j][1] + rbx - P[i][1] - rax, P[j][2] + rby - P[i][2] - ray
      local Ld = math.sqrt(dx * dx + dy * dy)
      if Ld > c then
        local ux, uy = dx / Ld, dy / Ld
        local vax, vay = V[i][1] - Wz[i] * ray, V[i][2] + Wz[i] * rax
        local vbx, vby = V[j][1] - Wz[j] * rby, V[j][2] + Wz[j] * rbx
        local f = kside * (Ld - c) + cd * ((vbx - vax) * ux + (vby - vay) * uy)
        if f > 0 then
          Fi[1], Fi[2], Fi[3] = Fi[1] + f * ux, Fi[2] + f * uy, Fi[3] + rax * f * uy - ray * f * ux
          Fj[1], Fj[2], Fj[3] = Fj[1] - f * ux, Fj[2] - f * uy, Fj[3] - (rbx * f * uy - rby * f * ux)
        end
      end
    end
    -- in line: the sideways offset between the two middles, at the midpoint
    local dx, dy = P[j][1] - P[i][1], P[j][2] - P[i][2]
    local ex, ey = (X[i][1] + X[j][1]) / 2, (X[i][2] + X[j][2]) / 2
    local f = ksh * (dx * ex + dy * ey)
    local tq = (dx * f * ey - dy * f * ex) / 2
    Fi[1], Fi[2], Fi[3] = Fi[1] + f * ex, Fi[2] + f * ey, Fi[3] + tq
    Fj[1], Fj[2], Fj[3] = Fj[1] - f * ex, Fj[2] - f * ey, Fj[3] + tq
  end
  -- (handed over as velocity changes, F dt / m and torque dt / I)
  local km, ki = dt / W.m, dt / (W.m * R * R / 2)
  for i = 1, NW do
    local Fi = F[i]
    setVelXYZ(cs[i].o, V[i][1] + Fi[1] * km, V[i][2] + Fi[2] * km, 0)
    setAngVelXYZ(cs[i].o, 0, 0, Wz[i] + Fi[3] * ki)
  end
end

-- after every frame: draw the coil half way between each two pieces, note
-- each end's landings, and start again once it's done
local function walkDraw()
  local px, py, pa = {}, {}, {}
  for i, cc in ipairs(W.coils) do
    px[i], py[i] = getPosXYZ(cc.o)
    local q = cc.b:getOrientation()
    pa[i] = 2 * math.atan2(q:getZ(), q:getW())
  end
  for i = 1, NW - 1 do
    local d = pa[i + 1] - pa[i]
    d = (d + math.pi) % (2 * math.pi) - math.pi
    wmid[i].trans = btTransform(btQuaternion(btVector3(0, 0, 1), pa[i] + d / 2),
                                btVector3((px[i] + px[i + 1]) / 2, (py[i] + py[i + 1]) / 2, 0))
  end
end
local function walkWatch()
  W.t = W.t + FRAME_DT
  local moving = false
  for _, e in ipairs({ 1, NW }) do
    local x, y = getPosXYZ(W.coils[e].o)
    local vv = W.coils[e].b:getLinearVelocity()
    local sp = math.sqrt(vv.x * vv.x + vv.y * vv.y)
    local k = stepOf(x)
    local on = (k >= 1 and k <= NST and math.abs(y - stepTop[k]) < 1) or (k > NST and y < 1)
    local L = W.landed[e]
    if on and sp < 10 and L[#L] ~= k then
      L[#L + 1] = k
      W.lastLand = W.t
      print(string.format("stairs t=%5.2fs  its %s end lands on %s", W.t, e == 1 and "first" or "other",
                          k > NST and "the floor" or ("step " .. k)))
    end
  end
  for _, cc in ipairs(W.coils) do
    local vv = cc.b:getLinearVelocity()
    if vv.x * vv.x + vv.y * vv.y > 4 then moving = true; break end
  end
  W.still = moving and 0 or W.still + FRAME_DT
  if not W.done and W.still > 0.5 then
    W.done = W.t
    local x = getPosXYZ(W.coils[1].o)
    local furthest = math.max(W.landed[1][#W.landed[1]], W.landed[NW][#W.landed[NW]])
    print(string.format("stairs t=%5.2fs  the walking Slinky comes to rest, %s: %d steps down in %.2f s",
                        W.t, furthest > NST and "on the floor" or ("on step " .. furthest), furthest - 1, W.lastLand))
  end
  -- (and goes again, a few seconds on)
  if W.done and W.t > W.done + 3 then walkStart() end
end

v:preSim(function(N_)
  for k = 1, NSTEPS - 1 do
    springs()
    walkForces(STEP)
    v:stepSimulation(STEP, 0, STEP)
    watchBottom(t + k * STEP)
  end
  springs()
  walkForces(STEP)
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
    if restartIn <= 0 then restartIn = nil; hang(); drawWire(); walkStart(); walkDraw(); return end
  end
  t = t + FRAME_DT
  shown = shown + 1
  if not released and shown >= v:getParam("hold") * 60 then letGo() end
  drawWire()
  walkDraw()
  walkWatch()
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
    if landedAt and not rested and since - landedAt >= REST_AFTER then layToRest() end
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
-- the views (V): both Slinkys; the falling one close up; the stairs close up
local VIEW = 1
local function setView()
  if VIEW == 1 then        -- both: the falling one and the stairs
    common.setCamera(btVector3(envnum("SL_CX", 58), envnum("SL_CY", 100), envnum("SL_CZ", 235)),
                     btVector3(envnum("SL_LX", 58), envnum("SL_LY", 84), envnum("SL_LZ", 0)))
  elseif VIEW == 2 then    -- close up on the falling one and the ball
    common.setCamera(btVector3(34, 142, 118), btVector3(6, 128, 0))
  else                     -- close up on the stairs
    common.setCamera(btVector3(ST_X0 + 45, 80, 125), btVector3(ST_X0 + 45, 45, 0))
  end
end

v:addShortcut("R", function(N_) hang(); drawWire() end)
v:addShortcut("V", function(N_) VIEW = VIEW % 3 + 1; setView() end)
v:addShortcut("W", function(N_) walkStart(); walkDraw() end)
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
  "Beside it, the same Slinky walks down seven stairs,",
  "end over end, and starts again once it's on the floor.",
  "",
  "R   hang it up again (it lets go after half a second)",
  "V   views: both; the falling one close; the stairs close",
  "W   set the one on the stairs going again",
  "Z   a tenth of real speed <-> real speed",
  "",
  "Sliders: stiffness (N/m), mass (g) -- both start both",
  "again -- hold (s), speed, steps.",
}, "\n"))

setView()
hang()
drawWire()
walkStart()
walkDraw()
