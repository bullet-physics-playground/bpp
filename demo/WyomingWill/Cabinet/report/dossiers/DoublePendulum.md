## The Double Pendulum

**What it shows** — Three tables. The butterfly: seven double pendulums let go from 120 degrees, each a billionth of a radian further round (bottom bobs 2 Å apart), swing as one for about five seconds and then fly apart: chaos. The two pure swings: the slow normal mode (rods together, lower rod sqrt 2 times as far), the fast one (rods opposed, 2.4 times as often), and a mix of both that never repeats, each with a chart recorder. Upside down: double pendulums on pivots shaken at 40 Hz; 0.6 cm falls, 1.0 cm stands (Kapitza/Acheson), 1.42 cm is thrown over by a parametric sway.

**Model** — Bullet only draws. The script integrates Lagrange's exact equations for equal point bobs on massless rods. Butterfly (l = 20 cm) and pure swings (l = 12 cm): Bulirsch-Stoer (Gragg modified midpoint with 2, 4, 6, 8, 10 substeps, Neville extrapolation in h^2, tenth order), 240 steps/s. Shaken chains (l = 10 cm): classical RK4, 4800 steps/s (120 per shake), pivot acceleration added to g. No friction anywhere. Extra hidden copies: a "twin" of butterfly pendulum 1 at half step (for a step-halving check) and a "shadow" offset by 1e-8 rad, renormalised every 0.25 s (Benettin's method for the largest Lyapunov exponent; norm in angles and angular rates / sqrt(g/l)). Upright stability: linearised equations integrated over one shake (RK4, 400 steps) to the 4x4 monodromy matrix; Floquet multipliers from its traces; window edges by 40-step bisection. Averaged theory: extra stiffness (a^2 w^2 / 2) D M^-1 D. Normal-mode amplitude correction: Lindstedt / normal-form average of the quartic Hamiltonian terms.

**Theory checks**

| Quantity | Theory (formula / source) | Simulation (this run) | Agreement |
|---|---|---|---|
| Butterfly energy (BS, 30 s) | conserved | max drift 2.1e-11 of m g l over all seven | conserved to 2e-11 |
| Step-halving twin, bottom bob at t = 1 s | should be << 2 Å start spacing | 64.4 fm (2 Å / 64.4 fm ~ 3100x) | integration error negligible |
| Twin reaches 1 cm | later than the seven | 8.3 s vs 6.3 s for the neighbour | arithmetic error lags by 2 s |
| Lyapunov exponent (Benettin, 30 s) | no closed form | 3.42 /s, doubling every 0.203 s | — |
| Separation 2 Å -> 1 cm | ln(1 cm / 2 Å) / lambda = 5.2 s | neighbour reached 1 cm at 6.3 s | observed 1.1 s (21%) later; order-of-magnitude check only |
| Slow mode, small swings | T = 2 pi / sqrt((g/l)(2 - sqrt 2)) = 0.90796 s (mine 0.907959) | — | — |
| Slow mode at 7 deg | Lindstedt: x(1 + 0.0849 A^2): 0.90911 s | 0.90911 s over 21 swings | -0.000% |
| Slow mode shape | lower/upper = +sqrt 2 = 1.4142 | 1.4091 | -0.36% |
| Fast mode, small swings | 2 pi / sqrt((g/l)(2 + sqrt 2)) = 0.37609 s (mine 0.376089) | — | small-swing theory alone 2.7% off |
| Fast mode at 7 deg | Lindstedt: x(1 + 1.8526 A^2): 0.38678 s | 0.38626 s over 51 swings | -0.135% |
| Fast mode shape | -sqrt 2 = -1.4142 | -1.4112 | -0.21% |
| Mixed swing (first 10 s) | half of each mode, each at its amplitude-corrected period | max deviation 0.1247 deg (1.78% of 7 deg); 5.11 deg with small-swing periods | good with correction |
| Lower stability edge, upright chain | averaged: a w > sqrt((2 + sqrt 2) g l): a > 0.728 cm (mine 0.7282); Floquet: 0.728 cm | 0.60 cm falls at 0.79 s; 1.00 cm stands | correct |
| Upper stability edge | Floquet: a < 1.356 cm (averaging cannot see it) | 1.42 cm thrown over at 3.96 s (4800/s); 4.46 s (my 9600/s run) | correct; timing step-dependent |
| Rocking period, a = 1.0 cm | Floquet exact 0.879 s; averaged 0.881 s | 0.881 s over 12 rocks, up to 3.8 deg | +0.3% / +0.1% (same at 9600 steps/s) |
| README console listing | README lines | identical to this run (incl. 1.42 cm at 3.96 s) | matches |

**Run used**

```
cd demo/WyomingWill/DoublePendulum && HOLD_S=0 timeout 1500 ../../../release/bpp -f double-pendulum.lua -n 2400 | grep -v ALSA
  (also DP_STEPS=9600 -n 1200 as a step-size check of the shaken chains)

    t=1 s  the bottom bobs: the next one 1.0 nm apart, the farthest 6.3 nm  (the first, stepped twice as finely: 64.4 fm)
    exactly (Floquet), it stands if 0.728 cm < a < 1.356 cm
    shaken 1.42 cm: the shaking pumps up a sway and throws it over at 3.96 s
    shaken 1.00 cm: it stands, rocking up to 3.8 degrees: a period of 0.881 s over 12 rocks (exact 0.879 s, +0.3%; averaged 0.881 s, +0.1%)
  Slow swing: a period of 0.90911 s over 21 swings (theory 0.90911 s for its size, -0.000%; small swings 0.90796 s);
  Fast swing: a period of 0.38626 s over 51 swings (theory 0.38678 s for its size, -0.135%; small swings 0.37609 s);
    to within 0.1247 degrees (1.78% of its 7; with the small-swing periods, 5.11 degrees)
  The butterfly, over 30 s: energy steady in all seven to 2.1e-11 of m g l;
    nearby swings part at 3.42 per second (Lyapunov, Benettin's method): doubling every 0.203 s,
    so 2.0 angstroms grows to 1 cm in about ln(1 cm / 2.0 angstroms) / 3.42 = 5.2 s; the next one got there at 6.3 s
    and the first, stepped twice as finely, only at 8.3 s
  [DP_STEPS=9600] shaken 1.42 cm: the shaking pumps up a sway and throws it over at 4.46 s
```

**Known departures and honest caveats**
- Idealised: point bobs, massless rods, no friction or air; Bullet plays no part in the physics.
- The Lyapunov estimate is a finite-time value from one 30 s trajectory; the predicted 5.2 s vs observed 6.3 s differ by 21%. Since 15 Oct 2026 the README says so itself: an order-of-magnitude check, not a precise test (the early growth is slower, before the gap aligns with the fastest-growing direction, and the bob gap is not the Benettin norm).
- Fast mode remains 0.135% off after the A^2 correction; the README attributes this to the next order.
- Mode-shape ratios (1.4091, -1.4112) are amplitude ratios of the measured maxima of each rod, slightly off sqrt 2 at 7 deg.
- The 1.42 cm chain's throw-over time is not converged in step size (3.96 s at 4800/s, 4.46 s at 9600/s, re-run 15 Oct 2026): it grows from a tiny seed that the step errors are part of, so only "is thrown over" is robust. Since 15 Oct 2026 the README states this. Its other numbers (0.881 s rocking, 0.79 s fall) were unchanged at 9600/s.
- The rocking period is measured on shake-averaged angles from a 4-degree tilt along the slow mode.
- "the next one 52.6 cm apart, the farthest 25.8 cm" at t = 7 s: "farthest" means pendulum 7 (the largest initial offset), not the maximum separation; after saturation it can be the smaller.
- Fixed on 15 Oct 2026: the lua header used to say energy holds "to about 1e-9" and the twin is "a few femtometres off after a second, a hundred-thousandth of the atom's width"; it now says 2e-11 of m g l and 64 fm, some three thousand times less than 2 Å, as the run gives (2.1e-11, 64.4 fm). The README's "start a hundred thousand times smaller" sentence was corrected the same way. Comments/README only; console output unchanged.

**References**
- D. J. Acheson (1993), stabilisation of an inverted chain of pendulums by vibration — README / lua header (journal not given).
- P. L. Kapitza (averaging), via the neighbouring Kapitza exhibit — README.
- Benettin's method (Lyapunov exponent), Lindstedt's method / normal form, Floquet theory, Bulirsch-Stoer with Gragg's modified midpoint — cited by method name only.
