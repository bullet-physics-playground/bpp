# The Galton board

`README.pdf` beside this file is a typeset copy of it.

Babbage's Hall, east bay 2. Francis Galton's quincunx: balls falling
through rows of pins, each pin sending a ball left or right, pile up in
the bins below in the bell of the normal curve. Galton had his made by
Tisley and Spiller in London in 1873, for lead shot, and showed it at the
Royal Institution in 1874; it is now in the Galton Collection at University
College London. He described it in 1877 and in *Natural Inheritance*
(1889), as a picture of how many small chances add up.

## What it computes

Each ball meets twelve pins on its way down, one in each row, and at each
goes left or right. The bin it ends in counts how many times it went
right, from 0 (the bin on the far left) to 12. If every pin were a fair
coin, the chance of ending in bin k would be the binomial's, C(12, k) in
4096:

| bin | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| in 4096 | 1 | 12 | 66 | 220 | 495 | 792 | 924 | 792 | 495 | 220 | 66 | 12 | 1 |
| of 150 balls | 0.0 | 0.4 | 2.4 | 8.1 | 18.1 | 29.0 | 33.8 | 29.0 | 18.1 | 8.1 | 2.4 | 0.4 | 0.0 |

The mean bin would be 6 and the spread (the standard deviation) the square
root of 12 over 2, 1.73. With more rows the binomial becomes the normal
curve. A gold line engraved in each bin marks where its share of 150 balls
would come to.

Real balls are not fair coins. Each pin here is fair (a ball goes right
about half the time), but the pins are not independent: a ball leaves a
pin still moving sideways and meets the next one off-centre on the same
side, so it goes the same way again two times in three. Now and then one
jumps a pin. The bins come out a little wider than fair coins' (a spread of
about 1.9 to 2.0, against 1.73), with the mean bin within about 0.3 of 6.
A deader ball remembers more, and taller rows let it jump more; no setting
tried does much better than this board. See `FINDINGS.md`, section 6.
A neck above every pin can cut the memory to nothing: see `SPLITTERS.md`
and `splitter-test.lua`, a test bed for a second board.

## The board

- **The hopper,** at the top, holds the 150 balls on two 60-degree slopes.
- **Two metering wheels** under it, mirror images side by side, geared
  together behind the board and turned by the one **crank** in front: the
  left turns clockwise, the right anticlockwise. Each has six slots in its
  rim; a slot comes up the wheel's outer side, picks up one ball from the
  bottom of the hopper, carries it down the wheel's inner side under its
  housing, and lets it drop into the **funnel** under both wheels. The ball
  leaves by a straight **neck**, 8 mm wide and 8 mm long, just over the
  first pin. The right wheel's slots are half a slot behind the left's, so
  the balls come from each in turn. A turn of the crank lets in up to
  twelve balls; at half a turn a second (the usual) the 150 take about 28
  seconds. Faster, a ball from each side can meet over the neck and jam.
- **The pins,** 4 mm, 12 mm apart on a triangular lattice, each centred
  under the gap above it: twelve rows from the first pin down. The side walls
  run where the next pin out would be, with half pins standing out of them,
  so a ball at the edge meets a pin where it would have met one.
- **Thirteen bins,** between dividers under the last row's pins, each
  10.4 mm wide inside (two staggered columns of balls).
- **The slide** under the bins: pulled out, the balls drop into **the
  drawer**, and the operator tips the drawer into the filling slot at the
  top, back into the hopper.

Why wheels, and not the hopper emptying through a funnel as on Galton's
own (his ran on small lead shot, likely several deep behind the glass): in
two dimensions, one 6 mm ball deep, a neck narrow enough to let the balls
in one at a time jams, and one wide enough not to jam floods the pins, and
the balls, knocking each other, spread far too wide. Why two: one wheel
hands every ball on in the same way, sideways and spinning, and the board
leant whichever way the wheel turned (turned the other way, the lean
changed sides). A mirrored pair makes the machine symmetric, so whatever
one wheel's balls do, the other's do the mirror image. `FINDINGS.md` has
the tries.

## Using it

| Key | |
|---|---|
| `Space` | turn the crank: run the balls through (again: stop) |
| `E` | empty the bins into the drawer, and pour it back into the hopper |
| `T` | the tour: a run, empty and pour back, and a second run (it starts with it) |

**Where to look.** The bins fill in a bell; compare them with the gold
lines. **The sign** beside the board (the exhibit's, not the machine's: it
is what an operator would write up) shows the run, how many balls are in
the bins, their mean bin and their spread, against 6.00 and 1.73 for fair
coins. Rest the mouse on the board, a wheel, a ball or the sign to see
each bin's count and the fair coins' counts beside them. The console prints
each run's counts.

**The hand** (the operator's, drawn half see-through so it hides little)
turns the crank, pulls and pushes the slide, and carries the drawer up to
the filling slot and tips it.

Sliders: `crank` (turns a second, 0.25 to 0.75; 0.5 usual), `bounce` (the restitution,
ball on board), `friction` (ball on board), `speed`.

## Running it

Open `galton.lua` in bpp, or run it in the hall (`HALL_START=galton`). It
starts with the tour, which prints each run's counts and
`RESULT galton tour: PASS` when, in each run, every ball reached a bin and
the mean bin is within 0.6 of 6 and the spread between 1.4 and 2.6.

Environment, for testing: `GB_TOUR=0` (no tour), `GB_RUNS` (runs in the
tour, 2), `GB_BALLS`, `GB_CRANK`, `GB_BOUNCE`, `GB_FRICTION`, `GB_ITER`
(solver passes, 20), `GB_LOG=1` (a line every 5 seconds; `=2` also where
the fastest ball is; `=3` also how the balls leave the funnel and go at the
first pin), `GB_REST=0` (never rest), `GB_HAND=0` (no hand), `GB_GEO`
(sizes to try, as `GB_GEO="S=13 PIN_D=3"` or `"V=11.95"` for the rows'
spacing: they are not written to the printed parts), `GB_PATHS=<file>`
(each ball's path through the pins, appended at the end of each run, for
`python3 paths.py <file>`, which measures how independent the pins are).

Once the operator is done and nothing moves, it rests: it stops stepping
until the next key, which saves the processor and changes nothing it
computes.

## How it is built

- **One source.** `galton-geometry.lua` holds every size. The simulation
  builds its contact shapes from it, and `galton.lua` writes the sizes to
  `parts/geometry.scad`, from which `parts/galton.scad` builds the printed
  parts. What is printed is what is simulated.
- **Bodies.** The board is one fixed body: its back plate and front sheet
  (boxes), its pins and half pins (cylinders), its walls (boxes along the
  outlines, the housings' in short straight pieces). Each wheel is one body
  on a hinge: its hub and the six pieces between its slots. The slide is a
  fixed box that, pulled out, touches nothing. The balls are 150 spheres,
  6 mm, 0.88 g.
- **The hand on the crank** is a steady speed, and **the gears** a lock:
  each wheel's hinge motor drives it toward the crank's turn (counted in its
  own sense), which holds the two together as meshing gears would. If a
  wheel stops (a ball caught), the hand turns the crank back a little and on
  again (it has not been needed in any run here).
- **Idealised:** the pouring, and the knock. The drawer is drawn going up
  and tipping, and the balls are moved from it to the top of the hopper a
  few at a time, as pouring would put them; the drawer's walls stay with the
  board's. If balls stay wedged in a bin when the slide is out (a zigzag
  stack can brace itself against the bin's walls), the operator knocks the
  board: the balls in the bins get the small jolt upward a knock would give
  them.
- **The sign** is the exhibit's display, not the machine's.

## Printing and building

`./make-stls.sh` (needs OpenSCAD) writes every part into `stl/`, each
turned to lie on the bed. The board is printed in three tiles, each under
200 mm.

| Part | Print | Size (mm) | Notes |
|---|---|---|---|
| `tile-top.stl` | 1 | 166 x 171 x 11 | the hopper, the wheels' recesses, the funnel and neck; on its back |
| `tile-middle.stl` | 1 | 166 x 196 x 11 | the pins and the tops of the bins; on its back |
| `tile-bottom.stl` | 1 | 166 x 199 x 11 | the bins, with their gold lines engraved 0.6 mm (paint them), the slide's slot and the drawer's bay |
| `splice.stl` | 2 | 146 x 30 x 3 | glued across the back of each joint |
| `wheel.stl` | 2 | 32 x 31 x 6 | a press fit on its axle; PLA, 100% infill. Fit the right one half a slot (30 degrees) behind the left |
| `gear.stl` | 2 | 45 x 45 x 5 | 28 teeth, module 1.5; pressed onto the axles behind the back plate, meshing |
| `crank.stl` | 1 | 34 x 10 x 18 | a press fit on the axle's front end |
| `slide.stl` | 1 | 170 x 15 x 7 | |
| `drawer.stl` | 1 | 168 x 47 x 9 | it slides into its bay through the back plate, under the front sheet |
| `stand.stl` | 1 | 196 x 91 x 68 | the board's foot stands between its lips |

The pins are printed with the board, standing up from the back plate. Print
the tiles at 0.2 mm layers with four walls, so the pins are solid.

**Also needed**

- **Steel balls,** 6 mm, 150 (and a few spare): bearing balls.
- **Clear acrylic,** 3 mm, 167 x 510 mm, the front sheet (it stops just
  above the slide, so the drawer can slide in under it):
  `stl/cut-front.svg` has its outline and the crank's axle's hole. Drill
  its 22 screw holes through the rim's holes, 3.2 mm.
- **22 M3 x 12 screws** (self-tapping into the 2.5 mm holes in the rim).
- **3 mm steel rod:** 33 mm (the left axle, with the crank) and 18 mm (the
  right).
- Glue for the splices; a little dry PTFE on the wheels and their housings.

**Assembly.** Glue the three tiles together with a splice across each joint
at the back, checking with a straight edge that the tiles' faces are flush
(the balls roll across the joints). Press each axle into its wheel and fit
it into its hole in the back plate, the long one on the left; at the back,
press the gears onto them, meshing, with the right wheel's slots half a
slot behind the left's. Lay the front sheet on, the left axle through its
hole, and screw it down all round the rim. Press the crank onto the left
axle's front. Put the slide in
its slot from the right, and the drawer into its bay under it. Stand the
board in the stand. Pour the balls in at the filling slot at the top, and
turn the crank.

See `FINDINGS.md` for how the sizes were arrived at.
