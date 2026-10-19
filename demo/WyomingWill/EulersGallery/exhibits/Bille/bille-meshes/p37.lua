-- A 37-vertex polyhedron with one stable face and one unstable vertex: a
-- Conway (6,6)-spiral (Domokos & Kovacs 2023): an apex above 6 horizontal
-- regular 6-gons, 37 faces.
-- AN IDEALISED DESIGN, NOT A BUILDABLE OBJECT (corrected 19 Oct 2026; this
-- header used to call it "a REAL object, not an idealisation"). The mass
-- model is a 0.5 mm polycarbonate shell (1.2 g/cm^3) over the faces plus a
-- 5.2 g weight per corner, treated as a POINT 3 mm inside the corner (towards
-- the mean of the corners; its own inertia taken as an 8 mm ball's). The
-- mass, centre of mass and inertia below are exact for that model, and the
-- simulation uses them as they are. Real 5.2 g tungsten weights (an 8.0 mm
-- ball or a 6.5 mm cube) cannot be placed like that at 9 cm: a centre 3 mm
-- in is only 1.5-2.5 mm from the face planes, so the weight would stick out
-- through the shell; and the corners of the three bottom rings are only
-- 2.8-3.8 mm apart (weight centres 2.5-3.5 mm), so neighbouring weights
-- would overlap (24 pairs closer than 8 mm). Checked with
-- ../reconstruction/w37/fitcheck.py (runs/fitcheck.log).
-- Ring radii and heights fitted for the idealised model (../../Gomboc/
-- variety-reconstruction/optshell.py): every other face tips it by at least
-- 3.36 mm and every other corner by at least as much on the fit's own
-- measure (9 cm tall); measured as the distance the centre of mass would have
-- to move, the nearest other corner is 2.4 mm away. Build errors in the same
-- idealised model (robust2.py): with accurate flat panels, ring sizes/heights
-- and weight positions off by 0.2 / 0.5 / 1.0 mm and weights scattered 3% in
-- mass, it still has exactly one of each in 100% / 98% / 67% of 300 trials.
-- A weighted 37-corner spiral that CAN be built (200 mm, 626 g, 37 tungsten
-- cylinders in a PLA print; designed and simulated, not yet printed):
-- ../print/w37/.
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
  -- faces: outward normal, centre-of-mass height above it (cm), band, the band it tips onto
  faces = {
    { n = { -0.000000, 0.000000, -1.000000 }, h = 1.45597, name = "base", next = nil },
    { n = { 0.044403, -0.025635, -0.998685 }, h = 1.49462, name = "S1", next = "base" },
    { n = { 0.044403, 0.025635, -0.998685 }, h = 1.49462, name = "S1", next = "base" },
    { n = { -0.044403, 0.025635, -0.998685 }, h = 1.49462, name = "S1", next = "base" },
    { n = { -0.044404, -0.025636, -0.998685 }, h = 1.49462, name = "S1", next = "base" },
    { n = { -0.000000, -0.051273, -0.998685 }, h = 1.49462, name = "S1", next = "base" },
    { n = { -0.000000, 0.051273, -0.998685 }, h = 1.49462, name = "S1", next = "base" },
    { n = { 0.113102, -0.065299, -0.991435 }, h = 1.56598, name = "S2", next = "S1" },
    { n = { -0.113102, -0.065299, -0.991435 }, h = 1.56598, name = "S2", next = "S1" },
    { n = { -0.113103, 0.065300, -0.991435 }, h = 1.56598, name = "S2", next = "S1" },
    { n = { 0.113103, 0.065300, -0.991435 }, h = 1.56598, name = "S2", next = "S1" },
    { n = { 0.000000, -0.130597, -0.991436 }, h = 1.56597, name = "S2", next = "S1" },
    { n = { 0.000000, 0.130597, -0.991436 }, h = 1.56597, name = "S2", next = "S1" },
    { n = { -0.483742, 0.279288, -0.829453 }, h = 1.92012, name = "S3", next = "S2" },
    { n = { 0.483742, 0.279289, -0.829452 }, h = 1.92012, name = "S3", next = "S2" },
    { n = { 0.483742, -0.279289, -0.829452 }, h = 1.92012, name = "S3", next = "S2" },
    { n = { -0.483742, -0.279289, -0.829452 }, h = 1.92012, name = "S3", next = "S2" },
    { n = { -0.000000, 0.558578, -0.829452 }, h = 1.92013, name = "S3", next = "S2" },
    { n = { -0.000000, -0.558578, -0.829452 }, h = 1.92013, name = "S3", next = "S2" },
    { n = { -0.752370, -0.434381, -0.495231 }, h = 2.30943, name = "S4", next = "S3" },
    { n = { 0.752370, -0.434381, -0.495231 }, h = 2.30943, name = "S4", next = "S3" },
    { n = { 0.752370, 0.434381, -0.495231 }, h = 2.30943, name = "S4", next = "S3" },
    { n = { -0.752370, 0.434381, -0.495231 }, h = 2.30943, name = "S4", next = "S3" },
    { n = { -0.000000, -0.868763, -0.495229 }, h = 2.30943, name = "S4", next = "S3" },
    { n = { -0.000000, 0.868763, -0.495229 }, h = 2.30943, name = "S4", next = "S3" },
    { n = { 0.864790, -0.499287, -0.053389 }, h = 2.78956, name = "S5", next = "S4" },
    { n = { 0.864790, 0.499287, -0.053389 }, h = 2.78956, name = "S5", next = "S4" },
    { n = { -0.864790, 0.499287, -0.053389 }, h = 2.78956, name = "S5", next = "S4" },
    { n = { -0.864790, -0.499287, -0.053389 }, h = 2.78956, name = "S5", next = "S4" },
    { n = { -0.000000, -0.998574, -0.053390 }, h = 2.78956, name = "S5", next = "S4" },
    { n = { -0.000000, 0.998574, -0.053390 }, h = 2.78956, name = "S5", next = "S4" },
    { n = { -0.743641, -0.429341, 0.512508 }, h = 3.86637, name = "S6", next = "S5" },
    { n = { 0.743641, -0.429341, 0.512508 }, h = 3.86637, name = "S6", next = "S5" },
    { n = { -0.000000, -0.858683, 0.512508 }, h = 3.86637, name = "S6", next = "S5" },
    { n = { 0.743641, 0.429341, 0.512508 }, h = 3.86637, name = "S6", next = "S5" },
    { n = { -0.743641, 0.429341, 0.512508 }, h = 3.86637, name = "S6", next = "S5" },
    { n = { -0.000000, 0.858683, 0.512508 }, h = 3.86637, name = "S6", next = "S5" },
  },
}
