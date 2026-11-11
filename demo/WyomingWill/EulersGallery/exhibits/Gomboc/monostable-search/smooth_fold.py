"""Annihilate the last extra pair (a balancing point and a saddle about to merge) by continuation.
Near the fold the pair's curvature k satisfies k^2 ~ linear in the shape, so step c along -grad(k^2)
to k^2 = 0 and a little past.   python3 smooth_fold.py in.npy out.npy
The centre of mass is taken on a level-7 icosphere, as smooth_check.py: at a fold the level-5 one is not close enough."""
import sys
import numpy as np
import smooth
from smooth_check import Exact, critical

c = np.load(sys.argv[1]); L = next(L for L in range(2, 20) if (L + 1) ** 2 - 4 == len(c))
S = smooth.Sphere(L); START = smooth.icosphere(4)[0]
N7, F7 = smooth.icosphere(7)
_a, _b, _c = N7[F7[:, 0]], N7[F7[:, 1]], N7[F7[:, 2]]
W7 = np.zeros(len(N7)); np.add.at(W7, F7.ravel(), np.repeat(np.linalg.norm(np.cross(_b - _a, _c - _a), axis=1) / 6, 3))
W7 *= 4 * np.pi / W7.sum()


def G7(E):
    h, x, A, nn = E.at(N7); r = np.linalg.eigvalsh(A + 10 * nn)[:, :2]; w = h * r[:, 0] * r[:, 1] * W7
    return (x * w[:, None]).sum(0) / (4 * w.sum() / 3)


def crits(c):
    B = S.body(c); E = Exact(c, S); P, kind, hg, ev = critical(E, G7(E), START, 40)
    return B, P, kind, hg, ev


def k2(c, near):
    """squared least |curvature| (mm/rad) of the critical point nearest 'near' that is not the rest or top"""
    B, P, kind, hg, ev = crits(c)
    main = [np.argmin(np.where(kind == 'rest', hg, np.inf)), np.argmax(np.where(kind == 'balance', hg, -np.inf))]
    extra = [i for i in range(len(P)) if i not in main]
    if not extra: return None, None
    i = min(extra, key=lambda i: np.linalg.norm(P[i] - near))
    return (np.abs(ev[i]).min() * B['s']) ** 2, P[i]


B, P, kind, hg, ev = crits(c)
print('start:', dict(zip(*np.unique(kind, return_counts=True))))
near = P[np.argmin(np.abs(ev).min(1))]
for step in range(30):
    f, near2 = k2(c, near)
    if f is None:
        print('pair gone at step', step); c = c + 4 * last; break
    near = near2; eps = 1e-5
    g = np.array([(k2(c + eps * e, near)[0] or 0) - f for e in np.eye(len(c))]) / eps
    last = -1.3 * f * g / (g @ g); c = c + last
    print(f'step {step}: k^2 {f:.5f}, |dc| {np.linalg.norm(1.3 * f * g / (g @ g)):.2e}', flush=True)
B, P, kind, hg, ev = crits(c)
print('end:', dict(zip(*np.unique(kind, return_counts=True))), 'radius min', B['rad'].min() * B['s'])
np.save(sys.argv[2], c)
