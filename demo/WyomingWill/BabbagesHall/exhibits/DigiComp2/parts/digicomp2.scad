// The Digi-Comp II -- Babbage's Hall (step 2c: the accumulator, memory, MQ, distributor and COMPLEMENT)
//
// Every printed part, in millimetres. The shapes that balls, rockers and
// flaps touch are built from the very numbers the simulation uses
// (geometry.scad, written from digicomp2-geometry.lua by the exhibit, in
// cm); what nothing touches is added round them: pin holes, the lettering,
// the stand. make-stls.sh (one folder up) makes them all.
//
// The board's own frame: x across it (right), y out of its face, z down the
// slope (toward you). The upper plate's face is y = 0; the lower level's is
// y = YL. The modules without "print-" draw the parts in that frame, as the
// simulation shows them; the print- parts lie them on the bed.
//
// PARTS
//   rocker      a flip-flop's top (roof, cups, tail, the pocket for its steel ball): 13
//   foot        its stem and foot, under the plate (glued into the rocker's hub): 13
//   flap        a switch's flap: 7 (MULTIPLY, CLEAR, COUNT, M1 .. M4)
//   wheel, star the feeder (START): its wheel, and the escape star glued on it: 1 each
//   anchor      the escapement's anchor, on its pin beside the wheel (its
//               counterweight a 1/2 inch steel ball in the cup on its arm): 1
//   trip-down-arm  AUTO: the arm hanging from the trip lever's axle, beyond
//               the channel's wall; the thread tied at its foot: 1
//   trip-eye    AUTO: the thread's eye, on a post behind the collector's wall: 1
//   trip-lever  AUTO: the lever at the bottom of the trip channel, on a 2 mm
//               wire axle through the channel's wall and the rim: 1
//   shutter     COMPLEMENT: a done hole's shutter, sliding in its groove: 6
//               (each with a 3 mm steel pin, 21 mm, pressed in); the bar
//               joining the pins is a 3 x 5 mm aluminium strip (README.md),
//   comp-knob   its handle, glued on its top end: 1
//   upper-i-j   the upper plate, in tiles: its walls, stop pegs, holes, lettering
//   lower-i-j   the lower level, in tiles: a 2 mm floor with its walls,
//               the posts that hold the plate up, the bosses the feet stand on
//   foot-back-1, foot-back-2, foot-front   the stand's feet: 2 of each
//               (each back foot in two halves, glued)

include <geometry.scad>

PART = "";
FONT = "DejaVu Sans:style=Bold";
S = 10;                                   // cm (the simulation's) -> mm
$fn = 40;
FLOOR = 0.2;                              // the lower tiles' floor (cm), on the plywood

// a 2D shape in the board's plane (points [x, -z] in mm), stood y0..y0+h (cm)
module slab(y0, h) translate([0, S * y0, 0]) rotate([-90, 0, 0]) linear_extrude(S * h) children();
module outline(p) polygon([for (q = p) [S * q[0], -S * q[1]]]);
// a strip along a centre line (cm), width w, from y0, h high (as the
// simulation's box: its length plus w)
module strip(s, w, y0, h) {
  dx = s[2] - s[0]; dz = s[3] - s[1];
  len = sqrt(dx * dx + dz * dz) + w;
  translate(S * [(s[0] + s[2]) / 2, y0 + h / 2, (s[1] + s[3]) / 2])
    rotate([0, atan2(-dz, dx), 0]) cube(S * [len, h, w], center = true);
}
module cylY(x, z, r, y0, h) translate(S * [x, y0, z]) rotate([-90, 0, 0]) cylinder(r = S * r, h = S * h);
module pinHole(y0, h) translate([0, S * y0 - 1, 0]) rotate([-90, 0, 0]) cylinder(r = S * F_PIN_R + 0.2, h = S * h + 2);

// ---- a flip-flop (its pin at 0, 0): the rocker on top, the foot below ----
STEM_SOCKET = 4;                          // mm the stem goes up into the rocker's hub
module rocker() difference() {
  slab(F_Y0, F_H) for (p = F_PIECES) outline(p);
  // the weight's pocket, from the top: a 1/4 inch steel ball pressed in
  // (6.35 mm; the pocket 6.3 mm across), its top 0.2 mm below the face
  translate([0, S * (F_Y0 + F_H) - 2 * S * F_WEIGHT_R - 0.2, S * F_WEIGHT_Z]) rotate([-90, 0, 0])
    cylinder(r = S * F_WEIGHT_R - 0.025, h = 2 * S * F_WEIGHT_R + 1);
  // the socket for the stem (glued), and the pin's hole
  translate([0, S * F_Y0 - 0.01, 0]) rotate([-90, 0, 0]) cylinder(r = S * F_STEM_R + 0.2, h = STEM_SOCKET);
  pinHole(F_Y0, F_H);
}
module rockerWeight() translate([0, S * (F_Y0 + F_H - F_WEIGHT_R) - 0.2, S * F_WEIGHT_Z]) sphere(r = S * F_WEIGHT_R, $fn = 24);
module foot() difference() {
  union() {
    cylY(0, 0, F_STEM_R, F_FY0, F_Y0 - F_FY0 + STEM_SOCKET / S);       // the stem, up into the rocker
    slab(F_FY0, F_FY1 - F_FY0) for (p = F_FOOT) outline(p);
  }
  pinHole(F_FY0, F_Y0 - F_FY0 + 1);
}

// ---- a switch's flap (its pin at 0, 0, its end up the slope) ----
module flap() difference() {
  translate(S * [-S_FT / 2, S_Y0, -S_FL]) cube(S * [S_FT, S_H, S_FL]);
  pinHole(S_Y0, S_H);
}

// ---- the feeder's wheel (its centre at 0, 0); the knob is gone (the
// escape star and the anchor turn it now: below) ----
module wheel() difference() {
  slab(W_Y0, W_H) for (p = W_PIECES) outline(p);
  pinHole(W_Y0, W_H);
}

// ---- COMPLEMENT: the shutters (closed: over their holes), their pins, the
// bar and its knob; open, all SH_TRAVEL to the right ----
module shutter(i) difference() {
  slab(-SH_T, SH_T) outline(SHUTTERS[i]);
  translate(S * [SH_PINS[i][0], 0, SH_PINS[i][1]]) pinHole(-SH_T, SH_T);
}
module complementBar() {
  difference() {
    slab(SH_BAR_Y0, SH_BAR_H) outline(SH_BAR);
    for (p = SH_PINS) translate(S * [p[0], 0, p[1]]) pinHole(SH_BAR_Y0, SH_BAR_H);
  }
  for (p = SH_PINS) cylY(p[0], p[1], SH_PIN_R, -SH_T, SH_BAR_Y0 + SH_BAR_H + SH_T);
}
module compKnob() cylY(SH_KNOB[0], SH_KNOB[1], SH_KNOB_R, SH_BAR_Y0 + SH_BAR_H, SH_KNOB_H);
// (its groove in the plate: where it is closed and open, 0.3 mm clear round)
module grooves() for (i = [0 : len(SHUTTERS) - 1])
  slab(-SH_T - 0.03, SH_T + 0.1) offset(delta = 0.3) hull() { outline(SHUTTERS[i]); translate([S * SH_TRAVEL, 0]) outline(SHUTTERS[i]); }

// ---- the escape star (on the wheel, its centre at 0, 0) and the anchor
// (its pin at 0, 0, at rest turned as ANCHOR_REST says) ----
module star() difference() {
  union() for (p = STAR_PIECES) slab(p[1], p[2]) outline(p[0]);
  pinHole(W_Y0, 3);
}
module anchor() difference() {
  union() for (p = ANCHOR_PIECES) slab(p[1], p[2]) outline(p[0]);
  pinHole(0, 3);
  // (the counterweight's seat: a 1/2 inch steel ball glued in a shallow cup)
  translate(S * [ANCHOR_CW[0], ANCHOR_CW[1], 0]) sphere(r = S * BALL_R + 0.1, $fn = 32);
  // (AUTO: the thread's hook goes down into this hole in the START lever)
  translate([0, 0, -S * ANCHOR_HOOK]) rotate([-90, 0, 0]) cylinder(r = S * ROD_PIN_R + 0.1, h = 40, $fn = 12);
}
// the trip lever (AUTO), in its own frame: the axle at the origin
// (the axle through it, a 2 mm wire: tripAxle(), along x, as placed on the board)
module tripLever() difference() {
  for (h = TRIP_HULLS) hull() for (q = h) translate(S * q) cube(0.01, center = true);
  rotate([0, 90, 0]) cylinder(r = S * TRIP_AXLE[5] + 0.05, h = 40, center = true, $fn = 16);
}
// the trip lever's hanging arm, glued on its axle's left end beyond the
// channel's wall (the axle glued in the lever too, turning in the wall and
// the rim); the thread tied through the hole at its foot. In the lever's frame
module tripDownArm() difference() {
  hull() for (q = TRIP_DOWN_ARM) translate(S * q) cube(0.01, center = true);
  translate([S * TRIP_DA[0], 0, 0]) rotate([0, 90, 0]) cylinder(r = S * TRIP_AXLE[5] + 0.05, h = 40, center = true, $fn = 16);
  translate(S * [TRIP_DA[0], -TRIP_DA[1] + 0.05, 0]) rotate([0, 90, 0]) cylinder(r = 0.6, h = 40, center = true, $fn = 12);
}
// the thread's eye: a post standing beside the board's right edge, glued to
// it by a foot under the lower board, its top a ring level with the START
// lever, that the thread turns through (as placed)
module tripEye() {
  cylY(TRIP_EYE[0], TRIP_EYE[2], 0.15, YL - BACK, TRIP_EYE[1] - (YL - BACK) - TRIP_EYE[3]);
  translate(S * [TRIP_EYE[0] - 0.55, YL - BACK - 0.3, TRIP_EYE[2] - 0.4]) cube(S * [0.8, 0.3, 0.8]);
  translate(S * [TRIP_EYE[0], TRIP_EYE[1], TRIP_EYE[2]]) rotate([-90, 0, 0]) rotate_extrude($fn = 24) translate([S * TRIP_EYE[3] - 0.6, 0]) circle(r = 0.6, $fn = 12);
}
module tripAxle() translate(S * [TRIP_AXLE[3], TRIP_AXLE[1], TRIP_AXLE[2]]) rotate([0, 90, 0])
  cylinder(r = S * TRIP_AXLE[5], h = S * (TRIP_AXLE[4] - TRIP_AXLE[3]), $fn = 16);
module anchorWeight() translate(S * [ANCHOR_CW[0], ANCHOR_CW[1], 0]) sphere(r = S * BALL_R, $fn = 24);

// ---- the upper plate: its face, holes, walls, stop pegs, the bosses under
// the flaps and the wheel, the lettering cut into it ----
module holes() for (h = HOLES) translate(S * [h[0], -PT - 0.1, h[2]]) cube(S * [h[1] - h[0], PT + 0.2, h[3] - h[2]]);
module upperPlate() translate(S * [BOARD[0], -PT, BOARD[2]]) cube(S * [BOARD[1] - BOARD[0], PT, BOARD[3] - BOARD[2]]);
module upperPins() {
  for (s = SWITCHES) translate(S * [s[0], -PT - 0.1, s[1]]) rotate([-90, 0, 0]) cylinder(r = S * F_PIN_R - 0.05, h = 20);
  translate(S * [WHEEL_AT[0], -PT - 0.1, WHEEL_AT[1]]) rotate([-90, 0, 0]) cylinder(r = S * F_PIN_R - 0.05, h = 20);
  translate(S * [ANCHOR_AT[0], -PT - 0.1, ANCHOR_AT[1]]) rotate([-90, 0, 0]) cylinder(r = S * F_PIN_R - 0.05, h = 20);
}
MARK_D = 0.6;                             // mm the lettering is cut in
// (the plate alone, its holes cut: how the simulation draws it, see-through)
module plateView() difference() { upperPlate(); holes(); }
module upper() difference() {
  union() {
    upperPlate();
    for (w = WALLS) strip(w, WALL_T, 0, WALL_H);
    for (p = PEGS) cylY(p[0], p[1], p[2], 0, WALL_H);
    for (p = ANCHOR_POSTS) cylY(p[0], p[1], p[2], 0, p[3]);         // (the anchor's stops)
    cylY(ANCHOR_AT[0], ANCHOR_AT[1], F_BOSS_R, 0, ANCHOR_PIECES[0][1]);  // (the boss under the anchor)
    for (s = SWITCHES) cylY(s[0], s[1], F_BOSS_R, 0, S_Y0);
    cylY(WHEEL_AT[0], WHEEL_AT[1], F_BOSS_R, 0, W_Y0);
  }
  holes();
  grooves();
  upperPins();
  translate([0, -MARK_D, 0]) slab(0, MARK_D / S + 0.01) marks2d();
}

// ---- the lower level: a floor with its walls, the posts, the bosses ----
module lower() difference() {
  union() {
    translate(S * [LOWER[0], YL - FLOOR, LOWER[2]]) cube(S * [LOWER[1] - LOWER[0], FLOOR, LOWER[3] - LOWER[2]]);
    for (w = LWALLS) strip(w, WALL_T, YL, w[4]);
    for (p = POSTS) cylY(p[0], p[1], 0.5, YL, GAP);
    for (t = TOGGLES) cylY(t[0], t[1], F_BOSS_R, YL, F_FY0 - YL);
  }
  for (t = TOGGLES) translate(S * [t[0], YL - FLOOR - 0.1, t[1]]) rotate([-90, 0, 0]) cylinder(r = S * F_PIN_R - 0.05, h = 20);
  // (the trip lever's axle, through the channel's wall and the rim: a snug hole)
  translate(S * [TRIP_AXLE[3] - 0.5, TRIP_AXLE[1], TRIP_AXLE[2]]) rotate([0, 90, 0])
    cylinder(r = S * TRIP_AXLE[5] - 0.05, h = S * (TRIP_AXLE[4] - TRIP_AXLE[3] + 1), $fn = 16);
  translate([0, -MARK_D, 0]) slab(YL, MARK_D / S + 0.01) lowerMarks2d();
}

// ---- the lettering ----
module label(t, x, z, size = 5) translate([S * x, -S * z]) text(t, size = size, halign = "center", valign = "center", font = FONT);
// (where each label goes is set in digicomp2-geometry.lua: MARKS)
module marks2d() for (m = MARKS) label(m[0], m[1], m[2], m[3]);
module lowerMarks2d() label("COLLECTOR", (LOWER[0] + LOWER[1]) / 2, LOWER[3] - 1.0, 6);
module boardMarks() {
  translate([0, -MARK_D + 0.05, 0]) slab(0, MARK_D / S) marks2d();
  translate([0, -MARK_D + 0.05, 0]) slab(YL, MARK_D / S) lowerMarks2d();
}

// ---- the tiles: each a piece of the plate (or the lower level) ----
NX = 2; NZ_U = 9; NZ_L = 9;
function cut(a, b, n, i) = a + (b - a) * i / n;
module tileOf(box, i, j, nz, y0, y1) intersection() {
  children();
  translate(S * [cut(box[0], box[1], NX, i) - (i == 0 ? 1 : 0), y0, cut(box[2], box[3], nz, j) - (j == 0 ? 1 : 0)])
    cube(S * [(box[1] - box[0]) / NX + (i == 0 || i == NX - 1 ? 1 : 0), y1 - y0, (box[3] - box[2]) / nz + (j == 0 || j == nz - 1 ? 1 : 0)]);
}

// ---- the stand: four feet under the lower board ----
// (the table is at the exhibit's y = 0: in the board's frame, y = (z sin TH - OY) / cos TH)
OY = FOOT + (-YL + BACK) * cos(TH) + LOWER[3] * sin(TH);
function tableY(z) = (z * sin(TH) - OY) / cos(TH);
FOOT_W = 3.0;
FOOT_Z = [LOWER[2] + 2.5, LOWER[3] - 2.5];
FOOT_X = [LOWER[0] + 2.5, LOWER[1] - 2.5];
module foot2d(zc) let(z0 = zc - FOOT_W / 2, z1 = zc + FOOT_W / 2)
  polygon(S * [[-z0, YL - BACK], [-z1, YL - BACK], [-z1, tableY(z1)], [-z0, tableY(z0)]]);
module standFoot(x, zc) translate([S * x, 0, 0]) rotate([0, 90, 0]) linear_extrude(S * FOOT_W, center = true) foot2d(zc);
module stand() for (x = FOOT_X, z = FOOT_Z) standFoot(x, z);

// (the exhibit's sign beside it, not part of the machine, is in sign.scad)

// ---- for printing: each on the bed ----
if (PART == "print-rocker") rotate([90, 0, 0]) translate([0, -S * F_Y0, 0]) rocker();
if (PART == "print-foot") rotate([90, 0, 0]) translate([0, -S * F_FY0, 0]) foot();
if (PART == "print-flap") rotate([90, 0, 0]) translate([0, -S * S_Y0, 0]) flap();
if (PART == "print-wheel") rotate([90, 0, 0]) translate([0, -S * W_Y0, 0]) wheel();
if (PART == "print-star") rotate([90, 0, 0]) translate([0, -S * min([for (p = STAR_PIECES) p[1]]), 0]) star();
if (PART == "print-anchor") rotate([90, 0, 0]) translate([0, -S * min([for (p = ANCHOR_PIECES) p[1]]), 0]) anchor();
if (PART == "print-trip-down-arm") translate([0, 0, 2]) rotate([0, -90, 0]) translate([-S * TRIP_DA[0], 0, 0]) tripDownArm();
if (PART == "print-trip-eye") translate([0, 0, -S * (YL - BACK - 0.3)]) rotate([90, 0, 0]) translate(-S * [TRIP_EYE[0], 0, TRIP_EYE[2]]) tripEye();
if (PART == "print-trip-lever") translate([0, 0, 5]) rotate([0, -90, 0]) tripLever();
if (PART == "print-shutter") rotate([90, 0, 0]) translate([-S * SH_PINS[0][0], S * SH_T, -S * SH_PINS[0][1]]) shutter(0);
if (PART == "print-comp-knob") rotate([90, 0, 0]) translate([-S * SH_KNOB[0], -S * (SH_BAR_Y0 + SH_BAR_H), -S * SH_KNOB[1]]) compKnob();
for (i = [0 : NX - 1], j = [0 : NZ_U - 1]) if (PART == str("print-upper-", i, "-", j))
  rotate([90, 0, 0]) translate([0, S * PT, -S * cut(BOARD[2], BOARD[3], NZ_U, j)]) tileOf(BOARD, i, j, NZ_U, -PT - 0.1, WALL_H + 0.1) upper();
for (i = [0 : NX - 1], j = [0 : NZ_L - 1]) if (PART == str("print-lower-", i, "-", j))
  rotate([90, 0, 0]) translate([0, -S * (YL - FLOOR), -S * cut(LOWER[2], LOWER[3], NZ_L, j)]) tileOf(LOWER, i, j, NZ_L, YL - FLOOR - 0.1, YL + 3.2) lower();   // (up to the collector's 30 mm wall)
// (the back foot is too tall for most beds: in two halves, glued one on the other)
BACK_MID = (YL - BACK + tableY(FOOT_Z[0])) / 2;
module backHalf(upper) intersection() {
  standFoot(0, FOOT_Z[0]);
  if (upper) translate([-50, S * BACK_MID, -2000]) cube([100, 2000, 4000]);
  else translate([-50, -2000, -2000]) cube([100, 2000 + S * BACK_MID, 4000]);
}
if (PART == "print-foot-back-1") translate([0, 0, S * FOOT_W / 2]) rotate([0, -90, 0]) backHalf(true);
if (PART == "print-foot-back-2") translate([0, 0, S * FOOT_W / 2]) rotate([0, -90, 0]) backHalf(false);
if (PART == "print-foot-front") translate([0, 0, S * FOOT_W / 2]) rotate([0, -90, 0]) standFoot(0, FOOT_Z[1]);
// ---- the parts where they are at rest, for checking that none overlap ----
if (PART == "rest-upper") upper();
if (PART == "rest-lower") lower();
if (PART == "rest-stand") stand();
for (i = [0 : len(TOGGLES) - 1]) {
  if (PART == str("rest-rocker", i)) translate(S * [TOGGLES[i][0], 0, TOGGLES[i][1]]) rotate([0, F_ALPHA - 0.3, 0]) rocker();
  if (PART == str("rest-foot", i)) translate(S * [TOGGLES[i][0], 0, TOGGLES[i][1]]) rotate([0, F_ALPHA - 0.3, 0]) foot();
}
for (i = [0 : len(SWITCHES) - 1]) if (PART == str("rest-flap", i)) translate(S * [SWITCHES[i][0], 0, SWITCHES[i][1]]) rotate([0, SWITCHES[i][2] * (S_ANG - 0.5), 0]) flap();
if (PART == "rest-wheel") translate(S * [WHEEL_AT[0], 0, WHEEL_AT[1]]) wheel();
if (PART == "rest-star") translate(S * [WHEEL_AT[0], 0, WHEEL_AT[1]]) star();
if (PART == "rest-anchor") translate(S * [ANCHOR_AT[0], 0, ANCHOR_AT[1]]) rotate([0, ANCHOR_REST, 0]) anchor();
if (PART == "rest-trip-down-arm") translate(S * [TRIP_AXLE[0], TRIP_AXLE[1], TRIP_AXLE[2]]) tripDownArm();
if (PART == "rest-trip-eye") tripEye();
if (PART == "rest-trip-lever") translate(S * [TRIP_AXLE[0], TRIP_AXLE[1], TRIP_AXLE[2]]) tripLever();
// (COMPLEMENT as the hand sets it up: off, the shutters to the right)
for (i = [0 : len(SHUTTERS) - 1]) if (PART == str("rest-shutter", i)) translate([S * SH_TRAVEL, 0, 0]) shutter(i);
if (PART == "rest-comp-bar") translate([S * SH_TRAVEL, 0, 0]) { complementBar(); compKnob(); }
if (PART == "assembly") rotate([90, 0, 0]) { upper(); lower(); for (t = TOGGLES) translate(S * [t[0], 0, t[1]]) rotate([0, F_ALPHA - 0.3, 0]) { rocker(); foot(); }
                          translate(S * [WHEEL_AT[0], 0, WHEEL_AT[1]]) { wheel(); star(); }
                          translate(S * [ANCHOR_AT[0], 0, ANCHOR_AT[1]]) rotate([0, ANCHOR_REST, 0]) anchor();
                          translate(S * [TRIP_AXLE[0], TRIP_AXLE[1], TRIP_AXLE[2]]) { tripLever(); tripDownArm(); }
                          tripEye();
                          translate([S * SH_TRAVEL, 0, 0]) { for (i = [0 : len(SHUTTERS) - 1]) shutter(i); complementBar(); compKnob(); } }
