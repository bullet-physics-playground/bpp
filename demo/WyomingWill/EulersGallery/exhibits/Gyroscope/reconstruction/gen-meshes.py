"""Meshes for gyroscope.lua, in body coordinates: the origin at the
gyroscope's centre of mass (the centre of the rotor and of the hoop), the
axle along +x, the hoop in the x-y plane, the rotor's disc in the y-z plane.
Run from this folder: python3 gen-meshes.py"""
import math

A = 4.4              # the hoop: radius of the groove's bottom
GW = 0.09            # the groove: half its width
LIP_H, LIP_T = 0.35, 0.12   # its sides: how far they stand out, how thick
R, RW = 3.0, 1.0     # the rotor: radius, rim width (along the axle)
RIN = 2.35           # inside of the rim
WEB = 0.3            # the web's thickness
HUB, HUBW = 0.55, 1.1
AX = 0.14            # the axle's radius
KNOB = 1.6           # the axle stands out of the hoop this far at its +x end, to a ball (the pivot)
OUT = "../gyroscope-meshes/"


def band(r0, r1, z0, z1, nu=128):
    """a flat ring in the x-y plane between radii r0 < r1, from z0 to z1 (a solid of revolution about z)"""
    prof = [(r0, z0), (r1, z0), (r1, z1), (r0, z1)]
    return revolve_z(prof, nu, closed=True)


def revolve_z(prof, nu, closed=False):
    V, F = [], []
    n = len(prof)
    for i in range(nu):
        a = 2 * math.pi * i / nu
        for r, z in prof:
            V.append((r * math.cos(a), r * math.sin(a), z))
    m = n if closed else n - 1
    for i in range(nu):
        for j in range(m):
            p, q = i * n + j, i * n + (j + 1) % n
            s, t = ((i + 1) % nu) * n + j, ((i + 1) % nu) * n + (j + 1) % n
            F.append((p, s, q)); F.append((q, s, t))
    return V, F


def revolve_x(prof, nu=64, closed=False):
    """a solid of revolution about the x axis: prof is [(x, r), ...]"""
    V, F = revolve_z([(r, x) for x, r in prof], nu, closed)
    return [(z, x, y) for x, y, z in V], F


def revolve_y(prof, nu=48, closed=False):
    """about the y axis: prof is [(y, r), ...]"""
    V, F = revolve_z([(r, y) for y, r in prof], nu, closed)
    return [(x, z, y) for x, y, z in V], F


def sector_x(x, r0, r1, a0, a1, n=24):
    """a flat sector of the disc x = const (both faces), radii r0..r1, angles a0..a1 about x"""
    V, F = [], []
    for i in range(n + 1):
        a = a0 + (a1 - a0) * i / n
        for r in (r0, r1):
            V.append((x, r * math.cos(a), r * math.sin(a)))
    for i in range(n):
        p = 2 * i
        F.append((p, p + 2, p + 1)); F.append((p + 1, p + 2, p + 3))
        F.append((p, p + 1, p + 2)); F.append((p + 1, p + 3, p + 2))
    return V, F


def write(path, parts, note):
    with open(path, "w") as f:
        f.write("# " + note + "\n")
        o = 0
        for V, F in parts:
            for v in V:
                f.write("v %.4f %.4f %.4f\n" % v)
            for t in F:     # (both sides: some of the profiles above wind one way, some the other)
                f.write("f %d %d %d\n" % (t[0] + 1 + o, t[1] + 1 + o, t[2] + 1 + o))
                f.write("f %d %d %d\n" % (t[0] + 1 + o, t[2] + 1 + o, t[1] + 1 + o))
            o += len(V)


# the frame: the grooved hoop (two lips and the band joining them inside),
# the axle across it, two bearing collars by the rotor
# (the groove's bottom at radius A; its sides stand out LIP_H)
lips = [band(A - 0.5, A + LIP_H, s * GW, s * (GW + LIP_T)) if s > 0 else band(A - 0.5, A + LIP_H, -GW - LIP_T, -GW)
        for s in (-1, 1)]
inner = band(A - 0.5, A, -GW, GW)
axle = revolve_x([(-A + 0.3, 0), (-A + 0.3, AX), (A - 0.3, AX), (A - 0.3, 0)], 24)
collars = [revolve_x([(s * (RW / 2 + 0.08), 0), (s * (RW / 2 + 0.08), 0.32), (s * (RW / 2 + 0.55), 0.32),
                      (s * (RW / 2 + 0.55), 0)], 32) for s in (-1, 1)]
BALL = 0.32
knobs, prongs = [], []
for sx in (-1, 1):
    m = lambda P: [(sx * x, r) for x, r in P]
    knobs.append(revolve_x(m([(A - 0.2, 0), (A - 0.2, 0.2), (A + KNOB - 0.3, 0.2), (A + KNOB - 0.3, 0)]), 24))
    c = A + KNOB
    knobs.append(revolve_x([(c + sx * BALL * math.cos(math.pi * k / 16), BALL * math.sin(math.pi * k / 16)) for k in range(17)], 32))
# the foot's fork (-x end): two prongs along y either side of the wire, under the ball
WR, PR, PL = 0.06, 0.08, 0.6
D = A + KNOB + BALL + WR
for z in (-1, 1):
    V, F = revolve_y([(-PL / 2 - PR + PR * (1 - math.cos(math.pi * k / 8)), PR * math.sin(math.pi * k / 8)) for k in range(9)] +
                     [(PL / 2 + PR * math.sin(math.pi * k / 16), PR * math.cos(math.pi * k / 16)) for k in range(9)], 16)
    prongs.append(([(x - D, y, zz + z * (WR + 0.02 + PR)) for x, y, zz in V], F))
    # (and a web joining it to the ball)
    V, F = revolve_x([(-D - 0.05, 0), (-D - 0.05, PR * 0.9), (-(A + KNOB), PR * 0.9), (-(A + KNOB), 0)], 12)
    prongs.append(([(x, y, zz + z * (WR + 0.02 + PR)) for x, y, zz in V], F))
write(OUT + "gyro-frame.obj", lips + [inner, axle] + knobs + prongs + collars,
      f"gyroscope frame: grooved hoop radius {A} cm (in the x-y plane), axle along x, standing out {KNOB} cm each end to a ball; a forked foot at -x")

# the rotor: a rim, a thin web, a hub (about the x axis)
rotor = revolve_x([(-HUBW / 2, AX), (-HUBW / 2, HUB), (-WEB / 2, HUB), (-WEB / 2, RIN), (-RW / 2, RIN),
                   (-RW / 2, R), (RW / 2, R), (RW / 2, RIN), (WEB / 2, RIN), (WEB / 2, HUB),
                   (HUBW / 2, HUB), (HUBW / 2, AX)], 96)
write(OUT + "gyro-rotor.obj", [rotor], f"gyroscope rotor: radius {R} cm, rim {RW} cm wide, about x")
# two painted sectors on each face of the web, to see it turn
marks = []
for s in (-1, 1):
    for a in (0.0, math.pi):
        marks.append(sector_x(s * (WEB / 2 + 0.01), HUB + 0.15, RIN - 0.1, a - 0.28, a + 0.28))
write(OUT + "gyro-rotor-marks.obj", marks, "painted marks on the rotor's web")

# the pedestal: a turned brass stand, its point at y = 0 (base below)
HP = 16.0
ped = revolve_y([(-HP, 0), (-HP, 3.2), (-HP + 0.5, 3.2), (-HP + 0.8, 2.6), (-HP + 1.2, 1.2), (-HP + 2.0, 0.55),
                 (-3.0, 0.45), (-2.2, 0.7), (-1.6, 0.7), (-1.2, 0.35), (-0.15, 0.08), (0.0, 0.0)], 48)
write(OUT + "pedestal.obj", [ped], f"pedestal: {HP} cm high, its point at the origin")

# the string: a thin cord along x, centred
LS = 12.0
cord = revolve_x([(-LS / 2, 0), (-LS / 2, 0.05), (LS / 2, 0.05), (LS / 2, 0)], 12)
write(OUT + "string.obj", [cord], f"string: {LS} cm along x, centred")
# the wire: 30 cm along x, 1.2 mm thick, centred
WL, WR = 30.0, 0.06
write(OUT + "wire.obj", [revolve_x([(-WL / 2, 0), (-WL / 2, WR), (WL / 2, WR), (WL / 2, 0)], 12)],
      f"tightrope wire: {WL} cm along x, centred")
print("done")
