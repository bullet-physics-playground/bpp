"""Build-error robustness of a weighted 37-corner design, exact mass model every
trial (w37.Body: outer polytope - inner polytope + union of pocket bosses - pockets
+ weights + glue).  usage: python3 robust.py design.npy WEIGHT [trials] [t] [rows]
Every trial counts the equilibria exactly with the perturbed hull and the trial's
centre of mass: stable faces (COM foot inside), unstable vertices (COM in the
vertex's normal cone).  Success = exactly one stable face, the base, and exactly
one unstable vertex.  Also reported: one unstable *point* (unstable vertices
closer than 1 mm merged: a split apex) and the smallest other-face margin.

Error models
  wmass s      every weight's mass x (1 + N(0,s))  (s = 0.5%: weighed and matched;
               3%: as bought, unsorted)
  wpos s       every weight's centre moved N(0,s) in x, y, z (rattle, print error)
  glue g       a CA drop of U(0,g) g in every pocket, at a random point of the pocket
  pla rho s    PLA density x (1+N(0,s)) everywhere (filament brand / moisture / voids)
  pla grad s   PLA density gradient, random direction, s across the body
  planes s     every outer face plane and every inner wall plane moved independently:
               offset N(0,s) + random tilt moving its corners by N(0,s)
  wall dt      every wall thicker/thinner by dt (systematic over/under-extrusion)
  droop d      the near-flat bottom bands print drooped: rings 1, 2 (and 3) lowered
               by d (not below the bed)
  combined     planes s + wall N(0,s/2) + wmass 3% + wpos 0.3 + glue 0.1 g + rho 3%
               + gradient 2%
"""
import numpy as np, sys, warnings, time
from w37 import *
from materials import CAT
from core import faces_of, equilibria, face_margin, halfspace_poly
warnings.filterwarnings('ignore')

def perturb(A, b, cen, rad, s, rng):
    A2 = A.copy(); b2 = b.copy()
    for i in range(len(A)):
        n = A[i]
        u = np.cross(n, rng.standard_normal(3)); u /= np.linalg.norm(u)
        ang = rng.standard_normal() * s / max(rad[i], 1e-3)
        n2 = n * np.cos(ang) + np.cross(u, n) * np.sin(ang)
        p = cen[i] - n * (n @ cen[i] + b[i])
        p = p + n * rng.standard_normal() * s
        A2[i] = n2; b2[i] = -n2 @ p
    return A2, b2

def count(V, faces, c, merge=1.0, flat_tol=0.0):
    """exactly one stable face (whichever it is: under large plane errors a near-flat
    S1 face can end up more nearly level than the base, and the body then rests on
    it instead -- still one stable face), one unstable vertex, one unstable point
    (unstable vertices closer than `merge` mm merged), smallest margin of the
    faces that are not the stable one, and the stable faces' n_z (diagnostics)"""
    st, un = equilibria(V, faces, c)
    if flat_tol:   # printed (sliced) hull: ignore 'rest faces' whose foot is less than flat_tol inside
        # (layer facets) and the flat last layer at the tip (n_z > 0.99: a balance point, not a rest)
        st = [j for j in st if -face_margin(V, *faces[j][:2], faces[j][2], c) > flat_tol and faces[j][0][2] < 0.99]
    ok_st = (len(st) == 1)
    pts = V[un]; groups = 0; used = np.zeros(len(un), bool)
    for i in range(len(un)):
        if used[i]: continue
        groups += 1; used |= np.linalg.norm(pts - pts[i], axis=1) < merge
    keep = st[0] if len(st) == 1 else int(np.argmin([f[0][2] for f in faces]))
    sm = min(face_margin(V, n, d, idx, c) for j, (n, d, idx) in enumerate(faces)
             if j != keep and not (flat_tol and n[2] > 0.99))
    return ok_st, len(un) == 1, groups == 1, sm, len(st), len(un), [round(faces[j][0][2], 3) for j in st]

class Design:
    def __init__(self, x, W, t=0.8, tb=0.8, zs=None, glue=0.03):
        self.x, self.W, self.t, self.tb, self.zs, self.glue = x, W, t, tb, zs, glue
        self.B = Body(x, W, t=t, tb=tb, zs=zs, glue=glue)
        B = self.B
        self.V0 = B.V; self.faces0 = B.faces
        self.A0 = np.array([f[0] for f in B.faces]); self.b0 = np.array([f[1] for f in B.faces])
        self.cen = np.array([B.V[f[2]].mean(0) for f in B.faces])
        self.rad = np.array([np.max(np.linalg.norm(B.V[f[2]] - B.V[f[2]].mean(0), axis=1)) for f in B.faces])
        # inner plane centres: the outer face centres moved in by t
        self.icen = self.cen - t * self.A0

    def com_fast(self, wm=None, Wpos=None, gm=None, gpos=None, rho_f=1.0, grad=None):
        """COM when only weights / glue / PLA density change (PLA geometry nominal)"""
        B = self.B
        wm = B.wm if wm is None else wm; Wpos = B.Wpos if Wpos is None else Wpos
        gm = B.gm if gm is None else gm; gpos = Wpos if gpos is None else gpos
        rho = B.rho * rho_f
        M = rho * B.vol_pla + wm.sum() + gm.sum()
        mom = rho * B.m1_pla + (wm[:, None] * Wpos).sum(0) + (gm[:, None] * gpos).sum(0)
        if grad is not None:
            g, s = grad; L = max(self.x[-1], 2 * self.x[:6].max())
            a = s / L; c0 = B.m1_pla / B.vol_pla
            mom = mom + rho * a * ((B.S_pla - np.outer(B.m1_pla, c0)) @ g)
        return mom / M

    def sliced_hull(self, rng, layer=0.2, xy=0.0, scale=0.0, efoot=0.0, wall_shift=0.0):
        """the printed outer surface as FDM makes it: every layer is the cross-section
        at its mid-height (PrusaSlicer), extruded over the layer; each layer shifted by
        N(0,xy) in x and y and grown/shrunk by N(0,scale) normal to its edges; the
        first layer grown by efoot (elephant foot). Returns hull vertices."""
        from scipy.spatial import HalfspaceIntersection, ConvexHull
        A, b = self.A0, self.b0
        H = self.V0[:, 2].max(); pts = []
        z = 0.0
        while z < H - 1e-9:
            zm = min(z + layer / 2, H - 1e-4)
            A2 = A[:, :2]; b2 = A[:, 2] * zm + b
            nrm = np.linalg.norm(A2, axis=1); keep = nrm > 1e-9
            A2, b2, nrm = A2[keep], b2[keep], nrm[keep]
            grow = (efoot if z == 0.0 else 0.0) + (scale * rng.standard_normal() if scale else 0.0)
            b2 = b2 - grow * nrm
            if np.any(b2 >= 0):      # origin outside: section vanishes (tip)
                z += layer; continue
            hs = HalfspaceIntersection(np.c_[A2, b2], np.zeros(2))
            P = hs.intersections
            if xy: P = P + rng.standard_normal(2) * xy
            top = min(z + layer, H)
            for zz in (z, top): pts.append(np.c_[P, np.full(len(P), zz)])
            z += layer
        P = np.vstack(pts)
        return P[ConvexHull(P).vertices]

    def trial(self, rng, planes=0.0, dwall=0.0, wmass=0.0, wpos=0.0, glue=0.0, rho=0.0, grad=0.0, droop=0.0,
              sliced=False, xy=0.0, scale=0.0, efoot=0.0, rings=0.0):
        B = self.B; W = self.W; n = len(B.P)
        wm = W.m * (1 + wmass * rng.standard_normal(n)) if wmass else B.wm
        Wpos = B.Wpos + wpos * rng.standard_normal((n, 3)) if wpos else B.Wpos
        if glue:
            gm = rng.uniform(0, glue, n)
            # random point in the pocket (cylinder): radius a, height L
            r = W.a * np.sqrt(rng.uniform(0, 1, n)); th = rng.uniform(0, 2 * np.pi, n)
            gpos = B.P + np.c_[r * np.cos(th), r * np.sin(th), rng.uniform(-W.L / 2, W.L / 2, n)]
        else:
            gm = B.gm; gpos = Wpos
        rho_f = 1 + rho * rng.standard_normal() if rho else 1.0
        gr = None
        if grad:
            g = rng.standard_normal(3); g /= np.linalg.norm(g); gr = (g, grad)
        if sliced or rings:
            c = self.com_fast(wm, Wpos, gm, gpos, rho_f, gr)
            if sliced:
                V = self.sliced_hull(rng, xy=xy, scale=scale, efoot=efoot)
            else:   # gallery robust2 model: ring radii / heights (and the apex height) off by N(0,rings)
                x2 = self.x + rings * rng.standard_normal(len(self.x)); x2[NR:2*NR-1] = np.maximum(x2[NR:2*NR-1], 0.0)
                V = verts(x2)
            fc, _ = faces_of(V, tol=1e-7)
            return count(V, fc, c, flat_tol=0.1)
        geo = planes or dwall or droop
        if not geo:
            c = self.com_fast(wm, Wpos, gm, gpos, rho_f, gr)
            return count(self.V0, self.faces0, c)
        # geometry changes: exact rebuild
        if droop:
            V = self.V0.copy()
            for ring in (1, 2, 3):
                sl = slice(1 + 6 * ring, 7 + 6 * ring)
                V[sl, 2] = np.maximum(V[sl, 2] - droop, 0.0)
            fc, _ = faces_of(V, tol=1e-7)
            oA = np.array([f[0] for f in fc]); ob = np.array([f[1] for f in fc])
            iA, ib = self.A0, self.b0 + self.t
        else:
            oA, ob = perturb(self.A0, self.b0, self.cen, self.rad, planes, rng) if planes else (self.A0, self.b0)
            iA, ib = perturb(self.A0, self.b0 + self.t, self.icen, self.rad, planes, rng) if planes else (self.A0, self.b0 + self.t)
            ib = ib + dwall
            iA = np.r_[iA, oA]; ib = np.r_[ib, ob + 0.3]        # walls never thinner than 0.3 mm
        Bt = Body(self.x, W, t=self.t, tb=self.tb, zs=self.zs, rho=B.rho * rho_f, glue=gm, wm=wm,
                  outerA=oA, outerb=ob, innerA=iA, innerb=ib, P=B.P, Wpos=Wpos)
        # glue position (Body puts glue at the weight centre): correct the moment
        if glue:
            Bt.com = Bt.com + (gm[:, None] * (gpos - Wpos)).sum(0) / Bt.M
        c = Bt.com
        if gr is not None:
            L = max(self.x[-1], 2 * self.x[:6].max()); a = gr[1] / L; c0 = Bt.m1_pla / Bt.vol_pla
            c = c + Bt.rho * a * ((Bt.S_pla - np.outer(Bt.m1_pla, c0)) @ gr[0]) / Bt.M
        return count(Bt.V, Bt.faces, c)

ROWS = [("nominal", {}),
        ("weights matched (0.5%)", dict(wmass=0.005)), ("weights unsorted (3%)", dict(wmass=0.03)),
        ("weights unsorted (5%)", dict(wmass=0.05)),
        ("weight position 0.2 mm", dict(wpos=0.2)), ("weight position 0.5 mm", dict(wpos=0.5)),
        ("weight position 1.0 mm", dict(wpos=1.0)),
        ("glue 0-0.1 g per pocket", dict(glue=0.1)), ("glue 0-0.3 g per pocket", dict(glue=0.3)),
        ("PLA density 5%", dict(rho=0.05)), ("PLA density gradient 3%", dict(grad=0.03)),
        ("planes 0.1 mm", dict(planes=0.1)), ("planes 0.2 mm", dict(planes=0.2)),
        ("planes 0.3 mm", dict(planes=0.3)), ("planes 0.5 mm", dict(planes=0.5)),
        ("wall +0.15 mm", dict(dwall=0.15)), ("wall -0.15 mm", dict(dwall=-0.15)),
        ("wall +0.3 mm", dict(dwall=0.3)),
        ("bottom droop 0.2 mm", dict(droop=0.2)), ("bottom droop 0.5 mm", dict(droop=0.5)),
        ("bottom droop 1.0 mm", dict(droop=1.0)),
        ("rings 0.2 mm (gallery model)", dict(rings=0.2, wpos=0.2, wmass=0.03)),
        ("rings 0.5 mm (gallery model)", dict(rings=0.5, wpos=0.5, wmass=0.03)),
        ("rings 1.0 mm (gallery model)", dict(rings=1.0, wpos=1.0, wmass=0.03)),
        ("as sliced, 0.2 mm layers", dict(sliced=True)),
        ("sliced + layer xy 0.1 mm", dict(sliced=True, xy=0.1, scale=0.1)),
        ("sliced + layer xy 0.2 mm", dict(sliced=True, xy=0.2, scale=0.2)),
        ("sliced + xy 0.2 + foot 0.4", dict(sliced=True, xy=0.2, scale=0.2, efoot=0.4)),
        ("combined (planes 0.2)", "c2"), ("combined (planes 0.3)", "c3"), ("combined (planes 0.5)", "c5")]

if __name__ == "__main__":
    x = np.load(sys.argv[1]); W = CAT[sys.argv[2]]
    N = int(sys.argv[3]) if len(sys.argv) > 3 else 300
    t = float(sys.argv[4]) if len(sys.argv) > 4 else 0.8
    only = sys.argv[5].split(',') if len(sys.argv) > 5 else None
    D = Design(x, W, t=t)
    m = D.B.margins()
    print(f"design {sys.argv[1]}  weight {W.name} ({W.m:.2f} g)  wall {t} mm  mass {D.B.M:.1f} g  "
          f"margins face {m['face']:.2f} vert {m['vert']:.2f} mm; {N} trials per row", flush=True)
    print(f"{'error model':28s} {'1 stable':>9s} {'1 unstable':>11s} {'1 unst. pt':>11s} {'all three':>10s} {'min face margin mm':>19s}")
    rng = np.random.default_rng(0)
    for name, kw in ROWS:
        if only and not any(o in name for o in only): continue
        res = []; t0 = time.time()
        n = 1 if name == "nominal" or name.startswith("wall") or name.startswith("bottom") or name.startswith("as sliced") else N
        for i in range(n):
            if isinstance(kw, str):
                sp = {"c2": 0.2, "c3": 0.3, "c5": 0.5}[kw]
                kk = dict(planes=sp, dwall=rng.standard_normal() * sp / 2, wmass=0.03, wpos=0.3, glue=0.1, rho=0.03, grad=0.02)
            else: kk = kw
            try:
                res.append(D.trial(rng, **kk))
            except Exception as e:
                res.append((False, False, False, np.nan, -1, -1, [])); print("   trial failed:", repr(e)[:100])
        r = np.array([[a, b, c, a and b] for a, b, c, *_ in res], float)
        bad = [x[6] for x in res if not x[0] and len(x) > 6][:6]
        mm = np.nanmin([d for _, _, _, d, *_ in res])
        print(f"{name:28s} {100*r[:,0].mean():8.1f}% {100*r[:,1].mean():10.1f}% {100*r[:,2].mean():10.1f}% {100*r[:,3].mean():9.1f}% {mm:19.2f}   ({time.time()-t0:.0f} s)" + (f"  e.g. stable faces n_z {bad}" if bad else ""), flush=True)
