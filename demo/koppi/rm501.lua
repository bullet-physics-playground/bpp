--
-- rm501.lua - Mitsubishi RM-501 Movemaster II robot arm    (WIP)
--
-- A 5-axis educational robot (waist, shoulder, elbow, wrist pitch, wrist
-- roll). The arm is a real rigid-body chain: six bodies joined by five
-- btHingeConstraint revolute joints, each driven by its angular motor.
--
-- Motion is planned by the trajectory generator ported from rm501/trajgen.c
-- (see demo/module/trajgen.lua): the planner sweeps the tool tip along
-- straight cartesian lines - trapezoidal velocity profile, cubic per-joint
-- interpolation, segment blending - between random reachable points in the
-- workspace. The RM-501 forward/inverse kinematics below are wired in as the
-- planner's kinematics hook, so every tick the planner emits the five joint
-- angles the hinge servos chase.
--
-- Usage: bpp -f demo/koppi/rm501.lua
--

local common  = require "common"
local trajgen = require "trajgen"

-- ---------------------------------------------------------------------------
-- RM-501 geometry (Denavit-Hartenberg parameters, same values as rm501.c)
-- ---------------------------------------------------------------------------

local D1, D5, A2, A3 = 2.3, 1.3, 2.2, 1.6   -- base height, tool, upper arm, forearm

-- Joint software limits in degrees: waist, shoulder, elbow, wrist pitch, roll
local LIMIT = {
  { -120, 180 },
  {  -30, 100 },
  { -100,   0 },
  {  -15, 175 },
  { -360, 360 },
}

local rad = math.rad
local deg = math.deg
local sin, cos, sqrt, atan2 = math.sin, math.cos, math.sqrt, math.atan2

local function clampd(x, lo, hi) return x < lo and lo or (x > hi and hi or x) end

-- ---------------------------------------------------------------------------
-- Kinematics (ported from rm501.c kins_fwd / kins_inv)
--
-- Joint angles are in degrees. theta1 = waist (about world +Y); theta2..4 are
-- the shoulder / elbow / wrist-pitch angles in the vertical arm plane, all
-- measured the same way rm501.c's j[1..3] are (home = 0, 90, -90, 0, 0 puts
-- the tool tip at (1.6, 3.2, 0), tool pointing straight down). phi = the tool
-- pitch = theta2 + theta3 + theta4; the d5 tool segment leaves the wrist in
-- direction (sin phi, -cos phi) in the arm plane.
-- ---------------------------------------------------------------------------

-- forward: joints[1..5] deg -> pose {x,y,z, a = tool pitch deg, b = roll deg}
local function kins_fwd(j)
  local t1, t2, t3 = rad(j[1]), rad(j[2]), rad(j[3])
  local t4 = rad(j[4])
  local phi = t2 + t3 + t4
  local rho = A2 * cos(t2) + A3 * cos(t2 + t3) + D5 * sin(phi)
  local h   = D1 + A2 * sin(t2) + A3 * sin(t2 + t3) - D5 * cos(phi)
  return {
    x = rho * cos(t1),
    y = h,
    z = rho * sin(t1),
    a = deg(phi),
    b = j[5],
  }
end

-- inverse: pose -> joints[1..5] deg. Elbow-"down" solution (s3 = -sqrt),
-- matching rm501.c. Results are clamped to the software limits.
local function kins_inv(pose)
  local x, y, z = pose.x, pose.y, pose.z
  local phi  = rad(pose.a or 0)
  local roll = pose.b or 0

  local t1  = atan2(z, x)
  local rho = sqrt(x * x + z * z)

  -- wrist-pitch joint = base of the d5 tool segment
  local rw = rho - D5 * sin(phi)
  local hw = y - D1 + D5 * cos(phi)

  -- planar 2R inverse for links A2, A3 reaching (rw, hw)
  local c3 = (rw * rw + hw * hw - A2 * A2 - A3 * A3) / (2 * A2 * A3)
  c3 = clampd(c3, -1, 1)
  local s3 = -sqrt(1 - c3 * c3)
  local t3 = atan2(s3, c3)

  local num = hw * (A3 * c3 + A2) - A3 * s3 * rw
  local den = rw * (A3 * c3 + A2) + A3 * s3 * hw
  local t2 = atan2(num, den)

  local t4 = phi - t2 - t3

  local j = { deg(t1), deg(t2), deg(t3), deg(t4), roll }
  for i = 1, 5 do j[i] = clampd(j[i], LIMIT[i][1], LIMIT[i][2]) end
  return j
end

-- ---------------------------------------------------------------------------
-- Scene
-- ---------------------------------------------------------------------------

common.setTiming(1 / 60, 20, 1 / 120)

local floor = Plane(0, 1, 0, 0, 40)
floor.col = "#141414"
floor.friction = 0.8
v:add(floor)

v:addParam("speed",   3.0, 0.5, 15,  0.5, "tool tip cartesian speed (units/s)")
v:addParam("accel",  40.0,   5, 300,   5, "tool tip cartesian acceleration (units/s^2)")
v:addParam("blend",  0.15,   0, 0.6, 0.05, "motion blending tolerance (0 = full stop at each point)")
v:addParam("Kp",     50.0,   4, 120,   2, "joint servo proportional gain")
v:addParam("gravity", false, "let gravity load the arm (motors must hold it up)")
v:addParam("showTarget", true, "show the planned tool-tip target marker")

v.gravity = btVector3(0, 0, 0)
v:setSolverIterations(40)

-- ---------------------------------------------------------------------------
-- The arm.
--
-- The moving parts are six bodies (static base + five links) spawned in the
-- all-zero joint pose - arm stretched horizontally along +X at height D1 -
-- so every hinge frame is world-axis aligned and starts at angle 0. Those
-- collision bodies are simple boxes and are left invisible; the robot the
-- viewer sees is built from cylinder joint housings, cylindrical link tubes
-- and a two-finger gripper, each a mass-0 "skin" part rigidly parented to one
-- of the links and re-posed every frame (see the postSim callback).
-- ---------------------------------------------------------------------------

local ORANGE = "#e5731d"
local DARK   = "#2b2b2b"
local STEEL  = "#9198a2"
local GREY   = "#5c5c5c"

-- quaternions taking a cylinder's local +Z axis onto a world axis
local Z_UP  = common.orientBetween(btVector3(0, 0, 0), btVector3(0, 1, 0)) -- +Z -> +Y
local Z_FWD = common.orientBetween(btVector3(0, 0, 0), btVector3(1, 0, 0)) -- +Z -> +X
local QID   = common.quat(0, 0, 0)

-- static base: a cylindrical foot + column (decorative skin), top face at
-- y = D1. `base` itself is a small invisible box down at floor level that only
-- anchors joint 1 - keeping it clear of the arm's swing near the shoulder.
local base = Cube(1.2, 0.4, 1.2, 0)
base.pos = btVector3(0, 0.2, 0)
base.transparency = 1.0
v:add(base)

-- foot + column are decorative skin over the invisible `base` box
local function static_skin(shape, col, trans)
  shape.col = col
  v:add(shape)
  shape.trans = trans
  shape.body:forceActivationState(4)
  shape.body:setCollisionFlags(shape.body:getCollisionFlags() + 4) -- CF_NO_CONTACT_RESPONSE
end

static_skin(Cylinder(1.15, 0.34, 0), "#161616", btTransform(Z_UP, btVector3(0, 0.17, 0)))
static_skin(Cylinder(0.44, D1 - 0.34, 0), DARK,
            btTransform(Z_UP, btVector3(0, 0.34 + (D1 - 0.34) / 2, 0)))

-- L1 turret, L2 upper arm, L3 forearm, L4 wrist, L5 hand - the invisible
-- collision boxes. Each is kept a bit shorter/thinner than its link so that
-- bodies not joined by a hinge never overlap and fight each other.
local turret = Cube(0.8, 0.8, 0.8, 1.2)
turret.pos = btVector3(0, D1, 0)

local upper = Cube(A2 - 0.2, 0.4, 0.4, 2.0)
upper.pos = btVector3(A2 / 2, D1, 0)

local fore = Cube(A3 - 0.4, 0.3, 0.3, 1.0)
fore.pos = btVector3(A2 + A3 / 2, D1, 0)

local wrist = Cube(0.32, 0.44, 0.44, 0.4)
wrist.pos = btVector3(A2 + A3, D1, 0)

-- the hand body is centred on the wrist point W so joint 5 (roll) is a rigid,
-- zero-offset hinge; the tool length is all in the skin below.
local hand = Cube(0.3, 0.5, 0.42, 0.7)
hand.pos = btVector3(A2 + A3, D1, 0)

local links = { turret, upper, fore, wrist, hand }
for _, b in ipairs(links) do
  b.friction = 0.4
  b.restitution = 0
  b.damp_lin = 0.05
  b.damp_ang = 0.3
  b.transparency = 1.0
  v:add(b)
  b.body:forceActivationState(4)     -- DISABLE_DEACTIVATION
end

-- Five revolute joints (axis is in each body's local frame; at the all-zero
-- spawn pose local == world). SIGN[i] maps a joint angle in the kinematic
-- model above to Bullet's getHingeAngle() for that joint - i.e. the physical
-- joint angle equals SIGN[i] * hinge:getHingeAngle(). These were measured by
-- driving each motor a known amount and reading back the arm geometry.
local AXIS_Y = btVector3(0, -1, 0)
local AXIS_Z = btVector3(0, 0, 1)
local SIGN   = { -1, -1, -1, -1, -1 }

local function hinge(a, b, pivotWorld, axis)
  local pa = btVector3(pivotWorld.x - a.pos.x, pivotWorld.y - a.pos.y, pivotWorld.z - a.pos.z)
  local pb = btVector3(pivotWorld.x - b.pos.x, pivotWorld.y - b.pos.y, pivotWorld.z - b.pos.z)
  local h = btHingeConstraint(a.body, b.body, pa, pb, axis, axis)
  v:addConstraint(h)
  return h
end

local S = btVector3(0, D1, 0)             -- shoulder / turret axis
local E = btVector3(A2, D1, 0)            -- elbow
local W = btVector3(A2 + A3, D1, 0)       -- wrist

local joints = {
  hinge(base,   turret, S, AXIS_Y),
  hinge(turret, upper,  S, AXIS_Z),
  hinge(upper,  fore,   E, AXIS_Z),
  hinge(fore,   wrist,  W, AXIS_Z),
  hinge(wrist,  hand,   W, AXIS_Y),
}

-- ---------------------------------------------------------------------------
-- Visible "skin": cylinder housings + link tubes + gripper, each rigidly
-- fixed to a link at a constant local offset. `off` is that offset as a
-- btTransform in the parent link's frame (all links spawn axis-aligned, so
-- these are written directly in world terms at the home pose).
-- ---------------------------------------------------------------------------

local skin = {}
local function part(shape, col, parent, quat, tx, ty, tz)
  shape.col = col
  shape.transparency = 0
  v:add(shape)
  shape.body:forceActivationState(4)
  shape.body:setCollisionFlags(shape.body:getCollisionFlags() + 4) -- CF_NO_CONTACT_RESPONSE
  skin[#skin + 1] = { obj = shape, parent = parent, off = btTransform(quat, btVector3(tx, ty, tz)) }
end

-- turret: vertical barrel around the waist axis, with a cap on top
part(Cylinder(0.46, 0.92, 0), ORANGE, turret, Z_UP, 0, 0, 0)
part(Cylinder(0.34, 0.3, 0),  DARK,   turret, Z_UP, 0, 0.55, 0)

-- shoulder yoke (J2) + upper-arm tube (from S to E)
part(Cylinder(0.3, 0.78, 0),       GREY,   upper, QID,  -A2 / 2, 0, 0)   -- at S
part(Cylinder(0.22, A2 - 0.12, 0), ORANGE, upper, Z_FWD, 0, 0, 0)

-- elbow housing (J3) + forearm tube (from E to W)
part(Cylinder(0.26, 0.66, 0),      GREY,   fore, QID, -A3 / 2, 0, 0)     -- at E
part(Cylinder(0.19, A3 - 0.1, 0),  ORANGE, fore, Z_FWD, 0, 0, 0)

-- wrist pitch housing (J4)
part(Cylinder(0.22, 0.5, 0),  GREY,  wrist, QID, 0, 0, 0)                -- at W

-- wrist-roll segment (J5) + two-finger gripper. Parented to the hand, which is
-- centred on W; the tool runs down local -Y for D5, the jaws open along local Z.
part(Cylinder(0.18, D5 - 0.1, 0), STEEL, hand, Z_UP, 0, -D5 / 2 + 0.05, 0)   -- W .. tip
part(Cube(0.28, 0.16, 0.54, 0), DARK,  hand, QID, 0, -D5 + 0.13, 0)         -- gripper knuckle
part(Cube(0.15, 0.46, 0.09, 0), STEEL, hand, QID, 0, -D5 - 0.06,  0.21)     -- finger +z
part(Cube(0.15, 0.46, 0.09, 0), STEEL, hand, QID, 0, -D5 - 0.06, -0.21)     -- finger -z

-- ---------------------------------------------------------------------------
-- Trajectory generator, RM-501 kinematics wired in as the kinematics hook.
-- ---------------------------------------------------------------------------

local BIG = 1e5
local tg, terr = trajgen.new{
  sample_interval        = 1 / 60,
  interpolation_rate     = 1,
  number_of_used_joints  = 5,
  max_coord_velocity     = 25,
  max_coord_acceleration = 400,
  joints = {
    { max_velocity = BIG, max_acceleration = BIG },
    { max_velocity = BIG, max_acceleration = BIG },
    { max_velocity = BIG, max_acceleration = BIG },
    { max_velocity = BIG, max_acceleration = BIG },
    { max_velocity = BIG, max_acceleration = BIG },
  },
  kinematics = {
    forward = function(j) return kins_fwd(j) end,
    inverse = function(pose) return kins_inv(pose) end,
  },
}
assert(tg, "trajgen.new failed: " .. tostring(terr and trajgen.errstr(terr)))

-- seed the planner at the physical spawn pose (all joints zero)
for i = 1, 5 do tg.joints[i].position = 0 end
tg:switch_state(trajgen.TRAJ_STATE_COORDINATED)
tg:tick()   -- run the COORDINATED_ENTER transition

-- ---------------------------------------------------------------------------
-- Random reachable targets.
--
-- Points are sampled in shoulder-centred "shell" coordinates: dwc = the wrist
-- centre's distance from the shoulder (kept inside the band the elbow limit
-- allows), alpha = its elevation in the arm plane, plus a waist azimuth and a
-- tool pitch/roll. A candidate is accepted only if the unclamped inverse
-- kinematics of both the target *and* the midpoint of the straight line to it
-- stay inside the joint limits (with margin) - so the planner never commands
-- an angle the arm has to clamp, and tracking stays tight.
-- ---------------------------------------------------------------------------

local function lerp(a, b, t) return a + (b - a) * t end
local rnd = math.random

-- inverse kinematics without the limit clamp, for reachability testing
local function kins_inv_raw(pose)
  local x, y, z = pose.x, pose.y, pose.z
  local phi = rad(pose.a or 0)
  local t1  = atan2(z, x)
  local rho = sqrt(x * x + z * z)
  local rw  = rho - D5 * sin(phi)
  local hw  = y - D1 + D5 * cos(phi)
  local c3  = clampd((rw * rw + hw * hw - A2 * A2 - A3 * A3) / (2 * A2 * A3), -1, 1)
  local s3  = -sqrt(1 - c3 * c3)
  local t3  = atan2(s3, c3)
  local t2  = atan2(hw * (A3 * c3 + A2) - A3 * s3 * rw,
                    rw * (A3 * c3 + A2) + A3 * s3 * hw)
  return { deg(t1), deg(t2), deg(t3), deg(phi - t2 - t3), pose.b or 0 }
end

local function in_limits(j, m)
  for i = 1, 5 do
    if j[i] < LIMIT[i][1] + m or j[i] > LIMIT[i][2] - m then return false end
  end
  return true
end

local function random_pose()
  local wa    = rad(lerp(-70, 118, rnd()))
  local dwc   = lerp(2.8, 3.42, rnd())
  local alpha = rad(lerp(-28, 46, rnd()))
  local pitch = rad(lerp(-14, 20, rnd()))
  local roll  = lerp(-120, 120, rnd())
  local rw, hw = dwc * cos(alpha), dwc * sin(alpha)
  local rho = rw + D5 * sin(pitch)
  local h   = D1 + hw - D5 * cos(pitch)
  return { x = rho * cos(wa), y = h, z = rho * sin(wa), a = deg(pitch), b = roll }
end

-- pick the next target: the straight line from `from` to it must stay inside
-- the joint limits, sampled along the way (the t=0 end is skipped - that is
-- wherever the arm already is, which is reachable by definition).
local function reachable_path(from, p)
  for _, t in ipairs({ 0.15, 0.4, 0.65, 0.9, 1 }) do
    local q = { x = lerp(from.x, p.x, t), y = lerp(from.y, p.y, t), z = lerp(from.z, p.z, t),
                a = lerp(from.a, p.a, t), b = lerp(from.b, p.b, t) }
    if not in_limits(kins_inv_raw(q), 5) then return false end
  end
  return true
end

local function next_target(from)
  for _ = 1, 40 do
    local p = random_pose()
    if reachable_path(from, p) then return p end
  end
  return from
end

-- the planner is seeded at the all-zero spawn pose, so that is where the
-- first straight-line move starts from
local target_pose = kins_fwd({ 0, 0, 0, 0, 0 })

-- ---------------------------------------------------------------------------
-- Target marker (planned tool tip) - a small sphere, purely visual (mass 0)
-- ---------------------------------------------------------------------------

local marker = Sphere(0.16, 0)
marker.col = "#39d353"
v:add(marker)
marker.body:forceActivationState(4)
-- CF_NO_CONTACT_RESPONSE: the marker is a pure visual, it must not shove the arm
marker.body:setCollisionFlags(marker.body:getCollisionFlags() + 4)

-- ---------------------------------------------------------------------------
-- Per-step: advance the planner, servo each hinge motor to its commanded
-- joint angle, and top the queue up with fresh random targets.
-- ---------------------------------------------------------------------------

local PI, TWO_PI = math.pi, 2 * math.pi
local function wrap_pi(a)
  a = a % TWO_PI                 -- Lua % follows the divisor sign: result in [0, 2pi)
  return a > PI and a - TWO_PI or a
end

v:preSim(function(N)
  v.gravity = v:getParam("gravity") and btVector3(0, -9.81, 0) or btVector3(0, 0, 0)

  local speed = v:getParam("speed")
  local accel = v:getParam("accel")
  local Kp    = v:getParam("Kp")
  tg:set_blending_tolerance(v:getParam("blend"))

  -- keep two moves queued so blending has a successor to blend into
  local guard = 0
  while tg:num_queued() < 2 and guard < 4 do
    guard = guard + 1
    local nt = next_target(target_pose)
    if tg:add_line(nt, speed, accel) == 0 then target_pose = nt end
  end

  if tg:tick() ~= 0 then print("trajgen: " .. trajgen.errstr(tg.last_error)) end

  -- servo the hinge motors to the planned joint angles (mapped to Bullet's
  -- hinge-angle sign by SIGN[i])
  for i = 1, 5 do
    local tgt = SIGN[i] * rad(tg.joints[i].position)
    local ff  = SIGN[i] * rad(tg.joints[i].velocity)   -- feed-forward joint rate
    local errA = wrap_pi(tgt - joints[i]:getHingeAngle())
    local w = clampd(ff + Kp * errA, -16, 16)
    joints[i]:enableAngularMotor(true, w, 2500)
  end

  -- move the marker to the planned tip
  if v:getParam("showTarget") then
    local tip = kins_fwd{
      tg.joints[1].position, tg.joints[2].position, tg.joints[3].position,
      tg.joints[4].position, tg.joints[5].position,
    }
    marker.pos = btVector3(tip.x, tip.y, tip.z)
  end
end)

-- Diagnostics (headless): track how well the physical arm follows the plan.
local dbg = { maxerr = 0, sumerr = 0, n = 0 }
v:postSim(function(N)
  -- re-pose the visible skin onto its links (link.trans is current post-step)
  for _, s in ipairs(skin) do
    local t = btTransform()
    t:mult(s.parent.trans, s.off)
    s.obj.trans = t
  end

  -- physical joint angles from the hinges, run through forward kinematics, vs
  -- the planned tool tip - a rough measure of how well the arm is tracking.
  local jm = {}
  for i = 1, 5 do jm[i] = SIGN[i] * deg(joints[i]:getHingeAngle()) end
  local pc = kins_fwd{ tg.joints[1].position, tg.joints[2].position, tg.joints[3].position,
                       tg.joints[4].position, tg.joints[5].position }
  local pm = kins_fwd(jm)
  local e = math.sqrt((pc.x - pm.x) ^ 2 + (pc.y - pm.y) ^ 2 + (pc.z - pm.z) ^ 2)
  if N > 60 then
    dbg.n = dbg.n + 1
    dbg.sumerr = dbg.sumerr + e
    if e > dbg.maxerr then dbg.maxerr = e end
  end
  if N % 200 == 0 then
    printf("N=%4d  cmd j=[%6.1f %6.1f %6.1f %6.1f %6.1f]  tip-track err now=%.3f  mean=%.3f  max=%.3f  q=%d",
      N, tg.joints[1].position, tg.joints[2].position, tg.joints[3].position,
      tg.joints[4].position, tg.joints[5].position,
      e, dbg.n > 0 and dbg.sumerr / dbg.n or 0, dbg.maxerr, tg:num_queued())
  end
end)

-- ---------------------------------------------------------------------------
-- Camera
-- ---------------------------------------------------------------------------

common.setCamera(
  btVector3(7.5, 5.5, 10.5),
  btVector3(0.8, 2.6, 0),
  0.5,
  { up = btVector3(0, 1, 0) })

-- EOF
