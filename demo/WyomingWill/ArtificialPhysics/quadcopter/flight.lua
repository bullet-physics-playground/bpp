--
-- quadcopter/flight.lua -- a physically modelled quadcopter for BPP
--
-- One drone = one Bullet rigid body (a flat box that covers the props,
-- with the inertia tensor of a real 450 mm X quad set explicitly), drawn
-- with the meshes from gen-meshes.py. Bullet integrates the rigid-body
-- motion (including the gyroscopic term) and handles contacts with the
-- ground, obstacles and other drones; everything that makes it fly is
-- computed here and handed to Bullet as one force and one torque per
-- physics step:
--
--  ROTORS. Four rotors on the diagonals, each with its own motor speed
--  omega_i. Thrust T_i = kT * omega_i^2 along the body up axis, reaction
--  (drag) torque Q_i = kQ * omega_i^2 about it, front-right and rear-left
--  spinning counter-clockwise seen from above, the other pair clockwise,
--  so yaw comes only from the speed difference between the pairs. Each
--  motor is a first-order lag (tauMotor) from its commanded speed, between
--  an armed idle speed and omegaMax. Thrust-to-weight at full throttle is
--  about 2.4, so the drone genuinely runs out of authority in hard
--  manoeuvres. Applying the summed rotor forces at the centre of mass plus
--  their moments (r x F) as a torque is exactly equivalent to applying
--  each rotor force at its hub.
--
--  AIR. Air-relative velocity va = v - air, where air is the wind plus
--  whatever the caller says is blowing at this drone (downwash from drones
--  above it). Three terms:
--    * axial inflow: a rotor climbing into its own inflow (or sitting in
--      someone's downwash) loses thrust. Linearised momentum theory,
--      dT/dV = -sqrt(T * rho * A / 2) along the body up axis -- about
--      1.35 N per m/s at hover for this airframe.
--    * rotor (blade-flapping/induced) drag, linear in the in-plane airspeed
--    * body form drag, 0.5 rho Cd A |va| va
--  plus ground effect on thrust (Cheeseman-Bennett, capped) close to the
--  ground, and a little rotational damping.
--
-- THE FLIGHT CONTROLLER is a standard cascade, structured like PX4's
-- multicopter controller, running every physics step:
--   position P (+ velocity feed-forward from the trajectory setpoint)
--     -> velocity PI -> desired acceleration -> desired thrust vector,
--        limited to maxTilt and to the available thrust (vertical first)
--     -> desired attitude (thrust direction + held yaw), geometric
--        attitude error on SO(3) (Lee et al.) -> body-rate setpoint
--     -> rate P with gyroscopic feed-forward -> body torques
--     -> motor mixer with saturation handling (roll/pitch kept, yaw
--        sacrificed first, collective shifted to fit) -> motor speeds.
-- The controller only sees the true state (no sensor noise model).
--
-- A tilt failsafe disarms the motors if the drone stays past failTilt
-- (like PX4's FD_FAIL_R/P), after which it is just a falling rigid body.
--
-- Usage:
--   local Quad = require "quadcopter.flight"
--   local d = Quad.new(x, y, z, colour)  -- on the ground or in the air
--   d.spx, d.spy, d.spz = ...            -- position setpoint (m)
--   d.vfx, d.vfy, d.vfz = ...            -- velocity feed-forward (m/s)
--   d.armed = true
--   each physics step: Quad.step(d, dt) then v:stepSimulation(dt, 1, dt)
--   each frame:        Quad.sync(d)      -- move the follower meshes
--   Quad.remove(d)
--

local M = {}

local sqrt, abs, min, max, exp, acos, cos, sin =
  math.sqrt, math.abs, math.min, math.max, math.exp, math.acos, math.cos, math.sin

--------------------------------------------------------------------------
-- Airframe: a generic 450 mm X quad, 1.5 kg all-up, 10x4.5 props on
-- ~920 kV motors and 3S. Inertia: four 60 g motors on 0.225 m arms plus a
-- distributed frame/battery -- in the range measured for real F450s.
--------------------------------------------------------------------------
local P = {
  mass       = 1.5,                 -- kg
  arm        = 0.225,               -- m, centre to motor
  Ixx        = 0.015,               -- kg m^2, roll  (body x, forward)
  Iyy        = 0.028,               -- kg m^2, yaw   (body y, up)
  Izz        = 0.015,               -- kg m^2, pitch (body z, right)
  kT         = 1.14e-5,             -- N / (rad/s)^2
  kQ         = 1.8e-7,              -- N m / (rad/s)^2  (kQ/kT = 15.8 mm)
  omegaMax   = 890,                 -- rad/s (~8500 rpm): 9.0 N per motor
  omegaIdle  = 120,                 -- rad/s, armed idle
  tauMotor   = 0.04,                -- s, motor + prop spin-up lag
  propR      = 0.127,               -- m, 10-inch prop
  rho        = 1.225,               -- kg/m^3
  dragRotor  = 0.25,                -- N per m/s of in-plane airspeed
  dragBody   = 0.03,                -- kg/m, 0.5 rho Cd A
  dragAng    = 0.003,               -- N m per rad/s
  g          = 9.81,

  -- position / velocity loops (horizontal, vertical)
  kpPosH = 1.0,  kpPosV = 1.2,
  kpVelH = 1.8,  kiVelH = 0.4,
  kpVelV = 4.0,  kiVelV = 2.0,
  vMaxH  = 6.0,  vMaxUp = 3.0,  vMaxDown = 2.0,
  maxTilt = math.rad(35),
  minThrustFrac = 0.15,             -- never ask for less than this x weight
  -- attitude / rate loops
  kAtt    = 6.5, kAttYaw  = 2.8,    -- rad/s per rad
  kRate   = 16,  kRateYaw = 6,      -- 1/s
  maxRate = 4.0, maxYawRate = 1.5,  -- rad/s
  failTilt = math.rad(65), failTime = 0.25,

  -- collision shape: a flat box covering the prop discs and legs (BPP binds
  -- no Y-axis btCylinderShape constructor)
  hullR = 0.29, hullHalfH = 0.07,
}
M.P = P

local A_DISC = 4 * math.pi * P.propR * P.propR     -- total rotor disc area
local MA = P.arm / sqrt(2)                          -- motor x/z offset
local CQ = P.kQ / P.kT                              -- yaw torque per N of thrust
local T_MAX = P.kT * P.omegaMax * P.omegaMax        -- per motor
local T_IDLE = P.kT * P.omegaIdle * P.omegaIdle
local LEG_DROP = P.hullHalfH                        -- centre of mass above the feet

M.T_MAX = T_MAX
M.HOVER_THRUST = P.mass * P.g / 4
M.GROUND_Y = LEG_DROP                               -- centre height when landed

-- btCollisionObject flags
local CF_KINEMATIC_OBJECT    = 2
local CF_NO_CONTACT_RESPONSE = 4

local MESH_DIR = "quadcopter/meshes/"
local FRONT_COL = "#d02020"
local PROPS_COL = "#202020"

--------------------------------------------------------------------------
-- construction
--------------------------------------------------------------------------
local SHAPE = btBoxShape(btVector3(P.hullR, P.hullHalfH, P.hullR))
local INERTIA = btVector3(P.Ixx, P.Iyy, P.Izz)

local function follower(file, col, transparency)
  local m = Mesh(MESH_DIR .. file, 0, false)
  m.col = col
  if transparency then m.transparency = transparency end
  -- visual only: out of every collision group, so Bullet never even pairs it
  -- with the drone's own hull (a GImpact mesh against a box costs ~1.5 ms a
  -- step, contact response or not)
  m.collides = false
  v:add(m)
  m.body:setCollisionFlags(CF_KINEMATIC_OBJECT + CF_NO_CONTACT_RESPONSE)
  return m
end

function M.new(x, y, z, col)
  local frame = Mesh(MESH_DIR .. "frame.obj", 0, false)
  local body = btRigidBody(P.mass, btDefaultMotionState(btTransform(btQuaternion(0, 0, 0, 1), btVector3(x, y, z))),
                           SHAPE, INERTIA)
  frame.body = body
  frame.col = col or "#ffffff"
  v:add(frame)
  body:forceActivationState(4)        -- DISABLE_DEACTIVATION
  body:setDamping(0, 0)               -- all air forces are modelled below
  body:setFriction(0.8)
  body:setRestitution(0.1)

  local d = {
    obj = frame, body = body,
    front = follower("front.obj", FRONT_COL),
    props = follower("props.obj", PROPS_COL, 0.55),
    -- state (refreshed every step)
    px = x, py = y, pz = z, vx = 0, vy = 0, vz = 0,
    upx = 0, upy = 1, upz = 0, tilt = 0,
    -- setpoints
    spx = x, spy = y, spz = z, vfx = 0, vfy = 0, vfz = 0, yawSp = 0,
    airx = 0, airy = 0, airz = 0,    -- air velocity at this drone (wind + downwash)
    armed = false, failed = false, failTimer = 0,
    holdVertI = true,                -- freeze the vertical integrator (on the ground)
    iVx = 0, iVy = 0, iVz = 0,       -- velocity-loop integrators
    w1 = 0, w2 = 0, w3 = 0, w4 = 0,  -- motor speeds
    thrust = 0, saturated = false,
  }
  M.sync(d)
  return d
end

function M.remove(d)
  v:remove(d.front); v:remove(d.props); v:remove(d.obj)
end

function M.setColor(d, col) d.obj.col = col end

-- keep the visual-only meshes glued to the body
function M.sync(d)
  local t = d.body:getCenterOfMassTransform()
  d.front.trans = t
  d.props.trans = t
end

-- an instant teleport (used for a fresh setup); zeroes all motion
function M.place(d, x, y, z)
  d.body:setCenterOfMassTransform(btTransform(btQuaternion(0, 0, 0, 1), btVector3(x, y, z)))
  d.body:setLinearVelocity(btVector3(0, 0, 0))
  d.body:setAngularVelocity(btVector3(0, 0, 0))
  d.spx, d.spy, d.spz = x, y, z
  d.vfx, d.vfy, d.vfz = 0, 0, 0
  d.iVx, d.iVy, d.iVz = 0, 0, 0
  d.w1, d.w2, d.w3, d.w4 = 0, 0, 0, 0
  M.sync(d)
end

local function clamp(x, lo, hi) if x < lo then return lo elseif x > hi then return hi end return x end
local function dot(ax, ay, az, bx, by, bz) return ax * bx + ay * by + az * bz end
-- the largest k <= kIn for which thrust t + k*y stays inside [lo, hi]
local function fitYaw(kIn, t, y, lo, hi)
  if y > 0 and t + y > hi then return min(kIn, (hi - t) / y) end
  if y < 0 and t + y < lo then return min(kIn, (lo - t) / y) end
  return kIn
end

--------------------------------------------------------------------------
-- one control + dynamics step: read state, run the controller, run the
-- motors, sum rotor + air forces, hand them to Bullet. Call right before
-- each v:stepSimulation(dt, 1, dt) (Bullet clears forces after a step).
--------------------------------------------------------------------------
function M.step(d, dt)
  local body = d.body
  local pos = body:getCenterOfMassPosition()
  local vel = body:getLinearVelocity()
  local q   = body:getOrientation()
  local w   = body:getAngularVelocity()
  local px, py, pz = pos.x, pos.y, pos.z
  local vx, vy, vz = vel.x, vel.y, vel.z
  local qx, qy, qz, qw = q:x(), q:y(), q:z(), q:w()
  local wx, wy, wz = w.x, w.y, w.z
  d.px, d.py, d.pz, d.vx, d.vy, d.vz = px, py, pz, vx, vy, vz

  -- body axes in world coordinates: b1 forward, b2 up, b3 right
  local b1x, b1y, b1z = 1 - 2 * (qy * qy + qz * qz), 2 * (qx * qy + qz * qw), 2 * (qx * qz - qy * qw)
  local b2x, b2y, b2z = 2 * (qx * qy - qz * qw), 1 - 2 * (qx * qx + qz * qz), 2 * (qy * qz + qx * qw)
  local b3x, b3y, b3z = 2 * (qx * qz + qy * qw), 2 * (qy * qz - qx * qw), 1 - 2 * (qx * qx + qy * qy)
  d.upx, d.upy, d.upz = b2x, b2y, b2z
  local tilt = acos(clamp(b2y, -1, 1))
  d.tilt = tilt

  -- failsafe: stuck past failTilt -> flight termination (motors off)
  if d.armed then
    if tilt > P.failTilt then
      d.failTimer = d.failTimer + dt
      if d.failTimer > P.failTime then d.armed = false; d.failed = true end
    else
      d.failTimer = 0
    end
  end

  local m, g = P.mass, P.g
  local c1, c2, c3, c4 = 0, 0, 0, 0   -- commanded motor speeds
  local T_total_cmd = 0
  d.saturated = false

  if d.armed then
    ------------------------------------------------------------------
    -- position -> velocity setpoint
    ------------------------------------------------------------------
    local vsx = d.vfx + P.kpPosH * (d.spx - px)
    local vsz = d.vfz + P.kpPosH * (d.spz - pz)
    local vsy = d.vfy + P.kpPosV * (d.spy - py)
    local vh = sqrt(vsx * vsx + vsz * vsz)
    if vh > P.vMaxH then vsx, vsz = vsx * P.vMaxH / vh, vsz * P.vMaxH / vh end
    vsy = clamp(vsy, -P.vMaxDown, P.vMaxUp)

    ------------------------------------------------------------------
    -- velocity PI -> desired acceleration -> desired thrust vector
    ------------------------------------------------------------------
    local evx, evy, evz = vsx - vx, vsy - vy, vsz - vz
    local ax = P.kpVelH * evx + P.kiVelH * d.iVx
    local az = P.kpVelH * evz + P.kiVelH * d.iVz
    local ay = P.kpVelV * evy + P.kiVelV * d.iVy
    local Fx, Fy, Fz = m * ax, m * (ay + g), m * az

    local limited = false
    local Fmin = P.minThrustFrac * m * g
    if Fy < Fmin then Fy = Fmin; limited = true end
    local Tlim = 4 * T_MAX * 0.95
    if Fy > Tlim then Fy = Tlim; limited = true end
    local Fh = sqrt(Fx * Fx + Fz * Fz)
    local FhMax = min(Fy * math.tan(P.maxTilt), sqrt(max(0, Tlim * Tlim - Fy * Fy)))
    if Fh > FhMax then
      Fx, Fz = Fx * FhMax / Fh, Fz * FhMax / Fh
      limited = true
    end
    -- integrate (conditional anti-windup: not while the output is limited)
    if not limited then
      d.iVx = clamp(d.iVx + evx * dt, -3, 3)
      d.iVz = clamp(d.iVz + evz * dt, -3, 3)
      if not d.holdVertI then d.iVy = clamp(d.iVy + evy * dt, -3, 3) end
    end

    ------------------------------------------------------------------
    -- desired attitude: up axis along F, yaw held at yawSp
    ------------------------------------------------------------------
    local Fn = sqrt(Fx * Fx + Fy * Fy + Fz * Fz)
    local d2x, d2y, d2z = Fx / Fn, Fy / Fn, Fz / Fn
    local hx, hz = cos(d.yawSp), -sin(d.yawSp)       -- desired heading (horizontal)
    -- d3 = normalize(h x d2), d1 = d2 x d3
    local d3x, d3y, d3z = -hz * d2y, hz * d2x - hx * d2z, hx * d2y
    local n3 = sqrt(d3x * d3x + d3y * d3y + d3z * d3z)
    d3x, d3y, d3z = d3x / n3, d3y / n3, d3z / n3
    local d1x, d1y, d1z = d2y * d3z - d2z * d3y, d2z * d3x - d2x * d3z, d2x * d3y - d2y * d3x

    -- geometric attitude error e_R = 1/2 vee(Rd^T R - R^T Rd), body frame
    local eRx = 0.5 * (dot(d3x, d3y, d3z, b2x, b2y, b2z) - dot(d2x, d2y, d2z, b3x, b3y, b3z))
    local eRy = 0.5 * (dot(d1x, d1y, d1z, b3x, b3y, b3z) - dot(d3x, d3y, d3z, b1x, b1y, b1z))
    local eRz = 0.5 * (dot(d2x, d2y, d2z, b1x, b1y, b1z) - dot(d1x, d1y, d1z, b2x, b2y, b2z))

    -- rate setpoint (body), current body rates
    local rsx = clamp(-P.kAtt * eRx, -P.maxRate, P.maxRate)
    local rsy = clamp(-P.kAttYaw * eRy, -P.maxYawRate, P.maxYawRate)
    local rsz = clamp(-P.kAtt * eRz, -P.maxRate, P.maxRate)
    local obx = b1x * wx + b1y * wy + b1z * wz
    local oby = b2x * wx + b2y * wy + b2z * wz
    local obz = b3x * wx + b3y * wy + b3z * wz

    -- rate P + gyroscopic feed-forward -> body torque
    local Ix, Iy, Iz = P.Ixx, P.Iyy, P.Izz
    local tx = Ix * P.kRate    * (rsx - obx) + (oby * Iz * obz - obz * Iy * oby)
    local ty = Iy * P.kRateYaw * (rsy - oby) + (obz * Ix * obx - obx * Iz * obz)
    local tz = Iz * P.kRate    * (rsz - obz) + (obx * Iy * oby - oby * Ix * obx)

    -- collective: the thrust vector projected on the current up axis
    local T = max(0, Fx * b2x + Fy * b2y + Fz * b2z)
    T_total_cmd = T

    ------------------------------------------------------------------
    -- mixer. Motors (body x, z): 1 (+a,+a) CCW, 2 (-a,+a) CW,
    -- 3 (-a,-a) CCW, 4 (+a,-a) CW.  tau_x = -a(T1+T2-T3-T4),
    -- tau_z = a(T1-T2-T3+T4), tau_y = cq(-T1+T2-T3+T4).
    ------------------------------------------------------------------
    local rx, rz, ry = tx / (4 * MA), tz / (4 * MA), ty / (4 * CQ)
    local r1, r2, r3, r4 = -rx + rz, -rx - rz, rx - rz, rx + rz
    local y1, y2, y3, y4 = -ry, ry, -ry, ry
    local lo, hi = min(r1, r2, r3, r4), max(r1, r2, r3, r4)
    local span, avail = hi - lo, T_MAX - T_IDLE
    if span > avail then
      local s = avail / span
      r1, r2, r3, r4, lo, hi = r1 * s, r2 * s, r3 * s, r4 * s, lo * s, hi * s
      d.saturated = true
    end
    local base = T / 4
    if base + hi > T_MAX then base = T_MAX - hi; d.saturated = true end
    if base + lo < T_IDLE then base = T_IDLE - lo end
    -- yaw: the largest fraction of it that still fits
    local k = fitYaw(1, base + r1, y1, T_IDLE, T_MAX)
    k = fitYaw(k, base + r2, y2, T_IDLE, T_MAX)
    k = fitYaw(k, base + r3, y3, T_IDLE, T_MAX)
    k = max(0, fitYaw(k, base + r4, y4, T_IDLE, T_MAX))
    local T1 = clamp(base + r1 + k * y1, T_IDLE, T_MAX)
    local T2 = clamp(base + r2 + k * y2, T_IDLE, T_MAX)
    local T3 = clamp(base + r3 + k * y3, T_IDLE, T_MAX)
    local T4 = clamp(base + r4 + k * y4, T_IDLE, T_MAX)
    c1, c2, c3, c4 = sqrt(T1 / P.kT), sqrt(T2 / P.kT), sqrt(T3 / P.kT), sqrt(T4 / P.kT)
  end

  ------------------------------------------------------------------
  -- motors: first-order lag toward the commanded speed
  ------------------------------------------------------------------
  local a = 1 - exp(-dt / P.tauMotor)
  local w1 = d.w1 + (c1 - d.w1) * a
  local w2 = d.w2 + (c2 - d.w2) * a
  local w3 = d.w3 + (c3 - d.w3) * a
  local w4 = d.w4 + (c4 - d.w4) * a
  d.w1, d.w2, d.w3, d.w4 = w1, w2, w3, w4
  local s1, s2, s3, s4 = w1 * w1, w2 * w2, w3 * w3, w4 * w4

  -- ground effect on thrust (rotor plane height above y = 0)
  local hRot = max(py + 0.046, 0.02)
  local ge = 1 / (1 - (P.propR / (4 * hRot)) ^ 2)
  if ge < 1 or ge > 1.25 then ge = 1.25 end
  local kT = P.kT * ge
  local T1, T2, T3, T4 = kT * s1, kT * s2, kT * s3, kT * s4
  local Tt = T1 + T2 + T3 + T4
  d.thrust = Tt

  -- rotor moments in the body frame
  local tbx = -MA * (T1 + T2 - T3 - T4)
  local tbz =  MA * (T1 - T2 - T3 + T4)
  local tby =  P.kQ * (-s1 + s2 - s3 + s4)

  ------------------------------------------------------------------
  -- air: axial inflow, rotor drag, body drag (air-relative velocity)
  ------------------------------------------------------------------
  local ax_, ay_, az_ = vx - d.airx, vy - d.airy, vz - d.airz
  local vu = ax_ * b2x + ay_ * b2y + az_ * b2z                 -- along the up axis
  local pxa, pya, pza = ax_ - vu * b2x, ay_ - vu * b2y, az_ - vu * b2z
  local cAx = sqrt(Tt * P.rho * A_DISC / 2)                     -- dT/dV_axial
  local va = sqrt(ax_ * ax_ + ay_ * ay_ + az_ * az_)
  local Fax = -cAx * vu * b2x - P.dragRotor * pxa - P.dragBody * va * ax_
  local Fay = -cAx * vu * b2y - P.dragRotor * pya - P.dragBody * va * ay_
  local Faz = -cAx * vu * b2z - P.dragRotor * pza - P.dragBody * va * az_

  body:applyCentralForce(btVector3(Tt * b2x + Fax, Tt * b2y + Fay, Tt * b2z + Faz))
  body:applyTorque(btVector3(
    b1x * tbx + b2x * tby + b3x * tbz - P.dragAng * wx,
    b1y * tbx + b2y * tby + b3y * tbz - P.dragAng * wy,
    b1z * tbx + b2z * tby + b3z * tbz - P.dragAng * wz))

  return T_total_cmd
end

-- induced (far-wake) downwash speed of a hovering drone at thrust T, used
-- by the caller's downwash model: 2 * sqrt(T / (2 rho A))
function M.wakeSpeed(T)
  return 2 * sqrt(max(T, 0) / (2 * P.rho * A_DISC))
end
M.DISC_RADIUS = sqrt(A_DISC / math.pi)   -- radius of one disc of the same total area

return M
