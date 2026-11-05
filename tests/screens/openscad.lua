--
-- Screenshot scene for tests/harness.py screens: a solid built by OpenSCAD
-- (needs openscad on the PATH). Nothing moves (every mass is 0).
--

v.gravity = btVector3(0, 0, 0)

local plane = Plane(0, 1, 0, 0, 20)
plane.col = "#b0b0b0"
v:add(plane)

local o = OpenSCAD([[
difference() {
  cube([2, 2, 2], center = true);
  sphere(r = 1.3, $fn = 48);
}
]], 0)
o.col = "#e8a33d"
o.pos = btVector3(0, 1, 0)
v:add(o)

v.cam:setUpVector(btVector3(0, 1, 0), true)
v.cam.pos = btVector3(4, 4, 6)
v.cam.look = btVector3(0, 0.8, 0)
