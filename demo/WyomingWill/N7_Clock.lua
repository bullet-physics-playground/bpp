-- =======================================================================
-- CONTROL PANEL -- live GUI gravity slider via bpp's own v:addParam /
-- v:getParam, not a plain Lua variable. This can genuinely be dragged
-- while the simulation is running. Only gravity is exposed as a slider
-- in this file; everything else below stays a fixed constant.
--
-- Gravity needs extra care: DRIVE_TORQUE (further down this file) is
-- computed FROM gravity, once, at that point in the script -- it will
-- NOT update itself just because the gravity slider moved later. The
-- postSim block near the bottom of this file explicitly watches for
-- gravity changes and recomputes + reapplies DRIVE_TORQUE and the
-- escapement's motor call whenever it does.
-- =======================================================================
local PARAM_INFO = {
  gravity = { min = 200, max = 20000, step = 100,
              comment = "primary speed lever -- beat period scales as 1/sqrt(gravity), so 3x faster needs ~9x this value, not 3x." },
}

local function setParam(name, value)
  local info = PARAM_INFO[name]
  value = math.max(info.min, math.min(info.max, value))
  v:addParam(name, value, info.min, info.max, info.step, info.comment)
  return value
end

setParam("gravity", 5000)

v.gravity = btVector3(0, -v:getParam("gravity"), 0)
v.friction = 0.1
v:setErp(0.8)
v:setErp2(0.0)
v.timeStep = 1.0/50.0

c = Cube(100,300,600,0) -- mass set to 0 (static, immovable)
c.pos = btVector3(0, 150, 0)
c.col = "#050"
c.friction = 0.1
c.body:setAngularVelocity(btVector3(0,0,0))
v:add(c)

-- Palette and Pendulum -- swings about the X axis (not Z), meaning it
-- sweeps through Y AND Z as it moves, not just XY. Verified numerically:
-- over a generous +-25deg swing (observed oscillation is roughly -13 to
-- +11deg, so this has real margin), it sweeps x: -93.4 to 95.6,
-- y: 9.1 to 177.3, z: 248.2 to 403.4 in world space. Every other
-- component below is positioned to clear z=403.4 with margin -- this is
-- the critical safety constraint for this whole file.
g1 = Mesh("demo/mesh/WMS_N7_Pend.stl", 30, false)
g1.col = "#fa0"
g1.pos = btVector3(-40,110,331)
g1.friction = 0.1
g1.restitution = 0.0
v:add(g1)
pivot0 = btVector3(-40,14,331)
axis0 = btVector3(1,0,0)
pivot1 = btVector3(0,54,0)
axis1 = btVector3(1,0,0)

con1 = btHingeConstraint(
  c.body, g1.body, pivot0, pivot1, axis0, axis1)
v:addConstraint(con1)

-- Escapement Wheel -- hinged on Z, driven by the drum/weight below.
g2 = Mesh("demo/mesh/WMS_N7_Wheel.stl", 100, false)
g2.col = "#b00"
g2.pos = btVector3(0,163,304)
g2.friction = 0.1
g2.restitution = 0.0
g2.body:setLinearFactor(btVector3(0,0,0));
v:add(g2)

pivot0 = btVector3(0,13,304)
axis0 = btVector3(0,0,1)
pivot1 = btVector3(0,0,0)
axis1 = btVector3(0,0,1)

con0 = btHingeConstraint(
  c.body, g2.body, pivot0, pivot1, axis0, axis1)
v:addConstraint(con0)

-- ---------------------------------------------------------------------
-- Winding drum + weight, welded to g2's own arbor -- SAFETY: pushed to
-- z=g2.z+130 (=434) to clear the pendulum's swept z-max of 403.4 with
-- margin. The drum's own x/y footprint (roughly x:-40..40, y:123..203)
-- also clears the pendulum's swept x/y range.
-- ---------------------------------------------------------------------
local DRUM_R  = 40
local DRUM_TH = 15
local WEIGHT_M = 0.11
local WEIGHT_R, WEIGHT_H = 22, 80
local DRIVE_SIGN = 1 -- best-attempt sign for clockwise escape-wheel rotation, unconfirmed visually -- flip to -1 if it renders backwards.

local DRUM_Z_EXTRA = 130 -- SAFETY: keeps the drum 25 units clear of gearA and outside the pendulum's swept volume.
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
-- Gear train + hands (second, hour -- no minute). SAFETY: each stage's
-- z sits further out than the last, all comfortably clear of the
-- pendulum's z=403.4 max reach.
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

local GEAR_Z = g2.pos.z + 155 -- SAFETY: 25 units clear of the drum (z=434).

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

local SECOND_HAND_Z = g2.pos.z + 253 -- SAFETY: comfortably clear of both the pendulum's swept z-max and gearA.
secondHand = OpenSCAD(counterbalanced_hand_sdl(90, 6, 3, 30, 33.180, 5, 0), 0.2, true) -- tail_w recomputed from the actual polygon centroid, verified exact
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
local meshDist = rpA + rpB
local gearBx, gearBy, gearBz = gearA.pos.x + meshDist, gearA.pos.y, gearA.pos.z

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

local GEAR2_Z = g2.pos.z + 195

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

-- ADJUSTABLE: rotates gearD clockwise around gearC (negative = clockwise),
-- preserving the gearC-gearD mesh distance exactly, while opening a gap
-- between gearE and hourWheel for the idler. The gearE-to-hourWheel
-- distance must stay within the window 144.45 (rpE+rpHour, below which
-- they directly touch, bypassing the idler) to 166.67 (beyond which the
-- idler can't reach both). -85 to -100 degrees all land inside it; -92
-- gives comfortable margin from both edges (156.96).
local GEARD_ROTATION_DEG = -92
-- Critically, rotating gearD's POSITION this far around gearC also
-- requires rotating its TOOTH PHASE by the same amount -- otherwise its
-- teeth no longer line up with the new contact point relative to gearC,
-- causing genuine mesh interference.
local sdlD, rpD = involute_gear_sdl(96, GEAR_MODULE, GEAR_PRESSURE, GEAR_TH, 360/96/2 + GEARD_ROTATION_DEG)
local mesh2Dist = rpC + rpD
local gearD_origAngle = math.deg(math.atan2(0, mesh2Dist)) -- straight-line baseline (gearC.x+mesh2Dist, gearC.y unchanged) is atan2(0,mesh2Dist)=0deg
local gearD_radius = mesh2Dist
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

local gearD_con = btHingeConstraint(gearD_anchor.body, gearD.body, btVector3(0,0,0), btVector3(0,0,0), btVector3(0,0,1), btVector3(0,0,1))
v:addConstraint(gearD_con)

local GEAR3_Z = g2.pos.z + 235

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

-- Idler gear: 8 teeth (matching gearA/gearC/gearE's size), adds a
-- fourth mesh reversal so hourWheel rotates the same direction as g2
-- itself, matching the second hand (welded directly to g2). Position
-- solved via two-circle intersection, automatically adapting if
-- GEARD_ROTATION_DEG above changes.
local sdlIdler, rpIdler = involute_gear_sdl(8, GEAR_MODULE, GEAR_PRESSURE, GEAR_TH)
local rpHour = GEAR_MODULE * 96 / 2 -- computed early, needed before the hourWheel SDL generation below
local idler_r1 = rpE + rpIdler
local idler_r2 = rpIdler + rpHour
local idler_dx, idler_dy = g2.pos.x - gearE.pos.x, g2.pos.y - gearE.pos.y
local idler_d = math.sqrt(idler_dx^2 + idler_dy^2)
assert(idler_d > rpE + rpHour, "GEARD_ROTATION_DEG has rotated gearD too far -- gearE and hourWheel are now closer than rpE+rpHour and directly overlap each other, bypassing the idler entirely. Increase the magnitude (less rotation).")
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

local sdlHour, _ = involute_gear_hollow_sdl(96, GEAR_MODULE, GEAR_PRESSURE, GEAR_TH, 40, 360/96/2)
local HOUR_WHEEL_Z = gearE.pos.z -- must match gearE's z -- meshing pairs need to share z to actually touch
hourWheel = OpenSCAD(sdlHour, 1.5, true)
hourWheel.col = "#B36430"
hourWheel.pos = btVector3(g2.pos.x, g2.pos.y, HOUR_WHEEL_Z) -- COAXIAL: same x,y as g2 itself
hourWheel.friction = 0.1
v:add(hourWheel)

-- Hour hand starts at the current real-world hour, not zero. Rotating
-- hourWheel itself (not the hand) so the weld below just rigidly
-- carries it -- must happen before its hinge is created, rounded to
-- the nearest tooth pitch (360/96=3.75deg) so it stays in phase with
-- gearE (via the idler). Reference angle unverified visually.
do
  local t = os.date("*t")
  local hour12 = t.hour % 12
  local hourDeg = (hour12 + t.min/60) * 30
  local pitch = 360/96
  local roundedDeg = math.floor(hourDeg/pitch + 0.5) * pitch
  local quat = btQuaternion(btVector3(0,0,1), math.rad(90 - roundedDeg))
  hourWheel.body:setMotionState(btDefaultMotionState(btTransform(quat, hourWheel.pos)))
end

-- COAXIAL HINGE: shares g2's own (x,y) pivot exactly, at hourWheel's
-- own z -- rotates independently of g2 at its own much slower rate
-- while sharing the same rotation axis in space.
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
-- Diagnostics: general cross-object penetration (checks ALL pairs, not
-- just pallet/wheel, given the collision-risk concern for this
-- specific layout), plus beat measurement.
-- ---------------------------------------------------------------------
local EMBED_WARN_THRESHOLD = -1.0
local worstOverallDist = nil
local worstOverallFrame = nil
local worstOverallPair = nil

local wheelTurn, prevC, prevS = 0, 1, 0
local lastAngVel = 0
local lastBeatTime = 0
local beatCount = 0

-- Live gravity-slider tracking: v:getParam("gravity") can be dragged
-- while the sim runs, but DRIVE_TORQUE was computed from gravity ONCE,
-- above, and won't follow a later slider move on its own -- so gravity
-- changes are detected explicitly each frame and DRIVE_TORQUE + the
-- escapement motor are recomputed and reissued to match.
local lastGravity = v:getParam("gravity")

v:postSim(function(N)
  local curGravity = v:getParam("gravity")
  if curGravity ~= lastGravity then
    v.gravity = btVector3(0, -curGravity, 0)
    DRIVE_TORQUE = WEIGHT_M * curGravity * DRUM_R
    con0:enableAngularMotor(true, DRIVE_SIGN * 100, DRIVE_TORQUE)
    print(string.format("frame %d: gravity slider moved %.0f -> %.0f, DRIVE_TORQUE recomputed to %.1f", N, lastGravity, curGravity, DRIVE_TORQUE))
    lastGravity = curGravity
  end

  local q = g2.trans:getRotation()
  local qz, qw = q:getZ(), q:getW()
  local c, s = qw*qw - qz*qz, 2*qw*qz
  local dSin = s*prevC - c*prevS
  local dCos = c*prevC + s*prevS
  if dCos > 0 then
    wheelTurn = wheelTurn + math.asin(math.max(-1, math.min(1, dSin)))
  end
  prevC, prevS = c, s

  -- the cord pays out: the weight drops by r * turn.
  weight.pos = btVector3(CORD_X,
                          WEIGHT_TOP_Y - math.abs(wheelTurn) * DRUM_R,
                          drum.pos.z)

  v:eachContact(function(oa, ob, px, py, pz, nx, ny, nz, dist, impulse)
    if dist < EMBED_WARN_THRESHOLD then
      if worstOverallDist == nil or dist < worstOverallDist then
        worstOverallDist = dist
        worstOverallFrame = N
      end
      if dist < -3 then
        print(string.format("frame %d: DEEP PENETRATION -- dist=%.3f", N, dist))
      end
    end
  end)
  if N % 500 == 0 and worstOverallDist ~= nil then
    print(string.format("  [penetration summary @ frame %d] worst dist so far: %.3f at frame %d", N, worstOverallDist, worstOverallFrame))
  end

  local av = g1.body:getAngularVelocity().x
  local t = N * v.timeStep
  if (lastAngVel > 0 and av <= 0) or (lastAngVel < 0 and av >= 0) then
    if beatCount > 0 then
      print(string.format("t=%.2fs: BEAT #%d -- %.3f sec since last beat", t, beatCount, t - lastBeatTime))
    end
    lastBeatTime = t
    beatCount = beatCount + 1
  end
  lastAngVel = av
end)

-- Camera commands, keeps things in view.
v.cam:setUpVector(btVector3(0,1,0), false)
v.cam:setHorizontalFieldOfView(0.0175)
v.cam.pos  = btVector3(0,0,15000)
v.cam.look = btVector3(0,95,100)

v.cam.focal_blur      = 0
v.cam.focal_aperture  = 5
v.cam.focal_point = btVector3(0,0,0)
