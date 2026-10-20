#!/usr/bin/env python3
"""Gomboc-C's collision hull and render mesh, from the GOMBOC900 STEP file.

  python3 gen_hull.py GOMBOC900.STEP check-old OLD_HULL_LUA OLD_OBJ
      re-makes the hull points and render mesh of before 19 Oct 2026 and
      compares them, text for text, with the given files
  python3 gen_hull.py GOMBOC900.STEP build OUTDIR [EPS_DEG, default 0.75]
      writes OUTDIR/gomboc-hull.lua and OUTDIR/gomboc.obj (the current ones)

Needs Python 3, numpy, scipy, gmsh (PyPI 4.15.2: its OpenCASCADE reads the
STEP and meshes it) and OCP (PyPI cadquery-ocp 8.0.1: mass properties).
See README.txt.
"""
import sys
import numpy as np
import gmsh
from scipy.spatial import ConvexHull

MESH_MM = 12.0          # gmsh Mesh.MeshSizeMax, CAD mm (1.2 mm at 9 cm)
CM_PER_MM = 0.01        # the 900 mm CAD body -> 9 cm, in cm

# ruling design (see README.txt): for every rolling lever arm up to
# DELTA_MAX_CM at every size down to S_MIN, the hull holds a tilt about the
# trough at most EPS beyond the smooth cylinder's bound, and nowhere else
DELTA_MAX_CM = 0.030    # 300 microns, the top of the "rolling" slider
S_MIN = 0.75            # smallest size in Gomboc Variety
SAFETY = 0.5            # spacing at most half of what would just allow a hold
EPS_DEG = 0.75          # the finest spacing that keeps every ruling a hull
                        # vertex in single precision (Bullet's): see README.txt


def mass_properties(step, eps):
    """volume (mm^3), centre of mass (mm), inertia/volume about it (mm^2).
    eps=None is OpenCASCADE's default (fixed-order) integration, which the
    files before 19 Oct 2026 used; eps=1e-9 is converged."""
    from OCP.STEPControl import STEPControl_Reader
    from OCP.GProp import GProp_GProps
    from OCP.BRepGProp import BRepGProp
    r = STEPControl_Reader()
    r.ReadFile(step)
    r.TransferRoots()
    sh = r.OneShape()
    g = GProp_GProps()
    if eps is None:
        BRepGProp.VolumeProperties_s(sh, g)
    else:
        BRepGProp.VolumeProperties_s(sh, g, eps)
    c = g.CentreOfMass()
    M = g.MatrixOfInertia()
    m = g.Mass()
    I = np.array([[M.Value(i, j) for j in (1, 2, 3)] for i in (1, 2, 3)]) / m
    return m, np.array([c.X(), c.Y(), c.Z()]), I


def to_body(X, com):
    """CAD mm -> body cm: 9 cm, COM at the origin, upright = +y
    (resting point straight down, balancing point up)."""
    X = np.asarray(X, float).reshape(-1, 3) - com
    return np.c_[-X[:, 1], X[:, 0], X[:, 2]] * CM_PER_MM


def mesh(step):
    """the 12 mm gmsh surface mesh: nodes (tag order), triangles (0-based,
    entity order), the interior node indices of the bottom cylinder, and that
    cylinder's face tag."""
    gmsh.initialize()
    gmsh.option.setNumber("General.Terminal", 0)
    gmsh.option.setNumber("Mesh.MeshSizeMax", MESH_MM)
    gmsh.open(step)
    gmsh.model.mesh.generate(2)
    tags, xyz, _ = gmsh.model.mesh.getNodes()
    assert tags[0] == 1 and tags[-1] == len(tags) and np.all(np.diff(tags) == 1)
    X = xyz.reshape(-1, 3)
    T = []
    for d, t in gmsh.model.getEntities(2):
        _, _, en = gmsh.model.mesh.getElements(2, t)
        T.append(np.array(en[0], int).reshape(-1, 3) - 1)
    T = np.concatenate(T)
    # the bottom cylinder: the cylindrical face holding the lowest point (min CAD x)
    low = X[:, 0].argmin()
    cyl = None
    for d, t in gmsh.model.getEntities(2):
        if gmsh.model.getType(d, t) != "Cylinder":
            continue
        nt, _, _ = gmsh.model.mesh.getNodes(2, t, True)
        if low + 1 in set(nt.tolist()):
            cyl = t
    inner, _, _ = gmsh.model.mesh.getNodes(2, cyl, False)
    return X, T, np.array(inner, int) - 1, cyl


def fmt(v, nd=6):
    s = "%.*f" % (nd, v)
    return s[1:] if s.lstrip("-0.") == "" and s[0] == "-" else s


# ---------------------------------------------------------------------------
# the files as they were before 19 Oct 2026
# ---------------------------------------------------------------------------

def old_files(step):
    _, com, _ = mass_properties(step, None)
    X, T, _, _ = mesh(step)
    gmsh.finalize()
    # hull vertices of the mesh, in metres (body 0.9 m), rounded to 1 micron
    H = np.round((X[ConvexHull(X).vertices] - com) / 1000.0, 6)
    # the hull of those, then the axes turned and scaled to 9 cm
    H = H[ConvexHull(H).vertices]
    P = np.c_[-10 * H[:, 1], 10 * H[:, 0], 10 * H[:, 2]]
    pts = ["    %.6f,%.6f,%.6f," % tuple(p) for p in P]
    V = to_body(X, com)
    obj = ["v %.6f %.6f %.6f" % tuple(v) for v in V] + ["f %d %d %d" % tuple(t + 1) for t in T]
    return pts, obj


def check_old(step, old_lua, old_obj):
    pts, obj = old_files(step)
    s = open(old_lua, encoding="utf-8").read().split("\n")
    i0 = s.index("  points = {") + 1
    lua_pts = s[i0:i0 + len(pts)]
    ok1 = lua_pts == pts and s[i0 + len(pts)] == "  },"
    o = [l for l in open(old_obj, encoding="utf-8").read().split("\n") if l[:2] in ("v ", "f ")]
    ok2 = o == obj
    print("hull points: %d made, %s" % (len(pts), "IDENTICAL to " + old_lua if ok1 else "DIFFERENT"))
    print("render mesh: %d lines made, %s" % (len(obj), "IDENTICAL to " + old_obj if ok2 else "DIFFERENT"))
    return ok1 and ok2


# ---------------------------------------------------------------------------
# the current files
# ---------------------------------------------------------------------------

def rulings(cyl, com, eps_deg):
    """ruling end points of the bottom cylinder, in body cm, plus a summary."""
    (u0, v0), (u1, v1) = [tuple(b) for b in np.array(gmsh.model.getParametrizationBounds(2, cyl))]
    ev = lambda u, v: to_body(gmsh.model.getValue(2, cyl, [u, v]), com)[0]
    # the circle's centre and radius, from three points of a cross-section
    a, b, c = ev(u0, 0.0), ev(0.5 * (u0 + u1), 0.0), ev(u1, 0.0)
    um = 0.5 * (u0 + u1)                  # parameter of the lowest ruling
    assert abs(b[1] - min(a[1], c[1])) > 1  # (b is the bottom)
    # circumcentre in the y-z plane (the axis runs along body x)
    A = np.array([[a[1], a[2]], [b[1], b[2]], [c[1], c[2]]])
    M = 2 * np.array([A[1] - A[0], A[2] - A[0]])
    r = np.array([A[1] @ A[1] - A[0] @ A[0], A[2] @ A[2] - A[0] @ A[0]])
    cy, cz = np.linalg.solve(M, r)
    rho = np.hypot(A[0, 0] - cy, A[0, 1] - cz)
    d = np.hypot(cy, cz)                  # COM to axis
    eps = np.radians(eps_deg)
    dlim = DELTA_MAX_CM / S_MIN

    def step(psi):
        de = 2 * d * np.cos(psi) * eps / rho                    # tilt bound + eps
        dn = SAFETY * 2 * max(0.0, d * np.sin(abs(psi)) - dlim) / rho   # no hold at all
        return min(MESH_MM / (rho / CM_PER_MM), max(de, dn))    # never coarser than 12 mm
    half = 0.5 * (u1 - u0)
    psis = [0.0]
    while True:
        p = psis[-1]
        h = step(p)
        h = min(h, step(p + h))
        if p + h >= half - 1e-12:
            break
        psis.append(p + h)
    if half - psis[-1] < 0.5 * step(psis[-1]) and len(psis) > 1:
        psis.pop()
    psis.append(half)
    psis = np.array(psis)
    psis = np.concatenate([-psis[:0:-1], psis])
    U = um + psis
    ends = []
    for u in U:
        ends.append(ev(u, v0))
        ends.append(ev(u, v1))
    return np.array(ends), U, dict(rho=rho, d=d, n=len(U), psis=psis)


def new_files(step, eps_deg):
    vol, com, I = mass_properties(step, 1e-9)
    X, T, inner, cyl = mesh(step)
    keep = np.ones(len(X), bool)
    keep[inner] = False                   # the cylinder's inside nodes ...
    R, U, info = rulings(cyl, com, eps_deg)   # ... are replaced by whole rulings
    # nodes of the 12 mm mesh on the cylinder's edges get a partner on the other
    # edge, so that every point there is the end of a whole ruling
    bnd, _, _ = gmsh.model.mesh.getNodes(2, cyl, True)
    bnd = np.setdiff1d(np.array(bnd, int) - 1, inner)
    (u0, v0), (u1, v1) = [tuple(b) for b in np.array(gmsh.model.getParametrizationBounds(2, cyl))]
    uv = np.array(gmsh.model.getParametrization(2, cyl, X[bnd].ravel())).reshape(-1, 2)
    extra = []
    for (u, v) in uv:
        if abs(v - v0) < 1e-6 or abs(v - v1) < 1e-6:
            if np.min(np.abs(U - u)) > 1e-9:
                extra.append(to_body(gmsh.model.getValue(2, cyl, [u, v1 if abs(v - v0) < 1e-6 else v0]), com)[0])
    B = to_body(X[keep], com)
    P = np.vstack([B, R] + ([np.array(extra)] if extra else []))
    gmsh.finalize()
    P = P[ConvexHull(P).vertices]
    # written with 7 decimals (0.001 micron); Bullet (single precision) reads
    # them as 32-bit floats, so keep only the vertices of the hull of those
    P = np.array([[float(fmt(c, 7)) for c in p] for p in P])
    P = P[ConvexHull(P.astype(np.float32).astype(np.float64)).vertices]
    V = to_body(X, com)
    K2 = np.array([I[1, 1], I[0, 0], I[2, 2]]) * CM_PER_MM ** 2   # body x, y, z
    info.update(volume=vol * CM_PER_MM ** 3, com=com, K2=K2, extra=len(extra),
                rest=-P[:, 1].min(), top=P[:, 1].max(), I=I)
    return P, V, T, info


HEADER = """-- Collision hull for gomboc.obj: GOMBOC900, a SolidWorks 2010 CAD model by Kiss Attila
-- (organisation 'e.v.', 12 Dec 2013, per the STEP file's header), published as
-- "Gömböc" Convex, homogeneous three-dimensional body by Istenes József on GrabCAD
-- on 5 December 2024: https://grabcad.com/library/gomboc-convex-homogeneous-three-dimensional-body-1
-- (licence not checked). Scaled to 9 cm, in cm, centred on the exact centre of
-- mass of the CAD solid, upright = local +y up (stable resting point straight
-- down, unstable tip up).
--
-- Made from the STEP file by ../hull-reconstruction/gen_hull.py (see its
-- README.txt). Every point lies on the CAD surfaces. The points are the hull
-- vertices of a 1.2 mm (at 9 cm) tessellation of every surface except the
-- bottom cylinder the gomboc rests and rocks on (radius 3.6 cm, axis along x,
-- %(d).4f cm above the centre of mass), plus %(n)d whole straight lines
-- (rulings) across that cylinder, end to end: %(w0).0f microns apart at the
-- bottom, wider further up. So rolling resistance (lever arm up to 300
-- microns, sizes 75-125%%) can hold a tilt about x at most %(exc).2f deg beyond
-- where the smooth cylinder would (checked). The hull's only resting faces are
-- %(nf)d strips within %(fmax).2f deg of upright, the deepest needing a %(dmax).4f micron
-- lift to leave. Before 19 Oct 2026 the bottom was 1.2 mm facets too: 13,476
-- points, 34 resting faces out to 16.3 deg, holding bands out to 21 deg.
-- volume (cm^3), restHeight/topHeight (cm, COM to the lowest and highest
-- point), inertia = squared radii of gyration about local x, y, z (cm^2): exact
-- CAD (OpenCASCADE, converged integration).
"""


def write_files(outdir, P, V, T, info, stats):
    w0 = info["rho"] * abs(info["psis"][len(info["psis"]) // 2 + 1] - info["psis"][len(info["psis"]) // 2]) * 1e4
    head = HEADER % dict(d=info["d"], n=info["n"], w0=w0, exc=stats["exc"],
                         nf=stats["nf"], fmax=stats["fmax"], dmax=stats["dmax"])
    K = info["K2"]
    lines = [head.rstrip("\n"), "return {",
             "  size = 9.0, volume = %.3f," % info["volume"],
             "  restHeight = %.5f, topHeight = %.5f," % (info["rest"], info["top"]),
             "  inertia = { %.6f, %.6f, %.6f }," % tuple(K),
             "  points = {"]
    lines += ["    %s,%s,%s," % tuple(fmt(c, 7) for c in p) for p in P]
    lines += ["  },", "}", ""]
    open(outdir + "/gomboc-hull.lua", "w", encoding="utf-8").write("\n".join(lines))
    obj = ["# GOMBOC900 CAD (Kiss Attila 2013; GrabCAD 2024) 1.2 mm mesh, 9 cm, cm, CoM at origin, upright = +y"]
    obj += ["v %s %s %s" % tuple(fmt(c) for c in v) for v in V]
    obj += ["f %d %d %d" % tuple(t + 1) for t in T]
    open(outdir + "/gomboc.obj", "w", encoding="utf-8").write("\n".join(obj) + "\n")


if __name__ == "__main__":
    step, cmd = sys.argv[1], sys.argv[2]
    if cmd == "check-old":
        sys.exit(0 if check_old(step, sys.argv[3], sys.argv[4]) else 1)
    elif cmd == "build":
        import statics
        eps_deg = float(sys.argv[4]) if len(sys.argv) > 4 else EPS_DEG
        P, V, T, info = new_files(step, eps_deg)
        info["eps_deg"] = eps_deg
        st = statics.resting_faces(P.astype(np.float32).astype(np.float64))
        stats = dict(nf=len(st), fmax=max(f["tilt"] for f in st), dmax=max(f["lift_um"] for f in st))
        # the furthest tilt about x the hull can be held at, against the smooth cylinder
        deg, lev = statics.trough_scan(P.astype(np.float32).astype(np.float64), lim=60)
        exc = 0.0
        for delta in (0.0075, 0.015, 0.030):
            for sz in (0.75, 1.0, 1.25):
                far = max(max(abs(a), abs(b)) for a, b in statics.bands(deg, lev, sz, delta))
                exc = max(exc, far - statics.smooth_bound(sz, delta))
                print("delta %3.0f um, size %3.0f%%: smooth cylinder %.2f deg, hull %.2f deg"
                      % (delta * 1e4, sz * 100, statics.smooth_bound(sz, delta), far))
        stats["exc"] = exc
        print("points %d (rulings %d, partners %d), rho %.5f d %.6f, volume %.4f, rest %.5f top %.5f, K2 %s"
              % (len(P), info["n"], info["extra"], info["rho"], info["d"], info["volume"],
                 info["rest"], info["top"], info["K2"]))
        print("resting faces %d, max tilt %.3f deg, deepest %.4f um" % (stats["nf"], stats["fmax"], stats["dmax"]))
        write_files(sys.argv[3], P, V, T, info, stats)
