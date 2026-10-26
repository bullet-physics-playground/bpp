# The Digi-Comp II: the accumulator

`README.pdf` beside this file is a typeset copy of it.

Babbage's Hall, west bay 3. The Digi-Comp II, made by E.S.R. Inc. in 1968,
was a computer of marbles: a sloping two-level board of flip-flops and
switches that balls rolled down one at a time. Set up with its switches, it
counted, cleared, added, subtracted, multiplied and divided binary numbers.
Its manual names four registers: the **accumulator** (7 flip-flops), the
**memory** (4 bits), the **MQ** (3 flip-flops: multiplier and quotient) and
the **distributor** (3 flip-flops working as a ring counter), and the
switches MULTIPLY, CLEAR, COUNT, COMPLEMENT, OVERFLOW and AUTO/MANUAL.

It is being built here in steps. The first (October 2026) was a counter of
three flip-flops. This, the second, is **the accumulator**: seven
flip-flops holding a number from 0 to 127, the **START** feeder at the
top, and the **CLEAR** and **COUNT** switches. Next come the memory, MQ and
distributor (adding and multiplying), then the complement (subtracting and
dividing).

## What it does

**Two levels,** as the original: the balls compute on the upper plate, and
a ball that is done drops through a hole to the lower level, which carries
it under everything else down to the **collector** at the bottom. The upper
plate is drawn see-through, so the lower level shows.

**The flip-flop** is a rocker on a pin: a roof with a cup at each end and a
tail onto two stop pegs, with a small steel ball pressed in under the apex.
Its centre of mass is a little up the slope from the pin, so it falls over
to one side or the other and stays there: a memory of one bit. Apex to the
right reads **1**, to the left **0** (printed either side of each apex). A
ball rolling straight down meets the roof on its raised side, rolls into
that cup, and its weight takes the rocker over; at the end of the swing the
cup tips it out. Nothing else turns the rockers: their shape and weight do
it.

**The accumulator** is seven of them down a staircase, A1 (the 1s) at the
top to A7 (the 64s) at the bottom:

- A ball that finds a flip-flop at **0** sets it to 1 and leaves to the
  right, through that flip-flop's **done hole**, to the lower level.
- One that finds it at **1** sets it to 0 and leaves to the left, down to
  the next flip-flop: the **carry**.

So a ball let into A1 adds one, carrying as far as it must: 0111111 (63)
and a ball makes 1000000 (64), the ball carrying past six flip-flops. A
carry out of A7 (from 127) drops through the **overflow** hole, and all
seven read 0 again.

**CLEAR.** Under each rocker, on the lower level, is its **foot**: an arm
up the slope from the pin, joined to the rocker by a stem through the
plate, ending in a wedge. When the rocker reads 1 the wedge leans into the
**clear lane** (green), which runs down the lower level past every foot. A
ball sent down the clear lane meets each wedge in its way and pushes it
aside, which turns that rocker to 0; it passes the rockers already at 0. So
one ball clears the whole accumulator.

**The switches** are flaps, set by hand. Each sits at the tip of the divider
between two outlets, its free end against one wall of the inlet, closing
that outlet: a ball only presses it harder against the wall and leaves by
the other. The ball from START meets **CLEAR** first: on, it drops through a
hole into the clear lane; off, it goes on to **COUNT**: on, it runs into A1
and adds one; off, it drops to the lower level and counts nothing. (In
E.S.R.'s machine MULTIPLY comes before CLEAR; it comes in the next step.)

**START** is the feeder: a wheel with four notches under the **input**
channel of waiting balls. Each quarter turn of its knob carries one ball
round from the top and lets it out at the bottom.

## Using it

| Key | |
|---|---|
| `Space` | START: a quarter turn of the knob, one ball |
| `C` | CLEAR on and off (by hand) |
| `N` | COUNT on and off (by hand) |
| `1` to `7` | set that flip-flop over by hand (`1` the 1s ... `7` the 64s), as you set the original's |
| `T` | the tour (it starts with it) |
| `R` | set it back by hand: the balls to the top, the accumulator to 0, COUNT on, CLEAR off |
| `Z` | slow motion (1/4 speed) on and off |

**Where to look.**

- **The rockers**, against the 0 and 1 printed either side of each apex,
  and the 1, 2, 4 ... 64 beside them: the machine's own reading. Read them
  bottom (64s) to top (1s) for the number written the usual way.
- **The switches'** flaps, against the on and off printed at their outlets.
- **The lower level** through the plate: done balls rolling down, and a
  clear ball running down the green lane past the feet.
- **The sign** on the table, THE ACCUMULATOR: what the rockers read, in
  binary and as a number, and how many balls have been let in. It is the
  exhibit's, not part of the machine: the script reads the rockers for it.

Rest the mouse on a rocker, a foot, a flap, the feeder or a wall to see what
it is and what it is doing.

**The tour** (`T`): COUNT on from 0, four balls (1, 2, 3, 4); 125 set by
hand and three balls (126, 127, and the carry right through to the
overflow: 0); 90 set by hand and CLEAR on, one ball (0); 127 and one ball
(0); CLEAR again at 0 (still 0); 5 set by hand with both switches off, one ball (still 5). After
each ball it checks the reading and that the ball reached the collector,
and prints `RESULT digicomp2 tour: PASS`. It takes about 70 simulated
seconds, and about a minute of computing here, headless.

Sliders: `friction` (0.1 to 0.6 checked), `speed`, `steps`.

## Running it

Open `digicomp2.lua` in bpp, or run it inside the hall (`HALL_START=digi`).
Environment, for testing: `DC_TOUR=0` (no tour), `DC_FRICTION`, `DC_PF`
(the pins' friction, as a torque in kg cm^2/s^2: 0.4), `DC_TH` (the board's
slope, 15 degrees), `DC_ROLL` (the table tilted across, degrees), `DC_HZ`
(steps a second, 2400), `DC_HAND` (the most torque the hand turns the knob
with, 50), `DC_PAUSE` (seconds between a reading and the next ball, 1),
`DC_LOG=1` (the rockers' leans at each reading), `DC_LOG=2` (also every
moving ball four times a second), `DC_LOG=3` (where every ball is at each
reading), `DC_CONTACTS=frame` (every contact of the
balls, rockers, flaps and wheel at that frame), `DC_REST=0` (never rest),
`DC_EXPORT=1` (rewrite `parts/geometry.scad`).

`tests/toggle.lua` is one flip-flop alone, with its foot, its done hole and
the clear lane; `tests/switch.lua` is one switch alone. Each prints `RESULT`
lines; their headers list their settings, and `FINDINGS.md` has what they
showed.

## Printing and building

`./make-stls.sh` (needs OpenSCAD, and bpp to refresh `geometry.scad`)
writes every part into `stl/`, each turned to lie on the bed. Every shape a
ball, a rocker or a flap touches comes from `digicomp2-geometry.lua`, the
same numbers the simulation uses. The largest pieces are the tiles, 162 x
184 mm.

| Part | Print | Size (mm) | Notes |
|---|---|---|---|
| `upper-i-j.stl` | 1 each (10) | 162 x 174 x 16 | the upper plate in tiles, two across and five down: its 4 mm face with the holes, the walls (12 mm high), the stop pegs, the bosses under the flaps and the wheel, the lettering cut 0.6 mm deep (fill it with paint, or change filament at that layer) |
| `lower-i-j.stl` | 1 each (10) | 162 x 184 x 17 (the bottom two 32) | the lower level in tiles: a 2 mm floor with its walls (15 mm), the clear lane, the collector's wall (30 mm), the posts that hold the plate up, and the bosses the feet stand on |
| `rocker.stl` | 7 | 44 x 19 x 9 | a flip-flop's top. 100% infill |
| `foot.stl` | 7 | 12 x 24 x 22 | its stem and foot: the stem glues up into the rocker's hub, through the plate's square hole. 100% infill |
| `flap.stl` | 2 | 3 x 19 x 9 | a switch's flap |
| `wheel.stl` | 1 | 39 x 39 x 9 | the feeder's wheel |
| `knob.stl` | 1 | 28 x 28 x 14 | glued onto the wheel's hub; its four marks are the quarter turns |
| `foot-back-1.stl`, `foot-back-2.stl` | 2 each | 30 x 124 x 30, 30 x 128 x 30 | the stand's tall back feet, each in two halves glued end to end (20% infill is plenty) |
| `foot-front.stl` | 2 | 30 x 21 x 30 | its low front feet |

**Also needed**

- **12 steel balls, 1/2 inch (12.7 mm)**, 8.35 g each (and a few spare).
- **7 steel balls, 1/4 inch (6.35 mm)**, 1.04 g: the rockers' weights,
  pressed into the pocket under each apex, flush.
- **3 mm steel dowel pins**: seven 32 mm long for the flip-flops (pressed
  into the lower tiles' bosses, up through foot, stem and rocker), two
  16 mm for the flaps and one 20 mm for the wheel (pressed into the upper
  plate).
- A **lower board** of 6 mm plywood, 322 x 878 mm, the lower tiles glued on
  it edge to edge, and the feet glued under it at its corners.
- Glue; a little dry PTFE or graphite on the pins.

**Assembly.** Glue the lower tiles onto the plywood, edge to edge, the
lanes' walls lining up across the joins. Press the flip-flops' pins into
their bosses. Glue the upper tiles together at their edges into one plate
(a strip of thin card or tape under each join helps). Put each foot on its
pin, wedge up the slope; lay the plate on its posts, the stems coming up
through the square holes; press the steel balls into the rockers and glue
each rocker onto its stem, roof up the slope. Press the flaps' and wheel's
pins into the plate, fit them, and glue the knob on the wheel. Glue the
tall feet under the back corners and the low ones under the front, so the
board slopes at 15 degrees toward you, and **level it across** (within 2
degrees; see `FINDINGS.md`). Set the accumulator to 0 (every apex to the
left), COUNT on and CLEAR off, put the balls in the input channel, and turn
the knob a quarter turn at a time.

The knob's first quarter turn after loading fills the wheel: balls come out
from the second. (In the simulation, the hand loads the wheel's two notches
as it puts the balls back, so the first turn lets one out.)

## What is not as built

- **The hand.** The knob is turned by the hand, a quarter turn at a time: in
  the simulation a motor on the wheel's pin, strong enough not to stall. The
  hand sets the switches and flip-flops, and puts the balls back, by placing
  them.
- **AUTO.** E.S.R.'s machine can run by itself: in AUTO, a ball at the
  bottom rolls under the START lever and lets the next ball go from the top.
  That is not built yet (`FINDINGS.md` says why); here every ball is let in
  by a turn of the knob, as in the original's MANUAL.
- **The pins** are hinges with a constant friction torque, 0.4 kg cm^2/s^2
  (`DC_PF`): PLA on PLA at a boss, worked out in `FINDINGS.md`.
- **The lettering** is drawn on the plate's face, not cut into it; the plate
  is drawn see-through.

See `FINDINGS.md` for how the numbers were arrived at.
