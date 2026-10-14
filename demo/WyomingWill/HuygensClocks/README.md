# Huygens' Clocks

In February 1665, ill in bed, Christiaan Huygens watched two of his
pendulum clocks hanging from one beam. Their pendulums were swinging in
exact opposition, and if he disturbed one, within half an hour they were
swinging in opposition again. He called it "an odd kind of sympathy". The
beam, resting on two chairs, could move a little: each pendulum's swing
pushed it, and it pushed back on both.

Here two pendulum clocks hang from a beam on rollers, held by a spring,
with a little friction. They start swinging out of step: 60 degrees apart,
then 300, then 120, four minutes each time. Within a minute they swing in
exact opposition, and the beam stops.

## Keys

| Key | Action |
|---|---|
| `R` | start them again, out of step |
| `Z` | slow motion (1/4) <-> real time |

Sliders: beam friction, speed (up to 4x, to watch them fall into step
faster), steps.

## Why

Swinging together, the pendulums push the beam to and fro, and the beam's
friction takes their energy (the beam's pushing back also shifts their
timing). Swinging in opposition, their pushes cancel, the beam stays still,
and nothing is lost. Each clock's escapement keeps its own swing going, so
what's left is the opposed swing. (Bennett, Schatz, Rockwood and
Wiesenfeld, *Proc. R. Soc. A*, 2002.)

## The theory, and what the console says

With the clocks stopped (no escapement, no friction), the two pendulums and
the beam have two ways of swinging:

* in opposition, at the pendulum's own frequency, with the beam still;
* together, more slowly, with the beam swinging against them.

The console works both out from the masses and the spring. For the
opposed swing it also allows for the amplitude: a pendulum swinging 8
degrees is a little slower than a small swing, by the elliptic integral.
Then, every 15 s, it gives the clocks' phase difference, their frequency,
and how far the beam moves:

    stopped, they'd swing in opposition at 0.9996 Hz (the beam still), or together at 0.9179 Hz (the beam swinging against them)
    in opposition, swinging 8 degrees (a pendulum's slower, the further it swings: the elliptic integral): 0.9984 Hz
    t=   15 s  the clocks 161.9 degrees apart (in opposition: 180); swinging at 1.0063 Hz; the beam moving up to 5.335 mm
    t=   30 s  the clocks 179.5 degrees apart (in opposition: 180); swinging at 1.0004 Hz; the beam moving up to 0.544 mm
    t=   45 s  the clocks 180.1 degrees apart (in opposition: 180); swinging at 0.9989 Hz; the beam moving up to 0.062 mm
    t=   60 s  the clocks 180.0 degrees apart (in opposition: 180); swinging at 0.9987 Hz; the beam moving up to 0.008 mm

They settle at 180.0 degrees apart, at 0.9987 Hz against 0.9984 for the
opposed swing at that amplitude. The escapement's pushes account for the
rest. The beam comes to a stop.

## The clocks

* Each pendulum is a brass bob of 191 g on a light rod, 25 cm from its
  pivot, so one full swing (out and back) takes about a second.
* Each escapement gives its pendulum a small push in the direction it's
  swinging every time it passes the bottom. The push is exactly what the
  air takes in half a swing at 8 degrees, so each clock keeps swinging at
  8 degrees. On its own, its air friction would give it a quality factor of
  150.
* The beam, with the two clock cases, weighs 1.5 kg. It sits on a spring
  (1.5 Hz on its own) with friction of 5 kg/s.

## Physics

* Bullet. The beam is a body that slides along x only; each pendulum is a
  body on a hinge to it.
* The spring, the beam's friction, the air and the escapements' pushes are
  worked out before every step.
* 2400 physics steps a second.
* The clocks' hands go round once a minute, by each one's own count of its
  swings.

## Files

* `huygens-clocks.lua`: the exhibit. It also stands in Euler's Cabinet of
  Curiosities (`../Cabinet/`).

Headless testing: `HC_SPEED`, `HC_STEPS`, `HC_PHASE` (degrees), `HC_M` (the
beam, kg), `HC_F` (its spring, Hz), `HC_C` (its friction), `HC_LOG=file.csv`.
