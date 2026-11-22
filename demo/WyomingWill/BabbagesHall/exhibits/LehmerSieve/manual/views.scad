// views.scad -- the manual's pictures of Lehmer's number sieve (Babbage's
// Hall): the printed parts, put together as in lehmer-sieve.scad, the
// wheels turned to x and pegged for N.
//   VIEW = "machine"  the whole machine
//   VIEW = "geneva"   one level, from above: the 9-place star, its crank,
//                     pin and locking disc (CRANK: the drive's angle)
// X = the turn the wheels stand at; PEGS = for each wheel (9, 8, 7, 5 places)
// the holes pegged (make-figures.py works them out for N as the exhibit does);
// SIGN = 1 or -1, the way a turn moves a wheel in the plan.
include <../parts/lehmer-sieve.scad>
VIEW = "machine";
X = 0;
PEGS = [[], [], [], []];
CRANK = 0;
SIGN = 1;
module turnedWheel(i) {
  m = MODS[i];
  rotate([0, SIGN * (X % m) * 360 / m, 0]) children();
}
if (VIEW == "machine") {
  color("Tan") base();
  color("Silver") { axle(); shaft(); }
  for (i = [0 : len(MODS) - 1]) {
    turnedWheel(i) {
      color([0.95, 0.93, 0.85]) wheel(i);
      color([0.2, 0.15, 0.1]) wheelNumbers(i);
      color("Firebrick") for (k = PEGS[i]) peg(i, k);
    }
    color("SteelBlue") { crank(i); lock(i); pin(i); }
    color("Peru") detent(i);
  }
  color("SteelBlue") { cam(); handle(); }
  color("DimGray") { probeRod(); probeArm(); }
}
if (VIEW == "geneva") {
  i = 0;
  turnedWheel(i) { color([0.95, 0.93, 0.85]) wheel(i); color([0.2, 0.15, 0.1]) wheelNumbers(i); color("Firebrick") for (k = PEGS[i]) peg(i, k); }
  translate([C, 0, 0]) rotate([0, CRANK, 0]) translate([-C, 0, 0]) color("SteelBlue") { crank(i); lock(i); pin(i); }
  color("DimGray") probeRod();
}
