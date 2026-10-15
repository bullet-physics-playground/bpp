## The Oloid and the Sphericon

**What it shows** — Three wooden rollers, each the convex hull of two circular arcs (radius 6 cm), are pushed along a level board at 15 cm/s. None is round, yet each rolls and lays its whole surface on the board while weaving from side to side. The oloid's (Schatz) centre of mass rises and falls a little as it rolls. The two-circle roller's (Stewart) and the sphericon's stay at one height, R/√2.

**Model** — Each roller is a Bullet rigid body (mass and principal moments from `reconstruction/gen-meshes.py`). Bullet's own collision is switched off (`collides=false`), and Bullet's gravity and gyroscopic term are off too (`setFlags(1)`). Before every physics step the script does three things. (1) It applies gravity (g = 981 cm/s²). (2) It advances the spin with Euler's torque-free equations, using RK4 in the body frame. (3) It finds the exact contact, the lowest point of each of the two arcs, from the analytic arc support function. Normal and Coulomb-friction impulses (μ = 0.6, a 2D friction cone) are solved together by sequential impulses, 8 iterations, with Baumgarte bias 0.2 on penetration. Rolling resistance is a moment δ·N with δ = 20 µm (`DELTA = 0.002` cm), applied against the rolling but not about the board normal. Bullet then only integrates positions and orientations. The run uses 2400 physics steps/s (`OL_STEPS`) and no damping. Theory for the height range is computed when the script loads: it scans 720 × 180 "down" directions and bisects for directions where both arcs reach equally far. Masses (this run, matching README): oloid 461.5 g, two-circle 496.2 g, sphericon 316.7 g (wood 0.7 g/cm³). Setting-down yaws (−14.7°, 12.0°, −25.6°) were "found by trying" so each rolls straight on average.

**Theory checks**

| Quantity | Theory (formula / source) | Simulation (this run) | Agreement |
|---|---|---|---|
| Oloid COM height range while rolling | between R/√2 and 3R/4 = 4.2426 to 4.5000 cm (script's own scan of the shape) | 4.2426 to 4.5000 cm | exact to 4 decimals (0.1 µm) |
| Two-circle roller COM height | constant, 4.2426 cm (scan; Stewart roller) | 4.2426 to 4.2426 cm | constant to 4 decimals |
| Sphericon COM height | constant R/√2 = 4.2426 cm | 4.2426 to 4.2426 cm | constant to 4 decimals |
| Energy loss besides rolling resistance (should be 0 for rolling without slipping), 2400 steps/s | 0 | sphericon 0.229 %, two-circle 0.681 %, oloid 0.227 % of push KE | README: "0.2 to 0.7 %" — matches |
| Same, 9600 steps/s (step-size convergence) | 0; README: "about a fifth" of the 2400 value | 0.046 %, 0.126 %, 0.054 % | ratios 0.20, 0.19, 0.24 — matches README |
| Share of push KE taken by rolling resistance (δ = 20 µm) | (bookkeeping, no theory value) | 6.6 %, 18.9 %, 15.9 % | — |
| Side-to-side weave | README/header now: two-circle 3.6, oloid 5.1, sphericon 5.8 cm; help text "3.6 to 5.8 cm" (fixed 15 Oct 2026; was "4 to 6 cm") | sphericon 5.8, two-circle 3.6, oloid 5.1 cm (same on every push in a 25 s run) | matches |
| Oloid volume | 3.0524 R³ (README, from gen-meshes.py) | not re-run | README only |

**Run used**

```
cd demo/WyomingWill/Oloid && HOLD_S=0 timeout 1500 bpp -f oloid.lua -n 720
cd demo/WyomingWill/Oloid && HOLD_S=0 OL_STEPS=9600 timeout 1500 bpp -f oloid.lua -n 720
cd demo/WyomingWill/Oloid && HOLD_S=0 bpp -f oloid.lua -n 1500      # 15 Oct 2026 re-run, weave figures, identical to the above
```
Default (2400 steps/s):
```
  Oloid     461.5 g; lying along a line on the board, its centre is between 4.2426 and 4.5000 cm up (theory)
  Sphericon reaches the far end at 3.93 s, 108.3 cm along the board, weaving 5.8 cm side to side:
            its centre 4.2426 to 4.2426 cm up (theory: 4.2426 to 4.2426);
            energy: of what the push gave it, 6.6% went to rolling resistance, and 0.229% otherwise (rolling without slipping, it should lose none)
  2-circle  reaches the far end at 6.83 s, 109.6 cm along the board, weaving 3.6 cm side to side:
            energy: of what the push gave it, 18.9% went to rolling resistance, and 0.681% otherwise (rolling without slipping, it should lose none)
  Oloid     reaches the far end at 9.02 s, 108.8 cm along the board, weaving 5.1 cm side to side:
            its centre 4.2426 to 4.5000 cm up (theory: 4.2426 to 4.5000);
```
OL_STEPS=9600:
```
            energy: of what the push gave it, 6.6% went to rolling resistance, and 0.046% otherwise (rolling without slipping, it should lose none)
            energy: of what the push gave it, 18.9% went to rolling resistance, and 0.126% otherwise (rolling without slipping, it should lose none)
            energy: of what the push gave it, 15.9% went to rolling resistance, and 0.054% otherwise (rolling without slipping, it should lose none)
```
The README's sample console block matches this default run line for line (times 3.93/9.02 s, distances, 0.229 %).

**Known departures and honest caveats**
- The height check partly tests the script against itself. The "theory" range comes from the same arc-support function the contact uses, scanned numerically, not from a closed-form derivation. It does agree with the closed-form values R/√2 = 4.2426 and 3R/4 = 4.5000.
- The min/max height is recorded once per frame (60 Hz), not every physics step.
- The contact model is the script's own sequential-impulse solver with Baumgarte stabilisation, not exact rolling constraints. The residual energy loss of 0.05-0.7 % is step-size error and shrinks about 5× from 2400 to 9600 steps/s.
- The rolling resistance (20 µm) is a chosen parameter. It takes 7-19 % of the push energy over the ~110 cm run.
- The setting-down yaw angles (12-26° off the axle) were tuned by hand so the rollers run straight on average.
- The board is level and the rollers are pushed. README: on a slope, past about 40 cm/s, one arc's normal force nearly vanishes and they skid. That limit was not tested here.
- Fixed 15 Oct 2026: README, header comment and help text said all three weave "4 to 6 cm"; the two-circle roller weaves 3.6 cm. They now give each body's measured weave (3.6 / 5.1 / 5.8 cm; help text 3.6 to 5.8 cm). The Cabinet's placard and catalogue text for this exhibit do not mention the weave. Text only; physics and console unchanged (hall vs standalone IDENTICAL, 900 frames).
- The oloid's centre height is not perfectly constant (it rises and falls by 0.26 cm). A real oloid on a slope therefore rolls unevenly; the exhibit shows this only as the pen trace.

**References** (as cited in README and code)
- Paul Schatz, the oloid, 1929.
- A. T. Stewart, the two-circle roller, 1966 (no title or journal given).
- Sphericon (no source cited).
- Mass properties: `reconstruction/gen-meshes.py` (NumPy/SciPy).
