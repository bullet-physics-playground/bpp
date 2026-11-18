// views.scad -- the manual's pictures of the Pascaline (Babbage's Hall):
// the printed parts, put together as in pascaline.scad, set to a state.
//   VIEW = "front"  the front: plate, dials, stops, the plate's numbers
//   VIEW = "works"  behind the front plate: the pin wheels, the cams, the
//                   sautoirs and their pawls (no plates, no dials)
// V = the digits' turns [hundreds, tens, units] (in units of 36 degrees);
// LEV, PAWL = the sautoirs' and pawls' angles (degrees), as the
// simulation reported them (PA_DEBUG=1); STY = [digit, angle] puts the
// stylus in the hole at that angle clockwise from the top (none: [-1, 0]).
include <../parts/pascaline.scad>
VIEW = "front";
V = [0, 0, 0];
LEV = [0, 0];
PAWL = [0, 0];
STY = [-1, 0];
function at(i) = [S * (-i * D), S * Y0, 0];              // digit i's axle (0: units)
module turned(i) translate(at(i)) rotate(-V[2 - i] * STEP) children();
if (VIEW == "front") {
  color("BurlyWood") frontPlate();
  color([0.25, 0.2, 0.15]) plateNumbers();
  for (i = [0 : ND - 1]) {
    turned(i) { color("Ivory") dial(false); color([0.2, 0.15, 0.1]) dialNumbers(); }
    color("DimGray") stop(i);
  }
  if (STY[0] >= 0) color("SteelBlue") translate(at(STY[0])) rotate(-STY[1]) translate([0, S * STYLUS_R, 0]) stylus();
}
if (VIEW == "works") {
  for (i = [0 : ND - 1]) turned(i) color(i < 2 ? "Peru" : "Tan") digit(i < 2);
  for (i = [0 : ND - 2]) {
    p = S * LEVER_PIVOTS[i]; h = S * PAWL_HINGES[i];
    translate([p[0], p[1], 0]) rotate(LEV[i]) translate([-p[0], -p[1], 0]) {
      color("SteelBlue") lever(i);
      translate([h[0], h[1], 0]) rotate(PAWL[i]) translate([-h[0], -h[1], 0]) color("Firebrick") pawl(i);
    }
    color("Silver") translate([p[0], p[1], p[2]]) cylinder(d = 3, h = 30, center = true, $fn = 16);
  }
}
