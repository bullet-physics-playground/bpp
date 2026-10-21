-- A hanging chain of the chain fountain's heap links (cone-twist joints, 30 deg, twist free, ERP 0.5,
-- 20 iterations, no contacts), every link spinning about its own axis at HG_S rad/s, a little
-- turning across (HG_P rad/s, random). Physics: the spin is an equilibrium (twist is free); the
-- links' turning across should stay small and the total energy should not grow.
-- HG_GYRO = exact | midpoint | implicit (Lua, before each step) | ab2 | euler1 | gyrostat | solver (body.gyroSolved,
-- flag 1024: bpp since 20 Oct 2026) | 0 ; HG_STEPS steps a second, HG_N links, HG_ERP, HG_IT, HG_P2P=1
-- (ball joints). Run: xvfb-run -a bpp -f gyro-hang.lua -n 40. (conefix: an attempt, broken, ignore.)
local function envnum(n, d) return tonumber(os.getenv(n) or "") or d end
local G = 981
v.gravity = btVector3(0, -G, 0)
local N = envnum("HG_N", 60)
local M = 0.0005 * 0.65 / 1.5
local RL, L = 0.225, 0.65
local IP, IA = M * (L * L / 4 + 0.4 * RL * RL), 0.4 * M * RL * RL
local K = (IP - IA) / IP
local STEPS = envnum("HG_STEPS", 1800)
local DT = 1 / STEPS
local GYRO = os.getenv("HG_GYRO") or "exact"
local S0, P0 = envnum("HG_S", 300), envnum("HG_P", 5)
local SHAPE = btCapsuleShapeX(RL, L - 2 * RL)
local rot = btQuaternion(btVector3(0, 0, 1), -math.pi / 2)    -- +x down
local ident = btQuaternion(0, 0, 0, 1)
local STOP = math.rad(30)
local seed = 12345
local function rnd() seed = (seed * 1103515245 + 12345) % 2147483648; return seed / 2147483648 - 0.5 end
local links = {}
local top = 100
local anchor = btRigidBody(0, btDefaultMotionState(btTransform(ident, btVector3(0, top, 0))), SHAPE, btVector3(0, 0, 0))
local ao = Mesh and nil
for i = 1, N do
  local mid = btVector3(0, top - (i - 0.5) * L, 0)
  local o = Sphere(0.1, M)
  o.collides = false
  v:add(o)
  local b = btRigidBody(M, btDefaultMotionState(btTransform(rot, mid)), SHAPE, btVector3(IA, IP, IP))
  o.body = b
  b:setActivationState(4); b:setDamping(0, 0)
  if GYRO ~= "bullet" then b:setFlags(GYRO == "solver" and 1024 or 0) end
  links[i] = { o = o, b = b }
end
-- joints: top link's near end (-L/2, i.e. up) to the anchor; link i's +L/2 (down) to link i+1's -L/2
local holdA = Sphere(0.05, 0); holdA.collides = false; holdA.pos = btVector3(0, top, 0); v:add(holdA)
local c0 = btConeTwistConstraint(links[1].b, holdA.body, btTransform(ident, btVector3(-L / 2, 0, 0)), btTransform(ident, btVector3(0, 0, 0)))
c0:setLimit(5, math.pi * 0.95); c0:setLimit(4, math.pi * 0.95); c0:setLimit(3, math.pi)
v:addConstraint(c0)
for i = 1, N - 1 do
  if os.getenv("HG_P2P") then
    v:addConstraint(btPoint2PointConstraint(links[i].b, links[i + 1].b, btVector3(L / 2, 0, 0), btVector3(-L / 2, 0, 0)))
  else
  local c = btConeTwistConstraint(links[i].b, links[i + 1].b, btTransform(ident, btVector3(L / 2, 0, 0)), btTransform(ident, btVector3(-L / 2, 0, 0)))
  c:setLimit(5, STOP); c:setLimit(4, STOP); c:setLimit(3, math.pi)
  v:addConstraint(c)
  end
end
local SP = {}
for i = 1, N do
  setAngVelXYZ(links[i].o, P0 * rnd(), -S0, P0 * rnd())   -- axis is -y in the world
  SP[i] = 0
end
v:setErp(envnum("HG_ERP", 0.5))
v:setSolverIterations(envnum("HG_IT", 20))
v.timeStep = 0

local function axisOf(b)
  local q = b:getOrientation()
  local x, y, z, w = q:getX(), q:getY(), q:getZ(), q:getW()
  return 1 - 2 * (y * y + z * z), 2 * (x * y + w * z), 2 * (x * z - w * y)
end
local QOLD = {}
local function qmul(a, b)   -- {x,y,z,w}
  return { a[4] * b[1] + a[1] * b[4] + a[2] * b[3] - a[3] * b[2],
           a[4] * b[2] - a[1] * b[3] + a[2] * b[4] + a[3] * b[1],
           a[4] * b[3] + a[1] * b[2] - a[2] * b[1] + a[3] * b[4],
           a[4] * b[4] - a[1] * b[1] - a[2] * b[2] - a[3] * b[3] }
end
local function qexp(wx, wy, wz, dt)
  local n = math.sqrt(wx * wx + wy * wy + wz * wz)
  if n * dt < 1e-12 then return { 0, 0, 0, 1 } end
  local h = 0.5 * n * dt
  local f = math.sin(h) / n
  return { wx * f, wy * f, wz * f, math.cos(h) }
end
local function post(dt)
  if GYRO ~= "conefix" then return end
  for i = 1, N do
    local l = links[i]
    local q0 = QOLD[i]
    local x, y, z, w = q0[1], q0[2], q0[3], q0[4]
    local ex, ey, ez = 1 - 2 * (y * y + z * z), 2 * (x * y + w * z), 2 * (x * z - w * y)
    local Wx, Wy, Wz = getAngVelXYZ(l.o)
    local s = Wx * ex + Wy * ey + Wz * ez
    local q = qmul(qmul(qexp(Wx - s * ex, Wy - s * ey, Wz - s * ez, dt), q0), qexp(s, 0, 0, dt))
    local px, py, pz = getPosXYZ(l.o)
    l.b:setCenterOfMassTransform(btTransform(btQuaternion(q[1], q[2], q[3], q[4]), btVector3(px, py, pz)))
  end
end
local function spin(dt)
  if GYRO == "0" or GYRO == "bullet" or GYRO == "solver" then return end
  if GYRO == "gyrostat" then
    for i = 1, N do
      local l = links[i]
      local ex, ey, ez = axisOf(l.b)
      local Wx, Wy, Wz = getAngVelXYZ(l.o)
      local s = Wx * ex + Wy * ey + Wz * ez
      SP[i] = SP[i] + s                                   -- the spin lives in Lua
      local px, py, pz = Wx - s * ex, Wy - s * ey, Wz - s * ez
      local cx, cy, cz = ey * pz - ez * py, ez * px - ex * pz, ex * py - ey * px
      local th = IA / IP * SP[i] * dt
      local c, sn = math.cos(th), math.sin(th)
      setAngVelXYZ(l.o, c * px + sn * cx, c * py + sn * cy, c * pz + sn * cz)
    end
    return
  end
  if GYRO == "ab2" or GYRO == "euler1" then
    for i = 1, N do
      local l = links[i]
      local ex, ey, ez = axisOf(l.b)
      local Wx, Wy, Wz = getAngVelXYZ(l.o)
      local s = Wx * ex + Wy * ey + Wz * ez
      local px, py, pz = Wx - s * ex, Wy - s * ey, Wz - s * ez
      -- I^-1 (-w x I w) = -k s (e x wperp)
      local gx, gy, gz = -K * s * (ey * pz - ez * py), -K * s * (ez * px - ex * pz), -K * s * (ex * py - ey * px)
      local pr = l.prev or { gx, gy, gz }
      local ax, ay, az = gx, gy, gz
      if GYRO == "ab2" then ax, ay, az = 1.5 * gx - 0.5 * pr[1], 1.5 * gy - 0.5 * pr[2], 1.5 * gz - 0.5 * pr[3] end
      l.prev = { gx, gy, gz }
      setAngVelXYZ(l.o, Wx + ax * dt, Wy + ay * dt, Wz + az * dt)
    end
    return
  end
  if GYRO == "conefix" then
    for i = 1, N do local q = links[i].b:getOrientation(); QOLD[i] = { q:getX(), q:getY(), q:getZ(), q:getW() } end
  end
  for i = 1, N do
    local l = links[i]
    local ex, ey, ez = axisOf(l.b)
    local Wx, Wy, Wz = getAngVelXYZ(l.o)
    local s = Wx * ex + Wy * ey + Wz * ez
    local px, py, pz = Wx - s * ex, Wy - s * ey, Wz - s * ez
    local cx, cy, cz = ey * pz - ez * py, ez * px - ex * pz, ex * py - ey * px
    local th = -K * s * dt
    local c, sn
    if GYRO == "exact" or GYRO == "conefix" then c, sn = math.cos(th), math.sin(th)
    elseif GYRO == "midpoint" then local h = th / 2; c, sn = (1 - h * h) / (1 + h * h), 2 * h / (1 + h * h)
    else c, sn = 1 / (1 + th * th), th / (1 + th * th) end
    setAngVelXYZ(l.o, s * ex + c * px + sn * cx, s * ey + c * py + sn * cy, s * ez + c * pz + sn * cz)
  end
end
local function measure()
  local E, ss, pp, xx = 0, 0, 0, 0
  for i = 1, N do
    local l = links[i]
    local ex, ey, ez = axisOf(l.b)
    local Wx, Wy, Wz = getAngVelXYZ(l.o)
    local vx, vy, vz = getVelXYZ(l.o)
    local x, y, z = getPosXYZ(l.o)
    local s = Wx * ex + Wy * ey + Wz * ez
    local p2 = Wx * Wx + Wy * Wy + Wz * Wz - s * s
    s = s + SP[i]
    E = E + 0.5 * M * (vx * vx + vy * vy + vz * vz) + 0.5 * (IA * s * s + IP * p2) + M * G * y
    ss, pp, xx = ss + s * s, pp + p2, math.max(xx, math.sqrt(x * x + z * z))
  end
  return E, math.sqrt(ss / N), math.sqrt(pp / N), xx
end
local E0, KE0
local T, PER = 0, math.floor(STEPS / 20 + 0.5)
v:preSim(function(n)
  if not E0 then
    E0 = measure()
    KE0 = 0
    for i = 1, N do KE0 = KE0 + 0.5 * IA * S0 * S0 end
  end
  for k = 1, PER do
    spin(DT)
    v:stepSimulation(DT, 0, DT)
    post(DT)
    T = T + DT
  end
  local E, s, p, xx = measure()
  print(string.format("t=%5.2f %-8s %5d steps/s  rms spin %7.1f  rms across %8.2f rad/s  max off axis %6.3f cm  (E-E0)/KEspin0 %+8.4f",
    T, GYRO, STEPS, s, p, xx, (E - E0) / KE0))
end)
