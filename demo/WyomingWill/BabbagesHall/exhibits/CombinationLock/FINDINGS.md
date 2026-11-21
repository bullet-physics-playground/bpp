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

## The safecracker's way

*Added 2026-11-20: `LK_WAY=safe`, MANUAL section 8.*

**The leak, in the model.** With the cam's notch under it, the fence
rests on the largest wheel whose gate isn't under it (`L.fenceOnWheels`),
and rocked gently each way the dial stops where the fence meets the
notch's chamfered walls (`L.contacts`: steps of 0.05 numbers, then halving
to 0.0005). On wheel 1's rim (40.0 mm) the contact points are 3.505
numbers apart; on wheel 2's (39.9) 3.346; on wheel 3's (39.8) 3.183. Each
0.1 mm the fence drops narrows the gap by 0.159 numbers.

**The method** (the exhibit's tour; `lock-test.lua` does the same in the
model):

1. All three wheels parked together on a number (left four times to the
   first, then left to each in turn), every 2.5 numbers from 7.5 to 90,
   until the first point back up after a narrowing (more than 0.08 below
   the median so far, once there are four points). Then the narrowing's
   edges, a half number at a time on the way the dial turns: from the last
   point outside it until inside, from the last inside until out. Halfway
   between is wheel 1's number.
2. Wheel 1 left there, wheels 2 and 3 parked together (right three times
   to the first, then right to each), every 2.5 numbers from just below
   wheel 1's number down round to 12 above it, the same way: wheel 2's
   number. (They can't be taken further: wheel 2 would carry wheel 1 off.)
   An edge in the part of the dial the hand can't feel from (second
   numbers within about 2 of 7.5 or 95.4) comes from the other edge and
   the first graph's width.
3. The last wheel: every second number from just above wheel 2's number on
   round to 8 below it, turning right to open each time (one off still
   opens). The forbidden zone, 90 to 99, isn't tried.

In the model, on 40 random locks (seed 7): both numbers found exactly in
all 40, from 51 readings a lock (the contact points felt), and all 40
opened by the last step, in 21.7 tries on average (`lua lock-test.lua`, 3.5
minutes, most of it `L.contacts`). Graphing the whole dial and then every
half number round each narrowing took 86 readings for 31-72-46; this
takes 43.

A real safecracker graphs the whole dial, and from both sides: his
readings scatter more, false gates and worn wheels narrow the gap where
there's no gate, and the deepest narrowing only shows among them all.
Here the gaps scatter 0.01 against 0.16, and with the wheels parked
together only one wheel can narrow it, so the rest of the graph would only
show it level. The first version of the edge scan stepped from the last
point read, not from where it began, and so went a whole number at a
time after the first step; in the model it missed 8 of 40 locks, all with
a second number by the blind part of the dial.

**Blind spots.** The gap can't be felt with the wheels parked from about
93 round to 7: the feel needs the dial at 4.5 or 95.5 first, and the
parking turn would pass the wheels. A safecracker would graph those from
the other side; the exhibit's locks keep their first two numbers out of
there. The narrowing (more than 0.08 below the rest) is 3.5 numbers wide,
the gate's 3.9 less where the fence's round touches its walls, so a graph
every 2.5 numbers always has a point or two in it.

**The physics against the model.** The feel: the hand turns at 3 numbers
a second with at most 0.6 N cm, and the dial counts as stopped when it
has moved more than 0.03 and then less than 0.25 numbers a second for 0.2
s. Felt twice, the contact points agree to 0.006. Over the tour's 86
points the gaps felt differ from the model's by 0.013 numbers (the
median; 0.017 for nine in ten), against the 0.159 the method reads; the
worst, 0.08, are at a narrowing's edges, where the fence is half on a gate's
wall. The tour took 43,000 frames (12 simulated minutes) with the full
graphs; now 25,400 (7 minutes, the last wheel's 32 tries most of it).

| the safecracker's tour, as it is but | found, opened | gaps: the worst apart | frames |
|---|---|---|---|
| as it is (wheels' drag 0.8 N cm, feel 0.6 N cm) | 31-72-46 | 0.084 | 42,950 |
| in the hall | 31-72-46 | 0.042 | 42,873 |
| hand 30, 120 numbers a second | 31-72-46 | 0.106, 0.059 | 56,617, 39,166 |
| wheels' drag 0.4, 1.5 N cm | 31-72-46 | 0.109, 0.029 | |
| wheels' drag 0.1, 0.2 N cm | **31-77-47, 31-76-46**: the fence turns wheel 2 | 0.18 | |
| surface friction 0.3, 0.6 | 31-72-46 | 0.026, 0.111 | |
| 600, 2400 steps a second | 31-72-46 | 0.106, 0.018 | |
| locks 12-58-71, 84-20-63, 50-9-88 | each its own | 0.138, 0.035, 0.114 | 38,793, 44,292, 47,126 |

That table is from the full graphs (whole dial, then every half number).
Stopping each graph past the narrowing and finding its edges (all pass;
the frames, and what was found, the third one off where it opens):

| the quicker tour, as it is but | found | gaps: the worst apart | frames |
|---|---|---|---|
| as it is | 31-72-46 | 0.045 | 25,392 |
| in the hall | 31-72-46 | 0.032 | 25,410 |
| hand 30 numbers a second | 31-72-46 | 0.017 | 35,118 |
| surface friction 0.3, 0.6 | 31-72-46 | 0.015, 0.019 | 25,458, 25,425 |
| 2400 steps a second | 31-72-46 | 0.017 | 25,430 |
| locks 12-58-71, 84-20-63, 50-9-88 | 12-58-70, 84-20-62, 50-9-89 | 0.019, 0.018, 0.017 | 16,860, 37,343, 30,255 |
| locks 51-8-68, 54-94-53 (the second by the blind part) | 51-8-68, 54-94-54 | 0.017, 0.091 | 29,935, 27,907 |

Check-all now allows 32,000 frames, 32,600 in the hall.

The dial way, with the wheels' drag 0.8 N cm: the tour on its own and in
the hall, with the spring 0.2 N, and 12 random combinations (seed 2), all
as the model says.

## The safecracker's way, heard

*Added 2026-11-20.* A click as each wall stops the gentle dial (two
sounds, `make-sounds.py`: a contact microphone's click, made up, not
worked out from the physics), and after each pair of contact points a tone
from bpp's synth, `v:setTone`, pitched by the gap: 329.6 Hz for 3.505, a
fourth (5 semitones) higher for each 0.159 narrower.

- **The click's moment.** Played on the first frame the dial, having
  moved, turns slower than 0.25 numbers a second: the wall has stopped it.
  The two clicks of a pair come 1.4 s apart (85 frames), the tone 0.2 s
  after the second (when the feel is sure the dial has stopped).
- **Heard, checked.** Headless bpp has no audio device and loads no
  sounds; with SDL's dummy driver (`SDL_AUDIODRIVER=dummy`) it plays them,
  and with `-e` they go into the exported scene's `.wav`. 1000 frames on
  lock 30-15-46: the clicks at frames 847 and 932, the tone at 944 (the
  export's 25 frames a second: 33.88, 37.28, 37.76 s), the tone's peak
  329.0 Hz (329.5 asked). The tone was a tenth of the clicks' level at 0.12
  of full scale: now 0.25.
- **What the ear gets.** The tour on 30-15-46: the tones on wheel 1's rim
  about E, one A at 30 (the narrowing, 3.342); then A, and D at 16 and
  13.5 (3.170, 3.168). The gaps' scatter (0.013 numbers, the median) is
  0.4 of a semitone, so the E's are a little out of tune; the steps are 5
  semitones. Mixed from the run's log at its own pace (the clicks and the
  synth's tone, 8 harmonics falling off as k^-2.5), two minutes of graph
  1 and graph 2 across the narrowings.
- **In the hall,** only while you're at the lock (`v:onEnter` and
  `v:onLeave`); away, the lock doesn't run anyway.

## What went wrong on the way to the safecracker's way

- **Seams stopped the feel.** The cam was built of convex pieces, and with
  the gentle torque the dial stopped at 2.73 and 10.36, where the fence
  crossed from one to the next: Bullet's internal edges. The dial way's
  30 N cm never noticed. The notch's leading piece now takes in 25 degrees
  of rim, so no seam lies where the fence slides while feeling.
- **Wheel sizes.** First 40.0, 39.85, 39.7 mm: on the smallest wheel the
  fence sat 0.7 mm down the notch, 0.1 mm above the foot of the 0.8 mm
  chamfer, and half caught. 0.1 mm steps keep it on the chamfer.
- **"Starting on it".** `goTo` counted the dial as on a number within 1:
  stopped at 31.02, then told right three times to 30, it went a fourth
  turn. And `toOpen`, from 99.97, went a whole turn. Both now allow half a
  number either way.
- **The fine look** used its own median, which a narrow window has inside
  the narrowing: it uses the coarse graph's.
- **The last wheel carried wheel 2.** Trying third numbers 0, 2, 4, ...
  passes wheel 3 through the second number when the third is above it
  (12-58-71: wheel 2 moved 9.6 at the try on 60, and the lock never
  opened). The tries now start just above the second number. And "left
  once to the next number" is wrong after the tries wrap past 0, or after
  a try in the high 80s, where the right turn to open (the number, the
  pull and 4 more) catches wheel 3 from behind: each try now turns left
  from where the last left wheel 3, 2 more.
- **Too strong a feel.** At 0.8 N cm, with surface friction 0.3 the fence
  rode up the leading chamfer and the first contact was never felt. 0.5
  and 0.65 felt it at friction 0.3, 0.45 and 0.6: now 0.6.
- **Too light a drag.** With each wheel's drag 0.4 N cm (the dial way's)
  and surface friction 0.6, the safecracker found wheel 2 at 78; at 0.2
  and 0.1, 76 and 77; and the lock opened on those all the same. The
  log showed why: as wheel 2's gate comes near the fence, the fence,
  pressed down by its spring, meets the gate's edge and turns the wheel
  into line, ahead of where its pin left it (+1.5 where the model has
  +7.5, +5.0, +2.5). So the narrowing comes early. A safecracker's lock
  that is too free does the same. Now 0.8 N cm; the dial way passes from 0.1
  to 1.

## Sweeps

The dial way's (2026-11-19, before the safecracker's way: each wheel's
drag was 0.4 N cm, now 0.8; the safecracker's has its own table above).
Each the tour (three tries and two closes), headless, everything else as
it was: the hand 70 numbers a second, each wheel's drag 0.4 N cm, the bolt's
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
