--
-- Galileo's Ramp: the Rolling Race -- Euler's Cabinet of Curiosities
--
-- Five things roll down a ramp side by side, let go together: a wooden
-- ball, a small steel ball, a wooden disc, a brass hoop and a can of soup.
-- Which wins? Not the heaviest, nor the biggest. What matters is only how
-- much of each one's mass is out at its rim: rolling, it has to spin up as
-- well as speed up, and a hoop, all rim, spends half its energy spinning.
-- The soup wins: the can turns, but the soup inside hardly does, so nearly
-- all its energy goes into running down the ramp.
--
-- Theory: rolling without slipping down a slope theta, a body of mass m,
-- radius r and moment of inertia I = k m r^2 accelerates at
--     a = g sin(theta) / (1 + k)
-- whatever its mass and size: so it takes sqrt(2 d / a) to roll d. Ball k
-- = 2/5, disc 1/2, hoop 1; the can, its tin only (the soup doesn't turn),
-- k = 0.094. The two balls, one big and wooden, one small and steel, tie.
-- The console gives each one's time at the finish line against that.
--
-- THE RACERS: the wooden ball 5 cm across; the steel ball 2 cm; the wooden
-- disc 5 cm across, 2 cm thick; the brass hoop 5 cm across; the can 6.6 cm
-- across, 9 cm long (40 g of tin, 330 g of soup). The ramp: 1.2 m long,
-- at 5 degrees; the finish line 1 m down from the start.
--
-- PHYSICS: Bullet, its own contacts. The balls are spheres. The disc, hoop
-- and can roll in their lanes, turning about their axes only, so touching
-- the ramp along a line across it is the same as touching it at the line's
-- middle: each is a sphere of its radius to Bullet (Bullet's cylinders,
-- touching along a line, jitter and lose 2% of their speed), with its own
-- moment of inertia (the hoop's all at its rim, the can's its tin's).
-- Friction 0.8, so none slips. 2400 physics steps a second.
--
-- Keys
--   R   line them up and let them go again
--   Z   slow motion (1/4) <-> real time
--
-- Units: centimetres, kilograms, seconds.
-- Headless testing: GR_SPEED, GR_STEPS, GR_SLOPE (degrees), GR_LOG=file.csv.
--

local common = require "common"

local DIR = "galileo-ramp-meshes/"
for _, dir in ipairs({ DIR, "demo/WyomingWill/GalileoRamp/" .. DIR }) do
  local f = io.open(dir .. "hoop.obj", "r")
  if f then f:close(); DIR = dir; break end
end

local G = 981
local function envnum(n, d) return tonumber(os.getenv(n) or "") or d end
local function param(...) v:addParam(...) end
param("speed", envnum("GR_SPEED", 1), 0.05, 2, 0.05, "simulated seconds per real second (Z: 1/4 <-> 1)")
param("steps", envnum("GR_STEPS", 2400), 600, 9600, 600, "physics steps per simulated second")

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

local Q0 = btQuaternion(0, 0, 0, 1)
local function block(sx, sy, sz, x, y, z, col, q)
  local c = Cube(sx, sy, sz, 0)
  c.trans = btTransform(q or Q0, btVector3(x, y, z))
  c.col = col
  c.collides = false
  v:add(c)
  return c
end

-- ---------------------------------------------------------------------
-- the table and the ramp
-- ---------------------------------------------------------------------
local TABLE_Y = 0
block(150, 3, 70, 0, TABLE_Y - 1.5, 0, "#7a4a24")
for _, x in ipairs({ -70, 70 }) do
  for _, z in ipairs({ -30, 30 }) do block(3, 72, 3, x, TABLE_Y - 3 - 36, z, "#4e2e15") end
end
local floor = Plane(0, 1, 0, TABLE_Y - 75, 300)
floor.col = "#3b3f45"
v:add(floor)

local SLOPE = math.rad(envnum("GR_SLOPE", 5))
local RL, RW = 120, 62                     -- the ramp: length, width
local X0 = -60                             -- its top end
local Y0 = TABLE_Y + 2 + RL * math.sin(SLOPE)
local D_FINISH = 100
local NX, NY = math.sin(SLOPE), math.cos(SLOPE)          -- its surface's normal
local DX, DY = math.cos(SLOPE), -math.sin(SLOPE)         -- down it
local QR = btQuaternion(btVector3(0, 0, 1), -SLOPE)
do
  local th = 2
  local cx, cy = X0 + RL / 2 * DX, Y0 + RL / 2 * DY
  local ramp = Cube(RL, th, RW, 0)
  ramp.trans = btTransform(QR, btVector3(cx - NX * th / 2, cy - NY * th / 2, 0))
  ramp.col = "#c9a877"
  ramp.friction = 0.8
  v:add(ramp)
  block(3, Y0 - TABLE_Y, RW, X0 + 1.5, (Y0 + TABLE_Y) / 2 - 1, 0, "#6a4424")
  -- the lanes, painted; the start and finish lines
  for k = -2, 3 do
    local z = (k - 0.5) * 12
    block(RL - 2, 0.05, 0.3, cx, cy + 0.03, z, "#8a6a40", QR)
  end
  local fx, fy = X0 + (D_FINISH + 6) * DX, Y0 + (D_FINISH + 6) * DY
  block(1.0, 0.06, RW - 2, fx, fy + 0.03, 0, "#e8e0c8", QR)
end

-- ---------------------------------------------------------------------
-- the racers
-- ---------------------------------------------------------------------
local RHO_WOOD, RHO_STEEL, RHO_BRASS = 0.0007, 0.00785, 0.0085
local RACERS = {
  { name = "the wooden ball", short = "Ball", z = -24, kind = "sphere", r = 2.5, col = "#c98f52" },
  { name = "the small steel ball", short = "Steel", z = -12, kind = "sphere", r = 1.0, col = "#c9ced6" },
  { name = "the wooden disc", short = "Disc", z = 0, kind = "disc", r = 2.5, w = 2.0, col = "#d9b36c" },
  { name = "the brass hoop", short = "Hoop", z = 12, kind = "hoop", r = 2.5, w = 1.5, col = "#c8a04a" },
  { name = "the can of soup", short = "Soup", z = 24, kind = "can", r = 3.3, w = 9.0, col = "#b8463a" },
}
for _, rc in ipairs(RACERS) do
  if rc.kind == "sphere" then
    rc.m = (rc.r > 2 and RHO_WOOD or RHO_STEEL) * 4 / 3 * math.pi * rc.r ^ 3
    rc.k = 0.4
    rc.shape = btSphereShape(rc.r)
    rc.I = { rc.k * rc.m * rc.r ^ 2, rc.k * rc.m * rc.r ^ 2, rc.k * rc.m * rc.r ^ 2 }
  elseif rc.kind == "disc" then
    rc.m = RHO_WOOD * math.pi * rc.r ^ 2 * rc.w
    rc.k = 0.5
    rc.shape = btSphereShape(rc.r)
    local Ip = rc.m * (rc.r ^ 2 / 4 + rc.w ^ 2 / 12)
    rc.I = { Ip, Ip, rc.k * rc.m * rc.r ^ 2 }
  elseif rc.kind == "hoop" then
    -- a ring 3 mm thick (its rim: all its mass at the radius)
    local t_ = 0.3
    rc.m = RHO_BRASS * math.pi * (rc.r ^ 2 - (rc.r - t_) ^ 2) * rc.w
    local Iax = 0.5 * rc.m * (rc.r ^ 2 + (rc.r - t_) ^ 2)
    rc.k = Iax / (rc.m * rc.r ^ 2)
    rc.shape = btSphereShape(rc.r)
    local Ip = rc.m * ((rc.r ^ 2 + (rc.r - t_) ^ 2) / 4 + rc.w ^ 2 / 12)
    rc.I = { Ip, Ip, Iax }
  else
    -- the can: 40 g of tin (its side and ends), 330 g of soup; the soup
    -- doesn't turn with it, so only the tin counts for its turning
    local mt, ms = 0.040, 0.330
    rc.m = mt + ms
    local area_side, area_end = 2 * math.pi * rc.r * rc.w, math.pi * rc.r ^ 2
    local m_side = mt * area_side / (area_side + 2 * area_end)
    local m_ends = mt - m_side
    local Iax = m_side * rc.r ^ 2 + m_ends * rc.r ^ 2 / 2
    rc.k = Iax / (rc.m * rc.r ^ 2)
    rc.shape = btSphereShape(rc.r)
    local Ip = rc.m * (rc.r ^ 2 / 4 + rc.w ^ 2 / 12)
    rc.I = { Ip, Ip, Iax }
  end
  local mesh = rc.kind ~= "sphere" and (DIR .. rc.kind .. ".obj") or nil
  local o
  if mesh then
    o = Mesh(mesh, 0, false)
  else
    o = Sphere(rc.r, 0)
  end
  local body = btRigidBody(rc.m, btDefaultMotionState(btTransform(Q0, btVector3(0, 50, rc.z))), rc.shape,
                           btVector3(rc.I[1], rc.I[2], rc.I[3]))
  o.body = body
  o.col = rc.col
  v:add(o)
  body:setActivationState(4)
  body:setDamping(0, 0)
  body:setFriction(0.8)
  body:setRestitution(0)
  if rc.kind ~= "sphere" then
    -- (a disc, hoop or can rolls in its lane, turning about its axis only;
    -- it touches the ramp along a line across it, which, held so, is the
    -- same as touching it at the line's middle: its collision shape is a
    -- sphere of its radius. Bullet's cylinders, touching along a line,
    -- lose 2% of their speed to jitter.)
    body:setLinearFactor(btVector3(1, 1, 0))
    body:setAngularFactor(btVector3(0, 0, 1))
  end
  rc.o, rc.b = o, body
  -- a painted stripe, so its turning shows
  rc.stripe = Mesh(DIR .. (rc.kind == "sphere" and (rc.r > 2 and "ball-stripe.obj" or "steel-stripe.obj")
                           or (rc.kind .. "-stripe.obj")), 0, false)
  rc.stripe.col = rc.kind == "can" and "#f2e6c8" or "#3a2412"
  rc.stripe.collides = false
  v:add(rc.stripe)
end

-- ---------------------------------------------------------------------
-- the race
-- ---------------------------------------------------------------------
local t, finished
local function theoryTime(rc) return math.sqrt(2 * D_FINISH * (1 + rc.k) / (G * math.sin(SLOPE))) end
local function lineUp()
  holdStart()
  t, finished = 0, 0
  print(string.format("\n--- the race: %.0f cm down a ramp at %.0f degrees ---", D_FINISH, math.deg(SLOPE)))
  local order = {}
  for _, rc in ipairs(RACERS) do
    -- its centre a radius off the ramp, at the start line (6 cm down from the top)
    local cx = X0 + 6 * DX + NX * rc.r
    local cy = Y0 + 6 * DY + NY * rc.r + 0.001
    local tr = btTransform(QR, btVector3(cx, cy, rc.z))
    rc.b:setCenterOfMassTransform(tr)
    rc.o.trans = tr
    rc.b:setLinearVelocity(btVector3(0, 0, 0))
    rc.b:setAngularVelocity(btVector3(0, 0, 0))
    rc.b:clearForces()
    rc.x0, rc.y0, rc.done = cx, cy, nil
    order[#order + 1] = rc
  end
  table.sort(order, function(a, b) return a.k < b.k end)
  for _, rc in ipairs(order) do
    print(string.format("  %-6s %-22s %6.1f g, k = I/(m r^2) = %.3f: a = g sin(theta)/(1 + k) = %5.1f cm/s^2; theory %.3f s",
                        rc.short, rc.name, rc.m * 1000, rc.k, G * math.sin(SLOPE) / (1 + rc.k), theoryTime(rc)))
  end
end

local LOGF = os.getenv("GR_LOG") and io.open(os.getenv("GR_LOG"), "w")
if LOGF then LOGF:write("t,racer,distance\n") end
local afterAll
v:preSim(function(N_)
  if holdPre() then return end
  for k = 1, NSTEPS do
    if k > 1 then t = t + STEP end
    -- (the moment each crosses the line is caught to the physics step)
    for _, rc in ipairs(RACERS) do
      if not rc.done then
        local x, y = getPosXYZ(rc.o)
        local d = (x - rc.x0) * DX + (y - rc.y0) * DY
        if d >= D_FINISH then
          -- (between this step and the last, where it crossed)
          local vx, vy = getVelXYZ(rc.o)
          local sp = vx * DX + vy * DY
          rc.done = t - (d - D_FINISH) / sp
          rc.vEnd = sp
          finished = finished + 1
          local th = theoryTime(rc)
          print(string.format("  %-6s %d%s across the line at %.4f s (theory %.4f, %+.3f%%), at %.1f cm/s (theory %.1f)",
                              rc.short, finished, ({ "st", "nd", "rd", "th", "th" })[finished], rc.done, th,
                              (rc.done - th) / th * 100, sp, math.sqrt(2 * D_FINISH * G * math.sin(SLOPE) / (1 + rc.k))))
        end
      end
    end
    if k < NSTEPS then v:stepSimulation(STEP, 0, STEP) end
  end
  t = t + STEP
end)

v:postSim(function(N_)
  if holdNow then return end
  for i, rc in ipairs(RACERS) do
    copyTrans(rc.stripe, rc.o)
    if LOGF and N_ % 3 == 0 then
      local x, y = getPosXYZ(rc.o)
      LOGF:write(string.format("%.4f,%d,%.3f\n", t, i, (x - rc.x0) * DX + (y - rc.y0) * DY))
    end
  end
  if finished == #RACERS then
    afterAll = afterAll or t
    if t > afterAll + 3 then afterAll = nil; lineUp() end
  end
  if t > 20 then lineUp() end
end)

-- ---------------------------------------------------------------------
-- keys, help
-- ---------------------------------------------------------------------
common.setCamera(btVector3(-20, 55, 105), btVector3(0, 6, 0))
v:addShortcut("R", function(N_) afterAll = nil; lineUp() end)
v:addShortcut("Z", function(N_)
  local sp = v:getParam("speed") < 0.5 and 1 or 0.25
  v:addParam("speed", sp, 0.05, 2, 0.05, "simulated seconds per real second (Z: 1/4 <-> 1)")
  applyTiming()
end)
v:onParamChanged(function(N_, name, value)
  if name == "speed" or name == "steps" then applyTiming() end
end)
v:setHelpText(table.concat({
  "Galileo's ramp: the rolling race (Euler's Cabinet of Curiosities)",
  "",
  "A wooden ball, a small steel ball, a wooden disc, a brass hoop",
  "and a can of soup roll down a ramp together. What wins is",
  "what has least of its mass out at its rim: a = g sin/(1 + k),",
  "k = I/(m r^2). The soup wins (the soup doesn't turn); the two",
  "balls tie; the hoop comes last.",
  "",
  "R   line them up and let them go again",
  "Z   slow motion (1/4) <-> real time",
}, "\n"))
local KEYS = {}
if v.onHover then
  for _, rc in ipairs(RACERS) do KEYS[objectKey(rc.o)] = rc end
  v:onHover(function(N_, obj, x, y, z)
    local rc = KEYS[objectKey(obj)]
    if not rc then return nil end
    return string.format("%s, %.0f g\nk = I/(m r^2) = %.3f: down the ramp in %.3f s (theory)", rc.name, rc.m * 1000, rc.k,
                         theoryTime(rc))
  end)
end

lineUp()
