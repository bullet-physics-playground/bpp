-- Who frees what when a script ends: an object frees the shape and motion
-- state it made itself; a shape a script hands in is Lua's; a motion state
-- a script makes belongs to C++ (adopt) and goes with the body that has it,
-- even a body the script made. Each case below must end the script without
-- a double free or a leak (the sanitizer job checks both); here, that the
-- objects still work while the script runs.

local pass = 0
local fail = 0

local function assert_near(name, got, expected)
  if type(got) == "number" and math.abs(got - expected) < 1e-4 then
    print("PASS " .. name)
    pass = pass + 1
  else
    print("FAIL " .. name .. ": got=" .. tostring(got) .. " expected=" .. tostring(expected))
    fail = fail + 1
  end
end

local function at(x, y, z)
  return btTransform(btQuaternion(0, 0, 0, 1), btVector3(x, y, z))
end

-- Its own shape and motion state.
local cube = Cube(1, 1, 1, 0)
cube.pos = btVector3(1, 0, 0)
v:add(cube)
assert_near("own motion state", cube.pos.x, 1)

-- A script's motion state on an object's own body, replaced by obj.pos
-- (which frees it) and then set again, so the script's is there at the end.
local clock = Cube(1, 1, 1, 0)
v:add(clock)
clock.body:setMotionState(btDefaultMotionState(at(2, 0, 0)))
assert_near("script's motion state", clock.pos.x, 2)
clock.pos = btVector3(3, 0, 0)
assert_near("obj.pos after a script's motion state", clock.pos.x, 3)
clock.body:setMotionState(btDefaultMotionState(at(4, 0, 0), at(0, 0, 0)))
assert_near("two-transform motion state", clock.pos.x, 4)

-- A body the script made (its own motion state too) replacing the object's.
local ball = Sphere(1, 1)
ball.body = btRigidBody(1, btDefaultMotionState(at(0, 5, 0)), btSphereShape(1), btVector3(1, 1, 1))
v:add(ball)
assert_near("script's body", ball.pos.y, 5)

-- A Bound around a shape the script made: the shape stays Lua's.
local shape = btBoxShape(btVector3(1, 1, 1))
local bound = Bound(shape, 0)
v:add(bound)
assert_near("Bound with a script's shape", bound.pos.x, 0)

-- An object the script takes back with v:remove, with a motion state of
-- its own making: Lua frees the object.
local gone = Cube(1, 1, 1, 0)
v:add(gone)
gone.body:setMotionState(btDefaultMotionState(at(6, 0, 0)))
v:remove(gone)
assert_near("removed object", gone.pos.x, 6)

-- One the script never adds, with a motion state of its making: Lua owns
-- the object (and frees it as Lua closes).
local loose = Cube(1, 1, 1, 0)
loose.body:setMotionState(btDefaultMotionState(at(7, 0, 0)))
assert_near("object never added", loose.pos.x, 7)

-- A body the script makes and gives no object: its motion state goes when
-- the script ends.
local bare = btRigidBody(1, btDefaultMotionState(at(0, 8, 0)), btSphereShape(1), btVector3(1, 1, 1))
assert_near("body with no object", bare:getCenterOfMassPosition().y, 8)

v:stepSimulation(1 / 60, 1, 1 / 60)

print(string.format("\n%d passed, %d failed", pass, fail))
