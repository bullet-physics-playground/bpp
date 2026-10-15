## The Spinning Egg

**What it shows** — A hard-boiled egg spun fast on its side rises onto its end and spins there like a top. Sliding friction at the table does it, as with the tippe top. Spun faster, it also jumps briefly off the table as it rises. A raw egg spun the same way stays down: its liquid does not turn with the shell, the egg slows quickly, and after a finger stops it, it starts turning again by itself.

**Model** — Each egg is a Bullet rigid body; Bullet only integrates position and orientation. The egg is a prolate spheroid with half-axes a = 2.85 cm and b = 2.15 cm, mass 58 g, with A = m(a²+b²)/5 across and C = 2mb²/5 about the long axis. Before every step the script applies gravity and runs Euler's torque-free equations (RK4; Bullet's gyroscopic term off). It then computes the exact contact: the spheroid's lowest point, with a unilateral normal impulse (so the egg can leave the table) and Coulomb friction μ = 0.3 in a 2D cone, by sequential impulses over 6 iterations with Baumgarte bias 0.2. The dish rim is handled the same way. Spin friction is a moment κ·N about the vertical with κ = 100 µm. Rolling resistance is δ·N with δ = 100 µm. The run uses 4800 steps/s, no damping. Raw egg: a 0.35 mm shell (10 % of the mass) is the rigid body. Potential-flow added inertia m_f/5·(a²−b²)²/(a²+b²) is added to it. The rest of the liquid is a second rotor, I_liq = 0.1194 kg cm², coupled to the shell by a linear drag with time constant 1.5 s. Spins: left and right 25 turns/s, middle 40 turns/s. Each egg starts tipped 6° from horizontal (3° until 15 Oct 2026; see caveats), spun about the vertical.

**Theory checks** (default run unless noted)

| Quantity | Theory (formula / source) | Simulation (this run) | Agreement |
|---|---|---|---|
| Spin when upright, left 25 t/s (Jellett, Moffatt & Shimomura 2002) | W = W0·A b/(C a) = 26.00 t/s; corrected for the J removed by spin friction and rolling resistance: 25.17 | 25.31 t/s | J changed +0.83 % |
| Same, middle 40 t/s (jumps) | 41.60; corrected 40.26 | 40.95 | +1.73 % |
| Same, κ = 0 (EG_KAPPA=0), left | 26.00; corrected 25.85 | 26.02 (25.98 at EG_STEPS=9600) | +0.81 % (+0.70 %) |
| Rate of rise, left, 60° → 30° from upright (added 15 Oct 2026) | Moffatt-Shimomura gyroscopic balance, sliding: J dθ/dt = −μ M g h², J from the egg at 60°, κ taking J: 0.240 s | 0.259 s, the same at EG_STEPS 2400/4800/9600/14400/19200/38400 | +8.2 %. Started in the balance (EG_BALANCED=1, no initial nutation): 0.246 vs 0.241 s, +2.1 % (+2.4 % at 19200) |
| Same, middle (jumps) | 0.384 s | 0.468 s (0.435 at 2400, 0.469-0.470 at 9600-38400) | +22.0 %; EG_BALANCED=1: 0.401 vs 0.385, +4.2 % |
| Energy budget, left: lost vs friction + landing work | equal | 41.17 vs 41.71 µJ | −1.29 % |
| Energy budget, middle | equal | 106.19 vs 107.08 µJ | −0.83 % |
| Step-size convergence of the energy budget (EG_STEPS 2400/4800/9600/14400/19200/38400; above 9600 env only, beyond the slider) | -> 0 | left: −2.56 / −1.29 / −0.69 / −0.50 / −0.40 / −0.30 %; middle: −1.62 / −0.83 / −0.44 / −0.32 / −0.29 / −0.26 % | both converge (fixed 15 Oct 2026; the left one did not before) |
| Rise onset vs step (same runs) | should not depend on step | left: rising (tilt < 60°) at 0.30 s and standing at 0.67-0.68 s at every step; J kept to +1.05 / +0.83 / +0.72 / +0.69 / +0.67 / +0.64 %; middle 0.52 s and 1.18-1.22 s | converged (fixed 15 Oct 2026; was 0.50 / 0.65 / 0.90 / 2.45 s / never, see caveats) |
| Left egg after standing up (EG_STEPS 4800/9600/19200, 1800 frames) | should not depend on step | tilt at 3 s: 4.2 / 7.1 / 9.2°; falling back at 22.33 / 20.62 / 17.60 s (spinning 6.4 / 7.6 / 10.0 t/s); back on its side 26.13 / 25.67 / 25.18 s | **not converged** (open; see caveats). README says so |
| Jump threshold (Shimomura et al. 2006 observed jumps; README: "faster than about 30 t/s") | — | 30 t/s: 1 jump (4.0 ms, < 0.01 mm); 32: 8 jumps (≤0.33 mm); 34: 13 jumps (≤0.58 mm) | OK |
| Jumps at 40 t/s (README: 24 jumps, ≤0.6 mm, 20 ms) | measured real eggs: fractions of a mm, up to a few 10 ms | 24 jumps, 0.32-1.08 s, longest 19.8 ms, highest 0.58 mm | matches README |
| Jumps vs friction at 35 t/s (README: still jumps for μ 0.2-0.5) | — | μ = 0.2: 20 jumps; μ = 0.5: 9 jumps | OK |
| Raw egg: shared spin of shell + liquid | W0·I_s/(I_s+I_liq) = 5.5 t/s (I_s 0.0336, I_liq 0.1194) | κ = 0 at 1.2 s: shell 5.81, liquid 5.24 (moment-weighted 5.37, my calculation); default κ: 4.44 / 4.73 | κ = 0: −2.3 % (−0.9 % from the old 3° start; the 6° egg touches off-centre and sliding friction takes some spin). README says "nearly do", with these numbers |
| Raw egg re-spin after finger (κ = 0) | liquid's L shared: 3.38 t/s | 3.34 t/s (3.36 vs 3.39 at EG_STEPS=9600) | −1.2 % (−0.9 %) |
| Raw egg re-spin, default κ | README: "about half" | 1.41 vs 2.76 t/s | OK |
| Falls back after slowing (README: ~20 s, ~6 t/s, step-dependent) | — | falling back at 22.33 s at 6.4 t/s; on its side 26.13 s (4800 steps/s) | OK at 4800, but see the not-converged row |

**Run used**

```
cd demo/WyomingWill/SpinningEgg && HOLD_S=0 timeout 1500 bpp -f spinning-egg.lua -n 1800      (also EG_STEPS=9600 / 19200 with EG_LOG, -n 1800)
HOLD_S=0 EG_STEPS={2400,9600,14400,19200,38400} ... -n 120;  EG_BALANCED=1 (and with EG_STEPS=19200) ... -n 120
HOLD_S=0 EG_KAPPA=0 ... -n 300 (also EG_STEPS=9600);  EG_KAPPA=0 EG_SPIN={20,30} (EG_STEPS 4800/9600/19200) ... -n 300
EG_FAST={30,32,34} ... -n 150;  EG_FAST=35 EG_MU={0.2,0.5} ... -n 240
EG_TILT=3 EG_STEPS={4800,9600,14400,19200,28800,38400} ... -n 300 (the old start); EG_TILT 2-10 and EG_MU/EG_SPIN variations to map the hold
```
```
         Jellett's J = 49.87 (A b W0 = 49.93 lying level); standing up it should spin W0 A b / (C a) = 26.00 turns/s (x 1.040)
  Left   rising at  0.30 s (tilt 31 deg, spinning 25.2 turns/s)
  Left   standing on its end at  0.67 s (tilt 10 deg, spinning 25.3 turns/s)
         spinning 25.31 turns/s; by Jellett's J it should be 25.17 (J 48.74, from 49.87, 48.33 with spin friction: +0.83%)
         energy lost 41.17 microjoules; friction took 41.73, landings -0.02: 41.71 (-1.29% apart)
         it rose from 60 to 30 deg in 0.259 s; by J dtheta/dt = mu M g h^2 (sliding) it should take 0.240 (+8.2%)
  Middle standing on its end at  1.22 s (tilt 2 deg, spinning 41.0 turns/s)
         spinning 40.95 turns/s; by Jellett's J it should be 40.26 (J 78.64, from 79.80, 77.31 with spin friction: +1.73%)
         it rose from 60 to 30 deg in 0.468 s; by J dtheta/dt = mu M g h^2 (sliding) it should take 0.384 (+22.0%)
         it jumped 24 times as it rose (0.32 to 1.08 s): longest 19.8 ms, highest 0.58 mm off the table
  Left   falling back at 22.33 s (tilt 16 deg, spinning 6.4 turns/s)
  [EG_BALANCED=1]        it rose from 60 to 30 deg in 0.246 s; by J dtheta/dt = mu M g h^2 (sliding) it should take 0.241 (+2.1%)
  [EG_STEPS=19200] Left  falling back at 17.60 s (tilt 15 deg, spinning 10.0 turns/s)
  [EG_TILT=3, EG_STEPS=19200] Left   rising at  2.45 s (tilt 23 deg, spinning 24.0 turns/s)   (28800, 38400: never)
```
The default-run lines match the README's console sample digit for digit. Hall and standalone output IDENTICAL (cmp2.sh, 1800 frames, 21 run lines); HOLD_S=0 for 1200 frames is an exact prefix of the default 0.5 s pause for 1230.

**Known departures and honest caveats**
- The egg is a symmetric spheroid; a real egg is fatter at one end (README admits this).
- Fixed on 15 Oct 2026: the left egg's rise onset was step-dependent (0.50 / 0.65 / 0.90 / 2.45 s at 4800 / 9600 / 14400 / 19200 steps/s). Cause, by experiment: started 3° from level, the egg sat at the edge where Coulomb friction can hold the contact point still. Converged (28800 and 38400 steps/s, the first followed for 20 s) the left egg never slides: it rolls on its side without slipping (contact slip 0 after each step, friction at 50-100 % of μN), drifts to level and slows; it never rises. At coarser steps the step's first-order errors tip it up until it breaks free. The hold is a stick/slip threshold, not a noise-seeded unstable equilibrium: once sliding, the rise is deterministic (Coulomb friction gives a finite rise rate, not exponential growth), and after breaking free the 3° egg rose from 60° to 30° in 0.233-0.241 s at every step that let it go (Moffatt-Shimomura: 0.227-0.239, the J left by then). Measured threshold at μ 0.3, 25 t/s: between 3° and 4° (4°: rises at 0.35 s at every step; 3.5°: 0.38 vs 0.42 s). It moves the expected way: μ 0.2 at 3° rises at 0.50 s at both 4800 and 38400; the 40 t/s egg rises from 1° and 1.5° at both 4800 and 38400. Fix: start at 6°, about twice the threshold, stated in the script and README (EG_TILT sets it). Not tuned to a theory value; the rise check is the rate (60° → 30°) against Moffatt-Shimomura, not the onset. All three eggs start at 6°, so the middle and raw eggs' numbers changed a little (24 jumps instead of 21; raw-egg sharing −2.3 % instead of −0.9 %).
- Still open: up on its end (about 10° tilt) the egg rolls without slipping, and the same first-order step error slowly tips it further up: tilt at 3 s 4.2° / 7.1° / 9.2° at 4800 / 9600 / 19200, so the time it starts falling back is 22.3 / 20.6 / 17.6 s (at 6.4 / 7.6 / 10.0 t/s). Not converged; the README now says so. Likewise at 20 t/s (EG_SPIN=20 EG_KAPPA=0) the egg rises to about 17° identically at every step but then stands (< 15°) at 1.25 s at 4800, 2.13 s at 9600, not within 5 s at 19200. The error comes from enforcing no-slip at the start-of-step lowest point while the contact runs round the egg at the spin rate (a fix to the translation, moving the centre on the exact arc about the contact, changed nothing). Evaluating the contact at the mid-step orientation cut the standing drift about 7x (tilt at 3 s 13.1° at 4800 vs 12.3° at 19200) but at 4800 and below it damped the nutation during the rise (60° → 30° in 0.238 s instead of the converged 0.259), so it was not adopted. A proper second-order rolling contact is still to do.
- The rise-rate check: the left egg rises 8 % slower than Moffatt-Shimomura's leading-order balance; the measured axis of rotation sits 7.65° from vertical at 64.4° tilt against the balance's 7.84° (ω = ((n − Ω cos θ) sin θ, θ̇, Ω sin²θ + n cos θ), C n = A Ω cos θ). The gap is the nutation from starting with pure spin about the vertical: started in balance it is 2 %. The middle egg is 22 % slower (4 % from balance); it jumps throughout its rise.
- Jellett's J is only approximately conserved. The script measures a 0.8-1.7 % change and corrects the prediction for the J removed by spin friction (and rolling resistance and the rim; the console calls the sum "spin friction", also with EG_KAPPA=0), so the "theory" value (25.17) already includes a model-side correction. The bare Moffatt-Shimomura prediction is 26.00 t/s. The first console line now gives the egg's actual J at the start (49.87) and A b W0 lying level (49.93); before, it labelled J0 as "A b W0".
- Spin friction κ and rolling resistance δ (100 µm each) are chosen parameters. κ sets how long the egg stays up; δ stops a fallen egg rolling across the dish.
- Contact is a sequential-impulse solver, not an exact unilateral constraint. Landings are perfectly inelastic, so jump heights and durations depend on that solver. The left egg's "landings −0.02" µJ is the normal impulse's work on the small Baumgarte overlap, not a landing.
- The raw egg's liquid is a two-rotor model: added inertia plus a linearly coupled rotor with a time constant of 1.5 s. It is not a fluid simulation, and the 1.5 s is an assumed value.

**References** (as cited in README)
- H. K. Moffatt and Y. Shimomura, "Spinning eggs — a paradox resolved", Nature 416, 385 (2002).
- Y. Shimomura and colleagues, Proc. R. Soc. A (2006), on spinning eggs jumping; reported in Science News, 23 May 2006, "Well-spun egg also jumps".
- The rise equation J dθ/dt = −F h² and the balance C n = A Ω cos θ as restated in K. Sasaki, "Spinning eggs — which end will rise?", arXiv:physics/0310163 (eqs. 7, 9-11).
