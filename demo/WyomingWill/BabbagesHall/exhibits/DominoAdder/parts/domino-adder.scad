// The Domino Half Adder -- Babbage's Hall
//
// Every printable part of the exhibit, in millimetres. The simulation loads
// these same shapes (scaled to its centimetres), so what you print is what
// was simulated. make-stls.sh (one folder up) makes them all; by hand:
//
//   openscad -o domino.stl   -D 'PART="domino"'   domino-adder.scad
//   openscad -o tile-2-3.stl -D 'PART="tile"' -D TX=2 -D TY=3 domino-adder.scad
//   openscad -o sign-SUM.stl -D 'PART="sign"' -D 'TEXT="SUM"' domino-adder.scad
//   openscad -o template.svg -D 'PART="template2d"' domino-adder.scad   (1:1 paper template)
//
// PARTS
//   domino      48 x 24 x 7.5 mm, the standard size: print about 260, or use
//               a box of ordinary dominoes (wood, plastic, bone: all fine)
//   tell        a tell-tale tile, 40 x 60 x 4 mm, digits engraved 0.6 mm: 0 on
//               its front, 1 on its back (two of them, SUM and CARRY)
//   inlay0/1    the digits, to print in a contrasting colour and press in
//   tile        the placement template, in 200 mm tiles (see below)
//   pin         3 mm alignment pins for the tiles' corner holes
//   sign        a little standing sign: A, B, GO, SUM, CARRY (printed standing
//               on its foot)
//
// THE TEMPLATE: the dominoes stand in pockets in thin tiles laid on the
// table. A pocket holds its domino where the simulation put it (to 0.4 mm
// and about 2 degrees), and its 1.6 mm wall stops the domino's foot from
// sliding as it tips -- the simulation has the same walls. Tiles butt
// together on a 200 mm grid, pinned at the corners. The two switch pockets
// of each input are outlined twice.

include <layout.scad>   // made by make-stls.sh from the exhibit's own layout:
                        // DOMINOES = [[x, y, heading_deg, kind], ...] (mm; kind 0 a domino,
                        // 1 a switch domino, 2 a tell-tale), TILES_X, TILES_Y

PART = "";
TX = 0; TY = 0;
TEXT = "A";

// the domino
DOM_W = 24; DOM_H = 48; DOM_T = 7.5;
EDGE = 0.8;                 // its edges rounded off this much (the simulation's are square)
// the tell-tale
TELL_W = 40; TELL_H = 60; TELL_T = 4;
DIGIT = 30; ENGRAVE = 0.6;
// the template
POCKET_C = 0.4;             // clearance round a domino, each side
WALL_W = 1.2;               // pocket wall width
WALL_H = 1.6;               // tile thickness (the walls' height)
TILE = 200;                 // tile size
BAR = 5;                    // lattice bars
GRID = 40;                  // lattice pitch
PIN_D = 3;                  // alignment pins

FONT = "DejaVu Serif:style=Bold";

module domino() {
  // lying flat, as printed: 48 long in x, 24 wide in y, 7.5 thick in z
  hull() for (x = [-1, 1], y = [-1, 1])
    translate([x * (DOM_H / 2 - EDGE), y * (DOM_W / 2 - EDGE), 0]) cylinder(r = EDGE, h = DOM_T, $fn = 16);
}

// the tell-tale, standing as on the board, centred: x across, y up, z toward
// you. Its 0 faces you (+z); the 1 is on its back, upside down, so that it
// reads the right way up when the tile has fallen toward you.
module digit(d) linear_extrude(ENGRAVE + 0.01) text(d, size = DIGIT, halign = "center", valign = "center", font = FONT);
module inlay(d) {
  if (d == "0") translate([0, 0, TELL_T / 2 - ENGRAVE]) digit("0");
  else translate([0, 0, -TELL_T / 2 + ENGRAVE]) rotate([180, 0, 0]) digit("1");
}
module tell() difference() { cube([TELL_W, TELL_H, TELL_T], center = true); inlay("0"); inlay("1"); }

// a footprint where it stands, seen from above (x to the right, y away from
// you); heading h: travel (sin h, cos h), so the shape is turned by -h
module footprint(d, grow) {
  w = (d[3] == 2) ? TELL_W : DOM_W;
  t = (d[3] == 2) ? TELL_T : DOM_T;
  translate([d[0], d[1]]) rotate(-d[2]) square([w + 2 * grow, t + 2 * grow], center = true);
}

module template2d() {
  difference() {
    union() for (d = DOMINOES) footprint(d, POCKET_C + WALL_W);
    for (d = DOMINOES) footprint(d, POCKET_C);
  }
  // the switches' pockets, outlined a second time
  for (d = DOMINOES) if (d[3] == 1) difference() { footprint(d, POCKET_C + 2 * WALL_W + 1); footprint(d, POCKET_C + WALL_W + 1); }
}

module tile(tx, ty) {
  x0 = tx * TILE; y0 = ty * TILE;
  difference() {
    linear_extrude(WALL_H) intersection() {
      translate([x0, y0]) square(TILE);
      union() {
        template2d();
        // a border and a lattice, so that a tile is one stiff piece
        translate([x0, y0]) difference() { square(TILE); translate([BAR, BAR]) square(TILE - 2 * BAR); }
        for (g = [GRID : GRID : TILE - 1]) {
          translate([x0 + g - BAR / 4, y0]) square([BAR / 2, TILE]);
          translate([x0, y0 + g - BAR / 4]) square([TILE, BAR / 2]);
        }
        for (cx = [0, 1], cy = [0, 1]) translate([x0 + cx * TILE, y0 + cy * TILE]) circle(d = 4 * PIN_D, $fn = 24);
      }
    }
    // the pockets go right through: a domino stands on the table
    translate([0, 0, -1]) linear_extrude(WALL_H + 2) for (d = DOMINOES) footprint(d, POCKET_C);
    // the pin holes at the corners (a quarter of each falls in this tile)
    for (cx = [0, 1], cy = [0, 1]) translate([x0 + cx * TILE, y0 + cy * TILE, -1]) cylinder(d = PIN_D + 0.3, h = WALL_H + 2, $fn = 16);
  }
}

module pin() cylinder(d = PIN_D, h = 2 * WALL_H, $fn = 16);

// a sign, standing: raised letters on a plate, on a foot. Centred on its
// foot, the letters facing you (+z), y up.
module sign(t) {
  w = 14 + 11 * len(t);
  translate([-w / 2, 0, -1.5]) cube([w, 22, 3]);
  translate([0, 11, 1.5]) linear_extrude(1.2) text(t, size = 12, halign = "center", valign = "center", font = FONT);
  translate([-w / 2, 0, -7]) cube([w, 3, 14]);          // its foot
}

if (PART == "domino") domino();
if (PART == "tell") tell();
if (PART == "inlay0") inlay("0");
if (PART == "inlay1") inlay("1");
if (PART == "tile") tile(TX, TY);
if (PART == "pin") pin();
if (PART == "sign") rotate([90, 0, 0]) sign(TEXT);     // (printed standing on its foot)
if (PART == "template2d") template2d();
