// The Differential -- Babbage's Hall
//
// A bevel-gear differential that adds: turn input A by a and input B by b,
// and the carrier turns by (a + b) / 2. Its dial is engraved at twice the
// scale, so it reads a + b. Every part, in millimetres; the simulation loads
// these same shapes (scaled to its centimetres) and turns them by their
// teeth alone. make-stls.sh (one folder up) makes them all; by hand:
//
//   openscad -o side.stl -D 'PART="side"' differential.scad
//
// PARTS (and what else you need: see README.md)
//   side        a side gear with its hub: 2 (A and B)
//   spider      a spider (planet) gear: 2
//   carrier     the carrier: a ring round the gears with the numbers 0..19
//               on its rim, the bosses for the spiders' cross pin, and a
//               cage riding on the side gears' hubs
//   drum        an input's number drum, 0..9: 2
//   crank       an input's crank: 2
//   frame       the base, the two posts the rods turn in, and the three
//               pointers, beside the drums and the ring at the front
//
// The gears are GregFrost's parametric involute bevel gears (GPL), in
// gearsv50.scad beside this file.

include <gearsv50.scad>

PART = "";

N = 16;                         // teeth on every gear (mitre gears: all alike)
PD = 60;                        // pitch diameter at the back of the teeth
OCP = PD * 180 / N;             // (GregFrost's "outside circular pitch")
CONE = PD / 2 * sqrt(2);        // cone distance, for a 45-degree pitch angle
FACE = 14;                      // face width
THICK = 6;                      // gear body behind the teeth
PRESSURE = 25;
BACKLASH = 0.3;
BORE = 5.3;                     // for 5 mm rods
APEX = sqrt(CONE * CONE - (PD / 2) * (PD / 2));     // the pitch apex's height above the gear's back

// the gear on its own, its back at z = 0, the apex at z = APEX
module bevel() bevel_gear(number_of_teeth = N, cone_distance = CONE, face_width = FACE,
                          outside_circular_pitch = OCP, pressure_angle = PRESSURE,
                          clearance = 0.2, bore_diameter = BORE, gear_thickness = THICK,
                          backlash = BACKLASH);

// THE LAYOUT (millimetres; as the simulation has it: x along the axis, to
// the right; y up; z toward you; the gears' common apex at the origin)
//   side gears' backs at x = -/+APEX, their hubs running out from there;
//   the carrier's ring round the middle, its cage riding on the hubs at
//   x = -/+CAGE_X; the input drums at x = -/+DRUM_X; the frame's posts
//   (the rods' bearings) at x = -/+POST_X; the cranks outside them.
HUB_D = 16; HUB_L = 40;
CAGE_X = APEX + 12;             // the cage's end plates
DRUM_X = APEX + 25;             // the input drums' middles
POST_X = APEX + 45;             // the frame's posts
CRANK_X = POST_X + 10;
ROD_L = 2 * (POST_X + 16);      // each input's rod, from its side gear out past its crank

// a side gear: the bevel, and a hub behind it (z < 0); the rod is glued in
module side() {
  difference() {
    union() { bevel(); translate([0, 0, -HUB_L]) cylinder(d = HUB_D, h = HUB_L + 1, $fn = 48); }
    translate([0, 0, -HUB_L - 1]) cylinder(d = BORE, h = HUB_L + APEX + 2, $fn = 24);
  }
}
module spider() bevel();

// numbers round a drum's rim, about the x axis, raised 1 mm: number i at
// i steps back from the front, so that turning the drum forward (about +x)
// by i steps brings i to the front, where the pointer is, upright
module rimNumbers(r, n, w, size, step = 1)
  for (i = [0 : n - 1]) rotate([90 - i * 360 / n, 0, 0]) translate([0, r - 1, 0]) rotate([-90, 0, 0])
    linear_extrude(2) text(str(i * step), size = size, halign = "center", valign = "center",
                           font = "DejaVu Sans:style=Bold");

// an input's drum: ten numbers, a unit for each tenth of a turn
DRUM_R = 24; DRUM_W = 12;
// (numbers = false: without them -- the simulation draws them apart, in another colour)
module drum(numbers = true) {
  difference() {
    union() {
      rotate([0, 90, 0]) cylinder(r = DRUM_R, h = DRUM_W, center = true, $fn = 96);
      if (numbers) rimNumbers(DRUM_R, 10, DRUM_W, 8);
    }
    rotate([0, 90, 0]) cylinder(d = BORE, h = DRUM_W + 2, center = true, $fn = 24);
  }
}

// the carrier: a ring round the cluster (clear of the spiders' backs, which
// sweep a circle of radius sqrt(2) * APEX), the bosses for the cross pin the
// spiders turn on, and a cage that rides on the side gears' hubs. Its rim
// carries twenty numbers: it turns half as far as an input, so it reads A + B.
RING_R = sqrt(2) * (APEX + 2) + 4;      // inside radius
RING_T = 6; RING_W = 14;
module drumNumbers() rimNumbers(DRUM_R, 10, DRUM_W, 8);
module carrierNumbers() rimNumbers(RING_R + RING_T, 20, RING_W, 8);
module carrier(numbers = true) {
  difference() {
    union() {
      rotate([0, 90, 0]) difference() {
        cylinder(r = RING_R + RING_T, h = RING_W, center = true, $fn = 120);
        cylinder(r = RING_R, h = RING_W + 2, center = true, $fn = 120);
      }
      if (numbers) carrierNumbers();
      // the cross pin's bosses, inside the ring
      for (s = [-1, 1]) translate([0, s * (RING_R - 2), 0]) rotate([90, 0, 0]) cylinder(d = 14, h = 8, center = true, $fn = 32);
      // the cage: four bars out along x, between the numbers' rows, and an
      // end plate at each end round a hub
      for (a = [45, 135, 225, 315]) rotate([a, 0, 0]) translate([0, RING_R + RING_T / 2, 0])
        cube([2 * CAGE_X + 6, 5, 5], center = true);
      for (s = [-1, 1]) translate([s * CAGE_X, 0, 0]) rotate([0, 90, 0]) {
        cylinder(d = HUB_D + 8, h = 6, center = true, $fn = 48);
        for (a = [45, 135, 225, 315]) rotate(a) translate([0, (RING_R + RING_T) / 2, 0]) cube([5, RING_R + RING_T, 6], center = true);
      }
    }
    // the cross pin, and the hubs' holes
    rotate([90, 0, 0]) cylinder(d = BORE, h = 3 * RING_R, center = true, $fn = 24);
    rotate([0, 90, 0]) cylinder(d = HUB_D + 0.6, h = 2 * CAGE_X + 20, center = true, $fn = 48);
  }
}

// a crank, on an input's rod outside its post (the arm along +y at zero)
module crank() {
  difference() {
    union() {
      rotate([0, 90, 0]) cylinder(d = 16, h = 8, center = true, $fn = 48);
      translate([-4, 0, -4]) cube([8, 40, 8]);
      translate([0, 38, 0]) rotate([0, 90, 0]) cylinder(d = 9, h = 22, $fn = 32);   // the handle, outward
    }
    rotate([0, 90, 0]) cylinder(d = BORE, h = 10, center = true, $fn = 24);
  }
}

// the frame (as it stands: y up): a base, the two posts the rods turn in,
// and three pointers on stalks from the base, each beside a drum or the
// ring at the front, pointing at the number that is read
AXIS_H = RING_R + RING_T + 22;          // the axis's height above the base
BASE_W = 110;
module pointer(px, r, w) {
  // the tip just left of the rim's front, at the axis's height, pointing right
  tipx = px - w / 2 - 1;
  hull() {
    translate([tipx - 0.5, -0.5, r - 3]) cube([0.5, 1, 1]);
    translate([tipx - 9, -3, r - 4]) cube([3, 6, 3]);
  }
  translate([tipx - 9, -AXIS_H, r - 4]) cube([3, AXIS_H - 2, 3]);       // its stalk, down to the base
}
module frame(pointers = true) {
  translate([-POST_X - 20, -AXIS_H - 8, -BASE_W / 2]) cube([2 * POST_X + 40, 8, BASE_W]);       // the base, under it all
  for (s = [-1, 1]) translate([s * POST_X, 0, 0]) difference() {
    union() {
      translate([-5, -AXIS_H, -14]) cube([10, AXIS_H, 28]);
      rotate([0, 90, 0]) cylinder(d = 28, h = 10, center = true, $fn = 48);
    }
    rotate([0, 90, 0]) cylinder(d = BORE + 0.4, h = 12, center = true, $fn = 24);
  }
  if (pointers) pointers();
}
module pointers() {
  pointer(-DRUM_X, DRUM_R + 1, DRUM_W);
  pointer(DRUM_X, DRUM_R + 1, DRUM_W);
  pointer(0, RING_R + RING_T + 1, RING_W);
}

// FOR THE SIMULATION: Bullet handles convex shapes best, so each gear is
// simulated as convex pieces -- its body (inside the root cone) and each
// tooth (outside it) -- made from these, by make-hulls.py. The root cone
// is GregFrost's, worked out again from his formulas.
PITCH_ANGLE = asin((PD / 2) / CONE);
APEX_TO_APEX = CONE / cos(PITCH_ANGLE);
ADDENDUM = PD / N;
DEDENDUM = ADDENDUM + 0.2;
ROOT_ANGLE = PITCH_ANGLE - atan(DEDENDUM / CONE);
ROOT_FULL_R = tan(ROOT_ANGLE) * APEX_TO_APEX;
module rootCone(grow = 0)
  translate([0, 0, APEX - APEX_TO_APEX]) cylinder(r1 = ROOT_FULL_R + grow, r2 = grow, h = APEX_TO_APEX, $fn = 128);
module sector(i) rotate(i * 360 / N)
  translate([0, 0, -60]) linear_extrude(200) polygon([[0, 0], [200 * cos(180 / N), -200 * sin(180 / N)], [200 * cos(180 / N), 200 * sin(180 / N)]]);
module toothPiece() intersection() { difference() { bevel(); rootCone(0.15); } sector(0); }
module bodyPiece() intersection() { bevel(); rootCone(0); }

// AS PRINTED (PART = "print-..."): each part turned to lie on the bed with
// nothing that needs support
if (PART == "print-side") translate([0, 0, 9.9]) rotate([180, 0, 0]) side();          // teeth down: their 45-degree faces print
if (PART == "print-spider") spider();                                               // back down
if (PART == "print-carrierhalf")                                                     // two of these, glued at the middle
  translate([0, 0, CAGE_X + 3]) rotate([0, 90, 0]) intersection() {
    carrier(); translate([0, -200, -200]) cube([400, 400, 400]);
  }
if (PART == "print-drum") translate([0, 0, DRUM_W / 2]) rotate([0, 90, 0]) drum();
if (PART == "print-crank") translate([0, 0, 4]) rotate([0, -90, 0]) crank();             // the handle up
if (PART == "print-frame") translate([0, 0, AXIS_H + 8]) rotate([90, 0, 0]) frame();  // the base on the bed

if (PART == "side") side();
if (PART == "spider") spider();
if (PART == "carrier") carrier();
if (PART == "crank") crank();
if (PART == "drum") drum();
if (PART == "frame") frame();
if (PART == "tooth") toothPiece();
if (PART == "body") bodyPiece();

// the whole machine, put together as the simulation has it (to look at)
module assembly() {
  color("BurlyWood") {
    translate([-APEX, 0, 0]) rotate([0, 90, 0]) side();
    translate([APEX, 0, 0]) rotate([0, -90, 0]) side();
  }
  color("Goldenrod") {
    translate([0, -APEX, 0]) rotate([-90, 0, 0]) rotate(360 / N / 2) spider();
    translate([0, APEX, 0]) rotate([90, 0, 0]) rotate(360 / N / 2) spider();
  }
  color("SaddleBrown", 0.8) carrier();
  color("Ivory") for (s = [-1, 1]) translate([s * DRUM_X, 0, 0]) drum();
  color("DimGray") for (s = [-1, 1]) translate([s * CRANK_X, 0, 0]) crank();
  color("Silver") for (s = [-1, 1]) translate([s * (APEX + HUB_L / 2 + 20), 0, 0]) rotate([0, 90, 0]) cylinder(d = 5, h = HUB_L + 60, center = true, $fn = 16);
  color("DarkSlateGray") frame();
}
if (PART == "assembly") assembly();
