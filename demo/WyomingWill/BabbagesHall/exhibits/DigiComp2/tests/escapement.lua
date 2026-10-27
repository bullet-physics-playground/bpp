--
-- tests/escapement.lua -- START: the feeder wheel and its anchor alone (Digi-Comp II, Babbage's Hall)
--
-- The exhibit's own feeder wheel (digicomp2-geometry.lua) with its escape
-- star, its housing, the INPUT channel of balls above it, and the ANCHOR
-- that holds it. A wound weight turns the wheel (here a steady torque on
-- it), and a fly keeps it slow (here a top speed); the anchor lets it round
-- a quarter turn each time it is tripped (its arm's end pushed across, as
-- START will push it). A sequence of trips, short and long; after each,
-- exactly one ball should have come out at the bottom, and none while it
-- stood at rest. Prints each trip and "RESULT escapement: PASS" when all
-- went right.
--
-- Run from the repository's top folder:
--   bpp -f demo/WyomingWill/BabbagesHall/exhibits/DigiComp2/tests/escapement.lua -n 2500
-- env: ES_SEQ (trip lengths in tenths of a second, e.g. "1,3,15,1,1,6,20,2"),
--      ES_WT (the weight's torque on the wheel, kg cm^2/s^2, 30),
--      ES_WV (the fly's top speed, radians a second, 3), ES_FR (friction,
--      0.3), ES_AFR (the anchor's friction on the pins, 0: rollers),
--      ES_PF (the pins' friction, kg cm^2/s^2, 0.4), ES_TH (slope, degrees,
--      15), ES_BALLS (balls loaded, 9), ES_PUSH (the hand's push on the arm,
--      kg cm^2/s^2 of torque at the anchor's pin, 300)
--
local common = require "common"
local function envnum(n, d) return tonumber(os.getenv(n) or "") or d end
local DIR
for _, d in ipairs({ "", "../", "demo/WyomingWill/BabbagesHall/exhibits/DigiComp2/" }) do
  local f = io.open(d .. "digicomp2-geometry.lua", "r")
  if f then f:close(); DIR = d; break end
end
assert(DIR, "escapement test: can't find digicomp2-geometry.lua")
local G = dofile(DIR .. "digicomp2-geometry.lua")
local F, Wh, A = G.FLIP, G.WHEEL, G.ANCHOR
local TH = math.rad(envnum("ES_TH", 15))
local R, MB = G.R, G.BALL_MASS
local FR, PF = envnum("ES_FR", 0.3), envnum("ES_PF", 0.4)
local PUSH = envnum("ES_PUSH", 300)
local STEP, NSTEPS = 1 / 2400, 40
common.setTiming(STEP, 0, STEP)
v.gravity = btVector3(0, -981, 0)
local cT, sT = math.cos(TH), math.sin(TH)
local BQ = btQuaternion(btVector3(1, 0, 0), TH)
local ident = btQuaternion(0, 0, 0, 1)
local zToY = btQuaternion(btVector3(1, 0, 0), -math.pi / 2)
local OX, OZ = -Wh.x, -Wh.z
local function W3(x, y, z) x, z = x + OX, z + OZ; return btVector3(x, y * cT - z * sT, y * sT + z * cT) end
local function L3(p) return p.x - OX, p.y * cT + p.z * sT, -p.y * sT + p.z * cT - OZ end
local function yq(psi) return BQ * btQuaternion(btVector3(0, 1, 0), psi) end

local X0, X1, Z0, Z1 = Wh.x - 6, A.x + 4, Wh.queueTop - 1, Wh.z + 14
local function box(x0, x1, y0, y1, z0, z1)
  local c = Cube(x1 - x0, y1 - y0, z1 - z0, 0)
  c.trans = btTransform(BQ, W3((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2))
  v:add(c); c.body:setFriction(1); c.body:setRestitution(0)
end
box(X0, X1, -G.PT, 0, Z0, Z1)
local function inBox(x, z) return x > X0 and x < X1 and z > Z0 and z < Wh.z + 4 end
for _, w in ipairs(G.walls) do
  if inBox(w[1], w[2]) and inBox(w[3], w[4]) then
    local dx, dz = w[3] - w[1], w[4] - w[2]
    local c = Cube(math.sqrt(dx * dx + dz * dz) + G.WALL_T, G.WALL_H, G.WALL_T, 0)
    c.trans = btTransform(yq(math.atan2(-dz, dx)), W3((w[1] + w[3]) / 2, G.WALL_H / 2, (w[2] + w[4]) / 2))
    v:add(c); c.body:setFriction(1); c.body:setRestitution(0)
  end
end
local anchor0 = Cube(0.01, 0.01, 0.01, 0); anchor0.collides = false; v:add(anchor0)
anchor0.trans = btTransform(ident, btVector3(0, 0, 0))
local function shapeOf(pieces, cx, cy, cz)
  local s = btCompoundShape(true)
  for _, pc in ipairs(pieces) do
    local hs = btConvexHullShape()
    for _, p in ipairs(pc[1]) do
      hs:addPoint(btVector3(p[1] - cx, pc[2] - cy, p[2] - cz), false)
      hs:addPoint(btVector3(p[1] - cx, pc[2] + pc[3] - cy, p[2] - cz), false)
    end
    hs:recalcLocalAabb(); hs:setMargin(0.005)
    s:addChildShape(btTransform(ident, btVector3(0, 0, 0)), hs)
  end
  return s
end
local function poseAt(x, z, cx, cy, cz, phi)
  local c, s = math.cos(phi), math.sin(phi)
  return btTransform(yq(phi), W3(x + c * cx + s * cz, cy, z - s * cx + c * cz))
end
local function pinned(body, x, y, z, cx, cz)
  local h = btHingeConstraint(anchor0.body, body, btTransform(BQ * zToY, W3(x, y, z)), btTransform(zToY, btVector3(-cx, 0, -cz)))
  v:addConstraint(h)
  if PF > 0 then h:enableAngularMotor(true, 0, PF * STEP) end
  return h
end
local function lean(body)
  local a = body:getCenterOfMassTransform():getBasis():getColumn(0)
  return math.deg(math.atan2(-a.y * sT + a.z * cT, a.x))
end

-- the wheel and its star, one body
local wy = 1.0
local wp = {}
for _, pc in ipairs(Wh.pieces) do wp[#wp + 1] = { pc, Wh.Y0, Wh.H } end
for _, p in ipairs(Wh.starPieces) do wp[#wp + 1] = p end
local wm, wI = Wh.mass + Wh.starMass, Wh.I + Wh.starI
local WT, WV = envnum("ES_WT", 30), envnum("ES_WV", 3)   -- the weight's torque on the wheel, the fly's top speed
local wtr = btTransform(BQ, W3(Wh.x, wy, Wh.z))
local wheel = btRigidBody(wm, btDefaultMotionState(wtr), shapeOf(wp, 0, wy, 0), btVector3(wI, wI, wI))
local wo = Cube(0.1, 0.1, 0.1, wm); wo.body = wheel; v:add(wo)
wheel:setCenterOfMassTransform(wtr); wheel:setActivationState(4); wheel:setFriction(FR); wheel:setRestitution(0)
local wh = pinned(wheel, Wh.x, wy, Wh.z, 0, 0)
-- the anchor, at rest
local ay = (A.Y0 + A.ARM_Y1) / 2
local apcs = {}
for _, p in ipairs(A.pieces) do apcs[#apcs + 1] = p end
local REST = A.REST
local atr = poseAt(A.x, A.z, A.cx, ay, A.cz, REST)
local anchor = btRigidBody(A.mass, btDefaultMotionState(atr), shapeOf(apcs, A.cx, ay, A.cz), btVector3(A.I, A.I, A.I))
local ao = Cube(0.1, 0.1, 0.1, A.mass); ao.body = anchor; v:add(ao)
anchor:setCenterOfMassTransform(atr); anchor:setActivationState(4); anchor:setFriction(envnum("ES_AFR", 0)); anchor:setRestitution(0)
local ah = pinned(anchor, A.x, ay, A.z, A.cx, A.cz)
-- its stops: two posts either side of the arm's end
local ex, ez = 0, -A.ARM + 0.4
for _, sgn in ipairs({ -1, 1 }) do
  local a = math.rad(A.LEAN) * -sgn
  local px = A.x + ex * math.cos(a) + ez * math.sin(a) + sgn * (0.15 + 0.25)
  local pz = A.z - ex * math.sin(a) + ez * math.cos(a)
  local c = Cylinder(0.25, A.ARM_Y1 + 0.2, 0)
  c.trans = btTransform(BQ * zToY, W3(px, (A.ARM_Y1 + 0.2) / 2, pz))
  v:add(c); c.body:setFriction(1); c.body:setRestitution(0)
end

-- the balls: one in the wheel's left-hand space, the rest above it in the channel
local NB = envnum("ES_BALLS", 9)
local balls = {}
for i = 1, NB do
  local b = Sphere(R, MB)
  local wr = Wh.ballR
  local x, z
  if i == 1 then x, z = Wh.x + wr, Wh.z
  elseif i == 2 then x, z = Wh.x, Wh.z - wr
  else x, z = Wh.x, Wh.z - wr - (i - 2) * (2 * R + 0.005) end
  b.trans = btTransform(ident, W3(x, R + 0.002, z))
  v:add(b); b.body:setFriction(FR); b.body:setRestitution(0); b.body:setActivationState(4)
  balls[i] = b
end
local function out()
  local n = 0
  for _, b in ipairs(balls) do local _, _, z = L3(b.pos); if z > Wh.z + 3.5 then n = n + 1 end end
  return n
end

local SEQ = {}
for t in (os.getenv("ES_SEQ") or "1,3,15,1,1,6,20,2"):gmatch("[%d.]+") do SEQ[#SEQ + 1] = tonumber(t) / 10 end
local t, k, fails, phase, tStart, before = 0, 0, 0, "rest", 0, 0
local tripping = false
v:preSim(function(N)
  for i = 1, NSTEPS do
    wh:enableAngularMotor(true, WV, WT * STEP)
    if tripping then ah:enableAngularMotor(true, envnum("ES_V", 3.0), PUSH * STEP)
    else ah:enableAngularMotor(true, 0, PF * STEP) end
    if i < NSTEPS then v:stepSimulation(STEP, 0, STEP) end
  end
end)
v:postSim(function(N)
  if os.getenv("ES_DBG") and N % 6 == 0 then print(string.format("DBG t %.2f wheel %.1f anchor %.1f out %d", t, lean(wheel), lean(anchor), out())) end
  t = t + STEP * NSTEPS
  if phase == "rest" and t > 2.0 then
    local n = out()
    print(string.format("at rest 2 s: %d out, the anchor at %.1f degrees  %s", n, lean(anchor), n == 0 and "" or "WRONG"))
    if n ~= 0 then fails = fails + 1 end
    phase, tStart, before = "idle", t, n
  elseif phase == "idle" and t - tStart > 0.3 then
    k = k + 1
    if k > #SEQ or out() >= NB - 1 then
      print(string.format("RESULT escapement: %s (%d wrong of %d)", fails == 0 and "PASS" or "FAIL", fails, #SEQ + 1))
      phase = "done"
    else
      before = out()
      tripping, phase, tStart = true, "trip", t
    end
  elseif phase == "trip" then
    if t - tStart >= SEQ[k] then print(string.format("  (tripped: the anchor at %.1f degrees)", lean(anchor))); tripping, phase, tStart = false, "wait", t end
  elseif phase == "wait" and t - tStart > 2.0 then
    local n = out() - before
    print(string.format("trip %.1f s: %d out, the anchor back at %.1f degrees  %s", SEQ[k], n, lean(anchor), n == 1 and "" or "WRONG"))
    if n ~= 1 then fails = fails + 1 end
    phase, tStart = "idle", t
  end
end)
