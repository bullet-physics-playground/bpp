"""Print-error robustness of a PLA-only monostable design, in full 3D, exact
mass properties every trial (convex polytopes: outer minus void).
usage: python3 robust.py design.npy SPEC t_mm [trials]   (SPEC as in opt3.py, e.g. 6:0,6:0,6:0,6:0,6:0,6:0)

Error models (each row: `trials` random builds):
  planes s   every outer face plane AND every void plane (inner wall faces,
             slab top) moved independently: offset N(0,s) plus a random tilt
             that moves the face's corners by N(0,s)  (s = 0.1/0.2/0.3/0.5/1 mm)
  wall dt    all walls thicker/thinner by dt (systematic over/under-extrusion)
  dens-pi    perimeter zone (0.9 mm next to every surface) vs infill densities
             each N(0, 3%) independently
  dens-grad  linear density gradient, random direction, 2% / 5% across the body
  dens-rand  random density per cell (5 mm layers x 8 sectors), N(0, 3%) / 5%
  efoot e    elephant foot: the first 0.3 mm flared outward by e (0.3/0.6 mm)
  combined   planes 0.2 + wall N(0,0.1) + perimeter/infill 3% + gradient 2%
             + random cells 3% + elephant foot 0.4
Reported: % with exactly one stable face (the base); % with exactly one
unstable vertex; % with one unstable *point* after merging unstable vertices
closer than 1 mm (a split apex); smallest margin seen.
"""
import numpy as np, sys, warnings
from scipy.spatial import ConvexHull
from core import *
from opt3 import unpack, verts, parse
warnings.filterwarnings('ignore')

class Design:
    def __init__(self, x, rings, t):
        R, Z, H, zs = unpack(x, len(rings))
        self.R, self.Z, self.H, self.zs, self.t = R, Z, H, zs, t
        self.V = verts(rings, R, Z, H)
        self.faces, _ = faces_of(self.V)
        self.oA = np.array([f[0] for f in self.faces]); self.ob = np.array([f[1] for f in self.faces])
        # face centres and radii (for tilts)
        self.oc = np.array([self.V[f[2]].mean(0) for f in self.faces])
        self.orad = np.array([np.max(np.linalg.norm(self.V[f[2]] - self.V[f[2]].mean(0), axis=1)) for f in self.faces])
        self.vA = np.r_[self.oA, [[0, 0, -1.0]]]; self.vb = np.r_[self.ob + t, zs]
        VV = halfspace_poly(self.vA, self.vb)
        self.void = VV
        self.vc = []; self.vrad = []
        for a, b in zip(self.vA, self.vb):
            on = VV[np.abs(VV @ a + b) < 1e-7]
            if len(on) == 0: on = VV
            self.vc.append(on.mean(0)); self.vrad.append(np.max(np.linalg.norm(on - on.mean(0), axis=1)) if len(on) > 1 else 1.0)
        self.vc = np.array(self.vc); self.vrad = np.array(self.vrad)

def perturb(A, b, cen, rad, s, rng):
    """move each plane: offset N(0,s) + tilt moving its corners by ~N(0,s)"""
    A2 = A.copy(); b2 = b.copy()
    for i in range(len(A)):
        n = A[i]
        # random tilt axis in the plane
        u = np.cross(n, rng.standard_normal(3)); u /= np.linalg.norm(u)
        ang = rng.standard_normal() * s / max(rad[i], 1e-3)
        n2 = n * np.cos(ang) + np.cross(u, n) * np.sin(ang)
        p = cen[i] - n * (n @ cen[i] + b[i])           # point on the plane (its centre)
        p = p + n * rng.standard_normal() * s           # offset
        A2[i] = n2; b2[i] = -n2 @ p
    return A2, b2

def dedupe(P, tol=1e-9):
    P = np.unique(np.round(P / tol) * tol, axis=0)
    return P

def regions_props(Vo, Vv, rho_fn=None):
    vo, m1o, So = convex_props(Vo)
    if Vv is not None and len(Vv) >= 4:
        vv, m1v, Sv = convex_props(Vv)
    else:
        vv, m1v, Sv = 0, np.zeros(3), np.zeros((3, 3))
    return vo - vv, m1o - m1v, So - Sv

def count(V, c, merge=0.1):
    faces, _ = faces_of(V, tol=1e-7)
    st, un = equilibria(V, faces, c)
    base = int(np.argmin([f[0][2] for f in faces]))
    ok_st = (len(st) == 1 and st[0] == base)
    # merge unstable vertices within `merge` cm
    pts = V[un]; groups = 0; used = np.zeros(len(un), bool)
    for i in range(len(un)):
        if used[i]: continue
        groups += 1
        d = np.linalg.norm(pts - pts[i], axis=1); used |= d < merge
    sm_f = [face_margin(V, n, d, idx, c) for j, (n, d, idx) in enumerate(faces) if j != base]
    return ok_st, len(un) == 1, groups == 1, min(sm_f)

def cell_props(Vo_A, Vo_b, Vv_A, Vv_b, cuts):
    """exact (vol, m1) of solid inside each cell given by extra halfspaces"""
    out = []
    for (cA, cb) in cuts:
        Po = halfspace_poly(np.r_[Vo_A, cA], np.r_[Vo_b, cb])
        Pv = halfspace_poly(np.r_[Vv_A, cA], np.r_[Vv_b, cb])
        vo, m1o = (0, np.zeros(3)) if Po is None or len(Po) < 4 else convex_props(Po)[:2]
        vv, m1v = (0, np.zeros(3)) if Pv is None or len(Pv) < 4 else convex_props(Pv)[:2]
        out.append((vo - vv, m1o - m1v))
    return out

def make_cells(D, dz=0.5, nsec=8):
    cuts = []
    zs = np.arange(0, D.H + dz, dz)
    for z0, z1 in zip(zs[:-1], zs[1:]):
        for s in range(nsec):
            a0 = 2 * np.pi * s / nsec; a1 = 2 * np.pi * (s + 1) / nsec
            # wedge between azimuths a0..a1 (<180 deg): two halfspaces through the axis
            n0 = np.array([np.sin(a0), -np.cos(a0), 0]); n1 = np.array([-np.sin(a1), np.cos(a1), 0])
            cA = np.array([[0, 0, -1.0], [0, 0, 1.0], n0, n1]); cb = np.array([z0, -z1, 0, 0])
            cuts.append((cA, cb))
    return cuts

def trial(D, rng, s_planes=0.0, dwall=0.0, pi_sd=0.0, grad=0.0, cell_sd=0.0, efoot=0.0, cells=None, cellprops=None):
    s = s_planes / 10
    oA, ob = (perturb(D.oA, D.ob, D.oc, D.orad, s, rng) if s > 0 else (D.oA, D.ob))
    vA, vb = (perturb(D.vA, D.vb, D.vc, D.vrad, s, rng) if s > 0 else (D.vA.copy(), D.vb.copy()))
    if dwall:
        vb = vb.copy(); vb[:-1] += dwall / 10            # side walls thicker by dwall (mm)
    Vo = halfspace_poly(oA, ob)
    # the void can never cut through the outside: keep >= 0.3 mm of wall
    vA = np.r_[vA, oA]; vb = np.r_[vb, ob + 0.03]
    Vv = halfspace_poly(vA, vb)
    Vo = dedupe(Vo); Vv = dedupe(Vv) if Vv is not None else None
    vol, m1, S = regions_props(Vo, Vv)
    M = vol; mom = m1.copy()
    if pi_sd:
        # infill zone = (outer offset 0.09 inward) minus (void grown 0.09)
        p = 0.09
        e1, e2 = rng.standard_normal(2) * pi_sd
        Pin = halfspace_poly(oA, ob + p)
        vin, m1in = convex_props(Pin)[:2]
        Pcap = halfspace_poly(np.r_[oA, vA], np.r_[ob + p, vb - p])     # (outer-p) & (void+p)
        if Pcap is not None and len(Pcap) >= 4:
            vc_, m1c = convex_props(Pcap)[:2]; vin -= vc_; m1in = m1in - m1c
        # perimeter = solid - infill
        M = (1 + e1) * (vol - vin) + (1 + e2) * vin
        mom = (1 + e1) * (m1 - m1in) + (1 + e2) * m1in
    if grad:
        g = rng.standard_normal(3); g /= np.linalg.norm(g)
        L = max(D.H, 2 * D.R.max())
        a = grad / L  # relative density change per cm (grad = total change across L)
        c0 = m1 / vol
        # rho = 1 + a g.(x - c0): mass += a g.(m1 - vol c0)=0 ; moment += a (S - c0 m1^T) g
        mom = mom + a * ((S - np.outer(m1, c0)) @ g)
    if cell_sd:
        eps = rng.standard_normal(len(cellprops)) * cell_sd
        for e, (cv, cm) in zip(eps, cellprops):
            M += e * cv; mom = mom + e * cm
    c = mom / M
    Vh = Vo
    if efoot:
        # base polygon (z ~ min) flared outward by efoot mm over the first 0.3 mm
        ff, _ = faces_of(Vo, tol=1e-7)
        bi = int(np.argmin([f[0][2] for f in ff]))
        B = Vo[ff[bi][2]]
        nb = ff[bi][0]; cen = B.mean(0)
        d = B - cen; d -= np.outer(d @ nb, nb); d /= np.linalg.norm(d, axis=1)[:, None]
        lip = np.r_[B + efoot / 10 * d, B + efoot / 10 * d - 0.03 * nb]   # in the base plane, 0.3 mm high
        Vh = np.r_[Vo, lip]
        Vh = Vh[ConvexHull(Vh).vertices]
    return count(Vh, c)

if __name__ == "__main__":
    x = np.load(sys.argv[1]); rings = parse(sys.argv[2]); t = float(sys.argv[3]) / 10
    N = int(sys.argv[4]) if len(sys.argv) > 4 else 300
    D = Design(x, rings, t)
    cells = make_cells(D)
    cp = cell_props(D.oA, D.ob, D.vA, D.vb, cells)
    rows = [("nominal", {}),
            ("planes 0.1 mm", dict(s_planes=0.1)), ("planes 0.2 mm", dict(s_planes=0.2)),
            ("planes 0.3 mm", dict(s_planes=0.3)), ("planes 0.5 mm", dict(s_planes=0.5)),
            ("planes 1.0 mm", dict(s_planes=1.0)), ("planes 2.0 mm", dict(s_planes=2.0)),
            ("wall +0.2 mm", dict(dwall=0.2)), ("wall -0.2 mm", dict(dwall=-0.2)),
            ("wall +0.4 mm", dict(dwall=0.4)),
            ("dens perim/infill 3%", dict(pi_sd=0.03)), ("dens perim/infill 10%", dict(pi_sd=0.10)),
            ("dens gradient 2%", dict(grad=0.02)), ("dens gradient 5%", dict(grad=0.05)),
            ("dens cells 3%", dict(cell_sd=0.03)), ("dens cells 10%", dict(cell_sd=0.10)),
            ("elephant foot 0.3 mm", dict(efoot=0.3)), ("elephant foot 0.6 mm", dict(efoot=0.6)),
            ("combined (0.2 mm)", "comb2"), ("combined (0.3 mm)", "comb3"), ("combined (0.5 mm)", "comb5")]
    rng = np.random.default_rng(0)
    print(f"design {sys.argv[1]}: rings {sys.argv[2]} t={t*10:.1f} mm, {N} trials per row")
    print(f"{'error model':28s} {'1 stable':>9s} {'1 unstable':>11s} {'1 unst. pt':>11s} {'min face margin mm':>19s}")
    for name, kw in rows:
        res = []
        for i in range(1 if name == "nominal" or name.startswith("wall") else N):
            if isinstance(kw, str):
                sp = {"comb2": 0.2, "comb3": 0.3, "comb5": 0.5}[kw]
                kk = dict(s_planes=sp, dwall=rng.standard_normal() * sp / 2, pi_sd=0.03, grad=0.02, cell_sd=0.03,
                          efoot=abs(rng.normal(0.4, 0.1)))
            else: kk = kw
            try:
                res.append(trial(D, rng, cells=cells, cellprops=cp, **kk))
            except Exception as e:
                res.append((False, False, False, np.nan)); print("   trial failed:", e)
        r = np.array([[a, b, c] for a, b, c, _ in res], float); mm = np.nanmin([d for *_, d in res]) * 10
        print(f"{name:28s} {100*r[:,0].mean():8.1f}% {100*r[:,1].mean():10.1f}% {100*r[:,2].mean():10.1f}% {mm:19.2f}", flush=True)
