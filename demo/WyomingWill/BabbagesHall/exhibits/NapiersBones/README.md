# Napier's Bones

*Babbage's Hall, west bay 2: the multiplication table, cut into rods.*

The third machine on the walk. Each face of a rod (a "bone") carries one
digit's multiples, × 1 to × 9, in nine cells, each split by a diagonal:
the tens above it, the units below. Lay the rods for 4138 side by side
beside the index rod, and row 6 holds 4 × 6, 1 × 6, 3 × 6 and 8 × 6 at
once:

    2/4  0/6  1/8  4/8

Adding along the diagonals from the right, a units digit and the next
rod's tens, carrying any ten, gives the row's product. The sums are 2,
4 + 0, 6 + 1, 8 + 4 and 8, that is 2 4 7 12 8; from the right: 8; 12,
write 2 and carry 1; 7 + 1 = 8; 4; 2: 24828. A multiplier of several
digits takes a row for each, each moved a place left of the one after it,
and the rows added: for 4138 × 567, 2069000 + 248280 + 28966 = 2346246.
John Napier published the rods in 1617, in *Rabdologiae*.

A hand lays the rods on Napier's board: it takes a rod from the tray,
turns it to the face it needs, lays it on the board's ledge beside the
last, and presses it into place. A red strip marks the row being read; a
slate behind shows the problem, each step, the row's cells, the sums
along the diagonals, each row's product and the total.

## The set

Ten four-sided rods, each carrying four digits' tables, as Glaisher
describes Napier's own set (quoted by MacTutor):

| Rod | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|---|---|---|---|---|---|---|---|---|---|---|
| Tables | 0 1 9 8 | 0 2 9 7 | 0 3 9 6 | 0 4 9 5 | 1 2 8 7 | 1 3 8 6 | 1 4 8 5 | 2 3 7 6 | 2 4 7 5 | 3 4 6 5 |

Every digit is on four rods and no rod has one twice, so any four-digit
number can be laid (`bones-test.lua` tries all 10,000), and nearly every
longer one (99.8% of five-digit numbers, 99.2% of six). 2222 needs four
different rods with a 2, and the tour lays it. Around each rod the faces
go a, b, 9 − a, 9 − b, so opposite faces make 9: Glaisher lists nine of
the rods in that order. Which faces Napier put opposite each other, the
sources at hand don't say; the third rod, which he lists 0 3 6 9, has its
9 opposite its 0 here like the rest.

## Two ways

In the hall, Tab steps through them (each has its own label on the
lectern); on its own, `NB_WAY` chooses.

**Napier's bones** (the default): the row read, the diagonals added, a
row for each of the multiplier's digits, the rows added.

**Genaille's rods** (`NB_WAY=genaille`): the same ten rods and the same
set, with Genaille's faces. Henri Genaille, a French railway engineer,
drew the carries (shown in 1891, with Édouard Lucas). A face has rows for
2 to 9 only ("1 is not really needed", Roegel). Row m holds m numbers,
one for each carry the rod to its right can send: the units of
digit × m + carry. Beside them, a triangle for each tens digit among
them, its tip pointing at the number on the next rod that the tens
select. From the last rod's top number in the row, follow the triangles
left: the numbers passed are the product, and the index rod's small red
column gives the last carry. No adding (but a multiplier of several digits
still takes a row each, added up). Red dots mark the path on the rods. The
Genaille rods here are four-sided, carrying Napier's set of tables;
Genaille's own multiplication set had one table to a strip.

    bpp -f napiers-bones.lua                 (or walk to it in the hall)
    NB_WAY=genaille bpp -f napiers-bones.lua

| Key | |
|---|---|
| `0`–`9` | a number (up to six figures), then `X`, then the multiplier (up to three), then `Return` |
| `Backspace` | a figure off |
| `C` | clear the board: the rods back in the tray |
| `M` | the camera close to the board (again: back; walking on puts the view back too) |
| `T` | the tour. Napier's bones: 425 × 6 (no carries), 6785 × 8 (carries), 2222 × 9 (four rods with a 2), 4138 × 567 (three rows). Genaille's rods: 52749 × 4, 874 × 7, 874 × 73 |

A number the set can't lay (11111: only four rods carry a 1) is said so
on the slate. The sliders: the rods' friction, the hand's speed, the
simulation's speed. Resting the mouse on a rod says which tables it
carries.

## What is simulated, and what is the script's

The ten rods are bodies: boxes 16 mm square and 176 mm long, 35 g. The
board (its plate, its ledge, the index rod against its rim) and the tray
are solid. The board is tilted 20 degrees toward you; a rod stays on it by
friction and the ledge.

The hand is the script's. It holds a rod by steering it: each step it sets
the rod's speed and spin toward where it should be, its weight held. It
lifts the rod, turns it to the face it needs, carries it to the board and
sets it down just clear of its neighbour. Then it lets go and presses the
rod left and down with 0.3 N until it stops against its neighbour and the
ledge. A rod left still for 2 s sleeps (Bullet's way with resting bodies;
`FINDINGS.md` says why), and wakes when a moving rod touches it.

Every reading is taken from where the rods lie: which face is up (from
each rod's orientation), and which of its cells is level with the
index's row. On Genaille's rods the triangles are followed by height: the
tip of each points to whichever number on the next rod is level with it.
A rod turned wrong, or lying a row out, gives a wrong answer, and the
slate says so. The slate, the red strip and dots, and the adding along the
diagonals and of the rows are the script's: a person does those.

## The parts

`./make-stls.sh` makes the STLs (OpenSCAD), each turned to lie on the
printer's bed; all are under 200 mm.

| Part | Print | Notes |
|---|---|---|
| `rod.stl` | 11 | the ten rods and the index rod, 16 × 16 × 176 mm, edges chamfered; printed standing on an end |
| `board.stl` | 1 | Napier's board, 144 × 192 mm: a plate with a ledge along its bottom and a rim on its left; the index rod lies against the rim |
| `foot.stl` | 2 | the feet the board lies on, tilted 20 degrees; a peg in each fits a hole under the board |
| `tray.stl` | 1 | the tray, ten slots, 194 × 186 mm |
| `slate-left.stl`, `slate-right.stl` | 1 each | the slate's board (34 × 15 cm) in halves; paint it with blackboard paint |
| `slate-stand-left.stl`, `slate-stand-right.stl` | 1 each | its stand: a foot and two posts with slots the board stands in |
| `slate-frame-left.stl`, `slate-frame-right.stl` | 1 each | its frame |

**The faces.** `napier-faces.pdf` and `genaille-faces.pdf` (two A4 pages
each) have a strip for each rod, its four faces side by side, 64 × 176
mm, and one for the index rod. Print at 100%, no "fit to page", and check
the bar is 100 mm. Cut each strip out, fold it on its faint lines and wrap
it round its rod, the digits at the top end; glue it down. The index
rod's strip has one face; wrap the Napier and the Genaille index on two
faces of the index rod and turn it to the one in use. A set for both ways
needs two sets of rods, or the second strips wrapped over the first.

## Files

| File | |
|---|---|
| `napiers-bones.lua` | the exhibit |
| `bones.lua` | the set, choosing rods for a number, reading a row each way, adding the rows |
| `bones-test.lua` | the set and both ways against plain arithmetic (`lua bones-test.lua`) |
| `parts/napiers-bones.scad` | every part's shape |
| `make-faces.py`, `faces/`, `napier-faces.pdf`, `genaille-faces.pdf` | the faces: textures for the simulation, and the strips to print |
| `make-slate.py`, `slate/` | the slate's pictures, and the steps' words |
| `make-stls.sh` | the STL files (not kept in the repository) |
| `FINDINGS.md` | what was measured |
