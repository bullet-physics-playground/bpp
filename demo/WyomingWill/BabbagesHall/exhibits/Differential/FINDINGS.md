# The Differential: what the simulation showed

`FINDINGS.pdf` beside this file is a typeset copy of it.

## Meshing

The four 16-tooth mitre gears mesh with each spider turned half a tooth
(11.25 degrees) from the side gears, as the geometry says: each side gear has
a tooth pointing at each spider, so the spider needs a gap there.

Checked outside Bullet by intersecting the printed meshes (trimesh,
manifold3d): the overlap volume is zero between 11.0 and 11.5 degrees, and
rises steadily on either side, to 488 mm³ at 0 degrees.

## Mesh-to-mesh contact (GImpact) doesn't work for these teeth

With each gear's printed mesh as its collision shape (Bullet's GImpact), the
gears never behaved:
- **Holding fails:** an input held by its motor was dragged round with the
  other.
- **No clean reading:** the carrier's turn was 10 to 60% off (A + B) / 2.
- **Spiders loose:** the spiders spun about axes other than their pins.
- **Nothing helped:** changing the margin (0.05 mm), the solver iterations
  (10 to 50), the motor strength (5 to 500), the friction (0.05 to 0.3), or
  driving the inputs kinematically.
- **Phase search:** looking for the spiders' phase by the kick their teeth
  gave at rest found only noise: near-zero at isolated angles, large at their
  neighbours.

Two set-up mistakes were found on the way, then fixed:
- An OpenSCAD mesh's place has to be set after it is added to the world. At
  first all four gears sat at the origin.
- A part's collisions are fixed when it is added. Turning `collides` on
  afterwards does nothing.

## Convex pieces do work

Each gear as a compound of convex hulls: its body inside the root cone (224
points), and its 16 teeth outside it (one 24-point hull, placed 16 times).
The tooth's hull is only 2% bigger than the tooth, the body's 1.6%. Masses
and inertias come from the printed parts at 0.8 g/cm³. With motors on the
inputs, over 4 s:

| A (turns/s) | B (turns/s) | carrier (turns) | (A + B) / 2 | error |
|---|---|---|---|---|
| 0.25 | 0 (held) | +0.4751 | +0.4751 | 0.00% |
| 0.25 | 0.25 | +0.9495 | +0.9495 | 0.00% |
| 0.25 | -0.25 | -0.0009 | -0.0009 | (2e-5 turns) |
| 0.5 | 0.1 | +1.1461 | +1.1461 | 0.00% |
| -0.4 | 0.3 | -0.1926 | -0.1926 | 0.02% |

That was at 10 solver iterations, and it ran faster than real time. The
exhibit uses 20.

## The hand

- **Both at once:** turning both inputs together and then stopping one jams
  the simulated teeth. The load jumps across the backlash all at once. So the
  hand turns one input at a time, as a person turns one crank at a time.
- **Holding:** an input held only at zero speed creeps (0.08 units) under the
  load from the other. The hand steers the held one back to where it was set.
- **Back-driving:** at friction 0.1 the held input is pushed 0.3 units before
  the hand corrects it. That is realistic: a slippery differential back-drives
  its other input unless it is held firmly.

## The tour (3 + 4, then 12, then 10, then 0)

| Setting | Result |
|---|---|
| friction 0.1 | PASS |
| friction 0.3 | PASS |
| friction 0.5 | PASS |
| hand speed 0.2 turns/s | PASS |
| hand speed 0.4 turns/s | PASS |
| hand speed 0.8 turns/s | PASS |

The ring agrees with A + B to 0.01 units every time.

## Resting

Once the hand has nothing to do and nothing has moved for half a second,
the Differential stops stepping until there is something to do again. Stepped at
2400 steps a second, a machine at rest costs as much as one running, and
its parts never quite stop (their sleeping is turned off, as it must be
while they work): what was left once it had settled was up to about 0.05 cm/s and 0.03 rad/s (the gears in their backlash).
"Not moving" is set just above that: 0.1 cm/s and 0.05 rad/s. Resting can't change a
result: woken, it carries on from exactly the state it stopped in,
speeds and all. Its sweep (friction 0.1, 0.3, 0.5; hand 0.2 and 0.8 turns a second) was run again with resting on: 6/6. Over a 70 s run, 79 s of computing became 16 s.
