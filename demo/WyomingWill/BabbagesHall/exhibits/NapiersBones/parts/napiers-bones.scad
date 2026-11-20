// napiers-bones.scad -- Babbage's Hall, Napier's bones
//
// Ten square rods (the bones), an index rod, and Napier's board: a plate
// with a ledge along its bottom and a rim on its left, the index rod lying
// against the rim; the rods are laid on the ledge beside it. The board lies
// on two feet, tilted toward the viewer; a tray beside it holds the rods.
// The faces are printed on paper (make-faces.py, napier-faces.pdf and
// genaille-faces.pdf) and wrapped round the rods. Millimetres.
//
// THE BOARD'S FRAME: x to the right along the ledge (0 at the index rod's
// right side, where the first rod goes), y up the board (0 on the ledge),
// z out of its face (0 on it). THE TABLE'S FRAME: x to the right, y away
// from the viewer, z up. boardOnTable() takes the one to the other.

S = 16;               // a rod's side
RL = 176;             // its length
CH = 0.8;             // its edges' chamfer
NROD = 10;
// the board
BX0 = -22; BX1 = 122; // the plate's ends (the rim from BX0 to -S, the index rod from -S to 0; seven rods' room)
BY0 = -10; BY1 = 182; // the ledge from BY0 to 0
BT = 6;               // the plate's thickness
LH = 8;               // the ledge's and the rim's height above the face
TILT = 20;            // the face, from level
H0 = 10 - BY0 * sin(TILT) + BT * cos(TILT);   // the board's origin above the table (its lowest edge 10 mm up)
BOX = -178; BOY = -60;                        // ... and where on the table
FOOT_X = [8, 96];
// the tray: ten slots, the rods lying in them along y, face 1 up
TX0 = 20;             // its left side, on the table
TP = 19;              // a slot's pitch
TW = 2; TF = 2; TD = 9;                       // its walls, floor, dividers' height
TL = RL + 6;
TY = 10;              // its middle, on the table
// the slate (as the slide rule's, raised above the board)
SLATE_W = 340; SLATE_H = 150; SLATE_T = 8; SLATE_Z = 90;
SLATE_Y = 150;

module boardOnTable() translate([BOX, BOY, H0]) rotate([TILT, 0, 0]) children();

// a rod, its long axis along y, its middle at the origin (chamfered edges)
module rod() hull() {
  for (sx = [-1, 1], sz = [-1, 1])
    translate([sx * (S / 2 - CH), -RL / 2, sz * (S / 2 - CH)]) rotate([-90, 0, 0]) cylinder(r = CH, h = RL, $fn = 8);
}

// the board: plate, ledge, rim; a peg hole for each foot
module board() difference() {
  union() {
    translate([BX0, BY0, -BT]) cube([BX1 - BX0, BY1 - BY0, BT]);
    translate([BX0, BY0, 0]) cube([BX1 - BX0, -BY0, LH]);                 // the ledge
    translate([BX0, 0, 0]) cube([-S - BX0, BY1, LH]);                     // the rim
  }
  for (x = FOOT_X) translate([x, 60, -BT - 1]) cylinder(d = 4, h = 4, $fn = 20);
}
// a foot, in the table's frame: a wedge under the board, a peg into it
module foot(x) {
  function t(p) = [BOY + p[0] * cos(TILT) - p[1] * sin(TILT), H0 + p[0] * sin(TILT) + p[1] * cos(TILT)];
  a = t([BY0 + 4, -BT]); b = t([BY1 - 6, -BT]);
  translate([BOX + x - 6, 0, 0]) rotate([90, 0, 90]) linear_extrude(12)
    polygon([[a[0] - 6, 0], [b[0] + 4, 0], b, a]);
  boardOnTable() translate([x, 60, -BT - 0.5]) cylinder(d = 3.8, h = 3.5, $fn = 20);
}
// the tray, in the table's frame: floor, walls, a divider between slots
module tray() {
  w = 2 * TW + NROD * TP;
  translate([TX0, TY - TL / 2 - TW, 0]) difference() {
    cube([w, TL + 2 * TW, TF + TD]);
    for (k = [0 : NROD - 1]) translate([TW + k * TP + 0.8, TW, TF]) cube([TP - 1.6, TL, TD + 1]);
  }
}
// (a slot's middle, in the table's frame)
function slotX(k) = TX0 + TW + (k - 0.5) * TP;

// the operator's finger (drawn, not printed): its tip at the origin, along +z
module finger() {
  hull() {
    sphere(d = 14, $fn = 24);
    translate([0, 0, 60]) sphere(d = 17, $fn = 24);
  }
  translate([0, -5.2, 6]) rotate([-12, 0, 0]) scale([1, 0.35, 1]) cylinder(d = 10, h = 12, $fn = 20);
}

// the slate, raised on a stand above the board; its face toward -y at y = 0.
// Printed apart: the board in two halves, the stand (a foot and two posts,
// the board resting in slots in the posts) in two halves
module slateBoard() translate([-SLATE_W / 2, 0, SLATE_Z]) cube([SLATE_W, SLATE_T, SLATE_H]);
module slateStand() difference() {
  union() {
    translate([-SLATE_W / 2 + 20, -30, 0]) cube([SLATE_W - 40, 60 + SLATE_T, 6]);
    for (s = [-1, 1]) translate([s * (SLATE_W / 2 - 40) - 8, -4, 0]) cube([16, SLATE_T + 8, SLATE_Z + 8]);
  }
  translate([-SLATE_W / 2 - 1, -0.2, SLATE_Z]) cube([SLATE_W + 2, SLATE_T + 0.4, 30]);   // (the slots, 8 mm deep: below the lowest row)
}
module slate() { slateBoard(); slateStand(); }
module slateFrame() difference() {
  translate([-SLATE_W / 2 - 8, -2, SLATE_Z - 8]) cube([SLATE_W + 16, SLATE_T + 2, SLATE_H + 16]);
  translate([-SLATE_W / 2, -3, SLATE_Z]) cube([SLATE_W, SLATE_T + 4, SLATE_H]);
}

// the whole, for pictures: four rods on the board, the rest in the tray
module assembly() {
  boardOnTable() {
    color("sienna") board();
    for (i = [0 : 4]) color("ivory") translate([-S / 2 + i * S, RL / 2, S / 2]) rod();
  }
  for (x = FOOT_X) color("saddlebrown") foot(x);
  color("sienna") tray();
  for (k = [5 : NROD]) color("ivory") translate([slotX(k), TY, TF + S / 2]) rod();
  translate([0, SLATE_Y, 0]) color("darkslategray") slate();
}

// (for make-stls.sh: each part turned to lie on the printer's bed)
PART = "";
if (PART == "rod") rotate([90, 0, 0]) rod();                  // (standing on its end: square edges, no supports)
if (PART == "board") board();
if (PART == "foot") rotate([0, -90, 0]) foot(0);
if (PART == "tray") tray();
module halfS(s) intersection() { children(); translate([s < 0 ? -200 : 0, -100, -1]) cube([200, 200, 400]); }
if (PART == "slate-left") rotate([-90, 0, 0]) halfS(-1) slateBoard();
if (PART == "slate-right") rotate([-90, 0, 0]) halfS(1) slateBoard();
if (PART == "slate-stand-left") halfS(-1) slateStand();
if (PART == "slate-stand-right") halfS(1) slateStand();
if (PART == "slate-frame-left") rotate([-90, 0, 0]) halfS(-1) slateFrame();
if (PART == "slate-frame-right") rotate([-90, 0, 0]) halfS(1) slateFrame();
