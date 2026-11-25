// spaghetti-sort.scad -- Babbage's Hall, the spaghetti sort (the bead
// sort's second way)
//
// A. K. Dewdney's spaghetti sort (1984): cut a strand of spaghetti to the
// length of each number, gather them in your fist and stand the bundle on
// the table, so that their lower ends are level. Lower your other hand
// flat onto them: the first strand it touches is the longest. Take it out,
// lower the hand on, and the next it touches is the next longest.
//
// Here the strands are printed rods, a number n cut 30 + 12 n mm long, so
// that 0 has a rod too. The fist is a rack: a base plate the rods stand on
// (the table that levels them), a notched strip on it for their feet, and
// a comb whose slots, open toward you, hold them upright. The flat hand is the palm: a board on a post, lowered by
// the operator's hand; the rods are taken out of their slots toward you.
//
// Millimetres. x across (slot 1 at the left), y up from the table, z
// toward you. spaghetti-sort.lua puts the rack on the table.
//
// Printed: the rods, the base in two halves, the comb, the post, the palm,
// the knob. Bought: nothing. The slate is the bead sort's.

NSLOT = 8;            // slots: numbers at most
PITCH = 26;           // slot to slot
ROD_D = 8;            // a rod across
ROD_L0 = 30;          // the rod for 0 ...
ROD_U = 12;           // ... and each unit more
function rodL(n) = ROD_L0 + ROD_U * n;
function slotX(k) = (k - (NSLOT + 1) / 2) * PITCH;   // slot k, 1 the leftmost

BASE_T = 6;           // the base plate, which the rods stand on
BASE_X0 = -120; BASE_X1 = 152;   // ... its ends (the post at the right)
BASE_Z0 = -40; BASE_Z1 = 20;     // ... back and front
ZC = -10;             // the comb's slots' back wall
COMB_Y0 = 20; COMB_Y1 = 26;      // the comb, its lower and upper face
COMB_Z0 = ZC - 12; COMB_Z1 = ZC + 16;
SLOT_W = ROD_D + 1;   // a slot, across: half a millimetre either side
ROD_Z = ZC + ROD_D / 2 + 0.5;    // the rods' axes, upright: half a millimetre in front of the slots' back
STOP_Z = ROD_Z + ROD_D / 2 + 0.3;  // the notches' front: the feet's, and a little
STOP_H = 3;           // the feet's strip: a notch for each foot, open at the back
NOTCH_W = ROD_D + 0.6;  // ... 0.3 mm either side: a rod can lean at most 2.3 degrees, and stands up again
POST_X = 141; POST_W = 12;       // the palm's post, at the right
POST_H = 190;

// the palm: a flat board, its lower face at y = 0 here (the script lowers
// it), across every slot, with an arm to a sleeve on the post
PALM_W = 250; PALM_T = 6; PALM_D = 40;
PALM_Z = ZC - 4;      // its middle, front to back
KNOB_X = 115;         // the knob the hand lowers it by, near its right end
module palm() {
  translate([-PALM_W / 2, 0, PALM_Z - PALM_D / 2]) cube([PALM_W, PALM_T, PALM_D]);
  // the arm and the sleeve round the post (printed with it)
  translate([PALM_W / 2 - 2, 0, ZC - 6]) cube([POST_X - POST_W / 2 - PALM_W / 2 - 1, PALM_T, 12]);
  difference() {
    translate([POST_X - POST_W / 2 - 4, 0, ZC - POST_W / 2 - 4]) cube([POST_W + 8, 24, POST_W + 8]);
    translate([POST_X - POST_W / 2 - 0.4, -1, ZC - POST_W / 2 - 0.4]) cube([POST_W + 0.8, 26, POST_W + 0.8]);
  }
}
// the knob the hand lowers it by
module knob() translate([KNOB_X, PALM_T, PALM_Z]) {
  rotate([-90, 0, 0]) cylinder(d = 8, h = 8, $fn = 24);
  translate([0, 8 + 5, 0]) sphere(d = 14, $fn = 32);
}

// a rod, along +z from its foot (the script stands it up)
module rod(n) {
  L = rodL(n);
  hull() {
    translate([0, 0, 0.6]) cylinder(d = ROD_D, h = L - 1.2, $fn = 24);
    cylinder(d = ROD_D - 1.2, h = L, $fn = 24);
  }
}
// the number on a rod: a band of colour (drawn by the script) is enough;
// the figure is engraved on its foot end
module rodPrint(n) difference() {
  rod(n);
  translate([0, 0, -0.01]) linear_extrude(0.6) mirror([1, 0, 0])
    text(str(n), size = 5, font = "DejaVu Sans:style=Bold", halign = "center", valign = "center");
}

// the rack: the base plate with the feet's strip, the comb on two cheeks,
// the post
module base() {
  translate([BASE_X0, 0, BASE_Z0]) cube([BASE_X1 - BASE_X0, BASE_T, BASE_Z1 - BASE_Z0]);
  difference() {
    translate([slotX(1) - PITCH / 2, BASE_T - 0.01, STOP_Z - 12]) cube([NSLOT * PITCH, STOP_H, 16]);
    for (k = [1 : NSLOT]) translate([slotX(k) - NOTCH_W / 2, BASE_T - 1, STOP_Z - 13]) cube([NOTCH_W, STOP_H + 2, 13]);
  }
}
module comb() difference() {
  union() {
    translate([slotX(1) - PITCH / 2 - 8, COMB_Y0, COMB_Z0]) cube([NSLOT * PITCH + 16, COMB_Y1 - COMB_Y0, COMB_Z1 - COMB_Z0]);
    // its cheeks, down to the base
    for (e = [-1, 1]) translate([e * (NSLOT * PITCH / 2 + 4) - 4, BASE_T - 0.01, COMB_Z0]) cube([8, COMB_Y0 - BASE_T + 0.02, COMB_Z1 - COMB_Z0]);
  }
  for (k = [1 : NSLOT]) translate([slotX(k) - SLOT_W / 2, COMB_Y0 - 1, ZC]) cube([SLOT_W, COMB_Y1 - COMB_Y0 + 2, COMB_Z1 - ZC + 1]);
}
module post() translate([POST_X - POST_W / 2, BASE_T - 0.01, ZC - POST_W / 2]) cube([POST_W, POST_H, POST_W]);
module rack() { base(); comb(); post(); }

// the printed parts, each turned to lie on the bed (make-stls.sh), all
// under 200 mm: the base, the comb and the palm each in two halves, cut at
// x = 0 (a tooth's middle, on the comb), glued. (Here y is up; on the
// printer's bed z is: rotate([90, 0, 0]) turns one into the other.)
PART = "";
N = 0;                // which rod
module half(e, x0, x1) intersection() {
  children();
  translate([e > 0 ? 0 : x0 - 1, -300, -300]) cube([e > 0 ? x1 + 1 : 1 - x0, 600, 600]);
}
if (PART == "rod") rodPrint(N);                                              // foot down, its figure on the bed
if (PART == "base-left") rotate([90, 0, 0]) half(-1, BASE_X0, BASE_X1) base();
if (PART == "base-right") rotate([90, 0, 0]) half(1, BASE_X0, BASE_X1) base();
// (the comb upside down, its top face on the bed)
if (PART == "comb-left") translate([0, 0, COMB_Y1]) rotate([-90, 0, 0]) half(-1, -200, 200) comb();
if (PART == "comb-right") translate([0, 0, COMB_Y1]) rotate([-90, 0, 0]) half(1, -200, 200) comb();
// (the post on its side)
if (PART == "post") translate([0, 0, -(ZC - POST_W / 2)]) rotate([0, 0, -90]) translate([-POST_X, 0, 0]) post();
// (the palm's board on the bed, its knuckle side up)
if (PART == "palm-left") rotate([90, 0, 0]) half(-1, -200, 200) palm();
if (PART == "palm-right") rotate([90, 0, 0]) half(1, -200, 200) palm();
if (PART == "knob") translate([-KNOB_X, PALM_Z, 0]) rotate([90, 0, 0]) translate([0, -PALM_T, 0]) knob();
