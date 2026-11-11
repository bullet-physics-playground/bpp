Monostable convex bodies found from scratch (9 Nov 2026)

Seven convex bodies of uniform density, each with ONE resting point, found by a
search that starts from random shapes, not from GOMBOC900 or a formula. None
is a gomboc: each has 2 to 4 balancing (unstable) points, not one. They were
made for printed self-righting toys, where one resting point is what matters
and extra balancing points do no harm (a body cannot stop on one). All seven
are lopsided: for every plane through the centre of mass, the mirror image
misses the body by 4 mm or more somewhere (at 90 mm).

HOW A SHAPE IS DESCRIBED
  genomes/<name>.npy  real spherical-harmonic coefficients, degrees 2..L
  (L = 6: 45 numbers; L = 4: 21). The support function about the origin is
  h(n) = 1 + sum c_k Y_k(n) on the 10,242 directions of an icosphere (level 5);
  the body is the intersection of the half-spaces x.n <= h(n), so it is convex
  whatever the numbers are. Where h is not a smooth body's support function
  some half-spaces miss the body, which leaves creases (edges), never flats.
  build.py turns a genome into the body: exact centre of mass at the origin,
  principal axes, longest extent 90 mm.

FILES
  build.py    genome -> body; counts resting and balancing points by
              persistence (resting: minima of face height over the face graph,
              as ../variety-reconstruction/basins.py; balancing: maxima of the
              distance from the centre of mass over the vertex graph); the
              softest rocking margin; --write makes meshes/<name>.obj and .lua
  search.py   the search (CMA-ES, popsize 16); --one-unstable for a (1,1) body
  drop.py     drop test in PyBullet
  meshes/     <name>.lua (hull points, volume, inertia, down, top, unstable
              points; 9 cm, in cm, as ../gomboc-meshes/*.lua) and <name>.obj
  gallery.png the seven, each resting on its one resting point
  smooth.py, smooth_check.py, smooth_search.py, smooth_refine.py, smooth_fold.py, mono-g1.png
              the same genomes read as smooth bodies, and the search that found mono-g1 (below)
  smooth_improve.py  strengthens mono-g1's weakest lever: mono-g2, mono-g3 (below)
  edged.py, edged_search.py, edged_drop.py, genomes-edged/, edged.png
              bodies with creases, and the search that found mono-e1 and mono-e2 (below)
  prescreen.py  the printing chat's print model (layers, seam slip) and a drop-stall metric (below)
  variety_map.py  a variety map (MAP-Elites) over build, scored by that metric (below)

  python3 build.py genomes/*.npy                  (about 1 s each)
  python3 build.py --write meshes genomes/*.npy
  python3 drop.py 30 genomes/*.npy                (about 4 s a drop)
  python3 search.py out.npy 600 6 2               (10 minutes)
NEEDS  Python 3, numpy, scipy (1.15 or later), cma 4.5.0, pybullet 3.2.7 (drop.py)

THE SEARCH
  Stage 1 drives the total depth of the extra resting points (any deeper than
  2 um at 90 mm) to zero; stage 2 then maximises the softest rocking margin at
  the resting point, capped at 6 mm, less 0.5 mm for every unit by which the
  longest extent exceeds twice the shortest. Every run that found a shape
  scored 5.8-6.0. The seven came from the same algorithm in its first form,
  which counted resting points with a different, compiled persistence routine
  (same 2 um threshold): mono-p1 25 min, L = 6, seed 1; mono-s2..s5 L = 6, seeds
  2-5; mono-s6, s7 L = 4, seeds 6, 7; each 10 min at most on 2 cores. Two more
  runs at L = 8 (seeds 8, 9) found no monostable body in 10 minutes. build.py
  re-checks each genome independently (table below).

THE SEVEN (at 90 mm; from build.py and drop.py)
  rocking margin = least over directions (every 5 deg) of h'' at the resting
  point, from quadratic fits over +-15 deg: the restoring lever per radian of
  tilt. GOMBOC900: 1.14 mm, its centre of mass 34.9 mm above the table.
  Counts are resting/balancing points deeper than 2, 5, 20, 100 um.

  name     extents (mm)      rest  margin  counts                     drops upright
  mono-p1  90.0 x 50.3 x 44.1  18.9  16.0   1/2  1/2  1/2  1/2         100%
  mono-s2  90.0 x 40.7 x 35.1  14.5  14.7   1/4  1/3  1/3  1/2         100%
  mono-s3  90.0 x 49.8 x 40.6  17.7  16.0   1/4  1/4  1/4  1/4         100%
  mono-s4  90.0 x 37.1 x 35.2  14.9   9.3   1/3  1/3  1/3  1/3         100%
  mono-s5  90.0 x 38.2 x 35.4  15.1  11.2   1/2  1/2  1/2  1/2          93%
  mono-s6  90.0 x 68.7 x 67.4  31.7   9.4   1/5  1/4  1/4  1/4          93%
  mono-s7  90.0 x 63.0 x 60.8  28.0  12.3   1/3  1/2  1/2  1/2          63%
  (rest = height of the centre of mass above the table at rest, mm)

  Drops: drop.py, 30 random drops each at 36 mm; upright = within 10 deg after
  6 s. Those that were not: mono-s5 at 32 and 70 deg, mono-s6 at 11 and 18,
  mono-s7 eleven at 10-17 deg. Not yet looked into: on the round, tall s6
  and s7 these may still have been rocking at 6 s.

  Two families: low wedge-like loaves (p1, s2-s5: centre of mass 15-19 mm up)
  and round, domed buns (s6, s7: 28-32 mm up, nearer GOMBOC900's build).

MONO-G1: ONE RESTING AND ONE BALANCING POINT, A (1,1) BODY LIKE THE GOMBOC
  Found by a second search, on smooth bodies. On the exact check it has one resting point, one
  balancing point and no saddle, but it is fragile and a poor self-righter (below). It is not the
  gomboc: its resting and balancing points are 90 deg apart (the gomboc's are opposite), and no plane
  through the centre of mass is a mirror plane (the best misses by 2.9 mm at 90 mm).

  smooth.py reads a genome as a smooth body: it differentiates the support function exactly (boundary
  point, radii of curvature), finds the centre of mass by quadrature, and takes equilibria as the
  critical points of the support function about the centre of mass, so facets cannot make false ones.
  The body must be truly convex (radii of curvature >= 0). mono-g1's least radius is 1.9 mm, so all
  its half-spaces touch and build.py builds the same body, faceted.

  python3 smooth_check.py genomes/mono-g1.npy     (about 6 s; scaled to a diameter of 90 mm, where
  build.py makes the longest principal extent 90, about 1% larger)
    exact: 1 resting, 1 balancing, 0 saddles (resting - saddles + balancing = 2); every critical
    point by Newton's method from 10,242 starts, centre of mass on a level-7 icosphere
    rest: centre of mass 38.3 mm up; rocking margin (least curvature) 21.5 mm/rad
    top: 46.4 mm from the centre of mass; curvatures -34.4 and -13.3 mm/rad
    extents (build.py) 90.0 x 84.6 x 81.9 mm

  How it was found (as run, 2 cores):
    1. python3 smooth_search.py b6 900 6 15: (1,1) on the 2 / 5 um persistence counts. The exact
       count still showed shallow pairs, an extra point and a saddle 0.1-4 um deep with curvature near
       zero, as in all four runs that got this far (L = 4, 6, 6, 8; two more did not).
    2. python3 smooth_refine.py rb6 540 6 1 sm_best_b6.npy, with the curvature floor at 0 rather
       than today's 0.2 mm; then python3 smooth_refine.py srb6 600 6 2 q_best_rb6.npy. One pair left
       (curvature 0.07 mm/rad).
    3. python3 smooth_fold.py q_best_srb6.npy mono-g1.npy: one continuation step merges the pair,
       then four more steps the same way (reproduces genomes/mono-g1.npy exactly).
  smooth_refine.py maximises Q = least over the sphere of |g| / sin(angle to the nearer of the rest
  and the top), g the tangential part of x(n) - G: the restoring lever per radian of tilt, positive
  only when there is no other equilibrium. Cheaper checks were gamed: the search first hid extra
  points between grid points, then away from Newton starts taken from the grid, so smooth_refine.py
  checks grid depths first and then counts by Newton's method from fixed starts.

  Fragile:
    * Q = 0.010 mm/rad at 90 mm. Along the direction of the merge, (1,1) holds from 0.3 um back
      (the merged pair, 51 deg from the rest, returns) to at least 12 um on, and is lost by 42 um on
      (an extra resting point and a saddle at 108 deg); each the largest change of the surface, other
      directions not explored. mono-g1 sits near one edge of that window.
    * The weakest lever is 109 deg from the rest: 0.010 mm at 90 mm, 0.004 mm at 36 mm, against
      drop.py's rolling friction of 0.1 mm. drop.py: 53% upright of 30; with 30 s instead of 6 s,
      7 of 12, the other five stopped at 97-112 deg. In practice it has a second rest there.
    * meshes/mono-g1.obj and .lua, built as the others, have false resting faces from the facets (58
      deeper than 5 um, none deeper than 20 um) and list a second balancing point; the smooth body has
      neither. A print would need a much finer mesh, and could not hold the tolerance anyway.
  So mono-g1 shows that this family holds a (1,1) body other than the gomboc. It is not a toy to
  print: the seven above right themselves far better.

MONO-G2, MONO-G3: MONO-G1 WITH ITS WEAKEST LEVER STRENGTHENED
  smooth_improve.py takes trust-region steps that raise the least of the lever field's local minima
  (linearised, a linear programme each step), keeping a step only if the exact count stays (1,1), the
  least radius of curvature stays >= 0.2 mm, and Q rises.
    python3 smooth_improve.py genomes/mono-g1.npy g1a.npy 4
    python3 smooth_improve.py g1a.npy mono-g2.npy 80                           (L = 6)
    python3 -c "import numpy as np; np.save('g2L8.npy', np.r_[np.load('mono-g2.npy'), np.zeros(32)])"
    python3 smooth_improve.py g2L8.npy mono-g3.npy 120                         (the same body in the L = 8 basis)
  (as run, except that the first two runs tracked at most 8 weak spots; at L = 8 about 20 tied, so the
  cap is now 80, and a rerun of the first two gives a slightly different mono-g2)
  smooth_check.py, both: exact 1 resting, 1 balancing, 0 saddles; grid counts 1/1 at every depth.
    name     L  Q (mm/rad)  least radius  rest up  extents (mm, diameter 90)  drops upright (120)
    mono-g1  6    0.010       1.86 mm     38.3     81.8 x 82.5 x 89.1           54%
    mono-g2  6    0.207       1.34 mm     38.3     81.8 x 82.5 x 89.1           64%
    mono-g3  8    0.251       0.23 mm     38.3     81.8 x 82.5 x 89.2           66%
  25 times the lever bought 12 points of drops. The far stalls (near 100 deg) fell from a third of the
  drops to a fifth; the near-upright friction stalls (10-25 deg) stayed at about 12%. The weak region is
  a ridge of near-equilibria, not a point, as in Schettini Gherardini's mono-monostatic polyhedron
  (arXiv 2609.07827, its "geometric price"). (The 120-drop figures use drop.py with 120 drops; with 30,
  mono-g1 showed 53%.)

MONO-E1, MONO-E2: (1,1) BODIES WITH ONE CREASE
  edged.py describes a body by its radial function about the origin, the least of K smooth pieces,
  rho(u) = min_k exp(sum_j a_kj Y_j(u)), degrees 0..4 (K = 3: 75 numbers, genomes-edged/*.npy). Where
  one piece takes over from another there is a crease. Equilibria are the critical points of the
  distance from the centre of mass over the sampled surface, with points added along the creases (an
  equilibrium on a crease is as real as one on a face), counted by persistence; convexity is checked by
  the depth of any sample inside the hull of all samples.
  edged_search.py: CMA-ES, popsize 16, restarted with twice the population when it stalls (none did in
  15 minutes). Score: not convex, then extra depth on the level-5 grid, then the same on level 6, then
  -Q. Six runs, 15 minutes each on 2 cores, L = 4:
    K = 1 (seeds 3, 6) and K = 2 (seeds 1, 4): every run ended as one smooth piece, stuck with 60-650
      um of extra resting / balancing points, as the smooth searches were before refining.
    K = 3 (seeds 2, 5): both reached (1,1) directly, each with 2 pieces showing and one crease.
    python3 edged_search.py e1 900 3 4 5          (mono-e1)
    python3 edged_search.py e2 900 3 4 2          (mono-e2)
  (the runs stop on time, so a rerun on another machine may stop at a different point)
  In both the balancing point lies ON the crease and the resting point on a smooth face (edged.png):
  found twice from independent starts.
    name     counts (0.5,2,5,20 um) L5/L6/L7  convexity  rest up  top    extents (mm)          Q (L6)  drops upright (120)
    mono-e1  1/1 at every level and depth     <= 0.3 um  32.6     48.0   89.4 x 80.1 x 71.6    0.033   96%  (5 at 149-150 deg)
    mono-e2  1/1 at every level and depth     <= 0.12 um 34.9     47.3   87.1 x 81.4 x 76.5    0.135   80%  (17 at 11-23 deg)
    python3 edged_drop.py 120 genomes-edged/*.npy
  mono-e2's weakest spot, 152 deg from the rest, lies on its crease; on a 0.008 deg local grid there is
  no hidden equilibrium there (the surface slope stays 0.033 mm/rad). Its Q falls as the grid refines
  (0.19, 0.135, 0.079 at levels 5, 6, 7): Q is ill-defined on a crease.
  Not done: an exact count like smooth_check.py (the grids reach 160,000 points; level 8 ran out of
  memory); a printed crease is rounded, and how much rounding the crease top can take is unchecked; the
  drop meshes (hulls of about 83,000 faces) are finer than the smooth bodies' (build.py), so the
  comparison is close but not like for like.

WHAT THIS ALL SHOWS (10 Nov 2026)
  1. One resting point is easy. A search from random shapes finds lopsided monostable convex bodies in
     minutes (the seven above); extra balancing points do no harm to a self-righting toy.
  2. One resting AND one balancing point, smooth, exists other than the gomboc (mono-g1: no mirror
     plane, rest and top 90 deg apart), but only within micrometres, with a ridge of near-equilibria.
     Strengthening the weakest lever 25 times lifted drops from 54% to 66%.
  3. A crease makes (1,1) easy. With three pieces both runs reached (1,1) directly, each with one
     crease carrying the balancing point; mono-e1 rights itself in 96% of drops.
  4. The weakest lever (Q) does not predict drops: mono-e1 has a weaker Q than mono-g3 and does far
     better. Where the weak region lies, and how deep the resting point is, matter more. For a printed
     toy, judge by drop tests.
  Best candidates to print: the low loaves (p1, s2-s4) and mono-e1.

PRE-SCREEN: A DROP METRIC THAT WORKS (11 Nov 2026)
  The weakest lever (Q) does not predict drops (point 4 above). prescreen.py predicts the share of drops
  that stall, from the convex hull alone, in about a second at build.py's resolution.
    python3 prescreen.py genomes/mono-s2.npy     level-7 body -> printed hulls -> stall   (about 17 s)
    python3 prescreen.py --hull hull.npy         a printed hull (mm at 36), as the printing chat's
  The model: from each of 10,242 landing directions the body rolls face to face toward the rest, gaining
  kinetic energy from height lost and paying rolling friction per radian turned; it stops on a face whose
  lever is below the friction once the energy is gone, and each dent whose basin it enters holds it with
  probability d^2 / (d^2 + (5 um)^2). The print model is the printing chat's spec (cut plane through the
  centre of mass, 0.2 mm first layer then 0.12 mm, 0.1 mm seam slip vertical or sideways); its hulls match
  the printing chat's to micrometres.
  Calibration, rank correlation with the share of drops that stall (mean error):
    PyBullet, 17 bodies (these, GOMBOC900, failed search runs) x 3 frictions, 30 s drops   0.85 (6.8 points)
    the printing chat's drops of its printed hulls, aligned and slipped, 26 cases           0.84 (7.5 points)
  Two lessons on the way:
    * 6 s drops mix true stalls with slow settling on the round bodies (s6, s7 above); 30 s drops do not.
    * An earlier form charged a dent only when the route crossed its lowest face. A variety map found that
      hole at once: bodies scoring 0.2% that stall in 63% and 53% of PyBullet drops (now 71% and 50%).
      Any metric used by a search will be gamed; drop-test the winners.
  Known misses: GOMBOC900's stalls at 16-22 deg in PyBullet (dynamic), mono-s4's vertical slip (13%
  observed, no static trap). A flat zone whose dents are a few micrometres deep can go from 0 to 70% with
  micrometre build changes (mono-s5 aligned: 0% in our hull, 71% in the printing chat's); test such bodies
  with small random surface bumps as well.

VARIETY MAP (11 Nov 2026)
  python3 variety_map.py b 7000 1    (2 hours, 2 cores; 10,784 bodies)
  Cells: rest height x middle/longest extent, 8 x 8; score: the worst predicted stall over aligned and the
  four seam slips at friction 0.15 and 0.3 mm. Seeds: mono-p1, s2-s7 and 57 random genomes.
  Result: 37 cells filled, but nothing beat the seeds. The best three cells are mono-s6 (1.2%), mono-s7
  (3.9%) and mono-s2 (5.0%), unchanged; every other cell is above 20%. On printed hulls with slips and
  surface bumps the three predict 0.2-1.1% (the printing chat's drops: 0-2%). Small random changes to a
  monostable body nearly always add a resting point, so mutation alone cannot leave these few shapes;
  improving them needs a search that keeps one resting point (as search.py does) with this metric as its
  second stage.

NOT DONE (none of these is ready to print)
  * Faceting: the 10,242 planes leave facets up to ~7 mm across at 90 mm and
    micro resting faces under 2 um deep; a finer icosphere would remove them.
  * The creases: a printed edge is slightly rounded. No resting or balancing
    point lies on a crease, but how much rounding each can take is unchecked.
  * Printing: cut, layers and seam slip are modelled (prescreen.py); tips and stringing are not.
