--
-- geneva-drive.lua -- Geneva drive (Maltese cross), shapes built in OpenSCAD.
--
-- A faithful port of the reference in geneva-drive (a Tcl/Tk animation
-- by Keith Vetter. A continuously-rotating "pin-disk" carries a single
-- pin that indexes a 4-slot Maltese cross one slot (90 deg) per turn, then
-- the cross dwells while the pin swings clear -- the classic intermittent
-- motion of a film projector.  The cross turns opposite the pin-disk.
--
-- Geometry is a textbook 4-station Geneva: grooves (deep enough that the pin
-- rides right to the bottom of the slot) open toward the four diagonals, the
-- concave lock arcs face the four axes, and the line of centers D is chosen
-- so the pin (orbit radius = D - slot floor) reaches the slot bottom --
-- fully "into the hole".
--
-- Usage: bpp -f demo/jr/gdr.lua
--

local common = require "common"

-- The mechanism is a flat plate lying in the XY plane, spinning about Z.
-- Gravity is off so nothing sags out of plane or wants to settle toward a
-- "bottom-heavy" rest pose -- the only force is the pin-disk motor.
v.gravity = btVector3(0, 0, 0)
common.setTiming(1/60, 12, 1/120)

-- Geometry ---------------------------------------------------------
-- Classic 4-slot Geneva proportions, verified collision-free over a full
-- cycle by a kinematic grid check (geneva_verify.py):
--   pin orbit RP = D*sin(45deg) = 1.84;  floor = D - RP - PT = 0.60 so the
--   pin rides right to the slot bottom -- fully "into the hole".
local D      = 2.6    -- distance between cross center and pin-disk center
local THICK  = 0.6    -- plate thickness along Z

-- Pin-disk: a locking rim (RIM) carrying one pin nub whose orbit RP has the
-- pin bottom flush with the groove floor.  The rim is not a full disc: a
-- bite (radius B_R at B_C, radially behind the pin) removes the trailing
-- wedge so the driver body clears the star while the pin is in the groove.
-- The pin nub overlaps the rim disc (RP - PT < RIM) so it is one solid part.
local IMP    = 3000   -- hinge motor max impulse (ramp-hardness)
-- Locking-rim radius nests in the star's notch arcs (rim < cross lobe tip:
-- the two coplanar discs would otherwise overlap and jam).
local RIM   = 1.70    -- locking-rim radius
local RP    = 1.84    -- pin orbit radius
local PT    = 0.16    -- pin radius
local B_C   = 1.90    -- bite center (local +Y, behind the pin)
local B_R   = 0.75    -- bite radius -> crescent-shaped driver
-- In the local frame the pin points +Y, away from the cross, so the disk can
-- start dwelled with the pin clear; the pin sweeps around and catches a slot.

-- Maltese cross (4 slots => indexes 360/4 = 90 deg per disk revolution)
local CROSS_R = 2.00  -- rim (blade-tip) radius of the cross disc; like the
                      --  reference driver it outswings the locking rim while it
                      --  indexes, and the rim's bite keeps them clear
local CARVE = 1.72 -- notch-arc radius on the axes (stores the 1.70 rim)
local DELTA = 0.20  -- flank offset: carve the notch from two offset arcs so a
                      --  flank wedges the rim = a positive stop (concentric arcs
                      --  would let the cross freewheel right through the dwell)
local FLOOR   = 0.60  -- groove floor radius: D - RP - PT, pin bottoms flush
local GW = 0.50  -- groove width (clearance around the 0.32 pin)
local FLR = 0.40  -- groove mouth flare past the rim; chamfers the mouth so
                      --  the pin steers into the slot instead of biting a tooth
local GG      = 46.0  -- groove centerline angle, 4-fold spaced 90 deg
-- grooves lie on the diagonals, the concave lock arcs on the axes.

-- Build the cross: a disc minus four deep rounded grooves (open at the rim,
-- pointed at the diagonals) minus four circular arcs carved at distance D on
-- the axes.  The arcs are close to the locking rim's circle, so when the disk
-- is dwelled the rim nests in one of them and holds the cross -- and while
-- the pin is driving the cross, the arcs just sweep clear of the rim.
local cross = OpenSCAD(string.format([[ 
  module groove() {
    hull() {
      translate([%.4f, 0]) circle(r = %.4f, $fn = 32);
      translate([%.4f, 0]) circle(r = %.4f, $fn = 32);
    }
  }
  module cross2d() {
    difference() {
      circle(r = %.4f, $fn = 192);
      for (a = [0, 90, 180, 270])
        rotate(a) {
          translate([-%.4f, %.4f, 0]) circle(r = %.4f, $fn = 128);
          translate([+%.4f, %.4f, 0]) circle(r = %.4f, $fn = 128);
        }
      for (a = [%.1f, %.1f, %.1f, %.1f])
        rotate(a) groove();
    }
  }
  translate([0, 0, -%.4f]) linear_extrude(%.4f) cross2d();
]], FLOOR, GW / 2, CROSS_R + FLR, GW / 2,
   CROSS_R, DELTA, D, CARVE, DELTA, D, CARVE,
   GG, GG + 90, GG + 180, GG + 270,
   THICK / 2, THICK), 1, true)
cross.col = "#64ce9c"
cross.pos = btVector3(0, 0, 0)
v:add(cross)

-- Build the pin-disk: crescent locking rim (disc minus trailing bite) plus
-- the pin nub riding on its rim -- one connected part.
local pinDisk = OpenSCAD(string.format([[
  module pindisk2d() {
    union() {
      difference() {
        circle(r = %.4f, $fn = 160);
        translate([0, %.4f]) circle(r = %.4f, $fn = 64);
      }
      translate([0, %.4f]) circle(r = %.4f, $fn = 32);
    }
  }
  translate([0, 0, -%.4f]) linear_extrude(%.4f) pindisk2d();
]], RIM, B_C, B_R, RP, PT, THICK / 2, THICK), 1, true)
pinDisk.col = "#ccce34"
pinDisk.pos = btVector3(0, D, 0)
v:add(pinDisk)

-- --- Constraints ---------------------------------------------------------
-- Pin-disk: hinge to the world at its own center, spun about Z by a motor.
local diskHinge = btHingeConstraint(pinDisk.body,
                                    btVector3(0, 0, 0), btVector3(0, 0, 1))
diskHinge:enableAngularMotor(true, 0.6, IMP)
v:addConstraint(diskHinge)

-- Cross: hinge to the world at its center; free to rotate -- the pin indexes
-- it purely by contact.
local crossHinge = btHingeConstraint(cross.body,
                                     btVector3(0, 0, 0), btVector3(0, 0, 1))
v:addConstraint(crossHinge)

-- Cold, low-friction tool steel: the pin must be able to slide out of the
-- groove and the cross to lift off the locking rim cleanly.
cross.body:setFriction(0.3)
cross.body:setRestitution(0.05)
pinDisk.body:setFriction(0.3)
pinDisk.body:setRestitution(0.05)

-- Bullet's default deactivation (2 s of motion below the sleep thresholds)
-- would park the slow-turning pin disk and the mostly-idle cross, freezing
-- the drive mid-cycle.  Zero the sleep thresholds so neither body ever naps.
cross.body:setSleepingThresholds(0, 0)
pinDisk.body:setSleepingThresholds(0, 0)

local OPT_PIN = 0.6
v:addParam("pinSpeed", OPT_PIN, 0.0, 4.0, 0.1, "pin-disk rotation speed, rad/s")
v:onParamChanged(function(N, name, value)
  if name == "pinSpeed" then
    diskHinge:enableAngularMotor(true, tonumber(value), 3000)
  end
end)

-- A thin static backplate gives the floating mechanism a mount to read
-- against (mass 0 => immovable).
local plate = Cube(5.5, 6.2, 0.05, 0)
plate.pos = btVector3(0, 1.1, -THICK * 0.5 - 0.06)
plate.col = "#222222"
v:add(plate)

-- Camera: the flat plate faces along -Z.
common.setCamera(btVector3(0, 1.2, 16), btVector3(0, 1.2, 0))
