"""(1,1) search on smooth bodies.  python3 smooth_search.py TAG SECONDS L SEED   (saves sm_best_TAG.npy)
stage 1: penalty = 3 * extra resting depth (> 2 um) + extra balancing depth (> 5 um), mm at 90 mm;
         non-convex (a negative radius of curvature) scores worse than any convex body.
stage 2: maximise the rocking margin at the rest, capped at 3 mm."""
import sys, time
import numpy as np, cma
from multiprocessing import Pool
import smooth

TAG, TLIM, L, SEED = sys.argv[1], float(sys.argv[2]), int(sys.argv[3]), int(sys.argv[4])
NP = (L + 1) ** 2 - 4; MCAP = 3.0
S = smooth.Sphere(L)


def parts(c):
    B = S.body(c); s = B['s']; rmin = B['rad'].min()
    if rmin < 0: return 1e4 * (1 - rmin * s / 90), None
    mn, mx = S.equilibria(B['hG'])
    eS = sum(d * s for d, _ in mn[1:] if d * s > 0.002); eU = sum(d * s for d, _ in mx[1:] if d * s > 0.005)
    if eS + eU > 0: return 100 + 100 * (3 * eS + eU), (eS, eU)
    return -min(smooth.margin(S, B, mn[0][1]), MCAP), (0, 0)


def score(c): return parts(c)[0]


if __name__ == '__main__':
    rng = np.random.default_rng(SEED)
    es = cma.CMAEvolutionStrategy(rng.normal(0, 0.01, NP), 0.02, {'popsize': 16, 'seed': SEED + 1, 'verbose': -9})
    best, itb, it, t0 = (np.inf, None), 0, 0, time.time()
    with Pool(2) as pool:
        while time.time() - t0 < TLIM and not es.stop():
            xs = es.ask(); fs = pool.map(score, xs); es.tell(xs, fs); it += 1
            k = int(np.argmin(fs))
            if fs[k] < best[0]: best, itb = (fs[k], np.array(xs[k])), it; np.save(f'sm_best_{TAG}.npy', best[1])
            if best[0] <= -MCAP + 1e-9 and it - itb > 100: break
            if it % 20 == 0:
                f, p = parts(best[1])
                st = f'(1,1) FOUND, margin {-f:.2f} mm' if f < 0 else (f'convex? no' if p is None else f'extra rest {p[0]*1000:.0f} um, extra balance {p[1]*1000:.0f} um')
                print(f'it {it} t={time.time() - t0:.0f}s {st} sigma {es.sigma:.4f}', flush=True)
    print('FINAL', smooth.report(S, best[1])[3], flush=True)
