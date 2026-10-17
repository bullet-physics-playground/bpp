# Findings: experiments, confirmations and errors

A running record of what the conversion has found: the book's results we have
reproduced, new results, errors and discrepancies in the book and in the
other implementations, and our own mistakes, corrected. It is updated with
every patch that finds something, and `FINDINGS.pdf` beside it is rebuilt
each time. `BOOK.md` says what to build and `FIXES.md` what was fixed in the
code; this file says what was learned.

**How to read an entry.** Each has an ID, the date, what was done, the
numbers, where the evidence lives (a check script, a README or a probe), and
a status:

- **Confirmed:** the book's claim, reproduced by our own measurement.
- **New:** a result the book does not have.
- **Book error:** the book disagrees with its own code, figures or arithmetic.
- **Divergence:** two implementations (NetLogo, the Android app, BPP) differ.
- **Our error:** something we got wrong, and how it was found and corrected.
- **Open:** measured but not yet settled.

Page numbers are PDF pages of `apbook1.pdf`; book page = PDF − 31.

---

## 1. The book's results, reproduced

**F1. Appendix A: glibc `random()` is biased, and BPP uses it** — 2026-10-17,
Confirmed. `checks/rng_appendix.lua`.
BPP's Lua 5.1 `math.random` is glibc `rand()` = `random()`. Run with Listing
A.1's sampling (S extra calls per accepted point in the unit disk, 10⁶
points, 36 bins, 99.9% cut χ² 66.6), it fails at S = 25 (χ² 321) and 27
(409), as the book shows (PDF 646–648). Also at S = 26 (223) and S = 3 (70),
which the book's sweep ("most values from one to 27") covers but does not
single out. The multiply-with-carry generator now in `lib/rng.lua` passes at
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
Angular momentum constant to 2×10⁻¹⁴, linear momentum 3×10⁻¹²; mean
separation 77.9 > D = 50; the maximum exceeds 2D = 100 for every seed tried
(111–123).

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

---

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
Both panels of Fig. 3.25 give the same 12 disc centres to within a pixel
(shifted by a constant crop). The discs, drawn 2·obstacleF = 20 across, set
the scale at 2.11 px per patch at 300 dpi, so the world is about 305 patches
wide, the goal at (−119, 4) and the field's centre at (48, −7). Fig. 3.26 uses
the same centres at radius 50. The closest gap at radius 10 is 5.2 patches
("narrowly spaced").

---

## 3. Errors and discrepancies in the book

**F14. Listing 11.4's printed result** — 2026-10-17, Book error (cosmetic).
`ch11/README.md`.
The listing puts the entry point at x₂ = 1.001, which raises the mean to
0.6525 (exact; our simulation agrees), but the text prints 0.6517. That
matches an entry at exactly 1 (0.65176). The same listing with glibc
`random()` also gives 0.6525, so it is not the generator.

**F15. Ch. 2.3d: the velocity cap's effect on the orbit's shape** —
2026-10-17, Open.
At Vmax 12 the book says the orbit "runs well, with a slight linear-momentum
change". We confirm the momentum change is slight (|P| up to 3.0) but the
orbit shrinks from 15–87 to 15–18, nearly circular, which the book does not
mention. The cap's code is not shown; we clip each speed.

The chapter notes list further suspected errors in the listings (Ch. 3, 6,
7, 9, 13, 18; `BOOK.md` §1 item 11). They are not yet re-checked by
measurement and will be entered here as each chapter is ported.

---

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
The one-sided neighbour cone (0–30° instead of NetLogo's ±15°) and the
dropped ninth move were real departures from NetLogo, but together they move
the deviation by about 3%. That is why BPP and Android agree closely (MFP 30
with 100 agents: 0.00087 against Android's 0.00085).

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

---

## 5. Our own errors, corrected

**F20. "NetLogo's MFP 30 and 50 values come from short runs"** — 2026-10-17,
Our error. Found by measurement (F16): with NetLogo's wall rule BPP
reproduces NetLogo's values exactly, so they were converged and the
difference is the walk itself. A short run can only raise the deviation
(noise adds in quadrature), never lower it, as at MFP 100.

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

**F27. The 3D mean free path estimate** — 2026-10-17, refined. An earlier
chat's Monte Carlo gave ≈ 0.7717 (4 M samples); the exact value is 0.771992
(F9), within that estimate's error.

---

## 6. How BPP behaves (worth knowing for every port)

**F28. Headless results depend on `delayMs`** — `FIXES.md` 1. The throttle
compares wall-clock time, so a headless run's result depends on machine speed
unless `delayMs` is 0. `lib/batch.py` sets it in every run.

**F29. R reloads the script and resets every slider** unless a scene binds R
itself; BPP's toolbar restart restores the sliders after reloading (F22).

**F30. One callback of each kind:** `v:postSim`, `v:preDraw`, `v:preStop` and
`v:onParamChanged` each hold one function; setting another replaces it (F26).

**F31. Slider ranges are floats turned into integers** (value / step), so
ranges must stay well inside ±2³¹ steps, and values above 2²⁴ are not exact
(F21).

**F32. Scripts run in their own folder** in the GUI (BPP changes directory on
open), so `require` finds modules relative to the script's folder; scripts in
subfolders add `../?.lua` to reach `lib/`.

---

## 7. Open questions

- F15: does the book's velocity cap clip speed, or each component?
- F18: the limits at MFP ≤ 17, which need about 10⁹ visits to resolve.
- The 3D threshold G_t for the cube formation (`BOOK.md` §1 item 9), to
  measure with a G sweep.
- Whether AR damping η alone makes the Newtonian drones settle like
  Lennard-Jones (`BOOK.md` §1 item 1), for M1.
