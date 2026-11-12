# The Galton board: findings

`FINDINGS.pdf` beside this file is a typeset copy of it.

How the board came to be as it is, and what was measured. MACHINES.md had
it as "balls and pins only; easy". The pins were easy enough; getting the
balls in was not. Unless said, every run was at 2400 steps a second and 20
solver passes, 150 balls of 6 mm, bounce (restitution, ball on board) 0.4,
friction (ball on board) 0.3. "Mean" is the mean bin (6 for fair coins),
"spread" the standard deviation (1.73 for fair coins). With 150 balls one
run's mean scatters by about 0.15 to 0.2 from run to run, its spread by
about 0.1.

## 1. The pitch of the pins

A ball must pass between two pins of a row, but the triangular lattice also
has straight diagonals, and if those are wider than a ball, a ball moving a
little sideways runs down one touching nothing. The first board (pins 3 mm,
13 mm apart, its diagonals 8.3 mm) did exactly that: traced, the first balls
went from the neck to the outermost bins in straight lines. With 4 mm pins
the window is narrow: between neighbours S - 4 must be more than 6, along a
diagonal S sin 60 - 4 less than 6 or not much more.

Dropping the balls one at a time, 4 mm above the first pin (a random 2 to
4 mm either side), 150 balls:

| pitch | between pins | diagonal | mean | spread |
|---|---|---|---|---|
| 11 mm (4 mm pins) | 7.0 mm | 5.5 mm | 6.05 | 1.42 |
| 12 mm (4 mm pins) | 8.0 mm | 6.4 mm | 6.21 | 1.73 |
| 13 mm (3 mm pins) | 10.0 mm | 8.3 mm | 5.80 | 2.72 |

At 11 mm the balls zigzag (alternate bins are favoured: each choice undoes
the last a little), at 13 mm they jump pins. 12 mm gives the binomial's own
spread, and is the board's.

## 2. The side walls

The side walls of the pins run where the next pin out would be. As smooth
60-degree walls they were ramps: a ball reaching one slid down it,
squeezing past the outermost pins through a gap 0.5 mm narrower than
itself (Bullet's soft contacts let a fast ball through a small overlap). So
the walls have **half pins** standing out of them where those pins would be:
a ball at the edge meets a pin head on.

A pin a little more than a ball's radius from a wall **cradles** a ball: one
came to rest on the outermost pin of the 11th row, against the bins' wall
(the pin's surface 3.2 mm from the wall: too little to pass, enough to sit
on). A ball can't rest on a half pin, which pushes it away from the wall. So
a pin that would leave less than a ball's width and a millimetre beside a
wall is left out, and the wall has a half pin there; the bins' straight
walls have one at every row.

## 3. Getting the balls in: a neck jams

Galton boards empty a hopper through a neck. Between two plates 7 mm apart
the balls are a two-dimensional pile, and such piles clog:

- **A neck three balls wide** (18 mm), the first pin just under it: it jammed
  after two balls, every time. A ball came to rest on top of the first pin,
  held there by the balls pressing on it, and plugged the neck.
- **A straight throat** under the funnel, so that a ball perched on the pin
  leaves room beside it: it jammed after three, an arch across the throat's
  top standing on the perched ball. A taller throat (18 mm): 27 balls, then
  a zigzag column in the throat, standing on a perched ball that had rolled
  a little off centre, against a wall.
- **An obstacle above the neck** (as in Zuriguel and others' experiments with
  silos, 2011, it takes the weight off the arch): 19 balls before a jam
  instead of 2. Better, not cured.
- **Tapping**: the operator rocks the board a little whenever no ball has come
  through for 0.4 s. At 1.5 degrees it did nothing; at 4 degrees, alternating
  and growing while it stayed stuck, 102 balls and then a jam no tap
  cleared; and the taps threw the balls about and widened the spread.
- **A neck five balls wide** (30 mm, the lattice starting with three pins so
  that it fits): no clog at the neck, but the balls came so fast that they
  piled on the first row, whose 7 mm gaps arched over like a grate.
- **Wider gaps** (pins 13 mm apart): the balls flowed (150 in 2 s), but
  crowded together they knocked each other sideways and the bins came out
  nearly flat (a spread of 3.4).

So a crowd of balls spreads far wider than one ball does. On the same board,
one ball at a time dropped low over the first pin: a spread of 1.78; from
the bottom of a throat, as wide as the stream: 2.08; as a crowd from a wide
neck: 2.68. The board needs its balls one at a time, and a neck can't do
that without jamming.

**The metering wheel** can. Six slots in a wheel 32 mm across, under the
hopper, turned by a crank: each slot picks up one ball from the bottom of
the pile and carries it round under its housing (2 mm clear of the wheel: a
slotted ball passes, a loose one can't get in). The hopper's downstream wall
meets the wheel square on, so it scrapes off any ball half in a slot rather
than pinching it. Five or six balls a turn; at one turn a second, 150 balls
in 27 seconds. In every run here (over forty) it never jammed, and the hand
never had to turn it back.

## 4. The first pin wasn't a coin

The wheel hands every ball on in the same way, and that was the next
trouble.

- **Dropped straight from the slot** onto the first pin: the slot is moving
  left at the bottom of its turn (9 cm/s), and the board leant left (mean
  5.60).
- **Through a straight chute** (7.2 mm, a ball and 1.2 mm): each ball bounced
  once off the chute's left wall and left it moving right at 3 cm/s, and
  nearly every one went right at the first pin (means 6.53 and 6.49). With
  the chute 1.5 mm to the left, every one counted went left (5.27). A wider
  chute: all left (4.89). (With the chute 3 mm to the left, and with one
  only 0.6 mm wider than a ball, the runs stopped with a ball stuck
  somewhere; not traced.) The first pin was not a coin but a switch, set by
  the chute.
- **A funnel** (18 mm at its mouth, 8 mm at its neck): the balls bounce
  between its walls a few times, and the bounces make the most of the small
  differences between one ball and the next (where it sat in its slot). The
  first pin sent 47% of the balls counted to the left; over six runs the
  mean was 6.08 and the spread 1.95. But the balls still left it moving left,
  5.4 cm/s on average, and how that came out at the first pin depended on
  the friction: at 0.15, 80% went left (means 5.19 to 5.65); at 0.45, two
  thirds went right (6.22 to 6.35).
- **A funnel and a straight neck** under it (8 mm wide, 8 mm long): the
  balls leave the neck at 0 plus or minus 1 cm/s, and the board cares less
  about the friction (section 5). This is the board's. Over six runs at the
  usual friction the means were 6.09 to 6.45 (6.31 on average) and the
  spreads 1.91 to 2.12 (2.03): it leans about a third of a bin to the right.
  Which way it leans, and how far, depends most on the bounce (section 5).
  Probably spin: the balls roll down the funnel's left wall into the neck,
  and a ball spinning that way kicks off the pin under it; not measured.
  That is a real board's kind of fault, and it is left as it is: moving the
  neck a little to one side would cancel it here, but only for the bounce
  and friction guessed.

The tour checks each run: every ball in a bin, the mean within 0.6 of 6, the
spread between 1.4 and 2.6.

## 5. Bounce, friction and speed

The finished board, each setting changed alone (three runs each; six at
the usual settings):

| setting | means | spreads | tour |
|---|---|---|---|
| usual (bounce 0.4, friction 0.3, crank 1 turn a second) | 6.09, 6.25, 6.31, 6.35, 6.41, 6.45 | 1.91 to 2.12 | pass |
| bounce 0.3 | 5.33, 5.54, 5.69 | 1.96 to 1.99 | fail (leans left) |
| bounce 0.55 | 6.07, 6.22, 6.51 | 2.44 to 2.50 | pass |
| bounce 0.7 | 6.05, 6.18, 6.42 | 2.39 to 2.44 | pass |
| friction 0.15 | 5.51, 5.93, 6.10 | 2.09 to 2.16 | pass |
| friction 0.45 | 6.09, 6.11, 6.18 | 1.80 to 1.89 | pass |
| crank 0.5 turn a second | 6.17, 6.33 | 2.05 to 2.10 | (the third run ran out of frames) |
| crank 1.5 turns a second | 5.48 | 1.64 | (the second run did not finish in the frames allowed; not traced) |

So the bounce sets the spread (2.0 at 0.4, 2.45 above 0.5) and, with the
crank's speed, which way the board leans. At 1.5 turns a second the balls
come too close together for the funnel and neck to settle each one (they
left the neck moving left at 6.8 cm/s) and the board leant left: keep the
crank to a turn a second or less. In every run that finished every ball reached a bin,
and the crank was never turned back.

The bounce is the number least known. No published coefficient of
restitution for a steel ball on printed PLA at these speeds (a few tenths
of a metre a second) was found; 0.4 is a guess. It is easy to measure: drop
a ball from 100 mm onto a printed tile lying on a hard table, and see how
high it comes back (a phone filming against a ruler); the bounce is the
square root of that height over 100 mm. The board's fairness depends on it:
below about 0.3, the funnel stops making the first pin a fair coin.

## 6. Settling, and resting

The balls low in a tall stack (36 balls in the middle bin) jitter at 5 or 6
cm/s at 20 solver passes: the solver's, not a movement (60 passes bring it
down to 1). Rather than pay three times the passes, a ball counts as still
under 8 cm/s; the run is over when the hopper is empty, nothing is on its
way and everything has been still for half a second. The exhibit then
rests (stops stepping) until the next key.

## 7. How fast it runs

While the balls are running, about 2.5 s of computing a simulated second
here (headless, on one core); the tour, two runs with the emptying and
pouring between, about two and a half minutes. At rest, nothing.

## 8. The printed parts

- Three tiles, each under 200 mm (166 x 200, 195 and 194 mm), joined by
  splices glued across the back.
- Every STL is one watertight solid, and the parts at rest don't overlap
  (every pair of the board, wheel, slide, drawer, front sheet, crank and
  stand: checked with manifold3d).
- Found on the way: where an outline only touched a circle that is cut as
  well (the wheel's recess), OpenSCAD left slivers, the extruded walls "were
  not closed", and a whole tile's walls went missing, in an STL that was
  still watertight (only the back plate was left). Each tile's thickness is
  checked now, and the outlines for crossing themselves. The drawer's bay
  and the slide's slot were first cut only halfway across: the overlap check
  found it.
