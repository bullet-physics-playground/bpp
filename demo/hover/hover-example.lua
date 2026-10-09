local common = require "common"
v.gravity = btVector3(0, 0, 0)
local floor = Plane(0, 1, 0, -10, 100); v:add(floor)
local m = Mesh("demo/dzhanibekov/dzhanibekov-meshes/t-handle.obj", 0, false)
local c = Cube(4, 4, 4, 0); c.pos = btVector3(10, 0, 0); v:add(c)
local hull = btConvexHullShape()
hull:addPoint(btVector3(-5, -1, -1), false); hull:addPoint(btVector3(5, 3, 1), false); hull:addPoint(btVector3(-5, 3, -1), false); hull:addPoint(btVector3(5, -1, 1), true)
m.body = btRigidBody(1, btDefaultMotionState(btTransform(btQuaternion(0,0,0,1), btVector3(-8, 0, 0))), hull, btVector3(1,1,1))
v:add(m)
common.setCamera(btVector3(0, 0, 40), btVector3(0, 0, 0))
local NAME = { [objectKey(m)] = "the T mesh", [objectKey(c)] = "the cube", [objectKey(floor)] = "the floor" }
v:onHover(function(N, obj, x, y, z)
  local n = NAME[objectKey(obj)] or "something else"
  print(string.format("hover: %s at %.1f %.1f %.1f", n, x, y, z))
  return string.format("This is %s\nhit at (%.1f, %.1f, %.1f)\nframe %d", n, x, y, z, N)
end)
