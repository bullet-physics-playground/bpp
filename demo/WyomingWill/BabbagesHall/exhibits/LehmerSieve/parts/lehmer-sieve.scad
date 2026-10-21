// Lehmer's number sieve -- Babbage's Hall: the printed parts.
//
// Every moving part's outline comes from geometry.scad, which
// make-geometry.py writes, and which also gives the simulation its shapes
// (sieve-geometry.lua): what is printed is what is simulated.
//
// Units: cm, in the machine's own frame (y up; the wheels' axle at x = z
// = 0; the drive shaft at x = C; the probe at x = -RHO). The simulation
// asks for parts as they stand in the machine; make-stls.sh sets PART to
// one of the "print-..." names below, which turns that part to lie on the
// printer's bed and scales it to millimetres.

include <geometry.scad>

PART = "";
$fn = 48;

function star_y(i) = Y0 + i * LEVEL + ARM_T + 0.1;
function crank_y(i) = Y0 + i * LEVEL;
function ga(m) = C * sin(180 / m);                 // a Geneva crank's radius
function idx(m) = search(m, MODS)[0];
// the bore of every part on the drive shaft: a D, the flat on the side away
// from the pins (file a flat 0.8 mm deep along the 6 mm shaft), so that the
// pins, the locking discs and the cam all go on at their angles
module dBore() intersection() { circle(r = SHAFT_R + 0.01, $fn = 24); translate([-(SHAFT_R - 0.08), -1]) square([2, 2]); }

// a plan shape (X, Y) = (x, -z), made a plate from y0 up, t thick
module plate(y0, t) translate([0, y0, 0]) rotate([-90, 0, 0]) linear_extrude(t) children();
module plan(p) polygon(points = p[0], paths = p[1]);

// ---------------------------------------------------------------------------
// the wheels: Geneva stars with a ring of holes at RHO, a number by each
// ---------------------------------------------------------------------------
module wheel(i) plate(star_y(i), STAR_T) plan(STARS[i]);
// hole k is the one under the probe k turns after 0: it is marked k
module wheelNumbers(i) {
  m = MODS[i];
  plate(star_y(i) + STAR_T, 0.05)
    for (k = [0 : m - 1]) {
      a = 180 + k * 360 / m;
      translate([1.45 * cos(a), 1.45 * sin(a)]) rotate(a + 90)
        text(str(k), size = 0.42, halign = "center", valign = "center");
    }
  // the wheel's number of places, by the axle
  plate(star_y(i) + STAR_T, 0.05) translate([0.95, 0]) rotate(90)
    text(str(m), size = 0.36, halign = "center", valign = "center");
}
// a peg, standing in hole k of wheel i (printed, a push fit: 7.6 mm)
module peg(i, k) {
  m = MODS[i];
  a = 180 + k * 360 / m;
  plate(star_y(i) - 0.02, STAR_T + 0.05) translate([RHO * cos(a), RHO * sin(a)]) circle(r = HOLE_R - 0.02);
}

// (the same, at the origin: the simulation moves it to its hole)
module pegShape() plate(-0.02, STAR_T + 0.05) circle(r = HOLE_R - 0.02);

// the detents: a leaf spring for each wheel, its round nose in the mouth of
// the slot opposite the drive (DETENTS: its nose and its root, in the plan)
module detentPlan(i) {
  n = DETENTS[i][0]; r = DETENTS[i][1];
  u = n / norm(n);
  off = DET_NR - DET_T / 2;
  translate(n) circle(r = DET_NR, $fn = 32);
  hull() { translate(n + u * off) circle(d = DET_T, $fn = 8); translate(r) circle(d = DET_T, $fn = 8); }
}
module detent(i) plate(star_y(i), STAR_T) detentPlan(i);
// where its root is held: a block on a post (or, for the wheels whose
// detents stand inside a wheel below, an arm in from a post outside them)
DET_POST_X = -9.9;
function detentPost(i) = let(r = DETENTS[i][1], t = detentDirs(i)[1])
  (norm(r) < 8.4) ? [DET_POST_X, r[1]] : r + t * 0.45;          // (in the plan)
// the leaf's root goes on past the hinge into a slot in its block: that
// much of it doesn't move
function detentDirs(i) = let(n = DETENTS[i][0], r = DETENTS[i][1], u = n / norm(n),
                             s = n + u * (DET_NR - DET_T / 2), t = (r - s) / norm(r - s)) [u, t];
module detentTab(i, extra = 0) {
  r = DETENTS[i][1]; t = detentDirs(i)[1];
  hull() { translate(r - t * 0.05) circle(d = DET_T + extra, $fn = 8); translate(r + t * 0.6) circle(d = DET_T + extra, $fn = 8); }
}
module detentMount(i) {
  r = DETENTS[i][1];
  u = detentDirs(i)[0]; t = detentDirs(i)[1];
  inside = norm(r) < 8.4;
  difference() {
    union() {
      plate(BASE_TOP - 1.2, 1.2) translate(detentPost(i)) circle(r = 0.44);   // (its foot, in the base)
      // the block the leaf's root is held in
      plate(star_y(i), STAR_T) translate(r + t * 0.35) rotate(atan2(t[1], t[0])) square([0.8, 0.7], center = true);
      if (inside) {
        plate(star_y(i), STAR_T) hull() { translate(r + t * 0.35) circle(r = 0.3); translate([DET_POST_X, r[1]]) circle(r = 0.3); }
        plate(BASE_TOP, star_y(i) + STAR_T - BASE_TOP) translate([DET_POST_X, r[1]]) circle(r = 0.45);
      } else {
        plate(BASE_TOP, star_y(i) + STAR_T - BASE_TOP) translate(detentPost(i)) circle(r = 0.45);
      }
    }
    plate(star_y(i) - 0.1, STAR_T + 0.2) detentTab(i, 0.02);        // (the slot: 0.1 mm looser than the leaf)
  }
}
module detentMounts() for (i = [0 : len(MODS) - 1]) detentMount(i);

// ---------------------------------------------------------------------------
// the drive: one shaft; under each wheel a crank with its pin, beside each
// wheel a locking disc; the cam at the top, and the handle
// ---------------------------------------------------------------------------
module crankPlan(m) {
  a = ga(m);
  difference() {
    union() {
      translate([-0.7, -0.55]) square([a + 1.25, 1.1]);
      circle(r = 0.75);
      translate([a, 0]) circle(r = 0.55);
    }
    dBore();
    translate([a, 0]) circle(r = PIN_R);
  }
}
module crank(i) {
  translate([C, 0, 0]) plate(crank_y(i), ARM_T) crankPlan(MODS[i]);
  // its hub, up to the locking disc
  translate([C, 0, 0]) plate(crank_y(i), ARM_T + 0.1) difference() { circle(r = 0.75); dBore(); }
}
module lock(i) {
  translate([C, 0, 0]) plate(star_y(i), STAR_T) difference() { union() { plan(LOCKS[i]); circle(r = 0.75); } dBore(); }
  // its hub, up to the next crank (a spacer above the top one)
  translate([C, 0, 0]) plate(star_y(i) + STAR_T, 0.1) difference() { circle(r = 0.75); dBore(); }
}
module pin(i) {
  a = ga(MODS[i]);
  translate([C + a, 0, 0]) plate(crank_y(i), star_y(i) + STAR_T - crank_y(i)) circle(r = PIN_R, $fn = 24);
}
module shaft() translate([C, 0, 0]) plate(BASE_TOP - 1.8, SHAFT_TOP - BASE_TOP + 1.8) circle(r = SHAFT_R, $fn = 24);

// the cam: a ring whose top rises and falls round it (CAM: the angle in the
// cam's own plan, and the height there), on a web to its hub
// (one closed solid: its points, round the ring, in the cam's own plan with
// its height up, then stood in the machine as the plates are)
module camRing() {
  n = CAM_NW;
  function h(k) = CAM[k % n][1];
  function t(k) = CAM[k % n][0];
  pts = [for (k = [0 : n - 1]) each [
           [CAM_IN * cos(t(k)), CAM_IN * sin(t(k)), CAM_BASE], [CAM_OUT * cos(t(k)), CAM_OUT * sin(t(k)), CAM_BASE],
           [CAM_IN * cos(t(k)), CAM_IN * sin(t(k)), h(k)], [CAM_OUT * cos(t(k)), CAM_OUT * sin(t(k)), h(k)]]];
  function q(k, j) = 4 * (k % n) + j;        // j: 0 inner low, 1 outer low, 2 inner high, 3 outer high
  faces = [for (k = [0 : n - 1]) each [
             [q(k + 1, 0), q(k + 1, 1), q(k, 1)], [q(k + 1, 0), q(k, 1), q(k, 0)],
             [q(k, 3), q(k + 1, 3), q(k + 1, 2)], [q(k, 3), q(k + 1, 2), q(k, 2)],
             [q(k + 1, 1), q(k + 1, 3), q(k, 3)], [q(k + 1, 1), q(k, 3), q(k, 1)],
             [q(k, 2), q(k + 1, 2), q(k + 1, 0)], [q(k, 2), q(k + 1, 0), q(k, 0)]]];   // (triangles: the top isn't flat)
  translate([C, 0, 0]) rotate([-90, 0, 0]) polyhedron(points = pts, faces = faces);
}
module cam() {
  camRing();
  translate([C, 0, 0]) plate(CAM_BASE, 0.6) difference() { circle(r = CAM_IN + 0.05, $fn = 72); dBore(); }
  // (its hub stands on the top locking disc's)
  translate([C, 0, 0]) plate(star_y(len(MODS) - 1) + STAR_T + 0.1, CAM_BASE + 0.6 - star_y(len(MODS) - 1) - STAR_T - 0.1)
    difference() { circle(r = 0.8); dBore(); }
}
// the handle, on the shaft's top: the hand turns it once for each step
module handle() {
  translate([C, 0, 0]) plate(SHAFT_TOP - 0.4, 0.4) difference() {
    hull() { circle(r = 0.7); translate([3.2, 0]) circle(r = 0.5); }
    dBore();
  }
  translate([C + 3.2, 0, 0]) plate(SHAFT_TOP - 0.1, 2.2) circle(r = 0.35);     // (the knob the hand holds)
}

// ---------------------------------------------------------------------------
// the probe: a 5 mm steel rod; an arm out to the cam, with a steel ball
// under it that the cam lifts
// ---------------------------------------------------------------------------
module probeRod() translate([-RHO, 0, 0]) plate(TIP_HIGH, PROBE_LEN) circle(r = PROBE_R, $fn = 24);
FOLLOW_Y = TIP_HIGH + FOLLOW_OFF + FOLLOW_R;      // the ball's centre
module probeArm() {
  difference() {
    translate([-RHO - 0.6, FOLLOW_Y, -0.4]) cube([C - CAM_RF + RHO + 1.0, 0.7, 0.8]);
    translate([-RHO, 0, 0]) plate(FOLLOW_Y - 1, 3) circle(r = PROBE_R, $fn = 24);
    translate([C - CAM_RF, FOLLOW_Y, 0]) sphere(r = FOLLOW_R, $fn = 24);
  }
  translate([-RHO, 0, 0]) plate(FOLLOW_Y, 1.3) difference() { circle(r = 0.6); circle(r = PROBE_R); }
}
module ball() translate([C - CAM_RF, FOLLOW_Y, 0]) sphere(r = FOLLOW_R, $fn = 24);

// ---------------------------------------------------------------------------
// the frame (it doesn't move): the base on its feet, the wheels' axle with
// washers between the wheels, the drive's bearing, the probe's guide, and
// the bell the probe rings when it falls right through
// ---------------------------------------------------------------------------
BASE_X0 = -12; BASE_X1 = 15; BASE_Z = 9.5;
module base() {
  difference() {
    translate([BASE_X0, BASE_TOP - 1.2, -BASE_Z]) cube([BASE_X1 - BASE_X0, 1.2, 2 * BASE_Z]);
    plate(BASE_TOP - 2, 3) circle(r = AXLE_R);
    translate([C, 0, 0]) plate(BASE_TOP - 2, 3) circle(r = SHAFT_R + 0.05);
    translate([-11, 0, 0]) plate(BASE_TOP - 2, 3) circle(r = 0.4);
    translate([-RHO, 0, 0]) plate(BASE_TOP - 2, 3) circle(r = 0.2);
    for (i = [0 : len(MODS) - 1]) plate(BASE_TOP - 2, 3) translate(detentPost(i)) circle(r = 0.45);
  }
}
module feet() for (x = [BASE_X0 + 1.5, BASE_X1 - 1.5], z = [-BASE_Z + 1.5, BASE_Z - 1.5])
  translate([x - 1, 0, z - 1]) cube([2, BASE_TOP - 1.2, 2]);
module bearing() translate([C, 0, 0]) plate(0.2, BASE_TOP - 1.2 - 0.2) difference() { circle(r = 1.0); circle(r = SHAFT_R + 0.05); }
// the lowest crank stands on this, on the base
module shaftWasher() translate([C, 0, 0]) plate(BASE_TOP, Y0 - BASE_TOP) difference() { circle(r = 0.75); circle(r = SHAFT_R + 0.05); }
module axle() plate(BASE_TOP - 1.2, STACK_TOP + 0.5 - BASE_TOP + 1.2) circle(r = AXLE_R, $fn = 24);
module axleTop() plate(STACK_TOP + 0.1, 0.4) difference() { circle(r = 0.8, $fn = 6); circle(r = AXLE_R); }
// the washers between the wheels (and the one under the lowest)
module washer(i) {
  y0 = (i == 0) ? BASE_TOP : star_y(i - 1) + STAR_T;
  plate(y0 + 0.02, star_y(i) - y0 - 0.04) difference() { circle(r = 0.9); circle(r = AXLE_R + 0.02); }
}
module washers() for (i = [0 : len(MODS) - 1]) washer(i);
// the probe's guide: a post behind the wheels, an arm over them to a sleeve
module guide() {
  difference() {
    union() {
      translate([-11.6, BASE_TOP, -0.6]) cube([1.2, GUIDE_Y1 - BASE_TOP, 1.2]);
      translate([-11.6, GUIDE_Y0, -0.6]) cube([11.6 - RHO + 0.7, GUIDE_Y1 - GUIDE_Y0, 1.2]);
      translate([-RHO, 0, 0]) plate(GUIDE_Y0, GUIDE_Y1 - GUIDE_Y0) circle(r = 0.6);
    }
    translate([-RHO, 0, 0]) plate(GUIDE_Y0 - 1, 3) circle(r = PROBE_R + 0.03, $fn = 24);
  }
  translate([-11, 0, 0]) plate(BASE_TOP - 1.5, 1.5) circle(r = 0.4);      // (its foot, into the base)
}
module bell() translate([-RHO, 0, 0]) {
  plate(BASE_TOP, TIP_LOW - BASE_TOP) circle(r = 0.7);           // the probe comes to rest on its floor
  plate(TIP_LOW, 0.3) difference() { circle(r = 0.7); circle(r = 0.5); }
}
module frame() { base(); feet(); bearing(); shaftWasher(); axle(); axleTop(); guide(); }

// ---------------------------------------------------------------------------
// for printing: each part turned to lie on the bed, in millimetres
// ---------------------------------------------------------------------------
module bed(y0) scale(10) rotate([90, 0, 0]) translate([0, -y0, 0]) children();
module wheelPrint(m) { i = idx(m); bed(star_y(i)) { wheel(i); wheelNumbers(i); } }
module crankPrint(m) { i = idx(m); bed(crank_y(i)) translate([-C, 0, 0]) crank(i); }
module lockPrint(m) { i = idx(m); bed(star_y(i)) translate([-C, 0, 0]) lock(i); }

if (PART == "print-wheel-9") wheelPrint(9);
if (PART == "print-wheel-8") wheelPrint(8);
if (PART == "print-wheel-7") wheelPrint(7);
if (PART == "print-wheel-5") wheelPrint(5);
if (PART == "print-crank-9") crankPrint(9);
if (PART == "print-crank-8") crankPrint(8);
if (PART == "print-crank-7") crankPrint(7);
if (PART == "print-crank-5") crankPrint(5);
if (PART == "print-lock-9") lockPrint(9);
if (PART == "print-lock-8") lockPrint(8);
if (PART == "print-lock-7") lockPrint(7);
if (PART == "print-lock-5") lockPrint(5);
if (PART == "print-detent-9") bed(star_y(0)) { detent(0); plate(star_y(0), STAR_T) detentTab(0); }
if (PART == "print-detent-8") bed(star_y(1)) { detent(1); plate(star_y(1), STAR_T) detentTab(1); }
if (PART == "print-detent-7") bed(star_y(2)) { detent(2); plate(star_y(2), STAR_T) detentTab(2); }
if (PART == "print-detent-5") bed(star_y(3)) { detent(3); plate(star_y(3), STAR_T) detentTab(3); }
if (PART == "print-detent-post-9") bed(BASE_TOP - 1.2) detentMount(0);
if (PART == "print-detent-post-8") bed(BASE_TOP - 1.2) detentMount(1);
if (PART == "print-detent-post-7") bed(BASE_TOP - 1.2) detentMount(2);
if (PART == "print-detent-post-5") bed(BASE_TOP - 1.2) detentMount(3);
if (PART == "print-peg") scale(10) cylinder(r = HOLE_R - 0.02, h = STAR_T, $fn = 32);
if (PART == "print-cam") bed(star_y(len(MODS) - 1) + STAR_T + 0.1) translate([-C, 0, 0]) cam();
if (PART == "print-handle") bed(SHAFT_TOP - 0.4) translate([-C, 0, 0]) handle();
if (PART == "print-probe-arm") bed(FOLLOW_Y) translate([RHO, 0, 0]) probeArm();
if (PART == "print-washer") scale(10) difference() { cylinder(r = 0.9, h = 0.56); translate([0, 0, -1]) cylinder(r = AXLE_R + 0.02, h = 3); }
if (PART == "print-washer-low") scale(10) difference() { cylinder(r = 0.9, h = star_y(0) - BASE_TOP - 0.04); translate([0, 0, -1]) cylinder(r = AXLE_R + 0.02, h = 3); }
if (PART == "print-guide") scale(10) translate([11.6, -(BASE_TOP - 1.5), 0.6]) guide();      // (on its side)
if (PART == "print-shaft-washer") scale(10) difference() { cylinder(r = 0.75, h = Y0 - BASE_TOP); translate([0, 0, -1]) cylinder(r = SHAFT_R + 0.05, h = 3); }
if (PART == "print-bearing") scale(10) difference() { cylinder(r = 1.0, h = BASE_TOP - 1.4); translate([0, 0, -1]) cylinder(r = SHAFT_R + 0.05, h = 3); }
if (PART == "print-foot") scale(10) cube([2, 2, BASE_TOP - 1.2]);
if (PART == "print-axle-nut") scale(10) difference() { cylinder(r = 0.8, h = 0.4, $fn = 6); translate([0, 0, -1]) cylinder(r = AXLE_R, h = 3); }
if (PART == "print-bell") bed(BASE_TOP) translate([RHO, 0, 0]) bell();
if (PART == "cut-base") scale(10) projection() rotate([90, 0, 0]) base();
