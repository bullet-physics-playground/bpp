"""Meshes for falling-slinky.lua. Run from this folder: python3 gen-meshes.py

  coil.obj   one coil of the Slinky, drawn as a flat ring of ribbon round
             the y axis (the Slinky's axis), its centre at the origin: the
             wire is a flat strip 2.4 mm wide (across) and 0.6 mm thick
             (along the axis), its middle 3.4 cm out
"""
import math

R = 3.4               # to the wire's middle
W, T = 0.24, 0.06     # the ribbon: width (radial), thickness (along y)
NU = 64

V, F = [], []
prof = [(R - W / 2, -T / 2), (R + W / 2, -T / 2), (R + W / 2, T / 2), (R - W / 2, T / 2)]
for i in range(NU):
    a = 2 * math.pi * i / NU
    for r, y in prof:
        V.append((r * math.cos(a), y, r * math.sin(a)))
n = len(prof)
for i in range(NU):
    for j in range(n):
        p, q = i * n + j, i * n + (j + 1) % n
        s, t = ((i + 1) % NU) * n + j, ((i + 1) % NU) * n + (j + 1) % n
        F.append((p, s, q)); F.append((q, s, t))
with open("../slinky-meshes/coil.obj", "w") as f:
    f.write("# one Slinky coil: a flat ring of ribbon round y, radius %.1f cm\n" % R)
    for v in V:
        f.write("v %.4f %.4f %.4f\n" % v)
    for a, b, c in F:      # (both sides)
        f.write("f %d %d %d\n" % (a + 1, b + 1, c + 1))
        f.write("f %d %d %d\n" % (a + 1, c + 1, b + 1))
print("done")
