How the new shapes in gomboc-meshes/ were made (Python 3, numpy, scipy)

Sloan beta shapes (in gomboc-meshes/: beta1-07 and beta1-08, form 1 at
beta 0.07 and 0.08; no others are kept -- form 2 is left out, see
gomboc-variety.lua)
  shapes.py   the two radius formulas, icospheres, exact mass properties
  gen.py      make(form, beta) writes <name>.obj (display) and <name>.lua
              (hull points, mass, inertia, rest normal, balancing point);
              9 cm, principal axes. Its __main__ makes a different, larger-beta
              set (form 1 at 0.12, 0.15; form 2 at 0.12, 0.17) into out/; the
              two kept were made with make(1, 0.07) and make(1, 0.08). In the
              kept .lua files `down` is the lowest face of the hull's one basin
              (from basins.py), not the formula's minimum that gen.py writes:
              4.6 deg apart for beta 0.07, 34.6 deg for 0.08.
  basins.py   counts the resting basins of a hull: rolling over each edge,
              persistence of the lowest faces. Gomboc-C's hull: 1 basin.
  scanb.py    scans beta: the hull keeps ONE basin up to form 1 beta ~0.08-0.09
              and form 2 beta ~0.04; beyond that (dimples) a second one appears.
              Rerun for form 1 (15 Oct 2026, 25000 surface points): the deepest
              extra basin is 5.9 um at 0.08 (the facets' own noise is ~5 um),
              11.9 at 0.085, 25.3 at 0.09, 43.0 at 0.095, 66.7 at 0.10. So the
              second basin first stands clear of the noise at 0.085.

Note on gomboc-findings.pdf (not edited): Section 4 says the Sloan shapes'
true resting orientation lies 4-5 deg from the formula's minimum. That holds
for beta 0.07 (4.6 deg) but not for beta 0.08 (34.6 deg, from the `down` and
`top` in the .lua files), and Section 5 of the same PDF says the balancing
point sits ~35 deg off the top on beta 0.08 at home. Its summary's "above
beta ~0.09" for the second basin is the rounded form of the scan above.
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

More corners, and shell + corner-weight models (p26, p37; see also gomboc-findings.pdf)
  table1.py   rebuilds every row of the paper's Table 1 from its angles: the
              listed z_C is not reproduced for any row (probably our misreading)
  optnk.py    fits any Conway (n,k)-spiral for the largest margin; 13, 16, 17,
              19 corners: no fit found; 21: 0.83 mm (4,5) and 0.62 (5,4);
              26: 2.78 mm; 37: 4.27 mm (9 cm tall). nk_*.npy = the fits.
              p21 now uses nk_4_5.npy.
  shellgrid.py  margins with a plastic skin and corner weights set inside
  optshell.py   refits (5,5) and (6,6) for 0.5 mm skin + 5.2 g weights 3 mm in
  genshell.py   writes p26/p37 (.obj, .lua) for that model
  CORRECTED 19 Oct 2026: that model is an idealisation, not a buildable object.
              The weights are points 3 mm inside the corners; real 5.2 g tungsten
              pieces (an 8 mm ball, a 6.5 mm cube) would stick out through the shell
              and overlap their neighbours near the base, at 9 cm. See
              ../../Bille/reconstruction/w37/fitcheck.py. A buildable weighted
              37-corner design (200 mm, tungsten cylinders in a PLA print) is in
              ../../Bille/print/w37/. gomboc-findings.pdf (Sections 1, 3 and 6) still
              says 37 corners "can be built" in this form; see its erratum page.
  robust2.py    build-error tolerance (accurate panels; rings, weights off)

Mass-distribution scale (gomboc-findings.pdf, Section 7)
  skel.py     fits the spiral family with the mass on the vertices, edges, faces
              or as a uniform solid; skel.log = results (only vertices work)
  frac.py     largest evenly spread share of the mass a corner-weighted design
              tolerates (21: 1.8% faces / 2.1% edges; 26: 9.7/13.3; 37: 17.9/24.7)
  freecom2.py free centre of mass (Bille-like): 10 and 13 corners work, but only
              with the centre of mass on the bottom face
