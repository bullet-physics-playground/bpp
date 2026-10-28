# The Digi-Comp II: counting, adding, multiplying, subtracting, dividing

`README.pdf` beside this file is a typeset copy of it. **`MANUAL.md`** (and
`MANUAL.pdf`) is an illustrated manual: how each operation works, ball by
ball, and which parts each one needs.

Babbage's Hall, west bay 3. The Digi-Comp II, made by E.S.R. Inc. in 1968,
was a computer of marbles: a sloping two-level board of flip-flops and
switches that balls rolled down one at a time. Set up with its switches, it
counted, cleared, added, subtracted, multiplied and divided binary numbers.
Its manual names four registers: the **accumulator** (7 flip-flops), the
**memory** (4 bits), the **MQ** (3 flip-flops: multiplier and quotient) and
the **distributor** (3 flip-flops), and the switches MULTIPLY, CLEAR,
COUNT, COMPLEMENT, OVERFLOW and AUTO/MANUAL.

It is being built here in steps. The first (October 2026) was a counter of
three flip-flops; the second (2a) the accumulator, with START, CLEAR and
COUNT; then (2b) **the memory, the MQ, the distributor and MULTIPLY**, to
add and multiply. This, step 2c, adds **COMPLEMENT**: it subtracts and
divides. Next comes AUTO.

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
cup tips it out. A ball that finds a flip-flop at 0 sets it to 1 and leaves
to the right; one that finds it at 1 sets it to 0 and leaves to the left.
Nothing else turns the rockers: their shape and weight do it. All thirteen
are the same part; where each side leads makes the register.

**The accumulator, A** is seven of them down a staircase, A1 (the 1s) at
the top right to A7 (the 64s):

- A ball that finds a flip-flop at **0** sets it to 1 and leaves to the
  right, through that flip-flop's **done hole**, to the lower level.
- One that finds it at **1** sets it to 0 and leaves to the left, down to
  the next flip-flop: the **carry**.

So a ball let into A1 adds one, carrying as far as it must; a ball let into
A3 adds four. A carry out of A7 drops through the **overflow** hole.

**CLEAR.** Under each of A's rockers, on the lower level, is its **foot**:
an arm up the slope from the pin, joined to the rocker by a stem through
the plate, ending in a wedge. When the rocker reads 1 the wedge leans into
the **clear lane** (green), which runs down the lower level past every
foot. A ball sent down the clear lane meets each wedge in its way and
pushes it aside, which turns that rocker to 0. So one ball clears the
whole accumulator. (The other six flip-flops have their feet too, being
the same part, but no lane beside them.)

**The switches** are flaps, set by hand. Each sits at the tip of the divider
between two outlets, its free end against one wall of the inlet, closing
that outlet: a ball only presses it harder against the wall and leaves by
the other. A ball from START meets **MULTIPLY** first. Off, it runs down to
**CLEAR**: on, it drops into the clear lane; off, it goes on to **COUNT**:
on, it runs into A1 and adds one; off, it drops to the lower level and
counts nothing.

**The memory, M** is four switches, M1 (1s) to M4 (8s), one beside each of
A1 to A4. Set to 1, a ball that reaches it runs into that flip-flop of the
accumulator (into its funnel, by the funnel's long left wall): M3 at 1 adds
four. Set to 0, the ball drops through a hole beside it, and rolls down the
lower level to the **return lane** at the board's left edge, and on to the
collector.

**MULTIPLY on** sends the balls to **the distributor, D**: D1 sends them to
D2 and D3 by turns, and each of those by turns to its two sides, so four
balls go four ways, and the fifth begins again. Set to start (D1 1, D2 1,
D3 0), the first ball of every four goes from D2 into **the MQ**, the second
to M1, the third to M3, the fourth to M2.

**The MQ** (multiplier-quotient) is three flip-flops down a staircase like
the accumulator's, MQ1 (1s) to MQ3 (4s), but read the other way: **1 with
the apex to the left** (it says so beside each). So a ball through it
takes one away: the borrow runs on to the left. A ball that leaves the MQ
on the right (done) runs on, through the funnels under MQ2 and MQ3, to M4.
A borrow out of MQ3, when the MQ was 0, drops through **STOP**.

So with MULTIPLY on, every four balls add the memory to the accumulator,
once for each count of the MQ, and when the MQ is used up the next ball
drops through STOP and the hand stops turning: the MQ times the memory,
added to what was in the accumulator, in 4 x MQ + 1 balls. **ADD** is the
same with the MQ at 1 (five balls), as in E.S.R.'s manual.

**COMPLEMENT.** Below each of A1 to A6's done holes a **done lane** runs
down and across into the next flip-flop's funnel. As a rule the hole is
open and the ball drops through it. COMPLEMENT is six **shutters**, one
over each of those holes, on one bar high over the walls (its handle beside
A1, `X`): slid left (on), they cover the holes, and a ball that sets a
flip-flop to 1 rolls over its hole and down its done lane into the next,
as a carry would. So it goes through every flip-flop from where it came in
to A7 and turns each over. With COUNT on, one ball makes A 127 - A;
COMPLEMENT off, one more adds 1: 128 - A, the two's complement. Add that to
a number and the sum goes over 128 (the carry drops through OVERFLOW and is
lost): it has subtracted. **Dividing** is adding the divisor to the
dividend's complement, cycle by cycle, while the MQ (set to 7) counts the
cycles, until A goes over: the hand watches the OVERFLOW hole and stops at
the end of that cycle. The MQ read the other way gives the cycles; if A
reads 0 that is the quotient, otherwise the quotient is one less and the
remainder is M - A (`MANUAL.md`, section 6). E.S.R.'s machine does this
with six more flip-flops (T1 to T6) and two to sequence them (CF1, CF2) in
four balls; this one does it with the shutters in two balls, the hand
moving COMPLEMENT between them.

**START** is the feeder: a wheel with four notches under the **input**
channel of waiting balls. Each quarter turn of its knob carries one ball
round from the top and lets it out at the bottom.

## Using it

| Key | |
|---|---|
| `Space` | START: a quarter turn of the knob, one ball |
| `M`, `C`, `N` | MULTIPLY, CLEAR, COUNT on and off (by hand) |
| `1` to `7` | set that flip-flop of the accumulator over by hand (`1` the 1s ... `7` the 64s), as you set the original's |
| `H`, `J`, `K`, `L` | the memory's 1s, 2s, 4s, 8s (M1 to M4) on and off |
| `8`, `9`, `0` | set the MQ's 1s, 2s, 4s over by hand |
| `D` | set the distributor to start a cycle (D1 1, D2 1, D3 0) |
| `X` | COMPLEMENT on and off (the shutters over the done holes) |
| `G` | run the program the **program** slider chooses (`G` again stops it) |
| `B` | the camera to the program board, close enough to read it; again, back |
| `T` | the tour: every program in the library, in turn (it starts with it) |
| `R` | set it back by hand: the balls to the top, everything to 0, COUNT on, the others off |
| `Z` | slow motion (1/4 speed) on and off |

To multiply: set the accumulator to 0 (or CLEAR it), the memory to one
number and the MQ to the other, `D`, MULTIPLY on, and `Space` until a ball
drops through STOP. To add, the same with the MQ at 1 and the accumulator
holding the first number. To subtract, complement the number to take away
(COUNT on, MULTIPLY off: `X`, `Space`, `X`, `Space`), then add the other.

**Where to look.**

- **The rockers**, against the 0 and 1 printed either side of each apex
  (the MQ's the other way round), and the 1, 2, 4 ... 64 beside A's: the
  machine's own reading. Read A bottom (64s) to top (1s) for the number
  written the usual way.
- **The switches'** flaps, against the on and off (the memory's 1 and 0)
  printed at their outlets.
- **The lower level** through the plate: done balls rolling down, a clear
  ball running down the green lane past the feet, and the memory's dropped
  balls going to the return lane on the left.
- **The sign** on the table: what the accumulator, the memory and the MQ
  read, in binary and as numbers, and how many balls have been let in.
  Under them, **THIS BALL**: before each ball, what it will do ("D1, D3,
  M1: adds 1") and what the accumulator was and will be. At the same time
  a **yellow dashed line** on the board shows the way it will go, through
  the switches and flip-flops, carries and all; then the hand lets it go,
  and you can watch it do just that (`Z` for slow motion). The sign and the
  line are the exhibit's, not part of the machine: the script works them
  out from the rockers and switches, as you would.

Rest the mouse on a rocker, a foot, a flap, the feeder or a wall to see what
it is and what it is doing.

**The tour** (`T`; it starts with the exhibit) runs the program library
(below), one program after another: count to 5; clear; **ADD** 37 + 11
(five balls, the last to STOP: 48); **MULTIPLY** 13 x 3 (thirteen balls:
39); the **COMPLEMENT** of 25 (102, then 103); **SUBTRACT** 12 - 4 (4
complemented to 124, then 12 added: 8, over 128); **DIVIDE** 13 / 5 ball
by ball (quotient 2, remainder 3) and 25 / 5 with loops; and counting out
nine balls. Each program's listing is in the Shortcuts pane, the line being
done in the status bar. After each ball it checks everything the ball
should have changed (the accumulator, the MQ, the distributor, STOP,
OVERFLOW) and that the ball reached the collector, and each program's
`CHECK` lines, and prints `RESULT digicomp2 tour: PASS`. It takes about 880
simulated seconds, and about twelve minutes of computing here, headless.
Twelve balls are not enough for the multiply: when the input runs low the
hand takes balls from the collector and puts them back at its top, as you
would.

**Programs.** The procedures can be written down and run: text files in
`programs/`, one step a line (the keys you would press, and `SET`, `UNTIL`
and `CHECK`), listed in `programs/LIBRARY`. Choose one with the
**program** slider and press `G`: the hand does it line by line, every ball
shown before it goes and checked after. The program is shown on the
**program board**, on a stand behind the machine's top end, the line being
done lit (`B` brings the camera close enough to read it, and back); it is
also in the Shortcuts pane, and the line in the status bar. The library has count, clear,
37 + 11, 13 x 3, the complement of 25, 12 - 4, 13 / 5 ball by ball, 25 / 5
with loops, and counting out nine balls; `MANUAL.md`, section 9, has the
language.

Sliders: `friction` (0.2 to 0.6 checked), `program`, `speed`, `steps`.

## Running it

Open `digicomp2.lua` in bpp, or run it inside the hall (`HALL_START=digi`).
Environment, for testing: `DC_TOUR=0` (no tour), `DC_FRICTION`, `DC_PF`
(the pins' friction, as a torque in kg cm^2/s^2: 0.4), `DC_TH` (the board's
slope, 15 degrees), `DC_ROLL` (the table tilted across, degrees), `DC_HZ`
(steps a second, 2400), `DC_HAND` (the most torque the hand turns the knob
with, 50), `DC_PAUSE` (seconds between a reading and the next ball, 1),
`DC_SHOW` (seconds the next ball's way is shown before it is let go, 1.5),
`DC_STEP` (begin the tour at that program of the library),
`DC_PROGRAM=name` (run only that program; `all`: every one in turn, as the
tour, then `RESULT digicomp2 programs: PASS`), `DC_LOG=1` (every rocker's lean at
each reading), `DC_LOG=2` (also every
moving ball four times a second), `DC_LOG=3` (where every ball is at each
reading), `DC_CONTACTS=frame` (every contact of the balls, rockers, flaps
and wheel at that frame), `DC_REST=0` (never rest), `DC_EXPORT=1` (rewrite
`parts/geometry.scad`).

`tests/toggle.lua` is one flip-flop alone, with its foot, its done hole and
the clear lane; `tests/switch.lua` is one switch alone; `tests/junction.lua`
is the piece of the board where the memory meets the accumulator (A1, A2
and M2: the carry and the memory's balls into the same funnel);
`tests/complement.lua` is A1 to A3 with their done lanes and shutters, each
ball checked with the shutters open and closed;
`tests/escapement.lua` is the feeder wheel driven by a weight and held by
the anchor that AUTO will trip (not on the board yet). Each prints
`RESULT` lines; their headers list their settings, and `FINDINGS.md` has
what they showed.

## Printing and building

`./make-stls.sh` (needs OpenSCAD, and bpp to refresh `geometry.scad`)
writes every part into `stl/`, each turned to lie on the bed. Every shape a
ball, a rocker or a flap touches comes from `digicomp2-geometry.lua`, the
same numbers the simulation uses. The largest pieces are the tiles, 214 x 182 mm (on a 220 mm bed, or turned on a 250 x 210 one).

| Part | Print | Size (mm) | Notes |
|---|---|---|---|
| `upper-i-j.stl` | 1 each (18) | 214 x 176 x 16 | the upper plate in tiles, two across and nine down: its 4 mm face with the holes and the shutters' grooves (2 mm deep), the walls (12 mm high), the stop pegs, the bosses under the flaps and the wheel, the lettering cut 0.6 mm deep (fill it with paint, or change filament at that layer) |
| `lower-i-j.stl` | 1 each (18) | 214 x 182 x 17 (the bottom two 32) | the lower level in tiles: a 2 mm floor with its walls (15 mm), the clear lane, the return lane, the collector's wall (30 mm), the posts that hold the plate up, and the bosses the feet stand on |
| `rocker.stl` | 13 | 44 x 19 x 9 | a flip-flop's top. 100% infill |
| `foot.stl` | 13 | 12 x 24 x 22 | its stem and foot: the stem glues up into the rocker's hub, through the plate's square hole. 100% infill |
| `flap.stl` | 7 | 3 x 19 x 9 | a switch's flap |
| `wheel.stl` | 1 | 39 x 39 x 9 | the feeder's wheel |
| `knob.stl` | 1 | 28 x 28 x 14 | glued onto the wheel's hub; its four marks are the quarter turns |
| `shutter.stl` | 6 | 28 x 22 x 2 | COMPLEMENT: a done hole's shutter, sliding in its groove in the plate; a pin pressed into its hole |
| `comp-knob.stl` | 1 | 10 x 10 x 12 | COMPLEMENT's handle, glued on the top end of its bar |
| `foot-back-1.stl`, `foot-back-2.stl` | 2 each | 30 x 219 x 30, 30 x 223 x 30 | the stand's tall back feet, each in two halves glued end to end (20% infill is plenty; on a 220 mm bed, lay them across its diagonal) |
| `foot-front.stl` | 2 | 30 x 21 x 30 | its low front feet |

**Also needed**

- **12 steel balls, 1/2 inch (12.7 mm)**, 8.35 g each (and a few spare;
  with more, a long multiply needs fewer trips to the collector).
- **13 steel balls, 1/4 inch (6.35 mm)**, 1.04 g: the rockers' weights,
  pressed into the pocket under each apex, flush.
- **3 mm steel dowel pins**: thirteen 32 mm long for the flip-flops
  (pressed into the lower tiles' bosses, up through foot, stem and rocker),
  seven 16 mm for the flaps and one 20 mm for the wheel (pressed into the
  upper plate).
- For COMPLEMENT: six more 3 mm pins, 21 mm long (one in each shutter),
  and the **bar**: a strip of aluminium (or hardwood) 5 x 3 mm, 792 mm
  long, drilled 3.4 mm for the pins, the first 30 mm from its top end and
  the others every 151.6 mm after it (the pins' places are `SH_PINS` in
  `parts/geometry.scad`).
- A **lower board** of 6 mm plywood, 424 x 1573 mm, the lower tiles glued
  on it edge to edge, and the feet glued under it at its corners.
- Glue; a little dry PTFE or graphite on the pins.

**Assembly.** Glue the lower tiles onto the plywood, edge to edge, the
lanes' walls lining up across the joins. Press the flip-flops' pins into
their bosses. Glue the upper tiles together at their edges into one plate
(a strip of thin card or tape under each join helps). Put each foot on its
pin, wedge up the slope; lay the plate on its posts, the stems coming up
through the square holes; press the steel balls into the rockers and glue
each rocker onto its stem, roof up the slope. Press the flaps' and wheel's
pins into the plate, fit them, and glue the knob on the wheel. Put the
shutters in their grooves, pins up, slip the bar over the pins and glue its
knob on. Glue the
tall feet under the back corners and the low ones under the front, so the
board slopes at 15 degrees toward you, and **level it across** (within 1
degree; see `FINDINGS.md`). Set every flip-flop to 0 (apex left; the MQ's
read 0 with the apex right), COUNT on and the other switches off, put the
balls in the input channel, and turn the knob a quarter turn at a time.

The knob's first quarter turn after loading fills the wheel: balls come out
from the second. (In the simulation, the hand loads the wheel's two notches
as it puts the balls back, so the first turn lets one out.)

## What is not as built

- **The hand.** The knob is turned by the hand, a quarter turn at a time: in
  the simulation a motor on the wheel's pin, strong enough not to stall. The
  hand sets the switches and flip-flops, puts the balls back, by placing
  them, and watches STOP: it turns no more once a ball has dropped through.
  Dividing, it watches OVERFLOW too, and stops at the end of that cycle. It
  moves COMPLEMENT between the two balls of a complement, which E.S.R.'s
  machine does itself with CF1 and CF2.
- **AUTO.** E.S.R.'s machine can run by itself: in AUTO, a ball at the
  bottom rolls under the START lever and lets the next ball go from the top,
  and the ball through STOP lets none. That is not on the board yet: its
  heart, the wheel turned by a wound weight and held by an anchor that lets
  it round a quarter turn (one ball) each time it is tripped, works alone
  (`tests/escapement.lua`; `FINDINGS.md` has the three tries); the trip and
  the STOP bypass are still to come. Here every ball is let in by a turn of
  the knob, as in the original's MANUAL.
- **The layout** is this machine's own, not E.S.R.'s: the registers do what
  the manual says, but where each part sits on the board was worked out
  here. The distributor is a tree of three flip-flops, and after the MQ and
  M4 it serves M1, M3, M2 (the manual's order is M2, M3, M1; the sum is the
  same). The complement is done with shutters and done lanes, not E.S.R.'s
  mode flip-flops; it made the board longer (the accumulator's steps are
  147.5 mm apart, for the lanes between them).
- **The pins** are hinges with a constant friction torque, 0.4 kg cm^2/s^2
  (`DC_PF`): PLA on PLA at a boss, worked out in `FINDINGS.md`.
- **The lettering** is drawn on the plate's face, not cut into it; the plate
  is drawn see-through.

See `FINDINGS.md` for how the numbers were arrived at.
