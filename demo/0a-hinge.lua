plane = Plane(0,1,0)
plane.col = "#111111"
v:add(plane)

cube = Cube(0.75,0.25,4.75,10) 
cube.pos = btVector3(0, 1, 0);
cube.col = "#ff0000"
v:add(cube)

c0 = Cylinder(1,1,0.25,1)
c0.pos = btVector3(0, 1, 2.5)
c0.col = "#00ff00"
v:add(c0)

c1 = Cylinder(1,1,0.25,1)
c1.pos = btVector3(0, 1, -2.5)
c1.col = "#0000ff"
v:add(c1)

pivot0 = btVector3(0,0,0)
axis0  = btVector3(0,0,1)

pivot1 = btVector3(0,0,-2.5)
axis1  = btVector3(0,0,1)

pivot2 = btVector3(0,0,2.5)
axis2  = btVector3(0,0,1)

con0 = btHingeConstraint(
  cube:getRigidBody(),
  c0:getRigidBody(),
  pivot0, pivot1, axis0, axis1)

con0:enableAngularMotor(true, 2, 1)

v:addConstraint(con0)

con1 = btHingeConstraint(
  cube:getRigidBody(),
  c1:getRigidBody(),
  pivot0, pivot2, axis0, axis2)

con1:enableAngularMotor(true, -2, 1)

v:addConstraint(con1)
