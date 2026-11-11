"""Smooth bodies from a support function, no facets.
h(n) = 1 + sum c_k Y_k(n)  (same basis as build.py, degrees 2..L), extended 1-homogeneously:
H(x) = |x| + sum c_k P_k(x) |x|^(1-l), P_k the harmonic polynomial with P_k = Y_k on the sphere.
At a unit normal n: boundary point x(n) = grad H, A = Hess H (tangent eigenvalues = principal radii
of curvature; convex iff both >= 0). Volume and centre of mass by quadrature over the sphere.
Equilibria = critical points of hG(n) = H(n) - G.n: minima resting, maxima balancing; counted by
persistence on the icosphere vertex graph. Depths in mm at a diameter of 90 mm."""
import itertools
import numpy as np
from scipy.special import sph_harm_y


def icosphere(level):
    t = (1 + 5 ** 0.5) / 2
    V = [np.array(v, float) for v in [[-1, t, 0], [1, t, 0], [-1, -t, 0], [1, -t, 0], [0, -1, t], [0, 1, t],
                                       [0, -1, -t], [0, 1, -t], [t, 0, -1], [t, 0, 1], [-t, 0, -1], [-t, 0, 1]]]
    V = [v / np.linalg.norm(v) for v in V]
    Fc = [[0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11], [1, 5, 9], [5, 11, 4], [11, 10, 2], [10, 7, 6],
          [7, 1, 8], [3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9], [4, 9, 5], [2, 4, 11], [6, 2, 10],
          [8, 6, 7], [9, 8, 1]]
    for _ in range(level):
        cache = {}; nf = []
        def mid(a, b):
            k = (min(a, b), max(a, b))
            if k not in cache:
                m = V[a] + V[b]; V.append(m / np.linalg.norm(m)); cache[k] = len(V) - 1
            return cache[k]
        for a, b, c in Fc:
            ab, bc, ca = mid(a, b), mid(b, c), mid(c, a)
            nf += [[a, ab, ca], [b, bc, ab], [c, ca, bc], [ab, bc, ca]]
        Fc = nf
    return np.array(V), np.array(Fc)


class Sphere:
    """basis values, gradients and Hessians of the 1-homogeneous extensions on one icosphere"""
    def __init__(self, L, level=5):
        self.L = L
        N, F = icosphere(level); self.N, self.F = N, F
        a, b, c = N[F[:, 0]], N[F[:, 1]], N[F[:, 2]]
        ar = np.linalg.norm(np.cross(b - a, c - a), axis=1) / 2
        w = np.zeros(len(N)); np.add.at(w, F.ravel(), np.repeat(ar / 3, 3)); self.w = w * 4 * np.pi / w.sum()
        self.E = np.unique(np.sort(np.concatenate([F[:, [0, 1]], F[:, [1, 2]], F[:, [2, 0]]]), 1), axis=0)
        # the basis exactly as build.sh_basis, normalised on the level-5 icosphere
        N5 = N if level == 5 else icosphere(5)[0]
        th = lambda M: np.arccos(np.clip(M[:, 1], -1, 1)); ph = lambda M: np.arctan2(M[:, 0], M[:, 2])
        def Y(l, m, M):
            y = sph_harm_y(l, abs(m), th(M), ph(M))
            return np.sqrt(2) * (y.imag if m < 0 else y.real) if m else y.real
        n = len(N); NP = (L + 1) ** 2 - 4
        self.v = np.zeros((n, NP)); self.g = np.zeros((n, NP, 3)); self.Hs = np.zeros((n, NP, 3, 3))
        k = 0; self.polys = []
        for l in range(2, L + 1):
            ex = [e for e in itertools.product(range(l + 1), repeat=3) if sum(e) == l]
            mono = lambda M: np.stack([M[:, 0] ** e[0] * M[:, 1] ** e[1] * M[:, 2] ** e[2] for e in ex], 1)
            Mn = mono(N5)
            for m in range(-l, l + 1):
                y = Y(l, m, N5); s = np.abs(y).max()
                coef = np.linalg.lstsq(Mn, y / s, rcond=None)[0]; self.polys.append((l, ex, coef))
                P, dP, ddP = self._poly(coef, ex, N)
                aa = 1 - l                                          # f = r^aa P at r = 1
                I = np.eye(3); nn = np.einsum('ni,nj->nij', N, N)
                self.v[:, k] = P
                self.g[:, k] = aa * P[:, None] * N + dP
                self.Hs[:, k] = (P[:, None, None] * (aa * I + aa * (aa - 2) * nn)
                                 + aa * (np.einsum('ni,nj->nij', N, dP) + np.einsum('ni,nj->nij', dP, N)) + ddP)
                k += 1
        self.nn = np.einsum('ni,nj->nij', N, N)

    @staticmethod
    def _poly(coef, ex, N):
        x = N.T; n = len(N); P = np.zeros(n); dP = np.zeros((n, 3)); ddP = np.zeros((n, 3, 3))
        pw = lambda i, e: x[i] ** e if e >= 0 else 0 * x[i]
        for cf, e in zip(coef, ex):
            if abs(cf) < 1e-12: continue
            e = list(e); P += cf * pw(0, e[0]) * pw(1, e[1]) * pw(2, e[2])
            for i in range(3):
                d = e.copy(); f = d[i]; d[i] -= 1
                if f: dP[:, i] += cf * f * pw(0, d[0]) * pw(1, d[1]) * pw(2, d[2])
                for j in range(3):
                    dd = d.copy(); g = dd[j]; dd[j] -= 1
                    if f and g: ddP[:, i, j] += cf * f * g * pw(0, dd[0]) * pw(1, dd[1]) * pw(2, dd[2])
        return P, dP, ddP

    def body(self, c):
        """h, boundary points x(n), radii of curvature (2 per n), centre of mass G, scale to 90 mm"""
        N = self.N
        h = 1 + self.v @ c
        x = N + np.einsum('nki,k->ni', self.g, c)
        A = (np.eye(3) - self.nn) + np.einsum('nkij,k->nij', self.Hs, c)
        rad = np.linalg.eigvalsh(A + 10 * self.nn)[:, :2]           # tangent eigenvalues
        det = rad[:, 0] * rad[:, 1]
        V = (h * det * self.w).sum() / 3
        G = ((x * (h * det * self.w)[:, None]).sum(0)) / (4 * V)
        hG = h - N @ G
        width = h + h[self._anti()]
        return dict(h=h, x=x, rad=rad, G=G, hG=hG, s=90.0 / width.max(), V=V)

    def _anti(self):
        if not hasattr(self, '_ai'):
            from scipy.spatial import cKDTree
            self._ai = cKDTree(self.N).query(-self.N)[1]
        return self._ai

    def equilibria(self, f):
        """persistence of minima (resting) and maxima (balancing) of f over the vertex graph:
        ([(depth, index)] minima, [(depth, index)] maxima), deepest first"""
        return _persist(f, self.E), _persist(-f, self.E)


def _persist(v, E):
    w = np.maximum(v[E[:, 0]], v[E[:, 1]]); o = np.argsort(w, kind='stable')
    parent = np.arange(len(v)); best = np.arange(len(v)); out = []
    def find(i):
        while parent[i] != i: parent[i] = parent[parent[i]]; i = parent[i]
        return i
    for k in o:
        a, b = E[k]; ra, rb = find(a), find(b)
        if ra == rb: continue
        if v[best[ra]] > v[best[rb]]: ra, rb = rb, ra
        out.append((w[k] - v[best[rb]], best[rb])); parent[rb] = ra
    out.append((np.inf, best[find(0)]))
    return sorted(out, key=lambda o: -o[0])


def margin(S, B, i):
    """rocking margin at critical normal i, mm: least eigenvalue of the tangent Hessian of hG = radius - hG"""
    return (B['rad'][i].min() - B['hG'][i]) * B['s']


def report(S, c):
    B = S.body(c); mn, mx = S.equilibria(B['hG']); s = B['s']
    cnt = lambda L, t: sum(1 for d, _ in L if d * s > t / 1000)
    return B, mn, mx, (f"radius min {B['rad'].min() * s:.2f} mm  counts (2,5,20,100 um): "
                       + ', '.join(f"{cnt(mn, t)}/{cnt(mx, t)}" for t in (2, 5, 20, 100))
                       + f"  raw {sum(d > 0 for d, _ in mn)}/{sum(d > 0 for d, _ in mx)}  rest {B['hG'][mn[0][1]] * s:.2f} mm  margin {margin(S, B, mn[0][1]):.2f} mm")
