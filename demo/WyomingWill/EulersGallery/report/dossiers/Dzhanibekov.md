## The Dzhanibekov Effect

**What it shows** — Three identical aluminium T-handles shaped like a wing nut float without gravity, each spun at 1 turn/s about a different principal axis with the same 1% extra wobble. The one spun about its intermediate axis (the stem) flips end over end every few seconds, again and again, as Vladimir Dzhanibekov's wing nut did on Salyut 7 in 1985; the two spun about the smallest (bar) and largest (across both) axes just spin steadily (the "tennis racket theorem").

**Model** — (Facts from the lua header, `dzhanibekov-meshes/t-handle-data.lua`, and README.md, written 15 Oct 2026.)
- Body: solid aluminium (2.7 g/cm^3) T-handle, bar r = 0.5 cm x 10 cm along body x, stem r = 0.8 cm x 4 cm along -y; mass 42.92 g; principal moments I = (0.102132, 0.184989, 0.277521) kg cm^2 about (bar, stem, across). Stem = middle moment.
- Each handle is a Bullet rigid body (convex-hull shape used only for mouse hover; no gravity, no contacts), damping 0. Bullet integrates only the orientation from the angular velocity.
- Bullet's gyroscopic term is off (setFlags(0)). Before every physics step the script advances the body-frame angular velocity by Euler's free-body equations with classical RK4, then projects it back onto the initial kinetic energy and |L| (two Newton steps along the gradients of E and L^2), and writes it back to Bullet.
- 600 physics steps/s by default (10 per 1/60 s frame; slider/DZ_STEPS 120-2400). Initial state: w = W about the chosen axis plus eps*W about the next axis, W = 2pi rad/s, eps = 1%.
- Console: each sign change of the spin component along the chosen axis is a "flip"; every 10 s it prints relative energy and angular-momentum error and the maximum tilt of the spin axis from vertical.
- Companion script `bullet-rotation-test.lua` (I = 1:2:3, w0 = (0.01, 10, 0) rad/s) tests Bullet's own gyroscopic options against Euler's equations.

**Theory checks**

Exact values computed now from Euler's equations: closed form T = 4K(k)/w_p with w_p = sqrt((I3-I2)(L^2-2E I1)/(I1 I2 I3)), k^2 = (I2-I1)(2E I3-L^2)/((I3-I2)(L^2-2E I1)) (case L^2 > 2E I2, here k^2 = 0.99968), cross-checked by a high-precision ODE integration (scipy DOP853, rtol 1e-11) that also gives first-flip times and axis tilts.

| Quantity | Theory (formula / source) | Simulation (this run) | Agreement |
|---|---|---|---|
| Time between flips, stem (middle axis) | T/2 = 2K(k)/w_p = 3.3131 s | mean of 35 intervals 3.3129 s (each printed as 3.30 or 3.32, frame-quantised) | -0.01% |
| Time of first flip | ODE: 1.657 s (1.6566) | 1.67 s (reported at frame end, 1/60 s resolution) | within one frame |
| Flips in 120 s | ODE: 36 | 36 (last at 117.62 s; ODE 117.615 s) | exact |
| Bar (smallest axis): steady | ODE: 0 flips, axis tilt max 2.08 deg | 0 flips, "axis wandered up to 2 deg" | agrees (console rounds to 1 deg) |
| Across (largest axis): steady | ODE: 0 flips, axis tilt max 0.60 deg | 0 flips, "up to 1 deg" | agrees to the console's rounding |
| Energy conservation (all three, 120 s) | E constant | worst printed relative error 4.3e-7 | ~single-precision level |
| Angular momentum conservation | L constant | worst printed relative error 2.2e-7 | ~single-precision level |
| Flip period claim (lua header) | header now: "3.3129 s between flips (mean of 35, over 2 minutes) against the exact 3.3131 s" (fixed 15 Oct 2026; was "to 0.2%, with energy and angular momentum exact") | 3.3129 s (re-run 15 Oct 2026: 36 flips, last 117.62 s) | -0.01% |
| Bullet gyro OFF, no Euler step (test, 60 s) | header: "nothing flips" | 0 flips (exact: 21) | confirms |
| Bullet "explicit" gyro (flag 2) | header: energy +59% | E +59.1%, L +26.1%; mean flip interval 2.34 s vs exact 2.873 s | confirms |
| Bullet default "implicit" (flag 8) | header/README now: energy -31.9%, L -17.5%, flips on time (fixed 15 Oct 2026; header said -44% / -25%) | re-run 15 Oct 2026: E -31.9%, L -17.5%; first flip 1.433 s vs exact 1.437 s; same with flag 4 | matches |
| Implicit at 16x steps (9600 Hz) | header now: "-3.3% and -1.7% a minute" | E -3.3%, L -1.7% (re-run) | confirms |

Linearised instability rate (for context, not printed by the exhibit): lambda = W sqrt((I2-I1)(I3-I2)/(I1 I3)) = 3.27 /s (e-folding 0.31 s).

**Run used**
```
cd demo/WyomingWill/EulersGallery/exhibits/Dzhanibekov
HOLD_S=0 DZ_LOG=dz.csv bpp -f dzhanibekov.lua -n 7200
DZ_FLAGS={0,2,4,8} DZ_LOG=brt_N.csv bpp -f bullet-rotation-test.lua -n 3600   (plus DZ_FLAGS=8 DZ_HZ=9600; DZ_FLAGS=0 DZ_EULER=1)
15 Oct 2026 re-runs: HOLD_S=0 bpp -f dzhanibekov.lua -n 7200; DZ_FLAGS={0,2,4,8} and DZ_FLAGS=8 DZ_HZ=9600, -n 3600 (all as before)
```
```
--- spin 1.0 turns/s, nudge 1.0% ---
  Left   flipped at   1.67 s  (flip 1)
  Left   flipped at   4.98 s, 3.32 s after the last  (flip 2)
  Left   flipped at   8.28 s, 3.30 s after the last  (flip 3)
t=   10s  Left: flips 3, axis wandered up to 90 deg, energy +8.0e-08, ang. mom. +4.0e-08 | Middle: flips 0, axis wandered up to 2 deg, energy +1.3e-07, ang. mom. +6.7e-08 | Right: flips 0, axis wandered up to 1 deg, energy +2.3e-07, ang. mom. +1.2e-07
t=   70s  Left: flips 21, axis wandered up to 90 deg, energy -8.3e-08, ang. mom. -4.1e-08 | Middle: flips 0, axis wandered up to 2 deg, energy +3.1e-07, ang. mom. +1.5e-07 | Right: flips 0, axis wandered up to 1 deg, energy +4.3e-07, ang. mom. +2.2e-07
  Left   flipped at 117.62 s, 3.30 s after the last  (flip 36)
```
The bullet-rotation-test figures come from its CSV logs (the script prints nothing), analysed now.

**Known departures and honest caveats**
- Checked 20 Oct 2026, not changed: Bullet's modes against the exact solution again, with a gallery-wide test (`report/gyro-free-test.lua`, GT_CASE=dzh: the same body, I = 1, 2, 3, 10 rad/s about the middle axis, one body per mode in one world, plus a midpoint-rule Euler step in the script with no projection). With the README's 0.01 rad/s nudge the exact path is so near the unstable one (k² = 0.999999) that single precision alone moves the flips: the midpoint rule, energy within 1.3·10⁻⁴ (600 steps/s) or 7·10⁻⁴ (1200) of exact, flips 23 or 25 times in 60 s against 21. So the comparison was also made with a 1.0 rad/s nudge (k² = 0.990099; exact, from 2K(k)/ω_p and a fine RK4 integration: a flip every 1.27555 s, the first at 0.6378 s, 47 in 60 s). Flips in 60 s, mean interval, energy and |L| after 60 s: midpoint 47, 1.2765 s, −4·10⁻⁵ (600 steps/s) and −1.5·10⁻⁴ (1200); flag 8 (default) 47, 1.2757 s, but energy −52.6%, |L| −31.9% at 600 steps/s, −33.5% and −18.8% at 1200; flag 4 the same as 8; flag 2 41 at 600 (44 at 1200), energy +104% (+49%); flag 0 none. The flip rate under flag 8 stays right while the spin drains away, so a flip count alone would not catch it; this exhibit's own scheme (RK4 plus projection) is the right one for it, and the default's loss rate measured here is what the Gömböc, Bille and Slinky dossiers compare their physical losses with. With 0.01 rad/s, flag 8 at 600 steps/s: −31.9% and −17.5%, as above.
- The rotational dynamics are the script's, not Bullet's: Bullet's own gyroscopic options were found inadequate (above), so Euler's equations are integrated in Lua with RK4 plus an explicit projection onto constant E and |L|. Conservation is therefore enforced, not emergent; the flip period is the real test, and it matches. Since 15 Oct 2026 the header and README say so plainly (the header said energy and L were "exact" and the console "checks" them; the console's E/L figures, at most 4.3e-7 and 2.2e-7, show only single-precision rounding).
- Bullet is single precision: E and L hold only to ~1e-7. The header admits that with a vanishingly small nudge rounding noise starts the wobble sooner. Seen clearly in the test script's own Euler mode (energy-only projection, 0.1% nudge): mean flip interval 2.52 s vs exact 2.873 s (-12%), because the energy noise (about +/-1.5e-6 relative) exceeds the orbit's distance from the separatrix (~2.5e-7). At the exhibit's 1% nudge this does not matter (0.01%).
- Fixed 15 Oct 2026: the header's figures for Bullet's default implicit integrator (-44% energy, -25% L per minute) were not reproducible; re-run gives -31.9% / -17.5% at 600 Hz (same with flag 4), and header and README now quote those.
- No step-size convergence study is reported; only the default 600 steps/s was run here.
- Which axis is "middle" depends on proportions (header: with a 7 cm stem the bar becomes the middle axis); the 4 cm stem is a design choice.
- Fixed 15 Oct 2026: the header's headless-test path and the data-file fallback pointed at `demo/dzhanibekov/`; both now `demo/WyomingWill/EulersGallery/exhibits/Dzhanibekov/`, and the exhibit runs from the repository root (checked: first flip 1.67 s as from the folder).
- Fixed 15 Oct 2026: README.md written (what it shows, keys, theory and console, physics with the Bullet test results, files, env vars).
- Not changed: `bullet-rotation-test.lua`'s own comment says its DZ_EULER mode holds E and L, but the code projects energy only (the README says energy only).
- Text and paths only; physics and console unchanged (hall vs standalone IDENTICAL, 900 frames).

**References** — None cited beyond the historical note (Dzhanibekov, Salyut 7, 1985) in the lua header. Elliptic-function solution of Euler's equations: standard (e.g. Landau & Lifshitz, Mechanics, sec. 37) — added here for the check, not cited by the exhibit.
