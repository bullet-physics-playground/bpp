# Splitters: a neck above every pin

The Galton board's pins are fair but not independent: a ball leaving a pin
still moves sideways and goes the same way again two times in three
(`FINDINGS.md`, section 6). The board's first pin is the exception: fed
straight down a narrow neck, it splits the balls 50/50. Could a neck above
every pin make every decision a fresh one? If so, a board of such
splitters would show the mathematics of independent fair coins exactly,
and with different walls it could show more than the binomial (gambler's
ruin, first passage, the reflection principle). This is the test, in bpp,
before any bay is designed around it.

## The test bed

`splitter-test.lua`, run on its own (not in the hall). Rows of "teeth":
each a 4 mm pin on top of a solid wedge whose sides slope down (60 degrees)
into vertical necks; each neck drops a ball onto the pin below, half a
pitch to the side, its foot 8 mm above that pin's centre (as the board's
neck). The same balls (6 mm steel), plates (a 7 mm gap) and contacts
(bounce 0.4, friction 0.3) as the Galton board. Balls are fed one at a time
down a neck onto the first pin, with a random offset of up to 0.3 mm; each
ball's path is recorded in the board's format and measured with
`paths.py`. Eight rows.

    SP_PATHS=/tmp/sp.txt SP_BALLS=600 bpp -f splitter-test.lua -n 24000
    python3 paths.py /tmp/sp.txt

Sizes and contacts are set from the environment (`SP_S` the pitch,
`SP_NECK_W`, `SP_NECK_L`, `SP_SLOPE`, `SP_BOUNCE`, `SP_FRICTION`, ...).
Over 70,000 balls went through the plain necks in all the runs below; none
stopped.

## The first try: the memory moved into the neck

At a 20 mm pitch with necks 8 mm wide and 12 mm long, the balls went the
same way 72% of the time, worse than the lattice. Logging how balls leave
a neck (`SP_LOG=1`) showed why: a ball crosses the neck, meets the far wall
and stays nearer it, leaving 0.4 mm off centre on the side it was heading
to (78% of the time). The next pin sees it off-centre on that side.

But each part of the shape pushes the memory one way or the other (300
balls each; P(same) is the chance of going the same way as at the last
pin, 0.5 for fair coins):

| at a 20 mm pitch | P(same) | correlation 1 row apart |
|---|---|---|
| necks 8 wide, 12 long (the first try) | 0.72 | +0.44 |
| necks 6.6 wide | 0.41 | -0.19 |
| necks 7 wide | 0.26 | -0.49 |
| necks 10 wide | 0.80 | +0.61 |
| necks 4 long | 0.99 | +0.98 |
| necks 24 long | 0.34 | -0.32 |
| sides 45 degrees | 0.72 | +0.43 |
| sides 75 degrees | 0.29 | -0.41 |
| bounce 0.7 | 0.43 | -0.15 |
| bounce 0.1 | 1.00 | +1.00 |
| friction 0.05 | 0.48 | -0.05 |
| pitch 30 mm | 0.52 | +0.05 |

Narrow or long necks and steep sides make a ball turn back; wide or short
necks and a dead ball make it go on. (It looks as if the number of times a
ball crosses the neck decides the sign, odd or even; not checked.)

## A 30 mm pitch: as good as independent, at its design point

The longer slopes bring a ball to the neck faster, to cross it more. With
1,000 balls each:

| at a 30 mm pitch | P(same) | correlation 1, 2, 3 rows apart | spread (8 fair coins: 1.414) |
|---|---|---|---|
| necks 8 wide, 12 long | 0.53 | +0.07, +0.01, -0.02 | 1.47 |
| necks 10 long | **0.49** | **-0.01, 0.00, +0.01** | **1.43** |
| necks 15 long | 0.51 | +0.01, +0.01, +0.01 | 1.46 |
| necks 7.5 wide | 0.50 | +0.01, +0.04, 0.00 | 1.46 |
| necks 8.5 wide | 0.54 | +0.08, +0.01, 0.00 | 1.49 |
| sides 55 degrees | 0.42 | -0.17, +0.06, -0.03 | 1.26 |
| sides 65 degrees | 0.40 | -0.20, +0.04, +0.01 | 1.21 |
| friction 0.2 | 0.55 | +0.09, +0.02, -0.02 | 1.55 |
| friction 0.45 | 0.43 | -0.15, +0.01, -0.01 | 1.24 |
| bounce 0.3 | 0.69 | +0.39, +0.18, +0.07 | 2.05 |
| bounce 0.5 | 0.42 | -0.16, +0.01, +0.02 | 1.24 |
| pitch 40 mm | 0.38 | -0.24, +0.04, -0.02 | 1.11 |

(The correlations' uncertainty is about 0.01.) With necks 10 mm long the
decisions cannot be told from fair, independent coins: P(same) 0.494, no
correlation at any distance, the spread 1.43 against 1.414. That is the
default of the test bed now.

- **Where the memory is small, it is one pin deep.** Two and three rows
  apart the correlations are within 0.06 in all these, against -0.21 on
  the lattice: what a splitter remembers is which way the ball came in.
  (Where the memory is strong, as at a bounce of 0.3 with short necks, it
  reaches two rows: below.)
- **The shape is forgiving:** a millimetre on the necks' width or length
  keeps P(same) within 0.49 to 0.54.
- **The bounce is not:** 0.3 gives 0.69, 0.5 gives 0.42. The slope (55 or
  65 degrees) and the friction matter about as much.

## Longer, narrower necks: less sensitive, but taller

With more crossings in a neck the memory should average out. P(same), 600
balls each:

| | bounce 0.25 | 0.4 | 0.55 | row to row |
|---|---|---|---|---|
| pitch 30, necks 8 wide, 12 long | 0.69 (at 0.3) | 0.53 | 0.42 (at 0.5) | 39 mm |
| pitch 30, necks 8 wide, 24 long | 0.66 | 0.55 | 0.63 | 51 mm |
| pitch 30, necks 8 wide, 36 long | 0.59 | 0.47 | 0.65 | 63 mm |
| pitch 30, necks 7 wide, 24 long | 0.64 | 0.48 | 0.64 | 51 mm |
| **pitch 30, necks 7 wide, 36 long** | **0.42** | **0.53** | **0.44** | 63 mm |
| pitch 40, necks 8 wide, 24 long | 0.54 | 0.61 | 0.69 | 59 mm |
| pitch 24, necks 8 wide, 36 long | 0.78 | 0.38 | 0.53 | 54 mm |

Over bounces of 0.25 to 0.55, the best (necks 7 mm wide and 36 mm long)
stays within 0.42 to 0.53, against 0.42 to 0.69 for the short necks. It
helps, but does not take the bounce out, and twelve rows of it would stand
0.76 m tall (the board's pins take 0.13 m).

## Taking the bounce out: three tries

**Mixing chambers.** Partway down the neck it widens around a small post
and narrows again: a little coin flip whose result is thrown away,
mirror-symmetric so it cannot favour a side. Short chambers (4 mm) trap
balls between the post and the narrowing wall. Longer ones pass them but
are worse at a low bounce: at 0.25 the balls turned back 86 to 90% of the
time. Every mixer in a vertical neck changes how many times a ball
crosses, which is what the bounce already does.

**Leaning necks.** Lean the neck, and gravity holds a ball on its lower
wall: it rolls out the same way whichever side it came in from, the
bouncing damped instead of counted. The pin then goes where the ball
lands, and the lean changes side row by row, so what one row favours the
next undoes. It erased too much: the balls left the neck so alike that the
pin became a knife-edge again (1 mm of the pin's place took a row from 98%
one way to 96% the other), and at the balance point the little that still
varied was the part that remembered: memory +0.75. A splitter needs plenty
of randomness beside what it remembers; erasing the memory is no use if
the randomness goes with it. The vertical neck's crossings are what give
it that randomness, and why the bounce matters.

**A corner.** Building the wedges from two convex slices instead of one
puts a seam where the slope meets the neck, at the corner a ball rolls
over into the neck. Nothing else changes, but at a 30 mm pitch and 10 mm
necks the memory moved from -0.01 to +0.12 (1,000 balls each, both
reproducible to the ball). How a ball meets that corner matters that much.
A printed corner (its radius, the layer lines, wear) will not be what any
simulation assumed, so no simulation can say a printed splitter's memory
to better than about 0.15.

(The memory here is `paths.py`'s row-by-row measure: P(right | right at
the last pin) - P(right | left at it), averaged over the rows. It is 0 for
independent pins even where a pin favours a side, which a pooled
correlation would mistake for memory.)

## Tuning instead: the necks' length for the bounce

So the splitters have to be tuned on the board that is built: necks as
inserts in two or three lengths, swapped until the balls stop favouring
"the same way" or "back". As a starting point, the memory and the spread
(8 rows; fair coins 1.414) at a 30 mm pitch with necks 8 mm wide, 800 balls
each (the memory's uncertainty about 0.03):

| bounce | necks 6 | 8 | 10 | 12 | 14 | 17 | 20 mm |
|---|---|---|---|---|---|---|---|
| 0.3 | +0.56, 2.46 | +0.57, 2.47 | +0.39, 2.05 | +0.38, 2.04 | +0.37, 2.06 | +0.17, 1.58 | **+0.06, 1.56** |
| 0.4 | +0.36, 1.97 | **+0.03, 1.44** | **-0.02, 1.41** | **+0.07, 1.46** | -0.20, 1.20 | -0.09, 1.36 | -0.27, 1.14 |
| 0.5 | -0.30, 1.09 | -0.44, 0.95 | -0.33, 1.06 | -0.16, 1.26 | -0.12, 1.32 | **0.00, 1.39** | **-0.02, 1.39** |
| 0.6 | -0.25, 1.08 | -0.36, 1.02 | **-0.03, 1.36** | +0.06, 1.53 | +0.09, 1.58 | +0.24, 1.79 | +0.27, 1.82 |

Every bounce tried has a length near nothing, but they do not follow in
order (0.4 wants 10 mm, 0.5 wants 17, 0.6 wants 10 again), and with the
seam at the corner the table moves by up to 0.15 (at 0.3 no length came
under +0.4). Where the memory is strong it reaches two rows (at 0.3 with
6 mm necks, +0.37 two rows apart). The table says where to start; the
board says where to stop.

## Teeth of one height: tuning without moving the rows

The table above changes the rows' spacing with the neck. A printed board
needs its rows fixed, so the part to swap is the whole printed tooth (the
wedge and its neck walls, keyed onto its steel pin), in variants of one
height: 29 mm from the pin's centre to the necks' foot, the slope taking
what the neck leaves (`SP_TOTAL=29.05`). Rows stay 37 mm apart whatever the
teeth. Memory, spread (8 rows; fair 1.414) and the correlation two rows
apart, 800 balls each:

| bounce | neck 4 (66°) | 6 (64°) | 8 (62°) | 10 (60°) | 12 (57°) | 14 (54°) | 16 (50°) | 18 (45°) | 20 (39°) | 22 (35°) | 24 (30°) |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 0.3 | +0.84, 3.23 | +0.50, 2.19 | +0.62, 2.52 | +0.41, 2.02 | +0.41, 2.01 | +0.31, 1.95 | +0.36, 1.93 | +0.15, 1.65 | **0.00, 1.50** | +0.36, 1.87 | +0.37, 1.98 |
| 0.4 | +0.53, 2.32 | -0.24, 1.12 | +0.09, 1.52 | **+0.01, 1.48** | +0.11, 1.63 | **+0.02, 1.46** | +0.22, 1.68 | +0.24, 1.73 | +0.13, 1.51 | +0.12, 1.51 | +0.06, 1.50 |
| 0.5 | -0.29, 1.12 | -0.32, 0.97 | -0.26, 1.11 | -0.30, 1.13 | **-0.07, 1.37** | +0.09, 1.49 | +0.07, 1.53 | +0.28, 1.75 | | | |
| 0.6 | -0.44, 0.93 | -0.18, 1.23 | -0.34, 0.99 | **-0.04, 1.32** | +0.08, 1.57 | +0.21, 1.61 | +0.22, 1.74 | +0.33, 1.87 | | | |

(Two rows apart the correlation stays under 0.08 wherever the memory is
under 0.3.) The 12 mm tooth with friction 0.2 or 0.45 instead of 0.3, at a
bounce of 0.4: -0.17 and +0.10; at 0.5: -0.08 and +0.05.

- **Every bounce has a tooth near nothing,** within 0.07: 0.3 the 20 mm
  neck, 0.4 the 10 mm (or 14), 0.5 the 12 mm, 0.6 the 10 mm.
- **Neighbours can differ wildly** (at 0.3: 20 mm 0.00, 22 mm +0.36), as
  the corner predicted. The tuning is by trial, not by reading between
  rows of the table.
- **The friction moves it about as much as a step of bounce,** so the
  choice is made on the board, not from the table.

So a splitter board comes with four sets of teeth: necks of 10, 12, 14 and
20 mm. Start from the measured bounce (the set the table marks), pour a few
hundred balls, and compare the pile's spread with the binomial's (engraved
in the bins): with a memory m the spread is about sqrt((1+m)/(1-m)) times
the binomial's, so 10% too wide is about +0.1 and 10% too narrow about
-0.1. A pile of 300 balls measures the spread to about 4%. Try the next set
the table suggests, and keep the one closest.

## A swallowing wall: first passage and the reflection principle

On a board, a swallowing wall is an exit in place of one column's necks: a
ball reaching that column drops through a hole into its own tube, one tube
for each row it can be caught at. Every pin a ball meets on the way is an
ordinary splitter. So the test is whether tuned splitters give the exact
mathematics. `splitter-test.lua` takes `SP_WALL_L` and `SP_WALL_R` (places
from the start; the row each ball is caught at goes to `SP_CAUGHT`), and
`walls.py` compares the counts with the formulas:

- a ball is first caught after n rows with probability
  (a/n) C(n, (n+a)/2) / 2^n, for a wall a places away (first passage);
- a survivor of all N rows ends at place u with probability
  [C(N, (N+u)/2) - C(N, (N+u+2a)/2)] / 2^N (the reflection principle: the
  paths that touched the wall pair off with the mirror images of paths
  ending at -2a-u).

Twelve rows, a wall 2 places to the left of the start, 3,000 balls, at a
bounce of 0.4 (expected counts in brackets):

| teeth | caught at row 2, 4, 6, 8, 10, 12 | survivors at place 0, 2, 4, 6, 8, 10+ | chi-square (12 df; 1% level 26.2) |
|---|---|---|---|
| tuned (10 mm necks, memory +0.01) | 720, 368, 233, 176, 128, 86 (750, 375, 234, 164, 123, 97) | 321, 402, 332, 168, 60, 6 (314, 419, 314, 152, 48, 10) | **11.9** |
| mistuned (4 mm necks, memory +0.53) | 1182, 255, 160, 128, 109, 74 | 134, 193, 217, 182, 176, 190 | 9,927 |

With tuned teeth the board gives first passage and the reflection
principle as the formulas do. Mistuned, it is plain at the first tube: the
first two pins go together, so 1,182 balls are caught at row 2 instead of
750, and the survivors spread to the far side. No ball stopped.

For the exhibit, with 150 balls a run, a wall 2 places from the start
fills the tubes with about 37, 19, 12, 8, 6 and 5 balls (a long thin tail:
the average time to be caught is infinite), and about 63 balls survive,
piled away from the wall (16, 21, 16, 8, 2). A wall 3 places away: 19, 14,
11, 8, 7, and 92 survivors.

## What it means

- A neck above every pin can cut the memory to nothing, but only at a
  shape that suits the bounce, and how a ball meets the neck's mouth moves
  that shape. No passive mixer tried (chambers, a lean) took the bounce out.
- So a splitter board is to be tuned as built: four sets of teeth of one
  height (necks of 10, 12, 14 and 20 mm), the bounce measured first
  (`FINDINGS.md` section 5) to choose where to start. Watching a few hundred balls
  with `GB_PATHS`-style counting, or simply the spread of the pile against
  its engraved curve, says which way to go: too wide, the balls keep on
  (longer or shorter necks, by the table); too narrow, they turn back.
- With teeth of one height the rows are 37 mm apart whatever the set:
  twelve rows in 0.45 m.
- Nothing jammed in the plain necks (over 70,000 balls in all), though
  the balls came one at a time; a full feed is still to try.
