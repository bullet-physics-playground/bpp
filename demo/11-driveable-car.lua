-- *********************
-- DRIVEABLE CAR EXAMPLE
-- *********************

-- v.gravity = btVector3(0,-9.81,0)

--
-- NOTES:
-- + Please turn deactivation OFF or keyboad shortcuts will not work
-- + Dimensions scaled x10 for better stability
--
-- KEYBOARD SHORTCUTS:
-- + F1  = switch camera 
-- + F2  = accelerate
-- + F3  = brake
-- + F4  = reverse
-- + F5  = neutral
-- + F9  = turn left
-- + F10 = turn right

-- v.gravity = btVector3(0,-9.81*3,0) -- XXX fix gravity in viewer.cpp

--
-- WARNING:
-- + The script doesn't run correctly most of the times. Sometimes some 
-- contraints will break, others the program will hang or even crash, but
-- if you get a clean run, it will work correctly until restarted (when
-- you see the four suspensions bouncing equally at the start, it means 
-- that it worked).

-- *******
-- CONTROL
-- *******

-- camera view:
-- 0=default GL cam, 1=back follow, 2=onboard, 3=external 
-- (see other test cameras at the EOF)
camera_view=3

-- car model: 
-- 1=Citroen GS, 2=Nissan Micra
car_model=2

if (car_model==1) then
-- Citroen GS
chassis_model="citroen_gs.3ds"
chassis_height=4.4
front_axle_xpos=12.45
rear_axle_xpos=-13.6
front_axle_width=15.5
rear_axle_width=15
front_arm_lenght=2.1
rear_arm_lenght=1.9
arm_radius=.2
arm_body_height=-1.4
suspension_lower_limit=-1
suspension_upper_limit=.1
tire_radius=3
tire_width=1.6
total_car_mass=1000
drivetrain_type=3  -- 0=NONE, 1=FWD, 2=RWD, 3=AWD
engine_placement=0.3  -- 1=FRONT, 0=CENTER, -1=REAR
engine_height=tire_radius+1
onboard_cam_height=7
chassis_sdl="object{car"
right_tire_sdl="object{gs_tyre"
left_tire_sdl="object{gs_tyre rotate 180*y"
end
if (car_model==2) then
-- Nissan Micra (by Ren Bui)
chassis_model="micraK11_Rene_Bui.3ds"
chassis_height=7.5
front_axle_xpos=11.8
rear_axle_xpos=-12.7
front_axle_width=14.2
rear_axle_width=14.2
front_arm_lenght=1.75
rear_arm_lenght=1.75
arm_radius=.2
arm_body_height=-5
suspension_lower_limit=-.8
suspension_upper_limit=.8
tire_radius=3
tire_width=1.8
total_car_mass=800
drivetrain_type=1  -- 0=NONE, 1=FWD, 2=RWD, 3=AWD
engine_placement=.5  -- 1=FRONT, 0=CENTER, -1=REAR
engine_height=tire_radius+1
onboard_cam_height=3.5
end

-- engine control
initial_angular_velocity=-35

-- obstacle selection:  
-- 0=NONE, 1=MISC, 2=MESH TERRAIN 
use_obstacles=1

-- ******************
-- INTERNAL VARIABLES
-- ******************

-- calculate components individual mass
-- the logic is : give half the mass to the chassis/engine combo
-- and the other half distrtibuted equally among the wheels components 
tire_mass=(total_car_mass*.5)/24
arm_mass=(total_car_mass*.5)/24
disc_mass=(total_car_mass*.5)/24
mount_mass=(total_car_mass*.5)/24
engine_mass=total_car_mass*.2
chassis_mass=total_car_mass*.3

-- calculate steering power needed
max_angular_steer_power=total_car_mass/2

-- materials params
tire_friction=1
tire_restitution=.01
metal_friction=.5
metal_restitution=.01

-- ************
-- CAR GEOMETRY
-- ************

-- CAR CHASSIS MESH
chassis=Mesh("demo/3ds/"..chassis_model,chassis_mass)
chassis.pos =btVector3(0,chassis_height,0)
chassis.col="#CCCCCC"
chassis.restitution=.01
chassis.friction=.1
if(chassis_sdl~=nil) then
chassis.pre_sdl=chassis_sdl
end
v:add(chassis)

-- ENGINE
engine=Cube(1,1,1,engine_mass)
engine_xpos=0
if(engine_placement>0) then
  engine_xpos=front_axle_xpos*engine_placement
end
if(engine_placement<0) then
  engine_xpos=rear_axle_xpos*math.abs(engine_placement)
end
engine.pos=btVector3(engine_xpos,engine_height,0)
v:add(engine)

-- FRONT WHEELS
-- right
front_right_wheel = Cylinder(tire_radius,tire_width*.9,tire_mass)
front_right_wheel.pos = btVector3(front_axle_xpos, tire_radius, front_axle_width*.5)
front_right_wheel.col = "#333333"
front_right_wheel.friction=tire_friction
front_right_wheel.restitution=tire_restitution
if(right_tire_sdl~=nil) then
front_right_wheel.pre_sdl=right_tire_sdl
end
v:add(front_right_wheel)
-- left
front_left_wheel = Cylinder(tire_radius,tire_width*.9,tire_mass)
front_left_wheel.pos = btVector3(front_axle_xpos, tire_radius, -front_axle_width*.5)
front_left_wheel.col = "#333333"
front_left_wheel.friction=tire_friction
front_left_wheel.restitution=tire_restitution
if(left_tire_sdl~=nil) then
front_left_wheel.pre_sdl=left_tire_sdl
end
v:add(front_left_wheel)

-- REAR WHEELS
-- right
rear_right_wheel = Cylinder(tire_radius,tire_width*.9,tire_mass)
rear_right_wheel.pos = btVector3(rear_axle_xpos, tire_radius, rear_axle_width*.5)
rear_right_wheel.col = "#333333"
rear_right_wheel.friction=tire_friction
rear_right_wheel.restitution=tire_restitution
if(right_tire_sdl~=nil) then
rear_right_wheel.pre_sdl=right_tire_sdl
end
v:add(rear_right_wheel)
-- left
rear_left_wheel = Cylinder(tire_radius,tire_width*.9,tire_mass)
rear_left_wheel.pos = btVector3(rear_axle_xpos, tire_radius, -rear_axle_width*.5)
rear_left_wheel.col = "#333333"
rear_left_wheel.friction=tire_friction
rear_left_wheel.restitution=tire_restitution
if(left_tire_sdl~=nil) then
rear_left_wheel.pre_sdl=left_tire_sdl
end
v:add(rear_left_wheel)

-- FRONT DISCS
-- right
front_right_disc=Cylinder(tire_radius*.75,tire_width,disc_mass)
front_right_disc.pos=btVector3(front_axle_xpos,tire_radius,front_axle_width*.5)
front_right_disc.col="#ff0000"
front_right_disc.friction=metal_friction
front_right_disc.restitution=metal_restitution
front_right_disc.pre_sdl="object{disk"
v:add(front_right_disc)
-- left
front_left_disc=Cylinder(tire_radius*.75,tire_width,disc_mass)
front_left_disc.pos=btVector3(front_axle_xpos,tire_radius,-front_axle_width*.5)
front_left_disc.col="#ff0000"
front_left_disc.friction=metal_friction
front_left_disc.restitution=metal_restitution
front_left_disc.pre_sdl="object{disk"
v:add(front_left_disc)

-- REAR DISCS
-- right
rear_right_disc=Cylinder(tire_radius*.75,tire_width,disc_mass)
rear_right_disc.pos=btVector3(rear_axle_xpos,tire_radius,rear_axle_width*.5)
rear_right_disc.col="#ff0000"
rear_right_disc.friction=metal_friction
rear_right_disc.restitution=metal_restitution
rear_right_disc.pre_sdl="object{disk"
v:add(rear_right_disc)
-- left
rear_left_disc=Cylinder(tire_radius*.75,tire_width,disc_mass)
rear_left_disc.pos=btVector3(rear_axle_xpos,tire_radius,-rear_axle_width*.5)
rear_left_disc.col="#ff0000"
rear_left_disc.friction=metal_friction
rear_left_disc.restitution=metal_restitution
rear_left_disc.pre_sdl="object{disk"
v:add(rear_left_disc)

-- FRONT SPINDLE
-- right
front_right_spindle=Cube(arm_radius*2,tire_radius,arm_radius*2,mount_mass)
front_right_spindle.pos=btVector3(front_axle_xpos,tire_radius,front_axle_width*.5-tire_width*.5-arm_radius)
front_right_spindle.col="#ffff00"
front_right_spindle.friction=metal_friction
front_right_spindle.restitution=metal_restitution
v:add(front_right_spindle)
-- left
front_left_spindle=Cube(arm_radius*2,tire_radius,arm_radius*2,mount_mass)
front_left_spindle.pos=btVector3(front_axle_xpos,tire_radius,-(front_axle_width*.5-tire_width*.5-arm_radius))
front_left_spindle.col="#ffff00"
front_left_spindle.friction=metal_friction
front_left_spindle.restitution=metal_restitution
v:add(front_left_spindle)

-- REAR SPINDLE
-- right
rear_right_spindle=Cube(arm_radius*2,tire_radius,arm_radius*2,mount_mass)
rear_right_spindle.pos=btVector3(rear_axle_xpos,tire_radius,rear_axle_width*.5-tire_width*.5-arm_radius)
rear_right_spindle.col="#ffff00"
rear_right_spindle.friction=metal_friction
rear_right_spindle.restitution=metal_restitution
v:add(rear_right_spindle)
-- left
rear_left_spindle=Cube(arm_radius*2,tire_radius,arm_radius*2,mount_mass)
rear_left_spindle.pos=btVector3(rear_axle_xpos,tire_radius,-(rear_axle_width*.5-tire_width*.5-arm_radius))
rear_left_spindle.col="#ffff00"
rear_left_spindle.friction=metal_friction
rear_left_spindle.restitution=metal_restitution
v:add(rear_left_spindle)

-- FRONT CONTROL ARMS 
-- right
front_right_upper_arm=Cylinder(arm_radius,front_arm_lenght,arm_mass)
front_right_upper_arm.pos=btVector3(front_axle_xpos,tire_radius+tire_radius*.25+arm_radius,front_axle_width*.5-tire_width*.5-arm_radius*2-front_arm_lenght*.5)
front_right_upper_arm.col="#0000ff"
front_right_upper_arm.friction=tire_friction
front_right_upper_arm.restitution=tire_restitution
v:add(front_right_upper_arm)
front_right_lower_arm=Cylinder(arm_radius,front_arm_lenght,arm_mass)
front_right_lower_arm.pos=btVector3(front_axle_xpos,tire_radius-(tire_radius*.25+arm_radius),front_axle_width*.5-tire_width*.5-arm_radius*2-front_arm_lenght*.5)
front_right_lower_arm.col="#0000ff"
front_right_lower_arm.friction=tire_friction
front_right_lower_arm.restitution=tire_restitution
v:add(front_right_lower_arm)
-- left
front_left_upper_arm=Cylinder(arm_radius,front_arm_lenght,arm_mass)
front_left_upper_arm.pos=btVector3(front_axle_xpos,tire_radius+tire_radius*.25+arm_radius,-(front_axle_width*.5-tire_width*.5-arm_radius*2-front_arm_lenght*.5))
front_left_upper_arm.col="#0000ff"
front_left_upper_arm.friction=tire_friction
front_left_upper_arm.restitution=tire_restitution
v:add(front_left_upper_arm)
front_left_lower_arm=Cylinder(arm_radius,front_arm_lenght,arm_mass)
front_left_lower_arm.pos=btVector3(front_axle_xpos,tire_radius-(tire_radius*.25+arm_radius),-(front_axle_width*.5-tire_width*.5-arm_radius*2-front_arm_lenght*.5))
front_left_lower_arm.col="#0000ff"
front_left_lower_arm.friction=tire_friction
front_left_lower_arm.restitution=tire_restitution
v:add(front_left_lower_arm)

-- REAR CONTROL ARMS 
-- right
rear_right_upper_arm=Cylinder(arm_radius,rear_arm_lenght,arm_mass)
rear_right_upper_arm.pos=btVector3(rear_axle_xpos,tire_radius+tire_radius*.25+arm_radius,rear_axle_width*.5-tire_width*.5-arm_radius*2-rear_arm_lenght*.5)
rear_right_upper_arm.col="#0000ff"
rear_right_upper_arm.friction=tire_friction
rear_right_upper_arm.restitution=tire_restitution
v:add(rear_right_upper_arm)
rear_right_lower_arm=Cylinder(arm_radius,rear_arm_lenght,arm_mass)
rear_right_lower_arm.pos=btVector3(rear_axle_xpos,tire_radius-(tire_radius*.25+arm_radius),rear_axle_width*.5-tire_width*.5-arm_radius*2-rear_arm_lenght*.5)
rear_right_lower_arm.col="#0000ff"
rear_right_lower_arm.friction=tire_friction
rear_right_lower_arm.restitution=tire_restitution
v:add(rear_right_lower_arm)
-- left
rear_left_upper_arm=Cylinder(arm_radius,rear_arm_lenght,arm_mass)
rear_left_upper_arm.pos=btVector3(rear_axle_xpos,tire_radius+tire_radius*.25+arm_radius,-(rear_axle_width*.5-tire_width*.5-arm_radius*2-rear_arm_lenght*.5))
rear_left_upper_arm.col="#0000ff"
rear_left_upper_arm.friction=tire_friction
rear_left_upper_arm.restitution=tire_restitution
v:add(rear_left_upper_arm)
rear_left_lower_arm=Cylinder(arm_radius,rear_arm_lenght,arm_mass)
rear_left_lower_arm.pos=btVector3(rear_axle_xpos,tire_radius-(tire_radius*.25+arm_radius),-(rear_axle_width*.5-tire_width*.5-arm_radius*2-rear_arm_lenght*.5))
rear_left_lower_arm.col="#0000ff"
rear_left_lower_arm.friction=tire_friction
rear_left_lower_arm.restitution=tire_restitution
v:add(rear_left_lower_arm)

-- FRONT STABILIZER BARS
front_stabilizer_bar=Cylinder(arm_radius,front_axle_width-tire_width,arm_mass*2)
front_stabilizer_bar.pos=btVector3(front_axle_xpos+tire_radius*.4,tire_radius,0)
front_stabilizer_bar.col = "#0000ff"
front_stabilizer_bar.friction=metal_friction
front_stabilizer_bar.restitution=metal_restitution
v:add(front_stabilizer_bar)
front_stabilizer_bar2=Cylinder(arm_radius,front_axle_width-tire_width,arm_mass*2)
front_stabilizer_bar2.pos=btVector3(front_axle_xpos-tire_radius*.4,tire_radius,0)
front_stabilizer_bar2.col = "#0000ff"
front_stabilizer_bar2.friction=metal_friction
front_stabilizer_bar2.restitution=metal_restitution
v:add(front_stabilizer_bar2)

-- REAR STABILIZER BARS
rear_stabilizer_bar=Cylinder(arm_radius,rear_axle_width-tire_width,arm_mass*2)
rear_stabilizer_bar.pos=btVector3(rear_axle_xpos+tire_radius*.4,tire_radius,0)
rear_stabilizer_bar.col = "#0000ff"
rear_stabilizer_bar.friction=metal_friction
rear_stabilizer_bar.restitution=metal_restitution
v:add(rear_stabilizer_bar)
rear_stabilizer_bar2=Cylinder(arm_radius,rear_axle_width-tire_width,arm_mass*2)
rear_stabilizer_bar2.pos=btVector3(rear_axle_xpos-tire_radius*.4,tire_radius,0)
rear_stabilizer_bar2.col = "#0000ff"
rear_stabilizer_bar2.friction=metal_friction
rear_stabilizer_bar2.restitution=metal_restitution
v:add(rear_stabilizer_bar2)


-- ***************
-- CAR CONSTRAINTS
-- ***************

-- FRONT WHEEL-DISC CONSTRAINTS, ROTATION HINGE
-- right
pivotA = btVector3(0,0,0)
axisA  = btVector3(0,0,1)
pivotB = btVector3(0,0,0)
axisB  = btVector3(0,0,1)
front_right_wheel_disc_constraint = btHingeConstraint(
  front_right_disc:getRigidBody(),
  front_right_wheel:getRigidBody(),
  pivotA, pivotB, axisA, axisB
)
v:addConstraint(front_right_wheel_disc_constraint)
-- left
pivotA = btVector3(0,0,0)
axisA  = btVector3(0,0,1)
pivotB = btVector3(0,0,0)
axisB  = btVector3(0,0,1)
front_left_wheel_disc_constraint = btHingeConstraint(
  front_left_disc:getRigidBody(),
  front_left_wheel:getRigidBody(),
  pivotA, pivotB, axisA, axisB
)
v:addConstraint(front_left_wheel_disc_constraint)

-- REAR WHEEL-DISC CONSTRAINTS, ROTATION HINGE
-- right
pivotA = btVector3(0,0,0)
axisA  = btVector3(0,0,1)
pivotB = btVector3(0,0,0)
axisB  = btVector3(0,0,1)
rear_right_wheel_disc_constraint = btHingeConstraint(
  rear_right_disc:getRigidBody(),
  rear_right_wheel:getRigidBody(),
  pivotA, pivotB, axisA, axisB
)
v:addConstraint(rear_right_wheel_disc_constraint)
-- left
pivotA = btVector3(0,0,0)
axisA  = btVector3(0,0,1)
pivotB = btVector3(0,0,0)
axisB  = btVector3(0,0,1)
rear_left_wheel_disc_constraint = btHingeConstraint(
  rear_left_disc:getRigidBody(),
  rear_left_wheel:getRigidBody(),
  pivotA, pivotB, axisA, axisB
)
v:addConstraint(rear_left_wheel_disc_constraint)

-- FRONT STEERING CONSTRAINT

-- right
pivotA = btVector3(0,0,arm_radius)
axisA  = btVector3(0,0,1)
pivotB = btVector3(0,0,-tire_width*.5)
axisB  = btVector3(0,0,1)
front_right_disc_spindle_constraint = btHingeConstraint(
  front_right_spindle:getRigidBody(),
  front_right_disc:getRigidBody(),
  pivotA, pivotB, axisA, axisB)
front_right_disc_spindle_constraint:setAxis(btVector3(0,1,0))
front_right_disc_spindle_constraint:setLimit(0,0,.9,.3,1)
v:addConstraint(front_right_disc_spindle_constraint)

-- left
pivotA = btVector3(0,0,-arm_radius)
axisA  = btVector3(0,0,1)
pivotB = btVector3(0,0,tire_width*.5)
axisB  = btVector3(0,0,1)
front_left_disc_spindle_constraint = btHingeConstraint(
  front_left_spindle:getRigidBody(),
  front_left_disc:getRigidBody(),
  pivotA, pivotB, axisA, axisB)
front_left_disc_spindle_constraint:setAxis(btVector3(0,1,0))
front_left_disc_spindle_constraint:setLimit(0,0,.9,.3,1)
v:addConstraint(front_left_disc_spindle_constraint)

-- REAR STEERING CONSTRAINT (FIXED)

-- right
pivotA = btVector3(0,0,arm_radius)
axisA  = btVector3(0,0,1)
pivotB = btVector3(0,0,-tire_width*.5)
axisB  = btVector3(0,0,1)
rear_right_disc_spindle_constraint = btHingeConstraint(
  rear_right_spindle:getRigidBody(),
  rear_right_disc:getRigidBody(),
  pivotA, pivotB, axisA, axisB)
rear_right_disc_spindle_constraint:setAxis(btVector3(0,1,0))
rear_right_disc_spindle_constraint:setLimit(0,0,.9,.3,1)
v:addConstraint(rear_right_disc_spindle_constraint)

-- left
pivotA = btVector3(0,0,-arm_radius)
axisA  = btVector3(0,0,1)
pivotB = btVector3(0,0,tire_width*.5)
axisB  = btVector3(0,0,1)
rear_left_disc_spindle_constraint = btHingeConstraint(
  rear_left_spindle:getRigidBody(),
  rear_left_disc:getRigidBody(),
  pivotA, pivotB, axisA, axisB)
rear_left_disc_spindle_constraint:setAxis(btVector3(0,1,0))
rear_left_disc_spindle_constraint:setLimit(0,0,.9,.3,1)
v:addConstraint(rear_left_disc_spindle_constraint)

-- FRONT ARMS CONTRAINTS

-- right
pivotA = btVector3(0,0,front_arm_lenght*.5)
axisA  = btVector3(1,0,0)
pivotB = btVector3(0,tire_radius*.25+arm_radius,-arm_radius)
axisB  = btVector3(1,0,0)
front_right_upper_arm_spindle_constraint = btHingeConstraint(
  front_right_upper_arm:getRigidBody(),
  front_right_spindle:getRigidBody(),
  pivotA, pivotB, axisA, axisB
)
v:addConstraint(front_right_upper_arm_spindle_constraint)
pivotA = btVector3(0,0,front_arm_lenght*.5)
axisA  = btVector3(1,0,0)
pivotB = btVector3(0,-(tire_radius*.25+arm_radius),-arm_radius)
axisB  = btVector3(1,0,0)
front_right_lower_arm_spindle_constraint = btHingeConstraint(
  front_right_lower_arm:getRigidBody(),
  front_right_spindle:getRigidBody(),
  pivotA, pivotB, axisA, axisB
)
v:addConstraint(front_right_lower_arm_spindle_constraint)
pivotA = btVector3(0,0,-front_arm_lenght*.5)
axisA  = btVector3(1,0,0)
pivotB = btVector3(front_axle_xpos,arm_body_height+tire_radius*.25+arm_radius,front_axle_width*.5-tire_width*.5-arm_radius*2-front_arm_lenght)
axisB  = btVector3(1,0,0)
front_right_upper_arm_chassis_constraint = btHingeConstraint(
  front_right_upper_arm:getRigidBody(),
  chassis:getRigidBody(),
  pivotA, pivotB, axisA, axisB
)
v:addConstraint(front_right_upper_arm_chassis_constraint)
pivotA = btVector3(0,0,-front_arm_lenght*.5)
axisA  = btVector3(1,0,0)
pivotB = btVector3(front_axle_xpos,arm_body_height-tire_radius*.25-arm_radius,front_axle_width*.5-tire_width*.5-arm_radius*2-front_arm_lenght)
axisB  = btVector3(1,0,0)
front_right_lower_arm_chassis_constraint = btHingeConstraint(
  front_right_lower_arm:getRigidBody(),
  chassis:getRigidBody(),
  pivotA, pivotB, axisA, axisB
)
v:addConstraint(front_right_lower_arm_chassis_constraint)

-- left
pivotA = btVector3(0,0,-front_arm_lenght*.5)
axisA  = btVector3(1,0,0)
pivotB = btVector3(0,tire_radius*.25+arm_radius,arm_radius)
axisB  = btVector3(1,0,0)
front_left_upper_arm_spindle_constraint = btHingeConstraint(
  front_left_upper_arm:getRigidBody(),
  front_left_spindle:getRigidBody(),
  pivotA, pivotB, axisA, axisB
)
v:addConstraint(front_left_upper_arm_spindle_constraint)
pivotA = btVector3(0,0,-front_arm_lenght*.5)
axisA  = btVector3(1,0,0)
pivotB = btVector3(0,-(tire_radius*.25+arm_radius),arm_radius)
axisB  = btVector3(1,0,0)
front_left_lower_arm_spindle_constraint = btHingeConstraint(
  front_left_lower_arm:getRigidBody(),
  front_left_spindle:getRigidBody(),
  pivotA, pivotB, axisA, axisB
)
v:addConstraint(front_left_lower_arm_spindle_constraint)
pivotA = btVector3(0,0,front_arm_lenght*.5)
axisA  = btVector3(1,0,0)
pivotB = btVector3(front_axle_xpos,arm_body_height+tire_radius*.25+arm_radius,-(front_axle_width*.5-tire_width*.5-arm_radius*2-front_arm_lenght))
axisB  = btVector3(1,0,0)
front_left_upper_arm_chassis_constraint = btHingeConstraint(
  front_left_upper_arm:getRigidBody(),
  chassis:getRigidBody(),
  pivotA, pivotB, axisA, axisB
)
v:addConstraint(front_left_upper_arm_chassis_constraint)
pivotA = btVector3(0,0,front_arm_lenght*.5)
axisA  = btVector3(1,0,0)
pivotB = btVector3(front_axle_xpos,arm_body_height-tire_radius*.25-arm_radius,-(front_axle_width*.5-tire_width*.5-arm_radius*2-front_arm_lenght))
axisB  = btVector3(1,0,0)
front_left_lower_arm_chassis_constraint = btHingeConstraint(
  front_left_lower_arm:getRigidBody(),
  chassis:getRigidBody(),
  pivotA, pivotB, axisA, axisB
)
v:addConstraint(front_left_lower_arm_chassis_constraint)

-- REAR ARMS CONTRAINTS

-- right
pivotA = btVector3(0,0,rear_arm_lenght*.5)
axisA  = btVector3(1,0,0)
pivotB = btVector3(0,tire_radius*.25+arm_radius,-arm_radius)
axisB  = btVector3(1,0,0)
rear_right_upper_arm_spindle_constraint = btHingeConstraint(
  rear_right_upper_arm:getRigidBody(),
  rear_right_spindle:getRigidBody(),
  pivotA, pivotB, axisA, axisB
)
v:addConstraint(rear_right_upper_arm_spindle_constraint)
pivotA = btVector3(0,0,rear_arm_lenght*.5)
axisA  = btVector3(1,0,0)
pivotB = btVector3(0,-(tire_radius*.25+arm_radius),-arm_radius)
axisB  = btVector3(1,0,0)
rear_right_lower_arm_spindle_constraint = btHingeConstraint(
  rear_right_lower_arm:getRigidBody(),
  rear_right_spindle:getRigidBody(),
  pivotA, pivotB, axisA, axisB
)
v:addConstraint(rear_right_lower_arm_spindle_constraint)
pivotA = btVector3(0,0,-rear_arm_lenght*.5)
axisA  = btVector3(1,0,0)
pivotB = btVector3(rear_axle_xpos,arm_body_height+tire_radius*.25+arm_radius,rear_axle_width*.5-tire_width*.5-arm_radius*2-rear_arm_lenght)
axisB  = btVector3(1,0,0)
rear_right_upper_arm_chassis_constraint = btHingeConstraint(
  rear_right_upper_arm:getRigidBody(),
  chassis:getRigidBody(),
  pivotA, pivotB, axisA, axisB
)
v:addConstraint(rear_right_upper_arm_chassis_constraint)
pivotA = btVector3(0,0,-rear_arm_lenght*.5)
axisA  = btVector3(1,0,0)
pivotB = btVector3(rear_axle_xpos,arm_body_height-tire_radius*.25-arm_radius,rear_axle_width*.5-tire_width*.5-arm_radius*2-rear_arm_lenght)
axisB  = btVector3(1,0,0)
rear_right_lower_arm_chassis_constraint = btHingeConstraint(
  rear_right_lower_arm:getRigidBody(),
  chassis:getRigidBody(),
  pivotA, pivotB, axisA, axisB
)
v:addConstraint(rear_right_lower_arm_chassis_constraint)
-- left
pivotA = btVector3(0,0,-rear_arm_lenght*.5)
axisA  = btVector3(1,0,0)
pivotB = btVector3(0,tire_radius*.25+arm_radius,arm_radius)
axisB  = btVector3(1,0,0)
rear_left_upper_arm_spindle_constraint = btHingeConstraint(
  rear_left_upper_arm:getRigidBody(),
  rear_left_spindle:getRigidBody(),
  pivotA, pivotB, axisA, axisB
)
v:addConstraint(rear_left_upper_arm_spindle_constraint)
pivotA = btVector3(0,0,-rear_arm_lenght*.5)
axisA  = btVector3(1,0,0)
pivotB = btVector3(0,-(tire_radius*.25+arm_radius),arm_radius)
axisB  = btVector3(1,0,0)
rear_left_lower_arm_spindle_constraint = btHingeConstraint(
  rear_left_lower_arm:getRigidBody(),
  rear_left_spindle:getRigidBody(),
  pivotA, pivotB, axisA, axisB
)
v:addConstraint(rear_left_lower_arm_spindle_constraint)
pivotA = btVector3(0,0,rear_arm_lenght*.5)
axisA  = btVector3(1,0,0)
pivotB = btVector3(rear_axle_xpos,arm_body_height+tire_radius*.25+arm_radius,-(rear_axle_width*.5-tire_width*.5-arm_radius*2-rear_arm_lenght))
axisB  = btVector3(1,0,0)
rear_left_upper_arm_chassis_constraint = btHingeConstraint(
  rear_left_upper_arm:getRigidBody(),
  chassis:getRigidBody(),
  pivotA, pivotB, axisA, axisB
)
v:addConstraint(rear_left_upper_arm_chassis_constraint)
pivotA = btVector3(0,0,rear_arm_lenght*.5)
axisA  = btVector3(1,0,0)
pivotB = btVector3(rear_axle_xpos,arm_body_height-tire_radius*.25-arm_radius,-(rear_axle_width*.5-tire_width*.5-arm_radius*2-rear_arm_lenght))
axisB  = btVector3(1,0,0)
rear_left_lower_arm_chassis_constraint = btHingeConstraint(
  rear_left_lower_arm:getRigidBody(),
  chassis:getRigidBody(),
  pivotA, pivotB, axisA, axisB
)
v:addConstraint(rear_left_lower_arm_chassis_constraint)

-- FRONT SPRING CONSTRAINTS (NO GEOM)

-- right
q = btQuaternion()
o = btVector3(front_axle_xpos,arm_body_height+tire_radius*.5,front_axle_width*.5-tire_width*.5-arm_radius)
frameA=btTransform(q,o)
o = btVector3(0,tire_radius*.5,0)
frameB=btTransform(q,o)
front_right_upper_arm_chassis_spring = btGeneric6DofConstraint(
  chassis:getRigidBody(),
  front_right_spindle:getRigidBody(),
  frameA,
  frameB,
  false
)
front_right_upper_arm_chassis_spring:setLimit(0,0,0)
front_right_upper_arm_chassis_spring:setLimit(1,suspension_lower_limit,suspension_upper_limit)
front_right_upper_arm_chassis_spring:setLimit(2,0,0)
front_right_upper_arm_chassis_spring:setLimit(3,0,0)
front_right_upper_arm_chassis_spring:setLimit(4,0,0)
front_right_upper_arm_chassis_spring:setLimit(5,0,0)
v:addConstraint(front_right_upper_arm_chassis_spring)
-- left
q = btQuaternion()
o = btVector3(front_axle_xpos,arm_body_height+tire_radius*.5,-(front_axle_width*.5-tire_width*.5-arm_radius))
frameA=btTransform(q,o)
o = btVector3(0,tire_radius*.5,0)
frameB=btTransform(q,o)
front_left_upper_arm_chassis_spring = btGeneric6DofConstraint(
  chassis:getRigidBody(),
  front_left_spindle:getRigidBody(),
  frameA,
  frameB,
  false
)
front_left_upper_arm_chassis_spring:setLimit(0,0,0)
front_left_upper_arm_chassis_spring:setLimit(1,suspension_lower_limit,suspension_upper_limit)
front_left_upper_arm_chassis_spring:setLimit(2,0,0)
front_left_upper_arm_chassis_spring:setLimit(3,0,0)
front_left_upper_arm_chassis_spring:setLimit(4,0,0)
front_left_upper_arm_chassis_spring:setLimit(5,0,0)
v:addConstraint(front_left_upper_arm_chassis_spring)

-- REAR SPRING CONSTRAINTS (NO GEOM)

-- right
q = btQuaternion()
o = btVector3(rear_axle_xpos,arm_body_height+tire_radius*.5,rear_axle_width*.5-tire_width*.5-arm_radius)
rear_right_chassis_trans=btTransform(q,o)
o = btVector3(0,tire_radius*.5,0)
rear_right_upper_arm_trans=btTransform(q,o)
rear_right_upper_arm_chassis_spring = btGeneric6DofConstraint(
  chassis:getRigidBody(),
  rear_right_spindle:getRigidBody(),
  rear_right_chassis_trans,
  rear_right_upper_arm_trans,
  false
)
rear_right_upper_arm_chassis_spring:setLimit(0,0,0)
rear_right_upper_arm_chassis_spring:setLimit(1,suspension_lower_limit,suspension_upper_limit)
rear_right_upper_arm_chassis_spring:setLimit(2,0,0)
rear_right_upper_arm_chassis_spring:setLimit(3,0,0)
rear_right_upper_arm_chassis_spring:setLimit(4,0,0)
rear_right_upper_arm_chassis_spring:setLimit(5,0,0)
v:addConstraint(rear_right_upper_arm_chassis_spring)
-- left
q = btQuaternion()
o = btVector3(rear_axle_xpos,arm_body_height+tire_radius*.5,-(rear_axle_width*.5-tire_width*.5-arm_radius))
rear_left_chassis_trans=btTransform(q,o)
o = btVector3(0,tire_radius*.5,0)
rear_left_upper_arm_trans=btTransform(q,o)
rear_left_upper_arm_chassis_spring = btGeneric6DofConstraint(
  chassis:getRigidBody(),
  rear_left_spindle:getRigidBody(),
  rear_left_chassis_trans,
  rear_left_upper_arm_trans,
  false
)
rear_left_upper_arm_chassis_spring:setLimit(0,0,0)
rear_left_upper_arm_chassis_spring:setLimit(1,suspension_lower_limit,suspension_upper_limit)
rear_left_upper_arm_chassis_spring:setLimit(2,0,0)
rear_left_upper_arm_chassis_spring:setLimit(3,0,0)
rear_left_upper_arm_chassis_spring:setLimit(4,0,0)
rear_left_upper_arm_chassis_spring:setLimit(5,0,0)
v:addConstraint(rear_left_upper_arm_chassis_spring)

-- FRONT STABILIZER BAR-DISCS-BODY CONSTRAINTS

-- right
pivotA = btVector3(tire_radius*.4,0,-tire_width*.5)
pivotB = btVector3(0,0,front_axle_width*.5-tire_width*.5)
front_right_stabilizer_bar_constraint = btPoint2PointConstraint(
  front_right_disc:getRigidBody(),
  front_stabilizer_bar:getRigidBody(),
  pivotA,
  pivotB
)
v:addConstraint(front_right_stabilizer_bar_constraint)
pivotA = btVector3(-tire_radius*.4,0,-tire_width*.5)
pivotB = btVector3(0,0,front_axle_width*.5-tire_width*.5)
front_right_stabilizer_bar2_constraint = btPoint2PointConstraint(
  front_right_disc:getRigidBody(),
  front_stabilizer_bar2:getRigidBody(),
  pivotA,
  pivotB
)
v:addConstraint(front_right_stabilizer_bar2_constraint)
-- left
pivotA = btVector3(tire_radius*.4,0,tire_width*.5)
pivotB = btVector3(0,0,-front_axle_width*.5+tire_width*.5)
front_left_stabilizer_bar_constraint = btPoint2PointConstraint(
  front_left_disc:getRigidBody(),
  front_stabilizer_bar:getRigidBody(),
  pivotA,
  pivotB
)
v:addConstraint(front_left_stabilizer_bar_constraint)
pivotA = btVector3(-tire_radius*.4,0,tire_width*.5)
pivotB = btVector3(0,0,-front_axle_width*.5+tire_width*.5)
front_left_stabilizer_bar2_constraint = btPoint2PointConstraint(
  front_left_disc:getRigidBody(),
  front_stabilizer_bar2:getRigidBody(),
  pivotA,
  pivotB
)
v:addConstraint(front_left_stabilizer_bar2_constraint)
-- center
q = btQuaternion()
o = btVector3(front_axle_xpos+tire_radius*.4,arm_body_height,0)
frameA=btTransform(q,o)
o = btVector3(0,0,0)
frameB=btTransform(q,o)
front_center_stabilizer_bar_constraint = btGeneric6DofConstraint(
  chassis:getRigidBody(),
  front_stabilizer_bar:getRigidBody(),
  frameA,
  frameB,
  false
)
v:addConstraint(front_center_stabilizer_bar_constraint)
front_center_stabilizer_bar_constraint:setLimit(0,0,0)
front_center_stabilizer_bar_constraint:setLimit(1,suspension_lower_limit,suspension_upper_limit)
front_center_stabilizer_bar_constraint:setLimit(2,0,0)
front_center_stabilizer_bar_constraint:setLimit(3,-math.pi*.125,math.pi*.125)
front_center_stabilizer_bar_constraint:setLimit(4,0,0)
front_center_stabilizer_bar_constraint:setLimit(5,0,0)
q = btQuaternion()
o = btVector3(front_axle_xpos-tire_radius*.4,arm_body_height,0)
frameA=btTransform(q,o)
o = btVector3(0,0,0)
frameB=btTransform(q,o)
front_center_stabilizer_bar2_constraint = btGeneric6DofConstraint(
  chassis:getRigidBody(),
  front_stabilizer_bar2:getRigidBody(),
  frameA,
  frameB,
  false
)
v:addConstraint(front_center_stabilizer_bar2_constraint)
front_center_stabilizer_bar2_constraint:setLimit(0,0,0)
front_center_stabilizer_bar2_constraint:setLimit(1,suspension_lower_limit,suspension_upper_limit)
front_center_stabilizer_bar2_constraint:setLimit(2,0,0)
front_center_stabilizer_bar2_constraint:setLimit(3,-math.pi*.125,math.pi*.125)
front_center_stabilizer_bar2_constraint:setLimit(4,0,0)
front_center_stabilizer_bar2_constraint:setLimit(5,0,0)

-- REAR STABILIZER BAR-DISCS-BODY CONSTRAINTS

-- right
pivotA = btVector3(tire_radius*.4,0,-tire_width*.5)
pivotB = btVector3(0,0,rear_axle_width*.5-tire_width*.5)
rear_right_stabilizer_bar_constraint = btPoint2PointConstraint(
  rear_right_disc:getRigidBody(),
  rear_stabilizer_bar:getRigidBody(),
  pivotA,
  pivotB
)
v:addConstraint(rear_right_stabilizer_bar_constraint)
pivotA = btVector3(-tire_radius*.4,0,-tire_width*.5)
pivotB = btVector3(0,0,rear_axle_width*.5-tire_width*.5)
rear_right_stabilizer_bar2_constraint = btPoint2PointConstraint(
  rear_right_disc:getRigidBody(),
  rear_stabilizer_bar2:getRigidBody(),
  pivotA,
  pivotB
)
v:addConstraint(rear_right_stabilizer_bar2_constraint)
-- left
pivotA = btVector3(tire_radius*.4,0,tire_width*.5)
pivotB = btVector3(0,0,-rear_axle_width*.5+tire_width*.5)
rear_left_stabilizer_bar_constraint = btPoint2PointConstraint(
  rear_left_disc:getRigidBody(),
  rear_stabilizer_bar:getRigidBody(),
  pivotA,
  pivotB
)
v:addConstraint(rear_left_stabilizer_bar_constraint)
pivotA = btVector3(-tire_radius*.4,0,tire_width*.5)
pivotB = btVector3(0,0,-rear_axle_width*.5+tire_width*.5)
rear_left_stabilizer_bar2_constraint = btPoint2PointConstraint(
  rear_left_disc:getRigidBody(),
  rear_stabilizer_bar2:getRigidBody(),
  pivotA,
  pivotB
)
v:addConstraint(rear_left_stabilizer_bar2_constraint)
-- center
q = btQuaternion()
o = btVector3(rear_axle_xpos+tire_radius*.4,-chassis_height+tire_radius,0)
rear_center_body_trans=btTransform(q,o)
o = btVector3(0,0,0)
rear_center_stabilizer_bar_trans=btTransform(q,o)
rear_center_stabilizer_bar_constraint = btGeneric6DofConstraint(
  chassis:getRigidBody(),
  rear_stabilizer_bar:getRigidBody(),
  rear_center_body_trans,
  rear_center_stabilizer_bar_trans,
  false
)
rear_center_stabilizer_bar_constraint:setLimit(0,0,0)
rear_center_stabilizer_bar_constraint:setLimit(1,suspension_lower_limit,suspension_upper_limit)
rear_center_stabilizer_bar_constraint:setLimit(2,0,0)
rear_center_stabilizer_bar_constraint:setLimit(3,-math.pi*.125,math.pi*.125)
rear_center_stabilizer_bar_constraint:setLimit(4,0,0)
rear_center_stabilizer_bar_constraint:setLimit(5,0,0)
v:addConstraint(rear_center_stabilizer_bar_constraint)
q = btQuaternion()
o = btVector3(rear_axle_xpos-tire_radius*.4,-chassis_height+tire_radius,0)
rear_center_body_trans=btTransform(q,o)
o = btVector3(0,0,0)
rear_center_stabilizer_bar_trans=btTransform(q,o)
rear_center_stabilizer_bar2_constraint = btGeneric6DofConstraint(
  chassis:getRigidBody(),
  rear_stabilizer_bar2:getRigidBody(),
  rear_center_body_trans,
  rear_center_stabilizer_bar_trans,
  false
)
rear_center_stabilizer_bar2_constraint:setLimit(0,0,0)
rear_center_stabilizer_bar2_constraint:setLimit(1,suspension_lower_limit,suspension_upper_limit)
rear_center_stabilizer_bar2_constraint:setLimit(2,0,0)
rear_center_stabilizer_bar2_constraint:setLimit(3,-math.pi*.125,math.pi*.125)
rear_center_stabilizer_bar2_constraint:setLimit(4,0,0)
rear_center_stabilizer_bar2_constraint:setLimit(5,0,0)
v:addConstraint(rear_center_stabilizer_bar2_constraint)

-- ENGINE-CHASSIS
pivotA = btVector3(0,0,0)
pivotB = btVector3(engine_xpos,-chassis_height+engine_height,0)
engine_constraint = btPoint2PointConstraint(
  engine:getRigidBody(),
  chassis:getRigidBody(),
  pivotA,
  pivotB
)
v:addConstraint(engine_constraint)


-- ************
-- TEST SCENERY
-- ************

-- default floor plane
if(use_obstacles<=1) then
  plane = Plane(0,1,0,0,1500)
--  plane = Cube(1000,1,1000,0)
  plane.col = "#111111"
  plane.pos=btVector3(0,0,0)
  plane.friction=1
  plane.restitution=.1
  plane.pre_sdl="object{ground"
  v:add(plane)
end

-- ground markings for reference of deviation
function lane(zpos)
  for j = 0,1 do
    for i = 1,20 do
      marks=Cube(10,.01,1,0)
      marks.pos=btVector3(-420+i*40,-.004,-15+30*j+zpos)
      marks.col = "#FF9900"
      marks.friction=.9
      marks.pre_sdl="object{track_mark()"
      v:add(marks)
    end
  end
end

-- suspension test: 
if(use_obstacles==1) then
  testbed=Mesh("demo/3ds/testbed.3ds",0)
  testbed.pos =btVector3(0,0,0)
  testbed.col="#996600"
  testbed.friction=.9
  testbed.restitution=0
  testbed.pre_sdl="object{testbed"
  v:add(testbed)
lane(0)
lane(108)
lane(-108)
lane(217)
lane(-216)
end

-- suspension test: mesh terrain test
if(use_obstacles==2) then
  terrain=Mesh("demo/3ds/terrain.3ds",0)
  terrain.pos =btVector3(0,-1,0)
  terrain.col="#993399"
  terrain.friction=.9
  terrain.restitution=0
  v:add(terrain)
end


-- ******************
-- KEYBOARD SHORTCUTS
-- ******************

-- switch camera
v:addShortcut("F1", function(N)
  camera_view = camera_view + 1;
  if (camera_view == 8) then
    camera_view = 1
  end
end)

-- steer left
v:addShortcut("F9", function(N)
  steer_power_right=max_angular_steer_power
  front_center_stabilizer_bar_constraint:setLimit(0,-tire_radius*.5,tire_radius*.5)
  front_center_stabilizer_bar_constraint:setLimit(2,-tire_radius*.25,tire_radius*.25)
  front_center_stabilizer_bar2_constraint:setLimit(0,-tire_radius*.5,tire_radius*.5)
  front_center_stabilizer_bar2_constraint:setLimit(2,-tire_radius*.25,tire_radius*.25)
  front_right_disc_spindle_constraint:setLimit(-math.pi*.33,math.pi*.33,.9,.3,1)
  front_left_disc_spindle_constraint:setLimit(-math.pi*.33,math.pi*.33,.9,.3,1)
  front_right_disc_spindle_constraint:enableAngularMotor(true, -10, steer_power_right)
  front_left_disc_spindle_constraint:enableAngularMotor(true, -10, steer_power_right)
  turning_right=N
  turning_left=nil
end)

-- steer right
v:addShortcut("F10", function(N)
  steer_power_left=max_angular_steer_power
  front_center_stabilizer_bar_constraint:setLimit(0,-tire_radius*.5,tire_radius*.5)
  front_center_stabilizer_bar_constraint:setLimit(2,-tire_radius*.25,tire_radius*.25)
  front_center_stabilizer_bar2_constraint:setLimit(0,-tire_radius*.5,tire_radius*.5)
  front_center_stabilizer_bar2_constraint:setLimit(2,-tire_radius*.25,tire_radius*.25)
  front_right_disc_spindle_constraint:setLimit(-math.pi*.33,math.pi*.33,.9,.3,1)
  front_left_disc_spindle_constraint:setLimit(-math.pi*.33,math.pi*.33,.9,.3,1)
  front_right_disc_spindle_constraint:enableAngularMotor(true, 10, steer_power_left)
  front_left_disc_spindle_constraint:enableAngularMotor(true, 10, steer_power_left)
  turning_left=N
  turning_right=nil
end)

-- accelerate forward
v:addShortcut("F2", function(N)
 front_right_wheel_disc_constraint:setLimit(1,-1,0,.3,1)
 front_left_wheel_disc_constraint:setLimit(1,-1,0,.3,1)
 rear_right_wheel_disc_constraint:setLimit(1,-1,0,.3,1)
 rear_left_wheel_disc_constraint:setLimit(1,-1,0,.3,1)
 current_angular_velocity=initial_angular_velocity
 steer_angle=front_right_disc_spindle_constraint:getHingeAngle()
 car_direction=btVector3(
   rear_left_wheel.pos.x-rear_right_wheel.pos.x,
   rear_left_wheel.pos.y-rear_right_wheel.pos.y,
   rear_left_wheel.pos.z-rear_right_wheel.pos.z
 ):normalized():rotate(btVector3(0,1,0),-steer_angle)
 wheel_angular_velocity=car_direction*current_angular_velocity
 if(drivetrain_type==1 or drivetrain_type==3) then
  front_right_wheel.body:setAngularVelocity(wheel_angular_velocity)
  front_left_wheel.body:setAngularVelocity(wheel_angular_velocity)
 end
 if(drivetrain_type==2 or drivetrain_type==3) then
  rear_right_wheel.body:setAngularVelocity(wheel_angular_velocity)
  rear_left_wheel.body:setAngularVelocity(wheel_angular_velocity)
 end
 accelerating=N
 braking=nil
end)

-- accelerate backward
v:addShortcut("F4", function(N)
 front_right_wheel_disc_constraint:setLimit(1,-1,0,.3,1)
 front_left_wheel_disc_constraint:setLimit(1,-1,0,.3,1)
 rear_right_wheel_disc_constraint:setLimit(1,-1,0,.3,1)
 rear_left_wheel_disc_constraint:setLimit(1,-1,0,.3,1)
 current_angular_velocity=-initial_angular_velocity
 steer_angle=front_right_disc_spindle_constraint:getHingeAngle()
 car_direction=btVector3(
   rear_left_wheel.pos.x-rear_right_wheel.pos.x,
   rear_left_wheel.pos.y-rear_right_wheel.pos.y,
   rear_left_wheel.pos.z-rear_right_wheel.pos.z
 ):normalized():rotate(btVector3(0,1,0),-steer_angle)
 wheel_angular_velocity=car_direction*current_angular_velocity
 if(drivetrain_type==1 or drivetrain_type==3) then
  front_right_wheel.body:setAngularVelocity(wheel_angular_velocity)
  front_left_wheel.body:setAngularVelocity(wheel_angular_velocity)
 end
 if(drivetrain_type==2 or drivetrain_type==3) then
  rear_right_wheel.body:setAngularVelocity(wheel_angular_velocity)
  rear_left_wheel.body:setAngularVelocity(wheel_angular_velocity)
 end
 accelerating=N
 braking=nil
end)

-- brake
v:addShortcut("F3", function(N)
  front_right_wheel_disc_constraint:setLimit(0,0,0,.3,1)
  front_left_wheel_disc_constraint:setLimit(0,0,0,.3,1)
  rear_right_wheel_disc_constraint:setLimit(0,0,0,.3,1)
  rear_left_wheel_disc_constraint:setLimit(0,0,0,.3,1)
  accelerating=nil
  braking=N
end)

-- neutral
v:addShortcut("F5", function(N)
  front_right_wheel.body:setAngularVelocity(btVector3(0,0,0))
  front_left_wheel.body:setAngularVelocity(btVector3(0,0,0))
  rear_right_wheel.body:setAngularVelocity(btVector3(0,0,0))
  rear_left_wheel.body:setAngularVelocity(btVector3(0,0,0))
  accelerating=nil
  braking=nil
end)


-- *********************
-- POST SIMULATION STUFF
-- *********************
v:postSim(function(N)

-- CAMERA VIEWS 
if(camera_view>0) then
  cam = Cam() 
  -- from the back, moves with the car
  if(camera_view==1) then
    cam.pos = rear_stabilizer_bar.pos+btVector3(rear_stabilizer_bar.pos.x-front_stabilizer_bar.pos.x,chassis_height+5,rear_stabilizer_bar.pos.z-front_stabilizer_bar.pos.z)*2
    cam.look = chassis.pos+btVector3(front_stabilizer_bar.pos.x-rear_stabilizer_bar.pos.x,front_stabilizer_bar.pos.y-rear_stabilizer_bar.pos.y+4,front_stabilizer_bar.pos.z-rear_stabilizer_bar.pos.z)
  end
  -- onboard
  if(camera_view==2) then
    cam.pos = btVector3(rear_stabilizer_bar.pos.x,chassis.pos.y+onboard_cam_height,rear_stabilizer_bar.pos.z)
    cam.look = chassis.pos+btVector3(front_stabilizer_bar.pos.x-rear_stabilizer_bar.pos.x,front_stabilizer_bar.pos.y-rear_stabilizer_bar.pos.y+onboard_cam_height,front_stabilizer_bar.pos.z-rear_stabilizer_bar.pos.z)
    cam:setHorizontalFieldOfView(.5)
  end
  -- static mount looking at the car
  if(camera_view==3) then
    cam.pos = btVector3(50,40,60)
    cam.look = chassis.pos
    cam:setHorizontalFieldOfView(1)
  end
  -- close look at the front suspension and wheels
  if(camera_view==4) then
    cam.pos = btVector3(chassis.pos.x+79,4,chassis.pos.z)
    cam.look = btVector3(chassis.pos.x,chassis.pos.y,chassis.pos.z)
    cam:setHorizontalFieldOfView(.5)
  end
  -- close look at the rear suspension and wheels
  if(camera_view==5) then
    cam.pos = btVector3(chassis.pos.x-45,chassis.pos.y,chassis.pos.z)
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
-- aerial view
  if(camera_view==8) then
    cam.pos = btVector3(chassis.pos.x,500,chassis.pos.z)
    cam.look = chassis.pos
  end  
  v:setCam(cam)
end

-- CAR STEERING: AUTO-STRAIGHTEN 
if(turning_right~=nil) then
  if(N>(turning_right+11)) then
    steer_power_right=nil
    front_right_disc_spindle_constraint:enableAngularMotor(false, 0, 0)
    front_left_disc_spindle_constraint:enableAngularMotor(false, 0, 0)
    front_right_disc_spindle_constraint:setLimit(0,0,.9,.3,1)
    front_left_disc_spindle_constraint:setLimit(0,0,.9,.3,1)
    front_center_stabilizer_bar_constraint:setLimit(0,0,0)
    front_center_stabilizer_bar_constraint:setLimit(2,0,0)
    front_center_stabilizer_bar2_constraint:setLimit(0,0,0)
    front_center_stabilizer_bar2_constraint:setLimit(2,0,0)
    turning_right=nil
  end
end
if(turning_left~=nil) then
  if(N>(turning_left+11)) then
    steer_power_left=nil
    front_right_disc_spindle_constraint:enableAngularMotor(false, 0, 0)
    front_left_disc_spindle_constraint:enableAngularMotor(false, 0, 0)
    front_right_disc_spindle_constraint:setLimit(0,0,.9,.3,1)
    front_left_disc_spindle_constraint:setLimit(0,0,.9,.3,1)
    front_center_stabilizer_bar_constraint:setLimit(0,0,0)
    front_center_stabilizer_bar_constraint:setLimit(2,0,0)
    front_center_stabilizer_bar2_constraint:setLimit(0,0,0)
    front_center_stabilizer_bar2_constraint:setLimit(2,0,0)
    turning_left=nil
  end
end

-- CAR ACCELERATION: MANTAIN POWER ONCE STARTED WITH F2 or F4
if(accelerating~=nil and  current_angular_velocity~=nil and accelerating<N) then
  steer_angle=front_right_disc_spindle_constraint:getHingeAngle()
  car_direction=btVector3(
    rear_left_wheel.pos.x-rear_right_wheel.pos.x,
    rear_left_wheel.pos.y-rear_right_wheel.pos.y,
    rear_left_wheel.pos.z-rear_right_wheel.pos.z
  ):normalized():rotate(btVector3(0,1,0),-steer_angle)
  wheel_angular_velocity=car_direction*current_angular_velocity
  if(drivetrain_type==1 or drivetrain_type==3) then
    front_right_wheel.body:setAngularVelocity(wheel_angular_velocity)
    front_left_wheel.body:setAngularVelocity(wheel_angular_velocity)
  end
  if(drivetrain_type==2 or drivetrain_type==3) then
    rear_right_wheel.body:setAngularVelocity(wheel_angular_velocity)
    rear_left_wheel.body:setAngularVelocity(wheel_angular_velocity)
  end
end

-- EXPORT SOME VARIABLES FOR USE IN POV-Ray
v.pre_sdl="#declare chassis_pos=<"..chassis.pos.x..","..chassis.pos.y..","..chassis.pos.z..">;".."\n".."#declare front_pos=<"..front_stabilizer_bar.pos.x..","..front_stabilizer_bar.pos.y..","..front_stabilizer_bar.pos.z..">;".."\n".."#declare rear_pos=<"..rear_stabilizer_bar.pos.x..","..rear_stabilizer_bar.pos.y..","..rear_stabilizer_bar.pos.z..">;".."\n".."\n"
  

end) -- postSim

v:onCommand(function(cmd)
--  print(cmd)
  local f = assert(loadstring(cmd))
  f(v)
end)  -- onCommand

-- EOF
