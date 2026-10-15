## Gomboc Variety (uniform-density Gömböcs)

**What it shows** — A Gömböc is a convex body of uniform density with exactly one stable and one unstable equilibrium, so however it is set down it rolls back to the same upright pose. The table drops up to 12 bodies at random orientations, cycling through three shapes: the real Gömböc (Gomboc-C, at 9 cm and at 75% and 125% size) and two of M. L. Sloan's analytic Gömböcs (β = 0.07 and 0.08). The lesson is that having one resting point in theory is not enough. Gomboc-C rights itself every time, while the gently sloped Sloan shapes usually stall on their sides under ordinary rolling resistance.

**Model** — Bullet handles contact. Each body is a `btConvexHullShape`:
- **Gomboc-C:** the convex hull of a 1.2 mm tessellation of the GOMBOC900 CAD B-spline surfaces (13,476 points, per gomboc-drop-c.lua).
- **Sloan shapes:** hull points of r⁴ = 1 + 4β sinφ cos(θ − 5φ).
- **Margin:** 0.04 cm, scaled with size.
- **Mass and inertia:** exact (CAD or analytic) at resin density 1.2 g/cm³. That gives 323 g at 9 cm, 136 g at 75%, 630 g at 125%, and 407 g / 401 g for β = 0.07 / 0.08.

The script steps the world itself at 1200 steps per simulated second (20 substeps of 1/1200 s per 1/60 s frame), using Bullet's semi-implicit Euler. Before every substep it applies two losses as constant moments at the contact:
- rolling resistance M = δ·m·g, with lever arm δ = 150 µm by default;
- spin friction of 0.7 rad/s².

Other settings: friction 0.5 (Bullet multiplies it by the table's 0.8), restitution 0.1 (table 0.2), air drag 0, no taps. The tray is flat with 8° ramps at the edges and a rim. Status thresholds: "Upright" means within 15° of the resting normal for 2 s. "At rest" means less than 0.2° of turn and 0.02 cm of movement over 2 s. Five seconds after a body comes to rest it is lifted away and the next shape is dropped (GV_REDROP).

**Theory checks**

| Quantity | Theory (formula / source) | Simulation (this run) | Agreement |
|---|---|---|---|
| Gomboc-C rests only on its one stable point | 1 stable + 1 unstable equilibrium (CAD surface checked, code comment) | random drops: 11 of 11 runs that came to rest were upright, tilt 0.4–7.9°; 60 s tally: 8 Gomboc-C runs, 0 not upright | 100% upright |
| Gomboc-C from a headstand (balanced on the unstable point, 1–3° nudge) | must leave the unstable point and right itself | 3 of 3 at rest upright: 0.3°, 4.0°, 12.5° (the last propped against a neighbour) | consistent |
| Sloan β 0.07 / 0.08 self-righting at 150 µm rolling resistance | one basin (mathematically monostatic); findings PDF Table 5b: 14 of 157 (9%) upright | drops: 13 of 13 runs at rest NOT upright (18–142°); headstand 0 of 3 (71–138°) | 0/16 vs 9% expected (about 1.4 of 16); small sample |
| Residual tilt of Gomboc-C at rest | 0° ideal; with a constant rolling moment it stops short. gomboc-drop-c.lua comment, corrected 15 Oct 2026: "0.3-8 deg ... (7.9 deg the most seen, on the 75% one in Gomboc Variety: the smaller, the further off)" (was "0.3-7 deg") | report run 0.3–7.9° (excluding the propped 12.5°); seeded re-run 15 Oct 2026: 0.3–4.6° | within the corrected range |
| Time to right from a headstand, 75% / 100% / 125% | findings PDF Table 6: 8.8 / 13.2 / 14.3 s | 8.75 / 13.03 / 2.73 s (125% was knocked by a neighbour) | 75% and 100% within 0.2 s |
| Mass at 100 / 75 / 125% | V·ρ = 268.851 cm³ × 1.2 g/cm³ = 322.6 g; × s³: 136.1 / 630.1 g | 323 / 136 / 630 g | exact |
| Hull's false resting faces (Gomboc-C) | ideally none | code comment: 34 hull resting faces, all within 16° of true rest, deepest needs a 0.53 µm lift | — (documented) |
| Height of balancing point above resting point | findings Table 5: Gomboc-C 11.3 mm; Sloan β 0.07 / 0.08: 4.8 / 5.1 mm | — (documented) | — |
| Energy drift with all losses off (step-size check) | no gain | gomboc-drop-c.lua comment: at 1200 steps/s "energy stays level, with no steady gain"; 2400 "no better"; 600 also no steady gain | documented, not rerun |

The 60-second tally printed by this run (time to rest, median and range): Gomboc-C 2 runs, 1.2 s (1.2–6.4). At 125%, 3 runs, 17.2 s (6.4–22.0). At 75%, 3 runs, 8.3 s (5.0–11.0). β 0.07: 5 runs, 3.1 s, 5 not upright. β 0.08: 5 runs, 5.7 s, 5 not upright.

**Run used** (random seed from the clock; one run each, so the numbers vary)
```
cd demo/WyomingWill/Gomboc && HOLD_S=0 stdbuf -oL timeout 3000 bpp -f gomboc-variety.lua -n 4200   # 70 s, 6 bodies, redrop 5
HOLD_S=0 GV_START=headstand GV_REDROP=0 timeout 3000 bpp -f gomboc-variety.lua -n 3600             # headstands
```
(A 9000-frame run was started but stopped: on the shared 2-core machine it ran at well under 1/5 of real time.)
```
  Orange  at rest after  17.15 s, 0.5 deg off upright -- Orange (Gomboc-C at 125%)
  Yellow  at rest after   8.30 s, 7.9 deg off upright -- Yellow (Gomboc-C at 75%)
  Purple  at rest after   2.25 s, 133.6 deg off upright  ** NOT UPRIGHT ** -- Purple (Sloan beta 0.07)
=== 60 s: 18 finished runs ===
    Gomboc-C at 125%             3 runs, time to rest median  17.2 s (6.4-22.0)
    Gomboc-C at 75%              3 runs, time to rest median   8.3 s (5.0-11.0)
    Sloan beta 0.07              5 runs, time to rest median   3.1 s (1.9-11.1), 5 not upright
    Sloan beta 0.08              5 runs, time to rest median   5.7 s (1.9-13.1), 5 not upright
  Yellow  upright after   8.75 s -- Yellow (Gomboc-C at 75%)
  Red     upright after  13.03 s -- Red (Gomboc-C)
  Red     at rest after  16.05 s, 0.3 deg off upright -- Red (Gomboc-C)
  Green   at rest after  16.22 s, 137.5 deg off upright  ** NOT UPRIGHT ** -- Green (Sloan beta 0.07)
```

Seeded re-run after the fixes (15 Oct 2026):
```
GV_SEED=3 GV_COUNT=4 GV_REDROP=1 HOLD_S=0 bpp -f gomboc-variety.lua -n 3700
=== 60 s: 13 finished runs ===
    Gomboc-C                     3 runs, time to rest median  12.8 s (11.8-14.0)
    Gomboc-C at 125%             2 runs, time to rest median   6.4 s (2.6-10.3)
    Gomboc-C at 75%              2 runs, time to rest median   5.1 s (3.0-7.1)
    Sloan beta 0.07              3 runs, time to rest median   3.5 s (1.6-5.1), 2 not upright
    Sloan beta 0.08              3 runs, time to rest median  10.4 s (7.2-20.3), 1 not upright
```
In the 60 s tally 1 of 3 β 0.07 and 2 of 3 β 0.08 runs ended upright; over the whole run (every body that came to rest, first report each) 1 of 4 β 0.07 and 2 of 5 β 0.08. So in this seeded run the Sloan shapes sometimes righted themselves, unlike the report's 0 of 16. 3 of 9 is more than the PDF's 9% (Table 5b) would make likely (a 4% chance), 0 of 16 less (22%); the samples are small and bodies here knock into each other, so neither run tests the 9% well. One β 0.07 body (Green, run 1) was re-reported at rest five times (4.4 to 51.6 s, creep) and so never entered the tally.

Pause and hall checks after the lift fix (15 Oct 2026): with `GV_SEED=3 GV_COUNT=4 GV_REDROP=1`, HOLD_S=0 for 900 frames is line for line a prefix of the default half-second pause for 930 frames (31 lines, lifts and redrops inside the window); hall against standalone (cmp2.sh, 1200 frames): IDENTICAL (32 run lines).

**Known departures and honest caveats**
- Fixed 15 Oct 2026: the attendant's lift ran during the start pause (a `holdTick` that called `liftStep`), so with the pause on the output differed. `holdTick` is removed; the lift waits for the pause to end and the pause changes nothing (checks above).
- **Rolling resistance and spin friction are script-side models.** They are constant moments, not Bullet physics. δ = 150 µm and 0.7 rad/s² were chosen, not measured. The findings PDF (Table 5b) shows that the outcome depends strongly on δ: without rolling resistance nothing ever settles, Gomboc-C included.
- **Gomboc-C stops a few degrees short of upright** (here up to 7.9°). The constant moment holds it wherever gravity's restoring lever is smaller than δ, and its valley is flat. The code says this is real behaviour.
- **The Sloan shapes are not strictly convex at these β.** They roll on their convex hull. The findings PDF cites arXiv:2604.17120, which finds strict convexity only below β ≈ 0.036. The hull gains a second basin at higher β. Re-checked 15 Oct 2026 by re-running the reconstruction's basin scan (scanb.py's method, form 1, 25000 surface points) at finer β: deepest extra basin 5.9 µm at 0.08 (the hull facets' own noise is ~5 µm), 11.9 µm at 0.085, 25.3 at 0.09, 43.0 at 0.095, 66.7 at 0.10 (the PDF's Table 5 gives 67 at 0.10 and none at 0.08). The lua comment ("first found at beta 0.085") was consistent with this; it now gives the depths and notes that the PDF rounds the limit to "above β ≈ 0.09". The scan result is recorded in variety-reconstruction/README.txt. The PDF was not edited.
- **The β 0.08 resting point:** the lua says its lowest point is ~35° from the formula's minimum; computed 15 Oct 2026 from the `down` and `top` vectors in gomboc-meshes/beta1-08.lua: 34.6° (β 0.07: 4.6°). The findings PDF §4 says the Sloan shapes' "true resting orientation lies 4–5° from the formula's minimum", which holds for β 0.07 only; its own §5 says the balancing point sits ~35° off the top on β 0.08. This inconsistency inside the PDF is now noted in variety-reconstruction/README.txt (there is no Gomboc README.md). The PDF was not edited.
- **Re-reported rests (creep).** Several bodies were reported "at rest" again and again: Yellow #3 (125%) five times between 19.6 and 32.4 s, and one β 0.07 three times. Each time the body had moved more than 0.2° or 0.2 mm within 2 s after being declared at rest, which matches the contact-solver creep admitted in gomboc-drop-c.lua ("up to ~0.3 deg and ~0.7 mm per minute"). The tally uses the last of these times.
- Fixed on 15 Oct 2026, tally median: with an even number of runs the "median" used to print the lower middle value; it is now the mean of the two middle values, in gomboc-variety.lua and gomboc-drop-c.lua. Seeded re-run: "Gomboc-C at 125%  2 runs, time to rest median 6.4 s (2.6-10.3)" = mean of 2.58 and 10.27 s.
- **Collisions between bodies** (props, knocks) affect individual results. The console flags them as "touching".
- Fixed on 15 Oct 2026: variety-reconstruction/README.txt listed meshes beta1-06 and beta2-04, which are not in gomboc-meshes/. It now names the two kept (beta1-07, beta1-08), says gen.py's __main__ makes a different larger-β set, and that the kept files' `down` is the lowest face of the hull's one basin, not the formula minimum gen.py writes. Sloan's form 2 is left out by design.
- Statistics are from one short run. The Sloan upright fraction (0/16) is compatible with the 9% in the findings PDF, given the small sample.

**References**
- Kiss Attila, GOMBOC900 SolidWorks CAD model (2013), as cited in code.
- M. L. Sloan, "An Analytical Gomboc", arXiv:2306.14914 (2023); MathWorld, "Gömböc".
- "Sloan's Analytical Gömböc at Published β: A Strict-Convexity-Constrained Reanalysis", arXiv:2604.17120 (2026), as cited in the findings PDF.
- P. L. Várkonyi, G. Domokos, "Mono-monostatic bodies: the answer to Arnold's question", Math. Intelligencer 28 (2006).
- G. Domokos, P. L. Várkonyi, "Geometry and self-righting of turtles", Proc. R. Soc. B 275 (2008).
- W. M. Spears with Claude, "One resting point is not enough" (gomboc-findings.pdf, 9 Oct 2026, working notes).
