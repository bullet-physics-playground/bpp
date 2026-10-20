# The Pascaline: findings

`FINDINGS.pdf` beside this file is a typeset copy of it.

How the carry was made to work in the simulation, in the order the
problems turned up. All the numbers live in `pascaline-geometry.lua`.

## The tuning history

1. **The hand turned into the cam's drop.** The first build turned the
   digits the wrong way, so the follower met the cam's steep face and
   jammed. Fixed by turning clockwise as seen from the front (the cam rises
   under the follower). Note that bpp's `getHingeAngle` is clockwise-positive
   about the hinge's axis, so a digit's value is `angle / 36°`.
2. **The digits passed through everything.** They had been added with
   `collides` set after `v:add`; collision groups are fixed when a body is
   added, so it must be set before.
3. **A high pivot swung the pawl sideways.** With the sautoir pivoted above
   the axles, the follower and the pawl's tip moved along arcs that pushed
   sideways on the cam and the pins as much as up. Moving the pivot down to
   the axles' height (`PA` 6 cm, then 10 cm from the next axle) made both
   move nearly straight up and down.
4. **Neighbouring cams collided.** A cam of radius 4.5 to 5 cm needs room;
   the axles' spacing `D` went from 8 cm to 11 cm.
5. **The nose caught the cam's foot.** At rest the follower's nose overlapped
   the start of the snail. Raising the cam's base radius to `R0` 1.5 cm and
   starting the nose `NOSEGAP` 0.5 mm above it fixed it.
6. **The pawl swung out as the lever dropped.** A pawl that yields one way
   must also be held against its stop, or the jolt of the drop throws it
   open and it misses the pin. A tail weight of 8 g (`TAIL`) holds it.
7. **The kick fell short** (about 0.88 of a step) and the click (the
   detent, then simulated as a pull to the nearest unit) pulled the tens back. Two changes: the pawl's tip lowered (`TIPY` -0.17 cm) so it
   pushes the pin for more of the drop, and the weight raised to 60 g.
8. **The ripple (99 + 1) failed.** The tens' sautoir dropped while the units'
   pawl was still on its way back, so the second carry came before the
   first had finished. Raising the cam's top (`R1` 4.5 to 5.0 cm) lifts the
   pawl clear of the pins sooner and gives it time to come back.
9. **Making it printable** changed nothing the simulation sees: gaps between
   the pawl's carrier and its arm were closed (the carrier's bar reaches
   1 cm further forward, the tail block reaches back to the link), and a
   boss was added round the pawl's pivot, where nothing comes near it.

## The checks

The tour (7, + 8 = 15, + 84 = 99, + 1 = 100) passes in all six runs of the
sweep:

| friction | turn rate (turns/s) | result |
|---|---|---|
| 0.15 | 0.3 | PASS |
| 0.30 | 0.3 | PASS |
| 0.45 | 0.3 | PASS |
| 0.30 | 0.15 | PASS |
| 0.30 | 0.6 | PASS |
| 0.45 | 0.6 | PASS |

It also passes inside the hall (`HALL_START=pascaline`), in the exhibit's
own sandboxed world.

Every STL checks as a single watertight solid (trimesh), and the simulated
parts do not overlap at rest (manifold3d).

## What a real build should watch

- **The weight** is what the carry runs on. With the lighter weight used
  before step 7 the kick fell short in the simulation; a real machine, with
  more friction, may want more than 60 g.
- **The pawl's tail** must hold the pawl against its stop firmly but let it
  yield easily over a pin. Adjust by adding or removing a nut.
- **The detents** must hold a wheel without fighting the carry: see below.
  A real one printed outside 1.0 to 1.6 mm, or in a stiffer plastic than
  PLA, may stop the carry or let a wheel overshoot.

## Resting

Once the hand has nothing to do and nothing has moved for half a second,
the Pascaline stops stepping until there is something to do again. Stepped at
2400 steps a second, a machine at rest costs as much as one running, and
its parts never quite stop (their sleeping is turned off, as it must be
while they work): what was left once it had settled was about 0.005 cm/s and 0.008 rad/s.
"Not moving" is set just above that: 0.05 cm/s and 0.02 rad/s. Resting can't change a
result: woken, it carries on from exactly the state it stopped in,
speeds and all. The sweep above was run again with resting on: 6/6.

## The detents

The simulated click (a weak pull to the nearest unit) became a printed
part, simulated as itself: a PLA leaf spring for each wheel, its round nose
(14 mm) resting between the two pins at 9 o'clock, rising from a block
screwed to the back of the front plate. In the simulation it is a body on a
hinge at the leaf's root, turned back by the leaf's stiffness worked out
from PLA (a cantilever: 3EI/L, E = 3.5 GPa), with a 0.5 mm preload. To let
a pin by, the nose rides out 4.7 mm.

Its thickness was found by running the tour at each (stiffness goes as the
cube of it):

| leaf | result | the readings' digits (tens and hundreds at 015, 099, 100) |
|---|---|---|
| 0.5, 0.6, 0.7 mm | FAIL | 99 + 1 gives 200: too weak to stop the hundreds, which overshoots |
| 0.8 mm | PASS | but the tens rests at 0.94 at 015: the units' pawl, riding a pin, holds it back |
| 1.0 to 1.6 mm | PASS | every wheel centred (1.00, 9.00, 1.00) |
| 1.8 mm and up | FAIL | too stiff: the sautoir's drop can't push the next wheel past its detent |

The window is 1.0 to 1.6 mm, four times in stiffness; 1.2 mm is near its
middle on that scale and is three lines of a 0.4 mm nozzle. At 1.2 mm the
leaf bends to at most 0.5% strain, well within PLA's.

With 1.2 mm leaves, the sweep (friction 0.15, 0.3, 0.45; the hand at 0.15
and 0.6 turns a second; and both at once) passes 6/6, every reading
centred, and the tour passes inside the hall. The parts don't overlap at
rest (manifold3d); `detent.stl` is a single watertight solid.

