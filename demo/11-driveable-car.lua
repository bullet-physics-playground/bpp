-- *********************
-- DRIVEABLE CAR EXAMPLE
-- *********************
--
-- NOTES:
-- + Please turn deactivation OFF or keyboad shortcuts will not work
-- + Scaled x10 (both measures and masses) for better stability
--
-- KEYBOARD SHORTCUTS:
-- + F1  = switch camera 
-- + F2  = accelerate
-- + F3  = neutral
-- + F4  = reverse
-- + F9  = turn left
-- + F10 = turn right

-- *******
-- CONTROL
-- *******

-- camera view
-- 0=default GL cam, 1=back, 2=onboard, 3=external 
-- (see other test cameras at the EOF)
camera_view=1

-- chassis specs: Nissan Micra (by Ren Bui)
chassis_height=8.25
front_axe_xpos=11.8
rear_axe_xpos=-12.7
front_axe_width=13.9
rear_axe_width=13.9
front_arm_lenght=3.75
rear_arm_lenght=3.75
arm_rad=.25
tire_rad=2.8
tire_width=1.8
disc_width=.25
spring_softness=.1
tire_mass=150
arm_mass=350
disc_mass=150
chassis_mass=8200-tire_mass*4-arm_mass*4-disc_mass*4-arm_mass

-- engine specs
angular_motor_speed=15
angular_motor_power=550
drive_type=0  -- 0=NONE, 1=FWD, 2=RWD, 3=AWD

-- generic tire params
tire_friction=.9
tire_restitution=.9

-- obstacle selection:  
-- 0=NONE, 1=ALTERNATE, 2=STEPS, 3=RAMP, 4=MESH TERRAIN 5=URBAN-LIKE
use_obstacles=0

-- reference ground marks
use_markings=1


-- ****************
-- CAR CHASSIS MESH
-- ****************

chassis=Mesh3DS("demo/micraK11_Rene_Bui.3ds",chassis_mass)
chassis.pos =btVector3(0,chassis_height,0)
chassis.col="#003399"
chassis.restitution=.01
chassis.friction=.1
v:add(chassis)


-- **********
-- FRONT ARMS
-- **********

-- left
front_left_arm=Cylinder(arm_rad,arm_rad,front_arm_lenght,arm_mass)
front_left_arm.pos=btVector3(front_axe_xpos,tire_rad,front_axe_width*.5-tire_width*.5-disc_width-front_arm_lenght*.5)
v:add(front_left_arm)

-- right
front_right_arm=Cylinder(arm_rad,arm_rad,front_arm_lenght,arm_mass)
front_right_arm.pos=btVector3(front_axe_xpos,tire_rad,-front_axe_width*.5+tire_width*.5+disc_width+front_arm_lenght*.5)
v:add(front_right_arm)


-- ***********
-- FRONT DISCS
-- ***********

-- left
front_left_disc=Cylinder(tire_rad*.5,tire_rad*.5,disc_width,disc_mass)
front_left_disc.pos=btVector3(front_axe_xpos,tire_rad,front_axe_width*.5-tire_width*.5-disc_width*.5)
v:add(front_left_disc)

-- right
front_right_disc=Cylinder(tire_rad*.5,tire_rad*.5,disc_width,disc_mass)
front_right_disc.pos=btVector3(front_axe_xpos,tire_rad,-(front_axe_width*.5-tire_width*.5-disc_width*.5))
v:add(front_right_disc)


-- ************
-- FRONT WHEELS
-- ************

-- left
front_left_wheel = Cylinder(tire_rad,tire_rad,tire_width,tire_mass)
front_left_wheel.pos = btVector3(front_axe_xpos, tire_rad, front_axe_width*.5)
front_left_wheel.col = "#333333"
front_left_wheel.friction=tire_friction
front_left_wheel.restitution=tire_restitution
v:add(front_left_wheel)

-- right
front_right_wheel = Cylinder(tire_rad,tire_rad,tire_width,tire_mass)
front_right_wheel.pos = btVector3(front_axe_xpos, tire_rad, -front_axe_width*.5)
front_right_wheel.col = "#333333"
front_right_wheel.friction=tire_friction
front_right_wheel.restitution=tire_restitution
v:add(front_right_wheel)


-- ******************
-- FRONT STEERING BAR
-- ******************

front_steering_bar=Cylinder(arm_rad*.5,arm_rad*.5,front_axe_width-tire_width-disc_width*2,arm_mass*.5)
front_steering_bar.pos=btVector3(front_axe_xpos+tire_rad*.4,tire_rad,0)
v:add(front_steering_bar)


-- ************************************
-- FRONT STEERING BAR-DISCS CONSTRAINTS
-- ************************************

-- left
front_left_disc_pivot = btVector3(tire_rad*.4,0,-disc_width*.5)
left_steering_bar_pivot = btVector3(0,0,front_axe_width*.5-tire_width*.5-disc_width)
left_steering_bar_constraint = btPoint2PointConstraint(
  front_left_disc:getRigidBody(),
  front_steering_bar:getRigidBody(),
  front_left_disc_pivot,
  left_steering_bar_pivot
)
v:addConstraint(left_steering_bar_constraint)

-- right
front_right_disc_pivot = btVector3(tire_rad*.4,0,disc_width*.5)
right_steering_bar_pivot = btVector3(0,0,-front_axe_width*.5+tire_width*.5+disc_width)
right_steering_bar_constraint = btPoint2PointConstraint(
  front_right_disc:getRigidBody(),
  front_steering_bar:getRigidBody(),
  front_right_disc_pivot,
  right_steering_bar_pivot
)
v:addConstraint(right_steering_bar_constraint)


-- ******************************************
-- FRONT WHEEL-DISC CONSTRAINTS, ENGINE HINGE
-- *******************************************

-- left
front_left_disc_pivot = btVector3(0,0,disc_width*.5)
front_left_disc_axis  = btVector3(0,0,1)
front_left_wheel_pivot = btVector3(0,0,-tire_width*.5)
front_left_wheel_axis  = btVector3(0,0,1)
front_left_wheel_disc_constraint = btHingeConstraint(
  front_left_disc:getRigidBody(),
  front_left_wheel:getRigidBody(),
  front_left_disc_pivot, front_left_wheel_pivot, front_left_disc_axis, front_left_wheel_axis
)
if (drive_type==1 or drive_type==3) then
  front_left_wheel_disc_constraint:enableAngularMotor(true, angular_motor_speed, angular_motor_power)
end
v:addConstraint(front_left_wheel_disc_constraint)

-- right
front_right_disc_pivot = btVector3(0,0,-disc_width*.5)
front_right_disc_axis  = btVector3(0,0,1)
front_right_wheel_pivot = btVector3(0,0,tire_width*.5)
front_right_wheel_axis  = btVector3(0,0,1)
front_right_wheel_disc_constraint = btHingeConstraint(
  front_right_disc:getRigidBody(),
  front_right_wheel:getRigidBody(),
  front_right_disc_pivot, front_right_wheel_pivot, front_right_disc_axis, front_right_wheel_axis
)
if (drive_type==1 or drive_type==3) then
  front_right_wheel_disc_constraint:enableAngularMotor(true, angular_motor_speed, angular_motor_power)
end
v:addConstraint(front_right_wheel_disc_constraint)


-- **************************************
-- FRONT DISC-ARM CONSTRAINT, STEER HINGE
-- **************************************

-- left
front_left_arm_pivot = btVector3(0,0,front_arm_lenght*.5)
front_left_arm_axis  = btVector3(0,0,1)
front_left_disc_pivot = btVector3(0,0,-disc_width*.5)
front_left_disc_axis  = btVector3(0,0,1)
front_left_disc_arm_constraint = btHingeConstraint(
  front_left_arm:getRigidBody(),
  front_left_disc:getRigidBody(),
  front_left_arm_pivot, front_left_disc_pivot, front_left_arm_axis, front_left_disc_axis)
front_left_disc_arm_constraint:setAxis(btVector3(0,1,0))
--front_left_disc_arm_constraint:setLimit(0,0,.1,.3,1)
v:addConstraint(front_left_disc_arm_constraint)

-- right
front_right_arm_pivot = btVector3(0,0,-front_arm_lenght*.5)
front_right_arm_axis  = btVector3(0,0,1)
front_right_disc_pivot = btVector3(0,0,disc_width*.5)
front_right_disc_axis  = btVector3(0,0,1)
front_right_disc_arm_constraint = btHingeConstraint(
  front_right_arm:getRigidBody(),
  front_right_disc:getRigidBody(),
  front_right_arm_pivot, front_right_disc_pivot, front_right_arm_axis, front_right_disc_axis)
front_right_disc_arm_constraint:setAxis(btVector3(0,1,0))
--front_right_disc_arm_constraint:setLimit(0,0,.1,.3,1)
v:addConstraint(front_right_disc_arm_constraint)


-- *******************************************
-- FRONT ARM-BODY CONSTRAINT, SUSPENSION HINGE
-- *******************************************

-- left
front_left_arm_pivot = btVector3(0,0,-front_arm_lenght*.5)
front_left_arm_axis  = btVector3(0,0,1)
front_left_body_pivot = btVector3(0,tire_rad-chassis_height,front_axe_width*.5-tire_width*.5-disc_width-front_arm_lenght)
front_left_body_axis  = btVector3(0,0,1)
front_left_arm_body_constraint = btHingeConstraint(
  front_left_arm:getRigidBody(),
  chassis:getRigidBody(),
  front_left_arm_pivot, front_left_body_pivot, front_left_arm_axis, front_left_body_axis)
front_left_arm_body_constraint:setAxis(btVector3(1,0,0))
--front_left_arm_body_constraint:setLimit(0,0,.1,.3,1)
v:addConstraint(front_left_arm_body_constraint)

-- right
front_right_arm_pivot = btVector3(0,0,front_arm_lenght*.5)
front_right_arm_axis  = btVector3(0,0,1)
front_right_body_pivot = btVector3(0,tire_rad-chassis_height,-(front_axe_width*.5-tire_width*.5-disc_width-front_arm_lenght))
front_right_body_axis  = btVector3(0,0,1)
front_right_arm_body_constraint = btHingeConstraint(
  front_right_arm:getRigidBody(),
  chassis:getRigidBody(),
  front_right_arm_pivot, front_right_body_pivot, front_right_arm_axis, front_right_body_axis) 
front_right_arm_body_constraint:setAxis(btVector3(-1,0,0))
--front_right_arm_body_constraint:setLimit(0,0,.1,.3,1)
v:addConstraint(front_right_arm_body_constraint)


-- ********************************************
-- FRONT ARM-BODY CONSTRAINT, SUSPENSION SPRING
-- ********************************************

q = btQuaternion()
q:setRotation(btVector3(0,0,1),math.pi*.5)

-- left
o = btVector3(0,0,front_arm_lenght*.5-disc_width)
front_left_arm_trans=btTransform(q,o)
o = btVector3(front_axe_xpos,-1,front_axe_width*.5-tire_width*.5-disc_width*2)
front_left_body_trans=btTransform(q,o)
front_left_body_arm_constraint=btSliderConstraint(
  front_left_arm:getRigidBody(),
  chassis:getRigidBody(),
  front_left_arm_trans,
  front_left_body_trans,
  false
)
front_left_body_arm_constraint:setSoftnessOrthoLin(spring_softness)
front_left_body_arm_constraint:setSoftnessLimLin(spring_softness)
v:addConstraint(front_left_body_arm_constraint)

-- right
o = btVector3(0,0,-front_arm_lenght*.5+disc_width)
front_right_arm_trans=btTransform(q,o)
o = btVector3(front_axe_xpos,-1,-(front_axe_width*.5-tire_width*.5-disc_width*2))
front_right_body_trans=btTransform(q,o)
front_right_body_arm_constraint=btSliderConstraint(
  front_right_arm:getRigidBody(),
  chassis:getRigidBody(),
  front_right_arm_trans,
  front_right_body_trans,
  false
)
front_right_body_arm_constraint:setSoftnessOrthoLin(spring_softness)
front_right_body_arm_constraint:setSoftnessLimLin(spring_softness)
v:addConstraint(front_right_body_arm_constraint)


-- *********
-- REAR ARMS
-- *********

-- left
rear_left_arm=Cylinder(arm_rad,arm_rad,front_arm_lenght,arm_mass)
rear_left_arm.pos=btVector3(rear_axe_xpos,tire_rad,rear_axe_width*.5-tire_width*.5-disc_width-front_arm_lenght*.5)
v:add(rear_left_arm)

-- right
rear_right_arm=Cylinder(arm_rad,arm_rad,rear_arm_lenght,arm_mass)
rear_right_arm.pos=btVector3(rear_axe_xpos,tire_rad,-rear_axe_width*.5+tire_width*.5+disc_width+rear_arm_lenght*.5)
v:add(rear_right_arm)


-- **********
-- REAR DISCS
-- **********

-- left
rear_left_disc=Cylinder(tire_rad*.5,tire_rad*.5,disc_width,disc_mass)
rear_left_disc.pos=btVector3(rear_axe_xpos,tire_rad,rear_axe_width*.5-tire_width*.5-disc_width*.5)
v:add(rear_left_disc)

-- right
rear_right_disc=Cylinder(tire_rad*.5,tire_rad*.5,disc_width,disc_mass)
rear_right_disc.pos=btVector3(rear_axe_xpos,tire_rad,-(rear_axe_width*.5-tire_width*.5-disc_width*.5))
v:add(rear_right_disc)


-- ***********
-- REAR WHEELS
-- ***********

-- left
rear_left_wheel = Cylinder(tire_rad,tire_rad,tire_width,tire_mass)
rear_left_wheel.pos = btVector3(rear_axe_xpos, tire_rad, rear_axe_width*.5)
rear_left_wheel.col = "#333333"
rear_left_wheel.friction=tire_friction
rear_left_wheel.restitution=tire_restitution
v:add(rear_left_wheel)

-- right
rear_right_wheel = Cylinder(tire_rad,tire_rad,tire_width,tire_mass)
rear_right_wheel.pos = btVector3(rear_axe_xpos, tire_rad, -rear_axe_width*.5)
rear_right_wheel.col = "#333333"
rear_right_wheel.friction=tire_friction
rear_right_wheel.restitution=tire_restitution
v:add(rear_right_wheel)


-- *******************
-- REAR STABILIZER BAR
-- *******************

rear_stabilizer_bar=Cylinder(arm_rad*.5,arm_rad*.5,rear_axe_width-tire_width-disc_width*2,arm_mass*.5)
rear_stabilizer_bar.pos=btVector3(rear_axe_xpos+tire_rad*.4,tire_rad,0)
v:add(rear_stabilizer_bar)


-- *************************************
-- REAR STABILIZER BAR-DISCS CONSTRAINTS
-- *************************************

-- left
rear_left_disc_pivot = btVector3(tire_rad*.4,0,-disc_width*.5)
rear_left_steering_bar_pivot = btVector3(0,0,rear_axe_width*.5-tire_width*.5-disc_width)
rear_left_steering_bar_constraint = btPoint2PointConstraint(
  rear_left_disc:getRigidBody(),
  rear_stabilizer_bar:getRigidBody(),
  rear_left_disc_pivot,
  rear_left_steering_bar_pivot
)
v:addConstraint(rear_left_steering_bar_constraint)

-- right
rear_right_disc_pivot = btVector3(tire_rad*.4,0,disc_width*.5)
rear_right_steering_bar_pivot = btVector3(0,0,-rear_axe_width*.5+tire_width*.5+disc_width)
rear_right_steering_bar_constraint = btPoint2PointConstraint(
  rear_right_disc:getRigidBody(),
  rear_stabilizer_bar:getRigidBody(),
  rear_right_disc_pivot,
  rear_right_steering_bar_pivot
)
v:addConstraint(rear_right_steering_bar_constraint)

-- center
rear_center_body_pivot = btVector3(rear_axe_xpos+tire_rad*.4,-chassis_height+tire_rad,0)
rear_center_steering_bar_pivot = btVector3(0,0,0)
rear_center_steering_bar_constraint = btPoint2PointConstraint(
  chassis:getRigidBody(),
  rear_stabilizer_bar:getRigidBody(),
  rear_center_body_pivot,
  rear_center_steering_bar_pivot
)
v:addConstraint(rear_center_steering_bar_constraint)


-- *****************************************
-- REAR WHEEL-DISC CONSTRAINTS, ENGINE HINGE
-- *****************************************

-- left
rear_left_disc_pivot = btVector3(0,0,disc_width*.5)
rear_left_disc_axis  = btVector3(0,0,1)
rear_left_wheel_pivot = btVector3(0,0,-tire_width*.5)
rear_left_wheel_axis  = btVector3(0,0,1)
rear_left_wheel_disc_constraint = btHingeConstraint(
  rear_left_disc:getRigidBody(),
  rear_left_wheel:getRigidBody(),
  rear_left_disc_pivot, rear_left_wheel_pivot, rear_left_disc_axis, rear_left_wheel_axis
)
if (drive_type==2 or drive_type==3) then
  rear_left_wheel_disc_constraint:enableAngularMotor(true, angular_motor_speed, angular_motor_power)
end
v:addConstraint(rear_left_wheel_disc_constraint)

-- right
rear_right_disc_pivot = btVector3(0,0,-disc_width*.5)
rear_right_disc_axis  = btVector3(0,0,1)
rear_right_wheel_pivot = btVector3(0,0,tire_width*.5)
rear_right_wheel_axis  = btVector3(0,0,1)
rear_right_wheel_disc_constraint = btHingeConstraint(
  rear_right_disc:getRigidBody(),
  rear_right_wheel:getRigidBody(),
  rear_right_disc_pivot, rear_right_wheel_pivot, rear_right_disc_axis, rear_right_wheel_axis
)
if (drive_type==2 or drive_type==3) then
  rear_right_wheel_disc_constraint:enableAngularMotor(true, angular_motor_speed, angular_motor_power)
end
v:addConstraint(rear_right_wheel_disc_constraint)


-- **************************************
-- REAR DISC-ARM CONSTRAINT, STEER HINGE
-- **************************************

-- left
rear_left_arm_pivot = btVector3(0,0,rear_arm_lenght*.5)
rear_left_arm_axis  = btVector3(0,0,1)
rear_left_disc_pivot = btVector3(0,0,-disc_width*.5)
rear_left_disc_axis  = btVector3(0,0,1)
rear_left_disc_arm_constraint = btHingeConstraint(
  rear_left_arm:getRigidBody(),
  rear_left_disc:getRigidBody(),
  rear_left_arm_pivot, rear_left_disc_pivot, rear_left_arm_axis, rear_left_disc_axis)
rear_left_disc_arm_constraint:setAxis(btVector3(0,1,0))
rear_left_disc_arm_constraint:setLimit(0,0,.1,.3,1)
v:addConstraint(rear_left_disc_arm_constraint)

-- right
rear_right_arm_pivot = btVector3(0,0,-rear_arm_lenght*.5)
rear_right_arm_axis  = btVector3(0,0,1)
rear_right_disc_pivot = btVector3(0,0,disc_width*.5)
rear_right_disc_axis  = btVector3(0,0,1)
rear_right_disc_arm_constraint = btHingeConstraint(
  rear_right_arm:getRigidBody(),
  rear_right_disc:getRigidBody(),
  rear_right_arm_pivot, rear_right_disc_pivot, rear_right_arm_axis, rear_right_disc_axis)
rear_right_disc_arm_constraint:setAxis(btVector3(0,1,0))
rear_right_disc_arm_constraint:setLimit(0,0,.1,.3,1)
v:addConstraint(rear_right_disc_arm_constraint)


-- *******************************************
-- REAR ARM-BODY CONSTRAINT, SUSPENSION HINGE
-- *******************************************

-- left
rear_left_arm_pivot = btVector3(0,0,-rear_arm_lenght*.5)
rear_left_arm_axis  = btVector3(0,0,1)
rear_left_body_pivot = btVector3(0,tire_rad-chassis_height,rear_axe_width*.5-tire_width*.5-disc_width-rear_arm_lenght)
rear_left_body_axis  = btVector3(0,0,1)
rear_left_arm_body_constraint = btHingeConstraint(
  rear_left_arm:getRigidBody(),
  chassis:getRigidBody(),
  rear_left_arm_pivot, rear_left_body_pivot, rear_left_arm_axis, rear_left_body_axis)
rear_left_arm_body_constraint:setAxis(btVector3(1,0,0))
--rear_left_arm_body_constraint:setLimit(0,0,.1,.3,1)
v:addConstraint(rear_left_arm_body_constraint)

-- right
rear_right_arm_pivot = btVector3(0,0,rear_arm_lenght*.5)
rear_right_arm_axis  = btVector3(0,0,1)
rear_right_body_pivot = btVector3(0,tire_rad-chassis_height,-(rear_axe_width*.5-tire_width*.5-disc_width-rear_arm_lenght))
rear_right_body_axis  = btVector3(0,0,1)
rear_right_arm_body_constraint = btHingeConstraint(
  rear_right_arm:getRigidBody(),
  chassis:getRigidBody(),
  rear_right_arm_pivot, rear_right_body_pivot, rear_right_arm_axis, rear_right_body_axis) 
rear_right_arm_body_constraint:setAxis(btVector3(-1,0,0))
--rear_right_arm_body_constraint:setLimit(0,0,.1,.3,1)
v:addConstraint(rear_right_arm_body_constraint)


-- ********************************************
-- REAR ARM-BODY CONSTRAINT, SUSPENSION SPRING
-- ********************************************

q = btQuaternion()
q:setRotation(btVector3(0,0,1),math.pi*.5)

-- left
o = btVector3(0,0,rear_arm_lenght*.5-disc_width)
rear_left_arm_trans=btTransform(q,o)
o = btVector3(rear_axe_xpos,-1,rear_axe_width*.5-tire_width*.5-disc_width*2)
rear_left_body_trans=btTransform(q,o)
rear_left_body_arm_constraint=btSliderConstraint(
  rear_left_arm:getRigidBody(),
  chassis:getRigidBody(),
  rear_left_arm_trans,
  rear_left_body_trans,
  false
)
rear_left_body_arm_constraint:setSoftnessOrthoLin(spring_softness)
rear_left_body_arm_constraint:setSoftnessLimLin(spring_softness)
v:addConstraint(rear_left_body_arm_constraint)

-- right
o = btVector3(0,0,-rear_arm_lenght*.5+disc_width)
rear_right_arm_trans=btTransform(q,o)
o = btVector3(rear_axe_xpos,-1,-(rear_axe_width*.5-tire_width*.5-disc_width*2))
rear_right_body_trans=btTransform(q,o)
rear_right_body_arm_constraint=btSliderConstraint(
  rear_right_arm:getRigidBody(),
  chassis:getRigidBody(),
  rear_right_arm_trans,
  rear_right_body_trans,
  false
)
rear_right_body_arm_constraint:setSoftnessOrthoLin(spring_softness)
rear_right_body_arm_constraint:setSoftnessLimLin(spring_softness)
v:addConstraint(rear_right_body_arm_constraint)


-- ************
-- TEST SCENERY
-- ************

-- default floor plane
if(use_obstacles~=4) then
  plane = Plane(0,1,0)
  plane.col = "#111111"
  plane.friction=0.9
  plane.restitution=.1
  v:add(plane)
end

-- ground markings for reference of deviation
if(use_markings==1) then
  if(use_obstacles<4) then
    for j = 1,5 do
      for i = 1,20 do
        marks=Cube(5,.01,1,0)
        marks.pos=btVector3(-200+i*20,.005,-3*40+40*j)
        marks.col = "#FF9900"
        marks.friction=.9
        v:add(marks)
      end
    end
  end
end

-- suspension test: alternate obstacles
if(use_obstacles==1) then
  for i = 1,40 do
    obs1=Cube(1,1,15,0)
    if(i%2==0) then
      obs1.pos=btVector3(20+i*5,.5,7.5)
    else
      obs1.pos=btVector3(20+i*5,.5,-7.5)
    end
    obs1.col = "#FF9900"
    obs1.friction=.9
    v:add(obs1)
  end
end

-- suspension test: steps
if(use_obstacles==2) then
  for i = 1,40 do
    obs1=Cube(10,1,30,0)
    if(i<=20) then
      obs1.pos=btVector3(20+i*10,.5+i,0)
    else
      obs1.pos=btVector3(20+i*10,.5+40-i,0)
    end
    obs1.col = "#FF9900"
    obs1.friction=.9
    v:add(obs1)
  end
end

-- suspension test: ramp
if(use_obstacles==3) then
  ramp=Cube(30,.1,30,0)
  q = btQuaternion(0,0,.1,1)
  o = btVector3(150,3,0)
  ramp.trans=btTransform(q,o)
  v:add(ramp)
end

-- suspension test: mesh terrain test
if(use_obstacles==4) then
  terrain=Mesh3DS("demo/terrain.3ds",0)
  terrain.pos =btVector3(430,4,0)
  terrain.col="#993399"
  terrain.friction=.9
  terrain.restitution=0
  v:add(terrain)
end

-- urban-like
if(use_obstacles==5) then
  for i = 1,100 do
    obs1=Cube(50,50,50,0)
    obs1.pos=btVector3(math.random(-5,5)*100,25,math.random(-5,5)*100)
    obs1.col = "#FF9900"
    obs1.friction=.9
    if(math.abs(obs1.pos.x)>50 and math.abs(obs1.pos.x)>50) then
    v:add(obs1)
    end
  end
end

-- ******************
-- KEYBOARD SHORTCUTS
-- ******************

-- switch camera
v:addShortcut("F1", function(N)
  camera_view = camera_view + 1;
  if (camera_view == 4) then
    camera_view = 1
  end
end)

-- steer left
v:addShortcut("F9", function(N)
  front_left_disc_arm_constraint:enableAngularMotor(true, 100, -500)
  front_right_disc_arm_constraint:enableAngularMotor(true, 100, -500)
end)

-- steer right
v:addShortcut("F10", function(N)
  front_right_disc_arm_constraint:enableAngularMotor(true, 100, 500)
  front_left_disc_arm_constraint:enableAngularMotor(true, 100, 500)
end)

-- accelerate forward
v:addShortcut("F2", function(N)
  front_left_wheel_disc_constraint:enableAngularMotor(true, angular_motor_speed, angular_motor_power)
  front_right_wheel_disc_constraint:enableAngularMotor(true, angular_motor_speed, angular_motor_power)
  rear_left_wheel_disc_constraint:enableAngularMotor(true, angular_motor_speed, angular_motor_power)
  rear_right_wheel_disc_constraint:enableAngularMotor(true, angular_motor_speed, angular_motor_power)
end)

-- neutral
v:addShortcut("F3", function(N)
  front_left_wheel_disc_constraint:enableAngularMotor(false, 0, 0)
  front_right_wheel_disc_constraint:enableAngularMotor(false, 0,0)
  rear_left_wheel_disc_constraint:enableAngularMotor(false, 0,0)
  rear_right_wheel_disc_constraint:enableAngularMotor(false, 0,0)
end)

-- accelerate backward
v:addShortcut("F4", function(N)
  front_left_wheel_disc_constraint:enableAngularMotor(true, angular_motor_speed, -angular_motor_power)
  front_right_wheel_disc_constraint:enableAngularMotor(true, angular_motor_speed, -angular_motor_power)
  rear_left_wheel_disc_constraint:enableAngularMotor(true, angular_motor_speed, -angular_motor_power)
  rear_right_wheel_disc_constraint:enableAngularMotor(true, angular_motor_speed, -angular_motor_power)
end)


-- *************************
-- on-the-fly camera control
-- *************************
v:postSim(function(N)

if(camera_view>0) then

  cam = Cam()
  
  -- from the back, moves with the car
  if(camera_view==1) then
    cam.pos = rear_stabilizer_bar.pos+btVector3(rear_stabilizer_bar.pos.x-front_steering_bar.pos.x,chassis_height,rear_stabilizer_bar.pos.z-front_steering_bar.pos.z)*2
    cam.look = front_steering_bar.pos
  end
  -- onboard
  if(camera_view==2) then
    cam.pos = btVector3(chassis.pos.x,chassis.pos.y+4,chassis.pos.z)
    cam.look = btVector3(front_steering_bar.pos.x,chassis.pos.y+4,front_steering_bar.pos.z)
  end
  -- static mount looking at the car
  if(camera_view==3) then
    cam.pos = btVector3(50,140,60)
    cam.look = chassis.pos
    cam:setHorizontalFieldOfView(1)
  end
  -- close look at the front suspension and wheels
  if(camera_view==4) then
    cam.pos = btVector3(chassis.pos.x+79,chassis.pos.y-7,chassis.pos.z)
    cam.look = btVector3(chassis.pos.x,chassis.pos.y,chassis.pos.z)
    cam:setHorizontalFieldOfView(.5)
  end
  -- close look at the rear suspension and wheels
  if(camera_view==5) then
    cam.pos = btVector3(chassis.pos.x-45,chassis.pos.y-3,chassis.pos.z)
    cam.look = btVector3(chassis.pos.x+10-30,chassis.pos.y-3,chassis.pos.z)
  end
  -- from below
  if(camera_view==6) then
    cam.pos = btVector3(chassis.pos.x,chassis.pos.y-400,chassis.pos.z)
    cam.look = btVector3(chassis.pos.x,chassis.pos.y,chassis.pos.z)
    cam:setHorizontalFieldOfView(.1)
  end
  -- pseudo orthographic from the side 
  if(camera_view==7) then
    cam.pos = btVector3(chassis.pos.x,10,chassis.pos.z+2000)
    cam.look = btVector3(chassis.pos.x,10,chassis.pos.z)
    cam:setHorizontalFieldOfView(.025)
  end
  
  v:cam(cam)

end
  
end) -- postSim

-- EOF