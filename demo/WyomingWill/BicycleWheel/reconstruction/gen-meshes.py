"""Meshes for bicycle-wheel.lua. Run from this folder: python3 gen-meshes.py

The stool's turning part and the figure sitting on it are in the turntable's
coordinates: the origin on the stool's axis at the top of the seat, facing
+z, up +y. The wheel is in its own: the origin at its centre, the axle along
+x. The stool's base is in the room's, its foot on the floor (y = 0).
Every face is written both ways round (some profiles wind one way, some the
other)."""
import math

OUT = "../bicycle-wheel-meshes/"
SEAT_Y = 55.0          # the seat's top, above the floor
WR = 22.0              # the wheel's radius (to the outside of the tyre): a small wheel, so it can come in close
TYRE = 1.8             # the tyre's thickness (radius of its section)
RIM_R = WR - 2 * TYRE  # the rim's outer radius
AXLE = 16.0            # half the axle's length (to the handles' ends)


def revolve(prof, nu, axis="y", closed=False):
    """a solid of revolution: prof is [(along, radius), ...] about the given axis"""
    V, F = [], []
    n = len(prof)
    for i in range(nu):
        a = 2 * math.pi * i / nu
        c, s = math.cos(a), math.sin(a)
        for h, r in prof:
            if axis == "y":
                V.append((r * c, h, r * s))
            elif axis == "x":
                V.append((h, r * c, r * s))
            else:
                V.append((r * c, r * s, h))
    m = n if closed else n - 1
    for i in range(nu):
        for j in range(m):
            p, q = i * n + j, i * n + (j + 1) % n
            s_, t = ((i + 1) % nu) * n + j, ((i + 1) % nu) * n + (j + 1) % n
            F.append((p, s_, q)); F.append((q, s_, t))
    return V, F


def sphere(c, r, nu=24, nv=12):
    prof = [(-r * math.cos(math.pi * k / nv), r * math.sin(math.pi * k / nv)) for k in range(nv + 1)]
    V, F = revolve(prof, nu, "y")
    return [(x + c[0], y + c[1], z + c[2]) for x, y, z in V], F


def rod(p, q, r, n=12, caps=True):
    """a cylinder (rounded ends if caps) from p to q"""
    d = [q[i] - p[i] for i in range(3)]
    L = math.sqrt(sum(x * x for x in d))
    prof = [(0, 0), (0, r), (L, r), (L, 0)]
    if caps:
        prof = [(-r * math.cos(math.pi / 2 * k / 4), r * math.sin(math.pi / 2 * k / 4)) for k in range(5)]
        prof += [(L + r * math.sin(math.pi / 2 * k / 4), r * math.cos(math.pi / 2 * k / 4)) for k in range(5)]
    V, F = revolve(prof, n, "y")
    # turn y onto d
    u = [x / L for x in d]
    # a basis: u, and two perpendicular to it
    a = [1, 0, 0] if abs(u[0]) < 0.9 else [0, 0, 1]
    e1 = [u[1] * a[2] - u[2] * a[1], u[2] * a[0] - u[0] * a[2], u[0] * a[1] - u[1] * a[0]]
    n1 = math.sqrt(sum(x * x for x in e1)); e1 = [x / n1 for x in e1]
    e2 = [u[1] * e1[2] - u[2] * e1[1], u[2] * e1[0] - u[0] * e1[2], u[0] * e1[1] - u[1] * e1[0]]
    W = []
    for x, y, z in V:
        W.append(tuple(p[i] + x * e1[i] + y * u[i] + z * e2[i] for i in range(3)))
    return W, F


def box(c, s):
    x0, y0, z0 = c[0] - s[0] / 2, c[1] - s[1] / 2, c[2] - s[2] / 2
    x1, y1, z1 = c[0] + s[0] / 2, c[1] + s[1] / 2, c[2] + s[2] / 2
    V = [(x0, y0, z0), (x1, y0, z0), (x1, y1, z0), (x0, y1, z0), (x0, y0, z1), (x1, y0, z1), (x1, y1, z1), (x0, y1, z1)]
    F = [(0, 2, 1), (0, 3, 2), (4, 5, 6), (4, 6, 7), (0, 1, 5), (0, 5, 4), (3, 7, 6), (3, 6, 2), (0, 4, 7), (0, 7, 3), (1, 2, 6), (1, 6, 5)]
    return V, F


def write(name, parts, note):
    with open(OUT + name, "w") as f:
        f.write("# " + note + "\n")
        o = 0
        for V, F in parts:
            for v in V:
                f.write("v %.3f %.3f %.3f\n" % v)
            for t in F:
                f.write("f %d %d %d\n" % (t[0] + 1 + o, t[1] + 1 + o, t[2] + 1 + o))
                f.write("f %d %d %d\n" % (t[0] + 1 + o, t[2] + 1 + o, t[1] + 1 + o))
            o += len(V)


# --- the stool's base (the room's coordinates): a round foot, a column
write("stool-base.obj", [
    revolve([(0, 0), (0, 30), (2, 30), (3.5, 26), (5, 6), (SEAT_Y - 14, 3.5), (SEAT_Y - 12, 6), (SEAT_Y - 10, 6), (SEAT_Y - 10, 0)], 48),
], "swivel stool: foot and column, to the bearing 10 cm under the seat")

# --- the stool's turning part (turntable coordinates, origin at the seat's top)
write("stool-seat.obj", [
    revolve([(-10, 0), (-10, 7), (-6, 7), (-5, 21), (-4, 23), (-1, 23), (0, 21), (0, 0)], 48),      # the seat
    revolve([(-34, 22), (-34, 24), (-32, 24), (-32, 22)], 48, closed=True),                           # the foot ring
] + [rod((22 * math.cos(a) * 0.3, -9, 22 * math.sin(a) * 0.3), (23 * math.cos(a), -33, 23 * math.sin(a)), 0.9)
     for a in [2 * math.pi * k / 4 + math.pi / 4 for k in range(4)]], "swivel stool: seat and foot ring (it turns)")

# --- the figure: a wooden lay figure, sitting, facing +z (turntable coordinates)
J = 3.2   # the joints' balls
fig = []
fig.append(sphere((0, 9, -2), 11))                           # hips
fig.append(rod((0, 12, -3), (0, 42, -2), 10.5))               # trunk
fig.append(rod((0, 40, -2), (0, 52, -1), 12.5))               # chest
fig.append(rod((0, 56, -1), (0, 64, 0), 3.5))                 # neck
fig.append(sphere((0, 74, 1), 9.5))                          # head
for sx in (-1, 1):
    hip, knee, ankle = (sx * 9, 7, 2), (sx * 10, 7, 40), (sx * 10, -30, 42)
    fig.append(rod(hip, knee, 6.5))                           # thigh
    fig.append(sphere(knee, J + 2))
    fig.append(rod(knee, ankle, 4.5))                         # shin
    fig.append(sphere(ankle, J))
    fig.append(box((sx * 10, -33, 46), (7, 3, 13)))           # foot, on the ring
    fig.append(sphere((sx * 19, 52, -1), J + 1))              # shoulder
write("figure.obj", fig, "a wooden lay figure sitting on the stool, facing +z")

# the arms: an upper arm and a forearm, along +x from the origin (the
# script turns and places them each frame)
UA, FA = 29.0, 27.0
write("upper-arm.obj", [rod((0, 0, 0), (UA, 0, 0), 3.6), sphere((UA, 0, 0), J)], f"upper arm, {UA} cm along x")
write("forearm.obj", [rod((0, 0, 0), (FA, 0, 0), 3.0), sphere((FA + 2.5, 0, 0), 3.6)], f"forearm and hand, {FA} cm along x")

# --- the wheel's part that doesn't turn: axle and handles (wheel coordinates)
write("wheel-axle.obj", [
    revolve([(-AXLE, 0), (-AXLE, 0.8), (AXLE, 0.8), (AXLE, 0)], 16, "x"),
    revolve([(-AXLE - 0.5, 0), (-AXLE - 0.5, 1.9), (-8.5, 1.9), (-8, 2.4), (-7, 2.4), (-6.5, 0)], 24, "x"),
    revolve([(AXLE + 0.5, 0), (AXLE + 0.5, 1.9), (8.5, 1.9), (8, 2.4), (7, 2.4), (6.5, 0)], 24, "x"),
], "the axle and two wooden handles, along x")

# --- the wheel's part that turns: hub, spokes, rim, tyre
hub = revolve([(-5, 0.9), (-5, 3.2), (-3.6, 3.2), (-3.4, 1.8), (3.4, 1.8), (3.6, 3.2), (5, 3.2), (5, 0.9)], 32, "x")
rim = revolve([(-1.2, RIM_R - 2.2), (-1.3, RIM_R), (1.3, RIM_R), (1.2, RIM_R - 2.2)], 128, "x", closed=True)
spokes = []
for k in range(32):
    a = 2 * math.pi * k / 32
    side = 1 if k % 2 == 0 else -1
    # tangential lacing: from the flange, a little round, to the rim
    a0 = a + side * 0.25
    p = (side * 4.2, 2.9 * math.cos(a0), 2.9 * math.sin(a0))
    q = (side * 0.5, (RIM_R - 2.0) * math.cos(a), (RIM_R - 2.0) * math.sin(a))
    spokes.append(rod(p, q, 0.11, 5, caps=False))
write("wheel-turning.obj", [hub, rim] + spokes, "hub, 32 spokes and rim, about x")
tyre = revolve([(TYRE * math.sin(2 * math.pi * k / 16), RIM_R + TYRE - TYRE * math.cos(2 * math.pi * k / 16)) for k in range(16)],
               128, "x", closed=True)
write("wheel-tyre.obj", [tyre], f"tyre: {WR} cm radius outside, about x")
# a painted mark on the rim, to see it turn (and the valve)
mark = revolve([(-1.35, RIM_R - 0.3), (-1.35, RIM_R + 0.05), (1.35, RIM_R + 0.05), (1.35, RIM_R - 0.3)], 128, "x", closed=True)
V, F = mark
keep = [i for i in range(len(V)) if math.atan2(V[i][2], V[i][1]) > -0.35 and math.atan2(V[i][2], V[i][1]) < 0.35]
ks = set(keep)
idx = {i: n for n, i in enumerate(keep)}
F2 = [(idx[a], idx[b], idx[c]) for a, b, c in F if a in ks and b in ks and c in ks]
write("wheel-mark.obj", [([V[i] for i in keep], F2), rod((0, RIM_R - 2.2, 0), (0, RIM_R - 4.5, 0), 0.45, 8)],
      "a painted band on the rim and the valve")
print("done")
