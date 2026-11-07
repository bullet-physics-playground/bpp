--
-- Screenshot scene for tests/harness.py screens: a marker for each joint
-- type (v.showConstraints), each joining two small boxes. Nothing moves
-- (every mass is 0), so the picture does not depend on when it is taken.
--

v.gravity = btVector3(0, 0, 0)
v.showConstraints = true

local plane = Plane(0, 1, 0, 0, 20)
plane.col = "#9aa5b1"
v:add(plane)

local function box(x, z, size)
  size = size or 0.5
  local o = Cube(size, size, size, 0)
  o.col = "#4c78a8"
  o.pos = btVector3(x, 0.5, z)
  v:add(o)
  return o.body
end

local function frame(x, y, z)
  return btTransform(btQuaternion(0, 0, 0, 1), btVector3(x, y, z))
end

-- Each joint sits between a pair of boxes 1 apart along x; pairs are laid
-- out in two rows.
local function pair(i, size)
  local x, z = (i % 5) * 2.2 - 4.4, math.floor(i / 5) * 2.5 - 1.25
  return box(x - 0.5, z, size), box(x + 0.5, z)
end

local right, left = btVector3(0.5, 0, 0), btVector3(-0.5, 0, 0)
local a, b

a, b = pair(0)
v:addConstraint(btPoint2PointConstraint(a, b, right, left))
a, b = pair(1)
v:addConstraint(btHingeConstraint(a, b, right, left, btVector3(0, 1, 0), btVector3(0, 1, 0)))
a, b = pair(2)
v:addConstraint(btSliderConstraint(a, b, frame(0.5, 0, 0), frame(-0.5, 0, 0), true))
a, b = pair(3)
v:addConstraint(btConeTwistConstraint(a, b, frame(0.5, 0, 0), frame(-0.5, 0, 0)))
a, b = pair(4)
v:addConstraint(btGeneric6DofConstraint(a, b, frame(0.5, 0, 0), frame(-0.5, 0, 0), true))
a, b = pair(5)
v:addConstraint(btGeneric6DofSpringConstraint(a, b, frame(0.5, 0, 0), frame(-0.5, 0, 0), true))
a, b = pair(6)
v:addConstraint(btFixedConstraint(a, b, frame(0.5, 0, 0), frame(-0.5, 0, 0)))
a, b = pair(7)
v:addConstraint(btHinge2Constraint(a, b, btVector3(0, 0.5, 1.25), btVector3(0, 1, 0), btVector3(1, 0, 0)))
-- (a gear's axes go through its bodies' centres: one body is tiny, so the
-- marker shows outside it)
a, b = pair(8, 0.1)
v:addConstraint(btGearConstraint(a, b, btVector3(0, 1, 0), btVector3(0, 1, 0), 2))
a, b = pair(9)
v:addConstraint(btGeneric6DofSpring2Constraint(a, b, frame(0.5, 0, 0), frame(-0.5, 0, 0)))

v.cam:setUpVector(btVector3(0, 1, 0), true)
v.cam.pos = btVector3(0, 6, 8)
v.cam.look = btVector3(0, 0.5, 0)
