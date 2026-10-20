--
-- The Gyroscope -- Euler's Gallery
--
-- Three toy gyroscopes, the same one each time: a brass rotor spinning
-- fast in a hoop, its axle standing out of the hoop at each end to a
-- little ball. Spun up and set down,
--   left    on a pedestal, held only by the ball at one end of its axle:
--           it doesn't fall, it goes round (precesses), axle level
--   middle  hung by a string from the same ball: the same, the string
--           leaning out a little as it goes round
--   right   on a tightrope, axle upright, standing on the wire on its
--           other end (a forked foot): it balances there, as a top
--           balances on its point. An attendant tips the wire, a degree
--           one way, then the other, and it slides to and fro along it,
--           upright (a gauge in front shows the tilt 20 times over)
-- As the rotors slow (air, bearings), the pedestal's and the string's go
-- round faster and sag lower; the tightrope one wobbles in wider and wider
-- circles. After 37 s the pedestal one slides off its point; after a
-- minute (39 turns a second) the tightrope one comes off the wire; the
-- one on the string sags on until, its rotor stopped (100 s), it just
-- hangs. R spins them up again.
--
-- THE GYROSCOPE: a rotor 6 cm across, 100 g, its weight mostly in the rim
-- (moment of inertia about the axle 0.65 m r^2), in a hoop 8.8 cm across
-- (50 g) on an axle (10 g); 160 g in all. Spun at 100 turns a second.
-- Held 6 cm from its centre, theory gives it a turn round every 2.45 s
-- (precession rate m g r / (I w) = 2.56 rad/s); it does that. On its
-- foot on the wire, a top's rule says it stays up while
-- I3 w > 2 sqrt(I m g l) (l = 6.4 cm, I across the axle about the foot):
-- above 46 turns a second (46.7 to 48.2). On a still, rough wire (the
-- friction slider at 0.3: 0.15 at the foot) it starts to wobble at 47
-- and comes off at 45; on a still wire with the default (0.005: 0.0025 at
-- the foot) it comes off at 42; rocked 1 degree, at 39.
--
-- PHYSICS
--  * Each gyroscope is one rigid body (hoop, axle and rotor together). The
--    rotor's spin relative to the hoop is carried as a number, an
--    angular momentum inside the body (a "gyrostat"): the rotor is drawn
--    turning, but Bullet never has to turn a body 100 times a second.
--  * Bullet's gyroscopic term is off. The body's gyroscopic torque,
--    -w x (I w + h) with h the rotor's angular momentum, is handed to
--    Bullet before every step, as the angular impulse it gives in the step
--    (not with applyTorque, which Bullet's friction leaves out: the foot
--    slid on a rough wire), so the pivot, the string and
--    the wire answer it as they would any force. It's taken from the last
--    two steps (Adams-Bashforth): taken from this step alone, the gyroscope
--    wobbles more and more; turned into a change of spin directly (as the
--    tops do), it sags steadily -- the pivot takes energy out every step.
--  * The pedestal's point is a ball joint at the ball's centre; the string
--    is a light rod (2 g) with a ball joint at each end; the wire is a
--    capsule 1.2 mm thick, the foot a ball (on the wire) and two prongs
--    (either side of it).
--  * Friction: the rotor loses 1 turn/s each second (air and bearings; what
--    the bearings take goes into whatever holds the frame, which doesn't
--    let it turn about its axle); a little friction at the pedestal's point
--    (and a quarter of it at the string's knot) against turning. That
--    friction is what makes them sag: with none, the sag is only the
--    wobble's, m g r I / (I3 w)^2, 3 degrees at 100 turns a second, 16 at
--    40. Foot and wire: 0.0025, as if the foot were a little wheel (it
--    slides on any slope over 0.14 degrees). Bullet multiplies the two
--    bodies' friction at a contact: the friction slider (0.005) is the
--    wire's, the frame keeps Bullet's own 0.5, so the slider's value is
--    twice what the foot has. (The frame on the table, if it falls: 0.6 x
--    0.5 = 0.3.)
--  * The wire is a kinematic body: tipped, Bullet gives it the speed it
--    moves at, and the foot feels that. Tipped more than about a degree,
--    the gyroscope is soon thrown over: each tip moves the way "up" is for
--    it, and it wobbles round the new up, and tips come about as often as
--    its wobble goes round (2.3 s), so they build it up. Rocked 1
--    degree it lasts 61 s (still: 58 s); 2, 9 s; 3, 6 s. 1.5 degrees is
--    on an edge: 63 s at the default 2400 steps a second (64 at 4800),
--    but at 1200 its wobble builds up and it comes off at 47 s, having
--    run into the posts at the wire's ends (15 cm out; its first two
--    slides do too). Along the wire only the slope and the
--    foot's friction act: its centre turns where a point sliding on the
--    tipped wire turns, to 0.1 cm (0.3 rocked 1.5 degrees).
--  * 2400 physics steps a second.
--
-- Keys
--   R   spin them up again
--   Z   slow motion (1/4) <-> real time
--
-- Units: centimetres, kilograms, seconds.
-- Headless testing: GY_SPIN (turns/s), GY_BEAR, GY_PIVF, GY_SLOPE, GY_ROCK,
-- GY_REACH (cm each way the attendant aims for), GY_MU, GY_LOG=file.csv.
--

local common = require "common"

local DIR = "gyroscope-meshes/"
for _, dir in ipairs({ DIR, "demo/WyomingWill/EulersGallery/exhibits/Gyroscope/" .. DIR }) do
  local f = io.open(dir .. "gyro-frame.obj", "r")
  if f then f:close(); DIR = dir; break end
end

local G = 981
-- the gyroscope (as gen-meshes.py)
local A = 4.4                      -- the hoop: radius to the bottom of its channel
local GW = 0.09                    -- the channel: half its width
local LIP_H, LIP_T = 0.35, 0.12    -- its sides: how far they stand out, how thick
local R, RW = 3.0, 1.0             -- rotor radius, rim width
local KNOB = 1.6                   -- the axle stands out of the hoop this far at each end, to a ball
local BALL = 0.32
local PIV = A + KNOB               -- where it's held (pedestal, string): the +x ball's centre
local WIRE_R = 0.06
-- the foot (the -x end): the wire sits under its ball, between two prongs
local D_WIRE = PIV + BALL + WIRE_R -- the wire's centre, from the gyroscope's centre
local PRONG_R, PRONG_L = 0.08, 0.6
local PRONG_Z = WIRE_R + 0.02 + PRONG_R
local MR, MH, MA = 0.100, 0.050, 0.010
local M = MR + MH + MA
local IR3 = 0.65 * MR * R * R      -- the rotor about the axle (its weight mostly in the rim)
local IR1 = 0.5 * IR3 + MR * RW * RW / 12
local I = {
  IR3 + 0.5 * MH * A * A,                             -- about the axle (x)
  IR1 + 0.5 * MH * A * A + MA * (2 * A) ^ 2 / 12,     -- y, in the hoop's plane
  IR1 + MH * A * A + MA * (2 * A) ^ 2 / 12,           -- z, across the hoop
}

local function envnum(n, d) return tonumber(os.getenv(n) or "") or d end
local function param(...) v:addParam(...) end
param("spin", envnum("GY_SPIN", 100), 30, 150, 5, "turns per second the rotors are spun up to (spins them up again)")
param("bearing", envnum("GY_BEAR", 1.0), 0, 5, 0.1, "the rotor's bearing friction: turns/s lost each second")
param("pivot friction", envnum("GY_PIVF", 0.5), 0, 20, 0.5, "friction against going round at the pedestal's point (x 1e-3 N m)")
param("slope", envnum("GY_SLOPE", 0), 0, 20, 1, "the wire's slope, degrees, while it isn't rocked (spins them up again)")
param("rock", envnum("GY_ROCK", 1), 0, 5, 0.5, "the tightrope: tip the wire this many degrees each way, to and fro, so the gyroscope slides (0: the wire stays at its slope; spins them up again)")
param("friction", envnum("GY_MU", 0.005), 0, 1, 0.005, "the wire's friction; Bullet multiplies it by the frame's 0.5, so at the foot it is half this (0.005: 0.0025)")
param("speed", 1, 0.05, 2, 0.05, "simulated seconds per real second (Z: 1/4 <-> 1)")
param("steps", 2400, 1200, 9600, 600, "physics steps per simulated second")

local STEP, NSTEPS, FRAME_DT = 1 / 2400, 40, 1 / 60
local function applyTiming()
  local speed = v:getParam("speed")
  NSTEPS = math.max(1, math.floor(v:getParam("steps") * speed / 60 + 0.5))
  FRAME_DT = speed / 60
  STEP = FRAME_DT / NSTEPS
  v.animationPeriod = 16
  common.setTiming(STEP, 0, STEP)
end

-- ---------------------------------------------------------------------
-- a pause at every start: one frame to put everything in place, then it
-- all stands still for HOLD_S seconds (half a second), so you see how it begins --
-- bpp's own physics step stopped too (a zero time step) -- and then it
-- carries on from there, exactly as if there had been no pause
-- ---------------------------------------------------------------------
local HOLD_FRAMES = math.floor(envnum("HOLD_S", 0.5) * 60 + 0.5)
local holdArm, holdLeft, holdNow = false, 0, false
local function holdStart() holdArm, holdLeft = true, 0 end
local function holdPre()            -- first thing before each step: true while it stands still
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
v:setSolverIterations(30)
v.showConstraints = false            -- (the joints are drawn as the pedestal's point and the string)

-- ---------------------------------------------------------------------
-- the table
-- ---------------------------------------------------------------------
local TABLE_Y = 0
local SPACING = 31
local Q0 = btQuaternion(0, 0, 0, 1)
local UPQ = btQuaternion(btVector3(1, 0, 0), math.pi / 2)        -- a Cylinder's axis (z) to y
local UPRIGHT = btQuaternion(btVector3(0, 0, 1), math.pi / 2)     -- a gyroscope's axle (x) to y, its -x end down
local function block(sx, sy, sz, x, y, z, col, solid, q)
  local c = Cube(sx, sy, sz, 0)
  c.trans = btTransform(q or Q0, btVector3(x, y, z))
  c.col = col
  if solid then c.friction = 0.6 else c.collides = false end
  v:add(c)
  return c
end
local function rod(r, y0, y1, x, z, col, solid)
  local c = Cylinder(r, y1 - y0, 0)
  c.trans = btTransform(UPQ, btVector3(x, (y0 + y1) / 2, z))
  c.col = col
  if solid then c.friction = 0.6 else c.collides = false end
  v:add(c)
  return c
end
block(118, 3, 44, 0, TABLE_Y - 1.5, 0, "#7a4a24", true)
for _, x in ipairs({ -54, 54 }) do
  for _, z in ipairs({ -18, 18 }) do block(3, 72, 3, x, TABLE_Y - 3 - 36, z, "#4e2e15") end
end
local floor = Plane(0, 1, 0, TABLE_Y - 75, 300)
floor.col = "#3b3f45"
v:add(floor)
local BRASS, DARK = "#c9a23f", "#3a2412"

-- left: the pedestal, its point at P_TIP
local P_HEIGHT = 16
local P_TIP = btVector3(-SPACING, TABLE_Y + P_HEIGHT, 0)
do
  local m = Mesh(DIR .. "pedestal.obj", 0, false)
  m.trans = btTransform(Q0, P_TIP)
  m.col = BRASS
  m.collides = false
  v:add(m)
  rod(0.45, TABLE_Y, P_TIP.y - 4.0, P_TIP.x, 0, BRASS, os.getenv("GY_COL") ~= "0")       -- what it can knock against
end
-- middle: a gallows, the string hung from HOOK
local S_LEN = 12
local HOOK = btVector3(0, TABLE_Y + 34, 0)
local POST_Z = -19
rod(0.6, TABLE_Y, HOOK.y + 1.2, 0, POST_Z, DARK, true)
block(1.2, 1.2, -POST_Z + 0.6, 0, HOOK.y + 0.6, POST_Z / 2 + 0.3, DARK, false)
block(4, 0.8, 4, 0, TABLE_Y + 0.4, POST_Z, DARK, false)
-- right: the wire, from W0 sloping down to the right, between two posts
local W_X0, W_LEN = SPACING - 15, 30
local W_X0p, W_Y0p                  -- (the wire's left end, as it is now)
local W_Y0 = TABLE_Y + 14
local wire, WIRE_DIR, WIRE_N
local wireSlope = 0                  -- radians, down to the right
local function wirePoint(s) return btVector3(W_X0p + s * WIRE_DIR.x, W_Y0p + s * WIRE_DIR.y, 0) end
local wirePosts = {}
local POST_LONG = 12                 -- the posts slide up and down through the table, this much spare below
-- the wire, sloping `sl` (radians) down to the right. Its left end stays at
-- W0 when it's set (slope slider); rocking, it turns about its middle,
-- MID, one end rising as the other falls. It's a kinematic body, so moving
-- it, Bullet gives it the velocity it moves at, and the foot on it feels that.
local MID = btVector3(W_X0 + W_LEN / 2, W_Y0, 0)
local function setWire(sl, aboutMid)
  wireSlope = sl
  WIRE_DIR = btVector3(math.cos(sl), -math.sin(sl), 0)
  WIRE_N = btVector3(math.sin(sl), math.cos(sl), 0)
  -- a capsule along x (Bullet's capsule-capsule contact is exact), turned
  -- down by the slope
  local q = btQuaternion(btVector3(0, 0, 1), -sl)
  local mid
  if aboutMid then
    mid = MID
    W_X0p, W_Y0p = MID.x - W_LEN / 2 * WIRE_DIR.x, MID.y - W_LEN / 2 * WIRE_DIR.y
  else
    W_X0p, W_Y0p = W_X0, W_Y0
    mid = btVector3(W_X0 + W_LEN / 2 * WIRE_DIR.x, W_Y0 + W_LEN / 2 * WIRE_DIR.y, 0)
  end
  if not wire then
    wire = Mesh(DIR .. "wire.obj", 0, false)
    wire.col = "#d8d8d8"
    wire.body = btRigidBody(0, btDefaultMotionState(btTransform(q, mid)), btCapsuleShapeX(WIRE_R, W_LEN), btVector3(0, 0, 0))
    wire.body:setFriction(v:getParam("friction"))
    wire.body:setCollisionFlags(wire.body:getCollisionFlags() + 2)     -- (kinematic)
    wire.body:setActivationState(4)
    v:add(wire)
    for k = 1, 2 do wirePosts[k] = rod(0.5, TABLE_Y - POST_LONG, W_Y0 + 0.8, 0, 0, DARK, true) end
  end
  wire.trans = btTransform(q, mid)
  -- the posts, at the wire's ends, their tops 0.8 above it
  for k, s in ipairs({ -0.5, W_LEN + 0.5 }) do
    local x, y = W_X0p + s * WIRE_DIR.x, W_Y0p + s * WIRE_DIR.y
    wirePosts[k].trans = btTransform(UPQ, btVector3(x, y + 0.8 - (W_Y0 + 0.8 - TABLE_Y + POST_LONG) / 2, 0))
  end
end
local function buildWire() setWire(math.rad(v:getParam("slope")), false) end
buildWire()
-- in front of the wire, a gauge: its needle turns 20 times as far as the
-- wire is tipped (a degree is too little to see on the wire itself)
local GAUGE_X20 = 20
local GAUGE_C = btVector3(MID.x, TABLE_Y + 5, 14)
local gauge, needle
do
  gauge = Cylinder(3.2, 0.3, 0)
  gauge.trans = btTransform(Q0, GAUGE_C)
  gauge.col = "#efe6cf"         -- (it collides, so the mouse finds it: bpp's hover only sees what collides)
  v:add(gauge)
  block(0.8, GAUGE_C.y - 3.2 - TABLE_Y, 0.8, GAUGE_C.x, (TABLE_Y + GAUGE_C.y - 3.2) / 2, GAUGE_C.z - 0.2, DARK, false)
  for _, deg in ipairs({ -40, -20, 0, 20, 40 }) do      -- marks at 0, 1 and 2 degrees each way
    local a = math.rad(deg)
    local len = deg == 0 and 0.9 or 0.6
    block(0.15, len, 0.1, GAUGE_C.x - (2.95 - len / 2) * math.sin(a), GAUGE_C.y + (2.95 - len / 2) * math.cos(a),
          GAUGE_C.z + 0.2, DARK, false, btQuaternion(btVector3(0, 0, 1), a))
  end
  needle = Cube(0.22, 2.6, 0.1, 0)
  needle.col = "#a8261c"
  needle.collides = false
  v:add(needle)
end
local function showGauge()
  local a = -GAUGE_X20 * wireSlope          -- (down to the right: the needle leans right)
  needle.trans = btTransform(btQuaternion(btVector3(0, 0, 1), a),
                             btVector3(GAUGE_C.x - 1.2 * math.sin(a), GAUGE_C.y + 1.2 * math.cos(a), GAUGE_C.z + 0.25))
end
showGauge()

-- ---------------------------------------------------------------------
-- the gyroscopes
-- ---------------------------------------------------------------------
-- the collision shape: the hoop as three discs (its channel and the two
-- sides); the rotor (a cylinder); the axle, and at each end a stem and a
-- ball; at -x the foot's prongs
local SHAPE = btCompoundShape(true)
SHAPE:addChildShape(btTransform(Q0, btVector3(0, 0, 0)), btCylinderShapeZ(btVector3(A, A, GW)))
for _, z in ipairs({ -1, 1 }) do
  SHAPE:addChildShape(btTransform(Q0, btVector3(0, 0, z * (GW + LIP_T / 2))), btCylinderShapeZ(btVector3(A + LIP_H, A + LIP_H, LIP_T / 2)))
end
SHAPE:addChildShape(btTransform(Q0, btVector3(0, 0, 0)), btCylinderShapeX(btVector3(RW / 2, R, R)))
SHAPE:addChildShape(btTransform(Q0, btVector3(0, 0, 0)), btCapsuleShapeX(0.14, 2 * A - 0.6))
for _, sx in ipairs({ -1, 1 }) do
  SHAPE:addChildShape(btTransform(Q0, btVector3(sx * (A + KNOB / 2 - 0.1), 0, 0)), btCapsuleShapeX(0.2, KNOB - 0.2))
  SHAPE:addChildShape(btTransform(Q0, btVector3(sx * PIV, 0, 0)), btSphereShape(BALL))
end
-- the foot's fork: two prongs either side of the wire, below the -x ball
for _, z in ipairs({ -1, 1 }) do
  SHAPE:addChildShape(btTransform(Q0, btVector3(-D_WIRE, 0, z * PRONG_Z)), btCapsuleShape(PRONG_R, PRONG_L))
end

local GYROS = {
  { name = "Left: on a pedestal, held by one end of its axle", short = "Pedestal", kind = "pedestal" },
  { name = "Middle: hung by a string from one end of its axle", short = "String", kind = "string" },
  { name = "Right: on a tightrope, axle upright, standing on its foot", short = "Tightrope", kind = "tightrope" },
}
local KEYS = {}
for _, g in ipairs(GYROS) do
  local frame = Mesh(DIR .. "gyro-frame.obj", 0, false)
  local body = btRigidBody(M, btDefaultMotionState(btTransform(Q0, btVector3(0, 50, 0))), SHAPE,
                           btVector3(I[1], I[2], I[3]))
  frame.body = body
  frame.col = BRASS
  v:add(frame)
  body:setActivationState(4)
  body:setDamping(0, 0)
  body:setRestitution(0)
  body:setFlags(0)                          -- gyroscopic term: handed over as an angular impulse, below
  local rotor = Mesh(DIR .. "gyro-rotor.obj", 0, false)
  rotor.col = "#b08a2e"
  rotor.collides = false
  v:add(rotor)
  local marks = Mesh(DIR .. "gyro-rotor-marks.obj", 0, false)
  marks.col = "#8c1c1c"
  marks.collides = false
  v:add(marks)
  g.m, g.body, g.rotor, g.marks = frame, body, rotor, marks
end
-- the pedestal's point and the string's hook: static anchors
local function anchor(p)
  local s = Sphere(0.05, 0)
  s.pos = p
  s.collides = false
  s.col = DARK
  v:add(s)
  return s
end
local P_ANCHOR = anchor(P_TIP)
local H_ANCHOR = anchor(HOOK)
-- the string: a light rod, 2 g
local S_MASS = 0.002
local stringObj = Mesh(DIR .. "string.obj", 0, false)
local stringBody = btRigidBody(S_MASS, btDefaultMotionState(btTransform(Q0, btVector3(0, HOOK.y - S_LEN / 2, 0))),
                               btCapsuleShapeX(0.05, S_LEN - 0.1),
                               btVector3(S_MASS * 0.05 ^ 2 / 2, S_MASS * S_LEN ^ 2 / 12, S_MASS * S_LEN ^ 2 / 12))
stringObj.body = stringBody
stringObj.col = "#e8e0c8"
stringObj.collides = false
v:add(stringObj)
stringBody:setActivationState(4)
stringBody:setDamping(0, 0)

local function basis(b)
  local B = b:getCenterOfMassTransform():getBasis()
  return { B:getColumn(0), B:getColumn(1), B:getColumn(2) }
end

local cons = {}
local function dropConstraints()
  for _, c in ipairs(cons) do v:removeConstraint(c) end
  cons = {}
end
local function pin(c) v:addConstraint(c); cons[#cons + 1] = c; return c end

local t = 0
local function place(g, q, pos)
  local b = g.body
  g.m.trans = btTransform(q, pos)          -- (the body and its motion state)
  b:setCenterOfMassTransform(btTransform(q, pos))
  b:setLinearVelocity(btVector3(0, 0, 0))
  b:setAngularVelocity(btVector3(0, 0, 0))
  b:clearForces()
  b:activate(true)
end

-- ---------------------------------------------------------------------
-- rocking the wire: an attendant tips it, ROCK degrees, about its middle,
-- one end rising as the other falls. First down to the right, to set the
-- gyroscope going; then always up on the side it's on (judged a little
-- ahead, LEAD seconds, for the time the tipping takes, SWING_S), so it
-- slides back and forth through the middle, as a ball rolls to and fro in
-- a dip.
-- ---------------------------------------------------------------------
local START_X, SWING_S, LEAD, ROCK_WAIT = 4, 0.6, 0.3, 1.0
local REACH = envnum("GY_REACH", 9)    -- how far each way it should slide (cm); the attendant tips later or sooner to keep it there
local rock = { on = false }
local function rockStart()
  rock = { on = v:getParam("rock") > 0, a = math.rad(v:getParam("rock")), from = 0, to = 0, tau = SWING_S,
           wait = ROCK_WAIT, started = false, swings = 0, late = 0, lastU = 0, ends = {}, s = 0 }
end
local function along(g)       -- the foot's place along the wire from its middle (cm, + right), and its speed
  local x, y, z = getPosXYZ(g.m)
  local a = basis(g.body)[1]
  local fx, fy = x - D_WIRE * a.x - MID.x, y - D_WIRE * a.y - MID.y
  local V = g.body:getLinearVelocity()
  return fx * WIRE_DIR.x + fy * WIRE_DIR.y, V.x * WIRE_DIR.x + V.y * WIRE_DIR.y
end
local function tipTo(sl)
  if sl ~= rock.to then rock.from, rock.to, rock.tau = wireSlope, sl, 0; rock.swings = rock.swings + 1 end
end
local function rockStep(h, g)
  if not rock.on then return end
  if g.state == "off the wire" then
    tipTo(0)                         -- (it's down: the wire's put level, and left)
  elseif rock.wait > 0 then
    rock.wait = rock.wait - h
    if rock.wait <= 0 then tipTo(rock.a) end
  else
    local s, u = along(g)
    rock.s = s
    if not rock.started then
      rock.started = s > START_X
    else
      -- each time it stops and turns: how far out it got; short of REACH,
      -- tip later next time (it gains), past it, sooner
      if u * rock.lastU < 0 and math.abs(s) > 1 then
        rock.late = math.max(-4, math.min(4, rock.late + 0.3 * (REACH - math.abs(s))))
        rock.ends[#rock.ends + 1] = s
      end
      rock.lastU = u
      local ahead = s + LEAD * u - (u > 0 and rock.late or -rock.late)
      tipTo(ahead > 0 and -rock.a or rock.a)
    end
  end
  if rock.tau < SWING_S then
    rock.tau = math.min(SWING_S, rock.tau + h)
    local f = rock.tau / SWING_S
    setWire(rock.from + (rock.to - rock.from) * (1 - math.cos(math.pi * f)) / 2, true)
  end
end

local spunWith                  -- the spin and slope they were last spun up with
local function spinThem()
  holdStart()
  t = 0
  dropConstraints()
  spunWith = { spin = v:getParam("spin"), slope = v:getParam("slope"), rock = v:getParam("rock") }
  local W = 2 * math.pi * v:getParam("spin")
  print(string.format("\n--- spun up: %.0f turns/s ---", v:getParam("spin")))
  for _, g in ipairs(GYROS) do
    g.S, g.phi, g.prev, g.state, g.since, g.events = W, 0, nil, nil, 0, {}
    g.turns, g.lastYaw = 0, nil
    if g.kind == "pedestal" then
      -- axle level, pointing toward -x from the point; the hoop flat; its
      -- +x end on the point
      local q = UPQ
      place(g, q, btVector3(P_TIP.x - PIV, P_TIP.y, P_TIP.z))
      g.pin = pin(btPoint2PointConstraint(g.body, P_ANCHOR.body, btVector3(PIV, 0, 0), btVector3(0, 0, 0)))
      g.state = "going round"
    elseif g.kind == "string" then
      -- the string straight down from the hook; the axle level, its +x end on the string
      local lo = btVector3(HOOK.x, HOOK.y - S_LEN, HOOK.z)
      local st = btTransform(btQuaternion(btVector3(0, 0, 1), -math.pi / 2), btVector3(HOOK.x, HOOK.y - S_LEN / 2, HOOK.z))
      stringObj.trans = st
      stringBody:setCenterOfMassTransform(st)
      stringBody:setLinearVelocity(btVector3(0, 0, 0))
      stringBody:setAngularVelocity(btVector3(0, 0, 0))
      place(g, UPQ, btVector3(lo.x - PIV, lo.y, lo.z))
      pin(btPoint2PointConstraint(stringBody, H_ANCHOR.body, btVector3(-S_LEN / 2, 0, 0), btVector3(0, 0, 0)))
      pin(btPoint2PointConstraint(stringBody, g.body, btVector3(S_LEN / 2, 0, 0), btVector3(PIV, 0, 0)))
      g.state = "going round"
    else
      -- the axle upright, its forked foot (-x) on the wire, tipped half a
      -- degree across the wire; the hoop in the wire's plane
      buildWire()
      rockStart()
      if rock.on then setWire(0, true) end
      showGauge()
      local q = btQuaternion(btVector3(1, 0, 0), math.rad(0.5)) * UPRIGHT
      local p = wirePoint(W_LEN / 2)
      -- (its centre straight up the axle from the wire)
      place(g, q, p)
      local ax = basis(g.body)[1]
      place(g, q, btVector3(p.x + D_WIRE * ax.x, p.y + D_WIRE * ax.y, p.z + D_WIRE * ax.z))
      g.state = "balancing"
    end
  end
end

-- ---------------------------------------------------------------------
-- before every physics step: the gyroscopic torque, the bearings, the
-- pivot friction
-- ---------------------------------------------------------------------
local BEAR, PIVF = 0, 0
local function cross(a1, a2, a3, b1, b2, b3) return a2 * b3 - a3 * b2, a3 * b1 - a1 * b3, a1 * b2 - a2 * b1 end
local function prestep(h)
  for _, g in ipairs(GYROS) do
    local b = g.body
    local c = basis(b)
    local W = b:getAngularVelocity()
    -- in body axes
    local w1 = c[1].x * W.x + c[1].y * W.y + c[1].z * W.z
    local w2 = c[2].x * W.x + c[2].y * W.y + c[2].z * W.z
    local w3 = c[3].x * W.x + c[3].y * W.y + c[3].z * W.z
    local hx = IR3 * g.S
    local t1, t2, t3 = cross(w1, w2, w3, I[1] * w1 + hx, I[2] * w2, I[3] * w3)
    t1, t2, t3 = -t1, -t2, -t3
    -- the rotor slows: air, and its bearings (what the bearings take goes
    -- through the frame into whatever holds it, which doesn't let the frame
    -- turn about its axle: so the frame isn't turned)
    if BEAR > 0 and g.S > 0 then
      g.S = g.S - math.min(g.S, BEAR * h)
    end
    g.phi = (g.phi + g.S * h) % (2 * math.pi)
    local tx = c[1].x * t1 + c[2].x * t2 + c[3].x * t3
    local ty = c[1].y * t1 + c[2].y * t2 + c[3].y * t3
    local tz = c[1].z * t1 + c[2].z * t2 + c[3].z * t3
    -- Adams-Bashforth: 3/2 of this step's torque less 1/2 of the last
    local p = g.prev
    if not p then p = { tx, ty, tz }; g.prev = p end
    local ax, ay, az = 1.5 * tx - 0.5 * p[1], 1.5 * ty - 0.5 * p[2], 1.5 * tz - 0.5 * p[3]
    p[1], p[2], p[3] = tx, ty, tz
    -- friction against going round, at the pedestal's point and the string's knot
    -- (against any turning there: about the upright mostly, which is what
    -- makes it sag; about the axle, which keeps the hoop from rolling over
    -- on the point)
    if PIVF > 0 and (g.pin or g.kind == "string") then
      local f = (g.kind == "string" and 0.25 or 1) * PIVF
      local wn = math.sqrt(W.x * W.x + W.y * W.y + W.z * W.z)
      local k = f * math.min(1, wn / 0.05) / math.max(wn, 1e-9)
      ax, ay, az = ax - k * W.x, ay - k * W.y, az - k * W.z
    end
    -- as the angular impulse it gives in the step, just before it, not
    -- with applyTorque: Bullet 3.24 leaves a torque set with applyTorque
    -- out of the speed its friction holds to zero (it has it in the push
    -- and in the speed the step leaves), so a foot held by friction slid
    -- at h*C*dt/I, every step (on a still, rough wire: 0.04 cm/s, under a
    -- degree from upright, as predicted; it set the top wobbling at 66 turns/s,
    -- not the rule's 47; changed 20 Oct 2026). As an impulse it is in
    -- every part of the solve.
    b:applyTorqueImpulse(btVector3(ax * h, ay * h, az * h))
  end
end

v:preSim(function(N)
  if holdPre() then return end
  for k = 1, NSTEPS - 1 do
    prestep(STEP)
    rockStep(STEP, GYROS[3])
    v:stepSimulation(STEP, 0, STEP)
  end
  prestep(STEP)
  rockStep(STEP, GYROS[3])
end)

-- ---------------------------------------------------------------------
-- after every frame: the rotors follow, and what each is doing
-- ---------------------------------------------------------------------
local function axleTilt(g)
  -- the axle's angle below level (pedestal, string) or from upright (tightrope)
  local a = basis(g.body)[1]
  if g.kind == "tightrope" then return math.deg(math.acos(math.max(-1, math.min(1, math.abs(a.y))))) end
  return math.deg(math.asin(math.max(-1, math.min(1, a.y))))
end
local LOGF = os.getenv("GY_LOG") and io.open(os.getenv("GY_LOG"), "w")
if LOGF then LOGF:write("t,which,tilt_deg,spin_turns_s,x,y,z,yaw_deg\n") end
local function say(g, s)
  if s ~= g.state then
    g.state, g.since = s, t
    print(string.format("  %-9s %s at %5.1f s (spin %.0f turns/s)", g.short, s, t, g.S / (2 * math.pi)))
  end
end
local restartIn                 -- frames until a slider's respin (see onParamChanged)
-- (frames counted only while it runs, not while it stands still: the
-- lines every 2 s come at the same moments with or without the pause)
local runFrames = 0
v:postSim(function(N)
  if holdNow then return end
  runFrames = runFrames + 1
  N = runFrames
  if restartIn then
    restartIn = restartIn - 1
    if restartIn <= 0 then restartIn = nil; spinThem(); return end
  end
  t = t + FRAME_DT
  showGauge()
  for k, g in ipairs(GYROS) do
    local x, y, z = getPosXYZ(g.m)
    local tq = g.body:getCenterOfMassTransform():getRotation() * btQuaternion(btVector3(1, 0, 0), g.phi)
    local rt = btTransform(tq, btVector3(x, y, z))
    g.rotor.trans = rt
    g.marks.trans = rt
    local tilt = axleTilt(g)
    g.tilt = tilt
    -- turns round (pedestal, string): the axle's heading
    local a = basis(g.body)[1]
    local yaw = math.deg(math.atan2(-a.z, a.x))
    if g.lastYaw then
      local d = yaw - g.lastYaw
      if d > 180 then d = d - 360 elseif d < -180 then d = d + 360 end
      g.turns = g.turns + d / 360
    end
    g.lastYaw = yaw
    if g.kind == "pedestal" and g.pin and tilt > 40 then
      -- it slides off the point
      v:removeConstraint(g.pin)
      for i, c in ipairs(cons) do if c == g.pin then table.remove(cons, i) break end end
      g.pin = nil
      say(g, "off the pedestal")
    elseif g.kind ~= "tightrope" and g.state == "going round" and tilt > 30 then
      say(g, "sagging")
    elseif g.kind == "tightrope" and g.state == "balancing" and tilt > 5 then
      say(g, "wobbling")
    elseif g.kind == "tightrope" and g.state ~= "off the wire" and (tilt > 50 or y < W_Y0 - 3) then
      say(g, "off the wire")
    end
    if LOGF and N % 4 == 0 then
      LOGF:write(string.format("%.4f,%d,%.2f,%.2f,%.3f,%.3f,%.3f,%.1f\n", t, k, tilt, g.S / (2 * math.pi), x, y, z, yaw))
    end
  end
  if N % 120 == 0 then
    local parts = {}
    for _, g in ipairs(GYROS) do
      if g.kind == "tightrope" then
        parts[#parts + 1] = string.format("%s from upright %4.1f deg, %3.0f t/s", g.short, g.tilt, g.S / (2 * math.pi)) ..
          (rock.on and string.format(", %+5.1f cm along the wire, tipped %+4.2f deg", rock.s, math.deg(wireSlope)) or "")
      else
        parts[#parts + 1] = string.format("%s below level %4.1f deg, %3.0f t/s, %.1f times round", g.short,
          g.tilt, g.S / (2 * math.pi), math.abs(g.turns))
      end
    end
    print(string.format("t=%5.1fs  %s", t, table.concat(parts, " | ")))
  end
  if LOGF and N % 60 == 0 then LOGF:flush() end
end)

-- ---------------------------------------------------------------------
-- keys, sliders
-- ---------------------------------------------------------------------
v:addShortcut("R", function(N) spinThem() end)
v:addShortcut("Z", function(N)
  local sp = v:getParam("speed") < 0.5 and 1 or 0.25
  v:addParam("speed", sp, 0.05, 2, 0.05, "simulated seconds per real second (Z: 1/4 <-> 1)")
  applyTiming()
end)
v:onParamChanged(function(N, name, value)
  -- spin and slope: spin them up again with it, once the slider has been
  -- still for half a second (and not if it's what they were spun with:
  -- bpp's Restart puts every slider back as it was)
  if spunWith and spunWith[name] ~= nil and math.abs(spunWith[name] - value) > 1e-6 then restartIn = 30 end
  if name == "speed" or name == "steps" then applyTiming() end
  if name == "friction" then wire.body:setFriction(value) end
  if name == "bearing" then BEAR = value * 2 * math.pi end
  if name == "pivot friction" then PIVF = value * 1e-3 * 1e4 end
end)
BEAR = v:getParam("bearing") * 2 * math.pi
PIVF = v:getParam("pivot friction") * 1e-3 * 1e4      -- N m to kg cm^2/s^2

v:setHelpText(table.concat({
  "The gyroscope (Euler's Gallery)",
  "",
  "A brass rotor spinning fast in a hoop. Held by one end of",
  "its axle, it doesn't fall: it goes round, axle level.",
  "",
  "Left:   on a pedestal",
  "Middle: hung by a string",
  "Right:  on a tightrope, axle upright, standing on the wire",
  "        on its forked foot: it balances, as a top does.",
  "        The wire is tipped a degree one way, then the other,",
  "        and it slides to and fro (the gauge: the tilt x 20)",
  "",
  "As the rotors slow, the left two go round faster and sag;",
  "the right one wobbles wider and comes off the wire.",
  "In about a minute all three are down.",
  "",
  "R   spin them up again",
  "Z   slow motion (1/4) <-> real time",
  "",
  "Sliders: spin (turns/s), bearing, pivot friction,",
  "rock (degrees each way; 0: still), slope (when still);",
  "spin, rock and slope spin them up again once you let go",
  "of the slider; friction (the wire's: half at the foot),",
  "speed, steps.",
  "Rest the mouse on a gyroscope to see what it's doing.",
}, "\n"))

if v.onHover then
  for _, g in ipairs(GYROS) do
    KEYS[objectKey(g.m)] = g
  end
  local TILTED = {}
  for _, o in ipairs({ gauge, needle, wire }) do TILTED[objectKey(o)] = true end
  v:onHover(function(N, obj, x, y, z)
    local key = objectKey(obj)
    if TILTED[key] then
      local d = math.deg(wireSlope)
      return string.format("The wire, tipped %.2f degrees%s\n(its ends %.1f mm above and below its middle)\n" ..
                           "The gauge's needle turns %d times as far; its marks are at 1 and 2 degrees.",
                           math.abs(d), d > 0.005 and " down to the right" or d < -0.005 and " down to the left" or "",
                           10 * W_LEN / 2 * math.abs(math.sin(wireSlope)), GAUGE_X20)
    end
    local g = KEYS[key]
    if not g then return nil end
    local how = g.kind == "tightrope" and string.format("axle %.0f deg from upright", g.tilt or 0) ..
                (rock.on and string.format(", %.1f cm %s of the wire's middle", math.abs(rock.s), rock.s >= 0 and "right" or "left") or "")
                                       or string.format("axle %.0f deg below level, %.1f times round", g.tilt or 0, math.abs(g.turns or 0))
    return string.format("%s\n%s for %.1f s\n%s, rotor %.0f turns/s", g.name, g.state or "?", t - (g.since or 0),
                         how, g.S / (2 * math.pi))
  end)
end

common.setCamera(btVector3(envnum("GY_CX", 0), envnum("GY_CY", 34), envnum("GY_CZ", 72)),
                 btVector3(envnum("GY_LX", 0), envnum("GY_LY", 17), envnum("GY_LZ", 0)))
spinThem()
