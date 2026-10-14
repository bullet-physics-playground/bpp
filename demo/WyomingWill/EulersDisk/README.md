# Euler's Disk

A heavy steel disc, set spinning on its edge on a mirror, rolls round and
round in place, leaning further and further over as it loses energy. The
further it leans, the faster it goes round: faster and faster, until it
suddenly stops, flat. Joseph Bendik's toy (1990s); a spinning coin on a
table does the same.

Set going at 30 degrees, it rolls for about 80 s. Then it's set going
again.

## Keys

| Key | Action |
|---|---|
| `R` | set it going again |
| `Z` | slow motion (1/4) <-> real time |

Sliders: rolling (resistance, in microns; moving it sets the disc going
again), speed, steps. Rest the mouse on the disc to see its lean and how
fast it should go round there.

## The theory, and what the console says

Rolling round in place (its centre still) at a lean alpha to the mirror,
the disc's axis goes round the upright at W, where

    W^2 = m g a (a cos alpha - h sin alpha) / (sin alpha (I1 a cos alpha - I3 h sin alpha))

Here a is the radius of its bottom edge (which it rolls on), h that edge's
distance below its centre along its axis, and I1 and I3 its moments of
inertia across and about its axis. For a thin disc this is W^2 = 4 g / (a
sin alpha).

Its energy above lying flat is (3/2) m g a alpha, near enough, when alpha
is small. So as it loses energy, alpha goes to nothing and W grows without
limit. Losing energy to rolling resistance (a moment delta m g against its
rolling), it gets there at a definite time t0, and near the end

    sqrt(alpha) falls at a steady rate, delta sqrt(m g a / I1) / (3 a), and
    W (t0 - t) = 3 a / delta

whatever its mass or moment of inertia.

    t= 27.70 s  leaning 14.98 degrees: going round  10.10 times a second (theory, going round in place:  10.11; -0.11%)
    t= 51.17 s  leaning  5.97 degrees: going round  15.72 times a second (theory, going round in place:  15.73; -0.08%)
    t= 74.63 s  leaning  0.99 degrees: going round  38.29 times a second (theory, going round in place:  38.33; -0.11%)
    t= 81.73 s  it stops, flat, leaning 0.30 degrees, going round 67 times a second
               sqrt(alpha) falling at 0.00818 a second (theory, near the end: delta sqrt(m g a / I1) / (3 a) = 0.00832);
               so it would lie flat at t0 = 90.6 s, going round infinitely fast
               t= 77.17 s, leaning 0.69 degrees: W (t0 - t) = 3864 (theory: 3 a / delta = 3800)

* **Going round in place:** it goes round at the rate the theory gives for
  its lean, to 0.1-0.2%, all the way from 25 degrees to 1.
* **The end:** sqrt(alpha) falls at a steady rate, 1.7% off the
  small-angle theory, and W (t0 - t) stays constant at 3864, 1.7% off
  3 a / delta.
* It stops at 0.3 degrees: about where a real one stops, when its
  bouncing and slipping on the mirror take over, which the theory doesn't
  follow.

## The disc

Steel, 7.6 cm across, 1.2 cm thick, 430 g (the size of the toy), rolling on
the edge of its bottom face. Rolling resistance 30 microns.

## Physics

* The disc rolls without slipping, all the way. So its motion is worked
  out in the script from the rolling equations, exactly, not by Bullet's
  contacts:
  * Newton's and Euler's equations for the disc, with the force at its
    contact point being whatever keeps that point still, solved for the
    turning at each moment;
  * stepped with RK4, 9600 times a second;
  * with no rolling resistance its energy stays put to a few parts in a
    million.
* Bullet's contacts were tried first. Their small errors at a contact going
  round a rim many times a second added energy about as fast as the
  rolling resistance took it.
* A light drag on the centre's sideways motion (10 per second: the air,
  and the mirror's grip not being perfect) keeps the disc rolling in
  place. Without it, as the disc loses energy, its centre drifts into
  circles a few millimetres across, and it goes round up to a fifth slower
  than rolling in place would.

## Files

* `eulers-disk.lua`: the exhibit. It also stands in Euler's Cabinet of
  Curiosities (`../Cabinet/`).
* `eulers-disk-meshes/`: the disc and its painted marks.
* `reconstruction/gen-meshes.py`: makes them (`python3 gen-meshes.py`, from
  that folder).

Headless testing: `ED_SPEED`, `ED_STEPS`, `ED_TILT` (degrees), `ED_DELTA`
(microns), `ED_DRAG` (per second), `ED_LOG=file.csv` (time, lean, W, W by
theory, energy, the centre's x and z).
