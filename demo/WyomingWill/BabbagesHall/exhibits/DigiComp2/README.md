# The Digi-Comp II: the counter

`README.pdf` beside this file is a typeset copy of it.

Babbage's Hall, west bay 3. The Digi-Comp II, made by E.S.R. Inc. in 1968,
was a computer of marbles: a sloping plastic board with a dozen or so
flip-flops on it, which balls rolled down one at a time. Set up with a few
switches, the balls coming to the bottom had counted, added or multiplied
in binary. This is its first step, its heart: **the counter**, three
flip-flops that count the balls let in, from 0 to 7. The full board, which
adds and multiplies, comes next.

## What it does

Each **flip-flop** is a rocker on a pin: a roof with a cup at each end and a
tail below the pin. Its centre of mass (with a small steel ball pressed into
it, under the roof's apex) is a little up the slope from the pin, so it
falls over to one side or the other and stays there, its tail against a stop
peg. It stays as it is left: it is a memory of one bit. Leaning with its
apex to the right, it reads **1**; to the left, **0** (the board says which,
either side of each apex).

A ball rolls straight down a short channel onto the apex. The apex leans to
one side, so the ball meets the roof on the side that is raised, rolls into
that side's cup, and its weight takes the rocker over to the other side; at
the end of the swing the cup tips the ball out. The next ball meets the
other side. So each ball leaves on the other side from the last, and leaves
the flip-flop reading the other way. Nothing turns the rockers but the
balls: their shape and weight do it.

The three flip-flops stand down a staircase, the **1s**, the **2s** and the
**4s**:

- A ball that finds a flip-flop at **0** sets it to 1 and leaves to the
  right, down its **lane** to the bins: done.
- One that finds it at **1** sets it to 0 and leaves to the left, down to the
  next flip-flop: the **carry**.

So every ball adds one, carrying as far as it must, exactly as you add one
in binary: 011 (3) and a ball makes 100 (4), the ball carrying past the 1s
and the 2s and stopping at the 4s. The eighth ball carries past all three
into the **overflow** lane, and the three read 0 again.

The **feeder** at the top lets the balls in one at a time: a wheel with four
notches under a channel of waiting balls. Each quarter turn of its knob
carries one ball round from the top and lets it out at the bottom into the
first channel. The bottom of each lane is a **bin**: the balls there show
which flip-flop each one stopped at (four in the 1s bin, two in the 2s,
one in the 4s and one in the overflow, after eight).

## Using it

Space lets in a ball. Watch it tip the rockers on its way; the three
rockers then read the count: 4s, 2s, 1s, left to right down the staircase.

**Where to look.**

- **The rockers**, against the 0 and 1 printed either side of each apex,
  and the 1s, 2s and 4s beside them: the machine's own reading.
- **The bins** at the bottom, marked 1, 2, 4 and 8: where each ball ended.
- **The sign** on the table, THE COUNT: how many balls the hand has let in,
  and what the rockers read. It is the exhibit's, not part of the machine:
  the script reads the rockers' lean for it.
- **The console** prints each reading during the tour.

| Key | |
|---|---|
| `Space` | a quarter turn of the feeder's knob: one ball |
| `T` | the tour: from 0, eight balls one at a time, each reading checked (it starts with it) |
| `R` | set it back by hand: the balls to the top, the rockers to 0 |
| `Z` | slow motion (1/4 speed) on and off |

Rest the mouse on a rocker to see what it reads and where the next ball
there will go; on the feeder, a ball, a wall or a peg, what it is.

Sliders: `friction` (0.1 to 0.6 checked), `speed`, `steps` (physics steps a
second).

## Running it

Open `digicomp2.lua` in bpp, or run it inside the hall
(`HALL_START=digi`). It starts with the tour, which checks after each ball
that the rockers read the number of balls let in (mod 8) and that the ball
went to the bin it should, and prints `RESULT digicomp2 tour: PASS`. The tour
takes about 28 simulated seconds and 7 s of computing here,
headless; at rest (nothing moving) the exhibit stops stepping.

Environment, for testing: `DC_TOUR=0` (no tour), `DC_FRICTION`, `DC_PF`
(the pins' friction, as a torque in kg cm^2/s^2: 0.4), `DC_TH` (the board's
slope, 15 degrees), `DC_ROLL` (the table tilted across, degrees), `DC_HZ`
(steps a second, 2400), `DC_HAND` (the most torque the hand turns the knob
with), `DC_BALLS` (balls in the tour), `DC_PAUSE` (seconds between a reading
and the next ball, 1), `DC_LOG=1` (the rockers' leans at each reading),
`DC_LOG=2` (also every ball four times a second), `DC_CONTACTS=frame`
(every contact of the balls and the wheel at that frame), `DC_REST=0`
(never rest), `DC_EXPORT=1` (rewrite `parts/geometry.scad`).

`tests/toggle.lua` is one flip-flop alone, under its channel, with balls
let go one at a time: it is where the rocker was worked out (its header
lists its settings; `FINDINGS.md` has what it showed).

## Printing and building

`./make-stls.sh` (needs OpenSCAD, and bpp to refresh `geometry.scad`)
writes every part into `stl/`, each turned to lie on the bed. Every shape a
ball or a rocker touches comes from `digicomp2-geometry.lua`, the same
numbers the simulation uses. The largest pieces are the three tiles of the
board, 188 x 156 mm.

| Part | Print | Size (mm) | Notes |
|---|---|---|---|
| `tile-0.stl`, `tile-1.stl`, `tile-2.stl` | 1 each | 188 x 156 x 16 | the board in three pieces, top to bottom: its face (4 mm), the walls (12 mm high), the stop pegs, the bosses the rockers turn on, and the lettering cut 0.6 mm deep (fill it with paint, or change filament at that layer) |
| `rocker.stl` | 3 | 44 x 19 x 9 | the flip-flops. 100% infill: the simulation's rocker is solid PLA (2.5 g) |
| `wheel.stl` | 1 | 39 x 39 x 9 | the feeder's wheel |
| `knob.stl` | 1 | 28 x 28 x 14 | glued onto the wheel's hub; its four marks are the quarter turns |
| `foot-back.stl` | 2 | 30 x 133 x 30 | the stand's tall back feet (20% infill is plenty) |
| `foot-front.stl` | 2 | 30 x 21 x 30 | its low front feet |

**Also needed**

- **8 steel balls, 1/2 inch (12.7 mm)**, 8.35 g each (and a few spare).
  Bearing balls are round and all alike, which glass marbles are not.
- **3 steel balls, 1/4 inch (6.35 mm)**, 1.04 g: the rockers' weights,
  pressed into the pocket under each apex, flush. They matter: without them
  a rocker's two leanings are so shallow that it can bounce back out of one
  (see `FINDINGS.md`).
- **3 mm steel dowel pins**: three 16 mm long for the rockers, one 20 mm
  for the wheel, pressed into the holes in the board's bosses.
- A **backing sheet** of 6 mm plywood, 185 x 467 mm, the tiles glued on it
  edge to edge, and the feet glued under it at its corners.
- Glue; a little dry PTFE or graphite on the pins.

**Assembly.** Glue the three tiles onto the backing sheet, edge to edge, the
walls lining up across the joins (run a ball down each lane across a join:
it must not catch). Glue the tall feet under the back corners and the low
ones under the front, so the board slopes at 15 degrees toward you. Press
the pins into the bosses, the rockers' weights into their pockets, and drop
each rocker on its pin, roof up the slope, then the wheel, then glue the
knob on it. **Level the board across**: the counter works with the table
tilted up to 2 degrees either way across, but not 3 (see `FINDINGS.md`);
a spirit level on the bins' wall does it. Set each rocker to 0 (apex to the
left), put the balls in the channel above the wheel, and turn the knob a
quarter turn at a time.

The knob's first quarter turn after loading fills the wheel: balls come out
from the second. (In the simulation, the hand loads the wheel's two
notches as it sets the balls back, so the first turn lets one out.)

## What is not as built

- **The hand.** The knob is turned by the hand, a quarter turn at a time:
  in the simulation a motor on the wheel's pin, strong enough not to stall.
  Setting it back (`R`) puts the balls and the rockers where the hand would.
- **The pins** are hinges with a constant friction torque, 0.4 kg cm^2/s^2
  (`DC_PF`): PLA on PLA at the boss, worked out in `FINDINGS.md`. The
  counter still works at seven times that.
- **The lettering** is drawn on the board's face, not cut into it.

See `FINDINGS.md` for how the numbers were arrived at.
