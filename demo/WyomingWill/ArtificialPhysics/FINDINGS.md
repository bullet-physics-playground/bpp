# Findings: experiments, confirmations and errors

A running record of what the conversion has found: the book's results we have
reproduced, new results, errors and discrepancies in the book and in the
other implementations, and our own mistakes, corrected. It is updated with
every patch that finds something, and `FINDINGS.pdf` beside it is rebuilt
each time. `BOOK.md` says what to build and `FIXES.md` what was fixed in the
code; this file says what was learned.

**How to read an entry.** Each has an ID, the date, what was done, the
numbers, where the evidence lives (a check script, a README or a probe), and a
status: **Confirmed** (the book's claim, reproduced by our own measurement),
**New** (a result the book does not have), **Book error** (the book disagrees
with its own code, figures or arithmetic), **Book discrepancy** (the same,
but small or an omission, not changing the conclusion), **Divergence** (NetLogo, the Android
app and BPP differ), **Our error** (something we got wrong, and how it was found
and corrected) or **Open** (measured but not yet settled).

Page numbers are PDF pages of `apbook1.pdf`; book page = PDF − 31.

## 1. The book's results, reproduced

**F1. Appendix A: glibc `random()` is biased, and BPP uses it** — 2026-10-17,
Confirmed. `checks/rng_appendix.lua`.
BPP's `math.random` is glibc `rand()` = `random()`, in Lua 5.1 and 5.2 alike
(William's BPP links 5.2, the cloud build 5.1). Run with Listing
A.1's sampling (S extra calls per accepted point in the unit disk, 10⁶
points, 36 bins, 99.9% cut χ² 66.6), it fails at S = 25 (χ² 321) and 27
(409), as the book shows (PDF 646–648); Lua 5.2 the same (321, 410); also
S = 26 (223) and 3 (70). The multiply-with-carry generator now in `lib/rng.lua` passes at
every S tried (χ² 26–47).

**F2. Ch. 2.1 spring1D, every result** — 2026-10-17, Confirmed.
`checks/ch02.lua`, `ch02/README.md`.
Momentum exactly 0; the separation oscillates symmetrically about D (27.000
to 73.000); period ×√10 at k = 1 (1.405 and 4.443); the centre of mass sits
by the heavy mass at ratio 10; friction 0.001 drains the energy (2641 to
0.016) and the separation settles at D; changing D mid-run moves the energy
to a new constant level (2641 to 998).

**F3. Ch. 2.2 spring2D: angular momentum and the centrifugal stretch** —
2026-10-17, Confirmed. `checks/ch02.lua`.
Angular momentum constant to 2×10⁻¹⁴, linear momentum 10⁻¹²; mean
separation 77.8 > D = 50; the maximum exceeds 2D = 100 for every seed tried
(111–118), with spring2D.nlogo's random start (F41).

**F4. Ch. 2.3 solar_system, experiments a–e** — 2026-10-17, Confirmed.
`checks/ch02.lua`.
(a) A lighter sun gives a larger orbit, more so for AM 15 (87 to 133) than
AM 10. (b) At Δt 0.1, AM 5 escapes (E from −121 to +111) and AM 0 is nonsense
(E to 448,804). (c) At Δt 0.001, AM 5 orbits properly and AM 0 still shoots
off left (x = −36,312). (d) Velocity caps fail: Vmax 9 drops the planet into
the sun (|P| up to 891). (e) Force cap Fmax 1: bound, precessing rosettes
(AM 4 precesses 112° per orbit); AM 0 swings through the sun, 0 to 15.6 away.

**F5. Ch. 2.3e: the book's peak speeds are right** — 2026-10-17, Confirmed.
`checks/ch02.lua`.
The text's "5.6, 5, 4 and 9 (when AM is zero, one, four and nine)" (PDF
84–85) looked non-monotone, and `book/ch02.md` advised re-measuring. We get
5.50, 4.97, 4.00, 9.00. For AM 4 and 9 the start is the closest point, so the
peak is the starting speed; AM 0 falls straight through the sun and AM 1
nearly does, so both peak near the centre.

**F6. Ch. 11.3: the mean free path 0.651757, and 0.6079 with a buffer** —
2026-10-17, Confirmed. `ch11/README.md`, `checks/mfp_theory.lua`.
The integral, computed to 60 digits, is 0.6517567914559… (Eq. 11.4 gives
0.651757); the 5% buffer gives 0.607939 (PDF 383: 0.6079). Listing 11.4 at
10⁷ samples agrees within one standard error.

**F7. Ch. 11.2: coverage converges to a seed-independent limit** —
2026-10-17, Confirmed. `HANDOFF.md` §6.
As the book argues from ergodicity (PDF 380), long runs from different seeds
reach the same deviation: at MFP 50 / 100 with one agent, 0.0158 / 0.0368
from both seeds to within 1%.

**F8. Fig. 4.19: 100 agents cover more evenly than 1 at large mean free
paths** — 2026-10-17, Confirmed.
At equal visits (5×10⁷), MFP 30 / 50 give 0.0035 / 0.0158 with one agent
and 0.00087 / 0.0035 with 100. Crowding adds turns, shortening the effective
free path. Agents are near-independent only when they rarely meet.

**F43. Ch. 13.2: the split-Newtonian point mass dithers across D** — 2026-10-18,
Confirmed (E2, PDF 447–449). `checks/ch13.lua`, `probes/settle_drones.lua`.
The book says the sign flip at D lets a point mass dither across it with
almost no net motion. The 2D particle replica of the drone law (G 1500,
power 2.2, forceMax 1.5, D 50, friction 0.6, 40 particles) does exactly that:
after 1,500 ticks the bonds are at 0.99 D but every particle still moves
0.55 units per tick. Flown by 50 drones the dither becomes real motion that
never stops: 0.27 m/s (2D) and 0.47 m/s (3D) after 170 s, 190 and 324
AR-boundary crossings per drone per minute, and a suggested-position gap
of 6 and 11 cm (3 seeds each). Lennard-Jones on the same drones settles in
20 s (2D) and at the last launch wave (3D).

**F44. Ch. 13.5: AR damping η settles the Newtonian drones like LJ** —
2026-10-18, Confirmed on drones (the book's Pioneers settle, PDF 454).
`quadcopter/README.md` ("Ch. 13 on the drones"). With η (Eq. 13.9, power 1)
and nothing else, the same 50 drones settle (scalar acceleration below
0.1 m/s² from then on; but see F52 for when the lattice is formed) 6 s
after AP engages in 2D and 29 s in 3D, when the
last launch wave joins (LJ: 20 s and 31–33 s); AR crossings fall to 0–1 per
drone per minute, speed to 0.001–0.003 m/s, the gap to 0.03–0.09 mm, with no crashes
(baseline 2 per 2D run). This answers `BOOK.md` §1 item 1's expectation:
yes, η alone does it, because the law is then smooth through zero at D.
The square and cube formations settle too: 6 s (2D square, LJ 23–25 s) and
27 s (cube, LJ 33 s), against 0.33 and 0.63 m/s of endless jitter without
η; LJ's cube is the more regular (bond CV 0.007–0.03 against η's
0.07–0.09). The lattice η settles into is the subject of F45.

## 2. New results

**F9. The mean free path in 3D: 0.7720 × the cube edge** — 2026-10-17, New.
`ch11/README.md`, `ch11/mfp_exact.py`, `checks/mfp_theory.lua`.
For cubic cells with face neighbours, the mean distance from a robot uniform
in a cube to entering the next is 0.771991712645…, or 0.713804 with the 5%
buffer. An integer-relation search on the 60-digit integral finds
90 f = 4 + 17√2 − 6√3 − 7π + 21 ln(1+√2) + 42 ln(2+√3), agreeing to 50 digits
(found by search, not proved). Listing 11.4 extended to 3D agrees within one
standard error. In BPP's coverage box (edge 26⅔) that is a mean free path of
20.6, or 19.0 with the buffer, against 17⅓ in 2D.

**F10. The 2D mean free path in one line** — 2026-10-17, New.
12 f = 2 + √2 + 5 ln(1+√2), equal to the book's Eq. 11.3–11.4.

**F11. Uniform Coverage: deviation limits by agent count** — 2026-10-17, New.
At 5×10⁷ visits (ticks × agents), mean of two seeds:

| MFP | 1 agent | 10 agents | 100 agents |
| --- | --- | --- | --- |
| 1 | 0.0046 | 0.0036 | 0.0031 |
| 4 | 0.0028 | 0.0020 | 0.0024 |
| 10 | 0.0019 | 0.0023 | 0.0014 |
| 17 | 0.0021 | 0.0020 | 0.0014 |
| 30 | 0.0035 | 0.0036 | 0.00087 |
| 50 | 0.0158 | 0.0131 | 0.0035 |
| 100 | 0.0368 | 0.0347 | — |

MFP 30–100 have converged (seeds agree); MFP ≤ 17 are still falling as
1/√visits and are upper bounds. At equal visits one agent covers as evenly as
ten, so what agents buy is time (F8 is the exception, when they crowd).

**F12. The book's integrator: energy swings but does not drift** —
2026-10-17, New. `checks/ch02.lua`, `checks/monitors.lua`.
Semi-implicit Euler keeps energy bounded, with a swing inside each cycle of
about Δt·ω: 0.45% for spring1D at Δt 0.001, 16% at the closest approach of
the AM 15 orbit at Δt 0.1, 8% for AM 5 passing 1.6 from the sun at Δt 0.001.
The drift between the start and end of a run is 10⁻⁴ or less for the springs and 0.2% for the coarsest orbit. The energy error
is first order in Δt (10.2× smaller for 10× smaller Δt). "Constant energy" in
the book means no drift.

**F13. Ch. 3's obstacle field, measured from the figures** — 2026-10-17,
New. `lib/world.lua` (`World.CH03_DISCS`).
Both panels of Fig. 3.25 give the same 12 disc centres within a pixel,
shifted as a group (F40). Scale 2.11 px per patch at 300 dpi from the discs
(20 across), confirmed by the formation's 63.3 px node spacing (D = 30). In
the model's world (701 × 401, goal at (−175.25, 0); F40) the field's centre
is at (−8, −11); the closest gap is 5.2 patches ("narrowly spaced"). Fig. 3.26
is a different field (F37).

**F42. spring3D stays in one plane** — 2026-10-18, New. `ch02/Spring3D.lua`:
from random 3D starts, L keeps its direction to 2×10⁻¹² degrees.

**F45. η shrinks the lattice when the range reaches second neighbours** —
2026-10-18, New. `checks/ch13.lua`, `quadcopter/README.md`.
In 2D at the default range 1.5 D, η settles the drones at 0.83 D (power 1)
and 0.805 D (power 2.2) instead of D, on all 3 seeds; the particle replica
gives 0.82–0.85 and 0.79–0.81, so this is the law, not the drones. η damps
the nearest neighbours' repulsion near D far more than the attraction of
the second neighbours, which come inside the range (at √3 a) once the
lattice spacing a falls below 0.866 D. Balancing the two in an infinite
triangular lattice gives a / D = (1 + c) / (1 + √3 c), with
c = 3^((1 − P) / (2 p_η)) for law power P: 0.800 (p_η = 1) and 0.762
(p_η = 2.2); a finite swarm's edge, with fewer second neighbours, sits a
little wider, as measured. Keeping the second neighbours out restores the
spacing: range 1.25 D gives 0.986 D on the drones (1.001 D as particles),
with the best lattice of any run (Delaunay CV 0.069 against LJ's 0.092 and
the baseline's 0.11). The 3D triangle's default range is already 1.25 D,
and it settles at 1.01 D.

**F46. The stop rule needs η** — 2026-10-18, New. With the sign flip, the
summed force is almost never small: a stop threshold of 0.01 or 0.03 (AP
units; in 2D the force just either side of D is ±0.27 per neighbour) held 0.04–0.3% of drone-ticks
in 2D and none in 3D, and the swarms jittered on as before. With η it holds
every drone once settled (residual speed 10⁻⁴ m/s in 2D, 10⁻⁹ m/s in 3D),
with the same settling time and lattice as η alone, so it does not freeze
the swarm before it has formed.

**F47. η softens the lattice: smooth flight, but it gives under load** —
2026-10-18, New. With η (power 1) the force's slope at D is F(D)/D: 0.0055
per AP unit in 2D and 0.0085 in 3D, against LJ's c·p/D² = 0.024, so the
lattice is a quarter to a third as stiff (the plain law has no slope at D,
only a step). Under the same load η therefore needs about four times LJ's
strain. Crossing
the default obstacle field after the moving goal (640 s, 2 seeds), η's
drones fly smoothly (acceleration below 0.1 m/s² throughout, mean speed
0.10 m/s against the jittering baseline's 0.20 / 0.40 m/s), lose none, and
travel slightly farther than the baseline but less far than LJ (swarm
centre at 632 s: −46 m against −43 and −50 in 2D; −47 against −41 and −51
in 3D). Under the goal's constant pull their bonds shrink to 0.85–0.92 D in
2D and 0.94–0.95 D in 3D, where LJ's stay at 0.97–1.0. η at the law's own
power (2.2 in 2D) settles no better than power 1 and leaves the lattice
smaller (0.87 D at range 1.25, still creeping outward after 170 s), so
power 1 is the better default.

**F49. η has two resting states: switched on after forming, the lattice
stays at D** — 2026-10-18, New; found by William in the GUI. With η on
from the launch, the 2D swarm settles at 0.83 D (F45). Switched on once the
plain law has spread the swarm (60 s after AP engages, 3 seeds), the same
drones settle within about 2 s at 0.96–0.97 D in 2D, and at 1.00–1.01 D in
3D with bond CV 0.035–0.055, the most regular Newtonian lattice measured
(η from the start 0.063, LJ 0.044, plain law 0.083). The particle replica
does the same (0.988 D; `checks/ch13.lua`). Both states are equilibria:
from a compact cluster the expansion passes through spacings below
0.866 D, where second neighbours are in range and η's balance stalls it;
a lattice already near D has them out of range, and η only removes the
dither. William's reading: it is annealing, with η as the cooling — the
plain law's dither (Ch. 13's "jumpiness", PDF 449) is the heat that lets
the lattice reach D, η from the start is a quench into the compressed
state. Next: a cooling schedule (ramp `etaPower` 0 → 1) and the fastest
cooling that still reaches D.

**F50. η in a band tied to D: no trap, a stiffer lattice, and a stiffness
limit set by the drones** — 2026-10-18, New; William's idea. Damping only
within |D − r| < w·D (`etaWidth`; w = 1 is Eq. 13.9) leaves the far forces
alone, so from the launch the 2D swarm no longer stalls: bonds 0.83 D
(w 1), 0.85 (0.5), 0.98 (0.25), 0.999 (0.15) on 50 drones, 3 seeds each;
the particle replica reaches D for w ≤ 0.2, as the F45 balance predicts
(no trap for w below about 0.26). w 0.15 gives the best 2D lattice measured
(Delaunay CV 0.064; LJ 0.092). Too narrow brings the jitter back: 2D at
w 0.1 crashed 4 drones, and 3D at w 0.15 kept jittering in 2 of 3 runs, at
0.1 fully (0.32 m/s). The edge falls at the same slope of the damped force
at D, F(D)/(w·D), in both dimensions: 0.034–0.037 per AP unit settles,
0.055–0.057 does not (LJ's slope is 0.024). So the band can be set from the
law and the separation, w ≈ F(D)/(0.04 D): 0.14 in 2D, 0.21 in 3D. One
w = 0.2 works in both: 2D settles (by the acceleration test; formed at
76–96 s, F52) at 0.994 D (Delaunay CV 0.077),
3D at the last launch wave at 1.01 D (bond CV 0.054), no crashes. Crossing
the obstacle field after the goal (2 seeds), w 0.2 holds its bonds at
0.93–0.94 D (2D) and 1.00 D (3D), where w 1 gave 0.85–0.86 and 0.94–0.95
and LJ 0.97 and 0.99, but it is slower: swarm centre at 632 s −43 m in 2D
and 3D (w 1: −46, −47; plain law −43, −41; LJ −50, −51). The stiffer
lattice threads the columns no faster than the jittering one; LJ is both
stiff and fluid.

**F51. Ch. 13.4.1.1: adaptive friction damps the dither but cannot stop
it, and alone it freezes the swarm** — 2026-10-18, Confirmed in part (PDF
463–465), New in part. `quadcopter/README.md`. Eq. 13.23 per axis on the
drones' AP velocity (`muMore`, `muLess`), plain Newtonian law, from the
launch, 3 seeds. The book's ratio condition holds: at kMore/kLess 2.5 and
10 (kLess 0.02) the swarm keeps moving (2D 0.12 and 0.04 m/s, 3D 0.22 and
0.08 m/s); at 25 it falls below 0.1 m/s² in 6 s (2D) and 30–32 s (3D).
But the drones still cross D 104 (2D) and 220 (3D) times per drone per
minute, at 0.014 and 0.023 m/s: the small-amplitude oscillation that the
book says remains after adaptive friction and that its static friction
removes (§13.4.1.4, PDF 465). Our acceleration test alone calls these runs
settled; the crossing count shows they are not. The cost is mobility:
that residual dither keeps flipping the commands' signs, so mu stays at
0.8–0.9 and damps the goal's pull too. Crossing the obstacle field (2
seeds) the swarm's centre reaches only +4.5 m (2D) and +8.3 m (3D) in
632 s, against −43 and −41 m for the plain law: the book's "too much
damping impairs reactivity" (PDF 463). With η in its 0.2 D band (F50) the
dither is gone, so mu decays (0.08–0.11 settled, 0.12–0.26 while following
the goal): by the acceleration test settling looked a little faster (5 s
2D, 29–30 s 3D), but the lattice forms later in 2D (91–117 s against
76–96 s, F52), the lattice the same (0.993 D, Delaunay CV
0.082; 3D 1.01 D, bond CV 0.054), and the crossing slightly slower (−40,
−38 m against −43, −43 m). In 2D alone it compresses the lattice (0.92–0.94
D); in 3D at ratio 10 it gave the most regular lattice measured (bond CV
0.023) while still moving at 0.08 m/s.

**F52. Settling times corrected: when is the lattice formed?** —
2026-10-18, Our error, corrected (FIXES 41; found by William in the GUI).
The settling times in F44, F50 and F51 came from the acceleration test,
which a slow outward creep passes: with η in its 0.2 D band the 2D bonds
were still growing from 0.89 to 0.99 D over ~165 s while it said 5–10 s.
Timed instead as *formed* (bonds ≥ 0.97 of the spacing and mean speed
< 0.01 m/s from then to the end; 285 s runs, 3 seeds, seconds after AP
engages):

| | 2D formed | 2D bond CV | 3D formed | 3D bond CV |
| --- | --- | --- | --- | --- |
| η (book band) from the launch | never (0.83 D) | — | 42–57 | 0.063 |
| η, band 0.2 D, from the launch | 76–96 | 0.066 | 66–154 | 0.053 |
| η 0.2 D + adaptive friction | 91–117 | 0.066 | 76–85 | 0.053 |
| η (book) switched on at 60 s | never (0.96 D) | — | 68 | 0.044 |
| η (book) switched on at 150 s | 157 | 0.046 | 158 | 0.020 |
| η 0.2 D switched on at 60 s | 88–106 | 0.063 | 72–79 | 0.047 |
| Lennard-Jones | 30–35 | 0.023 | 51–64 | 0.015 |

William's way — the plain law first, η once the swarm has spread to D
(F49) — gives the most regular Newtonian lattices, formed about 7 s after
the switch; but the plain law needs ~150 s of jitter to reach D in 2D
(switched at 60 s, η freezes it at 0.96 D), while in 3D it is there by
60 s. The narrow band is the fastest from the launch in 2D but slower than
the book's band in 3D; adaptive friction slows 2D and speeds only the
narrow band in 3D. LJ forms fastest in both.

**F53. Switching η on per drone by a local rule does not work** —
2026-10-18, New (negative). To automate F49, each drone turned η on, and
kept it on, by a local test of its own neighbours (one checkbox, no new
number). Two tests, 285 s, 3 seeds, 2D and 3D, book band and 0.2 D band:
*every neighbour within range at least 0.97 D* never forms a lattice in
either dimension (a few drones never pass, keep jittering at 0.06–0.14 m/s
and shake the rest; in 2D the early ones freeze patches at 0.93 D); *the
mean distance to the neighbours within range at least 0.97 D* passes at
once in the launch cluster (neighbours out to 1.5 D average near D), so it
is η from the launch again (2D 0.83 D with the book band; 0.2 D band
formed at 100–106 s, no better than without the switch). Anything between
the two is a new number to tune, so the switch was taken out (HANDOFF §2,
simplicity). The local rule that works is η in a band of 0.2 D from the
launch (F50, F52); switching η on later is a choice made by hand.

**F54. Ch. 13.4.1.4: static friction does not settle the drones** —
2026-10-18, New. Eq. 13.25 with the corrected condition μ·m·g < |F|, per
axis on the adaptive μ, the plain law without η (the book's whole Pioneer
recipe). g is set by the book's own scale, not tuned: g = 9.81 against
forces of ~100 at D (Fig. 13.3), so g′ = 0.098 F(D). At muMore 0.2 and 0.5
(muLess 0.02), 3 seeds, no run forms: the drones keep crossing D 123–343
times per drone per minute, as with adaptive friction alone (F51), and in
the obstacle-field crossing the swarm is as frozen (centre +3 to +8 m in
632 s). At 10× the book's g′ it is no better (128–367 crossings): blocking
an axis zeroes its command, μ decays, and the drone moves again. The
book's reasons for it — a minimum wheel speed and poor position estimates
(PDF 465) — are absent on these drones (no minimum speed, perfect
sensing); it belongs with the ground robots of M2 and with sensor noise
(G7). With LJ, F(D) ≈ 0, so it would do nothing.

**F55. Ch. 13.4.1.3: the adaptive speed cap is not needed on the drones**
— 2026-10-18, New. Eq. 13.24 with one reading per tick (the nearest column
surface or drone, so no beam count) and the Pioneer's values scaled to the
quadcopter (1.5 / 0.3 m/s, 1.5 m, k_less/k_more 12.5). Crossing a field
twice as dense (61–65 columns) after a goal twice as fast (0.4 m/s), 2
seeds, LJ and Newtonian with η: no drone hit a column with or without the
cap, and progress was the same within noise (e.g. Newtonian 3D centre at
374 s −12.8 / −14.4 m without, −13.9 / −14.5 m with). The cap never binds:
AP's commands stay at 0.1–0.2 m/s, because the obstacle repulsion was
already made gentle for these airframes (FIXES 17–23). The only losses are
drone–drone collisions in the 2D LJ launch, before the cap could matter.
It belongs with faster swarms and with ground robots whose ranging sees
obstacles late.

**F56. Defaults that work out of the box: η on, band 0.2 D in 2D and
0.5 D in 3D** — 2026-10-18, New. William's decision: the drones keep only
`etaPower` and `etaWidth`, on by default in the Newtonian scene. Measured
with no settings changed (285 s, 3 seeds; launch only, no field): with
0.2 in every mode, the 2D triangle forms at 76–96 s (0.993–0.998 D), the
2D square at 53–170 s (0.97–0.98 D), the 3D triangle at 66–154 s, but the
3D cube keeps jittering in 2 of 3 runs (53 crossings per drone per
minute): the 3D law's F(D) is 0.42, so the slope at D, F(D)/(w D), is
0.042, at the edge found in F50. A 0.5 band forms the cube at 80–128 s
(0.99 D) and the 3D triangle at 45–50 s (1.008 D, faster than LJ's
51–64 s). So the band follows from the two limits — slope at D below about
0.035 per AP unit (w ≥ 0.16 in 2D, ≥ 0.24 in 3D) and, in 2D at range
1.5 D, w < 0.26 against the second-neighbour trap — and is set per mode:
0.2 in 2D, 0.5 in 3D. The default scene (field, moving goal) loses no
drones: swarm centre at 630 s −42 / −44 m in 2D and −45 / −46 m in 3D
(plain law −43 and −41, LJ −50 and −51), bonds 0.93–0.98 D under the
goal's pull.

**F57. Three truly 3D models: a flipping tetrahedron, stable planets, a
ringing lattice** — 2026-10-18, New. `ch02/README.md`, `checks/ch02.lua`.
Two bodies always move in one plane (F42); these need three or more.
(a) **Tetrahedron**, masses 1–4 on six springs: an asymmetric top
(moments 4390 / 5840 / 7270). Spun 2° off the smallest or largest axis it
stays within 3–4° of L for 48 turns; off the middle axis it flips end for
end 7 times in 48 turns (5–10 for tilts 0.5–5°, spin 0.3–0.5, k 10–40):
the tennis-racket (Dzhanibekov) effect from springs alone, with |L| fixed
to 10⁻¹⁴ and E to 6×10⁻⁵. (b) **Planets**, solar_system's law and units
without caps, 4 planets at 15 × 1.8ⁱ⁻¹ tilted up to 10°: at 1/1000 and
3/1000 of the sun each, all radii stay within 1–3% for 150 outer orbits
(3 seeds); at 1/100 one seed of three breaks up by 150 orbits; at 3/100,
1/10, or spaced 1.3× apart, a planet is thrown out. The orbits' tilts
drift by degrees as the planets tug on each other. Stability needs light,
widely spaced planets, a time step of a few hundred per inner orbit,
momentum balanced at the start and circular speeds — and no caps. (c)
**Spring lattice**, 3 × 3 × 3 masses with springs on edges and face
diagonals (126; edges alone shear flat): it rings without end with P = 0
and L fixed, and with friction settles into the perfect cube (strain 6% to
10⁻⁸).

**F58. Elliptical orbits: two rules keep several planets stable** —
2026-10-18, New (William's question: circles worked, ellipses did not).
`ch02/Planets.lua`, `checks/ch02.lua`. Measured with the book's integrator
(3 planets, 6 seeds, 20 outer orbits unless stated):
(a) **Spacing.** An ellipse swings between a(1 − e) and a(1 + e), so the
spacing that works for circles lets elliptical orbits approach or cross.
Keeping the *gap* — the outer orbit's nearest point over the inner orbit's
farthest point — at the circles' 1.8 (ratio of semi-major axes
1.8 (1 + e)/(1 − e)) holds them: at e 0.3 and 0.5 every orbit stays within
1–6% of its shape for light planets (1/1000 of the sun) and within 16%
for heavy ones (1/100), 12 of 12 runs; e 0.7 also holds. At gap 1 (orbits
touching) light planets are scrambled (up to 42% past their farthest
point) and heavy ones break up in 11 of 12 runs; at circular spacing with
e 0.3–0.5, 4 of 12 light runs broke.
(b) **Time step.** The nearest-point pass lasts about √(rp³/GM),
rp = a(1 − e), much shorter than the orbit. With about 50 steps across it
(Δt = √(rp³/GM)/50) one planet keeps its energy within 1% (e 0.5) to 7%
(e 0.9) and its orbit does not turn; with 4 steps (e 0.9 at Δt 0.01) the
energy swings 88% at each pass and the orbit turns about 1° per orbit; with
1 step, 640% and 157° — and with neighbours, the system breaks. The book's
integrator keeps a lone orbit's size even then (it is symplectic), so the
damage shows in the energy and the turning, not the size.
*Our error, corrected:* the first measure of "broke" used each planet's
osculating semi-major axis about the sun, which heavy planets distort by
moving the sun; it called stable heavy systems broken. Farthest and nearest
distances against the orbit's own a(1 ± e) are the right test.

**F59. A pile from a truck: η from the launch is still the best way** —
2026-10-19, New (William: in wartime the drones are dropped as a pile, not
placed). The default launch is that pile: drones 1 m apart on the ground,
so in 2D, where all fly at one altitude, neighbours start ~0.86 D apart
(D = 3 m) and the swarm must expand; in 3D the thirds climb to their own
levels already ~D apart. Without η the plain law's jitter needs ~150 s to
shake out the 2D pile's defects (the 10th percentile of each drone's mean
first-shell distance stays ≤ 0.90 D for over 100 s). From the pile, 2D,
280 s, 3 seeds (formed, s / bond CV / drones lost):
η from the launch (default) 76, 87, 96 / 0.066 / 0;
take-off in thirds, η on 106, 171, 138 / 0.057 / 0;
one drone at a time, η on 185, 167, 148 / 0.066 / 0;
a per-drone switch latched on once its own first shell (within 1.25 D)
averages 0.97 D: 123, 172, 275 / 0.061 / 2 every run;
the same switch two-way (η on only while the shell is at D) never forms
(bonds 0.95–0.98 D, CV 0.13) / 2 every run, and with the take-off in
thirds never (CV 0.13).
The two-way switch was meant as local annealing, but drones near the
threshold keep turning η off, and each time they jitter again: the heat
never falls. Later waves must push into a lattice already damped. In 3D
the latched switch formed at 42–53 s (CV 0.060) and the two-way one at
63–277 s, no gain over the defaults. With the drones placed 1.8 m apart
(neighbours ~0.96 D), η from the launch forms at 27–33 s, but that is not
a pile. So nothing was added (HANDOFF §2): the defaults already get a good
lattice from the pile, about 1.5 min in 2D and under 1 min in 3D, and the
switch code was removed. LJ forms from the same pile in 30–35 s (CV
0.023): the faster way is in the force law's shape, not in a switch.

**F60. The world generator's terrain and water: meanders, the slope rule,
and two mistakes of ours** — 2026-10-20, New and Our error, corrected.
`lib/terrain.lua`, `checks/terrain.lua`. (a) **Meanders.** A river drawn
as a sine-generated curve (heading 1.1 sin φ to the valley; Langbein and
Leopold 1966) has sinuosity 1/J0(1.1) = 1.390: a 41.7 km test river
measures 1.391 and a meander wavelength of 10.9 widths (Leopold and Wolman:
10–14; ours 11). Varying each bend's length by ±30%, so meanders are not
all alike, keeps the sinuosity, because a bend's sinuosity does not depend
on its length. The presets' rivers measure 1.39–1.40, the city's (only 2.5
meanders long) 1.43. (b) **The slope rule** (no dry slope steeper than
15% along the grid, by lowering only) also makes the river valleys' walls,
the ponds' banks and the dry part of dredged cuts, so none needs its own
setting. Across a triangle it allows up to √2 × 15% = 21.2%, and four of
the five presets reach that on valley walls; that is what "drivable" means
here. (c) *Our errors, corrected:* dredging with 1:3 sides after the slope
rule left 33% dry banks where a channel ran up into land; sloped cuts now
come before the rule and only vertical quay walls after it. Hills drawn as
noise of either sign dug an inland hollow 15 m below sea level behind the
harbour town (245 nodes); hills now stand on the plain (0 to their
height). And a Lua trap worth knowing: `f(t, g(), fn)` passes only g's
first result when g returns several (Lua cuts a call's results to one
unless it is the last argument). (d) Each preset builds in 0.1–0.4 s in
Lua 5.1, and a seed gives identical terrain on Lua 5.1–5.4.

**F61. Zones and streets: the published LCZ fractions, and a connected
network from one rule** — 2026-10-20, Our error, corrected, and New.
`lib/town.lua`, `checks/town.lua`. (a) *Our error:* `BOOK.md` §6 gave
the open low-rise zone 15–25% built and the sparsely built 5–15%.
Stewart and Oke's table (2012, Table 3) gives 20–40% and 10–20%
(compact high-rise 40–60% and > 25 m, as we had). `Town.LCZ` now holds the
published ranges for all ten built zones, and the buildings (next patch)
will be calibrated to them. (b) **One rule makes the network whole:** keep
only the streets connected to an arterial. Without it, grid streets cut
off by the city's river, stubs at the edges of zones and the port's
grids (which stopped 24 m short of their arterial) were left as islands:
15 pieces in the city, 11 in the harbour town, 14 in the port, 1 in the
suburb. With it every street is reached from an arterial, which
`checks/town.lua` confirms independently by flooding a 4 m raster of the
streets (39,441 sample points, all reached). The port's districts were
then laid to meet their arterial, so it drops none. (c) **Woods'
share** has to be calibrated on the land it applies to: a noise cut taken
over the whole area gave woods on 25% and 40% of the open land when 30%
was asked; taken over the open land alone it gives 30.0%. (d) A BPP
trap: a Lua local named `Terrain` (our terrain module) hides BPP's global
`Terrain` mesh class in that file, and the viewer showed nothing; the
module is now `Land` there. Zones and streets build in 0.02–0.3 s and a
seed gives identical streets on Lua 5.1–5.4.

**F62. Buildings calibrated to the published LCZ ranges, and what it took**
— 2026-10-20, New and Our error, corrected. `lib/buildings.lua`,
`checks/buildings.lua`. (a) **Result.** Every built zone covering ≥ 3%
of a preset now falls inside Stewart and Oke's ranges, on seeds 1–3
(building fraction / mean height): city compact high-rise 41–45% / 56–64 m
(40–60%, > 25 m); compact mid-rise 40–46% / 18–19 m (40–70%, 10–25 m); open
mid-rise 23% / 18 m (20–40%, 10–25 m); harbour-town compact low-rise
45–48% / 7 m (40–70%, 3–10 m); open low-rise 22–24% / 5 m in the suburb and
the harbour town (20–40%, 3–10 m); sparsely built 12.5–13% / 5 m (10–20%);
port large low-rise 33–35% / 8 m (30–50%, 3–10 m); heavy industry 22–23% /
11–12 m (20–30%, 5–15 m). The city's skyline has a heavy tail (median
17.5 m, 99th percentile 80.5 m, tallest 171.5 m, 49 floors), and its mean
height falls from 65 m within 150 m of the centre to 31 m and then levels
at 18 m, as Schläpfer et al. (2015) describe (heights fall near the centre,
then settle). (b) **The suburb's streets were too sparse.** Cul-de-sacs
hung off collectors 400 m apart left block interiors empty: open
low-rise 10.6% and sparsely built 5.3% built, a third of the published
range. Measuring where the land went (28% street, 47% lots, 25% neither)
pointed at the network, not the houses. Local streets 80 m apart between
the collectors, half of them cut midway into cul-de-sacs, now carry the
lots (55 km of street in the suburb, about 2,300 houses). Cutting needed
care: a piece was first assumed to meet a collector at its uncut end, but
an end at a zone's edge meets nothing, and those pieces were reversed,
trimmed and dropped; locals are now split where they actually cross the
collectors. (c) **The gap rule and the setbacks interact.** Back-to-back
compact buildings with 1–2 m rear setbacks stood 2–4 m apart, inside the
forbidden 0–3 m, so the rule narrowed them and left gaps along the
streets; compact zones now have a rear setback of half the minimum gap
(1.5 m), and a building breaking the rule gives up depth before width.
(d) *Our error, corrected:* lots were first tested against the streets at
3 × 3 points, and on 110–150 m industrial lots whole 20 m streets passed
between the points: lots straddled streets and the port's heavy industry
read 21.5% built where the honest figure was 18%. The test is now exact
(distance from each street segment and turning circle to the lot's
rectangle), with water sampled every half cell. (e) The city's centre
first sat on its river, which took a quarter of the high-rise zone's land
and held it at 36–39% built; it now lies 150 m north. (f) A Lua trap:
`goto` does not exist in Lua 5.1 (BPP's cloud build). Lots and buildings
take 0.8–3.4 s per preset in Lua 5.1 and are identical on 5.1–5.4.

**F63. Mission features and trees: what measuring them corrected** —
2026-10-20, New and Our error, corrected. `lib/features.lua`,
`lib/vegetation.lua`, `checks/features.lua`. (a) **The storm drain must
flood at its outfall.** With the culvert's roof kept under 1 m of cover,
a 2 m culvert needs 3 m of ground over its floor; the bay's head is a low
shore (~1 m), so the drain leaves the land below sea level: its last 35 m
of 458 lie under water, a tide-locked outfall, which real low shores have
too. It is recorded (`flooded`) rather than hidden, and matters to the
capstone: robots in the drain cannot leave by the sea end. (b) *Our
errors, corrected:* the port's ship first sat 2 m off a quay wall that the
terrain mesh draws as a slope one 8 m cell wide, and its corner read as
aground (−7 m clearance); ships now stand off by a cell and 1 m of
fenders (under-keel clearance 3–6 m). A warehouse on a slope had doors
5 m over its lowest ground, which left the uphill door less than 2 m
high; doors are now 5 m over the ground at each door. (c) **The gap rule
is about obstacles, not pairs.** Container stacks two rows apart are
2.44 m apart, under the 3 m rule, but the row between them closes the gap;
the check now merges touching buildings into one obstacle before applying
the rule (what the Android app's rule means: gaps between obstacles fit an
agent or are closed). (d) **Counts** (seed 1): street trees 7,900 in the
suburb, 4,300 in the city, 5,200 in the harbour town; the rural preset has
1,640 lengths of hedgerow and woods as a canopy over 25% of its open land;
the harbour town's yard holds 130 stacks in 3 blocks with 6 pockets, the
port's 345. (e) **Traps** (open ground no street reaches, 2 m raster):
0.54% of the harbour town's old town and 0.04% of the city core; few,
because U-shaped courts open to the rear and back-to-back lots leave
3 m passages. A whole preset builds in 0.4–3.5 s in Lua 5.1, identically
on 5.1–5.4.

## 3. Errors and discrepancies in the book

**F14. Listing 11.4's printed result** — 2026-10-17, Book discrepancy.
`ch11/listing_11_4.lua`, `ch11/README.md`.
The listing's entry is at x₂ = 1.001 (exact mean 0.652501); the text prints
0.6517. With the book's generator (glibc, srandom(1), Lua 5.1) the listing
gives 0.652454, 9 standard errors away, but 0.651711 = "0.6517" at x₂ = 1, so
the text's run most likely used x₂ = 1 (inferred).

**F15. Ch. 2.3d: the velocity cap's effect on the orbit's shape** —
2026-10-17, Book discrepancy. `checks/ch02.lua`. At Vmax 12 the book says
the orbit "runs well, with a slight linear-momentum change". It is slight
(|P| ≤ 3.0), but the orbit shrinks unmentioned from 15–87 to 15–18: the cap
cuts the start speed 15 to 12. solar_system.nlogo caps as we do (scaling the
speed, keeping the direction); clipping each component gives 14.9–18.4.

The chapter notes list further suspected errors in the listings (Ch. 3, 6,
7, 9, 13, 18; `BOOK.md` §1 item 11). They are not yet re-checked by
measurement and will be entered here as each chapter is ported.

## 4. Differences between implementations

**F16. Uniform Coverage: the wall rule decides the large-MFP results** —
2026-10-17, Divergence (kept by decision). `FIXES.md` 36.
NetLogo turns when the patch 1 ahead or either patch 2 away at ±45° is wall;
the Android app, and BPP from it, turns only on touching the boundary. With
NetLogo's rule swapped into BPP (one agent, 10⁷ ticks), MFP 30 / 50 / 100
give 0.0074 / 0.0227 / 0.0271, reproducing NetLogo's own 0.0072 / 0.023 /
0.026. The Android rule gives 0.0035 / 0.0158 / 0.0368: better at every useful
MFP, worse only at 100. NetLogo is not maintained; the Android/BPP rule stays.

**F17. Uniform Coverage: the two known Android bugs barely matter** —
2026-10-17, Divergence. `FIXES.md` 4–5.
The one-sided neighbour cone (0–30° for ±15°) and the dropped ninth move
were real, but move the deviation about 3%, so BPP and Android agree (MFP 30,
100 agents: 0.00087 against 0.00085).

**F18. Earlier NetLogo and Android numbers at small MFP came from longer
runs** — 2026-10-17, Open.
William's old values at MFP ≤ 17 (0.00027–0.0016) sit below our 5×10⁷-visit
upper bounds, so those runs were longer. Their lengths were not recorded.

**F19. Zarzhitsky's map format, kept by the Android port** — 2026-10-17,
Confirmed. `lib/world.lua` (`writeCPT`).
A text file of nx lines of ny characters, `' '` open, `'b'` blocked. His
PlumeGen, rebuilt from source, loads a map written by our generator and
reports the same coverage (3.6%). Its reader as shipped wants a square of at
most 1024; ours writes any size.

**F48. `formation_newton.nlogo`, the book and the BPP port use different
defaults** — 2026-10-18, Divergence. The law is the same in all three
(`netlogo/README.md`). The model's sliders are G 310, power 2, Force_Maximum
1, Desired_Separation 30, Friction 0.15, Time_Step 1, 50 particles; the
book's text gives G 400 for the same model (`book/ch03.md`); both are above
the clustering threshold G_t = 259.8, so the model clusters by design. The
BPP ports take their 2D defaults from the Android app's `MyPanel.java`: G
1500, power 2.2, forceMax 1.5, D 50, friction 0.6, which is below its G_t
(2368). Ch. 13's damping is in none of them.

## 5. Our own errors, corrected

**F20. "NetLogo's MFP 30 and 50 values come from short runs"** — 2026-10-17,
Our error. With NetLogo's wall rule BPP reproduces NetLogo's values (F16),
so they had converged; a short run can only raise the deviation.

**F21. The seed slider would not move** — 2026-10-17, Our error. `FIXES.md`
34. Found by William. BPP stores slider ranges as floats and turns them into
an integer slider; a maximum of 2³¹ − 1 overflowed it. Now 0–1000; larger
seeds go through `SEED`.

**F22. R in Uniform Coverage reset the seed** — 2026-10-17, Our error.
`FIXES.md` 34. R was BPP's own reload, which resets every slider to its
default, so a chosen seed never applied. Uniform Coverage now binds R to a new
scatter, and a seed change restarts the scene in every demo.

**F23. The world viewer was mirrored top to bottom** — 2026-10-17, Our error.
Found by comparing with Fig. 3.25. Book y now maps to BPP −z, so a camera
looking down −z sees the book's orientation.

**F24. Energy "flat" tested as no swing** — 2026-10-17, Our error. The first
Ch. 2 checks failed seven times on the integrator's normal within-cycle swing
(F12); they now test drift and report the swing separately.

**F25. The repository ignored `lib/`** — 2026-10-17, Our error. The root
`.gitignore` rule `lib` (for build output) silently left the new folder out of
the first commit; an exception was added.

**F26. A test hook replaced the scene's own** — 2026-10-17, Our error. BPP
keeps one `postSim` callback, so a probe that set its own stopped the
simulation. Probes now use `preDraw` and `preStop` (`lib/batch.lua`).

**F27. The 3D mean free path estimate** — 2026-10-17, refined: an earlier
≈ 0.7717 (4 M samples) is within error of the exact 0.771992 (F9).

**F33. The checks assumed `lua5.1` was installed** — 2026-10-17, Our error.
Found by William (Lua 5.3 only): every check failed for want of the
interpreter, and three used `math.atan2`, gone in 5.3. `checks/run_all.sh` now
runs them inside BPP, else any Lua; all code runs on 5.1–5.4.

---

**F37. Fig. 3.26 drawn as Fig. 3.25's discs enlarged** — Our error, found by
William. Obstacles are placed by mouse clicks, so Fig. 3.26 has its own field:
six discs fitted to its outline (preset `ch03-wall`); drawn over the figure,
they trace it.

**F38. Fig. 3.26's discs measure radius 45, the text says 50** — Book
discrepancy (small). Radius 95 px at the scale confirmed by the lattice
(F13); the field covers 24.8% of the panel, ours 24.6%.

**F39. Code against William's instruction went out in a commit of ours** —
Our error. Another session's `cpt-textron` preset reached master because I
staged the folder unread. Removed; diffs are now read first.

**F40. Both figures' obstacles shift between panels: cropping** — 2026-10-18,
Our error (small), settled by the `.nlogo` and Fig. 3.23: each panel crops
~305 patches of a 701 × 401 world, which we took for the world. Pushing
moves a heavy (10⁵) obstacle ≤ 0.01 patch/tick. Presets use the model's frame.

**F41. Ch. 2's starts guessed, then checked against the .nlogo** —
2026-10-18, Our error (small). spring2D now starts at random headings and
spring1D's light mass on the right, as the models; F3 barely moves.

## 6. How BPP behaves (worth knowing for every port)

**F28. Headless results depend on `delayMs`** (FIXES 1): its throttle uses
wall-clock time; `lib/batch.py` sets it to 0.

**F29. R reloads the script and resets every slider** unless a scene binds R
itself; the toolbar restart restores the sliders after reloading (F22).

**F30. One callback of each kind:** `v:postSim`, `v:preDraw`, `v:preStop`,
`v:onParamChanged`; setting another replaces it (F26).

**F31. Slider ranges are floats turned into integers** (value / step): keep
them well inside ±2³¹ steps; values above 2²⁴ are not exact (F21).

**F32. Scripts run in their own folder** in the GUI; scripts in subfolders add
`../?.lua` to reach `lib/`.

**F34. BPP's Lua depends on the build:** 5.1 or 5.2 (`bpp.pro`), not the
standalone `lua`: William's is 5.2, the cloud build 5.1 (`bpp -l
'print(_VERSION)' -n 1`). The checks and the generator's stream agree on 5.1–5.4.

**F35. BPP runs a scene as soon as it loads;** S stops and restarts it. GUI
tests that "pressed S to start" were stopping runs (our error).

**F36. Huge "off" values make unusable sliders** (Force_Maximum 0.1–10⁶ could
not be set to 1; found by William). Caps now get a tick box and a slider over
the useful range. Same root as F31.

## 7. Open questions

- F18: the limits at MFP ≤ 17, which need about 10⁹ visits to resolve.
- The 3D threshold G_t for the cube formation (`BOOK.md` §1 item 9), to
  measure with a G sweep.
- How to keep η's spacing at D in 2D at range 1.5 D (F45): a shorter range
  works, as do switching η on after the lattice forms (F49) and a narrow
  band tied to D (F50). Whether the slope limit (~0.04–0.05 per AP unit)
  follows from the drones' lag and AP rate, and holds for other apHz.
  Static friction and the adaptive speed cap on ground robots with a
  minimum speed and real ranging (M2), and with sensor noise (G7); on the
  drones they are not needed (F54, F55). And whether the next Ch. 13 mechanisms (adaptive and static
  friction) settle the drones without η's loss of stiffness (F47).
- Getting a 2D lattice from a pile faster than η's ~1.5 min (F59): LJ
  does it in 30–35 s, so the lead is the shape of the force law near D.
