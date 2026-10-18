--
-- Kapitza's Pendulum -- Euler's Gallery
--
-- A pendulum stands upside down, balanced on its pivot, and doesn't fall:
-- the pivot is shaken up and down, a centimetre, forty times a second. Push
-- it over a little and it swings back up and rocks slowly about the
-- upright, as if gravity pointed up. (Stephenson saw it in 1908; Pyotr
-- Kapitza explained it in 1951.)
--
--   left    shaken 1.0 cm at 40 Hz: it stays up, rocking about the upright
--   right   shaken 0.6 cm at 40 Hz: not enough -- it falls over and swings
--           (then hangs, shaken, at the bottom)
--
-- Why: shaken fast, the pendulum quivers a little each shake. Leaning, the
-- pivot's push and the quiver line up so that, averaged over a shake, they
-- push it back toward upright -- more than gravity pulls it over, if the
-- shaking is hard enough.
--
-- Theory (Kapitza): averaged over the shaking, a pendulum of length l
-- (here the equivalent length I / (m d), I its moment of inertia about the
-- pivot and d its centre's distance from it) with its pivot shaken a cos(w
-- t) moves as if in a potential with the upright stable when
--     a^2 w^2 > 2 g l
-- and then it rocks about the upright at
--     W^2 = a^2 w^2 / (2 l^2) - g / l
-- The console gives the shaking against that limit, and the period it
-- rocks at against 2 pi / W, and against the period for the size of its
-- rocking (the averaged well is soft, so a bigger rock is slower).
--
-- THE PENDULUMS: a brass bob 3 cm across on a light rod, 20 cm from the
-- pivot to the bob's centre; the shaker at 40 Hz.
--
-- PHYSICS: Bullet: each pendulum a rigid body (bob and rod) on a hinge to
-- its pivot block, the block a heavy body moved exactly as the shaker moves
-- it, set before every step. 19200 physics steps a second (480 a shake):
-- the rocking's period moves with the step (1.115 s at 4800 a second,
-- 1.129 at 9600, 1.133 at 19200, 1.134 at 38400), and settles here.
--
-- Keys
--   R   stand them up again (tilted 8 degrees)
--   Z   slow motion (1/4) <-> real time
--
-- Units: centimetres, kilograms, seconds.
-- Headless testing: KP_SPEED, KP_STEPS, KP_TILT (degrees), KP_A1, KP_A2 (the
-- shaking, cm).
--

local common = require "common"

local G = 981
local function envnum(n, d) return tonumber(os.getenv(n) or "") or d end
local function param(...) v:addParam(...) end
param("left", envnum("KP_A1", 1.0), 0.1, 2, 0.05, "the left pivot's shaking, cm")
param("right", envnum("KP_A2", 0.6), 0.1, 2, 0.05, "the right pivot's shaking, cm")
param("speed", envnum("KP_SPEED", 1), 0.05, 2, 0.05, "simulated seconds per real second (Z: 1/4 <-> 1)")
param("steps", envnum("KP_STEPS", 19200), 2400, 19200, 1200, "physics steps per simulated second")

local STEP, NSTEPS, FRAME_DT = 1 / 19200, 320, 1 / 60
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
-- the table, the shakers, the pendulums
-- ---------------------------------------------------------------------
local TABLE_Y = 0
block(110, 3, 40, 0, TABLE_Y - 1.5, 0, "#7a4a24")
for _, x in ipairs({ -50, 50 }) do
  for _, z in ipairs({ -16, 16 }) do block(3, 72, 3, x, TABLE_Y - 3 - 36, z, "#4e2e15") end
end
local floor = Plane(0, 1, 0, TABLE_Y - 75, 300)
floor.col = "#3b3f45"
v:add(floor)

local F_HZ = 40
local OMEGA = 2 * math.pi * F_HZ
local PIVOT_Y = TABLE_Y + 30
local LB, RBOB, RROD = 20, 1.5, 0.25
local M_BOB = 0.0085 * 4 / 3 * math.pi * RBOB ^ 3      -- brass
local M_ROD = 0.0027 * math.pi * RROD ^ 2 * LB          -- aluminium
-- about the pivot (the body's centre of mass is where it is; its inertia
-- about that, and d, the centre's distance from the pivot)
local MP = M_BOB + M_ROD
local D_CM = (M_BOB * LB + M_ROD * LB / 2) / MP
local I_PIVOT = M_BOB * (LB ^ 2 + 0.4 * RBOB ^ 2) + M_ROD * LB ^ 2 / 3
local I_CM = I_PIVOT - MP * D_CM ^ 2
local L_EQ = I_PIVOT / (MP * D_CM)

local PENDS = {
  { name = "Left, shaken hard enough: it stays up", short = "Left", x = -24, param = "left" },
  { name = "Right, not shaken hard enough: it falls", short = "Right", x = 24, param = "right" },
}
local KEYS = {}
for _, p in ipairs(PENDS) do
  -- the shaker: a box on the table, a rod up to the pivot block
  block(10, 10, 10, p.x, TABLE_Y + 5, 0, "#3a3f46")
  local blk = Sphere(0.05, 0)
  local body = btRigidBody(1e4, btDefaultMotionState(btTransform(Q0, btVector3(p.x, PIVOT_Y, 0))),
                           btBoxShape(btVector3(1.2, 1.2, 1.2)), btVector3(1e6, 1e6, 1e6))
  blk.body = body
  blk.collides = false
  v:add(blk)
  body:setActivationState(4)
  body:setFlags(1)
  body:setGravity(btVector3(0, 0, 0))
  body:setLinearFactor(btVector3(0, 1, 0))
  body:setAngularFactor(btVector3(0, 0, 0))
  p.block, p.blockBody = blk, body
  p.blockDraw = block(2.4, 2.4, 2.4, p.x, PIVOT_Y, 0, "#8a8f96")
  p.shaft = block(0.8, PIVOT_Y - TABLE_Y - 10, 0.8, p.x, 0, 0, "#c8cdd4")
  -- the pendulum: the bob and the rod, one body (its frame at its centre
  -- of mass, the rod along its y)
  local shape = btCompoundShape(true)
  shape:addChildShape(btTransform(Q0, btVector3(0, LB - D_CM, 0)), btSphereShape(RBOB))
  local pb = Sphere(0.05, 0)
  local pbody = btRigidBody(MP, btDefaultMotionState(btTransform(Q0, btVector3(p.x, PIVOT_Y + D_CM, 0))), shape,
                            btVector3(I_CM, I_CM, I_CM))
  pb.body = pbody
  pb.collides = false
  v:add(pb)
  pbody:setActivationState(4)
  pbody:setDamping(0, 0)
  p.pend, p.pbody = pb, pbody
  local bob = Sphere(RBOB, 0)
  bob.col = "#c8a04a"
  bob.collides = false
  v:add(bob)
  p.bobDraw = bob
  local rod = Cylinder(RROD, LB - RBOB, 0)
  rod.col = "#d0d4da"
  rod.collides = false
  v:add(rod)
  p.rodDraw = rod
  KEYS[objectKey(bob)] = p
end

-- ---------------------------------------------------------------------
-- standing them up
-- ---------------------------------------------------------------------
local t = 0
local function upright(a) return a * a * OMEGA * OMEGA > 2 * G * L_EQ end
local function slowW(a) return math.sqrt(math.max(0, a * a * OMEGA * OMEGA / (2 * L_EQ * L_EQ) - G / L_EQ)) end
-- the rocking's period for its size A (radians): the averaged equation,
-- phi'' = (g/l) sin phi - K sin phi cos phi with K = a^2 w^2 / (2 l^2), is
-- to the next order phi'' = -W^2 phi + c phi^3, c = 2K/3 - g/(6 l): a soft
-- well, so a bigger rock is slower, by 1 + 3 c A^2 / (8 W^2) (Lindstedt)
local function slowPeriod(a, A)
  local W = slowW(a)
  local c = 2 / 3 * a * a * OMEGA * OMEGA / (2 * L_EQ * L_EQ) - G / (6 * L_EQ)
  return 2 * math.pi / W * (1 + 3 * c * A * A / (8 * W * W))
end
local function standUp()
  holdStart()
  t = 0
  local tilt = math.rad(envnum("KP_TILT", 8))
  print(string.format("\n--- stood up, tilted %.0f degrees; shaken at %d Hz ---", math.deg(tilt), F_HZ))
  print(string.format("  the pendulum: %.1f g, its centre %.2f cm from the pivot, equivalent length l = I/(m d) = %.3f cm;" ..
                      "\n  it stays up if a w > sqrt(2 g l) = %.1f cm/s, i.e. a > %.3f cm", MP * 1000, D_CM, L_EQ,
                      math.sqrt(2 * G * L_EQ), math.sqrt(2 * G * L_EQ) / OMEGA))
  for _, p in ipairs(PENDS) do
    if p.hinge then v:removeConstraint(p.hinge) end
    local a = v:getParam(p.param)
    p.a = a
    local tr = btTransform(Q0, btVector3(p.x, PIVOT_Y + a, 0))
    p.blockBody:setCenterOfMassTransform(tr)
    -- tilted toward +x (turned about -z)
    local q = btQuaternion(btVector3(0, 0, 1), -tilt)
    p.pbody:setCenterOfMassTransform(btTransform(q, btVector3(p.x + D_CM * math.sin(tilt), PIVOT_Y + a + D_CM * math.cos(tilt), 0)))
    p.pbody:setLinearVelocity(btVector3(0, 0, 0))
    p.pbody:setAngularVelocity(btVector3(0, 0, 0))
    p.hinge = btHingeConstraint(p.blockBody, p.pbody, btVector3(0, 0, 0), btVector3(0, -D_CM, 0),
                                btVector3(0, 0, 1), btVector3(0, 0, 1))
    v:addConstraint(p.hinge)
    p.cycSum, p.cycN, p.lastMean, p.cross, p.periods, p.fell, p.reported = 0, 0, nil, {}, {}, nil, false
    p.cyc = nil      -- (else the last run's unfinished shake takes this run's first angle)
    p.maxDev = 0
    if upright(a) then
      print(string.format("  %-6s shaken %.2f cm: a w = %.1f cm/s > %.1f -- it should stay up, rocking with a period of 2 pi / W = %.3f s",
                          p.short, a, a * OMEGA, math.sqrt(2 * G * L_EQ), 2 * math.pi / slowW(a)))
    else
      print(string.format("  %-6s shaken %.2f cm: a w = %.1f cm/s < %.1f -- it should fall", p.short, a, a * OMEGA,
                          math.sqrt(2 * G * L_EQ)))
    end
  end
end

-- the pendulum's angle from upright (positive leaning toward +x)
local function angleOf(p)
  local Bm = p.pbody:getCenterOfMassTransform():getBasis()
  local c = Bm:getColumn(1)
  return math.atan2(c.x, c.y)
end

-- ---------------------------------------------------------------------
-- before every step: the shakers; after each: the slow motion
-- ---------------------------------------------------------------------
local STEPS_PER_SHAKE
v:preSim(function(N_)
  if holdPre() then return end
  for k = 1, NSTEPS do
    local tt = t + (k - 1) * STEP
    for _, p in ipairs(PENDS) do
      local y = PIVOT_Y + p.a * math.cos(OMEGA * tt)
      p.blockBody:setCenterOfMassTransform(btTransform(Q0, btVector3(p.x, y, 0)))
      p.blockBody:setLinearVelocity(btVector3(0, -p.a * OMEGA * math.sin(OMEGA * tt), 0))
      -- the angle averaged over each shake (the slow motion)
      local th = angleOf(p)
      p.cycSum, p.cycN = p.cycSum + th, p.cycN + 1
      local cyc = math.floor(tt * F_HZ)
      if p.cyc and cyc ~= p.cyc then
        local mean = p.cycSum / p.cycN
        p.cycSum, p.cycN = 0, 0
        local tc = p.cyc / F_HZ + 0.5 / F_HZ
        if math.abs(mean) > math.pi / 2 and not p.fell then
          p.fell = tc
          print(string.format("  %-6s falls over at %.2f s", p.short, tc))
        end
        if not p.fell then
          p.maxDev = math.max(p.maxDev, math.abs(mean))
          -- upward crossings of upright: a period between each two
          if p.lastMean and p.lastMean < 0 and mean >= 0 then
            local tx = tc - (1 / F_HZ) * mean / (mean - p.lastMean)
            p.cross[#p.cross + 1] = tx
          end
        end
        p.lastMean = mean
      end
      p.cyc = cyc
    end
    if k < NSTEPS then v:stepSimulation(STEP, 0, STEP) end
  end
end)

v:postSim(function(N_)
  if holdNow then return end
  t = t + FRAME_DT
  for _, p in ipairs(PENDS) do
    local px, py = getPosXYZ(p.block)
    p.blockDraw.trans = btTransform(Q0, btVector3(px, py, 0))
    p.shaft.trans = btTransform(Q0, btVector3(px, (py - 1.2 + TABLE_Y + 10) / 2, 0))
    local th = angleOf(p)
    local sx, sy = math.sin(th), math.cos(th)
    p.bobDraw.trans = btTransform(Q0, btVector3(px + LB * sx, py + LB * sy, 0))
    p.rodDraw.trans = btTransform(btQuaternion(btVector3(0, 0, 1), -th) * btQuaternion(btVector3(1, 0, 0), math.pi / 2),
                                  btVector3(px + (LB - RBOB) / 2 * sx, py + (LB - RBOB) / 2 * sy, 0))
    if not p.reported and t > 8 then
      p.reported = true
      if p.fell then
        print(string.format("  %-6s fell over (%s)", p.short, upright(p.a) and "it shouldn't have" or "as it should"))
      elseif #p.cross >= 3 then
        local n = #p.cross - 1
        local per = (p.cross[#p.cross] - p.cross[1]) / n
        local W = slowW(p.a)
        local TA = slowPeriod(p.a, p.maxDev)
        print(string.format("  %-6s stays up, rocking up to %.1f degrees either side: a period of %.3f s over %d rocks (theory, 2 pi / W: %.3f s, %+.1f%%;" ..
                            " for its size: %.3f s, %+.1f%%)",
                            p.short, math.deg(p.maxDev), per, n, 2 * math.pi / W, (per * W / (2 * math.pi) - 1) * 100,
                            TA, (per / TA - 1) * 100))
      else
        print(string.format("  %-6s stays up (%s)", p.short, upright(p.a) and "as it should" or "it shouldn't have"))
      end
    end
  end
  if t > 15 then standUp() end
end)

-- ---------------------------------------------------------------------
-- keys, help
-- ---------------------------------------------------------------------
common.setCamera(btVector3(0, 42, 95), btVector3(0, 36, 0))
v:addShortcut("R", function(N_) standUp() end)
v:addShortcut("Z", function(N_)
  local sp = v:getParam("speed") < 0.5 and 1 or 0.25
  v:addParam("speed", sp, 0.05, 2, 0.05, "simulated seconds per real second (Z: 1/4 <-> 1)")
  applyTiming()
end)
v:onParamChanged(function(N_, name, value)
  if name == "speed" or name == "steps" then applyTiming() end
  if name == "left" or name == "right" then standUp() end
end)
v:setHelpText(table.concat({
  "Kapitza's pendulum (Euler's Gallery)",
  "",
  "An upside-down pendulum on a pivot shaken up and down 40",
  "times a second. Shaken hard enough, it stays up, rocking",
  "slowly about the upright: if a w > sqrt(2 g l).",
  "",
  "Left:  shaken 1.0 cm -- stays up",
  "Right: shaken 0.6 cm -- falls",
  "",
  "R   stand them up again",
  "Z   slow motion (1/4) <-> real time",
  "",
  "Sliders: left, right (the shaking, cm), speed, steps.",
}, "\n"))
if v.onHover then
  v:onHover(function(N_, obj, x, y, z)
    local p = KEYS[objectKey(obj)]
    if not p then return nil end
    return string.format("%s\nshaken %.2f cm at %d Hz; %.0f degrees from upright", p.name, p.a, F_HZ, math.deg(angleOf(p)))
  end)
end

standUp()
