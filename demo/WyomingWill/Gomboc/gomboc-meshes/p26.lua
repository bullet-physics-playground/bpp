-- A 26-vertex polyhedron with one stable face and one unstable vertex: a
-- Conway (5,5)-spiral (Domokos & Kovacs 2023): an apex above 5 horizontal
-- regular 5-gons, 26 faces. Unlike the 21-vertex one, this is a REAL
-- object, not an idealisation: a 0.5 mm polycarbonate shell (1.2 g/cm^3) with
-- a 5.2 g tungsten weight in every corner, centred 3 mm inside it.
-- Ring radii and heights fitted for that build (variety-reconstruction/
-- optshell.py): every other face tips it by at least 1.43 mm, every other
-- corner by at least as much (9 cm tall). Build errors (variety-reconstruction/
-- robust2.py): with accurate flat panels, ring sizes/heights and weight
-- positions off by 0.2 / 0.5 / 1.0 mm and weights scattered 3% in mass, it
-- still has exactly one of each in 75% / 27% / 5% of 300 trials.
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
}
