"""Edged bodies: the radial function about the origin is the least of K smooth pieces,
rho(u) = min_k exp(sum_j a_kj Y_j(u))  (real spherical harmonics, degrees 0..L, so a piece can be any size
and off centre), so pieces cut each other along creases. Sampled on an icosphere, plus crease points where grid
edges cross from one piece to another; convexity = the depth of any sample inside the hull of all samples;
centre of mass by quadrature; equilibria = critical points of the distance from
the centre of mass over the surface (minima resting, maxima balancing; true at creases too), counted by
persistence. Lengths in mm at a diameter of 90 mm."""
import numpy as np
from scipy.special import sph_harm_y
import smooth

_GRIDS = {}


def Ybasis(L, U):
    th = np.arccos(np.clip(U[:, 1], -1, 1)); ph = np.arctan2(U[:, 0], U[:, 2]); Y = []
    for l in range(0, L + 1):
        for m in range(-l, l + 1):
            y = sph_harm_y(l, abs(m), th, ph)
            Y.append(np.sqrt(2) * (y.imag if m < 0 else y.real) if m else y.real)
    return np.array(Y).T


class Grid:
    def __init__(self, L, level):
        N, F = smooth.icosphere(level); self.N, self.F, self.L = N, F, L
        n = np.cross(N[F[:, 1]] - N[F[:, 0]], N[F[:, 2]] - N[F[:, 0]])
        flip = (n * N[F[:, 0]]).sum(1) < 0; F = F.copy(); F[flip] = F[flip][:, [0, 2, 1]]; self.F = F
        a, b, c = N[F[:, 0]], N[F[:, 1]], N[F[:, 2]]
        ar = np.linalg.norm(np.cross(b - a, c - a), axis=1) / 2
        w = np.zeros(len(N)); np.add.at(w, F.ravel(), np.repeat(ar / 3, 3)); self.w = w * 4 * np.pi / w.sum()
        # edges with the two opposite vertices: (a, b, c, d), faces (a, b, c) and (b, a, d)
        ed = {}
        for f in F:
            for i in range(3):
                p, q, r = f[i], f[(i + 1) % 3], f[(i + 2) % 3]
                ed[(p, q)] = r
        self.Q4 = np.array([(p, q, r, ed[(q, p)]) for (p, q), r in ed.items() if p < q])
        self.E = self.Q4[:, :2]
        eidx = {(int(p), int(q)): i for i, (p, q) in enumerate(self.E)}
        self.FE = np.array([[eidx[(min(f[i], f[(i + 1) % 3]), max(f[i], f[(i + 1) % 3]))] for i in range(3)] for f in F])
        self.scale = 1 / np.abs(Ybasis(L, smooth.icosphere(5)[0])).max(0)   # as on the level-5 grid, at every level
        self.Y = Ybasis(L, N) * self.scale; self.nb = self.Y.shape[1]
        self.D = smooth.icosphere(3)[0]


def grid(L, level):
    if (L, level) not in _GRIDS: _GRIDS[(L, level)] = Grid(L, level)
    return _GRIDS[(L, level)]


def body(a, K, L, level=5):
    """sampled surface plus the creases: every grid edge whose ends lie on different pieces gets a crease point
    where the two pieces meet (two secant steps); the graph for counting runs along the creases"""
    from scipy.spatial import ConvexHull
    g = grid(L, level); A = a.reshape(K, g.nb); scale = g.scale
    LR = g.Y @ A.T; piece = LR.argmin(1); rho = np.exp(LR.min(1))
    V = (rho ** 3 * g.w).sum() / 3; G = ((rho ** 4 * g.w)[:, None] * g.N).sum(0) / (4 * V)
    ea, eb = g.E.T; cut = piece[ea] != piece[eb]
    ca, cb = ea[cut], eb[cut]; k1, k2 = piece[ca], piece[cb]
    fa = LR[ca, k1] - LR[ca, k2]; fb = LR[cb, k1] - LR[cb, k2]        # fa < 0 < fb
    ta, tb = np.zeros(len(ca)), np.ones(len(ca)); den = fa - fb; t = np.divide(fa, den, out=np.full_like(fa, 0.5), where=den != 0)
    for _ in range(2):
        U = (1 - t)[:, None] * g.N[ca] + t[:, None] * g.N[cb]; U /= np.linalg.norm(U, axis=1)[:, None]
        Lu = (Ybasis(L, U) * scale) @ A.T; f = Lu[np.arange(len(t)), k1] - Lu[np.arange(len(t)), k2]
        neg = f < 0; ta = np.where(neg, t, ta); fa = np.where(neg, f, fa); tb = np.where(neg, tb, t); fb = np.where(neg, fb, f)
        den = fa - fb; t = ta + (tb - ta) * np.divide(fa, den, out=np.full_like(fa, 0.5), where=den != 0)
    U = (1 - t)[:, None] * g.N[ca] + t[:, None] * g.N[cb]; U /= np.linalg.norm(U, axis=1)[:, None]
    rc = np.exp(((Ybasis(L, U) * scale) @ A.T).min(1)) if len(t) else np.zeros(0)
    n0 = len(g.N); X = np.r_[rho[:, None] * g.N, rc[:, None] * U] - G
    P = X @ g.D.T; s = 90.0 / (P.max(0) - P.min(0)).max(); X = X * s
    # graph: uncut grid edges, split cut edges, and crease points joined within each triangle
    cid = -np.ones(len(g.E), int); cid[np.where(cut)[0]] = n0 + np.arange(cut.sum())
    Eg = [g.E[~cut], np.c_[ca, n0 + np.arange(len(ca))], np.c_[cb, n0 + np.arange(len(ca))]]
    C = cid[g.FE]                                          # crease points on each triangle's edges
    for i, j in ((0, 1), (1, 2), (0, 2)):
        m = (C[:, i] >= 0) & (C[:, j] >= 0); Eg.append(np.c_[C[m, i], C[m, j]])
    Eg = np.concatenate(Eg)
    # convexity: depth of samples inside the hull of all samples (0 for a convex body)
    H = ConvexHull(X); inside = np.setdiff1d(np.arange(len(X)), H.vertices)
    conv = 0.0
    if len(inside):
        sub = inside[:: max(1, len(inside) // 400)]
        conv = (-(X[sub] @ H.equations[:, :3].T + H.equations[:, 3])).min(1).max()
    return dict(X=X, s=s, piece=piece, conv=conv, g=g, n0=n0, E=Eg, d=np.linalg.norm(X, axis=1))


def equilibria(B):
    d = B['d']
    return smooth._persist(d, B['E']), smooth._persist(-d, B['E'])      # [(depth mm, vertex)] resting, balancing


def lever(B, rest, top):
    """lever field: tangential offset of the centre of mass from the contact normal, per radian from the
    nearer of rest and top (mm/rad); vertex normals area-weighted"""
    g, X = B['g'], B['X'][:B['n0']]
    fn = np.cross(X[g.F[:, 1]] - X[g.F[:, 0]], X[g.F[:, 2]] - X[g.F[:, 0]])
    vn = np.zeros_like(X)
    for i in range(3): np.add.at(vn, g.F[:, i], fn)
    vn /= np.linalg.norm(vn, axis=1)[:, None]
    lam = np.linalg.norm(X - (X * vn).sum(1)[:, None] * vn, axis=1)
    U = X / np.linalg.norm(X, axis=1)[:, None]
    Xa = B['X']; ur, ut = Xa[rest] / np.linalg.norm(Xa[rest]), Xa[top] / np.linalg.norm(Xa[top])
    sn = np.sqrt(np.maximum(1 - np.maximum(U @ ur, U @ ut) ** 2, 1e-12))
    return lam / sn


def report(a, K, L, level):
    B = body(a, K, L, level); mn, mx = equilibria(B)
    cnt = lambda Lx, t: sum(1 for dd, _ in Lx if dd > t / 1000)
    Qf = lever(B, mn[0][1], mx[0][1])
    far = np.ones(len(Qf), bool); far[[i for i in (mn[0][1], mx[0][1]) if i < len(Qf)]] = False
    return B, mn, mx, (f"L{level}: convexity {B['conv'] * 1000:.2f} um  counts (0.5,2,5,20 um): "
                       + ', '.join(f"{cnt(mn, t)}/{cnt(mx, t)}" for t in (0.5, 2, 5, 20))
                       + f"  pieces on surface {len(np.unique(B['piece']))}  rest {B['d'][mn[0][1]]:.2f} top {B['d'][mx[0][1]]:.2f} mm"
                       + f"  Q {Qf[far].min():.3f} mm/rad")
