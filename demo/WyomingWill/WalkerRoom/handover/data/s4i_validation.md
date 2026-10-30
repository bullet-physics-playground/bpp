# Warm-starting against the ranking (30 October 2026)

13 ranked builds, nine rough terrains, 5 seeds; runs/run-table.sh plain200 / warm40 / warm40fast, then (plain200: the ranking's runs, from the reference tarball; warm40: 289 runs here, the rest and all of warm40fast on William's machine, 8 jobs, so its times are his):

    python3 runs/table.py runs/out/plain200 runs/out/warm40 runs/out/warm40fast

## runs/out/plain200

| Rank | Walker | Bracing | Timing | Direction | waves2 | waves4 | waves6 | logs3 | logs5 | logs7 | steps3 | steps5 | steps7 | Mean | ± | Hardest three | Runs |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Spears lift 44 | guides | trot | forward | 8.20 | 7.43 | 6.44 | 8.63 | 8.25 | 6.94 | 8.69 | 8.50 | 7.47 | 7.84 | 0.08 | 6.95 | 45 |
| 2 | Spears lift 44 diag | outside, held | trot | forward | 8.13 | 7.16 | 5.48 | 8.63 | 8.26 | 6.30 | 8.63 | 8.41 | 7.34 | 7.59 | 0.12 | 6.37 | 45 |
| 3 | Spears lift 53 | guides | trot | forward | 7.46 | 5.48 | 5.65 | 8.03 | 7.78 | 6.55 | 8.39 | 7.82 | 6.20 | 7.04 | 0.10 | 6.13 | 45 |
| 4 | Chebyshev-Spears diag | outside, held | trot | forward | 8.35 | 6.70 | 5.73 | 8.55 | 7.01 | 3.12 | 8.60 | 7.71 | 6.32 | 6.90 | 0.12 | 5.06 | 45 |
| 5 | Hoecken-Spears 4-bar diag | outside, held | trot | forward | 8.30 | 7.23 | 5.28 | 8.41 | 7.15 | 4.89 | 8.44 | 7.75 | 4.31 | 6.86 | 0.12 | 4.83 | 45 |
| 6 | Spears lift 53 diag | outside, held | trot | forward | 7.81 | 5.75 | 4.93 | 8.09 | 7.81 | 5.08 | 8.37 | 7.17 | 6.42 | 6.83 | 0.14 | 5.48 | 45 |
| 7 | Hoecken-Spears long-stance diag | outside, held | trot | forward | 7.86 | 7.44 | 6.05 | 8.15 | 7.10 | 2.99 | 8.38 | 7.32 | 6.01 | 6.81 | 0.18 | 5.02 | 45 |
| 8 | Hoecken-Spears slider diag | outside, held | trot | forward | 8.34 | 7.66 | 4.71 | 8.27 | 7.05 | 2.12 | 8.50 | 7.81 | 3.44 | 6.43 | 0.20 | 3.42 | 45 |
| 9 | Hoecken-Spears slider | guides | trot | forward | 8.47 | 7.46 | 4.19 | 8.25 | 6.95 | 2.42 | 8.45 | 7.75 | 3.23 | 6.35 | 0.19 | 3.28 | 45 |
| 10 | Hoecken-Spears 4-bar | guides | trot | forward | 8.36 | 7.65 | 4.17 | 8.38 | 6.89 | 2.17 | 8.42 | 7.86 | 2.77 | 6.30 | 0.21 | 3.04 | 45 |
| 11 | Klann | own | trot | forward | 7.65 | 7.87 | 5.43 | 8.55 | 6.66 | 2.79 | 8.74 | 7.06 | 1.28 | 6.22 | 0.13 | 3.16 | 45 |
| 12 | Jansen | own | trot | forward | 8.23 | 7.58 | 5.82 | 7.37 | 6.09 | 1.20 | 7.82 | 6.84 | 4.69 | 6.18 | 0.10 | 3.90 | 45 |
| 13 | Hoecken-Spears long-stance | guides | trot | forward | 8.40 | 8.14 | 3.00 | 8.30 | 4.75 | -0.07 | 8.39 | 4.65 | 1.53 | 5.23 | 0.26 | 1.49 | 45 |

## warm40  (585 runs; a run took 42 s on average)

| Rank | Walker | Bracing | Timing | Direction | waves2 | waves4 | waves6 | logs3 | logs5 | logs7 | steps3 | steps5 | steps7 | Mean | ± | Hardest three | Runs |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Spears lift 44 | guides | trot | forward | 8.24 | 7.12 | 5.14 | 8.74 | 8.43 | 7.46 | 8.79 | 8.45 | 7.69 | 7.78 | 0.07 | 6.76 | 45 |
| 2 | Spears lift 44 diag | outside, held | trot | forward | 8.10 | 7.16 | 5.76 | 8.74 | 8.42 | 6.68 | 8.81 | 8.48 | 7.38 | 7.73 | 0.08 | 6.61 | 45 |
| 3 | Hoecken-Spears 4-bar diag | outside, held | trot | forward | 8.43 | 7.27 | 5.95 | 8.38 | 7.34 | 3.77 | 8.51 | 7.93 | 6.23 | 7.09 | 0.11 | 5.32 | 45 |
| 4 | Spears lift 53 | guides | trot | forward | 7.81 | 5.85 | 3.46 | 8.29 | 8.14 | 6.74 | 8.54 | 7.84 | 7.05 | 7.08 | 0.11 | 5.75 | 45 |
| 5 | Spears lift 53 diag | outside, held | trot | forward | 8.18 | 6.15 | 3.63 | 8.41 | 7.34 | 5.47 | 8.52 | 8.08 | 7.30 | 7.01 | 0.15 | 5.46 | 45 |
| 6 | Chebyshev-Spears diag | outside, held | trot | forward | 8.40 | 7.11 | 5.65 | 8.43 | 7.13 | 2.71 | 8.65 | 7.99 | 5.79 | 6.87 | 0.16 | 4.72 | 45 |
| 7 | Hoecken-Spears long-stance diag | outside, held | trot | forward | 8.08 | 7.76 | 6.26 | 8.39 | 7.05 | 3.20 | 8.59 | 7.69 | 4.50 | 6.84 | 0.21 | 4.66 | 45 |
| 8 | Hoecken-Spears slider | guides | trot | forward | 8.53 | 7.49 | 6.42 | 8.27 | 6.08 | 2.05 | 8.51 | 8.05 | 5.82 | 6.80 | 0.16 | 4.76 | 45 |
| 9 | Hoecken-Spears slider diag | outside, held | trot | forward | 8.50 | 7.56 | 5.64 | 8.29 | 7.42 | 2.12 | 8.51 | 7.99 | 4.93 | 6.77 | 0.16 | 4.23 | 45 |
| 10 | Hoecken-Spears 4-bar | guides | trot | forward | 8.40 | 7.90 | 3.12 | 8.40 | 5.93 | 1.32 | 8.52 | 7.51 | 4.75 | 6.21 | 0.18 | 3.07 | 45 |
| 11 | Klann | own | trot | forward | 8.43 | 7.60 | 3.90 | 8.39 | 6.73 | 3.65 | 8.67 | 7.21 | 0.98 | 6.17 | 0.15 | 2.84 | 45 |
| 12 | Jansen | own | trot | forward | 8.03 | 7.45 | 5.89 | 7.50 | 6.17 | 1.16 | 7.94 | 6.81 | 4.58 | 6.17 | 0.12 | 3.87 | 45 |
| 13 | Hoecken-Spears long-stance | guides | trot | forward | 8.57 | 7.77 | 3.20 | 8.39 | 5.01 | -0.28 | 8.56 | 2.77 | 1.42 | 5.04 | 0.20 | 1.45 | 45 |

## warm40fast  (585 runs; a run took 23 s on average)

| Rank | Walker | Bracing | Timing | Direction | waves2 | waves4 | waves6 | logs3 | logs5 | logs7 | steps3 | steps5 | steps7 | Mean | ± | Hardest three | Runs |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Spears lift 44 | guides | trot | forward | 8.10 | 7.51 | 5.03 | 8.64 | 8.50 | 6.91 | 8.81 | 8.52 | 7.87 | 7.77 | 0.12 | 6.60 | 45 |
| 2 | Spears lift 44 diag | outside, held | trot | forward | 7.98 | 7.17 | 5.74 | 8.71 | 8.39 | 6.66 | 8.71 | 8.47 | 7.90 | 7.75 | 0.07 | 6.77 | 45 |
| 3 | Spears lift 53 | guides | trot | forward | 7.76 | 6.40 | 4.06 | 8.26 | 7.60 | 7.22 | 8.53 | 7.88 | 6.97 | 7.19 | 0.13 | 6.08 | 45 |
| 4 | Chebyshev-Spears diag | outside, held | trot | forward | 8.23 | 7.15 | 5.86 | 8.41 | 6.70 | 4.21 | 8.64 | 7.84 | 6.21 | 7.03 | 0.10 | 5.43 | 45 |
| 5 | Spears lift 53 diag | outside, held | trot | forward | 7.95 | 5.22 | 4.21 | 8.22 | 7.77 | 4.84 | 8.44 | 7.99 | 7.12 | 6.86 | 0.13 | 5.39 | 45 |
| 6 | Hoecken-Spears long-stance diag | outside, held | trot | forward | 8.03 | 7.61 | 5.61 | 8.29 | 7.53 | 2.71 | 8.52 | 7.61 | 5.69 | 6.84 | 0.15 | 4.67 | 45 |
| 7 | Hoecken-Spears 4-bar diag | outside, held | trot | forward | 8.36 | 7.13 | 4.24 | 8.44 | 6.65 | 3.05 | 8.44 | 7.87 | 6.57 | 6.75 | 0.12 | 4.62 | 45 |
| 8 | Hoecken-Spears slider | guides | trot | forward | 8.35 | 7.12 | 4.23 | 8.24 | 5.51 | 2.10 | 8.47 | 7.98 | 6.21 | 6.47 | 0.15 | 4.18 | 45 |
| 9 | Hoecken-Spears 4-bar | guides | trot | forward | 8.15 | 7.75 | 3.04 | 8.43 | 7.14 | 1.61 | 8.47 | 7.85 | 5.15 | 6.40 | 0.19 | 3.27 | 45 |
| 10 | Hoecken-Spears slider diag | outside, held | trot | forward | 8.37 | 7.01 | 6.28 | 8.30 | 5.17 | 1.67 | 8.51 | 7.70 | 4.29 | 6.37 | 0.21 | 4.08 | 45 |
| 11 | Jansen | own | trot | forward | 8.01 | 7.49 | 5.96 | 7.47 | 6.05 | 2.70 | 7.91 | 7.01 | 3.99 | 6.29 | 0.14 | 4.22 | 45 |
| 12 | Klann | own | trot | forward | 8.29 | 7.39 | 4.76 | 8.31 | 5.65 | 2.87 | 8.34 | 7.63 | 0.93 | 6.02 | 0.23 | 2.85 | 45 |
| 13 | Hoecken-Spears long-stance | guides | trot | forward | 8.52 | 7.50 | 3.75 | 8.32 | 2.58 | -0.02 | 8.55 | 4.15 | 0.75 | 4.90 | 0.21 | 1.49 | 45 |

## warm40 against plain200

| Walker | plain200 | warm40 | Change | ± (both) |
|---|---|---|---|---|
| Spears lift 44 | 7.84 | 7.78 | -0.06 | 0.11 |
| Spears lift 44 diag | 7.59 | 7.73 | +0.13 | 0.14 |
| Hoecken-Spears 4-bar diag | 6.86 | 7.09 | +0.23 | 0.16 |
| Spears lift 53 | 7.04 | 7.08 | +0.04 | 0.14 |
| Spears lift 53 diag | 6.83 | 7.01 | +0.18 | 0.21 |
| Chebyshev-Spears diag | 6.90 | 6.87 | -0.03 | 0.20 |
| Hoecken-Spears long-stance diag | 6.81 | 6.84 | +0.03 | 0.28 |
| Hoecken-Spears slider | 6.35 | 6.80 | +0.45 | 0.25 |
| Hoecken-Spears slider diag | 6.43 | 6.77 | +0.34 | 0.26 |
| Hoecken-Spears 4-bar | 6.30 | 6.21 | -0.09 | 0.27 |
| Klann | 6.22 | 6.17 | -0.05 | 0.20 |
| Jansen | 6.18 | 6.17 | -0.01 | 0.16 |
| Hoecken-Spears long-stance | 5.23 | 5.04 | -0.19 | 0.33 |

mean change +0.08 cm/s, mean |change| 0.14; rank correlation 0.97

## warm40fast against plain200

| Walker | plain200 | warm40fast | Change | ± (both) |
|---|---|---|---|---|
| Spears lift 44 | 7.84 | 7.77 | -0.07 | 0.14 |
| Spears lift 44 diag | 7.59 | 7.75 | +0.16 | 0.14 |
| Spears lift 53 | 7.04 | 7.19 | +0.15 | 0.16 |
| Chebyshev-Spears diag | 6.90 | 7.03 | +0.13 | 0.16 |
| Spears lift 53 diag | 6.83 | 6.86 | +0.04 | 0.19 |
| Hoecken-Spears long-stance diag | 6.81 | 6.84 | +0.03 | 0.24 |
| Hoecken-Spears 4-bar diag | 6.86 | 6.75 | -0.11 | 0.17 |
| Hoecken-Spears slider | 6.35 | 6.47 | +0.12 | 0.25 |
| Hoecken-Spears 4-bar | 6.30 | 6.40 | +0.10 | 0.28 |
| Hoecken-Spears slider diag | 6.43 | 6.37 | -0.07 | 0.29 |
| Jansen | 6.18 | 6.29 | +0.11 | 0.17 |
| Klann | 6.22 | 6.02 | -0.21 | 0.26 |
| Hoecken-Spears long-stance | 5.23 | 4.90 | -0.33 | 0.33 |

mean change +0.00 cm/s, mean |change| 0.13; rank correlation 0.96
