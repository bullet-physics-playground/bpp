## Bille Drop (weighted monostable bodies)

**What it shows** — These are bodies that rest on only one face because of where their mass is, not because of their shape alone.

- **Bille** is the monostable tetrahedron of Almadi, Dawson & Domokos (2025): a hollow carbon-tube frame with a dense tungsten-carbide wedge, so that set down on any face it tips, face to face, onto face D. It has one stable face and two unstable corners.
- **The spiral polyhedra** (after Domokos & Kovács 2023) have 21, 26 and 37 corners, each with equal weights at the corners. Each has one stable face (the base) and one unstable vertex (the apex). Their bands of side faces tip one onto the next: … → S2 → S1 → base.

Bodies are dropped at random orientations or set down on a wrong face, and the console prints the faces each one passed through.

**Model** — Bullet handles contact through each body's convex hull: the 4 vertices for Bille, the corner points for the polyhedra. Mass and principal inertia are taken from the data files:
- **Bille at size 1:** 120 g, I = (0.219, 1.225, 1.321) kg·cm². The collision margin is the real tube radius, 0.05 cm.
- **Polyhedra:** scaled 4.5× to 40 cm tall, with mass scaling as size³.
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

**Run used** (random seeds from the clock; one run each)
```
cd demo/WyomingWill/Bille && HOLD_S=0 timeout 1500 bpp -f bille-drop.lua -n 9000                      # speed 0.02, 3 s simulated
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
- **Not fully tested.** The polyhedra were tested in only 10 drops and 3 set-downs here, and the 21-corner body takes 11–16 s to settle at this scale. All results come from one short session.

**References**
- G. Almadi, R. J. MacG. Dawson, G. Domokos, "Building a monostable tetrahedron", arXiv:2506.19244 (2025); Quanta Magazine, 2025-06-25.
- G. Domokos, G. Almadi, K. Regős, R. Dawson, "On Equilibria of Tetrahedra", Math. Intelligencer (2023).
- G. Domokos, F. Kovács, "Conway's spiral and a discrete Gömböc with 21 point masses", Amer. Math. Monthly 130 (2023); arXiv:2103.13727.
- S. Bozóki, G. Domokos, F. Kovács, K. Regős, Int. J. Solids Struct. (2021) and Eur. J. Oper. Res. 310 (2023), as cited in the findings PDF.
- W. M. Spears with Claude, "One resting point is not enough" (../Gomboc/gomboc-findings.pdf, 2026).
