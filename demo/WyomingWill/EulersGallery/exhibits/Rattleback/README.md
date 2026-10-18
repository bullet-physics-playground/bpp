# The Rattleback

A rattleback (or celt) is a boat-shaped stone or block that spins smoothly
one way, but spun the other way it slows, starts to rock, and turns round
to spin the way it prefers. Tap one end while it lies still, and it starts
spinning, its favourite way, all by itself.

The trick is a skew: its mass is turned a few degrees away from the lines
of its hull. Then rocking and spinning are coupled: spinning the "wrong"
way feeds a rock, and the rock, pushing against the table through the
skewed hull, turns the spin round.

Three rattlebacks, the same each time (12 x 3 x 1.2 cm, plastic, the hull
turned 8 degrees from the mass axes; the two studs on top mark the
twist), are spun at a turn a second, with a little side-to-side rock from
the hand:

| Rattleback | What it does |
|---|---|
| left (amber) | spun clockwise (seen from above), its wrong way: within a second it rocks end to end, stops, and spins back anticlockwise |
| middle (teal) | spun anticlockwise, its own way: it just spins down |
| right (magenta), the restless one | spun clockwise on a table that takes almost no energy (rolling resistance 5 microns, not 50): it turns round, then back, then round again |

Tapped on the end from rest (`T`), all three start spinning
anticlockwise; the restless one then turns round twice more.

## Keys

| Key | Action |
|---|---|
| `R` | spin them again (left and right clockwise, middle anticlockwise) |
| `T` | stop them, then tap all three on the end |
| `Z` | slow motion (1/4) <-> real time |

Sliders: spin (turns a second), wobble (the hand's rock as it's spun,
rad/s), rolling (rolling resistance for the left and middle ones,
microns), restless rolling (for the right one), friction, speed, steps.
Moving the spin or wobble slider spins them again.
Rest the mouse on a rattleback to see its spin, how far it's rocking, how
many times it has reversed, and its rolling resistance.

## The theory, and what the console says

Checked against an independent model (`reference/rb_ref.py`: a rigid
half-ellipsoid rolling without slipping on a plane, energy exactly
conserved), this rattleback is unstable both ways: a small rock grows
strongly when it spins the wrong way, 8.9 times e each second at a turn a
second (8.5 at 6 rad/s), and weakly its own way, 1.7 (1.66 at 6 rad/s).
With the skew set to 0, neither grows. With no losses at all, it reverses
both ways, for ever. A real rattleback reverses only one way because the
table takes a little energy, enough to damp the weak instability; here
that is a rolling resistance, 50 microns.

The console reports each reversal, and every 2 seconds each one's spin
(+ = anticlockwise, seen from above):

    --- spun at 1.0 turns/s with a 1.0 rad/s wobble ---
      Restless REVERSED at  0.65 s: now spinning anticlockwise (rocking up to 8 deg)
      Left  REVERSED at  0.67 s: now spinning anticlockwise (rocking up to 7 deg)
    t=  2.0s  turns/s: Left +0.62  Middle +0.79  Restless +0.71   (+ = anticlockwise)
      Restless REVERSED at  4.22 s: now spinning clockwise (rocking up to 16 deg)
      Restless REVERSED at  6.23 s: now spinning anticlockwise (rocking up to 16 deg)
    t= 20.0s  turns/s: Left +0.02  Middle +0.05  Restless +0.01   (+ = anticlockwise)

The middle one never reverses. The restless one turns round three times
and then keeps creeping round at about 0.02 turns a second for as long as
it is watched (60 s); that's the contact solver, not a rattleback.

Tapped:

    --- all three tapped on the end, from rest ---
      Left  spinning anticlockwise at  0.03 s
      Middle spinning anticlockwise at  0.03 s
      Restless spinning anticlockwise at  0.03 s
      Restless REVERSED at  3.10 s: now spinning clockwise (rocking up to 9 deg)
      Restless REVERSED at  5.52 s: now spinning anticlockwise (rocking up to 9 deg)

* **How much rolling resistance makes it one-way.** Runs of 30 seconds
  from this start (1 turn a second, 1 rad/s wobble), the rolling slider
  at:
  * 0 and 10 microns: both reverse, again and again;
  * 20 and 30: the left one turns round, back, and round again (at 30 the
    middle one turns round too, once, late, at 8.7 s);
  * 40 to 100: one-way, the left one turns round once and the middle one
    never;
  * 150 and 300: neither turns round; but at 200 the left one still did,
    late, at 4.6 s. Above 100 it is near the edge.
* **What's checked, and what isn't.** The exhibit itself compares nothing
  with a theory number: it shows which way each one ends up spinning. The
  numbers (the growth rates, the both-ways instability, the skew-0
  control) come from the reference model. Its contact is a smooth
  ellipsoid that never slips; the exhibit's is Bullet's, on a hull of
  3073 points, with friction. The two aren't compared on when they
  reverse or how fast they spin after.

## Physics

* Each rattleback is a Bullet rigid body: a solid half-ellipsoid, half-axes
  6 x 1.5 x 1.2 cm, plastic (1.2 g/cm^3): 27.1 g; moments of inertia
  0.0145 (along its length), 0.2076 (about the vertical), 0.1978 (across
  it) kg cm^2.
* Contact is Bullet's own: a convex hull of 3073 points on the
  half-ellipsoid, 0.1 mm margin, 10-micron contact processing threshold,
  friction 0.6.
* Bullet's gyroscopic term is off; each one's spin is advanced by Euler's
  equations (RK4) before every physics step. (Bullet's default drains
  spin energy, which hides half of what a rattleback does.)
* Rolling resistance: a moment delta m g against rolling (the horizontal
  part of its spin), about the contact, taken straight below the centre
  of mass, before every step: 50 microns for the left and middle ones, 5
  for the restless one.
* 1200 physics steps a second, no damping.

## The reference model

`reference/` holds the checks the exhibit was built on:

* `rb_ref.py`: the rolling-without-slipping model. Run as it stands, it
  spins the rattleback at 6 rad/s each way, skew 8 and skew 0, for 30 s:

      skew 8 spin +6:  ...  first reversal 4.68 s  rock 28.7 pitch 6.2  energy drift -1.4e-09
      skew 8 spin -6:  ...  first reversal 1.07 s  rock 28.7 pitch 6.1  energy drift -1.5e-09

  and with skew 0, no reversal either way. (Its spin is + anticlockwise;
  -6 is the wrong way.) Its mass and moments are the exhibit's to the
  last digit given.
* `rb_scan.py`: the growth rates of a small rock, from the model's
  equations linearised about steady spinning, for a range of shapes,
  skews and heights of the centre of mass; it picked this shape as one
  that is clearly one-way.
* `rattleback-test.lua`: the same body in bpp alone, spun at `RB_SPIN`
  rad/s with a 0.02 rad/s rock, logging to `RB_LOG` (which it needs;
  `RB_SKEW` sets the skew). With `RB_EULER=1` and no rolling resistance,
  skew 8, it turns round both ways, as the reference model does: spun -6
  (clockwise) at 0.70 s, +6 at 3.15 s (the reference: 1.07 and 4.68 s).
  With `RB_ROLL=50`, spun -6 it turns round at 11.1 s; spun +6 it
  doesn't, nor does skew 0 either way, in 20 s. (At 50 microns the
  rolling resistance takes nearly all of the small starting rock at once,
  0.01 degrees down to 0.001, and the rock has to grow back from that:
  hence the 11 s.)

## Files

* `rattleback.lua`: the exhibit. It also stands in Euler's Gallery (`../../`).
* `rattleback-meshes/`: the rattleback (`rattleback.obj`) and
  `rattleback-data.lua`, its hull points, mass and moments of inertia.
* `reference/`: the reference model and tests above.

Headless testing: `RB_SPIN` (turns a second), `RB_ROLL`, `RB_RROLL`
(microns: left and middle, restless), `RB_START=tap`, `RB_LOG=file.csv`
(time, which, spin, rock, pitch).
