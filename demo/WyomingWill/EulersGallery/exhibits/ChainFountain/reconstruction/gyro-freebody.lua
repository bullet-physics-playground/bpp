-- Torque-free rigid body in Bullet 3.24 (via bpp), one body per method, no gravity, no contacts.
-- Exact answer: energy E and the world angular momentum vector L stay constant; for a symmetric
-- body (I2 = I3) also the spin about the axis w1 and |w_perp| in the body frame.
-- FB_SHAPE=link (the chain-fountain heap link, kg/cm) or asym; FB_W="w1,w2,w3" (rad/s, body frame);
-- FB_STEPS (steps a second), frames (-n) of FB_PER steps. "solver" needs a bpp with bpp-gyro-midpoint.diff.
v.gravity = btVector3(0, 0, 0)
local function envnum(n, d) return tonumber(os.getenv(n) or "") or d end
local SCALE_M = 1024
local M = 0.0005 * 0.65 / 1.5
local RL, L = 0.225, 0.65
local I
if (os.getenv("FB_SHAPE") or "link") == "link" then
  local IP = M * (L * L / 4 + 0.4 * RL * RL)
  I = { 0.4 * M * RL * RL, IP, IP }
else
  I = { 1.0e-5, 2.0e-5, 3.2e-5 }
end
local w0 = {}
for s in (os.getenv("FB_W") or "1000,600,0"):gmatch("[^,]+") do w0[#w0 + 1] = tonumber(s) end
local DT = 1 / envnum("FB_STEPS", 1800)
local PER = envnum("FB_PER", 900)
local q0 = btQuaternion(btVector3(1, 2, 3):normalized(), 0.7)

local function qparts(b) local q = b:getOrientation(); return q:getX(), q:getY(), q:getZ(), q:getW() end
-- rotate (vx,vy,vz) by unit quaternion (x,y,z,w); inv: by its inverse
local function qrot(x, y, z, w, vx, vy, vz, inv)
  if inv then x, y, z = -x, -y, -z end
  local tx, ty, tz = 2 * (y * vz - z * vy), 2 * (z * vx - x * vz), 2 * (x * vy - y * vx)
  return vx + w * tx + (y * tz - z * ty), vy + w * ty + (z * tx - x * tz), vz + w * tz + (x * ty - y * tx)
end

local methods = { "none", "bullet8", "bullet8x1024", "explicit", "bulletformula", "midpoint", "exact", "ax_exact", "ax_midpoint", "ax_implicit", "solver" }
local bodies = {}
for k, name in ipairs(methods) do
  local s = (name == "bullet8x1024") and SCALE_M or 1
  local o = Sphere(0.1, M * s)
  o.collides = false
  o.pos = btVector3(0, 10, 5 * k)
  v:add(o)
  local b = o.body
  b:setMassProps(M * s, btVector3(I[1] * s, I[2] * s, I[3] * s))
  b:setCenterOfMassTransform(btTransform(q0, btVector3(0, 10, 5 * k)))
  b:setActivationState(4); b:setDamping(0, 0)
  b:setFlags((name == "bullet8" or name == "bullet8x1024") and 8 or (name == "solver" and 1024 or 0))
  local x, y, z, w = qparts(b)
  local W1, W2, W3 = qrot(x, y, z, w, w0[1], w0[2], w0[3])
  b:setAngularVelocity(btVector3(W1, W2, W3))
  bodies[k] = { o = o, b = b, name = name }
end

local GYRO_K = (I[2] - I[1]) / I[2]
local function axis(bd, dt, GYRO)
      local q = bd.b:getOrientation()
      local x, y, z, w = q:getX(), q:getY(), q:getZ(), q:getW()
      local ex, ey, ez = 1 - 2 * (y * y + z * z), 2 * (x * y + w * z), 2 * (x * z - w * y)  -- its axis
      local Wx, Wy, Wz = getAngVelXYZ(bd.o)
      local s = Wx * ex + Wy * ey + Wz * ez
      local px, py, pz = Wx - s * ex, Wy - s * ey, Wz - s * ez
      local cx, cy, cz = ey * pz - ez * py, ez * px - ex * pz, ex * py - ey * px
      local c, sn
      if GYRO == "exact" then
        local th = -GYRO_K * s * dt
        c, sn = math.cos(th), math.sin(th)
      elseif GYRO == "midpoint" then
        local h = -GYRO_K * s * dt / 2
        c, sn = (1 - h * h) / (1 + h * h), 2 * h / (1 + h * h)
      else
        local th = -GYRO_K * s * dt
        c, sn = 1 / (1 + th * th), th / (1 + th * th)
      end
      setAngVelXYZ(bd.o, s * ex + c * px + sn * cx, s * ey + c * py + sn * cy, s * ez + c * pz + sn * cz)
end
-- the Lua gyroscopic updates, before the step, as a change of spin
local function lua(bd, dt)
  local name = bd.name
  if name == "none" or name == "bullet8" or name == "bullet8x1024" or name == "solver" then return end
  if name:sub(1, 3) == "ax_" then return axis(bd, dt, name:sub(4)) end
  local x, y, z, w = qparts(bd.b)
  local Wx, Wy, Wz = getAngVelXYZ(bd.o)
  local a1, a2, a3 = qrot(x, y, z, w, Wx, Wy, Wz, true)
  local b1, b2, b3
  if name == "explicit" then
    -- forward Euler: w += dt I^-1 ((I w) x w)
    local o1, o2, o3 = I[1] * a1, I[2] * a2, I[3] * a3
    b1 = a1 + dt * (o2 * a3 - o3 * a2) / I[1]
    b2 = a2 + dt * (o3 * a1 - o1 * a3) / I[2]
    b3 = a3 + dt * (o1 * a2 - o2 * a1) / I[3]
  elseif name == "bulletformula" then
    -- btRigidBody::computeGyroscopicImpulseImplicit_Body: one Newton step of backward Euler
    local o = { I[1] * a1, I[2] * a2, I[3] * a3 }
    local wv = { a1, a2, a3 }
    local f = { dt * (a2 * o[3] - a3 * o[2]), dt * (a3 * o[1] - a1 * o[3]), dt * (a1 * o[2] - a2 * o[1]) }
    local S0 = { { 0, -a3, a2 }, { a3, 0, -a1 }, { -a2, a1, 0 } }
    local S1 = { { 0, -o[3], o[2] }, { o[3], 0, -o[1] }, { -o[2], o[1], 0 } }
    local J = {}
    for r = 1, 3 do J[r] = {}; for c = 1, 3 do J[r][c] = (r == c and I[c] or 0) + dt * (S0[r][c] * I[c] - S1[r][c]) end end
    local function det(Mx) return Mx[1][1] * (Mx[2][2] * Mx[3][3] - Mx[2][3] * Mx[3][2]) - Mx[1][2] * (Mx[2][1] * Mx[3][3] - Mx[2][3] * Mx[3][1]) + Mx[1][3] * (Mx[2][1] * Mx[3][2] - Mx[2][2] * Mx[3][1]) end
    local D = det(J)
    local xs = {}
    for c = 1, 3 do
      local Mx = { { J[1][1], J[1][2], J[1][3] }, { J[2][1], J[2][2], J[2][3] }, { J[3][1], J[3][2], J[3][3] } }
      for r = 1, 3 do Mx[r][c] = f[r] end
      xs[c] = det(Mx) / D
    end
    b1, b2, b3 = a1 - xs[1], a2 - xs[2], a3 - xs[3]
  elseif name == "midpoint" then
    -- implicit midpoint, iterated to convergence: keeps E and |L| exactly
    b1, b2, b3 = a1, a2, a3
    for it = 1, 200 do
      local m1, m2, m3 = (a1 + b1) / 2, (a2 + b2) / 2, (a3 + b3) / 2
      local o1, o2, o3 = I[1] * m1, I[2] * m2, I[3] * m3
      local n1 = a1 + dt * (o2 * m3 - o3 * m2) / I[1]
      local n2 = a2 + dt * (o3 * m1 - o1 * m3) / I[2]
      local n3 = a3 + dt * (o1 * m2 - o2 * m1) / I[3]
      local d = math.abs(n1 - b1) + math.abs(n2 - b2) + math.abs(n3 - b3)
      b1, b2, b3 = n1, n2, n3
      if d < 1e-13 * (math.abs(a1) + math.abs(a2) + math.abs(a3)) then break end
    end
  elseif name == "exact" then
    -- symmetric body (I2 = I3): w1 constant, (w2, w3) turn by -k w1 dt, k = (I2 - I1)/I2
    local th = -(I[2] - I[1]) / I[2] * a1 * dt
    local c, s = math.cos(th), math.sin(th)
    b1, b2, b3 = a1, c * a2 - s * a3, s * a2 + c * a3
  end
  setAngVelXYZ(bd.o, qrot(x, y, z, w, b1, b2, b3))
end

local function state(bd)
  local x, y, z, w = qparts(bd.b)
  local Wx, Wy, Wz = getAngVelXYZ(bd.o)
  local a1, a2, a3 = qrot(x, y, z, w, Wx, Wy, Wz, true)
  local E = 0.5 * (I[1] * a1 * a1 + I[2] * a2 * a2 + I[3] * a3 * a3)
  local L1, L2, L3 = qrot(x, y, z, w, I[1] * a1, I[2] * a2, I[3] * a3)
  return E, L1, L2, L3, a1, math.sqrt(a2 * a2 + a3 * a3)
end
for _, bd in ipairs(bodies) do bd.E0, bd.L1, bd.L2, bd.L3 = state(bd) end

local T = 0
local function report()
  for _, bd in ipairs(bodies) do
    local E, L1, L2, L3, a1, ap = state(bd)
    local Ln = math.sqrt(L1 * L1 + L2 * L2 + L3 * L3)
    local L0 = math.sqrt(bd.L1 ^ 2 + bd.L2 ^ 2 + bd.L3 ^ 2)
    local cosang = (L1 * bd.L1 + L2 * bd.L2 + L3 * bd.L3) / (Ln * L0)
    print(string.format("t=%6.3f %-13s dE/E %+9.2e  d|L|/|L| %+9.2e  L dir %8.4f deg  w1 %9.3f  |wperp| %9.3f",
      T, bd.name, E / bd.E0 - 1, Ln / L0 - 1, math.deg(math.acos(math.min(1, cosang))), a1, ap))
  end
end
v.timeStep = 0
v:preSim(function(N)
  for s = 1, PER do
    for _, bd in ipairs(bodies) do lua(bd, DT) end
    v:stepSimulation(DT, 0, DT)
    T = T + DT
  end
  report()
end)
