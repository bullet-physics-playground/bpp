# The Suanpan

*Babbage's Hall, west bay 1: the Chinese abacus.*

The first machine on the walk, and the oldest. Seven rods; on each, two
**heaven beads** above the beam (the reckoning bar) and five **earth
beads** below it. A bead counts when it is pushed to the beam: a heaven
bead 5, an earth bead 1. So each rod holds a digit from 0 to 9, the units
on the right, and the abacus a number up to 9,999,999.

Type a number and press Return, and the operator's finger adds it, rod by
rod from the left, as it is done by hand. A slate beside the abacus shows
the number on it, the one being added, the rod the finger is at, and the
rule it is using:

| Rule | When | Example |
|---|---|---|
| direct | there is room on the rod | +3: three earth beads up; +7 = 5 + 2: the heaven bead down, two earth beads up |
| five-complement | not enough earth beads left | +3 = 5 − 2: the heaven bead down, two earth beads away |
| ten-complement | the rod would pass 9 | +8 = 10 − 2: two earth beads away, and carry 1 to the rod on the left |
| ten and five together | taking away 10 − a needs the heaven bead | +6 = 10 − 4, and −4 = −5 + 1: one earth bead up, the heaven bead up, carry 1 |

A pupil learned these by heart: nobody works out 7 + 8 on an abacus. The
rules are in `plan.lua`; checked against plain arithmetic on 120,000
random additions, all six cases come up and none goes wrong.

    bpp -f suanpan.lua                  (or walk to it in the hall)

| Key | |
|---|---|
| `0`–`9` | a number to add (the slate shows it) |
| `Return` | add it |
| `Backspace` | its last digit off |
| `C` | clear the abacus: heaven beads up, earth beads down |
| `T` | the tour: 3, 4, 8, 6, 79 and 1234 added, a rule of its own each, to 1334 |

The sliders: the beads' friction on their rods, the finger's speed, and the
simulation's speed. Resting the mouse on a bead, the frame, the slate or
the finger says what it is and what the abacus reads.

## What is simulated, and what is the script's

Each bead is a body that slides on its rod (a slider constraint along the
rod; a motor on it at no speed and a small force is the rod's friction, so
a bead stays where it is left). The finger takes hold of one bead and moves
it; that bead pushes the others ahead of it by contact, as a finger does on
a real abacus, and they stop where they meet the beam, the frame or the
beads already there. The beads' value is read from where they are, after
every addition, and checked against what the rules say it should be.

The finger, the slate and the reading of the beads are the script's: a
person works an abacus, and the slate is there to show what the person
knows. `FINDINGS.md` has the measurements.

## The parts

Every part is printed but the rods. `./make-stls.sh` makes them, each turned
to lie on the printer's bed (OpenSCAD); all are under 200 mm.

| Part | Print | Notes |
|---|---|---|
| `bead.stl` | 49 | 20 mm across, 12 mm thick, a 3.4 mm hole; any colour darker than the frame |
| `bar-near.stl`, `bar-far.stl` | 1 each | 192 × 12 × 24 mm; blind holes for the rods |
| `bar-side.stl` | 2 | 120 × 12 × 24 mm |
| `beam.stl` | 1 | 168 × 8 × 20 mm, the rods through it |
| `slate-left.stl`, `slate-right.stl` | 1 each | the slate's board and foot, in halves; paint the face with blackboard paint |
| `slate-frame-left.stl`, `slate-frame-right.stl` | 1 each | its frame, in halves |

Buy: seven 3 mm steel rods, 136 mm long (silver steel or stainless).

**Assembly.** Thread the beads on the rods: five, then the beam, then two.
Push the rods' ends into the near and far bars' holes, glue the side bars
between the ends, and glue the beam to the side bars 74 mm from the near
bar's inner face. The beads should slide freely but not fall along a rod
held upright: if they are loose, a 3.2 mm hole holds them better.

## Files

| File | |
|---|---|
| `suanpan.lua` | the exhibit |
| `plan.lua` | the rules for adding, as moves of beads |
| `parts/suanpan.scad` | every part's shape |
| `make-slate.py`, `slate/` | the slate's pictures (Pillow), and the rules' words |
| `make-stls.sh` | the STL files (not kept in the repository) |
| `FINDINGS.md` | what was measured |
