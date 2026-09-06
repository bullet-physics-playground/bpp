
local common = require "common"
local colors = require "color"

-- =======================================================================
-- CONTROL PANEL -- a real, live GUI slider via bpp's own v:addParam /
-- v:getParam, not a plain Lua variable. This genuinely can be dragged
-- while the simulation is running.
--
-- Gravity is the one parameter in this file that needs extra care:
-- DRIVE_TORQUE (further down this file) is computed FROM gravity, once,
-- at that point in the script -- it will NOT update itself just because
-- the gravity slider moved later. The postSim block below explicitly
-- watches for gravity changes and recomputes + reapplies DRIVE_TORQUE
-- and the escapement's motor call whenever it does.
--
-- Every other former slider (friction, escapementFriction, erp,
-- maxSubSteps, fixedTimeStepDenom, depthDelta) is now a fixed constant
-- just below, at its last-tuned value.
-- =======================================================================
local PARAM_INFO = {
  gravity = { min = 200, max = 20000, step = 100,
              comment = "primary speed lever -- beat period scales as 1/sqrt(gravity), so 3x faster needs ~9x this value, not 3x. Tested range: 500-5000; higher is your own territory" },
}

local function setParam(name, value)
  local info = PARAM_INFO[name]
  value = math.max(info.min, math.min(info.max, value))
  v:addParam(name, value, info.min, info.max, info.step, info.comment)
  return value
end

setParam("gravity", 6900)

-- Former sliders, now fixed constants at their last-tuned values (see
-- CONTROL PANEL comment above for why they were pulled out of the GUI).
local FRICTION               = 0.8   -- global default friction (frame, ground, drum, gears) -- does not affect g1/g2, see ESCAPEMENT_FRICTION
local ESCAPEMENT_FRICTION    = 0.1   -- g1 (pendulum) and g2 (wheel) specific friction -- the pallet/wheel contact that actually matters for beat behavior
local ERP                    = 0.4   -- constraint-correction aggressiveness. 0.4 (with the -0.8 depthing adjustment below) measurably reduced pallet/wheel penetration vs 1.0
local MAX_SUB_STEPS          = 50    -- physics substeps per 0.1s frame. Finer prevents gear-tooth tunneling but made beat timing MORE erratic in direct testing -- a real trade-off, not bigger-is-better
local FIXED_TIMESTEP_DENOM   = 400   -- fixedTimeStep = 1/this. Paired with MAX_SUB_STEPS; MAX_SUB_STEPS/FIXED_TIMESTEP_DENOM must cover 0.1s (>= 10) or Bullet falls behind every frame
local DEPTH_DELTA            = -0.8  -- pallet depthing -- raises/lowers g1's pivot relative to the wheel. -0.8 to -0.9 tested best; -0.5 to -0.7 and -1.1 to -1.4 work but worse; -1.5 and beyond, or anything positive, jams the escapement outright in direct testing. Only applied here at startup -- it sets the hinge constraint's own geometry, which can't be safely rebuilt mid-run, so it was never a candidate for a live slider anyway.

v.gravity = btVector3(0, -v:getParam("gravity"), 0)
v.friction = FRICTION
v:setErp(ERP)
v:setErp2(0.0)

v.timeStep = 1/10 -- Fast running

-- Bullet only advances as much of each v.timeStep as MAX_SUB_STEPS *
-- fixedTimeStep covers; anything past that isn't lost but keeps rolling
-- forward in an ever-growing backlog.
v.maxSubSteps   = MAX_SUB_STEPS
v.fixedTimeStep = 1 / FIXED_TIMESTEP_DENOM
--v:setTau(0.0)

p = Plane(0, 1, 0, 0, 1000)
p.col = "#227"
--v:add(p)

c = Cube(6000,6000,6,0)
c.pos = btVector3(0, 300, 0)
c.col = "#050"
c.friction = 0.1
c.body:setAngularVelocity(btVector3(0,0,0))
v:add(c)

-- Palette and Pendulum
--
-- THE THIRD ARGUMENT (false) IS THE FIX THAT MATTERS MOST HERE. bpp's
-- Mesh() defaults to recentering a loaded STL to its own centre of mass
-- (centerOfMass=true), silently shifting where the geometry actually
-- sits relative to the .pos you give it. This script's pivot numbers and
-- "Global coords of COM" comments were worked out against the STL's RAW
-- origin, not a COM-recentered one -- confirmed directly: with the
-- default (true), v:eachContact() never once reported g1 touching g2
-- across hundreds of simulated frames (the pallet visibly sits offset
-- from the wheel, "in front of" it); with centerOfMass=false, real
-- sustained contact appears immediately and the escapement wheel's own
-- angular velocity starts alternately dropping to ~0 and picking back up
-- to the drive speed -- genuine stop-and-go escapement action, not a
-- freewheeling wheel that just drags the pallet along.
g1 = Mesh("demo/mesh/WMS_E2_Pend.stl", 100, false)
g1.col = "teal"
g1.pos = btVector3(-14.1, 198.5 + DEPTH_DELTA, 304) -- Global coords of COM -- DEPTH_DELTA constant (applied at startup only, see PARAM_INFO/CONTROL PANEL above)
g1.friction = ESCAPEMENT_FRICTION
g1.restitution = 0.0
g1.body:setLinearFactor(btVector3(0.1,0.1,0));
--g1.body:setAngularFactor(btVector3(0,0,1));
v:add(g1)
-- Position on cube, center is at 0,0
pivot0 = btVector3(0, 60 + DEPTH_DELTA, 304) -- Note the 60 -- must move BY THE SAME AMOUNT as g1.pos above to keep the pallet's own shape/pivot relationship intact
axis0 = btVector3(0,0,1)
-- Local coordinates of pivot are (-14.1,161.5)
pivot1 = btVector3(14.1,161.5,0) --198.5+161.5=360=300+60
axis1 = btVector3(0,0,1)

con1 = btHingeConstraint(
  c.body, g1.body, pivot0, pivot1, axis0, axis1)
v:addConstraint(con1)

-- Escapement Wheel, which is powered
g2 = Mesh("demo/mesh/WMS_E2_Wheel.stl", 100, false)
g2.col = "#f00"
--g2.pos = btVector3(0,400,300) -- Global
g2.pos = btVector3(0,398.8,300) -- Global
g2.friction = ESCAPEMENT_FRICTION
g2.restitution = 0.0
g2.body:setLinearFactor(btVector3(0,0,0));
--g2.body:setAngularFactor(btVector3(0,0,1));
v:add(g2)

--pivot0 = btVector3(0,100,300) -- Local, 400-100=300
pivot0 = btVector3(0,98.8,300) -- Local, 400-100=300
axis0 = btVector3(0,0,1)
pivot1 = btVector3(0,0,0)
axis1 = btVector3(0,0,1)

-- No gear train sits directly downstream of this hinge -- a marginal
-- mesh (fine, module-2.75 teeth) jams reliably at this position in the
-- scene despite meshing perfectly cleanly elsewhere with byte-identical
-- generation code, most likely a floating-point precision sensitivity
-- in Bullet's mesh-vs-mesh collision at this coordinate scale rather
-- than a fixable geometry bug. The escapement itself -- the part that
-- actually matters -- does not depend on it.
con0 = btHingeConstraint(
  c.body, g2.body, pivot0, pivot1, axis0, axis1)

-- ---------------------------------------------------------------------
-- Winding drum + weight, welded directly onto the escape wheel's own
-- arbor (no intermediate gear this time). Same closed-form cord idiom
-- as before: constant torque on the arbor, weight position read out
-- from the arbor's accumulated rotation, delivered through
-- enableAngularMotor (not applyTorque -- see the comment below) with an
-- unreachable target velocity so it's always pinned at max force,
-- behaving as constant torque rather than a speed-seeking servo.
-- ---------------------------------------------------------------------

local DRUM_R  = 40   -- drum radius -- tune together with WEIGHT_M to get a working drive torque
local DRUM_TH = 15
local WEIGHT_M = 0.2549 -- calibrated so DRIVE_TORQUE below matches max force 10000
local WEIGHT_R, WEIGHT_H = 22, 80
--local DRIVE_SIGN = 1  -- clockwise drive direction for this escapement
local DRIVE_SIGN = 1  -- clockwise drive direction for this escapement

-- DRUM_Z_EXTRA clears the drum (and the weight hanging off it) of the
-- pendulum fork's z-slice -- confirmed by v:eachContact() that without
-- this the falling weight box was physically colliding with the
-- swinging pendulum every frame.
local DRUM_Z_EXTRA = 40
drum = Cylinder(DRUM_R, DRUM_TH, 2)
drum.col = "#960"
drum.transparency = 0.4
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

-- Cylinder() shapes are built along their own local Z axis
-- (btCylinderShapeZ), so a -90deg rotation about X is needed to stand
-- the weight (and the cord, below) up along world Y instead of lying on
-- its side. Object doesn't expose a Lua setRotation, so this goes
-- through the body's motion state directly -- the same thing
-- Object::setPosition does internally, just also touching rotation.
-- Position-only updates via .pos afterwards leave this rotation alone
-- (confirmed from source: setPosition only replaces trans:setOrigin()).
local UP_Z_TO_Y = btQuaternion(btVector3(1,0,0), -math.pi/2)

-- The cord doesn't hang from the drum's rotation axis -- it leaves the
-- drum tangentially, at the edge ("the cord hangs on the +x side").
-- Since the drum's centre doesn't translate, only spins in place, that
-- tangent point is fixed in world space regardless of the arbor's
-- rotation -- no need to track it with wheelTurn, a constant offset of
-- DRUM_R is correct.
local CORD_X = drum.pos.x + DRUM_R

weight = Cylinder(WEIGHT_R, WEIGHT_H, 0)
weight.col = "#B5A642" -- Brass
v:add(weight)
local WEIGHT_TOP_Y = drum.pos.y - DRUM_R - WEIGHT_H/2 - 10 -- hangs just clear of the drum at rest
weight.body:setMotionState(btDefaultMotionState(
  btTransform(UP_Z_TO_Y, btVector3(CORD_X, WEIGHT_TOP_Y, drum.pos.z))))

-- The cord: a thin cylinder from the drum down past the weight's whole
-- anticipated travel, built ONCE (drawn as one static thread, with the
-- weight sliding down it) rather than resizing/rebuilding it every
-- frame.
--
-- bpp's Cylinder render path uses a length captured at construction time
-- (glScalef from a fixed lengths[] array) rather than the live collision
-- shape, so setLocalScaling() alone only changes the (invisible)
-- collision geometry, not what's drawn -- the rendered cord stays
-- pinned at its construction length while the collision shape silently
-- stretches. Rebuilding the cord object every frame works, but
-- recreating a full physics object leaks a small but real amount of
-- memory even when the old one is explicitly v:remove()'d. Building one
-- cord long enough to begin with sidesteps the whole problem, at the
-- cost of needing a reasonable travel estimate up front: if the weight
-- ever descends past MAX_DROP it will visually run off the end of the
-- visible cord.
local CORD_R = 3
local MAX_DROP = 2000 -- generous margin past the weight's starting position; raise if the clock runs long enough to exceed it
local cordTopY = drum.pos.y -- same height as the arbor -- the tangent point at the drum's edge, not below it
local cordBottomY = WEIGHT_TOP_Y + WEIGHT_H/2 - MAX_DROP
cord = Cylinder(CORD_R, cordTopY - cordBottomY, 0)
cord.col = "Wheat"
v:add(cord)
cord.body:setMotionState(btDefaultMotionState(
  btTransform(UP_Z_TO_Y, btVector3(CORD_X, (cordTopY + cordBottomY)/2, drum.pos.z))))

local DRIVE_TORQUE = WEIGHT_M * math.abs(v.gravity.y) * DRUM_R

-- g2.body:applyTorque() called once per preSim only affects the FIRST of
-- v.maxSubSteps internal Bullet substeps -- Bullet clears accumulated
-- forces after every substep, not once per v.timeStep call.
-- enableAngularMotor is evaluated by Bullet's constraint solver every
-- substep, so it doesn't have this problem, and with the target
-- velocity set far higher than the mechanism can reach, it stays pinned
-- at max force (DRIVE_TORQUE) at all times -- i.e. constant applied
-- torque, same as a real weight on a cord, rather than a speed-seeking
-- servo.
con0:enableAngularMotor(true, DRIVE_SIGN * 100, DRIVE_TORQUE)
v:addConstraint(con0)

-- ---------------------------------------------------------------------
-- Two gears, driven off the escapement arbor. gearA is welded rigidly
-- onto g2's own arbor (same zero-play btGeneric6DofConstraint idiom the
-- drum uses); gearB just meshes with it via contact, hinged to its own
-- small static anchor, driven by nothing but that contact.
-- ---------------------------------------------------------------------

-- Counterbalanced clock-hand SDL: a tapered pointer from the pivot
-- (0,0) out to +x, with a trapezoidal counterweight tail extending to
-- -x on the opposite side. tail_w is solved numerically (not guessed)
-- so the polygon's own area centroid lands exactly at the pivot --
-- confirmed via the shoelace centroid formula for each hand's specific
-- dimensions below. Without this, an unbalanced hand welded onto a
-- gear introduces a periodic gravity-driven torque as it rotates,
-- fighting the escapement's own steady pacing.
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

local GEAR_MODULE = 2.7778 -- matches gearsv50 drivetrain stage 1's circular_pitch=500 physical size exactly
local GEAR_PRESSURE = 20
local GEAR_TH = 15
local GEAR_Z = g2.pos.z + 60 -- well clear of the wheel/pendulum's z-band (~300-316)

local sdlA, rpA = involute_gear_sdl(8, GEAR_MODULE, GEAR_PRESSURE, GEAR_TH) -- matches drivetrain stage 1's pinion
gearA = OpenSCAD(sdlA, 4, true)
gearA.col = "#ccc"
gearA.pos = btVector3(g2.pos.x, g2.pos.y, GEAR_Z)
gearA.friction = 0.1
v:add(gearA)

local gearA_frameInG2   = btTransform(btQuaternion(0,0,0,1), btVector3(0, 0, GEAR_Z - g2.pos.z))
local gearA_frameInGearA = btTransform(btQuaternion(0,0,0,1), btVector3(0, 0, 0))
local gearA_weld = btGeneric6DofConstraint(g2.body, gearA.body, gearA_frameInG2, gearA_frameInGearA, true)
gearA_weld:setLinearLowerLimit(btVector3(0,0,0))
gearA_weld:setLinearUpperLimit(btVector3(0,0,0))
gearA_weld:setLimit(3, 0, 0)
gearA_weld:setLimit(4, 0, 0)
gearA_weld:setLimit(5, 0, 0)
v:addConstraint(gearA_weld)

-- ---------------------------------------------------------------------
-- Second hand: welded directly onto g2's own arbor (the escape wheel
-- itself) -- no reduction needed, since the escape wheel already
-- completes exactly 1 revolution per 60 seconds (20 teeth x 3s/beat),
-- which is exactly what a seconds hand needs. Placed at z=g2.z+80, in
-- the ~25-unit clear gap between gearA/gearB (z=360) and stage 2
-- (z=400). Counterweight tail_width solved for length=70, w0=6, w1=3,
-- tail=35: 13.080, confirmed centroid_x = 0 to within 1e-6.
-- ---------------------------------------------------------------------
local SECOND_HAND_Z = g2.pos.z + 80
secondHand = OpenSCAD(counterbalanced_hand_sdl(70, 6, 3, 35, 13.080, 5, 0), 0.2, true)
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

-- NOTE: g2 (the escape wheel) is deliberately NOT rotated to match the
-- current second, unlike gearD/gearF above. Those are simple, freely
-- meshing gears where any rotation rounded to a tooth pitch is
-- mechanically identical to starting at phase 0. g2 is different -- its
-- relationship to the pallet is the escapement's own locking/impulse
-- geometry, tuned via the depth=-0.8 adjustment specifically for its
-- current starting orientation. Rotating it could easily land the
-- pallet in a bad relative position and reintroduce the pallet/wheel
-- embedding problem.
-- So: the second hand starts wherever the escapement's own construction
-- puts it, not at the literal current second -- correctness here loses
-- to not breaking the escapement.
do
  local t = os.date("*t")
  print(string.format("[second hand] NOT synced to real time (real second=%d) -- see comment above for why", t.sec))
end

local sdlB, rpB = involute_gear_sdl(40, GEAR_MODULE, GEAR_PRESSURE, GEAR_TH, 360/40/2) -- a 5:1 reduction matching drivetrain stage 1's wheel
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
-- no motor: driven purely by meshing contact with gearA

-- ---------------------------------------------------------------------
-- Stage 2: 8T pinion welded onto gearB's own arbor, meshing with a 96T
-- wheel -- a 12:1 reduction, matching drivetrain stage 2's tooth counts
-- and physical size (same GEAR_MODULE, so pitch radii match gearsv50's
-- circular_pitch=500 scale exactly). Same old-generator style as
-- gearA/gearB above, just placed at a new z clear of their z-band
-- (352.5-367.5) -- z=400 leaves a comfortable ~32 units of clearance.
-- ---------------------------------------------------------------------
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

-- IDLER PREP: without rotation, gearD would touch gearF at EXACTLY the
-- mesh distance (144.44 = rpE+rpF), a direct mesh with no room for an
-- idler at all. Rotating gearD around gearC (preserves the gearC-gearD
-- mesh distance exactly, at any angle) opens clearance to gearF
-- instead. Valid window: roughly -0.5 to -8.5deg keeps gearE-gearF
-- distance within (rpE+rpF, (rpE+rpIdler)+(rpIdler+rpF)) =
-- (144.45, 166.67) for an 8-tooth idler. -5deg gives a comfortable
-- midpoint (156.92). The phase offset in involute_gear_sdl below
-- (+GEARD_ROTATION_DEG) is required too -- rotating a gear's position
-- without also rotating its tooth phase misaligns the teeth at the
-- new contact point with gearC.
local GEARD_ROTATION_DEG = -5
local sdlD, rpD = involute_gear_sdl(96, GEAR_MODULE, GEAR_PRESSURE, GEAR_TH, 360/96/2 + GEARD_ROTATION_DEG)
local mesh2Dist = rpC + rpD
local gearD_origAngle = math.deg(math.atan2(515.32 - gearC.pos.y, 153.64 - gearC.pos.x))
local gearD_radius = math.sqrt((153.64-gearC.pos.x)^2 + (515.32-gearC.pos.y)^2)
local gearD_ang = math.rad(gearD_origAngle + GEARD_ROTATION_DEG)
local gearDx = gearC.pos.x + gearD_radius * math.cos(gearD_ang)
local gearDy = gearC.pos.y + gearD_radius * math.sin(gearD_ang)
local gearDz = gearC.pos.z

gearD_anchor = Cylinder(2.25, GEAR_TH, 0)
gearD_anchor.pos = btVector3(gearDx, gearDy, gearDz)
gearD_anchor.col = "#ccc"
v:add(gearD_anchor)

gearD = OpenSCAD(sdlD, 1.5, true)
gearD.col = "lightgreen"
gearD.pos = btVector3(gearDx, gearDy, gearDz)
gearD.friction = 0.1
v:add(gearD)

local gearD_con = btHingeConstraint(gearD_anchor.body, gearD.body, btVector3(0,0,0), btVector3(0,0,0), btVector3(0,0,1), btVector3(0,0,1))
v:addConstraint(gearD_con)
-- no motor: driven purely by meshing contact with gearC

-- Set gearD's initial rotation to match the real current minute,
-- rounded to the nearest whole tooth pitch (360/96 = 3.75deg) so this
-- is mechanically identical to starting at phase 0 -- same tooth
-- alignment with gearC, no risk of a bad meshing phase, just offset by
-- a whole number of teeth (worth ~19 seconds of display error at most).
-- This MUST happen before gearE is welded onto gearD below -- doing it
-- after would leave gearE's weld referencing gearD's old orientation,
-- and the solver would violently "catch up" gearE to match on the
-- next step.
do
  local t = os.date("*t")
  local minuteDeg = (t.min + t.sec/60) * 6
  local pitch = 360/96
  local roundedDeg = math.floor(minuteDeg/pitch + 0.5) * pitch
  local quat = btQuaternion(btVector3(0,0,1), math.rad(90 - roundedDeg))
  gearD.body:setMotionState(btDefaultMotionState(btTransform(quat, gearD.pos)))
end

-- ---------------------------------------------------------------------
-- Stage 3: 8T pinion welded onto gearD's own arbor, meshing with a 96T
-- wheel -- a further 12:1 reduction, matching drivetrain stage 3's
-- tooth counts and physical size. Same old-generator style as the
-- other stages, placed at a new z clear of stage 2's z-band.
-- Total reduction from the escape wheel arbor to gearF: 5:1 * 12:1 *
-- 12:1 = 720:1, matching the real drivetrain's escape-wheel-to-hour
-- ratio.
-- ---------------------------------------------------------------------
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

local sdlF, rpF = involute_gear_sdl(96, GEAR_MODULE, GEAR_PRESSURE, GEAR_TH, 360/96/2)
local mesh3Dist = rpE + rpF
-- gearF lands almost directly above g2 (x=30, not exactly 0 -- needed
-- for a geometry where BOTH large gears clear g2, not just this one).
-- Verified clearance: ~192 units from g2.
local gearFx, gearFy, gearFz = 30, 590, gearE.pos.z

-- Idler gear: adds a fourth mesh reversal (gearA-gearB, gearC-gearD,
-- gearE-idler, idler-gearF) so gearF (and the hour hand on it) rotates
-- the SAME direction as g2 itself, matching the second hand (welded
-- directly to g2, always follows its direction). 8 teeth, matching
-- the other pinions in this drivetrain. Position solved via two-circle
-- intersection: exactly (rpE+rpIdler) from gearE, exactly
-- (rpIdler+rpF) from gearF.
local sdlIdler, rpIdler = involute_gear_sdl(8, GEAR_MODULE, GEAR_PRESSURE, GEAR_TH)
local idler_r1 = rpE + rpIdler
local idler_r2 = rpIdler + rpF
local idler_dx, idler_dy = gearFx - gearE.pos.x, gearFy - gearE.pos.y
local idler_d = math.sqrt(idler_dx^2 + idler_dy^2)
assert(idler_d > rpE + rpF, "GEARD_ROTATION_DEG hasn't opened enough clearance -- gearE and gearF are closer than rpE+rpF and would directly overlap, bypassing the idler. Increase the rotation magnitude.")
assert(idler_d < idler_r1 + idler_r2, "GEARD_ROTATION_DEG has opened too much clearance -- the idler can no longer reach both gearE and gearF. Reduce the rotation magnitude.")
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

gearF_anchor = Cylinder(2.25, GEAR_TH, 0)
gearF_anchor.pos = btVector3(gearFx, gearFy, gearFz)
gearF_anchor.col = "#ccc"
v:add(gearF_anchor)

gearF = OpenSCAD(sdlF, 1.5, true)
gearF.col = "#B36430"
gearF.pos = btVector3(gearFx, gearFy, gearFz)
gearF.friction = 0.1
v:add(gearF)

local gearF_con = btHingeConstraint(gearF_anchor.body, gearF.body, btVector3(0,0,0), btVector3(0,0,0), btVector3(0,0,1), btVector3(0,0,1))
v:addConstraint(gearF_con)
-- no motor: driven purely by meshing contact with gearE

-- Set gearF's initial rotation to match the real current hour, same
-- rounding-to-tooth-pitch technique as gearD above. Must happen before
-- hourHand is welded onto gearF, for the same reason.
do
  local t = os.date("*t")
  local hourDeg = ((t.hour % 12) + t.min/60) * 30
  local pitch = 360/96
  local roundedDeg = math.floor(hourDeg/pitch + 0.5) * pitch
  print(string.format("HOUR HAND SYNC: os.date=%02d:%02d:%02d -> hourDeg=%.3f -> rounded to %.3f (equivalent to %02d:%04.1f)",
        t.hour, t.min, t.sec, hourDeg, roundedDeg, math.floor(roundedDeg/30) % 12, (roundedDeg % 30)/30*60))
  local quat = btQuaternion(btVector3(0,0,1), math.rad(90 - roundedDeg))
  gearF.body:setMotionState(btDefaultMotionState(btTransform(quat, gearF.pos)))
end

-- ---------------------------------------------------------------------
-- Minute hand: welded onto gearD's arbor (60:1 cumulative reduction
-- from the escape wheel -- matches 1 rev/hour, correct for a minute
-- hand). Counterweight tail_width solved numerically for this hand's
-- specific dimensions (length=90, w0=8, w1=4, tail=45): 17.440,
-- confirmed centroid_x = 0 to within 1e-6.
-- ---------------------------------------------------------------------
local MINUTE_HAND_Z = gearD.pos.z + 10
minuteHand = OpenSCAD(counterbalanced_hand_sdl(90, 8, 4, 45, 17.440, 5, 0), 0.2, true)
minuteHand.col = "#e60000"
minuteHand.pos = btVector3(gearD.pos.x, gearD.pos.y, MINUTE_HAND_Z)
--v:add(minuteHand)

local minuteHand_frameInGearD = btTransform(btQuaternion(0,0,0,1), btVector3(0, 0, MINUTE_HAND_Z - gearD.pos.z))
local minuteHand_frameInHand = btTransform(btQuaternion(0,0,0,1), btVector3(0, 0, 0))
local minuteHand_weld = btGeneric6DofConstraint(gearD.body, minuteHand.body, minuteHand_frameInGearD, minuteHand_frameInHand, true)
minuteHand_weld:setLinearLowerLimit(btVector3(0,0,0))
minuteHand_weld:setLinearUpperLimit(btVector3(0,0,0))
minuteHand_weld:setLimit(3, 0, 0)
minuteHand_weld:setLimit(4, 0, 0)
minuteHand_weld:setLimit(5, 0, 0)
--v:addConstraint(minuteHand_weld)

-- ---------------------------------------------------------------------
-- Hour hand: welded onto gearF's arbor (720:1 cumulative reduction --
-- matches 1 rev/12h). tail_width solved for length=60, w0=10, w1=5,
-- tail=30: 21.800, confirmed centroid_x = 0 to within 1e-6.
-- ---------------------------------------------------------------------
local HOUR_HAND_Z = gearF.pos.z + 10
hourHand = OpenSCAD(counterbalanced_hand_sdl(60, 10, 5, 30, 21.800, 5, 0), 0.2, true)
hourHand.col = "#663B1F"
hourHand.pos = btVector3(gearF.pos.x, gearF.pos.y, HOUR_HAND_Z)
v:add(hourHand)

local hourHand_frameInGearF = btTransform(btQuaternion(0,0,0,1), btVector3(0, 0, HOUR_HAND_Z - gearF.pos.z))
local hourHand_frameInHand = btTransform(btQuaternion(0,0,0,1), btVector3(0, 0, 0))
local hourHand_weld = btGeneric6DofConstraint(gearF.body, hourHand.body, hourHand_frameInGearF, hourHand_frameInHand, true)
hourHand_weld:setLinearLowerLimit(btVector3(0,0,0))
hourHand_weld:setLinearUpperLimit(btVector3(0,0,0))
hourHand_weld:setLimit(3, 0, 0)
hourHand_weld:setLimit(4, 0, 0)
hourHand_weld:setLimit(5, 0, 0)
v:addConstraint(hourHand_weld)

-- ---------------------------------------------------------------------
-- Gear-slip diagnostic: gearB should turn exactly -(nA/nB) x gearA's
-- angle for clean meshing. Flag it the first time that drifts more than
-- half a gearB tooth pitch.
-- ---------------------------------------------------------------------
local function angleTracker(obj)
  local prevC, prevS, turn = 1, 0, 0
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
local GEAR_RATIO = 8 / 40 -- pinion_teeth/wheel_teeth
local GEAR_SLIP_LIMIT_DEG = (360/40) / 2
local gearSlipWarned = false
local trackGearC, trackGearD = angleTracker(gearC), angleTracker(gearD)
local GEAR2_RATIO = 8 / 96
local GEAR2_SLIP_LIMIT_DEG = (360/96) / 2
local gear2SlipWarned = false
local trackGearE, trackGearF = angleTracker(gearE), angleTracker(gearF)
local GEAR3_RATIO = 8 / 96
local GEAR3_SLIP_LIMIT_DEG = (360/96) / 2
local gear3SlipWarned = false

-- ---------------------------------------------------------------------
-- Beat-measurement instrumentation, sim time vs real OS time.
--
-- Tracks the pendulum's (g1's) own rotation and detects zero-crossings
-- of its angular velocity -- each crossing is a turning point (the
-- extreme of a swing), i.e. one "beat" (a tick or a tock). "sim" below
-- is N*v.timeStep -- simulated time -- and "real" is measured directly
-- with os.clock() (wall/CPU time). These will NOT agree in headless
-- batch runs (frames get computed as fast as the CPU allows); in the
-- interactive viewer this is the actual test of whether bpp paces
-- itself against the wall clock.
-- ---------------------------------------------------------------------
local trackPendulum = angleTracker(g1)
local lastPendAngVel = 0
local lastBeatTime = 0
local lastBeatClock = os.clock()
local simClockStart = os.clock()
local beatCount = 0

local wheelTurn, prevC, prevS = 0, 1, 0

-- Live gravity-slider tracking: v:getParam("gravity") can be dragged
-- while the sim runs, but DRIVE_TORQUE was computed from it ONCE,
-- above, and won't follow a later slider move on its own -- so gravity
-- changes are detected explicitly each frame and DRIVE_TORQUE + the
-- escapement motor are recomputed and reissued to match. friction, erp,
-- maxSubSteps, fixedTimeStep, and depthDelta no longer need this kind
-- of per-frame handling now that they're fixed constants (FRICTION,
-- ERP, MAX_SUB_STEPS, FIXED_TIMESTEP_DENOM, DEPTH_DELTA above) instead
-- of sliders -- each was set once, at startup, and stays put.
local lastGravity = v:getParam("gravity")

-- Penetration-depth diagnostic: objective measurement of pallet/wheel
-- contact depth (dist<0 = real interpenetration), used to tune the
-- DEPTH_DELTA (-0.8) and ERP (0.4) constants above. Kept here so you
-- can keep monitoring it during the actual long run.
local EMBED_WARN_THRESHOLD = -1.0
local worstOverallDist = nil
local worstOverallFrame = nil

v:postSim(function(N)
  local curGravity = v:getParam("gravity")
  if curGravity ~= lastGravity then
    v.gravity = btVector3(0, -curGravity, 0)
    DRIVE_TORQUE = WEIGHT_M * curGravity * DRUM_R
    con0:enableAngularMotor(true, DRIVE_SIGN * 100, DRIVE_TORQUE)
    print(string.format("frame %d: gravity slider moved %.0f -> %.0f, DRIVE_TORQUE recomputed to %.1f", N, lastGravity, curGravity, DRIVE_TORQUE))
    lastGravity = curGravity
  end

  local worstDistThisFrame = nil
  v:eachContact(function(oa, ob, px, py, pz, nx, ny, nz, dist, impulse)
    local function is(a, b) local ok, eq = pcall(function() return a == b end); return ok and eq end
    if (is(oa, g1) and is(ob, g2)) or (is(oa, g2) and is(ob, g1)) then
      if worstDistThisFrame == nil or dist < worstDistThisFrame then
        worstDistThisFrame = dist
      end
    end
  end)
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
    print(string.format("  [penetration summary @ frame %d] worst dist so far: %.3f at frame %d", N, worstOverallDist, worstOverallFrame))
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

  -- the cord pays out: the weight drops by r * turn, no rope needed --
  -- the cord itself is static (built once above) and the weight just
  -- slides down along it as this position updates.
  weight.pos = btVector3(CORD_X,
                          WEIGHT_TOP_Y - math.abs(wheelTurn) * DRUM_R,
                          drum.pos.z)

  local a, b = trackGearA(), trackGearB()
  local slipDeg = math.deg(math.abs(b - (-GEAR_RATIO * a)))
  if slipDeg > GEAR_SLIP_LIMIT_DEG and not gearSlipWarned then
    print(string.format("frame %d: GEAR SLIP -- gearB is %.2f deg off expected (limit %.2f deg)", N, slipDeg, GEAR_SLIP_LIMIT_DEG))
    gearSlipWarned = true
  end
  if N % 100 == 0 then
    --print(string.format("frame %d: gearA=%.2fdeg gearB=%.2fdeg slip=%.2fdeg", N, math.deg(a), math.deg(b), slipDeg))
  end

  local c, d = trackGearC(), trackGearD()
  local slip2Deg = math.deg(math.abs(d - (-GEAR2_RATIO * c)))
  if slip2Deg > GEAR2_SLIP_LIMIT_DEG and not gear2SlipWarned then
    --print(string.format("frame %d: GEAR SLIP -- gearD is %.2f deg off expected (limit %.2f deg)", N, slip2Deg, GEAR2_SLIP_LIMIT_DEG))
    gear2SlipWarned = true
  end
  if N % 100 == 0 then
    --print(string.format("frame %d: gearC=%.2fdeg gearD=%.2fdeg slip=%.2fdeg", N, math.deg(c), math.deg(d), slip2Deg))
  end

  local e, f = trackGearE(), trackGearF()
  local slip3Deg = math.deg(math.abs(f - (-GEAR3_RATIO * e)))
  if slip3Deg > GEAR3_SLIP_LIMIT_DEG and not gear3SlipWarned then
    --print(string.format("frame %d: GEAR SLIP -- gearF is %.2f deg off expected (limit %.2f deg)", N, slip3Deg, GEAR3_SLIP_LIMIT_DEG))
    gear3SlipWarned = true
  end
  if N % 100 == 0 then
    --print(string.format("frame %d: gearE=%.2fdeg gearF=%.2fdeg slip=%.2fdeg", N, math.deg(e), math.deg(f), slip3Deg))
  end

  local pTurn = trackPendulum()
  local pav = g1.body:getAngularVelocity().z
  local t = N * v.timeStep
  if (lastPendAngVel > 0 and pav <= 0) or (lastPendAngVel < 0 and pav >= 0) then
    local nowClock = os.clock()
    local beatDurationSim = t - lastBeatTime
    local beatDurationReal = nowClock - lastBeatClock
    if beatCount > 0 then -- skip the very first "crossing" from t=0
      print(string.format("t=%.2fs(sim): BEAT #%d -- %.3f sec(sim) / %.3f sec(real) since last beat",
                           t, beatCount, beatDurationSim, beatDurationReal))
    end
    lastBeatTime = t
    lastBeatClock = nowClock
    beatCount = beatCount + 1
    if beatCount % 20 == 0 then
      local cumSim = t
      local cumReal = nowClock - simClockStart
      print(string.format("  [cumulative check @ beat %d] sim=%.1fs real=%.1fs  (real/sim ratio=%.3f)",
                           beatCount, cumSim, cumReal, cumSim > 0 and cumReal/cumSim or 0))
    end
  end
  lastPendAngVel = pav
end)

-- Camera commands, keeps things in view.
v.cam:setUpVector(btVector3(0,1,0), false)
-- Widened and recentered to keep the whole mechanism in frame, from the
-- escapement (x=0) to gearF/hour hand (x~356).
v.cam:setHorizontalFieldOfView(0.0304)
v.cam.pos  = btVector3(178,0,15000)
v.cam.look = btVector3(178,395,0) 

v.cam.focal_blur      = 0
v.cam.focal_aperture  = 5
v.cam.focal_point = btVector3(0,0,0)
