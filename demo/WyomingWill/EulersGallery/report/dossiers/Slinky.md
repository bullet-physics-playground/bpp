## The Falling Slinky, and the Slinky on the Stairs

**What it shows** — A Slinky hangs stretched under its own weight, with a steel ball hanging level with its bottom. When both are released, the ball falls at once, but the Slinky's bottom hangs motionless until the collapse coming down from the top reaches it. Meanwhile the Slinky's centre of mass falls exactly like the ball. Beside it, the same Slinky walks end over end down seven stairs.

**Model**
- Falling Slinky: M = 215 g, N = 86 coils (SL_COILS), each a Bullet rigid body of M/N = 2.5 g. The collision shape is a thin square plate, 7 cm across. Closed length is 5.6 cm, stiffness k = 1.76 N/m, with no pre-tension. Neighbours are joined by a btSliderConstraint along the axis, with a lower limit at the closed spacing, no restitution, and rotation locked. This gives inelastic coil-on-coil stops. The script applies the spring force kseg = k(N-1) per gap before every physics step, and only while the gap is stretched. Each coil's initial stretch is set from the weight below it, so nothing moves before release. Bullet steps at 4800 per simulated second with 60 solver iterations and no damping. Coil friction is 0.5 and floor friction 0.6. The display runs at 0.1x real speed (SL_SPEED). The hand releases after a 0.5 s "hold" slider. 0.05 s after landing, the pile is replaced by a frozen closed stack, because loose coils jostle in Bullet.
- Stairs walker: the same M and k, built as 43 capsule pieces of 2 coils each, constrained to the plane (x, y, rotation about z). The two sides of each piece connect to the next piece by pull-only springs of k(42)/2 each, with damping 0.05 N s/m. A shear spring of 10 k(42) keeps pieces in line. Forces are applied by the script as velocity kicks each step, and Bullet handles the contacts (friction 0.6, restitution 0). There are 7 steps, 12 cm rise and 13 cm tread, from 84 cm. It restarts 3 s after coming to rest.

**Theory checks**

| Quantity | Theory (formula / source) | Simulation (this run) | Agreement |
|---|---|---|---|
| Time the bottom stays put | t* = sqrt(M / 3k) = 0.2018 s (script) | 0.2038 s (86 coils) | +1.0% (README now: 0.2038 s) |
| Same, the discrete chain itself (new, 15 Oct 2026: reconstruction/slinky-chain.c, point masses + pull-only springs + sticking collisions, step 1e-6 s) | continuum limit 0.2018 | 43: 0.20412; 86: 0.20296; 172: 0.20238; 344: 0.20208 s (same at 5e-7 s) | +1.15 / +0.58 / +0.29 / +0.14 %: halves as coils double |
| Bullet vs step size, 86 coils (SL_STEPS, new env) | the chain's 0.2030 | 4800: 0.2038; 9600: 0.2033; 19200: 0.2031; 38400: 0.2030 s | converges to the chain; the step adds +0.4% at the default |
| Bullet, 43 / 86 / 172 coils at 4800 steps/s | should approach 0.2018 as N grows (old README) | 0.2046 / 0.2038 / 0.2048 s | **does not**: the step error grows with N |
| Same at 9600 / 19200 steps/s | — | 9600: 0.2043 / 0.2033 / 0.2030; 19200: 0.2042 / 0.2031 / 0.2026 s (38400: 43 coils 0.2042, 86 0.2030) | with small steps it does approach, as the chain does |
| Detection threshold (1 cm/s vs 10 cm/s, scratch copy) | should not matter | 0.2038 s both | not the cause |
| Hanging stretch | M g / 2k = 59.9 cm | printed length 65.5 cm minus 5.6 cm closed = 59.9 cm | exact (README: "stretches 60 cm") |
| Ball's fall when the bottom starts moving | g t^2 / 2 at t = 0.2038 s = 20.4 cm | 20.4 cm | exact (README: 20 cm) |
| Bottom stationary before t* | displacement 0 | bottom drop 0.000 cm at t = 0.100 and 0.200 s (SL_LOG) | exact |
| Centre of mass in free fall | y_cm drop = g t^2 / 2 (only gravity acts) | t = 0.1/0.2/0.3/0.4 s: CoM drop 4.915/19.641/44.176/78.521 cm vs ball 4.915/19.640/44.176/78.521 cm; g t^2/2 = 4.905/19.620/44.145/78.480 | CoM = ball to 0.001 cm. The 0.01-0.04 cm offset from g t^2/2 is one 1/600 s logging-frame phase |
| Landing time | (no theory given) | 0.492 s after release | (README gives none) |
| Stairs: time per step, 7 steps | README now: "about 0.4 s a step (2.6 to 3.1 s for a clean walk)"; sample walk 3.03 s | 21 walks at native 0.1x speed: clean walks 2.56-3.07 s to the floor | matches the corrected README (the old "a third of a second", 2.64 s sample, was from an earlier run) |
| Stairs failure rate | old README: "one walk in three or four" goes wrong; README now: "nearly one walk in two" | native 0.1x speed, 21 walks in a row (HOLD_S=0, -n 84000): 12 clean; 4 reached the floor but skipped steps (3 4 5 F; 3 4 5 7 F; 3 4 5 6 F F; 3 4 5 F); 3 stopped on step 7; 2 never started (rest on step 2, no landings). Earlier SL_SPEED=1 sample: 4 of 9 clean | 9/21 = 43% imperfect; README corrected |

**Run used**

```
cd demo/WyomingWill/EulersGallery/exhibits/Slinky
SL_LOG=sl.csv HOLD_S=0 timeout 1500 ../../../../../release/bpp -f falling-slinky.lua -n 9000      # 15 s simulated at 0.1x
SL_COILS=172 HOLD_S=0 timeout 1500 ../../../../../release/bpp -f falling-slinky.lua -n 600
SL_COILS=43  HOLD_S=0 timeout 1500 ../../../../../release/bpp -f falling-slinky.lua -n 600
SL_SPEED=1   HOLD_S=0 timeout 2400 ../../../../../release/bpp -f falling-slinky.lua -n 3600      # 60 s, walk statistics (report)
HOLD_S=0 ../../../../../release/bpp -f falling-slinky.lua -n 84000                                 # 15 Oct 2026: 21 walks at 0.1x
SL_STEPS=9600/19200/38400 (SL_COILS=43/86/172) ... -n 400                                     # 15 Oct 2026: step study
cc -O2 -o slinky-chain reconstruction/slinky-chain.c -lm; ./slinky-chain {43,86,172,344} 1e-6  # 15 Oct 2026
```
(HOLD_S has no effect here. This exhibit uses its own "hold" slider, 0.5 s.)

```
--- hung up: 215 g, 86 coils, stiffness 1.76 N/m; 65.5 cm long hanging (5.6 cm closed up); the bottom should stay put for 0.202 s ---
t= 0.254s  the bottom starts to move, 0.2038 s after letting go (it should, by theory: 0.2018 s); the ball had fallen 20.4 cm
t= 0.542s  the Slinky lands, 0.492 s after letting go
stairs t= 3.75s  the walking Slinky comes to rest, on the floor: 7 steps down in 3.03 s
stairs t= 3.64s  the walking Slinky comes to rest, on the floor: 7 steps down in 2.98 s
[43 coils]  t= 0.255s  the bottom starts to move, 0.2046 s after letting go (it should, by theory: 0.2018 s); the ball had fallen 20.6 cm
[172 coils] t= 0.255s  the bottom starts to move, 0.2048 s after letting go (it should, by theory: 0.2018 s); the ball had fallen 20.6 cm
[SL_SPEED=1] stairs t= 2.18s  the walking Slinky comes to rest, on step 6: 5 steps down in 1.40 s
[SL_STEPS=19200] t= 0.253s  the bottom starts to move, 0.2031 s after letting go (it should, by theory: 0.2018 s); the ball had fallen 20.2 cm
86 coils, step 1e-06 s: the bottom moves at 0.20296 s (its gap closes at 0.20296 s); sqrt(M/3k) = 0.20179 s
[0.1x, walk 9]  stairs t= 7.25s  the walking Slinky comes to rest, on step 7: 6 steps down in 2.80 s
[0.1x, walk 14] stairs t= 1.28s  the walking Slinky comes to rest, on step 2: 1 steps down in 0.00 s
```

**Known departures and honest caveats**
- Checked 20 Oct 2026, not changed: **Bullet's gyroscopic term.** Every coil, stair piece and the ball keep Bullet's default, flag 8 (BT_ENABLE_GYROSCOPIC_FORCE_IMPLICIT_BODY), and it is on: Bullet's 3×3 solve drops it only when the determinant is under single precision's epsilon, 1.19·10⁻⁷ in kg³·cm⁶, and these are above it (falling coil I = 0.01445, 0.0289, 0.01445 kg·cm², det 6.0·10⁻⁶; stair piece 0.0289, 0.0578, 0.0289, det 4.8·10⁻⁵; ball 0.045 each way). It can do nothing here, so its known loss of energy (it is one Newton step of backward Euler; see the Gömböc section) does not arise: the falling coils cannot turn (the sliders lock rotation), the ball's inertia is the same every way, and the stair pieces turn only about z (angular factor 0, 0, 1), one of their principal axes, where the gyroscopic torque ω × Iω is zero. Test (`report/gyro-free-test.lua`, GT_CASE=slinky GT_W=20 GT_HZ=4800 GT_PLANAR=1): a free stair piece turning at 20 rad/s about z keeps its energy exactly with the term off, explicit, or implicit in the world's frame; with the default it gains 5.0·10⁻⁴ in 10 s (Bullet's single-precision change of frame and back; 5·10⁻⁵ a second). Turning in 3-D, which it cannot here, it would lose 11.7% in 10 s. In the exhibit (`report/gyro-probe.lua`, GP_FILE=falling-slinky.lua, first 5 s simulated: the fall and the walk under way): the energy the term makes, worked out in double precision before every step, is −8.6·10⁻⁶ kg·cm²/s² in all, against 47,400 lost to everything.
- Fixed on 15 Oct 2026, the hang-time explanation: the README used to say more coils bring the wait closer to sqrt(M/3k). At the default 4800 steps/s they do not (43/86/172 coils: 0.2046/0.2038/0.2048 s). Established cause: the +1.0% at 86 coils is +0.6% from the discreteness itself (an exact chain of 86 sticky point masses waits 0.2030 s; the gap halves as coils double) and +0.4% from Bullet's step (0.2038 at 4800 steps/s, 0.2031 at 19200, 0.2030 at 38400). The step error grows with N because the collapse front then crosses each coil in fewer steps, which is why 172 coils are no better at 4800 steps/s. The detection threshold (1 vs 10 cm/s) makes no difference. README and lua header now say this; SL_STEPS was added for headless testing, and reconstruction/slinky-chain.c (the independent chain check the README cites) was added. Default steps not raised: 4800 steps/s already costs ~20 ms per frame here with the 86 coils and the stairs walker.
- The theory is for a continuous spring with **no pre-tension**. The model deliberately has none, although a real Slinky does.
- Coil collisions are perfectly inelastic slider limits, not true contact. After landing, the coils are replaced by a frozen pile, so post-landing dynamics are not physical.
- The walker is a planar, 43-piece reduced model with tuned damping. The README says 0.05 N s/m was chosen because less damping gallops and more stalls. The 12 x 13 cm stairs are the size it "walks best on". Walks are sensitive to tiny differences (the walker is rebuilt identically each time; walks differ through Bullet's internal ordering, so the "statistics" are of that sensitivity). At SL_SPEED=1 landings are detected once per 1/60 s frame instead of per 1/600 s (the physics step, 1/4800 s, is the same), so brief landings can be missed and a clean walk logged as skipping; the README now says to count walks at the native 0.1x speed. Fixed on 15 Oct 2026: the README's "one walk in three or four" is now "nearly one walk in two", with the 21-walk breakdown, and its sample walk listing is replaced by walk 1 of this run.
- The ball is a 50 g Bullet sphere released from a fixed constraint at the same instant.

**References**
- None cited by name in the code or README. The sqrt(M/3k) result is derived in the README from momentum M g t.
