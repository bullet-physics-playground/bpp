"""Meshes and mass properties for oloid.lua. Run from this folder:
python3 gen-meshes.py  (needs NumPy and SciPy)

Three rollers, each the convex hull of two circular arcs:
  oloid             two circles of radius R in perpendicular planes, each
                    through the other's centre (centres R apart)
  two-circle roller the same, centres R*sqrt(2) apart
  sphericon         two half circles of radius R in perpendicular planes,
                    the ends of each the ends of a diameter of the other
                    (a double cone with a right angle at its points, cut
                    along its axis and one half turned a quarter turn)
Each is worked out as the hull of 4000 points on its arcs; its volume,
centre of mass and moments of inertia from that (the hull's tetrahedra),
and everything is then put in its principal axes, centre at the origin.
Writes <name>.obj (the solid), <name>-edges.obj (its two arcs, painted) and
rollers.lua (the arcs and the mass properties, for the script)."""
import math
import numpy as np
from scipy.spatial import ConvexHull

OUT = "../oloid-meshes/"
R = 6.0
DENSITY = 0.0007          # kg per cm^3: a light wood


def arcs(kind):
    """[(centre, u, w, a0, a1)]: points centre + R (cos a u + sin a w), a0 <= a <= a1"""
    if kind == "sphericon":
        return [(np.zeros(3), np.array([0, 0, 1.0]), np.array([0, 1.0, 0]), 0.0, math.pi),     # x = 0, y >= 0
                (np.zeros(3), np.array([1.0, 0, 0]), np.array([0, -1.0, 0]), 0.0, math.pi)]    # z = 0, y <= 0
    d = R / 2 if kind == "oloid" else R / math.sqrt(2)
    return [(np.array([-d, 0, 0]), np.array([1.0, 0, 0]), np.array([0, 1.0, 0]), -math.pi, math.pi),
            (np.array([d, 0, 0]), np.array([1.0, 0, 0]), np.array([0, 0, 1.0]), -math.pi, math.pi)]


def points(arcl, n):
    P = []
    for c, u, w, a0, a1 in arcl:
        for k in range(n):
            a = a0 + (a1 - a0) * k / (n - 1)
            P.append(c + R * (math.cos(a) * u + math.sin(a) * w))
    return np.array(P)


def mass_props(P, hull):
    c0 = P.mean(axis=0)
    V = 0.0
    S1 = np.zeros(3)
    S2 = np.zeros((3, 3))
    for simplex, eq in zip(hull.simplices, hull.equations):
        a, b, c = P[simplex]
        # outward: (b - a) x (c - a) along the face normal
        if np.dot(np.cross(b - a, c - a), eq[:3]) < 0:
            b, c = c, b
        a, b, c = a - c0, b - c0, c - c0
        v = np.dot(a, np.cross(b, c)) / 6.0
        V += v
        S1 += v * (a + b + c) / 4.0
        # second moments of the tetrahedron (0, a, b, c)
        M = np.outer(a, a) + np.outer(b, b) + np.outer(c, c) + np.outer(a + b + c, a + b + c)
        S2 += v * M / 20.0
    cm = S1 / V
    S2c = S2 - V * np.outer(cm, cm)
    I = np.trace(S2c) * np.eye(3) - S2c
    return V, cm + c0, I


lines = ["-- made by reconstruction/gen-meshes.py: each roller's arcs (in its",
         "-- principal axes, centre of mass at the origin) and its mass properties",
         "return {"]
for kind in ["oloid", "two-circle", "sphericon"]:
    A = arcs(kind)
    P = points(A, 2000)
    hull = ConvexHull(P)
    V, cm, I = mass_props(P, hull)
    m = V * DENSITY
    evals, evecs = np.linalg.eigh(I * DENSITY)
    # principal frame: columns of evecs; make it right-handed
    if np.linalg.det(evecs) < 0:
        evecs[:, 2] = -evecs[:, 2]
    Rm = evecs.T                      # world -> principal
    tf = lambda p: Rm @ (p - cm)
    tv = lambda v: Rm @ v
    # the solid, in the principal frame
    Pp = np.array([tf(p) for p in points(A, 400)])
    h2 = ConvexHull(Pp)
    with open(OUT + kind + ".obj", "w") as f:
        f.write(f"# {kind}: R = {R} cm, in its principal axes, centre of mass at the origin\n")
        for p in Pp:
            f.write("v %.5f %.5f %.5f\n" % tuple(p))
        for s in h2.simplices:
            f.write("f %d %d %d\n" % (s[0] + 1, s[1] + 1, s[2] + 1))
            f.write("f %d %d %d\n" % (s[0] + 1, s[2] + 1, s[1] + 1))
    # the arcs, painted: a thin band along each
    with open(OUT + kind + "-edges.obj", "w") as f:
        f.write(f"# {kind}: its two arcs, as thin tubes\n")
        o = 0
        for c, u, w, a0, a1 in A:
            n = 200
            for k in range(n):
                a = a0 + (a1 - a0) * k / (n - 1)
                p = c + R * (math.cos(a) * u + math.sin(a) * w)
                t = -math.sin(a) * u + math.cos(a) * w
                nrm = np.cross(u, w)
                q = math.cos(a) * u + math.sin(a) * w
                for j in range(6):
                    b = 2 * math.pi * j / 6
                    off = 0.18 * (math.cos(b) * nrm + math.sin(b) * q)
                    f.write("v %.5f %.5f %.5f\n" % tuple(tf(p + off)))
            for k in range(n - 1):
                for j in range(6):
                    a_, b_ = o + k * 6 + j + 1, o + k * 6 + (j + 1) % 6 + 1
                    c_, d_ = a_ + 6, b_ + 6
                    f.write("f %d %d %d\nf %d %d %d\n" % (a_, c_, b_, b_, c_, d_))
                    f.write("f %d %d %d\nf %d %d %d\n" % (a_, b_, c_, b_, d_, c_))
            o += n * 6
    lines.append(f'  ["{kind}"] = {{')
    lines.append(f"    volume = {V:.4f}, mass = {m:.6f}, I = {{ {evals[0]:.7f}, {evals[1]:.7f}, {evals[2]:.7f} }},")
    lines.append("    arcs = {")
    for c, u, w, a0, a1 in A:
        cc, uu, ww = tf(c + np.zeros(3)), tv(u), tv(w)
        lines.append("      { c = { %.6f, %.6f, %.6f }, u = { %.6f, %.6f, %.6f }, w = { %.6f, %.6f, %.6f }, a0 = %.6f, a1 = %.6f }," %
                     (*cc, *uu, *ww, a0, a1))
    lines.append("    },")
    lines.append("  },")
    print(kind, "volume %.3f cm^3 (%.4f R^3), mass %.1f g, I" % (V, V / R ** 3, m * 1000), evals * 1, "cm offset", cm)
lines.append("}")
open(OUT + "rollers.lua", "w").write("\n".join(lines) + "\n")
print("done")
