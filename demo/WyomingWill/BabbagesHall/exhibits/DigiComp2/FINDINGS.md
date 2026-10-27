# The Digi-Comp II: what the simulation showed

`FINDINGS.pdf` beside this file is a typeset copy of it.

1/2 inch steel balls (12.7 mm, 8.35 g), PLA parts, friction 0.3, no
bounce, the board at 15 degrees, 2400 steps a second, the pins' friction
0.4 kg cm^2/s^2, unless a line says otherwise. Each mechanism was worked out
alone first, in `tests/`, then on the board, with its tour.

## Step 2b: adding and multiplying

### Laying it out

Thirteen flip-flops, seven switches and the lanes between them have to fit
on one level, and lanes cannot cross there (a ball can go down to the lower
level, never back up). The board was laid out in a plan drawn from the
geometry (every wall, hole and peg, the lanes coloured by kind) and changed
until nothing touched. These settled most of it:

- **The order of the memory.** The memory's switches stand beside A1 to
  A4, down the accumulator's staircase, so the lanes reaching them, from
  above and the left, must keep their order: the leftmost of the
  distributor's four outlets can only go to the lowest, M4. So D2's left
  goes to the MQ and on to M4, D2's right to M3, D3's left to M2, D3's
  right to M1, and with the distributor set to start, the balls of a cycle
  go to the MQ (and M4), M1, M3, M2. The manual's order after the MQ is M2,
  M3, M1; the sum is the same.
- **The distributor is a tree,** not the original's ring: D1 sends the
  balls to D2 and D3 by turns, each of them by turns to its two sides.
  D2 is where the next step of a staircase would be, so D1's left drops
  straight into its funnel, and D2's left straight into MQ1's; D1's right,
  and every other outlet, falls into a **catch** (a funnel where the next
  flip-flop's would be) and runs on down a lane. D3 must stand far enough
  from D2 that D2's right catch and D3's left don't overlap (8 cm right of
  D1), and low enough that the lane to it falls steeply enough (14.2 cm
  below D1).
- **Lanes** fall at least 35 degrees from across the board (the geometry
  warns of any that don't); the flattest, D1's to D3, falls 39 degrees.
  The longest are MULTIPLY's down to CLEAR and D2's to M3, 27 cm each.

The board grew from 322 x 878 to 424 x 1216 mm (14 tiles a level), and its
table from 100 x 150 to 110 x 180 cm.

### Two ways into one funnel

A1 to A4 each take balls from two places: the carry from the flip-flop
above (or COUNT, for A1) and the memory. The carry was traced first
(a copy of `tests/toggle.lua` printing the ball's centre every 1/60 s): it leaves the cup
moving 11 cm/s across and crosses the next funnel's mouth 4 mm left of its
centre, so its left half is not free for a lane ending over it. Instead
each of these funnels has a **long left wall**, out 35 mm and up 15.7 mm
(31 degrees), and the memory's outlet ends over that wall, 26 mm left of
the throat: its ball drops onto the wall and rolls down it into the throat,
beside the carry's path, not across it (`tests/junction.lua`: the carry and
the memory's balls in turn, nine of nine right).

- **Under the lane's end.** With the outlet ending 19.7 mm above the
  throat, the memory's ball stuck at once: rolling down the long wall, it
  had to pass under the end of the outlet's own right-hand wall, which left
  8 mm. It ends 28 mm above the throat now. The MQ's done balls join the
  same way (a long right wall under MQ2's and MQ3's catches, mirrored), and
  stuck there the same way, first.
- **COUNT** at first ended over the right half of A1's funnel; its ball
  stuck under its own outlet's left wall, as the memory's had. Centred over
  the throat, it worked, but with the pins' friction at 2 or 3 A1 stopped
  near the middle (+4 to +6 degrees) after the first ball, and the next
  went the wrong way: the ball has run 40 cm down from MULTIPLY, and came
  into the top of A1's run at 34 cm/s (the toggle test's ball starts there
  at rest). A1's
  funnel has a long right wall too now, and COUNT's outlet ends over it as
  the memory's do over the left: the ball drops onto the wall and rolls in
  slowly.
- **The clear lane** starts at CLEAR's drop, right of COUNT now, and bends
  left at once to pass where COUNT's off balls land. Coming down straight
  to A1's foot, the clear ball was pushed by the narrowing past its line
  into A1's wedge (at 0), and with the pins' friction at 0.1 its rubbing
  dragged A1 over to 1. The lane now overshoots to the left and comes back
  a little to the right, so the ball meets the foot running along the
  right wall, as at every other foot.

### The memory's switches

The same switches as CLEAR and COUNT, but a 0 has to drop the ball before
it can reach the next switch's inlet, only 5 cm below: so the "0" outlet
ends at once in a hole just under the flap's pin, its walls round it. The
first one stood the hole's inner wall where the divider's slope begins:
the ball rested on its end, beside the flap. The wall now begins where the
divider's slope ends. A ball dropped there rolls down a wall on the lower
level (40 degrees) to the **return lane** down the left edge, and on to
the collector, away from the clear lane.

### The MQ

Three flip-flops down a staircase like the accumulator's, read the other
way: a ball that finds one at 1 (apex left, as it is lettered) sets it to 0
and leaves to the right (done); one that finds it at 0 sets it to 1 and
goes on to the next (the borrow). So each ball takes one away, the same
parts as the accumulator adding one. A borrow out of MQ3, when the MQ was 0,
drops through STOP: the hand watches it (as you watch the machine in
MANUAL) and turns no more. The done balls of MQ1, MQ2 and MQ3 run together
through the catches under MQ2 and MQ3 (each takes the lane from the one
before on its long right wall) and on to M4.

### On the board

The tour (README.md): COUNT 0 to 2, CLEAR, ADD 37 + 11 (five balls: 48,
then STOP), CLEAR, MULTIPLY 13 x 3 (thirteen balls: 39, then STOP),
twenty-two balls. After each ball it checks the accumulator, the MQ, the
three distributor flip-flops and STOP against what one more ball should
make of them, and that the ball reached the collector. The hand puts balls
from the collector back into the input when fewer than four are waiting. It
passed in every one of these:

- friction 0.1, 0.3, 0.6
- pin friction 0.1, 0.4, 1, 2, 3
- slope 12, 15, 20, 25 degrees
- tilted across 1 and 2 degrees either way
- 1200, 2400, 4800 steps a second
- the hand's torque on the knob 30, 50, 1000 kg cm^2/s^2

(eighteen runs, each the whole tour). Before the two changes to A1 above
(COUNT onto a long wall, and the clear lane's bend), pin friction 0.1, 2
and 3 failed there; the others tried then (friction 0.1 and 0.6, 1200 and
4800 steps, the hand's torque 30 and 1000, slope 25, tilted 2 degrees)
passed. `tests/junction.lua` passed (nine of nine) at friction 0.1 and 0.6, pin friction 0.1 and 3,
and slopes 12 and 25 degrees.

The computing was right the first time the balls could get through: the
distributor, the MQ and the memory gave 48 and 39 once the three places
above (the two funnels and the memory's hole) let the balls by.

### The printed parts

Every STL (`make-stls.sh`: 14 upper and 14 lower tiles now, 212 mm across)
is one watertight solid. Put where they are at rest, no two parts overlap
but each foot's stem in its rocker's socket (0.3 mm^3, where they are
glued), for all thirteen flip-flops and seven flaps.

### Showing where the ball will go

Before each ball the exhibit works out, from what the rockers and switches
read, the way the ball will take and what it will do, draws the way as a
yellow dashed line on the board (360 short dashes, all alike, moved into
place) and says it on the sign (THIS BALL). It is the same reckoning the
tour checks each ball against (the accumulator, the MQ, the distributor
and STOP after every ball), so a tour that passes did what the line and
the sign said, ball by ball.

### What it costs

About 430 fixed boxes (320 walls, the plate round its holes, the pegs
and posts), twelve balls, thirteen rockers, seven flaps and the wheel. The
tour, about 215 simulated seconds (each ball's way is shown for 1.5 s
before it goes), took about four minutes of computing headless here (twice the rockers and twice the length of 2a's);
between balls, and when it is done, the exhibit rests and costs nearly
nothing.

## Step 2a: the accumulator

### Two levels

E.S.R.'s board has two levels, and so has this one: the upper plate (4 mm)
on which the balls compute, and under it the lower level, 15.2 mm high (a
ball and 2.5 mm), which takes every ball that is done down to the
collector, under everything else. It is what makes a seven-bit accumulator
fit: step 1's done lanes each needed a strip of board down to the bins, and
seven of them would not have fitted beside the staircase.

- **Done holes.** A ball tipped out of a rocker's right cup drops through a
  14.5 mm hole 31 mm right of and 13 mm below the pin, a wall beyond it and
  below it so it can't run past. With the hole 1.5 mm further out, the
  flip-flop's test failed at friction 0.6 and at pin friction 3.
- **The collector's wall** is past the end of the plate, with nothing over
  it. At 15.2 mm high, a ball that had rolled the length of the lower level
  at a slope of 22 degrees or more jumped it and left the board. It is 30 mm
  high.
- **The collector** first sloped down to the left: the balls lined up from
  the left end, over the end of the clear lane, and the ninth ball blocked
  it, so the tenth stopped in the lane. It slopes down to the right now
  (2 cm across the board), away from the clear lane and the overflow, and
  the clear lane ends 35 mm short of its wall, so a ball coming out of it
  can turn and roll along the wall (ending 10 mm short, two balls were
  trapped between the lane's end and the wall).
- **The input channel** holds ten balls (13.5 cm); a ball placed past its
  end fell off the board.

### The flip-flop's foot: CLEAR

The original clears its accumulator with a ball on the lower level. Here
each rocker has a **foot** on the lower level, joined to it by a stem
through a square hole in the plate: an arm 20 mm up the slope from the pin
(down the slope, its weight would have made the rocker hang like a
pendulum instead of falling over to one side: tried first, it did), ending
in a wedge that leans right when the rocker reads 1. A ball coming down the
**clear lane** beside it meets the wedge's sloping face and pushes it left,
which is the way that turns the rocker to 0. With the foot, the whole
flip-flop weighs 5.45 g (rocker 2.5 g, foot 1.9 g, steel ball 1.0 g), its
centre of mass 4.4 mm up the slope from the pin: the foot up the slope
makes its two leanings deeper than step 1's rocker's (2.4 mm).

- **Pushed part way.** At first the lane was straight, and the ball pushed
  the wedge only until it could squeeze past it. That left the rocker a
  little past the middle, where its weight hardly turns it and the pin's
  friction holds it: at friction 0.6 it stopped at +3 degrees, still
  reading 1, four times in eleven. And the lane had to be placed within a
  millimetre either way (13.5 to 15.5 mm right of the pin both failed).
- **The narrowing.** Now the lane's right wall comes in beside the foot, so
  the ball passes the wedge with its left side 0.5 mm clear of where the
  wedge is when the rocker is at 0 against its stop. A ball that meets a
  wedge at 1 must push it all the way back to 0 (the rocker then reads -11
  degrees); one that finds it at 0 touches nothing. It works with that gap
  anywhere from 0.2 to 1.5 mm, at friction 0.1 to 0.6 and pin friction 0 to
  4 (`tests/toggle.lua`, eleven or sixteen balls each, from above and down
  the clear lane in turn), and at slopes of 8 to 25 degrees.
- **Corners.** Two places jammed a clear ball, both found with
  `DC_CONTACTS`: the lane's left wall coming back just where the right wall
  narrowed (leaving 12.4 mm for a 12.7 mm ball), and the narrowing starting
  above the bend where the lane from the flip-flop before joins it (its
  corner stood in the lane). The left wall now stays open until past the
  narrowing, and the narrowing starts below the bend. A lane's walls are
  mitred at its bends.

### The switches

A flap 20 mm long and 3 mm thick on a pin at the tip of the divider between
two outlets, its free end against one wall of the inlet. It was right ten
times in ten (set by hand left and right in turn, then a ball) at friction
0.1 and 0.6, pin friction 0 and 2, slopes 8 and 25 degrees, and with the
ball run in from 1 or 15 cm above (`tests/switch.lua`). The divider's tip
must stay 5.5 mm below the flap's pin: at 1.5 mm the flap jammed against it.

### AUTO: the START lever (not built yet)

The original's AUTO lets a ball reaching the bottom release the next from
the top, through the START lever. A long lever on the lower level was
tried, its top end carrying two teeth up through slots into the input
channel (an escapement: one ball out each time the lever is pushed) and
its bottom end a wedge in a trip lane. It failed: round teeth coming in
from the sides of the channel are pushed sideways by the balls they hold,
and with the lever's pin 9 cm away that was enough to hold the lever pushed
(it never came back after the hand let go), and a trip ball let all six
balls out at once. The next design needs teeth whose faces meet the balls
square on, on a lever whose pin is in line with the channel, so the balls'
weight turns it neither way.

### The accumulator on the board

The tour (README.md): COUNT from 0 to 4; 125 to 127 and over to 0, the
carry running through all seven; CLEAR from 90 and from 127; CLEAR at 0;
both switches off. Every reading and every ball's arrival in the collector
checked, eleven balls. It passed in every one of these:

- friction 0.1, 0.2, 0.3, 0.4, 0.5, 0.6
- pin friction 0.1, 0.4, 1, 2, 3 (a quarter of the estimate to seven times it)
- slope 8, 10, 15, 20, 25 degrees (at 8 the tour takes longer)
- tilted across 1 and 2 degrees either way
- 1200, 2400, 4800 steps a second
- the hand's torque on the knob 30, 50, 1000 kg cm^2/s^2

and failed with no pin friction at all (the 1s rocker bounced back off its
stop, on the board though not in its test; any real pin has some), and
tilted 3 degrees across either way (as in step 1, the balls are carried past
the apexes). So: level across within 2 degrees.

### The printed parts

Every STL (`make-stls.sh`) is one watertight solid. Put where they are at
rest (`PART="rest-..."` in `parts/digicomp2.scad`), no two parts overlap but
each foot's stem in its rocker's socket (0.3 mm^3, where they are glued).
The bottom lower tiles first came out with the collector's wall cut off at
the plate's height, and the collector's tall end walls overlapped the
plate's rim; both fixed.

### What it costs

A few hundred fixed boxes (walls, the plate round its holes, pegs, posts),
twelve balls, seven rockers, two flaps and the wheel. The tour, about 90
simulated seconds, took about a minute of computing headless here; the
exhibit rests (stops stepping) whenever nothing has moved for half a
second, so between balls it costs nearly nothing.

## Step 1: the counter (2026-10-26)

Three flip-flops on a one-level board, with lanes to bins for the done
balls. The rocker then had no foot, and `tests/toggle.lua` was the rocker
alone under its channel (it is now the rocker with its foot: see step 2a).


1/2 inch steel balls (12.7 mm, 8.35 g), PLA parts, friction 0.3, no
bounce, the board at 15 degrees, 2400 steps a second, the pins' friction
0.4 kg cm^2/s^2, unless a line says otherwise. The flip-flop was worked out
alone first, with `tests/toggle.lua` (one rocker under its channel, balls let
go one at a time, 16 of them), then in the counter, with its tour (eight
balls from 0, each reading checked).

### The flip-flop

**The idea.** A rocker on a pin whose centre of mass is up the slope from
the pin is over-centre: it falls to one side or the other against a stop and
stays, a bit of memory. Its top is a roof whose apex is up the slope from the
pin, so the apex leans with it. A ball coming straight down meets the roof
beside the apex, on the side that is raised, and its weight on that side
takes the rocker over. So each ball goes the other way from the last. The
first rocker, an inverted V of plain strips, did this sixteen times out of
sixteen at every slope from 6 to 30 degrees and every friction from 0.1 to
0.6, as long as it leaned at least 8 degrees (at 6 degrees the apex moved
too little to choose a side for the ball).

**Cups.** With friction at its pin, the plain roof stopped half way over: the
ball runs off the end of the roof while the rocker is still near the middle,
where its own weight hardly turns it, and the pin's friction holds it there.
The next ball then finds no raised side. At 0.8 kg cm^2/s^2 of pin friction,
14 of 16 balls went the wrong way. A **lip** at each end of the roof makes a
cup, which holds the ball until the rocker has gone over; at the end of the
swing the cup tips it out. With 5 mm lips the rocker worked at four times
that friction. The lips lean out 67 degrees from straight up the slope:

| Lips (lean out) | Counter's tour, under 10 hard conditions |
|---|---|
| none | fails at 0.8 kg cm^2/s^2 of pin friction (the rocker alone) |
| 60 degrees | 8 of 10: a ball stays in a cup when the table is tilted 2 degrees across |
| 67 degrees | 9 of 10: with no pin friction at all, a rocker bounces back from its stop |
| 75 degrees | 9 of 10: the same |
| 3.5 mm long, 67 degrees | 8 of 10: too short to hold the ball over at high pin friction |

(The ten: tilted 1 and 2 degrees across either way, pin friction 0 and 2,
friction 0.1 and 0.6, slope 10 and 20 degrees. These were run with the pin
friction first estimated, 0.25 kg cm^2/s^2, before the steel ball below,
which these rockers did not have.)

**The weight.** The bouncing back is a sign that the rocker's two leanings
are too shallow: its centre of mass was only 1.5 mm up the slope from the
pin, so the dip it rests in is tiny, and a rocker coming hard onto its stop
can rebound right out of it. A **steel ball of 1/4 inch (1.04 g)** pressed
into the rocker under its apex, 5.8 mm up from the pin, moves the centre of
mass to 2.4 mm and makes the dip deep enough: with it and the 67 degree lips,
the counter passed all ten (and so did 1 and 2 g, 5 mm up, tried before it).

**The apex.** The first rockers were built of boxes, and the strut from the
pin to the apex stood 3.5 mm above the roof: the ball landed on its corner
and went either way. The rocker is now built of convex pieces whose upper
edges are the roof's lines exactly, nothing above them (and the printed part
is the same pieces).

**Its numbers.** Roof 32 mm wide at 30 degrees, apex 10 mm up the slope from
the pin, lips 5 mm, strips 3.5 mm, 9 mm high, 1.5 mm off the board on the
pin's boss; it leans 12 degrees either way to its stop pegs. It weighs
2.5 g printed solid, 3.6 g with its steel ball.

**The pin's friction.** The rocker lies on the boss round its pin with its
weight across the board, 3.4 g-force; PLA on PLA (0.3 to 0.4) at the boss's
mean radius (about 2.9 mm) gives about 0.4 kg cm^2/s^2 (0.04 mN m), the
pin itself a tenth of that. The simulation uses 0.4. At that, the rocker's
own weight cannot turn it against the pin when it is near its stop (about
0.03 at 8 degrees), so it stays where the ball leaves it, 8 to 12 degrees
over: that is still far enough for the next ball to choose its side.

**The rocker alone** (`tests/toggle.lua`, 16 balls each; the least lean any
ball left it at):

| | Passed | Least lean |
|---|---|---|
| as built | yes | 9.1 degrees |
| pin friction 0, 1, 2, 4, 5 | yes | 11.6, 11.0, 10.3, 3.8, 0.5 |
| pin friction 6 | **no**: the rocker stops in the middle | 1.3 |
| friction 0.1 to 0.8 | yes | 7.8 to 9.8 |
| slope 6 to 30 degrees | yes | 9.6 to 11.6 |
| run 5, 10, 15 cm longer (faster balls) | yes | 7.6, 6.0, 2.8 |
| run 20 cm longer | **no**: the ball comes too fast and jumps the cup | |
| let go up to 0.75 mm off centre (all the channel allows) | yes | 8.7 |
| tilted across 2 or 3 degrees one way, 2 the other | yes | 7.1 to 10.0 |
| tilted across 3 degrees the other way, or 4 | **no** | |
| 1200 and 4800 steps a second | yes | 8.8, 9.9 |

Tilted across, the ball runs down its channel pressed against the downhill
wall, and the board's sideways pull carries it past the apex onto the low
side, which it then rolls down without turning the rocker. So the board must
be level across: within 2 degrees.

### The counter

**The staircase.** Each flip-flop 3.5 cm left of and 8 cm below the last,
so a carry leaving the left cup falls straight into the next one's funnel;
each done ball leaves the right cup into a lane straight down to the bins.
The lanes' mouths were first 2.4 cm right of the pin: a ball came out of the
cup and stuck, wedged between the rocker's lip and the lane's flared wall
(found with `DC_CONTACTS`). At 2.8 cm they clear.

**The feeder.** A wheel of four notches turning under the channel of
balls. Three things were found:

- A wall's box runs 1.5 mm past its ends (so walls meet solidly), and the
  ends of the channels at the wheel's housing reached into the wheel's path:
  the wheel rubbed them and stuck at friction 0.5. Those channels now start
  2 mm further out.
- The hand must be able to push: seven waiting balls press on the wheel's
  rim. The simulation's hand turns the knob with up to 50 kg cm^2/s^2
  (5 mN m, a light finger); it also passed with 20 and 1000.
- In the first wheel the teeth only touched the hub, which would have
  printed as five pieces: the hub is now 0.5 mm wider than the notches, so
  the wheel is one solid.

**The tour,** eight balls from 0, each reading and each ball's bin checked,
the machine as built (pin friction 0.4), passed in every one of these:

- friction 0.1, 0.2, 0.3, 0.4, 0.5, 0.6
- pin friction 0, 1, 2, 3 (eight times the estimate)
- slope 8, 10, 15, 20, 25 degrees
- 1200, 2400, 4800 steps a second
- tilted across 1 and 2 degrees either way
- friction 0.6 with: tilted 2 degrees either way, slope 10 degrees, pin
  friction 2; friction 0.1 with: tilted 1 degree either way or 2 one way,
  slope 10 degrees, no pin friction
- the hand's torque 20 and 1000

and failed at pin friction 4 (a rocker stopped near the middle), tilted 3
degrees across either way, and at friction 0.1 tilted 2 degrees the other
way. So: level across within 2 degrees, and within 1 to be sure.

### What it costs

Little: eight balls, three rockers and the wheel, against some fifty fixed
walls and pegs. The tour, about 28 simulated seconds, took 7 s of computing
headless here; the exhibit rests (stops stepping) once nothing has moved for
half a second.

### What is idealised

- The knob is turned by the hand: a motor on the wheel's pin, exactly a
  quarter turn at a time. In the machine as built you turn it by its four
  marks (how far off a quarter it may be was not tried).
- The pins are hinges with a constant friction torque.
- Setting it back puts the balls and the rockers in place by hand.
