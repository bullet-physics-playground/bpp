## Galileo's Ramp: the Rolling Race

**What it shows** — Five rollers are let go together on a 5-degree ramp: a wooden ball, a small steel ball, a wooden disc, a brass hoop and a can of soup. The order at the finish line depends only on how much of each body's mass sits out at its rim (k = I/(m r^2)), not on its mass or size. The soup can wins because the liquid inside hardly turns, the two balls tie, and the hoop comes last.

**Model** — Bullet does the contacts. The balls are `btSphereShape`. The disc, hoop and can also collide as spheres of their own radius, but they are held to their lanes (linear factor (1,1,0), angular factor (0,0,1)) and given their own inertia tensors. The README says Bullet's cylinders, touching along a line, "jitter and lose 2% of their speed", which is why they are not used. The racers (code and README):
- wooden ball: r = 2.5 cm, 0.7 g/cm^3, 45.8 g, k = 0.4
- steel ball: r = 1.0 cm, 7.85 g/cm^3, 32.9 g, k = 0.4
- wooden disc: r = 2.5 cm, 2 cm thick, 27.5 g, k = 0.5
- brass hoop: 3 mm thick, 1.5 cm wide, 56.5 g; k = (r^2 + r_i^2)/(2 r^2) = 0.887
- can: 40 g of tin plus 330 g of soup. Only the tin counts towards the spin inertia, which gives k = 0.094.

Physics settings: friction 0.8 on both ramp and bodies, which Bullet multiplies to 0.64 at each contact (the README and lua said "friction 0.8" until 16 Oct 2026; they now give 0.64), restitution 0, damping 0, g = 981 cm/s^2, 30 solver iterations, 2400 steps per simulated second by default (GR_STEPS). Bullet's integrator is its usual semi-implicit (symplectic) Euler. The ramp is 120 cm long, and the finish line is 100 cm below the start line. The script interpolates each finish crossing to within one physics step.

**Theory checks**

| Quantity | Theory (formula / source) | Simulation (this run) | Agreement |
|---|---|---|---|
| Soup time to 100 cm | t = sqrt(2d(1+k)/(g sinθ)), k=0.094: 1.5994 s | 1.5992 s | -0.013% |
| Wooden ball time | k=0.4: 1.8097 s | 1.8095 s | -0.011% |
| Steel ball time (ties wooden ball) | k=0.4: 1.8097 s | 1.8095 s | -0.011%; ties ball to 0.1 ms |
| Disc time | k=0.5: 1.8732 s | 1.8730 s | -0.011% |
| Hoop time | k=0.887: 2.1011 s | 2.1009 s | -0.010% |
| Speed at line, soup / ball / disc / hoop | v = sqrt(2 d g sinθ/(1+k)): 125.0 / 110.5 / 106.8 / 95.2 cm/s | 125.1 / 110.5 / 106.8 / 95.2 cm/s | ≤0.1 cm/s |
| Acceleration (least-squares fit of d = ½at² + v0 t + d0 to GR_LOG, 0.2 s to finish) | a = g sinθ/(1+k): ball 61.07, disc 57.00, hoop 45.30, soup 78.18 cm/s² | 61.071 / 56.999 / 45.305 / 78.182 cm/s² | <0.01% |
| Galileo's odd-number rule (distance in successive 0.5 s intervals) | 1 : 3 : 5 | 1 : 2.998 : 4.997 (all five racers) | 0.1% |
| Step-size convergence, soup time error | error → 0 as dt → 0 | 600 st/s -0.052%; 2400 -0.013%; 9600 -0.003% | error ∝ dt (first order, ~4× per 4× steps) |
| Finish order | soup < balls (tie) < disc < hoop | Soup, Ball, Steel, Disc, Hoop | matches |

The theory values for time and speed are printed by the script. The fit and odd-number rows I computed from the GR_LOG CSV of this run. Times in the README are identical to this run's, to every printed digit.

**Run used**
```
cd demo/WyomingWill/EulersGallery/exhibits/GalileoRamp && HOLD_S=0 timeout 1500 bpp -f galileo-ramp.lua -n 600            # 2400 steps/s
HOLD_S=0 GR_STEPS=600  ... -n 600 ;  HOLD_S=0 GR_STEPS=9600 ... -n 600                             # convergence
HOLD_S=0 GR_LOG=gr.csv ... -n 150                                                                   # distance log
```
```
  Soup   the can of soup         370.0 g, k = I/(m r^2) = 0.094: a = g sin(theta)/(1 + k) =  78.2 cm/s^2; theory 1.599 s
  Hoop   the brass hoop           56.5 g, k = I/(m r^2) = 0.887: a = g sin(theta)/(1 + k) =  45.3 cm/s^2; theory 2.101 s
  Soup   1st across the line at 1.5992 s (theory 1.5994, -0.013%), at 125.1 cm/s (theory 125.0)
  Ball   2nd across the line at 1.8095 s (theory 1.8097, -0.011%), at 110.5 cm/s (theory 110.5)
  Steel  3rd across the line at 1.8095 s (theory 1.8097, -0.011%), at 110.5 cm/s (theory 110.5)
  Disc   4th across the line at 1.8730 s (theory 1.8732, -0.011%), at 106.8 cm/s (theory 106.8)
  Hoop   5th across the line at 2.1009 s (theory 2.1011, -0.010%), at 95.2 cm/s (theory 95.2)
GR_STEPS=600:  Soup   1st across the line at 1.5986 s (theory 1.5994, -0.052%) ...
GR_STEPS=9600: Soup   1st across the line at 1.5994 s (theory 1.5994, -0.003%) ...
```

**Known departures and honest caveats**
- The disc, hoop and can are spheres to the collision detector and are locked to planar motion with spin about their axes only. That is exact for an ideal line contact, but the model cannot show wobble, steering or edge effects. Collision shape and inertia are chosen separately, on purpose.
- The can is an idealisation: the soup is treated as not turning at all, so it counts only towards translation. Real soup is viscous and slowly spins up, so a real can would sit somewhere between k = 0.094 and that of a solid cylinder (0.5).
- All times are about 0.2 ms early (-0.01%). The error halves roughly with each doubling of the step rate (first-order integrator). At the default 2400 steps/s it is far below anything visible.
- Friction (0.64 at the contact) was chosen so that nothing slips. At 5° the friction needed is small (μ ≥ k tanθ/(1+k), at most 0.041 for the hoop), so this is comfortable. Rolling resistance and air drag are absent: the ramp is ideal.
- The odd-number rule and acceleration fit are not printed by the exhibit. I computed them from the optional log. In the log, the ball passes the 114 cm end of the ramp before t = 2.0 s, so only the first three intervals (up to 1.5 s) were used.
- The README's console excerpt matches this run exactly.

**References**
- Galileo Galilei, inclined-plane experiments (named in the exhibit title; no specific citation in code or README).
- Standard rolling-without-slipping result a = g sinθ/(1 + I/(m r²)) (stated in code and README; no source cited).
