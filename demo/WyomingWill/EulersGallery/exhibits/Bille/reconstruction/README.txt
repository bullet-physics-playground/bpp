BILLE, THE MONOSTABLE TETRAHEDRON -- RECONSTRUCTION NOTES

Sources: G. Almadi, R. Dawson, G. Domokos, 'Building a monostable tetrahedron', arXiv:2506.19244 (2025);
Quanta Magazine, 2025-06-25; Domokos, Almadi, Regos, Dawson, 'On Equilibria of Tetrahedra', Math. Intelligencer (2023).
The paper gives the node coordinates only as an image (Fig. 1c). Everything below is fitted/designed
from numbers published in text. It is NOT the authors' drawing; the mirror image fits equally well.

Published numbers used: longest edge 500 mm; volume 668.624 cm^3; loading-zone volumes (Table 1)
  B->A->D<-C 1.4318, C->D->A<-B 0.5716, B->A->D->C 0.0199, C->D->A->B 0.0067 cm^3;
  tubes OD 1 / ID 0.5 mm, 1.36 g/cm^3; tungsten carbide 14.15 g/cm^3; total mass 120 g; rests only on face D.

FITTED VERTICES (mm)
  A  (    0.000,     0.000,     0.000)
  B  (  340.649,     0.000,   115.730)
  C  (  226.010,   -69.329,    89.980)
  D  (  500.000,     0.000,     0.000)
  volume 668.6240 cm^3
  edges (mm): AB 359.77, AC 252.95, AD 500.00, BC 136.43, BD 196.94, CD 296.60
  dihedral angles (deg): AB 100.22, AC 44.83, AD 37.61, BC 102.21, BD 38.17, CD 108.52   (obtuse path A-B-C-D)
  loading-zone volumes reproduced (cm^3): 1.4318, 0.5716, 0.0199, 0.0067

MASS DESIGN
  frame: 6 tubes, 1.396 g
  tungsten-carbide wedge along edge BC, cut by the plane n.x = c with n = (-0.26036, 0.16713, 0.95094), c = 15.0377 mm
  wedge volume 8.382 cm^3, mass 118.60 g; wedge corners (mm):
     (  340.649,     0.000,   115.730)
     (  239.828,    -0.000,    81.478)
     (  347.297,     0.000,   110.902)
     (  226.010,   -69.329,    89.980)
     (  224.582,   -68.891,    89.411)
     (  226.190,   -69.284,    89.920)
  total 120.00 g; centre of mass (287.619, -17.552, 98.741) mm
  the centre of mass is 0.81 mm inside the face-D loading zone (the zone is at most 1.48 mm deep);
  on face A it lies 0.81 mm beyond the tipping edge BC. A 0.1 g glue blob at a far vertex moves it ~0.25 mm.

FILES
  tetra.py  falling-pattern rules (which face it tips onto from each face, for any centre of mass)
  zones.py  loading zones as exact polytopes;  fit.py  the shape fit;  mass.py  the wedge design

Spiral polyhedra (bille-meshes/p21, p26, p37)
  Moved here from ../Gomboc/gomboc-meshes: like Bille, they work because of
  where their mass is. Shapes and mass models were made by the scripts in
  ../Gomboc/variety-reconstruction (opt21.py/optnk.py, gen21solid.py,
  optshell.py, genshell.py). genbille.py adds the face list each .lua file
  now carries: outward normal, centre-of-mass height, band name (S1 next to
  the base ... apex band) and the band it tips onto quasi-statically. Every
  band tips onto the one below it: ... -> S2 -> S1 -> base.
  genframe.py writes pNN-frame.obj: the polyhedra drawn as frames (balls on
  rods) for the "polyhedra look" slider; same body frame, drawing only.
  CORRECTED 19 Oct 2026: p26 and p37 are IDEALISED designs, not real objects
  (their headers used to say "a REAL object, not an idealisation"). Their mass
  model is a 0.5 mm polycarbonate shell plus 5.2 g corner weights taken as
  points 3 mm inside the corners. A real 5.2 g tungsten weight (8.0 mm ball,
  6.5 mm cube) cannot be placed there at 9 cm: its centre would be only
  1.1-2.5 mm from the face planes, and neighbouring weights near the base
  would be 2.5-4.1 mm apart, so they would overlap (w37/fitcheck.py,
  w37/runs/fitcheck.log). Measured as the distance the centre of mass must
  move, the nearest corner margin is 0.71 mm (p26) and 2.41 mm (p37), against
  1.43 / 3.36 mm on the fit's own measure. The simulation is unchanged: it
  uses the mass properties of the idealised model as computed.

Weighted 37-corner print (w37/; print files in ../print/w37/)
  The buildable counterpart of p37: 37 tungsten pinewood-derby cylinders
  (3/8" x 0.44", 0.5 oz, 14.17 g) in pockets in a 0.8 mm PLA shell, 200 mm
  tall, 626 g, smallest margin 4.16 mm; 7 pauses during the print to insert
  the weights. Face-plane errors of 0.1 / 0.2 / 0.3 / 0.5 mm: 100 / 95 / 81 /
  27% of simulated builds keep one stable face. In bpp: 88/88 drops and 36/36
  set-downs ended on the base. Designed and simulated, not yet printed. See
  w37/README.md (scripts, logs, how to rerun) and ../print/w37/README.md.

PLA-only polyhedron (bille-meshes/ppla37.obj, ppla37-data.lua; print files in ../print/)
  The gallery's own design (not from a paper): an apex above 6 regular hexagons, 37 faces,
  15 cm tall, printed in PLA only. Solid PLA up to 23.65 mm above the base, one closed air
  void above it, 1.0 mm walls: 331 g, centre of mass 23.69 mm up. The fill level sits at the
  centre-of-mass height, which is where it puts the centre of mass lowest. One stable face
  (the base, foot 41.14 mm inside), one unstable vertex (the apex); smallest margin 12.35 mm
  (faces and corners). In Bille Drop it is drawn 40 cm tall (40/15; mass x (40/15)^3).
  Files in pla/:
    core.py, test_core.py   exact polytope mass properties, equilibria, margins
    opt2.py, opt3.py, opt4.py, sym.py   the shape/fill-level optimisation (opt3: any ring spec;
                            supportless = no surface overhanging more than 45 deg)
    scan_size.py            margin vs size and wall (runs/scan_size.log)
    robust.py               print-error trials (runs/robust_a66.log = this design,
                            runs/robust_size10.log = the 10 cm variant)
    apexsplit.py            how the apex splits under plane errors (runs/apexsplit.log)
    export.py               writes STL / OBJ / data.lua / cutaway / props (ppla37-props.txt)
    check3d.py              3D check of a design;  verify_stl.py  independent check from the STL
    ppla37-params.npy (= runs/a_6_6_t10.npy)  the design vector; runs/a_*_t10.npy.log  the
                            optimisation logs for (5,6), (6,6), (6,8), (7,6) ring stacks
    sim/                    pla-drop.lua (Bille Drop with only the body list changed, plus
                            PP_SCALE / PP_FACE), run_tests.sh and its logs. run_tests.sh expects
                            meshes/ppla-data.lua and meshes/ppla.obj = ppla37-data.lua / ppla37.obj.
  Scripts were run with python3 + numpy + scipy (+ trimesh in export.py) from the folder they
  are in; paths inside are relative (runs/...).
