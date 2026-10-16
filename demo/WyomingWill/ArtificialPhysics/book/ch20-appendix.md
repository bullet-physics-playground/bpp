# Appendix A — Anomalous Behavior of the random() Number Generator

- **Authors:** William M. Spears and Derek T. Green (University of Arizona)
- **Book pages:** 615–621. **PDF pages:** 646–652 (PDF 653 is blank; the Index starts on PDF 654 at book p. 623, followed by the References. Both were skipped). Book page = PDF page − 31.
- **Context:** while building APO (Ch. 19), the authors were also analysing PSO theoretically [237]. Theory and Monte Carlo experiment disagreed. The theory was right; the C library generator `random()` was at fault. Identical behaviour was seen on Ubuntu, Red Hat, Debian and Mac OS X. Footnote 1: since April 2006 glibc `rand()` is the same as `random()`.

---

## E1. Angle histogram of rejection-sampled points in the unit disk (Listing A.1, Figs. A.1, A.2)
- **PDF 646–648 (book 615–617).**
- **Code:**
  - `srandom(1)`, then 10⁹ samples.
  - For each sample, first make **S superfluous `random()` calls**. Then rejection-sample (x, y) = 2·random()/RAND_MAX − 1 until sqrt(x² + y²) ≤ 1.
  - Bin atan2(y, x) into 360 one-degree bins.
- **Results to reproduce:**
  - **S = 0:** flat at about 2,777,777 per bin (Fig. A.1; normal noise).
  - **S = 25:** sinusoidal with **peaks at ±90°**. **S = 27:** **peaks at 0° and 180°**. Both span about 2.71e6 to 2.85e6, i.e. **±2.6%** (Fig. A.2).

## E2. Spatial histogram in the unit disk (Listing A.2, Figs. A.3, A.4)
- **PDF 649–650.** Same sampler, with a 101 × 101 grid over [−1, 1]².
- **Results to reproduce:** S = 0 is uniform. S = 25 and 27 show bright lobes in the same directions as E1.
- **Sweep result:** "non-uniform results appear for **most values from one to 27**; **28 to 100** showed no anomalies."
- **Suspected cause (text):** random() is the additive lagged-Fibonacci generator r[i] = r[i−31] + r[i−3]. The two lags are 27 numbers apart: "is this a coincidence?"

## E3. Quarter-circle area Monte Carlo (Listing A.3)
- **PDF 651–652.** Points uniform in the unit square, without rejection; count those with x² + y² ≤ 1; 10⁹ trials with S extra calls.
- **Result:** estimates π/4 ≈ 0.78539 accurately for every S. The area test is insensitive to the defect.

## E4. Control generators
- **PDF 651–652.** Replacing random() with the generator of ref [21] ("passes all of the tests", also discussed in [148]) gives "almost no anomalies". **drand48() and erand48() also performed very well.**
- The authors leave the explanation open.

---

## Independent check on this machine (glibc 2.39, x86-64; not in the book)
I compiled Listing A.1 as given (srandom(1)) and ran it with 2×10⁷ samples per S. I measured the cos 2θ moment of the angle distribution; it is 0 for a uniform distribution, and its 1σ is about 1.6×10⁻⁴.

| S | 0 | 1 | 3 | 10 | 25 | 26 | 27 | 28 | 31 | 40 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| cos 2θ moment | −0.00005 | +0.0006 | −0.0030 | −0.0026 | **−0.0110** | **+0.0096** | **+0.0141** | +0.0001 | −0.0001 | −0.0003 |
| peak bin | — | — | — | — | **≈ −78° (±90° lobes)** | — | **0°** | — | — | — |

At S = 25 and 27 the bin maximum/minimum ratio is 1.035/0.964 and 1.040/0.962 of the mean.

- **The book's result reproduces exactly:** S = 25 favours ±90°, S = 27 favours 0°/180°, S ≥ 28 is clean, and many smaller S values (3, 10, …) are biased by roughly 0.3%, about 20σ.
- A sweep of S = 0…40 at 10⁶ samples (1σ ≈ 7×10⁻⁴) also tested **3D rejection sampling in the unit ball** (3 draws per try). It shows the same pattern:
  - significant anisotropy at S = 7, 9, 10, 12, 20, 21, **23 (P₂(z) = −0.011), 24, 26 (+0.013), 27 (x² − y² = −0.014)**
  - clean from **S ≥ 28**
- **Working rule:** the bias appears whenever each "sample" consumes a fixed, small number of draws, of the order of the lag of 31 or fewer, so that the r[i−3] + r[i−31] relation links coordinates of nearby samples. Separate test programs, timing and code are in the scratchpad (not part of the deliverable).

---

## What this means for BPP

### 1. BPP's `math.random` very likely *is* this generator
- BPP embeds **Lua 5.1/5.2** (HANDOFF.md deps: `liblua5.1-0-dev liblua5.2-dev`).
- In both versions `math.random()` is implemented in C as `(rand() % RAND_MAX) / RAND_MAX`, and `math.randomseed(x)` calls `srand((int)x)`. On glibc **`rand()` == `random()`**, the same additive-feedback generator with lags 3/31 and shared state.
- So every BPP script on Linux draws from exactly the generator in this appendix, with 31-bit resolution.
- The exceptions, which a porter should check with `print(_VERSION, jit and jit.version)`:
  - Lua 5.3 uses `random()` directly, so it is the same.
  - Lua 5.4 uses xoshiro256\*\*, which is fine.
  - LuaJIT uses its own Tausworthe generator, which is fine.
  - On macOS, Lua 5.1/5.2 `rand()` is a *different* and weaker generator, so results there are not comparable with Linux runs at the same seed.
- The state is **process-global**. Any C/C++ code in the BPP process that calls `rand()`/`random()` (BPP's own C++, a library) shares and advances the stream, invisibly to Lua. That breaks seed reproducibility and changes the effective "S".

### 2. Where BPP ports are exposed
The defect needs (a) a fixed small number of draws per sample and (b) a geometric construction that is sensitive to correlations between consecutive coordinates. Both are common in this project:
- **Random initial positions in a disk, ball or annulus by rejection** (formation launches, the 400 × 400 quark scatter in Ch. 17, the APO cluster init in Ch. 19, the Ch. 7 kinetic gas, Ch. 11 coverage). Draw counts per agent are fixed and small, often with 1–3 extra draws per agent for heading, colour or altitude. That is exactly S = 1…27.
- **Random directions** for mean-free-path coverage turns (Ch. 11 and the existing Uniform Coverage), Brownian or kinetic-theory velocities, and the "random triggering" kicks of Ch. 17 Method 2. If these use rejection in the disk or ball, or Box–Muller pairs, a direction bias of 0.3–4% is plausible, and coverage-uniformity metrics are precisely what would reveal it.
- **Sensor noise** (Ch. 19 uniform noise, one draw per fitness evaluation, every agent every tick) and **PSO's r₁, r₂** (Ch. 18/19 batch harnesses) consume millions of draws in a fixed per-iteration pattern.
- The **area-type** use (uniform in a box, no rejection) is safe according to E3. So uniform placement in a square arena is fine.

### 3. Recommendations for the BPP code base
1. **Do not use `math.random` for science runs.** Add a small Lua RNG module.
   - **MRG32k3a** (L'Ecuyer) is designed for double-precision arithmetic: every intermediate value is below 2⁵³, so it is exact in Lua 5.1 numbers without bit operations. It is about 20 lines, has period 2¹⁹¹, and supports **independent streams**.
   - Alternatively use Wichmann–Hill 2006. Both are far better than random() and are fully deterministic across platforms, so Linux and macOS runs match.
   - **xorshift/PCG need 64-bit integers or bit operations**, which Lua 5.1 lacks. Avoid them unless BPP is on LuaJIT or Lua 5.3+.
2. **One stream per purpose** (initial placement, sensor noise, behaviour randomness, per agent if needed). Then adding one extra draw somewhere, such as a new random colour, neither shifts "S" for the others nor changes every other random number in the run. This also gives common random numbers for A/B comparisons (for example LJ against Newtonian from identical starts), which reduces the variance of the difference.
3. **Avoid rejection sampling for directions where a closed form exists.**
   - 2D: θ = 2πU.
   - 3D: z = 2U₁ − 1, φ = 2πU₂, (√(1 − z²) cos φ, √(1 − z²) sin φ, z).
   - Uniform in a disk: r = R√U. Uniform in a ball: r = R·U^{1/3}.
   These are also cheaper in Lua.
4. **Seeding for batch runs (glibc and Lua 5.1 specifics, verified here):**
   - **`srand(0)` and `srand(1)` give identical streams.** `math.randomseed(0)` equals `math.randomseed(1)`. The existing probes and `sweep.sh`/`sumsweep.py` use seeds 1, 2, 3, so they are fine. Never start a seed list at 0.
   - `math.randomseed` truncates to a C int, so 2³² + 1 equals 1. Seeding from `os.time()` gives **identical seeds for parallel jobs started in the same second**. Always pass explicit `SEED` env values, as the probes already do.
   - **Seed before the scene's setup draws anything.** A probe appended with `-l` that calls `math.randomseed` *after* the script has placed its agents seeds only the later behaviour. `field_probe.lua` handles this by re-running `setup()`; `cube_drone.lua` and `tri_drone.lua` should be checked for the same.
   - Log the seed, `_VERSION` and the RNG module name in every output line.
5. **Regression test:** keep a 30-line Lua probe that runs Listing A.1 with `math.random` and with the new RNG for S ∈ {0, 25, 27} at about 10⁷ samples and prints the cos 2θ moment. The expected values for math.random on glibc are about −0.011 and +0.014 at S = 25 and 27; the new RNG should give ≈ 0 ± 2×10⁻⁴. This documents the issue and catches a platform change. It takes about a minute in Lua.
6. For **statistical claims** (Ch. 17's "81% single group", Ch. 19's 10-run tables, coverage uniformity), run at least two RNGs, or the same RNG with different S-patterns. A result that changes with the generator is an artefact.

## Contradictions with and additions to the existing plan
- The plan does not mention RNG. This appendix argues for adding **"RNG module + seed discipline + batch runner"** as shared groundwork *before* the statistical ports: the quark coalescence rate, the Ch. 17 Method 2 success rate, the Ch. 19 tables, Ch. 7 kinetic theory, Ch. 11 coverage and the Ch. 18 benchmarks.
- It also provides a ready-made **sanity demo** that BPP can show visually: scatter 10⁵ points in a disk with math.random at S = 27 against the new RNG, and display the four-lobed density.
