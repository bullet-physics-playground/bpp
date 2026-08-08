--
-- Demo of the RigidSoftContact class
--
-- This demo shows the basic usage of RigidSoftContact: a read-only
-- snapshot of one of Bullet's soft-vs-rigid collision contacts (what
-- Bullet itself calls a "Rigid contact", btSoftBody::RContact, stored in
-- btSoftBody::m_rcontacts). Bullet regenerates the whole contact array
-- from scratch every simulation step, so these are copied-out values, not
-- live references: query them via SoftBody:getContact(i) after a
-- simulation step, e.g. from a postSim callback.
--
-- Usage: bpp -f demo/basic/17-rigid-soft-contact.lua
--

local color  = require "color"
local common = require "common"

common.setTiming(1/25, 30, 1/120)

--
-- SCENE SETUP
--

-- Ground plane
ground = Plane(0,1,0,0,20)
ground.col = color.darkgray
ground.friction = 0.8
v:add(ground)

-- A static cube for the cloth to drape over, so contacts show up against
-- two different rigid bodies (the cube and the ground) at once.
box = Cube(1,1,1,0) -- 1x1x1, mass 0 => static
box.pos = btVector3(0, 0.5, 0)
box.col = color.steelblue
box.friction = 0.8
v:add(box)

-- A small cloth patch dropped flat above the ground, so it lands and
-- generates soft-vs-rigid contacts we can inspect.
sb = SoftBody(4, 4, 100, 100, 1.0, 0)
sb.col = color.coral
sb.pos = btVector3(0, 3, 0)
v:add(sb)

-- Camera
common.setCamera(btVector3(6, 4, 6), btVector3(0, 0.5, 0), 0.5)

local function vecToString(v3)
  return string.format("(%.2f, %.2f, %.2f)", v3.x, v3.y, v3.z)
end

-- preStart: Called once before simulation starts
v:preStart(function(N)
  print("preStart("..tostring(N)..")")
end)

-- Maps a RigidSoftContact's .body back to the name of the Object it
-- belongs to, so the log below reads "ground"/"box" instead of a raw
-- btRigidBody handle.
local function bodyName(body)
  if body == ground.body then return "ground" end
  if body == box.body then return "box" end
  return "unknown"
end

-- postSim: Called after each simulation step. SoftBody:contactCount is
-- the number of active rigid-soft contacts this step; SoftBody:getContact(i)
-- (0-indexed) returns a RigidSoftContact snapshot with .node (the soft
-- body node index touching a rigid body), .body (the btRigidBody touched),
-- .pos (world contact position), .normal, .friction and .hardness.
local wasTouching = false

v:postSim(function(N)
  local n = sb.contactCount

  if N == 1 or N % 20 == 0 or (n > 0 and not wasTouching) then
    if n == 0 then
      print(N..": cloth is falling, 0 contacts")
    else
      local c = sb:getContact(0)
      print(N..": "..n.." contacts, first one: node="..c.node
            .." pos="..vecToString(c.pos)
            .." normal="..vecToString(c.normal)
            .." friction="..string.format("%.2f", c.friction)
            .." touching="..bodyName(c.body))
    end
  end

  wasTouching = (n > 0)
end)

-- EOF
