// The Pascaline -- Babbage's Hall
//
// Pascal's adding machine (1642), three digits, with his carry: the
// sautoir, a weighted lever that each digit lifts as it counts from 0 to 9
// and drops as it passes 9, its pawl kicking the next digit on by one.
//
// Every printed part, in millimetres. The moving parts are built from the
// very primitives the simulation uses (geometry.scad, written from
// pascaline-geometry.lua by the exhibit), with what nothing touches added
// round them: wheels, hubs, dials, bolt and pivot holes, the frame.
// make-stls.sh (one folder up) makes them all.
//
// PARTS
//   digitcam    a digit with its snail cam: 2 (units, tens)
//   digitlast   the last digit (hundreds), no cam: 1
//   lever0/1    the sautoirs, one for each carry
//   pawl0/1     their pawls
//   detent      the leaf springs that hold each digit at a unit: 3
//   frame       the base, the front plate (axles, pointers) and the back
//               plate (the sautoirs' pivots)
//   pointer     3, only to glue on front plates cut from acrylic or plywood

include <geometry.scad>

PART = "";
FONT = "DejaVu Sans:style=Bold";
S = 10;                                   // cm (the simulation's) -> mm

module prim(p) {
  if (p[0] == "box") translate(S * [p[1], p[2], p[3]]) cube(S * [p[4], p[5], p[6]], center = true);
  if (p[0] == "cylz") translate(S * [p[1], p[2], p[3]]) cylinder(r = S * p[4], h = S * p[5], center = true, $fn = 32);
  if (p[0] == "hull") hull() for (q = p[1]) translate(S * q) cube(0.02, center = true);
}
module prims(P) for (p = P) prim(p);

// ---- a digit, in its own frame: its axis along z, its 0 at the top ----
DIAL_R = 44; DIAL_Z0 = 24; DIAL_Z1 = 29;  // the dial, in front of the front plate
module dialNumbers()
  for (k = [0 : 9]) rotate(k * STEP)      // (value k comes to the top when the digit has turned k steps clockwise)
    translate([0, DIAL_R - 10, DIAL_Z1]) linear_extrude(1.2)
      text(str(k), size = 11, halign = "center", valign = "center", font = FONT);
// the digit, printed in one piece from its cam up to the end of its hub
// (the hub turns in the front plate; the dial is pressed on in front)
module digit(withCam) {
  prims(withCam ? DIGIT_CAM : DIGIT_PLAIN);
  // the wheel carrying the pins (clear of the sautoir's nose by 1.5 mm)
  translate([0, 0, -4.5]) cylinder(r = S * (RP + PIN_R) + 3, h = 4.6, $fn = 64);
  // the hub, from the cam's back (or, with no cam, the wheel's) through the front plate
  hz = withCam ? S * CZ0 : -4.5;
  translate([0, 0, hz]) cylinder(r = 6, h = DIAL_Z0 + 3 - hz, $fn = 32);
}
// the dial: pressed onto the hub's end, its numbers raised (paint them dark
// on a light face; numbers = false: the face alone, as the simulation draws
// the numbers apart, in another colour)
module dial(numbers = true) difference() {
  union() {
    translate([0, 0, DIAL_Z0]) cylinder(r = DIAL_R, h = DIAL_Z1 - DIAL_Z0, $fn = 96);
    if (numbers) dialNumbers();
  }
  translate([0, 0, DIAL_Z0 - 1]) cylinder(r = 6.1, h = 3.2, $fn = 32);    // (the hub's end goes in)
}
// as the simulation draws it: the digit and its dial, one body
module digitAll(withCam) { digit(withCam); dial(); }

// ---- the sautoirs and pawls, in the machine's frame (cm * S) ----
PIN = 3.2;                                // their pivot pins: 3 mm steel
module lever(i) {
  difference() {
    prims(LEVERS[i]);
    translate(S * [LEVER_PIVOTS[i][0], LEVER_PIVOTS[i][1], LEVER_PIVOTS[i][2]]) cylinder(d = PIN, h = 20, center = true, $fn = 16);
    translate(S * [PAWL_HINGES[i][0], PAWL_HINGES[i][1], PAWL_HINGES[i][2] + 0.75]) cylinder(d = PIN, h = 10, center = true, $fn = 16);
    // the weight: an M6 bolt through the block, the steel on it
    translate(S * [WEIGHT_AT[i][0], WEIGHT_AT[i][1], WEIGHT_AT[i][2]]) cylinder(d = 6.4, h = 20, center = true, $fn = 16);
  }
}
module pawl(i) {
  difference() {
    union() {
      prims(PAWLS[i]);
      // a boss round its pivot (in the print only: nothing comes near it)
      translate(S * [PAWL_HINGES[i][0], PAWL_HINGES[i][1], PAWL_HINGES[i][2]]) cylinder(r = 4.5, h = 6, center = true, $fn = 32);
    }
    translate(S * [PAWL_HINGES[i][0], PAWL_HINGES[i][1], PAWL_HINGES[i][2]]) cylinder(d = PIN + 0.3, h = 20, center = true, $fn = 16);
  }
}

// ---- the detents: a leaf spring for each digit ----
// The moving part (nose and leaf) as assembled, the nose touching two pins;
// the simulation draws this, and turns it about the leaf's root.
module detentMoving(i) prims(DETENTS[i]);
// Its root: a block, screwed to the back of the front plate with an M3
// screw from the front (a 2.5 mm hole to tap), holding the leaf's foot.
DB_W = 10; DB_H = 8;                       // the block across (x) and down from the leaf's root (y)
module detentRoot(i) {
  r = DETENT_ROOTS[i];
  difference() {
    translate([S * r[0] - DB_W / 2, S * r[1] - DB_H, S * DET_Z0]) cube([DB_W, DB_H, FP_Z0 - S * DET_Z0]);
    translate([S * r[0], S * r[1] - DB_H / 2, 0]) cylinder(d = 2.5, h = 100, $fn = 16);
  }
}
// The part as printed: one piece, the leaf straight as it is when free --
// a little further in than when it is in place, pressed out by the pins
// (DET_PRE: the preload) -- standing on the face that lies toward the
// wheel, the leaf upright. Print it in PLA, 100% infill for the leaf (it
// is 1.2 mm: three lines of a 0.4 mm nozzle), perimeters along it.
module detentPart(i) {
  r = DETENT_ROOTS[i];
  union() {
    translate(S * [r[0], r[1], 0]) rotate(-atan(DET_PRE / DET_L)) translate(-S * [r[0], r[1], 0]) detentMoving(i);
    detentRoot(i);
  }
}

// ---- the frame: base, front plate, back plate ----
FP_Z0 = 16; FP_Z1 = 22;                   // the front plate (between the pawls' carriers and the dials)
BP_Z0 = -48; BP_Z1 = -42;                 // the back plate (behind the sautoirs)
// the pointers over the dials' tops (part of the front plate; the
// simulation draws them apart, in brass)
module pointers()
  for (i = [0 : ND - 1]) translate([S * (-i * D), S * Y0 + DIAL_R + 3, FP_Z1])
    linear_extrude(DIAL_Z1 - FP_Z1 + 2) polygon([[-4, 8], [4, 8], [0, 0]]);
module frame(withPointers = true) {
  x0 = S * (-(ND - 1) * D - PA) - 30;     // (left of the last sautoir's pivot)
  x1 = S * R1 + 60;
  ybase = S * Y0 - 70;
  ytop = S * Y0 + 62;
  // the base
  translate([x0, ybase - 8, BP_Z0]) cube([x1 - x0, 8, FP_Z1 - BP_Z0 + 40]);
  // the front plate: each digit's hub turns in a hole in it (nothing may
  // run behind the wheels, where the sautoirs swing)
  difference() {
    translate([x0, ybase, FP_Z0]) cube([x1 - x0, ytop - ybase, FP_Z1 - FP_Z0]);
    for (i = [0 : ND - 1]) translate([S * (-i * D), S * Y0, 0]) cylinder(d = 12.4, h = 100, center = true, $fn = 48);
    // the detents' screws (M3, from the front into their blocks)
    for (i = [0 : ND - 1]) translate([S * DETENT_ROOTS[i][0], S * DETENT_ROOTS[i][1] - DB_H / 2, 0]) cylinder(d = 3.4, h = 100, center = true, $fn = 16);
  }
  if (withPointers) pointers();
  // the back plate, with the sautoirs' pivot pins
  difference() {
    translate([x0, ybase, BP_Z0]) cube([x1 - x0, ytop - ybase, BP_Z1 - BP_Z0]);
    for (i = [0 : ND - 2]) translate(S * [LEVER_PIVOTS[i][0], LEVER_PIVOTS[i][1], 0]) cylinder(d = PIN - 0.2, h = 200, center = true, $fn = 16);
  }
  // the ends, joining the plates
  for (x = [x0, x1 - 8]) translate([x, ybase, BP_Z0]) cube([8, ytop - ybase, FP_Z1 - BP_Z0]);
}

// AS PRINTED: each turned to lie on the bed; the long frame pieces in two
// halves (or cut the plates from 6 mm acrylic or plywood: PART="cut-front",
// "cut-back" give their outlines, for a .dxf or .svg)
FX0 = S * (-(ND - 1) * D - PA) - 30;      // (as in frame())
FX1 = S * R1 + 60;
FXM = (FX0 + FX1) / 2;
module half(which) intersection() { children(); translate([which == 0 ? -1000 : FXM, -1000, -1000]) cube([which == 0 ? 1000 + FXM : 1000, 2000, 2000]); }
// (the front plate with its pointers standing on it; the cut outline without)
module frontPlate(withPointers = true) {
  intersection() { frame(false); translate([-1000, -1000, FP_Z0]) cube([2000, 2000, FP_Z1 - FP_Z0]); }
  if (withPointers) pointers();
}
module backPlate() intersection() { frame(); translate([-1000, -1000, BP_Z0]) cube([2000, 2000, BP_Z1 - BP_Z0]); }
if (PART == "print-digitcam") translate([0, 0, -S * CZ0]) digit(true);                    // its cam on the bed
if (PART == "print-digitlast") translate([0, 0, 4.5]) digit(false);                    // its wheel on the bed
if (PART == "print-dial") translate([0, 0, -DIAL_Z0]) dial();                           // face up
if (PART == "print-lever0") translate([0, 0, -S * (-2.1 - 0.3)]) lever(0);              // its plane on the bed (the pawl's arm needs support)
if (PART == "print-lever1") translate([0, 0, -S * (-3.3 - 0.3)]) lever(1);
if (PART == "print-pawl0") translate([0, 0, -S * (PZ0 + PZ1) / 2 + 4]) pawl(0);
if (PART == "print-detent") translate([-S * DETENT_ROOTS[0][0], -S * DETENT_ROOTS[0][1], -S * DET_Z0]) detentPart(0);   // the wheel's side down
if (PART == "print-pawl1") translate([0, 0, -S * (PZ0 + PZ1) / 2 + 4]) pawl(1);
if (PART == "print-front-left") rotate([0, 0, 0]) translate([0, 0, -FP_Z0]) half(0) frontPlate();
if (PART == "print-front-right") translate([0, 0, -FP_Z0]) half(1) frontPlate();
if (PART == "print-back-left") translate([0, 0, -BP_Z0]) half(0) backPlate();
if (PART == "print-back-right") translate([0, 0, -BP_Z0]) half(1) backPlate();
FYB = S * Y0 - 70;                        // (the base's top, as in frame())
module basePiece() intersection() { frame(); translate([-1000, FYB - 50, -1000]) cube([2000, 50, 2000]); }
FYT = S * Y0 + 62;                        // (the plates' top)
module endPiece() cube([FP_Z0 - BP_Z1, FYT - FYB, 8]);      // a bar joining the plates at each end (as printed)
if (PART == "print-base-left") translate([0, 0, 0]) rotate([90, 0, 0]) translate([0, -FYB + 8, 0]) half(0) basePiece();
if (PART == "print-base-right") rotate([90, 0, 0]) translate([0, -FYB + 8, 0]) half(1) basePiece();
if (PART == "print-end") endPiece();
if (PART == "cut-front") projection(cut = true) translate([0, 0, -(FP_Z0 + FP_Z1) / 2]) frontPlate(false);
// a pointer on its own, to glue on a cut plate (3 of them)
if (PART == "print-pointer") translate([0, -(S * Y0 + DIAL_R + 3), -FP_Z1]) intersection() { pointers(); translate([-20, -1000, -1000]) cube([40, 2000, 2000]); }
if (PART == "cut-back") projection(cut = true) translate([0, 0, -(BP_Z0 + BP_Z1) / 2]) backPlate();
if (PART == "digitcam") digit(true);
if (PART == "digitlast") digit(false);
if (PART == "lever0") lever(0);
if (PART == "lever1") lever(1);
if (PART == "pawl0") pawl(0);
if (PART == "pawl1") pawl(1);
if (PART == "frame") frame();

// the whole machine, put together at rest (to look at)
module assembly(withFrame = true) {
  for (i = [0 : ND - 1]) translate([S * (-i * D), S * Y0, 0]) color("Goldenrod") digit(i < ND - 1);
  for (i = [0 : ND - 2]) { color("SlateGray") lever(i); color("DarkGoldenrod") pawl(i); }
  for (i = [0 : ND - 1]) color("Wheat") { detentMoving(i); detentRoot(i); }
  if (withFrame) color("SaddleBrown", 0.3) frame();
}
if (PART == "assembly") assembly();
if (PART == "works") assembly(false);
