"""Drop test for edged bodies (genomes-edged/*.npy, 3 pieces, L = 4): the convex hull of the level-6
samples, creases included (about 83,000 faces), then exactly drop.py's test.
  python3 edged_drop.py N genomes-edged/mono-e1.npy ...      (about 4 s a drop)"""
import sys, os
import numpy as np
from scipy.spatial import ConvexHull
import edged, build, drop


def mesh(a, K=3, L=4):
    B = edged.body(a, K, L, 6); mn, mx = edged.equilibria(B)
    X = B['X']; F = ConvexHull(X).simplices.copy()
    n = np.cross(X[F[:, 1]] - X[F[:, 0]], X[F[:, 2]] - X[F[:, 0]])
    flip = (n * X[F].mean(1)).sum(1) < 0; F[flip] = F[flip][:, [0, 2, 1]]
    vol, com, I = build.mass(X, F); R = np.linalg.eigh(I)[1]            # principal axes, as drop.py expects
    down = X[mn[0][1]] / np.linalg.norm(X[mn[0][1]])
    return (X - com) @ R, F, down @ R


if __name__ == '__main__':
    n = int(sys.argv[1])
    for path in sys.argv[2:]:
        X, F, down = mesh(np.load(path))
        build.body = lambda c, X=X, F=F: (X, F); build.stable = lambda X_, F_, d=down: [(None, d)]
        t = drop.run(None, n)
        print(f"{os.path.basename(path)[:-4]}: upright {100 * (t < 10).mean():.0f}% of {n}, median tilt {np.median(t):.1f} deg,"
              f" others at {np.round(np.sort(t[t >= 10])).astype(int).tolist()}", flush=True)
