# The bead sort: findings

`FINDINGS.pdf` beside this file is a typeset copy.

What was measured in the simulation while the exhibit was built, and what
it means for a real one. All runs are `bpp -f bead-sort.lua` with the
tour, under Xvfb, on 2026-11-22.

## 1. How the beads are simulated

Each bead is a body (a 2 cm octagonal bead, 1.2 cm thick, 4.5 g) held to
its rod by a slider: it can move only along the rod. The slider's motor,
held at zero speed with a limited force, is the bead's friction on the
rod; the `friction` slider sets that force. Beads stop on each other by
contact, and on the bars by the slider's limits. The frame is a body on a
hinge, turned by the hinge's motor; the hand's speed (the `hand` slider)
limits the motor's speed.

The world runs at 600 steps a second (ten steps for every frame drawn).
At one step a frame the frame turned slowly and the beads jittered: bpp's
`setTiming` gives one step a frame, so the exhibit runs the other nine
itself, before each frame.

## 2. When the first bead slides

A bead held by a friction force F starts down its rod when the part of its
weight along the rod, mg sin θ, passes F. The bead weighs 4.4 (in the
slider's units, kg cm/s²), so it should start at sin θ = F / 4.4. The
exhibit logs the frame's angle when the first bead has moved 3 mm toward
the hinge.

| friction | theory | first slide | later by |
|---|---|---|---|
| 0.3 (as it is) | 3.9° | 9.0° | 5.1° |
| 1 | 13.1° | 18.0° | 4.9° |
| 2 | 27.0° | 32.0° | 5.0° |
| 3 | 42.9° | 48.0° | 5.1° |
| 4 | 65.1° | 71.5° | 6.4° |
| 4.6 (more than its weight) | never | never | |

The measured angle is always about 5° later than theory, at every
friction. That is the time the bead takes to move the 3 mm, while the
frame keeps turning. Turning the frame slower or faster confirms it:

| hand | first slide | later by | in time |
|---|---|---|---|
| 10°/s | 6.2° | 2.3° | 0.23 s |
| 30°/s (as it is) | 9.0° | 5.1° | 0.17 s |
| 90°/s | 15.0° | 11.1° | 0.12 s |

So the friction model does what it should: beads start where theory says,
and the logged angle is later only because a bead has to get going. With
no friction (0) a bead drifts as soon as anything touches it, even with
the frame flat: the first "slide" is logged at 0°, from beads nudging each
other as the next row is laid.

## 3. Does it sort?

Each sweep ran the tour's three lists and twenty lists at random (one to
eight numbers, 0 to 9), each laid, turned, settled and read.

| run | lists | wrong |
|---|---|---|
| as it is (seed 1) | 23 | 0 |
| seed 2 | 23 | 0 |
| friction 0, 1, 2, 3, 4 | 23 each | 0 |
| hand 10°/s, 90°/s | 23 each | 0 |
| 300 steps a second, 1200 steps a second | 23 each | 0 |
| friction 4.6 | 3 | 3 |

Friction 4.6 is more than a bead's weight: no bead ever moves, the rows
stay as they were laid, and the exhibit says the rows are not sorted. A
real bead sort fails the same way if its beads are tight on their rods.
The slider stops at 3, below the weight; the sweep set 4 and 4.6 from
`BS_FRICTION`.

## 4. How long it takes

The frame takes 3.2 s to turn upright at 30°/s (the hand slows near the
end). The beads fall while it turns: by the time it is upright they have
already landed, and the exhibit's "settled" test (every bead slower than
0.2 cm/s on its rod for a quarter of a second) passes after 0.28 s, its
least. A bead falling the whole rod (10 cm) freely would take 0.14 s.

At its stop the frame chatters slightly, so "settled" is judged by each
bead's movement along its rod, not by the beads' speed in the world:
judged that way, the first list waited out the 3 s limit.

## 5. A fault found by the sweep

While beads fall, two beads on one rod can briefly be in the same row's
band, and the live count on the slate showed a row of 10 (and looked for
a picture `digit-10.png` that doesn't exist). A rod now counts once in a
row. The final reading, taken once everything has settled, was never
affected: every bead then has its own row.

## 6. For a real one

- **The beads must be loose.** Friction up to about two thirds of a bead's
  weight still sorts, but the frame must then turn almost upright before
  anything moves. Print the holes loose (3.6 mm on a 3 mm rod) and open
  them if a bead doesn't fall freely on a rod held upright.
- **Turn it slowly enough.** Nothing in the simulation went wrong at
  90°/s, but a real frame turned fast will throw beads against the stop.
- **Smooth rods.** Steel, not printed: a printed rod's layers catch.
