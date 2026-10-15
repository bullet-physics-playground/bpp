## The Bicycle Wheel

**What it shows** — A wooden lay figure on a swivel stool, feet off the floor, holds a spinning bicycle wheel with its axle upright; the stool is still. Turning the wheel over makes the stool turn the other way; turning it back stops the stool. Pushing the wheel out to arm's length slows the stool, pulling it in speeds it up again (the figure-skater effect). Nothing pushes on the floor: it is angular momentum about the stool's axis being shared between wheel and figure.

**Model** — Three Bullet rigid bodies (code, README):
- Stool seat + figure: one body, 75 kg, I = 15000 kg cm^2 (1.5 kg m^2) about the stool axis, on a vertical btHingeConstraint to a fixed anchor; bearing friction 0.02 N m (slider `stool friction`, applied by the script as a saturated torque).
- Hands: 1 kg, I = 100 kg cm^2, on a btSliderConstraint straight out in front, motor-driven between 34 cm (close) and 50 cm (out) in 1.5 s (smoothstep path + proportional correction, gain 40).
- Wheel (axle + handles): 3 kg, I = 1150 kg cm^2 about the axle (0.115 kg m^2), 600 across; hinged to the hands along the slide axis; a hinge motor turns it over in 1.2 s.
- The wheel's spin is not a Bullet rotation: it is a scalar angular momentum h = I3·S carried inside the body (a gyrostat). Bullet's gyroscopic term is off (setFlags(0)); the script applies the gyroscopic torque -w x (I w + h) each step, 2nd-order Adams-Bashforth (1.5·T_n - 0.5·T_(n-1)). The hinge reaction to that torque is what turns the stool.
- Wheel bearing friction 0.02 turns/s per second; the lost spin is handed to the axle as torque.
- 1200 physics steps/s (20 per 1/60 s frame), 30 solver iterations, no damping, gravity 981 cm/s^2 (irrelevant to the physics shown).
- The "should" value printed after each move is computed in Lua: (L0 - I3·S·(axle·up)) / (I_P + (m_w+m_hands)·d^2 + I_w,eff + I_hands), with L0 = total angular momentum about the stool axis when the move started.

**Theory checks**

Spin 4 turns/s: h = 0.115 x 2pi x 4 = 2.890 kg m^2/s. I_close = 1.5 + 4 x 0.34^2 + 0.115 + 0.010 = 2.087 kg m^2; I_out = 1.5 + 4 x 0.50^2 + 0.115 + 0.010 = 2.625 kg m^2 (hand calculation from code constants; README quotes 2.09 and 2.63).

| Quantity | Theory (formula / source) | Simulation (this run) | Agreement |
|---|---|---|---|
| Stool rate, wheel turned over, held close (no friction) | w = 2h/I_close = 2 x 2.890/2.087 = 2.769 rad/s | 2.769 (first round); 2.770 later rounds | 0.000 / +0.001 rad/s (<0.04%) |
| Stool rate, pushed out (no friction) | w = 2h/I_out = 2.202 rad/s | 2.202 | 0.000 |
| Stool rate, pulled back in (no friction) | 2.769 rad/s | 2.769 (2.770 later) | <0.04% |
| Stool rate, axle up again (no friction) | 0 | 0.000 (0.001 in rounds 5-6) | <=0.001 rad/s |
| Angular momentum about stool axis (no friction, 120 s, 6 rounds) | conserved; README: "within 0.1%" | max deviation 0.093%, end +0.050% (from BW_LOG) | within README bound |
| Stool rate vs console "should", defaults (friction on), 24 moves | console theory from L at move start | turned over 2.719 vs 2.736 ... 1.136 vs 1.152; out 2.099 vs 2.114; in 2.565 vs 2.584; up -0.021 vs -0.018 | sim 0.015-0.020 rad/s below (0.6-1.4%), as README predicts (~0.02 rad/s friction during move) |
| README friction sequence, turned over & close | README: 2.72, 2.46, 2.19 rad/s | 2.719, 2.456, 2.192 | matches |
| README frictionless table | README: 2.769 / 2.202 / 2.769 / 0.000 | 2.769 / 2.202 / 2.769 / +0.000 | matches |

**Run used**
```
cd demo/WyomingWill/BicycleWheel
HOLD_S=0 BW_STOOLF=0 BW_WHEELF=0 BW_LOG=bw0.csv bpp -f bicycle-wheel.lua -n 7200   # frictionless
HOLD_S=0 BW_LOG=bw.csv bpp -f bicycle-wheel.lua -n 7200                            # defaults
```
Frictionless:
```
t=  3.7s  wheel turned over (34 cm out): the stool turning at +2.769 rad/s (0.44 turns/s); it should, by its angular momentum: +2.769
t=  8.5s  wheel pushed out (50 cm out): the stool turning at +2.202 rad/s (0.35 turns/s); it should, by its angular momentum: +2.202
t= 13.0s  wheel pulled in (34 cm out): the stool turning at +2.769 rad/s (0.44 turns/s); it should, by its angular momentum: +2.769
t= 17.3s  wheel axle up again (34 cm out): the stool turning at +0.000 rad/s (0.00 turns/s); it should, by its angular momentum: +0.000
t=118.1s  wheel turned over (34 cm out): the stool turning at +2.770 rad/s (0.44 turns/s); it should, by its angular momentum: +2.770
```
Defaults:
```
t=  3.7s  wheel turned over (34 cm out): the stool turning at +2.719 rad/s (0.43 turns/s); it should, by its angular momentum: +2.736
t= 17.3s  wheel axle up again (34 cm out): the stool turning at -0.021 rad/s (0.00 turns/s); it should, by its angular momentum: -0.018
t= 22.8s  wheel turned over (34 cm out): the stool turning at +2.456 rad/s (0.39 turns/s); it should, by its angular momentum: +2.472
t= 41.8s  wheel turned over (34 cm out): the stool turning at +2.192 rad/s (0.35 turns/s); it should, by its angular momentum: +2.208
```
Angular-momentum figures (0.093%, 0.050%) were computed from the L_up column of the BW_LOG csv; no NaN appeared in either 120 s run.

**Known departures and honest caveats**
- The "theory" column the console prints is computed by the script from the simulated state at the start of each move; it is an internal consistency check (angular momentum bookkeeping), not an independent prediction. The independent hand calculation (2.769, 2.202 rad/s) agrees with it in the frictionless case.
- With friction on (defaults) the stool lags the console "should" by 0.015-0.020 rad/s because friction during the 1.2-1.5 s move is not accounted for (README says so). Total angular momentum falls 60% over 120 s in the default run; that is the stool bearing and wheel bearing, by design (the spin drops from 4.0 to 1.6 turns/s).
- After "axle up again" with friction on, the stool shows -0.021 rad/s rather than 0: the friction-induced residual.
- Mass properties are idealised: the figure+stool is one rigid body with a fixed 1.5 kg m^2; the arms are drawn only (the 1 kg "hands" body stands in for them); the wheel's inertia (0.115 kg m^2) and 600 kg cm^2 transverse are chosen, not derived from the mesh. The wheel's spin is a gyrostat number, not a rotating Bullet body.
- The gyroscopic torque is explicit (Adams-Bashforth); the agreement shown is at the default 1200 steps/s; no step-size study is documented.
- Open issue (user report, not reproduced): a user saw the bicycle wheel go to NaN once in the GUI after visiting the solar system exhibit in the hall (Cabinet). It could not be reproduced headless; the 7200-frame default run on 15 Oct 2026 was NaN-free too. Cause still unknown (the Cabinet prefixes each exhibit's sliders, so the solar system's settings are not shared with this exhibit). Guard added 15 Oct 2026: after every frame the script checks the positions, velocities and angular velocities of the stool, wheel and hands bodies, and the wheel's spin, angle, arm angle and slide distance; if any is not finite it prints one console line ("t=...s  ** NOT A NUMBER: the simulation broke down (going by itself, move N, last move: ...; wheel ... cm out, spinning ... rad/s, turned ... rad; steps, speed, step); stool at (...) moving (...) turning (...); wheel ...; hands ... -- starting again") and restarts the run cleanly. Tested by injecting a NaN into the wheel's angular velocity at t = 5 s in a scratch copy: the line was printed, the run restarted, and the restarted run's first report (t = 3.7 s, +2.719 / +2.736) was identical to a fresh start. Also: the bearing-loss term IW3·d/h is now skipped if the step h were ever 0 (it would be 0/0); this does not occur in normal use and is not claimed to be the cause.
- Fixed on 15 Oct 2026: pressing R mid-move used to print a stray "wheel turned over ..." line about 1.7 s into the new run (the cut-off move's pending report, with the restarted clock). restart() now clears the pending report; tested by forcing a restart at t = 2.5 s, mid-turn, in a scratch copy: no stray line.
- Checks after these changes: default 7200-frame run gives console output byte-identical to the previous version of the script (27 lines); hall identity cmp2.sh "the bicycle wheel" 2400 frames: IDENTICAL (8 run lines); pause check 2400/2430 frames: prefix OK (10 lines).

**References** — None cited in the README or code. The physics is the standard textbook "rotating stool and bicycle wheel" demonstration of angular momentum conservation.
