## The Rattleback

**What it shows** — A rattleback (celt) is a boat-shaped body whose mass axes are turned a few degrees from the lines of its hull. Spun one way, it spins smoothly. Spun the other way, it starts to rock, stops, and spins back. Tapped on the end from rest, it starts spinning its preferred way. Three identical rattlebacks are shown: left, spun clockwise (the wrong way); middle, spun anticlockwise (its own way); right, "restless", spun clockwise on an almost lossless table, so it reverses more than once.

**Model** — The body is a solid half-ellipsoid with half-axes 6 × 1.5 × 1.2 cm, plastic at 1.2 g/cm³, with the hull turned 8° about the vertical from the principal axes. From `rattleback-data.lua`: m = 27.14 g, I = (0.01454, 0.20765, 0.19775) kg cm². Collision uses Bullet's own contact (unlike the other three exhibits here): a btConvexHullShape of 3073 surface points, 0.1 mm margin, contact-processing threshold 0.001 cm, friction 0.6, restitution 0. Bullet's gyroscopic term is off (`setFlags(0)`). Instead, Euler's torque-free equations are advanced with RK4 before every Bullet step. Rolling resistance is a moment δ·m·g against the horizontal part of ω about the contact, which is taken as directly below the centre of mass. Defaults: δ = 50 µm (left and middle) and 5 µm (restless). The run uses 1200 steps/s, no damping. Initial conditions: 1 turn/s about the vertical plus a 1 rad/s "hand wobble" about the long axis; the tap is 3 rad/s of pitch. Documentation: README.md (written 15 Oct 2026: what it shows, keys, model, theory and console, the reference model and its checks, files, headless env vars), the lua header, and `reference/` (rb_ref.py, an independent rolling-without-slipping ODE model; rb_scan.py; rattleback-test.lua).

**Theory checks**

| Quantity | Theory (formula / source) | Simulation (this run) | Agreement |
|---|---|---|---|
| Mass properties | rb_ref.py: m = (2/3)π A B C ρ; I from the half-ellipsoid formulas | data file 0.0271434 kg; I = 0.0145353, 0.2076467, 0.1977530; rb_ref gives 0.02714336, 0.01453527, 0.20764671, 0.19775295 | identical |
| Linear growth rate, wrong way (clockwise) | eigenvalues of linearised rb_ref (recomputed 15 Oct 2026); header/README now "8.9/s at 1 turn/s; 8.5/s at 6 rad/s" (fixed; header said 8.5 at 1 turn/s) | 8.493 /s at 6 rad/s; 8.882 /s at 2π rad/s (1 turn/s) | matches |
| Growth rate, own way (anticlockwise) | code comment / README: 1.7 /s at 1 turn/s (README: 1.66 at 6 rad/s) | 1.661 /s at 6 rad/s; 1.728 /s at 1 turn/s | OK |
| Skew 0 control | no instability | growth 0.0000 /s both ways (rb_ref); rb_ref integration: no reversal in 30 s | OK |
| Lossless reference reverses both ways | code: "unstable in BOTH directions" | rb_ref, ±6 rad/s, skew 8: first reversal at 4.68 s (+spin) and 1.07 s (−spin); energy drift −1.4e-9 / −1.5e-9 | OK |
| Exhibit: wrong-way spin reverses | expected | Left REVERSED at 0.67 s (rocking up to 7°) | qualitative OK |
| Exhibit: own-way spin does not reverse | expected (δ = 50 µm damps the weak instability) | Middle never reversed in 60 s | OK |
| Restless (δ = 5 µm) reverses repeatedly | "again and again" | 3 reversals: 0.65, 4.22, 6.23 s; then ~+0.02 turn/s creep to 60 s | qualitative OK; only 3 reversals |
| Tap from rest spins anticlockwise | expected | all three anticlockwise at 0.03 s; restless later reverses at 3.10 and 5.52 s | OK |
| δ window (left and middle; RB_ROLL, 30 s runs, exhibit start) | header/README now state the measured window (fixed 15 Oct 2026; header said "20-100 µm one-way; at 200 neither way reverses") | 0, 10 µm: both reverse repeatedly. 20: Left reverses 3x (0.55, 5.35, 7.62 s). 30: Left 3x (0.52, 3.93, 5.38 s), Middle once at 8.73 s. 40, 50, 75, 100: one-way (Left once at 0.52-0.68 s, Middle never). 150, 300: neither reverses. 200: Left reverses late, 4.57 s | one-way window 40-100 µm; documented as such |
| Bullet harness vs reference, no losses (rattleback-test.lua, RB_EULER=1, RB_ROLL=0, skew 8, ±6 rad/s, 0.02 rad/s rock) | rb_ref first reversal: 1.07 s (−6, wrong way), 4.68 s (+6) | 0.70 s (−6), 3.15 s (+6) | both ways, same order; Bullet reverses ~1/3 sooner |

**Run used**

```
cd demo/WyomingWill/Rattleback && HOLD_S=0 timeout 1500 bpp -f rattleback.lua -n 3600
HOLD_S=0 RB_START=tap ... -n 1800 ;  HOLD_S=0 RB_ROLL={0,20,100,200} ... -n 1200
python3 reference/rb_ref.py (run via runpy, PYTHONDONTWRITEBYTECODE=1); linearised growth: rb_scan-style Jacobian on rb_ref
reference/: RB_SKEW={8,0} RB_SPIN={-6,6} RB_EULER=1 RB_ROLL=50 RB_LOG=... bpp -f rattleback-test.lua -n 1200
15 Oct 2026 re-runs: default -n 3600; RB_START=tap -n 1800; RB_ROLL={0,10,20,30,40,75,100,150,200,300} -n 1800;
  rb_ref.py and the growth rates again; rattleback-test.lua as above plus RB_ROLL=0 (skew 8, ±6), -n 600
```
```
  Restless REVERSED at  0.65 s: now spinning anticlockwise (rocking up to 8 deg)
  Left  REVERSED at  0.67 s: now spinning anticlockwise (rocking up to 7 deg)
t=  2.0s  turns/s: Left +0.62  Middle +0.79  Restless +0.71   (+ = anticlockwise)
  Restless REVERSED at  4.22 s: now spinning clockwise (rocking up to 16 deg)
  Restless REVERSED at  6.23 s: now spinning anticlockwise (rocking up to 16 deg)
skew 8 spin +6:  ... first reversal 4.68 s  rock 28.7 pitch 6.2  energy drift -1.4e-09
skew 8 spin -6:  ... first reversal 1.07 s  rock 28.7 pitch 6.1  energy drift -1.5e-09
skew 0 spin +6:  ... first reversal none  rock 0.0 pitch 0.0  energy drift -4.4e-14
(RB_ROLL=200)  Left  REVERSED at  4.57 s: now spinning anticlockwise (rocking up to 5 deg)
```

**Known departures and honest caveats**
- The theory comparison is **qualitative in the exhibit itself**. The console reports reversals and spin rates, never comparing them with a theory number. The quantitative checks (growth rates, the both-ways instability) live in `reference/rb_ref.py`, an independent rigid-ellipsoid, no-slip, energy-conserving model, not in the exhibit.
- The exhibit uses Bullet's general convex-hull contact, with friction, possible slip and a hull faceted into 3073 points. The reference model assumes no slip on a smooth ellipsoid. The two are not compared directly on reversal time or spin after reversal.
- One-way behaviour is **tuned via rolling resistance**. With no losses, this shape reverses both ways. The real asymmetry depends on table losses, a modelling choice. Fixed 15 Oct 2026: the header's window ("20-100 µm one-way; at 200 neither") is replaced by what runs from the exhibit's start show: one-way for 40-100 µm; at 20 and 30 µm the wrong-way one turns round and back (at 30 the own-way one also reverses once, late); at 150 and 300 neither reverses, but at 200 the wrong-way one still does, late (4.57 s), so above 100 it is near the edge. The window is narrow and not monotone; the default 50 µm sits inside it.
- The rolling-resistance contact point is approximated as directly below the centre of mass.
- After the restless one settles, it keeps a ~0.02 turn/s spin out to 60 s rather than coming to rest. This is likely contact-solver creep.
- Corrected 15 Oct 2026 (this dossier's earlier reading was wrong): in the reference harness (`rattleback-test.lua`, RB_ROLL=50) the body sits on the table from the start (height 0.7600 cm is the rest height plus the 0.01 cm margin). It spins at ±6.00 for ~10 s because the 50 µm rolling resistance at once removes almost all of the 0.02 rad/s starting rock (0.01 deg -> 0.0009 deg at the first frame); the rock then regrows slowly, and skew 8 at −6 rad/s reverses at 11.1 s; +6 does not, skew 0 neither, in 20 s. With RB_ROLL=0 it reverses both ways (0.70 s and 3.15 s; rb_ref 1.07 and 4.68 s).
- Fixed 15 Oct 2026: the data-file fallback path was `demo/rattleback/`; it is now `demo/WyomingWill/Rattleback/`, and the exhibit runs from the repository root (checked).
- Fixed 15 Oct 2026: the header quoted 8.5 /s "at 1 turn/s"; that is the 6 rad/s value. It now says 8.9 /s at 1 turn/s (8.5 at 6 rad/s). The header's key list also said R spins "left clockwise, right anticlockwise" and T taps "both"; now left and right clockwise, middle anticlockwise, and all three.
- The restless one reverses 3 times (0.65, 4.22, 6.23 s), not "again and again" as the help text says; the header now gives the three times; the help text was left as it is.
- Text and a fallback path only; physics and console unchanged (hall vs standalone IDENTICAL, 900 frames; a fresh 600-frame standalone run matches the start of the earlier 3600-frame run line for line).
- Fixed 17 Oct 2026: **the start pause changed the console.** The `t=` lines every 2 s were printed on bpp's frame count (`N % 120`), which counts the pause's frames too, so with the pause they came at t = 1.5, 3.5, ... s instead of 2.0, 4.0, .... rattleback.lua now counts only the frames it runs (the same for the log file). With HOLD_S=0 the output is byte-identical to before (1800 frames); HOLD_S=0 for 1800 frames is now a prefix of the default for 1830 (also at 900 and 2400); hall against standalone (cmp2.sh, 1800 frames): IDENTICAL (18 run lines).

**References** — None are cited in code or reference files. The classical analyses (Walker 1896; Bondi 1986, Proc. R. Soc. A; Garcia & Hubbard 1988, Proc. R. Soc. A) are the standard theory for the spin-direction-dependent instability. They are added here for context and are not used by the exhibit.
