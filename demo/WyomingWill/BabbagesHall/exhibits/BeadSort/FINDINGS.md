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

## 7. The spaghetti sort (the second way, 2026-11-24)

`BS_WAY=spaghetti`: eight printed rods (8 mm across, 30 + 12 n mm long)
stood in a rack, a palm on a slider lowered onto them (`README.md`, "The
second way"). All runs headless, 600 steps a second, unless said.

### 7.1 Standing the rods: upright, not leaning

The first rack had the rods lean back 4 degrees against the comb's top
edge, with a stop for their feet, so that each would rest in one place.
Measured from the bodies' turns, they didn't: a rod stood on a flat foot
rights itself unless it leans past atan(r / (L/2)), 10.8 degrees for the
42 mm rod and 3.3 for the 138 mm one, so the short rods stood upright and
off the comb, and only the tallest leant, 5 degrees. And with nothing
holding its foot sideways, the 138 mm rod also leant **7 degrees sideways**
(its middle 8.5 mm from its slot's): the comb held it only near the top of
the rack, and its foot slid along the stop. Its top stood 1 mm low.

Now every rod stands upright: its foot in a notch (0.3 mm clear either
side, its front against the notch's front) and its upper part in the
comb's slot (0.5 mm clear). Between them it can lean at most 2.3 degrees,
less than the 3.3 at which the tallest still stands up again, so every rod
comes to rest upright. Measured: within 0.13 degrees, each top at the base
plus its length to 0.001 cm.

### 7.2 Where the palm stops

The palm's touch is looked for in the contacts after every step (at 3 cm
a second, 0.05 mm a step), and the hand stops it at once. Over the 119
touches of a 23-list run the palm stopped **0.08 to 0.18 mm** above the
rod's top (mean 0.13: Bullet reports a contact a little before the parts
meet). Rods differ by 12 mm a unit, so the reading has a hundred times
the room it needs. (Looked for once a frame, ten steps, the hand would
press on for up to 0.5 mm of travel before stopping; a real palm pressed
hard bends spaghetti.)

Two equal numbers stand equally tall, and the palm meets both in the same
step (5 0 5 2 8 2: the two 5s, then the two 2s): the hand takes the one in
the lower slot, then the other at once. Either order is right.

### 7.3 Does it sort?

Each sweep ran the tour's three lists and twenty at random (one to eight
numbers, 0 to 9).

| run | lists | wrong |
|---|---|---|
| as it is (seed 1; seed 2) | 23 each | 0 |
| palm at 0.5 cm/s; at 10 cm/s | 23 each | 0 |
| friction 0; 1.2 | 23 each | 0 |
| 300 steps a second; 1200 | 23 each | 0 |

Friction can't make it fail as it makes the bead sort fail: nothing has to
slide for the answer, only stand. The tour (three lists) ends at frame
4322, 72 simulated seconds; check-all allows 5000 (5600 in the hall).

### 7.4 What does make it fail: a palm out of level

`BS_TILT` lowers the palm's right end by so many degrees (a test; no
slider). The palm then meets a rod on the right early, by its distance
from the left times the tilt's tangent. A difference of one is 12 mm, and
the rack is 182 mm from the first slot to the last, so two rods one apart
could be taken out of order past atan(12 / 182) = **3.8 degrees**. Before
that, the palm's low end grounds on the comb before it reaches a short
rod at the far left: a 0 in slot 1 can't be reached past **2.8 degrees**.

| tilt | lists (seed 1) | wrong | how |
|---|---|---|---|
| 0, 2, 2.5 degrees | 23 each | 0 | |
| 3 | 23 | 3 | a 0 not reached (the palm on the comb) |
| 3.5, 4 | 23 each | 4 | the same |
| 5 | 23 | 5 | the same, and once two rods not reached |

No two rods were taken out of order in these lists (that needs a pair one
apart at opposite ends of the rack); the grounding comes first. A real
one: the post must hold the palm level to a degree or two, and lower it
gently.

### 7.5 A fault in bpp found on the way: wrong handles from eachContact

In the hall (not on its own) the palm never "touched" anything, and sat on
the tallest rod until the lowering gave up. `v:eachContact` names the two
objects of each contact by the handles they were added with
(`Viewer::addObject` keeps a reference to the value at index 2 of the Lua
stack). But the hall loads an exhibit in a coroutine, and `addObject`
reads the stack of bpp's main Lua state, not the coroutine's: for every
object added while the exhibit loads (the rack, the palm) it kept whatever
sat there, here the name of a slider ("Bead sort, spaghetti: palm").
Objects added later (the rods, during the tour) were right. The exhibit no
longer needs the palm's handle: a contact with a rod above the comb's top
can only be the palm's, since nothing else is there and rods never touch.
The fix in bpp is for Jakob (take the handle from the call's own Lua
state, as `luabind::object` does).

### 7.6 The carry, drawn

The rod taken leaves the simulation and is carried by the script. At
first it was turned about its middle while it moved, and it swept through
its neighbours (it looked as if a rod had fallen over). Now its foot is
lifted over the notch and it is drawn out toward you, clear of the rack;
then it is tipped toward you about its foot while lifted 3 cm, turned to
lie across, and lowered into the row: it passes over every rod standing
and every rod laid.
