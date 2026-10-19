"""Weighted 37-corner monostable polyhedron for FDM printing (Conway (6,6)-spiral
after Domokos & Kovacs 2023): exact mass model of a PLA shell with a stock
weight in a pocket at every corner.

Units: mm, g.  Body frame: base face on z = 0, apex at (0,0,H), z = print up.

Geometry  x = [R0..R5, Z1..Z5, H]   (Z0 = 0: base ring; 6 rings of 6 aligned
corners, phase 0; apex on the axis).

Interior (all exact polyhedral / analytic volume integrals, no sampling):
  PLA   = Outer - Void - sum(pockets)
  Outer = hull(vertices)
  Void  = {n_f.x + d_f + t <= 0 for every outer face f}   (walls t thick)
          & {u_v.x <= c_v for every corner v}               (a solid PLA 'cap'
          behind every pocket: u_v = outward direction of the corner, tilted
          to <= 45 deg above horizontal so the cap's underside prints without
          support; c_v = (lowest u_v.x over the pocket) - t_cap)
          & {z >= zs}                                       (optional floor slab)
  Pocket = vertical cylinder (radius a, height L) [or square prism, side s],
          placed as close to its corner as the walls allow (exact 2D QP in the
          corner's mirror plane): every outer face >= t away from the pocket.
  Weight = sphere / cylinder / cube of the stock size, resting on the pocket
          floor (centre = floor + its half height), centred horizontally.
  Glue  = a CA drop (default 0.03 g) at the weight centre.
"""
import numpy as np
from core import faces_of, convex_props, halfspace_poly, margins, face_margin, vertex_cone_dist, equilibria

RHO_PLA = 1.24e-3   # g/mm^3
K = 6; NR = 6

def verts(x):
    R = x[:NR]; Z = np.r_[0.0, x[NR:2 * NR - 1]]; H = x[2 * NR - 1]
    V = [(0.0, 0.0, H)]
    for r, z in zip(R, Z):
        for j in range(K):
            ph = 2 * np.pi * j / K
            V.append((r * np.cos(ph), r * np.sin(ph), z))
    return np.array(V)

# ------------------------------------------------------------------ weights
class Weight:
    """stock weight. kind: 'sphere' (d), 'cyl' (d, l; axis vertical), 'cube' (s)
    mass m (g, nominal), clr: radial clearance of the pocket, clz: extra height"""
    def __init__(self, name, kind, dims, m, clr=0.15, clz=0.4):
        self.name, self.kind, self.dims, self.m, self.clr, self.clz = name, kind, dims, m, clr, clz
        if kind == 'sphere':
            d = dims[0]; self.h = d; self.a = d / 2 + clr; self.half = d / 2
            self.I0 = 0.1 * m * d * d * np.eye(3)            # 2/5 m r^2
            self.vol = np.pi * d ** 3 / 6
        elif kind == 'cyl':
            d, l = dims; self.h = l; self.a = d / 2 + clr; self.half = l / 2
            self.I0 = m * np.diag([d * d / 16 + l * l / 12, d * d / 16 + l * l / 12, d * d / 8])
            self.vol = np.pi * d * d / 4 * l
        elif kind == 'cube':
            s = dims[0]; self.h = s; self.a = s / 2 + clr; self.half = s / 2
            self.I0 = m * s * s / 6 * np.eye(3)
            self.vol = s ** 3
        self.L = self.h + clz                                # pocket height
        self.prism = (kind == 'cube')

    def support(self, n):
        """max of n.(p - pocket centre) over the pocket, for unit normals n (..,3)"""
        n = np.atleast_2d(n)
        if self.prism:   # square prism, sides along the corner's radial / tangential directions
            return self.a * (np.abs(n[:, 0]) + np.abs(n[:, 1])) + self.L / 2 * np.abs(n[:, 2])
        return self.a * np.hypot(n[:, 0], n[:, 1]) + self.L / 2 * np.abs(n[:, 2])

    def pocket_props(self, c):
        """exact (vol, first moment, second moment tensor) of the pocket void"""
        a, L = self.a, self.L
        if self.prism:
            s = 2 * a; v = s * s * L; J = v * np.diag([s * s / 12, s * s / 12, L * L / 12])
        else:
            v = np.pi * a * a * L; J = v * np.diag([a * a / 4, a * a / 4, L * L / 12])
        return v, v * c, J + v * np.outer(c, c)

# --------------------------------------------------------- pocket placement
def _qp2(target, G, h):
    """min |p-target|^2 s.t. G p <= h in 2D, exact by active-set enumeration
    (vectorised: every single constraint and every pair of constraints)"""
    if np.all(G @ target <= h + 1e-9): return target.copy()
    gg = (G * G).sum(1)
    Ps = target[None, :] - ((G @ target - h) / gg)[:, None] * G           # projections on each line
    i, j = np.triu_indices(len(G), 1)
    det = G[i, 0] * G[j, 1] - G[i, 1] * G[j, 0]
    k = np.abs(det) > 1e-12; i, j, det = i[k], j[k], det[k]
    px = (h[i] * G[j, 1] - G[i, 1] * h[j]) / det
    py = (G[i, 0] * h[j] - h[i] * G[j, 0]) / det
    C = np.r_[Ps, np.c_[px, py]]
    feas = np.all(C @ G.T <= h[None, :] + 1e-9, axis=1)
    if not feas.any(): return None
    C = C[feas]; d = np.linalg.norm(C - target, axis=1)
    return C[np.argmin(d)]

def place_pockets(V, faces, W, t, frame=None):
    """pocket centres (37,3), one per vertex, nearest to the corner with every outer
    face >= t from the pocket. Ring corners lie on mirror planes, so the optimum is
    in the plane (e_r, z): solve in 2D for one corner per ring and rotate."""
    nV = len(V)
    A = np.array([f[0] for f in faces]); d = np.array([f[1] for f in faces])
    P = np.zeros((nV, 3))
    # apex: on the axis, as high as allowed
    hz = W.support(A)
    lim = [(-d[i] - hz[i] - t) / A[i, 2] for i in range(len(A)) if A[i, 2] > 1e-9]
    P[0] = (0, 0, min(lim))
    lo = [(-d[i] - hz[i] - t) / A[i, 2] for i in range(len(A)) if A[i, 2] < -1e-9]
    if P[0, 2] < max(lo): return None
    for v in range(1, nV, K):
        r = np.hypot(V[v, 0], V[v, 1]); ph = np.arctan2(V[v, 1], V[v, 0])
        er = np.array([np.cos(ph), np.sin(ph), 0.0])
        # in the mirror plane, the pocket's support depends on n's components; use the
        # full 3D normal for the support but only (n.er, n_z) for the position
        if W.prism:   # rotate normals into the corner's frame (prism sides radial/tangential)
            et = np.array([-np.sin(ph), np.cos(ph), 0.0])
            An = np.c_[A @ er, A @ et, A[:, 2]]; hs = W.support(An)
        else:
            hs = W.support(A)
        G = np.c_[A @ er, A[:, 2]]; h = -d - hs - t
        p = _qp2(np.array([r, V[v, 2]]), G, h)
        if p is None: return None
        for j in range(K):
            pj = ph + 2 * np.pi * j / K
            P[v + j] = (p[0] * np.cos(pj), p[0] * np.sin(pj), p[1])
    return P

def pocket_clearance(P, W):
    """smallest gap (mm) between any two pockets (vertical cylinders/prisms; prisms
    treated by their circumscribed cylinder: conservative)"""
    a = W.a * (np.sqrt(2) if W.prism else 1.0); L = W.L
    dxy = np.hypot(P[:, None, 0] - P[None, :, 0], P[:, None, 1] - P[None, :, 1])
    if W.prism:   # prisms on the same radial line (same azimuth): exact radial separation
        ph = np.arctan2(P[:, 1], P[:, 0]); rr = np.hypot(P[:, 0], P[:, 1])
        same = (np.abs(np.angle(np.exp(1j * (ph[:, None] - ph[None, :])))) < 1e-6) & (rr[:, None] > 1e-6) & (rr[None, :] > 1e-6)
        dxy = np.where(same, dxy - 2 * W.a + 2 * a, dxy)
    dz = np.abs(P[:, None, 2] - P[None, :, 2])
    sep = np.maximum(dxy - 2 * a, dz - L)
    np.fill_diagonal(sep, 1e9)
    return sep.min(), sep

# ------------------------------------------------------------- bosses
SQ2 = np.sqrt(2.0)
def boss_halfspaces(P, W, tb, nV):
    """For every pocket, the halfspaces (A x + b <= 0) of its solid PLA boss
    B_v (before intersecting with the shell's inner region):
      ring corner: a block around the pocket, tb thick on all four vertical sides
        (radial in/out, two lateral) and on its top; its underside a 45 deg chamfer
        running down-outward from the pocket wall's inner-bottom edge (prints without
        support); clipped by the shell's inner surface.
      apex: everything above an upward-opening 45 deg hexagonal cone just below
        the pocket (prints without support)."""
    out = []
    a, L = W.a, W.L
    w = a + tb
    for i in range(nV):
        p = P[i]
        if i == 0:
            zb = p[2] - L / 2 - tb; z0 = zb - w
            A = []; b = []
            for k in range(6):
                ph = k * np.pi / 3; e = np.array([np.cos(ph), np.sin(ph), 0.0])
                n = (e - np.array([0, 0, 1.0])) / SQ2      # e.x - z + z0 <= 0
                A.append(n); b.append(z0 / SQ2)
            out.append((np.array(A), np.array(b)))
            continue
        ph = np.arctan2(p[1], p[0]); rho = np.hypot(p[0], p[1])
        er = np.array([np.cos(ph), np.sin(ph), 0.0]); et = np.array([-np.sin(ph), np.cos(ph), 0.0]); ez = np.array([0, 0, 1.0])
        r0 = rho - a - tb; z0 = p[2] - L / 2 - tb; ztop = p[2] + L / 2 + tb
        A = [-er, er, et, -et, ez, -(er + ez) / SQ2]
        b = [r0, -(rho + a + tb), -w, -w, -ztop, (r0 + z0) / SQ2]
        out.append((np.array(A), np.array(b)))
    return out

def union_props(base_A, base_b, regions, cache_pairs=None):
    """exact (vol, m1, S) of the union of convex regions Q_i = {base} & region_i,
    by inclusion-exclusion over every intersecting subset (cliques)."""
    n = len(regions)
    Q = []
    for (A, b) in regions:
        P = halfspace_poly(np.r_[base_A, A], np.r_[base_b, b])
        Q.append(P)
    vol = 0.0; m1 = np.zeros(3); S = np.zeros((3, 3))
    single = []
    for i, P in enumerate(Q):
        if P is None or len(P) < 4: single.append(None); continue
        v, a1, a2 = convex_props(P); vol += v; m1 += a1; S += a2
        single.append((P.min(0), P.max(0)))
    # pairwise candidates by bounding boxes
    idx = [i for i in range(n) if single[i] is not None]
    adj = {i: set() for i in idx}
    pairs = []
    for ii, i in enumerate(idx):
        for j in idx[ii + 1:]:
            lo = np.maximum(single[i][0], single[j][0]); hi = np.minimum(single[i][1], single[j][1])
            if np.all(hi > lo + 1e-9):
                P = halfspace_poly(np.r_[base_A, regions[i][0], regions[j][0]], np.r_[base_b, regions[i][1], regions[j][1]])
                if P is not None and len(P) >= 4:
                    adj[i].add(j); adj[j].add(i); pairs.append((i, j))
    # cliques (subsets of size >= 2 whose regions all intersect), with signs
    def extend(clique, cands):
        nonlocal vol, m1, S
        for j in sorted(cands):
            if j <= clique[-1]: continue
            c2 = clique + [j]
            A = np.r_[base_A, np.concatenate([regions[k][0] for k in c2])]
            b = np.r_[base_b, np.concatenate([regions[k][1] for k in c2])]
            P = halfspace_poly(A, b)
            if P is None or len(P) < 4: continue
            v, a1, a2 = convex_props(P); sg = (-1) ** (len(c2) - 1)
            vol += sg * v; m1 += sg * a1; S += sg * a2
            extend(c2, cands & adj[j])
    for i in idx:
        extend([i], adj[i])
    return vol, m1, S, Q, pairs

# ------------------------------------------------------------- full model
class Body:
    def __init__(self, x, W, t=0.8, tb=0.8, zs=None, rho=RHO_PLA, glue=0.03, wm=None,
                 outerA=None, outerb=None, innerA=None, innerb=None, P=None, Wpos=None, V=None,
                 bosses=True, pockets=True):
        """x: ring params; W: Weight; t: shell wall; tb: boss wall; zs: top of a solid
        floor slab (None: just the base wall).  Overrides (robustness trials): perturbed
        outer / inner planes, pocket centres P, weight centres Wpos, weight masses wm."""
        self.x, self.W, self.t, self.tb, self.rho = x, W, t, tb, rho
        V0 = verts(x)
        faces0, _ = faces_of(V0)
        A0 = np.array([f[0] for f in faces0]); b0 = np.array([f[1] for f in faces0])
        if P is None:
            P = place_pockets(V0, faces0, W, t) if pockets else (Wpos if Wpos is not None else V0.copy())
        self.P = P
        if P is None: self.ok = False; return
        self.ok = True
        oA = A0 if outerA is None else outerA; ob = b0 if outerb is None else outerb
        iA = A0 if innerA is None else innerA; ib = (b0 + t) if innerb is None else innerb
        if outerA is None:
            V, faces = V0, faces0
        else:
            V = halfspace_poly(oA, ob); V = np.unique(np.round(V, 9), axis=0)
            faces, _ = faces_of(V, tol=1e-7)
        self.V, self.faces = V, faces
        self.base = int(np.argmin([f[0][2] for f in faces]))
        self.zs = t if zs is None else zs
        Vin = halfspace_poly(np.r_[iA, [[0, 0, -1.0]]], np.r_[ib, t])    # inner region (above the base wall)
        self.Vin = Vin
        vo, m1o, So = convex_props(V)
        vi, m1i, Si = convex_props(Vin)
        regions = boss_halfspaces(P, W, self.tb, len(P)) if bosses else []
        if self.zs > t + 1e-9:
            regions.append((np.array([[0, 0, 1.0]]), np.array([-self.zs])))
        self.regions = regions
        vu, m1u, Su, self.Q, self.pairs = union_props(np.r_[iA, [[0, 0, -1.0]]], np.r_[ib, t], regions)
        vp = 0.0; m1p = np.zeros(3); Sp = np.zeros((3, 3))
        for p in (P if pockets else []):
            a1, a2, a3 = W.pocket_props(p); vp += a1; m1p += a2; Sp += a3
        self.vol_outer, self.vol_inner, self.vol_boss, self.vol_pockets = vo, vi, vu, vp
        vol = vo - vi + vu - vp; m1 = m1o - m1i + m1u - m1p; S = So - Si + Su - Sp
        self.vol_pla = vol; self.vol_shell = vo - vi
        self.m1_pla, self.S_pla = m1, S
        self.m_pla = rho * vol
        if Wpos is None:
            Wpos = P - np.array([0, 0, W.L / 2 - W.half])
        self.Wpos = Wpos
        wm = np.full(len(P), W.m) if wm is None else np.asarray(wm)
        gm = np.full(len(P), glue) if np.isscalar(glue) else np.asarray(glue)
        self.wm, self.gm = wm, gm
        pm = wm + gm
        M = rho * vol + pm.sum()
        mom = rho * m1 + (pm[:, None] * Wpos).sum(0)
        com = mom / M
        SS = rho * S + np.einsum('i,ij,ik->jk', pm, Wpos, Wpos)
        Sc = SS - M * np.outer(com, com)
        I = np.trace(Sc) * np.eye(3) - Sc + (W.I0 / W.m) * wm.sum()
        self.M, self.com, self.I = M, com, I

    def margins(self):
        fm, _ = margins(self.V, self.faces, self.com, self.base, 0)
        vm = vertex_signed(self.V, self.faces, self.com)
        apex = int(np.argmax(self.V[:, 2]))
        of = np.delete(fm, self.base)
        ov = [m for j, m in vm.items() if j != apex]
        return dict(face=of.min(), vert=min(ov), base=-fm[self.base], apex=vm[apex] < 0, fm=fm, vm=vm)

    def count(self):
        st, un = equilibria(self.V, self.faces, self.com)
        return st, un

# ------------------------------------------------- fast symmetric evaluation
def _rotsum(v, m1, S, n=6):
    """sum of (v, m1, S) over the n rotations about z by 2 pi k / n (n >= 3)"""
    S2 = np.zeros((3, 3)); S2[0, 0] = S2[1, 1] = n / 2 * (S[0, 0] + S[1, 1]); S2[2, 2] = n * S[2, 2]
    return n * v, np.array([0, 0, n * m1[2]]), S2

def _rot(A, ang):
    c, s = np.cos(ang), np.sin(ang); R = np.array([[c, -s, 0], [s, c, 0], [0, 0, 1.0]])
    return A @ R.T

def fast_props(x, W, t=0.8, tb=0.8, zs=None, rho=RHO_PLA, glue=0.03, need_pairs_check=False):
    """same model as Body (nominal, symmetric), using the 6-fold symmetry; inclusion-
    exclusion to pairs only (Body does all orders; designs are re-checked with it).
    returns dict(M, com, V, faces, P, gap, ...) or None"""
    V = verts(x)
    try:
        faces, hull = faces_of(V)
    except Exception:
        return None
    if len(hull.vertices) != len(V): return None
    A0 = np.array([f[0] for f in faces]); b0 = np.array([f[1] for f in faces])
    P = place_pockets(V, faces, W, t)
    if P is None: return None
    gap, _ = pocket_clearance(P, W)
    baseA = np.r_[A0, [[0, 0, -1.0]]]; baseB = np.r_[b0 + t, t]
    vo, m1o, So = convex_props(V)
    Vin = halfspace_poly(baseA, baseB)
    if Vin is None: return None
    vi, m1i, Si = convex_props(Vin)
    regs = boss_halfspaces(P, W, tb, len(P))
    zs = t if zs is None else zs
    # representatives: apex (0), ring corner 1+6i (i=0..5); slab
    reps = [0] + [1 + K * i for i in range(NR)]
    vol = 0.0; m1 = np.zeros(3); S = np.zeros((3, 3))
    Qs = {}
    def poly(Alist, blist):
        P_ = halfspace_poly(np.r_[baseA, *Alist], np.r_[baseB, *blist])
        return None if P_ is None or len(P_) < 4 else P_
    for r in reps:
        Q = poly([regs[r][0]], [regs[r][1]])
        Qs[r] = Q
        if Q is None: continue
        v, a1, a2 = convex_props(Q)
        if r == 0: vol += v; m1 += a1; S += a2
        else:
            v, a1, a2 = _rotsum(v, a1, a2); vol += v; m1 += a1; S += a2
    slab = None
    if zs > t + 1e-9:
        slab = (np.array([[0, 0, 1.0]]), np.array([-zs]))
        Q = poly([slab[0]], [slab[1]]); Qs['slab'] = Q
        if Q is not None:
            v, a1, a2 = convex_props(Q); vol += v; m1 += a1; S += a2
    def bbox(Q): return (Q.min(0), Q.max(0))
    def boxes_meet(b1, b2):
        return np.all(np.minimum(b1[1], b2[1]) > np.maximum(b1[0], b2[0]) + 1e-9)
    # bounding boxes of every corner's Q by rotation of the representative
    allQ = {}
    for r in reps[1:]:
        if Qs[r] is None: continue
        for m in range(K):
            allQ[r + m] = _rot(Qs[r], 2 * np.pi * m / K)
    if Qs[0] is not None: allQ[0] = Qs[0]
    npairs = 0
    def add_pair(i, j, factor, rotsym):
        nonlocal vol, m1, S, npairs
        Ri = regs[i] if i != 'slab' else slab; Rj = regs[j] if j != 'slab' else slab
        Q = poly([Ri[0], Rj[0]], [Ri[1], Rj[1]])
        if Q is None: return
        npairs += 1
        v, a1, a2 = convex_props(Q)
        if rotsym: v, a1, a2 = _rotsum(v, a1, a2)
        vol -= factor * v; m1 -= factor * a1; S -= factor * a2
    ringreps = [r for r in reps[1:] if Qs[r] is not None]
    for ii, r in enumerate(ringreps):
        for r2 in ringreps[ii:]:
            for m in range(K):
                j = r2 + m
                if r2 == r and m == 0: continue
                if j not in allQ or not boxes_meet(bbox(allQ[r]), bbox(allQ[j])): continue
                add_pair(r, j, 0.5 if r2 == r else 1.0, True)
        if 0 in allQ and boxes_meet(bbox(allQ[0]), bbox(allQ[r])): add_pair(0, r, 1.0, True)
        if slab is not None and Qs['slab'] is not None and boxes_meet(bbox(Qs['slab']), bbox(allQ[r])): add_pair('slab', r, 1.0, True)
    if slab is not None and 0 in allQ and Qs['slab'] is not None and boxes_meet(bbox(Qs['slab']), bbox(allQ[0])): add_pair('slab', 0, 1.0, False)
    vp = 0.0; m1p = np.zeros(3); Sp = np.zeros((3, 3))
    for p in P:
        a1, a2, a3 = W.pocket_props(p); vp += a1; m1p += a2; Sp += a3
    volp = vo - vi + vol - vp; m1t = m1o - m1i + m1 - m1p
    Wpos = P - np.array([0, 0, W.L / 2 - W.half])
    pm = W.m + glue
    M = rho * volp + pm * len(P)
    com = (rho * m1t + pm * Wpos.sum(0)) / M
    com[:2] = 0.0
    return dict(M=M, com=com, V=V, faces=faces, P=P, gap=gap, m_pla=rho * volp, vol_boss=vol, npairs=npairs)

def fast_margin(x, W, **kw):
    r = fast_props(x, W, **kw)
    if r is None: return None
    base = int(np.argmin([f[0][2] for f in r['faces']]))
    fm, _ = margins(r['V'], r['faces'], r['com'], base, 0)
    vm = vertex_signed(r['V'], r['faces'], r['com'])
    r['face'] = np.delete(fm, base).min(); r['vert'] = min(m for j, m in vm.items() if j != 0)
    r['base'] = -fm[base]; r['fm'] = fm; r['vm'] = vm
    return r

def vertex_signed(V, faces, c):
    """signed vertex margins (mm): + distance of the COM from the vertex's
    equilibrium cone v - N(v) when outside (core.vertex_cone_dist), - depth inside
    (distance to the nearest facet of the cone) when the vertex IS an equilibrium."""
    vn = {}
    for (n, d, idx) in faces:
        for j in idx: vn.setdefault(j, []).append(n)
    out = {}
    for j, ns in vn.items():
        r = vertex_cone_dist(V[j], ns, c)
        if r > 1e-9: out[j] = r; continue
        N = np.array(ns); m = N.mean(0); m /= np.linalg.norm(m)
        u = np.cross(m, [1, 0, 0]);
        if np.linalg.norm(u) < 1e-6: u = np.cross(m, [0, 1, 0])
        u /= np.linalg.norm(u); w = np.cross(m, u)
        ang = np.arctan2(N @ w, N @ u); N = N[np.argsort(ang)]
        dmin = np.inf
        for i in range(len(N)):
            f = np.cross(N[i], N[(i + 1) % len(N)]); nf = np.linalg.norm(f)
            if nf < 1e-12: continue
            dmin = min(dmin, abs((c - V[j]) @ f) / nf)
        out[j] = -dmin
    return out
