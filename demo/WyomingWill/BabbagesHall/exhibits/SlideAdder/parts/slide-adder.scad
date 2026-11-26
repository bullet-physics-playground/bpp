// slide-adder.scad -- Babbage's Hall, the slide adder (Troncet's
// arithmographe, 1889; the Addiator, 1920)
//
// Six bands slide up and down behind a cover. Each band carries a row of
// pegs along its left edge, a step (8 mm) apart, and the digits 0 to 9 on
// its face, one of which shows in the column's window. The cover has a slot
// over each row of pegs, and the slots are joined at the top and at the
// bottom by channels. The stylus goes through a slot into the gap between
// two pegs, and moves the band with it.
//
// To add d in a column, put the stylus in the gap beside the d on the
// cover (d steps above the slot's bottom) and draw it down to the bottom:
// the band goes down d steps, and its window shows d more. If the gap is
// red (the band is already so far down that d more would pass 9), push it
// up to the top instead: the band goes up 10 - d steps, which shows d more
// less ten; then along the top channel into the next slot to the left, and
// down one step: that is the carry. Subtracting is the same upside down,
// from the digits on the slot's other side, borrowing along the bottom.
//
// Millimetres. x across (column 1, the units, at the right), y up from
// the table, z toward you. slide-adder.lua stands it on the table.
//
// Printed: the six bands, the cover and the back in halves, the zeroing
// bar, the stylus, two feet. Bought: nothing. The labels are printed on
// paper and glued on the cover (labels/).

NCOL = 6;             // columns
P = 8;                // a step: peg to peg
RP = 2;               // a peg's radius
NPEG = 21;            // pegs on a band: the gaps between them are 0 to 19
W = 24;               // column to column
S = 4;                // a slot's width
Y0 = 120;             // the slots' bottom (a band's gap 0, when it reads 0)
YT = Y0 + 10 * P;     // their top: the top channel
function colX(j) = ((NCOL + 1) / 2 - j) * W;     // column j, 1 the units (rightmost)
XL = colX(NCOL) - 15; XR = colX(1) + 30;         // the case's sides

// depths (z): the back, the bands' bodies, their pegs, the cover
BACK_Z0 = -9.5; BACK_Z1 = -6.5;
BODY_Z0 = -6; BODY_Z1 = -3.5;
PEG_Z0 = -3.5; PEG_Z1 = 0;
COVER_Z0 = 0.5; COVER_Z1 = 3.5;

// a band, reading 0 (at its top). Its body runs right of its pegs; the
// digits 0..9 are on it, 0 in the window when it reads 0
YW = Y0 - 16;         // the windows' middle
BAND_X0 = -2.5; BAND_X1 = 19.5;   // its body, from its pegs' line
YB = YW - 6;          // its foot, which the zeroing bar lifts
YBT = Y0 + (NPEG - 0.5) * P + 3;  // its top
TRAVEL = 9 * P;       // reading 0 (up) to 9 (down)
DIGIT_X = 10;         // the digits' line, from the pegs'
module bandBody() translate([BAND_X0, YB, BODY_Z0]) cube([BAND_X1 - BAND_X0, YBT - YB, BODY_Z1 - BODY_Z0]);
module bandPegs() for (i = [0 : NPEG - 1]) translate([0, Y0 + (i - 0.5) * P, PEG_Z0 - 0.01]) cylinder(r = RP, h = PEG_Z1 - PEG_Z0 + 0.01, $fn = 20);
// (the red behind the gaps 10 and over: gaps there mean "too far: up and over")
RED_Y0 = Y0 + 9.5 * P;
module bandRed() translate([-RP - 0.5, RED_Y0, BODY_Z1 - 0.01]) cube([2 * RP + 1, YBT - 3 - RED_Y0, 0.2]);
module band() { bandBody(); bandPegs(); }

// the cover: a plate with the slots, the channels joining them, and a
// window for each column. The channels along the top and the bottom cut
// the plate between two slots off on every side: each such island is a
// part of its own, held by two studs on the rib behind it (back())
ISL_Y0 = Y0 + S / 2; ISL_Y1 = YT - S / 2;        // an island, between the channels
function islX0(j) = colX(j + 1) + S / 2;         // island j: between slots j + 1 and j
function islX1(j) = colX(j) - S / 2;
module island(j) translate([islX0(j), ISL_Y0, COVER_Z0]) cube([islX1(j) - islX0(j), ISL_Y1 - ISL_Y0, COVER_Z1 - COVER_Z0]);
module coverFrame() difference() {
  coverPlate();
  for (j = [1 : NCOL - 1]) translate([islX0(j) - 0.01, ISL_Y0 - 0.01, COVER_Z0 - 1]) cube([islX1(j) - islX0(j) + 0.02, ISL_Y1 - ISL_Y0 + 0.02, COVER_Z1 - COVER_Z0 + 2]);
}
module cover() { coverFrame(); for (j = [1 : NCOL - 1]) island(j); }
module coverPlate() difference() {
  translate([XL, YCB, COVER_Z0]) cube([XR - XL, YCT - YCB, COVER_Z1 - COVER_Z0]);
  for (j = [1 : NCOL]) {
    translate([colX(j), 0, 0]) hull() {
      translate([0, Y0, COVER_Z0 - 1]) cylinder(d = S, h = 5, $fn = 16);
      translate([0, YT, COVER_Z0 - 1]) cylinder(d = S, h = 5, $fn = 16);
    }
    translate([colX(j) + DIGIT_X - 4.5, YW - 3.5, COVER_Z0 - 1]) cube([9, 7, 5]);
  }
  for (y = [Y0, YT]) hull() {
    translate([colX(NCOL), y, COVER_Z0 - 1]) cylinder(d = S, h = 5, $fn = 16);
    translate([colX(1), y, COVER_Z0 - 1]) cylinder(d = S, h = 5, $fn = 16);
  }
  // the zeroing bar's tab, through a slot at the right
  translate([XR - 12, YBAR - 5, COVER_Z0 - 1]) cube([6, YB - YBAR + 9, 5]);
}
YCB = YB - TRAVEL - 18;          // the case's foot
YCT = YBT + 6;                   // its top
// the back: a plate with ribs between the bands, and the sides that hold the
// cover off it
RIB_W = 1.2;
RIB_Y0 = YB + 2;
function ribX(j) = j <= NCOL ? colX(j) + BAND_X0 - 1.6 : colX(1) + BAND_X1 + 0.4;   // left of band j; and right of band 1
STUD_Y = [ISL_Y0 + 10, ISL_Y1 - 10];             // the studs that hold the islands, on the ribs under them
module back() {
  translate([XL, YCB, BACK_Z0]) cube([XR - XL, YCT - YCB, BACK_Z1 - BACK_Z0]);
  // (the ribs from just above a band's foot when it reads 0: every band
  // always covers that height, and below it the zeroing bar runs free)
  for (j = [1 : NCOL + 1]) translate([ribX(j), RIB_Y0, BACK_Z1 - 0.01]) cube([RIB_W, YCT - RIB_Y0, BODY_Z1 - BACK_Z1]);
  for (j = [1 : NCOL - 1], y = STUD_Y) translate([ribX(j), y - 4, BODY_Z1 - 0.01]) cube([RIB_W, 8, COVER_Z0 - BODY_Z1 + 0.02]);
  for (x = [XL, XR - 4]) translate([x, YCB, BACK_Z1 - 0.01]) cube([4, YCT - YCB, COVER_Z0 - BACK_Z1 + 0.02]);
  translate([XL, YCB, BACK_Z1 - 0.01]) cube([XR - XL, 4, COVER_Z0 - BACK_Z1 + 0.02]);
  translate([XL, YCT - 4, BACK_Z1 - 0.01]) cube([XR - XL, 4, COVER_Z0 - BACK_Z1 + 0.02]);
}

// the zeroing bar: under the bands' feet, lifted by its tab to put every
// band to 0, then let down again
YBAR = YB - TRAVEL - 6;          // its top, at rest
module bar() {
  translate([colX(NCOL) + BAND_X0, YBAR - 4, BODY_Z0]) cube([colX(1) + BAND_X1 - colX(NCOL) - BAND_X0, 4, BODY_Z1 - BODY_Z0]);
  translate([colX(1) + BAND_X1 - 0.01, YBAR - 4, BODY_Z0]) cube([XR - 9 - colX(1) - BAND_X1, 4, BODY_Z1 - BODY_Z0]);
  translate([XR - 11, YBAR - 4, BODY_Z0]) cube([4, 4, COVER_Z1 + 6 - BODY_Z0]);
  translate([XR - 9, YBAR - 2, COVER_Z1 + 6]) sphere(d = 9, $fn = 24);
}

// the stylus: a pen, its tip at the origin, its shank along +z
module stylus() {
  sphere(d = 3, $fn = 16);
  cylinder(d = 3, h = 6, $fn = 16);
  translate([0, 0, 6]) cylinder(d1 = 3, d2 = 7, h = 8, $fn = 20);
  translate([0, 0, 14]) cylinder(d = 7, h = 50, $fn = 20);
}
// the operator's finger, its tip at the origin, along +z
module finger() {
  hull() {
    sphere(d = 14, $fn = 24);
    translate([0, 0, 60]) sphere(d = 17, $fn = 24);
  }
  translate([0, -5.2, 6]) rotate([-12, 0, 0]) scale([1, 0.35, 1]) cylinder(d = 10, h = 12, $fn = 20);
}

// two feet hold the case upright on the table
module foot(e) translate([e > 0 ? XR - 4 : XL, 0, 0]) difference() {
  translate([0, 0, -40]) cube([4, YCB + 30, 80]);
  translate([-1, YCB + 0.01, BACK_Z0 - 0.2]) cube([6, 40, COVER_Z1 - BACK_Z0 + 0.4]);
}

// the slate: a board in a frame on two legs, its face toward +z
SLATE_W = 180; SLATE_H = 130; SLATE_T = 6; SLATE_Y = 90;
module slate() translate([-SLATE_W / 2, SLATE_Y, -SLATE_T]) cube([SLATE_W, SLATE_H, SLATE_T]);
module slateFrame() {
  difference() {
    translate([-SLATE_W / 2 - 8, SLATE_Y - 8, -SLATE_T - 2]) cube([SLATE_W + 16, SLATE_H + 16, SLATE_T + 3]);
    translate([-SLATE_W / 2, SLATE_Y, -SLATE_T - 3]) cube([SLATE_W, SLATE_H, SLATE_T + 5]);
  }
  for (e = [-1, 1]) translate([e * (SLATE_W / 2 - 20) - 5, 0, -SLATE_T - 2]) cube([10, SLATE_Y - 7, 6]);
  translate([-SLATE_W / 2 + 10, 0, -40]) cube([SLATE_W - 20, 6, 50]);
}

// the printed parts, each turned to lie on the bed (make-stls.sh)
PART = "";
module halfY(lower, cut) intersection() {
  children();
  translate([-500, lower ? -500 : cut, -500]) cube([1000, lower ? 500 + cut : 1000, 1000]);
}
YCUT = Y0 - 10;                  // the cover and the back are printed in halves, cut here (below the slots)
if (PART == "band") translate([0, -YB, -BODY_Z0]) band();                  // its back on the bed, its pegs up
// (the cover face down; the back on its back)
if (PART == "cover-lower") translate([0, -YCB, COVER_Z1]) mirror([0, 0, 1]) halfY(true, YCUT) coverFrame();
if (PART == "cover-upper") translate([0, -YCUT, COVER_Z1]) mirror([0, 0, 1]) halfY(false, YCUT) coverFrame();
if (PART == "island") translate([-islX0(1), -ISL_Y0, COVER_Z1]) mirror([0, 0, 1]) island(1);   // (all five alike)
if (PART == "back-lower") translate([0, -YCB, -BACK_Z0]) halfY(true, YCUT) back();
if (PART == "back-upper") translate([0, -YCUT, -BACK_Z0]) halfY(false, YCUT) back();
if (PART == "bar") translate([0, -YBAR + 4, -BODY_Z0]) bar();
if (PART == "stylus") translate([0, 0, 1.5]) stylus();
if (PART == "foot-left") rotate([0, -90, 0]) translate([-XL, 0, 0]) foot(-1);
if (PART == "foot-right") rotate([0, -90, 0]) translate([-(XR - 4), 0, 0]) foot(1);
