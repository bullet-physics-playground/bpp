io.write("Hello world, from ",_VERSION,"!\n")

print("Cube")
cube = Cube()
cube.pos = btVector3(0, 0.5, 0);
cube.color = QColor("#ff0000")

print("Cylinder")
cylinder = Cylinder()
cylinder.pos = btVector3(1, 0.5, 0)
cylinder.color = QColor("#00ff00")

print("Dice")
dice = Dice()
dice.pos = btVector3(2, 0.5, 0)
dice.color = QColor("#0000ff")

print("Plane")
plane = Plane()
plane.pos = btVector3(3, 0.5, 0)

print("Sphere")
sphere = Sphere()
sphere.pos = btVector3(4, 0.5, 0)
sphere.color = QColor("#00ff00")

v:add(cube)
v:add(cylinder)
v:add(dice)
v:add(plane)
v:add(sphere)
