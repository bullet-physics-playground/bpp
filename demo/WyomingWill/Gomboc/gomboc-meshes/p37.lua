-- A 37-vertex polyhedron with one stable face and one unstable vertex: a
-- Conway (6,6)-spiral (Domokos & Kovacs 2023): an apex above 6 horizontal
-- regular 6-gons, 37 faces. Unlike the 21-vertex one, this is a REAL
-- object, not an idealisation: a 0.5 mm polycarbonate shell (1.2 g/cm^3) with
-- a 5.2 g tungsten weight in every corner, centred 3 mm inside it.
-- Ring radii and heights fitted for that build (variety-reconstruction/
-- optshell.py): every other face tips it by at least 3.36 mm, every other
-- corner by at least as much (9 cm tall). Build errors (variety-reconstruction/
-- robust2.py): with accurate flat panels, ring sizes/heights and weight
-- positions off by 0.2 / 0.5 / 1.0 mm and weights scattered 3% in mass, it
-- still has exactly one of each in 100% / 98% / 67% of 300 trials.
-- Stable: the bottom 6-gon. Unstable: the apex.
-- Units cm, kg. Body frame: z up through the apex, origin at the centre of mass.
return {
  size = 9.00, mass = 0.201152, margin = 0.04, n = 6, k = 6,
  inertia = { 5.732577, 5.732577, 4.499773 },   -- squared radii of gyration, cm^2
  down = { 0, 0, -1 }, top = { -0.000000, -0.000000, 7.544027 },
  restHeight = 1.45597, topHeight = 7.54403,
  vertices = {
    -0.00000,-0.00000,7.54403,
    3.38796,-0.00000,2.62815,
    1.69398,2.93406,2.62815,
    -1.69398,2.93406,2.62815,
    -3.38796,0.00000,2.62815,
    -1.69398,-2.93406,2.62815,
    1.69398,-2.93406,2.62815,
    3.24187,-0.00000,0.26181,
    1.62093,2.80754,0.26181,
    -1.62093,2.80754,0.26181,
    -3.24187,0.00000,0.26181,
    -1.62093,-2.80754,0.26181,
    1.62093,-2.80754,0.26181,
    2.50892,-0.00000,-0.85171,
    1.25446,2.17279,-0.85171,
    -1.25446,2.17279,-0.85171,
    -2.50892,0.00000,-0.85171,
    -1.25446,-2.17279,-0.85171,
    1.25446,-2.17279,-0.85171,
    1.56764,-0.00000,-1.40067,
    0.78382,1.35762,-1.40067,
    -0.78382,1.35762,-1.40067,
    -1.56764,0.00000,-1.40067,
    -0.78382,-1.35762,-1.40067,
    0.78382,-1.35762,-1.40067,
    1.19097,-0.00000,-1.44364,
    0.59549,1.03141,-1.44364,
    -0.59549,1.03141,-1.44364,
    -1.19097,0.00000,-1.44364,
    -0.59549,-1.03141,-1.44364,
    0.59549,-1.03141,-1.44364,
    0.91365,-0.00000,-1.45597,
    0.45683,0.79125,-1.45597,
    -0.45683,0.79125,-1.45597,
    -0.91365,-0.00000,-1.45597,
    -0.45683,-0.79125,-1.45597,
    0.45683,-0.79125,-1.45597,
  },
}
