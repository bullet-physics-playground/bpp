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
    Left   stays up, rocking up to 7.6 degrees either side: a period of 1.133 s over 6 rocks (theory, 2 pi / W: 1.124 s, +0.8%; for its size: 1.135 s, -0.2%)

The rocking is measured on the angle averaged over each shake. Kapitza's
2 pi / W is for small rocking. The averaged well is soft: to the next
order its equation is

    phi'' = -W^2 phi + c phi^3,   c = (2/3) a^2 w^2 / (2 l^2) - g / (6 l)

so a rock A radians wide is slower by 1 + 3 c A^2 / (8 W^2) (Lindstedt's
method): 0.97% at the 7.6 degrees it rocks. The period comes within 0.2%
of that. The pendulum's exact equation, stepped finely by itself (not by
Bullet), rocks from 8 degrees with a period of 1.134 s: so 0.1% of the
0.2% is the averaging (the next terms), and 0.1% is Bullet's step. Tilted
only 2 degrees, the exhibit gives 1.122 s against 2 pi / W's 1.124 s.

The step matters here. Against the exact equation's 1.134 s, Bullet's
hinge stepped 4800 times a second rocks 1.7% too quick (1.115 s); 9600,
0.4% (1.129 s); 19200, the default, 0.1% (1.133 s); 38400, 0.0% (1.134 s).
At 4800 that error happened to cancel the rock's size, and the period
looked 0.8% from 2 pi / W for the wrong reason.

## The pendulums

Each is a brass bob 3 cm across on a light aluminium rod, 20 cm from the
pivot to the bob's centre, 130.8 g in all. The shaker runs at 40 Hz.

## Physics

* Bullet. Each pendulum, bob and rod, is a rigid body on a hinge to its
  pivot block.
* The block is a heavy body moved exactly as the shaker moves it, and
  given the shaker's speed, before every step.
* 19200 physics steps a second, 480 to a shake (see above for why so
  many). The steps slider goes from 2400 to 19200.

## Files

* `kapitza.lua`: the exhibit. It also stands in Euler's Gallery (`../../`).

Headless testing: `KP_SPEED`, `KP_STEPS`, `KP_TILT` (degrees), `KP_A1`,
`KP_A2` (the shaking, cm).
