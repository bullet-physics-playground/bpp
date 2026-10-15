--
-- Newton's Cradle -- Euler's Cabinet of Curiosities
--
-- Five steel balls hang in a row, each on a V of two threads, just
-- touching. Lift one and let it go: it strikes the row and stops, and the
-- ball at the far end flies out; it swings back, strikes, and the first
-- flies out again. Lift two, and two fly out; three, and three.
--
-- Momentum and energy are both kept in a strike (nearly: steel isn't quite
-- perfectly elastic), and with identical balls the only way to keep both is
-- for as many balls to leave as arrived, at the speed they came. But that
-- argument assumes the strike is a series of separate two-ball collisions.
-- In a row of balls that touch, the push travels through them as a pulse,
-- squeezing each contact (Hertz's law: the push grows as the 3/2 power of
-- the squeeze), and the far ball doesn't get quite everything: the others
-- keep a little motion, and after many strikes the whole row is swinging
-- together. Leave a hair's gap between the balls (G) and each strike is a
-- clean series of two-ball collisions: one in, one out, almost exactly.
--
-- The console, for each strike: the balls' speeds before and after,
-- momentum (kept), energy (kept but for the damping in the contacts), and
-- how long since the last strike against the time a half swing takes at
-- the amplitude the balls swing out to -- exactly, for a ball that turns
-- with its threads (a physical pendulum), with the elliptic integral for
-- the amplitude.
--
-- THE CRADLE: steel balls 25 mm across, 64 g each, their centres 15 cm
-- below the threads' tops. Steel on steel: Hertz contacts (Young's modulus
-- 200 GPa, Poisson's ratio 0.3) with a little damping (a quarter of Hunt
-- and Crossley's for steel: two balls meeting at 63 cm/s part at 0.982 of
-- it; the damping slider sets it, 0 for none).
--
-- PHYSICS
--  * Each ball a rigid body on a hinge to the frame (its two threads: it
--    swings in the plane of the row, turning as it swings).
--  * The strikes: Bullet's contacts can't do them (a whole row of balls
--    touching at once). Before every physics step, any balls that touch or
--    will within the step are worked out here, each along its swing:
--    Hertz's push between neighbours, in steps of a quarter of a
--    microsecond (a strike lasts about a tenth of a millisecond), and the
--    balls' speeds and places handed back to Bullet, on their hinges.
--  * 2400 physics steps a second.
--  * Each strike clacks: the sound worked out from the same strike and the
--    air the jerked balls push (make-sounds.py, cradle-sounds/), louder
--    the faster the balls meet.
--
-- Keys
--   1 2 3 4   lift that many balls and let them go
--   G         the balls touching <-> a 0.1 mm gap between them
--   A         by itself, one ball, then two, then three: on/off
--   Z         slow motion (1/4) <-> real time
--
-- Units: centimetres, kilograms, seconds.
-- Headless testing: NC_SPEED, NC_STEPS, NC_LIFT (degrees), NC_GAP (cm), NC_DAMP,
-- NC_LOG=file.csv.
--

local common = require "common"

local G = 981
local function envnum(n, d) return tonumber(os.getenv(n) or "") or d end
local function param(...) v:addParam(...) end
param("lift", envnum("NC_LIFT", 30), 5, 60, 1, "degrees the lifted balls are pulled back")
param("damping", envnum("NC_DAMP", 0.25), 0, 2, 0.05, "damping in the contacts (1: Hunt-Crossley 0.12 s/m)")
param("speed", envnum("NC_SPEED", 1), 0.05, 2, 0.05, "simulated seconds per real second (Z: 1/4 <-> 1)")
param("steps", envnum("NC_STEPS", 2400), 1200, 9600, 600, "physics steps per simulated second")

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
-- the balls and the frame
-- ---------------------------------------------------------------------
local NB = 5
local RB = 1.25                            -- radius
local RHO = 0.00785                        -- steel, kg/cm^3
local MB = RHO * 4 / 3 * math.pi * RB ^ 3
local IB = 0.4 * MB * RB * RB
local LP = 15                              -- from the threads' tops to the balls' centres
local DV = 7                               -- the threads' tops: this far either side
local TABLE_Y = 0
local BASE_Y = TABLE_Y + 2
local CENTRE_Y = BASE_Y + 5 + RB           -- the balls' centres, hanging
local TOP_Y = CENTRE_Y + LP
local GAP = envnum("NC_GAP", 0)

-- Hertz: push = K squeeze^(3/2), two equal steel balls
local E_STAR = 200e9 / (2 * (1 - 0.3 ^ 2)) * 0.01     -- Pa = 0.01 kg/(cm s^2)
local K_H = 4 / 3 * E_STAR * math.sqrt(RB / 2)
local ALPHA0 = 0.0012                     -- Hunt-Crossley damping, s/cm (restitution about 1 - 2/3 alpha v)
local ALPHA = ALPHA0

-- two balls meeting head on at speed u: how long they touch, and the
-- speed they part at over the speed they met at
local function twoBalls(u, alpha)
  local x, w1, w2 = 0, u, 0                -- (x: the squeeze)
  local dt = 0.0625e-6
  local tt = 0
  local function f(sq, rate) local r = K_H * sq * math.sqrt(sq) * (1 + 1.5 * alpha * rate); return r > 0 and r or 0 end
  repeat
    local fr = f(x, w1 - w2)
    w1, w2 = w1 - fr / MB * dt, w2 + fr / MB * dt
    x = x + (w1 - w2) * dt
    tt = tt + dt
  until x < 0 or tt > 0.01
  return tt, (w2 - w1) / u
end
local function hertzTime(u)
  -- Hertz: 2.87 (m^2 / (R E*^2 u))^(1/5), m and R the reduced mass and radius
  return 2.87 * ((MB / 2) ^ 2 / ((RB / 2) * E_STAR ^ 2 * u)) ^ 0.2
end


-- the frame: a wooden base, two brass uprights each end, rods along the top
block(36, 2, 22, 0, TABLE_Y + 1, 0, "#4e2e15")
local BRASS = "#c8a04a"
for _, x in ipairs({ -15, 15 }) do
  for _, z in ipairs({ -DV, DV }) do
    local c = Cylinder(0.4, TOP_Y - BASE_Y, 0)
    c.trans = btTransform(btQuaternion(btVector3(1, 0, 0), math.pi / 2), btVector3(x, (TOP_Y + BASE_Y) / 2, z))
    c.col = BRASS
    c.collides = false
    v:add(c)
  end
end
for _, z in ipairs({ -DV, DV }) do
  local c = Cylinder(0.4, 30.8, 0)
  c.trans = btTransform(btQuaternion(btVector3(0, 1, 0), math.pi / 2), btVector3(0, TOP_Y, z))
  c.col = BRASS
  c.collides = false
  v:add(c)
end
local floor = Plane(0, 1, 0, TABLE_Y - 75, 300)
floor.col = "#3b3f45"
v:add(floor)
block(80, 3, 44, 0, TABLE_Y - 1.5, 0, "#7a4a24")
for _, x in ipairs({ -36, 36 }) do
  for _, z in ipairs({ -18, 18 }) do block(3, 72, 3, x, TABLE_Y - 3 - 36, z, "#4e2e15") end
end

local balls = {}
local THREAD = "#e8e0c8"
-- (each thread: from its rod to a point on the ball's top half, 0.6 of the
-- radius up and 4 mm off the middle; it turns with the ball, so its length
-- stays the same)
local THREAD_LEN = math.sqrt((LP - 0.6 * RB) ^ 2 + (DV - 0.4) ^ 2)
for i = 1, NB do
  local b = {}
  b.anchor = Sphere(0.05, 0)
  b.anchor.collides = false
  b.anchor.col = BRASS
  v:add(b.anchor)
  local s = Sphere(RB, MB)
  s.col = "#dde2ea"
  s.collides = false                       -- (the strikes are worked out below)
  v:add(s)
  s.body:setActivationState(4)
  s.body:setDamping(0, 0)
  b.s = s
  b.threads = {}
  for k = 1, 2 do
    local c = Cylinder(0.03, THREAD_LEN, 0)
    c.col = THREAD
    c.collides = false
    v:add(c)
    b.threads[k] = c
  end
  balls[i] = b
end

-- ---------------------------------------------------------------------
-- lifting and letting go
-- ---------------------------------------------------------------------
local t, lifted = 0, 1
local function ballX(i) return (i - (NB + 1) / 2) * (2 * RB + GAP) end
local strikes, lastStrike, event, quietSteps
local function lift(n)
  holdStart()
  t = 0
  lifted = n
  local th = math.rad(v:getParam("lift"))
  for i, b in ipairs(balls) do
    if b.hinge then v:removeConstraint(b.hinge) end
    local ax = ballX(i)
    b.anchor.pos = btVector3(ax, TOP_Y, 0)
    local a = (i <= n) and -th or 0
    local q = btQuaternion(btVector3(0, 0, 1), a)
    local tr = btTransform(q, btVector3(ax + LP * math.sin(a), TOP_Y - LP * math.cos(a), 0))
    b.s.trans = tr
    b.s.body:setCenterOfMassTransform(tr)
    b.s.body:setLinearVelocity(btVector3(0, 0, 0))
    b.s.body:setAngularVelocity(btVector3(0, 0, 0))
    b.hinge = btHingeConstraint(b.anchor.body, b.s.body, btVector3(0, 0, 0), btVector3(0, LP, 0),
                                btVector3(0, 0, 1), btVector3(0, 0, 1))
    v:addConstraint(b.hinge)
    b.ax = ax
  end
  strikes, lastStrike, event, quietSteps = 0, nil, nil, 0
  print(string.format("\n--- %d ball%s lifted %d degrees and let go; the balls %s ---", n, n > 1 and "s" or "",
                      v:getParam("lift"), GAP > 0 and string.format("%.2f mm apart", GAP * 10) or "touching"))
  local u = math.sqrt(2 * G * LP * (1 - math.cos(th)) / (1 + 0.4 * RB * RB / (LP * LP)))
  local tc = twoBalls(u, 0)
  local _, e = twoBalls(u, ALPHA)
  print(string.format("    two balls meeting at %.1f cm/s: they touch for %.1f microseconds (Hertz: %.1f); they part at %.3f of it",
                      u, tc * 1e6, hertzTime(u) * 1e6, e))
end

-- ---------------------------------------------------------------------
-- before every physics step: the strikes
-- ---------------------------------------------------------------------
local X, VX, U, W, D0 = {}, {}, {}, {}, {}

-- ---------------------------------------------------------------------
-- the clack: worked out from the same strike, and the air a jerked ball
-- pushes (make-sounds.py): one sound for 1 to 4 balls coming in at each of
-- 10, 20, 35, 60 and 100 cm/s, all to one scale; a strike plays the one
-- at or just above its speed, softer as the pressure goes, speed^1.48
-- ---------------------------------------------------------------------
local SND_DIR = "cradle-sounds/"
for _, d in ipairs({ "", "demo/WyomingWill/NewtonsCradle/" }) do
  local f = io.open(d .. SND_DIR .. "clack-n1-v60.wav", "r")
  if f then f:close(); SND_DIR = d .. SND_DIR; break end
end
local SND_SPEEDS = { 10, 20, 35, 60, 100 }
local SND = {}
if v.loadSound and v.playSound then
  for n = 1, 4 do
    SND[n] = {}
    for _, u in ipairs(SND_SPEEDS) do
      SND[n][u] = v:loadSound(string.format("%sclack-n%d-v%d.wav", SND_DIR, n, u))
    end
  end
end
-- at a strike's start: how fast the balls meet, and how many come in together
local function clack()
  if not SND[1] then return end
  local j, c = nil, 0
  for i = 1, NB - 1 do
    local ci = VX[i] - VX[i + 1]
    if ci > c then j, c = i, ci end
  end
  if not j or c < 2 then return end                -- (too soft to hear)
  local n, side, step = 1, j, -1
  if math.abs(VX[j + 1]) > math.abs(VX[j]) then side, step = j + 1, 1 end
  local k = side + step
  while k >= 1 and k <= NB and math.abs(VX[k] - VX[side]) < 0.2 * c do n, k = n + 1, k + step end
  n = math.min(n, 4)
  local ub = SND_SPEEDS[#SND_SPEEDS]            -- (the file at or just above its speed, played softer)
  for i = #SND_SPEEDS, 1, -1 do if SND_SPEEDS[i] >= c then ub = SND_SPEEDS[i] end end
  local id = SND[n][ub]
  if id and id >= 0 then
    pcall(function() v:playSound(id, math.min(1, (c / ub) ^ 1.48)) end)
  end
end
local SUB = 0.25e-6
-- (each ball is worked out along its own swing, on its hinge: a push along
-- the line between two balls moves each along its swing by the part of it
-- that lies along the swing, and a ball's inertia along its swing is
-- m (1 + 2/5 r^2/L^2), since it turns with its threads)
local MS = MB * (1 + 0.4 * RB * RB / (LP * LP))
local A, CL, CR = {}, {}, {}
local function strike(h)
  -- where they are along their swings, and how fast
  for i, b in ipairs(balls) do
    local x, y = getPosXYZ(b.s)
    local vx, vy = getVelXYZ(b.s)
    local a = math.atan2(x - b.ax, TOP_Y - y)
    X[i], b.y, A[i] = x, y, a
    VX[i] = vx * math.cos(a) + vy * math.sin(a)
  end
  -- each contact: the gap, and how each ball's swing moves along the line between them
  local touching = false
  for i = 1, NB - 1 do
    local dx, dy = X[i + 1] - X[i], balls[i + 1].y - balls[i].y
    local l = math.sqrt(dx * dx + dy * dy)
    local nx, ny = dx / l, dy / l
    D0[i] = l - 2 * RB
    CL[i] = math.cos(A[i]) * nx + math.sin(A[i]) * ny
    CR[i] = math.cos(A[i + 1]) * nx + math.sin(A[i + 1]) * ny
    -- (pressed now, or will be within the step: a strike can last longer
    -- than a step, and a contact still pressed but opening must be worked
    -- out to the end, or what it holds is lost)
    if math.min(D0[i], D0[i] + (CR[i] * VX[i + 1] - CL[i] * VX[i]) * h) < -1e-7 then touching = true end
  end
  if not touching then return false end
  -- the row, over this step: Hertz between neighbours
  for i = 1, NB do U[i], W[i] = 0, VX[i] end
  local n = math.ceil(h / SUB)
  local dt = h / n
  local F = {}
  local function forces()
    for i = 1, NB - 1 do
      local sq = -(D0[i] + CR[i] * U[i + 1] - CL[i] * U[i])
      if sq > 0 then
        local rate = CL[i] * W[i] - CR[i] * W[i + 1]      -- how fast it's squeezing
        local f = K_H * sq * math.sqrt(sq) * (1 + 1.5 * ALPHA * rate)
        F[i] = f > 0 and f or 0
      else
        F[i] = 0
      end
    end
  end
  local function accel(i)
    return ((i > 1 and F[i - 1] * CR[i - 1] or 0) - (i < NB and F[i] * CL[i] or 0)) / MS
  end
  forces()
  for _ = 1, n do
    -- velocity Verlet
    for i = 1, NB do
      W[i] = W[i] + 0.5 * dt * accel(i)
      U[i] = U[i] + dt * W[i]
    end
    forces()
    for i = 1, NB do
      W[i] = W[i] + 0.5 * dt * accel(i)
    end
  end
  -- hand them back: each ball on its swing, at the new speed, placed so
  -- that Bullet's step (at that speed) ends where the row had it, and
  -- turned with its threads, just as the hinge has it (so the hinge has
  -- nothing to put right, and a squeeze carried into the next step is kept)
  for i, b in ipairs(balls) do
    if W[i] ~= VX[i] then
      local a = A[i] + (U[i] - W[i] * h) / LP
      local c, sn = math.cos(a), math.sin(a)
      local body = b.s.body
      body:setCenterOfMassTransform(btTransform(btQuaternion(btVector3(0, 0, 1), a),
                                                btVector3(b.ax + LP * sn, TOP_Y - LP * c, 0)))
      body:setLinearVelocity(btVector3(W[i] * c, W[i] * sn, 0))
      body:setAngularVelocity(btVector3(0, 0, W[i] / LP))
    end
  end
  return true
end

local function snapshot()
  local s = { v = {}, p = 0, e = 0 }
  for i, b in ipairs(balls) do
    local vx, vy, vz = getVelXYZ(b.s)
    s.v[i] = vx
    s.p = s.p + MB * vx
    s.e = s.e + 0.5 * MB * (vx * vx + vy * vy + vz * vz)
    local _, _, wz = getAngVelXYZ(b.s)
    s.e = s.e + 0.5 * IB * wz * wz
  end
  return s
end

-- the time a half swing takes, out and back, at amplitude th: a ball on its
-- hinge (a physical pendulum: moment of inertia m (L^2 + 2/5 r^2))
local function ellipticK(k)
  local a, b = 1, math.sqrt(1 - k * k)
  for _ = 1, 30 do a, b = (a + b) / 2, math.sqrt(a * b) end
  return math.pi / (2 * a)
end
local function halfSwing(th)
  local leq = (LP * LP + 0.4 * RB * RB) / LP
  return 2 * math.sqrt(leq / G) * ellipticK(math.sin(th / 2))
end

local function angleOf(b)
  local x, y = getPosXYZ(b.s)
  return math.atan2(x - b.ax, TOP_Y - y)
end

v:preSim(function(N_)
  if holdPre() then return end
  for k = 1, NSTEPS do
    local before = (not event) and snapshot() or nil
    local hit = strike(STEP)
    if hit then
      if not event then
        event = { t = t + (k - 1) * STEP, before = before }
        clack()
      end
      quietSteps = 0
    elseif event then
      quietSteps = quietSteps + 1
      -- (what came out: just after the last contact)
      if quietSteps == 1 then event.after, event.t1 = snapshot(), t + (k - 1) * STEP end
      if quietSteps >= 24 then
        -- the strike's over (no contact for 10 ms)
        local after = event.after
        local b4 = event.before
        local big = 0
        for i = 1, NB do big = math.max(big, math.abs(after.v[i] - b4.v[i])) end
        -- (the little knocks between balls left barely moving aren't counted)
        if big > 3 then
          strikes = strikes + 1
          local vin, vout = {}, {}
          for i = 1, NB do
            vin[i] = string.format("%6.1f", b4.v[i])
            vout[i] = string.format("%6.1f", after.v[i])
          end
          local line = string.format("  strike %2d at %6.3f s: speeds before %s\n                               after  %s cm/s;" ..
                                     " energy %.1f%%; momentum along the row %.2f%% off (over %.1f ms of strikes, gravity and the threads act too)",
                                     strikes, event.t, table.concat(vin, " "), table.concat(vout, " "),
                                     after.e / b4.e * 100, math.abs(after.p - b4.p) / math.abs(b4.p) * 100,
                                     (event.t1 - event.t) * 1000)
          if strikes == 1 then
            local th = math.rad(v:getParam("lift"))
            line = line .. string.format("\n                    %.4f s after letting go; a quarter swing from %.0f degrees takes %.4f s",
                                         event.t, math.deg(th), halfSwing(th) / 2)
          end
          if strikes <= 4 or strikes % 10 == 0 then print(line) end
        end
        event = nil
      end
    end
    if k < NSTEPS then v:stepSimulation(STEP, 0, STEP) end
  end
end)

-- ---------------------------------------------------------------------
-- after every frame: the threads; the amplitude of the swing
-- ---------------------------------------------------------------------
local function setThread(c, x0, y0, z0, x1, y1, z1)
  local dx, dy, dz = x1 - x0, y1 - y0, z1 - z0
  local len = math.sqrt(dx * dx + dy * dy + dz * dz)
  local ux, uy, uz = dx / len, dy / len, dz / len
  local ax, ay = -uy, ux
  local al = math.sqrt(ax * ax + ay * ay)
  local q = al > 1e-9 and btQuaternion(btVector3(ax / al, ay / al, 0), math.acos(uz)) or Q0
  c.trans = btTransform(q, btVector3((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2))
end
local auto, nextAuto = true, 15
local LOGF = os.getenv("NC_LOG") and io.open(os.getenv("NC_LOG"), "w")
if LOGF then LOGF:write("t,ball1_x,ball5_x,ball1_vx,ball5_vx\n") end
v:postSim(function(N_)
  if holdNow then return end
  t = t + FRAME_DT
  for i, b in ipairs(balls) do
    local x, y, z = getPosXYZ(b.s)
    -- each thread from its top (on a rod) to the ball's top, in the plane
    -- of the swing turned out to the rod
    local a = angleOf(b)
    for k, side in ipairs({ -1, 1 }) do
      setThread(b.threads[k], b.ax, TOP_Y, side * DV, x - RB * 0.6 * math.sin(a), y + RB * 0.6 * math.cos(a), side * 0.4)
    end
    -- the swing's amplitude since the last strike
    if lastStrike and math.abs(a) > (lastStrike.amp or 0) then lastStrike.amp = math.abs(a) end
  end
  if LOGF then
    local x1, _, _ = getPosXYZ(balls[1].s)
    local x5, _, _ = getPosXYZ(balls[NB].s)
    LOGF:write(string.format("%.4f,%.4f,%.4f,%.3f,%.3f\n", t, x1, x5, (getVelXYZ(balls[1].s)), (getVelXYZ(balls[NB].s))))
  end
  if auto and t >= nextAuto then
    lift(lifted % 3 + 1)
    nextAuto = 15
  end
end)

-- ---------------------------------------------------------------------
-- keys, sliders, help
-- ---------------------------------------------------------------------
common.setCamera(btVector3(3, 24, 46), btVector3(0, 12, 0))
for n = 1, 4 do
  v:addShortcut(tostring(n), function(N_) auto = false; lift(n) end)
end
v:addShortcut("A", function(N_)
  auto = not auto
  print(auto and "  (by itself again: one, two, three balls)" or "  (by itself: off)")
end)
v:addShortcut("G", function(N_)
  GAP = GAP > 0 and 0 or 0.01
  lift(lifted)
end)
v:addShortcut("Z", function(N_)
  local sp = v:getParam("speed") < 0.5 and 1 or 0.25
  v:addParam("speed", sp, 0.05, 2, 0.05, "simulated seconds per real second (Z: 1/4 <-> 1)")
  applyTiming()
end)
v:onParamChanged(function(N_, name, value)
  if name == "speed" or name == "steps" then applyTiming() end
  if name == "damping" then ALPHA = ALPHA0 * value end
end)
ALPHA = ALPHA0 * v:getParam("damping")
v:setHelpText(table.concat({
  "Newton's cradle (Euler's Cabinet of Curiosities)",
  "",
  "Lift one ball and let go: one flies out at the far end.",
  "Two, and two; three, and three. Touching balls pass the",
  "push along as a pulse, and the far ball doesn't get quite",
  "all of it; with a hair's gap (G) it's almost exact.",
  "",
  "1 2 3 4   lift that many balls and let go",
  "G         touching <-> a 0.1 mm gap",
  "A         by itself (one, two, three): on/off",
  "Z         slow motion (1/4) <-> real time",
  "",
  "Sliders: lift (degrees), damping, speed, steps.",
}, "\n"))

lift(1)
