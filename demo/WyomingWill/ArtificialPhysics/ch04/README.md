# Ch. 4 — Perfect formations (4.1), uniform coverage (4.3) and Couette flow (4.4), checked against the book

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

## Ch. 4.4 — Couette flow (kinetic theory)

`BOOK.md` entry 4.4 (PDF 147–156, Listing 4.5, Eqs. 4.2–4.6,
`book/ch04.md`). `kt.nlogo` as plain Lua, operation for operation:
particles with no forces, only velocities, in a corridor between a yellow
wall moving down and a red wall moving up at Wall_Velocity V. A particle
with any other within 2 picks one at random and the two exchange velocity
as in a collision at a random angle (momentum and relative speed kept); a
particle within 1 of a wall patch is given a new velocity, the normal
part Rayleigh (s = √T, away from the wall) and the tangential part
Gaussian (σ = √T) plus the wall's velocity. Defaults: 1000 particles,
V 1.0, T 0.010.

| File | What |
| --- | --- |
| `couette.lua` | The model (the world, the step, the 13-column histogram, compute-stats, Resample), with two switches of ours: `split` (measures, changes nothing) and `inward` (below) |
| `couette1.c` | The same model in C, about 200 times faster, for the long runs: the same random numbers in the same order, so the same numbers to the last bit (checked on Lua 5.1, 5.2, 5.3 and 5.4) |
| `couette1_reference.txt` | Two short runs of the C, which the check repeats in Lua |
| `../checks/ch04_couette.lua` | 10 checks, about 75 s (any Lua 5.1–5.4, and BPP) |
| `Couette-Vehicles.lua` | The model flown by vehicles through velocity commands (G4; below), on any vehicle with `velocity()` |

**Where the book's text is silent, the `.nlogo` decides:** a world of
patches −42…42 that wraps in x and y; the walls are the three patch
columns at each side (pxcor 40–42 red, −42…−40 yellow), and "near" is a
patch centre within 1, so a wall acts from x ≈ ±39; a red check then a
yellow one, so across the wrap (x ≥ 42) yellow wins; particles start at
7/8 of a uniform position with speed 1.2533√T in a random integer
direction; every tick all collide, one at a time in a new random order,
then all move; collision angles are integer degrees; the 13 columns
split −42…42 with strict edges; the setup's state is the first sample.
The `.nlogo` sums the speeds but has no mean-speed monitor; the book
"adds one" (PDF 154), which we read as the mean of |v| over the particles
and the samples since Resample.

### What the walls do (FINDINGS F85)

A particle that steps into a wall zone (x beyond ±39) is given its new
velocity, but it is often still in the zone after the next move, and then
it is drawn again; it leaves only on a draw large enough to carry it out.
So the wall emits the size-biased Rayleigh, not the Rayleigh it draws:
particles leaving a wall carry |vx| = 1.40–1.42 √T and vx² = 2.38–2.44 T,
against 1.2533 and 2 (a fully size-biased Rayleigh has 1.596 and 3; the
zone is about one step deep, so the bias is partial). The gas is heated
past T, everywhere, not just at the walls: the mean speed of the
particles away from the walls is the same as the mean of all.

`inward` thermalises a particle only while it moves into the wall, so a
particle on its way out is left alone: the emission is then close to the
Rayleigh (|vx| 1.27–1.28 √T, vx² 2.03–2.09 T). It is Kerr's rule
(Garcia's DSMC wall, below) and, since 2026-10-28 (William), the default
of `couette.lua`, `couette1.c` and `Couette-Vehicles.lua`; `inward =
false` is the `.nlogo`'s wall. The tables here name the rule each run
used.

### Fig. 4.23: the velocity profile

The book: V = 0.5, 1.0, 1.5, 2.0, 10,000 ticks each with Resample at
5,000; the slope agrees "almost perfectly" with 2V/12 = V/6, slightly
below at 2.0, correlation > 0.999 always. Read off the figure at 400 dpi
(one pixel is 0.0004 in slope): on V/6 to within a pixel to V ≈ 1.5, and
about 0.3297 at 2.0. Ours, 10 seeds each (sd 0.0005–0.0010 in slope):

| V | V/6 | `.nlogo` slope | ratio | corr | `inward` slope | ratio | corr |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 0.5 | 0.0833 | 0.0839 | 1.007 | 0.9980–0.9991 | 0.0829 | 0.995 | 0.9979–0.9989 |
| 1.0 | 0.1667 | 0.1707 | 1.024 | 0.9987–0.9991 | 0.1676 | 1.005 | 0.9986–0.9991 |
| 1.5 | 0.2500 | 0.2540 | 1.016 | 0.9992–0.9994 | 0.2495 | 0.998 | 0.9992–0.9994 |
| 2.0 | 0.3333 | 0.3352 | 1.006 | 0.9995 | 0.3295 | 0.989 | 0.9995–0.9996 |

- **The profile is linear, as the book says,** and the left half sweeps
  down and the right half up (Fig. 4.22). It is not quite straight: a
  slight S, flatter by the walls (end bars at 0.96–0.97 V), steeper in
  the middle.
- **As written, the `.nlogo` sits 1–2.5% above V/6**, a difference the
  book's figure would show (12 pixels at V = 1); with `inward` it lies on
  V/6 within 0.6% up to V = 1.5 and at 0.3295 for V = 2 against the
  figure's ~0.3297. Fig. 4.22 (V = 1, 15,032 ticks, no Resample) says the
  same: 0.16256 in the book, 0.1646–0.1660 for the `.nlogo` (5 seeds).
  The book's runs behave like `inward`. `kt.nlogo` is the book's own
  model (William's NetLogo 6 conversion; the converter changed only
  `foreach` syntax, not `go-particles`), and its wall has no direction
  test, so the book's figures came from another version of the code or
  other settings; the book does not say which. Kerr's KT simulator
  (Garcia's DSMC wall: thermalise when a step would cross the wall,
  placed back as if bounced; his thesis, printed p. 27) has exactly the
  `inward` behaviour, so an earlier `kt.nlogo` most likely had that rule
  (our inference; F85).
- **V/6 is a good rule, not an exact law here.** The slope moves with
  the gas's density and temperature (`.nlogo`, V = 1, 3 seeds): N 500,
  1000, 2000 give 0.960, 1.027, 1.075 × V/6; T 0.001, 0.01, 0.04 give
  1.050, 1.027, 0.990. "Almost perfect" holds to a few percent.
- **The correlation** is 0.998–0.9995 at 5,000 samples, a little under
  the book's "always > 0.999" for V ≤ 1; it is averaging noise: run
  15,032 ticks as for Fig. 4.22 we get 0.9994–0.9995 against its
  0.99954.
- **Steady by 5,000 ticks:** 100,000 ticks (Resample at 50,000) give
  0.1701–0.1707 at V = 1, the same as 10,000.
- **The momenta stay near 0** (Fig. 4.22's −0.002, −0.008): ours are
  within 3 standard errors of the mean of 1000 velocities, |P| ≲ 0.03.

### Fig. 4.24: mean speed against temperature, walls at rest

The book: √T = 0.01…0.20 in steps of 0.01, 100,000 ticks each with
Resample at 50,000; fit v̄ = 1.2617 √T + 0.0013, r = 0.9996 (Eq. 4.6),
against the theory's 1.2533 √T (Eq. 4.5, 2D, k = m = 1).

Ours, 2 seeds per rule (`couette1.c`, the book's protocol, 1000
particles; the speed is the mean over particles and the samples since
Resample):

| Rule | Fit (each seed) | r |
| --- | --- | --- |
| book (Eq. 4.6) | 1.2617 √T + 0.0013 | 0.9996 |
| `.nlogo` | 1.3584 √T + 0.0003; 1.3631 √T + 0.0001 | 0.99999 |
| `inward` | 1.2981 √T + 0.0004; 1.2940 √T + 0.0006 | 0.99997 |

| √T | `.nlogo` v̄/√T | `inward` v̄/√T |
| --- | --- | --- |
| 0.01 | 1.346–1.388 | 1.289–1.315 |
| 0.02 | 1.355–1.368 | 1.296–1.319 |
| 0.05 | 1.364–1.370 | 1.311–1.327 |
| 0.10 | 1.360–1.372 | 1.300–1.310 |
| 0.15 | 1.358–1.365 | 1.295–1.303 |
| 0.20 | 1.357–1.367 | 1.290–1.298 |

- **v̄ is proportional to √T, as the theory says** (r = 0.99997 or
  better, intercepts under 0.001), at every temperature: the model has
  no scale of its own in speed.
- **As written, the `.nlogo` gives 1.36 √T, 8.5% above Eq. 4.5** and
  7.8% above the book's fit: its walls heat the gas (above). The mean
  speed away from the walls is the same as the mean of all, so it is not
  the wall particles that raise the average (our first guess, wrong).
- **`inward` gives 1.30 √T at 1000 particles, and the book's value at
  fewer:** at √T 0.1 (3 seeds, ±0.01 each) N = 30, 100, 300, 1000 give
  1.271, 1.256, 1.268, 1.304, while the `.nlogo`'s stays at 1.360,
  1.352, 1.340, 1.366. The book's 1.2617 fits walls that leave outgoing
  particles alone at a density below 1000 particles; its scatter
  (r = 0.9996, against our 0.99997 at 1000) also suggests fewer
  particles. Which N it used, the book does not say.

The Android app (`kinetic/KineticTheorySimulation.kt`) follows the model
except: x is clamped to ±42 instead of wrapping; the wall zone is
|x| ≥ 39 whatever y; neighbours strictly within 2; collision angles are
continuous; every particle is binned, ±42 included. With all five in our
C (5 seeds) its slopes are 1.012, 1.024 and 1.007 × V/6 at V = 0.5, 1
and 2, the `.nlogo`'s: it has the same wall, and the same heating.

### Couette flow on vehicles (G4, FINDINGS F88, F89)

`Couette-Vehicles.lua` runs `kt.nlogo`'s step on vehicles through
velocity commands (`velocity()`, G4): every KT tick (5 Hz) it senses the
vehicles' actual positions and velocities, records the profile of the
actual velocities, runs one tick of collisions and walls
(`couette.lua`'s `collide`) and commands each vehicle its new velocity.
The world is the model's (85 × 85 units, 1 unit = 0.5 m, so V = 1 is
2.5 m/s and the collision range 1 m), wrapping along the corridor. KT
keeps its own velocities, the ones it commanded, as the formation
harness keeps AP's and Kerr's robots carry theirs; `senseVelocity`
collides the sensed ones instead. V 1, T 0.01, `.nlogo` walls, 10,000
ticks with Resample at 5,000; "lag" is the mean |actual − commanded|
velocity at sensing over the mean commanded speed.

| Vehicles | N | Slope / (V/6) | corr | Mean speed / √T | Lag | Wall overshoots / 1000 ticks |
| --- | --- | --- | --- | --- | --- | --- |
| ideal (2 seeds) | 100 | 0.911, 0.940 | 0.9994 | 8.04–8.07 | 0 | 0 |
| point mass, the drone's limits (2 seeds) | 100 | 0.957, 0.916 | 0.9986–0.9992 | 8.19–8.27 | 0.12 | 5–6 |
| point mass, lag 0.6 / 0.9 / 1.5 s | 100 | 0.952 / 0.911 / 0.768 | 0.996 / 0.991 / 0.938 | 8.3–8.7 | 0.14–0.18 | 12 / 39 / 72 |
| quadcopters (2 seeds) | 100 | 0.208, 0.184 | 0.90–0.96 | 1.44–1.81 | 0.72–0.75 | 11–16 |
| ideal | 1000 | 1.023 | 0.9988 | 8.34 | 0 | 0 |
| point mass, lag 0.1 / 0.45 / 0.9 s | 1000 | 1.019 / 1.022 / 1.041 | 0.9976–0.9988 | 8.27–8.31 | 0.11 / 0.27 / 0.35 | 0 / 0.1 / 3.6 |
| point mass, sensed velocities | 1000 | 0.002 | 0.49 | 0.04 | — | 0 |
| point mass, sensed velocities (2 seeds) | 100 | 0.04, 0.08 | 0.68–0.86 | 0.81–0.82 | — | 0 |

- **The ideal vehicle is the model:** through the whole sense → collide
  → command loop it gives `couette1.c`'s 1.02 × V/6 at N 1000; at N 100
  the slope is 0.91–0.94 (F86: it falls with density).
- **Lag does not break the profile** while KT keeps its own velocities.
  At N 1000 a vehicle collides about every 0.25 s, yet point masses with
  lags of 0.1, 0.45 and 0.9 s keep the slope (1.02–1.04) and the gas's
  energy; at N 100 it holds to 0.9 s and weakens at 1.5 s (0.77), where
  vehicles overshoot the walls 72 times per 1000 ticks. Lag moves the
  vehicles late; it does not act like extra viscosity, as `BOOK.md` §5
  guessed.
- **Colliding the sensed velocities freezes the gas.** A vehicle sensed
  part-way to the velocity its last collision gave it takes that mix
  into the next collision, which loses energy as an inelastic collision
  does: the mean speed falls to 0.04–0.8 √T, vehicles stop reaching the
  walls and the profile is gone (0.002–0.08). So a robot must carry its
  KT velocity as state, not measure it.
- **The drones crash into each other.** Their velocity-mode response is
  only a little slower than with waypoints (t63 0.6–0.7 s), and a point
  mass with even more lag keeps the profile; but KT's collisions are
  virtual, nothing keeps two airframes apart, and 40 of 100 drones were
  down by 300 s (seed 1, 1500 ticks), each failing with a neighbour 0.16–
  0.53 m away. Down drones answer no command, which is the 0.72–0.75
  "lag" and the lost profile. Kerr assumes "the robots have low-level
  routines that prevent actual collisions" (his thesis, printed p. 37)
  but gives none; KT on drones needs one. Which (a short-range repulsion under the
  KT command, or a larger virtual collision range) is the next decision.

### Not done

Collision avoidance under KT for the drones (above); the boats (they
have `velocity()`; at 0.79 m/s the model's V must be scaled down) and the
ground robots (no `velocity()` yet). ★ 3D (a slab between two planes) is
open.
