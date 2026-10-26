// The Digi-Comp II -- Babbage's Hall (step 2a: the accumulator)
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
//   rocker      a flip-flop's top (roof, cups, tail, the pocket for its steel ball): 7
//   foot        its stem and foot, under the plate (glued into the rocker's hub): 7
//   flap        a switch's flap: 2 (CLEAR, COUNT)
//   wheel, knob the feeder (START): 1 each
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

// ---- the feeder's wheel (its centre at 0, 0) and knob ----
module wheel() difference() {
  slab(W_Y0, W_H) for (p = W_PIECES) outline(p);
  pinHole(W_Y0, W_H);
}
KNOB_Y = W_Y0 + W_H;                       // it stands on the wheel's hub, above the balls
module knob() translate([0, S * KNOB_Y, 0]) rotate([-90, 0, 0]) difference() {
  union() {
    cylinder(r = 5.5, h = 6);                         // the stem (inside the notches' bottoms)
    translate([0, 0, 6]) cylinder(r = 14, h = 6);     // the grip, clear above the balls
    translate([0, 9, 12]) cylinder(r = 2.5, h = 2);   // the pointer
  }
  for (a = [0, 90, 180, 270]) rotate(a) translate([14, 0, 9]) cube([3, 2, 7], center = true);
  translate([0, 0, -1]) cylinder(r = S * F_PIN_R + 0.2, h = 8);
}

// ---- the upper plate: its face, holes, walls, stop pegs, the bosses under
// the flaps and the wheel, the lettering cut into it ----
module holes() for (h = HOLES) translate(S * [h[0], -PT - 0.1, h[2]]) cube(S * [h[1] - h[0], PT + 0.2, h[3] - h[2]]);
module upperPlate() translate(S * [BOARD[0], -PT, BOARD[2]]) cube(S * [BOARD[1] - BOARD[0], PT, BOARD[3] - BOARD[2]]);
module upperPins() {
  for (s = SWITCHES) translate(S * [s[0], -PT - 0.1, s[1]]) rotate([-90, 0, 0]) cylinder(r = S * F_PIN_R - 0.05, h = 20);
  translate(S * [WHEEL_AT[0], -PT - 0.1, WHEEL_AT[1]]) rotate([-90, 0, 0]) cylinder(r = S * F_PIN_R - 0.05, h = 20);
}
MARK_D = 0.6;                             // mm the lettering is cut in
// (the plate alone, its holes cut: how the simulation draws it, see-through)
module plateView() difference() { upperPlate(); holes(); }
module upper() difference() {
  union() {
    upperPlate();
    for (w = WALLS) strip(w, WALL_T, 0, WALL_H);
    for (p = PEGS) cylY(p[0], p[1], p[2], 0, WALL_H);
    for (s = SWITCHES) cylY(s[0], s[1], F_BOSS_R, 0, S_Y0);
    cylY(WHEEL_AT[0], WHEEL_AT[1], F_BOSS_R, 0, W_Y0);
  }
  holes();
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
  translate([0, -MARK_D, 0]) slab(YL, MARK_D / S + 0.01) lowerMarks2d();
}

// ---- the lettering ----
module label(t, x, z, size = 5) translate([S * x, -S * z]) text(t, size = size, halign = "center", valign = "center", font = FONT);
module marks2d() {
  for (i = [0 : len(TOGGLES) - 1]) {
    t = TOGGLES[i];
    // (the apex leans right for 1, left for 0)
    label("0", t[0] - 1.7, t[1] - 1.9, 6); label("1", t[0] + 1.7, t[1] - 1.9, 6);
    label(str(pow(2, i)), t[0] - 3.1, t[1] - 4.6, 7);
  }
  k = SWITCHES[0]; c = SWITCHES[1];
  label("CLEAR", k[0] - 3.4, k[1] - 1.2, 5); label("on", k[0] - 1.67, k[1] + 3.9, 4); label("off", k[0] + 1.67 + 1.8, k[1] + 3.0, 4);
  label("COUNT", c[0] + 3.6, c[1] - 1.2, 5); label("on", c[0] - 1.67 - 1.6, c[1] + 2.4, 4); label("off", c[0] + 1.67, c[1] + 3.9, 4);
  label("START", WHEEL_AT[0] + 4.2, WHEEL_AT[1], 5);
  label("OVERFLOW", OVERFLOW[0] + 0.3, OVERFLOW[1] + 2.0, 4);
}
module lowerMarks2d() label("COLLECTOR", (LOWER[0] + LOWER[1]) / 2, LOWER[3] - 1.0, 6);
module boardMarks() {
  translate([0, -MARK_D + 0.05, 0]) slab(0, MARK_D / S) marks2d();
  translate([0, -MARK_D + 0.05, 0]) slab(YL, MARK_D / S) lowerMarks2d();
}

// ---- the tiles: each a piece of the plate (or the lower level) ----
NX = 2; NZ_U = 5; NZ_L = 5;
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

// ---- the exhibit's sign beside it (not part of the machine): a line of text ----
module signText(t, size = 16) linear_extrude(1) text(t, size = size, halign = "left", valign = "center", font = FONT);

// ---- for printing: each on the bed ----
if (PART == "print-rocker") rotate([90, 0, 0]) translate([0, -S * F_Y0, 0]) rocker();
if (PART == "print-foot") rotate([90, 0, 0]) translate([0, -S * F_FY0, 0]) foot();
if (PART == "print-flap") rotate([90, 0, 0]) translate([0, -S * S_Y0, 0]) flap();
if (PART == "print-wheel") rotate([90, 0, 0]) translate([0, -S * W_Y0, 0]) wheel();
if (PART == "print-knob") rotate([90, 0, 0]) translate([0, -S * KNOB_Y, 0]) knob();
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
for (i = [0 : 1]) if (PART == str("rest-flap", i)) translate(S * [SWITCHES[i][0], 0, SWITCHES[i][1]]) rotate([0, (i == 0 ? 1 : -1) * (S_ANG - 0.5), 0]) flap();
if (PART == "rest-wheel") translate(S * [WHEEL_AT[0], 0, WHEEL_AT[1]]) wheel();
if (PART == "rest-knob") translate(S * [WHEEL_AT[0], 0, WHEEL_AT[1]]) knob();
if (PART == "assembly") rotate([90, 0, 0]) { upper(); lower(); for (t = TOGGLES) translate(S * [t[0], 0, t[1]]) rotate([0, F_ALPHA - 0.3, 0]) { rocker(); foot(); }
                          translate(S * [WHEEL_AT[0], 0, WHEEL_AT[1]]) { wheel(); knob(); } }
