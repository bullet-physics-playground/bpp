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

Real balls are not fair coins: they bounce, and now and then one jumps a
pin. Here the bins come out a little wider than fair coins' (a spread of
about 2.0), and the board leans about a third of a bin to the right (a mean
of about 6.3; which way and how far depends most on how the balls bounce).
See `FINDINGS.md`.

## The board

- **The hopper,** at the top, holds the 150 balls on two 60-degree slopes.
- **The metering wheel** under it, turned by the **crank** in front: six
  slots in its rim, each of which carries one ball from the bottom of the
  hopper round under its housing, and lets it drop into a small **funnel**.
  The ball bounces between the funnel's walls and leaves by a straight
  **neck**, 8 mm wide and 8 mm long, just over the first pin. A turn of the crank lets in up to six
  balls; at one turn a second the 150 take about 27 seconds.
- **The pins,** 4 mm, 12 mm apart on a triangular lattice, each centred
  under the gap above it: twelve rows from the first pin down. The side walls
  run where the next pin out would be, with half pins standing out of them,
  so a ball at the edge meets a pin where it would have met one.
- **Thirteen bins,** between dividers under the last row's pins, each
  10.4 mm wide inside (two staggered columns of balls).
- **The slide** under the bins: pulled out, the balls drop into **the
  drawer**, and the operator tips the drawer into the filling slot at the
  top, back into the hopper.

Why a wheel, and not the hopper emptying through a neck as on most Galton
boards: in two dimensions a neck narrow enough to let the balls in one at a
time jams, and one wide enough not to jam floods the pins, and the balls,
knocking each other, spread far too wide. Why the funnel: the wheel hands
every ball on in the same way, and dropped straight from the slot nearly
every one went the same way at the first pin; the funnel's bounces make the
small differences between balls count, and the neck takes out the sideways
speed they all leave the funnel with. `FINDINGS.md` has the tries.

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
coins. Rest the mouse on the board, the wheel, a ball or the sign to see
each bin's count and the fair coins' counts beside them. The console prints
each run's counts.

**The hand** (the operator's, drawn half see-through so it hides little)
turns the crank, pulls and pushes the slide, and carries the drawer up to
the filling slot and tips it.

Sliders: `crank` (turns a second, 0.25 to 1.5; checked at 0.5 and 1, and above 1 the board leans left), `bounce` (the restitution,
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
(sizes to try, as `GB_GEO="S=13 PIN_D=3"`: they are not written to the
printed parts).

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
  outlines, the housing's in short straight pieces). The wheel is one body
  on a hinge: its hub and the six pieces between its slots. The slide is a
  fixed box that, pulled out, touches nothing. The balls are 150 spheres,
  6 mm, 0.88 g.
- **The hand on the crank** is a motor on the wheel's hinge at a steady
  speed. If the wheel stops against it (a ball caught), the hand turns it
  back a little and on again (it has not been needed in any run here).
- **Idealised:** the pouring. The drawer is drawn going up and tipping, and
  the balls are moved from it to the top of the hopper a few at a time, as
  pouring would put them. The drawer's walls stay with the board's.
- **The sign** is the exhibit's display, not the machine's.

## Printing and building

`./make-stls.sh` (needs OpenSCAD) writes every part into `stl/`, each
turned to lie on the bed. The board is printed in three tiles, each under
200 mm.

| Part | Print | Size (mm) | Notes |
|---|---|---|---|
| `tile-top.stl` | 1 | 166 x 200 x 11 | the hopper, the wheel's recess, the funnel and neck; on its back |
| `tile-middle.stl` | 1 | 166 x 195 x 11 | the pins and the tops of the bins; on its back |
| `tile-bottom.stl` | 1 | 166 x 194 x 11 | the bins, with their gold lines engraved 0.6 mm (paint them), the slide's slot and the drawer's bay |
| `splice.stl` | 2 | 146 x 30 x 3 | glued across the back of each joint |
| `wheel.stl` | 1 | 32 x 31 x 6 | a press fit on the axle; PLA, 100% infill |
| `crank.stl` | 1 | 34 x 10 x 18 | a press fit on the axle's front end |
| `slide.stl` | 1 | 170 x 15 x 7 | |
| `drawer.stl` | 1 | 168 x 41 x 9 | it slides into its bay through the back plate, under the front sheet |
| `stand.stl` | 1 | 196 x 91 x 68 | the board's foot stands between its lips |

The pins are printed with the board, standing up from the back plate. Print
the tiles at 0.2 mm layers with four walls, so the pins are solid.

**Also needed**

- **Steel balls,** 6 mm, 150 (and a few spare): bearing balls.
- **Clear acrylic,** 3 mm, 167 x 539 mm, the front sheet (it stops just
  above the slide, so the drawer can slide in under it):
  `stl/cut-front.svg` has its outline and the axle's hole. Drill its 22
  screw holes through the rim's holes, 3.2 mm.
- **22 M3 x 12 screws** (self-tapping into the 2.5 mm holes in the rim).
- **3 mm steel rod,** 25 mm, the wheel's axle.
- Glue for the splices; a little dry PTFE on the wheel and its housing.

**Assembly.** Glue the three tiles together with a splice across each joint
at the back, checking with a straight edge that the tiles' faces are flush
(the balls roll across the joints). Press the axle into the wheel, so it
stands 2 mm out of the wheel's back, and fit it into the hole in the back
plate. Lay the front sheet on, the axle through its hole, and screw it down
all round the rim. Press the crank onto the axle's front. Put the slide in
its slot from the right, and the drawer into its bay under it. Stand the
board in the stand. Pour the balls in at the filling slot at the top, and
turn the crank.

See `FINDINGS.md` for how the sizes were arrived at.
