## Kapitza's Pendulum

**What it shows** — An upside-down pendulum stands on a pivot shaken up and down 40 times a second and does not fall; nudged, it rocks slowly about the upright as if gravity pointed up. Left: shaken 1.0 cm, it stays up. Right: shaken 0.6 cm, too little, it falls and ends up hanging. Both are stood up again, tilted 8 degrees, every 15 s.

**Model** — Bullet. Each pendulum is one rigid body (brass bob 3 cm diameter plus aluminium rod radius 0.25 cm; bob centre 20 cm from the pivot; 130.8 g; centre of mass 19.19 cm from the pivot; inertia from the composite) on a `btHingeConstraint` to a pivot block. The block is a 10^4 kg body moved kinematically by the script before every step: position y = y0 + a cos(w t) and velocity -a w sin(w t), w = 2 pi x 40 Hz. No friction, Bullet damping 0, solver iterations 40, 19200 physics steps/s (480 per shake; raised from 4800 on 15 Oct 2026, see below; steps slider 2400-19200). The slow motion is measured on the angle averaged over each 1/40 s shake; rocking period from upward zero crossings of that average.

**Theory checks**

| Quantity | Theory (formula / source) | Simulation (this run) | Agreement |
|---|---|---|---|
| Equivalent length | l = I / (m d): 19.761 cm | (input; independent recomputation 19.7614 cm) | exact |
| Stability threshold | Kapitza: a w > sqrt(2 g l) = 196.9 cm/s, a > 0.783 cm | 1.00 cm stays up; 0.60 cm falls at 0.69 s | qualitatively correct |
| Threshold bracket (KP_A1=0.80 KP_A2=0.76) | 0.80 cm (a w = 201.1) should stand; 0.76 cm (191.0) should fall | 0.80 cm "stays up (as it should)"; 0.76 cm falls at 1.39 s | correct on both sides, within +/-3% of threshold |
| Rocking period, a = 1.0 cm, small-rock theory | 2 pi / W, W^2 = a^2 w^2 / (2 l^2) - g / l: 1.124 s | 1.133 s over 6 rocks, up to 7.6 deg | +0.8% (expected: the rock is 7.6 deg, not small) |
| Rocking period for its size (new console term) | averaged eq. to next order phi'' = -W^2 phi + c phi^3, c = 2K/3 - g/(6l), K = a^2 w^2/(2 l^2); Lindstedt T = (2 pi/W)(1 + 3 c A^2/(8 W^2)), A = 7.6 deg: 1.135 s (+0.97%) | 1.133 s | -0.2% |
| Exact (non-averaged) pendulum equation, integrated independently (Python RK4, 400 steps per shake, same shake-averaged measurement) | theta'' = (g - a w^2 cos wt) sin theta / l, from 8 deg: 1.1341 s; from 2 deg: 1.1237 s | 1.133 s (8 deg); KP_TILT=2: 1.122 s | -0.1% / -0.15% |
| Step-size convergence of the rocking period (KP_STEPS) | should converge to the exact equation's 1.134 s | 2400: 1.073; 3600: 1.103; 4800: 1.115; 7200: 1.125; 9600: 1.129; 14400: 1.132; 19200: 1.133; 38400: 1.134 s | converged to 0.1% at the new default |
| Repeatability over 4 restarts (3600 frames) | — | 1.133 s and 7.6 deg each time | stable (fixed: see caveats) |
| Hall identity / pause | identical in the Gallery; HOLD_S=0 output a prefix of the default-pause output | cmp2.sh "Kapitza" 1500 frames: IDENTICAL (12 run lines); pause check 1500/1530 frames: prefix OK (18 lines) | pass |

No energy check (the shaker does work by design).

**Run used**

```
cd demo/WyomingWill/EulersGallery/exhibits/Kapitza && HOLD_S=0 timeout 1500 ../../../../../release/bpp -f kapitza.lua -n 3600 | grep -v ALSA
  (also KP_A1=0.80 KP_A2=0.76 -n 1200; KP_TILT=2 -n 600; KP_STEPS=2400..38400 -n 600)

  the pendulum: 130.8 g, its centre 19.19 cm from the pivot, equivalent length l = I/(m d) = 19.761 cm;
  it stays up if a w > sqrt(2 g l) = 196.9 cm/s, i.e. a > 0.783 cm
  Left   shaken 1.00 cm: a w = 251.3 cm/s > 196.9 -- it should stay up, rocking with a period of 2 pi / W = 1.124 s
  Right  shaken 0.60 cm: a w = 150.8 cm/s < 196.9 -- it should fall
  Right  falls over at 0.69 s
  Left   stays up, rocking up to 7.6 degrees either side: a period of 1.133 s over 6 rocks (theory, 2 pi / W: 1.124 s, +0.8%; for its size: 1.135 s, -0.2%)
  [KP_STEPS=4800, the old default] Left   stays up, rocking up to 7.6 degrees either side: a period of 1.115 s over 6 rocks (theory, 2 pi / W: 1.124 s, -0.8%; for its size: 1.135 s, -1.7%)
  [KP_TILT=2] Left   stays up, rocking up to 1.9 degrees either side: a period of 1.122 s over 6 rocks (theory, 2 pi / W: 1.124 s, -0.2%; for its size: 1.125 s, -0.2%)
  [KP_A1=0.80] Left   stays up (as it should)
  [KP_A2=0.76] Right  falls over at 1.39 s
```

**Known departures and honest caveats**
- Fixed on 15 Oct 2026, step size: at the old default of 4800 steps/s the rocking period was 1.7% short of the converged value (1.115 s against 1.134 s), and that error happened to cancel the finite-amplitude lengthening, so "-0.8% from 2 pi / W" agreed for the wrong reason. The default is now 19200 steps/s (slider max raised to 19200), where the period is within 0.1% of both the 38400 run and an independent integration of the exact pendulum equation. Cost: about 6 ms of CPU per frame headless.
- Fixed on 15 Oct 2026, comparison: the console now also gives the period for the rock's measured size (Lindstedt correction of the averaged equation, about +1%), so the comparison is no longer between a finite rock and a small-rock formula only. The remaining -0.2% is half the averaging's next terms (the exact equation gives 1.1341 s vs 1.135) and half step error.
- Fixed on 15 Oct 2026, restart bug: after each 15 s restart the first shake-average bin included the previous run's stale bin plus the new 8-deg start angle, so later runs reported "rocking up to 8.0 degrees" (the start tilt) instead of 7.6. Now every run reports 7.6.
- Kapitza's formulas are first-order averages (fast shaking, small rocking); the README says so.
- Near threshold (0.80 cm) the rocking period (4.3 s theory) is too long for the 8 s report window, so only "stays up" is checked, not a period.
- No upper stability limit is checked (Kapitza's averaging cannot see it; the DoublePendulum exhibit's Floquet analysis does that for the two-rod chain).
- The pivot is driven exactly (kinematic), i.e. an ideal shaker; the hinge is frictionless and the motion is planar.
- Fixed on 15 Oct 2026, documentation: the lua header listed a non-existent `KP_LOG=file.csv`; it now lists `KP_A1`, `KP_A2`, as the README does. The README's "131 g" now reads 130.8 g, as the console.

**References**
- A. Stephenson (1908), first observation — README / lua header.
- P. L. Kapitza (1951), averaged-potential explanation — README / lua header (titles and journals not given).
