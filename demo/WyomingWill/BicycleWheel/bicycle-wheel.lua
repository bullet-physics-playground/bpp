--
-- The Bicycle Wheel -- Euler's Cabinet of Curiosities
--
-- A figure sits on a swivel stool, its feet off the floor, holding a
-- bicycle wheel by the handles on its axle. The wheel spins at 3 turns a
-- second, axle upright. The stool is still.
-- Then the figure turns the wheel over -- and the stool starts to turn the
-- other way. Turn the wheel back and the stool stops again. Nothing has
-- pushed against the floor: the spin's angular momentum, which was
-- pointing up, now points down, and the figure and the stool together have
-- to take up the difference, twice the wheel's.
--
-- It turns the wheel over by itself every few seconds (A: on/off); F turns
-- it over now, L holds it level (half the difference: the stool turns half
-- as fast).
--
-- THE WHEEL: 66 cm across, 2.2 kg, its weight mostly in the rim and tyre
-- (moment of inertia about the axle 0.15 kg m^2); at 3 turns a second its
-- angular momentum is 2.83 kg m^2/s. Figure and stool: 2.5 kg m^2 about the
-- stool's axis; with the wheel, held 47 cm out, 3.14. So turned over, the
-- stool should turn at 2 x 2.83 / 3.14 = 1.80 rad/s, a turn in 3.5 s; the
-- console gives what it does and what it should, each time. (With no
-- friction the two agree to 4 figures, and the angular momentum about the
-- stool's axis stays within 0.03% of where it started.)
--
-- PHYSICS
--  * The stool's turning part and the figure are one rigid body, on a
--    hinge (a vertical axis) to the floor; a little friction in its
--    bearing.
--  * The wheel is one rigid body (axle, handles and wheel), on a hinge to
--    the figure's turning body: its axis points straight out in front of
--    the figure, through the wheel's centre -- the figure's arms, which turn
--    the wheel over about it and hold it every other way. A motor on that
--    hinge turns it over (in 1.2 s, smoothly); the arms are drawn to the
--    handles.
--  * The wheel's spin is carried as a number, an angular momentum inside
--    its body (a "gyrostat", as the gyroscopes are): the wheel is drawn
--    turning at the angle it's at. Bullet's gyroscopic term is off; the
--    body's gyroscopic torque, -w x (I w + h), is handed to Bullet as a
--    torque before every step (Adams-Bashforth, from the last two steps),
--    so the hinges answer it as they would any force. That's what turns
--    the stool: the hinge in the figure's arms pushing back.
--  * The wheel slows a little (0.02 turns/s each second, its bearings: what
--    they take goes through the axle into the figure).
--  * 1200 physics steps a second.
--
-- Keys
--   F   turn the wheel over (up <-> down)
--   L   hold it level, then F to go on
--   A   turning it over by itself every 6 s: on/off
--   R   start again (stool still, wheel spun up, axle up)
--   Z   slow motion (1/4) <-> real time
--
-- Units: centimetres, kilograms, seconds (so moments of inertia in kg cm^2:
-- 1 kg m^2 = 10000).
-- Headless testing: BW_SPIN (turns/s), BW_LOG=file.csv.
--

local common = require "common"

local DIR = "bicycle-wheel-meshes/"
for _, dir in ipairs({ DIR, "demo/WyomingWill/BicycleWheel/" .. DIR }) do
  local f = io.open(dir .. "figure.obj", "r")
  if f then f:close(); DIR = dir; break end
end

local G = 981
local SEAT_Y = 55                        -- the seat's top (as gen-meshes.py)
local WY, WD = 46, 47                    -- the wheel's centre: above the seat, out in front
local GRIP = 13                          -- the hands on the handles: this far out along the axle
local SHOULDER = { x = 19, y = 52, z = -1 }
local UA, FA = 29, 27                    -- upper arm, forearm (as gen-meshes.py)
-- the wheel
local MW = 2.2
local IW3 = 1500                         -- about the axle, kg cm^2 (0.15 kg m^2)
local IW1 = 800                          -- across it
local IW = { IW3, IW1, IW1 }
-- the figure and the stool's turning part
local MP = 75
local IP = 25000                         -- about the stool's axis (2.5 kg m^2)

local function envnum(n, d) return tonumber(os.getenv(n) or "") or d end
local function param(...) v:addParam(...) end
param("spin", envnum("BW_SPIN", 3), 0.5, 6, 0.5, "turns per second the wheel is spun up to (starts it again)")
param("turn over", envnum("BW_FLIP", 1.2), 0.3, 4, 0.1, "seconds the figure takes to turn the wheel over")
param("stool friction", envnum("BW_STOOLF", 0.02), 0, 0.5, 0.01, "friction in the stool's bearing (N m)")
param("wheel friction", envnum("BW_WHEELF", 0.02), 0, 0.5, 0.01, "the wheel's bearings: turns/s lost each second")
param("speed", 1, 0.05, 2, 0.05, "simulated seconds per real second (Z: 1/4 <-> 1)")
param("steps", 1200, 600, 4800, 300, "physics steps per simulated second")

local STEP, NSTEPS, FRAME_DT = 1 / 1200, 20, 1 / 60
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
v:setSolverIterations(30)
v.showConstraints = false

local Q0 = btQuaternion(0, 0, 0, 1)
local floor = Plane(0, 1, 0, 0, 400)
floor.col = "#6b4a2e"
v:add(floor)

-- ---------------------------------------------------------------------
-- the stool and the figure
-- ---------------------------------------------------------------------
local function visual(file, col)
  local m = Mesh(DIR .. file, 0, false)
  m.col = col
  m.collides = false
  v:add(m)
  return m
end
local WOOD, LAYFIG, BRASS, STEEL = "#5a3418", "#d2a874", "#b8932e", "#c9ccd0"
visual("stool-base.obj", WOOD).trans = btTransform(Q0, btVector3(0, 0, 0))
local anchor = Sphere(0.5, 0)
anchor.pos = btVector3(0, SEAT_Y, 0)
anchor.collides = false
v:add(anchor)

-- the turning body: drawn as the seat; the figure and the foot ring follow
local tt = Mesh(DIR .. "stool-seat.obj", 0, false)
tt.col = WOOD
local ttBody = btRigidBody(MP, btDefaultMotionState(btTransform(Q0, btVector3(0, SEAT_Y, 0))),
                           btSphereShape(5), btVector3(IP, IP, IP))
tt.body = ttBody
v:add(tt)
ttBody:setActivationState(4)
ttBody:setDamping(0, 0)
local figure = visual("figure.obj", LAYFIG)
local arms = {}
for _, sx in ipairs({ -1, 1 }) do
  arms[#arms + 1] = { sx = sx, upper = visual("upper-arm.obj", LAYFIG), fore = visual("forearm.obj", LAYFIG) }
end

-- the wheel: the axle and handles are its body; the turning wheel follows
local axle = Mesh(DIR .. "wheel-axle.obj", 0, false)
axle.col = STEEL
local wBody = btRigidBody(MW, btDefaultMotionState(btTransform(Q0, btVector3(0, SEAT_Y + WY, WD))),
                          btSphereShape(3), btVector3(IW[1], IW[2], IW[3]))
axle.body = wBody
v:add(axle)
wBody:setActivationState(4)
wBody:setDamping(0, 0)
wBody:setFlags(0)                         -- gyroscopic term: handed over as a torque, below
local wheelParts = { visual("wheel-turning.obj", STEEL), visual("wheel-tyre.obj", "#262626"),
                     visual("wheel-mark.obj", "#b0261f") }

local function basis(b)
  local B = b:getCenterOfMassTransform():getBasis()
  return { B:getColumn(0), B:getColumn(1), B:getColumn(2) }
end

-- ---------------------------------------------------------------------
-- the hinges: the stool's (vertical) and the arms' (out in front)
-- ---------------------------------------------------------------------
local stoolHinge, armHinge
local S = 0                               -- the wheel's spin, rad/s (relative to the axle)
local phi = 0                             -- the wheel's angle, for drawing
local prevT                               -- last step's gyroscopic torque
local flipAngle, lastRaw = 0, nil         -- the arm hinge's angle, unwrapped
local target, from, to, t0, dur = 0, 0, 0, 0, 1.2
local t, auto, nextAuto = 0, true, 2.0
local L0 = 0                              -- the angular momentum about the upright as it started turning the wheel
local EXTRA_TURN = -1                     -- the way round it's turned over (the top handle passes the figure's right)

local spunWith                            -- the spin it was last spun up with
local function restart()
  if stoolHinge then v:removeConstraint(stoolHinge) end
  if armHinge then v:removeConstraint(armHinge) end
  local tq = btTransform(Q0, btVector3(0, SEAT_Y, 0))
  tt.trans = tq
  ttBody:setCenterOfMassTransform(tq)
  ttBody:setLinearVelocity(btVector3(0, 0, 0))
  ttBody:setAngularVelocity(btVector3(0, 0, 0))
  -- the axle upright: the wheel's x turned onto y
  local wq = btTransform(btQuaternion(btVector3(0, 0, 1), math.pi / 2), btVector3(0, SEAT_Y + WY, WD))
  axle.trans = wq
  wBody:setCenterOfMassTransform(wq)
  wBody:setLinearVelocity(btVector3(0, 0, 0))
  wBody:setAngularVelocity(btVector3(0, 0, 0))
  stoolHinge = btHingeConstraint(ttBody, anchor.body, btVector3(0, 0, 0), btVector3(0, 0, 0),
                                 btVector3(0, 1, 0), btVector3(0, 1, 0))
  v:addConstraint(stoolHinge)
  armHinge = btHingeConstraint(ttBody, wBody, btVector3(0, WY, WD), btVector3(0, 0, 0),
                               btVector3(0, 0, 1), btVector3(0, 0, 1))
  v:addConstraint(armHinge)
  spunWith = v:getParam("spin")
  S = 2 * math.pi * v:getParam("spin")
  phi, prevT = 0, nil
  flipAngle, lastRaw = 0, nil
  target, from, to, t0 = 0, 0, 0, 0
  t, nextAuto = 0, 2.0
  L0 = IW3 * S
  print(string.format("\n--- the wheel spun up: %.1f turns/s, axle up; the stool still ---", v:getParam("spin")))
end

-- where the figure has the wheel: 0 up, 1 level, 2 down (half turns)
local pos = 0
local angMomUp
local function turnTo(p)
  if p == pos then return end
  from = target
  to = EXTRA_TURN * p * math.pi / 2
  t0, dur = t, v:getParam("turn over")
  pos = p
  L0 = angMomUp()           -- (what the turn must keep: the stool's bearing takes a little between turns)
end

-- ---------------------------------------------------------------------
-- before every physics step
-- ---------------------------------------------------------------------
local STOOLF, WHEELF = 0, 0
local function smooth(u) u = math.max(0, math.min(1, u)); return u * u * (3 - 2 * u) end
local function dsmooth(u) if u <= 0 or u >= 1 then return 0 end return 6 * u * (1 - u) end
local function prestep(h, tNow)
  -- the arms: the hinge's angle (unwrapped), driven along the smooth path
  local raw = armHinge:getHingeAngle()
  if lastRaw then
    local d = raw - lastRaw
    if d > math.pi then d = d - 2 * math.pi elseif d < -math.pi then d = d + 2 * math.pi end
    flipAngle = flipAngle + d
  end
  lastRaw = raw
  local u = (tNow - t0) / dur
  target = from + (to - from) * smooth(u)
  local vel = (to - from) * dsmooth(u) / dur + 40 * (target - flipAngle)
  armHinge:enableAngularMotor(true, vel, 2e6 * h)

  -- the wheel: its gyroscopic torque, the bearings
  local c = basis(wBody)
  local W = wBody:getAngularVelocity()
  local w1 = c[1].x * W.x + c[1].y * W.y + c[1].z * W.z
  local w2 = c[2].x * W.x + c[2].y * W.y + c[2].z * W.z
  local w3 = c[3].x * W.x + c[3].y * W.y + c[3].z * W.z
  local L1, L2, L3 = IW[1] * w1 + IW3 * S, IW[2] * w2, IW[3] * w3
  local t1, t2, t3 = -(w2 * L3 - w3 * L2), -(w3 * L1 - w1 * L3), -(w1 * L2 - w2 * L1)
  if WHEELF > 0 and S > 0 then
    local d = math.min(S, WHEELF * h)
    S = S - d
    t1 = t1 + IW3 * d / h                  -- (what the bearings take goes to the axle)
  end
  phi = (phi + S * h) % (2 * math.pi)
  local tx = c[1].x * t1 + c[2].x * t2 + c[3].x * t3
  local ty = c[1].y * t1 + c[2].y * t2 + c[3].y * t3
  local tz = c[1].z * t1 + c[2].z * t2 + c[3].z * t3
  local p = prevT
  if not p then p = { tx, ty, tz }; prevT = p end
  local ax, ay, az = 1.5 * tx - 0.5 * p[1], 1.5 * ty - 0.5 * p[2], 1.5 * tz - 0.5 * p[3]
  p[1], p[2], p[3] = tx, ty, tz
  wBody:applyTorque(btVector3(ax, ay, az))

  -- the stool's bearing
  if STOOLF > 0 then
    local wy = ttBody:getAngularVelocity().y
    ttBody:applyTorque(btVector3(0, -STOOLF * math.max(-1, math.min(1, wy / 0.01)), 0))
  end
end

v:preSim(function(N)
  local tNow = t
  for k = 1, NSTEPS do
    prestep(STEP, tNow)
    if k < NSTEPS then v:stepSimulation(STEP, 0, STEP) end
    tNow = tNow + STEP
  end
end)

-- ---------------------------------------------------------------------
-- after every frame: the figure, the arms and the wheel follow; what the
-- stool is doing
-- ---------------------------------------------------------------------
local function rotTo(dx, dy, dz)
  -- a rotation taking +x onto (dx, dy, dz)
  local n = math.sqrt(dx * dx + dy * dy + dz * dz)
  dx, dy, dz = dx / n, dy / n, dz / n
  local ay, az = -dz, dy
  local s = math.sqrt(ay * ay + az * az)
  if s < 1e-9 then return dx > 0 and Q0 or btQuaternion(btVector3(0, 1, 0), math.pi) end
  return btQuaternion(btVector3(0, ay / s, az / s), math.atan2(s, dx))
end
local function toWorld(c, o, x, y, z)
  return o[1] + c[1].x * x + c[2].x * y + c[3].x * z, o[2] + c[1].y * x + c[2].y * y + c[3].y * z,
         o[3] + c[1].z * x + c[2].z * y + c[3].z * z
end
local function placeArm(arm, sx, sy, sz, hx, hy, hz, ox, oy, oz)
  -- two links from the shoulder to the hand, the elbow out to the side (o)
  local dx, dy, dz = hx - sx, hy - sy, hz - sz
  local d = math.sqrt(dx * dx + dy * dy + dz * dz)
  d = math.min(d, UA + FA - 0.01)
  local ux, uy, uz = dx / d, dy / d, dz / d
  -- the elbow's distance along the line, and out from it
  local a = (UA * UA - FA * FA + d * d) / (2 * d)
  local e = math.sqrt(math.max(0, UA * UA - a * a))
  -- out: o made square to the line
  local k = ox * ux + oy * uy + oz * uz
  local px, py, pz = ox - k * ux, oy - k * uy, oz - k * uz
  local pn = math.sqrt(px * px + py * py + pz * pz)
  px, py, pz = px / pn, py / pn, pz / pn
  local ex, ey, ez = sx + a * ux + e * px, sy + a * uy + e * py, sz + a * uz + e * pz
  arm.upper.trans = btTransform(rotTo(ex - sx, ey - sy, ez - sz), btVector3(sx, sy, sz))
  arm.fore.trans = btTransform(rotTo(hx - ex, hy - ey, hz - ez), btVector3(ex, ey, ez))
end

local LOGF = os.getenv("BW_LOG") and io.open(os.getenv("BW_LOG"), "w")
if LOGF then LOGF:write("t,flip_deg,axle_up,stool_rad_s,theory_rad_s,spin_turns_s,L_up\n") end
local reported = true
local function stoolRate() return ttBody:getAngularVelocity().y end
local function axleUp() return basis(wBody)[1].y end
-- what the stool should be doing, from the angular momentum about the
-- upright when the wheel started turning over: L0 = (figure, stool and
-- wheel's moment of inertia) x rate + the spin's share, h (axle . up)
local function theory()
  local up = axleUp()
  local Iw = IW1 + (IW3 - IW1) * up * up
  local Itot = IP + MW * WD * WD + Iw
  return (L0 - IW3 * S * up) / Itot
end
function angMomUp()
  -- the whole thing's, about the stool's axis (for the log)
  local wy = ttBody:getAngularVelocity().y
  local c = basis(wBody)
  local W = wBody:getAngularVelocity()
  local w = { c[1].x * W.x + c[1].y * W.y + c[1].z * W.z, c[2].x * W.x + c[2].y * W.y + c[2].z * W.z,
              c[3].x * W.x + c[3].y * W.y + c[3].z * W.z }
  local Lb = { IW[1] * w[1] + IW3 * S, IW[2] * w[2], IW[3] * w[3] }
  local Lw = c[1].y * Lb[1] + c[2].y * Lb[2] + c[3].y * Lb[3]
  local x, _, z = getPosXYZ(axle)
  local V = wBody:getLinearVelocity()
  return IP * wy + Lw + MW * (z * V.x - x * V.z)
end

local restartIn                           -- frames until the spin slider's restart (see onParamChanged)
v:postSim(function(N)
  if restartIn then
    restartIn = restartIn - 1
    if restartIn <= 0 then restartIn = nil; restart(); pos = 0; auto = true; return end
  end
  t = t + FRAME_DT
  copyTrans(figure, tt)
  -- the wheel
  local tr = wBody:getCenterOfMassTransform()
  local x, y, z = getPosXYZ(axle)
  local wt = btTransform(tr:getRotation() * btQuaternion(btVector3(1, 0, 0), phi), btVector3(x, y, z))
  for _, m in ipairs(wheelParts) do m.trans = wt end
  -- the arms: shoulders on the figure, hands on the handles
  local ct = basis(ttBody)
  local ox, oy, oz = getPosXYZ(tt)
  local cw = basis(wBody)
  for _, arm in ipairs(arms) do
    local sx, sy, sz = toWorld(ct, { ox, oy, oz }, arm.sx * SHOULDER.x, SHOULDER.y, SHOULDER.z)
    -- the figure's -x hand on the axle's +x end, its +x hand on the -x end
    local hx, hy, hz = toWorld(cw, { x, y, z }, -arm.sx * GRIP, 0, 0)
    local px, py, pz = toWorld(ct, { 0, 0, 0 }, arm.sx, -0.5, -0.3)
    placeArm(arm, sx, sy, sz, hx, hy, hz, px, py, pz)
  end
  -- turning it over by itself
  if auto and t >= nextAuto and t >= t0 + dur then
    turnTo(pos == 0 and 2 or 0)
    nextAuto = t + dur + 6
    reported = false
  end
  if not reported and t >= t0 + dur + 0.5 then
    reported = true
    print(string.format("t=%5.1fs  wheel %s: the stool turning at %+.3f rad/s (%.2f turns/s); it should, by its angular momentum: %+.3f",
      t, pos == 0 and "axle up again" or pos == 1 and "held level" or "turned over", stoolRate(),
      math.abs(stoolRate()) / (2 * math.pi), theory()))
  end
  if LOGF and N % 4 == 0 then
    LOGF:write(string.format("%.4f,%.2f,%.4f,%.5f,%.5f,%.3f,%.1f\n", t, math.deg(flipAngle), axleUp(), stoolRate(), theory(),
                             S / (2 * math.pi), angMomUp()))
  end
  if LOGF and N % 60 == 0 then LOGF:flush() end
end)

-- ---------------------------------------------------------------------
-- keys, sliders, help, hover
-- ---------------------------------------------------------------------
v:addShortcut("F", function(N) auto = false; turnTo(pos == 0 and 2 or 0); reported = false end)
v:addShortcut("L", function(N) auto = false; turnTo(1); reported = false end)
v:addShortcut("A", function(N)
  auto = not auto
  nextAuto = t + 1
  print(auto and "turning it over by itself every 6 s" or "turning it over only on F")
end)
v:addShortcut("R", function(N) restart(); pos = 0; auto = true end)
v:addShortcut("Z", function(N)
  local sp = v:getParam("speed") < 0.5 and 1 or 0.25
  v:addParam("speed", sp, 0.05, 2, 0.05, "simulated seconds per real second (Z: 1/4 <-> 1)")
  applyTiming()
end)
v:onParamChanged(function(N, name, value)
  -- the spin: start again with it, once the slider has been still for half
  -- a second (and not if it's what the wheel has: bpp's Restart puts every
  -- slider back as it was)
  if name == "spin" and spunWith and math.abs(spunWith - value) > 1e-6 then restartIn = 30 end
  if name == "speed" or name == "steps" then applyTiming() end
  if name == "stool friction" then STOOLF = value * 1e4 end
  if name == "wheel friction" then WHEELF = value * 2 * math.pi end
end)
STOOLF = v:getParam("stool friction") * 1e4          -- N m to kg cm^2/s^2
WHEELF = v:getParam("wheel friction") * 2 * math.pi

v:setHelpText(table.concat({
  "The bicycle wheel (Euler's Cabinet of Curiosities)",
  "",
  "On a swivel stool, feet off the floor, a figure holds a",
  "spinning bicycle wheel, axle up. It turns the wheel over,",
  "and the stool starts to turn the other way; turned back,",
  "the stool stops. The spin's angular momentum was up and is",
  "now down: figure and stool take up the difference.",
  "",
  "F   turn the wheel over (up <-> down)",
  "L   hold it level (the stool turns half as fast)",
  "A   turning it over by itself every 6 s: on/off",
  "R   start again",
  "Z   slow motion (1/4) <-> real time",
  "",
  "Sliders: spin (turns/s; starts it again), turn over (seconds),",
  "stool friction, wheel friction, speed, steps.",
  "Rest the mouse on the wheel or the stool.",
}, "\n"))

if v.onHover then
  v:onHover(function(N, obj, hx, hy, hz)
    if objectKey(obj) == objectKey(axle) then
      return string.format("The wheel: %.2f turns/s, axle %s\n(%.0f degrees from up)", S / (2 * math.pi),
        axleUp() > 0.7 and "up" or axleUp() < -0.7 and "down" or "level", math.deg(math.acos(math.max(-1, math.min(1, axleUp())))))
    elseif objectKey(obj) == objectKey(tt) then
      return string.format("The stool: turning at %.2f rad/s (%.2f turns/s)\nby its angular momentum it should: %.2f rad/s",
        stoolRate(), math.abs(stoolRate()) / (2 * math.pi), theory())
    end
    return nil
  end)
end

common.setCamera(btVector3(envnum("BW_CX", 90), envnum("BW_CY", 160), envnum("BW_CZ", 270)),
                 btVector3(envnum("BW_LX", 0), envnum("BW_LY", 85), envnum("BW_LZ", 15)))
restart()
