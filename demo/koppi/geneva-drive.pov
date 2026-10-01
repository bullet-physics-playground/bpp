// geneva-drive.pov -- Geneva drive (Maltese cross), analytic kinematics
//
// A standalone POV-Ray SDL port of demo/constraint/11-geneva-drive.lua.
// Nothing physical is simulated: unlike bpp, which lets the motor-driven
// pin-disk and the free-hinging cross interact through Bullet contact,
// this file positions both rotors with closed-form formulas evaluated once
// per frame, as a pure function of the built-in `clock` variable.
//
// THE KINEMATIC MODEL
// Cross center sits at the origin, pin-disk center at (0, D). The pin
// travels on an orbit of radius RP about the disk center:
//
//   P(theta) = (RP*sin(theta), D + RP*cos(theta))
//
// with theta the disk rotation angle, taken from theta=0 at the "far
// side" (pin pointing straight away from the cross -- the pose the Lua
// demo starts in). While a pin is engaged, the cross's slot keeps its
// centerline pointing at the pin, so the cross angle is, exactly,
//
//   phi(theta) = atan2(RP*sin(theta), D + RP*cos(theta))      (from the +X axis)
//
// and the known Geneva speed ratio dphi/dtheta = RP*(D*cos(theta)+RP) /
// (D^2 + RP^2 + 2*D*RP*cos(theta)) is an immediate consequence. The pin's
// closest approach to the cross center is the alpha=0 point, theta=180.
// Engagement spans alpha in [-alphaE, +alphaE] around it, where alphaE is
// the driver angle at which the cross has turned its full slot pitch
// 360/slots. Solving phi(+alphaE) - phi(-alphaE) = 90:
//
//   sin(alphaE) + cos(alphaE) = D / RP     =>      alphaE = asin(D/(RP*sqrt 2)) - 45
//
//   For the shipped geometry (D=2.6, RP=1.84 = D*sin 45) this is ~42.7, so
//   the pin steers the cross through a clean 90 while the disk sweeps
//   ~85; the rest of the disk turn is the classic dwell, during which the
//   disk's locking rim nests in the cross's notch arcs. Outside the window
//   phi is clamped, giving the intermittent stop-start motion -- no contact
//   solving involved anywhere, and the pin provably rides the slot
//   centerline through the whole cycle. Each index advances the cross -90
//   (clockwise, following the CW-orbiting pin); the next rev reproduces a
//   fresh slot aimed at the same 135-degree entry point (the GG+90 groove).
//
// Geometry constants are taken verbatim from 11-geneva-drive.lua, and the
// two discs are built in SDL as the same CSG the Lua demo sends to
// OpenSCAD: the cross is a disc minus four rounded grooves (open at the
// rim, flared at the mouth) minus four two-lobe lock notches, the pin-disk
// is a crescent disc minus a trailing "bite" with the pin stub re-added.
//
// Usage:
//   Quick static preview:              povray +W1280 +H720 geneva-drive.pov
//   Full loop (4 disk turns = 1 cross turn, loops seamlessly):
//                                     povray +W1280 +H720 +KFF480 geneva-drive.pov
//
#version 3.7;

global_settings { assumed_gamma 1.0 }

//----------------------------------------------------------------------
// Geometry -- identical numbers to 11-geneva-drive.lua.
//----------------------------------------------------------------------
#declare D       = 2.6;    // cross-center-to-disk-center distance, +Y
#declare THICK   = 0.6;    // plate thickness along Z
#declare RIM     = 1.70;   // pin-disk locking-rim radius
#declare RP      = 1.84;   // pin orbit radius
#declare PT      = 0.16;   // pin radius
#declare B_C     = 1.90;   // bite center (local +Y, behind the pin)
#declare B_R     = 0.75;   // bite radius -> crescent driver
#declare CROSS_R = 2.00;   // Maltese-cross blade-tip radius
#declare CARVE   = 1.72;   // lock-notch arc radius on the axes
#declare DELTA   = 0.20;   // notch flank offset (two-lobe stop)
#declare FLOOR   = 0.60;   // groove floor radius (= D - RP - PT)
#declare GW      = 0.50;   // groove width (clearance around the 0.32 pin)
#declare FLR     = 0.40;   // groove mouth flare past the rim
#declare GG      = 46.0;   // groove centerline angle, 4-fold spaced 90

#declare SLOTS   = 4;      // Maltese-cross station count
#declare REVS    = 4;      // disk turns per loop (= SLOTS, so the cross
                           //   makes one full, seamless turn)

//----------------------------------------------------------------------
// Analytic Geneva kinematics (see header).
//----------------------------------------------------------------------
#declare AlphaE = degrees(asin(D / (RP * sqrt(2)))) - 45;

#declare ThetaTot   = clock * REVS * 360;   // total disk angle for this frame
#declare Rev        = floor(ThetaTot / 360);
#declare Ang        = ThetaTot - Rev * 360; // disk angle within this revolution
#declare Beta       = Ang - 180;            // 0 = pin closest to cross center
// For clockwise disc rotation the pin enters from azimuth 135 (upper-left)
// rather than 45 (upper-right).  The GG+90=136 groove catches it at rest,
// and each index rotates the cross -90 (clockwise), stepping the DwellAngle
// down by 90/rev so the next CW-neighbour groove is aimed at 135.
#declare DwellAngle = -1 - Rev * 90;

#declare CrossAngle = DwellAngle;
#if (Beta < -AlphaE)
  #declare CrossAngle = DwellAngle;
#elseif (Beta > AlphaE)
  #declare CrossAngle = DwellAngle - 90;
#else
  #declare PinAz = degrees(atan2(D + RP * cos(radians(Ang)), RP * sin(radians(Ang))));
  #declare CrossAngle = DwellAngle + (PinAz - 135);
#end

#debug concat("geneva-drive.pov: ", str(REVS * 360 / 3, 0, 0),
              " frames for 1 seamless loop at 1 frame/3 deg (KFF",
              str(REVS * 360 / 3, 0, 0), ")\n")

//----------------------------------------------------------------------
// Finishes and colors (the Lua demo's vertex colors).
//----------------------------------------------------------------------
#macro MechFinish()
  finish { ambient 0.15 diffuse 0.7 phong 0.6 phong_size 40 }
#end

//----------------------------------------------------------------------
// Maltese cross: disc minus 4 rounded grooves minus 4 two-lobe notches.
// A groove is the extruded hull of two circles (OpenSCAD's groove()),
// i.e. a rounded capsule: an axis-aligned middle box plus two round caps.
//----------------------------------------------------------------------
#macro GrooveCut(Ang, T)
  #local Ux = cos(radians(Ang));
  #local Uy = sin(radians(Ang));
  #local P0 = Ux * FLOOR * x + Uy * FLOOR * y;
  #local P1 = Ux * (CROSS_R + FLR) * x + Uy * (CROSS_R + FLR) * y;
  #local h  = GW / 2;
  #local B0 = (min(P0.x, P1.x) - abs(Uy) * h) * x
            + (min(P0.y, P1.y) - abs(Ux) * h) * y
            - (T / 2) * z;
  #local B1 = (max(P0.x, P1.x) + abs(Uy) * h) * x
            + (max(P0.y, P1.y) + abs(Ux) * h) * y
            + (T / 2) * z;
  union {
    box   { B0, B1 }
    cylinder { P0 - (T / 2 + 0.01) * z, P0 + (T / 2 + 0.01) * z, h }
    cylinder { P1 - (T / 2 + 0.01) * z, P1 + (T / 2 + 0.01) * z, h }
  }
#end

#declare CrossObj = difference {
  cylinder { -THICK / 2 * z, THICK / 2 * z, CROSS_R }
  #local I = 0;
  #while (I < SLOTS)
    object { GrooveCut(GG + I * 90, THICK) }
    #local I = I + 1;
  #end
  #local I = 0;
  #while (I < SLOTS)
    #local A = I * 90;
    #local C = cos(radians(A));
    #local S = sin(radians(A));
    // OpenSCAD:  rotate(A) { translate([+-DELTA, D]) circle(r = CARVE) }
    //   rotate(A) maps (x,y) -> (x c - y s, x s + y c), so the two concave
    //   lock arcs center on the AXES at rotate(A)(+-DELTA, D) = D*Ay +- DELTA*Ax
    #local N1 = < DELTA * C - D * S, DELTA * S + D * C, 0>;
    #local N2 = <-DELTA * C - D * S, -DELTA * S + D * C, 0>;
    #local EZ = (THICK / 2 + 0.01) * z;
    object { cylinder { N1 - EZ, N1 + EZ, CARVE } }
    object { cylinder { N2 - EZ, N2 + EZ, CARVE } }
    #local I = I + 1;
  #end
}

//----------------------------------------------------------------------
// Pin-disk: crescent locking rim (disc minus trailing bite) plus the
// protruding pin stub -- one connected part, as in the OpenSCAD union.
//----------------------------------------------------------------------
#declare PinDiskObj = union {
  difference {
    cylinder { -THICK / 2 * z, THICK / 2 * z, RIM }
    cylinder { B_C * y - (THICK / 2 + 0.01) * z,
               B_C * y + (THICK / 2 + 0.01) * z, B_R }
  }
  cylinder { RP * y - THICK / 2 * z, RP * y + THICK / 2 * z, PT }
}

//----------------------------------------------------------------------
// Scene
//----------------------------------------------------------------------
background { color rgb <0.05, 0.05, 0.07> }
global_settings { ambient_light rgb <0.35, 0.35, 0.4> }

// Stallion of the kinematic world: the cross, and the pin-disk riding next
// to it at (0, D). Both rotate in-plane about Z; parity between the two
// bodies' POV rotations and the analytic model is exact (POV rotates about
// +Z by the same right-handed angles the math uses).
object {
  CrossObj
  rotate z * CrossAngle
  pigment { color rgb <0.392, 0.808, 0.612> }   // #64ce9c
  MechFinish()
}

object {
  PinDiskObj
  rotate z * (-ThetaTot)
  translate y * D
  pigment { color rgb <0.800, 0.808, 0.204> }   // #ccce34
  MechFinish()
}

// Dark backing plate, mirroring the Lua demo's mount (moved to +Z so it
// reads as "behind" the mechanism from this camera's -Z side).
box {
  <-2.75, -3.1, THICK / 2 + 0.06 - 0.025>,
  < 2.75,  3.1, THICK / 2 + 0.06 + 0.025>
  pigment { color rgb <0.133, 0.133, 0.133> }   // #222222
  finish { ambient 0.1 diffuse 0.5 phong 0.2 phong_size 20 }
}

//----------------------------------------------------------------------
// Camera and lights: near-orthographic flat view straight at the plate,
// like the bpp export framing, so the intermittent motion stays readable.
//----------------------------------------------------------------------
camera {
  location <0, 1.2, -16>
  right    image_width / image_height * x
  look_at  <0, 1.2, 10>
  angle    45
}

light_source { <6, 8, -10> color rgb <1, 0.96, 0.9> }
light_source { <-6, 4, -12> color rgb <0.55, 0.55, 0.62> shadowless }
light_source { <0, 6, 8>    color rgb <0.30, 0.34, 0.45> shadowless }

// EOF