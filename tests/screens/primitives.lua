--
-- Screenshot scene for tests/harness.py screens: each primitive shape, in
-- its own colour, on a plane. Nothing moves (every mass is 0), so the
-- picture does not depend on when it is taken.
--

v.gravity = btVector3(0, 0, 0)

local plane = Plane(0, 1, 0, 0, 20)
plane.col = "#9aa5b1"
v:add(plane)

local function place(o, col, x, y, z)
  o.col = col
  o.pos = btVector3(x, y, z)
  v:add(o)
  return o
end

place(Cube(1, 1, 1, 0), "#d62728", -3, 0.5, 0)
place(Sphere(0.6, 0), "#2ca02c", -1.5, 0.6, 0)
place(Cylinder(0.5, 1, 0), "#1f77b4", 0, 0.5, 0)
place(Cone(0.5, 1, 0), "#ff7f0e", 1.5, 0.5, 0)
place(Torus(0.5, 0.2, 0), "#9467bd", 3, 0.2, 0)
place(Cube(0.6, 2, 0.6, 0), "#8c564b", 0, 1, -2)

v.cam:setUpVector(btVector3(0, 1, 0), true)
v.cam.pos = btVector3(2, 5, 12)
v.cam.look = btVector3(0, 0.5, 0)
