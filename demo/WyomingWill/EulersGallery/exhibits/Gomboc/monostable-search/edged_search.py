"""Population search for an edged (1,1) body.  python3 edged_search.py TAG SECONDS K L SEED
CMA-ES, restarted from a fresh random start with twice the population whenever it converges (IPOP).
score: not convex (a sample deeper than 1 um inside the hull)  1e4 + 1e3 * depth
       extra resting / balancing points on the level-5 graph (total depth over 0.5 um)  100 + 100 * (3 eS + eU)
       otherwise, if the level-6 graph agrees (else 50 + its extra depth)  -Q, the weakest lever (mm/rad)"""
import sys, time
import numpy as np, cma
from multiprocessing import Pool
import edged

TAG, TLIM, K, L, SEED = sys.argv[1], float(sys.argv[2]), int(sys.argv[3]), int(sys.argv[4]), int(sys.argv[5])
NB = (L + 1) ** 2; NP = K * NB


def extras(B):
    mn, mx = edged.equilibria(B)
    eS = sum(d for d, _ in mn[1:] if d > 0); eU = sum(d for d, _ in mx[1:] if d > 0)
    return mn, mx, eS, eU


def score(a):
    try:
        B = edged.body(a, K, L, 5)
        if not np.isfinite(B['X']).all(): return 1e5
        if B['conv'] > 0.001: return 1e4 + 1e3 * B['conv']
        mn, mx, eS, eU = extras(B)
        if eS + eU > 0.0005: return 100 + 100 * (3 * eS + eU)
        B6 = edged.body(a, K, L, 6); _, _, eS6, eU6 = extras(B6)
        if B6['conv'] > 0.001 or eS6 + eU6 > 0.0005: return 50 + 100 * (3 * eS6 + eU6 + B6['conv'])
        Qf = edged.lever(B, mn[0][1], mx[0][1]); far = np.ones(len(Qf), bool)
        far[[i for i in (mn[0][1], mx[0][1]) if i < len(Qf)]] = False
        return -Qf[far].min()
    except Exception:
        return 1e5


def start(rng):
    a = rng.normal(0, 0.02, (K, NB)); a[:, 1:4] = rng.normal(0, 0.08, (K, 3))
    return a.ravel()


if __name__ == '__main__':
    rng = np.random.default_rng(SEED)
    best, t0, pop, run = (np.inf, None), time.time(), 16, 0
    with Pool(2) as pool:
        while time.time() - t0 < TLIM:
            es = cma.CMAEvolutionStrategy(start(rng), 0.05, {'popsize': pop, 'seed': SEED * 100 + run, 'verbose': -9})
            it = 0
            while time.time() - t0 < TLIM and not es.stop():
                xs = es.ask(); fs = pool.map(score, xs); es.tell(xs, fs); it += 1
                k = int(np.argmin(fs))
                if fs[k] < best[0]: best = (fs[k], np.array(xs[k])); np.save(f'e_best_{TAG}.npy', best[1])
                if it % 20 == 0:
                    f = best[0]
                    st = (f'(1,1) Q {-f:.4f} mm/rad' if f < 0 else f'L6 extra {(f - 50) * 10:.1f} um' if f < 100
                          else f'extra {(f - 100) * 10:.0f} um' if f < 1e4 else 'not convex')
                    print(f'run {run} pop {pop} it {it} t={time.time() - t0:.0f}s best: {st}  sigma {es.sigma:.4f}', flush=True)
            run += 1; pop *= 2
    print('FINAL', edged.report(best[1], K, L, 6)[3], flush=True)
