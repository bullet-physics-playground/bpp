FAMILY 0: MONO-E2 WITH ITS WEAK LEVERS RAISED (families chat, 17 Nov 2026) -- work in progress

  python3 search0.py TAG SECONDS SEED [START.npy]    CMA-ES from mono-e2; SIGMA=... sets the step (0.004)
  python3 check0.py GENOME.npy                       counts L5-7, exact lever, printed hulls with slips

Score: edged_search.py's feasibility stages (convex to 1 um, (1,1) at 0.5 um on levels 5 and 6), then the
soft floor of the exact face lever beyond 25 deg from upright (mean of the lowest 0.5%, mm at 36; face
normals from the harmonics, so no facets), keeping max / min radius >= 1.30.

e2 is fragile: at a step of 0.004 nearly every change breaks (1,1) on level 5 (115 generations before
the first feasible one).

RESULTS (36 mm; printed hulls from prescreen.py, across cut)
  genome         run                    lever min   at    max/min  rest-top  slip sy               slip sz              stall sy / sz (mu 0.05)
  mono-e2        --                     0.012 mm    152   1.356    80 deg    157 um rest at 157    53 um at 155         17.7 / 17.3%
  f0_best_a.npy  search0.py a 560 1     0.106 mm    165   1.370    88 deg    112 um at 166         11 um at 165         10.9 /  4.7%
  f0_best_b.npy  SIGMA=0.0015, b 560 2  0.158 mm    152   1.387    91 deg     64 um at 163         none                 16.5 /  0.0%
                 from f0_best_a
  All three: strict (1,1) on levels 5-7, no extra rest on the aligned hull. f0_best_b reaches 1.1 um of
  non-convexity on level 7 (the search leans on the 1 um tolerance): tighten before using it.

Raising the lever floor does not remove the static slip rest; the rest moves (152 -> 163-166 deg) and
stays near the cut. But the printing chat's BPP drops of mono-e2 (printing/hulls/, 7b4d1e0) show that at
the measured PLA rolling resistance (50 um) that slip rest catches nothing on a level table: the real
failures are far-side stops at 93-161 deg, worse with tilt. Those are e2's weak levers, which is what
this score raises.

BPP DROPS (printing/bpp-drops/ rig, unchanged: 36 mm, across cut, GC_ROLL 50, seed 1, 5400 frames;
hulls from printed_hull.py --step 0.2, then thinned to every second point as the printing chat did for e2;
logs in drops/, f0_best_a.obj and f0_best_b.obj are the bodies)
  case                      mono-e2 (printing chat)          f0_best_a        f0_best_b
  aligned, 1 deg tilt       28/32 (105, 135 x2, 160)         16/19 (115 x2, 120)   25/25, median 14 s (e2: 31 s)
  aligned, 2 deg tilt       20/25 (93, 96, 108 x2, 121, 15)  --               22/24 (115, 160)
  vertical slip, 1 deg      12/18 (102.6 x5, 106.5)          --               24/24
  One seed each, 19-25 rests a run: f0_best_b looks clearly better than e2, f0_best_a no better. The
  acceptance test asks for 95% level-table runs too (not yet run for f0_best_b), and f0_best_b's 1.1 um
  non-convexity at level 7 should be polished away first (the printed body is the hull either way).

POLISH, 18 Nov: f0_best_c.npy (CONV=0.0003 SIGMA=0.0008 search0.py c 560 3 f0_best_b.npy)
  convexity 0.00 um at levels 5-7; strict (1,1); exact lever min 0.171 mm at 129 deg; max/min 1.381; rest-top 91 deg
  static slip rests: sy 94 um at 163 deg, sz 9 um, aligned none
  BPP level table (same rig and thinning as above):   aligned 19/23 (83%; 104 deg x3, 115)   vertical slip 23/24 (96%; 160)
  FAILS the 95% level-table test aligned. The stops at 104 deg are one band of printed-hull faces (104-112 deg,
  levers 77-104 um at 36 mm) where the smooth design lever is 0.22-0.30 mm: 0.12 mm layer steps at about 45 deg
  to the layers become long flat facets and cost about 0.15 mm of lever. So the design needs margin there (the
  shared score in ../common/fam.py now penalises the mean shortfall below 0.45 mm), or a cut whose layers do not
  cross the band at 45 deg.

VERDICT, 18 Nov: f0_best_b is the candidate; f0_best_c is withdrawn (worse on a level table, above).
  The printing chat's full set for f0_best_b (printing/hulls/families-f0_best_b/, ec2fc18) with these runs:
  level al 22/22, sy 25/25, sz 17/17; 1 deg al 40/41, sy 24/24, sz 10/10; 2 deg al 39/50 (78%, stops 98-101 deg).
  f0_best_b.obj (the convex hull; what is printed): no extra resting face deeper than 2 um (prescreen edge
  passes), rest face 0.09 deg from -Y; support-function minima on it have levers >= 157 um at 36 mm (sampling
  kinks, not equilibria). Its 1.1 um non-convexity exists only in the radial description.
