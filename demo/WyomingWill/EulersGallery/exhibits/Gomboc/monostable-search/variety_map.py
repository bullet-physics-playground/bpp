"""Variety map (MAP-Elites) of self-righting convex bodies, scored by prescreen.py's stall metric.
  python3 variety_map.py TAG SECONDS SEED       archive saved to map_TAG.npz (keys, genomes, res)
Genome: build.py genome, L = 6 (45 numbers), body built by build.py (level-5 icosphere, 90 mm).
Cell: rest height (centre of mass above the table at rest, mm at 90, 12-42 in 8 bins) x middle / longest principal
extent (0.35-1.0, 8 bins). Score (lower is better): the worst predicted stall over aligned, vertical slip +- and
sideways slip +- (0.25 mm at 90 = 0.1 mm at 36, on the body unlayered), each the mean over rolling friction 0.15 and
0.3 mm; plus 0.05 x the share of directions more than 25 deg from upright whose lever is under 0.3 mm at 36.
Seeds: mono-p1, s2..s7 and 57 random genomes; then batches of 32 children, each a mutated elite (Gaussian, sigma
0.003-0.04), 20% after uniform crossover with another elite. A fast screen: finalists go to prescreen.py."""
import sys, os, numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from multiprocessing import Pool
from scipy.spatial import ConvexHull, cKDTree
import build, smooth, prescreen as ps
NP = 45; HB = np.linspace(12, 42, 9); RB = np.linspace(0.35, 1.0, 9)


def slipped(X, d, kind, sign=1, v=0.25):
    """the +n half (n = xhat - (xhat.d) d) moves by v along up = -d ('vertical') or n x up ('side');
    centre of mass moves by v x the volume share moved"""
    x = np.array([1.0, 0, 0]); n = x - (x @ d) * d; n /= np.linalg.norm(n)
    up = -d; w = (up if kind == 'vertical' else np.cross(n, up)) * v * sign
    H = ConvexHull(X); P = X[H.vertices]; s = P @ n
    E = H.simplices[:, [0, 1, 1, 2, 2, 0]].reshape(-1, 2); a, b = X[E[:, 0]], X[E[:, 1]]; sa, sb = a @ n, b @ n
    cr = (sa > 0) != (sb > 0); t = sa[cr] / (sa[cr] - sb[cr]); C = a[cr] + t[:, None] * (b[cr] - a[cr])
    frac = ConvexHull(np.r_[P[s > 0], C]).volume / H.volume
    return np.r_[P[s <= 0], C, P[s > 0] + w, C + w] - w * frac


def evaluate(c):
    try:
        X, F = build.body(c); P = ps.prep(X); d = P['down']
        rest_h = P['h'].min(); ext = np.sort(np.ptp(X, 0))[::-1]; ratio = ext[1] / ext[0]
        worst = ps.stall(P).mean()
        for kind in ('vertical', 'side'):
            for sg in (1, -1):
                worst = max(worst, ps.stall(ps.prep(slipped(X, d, kind, sg))).mean())
        st = cKDTree(P['n']).query(smooth.icosphere(4)[0])[1]; far = P['n'][st] @ d < np.cos(np.radians(25))
        floor = (far & (0.4 * P['lam'][st] < 0.3)).mean()
        return worst + 0.05 * floor, rest_h, ratio, worst, floor
    except Exception:
        return np.inf, 0, 0, np.inf, 1


def cell(h, r):
    i, j = np.searchsorted(HB, h) - 1, np.searchsorted(RB, r) - 1
    return (i, j) if 0 <= i < 8 and 0 <= j < 8 else None


if __name__ == '__main__':
    import time
    TAG, TLIM, SEED = sys.argv[1], float(sys.argv[2]), int(sys.argv[3])
    rng = np.random.default_rng(SEED); G = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'genomes')
    seeds = []
    for nm in ('mono-p1', 'mono-s2', 'mono-s3', 'mono-s4', 'mono-s5', 'mono-s6', 'mono-s7'):
        c = np.load(os.path.join(G, nm + '.npy')); seeds.append(np.r_[c, np.zeros(NP - len(c))])
    seeds += [rng.normal(0, s, NP) for s in rng.choice([0.01, 0.03, 0.06], 57)]
    arch = {}; t0 = time.time(); n = 0
    def insert(c, r):
        k = cell(r[1], r[2])
        if k is not None and np.isfinite(r[0]) and (k not in arch or r[0] < arch[k][1][0]): arch[k] = (c, r)
    with Pool(2) as pool:
        for c, r in zip(seeds, pool.map(evaluate, seeds)): insert(c, r); n += 1
        while time.time() - t0 < TLIM:
            keys = list(arch); kids = []
            for _ in range(32):
                p = arch[keys[rng.integers(len(keys))]][0]
                if rng.random() < 0.2:
                    q = arch[keys[rng.integers(len(keys))]][0]; m = rng.random(NP) < 0.5; p = np.where(m, p, q)
                kids.append(p + rng.normal(0, rng.choice([0.003, 0.01, 0.02, 0.04]), NP))
            for c, r in zip(kids, pool.map(evaluate, kids)): insert(c, r)
            n += 32
            if n % 640 == 0 or time.time() - t0 >= TLIM:
                sc = np.array([v[1][0] for v in arch.values()])
                print(f't={time.time()-t0:.0f}s evals {n} cells {len(arch)}/64  best {sc.min():.4f}  under 0.02: {(sc < 0.02).sum()}', flush=True)
                ks = sorted(arch); np.savez(f'map_{TAG}.npz', keys=np.array(ks), genomes=np.array([arch[k][0] for k in ks]),
                                            res=np.array([arch[k][1] for k in ks]))
