## The Spinning Egg

**What it shows** — A hard-boiled egg spun fast on its side rises onto its end and spins there like a top. Sliding friction at the table does it, as with the tippe top. Spun faster, it also jumps briefly off the table as it rises. A raw egg spun the same way stays down: its liquid does not turn with the shell, the egg slows quickly, and after a finger stops it, it starts turning again by itself.

**Model** — Each egg is a Bullet rigid body; Bullet only integrates position and orientation. The egg is a prolate spheroid with half-axes a = 2.85 cm and b = 2.15 cm, mass 58 g, with A = m(a²+b²)/5 across and C = 2mb²/5 about the long axis. Before every step the script applies gravity and runs Euler's torque-free equations (RK4; Bullet's gyroscopic term off). It then computes the exact contact: the spheroid's lowest point, with a unilateral normal impulse (so the egg can leave the table) and Coulomb friction μ = 0.3 in a 2D cone, by sequential impulses over 6 iterations with Baumgarte bias 0.2. The dish rim is handled the same way. Spin friction is a moment κ·N about the vertical with κ = 100 µm. Rolling resistance is δ·N with δ = 100 µm. The run uses 4800 steps/s, no damping. Raw egg: a 0.35 mm shell (10 % of the mass) is the rigid body. Potential-flow added inertia m_f/5·(a²−b²)²/(a²+b²) is added to it. The rest of the liquid is a second rotor, I_liq = 0.1194 kg cm², coupled to the shell by a linear drag with time constant 1.5 s. Spins: left and right 25 turns/s, middle 40 turns/s. Each egg starts tipped 3° from horizontal.

**Theory checks** (default run unless noted)

| Quantity | Theory (formula / source) | Simulation (this run) | Agreement |
|---|---|---|---|
| Spin when upright, left 25 t/s (Jellett, Moffatt & Shimomura 2002) | W = W0·A b/(C a) = 26.00 t/s; corrected for spin-friction loss of J at the actual tilt: 25.07 | 25.21 t/s | J changed +0.82 % |
| Same, middle 40 t/s (jumps) | 41.60; corrected 40.31 | 40.92 | +1.50 % |
| Same, κ = 0 (EG_KAPPA=0), left | J kept: 25.87 at the actual tilt | 26.02 | +0.79 % |
| Energy budget, left: lost vs friction + landing work | equal | 42.67 vs 43.33 µJ | −1.51 % |
| Energy budget, middle | equal | 107.81 vs 108.69 µJ | −0.81 % |
| Step-size convergence of the energy budget (re-run 15 Oct 2026, EG_STEPS 4800/9600/14400/19200; above 9600 env only, beyond the slider) | -> 0 | middle: -0.81 / -0.44 / -0.34 / -0.29 %; left: -1.51 / -0.91 / -0.83 / -1.38 % | middle converges; left does not, because its rise time is not converged (next row). README now says so |
| Left egg rise onset vs step (same runs) | should not depend on step | starts rising at 0.50 / 0.65 / 0.90 / 2.45 s; standing at 0.85 / 1.00 / 1.25 / 2.78 s; J kept to +0.82 / +0.72 / +0.70 / +0.85 % | **not converged** (it starts 3 deg from level; the step errors help seed the rise). Middle egg rises at 0.52 s at every step |
| Jump threshold (Shimomura et al. 2006 observed jumps; README: "> about 32 t/s") | ~32 t/s | 30 t/s: no jumps; 32: 4 jumps (≤0.11 mm); 34: 10 jumps (≤0.50 mm) | OK |
| Jumps at 40 t/s (README: 21 jumps, ≤0.6 mm, 20 ms) | measured real eggs: fractions of a mm, up to a few 10 ms | 21 jumps, 0.42-1.11 s, longest 20.0 ms, highest 0.59 mm | matches README |
| Jumps vs friction at 35 t/s (README: still jumps for μ 0.2-0.5) | — | μ = 0.2: 17 jumps; μ = 0.5: 6 jumps | OK |
| Raw egg: shared spin of shell + liquid | W0·I_s/(I_s+I_liq) = 5.5 t/s (I_s 0.0336, I_liq 0.1194) | κ = 0 at 1.2 s: shell 5.93, liquid 5.31 (L-weighted mean 5.45, my calculation); default κ: 4.55 / 4.79 | κ = 0 is within ~1 %, still converging; README says "they do" |
| Raw egg re-spin after finger (κ = 0) | liquid's L shared: 3.43 t/s | 3.40 t/s (same at EG_STEPS=9600) | -0.9 %; README updated 15 Oct 2026 from 3.41/3.44 to the run's 3.40/3.43 |
| Raw egg re-spin, default κ | README: "about half" | 1.46 vs 2.81 t/s | OK |
| Falls back after slowing (README: ~20 s, ~6 t/s) | — | falling back at 22.38 s at 6.4 t/s; on its side 26.18 s | OK |

**Run used**

```
cd demo/WyomingWill/SpinningEgg && HOLD_S=0 timeout 1500 bpp -f spinning-egg.lua -n 1800
HOLD_S=0 EG_KAPPA=0 ... -n 300 (also with EG_STEPS=9600);  EG_STEPS=9600 / 14400 / 19200 ... -n 300;  EG_LOG at 4800 and 19200 (tilt history)
EG_FAST={30,32,34} ... -n 150;  EG_FAST=35 EG_MU={0.2,0.5} ... -n 150
```
```
         Jellett's J = A b W0 = 49.92; standing up it should spin W0 A b / (C a) = 26.00 turns/s (x 1.040)
  Left   standing on its end at  0.85 s (tilt 10 deg, spinning 25.2 turns/s)
         spinning 25.21 turns/s; by Jellett's J it should be 25.07 (J 48.53, from 49.92, 48.14 with spin friction: +0.82%)
         energy lost 42.67 microjoules; friction took 43.23, landings 0.10: 43.33 (-1.51% apart)
  Middle standing on its end at  1.20 s (tilt 2 deg, spinning 40.9 turns/s)
         spinning 40.92 turns/s; by Jellett's J it should be 40.31 (J 78.58, from 79.86, 77.41 with spin friction: +1.50%)
         it jumped 21 times as it rose (0.42 to 1.11 s): longest 20.0 ms, highest 0.59 mm off the table
  Left   falling back at 22.38 s (tilt 16 deg, spinning 6.4 turns/s)
(EG_KAPPA=0) and the egg starts turning again by itself, up to 3.40 turns/s (sharing the liquid's spin, it would
         be 3.43 with no spin friction at the table)
  [EG_STEPS=19200] Left   rising at  2.45 s (tilt 23 deg, spinning 24.0 turns/s)
  [EG_STEPS=19200]        energy lost 56.03 microjoules; friction took 56.50, landings 0.32: 56.82 (-1.38% apart)
  [EG_STEPS=19200]        energy lost 110.11 microjoules; friction took 100.56, landings 9.88: 110.43 (-0.29% apart)
```
The default-run lines match the README's console sample digit for digit.

**Known departures and honest caveats**
- The egg is a symmetric spheroid; a real egg is fatter at one end (README admits this).
- Jellett's J is only approximately conserved. The script measures a 0.8-1.5 % change and corrects the prediction for the J removed by spin friction, so the "theory" value (25.07) already includes a model-side correction. The bare Moffatt-Shimomura prediction is 26.00 t/s.
- Spin friction κ and rolling resistance δ (100 µm each) are chosen parameters. κ sets how long the egg stays up; δ stops a fallen egg rolling across the dish.
- The left egg's rise is step-size sensitive and not converged: it starts rising at 0.50 s (4800 steps/s), 0.65 (9600), 0.90 (14400), 2.45 (19200). The EG_LOG tilt history shows why: at 19200 it sits at 86.6-87.8 deg (to t = 2.1 s) (its start, 3 deg from level) for 2 s before rising; at 4800 it is already at 85 deg by 0.2 s. The rise grows from a tiny tilt and the step errors seed it. Its energy-budget gap therefore does not shrink with the step (-1.51/-0.91/-0.83/-1.38 %); only the middle egg (40 t/s, rises at 0.52 s at every step) converges as the README used to claim for both. Fixed on 15 Oct 2026 in the README: it now gives both eggs' figures, the left egg's rise times, and notes that 14400 and 19200 are set with EG_STEPS beyond the 9600 slider. Not fixed: the physics of the onset itself (what a converged left egg does) is unknown; a run beyond 19200 was not made.
- Contact is a sequential-impulse solver, not an exact unilateral constraint. Landings are perfectly inelastic, so jump heights and durations depend on that solver.
- The raw egg's liquid is a two-rotor model: added inertia plus a linearly coupled rotor with a time constant of 1.5 s. It is not a fluid simulation, and the 1.5 s is an assumed value.

**References** (as cited in README)
- H. K. Moffatt and Y. Shimomura, "Spinning eggs — a paradox resolved", Nature 416, 385 (2002).
- Y. Shimomura and colleagues, Proc. R. Soc. A (2006), on spinning eggs jumping; reported in Science News, 23 May 2006, "Well-spun egg also jumps".
