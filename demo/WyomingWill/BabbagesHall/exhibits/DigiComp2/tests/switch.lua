--
-- tests/switch.lua -- one Digi-Comp II switch alone (Babbage's Hall)
--
-- A flap on a pin at the tip of the divider between two outlets (the shape
-- the exhibit uses: digicomp2-geometry.lua), its free end up the slope
-- against one wall of the inlet, closing that outlet. The hand sets it one
-- way or the other, then a ball comes down: it should leave by the open
-- outlet and leave the flap where it was. Prints each ball and
-- "RESULT switch: PASS" when all went right.
--
-- Run from the repository's top folder:
--   bpp -f demo/WyomingWill/BabbagesHall/exhibits/DigiComp2/tests/switch.lua -n 900
-- env: SW_SEQ (how the hand sets it before each ball, L closing the left
--      outlet or R, "LLRRLRRLLR"), SW_FR (friction, 0.3), SW_PF (the pin's
--      friction, kg cm^2/s^2, 0.4), SW_TH (slope, 15), SW_DROP (cm of run
--      above the inlet, 4)
--
local common = require "common"
local function envnum(n, d) return tonumber(os.getenv(n) or "") or d end
local DIR
for _, d in ipairs({ "", "../", "demo/WyomingWill/BabbagesHall/exhibits/DigiComp2/" }) do
  local f = io.open(d .. "digicomp2-geometry.lua", "r")
  if f then f:close(); DIR = d; break end
end
assert(DIR, "switch test: can't find digicomp2-geometry.lua")
local G = dofile(DIR .. "digicomp2-geometry.lua")
local SW = G.SWITCH
local TH = math.rad(envnum("SW_TH", 15))
local R, MB = G.R, G.BALL_MASS
local FR, PF = envnum("SW_FR", 0.3), envnum("SW_PF", 0.4)
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
local function wall(x1, z1, x2, z2)
  local dx, dz = x2 - x1, z2 - z1
  local c = Cube(math.sqrt(dx * dx + dz * dz) + G.WALL_T, G.WALL_H, G.WALL_T, 0)
  c.trans = btTransform(yq(math.atan2(-dz, dx)), W3((x1 + x2) / 2, G.WALL_H / 2, (z1 + z2) / 2))
  v:add(c); c.body:setFriction(1); c.body:setRestitution(0)
end
local board = Cube(40, 1, 40, 0)
board.trans = btTransform(BQ, W3(0, -0.5, 0)); v:add(board); board.body:setFriction(1); board.body:setRestitution(0)

-- the junction: an inlet (wide enough for the flap beside the ball), the
-- divider's tip at (0, 0), two outlets below
local CH = G.CHAN
local FT, IW, FL = SW.FT, SW.IW, SW.FL
local half = IW / 2
local C = half + G.WALL_T / 2
local zTop = -FL - envnum("SW_DROP", 4)
wall(-C, zTop, -C, -FL + 0.2); wall(C, zTop, C, -FL + 0.2)
-- (the inlet's walls flare out to the outlets' outer walls)
local OX = SW.OX                               -- each outlet's centre
local OC = CH / 2 + G.WALL_T / 2
wall(-C, -FL + 0.2, -OX - OC, 0.6); wall(C, -FL + 0.2, OX + OC, 0.6)
wall(-OX - OC, 0.6, -OX - OC, 6); wall(OX + OC, 0.6, OX + OC, 6)
-- the divider: a wedge from the tip down between the outlets
wall(0, 0.55, -OX + OC, 1.8); wall(0, 0.55, OX - OC, 1.8)
wall(-OX + OC, 1.8, -OX + OC, 6); wall(OX - OC, 1.8, OX - OC, 6)

-- the flap: pivot at (0, 0); its end against a wall at (+-(half - FT/2), -L)
local ang = math.asin((half - FT / 2) / FL)     -- its lean either way
local mass, I = SW.mass, SW.I
local cz = -FL / 2
local yc = SW.Y0 + SW.H / 2
local shape = btCompoundShape(true)
local bx = btBoxShape(btVector3(FT / 2, SW.H / 2, FL / 2)); bx:setMargin(0.005)
shape:addChildShape(btTransform(ident, btVector3(0, 0, 0)), bx)
local function pose(phi)   -- (phi right-handed: + leans its end to the left... see below)
  local c, s = math.cos(phi), math.sin(phi)
  return btTransform(yq(phi), W3(s * cz, yc, c * cz))
end
local body = btRigidBody(mass, btDefaultMotionState(pose(ang)), shape, btVector3(I, I, I))
local flap = Cube(0.1, 0.1, 0.1, mass); flap.body = body; v:add(flap)
body:setCenterOfMassTransform(pose(ang)); body:setActivationState(4); body:setFriction(FR); body:setRestitution(0)
local anchor = Cube(0.01, 0.01, 0.01, 0); anchor.collides = false; v:add(anchor)
anchor.trans = btTransform(ident, btVector3(0, 0, 0))
local hinge = btHingeConstraint(anchor.body, body, btTransform(BQ * zToY, W3(0, yc, 0)),
                                btTransform(zToY, btVector3(0, 0, -cz)))
v:addConstraint(hinge)
if PF > 0 then hinge:enableAngularMotor(true, 0, PF * STEP) end
-- which way its end leans: x of its end
local function endX()
  local tr = body:getCenterOfMassTransform()
  local p = tr:getBasis():getColumn(2)         -- its z axis (toward the pin from the end is +z)
  return -p.x * FL / 2 * 2
end
print(string.format("FLAP %.2f g, leaning %.1f degrees either way", mass * 1000, math.deg(ang)))

local SEQ = os.getenv("SW_SEQ") or "LLRRLRRLLR"
local t, k, cur, pt = 0, 0, nil, 0
local fails = 0
v:preSim(function(N) for i = 1, NSTEPS - 1 do v:stepSimulation(STEP, 0, STEP) end end)
v:postSim(function(N)
  t = t + STEP * NSTEPS; pt = pt + STEP * NSTEPS
  if not cur and pt > 0.5 and k < #SEQ then
    k = k + 1
    local set = SEQ:sub(k, k)
    -- the hand sets it: L closes the left outlet (its end against the left wall)
    local phi = (set == "L") and ang or -ang
    body:setCenterOfMassTransform(pose(phi)); body:setLinearVelocity(btVector3(0, 0, 0)); body:setAngularVelocity(btVector3(0, 0, 0))
    local b = Sphere(R, MB)
    b.trans = btTransform(ident, W3((math.random() - 0.5) * 0.1, R + 0.002, zTop + 0.8))
    v:add(b); b.body:setFriction(FR); b.body:setRestitution(0); b.body:setActivationState(4)
    cur = { obj = b, set = set, t = t }
  end
  if cur then
    local x, y, z = L3(cur.obj.pos)
    if z > 5 or t - cur.t > 3 then
      local out = (t - cur.t > 3) and string.format("STUCK(%.2f,%.2f)", x, z) or (x < 0 and "L" or "R")
      local ex = endX()
      local held = (cur.set == "L") == (ex < 0)
      local ok = held and out == ((cur.set == "L") and "R" or "L")
      if not ok then fails = fails + 1 end
      print(string.format("set %s: ball out %s, flap end at x %+.2f %s", cur.set, out, ex, ok and "" or "WRONG"))
      v:remove(cur.obj); cur = nil; pt = 0
      if k == #SEQ then print(string.format("RESULT switch: %s (%d wrong of %d)", fails == 0 and "PASS" or "FAIL", fails, #SEQ)) end
    end
  end
end)
