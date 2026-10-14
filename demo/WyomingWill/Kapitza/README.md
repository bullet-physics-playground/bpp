# Kapitza's Pendulum

A pendulum stands upside down, balanced on its pivot, and doesn't fall.
The pivot is shaken up and down, a centimetre, forty times a second. Push
the pendulum over a little and it swings back up and rocks slowly about
the upright, as if gravity pointed up. Aurel Stephenson saw it in 1908;
Pyotr Kapitza explained it in 1951.

| Pendulum | What happens |
|---|---|
| left | shaken 1.0 cm at 40 Hz: it stays up, rocking about the upright |
| right | shaken 0.6 cm at 40 Hz: not enough, so it falls over and swings, then hangs, shaken, at the bottom |

Every 15 s they're stood up again, tilted 8 degrees.

## Keys

| Key | Action |
|---|---|
| `R` | stand them up again |
| `Z` | slow motion (1/4) <-> real time |

Sliders: left, right (each pivot's shaking, in cm; moving one stands them
up again), speed, steps.

## Why

Shaken fast, the pendulum quivers a little with each shake. When it's
leaning, the pivot's push and the quiver line up so that, averaged over a
shake, they push it back toward upright. If the shaking is hard enough,
that push is more than gravity's pull over.

## The theory, and what the console says

Kapitza averaged over the shaking. A pendulum of length l, its pivot
shaken a cos(w t), then moves as if in a potential in which upright is
stable when

    a^2 w^2 > 2 g l

and it rocks about the upright at

    W^2 = a^2 w^2 / (2 l^2) - g / l

For a pendulum that isn't a point on a weightless rod, l is its
equivalent length, I / (m d), with I its moment of inertia about the pivot
and d its centre of mass's distance from it.

    the pendulum: 130.8 g, its centre 19.19 cm from the pivot, equivalent length l = I/(m d) = 19.761 cm;
    it stays up if a w > sqrt(2 g l) = 196.9 cm/s, i.e. a > 0.783 cm
    Left   shaken 1.00 cm: a w = 251.3 cm/s > 196.9 -- it should stay up, rocking with a period of 2 pi / W = 1.124 s
    Right  shaken 0.60 cm: a w = 150.8 cm/s < 196.9 -- it should fall
    Right  falls over at 0.69 s
    Left   stays up, rocking up to 7.6 degrees either side: a period of 1.115 s over 6 rocks (theory, 2 pi / W: 1.124 s, -0.8%)

The rocking is measured on the angle averaged over each shake. Its period
comes within 0.8% of Kapitza's, which is itself an approximation: it
averages over the shake, and treats the rocking as small.

## The pendulums

Each is a brass bob 3 cm across on a light aluminium rod, 20 cm from the
pivot to the bob's centre, 131 g in all. The shaker runs at 40 Hz.

## Physics

* Bullet. Each pendulum, bob and rod, is a rigid body on a hinge to its
  pivot block.
* The block is a heavy body moved exactly as the shaker moves it, and
  given the shaker's speed, before every step.
* 4800 physics steps a second, 120 to a shake.

## Files

* `kapitza.lua`: the exhibit. It also stands in Euler's Cabinet of
  Curiosities (`../Cabinet/`).

Headless testing: `KP_SPEED`, `KP_STEPS`, `KP_TILT` (degrees), `KP_A1`,
`KP_A2` (the shaking, cm).
