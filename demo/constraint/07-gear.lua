--
-- btGearConstraint demo
-- Two gears coupled by btGearConstraint, gearA driven by motor
--


theta = math.pi / 100

l1 = 2 - math.tan(theta)
l2 = 1 / math.cos(theta)
ratio = l2 / l1

gearA = Mesh("demo/mesh/spur-01.stl", 1, false)
gearA.pos = btVector3(-25, 10, 0)
gearA.col = "#ff0000"
v:add(gearA)

gearB = Mesh("demo/mesh/spur-02.stl", 1, false)
gearB.pos = btVector3(25, 10, 0)
q = btQuaternion()
q:setEulerZYX(0, 0, -theta)
gearB.rot = q
gearB.col = "#006600"
v:add(gearB)

gearA.body:setLinearFactor(btVector3(0, 0, 0))
gearA.body:setAngularFactor(btVector3(0, 0, 1))

hinge = btHingeConstraint(
  gearA.body,
  btVector3(0, 0, 0),
  btVector3(0, 0, 1))
hinge:enableAngularMotor(true, 2, 10)
v:addConstraint(hinge)

con = btGearConstraint(
  gearA.body, gearB.body,
  btVector3(0, 0, 1), btVector3(0, 0, 1),
  ratio)

v:addConstraint(con)

hingeB = btHingeConstraint(
  gearB.body,
  btVector3(0, 0, 0),
  btVector3(0, 0, 1))
v:addConstraint(hingeB)

v.cam:setUpVector(btVector3(0,1,0), true)
v.cam.pos = btVector3(10, 100, 100)
v.cam.look = btVector3(0, 10, 0)

-- EOF