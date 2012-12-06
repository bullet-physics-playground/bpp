plane = Plane(0,1,0)
plane.pos = btVector3(0, 0, 0)
plane.col = "#111111"
v:add(plane)

pal = Palette("demo/pal_ggl.gpl")
pal:setSeed(4)

cube = Cube(0.75,0.25,4.75,10) 
cube.pos = btVector3(0, 1, 0);
cube.color = pal:getRandomColor()
v:add(cube)

c0 = Cylinder(1,1,0.25)
c0.pos = btVector3(0, 1, 2.5)
c0.color = pal:getRandomColor()
v:add(c0)

c1 = Cylinder(1,1,0.25)
c1.pos = btVector3(0, 1, -2.5)
c1.color = pal:getRandomColor()
v:add(c1)

pivot0 = btVector3(0,0,0)
axis0  = btVector3(0,0,1)

pivot1 = btVector3(0,0,-2.5)
axis1  = btVector3(0,0,1)

pivot2 = btVector3(0,0,2.5)
axis2  = btVector3(0,0,1)

con0 = btHingeConstraint(cube:getRigidBody(), c0:getRigidBody(), pivot0, pivot1, axis0, axis1)

con0:enableAngularMotor(true, 2, 1)

v:addConstraint(con0)

con1 = btHingeConstraint(cube:getRigidBody(), c1:getRigidBody(), pivot0, pivot2, axis0, axis2)

con1:enableAngularMotor(true, -2, 1)

v:addConstraint(con1)
