-- Bullet's handling of free rigid-body rotation vs Euler's equations
local common = require "common"
local HZ = tonumber(os.getenv("DZ_HZ") or "600")
common.setTiming(1/60, 0, 1/60)          -- overridden: we step ourselves
v.gravity = btVector3(0, 0, 0)
local FLAGS = tonumber(os.getenv("DZ_FLAGS") or "8")
local I = btVector3(1, 2, 3)             -- kg m^2 (any units)
local s = Sphere(0.1, 1)
v:add(s)
local b = s.body
b:setMassProps(1, I)
b:setFlags(FLAGS)
b:setActivationState(4)
b:setDamping(0, 0)
-- spin about body y (intermediate) at 10 rad/s, nudged 0.01 rad/s about x
b:setAngularVelocity(btVector3(tonumber(os.getenv("DZ_NUDGE") or "0.01"), 10, 0))
local f = io.open(os.getenv("DZ_LOG"), "w")
local t = 0
local n = math.floor(HZ / 60 + 0.5)
v.timeStep, v.maxSubSteps, v.fixedTimeStep = 1/HZ, 0, 1/HZ
-- DZ_EULER=1: Bullet's gyroscopic term off; each step, advance the
-- body-frame angular velocity by Euler's equations (RK4), then rescale it so
-- kinetic energy and |angular momentum| stay exactly at their start values.
local EULER = os.getenv("DZ_EULER") == "1"
local Iv = { I.x, I.y, I.z }
local function bodyW()
  local B = b:getCenterOfMassTransform():getBasis()
  local w = b:getAngularVelocity()
  local c = { B:getColumn(0), B:getColumn(1), B:getColumn(2) }
  return { c[1].x*w.x + c[1].y*w.y + c[1].z*w.z, c[2].x*w.x + c[2].y*w.y + c[2].z*w.z,
           c[3].x*w.x + c[3].y*w.y + c[3].z*w.z }, c
end
local function deriv(w)
  return { (Iv[2]-Iv[3])*w[2]*w[3]/Iv[1], (Iv[3]-Iv[1])*w[3]*w[1]/Iv[2], (Iv[1]-Iv[2])*w[1]*w[2]/Iv[3] }
end
local function add(a, b, h) return { a[1]+h*b[1], a[2]+h*b[2], a[3]+h*b[3] } end
local E0, L0
local function eulerStep(h)
  local w, c = bodyW()
  if not E0 then
    E0 = Iv[1]*w[1]^2 + Iv[2]*w[2]^2 + Iv[3]*w[3]^2
    L0 = (Iv[1]*w[1])^2 + (Iv[2]*w[2])^2 + (Iv[3]*w[3])^2
  end
  local k1 = deriv(w); local k2 = deriv(add(w, k1, h/2)); local k3 = deriv(add(w, k2, h/2)); local k4 = deriv(add(w, k3, h))
  for i = 1, 3 do w[i] = w[i] + h/6 * (k1[i] + 2*k2[i] + 2*k3[i] + k4[i]) end
  -- gentle projection back onto E = E0 and |L|^2 = L0 (two scalings would fight; use E only then L)
  local E = Iv[1]*w[1]^2 + Iv[2]*w[2]^2 + Iv[3]*w[3]^2
  local sE = math.sqrt(E0 / E)
  for i = 1, 3 do w[i] = w[i] * sE end
  -- back to world
  b:setAngularVelocity(btVector3(c[1].x*w[1] + c[2].x*w[2] + c[3].x*w[3],
                                 c[1].y*w[1] + c[2].y*w[2] + c[3].y*w[3],
                                 c[1].z*w[1] + c[2].z*w[2] + c[3].z*w[3]))
end
v:preSim(function(N)
  for k = 1, n - 1 do
    if EULER then eulerStep(1/HZ) end
    v:stepSimulation(1/HZ, 0, 1/HZ)
  end
  if EULER then eulerStep(1/HZ) end
end)
v:postSim(function(N)
  t = t + n / HZ
  local B = b:getCenterOfMassTransform():getBasis()
  local w = b:getAngularVelocity()
  -- body-frame angular velocity: R^T w
  local c0, c1, c2 = B:getColumn(0), B:getColumn(1), B:getColumn(2)
  local w1 = c0.x*w.x + c0.y*w.y + c0.z*w.z
  local w2 = c1.x*w.x + c1.y*w.y + c1.z*w.z
  local w3 = c2.x*w.x + c2.y*w.y + c2.z*w.z
  f:write(string.format("%.5f,%.8f,%.8f,%.8f\n", t, w1, w2, w3))
  if N % 60 == 0 then f:flush() end
end)
