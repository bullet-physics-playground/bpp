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
About 26,000 balls went through in all the runs below; none stopped.

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

- **The memory is one pin deep.** Wherever P(same) is off, it is off at the
  next pin only: two and three rows apart the correlations are within
  0.06 everywhere, against -0.21 on the lattice. What a splitter remembers
  is only which way the ball came in.
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

## What it means

- A neck above every pin works as hoped in one way: the memory is cut to a
  single pin, and at the right shape it is gone. Nothing jammed, though
  the balls came one at a time.
- To get there on a printed board, the bounce of the real balls on the real
  plastic has to be measured first (`FINDINGS.md` section 5 says how), and
  the necks' length chosen for it: a test print of three or four rows, with
  necks that can be trimmed, would settle it.
- Short necks keep a board of reasonable height (37 mm a row at a 30 mm
  pitch and 10 mm necks: twelve rows in 0.45 m), but need that tuning.
  Long necks are more forgiving and much taller.
- Still to try: a more compact mixer than a long neck (a few staggered
  baffles inside it, say), which might give the long necks' insensitivity
  in less height; and a full feed (balls meeting in the necks).
