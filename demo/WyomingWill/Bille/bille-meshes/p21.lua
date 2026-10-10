-- A 21-vertex polyhedron with one stable and one unstable equilibrium,
-- after Domokos & Kovacs, "Conway's spiral and a discrete Gomboc with 21 point
-- masses" (Amer. Math. Monthly 130, 2023; arXiv:2103.13727): a Conway (4,5)-spiral
-- -- one apex and four horizontal regular pentagons, 21 faces -- with equal
-- masses at its 21 corners. RECONSTRUCTED: the paper gives the spiral's angles
-- but not the vertices, and its listed centre-of-mass height does not follow
-- from them, so the ring radii and heights were re-fitted (close to the paper's
-- spiral) to make the margins as large as possible: every other face tips the
-- body by at least 0.83 mm, every other vertex by at least 0.83 mm (at 9 cm).
-- Drawn as a closed polyhedron, but the physics is the paper's idealisation:
-- ALL the mass in the 21 corners (5.2 g each), a weightless skin. Building a
-- real one is much harder than the drawing suggests: with a 0.3 mm plastic
-- skin and 5-10 g weights centred 2 mm inside the corners, even the best
-- re-fitted shape has extra resting faces; 20 g a corner (420 g in all) just
-- scrapes by, 0.05 mm to spare (variety-reconstruction/opt21s.py, try_s.py).
-- Stable: the bottom pentagon. Unstable: the apex.
-- Units cm, kg. Body frame: z up through the apex, origin at the centre of mass.
return {
  size = 9.00, mass = 0.109200, margin = 0.04,
  inertia = { 5.384468, 5.384468, 3.077990 },   -- squared radii of gyration, cm^2
  down = { 0, 0, -1 }, top = { 0.000000, -0.000000, 7.822055 },
  restHeight = 1.17795, topHeight = 7.82205,
  vertices = {
    0.00000,-0.00000,7.82205,
    2.69394,-0.00000,1.11899,
    0.83247,2.56209,1.11899,
    -2.17944,1.58346,1.11899,
    -2.17944,-1.58346,1.11899,
    0.83247,-2.56209,1.11899,
    1.98087,-0.00000,-0.48702,
    0.61212,1.88392,-0.48702,
    -1.60255,1.16432,-0.48702,
    -1.60255,-1.16432,-0.48702,
    0.61212,-1.88392,-0.48702,
    1.21393,-0.00000,-1.01843,
    0.37513,1.15452,-1.01843,
    -0.98209,0.71353,-1.01843,
    -0.98209,-0.71353,-1.01843,
    0.37513,-1.15452,-1.01843,
    0.52228,-0.00000,-1.17795,
    0.16139,0.49671,-1.17795,
    -0.42253,0.30699,-1.17795,
    -0.42253,-0.30699,-1.17795,
    0.16139,-0.49671,-1.17795,
  },
  -- faces: outward normal, centre-of-mass height above it (cm), band, the band it tips onto
  faces = {
    { n = { 0.000000, 0.000000, -1.000000 }, h = 1.17795, name = "base", next = nil },
    { n = { 0.221800, -0.161146, -0.961684 }, h = 1.24866, name = "S1", next = "base" },
    { n = { 0.221800, 0.161146, -0.961684 }, h = 1.24866, name = "S1", next = "base" },
    { n = { -0.084720, -0.260741, -0.961684 }, h = 1.24866, name = "S1", next = "base" },
    { n = { -0.084720, 0.260741, -0.961684 }, h = 1.24866, name = "S1", next = "base" },
    { n = { -0.274158, 0.000000, -0.961685 }, h = 1.24866, name = "S1", next = "base" },
    { n = { -0.201018, -0.618661, -0.759507 }, h = 1.41236, name = "S2", next = "S1" },
    { n = { 0.526265, -0.382355, -0.759506 }, h = 1.41236, name = "S2", next = "S1" },
    { n = { 0.526265, 0.382355, -0.759506 }, h = 1.41236, name = "S2", next = "S1" },
    { n = { -0.201018, 0.618661, -0.759507 }, h = 1.41236, name = "S2", next = "S1" },
    { n = { -0.650500, -0.000000, -0.759506 }, h = 1.41235, name = "S2", next = "S1" },
    { n = { 0.761386, -0.553180, -0.338056 }, h = 1.67285, name = "S3", next = "S2" },
    { n = { 0.761386, 0.553180, -0.338056 }, h = 1.67285, name = "S3", next = "S2" },
    { n = { -0.290827, -0.895061, -0.338062 }, h = 1.67284, name = "S3", next = "S2" },
    { n = { -0.290827, 0.895061, -0.338062 }, h = 1.67284, name = "S3", next = "S2" },
    { n = { -0.941125, -0.000000, -0.338059 }, h = 1.67284, name = "S3", next = "S2" },
    { n = { 0.769370, -0.558981, 0.309208 }, h = 2.41864, name = "S4", next = "S3" },
    { n = { -0.293874, 0.904449, 0.309208 }, h = 2.41864, name = "S4", next = "S3" },
    { n = { 0.769370, 0.558981, 0.309208 }, h = 2.41864, name = "S4", next = "S3" },
    { n = { -0.950995, -0.000000, 0.309207 }, h = 2.41864, name = "S4", next = "S3" },
    { n = { -0.293874, -0.904449, 0.309208 }, h = 2.41864, name = "S4", next = "S3" },
  },
}
