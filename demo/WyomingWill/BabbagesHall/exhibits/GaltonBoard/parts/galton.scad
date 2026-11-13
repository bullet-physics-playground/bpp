// galton.scad -- the Galton board (Babbage's Hall), in millimetres.
//
// Every size comes from geometry.scad, which galton.lua writes from
// galton-geometry.lua: the simulation's contact shapes are made from the
// same numbers, so what is printed is what is simulated.
//
// The board's frame: x to the right, y up, z toward you; the back plate's
// face at z = 0, the front sheet's back at z = GAP; y = 0 is the first row's
// middle pin. make-stls.sh turns each printed part to lie on the bed
// (PART = "print-...").

include <geometry.scad>

PART = "";
$fn = 24;

// ---------------------------------------------------------------------------
// the board
// ---------------------------------------------------------------------------
module outside() translate([-OUT_W / 2, OUT_Y0]) square([OUT_W, OUT_H]);
// the drawer's bay (through the back plate: the drawer has its own back and
// front) and the slide's slot, both open to the right-hand side
DRAWER_WALL = 1.2;
BAY_X0 = -W - DRAWER_WALL - 0.3;
BAY_Y0 = Y_DRAWER - DRAWER_WALL - 0.3;
BAY_Y1 = Y_FLOOR - SLIDE_T - 0.2;
module bay() translate([BAY_X0, BAY_Y0]) square([OUT_W / 2 + 1 - BAY_X0, BAY_Y1 - BAY_Y0]);
module slideSlot() translate([-W - 2, Y_FLOOR - SLIDE_T - 0.2]) square([2 * W + RIM + 3, SLIDE_T + 0.4]);
// the walls, as seen from the front: the outside less the ball spaces
module wallsPlan() difference() {
  outside();
  polygon(MAIN);
  polygon(HOPPER);
  for (sx = [-1, 1]) translate([sx * WHEEL_X, WHEEL_Y]) circle(r = HOUSING, $fn = 120);
  bay();
  slideSlot();
  translate([-FILL_W / 2, Y_TOP - 1]) square([FILL_W, RIM + 2]);     // the filling slot
}
// the screws along the rim that hold the front sheet (and the tiles)
function screwsOn(a, b, n) = [for (i = [0 : n]) a + (b - a) * i / n];
// (the front sheet stops above the slide: the drawer's front goes under it)
FRONT_Y0 = Y_FLOOR + 1;
SCREWS = concat(
  [for (y = screwsOn(FRONT_Y0 + 8, OUT_Y1 - 10, round((OUT_Y1 - 18 - FRONT_Y0) / SCREW_PITCH))) [-OUT_W / 2 + RIM / 2, y]],
  [for (y = screwsOn(FRONT_Y0 + 8, OUT_Y1 - 10, round((OUT_Y1 - 18 - FRONT_Y0) / SCREW_PITCH))) [OUT_W / 2 - RIM / 2, y]]);
module board() difference() {
  union() {
    translate([0, 0, -BACK_T]) linear_extrude(BACK_T) difference() { outside(); bay(); }
    linear_extrude(GAP) wallsPlan();
    for (p = concat(PINS, BUMPS)) translate([p[0], p[1], -0.01]) cylinder(d = PIN_D, h = GAP + 0.01, $fn = 20);
    for (x = DIVIDERS) {
      translate([x - DIV_T / 2, Y_FLOOR, 0]) cube([DIV_T, Y_DIV - Y_FLOOR, GAP]);
      translate([x, Y_DIV, 0]) cylinder(d = DIV_T, h = GAP, $fn = 12);
    }
  }
  for (sx = [-1, 1]) translate([sx * WHEEL_X, WHEEL_Y, -BACK_T - 1]) cylinder(d = AXLE_D + 0.2, h = BACK_T + 2, $fn = 16);
  for (s = SCREWS) translate([s[0], s[1], -1]) cylinder(d = SCREW_D, h = GAP + 2, $fn = 12);
  // the expected heights in the bins, engraved 0.6 mm in the back plate
  marksCut();
}
// the pins and half pins again, to draw them in brass (the board's own, a
// hair larger, so they show over it)
module pinsDrawn() for (p = concat(PINS, BUMPS)) translate([p[0], p[1], 0]) cylinder(d = PIN_D + 0.1, h = GAP + 0.05, $fn = 16);
// the binomial's heights for NBALLS balls: a line across each bin
module marks(depth) for (k = [0 : NBINS - 1]) if (EXPECTED[k] > 0)
  translate([BINS[k] - (S - DIV_T) / 2 + 0.6, Y_FLOOR + EXPECTED[k] - 0.5, -depth])
    cube([S - DIV_T - 1.2, 1.0, depth + 0.05]);
module marksCut() marks(0.6);

// the tiles: the board cut at CUTS (heights), each to print on its back
module tile(k) {
  y0 = k == 0 ? OUT_Y0 - 1 : CUTS[len(CUTS) - k];
  y1 = k == len(CUTS) ? OUT_Y1 + 1 : CUTS[len(CUTS) - 1 - k];
  intersection() { board(); translate([-OUT_W, y0, -BACK_T - 1]) cube([2 * OUT_W, y1 - y0, GAP + BACK_T + 2]); }
}
// a splice plate, glued across the back of each joint
module splice() difference() {
  translate([-OUT_W / 2 + 10, -15, 0]) cube([OUT_W - 20, 30, 3]);
  for (x = [-50, 0, 50]) for (y = [-8, 8]) translate([x, y, -1]) cylinder(d = 3.4, h = 5, $fn = 12);
}

// ---------------------------------------------------------------------------
// the metering wheel, the crank, the slide, the drawer
// ---------------------------------------------------------------------------
// the wheel (its centre at the origin, its faces at z = +-WHEEL_T/2): each
// slot is the strip SLOT_W wide outside the hub circle, as in the simulation
module wheel() difference() {
  cylinder(r = WHEEL_R, h = WHEEL_T, center = true, $fn = 96);
  for (a = SLOT_ANGLES) rotate([0, 0, a]) difference() {
    translate([0, -SLOT_W / 2, -WHEEL_T]) cube([WHEEL_R + 1, SLOT_W, 2 * WHEEL_T]);
    cylinder(r = WHEEL_R - SLOT_D, h = 3 * WHEEL_T, center = true, $fn = 96);
  }
  cylinder(d = AXLE_D - 0.1, h = WHEEL_T + 2, center = true, $fn = 16);   // (a press fit on the axle)
}
// an axle: from its gear behind the back plate, through the plate and its
// wheel, and (the left one, the crank's) through the front sheet
// (long: the crank's, out through the front sheet; short: the right one, ending in its wheel)
module axle(long = true) translate([0, 0, -BACK_T - GEAR_T - 2])
  cylinder(d = AXLE_D, h = long ? THICK + GEAR_T + 14 : BACK_T + GEAR_T + 2 + GAP - 0.5, $fn = 16);
// a gear (its back at z = 0, its centre at the origin): GEAR_Z teeth of
// module GEAR_M, so that the two meet at their pitch circles; plain
// trapezoid teeth, pressed onto the axle behind the back plate
module gear() difference() {
  linear_extrude(GEAR_T) {
    circle(r = GEAR_Z * GEAR_M / 2 - 1.25 * GEAR_M, $fn = 96);
    for (k = [0 : GEAR_Z - 1]) rotate(k * 360 / GEAR_Z)
      polygon([[GEAR_Z * GEAR_M / 2 - 1.3 * GEAR_M, -0.85 * GEAR_M], [GEAR_Z * GEAR_M / 2 + GEAR_M, -0.35 * GEAR_M],
               [GEAR_Z * GEAR_M / 2 + GEAR_M, 0.35 * GEAR_M], [GEAR_Z * GEAR_M / 2 - 1.3 * GEAR_M, 0.85 * GEAR_M]]);
  }
  translate([0, 0, -1]) cylinder(d = AXLE_D - 0.1, h = GEAR_T + 2, $fn = 16);
}
// the crank, in front of the sheet (its hub on the axle at z = 0)
module crank() {
  difference() {
    hull() { cylinder(d = 10, h = 4, $fn = 24); translate([CRANK_R, 0, 0]) cylinder(d = 8, h = 4, $fn = 24); }
    translate([0, 0, -1]) cylinder(d = AXLE_D - 0.1, h = 6, $fn = 16);
  }
  translate([CRANK_R, 0, 0]) cylinder(d = 7, h = 18, $fn = 24);                  // the handle
}
// the slide: a plate under the bins, out through the right-hand rim, with a
// finger tab standing up from its end (the drawer's handle is below it)
module slide() {
  translate([-W - 1.5, -SLIDE_T / 2, 0]) cube([2 * W + RIM + 1.5, SLIDE_T, GAP - 0.4]);
  translate([W + RIM, -SLIDE_T / 2, 0]) cube([8, SLIDE_T + 12, GAP - 0.4]);
}
// the drawer: a tray 7 mm deep inside (the balls' depth), sliding in the
// bay from the right; its inside is the simulation's
module drawer() {
  difference() {
    translate([-W - DRAWER_WALL, Y_DRAWER - DRAWER_WALL, -DRAWER_WALL])
      cube([2 * W + DRAWER_WALL + RIM, BAY_Y1 - 0.2 - Y_DRAWER + DRAWER_WALL, GAP + 2 * DRAWER_WALL]);
    translate([-W, Y_DRAWER, 0]) cube([2 * W, 100, GAP]);
  }
  translate([W + RIM, Y_DRAWER + 4, -DRAWER_WALL]) cube([6, Y_FLOOR - SLIDE_T - Y_DRAWER - 8, GAP + 2 * DRAWER_WALL]);   // its handle
}
// the front sheet (bought: clear acrylic), drawn
module front() translate([0, 0, GAP]) difference() {
  translate([-OUT_W / 2, FRONT_Y0, 0]) cube([OUT_W, OUT_Y1 - FRONT_Y0, FRONT_T]);
  translate([-WHEEL_X, WHEEL_Y, -1]) cylinder(d = AXLE_D + 0.5, h = FRONT_T + 2, $fn = 16);     // (the crank's axle)
}
// the stand: the board's foot stands on its foot, between a lip in front
// and one behind; two gussets behind hold the back lip
ZMID = (GAP + FRONT_T - BACK_T) / 2;           // the board's middle, through its thickness
module stand() translate([0, OUT_Y0, ZMID]) {
  translate([-FOOT_W / 2, -FOOT_T, -FOOT_D / 2]) cube([FOOT_W, FOOT_T, FOOT_D]);
  translate([-FOOT_W / 2, 0, THICK / 2 + 0.2]) cube([FOOT_W, LIP_H, LIP_T]);
  translate([-FOOT_W / 2, 0, -THICK / 2 - 0.2 - LIP_T]) cube([FOOT_W, LIP_H, LIP_T]);
  zb = -THICK / 2 - 0.2 - LIP_T;
  for (x = [-OUT_W / 2 + 15, OUT_W / 2 - 15]) hull() {
    translate([x - 2, 0, zb - 35]) cube([4, 1, 35]);
    translate([x - 2, 0, zb - 1]) cube([4, 60, 1]);
  }
}

// ---------------------------------------------------------------------------
// the sign (the exhibit's, not the machine's: what an operator would write
// up, on drums like a counter's). Its own frame: x along it, y up, z out of
// its face; the face at z = 0, its bottom left corner at 0, 0.
// ---------------------------------------------------------------------------
DRUM_R = 17;
DRUM_N = 11;
DRUM_A = 360 / DRUM_N;
DRUM_FACE = 2 * DRUM_R * tan(DRUM_A / 2);
SIGN_D = 3.5 + 2 * DRUM_R / cos(DRUM_A / 2) + 5;
module drumBody(w) {
  for (k = [0 : DRUM_N - 1]) rotate([k * DRUM_A, 0, 0]) translate([-w / 2, -DRUM_FACE / 2, DRUM_R - 2.5]) cube([w, DRUM_FACE, 2.5]);
  rotate([0, 90, 0]) cylinder(r = DRUM_R - 2, h = w, center = true, $fn = 22);
}
module drumDigits() for (k = [0 : 9])
  rotate([k * DRUM_A, 0, 0]) translate([0, 0, DRUM_R]) linear_extrude(0.5)
    text(str(k), size = 7, halign = "center", valign = "center");
module signBox(W, H, wins) difference() {
  translate([0, -15, -SIGN_D]) cube([W, H + 15, SIGN_D]);
  for (w = wins) {
    translate([w[0] - w[2] / 2 - 0.5, w[1] - 6, -5]) cube([w[2] + 1, 12, 10]);
    translate([w[0] - w[2] / 2 - 1, w[1] - DRUM_R / cos(DRUM_A / 2) - 1.5, -SIGN_D + 2])
      cube([w[2] + 2, 2 * DRUM_R / cos(DRUM_A / 2) + 3, SIGN_D - 5]);
  }
}
// labels: [text, x, y, size]
module signLabels(labels) for (l = labels)
  translate([l[1], l[2], 0]) linear_extrude(0.6) text(l[0], size = l[3], valign = "center");

// ---------------------------------------------------------------------------
// to print (make-stls.sh)
// ---------------------------------------------------------------------------
if (PART == "print-tile-top") translate([0, 0, BACK_T]) tile(2);
if (PART == "print-tile-middle") translate([0, 0, BACK_T]) tile(1);
if (PART == "print-tile-bottom") translate([0, 0, BACK_T]) tile(0);
if (PART == "print-splice") splice();
if (PART == "print-wheel") translate([0, 0, WHEEL_T / 2]) wheel();
if (PART == "print-gear") gear();
if (PART == "print-crank") crank();
if (PART == "print-slide") rotate([90, 0, 0]) translate([0, SLIDE_T / 2 + 6, 0]) slide();
if (PART == "print-drawer") translate([0, -Y_DRAWER, DRAWER_WALL]) drawer();
if (PART == "print-stand") rotate([90, 0, 0]) translate([0, -OUT_Y0 + FOOT_T, -ZMID]) stand();
if (PART == "cut-front") projection() front();
if (PART == "board") board();
