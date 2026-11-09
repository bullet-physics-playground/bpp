"""Search for a monostable convex body from scratch (CMA-ES over the genome of build.py).
  stage 1: drive the total depth of the extra resting points (deeper than 2 um at 90 mm) to zero;
  stage 2: then maximise the softest rocking margin at the rest (capped at 6 mm), less 0.5 mm for every
           unit by which the longest extent exceeds twice the shortest.
With --one-unstable the extra balancing points (deeper than 5 um) count in stage 1 too, at a third of the
weight of extra resting points: a search for a (1,1) body, a gomboc.
  python3 search.py OUT.npy SECONDS L SEED [--start GENOME.npy] [--one-unstable]
Needs numpy, scipy, cma (pip install cma; 4.5.0 used)."""
import sys, time
import numpy as np, cma
from multiprocessing import Pool
import build

a = sys.argv[1:]; OUT, TLIM, L, SEED = a[0], float(a[1]), int(a[2]), int(a[3])
START = a[a.index('--start') + 1] if '--start' in a else None
ONE_U = '--one-unstable' in a
NP = (L + 1) ** 2 - 4
MCAP = 6.0


def score(c):
    if (1.0 + build.sh_basis(L) @ c).min() <= 0.3: return 1e4
    try: X, F = build.body(c)
    except Exception: return 1e4
    S = build.stable(X, F)
    pen = sum(d for d, _ in S[1:] if d > 0.002)
    if ONE_U: pen = 3 * pen + sum(d for d, _ in build.unstable(X, F)[1:] if d > 0.005)
    if pen > 0: return 100 + 100 * pen
    e = np.sort(np.ptp(X, 0))
    return -(min(build.margin(X, S[0][1]), MCAP) - 0.5 * max(0, e[2] / e[0] - 2.0))


if __name__ == '__main__':
    rng = np.random.default_rng(SEED)
    v0 = np.load(START) if START else rng.normal(0, 0.03, NP)
    es = cma.CMAEvolutionStrategy(v0, 0.03 if START else 0.06, {'popsize': 16, 'seed': SEED + 1, 'verbose': -9})
    best, itb, it, t0 = (np.inf, None), 0, 0, time.time()
    with Pool() as pool:
        while time.time() - t0 < TLIM and not es.stop():
            xs = es.ask(); fs = pool.map(score, xs); es.tell(xs, fs); it += 1
            k = int(np.argmin(fs))
            if fs[k] < best[0]: best, itb = (fs[k], np.array(xs[k])), it; np.save(OUT, best[1])
            if best[0] <= -MCAP + 1e-9 and it - itb > 100: break
            if it % 10 == 0:
                st = f'found, score {-best[0]:.2f}' if best[0] < 0 else f'not yet, extra depth {(best[0] - 100) * 10:.0f} um'
                print(f'it {it}  {time.time() - t0:.0f} s  {st}', flush=True)
