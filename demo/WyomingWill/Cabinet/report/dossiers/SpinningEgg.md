## The Spinning Egg

**What it shows** — A hard-boiled egg spun fast on its side rises onto its end and spins there like a top. Sliding friction at the table does it, as with the tippe top. Up on its end it rolls, and as spin friction slows it, it leans further and further over until it is back on its side. Spun faster, it also jumps briefly off the table as it rises. A raw egg spun the same way stays down: its liquid does not turn with the shell, the egg slows quickly, and after a finger stops it, it starts turning again by itself.

**Model** — Each egg is a Bullet rigid body; Bullet only integrates position and orientation (x += h v, q = exp(h w) q). The egg is a prolate spheroid with half-axes a = 2.85 cm and b = 2.15 cm, mass 58 g, with A = m(a²+b²)/5 across and C = 2mb²/5 about the long axis. Before every step the script does the rest:
- gravity;
- Euler's equations, with Bullet's gyroscopic term off;
- the exact contact at the spheroid's lowest point: a unilateral normal impulse (so the egg can leave the table) and Coulomb friction, μ = 0.3, by sequential impulses over 6 iterations with Baumgarte bias 0.2;
- spin friction (a moment κ·N about the vertical) and rolling resistance (δ·N against the level part of w), both in the same solve, with κ = δ = 100 µm. The dish rim is a contact too.

Since 17 Oct 2026 the step is second-order and time-symmetric. The velocities it leaves belong to the middle of Bullet's move, so:
- no-slip and no-penetration are imposed at the lowest point half a step on, and the impulses act at the lowest point now;
- the gyroscopic term (implicit midpoint) and the sliding-friction direction are taken at the mean of the step's start and end, so friction opposes the mean slip;
- the contact is solved twice: a predictor with RK4 Euler, then a corrector with the predicted end state;
- the work tally takes each impulse times the step-mean velocity at its point, which is the exact energy identity of this step.

The run uses 4800 steps/s and no damping. Raw egg:
- A 0.35 mm shell (10 % of the mass) is the rigid body, with the potential-flow added inertia m_f/5·(a²−b²)²/(a²+b²).
- The rest of the liquid is a second rotor, I_liq = 0.1194 kg cm², coupled to the shell by a linear drag with time constant 1.5 s.

Spins: left and right 25 turns/s, middle 40 turns/s. Each egg starts tipped 6° from horizontal, spun about the vertical.

**Theory checks** (default run, 4800 steps/s, unless noted)

| Quantity | Theory (formula / source) | Simulation (this run) | Agreement |
|---|---|---|---|
| Spin when upright, left 25 t/s (Jellett, Moffatt & Shimomura 2002) | W = W0·A b/(C a) = 26.00 t/s; corrected for the J removed by spin friction and rolling resistance: 25.15 | 25.22 t/s | J changed +0.60 % |
| Same, middle 40 t/s (jumps) | 41.60; corrected 40.26 | 40.76 | +1.29 % |
| Same, κ = 0 (EG_KAPPA=0), left; and EG_SPIN=30 | 25.85; 31.02 | 25.94; 31.25 (identical at EG_STEPS 4800/9600/19200) | +0.58 %; +0.83 % |
| Rate of rise, left, 60° → 30° from upright | Moffatt-Shimomura gyroscopic balance, sliding: J dθ/dt = −μ M g h², J from the egg at 60°, κ taking J: 0.239 s | 0.261 s, the same at EG_STEPS 2400/4800/9600/14400/19200/38400 | +9.1 %. Started in the balance (EG_BALANCED=1): 0.247 vs 0.241 s, +2.5 % (+2.3 to +2.7 % over 2400-19200) |
| Same, middle (jumps) | 0.384 s | 0.471 s at every step | +22.7 %; EG_BALANCED=1: 0.407 vs 0.385, +5.7 % |
| Energy budget, left: lost vs friction + landing work | equal (exact identity of the step: impulse · step-mean velocity) | 41.88 vs 41.88 µJ | 0.00 % |
| Energy budget, middle | equal | 109.15 vs 109.15 µJ | 0.00 % |
| Energy budget vs step (EG_STEPS 2400-38400) | → 0 | within ±0.01 % at every step, both eggs | closes. Before 17 Oct: −2.56 / −1.29 / −0.69 / −0.40 / −0.30 % (left), shrinking with the step |
| Rolling egg keeps energy (EG_KAPPA=0 EG_DELTA=0; Chaplygin's rolling body of revolution is conservative and integrable) | E constant, tilt bounded | 1 → 10 s: E spread 0.0025 / 0.0019 / 0.0023 µJ (of 161.15) at 2400 / 4800 / 9600; tilt 9.4-10.6° | conserved. Before 17 Oct the tilt crept to 0.4-0.8° (nearly upright) by 10 s |
| Rise onset vs step (2400-38400) | should not depend on step | left: rising at 0.30 s, standing at 0.68 s at every step; middle 0.50 s and 1.22 s | converged |
| **Standing phase vs step**, left (EG_STEPS 2400/4800/9600/19200/38400, 1800 frames) | should not depend on step | tilt at 3 s: 12.01 / 11.99 / 11.97 / 11.97 / 11.89°; at 15 s: 22.64 / 22.65 / 22.66 / 22.66 / 22.53°; falling back (15°) 7.97 s (18.5 t/s) at 2400-19200, 8.15 s at 38400; back on its side 24.40 s at all | **converged** (fixed 17 Oct 2026). 2400-19200 agree to 0.05° and 0.01 s; 38400 is off by single-precision rounding (see caveats) |
| Standing phase vs exact rolling, left (reconstruction/rolling-check.py: rolling-without-slipping equations + κ, δ, DOP853 rtol 1e-11, from the exhibit's state at 1 s) | tilt 11.97° (3 s), 17.10° (10 s), 22.69° (15 s); past 15° at 8.05 s (console rule); 60° at 24.39 s; friction ≤ 0.855 μN (rolling holds) | 11.99°, 17.12°, 22.65°; 7.97 s; 24.40 s | ≤ 0.04°; −0.08 s; +0.01 s |
| Spin-down standing: J falls at the moments' rate; standing J = C a W, so dW/dt = (dJ/dt)/(C a) | κ only, κ M g h/(C a): 0.83 t/s²; with the reference's dJ/dt = −1.782/s: 0.928 t/s² | dJ/dt −1.782/s, dW/dt −0.934 t/s² (2-15 s; identical at 2400/4800/19200) | 0.6 % vs the J rate; κ-only estimate 11 % low (it leaves out δ and the tilt) |
| Middle egg standing (EG_STEPS 2400-38400) | should not depend on step | tilt at 3 s 4.84 / 4.88 / 4.91 / 4.90 / 4.73°; falling back 25.78 / 25.78 / 26.05 / 26.50 / 27.23 s | close, not tight (see caveats) |
| Jump threshold (Shimomura et al. 2006 observed jumps; README: "about 30 turns a second or faster") | — | 29 t/s: none; 30: 4 jumps (16.0 ms, 0.10 mm); 32: 9 (≤ 0.45 mm); 34: 14 (≤ 0.62 mm); same counts at 19200 | OK |
| Jumps at 40 t/s (README: 25 jumps, ≤ 0.6 mm, 21 ms) | measured real eggs: fractions of a mm, up to a few 10 ms | 25 jumps, 0.29-1.09 s, longest 21.3 ms, highest 0.59 mm | matches README |
| Jumps vs friction at 35 t/s (README: still jumps for μ 0.2-0.5) | — | μ = 0.2: 22 jumps; μ = 0.5: 9 jumps | OK |
| Raw egg: shared spin of shell + liquid | W0·I_s/(I_s+I_liq) = 5.49 t/s (I_s 0.0336, I_liq 0.1194) | κ = 0 at 1.2 s: shell 5.87, liquid 5.27 (moment-weighted 5.40, my calculation); default κ: 4.49 / 4.75 | κ = 0: −1.6 %. README says "nearly do", with these numbers |
| Raw egg re-spin after finger (κ = 0) | liquid's L shared: 3.40 t/s | 3.37 t/s (same at 9600 and 19200) | −0.9 % |
| Raw egg re-spin, default κ | README: "about half" | 1.43 vs 2.78 t/s | OK |
| Falls back (README: past 15° after 8 s, back on its side after 24 s under 3 t/s) | — | 7.97 s (18.5 t/s); 24.40 s (2.6 t/s) | OK |

**Run used**

```
cd demo/WyomingWill/SpinningEgg && HOLD_S=0 EG_STEPS={2400,4800,9600,19200,38400} EG_LOG=... timeout 3000 bpp -f spinning-egg.lua -n 1800   (also EG_STEPS=14400 -n 120; 76800 -n 600)
HOLD_S=0 EG_BALANCED=1 [EG_STEPS=2400|19200] ... -n 120;  EG_KAPPA=0 [EG_STEPS=9600|19200] -n 300;  EG_KAPPA=0 EG_SPIN={20,30} EG_STEPS={4800,9600,19200} -n 300
EG_KAPPA=0 EG_DELTA=0 EG_STEPS={2400,4800,9600} EG_LOG=... -n 600;  EG_FAST={26,28,29,30,32,34} -n 150 (30-34 also at 19200);  EG_FAST=35 EG_MU={0.2,0.5} -n 240
EG_TILT={3,3.5,4,5} EG_STEPS={2400,4800,19200[,9600,38400 for 3]} -n 300;  EG_SPEED={0.5,2} with EG_LOG (speed check)
HOLD_S=0 EG_STEPS={4800,19200} EG_STATE=1.0:state.txt -n 61; python3 reconstruction/rolling-check.py state.txt [0 0 10]
```
```
  Left   rising at  0.30 s (tilt 31 deg, spinning 25.2 turns/s)
  Left   standing on its end at  0.68 s (tilt 11 deg, spinning 25.2 turns/s)
         spinning 25.22 turns/s; by Jellett's J it should be 25.15 (J 48.59, from 49.87, 48.30 with spin friction: +0.60%)
         energy lost 41.88 microjoules; friction took 41.88, landings -0.00: 41.88 (0.00% apart)
         it rose from 60 to 30 deg in 0.261 s; by J dtheta/dt = mu M g h^2 (sliding) it should take 0.239 (+9.1%)
  Middle standing on its end at  1.22 s (tilt 4 deg, spinning 40.8 turns/s)
         it rose from 60 to 30 deg in 0.471 s; by J dtheta/dt = mu M g h^2 (sliding) it should take 0.384 (+22.7%)
         it jumped 25 times as it rose (0.29 to 1.09 s): longest 21.3 ms, highest 0.59 mm off the table
  Left   falling back at  7.97 s (tilt 15 deg, spinning 18.5 turns/s)
  Left   back on its side at 24.40 s (tilt 63 deg, spinning 2.6 turns/s)
  Middle falling back at 25.78 s (tilt 15 deg, spinning 18.7 turns/s)
  rolling-check.py: past 15 deg (as the console counts): 8.05 s, spinning 18.7 turns/s; back at 60 deg at 24.39 s; most friction needed: 0.855 of mu N
```
The default-run lines match the README's console sample digit for digit. Hall and standalone output IDENTICAL (cmp2.sh, 1800 frames, 22 run lines); HOLD_S=0 for 1200 frames is an exact prefix of the default 0.5 s pause for 1230 (28 lines). Speed: the hard-boiled eggs' EG_LOG rows are bit-identical at EG_SPEED 0.5, 1 and 2 at every common time; console lines are sampled on frames (and the finger acts on frames), so their times and values move by up to a frame with speed, as before. Cost (CPU, 1800 frames, measured while two other processes held both cores): 8.4-8.6 ms/frame standalone (the old step: 7.6), 13.6 ms/frame in the Cabinet with the egg; frame budget 16.7 ms. Default steps unchanged (4800).

**Known departures and honest caveats**
- The egg is a symmetric spheroid; a real egg is fatter at one end (README admits this).
- **Fixed on 17 Oct 2026: the standing phase depended on the step.**
  - Before, at 2400 / 4800 / 9600 / 19200 / 38400 steps/s: tilt at 3 s 1.8 / 4.5 / 7.3 / 9.3 / 10.5°; falling back at 23.4 / 22.3 / 20.6 / 17.6 / 13.9 s; on its side 26.5 / 26.1 / 25.7 / 25.2 / 24.8 s.
  - Cause: Bullet's update makes the step a leapfrog. The velocities after the kick live at the half step, but no-slip (and the normal velocity) was imposed at the start-of-step lowest point. Rolling, the contact runs round the egg at the spin rate, so each step left an O(h) slip.
  - Two further first-order pieces showed up once that was fixed. First, the gyroscopic term was taken at the pre-step w. With κ = δ = 0 the energy then grew +8.7 / +4.4 / +2.2 µJ in 9 s at 2400 / 4800 / 9600; the implicit midpoint removes this. Second, spin friction and rolling resistance were applied after the no-slip solve. Moving them into the solve was harmless but is kept for consistency.
  - The earlier attempt (contact at the mid-step orientation, lever arm also there) was reproduced: 60° → 30° in 0.238 s at 4800, 0.243 at 2400. It is not time-symmetric; the adopted step puts the lever arm at the start of the step.
  - Converged by Richardson-style comparison and by an independent double-precision rolling integration (table).
- **Changed friction law (17 Oct 2026).** The old solver clamped the stick impulse radially to μN, so in the limit h → 0 friction pointed along −K⁻¹·slip, not −slip, with K the anisotropic contact mass matrix. That is not Coulomb's law. Friction now opposes the slip, taken at the time of the kick. The rise check moved from 0.259 vs 0.240 (+8.2 %) to 0.261 vs 0.239 (+9.1 %), and the middle egg from +22.0 % to +22.7 %. The rise is converged with the new law: tilt at 0.5 s is 36.48 / 36.54 / 36.60 / 36.61 / 36.62° at 2400 / 4800 / 9600 / 19200 / 38400.
- **The energy budget is now an exact identity** (work = impulse · step-mean velocity, and the gyroscopic step conserves energy exactly). Its 0.00 % shows the integrator makes or loses no energy besides friction; it no longer measures the step error as it did before.
- **Single-precision floor.** Bullet stores the state as floats. Above about 20000 steps/s the rounding accumulates with the number of steps. Against the double-precision reference (17.08-17.10° at 10 s) the tilt is off by +0.01° at 19200, −0.05° at 38400 and −0.15° at 76800. It is not the position: the same with all dishes at x = 0. So 38400 gives falling back at 8.15 s instead of 7.97.
- **Middle egg standing phase** agrees less tightly. Falling back is 25.8 s at 2400-4800, 26.1 at 9600, 26.5 at 19200 and 27.2 at 38400. Its 25 inelastic landings leave the standing state slightly different (tilt at 1 s 28.8-29.3°), and the float floor adds to it at the finest steps. Not investigated further.
- **"Falling back" is a 15° threshold on a slow lean.** The egg never stands still and then falls. It stops rising at 11° (rolling: the rise needs sliding) and leans steadily as it slows. The console's 15° and 60° crossings, debounced 0.25 s on frames, carry the nutation (±0.5°) in them: the reference crosses at 8.05 s against the exhibit's 7.97.
- The upright rolling egg would be gyroscopically stable above about 5.8 t/s. That is my calculation, bisecting simulations of the same rolling equations from upright with a 0.5° kick. The frictionless-table condition C²n² > 4 A M g (a − b²/a), from memory, gives 9.5 t/s. The egg never stands upright, though, so neither is a fall-back prediction. The lean is a slow drift of the rolling motion as J falls, which the rolling reference reproduces.
- Similar consequences of rolling once standing:
  - at 20 t/s with κ = 0 the left egg stops rising at about 18° and never "stands" (< 15°), identically at 4800 and 19200 (before: 1.25 s at 4800, 2.13 s at 9600, never at 19200);
  - at μ = 0.5 the left egg stops at about 17° (before: "standing" 0.72 s at 13°).
- Start tilt (fixed 15 Oct, now re-measured): from 3° the left egg never rises at any step from 2400 to 38400 (converged; before it rose at 0.50-2.45 s depending on the step). At 3.5° the onset is still step-sensitive, 0.38 / 0.38 / 0.42 s at 2400 / 4800 / 19200, because 3.5° is at the stick/slip edge. From 4°: 0.35 s at every step. The default 6° rises at 0.30 s.
- The rise-rate check: the left egg rises 9 % slower than Moffatt-Shimomura's leading-order balance. The gap is the nutation from starting with pure spin about the vertical; started in balance it is 2.5 %. The middle egg is 23 % slower (6 % from balance); it jumps throughout its rise.
- Jellett's J is only approximately conserved (0.6-1.3 % change). The prediction is corrected for the J removed by spin friction, rolling resistance and the rim (the console calls the sum "spin friction"). The bare prediction is 26.00 t/s.
- Spin friction κ and rolling resistance δ (100 µm each) are chosen parameters. κ sets how fast the egg slows and so when it is back on its side.
- The contact is a sequential-impulse solver, not an exact unilateral constraint; landings are perfectly inelastic. The dish rim's contact still uses the lowest point at the step's start (first-order). The left and middle eggs never touch it in the default run.
- The raw egg's liquid is a two-rotor model (added inertia plus a linearly coupled rotor, τ = 1.5 s, assumed). Its finger acts on frames, so its numbers move slightly with EG_SPEED.

**References**
- Cited in the README:
  - H. K. Moffatt and Y. Shimomura, "Spinning eggs — a paradox resolved", Nature 416, 385 (2002).
  - Y. Shimomura and colleagues, Proc. R. Soc. A (2006), on spinning eggs jumping; reported in Science News, 23 May 2006, "Well-spun egg also jumps".
  - R. McLachlan and M. Perlmutter, "Integrators for nonholonomic mechanical systems", J. Nonlinear Sci. (2006), doi 10.1007/s00332-005-0698-1: reversible integrators for rolling-type constraints, with energy error that random-walks rather than drifts.
  - K. Modin and O. Verdier, "What makes nonholonomic integrators work?", Numer. Math. 145, 405-435 (2020): reversibility, through reversible KAM theory, explains the near-conservation.
- Not cited in the README:
  - The rise equation J dθ/dt = −F h² and the balance C n = A Ω cos θ, as restated in K. Sasaki, "Spinning eggs — which end will rise?", arXiv:physics/0310163 (eqs. 7, 9-11).
  - From memory, not checked: the integrability of a rolling body of revolution (Chaplygin), e.g. A. V. Borisov and I. S. Mamaev, Regul. Chaotic Dyn. 7, 177 (2002); and the frictionless-plane stability condition quoted above.
