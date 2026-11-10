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

NOT DONE (none of these is ready to print)
  * Faceting: the 10,242 planes leave facets up to ~7 mm across at 90 mm and
    micro resting faces under 2 um deep; a finer icosphere would remove them.
  * The creases: a printed edge is slightly rounded. No resting or balancing
    point lies on a crease, but how much rounding each can take is unchecked.
  * Printing: no cut, layer, seam or tip checks yet.
