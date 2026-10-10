"""The chain link mesh for chain-fountain.lua: python3 gen-link.py ../chain-fountain-meshes/link.obj 0.3 1.5"""
import math, sys
def capsule(path, r, L, n=12, m=4):
    """a capsule along x, from -L/2 to L/2 (its tips), radius r"""
    h = L / 2 - r
    V = []; F = []
    rings = []
    for side, x0 in ((-1, -h), (1, h)):
        for j in range(m + 1) if side < 0 else range(m, -1, -1):
            a = math.pi / 2 * j / m
            rings.append((x0 + side * r * math.cos(a), r * math.sin(a)))
    # rings ordered from -tip to +tip
    rings.sort(key=lambda t: t[0])
    for (x, rr) in rings:
        for i in range(n):
            p = 2 * math.pi * i / n
            V.append((x, rr * math.cos(p), rr * math.sin(p)))
    for k in range(len(rings) - 1):
        for i in range(n):
            a = k * n + i; b = k * n + (i + 1) % n
            F.append((a, b, a + n)); F.append((b, b + n, a + n))
    with open(path, "w") as f:
        f.write("# chain link: capsule along x, tips at -/+%g, radius %g\n" % (L / 2, r))
        for v in V: f.write("v %.4f %.4f %.4f\n" % v)
        for t in F: f.write("f %d %d %d\n" % (t[0] + 1, t[1] + 1, t[2] + 1))
capsule(sys.argv[1], float(sys.argv[2]), float(sys.argv[3]))
