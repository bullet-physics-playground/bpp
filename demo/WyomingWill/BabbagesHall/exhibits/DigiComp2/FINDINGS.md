# The Digi-Comp II counter: what the simulation showed

`FINDINGS.pdf` beside this file is a typeset copy of it.

1/2 inch steel balls (12.7 mm, 8.35 g), PLA parts, friction 0.3, no
bounce, the board at 15 degrees, 2400 steps a second, the pins' friction
0.4 kg cm^2/s^2, unless a line says otherwise. The flip-flop was worked out
alone first, with `tests/toggle.lua` (one rocker under its channel, balls let
go one at a time, 16 of them), then in the counter, with its tour (eight
balls from 0, each reading checked).

## The flip-flop

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

## The counter

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

## What it costs

Little: eight balls, three rockers and the wheel, against some fifty fixed
walls and pegs. The tour, about 28 simulated seconds, took 7 s of computing
headless here; the exhibit rests (stops stepping) once nothing has moved for
half a second.

## What is idealised

- The knob is turned by the hand: a motor on the wheel's pin, exactly a
  quarter turn at a time. In the machine as built you turn it by its four
  marks (how far off a quarter it may be was not tried).
- The pins are hinges with a constant friction torque.
- Setting it back puts the balls and the rockers in place by hand.
