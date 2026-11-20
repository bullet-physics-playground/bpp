// combination-lock.scad -- every part of Babbage's Hall's combination lock.
// The sizes come from lock-geometry.scad, which lock.lua writes (the same
// numbers the simulation's bodies are made from). Millimetres.
//
// The lock's frame: x to the right, y up, z toward you; the origin on the
// spindle's axis at the back plate's front face; the table at y = -AXIS_H.
// A part that moves is drawn about its body's origin (each module says
// where that is); make-stls.sh turns each to lie on the printer's bed.
include <lock-geometry.scad>
$fn = 144;
FONT = "Liberation Sans:style=Bold";

TABLE_Y = -AXIS_H;
BASE_T = 6;
BACK_X0 = -140; BACK_X1 = 54; BACK_Y1 = 64;   // the back plate
BASE_X0 = -146;                               // the base, under the keeper too: 200 mm

// ---------------------------------------------------------------------
// the wheels: about the axis, their middle at z = 0. Gate's middle at
// gate (degrees, the wheel's own frame); n its number, cut in its face.
// ---------------------------------------------------------------------
module gateCut(gate, r, depth, t) {
  // a wedge of radial walls, GATE_HALF either side, from the rim depth deep
  rotate([0, 0, gate]) linear_extrude(height = t + 2, center = true)
    polygon([[0, 0], [2 * r * cos(GATE_HALF), 2 * r * sin(GATE_HALF)],
             [2 * r * cos(GATE_HALF), -2 * r * sin(GATE_HALF)]]);
}
module wheel(gate, n = 1) difference() {
  cylinder(r = R_W, h = T_W, center = true);
  cylinder(r = HUB_R, h = T_W + 2, center = true, $fn = 48);
  difference() {
    gateCut(gate, R_W, GATE_DEPTH, T_W);
    cylinder(r = R_W - GATE_DEPTH, h = T_W + 4, center = true);
  }
  // the pin's hole (a press fit for a 3 mm dowel)
  rotate([0, 0, PIN_AT]) translate([PIN_R, 0, 0]) cylinder(d = PIN_D - 0.1, h = T_W + 2, center = true, $fn = 24);
  // its number, cut 0.6 mm into its front face, below the hub
  translate([0, -17, T_W / 2 - 0.6]) linear_extrude(1) text(str(n), size = 9, font = FONT, halign = "center", valign = "center");
  // a lightening ring of holes (the wheels are lighter, the pins' pushes the same)
  for (k = [0 : 5]) rotate([0, 0, 30 + 60 * k]) translate([16, 0, 0]) cylinder(r = 4.5, h = T_W + 2, center = true, $fn = 32);
}
// the gate's floor painted red (to see it from above)
module gateMark(gate) rotate([0, 0, gate]) intersection() {
  difference() { cylinder(r = R_W - GATE_DEPTH + 0.25, h = T_W - 0.4, center = true); cylinder(r = R_W - GATE_DEPTH - 0.5, h = T_W, center = true); }
  linear_extrude(height = T_W, center = true) polygon([[0, 0], [2 * R_W * cos(GATE_HALF - 0.3), 2 * R_W * sin(GATE_HALF - 0.3)], [2 * R_W * cos(GATE_HALF - 0.3), -2 * R_W * sin(GATE_HALF - 0.3)]]);
}
module pin() cylinder(d = PIN_D, h = PIN_L, center = true, $fn = 24);
module washer() difference() {         // a spacer between wheels (fixed on the post: keyed)
  cylinder(r = WASHER_R, h = 5.4, center = true, $fn = 72);
  cylinder(r = POST_R + 0.1, h = 8, center = true, $fn = 48);
}

// ---------------------------------------------------------------------
// the dial's body: the cam, the spindle, the dial and its knob, one body
// about the axis, its origin at the cam's middle (z = Z_C + T_C / 2)
// ---------------------------------------------------------------------
CAM_MID = Z_C + T_C / 2;
module cam() difference() {
  translate([0, 0, -T_C / 2]) linear_extrude(T_C) polygon(CAM_OUTLINE);
  // the spindle's flat-sided hole (it can't slip)
  intersection() { cylinder(r = SPINDLE_R + 0.1, h = T_C + 2, center = true, $fn = 48); cube([2 * SPINDLE_R + 1, 2 * SPINDLE_R - 1.2, T_C + 2], center = true); }
  rotate([0, 0, PIN_AT]) translate([PIN_R, 0, -T_C / 2 - 1]) cylinder(d = PIN_D - 0.1, h = CAM_PIN_IN + 1, $fn = 24);
}
module camPin() rotate([0, 0, PIN_AT]) translate([PIN_R, 0, -T_C / 2 - CAM_PIN_OUT]) cylinder(d = PIN_D, h = CAM_PIN_OUT + CAM_PIN_IN, $fn = 24);
module spindle() difference() {         // an 8 mm steel rod, its flat filed on where it goes through the cam
  translate([0, 0, -T_C / 2]) cylinder(r = SPINDLE_R, h = KNOB_Z1 - 6 - Z_C, $fn = 48);
  translate([-SPINDLE_R - 1, SPINDLE_R - 0.7, -T_C / 2 - 1]) cube([2 * SPINDLE_R + 2, 2, T_C + 3]);
  translate([-SPINDLE_R - 1, -SPINDLE_R - 1.3, -T_C / 2 - 1]) cube([2 * SPINDLE_R + 2, 2, T_C + 3]);
}
module dialFace() difference() {        // the dial and its knob, printed in one
  union() {
    translate([0, 0, DIAL_Z0 - CAM_MID]) cylinder(r = DIAL_R, h = DIAL_Z1 - DIAL_Z0);
    translate([0, 0, DIAL_Z1 - CAM_MID - 1]) cylinder(r1 = KNOB_R + 3, r2 = KNOB_R, h = 4);
    translate([0, 0, DIAL_Z1 - CAM_MID]) difference() {
      cylinder(r = KNOB_R, h = KNOB_Z1 - DIAL_Z1);
      for (k = [0 : 29]) rotate([0, 0, 12 * k]) translate([KNOB_R + 0.3, 0, 2]) cylinder(r = 1.2, h = 40, $fn = 12);
    }
  }
  translate([0, 0, DIAL_Z0 - CAM_MID - 1]) cylinder(r = SPINDLE_R + 0.1, h = KNOB_Z1 - DIAL_Z0 - 5, $fn = 48);
}
// the dial's marks: raised 0.6 mm on its face (print them in a second
// colour, or paint them). Number n stands at 90 - 3.6 n degrees: under the
// index at the top when the dial has turned n numbers left.
module dialMarks() translate([0, 0, DIAL_Z1 - CAM_MID]) {
  for (n = [0 : 99]) rotate([0, 0, 90 - 3.6 * n]) {
    l = (n % 10 == 0) ? 6 : (n % 5 == 0) ? 4.5 : 3;
    translate([DIAL_R - 1.2 - l, -0.45, 0]) cube([l, 0.9, 0.6]);
  }
  // the tens, each upright when it is under the index
  for (n = [0 : 10 : 90]) rotate([0, 0, 90 - 3.6 * n]) translate([DIAL_R - 13, 0, 0]) rotate([0, 0, -90])
    linear_extrude(0.6) text(str(n), size = 5.2, font = FONT, halign = "center", valign = "center");
}

// ---------------------------------------------------------------------
// the fixed parts, in the lock's frame
// ---------------------------------------------------------------------
module base() translate([BASE_X0, TABLE_Y, -BACK_T]) cube([BACK_X1 - BASE_X0, BASE_T, STAND_Z1 + BACK_T + 14]);
module backPlate() {
  difference() {
    translate([BACK_X0, TABLE_Y + BASE_T, -BACK_T]) cube([BACK_X1 - BACK_X0, BACK_Y1 - TABLE_Y - BASE_T, BACK_T]);
    translate([0, 0, -BACK_T - 1]) cylinder(r = POST_R - 2, h = BACK_T + 2, $fn = 32);
  }
  // the wheel post: a 12 mm tube, wheels and washers on it; a groove for the e-clip in front of wheel 3
  difference() {
    cylinder(r = POST_R, h = POST_Z1, $fn = 48);
    translate([0, 0, -1]) cylinder(r = 2, h = POST_Z1 + 2, $fn = 16);
    translate([0, 0, Z_W[2] + T_W + 1.1]) difference() { cylinder(r = POST_R + 1, h = 1.8, $fn = 48); translate([0, 0, -1]) cylinder(r = POST_R - 0.6, h = 4, $fn = 48); }
  }
}
module washers() {                      // (on the post: behind wheel 1, between the wheels)
  for (z = [Z_W[0] - 3, Z_W[1] - 3, Z_W[2] - 3]) translate([0, 0, z]) washer();
  translate([0, 0, Z_W[2] + T_W + 1.2]) difference() { cylinder(r = 10, h = 1.6, $fn = 48); translate([0, 0, -1]) cylinder(r = POST_R - 0.5, h = 4, $fn = 48); }
}
// the front standard: the door, as it were; the spindle's bearing, and the index
module standard() {
  difference() {
    union() {
      translate([-28, TABLE_Y + BASE_T, STAND_Z0]) cube([56, AXIS_H + 47 - BASE_T, STAND_Z1 - STAND_Z0]);
      translate([-28, TABLE_Y + BASE_T, STAND_Z0 - 10]) cube([56, 4, STAND_Z1 - STAND_Z0 + 20]);
    }
    translate([0, 0, STAND_Z0 - 1]) cylinder(r = SPINDLE_R + 0.3, h = 20, $fn = 48);
  }
  // the index: an arm over the dial's top, a point down to its marks
  translate([-6, DIAL_R + 2, STAND_Z1 - 1]) cube([12, 5, DIAL_Z1 - STAND_Z1 + 3.5]);
  translate([0, 0, DIAL_Z1 + 0.8]) linear_extrude(1.7)
    polygon([[-4.5, DIAL_R + 4], [4.5, DIAL_R + 4], [0, DIAL_R - 4.5]]);
}
// the bolt's guides: two brackets on the back plate the bolt slides through
module guide(x) difference() {
  translate([x - 6, ROD_Y - BOLT_W / 2 - 4, 0]) cube([12, BOLT_W + 8, BOLT_Z1 + 4]);
  translate([x - 7, ROD_Y - BOLT_W / 2 - 0.3, BOLT_Z0 - 0.3]) cube([14, BOLT_W + 0.6, BOLT_Z1 - BOLT_Z0 + 0.6]);
  translate([x - 7, ROD_Y - BOLT_W / 2 - 0.3, -1]) cube([14, BOLT_W + 0.6, BOLT_Z0 - 2]);
}
module guides() { guide(-82); guide(-106); }
// the keeper: the door frame's strike, which the bolt goes into
KEEP_X0 = -146; KEEP_X1 = -114;
module keeper() difference() {
  translate([KEEP_X0, TABLE_Y + BASE_T, BOLT_Z0 - 10]) cube([KEEP_X1 - KEEP_X0, ROD_Y + BOLT_W / 2 + 12 - TABLE_Y - BASE_T, BOLT_Z1 - BOLT_Z0 + 20]);
  translate([KEEP_X1 - 14, ROD_Y - BOLT_W / 2 - 0.6, BOLT_Z0 - 0.6]) cube([16, BOLT_W + 1.2, BOLT_Z1 - BOLT_Z0 + 1.2]);
}

// ---------------------------------------------------------------------
// the bolt (its origin at the pivot, thrown) and the lever (its origin at
// the pivot): they move
// ---------------------------------------------------------------------
module bolt() difference() {
  translate([0, 0, BOLT_Z0]) linear_extrude(BOLT_Z1 - BOLT_Z0) union() {
    E = BOLT_END - PIVOT_X;               // (its end, its top corner bevelled)
    polygon([[E, -BOLT_W / 2], [0, -BOLT_W / 2], [0, BOLT_W / 2], [E + 3, BOLT_W / 2], [E, BOLT_W / 2 - 3]]);
    circle(r = BOLT_W / 2, $fn = 48);
  }
  translate([0, 0, BOLT_Z0 - 1]) cylinder(d = 4.1, h = 30, $fn = 24);
}
module pivotPin() translate([0, 0, BOLT_Z0 - 1]) cylinder(d = 4, h = LEVER_Z1 - BOLT_Z0 + 2.5, $fn = 24);
// the lever's spring: a torsion spring on the pivot pin, behind the lever,
// one leg on the bolt and one under the lever, pressing it down (bought)
module torsionSpring() for (k = [0 : 3]) translate([0, 0, BOLT_Z1 + 0.15 + 0.2 + k * 0.2])
  rotate_extrude($fn = 24) translate([2.6, 0]) circle(r = 0.2, $fn = 8);
module lever() difference() {
  translate([0, 0, LEVER_Z0]) linear_extrude(LEVER_Z1 - LEVER_Z0) hull() {
    circle(r = 6, $fn = 48);
    translate([-PIVOT_X, 0]) circle(r = 5, $fn = 48);
  }
  translate([0, 0, LEVER_Z0 - 1]) cylinder(d = 4.2, h = 10, $fn = 24);
  translate([-PIVOT_X, 0, LEVER_Z0 - 1]) cylinder(d = ROD_D - 0.1, h = 10, $fn = 24);   // (the fence, pressed in)
}
// the fence: a 4 mm steel rod, cut to length
module rod() translate([-PIVOT_X, 0, ROD_Z0]) cylinder(d = ROD_D, h = ROD_Z1 - ROD_Z0, $fn = 32);

// ---------------------------------------------------------------------
// the slate (the script's, said so on its placard: it shows the working),
// behind the lock, raised; and the operator's fingers on the knob
// ---------------------------------------------------------------------
SLATE_W = 340; SLATE_H = 150; SLATE_T = 6; SLATE_Z = -60; SLATE_Y0 = 140;   // (its board: y above the table)
SLATE_X = -45;
module slate() translate([SLATE_X, TABLE_Y, SLATE_Z]) {
  translate([-SLATE_W / 2, SLATE_Y0, 0]) cube([SLATE_W, SLATE_H, SLATE_T]);
}
module slateFrame() translate([SLATE_X, TABLE_Y, SLATE_Z]) difference() {
  translate([-SLATE_W / 2 - 8, SLATE_Y0 - 8, -2]) cube([SLATE_W + 16, SLATE_H + 16, SLATE_T + 2]);
  translate([-SLATE_W / 2, SLATE_Y0, -3]) cube([SLATE_W, SLATE_H, SLATE_T + 4]);
}
module slatePost() {                   // one of its two posts, on its foot
  translate([-6, 0, -3]) cube([12, SLATE_Y0, 10]);
  translate([-20, 0, -20]) cube([40, 6, 44]);
}
module slateStand() translate([SLATE_X, TABLE_Y, SLATE_Z])
  for (s = [-1, 1]) translate([s * (SLATE_W / 2 - 40), 0, 0]) slatePost();
// a thumb and a finger pinching the knob, about the axis, at the dial's body's origin
module fingers() for (s = [-1, 1]) rotate([0, 0, 90 + s * 62]) {
  translate([KNOB_R + 2.5, 0, KNOB_Z1 - CAM_MID - 5]) hull() {     // (the tip, on the knurl)
    sphere(r = 3.2, $fn = 20);
    translate([5, 0, 7]) sphere(r = 3.8, $fn = 20);
  }
  translate([KNOB_R + 7.5, 0, KNOB_Z1 - CAM_MID + 2]) hull() {     // (the next joint, toward you)
    sphere(r = 3.8, $fn = 20);
    translate([4, 0, 11]) sphere(r = 4.6, $fn = 20);
  }
}

// ---------------------------------------------------------------------
// the whole, for pictures: the lock set to the combination its gates make
// ---------------------------------------------------------------------
GATES = [317.7611, 204.5593, 277.5204];       // (31-72-46: lua lock.lua gates 31 72 46)
module assembly(dial = 0) {
  color("#2f3a34") { base(); backPlate(); standard(); guides(); keeper(); }
  color("#aaaaaa") washers();
  for (i = [0 : 2]) translate([0, 0, Z_W[i] + T_W / 2]) { color("#c9a24a") wheel(GATES[i], i + 1); color("#b0b4b8") rotate([0, 0, PIN_AT]) translate([PIN_R, 0, 0]) pin(); }
  translate([0, 0, CAM_MID]) rotate([0, 0, 3.6 * dial]) { color("#9a7434") cam(); color("#b0b4b8") { camPin(); spindle(); } color("#1d1d1f") dialFace(); color("#e8d48a") dialMarks(); }
  translate([PIVOT_X, ROD_Y, 0]) { color("#b8bcc0") bolt(); color("#3d4a42") lever(); color("#d0d4d8") { rod(); pivotPin(); } }
}

// (for make-stls.sh: each part turned to lie on the printer's bed)
PART = "";
GATE = 0; WHEEL_N = 1;
if (PART == "wheel") translate([0, 0, T_W / 2]) rotate([180, 0, 0]) wheel(GATE, WHEEL_N);   // (its numbered face down)
if (PART == "cam") translate([0, 0, T_C / 2]) cam();
if (PART == "dial") translate([0, 0, KNOB_Z1 - CAM_MID]) rotate([180, 0, 0]) dialFace();  // (the knob down)
if (PART == "dial-marks") translate([0, 0, -(DIAL_Z1 - CAM_MID)]) dialMarks();
if (PART == "washer") translate([0, 0, 2.7]) washer();
if (PART == "back-plate") translate([0, 0, BACK_T]) backPlate();             // (on its back, the post up)
if (PART == "base") rotate([90, 0, 0]) translate([0, -TABLE_Y, 0]) base();           // (flat)
if (PART == "standard") translate([0, 0, -STAND_Z0 + 10]) standard();       // (its back down: the foot's back runs 10 mm behind)
if (PART == "guide") translate([82, 0, 0]) guide(-82);
if (PART == "keeper") rotate([90, 0, 0]) translate([0, -TABLE_Y - BASE_T, 0]) keeper();   // (standing)
if (PART == "bolt") translate([0, 0, -BOLT_Z0]) bolt();
if (PART == "lever") translate([0, 0, -LEVER_Z0]) lever();
module halfSlate(lo) intersection() { children(); translate([lo ? SLATE_X - 500 : SLATE_X, -500, -500]) cube([500, 1000, 1000]); }
if (PART == "slate-left") translate([0, 0, -SLATE_Z]) halfSlate(true) slate();          // (flat)
if (PART == "slate-right") translate([0, 0, -SLATE_Z]) halfSlate(false) slate();
if (PART == "slate-frame-left") translate([0, 0, -SLATE_Z + 2]) halfSlate(true) slateFrame();
if (PART == "slate-frame-right") translate([0, 0, -SLATE_Z + 2]) halfSlate(false) slateFrame();
if (PART == "slate-stand") rotate([90, 0, 0]) slatePost();                               // (standing on its foot)
if (PART == "assembly") assembly();
