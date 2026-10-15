## Newton's Cradle

**What it shows** — Five steel balls hang in a row on V-threads. Lift one, two or three and let go: the same number fly out at the far end. Because the balls touch, a strike is a compression pulse through the row rather than a chain of two-ball collisions, so the far ball does not get quite everything; the row breaks up and, over a few minutes, ends up swinging together. With a 0.1 mm gap (key `G`) each strike becomes a clean one-in, one-out sequence.

**Model** — Balls: rigid spheres, 25 mm diameter, 64 g (code: rho 0.00785 kg/cm^3, 64.2 g computed), centres 15 cm below the thread tops. Each ball is a Bullet rigid body on a `btHingeConstraint` to a static anchor (it swings in the row's plane and turns with its threads); Bullet collisions are off (`collides = false`), solver iterations 40, Bullet damping 0. Bullet steps at 2400 /s (slider 1200-9600). Strikes are done by the script before every physics step: any pair pressed together, or predicted to touch within the step, is integrated with each ball moving along its own swing (the contact force along the line of centres, projected on each ball's swing tangent; inertia along the swing m(1 + 2/5 r^2/L^2), since the ball turns with its threads), with Hertz forces F = K d^(3/2), K = 4/3 E* sqrt(R/2), E* = E / (2(1 - nu^2)), E = 200 GPa, nu = 0.3, times a Hunt-Crossley factor (1 + 1.5 alpha v), alpha = 0.25 x 0.0012 s/cm (a quarter of Hunt-Crossley for steel). Integrator: velocity Verlet, sub-steps <= 0.25 us; each ball is handed back to Bullet on its hinge circle, turned with its threads, with velocity W along its swing tangent and angular rate W/L (so the hinge solver has nothing to correct), placed so Bullet's step ends where the row had it. A squeeze still held at the end of a step is carried into the next step through the positions and worked out there. Knocks with |dv| < 3 cm/s are not counted as strikes. Clack sound is pre-synthesised by `make-sounds.py` (same Hertz strike at 20 ns steps, rigid-sphere dipole radiation with the h2 spherical Hankel function, table image at 0.85, 48 kHz) — not run here because it rewrites `cradle-sounds/`.

**Theory checks**

| Quantity | Theory (formula / source) | Simulation (this run) | Agreement |
|---|---|---|---|
| Two-ball contact time at 62.7 cm/s | Hertz: 2.87 (m^2/(R E*^2 v))^(1/5), m,R reduced: 84.2 us | 84.2 us (script's own 2-ball integration) | exact to 0.1 us |
| Restitution of two-ball strike, damping 0.25 | design target 0.982 (README) | 0.982 (1.000 with NC_DAMP=0) | matches |
| Time to first strike | quarter period of physical pendulum, I = m(L^2 + 2/5 r^2), elliptic K, 30 deg: 0.1979 s (I reproduced 0.19789 s independently) | 0.1975 s (2400 steps); 0.1977 s (3000, 4800); 0.1978 s (7200, 9600); 0.1967 s (1200) | -0.4 ms = one step (README says so) |
| Energy in first strike, no damping | conserved: 100% | 100.0% (touching); 100.0% (gap) | 0.0% |
| Momentum along row, first strike | conserved | 0.00% off | exact |
| Touching row, no damping: speeds after | README: -4.5, -1.9, -0.9, 8.0, 62.0 cm/s | -4.5, -1.9, -0.9, 8.0, 62.0 | identical |
| Touching row, damping 0.25: speeds after | README: -4.1, -1.6, -0.6, 8.5, 60.4 cm/s; energy 95.3% | -4.1, -1.6, -0.6, 8.5, 60.4; 95.3% | identical |
| Gap 0.1 mm, no damping | README: 62.7 out, others < 0.05 cm/s | 0.0, -0.0, -0.0, -0.0, 62.7; energy 100.0% | identical |
| Gap 0.1 mm, damping 0.25 | four two-ball strikes at e = 0.982: each striker keeps (1-e)/2 x 62.7 = 0.56 cm/s, out 62.7 x 0.991^4 = 60.5 | 0.6, 0.6, 0.6, 0.5, 60.5; energy 93.0% | matches |
| Ball 4's share of incoming momentum | Herrmann & Seitz 1982 five-ball simulation: ~12% (README) | 8.5/62.7 = 13.6% (README says 14%) | +1.6 points; same pattern (1-3 back, 4-5 forward) |
| Row merges to swinging together | Hutzler et al. 2004: 1-2 min on real cradles (README) | 1 ball, 30 deg, auto off, 7 min run: together swing 5.2 deg; largest ball's swing about the row's mean falls below 1/2 of it at ~80 s, 1/5 at ~3 min, 1/10 at ~6.5 min (1200 and 9600 steps/s agree to a few s); energy 32% at 15 s, 19% at 1 min, then 16.6% (the together swing). Damping 0: never merges (relative swing ~24 deg after 3 min), energy kept to 1.5% | same scale as real cradles, somewhat slower; set by the contact damping alone (README says so) |
| Clack peak at listener, 60 cm/s | README (make-sounds.py console): 2.7 Pa, 103 dB, peak ~ speed^1.48 | not run | README only |
| Step-size convergence of first strike | should be independent of step | 1200, 2400, 3000, 4800, 7200, 9600 steps/s: -4.1 -1.6 -0.6 8.5 60.4-60.5 cm/s, energy 95.3-95.4%; NC_DAMP=0: -4.5 -1.9 -0.9 8.0 62.0, energy 100.0% (100.2% at 1200, over a 1.7 ms window with gravity acting) | converged (fixed 15 Oct 2026) |

**Run used**

```
cd demo/WyomingWill/NewtonsCradle && HOLD_S=0 timeout 1500 ../../../release/bpp -f newtons-cradle.lua -n 3600 | grep -v ALSA
  (plus -n 900 / -n 40 runs with NC_DAMP=0; NC_GAP=0.01; NC_GAP=0.01 NC_DAMP=0; NC_STEPS=1200,2400,3000,4800,7200,9600 each with
   and without NC_DAMP=0; settling: a scratch copy of the exhibit with the auto-lift off and each ball's angle and the total
   energy logged every frame, 1 ball, 25200 frames at 2400/s, 14400 at 9600/s, 7200 at 1200/s, 10800 with NC_DAMP=0)

    two balls meeting at 62.7 cm/s: they touch for 84.2 microseconds (Hertz: 84.2); they part at 0.982 of it
  strike  1 at  0.197 s: speeds before   62.7    0.0    0.0    0.0    0.0
                               after    -4.1   -1.6   -0.6    8.5   60.4 cm/s; energy 95.3%; momentum along the row 0.00% off ...
                    0.1975 s after letting go; a quarter swing from 30 degrees takes 0.1979 s
  [NC_DAMP=0]  after    -4.5   -1.9   -0.9    8.0   62.0 cm/s; energy 100.0%; momentum along the row 0.00% off
  [NC_GAP=0.01 NC_DAMP=0]  after     0.0   -0.0   -0.0   -0.0   62.7 cm/s; energy 100.0%
  [NC_GAP=0.01]  after     0.6    0.6    0.6    0.5   60.5 cm/s; energy 93.0%
  [1 ball] strike 90 at 13.425 s: ... after    22.8    4.6    5.8    6.9   12.3 cm/s; energy 119.1%; momentum 7.52% off (over 14.2 ms)
  [3 balls] strike 240 at 14.775 s: ... after   -20.4  -41.1  -16.5  -43.7  -45.4 cm/s (still not swinging together at 15 s)
  [NC_STEPS=9600]  after    -4.1   -1.6   -0.6    8.5   60.4 cm/s; energy 95.3%; momentum along the row 0.00% off
  [NC_STEPS=1200]  after    -4.1   -1.6   -0.6    8.5   60.5 cm/s; energy 95.4%; momentum along the row 0.01% off
```

**Known departures and honest caveats**
- Fixed 15 Oct 2026: **step-size failure at 9600 steps/s** (first strike kept 66.8% of the energy, ball 4 left at 22.6 cm/s; 6000 steps/s with no damping also failed, 84.4%). Cause: the "touching" test only asked whether a pair would be pressed at the end of the step if it moved freely (gap - closing speed x h < 0). A contact still squeezed but already opening (at 9600/s the pulse straddles steps: ball 4-5 still squeezed 14 um at a step boundary, separating at 23 cm/s) was predicted "open", so the next step skipped the strike and Bullet simply let the balls fly apart through each other, throwing the stored squeeze away. Now a pair is worked out if it is pressed now or will be within the step. A second, smaller error came from the hand-back: balls were moved along x without turning them on their hinges, and the hinge solver's correction shifted squeezes of ~15 um by 10-50 nm between steps (0.1-0.3% of a strike's energy); and strikes at a swing angle were worked out along x with mass m, then projected by the hinge onto the swing, which made or lost energy by ~angle^2/2 per strike (with damping 0 the energy wandered by +-10% over a minute after the first fix alone); now each ball is handed back on its hinge circle, turned, with velocity along its swing, and the row is worked out along each ball's swing with its inertia m(1 + 2/5 r^2/L^2). The default first strike moved from 60.477 to 60.450 cm/s for ball 5 (shown 60.5 -> 60.4; README updated).
- Fixed 15 Oct 2026: **settling time**. The same lost squeezes, through many later strikes, drained the energy: with NC_DAMP=0 the old code lost 59% of the energy by 5 s and 81% by 20 s, and the row "merged" in ~15 s whether damped or not. That fast merging was the bug. Now with damping 0 energy is kept to 1.5% over 3 min and the row never merges; with the default damping it merges over minutes (table). The README's "Why the balls part" now gives the measured times and says the rate is set by the contact damping alone (a quarter of Hunt-Crossley, chosen for the 0.982 two-ball restitution, not tuned to Hutzler); a real cradle also has air, thread and alignment losses that the model lacks, so the near-agreement with 1-2 min is not a test of the model.
- Late "strikes" in long runs report energy 58-126% and momentum up to ~105% off; these are windows of 10-40 ms of repeated contact in which gravity and the threads act, so the per-strike bookkeeping is not a conservation test there.
- By itself the exhibit relifts every 15 s, so the settling is only seen with `A` off.
- Ball 4 gets 13.6% of the incoming momentum versus Herrmann & Seitz's ~12%: same pattern, not the same number.
- Threads are a hinge, so out-of-plane swinging and thread stretch are absent; the threads are drawn only.
- Sound: README numbers only (not regenerated; files unchanged, md5 checked). Fixed 15 Oct 2026: `make-sounds.py`'s docstring said the loudest file was "four balls at 120 cm/s"; its speeds stop at 100 and the files show clack-n1-v100.wav peaks at 0.95 (n2-v100 0.62, n1-v60 0.56), so it now says "one ball at 100 cm/s".
- Checks after the fix: hall vs standalone (cmp2.sh newton, 1500 frames): IDENTICAL (59 run lines); pause: HOLD_S=0 -n 840 is a prefix of the default -n 870 (30 of 30 lines), and -n 1200 of -n 1260 across the 15 s relift (52 of 52).

**References**
- H. Hertz (contact law, contact-time formula 2.87(...)^(1/5)) — cited by name.
- K. H. Hunt and F. R. E. Crossley (contact damping) — cited by name.
- F. Herrmann and M. Seitz (1982), five-ball simulation of the cradle (README; journal not given).
- E. J. Hinch and S. Saint-Jean (1999), break-up of a line of balls (README).
- S. Hutzler, G. Delaney, D. Weaire and F. MacLeod, "Rocking Newton's cradle", Am. J. Phys. 72 (2004).
