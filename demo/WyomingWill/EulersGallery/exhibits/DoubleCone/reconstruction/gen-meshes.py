"""Meshes for double-cone.lua. Run from this folder: python3 gen-meshes.py

The double cone: two cones base to base, its axis along z, its centre at
the origin (radius R at the middle, each cone H long). The cylinder: radius
RC, length LC, along z. Each drawn as its body and painted stripes (lines
from end to end, so the turning shows). Every face is written both ways
round."""
import math

OUT = "../double-cone-meshes/"
R, H = 5.0, 12.0
RC, LC = 3.0, 26.0
NU = 96


def write(name, parts, note):
    with open(OUT + name, "w") as f:
        f.write("# " + note + "\n")
        o = 0
        for V, F in parts:
            for v in V:
                f.write("v %.4f %.4f %.4f\n" % v)
            for t in F:
                f.write("f %d %d %d\n" % (t[0] + 1 + o, t[1] + 1 + o, t[2] + 1 + o))
                f.write("f %d %d %d\n" % (t[0] + 1 + o, t[2] + 1 + o, t[1] + 1 + o))
            o += len(V)


def revolve(prof, a0=0.0, a1=2 * math.pi, nu=NU, lift=0.0):
    """prof: [(z, r), ...] about z; between angles a0 and a1"""
    full = abs(a1 - a0 - 2 * math.pi) < 1e-9
    cols = nu if full else nu + 1
    V, F = [], []
    n = len(prof)
    for i in range(cols):
        a = a0 + (a1 - a0) * i / nu
        for z, r in prof:
            V.append(((r + lift) * math.cos(a), (r + lift) * math.sin(a), z))
    for i in range(nu):
        i1 = (i + 1) % cols if full else i + 1
        for j in range(n - 1):
            p, q, s, t = i * n + j, i * n + j + 1, i1 * n + j, i1 * n + j + 1
            F.append((p, s, q)); F.append((q, s, t))
    return V, F


cone = [(-H, 0.0), (0.0, R), (H, 0.0)]
cone_fine = [(-H + 2 * H * k / 48, R * (1 - abs(-H + 2 * H * k / 48) / H)) for k in range(49)]
write("double-cone.obj", [revolve(cone)], f"double cone: radius {R} at the middle, {2*H} long, along z")
stripes = []
for k in range(4):
    a = math.pi / 2 * k
    stripes.append(revolve(cone_fine, a - 0.06, a + 0.06, 3, lift=0.03))
write("double-cone-stripes.obj", stripes, "four painted lines from end to end")
cyl = [(-LC / 2, 0.0), (-LC / 2, RC), (LC / 2, RC), (LC / 2, 0.0)]
write("cylinder.obj", [revolve(cyl)], f"cylinder: radius {RC}, {LC} long, along z")
cs = []
for k in range(4):
    a = math.pi / 2 * k
    cs.append(revolve([(-LC / 2, RC), (LC / 2, RC)], a - 0.06, a + 0.06, 3, lift=0.03))
write("cylinder-stripes.obj", cs, "four painted lines along the cylinder")
print("done")
