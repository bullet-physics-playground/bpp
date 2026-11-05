--
-- Screenshot scene for tests/harness.py screens: shadows, transparency and
-- a rotated body. Nothing moves (every mass is 0).
--

v.gravity = btVector3(0, 0, 0)
v.shadows = true

local plane = Plane(0, 1, 0, 0, 20)
plane.col = "#e0e0e0"
v:add(plane)

local tall = Cube(0.5, 3, 0.5, 0)
tall.col = "#444444"
tall.pos = btVector3(-2, 1.5, 0)
v:add(tall)

local glass = Cube(2, 2, 0.2, 0)
glass.col = "#3399ff"
glass.transparency = 0.5
glass.pos = btVector3(0, 1, 1)
v:add(glass)

local behind = Sphere(0.7, 0)
behind.col = "#cc2222"
behind.pos = btVector3(0, 0.7, -0.5)
v:add(behind)

local tilted = Cube(1, 1, 1, 0)
tilted.col = "#22aa55"
tilted.trans = btTransform(btQuaternion(btVector3(1, 1, 0), 0.6), btVector3(2.2, 1, 0))
v:add(tilted)

v.cam:setUpVector(btVector3(0, 1, 0), true)
v.cam.pos = btVector3(-3, 6, 10)
v.cam.look = btVector3(0, 0.8, 0)
