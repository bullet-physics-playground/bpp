-- A second world (v:newWorld) with a joint between two bodies the script
-- made itself. Quitting must not touch them after Lua has freed them: the
-- joint comes out of its world while its bodies are still there. (Seen
-- only under a memory checker -- the sanitizer job -- as a use after free
-- in Viewer::dropWorlds() at exit.)

local w = v:newWorld()
v:useWorld(w)
local shape = btSphereShape(1)
local function body(y, mass)
  local b = btRigidBody(mass, btDefaultMotionState(btTransform(btQuaternion(0, 0, 0, 1), btVector3(0, y, 0))),
                        shape, btVector3(1, 1, 1))
  local o = Sphere(1, mass)
  o.body = b
  v:add(o)
  return b
end
local top, bottom = body(10, 0), body(8, 1)
v:addConstraint(btPoint2PointConstraint(top, bottom, btVector3(0, -1, 0), btVector3(0, 1, 0)))
for i = 1, 60 do v:stepSimulation(1 / 60, 1, 1 / 60) end
v:useWorld(0)
print(string.format("PASS the joint holds in its own world (%.2f)", bottom:getCenterOfMassPosition().y))
print("\n1 passed, 0 failed")
