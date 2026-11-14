# The Pascaline

`README.pdf` beside this file is a typeset copy of it.

Babbage's Hall, west bay 2. Blaise Pascal's adding machine (1642), with
three digits and his own carry: the **sautoir** ("jumper").

Each digit wheel carries ten pins and, behind them, a snail cam; in front
of the plate, its dial shows the digit. As the units count from 0
to 9 the cam slowly lifts a weighted lever, the sautoir. As the units pass
9 the cam's step drops away under it, the weight falls, and a pawl on the
lever's end kicks the tens wheel on by one pin. On the way up the pawl
yields and slips back over the next pin. Because each carry is powered by
a weight that was lifted earlier, a carry that ripples (99 + 1 = 100)
needs no more force from the hand than any other step. This was Pascal's
answer to the problem that wrecked earlier calculators: a long ripple
carry jams a machine that drives it straight through gears.

## Using it

As with Pascal's own, by hand, with a stylus. Each dial has ten holes
between its numbers, and round each dial the front plate has the numbers 1
to 9, with a finger stop at about 4 o'clock. To add 7 to a digit, put the
stylus in the dial's hole beside the plate's 7 and turn it clockwise until
it meets the stop: the digit goes on by exactly 7, whatever it showed. To
add 84, turn the units by 4 and the tens by 8. The total is read under the
pointers. A digit passing 9 carries one into the next by itself, on the
weight it lifted on the way.

It only goes forward (turned back, the sautoir's nose would meet the steep
side of the cam). Pascal subtracted by adding the complement: to take 3
from a three-digit number, add 997 and let the carry out of the hundreds
fall away.

In the simulation you drive it the same way, with the mouse or the keys:

- **The mouse:** rest it on a hole of any dial. The stylus goes into that
  hole, and the tooltip says what it will add ("add 7 to the units: 000
  becomes 007"). Press **Space** and it turns to the stop. Nothing turns
  until you press Space, so the mouse can wander freely. (bpp asks about
  the mouse once it has been still for half a second.)
- **The keys:** `U`, `T` or `H` chooses the units, tens or hundreds (a brass
  mark appears below that dial); `1` to `9` adds that much to it, in one
  stroke: the stylus goes into the hole by the plate's number and round to
  the stop.

The hand that turns the digit is a motor on its axle; the stylus is drawn
doing it, and lies on the table in front between strokes.

## Running it

Open `pascaline.lua` in bpp, or run it inside the hall
(`HALL_START=pascaline`). It starts with a tour: 7, then + 8 = 15 (a
carry), + 84 = 99, + 1 = 100 (a double ripple). It prints
`RESULT pascaline tour: PASS` when every reading is right.

| Key | |
|---|---|
| `U` `T` `H` | choose the units, tens or hundreds |
| `1` to `9` | add that much to the chosen wheel |
| `Space` | turn the stylus in the hole the mouse chose to the stop |
| `R` | reset to 000 |
| `D` | the tour again |
| `Z` | slow motion (1/4 speed) on and off |

Sliders: `friction` (0.15 to 0.45 checked), `turn rate` (how fast the hand
turns a digit), `speed`.

Environment, for testing: `PA_TOUR=0` (no tour), `PA_FRICTION`, `PA_RATE`,
`PA_DEBUG=1` (prints the digits' values and the levers' and pawls'
angles), `PA_EXPORT=1` (rewrites `parts/geometry.scad`), `PA_REST=0` (never
rest: see below), `PA_REST_LOG=1` (says when it rests), `PA_DET_T_MM`
(the detents' leaves this thick, in mm, to try others).

Once the hand is done and nothing moves, the machine rests: it stops
stepping until the next key or tour step, which saves the processor and
changes nothing it computes.

## How it is built

- **One source.** `pascaline-geometry.lua` holds every moving part's shape
  as boxes, cylinders and convex hulls, with masses. The simulation builds
  its bodies from them, and writes them to `parts/geometry.scad`, which
  `parts/pascaline.scad` builds the printed parts from. What is printed is
  what was simulated.
- **Bodies.** Each lever and pawl is a compound of its primitives, its
  origin at its centre of mass. The digits turn on hinges to the frame; the
  sautoirs pivot on pins in the back plate, at the axles' height; each pawl
  is hinged to its sautoir, limited so it yields one way only, and held
  against its stop by a small tail weight.
- **The detents.** Each wheel is held at its digit by a printed PLA leaf
  spring, whose round nose rests between two pins at 9 o'clock and centres
  the wheel. It is simulated as a body (nose and leaf) on a hinge at the
  leaf's root, turned back by the leaf's own stiffness, worked out from PLA
  (3EI/L), with the 0.5 mm preload it has in place.
- **The hand** turns one digit at a time by its hinge's motor, one step per
  press, then lets go.

## Printing and building

`./make-stls.sh` (needs OpenSCAD, and bpp to refresh `geometry.scad`)
writes every part into `stl/`, each turned to lie on the bed. The largest
pieces are 230 x 140 mm.

| Part | Print | Size (mm) | Notes |
|---|---|---|---|
| `digit-cam.stl` | 2 | 72 x 83 x 43 | units and tens. Cam on the bed; supports under the pin wheel |
| `digit-last.stl` | 1 | 59 x 59 x 32 | hundreds (no cam) |
| `dial.stl` | 3 | 88 x 88 x 6 | press onto the hub's end. Print it light (ivory or white) and paint the raised numbers dark |
| `sautoir-0.stl`, `sautoir-1.stl` | 1 each | 215 x 28 x 40/52 | supports under the pawl's carrier arm |
| `pawl-0.stl`, `pawl-1.stl` | 1 each | 31 x 23 x 8 | |
| `stop.stl` | 3 | 13 x 32 x 5 | the finger stops: printed on their side, screwed to the front plate |
| `stylus.stl` | 1 | 8 x 8 x 30 | or use any 4 mm rod |
| `detent.stl` | 3 | 19 x 55 x 14 | the leaf springs. PLA, standing as it lies (no supports), 100% infill; the leaf is 1.2 mm, three lines of a 0.4 mm nozzle |
| `frame-front-left/right.stl` | 1 each | 230 x 140 x 15 | the front plate, the digits' bearings, the pointers and the numbers round each dial (paint them) |
| `frame-back-left/right.stl` | 1 each | 230 x 140 x 6 | the back plate, the sautoirs' pivots |
| `frame-base-left/right.stl` | 1 each | 230 x 110 x 8 | |
| `frame-end.stl` | 2 | 58 x 132 x 8 | joins the plates at each end |

Instead of printing the plates you can cut them from 6 mm acrylic (clear,
so the works show) or plywood, gluing on three printed `pointer.stl`: `stl/cut-front-plate.svg` and
`stl/cut-back-plate.svg` are their outlines.

**Also needed**

- 2 steel weights of about **60 g**, each on an **M6 bolt** through the
  sautoir's weight block (a stack of M6 nuts or washers does). The weight
  matters: the drop must carry the next wheel a full step.
- 2 pawl tail weights of about **8 g** (an M5 nut glued on). Too light and
  the pawl swings out instead of catching.
- **3 mm steel rod** for pivot pins: 2 for the sautoirs (into the back
  plate) and 2 for the pawls.
- **3 M3 screws,** about 16 mm, one through the front plate into each
  detent's block (its 2.5 mm hole is for the screw to tap).
- **3 M3 screws,** about 8 mm, one through each finger stop into the front
  plate (tapped into its 2.5 mm hole).
- Glue or M3 screws for the frame joints; a little dry PTFE or graphite on
  the cams and pins.

**Assembly.** Glue the plate halves and the base halves. Fit the sautoirs
on their pins in the back plate, and the pawls on theirs. Slide each digit's
hub, cam first, from behind through the front plate, then press its dial on
with 0 at the top under the pointer (its holes then stand by the plate's
numbers). Set the units and tens to 0 with each
sautoir resting at the bottom of its cam. Screw a detent behind each
wheel, its block against the back of the front plate and its nose dropped
between the two pins at 9 o'clock (lift the nose over a pin to fit it).
Join the plates with the end pieces and the base. Screw a finger stop
beside each dial, its arm reaching in over the dial's face. Then add with
the stylus (see "Using it") and watch the tens step on as the units pass 9.

The detents' thickness matters: the simulation's carry works with leaves
from 1.0 to 1.6 mm thick (see `FINDINGS.md`), and 1.2 mm is in the middle.
If your printer makes them thicker or thinner, the carry still has room.

See `FINDINGS.md` for how the numbers were arrived at.
