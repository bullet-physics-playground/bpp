"""Family 0: mono-e2 with its weak levers raised (families chat, 17 Nov 2026).
  python3 search0.py TAG SECONDS SEED [START.npy]       CMA-ES from mono-e2 (or START), K = 3, L = 4
score (lower is better), as edged_search.py for feasibility, then the exact-surface lever:
  not convex (sample deeper than 1 um inside the hull)        1e4 + 1e3 * depth
  extra resting / balancing points, level-5 graph (> 0.5 um)  100 + 100 * (3 eS + eU)
  the same on the level-6 graph                               50 + ...
  otherwise  -(soft floor of the lever at 36 mm beyond 25 deg from upright): the mean of the lowest 0.5% of
  the exact face levers on the level-6 grid (face normals from the harmonics, so no facets), mm at 36,
  less 1 for each 0.01 that max / min radius falls below 1.30 (keep the look)."""
import os, sys, time, numpy as np, cma
from multiprocessing import Pool
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, os.path.join(HERE, '../../monostable-search'))
import edged

K, L = 3, 4


def face_lever(a, level=6):
    """exact lever (mm at 90) at every grid direction, the tilt of its face normal from the rest normal (deg),
    and max / min radius"""
    g = edged.grid(L, level); A = a.reshape(K, g.nb); sc = g.scale
    U = g.N; LL = g.Y @ A.T; kk = LL.argmin(1); r = np.exp(LL.min(1))
    V = (r ** 3 * g.w).sum() / 3; G = ((r ** 4 * g.w)[:, None] * U).sum(0) / (4 * V)
    e = 1e-5; t1 = np.cross(U, [0.3, 0.5, 0.8]); t1 /= np.linalg.norm(t1, axis=1)[:, None]; t2 = np.cross(U, t1)
    def fk(W): W = W / np.linalg.norm(W, axis=1)[:, None]; return ((edged.Ybasis(L, W) * sc) @ A.T)[np.arange(len(U)), kk]
    g1 = (fk(U + e * t1) - fk(U - e * t1)) / (2 * e); g2 = (fk(U + e * t2) - fk(U - e * t2)) / (2 * e)
    n = U - g1[:, None] * t1 - g2[:, None] * t2; n /= np.linalg.norm(n, axis=1)[:, None]
    R = r[:, None] * U - G; d = np.linalg.norm(R, axis=1)
    s = 90.0 / (2 * d.max())                                   # diameter ~90 mm (as edged.body, near enough)
    lev = np.linalg.norm(R - (R * n).sum(1)[:, None] * n, axis=1) * s
    rest_n = n[np.argmin(d)]
    tilt = np.degrees(np.arccos(np.clip(n @ rest_n, -1, 1)))
    return lev, tilt, d.max() / d.min()


def extras(B):
    mn, mx = edged.equilibria(B)
    return sum(x for x, _ in mn[1:] if x > 0), sum(x for x, _ in mx[1:] if x > 0)


def score(a):
    try:
        B = edged.body(a, K, L, 5)
        if not np.isfinite(B['X']).all(): return 1e5
        if B['conv'] > 0.001: return 1e4 + 1e3 * B['conv']
        eS, eU = extras(B)
        if eS + eU > 0.0005: return 100 + 100 * (3 * eS + eU)
        B6 = edged.body(a, K, L, 6); eS, eU = extras(B6)
        if B6['conv'] > 0.001 or eS + eU > 0.0005: return 50 + 100 * (3 * eS + eU + B6['conv'])
        lev, tilt, rr = face_lever(a)
        far = np.sort(0.4 * lev[tilt > 25]); floor = far[:max(1, len(far) // 200)].mean()
        return -floor + 100 * max(0.0, 1.30 - rr)
    except Exception:
        return 1e5


if __name__ == '__main__':
    TAG, TLIM, SEED = sys.argv[1], float(sys.argv[2]), int(sys.argv[3])
    x0 = np.load(sys.argv[4] if len(sys.argv) > 4 else os.path.join(HERE, '../mono-e2/mono-e2.npy'))
    f0 = score(x0); print(f'start score {f0:.4f}', flush=True)
    best, t0 = (f0, x0), time.time()
    es = cma.CMAEvolutionStrategy(x0, float(os.environ.get('SIGMA', 0.004)), {'popsize': 16, 'seed': SEED, 'verbose': -9})
    with Pool(2) as pool:
        it = 0
        while time.time() - t0 < TLIM and not es.stop():
            xs = es.ask(); fs = pool.map(score, xs); es.tell(xs, fs); it += 1
            k = int(np.argmin(fs))
            if fs[k] < best[0]: best = (fs[k], np.array(xs[k])); np.save(os.path.join(HERE, f'f0_best_{TAG}.npy'), best[1])
            if it % 5 == 0:
                print(f'it {it} t={time.time() - t0:.0f}s best {best[0]:.4f}  gen-min {min(fs):.4f}  feasible {sum(f < 0 for f in fs)}/16', flush=True)
    print('FINAL', best[0], flush=True)
