--
-- btHinge2Constraint demo
-- Models a steerable, driven, sprung wheel, like a real vehicle
-- suspension: 2 rotational DOFs -- steering around axis1, wheel spin
-- around axis2 (must be orthogonal to axis1) -- plus 1 translational DOF
-- for suspension travel, all in a single constraint.
--

plane = Plane(0,1,0,0,20)
plane.col = "#222222"
v:add(plane)

chassis = Cube(2, 0.5, 1, 0)
chassis.pos = btVector3(0, 5, 0)
chassis.col = "#444444"
v:add(chassis)

wheelRadius = 1.2
wheel = Cylinder(wheelRadius, 0.6, 3)
wheel.pos = btVector3(3, 3.5, 0)
q = btQuaternion()
q:setEulerZYX(0, math.pi / 2, 0) -- lay the cylinder on its side: axis along X, like a wheel
wheel.rot = q
wheel.col = "#4488ff" -- distinct from the orange constraint-visualization gizmo
v:add(wheel)

anchor = btVector3(3, 4.2, 0)
axis1  = btVector3(0, 1, 0) -- steering axis (the vertical strut)
axis2  = btVector3(1, 0, 0) -- wheel spin axis, orthogonal to axis1

con = btHinge2Constraint(chassis.body, wheel.body, anchor, axis1, axis2)

-- Suspension: linear travel along the constraint's own local Z, spring-
-- loaded so the wheel bobs and settles under gravity instead of being
-- rigidly held at its starting height.
con:setLinearLowerLimit(btVector3(0, 0, -0.8))
con:setLinearUpperLimit(btVector3(0, 0, 0.3))
con:enableSpring(2, true)
con:setStiffness(2, 60, true)
con:setDamping(2, 0.4, true)
con:setEquilibriumPoint(2, -0.3)

-- Wheel spin (axis2) stays free and is driven by a constant-velocity
-- motor, like a driven wheel rolling forward.
con:enableMotor(3, true)
con:setTargetVelocity(3, 6)
con:setMaxMotorForce(3, 200)

-- Steering (axis1) is angle-limited and driven by a servo motor toward a
-- target angle that sweeps back and forth, like a wheel steering left and
-- right while it drives.
con:setLowerLimit(-math.pi * 0.3)
con:setUpperLimit(math.pi * 0.3)
con:enableMotor(5, true)
con:setServo(5, true)
con:setTargetVelocity(5, 2)
con:setMaxMotorForce(5, 300)

v:addConstraint(con)

v:postSim(function(N)
  local steer = math.sin(N / 120 * math.pi * 2) * math.pi * 0.25
  con:setServoTarget(5, steer)
end)

v.cam:setUpVector(btVector3(0, 1, 0), true)
v.cam.pos  = btVector3(10, 7, 12)
v.cam.look = btVector3(2, 3, 0)

-- EOF
