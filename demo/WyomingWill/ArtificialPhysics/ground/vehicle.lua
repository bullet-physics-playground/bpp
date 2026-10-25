--
-- ground/vehicle.lua -- a differential-drive ground robot (BOOK.md G10)
-- behind the vehicle interface (lib/swarm.lua, G18)
--
-- THE ROBOT is the book's Pioneer 3-AT as Ch. 13 describes it (PDF
-- 449-453, 463-465; book/ch13.md E3, E4, E11): two driven sides r_diff =
-- 0.3 m either side of the centre, each wheel speed 0 or 0.1-0.5 m/s in
-- either direction (Fig. 13.7's minimum speed), forward speed capped
-- at u_max = 0.5 m/s and turn rate at Omega_max = 0.4 rad/s. Body: a
-- 12 kg box 0.51 x 0.28 x 0.50 m (the P3-AT's datasheet size and mass).
--
-- PHYSICS. One Bullet rigid body; Bullet handles gravity and contacts
-- (with the ground, columns and other robots; the body itself is
-- frictionless, so all traction comes from the tyres). Every physics step
-- the tyre forces are computed here and applied at the centre of mass:
--   wheels   each side's wheel speed follows its command at no more than
--            WHEEL_ACC (1 m/s^2), the motors' limit;
--   traction each side pushes along the heading with
--            F = K_SLIP (v_wheel - v_contact), v_contact the body's
--            forward speed at that side (v_f +- Omega r_diff), capped at
--            mu m g / 2 (mu = 0.8) per side;
--   sideways the tyres resist sideways slip with K_SLIP v_side, capped at
--            mu m g, so the robot cannot move sideways (only skid);
--   yaw      the torque r_diff (F_right - F_left) about the body's up axis.
-- So a robot pushing a column spins its wheels and stays put, and one
-- that is pushed sideways skids.
--
-- GUIDANCE: from AP's command to wheel speeds (book Eqs. 13.4-13.6).
-- AP's command is a straight-line leg: be at w at t0 + T. Every step the
-- leg's point sp(t) = start + vf (t - t0) (then w) and its velocity vf
-- give the desired velocity
--   u_d = vf + K_POS (sp - p)                   (m/s, horizontal)
-- The robot drives forwards or, if u_d points behind it, backwards (the
-- Pioneer reverses; the side only changes when the other is better by
-- more than FLIP_MARGIN, so it does not chatter at 90 deg). With phi the
-- angle from the driving direction to u_d (radians, + = to the left):
--   Omega = clamp(K_HEAD phi, +-min(Omega_max, |u_d| / r_diff))
--                                                (rad/s, + = left turn)
--   u     = |u_d| cos(phi), capped at u_max - |Omega| r_diff  (Eq. 13.6)
--   v_right, v_left = u +- Omega r_diff          (Eqs. 13.4-13.5)
-- and a wheel commanded below V_MIN in magnitude (but not 0) turns at
-- V_MIN: the wheels cannot turn slower (Fig. 13.7), so a small correction
-- is made at the minimum speed rather than not at all (William,
-- 2026-10-25; rounding down to 0 froze the robots short of the lattice
-- and behind columns, F66, F68, F72). A wheel rounded up against the
-- other's direction would turn the robot faster than Omega_max, so the
-- faster wheel is then eased to keep (v_right - v_left) / (2 r_diff)
-- within Omega_max (without this, 0.56 rad/s in the turn check). A wheel
-- commanded exactly 0 stops, and the robot pivots on it with the other
-- held to 2 r_diff Omega_max. The turn-rate limit |u_d| / r_diff keeps
-- every wheel no faster than the speed AP asks for (but for the minimum),
-- so a robot asked to creep does not spin on the spot
-- (it did, at the full 0.4 rad/s, before this rule). AP's
-- desired velocity is a point-mass velocity; the robot can only follow
-- its component along its heading while it turns -- the lag Ch. 13
-- warns about. The sensed position is the rotation centre (the book's
-- offset particle is not modelled).
--
-- No 3D (can3D false), nothing breaks on contact (fragile false: bumps
-- are counted, not losses), no wind. Deploy: ready at once, on its pad.
--

local V = {}

V.name   = "ground robot"
V.noun   = "robots"
V.moving = "driving"
V.can3D  = false
V.fragile = false
V.floorY = 0

-- the Pioneer 3-AT (book Ch. 13; datasheet for size and mass)
local P = {
  mass = 12.0,                 -- kg
  len = 0.508, wid = 0.497, hgt = 0.277,   -- m (box; length along the heading)
  rDiff = 0.3,                 -- m, each side's distance from the centre (book)
  vMin = 0.1, vMax = 0.5,      -- m/s, wheel speed: 0 or vMin..vMax (book Fig. 13.7)
  uMax = 0.5,                  -- m/s, forward speed cap (book)
  omegaMax = 0.4,              -- rad/s, turn-rate cap (book)
  wheelAcc = 1.0,              -- m/s^2, motors' limit on wheel speed change
  kSlip = 240,                 -- N per m/s of slip, per side (~0.05 s to take up slip)
  mu = 0.8,                    -- tyre friction
  g = 9.81,
  kPos = 1.0,                  -- 1/s, pull back onto the leg
  kHead = 2.0,                 -- 1/s, turn rate per radian of heading error
  flipMargin = math.rad(20),   -- forwards/backwards hysteresis
}
V.P = P

local Y0 = P.hgt / 2           -- centre height on the ground
function V.planeY() return Y0 end

local FRONT_COL = "#d02020"

function V.new(x, z, toAlt)
  local o = Cube(P.len, P.hgt, P.wid, P.mass)
  o.pos = btVector3(x, Y0, z)
  o.col = "#ffffff"
  v:add(o)
  o.body:setFriction(0)
  o.body:setRestitution(0)
  o.body:setDamping(0, 0)
  o.body:forceActivationState(4)          -- DISABLE_DEACTIVATION
  -- the front: a red bar across the leading edge (drawn only)
  local f = Cube(0.04, 0.05, P.wid * 0.9, 0)
  f.col = FRONT_COL
  f.collides = false
  v:add(f)
  local d = { obj = o, body = o.body, front = f,
              px = x, py = Y0, pz = z, vx = 0, vy = 0, vz = 0,
              hx = 1, hz = 0, omega = 0,          -- heading (unit, xz) and yaw rate
              wl = 0, wr = 0, cl = 0, cr = 0,      -- wheel speeds and commands, m/s
              dir = 1, armed = true,
              sx = x, sz = z, vfx = 0, vfz = 0, t0 = 0, trT = 0, wpx = x, wpy = Y0, wpz = z }
  V.sync(d)
  return d
end

function V.remove(d) v:remove(d.front); v:remove(d.obj) end
function V.setColor(d, col) d.obj.col = col end
function V.sync(d)
  local o, q = d.body:getCenterOfMassPosition(), d.body:getOrientation()
  d.front.trans = btTransform(q, btVector3(o.x + d.hx * P.len / 2, o.y + P.hgt / 2 + 0.03, o.z + d.hz * P.len / 2))
end

local function rest(d)            -- a leg that stays where it is
  d.wpx, d.wpy, d.wpz = d.px, d.py, d.pz
  d.sx, d.sz, d.vfx, d.vfz, d.trT = d.px, d.pz, 0, 0, 0
end
function V.join(d, simTime) rest(d) end
function V.hold(d) rest(d) end

function V.command(d, wx, wy, wz, T, simTime)
  d.wpx, d.wpy, d.wpz = wx, wy, wz
  d.sx, d.sz = d.px, d.pz
  d.t0, d.trT = simTime, T
  d.vfx, d.vfz = (wx - d.px) / T, (wz - d.pz) / T
end

local function clamp(x, lo, hi) if x < lo then return lo elseif x > hi then return hi end return x end
local function wheel(c)           -- the minimum speed (rounded up; 0 stays 0) and the cap
  local a = math.abs(c)
  if a == 0 then return 0 elseif a < P.vMin then a = P.vMin end
  return (c > 0 and 1 or -1) * math.min(a, P.vMax)
end

-- every physics step: AP's leg -> wheel commands
function V.guide(d, st, simTime, dt)
  if st == "takeoff" then d.ready = true; return end
  if st ~= "ap" and st ~= "hold" then d.cl, d.cr = 0, 0; return end
  -- the leg's point and velocity now
  local spx, spz, vfx, vfz = d.wpx, d.wpz, 0, 0
  local u_ = simTime - d.t0
  if d.trT > 0 and u_ < d.trT then
    spx, spz, vfx, vfz = d.sx + d.vfx * u_, d.sz + d.vfz * u_, d.vfx, d.vfz
  end
  local ux, uz = vfx + P.kPos * (spx - d.px), vfz + P.kPos * (spz - d.pz)
  local sp = math.sqrt(ux * ux + uz * uz)
  if sp < 1e-6 then d.cl, d.cr = 0, 0; return end
  -- angle from the heading to u_d, + = to the left (about +y)
  local phi = math.atan2(d.hz * ux - d.hx * uz, d.hx * ux + d.hz * uz)
  local back = phi > 0 and phi - math.pi or phi + math.pi   -- the same, driving backwards
  local cur, other = (d.dir > 0) and phi or back, (d.dir > 0) and back or phi
  if math.abs(other) + P.flipMargin < math.abs(cur) then d.dir = -d.dir; cur = other end
  local om = math.min(P.omegaMax, sp / P.rDiff)       -- no wheel faster than AP asks
  local omega = clamp(P.kHead * cur, -om, om)
  local u = math.min(sp * math.cos(cur), P.uMax - math.abs(omega) * P.rDiff)
  if u < 0 then u = 0 end
  u = d.dir * u
  local cr, cl = wheel(u + omega * P.rDiff), wheel(u - omega * P.rDiff)
  -- a wheel rounded up against the other's direction would turn the robot
  -- faster than Omega_max (0.56 rad/s in the check): the faster is eased
  local lim = 2 * P.rDiff * P.omegaMax
  if cr - cl > lim then if math.abs(cr) >= math.abs(cl) then cr = cl + lim else cl = cr - lim end
  elseif cl - cr > lim then if math.abs(cl) >= math.abs(cr) then cl = cr + lim else cr = cl - lim end end
  -- one wheel at 0: the robot pivots on it, so the other is held to
  -- 2 r_diff Omega_max to keep the turn rate within Omega_max
  local pivot = 2 * P.rDiff * P.omegaMax
  if cl == 0 then cr = clamp(cr, -pivot, pivot) end
  if cr == 0 then cl = clamp(cl, -pivot, pivot) end
  d.cr, d.cl = cr, cl
end

-- every physics step: wheels, tyre forces
function V.step(d, dt)
  local body = d.body
  local pos, vel, w = body:getCenterOfMassPosition(), body:getLinearVelocity(), body:getAngularVelocity()
  local q = body:getOrientation()
  local qx, qy, qz, qw = q:x(), q:y(), q:z(), q:w()
  d.px, d.py, d.pz, d.vx, d.vy, d.vz = pos.x, pos.y, pos.z, vel.x, vel.y, vel.z
  -- body axes: forward (local x), up (local y), right (local z)
  local fx, fy, fz = 1 - 2 * (qy * qy + qz * qz), 2 * (qx * qy + qz * qw), 2 * (qx * qz - qy * qw)
  local ux, uy, uz = 2 * (qx * qy - qz * qw), 1 - 2 * (qx * qx + qz * qz), 2 * (qy * qz + qx * qw)
  local rx, ry, rz = 2 * (qx * qz + qy * qw), 2 * (qy * qz - qx * qw), 1 - 2 * (qx * qx + qy * qy)
  local hn = math.sqrt(fx * fx + fz * fz)
  if hn > 1e-6 then d.hx, d.hz = fx / hn, fz / hn end
  local omega = w.x * ux + w.y * uy + w.z * uz            -- yaw rate, + = left
  d.omega = omega

  -- wheels follow their commands at no more than wheelAcc
  local a = P.wheelAcc * dt
  d.wr = d.wr + clamp(d.cr - d.wr, -a, a)
  d.wl = d.wl + clamp(d.cl - d.wl, -a, a)

  -- traction (along the heading) and sideways grip, capped by friction
  local vf = vel.x * fx + vel.y * fy + vel.z * fz
  local vs = vel.x * rx + vel.y * ry + vel.z * rz
  local cap = P.mu * P.mass * P.g / 2
  local Fr = clamp(P.kSlip * (d.wr - (vf + omega * P.rDiff)), -cap, cap)
  local Fl = clamp(P.kSlip * (d.wl - (vf - omega * P.rDiff)), -cap, cap)
  local Fs = clamp(-2 * P.kSlip * vs, -2 * cap, 2 * cap)
  local F = Fr + Fl
  body:applyCentralForce(btVector3(F * fx + Fs * rx, F * fy + Fs * ry, F * fz + Fs * rz))
  local tq = P.rDiff * (Fr - Fl)
  body:applyTorque(btVector3(tq * ux, tq * uy, tq * uz))
end

return V
