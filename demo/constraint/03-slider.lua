--
-- btSliderConstraint demo
-- Slider constraint allows relative motion along one axis (linear sliding)
-- and optionally rotation around that axis (angular)
--

plane = Plane(0,1,0,0,10)
plane.pos = btVector3(0, -3, 0)
plane.col = "#222222"
--v:add(plane)

base = Cube(15,0.5,2,0)
base.pos = btVector3(0, 0.5, 0)
base.col = "#444444"
v:add(base)

slider = Cube(1.5,0.5,2,1)
slider.pos = btVector3(0, 1, 0)
slider.col = "#ff6600"
v:add(slider)

-- Inverted Pendulum
pendulum = Cylinder(0.2, 3, 1)
pendulum.pos = btVector3(0, 3, 2)
pendulum.col = "#00ff00"
v:add(pendulum)

-- Second Pendulum Cylinder
pendulum2 = Cylinder(0.2, 4, 1)
pendulum2.pos = btVector3(0, 3, 4)
pendulum2.col = "#0000ff"
v:add(pendulum2)

pendulum_con = btHingeConstraint(
  slider.body, pendulum.body,
  btVector3(0, 0.5, 1), btVector3(0, 0, -1),
  btVector3(0, 0, 1), btVector3(0, 0, 1))
v:addConstraint(pendulum_con)

pendulum_con2 = btHingeConstraint(
  pendulum.body, pendulum2.body,
  btVector3(0, 0, 1), btVector3(0, 0, -2.5),
  btVector3(0, 1, 0), btVector3(0, 2, 0))
v:addConstraint(pendulum_con2)

frameInA = btTransform()
frameInA:setIdentity()
frameInA:setOrigin(btVector3(0, 1, 0))

frameInB = btTransform()
frameInB:setIdentity()
frameInB:setOrigin(btVector3(0, 0.5, 0))

con = btSliderConstraint(
  base.body, slider.body,
  frameInA, frameInB,
  true)

con:setLowerLinLimit(-5)
con:setUpperLinLimit(5)
con:setPoweredLinMotor(true)
con:setMaxLinMotorForce(500)

con:setPoweredAngMotor(true)
con:setMaxAngMotorForce(500)

v:addConstraint(con)

v:postSim(function(N)
  linVel = math.sin(N / 60 * math.pi * 2) * 20
  angVel = math.sin(N / 60 * math.pi * 2) * 5
  con:setTargetLinMotorVelocity(linVel)
  con:setTargetAngMotorVelocity(angVel)
end)

v.cam:setUpVector(btVector3(0.0404929, 0.837619, -0.544752), true)
v.cam.up   = btVector3(0.0404929, 0.837619, -0.544752)
v.cam.pos  = btVector3(-1.07499, 14.0327, 21.5028)
v.cam.look = btVector3(41823.5, -546128, -836626)

-- EOF