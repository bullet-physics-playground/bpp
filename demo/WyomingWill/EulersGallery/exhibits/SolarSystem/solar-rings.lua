-- The giant planets' rings, made by make-rings.py: don't edit.
-- Radii in km (from memory: see make-rings.py); each band's meshes, orrery and vitrine.
return {
  Saturn = {
    { name = "D", r0 = 66900, r1 = 74510, col = "#6f6658", op = 0.06, faint = true, narrow = false, orrery = "rings-orrery-saturn-1.obj", vitrine = "rings-vitrine-saturn-1.obj" },
    { name = "C", r0 = 74658, r1 = 92000, col = "#8f8470", op = 0.35, faint = false, narrow = false, orrery = "rings-orrery-saturn-2.obj", vitrine = "rings-vitrine-saturn-2.obj" },
    { name = "B (inner)", r0 = 92000, r1 = 99000, col = "#cdbd98", op = 0.75, faint = false, narrow = false, orrery = "rings-orrery-saturn-3.obj", vitrine = "rings-vitrine-saturn-3.obj" },
    { name = "B", r0 = 99000, r1 = 117580, col = "#e6d9b6", op = 0.97, faint = false, narrow = false, orrery = "rings-orrery-saturn-4.obj", vitrine = "rings-vitrine-saturn-4.obj" },
    { name = "Cassini Division", r0 = 117580, r1 = 122170, col = "#5e5547", op = 0.18, faint = false, narrow = false, orrery = "rings-orrery-saturn-5.obj", vitrine = "rings-vitrine-saturn-5.obj" },
    { name = "A", r0 = 122170, r1 = 133423, col = "#cfc19c", op = 0.8, faint = false, narrow = false, orrery = "rings-orrery-saturn-6.obj", vitrine = "rings-vitrine-saturn-6.obj" },
    { name = "A (outer)", r0 = 133745, r1 = 136775, col = "#c4b691", op = 0.7, faint = false, narrow = false, orrery = "rings-orrery-saturn-7.obj", vitrine = "rings-vitrine-saturn-7.obj" },
    { name = "F", r0 = 140155, r1 = 140205, col = "#c9bfa6", op = 0.5, faint = false, narrow = true, orrery = "rings-orrery-saturn-8.obj", vitrine = "rings-vitrine-saturn-8.obj" },
  },
  Jupiter = {
    { name = "halo", r0 = 92000, r1 = 122500, col = "#6e5644", op = 0.04, faint = true, narrow = false, orrery = "rings-orrery-jupiter-1.obj", vitrine = "rings-vitrine-jupiter-1.obj" },
    { name = "main ring", r0 = 122500, r1 = 129000, col = "#7d6150", op = 0.1, faint = true, narrow = false, orrery = "rings-orrery-jupiter-2.obj", vitrine = "rings-vitrine-jupiter-2.obj" },
    { name = "Amalthea gossamer ring", r0 = 129000, r1 = 182000, col = "#6e5644", op = 0.03, faint = true, narrow = false, orrery = "rings-orrery-jupiter-3.obj", vitrine = "rings-vitrine-jupiter-3.obj" },
    { name = "Thebe gossamer ring", r0 = 182000, r1 = 226000, col = "#6e5644", op = 0.02, faint = true, narrow = false, orrery = "rings-orrery-jupiter-4.obj", vitrine = "rings-vitrine-jupiter-4.obj" },
  },
  Uranus = {
    { name = "zeta", r0 = 37850, r1 = 41350, col = "#3a3c40", op = 0.05, faint = true, narrow = false, orrery = "rings-orrery-uranus-1.obj", vitrine = "rings-vitrine-uranus-1.obj" },
    { name = "6", r0 = 41836.2, r1 = 41837.8, col = "#4a4b4e", op = 0.6, faint = true, narrow = true, orrery = "rings-orrery-uranus-2.obj", vitrine = "rings-vitrine-uranus-2.obj" },
    { name = "5", r0 = 42233, r1 = 42235, col = "#4a4b4e", op = 0.6, faint = true, narrow = true, orrery = "rings-orrery-uranus-3.obj", vitrine = "rings-vitrine-uranus-3.obj" },
    { name = "4", r0 = 42569.8, r1 = 42572.2, col = "#4a4b4e", op = 0.6, faint = true, narrow = true, orrery = "rings-orrery-uranus-4.obj", vitrine = "rings-vitrine-uranus-4.obj" },
    { name = "alpha", r0 = 44714.5, r1 = 44721.5, col = "#4a4b4e", op = 0.6, faint = true, narrow = true, orrery = "rings-orrery-uranus-5.obj", vitrine = "rings-vitrine-uranus-5.obj" },
    { name = "beta", r0 = 45657, r1 = 45665, col = "#4a4b4e", op = 0.6, faint = true, narrow = true, orrery = "rings-orrery-uranus-6.obj", vitrine = "rings-vitrine-uranus-6.obj" },
    { name = "eta", r0 = 47175.2, r1 = 47176.8, col = "#4a4b4e", op = 0.6, faint = true, narrow = true, orrery = "rings-orrery-uranus-7.obj", vitrine = "rings-vitrine-uranus-7.obj" },
    { name = "gamma", r0 = 47625.5, r1 = 47628.5, col = "#4a4b4e", op = 0.6, faint = true, narrow = true, orrery = "rings-orrery-uranus-8.obj", vitrine = "rings-vitrine-uranus-8.obj" },
    { name = "delta", r0 = 48297, r1 = 48303, col = "#4a4b4e", op = 0.6, faint = true, narrow = true, orrery = "rings-orrery-uranus-9.obj", vitrine = "rings-vitrine-uranus-9.obj" },
    { name = "lambda", r0 = 50022, r1 = 50024, col = "#4a4b4e", op = 0.5, faint = true, narrow = true, orrery = "rings-orrery-uranus-10.obj", vitrine = "rings-vitrine-uranus-10.obj" },
    { name = "epsilon", r0 = 51120, r1 = 51178, col = "#56575a", op = 0.75, faint = true, narrow = true, orrery = "rings-orrery-uranus-11.obj", vitrine = "rings-vitrine-uranus-11.obj" },
    { name = "nu", r0 = 66100, r1 = 69900, col = "#5a4a40", op = 0.03, faint = true, narrow = false, orrery = "rings-orrery-uranus-12.obj", vitrine = "rings-vitrine-uranus-12.obj" },
    { name = "mu", r0 = 86000, r1 = 103000, col = "#4a5a78", op = 0.02, faint = true, narrow = false, orrery = "rings-orrery-uranus-13.obj", vitrine = "rings-vitrine-uranus-13.obj" },
  },
  Neptune = {
    { name = "Galle", r0 = 40900, r1 = 42900, col = "#5c4a42", op = 0.05, faint = true, narrow = false, orrery = "rings-orrery-neptune-1.obj", vitrine = "rings-vitrine-neptune-1.obj" },
    { name = "Le Verrier", r0 = 53143.5, r1 = 53256.5, col = "#6a5a50", op = 0.45, faint = true, narrow = true, orrery = "rings-orrery-neptune-2.obj", vitrine = "rings-vitrine-neptune-2.obj" },
    { name = "Lassell", r0 = 53300, r1 = 57200, col = "#5c4a42", op = 0.04, faint = true, narrow = false, orrery = "rings-orrery-neptune-3.obj", vitrine = "rings-vitrine-neptune-3.obj" },
    { name = "Arago", r0 = 57150, r1 = 57250, col = "#6a5a50", op = 0.3, faint = true, narrow = true, orrery = "rings-orrery-neptune-4.obj", vitrine = "rings-vitrine-neptune-4.obj" },
    { name = "Adams", r0 = 62907, r1 = 62957, col = "#6a5a50", op = 0.4, faint = true, narrow = true, orrery = "rings-orrery-neptune-5.obj", vitrine = "rings-vitrine-neptune-5.obj" },
    { name = "Adams arcs", r0 = 62907, r1 = 62957, col = "#8a7868", op = 0.85, faint = true, narrow = true, orrery = "rings-orrery-neptune-6.obj", vitrine = "rings-vitrine-neptune-6.obj" },
  },
}
