-- A 26-vertex polyhedron with one stable face and one unstable vertex: a
-- Conway (5,5)-spiral (Domokos & Kovacs 2023): an apex above 5 horizontal
-- regular 5-gons, 26 faces.
-- AN IDEALISED DESIGN, NOT A BUILDABLE OBJECT (corrected 19 Oct 2026; this
-- header used to call it "a REAL object, not an idealisation"). The mass
-- model is a 0.5 mm polycarbonate shell (1.2 g/cm^3) over the faces plus a
-- 5.2 g weight per corner, treated as a POINT 3 mm inside the corner (towards
-- the mean of the corners; its own inertia taken as an 8 mm ball's). The
-- mass, centre of mass and inertia below are exact for that model, and the
-- simulation uses them as they are. Real 5.2 g tungsten weights (an 8.0 mm
-- ball or a 6.5 mm cube) cannot be placed like that at 9 cm: a centre 3 mm
-- in is only 1.1-2.5 mm from the face planes, so the weight would stick out
-- through the shell; and in the bottom three rings the weight centres are
-- 3.8-4.1 mm from the next ring's (corners 4.4-4.6 mm apart), so neighbouring
-- weights would overlap (15 pairs closer than 8 mm). Checked with
-- ../reconstruction/w37/fitcheck.py (runs/fitcheck.log).
-- Ring radii and heights fitted for the idealised model (../../Gomboc/
-- variety-reconstruction/optshell.py): every other face tips it by at least
-- 1.43 mm and every other corner by at least as much on the fit's own
-- measure (9 cm tall); measured as the distance the centre of mass would have
-- to move, the nearest other corner is 0.71 mm away. Build errors in the same
-- idealised model (robust2.py): with accurate flat panels, ring sizes/heights
-- and weight positions off by 0.2 / 0.5 / 1.0 mm and weights scattered 3% in
-- mass, it still has exactly one of each in 75% / 27% / 5% of 300 trials.
-- A weighted spiral that CAN be built (37 corners, 200 mm, tungsten cylinders
-- in a PLA print; designed and simulated, not yet printed): ../print/w37/.
-- Stable: the bottom 5-gon. Unstable: the apex.
-- Units cm, kg. Body frame: z up through the apex, origin at the centre of mass.
return {
  size = 9.00, mass = 0.141669, margin = 0.04, n = 5, k = 5,
  inertia = { 5.000325, 5.000325, 3.357822 },   -- squared radii of gyration, cm^2
  down = { 0, 0, -1 }, top = { 0.000000, -0.000000, 7.606402 },
  restHeight = 1.39360, topHeight = 7.60640,
  vertices = {
    0.00000,-0.00000,7.60640,
    2.98152,-0.00000,1.54577,
    0.92134,2.83560,1.54577,
    -2.41210,1.75250,1.54577,
    -2.41210,-1.75250,1.54577,
    0.92134,-2.83560,1.54577,
    2.51865,-0.00000,-0.27373,
    0.77831,2.39538,-0.27373,
    -2.03763,1.48043,-0.27373,
    -2.03763,-1.48043,-0.27373,
    0.77831,-2.39538,-0.27373,
    1.84069,-0.00000,-0.97817,
    0.56880,1.75060,-0.97817,
    -1.48915,1.08193,-0.97817,
    -1.48915,-1.08193,-0.97817,
    0.56880,-1.75060,-0.97817,
    1.45377,-0.00000,-1.23071,
    0.44924,1.38262,-1.23071,
    -1.17613,0.85451,-1.23071,
    -1.17613,-0.85451,-1.23071,
    0.44924,-1.38262,-1.23071,
    1.04506,-0.00000,-1.39360,
    0.32294,0.99391,-1.39360,
    -0.84547,0.61427,-1.39360,
    -0.84547,-0.61427,-1.39360,
    0.32294,-0.99391,-1.39360,
  },
  -- faces: outward normal, centre-of-mass height above it (cm), band, the band it tips onto
  faces = {
    { n = { 0.000000, -0.000000, -1.000000 }, h = 1.39360, name = "base", next = nil },
    { n = { 0.357519, -0.259752, -0.897056 }, h = 1.62377, name = "S1", next = "base" },
    { n = { 0.357519, 0.259752, -0.897056 }, h = 1.62377, name = "S1", next = "base" },
    { n = { -0.136558, 0.420285, -0.897058 }, h = 1.62377, name = "S1", next = "base" },
    { n = { -0.136557, -0.420280, -0.897060 }, h = 1.62376, name = "S1", next = "base" },
    { n = { -0.441910, 0.000000, -0.897059 }, h = 1.62376, name = "S1", next = "base" },
    { n = { 0.507989, 0.369077, -0.778286 }, h = 1.69635, name = "S2", next = "S1" },
    { n = { 0.507989, -0.369077, -0.778286 }, h = 1.69635, name = "S2", next = "S1" },
    { n = { -0.194036, 0.597180, -0.778284 }, h = 1.69635, name = "S2", next = "S1" },
    { n = { -0.194036, -0.597180, -0.778284 }, h = 1.69635, name = "S2", next = "S1" },
    { n = { -0.627910, -0.000000, -0.778286 }, h = 1.69635, name = "S2", next = "S1" },
    { n = { 0.638344, -0.463782, -0.614348 }, h = 1.77593, name = "S3", next = "S2" },
    { n = { 0.638344, 0.463782, -0.614348 }, h = 1.77593, name = "S3", next = "S2" },
    { n = { -0.243825, 0.750415, -0.614351 }, h = 1.77593, name = "S3", next = "S2" },
    { n = { -0.243825, -0.750415, -0.614351 }, h = 1.77593, name = "S3", next = "S2" },
    { n = { -0.789036, 0.000000, -0.614347 }, h = 1.77593, name = "S3", next = "S2" },
    { n = { 0.792410, -0.575718, -0.201583 }, h = 2.05098, name = "S4", next = "S3" },
    { n = { 0.792410, 0.575718, -0.201583 }, h = 2.05098, name = "S4", next = "S3" },
    { n = { -0.302673, 0.931532, -0.201585 }, h = 2.05098, name = "S4", next = "S3" },
    { n = { -0.302673, -0.931532, -0.201585 }, h = 2.05098, name = "S4", next = "S3" },
    { n = { -0.979471, -0.000000, -0.201584 }, h = 2.05098, name = "S4", next = "S3" },
    { n = { 0.751672, -0.546121, 0.369784 }, h = 2.81273, name = "S5", next = "S4" },
    { n = { -0.287113, 0.883643, 0.369785 }, h = 2.81273, name = "S5", next = "S4" },
    { n = { 0.751672, 0.546121, 0.369784 }, h = 2.81273, name = "S5", next = "S4" },
    { n = { -0.929118, -0.000000, 0.369784 }, h = 2.81273, name = "S5", next = "S4" },
    { n = { -0.287113, -0.883643, 0.369785 }, h = 2.81273, name = "S5", next = "S4" },
  },
}
