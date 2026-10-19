# The Pascaline

`README.pdf` beside this file is a typeset copy of it.

Babbage's Hall, west bay 3. Blaise Pascal's adding machine (1642), with
three digits and his own carry: the **sautoir** ("jumper").

Each digit wheel carries ten pins (the hand turns it by these, like a
dial telephone) and, behind them, a snail cam. As the units count from 0
to 9 the cam slowly lifts a weighted lever, the sautoir. As the units pass
9 the cam's step drops away under it, the weight falls, and a pawl on the
lever's end kicks the tens wheel on by one pin. On the way up the pawl
yields and slips back over the next pin. Because each carry is powered by
a weight that was lifted earlier, a carry that ripples (99 + 1 = 100)
needs no more force from the hand than any other step. This was Pascal's
answer to the problem that wrecked earlier calculators: a long ripple
carry jams a machine that drives it straight through gears.

## Running it

Open `pascaline.lua` in bpp, or run it inside the hall
(`HALL_START=pascaline`). It starts with a tour: 7, then + 8 = 15 (a
carry), + 84 = 99, + 1 = 100 (a double ripple). It prints
`RESULT pascaline tour: PASS` when every reading is right.

| Key | |
|---|---|
| `1` `2` `3` | add one to the units, tens, hundreds |
| `R` | reset to 000 |
| `T` | the tour again |
| `Z` | slow motion (1/4 speed) on and off |

Sliders: `friction` (0.15 to 0.45 checked), `turn rate` (how fast the hand
turns a digit), `speed`.

Environment, for testing: `PA_TOUR=0` (no tour), `PA_FRICTION`, `PA_RATE`,
`PA_DEBUG=1` (prints the digits' values and the levers' and pawls'
angles), `PA_EXPORT=1` (rewrites `parts/geometry.scad`).

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
- **The click.** A real Pascaline has a spring detent on each wheel. Here it
  is a weak pull toward the nearest whole digit, applied by the hinge's
  motor.
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
| `dial.stl` | 3 | 88 x 88 x 6 | press onto the hub's end; paint the raised numbers |
| `sautoir-0.stl`, `sautoir-1.stl` | 1 each | 215 x 28 x 40/52 | supports under the pawl's carrier arm |
| `pawl-0.stl`, `pawl-1.stl` | 1 each | 31 x 23 x 8 | |
| `frame-front-left/right.stl` | 1 each | 230 x 140 x 6 | the front plate, the digits' bearings and pointers |
| `frame-back-left/right.stl` | 1 each | 230 x 140 x 6 | the back plate, the sautoirs' pivots |
| `frame-base-left/right.stl` | 1 each | 230 x 110 x 8 | |
| `frame-end.stl` | 2 | 58 x 132 x 8 | joins the plates at each end |

Instead of printing the plates you can cut them from 6 mm acrylic (clear,
so the works show) or plywood: `stl/cut-front-plate.svg` and
`stl/cut-back-plate.svg` are their outlines.

**Also needed**

- 2 steel weights of about **60 g**, each on an **M6 bolt** through the
  sautoir's weight block (a stack of M6 nuts or washers does). The weight
  matters: the drop must carry the next wheel a full step.
- 2 pawl tail weights of about **8 g** (an M5 nut glued on). Too light and
  the pawl swings out instead of catching.
- **3 mm steel rod** for pivot pins: 2 for the sautoirs (into the back
  plate) and 2 for the pawls.
- Glue or M3 screws for the frame joints; a little dry PTFE or graphite on
  the cams and pins.

**Assembly.** Glue the plate halves and the base halves. Fit the sautoirs
on their pins in the back plate, and the pawls on theirs. Slide each digit's
hub, cam first, from behind through the front plate, then press its dial on
with 0 at the top under the pointer. Set the units and tens to 0 with each
sautoir resting at the bottom of its cam. Join the plates with the end
pieces and the base. Then turn the units by its pins and watch the tens
step on as it passes 9.

A spring detent on each wheel (a strip of spring steel or a printed leaf
pressing on the pins) keeps the digits from being nudged; the simulation's
click stands in for it.

See `FINDINGS.md` for how the numbers were arrived at.
