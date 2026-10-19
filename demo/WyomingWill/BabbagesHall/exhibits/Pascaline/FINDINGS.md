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
7. **The kick fell short** (about 0.88 of a step) and the click pulled the
   tens back. Two changes: the pawl's tip lowered (`TIPY` -0.17 cm) so it
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
- **The click** in the simulation is gentle. A real detent spring that is
  too strong will need a heavier weight to overcome.
