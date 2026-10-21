"""Lehmer's number sieve -- the one source of its geometry.

Run from this folder:  python3 make-geometry.py   (needs shapely 2.1 or later)

Writes
  geometry.scad      every moving part's outline, for lehmer-sieve.scad
                     (the printed parts) -- millimetres are its business:
                     the numbers here are in cm, as the simulation's
  ../sieve-geometry.lua  the same parts as convex pieces, with their masses,
                     centres of mass and moments, for the simulation

So what is printed is what is simulated: the wheels' outlines, their holes,
the slots and locking arcs of the Geneva stars, the drive's pins and
locking discs, and the cam that lifts the probe all come from here.

THE MACHINE (cm; the machine's frame: y up, the wheels' axle at x = z = 0,
the drive shaft at x = C behind... to the right, the probe at x = -RHO)

  Four wheels on one axle, one above the other: 9 positions at the bottom,
  then 8, 7, 5. Each is a Geneva star: one turn of the drive shaft beside
  them moves every wheel on by exactly one position, and locks it there
  between turns. A ring of holes, one per position, at radius RHO; pegs
  in some of them. A probe above the stack, at the reading place, is
  lifted by a cam on the drive shaft while the wheels move, and let down
  when they have stopped: it falls through as many wheels as have an open
  hole under it, and right through when they all do.
"""
import math
import shapely
from shapely.geometry import Point, Polygon, box
from shapely import affinity
from shapely.ops import unary_union

# ---------------------------------------------------------------------------
# sizes (cm)
# ---------------------------------------------------------------------------
C = 8.5            # the drive shaft from the wheels' axle
MODS = [9, 8, 7, 5]  # the wheels, bottom to top
PIN_R = 0.3        # the drive pins (6 mm steel dowels)
SLOT_HW = 0.35     # a slot's half width (0.5 mm of play on the 6 mm pin)
FLARE = None       # (or (width, length): the slot's mouth opened out instead -- tried: see FINDINGS.md)
LOCK_GAP = 0.05    # between a locking disc and a star's arc (0.5 mm). The arc is part of a circle
                     # round the drive's axis, so a star turned a little moves along it: locked, a
                     # star can still turn about a degree either way (measured: FINDINGS.md)
END_GAP, END_SPAN = 0.15, 15.0   # the arc's last END_SPAN degrees (seen from the drive) eased back, a
                     # ramp out to END_GAP: the disc's edge comes onto the arc there, and brings a
                     # star that stopped a little off its place back to it
RELIEF_GAP = 0.15  # round where a star passes the locking disc: room for the star to stand off its
                   # place by the lock's play, and to lead or lag by the pin's play in its slot
# THE DETENTS. The locking disc only keeps a star within its play (about a
# degree each way: FINDINGS.md); what puts it on its place is a detent, a
# printed PLA leaf spring whose round nose rests in the mouth of the slot
# opposite the drive, against both its corners, as the Pascaline's does
# between two pins.
DET_NR = 0.5       # the nose's radius (wider than the slot, so it sits on the corners)
DET_L = 3.0        # the leaf, root to nose
DET_T = 0.12       # its thickness (1.2 mm: three lines of a 0.4 mm nozzle)
DET_PRE = 0.05     # how far it is pressed back at rest
DET_STOP = 0.1     # how much further in its stop lets the nose go (between the slots it floats)
RHO = 2.4          # the ring of holes
HOLE_R = 0.4       # the holes (8 mm); the probe is 5 mm
AXLE_R = 0.4       # the wheels' axle (8 mm steel rod); the bore 0.42
BORE_R = 0.42
SHAFT_R = 0.3      # the drive shaft (6 mm steel rod)
STAR_T = 0.5       # a wheel's thickness
ARM_T = 0.4        # a drive crank's thickness, under its wheel
GAP = 0.1
LEVEL = ARM_T + GAP + STAR_T + GAP   # one wheel and its crank: 1.1
BASE_TOP = 2.0     # the base plate's top (it stands on feet)
Y0 = BASE_TOP + 0.2                  # the lowest crank's underside
PROBE_R = 0.25
FOLLOW_R = 0.4     # the probe's follower: an 8 mm steel ball
CAM_RF = 4.0       # the follower's radius on the cam
CAM_IN, CAM_OUT = 3.5, 4.5
FOLLOW_OFF = 6.0   # the follower's underside above the probe's tip
ARCSTEP = 3.0      # degrees between points on arcs

def crank_y(i): return Y0 + i * LEVEL
def star_y(i): return crank_y(i) + ARM_T + GAP
STACK_TOP = star_y(len(MODS) - 1) + STAR_T
TIP_LOW = star_y(0) - 0.45                     # the probe right through
TIP_HIGH = STACK_TOP + 0.5                     # the probe lifted clear
CAM_LO = TIP_LOW + FOLLOW_OFF - 0.15           # the cam's surface: low (the follower free) ...
CAM_HI = TIP_HIGH + FOLLOW_OFF + 0.1           # ... and high (the probe lifted)
CAM_BASE = CAM_LO - 0.6
SHAFT_TOP = CAM_HI + 0.5
GUIDE_Y0, GUIDE_Y1 = STACK_TOP + 0.8, STACK_TOP + 1.7
PROBE_LEN = 8.5

# the cam's profile, by the drive's turn phi (degrees) from where it rests:
# the probe goes up before any wheel starts to move (the 9-wheel's Geneva
# moves from 110 to 250 degrees) and comes down after they have all stopped
RISE = (12.0, 100.0)
FALL = (260.0, 348.0)
def cam_height(phi):
    phi %= 360.0
    def ease(t): return 0.5 - 0.5 * math.cos(math.pi * t)
    if phi < RISE[0] or phi >= FALL[1]: return CAM_LO
    if phi < RISE[1]: return CAM_LO + (CAM_HI - CAM_LO) * ease((phi - RISE[0]) / (RISE[1] - RISE[0]))
    if phi < FALL[0]: return CAM_HI
    return CAM_HI - (CAM_HI - CAM_LO) * ease((phi - FALL[0]) / (FALL[1] - FALL[0]))

PLA = 0.8e-3       # kg/cm^3, as printed (the hall's other exhibits use the same)
STEEL = 7.85e-3

# ---------------------------------------------------------------------------
# 2D helpers: the plan is (X, Y) = (x, -z), so a turn from X to Y is a
# right-handed turn about +y
# ---------------------------------------------------------------------------
def circle(cx, cy, r, step=ARCSTEP):
    n = max(12, int(round(360 / step)))
    return Polygon([(cx + r * math.cos(2 * math.pi * k / n), cy + r * math.sin(2 * math.pi * k / n)) for k in range(n)])

def geneva(m):
    a = C * math.sin(math.pi / m)
    b = C * math.cos(math.pi / m)
    lockR = a - 1.5 * PIN_R
    return a, b, lockR

# the star (wheel) for m positions, in its own plan, the arm k = 0 facing
# the drive (+X); and its holes' centres (hole k at 180 + k * 360/m degrees:
# the one under the probe after k steps from 0)
#
# coarse: the shape the simulation's contacts use. Every corner inside the
# outline costs a convex piece, so there the holes are squares inside the
# round ones (a little more wheel round the probe, never less), the slots'
# ends square and a little deeper (the pin never reaches them), the locking
# arcs drawn every 8 degrees (the chords stand 0.02 cm or less inside the
# 0.04 cm gap), and the bore left out (the axle is the hinge)
def star(m, holes=True, coarse=False):
    a, b, lockR = geneva(m)
    d = 360.0 / m
    s = circle(0, 0, b, 1.0)
    cuts = []
    for k in range(m):
        ang = math.radians(d / 2 + k * d)
        r0 = C - a                                # the pin's deepest
        L = b + 1.0 - r0
        if coarse:
            slot = box(-SLOT_HW - 0.05, -SLOT_HW, L, SLOT_HW)
        else:
            slot = box(0, -SLOT_HW, L, SLOT_HW).union(circle(0, 0, SLOT_HW, 6))
        if FLARE:
            fw, fl = FLARE
            m0 = b - r0                              # the mouth, along the slot from its inner end
            slot = slot.union(Polygon([(m0 - fl, -SLOT_HW), (m0 + 0.05, -SLOT_HW - fw - 0.05 * fw / fl),
                                       (m0 + 0.05, SLOT_HW + fw + 0.05 * fw / fl), (m0 - fl, SLOT_HW)]))
        slot = affinity.translate(slot, r0, 0)
        slot = affinity.rotate(slot, math.degrees(ang), origin=(0, 0))
        cuts.append(slot)
        q = math.radians(k * d)
        qx, qy = C * math.cos(q), C * math.sin(q)
        R = lockR + LOCK_GAP
        cuts.append(circle(qx, qy, R, 8.0 if coarse else 1.0))
        # the arc's ends, eased: seen from Q (the drive's axis, this arm
        # locked), the arc ends psi from the line back to the wheel's centre
        psi = math.degrees(math.acos((C * C + R * R - b * b) / (2 * C * R)))
        back = math.degrees(q) + 180
        for sgn in (-1, 1):
            step = 1.0 if not coarse else 3.0
            ts = [psi - END_SPAN + step * j for j in range(int((END_SPAN + 40) / step) + 1)]
            pts = [(qx, qy)]
            for t in ts:
                u = min(1.0, max(0.0, (t - (psi - END_SPAN)) / END_SPAN))
                r = R + END_GAP * u
                ang = math.radians(back + sgn * t)
                pts.append((qx + r * math.cos(ang), qy + r * math.sin(ang)))
            cuts.append(Polygon(pts))
    if not coarse:
        cuts.append(circle(0, 0, BORE_R, 6))
    if holes:
        for k in range(m):
            q = math.radians(180 + k * d)
            hx, hy = RHO * math.cos(q), RHO * math.sin(q)
            if coarse:
                hs = HOLE_R * 0.9
                sq = affinity.rotate(box(-hs, -hs, hs, hs), 180 + k * d, origin=(0, 0))
                cuts.append(affinity.translate(sq, hx, hy))
            else:
                cuts.append(circle(hx, hy, HOLE_R, 6))
    return s.difference(unary_union(cuts))

def hole_centres(m):
    d = 360.0 / m
    return [(RHO * math.cos(math.radians(180 + k * d)), RHO * math.sin(math.radians(180 + k * d))) for k in range(m)]

# the wheel's turn (degrees, right-handed) while the drive turns phi
# (degrees) from rest at the start of a step: 0, then -360/m
def wheel_turn(m, phi):
    a, b, lockR = geneva(m)
    lo, hi = 90 + 180.0 / m, 270 - 180.0 / m
    if phi <= lo: return 0.0
    if phi >= hi: return -360.0 / m
    p = math.radians(phi)
    px, py = C + a * math.cos(p), a * math.sin(p)
    return math.degrees(math.atan2(py, px)) - 180.0 / m

# the locking disc for the wheel m, in the drive's own plan (its axis at the
# origin, the pin at +X): a disc, less everywhere the star passes in a turn
def lock_disc(m):
    a, b, lockR = geneva(m)
    disc = circle(0, 0, lockR, 1.0)
    st = star(m, holes=False)
    swept = []
    for k in range(0, 361):
        phi = k * 1.0
        w = affinity.rotate(st, wheel_turn(m, phi), origin=(0, 0))
        w = affinity.translate(w, -C, 0)                  # the drive's axis at the origin
        w = affinity.rotate(w, -phi, origin=(0, 0))       # into the drive's frame
        swept.append(w)
    sw = unary_union(swept).buffer(RELIEF_GAP).simplify(0.01)
    d = disc.difference(sw)
    d = d.difference(circle(0, 0, SHAFT_R + 0.01, 45))   # (the shaft's own hole: it is drawn with the shaft)
    if d.geom_type == "MultiPolygon":
        d = max(d.geoms, key=lambda g: g.area)
    return d

# ---------------------------------------------------------------------------
# convex pieces: a constrained triangulation, merged (Hertel and Mehlhorn)
# ---------------------------------------------------------------------------
def cross(o, a, b): return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])

def is_convex(p):
    n = len(p)
    for i in range(n):
        if cross(p[i], p[(i + 1) % n], p[(i + 2) % n]) < -1e-9: return False
    return True

def convex_pieces(poly, tol=0.004):
    # (arcs on the outside of a part are kept as they are; inside it -- a
    # hole, a slot's end, a locking arc -- each corner costs a piece, so
    # those are drawn coarser: see star())
    poly = shapely.set_precision(poly.simplify(tol), 1e-5)
    tris = shapely.constrained_delaunay_triangles(poly)
    key = lambda p: (round(p[0], 4), round(p[1], 4))
    polys = []
    for t in tris.geoms:
        if t.area < 1e-9: continue
        c = [key(p) for p in list(t.exterior.coords)[:3]]
        if cross(c[0], c[1], c[2]) < 0: c = [c[0], c[2], c[1]]
        if len(set(c)) == 3: polys.append(c)
    owner = {}                       # a directed edge -> the piece it belongs to
    for i, p in enumerate(polys):
        for j in range(len(p)): owner[(p[j], p[(j + 1) % len(p)])] = i
    changed = True
    while changed:
        changed = False
        for i in range(len(polys)):
            p = polys[i]
            if p is None: continue
            j = 0
            while j < len(p):
                a, b = p[j], p[(j + 1) % len(p)]
                k = owner.get((b, a))
                if k is not None and k != i and polys[k] is not None:
                    q = polys[k]
                    ia = q.index(a)
                    qq = q[ia:] + q[:ia]                  # a ... b (q runs b -> a, then on round to b)
                    merged = p[:j + 1] + qq[1:-1] + p[j + 1:]
                    if is_convex(merged):
                        for e in range(len(q)): owner.pop((q[e], q[(e + 1) % len(q)]), None)
                        owner.pop((a, b), None)
                        polys[k] = None
                        polys[i] = p = merged
                        for e in range(len(p)): owner[(p[e], p[(e + 1) % len(p)])] = i
                        changed = True
                        continue
                j += 1
    return [p for p in polys if p is not None]

# ---------------------------------------------------------------------------
# mass properties of a prism of polygon p (plan), y from y0 to y1, density
# rho: mass, centre (x, y, z) and the second moments about that centre
# ---------------------------------------------------------------------------
def plate_props(poly, y0, y1, rho):
    from shapely.geometry import Polygon as P
    A = 0; Sx = Sy = Sxx = Syy = 0
    rings = [list(poly.exterior.coords)] + [list(r.coords) for r in poly.interiors]
    for ri, ring in enumerate(rings):
        ring_poly = P(ring)
        sign = 1
        # shoelace integrals over each ring, signed by orientation
        for (x0, y0_, ), (x1, y1_) in zip(ring[:-1], ring[1:]):
            cr = x0 * y1_ - x1 * y0_
            A += cr / 2
            Sx += (x0 + x1) * cr / 6
            Sy += (y0_ + y1_) * cr / 6
            Sxx += (x0 * x0 + x0 * x1 + x1 * x1) * cr / 12
            Syy += (y0_ * y0_ + y0_ * y1_ + y1_ * y1_) * cr / 12
    if A < 0: A, Sx, Sy, Sxx, Syy = -A, -Sx, -Sy, -Sxx, -Syy
    h = y1 - y0
    m = rho * A * h
    cx, cy = Sx / A, Sy / A          # plan
    return dict(m=m, X=cx, Y=cy, yc=(y0 + y1) / 2, h=h, A=A,
                Ixx_plan=rho * h * Sxx, Iyy_plan=rho * h * Syy)

def combine(parts):
    """parts: list of (mass, (x, y, z), (Ixx, Iyy, Izz) about own centre) in
    the machine frame; returns the mass, centre, and the moments about it"""
    M = sum(p[0] for p in parts)
    c = [sum(p[0] * p[1][i] for p in parts) / M for i in range(3)]
    I = [0, 0, 0]
    for m, (x, y, z), (ix, iy, iz) in parts:
        dx, dy, dz = x - c[0], y - c[1], z - c[2]
        I[0] += ix + m * (dy * dy + dz * dz)
        I[1] += iy + m * (dx * dx + dz * dz)
        I[2] += iz + m * (dx * dx + dy * dy)
    return M, c, I

def plate_inertia(poly, y0, y1, rho, ox=0.0):
    """a plate (plan polygon, its plan origin moved to x = ox) as
    (mass, centre, moments about its centre) in the machine frame"""
    pr = plate_props(poly, y0, y1, rho)
    m, X, Y, h = pr["m"], pr["X"], pr["Y"], pr["h"]
    # about the plan origin: Iy (vertical) = rho h (Sxx + Syy); about the centre:
    Iy = pr["Ixx_plan"] + pr["Iyy_plan"] - m * (X * X + Y * Y)
    Ix = pr["Iyy_plan"] - m * Y * Y + m * h * h / 12           # (x axis: the plan's Y spread, and the thickness)
    Iz = pr["Ixx_plan"] - m * X * X + m * h * h / 12
    return (m, (X + ox, pr["yc"], -Y), (Ix, Iy, Iz))

def cyl_inertia(r, y0, y1, x, z, rho):
    h = y1 - y0
    m = rho * math.pi * r * r * h
    return (m, (x, (y0 + y1) / 2, z), (m * (3 * r * r + h * h) / 12, m * r * r / 2, m * (3 * r * r + h * h) / 12))

# ---------------------------------------------------------------------------
# build everything
# ---------------------------------------------------------------------------
def fmt(v): return "%.4f" % v

def lua_pieces(pieces, y0, y1, ox=0.0):
    """convex plan polygons -> Lua: each a flat list of 3D points (machine frame)"""
    out = []
    for p in pieces:
        pts = []
        for (X, Y) in p:
            for y in (y0, y1):
                pts += [fmt(X + ox), fmt(y), fmt(-Y)]
        out.append("{" + ",".join(pts) + "}")
    return out

def scad_poly(poly):
    """a shapely polygon (with holes) -> [points, paths] for OpenSCAD"""
    pts, paths = [], []
    for ring in [poly.exterior] + list(poly.interiors):
        c = list(ring.coords)[:-1]
        paths.append(list(range(len(pts), len(pts) + len(c))))
        pts += c
    return "[[" + ",".join("[%s,%s]" % (fmt(x), fmt(y)) for x, y in pts) + "],[" + \
           ",".join("[" + ",".join(str(i) for i in pa) + "]" for pa in paths) + "]]"

lua = []
scad = []
lua.append("-- made by parts/make-geometry.py: do not edit (cm, kg; the machine's frame, y up)")
lua.append("local G = {}")
consts = dict(C=C, PIN_R=PIN_R, RHO=RHO, HOLE_R=HOLE_R, AXLE_R=AXLE_R, BORE_R=BORE_R, SHAFT_R=SHAFT_R,
              STAR_T=STAR_T, ARM_T=ARM_T, LEVEL=LEVEL, BASE_TOP=BASE_TOP, Y0=Y0, PROBE_R=PROBE_R,
              FOLLOW_R=FOLLOW_R, CAM_RF=CAM_RF, CAM_IN=CAM_IN, CAM_OUT=CAM_OUT, FOLLOW_OFF=FOLLOW_OFF,
              STACK_TOP=STACK_TOP, TIP_LOW=TIP_LOW, TIP_HIGH=TIP_HIGH, CAM_LO=CAM_LO, CAM_HI=CAM_HI,
              CAM_BASE=CAM_BASE, SHAFT_TOP=SHAFT_TOP, GUIDE_Y0=GUIDE_Y0, GUIDE_Y1=GUIDE_Y1,
              PROBE_LEN=PROBE_LEN, SLOT_HW=SLOT_HW, LOCK_GAP=LOCK_GAP)
for k, v in consts.items():
    lua.append("G.%s = %s" % (k, fmt(v)))
    scad.append("%s = %s;" % (k, fmt(v)))
lua.append("G.MODS = {" + ",".join(str(m) for m in MODS) + "}")
scad.append("MODS = [" + ",".join(str(m) for m in MODS) + "];")
scad.insert(0, "// made by make-geometry.py: do not edit (cm)")
lua.append("G.RISE = {%s, %s}; G.FALL = {%s, %s}" % (RISE[0], RISE[1], FALL[0], FALL[1]))

# the wheels
lua.append("G.wheels = {}")
scad_stars, scad_holes = [], []
for i, m in enumerate(MODS):
    a, b, lockR = geneva(m)
    st = star(m)
    y0, y1 = star_y(i), star_y(i) + STAR_T
    pieces = convex_pieces(star(m, coarse=True))
    inert = plate_inertia(st, y0, y1, PLA)
    M, com, I = combine([inert])
    hc = hole_centres(m)
    lua.append("G.wheels[%d] = { m = %d, y0 = %s, y1 = %s, a = %s, b = %s, lockR = %s," %
               (i + 1, m, fmt(y0), fmt(y1), fmt(a), fmt(b), fmt(lockR)))
    lua.append("  mass = %.5f, com = {%s, %s, %s}, inertia = {%.6f, %.6f, %.6f}," %
               (M, fmt(com[0]), fmt(com[1]), fmt(com[2]), I[0], I[1], I[2]))
    lua.append("  holes = {" + ",".join("{%s,%s}" % (fmt(x), fmt(-y)) for x, y in hc) + "},   -- (x, z)")
    lua.append("  pieces = {\n    " + ",\n    ".join(lua_pieces(pieces, y0, y1)) + " } }")
    scad_stars.append(scad_poly(st))
    print("wheel %d: %d convex pieces, %.1f g, a %.3f b %.3f lock %.3f" % (m, len(pieces), M * 1000, a, b, lockR))
scad.append("STARS = [\n" + ",\n".join(scad_stars) + "];")

# the detents: for each wheel, the slot whose mouth is nearest the far side
# (180 degrees in the plan) at rest; the nose there; the leaf's root along the
# tangent, toward +Y in the plan
lua.append("G.detents = {}")
sdet = []
for i, m in enumerate(MODS):
    a, b, lockR = geneva(m)
    d = 360.0 / m
    angs = [d / 2 + k * d for k in range(m)]
    th = min(angs, key=lambda t: abs(((t - 180) + 180) % 360 - 180))
    u = (math.cos(math.radians(th)), math.sin(math.radians(th)))
    t = (-u[1], u[0])                                   # the tangent (a right-handed quarter turn)
    # (in from outside along the slot's axis until the nose meets the star:
    # the corners are where the slot's sides meet what the locking arcs leave)
    st = star(m, holes=False, coarse=True)
    dist = b + DET_NR + 0.5
    while circle(dist * u[0], dist * u[1], DET_NR, 3).distance(st) > 0.0005: dist -= 0.0005
    nx, ny = dist * u[0], dist * u[1]
    off = DET_NR - DET_T / 2                            # (the leaf runs along the nose's back)
    rx, ry = nx + DET_L * t[0] + off * u[0], ny + DET_L * t[1] + off * u[1]
    y0, y1 = star_y(i), star_y(i) + STAR_T
    lm = PLA * (DET_L * DET_T * STAR_T) + PLA * math.pi * DET_NR ** 2 * STAR_T
    print("  detent for %d: its nose %.3f out, the star's outer radius %.3f" % (m, dist, b))
    lua.append("G.detents[%d] = { angle = %s, nose = {%s, %s}, root = {%s, %s}, y0 = %s, y1 = %s, mass = %.6f }   -- (x, z)" %
               (i + 1, fmt(th), fmt(nx), fmt(-ny), fmt(rx), fmt(-ry), fmt(y0), fmt(y1), lm))
    sdet.append("[[%s,%s],[%s,%s]]" % (fmt(nx), fmt(ny), fmt(rx), fmt(ry)))
E = 3.5e9 * 1e-4 / 1e4 * 1e4      # PLA's modulus, 3.5 GPa, in kg/(cm s^2): 3.5e9 Pa = 3.5e9 kg/(m s^2) = 3.5e7 kg/(cm s^2)
E = 3.5e7
I = STAR_T * DET_T ** 3 / 12      # the leaf's section (cm^4)
K = 3 * E * I / DET_L             # at its root: torque per radian (kg cm^2/s^2), 3EI/L
lua.append("G.DET_K = %.3f   -- the leaf's stiffness at its root, 3EI/L, PLA 3.5 GPa (kg cm^2 / s^2 per radian)" % K)
for k_, v_ in dict(DET_NR=DET_NR, DET_L=DET_L, DET_T=DET_T, DET_PRE=DET_PRE, DET_STOP=DET_STOP).items():
    lua.append("G.%s = %s" % (k_, fmt(v_)))
    scad.append("%s = %s;" % (k_, fmt(v_)))
scad.append("DETENTS = [" + ",".join(sdet) + "];   // [nose, root] in the plan, at rest")
print("detents: leaf stiffness %.1f kg cm^2/s^2 a radian" % K)

# the drive: the shaft, and for each wheel a crank (arm and pin) under it and
# a locking disc beside it; the cam at the top. Machine frame: its axis at
# x = C, z = 0; the pins point to +x at rest
lua.append("G.drive = { pieces = {}, cylinders = {} }")
drive_parts = []
dp = []          # lua piece strings
cyls = []        # (r, y0, y1, x, z)
locks = []
cyls.append((SHAFT_R, BASE_TOP - 1.8, SHAFT_TOP, C, 0.0))
drive_parts.append(cyl_inertia(SHAFT_R, BASE_TOP - 1.8, SHAFT_TOP, C, 0.0, STEEL))
for i, m in enumerate(MODS):
    a, b, lockR = geneva(m)
    ya0, ya1 = crank_y(i), crank_y(i) + ARM_T
    ys0, ys1 = star_y(i), star_y(i) + STAR_T
    arm = box(-0.7, -0.55, a + 0.55, 0.55).union(circle(0, 0, 0.75, 10)).union(circle(a, 0, 0.55, 10))
    for pc in convex_pieces(arm):
        dp += lua_pieces([pc], ya0, ya1, C)
    drive_parts.append(plate_inertia(arm, ya0, ya1, PLA, C))
    cyls.append((PIN_R, ya0, ys1, C + a, 0.0))
    drive_parts.append(cyl_inertia(PIN_R, ya0, ys1, C + a, 0.0, STEEL))
    ld = lock_disc(m)
    lpcs = convex_pieces(ld)
    dp += lua_pieces(lpcs, ys0, ys1, C)
    drive_parts.append(plate_inertia(ld, ys0, ys1, PLA, C))
    locks.append(scad_poly(ld))
    print("drive, wheel %d: arm, pin, locking disc in %d pieces" % (m, len(lpcs)))
# the cam: a ring of wedges, each one's top following the profile; the
# follower sits at the cam's angle 180 - phi (it is at -x from the shaft)
NW = 72
cam_rows = []
for k in range(NW):
    t0, t1 = 360.0 * k / NW, 360.0 * (k + 1) / NW
    h0, h1 = cam_height(180 - t0), cam_height(180 - t1)
    pts = []
    for t, h in ((t0, h0), (t1, h1)):
        for r in (CAM_IN, CAM_OUT):
            X, Y = r * math.cos(math.radians(t)), r * math.sin(math.radians(t))
            pts += [fmt(C + X), fmt(CAM_BASE), fmt(-Y), fmt(C + X), fmt(h), fmt(-Y)]
    dp.append("{" + ",".join(pts) + "}")
    cam_rows.append("[%s,%s]" % (fmt(t0), fmt(h0)))
cam_ring = circle(0, 0, CAM_OUT, 2).difference(circle(0, 0, CAM_IN, 2))
drive_parts.append(plate_inertia(cam_ring, CAM_BASE, (CAM_LO + CAM_HI) / 2, PLA, C))
M, com, I = combine(drive_parts)
lua.append("G.drive.mass = %.5f; G.drive.com = {%s, %s, %s}; G.drive.inertia = {%.6f, %.6f, %.6f}" %
           (M, fmt(com[0]), fmt(com[1]), fmt(com[2]), I[0], I[1], I[2]))
lua.append("G.drive.pieces = {\n  " + ",\n  ".join(dp) + " }")
lua.append("G.drive.cylinders = {" + ",".join("{%s,%s,%s,%s,%s}" % tuple(fmt(v) for v in c) for c in cyls) + "}   -- r, y0, y1, x, z")
print("drive: %.1f g, centre of mass %.3f %.3f %.3f" % (M * 1000, com[0], com[1], com[2]))
scad.append("LOCKS = [\n" + ",\n".join(locks) + "];")
scad.append("CAM = [" + ",".join(cam_rows) + "];   // [angle in the cam's plan, the top's height]")
scad.append("CAM_NW = %d;" % NW)

# the probe: a steel rod, its arm (printed) and the follower ball, at the
# reading place x = -RHO; frame: its tip at TIP_HIGH
xp = -RHO
xf = C - CAM_RF
parts = [cyl_inertia(PROBE_R, TIP_HIGH, TIP_HIGH + PROBE_LEN, xp, 0, STEEL)]
yf = TIP_HIGH + FOLLOW_OFF + FOLLOW_R      # the follower's centre
parts.append((STEEL * 4 / 3 * math.pi * FOLLOW_R ** 3, (xf, yf, 0), (0.4 * STEEL * 4 / 3 * math.pi * FOLLOW_R ** 5,) * 3))
armL = xf - xp + 1.2
am = PLA * armL * 0.8 * 0.6
parts.append((am, ((xp + xf) / 2, yf + 0.1, 0), (am * (0.8 ** 2 + 0.6 ** 2) / 12, am * (armL ** 2 + 0.8 ** 2) / 12, am * (armL ** 2 + 0.6 ** 2) / 12)))
M, com, I = combine(parts)
lua.append("G.probe = { x = %s, xf = %s, yf = %s, mass = %.5f, com = {%s, %s, %s}, inertia = {%.6f, %.6f, %.6f} }" %
           (fmt(xp), fmt(xf), fmt(yf), M, fmt(com[0]), fmt(com[1]), fmt(com[2]), I[0], I[1], I[2]))
print("probe: %.1f g" % (M * 1000))
lua.append("return G")

open("geometry.scad", "w").write("\n".join(scad) + "\n")
open("../sieve-geometry.lua", "w").write("\n".join(lua) + "\n")
print("wrote geometry.scad and ../sieve-geometry.lua")
