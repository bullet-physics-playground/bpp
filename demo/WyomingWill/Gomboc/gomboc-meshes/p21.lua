-- A 21-vertex polyhedron with one stable and one unstable equilibrium,
-- after Domokos & Kovacs, "Conway's spiral and a discrete Gomboc with 21 point
-- masses" (Amer. Math. Monthly 130, 2023; arXiv:2103.13727): a Conway (4,5)-spiral
-- -- one apex and four horizontal regular pentagons -- with equal masses at its
-- 21 vertices. RECONSTRUCTED: the paper gives the spiral's angles
-- but not the vertices, and its listed centre-of-mass height does not follow from
-- them, so the ring radii and heights were re-fitted (close to the paper's spiral)
-- to make the margins as large as possible: every other face tips the body by at
-- least 0.60 mm, every other vertex by at least 0.60 mm (at this size).
-- Built as 21 tungsten balls (r 4.0 mm) on 1 mm carbon rods; the rods are
-- included in the mass. Stable: the bottom pentagon. Unstable: the apex.
-- Units cm, kg. Body frame: z up through the apex, origin at the centre of mass.
return {
  size = 9.00, mass = 0.109773, ballRadius = 0.400, rodRadius = 0.050,
  inertia = { 5.989837, 5.989837, 3.752567 },   -- squared radii of gyration, cm^2
  down = { 0, 0, -1 }, top = { 0.000000, -0.000000, 7.675573 },
  restHeight = 1.32443, topHeight = 7.67557,
  vertices = {
    0.00000,-0.00000,7.67557,
    2.91163,-0.00000,1.35473,
    0.89974,2.76912,1.35473,
    -2.35556,1.71141,1.35473,
    -2.35556,-1.71141,1.35473,
    0.89974,-2.76912,1.35473,
    2.21343,-0.00000,-0.49748,
    0.68399,2.10509,-0.49748,
    -1.79070,1.30102,-0.49748,
    -1.79070,-1.30102,-0.49748,
    0.68399,-2.10509,-0.49748,
    1.29865,-0.00000,-1.13860,
    0.40131,1.23509,-1.13860,
    -1.05063,0.76333,-1.13860,
    -1.05063,-0.76333,-1.13860,
    0.40131,-1.23509,-1.13860,
    0.65500,-0.00000,-1.32443,
    0.20241,0.62295,-1.32443,
    -0.52991,0.38500,-1.32443,
    -0.52991,-0.38500,-1.32443,
    0.20241,-0.62295,-1.32443,
  },
  edges = {
    1,2,
    1,3,
    1,4,
    1,5,
    1,6,
    2,3,
    2,6,
    2,7,
    3,4,
    3,8,
    4,5,
    4,9,
    5,6,
    5,10,
    6,11,
    7,8,
    7,11,
    7,12,
    8,9,
    8,13,
    9,10,
    9,14,
    10,11,
    10,15,
    11,16,
    12,13,
    12,16,
    12,17,
    13,14,
    13,18,
    14,15,
    14,19,
    15,16,
    15,20,
    16,21,
    17,18,
    17,21,
    18,19,
    19,20,
    20,21,
  },
}
