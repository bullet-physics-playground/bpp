// bead-sort.scad -- Babbage's Hall, the bead sort
//
// Nine steel rods in a frame. A number from 0 to 9 is a row of beads, laid
// from the left: 3 is a bead on rods 1, 2 and 3. Up to eight numbers, one
// row each. Laid flat, the beads stay where they are put; turned upright,
// they slide down their rods, each as far as the beads below let it. Then
// the bottom row holds as many beads as the largest number, the next row
// the next largest, and so on: the rows are the numbers, sorted.
//
// Millimetres. The frame's own frame: x across the rods (rod 1 at the
// left), s along them from the hinge (its lower edge, when upright), h
// out of the frame's face (toward you, upright; up, flat). bead-sort.lua
// hinges it on its foot and puts the beads on the rods.
//
// Printed: the frame (two end bars, each in two halves, and two side
// bars, glued), the beads, the foot (in two halves), the rest, the knob.
// Bought: nine 3 mm steel rods, 116 mm long, and a 3 mm steel pin, 264 mm,
// for the hinge. The slate is the exhibit's own (drawn, not printed).
// README.md has the parts and how they go together.

NROD = 9;             // rods
PITCH = 26;           // rod to rod
NROW = 8;             // rows: numbers at most
BEAD_D = 20;          // a bead across
BEAD_T = 12;          // ... and along its rod
CHAMFER = 2;          // its edges
ROD_D = 3;            // steel rods
HOLE_D = 3.6;         // the beads' holes (loose: they slide down under their own weight)
BAR_W = 12;           // the frame's bars: width, along the rods (end bars) or across (side bars)
BAR_H = 22;           //   and depth, out of the face
ROD_H = BAR_H / 2;    // the rods, out of the frame's back
INNER = NROW * BEAD_T + 4;                       // the rods' clear length: eight beads and a little
LEN = INNER + 2 * BAR_W;                         // the frame, along the rods
WID = NROD * PITCH + 2 * BAR_W;                  // ... and across
S0 = BAR_W;                                      // the bottom bar's inner face (the beads' floor)
function rodX(i) = (i - (NROD + 1) / 2) * PITCH; // rod i, 1 the leftmost
function rowS(r) = S0 + (r - 0.5) * BEAD_T;      // row r's beads' middles, 1 the lowest

// the frame: end bars and side bars; the rods' holes; the hinge's
// knuckles under the bottom bar, at its ends
KNUCKLE_W = 16;       // a knuckle, across
PIN_D = 3;
HINGE_H = -6;         // the pin's axis: below the frame's back, at s = 0
module frame() difference() {
  union() {
    translate([-WID / 2, 0, 0]) cube([WID, BAR_W, BAR_H]);                        // bottom bar
    translate([-WID / 2, LEN - BAR_W, 0]) cube([WID, BAR_W, BAR_H]);              // top bar
    for (e = [-1, 1]) translate([e > 0 ? WID / 2 - BAR_W : -WID / 2, 0, 0]) cube([BAR_W, LEN, BAR_H]);
    for (e = [-1, 1]) translate([e * (WID / 2 - KNUCKLE_W / 2) - KNUCKLE_W / 2, 0, HINGE_H])
      hull() {
        cube([KNUCKLE_W, BAR_W, 1 - HINGE_H]);
        rotate([0, 90, 0]) cylinder(r = 6, h = KNUCKLE_W, $fn = 32);
      }
  }
  for (i = [1 : NROD]) translate([rodX(i), 4, ROD_H]) rotate([-90, 0, 0]) cylinder(d = ROD_D + 0.2, h = LEN - 8, $fn = 16);
  translate([-WID / 2 - 1, 0, HINGE_H]) rotate([0, 90, 0]) cylinder(d = PIN_D + 0.3, h = WID + 2, $fn = 16);
}
// the rods, steel
module rods() for (i = [1 : NROD])
  translate([rodX(i), 4, ROD_H]) rotate([-90, 0, 0]) cylinder(d = ROD_D, h = LEN - 8, $fn = 12);
// the knob, on the top bar's middle, for the hand
module knob() translate([0, LEN - BAR_W / 2, BAR_H]) {
  cylinder(d = 8, h = 8, $fn = 24);
  translate([0, 0, 8]) sphere(d = 14, $fn = 32);
}
// a bead: a short cylinder along s, chamfered, its middle at the origin
module bead() difference() {
  rotate([-90, 0, 0]) translate([0, 0, -BEAD_T / 2]) hull() {
    cylinder(d = BEAD_D - 2 * CHAMFER, h = BEAD_T, $fn = 48);
    translate([0, 0, CHAMFER]) cylinder(d = BEAD_D, h = BEAD_T - 2 * CHAMFER, $fn = 48);
  }
  rotate([-90, 0, 0]) translate([0, 0, -BEAD_T]) cylinder(d = HOLE_D, h = 2 * BEAD_T, $fn = 16);
}

// the foot: a plate on the table that the frame hinges on, with a knuckle
// at each end inside the frame's, and the stop the frame leans on upright.
// Its own frame: the pin's axis along x at the origin, z up, y toward
// the frame's flat side (away from you)
FOOT_D = 40;          // the plate, toward you and away
FOOT_T = 6;
PIN_Z = 14;           // the pin above the table
module foot() difference() {
  union() {
    translate([-WID / 2, -FOOT_D + 10, -PIN_Z]) cube([WID, FOOT_D, FOOT_T]);
    for (e = [-1, 1]) translate([e * (WID / 2 - KNUCKLE_W - 10) - 8, -6, -PIN_Z]) hull() {
      cube([16, 12, FOOT_T]);
      translate([0, 6, PIN_Z]) rotate([0, 90, 0]) cylinder(r = 6, h = 16, $fn = 32);
    }
    // the stop: a block toward you that the bottom bar's face meets upright
    translate([-40, -(BAR_H - HINGE_H) - 8.3, -PIN_Z]) cube([80, 8, PIN_Z + 4]);
  }
  translate([-WID / 2 - 1, 0, 0]) rotate([0, 90, 0]) cylinder(d = PIN_D + 0.3, h = WID + 2, $fn = 16);
}
// the rest the frame's top bar lies on, flat (on the table, under it)
module rest() translate([-30, LEN - BAR_W, -PIN_Z]) cube([60, BAR_W, PIN_Z - HINGE_H]);
module pin() translate([-WID / 2 - 3, 0, 0]) rotate([0, 90, 0]) cylinder(d = PIN_D, h = WID + 6, $fn = 12);

// the operator's finger (drawn, not printed): along -z, its tip at the origin
module finger() {
  hull() {
    sphere(d = 14, $fn = 24);
    translate([0, 0, 60]) sphere(d = 17, $fn = 24);
  }
  translate([0, -5.2, 6]) rotate([-12, 0, 0]) scale([1, 0.35, 1]) cylinder(d = 10, h = 12, $fn = 20);
}

// the slate: a board in a frame, on two legs and a foot; its face toward
// -y, its board above the upright frame (from SLATE_Z up)
SLATE_W = 300; SLATE_H = 170; SLATE_T = 8; SLATE_Z = 160;
module slate() {
  translate([-SLATE_W / 2, 0, SLATE_Z]) cube([SLATE_W, SLATE_T, SLATE_H]);
  translate([-SLATE_W / 2 + 20, -30, 0]) cube([SLATE_W - 40, 60 + SLATE_T, 6]);
  for (e = [-1, 1]) translate([e * (SLATE_W / 2 - 40) - 6, 0, 0]) cube([12, SLATE_T, SLATE_Z + 4]);
}
module slateFrame() difference() {
  translate([-SLATE_W / 2 - 8, -2, SLATE_Z - 8]) cube([SLATE_W + 16, SLATE_T + 2, SLATE_H + 16]);
  translate([-SLATE_W / 2, -3, SLATE_Z]) cube([SLATE_W, SLATE_T + 4, SLATE_H]);
}

// the printed parts, each turned to lie on the bed (make-stls.sh): the
// frame cut into its bars (each end bar in two halves: under 200 mm)
PART = "";
module cut(x0, x1, s0, s1) intersection() { frame(); translate([x0, s0, HINGE_H - 7]) cube([x1 - x0, s1 - s0, BAR_H - HINGE_H + 8]); }
// (the bottom bar's halves lie on their faces, the knuckles up)
module footHalf(e) intersection() { foot(); translate([e > 0 ? 0 : -WID / 2 - 1, -60, -PIN_Z - 1]) cube([WID / 2 + 1, 80, 40]); }
if (PART == "bead") translate([0, 0, BEAD_T / 2]) rotate([90, 0, 0]) bead();
if (PART == "bar-bottom-left") translate([0, 0, BAR_H]) rotate([180, 0, 0]) cut(-WID / 2 - 1, 0, -7, BAR_W);
if (PART == "bar-bottom-right") translate([0, 0, BAR_H]) rotate([180, 0, 0]) cut(0, WID / 2 + 1, -7, BAR_W);
if (PART == "bar-top-left") cut(-WID / 2 - 1, 0, LEN - BAR_W, LEN + 1);
if (PART == "bar-top-right") cut(0, WID / 2 + 1, LEN - BAR_W, LEN + 1);
if (PART == "bar-side") cut(-WID / 2 - 1, -WID / 2 + BAR_W, BAR_W + 0.01, LEN - BAR_W);
if (PART == "foot-left") translate([0, 0, PIN_Z]) footHalf(-1);
if (PART == "foot-right") translate([0, 0, PIN_Z]) footHalf(1);
if (PART == "rest") translate([0, 0, PIN_Z]) rest();
if (PART == "knob") translate([0, 0, -BAR_H]) knob();
