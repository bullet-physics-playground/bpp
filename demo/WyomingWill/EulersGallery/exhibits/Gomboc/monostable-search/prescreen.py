"""Pre-screen for printed self-righting bodies: the printing chat's print model plus a rolling model of a drop
that predicts the share of drops that stall before righting (soft-dent stall metric, 10 Nov 2026).

  python3 prescreen.py genomes/mono-s2.npy ...    genome -> level-7 body -> printed hulls (aligned, vertical slip,
                                                  sideways slip) -> predicted stall at rolling friction 0.15, 0.3 mm
  python3 prescreen.py --hull hull.npy ...        a printed hull already made (points, mm at 36, centre of mass at
                                                  the origin, as the printing chat's hulls/<shape>_<case>.npy)

PRINT MODEL (the printing chat's spec)
  frame:  x = n = xhat - (xhat.d) d (xhat the least-inertia axis, d the resting normal), y = up = -d, z = x cross y;
          centre of mass at the origin; mm at 36 mm (longest principal extent).
  layers: each half stacked outward from the cut plane x = 0: first 0.2 mm, then 0.12 mm. Each layer is the body's
          section at the layer's mid-height as a vertical wall: points every 0.1 mm on that contour at mid-height,
          and on the contour inset by half a layer at the layer's top and bottom; only layers whose top is within
          the body.
  slip:   the +x half moves by 0.1 mm along +y ('sy') or +z ('sz'); the centre of mass moves by 0.1 mm x the share
          of hull points on the moved side. The table touches only the convex hull.

STALL METRIC (stall)
  On the convex hull (mm at 90; at 36 mm everything scales by 0.4): resting on face f the centre of mass is h_f
  up and its foot lies lam_f outside the face. From each of 10,242 landing directions the body rolls face to face
  toward the main rest by the lowest way out of every dent (priority flood). Kinetic energy (mm at 36, per unit
  weight) starts at 0.02 and changes by 0.4 * (height lost) - mu * (angle turned, rad). It stalls on a face whose
  lever is too weak (0.4 lam < mu) once its energy is used up; and each time its route enters the basin of a dent
  (watershed of the dents deeper than 1 um) that dent, of depth d at 90 mm, holds it with probability
  d^2 / (d^2 + d0^2), d0 = 5 um. Upright = within 10 deg of the rest.
  Calibration (Spearman rank correlation with the drop share that stalls): PyBullet, 17 shapes x 3 frictions,
  30 s drops: 0.85 (mean error 6.8 points); the printing chat's drops of its printed hulls, 26 cases: 0.84 (7.5).
  Charging a dent only when the route crossed its lowest face (an earlier form) missed whole extra resting
  points: two bodies scored 0.2% that stall in 63% and 53% of PyBullet drops (predicted now 71% and 50%).
  Known misses: GOMBOC900's 16-22 deg stalls in PyBullet (dynamic), mono-s4's vertical slip (13%, no static trap).
  A flat zone whose dents are a few um deep can flip between 0 and 70% with um-level build differences
  (mono-s5): test such a body with small random surface bumps as well.
NEEDS numpy, scipy, shapely; build.py and smooth.py from this folder."""
import sys, os, heapq, numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from scipy.spatial import ConvexHull, cKDTree
from shapely.geometry import Polygon
import build, smooth

# ---------------------------------------------------------------- print model

def mass(X, F):
    a, b, c = X[F[:, 0]], X[F[:, 1]], X[F[:, 2]]
    v6 = np.einsum('ij,ij->i', a, np.cross(b, c)); vol = v6.sum() / 6
    com = ((a + b + c) * v6[:, None]).sum(0) / 24 / vol; s = a + b + c
    S = (np.einsum('k,ki,kj->ij', v6, a, a) + np.einsum('k,ki,kj->ij', v6, b, b) + np.einsum('k,ki,kj->ij', v6, c, c)
         + np.einsum('k,ki,kj->ij', v6, s, s)) / 120 - vol * np.outer(com, com)
    return vol, com, np.trace(S) * np.eye(3) - S


def body7(c, level=7):
    """a build.py genome on a level-7 icosphere (163,842 planes), build.py's level-5 basis normalisation kept;
    principal axes (x least inertia), longest extent 90 mm"""
    import scipy.special as sp
    L = build.degree(c)
    def rawY(N):
        t, p = np.arccos(np.clip(N[:, 1], -1, 1)), np.arctan2(N[:, 0], N[:, 2]); Y = []
        for l in range(2, L + 1):
            for m in range(-l, l + 1):
                y = sp.sph_harm_y(l, abs(m), t, p); Y.append(np.sqrt(2) * (y.imag if m < 0 else y.real) if m else y.real)
        return np.array(Y).T
    N7 = build.icosphere(level); Y = rawY(N7) / np.abs(rawY(build.N)).max(0)
    h = 1.0 + Y @ c
    d = ConvexHull(N7 / h[:, None]); X = d.equations[:, :3] / -d.equations[:, 3:4]
    F = build.outward(X, ConvexHull(X).simplices)
    vol, com, I = mass(X, F); w, R = np.linalg.eigh(I); R[:, 2] *= np.linalg.det(R)
    X = (X - com) @ R
    return X * 90.0 / np.ptp(X, 0).max()


def to_frame(X):
    """principal-axis body (x least inertia), mm at 90 -> printing frame, mm at 36"""
    e = ConvexHull(X).equations; d = e[np.argmin(-e[:, 3]), :3]          # resting normal: the lowest face
    x = np.array([1.0, 0, 0]); n = x - (x @ d) * d; n /= np.linalg.norm(n); y = -d; z = np.cross(n, y)
    return (X @ np.c_[n, y, z]) * 0.4


def _section(H, X, c):
    a, b = X[H[:, [0, 1, 2]]].reshape(-1, 3), X[H[:, [1, 2, 0]]].reshape(-1, 3); sa, sb = a[:, 0] - c, b[:, 0] - c
    cr = (sa > 0) != (sb > 0)
    if cr.sum() < 3: return None
    t = sa[cr] / (sa[cr] - sb[cr]); return (a[cr] + t[:, None] * (b[cr] - a[cr]))[:, 1:]


def _ring(poly, step):
    L = poly.exterior.length; k = max(int(np.ceil(L / step)), 8)
    return np.array([poly.exterior.interpolate(s).coords[0] for s in np.linspace(0, L, k, endpoint=False)])


def layered(X, first=0.2, layer=0.12, step=0.1):
    """printed points of the +x half and of the -x half (X in the printing frame)"""
    H = ConvexHull(X).simplices; halves = []
    for sgn in (1, -1):
        pts, lo, k = [], 0.0, 0; xmax = (sgn * X[:, 0]).max()
        while True:
            t = first if k == 0 else layer; hi = lo + t; mid = (lo + hi) / 2
            if hi > xmax: break
            S = _section(H, X, sgn * mid)
            if S is None: break
            poly = Polygon(S[ConvexHull(S).vertices])
            for xx, pg in ((mid, poly), (lo, poly.buffer(-t / 2)), (hi, poly.buffer(-t / 2))):
                if pg.is_empty or pg.area <= 0: continue
                R = _ring(pg if pg.geom_type == 'Polygon' else max(pg.geoms, key=lambda g: g.area), step)
                pts.append(np.c_[np.full(len(R), sgn * xx), R])
            lo = hi; k += 1
        halves.append(np.concatenate(pts))
    return halves


def printed(halves, case='al', v=0.1):
    """convex-hull vertices of the printed body, case al / sy / sz (mm at 36, centre of mass at the origin)"""
    P, M = halves
    if case == 'al': Y = np.r_[P, M]
    else:
        w = np.array([0, v, 0]) if case == 'sy' else np.array([0, 0, v])
        allp = np.r_[P + w, M]; frac = (ConvexHull(allp).vertices < len(P)).mean(); Y = allp - w * frac
    return Y[ConvexHull(Y).vertices]

# ---------------------------------------------------------------- stall metric

def faces(X, F):
    """outward unit normal n, height h of the centre of mass (origin), lever lam (distance of the foot of the
    centre of mass outside the face, 0 inside) and face adjacency A"""
    a, b, c = X[F[:, 0]], X[F[:, 1]], X[F[:, 2]]
    n = np.cross(b - a, c - a); n /= np.linalg.norm(n, axis=1)[:, None]
    h = (n * a).sum(1); q = h[:, None] * n; P = [a, b, c]
    out = np.zeros(len(F), bool); dmin = np.full(len(F), np.inf)
    for i in range(3):
        u, v = P[i], P[(i + 1) % 3]; e = v - u
        out |= (np.cross(e, q - u) * n).sum(1) < 0
        t = np.clip(((q - u) * e).sum(1) / (e * e).sum(1), 0, 1)
        dmin = np.minimum(dmin, np.linalg.norm(u + t[:, None] * e - q, axis=1))
    lam = np.where(out, dmin, 0.0)
    E = np.sort(np.c_[F[:, [0, 1]], F[:, [1, 2]], F[:, [2, 0]]].reshape(-1, 2), 1)
    fid = np.repeat(np.arange(len(F)), 3); o = np.lexsort(E.T[::-1]); Es, fs = E[o], fid[o]
    same = (Es[1:] == Es[:-1]).all(1)
    return n, h, lam, np.c_[fs[:-1][same], fs[1:][same]]


def prep(X):
    """X: surface points, mm at 90, centre of mass at the origin. Faces, the drainage route of every face to the
    main rest (the lowest face) by the lowest way out of every dent, and every dent's depth (persistence)."""
    H = ConvexHull(X); F = H.simplices.copy()
    nrm = np.cross(X[F[:, 1]] - X[F[:, 0]], X[F[:, 2]] - X[F[:, 0]]); fl = (nrm * X[F].mean(1)).sum(1) < 0; F[fl] = F[fl][:, [0, 2, 1]]
    n, h, lam, A = faces(X, F); nf = len(F)
    o = np.argsort(np.r_[A[:, 0], A[:, 1]]); src = np.r_[A[:, 0], A[:, 1]][o]; dst = np.r_[A[:, 1], A[:, 0]][o]
    ptr = np.searchsorted(src, np.arange(nf + 1)); r = int(np.argmin(h))
    nxt = -np.ones(nf, int); key = np.full(nf, np.inf); nxt[r] = r; key[r] = h[r]; pq = [(h[r], r)]
    while pq:
        k, i = heapq.heappop(pq)
        if k > key[i]: continue
        for j in dst[ptr[i]:ptr[i + 1]]:
            if nxt[j] < 0: nxt[j] = i; key[j] = max(h[j], k); heapq.heappush(pq, (key[j], j))
    dent = np.zeros(nf)
    for d, i in smooth._persist(h, A)[1:]: dent[i] = d
    # watershed: every face belongs to the dent (deeper than 1 um, or the main rest) it rolls into
    basin = -np.ones(nf, int); pq = []
    for s in [r] + list(np.where(dent > 0.001)[0]): basin[s] = s; heapq.heappush(pq, (h[s], s))
    while pq:
        k, i = heapq.heappop(pq)
        for j in dst[ptr[i]:ptr[i + 1]]:
            if basin[j] < 0: basin[j] = basin[i]; heapq.heappush(pq, (max(h[j], k), j))
    return dict(n=n, h=h, lam=lam, nxt=nxt, step=np.arccos(np.clip((n * n[nxt]).sum(1), -1, 1)), down=n[r], dent=dent,
                basin=basin)


def stall(P, mus=(0.15, 0.3), d0=0.005, eta=1.0, k0=0.02, start_level=5):
    """predicted share of drops that stall, one per rolling friction mu (mm at 36)"""
    n, h, lam, nxt, step, basin = P['n'], P['h'], P['lam'], P['nxt'], P['step'], P['basin']
    pd = P['dent'] ** 2 / (P['dent'] ** 2 + d0 ** 2); lq = np.log1p(-np.minimum(pd, 1 - 1e-12))
    near = n @ P['down'] > np.cos(np.radians(10)); start = cKDTree(n).query(smooth.icosphere(start_level)[0])[1]; out = []
    for mu in mus:
        weak = 0.4 * lam < mu; cur = start.copy(); ke = np.full(len(start), float(k0)); alive = ~near[start]
        ls = np.zeros(len(start)); st = np.zeros(len(start), bool); last = -np.ones(len(start), int)
        for _ in range(50000):
            a = np.where(alive)[0]
            if not len(a): break
            i = cur[a]; b = basin[i]; ls[a] += np.where(b != last[a], lq[b], 0.0); last[a] = b     # entering a dent's basin
            stop = (ke[a] <= 0) & weak[i] & ~near[i]
            st[a[stop]] = True; alive[a[stop]] = False; a = a[~stop]; i = cur[a]
            ke[a] = np.maximum(ke[a] + eta * 0.4 * (h[i] - h[nxt[i]]) - mu * step[i], 0); cur[a] = nxt[i]
            alive[a[near[cur[a]] | (nxt[cur[a]] == cur[a])]] = False
        surv = np.where(st, 0.0, np.exp(ls)); surv[near[start]] = 1.0
        out.append(1 - surv.mean())
    return np.array(out)


def hull_stall(Y36, mus=(0.15, 0.3)):
    """stall for a printed hull given in mm at 36"""
    return stall(prep(Y36 / 0.4), mus)


if __name__ == '__main__':
    args = sys.argv[1:]
    if args and args[0] == '--hull':
        for fn in args[1:]:
            s = hull_stall(np.load(fn)); print(f'{os.path.basename(fn):28s} stall {100 * s[0]:5.1f}% at 0.15 mm, {100 * s[1]:5.1f}% at 0.3 mm', flush=True)
    else:
        for fn in args:
            hv = layered(to_frame(body7(np.load(fn)))); r = {c: hull_stall(printed(hv, c)) for c in ('al', 'sy', 'sz')}
            print(f'{os.path.basename(fn):16s} ' + '   '.join(f'{c} {100 * s[0]:4.1f}/{100 * s[1]:4.1f}%' for c, s in r.items())
                  + f'   worst {100 * max(s.mean() for s in r.values()):4.1f}%   (stall at mu 0.15/0.3 mm)', flush=True)
