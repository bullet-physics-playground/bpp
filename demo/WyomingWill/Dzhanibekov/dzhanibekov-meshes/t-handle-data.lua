-- T-handle with wing-nut proportions, solid aluminium (2.7 g/cm^3): a bar
-- (radius 0.5 cm, 10 cm long) along body x, and a short, thick stem (radius
-- 0.8 cm, 4 cm long) along body -y from the middle of the bar. cm, kg.
-- Body frame = principal axes, origin at the centre of mass (1.265 cm
-- below the bar's axis).
--   y (along the stem)   : middle moment   -> unstable spin, flips
--   x (along the bar)    : smallest moment -> stable spin
--   z (across both)      : largest moment  -> stable spin
-- (Proportions matter: with a long stem -- 7 cm -- the stem becomes the
-- smallest moment and the bar the middle one.)
return {
  mass = 0.042920,
  inertia = { 0.102132, 0.184989, 0.277521 },   -- kg cm^2 about x, y, z
}
