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
  gen21solid.py  writes p21.obj (closed polyhedron, flat faces) and p21.lua
              (equal point masses at the corners, weightless skin)
  gen21.py    the earlier skeleton version (tungsten balls on carbon rods)
  opt21s.py, try_s.py  could a REAL hollow one work? Re-fits the shape with a
              thin plastic skin and corner weights set inside the corners:
              0.3 mm skin + 5-10 g weights 2 mm in: no (extra resting faces);
              20 g weights 2 mm in: just (0.05 mm margin); 20 g right at the
              corners: yes (0.54 mm)

More corners, and real builds (p26, p37; see also gomboc-findings.pdf)
  table1.py   rebuilds every row of the paper's Table 1 from its angles: the
              listed z_C is not reproduced for any row (probably our misreading)
  optnk.py    fits any Conway (n,k)-spiral for the largest margin; 13, 16, 17,
              19 corners: no fit found; 21: 0.83 mm (4,5) and 0.62 (5,4);
              26: 2.78 mm; 37: 4.27 mm (9 cm tall). nk_*.npy = the fits.
              p21 now uses nk_4_5.npy.
  shellgrid.py  margins with a plastic skin and corner weights set inside
  optshell.py   refits (5,5) and (6,6) for 0.5 mm skin + 5.2 g weights 3 mm in
  genshell.py   writes p26/p37 (.obj, .lua) for that build
  robust2.py    build-error tolerance (accurate panels; rings, weights off)
