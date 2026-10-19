"""Core geometry / exact mass properties / equilibrium margins for PLA-only
monostable polyhedra (stack of aligned regular k-gon rings + apex).

Units: cm, g (density g/cm^3).  Body frame: z up, base plane z = 0.

Mass model (all EXACT polyhedral volume integrals, no sampling):
  solid = Outer  minus  Void
  Outer = convex hull of the vertices
  Void  = {x : n_f.x + d_f + t <= 0 for every outer face f}  (inner offset by
          the wall thickness t, measured normal to each face)
        & {z >= zs}                                           (solid slab below)
  Both are convex polytopes -> exact volume, first and second moments by
  tetrahedral decomposition.
"""
import numpy as np
from scipy.spatial import ConvexHull, HalfspaceIntersection
from scipy.optimize import linprog, nnls

RHO = 1.24  # g/cm^3, PLA

# ---------------------------------------------------------------- geometry
def ring_verts(k, R, Z, H, twist=None):
    """apex (0,0,H) first, then rings i=0..n-1 (i=0 = base ring at Z[0])."""
    V = [(0.0, 0.0, H)]
    for i, (r, z) in enumerate(zip(R, Z)):
        ph0 = 0.0 if twist is None else twist[i]
        for j in range(k):
            ph = ph0 + 2 * np.pi * j / k
            V.append((r * np.cos(ph), r * np.sin(ph), z))
    return np.array(V)

def faces_of(V, tol=1e-6):
    """merged hull faces: list of (normal, offset, vertex-index list ordered ccw)"""
    H = ConvexHull(V)
    groups = {}
    for s, e in zip(H.simplices, H.equations):
        # merge by plane
        key = None
        for kk, (ee, ss) in groups.items():
            if np.abs(ee[:3] @ e[:3] - 1) < tol and abs(ee[3] - e[3]) < tol * 10:
                key = kk; break
        if key is None:
            key = len(groups); groups[key] = (e, set())
        groups[key][1].update(s)
    out = []
    for e, ss in groups.values():
        n = e[:3] / np.linalg.norm(e[:3]); d = e[3]
        idx = np.array(sorted(ss))
        P = V[idx]; c = P.mean(0)
        u = np.cross(n, [1, 0, 0]);
        if np.linalg.norm(u) < 1e-6: u = np.cross(n, [0, 1, 0])
        u /= np.linalg.norm(u); w = np.cross(n, u)
        q = np.c_[(P - c) @ u, (P - c) @ w]
        if len(P) > 3:
            h2 = ConvexHull(q)            # drop points interior to the face; ccw order about n
            out.append((n, d, idx[h2.vertices]))
        else:
            ang = np.arctan2(q[:, 1], q[:, 0])
            out.append((n, d, idx[np.argsort(ang)]))
    return out, H

# ---------------------------------------------------------- mass properties
def tet_moments(p0, a, b, c):
    """volume (signed), first moment, second moment tensor of tetra p0abc"""
    v6 = np.einsum('ij,ij->i', a - p0, np.cross(b - p0, c - p0))
    vol = v6 / 6
    s = p0 + a + b + c
    m1 = (vol[:, None] * s / 4).sum(0)
    S = (np.einsum('i,ij,ik->jk', vol, s, s) + np.einsum('i,ij,ik->jk', vol, a, a)
         + np.einsum('i,ij,ik->jk', vol, b, b) + np.einsum('i,ij,ik->jk', vol, c, c)
         + np.einsum('i,j,k->jk', vol, p0, p0)) / 20
    return vol.sum(), m1, S

def convex_props(P):
    """exact (vol, first moment, second moment) of the convex hull of points P"""
    H = ConvexHull(P)
    p0 = P[H.vertices].mean(0)
    s = H.simplices.copy()
    a, b, c = P[s[:, 0]], P[s[:, 1]], P[s[:, 2]]
    nrm = np.cross(b - a, c - a)
    flip = np.einsum('ij,ij->i', nrm, H.equations[:, :3]) < 0
    b2 = np.where(flip[:, None], c, b); c2 = np.where(flip[:, None], b, c)
    return tet_moments(p0, a, b2, c2)

def halfspace_poly(A, b):
    """vertices of {x: A x + b <= 0}; None if empty/degenerate"""
    # Chebyshev centre
    nrm = np.linalg.norm(A, axis=1)
    res = linprog(np.r_[0, 0, 0, -1], A_ub=np.c_[A, nrm], b_ub=-b,
                  bounds=[(None, None)] * 3 + [(0, None)], method='highs')
    if res.status != 0 or res.x[3] < 1e-5: return None
    hs = HalfspaceIntersection(np.c_[A, b], res.x[:3])
    P = hs.intersections
    P = P[np.all(np.isfinite(P), axis=1)]
    return P

def void_poly(faces, t, zs, extra=None):
    A = [f[0] for f in faces]; b = [f[1] + t for f in faces]
    A.append(np.array([0, 0, -1.0])); b.append(zs)
    if extra is not None:
        for (aa, bb) in extra: A.append(aa); b.append(bb)
    return halfspace_poly(np.array(A), np.array(b))

def mass_props(V, faces, t, zs, rho=RHO, void=None):
    """exact mass (g), COM, inertia tensor about COM (g cm^2) of hull(V) minus void"""
    vo, m1o, So = convex_props(V)
    if void is None: void = void_poly(faces, t, zs)
    if void is not None and len(void) >= 4:
        vv, m1v, Sv = convex_props(void)
    else:
        vv, m1v, Sv = 0.0, np.zeros(3), np.zeros((3, 3))
    vol = vo - vv; m1 = m1o - m1v; S = So - Sv
    M = rho * vol; com = m1 / vol
    Sc = rho * (S - vol * np.outer(com, com))
    I = np.trace(Sc) * np.eye(3) - Sc
    return dict(M=M, com=com, I=I, vol=vol, void_vol=vv, outer_vol=vo, void=void)

# ------------------------------------------------------------ margins
def seg_dist(p, a, b):
    ab = b - a; s = np.clip((p - a) @ ab / (ab @ ab), 0, 1)
    return np.linalg.norm(p - a - s * ab)

def face_margin(V, n, d, idx, c):
    """signed distance (cm) of the COM foot from the face polygon:
    > 0 outside (face not an equilibrium), < 0 inside (depth)."""
    p = c - (n @ c + d) * n
    P = V[idx]; L = len(P)
    inside = True
    for i in range(L):
        a, b = P[i], P[(i + 1) % L]
        if np.cross(b - a, p - a) @ n < 0: inside = False
    dist = min(seg_dist(p, P[i], P[(i + 1) % L]) for i in range(L))
    return -dist if inside else dist

def vertex_cone_dist(v, normals, c):
    """distance from COM c to the set of COM positions that make v an
    equilibrium (cone v - N(v)); 0 if v is one."""
    N = np.array(normals).T
    _, r = nnls(N, v - c)
    return r

def margins(V, faces, c, base_i, apex_i):
    """dict: per-face signed margins (cm), per-vertex margins (cm)"""
    fm = []
    for i, (n, d, idx) in enumerate(faces):
        m = face_margin(V, n, d, idx, c)
        fm.append(m)
    vnorm = {}
    for (n, d, idx) in faces:
        for j in idx: vnorm.setdefault(j, []).append(n)
    vm = {}
    for j, ns in vnorm.items():
        vm[j] = vertex_cone_dist(V[j], ns, c)
    return np.array(fm), vm

def summary_margin(V, faces, c, base_i, apex_i):
    fm, vm = margins(V, faces, c, base_i, apex_i)
    other_f = np.delete(fm, base_i)
    other_v = [m for j, m in vm.items() if j != apex_i]
    return dict(face=other_f.min(), vert=min(other_v), base=-fm[base_i],
                apex_is_eq=vm[apex_i] < 1e-12, fm=fm, vm=vm)

def equilibria(V, faces, c):
    """exact count: faces whose foot is inside, vertices whose cone contains c"""
    st = [i for i, (n, d, idx) in enumerate(faces) if face_margin(V, n, d, idx, c) < 0]
    vnorm = {}
    for (n, d, idx) in faces:
        for j in idx: vnorm.setdefault(j, []).append(n)
    un = [j for j, ns in vnorm.items() if vertex_cone_dist(V[j], ns, c) < 1e-12]
    return st, un
