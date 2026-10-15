## The Brazil-Nut Effect

**What it shows** — Three glass-fronted boxes, each holding a one-bead-thick layer of beads, are shaken vertically at 7 Hz. Shaken gently (peak 0.8 g), the bed never leaves the floor and nothing happens. Shaken hard (3 g), a big bead starting at the bottom rises to the top within seconds and stays there. A small coloured bead in the third box rises too, but then sinks again by a wall and circulates. This shows the convection rolls (up in the middle, down by the walls) that Knight, Jaeger and Nagel identified as the mechanism.

**Model** — Bullet does everything here; the script adds no custom contact or integration.
- Beads: 140 glass spheres per box (density 0.0025 kg/cm^3), radius 0.5 cm, with a deterministic size spread of +/-5% (BN_POLY = 0.1) so they do not crystallise. Big bead: radius 1.5 cm. All beads are locked to the x-y plane (linear factor (1,1,0), rotation about z only).
- Friction: 0.8 bead-bead, 1.0 walls. Restitution 0.1 for both.
- Box: a 1e4 kg compound body (floor plus two walls, 15 cm wide inside, 24 cm tall) with its own gravity off. The script sets its position and velocity to the sinusoid y = A sin(wt) before every physics step. The front and back glass are not colliders; the planar constraint stands in for them.
- Shaking: f = 7 Hz, A = Gamma g / w^2, which gives 4.1 mm for Gamma = 0.8 and 15.2 mm for Gamma = 3.
- Stepping: 2400 physics steps per second, 20 solver iterations. Beads settle for 0.5 s before shaking starts. The boxes are re-poured every 90 s.
- Floor push: the floor's push on the bed is measured from how much the heavy box is slowed in each step, binned by phase in 2-degree bins over shakes 5 to 12.

**Theory checks** (two seeds; the default seed 7 is the README's)

| Quantity | Theory (formula / source) | Simulation, seed 7 | Seed 8 | Agreement |
|---|---|---|---|---|
| Amplitude for Gamma | A = Gamma g / (2 pi f)^2 | 4.1 mm (0.8 g), 15.2 mm (3 g) | same | exact (definition) |
| Gamma = 0.8: bed stays on floor | min floor push = (1 - Gamma) W = 0.20 W (rigid bed) | never left; min push 0.18 W | 0.20 W | 0.02 W low / exact |
| Gamma = 3: lift-off phase, middle box | rigid bed: arcsin(1/Gamma) = 19.5 deg (a perfectly inelastic rigid bed, iterated: lands at 1.4 deg, leaves at 19.5) | 46 to 48 deg | 46 to 48 deg | **Disagrees by about 27 deg; tested 15 Oct 2026: mostly Bullet's contact compliance** (next rows) |
| Same, right box | 19.5 deg | 50 to 52 deg | 42 to 44 deg | as above |
| Lift-off phase vs contact stiffness (seed 7; middle, right box) | should tend to 19.5 if the late lift-off is numerical softness | 2400 steps/s, 20 iterations (default): 46-48, 50-52; 4800/s: 36-38, 32-34; 100 iterations: 36-38, 38-40; 9600/s + 60 iterations: 28-30, 36-38 | moves toward 19.5 as contacts stiffen; not converged at the stiffest tried |
| Lift-off phase vs bounce, friction (seed 7) | — | restitution 0: 42-44, 40-42; friction 0.3/0.3: 40-42, 54-56 | secondary |
| Big bead rises (Brazil-nut effect) | qualitative (Knight et al. 1993: rises with convection) | top at 6.3 s (44 shakes), rose 8.4 cm | 21.4 s (149 shakes), rose 10.8 cm (re-run 15 Oct 2026: same) | qualitative yes; timing varies 3x with the pour. At 4800 steps/s (seed 7): 11.9 s (82 shakes); coloured bead 19.3 s |
| Big bead stays up | qualitative | upper half 77% of the time | 91% | yes |
| Convection, middle box | rise in middle, fall at walls | middle +5.5 mm/s, walls -10.1 mm/s | +4.8 / -9.5 mm/s | correct sign / pattern |
| Convection, right box | same | +7.8 / -12.9 mm/s | +7.1 / -12.5 mm/s | correct sign / pattern |
| Coloured bead circulates | up nearer the middle, down nearer the walls | 4 round trips; up 3.6 cm, down 4.6 cm from centre (walls at 7.5) | 4 trips; 2.6 / 3.4 cm | yes |
| Coloured bead reaches top | qualitative | 11.6 s (81 shakes), rose 8.9 cm | 12.7 s (89 shakes), 9.3 cm | yes |

The only quantitative theory comparisons are the Gamma < 1 floor push and the rigid-bed lift-off phase. Everything else checks direction, sign and pattern. There is no comparison with a measured rise rate or convection speed, and no conservation check (the system is driven and dissipative).

**Run used**

```
cd demo/WyomingWill/BrazilNut && HOLD_S=0 timeout 1500 ../../../release/bpp -f brazil-nut.lua -n 3700
cd demo/WyomingWill/BrazilNut && BN_SEED=8 HOLD_S=0 timeout 1500 ../../../release/bpp -f brazil-nut.lua -n 3700
```

```
  Left   Gamma 0.8: the bed never left the floor (the floor's push never less than 0.18 of its weight; a rigid bed's: 0.20)
  Middle Gamma 3.0: the bed leaves the floor 46 to 48 degrees into the upswing (a rigid bed: arcsin 1/Gamma = 19.5;
  Right  Gamma 3.0: the bed leaves the floor 50 to 52 degrees into the upswing (a rigid bed: arcsin 1/Gamma = 19.5;
  Middle the big bead reaches the top at 6.3 s (44 shakes), having risen 8.4 cm
  Right  the coloured bead reaches the top at 11.6 s (81 shakes), having risen 8.9 cm
  Middle from 5 s to a minute: beads in the middle rising 5.5 mm/s on average, beside the walls falling 10.1 mm/s
  Middle the big bead, since reaching the top, has been in the bed's upper half 77% of the time
  Right  from 5 s to a minute: beads in the middle rising 7.8 mm/s on average, beside the walls falling 12.9 mm/s
  Right  the coloured bead has gone round 4 times: going up it was 3.6 cm from the middle on average, going down 4.6 cm (the walls are 7.5 cm out)
[seed 8] Middle the big bead reaches the top at 21.4 s (149 shakes), having risen 10.8 cm
```
Seed 7 reproduced every console line in the README exactly. The README omits the "Right ... 50 to 52 degrees" line, but that is not a disagreement.

Console after the 15 Oct 2026 text change (seed 7):
```
  Middle Gamma 3.0: the bed leaves the floor 46 to 48 degrees into the upswing (a rigid bed: arcsin 1/Gamma = 19.5;
         this one presses on longer: Bullet's contacts give a little, and the stiffer they are, the sooner it leaves)
```
Stiffness runs: BN_STEPS=4800; BN_STEPS=9600 (and 60 iterations, scratch copy); 100 iterations (scratch copy); BN_E=0; BN_MUB=0.3 BN_MUW=0.3; each -n 110. BN_STEPS=4800 -n 1500 for the rise. BN_SEED=8 -n 1400.

Pause and hall checks after the console change (15 Oct 2026): hall against standalone (cmp2.sh, 900 frames): IDENTICAL (7 run lines); HOLD_S=0 for 400 frames is a prefix of the default pause for 430 frames (10 lines).

**Known departures and honest caveats**
- **The parameters were tuned.** The README says that 7 Hz, 3 g and high friction "were found by trying". At 10 Hz and 2.5 g with less friction, the big bead rose "only now and then" (README; not re-run here).
- The lift-off phase is far from the rigid-bed value: about 47 deg against 19.5 deg. The README used to explain it as a springy bed squeezed by its landing, untested. Tested 15 Oct 2026 (scratch copy that also printed the push-vs-phase profile and took a solver-iteration setting): stiffer contacts move the lift-off toward 19.5 (4800 steps/s: 36-38 deg; 100 iterations: 36-38; 9600 steps/s with 60 iterations: 28-30, middle box), so the late lift-off is mostly Bullet's soft, position-corrected contacts, not a property of glass beads. It had not converged at the stiffest setting tried, which is too slow for the exhibit. In the default profile the floor's push is 4-10 W from 0 to 18 deg (the landing; a rigid inelastic bed would land at 1.4 deg), 1.4 W at 30-36 deg, and drops below 0.1 W at 48 deg. The console line, lua header and README now say this ("this one presses on longer: Bullet's contacts give a little, and the stiffer they are, the sooner it leaves"); how much later than 19.5 deg a real bed of glass beads would leave is stated as not tested.
- The rise time depends strongly on the initial packing: 6.3 s for seed 7, 21.4 s for seed 8 (re-run 15 Oct 2026). Since 15 Oct 2026 the README says so (and gives the 4800-steps/s rise, 11.9 s); its table now reads "comes up (within seconds with this pour; it can take twenty)".
- The bed is 2-D (one bead thick) with high wall friction, which drives the wall-shear convection. A real 3-D jar of nuts has other mechanisms (percolation, void filling, inertia) that this setup neither isolates nor excludes.
- The box is a kinematic driver (prescribed position and velocity on a 1e4 kg body), not a dynamic shaker. The floor-push measurement depends on that huge mass ratio.
- Bead sizes come from a deterministic formula, and pouring uses the script's own linear congruential random-number generator, so each pour is identical for a given BN_SEED.

**References**
- J. B. Knight, H. M. Jaeger, S. R. Nagel, Phys. Rev. Lett. 70, 3728 (1993): the big bead rises with the convection (README).
