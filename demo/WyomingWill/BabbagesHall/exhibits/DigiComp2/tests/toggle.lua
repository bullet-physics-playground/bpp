--
-- tests/toggle.lua -- the Digi-Comp II's flip-flop alone (Babbage's Hall)
--
-- One rocker, the very shape the exhibit uses (digicomp2-geometry.lua),
-- on its pin between its stop pegs, under a straight run of channel. Balls
-- are let go at the top of the run one at a time; each should leave on the
-- other side from the last, and leave the rocker leaning the other way.
-- Prints each ball and "RESULT toggle: PASS" when all alternated.
--
-- Run from the repository's top folder (or from this folder):
--   bpp -f demo/WyomingWill/BabbagesHall/exhibits/DigiComp2/tests/toggle.lua -n 1400
-- env: TG_N (balls, 16), TG_TH (slope, degrees), TG_FR (friction, 0.3),
--      TG_PF (the pin's friction, kg cm^2/s^2, 0.4), TG_DROP (cm of run
--      above the usual run's top, 0), TG_JIT (cm: each ball let go that far
--      off centre at most, at random; the channel allows 0.075), TG_SEED,
--      TG_GAP (s between balls, 1.2), TG_HZ (steps a second, 2400),
--      TG_ROLL (degrees: the board tilted across, down to the right)
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

local TH = math.rad(envnum("TG_TH", G.TH))
local GRAV = 981
local R, MB = G.R, G.BALL_MASS
local FR = envnum("TG_FR", 0.3)
local PF = envnum("TG_PF", 0.4)
local DROP = envnum("TG_DROP", 0)
local NB = envnum("TG_N", 16)
local JIT = envnum("TG_JIT", 0)
local GAP = envnum("TG_GAP", 1.2)
math.randomseed(envnum("TG_SEED", 1))

local STEP = 1 / envnum("TG_HZ", 2400)
local NSTEPS = math.max(1, math.floor(1 / 60 / STEP + 0.5))
common.setTiming(STEP, 0, STEP)
do
  local r = math.rad(envnum("TG_ROLL", 0))
  v.gravity = btVector3(GRAV * math.sin(r), -GRAV * math.cos(r), 0)
end

local cT, sT = math.cos(TH), math.sin(TH)
local BQ = btQuaternion(btVector3(1, 0, 0), TH)
local ident = btQuaternion(0, 0, 0, 1)
local zToY = btQuaternion(btVector3(1, 0, 0), -math.pi / 2)
local function W3(x, y, z) return btVector3(x, y * cT - z * sT, y * sT + z * cT) end
local function L3(p) return p.x, p.y * cT + p.z * sT, -p.y * sT + p.z * cT end
local function yq(psi) return BQ * btQuaternion(btVector3(0, 1, 0), psi) end

local board = Cube(40, 1, 40, 0)
board.trans = btTransform(BQ, W3(0, -0.5, 0))
v:add(board)
board.body:setFriction(1); board.body:setRestitution(0)
local function wall(x1, z1, x2, z2)
  local dx, dz = x2 - x1, z2 - z1
  local c = Cube(math.sqrt(dx * dx + dz * dz) + G.WALL_T, G.WALL_H, G.WALL_T, 0)
  c.trans = btTransform(yq(math.atan2(-dz, dx)), W3((x1 + x2) / 2, G.WALL_H / 2, (z1 + z2) / 2))
  v:add(c)
  c.body:setFriction(1); c.body:setRestitution(0)
end
local function peg(x, z, r)
  local c = Cylinder(r, G.WALL_H, 0)
  c.trans = btTransform(BQ * zToY, W3(x, G.WALL_H / 2, z))
  v:add(c)
  c.body:setFriction(1); c.body:setRestitution(0)
end

-- the rocker, as the exhibit builds it
local yc = F.Y0 + F.H / 2
local shape = btCompoundShape(true)
for _, pc in ipairs(F.pieces) do
  local hs = btConvexHullShape()
  for _, p in ipairs(pc) do
    hs:addPoint(btVector3(p[1] - F.cx, -F.H / 2, p[2] - F.cz), false)
    hs:addPoint(btVector3(p[1] - F.cx, F.H / 2, p[2] - F.cz), false)
  end
  hs:recalcLocalAabb(); hs:setMargin(0.005)
  shape:addChildShape(btTransform(ident, btVector3(0, 0, 0)), hs)
end
local function pose(phi)
  local c, s = math.cos(phi), math.sin(phi)
  return btTransform(yq(phi), W3(c * F.cx + s * F.cz, yc, -s * F.cx + c * F.cz))
end
local tr0 = pose(math.rad(F.ALPHA - 0.3))
local body = btRigidBody(F.mass, btDefaultMotionState(tr0), shape, btVector3(F.I, F.I, F.I))
local rocker = Cube(0.1, 0.1, 0.1, F.mass)
rocker.body = body
v:add(rocker)
body:setCenterOfMassTransform(tr0)
body:setActivationState(4)
body:setFriction(FR); body:setRestitution(0)
local anchor = Cube(0.01, 0.01, 0.01, 0)
anchor.collides = false
v:add(anchor)
anchor.trans = btTransform(ident, btVector3(0, 0, 0))
local hinge = btHingeConstraint(anchor.body, body, btTransform(BQ * zToY, W3(0, yc, 0)),
                                btTransform(zToY, btVector3(-F.cx, 0, -F.cz)))
v:addConstraint(hinge)
if PF > 0 then hinge:enableAngularMotor(true, 0, PF * STEP) end
peg(-F.pegX, F.pegZ, F.PEG_R); peg(F.pegX, F.pegZ, F.PEG_R)
print(string.format("ROCKER %.2f g (printed %.2f g and the steel ball), centre of mass %.3f cm up the slope from the pin",
                    F.mass * 1000, F.printed * 1000, -F.cz))

-- the run, as above each of the exhibit's flip-flops
local C = G.CHAN / 2 + G.WALL_T / 2
local runBot = -F.A - 1.4 - R
local runTop = runBot - F.RUN - DROP
wall(-C, runTop, -C, runBot); wall(C, runTop, C, runBot)

-- its lean, degrees: positive is apex to the right (the exhibit's 1)
local function lean()
  local a = body:getCenterOfMassTransform():getBasis():getColumn(0)
  local bz = -a.y * sT + a.z * cT
  return math.deg(math.atan2(bz, a.x))
end

local balls, nb, t, nextT = {}, 0, 0, 0.6
local fails, last = 0, nil
local minLean = 90
v:preSim(function(N) for k = 1, NSTEPS - 1 do v:stepSimulation(STEP, 0, STEP) end end)
v:postSim(function(N)
  t = t + STEP * NSTEPS
  if nb < NB and t >= nextT then
    nb = nb + 1
    local b = Sphere(R, MB)
    local jx = JIT > 0 and (math.random() * 2 - 1) * JIT or 0
    b.trans = btTransform(ident, W3(jx, R + 0.002, runTop + R + 0.05))
    v:add(b)
    b.body:setFriction(FR); b.body:setRestitution(0); b.body:setActivationState(4)
    balls[#balls + 1] = { obj = b, n = nb, a0 = lean(), t = t }
    nextT = t + GAP
  end
  for i = #balls, 1, -1 do
    local b = balls[i]
    local x, y, z = L3(b.obj.pos)
    if z > F.T + 2.0 or t - b.t > 3 then
      local side = (z > F.T + 2.0) and (x < 0 and "L" or "R") or "STUCK"
      -- (leaning 1, apex right, the ball goes left; leaning 0, right)
      local want = b.a0 > 0 and "L" or "R"
      local a1 = lean()
      local ok = side == want and (a1 > 0) ~= (b.a0 > 0)
      if not ok then fails = fails + 1 end
      minLean = math.min(minLean, math.abs(a1))
      print(string.format("ball %2d  lean %+6.2f -> out %s -> lean %+6.2f   %.2f s  %s", b.n, b.a0, side, a1, t - b.t,
                          ok and "" or "WRONG"))
      v:remove(b.obj)
      table.remove(balls, i)
      if b.n == NB then
        print(string.format("  least lean after a ball: %.1f degrees (the stops are at %.1f)", minLean, F.ALPHA))
        print(string.format("RESULT toggle: %s (%d wrong of %d)", fails == 0 and "PASS" or "FAIL", fails, NB))
      end
    end
  end
end)
common.setCamera(btVector3(0, 30, 20), btVector3(0, 0, 0))
