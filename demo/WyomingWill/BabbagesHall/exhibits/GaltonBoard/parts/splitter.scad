// splitter.scad -- Babbage's Hall, the splitter board (SPLITTERS.md)
//
// The Galton board's parts (galton.scad: the wheels, gears, crank, slide,
// drawer, front sheet, stand, sign), sized by the splitter board's geometry
// (splitter-geometry.scad, made by galton.lua from splitter-geometry.lua:
// included after galton.scad, so its sizes are the ones used). What
// differs is here: the board, with its exit blocks, ramps and tubes; the
// teeth, printed apart (they are what is swapped to tune the board); the
// marks, in the bins and the tubes.

include <galton.scad>
include <splitter-geometry.scad>

// the board: the Galton board's, with the solids (the exit blocks, the
// ramps, the tubes' walls) standing in the ball space
module board() difference() {
  union() {
    translate([0, 0, -BACK_T]) linear_extrude(BACK_T) difference() { outside(); bay(); }
    linear_extrude(GAP) wallsPlan();
    for (q = SOLIDS) linear_extrude(GAP) polygon(q);
    for (x = DIVIDERS) {
      translate([x - DIV_T / 2, Y_FLOOR, 0]) cube([DIV_T, Y_DIV - Y_FLOOR, GAP]);
      translate([x, Y_DIV, 0]) cylinder(d = DIV_T, h = GAP, $fn = 12);
    }
  }
  for (sx = [-1, 1]) translate([sx * WHEEL_X, WHEEL_Y, -BACK_T - 1]) cylinder(d = AXLE_D + 0.2, h = BACK_T + 2, $fn = 16);
  for (s = SCREWS) translate([s[0], s[1], -1]) cylinder(d = SCREW_D, h = GAP + 2, $fn = 12);
  for (p = PINS) translate([p[0], p[1], -BACK_T - 1]) cylinder(d = PIN_D, h = BACK_T + 1.5, $fn = 16);   // the pins' holes
  marksCut();
}
// the teeth: each printed apart, a wedge on its steel pin (the pin through
// a hole at its apex); a set of one neck length is swapped for another
module teeth() difference() {
  for (q = TEETH) linear_extrude(GAP - 0.4) polygon(q);
  for (p = PINS) translate([p[0], p[1], -1]) cylinder(d = PIN_D + 0.2, h = GAP + 2, $fn = 16);
}
// the pins, steel, drawn
module pinsDrawn() for (p = PINS) translate([p[0], p[1], 0]) cylinder(d = PIN_D + 0.1, h = GAP + 0.05, $fn = 16);
// the exact counts for NBALLS balls: a line across each bin and each tube
module marks(depth) {
  for (k = [0 : NBINS - 1]) if (EXPECTED[k] > 0.5)
    translate([BINS[k] - (S - DIV_T) / 2 + 0.6, Y_FLOOR + EXPECTED[k] - 0.5, -depth])
      cube([S - DIV_T - 1.2, 1.0, depth + 0.05]);
  for (m = TUBE_MARKS) translate([m[0] - TUBE_IN / 2 + 0.5, m[1] - 0.5, -depth]) cube([TUBE_IN - 1, 1.0, depth + 0.05]);
}
