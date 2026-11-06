--
-- Screenshot scene for tests/harness.py screens: blobs drawn with the
-- surface POV-Ray renders. Nothing moves (every mass is 0).
--

v.gravity = btVector3(0, 0, 0)

local plane = Plane(0, 1, 0, 0, 20)
plane.col = "#b0b0b0"
v:add(plane)

-- Two spheres close enough that their fields merge into one surface.
local merged = Blob(0.5, 0)
merged:addSphereComponent(btVector3(-0.7, 0, 0), 1.0, 1.0)
merged:addSphereComponent(btVector3(0.7, 0, 0), 1.0, 1.0)
merged.col = "#3a7bd5"
merged.pos = btVector3(-1.6, 0.6, 0)
v:add(merged)

-- Spheres of different strengths and a thin cylinder along y.
local mixed = Blob(0.5, 0)
mixed:addSphereComponent(btVector3(0, 0, 0), 1.2, 1.0)
mixed:addSphereComponent(btVector3(1.0, 0.5, 0.0), 0.8, 0.8)
mixed:addCylinderComponent(btVector3(-0.8, -0.5, 0.0), btVector3(0, 1, 0), 0.5, 1.5, 0.6)
mixed.col = "#d0453a"
mixed.pos = btVector3(1.8, 0.8, 0)
v:add(mixed)

v.cam:setUpVector(btVector3(0, 1, 0), true)
v.cam.pos = btVector3(0, 2.5, 7)
v.cam.look = btVector3(0, 0.6, 0)
