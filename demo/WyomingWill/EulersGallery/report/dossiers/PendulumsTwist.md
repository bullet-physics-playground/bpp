## Pendulums with a Twist

**What it shows** — Three tables of pendulums that defy intuition. A "flip row" of nine equal-bob double pendulums, released from rest with both rods at the same angle (60 to 120 degrees), shows that energy forbids the lower rod from going over the top below 70.53 degrees, while being *allowed* above that line does not mean it *happens* (72 and 76 degrees never flip). Three swinging Atwood machines (mass ratios mu = 2.8, 3.0, 3.2) look alike, but only at mu = 3 is there a hidden second conserved quantity, shown on a dial whose needle stays still. Two swinging springs show 2:1 autoparametric resonance: tuned bounce:swing = 2:1, the bounce drains into a swing that grows to about 11 degrees and back; tuned 2.4:1 it just bounces.

**Model** — Every pendulum is integrated by the script from its exact Lagrangian equations of motion; Bullet only draws (all objects are non-colliding, mass-0 display bodies; cords and springs are drawn as beads). Integrator: Bulirsch-Stoer (Gragg modified midpoint with 2, 4, 6, 8, 10 substeps, Richardson-extrapolated to zero step: tenth order), 240 macro-steps per simulated second (4 per 1/60 s frame); the Atwood machines take two half-steps, i.e. 480 per second. No damping or friction anywhere. Units cm, kg, s; g = 981 cm/s^2.
- Flip row: rods l = 7 cm, equal point bobs, angles 60, 66, 70, 72, 76, 80, 90, 100, 120 degrees.
- Atwood: (1 + mu) r'' = r theta'^2 - g (mu - cos theta), r theta'' = -2 r' theta' - g sin theta; start r = 18 cm, theta = 60 degrees, from rest; zero-size pulleys 8 cm apart.
- Springs: stretched length l = 20 cm at rest, released Z = 2 cm lower with a 0.05-degree swing; k chosen so sqrt(k/m) = 2.0 or 2.4 times sqrt(g/l). The exact (Floquet) growth rate is computed in the script by RK4 (2000 steps) over one bounce period of the linearised swing equation with prescribed r(t).
- Everything restarts every 60 s (PT_CYCLE); the report prints at the end of each cycle.

**Theory checks**

| Quantity | Theory (formula / source) | Simulation (this run) | Agreement |
|---|---|---|---|
| Lower-rod flip threshold | E = -3mgl cos a must reach -mgl: cos a <= 1/3, a >= 70.53 deg | Never flipped: 60, 66, 70 (below line); also 72, 76 (above line, allowed but not seen in 60 s). Flipped: 80 (10.86 s), 90 (2.81 s), 100 (1.26 s), 120 (1.82 s) | Consistent: no flip below 70.53 deg |
| Upper-rod flip threshold | needs +mgl: cos a <= -1/3, a >= 109.47 deg | Only 120 deg flips its upper rod (4.87 s); 100 deg does not | Consistent |
| Flip-row energy conservation | E constant | max abs(E - E0) = 1.1e-08 of m g l | Conserved (README: 1.1e-08, identical) |
| Atwood mu = 3 second integral | I = p_xi^2/8 - E xi^2 + 2 xi^4, p_xi = 4 xi'(xi^2 + eta^2), constant only at mu = 3 (Casasayas-Nunes-Tufillaro 1990) | I between 0.7500000000 and 0.7500000000 | Constant to 10 printed digits |
| Same quantity, mu = 2.8 | not conserved | I between 0.6151989479 and 1.0500000000 | Wanders, as expected |
| Same quantity, mu = 3.2 | not conserved | I between 0.3572701538 and 0.8542564850 | Wanders, as expected |
| Atwood energy (relative) | E constant | 3.1e-13 (2.8), 2.8e-13 (3.0), 2.1e-13 (3.2) | Conserved to round-off |
| Atwood closest approach to pulley | (no theory; README value) | 7.0 / 4.5 / 3.7 cm; no pulley hit | Matches README exactly |
| Spring 2:1 growth rate | s = (3/4)(Z/l) sqrt(g/l) = 0.525 /s (first order); Floquet multiplier of one bounce: 0.527 /s | fitted from swing peaks 0.2 to 3 deg: 0.526 /s | -0.2% vs Floquet, +0.2% vs first order |
| Spring 2:1 peak swing | (README: "grows to 11 degrees") | at most 11.4 degrees | Matches README |
| Spring 2.4:1 | Floquet: no growth (multipliers on unit circle) | never grew; at most 0.0 degrees | Exact |
| Spring energy (relative) | E constant | 4.9e-14 (2.0:1), 3.6e-14 (2.4:1) | Conserved to round-off |

The threshold angles 70.53 and 109.47, and the theoretical rates 0.525 and 0.527, are computed by the script and printed at each release.

**Run used**

```
cd demo/WyomingWill/EulersGallery/exhibits/PendulumsTwist && HOLD_S=0 timeout 1500 ../../../../../release/bpp -f pendulums-twist.lua -n 3620
```

```
    Tuned 2.0:1, the swing grows as exp(s t): s = (3/4)(Z/l) w = 0.525/s to first order, 0.527/s exactly (Floquet);
    flip row, let go at 80 degrees: the lower rod goes over the top at 10.86 s
    the flip row: the lower rod over the top -- 80: 10.9 s, 90: 2.8 s, 100: 1.3 s, 120: 1.8 s (upper 4.9 s); never: 60, 66, 70, 72, 76 degrees (below 70.53 it can't; above, it may)
      energy steady to 1.1e-08 of m g l
    Atwood, 2.8 times: I between 0.6151989479 and 1.0500000000 (no such constant here); energy steady to 3.1e-13; closest to its pulley 7.0 cm
    Atwood, 3.0 times: I between 0.7500000000 and 0.7500000000 (constant, as at 3 it must be); energy steady to 2.8e-13; closest to its pulley 4.5 cm
    Atwood, 3.2 times: I between 0.3572701538 and 0.8542564850 (no such constant here); energy steady to 2.1e-13; closest to its pulley 3.7 cm
    spring, 2.0:1: the swing grew at 0.526/s, from 0.2 to 3 degrees (theory 0.527 exactly, 0.525 to first order); at most 11.4 degrees; energy steady to 4.9e-14
    spring, 2.4:1: the swing never grew; at most 0.0 degrees; energy steady to 3.6e-14
```

Every number in the README's console excerpt was reproduced digit for digit by this run.

**Known departures and honest caveats**
- The README says plainly that the mu = 2.8 and 3.2 Atwood machines are **not visibly chaotic** when released from rest at 60 degrees. The author reports (README; not re-run here) that two copies started 1e-6 rad apart separate at no measurable exponential rate for release angles from 60 to 170 degrees and ratios from 1.3 to 3.2. So the exhibit does not claim to show chaos. What sets mu = 3 apart is only the hidden constant, shown on the dial (needle turns 120 deg per 0.5 change in I).
- The README also states (not re-run here) that from 90 degrees at mu = 2.5 the light weight is whipped into its pulley within 16 s. The script stops integrating a machine if r < 3% of 18 cm. The pulleys have zero size.
- Flip times near the threshold (72, 76 deg "never"; 80 deg at 10.9 s) cover a 60 s window only. "Never" means "not within 60 s", not proven never. The energy line is a necessary condition, not a sufficient one.
- The flip-row energy drift (1.1e-08 of mgl) is about five orders larger than the Atwood and spring drifts; it is still small. Fixed on 15 Oct 2026: the Lua header comment used to say "steady to 1e-10"; it now says "steady to 1e-8 of m g l", matching the console and README (1.1e-08). Comment only; console output unchanged.
- The growth rate is fitted to swing peaks between 0.2 and 3 degrees only, where the linear (exponential) phase holds. The later energy exchange (11.4 deg maximum) is nonlinear and is not compared with theory.
- Idealisations: point bobs, massless rigid rods and inextensible massless cords, frictionless pulleys of zero radius, massless linear springs.

**References**
- S. Casasayas, A. Nunes, N. Tufillaro (1990): the integrable swinging Atwood machine at mu = 3 (cited in code and README; no journal given).
- Pujol, Tufillaro and group, arXiv:2507.00058: the form of the integral I used here (README).
- Mathieu's equation and Floquet theory, for the parametric growth rate (README; no specific source).
