## Euler's Disk

**What it shows** — A heavy steel disc is set rolling on its edge on a mirror at a 30° lean. It rolls round in place and leans further over as it loses energy. The flatter it gets, the faster its axis goes round, until it suddenly stops, flat. This is Joseph Bendik's 1990s toy; a spinning coin does the same.

**Model** — Bullet is not used for the dynamics. The README says Bullet's contacts "added energy about as fast as the rolling resistance took it". The script integrates the exact rolling-without-slipping equations: Newton's and Euler's equations for the disc, with the contact force solved each instant so that the contact point is stationary: (I + m(r·r − r rᵀ)) ω̇ = −ω×Iω + m r×(g·up − ω×ṙ) + moments. Integration is RK4 at 9600 steps/s (`ED_STEPS`), with Gram-Schmidt re-orthonormalisation and the centre height reset from the contact geometry every step. The disc is steel (ρ = 7.85 g/cm³), a = 3.8 cm radius, 1.2 cm thick, rolling on the edge of its bottom face (h = 0.6 cm). Run values: m = 427 g, I1 = 1.594, I3 = 3.085 kg cm². Dissipation has two parts: (1) rolling resistance, a moment δ·m·g against the level part of ω, with δ = 30 µm (`ED_DELTA`); (2) a drag of 10 /s on the centre's sideways motion (`ED_DRAG`; README: "the air, and the mirror's grip not being perfect"). The disc is set going at α = 30° with the steady-precession Ω for that lean, 7.47 turns/s. It counts as stopped when α < 0.3°.

**Theory checks**

| Quantity | Theory (formula / source) | Simulation (this run) | Agreement |
|---|---|---|---|
| Precession Ω at 24.92° | Ω² = m g a (a cosα − h sinα) / (sinα (I1 a cosα − I3 h sinα)) → 8.06 turns/s | 8.04 | −0.18 % |
| Ω at 19.88° | same → 8.88 | 8.87 | −0.14 % |
| Ω at 14.98° | same → 10.11 | 10.10 | −0.11 % |
| Ω at 9.99° | same → 12.25 | 12.24 | −0.09 % |
| Ω at 5.97° | same → 15.73 | 15.72 | −0.08 % |
| Ω at 4.00° | same → 19.15 | 19.14 | −0.08 % |
| Ω at 1.98° | same → 27.14 | 27.11 | −0.09 % |
| Ω at 0.99° | same → 38.33 | 38.29 | −0.11 % |
| Rate of fall of √α near the end | δ √(m g a / I1) / (3a) = 0.00832 /s | 0.00818 /s (line fit to samples with α < 2°) | −1.7 % |
| Finite-time singularity constant | Ω (t0 − t) = 3a/δ = 3800 (t0 from the fit: 90.6 s) | 3861 (0.32°), 3864 (0.69°), 3867 (1.20°), 3872 (1.84°) | +1.6 to +1.9 % |
| Energy conservation with no losses (ED_DELTA=0, ED_DRAG=0, 19.8 s) | E constant | 2523.0883 kg cm²/s² at all 77 logged samples | no change at the logged 8 significant figures (< 4e-8 relative), with or without the drag; README now says "to the eighth figure over 20 s" |
| Stopping lean / time | (not theory) README: 0.30°, 81.73 s, 67 turns/s | 0.30°, 81.73 s, 67 turns/s | identical to README |

**Run used**

```
cd demo/WyomingWill/EulersGallery/exhibits/EulersDisk && HOLD_S=0 timeout 1500 bpp -f eulers-disk.lua -n 5400
cd demo/WyomingWill/EulersGallery/exhibits/EulersDisk && HOLD_S=0 ED_DELTA=0 ED_DRAG=0 ED_LOG=disk_e.csv timeout 1500 bpp -f eulers-disk.lua -n 1200
```
```
--- set going: leaning 30 degrees, going round 7.47 times a second; rolling resistance 30 microns ---
  the disc: 427 g, 7.6 cm across, 1.2 cm thick; I1 1.594, I3 3.085 kg cm^2
  t=  8.72 s  leaning 24.92 degrees: going round   8.04 times a second (theory, going round in place:   8.06; -0.18%)
  t= 51.17 s  leaning  5.97 degrees: going round  15.72 times a second (theory, going round in place:  15.73; -0.08%)
  t= 74.63 s  leaning  0.99 degrees: going round  38.29 times a second (theory, going round in place:  38.33; -0.11%)
  t= 81.73 s  it stops, flat, leaning 0.30 degrees, going round 67 times a second
             sqrt(alpha) falling at 0.00818 a second (theory, near the end: delta sqrt(m g a / I1) / (3 a) = 0.00832);
             so it would lie flat at t0 = 90.6 s, going round infinitely fast
             t= 77.17 s, leaning 0.69 degrees: W (t0 - t) = 3864 (theory: 3 a / delta = 3800)
             t= 68.63 s, leaning 1.84 degrees: W (t0 - t) = 3872 (theory: 3 a / delta = 3800)
```
Every number in the README's console sample (10.10/10.11, 15.72/15.73, 38.29/38.33, 81.73 s, 0.00818 vs 0.00832, t0 = 90.6 s, 3864 vs 3800) was reproduced exactly.

**Known departures and honest caveats**
- **The dissipation law is a modelling choice.** It is a constant rolling-resistance moment δ·m·g. That gives √α falling linearly, so α ∝ (t0 − t)² and Ω ∝ 1/(t0 − t). Moffatt's finite-time-singularity analysis (Nature 2000) uses viscous dissipation in the air layer instead, giving α ∝ (t0 − t)^(1/3). The exhibit's "theory" is the theory of its own dissipation model, so it cannot discriminate between real-world dissipation mechanisms. Since 15 Oct 2026 the README and lua header say this plainly: the finite-time end comes from the chosen rolling-resistance law, Moffatt's air law would give α ∝ (t0 − t)^(1/3), Ω ∝ (t0 − t)^(−1/6), and the exhibit can't tell them apart (README also cites Easwar, Rouyer and Menon 2002, vacuum experiments).
- The near-end law is a small-angle asymptote. The 1.7 % gaps (√α rate, Ω(t0 − t)) are consistent with the finite angles of the fit window (α < 2°) and with the extrapolated t0. Note t0 = 90.6 s, while the disc actually stops at 81.73 s.
- The extra sideways drag (10 /s) was added to keep the centre still. Without it, the README says, the centre drifts into mm-sized circles and Ω runs up to 20 % below the in-place theory. The 0.1 % agreement therefore depends partly on this tuned drag.
- The disc never slips and never bounces. The README admits the real toy stops around 0.3° when bouncing and slipping take over, which this model does not include. The 0.3° stop is an imposed threshold, not an emergent result.
- Fixed on 15 Oct 2026: the README and lua header said "430 g"; they now say 427 g, as the console prints.
- The energy test (no losses): re-run 15 Oct 2026 with ED_DELTA=0 alone and with ED_DELTA=0 ED_DRAG=0, 1200 frames (19.8 s): 2523.0883 kg cm²/s² at all 77 logged samples in both. The README and header used to say "a few parts in a million"; they now say "to the eighth figure over 20 s".

**References**
- Joseph Bendik, Euler's Disk toy (1990s), as named in README.
- H. K. Moffatt (2000), Nature: Euler's disk and its finite-time singularity (cited in README and lua header since 15 Oct 2026, as the contrasting air-viscosity law).
- K. Easwar, F. Rouyer, N. Menon (2002), vacuum experiments on the spinning disc (README, since 15 Oct 2026; journal not given there).
