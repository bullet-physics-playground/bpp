How Gomboc-C's collision hull and render mesh (../gomboc-meshes/gomboc-hull.lua,
gomboc.obj) are made from the CAD model, and how they were checked.

THE CAD MODEL (not in the repository: its licence is not stated)
  GOMBOC900.STEP, from the GrabCAD page "Gömböc" Convex, homogeneous
  three-dimensional body, published by Istenes József on 5 December 2024:
  https://grabcad.com/library/gomboc-convex-homogeneous-three-dimensional-body-1
  (download the zip; a free GrabCAD login is needed; the zip holds
  GOMBOC900.STEP and a picture, 01.JPG). The STEP header says: STEP AP203,
  FILE_NAME 'GOMBOC900.STEP', 2013-12-12T09:11:28, author 'Kiss Attila',
  organisation 'e.v.', SolidWorks 2010. Lengths in mm; the body is 900 mm
  long. 29 faces: 16 B-spline, 7 planes, 4 cones, 3 cylinders (radius 360 mm).

NEEDS  Python 3 with numpy, scipy, gmsh (PyPI gmsh 4.15.2, whose OpenCASCADE
  reads the STEP and meshes it) and OCP (PyPI cadquery-ocp 8.0.1.1.0, for the
  mass properties):  pip install gmsh==4.15.2 cadquery-ocp==8.0.1.1.0

FILES
  gen_hull.py   makes the two files; also re-makes the files of before
                19 Oct 2026 and compares them with given copies
  statics.py    the hull's resting faces and, along the resting trough, where
                rolling resistance can hold it, against the smooth cylinder
  cadlever.py   the CAD body's own lever map: for every face point (1.5 mm
                mesh), edge and corner, gravity's lever when it is the contact
  holdmap.py    where rolling resistance can hold a hull, over every tilt,
                each hold checked against cadlever.py's map (genuine/false)

  python3 gen_hull.py GOMBOC900.STEP check-old OLD/gomboc-hull.lua OLD/gomboc.obj
  python3 gen_hull.py GOMBOC900.STEP build ../gomboc-meshes      (about 5 s)
  python3 statics.py ../gomboc-meshes/gomboc-hull.lua             (about 1 min)
  python3 cadlever.py GOMBOC900.STEP cadlever.npz                 (about 2.5 min)
  python3 holdmap.py cadlever.npz ../gomboc-meshes/gomboc-hull.lua (about 5 min)

THE FILES OF BEFORE 19 OCT 2026, REPRODUCED
  `check-old` re-makes them and they come out identical, text for text: all
  13,476 hull points of gomboc-hull.lua and all 54,821 v/f lines of
  gomboc.obj. The recipe was: gmsh with Mesh.MeshSizeMax = 12 (mm; 1.2 mm at
  9 cm), all other options default -> 18,275 nodes, 36,546 triangles (these
  are gomboc.obj, in gmsh's node and element order); the convex-hull vertices
  of the nodes (scipy/qhull: 15,194), moved to OpenCASCADE's centre of mass
  and written in metres (the body 0.9 m) to 6 decimals; the hull of those
  rounded points (13,476); turned to the exhibit's axes and scaled to 9 cm:
  x = -(CAD y), y = CAD x, z = CAD z. The centre of mass and inertia were
  OpenCASCADE's defaults (BRepGProp::VolumeProperties without a tolerance).

WHAT CHANGED (19 Oct 2026)
  1. Exact mass properties. OpenCASCADE's default integration is not
     converged on this solid. With a tolerance (1e-6 and 1e-9 agree):
     volume 268,763,417 mm^3, not 268,851,114 (-0.033%; a fine mesh,
     extrapolated, gives 268,762,800); centre of mass (884.478954,
     6750.000006, 1349.999994) mm, not (884.480906, 6750.019110,
     1350.018792): the model is symmetric under a half turn about the
     vertical line Y = 6750, Z = 1350 mm, so the old value was 0.027 mm (CAD)
     off that line, 2.7 microns at 9 cm; squared radii of gyration (cm^2 at
     9 cm, body x, y, z) 5.796654, 6.786643, 7.261962, not 5.7974, 6.7876,
     7.2609. Everything is now centred on the converged centre of mass.
     The resting normal is then exactly body -y: the bottom cylinder's axis
     lies straight above the centre of mass (with the old centre it was
     0.094 deg off).
  2. The trough. The gomboc rests and rocks on a cylinder (radius 360 mm,
     axis along body x, 114.710 mm above the centre of mass at CAD size;
     3.6 cm and 0.1147 cm at 9 cm), cut off by two planes 225 mm apart. On a
     cylinder, tilting about x, gravity's lever is exactly d sin(tilt),
     d = 0.1147 cm x size, so rolling resistance delta holds it out to
     asin(delta / d): 7.51 deg at 9 cm for 150 microns, 10.04 deg at 75%,
     6.00 deg at 125%. The 12 mm mesh's nodes inside this face are replaced
     by whole rulings (straight lines across the cylinder, end to end, each
     end on the trimming edges: exact points of the surface). A hull of
     rulings is a prism of long thin flat strips. Pivoting on a ruling that
     sits within half a spacing w of the true contact moves gravity's lever
     by up to w/2, so the hull holds a tilt at most about w/(2 d cos(tilt))
     beyond the smooth bound. The spacing is chosen for every lever arm
     delta up to 300 microns (the slider's top) and every size down to 75%:
       - near the bottom, w = 2 d cos(tilt) eps with eps = 0.75 deg
         (30 microns at 9 cm). Finer would hardly help: Bullet works in
         32-bit floats, and its search for the lowest point compares heights
         p.n of points 3.6 cm out with rounding errors of a few 1e-7 cm;
         rulings whose heights differ by less cannot be told apart, and on
         this cylinder that is a ruling 10-20 microns either side of the
         true contact, about the w/2 = 15 microns of this spacing. (eps = 0.5
         deg gave 16,476 points; 0.25 deg, 18,820);
       - further up, where no lever arm up to 300 microns at 75% can hold it
         at all (d sin(tilt) > 0.04 cm), half the spacing that would just
         allow a hold, but never coarser than the 12 mm mesh.
     The 12 mm mesh's nodes on the trimming edges get a partner on the other
     edge (188), so every point there is the end of a whole ruling. 1229
     rulings. All other faces keep the 12 mm mesh, as before. The points
     are the hull vertices of all that, written to 7 decimals (cm), then
     only those still hull vertices as 32-bit floats: 15,548 points.
  3. gomboc.obj: the same 12 mm mesh as before (the render mesh needs no
     more), moved to the converged centre of mass (up to 2.7 microns).
     Its first line stays one short line: Gomboc Variety writes scaled copies
     of the .obj to temporary files, and with a multi-line header bpp failed
     to load them.

CHECKS (statics.py and holdmap.py; delta = rolling-resistance lever arm)
  Resting faces (the centre-of-mass foot inside a face; points as 32-bit
  floats, coplanar triangles merged):
    before: 34, out to 16.29 deg, the deepest needing a 0.535 micron lift
            to leave (at 5.16 deg); one at 11.72 deg (0.057 micron) is where
            the 11.4-11.7 deg rests of 19 Oct 2026 were
    now:    32, all strips between neighbouring rulings, within 0.74 deg of
            upright, the deepest needing 0.0029 micron
  Furthest tilt about x at which the hull can be held (0.002 deg scan, out to
  60 deg), against the smooth cylinder's asin(delta / d):
                      smooth    before     now
    150 um,  75%      10.04     24.84     10.71
    150 um, 100%       7.51     21.16      8.22
    150 um, 125%       6.00     21.16      6.70
     75 um, 100%       3.75     21.16      4.42
    300 um,  75%      20.41     37.02     21.22
    300 um, 100%      15.16     30.47     15.92
    300 um, 125%      12.08     27.63     12.92
  (at most 0.84 deg beyond the smooth bound for every delta and size above).
  At delta 150 um the hull now holds continuously out to 9.25 / 6.74 / 5.22
  deg (75 / 100 / 125%), then in narrow bands (at most 0.09 deg wide) to the
  furthest tilt above. Before, it held only within 0.2-1.3 deg of upright
  continuously and then in some 57 narrow bands out to 21-25 deg, 5.3-5.6 deg
  of them in all beyond the smooth bound (e.g. 11.38-11.72 deg at 9 cm, the
  resting face at 11.72 deg).
  Every other tilt (holdmap.py, point contacts, 0.1 x 0.25 deg grid, delta
  150 um): the rest of the surface is the same 1.2 mm mesh as before, and it
  has the same false holds as before (cells, at 75 / 100 / 125%: 1440 / 883
  / 622 now, 1430 / 879 / 623 before), at three kinds of place:
    - 30-60 deg toward the body's ends (+-x), near 38 deg, on the two large
      B-spline faces under the ends: the CAD surface there is nearly level
      (its normal 0.9 deg from the radius, a lever of 0.6-0.7 mm at 9 cm,
      so it cannot be held), but the 1.2 mm facets bring the hull's lever
      under 150 microns in spots;
    - 60-90 deg, around four sharp corners of the CAD body (body
      (+-3.688, -0.951, +-2.348) cm): resting on a corner at 77.7 deg the
      CAD body's own lever is only 107 microns at 9 cm (80 at 75%, 134 at
      125%), so rolling resistance can genuinely hold it there; the facets
      around the corners widen that;
    - 120-180 deg, near the top: near the balancing point the CAD lever is
      small anyway (genuine holds), and the facets widen it.
  Making these go too needs facets of 0.2-0.5 mm over most of those faces:
  about 40,000 points, three times the cost. Not done.
  The CAD body itself: one stable and one unstable equilibrium (the four
  corners are not equilibria: the radius misses their normal cones by
  0.137 deg).

COST  Bullet's convex-hull support search is linear in the number of points:
  15,548 against 13,476 (+15%). User CPU, headless, on this 2-core 2.1 GHz
  machine: Gomboc Drop C (GC_SEED=2, re-drop off) frames 1800-2400, all six
  at rest: 36.0 s before, 40.5 s now (+12%). First 600 frames, seeds 1-3:
  Drop C 113.2 -> 116.5 s (+3%), Gomboc Variety 102.1 -> 128.1 s (+25%);
  the runs move differently, so these include different motion.

SIDE EFFECT  Before, a resting gomboc stopped on the nearest of the hull's
  facets whose foot lay inside it, and stayed there. With the trough this
  fine it keeps creeping toward upright (one at 9 cm: 0.06 deg/s near 6 deg,
  0.02 deg/s at 2-3 deg), though gravity's lever is under delta and a real
  one would stay put. That is numerical (the loss model cancels the turning
  speed before each step, but each step moves the body by the speed gravity
  adds within it; the contact solver adds to it); see report/dossiers/
  Gomboc.md.

VERSIONS used: Python 3.13.16, numpy 2.5.3, scipy 1.18.1 (qhull), gmsh
  4.15.2, cadquery-ocp 8.0.1.1.0. The old files' exact reproduction depends
  on gmsh's meshing and qhull; other versions may differ in the last digits.
