# Linkages That Compute

*Babbage's Hall, east bay 4: hinged bars that work out 1/x, draw a
straight line, and multiply.*

**`MANUAL.pdf`** is the manual: how each linkage works, why it gives the
answer it does, with pictures, and the exhibit's keys (`H` opens it, here
or in the hall). This README is the builder's reference.

The eighth machine on the walk, facing the slide adder. Nothing turns and
nothing counts: a few bars pinned together lie flat on a board, and where
one pin is put decides where another must go. Charles-Nicolas Peaucellier
described the first of these in 1864; Lipman Lipkin found it again in
1871; Sylvester's lecture at the Royal Institution in 1874 started a
craze for linkages in England, and Alfred Kempe showed in 1876 that
linkages can draw any curve given by a polynomial. Bar-linkage computers
did fire control in the Second World War.

The bars are 3 mm thick and lie in planes 7 mm apart above the board. The
operator's hand moves an input carriage along a slot, or turns a crank;
the output is a pin whose place on a paper scale is the answer. A slate
behind the board shows the input, the reading and the answer worked out.

## Three ways

In the hall, Tab steps through them (each has its own label on the
lectern); on its own, `LN_WAY` chooses.

**The inverter** (the default). Two long arms, 15.05 cm, from a fixed pin
O hold the corners A and B of a rhombus of side 11.25. Its other corners,
P and Q, stay on the line through O, and OP × OQ = 15.05² − 11.25² = 100,
whatever the shape. P rides a carriage in a slot along the board; type x
(5 to 9) and press Return, and the hand slides it to x: Q stops at
100 / x, on the scale.

**The straight line** (`LN_WAY=line`). The same cell, with P on a crank
3.5 long pivoted at O + 3.5, so its circle passes through O. Inversion
turns a circle through O into a straight line: Q goes along x = 100 / 7 =
14.29, and a pen at Q dots it on the board. Return turns the crank from
−80° to 80° and back (type an angle first for less); the slate shows how
far the pen is off the line, now and at most.

**The multiplier** (`LN_WAY=multiply`). A lever with a slot along it turns
about a fixed pin O. Across the board at 6 from O, the b carriage's pin
rides the slot: set to b, it is 0.75 b across, so the lever's slope is
0.75 b / 6. A bridge across the board, set at 4 a along it, carries the
cross carriage, whose pin rides the slot too: it stands 4a × 0.75b / 6 =
a b / 2 across, and its scale (marked double) reads a × b. Type a (2 to
5), Space, b (−5 to 5), and Return. a = b squares.

    bpp -f linkages.lua                     (or walk to it in the hall)
    LN_WAY=line bpp -f linkages.lua
    LN_WAY=multiply bpp -f linkages.lua

| Key | |
|---|---|
| `0`–`9`, `.`, `-` | a number (the slate shows it) |
| `Space` | between a and b (multiplying) |
| `Return` | set it; the line: turn the crank across and back |
| `Backspace` | a figure off |
| `R` | a setting at random |
| `T` | the tour. Inverter: x = 5, 6.25, 8, 9. The line: −80° to 80° and back. Multiplying: 3 × 4, 2.5 × 2.5, 4.5 × −2, 5 × 5 |
| `H` | the manual, `MANUAL.pdf`, opened in your PDF viewer |

The sliders: the hand's speed (cm a second; degrees a second for the
crank) and the simulation's speed.

## What is simulated, and what is the script's

Every **bar**, the **crank**, each **carriage**, the **lever**, the
**bridge** and the two **blocks** is a body. Every **pin** is a hinge
(Bullet's `btHingeConstraint`), and every **slot** a slider. The board
lies flat, so the bars' weight acts across their plane of motion and none
of it loads the linkage: only the hand's push does.

The Walker Room's rules for linkages (`demo/WyomingWill/WalkerRoom`):
bars hinged together lie in different planes, so they never touch; where
more than two parts meet, one is the hub and the others hinge to it; the
hinges are stiff (no softening), and the solver works every joint 80
times a step. One rule more, found here: a hinge pins its two points
together in all three directions, so between bars in different planes
each pin's point on one bar is raised to the other's plane (otherwise the
pin pulls the bars toward one plane and they lean: the inverter read 16%
off; `FINDINGS.md`).

In the multiplier the pins in the slot are **blocks**, each on a slider
along the lever and hinged to its carriage; the b carriage's block lies
under the lever and the cross carriage's over it, so they can pass.

The **operator** is the script: it moves the input carriages with a motor
on their sliders (at the hand's speed, no more than 5 N) or turns the
crank with a motor on its hinge (speeding up and slowing down over a
third of a second), and reads the output from where the output pin is.
The slate, the scales and the pen's dots are drawn.

## The parts

All printed but the pins. `./make-stls.sh` makes the STLs, each turned to
lie on the printer's bed (OpenSCAD); all are under 200 mm.

| Part | Print | Notes |
|---|---|---|
| `board-inverter-0`–`3.stl` | 1 each | the board for the inverter and the straight line, 290 × 280 × 10 mm in quarters: the input's slot (50 mm, x from 4.5 to 9.5) and the holes for O and the crank's pivot |
| `board-multiply-0`–`3.stl` | 1 each | the multiplier's board: the b carriage's slot across, the bridge's two slots along, O's hole |
| `arm.stl` | 2 | 150.52 mm between pins, 8 mm wide, 3 mm thick |
| `side.stl` | 4 | the rhombus's sides, 112.5 mm between pins |
| `crank.stl` | 1 | 35 mm between pins |
| `lever-0.stl`, `lever-1.stl` | 1 each | the lever, 264 mm with its 5 mm slot, in two halves that overlap 30 mm at half thickness, glued |
| `carriage.stl` | 3 | a block with a pin up, and a round peg under it that runs in its slot (6 mm wide, 3 mm deep) |
| `block.stl` | 2 | the multiplier's pins in the slot |
| `bridge-0.stl`, `bridge-1.stl` | 1 each | the bridge, 270 mm, in halves; pegs under its feet run in the bridge's slots |
| `knob.stl` | 4 | for the hand: on the inverter's carriage (or the crank), the b carriage and the bridge; and the red one on Q |

Buy: 3 mm steel pins, 30 mm long, about 12.

**The scales.** `slate/scale-inverter.png`, `scale-a.png`, `scale-b.png`
and `scale-product.png`, and `rule.png` (the straight line's), are 10
pixels a millimetre: print them at that size and glue them beside their
slots (`linkages.lua` places each).

**Assembly.** Glue the quarters of a board on a flat surface. Pin O and
the crank's pivot into their holes. Pin the bars together in order of
their planes (`linkages.lua`: the arms in planes 1 and 2, the rhombus's
sides in 3 and 4), with a 4 mm spacer under each where it stands above a
bar it isn't pinned to. Each bar should swing freely on its pin without
rocking: rock lets Q wander off the answer.

## Files

| File | |
|---|---|
| `MANUAL.md`, `manual/` | the manual and its figures (`python3 manual/make-figures.py` redraws them, but for `fig-exhibit.png`, a screenshot) |
| `linkages.lua` | the exhibit, all three ways |
| `parts/linkages.scad` | every part's shape, and the sizes the exhibit uses |
| `make-slate.py`, `slate/` | the slate's pictures and the scales |
| `make-stls.sh` | the STL files (not kept in the repository) |
| `FINDINGS.md` | what was measured |
