// linkages.scad -- Babbage's Hall, linkages that compute
//
// Hinged bars, flat on a board, that compute as they move:
//
//   Peaucellier's inverter (1864). Two arms of length L from a fixed pin O
//   hold opposite corners A and B of a rhombus of side S; its other
//   corners P and Q stay on one line through O, and OP x OQ = L^2 - S^2
//   whatever the shape. Here L^2 - S^2 = 100 (cm), so with P set at x on
//   the scale, Q stops at 100 / x.
//
//   Peaucellier's straight line. Put P on a crank whose circle passes
//   through O, and Q, the inverse of a circle through O, moves along a
//   straight line: the first linkage to draw an exact straight line.
//
//   A multiplier: a slotted lever through a fixed pin. A pin in its slot,
//   on a carriage at a fixed distance D across the board, tilts it to the
//   slope Y / D; a bridge at X along the board carries a cross carriage
//   whose pin rides the slot too, so it stands at X Y / D.
//
// Millimetres. x along the board (to the right), y up from the table, z
// toward you. linkages.lua puts the pieces on the board. The bars lie in
// planes 7 mm apart, 3 mm thick (Babbage's Hall follows the Walker Room's
// rule: bars hinged together are in different planes; bars that never
// meet may share one).
//
// Printed: the board in four, the bars, the crank, the carriages, the
// lever, the bridge in two, the blocks, the pins' caps, the slate's frame.
// Bought: 3 mm steel pins (or printed ones), a slate board.

BOARD_T = 10;                    // the board, on the table
BX0 = -165; BX1 = 125;           // its ends (x)
BZ0 = -140; BZ1 = 140;           // its back and front (z)
GAP = 7; THICK = 3; BAR_W = 8;   // the planes; a bar's thickness and width
function planeY(k) = BOARD_T + 6 + k * GAP;   // the middle of plane k
PIN_D = 3;

// the inverter: O, the arms, the rhombus
OX = -130;                       // O (z = 0)
L_ARM = 150.52; S_SIDE = 112.5;  // L^2 - S^2 = 100.0 cm^2 (to 0.0002)
CRANK_C = 35;                    // the straight line's crank: its pin at O + C, its length C

// a bar of length l between pin centres, along +x from its first pin
module bar(l, w = BAR_W) difference() {
  hull() {
    cylinder(d = w, h = THICK, center = true, $fn = 28);
    translate([l, 0, 0]) cylinder(d = w, h = THICK, center = true, $fn = 28);
  }
  for (x = [0, l]) cylinder(d = PIN_D + 0.3, h = THICK + 2, center = true, $fn = 16);
}
// (the same, its axis y up, for the script: bar(l) turned to lie flat)
module barFlat(l) rotate([90, 0, 0]) bar(l);

// a carriage: a block that rides a slot in the board, with a pin up and a
// knob for the hand
module carriage(h = 2 * GAP) {
  translate([-7, -2.5, -7]) cube([14, 4, 14]);
  translate([0, 1.5, 0]) rotate([-90, 0, 0]) cylinder(d = PIN_D, h = h + 3, $fn = 16);
}
module knob() { translate([0, 0, 0]) rotate([-90, 0, 0]) cylinder(d = 5, h = 14, $fn = 16); translate([0, 17, 0]) sphere(d = 11, $fn = 24); }

// the board, with the slot for the inverter's input (along x, at z = 0),
// the multiplier's slots, the scales are paper glued on (scales/)
SLOT_W = 6;
module board(way) difference() {
  translate([BX0, 0, BZ0]) cube([BX1 - BX0, BOARD_T, BZ1 - BZ0]);
  if (way == "inverter") translate([OX + 45, BOARD_T - 3, -SLOT_W / 2]) cube([50, 4, SLOT_W]);
  // (the fixed pins' holes: O, and the straight line's crank at O + C)
  for (x = way == "inverter" ? [OX, OX + CRANK_C] : [MOX]) translate([x, BOARD_T - 6, 0]) rotate([-90, 0, 0]) cylinder(d = PIN_D, h = 7, $fn = 16);
  if (way == "multiply") {
    translate([MOX + MD - SLOT_W / 2, BOARD_T - 3, -40]) cube([SLOT_W, 4, 80]);                         // the y carriage's
    for (z = [BRIDGE_Z0 + 6, BRIDGE_Z1 - 6]) translate([MOX + 75, BOARD_T - 3, z - SLOT_W / 2]) cube([130, 4, SLOT_W]);   // the bridge's
  }
}

// the multiplier: its O, the y carriage's distance, the lever, the bridge
MOX = -150;                      // its O (z = 0)
MD = 60;                         // the y carriage's guide, across, at O + D
LEVER_L = 250;
module lever() difference() {
  hull() { cylinder(d = 14, h = THICK, center = true, $fn = 28); translate([LEVER_L, 0, 0]) cylinder(d = 14, h = THICK, center = true, $fn = 28); }
  cylinder(d = PIN_D + 0.3, h = THICK + 2, center = true, $fn = 16);
  hull() { translate([20, 0, 0]) cylinder(d = 5, h = THICK + 2, center = true, $fn = 16); translate([LEVER_L - 6, 0, 0]) cylinder(d = 5, h = THICK + 2, center = true, $fn = 16); }
}
module leverFlat() rotate([90, 0, 0]) lever();
// a block riding the slot (a T: its tongue in the slot, its pin to its carriage)
module block() { translate([-6, -1.5, -4]) cube([12, 3, 8]); }
BRIDGE_Z0 = -135; BRIDGE_Z1 = 135;
module bridge() {
  translate([-6, -2, BRIDGE_Z0]) cube([12, 4, BRIDGE_Z1 - BRIDGE_Z0]);
  for (z = [BRIDGE_Z0 + 6, BRIDGE_Z1 - 6]) translate([-5, -2 - (planeY(1) - planeY(0)) + 0.01, z - 5]) cube([10, planeY(1) - planeY(0), 10]);
}

// the slate: a board in a frame on two legs, its face toward +z
SLATE_W = 220; SLATE_H = 120; SLATE_T = 6; SLATE_Y = 70;
module slate() translate([-SLATE_W / 2, SLATE_Y, -SLATE_T]) cube([SLATE_W, SLATE_H, SLATE_T]);
module slateFrame() {
  difference() {
    translate([-SLATE_W / 2 - 8, SLATE_Y - 8, -SLATE_T - 2]) cube([SLATE_W + 16, SLATE_H + 16, SLATE_T + 3]);
    translate([-SLATE_W / 2, SLATE_Y, -SLATE_T - 3]) cube([SLATE_W, SLATE_H, SLATE_T + 5]);
  }
  for (e = [-1, 1]) translate([e * (SLATE_W / 2 - 20) - 5, 0, -SLATE_T - 2]) cube([10, SLATE_Y - 7, 6]);
  translate([-SLATE_W / 2 + 10, 0, -40]) cube([SLATE_W - 20, 6, 50]);
}
// the operator's finger, its tip at the origin, along +z
module finger() {
  hull() { sphere(d = 14, $fn = 24); translate([0, 0, 60]) sphere(d = 17, $fn = 24); }
  translate([0, -5.2, 6]) rotate([-12, 0, 0]) scale([1, 0.35, 1]) cylinder(d = 10, h = 12, $fn = 20);
}

// the printed parts, each lying on the bed (make-stls.sh)
PART = ""; WAY = "inverter"; N = 0; LEN = 100;
module quarter(i) intersection() {
  translate([0, 0, 0]) board(WAY);
  translate([i % 2 == 0 ? BX0 - 1 : (BX0 + BX1) / 2, -1, i < 2 ? BZ0 - 1 : 0]) cube([(BX1 - BX0) / 2 + 1, BOARD_T + 2, (BZ1 - BZ0) / 2 + 1]);
}
if (PART == "board") translate([0, 0, 0]) rotate([90, 0, 0]) mirror([0, 0, 1]) quarter(N);
if (PART == "bar") translate([0, 0, THICK / 2]) bar(LEN);
// (the lever, 264 mm, in two: each half has half its thickness over the
// other for 30 mm, glued)
module leverHalf(i) intersection() {
  lever();
  if (i == 0) union() { translate([-20, -20, -THICK]) cube([LEVER_L / 2 - 15 + 20, 40, 2 * THICK]); translate([LEVER_L / 2 - 15.01, -20, -THICK]) cube([30.02, 40, THICK]); }
  else union() { translate([LEVER_L / 2 + 15, -20, -THICK]) cube([LEVER_L, 40, 2 * THICK]); translate([LEVER_L / 2 - 15, -20, 0]) cube([30.02, 40, THICK]); }
}
if (PART == "lever-half") translate([N == 0 ? 0 : -LEVER_L / 2, 0, THICK / 2]) rotate([N == 0 ? 0 : 180, 0, 0]) leverHalf(N);
// (printed, a carriage has a round peg under it, 5.6 mm, that runs in its
// slot: the slots are 6 mm wide and 3 mm deep, and the carriage's block
// stands 3.5 mm above the board; the script's carriage leaves it out, as
// its slider does the guiding)
module carriagePrinted() { carriage(); translate([0, -2.5 + 0.01, 0]) rotate([90, 0, 0]) cylinder(d = SLOT_W - 0.4, h = 6.3, $fn = 24); }
if (PART == "carriage") rotate([90, 0, 0]) mirror([0, 0, 1]) translate([0, 8.79, 0]) carriagePrinted();
if (PART == "block") translate([0, 0, 1.5]) rotate([90, 0, 0]) block();
// (printed, each of the bridge's feet has a peg, 5.6 mm, down into its slot)
module bridgePrinted() { bridge(); for (z = [BRIDGE_Z0 + 6, BRIDGE_Z1 - 6]) translate([0, -2 - (planeY(1) - planeY(0)) + 0.02, z]) rotate([90, 0, 0]) cylinder(d = SLOT_W - 0.4, h = 7, $fn = 24); }
if (PART == "bridge-half") translate([0, 0, 6]) rotate([0, 90, 0]) intersection() { bridgePrinted(); translate([-50, -50, N == 0 ? BRIDGE_Z0 - 1 : 0]) cube([100, 100, (BRIDGE_Z1 - BRIDGE_Z0) / 2 + 1]); }
if (PART == "knob") rotate([90, 0, 0]) knob();
