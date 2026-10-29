# The Digi-Comp II: what the simulation showed

`FINDINGS.pdf` beside this file is a typeset copy of it.

1/2 inch steel balls (12.7 mm, 8.35 g), PLA parts, friction 0.3, no
bounce, the board at 15 degrees, 2400 steps a second, the pins' friction
0.4 kg cm^2/s^2, unless a line says otherwise. Each mechanism was worked out
alone first, in `tests/`, then on the board, with its tour.

## Step 2d: AUTO (2026-10-28)

### The escapement on the board

The feeder's knob is gone: the wheel is turned by the weight (a torque of
30 kg cm^2/s^2 on its pin, `DC_WEIGHT`) no faster than the fly lets it (3
radians a second, `DC_FLY`), and held by the anchor, as in
`tests/escapement.lua` (step 2a, below). The hand's START is a push on the
anchor's arm for 0.3 s (`DC_PUSH`, 300). On the board it needed:

- **The anchor's stop posts in the simulation** (they had been drawn
  only): without them the anchor, pushed, swung on to 90 degrees.
- **Waiting for the anchor to come home.** A finger sliding off a pin
  brings the anchor back slowly, up to half a second; the simulation had
  come to rest before it was home, and the next ball came one push late.
  The machine now counts as busy until the anchor is within 1.5 degrees of
  rest (or 3 s have passed).
- **Rollers** on the fingers: the anchor's friction is 0, as the test found.

With that the whole library (all MANUAL) passed as before.

### The trip

The collector's wall now stops short of the right-hand side, and every ball
turns down a **trip channel** there, under the trip lever, and on to the
**store** below it (a second wall, sloping down to the left, where the
balls wait for the hand). Getting a ball into the channel took three tries:

- The wall ended 2 mm short of the channel's left wall: the balls went
  down that gap, outside the channel, past the lever.
- It ended over the channel, at its middle: the balls stuck in the corner
  between its end and the rim. Past its end a ball needs its whole width
  clear to the rim (the end and the rim were 7.6 mm apart).
- It ends on the channel's left wall: 14.7 mm to the rim, and every ball
  turns down the channel.

**The lever.** The first lever's arm reached up the slope from its axle,
its end just above a ball's middle, and its post pulled a thread to a crank
on the anchor. A ball arriving under the arm's end never lifted it: it met
the end's corner 1.9 mm over its middle, so the push was 17 degrees above
the board, and below the line from the corner to the axle (34 degrees). It
only pushed the arm down onto its stop, and the ball stopped. The arm now
**trails down the slope** from the axle: a ball rolls under the axle and
meets the arm's underside, which it can only lift. A post up from the axle
then tips *up* the slope as the arm lifts, so it **pushes**: a rod, not a
thread, to the anchor's counterweight arm, extended past the ball, 35 mm
from the pin. Pushed up the slope there, the anchor trips. (The rod is
gone now: the lever pulls a thread, try 6 below.)

Measured on the board, with the rod nearly weightless (0.3 g, the first
try): a ball lifts the lever 0.34 to 0.35 radians (0.38 once); through the
rod that takes the anchor from -7.9 to +5.0 degrees of its -7.9 to +7.9
degree swing, 82% of it. That was enough: the second finger catches the
next pin, and every trip let out exactly one ball.

**The rod's weight.** That was with the rod nearly weightless (0.3 g). A
real rod 1.5 m long weighs more: a 1.5 mm carbon-fibre rod, about 4 g. Its
weight down the slope pushes the post back down the slope, against the
ball: with a rod of 1, 2 or 3 g the first ball no longer lifted the lever
enough, and the machine stopped after it. So the rod's weight has to be
balanced, and that took five tries, and then a sixth design without a
rod at all:

1. **A counterweight on the lever, up the slope over its axle** (a steel
   ball on a short arm). AUTO then passed with any rod from 0.3 to 8 g.
   But MANUAL took the rod off, and without the rod's weight the lever
   tipped over into the channel, its counterweight down among the balls,
   and the 13 x 3 stopped at its 13th ball, all twelve balls behind it.
2. **The rod on for good,** working an **AUTO crank**: an arm of its own on
   the anchor's pin, over the anchor and its counterweight ball, as long
   as the anchor's counterweight arm. AUTO is a latch pin through the
   crank's end and the end of that arm; MANUAL, the pin out, leaves the
   crank swinging idle. MANUAL still failed: a counterweight over the axle
   balances the rod only near rest. Past 0.14 radians it is top-heavy, so
   once a ball had lifted the lever it fell on over and stayed there,
   counterweight in the channel. (The lever's post had also gone up to
   the crank's height, 37 mm over the plate; then a 2 g rod failed in
   AUTO too, the counterweight, made for 4 g, holding the anchor half
   tripped. The taller the post, the more any mismatch between rod and
   counterweight turns the lever; the post is short again, its top 21 mm
   over the plate, and the rod slopes up to the crank, 0.7 degrees.)
3. **A counterweight on the AUTO crank**, across its pin (in the board's
   plane, so the same at every angle): MANUAL passed, but in AUTO a ball
   stopped under the lever, and the machine with it.
4. **A thread instead of the rod,** from the post down the slope round a
   pulley and back up the board (nothing to balance: a thread weighs
   next to nothing): in the simulation the closed loop of lever, thread
   and pulley held the lever down, and the first ball stopped under it,
   though a motor on the lever's axle turned it easily.
5. **A counterweight hanging below the lever's axle,** on an arm glued on
   the axle's end where it comes out beyond the channel's left wall,
   behind the collector's wall, where no ball goes: a 3/8 inch steel ball
   (3.53 g), 3 mm below the axle and 6.4 mm up the slope, which balances a
   4 g rod. Below the axle it is steady at every angle. (Hung lower, 9 mm
   below, it was too steady: it pressed the lever down on the first ball,
   which stopped under it, the anchor half tripped, and the wheel ran.)
   This passed, in MANUAL and AUTO: 13 x 5 in AUTO, all 21 balls from
   one START, with a rod of 0.3, 2, 4 and 8 g, and at friction 0.2, 0.3,
   0.45 and 0.6.

6. **A thread, pulling (2026-10-28).** William's point: a rod 1.5 m long
   and that thin can pull but hardly push (a 1.5 mm carbon rod buckles at
   about 14 g; the trip needs about 2, but only while the rod stays
   straight). A thread can't push at all, so the lever's part that it is
   tied to must move *away* from the anchor as a ball lifts it: an arm
   hanging down from the axle, whose foot swings down the slope. The
   axle comes out through the rim, the arm hangs beside the board, and
   the thread runs straight up beside the board's right edge, outside
   everything, to an eye level with the START lever, and across to the
   START lever, 19 mm from the anchor's pin. It pulls the lever to the
   right, as the hand does. A thread weighs next to nothing, so there is
   nothing to balance: the counterweights, the AUTO crank and the latch
   are gone. In the simulation the thread can't stretch and only pulls:
   each step, if it is taut and the lever and anchor would lengthen it,
   an equal pull on both ends stops that (as a spring of nylon's
   stiffness, the ball bounced off the lever and stopped). Earlier, a
   thread run round a pulley at the bottom, its two pieces simulated as
   rigid links, had held the lever down.

   This needed the lever's underside changed. Its straight underside met
   a ball 3 mm from the axle, where the ball has little leverage, and now
   and then a ball stopped there, under the axle (the 13 x 3 in MANUAL,
   its 13th ball; it also explains some of the failures above). The
   underside now stays high out to 6 mm from the axle and then slopes
   down to the end: a ball meets it farther out. Then 13 x 3 in MANUAL and
   13 x 5 in AUTO passed, the AUTO one at friction 0.2, 0.3, 0.45 and
   0.6, the MANUAL one at 0.3 and 0.6.

**Friction.** At friction 0.6 (the slider's top) a ball once stuck under
the lever (with try 2): wedged between the floor and the arm, it can't
roll on both, and slid too stiffly on the arm. The lever stopped a third
of the way up, holding the anchor half tripped, where neither finger holds
a pin, and the wheel let nine balls go at once. So the lever's underside
is faced with PTFE tape (0.1 on steel, whatever the slider says).

**STOP** drops its ball into a pocket under the plate, beside the return
lane: it never reaches the lever, nothing trips, and the machine stops.

### Checking it

In AUTO the next ball is already let go when a ball lifts the lever, so the
program's `RUN` checks each ball there (everything it changed, and that it
reached the bottom), with one ball in flight; the ball through STOP is
checked when all is still. `programs/multiply-auto.dc2`, 13 x 5, ran 21
balls from one START, every one right, and A read 65. The hand keeps the
input filled from the store as it runs.

### Still to do

- OVERFLOW halting the machine, for dividing and counting out in AUTO (a
  flap under the OVERFLOW hole, and a pocket, as STOP's).
- The weight, its winding and the fly as parts.
- The thread as it is: it stretches a little and rubs in its eye; in the
  simulation it does neither, and weighs nothing.

## Step 2c: the complement, subtracting and dividing

### Done lanes and shutters

E.S.R.'s machine complements with six mode flip-flops between A's (T1 to
T6) and two more to sequence them (CF1, CF2). Here the same thing is done
with fewer moving parts: under each of A1 to A6's done holes a **done
lane** runs on into the next flip-flop's funnel, and a **shutter** covers
the hole. Closed, a ball leaving a flip-flop on its "done" side rolls over
the hole and on into the next one, as a carry does, so it turns over every
flip-flop to A7. Open, the hole takes the ball as before. All six shutters
are on one bar: the COMPLEMENT switch.

- **The lanes needed room.** A done lane runs from the hole (3.1 cm right of
  its flip-flop, 1.3 down) 4 cm across to the next funnel's long right wall,
  and no lane may run flatter than 35 degrees. So the accumulator's steps
  went from 8 cm down the slope to 14.75 (`G.ADZ`; the distributor's and
  MQ's stay 8): the board went from 1216 to 1573 mm long.
- **The carry drifts.** Falling 14.75 cm instead of 8, a carry (which leaves
  its flip-flop moving left) drifted out past the short left wall of A5's
  funnel: on the board, the complement of 25 stopped at A4 (25 -> 22, the
  ball lost). Every one of A's funnels now has both walls long, as A1 to
  A4's had already (for the memory's lanes); then it went right. Traced,
  the carries into A5 to A7 still reached the very end of that long wall
  (4.5 cm left of where they left), and at 1200 steps a second one went
  past it. So A5 to A7's long left walls go on straight up the slope as
  **guides**, to the level of the flip-flop above. (A2 to A4 have the
  memory's lanes there, whose walls do the same.)
- **The hole has no wall below it.** Before, each done hole had a wall
  just below it that stopped the ball over it. With the lane going on below,
  there is none: the ball must drop in as it passes. In the test it did,
  every time, square (14.5 mm) or longer down the slope (20 mm), at friction
  0.1 to 0.5, pin friction 0.1 to 3 and slopes 8 to 25 degrees. But on the
  board tilted 2 degrees across (down to the left), balls rode over the
  done holes and on down the lanes, adding wrongly: a square hole leaves
  only 0.9 mm either side of the ball, and a ball running down a little off
  its middle rides one edge. So the holes are 20 mm down the slope and 18
  mm across (`G.DONE_L`, `G.DONE_W`; wider to the left, where nothing
  stands), 2.7 mm either side; the test then passed tilted 2 degrees either
  way (3 degrees fails, as everything did before).
- **The shutters slide across, not down.** Sliding down the slope, a
  shutter leaves its groove open in the lane's floor, a 2 mm pit the ball
  must cross. Sliding across, to the right, the groove it leaves is under the
  lane's right wall and outside the lane, and when it is open, the groove
  left is the hole itself. Each shutter is a 2 mm tile in a groove in the
  plate's face, flush; a pin stands up from its right end outside the lane,
  and the bar joins the pins 16 mm over the plate, above the walls (12 mm)
  and the balls (12.7 mm): nothing that rolls touches it.

`tests/complement.lua` (three flip-flops of A and their lanes, from the
exhibit's geometry): thirteen balls, every case of the three with the
shutters closed and the ordinary counting cases with them open, each
checked for what it turned over and where it went. With the board as it is
now, it passed for A1 to A3, A2 to A4, A3 to A5 and A4 to A6, at friction
0.1, 0.3 and 0.5, pin friction 0.1, 0.4 and 3, slopes 8, 15 and 25 degrees,
and tilted 1 degree across either way.

### Two balls, and the hand

The complement is two balls here: COMPLEMENT on, one ball (127 - A);
COMPLEMENT off, one more (+1). The hand moves COMPLEMENT between them, the
job CF1 and CF2 do on the original. When AUTO is built, that is the one
step of the complement it won't do by itself.

### Dividing, and the remainder

E.S.R.'s manual divides by adding the divisor to the dividend's complement
until A overflows (OVERFLOW on HALT), the MQ counting the cycles; its chapter
on remainders could not be read here. Working it through on this board:
a cycle adds M a bit at a time (8s, 1s, 4s, 2s), and A can go over on any of
those balls. Stopped at once, the rest of M is never added, and A then says
nothing useful: 11 / 5 goes over on the third cycle's 1s ball (127 + 1) and
would stop with A = 0, as 10 / 5 does, and read as 3 exactly. Finished to
the end of the cycle (its 4s ball too), A = 4. In general, finished, A =
cycles x M - dividend, so:

- A = 0: it went exactly, the quotient is the cycles;
- otherwise the quotient is the cycles less one, the remainder M - A.

So the hand watches OVERFLOW and stops at the end of the cycle (when the
next ball would go to the MQ). The tour divides 13 by 5 this way: the
third cycle goes over (on its 4s ball), A is left at 2, the MQ has counted
three cycles: quotient 2, remainder 3.

### On the board

The tour (now also the complement of 25, 12 - 4 and 13 / 5, 75 balls in
all, every one checked, and the quotient and remainder) passed in every
one of these:

- friction 0.2, 0.3, 0.6
- pin friction 0.1, 0.4, 3
- slope 10, 15, 20 degrees
- 1200, 2400, 4800 steps a second
- tilted across 1 degree either way, and 2 degrees down to the right

and failed:

- **tilted 2 degrees down to the left.** Carries that fall the length of
  the longer step arrive slowly, after the guide and the funnel's long
  walls, and the tilt carries a slow ball over the apex of a flip-flop at 0
  to its far side, past it unturned (traced in `tests/complement.lua`,
  CP_FROM=3, CP_ROLL=-2). Step 2b passed 2 degrees either way. So: **level
  across within 1 degree** now.
- **friction 0.1,** once in 75 balls: D3, the distributor's, left the
  previous ball's swing at 5 degrees of its 12 (the ball slid out of its
  cup before the swing was done, and the pin's friction held it there), and
  the next ball read it the other way. The distributor is as it was in 2b
  (step 2b's own tour, run again now at friction 0.1, fails the same way, on
  its 17th ball, with D3 at 5 and 6 degrees after several balls. Its list
  below says it passed; it doesn't now. The narrated tour, since, changed
  the timing between balls, which may be why; not looked into further).
  So: friction 0.2 to 0.6. A stronger over-centre
  pull on the rockers would be the cure; not tried.


### The printed parts

Every STL is one watertight solid (`make-stls.sh`: 18 upper and 18 lower
tiles now, 214 x 182 mm at most; the shutter; the bar's knob). Put where
they are at rest, COMPLEMENT off, no two parts overlap but each foot's stem
in its rocker's socket, as before: the shutters lie in their grooves, the
bar clears every wall, peg and rocker.

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

### AUTO: the START lever (the escapement works; not on the board yet)

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

**Second attempt (2026-10-27): the wheel held by an anchor.** The feeder
wheel itself as the escapement: let the balls' weight turn it, and hold it
a quarter turn at a time with a clock's anchor (two fingers on a pin to
the wheel's right, catching four pins on an escape star above the balls).
Each finger lay along the line its pin moves on, through the anchor's pin,
so the wheel's push could not turn the anchor. In a test of the wheel
and anchor alone, the anchor (a 1/2 inch steel ball its counterweight)
swung to tripped when pushed and back by itself when let go (not quite
home: against a pin that had stopped short). But the wheel would not
turn:

- **Balls coming down onto the top of the wheel** (as now): the next ball
  in the channel dips into the notch as the ball in it is carried away,
  and the notch's edge must then push it, and every ball above it, back up
  the channel. The hand's knob can (it is allowed 50 kg cm^2/s^2); the
  weight of one ball in the wheel gives about 3, and the wheel stopped 12
  degrees round.
- **A paddle wheel fed from the side,** the channel coming down in line
  with its left-hand space so the balls' weight pulled it round: the next
  ball still follows the one being carried away, and the vane coming round
  next must sweep through the channel and push it back. It stopped 58
  degrees round, a ball jammed between the vane and the channel's wall.

Whatever lets one ball go must at some point push the next back against
the balls above it. So that push has to come from somewhere other than the
balls in the wheel: from the trip (a ball arriving at the bottom has fallen
over a metre, but loses most of that at the collector's wall), or, more
surely, from a weight the hand winds up, as a clock's, turning the wheel
through the anchor, which already worked. That is the next thing to try.

**Third attempt (2026-10-27): a wound weight, a fly, and straight fingers.**
The wheel driven by a steady torque (the weight) with a top speed (a fly,
the air brake on a clock's striking train), and held by the anchor
(digicomp2-geometry.lua, G.ANCHOR; tests/escapement.lua). It works: at
rest nothing comes out, and each trip, from a tenth of a second to two
seconds long, lets out exactly one ball and the anchor comes back home.
What it took:

- **Each finger on its own side of the pin it stops.** The first finger
  stops a pin coming toward the anchor's pin, and lies on the near side of
  the stopping point; the second stops a pin moving away, and must lie
  beyond it, on a bar carried over the pins. With both on the near side
  the second never touched its pin.
- **Straight fingers, not curved ones.** Fingers curved as a deadbeat
  clock's (arcs about the anchor's pin, so the pin slides along them while
  the anchor swings) held the anchor tripped whenever the wheel was driven:
  the pin caught on the arc's edge, and the push there no longer passed
  through the anchor's pin (it turned the anchor half as hard as the
  counterweight, the other way). Straight fingers along the line through
  the anchor's pin have no such edge.
- **Rollers on the fingers** (no friction at the anchor): it passed with
  friction 0, 0.05 and 0.1 there; with the curved fingers any friction
  held it.
- **A weight big enough to push the column back.** At the board's 15
  degrees, a torque of 20 to 60 kg cm^2/s^2 on the wheel works and 10 does
  not (the wheel can't push the next ball back up the channel); at 25
  degrees 30 is too little for a short trip, and 50 works.
- **A fly.** With the top speed 1.5 to 12 radians a second (a quarter turn
  in a fifth of a second to a second) every trip let out one ball; with no
  limit one trip in eight let none.

It passed (eight trips each) with friction 0.1, 0.3, 0.5; pin friction
0.1, 0.4, 2; slope 8, 15, 20 degrees; 4 and 9 balls in the channel; the
hand's push 100 and 300.

Still to do before AUTO is on the board: the weight, its winding and the
fly as parts (here a torque and a speed limit on the wheel's pin); the
trip, a ball arriving at the bottom pushing the anchor's arm across; STOP,
whose ball must not; and the AUTO/MANUAL switch between the hand's knob and
the weight.

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
