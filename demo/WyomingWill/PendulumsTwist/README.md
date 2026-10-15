# Pendulums with a Twist

Three more pendulums that don't do what you'd guess.

| Table | What happens |
|---|---|
| left: the flip row | Nine double pendulums, let go from rest with both rods at the same angle, from 60 degrees on the left to 120 on the right. Can the lower rod swing right over the top? Energy says it can't unless 3 cos(angle) < 1, so below 70.5 degrees it never does. Above that line it's allowed, but allowed isn't the same as happens: at 72 and 76 degrees it doesn't, for as long as you watch; at 80 it takes 11 seconds, at 90 three. A bob turns red when its rod first goes over. The upper rod's own line is 109.5 degrees, and only the 120-degree one crosses it. |
| middle: the swinging Atwood machines | A cord over two pulleys. On the left hangs a heavy weight that only goes up and down; on the right, a light one that swings. Let go from 60 degrees, the light one swings in and out, the cord paying in and out, and its path (the dotted trail) is a tangle. There are three machines, the heavy weight 2.8, 3.0 and 3.2 times the light one. They look alike, and from this gentle start all three swing in an orderly way. The difference is hidden: only at exactly 3 does the motion keep a second constant besides its energy, so only at 3 can it never become chaotic, however it's started. The dial in front of each shows that quantity: at 3 to 1 its needle never moves; at 2.8 and 3.2 it wanders. |
| right: the swinging springs | A weight on a spring, set bouncing straight up and down with the merest swing. On the left, the spring's bounce is tuned to exactly twice its swing's frequency: the bounce drains away into a swing that grows to 11 degrees, then turns back into a bounce, and again. On the right, tuned 2.4 times, it just bounces. |

Every 60 s they're all let go again.

## Keys

| Key | Action |
|---|---|
| `R` | let them all go again |
| `Z` | slow motion (1/4) <-> real time |

## The theory, and what the console says

**The flip row.** Equal bobs, rods l. Let go from rest with both rods at
angle a, the energy is −3 m g l cos a. For the lower rod to go over the
top, the pendulum must at some moment have the upper rod hanging down and
the lower straight up: energy −m g l, at the least. So it can only
happen if cos a ≤ 1/3, a ≥ 70.53°. The upper rod over the top needs
+m g l: cos a ≤ −1/3, a ≥ 109.47°. That's a sharp line one way only.
Above it the flip is possible, but the motion near the line is mostly
orderly and may never find its way over:

    flip row, let go at 100 degrees: the lower rod goes over the top at 1.26 s
    flip row, let go at 120 degrees: the lower rod goes over the top at 1.82 s
    flip row, let go at 90 degrees: the lower rod goes over the top at 2.81 s
    flip row, let go at 120 degrees: the upper rod goes over the top at 4.87 s
    flip row, let go at 80 degrees: the lower rod goes over the top at 10.86 s
    ...
    the flip row: the lower rod over the top -- 80: 10.9 s, 90: 2.8 s, 100: 1.3 s, 120: 1.8 s (upper 4.9 s); never: 60, 66, 70, 72, 76 degrees (below 70.53 it can't; above, it may)
      energy steady to 1.1e-08 of m g l

**The swinging Atwood machine.** With r the swinging side's length, θ its
angle from straight down, and μ the heavy weight over the light,

    (1 + μ) r'' = r θ'² − g (μ − cos θ)
    r θ'' = −2 r' θ' − g sin θ

Its energy is conserved for any μ. At μ = 3, and only there, there is a
second conserved quantity. Casasayas, Nunes and Tufillaro found it in
1990; the form here follows Pujol and Tufillaro's group (arXiv
2507.00058). In coordinates r = (ξ² + η²)/2, tan(θ/2) = (ξ² − η²)/(2ξη),
and in units of the starting length and g,

    I = p_ξ²/8 − E ξ² + 2 ξ⁴,   p_ξ = 4 ξ' (ξ² + η²)

stays constant. With two constants for two degrees of freedom, the motion
is integrable, so it can never be chaotic. The console follows I in all
three machines, and each machine's dial shows it: the needle turns 120
degrees for a change of 0.5 in I.

    Atwood, 2.8 times: I between 0.6151989479 and 1.0500000000 (no such constant here); energy steady to 3.1e-13; closest to its pulley 7.0 cm
    Atwood, 3.0 times: I between 0.7500000000 and 0.7500000000 (constant, as at 3 it must be); energy steady to 2.8e-13; closest to its pulley 4.5 cm
    Atwood, 3.2 times: I between 0.3572701538 and 0.8542564850 (no such constant here); energy steady to 2.1e-13; closest to its pulley 3.7 cm

Released from rest, 2.8 and 3.2 aren't visibly chaotic either. Two
copies started a millionth of a radian apart stay together, and their
separation grows at no measurable exponential rate, from 60 to 170
degrees and for ratios from 1.3 to 3.2. So the exhibit doesn't claim to
show chaos at 2.8 and 3.2: what sets 3 apart here is the hidden
constant, which only the dial shows.

(Released from 60 degrees, none of them comes near its pulley. From 90
degrees at μ = 2.5, the light weight is whipped into its pulley within
16 s.)

**The swinging spring.** A weight m on a spring k, stretched to length l
at rest. Its bounce has frequency √(k/m) and its swing √(g/l). Tuned so
the bounce is twice the swing, the bounce pumps the swing as a child pumps
a swing: an autoparametric resonance. Bouncing Z with a tiny swing, the
swing grows at first as exp(s t), with

    s = (3/4)(Z / l) √(g / l)

to first order. One quarter comes from the swing's frequency being
modulated, as in Mathieu's equation, and a half from the length's rate
of change. The exact rate follows a small swing through one bounce
(Floquet's multipliers, as for the upside-down chain next door). Tuned
2.4:1, there is no growth, exactly. The console fits the swing's peaks
while it grows from 0.2 to 3 degrees:

    Tuned 2.0:1, the swing grows as exp(s t): s = (3/4)(Z/l) w = 0.525/s to first order, 0.527/s exactly (Floquet);
    tuned 2.4:1, exactly: no growth at all
    spring, 2.0:1: the swing grew at 0.526/s, from 0.2 to 3 degrees (theory 0.527 exactly, 0.525 to first order); at most 11.4 degrees; energy steady to 4.9e-14
    spring, 2.4:1: the swing never grew; at most 0.0 degrees; energy steady to 3.6e-14

## The pendulums

* **The flip row:** equal bobs on light rods, 7 cm each.
* **The Atwood machines:** a light weight swinging on 18 cm of cord at the
  start; the counterweights drawn as tall as their mass ratio; zero-size
  pulleys 8 cm apart.
* **The springs:** stretched to 20 cm at rest, let go 2 cm lower, swinging
  0.05 degrees.

## Physics

* Each is worked out from its exact equations (Lagrange's) by
  Bulirsch–Stoer: Gragg's modified midpoint with 2, 4, 6, 8 and 10
  substeps, extrapolated to none, which is tenth order. That's 240 steps a
  second, and 480 for the Atwood machines, whose light weight whips round
  fast when its cord is short.
* Bullet only draws them. The cords and springs are drawn as beads, since
  their lengths change.

## Files

* `pendulums-twist.lua`: the exhibit. It also stands in Euler's Cabinet of
  Curiosities (`../Cabinet/`).
* `twist-meshes/`: the dials' lettering, made by `make-labels.py`
  (Pillow, NumPy, the DejaVu fonts).

Headless testing: `PT_SPEED`, `PT_CYCLE` (seconds between restarts).
