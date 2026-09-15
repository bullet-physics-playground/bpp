-- =======================================================================
-- CONTROL PANEL -- live GUI gravity slider via bpp's own v:addParam /
-- v:getParam, not a plain Lua variable. Gravity needs extra care:
-- DRIVE_TORQUE (further down) is computed FROM gravity once, at that
-- point in the script -- it won't follow a later slider move on its
-- own. The postSim block near the bottom watches for gravity changes
-- and recomputes + reapplies DRIVE_TORQUE and the escapement's motor
-- call whenever it does.
-- =======================================================================
local PARAM_INFO = {
  gravity = { min = 200, max = 10000, step = 100,
              comment = "primary speed lever -- beat period scales as 1/sqrt(gravity), so 3x faster needs ~9x this value, not 3x." },
}

local function setParam(name, value)
  local info = PARAM_INFO[name]
  value = math.max(info.min, math.min(info.max, value))
  v:addParam(name, value, info.min, info.max, info.step, info.comment)
  return value
end

setParam("gravity", 3138)

v.gravity = btVector3(0, -v:getParam("gravity"), 0)
v.friction = 1
v:setErp(0.4)
v:setErp2(0.0)
v.timeStep = 1.0/10.0

-- Tick/tock sound effects, extracted from a clock-ticking recording.
-- loadSound() is safe to call even with no audio device present (returns
-- -1); playSound() on an invalid id is a silent no-op, so this degrades
-- gracefully on a machine/CI run with no audio hardware.
local tickSoundId = v:loadSound("demo/sound/tick.wav")
local tockSoundId = v:loadSound("demo/sound/tock.wav")

c = Cube(6000,6000,6,0) -- static plate
c.pos = btVector3(0, 300, 0)
c.col = "#050"
c.friction = .1
c.body:setAngularVelocity(btVector3(0,0,0))
v:add(c)

-- Palette and Pendulum -- MIRRORED across X (the escapement wheel
-- rotates clockwise; rather than add an idler gear to reverse direction
-- back for the gear train, the escapement itself runs counter-clockwise
-- and the pallet is mirrored to still engage correctly). Mirrored on
-- the actual STL geometry (vertices negated in x, winding flipped),
-- not a coordinate hack.
g1 = Mesh("demo/mesh/WMS_N2_Pend.stl", 100, false)
g1.col = "#fa0"
g1.pos = btVector3(19,339,304) -- pivot retuned to reduce recoil
g1.friction = 0.1
g1.restitution = 0.0
g1.body:setLinearFactor(btVector3(0.1,0.1,0));
v:add(g1)

pivot0 = btVector3(0,257,304) -- pivot retuned to reduce recoil
axis0 = btVector3(0,0,1)
pivot1 = btVector3(-19,218,0)
axis1 = btVector3(0,0,1)

con1 = btHingeConstraint(
  c.body, g1.body, pivot0, pivot1, axis0, axis1)
v:addConstraint(con1)

-- Escapement Wheel -- driven by the drum/weight below, not a direct
-- motor.
g2 = Mesh("demo/mesh/WMS_N2_Wheel.stl", 100, false)
g2.col = "#f00"
g2.pos = btVector3(0,151,300)
g2.friction = 0.1
g2.restitution = 0.0
g2.body:setLinearFactor(btVector3(0,0,0));
v:add(g2)

pivot0 = btVector3(0,-149,300)
axis0 = btVector3(0,0,1)
pivot1 = btVector3(0,0,0)
axis1 = btVector3(0,0,1)

con0 = btHingeConstraint(
  c.body, g2.body, pivot0, pivot1, axis0, axis1)
v:addConstraint(con0)

-- ---------------------------------------------------------------------
-- Winding drum + weight, welded directly onto the escape wheel's own
-- arbor -- constant torque via enableAngularMotor with an unreachable
-- target velocity.
-- ---------------------------------------------------------------------
local DRUM_R  = 40
local DRUM_TH = 15
local WEIGHT_M = 0.11 -- tuned for beat consistency
local WEIGHT_R, WEIGHT_H = 22, 80
local DRIVE_SIGN = 1 -- natural clockwise direction

local DRUM_Z_EXTRA = 40
drum = Cylinder(DRUM_R, DRUM_TH, 2)
drum.col = "Silver"
drum.transparency = 0.8
drum.pos = btVector3(g2.pos.x, g2.pos.y, g2.pos.z + DRUM_Z_EXTRA)
v:add(drum)

local drum_frameInG2   = btTransform(btQuaternion(0,0,0,1), btVector3(0,0,DRUM_Z_EXTRA))
local drum_frameInDrum = btTransform(btQuaternion(0,0,0,1), btVector3(0,0,0))
local drum_weld = btGeneric6DofConstraint(g2.body, drum.body, drum_frameInG2, drum_frameInDrum, true)
drum_weld:setLinearLowerLimit(btVector3(0,0,0))
drum_weld:setLinearUpperLimit(btVector3(0,0,0))
drum_weld:setLimit(3, 0, 0)
drum_weld:setLimit(4, 0, 0)
drum_weld:setLimit(5, 0, 0)
v:addConstraint(drum_weld)

local UP_Z_TO_Y = btQuaternion(btVector3(1,0,0), -math.pi/2)
local CORD_X = drum.pos.x + DRUM_R

weight = Cylinder(WEIGHT_R, WEIGHT_H, 0)
weight.col = "#B5A642"
v:add(weight)
local WEIGHT_TOP_Y = drum.pos.y - DRUM_R - WEIGHT_H/2 - 10
weight.body:setMotionState(btDefaultMotionState(
  btTransform(UP_Z_TO_Y, btVector3(CORD_X, WEIGHT_TOP_Y, drum.pos.z))))

local CORD_R = 3
local MAX_DROP = 2000
local cordTopY = drum.pos.y
local cordBottomY = WEIGHT_TOP_Y + WEIGHT_H/2 - MAX_DROP
cord = Cylinder(CORD_R, cordTopY - cordBottomY, 0)
cord.col = "Wheat"
v:add(cord)
cord.body:setMotionState(btDefaultMotionState(
  btTransform(UP_Z_TO_Y, btVector3(CORD_X, (cordTopY + cordBottomY)/2, drum.pos.z))))

local DRIVE_TORQUE = WEIGHT_M * math.abs(v.gravity.y) * DRUM_R
con0:enableAngularMotor(true, DRIVE_SIGN * 100, DRIVE_TORQUE)

-- ---------------------------------------------------------------------
-- Gear train + hands. Second, minute, and hour hands, all driven off
-- one gear train: second hand welded directly to g2 (the escape
-- wheel), minute hand welded to gearD (stage 2, 60:1 down from g2),
-- hour hand welded to hourWheel (stage 3, 720:1 down from g2, via the
-- idler-corrected coaxial wheel).
-- ---------------------------------------------------------------------

local function involute_gear_sdl(n, module_m, pressure_angle, th, phase_deg)
  local r_p = module_m * n / 2
  local r_b = r_p * math.cos(math.rad(pressure_angle))
  local r_a = r_p + module_m
  local r_d = r_p - 1.25 * module_m
  local half_tooth_deg = 90 / n
  phase_deg = phase_deg or 0
  local sdl = string.format([=[
n = %d; r_b = %f; r_p = %f; r_a = %f; r_d = %f; half_tooth = %f; th = %f; phase = %f; res = 8;
function involute(base_radius, involute_angle) = [
  base_radius*(cos(involute_angle) + involute_angle*PI/180*sin(involute_angle)),
  base_radius*(sin(involute_angle) - involute_angle*PI/180*cos(involute_angle))];
function involute_intersect_angle(base_radius, radius) = sqrt(pow(radius/base_radius, 2) - 1) * 180 / PI;
function rotate_point(rot, coord) = [cos(rot)*coord[0] + sin(rot)*coord[1], cos(rot)*coord[1] - sin(rot)*coord[0]];
function mirror_point(coord) = [ coord[0], -coord[1] ];
min_radius = max(r_b, r_d);
pitch_point = involute(r_b, involute_intersect_angle(r_b, r_p));
pitch_angle = atan2(pitch_point[1], pitch_point[0]);
centre_angle = pitch_angle + half_tooth;
start_angle = involute_intersect_angle(r_b, min_radius);
stop_angle  = involute_intersect_angle(r_b, r_a);
root_pt = rotate_point(centre_angle, [r_d, 0]);
right_flank = concat([ root_pt ], [ for (i = [0:res]) rotate_point(centre_angle, involute(r_b, start_angle + (stop_angle - start_angle)*i/res)) ]);
left_flank_rev = [ for (i = [len(right_flank)-1:-1:0]) mirror_point(right_flank[i]) ];
tooth_pts = concat(right_flank, left_flank_rev);
module tooth(rot_deg) { rotate([0, 0, rot_deg]) polygon(points = tooth_pts); }
linear_extrude(height = th, center = true)
  rotate(phase) {
    union() {
      rotate(half_tooth) circle(r = r_d, $fn = n*2);
      for (i = [0:n-1]) tooth(i*360/n);
    }
  }
]=], n, r_b, r_p, r_a, r_d, half_tooth_deg, th, phase_deg)
  return sdl, r_p
end

local function counterbalanced_hand_sdl(length, w0, w1, tail, tail_w, th, zOffset)
  local function fmt_pt(x, y) return string.format("[%f, %f]", x, y) end
  local pts = table.concat({
    fmt_pt(0, w0/2), fmt_pt(length*0.7, w1/2), fmt_pt(length, 0),
    fmt_pt(length*0.7, -w1/2), fmt_pt(0, -w0/2),
    fmt_pt(-tail, -tail_w/2), fmt_pt(-tail, tail_w/2),
  }, ", ")
  return string.format("translate([0,0,%f]) linear_extrude(height=%f, center=true) polygon(points=[%s]);",
                        zOffset, th, pts)
end

local GEAR_MODULE = 2.7778
local GEAR_PRESSURE = 20
local GEAR_TH = 10

-- Stage 1: 8T pinion welded onto g2's own arbor, meshing with a 40T wheel
local GEAR_Z = g2.pos.z + 60

local sdlA, rpA = involute_gear_sdl(8, GEAR_MODULE, GEAR_PRESSURE, GEAR_TH)
gearA = OpenSCAD(sdlA, 4, true)
gearA.col = "#ccc"
gearA.pos = btVector3(g2.pos.x, g2.pos.y, GEAR_Z) 
gearA.friction = 0.1
v:add(gearA)

local gearA_frameInG2 = btTransform(btQuaternion(0,0,0,1), btVector3(0, 0, GEAR_Z - g2.pos.z))
local gearA_frameInGearA = btTransform(btQuaternion(0,0,0,1), btVector3(0, 0, 0))
local gearA_weld = btGeneric6DofConstraint(g2.body, gearA.body, gearA_frameInG2, gearA_frameInGearA, true)
gearA_weld:setLinearLowerLimit(btVector3(0,0,0))
gearA_weld:setLinearUpperLimit(btVector3(0,0,0))
gearA_weld:setLimit(3, 0, 0)
gearA_weld:setLimit(4, 0, 0)
gearA_weld:setLimit(5, 0, 0)
v:addConstraint(gearA_weld)

-- Second hand: welded directly onto g2's own arbor.
local SECOND_HAND_Z = g2.pos.z + 210 -- 20 units past the hour hand (z=494) so it's the outermost, closest-to-viewer element, matching a real clock's second hand
secondHand = OpenSCAD(counterbalanced_hand_sdl(90, 6, 3, 30, 33.180, 5, 0), 0.2, true) -- tail_w recomputed from the actual polygon centroid, verified exact to within 1e-14
secondHand.col = "#AD8B71"
secondHand.pos = btVector3(g2.pos.x, g2.pos.y, SECOND_HAND_Z)
v:add(secondHand)

local secondHand_frameInG2 = btTransform(btQuaternion(0,0,0,1), btVector3(0, 0, SECOND_HAND_Z - g2.pos.z))
local secondHand_frameInHand = btTransform(btQuaternion(0,0,0,1), btVector3(0, 0, 0))
local secondHand_weld = btGeneric6DofConstraint(g2.body, secondHand.body, secondHand_frameInG2, secondHand_frameInHand, true)
secondHand_weld:setLinearLowerLimit(btVector3(0,0,0))
secondHand_weld:setLinearUpperLimit(btVector3(0,0,0))
secondHand_weld:setLimit(3, 0, 0)
secondHand_weld:setLimit(4, 0, 0)
secondHand_weld:setLimit(5, 0, 0)
v:addConstraint(secondHand_weld)

local sdlB, rpB = involute_gear_sdl(40, GEAR_MODULE, GEAR_PRESSURE, GEAR_TH, 360/40/2)
local BACKLASH = 0.3 -- WMS: test -- real gear designs always include clearance; this design had zero
local meshDist = rpA + rpB + BACKLASH
local gearBx, gearBy, gearBz = gearA.pos.x + meshDist, gearA.pos.y, gearA.pos.z
-- WMS Add 100 to .z to disengage

gearB_anchor = Cylinder(2.25, GEAR_TH, 0)
gearB_anchor.pos = btVector3(gearBx, gearBy, gearBz)
gearB_anchor.col = "#ccc"
v:add(gearB_anchor)

gearB = OpenSCAD(sdlB, 1.5, true)
gearB.col = "#A2B9DE"
gearB.pos = btVector3(gearBx, gearBy, gearBz)
gearB.friction = 0.1
v:add(gearB)

local gearB_con = btHingeConstraint(gearB_anchor.body, gearB.body, btVector3(0,0,0), btVector3(0,0,0), btVector3(0,0,1), btVector3(0,0,1))
v:addConstraint(gearB_con)

-- Stage 2: 8T pinion welded onto gearB's arbor, meshing with a 96T
-- wheel -- no hand attached, intermediate stage only.
local GEAR2_Z = g2.pos.z + 100

local sdlC, rpC = involute_gear_sdl(8, GEAR_MODULE, GEAR_PRESSURE, GEAR_TH)
gearC = OpenSCAD(sdlC, 4, true)
gearC.col = "#ccc"
gearC.pos = btVector3(gearB.pos.x, gearB.pos.y, GEAR2_Z)
gearC.friction = 0.1
v:add(gearC)

local gearC_frameInGearB = btTransform(btQuaternion(0,0,0,1), btVector3(0, 0, GEAR2_Z - gearB.pos.z))
local gearC_frameInGearC = btTransform(btQuaternion(0,0,0,1), btVector3(0, 0, 0))
local gearC_weld = btGeneric6DofConstraint(gearB.body, gearC.body, gearC_frameInGearB, gearC_frameInGearC, true)
gearC_weld:setLinearLowerLimit(btVector3(0,0,0))
gearC_weld:setLinearUpperLimit(btVector3(0,0,0))
gearC_weld:setLimit(3, 0, 0)
gearC_weld:setLimit(4, 0, 0)
gearC_weld:setLimit(5, 0, 0)
v:addConstraint(gearC_weld)

local sdlD, rpD = involute_gear_sdl(96, GEAR_MODULE, GEAR_PRESSURE, GEAR_TH, 360/96/2)
local mesh2Dist = rpC + rpD + BACKLASH
-- COAXIAL: gearD's position is solved to be EXACTLY mesh2Dist from
-- gearC (preserving the mesh) AND exactly (rpE_pinion + rpHourWheel =
-- 144.44) from g2 itself -- a two-circle intersection. This lets gearE
-- (welded to gearD) mesh directly with a hollow hour wheel centered
-- exactly on g2's own axis, instead of sitting off to the side.
-- ADJUSTABLE: rotates gearD clockwise around gearC (negative =
-- clockwise), preserving the gearC-gearD mesh distance while opening up
-- the gearE-hourWheel gap the idler needs. Valid range is roughly -1 to
-- -20 (beyond -20.7 the gap exceeds what any idler can reach). -15
-- gives a comfortable, non-degenerate margin.
local GEARD_ROTATION_DEG = -15

local gearD_origAngle = math.deg(math.atan2(291.546 - gearC.pos.y, 33.335 - gearC.pos.x))
local gearD_radius = math.sqrt((33.335-gearC.pos.x)^2 + (291.546-gearC.pos.y)^2)
local gearD_ang = math.rad(gearD_origAngle + GEARD_ROTATION_DEG)
local gearDx = gearC.pos.x + gearD_radius * math.cos(gearD_ang)
local gearDy = gearC.pos.y + gearD_radius * math.sin(gearD_ang)
local gearDz = gearC.pos.z

gearD_anchor = Cylinder(2.25, GEAR_TH, 0)
gearD_anchor.pos = btVector3(gearDx, gearDy, gearDz)
gearD_anchor.col = "#ccc"
v:add(gearD_anchor)

gearD = OpenSCAD(sdlD, 1.5, true)
gearD.col = "coral"
gearD.pos = btVector3(gearDx, gearDy, gearDz)
gearD.friction = 0.1
v:add(gearD)

-- Minute hand starts at the current real-world minute, not zero.
-- Rotating gearD itself (not the hand) before its hinge is created, so
-- the weld just rigidly carries it. Rounded to the nearest tooth pitch
-- (360/96=3.75deg) so gearD stays correctly meshed with gearC (left at
-- its own default phase). This one reference angle is trusted --
-- everything downstream of gearD (hourWheel included) is now derived
-- from it via the drivetrain's own exact gear ratio, rather than each
-- being independently guessed from wall-clock time. -- WMS
local WMS_gearD_roundedDeg
do
  local t = os.date("*t")
  local minuteDeg = (t.min + t.sec/60) * 6
  local pitch = 360/96
  local roundedDeg = math.floor(minuteDeg/pitch + 0.5) * pitch
  WMS_gearD_roundedDeg = roundedDeg
  print(string.format("MINUTE HAND SYNC: os.date=%02d:%02d:%02d -> minuteDeg=%.3f -> rounded to %.3f",
                       t.hour, t.min, t.sec, minuteDeg, roundedDeg))
  local quat = btQuaternion(btVector3(0,0,1), math.rad(90 - roundedDeg))
  gearD.body:setMotionState(btDefaultMotionState(btTransform(quat, gearD.pos)))
end

local gearD_con = btHingeConstraint(gearD_anchor.body, gearD.body, btVector3(0,0,0), btVector3(0,0,0), btVector3(0,0,1), btVector3(0,0,1))
v:addConstraint(gearD_con)

-- Minute hand: welded directly onto gearD's own arbor, 60:1 down from
-- g2. Direction matches g2/the second hand (the two mesh reversals
-- gearA->gearB and gearC->gearD cancel out). NOT coaxial with
-- g2/hourWheel -- gearD sits off to the side at its own (x,y); only
-- hourWheel gets the hollow coaxial wheel + idler treatment. Dimensions
-- (75, 8, 4, 30, tail_w=29.500) follow the 60/75/90 hour/minute/second
-- length pattern and are mass-balanced (polygon centroid at the pivot,
-- Cx=0).
local MINUTE_HAND_Z = gearD.pos.z + 55
minuteHand = OpenSCAD(counterbalanced_hand_sdl(75, 8, 4, 30, 29.500, 5, 0), 0.2, true)
minuteHand.col = "#2ca02c"
minuteHand.pos = btVector3(gearD.pos.x, gearD.pos.y, MINUTE_HAND_Z)
v:add(minuteHand)

local minuteHand_frameInGearD = btTransform(btQuaternion(0,0,0,1), btVector3(0, 0, MINUTE_HAND_Z - gearD.pos.z))
local minuteHand_frameInHand = btTransform(btQuaternion(0,0,0,1), btVector3(0, 0, 0))
local minuteHand_weld = btGeneric6DofConstraint(gearD.body, minuteHand.body, minuteHand_frameInGearD, minuteHand_frameInHand, true)
minuteHand_weld:setLinearLowerLimit(btVector3(0,0,0))
minuteHand_weld:setLinearUpperLimit(btVector3(0,0,0))
minuteHand_weld:setLimit(3, 0, 0)
minuteHand_weld:setLimit(4, 0, 0)
minuteHand_weld:setLimit(5, 0, 0)
v:addConstraint(minuteHand_weld)

-- Stage 3: 8T pinion welded onto gearD's arbor, meshing with a hollow
-- 96T hour wheel that shares g2's own rotation axis -- 720:1 cumulative
-- from the escape wheel.
local GEAR3_Z = g2.pos.z + 140

local sdlE, rpE = involute_gear_sdl(8, GEAR_MODULE, GEAR_PRESSURE, GEAR_TH)
gearE = OpenSCAD(sdlE, 4, true)
gearE.col = "#ccc"
gearE.pos = btVector3(gearD.pos.x, gearD.pos.y, GEAR3_Z)
gearE.friction = 0.1
v:add(gearE)

local gearE_frameInGearD = btTransform(btQuaternion(0,0,0,1), btVector3(0, 0, GEAR3_Z - gearD.pos.z))
local gearE_frameInGearE = btTransform(btQuaternion(0,0,0,1), btVector3(0, 0, 0))
local gearE_weld = btGeneric6DofConstraint(gearD.body, gearE.body, gearE_frameInGearD, gearE_frameInGearE, true)
gearE_weld:setLinearLowerLimit(btVector3(0,0,0))
gearE_weld:setLinearUpperLimit(btVector3(0,0,0))
gearE_weld:setLimit(3, 0, 0)
gearE_weld:setLimit(4, 0, 0)
gearE_weld:setLimit(5, 0, 0)
v:addConstraint(gearE_weld)

local function involute_gear_hollow_sdl(n, module_m, pressure_angle, th, inner_radius, phase_deg)
  local r_p = module_m * n / 2
  local r_b = r_p * math.cos(math.rad(pressure_angle))
  local r_a = r_p + module_m
  local r_d = r_p - 1.25 * module_m
  local half_tooth_deg = 90 / n
  phase_deg = phase_deg or 0
  local sdl = string.format([=[
n = %d; r_b = %f; r_p = %f; r_a = %f; r_d = %f; half_tooth = %f; th = %f; phase = %f; res = 8; inner_r = %f;
function involute(base_radius, involute_angle) = [
  base_radius*(cos(involute_angle) + involute_angle*PI/180*sin(involute_angle)),
  base_radius*(sin(involute_angle) - involute_angle*PI/180*cos(involute_angle))];
function involute_intersect_angle(base_radius, radius) = sqrt(pow(radius/base_radius, 2) - 1) * 180 / PI;
function rotate_point(rot, coord) = [cos(rot)*coord[0] + sin(rot)*coord[1], cos(rot)*coord[1] - sin(rot)*coord[0]];
function mirror_point(coord) = [ coord[0], -coord[1] ];
min_radius = max(r_b, r_d);
pitch_point = involute(r_b, involute_intersect_angle(r_b, r_p));
pitch_angle = atan2(pitch_point[1], pitch_point[0]);
centre_angle = pitch_angle + half_tooth;
start_angle = involute_intersect_angle(r_b, min_radius);
stop_angle  = involute_intersect_angle(r_b, r_a);
root_pt = rotate_point(centre_angle, [r_d, 0]);
right_flank = concat([ root_pt ], [ for (i = [0:res]) rotate_point(centre_angle, involute(r_b, start_angle + (stop_angle - start_angle)*i/res)) ]);
left_flank_rev = [ for (i = [len(right_flank)-1:-1:0]) mirror_point(right_flank[i]) ];
tooth_pts = concat(right_flank, left_flank_rev);
module tooth(rot_deg) { rotate([0, 0, rot_deg]) polygon(points = tooth_pts); }
linear_extrude(height = th, center = true)
  rotate(phase) {
    difference() {
      union() {
        rotate(half_tooth) circle(r = r_d, $fn = n*2);
        for (i = [0:n-1]) tooth(i*360/n);
      }
      circle(r = inner_r, $fn = 48);
    }
  }
]=], n, r_b, r_p, r_a, r_d, half_tooth_deg, th, phase_deg, inner_radius)
  return sdl, r_p
end

local HOUR_WHEEL_Z = gearE.pos.z -- every mesh pair in this design shares the same z; hourWheel needs to too.

-- Idler gear: 8 teeth, adds a fourth mesh reversal so hourWheel rotates
-- the SAME direction as g2 (matching the second hand). Position solved
-- via two-circle intersection: exactly (rpE + rpIdler) from gearE, and
-- exactly (rpIdler + rpHour) from g2 -- automatically adapts if
-- GEARD_ROTATION_DEG above changes.
local sdlIdler, rpIdler = involute_gear_sdl(8, GEAR_MODULE, GEAR_PRESSURE, GEAR_TH)
local rpHour = GEAR_MODULE * 96 / 2 -- needed before hourWheel's own SDL generation below
local idler_r1 = rpE + rpIdler + BACKLASH
local idler_r2 = rpIdler + rpHour + BACKLASH
local idler_dx, idler_dy = g2.pos.x - gearE.pos.x, g2.pos.y - gearE.pos.y
local idler_d = math.sqrt(idler_dx^2 + idler_dy^2)
assert(idler_d < idler_r1 + idler_r2, "GEARD_ROTATION_DEG is rotated too far -- the idler can no longer reach both gearE and hourWheel. Reduce the magnitude.")
local idler_a = (idler_r1^2 - idler_r2^2 + idler_d^2) / (2*idler_d)
local idler_h = math.sqrt(math.max(0, idler_r1^2 - idler_a^2))
local idler_xm = gearE.pos.x + idler_a*idler_dx/idler_d
local idler_ym = gearE.pos.y + idler_a*idler_dy/idler_d
local idlerX = idler_xm + idler_h*idler_dy/idler_d
local idlerY = idler_ym - idler_h*idler_dx/idler_d
local idlerZ = gearE.pos.z

idler_anchor = Cylinder(2.25, GEAR_TH, 0)
idler_anchor.pos = btVector3(idlerX, idlerY, idlerZ)
idler_anchor.col = "#ccc"
v:add(idler_anchor)

idlerGear = OpenSCAD(sdlIdler, 4, true)
idlerGear.col = "#eee"
idlerGear.pos = btVector3(idlerX, idlerY, idlerZ)
idlerGear.friction = 0.1
v:add(idlerGear)

local idler_con = btHingeConstraint(idler_anchor.body, idlerGear.body, btVector3(0,0,0), btVector3(0,0,0), btVector3(0,0,1), btVector3(0,0,1))
v:addConstraint(idler_con)

local sdlHour, rpHour = involute_gear_hollow_sdl(96, GEAR_MODULE, GEAR_PRESSURE, GEAR_TH, 40, 360/96/2)
hourWheel = OpenSCAD(sdlHour, 1.5, true)
hourWheel.col = "maroon"
hourWheel.pos = btVector3(g2.pos.x, g2.pos.y, HOUR_WHEEL_Z) -- COAXIAL: same x,y as g2 itself
hourWheel.friction = 0.1
v:add(hourWheel)

-- Hour hand starts at the current real-world hour, not zero. Rather than
-- independently computing hourDeg from wall-clock time and rounding it
-- separately (which had no guarantee of staying in phase with gearD at
-- the idler joint), derive hourWheel's angle FROM gearD's already-set
-- angle via the drivetrain's own exact 12:1 ratio (720:1 g2:hourWheel /
-- 60:1 g2:gearD) -- the same way turning a real clock's minute hand
-- carries the hour hand along with it, rather than setting both
-- independently and hoping they agree. -- WMS
do
  local t = os.date("*t")
  local hour12 = t.hour % 12
  -- gearD's TOTAL accumulated rotation since 12:00 (not wrapped to a
  -- single hour), using the same rounded value gearD was actually set
  -- to above, so this inherits gearD's trusted phase exactly.
  local gearD_totalDeg = WMS_gearD_roundedDeg + hour12 * 360
  local hourWheelDeg = gearD_totalDeg / 12
  print(string.format("HOUR HAND SYNC: os.date=%02d:%02d:%02d -> hour12=%d -> hourWheelDeg=%.3f (derived from gearD's rounded phase, not independently rounded)",
                       t.hour, t.min, t.sec, hour12, hourWheelDeg))
  local quat = btQuaternion(btVector3(0,0,1), math.rad(90 - hourWheelDeg))
  hourWheel.body:setMotionState(btDefaultMotionState(btTransform(quat, hourWheel.pos)))
end

-- COAXIAL HINGE: shares g2's own (x,y) pivot exactly, just at
-- hourWheel's own z -- the hour wheel rotates independently of g2 at
-- its own much slower rate while sharing the same rotation axis.
local hourWheel_pivot0 = btVector3(g2.pos.x - c.pos.x, g2.pos.y - c.pos.y, HOUR_WHEEL_Z - c.pos.z)
local hourWheel_con = btHingeConstraint(c.body, hourWheel.body, hourWheel_pivot0, btVector3(0,0,0), btVector3(0,0,1), btVector3(0,0,1))
v:addConstraint(hourWheel_con)

local HOUR_HAND_Z = hourWheel.pos.z + 10
hourHand = OpenSCAD(counterbalanced_hand_sdl(60, 10, 5, 30, 21.800, 5, 0), 0.2, true)
hourHand.col = "#1a1aff"
hourHand.pos = btVector3(hourWheel.pos.x, hourWheel.pos.y, HOUR_HAND_Z)
v:add(hourHand)

local hourHand_frameInHourWheel = btTransform(btQuaternion(0,0,0,1), btVector3(0, 0, HOUR_HAND_Z - hourWheel.pos.z))
local hourHand_frameInHand = btTransform(btQuaternion(0,0,0,1), btVector3(0, 0, 0))
local hourHand_weld = btGeneric6DofConstraint(hourWheel.body, hourHand.body, hourHand_frameInHourWheel, hourHand_frameInHand, true)
hourHand_weld:setLinearLowerLimit(btVector3(0,0,0))
hourHand_weld:setLinearUpperLimit(btVector3(0,0,0))
hourHand_weld:setLimit(3, 0, 0)
hourHand_weld:setLimit(4, 0, 0)
hourHand_weld:setLimit(5, 0, 0)
v:addConstraint(hourHand_weld)

-- ---------------------------------------------------------------------
-- Diagnostics: gear slip (per stage), pallet/wheel penetration depth,
-- tooth-skip detection, and beat measurement (sim vs real OS time).
-- ---------------------------------------------------------------------
local function angleTracker(obj)
  local q0 = obj.trans:getRotation()
  local prevC, prevS = q0:getW()*q0:getW() - q0:getZ()*q0:getZ(), 2*q0:getW()*q0:getZ()
  local turn = 0
  return function()
    local q = obj.trans:getRotation()
    local qz, qw = q:getZ(), q:getW()
    local c, s = qw*qw - qz*qz, 2*qw*qz
    local dSin = s*prevC - c*prevS
    local dCos = c*prevC + s*prevS
    if dCos > 0 then turn = turn + math.asin(math.max(-1, math.min(1, dSin))) end
    prevC, prevS = c, s
    return turn
  end
end

local trackGearA, trackGearB = angleTracker(gearA), angleTracker(gearB)
local GEAR_RATIO = 8 / 40
local GEAR_SLIP_LIMIT_DEG = (360/40) / 2
local gearSlipWarned = false
local trackGearC, trackGearD = angleTracker(gearC), angleTracker(gearD)
local GEAR2_RATIO = 8 / 96
local GEAR2_SLIP_LIMIT_DEG = (360/96) / 2
local gear2SlipWarned = false
local trackGearE, trackGearF = angleTracker(gearE), angleTracker(hourWheel)
local GEAR3_RATIO = 8 / 96
local GEAR3_SLIP_LIMIT_DEG = (360/96) / 2
local gear3SlipWarned = false

-- Penetration-depth diagnostic: objective measurement of pallet/wheel
-- contact depth (dist<0 = real interpenetration). Gated behind
-- DEBUG_PENETRATION -- when false, the v:eachContact() call itself
-- never runs (see v:postSim below), not just the prints.
local DEBUG_PENETRATION = false
local EMBED_WARN_THRESHOLD = -1.0
local worstOverallDist = nil
local worstOverallFrame = nil
local prevWheelC, prevWheelS = 1, 0
local TOOTH_SKIP_THRESHOLD_DEG = 8

-- Hoisted rather than built fresh every frame, to avoid allocating new
-- closures on every physics step. objIs()/rawObjEq() pass the same
-- function reference to pcall each time instead of building a new
-- wrapper closure per call (the pcall itself is still needed --
-- comparing certain userdata combinations without it can raise rather
-- than just returning false).
local function rawObjEq(a, b) return a == b end
local function objIs(a, b)
  local ok, eq = pcall(rawObjEq, a, b)
  return ok and eq
end

local worstDistThisFrame = nil   -- reset at the top of every postSim call, read back after v:eachContact() returns

local function trackWorstContactDist(oa, ob, px, py, pz, nx, ny, nz, dist, impulse)
  if (objIs(oa, g1) and objIs(ob, g2)) or (objIs(oa, g2) and objIs(ob, g1)) then
    if worstDistThisFrame == nil or dist < worstDistThisFrame then
      worstDistThisFrame = dist
    end
  end
end

local wheelTurn, prevC, prevS = 0, 1, 0
local lastAngVel = 0
local lastBeatTime = 0
-- v:getTime(): bpp's own wall-clock timer (Viewer::getTime(), backed by
-- a QElapsedTimer), used here for real beat-duration measurement.
local lastBeatClock = v:getTime()
local simClockStart = v:getTime()
local beatCount = 0

-- RECOIL FILTER: this escapement recoils (briefly reverses) right after
-- some true beats, crossing the pendulum's zero-angular-velocity
-- threshold again almost immediately -- a naive zero-crossing counter
-- would count that as an extra beat. MIN_BEAT_DURATION_SIM rejects any
-- crossing under this many sim-seconds after the last counted beat
-- (true beats run ~2.5-2.9s here, spurious ones ~0.1s -- a wide,
-- unambiguous gap).
local MIN_BEAT_DURATION_SIM = 1.0

-- ---------------------------------------------------------------------
-- SLOW-MOVING GRAVITY CONTROLLER: nudges the "gravity" slider, once
-- every BEATS_PER_BLOCK beats, so the REAL (wall-clock) time for a
-- whole block of beats drifts toward TARGET_BLOCK_SECONDS. Reuses the
-- existing "gravity" lever -- calls setParam("gravity", ...), and the
-- "Live gravity-slider tracking" block below picks the new value up on
-- the next frame and reapplies DRIVE_TORQUE + the escapement motor +
-- v.gravity, exactly as if a person had moved the slider by hand.
--
-- Sign: higher gravity means a SHORTER pendulum period (beat period
-- scales as 1/sqrt(gravity)), so a block running SLOWER than target
-- (positive error) needs a POSITIVE gravity nudge to speed it back up.
--
-- Measures the way a clockmaker actually would -- a stopwatch across a
-- fixed, physically meaningful number of beats, reading off the total
-- elapsed time, rather than each individual beat's own duration.
--
-- BEATS_PER_BLOCK=42: this wheel has 21 teeth, x 2 beats/tooth = one
-- full escape-wheel revolution. TARGET_BLOCK_SECONDS=60.0 is fixed: the
-- second hand is welded directly to the escape wheel with no reduction,
-- so one wheel revolution IS one second-hand rotation, which must
-- complete in exactly 60 real seconds by definition -- true regardless
-- of tooth count. TARGET_BEAT_REAL is derived from those two
-- (60/42 = 1.4286s/beat), not hardcoded.
local BEATS_PER_BLOCK          = 42     -- 21 teeth x 2 beats/tooth = one full escape-wheel revolution
local TARGET_BLOCK_SECONDS     = 60.0   -- fixed: one wheel revolution = one second-hand rotation = 60 real seconds, by definition
local TARGET_BEAT_REAL         = TARGET_BLOCK_SECONDS / BEATS_PER_BLOCK   -- derived, not hardcoded: 60/42 = 1.4286s/beat
local BLOCK_ERROR_DEADBAND     = 1.0    -- block |error| (seconds) must exceed this before any correction happens
local BLOCK_GAIN               = 300 / 42   -- gravity units per second of block error, before clamping
local MAX_GRAVITY_STEP_PER_UPDATE = PARAM_INFO.gravity.step   -- reuse the slider's own step size as the hard per-update cap
local CONTROL_WARMUP_BEATS     = 5      -- beats since SIM START (not "since training started") to skip before block monitoring starts -- block monitoring now runs continuously regardless of training state, see the postSim block below.
local blockStartClock = nil             -- v:getTime() at the start of the current BEATS_PER_BLOCK-beat stopwatch block
local blockBeatCount = 0                -- how many beats into the current block so far

-- ---------------------------------------------------------------------
-- TRAINING / LOCK WORKFLOW: press 'T' to start a training run (the
-- controller above becomes active and starts adjusting gravity); press
-- 'G' once it looks stable to lock gravity at its current value and
-- stop touching it, session-wide. Starts OFF by default -- a headless
-- run never presses a key, so gravity just stays at its startup value.
local training = false          -- true only between a 'T' press and the next 'G' press
local trainingStartBeat = nil   -- beatCount at the moment training last started, so CONTROL_WARMUP_BEATS
                                 -- counts beats since THIS training run began, not beats since the sim started
local trainingGravityMin = nil  -- lowest gravity value actually seen during the current/most recent training session
local trainingGravityMax = nil  -- highest gravity value actually seen during the current/most recent training session

-- Records a gravity value as part of "the range considered while
-- training" -- called once when training starts (the starting value
-- counts too, even if no correction ever moves it) and again after
-- every actual correction.
local function noteGravitySeen(g)
  if trainingGravityMin == nil or g < trainingGravityMin then trainingGravityMin = g end
  if trainingGravityMax == nil or g > trainingGravityMax then trainingGravityMax = g end
end

v:addShortcut("T", function(N)
  if training then
    print("[tuning] already running -- press 'G' to lock in the current gravity, or let it keep tuning")
    return
  end
  training = true
  trainingStartBeat = beatCount
  blockStartClock = nil   -- discard any in-progress block from before training started (or from a previous training run)
  blockBeatCount = 0
  trainingGravityMin, trainingGravityMax = nil, nil   -- fresh range for this session
  local startG = v:getParam("gravity")
  noteGravitySeen(startG)
  print(string.format("[tuning] STARTED at frame %d, gravity=%.1f -- adjusting until 'G' locks it in", N, startG))
end)

v:addShortcut("G", function(N)
  if not training then
    print("[tuning] not currently running -- press 'T' first to start tuning, then 'G' once it's settled")
    return
  end
  training = false
  print(string.format("[tuning] LOCKED at frame %d -- gravity=%.1f, held fixed from here on", N, v:getParam("gravity")))
  print(string.format("[tuning] gravity ranged from %.1f to %.1f (span %.1f) over this tuning session",
                       trainingGravityMin, trainingGravityMax, trainingGravityMax - trainingGravityMin))
end)

-- Lists this file's own v:addShortcut() bindings in the "Shortcuts" dock
-- panel.
v:setHelpText(
  "T: Start gravity tuning (adjusts gravity toward a 60s/42-beat target)\n" ..
  "G: Lock gravity at its current value and stop tuning"
)

-- Live gravity-slider tracking: v:getParam("gravity") can be dragged
-- while the sim runs, but DRIVE_TORQUE was computed from gravity ONCE,
-- above, and won't follow a later slider move on its own -- so gravity
-- changes are detected explicitly each frame and DRIVE_TORQUE + the
-- escapement motor are recomputed and reissued to match.
local lastGravity = v:getParam("gravity")

v:postSim(function(N)
  -- PERIODIC FULL GC: per-frame reads of physics state allocate small
  -- Lua userdata every frame. Nothing leaks (Lua's own GC reclaims it),
  -- but left to the default incremental pacing alone, process RSS still
  -- creeps up over time since incremental steps don't coalesce freed
  -- memory as well as a full collection does. A periodic full collect()
  -- keeps RSS flat for a cost that's negligible next to this file's
  -- actual per-frame physics cost.
  if N % 200 == 0 then
    collectgarbage("collect")
  end

  local curGravity = v:getParam("gravity")
  if curGravity ~= lastGravity then
    v.gravity = btVector3(0, -curGravity, 0)
    DRIVE_TORQUE = WEIGHT_M * curGravity * DRUM_R
    con0:enableAngularMotor(true, DRIVE_SIGN * 100, DRIVE_TORQUE)
    print(string.format("frame %d: gravity slider moved %.0f -> %.0f, DRIVE_TORQUE recomputed to %.1f", N, lastGravity, curGravity, DRIVE_TORQUE))
    lastGravity = curGravity
  end

  if DEBUG_PENETRATION then
    worstDistThisFrame = nil
    v:eachContact(trackWorstContactDist)
    if worstDistThisFrame ~= nil then
      if worstDistThisFrame < EMBED_WARN_THRESHOLD then
        --print(string.format("frame %d: PALLET/WHEEL PENETRATION -- dist=%.3f (threshold %.2f)", N, worstDistThisFrame, EMBED_WARN_THRESHOLD))
      end
      if worstOverallDist == nil or worstDistThisFrame < worstOverallDist then
        worstOverallDist = worstDistThisFrame
        worstOverallFrame = N
      end
    end
    if N % 500 == 0 and worstOverallDist ~= nil then
      --print(string.format("  [penetration summary @ frame %d] worst dist so far: %.3f at frame %d", N, worstOverallDist, worstOverallFrame))
    end
  end

  local wq = g2.trans:getRotation()
  local wqz, wqw = wq:getZ(), wq:getW()
  local wc, ws = wqw*wqw - wqz*wqz, 2*wqw*wqz
  local wdSin = ws*prevWheelC - wc*prevWheelS
  local wdCos = wc*prevWheelC + ws*prevWheelS
  local frameAngleDeg = math.deg(math.atan2(wdSin, wdCos))
  if math.abs(frameAngleDeg) > TOOTH_SKIP_THRESHOLD_DEG then
    print(string.format("frame %d: SUSPECTED TOOTH SKIP -- wheel moved %.2fdeg in one frame (threshold %.0fdeg)", N, frameAngleDeg, TOOTH_SKIP_THRESHOLD_DEG))
  end
  prevWheelC, prevWheelS = wc, ws

  local q = g2.trans:getRotation()
  local qz, qw = q:getZ(), q:getW()
  local c, s = qw*qw - qz*qz, 2*qw*qz
  local dSin = s*prevC - c*prevS
  local dCos = c*prevC + s*prevS
  if dCos > 0 then
    wheelTurn = wheelTurn + math.asin(math.max(-1, math.min(1, dSin)))
  end
  prevC, prevS = c, s

  weight.pos = btVector3(CORD_X,
                          WEIGHT_TOP_Y - math.abs(wheelTurn) * DRUM_R,
                          drum.pos.z)

  local a, b = trackGearA(), trackGearB()
  local slipDeg = math.deg(math.abs(b - (-GEAR_RATIO * a)))
  if slipDeg > GEAR_SLIP_LIMIT_DEG and not gearSlipWarned then
    print(string.format("frame %d: GEAR SLIP -- gearB is %.2f deg off expected (limit %.2f deg)", N, slipDeg, GEAR_SLIP_LIMIT_DEG))
    gearSlipWarned = true
  end
  local c2, d = trackGearC(), trackGearD()
  local slip2Deg = math.deg(math.abs(d - (-GEAR2_RATIO * c2)))
  if slip2Deg > GEAR2_SLIP_LIMIT_DEG and not gear2SlipWarned then
    print(string.format("frame %d: GEAR SLIP -- gearD is %.2f deg off expected (limit %.2f deg)", N, slip2Deg, GEAR2_SLIP_LIMIT_DEG))
    gear2SlipWarned = true
  end
  local e, f = trackGearE(), trackGearF()
  local slip3Deg = math.deg(math.abs(f - (-GEAR3_RATIO * e)))
  if slip3Deg > GEAR3_SLIP_LIMIT_DEG and not gear3SlipWarned then
    print(string.format("frame %d: GEAR SLIP -- hourWheel is %.2f deg off expected (limit %.2f deg)", N, slip3Deg, GEAR3_SLIP_LIMIT_DEG))
    gear3SlipWarned = true
  end
  if N % 100 == 0 then
    --print(string.format("frame %d: gearA=%.2f gearB=%.2f | gearC=%.2f gearD=%.2f | gearE=%.2f gearF=%.2f",
    --                   N, math.deg(a), math.deg(b), math.deg(c2), math.deg(d), math.deg(e), math.deg(f)))
  end

  local av = g1.body:getAngularVelocity().z
  local t = N * v.timeStep
  if (lastAngVel > 0 and av <= 0) or (lastAngVel < 0 and av >= 0) then
    local nowClock = v:getTime()
    local beatDurationSim = t - lastBeatTime
    local beatDurationReal = nowClock - lastBeatClock

    if beatDurationSim >= MIN_BEAT_DURATION_SIM then
      if beatCount > 0 then
        --print(string.format("t=%.2fs(sim): BEAT #%d -- %.3f sec(sim) / %.3f sec(real) since last beat", t, beatCount, beatDurationSim, beatDurationReal))
        print(string.format("BEAT #%d -- %.3f sec(real) since last beat",
                             beatCount, beatDurationReal))

        -- Alternate tick/tock by beat parity -- a real escapement makes
        -- two distinct sounds per full oscillation (pallet engaging one
        -- side, then the other), not the same sound twice.
        if beatCount % 2 == 0 then
          v:playSound(tickSoundId)
        else
          v:playSound(tockSoundId)
        end

        -- Block-level monitoring now runs continuously -- before 'T' is
        -- ever pressed, while training is active, and after 'G' locks
        -- it -- so you always see whether the current beat rate is
        -- within the deadband, not just while actively training.
        if beatCount >= CONTROL_WARMUP_BEATS then
          if blockStartClock == nil then
            blockStartClock = nowClock   -- this beat marks the start of a new BEATS_PER_BLOCK-beat stopwatch block
            blockBeatCount = 0
          end
          blockBeatCount = blockBeatCount + 1

          if blockBeatCount >= BEATS_PER_BLOCK then
            local blockElapsed = nowClock - blockStartClock
            blockStartClock = nil   -- next beat starts a fresh block
            blockBeatCount = 0

            local err = blockElapsed - TARGET_BLOCK_SECONDS
            if math.abs(err) <= BLOCK_ERROR_DEADBAND then
              print(string.format("  [beat control] %d beats took %.3fs (target %.1fs) err=%+.3fs -- within deadband (+/-%.1fs), no correction",
                                   BEATS_PER_BLOCK, blockElapsed, TARGET_BLOCK_SECONDS, err, BLOCK_ERROR_DEADBAND))
            elseif not training then
              -- Outside deadband, but training is off -- report the
              -- error for visibility without touching gravity.
              print(string.format("  [beat control] %d beats took %.3fs (target %.1fs) err=%+.3fs -- outside deadband (+/-%.1fs), but tuning is off, no change applied",
                                   BEATS_PER_BLOCK, blockElapsed, TARGET_BLOCK_SECONDS, err, BLOCK_ERROR_DEADBAND))
            else
              local step = BLOCK_GAIN * err
              step = math.max(-MAX_GRAVITY_STEP_PER_UPDATE, math.min(MAX_GRAVITY_STEP_PER_UPDATE, step))

              local curG = v:getParam("gravity")
              local newG = setParam("gravity", curG + step)   -- setParam() itself clamps to PARAM_INFO.gravity's [min,max]
              noteGravitySeen(newG)
              print(string.format("  [beat control] %d beats took %.3fs (target %.1fs) err=%+.3fs -> gravity %.1f -> %.1f",
                                   BEATS_PER_BLOCK, blockElapsed, TARGET_BLOCK_SECONDS, err, curG, newG))
            end
            -- Range-so-far tracking only means something during an
            -- active (or at least once-started) training session --
            -- trainingGravityMin/Max are nil until 'T' has been pressed
            -- at least once, so guard this line or it'll error before that.
            if training then
              print(string.format("  [beat control] gravity range so far this session: %.1f to %.1f (span %.1f)",
                                   trainingGravityMin, trainingGravityMax, trainingGravityMax - trainingGravityMin))
            end
          end
        end
      end
      lastBeatTime = t
      lastBeatClock = nowClock
      beatCount = beatCount + 1
    end
    -- else: recoil-driven crossing, too soon after the last true beat --
    -- ignored entirely. lastBeatTime/lastBeatClock are deliberately left
    -- untouched here, so the NEXT true beat's reported duration is still
    -- measured from the last TRUE beat, not truncated by this blip.
  end
  lastAngVel = av
end)

-- Camera commands, keeps things in view.
v.cam:setUpVector(btVector3(0,1,0), false)
v.cam:setHorizontalFieldOfView(0.0275)
v.cam.pos  = btVector3(0,0,15000)
v.cam.look = btVector3(0,395,0)

v.cam.focal_blur      = 0
v.cam.focal_aperture  = 5
v.cam.focal_point = btVector3(0,0,0)
