"""Meshes for tippe-top.lua: the ball, the stem and a painted stripe, for
each kind of top, in body coordinates (the origin at the top's centre of
mass, the stem along +y). Run from this folder: python3 gen-meshes.py"""
import math

R, RS, LS = 1.5, 0.6, 0.6           # ball radius, stem-tip radius, how far the tip stands out
KINDS = {"tippe-top": 0.45, "centred": 0.06}    # centre of mass below the ball's centre, cm

def sphere(cx, cy, cz, r, nu=48, nv=24, keep=None):
    V, F = [], []
    for j in range(nv + 1):
        th = math.pi * j / nv
        for i in range(nu):
            ph = 2 * math.pi * i / nu
            V.append((cx + r * math.sin(th) * math.cos(ph), cy + r * math.cos(th), cz + r * math.sin(th) * math.sin(ph)))
    for j in range(nv):
        for i in range(nu):
            a, b = j * nu + i, j * nu + (i + 1) % nu
            c, d = a + nu, b + nu
            tri = [(a, c, b), (b, c, d)]
            for t in tri:
                if keep is None or all(keep(V[k]) for k in t):
                    F.append(t)
    return V, F

def stripe(cx, cy, r, ph0, width, nv=32):
    """a band on the ball from pole to pole, `width` radians wide, just proud of it"""
    V, F = [], []
    for j in range(nv + 1):
        th = 0.12 * math.pi + 0.76 * math.pi * j / nv     # (not over the stem or the very bottom)
        for ph in (ph0 - width / 2, ph0 + width / 2):
            V.append((r * math.sin(th) * math.cos(ph), cy + r * math.cos(th), r * math.sin(th) * math.sin(ph)))
    for j in range(nv):
        a = 2 * j
        F.append((a, a + 2, a + 1)); F.append((a + 1, a + 2, a + 3))
        F.append((a, a + 1, a + 2)); F.append((a + 1, a + 3, a + 2))     # (both sides)
    return V, F

def cylinder(y0, y1, r, n=32):
    V, F = [], []
    for y in (y0, y1):
        for i in range(n):
            ph = 2 * math.pi * i / n
            V.append((r * math.cos(ph), y, r * math.sin(ph)))
    for i in range(n):
        a, b = i, (i + 1) % n
        F.append((a, a + n, b)); F.append((b, a + n, b + n))
    return V, F

def write(path, parts, note):
    with open(path, "w") as f:
        f.write("# " + note + "\n")
        o = 0
        for V, F in parts:
            for v in V: f.write("v %.4f %.4f %.4f\n" % v)
            for t in F: f.write("f %d %d %d\n" % (t[0] + 1 + o, t[1] + 1 + o, t[2] + 1 + o))
            o += len(V)

for name, A in KINDS.items():
    cy = A                                   # the ball's centre, above the centre of mass
    tip = cy + R + LS - RS                   # the stem tip's centre
    write(f"../tippe-top-meshes/{name}-ball.obj", [sphere(0, cy, 0, R)],
          f"tippe top ball: radius {R} cm, centre {A} cm above the centre of mass")
    # the stem: what stands out of the ball -- a collar and the rounded tip
    write(f"../tippe-top-meshes/{name}-stem.obj",
          [cylinder(cy + 0.6 * R, tip, RS * 0.999), sphere(0, tip, 0, RS, 32, 16)],
          f"tippe top stem: tip radius {RS} cm, standing {LS} cm out of the ball")
    write(f"../tippe-top-meshes/{name}-stripe.obj",
          [stripe(0, cy, R * 1.008, 0.0, 0.36), stripe(0, cy, R * 1.008, math.pi, 0.36)],
          "two painted bands, to see it spin")
print("done")
