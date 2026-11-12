// hand.scad -- the Galton board's operator's hand (Babbage's Hall): a copy
// of the Digi-Comp II's (exhibits/DigiComp2/parts/hand.scad). The
// exhibit's, not the machine's, and drawn only (it touches nothing). In
// millimetres: the tip of the pointing finger is at the origin, the finger
// pointing down -y; the palm, the curled fingers and the thumb rise behind
// it along +y and +z (the script turns it). Kept apart from galton.scad so
// that changing the board doesn't remake it.

$fn = 20;
module knuckles(pts) for (i = [0 : len(pts) - 2]) hull() {
  translate(pts[i][0]) sphere(r = pts[i][1]);
  translate(pts[i + 1][0]) sphere(r = pts[i + 1][1]);
}
module hand() {
  // the pointing finger, tip down, leaning back toward the operator
  knuckles([[[0, 8, 2], 7.5], [[0, 32, 12], 8.2], [[0, 56, 26], 9.2]]);
  // the palm: flat, sloping back from the knuckles to the wrist
  hull() for (p = [[-4, 58, 26], [44, 55, 23], [-2, 84, 74], [40, 82, 72]]) translate(p) sphere(r = 10);
  // the other three fingers, curled under, each to its own knuckle
  for (x = [14, 27, 40]) knuckles([[[x, 55, 22], 8], [[x, 38, 22], 7.5], [[x, 30, 34], 7]]);
  // the thumb, along the pointing finger
  knuckles([[[-10, 74, 58], 9], [[-18, 52, 36], 8], [[-12, 34, 20], 7]]);
  // (no forearm: the hand alone, which hides less)
}
