# The Gyroscope

Three toy gyroscopes, the same one each time: a brass rotor spinning fast in
a hoop, its axle standing out of the hoop at each end to a little ball. Spun
up to 100 turns a second and set down:

* **Left, on a pedestal**, held only by the ball at one end of its axle. It
  doesn't fall: it goes round (precesses), axle level, a turn every 2.4
  seconds.
* **Middle, hung by a string** from the same ball. The same, the string
  leaning out a little as it goes round.
* **Right, on a tightrope**, axle upright, standing on the wire on its other
  end, a forked foot. It balances there, as a top balances on its point.

As the rotors slow, the left two go round faster and sag lower; the right
one wobbles in wider and wider circles. After about 40 seconds the pedestal
one slides off its point; at about 50 turns a second the tightrope one
comes off the wire; the one on the string sags on until its rotor stops,
at 100 seconds, and it just hangs.

## Keys

| Key | Action |
|---|---|
| `R` | spin them up again |
| `Z` | slow motion (1/4) <-> real time |

Sliders: spin (turns a second), bearing (how fast the rotors slow), pivot
friction (at the pedestal's point; a quarter of it at the string's knot),
slope (of the wire: from about 17 degrees the tightrope gyroscope slides
down it), friction (foot on wire), speed, steps. Moving the spin or slope
slider spins them up again with the new setting, half a second after you
let go.
Rest the mouse on a gyroscope to see what it's doing. The console reports
each change ("Pedestal sagging at 29.7 s") and every 2 seconds each one's
tilt, spin and how many times it has gone round.

## The gyroscope

A rotor 6 cm across, 100 g, its weight mostly in the rim (moment of inertia
about the axle 0.65 m r^2); a hoop 8.8 cm across, 50 g; an axle, 10 g; 160 g
in all. The balls are 6 cm from the centre.

* **Going round.** Held 6 cm from its centre, it goes round at
  m g r / (I w): 2.67 radians a second at 100 turns a second, a turn every
  2.35 s. It does that (3.4 turns in its first 8 seconds, as it slows from
  100 to 92 turns a second).
* **Sagging.** With no friction at all it would go round level for ever,
  however slowly it spun, dipped only by its wobble (m g r I / (I3 w)^2: 3
  degrees at 100 turns a second, 16 at 40). It does that too, with the
  pivot friction slider at 0. Friction against going round is what makes a
  real one sag.
* **Standing on the wire.** A top stays up on its point while
  I3 w > 2 sqrt(I m g l), with l the height of its centre of mass above the
  point and I its moment of inertia across the axle about the point: here
  above 46 turns a second. It comes off at about 50.

Getting the tightrope to work took some finding. The first gyroscope stood
on the wire on its hoop, with a groove round the hoop for the wire. It can't
balance there, however fast it spins: rolling along the wire, the hoop
turns its axle over, and the axle soon lies along the wire, where the spin
does nothing to hold it up. Standing on a foot at the end of its axle, it
is a top on a point, and stays up.

## Physics

* Each gyroscope is one rigid body: hoop, axle and rotor together. The
  rotor's spin relative to the hoop is carried as a number, an angular
  momentum inside the body (a "gyrostat"). The rotor is drawn turning, but
  Bullet never has to turn a body 100 times a second.
* Bullet's gyroscopic term is off. The body's gyroscopic torque,
  -w x (I w + h), with h the rotor's angular momentum, is handed to Bullet
  as a torque before every step, so the pivot, the string and the wire
  answer it as they would any other force. It's taken from the last two
  steps (Adams-Bashforth). Taken from this step alone, the gyroscope wobbles
  more and more; turned straight into a change of spin (as the tops do), it
  sags steadily, because the pivot takes energy out every step.
* The pedestal's point is a ball joint at the ball's centre; the string is a
  light rod (2 g) with a ball joint at each end; the wire is a capsule
  1.2 mm thick; the foot is a ball (on the wire) and two prongs (either side
  of it). When the pedestal one sags 40 degrees below level, it slides off
  the point.
* The rotors lose a turn a second each second (air and bearings). What the
  bearings take goes into whatever holds the frame, which doesn't let it
  turn about its axle, so the frame isn't turned.
* 2400 physics steps a second, 30 solver iterations.

The rotor is drawn at the angle it's at, so at 100 turns a second, seen 60
times a second, its red marks seem to turn slowly or stand still, as a
wheel in a film does.

## Files

* `gyroscope.lua`: the exhibit. It also stands in Euler's Cabinet of
  Curiosities (`../Cabinet/`).
* `gyroscope-meshes/`: the frame (hoop, axle, balls, foot), the rotor and its
  marks, the pedestal, the string and the wire.
* `reconstruction/gen-meshes.py`: makes them (`python3 gen-meshes.py`, from
  that folder).

Headless testing: `GY_SPIN` (turns a second), `GY_BEAR`, `GY_PIVF`,
`GY_SLOPE`, `GY_MU`, `GY_LOG=file.csv` (time, which, tilt, spin, position,
heading).
