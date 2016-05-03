-- CONTROL
angular_motor_speed=3
drive_type=3 -- 0=NONE, 1=FWD, 2=RWD, 3=AWD
car_previous_velocity=btVector3(angular_motor_speed,0,0)
tire_friction=.9
tire_restitution=.9

-- FLOOR
plane = Plane(0,1,0)
plane.col = "#111111"
plane.friction=0.9
plane.restitution=.1
v:add(plane)

-- CAR MESH
car_body=Mesh("demo/3ds/citroen_gs.3ds",1)
car_body.pos =btVector3(0,4,0)
--car_body=Cube(40,1,11,1)
--car_body.pos =btVector3(0,5,0)
car_body.col="#003399"
car_body.vel=car_previous_velocity
car_body.restitution=0
v:add(car_body)

-- FRONT AXE
front_axe_left_arm=Cylinder(.5,.5,6,1)
front_axe_left_arm.pos=btVector3(12,3,3.5)
front_axe_left_arm.friction=0.1
front_axe_left_arm.restitution=0
front_axe_left_arm.vel=car_previous_velocity
v:add(front_axe_left_arm)

front_axe_right_arm=Cylinder(.5,.5,6,1)
front_axe_right_arm.pos=btVector3(12,3,-3.5)
front_axe_right_arm.friction=0.1
front_axe_right_arm.restitution=0
front_axe_right_arm.vel=car_previous_velocity
v:add(front_axe_right_arm)

-- FRONT WHEELS
front_wheel_left = Cylinder(3,3,2,1)
front_wheel_left.pos = btVector3(12, 3, 7.5)
front_wheel_left.col = "#333333"
front_wheel_left.friction=tire_friction
front_wheel_left.restitution=tire_restitution
front_wheel_left.vel=car_previous_velocity
v:add(front_wheel_left)

front_wheel_right = Cylinder(3,3,2,1)
front_wheel_right.pos = btVector3(12, 3, -7.5)
front_wheel_right.col = "#333333"
front_wheel_right.friction=tire_friction
front_wheel_right.restitution=tire_restitution
front_wheel_right.vel=car_previous_velocity
v:add(front_wheel_right)

-- FRONT ARMS-BODY CONSTRAINT
front_arm_left_pivot = btVector3(-12,-3,-3.5)
front_arm_left_axis  = btVector3(0,0,1)

front_arm_right_pivot = btVector3(-12,-3,3.5)
front_arm_right_axis  = btVector3(0,0,1)

front_body_left_pivot = btVector3(12,-5,.5)
front_body_left_axis  = btVector3(0,0,1)

front_body_right_pivot = btVector3(12,-5,-.5)
front_body_right_axis  = btVector3(0,0,1)

front_arm_left_axe_constraint = btHingeConstraint(
  front_axe_left_arm:getRigidBody(),
  car_body:getRigidBody(),
  front_arm_left_pivot, front_body_left_pivot, front_arm_left_axis, front_body_left_axis)

front_arm_right_axe_constraint = btHingeConstraint(
  front_axe_right_arm:getRigidBody(),
  car_body:getRigidBody(),
  front_arm_right_pivot, front_body_right_pivot, front_arm_right_axis, front_body_right_axis)
  
front_arm_left_axe_constraint:setAxis(btVector3(1,0,0))
front_arm_right_axe_constraint:setAxis(btVector3(1,0,0))

v:addConstraint(front_arm_left_axe_constraint)
v:addConstraint(front_arm_right_axe_constraint)

-- FRONT WHEELS-AXE CONSTRAINTS
front_axe_left_pivot = btVector3(0,0,-3.5)
front_axe_left_axis  = btVector3(0,0,1)

front_axe_right_pivot = btVector3(0,0,3.5)
front_axe_right_axis  = btVector3(0,0,1)

front_wheel_left_pivot = btVector3(0,0,-7.5)
front_wheel_left_axis  = btVector3(0,0,1)

front_wheel_right_pivot = btVector3(0,0,7.5)
front_wheel_right_axis  = btVector3(0,0,1)

front_wheel_left_axe_constraint = btHingeConstraint(
  front_axe_left_arm:getRigidBody(),
  front_wheel_left:getRigidBody(),
  front_axe_left_pivot, front_wheel_left_pivot, front_axe_left_axis, front_wheel_left_axis)

front_wheel_right_axe_constraint = btHingeConstraint(
  front_axe_right_arm:getRigidBody(),
  front_wheel_right:getRigidBody(),
  front_axe_right_pivot, front_wheel_right_pivot, front_axe_right_axis, front_wheel_right_axis)

if (drive_type==1 or drive_type==3) then
  front_wheel_left_axe_constraint:enableAngularMotor(true, angular_motor_speed, 1)
  front_wheel_right_axe_constraint:enableAngularMotor(true, angular_motor_speed, 1)
end

v:addConstraint(front_wheel_left_axe_constraint)
v:addConstraint(front_wheel_right_axe_constraint)

-- FRONT LEFT AXE-BODY CONSTRAINT
q = btQuaternion(0,1,0,1)
o = btVector3(-12,-3,-.5)
front_axe_left_spring_axe_trans=btTransform(q,o)
o = btVector3(0,-5,3.5)
front_axe_left_spring_body_trans=btTransform(q,o)
front_axe_left_spring_constraint=btSliderConstraint(
  front_axe_left_arm:getRigidBody(),
  car_body:getRigidBody(),
  front_axe_left_spring_axe_trans,
  front_axe_left_spring_body_trans,
  false)
o = btVector3(-12,-3,.5)
front_axe_right_spring_axe_trans=btTransform(q,o)
o = btVector3(0,-5,-3.5)
front_axe_right_spring_body_trans=btTransform(q,o)
front_axe_right_spring_constraint=btSliderConstraint(
  front_axe_right_arm:getRigidBody(),
  car_body:getRigidBody(),
  front_axe_right_spring_axe_trans,
  front_axe_right_spring_body_trans,
  false)

front_axe_left_spring_constraint:setLowerLinLimit(0)
front_axe_left_spring_constraint:setUpperLinLimit(0)
v:addConstraint(front_axe_left_spring_constraint)

front_axe_right_spring_constraint:setLowerLinLimit(0)
front_axe_right_spring_constraint:setUpperLinLimit(0)
v:addConstraint(front_axe_right_spring_constraint)

-- REAR AXE
rear_axe_left_arm=Cylinder(.5,.5,6,1)
rear_axe_left_arm.pos=btVector3(-14,3,3.5)
rear_axe_left_arm.friction=0.1
rear_axe_left_arm.restitution=0
rear_axe_left_arm.vel=car_previous_velocity
v:add(rear_axe_left_arm)

rear_axe_right_arm=Cylinder(.5,.5,6,1)
rear_axe_right_arm.pos=btVector3(-14,3,-3.5)
rear_axe_right_arm.friction=0.1
rear_axe_right_arm.restitution=0
rear_axe_right_arm.vel=car_previous_velocity
v:add(rear_axe_right_arm)


-- REAR WHEELS
rear_wheel_left = Cylinder(3,3,2,1)
rear_wheel_left.pos = btVector3(-14, 3, 7.0)
rear_wheel_left.col = "#333333"
rear_wheel_left.friction=tire_friction
rear_wheel_left.restitution=tire_restitution
rear_wheel_left.vel=car_previous_velocity
v:add(rear_wheel_left)

rear_wheel_right = Cylinder(3,3,2,1)
rear_wheel_right.pos = btVector3(-14, 3, -7.0)
rear_wheel_right.col = "#333333"
rear_wheel_right.friction=tire_friction
rear_wheel_right.restitution=tire_restitution
rear_wheel_right.vel=car_previous_velocity
v:add(rear_wheel_right)

-- REAR ARMS-BODY CONSTRAINT
rear_arm_left_pivot = btVector3(-14,-3,-3.5)
rear_arm_left_axis  = btVector3(0,0,1)

rear_arm_right_pivot = btVector3(-14,-3,3.5)
rear_arm_right_axis  = btVector3(0,0,1)

rear_body_left_pivot = btVector3(14,-5,.5)
rear_body_left_axis  = btVector3(0,0,1)

rear_body_right_pivot = btVector3(14,-5,-.5)
rear_body_right_axis  = btVector3(0,0,1)

rear_arm_left_axe_constraint = btHingeConstraint(
  rear_axe_left_arm:getRigidBody(),
  car_body:getRigidBody(),
  rear_arm_left_pivot, rear_body_left_pivot, rear_arm_left_axis, rear_body_left_axis)

rear_arm_right_axe_constraint = btHingeConstraint(
  rear_axe_right_arm:getRigidBody(),
  car_body:getRigidBody(),
  rear_arm_right_pivot, rear_body_right_pivot, rear_arm_right_axis, rear_body_right_axis)
  
rear_arm_left_axe_constraint:setAxis(btVector3(1,0,0))
rear_arm_right_axe_constraint:setAxis(btVector3(1,0,0))

v:addConstraint(rear_arm_left_axe_constraint)
v:addConstraint(rear_arm_right_axe_constraint)

-- REAR WHEELS-AXE CONSTRAINTS
rear_axe_left_pivot = btVector3(0,0,-3.5)
rear_axe_left_axis  = btVector3(0,0,1)

rear_axe_right_pivot = btVector3(0,0,3.5)
rear_axe_right_axis  = btVector3(0,0,1)

rear_wheel_left_pivot = btVector3(0,0,-7.0)
rear_wheel_left_axis  = btVector3(0,0,1)

rear_wheel_right_pivot = btVector3(0,0,7.0)
rear_wheel_right_axis  = btVector3(0,0,1)

rear_wheel_left_axe_constraint = btHingeConstraint(
  rear_axe_left_arm:getRigidBody(),
  rear_wheel_left:getRigidBody(),
  rear_axe_left_pivot, rear_wheel_left_pivot, rear_axe_left_axis, rear_wheel_left_axis)

rear_wheel_right_axe_constraint = btHingeConstraint(
  rear_axe_right_arm:getRigidBody(),
  rear_wheel_right:getRigidBody(),
  rear_axe_right_pivot, rear_wheel_right_pivot, rear_axe_right_axis, rear_wheel_right_axis)

if (drive_type==2 or drive_type==3) then
 rear_wheel_left_axe_constraint:enableAngularMotor(true, angular_motor_speed, 1)
 rear_wheel_right_axe_constraint:enableAngularMotor(true, angular_motor_speed, 1)
end

v:addConstraint(rear_wheel_left_axe_constraint)
v:addConstraint(rear_wheel_right_axe_constraint)

-- REAR AXE-BODY CONSTRAINT
q = btQuaternion(0,1,0,1)
o = btVector3(14,-3,-.5)
rear_axe_left_spring_axe_trans=btTransform(q,o)
o = btVector3(0,-5,3.5)
rear_axe_left_spring_body_trans=btTransform(q,o)
rear_axe_left_spring_constraint=btSliderConstraint(
  rear_axe_left_arm:getRigidBody(), 
  car_body:getRigidBody(), 
  rear_axe_left_spring_axe_trans, 
  rear_axe_left_spring_body_trans, 
  false)
o = btVector3(14,-3,.5)
rear_axe_right_spring_axe_trans=btTransform(q,o)
o = btVector3(0,-5,-3.5)
rear_axe_right_spring_body_trans=btTransform(q,o)
rear_axe_right_spring_constraint=btSliderConstraint(
  rear_axe_right_arm:getRigidBody(), 
  car_body:getRigidBody(), 
  rear_axe_right_spring_axe_trans, 
  rear_axe_right_spring_body_trans, 
  false)

rear_axe_left_spring_constraint:setLowerLinLimit(0)
rear_axe_left_spring_constraint:setUpperLinLimit(0)
v:addConstraint(rear_axe_left_spring_constraint)
rear_axe_right_spring_constraint:setLowerLinLimit(0)
rear_axe_right_spring_constraint:setUpperLinLimit(0)
v:addConstraint(rear_axe_right_spring_constraint)

-- alternate obstacles
for i = 1,40 do
  obs1=Cube(1,1,10,0)
  if(i%2==0) then
    obs1.pos=btVector3(20+i*5,.5,7.5)
  else
    obs1.pos=btVector3(20+i*5,.5,-7.5)
  end
  obs1.col = "#FF9900"
  obs1.friction=.9
  v:add(obs1)
end

-- steps
--for i = 1,40 do
--  obs1=Cube(5,1,40,0)
--  if(i<=20) then
--  obs1.pos=btVector3(20+i*5,.5+i,0)
--  else
--  obs1.pos=btVector3(20+i*5,.5+40-i,0)
--  end
--  obs1.col = "#FF9900"
--  obs1.friction=.9
--  v:add(obs1)
--end

v:postSim(function(N)
  cam = Cam()
  cam.pos = btVector3(car_body.pos.x,car_body.pos.y,car_body.pos.z+50)
--  cam.pos = btVector3(car_body.pos.x+40,40,car_body.pos.z+50)
  cam.look = car_body.pos
  v:cam(cam)
end)

