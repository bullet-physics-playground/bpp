-- rattleback feasibility test (headless)
local common = require "common"
local function env(n, d) return tonumber(os.getenv(n) or "") or d end
local A, B, C = 6.0, 1.5, 1.2            -- half-length (x), half-width (z), depth (y), cm
local SKEW = math.rad(env("RB_SKEW", 8)) -- hull turned this much from the mass axes
local RHO = 0.0012                       -- kg/cm^3 (plastic)
local HZ = env("RB_HZ", 1200)
local EULER = (os.getenv("RB_EULER") == "1")
local G = 981
v.gravity = btVector3(0, -G, 0)
v.timeStep, v.maxSubSteps, v.fixedTimeStep = 1 / HZ, 0, 1 / HZ
local n = math.floor(HZ / 60 + 0.5)

local m = (2 / 3) * math.pi * A * B * C * RHO
local y0 = -3 * C / 8                    -- centre of mass below the flat top
local Ixx = m * (C * C + B * B) / 5 - m * y0 * y0
local Iyy = m * (A * A + B * B) / 5
local Izz = m * (A * A + C * C) / 5 - m * y0 * y0
local IV = { Ixx, Iyy, Izz }

-- hull: half-ellipsoid surface, in the frame of the mass axes (origin at COM)
local hull = btConvexHullShape()
local cs, sn = math.cos(SKEW), math.sin(SKEW)
local NU, NV = 96, 32
local cnt = 0
for i = 0, NV do
  local th = (math.pi / 2) * i / NV        -- 0 = bottom pole, pi/2 = rim
  for j = 0, NU - 1 do
    local ph = 2 * math.pi * j / NU
    local x = A * math.sin(th) * math.cos(ph)
    local z = B * math.sin(th) * math.sin(ph)
    local y = -C * math.cos(th) - y0
    local xr, zr = cs * x - sn * z, sn * x + cs * z   -- turn the hull by SKEW about y
    cnt = cnt + 1
    hull:addPoint(btVector3(xr, y, zr), false)
    if i == 0 then break end
  end
end
hull:recalcLocalAabb()
hull:setMargin(0.01)

local floor = Plane(0, 1, 0, 0, 200); floor.friction = 0.6; v:add(floor)
local s = Sphere(0.5, 1)
local body = btRigidBody(m, btDefaultMotionState(btTransform(btQuaternion(0, 0, 0, 1), btVector3(0, C + y0 + 0.012, 0))),
                         hull, btVector3(Ixx, Iyy, Izz))
s.body = body
v:add(s)
body:setFriction(0.6); body:setRestitution(0); body:setDamping(0, 0); body:setActivationState(4)
if os.getenv("RB_CPT") then body:setContactProcessingThreshold(tonumber(os.getenv("RB_CPT"))) end
body:setFlags(EULER and 0 or 8)
local W0 = env("RB_SPIN", 6)            -- rad/s about vertical
body:setAngularVelocity(btVector3(env("RB_ROCK", 0.02), W0, env("RB_PITCH", 0)))

local function basis() local Bm = body:getCenterOfMassTransform():getBasis(); return { Bm:getColumn(0), Bm:getColumn(1), Bm:getColumn(2) } end
local function deriv(w) return { (IV[2]-IV[3])*w[2]*w[3]/IV[1], (IV[3]-IV[1])*w[3]*w[1]/IV[2], (IV[1]-IV[2])*w[1]*w[2]/IV[3] } end
local function eulerStep(h)
  local c = basis(); local W = body:getAngularVelocity()
  local w = { c[1].x*W.x+c[1].y*W.y+c[1].z*W.z, c[2].x*W.x+c[2].y*W.y+c[2].z*W.z, c[3].x*W.x+c[3].y*W.y+c[3].z*W.z }
  local function add(a, d, k) return { a[1]+k*d[1], a[2]+k*d[2], a[3]+k*d[3] } end
  local k1 = deriv(w); local k2 = deriv(add(w,k1,h/2)); local k3 = deriv(add(w,k2,h/2)); local k4 = deriv(add(w,k3,h))
  for i = 1, 3 do w[i] = w[i] + h/6*(k1[i]+2*k2[i]+2*k3[i]+k4[i]) end
  body:setAngularVelocity(btVector3(c[1].x*w[1]+c[2].x*w[2]+c[3].x*w[3], c[1].y*w[1]+c[2].y*w[2]+c[3].y*w[3], c[1].z*w[1]+c[2].z*w[2]+c[3].z*w[3]))
end
-- rolling resistance: constant moment delta*m*g against rolling (horizontal
-- part of the spin) about the contact, as in Gomboc Drop C
local DELTA = env("RB_ROLL", 0) * 1e-4    -- microns -> cm
local SPINF = env("RB_SPINF", 0)          -- rad/s^2 against spin about the vertical
local function resist(h)
  if DELTA <= 0 and SPINF <= 0 then return end
  local W = body:getAngularVelocity(); local V = body:getLinearVelocity()
  local wx, wy, wz, vx, vy, vz = W.x, W.y, W.z, V.x, V.y, V.z
  local _, py = getPosXYZ(s)
  local r = py
  local w = math.sqrt(wx*wx + wz*wz)
  if w > 0 and DELTA > 0 then
    local c = basis(); local ax, az = wx/w, wz/w; local k2 = 0
    for i = 1, 3 do local d = ax*c[i].x + az*c[i].z; k2 = k2 + IV[i]/m*d*d end
    local dw = math.min(w, DELTA*G/(k2 + r*r)*h)
    local dwx, dwz = -dw*ax, -dw*az
    wx, wz = wx + dwx, wz + dwz; vx, vz = vx - dwz*r, vz + dwx*r
  end
  if SPINF > 0 then local d = math.min(math.abs(wy), SPINF*h); wy = wy - (wy > 0 and d or -d) end
  body:setAngularVelocity(btVector3(wx, wy, wz)); body:setLinearVelocity(btVector3(vx, vy, vz))
end
v:preSim(function(N)
  for k = 1, n - 1 do if EULER then eulerStep(1/HZ) end; resist(1/HZ); v:stepSimulation(1/HZ, 0, 1/HZ) end
  if EULER then eulerStep(1/HZ) end; resist(1/HZ)
end)
local f = io.open(os.getenv("RB_LOG"), "w")
local t = 0
v:postSim(function(N)
  t = t + n / HZ
  local W = body:getAngularVelocity(); local c = basis()
  local roll = math.deg(math.asin(math.max(-1, math.min(1, c[1].y))))   -- long axis tilt (pitch)
  local side = math.deg(math.asin(math.max(-1, math.min(1, c[3].y))))   -- sideways rock
  local _, py = getPosXYZ(s)
  f:write(string.format("%.4f,%.5f,%.4f,%.4f,%.4f\n", t, W.y, roll, side, py))
  if N % 60 == 0 then f:flush() end
end)
print(string.format("mass %.4f kg, I = %.4f %.4f %.4f kg cm^2, hull points %d", m, Ixx, Iyy, Izz, cnt))
