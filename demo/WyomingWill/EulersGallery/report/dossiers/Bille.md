## Bille Drop (weighted monostable bodies)

**What it shows** — These are bodies that rest on only one face because of where their mass is, not because of their shape alone.

- **Bille** is the monostable tetrahedron of Almadi, Dawson & Domokos (2025): a hollow carbon-tube frame with a dense tungsten-carbide wedge, so that set down on any face it tips, face to face, onto face D. It has one stable face and two unstable corners.
- **The spiral polyhedra** (after Domokos & Kovács 2023) have 21, 26 and 37 corners, each with equal weights at the corners. Each has one stable face (the base) and one unstable vertex (the apex). Their bands of side faces tip one onto the next: … → S2 → S1 → base.
- **The PLA-only polyhedron** ("ppla37", added 18 Oct 2026) is the gallery's own design, not taken from a paper. It is the same kind of spiral, an apex above 6 hexagons with 37 faces, but has no added weights. It is a single 15 cm, 331 g PLA print: solid up to 23.65 mm above the base, with one closed air void above that and 1.0 mm walls. That makes it bottom-heavy, with the centre of mass 23.7 mm up. The trick is the fill level, which sits at the centre-of-mass height, the level that puts the centre of mass lowest. It is printable as is (see `exhibits/Bille/print/README.md`). In the cycle it follows the 37-corner body (21 → 26 → 37 → PLA → …) and is always drawn solid; its corners light up with the same white balls.

Bodies are dropped at random orientations or set down on a wrong face, and the console prints the faces each one passed through.

**Model** — Bullet handles contact through each body's convex hull: the 4 vertices for Bille, the corner points for the polyhedra. Mass and principal inertia are taken from the data files:
- **Bille at size 1:** 120 g, I = (0.219, 1.225, 1.321) kg·cm². The collision margin is the real tube radius, 0.05 cm.
- **Polyhedra:** scaled 4.5× to 40 cm tall, with mass scaling as size³. The PLA-only body is scaled 40/15 (the 15 cm print drawn 40 cm tall): 6.28 kg at size 1, collision margin 0.04 cm × 40/15. Its mass and inertia are the exact polyhedral values of solid minus void (`bille-meshes/ppla37-data.lua`).
- **Per-colour sizes:** 1.0, 0.6, 1.3, 0.8, 1.15 and 0.7.

The losses are applied by the script before every physics step, as constant moments: rolling resistance with lever arm δ = 50 µm (not scaled with size) and spin friction of 0.7 rad/s². Other settings: friction 0.5 (× table 0.8 = 0.4 at the table, 0.25 body on body), restitution 0.1 (× table 0.2 = 0.02 at the table, 0.01 body on body), no air drag.

**Time step.** Requested: 1200 steps per simulated second (slider), but at least one step per frame. Actual, from the code `NSTEPS = max(1, floor(steps·speed/60 + 0.5))`:
- At the default 1/50 slow motion (speed 0.02), NSTEPS rounds to 1, so the step is 1/3000 s.
- At speed 0.1 it is 1/1200 s.

**Detection thresholds.** A face counts as "lain on" when its normal is within 2° of straight down for 0.03 s. "At rest" means less than 0.2° and 0.03 cm of movement over 0.4 s. An edge counts as "rolled on" when exactly two of its corners are within 0.15% of the body's size of the table.

**Theory checks**

| Quantity | Theory (formula / source) | Simulation (this run) | Agreement |
|---|---|---|---|
| Bille rests only on face D (random drops) | monostable on D (paper; reconstruction puts the COM 0.81 mm inside the face-D loading zone, which is at most 1.48 mm deep: README.txt) | 27 of 27 drops on D (6 at speed 0.02, 21 at speed 0.1); tallies "16 runs, 16 on the stable face" | 100% |
| Bille set down on a wrong face | ends on D | 6 of 6 on D | 100% |
| Falling pattern from C | C → D (quasi-static rule) | 2 of 2: C → D, over edge AB (= C∩D) | matches |
| Falling pattern from A | A → D | 1 of 1: A → D, over edge BC (= A∩D) | matches |
| Falling pattern from B | B → A → D | report run: 3 of 3 logged as "B → D" (edges CD = B∩A then BC = A∩D). Since 15 Oct 2026 a face crossed in under 0.03 s is logged in brackets: re-run (BD_SEED=5 BD_BODIES=1 BD_COUNT=3 BD_START=setdown) logs Green "B -> (A) -> D; edges it rolled on: CD, BC" | path now matches in the face log too |
| Polyhedra rest only on the base (drops) | one stable face | 21-corner 4/4 (incl. one in the mixed run), 26-corner 2/2, 37-corner 4/4 | 10/10 |
| Polyhedra set down on a band | S_n → … → S1 → base | 37-corner: S6→S5→S4→S3→S2→S1 (then rocks S2/S1/base); 26-corner from S4: S4 → base; 21-corner from S1: S1 → base | all end on base; order never reversed except brief rocking (e.g. 26-corner drop S1→S2→S1→base) |
| Bille time to rest after drop | header: a single face-to-face tip takes ~1/20 s | median 0.39–0.41 s (tallies), range 0.36–0.69 s | — |
| Polyhedra time to rest (40 cm scale) | findings Table 6 at 9 cm: 4.3 / 2.3 / 2.5 s (21/26/37) | 21: 11.15–16.22 s; 26: 4.09–5.16 s; 37: 4.33–6.01 s | not comparable directly (scaled 4.5×, sizes 0.6–1.3) |
| Masses | 120 g × s³; polyhedra 109 / 142 / 201 g at 9 cm (findings) × (4.5 s)³ | Bille 120 / 264 / 183 g at s = 1 / 1.3 / 1.15; 21-corner 9951 g at s=1 (109.2 g at 9 cm), 26: 28362 g (141.7 g), 37: 27878 g (201.1 g) | exact |
| Earlier statistics (README) | — | code header: Bille "re-dropped 346 times, always ended on face D"; findings: polyhedra 116/117 on base (26-corner: 37/38) | documented |
| PLA-only: statics (added 18 Oct 2026) | exact polyhedral mass properties (outer polytope minus void polytope), reconstruction/pla/core.py | 1 stable face (base, centre-of-mass foot 41.14 mm inside); 1 unstable vertex (apex); nearest false face: foot 12.35 mm outside (S1, S2, S3 bands; S4–S6 17.7–24.2 mm); nearest other corner 12.35 mm from being an equilibrium. Re-checked independently from the STL (verify_stl.py: signed-tetrahedron volume 267.157 cm³, 331.275 g, COM 23.686 mm; 1 face with the foot inside, by 41.137 mm; next −12.346 mm) | exact; the face check is independent |
| PLA-only: mass | 1.24 g/cm³ × 267.157 cm³ = 331.3 g; × (40/15)³ at gallery size 1 | console: 6282 g at size 1 (40 cm), 1357 / 13801 / 3216 / 9554 / 2155 g for sizes 0.6 / 1.3 / 0.8 / 1.15 / 0.7 | exact |
| PLA-only: print-error robustness (computed, 300 trials a row; runs/robust_a66.log) | one stable face wanted | 100% with plane errors 0.1–0.5 mm, walls −0.2/+0.2/+0.4 mm, perimeter/infill density 3%/10%, gradients 2%/5%, random cells 3%/10%, elephant foot 0.3/0.6 mm, combined 0.2/0.3/0.5 mm; 89% at 1.0 mm, 6.3% at 2.0 mm planes | margin holds to ~0.5 mm |
| PLA-only: apex split (runs/apexsplit.log, re-run 18 Oct 2026) | 1 unstable vertex wanted | 18–19% of builds (robust_a66.log: 19–21%) have exactly 2 unstable vertices; apart ≤ 0.77 / 1.53 / 2.29 / 3.82 mm at plane errors 0.1 / 0.2 / 0.3 / 0.5 mm, distances from the COM differing ≤ 1.6 / 6.2 / 13.8 / 39 µm; stable faces still 1 in 100% | caveat (below) |
| PLA-only: drops at gallery scale, as shipped (BD_BODIES=2, 6 bodies, sizes 0.6–1.3, re-drop 1 s; seeds 11–14 at speed 0.1, 96 s each; seed 15 at the default 0.02, 19 s) | always on the base | tallies 19/20, 19/20, 20/20, 20/21 and 4/4: **82 of 85** on the base, median time to rest 0.91–0.95 s (1.29 s at 0.02). The 3 others: 2 "no face, may be touching" another body, 1 "no face" alone (see below) | consistent with monostable |
| PLA-only: drops, PLA-only cycle (scratch copy with only CYCLE changed; 6 bodies; seeds 21, 22 at speed 0.1, 48 s; seed 23 at 0.02, 19 s) | always on the base | 155/165, 141/153, 62/65 = 358 of 383 (93.5%) in the tallies. For seed 21 every failure was located from a BD_LOG re-run (identical console): 7 rested touching another body (2 of them on S1/S2, propped in the middle of the table), 4 alone, all of them within 15 cm of the sloping band at the table's edge (no face within 2° of down: these are bodies 24–52 cm across lying across the flat-to-ramp joint or on the 8° ramp) | no false resting face on the flat table seen |
| PLA-only: earlier test runs (reconstruction/pla/sim/logs, pla-drop.lua) | — | real 15 cm size, sizes all 1: 219/219 drops and 36/36 set-downs (6 on each band S1–S6) ended on the base. Gallery scale (sizes 0.6–1.3): 80/82 drops (35/35, 39/41, 6/6; the 2 others "no face", touching another body), 34/36 set-downs (the 2 others "no face", one touching) | as above |
| PLA-only: tipping off S1 (set down flat, logged every frame) | quasi-static start: α₀ = g·e/k², e = foot beyond the tipping edge, k² = I_edge/m (tiptheory.py): 11.6 rad/s² at 40 cm, 0.5° at 0.039 s, 2° at 0.078 s | 0.035 / 0.072 s (1/1200 s steps), 0.035 / 0.072 (1/3000), 0.037 / 0.073 (1/4800). Same check: p37 S1 theory 0.031/0.062, sim 0.031/0.061; p26 S1 0.066/0.131 vs 0.053/0.115; Bille A 0.031/0.062 vs 0.019–0.022/0.043–0.047 | close; sim a little early for Bille and p26 (the 0.2 mm set-down drop and the contact impulse are not in the formula) |

**Run used** (random seeds from the clock; one run each)
```
cd demo/WyomingWill/EulersGallery/exhibits/Bille && HOLD_S=0 timeout 1500 bpp -f bille-drop.lua -n 9000                      # speed 0.02, 3 s simulated
HOLD_S=0 BD_SPEED=0.1 bpp -f bille-drop.lua -n 9000                                                   # 15 s simulated
HOLD_S=0 BD_START=setdown BD_COUNT=6 BD_REDROP=0 bpp ... -n 3600   (speed 0.02, and again with BD_SPEED=0.1)
HOLD_S=0 BD_SPEED=0.1 BD_BODIES=2 BD_COUNT=6 BD_REDROP=1 bpp ... -n 12000                             # polyhedra only
```
Re-run after the 15 Oct 2026 logging change (seeded):
```
BD_SEED=5 BD_BODIES=1 BD_COUNT=3 BD_START=setdown BD_REDROP=0 HOLD_S=0 bpp -f bille-drop.lua -n 2500
  Green   set down on B; predicted: B -> A -> D
  Yellow  at rest on face D after  0.23 s; faces it lay on: A -> D; edges it rolled on: BC -- Yellow (Bille)
  Red     at rest on face D after  0.25 s; faces it lay on: A -> D; edges it rolled on: BC, AB -- Red (Bille)
  Green   at rest on face D after  0.34 s; faces it lay on: B -> (A) -> D; edges it rolled on: CD, BC -- Green (Bille)
BD_SEED=5 BD_BODIES=1 BD_COUNT=3 BD_REDROP=1 HOLD_S=0 bpp -f bille-drop.lua -n 4000
=== 1 s: 3 finished runs ===
    Bille                                  3 runs, 3 on the stable face, time to rest median 0.33 s; paths: D x3
```
(Bille seeds from the clock unless BD_SEED is set; seeded, it is checked for hall identity below. The tally's new median was not exercised with an even count in this short run; the formula is (t[floor((n+1)/2)] + t[floor(n/2)+1]) / 2.)
```
  Yellow  set down on B; predicted: B -> A -> D
  Yellow  at rest on face D after  0.45 s; faces it lay on: B -> D; edges it rolled on: CD, BC -- Yellow (Bille)
  Red     at rest on face D after  0.19 s; faces it lay on: C -> D; edges it rolled on: AB -- Red (Bille)
  Orange  at rest on face D after  0.21 s; faces it lay on: A -> D; edges it rolled on: BC -- Orange (Bille)
=== 12 s: 16 finished runs ===
    Bille                                 16 runs, 16 on the stable face, time to rest median 0.41 s; paths: D x16
  Purple  set down on S6; predicted: S6 -> S5 -> S4 -> S3 -> S2 -> S1 -> base
  Purple  at rest on face base after  5.04 s; faces it lay on: S6 -> S5 -> S4 -> S3 -> S2 -> S1 -> S2 -> S1 -> base -> S1 -> base -- Purple (37-corner)
    21-corner polyhedron (ideal)           3 runs, 3 on the stable face, time to rest median 14.98 s; paths: S1 -> base x2, S3 -> S2 -> S1 -> base -> S1 -> base x1
    37-corner polyhedron (shell + weights)   4 runs, 4 on the stable face, time to rest median 4.58 s; ...
```

Pause and hall checks after the lift fix (15 Oct 2026): with `BD_SEED=5 BD_BODIES=1 BD_COUNT=3 BD_REDROP=1`, HOLD_S=0 for 3000 frames is a prefix of the default pause for 3030 frames (36 lines); hall against standalone (cmp2.sh, 1500 frames): IDENTICAL (12 run lines). With a fixed seed the hall-identity check applies like any other exhibit's.

**PLA-only polyhedron: runs and checks (18 Oct 2026)**
```
cd exhibits/Bille
HOLD_S=0 BD_SEED=11..14 BD_SPEED=0.1 BD_BODIES=2 BD_COUNT=6 BD_REDROP=1 bpp -f bille-drop.lua -n 60000   # 96 s each
HOLD_S=0 BD_SEED=15 BD_BODIES=2 BD_COUNT=6 BD_REDROP=1 bpp -f bille-drop.lua -n 60000                  # speed 0.02, 19 s
=== 96 s: 84 finished runs ===   (seed 14)
    21-corner polyhedron (ideal)          21 runs, 19 on the stable face, time to rest median 12.11 s; ...
    26-corner polyhedron (shell + weights)  21 runs, 21 on the stable face, time to rest median 4.25 s; ...
    37-corner polyhedron (shell + weights)  21 runs, 21 on the stable face, time to rest median 5.27 s; ...
    PLA-only polyhedron (no weights)      21 runs, 20 on the stable face, time to rest median 0.95 s; paths: (S1) -> base x2, (S2) -> (S1) -> ...
```
- **Console unchanged up to the first PLA body.** The unmodified script and the new one were run with the same seeds: default (BD_SEED=7, 9000 frames), set-down (BD_SEED=7 BD_START=setdown BD_COUNT=6 BD_BODIES=2), mixed at speed 0.1 (BD_SEED=7, 20000 frames) and polyhedra only (BD_SEED=7 BD_BODIES=2 BD_COUNT=6, 12000 frames).
  - The default and set-down outputs are byte-identical, since no PLA body appears in them.
  - In the mixed run the first 201 lines are identical; the first PLA body appears at line 202.
  - In the polyhedra-only run the first 37 lines are identical; the first PLA body appears at line 38.
  - A colour's earlier bodies keep their turns: Green 21 → 26 → 37 as before, and the PLA body takes the 4th turn.
- **Hall identity.** `BD_SEED=5 BD_BODIES=2 BD_COUNT=6 BD_REDROP=1 BD_SPEED=0.1 bash ../../report/cmp2.sh Bille Bille bille-drop.lua 9000 plahall` gives IDENTICAL (102 run lines, 13 of them about PLA bodies). The earlier Bille-only check (BD_SEED=5 BD_BODIES=1 BD_COUNT=3 BD_REDROP=1, 1500 frames) is still IDENTICAL (12 run lines).
- **Pause prefix.** With the same seeded PLA settings, HOLD_S=0 for 9000 frames gives 110 lines (13 about PLA). These are line for line the first 110 lines of the default half-second pause run for 9030 frames.

**Bullet creep check (18 Oct 2026, measured only, physics not changed).** A separate study of uniform-density polyhedra (23 g PLA bodies, 200 mm long and 8–15 mm thick) found that Bullet lets a polyhedron lying flat on a face creep by about 0.85°/s, or 0.25°/s at 4800 steps/s, whatever the collision margin. To see whether this touches any result here, single bodies were set down at size 1 with a scratch copy of bille-drop.lua (`reconstruction/pla/creep/`: creep-lua.patch adds CR_KIND / CR_FACE / CR_LOG only). Each was logged for 10 s after a 2 s settle, at steps of 1/1200, 1/3000 and 1/4800 s, both with the default losses and with rolling resistance and spin friction off.

- **On the stable face** (Bille D, p26, p37 and PLA-only base): the total rotation over 10 s was at most 0.07° and the slide at most 0.1 mm in all 24 runs, so the creep rate is **≤ 0.007°/s**. That is at least 100× below 0.85°/s and at the resolution of the logged single-precision quaternions (~0.02–0.05°). The face's tilt from straight down did not drift: it stayed constant to the 0.03° log resolution. Bille's steady 0.05° on D is geometry, not drift. Bullet's default contact-processing threshold instead of the script's 10 µm (p37, no losses, 1/1200 and 1/4800 s) gave the same numbers.
- **On a false face** (Bille A and C, p26 / p37 / PLA-only S1, logged every frame): the times to tilt 0.5°, 2° and 10° hardly depend on the step. For example, PLA-only S1 took 0.035 / 0.072 / 0.160 s at 1/1200 s and 0.037 / 0.073 / 0.163 s at 1/4800 s. They agree with the quasi-static start α₀ = g·e/k² (row above). A creep of 0.85°/s would add under 0.1° within these times.
- **Gomboc-C at rest** (gomboc-drop-c.lua unchanged, GC_COUNT=1 GC_SEED=1 GC_REDROP=0, 108 s after coming to rest): 0.12°/min of rotation and 0.56 mm/min of slide at 1200 steps/s (tilt 1.13° → 1.35°), and 0.07°/min and 0.003 mm in total at 4800. This is consistent with the "up to ~0.3 deg and ~0.7 mm per minute" in its header, and about 400× below 0.85°/s.

**Finding: the creep seen in the other study does not appear in Bille Drop or Gomboc-C, and does not affect any documented result here.** The rest detector (0.2° in 0.4 s, i.e. 0.5°/s) would have caught a 0.85°/s creep, because bodies would then never be declared at rest; they are. The cause of the difference was not found. The other study's bodies are lighter (23 g, against 0.12–28 kg at size 1 here) and far more slender (8–15 mm thick, with a 0.4 mm margin). That may matter, but it is untested.

**Known departures and honest caveats**
- Fixed 15 Oct 2026: the attendant's lift ran during the start pause (a `holdTick` that called `liftStep`), so with the pause on the output differed. `holdTick` is removed; the lift waits for the pause to end and the pause changes nothing (checks above).
- Fixed on 15 Oct 2026: the tally's "median" with an even number of runs printed the lower middle value; it is now the mean of the two middle values (same fix in ../Gomboc).
- **The Bille shape is a reconstruction, not the authors' drawing.** The paper gives vertex coordinates only in a figure. The shape was fitted to the published longest edge (500 mm), volume (668.624 cm³) and the four loading-zone volumes, all matched exactly. The mirror image fits equally well. The WC wedge mass design is the author's own, not the paper's.
- **Bille has a tiny design margin.** Its centre of mass sits 0.81 mm inside a zone at most 1.48 mm deep, and "a 0.1 g glue blob at a far vertex moves it ~0.25 mm" (README.txt).
- **The 21-corner body is the paper's idealisation** (point masses, weightless skin). The findings PDF says it is "essentially a mathematical object". Domokos & Kovács' Table 1 centre-of-mass values could not be reproduced from the stated construction, so the shapes were refitted (opt21/optnk). The 26- and 37-corner bodies are refitted for a 0.5 mm polycarbonate shell with tungsten weights.
- **Logged paths are dynamic, not quasi-static.** Bodies dropped or set down carry momentum and can cross a face in under the 0.03 s that counts as lying on it, or rock back up a band (S1 → S2). Fixed on 15 Oct 2026: such a quickly crossed face is no longer dropped from the log; it is printed in brackets, e.g. "B -> (A) -> D"; a bracketed face later lain on properly is replaced by the plain name.
- Found 16 Oct 2026, physics not changed: **the restitution slider's 0.1 is 0.02 at the table.** Bullet multiplies the two bodies' restitution (and friction), and the table's is 0.2. The slider's help said only "bounciness"; it now gives the product, and a comment at the table gives both products (friction 0.4, restitution 0.02 at the table; 0.25 and 0.01 body on body). No theory check uses the restitution; the value was chosen, not measured, and a resin body on a wooden table bounces more than 0.02, so the bounce here is on the low side. It is left as it is, since raising it would change the validated statistics.
- **Rolling resistance and spin friction are script-side constant moments** (δ = 50 µm chosen, not measured).
- **Time step depends on speed.** The effective step is 1/3000 s at the default speed and 1/1200 s at speed 0.1, despite the "steps" slider reading 1200 (there is always at least one step per frame). Documented on 15 Oct 2026 in the lua header and the slider's description ("at least one a frame (at 0.02 speed: 3000 a second)"); not changed, since a step independent of speed would need fractional steps per frame. No convergence study is documented for this exhibit.
- **The PLA-only polyhedron is a design, not yet a printed object.** Every number for it is calculated: exact mass properties, simulated print errors and Bullet runs. No real print has been made or weighed yet. Its robustness was computed for random face-plane, wall, density and elephant-foot errors, not for warping, a dented or uneven table, or a slicer that fills the void. A filled body (1.65 kg) has its centre of mass at 57.5 mm and rests on most of its faces; print/README.md says how to check for this (by weight).
- **Its apex can split.** In about a fifth of simulated builds with face-plane errors there are 2 unstable vertices at the tip instead of 1. They are next to each other: under 1 mm apart at 0.1 mm errors and up to 3.8 mm at 0.5 mm. Their distances from the centre of mass differ by 1.6 to 39 µm. The body still has exactly one stable face, so it is still monostable, but strictly it is then not a "discrete Gömböc" with one stable and one unstable equilibrium. The robust_a66.log column "1 unst. pt" (unstable vertices merged within 1 mm) shows the same effect: 100 / 96 / 92 / 86% at 0.1 / 0.2 / 0.3 / 0.5 mm.
- **PLA-only failures in the drop tallies are table effects, not false resting faces.** Every failure in the located run was either touching another body or lying across the joint between the flat table and its 8° sloping band. At gallery scale the bodies are 24–52 cm across on a 226 × 164 cm flat. A body resting on the slope has no face within the 2° of straight down that the detector asks for. At the real 15 cm size no failure was seen (219/219 drops, 36/36 set-downs).
- `reconstruction/pla/apexcluster.py`, the original study's script for the apex split, gave nonsense when re-run (38 "unstable vertices", with the whole body counted). It was replaced by `apexsplit.py`, which calls robust.py's own trial and equilibrium code. The ~21% figure in robust_a66.log and apexsplit.py's 18–19% (a different random seed) agree within sampling.
- **Not fully tested.** The polyhedra were tested in only 10 drops and 3 set-downs here, and the 21-corner body takes 11–16 s to settle at this scale. All results come from one short session.

**References**
- G. Almadi, R. J. MacG. Dawson, G. Domokos, "Building a monostable tetrahedron", arXiv:2506.19244 (2025); Quanta Magazine, 2025-06-25.
- G. Domokos, G. Almadi, K. Regős, R. Dawson, "On Equilibria of Tetrahedra", Math. Intelligencer (2023).
- G. Domokos, F. Kovács, "Conway's spiral and a discrete Gömböc with 21 point masses", Amer. Math. Monthly 130 (2023); arXiv:2103.13727.
- S. Bozóki, G. Domokos, F. Kovács, K. Regős, Int. J. Solids Struct. (2021) and Eur. J. Oper. Res. 310 (2023), as cited in the findings PDF.
- W. M. Spears with Claude, "One resting point is not enough" (../Gomboc/gomboc-findings.pdf, 2026).
