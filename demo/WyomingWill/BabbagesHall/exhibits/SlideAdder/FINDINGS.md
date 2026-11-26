# The Slide Adder: findings

What was measured while building the slide adder (2026-11-25). All runs
headless, 600 steps a second, unless said. Each sweep is the tour's three
sums and twenty at random (two five-figure numbers each; subtracting,
their sum less one of them), each from 0.

## 1. The prototype

A scratch script first (`HANDOFF.md` section 6): two to six bands of pegs
on sliders, the cover's slots and channels as boxes, and a stylus moved
by a force toward where a hand means it to be. 47 + 85, 47295 + 85358,
99999 + 1, 99999 + 99999 and 12345 + 98765 came out right at once, at a
hand of 1 to 10 cm a second, and at 600 and 1200 steps a second.

**The carry's one step fell short.** A push to a slot's end leaves the band
exactly in step (7.008, 1.997 steps: the slot's end stops the stylus).
But "one step down" after the hook left the next band at 0.928: the stylus
has 0.5 mm of play between two pegs (a 3 mm ball in a 4 mm gap), and the
hand's stiffness gives a little more under the band's friction. A person
pushes "a bit" until the band has moved one step; the hand now goes on 0.6
mm past the step, and the band lands at 1.003.

## 2. Standing upright: friction against weight

The adder stands upright, so a band must be held by more friction than its
weight (12 g: 11.8 kg cm/s²). The bands' friction is a motor on each
slider at no speed and a limited force, 20 by default.

| a band's friction | adding | subtracting |
|---|---|---|
| 10 (less than its weight) | every band slides to the bottom: 999999 | |
| 13 | 23 sums right | 23 right |
| 20 (default) | 23 right | 23 right |
| 60 | 23 right (with the bar's force raised: section 5) | 23 right |

The friction slider starts at 13. A pocket Addiator lies flat and never
meets this; a printed one standing upright needs a groove that grips (a
strip of felt, or wax on a tight fit).

## 3. The hand

The stylus is a body: a ball among the pegs and a ball in the slot, with
no gravity, no turning, and a force toward the hand's target, 1000 kg/s²
stiff (0.03 cm off for a band's friction) and damped, capped at 2 N (200
kg cm/s²). It goes where the slot and the pegs let it and stops where they
don't; the operator reads "stopped" when it rests more than 1.5 mm short of
where it was sent.

| run | adding | subtracting |
|---|---|---|
| as it is (hand 6 cm/s) | 23 right | 23 right |
| hand 2 cm/s; 15 cm/s | 23 right each | 23 right each |
| force 120 (1.2 N) | 23 right | 23 right |
| force 25 (0.25 N) | wrong from the first sum | |

At 0.25 N the hand can push a band down (that needs the friction less the
weight, 8.2) but not up (friction plus weight, 31.8): it takes a band it
can't lift for a 9 that won't take a carry, and the carries go astray
(47295 + 85358 read 047595). Anything from 1.2 N on works.

## 4. Steps a second: a stopped band must stop the stylus

| steps a second | adding | subtracting |
|---|---|---|
| 300 | 6 of 23 wrong | 23 right |
| 600 (default) | 23 right | 23 right |
| 1200 | 23 right | 23 right |

At 300 the failures were all carries running into a 9 (99999 + 1 read
099990): the stylus, pushed down on a band already at its bottom, squeezed
past the peg instead of stopping, so the operator never felt the 9 and
didn't carry on. Bullet's contacts are soft, and a coarser step lets the
ball sink further into the peg. At 600 and 1200 the block held at every
force tried, up to 10 N (five times the hand's), on 99999 + 1. Subtracting
at 300 passed: its blocked moves push up against a band at its top, which
the slider's limit holds without the peg's help.

## 5. The zeroing bar

The bar lifts every band at once, so its force must beat six bands'
friction and weight together. At 4 N it could not lift six bands at
friction 60 (6 × (60 + 11.8) = 431), and the next sum started from
leftovers (67262 read 167173; 5 of 23 wrong). The hand on the tab now
pulls up to 10 N, and friction 60 passes both ways.

## 6. The printed parts

**The cover fell apart into islands.** With a channel along the top
(carries) and one along the bottom (borrows), the cover between two slots
is cut off on every side: the first STL of a cover half had six separate
solids. The five islands are now parts of their own, each glued onto two
studs that rise from the rib behind it (the ribs run between the bands,
where nothing moves).

**The ribs crossed the bar's path.** The ribs that keep the bands apart
first ran the full height of the back, through the zeroing bar's travel.
Every band always covers the height from 100 mm to 215 mm whatever it
reads, so the ribs now start at 100 mm and guide every band all the same,
and the bar runs free below.

Checked with manifold3d (OpenSCAD's intersection of the assembled parts):
the bands at both ends of their travel against the back and the cover,
the bar at both ends against the back, the cover and the bands: no
overlap, the raised bar just touching the bands' feet. The cover, the back
and the studs meet at 0.01 mm glue faces. Every STL is one watertight
solid, under 200 mm.

## 7. Timing

The tour ends at frame 5527 adding (99999 + 1 is the longest, with its
five nines), 5033 subtracting; check-all allows 6500 on its own, 7200 in
the hall. A sum of two five-figure numbers takes about 27 simulated
seconds at the hand's 6 cm a second, clearing included (23 sums, 37348
frames).

## 8. Seen in the pictures

The bands' digits show through the bottom channel as well as the window:
the channel crosses every band below its pegs, where its digits are. An
Addiator's hooks are short curves, and show only a sliver of band; here
the channels are straight across. It changes nothing read (the windows
are the reading), and the README says so.
