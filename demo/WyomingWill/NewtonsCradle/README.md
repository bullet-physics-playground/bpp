# Newton's Cradle

Five steel balls hang in a row, each on a V of two threads, just touching.
Lift one and let it go: it strikes the row and stops, and the ball at the
far end flies out. That ball swings back and strikes, and the first flies
out again. Lift two, and two fly out; lift three, and three do.

## Why

In a strike, momentum and energy are both kept (nearly: steel isn't quite
perfectly elastic). With identical balls, the only way to keep both is for
as many balls to leave as arrived, at the speed they came.

But that argument treats the strike as a series of separate two-ball
collisions. In a row of balls that touch, the push travels through them as
a pulse, squeezing each contact. By Hertz's law, the push grows as the 3/2
power of the squeeze. So the far ball doesn't get quite everything: the
others keep a little motion, and after a few dozen strikes the whole row is
swinging together. Leave a hair's gap between the balls (`G`) and each
strike really is a series of two-ball collisions: one in, one out, almost
exactly.

By itself it lifts one ball, then two, then three, 15 s each.

## Keys

| Key | Action |
|---|---|
| `1` `2` `3` `4` | lift that many balls and let them go |
| `G` | the balls touching <-> a 0.1 mm gap between them |
| `A` | by itself (one ball, then two, then three): on/off |
| `Z` | slow motion (1/4) <-> real time |

Sliders: lift (degrees), damping (in the contacts; 0 for none), speed,
steps.

## What the console says

    --- 1 ball lifted 30 degrees and let go; the balls touching ---
        two balls meeting at 62.7 cm/s: they touch for 84.2 microseconds (Hertz: 84.2); they part at 0.982 of it
      strike  1 at  0.197 s: speeds before   62.7    0.0    0.0    0.0    0.0
                                   after    -4.1   -1.6   -0.6    8.5   60.5 cm/s; energy 95.3%; momentum along the row 0.00% off ...
                        0.1975 s after letting go; a quarter swing from 30 degrees takes 0.1979 s

* **Hertz.** Two balls meeting head on touch for 84.2 microseconds, just as
  Hertz's formula gives: 2.87 (m^2 / (R E*^2 v))^(1/5), with m and R the
  reduced mass and radius.
* **The swing.** The first strike comes a quarter swing after letting go:
  0.1975 s, against 0.1979 s for a ball that turns with its threads (a
  physical pendulum, its moment of inertia m (L^2 + 2/5 r^2)) swinging from
  30 degrees, worked out with the elliptic integral. The difference is the
  step, 0.4 ms.
* **The strike.** With no damping (the slider at 0) the energy is all kept:
  100.0%. The touching row sends out 62.0 of 62.7 cm/s, leaving the others
  -4.5, -1.9, -0.9 and 8.0 cm/s. With the gap, the row sends out 62.6, and
  the others keep 0.1 cm/s at most. Momentum along the row is kept, but for
  what gravity and the threads change during the strike (a few
  milliseconds when the balls left moving knock again).

## The cradle

Steel balls 25 mm across, 64 g each, their centres 15 cm below the
threads' tops.

The contacts are steel on steel: Hertz's law with Young's modulus 200 GPa
and Poisson's ratio 0.3. A little damping is added: a quarter of Hunt and
Crossley's for steel, so two balls meeting at 63 cm/s part at 0.982 of the
speed.

## Physics

* Each ball is a rigid body on a hinge to the frame. That's its two
  threads: it swings in the plane of the row, turning as it swings.
* Bullet's contacts can't do the strikes, with a whole row of balls
  touching at once. So before every physics step, the script finds any
  balls that touch, or will within the step, and works them out along the
  row:
  * Hertz's push between neighbours, in steps of a quarter of a
    microsecond (a strike lasts about a tenth of a millisecond);
  * then it hands the balls' speeds and places back to Bullet, placed so
    that Bullet's step ends where the row had them.
* Little knocks between balls left barely moving (less than 3 cm/s) aren't
  counted as strikes.
* 2400 physics steps a second.

## Why the balls part

Watch a few strikes and gaps open between the balls, a few millimetres to
a centimetre, and close again. That's real. Because the balls touch, a
strike isn't a series of separate two-ball collisions: the push runs
through the row as a squeeze, a tenth of a millisecond long, and the far
ball doesn't get quite everything. The row breaks up, and every ball moves
a little. The first strike, one ball in at 63 cm/s:

| ball | 1 (it struck) | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|
| speed after, cm/s | −4.1 (back) | −1.6 | −0.6 | +8.5 | +60.5 |

So ball 4 follows ball 5 out, about 1 cm on these 15 cm threads, and
ball 1 bounces back half a centimetre; out of step, they open gaps and
close them again. This is what Herrmann and Seitz's five-ball simulation
(1982) found: balls 1 to 3 go back, 4 and 5 forward, ball 4 with about
12% of the incoming momentum (here, 14%), ball 5 with nearly all the rest.
Hinch and Saint-Jean (1999) worked out how such a line breaks up; and
watching a real cradle, the fourth ball can be seen to move and the first
to come back a little.

The small losses in each strike wear the balls' motion relative to each
other away, and after a minute or two the whole row swings together, in
step, at a smaller swing (Hutzler, Delaney, Weaire and MacLeod, "Rocking
Newton's cradle", Am. J. Phys. 72, 2004, who found it settled in 1 to 2
minutes on real cradles). For the textbook version, press `G`: a 0.1 mm
gap between the balls makes each strike a clean series of two-ball
collisions, one in, one out, almost exactly.

## The clack

Each strike clacks, and the clack is worked out from the same physics
(`make-sounds.py`). Almost all of a Newton's cradle's sound is
*acceleration noise*. In the tenth of a millisecond a strike lasts, each
ball is jerked to a new speed, and as it jerks it pushes the air ahead of
it and pulls the air behind it. (The balls' own ringing is far too high to
hear: a 25 mm steel ball's lowest note is about 100 kHz.)

So the generator runs the strike as the exhibit does: Hertz's law between
neighbours, the same damping, 20 ns steps. It takes each ball's motion
through the strike. For each frequency it uses the exact solution for the
sound a rigid sphere sends out as it moves, from each ball at its own
distance and angle from you, and again from each ball's image under the
table. Then a short, quiet room tail.

You're 60 cm in front of the cradle, 40 cm to the right and 15 cm up. A
ball coming in at 60 cm/s (a 30-degree lift) clacks at a peak of 2.7 Pa
there (103 dB, for a tenth of a millisecond), and the peak goes as the
speed to the power 1.48.

There's one sound for each of 1 to 4 balls coming in, at each of 10, 20,
35, 60 and 100 cm/s (`cradle-sounds/`, 650 KB), all to one scale. A strike
plays the one at or just above its speed, softer by that power, so the
clacks fade as the swing dies. A strike under 2 cm/s is too soft to hear,
and isn't played.

## Files

* `newtons-cradle.lua`: the exhibit. It also stands in Euler's Cabinet of
  Curiosities (`../Cabinet/`).
* `cradle-sounds/`: the clacks, made by `make-sounds.py` (NumPy, SciPy).

Headless testing: `NC_SPEED`, `NC_STEPS`, `NC_LIFT` (degrees), `NC_GAP`
(cm), `NC_DAMP`, `NC_LOG=file.csv`.
