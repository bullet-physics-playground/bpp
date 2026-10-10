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
