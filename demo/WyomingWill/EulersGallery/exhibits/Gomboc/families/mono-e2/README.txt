MONO-E2: VERIFICATION AND HAND-OFF (families chat, 17 Nov 2026)

mono-e2 is a convex, uniform-density body with one resting and one balancing point (a true gomboc)
that looks unlike the classic shape: a fat pebble with one soft crease, max / min radius 1.36, its
balancing point on the crease 80 deg from the rest (the classic's are about 172 deg apart). It was
found by the shape chat (../../monostable-search/edged_search.py e2 900 3 4 2). Write-up with the
literature check and the search plan for new families:
https://claude.ai/artifact/BKgP7G3w56Lb3knbFD8V46

FILES
  mono-e2.npy       the genome (75 numbers, the same as ../../monostable-search/genomes-edged/mono-e2.npy)
  mono-e2.obj       convex hull of edged.body(a, 3, 4, 6): 41,802 vertices, 83,600 faces; 9 cm at
                    the widest, in cm; centre of mass at the origin; upright = +Y (resting face within
                    0.06 deg of -Y); X = least-inertia axis projected horizontal; volume 270.85 cm^3
  e2_views.png      three views, upright, crease dotted
  e2_levermap.png   lever at 36 mm over all orientations (equal-area, centred on upright)
  scripts/          the checks below; run from any folder, they find ../../../monostable-search

HOW THE SHAPE IS DESCRIBED
  r(u) = min_k exp(sum_j a_kj s_j Y_j(u)), K = 3 pieces, real spherical harmonics of degree 0..4,
  s_j = 1 / max |Y_j| on the level-5 icosphere (as edged.py). Pieces 0 and 1 show; they meet along one
  closed crease, 317 mm long at 90 mm; the angle between the face normals across it is 3.3-47 deg.

SHAPE (at 90 mm; at 36 mm multiply lengths by 0.4)
  principal extents 87.1 x 81.4 x 76.5 mm; centre of mass 34.85 mm up at rest, 47.26 at the top
  (climb 12.41 mm, 4.96 at 36 mm); max / min radius 1.356

EQUILIBRIA: STRICT (1,1), NO SADDLES
  1 repo counter, levels 5/6/7          1/1 at 0.5, 2, 5, 20 um; convexity <= 0.12 um
  2 support function (sphere_metrics)   1/1 at 5 um and deeper; minima of 1-4 um within 5 deg of the
                                        rest are facet artefacts (check 3)
  3 exact surface near rest and top     one minimum (e2_local.py)
  4 crease, exact (e2_crease.py)        distance along the crease has two critical points: the top
                                        (radial inside the normal cone) and a minimum at 38.31 mm
                                        (outside the cone: not an equilibrium)
  5 smooth faces (e2_smoothlever.py)    lever zero only at the rest
  6 delivered .obj (prescreen.py)       no extra resting face deeper than 2 um

MARGINS (lever at 36 mm, exact surface)
  152 deg  0.012 mm  face 0 at the crease's shallow end (crease angle 4.8 deg)  <- the slip trap
   52 deg  0.042 mm  crease, nearly perpendicular to the radial direction
  159, 127, 112, 97, 118 deg: 0.088, 0.122, 0.147, 0.174, 0.182 mm
  Weak share (lever < rest height x tan 1.4 deg beyond 25 deg, hull support-point lever): 10.0% at
  level 7, but 7.2 / 9.1% at levels 5 / 6: the hull value depends on the mesh. GOMBOC900 on the same
  measure: 6.3%.
  Rocking: least lever over azimuth 0.38 / 0.53 / 0.89 mm at 10 / 15 / 20 deg tilt.

PRINT MODEL (prescreen.py, across cut through the centre of mass)
  aligned   no extra rest                        stall 0.0 / 2.0 / 21.3% at friction 0.05 / 0.15 / 0.3 mm
  slip sy   extra rest 157 um deep at 157 deg    stall 17.7 / 21.9 / 30.5%
  slip sz   extra rest  53 um deep at 155 deg    stall 17.3 / 17.3 / 29.5%
  Every plane through the centre of mass has overhangs of 45 deg or less (best plane 3.7 deg).
  Verdict: passes max / min >= 1.2, visibly new and strict (1,1); fails 95% upright with a slip.

SCRIPTS (python3; numpy, scipy, shapely, cma for the repo; output files go to the current folder)
  sphere_metrics.py   support function, persistence, lever with tied contacts, weak share, rocking
  e2_analyze.py [levels]  all metrics per level (level 7 needs about 6 GB)
  e2_local.py, e2_crease.py, e2_smoothlever.py, e2_levmin.py   checks 3-5 and the margins
  e2_print.py         printed hulls, slips, stall, overhang over cut planes
  e2_export.py        writes out/mono-e2.obj (make out/ first)
  e2_figs.py          the two pictures; calib.py  the same metrics on GOMBOC900
