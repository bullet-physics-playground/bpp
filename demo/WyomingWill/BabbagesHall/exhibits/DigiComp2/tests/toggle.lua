--
-- tests/toggle.lua -- one Digi-Comp II flip-flop alone (Babbage's Hall)
--
-- One rocker, the very shape the exhibit uses (digicomp2-geometry.lua): its
-- roof, cups and steel ball on the upper plate, its stem through the plate
-- and its foot on the lower level, on its pin between its stop pegs, under a
-- straight run of channel; its done hole on its right; the clear lane on
-- the lower level beside its foot. A sequence of balls: B from above (each
-- should leave on the other side from the last: a done ball drops through
-- the hole, a carry stays on the upper level going left), C down the clear
-- lane (it should leave the rocker at 0, whatever it was). Prints each ball
-- and "RESULT toggle: PASS" when all went right.
--
-- Run from the repository's top folder:
--   bpp -f demo/WyomingWill/BabbagesHall/exhibits/DigiComp2/tests/toggle.lua -n 1300
-- env: TL_SEQ (the sequence, "BCBBCCBCBBC"), TL_FR (friction, 0.3), TL_PF
--      (the pin's friction, kg cm^2/s^2, 0.4), TL_TH (slope, degrees, 15),
--      TL_MARGIN (how far the narrowed clear lane holds a ball clear of a
--      wedge at 0, cm), TL_HX, TL_HZ (the done hole's centre)
--
local common = require "common"
local function envnum(n, d) return tonumber(os.getenv(n) or "") or d end
local DIR
for _, d in ipairs({ "", "../", "demo/WyomingWill/BabbagesHall/exhibits/DigiComp2/" }) do
  local f = io.open(d .. "digicomp2-geometry.lua", "r")
  if f then f:close(); DIR = d; break end
end
assert(DIR, "toggle test: can't find digicomp2-geometry.lua")
local G = dofile(DIR .. "digicomp2-geometry.lua")
local F = G.FLIP
local TH = math.rad(envnum("TL_TH", 15))
local R, MB = G.R, G.BALL_MASS
local FR, PF = envnum("TL_FR", 0.3), envnum("TL_PF", 0.4)
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

local PT, GAP, YL = G.PT, G.GAP, G.YL
local function box(x0, x1, y0, y1, z0, z1)
  local c = Cube(x1 - x0, y1 - y0, z1 - z0, 0)
  c.trans = btTransform(BQ, W3((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2))
  v:add(c); c.body:setFriction(1); c.body:setRestitution(0)
  return c
end
-- a plate x0..x1, z0..z1 with rectangular holes {x0,x1,z0,z1}
local function plate(X0, X1, Z0, Z1, holes, y0, y1)
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
        if h[1] > x + 1e-6 then box(x, h[1], y0, y1, a, b) end
        x = math.max(x, h[2])
      end
      if X1 > x + 1e-6 then box(x, X1, y0, y1, a, b) end
    end
  end
end
local function wall(x1, z1, x2, z2, y0, y1)
  local dx, dz = x2 - x1, z2 - z1
  local c = Cube(math.sqrt(dx * dx + dz * dz) + G.WALL_T, y1 - y0, G.WALL_T, 0)
  c.trans = btTransform(yq(math.atan2(-dz, dx)), W3((x1 + x2) / 2, (y0 + y1) / 2, (z1 + z2) / 2))
  v:add(c); c.body:setFriction(1); c.body:setRestitution(0)
end
local function peg(x, z, r, y0, y1)
  local c = Cylinder(r, y1 - y0, 0)
  c.trans = btTransform(BQ * zToY, W3(x, (y0 + y1) / 2, z))
  v:add(c); c.body:setFriction(1); c.body:setRestitution(0)
end

-- the done hole, right of the rocker
local HX, HZ, HS = envnum("TL_HX", G.DONE[1]), envnum("TL_HZ", G.DONE[2]), G.HOLE
local HUBH = F.STEM_R + 0.05
plate(-12, 12, -12, 12, { { HX - HS / 2, HX + HS / 2, HZ - HS / 2, HZ + HS / 2 }, { -HUBH, HUBH, -HUBH, HUBH } }, -PT, 0)
box(-12, 12, YL - 0.5, YL, -12, 12)               -- the lower level
-- (a stop past the hole: the ball can't skip over it)
wall(HX + HS / 2 + 0.15, HZ - HS / 2 - 0.6, HX + HS / 2 + 0.15, HZ + HS / 2 + 0.15, 0, G.WALL_H)
wall(HX - HS / 2, HZ + HS / 2 + 0.15, HX + HS / 2 + 0.15, HZ + HS / 2 + 0.15, 0, G.WALL_H)

-- the rocker, as the exhibit builds it: its pieces on the upper plate, its
-- stem and foot below
local pieces = {}
for _, pc in ipairs(F.pieces) do pieces[#pieces + 1] = { pts = pc, y0 = F.Y0, h = F.H } end
for _, l in ipairs(F.lower) do pieces[#pieces + 1] = { pts = l[1], y0 = l[2], h = l[3] } end
local m, cx, cz, I = F.mass, F.cx, F.cz, F.I
local yc = F.Y0 + F.H / 2
local shape = btCompoundShape(true)
for _, p in ipairs(pieces) do
  local hs = btConvexHullShape()
  for _, q in ipairs(p.pts) do
    hs:addPoint(btVector3(q[1] - cx, p.y0 - yc, q[2] - cz), false)
    hs:addPoint(btVector3(q[1] - cx, p.y0 + p.h - yc, q[2] - cz), false)
  end
  hs:recalcLocalAabb(); hs:setMargin(0.005)
  shape:addChildShape(btTransform(ident, btVector3(0, 0, 0)), hs)
end
local function pose(phi)
  local c, s = math.cos(phi), math.sin(phi)
  return btTransform(yq(phi), W3(c * cx + s * cz, yc, -s * cx + c * cz))
end
local tr0 = pose(math.rad(F.ALPHA - 0.3))
local body = btRigidBody(m, btDefaultMotionState(tr0), shape, btVector3(I, I, I))
local rocker = Cube(0.1, 0.1, 0.1, m); rocker.body = body; v:add(rocker)
body:setCenterOfMassTransform(tr0); body:setActivationState(4)
body:setFriction(FR); body:setRestitution(0)
local anchor = Cube(0.01, 0.01, 0.01, 0); anchor.collides = false; v:add(anchor)
anchor.trans = btTransform(ident, btVector3(0, 0, 0))
local hinge = btHingeConstraint(anchor.body, body, btTransform(BQ * zToY, W3(0, yc, 0)),
                                btTransform(zToY, btVector3(-cx, 0, -cz)))
v:addConstraint(hinge)
if PF > 0 then hinge:enableAngularMotor(true, 0, PF * STEP) end
peg(-F.pegX, F.pegZ, F.PEG_R, 0, G.WALL_H); peg(F.pegX, F.pegZ, F.PEG_R, 0, G.WALL_H)
print(string.format("ROCKER %.2f g (printed %.2f g, its foot %.2f g, and the steel ball), centre of mass %.3f cm up the slope from the pin",
                    m * 1000, F.printed * 1000, F.footMass * 1000, -cz))
-- the run above it
local C = G.CHAN / 2 + G.WALL_T / 2
local runBot = -F.A - 1.4 - R
local runTop = runBot - F.RUN
wall(-C, runTop, -C, runBot, 0, G.WALL_H); wall(C, runTop, C, runBot, 0, G.WALL_H)
-- the clear lane on the lower level, open beside the foot
local XC = G.XC
local LF = F.LF
local LW0, LW1 = -LF - 1.6, -LF + 2.3               -- (no left wall where the foot swings)
G.CLEAR_MARGIN = envnum("TL_MARGIN", G.CLEAR_MARGIN)
wall(XC + C, -6, XC + C, -LF - 1.0, YL, -PT)
for _, w in ipairs(G.footWalls({ x = 0, z = 0 })) do wall(w[1], w[2], w[3], w[4], YL, -PT) end
wall(XC + C, 0.3, XC + C, 8, YL, -PT)
wall(XC - C, -6, XC - C, LW0, YL, -PT); wall(XC - C, LW1, XC - C, 8, YL, -PT)

local function lean()
  local a = body:getCenterOfMassTransform():getBasis():getColumn(0)
  return math.deg(math.atan2(-a.y * sT + a.z * cT, a.x))
end

-- the sequence: TL_SEQ, e.g. "BBCBC": B a ball from above, C a clear ball
local SEQ = os.getenv("TL_SEQ") or "BCBBCCBCBBC"
local t, nextT, k, fails = 0, 0.6, 0, 0
local cur
v:preSim(function(N) for i = 1, NSTEPS - 1 do v:stepSimulation(STEP, 0, STEP) end end)
v:postSim(function(N)
  t = t + STEP * NSTEPS
  if not cur and t >= nextT and k < #SEQ then
    k = k + 1
    local kind = SEQ:sub(k, k)
    local b = Sphere(R, MB)
    if kind == "B" then b.trans = btTransform(ident, W3(0, R + 0.002, runTop + R + 0.05))
    else b.trans = btTransform(ident, W3(XC, YL + R + 0.002, -5)) end
    v:add(b); b.body:setFriction(FR); b.body:setRestitution(0); b.body:setActivationState(4)
    cur = { obj = b, kind = kind, a0 = lean(), t = t }
  end
  if cur then
    local x, y, z = L3(cur.obj.pos)
    local done = z > 6 or t - cur.t > 3
    if done then
      local where = (t - cur.t > 3) and "STUCK" or ((y < -PT) and "below" or "above") .. (x < 0 and " left" or " right")
      local a1 = lean()
      local want, wantLean
      if cur.kind == "B" then
        if cur.a0 > 0 then want, wantLean = "above left", -1 else want, wantLean = "below right", 1 end
      else want, wantLean = "below right", -1 end
      local ok = where == want and ((a1 > 0) == (wantLean > 0))
      if not ok then fails = fails + 1 end
      print(string.format("%s  lean %+6.2f -> %-11s lean %+6.2f   %s", cur.kind == "B" and "ball " or "clear", cur.a0, where, a1, ok and "" or "WRONG"))
      v:remove(cur.obj); cur = nil; nextT = t + 0.3
      if k == #SEQ then print(string.format("RESULT toggle: %s (%d wrong of %d)", fails == 0 and "PASS" or "FAIL", fails, #SEQ)) end
    end
  end
end)
