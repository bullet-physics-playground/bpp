--
-- The Double Cone -- Euler's Cabinet of Curiosities
--
-- Two cones joined base to base, set on two rails that rise and spread
-- apart like a V: let go at the low, narrow end, the double cone rolls up
-- to the high, wide end -- uphill, it seems. It doesn't really: as the rails
-- spread, they meet the cone nearer its points, where it's thinner, so it
-- sinks between them faster than they rise. Its centre of mass goes down
-- all the way. (A favourite of 18th-century lecture rooms, where
-- instrument makers sold it as a "mechanical paradox".)
--
-- Three tracks, back to front:
--   back    (brass cone)   rails rising 1.5 cm over 50: the cone rolls up
--   middle  (cylinder)     the same rails: a plain cylinder rolls down
--   front   (steel cone)   rails rising 5 cm over 50: too steep; the same
--                          cone rolls down
--
-- Theory: the rails rise at a slope tan(theta) and spread at tan(phi) on
-- each side; where the rails meet the cone, its radius shrinks by R/H for
-- each cm out from the middle (R its radius, H each cone's length). So the
-- centre goes down as it rolls up if
--     tan(theta) < tan(phi) R / H
-- The console gives the centre's height all along, against the height the
-- geometry gives it (worked out exactly, rails' thickness and all), and
-- its energy: rolling without slipping, it keeps it.
--
-- THE CONE: radius 5 cm at the middle, each cone 12 cm long, 400 g, solid
-- (moment of inertia 3/10 m R^2 about its axis). The rails: 8 mm brass
-- rods, 5 cm apart at the low end and 19 cm at the high end, 50 cm long.
--
-- PHYSICS: Bullet, its own contacts: the cone a compound of two cone shapes,
-- the cylinder a cylinder shape, each rail a row of 10 cm capsules end to
-- end (Bullet finds contacts on one long rod less surely); friction 0.81
-- where they touch (0.9 on the rails and on the rollers: Bullet multiplies
-- the two), high, so nothing slips. 2400 physics steps a second.
--
-- Keys
--   R   set them going again
--   Z   slow motion (1/4) <-> real time
--
-- Units: centimetres, kilograms, seconds.
-- Headless testing: DC_SPEED, DC_STEPS, DC_LOG=file.csv.
--

local common = require "common"

local DIR = "double-cone-meshes/"
for _, dir in ipairs({ DIR, "demo/WyomingWill/DoubleCone/" .. DIR }) do
  local f = io.open(dir .. "double-cone.obj", "r")
  if f then f:close(); DIR = dir; break end
end

local G = 981
local function envnum(n, d) return tonumber(os.getenv(n) or "") or d end
local function param(...) v:addParam(...) end
param("speed", envnum("DC_SPEED", 1), 0.05, 2, 0.05, "simulated seconds per real second (Z: 1/4 <-> 1)")
param("steps", envnum("DC_STEPS", 2400), 600, 9600, 600, "physics steps per simulated second")

local STEP, NSTEPS, FRAME_DT = 1 / 2400, 40, 1 / 60
local function applyTiming()
  local speed = v:getParam("speed")
  NSTEPS = math.max(1, math.floor(v:getParam("steps") * speed / 60 + 0.5))
  FRAME_DT = speed / 60
  STEP = FRAME_DT / NSTEPS
  v.animationPeriod = 16
  common.setTiming(STEP, 0, STEP)
end

-- ---------------------------------------------------------------------
-- a pause at every start: one frame to put everything in place, then it
-- all stands still for HOLD_S seconds (half a second), so you see how it begins --
-- bpp's own physics step stopped too (a zero time step) -- and then it
-- carries on from there, exactly as if there had been no pause
-- ---------------------------------------------------------------------
local HOLD_FRAMES = math.floor(envnum("HOLD_S", 0.5) * 60 + 0.5)
local holdArm, holdLeft, holdNow = false, 0, false
local function holdStart() holdArm, holdLeft = true, 0 end
local function holdPre()            -- first thing before each step: true while it stands still
  if holdLeft > 0 then
    holdLeft = holdLeft - 1
    holdNow = true
    v.timeStep = 0
    return true
  end
  if holdNow then holdNow = false; applyTiming() end
  if holdArm then holdArm, holdLeft = false, HOLD_FRAMES end
  return false
end
applyTiming()
v.gravity = btVector3(0, -G, 0)
v:setSolverIterations(30)

local Q0 = btQuaternion(0, 0, 0, 1)
local function block(sx, sy, sz, x, y, z, col, q)
  local c = Cube(sx, sy, sz, 0)
  c.trans = btTransform(q or Q0, btVector3(x, y, z))
  c.col = col
  c.collides = false
  v:add(c)
  return c
end

-- ---------------------------------------------------------------------
-- the table and the three tracks
-- ---------------------------------------------------------------------
local TABLE_Y = 0
block(96, 3, 104, 0, TABLE_Y - 1.5, 0, "#7a4a24")
for _, x in ipairs({ -44, 44 }) do
  for _, z in ipairs({ -48, 48 }) do block(3, 72, 3, x, TABLE_Y - 3 - 36, z, "#4e2e15") end
end
local floor = Plane(0, 1, 0, TABLE_Y - 75, 300)
floor.col = "#3b3f45"
v:add(floor)

local R, H = 5.0, 12.0                     -- the double cone: radius at the middle, each cone's length
local RC, LC = 3.0, 26.0                   -- the cylinder
local MASS = 0.40
local RHO = 0.4                            -- the rails' radius
local L, X0 = 50, -25                      -- the rails: their length, where they start (x)
local D0, D1 = 2.5, 9.5                    -- each rail's distance from the middle, at the low and high ends
local TANPHI = (D1 - D0) / L
local Y0 = 12                              -- the rails' centres at the low end, above the table
local MARGIN = 0.01                       -- (the cones' collision margin, on their surface)
local TANG = R / H                         -- the cone's taper
local COSG = math.cos(math.atan(TANG))

local TRACKS = {
  { name = "Back (brass), a double cone on rails rising 1.5 cm -- rolls up", short = "Back", z = -30, rise = 1.5,
    kind = "cone", col = "#c9a23a", s0 = 7 },
  { name = "Middle, a cylinder on the same rails -- rolls down", short = "Middle", z = 0, rise = 1.5,
    kind = "cylinder", col = "#8a5a2b", s0 = 38 },
  { name = "Front (steel), the same double cone on rails rising 5 cm -- rolls down", short = "Front", z = 30, rise = 5,
    kind = "cone", col = "#a8adb5", s0 = 30 },
}

local BRASS, POST = "#c8a04a", "#4e2e15"
local function railPoint(tr, side, s)
  return X0 + s, TABLE_Y + Y0 + s * tr.rise / L, tr.z + side * (D0 + s * TANPHI)
end
-- a rail: a static cylinder along its line
local function rail(tr, side)
  local xa, ya, za = railPoint(tr, side, -2)
  local xb, yb, zb = railPoint(tr, side, L + 2)
  local dx, dy, dz = xb - xa, yb - ya, zb - za
  local len = math.sqrt(dx * dx + dy * dy + dz * dz)
  -- turn z onto the rail's direction
  local ux, uy, uz = dx / len, dy / len, dz / len
  local ax, ay, az = -uy, ux, 0                       -- z x u
  local al = math.sqrt(ax * ax + ay * ay + az * az)
  local q = btQuaternion(btVector3(ax / al, ay / al, az / al), math.acos(uz))
  local c = Cylinder(RHO, len, 0)
  c.trans = btTransform(q, btVector3((xa + xb) / 2, (ya + yb) / 2, (za + zb) / 2))
  c.col = BRASS
  c.collides = false
  v:add(c)
  -- (what the rollers touch: short capsules end to end along the rail --
  -- the same round rod, but Bullet finds contacts on short pieces more
  -- surely than on one long one)
  local shape = btCompoundShape(true)
  local SEG = 10
  local n = math.ceil(len / (SEG - 0.5))
  for k = 0, n - 1 do
    local zc = -len / 2 + SEG / 2 + k * (len - SEG) / (n - 1)
    shape:addChildShape(btTransform(Q0, btVector3(0, 0, zc)), btCapsuleShapeZ(RHO, SEG - 2 * RHO))
  end
  local col = Sphere(0.01, 0)
  local body = btRigidBody(0, btDefaultMotionState(btTransform(q, btVector3((xa + xb) / 2, (ya + yb) / 2, (za + zb) / 2))),
                           shape, btVector3(0, 0, 0))
  col.body = body
  col.col = BRASS
  v:add(col)
  body:setFriction(0.9)
  body:setRestitution(0)
  -- posts under it, and stops at its ends
  for _, s in ipairs({ 0, L }) do
    local x, y, z = railPoint(tr, side, s)
    block(1.2, y - RHO - TABLE_Y, 1.2, x, TABLE_Y + (y - RHO - TABLE_Y) / 2, z, POST)
  end
  for _, s in ipairs({ -1.2, L + 1.2 }) do
    local x, y, z = railPoint(tr, side, s)
    local st = Cube(1.2, 3.0, 1.6, 0)
    st.trans = btTransform(Q0, btVector3(x, y + 1.2, z))
    st.col = POST
    st.friction = 0.5
    v:add(st)
  end
end
for _, tr in ipairs(TRACKS) do
  tr.tanTheta = tr.rise / L
  rail(tr, -1); rail(tr, 1)
end

-- ---------------------------------------------------------------------
-- the rollers
-- ---------------------------------------------------------------------
local function coneShape()
  local s = btCompoundShape(true)
  for _, side in ipairs({ -1, 1 }) do
    local c = btConeShapeZ(R, H)            -- (its point at +H/2 along z, its base at -H/2)
    c:setMargin(MARGIN)
    local q = side > 0 and Q0 or btQuaternion(btVector3(1, 0, 0), math.pi)
    s:addChildShape(btTransform(q, btVector3(0, 0, side * H / 2)), c)
  end
  return s
end
local IAX_CONE = 0.3 * MASS * R * R                        -- about its axis
local IPERP_CONE = MASS * (3 / 20 * R * R + H * H / 10)    -- across it, through the middle
local IAX_CYL = 0.5 * MASS * RC * RC
local IPERP_CYL = MASS * (RC * RC / 4 + LC * LC / 12)
local KEYS = {}
for _, tr in ipairs(TRACKS) do
  local shape, I1, I3, mesh, stripes
  if tr.kind == "cone" then
    shape, I1, I3, mesh, stripes = coneShape(), IPERP_CONE, IAX_CONE, "double-cone.obj", "double-cone-stripes.obj"
  else
    shape = btCylinderShapeZ(btVector3(RC, RC, LC / 2))
    I1, I3, mesh, stripes = IPERP_CYL, IAX_CYL, "cylinder.obj", "cylinder-stripes.obj"
  end
  local m = Mesh(DIR .. mesh, 0, false)
  local body = btRigidBody(MASS, btDefaultMotionState(btTransform(Q0, btVector3(0, 50, tr.z))), shape,
                           btVector3(I1, I1, I3))
  m.body = body
  m.col = tr.col
  v:add(m)
  body:setActivationState(4)
  body:setDamping(0, 0)
  body:setFriction(0.9)
  body:setRestitution(0)
  local st = Mesh(DIR .. stripes, 0, false)
  st.col = "#3a2412"
  st.collides = false
  v:add(st)
  tr.m, tr.b, tr.st, tr.I = m, body, st, { I1, I1, I3 }
  KEYS[objectKey(m)] = tr
end

-- ---------------------------------------------------------------------
-- the geometry: where the centre should be, for the roller at x
-- ---------------------------------------------------------------------
-- (the cone touching a rail: the rail's centre line stays RHO + MARGIN
-- off the cone's surface, which is the same as touching a cone whose
-- radius is more by (RHO + MARGIN) / cos(taper))
local RP = R + (RHO + MARGIN) / COSG
local HP = RP / TANG
-- how far the rail's centre line is outside the (shrunk) cone with its
-- centre at (xc, y): the least, along the rail
local function clearance(tr, xc, y)
  local function at(s)
    local px, py, pz = railPoint(tr, 1, s)
    local a = math.abs(pz - tr.z)
    local q = math.sqrt((px - xc) ^ 2 + (py - y) ^ 2)
    return q - math.max(0, RP * (1 - a / HP))
  end
  local s0 = xc - X0
  local best, bs = 1e9, s0
  for k = -40, 40 do
    local s = s0 + k * 0.25
    local c = at(s)
    if c < best then best, bs = c, s end
  end
  local lo, hi = bs - 0.25, bs + 0.25
  for _ = 1, 50 do
    local m1, m2 = lo + (hi - lo) * 0.382, lo + (hi - lo) * 0.618
    if at(m1) < at(m2) then hi = m2 else lo = m1 end
  end
  return at((lo + hi) / 2)
end
local function predictY(tr, xc)
  local _, yr, _ = railPoint(tr, 1, xc - X0)
  if tr.kind == "cylinder" then
    return yr + (RC + RHO) / math.cos(math.atan(tr.tanTheta))
  end
  local lo, hi = yr - 1, yr + R + 2
  for _ = 1, 60 do
    local mid = (lo + hi) / 2
    if clearance(tr, xc, mid) < 0 then lo = mid else hi = mid end
  end
  return (lo + hi) / 2
end

-- ---------------------------------------------------------------------
-- setting them going, and watching them
-- ---------------------------------------------------------------------
local t = 0
local function energy(tr)
  local b = tr.b
  local Bm = b:getCenterOfMassTransform():getBasis()
  local W, V = b:getAngularVelocity(), b:getLinearVelocity()
  local ke = 0.5 * MASS * (V.x * V.x + V.y * V.y + V.z * V.z)
  for i = 0, 2 do
    local c = Bm:getColumn(i)
    local w = c.x * W.x + c.y * W.y + c.z * W.z
    ke = ke + 0.5 * tr.I[i + 1] * w * w
  end
  return ke + MASS * G * b:getCenterOfMassPosition().y
end

local function setGoing()
  holdStart()
  t = 0
  print("\n--- set going ---")
  for _, tr in ipairs(TRACKS) do
    local x = X0 + tr.s0
    local y = predictY(tr, x) + 0.001
    local tf = btTransform(Q0, btVector3(x, y, tr.z))
    tr.b:setCenterOfMassTransform(tf)
    tr.m.trans = tf
    tr.b:setLinearVelocity(btVector3(0, 0, 0))
    tr.b:setAngularVelocity(btVector3(0, 0, 0))
    tr.b:clearForces()
    tr.E0, tr.Emin, tr.Emax = energy(tr), nil, nil
    tr.worst, tr.state, tr.still, tr.reported = 0, "rolling", 0, false
    tr.x0, tr.y0 = x, y
    local ya, yb = predictY(tr, X0 + 1), predictY(tr, X0 + L - 1)
    if tr.kind == "cone" then
      local crit = TANPHI * R / H
      print(string.format("  %-6s rails rise %.1f cm over %d (tan %.3f); the cone's centre would go %s by %.2f cm from end to end:" ..
                          "\n         tan(theta) %.3f %s tan(phi) R/H = %.3f %.3f / %.3f = %.4f, so it rolls %s",
                          tr.short, tr.rise, L, tr.tanTheta, yb < ya and "down" or "up", math.abs(yb - ya),
                          tr.tanTheta, tr.tanTheta < crit and "<" or ">", TANPHI, R, H, crit,
                          tr.tanTheta < crit and "UP the rails (its centre going down)" or "down the rails"))
    else
      print(string.format("  %-6s a cylinder on the same rails: its centre rises %.2f cm with them, so it rolls down", tr.short, yb - ya))
    end
  end
end

local LOGF = os.getenv("DC_LOG") and io.open(os.getenv("DC_LOG"), "w")
if LOGF then LOGF:write("t,track,x,y,y_geometry,energy\n") end
local restAll = 0
local EDGE = 6.5           -- (nearer the ends than this, it can touch the stops)
v:postSim(function(N_)
  if holdNow then return end
  t = t + FRAME_DT
  local allStill = true
  for k, tr in ipairs(TRACKS) do
    copyTrans(tr.st, tr.m)
    local x, y = getPosXYZ(tr.m)
    local vx, vy, vz = getVelXYZ(tr.m)
    local sp = math.sqrt(vx * vx + vy * vy + vz * vz)
    -- the centre against the geometry (away from the stops at the ends)
    local s = x - X0
    if s > EDGE and s < L - EDGE then
      local yp = predictY(tr, x)
      tr.worst = math.max(tr.worst, math.abs(y - yp))
      tr.lastGap = y - yp
    end
    local E = energy(tr)
    tr.Emin = math.min(tr.Emin or E, E)
    tr.Emax = math.max(tr.Emax or E, E)
    if not tr.reported then
      tr.Ereach = E
    end
    -- reaching an end
    if not tr.reported and (s >= L - EDGE or s <= EDGE) and math.abs(s - tr.s0) > 3 then
      tr.reported = true
      local released = MASS * G * math.abs(y - tr.y0)
      print(string.format("  %-6s nears the %s end at %.2f s, having rolled %.1f cm %s (the rails %s %.2f cm): its centre went %s %.3f cm (the geometry: %.3f)," ..
                          "\n         off the geometry by %.4f cm at worst on the way; it lost %.2f%% of the energy its centre's fall gave it",
                          tr.short, s > L / 2 and "high, wide" or "low, narrow", t, math.abs(x - tr.x0),
                          s > L / 2 and "up the rails" or "down the rails", s > L / 2 and "rising" or "falling",
                          math.abs(x - tr.x0) * tr.tanTheta, y < tr.y0 and "down" or "up",
                          math.abs(y - tr.y0), math.abs(predictY(tr, x) - tr.y0),
                          tr.worst, (tr.E0 - E) / released * 100))
    end
    if sp < 0.2 then tr.still = tr.still + FRAME_DT else tr.still = 0 end
    if tr.still < 1 then allStill = false end
    if LOGF and N_ % 2 == 0 then
      LOGF:write(string.format("%.4f,%d,%.4f,%.4f,%.4f,%.4f\n", t, k, x, y, (s > 1 and s < L - 1) and predictY(tr, x) or 0, E))
    end
  end
  restAll = allStill and restAll + FRAME_DT or 0
  if restAll > 2 or t > 30 then setGoing() end
end)

v:preSim(function(N_)
  if holdPre() then return end
  for k = 1, NSTEPS - 1 do v:stepSimulation(STEP, 0, STEP) end
end)

-- ---------------------------------------------------------------------
-- keys, sliders, help
-- ---------------------------------------------------------------------
common.setCamera(btVector3(0, 48, 112), btVector3(0, 8, 0))
v:addShortcut("R", function(N_) setGoing() end)
v:addShortcut("Z", function(N_)
  local sp = v:getParam("speed") < 0.5 and 1 or 0.25
  v:addParam("speed", sp, 0.05, 2, 0.05, "simulated seconds per real second (Z: 1/4 <-> 1)")
  applyTiming()
end)
v:onParamChanged(function(N_, name, value)
  if name == "speed" or name == "steps" then applyTiming() end
end)
v:setHelpText(table.concat({
  "The double cone (Euler's Cabinet of Curiosities)",
  "",
  "On rails that rise and spread apart, a double cone rolls",
  "up to the high end. Its centre of mass goes down: the rails",
  "meet it nearer its points, where it's thinner.",
  "",
  "Back (brass):  rails rising 1.5 cm -- the cone rolls up",
  "Middle:        the same rails -- a cylinder rolls down",
  "Front (steel): rails rising 5 cm -- the cone rolls down",
  "",
  "It rolls up if tan(theta) < tan(phi) R/H.",
  "",
  "R   set them going again",
  "Z   slow motion (1/4) <-> real time",
  "Rest the mouse on a roller to see where it is.",
}, "\n"))
if v.onHover then
  v:onHover(function(N_, obj, x, y, z)
    local tr = KEYS[objectKey(obj)]
    if not tr then return nil end
    local px, py = getPosXYZ(tr.m)
    return string.format("%s\n%.1f cm along the rails; its centre %.2f cm above the table (the geometry: %.2f)",
                         tr.name, px - X0, py - TABLE_Y, predictY(tr, px) - TABLE_Y)
  end)
end

setGoing()
