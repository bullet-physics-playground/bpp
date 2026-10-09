-- Bille, the monostable tetrahedron -- RECONSTRUCTED, not the published drawing.
-- Shape fitted to the published numbers (arXiv:2506.19244, Quanta 2025-06-25):
-- longest edge 500 mm, volume 668.624 cm^3, loading-zone volumes 1.4318 /
-- 0.5716 / 0.0199 / 0.0067 cm^3 (all matched exactly). Mass design: carbon
-- tubes OD 1 / ID 0.5 mm (1.36 g/cm^3) on the six edges + a tungsten-carbide
-- wedge (14.15 g/cm^3) along edge BC, cut by one plane; total 120.0 g.
-- Units: cm, kg. Body frame = principal axes, origin at the centre of mass.
-- Faces are named by the opposite vertex; it is stable only on face D.
-- Predicted falling pattern (quasi-static): B -> A -> D <- C.
return {
  mass = 0.120000,
  inertia = { 0.219124, 1.224880, 1.320906 },                 -- kg cm^2 about principal axes
  vertices = { A = { -28.555581, 10.571784, -0.801982 }, B = { 5.810426, 0.015191, 0.572192 }, C = { -7.389437, -3.274103, -0.458655 }, D = { 18.454920, 0.480223, -14.519605 } },
  normals  = { A = { 0.226847, -0.960621, 0.160461 }, B = { -0.340516, -0.539637, -0.769961 }, C = { 0.274222, 0.926328, 0.258298 }, D = { -0.060772, -0.068209, 0.995818 } },   -- outward
  height   = { A = 1.39530, B = 4.63620, C = 1.75522, D = 0.21565 },  -- COM above face, cm
  tubeRadius = 0.05,                      -- cm (real); the drawing uses 0.3
  comMargin = 0.0813, -- cm: how deep the COM sits in the face-D zone
}
