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
  gravity = { min = 200, max = 4000, step = 100,
              comment = "primary speed lever -- beat period scales as 1/sqrt(gravity), so 3x faster needs ~9x this value, not 3x." },
}

local function setParam(name, value)
  local info = PARAM_INFO[name]
  value = math.max(info.min, math.min(info.max, value))
  v:addParam(name, value, info.min, info.max, info.step, info.comment)
  return value
end

setParam("gravity", 1166)

v.gravity = btVector3(0, -v:getParam("gravity"), 0)
v.friction = 0.1
v:setErp(0.8)
v:setErp2(0.0)
v.timeStep = 1.0/50.0

-- Tick/tock sound effects, extracted from a clock-ticking recording.
-- loadSound() is safe to call even with no audio device present (returns
-- -1); playSound() on an invalid id is a silent no-op, so this degrades
-- gracefully on a machine/CI run with no audio hardware.
local tickSoundId = v:loadSound("../../../demo/sound/tick.wav")
local tockSoundId = v:loadSound("../../../demo/sound/tock.wav")

c = Cube(100,300,600,0) -- mass set to 0 (static, immovable)
c.pos = btVector3(0, 150, 0)
c.col = "#050"
c.friction = 0.1
c.body:setAngularVelocity(btVector3(0,0,0))
v:add(c)

-- Palette and Pendulum -- swings about the X axis (not Z), sweeping
-- through Y and Z as it moves, not just XY. Over a generous +-25deg
-- swing it sweeps x: -93.4 to 95.6, y: 9.1 to 177.3, z: 248.2 to 403.4
-- in world space -- every other component below is positioned to clear
-- z=403.4 with margin.
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
-- z=g2.z+130 to clear the pendulum's swept z-max of 403.4.
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
-- Motor starts at ZERO torque, not DRIVE_TORQUE -- the escapement must
-- not tick during the gear spin-up animation below. Full torque is
-- applied once that animation completes (see the postSim block).
con0:enableAngularMotor(true, DRIVE_SIGN * 100, 0)

-- ---------------------------------------------------------------------
-- Gear train + hands: second, minute, and hour, all driven off one gear
-- train (second hand welded directly to g2, minute hand welded to
-- gearD -- 60:1 down from g2, hour hand welded to hourWheel -- 720:1
-- down, via the idler-corrected coaxial wheel). SAFETY: each stage's z
-- sits further out than the last, clear of the pendulum's z=403.4 max.
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
-- preserving the gearC-gearD mesh distance, while opening a gap between
-- gearE and hourWheel for the idler. The gearE-to-hourWheel distance
-- must stay within 144.45 (rpE+rpHour, below which they touch directly,
-- bypassing the idler) to 166.67 (beyond which the idler can't reach
-- both); -92 gives comfortable margin from both edges (156.96).
local GEARD_ROTATION_DEG = -92
-- Rotating gearD's POSITION this far around gearC also requires
-- rotating its TOOTH PHASE by the same amount, or its teeth no longer
-- line up with the new contact point relative to gearC.
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

-- BASELINE+RATIO FRAMEWORK (ported from N2/E3, validated identically):
-- GEARD_BASELINE (3.58) is DEFINED to be "gearD's zero" -- not 12
-- o'clock, just wherever the gear itself properly meshes with gearC
-- (brute-force polygon-overlap confirmed, near-zero interpenetration
-- -- 0.041, pure discretization noise relative to gearD's actual
-- size). minuteHand is separately welded with a FIXED offset so it
-- reads exactly 12:00 AT that reference (see MINUTE_HAND_OFFSET
-- below) -- and because every downstream angle (idler, hourWheel,
-- both hands) is a fixed ratio away from gearD's rotation FROM ITS
-- OWN BASELINE, rotating gearD by theta degrees from baseline rotates
-- everything else by the correct, proportional amount too, and the
-- mesh never falls out of validity. theta = -totalMinutes*6 (negative
-- because increasing time needs decreasing raw, this file's
-- "raw=90-clockDeg" convention), then snapped to the nearest multiple
-- of gearD's own 3.75deg tooth pitch so the target lands on an
-- ACTUALLY validated meshing position. This whole approach (and the
-- validated linear ratio formulas used below for idlerGear/hourWheel)
-- replaces the file's original independent-rounding + unvalidated /12
-- ratio for hourWheel, which never actually checked whether the mesh
-- was geometrically valid -- confirmed it wasn't (real tooth
-- interpenetration, on top of never starting the hands at 12:00
-- either).
GEARD_BASELINE = 3.58   -- global -- gearD's own validated meshing reference; "gearD's zero", not 12 o'clock
local t = os.date("*t")
local hour12 = t.hour % 12
local totalMinutes = hour12 * 60 + (t.min + t.sec / 60)
local thetaIdeal = -totalMinutes * 6
local k = math.floor(thetaIdeal / 3.75 + 0.5)
GEARD_RAW_TARGET = GEARD_BASELINE + k * 3.75   -- global -- the FULL, unwrapped total (can be large), read by the sweep animation below
print(string.format("OS CLOCK SYNC: os.date=%02d:%02d:%02d -> totalMinutes=%.4f -> GEARD_RAW_TARGET=%.3f",
                     t.hour, t.min, t.sec, totalMinutes, GEARD_RAW_TARGET))

-- Starts at gearD's own baseline reference -- kinematic +
-- no-contact-response for the sweep below, animated up to
-- GEARD_RAW_TARGET.
GEARD_RAW = GEARD_BASELINE   -- global -- current angle during the sweep, read by gearE/minuteHand below and updated each frame by the sweep
gearD.body:setCollisionFlags(2 + 4)   -- CF_KINEMATIC_OBJECT | CF_NO_CONTACT_RESPONSE
gearD.body:setActivationState(4)      -- DISABLE_DEACTIVATION
gearD.body:setMotionState(btDefaultMotionState(
  btTransform(btQuaternion(btVector3(0,0,1), math.rad(GEARD_RAW)), gearD.pos)))

local gearD_con = btHingeConstraint(gearD_anchor.body, gearD.body, btVector3(0,0,0), btVector3(0,0,0), btVector3(0,0,1), btVector3(0,0,1))
v:addConstraint(gearD_con)

-- Minute hand: welded directly onto gearD's own arbor, 60:1 down from
-- g2. Direction matches g2/the second hand (the two mesh reversals
-- gearA->gearB and gearC->gearD cancel out). Dimensions (75, 8, 4, 30,
-- tail_w=29.500) follow the 60/75/90 hour/minute/second length pattern
-- and are mass-balanced (polygon centroid at the pivot, Cx=0).
local MINUTE_HAND_Z = gearD.pos.z + 65
minuteHand = OpenSCAD(counterbalanced_hand_sdl(75, 8, 4, 30, 29.500, 5, 0), 0.2, true)
minuteHand.col = "#e60000"
minuteHand.pos = btVector3(gearD.pos.x, gearD.pos.y, MINUTE_HAND_Z)
v:add(minuteHand)

-- Matches gearD's raw angle directly, WITH a fixed offset baked in so
-- the hand reads exactly 12:00 at gearD's own baseline (see
-- MINUTE_HAND_OFFSET below). Kinematic + no-contact-response for the
-- sweep -- confirmed (elsewhere in this project) that leaving it
-- dynamic while gearD is kinematic lets it sag under gravity (the weld
-- isn't stiff enough to resist gravity while the gear train sits
-- unloaded).
MINUTE_HAND_OFFSET = 90 - GEARD_BASELINE   -- global -- fixed once; minuteHand's raw angle is always gearD's raw angle + this constant, at ANY gearD angle, not just baseline
minuteHand.body:setMotionState(btDefaultMotionState(
  btTransform(btQuaternion(btVector3(0,0,1), math.rad(GEARD_RAW + MINUTE_HAND_OFFSET)), minuteHand.pos)))
minuteHand.body:setCollisionFlags(2 + 4)
minuteHand.body:setActivationState(4)

-- frameInGearD's rotation carries MINUTE_HAND_OFFSET (not identity) --
-- this is the PERMANENT relationship the constraint solver enforces
-- once normal physics takes over after the sweep, so it must match
-- exactly what minuteHand was just set to above.
local minuteHand_frameInGearD = btTransform(btQuaternion(btVector3(0,0,1), math.rad(MINUTE_HAND_OFFSET)), btVector3(0, 0, MINUTE_HAND_Z - gearD.pos.z))
local minuteHand_frameInHand = btTransform(btQuaternion(0,0,0,1), btVector3(0, 0, 0))
local minuteHand_weld = btGeneric6DofConstraint(gearD.body, minuteHand.body, minuteHand_frameInGearD, minuteHand_frameInHand, true)
minuteHand_weld:setLinearLowerLimit(btVector3(0,0,0))
minuteHand_weld:setLinearUpperLimit(btVector3(0,0,0))
minuteHand_weld:setLimit(3, 0, 0)
minuteHand_weld:setLimit(4, 0, 0)
minuteHand_weld:setLimit(5, 0, 0)
v:addConstraint(minuteHand_weld)

local GEAR3_Z = g2.pos.z + 235

local sdlE, rpE = involute_gear_sdl(8, GEAR_MODULE, GEAR_PRESSURE, GEAR_TH)
gearE = OpenSCAD(sdlE, 4, true)
gearE.col = "#ccc"
gearE.pos = btVector3(gearD.pos.x, gearD.pos.y, GEAR3_Z)
gearE.friction = 0.1
v:add(gearE)

-- Matches gearD's raw angle directly, same reasoning as minuteHand.
-- Kinematic + no-contact-response for the sweep below (needed now --
-- gearE didn't have this before, since there was no sweep to hold it
-- kinematic through; without it, gearE would sag under gravity while
-- gearD is held kinematic above it).
gearE.body:setMotionState(btDefaultMotionState(
  btTransform(btQuaternion(btVector3(0,0,1), math.rad(GEARD_RAW)), gearE.pos)))
gearE.body:setCollisionFlags(2 + 4)
gearE.body:setActivationState(4)

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

-- Idler gear: 8 teeth, adds a fourth mesh reversal so hourWheel rotates
-- the same direction as g2, matching the second hand. Position solved
-- via two-circle intersection, adapting automatically if
-- GEARD_ROTATION_DEG above changes.
local sdlIdler, rpIdler = involute_gear_sdl(8, GEAR_MODULE, GEAR_PRESSURE, GEAR_TH)
local rpHour = GEAR_MODULE * 96 / 2 -- computed early, needed before the hourWheel SDL generation below
-- IDLER_BACKLASH: this file had NO backlash at all on either idler
-- mesh (matching E3's original problem exactly, since N7 and E3 share
-- this identical downstream gear train) -- confirmed at zero backlash,
-- gearE-idler's valid window was only 0.22deg and idler-hourWheel's
-- was a razor-thin 0.02deg. Fixed the same way, with the same
-- validated values (confirmed directly against N7's own real
-- positions, not just assumed to match E3's): 0.3 on idler_r1
-- (gearE-idler's window stays solid, 1.44-1.56deg) and 1.5 on idler_r2
-- (checked BOTH window width -- widens to 0.50deg -- AND actual tooth
-- engagement depth together, landing at 88% coverage across a full
-- tooth pitch, not just "wider is better").
local idler_r1 = rpE + rpIdler + 0.3
local idler_r2 = rpIdler + rpHour + 1.5
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

-- Tracks gearE via a validated linear formula -- idler_raw = 134.61 -
-- gearE_raw -- derived from the single brute-force-confirmed reference
-- point (gearE_raw=3.58 -> idler_raw=140.61, near-zero overlap: 0.0002,
-- discretization noise) combined with the theoretically-correct -1x
-- ratio (equal 8-tooth external gears), re-validated at six other,
-- very different gearE_raw values (up to +/-360deg away) -- all
-- confirmed near-zero, not just the one calibration point. (These are
-- E3's numbers, not independently re-derived for N7 -- confirmed
-- directly that N7's gearC/gearD/gearE/idler/hourWheel positions are
-- bit-for-bit identical to E3's, since N7 and E3 share this exact
-- downstream gear train unchanged.)
idlerGear.body:setCollisionFlags(2 + 4)
idlerGear.body:setActivationState(4)
idlerGear.body:setMotionState(btDefaultMotionState(
  btTransform(btQuaternion(btVector3(0,0,1), math.rad(134.61 - GEARD_RAW)), idlerGear.pos)))

local idler_con = btHingeConstraint(idler_anchor.body, idlerGear.body, btVector3(0,0,0), btVector3(0,0,0), btVector3(0,0,1), btVector3(0,0,1))
v:addConstraint(idler_con)

local sdlHour, _ = involute_gear_hollow_sdl(96, GEAR_MODULE, GEAR_PRESSURE, GEAR_TH, 40, 360/96/2)
local HOUR_WHEEL_Z = gearE.pos.z -- must match gearE's z -- meshing pairs need to share z to actually touch
hourWheel = OpenSCAD(sdlHour, 1.5, true)
hourWheel.col = "#B36430"
hourWheel.pos = btVector3(g2.pos.x, g2.pos.y, HOUR_WHEEL_Z) -- COAXIAL: same x,y as g2 itself
hourWheel.friction = 0.1
v:add(hourWheel)

-- Tracks idler via a validated linear formula -- hourWheel_raw =
-- -idler_raw/12 + 78.1092 -- derived from the brute-force-confirmed
-- reference point (idler_raw=140.61 -> hourWheel_raw=129.64,
-- near-zero overlap: 0.0073, discretization noise) combined with the
-- theoretically-correct -1/12 ratio (8-tooth idler : 96-tooth
-- hourWheel, external mesh, reversed direction), re-validated at six
-- other very different idler_raw values -- all confirmed near-zero.
hourWheel.body:setCollisionFlags(2 + 4)
hourWheel.body:setActivationState(4)
HOUR_WHEEL_RAW = -(134.61 - GEARD_RAW)/12 + 78.1092   -- global -- current angle during the sweep, updated each frame; also read by hourHand below
hourWheel.body:setMotionState(btDefaultMotionState(
  btTransform(btQuaternion(btVector3(0,0,1), math.rad(HOUR_WHEEL_RAW)), hourWheel.pos)))

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

-- Same offset-weld approach as minuteHand -- HOUR_HAND_OFFSET is fixed
-- once here, using HOUR_WHEEL_RAW's value right now (still at its
-- baseline setting -- the sweep hasn't started moving it yet).
HOUR_HAND_OFFSET = 90 - HOUR_WHEEL_RAW   -- global -- fixed once; hourHand's raw angle is always hourWheel's raw angle + this constant, at ANY hourWheel angle
hourHand.body:setMotionState(btDefaultMotionState(
  btTransform(btQuaternion(btVector3(0,0,1), math.rad(HOUR_WHEEL_RAW + HOUR_HAND_OFFSET)), hourHand.pos)))
hourHand.body:setCollisionFlags(2 + 4)
hourHand.body:setActivationState(4)

local hourHand_frameInHourWheel = btTransform(btQuaternion(btVector3(0,0,1), math.rad(HOUR_HAND_OFFSET)), btVector3(0, 0, HOUR_HAND_Z - hourWheel.pos.z))
local hourHand_frameInHand = btTransform(btQuaternion(0,0,0,1), btVector3(0, 0, 0))
local hourHand_weld = btGeneric6DofConstraint(hourWheel.body, hourHand.body, hourHand_frameInHourWheel, hourHand_frameInHand, true)
hourHand_weld:setLinearLowerLimit(btVector3(0,0,0))
hourHand_weld:setLinearUpperLimit(btVector3(0,0,0))
hourHand_weld:setLimit(3, 0, 0)
hourHand_weld:setLimit(4, 0, 0)
hourHand_weld:setLimit(5, 0, 0)
v:addConstraint(hourHand_weld)

local wheelTurn, prevC, prevS = 0, 1, 0
local lastAngVel = 0
local lastBeatTime = 0
-- v:getTime(): bpp's own wall-clock timer (Viewer::getTime(), backed by
-- a QElapsedTimer), used here for real beat-duration measurement.
soundMuted = false        -- true after an 'S' press, until the next 'S' press toggles it back (global to avoid postSim's upvalue ceiling)
local lastBeatClock = v:getTime()
local simClockStart = v:getTime()
local osStartCapture = os.date("*t")
local osStartSeconds = osStartCapture.hour*3600 + osStartCapture.min*60 + osStartCapture.sec
local beatCount = 0

-- RECOIL FILTER: the escapement can briefly reverse right after a true
-- beat, crossing the pendulum's zero-angular-velocity threshold again
-- almost immediately -- a naive zero-crossing counter would count that
-- as an extra beat. MIN_BEAT_DURATION_SIM rejects any crossing that
-- comes in under this many sim-seconds after the last counted beat.
local MIN_BEAT_DURATION_SIM = 0.1

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
-- BEATS_PER_BLOCK=42: this wheel has 21 teeth, x 2 beats/tooth = one
-- full escape-wheel revolution. TARGET_BLOCK_SECONDS=60.0 is fixed: the
-- second hand is welded directly to the escape wheel with no reduction,
-- so one wheel revolution IS one second-hand rotation, which must
-- complete in exactly 60 real seconds by definition of what a second
-- hand is -- true regardless of tooth count.
local BEATS_PER_BLOCK          = 42     -- 21 teeth x 2 beats/tooth = one full escape-wheel revolution
local TARGET_BLOCK_SECONDS     = 60.0   -- fixed: one wheel revolution = one second-hand rotation = 60 real seconds, by definition
--local BLOCK_ERROR_DEADBAND     = 0.05 * BEATS_PER_BLOCK   -- block |error| (seconds) must exceed this before any correction happens (= 0.05s/beat-equivalent)
local BLOCK_ERROR_DEADBAND     = 0.0125 * BEATS_PER_BLOCK   -- block |error| (seconds) must exceed this before any correction happens (= 0.05s/beat-equivalent)
local BLOCK_GAIN               = 300 / BEATS_PER_BLOCK    -- gravity units per second of block error, before clamping
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
-- ---------------------------------------------------------------------
local training = false          -- true only between a 'T' press and the next 'G' press
local trainingGravityMin = nil  -- lowest gravity value actually seen during the current/most recent training session
local trainingGravityMax = nil  -- highest gravity value actually seen during the current/most recent training session

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
  print(string.format("[tuning] gravity ranged from %.1f to %.1f (span %.1f) over this training session",
                       trainingGravityMin, trainingGravityMax, trainingGravityMax - trainingGravityMin))
end)

v:addShortcut("S", function(N)
  soundMuted = not soundMuted
  print(string.format("[sound] beat sound %s", soundMuted and "MUTED" or "UNMUTED"))
end)

v:setHelpText(
  "T: Start gravity training (adjusts gravity toward a 60s/" .. BEATS_PER_BLOCK .. "-beat target)\n" ..
  "G: Lock gravity at its current value and stop training\n" ..
  "S: Toggle beat sound (tick/tock) on/off"
)

-- Live gravity-slider tracking: v:getParam("gravity") can be dragged
-- while the sim runs, but DRIVE_TORQUE was computed from gravity ONCE,
-- above, and won't follow a later slider move on its own -- so gravity
-- changes are detected explicitly each frame and DRIVE_TORQUE + the
-- escapement motor are recomputed and reissued to match.
local lastGravity = v:getParam("gravity")

-- ---------------------------------------------------------------------
-- HAND SWEEP: gearD is kinematically eased from GEARD_BASELINE (its
-- construction-time pose above) to GEARD_RAW_TARGET (the real current
-- time) over SWEEP_SECONDS. gearE, minuteHand, idlerGear, hourWheel,
-- hourHand are all re-derived from gearD's CURRENT (in-progress) angle
-- every frame using the same validated linear formulas used at
-- construction time -- not independently animated -- so they stay
-- correctly, continuously meshed throughout the whole sweep. Since
-- this is pure kinematic/formula-driven motion (not physics
-- propagating contact forces through the train), there's no physical
-- speed limit -- a fixed, short duration works regardless of how much
-- rotation GEARD_RAW_TARGET represents. This mirrors N2/E3 exactly;
-- N7's pendulum/escapement side is untouched by any of this -- it's
-- gated off entirely (zero motor torque, see above) until the sweep
-- finishes, then released, same as E3 (no evidence N7's pendulum needs
-- N2's torque ramp -- it's a well-tested, stable escapement already,
-- confirmed elsewhere in this project at 2.55% normalized deviation).
-- ---------------------------------------------------------------------
local SWEEP_SECONDS = 5.0
local GEARD_RAW_START = GEARD_BASELINE
local sweepT0 = nil
local sweepDone = false

local function spinUpEase(frac)
  return frac * frac * (3 - 2 * frac)
end

local function applySweepAngles(gearDRawNow)
  local quatD = btQuaternion(btVector3(0,0,1), math.rad(gearDRawNow))
  gearD.body:setMotionState(btDefaultMotionState(btTransform(quatD, gearD.pos)))
  local quatMinuteHand = btQuaternion(btVector3(0,0,1), math.rad(gearDRawNow + MINUTE_HAND_OFFSET))
  minuteHand.body:setMotionState(btDefaultMotionState(btTransform(quatMinuteHand, minuteHand.pos)))
  gearE.body:setMotionState(btDefaultMotionState(btTransform(quatD, gearE.pos)))

  local idlerRawNow = 134.61 - gearDRawNow
  local quatI = btQuaternion(btVector3(0,0,1), math.rad(idlerRawNow))
  idlerGear.body:setMotionState(btDefaultMotionState(btTransform(quatI, idlerGear.pos)))

  local hourWheelRawNow = -idlerRawNow/12 + 78.1092
  local quatH = btQuaternion(btVector3(0,0,1), math.rad(hourWheelRawNow))
  hourWheel.body:setMotionState(btDefaultMotionState(btTransform(quatH, hourWheel.pos)))
  local quatHourHand = btQuaternion(btVector3(0,0,1), math.rad(hourWheelRawNow + HOUR_HAND_OFFSET))
  hourHand.body:setMotionState(btDefaultMotionState(btTransform(quatHourHand, hourHand.pos)))

  return hourWheelRawNow
end

v:postSim(function(N)
  if not sweepDone then
    if sweepT0 == nil then
      sweepT0 = v:getTime()
    end
    local elapsed = v:getTime() - sweepT0
    if elapsed >= SWEEP_SECONDS then
      GEARD_RAW = GEARD_RAW_TARGET
      HOUR_WHEEL_RAW = applySweepAngles(GEARD_RAW_TARGET)
      gearD.body:setCollisionFlags(0)
      gearD.body:setActivationState(1)
      minuteHand.body:setCollisionFlags(0)
      minuteHand.body:setActivationState(1)
      gearE.body:setCollisionFlags(0)
      gearE.body:setActivationState(1)
      idlerGear.body:setCollisionFlags(0)
      idlerGear.body:setActivationState(1)
      hourWheel.body:setCollisionFlags(0)
      hourWheel.body:setActivationState(1)
      hourHand.body:setCollisionFlags(0)
      hourHand.body:setActivationState(1)
      con0:enableAngularMotor(true, DRIVE_SIGN * 100, DRIVE_TORQUE)   -- NOW start driving the escapement -- not before
      -- Fresh baseline for beat detection -- otherwise the first real
      -- beat's reported duration would span the whole sweep window
      -- instead of being measured from when the escapement actually
      -- starts.
      lastAngVel = g1.body:getAngularVelocity().x
      lastBeatTime = N * v.timeStep
      lastBeatClock = v:getTime()
      sweepDone = true
      print(string.format("frame %d: hand sweep complete (%.1fs) -- whole minute/hour train now driven by normal physics", N, elapsed))
    else
      local frac = spinUpEase(elapsed / SWEEP_SECONDS)
      GEARD_RAW = GEARD_RAW_START + (GEARD_RAW_TARGET - GEARD_RAW_START) * frac
      applySweepAngles(GEARD_RAW)
    end
    return   -- nothing below this point should run until the sweep completes
  end

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

  local av = g1.body:getAngularVelocity().x
  local t = N * v.timeStep
  if (lastAngVel > 0 and av <= 0) or (lastAngVel < 0 and av >= 0) then
    local nowClock = v:getTime()
    local beatDurationSim = t - lastBeatTime
    local beatDurationReal = nowClock - lastBeatClock

    if beatDurationSim >= MIN_BEAT_DURATION_SIM then
      if beatCount > 0 then
        print(string.format("BEAT #%d -- %.3f sec(real) since last beat",
                             beatCount, beatDurationReal))

        -- Alternate tick/tock by beat parity -- a real escapement makes
        -- two distinct sounds per full oscillation (pallet engaging one
        -- side, then the other), not the same sound twice.
        if not soundMuted then
          if beatCount % 2 == 0 then
            v:playSound(tickSoundId)
          else
            v:playSound(tockSoundId)
          end
        end

        -- Block-level monitoring now runs continuously -- before 'T' is
        -- ever pressed, while training is active, and after 'G' locks
        -- it -- so you always see whether the current beat rate is
        -- within the deadband, not just while actively training.
        if beatCount >= CONTROL_WARMUP_BEATS then
          if blockStartClock == nil then
            -- FIX (off-by-one): use lastBeatClock (the previous beat's
            -- timestamp, not yet overwritten to nowClock this frame -- see
            -- below) so blockElapsed spans exactly BEATS_PER_BLOCK real
            -- intervals, not BEATS_PER_BLOCK-1. Ported from the same fix
            -- verified in N2_Clock6.lua.
            blockStartClock = lastBeatClock
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
              print(string.format("  [beat control] %d beats took %.3fs (target %.1fs) err=%+.3fs -- outside deadband (+/-%.1fs), but training is off, no change applied",
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

            -- [hand check] -- decode each hand's ACTUAL current angle back
            -- into an indicated time and compare directly against the OS
            -- clock, independently for each hand. 90deg = 12 o'clock in
            -- this codebase's convention; angle decreases clockwise.
            local mq = minuteHand.trans:getRotation()
            local mAngle = math.deg(2*math.atan2(mq:getZ(), mq:getW()))
            local minuteFromMinuteHand = ((90 - mAngle) / 6) % 60

            local hq = hourHand.trans:getRotation()
            local hAngle = math.deg(2*math.atan2(hq:getZ(), hq:getW()))
            local hoursFrac = ((90 - hAngle) / 30) % 12
            local hourFromHourHand = math.floor(hoursFrac)
            local minuteFromHourHand = (hoursFrac - hourFromHourHand) * 60

            local osNow = os.date("*t")
            local monotonicSeconds = (osStartSeconds + (v:getTime() - simClockStart)) % 86400
            local monoH = math.floor(monotonicSeconds / 3600)
            local monoM = math.floor((monotonicSeconds % 3600) / 60)
            local monoS = monotonicSeconds % 60
            print(string.format("  [hand check] OS time=%02d:%02d:%02d  |  monotonic time=%02d:%02d:%05.2f  |  hourHand indicates %d:%04.1f  |  minuteHand indicates :%04.1f",
                                 osNow.hour, osNow.min, osNow.sec,
                                 monoH, monoM, monoS,
                                 hourFromHourHand, minuteFromHourHand,
                                 minuteFromMinuteHand))
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
v.cam:setHorizontalFieldOfView(0.0175)
v.cam.pos  = btVector3(0,0,15000)
v.cam.look = btVector3(0,95,100)

v.cam.focal_blur      = 0
v.cam.focal_aperture  = 5
v.cam.focal_point = btVector3(0,0,0)
