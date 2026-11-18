s1: F2 smoothly reshaped for slope tolerance (shape chat, 17 Nov 2026). For the printing chat's BPP calibration drops.

s1.obj   convex, watertight, 9137 vertices; same units and frame as gomboc_F2.obj (mm, extents 90.3 x 80.3 x 71.0,
         centre of mass at the origin, upright = +Y, long axis x, cut plane x = 0); i.e. the gomboc.obj frame.
         Largest change from F2: 0.73 mm at 90 mm.
s1-genome.npy  45 numbers: F2's vertices scaled radially from the centre of mass by exp(sum c_k Y_k), real spherical
         harmonics of degree 2..6 (gsearch.body). gsearch.py as run (CMA-ES, 25 min, then 2 h at degree 8 that found
         nothing better); paths point at the shape chat's working folders.

Design: 1 resting point at 2 um; balancing points 1 deeper than 20 um, 4 deeper than 2 um (the relaxed threshold).
Objective used (now known to be a poor proxy): the uniform share of directions beyond 25 deg with support-point lever
< 0.05 + h tan 1.5 deg, worst of aligned and 0.1 mm vertical slip; F2 2.9-3.1% -> s1 2.2-2.5% on printed hulls; the
face-based share 9.4-10.3% -> 4.8-5.7%. Its upright-margin constraint (>= 2.07 mm on the 20 deg ring) used the
support-point lever, which on the bottom line contact is an artefact (true arm ~0.2 mm): disregard it.
PyBullet, 1.5 deg tilt, mu 0.05 mm, 200 random drops each, 30 s: F2 104 upright (<35 deg), s1 91; the rest stopped flat
on facets whose face lever (0.16-0.34 mm) was under the 0.43 mm slope threshold, many near 138 deg.
gradlev.py  gradient lever |grad h| vs support-point lever on printed hulls: the same shares (the weak arm lives
only on line / face contacts, which a uniform sample never hits).
