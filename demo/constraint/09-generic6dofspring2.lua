--
-- btGeneric6DofSpring2Constraint demo
-- The improved successor to btGeneric6DofSpringConstraint: a more stable
-- spring implementation, plus servo motor support (drives an axis toward
-- a target position/angle at a bounded speed, rather than just spinning
-- at a constant velocity like a plain motor).
--

plane = Plane(0,1,0,0,10)
plane.col = "#222222"
v:add(plane)

base = Cube(1,0.5,1,0)
base.pos = btVector3(0, 8, 0)
base.col = "#444444"
v:add(base)

link = Cube(1,1,1,1)
link.pos = btVector3(0, 5, 0)
link.col = "#ff6600"
v:add(link)

frameInA = btTransform()
frameInA:setIdentity()
frameInA:setOrigin(btVector3(0, -1, 0))

frameInB = btTransform()
frameInB:setIdentity()
frameInB:setOrigin(btVector3(0, 1.5, 0))

con = btGeneric6DofSpring2Constraint(
  base.body, link.body,
  frameInA, frameInB)

-- X and Z are locked (lower==upper==0); Y is a limited, spring-loaded
-- range -- like a suspension the link hangs and bobs on.
con:setLinearLowerLimit(btVector3(0, -4, 0))
con:setLinearUpperLimit(btVector3(0, 1, 0))
con:enableSpring(1, true)
con:setStiffness(1, 40, true)
con:setDamping(1, 0.3, true)
con:setEquilibriumPoint(1, -2)

-- X/Y rotation locked; Z is free to swing, driven by a servo motor toward
-- a target angle that sweeps back and forth (see postSim below) -- unlike
-- a plain motor's constant spin, the link visibly settles wherever the
-- target currently is instead of endlessly spinning past it.
con:setAngularLowerLimit(btVector3(0, 0, -math.pi))
con:setAngularUpperLimit(btVector3(0, 0, math.pi))
con:enableMotor(5, true)
con:setServo(5, true)
con:setTargetVelocity(5, 3)
con:setMaxMotorForce(5, 300)

v:addConstraint(con)

v:postSim(function(N)
  local target = math.sin(N / 90 * math.pi * 2) * math.pi * 0.4
  con:setServoTarget(5, target)
end)

v.cam:setUpVector(btVector3(0, 1, 0), true)
v.cam.pos  = btVector3(10, 8, 14)
v.cam.look = btVector3(0, 4, 0)

-- EOF
