--
-- tests/complement.lua -- COMPLEMENT: the done lanes and their shutters (Digi-Comp II, Babbage's Hall)
--
-- A piece of the exhibit's own board (digicomp2-geometry.lua): A1, A2 and
-- A3, their funnels, done holes and done lanes, down to A4's funnel (or,
-- CP_FROM=n, An to An+2, down to An+3's: "A1 .. A4" below then means those). A
-- sequence of balls let in over A1, each with A1 .. A3 set by hand and the
-- shutters open or closed:
--   open (COMPLEMENT off): the ball counts: it turns over every 1 it meets
--     and the first 0, and drops through that one's done hole (or, all
--     three at 1, goes on to A4)
--   closed (COMPLEMENT on): it turns over all three, whatever they read,
--     and goes on to A4 (by A3's done lane or its carry)
-- Each ball's case is "SBBB": S "o" open or "c" closed, then A1, A2, A3.
-- Every wall, hole, peg and rocker is the exhibit's. Prints each ball and
-- "RESULT complement: PASS" when all went right.
--
-- Run from the repository's top folder:
--   bpp -f demo/WyomingWill/BabbagesHall/exhibits/DigiComp2/tests/complement.lua -n 4000
-- env: CP_SEQ (the cases, space between), CP_FR (friction, 0.3), CP_PF (the
--      pins' friction, kg cm^2/s^2, 0.4), CP_TH (slope, degrees, 15), CP_ROLL
--      (degrees: the table not level across, down to the right), CP_FROM (1)
--
local common = require "common"
local function envnum(n, d) return tonumber(os.getenv(n) or "") or d end
local DIR
for _, d in ipairs({ "", "../", "demo/WyomingWill/BabbagesHall/exhibits/DigiComp2/" }) do
  local f = io.open(d .. "digicomp2-geometry.lua", "r")
  if f then f:close(); DIR = d; break end
end
assert(DIR, "complement test: can't find digicomp2-geometry.lua")
local G = dofile(DIR .. "digicomp2-geometry.lua")
local F = G.FLIP
local TH = math.rad(envnum("CP_TH", 15))
local R, MB = G.R, G.BALL_MASS
local FR, PF = envnum("CP_FR", 0.3), envnum("CP_PF", 0.4)
local STEP, NSTEPS = 1 / 2400, 40
common.setTiming(STEP, 0, STEP)
do
  local r = math.rad(envnum("CP_ROLL", 0))       -- (the table not level across: down to the right)
  v.gravity = btVector3(981 * math.sin(r), -981 * math.cos(r), 0)
end
local cT, sT = math.cos(TH), math.sin(TH)
local BQ = btQuaternion(btVector3(1, 0, 0), TH)
local ident = btQuaternion(0, 0, 0, 1)
local zToY = btQuaternion(btVector3(1, 0, 0), -math.pi / 2)
local function W3(x, y, z) return btVector3(x, y * cT - z * sT, y * sT + z * cT) end
local function L3(p) return p.x, p.y * cT + p.z * sT, -p.y * sT + p.z * cT end
local function yq(psi) return BQ * btQuaternion(btVector3(0, 1, 0), psi) end
local PT, YL = G.PT, G.YL
local RUNTOP = F.A + 1.4 + G.R + F.RUN

-- the piece of board: everything within this box
local F0 = math.floor(envnum("CP_FROM", 1))       -- (the first of the three: A1 .. A4)
local T = {}
for k = 1, 4 do T[k] = G.toggles[F0 + k - 1] end
local X0, X1 = T[4].x - 4.5, T[1].x + 5
local Z0, Z1 = T[1].z - RUNTOP - 2.5, T[4].z - RUNTOP + 0.5
local ZEND = T[4].z - RUNTOP - 0.5                  -- (a ball past this has reached A4's funnel)
local function inBox(x, z) return x > X0 and x < X1 and z > Z0 and z < Z1 end

local function box(x0, x1, y0, y1, z0, z1)
  local c = Cube(x1 - x0, y1 - y0, z1 - z0, 0)
  c.trans = btTransform(BQ, W3((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2))
  v:add(c); c.body:setFriction(1); c.body:setRestitution(0)
  return c
end
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
-- the shutters: thin tiles flush with the plate; closed over the hole, open
-- TRAVEL farther to the right
local SH = G.SHUTTER
local shutters = {}
for k = 1, 3 do
  for _, pc in ipairs(G.shutters[F0 + k - 1].pieces) do
    local x0, x1, z0, z1 = pc[1][1], pc[3][1], pc[1][2], pc[3][2]
    shutters[#shutters + 1] = { c = box(x0, x1, -SH.T, 0, z0, z1), x = (x0 + x1) / 2, z = (z0 + z1) / 2 }
  end
end
local function setShutters(closed)
  for _, s in ipairs(shutters) do
    s.c.trans = btTransform(BQ, W3(s.x + (closed and 0 or SH.TRAVEL), -SH.T / 2, s.z))
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

local yc = F.Y0 + F.H / 2
local fp = {}
for _, pc in ipairs(F.pieces) do fp[#fp + 1] = { pc, F.Y0, F.H } end
for _, l in ipairs(F.lower) do fp[#fp + 1] = l end
local LEAN = math.rad(F.ALPHA - 0.3)
local rockers = {}
for k = 1, 3 do
  local t = T[k]
  local tr = poseAt(t.x, t.z, F.cx, yc, F.cz, LEAN)
  local body = btRigidBody(F.mass, btDefaultMotionState(tr), shapeOf(fp, F.cx, yc, F.cz), btVector3(F.I, F.I, F.I))
  local o = Cube(0.1, 0.1, 0.1, F.mass); o.body = body; v:add(o)
  setUp(body, tr); body:setActivationState(4); body:setFriction(FR); body:setRestitution(0)
  pinned(body, t.x, yc, t.z, F.cx, F.cz)
  rockers[k] = { t = t, body = body }
end
local function bit(k)
  local a = rockers[k].body:getCenterOfMassTransform():getBasis():getColumn(0)
  return (-a.y * sT + a.z * cT) > 0 and 1 or 0
end
local function setBit(k, b)
  local t = rockers[k].t
  setUp(rockers[k].body, poseAt(t.x, t.z, F.cx, yc, F.cz, b == 1 and -LEAN or LEAN))
end
local function bits() return bit(1) .. bit(2) .. bit(3) end

local SEQ = {}
for c in (os.getenv("CP_SEQ") or "c000 c111 c101 c010 o000 o100 o110 o111 c011 c100 o010 c001 c110"):gmatch("%S+") do SEQ[#SEQ + 1] = c end
local t, nextT, k, fails = 0, 0.6, 0, 0
local cur
v:preSim(function(N) for i = 1, NSTEPS - 1 do v:stepSimulation(STEP, 0, STEP) end end)
v:postSim(function(N)
  t = t + STEP * NSTEPS
  if not cur and t >= nextT and k < #SEQ then
    k = k + 1
    local c = SEQ[k]
    local closed = c:sub(1, 1) == "c"
    setShutters(closed)
    local want, past = {}, false
    for j = 1, 3 do setBit(j, tonumber(c:sub(j + 1, j + 1))) end
    -- what it should do
    local b = { tonumber(c:sub(2, 2)), tonumber(c:sub(3, 3)), tonumber(c:sub(4, 4)) }
    local wb, dropAt = { b[1], b[2], b[3] }, nil
    for j = 1, 3 do
      wb[j] = 1 - b[j]
      if not closed and b[j] == 0 then dropAt = j; break end
    end
    local ball = Sphere(R, MB)
    ball.trans = btTransform(ident, W3(T[1].x, R + 0.002, T[1].z - RUNTOP + R + 0.05))
    v:add(ball); ball.body:setFriction(FR); ball.body:setRestitution(0); ball.body:setActivationState(4)
    cur = { obj = ball, c = c, want = wb[1] .. wb[2] .. wb[3], dropAt = dropAt, t = t }
  end
  if cur then
    local x, y, z = L3(cur.obj.pos)
    if os.getenv("CP_TRACE") and N % 3 == 0 then
      local ls = {}
      for k = 1, 3 do
        local a = rockers[k].body:getCenterOfMassTransform():getBasis():getColumn(0)
        ls[k] = string.format("%.1f", math.deg(math.atan2(-a.y * sT + a.z * cT, a.x)))
      end
      print(string.format("      t %.2f ball %.2f %.2f %.2f  leans %s", t - cur.t, x, y, z, table.concat(ls, " ")))
    end
    local below = y < -PT
    local done = below or z > ZEND or t - cur.t > 6
    if done and below then
      -- (dropped: settle, then see where: which done hole)
      if not cur.droppedAt then cur.droppedAt, cur.tDrop = z, t end
      done = t - cur.tDrop > 0.5
    end
    if done then
      local got = bits()
      local where
      if t - cur.t > 6 then where = "STUCK"
      elseif cur.droppedAt then
        where = "dropped"
        for j = 1, 3 do
          local h = G.holes
          local d = T[j].done
          if math.abs(cur.droppedAt - d[2]) < 2 then where = "dropped at " .. j end
        end
      else where = "on to A4" end
      local wantWhere = cur.dropAt and ("dropped at " .. cur.dropAt) or "on to A4"
      local ok = got == cur.want and where == wantWhere
      if not ok then fails = fails + 1 end
      print(string.format("%s  %s: A1-A3 %s -> %s (want %s), %s%s  %.1f s", cur.c:sub(1, 1) == "c" and "closed" or "open  ",
                          cur.c:sub(2), cur.c:sub(2), got, cur.want, where, ok and "" or "  WRONG", t - cur.t))
      v:remove(cur.obj); cur = nil; nextT = t + 0.4
      if k == #SEQ then print(string.format("RESULT complement: %s (%d wrong of %d)", fails == 0 and "PASS" or "FAIL", fails, #SEQ)) end
    end
  end
end)
