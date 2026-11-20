# The Combination Lock: findings

*What was tried and measured in building it (2026-11-19).*

## The model, every combination

`lock-test.lua`, with no physics: `lock.lua`'s wheels, pins and gates,
turned as the dialling rules say (left four times to the first number,
right three times to the second, left twice to the third, right to open),
from a scrambled start. Each of the 1,000,000 combinations was set as the
lock's own and dialled (13 s).

- **Two pins touching** are 1.911 numbers apart (3 mm pins at 25 mm), so
  each pick-up comes after 100 − 2 × 1.911 = 96.2 numbers of lost motion.
- **Not every combination can be set by the rules** (190,400 of them).
  Setting the second number, wheel 2 travels the distance from the first
  number to the second plus 4 × 1.911; if that comes to a whole turn less
  2 × 1.911, it comes round to wheel 1 and carries it off. That happens
  exactly when the second number is 0 to 11 above the first. Likewise
  wheel 3 carries wheel 2 off when the third number is 0 to 7 below the
  second. Real makers' instructions warn against numbers close together;
  here the rule is exact. The slate warns before dialling such a
  combination, and the simulation then carries the wheel off as the model
  says.
- **The forbidden zone.** After the third number, turning right to open,
  the cam must reach the fence and draw the bolt (its notch's half-width
  and the pull: 6.45 numbers past the opening point, 0) before its pin
  comes round to wheel 3's, 96.2 numbers on. Every combination whose last
  number is 90 to 99 fails so (100,000). Safe-lock makers name a forbidden
  zone for the last number too.
- **The lock never opens early.** Of the rest, none has all three gates
  under the fence when the cam's notch passes it, turning right while the
  second number is set (the only time the notch passes turning right
  before the end).
- **The tolerance.** The fence's fall against one wheel alone, the
  wheel's gate so many numbers off: 5.90 mm (to the gate's floor) up to
  1.05, then 4.68 at 1.10, 2.32 at 1.15, 1.73 at 1.20. In the lock the
  cam's notch stops it at 4.0 mm. The notch's steep wall hooks the fence
  once its centre is below the wall's top, a fall of 2.8 mm: within 1.14
  numbers either way.
- **27 combinations open the lock** set to 31-72-46: each number within
  one of its own (30 to 32, 71 to 73, 45 to 47). So the million
  combinations are about 37,037 really different ones. Matt Blaze
  (*Safecracking for the computer scientist*, 2004) estimated a real
  three-wheel safe lock's at 22,330 to 111,139; a government analysis he
  cites put it at 38,720.

## The physics against the model

The tour (the lock's own combination; the last number five off; every
number one off) and each run below log where each gate stands from the
fence after every move, from the wheels' bodies, beside the model's. They
agree to 0.03 numbers (0.1 degree) after every move, and to 0.07 at worst
in any run.

## What went wrong on the way

**The fence resting on the wheels.** At first the cam was 0.4 mm smaller
than the wheels, so the fence rested on the rims and only the notch let
it fall onto the cam. Setting the third number, with wheels 1 and 2
already set (their gates under the fence), wheel 3's gate passing under it
let the fence drop 0.4 mm into all three gates; wheel 3's gate wall then
shoved the fence, and the fence dragged wheel 2 1.34 numbers off. Sargent
& Greenleaf rest the lever on the cam, clear of the wheels: so here, the
cam 0.4 mm bigger. The wheels now turn freely under the fence.

**The notch's steep wall catching a fence that had only fallen onto the
rims.** With the fence on the cam, the notch passing under it lets it fall
0.4 mm onto the wheels' rims. The notch's steep wall then caught its edge
and pushed it sideways before it rode up: the bolt moved 0.4 mm, and a set
wheel whose gate was under the fence was dragged 6.4 numbers. Its top 0.8
mm is now chamfered at 25 degrees: a fence 0.4 mm in meets only the
chamfer and is lifted straight out (the bolt moves 0.1 mm, and back).

**Pins as cylinders.** Even so, setting the second number, wheel 1 jumped
0.6 numbers when the cam picked up wheel 3 and 8.6 more when wheel 3
picked up wheel 2. The pins of resting wheels touch (the last move left
them so), and Bullet's contacts between two touching parallel cylinders
came out with false normals: (0.99, 0.15) where the line between the pins
is (−0.6, 0.8). Their friction dragged wheel 1 along as wheel 2 moved off.
Two pins only ever meet in the gap between their parts, so each pin is now
a sphere of its radius in the middle of that gap (a pin through a wheel,
two). Sphere-on-sphere contacts are exact; in the plane where the pins
meet they touch as the cylinders do. Every move since sets the gates to
0.03 numbers of the model.

**The fence's fall into the notch.** The notch's leading wall was steep,
so the fence dropped freely into it, at about 37 cm/s, and struck the edge
of a gate 1.5 numbers off: the blow turned that wheel 0.47 numbers in a
frame, enough to let the fence in. The leading wall's top is chamfered now
too, and lowers the fence onto the wheels at the cam's pace.

**A round fence turns a wheel that is nearly there.** It still opened at
1.5 numbers off, against a model that says 1.14, and at four times the
wheels' drag too. Resting on a gate's corner, a round fence pushes along
the line to its centre, tilted 40 degrees or more, and the sideways part
of its spring's press turns the wheel the last bit. Measured, with one
wheel off at a time (each alike):

| a gate off by | 1.0 | 1.1 | 1.2 | 1.5 | 1.8 | 2.0 | 2.3 |
|---|---|---|---|---|---|---|---|
| the dial higher | opens | opens | opens | opens | opens | locked | locked |
| the dial lower | opens | opens | opens | opens | locked | locked | locked |

A flat-bottomed fence would push straight down on a corner. Tried as a
4 mm square bar, it gave the right tolerance but threw the bolt about:
sliding over the cam's convex pieces, a box's contact sometimes took a
piece's inner, radial face for its normal (−0.98, −0.19 at the cam's back
edge, far from the notch), and every pass of the notch crept the bolt back
until the fence was hooked. That is Bullet's internal-edge problem, which
a round fence doesn't meet. So the fence is round, and the exhibit says
what it expects accordingly: open if every gate is within the model's
1.14 (the fence falls in by itself), locked if one is 2 or more off, and
either between. A whole number off is never in between: one off opens,
two off doesn't.

**Closing fast.** At 120 or 150 numbers a second (the default is 70), the
close left the bolt drawn back about 6 mm: the fence's knock on the notch's
steep wall lifted it out before the bolt was fully thrown. The hand now
turns the first 20 numbers of a close at 40 a second at most, as a person
turning the dial back steadily; at 150 the whole tour then passes.

## The relock, and the springs

Turning left after opening, the notch's leading wall (72 degrees, then the
chamfer) pushes the fence, and by it the bolt and the three wheels (their
gates hold it), back until the bolt meets its stop; only then may the
fence ride up out of the notch. It rides up too soon if the bolt and the
wheels resist too much for the lever's spring. Measured: the close works
with the bolt's friction at 0.3 and 0.6 N and fails at 1.2 N (against the
spring's 0.3 N at the fence); with the spring at 0.2 N it works, at 0.1 N
not; with each wheel's drag at 1 N cm it works, at 2 N cm not. Roughly,
the bolt's friction and the wheels' drag at the fence together must stay
under four times the spring's press. A printed bolt that drags needs
sanding and wax, or a stronger spring.

## Sweeps

Each the tour (three tries and two closes), headless, everything else as
it is: the hand 70 numbers a second, each wheel's drag 0.4 N cm, the bolt's
friction 0.6 N, the spring 0.3 N at the fence, surface friction 0.45 (pairs
0.2), 1200 steps a second.

| | tour | frames |
|---|---|---|
| as it is | PASS | 5021 |
| hand 30 | PASS | 8338 |
| hand 120, 150 | PASS | 4042, 3755 |
| wheel drag 0.1, 0.2, 1 N cm | PASS | |
| wheel drag 2 N cm | **FAIL**: the close leaves the bolt drawn back | |
| bolt friction 0.3 N | PASS | |
| bolt friction 1.2, 2 N | **FAIL**: the close | |
| spring 0.2, 0.6 N | PASS | |
| spring 0.1 N | **FAIL**: the close | |
| surface friction 0.3, 0.6 | PASS | |
| 600, 2400 steps a second | PASS | 6713, 5009 |
| 12 random combinations near the lock's, twice (`LK_RANDOM=12`, seeds 1 and 2) | PASS: 24 tried, 3 opened, all as the model said | 19,548 |

The tour takes about 84 simulated seconds, 15 s headless here. check-all
allows 6000 frames on its own and 6600 in the hall.

## The printed parts

Every STL is one watertight solid under 200 mm, lying on its bed, but for
the dial's marks: 119 raised marks and numbers, printed as the dial's
second colour (a multi-material printer, or a filament change at the
layer), not on their own. Assembled, no two parts overlap but where a pin
is pressed in (a wheel's pin, 2.3 mm³; the fence in the lever, 2.7 mm³).

**Not tested:** a printed lock. Whether a wave washer gives the wheels a
steady drag near 0.4 N cm, whether the bolt slides as freely as 0.6 N
assumes, whether PLA on steel at the fence is near the friction used here,
and how sharp the printed chamfers come out.
