"""Slope-tolerant (1,1) gomboc by smooth deformation of F2.   python3 gsearch.py TAG SECONDS SEED [SIGMA]
Body: F2's mesh vertices scaled radially (from the centre of mass) by exp(sum c_k Y_k), real spherical harmonics of
degree 2..6 (45 numbers), convex hull, centre of mass at origin, longest extent 90 mm, F2's frame (upright +y, long
axis x; cut plane x = 0).
Objective (lower is better): worst over aligned and the 0.1 mm vertical half-slip both ways of the share of directions
more than 25 deg from upright where the support-point lever is below 0.05 mm + h tan(1.5 deg), h the centre-of-mass
height in that orientation (mm at 36).  Constraints: exactly 1 resting and 1 balancing point deeper than 2 um at 90
mm; upright margin (least support-point lever on the 20 deg ring) >= 2.07 mm at 36 (L4's printed hull)."""
import sys, time, numpy as np
sys.path[:0] = ['/home/claude/mono/monostable-search', '/home/claude/cal']
from multiprocessing import Pool
from scipy.spatial import ConvexHull
import cma, edged, smooth, slope, prescreen as ps, variety_map as vm
V0 = slope.normal_form(slope.load_obj('/home/claude/f2zip/gomboc_F2.obj')); R0 = np.linalg.norm(V0, axis=1)
import os; LD = int(os.environ.get('GS_L', '6'))
B = edged.Ybasis(LD, V0 / R0[:, None])[:, 4:]; B = B / np.abs(B).max(0)            # degrees 2..LD (default 6)
U = smooth.icosphere(5)[0]; MARGIN = 2.07; TB = 0.002     # balancing-point depth threshold (mm at 90); 0.02 with --tb20


def body(c): return slope.normal_form(V0 * np.exp(B @ c)[:, None])


def sweak(X, d):
    V = X[ConvexHull(X).vertices]; x = V[np.argmax(U @ V.T, 1)]; hs = (x * U).sum(1)
    lev = 0.4 * np.linalg.norm(x - hs[:, None] * U, axis=1); far = U @ d < np.cos(np.radians(25))
    return (far & (lev < 0.05 + 0.4 * hs * np.tan(np.radians(1.5)))).mean()


def evaluate(c):
    try:
        X = body(c); P = ps.prep(X); d = P['down']; nr, nb = slope.counts(X, P, TB); m = slope.margin(X, d)
        pen = abs(nr - 1) + abs(nb - 1) + max(0, MARGIN - m)
        w = [sweak(X, d)] + [sweak(vm.slipped(X, d, 'vertical', s), d) for s in (1, -1)]
        return max(w) + pen, max(w), nr, nb, m
    except Exception:
        return 10.0, 1, 0, 0, 0


if __name__ == '__main__':
    if '--tb20' in sys.argv: sys.argv.remove('--tb20'); TB = 0.02
    TAG, TLIM, SEED = sys.argv[1], float(sys.argv[2]), int(sys.argv[3]); sig = float(sys.argv[4]) if len(sys.argv) > 4 else 0.01
    t0 = time.time(); best = (np.inf, None)
    x0 = np.zeros(B.shape[1])
    if os.environ.get('GS_X0'): c0 = np.load(os.environ['GS_X0']); x0[:len(c0)] = c0       # warm start, extra degrees at 0
    es = cma.CMAEvolutionStrategy(x0, sig, {'popsize': 16, 'seed': SEED, 'verbose': -9})
    with Pool(2) as pool:
        r0 = evaluate(x0); print(f'start: score {r0[0]:.4f} weak {100*r0[1]:.1f}% counts {r0[2]},{r0[3]} margin {r0[4]:.2f}', flush=True)
        g = 0
        while time.time() - t0 < TLIM:
            C = es.ask(); R = pool.map(evaluate, C); es.tell(C, [r[0] for r in R]); g += 1
            k = int(np.argmin([r[0] for r in R]))
            if R[k][0] < best[0]:
                best = (R[k][0], C[k], R[k]); np.save(f'gs_{TAG}.npy', C[k])
            if g % 5 == 0:
                b = best[2]; print(f't={time.time()-t0:.0f}s gen {g} best score {b[0]:.4f} weak {100*b[1]:.1f}% counts {b[2]},{b[3]} margin {b[4]:.2f}  sigma {es.sigma:.4f}', flush=True)
