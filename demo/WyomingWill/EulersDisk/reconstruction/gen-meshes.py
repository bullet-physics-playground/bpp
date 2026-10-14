"""Meshes for eulers-disk.lua. Run from this folder: python3 gen-meshes.py

The disc, its axis along y, centred at the origin: 7.6 cm across, 1.2 cm
thick, its edges sharp (it rolls on the edge of its bottom face); and
painted marks on its faces, so its turning shows.
Every face is written both ways round."""
import math

OUT = "../eulers-disk-meshes/"
A, W = 3.8, 1.2
AP = A - 0.4


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


def revolve_y(prof, a0=0.0, a1=2 * math.pi, nu=96):
    full = abs(a1 - a0 - 2 * math.pi) < 1e-9
    cols = nu if full else nu + 1
    V, F = [], []
    n = len(prof)
    for i in range(cols):
        a = a0 + (a1 - a0) * i / nu
        for r, y in prof:
            V.append((r * math.cos(a), y, r * math.sin(a)))
    for i in range(nu):
        i1 = (i + 1) % cols if full else i + 1
        for j in range(n - 1):
            p, q, s, t = i * n + j, i * n + j + 1, i1 * n + j, i1 * n + j + 1
            F.append((p, s, q)); F.append((q, s, t))
    return V, F


prof = [(0.0, -W / 2), (A, -W / 2), (A, W / 2), (0.0, W / 2)]
write("disc.obj", [revolve_y(prof)], "Euler's disk: 7.6 cm across, 1.2 thick, axis along y")
# the mark: a band from the middle to the rim on the top face, and a ring
mark = revolve_y([(0.3, W / 2 + 0.01), (AP, W / 2 + 0.01)], -0.18, 0.18, 6)
ring = revolve_y([(AP * 0.55, W / 2 + 0.012), (AP * 0.62, W / 2 + 0.012)])
mark2 = revolve_y([(0.3, -W / 2 - 0.01), (AP, -W / 2 - 0.01)], -0.18, 0.18, 6)
write("disc-mark.obj", [mark, ring, mark2], "painted marks on its faces")
print("done")
