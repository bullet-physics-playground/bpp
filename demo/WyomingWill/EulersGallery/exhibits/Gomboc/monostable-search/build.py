"""Build the monostable shapes from their genomes and check them.

A genome is a vector of real spherical-harmonic coefficients c (degrees 2..L, l = 1 left out: it only
moves the body). The support function about the origin is h(n) = 1 + sum c_k Y_k(n) on the 10,242
directions n of an icosphere (level 5); the body is the intersection of the half-spaces x.n <= h(n),
so it is convex whatever c is. It is then moved to its exact centre of mass and scaled.

  python3 build.py genomes/mono-s2.npy ...           check: equilibria, margin
  python3 build.py --write meshes genomes/*.npy      also write <name>.obj and <name>.lua (9 cm, in cm)
Needs Python 3, numpy, scipy (1.15 or later, for sph_harm_y)."""
import sys, os
import numpy as np
from scipy.spatial import ConvexHull
from scipy.special import sph_harm_y


def icosphere(level):
    t = (1 + 5 ** 0.5) / 2
    V = np.array([[-1, t, 0], [1, t, 0], [-1, -t, 0], [1, -t, 0], [0, -1, t], [0, 1, t], [0, -1, -t], [0, 1, -t],
                  [t, 0, -1], [t, 0, 1], [-t, 0, -1], [-t, 0, 1]], float)
    Fc = [[0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11], [1, 5, 9], [5, 11, 4], [11, 10, 2], [10, 7, 6],
          [7, 1, 8], [3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9], [4, 9, 5], [2, 4, 11], [6, 2, 10],
          [8, 6, 7], [9, 8, 1]]
    V = list(V / np.linalg.norm(V, axis=1)[:, None])
    for _ in range(level):
        cache = {}; nf = []
        def mid(a, b):
            k = (min(a, b), max(a, b))
            if k not in cache:
                m = V[a] + V[b]; V.append(m / np.linalg.norm(m)); cache[k] = len(V) - 1
            return cache[k]
        for a, b, c in Fc:
            ab, bc, ca = mid(a, b), mid(b, c), mid(c, a)
            nf += [[a, ab, ca], [b, bc, ab], [c, ca, bc], [ab, bc, ca]]
        Fc = nf
    return np.array(V)


N = icosphere(5)


def sh_basis(L):
    th = np.arccos(np.clip(N[:, 1], -1, 1)); ph = np.arctan2(N[:, 0], N[:, 2])      # pole along +y
    Y = []
    for l in range(2, L + 1):
        for m in range(-l, l + 1):
            y = sph_harm_y(l, abs(m), th, ph)
            Y.append(np.sqrt(2) * (y.imag if m < 0 else y.real) if m else y.real)
    Y = np.array(Y).T
    return Y / np.abs(Y).max(0)


def degree(c):
    return next(L for L in range(2, 20) if (L + 1) ** 2 - 4 == len(c))


def outward(X, F):
    n = np.cross(X[F[:, 1]] - X[F[:, 0]], X[F[:, 2]] - X[F[:, 0]])
    flip = np.einsum('ij,ij->i', n, X[F[:, 0]] - X.mean(0)) < 0
    F = F.copy(); F[flip] = F[flip][:, [0, 2, 1]]
    return F


def mass(X, F):
    """volume, centre of mass, inertia tensor per unit density"""
    a, b, c = X[F[:, 0]], X[F[:, 1]], X[F[:, 2]]
    v6 = np.einsum('ij,ij->i', a, np.cross(b, c)); vol = v6.sum() / 6
    com = ((a + b + c) * v6[:, None]).sum(0) / 24 / vol
    S = np.zeros((3, 3))                                        # second moments  int x x^T dV
    for P, Q, R, w in zip(a, b, c, v6):
        s = P + Q + R
        S += w / 120 * (np.outer(P, P) + np.outer(Q, Q) + np.outer(R, R) + np.outer(s, s))
    S -= vol * np.outer(com, com)
    return vol, com, np.trace(S) * np.eye(3) - S


def body(c):
    """vertices and outward faces of the body: centre of mass at the origin, principal axes (x the
    least moment of inertia), longest extent 90"""
    h = 1.0 + sh_basis(degree(c)) @ c
    d = ConvexHull(N / h[:, None])                              # dual: body vertices = dual facets
    X = d.equations[:, :3] / -d.equations[:, 3:4]
    F = outward(X, ConvexHull(X).simplices)
    vol, com, I = mass(X, F); w, R = np.linalg.eigh(I); R[:, 2] *= np.linalg.det(R)
    X = (X - com) @ R
    return X * 90.0 / np.ptp(X, 0).max(), F


def stable(X, F):
    """resting points: persistence of minima of the face-plane height over the face graph (as in
    ../variety-reconstruction/basins.py). Returns [(depth, outward normal)], deepest (the rest) first."""
    n = np.cross(X[F[:, 1]] - X[F[:, 0]], X[F[:, 2]] - X[F[:, 0]]); n /= np.linalg.norm(n, axis=1)[:, None]
    h = np.einsum('ij,ij->i', n, X[F[:, 0]])
    ed = {}
    for f, s in enumerate(F):
        for a, b in ((s[0], s[1]), (s[1], s[2]), (s[2], s[0])):
            ed.setdefault((min(a, b), max(a, b)), []).append(f)
    E = []
    for (a, b), fs in ed.items():
        A, B = X[a], X[b]; ab = B - A; t = -(A @ ab) / (ab @ ab); u = A + t * ab; u /= np.linalg.norm(u)
        n1, n2 = n[fs[0]], n[fs[1]]; ang = lambda p, q: np.arccos(np.clip(p @ q, -1, 1))
        w = max(h[fs[0]], h[fs[1]])
        if ang(n1, u) + ang(u, n2) <= ang(n1, n2) + 1e-9:       # rolling over the edge passes its top
            w = max(w, np.linalg.norm(A + np.clip(t, 0, 1) * ab))
        E.append((w, fs[0], fs[1]))
    return _persist(h, E, n)


def unstable(X, F):
    """balancing points: persistence of maxima of the distance from the centre of mass over the vertex
    graph; an edge joins its ends at the least distance along it. Returns [(depth, point)], highest first."""
    r = np.linalg.norm(X, axis=1)
    e = np.unique(np.sort(np.concatenate([F[:, [0, 1]], F[:, [1, 2]], F[:, [2, 0]]]), 1), axis=0)
    A, B = X[e[:, 0]], X[e[:, 1]]; ab = B - A
    t = np.clip(-np.einsum('ij,ij->i', A, ab) / np.einsum('ij,ij->i', ab, ab), 0, 1)
    w = np.linalg.norm(A + t[:, None] * ab, axis=1)
    return _persist(-r, [(-wi, a, b) for wi, (a, b) in zip(w, e)], X)


def _persist(v, E, where):
    E = sorted(E); parent = list(range(len(v))); best = list(range(len(v))); out = []
    def find(i):
        while parent[i] != i: parent[i] = parent[parent[i]]; i = parent[i]
        return i
    for w, a, b in E:
        ra, rb = find(a), find(b)
        if ra == rb: continue
        if v[best[ra]] > v[best[rb]]: ra, rb = rb, ra             # ra keeps the lower minimum
        out.append((w - v[best[rb]], where[best[rb]])); parent[rb] = ra
    root = find(0); out.append((np.inf, where[best[root]]))
    return sorted(out, key=lambda o: -o[0])


def margin(X, down):
    """softest rocking margin at the rest: least over directions (every 5 deg) of h'' from +-15 deg quadratic fits"""
    e1 = np.cross(down, [1.0, 0, 0] if abs(down[0]) < 0.9 else [0, 0, 1.0]); e1 /= np.linalg.norm(e1)
    e2 = np.cross(down, e1); tq = np.radians(np.arange(-15, 15.01, 0.5)); m = []
    for p in np.radians(np.arange(0, 180, 5)):
        t = np.cos(p) * e1 + np.sin(p) * e2
        U = np.cos(tq)[:, None] * down + np.sin(tq)[:, None] * t
        m.append(np.polyfit(tq, (U @ X.T).max(1), 2)[0] * 2)
    return min(m)


def lua(name, X, F, S, U, out):
    """9 cm, in cm, as ../gomboc-meshes/*.lua"""
    vol, com, I = mass(X, F); w = np.diag(I) / vol
    Xp = X / 10; s = 1 / 10
    H = ConvexHull(Xp); pts = Xp[H.vertices]
    down = S[0][1]; top = U[0][1] * s
    unst = [p * s for d, p in U if d > 0.005]
    rest = float((Xp @ down).max())
    with open(os.path.join(out, name + '.lua'), 'w') as f:
        f.write(f"-- {name}: a monostable convex body from ../monostable-search (genome genomes/{name}.npy,\n")
        f.write("-- built by build.py). Uniform density, longest extent 9.0 cm, in cm, centre of mass at the\n")
        f.write(f"-- origin, principal axes. One resting point; {len(unst)} balancing points (deeper than 5 um at 9 cm).\n")
        f.write("return {\n")
        f.write(f"  size = 9.0, volume = {vol / 1000:.4f},\n")
        f.write("  inertia = { %.6f, %.6f, %.6f },   -- squared radii of gyration, cm^2\n" % tuple(w / 100))
        f.write("  down = { %.6f, %.6f, %.6f },      -- outward normal at the resting point\n" % tuple(down))
        f.write("  top = { %.6f, %.6f, %.6f },       -- the highest balancing (unstable) point\n" % tuple(top))
        f.write("  unstable = { %s },\n" % ', '.join('{ %.5f, %.5f, %.5f }' % tuple(p) for p in unst))
        f.write(f"  restHeight = {rest:.5f}, topHeight = {np.linalg.norm(top):.5f},\n")
        f.write("  points = {\n" + ''.join('    %.5f,%.5f,%.5f,\n' % tuple(p) for p in pts) + "  },\n}\n")
    with open(os.path.join(out, name + '.obj'), 'w') as f:
        f.write(f"# {name}: 9 cm, in cm, centre of mass at the origin, principal axes (as {name}.lua)\n")
        f.write(''.join('v %.5f %.5f %.5f\n' % tuple(p) for p in Xp) + ''.join('f %d %d %d\n' % tuple(t + 1) for t in F))


if __name__ == '__main__':
    args = sys.argv[1:]; out = None
    if args[0] == '--write': out = args[1]; args = args[2:]; os.makedirs(out, exist_ok=True)
    for path in args:
        name = os.path.basename(path)[:-4]; c = np.load(path)
        X, F = body(c); S = stable(X, F); U = unstable(X, F)
        cnt = lambda L, tol: sum(1 for d, _ in L if d > tol)
        down = S[0][1]
        print(f"{name}: L={degree(c)}  stable/unstable (deeper than 2, 5, 20, 100 um at 90 mm): "
              + ', '.join(f"{cnt(S, t / 1000)}/{cnt(U, t / 1000)}" for t in (2, 5, 20, 100))
              + f"  extents {np.round(np.ptp(X, 0), 1)}  rest {(X @ down).max():.2f} mm"
              + f"  margin {margin(X, down):.1f} mm", flush=True)
        if out: lua(name, X, F, S, U, out)
