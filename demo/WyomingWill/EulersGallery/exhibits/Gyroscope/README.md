# The Gyroscope

Three toy gyroscopes, the same one each time: a brass rotor spinning fast in
a hoop, its axle standing out of the hoop at each end to a little ball. Spun
up to 100 turns a second and set down:

* **Left, on a pedestal**, held only by the ball at one end of its axle. It
  doesn't fall: it goes round (precesses), axle level, a turn every 2.45
  seconds.
* **Middle, hung by a string** from the same ball. The same, the string
  leaning out a little as it goes round.
* **Right, on a tightrope**, axle upright, standing on the wire on its other
  end, a forked foot. It balances there, as a top balances on its point.
  And it travels: an attendant tips the wire a degree, one end up and the
  other down, and it slides down the wire, upright; tipped back, it slows,
  stops and slides back, to and fro along the wire, about 9 cm each way. A
  degree is too little to see on the wire (its ends move 2.6 mm), so a
  gauge in front of it shows the tilt 20 times over.

As the rotors slow, the left two go round faster and sag lower; the right
one wobbles in wider and wider circles. After 37 seconds the pedestal
one slides off its point; after a minute, at 39 turns a second, the
tightrope one comes off the wire; the one on the string sags on until its
rotor stops, at 100 seconds, and it just hangs.

## Keys

| Key | Action |
|---|---|
| `R` | spin them up again |
| `Z` | slow motion (1/4) <-> real time |

Sliders: spin (turns a second), bearing (how fast the rotors slow), pivot
friction (at the pedestal's point; a quarter of it at the string's knot),
rock (how far the wire is tipped each way, in degrees; 0 leaves it still),
slope (of the wire, when it isn't rocked), friction (the wire's; the foot
has half of it: see below), speed, steps. Moving the spin, rock or slope slider spins them up again with the
new setting, half a second after you let go.
Rest the mouse on a gyroscope to see what it's doing, or on the wire or
the gauge for its tilt. The console reports
each change ("Pedestal sagging at 29.7 s") and every 2 seconds each one's
tilt, spin and how many times it has gone round.

## The gyroscope

A rotor 6 cm across, 100 g, its weight mostly in the rim (moment of inertia
about the axle 0.65 m r^2); a hoop 8.8 cm across, 50 g; an axle, 10 g; 160 g
in all. The balls are 6 cm from the centre.

* **Going round.** Held 6 cm from its centre, it goes round at
  m g r / (I w): 2.56 radians a second at 100 turns a second, a turn every
  2.45 s. It does that: 2.58 radians a second over its first 2 seconds
  (theory at the 99 turns a second it has then, 2.59), and 3.35 turns in
  its first 8 seconds, as it slows from 100 to 92 turns a second (theory
  3.40; the console rounds it to 3.4).
* **Sagging.** With no friction at all it would go round level for ever,
  however slowly it spun, dipped only by its wobble (m g r I / (I3 w)^2: 3
  degrees at 100 turns a second, 16 at 40). It does that too, with the
  pivot friction slider at 0. Friction against going round is what makes a
  real one sag.
* **Standing on the wire.** A top stays up on its point while
  I3 w > 2 sqrt(I m g l), with l the height of its centre of mass above the
  point and I its moment of inertia across the axle about the point: here
  above 46 turns a second (46.7 to 48.2, as I is 7.36 or 7.85 kg cm^2,
  in the hoop's plane or across it). On a still, rough wire (0.15 at the
  foot) it starts to wobble at 47 turns a second, as the rule says, and
  comes off at 45.

Getting the tightrope to work took some finding. The first gyroscope stood
on the wire on its hoop, with a groove round the hoop for the wire. It can't
balance there, however fast it spins: rolling along the wire, the hoop
turns its axle over, and the axle soon lies along the wire, where the spin
does nothing to hold it up. Standing on a foot at the end of its axle, it
is a top on a point, and stays up.

* **Sliding along the wire.** The foot's friction on the wire is 0.0025,
  as if it ran on a little wheel, so it slides on any slope steeper than
  0.14 degrees (still, it holds at 0.1 degrees and slides at 0.2). Bullet
  multiplies the two bodies' friction at a contact; the friction slider
  sets the wire's, 0.005, and the frame has Bullet's own 0.5, so the foot
  has half the slider's value. The attendant tips the wire 1 degree down to the right, and
  then always up on the side the gyroscope is on (judged 0.3 s ahead, for
  the 0.6 s each tip takes), so it slides to and fro through the middle,
  as a ball rolls to and fro in a dip; each time it stops, the attendant
  tips a little later or sooner next time, to keep it going about 9 cm
  each way (4 to 13 cm; the first time 14, before it has the timing: a
  point sliding on the wire with the foot's friction, tipped as the wire
  is tipped, goes 13.4).
  The console gives where it is on the wire and the wire's tilt.
* **Why only a degree.** To a gyroscope on a tipped wire, "up" is square
  to the wire, so each tip moves its up a little, and it wobbles round its
  new up. Its wobble goes round every 2.3 s, and the tips come about as
  often, so they build it up. Rocked 1 degree, it stays up a little
  longer than on a still wire (61 s, against 58); rocked 1.5 degrees,
  about as long (63 s; but see below); rocked 2 degrees, it's thrown
  over in 9 s; 3 degrees, in 6 s. Try the rock slider.
* **Rocked 1.5 degrees.** Its first two slides run to the end of the
  wire, where the foot meets the post (14.6 cm out): tipped as the
  attendant first tips it, a point sliding on the wire would go 16 cm.
  After that it goes 1 to 13 cm each way, 9 on average. But it is on an
  edge: whether its wobble builds up depends on the smallest differences.
  At the default 2400 steps a second (and at 4800) it stays small, 3 to
  11 degrees, and it lasts 63 s (64); at 1200 it builds up, to 12 to 26
  degrees, the attendant can't hold it to 9 cm (it tips as early as it
  can, 4 cm), it runs into the posts again in its last 5 seconds and
  comes off at 47 s. The wobble doesn't push it along the wire: along the wire only the slope and the foot's
  friction act on it, and its centre turns where a point sliding on the
  tipped wire with that friction turns, to 0.1 cm (0.3 rocked 1.5
  degrees), except where a post stops it. A wide wobble only puts the
  foot, which is what the attendant watches, up to 3 cm to one side of
  the centre.
* **Why it lasts longer than on a still, rough wire.** There (the
  friction slider at 0.3: 0.15 at the foot) it starts to wobble at 47
  turns a second, as the rule says, and comes off at 45. The foot that
  can slide along the wire lets it, there, keep its point under its
  middle, which is steadier (for a top on ice the rule has I about the
  middle, not about the point); still, it comes off at 42 turns a second,
  and rocked 1 degree, at 39.

## Physics

* Each gyroscope is one rigid body: hoop, axle and rotor together. The
  rotor's spin relative to the hoop is carried as a number, an angular
  momentum inside the body (a "gyrostat"). The rotor is drawn turning, but
  Bullet never has to turn a body 100 times a second.
* Bullet's gyroscopic term is off. The body's gyroscopic torque,
  -w x (I w + h), with h the rotor's angular momentum, is handed to Bullet
  before every step, as the turn it gives the body in the step (an angular
  impulse), so the pivot, the string and the wire answer it as they would
  any other force. (Until 20 Oct 2026 it was handed over as a torque, with
  applyTorque, and Bullet 3.24's friction leaves such a torque out: it
  holds the foot still against everything else, so a foot held by
  friction slid, at h C dt / I: h the foot's distance from the centre, C
  the torque, I the moment of inertia, dt the step. On the still, rough
  wire the foot slid 0.04 cm/s, as that predicts, and the top started to
  wobble at 66 turns a second instead of the rule's 47, and at 61 to 69
  as the step changed; now it does at 47 or 48 at 1200, 2400 and 4800
  steps a second.) It's taken from the last two steps (Adams-Bashforth). Taken from this step alone, the gyroscope wobbles
  more and more; turned straight into a change of spin (as the tops do), it
  sags steadily, because the pivot takes energy out every step.
* The pedestal's point is a ball joint at the ball's centre; the string is a
  light rod (2 g) with a ball joint at each end; the wire is a capsule
  1.2 mm thick; the foot is a ball (on the wire) and two prongs (either side
  of it). The wire is a kinematic body: as it's tipped, Bullet gives it
  the speed it moves at, and the foot feels that. When the pedestal one sags 40 degrees below level, it slides off
  the point.
* The rotors lose a turn a second each second (air and bearings). What the
  bearings take goes into whatever holds the frame, which doesn't let it
  turn about its axle, so the frame isn't turned.
* 2400 physics steps a second, 30 solver iterations.

The rotor is drawn at the angle it's at, so at 100 turns a second, seen 60
times a second, its red marks seem to turn slowly or stand still, as a
wheel in a film does.

## Files

* `gyroscope.lua`: the exhibit. It also stands in Euler's Gallery (`../../`).
* `gyroscope-meshes/`: the frame (hoop, axle, balls, foot), the rotor and its
  marks, the pedestal, the string and the wire.
* `reconstruction/gen-meshes.py`: makes them (`python3 gen-meshes.py`, from
  that folder).

Headless testing: `GY_SPIN` (turns a second), `GY_BEAR`, `GY_PIVF`,
`GY_ROCK`, `GY_REACH` (cm each way), `GY_SLOPE`, `GY_MU`, `GY_LOG=file.csv` (time, which, tilt, spin, position,
heading).
