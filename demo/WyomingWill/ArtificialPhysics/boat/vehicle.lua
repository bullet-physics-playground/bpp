--
-- boat/vehicle.lua -- a holonomic round surface boat (ASV; BOOK.md G11)
-- behind the vehicle interface (lib/swarm.lua, G18)
--
-- THE BOAT is the book's ASV from Ch. 6 (PDF 218-222; book/ch06.md
-- E6.7): a round hull 18 in (0.46 m) across and 6 in (0.15 m) deep,
-- driven by two counter-rotating Voith-Schneider propellers, which push in
-- any horizontal direction (no "forward"), the second cancelling the
-- first's torque. The book gives no mass, thrust or speed; ours are
-- chosen and stated: 12 kg (draft 7.2 cm), thrust up to 12 N, which
-- against the drag below gives a top speed of ~0.8 m/s.
--
-- PHYSICS. One Bullet rigid body (a vertical cylinder) floating on a flat,
-- still sea at y = 0, over a seabed at floorY; Bullet handles gravity and
-- contacts with columns and other boats. Every physics step the water's
-- forces are computed here (BPP has no fluid simulation; G19):
--   buoyancy  rho g A_i h_i at each of 9 points spread over the bottom
--             (A_i = 1/9 of the bottom's area; h_i the point's depth,
--             0 to the hull's depth), so the hull floats level and rights
--             itself after a knock;
--   heave     -C_HEAVE v_i,y at the same points (half-critical damping);
--   drag      -(C_LIN + C_QUAD |v|) v horizontally, C_QUAD = 0.5 rho Cd
--             (diameter x draft), Cd = 1; -C_YAW omega_y about the vertical;
--   added mass  a hull moving sideways also moves water: a vertical
--             cylinder carries about its own displaced mass along (added
--             mass coefficient 1), so horizontal water and thrust forces
--             act on mass + added mass (they are scaled by m/(m + m_a));
--   thrust    a horizontal force vector, at most T_MAX in magnitude, that
--             follows its command with a first-order lag TAU_THRUST
--             (0.3 s: the blades' cyclic pitch changing).
--
-- GUIDANCE: AP's command is a straight-line leg (be at w at t0 + T). Every
-- step the leg's point sp(t) and velocity vf give the desired velocity
--   u_d = vf + K_POS (sp - p)                    (m/s, horizontal)
-- and the thrust command is the drag at u_d plus a velocity loop:
--   T_cmd = drag(u_d) + (m + m_a) K_VEL (u_d - v), at most T_MAX
-- So the boat is holonomic like a quadcopter, but slower, with less
-- authority and nothing like a 35 degree tilt to brake with.
--
-- No 3D (can3D false), nothing breaks on contact (fragile false), no
-- wind, waves or current (G19 later). Deploy: ready at once, afloat on
-- its pad. The 2D plane (planeY) is the hull's centre when afloat.
--

local V = {}

V.name   = "boat"
V.noun   = "boats"
V.moving = "sailing"
V.can3D  = false
V.fragile = false
V.floorY = -3.0               -- the seabed (m), well below every hull
V.groundColor = "#4a5a48"

local P = {
  mass = 12.0,                -- kg (chosen)
  radius = 0.23, depth = 0.15,-- m, the book's 18 x 6 in hull
  rho = 1000, g = 9.81,
  tMax = 12.0,                -- N, thrust (chosen: ~0.8 m/s top speed)
  tauThrust = 0.3,            -- s, thrust direction and size lag
  cLin = 2.0,                 -- N per m/s, low-speed drag
  cd = 1.0,                   -- drag coefficient on the wetted side
  cYaw = 0.5,                 -- N m per rad/s
  kPos = 1.0,                 -- 1/s, pull back onto the leg
  kVel = 2.0,                 -- 1/s, velocity loop
}
local AREA = math.pi * P.radius * P.radius
local DRAFT = P.mass / (P.rho * AREA)                 -- 0.072 m
local C_QUAD = 0.5 * P.rho * P.cd * 2 * P.radius * DRAFT
local M_ADD = P.rho * AREA * DRAFT                    -- = mass: coefficient 1
local K_HEAVE = P.rho * P.g * AREA
local C_HEAVE = math.sqrt(K_HEAVE * P.mass)           -- half-critical: 2 zeta sqrt(k m), zeta 0.5
local Y0 = P.depth / 2 - DRAFT                        -- hull centre afloat
V.P, V.DRAFT, V.M_ADD = P, DRAFT, M_ADD

-- the 9 buoyancy points on the bottom, in hull coordinates (radius, angle)
local PTS = { { 0, 0 } }
for i = 0, 7 do PTS[#PTS + 1] = { 0.75 * P.radius, i * math.pi / 4 } end

function V.planeY() return Y0 end

-- the sea surface, drawn only
function V.scene()
  local w = Plane(0, 1, 0, 0, 120)
  w.col = "#2a6a9a"
  w.transparency = 0.45
  w.collides = false
  v:add(w)
end

local Q_UP = btQuaternion(btVector3(1, 0, 0), -math.pi / 2)   -- cylinder axis (local z) -> up

function V.new(x, z, toAlt)
  local o = Cylinder(P.radius, P.depth, P.mass)
  o.trans = btTransform(Q_UP, btVector3(x, Y0, z))
  o.col = "#ffffff"
  v:add(o)
  o.body:setFriction(0.3)
  o.body:setRestitution(0.1)
  o.body:setDamping(0, 0)
  o.body:forceActivationState(4)          -- DISABLE_DEACTIVATION
  local d = { obj = o, body = o.body, px = x, py = Y0, pz = z, vx = 0, vy = 0, vz = 0,
              tx = 0, tz = 0, cx = 0, cz = 0, armed = true,
              sx = x, sz = z, vfx = 0, vfz = 0, t0 = 0, trT = 0, wpx = x, wpy = Y0, wpz = z }
  return d
end

function V.remove(d) v:remove(d.obj) end
function V.setColor(d, col) d.obj.col = col end
function V.sync(d) end

local function rest(d)
  d.velMode = false
  d.wpx, d.wpy, d.wpz = d.px, d.py, d.pz
  d.sx, d.sz, d.vfx, d.vfz, d.trT = d.px, d.pz, 0, 0, 0
end
function V.join(d, simTime) rest(d) end
function V.hold(d) rest(d) end

function V.command(d, wx, wy, wz, T, simTime)
  d.velMode = false
  d.wpx, d.wpy, d.wpz = wx, wy, wz
  d.sx, d.sz = d.px, d.pz
  d.t0, d.trT = simTime, T
  d.vfx, d.vfz = (wx - d.px) / T, (wz - d.pz) / T
end

-- G4: sail at the horizontal velocity (vx, vz) (m/s) until the next
-- command: u_d = v, with no pull back onto a leg (vy is ignored)
function V.velocity(d, vx, vy, vz, simTime)
  d.velMode = true
  d.vfx, d.vfz = vx, vz
end

local function drag(vx, vz)      -- horizontal water drag on velocity (vx, vz), N
  local s = math.sqrt(vx * vx + vz * vz)
  local c = P.cLin + C_QUAD * s
  return -c * vx, -c * vz
end

-- every physics step: AP's leg -> thrust command
function V.guide(d, st, simTime, dt)
  if st == "takeoff" then d.ready = true; return end
  if st ~= "ap" and st ~= "hold" then d.cx, d.cz = 0, 0; return end
  local spx, spz, vfx, vfz = d.wpx, d.wpz, 0, 0
  local u_ = simTime - d.t0
  if d.velMode then
    spx, spz, vfx, vfz = d.px, d.pz, d.vfx, d.vfz
  elseif d.trT > 0 and u_ < d.trT then
    spx, spz, vfx, vfz = d.sx + d.vfx * u_, d.sz + d.vfz * u_, d.vfx, d.vfz
  end
  local ux, uz = vfx + P.kPos * (spx - d.px), vfz + P.kPos * (spz - d.pz)
  local dx, dz = drag(ux, uz)
  local m = P.mass + M_ADD
  local cx, cz = -dx + m * P.kVel * (ux - d.vx), -dz + m * P.kVel * (uz - d.vz)
  local c = math.sqrt(cx * cx + cz * cz)
  if c > P.tMax then cx, cz = cx * P.tMax / c, cz * P.tMax / c end
  d.cx, d.cz = cx, cz
end

-- every physics step: thrust, buoyancy, damping, drag
function V.step(d, dt)
  local body = d.body
  local pos, vel, w = body:getCenterOfMassPosition(), body:getLinearVelocity(), body:getAngularVelocity()
  local q = body:getOrientation()
  local qx, qy, qz, qw = q:x(), q:y(), q:z(), q:w()
  d.px, d.py, d.pz, d.vx, d.vy, d.vz = pos.x, pos.y, pos.z, vel.x, vel.y, vel.z
  -- hull axes: a = local x, b = local y (both across the hull), u = local z (the hull's up)
  local ax, ay, az = 1 - 2 * (qy * qy + qz * qz), 2 * (qx * qy + qz * qw), 2 * (qx * qz - qy * qw)
  local bx, by, bz = 2 * (qx * qy - qz * qw), 1 - 2 * (qx * qx + qz * qz), 2 * (qy * qz + qx * qw)
  local ux, uy, uz = 2 * (qx * qz + qy * qw), 2 * (qy * qz - qx * qw), 1 - 2 * (qx * qx + qy * qy)

  -- thrust follows its command
  local k = 1 - math.exp(-dt / P.tauThrust)
  d.tx, d.tz = d.tx + (d.cx - d.tx) * k, d.tz + (d.cz - d.tz) * k

  -- buoyancy and heave damping at the bottom points
  local Fx, Fy, Fz, Tx, Ty, Tz = 0, 0, 0, 0, 0, 0
  local half = P.depth / 2
  local ai = AREA / #PTS
  for _, pt in ipairs(PTS) do
    local r, th = pt[1], pt[2]
    local ca, sa = r * math.cos(th), r * math.sin(th)
    -- the point relative to the centre of mass
    local rx = ca * ax + sa * bx - half * ux
    local ry = ca * ay + sa * by - half * uy
    local rz = ca * az + sa * bz - half * uz
    local h = -(pos.y + ry)                       -- depth below the surface
    if h > 0 then
      if h > P.depth then h = P.depth end
      -- the point's vertical velocity: v + w x r
      local vpy = vel.y + w.z * rx - w.x * rz
      local fy = P.rho * P.g * ai * h - C_HEAVE / #PTS * vpy
      Fy = Fy + fy
      Tx, Ty, Tz = Tx - rz * fy, Ty, Tz + rx * fy  -- r x (0, fy, 0)
    end
  end

  -- horizontal water drag and thrust, on mass + added mass
  local dx, dz = drag(vel.x, vel.z)
  local s = P.mass / (P.mass + M_ADD)
  Fx = Fx + (dx + d.tx) * s
  Fz = Fz + (dz + d.tz) * s
  body:applyCentralForce(btVector3(Fx, Fy, Fz))
  body:applyTorque(btVector3(Tx, Ty - P.cYaw * w.y, Tz))
end

return V
