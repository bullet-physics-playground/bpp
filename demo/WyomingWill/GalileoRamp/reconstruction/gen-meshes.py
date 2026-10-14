"""Meshes for galileo-ramp.lua. Run from this folder: python3 gen-meshes.py

The disc, the hoop and the can, each along z, centred at the origin, and a
painted stripe for each racer (the balls' a band round them), so their
turning shows. Every face is written both ways round."""
import math

OUT = "../galileo-ramp-meshes/"
NU = 64


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


def revolve(prof, a0=0.0, a1=2 * math.pi, nu=NU, closed=False):
    """prof: [(z, r)] about z"""
    full = abs(a1 - a0 - 2 * math.pi) < 1e-9
    cols = nu if full else nu + 1
    V, F = [], []
    n = len(prof)
    for i in range(cols):
        a = a0 + (a1 - a0) * i / nu
        for z, r in prof:
            V.append((r * math.cos(a), r * math.sin(a), z))
    m = n if closed else n - 1
    for i in range(nu):
        i1 = (i + 1) % cols if full else i + 1
        for j in range(m):
            j1 = (j + 1) % n
            p, q, s, t = i * n + j, i * n + j1, i1 * n + j, i1 * n + j1
            F.append((p, s, q)); F.append((q, s, t))
    return V, F


def sphere_band(r, w=0.12):
    """a band round a sphere (radius r + a hair), in the plane x = 0... as a revolve about x"""
    V, F = [], []
    nu, nv = 64, 3
    for i in range(nu):
        a = 2 * math.pi * i / nu
        for j in range(nv):
            b = -w + 2 * w * j / (nv - 1)
            rr = r * 1.01
            V.append((rr * math.sin(b), rr * math.cos(b) * math.cos(a), rr * math.cos(b) * math.sin(a)))
    for i in range(nu):
        i1 = (i + 1) % nu
        for j in range(nv - 1):
            p, q, s, t = i * nv + j, i * nv + j + 1, i1 * nv + j, i1 * nv + j + 1
            F.append((p, s, q)); F.append((q, s, t))
    return V, F


R, W = 2.5, 2.0
write("disc.obj", [revolve([(-W / 2, 0), (-W / 2, R), (W / 2, R), (W / 2, 0)])], "wooden disc, radius 2.5, 2 thick, along z")
write("disc-stripe.obj", [revolve([(W / 2 + 0.01, 0.0), (W / 2 + 0.01, R * 0.95)], -0.12, 0.12, 4),
                          revolve([(-W / 2 - 0.01, 0.0), (-W / 2 - 0.01, R * 0.95)], -0.12, 0.12, 4)], "a radius painted on each face")
HW, T = 1.5, 0.3
write("hoop.obj", [revolve([(-HW / 2, R - T), (-HW / 2, R), (HW / 2, R), (HW / 2, R - T)], closed=True)],
      "brass hoop, radius 2.5, 3 mm thick, 1.5 wide, along z")
write("hoop-stripe.obj", [revolve([(-HW / 2 - 0.01, R - T + 0.02), (-HW / 2 - 0.01, R - 0.02)], -0.2, 0.2, 4),
                          revolve([(HW / 2 + 0.01, R - T + 0.02), (HW / 2 + 0.01, R - 0.02)], -0.2, 0.2, 4)], "a mark on each side")
CR, CW = 3.3, 9.0
write("can.obj", [revolve([(-CW / 2, 0), (-CW / 2, CR - 0.15), (-CW / 2 + 0.15, CR), (CW / 2 - 0.15, CR),
                           (CW / 2, CR - 0.15), (CW / 2, 0)])], "a can, radius 3.3, 9 long, along z")
write("can-stripe.obj", [revolve([(-CW / 2 + 0.3, CR + 0.01), (CW / 2 - 0.3, CR + 0.01)], -0.25, 0.25, 6)], "a label stripe along the can")
write("ball-stripe.obj", [sphere_band(2.5)], "a band round the wooden ball (radius 2.5)")
write("steel-stripe.obj", [sphere_band(1.0, 0.18)], "a band round the steel ball (radius 1)")
print("done")
