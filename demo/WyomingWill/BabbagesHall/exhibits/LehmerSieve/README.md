# Lehmer's number sieve

`README.pdf` beside this file is a typeset copy of it.

Babbage's Hall, east bay 1. A number sieve after Derrick Lehmer's (1926
and 1932): wheels of different numbers of places, all moved on together,
with holes where a number passes a test. Where every wheel has an open
hole at the reading place, a probe falls right through, and the machine
stops: that number passes every test at once.

Lehmer's first sieve was made of bicycle chains, each loop as many links
long as its test's modulus, with a rod standing out of the links for the
remainders that pass. The rods closed small switches as the chains went
round, and when every switch was closed at once, a signal ran the length of
the machine. His 1932 sieve had gears of different sizes with a hole for
each remainder, the holes not wanted plugged (with toothpicks), a bright
light on one side and a photocell on the other: when the holes lined up,
light reached the cell, and its signal, amplified, stopped the motor. This
one is mechanical throughout: holes in printed wheels, pegs in the holes
that fail (Lehmer's toothpicks), and a probe that falls by its own weight.

## What it does

It factors a number N by Fermat's way. If x * x - N is a square, y * y,
then N = (x - y)(x + y). Fermat tried x = the first whole number past the
square root of N, then the next, and so on. The sieve does the trying. A
square leaves only certain remainders when divided by m (by 8: 0, 1 or 4),
so x * x - N can be a square only when x mod m is one of a few. On the
wheel of m places, those holes are open and the rest are pegged. After x
turns from 0, the hole under the probe on the wheel of m places is the one
marked x mod m, so the probe falls right through only at an x that passes
the test for all four wheels at once: 9, 8, 7 and 5 places, which between
them repeat only every 2520 turns.

The sieve only says "maybe": each x it stops at must still be tried by hand
(is x * x - N a square?). For N = 1241, starting at x = 36, it stops at 39
(39 * 39 - 1241 = 280, not a square), and at 45 (45 * 45 - 1241 = 784 =
28 * 28), so 1241 = 17 x 73. Over every 2520 turns, only 144 x get past all
four wheels for 1241 (one in 17); the tour's first ten happen to hold two
of them. With more wheels it would reject still more. Lehmer's
chain sieve tried about 60 numbers a second, his gear sieve about 5000.

## The machine

- **Four wheels** on one fixed axle, one above the other: 9 places at the
  bottom, then 8, 7 and 5. Each is a **Geneva star**: a wheel with a slot
  for each place. Beside them is the **drive shaft**, with the handle on top.
  Under each wheel the shaft carries a crank with a pin. Once a turn, the
  pin enters a slot, turns the star on by exactly one place, and leaves it.
  So one turn of the handle moves every wheel on by one place, whatever its
  size. Beside each star, the shaft carries a **locking disc** that rides in
  the star's curved edge between turns, so the star can't be turned out of
  step.
- **A detent** for each wheel, a printed leaf spring with a round nose that
  rests in the mouth of the slot opposite the drive, against both of its
  corners. It puts each star exactly on its place between turns. (The
  locking disc keeps a star within about a degree of its place: the detent
  puts it there. See `FINDINGS.md`.)
- **A ring of holes** in each wheel, one per place, marked with its number.
  **Pegs** close the holes of the numbers that fail.
- **The probe**, a steel rod at the reading place, above the stack, in a
  guide. An arm from it reaches over to the **cam** on top of the drive
  shaft, which lifts it before the wheels move and lets it down after they
  have stopped. It falls through as many wheels as have an open hole under
  it. Right through, it comes to rest in the **bell** at the bottom.

## Using it

The hand turns the handle a whole turn at a time. Watch the probe: it goes
down into the stack as far as the first pegged hole. When it goes right
through, the tour (and `G`) stops, and the console says whether x * x - N
is a square.

| Key | |
|---|---|
| `Space` | one turn of the handle |
| `G` | go: turn until the probe falls right through (`G` again: stop) |
| `N` | the next number to factor: 1241, 1679, 1157, 2813 (re-pegs the wheels and sets them to its first x) |
| `R` | set the wheels back to the first x |
| `T` | the tour: factoring 1241 (it starts with it) |
| `Z` | slow motion (1/4 speed) on and off |

Rest the mouse on a wheel to see which hole is under the probe and which
are open; on the probe, how far it has gone through.

Sliders: `friction` (0.1 to 0.4 checked), `turn rate` (how fast the hand
turns the handle, 0.25 to 1 turn a second checked), `speed`.

## Running it

Open `lehmer-sieve.lua` in bpp, or run it inside the hall
(`HALL_START=lehmer`). It starts with the tour, which prints each turn's
reading and `RESULT lehmer-sieve tour: PASS` when every reading was right
and the factors are found. At every turn it checks that the probe went
exactly as far as the pegs say it should, and that the wheels, read on
their own, show the x the hand has counted to.

Environment, for testing: `LS_TOUR=0` (no tour), `LS_N` (the number to
factor), `LS_GO=1` (turn until the probe falls through, without the tour),
`LS_FRICTION`, `LS_RATE`, `LS_LOG=1` (every turn's reading), `LS_LOG=2`
(also the handle, the wheels' places, the probe and the detents every half
second; `LS_LOGDT` sets how often), `LS_HZ` (steps a second, 2400),
`LS_ITER` (solver passes, 20), `LS_REST=0` (never rest), `LS_REST_LOG=1`.

Once the hand is done and nothing moves, the machine rests: it stops
stepping until the next key, which saves the processor and changes nothing
it computes.

## How it is built

- **One source.** `parts/make-geometry.py` (needs shapely) works out every
  moving part's outline: the stars with their slots, locking arcs and
  holes, the locking discs (a disc, less wherever its star passes in a turn),
  the cranks, the cam's profile and the detents. It writes them to
  `parts/geometry.scad`, which `parts/lehmer-sieve.scad` builds the printed
  parts from, and to `sieve-geometry.lua`, the same outlines cut into convex
  pieces for the simulation. What is printed is what was simulated.
- **Bodies.** Each wheel is one body on a hinge about the axle; its pegs are
  part of it (a peg not wanted is moved into the wheel's hub, where it
  touches nothing). The drive is one body on a hinge (the shaft, cranks,
  pins, locking discs and cam). Each detent is a body on a hinge at its
  leaf's root, turned back by the leaf's own stiffness (3EI/L, PLA's
  modulus), with a stop. The probe slides in its guide (a slider).
- **The hand** is a motor on the drive's hinge, steered a whole turn at a
  time. The wheels move only as the pins push them, and the probe only as
  the cam and gravity move it.
- **Idealised:** the hand stops turning when the probe falls right through
  (Lehmer's photocell and relay did that); here a person watching would. The
  wheels are set to their first x by hand (lift each off its axle, turn it,
  put it back), as the simulation does by placing them.

## Printing and building

`./make-stls.sh` (needs OpenSCAD) writes every part into `stl/`, each
turned to lie on the bed. The largest is the 9-place wheel, 150 x 152 mm.

| Part | Print | Size (mm) | Notes |
|---|---|---|---|
| `wheel-9.stl`, `-8`, `-7`, `-5` | 1 each | 149 x 152 x 5.5 (the 9) | the numbers stand 0.5 mm proud: paint them, or change filament there |
| `peg.stl` | 20 | 7.6 x 7.6 x 5 | a push fit in the 8 mm holes; paint them red |
| `crank-9.stl` ... `-5` | 1 each | 42 to 63 x 15 x 5 | a 6 mm steel dowel pressed into the end, standing 6 mm up |
| `lock-9.stl` ... `-5` | 1 each | 42 to 89 x 47 to 89 x 6 | the locking discs |
| `cam.stl` | 1 | 90 x 90 x 65 | 15% infill is plenty |
| `handle.stl` | 1 | 44 x 14 x 25 | |
| `detent-9.stl` ... `-5` | 1 each | 10 to 23 x 37 to 42 x 5 | PLA, 100% infill; the leaf is 1.2 mm, three lines of a 0.4 mm nozzle; its root goes on 6 mm past the hinge, into the post's slot |
| `detent-post-9.stl` ... `-5` | 1 each | 24 to 57 tall | the leaf's root presses into the slot in its block |
| `probe-arm.stl` | 1 | 79 x 12 x 13 | the ball is glued into the socket under its end |
| `guide.stl` | 1 | 99 x 77 x 12 | printed on its side |
| `washer.stl` x3, `washer-low.stl` x1 | | 18 across | between the wheels on the axle |
| `bell.stl`, `bearing.stl`, `shaft-washer.stl`, `axle-nut.stl`, `foot.stl` x4 | | | the bearing goes under the base; the shaft washer on it, under the lowest crank |

**Also needed**

- **Plywood,** 12 mm, 270 x 190 mm, for the base: `stl/cut-base.svg` has its
  outline and holes. Glue the four feet under its corners.
- **8 mm steel rod,** 65 mm, the wheels' axle (pressed into the base).
- **6 mm steel rod,** 135 mm, the drive shaft, with a flat filed 0.8 mm deep
  along it (the drive's parts have D-shaped bores, so that the pins, the
  locking discs and the cam go on at their angles). It turns in the bearing
  under the base and in the base.
- **4 steel dowels,** 6 x 10 mm, the cranks' pins.
- **5 mm steel rod,** 85 mm, the probe.
- **An 8 mm steel ball,** the follower under the probe's arm.
- Glue; a little dry PTFE on the slots, the locking arcs and the cam.

**Assembly.** Press the axle and the detent posts into the base, the shaft
through the bearing and the base. Put the shaft washer on the shaft, then slide
the drive's parts down it in order: for each wheel from the bottom, its
crank, then its locking disc; then the cam. Each goes on the flat, and they
stand on one another's hubs. Glue the handle on the top. Put the low washer on the axle, then the 9-place
wheel, a washer, the 8, a washer, the 7, a washer, the 5, and the nut.
Turn the handle slowly once to see each pin go into a slot and out again.
Fit the detents (press each leaf into its post's slot; the nose drops into
the mouth of the slot opposite the drive). Set the guide in the base, the
probe through its sleeve, the arm on the probe with its ball on the cam.
Then peg the wheels for a number (the console lists the open holes), set
each wheel by hand so the hole for x mod m is under the probe, and turn.

See `FINDINGS.md` for how the numbers were arrived at.
