# Ch. 7 — Gas-mimetic swarms: the theory checks, on Kerr's own code

`BOOK.md` entries 7.1–7.4 (PDF 228–243, `book/ch07.md`; Kerr's thesis,
digest `book/theses/Kerr.md`). The chapter's three theory experiments are
uniform density at rest (Fig. 7.5), mean speed against temperature
(Fig. 7.6) and the velocity profile between one or two moving walls
(Figs. 7.7–7.8). Here they are run on Kerr's own simulator: his 2004 Java,
in this folder as he left it, and ported to Lua operation for operation.

| File | What |
| --- | --- |
| `kerr/` | Kerr's 2004 Java (William's archive, `code.7.04`): one folder per experiment, `StandardCouette` (profile), `UniformDistribution` (density), `AverageSpeed` (speed), each with his gas (`ktphysics/`), his drivers and their output files (`experiments/`), his AP gas (`apgasphysics/`) and his Java of Garcia's program (`physicsorig/`, `physics/`) |
| `kerr_seed.diff` | One line in each `ktphysics/CouettePhysics.java`: the seed from `-Dkerr.seed` instead of the clock (his runs cannot be repeated otherwise) |
| `KerrReference.java` | Ours: runs his gas from a seed and prints the state |
| `kerr_reference.sh` | Builds his Java with the diff (in a temporary copy) and writes `kerr_reference.txt`, four runs that `../checks/ch07.lua` compares the Lua with (needs a JDK) |
| `kerr.lua` | His gas in Lua, with five fixes as switches, all off (his code) by default |
| `obstacles.lua` | Ours: obstacles for his gas (his 2005 generator's layouts; three face rules), for the flow runs |
| `theory.lua` | One run of one experiment, measured as his drivers measured it and as the book defines its error; one line out (the protocols are at its top) |
| `sweep.sh` | The sweeps into `theory_runs.txt` (the tables below) |
| `../checks/ch07.lua` | 15 checks, about 30 s (any Lua 5.1–5.4, and BPP) |

**Provenance.** `kerr/` is the code William found in his archive
(`forclaude.zip`, folder `code.7.04`), April 2004: the simulator behind
the FAABS III paper (Kerr, Spears et al., *Two formal gas models for
multi-agent sweeping and obstacle avoidance*, 2004) and the start of
Kerr's thesis Ch. 5. Taken as it is, but for line endings (CRLF to LF)
and trailing spaces (removed; neither changes what the Java does);
left out are the compiled classes, NetBeans' `.nbattrs` and one 19 MB
output file (`AverageSpeed/experiments/output.txt`). His drivers write to
`C:\cygwin\home\wkerr\repos\FAABSIII\…`; their output files beside them
are his own runs.

**Garcia.** Kerr's gas is Alejandro Garcia's DSMC program for Couette flow,
`dsmcne`, from *Numerical Methods for Physics* (2nd ed., Prentice Hall,
2000; Garcia's code: github.com/AlejGarcia/NM4P), translated to Java and
made two-dimensional: move, sort into cells, collide (no-time-counter
candidates, accepted with probability c_r / c_r,max), with thermal walls
(Maxwell's biased distribution, the particle flying on from the strike
for the rest of the step). Units are Garcia's: argon in SI, a channel
1 µm wide, wall speeds as Mach numbers. `kerr/*/physicsorig/` is Kerr's
Java of Garcia's original (its wall-speed start `vwall * 2*(x/L)-0.5`
has a bracket lost; Garcia's is `vwall*2*(x/L - 0.5)`).

**The port is exact.** `kerr.lua` repeats his Java's arithmetic in the
same order, with his random numbers (Park and Miller's minimal standard).
Four runs from fixed seeds, one per experiment, 200–1,000 steps, end with
the same number of collisions and the same positions and velocities, bit
for bit in most runs and within 10⁻¹² in the others (the maths libraries'
logarithms) — `checks/ch07.lua` 1–4 on Lua 5.1–5.4.

## What his code does that the book does not say

Read from his Java and measured on the Lua (`kerr.lua`'s header has
them line by line):

1. **The collision angle** is Garcia's 3D draw with its azimuth dropped:
   cos θ = 1 − 2U, sin θ = +√(1 − cos² θ), θ from the x axis (across the
   channel). Relative velocities after a collision lean toward the flow's
   axis, and only half the circle is drawn for the first particle of a
   pair (the pair's order is random, so the other half comes from the
   other order). The book's text has θ uniform on [0, 2π) (PDF 236). Fix
   `iso`.
2. **The boxes' walls at y** (the density and speed experiments; the
   walls at x are Garcia's). A particle that crosses y = 0 or y = L is
   placed from where its path crosses the line y = 0, whichever wall it
   hit, then clamped into the box: one that left through y = L comes back
   at y = 0. In the density box it also gets vx = +|Rayleigh|, always
   toward x = L. The speed box reflects vy. Fix `walls` (Garcia's wall
   at y too; the speed box keeps its reflection, placed right).
3. **Collision counting**: n² candidate pairs per cell (Garcia: n(n − 1))
   and c_r,max raised after every candidate (Garcia: after the cell).
   Fix `garcia`.
4. **The profile's start**: Garcia's gradient, vy = V (2x/L − 1) on top of
   the thermal speeds, from −V at one wall to +V at the other, also in the
   one-sided runs, where the flow should go from 0 to V. Fix `rest` (no
   gradient).
5. **The profile's channel is open along the flow.** The cells cover 10 L
   of it, nothing stops the gas beyond; it drifts with the wall, and
   particles past the last row are sorted into it. At Mach 1.2 two in five
   particles are past 10 L by step 500 and all by step 5,000 (y up to
   ~370 L by step 20,000). The profile across the channel is still
   measured (the gas is just denser per cell, and collides more: 0.11 per
   particle per step at the start, ~0.2 later). Fix `periodic` (the
   channel periodic over its cells, as Garcia's), used for the obstacle
   runs.
6. **His error measures** (his drivers, `kerr/*/experiments/`), each
   unlike the paper's and the book's |theory − simulation| / theory:
   - speed: |⟨v⟩ − theory| divided by the **fastest single speed met** in
     the runs (about 4 × ⟨v⟩), not by the theory;
   - density: the counts in 5 × 5 cells summed over the last 199 of
     30,000 steps and divided by 200, cut to integers; the error is the
     sum of the cells' **excess** over N/25, divided by N − N/25 (the most
     excess possible); his runs also carried the grid over from one run
     to the next;
   - profile: per cell, |theory − simulation| divided by the **largest
     error possible** there, max(theory, V − theory), over steps 1–2,000
     from the gradient start.

## Results

### Speed (Exp. 2, Fig. 7.6)

500 particles in the L × L box, 2,000 steps, the mean speed over every
particle and step against √(πkT/2m) (3 seeds; `theory.lua speed`). In
Garcia's units every run is the same at any temperature, scaled: T = 25,
273 and 350 K give the same relative numbers to the last digit (so his
file's spread over T is his clock seeds, nothing else).

| Fixes | err (book) | his measure | ⟨v²⟩ / 2kT/m | ⟨v⟩/√⟨v²⟩ |
| --- | --- | --- | --- | --- |
| none (his code) | +3.75% | 0.82% | 1.084 | 0.883 |
| iso | +2.14% | 0.47% | 1.038 | |
| walls | +2.29% | 0.50% | 1.050 | |
| garcia | +3.56% | 0.78% | 1.079 | |
| iso, walls, garcia | +0.28% | 0.11% | 1.003 | 0.888 |

His own file (`AverageSpeed/experiments/ktphysics.txt`, 20 runs per T):
+3.73%, +3.98%, +3.94% at 350, 25, 273 K by the book's measure. His gas
runs **hot**, by 8% in ⟨v²⟩; the speeds keep Maxwell's shape (0.8862), so
the mean is high because the temperature is. His measure divides the
same error by the fastest speed met and makes it ~0.8%, the level of
Fig. 7.6 (0.9–1.1% at 0% obstacles, read from the figure's source; F94).
With all three fixes the gas is at the walls' temperature and the mean
speed is the theory's to 0.3%.

### Density (Exp. 1, Fig. 7.5)

N particles in the L × L box (20 × 20 cells), started uniform in the
square [L/2, 3L/4]²; the counts in a 5 × 5 grid over the last 199 steps
(`theory.lua density`). His runs: N = 10,000, 12,000 and 15,000, 30,000
steps; his file (`UniformDistribution/experiments/ktphysics.txt`) has
0.186–0.191 by his measure.

| N, steps | Fixes | his measure | book's |
| --- | --- | --- | --- |
| 10,000, 30,000 | none (his code) | 0.187, 0.185 | 36.6%, 36.2% |
| 10,000, 30,000 | walls | 0.007, 0.007 | 1.9%, 2.0% |
| 10,000, 30,000 | iso | 0.179, 0.182 | 34.9%, 35.6% |
| 10,000, 30,000 | iso, walls, garcia | 0.003, 0.005 | 1.2%, 1.6% |
| 100–800, 5,000 | none | 0.16–0.19 | 35–40% |
| 100–800, 5,000 | walls | 0.017–0.035 | 16% (N 100), 11% (200), 9% (300, 400), 5–6% (500–800) |

His gas does not spread uniformly: it piles into the corner x = L,
y = 0 (his own grid at N = 10,000, rows y = 0 to L, columns x = 0 to L):

    311 398 502 722 1364
    303 333 402 522 655
    300 313 359 405 447
    277 278 285 313 318
    231 221 225 228 225      (N/C = 400)

The walls at y send every particle that strikes them toward x = L and
put the ones that leave through y = L back at y = 0 (item 2). With
Garcia's wall there instead (`walls`) the box fills uniformly: 2% off at
N = 10,000; the other two fixes add little (1.2–1.6% with all three).

### Profile (Exp. 3, Figs. 7.7–7.8)

500 particles in the channel L wide (7 cells across), one-sided (the
wall at x = L moving at Mach M, the other at rest) or two-sided (both at
M the same way); the mean vy in 7 columns, averaged over a window of
steps; in Mach (`theory.lua profile`, 3 seeds each). His window is steps
1–2,000 from his start (Garcia's gradient); "rest" is the same window
from a start at rest; "settled" is steps 5,001–10,000. His measure
divides each column's error by the largest possible there; the book's
by the theory (V x/L at the column's centre, V/14 next to the still
wall).

| M | his measure, his window | book's, his window | book's, from rest | book's, settled | settled profile (Mach), theory (k + ½) M/7 |
| --- | --- | --- | --- | --- | --- |
| 0.65 | 0.160 | 61% | 62% | 19% | 0.09 0.16 0.24 0.33 0.41 0.48 0.56 |
| 1.2 | 0.110 | 43% | 46% | 17% | 0.15 0.30 0.45 0.60 0.75 0.89 1.03 |
| 1.792 | 0.091 | 34% | 35% | 16% | 0.22 0.44 0.67 0.90 1.12 1.34 1.56 |
| 1 | 0.123 | 51% | 46% | 20% | 0.14 0.26 0.39 0.51 0.63 0.75 0.86 |
| 2 | 0.082 | 30% | 30% | 15% | 0.25 0.49 0.73 0.99 1.25 1.50 1.75 |
| 3 | 0.055 | 20% | 25% | 13% | 0.35 0.72 1.11 1.49 1.88 2.27 2.64 |
| 4 | 0.046 | 17% | 19% | 11% | 0.44 0.94 1.46 1.99 2.53 3.06 3.56 |
| 5 | 0.036 | 12% | 15% | 8.3% | 0.51 1.14 1.80 2.48 3.17 3.85 4.49 |
| 6 | 0.030 | 11% | 12% | 5.9% | 0.56 1.34 2.16 3.00 3.83 4.66 5.43 |
| 7 | 0.023 | 7.4% | 10% | 4.5% | 0.63 1.53 2.51 3.51 4.49 5.48 6.38 |
| 8 | 0.021 | 5.8% | 8.2% | 3.7% | 0.69 1.73 2.87 4.02 5.15 6.27 7.31 |

His file (`StandardCouette/experiments/newphysics.txt`, 10 runs each):
0.150, 0.115 and 0.088 at Mach 0.65, 1.2 and 1.792, his measure; ours
0.160, 0.110, 0.091 (3 runs). By the book's measure the same runs are
34–61% off: the column by the still wall, where the theory is V/14, is
off by 150–290% (slip: the gas there moves with the rest). His start
does not matter much (from rest within a few points). Settled, the
profile is linear with slip at both walls (at Mach 4 the columns rise by
0.52 each against the theory's 0.57, from 0.44 against 0.29), the error
falls with M, 20% at Mach 1 to 3.7% at 8, and the gas heats with the
shear (collisions per particle per step 0.17 at Mach 0.65, 0.49 at 8).

Two-sided, the flow is flat at V: 0.96–0.98 V in his window (the
gradient start still unwinding), 1.00 V settled (3 seeds at M = 1, 2, 4,
8; error 1.8–3.0% and 0.1–1.0%).

All of this in an open channel whose gas has left the cells it is
sorted into (item 5 above); the theory does not see it, since the
profile across the channel does not depend on where along it the gas is.

### Obstacles (ours; Fig. 7.8's setting)

The code behind Fig. 7.8's obstacles is not in the archive, so we built
them: Kerr's own 2005 layout (`ObstacleGenerator`: blocks on a 40 × 40
grid, pockets cut off from the free space filled; `obstacles.lua`) in
his gas made Garcia's (`iso`, `walls`, `garcia`, `rest`) and periodic
along the flow (`periodic`: an L × L channel, 500 particles, 7 × 7 cells),
V = Mach 4, 8 subcorridors as the book's, steps 3,001–8,000, 3 layouts
and seeds each (`theory.lua flow`). Three rules at the obstacles' faces:
`rest` (a thermal wall at rest, as his 2004 `SquareObstacle`), `couette`
(faces parallel to the flow move at V, as his robots treat them, PDF
229) and `specular` (a mirror). The flow's mean over the subcorridors,
as a share of V:

| Obstacles | 0% | 10% | 20% | 30% | 40% | 50% |
| --- | --- | --- | --- | --- | --- | --- |
| Fig. 7.8 right (two-sided) | 0.90 | 0.84 | 0.78 | 0.77 | 0.65 | 0.48 |
| two-sided, rest | 1.00 | 0.14 | 0.05 | 0.08 | 0.04 | 0.02 |
| two-sided, couette | | 0.27 | 0.16 | 0.16 | 0.10 | 0.06 |
| two-sided, specular | | 0.16 | 0.07 | 0.11 | 0.06 | 0.03 |
| Fig. 7.8 left (one-sided) | 0.45 | 0.35 | 0.28 | 0.21 | 0.06 | 0.02 |
| one-sided, rest | 0.50 | 0.06 | 0.04 | 0.02 | 0.01 | 0.01 |
| one-sided, couette | | 0.17 | 0.14 | 0.10 | 0.08 | 0.05 |
| one-sided, specular | | 0.05 | 0.03 | 0.02 | 0.02 | 0.02 |

Without obstacles this gas gives Fig. 7.8 left's profile closely: linear,
slope 0.76 of the theory's (the figure's 0.80), from 0.67 to 3.33 across
the subcorridors (the figure's 0.39 to 3.20). With obstacles no rule
comes near: 10% of them already stop 73–95% of the flow, where the
figure loses 6% (two-sided) or 23% (one-sided), and about half the
particles move backward. In a steady channel the walls must give all the
momentum the obstacles take, and every rule takes it at the faces across
the flow, which send particles back; moving the parallel faces (the
robots' rule) helps least badly but not enough. Fig. 7.8's flow passes
its obstacles nearly as if they were not there, which a steady gas
cannot do; its runs must have measured something else (a sweep that
never reached steady flow, obstacles in part of the corridor only, or
another rule), which the archive does not show.

Nor are the figures from Kerr's 2005 robot controller: run on his own
robot simulator (William's copy; a driver of ours, 300 robots, wall
speed 4.08 units per step = Mach 4 in his units, 3,000 steps; 4 runs,
which his unseeded robots do not repeat), `KTRobot` gives a U-shaped
profile without obstacles (2.6–3.4 units per step by the walls, 0.9–1.7
in the middle), not Fig. 7.8 right's flat 3.6. Kerr said so himself
(email to Diana and William, 19 March 2011): the journal's theory runs
were "just in Java", in "toroidal worlds" with "several hundred robots",
and "we never reran the experiments on the robot simulator". The
two-sided runs of Fig. 7.8 right were new in August 2006 (his email "Two
Sided Couette Results", 22 August 2006, sent from ISI). That Java gas
simulator, toroidal and with obstacles, is the one not in the archive.
The robot code comes into the repo with the corridor sweep (7.5–7.6).

## The book's figures

The journal paper's sources (William's archive, `journal_wes/`, with
gnuplot's PostScript of each figure) give the book's Figs. 7.5–7.8 curve
for curve: `ktunir.2.eps`, `ktv.2.eps`, `ktvy.2.eps`, `actual-vd.eps` and
`actual-vd-2.eps`. Their plotted points, read from the PostScript:

| Fig. | 0% obstacles | 10–50% obstacles |
| --- | --- | --- |
| 7.5 density error vs N (100–800) | 6.1, 6.2, 6.3, 6.4, 6.5, 6.5, 6.5, 6.5% | 10%: 8.4 → 5.8; 20%: 7.8 → 5.0; 30%: 10.3 → 8.8; 40%: 11.5 → 9.1; 50%: 9.6 → 8.8% |
| 7.6 speed error vs T (50–400) | 0.86–1.14% | 0.64–0.95% |
| 7.7 one-sided profile error vs V (1–8) | 35.4, 23.4, 20.4, 18.2, 16.2, 14.8% (V = 1–6; no points at 7, 8) | 10%: 32.6 → 21.5; 20%: 53 → 36; 30%: 74 → 54; 40%: 103 → 88; 50%: 122 → 102% |
| 7.8 left, one-sided, V = 4, 8 subcorridors | 0.39, 0.78, 1.19, 1.59, 2.00, 2.40, 2.80, 3.20 | 10%: 0.26 → 2.63; 20%: 0.19 → 2.20; 30%: 0.12 → 1.76; 40%: 0.01 → 0.74; 50%: −0.09 → 0.73 |
| 7.8 right, two-sided, V = 4 | 3.57–3.60 | 10%: 3.34–3.42; 20%: 3.10–3.15; 30%: 2.93–3.09; 40%: 2.46–2.70; 50%: 1.78–2.15 |

They are not from the code here: they have obstacles, 300 robots and 8
subcorridors, and the 2004 code has neither obstacles in its drivers nor
those settings. Their simulator (2005, the thesis's) is not in the
archive William has found so far. Against it, the 2004 code's runs:

- **Speed:** Fig. 7.6's ~1% is the level of his measure (0.8%, the error
  divided by the fastest speed met); by the book's measure his gas is
  3.75% off. The book's and the journal draft's "less than 2%" (PDF 241)
  and the thesis's "less than 10%" describe the same plot (F94).
- **Density:** Fig. 7.5's 6% at 0% obstacles is not his 2004 box (36% by
  the book's measure, his corner pile-up); with the walls at y put right
  it is of the figure's order (9% at N = 300, 5–6% from N = 500,
  falling with N as counting noise does, where the figure is flat at
  6.1–6.5%).
- **Profile:** Fig. 7.7's 0% curve lies between his window and the
  settled flow (at V = 2, 3, 4: 23, 20, 18% against 30, 20, 17% and 15,
  13, 11%); Fig. 7.8 left has the same linear profile with slip (slope
  0.80 of the theory's, ours 0.85 in his window, 0.91 settled); Fig. 7.8
  right is flat but at 0.90 V, where his code gives 0.98 V in 2,000 steps
  and 1.00 V settled: a flow not yet spun up, or slower walls.
- **Obstacles:** two kinds are in the archive. His April 2004 gas
  simulator for the FAABS coverage runs (`code.4.04`, not here) has
  squares only (`SquareObstacle`), at rest and thermalising like his
  box's walls (a face across the flow gets a normal speed |N(0, σ)| and
  a tangential +Rayleigh, again always one way). His 2005 robot
  simulator (`obstacle/`) has squares, circles and triangles, and a
  course file can hold all three; but its obstacles are only seen by
  the sonar (circles and triangles are left out of the coverage and
  shadow counts), and all 50 of its courses (40 for the thesis's
  sweeps, 10 for videos, made by its `ObstacleGenerator` from blocks of
  a 40 × 40 grid) hold rectangles only. The triangle, circle and cup of
  Fig. 7.2 (the journal's `kt1`–`kt3.eps`, August 2004) come from a
  version not in the archive. With his generator's layouts in his gas,
  every face rule we tried holds the flow far below Fig. 7.8, where 10%
  of obstacles cost the two-sided flow only 6% (Obstacles, above;
  FINDINGS F94); how the thesis's runs treated obstacles remains open.

## The corridor sweep (entries 7.5–7.6): Kerr's 2005 robot simulator

The chapter's second half (PDF 244–251, Figs. 7.9–7.13) compares Kerr's
KT robots with a Default controller and Koenig's Ant on sweeping a 1000″
× 5000″ corridor with obstacles. William's archive has the simulator
that ran it (`forclaude.zip`, `robotSimulator`, November 2004 to 2005)
with Kerr's own logs of the runs behind the figures.

| File | What |
| --- | --- |
| `kerr2005/` | Kerr's 2005 robot simulator as he left it (William's archive): the world (`env/`), the controllers (`robot/`: `KTRobot`, `AntRobot`, `Simple2` = the book's Default, and others), the sensors (`sensor/`: sonar ring, robot detector, goal, messages), obstacles (`obstacle/`, `obstacleGenerator/`), his drivers (`experiments/IROS.java`, `Thesis_2.java`), his 50 obstacle courses (`data/`) and his thesis logs (`log/thesis/`, 100 runs per setting) |
| `kerr2005_seed.diff` | Six lines: with `-Dkerr.seed` the robots' random generators are seeded from the run's seed instead of the clock |
| `KerrSweep.java` | Ours: his drivers' loop (seeds 100, 101, … over courses and runs) without their graphics, printing his log lines |
| `kerr2005.sh` | Builds it (in a temporary copy) and reruns a sample of his settings into `kerr2005_runs.txt` (about an hour on two cores; needs a JDK) |
| `kerr2005_runs.txt` | That sample: 225 runs |

Taken as it is but for line endings (CRLF to LF) and trailing spaces
(removed); left out are the
compiled classes, NetBeans' `.nbattrs`, two bitmaps, his IROS logs and his
derived summaries (`log/thesis/composite`, `statsig`). Two of his files do
not compile on a current JDK (`util/ImageSaver.java` needs the JPEG codec
Java 7 removed; `robot/Simple.java` repeats a class of `Simple2.java`);
`kerr2005.sh` compiles only what the three controllers use.

**His logs are the book's figures.** Each setting in `log/thesis/` is
100 runs (10 courses × 10 runs; driver, controller, seeds 100–199):

| Controller | 0% | 10% | 20% | 30% | 40% | N 5 | N 10 | N 15 | N 20 | N 25 | N 30 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| KT: total % | 76.9 | 88.6 | 89.8 | 89.1 | 88.4 | 57.2 | 75.0 | 82.7 | 87.0 | 89.8 | 91.9 |
| KT: shadow % | — | 68.2 | 81.4 | 75.7 | 77.7 | 38.8 | 57.9 | 70.7 | 77.5 | 81.6 | 84.6 |
| KT: time (steps) | 4,848 | 12,763 | 20,635 | 24,667 | 52,672 | 13,913 | 16,905 | 18,609 | 20,528 | 20,921 | 22,754 |
| Ant: total % | 98.1 | 98.0 | 97.9 | 97.7 | 97.5 | 96.4 | 97.2 | 97.6 | 97.7 | 97.9 | 98.0 |
| Ant: time | 67,297 | 61,935 | 62,175 | 63,822 | 71,136 | 126,174 | 89,977 | 77,182 | 68,049 | 63,448 | 57,353 |
| Default: total % | 41.9 | 43.4 | 45.1 | 44.9 | 40.7 | 17.7 | 27.9 | 35.0 | 41.2 | 45.6 | 49.7 |
| Default: shadow % | — | 24.6 | 31.6 | 25.0 | 27.1 | 9.9 | 17.2 | 22.2 | 28.0 | 31.1 | 34.5 |
| Default: time | 1,997 | 2,540 | 12,564 | 10,196 | 99,378 | 8,633 | 8,822 | 9,557 | 11,475 | 12,642 | 12,657 |

(Ant's shadow coverage is 100% everywhere.) These are Figs. 7.11–7.13,
point for point as far as the figures can be read. The settings, from his
drivers: 25 robots at 0–40% obstacles (`IROS.java`); N = 5–30 robots at
**20%** obstacles (`Thesis_2.java`, `obstaclePercentage = 20`), where the
book says 30% (PDF 247): his N = 25 runs give what his 25-robot runs at
20% give (total 89.8 and 89.8, shadow 81.6 and 81.4, time 20,921 and
20,635), not those at 30% (89.1, 75.7, 24,667). Each point is **10**
corridors × 10 runs, where the book says five (PDF 246–247). The KT
robots' moving-wall speed is 0.4 (`KTRobot.wall`, default 2.0); robots
move 6″ a step when the way is clear (`Robot.VMAX`).

**His code gives his logs.** Rerun (`kerr2005.sh`: the first run of each
course, 10 per setting, 5 for Ant over 0–40% only), every setting agrees
with his 100 runs within 3 standard errors in total and shadow coverage
(`checks/ch07.lua`); the means:

| Controller | 0% | 10% | 20% | 30% | 40% | N 5 | N 10 | N 15 | N 20 | N 30 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| KT: total % (his) | 77.0 (76.9) | 88.7 (88.6) | 89.9 (89.8) | 89.4 (89.1) | 88.6 (88.4) | 54.3 (57.2) | 76.5 (75.0) | 83.7 (82.7) | 87.5 (87.0) | 91.9 (91.9) |
| KT: shadow % | — | 66.4 (68.2) | 82.2 (81.4) | 73.7 (75.7) | 78.8 (77.7) | 38.1 (38.8) | 61.3 (57.9) | 72.1 (70.7) | 78.0 (77.5) | 83.9 (84.6) |
| Ant: total % | 98.1 (98.1) | 98.0 (98.0) | 97.9 (97.9) | 97.7 (97.7) | 97.5 (97.5) | | | | | |
| Default: total % | 43.4 (41.9) | 45.4 (43.4) | 46.8 (45.1) | 46.1 (44.9) | 41.9 (40.7) | 17.4 (17.7) | 28.3 (27.9) | 34.1 (35.0) | 42.4 (41.2) | 50.7 (49.7) |

Sweep times scatter more (a few runs hit the 150,000-step limit) but agree
within 2 standard errors. Default's total coverage sits 1–2 points above
his at 0–20% obstacles (up to 2.7 standard errors), the one systematic
difference; his logs may come from a slightly earlier `Simple2`.

**What the code does that the book does not say** (the Lua port below
has the first and two of the KT robot's as switches):
- All KT robots share one random sequence: each seeds its generator from
  the clock in milliseconds when it is created, and all 25 are created in
  the same millisecond (Ant too; Default adds its id).
- The run ends when every robot has spent 10 steps near the goal line or
  at 150,000 steps; robots that finish stop where they are.
- Every move builds a log line of every robot's state
  (`Environment.logRobotInformation` tests its debug level the wrong way
  round) and the logger then drops it, its level being off: nothing is
  written (`log/debug.txt` stays empty; we said it was written, F99).
- The KT robot (F98): its speed is always the safe distance, 6″ when the
  way is clear; the velocity the collisions give sets only the heading
  (Listing 7.1's `max(…, 6)`, capped at V_max, says the same; PDF 246:
  "the magnitude of the velocity of all robots is fixed"). A robot told
  its velocity by a partner reads the sender's bearing where the angle
  should be, and 0 for the bearing (`CommunicationSensor.prepMessages`
  writes slot 1 twice). Its wall's line is fitted from the first sonars,
  counted from sonar 0 one way round and from sonar 23 the other, that
  see anything within 60″, taken to lie at 45° − 15° i and −45° +
  15° (23 − i), not the leftmost and rightmost within ±45° that see
  something within 15″ (PDF 232); ε is 45°.

## The Lua port of the 2005 simulator (step 2)

| File | What |
| --- | --- |
| `kerr2005.lua` | His world, sensors and the three controllers (`KTRobot`, `AntRobot`, `Simple2`) in Lua, operation for operation, every float operation of his Java rounded to a float; Java's random numbers (`java.util.Random`) exactly; three switches (below), off by default (his code) |
| `kerr2005_run.lua` | One run from his drivers' seed, printing his log line |
| `KerrTrace.java`, `kerr2005_reference.sh`, `kerr2005_reference.txt` | Ours: five runs of his Java from fixed seeds, the state at their last step, which `../checks/ch07.lua` compares the Lua with (needs a JDK) |
| `kerr2005_port.sh`, `kerr2005_lua_runs.txt` | A sample of `kerr2005_runs.txt` (his Java, rerun) rerun on the Lua, line for line |
| `kerr2005_fixes.sh`, `kerr2005_fix_runs.txt` | The switches on KT at 20% obstacles, his 10 courses |

Only rectangles are ported (all 50 of his courses are rectangles; his
circles and triangles are in none). Sensing skips the robots, obstacles
and walls beyond a sonar's reach (63″; the cut is 80″), which his code
tests and finds out of range: the results are the same, 20–50 times
faster. In Lua 5.1, 25 robots on a 20% course take about 5–8 ms a step
with KT (2–4 minutes a run), 15 ms with Default and 1 ms with Ant (its
robots read one sonar a step). LuaJIT runs it about 7 times faster with
the same results to the bit (a KT run at 20% in 13 s against 86 s;
`../checks/ch07.lua` passes on it), which the full sweep uses.

**The port is his Java.** The five reference runs (KT without obstacles
and at 20% with 5 robots, to the end; KT, Ant and Default at 20% for
1,000, 2,000 and 500 steps) end in his state, the same cells covered at
the same step (`../checks/ch07.lua`). Whole runs compared every 1,000
steps stay bit for bit (Ant at 20%, 98,544 steps; Default at 40%,
51,706) or within 7 × 10⁻¹³ (KT at 20% and 40%, 28,076 and 32,798 steps):
Java's cos and sin (HotSpot's) and the C library's differ in the last bit
of 0.2% of calls, and those enter the positions, which are doubles (its
atan2, acos and log, fdlibm's and HotSpot's, differ in 8–18% and 0.1% of
calls, but only reach floats). The sample of his Java's reruns
(`kerr2005_runs.txt`) rerun on the Lua (`kerr2005_port.sh`: KT and
Default at every setting, courses 0–2, Default at 40% on course 6 only;
Ant at 0% and 20%; 60 runs, up to 64,552 steps) gives his lines exactly,
the same sweep times and the same cells. So the Lua stands in for his
code, and his logs' agreement with it (F96) carries over.

**Switches** (`o.fix`; `kerr2005_run.lua`'s last argument):
`seeds` gives each KT and Ant robot its own random numbers (seed + id, as
Default); `messages` lets a told robot read the velocity it was told;
`wallfit` fits the wall from the leftmost and rightmost sonars within
±45° that see something within 15″, as the book says. KT, 25 robots, 20%
obstacles, the first run on each of his 10 courses (`kerr2005_fixes.sh`):

| Switches | Total % | Shadow % | Time (steps) |
| --- | --- | --- | --- |
| none (his code; his Java's reruns) | 89.9 ± 0.4 | 82.2 ± 1.1 | 23,214 ± 2,084 |
| `seeds` | 90.2 ± 0.5 | 82.3 ± 1.3 | 22,460 ± 1,472 |
| `messages` | 89.5 ± 0.6 | 83.0 ± 1.1 | 19,864 ± 2,532 |
| `wallfit` | 90.1 ± 0.4 | 82.1 ± 1.3 | 23,891 ± 1,976 |
| all three | 90.0 ± 0.4 | 81.0 ± 1.4 | 22,097 ± 2,244 |

(mean ± standard error, 10 runs each.) None moves the sweep beyond its
noise: the book's text and his code give the same coverage and time
here, so his figures stand for the controller the book describes. The
switches stay, off, for the sweep on BPP's robots (step 3).

## The full sweep (step 3, on William's machine)

`kerr2005_sweep.sh` runs the book's two experiments with Kerr's protocol
on the port: Exp. 1, 25 robots at 0–40% obstacles; Exp. 2, 5–30 robots at
20% (his setting, F97); 10 courses × 10 runs per setting, his seeds. It
runs each controller with his code, and KT and Ant again as the book
describes them (KT: `seeds`, `messages`, `wallfit`; Ant: `seeds`; Default
has no switch). That is 5,000 runs, about 16 CPU-hours with LuaJIT
(Default at 40% runs 150,000 steps on most courses, about 90 s each, and
goes first). Runs in parallel, and resumes where it stopped (runs already
in `kerr2005_sweep_runs.txt` are skipped; a run done twice counts once):

    sudo apt install luajit                      # once
    bash ch07/kerr2005_sweep.sh                  # all cores; Ctrl-C and rerun at will
    luajit ch07/kerr2005_figs.lua                # Figs. 7.11-7.13 so far

`kerr2005_figs.lua` prints the three figures as tables: his logs' mean,
ours with his code (± the 95% interval, as the book's error bars, with
the number of runs and z against his logs) and ours with the book's
version.
