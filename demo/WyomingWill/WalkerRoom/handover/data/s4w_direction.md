# Forward against reversed, the 11 buildable walkers (9 November 2026, handover section 4w)

Each walker on the 8 m track, the nine rough terrains, seeds 1-5, 20 s (speed from 5 s), run-table.sh's standard
(warm40fast: si-warm, 40 iterations, 1/1920 s; motor 0.5 a crank, Earth gravity, ankle springs, ankle stop, 1.0 cm
links, LINK_DAMP 0, trot), the diag builds with outside braces and held pendants, Klann, Jansen and Spears 4-bar on
their own frames; reversed: `EXTRA='REVERSE=true'` (the cranks turned backward, so it walks the other way). Run on
the cloud container (2 cores, Bullet 3.24 with threads, none used); every run in `s4w_runs.csv`. Mean cm/s; ± the
standard error of the nine-terrain mean from the seed spread in each cell; hardest three: waves 6, logs 7, steps 7.

| Walker | Bracing | Timing | Direction | waves 2 | waves 4 | waves 6 | logs 3 | logs 5 | logs 7 | steps 3 | steps 5 | steps 7 | Nine rough | ± | Hardest three |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Chebyshev-Spears lift 51 diag | outside, held | trot | forward | 8.10 | 6.96 | 5.63 | 8.69 | 8.34 | 6.97 | 8.82 | 8.50 | 7.74 | 7.75 | 0.07 | 6.78 |
| Chebyshev-Spears lift 51 diag | outside, held | trot | reversed | 8.48 | 6.55 | 5.11 | 8.80 | 7.77 | 6.21 | 8.73 | 7.42 | 2.02 | 6.79 | 0.19 | 4.45 |
| Chebyshev-Spears lift 62 diag | outside, held | trot | forward | 8.09 | 5.57 | 4.85 | 7.91 | 7.75 | 5.63 | 8.49 | 7.46 | 7.47 | 7.02 | 0.14 | 5.98 |
| Chebyshev-Spears lift 62 diag | outside, held | trot | reversed | 7.73 | 6.45 | 5.82 | 8.92 | 8.78 | 6.53 | 8.84 | 7.08 | 2.44 | 6.95 | 0.19 | 4.93 |
| Chebyshev-Spears diag | outside, held | trot | forward | 8.37 | 7.46 | 5.75 | 8.42 | 7.07 | 3.21 | 8.58 | 7.88 | 6.05 | 6.98 | 0.12 | 5.00 |
| Chebyshev-Spears diag | outside, held | trot | reversed | 8.05 | 7.32 | 5.37 | 8.38 | 7.19 | 2.19 | 8.59 | 7.74 | 6.25 | 6.79 | 0.11 | 4.60 |
| Hoecken-Spears 4-bar diag | outside, held | trot | forward | 8.21 | 7.39 | 4.89 | 8.45 | 7.03 | 3.67 | 8.45 | 7.88 | 5.65 | 6.84 | 0.16 | 4.74 |
| Hoecken-Spears 4-bar diag | outside, held | trot | reversed | 8.28 | 6.94 | 4.42 | 8.47 | 7.20 | 3.76 | 8.49 | 7.93 | 6.29 | 6.87 | 0.12 | 4.82 |
| Hoecken-Spears slider diag | outside, held | trot | forward | 8.25 | 6.66 | 4.52 | 8.32 | 6.28 | 1.35 | 8.50 | 7.79 | 4.23 | 6.21 | 0.21 | 3.37 |
| Hoecken-Spears slider diag | outside, held | trot | reversed | 8.46 | 7.56 | 4.55 | 8.32 | 6.29 | 1.04 | 8.53 | 7.87 | 2.99 | 6.18 | 0.19 | 2.86 |
| Klann | own frame | trot | forward | 8.35 | 7.37 | 4.92 | 8.33 | 5.58 | 3.01 | 8.47 | 7.20 | 1.83 | 6.12 | 0.23 | 3.26 |
| Klann | own frame | trot | reversed | 8.35 | 7.53 | 6.22 | 8.50 | 7.97 | 4.73 | 8.70 | 8.08 | 3.00 | 7.01 | 0.14 | 4.65 |
| Jansen | own frame | trot | forward | 8.25 | 7.01 | 5.15 | 6.95 | 5.26 | 1.33 | 7.89 | 6.73 | 4.07 | 5.85 | 0.18 | 3.51 |
| Jansen | own frame | trot | reversed | 8.35 | 6.97 | 4.54 | 7.76 | 5.56 | 1.70 | 7.78 | 5.96 | 2.09 | 5.63 | 0.14 | 2.78 |
| Hoecken slider diag | outside, held | trot | forward | 8.40 | 6.80 | 4.40 | 7.99 | 5.04 | 0.24 | 8.06 | 5.97 | 1.82 | 5.41 | 0.14 | 2.15 |
| Hoecken slider diag | outside, held | trot | reversed | 8.46 | 6.71 | 4.04 | 7.59 | 5.29 | -0.01 | 7.95 | 6.06 | 2.06 | 5.35 | 0.15 | 2.03 |
| Hoecken 4-bar diag | outside, held | trot | forward | 8.28 | 6.86 | 3.56 | 7.60 | 3.83 | -0.24 | 7.65 | 4.90 | 1.37 | 4.87 | 0.16 | 1.57 |
| Hoecken 4-bar diag | outside, held | trot | reversed | 8.27 | 6.78 | 4.67 | 7.67 | 3.60 | -0.13 | 7.65 | 3.06 | 0.69 | 4.70 | 0.19 | 1.74 |
| Chebyshev diag | outside, held | trot | forward | 7.70 | 6.36 | 2.27 | 6.95 | 3.69 | -0.28 | 7.25 | 5.16 | 1.42 | 4.50 | 0.16 | 1.14 |
| Chebyshev diag | outside, held | trot | reversed | 8.01 | 6.34 | 2.92 | 7.23 | 2.85 | 0.14 | 7.26 | 3.87 | -0.08 | 4.28 | 0.19 | 0.99 |
| Spears 4-bar | own frame | trot | forward | 7.23 | 5.54 | 3.12 | 7.28 | 2.78 | 0.49 | 7.85 | 1.07 | 1.46 | 4.09 | 0.16 | 1.69 |
| Spears 4-bar | own frame | trot | reversed | 8.24 | 7.22 | 5.58 | 7.95 | 5.92 | 0.57 | 8.38 | 6.87 | 1.05 | 5.75 | 0.11 | 2.40 |

| Walker | Forward | Reversed | Reversed − forward | ± | Past 2±? | Hardest three fwd / rev |
|---|---|---|---|---|---|---|
| Chebyshev-Spears lift 51 diag | 7.75 | 6.79 | -0.96 | 0.20 | yes | 6.78 / 4.45 |
| Chebyshev-Spears lift 62 diag | 7.02 | 6.95 | -0.07 | 0.23 | no | 5.98 / 4.93 |
| Chebyshev-Spears diag | 6.98 | 6.79 | -0.19 | 0.16 | no | 5.00 / 4.60 |
| Hoecken-Spears 4-bar diag | 6.84 | 6.87 | +0.02 | 0.20 | no | 4.74 / 4.82 |
| Hoecken-Spears slider diag | 6.21 | 6.18 | -0.04 | 0.28 | no | 3.37 / 2.86 |
| Klann | 6.12 | 7.01 | +0.89 | 0.27 | yes | 3.26 / 4.65 |
| Jansen | 5.85 | 5.63 | -0.21 | 0.22 | no | 3.51 / 2.78 |
| Hoecken slider diag | 5.41 | 5.35 | -0.06 | 0.21 | no | 2.15 / 2.03 |
| Hoecken 4-bar diag | 4.87 | 4.70 | -0.17 | 0.25 | no | 1.57 / 1.74 |
| Chebyshev diag | 4.50 | 4.28 | -0.22 | 0.25 | no | 1.14 / 0.99 |
| Spears 4-bar | 4.09 | 5.75 | +1.66 | 0.20 | yes | 1.69 / 2.40 |

Ranking at each walker's better direction:
 1. Chebyshev-Spears lift 51 diag: 7.75 (forward)
 2. Chebyshev-Spears lift 62 diag: 7.02 (forward)
 3. Klann: 7.01 (reversed)
 4. Chebyshev-Spears diag: 6.98 (forward)
 5. Hoecken-Spears 4-bar diag: 6.87 (reversed)
 6. Hoecken-Spears slider diag: 6.21 (forward)
 7. Jansen: 5.85 (forward)
 8. Spears 4-bar: 5.75 (reversed)
 9. Hoecken slider diag: 5.41 (forward)
10. Hoecken 4-bar diag: 4.87 (forward)
11. Chebyshev diag: 4.50 (forward)
