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

NOT DONE (none of these is ready to print)
  * Faceting: the 10,242 planes leave facets up to ~7 mm across at 90 mm and
    micro resting faces under 2 um deep; a finer icosphere would remove them.
  * The creases: a printed edge is slightly rounded. No resting or balancing
    point lies on a crease, but how much rounding each can take is unchecked.
  * Printing: no cut, layer, seam or tip checks yet.
