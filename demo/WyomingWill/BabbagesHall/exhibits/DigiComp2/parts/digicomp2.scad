// The Digi-Comp II -- Babbage's Hall (step 1: the counter)
//
// Every printed part, in millimetres. The shapes that balls and rockers
// touch are built from the very numbers the simulation uses (geometry.scad,
// written from digicomp2-geometry.lua by the exhibit, in cm); what nothing
// touches is added round them: pin holes, hubs, the lettering, the stand.
// make-stls.sh (one folder up) makes them all.
//
// The board's own frame: x across it (right), y out of its face, z down the
// slope (toward you). The modules without "print-" draw the parts in that
// frame, as the simulation shows them; the print- parts lie them on the bed.
//
// PARTS
//   rocker     a flip-flop: 3
//   wheel      the feeder's wheel: 1;  knob: its knob, glued on: 1
//   tile-0..2  the board, in three tiles (walls, pegs, bosses, lettering)
//   foot-back, foot-front   the stand's feet: 2 of each

include <geometry.scad>

PART = "";
FONT = "DejaVu Sans:style=Bold";
S = 10;                                   // cm (the simulation's) -> mm
$fn = 40;

// a 2D shape in the board's plane (points [x, -z] in mm), stood y0..y0+h
module slab(y0, h) translate([0, S * y0, 0]) rotate([-90, 0, 0]) linear_extrude(S * h) children();
// a strip along a centre line (cm), width w, from y0, h high (as the
// simulation's box: its length plus w)
module strip(s, w, y0, h) {
  dx = s[2] - s[0]; dz = s[3] - s[1];
  len = sqrt(dx * dx + dz * dz) + w;
  translate(S * [(s[0] + s[2]) / 2, y0 + h / 2, (s[1] + s[3]) / 2])
    rotate([0, atan2(-dz, dx), 0]) cube(S * [len, h, w], center = true);
}

// ---- a flip-flop (its pivot at 0, 0) ----
module rocker() difference() {
  slab(F_Y0, F_H) for (p = F_PIECES) polygon([for (q = p) [S * q[0], -S * q[1]]]);
  // the weight's pocket, from the top: a 1/4 inch steel ball pressed in
  // (6.35 mm; the pocket 6.3 mm across), its top 0.2 mm below the face
  translate([0, S * (F_Y0 + F_H) - 2 * S * F_WEIGHT_R - 0.2, S * F_WEIGHT_Z]) rotate([-90, 0, 0])
    cylinder(r = S * F_WEIGHT_R - 0.025, h = 2 * S * F_WEIGHT_R + 1);
  // the pin's hole (3 mm pin, 0.2 mm clearance)
  translate([0, S * F_Y0 - 1, 0]) rotate([-90, 0, 0]) cylinder(r = S * F_PIN_R + 0.2, h = S * F_H + 2);
}

module rockerWeight() translate([0, S * (F_Y0 + F_H - F_WEIGHT_R) - 0.2, S * F_WEIGHT_Z]) sphere(r = S * F_WEIGHT_R, $fn = 24);

// ---- the feeder's wheel (its centre at 0, 0) and knob ----
module wheel() difference() {
  slab(W_Y0, W_H) for (p = W_PIECES) polygon([for (q = p) [S * q[0], -S * q[1]]]);
  translate([0, S * W_Y0 - 1, 0]) rotate([-90, 0, 0]) cylinder(r = S * F_PIN_R + 0.2, h = S * W_H + 2);
}
KNOB_Y = W_Y0 + W_H;                       // it stands on the wheel's hub, above the balls
module knob() translate([0, S * KNOB_Y, 0]) rotate([-90, 0, 0]) difference() {
  union() {
    cylinder(r = 5.5, h = 6);                         // the stem (inside the notches' bottoms)
    translate([0, 0, 6]) cylinder(r = 14, h = 6);     // the grip, clear above the balls
    // the pointer: which notch is at the bottom
    translate([0, 9, 12]) cylinder(r = 2.5, h = 2);
  }
  // four marks round the grip: a quarter turn is one ball
  for (a = [0, 90, 180, 270]) rotate(a) translate([14, 0, 9]) cube([3, 2, 7], center = true);
  translate([0, 0, -1]) cylinder(r = S * F_PIN_R + 0.2, h = 8);
}

// ---- the board: the plate, walls, pegs, the bosses the rockers turn on ----
module walls() for (w = WALLS) strip(w, WALL_T, 0, WALL_H);
module pegs() for (p = PEGS) translate(S * [p[0], 0, p[1]]) rotate([-90, 0, 0]) cylinder(r = S * p[2], h = S * WALL_H);
module bosses() {
  for (t = TOGGLES) translate(S * [t[0], 0, t[1]]) rotate([-90, 0, 0]) cylinder(r = S * F_BOSS_R, h = S * F_Y0);
  translate(S * [WHEEL_AT[0], 0, WHEEL_AT[1]]) rotate([-90, 0, 0]) cylinder(r = S * F_BOSS_R, h = S * W_Y0);
}
module pinHoles() {
  // (3 mm pins, pressed in: 0.05 mm tight; through the plate)
  for (t = TOGGLES) translate(S * [t[0], -BOARD_T - 0.1, t[1]]) rotate([-90, 0, 0]) cylinder(r = S * F_PIN_R - 0.05, h = 20);
  translate(S * [WHEEL_AT[0], -BOARD_T - 0.1, WHEEL_AT[1]]) rotate([-90, 0, 0]) cylinder(r = S * F_PIN_R - 0.05, h = 20);
}
module plate() translate(S * [BOARD[0], -BOARD_T, BOARD[2]]) cube(S * [BOARD[1] - BOARD[0], BOARD_T, BOARD[3] - BOARD[2]]);

// the lettering, cut 0.6 mm into the board (fill it, or print it in a second
// colour): each flip-flop's 0 and 1 either side of its apex, and its weight
MARK_D = 0.6;
module marks2d() {
  for (i = [0 : len(TOGGLES) - 1]) {
    t = TOGGLES[i];
    translate([S * t[0], -S * t[1]]) {
      // (the apex leans right for 1, left for 0)
      translate([-S * 1.7, S * 1.9]) text("0", size = 6, halign = "center", valign = "center", font = FONT);
      translate([S * 1.7, S * 1.9]) text("1", size = 6, halign = "center", valign = "center", font = FONT);
      translate([-S * 3.0, S * 4.6]) text(str(pow(2, i), "s"), size = 7, halign = "center", valign = "center", font = FONT);
    }
  }
  for (i = [0 : len(LANES) - 1]) {
    l = LANES[i];
    translate([S * l[0], -S * (l[1] + 0.9)])
      text(i < len(TOGGLES) ? str(pow(2, i)) : "8", size = 5, halign = "center", valign = "center", font = FONT);
  }
}
module boardMarks() translate([0, -MARK_D + 0.05, 0]) slab(0, MARK_D / S) marks2d();
module board() difference() {
  union() { plate(); walls(); pegs(); bosses(); }
  pinHoles();
  translate([0, -MARK_D, 0]) slab(0, MARK_D / S + 0.01) marks2d();
}

// the three tiles: the board cut across the slope at TILE_Z (cm); each tile
// with a tongue at its top edge that fits under the tile above
TILE_Z = [BOARD[2], (2 * BOARD[2] + BOARD[3]) / 3, (BOARD[2] + 2 * BOARD[3]) / 3, BOARD[3]];
module tile(i) intersection() {
  board();
  translate(S * [BOARD[0] - 1, -BOARD_T - 1, TILE_Z[i]]) cube(S * [BOARD[1] - BOARD[0] + 2, WALL_H + BOARD_T + 2, TILE_Z[i + 1] - TILE_Z[i]]);
}

// ---- the stand: four feet under the backing sheet ----
// (the table is at the exhibit's y = 0: in the board's frame, y = (z sin TH - OY) / cos TH)
OY = FOOT + (BOARD_T + BACK) * cos(TH) + BOARD[3] * sin(TH);
function tableY(z) = (z * sin(TH) - OY) / cos(TH);
FOOT_W = 3.0;                             // each foot 3 cm square, seen from above
FOOT_Z = [BOARD[2] + 2.5, BOARD[3] - 2.5]; // a back pair (tall) and a front pair (low)
FOOT_X = [BOARD[0] + 2.5, BOARD[1] - 2.5];
// a foot's outline as points [-z, y] (its top under the sheet, its bottom on the table), stood across x
module foot2d(zc) let(z0 = zc - FOOT_W / 2, z1 = zc + FOOT_W / 2)
  polygon(S * [[-z0, -BOARD_T - BACK], [-z1, -BOARD_T - BACK], [-z1, tableY(z1)], [-z0, tableY(z0)]]);
module foot(x, zc) translate([S * x, 0, 0]) rotate([0, 90, 0]) linear_extrude(S * FOOT_W, center = true) foot2d(zc);
module stand() for (x = FOOT_X, z = FOOT_Z) foot(x, z);

// ---- the exhibit's sign beside it (not part of the machine): a line of text ----
module signText(t, size = 16) linear_extrude(1) text(t, size = size, halign = "left", valign = "center", font = FONT);

// ---- for printing: each on the bed ----
if (PART == "print-rocker") rotate([90, 0, 0]) translate([0, -S * F_Y0, 0]) rocker();
if (PART == "print-wheel") rotate([90, 0, 0]) translate([0, -S * W_Y0, 0]) wheel();
if (PART == "print-knob") rotate([90, 0, 0]) translate([0, -S * KNOB_Y, 0]) knob();
for (i = [0 : 2]) if (PART == str("print-tile", i))
  rotate([90, 0, 0]) translate([0, S * BOARD_T, -S * TILE_Z[i]]) tile(i);
// (a foot on its side: its outline flat on the bed)
if (PART == "print-foot-back") translate([0, 0, S * FOOT_W / 2]) rotate([0, -90, 0]) foot(0, FOOT_Z[0]);
if (PART == "print-foot-front") translate([0, 0, S * FOOT_W / 2]) rotate([0, -90, 0]) foot(0, FOOT_Z[1]);
// ---- the parts where they are at rest, for checking that none overlap ----
if (PART == "rest-board") board();
if (PART == "rest-backing") translate(S * [BOARD[0], -BOARD_T - BACK, BOARD[2]]) cube(S * [BOARD[1] - BOARD[0], BACK, BOARD[3] - BOARD[2]]);
if (PART == "rest-stand") stand();
for (i = [0 : len(TOGGLES) - 1]) if (PART == str("rest-rocker", i))
  translate(S * [TOGGLES[i][0], 0, TOGGLES[i][1]]) rotate([0, F_ALPHA - 0.3, 0]) rocker();
if (PART == "rest-wheel") translate(S * [WHEEL_AT[0], 0, WHEEL_AT[1]]) wheel();
if (PART == "rest-knob") translate(S * [WHEEL_AT[0], 0, WHEEL_AT[1]]) knob();
if (PART == "assembly") rotate([90, 0, 0]) { board(); stand(); for (t = TOGGLES) translate(S * [t[0], 0, t[1]]) rotate([0, F_ALPHA - 0.3, 0]) rocker();
                          translate(S * [WHEEL_AT[0], 0, WHEEL_AT[1]]) { wheel(); knob(); } }
