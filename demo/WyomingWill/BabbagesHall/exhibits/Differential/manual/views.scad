// views.scad -- the manual's pictures of the Differential (Babbage's Hall):
// the parts as put together in differential.scad, drawn by OpenSCAD.
//   VIEW = "all"    the whole machine
//   VIEW = "gears"  only the four gears, the cross pin and the rods
include <../parts/differential.scad>
VIEW = "all";
if (VIEW == "all") assembly();
if (VIEW == "gears") {
  color("BurlyWood") {
    translate([-APEX, 0, 0]) rotate([0, 90, 0]) side();
    translate([APEX, 0, 0]) rotate([0, -90, 0]) side();
  }
  color("Goldenrod") {
    translate([0, -APEX, 0]) rotate([-90, 0, 0]) rotate(360 / N / 2) spider();
    translate([0, APEX, 0]) rotate([90, 0, 0]) rotate(360 / N / 2) spider();
  }
  color("Silver") rotate([90, 0, 0]) cylinder(d = 5, h = 2 * APEX + 30, center = true, $fn = 16);
  color("Silver") for (s = [-1, 1]) translate([s * (APEX + HUB_L / 2 + 20), 0, 0]) rotate([0, 90, 0]) cylinder(d = 5, h = HUB_L + 60, center = true, $fn = 16);
}
