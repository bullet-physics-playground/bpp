"""Shared builder, score and CMA-ES loop for the families (families chat, 18 Nov 2026).

A family maps a short genome to the K x nb coefficient matrix of ../../monostable-search/edged.py
(r(u) = min_k exp(sum_j A_kj s_j Y_j(u)), real harmonics to degree L), so edged.body / equilibria do the rest.
  c3      one free piece (nb numbers) copied at 0, 120, 240 deg about y (edged's polar axis, upright), plus a round piece (L+1 numbers, m = 0
          only). Threefold symmetric: a (1,1) body must have rest and top on the y axis, 180 deg apart.
  mirror  K free pieces, each made even under x -> -x (mirror plane x = 0 holds the y axis).
  free    K free pieces (as edged_search.py); min_pieces sets how many must show.
Harmonic rotations and reflections are found numerically (least squares on the grid), so no sign conventions.

  python3 fam.py FAMILY TAG SECONDS SEED [K] [START.npy]      writes best_<FAMILY>_<TAG>.npy next to this file
Env: L (4), SIGMA (0.05 random start / 0.004 warm), CONV (0.0003 = 0.3 um), POP (16), MINPIECES (free: 3)."""
import os, sys, time, numpy as np
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, os.path.join(HERE, '../../monostable-search'))
import edged

L = int(os.environ.get('L', 4))
CONV = float(os.environ.get('CONV', 0.0003))
_M = {}


def _transform(kind, angle=0.0):
    """matrix M with f(T u) = Y(u) (M a) for f = Y a, T a rotation about y or the reflection x -> -x"""
    key = (kind, round(angle, 9), L)
    if key not in _M:
        g = edged.grid(L, 4); Ys = g.Y
        if kind == 'rot':
            c, s = np.cos(angle), np.sin(angle); T = np.array([[c, 0, s], [0, 1.0, 0], [-s, 0, c]])
        else:
            T = np.diag([-1.0, 1.0, 1.0])
        Yt = edged.Ybasis(L, g.N @ T.T) * g.scale
        _M[key] = np.linalg.lstsq(Ys, Yt, rcond=None)[0]
    return _M[key]


def m0_index():
    M = _transform('rot', 1.0); return np.where(np.abs(np.diag(M) - 1) < 1e-6)[0]


def nb(): return (L + 1) ** 2


def build(fam, x, K=3):
    """genome -> (K', nb) coefficient matrix"""
    n = nb()
    if fam == 'c3':
        a = x[:n]; b = np.zeros(n); b[m0_index()] = x[n:n + L + 1]
        return np.array([a] + [_transform('rot', 2 * np.pi * k / 3) @ a for k in (1, 2)] + [b])
    if fam == 'mirror':
        P = (np.eye(n) + _transform('ref')) / 2
        return np.array([P @ x[k * n:(k + 1) * n] for k in range(K)])
    return x.reshape(K, n)


def genome_size(fam, K=3): return nb() + L + 1 if fam == 'c3' else K * nb()


def face_lever(A, level=6):
    """exact face lever (mm at 90) per grid direction, tilt of its face normal from the rest normal (deg),
    max / min radius, rest-top angle seen from the centre of mass (deg)"""
    K = len(A); g = edged.grid(L, level); sc = g.scale
    U = g.N; LL = g.Y @ A.T; kk = LL.argmin(1); r = np.exp(LL.min(1))
    V = (r ** 3 * g.w).sum() / 3; G = ((r ** 4 * g.w)[:, None] * U).sum(0) / (4 * V)
    e = 1e-5; t1 = np.cross(U, [0.3, 0.5, 0.8]); t1 /= np.linalg.norm(t1, axis=1)[:, None]; t2 = np.cross(U, t1)
    def fk(W): W = W / np.linalg.norm(W, axis=1)[:, None]; return ((edged.Ybasis(L, W) * sc) @ A.T)[np.arange(len(U)), kk]
    g1 = (fk(U + e * t1) - fk(U - e * t1)) / (2 * e); g2 = (fk(U + e * t2) - fk(U - e * t2)) / (2 * e)
    n = U - g1[:, None] * t1 - g2[:, None] * t2; n /= np.linalg.norm(n, axis=1)[:, None]
    R = r[:, None] * U - G; d = np.linalg.norm(R, axis=1); s = 90.0 / (2 * d.max())
    lev = np.linalg.norm(R - (R * n).sum(1)[:, None] * n, axis=1) * s
    i0, i1 = np.argmin(d), np.argmax(d)
    tilt = np.degrees(np.arccos(np.clip(n @ n[i0], -1, 1)))
    from_top = np.degrees(np.arccos(np.clip(n @ (R[i1] / d[i1]), -1, 1)))
    ang = np.degrees(np.arccos(np.clip(R[i0] @ R[i1] / (d[i0] * d[i1]), -1, 1)))
    return lev, tilt, d.max() / d.min(), ang, from_top


TARGET = float(os.environ.get("TARGET", 0.45))   # mm at 36: 0.05 friction + a 1 deg slope push (0.3) + about 0.1 lost to printed layer flats


def deficit(lev, tilt, from_top):
    """mean shortfall (mm at 36) of the exact lever below TARGET, over grid directions more than 25 deg from
    upright and 10 deg from the top (grid directions are near-uniform)"""
    m = (tilt > 25) & (from_top > 10)
    return np.maximum(0.0, TARGET - 0.4 * lev[m]).mean()


def extras(B):
    mn, mx = edged.equilibria(B)
    return sum(x for x, _ in mn[1:] if x > 0), sum(x for x, _ in mx[1:] if x > 0)


def score(x, fam, K=3, min_pieces=0):
    """lower is better; staged like edged_search.py (feasible scores are below 1), then the lever deficit"""
    try:
        A = build(fam, np.asarray(x), K); Kp = len(A); a = A.ravel()
        B = edged.body(a, Kp, L, 5)
        if not np.isfinite(B['X']).all(): return 1e5
        shown = len(np.unique(B['piece']))
        pen = 20.0 * max(0, min_pieces - shown)
        if B['conv'] > CONV: return 1e4 + 1e3 * B['conv'] + pen
        eS, eU = extras(B)
        if eS + eU > 0.0005: return 100 + 100 * (3 * eS + eU) + pen
        B6 = edged.body(a, Kp, L, 6); eS, eU = extras(B6)
        if B6['conv'] > CONV or eS + eU > 0.0005: return 50 + 100 * (3 * eS + eU + B6['conv']) + pen
        lev, tilt, rr, ang, ft = face_lever(A)
        return deficit(lev, tilt, ft) + 100 * max(0.0, 1.20 - rr) + pen
    except Exception:
        return 1e5


def _score_star(args): return score(*args)


if __name__ == '__main__':
    import cma
    from multiprocessing import Pool
    fam, tag, tlim, seed = sys.argv[1], sys.argv[2], float(sys.argv[3]), int(sys.argv[4])
    K = int(sys.argv[5]) if len(sys.argv) > 5 else 3
    mp = int(os.environ.get('MINPIECES', 3 if fam == 'free' else 0))
    n = genome_size(fam, K); rng = np.random.default_rng(seed)
    if len(sys.argv) > 6: x0 = np.load(sys.argv[6]); sig = float(os.environ.get('SIGMA', 0.004))
    else:
        x0 = rng.normal(0, 0.03, n); sig = float(os.environ.get('SIGMA', 0.05))
        if fam == 'c3': x0[nb():nb() + 2] += [0.05, 0.15]     # round piece below the three copies at the bottom
    out = os.path.join(HERE, f'best_{fam}_{tag}.npy')
    best, t0 = (score(x0, fam, K, mp), x0), time.time(); print(f'{fam} K={K} L={L} n={n} start {best[0]:.4f}', flush=True)
    es = cma.CMAEvolutionStrategy(x0, sig, {'popsize': int(os.environ.get('POP', 16)), 'seed': seed, 'verbose': -9})
    with Pool(2) as pool:
        it = 0
        while time.time() - t0 < tlim and not es.stop():
            xs = es.ask(); fs = pool.map(_score_star, [(x, fam, K, mp) for x in xs]); es.tell(xs, fs); it += 1
            k = int(np.argmin(fs))
            if fs[k] < best[0]: best = (fs[k], np.array(xs[k])); np.save(out, best[1])
            if it % 10 == 0: print(f'it {it} t={time.time() - t0:.0f}s best {best[0]:.4f} sigma {es.sigma:.4f}', flush=True)
    print('FINAL', best[0], flush=True)
