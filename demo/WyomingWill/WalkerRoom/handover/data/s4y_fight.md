# Two motors on one braced pair (13 November 2026; handover section 4y)

warm40fast (the standard), 20 s runs, Earth standard, trot, forward, 8 m track, bump 15, normal ground, outside braces, held pendants. Raw: s4y_runs.csv. Probe: runs/fightprobe.lua (run-table.sh, PROBE=runs/fightprobe.lua); tables: runs/fight.py, runs/table.py.

## While walking, as built (flat and the nine rough terrains, seeds 1-3)

| Walker | Bracing | Timing | Direction | Runs | Opposed | Fight / pair torque (all) | (hardest three) | Fight p95 / cap | Motor at cap | Fight when at cap / cap | Pair's cranks apart, most (deg) |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Chebyshev-Spears lift 51 diag | outside, held | trot | forward | 30 | 9.9% | 2.4% | 2.2% | 2.4% | 1.2% | 0.2% | 4.9 |
| Chebyshev-Spears diag | outside, held | trot | forward | 30 | 6.0% | 1.2% | 0.9% | 1.3% | 3.3% | 0.0% | 2.5 |
| Hoecken-Spears 4-bar diag | outside, held | trot | forward | 30 | 5.2% | 1.2% | 0.9% | 1.1% | 2.6% | 0.0% | 3.0 |
| Chebyshev-Spears lift 62 diag | outside, held | trot | forward | 30 | 13.3% | 3.7% | 3.8% | 3.9% | 1.1% | 2.4% | 7.5 |
| Hoecken-Spears slider diag | outside, held | trot | forward | 30 | 12.9% | 6.6% | 8.0% | 3.9% | 0.4% | 0.1% | 5.2 |
| Hoecken slider diag | outside, held | trot | forward | 30 | 6.8% | 1.6% | 1.3% | 1.3% | 0.1% | 0.0% | 1.6 |
| Hoecken 4-bar diag | outside, held | trot | forward | 30 | 8.4% | 2.4% | 2.2% | 2.0% | 1.0% | 0.0% | 1.5 |
| Chebyshev diag | outside, held | trot | forward | 30 | 7.4% | 2.0% | 1.9% | 1.7% | 1.2% | 0.1% | 1.2 |

Opposed: share of frames the pair's two torques have opposite signs, the smaller over 1% of the cap. Fight: the smaller of the two when opposed. Cap: 0.5 a crank (weight x stride).

## One motor a pair at twice the torque, the other crank geared 1:1 to it (PAIR_MOTOR = true), against two motors (nine rough terrains, seeds 1-3)

## one motor + gear against two motors

| Walker | two motors | one motor + gear | Change | ± (both) |
|---|---|---|---|---|
| Chebyshev-Spears lift 51 diag | 7.83 | 7.65 | -0.18 | 0.09 |
| Chebyshev-Spears diag | 6.96 | 7.05 | +0.09 | 0.26 |
| Hoecken-Spears 4-bar diag | 6.88 | 6.76 | -0.12 | 0.23 |
| Chebyshev-Spears lift 62 diag | 6.80 | 6.68 | -0.12 | 0.26 |
| Hoecken-Spears slider diag | 6.05 | 6.18 | +0.13 | 0.37 |
| Hoecken slider diag | 5.31 | 5.24 | -0.07 | 0.24 |
| Hoecken 4-bar diag | 4.83 | 4.59 | -0.24 | 0.29 |
| Chebyshev diag | 4.36 | 4.58 | +0.22 | 0.28 |

mean change -0.04 cm/s, mean |change| 0.14; rank correlation 1.00

Flat (seeds 1-3):

## one motor + gear against two motors

| Walker | two motors | one motor + gear | Change | ± (both) |
|---|---|---|---|---|
| Hoecken slider diag | 9.05 | 9.05 | +0.00 | 0.00 |
| Hoecken 4-bar diag | 9.02 | 9.03 | +0.00 | 0.00 |
| Hoecken-Spears slider diag | 9.02 | 9.02 | -0.00 | 0.00 |
| Chebyshev-Spears diag | 9.07 | 9.02 | -0.05 | 0.00 |
| Chebyshev diag | 8.96 | 8.96 | +0.00 | 0.00 |
| Hoecken-Spears 4-bar diag | 9.00 | 8.95 | -0.05 | 0.00 |
| Chebyshev-Spears lift 51 diag | 8.91 | 8.91 | +0.00 | 0.01 |
| Chebyshev-Spears lift 62 diag | 8.87 | 8.84 | -0.02 | 0.01 |

mean change -0.02 cm/s, mean |change| 0.02; rank correlation 0.81

## One motor a pair, the other crank free (PAIR_MOTOR = "free"; seed 1)

| Walker | Bracing | Timing | Direction | Flat: two motors / one, free | Waves 4 | Logs 7 | Free crank off its partner, most (deg) |
|---|---|---|---|---|---|---|---|
| Chebyshev-Spears diag | outside, held | trot | forward | 9.07 / 9.04 | 7.62 / 5.27 | -0.33 / 0.07 | 2882 |
| Chebyshev-Spears lift 51 diag | outside, held | trot | forward | 8.91 / 8.95 | 6.61 / 7.41 | 6.91 / 6.27 | 13 |
| Chebyshev-Spears lift 62 diag | outside, held | trot | forward | 8.86 / 8.93 | 6.82 / 5.55 | 6.20 / 5.86 | 22 |
| Chebyshev diag | outside, held | trot | forward | 8.95 / 8.91 | 6.79 / 2.52 | -0.28 / 0.09 | 2520 |
| Hoecken-Spears 4-bar diag | outside, held | trot | forward | 9.00 / 8.95 | 7.58 / 4.94 | 3.44 / -0.09 | 2685 |
| Hoecken-Spears slider diag | outside, held | trot | forward | 9.02 / 8.59 | 6.37 / 1.15 | 1.95 / -0.02 | 3960 |
| Hoecken 4-bar diag | outside, held | trot | forward | 9.02 / 9.02 | 6.64 / 0.74 | -0.31 / 0.04 | 2520 |
| Hoecken slider diag | outside, held | trot | forward | 9.05 / 8.97 | 6.95 / 6.26 | 0.09 / 0.60 | 4184 |

## Klann on flat: forward and reversed (seeds 1-2; runs/fightprobe.lua, so "at the cap" is the share of motor-frames at 98% of the cap or more)

| Walker | Bracing | Timing | Direction | Setting | Speed | Cranks (share of driven speed) | Torque p95 / max | At the cap |
|---|---|---|---|---|---|---|---|---|
| Klann | own frame | trot | forward | Bullet, 1000 iterations, 1/3840 s | 9.25, 9.20 | −0.65..1.13, −0.85..1.11 | 0.095 / 0.50, 0.089 / 0.50 | 0.4%, 0.4% |
| Klann | own frame | trot | reversed | Bullet, 1000 iterations, 1/3840 s | 8.79, 8.77 | 0.84..1.02, 0.85..1.05 | 0.079 / 0.50, 0.079 / 0.50 | 0.1%, 0.0% |
| Klann | own frame | trot | forward | warm40fast | 8.93, 9.04 | −1.31..1.19, −0.85..1.14 | 0.093 / 0.50, 0.090 / 0.50 | 0.3%, 0.3% |
| Klann | own frame | trot | reversed | warm40fast | 8.92, 8.92 | 0.16..1.13, −0.29..1.12 | 0.086 / 0.50, 0.086 / 0.50 | 0.0%, 0.1% |
