## The Brazil-Nut Effect

**What it shows** — Three glass-fronted boxes, each holding a one-bead-thick layer of beads, are shaken vertically at 7 Hz. Shaken gently (peak 0.8 g), the bed never leaves the floor and nothing happens. Shaken hard (3 g), a big bead starting at the bottom rises to the top and stays there. A small coloured bead in the third box rises too, then sinks again by a wall and circulates. This shows the convection rolls (up in the middle, down by the walls) that Knight, Jaeger and Nagel identified as the mechanism.

**Model** — Bullet does everything here; the script adds no custom contact or integration.
- Beads: 140 glass spheres per box (density 0.0025 kg/cm^3), radius 0.5 cm with a deterministic +/-5% spread (BN_POLY = 0.1), big bead radius 1.5 cm. All locked to the x-y plane (linear factor (1,1,0), rotation about z only). btSphereShape, so contacts are exact sphere-sphere and sphere-box.
- Friction and bounce: each body has its own (beads 0.8 and 0.1, box 1.0 and 0.1), and Bullet multiplies the pair's values. Effective: friction 0.64 bead-bead, 0.8 bead-wall and bead-floor; restitution 0.01 everywhere. (Before 16 Oct 2026 the README gave the per-body values as if they were the effective ones.)
- Box: a 1e4 kg compound body (floor plus two walls, 15 cm wide inside, 24 cm tall) with its own gravity off. Its position and velocity are set to y = A sin(wt) before every physics step. The front and back glass are not colliders; the planar constraint stands in for them.
- Shaking: f = 7 Hz, A = Gamma g / w^2: 4.1 mm for Gamma = 0.8, 15.2 mm for Gamma = 3.
- Stepping: 2400 steps per second, 20 solver iterations (BN_STEPS, BN_ITER), Bullet's default contact ERP 0.2 and split impulse. Beads settle for 0.5 s before shaking. Re-poured every 90 s.
- Measurement (changed 16 Oct 2026): the floor's push on the bed is taken from the bed's own momentum, (P_after - P_before)/dt + W, every step in shakes 5 to 32, binned by phase in 2-degree bins. W now includes the big or coloured bead. The bed's centre-of-mass velocity relative to the floor is binned the same way. Before, the push came from the change in the 1e4 kg box's velocity, which in single precision is quantised at about 0.85 W per step. W also left out the big bead, and the average stopped at shake 9.75 although the text said shake 12.

**Theory checks** (seed 7 is the README's; seed 8 as a second pour)

| Quantity | Theory (formula / source) | Simulation, seed 7 | Seed 8 | Agreement |
|---|---|---|---|---|
| Amplitude | A = Gamma g / (2 pi f)^2 | 4.1 mm, 15.2 mm | same | exact (definition) |
| Gamma = 0.8: bed stays on floor | min push = (1 - Gamma) W = 0.20 W (rigid bed) | never left; min 0.19 W | 0.18 W | 0.01-0.02 W low |
| Gamma = 3: when the bed has landed (CoM stops descending relative to floor) | rigid, perfectly inelastic bed (Mehta and Luck 1990): lands at 1.4 deg, rests until 19.5 | middle, right: 42-44, 42-44 deg; still descending at 11 and 12 cm/s at 18-20 deg | 38-40, 42-44 | **Departs from the rigid model.** The bed flies dilated and lands bottom-up, as real layers do (Bougie et al. 2002; Pastor et al. 2007). Landing ends at 38-44 deg at every step rate tried (2400 to 9600 per s) |
| Gamma = 3: lift-off phase | arcsin(1/Gamma) = 19.5 deg if the bed has landed by then; otherwise as soon as it has landed | 48-50, 44-46 deg | 44-46, 46-48 | 2-6 deg after landing at the default |
| Lift-off convergence (seed 7, seed 8; middle, right) | stiff limit should stop changing | 2400/20: 48,44 / 44,46; 2400/50: 44,44 / 40,42; 3600/30: 38,38 / 42,44; 4800/20: 36,38 / 40,42; 9600/20: 42,36 / 42,42; also 2400/100: 42,44; 4800/50: 40,42; 4800/100: 36,40; 9600/50: 44,36 (seed 7) | | Converged at 4800 steps/s and above: 36-44, mean 40 (scatter +/-3 between pours and bins), equal to the landing end. Default 46 on average: **about 6 deg numerical, about 20 deg the landing** |
| Lift-off vs bounce and friction (4800/20, seed 7) | — | restitution 0: 42, 40; friction 0.09: 44, 44; restitution 0.95 (glass): the bed never settles (push never below 0.2 W) | | insensitive to bounce 0-0.01 and to friction; glass-like bounce fluidises the bed in Bullet |
| Big bead rises | qualitative (Knight et al. 1993) | 6.3 s (44 shakes), rose 8.4 cm | 21.4 s (149 shakes) | yes. **Not step-converged:** 4800/s 11.9 s; 9600/s 43.6 s; seed 8 at 4800/s not up within 60 s |
| Big bead stays up | qualitative | upper half 77% | 91% | yes |
| Convection, middle box | rise in middle, fall at walls | +5.5 / -10.1 mm/s | +4.8 / -9.5 | right sign. **Speed not converged:** 4800/s +3.2 / -8.0 (seed 8: +2.2 / -6.3); 9600/s +2.4 / -6.0 |
| Convection, right box | same | +7.8 / -12.9 mm/s | +7.1 / -12.5 | right sign; 4800/s +5.3 / -9.9; 9600/s +4.9 / -8.5 |
| Coloured bead circulates | up nearer the middle, down nearer the walls | 4 round trips; up 3.6 cm, down 4.6 cm from centre | 4; 2.6 / 3.4 cm | yes (4800/s: 1 trip) |
| Coloured bead reaches top | qualitative | 11.6 s (81 shakes), 8.9 cm | 12.7 s (89 shakes), 9.3 cm | yes |

The push profile at the default (seed 7, middle box): about 6-9 W from 336 to 0 deg (the landing), 2.6 W at 18-20 deg, 0.4 W at 36-38, below 0.1 W from 48. At 4800/s: 1.1 W at 18-20, 0.08 W at 36. The CoM approach speed at 18-20 deg is 11 cm/s at 2400/s and 7 cm/s at 4800/s (scratch copy that printed the bins). Separately (scratch, box-based measure, 2400/20): the lowest beads touch the floor at 322-342 deg, with the bed's CoM 0.5-1.3 cm above its packed height.

**Cost** (this machine, 2 cores, shared). Default: 31-35 ms per frame standalone and 37-39 ms in the hall after the measuring window. Both are about 2x the 16.7 ms a 60 fps frame has. The new per-step momentum sum adds a few ms per frame during the 4 s window (shakes 5-32). Relative to the default: 2400/50 x1.33; 3600/30 x1.6; 4800/20 x1.8-1.9; 9600/20 about x4-5.

**Run used**

```
cd demo/WyomingWill/BrazilNut && HOLD_S=0 timeout 3000 ../../../release/bpp -f brazil-nut.lua -n 3700
  (and BN_SEED=8; BN_STEPS=4800, 9600; BN_ITER=50 with -n 3700; the grid above with -n 310)
```
```
  Left   Gamma 0.8: the bed never left the floor (the floor's push never less than 0.19 of its weight; a rigid bed's: 0.20)
  Middle Gamma 3.0: the bed leaves the floor 48 to 50 degrees into the upswing (a rigid bed: arcsin 1/Gamma = 19.5);
         it can't till it has landed: at 18 to 20 degrees its middle is still coming down (11 cm/s); landed at 42 to 44
  Right  Gamma 3.0: the bed leaves the floor 44 to 46 degrees into the upswing (a rigid bed: arcsin 1/Gamma = 19.5);
         it can't till it has landed: at 18 to 20 degrees its middle is still coming down (12 cm/s); landed at 42 to 44
  Middle the big bead reaches the top at 6.3 s (44 shakes), having risen 8.4 cm
  Right  the coloured bead reaches the top at 11.6 s (81 shakes), having risen 8.9 cm
  Middle from 5 s to a minute: beads in the middle rising 5.5 mm/s on average, beside the walls falling 10.1 mm/s
  Right  from 5 s to a minute: beads in the middle rising 7.8 mm/s on average, beside the walls falling 12.9 mm/s
```
The README's console block matches this run. Hall against standalone (cmp2.sh, 900 frames): IDENTICAL (7 run lines). HOLD_S=0 for 400 frames is a prefix of the default pause for 430 frames (10 lines). BN_SPEED=0.25 (1250 frames): 50-52 / 42-44 deg, landed 42-44 / 42-44, the same as real time within the scatter. The trajectories differ bit for bit, as before, because the frame time accumulates differently.

**Known departures and honest caveats**
- **The 19.5 deg comparison was the wrong theory for this bed** (fixed 16 Oct 2026). arcsin(1/Gamma) is when a bed *resting* on the floor leaves it. This bed is still landing then: it lands dilated, bottom-up, and its CoM only stops descending at about 40 deg, at every step rate. The console now prints both. The 15 Oct 2026 conclusion, "mostly Bullet's soft contacts, 28-30 deg at 9600/s + 60 iterations", came from 4.75-shake averages with the quantised box measure. With 28-shake averages, two pours and the momentum measure, the stiff limit is about 40 deg. Only about 6 deg of the 27 is numerical.
- **The default is not the converged setting.** 2400/20 leaves about 6 deg late. The converged setting, 4800/20, costs about 1.9x the default, and the default is already about 2x over the 60 fps budget here, so the default stays. The slider reaches 4800.
- **Convection speed and rise time are not step-converged.** Middle-box rise in the middle: 5.5 mm/s at 2400/s, 3.2 at 4800/s, 2.4 at 9600/s, still falling. Big-bead rise: 6.3 s, 11.9 s, 43.6 s. The default's softer contacts roughly double the rolls' speed. Direction and pattern are robust.
- **Not glass.** Real glass-glass impacts give e about 0.92-0.97 and mu about 0.05-0.18 (Cornell impact table, 3 mm spheres; Foerster et al. 1994). The exhibit's effective e = 0.01 and mu = 0.64/0.8 were found by trying. With e = 0.95 the bed never settles in Bullet, which applies restitution to every contact closing faster than 0.2 cm/s, every step (btSequentialImpulseConstraintSolver::restitutionCurve; m_restingContactRestitutionThreshold is unused). That is a Bullet limitation, not glass behaviour.
- **The rise time depends strongly on the pour:** 6.3 s for seed 7, 21.4 s for seed 8.
- A 2-D bed (one bead thick) with high wall friction drives the wall-shear convection. A real 3-D jar has other mechanisms (percolation, void filling, inertia).
- The box is a kinematic driver, not a dynamic shaker. Each pour is deterministic for a given BN_SEED.
- What Lua cannot reach: bpp exposes setErp/setErp2/setCfm/setTau/setSolverIterations. It does not expose split impulse, its threshold (-0.04 world units = 0.4 mm here, so most bead penetrations are corrected by Baumgarte velocity), warm starting, solver mode or setContactStiffnessAndDamping. ERP2 0.05 changed nothing (48, 44); ERP2 0.8 made the lift-off later (60, 50).

**References**
- J. B. Knight, H. M. Jaeger, S. R. Nagel, Phys. Rev. Lett. 70, 3728 (1993) (README).
- A. Mehta, J. M. Luck, "Novel temporal behavior of a nonlinear dynamical system: the completely inelastic bouncing ball", Phys. Rev. Lett. 65, 393 (1990).
- J. Bougie, S. J. Moon, J. B. Swift, H. L. Swinney, "Shocks in vertically oscillated granular layers", Phys. Rev. E 66, 051301 (2002): MD with e = 0.9, 9 layers, Gamma = 3. The layer dilates in flight, and the compaction shock crosses it in about a quarter cycle before the layer leaves.
- J. M. Pastor, D. Maza, I. Zuriguel, A. Garcimartin, J.-F. Boudet, "Time resolved particle dynamics in granular convection", Physica D 232, 128 (2007): the inelastic-ball model fits flight times for Gamma below about 2.7. Above Gamma about 3 the collision lasts about as long as the layer is stuck to the plate.
- S. F. Foerster, M. Y. Louge, H. Chang, K. Allia, "Measurements of the collision properties of small spheres", Phys. Fluids 6, 1108 (1994); Cornell impact-results table.
