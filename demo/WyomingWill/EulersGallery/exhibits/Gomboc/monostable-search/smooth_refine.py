"""Push a smooth body to an exact (1,1) by maximising Q.  python3 smooth_refine.py TAG SECONDS L SEED [start.npy]
(saves q_best_TAG.npy; environment SIGMA = first step from start.npy, default 0.003; LEVEL = grid, default 5)
g(n) = tangential part of x(n) - G (zero exactly at equilibria). Q = min over the grid of |g| / sin(angle to
the nearer of the rest and the top), in mm per radian at 90 mm: Q > 0 means no other equilibria, and at the rest
and the top it is the least curvature of hG there (the rocking margin). Non-convex bodies score worse.
Tier 1: extra minima/maxima of hG on the grid (any depth over 0.5 um in total) score 100 + 100 * (3 eS + eU).
Tier 2: otherwise an exact count (damped Newton from the 2562 points of a level-4 icosphere); with extra
equilibria the score is 10 + their number + sum of tanh(least |curvature| / 5 mm). Tier 3: Q, for exact (1,1)."""
import sys, time, os
import numpy as np, cma
from multiprocessing import Pool
import smooth
from smooth_check import Exact, critical

a = sys.argv[1:]; TAG, TLIM, L, SEED = a[0], float(a[1]), int(a[2]), int(a[3]); START = a[4] if len(a) > 4 else None
NP = (L + 1) ** 2 - 4
S = smooth.Sphere(L, level=int(os.environ.get('LEVEL', 5)))
START4 = smooth.icosphere(4)[0]


def Q(c):
    B = S.body(c); s = B['s']; rmin = B['rad'].min()
    if rmin * s < 0.2: return -1e3 * (1 - (rmin * s - 0.2) / 90)   # radius of curvature >= 0.2 mm everywhere
    N, G = S.N, B['G']
    g = np.linalg.norm(B['x'] - G - ((B['x'] - G) * N).sum(1)[:, None] * N, axis=1)
    mn, mx = S.equilibria(B['hG'])                  # tier 1: extra depths seen on the grid
    eS = sum(d for d, _ in mn[1:] if d > 0) * s; eU = sum(d for d, _ in mx[1:] if d > 0) * s
    if eS + eU > 0.0005: return -(100 + 100 * (3 * eS + eU))
    E = Exact(c, S)                                 # tier 2: exact count from 2562 fixed starts
    P, kind, hg, ev = critical(E, G, START4, 30)
    if len(P) < 3 or 'rest' not in kind or 'balance' not in kind: return -100.0
    extra = [i for i in range(len(P)) if not ((kind[i] == 'rest' and hg[i] == hg[kind == 'rest'].min())
                                              or (kind[i] == 'balance' and hg[i] == hg[kind == 'balance'].max()))]
    if extra:
        return -(10 + len(extra) + np.tanh(np.abs(ev[extra] * s).min(1) / 5).sum())
    r, t = P[kind == 'rest'][0], P[kind == 'balance'][0]
    sn = np.sqrt(np.maximum(1 - np.maximum(N @ r, N @ t) ** 2, 1e-12))
    return (g / sn).min() * s


def score(c): return -Q(c)


if __name__ == '__main__':
    rng = np.random.default_rng(SEED)
    v0 = np.load(START) if START else rng.normal(0, 0.01, NP)
    es = cma.CMAEvolutionStrategy(v0, float(os.environ.get('SIGMA', 0.003)) if START else 0.02, {'popsize': 16, 'seed': SEED + 1, 'verbose': -9})
    best, it, t0 = (np.inf, None), 0, time.time()
    with Pool(2) as pool:
        while time.time() - t0 < TLIM and not es.stop():
            xs = es.ask(); fs = pool.map(score, xs); es.tell(xs, fs); it += 1
            k = int(np.argmin(fs))
            if fs[k] < best[0]: best = (fs[k], np.array(xs[k])); np.save(f'q_best_{TAG}.npy', best[1])
            if it % 20 == 0: print(f'it {it} t={time.time() - t0:.0f}s ' + (f'Q {-best[0]:.4f} mm/rad' if best[0] < 0 else (f'grid extras {(best[0]-100)*10:.1f} um' if best[0] >= 100 else f'exact extras score {best[0]:.3f}')) + f' sigma {es.sigma:.4f}', flush=True)
    print('FINAL Q', -best[0], flush=True)
