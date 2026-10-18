"""Meshes for spinning-egg.lua. Run from this folder: python3 gen-meshes.py

The egg is a prolate spheroid, its long axis along y: semi-axes B, A, B
(the shape the physics has). It's drawn in two parts: the shell, and two
painted bands (a ring round its middle, and a line from end to end) that
stand out a hair so they show the spin. Every face is written both ways
round."""
import math

OUT = "../spinning-egg-meshes/"
A, B = 2.85, 2.15        # semi-axes (cm): 5.7 cm long, 4.3 cm across


def spheroid_pt(u, th, lift=0.0):
    """u: angle from the +y end (0..pi), th: angle round the axis; lift: out along the normal"""
    x, y, z = B * math.sin(u) * math.cos(th), A * math.cos(u), B * math.sin(u) * math.sin(th)
    nx, ny, nz = x / (B * B), y / (A * A), z / (B * B)
    nl = math.sqrt(nx * nx + ny * ny + nz * nz)
    return (x + lift * nx / nl, y + lift * ny / nl, z + lift * nz / nl)


def grid(u0, u1, th0, th1, nu, nt, lift=0.0, wrap=False):
    V, F = [], []
    cols = nt if wrap else nt + 1
    for i in range(nu + 1):
        u = u0 + (u1 - u0) * i / nu
        for j in range(cols):
            V.append(spheroid_pt(u, th0 + (th1 - th0) * j / nt, lift))
    for i in range(nu):
        for j in range(nt):
            j1 = (j + 1) % cols if wrap else j + 1
            p, q, r, s = i * cols + j, i * cols + j1, (i + 1) * cols + j, (i + 1) * cols + j1
            F.append((p, r, q)); F.append((q, r, s))
    return V, F


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


write("egg-shell.obj", [grid(0, math.pi, 0, 2 * math.pi, 64, 64, wrap=True)],
      f"the egg: a spheroid {2*A} cm long, {2*B} cm across, long axis along y")
w = 0.12   # the bands' half-width, radians
write("egg-bands.obj", [
    grid(math.pi / 2 - w * 0.8, math.pi / 2 + w * 0.8, 0, 2 * math.pi, 2, 96, lift=0.004, wrap=True),   # round the middle
    grid(0.05, math.pi - 0.05, -w, w, 64, 2, lift=0.004),                                               # end to end
], "painted bands: one round the middle, one from end to end")
print("done")
