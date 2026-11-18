"""Orientation-sphere metrics for a convex body given as points (mm at 90, any frame).

Independent of edged.py's equilibrium count: works on the support function h(d) = max_x (x - G).d over
directions d (d = outward normal at the contact = 'down'), G the exact centre of mass of the convex hull.
  - resting points  = local minima of h on the direction sphere, counted by persistence
  - balancing points = local maxima of h
  - lever(d) = |p(d) - (p(d).d) d|, p(d) the support point: horizontal distance centre of mass -> contact
"""
import numpy as np
from scipy.spatial import ConvexHull


def icosphere(level):
    t = (1 + 5 ** 0.5) / 2
    V = [(-1, t, 0), (1, t, 0), (-1, -t, 0), (1, -t, 0), (0, -1, t), (0, 1, t), (0, -1, -t), (0, 1, -t),
         (t, 0, -1), (t, 0, 1), (-t, 0, -1), (-t, 0, 1)]
    F = [(0, 11, 5), (0, 5, 1), (0, 1, 7), (0, 7, 10), (0, 10, 11), (1, 5, 9), (5, 11, 4), (11, 10, 2), (10, 7, 6),
         (7, 1, 8), (3, 9, 4), (3, 4, 2), (3, 2, 6), (3, 6, 8), (3, 8, 9), (4, 9, 5), (2, 4, 11), (6, 2, 10),
         (8, 6, 7), (9, 8, 1)]
    V = [np.array(v, float) / np.linalg.norm(v) for v in V]
    for _ in range(level):
        cache, F2 = {}, []
        def mid(a, b):
            k = (min(a, b), max(a, b))
            if k not in cache:
                m = V[a] + V[b]; V.append(m / np.linalg.norm(m)); cache[k] = len(V) - 1
            return cache[k]
        for a, b, c in F:
            ab, bc, ca = mid(a, b), mid(b, c), mid(c, a)
            F2 += [(a, ab, ca), (b, bc, ab), (c, ca, bc), (ab, bc, ca)]
        F = F2
    return np.array(V), np.array(F)


def hull_mass(X):
    H = ConvexHull(X); F = H.simplices.copy(); c0 = X[H.vertices].mean(0)
    a, b, c = X[F[:, 0]] - c0, X[F[:, 1]] - c0, X[F[:, 2]] - c0
    v6 = np.einsum('ij,ij->i', a, np.cross(b, c)); fl = v6 < 0
    F[fl] = F[fl][:, [0, 2, 1]]; v6 = np.abs(v6)
    vol = v6.sum() / 6; com = ((a + b + c) * v6[:, None]).sum(0) / 24 / vol
    s = a + b + c
    S = (np.einsum('k,ki,kj->ij', v6, a, a) + np.einsum('k,ki,kj->ij', v6, b, b) + np.einsum('k,ki,kj->ij', v6, c, c)
         + np.einsum('k,ki,kj->ij', v6, s, s)) / 120 - vol * np.outer(com, com)
    I = np.trace(S) * np.eye(3) - S
    return vol, com + c0, I, H


def _minnorm2d(Q):
    """distance from the origin to the convex hull of 2-D points Q"""
    if len(Q) == 1: return np.linalg.norm(Q[0])
    if len(Q) == 2 or np.linalg.matrix_rank(Q - Q[0], tol=1e-9) < 2:
        a, b = Q[np.argmin(Q @ (Q[-1] - Q[0]))], Q[np.argmax(Q @ (Q[-1] - Q[0]))]; e = b - a
        t = np.clip(-(a @ e) / max(e @ e, 1e-30), 0, 1); return np.linalg.norm(a + t * e)
    H = ConvexHull(Q); eq = H.equations
    if (eq[:, 2] <= 1e-12).all(): return 0.0
    best = np.inf
    for s0, s1 in H.simplices:
        a, e = Q[s0], Q[s1] - Q[s0]; t = np.clip(-(a @ e) / (e @ e), 0, 1); best = min(best, np.linalg.norm(a + t * e))
    return best


def support(P, D, chunk=None, tie=1e-3):
    """h(d), the index of a support point, and the lever: distance from the foot of the centre of mass to the
    contact set (support points within `tie` mm of the table, 1 um at 90 mm), P hull vertices relative to G"""
    chunk = chunk or max(100, int(1.5e8 // len(P))); h = np.empty(len(D)); k = np.empty(len(D), int); lev = np.empty(len(D))
    for i in range(0, len(D), chunk):
        Dc = D[i:i + chunk]; M = Dc @ P.T; j = M.argmax(1); hh = M[np.arange(len(j)), j]
        k[i:i + chunk] = j; h[i:i + chunk] = hh
        p = P[j]; lev[i:i + chunk] = np.linalg.norm(p - (p * Dc).sum(1)[:, None] * Dc, axis=1)
        ties = (M >= hh[:, None] - tie).sum(1) > 1
        for r in np.where(ties)[0]:
            d = Dc[r]; Q = P[M[r] >= hh[r] - tie]; u = np.cross(d, [1.0, 0, 0] if abs(d[0]) < 0.9 else [0, 1.0, 0])
            u /= np.linalg.norm(u); v = np.cross(d, u); lev[i + r] = _minnorm2d(np.c_[Q @ u, Q @ v])
    return h, k, lev


def edges(F):
    E = np.sort(np.r_[F[:, [0, 1]], F[:, [1, 2]], F[:, [2, 0]]], 1)
    return np.unique(E, axis=0)


def persist(f, E):
    """0-dim persistence of sublevel sets of f on a graph: [(depth, vertex)] for every minimum, deepest first
    (the global minimum gets depth inf)"""
    n = len(f); w = np.maximum(f[E[:, 0]], f[E[:, 1]]); par = np.arange(n); mn = np.arange(n); out = []
    def find(i):
        while par[i] != i: par[i] = par[par[i]]; i = par[i]
        return i
    # vertices enter at f; an edge joins when both ends are in
    for k in np.argsort(w, kind='stable'):
        a, b = find(E[k, 0]), find(E[k, 1])
        if a == b: continue
        if f[mn[a]] > f[mn[b]]: a, b = b, a
        out.append((w[k] - f[mn[b]], mn[b])); par[b] = a
    out.append((np.inf, mn[find(0)]))
    return sorted(out, key=lambda t: -t[0])


class Body:
    def __init__(self, X, level=7):
        vol, G, I, H = hull_mass(X)
        self.vol, self.I = vol, I
        P = X[H.vertices] - G
        w, R = np.linalg.eigh(I); R[:, 2] *= np.linalg.det(R)           # principal axes, x least inertia
        self.P = P @ R
        self.D, self.DF = icosphere(level); self.E = edges(self.DF)
        Rr = np.linalg.qr(np.random.default_rng(7).normal(size=(3, 3)))[0]; self.D = self.D @ Rr   # off the axes
        a = self.D[self.DF]; ar = np.linalg.norm(np.cross(a[:, 1] - a[:, 0], a[:, 2] - a[:, 0]), axis=1) / 2
        wv = np.zeros(len(self.D)); np.add.at(wv, self.DF.ravel(), np.repeat(ar / 3, 3)); self.w = wv / wv.sum()
        self.h, self.k, self.lever = support(self.P, self.D)
        self.mins = persist(self.h, self.E); self.maxs = persist(-self.h, self.E)
        self.rest = self.D[self.mins[0][1]]; self.top = self.D[self.maxs[0][1]]
        r = np.linalg.norm(self.P, axis=1)
        self.rmax, self.rmin = r.max(), self.h.min()

    def counts(self, um=(0.5, 2, 5, 20, 100)):
        return [(sum(d > t / 1000 for d, _ in self.mins), sum(d > t / 1000 for d, _ in self.maxs)) for t in um]

    def tilt(self):
        return np.degrees(np.arccos(np.clip(self.D @ self.rest, -1, 1)))

    def weak_share(self, mu=0.05, slope=1.4, beyond=25.0, scale=0.4, h_mode='rest'):
        """share of the orientation sphere beyond `beyond` deg from the rest where lever < mu + h tan(slope),
        all at 36 mm (scale 0.4). h_mode 'rest' = rest height (doc), 'local' = h(d)"""
        hh = self.h.min() if h_mode == 'rest' else self.h
        thr = mu + scale * hh * np.tan(np.radians(slope))
        far = self.tilt() > beyond
        weak = far & (scale * self.lever < thr)
        return self.w[weak].sum(), weak

    def rocking(self, tilt=20.0, scale=0.4):
        """least lever (36 mm) over the ring at `tilt` deg and over the cap out to it"""
        t = self.tilt(); ring = np.abs(t - tilt) < 0.6; cap = (t > 3) & (t <= tilt)
        return scale * self.lever[ring].min(), scale * self.lever[cap].min()

    def to_upright(self):
        """rotation taking body coords to the delivery frame: rest normal -> -Y, least-inertia axis
        (projected) -> X; returns R (3x3) with Xnew = X @ R"""
        d = self.rest; y = -d
        x = np.array([1.0, 0, 0]); x = x - (x @ y) * y; x /= np.linalg.norm(x); z = np.cross(x, y)
        return np.c_[x, y, z]


def load_lua_points(fn):
    import re
    s = open(fn).read(); s = s[s.index('points = {'):]; s = s[s.index('{') + 1:s.index('}')]
    v = np.array([float(t) for t in re.findall(r'-?\d+\.?\d*(?:[eE]-?\d+)?', s)])
    return v.reshape(-1, 3) * 10.0      # cm -> mm
