# The Double Pendulum

A pendulum hung from the bottom of another: two bobs, two light rods.
It's simple to build, and it defies intuition in three ways.

| Table | What happens |
|---|---|
| left: the butterfly | Seven double pendulums hang on one pivot and are let go together, each a billionth of a radian further round than the one before. Each one's bottom bob starts an atom's width (2 Å) further along. For five seconds they swing as one. Then, all at once, they fly apart and never come together again. |
| middle: the two pure swings | The same pendulum can swing for ever in just two simple ways. In the slow one, the rods swing together, the lower one √2 times as far. In the fast one, the rods swing opposed, 2.4 times as often. The ratio is irrational, so a mix of the two never repeats. Left: the slow swing. Centre: the fast one. Right: let go with only the top rod pulled aside, which is half of each. Under each, a chart recorder draws its rods' angles as they swing, the upper rod in gold and the lower in blue: together, the two waves rise and fall in step; opposed, they run against each other and faster; the mix never draws the same thing twice. |
| right: upside down | Three double pendulums stand on their heads on pivots shaken up and down 40 times a second. Shaken 0.6 cm, it falls. Shaken 1.0 cm, the floppy two-rod chain stands up, rocking slowly. Shaken 1.42 cm, a little too hard, it stands a few seconds, but the shaking pumps up a sway (as legs pump a swing) that grows until it throws it over. A fallen one is stood up again after 3 s, to show it again. |

Every 30 s they're all let go again.

## Keys

| Key | Action |
|---|---|
| `R` | let them all go again |
| `Z` | slow motion (1/4) <-> real time |

Sliders: gentle, right, hard (each upside-down pivot's shaking, in cm;
moving one lets them all go again), speed, steps.

## Why

**The butterfly.** The double pendulum is chaotic: two swings that start
close together part, on average, exponentially fast. Here the gap doubles
about every fifth of a second, so a billionth of a radian is everything in
about thirty doublings, six seconds. The pendulums are deterministic: the
same start gives the same swing every time. But the swing can't be
foretold beyond a few seconds, because no start is ever known to an atom's
width.

**The pure swings.** For small swings the pendulum is two coupled
oscillators. They share two *normal modes*, motions in which everything
swings at one frequency. Any other motion is a sum of the two, and because
their frequencies' ratio is irrational, the sum never repeats.

**Upside down.** This is Kapitza's trick, from the bay next door: fast
shaking makes, on average, a force that pushes a leaning pendulum back up.
David Acheson showed in 1993 that it works for a chain of pendulums too,
floppy as it is. But it works only in a window. Shake too gently and
gravity wins. Shake too hard and the shaking itself pumps up a swing, a
parametric resonance, and the chain is thrown off.

## The theory, and what the console says

Equal bobs, rods of length l, angles θ₁, θ₂ from hanging straight down.

**The butterfly.** There is no formula for chaos's rate, so the console
checks that what you see is real. Each pendulum's energy stays steady, to
2e-11 of m g l. The first pendulum is also worked out again, hidden, with
steps half as long: after a second it is 64 femtometres from the first,
three thousand times less than the atom's width the seven start apart. The
console then measures how fast nearby swings part (the Lyapunov exponent,
by Benettin's method, over the 30 s) and from that predicts when 2 Å
becomes 1 cm:

    t=1 s  the bottom bobs: the next one 1.0 nm apart, the farthest 6.3 nm  (the first, stepped twice as finely: 64.4 fm)
    t=2 s  the bottom bobs: the next one 6.5 nm apart, the farthest 38.8 nm  (the first, stepped twice as finely: 458 fm)
    t=3 s  the bottom bobs: the next one 107.3 nm apart, the farthest 643.7 nm  (the first, stepped twice as finely: 8.5 pm)
    t=4 s  the bottom bobs: the next one 3.6 microns apart, the farthest 21.4 microns  (the first, stepped twice as finely: 2.8 angstroms)
    t=5 s  the bottom bobs: the next one 605.3 microns apart, the farthest 3.62 mm  (the first, stepped twice as finely: 47.8 nm)
    t=6 s  the bottom bobs: the next one 8.19 mm apart, the farthest 5.1 cm  (the first, stepped twice as finely: 643.4 nm)
    t=7 s  the bottom bobs: the next one 52.6 cm apart, the farthest 25.8 cm  (the first, stepped twice as finely: 36.5 microns)
    ...
    The butterfly, over 30 s: energy steady in all seven to 2.1e-11 of m g l;
      nearby swings part at 3.42 per second (Lyapunov, Benettin's method): doubling every 0.203 s,
      so 2.0 angstroms grows to 1 cm in about ln(1 cm / 2.0 angstroms) / 3.42 = 5.2 s; the next one got there at 6.3 s
      and the first, stepped twice as finely, only at 8.3 s

The arithmetic has its own butterfly: its tiny errors grow at the same
rate. But they start a hundred thousand times smaller than the atom, so
the arithmetic's version parts two seconds after the seven have.

**The pure swings.** For small swings,

    w² = (g / l)(2 ∓ √2),   lower rod / upper = ±√2

with the slow swing the rods together and the fast one opposed. A real
swing has a size, and a bigger swing is a little slower: for one pendulum
the period grows by 1 + A²/16. For the double pendulum, the next terms of
its equations, averaged over the pure swings (Lindstedt's method, the
normal form), give 1 + 0.0849 A² for the slow swing and 1 + 1.8526 A² for
the fast one, 22 times as much. The mixed pendulum is then half of each,
each at its own period:

    Slow swing: a period of 0.90911 s over 21 swings (theory 0.90911 s for its size, -0.000%; small swings 0.90796 s);
      lower rod / upper 1.4091 (theory +1.4142)
    Fast swing: a period of 0.38626 s over 51 swings (theory 0.38678 s for its size, -0.135%; small swings 0.37609 s);
      lower rod / upper -1.4112 (theory -1.4142)
    Mixed: over the first 10 s it moves as half of each pure swing, each at its own period for its size,
      to within 0.1247 degrees (1.78% of its 7; with the small-swing periods, 5.11 degrees)

They swing 7 degrees, big enough to see. The small-swing theory alone
would be 2.7% out for the fast swing there; with the correction for its
size it's 0.14%, the rest being the next order of the correction.

**Upside down.** The pivot is shaken a cos(w t). Averaged over the shaking
(Kapitza's method), the chain moves as if under an extra stiffness
(a² w² / 2) D M⁻¹ D, with M its inertia and D the gradient of its mass's
height. With equal bobs and rods, it stands if

    a w > sqrt((2 + √2) g l)          (one rod: sqrt(2 g l))

and rocks then at the averaged system's two slow frequencies. The exact
answer follows a small swing through one shake (the monodromy matrix; its
eigenvalues, Floquet's multipliers, lie on the unit circle if and only if
the upright is stable). That also finds the top of the window, which
averaging can't see:

    averaged over the shaking (Kapitza, Acheson) it stands if a w > sqrt((2 + sqrt 2) g l): a > 0.728 cm
    exactly (Floquet), it stands if 0.728 cm < a < 1.356 cm
    shaken 0.60 cm: falls at 0.79 s
    shaken 1.42 cm: the shaking pumps up a sway and throws it over at 3.96 s
    shaken 0.60 cm: it fell (as it should)
    shaken 1.00 cm: it stands, rocking up to 3.8 degrees: a period of 0.881 s over 12 rocks (exact 0.879 s, +0.3%; averaged 0.881 s, +0.1%)
    shaken 1.42 cm: it was thrown over by the sway the shaking pumped up (as it should)

It's tilted along its slow rocking (the lower rod √2 times as far), and the
rocking is measured on the angle averaged over each shake.

## The pendulums

Equal bobs on light rods: 20 cm rods for the butterfly, 12 cm for the pure
swings, 10 cm upside down. The butterfly starts with both rods at 120
degrees, the pure swings at 7 degrees, and the upside-down ones tilted 4
degrees.

## Physics

* The swing's exact equations (Lagrange's), worked out here. Bullet only
  draws the pendulums.
* The shaken ones are stepped by RK4, 4800 times a second (120 to a
  shake), with the pivot's acceleration added to g.
* The others are stepped by Bulirsch–Stoer: Gragg's modified midpoint
  with 2, 4, 6, 8 and 10 substeps, extrapolated to none, which is tenth
  order. There are 240 steps a second, fewer evaluations than RK4 at 2400
  a second, and some 25,000 times as accurate.
* The whole table costs about an eighth of a second of computing per
  simulated second.

## Files

* `double-pendulum.lua`: the exhibit. It also stands in Euler's Cabinet of
  Curiosities (`../Cabinet/`).
* `dp-meshes/`: the lettering under the pure swings and on the shakers,
  made by `make-labels.py` (Pillow, NumPy, the DejaVu fonts).

Headless testing: `DP_SPEED`, `DP_STEPS`, `DP_CYCLE` (seconds between
restarts), `DP_A1`, `DP_A2`, `DP_A3` (the shaking, cm), `DP_LOG=file.csv`
(the butterfly's spread, every frame).
