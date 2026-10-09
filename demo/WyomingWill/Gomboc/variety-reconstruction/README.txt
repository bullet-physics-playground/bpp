How the new shapes in gomboc-meshes/ were made (Python 3, numpy, scipy)

Sloan beta shapes (beta1-06, beta1-07, beta1-08, beta2-04)
  shapes.py   the two radius formulas, icospheres, exact mass properties
  gen.py      writes <name>.obj (display) and <name>.lua (hull points, mass,
              inertia, rest normal, balancing point); 9 cm, principal axes
  basins.py   counts the resting basins of a hull: rolling over each edge,
              persistence of the lowest faces. Gomboc-C's hull: 1 basin.
  scanb.py    scans beta: the hull keeps ONE basin up to form 1 beta ~0.08-0.09
              and form 2 beta ~0.04; beyond that (dimples) a second one appears
  lever.py    where rolling resistance can hold a shape (tipping lever below
              the rolling-resistance lever arm)
  hulleq.py   older facet check (local barriers only)
  Note: MathWorld gives form 2's balancing point as phi = 0; the radius is in
  fact largest at phi = pi/2, theta = 0 (opposite the resting point).

21-vertex polyhedron (p21)
  Domokos & Kovacs (arXiv:2103.13727), Table 1 line 3, gives the Conway
  (4,5)-spiral's angles 66.173, 44.519, 29.875, 19.716 (+19.716) deg but no
  coordinates. Built exactly from those angles, the vertices' centre of mass
  is at z = -0.0364, not the listed -0.0154, and the hull has 11 resting faces
  (vertices on the spiral) or 6 balancing points (spiral through the pentagon
  edge midpoints) -- so the reading of the paper is incomplete.
  opt21.py    keeps the structure (apex + 4 regular pentagons, equal masses)
              and re-fits the 4 ring radii and heights to maximise the margins
              of the one stable face and one unstable vertex. Result (best21.npy)
              is within ~0.02 of the paper's spiral; margins 0.6 mm at 9 cm;
              still 1 + 1 with 1 mm random vertex errors (100% at 0.1 mm).
  eq.py       exact equilibrium count of a polyhedron with point masses
  gen21.py    tungsten balls + carbon rods, mass properties, display mesh
