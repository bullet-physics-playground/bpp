"""Gradient lever (printing chat, 17 Nov): lever(u) = |grad h(u)|, h the support function of the hull, central
differences at +-0.5 deg in two tangent directions. Weak share beyond 25 deg: lever < 0.05 + h tan 1.5 (mm at 36)."""
import sys, numpy as np
sys.path[:0] = ['/home/claude/mono/monostable-search', '/home/claude/cal']
from scipy.spatial import ConvexHull
import build
def fib(n=40000):
    i = np.arange(n) + .5; z = 1 - 2 * i / n; r = np.sqrt(1 - z * z); t = np.pi * (1 + 5 ** .5) * i
    return np.c_[r * np.cos(t), z, r * np.sin(t)]
U = fib()
def hsup(V, W): return np.concatenate([(W[i:i + 4000] @ V.T).max(1) for i in range(0, len(W), 4000)])
def levers(Y, dl=np.radians(0.5)):
    X = Y[ConvexHull(Y).vertices]; vol, com, I = build.mass(X, build.outward(X, ConvexHull(X).simplices)); V = X - com
    a = np.where(np.abs(U[:, 0]) < 0.9, 0, 1); e = np.cross(U, np.eye(3)[a]); e /= np.linalg.norm(e, axis=1)[:, None]; f = np.cross(U, e)
    g = []
    for t in (e, f):
        g.append((hsup(V, np.cos(dl) * U + np.sin(dl) * t) - hsup(V, np.cos(dl) * U - np.sin(dl) * t)) / (2 * dl))
    h = hsup(V, U); S = np.concatenate([V[np.argmax(U[i:i+4000] @ V.T, 1)] for i in range(0, len(U), 4000)])
    sp = np.linalg.norm(S - h[:, None] * U, axis=1)
    return np.hypot(*g), sp, h
def report(nm, Y):
    gl, sp, h = levers(Y); d = U[np.argmin(h)]; tilt = np.degrees(np.arccos(np.clip(U @ d, -1, 1))); far = tilt > 25
    thr = 0.05 + h * np.tan(np.radians(1.5))
    ring = [gl[(tilt > r - 0.5) & (tilt < r + 0.5)].min() for r in (5, 10, 20)]
    print(f'{nm:10s} weak: gradient {100*(far&(gl<thr)).mean():5.1f}%  support-point {100*(far&(sp<thr)).mean():5.1f}%   '
          f'least gradient lever on 5/10/20 deg rings {np.round(ring,3)}', flush=True)
if __name__ == '__main__':
    for fn in sys.argv[1:]: report(fn.split('/')[-1].replace('.npy', ''), np.load(fn))
