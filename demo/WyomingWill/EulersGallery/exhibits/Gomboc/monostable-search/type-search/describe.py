"""Descriptors of a (1,1) body, to tell types apart.  python3 describe.py FILE ...  (edged genome .npy with K=3 L=4, or .obj)
  python3 describe.py ../genomes-edged/mono-e2.npy ../meshes/mono-g1.obj
angle   rest-top angle seen from the centre of mass (deg; the gomboc's is ~180)
pieces  smooth pieces showing (edged only); top/rest on crease?
mirror  best mirror miss over planes through the centre of mass (mm at 90)
shape   principal extents ratios; rest height, top distance"""
import sys, numpy as np
import os; sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
from scipy.spatial import ConvexHull, cKDTree
import edged, smooth


def mirror_miss(X):
    Y = X[ConvexHull(X).vertices]; t = cKDTree(Y); best = 1e9
    for n in smooth.icosphere(3)[0]:
        if n[np.argmax(np.abs(n))] < 0: continue
        R = Y - 2 * (Y @ n)[:, None] * n; m = t.query(R)[0].max()
        if m < best: best, nb = m, n
    from scipy.optimize import minimize
    f = lambda p: t.query(Y - 2 * (Y @ (n := (q := nb + np.r_[p, 0] @ np.eye(3)) / np.linalg.norm(q)))[:, None] * n)[0].max()
    r = minimize(f, [0, 0], method='Nelder-Mead', options=dict(xatol=1e-4, fatol=1e-3))
    f2 = lambda p: t.query(Y - 2 * (Y @ (n := (q := nb + np.r_[0, p[0], p[1]]) / np.linalg.norm(q)))[:, None] * n)[0].max()
    return min(best, r.fun, minimize(f2, [0, 0], method='Nelder-Mead').fun)


def describe(fn, K=3, L=4):
    if fn.endswith('.obj'):
        import build, prescreen as ps
        V = np.array([l.split()[1:4] for l in open(fn) if l.startswith('v ')], float); X = V[ConvexHull(V).vertices]
        vol, com, I = ps.mass(X, build.outward(X, ConvexHull(X).simplices)); X = (X - com) * 90.0 / np.ptp(X, 0).max()
        d = np.linalg.norm(X, axis=1); E = np.unique(np.sort(ConvexHull(X).simplices[:, [0,1,1,2,2,0]].reshape(-1, 2), 1), axis=0)
        mx = smooth._persist(-d, E); top = X[mx[0][1]]
        P = ps.prep(X); rest = -P['down'] * 0 + P['n'][np.argmin(P['h'])] * P['h'].min(); extra = ''
    else:
        a = np.load(fn); B = edged.body(a, K, L, 6); mn, mx = edged.equilibria(B); X = B['X']
        rest, top = X[mn[0][1]], X[mx[0][1]]; n0 = B['n0']
        extra = f"pieces {len(np.unique(B['piece']))}  top on crease {mx[0][1] >= n0}  rest on crease {mn[0][1] >= n0}"
    ang = np.degrees(np.arccos(rest @ top / np.linalg.norm(rest) / np.linalg.norm(top)))
    w, V = np.linalg.eigh(np.cov(X.T)); e = np.ptp(X @ V, 0); e = np.sort(e)[::-1]
    print(f"{fn.split('/')[-1]:14s} angle {ang:5.1f}  rest {np.linalg.norm(rest):5.1f}  top {np.linalg.norm(top):5.1f}  "
          f"extents {e[0]:.0f}x{e[1]:.0f}x{e[2]:.0f}  mirror miss {mirror_miss(X):.1f} mm  {extra}", flush=True)


if __name__ == '__main__':
    for f in sys.argv[1:]: describe(f)
