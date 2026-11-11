--
-- Screenshot scene for tests/harness.py screens: the hover (v:onHover).
-- The harness rests the pointer on the middle of the view (the line below)
-- and grabs the screen there, the tooltip included. A cube that doesn't
-- collide stands in front of a ball; its hook has nothing to say, so the
-- hover looks through it to the ball, which says what it is and where the
-- ray hit it. A second ball, off to the side, says something else, so the
-- picture shows which one was found.
--
-- mouse: 505 370
--

v.gravity = btVector3(0, 0, 0)

local plane = Plane(0, 1, 0, 0, 20)
plane.col = "#9aa5b1"
v:add(plane)

local ball = Sphere(2, 0)
ball.col = "#1f77b4"
ball.pos = btVector3(0, 2, 0)
v:add(ball)

local other = Sphere(1, 0)
other.col = "#d62728"
other.pos = btVector3(5, 1, 0)
v:add(other)

local glass = Cube(1.5, 1.5, 1.5, 0)
glass.col = "#2ca02c"
glass.pos = btVector3(0, 2, 4)
glass.collides = false
v:add(glass)

v.cam:setUpVector(btVector3(0, 1, 0), true)
v.cam.pos = btVector3(0, 2, 14)
v.cam.look = btVector3(0, 2, 0)

local names = { [objectKey(ball)] = "the blue ball", [objectKey(other)] = "the red ball" }

v:onHover(function(N, obj, x, y, z)
  local name = names[objectKey(obj)]
  if not name then return end        -- the plane, the green cube: nothing
  return string.format("%s\nhit at %.1f %.1f %.1f", name, x, y, z)
end)
