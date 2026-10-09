--
-- Gomboc self-righting test
--
-- Nine copies of the GOMBOC900 mesh (scaled to metres, centred on its centre
-- of mass) are dropped onto a plane, each starting with a different body
-- direction pointing down. A true gomboc has a single stable equilibrium, so
-- every copy should end up resting on the same point: body -X pointing down.
-- The unstable equilibrium (the tip) is body +X.
--
-- Usage: bpp demo/mesh/gomboc-test.lua      (GUI)
--

local common = require "common"

common.setTiming(1/30, 40, 1/240)
v.gravity = btVector3(0, -9.81, 0)

local LOG = os.getenv("GOMBOC_LOG") or "gomboc-log.csv"
local STL = os.getenv("GOMBOC_STL") or "demo/mesh/gomboc_m.stl"

-- ground
local ground = Plane(0, 1, 0, 0, 12)
ground.col = "#30343a"
ground.friction = 0.8
v:add(ground)

-- mass properties from the exact CAD solid (density 1000 kg/m^3)
local MASS = 268.85
-- principal radii of gyration^2 (m^2), axes aligned with body x, y, z
local K2 = btVector3(0.067876, 0.057974, 0.072609)

local function quatDown(d)
  -- rotation taking body direction d to world down (0,-1,0)
  local n = math.sqrt(d.x*d.x + d.y*d.y + d.z*d.z)
  d = btVector3(d.x/n, d.y/n, d.z/n)
  local down = btVector3(0, -1, 0)
  local c = d:dot(down)
  local axis = btVector3(d.y*down.z - d.z*down.y,
                         d.z*down.x - d.x*down.z,
                         d.x*down.y - d.y*down.x)
  local s = math.sqrt(axis.x^2 + axis.y^2 + axis.z^2)
  if s < 1e-9 then
    if c > 0 then return btQuaternion(0, 0, 0, 1) end
    return btQuaternion(btVector3(0, 0, 1), math.pi)
  end
  axis = btVector3(axis.x/s, axis.y/s, axis.z/s)
  return btQuaternion(axis, math.atan2(s, c))
end

-- initial "down" directions in body coordinates
local cases = {
  { "tip +X (unstable)", btVector3( 1, 0.01, 0.01) },
  { "+Y",                btVector3( 0, 1, 0) },
  { "-Y",                btVector3( 0,-1, 0) },
  { "+Z",                btVector3( 0, 0, 1) },
  { "-Z",                btVector3( 0, 0,-1) },
  { "+X+Y+Z",            btVector3( 1, 1, 1) },
  { "+X-Y",              btVector3( 1,-1, 0) },
  { "+Y-Z",              btVector3( 0, 1,-1) },
  { "-X (stable, control)", btVector3(-1, 0, 0) },
}

local bodies = {}
local spacing = 1.6

for i, c in ipairs(cases) do
  local m = Mesh(STL, MASS, true)
  m.col = "#f2c58a"
  m.friction = 0.8
  m.restitution = 0.0
  local col = (i - 1) % 3
  local row = math.floor((i - 1) / 3)
  m.trans = btTransform(quatDown(c[2]),
                        btVector3((col - 1) * spacing, 0.52, (row - 1) * spacing))
  v:add(m)
  m.body:setMassProps(MASS, btVector3(MASS*K2.x, MASS*K2.y, MASS*K2.z))
  m.body:setSleepingThresholds(0, 0)
  m.body:setDamping(0.02, 0.05)
  bodies[i] = { name = c[1], m = m }
end

common.setCamera(btVector3(4.2, 3.6, 4.8), btVector3(0, 0.1, 0), 0.6)

local f = io.open(LOG, "w")
f:write("t,idx,name,angle_to_stable_deg,com_y,speed,down_x,down_y,down_z\n")

local frame = 0
v:postSim(function(N)
  frame = frame + 1
  if frame % 15 ~= 0 then return end
  local t = frame * (1/30)
  for i, b in ipairs(bodies) do
    local tr = b.m.trans
    local R = tr:getBasis()
    -- world down expressed in body coordinates: R^T * (0,-1,0)
    local dx = -R:getColumn(0).y
    local dy = -R:getColumn(1).y
    local dz = -R:getColumn(2).y
    local cosang = math.max(-1, math.min(1, -dx))   -- vs body (-1,0,0)
    local ang = math.deg(math.acos(cosang))
    local vel = b.m.vel
    local sp = math.sqrt(vel.x^2 + vel.y^2 + vel.z^2)
    f:write(string.format("%.2f,%d,%s,%.3f,%.5f,%.5f,%.4f,%.4f,%.4f\n",
      t, i, b.name, ang, b.m.pos.y, sp, dx, dy, dz))
  end
  f:flush()
end)
