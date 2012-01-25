cube = Cube() 
cube.pos = btVector3(0, 0.5, 0);
cube.color = QColor("#ff0000")

cylinder = Cylinder()
cylinder.pos = btVector3(1, 0.5, 0)
cylinder.color = QColor("#00ff00")

dice = Dice()
dice.pos = btVector3(2, 0.5, 0)
dice.color = QColor("#0000ff")

plane = Plane(0,1,0)
plane.pos = btVector3(0, 0, 0)
plane.color = QColor("#111111")

sphere = Sphere()
sphere.pos = btVector3(4, 0.5, 0)
sphere.color = QColor("#00ff00")

v:add(cube)
v:add(cylinder)
v:add(dice)
v:add(plane)
v:add(sphere)
