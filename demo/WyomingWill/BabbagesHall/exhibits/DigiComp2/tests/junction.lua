--
-- tests/junction.lua -- where the memory meets the accumulator (Digi-Comp II, Babbage's Hall)
--
-- A piece of the exhibit's own board (digicomp2-geometry.lua): A1 and A2,
-- the funnel over A2 with its long left wall, and the memory switch M2 whose
-- "1" outlet ends over that wall. Two ways into A2: the carry from A1 (a
-- ball let in over A1 while A1 reads 1), and a ball from M2's inlet. A
-- sequence of them:
--   C  the carry: A1 set to 1 by hand, a ball over A1. It should set A1 to
--      0, and arrive at A2 and turn it over
--   M  M2 at 1: a ball into M2. It should arrive at A2 and turn it over
--   Z  M2 at 0: a ball into M2. It should drop through M2's hole, and A2
--      stay as it was
-- Every wall, hole, peg and rocker is the exhibit's. Prints each ball and
-- "RESULT junction: PASS" when all went right.
--
-- Run from the repository's top folder:
--   bpp -f demo/WyomingWill/BabbagesHall/exhibits/DigiComp2/tests/junction.lua -n 2500
-- env: JN_SEQ (the sequence, "CMZMCCZMM"), JN_FR (friction, 0.3), JN_PF
--      (the pins' friction, kg cm^2/s^2, 0.4), JN_TH (slope, degrees, 15)
--
local common = require "common"
local function envnum(n, d) return tonumber(os.getenv(n) or "") or d end
local DIR
for _, d in ipairs({ "", "../", "demo/WyomingWill/BabbagesHall/exhibits/DigiComp2/" }) do
  local f = io.open(d .. "digicomp2-geometry.lua", "r")
  if f then f:close(); DIR = d; break end
end
assert(DIR, "junction test: can't find digicomp2-geometry.lua")
local G = dofile(DIR .. "digicomp2-geometry.lua")
local F, S = G.FLIP, G.SWITCH
local TH = math.rad(envnum("JN_TH", 15))
local R, MB = G.R, G.BALL_MASS
local FR, PF = envnum("JN_FR", 0.3), envnum("JN_PF", 0.4)
local STEP, NSTEPS = 1 / 2400, 40
common.setTiming(STEP, 0, STEP)
v.gravity = btVector3(0, -981, 0)
local cT, sT = math.cos(TH), math.sin(TH)
local BQ = btQuaternion(btVector3(1, 0, 0), TH)
local ident = btQuaternion(0, 0, 0, 1)
local zToY = btQuaternion(btVector3(1, 0, 0), -math.pi / 2)
local function W3(x, y, z) return btVector3(x, y * cT - z * sT, y * sT + z * cT) end
local function L3(p) return p.x, p.y * cT + p.z * sT, -p.y * sT + p.z * cT end
local function yq(psi) return BQ * btQuaternion(btVector3(0, 1, 0), psi) end
local PT, YL = G.PT, G.YL

-- the piece of board: everything within this box
local A1, A2, M2 = G.rocker.A1, G.rocker.A2, G.switches.M2
local X0, X1 = M2.x - 4, A1.x + 5
local Z0, Z1 = math.min(M2.z - S.FL - S.DROP, A1.z - F.A - 1.4 - R - F.RUN) - 1, A2.z + 3
local function inBox(x, z) return x > X0 and x < X1 and z > Z0 and z < Z1 end

local function box(x0, x1, y0, y1, z0, z1)
  local c = Cube(x1 - x0, y1 - y0, z1 - z0, 0)
  c.trans = btTransform(BQ, W3((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2))
  v:add(c); c.body:setFriction(1); c.body:setRestitution(0)
end
-- the plate, with the holes in the box
do
  local holes = {}
  for _, h in ipairs(G.holes) do if inBox((h[1] + h[2]) / 2, (h[3] + h[4]) / 2) then holes[#holes + 1] = h end end
  local zs = { Z0, Z1 }
  for _, h in ipairs(holes) do zs[#zs + 1] = h[3]; zs[#zs + 1] = h[4] end
  table.sort(zs)
  for i = 1, #zs - 1 do
    local a, b = zs[i], zs[i + 1]
    if b - a > 1e-6 then
      local cuts = {}
      for _, h in ipairs(holes) do if h[3] <= a + 1e-6 and h[4] >= b - 1e-6 then cuts[#cuts + 1] = h end end
      table.sort(cuts, function(p, q) return p[1] < q[1] end)
      local x = X0
      for _, h in ipairs(cuts) do
        if h[1] > x + 1e-6 then box(x, h[1], -PT, 0, a, b) end
        x = math.max(x, h[2])
      end
      if X1 > x + 1e-6 then box(x, X1, -PT, 0, a, b) end
    end
  end
end
box(X0, X1, YL - 0.5, YL, Z0, Z1 + 8)              -- the lower level
local function wall(w, y0, y1)
  local dx, dz = w[3] - w[1], w[4] - w[2]
  local c = Cube(math.sqrt(dx * dx + dz * dz) + G.WALL_T, y1 - y0, G.WALL_T, 0)
  c.trans = btTransform(yq(math.atan2(-dz, dx)), W3((w[1] + w[3]) / 2, (y0 + y1) / 2, (w[2] + w[4]) / 2))
  v:add(c); c.body:setFriction(1); c.body:setRestitution(0)
end
for _, w in ipairs(G.walls) do
  if inBox(w[1], w[2]) and inBox(w[3], w[4]) and w.role ~= "lane" then wall(w, 0, G.WALL_H) end
end
for _, w in ipairs(G.lwalls) do if inBox(w[1], w[2]) and inBox(w[3], w[4]) then wall(w, YL, YL + w[5]) end end
for _, p in ipairs(G.pegs) do
  if inBox(p[1], p[2]) then
    local c = Cylinder(p[3], G.WALL_H, 0)
    c.trans = btTransform(BQ * zToY, W3(p[1], G.WALL_H / 2, p[2]))
    v:add(c); c.body:setFriction(1); c.body:setRestitution(0)
  end
end
local anchor = Cube(0.01, 0.01, 0.01, 0); anchor.collides = false; v:add(anchor)
anchor.trans = btTransform(ident, btVector3(0, 0, 0))
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
  local h = btHingeConstraint(anchor.body, body, btTransform(BQ * zToY, W3(x, y, z)), btTransform(zToY, btVector3(-cx, 0, -cz)))
  v:addConstraint(h)
  if PF > 0 then h:enableAngularMotor(true, 0, PF * STEP) end
end
local function setUp(body, tr)
  body:setCenterOfMassTransform(tr); body:setLinearVelocity(btVector3(0, 0, 0)); body:setAngularVelocity(btVector3(0, 0, 0))
  body:activate(true)
end

-- A1 and A2
local yc = F.Y0 + F.H / 2
local fp = {}
for _, pc in ipairs(F.pieces) do fp[#fp + 1] = { pc, F.Y0, F.H } end
for _, l in ipairs(F.lower) do fp[#fp + 1] = l end
local LEAN = math.rad(F.ALPHA - 0.3)
local rockers = {}
for _, t in ipairs({ A1, A2 }) do
  local tr = poseAt(t.x, t.z, F.cx, yc, F.cz, LEAN)
  local body = btRigidBody(F.mass, btDefaultMotionState(tr), shapeOf(fp, F.cx, yc, F.cz), btVector3(F.I, F.I, F.I))
  local o = Cube(0.1, 0.1, 0.1, F.mass); o.body = body; v:add(o)
  setUp(body, tr); body:setActivationState(4); body:setFriction(FR); body:setRestitution(0)
  pinned(body, t.x, yc, t.z, F.cx, F.cz)
  rockers[t.name] = { t = t, body = body }
end
local function bit(name)
  local a = rockers[name].body:getCenterOfMassTransform():getBasis():getColumn(0)
  return (-a.y * sT + a.z * cT) > 0 and 1 or 0
end
local function setBit(name, b)
  local t = rockers[name].t
  setUp(rockers[name].body, poseAt(t.x, t.z, F.cx, yc, F.cz, b == 1 and -LEAN or LEAN))
end
-- M2's flap
local syc, scz, ang = S.Y0 + S.H / 2, -S.FL / 2, math.rad(S.ANG - 0.5)
local flap
do
  local pcs = { { { { -S.FT / 2, -S.FL }, { S.FT / 2, -S.FL }, { S.FT / 2, 0 }, { -S.FT / 2, 0 } }, S.Y0, S.H } }
  local tr = poseAt(M2.x, M2.z, 0, syc, scz, ang)
  flap = btRigidBody(S.mass, btDefaultMotionState(tr), shapeOf(pcs, 0, syc, scz), btVector3(S.I, S.I, S.I))
  local o = Cube(0.1, 0.1, 0.1, S.mass); o.body = flap; v:add(o)
  setUp(flap, tr); flap:setActivationState(4); flap:setFriction(FR); flap:setRestitution(0)
  pinned(flap, M2.x, syc, M2.z, 0, scz)
end
-- (M2 at 1: its ball goes right, the flap against the left wall)
local function setM2(on) setUp(flap, poseAt(M2.x, M2.z, 0, syc, scz, on and ang or -ang)) end

local SEQ = os.getenv("JN_SEQ") or "CMZMCCZMM"
local t, nextT, k, fails = 0, 0.6, 0, 0
local cur
v:preSim(function(N) for i = 1, NSTEPS - 1 do v:stepSimulation(STEP, 0, STEP) end end)
v:postSim(function(N)
  t = t + STEP * NSTEPS
  if not cur and t >= nextT and k < #SEQ then
    k = k + 1
    local kind = SEQ:sub(k, k)
    if kind == "C" then setBit("A1", 1) else setM2(kind == "M") end
    local b = Sphere(R, MB)
    local x, z
    if kind == "C" then x, z = A1.x, A1.z - F.A - 1.4 - R - F.RUN + R + 0.05
    else x, z = M2.x, M2.z - S.FL - S.DROP + R + 0.05 end
    b.trans = btTransform(ident, W3(x, R + 0.002, z))
    v:add(b); b.body:setFriction(FR); b.body:setRestitution(0); b.body:setActivationState(4)
    cur = { obj = b, kind = kind, a2 = bit("A2"), t = t + 0.3 }
  end
  if cur then
    local x, y, z = L3(cur.obj.pos)
    local below = y < -PT
    local done = (not below and z > A2.z + 2) or (below and z > A2.z - 6 and cur.kind ~= "Z") or
                 (below and cur.kind == "Z") or t - cur.t > 4
    if done then
      local turned = bit("A2") ~= cur.a2
      local ok
      if cur.kind == "Z" then ok = below and not turned
      else ok = turned and t - cur.t <= 4 and (cur.kind ~= "C" or bit("A1") == 0) end
      if not ok then fails = fails + 1 end
      local where = t - cur.t > 4 and "STUCK" or (below and "dropped" or "on")
      print(string.format("%s  %-8s  A2 %d -> %d  %s", cur.kind == "C" and "carry " or (cur.kind == "M" and "M2 at 1" or "M2 at 0"),
                          where, cur.a2, bit("A2"), ok and "" or "WRONG"))
      v:remove(cur.obj); cur = nil; nextT = t + 0.3
      if k == #SEQ then print(string.format("RESULT junction: %s (%d wrong of %d)", fails == 0 and "PASS" or "FAIL", fails, #SEQ)) end
    end
  end
end)
