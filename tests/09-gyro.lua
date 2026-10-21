-- test body.gyroSolved: a body's gyroscopic term solved with its joints
--
-- A rigid body keeps its angular momentum L = I w, not its angular
-- velocity (Euler's equations, I dw/dt = -w x I w + torque). Bullet's own
-- term is applied outside the constraint solve and is skipped for small
-- bodies (in kg and cm, a bead's inertia has a determinant under
-- FLT_EPSILON). body.gyroSolved = true has bpp solve it inside the step,
-- as the linearly implicit midpoint rule, with the body answering its
-- joints and contacts through (I + dt/2 d(w x Iw)/dw)^-1. Checked here:
-- the flag; a free spinning body keeps its energy and angular momentum;
-- a body without the flag is left exactly as Bullet moves it; and a
-- hanging chain of spinning links stays still (a term added before the
-- step instead makes it shake itself apart).

local pass, fail = 0, 0
local function check(name, ok, detail)
  if ok then
    print("PASS " .. name)
    pass = pass + 1
  else
    print("FAIL " .. name .. (detail and (": " .. detail) or ""))
    fail = fail + 1
  end
end

v.gravity = btVector3(0, 0, 0)
v.timeStep = 0
local ident = btQuaternion(0, 0, 0, 1)
local DT = 1 / 1800

-- 1: the flag
local b0 = btRigidBody(1, btDefaultMotionState(btTransform(ident, btVector3(0, 0, 0))), btSphereShape(1), btVector3(1, 1, 1))
check("BPP_GYRO_MIDPOINT is 1024", BPP_GYRO_MIDPOINT == 1024)
check("a new body: Bullet's implicit term on, gyroSolved false", b0:getFlags() == 8 and b0.gyroSolved == false)
b0.gyroSolved = true
check("gyroSolved = true: bpp's flag on, Bullet's off", b0:getFlags() == 1024 and b0.gyroSolved == true)
b0:setFlags(1025)
b0.gyroSolved = false
check("gyroSolved = false: only bpp's flag cleared", b0:getFlags() == 1)

-- 2: free bodies, a chain-fountain link (kg, cm) spinning 1000 rad/s about
-- its axis and turning 600 across, and an asymmetric body
local M, RL, L = 0.0005 * 0.65 / 1.5, 0.225, 0.65
local IP = M * (L * L / 4 + 0.4 * RL * RL)
local cases = {
  { name = "link", I = btVector3(0.4 * M * RL * RL, IP, IP), w = btVector3(1000, 600, 0) },
  { name = "asymmetric", I = btVector3(1.0e-5, 2.0e-5, 3.2e-5), w = btVector3(30, 200, 15) },
}
local q0 = btQuaternion(btVector3(1, 2, 3):normalized(), 0.7)
local function basis(q) return btTransform(q, btVector3(0, 0, 0)):getBasis() end
local function mul(R, w) return btVector3(R:getRow(0):dot(w), R:getRow(1):dot(w), R:getRow(2):dot(w)) end
local function worldI(b, I, w)                      -- R diag(I) R^T w
  local R = basis(b:getOrientation())
  local a = mul(R:transpose(), w)
  return mul(R, btVector3(I.x * a.x, I.y * a.y, I.z * a.z))
end
local bodies = {}
for k, c in ipairs(cases) do
  for _, solved in ipairs({ true, false }) do
    local o = Sphere(0.1, M)
    o.collides = false
    v:add(o)
    local b = o.body
    b:setMassProps(M, c.I)
    b:setCenterOfMassTransform(btTransform(q0, btVector3(10 * k, 0, solved and 0 or 5)))
    b:setActivationState(4)
    b:setDamping(0, 0)
    if solved then b.gyroSolved = true else b:setFlags(0) end
    b:setAngularVelocity(mul(basis(q0), c.w))
    bodies[#bodies + 1] = { c = c, b = b, solved = solved }
  end
end
local function state(bd)
  local w = bd.b:getAngularVelocity()
  local Lw = worldI(bd.b, bd.c.I, w)
  return 0.5 * w:dot(Lw), Lw
end
for _, bd in ipairs(bodies) do bd.E0, bd.L0 = state(bd); bd.w0 = bd.b:getAngularVelocity() end
for i = 1, 1800 do v:stepSimulation(DT, 0, DT) end
for _, bd in ipairs(bodies) do
  local E, Lw = state(bd)
  local dE, dL = E / bd.E0 - 1, Lw:length() / bd.L0:length() - 1
  local ang = math.deg(math.acos(math.min(1, Lw:dot(bd.L0) / (Lw:length() * bd.L0:length()))))
  if bd.solved then
    check(bd.c.name .. ", solved, 1 s: energy and |L| kept to 1e-4, L's direction to 30 deg",
          math.abs(dE) < 1e-4 and math.abs(dL) < 1e-4 and ang < 30,
          string.format("dE/E %.1e, d|L|/|L| %.1e, %.1f deg", dE, dL, ang))
  else
    local w = bd.b:getAngularVelocity()
    check(bd.c.name .. ", not marked: its angular velocity untouched (Bullet's, term off)",
          w.x == bd.w0.x and w.y == bd.w0.y and w.z == bd.w0.z)
  end
end

-- 3: a hanging chain of 20 links, each spinning 1000 rad/s about its own
-- axis (an equilibrium: the twist is free), cone-twist joints bending 30
-- degrees, 1800 steps a second, 2 s. Nothing can grow: the term does no work.
v.gravity = btVector3(0, -981, 0)
v:setErp(0.5)
v:setSolverIterations(20)
local IA = 0.4 * M * RL * RL
local SHAPE = btCapsuleShapeX(RL, L - 2 * RL)
local down = btQuaternion(btVector3(0, 0, 1), -math.pi / 2)    -- each link's x axis pointing down
local N, TOP, S0 = 20, 100, 1000
local links = {}
local held = Sphere(0.05, 0); held.collides = false; held.pos = btVector3(100, TOP, 0); v:add(held)
for i = 1, N do
  local o = Sphere(0.1, M)
  o.collides = false
  v:add(o)
  local b = btRigidBody(M, btDefaultMotionState(btTransform(down, btVector3(100, TOP - (i - 0.5) * L, 0))), SHAPE, btVector3(IA, IP, IP))
  o.body = b
  b:setActivationState(4)
  b:setDamping(0, 0)
  b.gyroSolved = true
  links[i] = { o = o, b = b }
end
local function cone(a, b, pa, pb, lim)
  local c = btConeTwistConstraint(a, b, btTransform(ident, pa), btTransform(ident, pb))
  c:setLimit(5, lim); c:setLimit(4, lim); c:setLimit(3, math.pi)
  v:addConstraint(c)
end
cone(links[1].b, held.body, btVector3(-L / 2, 0, 0), btVector3(0, 0, 0), math.pi * 0.95)
for i = 1, N - 1 do cone(links[i].b, links[i + 1].b, btVector3(L / 2, 0, 0), btVector3(-L / 2, 0, 0), math.rad(30)) end
local seed = 12345
local function rnd() seed = (seed * 1103515245 + 12345) % 2147483648; return seed / 2147483648 - 0.5 end
for i = 1, N do links[i].b:setAngularVelocity(btVector3(5 * rnd(), -S0, 5 * rnd())) end
local function measure()
  local E, pp = 0, 0
  for i = 1, N do
    local b = links[i].b
    local e = basis(b:getOrientation()):getColumn(0)     -- the link's axis
    local w, vel = b:getAngularVelocity(), b:getLinearVelocity()
    local s = w:dot(e)
    local p2 = w:dot(w) - s * s
    E = E + 0.5 * M * vel:dot(vel) + 0.5 * (IA * s * s + IP * p2) + M * 981 * b:getCenterOfMassPosition().y
    pp = pp + p2
  end
  return E, math.sqrt(pp / N)
end
for i = 1, 90 do v:stepSimulation(DT, 0, DT) end       -- (the joints take up their slack first)
local E0 = measure()
local KE = N * 0.5 * IA * S0 * S0
local worst, dEmax = 0, 0
for i = 1, 3600 do
  v:stepSimulation(DT, 0, DT)
  if i % 180 == 0 then
    local E, p = measure()
    worst, dEmax = math.max(worst, p), math.max(dEmax, math.abs(E - E0) / KE)
  end
end
check("hanging chain of spinning links, solved, 2 s: turning across stays under 5 rad/s, energy within 1e-3 of the spin's",
      worst < 5 and dEmax < 1e-3, string.format("across up to %.2f rad/s, |dE| %.1e of the spin energy", worst, dEmax))

print(string.format("\n%d passed, %d failed", pass, fail))
