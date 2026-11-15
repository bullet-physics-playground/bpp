// suanpan.scad -- Babbage's Hall, the suanpan (the Chinese abacus)
//
// Seven rods, each with two heaven beads above the beam (the reckoning bar)
// and five earth beads below it. A bead counts when it is at the beam: a
// heaven bead 5, an earth bead 1. Millimetres. The abacus lies on the
// table: x across the rods (the units rod on the right), y along them (the
// heaven beads at +y, away from the person working it), z up from the
// table. suanpan.lua turns it into the hall's frame and puts the beads on
// the rods.
//
// Printed: the frame (four bars and the beam, glued; each under 200 mm),
// the 49 beads, the slate (its board and its frame each in two halves). Bought: seven 3 mm steel
// rods, 136 mm long. README.md has the parts and how they go together.

ROD_N = 7;            // rods
PITCH = 24;           // rod to rod
BEAD_D = 20;          // a bead across its middle
BEAD_T = 12;          // ... and along its rod
BEAD_END = 8;         // its flat ends, across
ROD_D = 3;            // steel rods
HOLE_D = 3.4;         // the beads' holes
BAR_W = 12;           // the frame's bars: width
BAR_H = 24;           //   and height
BEAM_W = 8;           // the beam (the reckoning bar), along the rods
HEAVEN_L = 2 * BEAD_T + 14;     // the decks, inside: room for the beads and to move
EARTH_L = 5 * BEAD_T + 14;
ROD_Z = BAR_H / 2;    // the rods, above the table
LEN = 2 * BAR_W + HEAVEN_L + BEAM_W + EARTH_L;   // the frame, along the rods
WID = ROD_N * PITCH + 2 * BAR_W;                 // ... and across
Y0 = -LEN / 2;                                   // its near edge
BEAM_Y = Y0 + BAR_W + EARTH_L;                   // the beam's near face
function rodX(i) = (i - (ROD_N + 1) / 2) * PITCH; // rod i, 1 the leftmost

// the frame: two end bars, two side bars, the beam; the rods' holes
module frame() difference() {
  union() {
    translate([-WID / 2, Y0, 0]) cube([WID, BAR_W, BAR_H]);                       // near bar
    translate([-WID / 2, -Y0 - BAR_W, 0]) cube([WID, BAR_W, BAR_H]);              // far bar
    for (s = [-1, 1]) translate([s > 0 ? WID / 2 - BAR_W : -WID / 2, Y0, 0]) cube([BAR_W, LEN, BAR_H]);
    translate([-WID / 2, BEAM_Y, 2]) cube([WID, BEAM_W, BAR_H - 4]);             // the beam
  }
  for (i = [1 : ROD_N]) translate([rodX(i), Y0 + 4, ROD_Z]) rotate([-90, 0, 0]) cylinder(d = ROD_D + 0.2, h = LEN - 8, $fn = 16);
}
// (no dots on the beam: a dot every third rod is the Japanese soroban's)
// the rods, steel
module rods() for (i = [1 : ROD_N])
  translate([rodX(i), Y0 + 4, ROD_Z]) rotate([-90, 0, 0]) cylinder(d = ROD_D, h = LEN - 8, $fn = 12);
// a bead: two cones back to back, along y, its middle at the origin
module bead() difference() {
  rotate([-90, 0, 0]) union() {
    cylinder(d1 = BEAD_END, d2 = BEAD_D, h = BEAD_T / 2, $fn = 32);
    translate([0, 0, -BEAD_T / 2]) cylinder(d1 = BEAD_D, d2 = BEAD_END, h = BEAD_T / 2, $fn = 32);
    mirror([0, 0, 1]) cylinder(d1 = BEAD_END, d2 = BEAD_D, h = BEAD_T / 2, $fn = 32);
  }
  rotate([-90, 0, 0]) translate([0, 0, -BEAD_T]) cylinder(d = HOLE_D, h = 2 * BEAD_T, $fn = 16);
}
// the operator's finger (drawn, not printed): along -z, its tip at the origin
module finger() {
  hull() {
    sphere(d = 14, $fn = 24);
    translate([0, 0, 60]) sphere(d = 17, $fn = 24);
  }
  // the nail
  translate([0, -5.2, 6]) rotate([-12, 0, 0]) scale([1, 0.35, 1]) cylinder(d = 10, h = 12, $fn = 20);
}
// the slate: a board in a frame, on a foot; its face toward -y, its foot on the table
SLATE_W = 280; SLATE_H = 170; SLATE_T = 8;
module slate() {
  translate([-SLATE_W / 2, 0, 20]) cube([SLATE_W, SLATE_T, SLATE_H]);
  // the foot
  translate([-SLATE_W / 2 + 20, -30, 0]) cube([SLATE_W - 40, 60 + SLATE_T, 6]);
  for (s = [-1, 1]) translate([s * (SLATE_W / 2 - 40) - 6, 0, 0]) cube([12, SLATE_T, 24]);
}
module slateFrame() difference() {
  translate([-SLATE_W / 2 - 8, -2, 12]) cube([SLATE_W + 16, SLATE_T + 2, SLATE_H + 16]);
  translate([-SLATE_W / 2, -3, 20]) cube([SLATE_W, SLATE_T + 4, SLATE_H]);
}

// (for make-stls.sh)
PART = "";
if (PART == "bead") rotate([90, 0, 0]) bead();
if (PART == "near") intersection() { frame(); translate([-WID / 2, Y0, 0]) cube([WID, BAR_W, BAR_H]); }
if (PART == "far") intersection() { frame(); translate([-WID / 2, -Y0 - BAR_W, 0]) cube([WID, BAR_W, BAR_H]); }
if (PART == "side") rotate([0, 0, 90]) intersection() { frame(); translate([-WID / 2, Y0 + BAR_W, 0]) cube([BAR_W, LEN - 2 * BAR_W, BAR_H]); }
if (PART == "beam") difference() { translate([-WID / 2 + BAR_W, BEAM_Y, 2]) cube([WID - 2 * BAR_W, BEAM_W, BAR_H - 4]); frame_rods(); }
module frame_rods() for (i = [1 : ROD_N]) translate([rodX(i), Y0 + 4, ROD_Z]) rotate([-90, 0, 0]) cylinder(d = ROD_D + 0.2, h = LEN - 8, $fn = 16);
// (the slate and its frame, each in two halves, left and right, glued; the
// board laid on its back to print)
module half(s) intersection() { children(); translate([s < 0 ? -200 : 0, -100, -1]) cube([200, 200, 300]); }
if (PART == "slate-left") rotate([-90, 0, 0]) half(-1) slate();
if (PART == "slate-right") rotate([-90, 0, 0]) half(1) slate();
if (PART == "slate-frame-left") rotate([-90, 0, 0]) half(-1) slateFrame();
if (PART == "slate-frame-right") rotate([-90, 0, 0]) half(1) slateFrame();
