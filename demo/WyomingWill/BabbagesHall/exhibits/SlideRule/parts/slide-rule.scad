// slide-rule.scad -- Babbage's Hall, the slide rule
//
// A Mannheim simplex rule, 25 cm scales: A on the upper stator; B, CI and
// C on the slide; D, K and L on the lower stator; a cursor with a
// hairline. Millimetres.
//
// THE RULE'S FRAME: x along the rule (0 at the scales' left index, 1 on C
// and D; 250 at the right index), y across its face (the slide's middle
// at 0, the A side +y), z out of the face (the face at 0). The slide and
// the cursor are drawn here closed (the slide's 1 over D's 1, the
// hairline at x = 0); slide-rule.lua moves them.
//
// THE TABLE'S FRAME: x along the rule, y away from the viewer, z up from
// the table. The rule lies on two feet, tilted TILT degrees toward the
// viewer: ruleOnTable() takes the rule's frame to the table's.
//
// Printed: the stock and the slide (each in two halves, joined by splice
// bars under them), the cursor's frame, the two feet, the slate. Bought:
// a 2 mm clear acrylic window for the cursor. The scales are printed on
// paper (make-scales.py, scales.pdf) and glued on. README.md has the
// parts and how they go together.

L = 250;              // the scales' length: one decade of C and D
X0 = -20; X1 = 270;   // the stock's and the slide's ends
SPLIT = 125;          // where the halves meet
// across the face (y)
YA = 19;              // the upper stator's edge (A)
YS = 9;               // the slide's edges, at the face (+-)
YB = -27;             // the lower stator's edge (D, K, L)
// through it (z)
ZB = -8;              // the stock's back
ZC = -4.5;            // the channel's floor
YSB = 10.5;           // the channel's half width at its floor (a dovetail)
CLR = 0.2;            // the slide's clearance in the channel
// the edges' grooves, for the cursor's tongues
GZ = -4; GD = 1.5; GH = 1.2;     // their middle, depth, half height
// the cursor
CW = 15;              // its half width, along the rule
CZ0 = 0.6; CZ1 = 3.6; // its front plate, above the face
WX = 11;              // the window's opening, half width
// the feet
TILT = 25;            // the rule's face, from level
FOOT_X = [16, 234];   // the feet's middles, along the rule
FOOT_W = 12;
PEG_Y = -18;          // the pegs, under the lower stator
H0 = 8 + (-YB) * sin(TILT) - ZB * cos(TILT);   // the rule's origin above the table (its lowest edge 8 mm up)
Y0 = -30;             // ... and from the table's middle, toward the viewer

module ruleOnTable() translate([0, Y0, H0]) rotate([TILT, 0, 0]) children();

// the stock: one bar, a dovetail channel for the slide, a V groove in each
// long edge for the cursor, two peg holes and two splice recesses behind
module stockSection() polygon([
  [YB, ZB], [YA, ZB],
  [YA, GZ - GH], [YA - GD, GZ], [YA, GZ + GH], [YA, 0],
  [YS, 0], [YSB, ZC], [-YSB, ZC], [-YS, 0], [YB, 0],
  [YB, GZ + GH], [YB + GD, GZ], [YB, GZ - GH]]);
module stock() difference() {
  translate([X0, 0, 0]) rotate([90, 0, 90]) linear_extrude(X1 - X0) stockSection();
  for (x = FOOT_X) translate([x, PEG_Y, ZB - 1]) cylinder(d = 4, h = 5, $fn = 20);
  stockSplices(0.2);
}
// (the splice bars: under each stator, across the joint)
module stockSplices(c = 0) for (y = [YA - 6, YB + 7])
  translate([SPLIT - 20 - c, y - 3 - c, ZB - 1]) cube([40 + 2 * c, 6 + 2 * c, 1 + 2 + c]);
// the slide: the channel's shape less the clearance, a splice recess behind
module slideSection() polygon([
  [-YS + CLR, 0], [YS - CLR, 0], [YSB - CLR, ZC + CLR], [-YSB + CLR, ZC + CLR]]);
module slide() difference() {
  translate([X0, 0, 0]) rotate([90, 0, 90]) linear_extrude(X1 - X0) slideSection();
  slideSplice(0.2);
}
module slideSplice(c = 0) translate([SPLIT - 20 - c, -5 - c, ZC + CLR - 1]) cube([40 + 2 * c, 10 + 2 * c, 1 + 1.5 + c]);

// the cursor: a front plate over the face with the window's opening and a
// recess under it for the acrylic, and an end piece down each long edge
// with a V tongue in the edge's groove. The hairline at x = 0.
module cursorFrame() difference() {
  union() {
    translate([-CW, YB - 2.5, CZ0]) cube([2 * CW, YA - YB + 5, CZ1 - CZ0]);
    for (s = [0, 1]) {
      y0 = s == 0 ? YA + 0.3 : YB - 2.5;
      translate([-CW, y0, GZ - 2]) cube([2 * CW, 2.2, CZ0 - GZ + 2.01]);
      // the tongue
      ye = s == 0 ? YA + 0.5 : YB - 0.5;          // (from inside the end piece, so the two are one solid)
      yt = s == 0 ? YA - GD + 0.6 : YB + GD - 0.6;
      translate([-CW, 0, 0]) rotate([90, 0, 90]) linear_extrude(2 * CW)
        polygon([[ye, GZ - GH + 0.3], [yt, GZ], [ye, GZ + GH - 0.3]]);
    }
  }
  translate([-WX, YB + 1, CZ0 - 1]) cube([2 * WX, YA - YB - 2, CZ1 - CZ0 + 2]);       // the opening
  translate([-WX - 2, YB - 0.2, CZ0 - 0.01]) cube([2 * WX + 4, YA - YB + 0.4, 2.01]);    // the acrylic's recess (2 mm)
}
module cursorWindow() translate([-WX - 2 + 0.1, YB - 0.1, CZ0]) cube([2 * WX + 3.8, YA - YB + 0.2, 2]);
// the hairline, drawn on the window's underside
module hairline() translate([-0.15, YB - 0.5, CZ0 - 0.02]) cube([0.3, YA - YB + 1, 0.05]);

// a foot, in the table's frame: a wedge under the stock's back, inside its
// edges (so the cursor's end pieces pass), with a peg into the rule
module foot(x) {
  p1 = [YB + 2, ZB]; p2 = [YA - 2, ZB];
  function t(p) = [Y0 + p[0] * cos(TILT) - p[1] * sin(TILT), H0 + p[0] * sin(TILT) + p[1] * cos(TILT)];
  a = t(p1); b = t(p2);
  translate([x - FOOT_W / 2, 0, 0]) rotate([90, 0, 90]) linear_extrude(FOOT_W)
    polygon([[a[0] - 6, 0], [b[0] + 4, 0], b, a]);
  ruleOnTable() translate([x, PEG_Y, ZB - 0.5]) cylinder(d = 3.8, h = 4, $fn = 20);
}

// the operator's finger (drawn, not printed): its tip at the origin, along +z
module finger() {
  hull() {
    sphere(d = 14, $fn = 24);
    translate([0, 0, 60]) sphere(d = 17, $fn = 24);
  }
  translate([0, -5.2, 6]) rotate([-12, 0, 0]) scale([1, 0.35, 1]) cylinder(d = 10, h = 12, $fn = 20);
}

// the slate (as the suanpan's, wider and lower): a board in a frame, on a foot; its face
// toward -y, its foot on the table, in the table's frame at y = 0
SLATE_W = 340; SLATE_H = 120; SLATE_T = 8;
SLATE_Y = 60;         // its face, from the table's middle
module slate() {
  translate([-SLATE_W / 2, 0, 20]) cube([SLATE_W, SLATE_T, SLATE_H]);
  translate([-SLATE_W / 2 + 20, -30, 0]) cube([SLATE_W - 40, 60 + SLATE_T, 6]);
  for (s = [-1, 1]) translate([s * (SLATE_W / 2 - 40) - 6, 0, 0]) cube([12, SLATE_T, 24]);
}
module slateFrame() difference() {
  translate([-SLATE_W / 2 - 8, -2, 12]) cube([SLATE_W + 16, SLATE_T + 2, SLATE_H + 16]);
  translate([-SLATE_W / 2, -3, 20]) cube([SLATE_W, SLATE_T + 4, SLATE_H]);
}

// the whole, closed, in the table's frame (for pictures)
module assembly() {
  ruleOnTable() { color("tan") stock(); color("ivory") slide(); color("gray") cursorFrame(); }
  for (x = FOOT_X) color("sienna") foot(x);
  translate([125, SLATE_Y, 0]) color("darkslategray") slate();
}

// (for make-stls.sh: each part turned to lie on the printer's bed)
PART = "";
module halfX(lo) intersection() { children(); translate([lo ? X0 - 1 : SPLIT, -100, -100]) cube([lo ? SPLIT - X0 + 1 : X1 - SPLIT + 1, 200, 200]); }
if (PART == "stock-left") halfX(true) stock();               // (face up: the dovetail's undercut is 20 degrees)
if (PART == "stock-right") halfX(false) stock();
if (PART == "slide-left") translate([0, 0, -ZC]) halfX(true) slide();   // (its wide back down)
if (PART == "slide-right") translate([0, 0, -ZC]) halfX(false) slide();
if (PART == "stock-splice") cube([40, 6, 2]);
if (PART == "slide-splice") cube([40, 10, 1.4]);
if (PART == "cursor") rotate([180, 0, 0]) cursorFrame();     // (the front plate down)
if (PART == "foot") rotate([0, -90, 0]) foot(0);              // (on its side)
module halfS(s) intersection() { children(); translate([s < 0 ? -200 : 0, -100, -1]) cube([200, 200, 300]); }
if (PART == "slate-left") rotate([-90, 0, 0]) halfS(-1) slate();
if (PART == "slate-right") rotate([-90, 0, 0]) halfS(1) slate();
if (PART == "slate-frame-left") rotate([-90, 0, 0]) halfS(-1) slateFrame();
if (PART == "slate-frame-right") rotate([-90, 0, 0]) halfS(1) slateFrame();
