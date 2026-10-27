# Ch. 4 — Perfect formations (4.1) and uniform coverage (4.3), checked against the book

## Ch. 4.1 — Perfect formations

`BOOK.md` entry 4.1 (PDF 124–130, Listing 4.1, `book/ch04.md`).
`formation_perfect.nlogo` as plain Lua, operation for operation, run at
the model's own defaults (100 particles, G 1000, p 2.5, Fmax 1, friction
0.5, Δt 1, D 25, square first, a start in a normal cluster of sd 20).
Each particle has an attribute (m, n), its slot: a smaller m belongs to
the left, a smaller n below, in a frame shared through a compass. Inside D
a pair attracts instead of repelling when it is in the wrong order for its
attributes; for the triangle, two special cases push a pair apart along
one axis only, which breaks Newton's third law (PDF 128–130).

| File | What |
| --- | --- |
| `perfect.lua` | The model: `init-m-n` as written, Listing 4.1's rules, Toggle Formation, One is Born, the momenta; the fit of the ideal lattice that measures "perfect"; and our third-law variant for the author's question (a) |
| `../checks/ch04_perfect.lua` | The results as 12 short checks, about 10 s (any Lua 5.1–5.4, and BPP) |

**How "perfect" is measured** (the book shows pictures only). The ideal
lattice the attributes describe (square: D (m, n); triangle: D (m/2,
n√3/2)) is fitted to the particles by least squares, moved, turned and
scaled. A formation is **formed** when every particle is within 0.25 D of
its own slot; the fit also gives the RMS distance, the lattice's angle
from the compass axes and its spacing. A wrong order shows as a particle
about one spacing from its slot.

**Results** (10 seeds each, with three toggles after each start;
"formed" within 5,000 ticks of the start or 20,000 of a toggle; the
particles never stop: they dither about their slots at about 1–2
patches a tick, as the split law does at D):

| Run | Formed | Ticks to form | Angle | RMS / worst (D) | Momenta |
| --- | --- | --- | --- | --- | --- |
| Square from the start | 9 of 10 | 120–200 (median 160) | −1.4 to 1.9° | 0.03 / 0.06–0.09 | \|L\| < 10⁻¹¹, \|P\| < 10⁻¹² |
| Triangle from the start | 10 of 10 | 170–200 (median 190) | −0.9 to 1.2° | 0.02 / 0.05–0.06 | \|L\| up to 300–850, \|P\| < 10⁻¹² |
| Toggled to the triangle | 25 of 30 | 210–390 (median 280) | **+11.3 to +13.2°** | 0.02 / 0.04–0.07 | \|L\| up to 330–650 |
| Toggled to the square | 29 of 30 | 150–2330 (median 180) | **−11.8 to −15.2°** | 0.03 / 0.06–0.09 | \|L\| up to 24 (left from the triangle) |
| Triangle, third law kept (question a) | 6 of 10 in 20,000 ticks | 850–2230 | −1.2 to 1.8° | 0.03–0.09 / 0.06–0.24 | \|L\| < 10⁻¹¹ |

- **Both lattices form perfectly** from the model's start: every particle
  in its own slot, spacing within 0.4% of D, in 120–200 ticks.
- **Momenta as the book says:** linear momentum is conserved by both
  lattices (to rounding), angular momentum by the square only; the
  triangle's special cases inject it while the particles sort themselves
  (|L| up to 850), and it falls back to about 0 once they are in order.
- **Toggle Formation rebuilds the other lattice, perfectly, but turned.**
  Every rebuilt lattice has each particle in its slot, but the lattice
  sits 11–15° off the compass axes: triangles +11° to +13°, squares −12°
  to −15°, and it stays there (followed to 50,000 ticks). During a
  rebuild the formation turns as a whole (seed 1: from about 40° to 12°,
  with L negative throughout) and stops where the order constraints are
  all met. The rules only test which side of each other two particles
  are, so nothing turns a lattice back to the axes once it is in order.
  The rules have no handedness: with the whole problem mirrored left to
  right (positions and every m) the angle comes out exactly opposite
  (+10.6° and −10.6°, −12.7° and +12.7°, from ideal starts); the
  handedness is `init-m-n`'s, whose square and triangle rings number the
  particles in different rotational orders. The final angle does not
  depend on the start's (an ideal square turned −12° or +12° still ends
  at +11° to +12°); why 11–13° in particular we have not found. A
  lattice fitted without turning shows the rebuilt ones 0.7–0.8 D from
  "ideal", which is what first looked like a failure. Fig. 4.4's last
  panel may well be turned too; at its size we cannot tell.
- **One is Born works:** of 60 clones added one at a time (3 seeds × 10
  per lattice), 57 reached their slots in 10–210 ticks; 3 square clones
  waited until the next clone arrived. At 110 particles both lattices were
  perfect.
- **Changing D** abruptly from 25 to 30 is followed within 100–200 ticks
  (3 seeds per lattice; spacing within 1% of the new D), and so are 25 →
  20 and a slow climb to 30 (1 every 50 ticks); a jump from 20 to 30 left
  the triangle disordered (worst 0.4 D) for 200 ticks, perfect again by
  500. **Shrinking D slowly (0.5 every 200 ticks, 3 seeds) breaks the
  formation into clusters at D = 16.5 for the square (all seeds) and
  14.5–15 for the triangle.** That is not at G_t: there G 1000 is already
  4.4 × Eq. 3.5's G_t2 (square) and 4.0–4.3 × Eq. 3.4's G_t (triangle); a
  formed lattice holds far above G_t (Ch. 3's hysteresis). It breaks where
  the force at D reaches the cap, G / D^p ≈ Fmax (0.90 for the square, 1.1–
  1.25 for the triangle), i.e. at G ≈ Fmax D^p = S × G_t, S = 2 + 2√2 or
  2√3: every force near D is then the same capped size and the rules can
  no longer hold the slots. (We first put it down to G > G_t, citing Eq.
  3.4 for both lattices: wrong.) The model's Good Gravitational Constant
  monitor tells the user to lower G with D.
- **The author's question (a), perfect triangles without breaking the
  third law** (ours: the two special cases repulse along the line, like
  every other case): yes, but only 6 of 10 starts formed within 20,000
  ticks, in 850–2230 ticks against the model's 170–200, with angular
  momentum conserved. The broken third law is what makes the triangle
  form fast, as the book says.
- **Failures seen** (the two followed to 100,000 ticks did not heal): (1) a
  particle left more than its sensing range (1.3–1.7 D) from all others
  never joins (square, seed 7: 2.2 D from the nearest, 4.2 D from its
  slot); (2) in 4 of the other 29 toggles to the triangle the worst
  particle stays 0.72–0.75 D from its slot; in the one we looked at (seed
  1) a short edge row of 3 particles sits one place along from its slots.
  An edge row has few neighbours to put it in order.
- **`init-m-n`** gives 100 distinct square slots on a checkerboard of the
  particles' parity (who mod 2, as the square law needs) and 127 distinct
  triangle slots; the 128th particle repeats a slot (the code says "good
  up to 126 particles"), so One is Born past 127 cannot form a perfect
  triangle.

**The Android app** (`perfect/ParticleSimulation.kt`) follows the model
except: single precision; r below 0.1 is raised to 0.1 (NetLogo would
divide by zero); a clone starts at rest (NetLogo's `hatch` copies the
velocity); its angular momentum skips particles slower than 0.01. None
changes the results above.

## Ch. 4.3 — Uniform coverage checked against the book and William's runs

`BOOK.md` entries 4.3a and 4.3b (PDF 139–147, `book/ch04.md`). The two
coverage models, `uniform.nlogo` (turn only at walls and other agents)
and `uniform_mfpl.nlogo` (also turn after a mean free path), as plain Lua
that does what each `.nlogo` does, operation for operation, checked
against Table 4.2, Figs. 4.17 and 4.19 and William's own NetLogo and
Android runs (`uniform_data.txt`); and the BPP scene `../Uniform_Coverage.lua`
(a port of the Android app) run on the same grid.

| File | What |
| --- | --- |
| `coverage.lua` | The two models: the world, the agents' step and the deviation (Eq. 4.1) |
| `sweep.lua` | The deviation over agents and mean free paths, with the stopping rule below |
| `uniform_data.txt` | William's runs, as he sent them (2026-10-25): NetLogo and Android deviations for 1–1000 agents, MFP 1–120, and two BPP columns (before and after FIXES 4–5). Run lengths were not recorded (tens of millions of ticks, depending on the agents) |
| `Uniform.ods` | William's sheet (Nov–Dec 2025): NetLogo and Android, one agent, and NetLogo's 1000 agents at MFP 1–100, with a chart; its numbers are those in `uniform_data.txt` |
| `../checks/ch04.lua` | The book's results as 8 short checks, about 40 s (any Lua 5.1–5.4) |
| `../probes/coverage_sweep.lua` | The BPP scene under the same stopping rule, for `lib/batch.py` |

**Where the book's text is silent, the `.nlogo` decides** (`coverage.lua`
has the details): a world of patches −42…42 that wraps, with the border
patches the yellow wall; agents start at 15/16 of a uniform position and
a random integer heading; every tick they move one at a time in a new
random order; an agent turns (random 360) when the patch 1 ahead or 2
ahead at ±45° is wall, another agent is within 3 patches and 15° of its
heading, or its step count reaches the mean free path, trying up to nine
times; the nine cells split −40…40 at ±13⅓, the outer ones reaching the
wall; every agent is counted in its cell every tick, the setup's count
included.

**Stopping rule** (William: "pick a fair stopping criterion"). The right
length depends on the agents and the mean free path, so every run uses
the same rule: agent steps (agents × ticks) in doubling blocks from 2 ×
10⁷, stopping when the deviation is within 1% of its value a block
earlier, or at 2 × 10⁸ agent steps, the book's budget for Fig. 4.19 (one
particle 2 × 10⁸ ticks, 100 particles 2 × 10⁶). A run that hit the cap
without meeting the 1% test is marked \*.

### William's runs, reproduced

Seed 1. "NetLogo copy" is `coverage.lua`; "BPP scene" is
`Uniform_Coverage.lua` (the Android rule: turns only when the next step
would cross the arena's ±40 edge; FIXES 36, FINDINGS F16), whose own
MFP 120 is the "none" of its slider.

| Agents | MFP | NetLogo (William) | NetLogo copy (ours) | Android (William) | BPP scene (ours) |
| --- | --- | --- | --- | --- | --- |
| 1 | 1 | 0.00057 | 0.0029* | 0.00122 | 0.0032* |
| 1 | 4 | 0.000402 | 0.0019* | 0.000437 | 0.0020* |
| 1 | 10 | 0.0014 | 0.0022 | 0.00073 | 0.00062* |
| 1 | 17 | 0.0038 | 0.0039 | 0.0019 | 0.0018 |
| 1 | 30 | 0.0072 | 0.0073 | 0.0043 | 0.0035 |
| 1 | 50 | 0.023 | 0.0231 | 0.016 | 0.0157 |
| 1 | 100 | 0.026 | 0.0267 | 0.036 | 0.0367 |
| 10 | 1 | 0.0011 | 0.0035* | 0.0011 | 0.0029* |
| 10 | 4 | 0.0005 | 0.0018 | 0.00075 | 0.00082* |
| 10 | 10 | 0.0014 | 0.0018* | 0.0006 | 0.0015* |
| 10 | 17 | 0.00347 | 0.0034 | 0.00176 | 0.0017* |
| 10 | 30 | 0.0068 | 0.0068 | 0.0038 | 0.0033 |
| 10 | 50 | 0.0203 | 0.0204 | 0.0144 | 0.0131 |
| 10 | 100 | 0.0256 | 0.0254 | 0.033 | 0.0347 |
| 100 | 1 | 0.0011 | 0.0026* | 0.0016 | 0.0135* |
| 100 | 4 | 0.00046 | 0.0015* | 0.0013 | 0.0029* |
| 100 | 10 | 0.00064 | 0.0011* | 0.00027 | 0.0028* |
| 100 | 17 | 0.0019 | 0.0017 | 0.00084 | 0.0012* |
| 100 | 30 | 0.0030 | 0.0032 | 0.00085 | 0.0015* |
| 100 | 50 | 0.0029 | 0.0029 | 0.0027 | 0.0032* |
| 100 | 100 | 0.016 | 0.0162 | 0.020 | 0.0212* |
| 1000 | 1 | 0.0042 | 0.0037 | 0.0040 | not run |
| 1000 | 4 | 0.0033 | 0.0040 | 0.0031 | not run |
| 1000 | 10 | 0.0036 | 0.0039 | 0.0041 | not run |
| 1000 | 17 | 0.0042 | 0.0040 | 0.0046 | not run |
| 1000 | 30 | 0.0044 | 0.0049 | 0.0048 | not run |
| 1000 | 50 | 0.0044 | 0.0045* | 0.0047 | not run |
| 1000 | 100 | 0.0044 | 0.0045 | 0.0048 | not run |

\* not settled (the 1% test failed at the cap). The BPP scene's 100 agents
ran to 2 × 10⁷ agent steps only, and its 1000 agents not at all: the
scene tests every pair of agents every tick (10⁶ tests a tick for 1000),
so the full budget would take days; its 1000-agent numbers stay
William's Android ones. William's own BPP runs at MFP 17 (0.0016 for one
agent; 0.0013 and 0.0014 for 10 before and after FIXES 4–5; 0.0011 and
0.0005 for 100) sit with the scene's here.

**MFP 17 and above: the copy reproduces William's NetLogo column**, to
within a few percent for 1–100 agents and about 10% for 1000; the BPP
scene reproduces his Android column the same way. **Below 17 neither run
settles within 2 × 10⁸ agent steps.** With a mean free path of a few
steps an agent random-walks between cells, so the deviation there is
sampling noise falling as ~1/√(agent steps): one agent at MFP 1, 4 and
10 over four seeds gives 0.0029–0.0040, 0.0009–0.0020 and 0.0013–0.0022,
against William's 0.00057, 0.0004 and 0.0014. Reaching his values would
take ~10⁹–10¹⁰ ticks, so his small-MFP numbers come from much longer runs
(or are the lucky end of the spread); they are not a disagreement.

### One agent run long: the mean free path as an upper bound

What Fig. 4.19 tests (PDF 144–146): the theory's 0.65 × cell size (17⅓
here) is an **upper bound**. Very short mean free paths give excellent
uniformity but carry a robot across the region slowly; the aim is the
largest mean free path whose coverage matches the 10,000-particle
swarm, a deviation of 0.003, given time. `coverage1.c` is one agent of
the Android rule (as `../Uniform_Coverage.lua`) in C, about 20 million
steps a second; `coverage1_sweep.sh` runs it for MFP 120 down to 1.

| File | What |
| --- | --- |
| `coverage1.c`, `coverage1_sweep.sh` | The program and the sweep (one seed: the time average stands for the ensemble, Sec. 11.2.6) |
| `coverage1_william.txt` | William's run of it, 2026-10-26: MFP 1–100, 5.12 × 10⁹ steps each, as he sent it |
| `coverage1_runs.txt` | Ours: every checkpoint from 1.25 × 10⁷ steps, doubling through Fig. 4.19's 2 × 10⁸, until no improvement at two checkpoints in a row (at most 1.6 × 10⁹) |

| MFP | 2 × 10⁸ steps | 5.12 × 10⁹ (William) | ratio |
| --- | --- | --- | --- |
| 1 | 0.0030 | 0.0008 | 3.7 |
| 2 | 0.0019 | 0.0008 | 2.3 |
| 5 | 0.0008 | 0.0005 | 1.8 |
| 9 | 0.0007 | 0.0002 | 3.5 |
| 12 | 0.0011 | 0.0005 | 2.3 |
| 15 | 0.0012 | 0.0009 | 1.3 |
| 17 | 0.0016 | 0.0015 | 1.05 |
| 20 | 0.0014 | 0.0014 | 1.00 |
| 24 | 0.0006 | 0.0003 | 2.5 |
| 28 | 0.0012 | 0.0014 | 0.9 |
| 30 | 0.0033 | 0.0034 | 0.95 |
| 50 | 0.0157 | 0.0157 | 1.00 |
| 62 | 0.0069 | 0.0068 | 1.01 |
| 100 | 0.0371 | 0.0369 | 1.01 |

- **At or below the bound one agent beats the swarm's 0.003**: at 5.12 ×
  10⁹ steps every MFP from 1 to 28 is below it, 0.0002–0.0008 for MFP
  1–14 and at most 0.0017 for 15–21.
- **Below about 15 the coverage keeps improving with time** (2–4 times
  better from 2 × 10⁸ to 5.12 × 10⁹ steps; the shortest paths, which
  cross the region slowest, need the longest runs: MFP 1 only just meets
  0.003 at the book's budget). **From about 17 up the value is fixed by 2
  × 10⁸ steps**, a property of the turning rule, not of the run: 0.0013–
  0.0017 at 15–21, still good; from about 30, worse than the goal and no
  better with time (0.037 at 100). Good uniformity "at about 15 or less"
  with the bound at 17⅓, as the book says.
- **The layout's own good regions**, as the book explains for 53–65: a
  dip at 22–27 (to 0.00025 at 24, near one cell width, 26⅔) and the dip
  at 53–65 (deepest 0.0068 at 62). They are this environment's, so 0.65
  × cell size stays the safe choice.
- The Android rule is lower than the book's NetLogo curve below about 50
  (the wall rule, F16), with the same shape. Our runs and William's agree
  to 3–4 digits where both are settled (MFP 84: 0.02913 at 1.6 × 10⁹,
  0.02913 at 5.12 × 10⁹), as they should: same program, same seed.

### The book's results

| Book | Ours (`coverage.lua`) |
| --- | --- |
| Table 4.2 (`uniform.nlogo`, no mean free path): 1, 10, 100, 1000, 10,000 particles give 0.027, 0.026, 0.016, 0.004, 0.003 | 0.0272, 0.0265, 0.0168, 0.0045 (10,000 not run) |
| Fig. 4.17: one particle visits the corners most, then the edges, the centre least | Corners 0.1200, edges 0.1064, centre 0.0942 (mean shares, 5 × 10⁶ ticks) |
| Fig. 4.19, one particle: below 0.003 for MFP ≲ 15, a bump at ~17, poor above ~30, plateau ~0.027 | MFP 10: 0.0013–0.0022 (not settled); 17: 0.0039; 30: 0.0073; 50: 0.0231; 100–120: 0.0267–0.0272 |
| ... a dip between MFP 53 and 65 (turning at the far edge of the centre cell, 53⅓ and 66⅔ away) | 55: 0.0210, 60: 0.0124, **65: 0.0037**, 70: 0.0059, 80: 0.0184 |
| Fig. 4.19, 100 particles: ~0.002–0.005 to MFP 55, then up to ~0.017 | 17: 0.0017, 30: 0.0032, 50: 0.0029, 55: 0.0027, 60: 0.0062, 65: 0.0095, 80: 0.0153, 120: 0.0168 |
| MFP 120 is "none": the longest straight path, 80√2 ≈ 113, is shorter | MFP 120 and no MFP give the same deviation to the last digit (0.02722) |

### Not done

Ch. 11.5–11.6 (turns at walls only, then mean-free-path turns, on Maxim's
cell-based simulator) are the same questions as Table 4.2 and Fig. 4.19 on
a different simulator. Table 11.1 (Ch. 11.8) is done on Maxim's own
simulator: `../ch11/README.md`.
