# The Suanpan: findings

*What was tried and measured in building it (2026-11-15).*

## Beads on rods

A bead is a body on a slider constraint along its rod (the constraint's
axis is its frame's x, turned along the rod). Its limits are its own
range: an earth bead from where it rests against the beads below it to
where it rests against the beam and the beads above, so a stack's places
are exact and the reading is crisp. The beads also touch: each is a
convex hull of its own shape (two cones back to back), so a bead pushed
along the rod pushes the next by contact.

**Friction is a motor.** A slider's linear motor at zero speed with a
small maximum force holds a bead where it is left and lets anything
stronger move it: Coulomb friction along the rod. The default is 0.3 kg
cm/s² (3 mN): a bead going 6 cm/s stops in about 1.4 mm when let go.
Gravity plays no part (the abacus lies flat, as one is used).

**A finger that hits hard scatters the beads.** In the first prototype the
finger drove a bead at 10 cm/s with full force and let go at a fixed place:
the beads ahead were knocked on, apart from one another, and the driven
bead bounced back off them (restitution 0.2). Steered instead, its speed
proportional to how far it has to go (10 per second, at most the finger's
speed) and with no bounce between beads, the stack closes up against the
beam and stays: 2.47, 3.88 and 5.30 cm along the rod for the last three of
five, 1.41 apart (the beads are 1.2 cm, plus their collision margins). The
finger counts a bead as there within 0.3 mm, held 0.08 s; it waits for the
beads' own spacing, not an exact place (asked for 0.1 mm better than packed
beads can sit, it never let go).

**Moves.** To push earth beads up, the finger takes the farthest of those to
go and moves it to its place at the beam; the ones between go ahead of it.
To push them down, it takes the nearest of those to go, beside the ones
staying, and moves it down; the ones below it go ahead. A heaven bead is
moved alone (only the first is used in adding; the second stays up, as
the five extra counts are only for older methods of division).

## The rules

`plan.lua` turns an addition into steps, each a rule and the moves for it,
digit by digit from the left, a carry added at once to the rod on the
left (and on, if that rod passes 9 too). Against plain arithmetic, 20,000
runs of six random additions (120,000 in all, totals up to 9,999,999): none
wrong, and every move legal (no rod asked for more than one heaven bead or
four earth beads). How often each rule came up:

| direct | direct with the heaven bead | five-complement | ten-complement | ten, by way of five | ten, the heaven bead up |
|---|---|---|---|---|---|
| 345,409 | 124,999 | 69,321 | 100,083 | 50,044 | 94,081 |

## The tour, and the sliders

The tour adds 3, 4, 8, 6, 79 and 1234 to a clear abacus: direct, the
five-complement, the ten-complement with a carry, ten by way of five, a
carry that runs on over two rods (21 + 79 = 100), and four rods direct.
The beads must read 3, 7, 15, 21, 100 and 1334 after each. It passed at
every setting tried (headless, 2026-11-15):

| Setting | Tour |
|---|---|
| friction 0.05, 0.1, 0.3, 0.6, 1.0, 2.0 kg cm/s² | all pass |
| the finger at 2, 5, 8, 12 cm/s | all pass |
| 300, 600, 1200 steps a second | all pass |
| 40 random numbers up to 99,999 added, checked after each | pass |
| the same, the finger at 12 cm/s and friction 0.1 | pass |

At 600 steps a second (the default) a frame is ten steps of 49 beads on
their sliders: light work. When nothing is moving and the finger has
nothing to do, the exhibit rests (stops stepping) after half a second,
as the others do.

## Sizes

A bead is 1.8 cm³ of PLA, 2.3 g solid. Real suanpans have 13 rods or more;
seven keep every printed part under 200 mm (the near and far bars are 192
mm) and hold numbers up to 9,999,999, enough for the tour and most sums.
The slate is printed in halves (280 × 170 mm).

## Not done

Subtraction (the same rules backward), multiplication and division; the
second heaven bead and fifth earth bead, used in old division methods
(and for the sixteen ounces of the old Chinese pound, a rod holding up to
15) are there but never moved.
