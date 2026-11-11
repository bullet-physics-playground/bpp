"""Exact equilibria of a smooth genome: python3 smooth_check.py genome.npy ...
Centre of mass by quadrature on a level-7 icosphere; every critical point of hG by Newton's method
from many starts, classified by the Hessian; depths by persistence on the level-7 grid."""
import sys
import numpy as np
import smooth

LEVEL = 7


class Exact:
    def __init__(self, c, S=None):
        self.S = S or smooth.Sphere(next(L for L in range(2, 20) if (L + 1) ** 2 - 4 == len(c)), level=1)
        self.terms = []
        k = 0; byl = {}
        for l, ex, coef in self.S.polys:
            e = byl.setdefault(l, [ex, 0]); e[1] = e[1] + c[k] * coef; k += 1
        self.terms = [(l, ex, cf) for l, (ex, cf) in byl.items()]

    def at(self, M):
        """h, x, A at unit vectors M"""
        n = len(M); I = np.eye(3); nn = np.einsum('ni,nj->nij', M, M)
        h = np.ones(n); x = M.copy(); A = I - nn
        for l, ex, cf in self.terms:
            P, dP, ddP = smooth.Sphere._poly(cf, ex, M); aa = 1 - l
            h += P; x += aa * P[:, None] * M + dP
            A += (P[:, None, None] * (aa * I + aa * (aa - 2) * nn)
                  + aa * (np.einsum('ni,nj->nij', M, dP) + np.einsum('ni,nj->nij', dP, M)) + ddP)
        return h, x, A, nn


def critical(E, G, M, iters=60):
    """every critical point of hG reached by damped Newton from the unit vectors M:
    points, kind (rest / balance / saddle), hG, tangent Hessian eigenvalues"""
    M = M.copy()
    for _ in range(iters):
        h_, x_, A_, nn_ = E.at(M); P = np.eye(3) - nn_
        g = np.einsum('nij,nj->ni', P, x_ - G)
        hg = h_ - M @ G
        Ht = np.einsum('nij,njk,nkl->nil', P, A_ - hg[:, None, None] * np.eye(3), P) + nn_
        d = -np.linalg.solve(Ht, g[..., None])[..., 0]
        d *= np.minimum(1, 0.05 / (np.linalg.norm(d, axis=1) + 1e-30))[:, None]
        M = M + d; M /= np.linalg.norm(M, axis=1)[:, None]
    h_, x_, A_, nn_ = E.at(M); P = np.eye(3) - nn_
    g = np.linalg.norm(np.einsum('nij,nj->ni', P, x_ - G), axis=1)
    M = M[g < 1e-11]
    from scipy.spatial import cKDTree
    from scipy.sparse import coo_matrix
    from scipy.sparse.csgraph import connected_components
    pr = np.array(sorted(cKDTree(M).query_pairs(1e-6))).reshape(-1, 2)
    nc, lab = connected_components(coo_matrix((np.ones(len(pr)), (pr[:, 0], pr[:, 1])), shape=(len(M),) * 2))
    keep = M[np.unique(lab, return_index=True)[1]].reshape(-1, 3)
    h_, x_, A_, nn_ = E.at(keep); hg = h_ - keep @ G
    ev = np.linalg.eigvalsh(A_ + 10 * nn_)[:, :2] - hg[:, None]
    kind = np.where((ev > 0).all(1), 'rest', np.where((ev < 0).all(1), 'balance', 'saddle'))
    return keep, kind, hg, ev


def run(c):
    E = Exact(c)
    N, F = smooth.icosphere(LEVEL)
    a, b, cc = N[F[:, 0]], N[F[:, 1]], N[F[:, 2]]
    ar = np.linalg.norm(np.cross(b - a, cc - a), axis=1) / 2
    w = np.zeros(len(N)); np.add.at(w, F.ravel(), np.repeat(ar / 3, 3)); w *= 4 * np.pi / w.sum()
    h, x, A, nn = E.at(N)
    rad = np.linalg.eigvalsh(A + 10 * nn)[:, :2]; det = rad[:, 0] * rad[:, 1]
    V = (h * det * w).sum() / 3; G = (x * (h * det * w)[:, None]).sum(0) / (4 * V)
    from scipy.spatial import cKDTree
    s = 90.0 / (h + h[cKDTree(N).query(-N)[1]]).max()
    hG = h - N @ G
    Eg = np.unique(np.sort(np.concatenate([F[:, [0, 1]], F[:, [1, 2]], F[:, [2, 0]]]), 1), axis=0)
    mn, mx = smooth._persist(hG, Eg), smooth._persist(-hG, Eg)
    keep, kind, hg, ev = critical(E, G, smooth.icosphere(5)[0])
    Qv = np.nan
    if (kind == 'rest').sum() == 1 and (kind == 'balance').sum() == 1:
        r, t = keep[kind == 'rest'][0], keep[kind == 'balance'][0]
        gg = np.linalg.norm(x - G - ((x - G) * N).sum(1)[:, None] * N, axis=1)
        Qv = (gg / np.sqrt(np.maximum(1 - np.maximum(N @ r, N @ t) ** 2, 1e-12))).min() * s
    nS, nU, nX = (kind == 'rest').sum(), (kind == 'balance').sum(), (kind == 'saddle').sum()
    cnt = lambda Lx, t: sum(1 for d_, _ in Lx if d_ * s > t / 1000)
    out = (f"exact: {nS} resting, {nU} balancing, {nX} saddles (Euler {nS - nX + nU}); "
           f"grid L7 counts (0.5,2,5,20 um): " + ', '.join(f"{cnt(mn, t)}/{cnt(mx, t)}" for t in (0.5, 2, 5, 20))
           + f"; Q on L7 {Qv:.3f} mm/rad; radius min {rad.min() * s:.2f} mm; widths {np.round(np.sort(np.ptp(x, 0)) * s, 1)}")
    return out, dict(G=G, s=s, crit=keep, kind=kind, hG=hg * s, ev=ev * s, mn=[(d * s, N[i]) for d, i in mn[:6]],
                     mx=[(d * s, N[i]) for d, i in mx[:6]])


if __name__ == '__main__':
    for p in sys.argv[1:]:
        out, r = run(np.load(p)); print(p, out, flush=True)
        for k, hg, ev in sorted(zip(r['kind'], r['hG'], r['ev']), key=lambda t: t[1]):
            print(f"   {k:8s} height {hg:8.4f} mm  hessian {ev[0]:9.3f} {ev[1]:9.3f}")
        print('   grid depths rest  ', [f"{d:.4f}" for d, _ in r['mn'][1:4]], ' balance', [f"{d:.4f}" for d, _ in r['mx'][1:4]])
