-- The giant planets' rings, made by make-rings.py: don't edit.
-- Radii in km, tau and albedo from NASA's NSSDC ring fact sheets (fetched 2026-10-18; see make-rings.py);
-- op and col drawn from them by make-rings.py's rule; each band's meshes, orrery and vitrine.
return {
  Saturn = {
    { name = "D", r0 = 66900, r1 = 74510, tau = 1e-05, albedo = 0.12, col = "#757060", op = 0.030, faint = true, narrow = false, orrery = "rings-orrery-saturn-1.obj", vitrine = "rings-vitrine-saturn-1.obj", note = "albedo not on the sheet: taken as C's lowest" },
    { name = "C", r0 = 74658, r1 = 91975, tau = 0.2, albedo = 0.21, col = "#97907c", op = 0.181, faint = false, narrow = false, orrery = "rings-orrery-saturn-2.obj", vitrine = "rings-vitrine-saturn-2.obj" },
    { name = "B", r0 = 91975, r1 = 117507, tau = 1.45, albedo = 0.5, col = "#e1d6b8", op = 0.765, faint = false, narrow = false, orrery = "rings-orrery-saturn-3.obj", vitrine = "rings-vitrine-saturn-3.obj" },
    { name = "Cassini Division", r0 = 117507, r1 = 122340, tau = 0.05, albedo = 0.3, col = "#b2a992", op = 0.074, faint = false, narrow = false, orrery = "rings-orrery-saturn-4.obj", vitrine = "rings-vitrine-saturn-4.obj" },
    { name = "A", r0 = 122340, r1 = 133410, tau = 0.7, albedo = 0.5, col = "#e1d6b8", op = 0.503, faint = false, narrow = false, orrery = "rings-orrery-saturn-5.obj", vitrine = "rings-vitrine-saturn-5.obj" },
    { name = "A (outside the Encke gap)", r0 = 133735, r1 = 136780, tau = 0.7, albedo = 0.5, col = "#e1d6b8", op = 0.503, faint = false, narrow = false, orrery = "rings-orrery-saturn-6.obj", vitrine = "rings-vitrine-saturn-6.obj", note = "the Encke gap's width, 325 km, not on the sheet (it gives its inner edge, 133,410)" },
    { name = "F", r0 = 139826, r1 = 139876, tau = 0.1, albedo = 0.6, col = "#f4e8c8", op = 0.095, faint = false, narrow = true, orrery = "rings-orrery-saturn-7.obj", vitrine = "rings-vitrine-saturn-7.obj", note = "its width, 50 km, not on the sheet" },
  },
  Jupiter = {
    { name = "halo", r0 = 89400, r1 = 123000, tau = 3e-06, albedo = 0.015, col = "#261f1a", op = 0.024, faint = true, narrow = false, orrery = "rings-orrery-jupiter-1.obj", vitrine = "rings-vitrine-jupiter-1.obj", note = "albedo not on the sheet: taken as the main ring's" },
    { name = "main ring", r0 = 123000, r1 = 128940, tau = 5e-06, albedo = 0.015, col = "#261f1a", op = 0.026, faint = true, narrow = false, orrery = "rings-orrery-jupiter-2.obj", vitrine = "rings-vitrine-jupiter-2.obj" },
    { name = "Amalthea gossamer ring", r0 = 128940, r1 = 181350, tau = 1e-07, albedo = 0.015, col = "#261f1a", op = 0.006, faint = true, narrow = false, orrery = "rings-orrery-jupiter-3.obj", vitrine = "rings-vitrine-jupiter-3.obj", note = "albedo: as the main ring's" },
    { name = "Thebe gossamer ring", r0 = 181350, r1 = 221900, tau = 1e-07, albedo = 0.015, col = "#261f1a", op = 0.006, faint = true, narrow = false, orrery = "rings-orrery-jupiter-4.obj", vitrine = "rings-vitrine-jupiter-4.obj", note = "albedo: as the main ring's" },
    { name = "Thebe ring's extension", r0 = 221900, r1 = 280000, tau = 1e-07, albedo = 0.015, col = "#261f1a", op = 0.006, faint = true, narrow = false, orrery = "rings-orrery-jupiter-5.obj", vitrine = "rings-vitrine-jupiter-5.obj", note = "albedo: as the main ring's" },
  },
  Uranus = {
    { name = "zeta", r0 = 37850, r1 = 41350, tau = 1e-05, albedo = 0.015, col = "#282829", op = 0.030, faint = true, narrow = false, orrery = "rings-orrery-uranus-1.obj", vitrine = "rings-vitrine-uranus-1.obj", note = "NOT ON THE SHEETS (radii from memory; tau and albedo assumed)" },
    { name = "6", r0 = 41837, r1 = 41838.5, tau = 0.3, albedo = 0.015, col = "#282829", op = 0.259, faint = false, narrow = true, orrery = "rings-orrery-uranus-2.obj", vitrine = "rings-vitrine-uranus-2.obj" },
    { name = "5", r0 = 42234, r1 = 42236, tau = 0.5, albedo = 0.015, col = "#282829", op = 0.393, faint = false, narrow = true, orrery = "rings-orrery-uranus-3.obj", vitrine = "rings-vitrine-uranus-3.obj" },
    { name = "4", r0 = 42571, r1 = 42573, tau = 0.3, albedo = 0.015, col = "#282829", op = 0.259, faint = false, narrow = true, orrery = "rings-orrery-uranus-4.obj", vitrine = "rings-vitrine-uranus-4.obj" },
    { name = "alpha", r0 = 44718, r1 = 44725, tau = 0.4, albedo = 0.015, col = "#282829", op = 0.330, faint = false, narrow = true, orrery = "rings-orrery-uranus-5.obj", vitrine = "rings-vitrine-uranus-5.obj" },
    { name = "beta", r0 = 45661, r1 = 45669, tau = 0.3, albedo = 0.015, col = "#282829", op = 0.259, faint = false, narrow = true, orrery = "rings-orrery-uranus-6.obj", vitrine = "rings-vitrine-uranus-6.obj" },
    { name = "eta", r0 = 47176, r1 = 47177.6, tau = 0.4, albedo = 0.015, col = "#282829", op = 0.330, faint = false, narrow = true, orrery = "rings-orrery-uranus-7.obj", vitrine = "rings-vitrine-uranus-7.obj" },
    { name = "gamma", r0 = 47627, r1 = 47629.5, tau = 0.3, albedo = 0.015, col = "#282829", op = 0.259, faint = false, narrow = true, orrery = "rings-orrery-uranus-8.obj", vitrine = "rings-vitrine-uranus-8.obj" },
    { name = "delta", r0 = 48300, r1 = 48305, tau = 0.5, albedo = 0.015, col = "#282829", op = 0.393, faint = false, narrow = true, orrery = "rings-orrery-uranus-9.obj", vitrine = "rings-vitrine-uranus-9.obj" },
    { name = "lambda", r0 = 50024, r1 = 50026, tau = 0.1, albedo = 0.015, col = "#282829", op = 0.095, faint = false, narrow = true, orrery = "rings-orrery-uranus-10.obj", vitrine = "rings-vitrine-uranus-10.obj" },
    { name = "epsilon", r0 = 51149, r1 = 51207, tau = 1.4, albedo = 0.018, col = "#2c2c2d", op = 0.753, faint = false, narrow = true, orrery = "rings-orrery-uranus-11.obj", vitrine = "rings-vitrine-uranus-11.obj" },
    { name = "nu (R/2003 U 2)", r0 = 65400, r1 = 69200, tau = 1e-05, albedo = 0.015, col = "#282829", op = 0.030, faint = true, narrow = false, orrery = "rings-orrery-uranus-12.obj", vitrine = "rings-vitrine-uranus-12.obj", note = "tau '<<0.01' on the sheet: taken as 1e-5; albedo not on it" },
    { name = "mu (R/2003 U 1)", r0 = 89200, r1 = 106200, tau = 1e-05, albedo = 0.015, col = "#282829", op = 0.030, faint = true, narrow = false, orrery = "rings-orrery-uranus-13.obj", vitrine = "rings-vitrine-uranus-13.obj", note = "tau '<<0.01' on the sheet: taken as 1e-5; albedo not on it" },
  },
  Neptune = {
    { name = "Galle", r0 = 40900, r1 = 42900, tau = 0.0001, albedo = 0.015, col = "#28221e", op = 0.042, faint = true, narrow = false, orrery = "rings-orrery-neptune-1.obj", vitrine = "rings-vitrine-neptune-1.obj" },
    { name = "Le Verrier", r0 = 53200, r1 = 53300, tau = 0.01, albedo = 0.015, col = "#28221e", op = 0.066, faint = true, narrow = true, orrery = "rings-orrery-neptune-2.obj", vitrine = "rings-vitrine-neptune-2.obj" },
    { name = "Lassell", r0 = 53200, r1 = 57200, tau = 0.0001, albedo = 0.015, col = "#28221e", op = 0.042, faint = true, narrow = false, orrery = "rings-orrery-neptune-3.obj", vitrine = "rings-vitrine-neptune-3.obj" },
    { name = "Arago", r0 = 57200, r1 = 57300, tau = 0.0001, albedo = 0.015, col = "#28221e", op = 0.042, faint = true, narrow = true, orrery = "rings-orrery-neptune-4.obj", vitrine = "rings-vitrine-neptune-4.obj", note = "its tau not on the sheet (its column reads '<100', likely the width): taken as Lassell's" },
    { name = "Adams", r0 = 62933, r1 = 62948, tau = 0.05, albedo = 0.015, col = "#28221e", op = 0.074, faint = false, narrow = true, orrery = "rings-orrery-neptune-5.obj", vitrine = "rings-vitrine-neptune-5.obj" },
    { name = "Adams arcs", r0 = 62933, r1 = 62948, tau = 0.12, albedo = 0.04, col = "#3e362f", op = 0.113, faint = false, narrow = true, orrery = "rings-orrery-neptune-6.obj", vitrine = "rings-vitrine-neptune-6.obj", note = "their span (40 degrees) and place round the ring not on the sheet: an example" },
  },
}
