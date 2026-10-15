--
-- Huygens' Clocks -- Euler's Cabinet of Curiosities
--
-- In February 1665, ill in bed, Christiaan Huygens watched two of his
-- pendulum clocks hanging from one beam and saw their pendulums swinging in
-- exact opposition -- and if he disturbed one, within half an hour they
-- were swinging in opposition again. He called it "an odd kind of
-- sympathy". The beam, resting on two chairs, could move a little: each
-- pendulum's swing pushes it, and it pushes back on both.
--
-- Here two pendulum clocks hang from a beam on rollers, held by a spring,
-- with a little friction. They start swinging out of step (60 degrees
-- apart, then 300, then 120, each four minutes); within a minute they swing
-- in exact opposition, and the beam stops.
--
-- Why: swinging together, the pendulums push the beam to and fro, and the
-- beam's friction takes their energy (and the beam's pushing shifts their
-- timing); swinging in opposition, their pushes cancel, the beam stays
-- still, nothing is lost. Each clock's escapement keeps its own swing going,
-- so what's left is the opposed swing. (Bennett, Schatz, Rockwood and
-- Wiesenfeld, 2002.)
--
-- Theory: with the clocks stopped (no escapement, no friction), the two
-- pendulums and the beam have two ways of swinging: in opposition, at the
-- pendulum's own frequency (the beam still), and together, slower (the
-- beam swinging the other way). The console works those out from the
-- masses and the spring and compares the opposed one with what the clocks
-- settle into; and gives the clocks' phase difference as it goes to 180
-- degrees, and the beam's swing as it dies away.
--
-- THE CLOCKS: each pendulum a brass bob of 191 g on a light rod, 25 cm
-- from its pivot (a second's swing out and back); the escapement gives it a
-- small push each time it passes the bottom, keeping it swinging about 8
-- degrees; air friction on each slows it a little. The beam with the two
-- clock cases: 1.5 kg, on a spring (1.5 Hz alone), with friction (5 kg/s).
--
-- PHYSICS: Bullet: the beam a body that slides along x only; each pendulum
-- a body on a hinge to it; the spring, the beam's friction, the air, and
-- the escapements' pushes worked out before every step. 2400 physics
-- steps a second.
--
-- Keys
--   R   start them again, out of step
--   Z   slow motion (1/4) <-> real time
--
-- Units: centimetres, kilograms, seconds.
-- Headless testing: HC_SPEED, HC_STEPS, HC_PHASE (degrees), HC_LOG=file.csv.
--

local common = require "common"

local G = 981
local function envnum(n, d) return tonumber(os.getenv(n) or "") or d end
local function param(...) v:addParam(...) end
param("beam friction", envnum("HC_C", 5), 0, 20, 0.5, "the beam's friction, kg/s")
param("speed", envnum("HC_SPEED", 1), 0.05, 4, 0.05, "simulated seconds per real second (Z: 1/4 <-> 1)")
param("steps", envnum("HC_STEPS", 2400), 1200, 9600, 600, "physics steps per simulated second")

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
v:setSolverIterations(40)
v.showConstraints = false

local Q0 = btQuaternion(0, 0, 0, 1)
local function block(sx, sy, sz, x, y, z, col)
  local c = Cube(sx, sy, sz, 0)
  c.trans = btTransform(Q0, btVector3(x, y, z))
  c.col = col
  c.collides = false
  v:add(c)
  return c
end

-- ---------------------------------------------------------------------
-- the floor, two chairs' worth of stand, the beam, the clocks
-- ---------------------------------------------------------------------
local floor = Plane(0, 1, 0, 0, 300)
floor.col = "#3b3f45"
v:add(floor)
local WOOD, DARK, BRASS = "#6a3e1c", "#4e2e15", "#c8a04a"
local BEAM_Y = 95
for _, x in ipairs({ -45, 45 }) do
  block(4, BEAM_Y - 4, 4, x, (BEAM_Y - 4) / 2, -8, DARK)
  block(4, BEAM_Y - 4, 4, x, (BEAM_Y - 4) / 2, 8, DARK)
  block(6, 2, 20, x, BEAM_Y - 3, 0, DARK)
end

local LP = 25                               -- pivot to bob centre
local RBOB = 1.75
local MBOB = 0.0085 * 4 / 3 * math.pi * RBOB ^ 3
local M_BEAM = envnum("HC_M", 1.5)
local F_SPRING = envnum("HC_F", 1.5)      -- Hz, the beam alone on its spring
local K_SPRING = M_BEAM * (2 * math.pi * F_SPRING) ^ 2
local Q_AIR = 150                           -- each pendulum's quality factor, its air friction alone
local CLOCK_X = { -18, 18 }

-- the beam: slides along x only
local beamDraw = block(100, 4, 8, 0, BEAM_Y, 0, WOOD)
local beamHold = Sphere(0.05, 0)
local beamBody = btRigidBody(M_BEAM, btDefaultMotionState(btTransform(Q0, btVector3(0, BEAM_Y, 0))),
                             btBoxShape(btVector3(50, 2, 4)), btVector3(1, 1, 1))
beamHold.body = beamBody
beamHold.collides = false
v:add(beamHold)
beamBody:setActivationState(4)
beamBody:setDamping(0, 0)
beamBody:setFlags(1)
beamBody:setGravity(btVector3(0, 0, 0))
beamBody:setLinearFactor(btVector3(1, 0, 0))
beamBody:setAngularFactor(btVector3(0, 0, 0))
-- the spring: drawn as a coil of short pieces from the left post
local springParts = {}
for k = 1, 12 do springParts[k] = block(0.6, 0.6, 3, 0, 0, 0, "#9aa0a8") end

-- the pendulums: brass bob, light rod, as one body; frame at the centre
-- of mass, rod along its y, pivot above
local M_ROD = 0.0027 * math.pi * 0.2 ^ 2 * LP
local MP = MBOB + M_ROD
local D_CM = (MBOB * LP + M_ROD * LP / 2) / MP
local I_PIV = MBOB * (LP * LP + 0.4 * RBOB * RBOB) + M_ROD * LP * LP / 3
local I_CM = I_PIV - MP * D_CM * D_CM
local W0 = math.sqrt(MP * G * D_CM / I_PIV)
local AIR = I_PIV * W0 / Q_AIR              -- the air: a moment AIR * its turning rate (kg cm^2 / s)
local CLOCKS = {}
for i, cx in ipairs(CLOCK_X) do
  local c = { x = cx }
  -- the clock's case: hung on the beam (drawn; its mass is in the beam's)
  c.case = block(14, 34, 6, cx, BEAM_Y - 19, -5, "#3a2412")
  c.face = Cylinder(5, 0.4, 0)
  c.face.col = "#efe6cf"
  c.face.collides = false
  v:add(c.face)
  c.hand = block(0.4, 4, 0.2, cx, 0, 0, "#1a1a1a")
  local shape = btCompoundShape(true)
  shape:addChildShape(btTransform(Q0, btVector3(0, -(LP - D_CM), 0)), btSphereShape(RBOB))
  local h = Sphere(0.05, 0)
  local body = btRigidBody(MP, btDefaultMotionState(btTransform(Q0, btVector3(cx, BEAM_Y - 6 - D_CM, 0))), shape,
                           btVector3(I_CM, I_CM, I_CM))
  h.body = body
  h.collides = false
  v:add(h)
  body:setActivationState(4)
  body:setDamping(0, 0)
  c.holder, c.body = h, body
  c.bob = Sphere(RBOB, 0)
  c.bob.col = BRASS
  c.bob.collides = false
  v:add(c.bob)
  c.rod = Cylinder(0.2, LP - RBOB, 0)
  c.rod.col = "#b8a070"
  c.rod.collides = false
  v:add(c.rod)
  CLOCKS[i] = c
end
local PIVOT_DY = -6                         -- the pivots, below the beam's middle

-- ---------------------------------------------------------------------
-- the theory: the two ways of swinging, clocks stopped (small swings)
-- ---------------------------------------------------------------------
-- coordinates: the beam's x, each pendulum's angle. Kinetic energy
-- 1/2 (M + 2 m) x'^2 + sum m d x' th' + 1/2 I th'^2; potential 1/2 k x^2 +
-- 1/2 m g d th^2 each. In opposition the beam stays still: w^2 = m g d / I.
-- Together: th1 = th2 = th, and
--   (M + 2m) x'' + 2 m d th'' + k x = 0,   m d x'' + I th'' + m g d th = 0
local MT = M_BEAM + 2 * MP
local W_OPP = math.sqrt(MP * G * D_CM / I_PIV)
local W_TOG
do
  -- det [ k - (M+2m) w^2 , -2 m d w^2 ; -m d w^2 , m g d - I w^2 ] = 0, a
  -- quadratic in w^2: the root near the pendulum's
  local a = MT * I_PIV - 2 * (MP * D_CM) ^ 2
  local b = -(K_SPRING * I_PIV + MT * MP * G * D_CM)
  local c = K_SPRING * MP * G * D_CM
  local disc_ = math.sqrt(b * b - 4 * a * c)
  local r1, r2 = (-b - disc_) / (2 * a), (-b + disc_) / (2 * a)
  W_TOG = math.sqrt(math.min(r1, r2))
end

-- ---------------------------------------------------------------------
-- starting them
-- ---------------------------------------------------------------------
local t = 0
local STARTS
local AMP0 = math.rad(8)
-- the escapement's push each pass (a change of turning rate): what the air
-- takes in half a swing at AMP0, so it keeps swinging AMP0
local KICK = AIR * AMP0 * math.pi / (2 * I_PIV)
local function ellipticK(k)
  local a, b = 1, math.sqrt(1 - k * k)
  for _ = 1, 30 do a, b = (a + b) / 2, math.sqrt(a * b) end
  return math.pi / (2 * a)
end
local function angleOf(c)
  local Bm = c.body:getCenterOfMassTransform():getBasis()
  local col = Bm:getColumn(1)
  return math.atan2(-col.x, col.y)          -- (positive: the bob out toward +x)
end
local function start()
  holdStart()
  t = 0
  STARTS = (STARTS or 0) + 1
  local ph = math.rad(envnum("HC_PHASE", ({ 60, 300, 120 })[(STARTS - 1) % 3 + 1]))
  beamBody:setCenterOfMassTransform(btTransform(Q0, btVector3(0, BEAM_Y, 0)))
  beamBody:setLinearVelocity(btVector3(0, 0, 0))
  for i, c in ipairs(CLOCKS) do
    if c.hinge then v:removeConstraint(c.hinge) end
    -- each at amplitude AMP0, the second PH behind the first (a phase psi:
    -- angle AMP0 cos psi, turning rate -AMP0 W sin psi)
    local psi = (i == 1) and 0 or -ph
    local th = AMP0 * math.cos(psi)
    local thd = -AMP0 * W_OPP * math.sin(psi)
    local q = btQuaternion(btVector3(0, 0, 1), th)
    local px, py = c.x, BEAM_Y + PIVOT_DY
    -- the centre of mass D_CM below the pivot, turned th
    c.body:setCenterOfMassTransform(btTransform(q, btVector3(px + D_CM * math.sin(th), py - D_CM * math.cos(th), 0)))
    c.body:setAngularVelocity(btVector3(0, 0, thd))
    c.body:setLinearVelocity(btVector3(D_CM * thd * math.cos(th), D_CM * thd * math.sin(th), 0))
    c.hinge = btHingeConstraint(beamBody, c.body, btVector3(c.x, PIVOT_DY, 0), btVector3(0, D_CM, 0),
                                btVector3(0, 0, 1), btVector3(0, 0, 1))
    v:addConstraint(c.hinge)
    c.prev, c.passes, c.lastUp, c.periods = th, 0, nil, {}
  end
  print(string.format("\n--- the clocks started %.0f degrees out of step, swinging %.0f degrees ---", math.deg(ph), math.deg(AMP0)))
  print(string.format("  stopped, they'd swing in opposition at %.4f Hz (the beam still), or together at %.4f Hz (the beam swinging against them)",
                      W_OPP / (2 * math.pi), W_TOG / (2 * math.pi)))
  print(string.format("  in opposition, swinging %.0f degrees (a pendulum's slower, the further it swings: the elliptic integral): %.4f Hz",
                      math.deg(AMP0), W_OPP / (2 * math.pi) * math.pi / (2 * ellipticK(math.sin(AMP0 / 2)))))
  CLOCKS.report, CLOCKS.beamMax = 0, 0
end

-- ---------------------------------------------------------------------
-- before every step: the spring, the beam's friction, the air, the
-- escapements
-- ---------------------------------------------------------------------
v:preSim(function(N_)
  if holdPre() then return end
  local cb = v:getParam("beam friction")
  for k = 1, NSTEPS do
    local tt = t + (k - 1) * STEP
    local bx = getPosXYZ(beamHold)
    local bv = getVelXYZ(beamHold)
    -- the spring and friction on the beam (a change of its speed)
    setVelXYZ(beamHold, bv + (-K_SPRING * bx - cb * bv) * STEP / M_BEAM, 0, 0)
    for _, c in ipairs(CLOCKS) do
      local _, _, wz = getAngVelXYZ(c.holder)
      -- the air: a moment against the turning (as a change of turning rate)
      local dw = -AIR * wz / I_PIV * STEP
      -- the escapement: a push in the direction it's swinging, each time
      -- it passes the bottom
      local th = angleOf(c)
      if (c.prev < 0) ~= (th < 0) then
        dw = dw + (wz > 0 and KICK or -KICK)
        c.passes = c.passes + 1
        -- (an upward pass: its time, for its phase)
        if th > 0 then
          local frac = c.prev / (c.prev - th)
          local tc = tt - STEP + frac * STEP
          if c.lastUp then c.periods[#c.periods + 1] = tc - c.lastUp end
          c.lastUp = tc
          c.upTimes = c.upTimes or {}
          c.upTimes[#c.upTimes + 1] = tc
        end
      end
      c.prev = th
      if dw ~= 0 then
        -- (turning about the pivot: the centre of mass's speed changes too)
        local vx, vy, vz = getVelXYZ(c.holder)
        local s, co = math.sin(th), math.cos(th)
        setAngVelXYZ(c.holder, 0, 0, wz + dw)
        setVelXYZ(c.holder, vx + D_CM * dw * co, vy + D_CM * dw * s, vz)
      end
    end
    if k < NSTEPS then v:stepSimulation(STEP, 0, STEP) end
  end
end)

-- ---------------------------------------------------------------------
-- after every frame: draw; the phase difference
-- ---------------------------------------------------------------------
local LOGF = os.getenv("HC_LOG") and io.open(os.getenv("HC_LOG"), "w")
if LOGF then LOGF:write("t,theta1_deg,theta2_deg,beam_x\n") end
local function phaseDiff()
  -- from the last upward passes: how far behind the first the second is,
  -- as a fraction of the first's period
  local a, b = CLOCKS[1], CLOCKS[2]
  if not (a.upTimes and b.upTimes and #a.periods > 0) then return nil end
  local ta = a.upTimes[#a.upTimes]
  local tb = b.upTimes[#b.upTimes]
  local per = a.periods[#a.periods]
  local d = ((tb - ta) / per) % 1
  return d * 360
end
v:postSim(function(N_)
  if holdNow then return end
  t = t + FRAME_DT
  local bx = getPosXYZ(beamHold)
  beamDraw.trans = btTransform(Q0, btVector3(bx, BEAM_Y, 0))
  -- the spring, from the left post (x = -49) to the beam's end
  local x0, x1 = -54, bx - 50
  for k, p in ipairs(springParts) do
    local f = (k - 0.5) / #springParts
    p.trans = btTransform(btQuaternion(btVector3(1, 0, 0), (k % 2 == 0) and 0.5 or -0.5),
                          btVector3(x0 + (x1 - x0) * f, BEAM_Y, 0))
  end
  CLOCKS.beamMax = math.max(CLOCKS.beamMax, math.abs(bx))
  for _, c in ipairs(CLOCKS) do
    local cx = c.x + bx
    c.case.trans = btTransform(Q0, btVector3(cx, BEAM_Y - 19, -5))
    c.face.trans = btTransform(Q0, btVector3(cx, BEAM_Y - 9, -1.6))
    local th = angleOf(c)
    local px, py = cx, BEAM_Y + PIVOT_DY
    local s, co = math.sin(th), math.cos(th)
    c.bob.trans = btTransform(Q0, btVector3(px + LP * s, py - LP * co, 0))
    c.rod.trans = btTransform(btQuaternion(btVector3(0, 0, 1), th) * btQuaternion(btVector3(1, 0, 0), math.pi / 2),
                              btVector3(px + (LP - RBOB) / 2 * s, py - (LP - RBOB) / 2 * co, 0))
    -- the clock's hand: a turn a minute, by its own count of swings
    local ang = -c.passes / 2 / 60 * 2 * math.pi
    c.hand.trans = btTransform(btQuaternion(btVector3(0, 0, 1), ang),
                               btVector3(cx - 2 * math.sin(ang), BEAM_Y - 9 + 2 * math.cos(ang), -1.3))
  end
  -- every 15 s: the phase difference, the swings, the beam
  if t >= CLOCKS.report + 15 then
    CLOCKS.report = CLOCKS.report + 15
    local pd = phaseDiff()
    local a, b = CLOCKS[1], CLOCKS[2]
    local per = a.periods[#a.periods] or 0
    print(string.format("  t=%5.0f s  the clocks %5.1f degrees apart (in opposition: 180); swinging at %.4f Hz; the beam moving up to %.3f mm",
                        t, pd or 0, per > 0 and 1 / per or 0, CLOCKS.beamMax * 10))
    CLOCKS.beamMax = 0
  end
  if LOGF and N_ % 4 == 0 then
    LOGF:write(string.format("%.3f,%.3f,%.3f,%.5f\n", t, math.deg(angleOf(CLOCKS[1])), math.deg(angleOf(CLOCKS[2])), bx))
  end
  if t > 240 then start() end
end)

-- ---------------------------------------------------------------------
-- keys, help
-- ---------------------------------------------------------------------
common.setCamera(btVector3(0, 85, 125), btVector3(0, 75, 0))
v:addShortcut("R", function(N_) start() end)
v:addShortcut("Z", function(N_)
  local sp = v:getParam("speed") < 0.5 and 1 or 0.25
  v:addParam("speed", sp, 0.05, 4, 0.05, "simulated seconds per real second (Z: 1/4 <-> 1)")
  applyTiming()
end)
v:onParamChanged(function(N_, name, value)
  if name == "speed" or name == "steps" then applyTiming() end
end)
v:setHelpText(table.concat({
  "Huygens' clocks (Euler's Cabinet of Curiosities)",
  "",
  "Two pendulum clocks hang from one beam, which can move a",
  "little. Started out of step, within a minute or two they",
  "swing in exact opposition, and the beam stops: what Huygens",
  "saw in 1665, 'an odd kind of sympathy'.",
  "",
  "R   start them again, out of step",
  "Z   slow motion (1/4) <-> real time",
  "",
  "Sliders: beam friction, speed (up to 4x), steps.",
}, "\n"))

start()
