"""Exact loading zones as convex polytopes.

Every boundary between falling patterns that involves only 'tip over an edge'
decisions is a plane:
  * prism planes: contain an edge of face F and are perpendicular to F
    (foot of O crosses that edge of F)
  * Voronoi planes: through a vertex v of F, perpendicular to an edge v-x of F
    (foot of O passes from the edge region to the vertex region)
Start from the arrangement cell containing a seed point, then repeatedly drop
planes across which the pattern does not change, until every facet of the
cell separates different patterns (or is a face of the tetrahedron).
The result is checked by sampling.
"""
import numpy as np
from scipy.spatial import HalfspaceIntersection, ConvexHull
from tetra import successors, face_normals


def candidate_planes(V):
    N = face_normals(V)
    P = []                                   # (normal, offset) : n.x + d = 0
    for f in range(4):
        tri = [x for x in range(4) if x != f]
        n = N[f]
        for a in range(3):
            for b in range(a + 1, 3):
                x, y = V[tri[a]], V[tri[b]]
                m = np.cross(n, y - x); m /= np.linalg.norm(m)
                P.append((m, -m @ x, ("prism", f, tri[a], tri[b])))
                for v, w in ((x, y), (y, x)):
                    e = (w - v) / np.linalg.norm(w - v)
                    P.append((e, -e @ v, ("voronoi", f, tri[a], tri[b])))
    return P


def tetra_halfspaces(V):
    N = face_normals(V)
    H = []
    for f in range(4):
        i = [x for x in range(4) if x != f][0]
        H.append(np.r_[N[f], -N[f] @ V[i]])  # n.x - n.Vi <= 0 inside
    return np.array(H)


def pat(V, x):
    return tuple(successors(V, np.atleast_2d(x))[0])


def zone(V, seed, maxit=40, eps=1e-6):
    target = pat(V, seed)
    planes = candidate_planes(V)
    T = tetra_halfspaces(V)
    active = list(range(len(planes)))
    scale = np.max(np.abs(V))
    for it in range(maxit):
        H = [T]
        for k in active:
            n, d, _ = planes[k]
            s = np.sign(n @ seed + d)
            if s == 0:
                s = 1
            H.append(np.r_[-s * n, -s * d][None, :])   # keep the seed side: -s(n.x+d) <= 0
        H = np.vstack(H)
        try:
            hs = HalfspaceIntersection(H, seed)
        except Exception:
            return None
        pts = hs.intersections
        hull = ConvexHull(pts)
        # which halfspaces are facets: check for each active plane whether some hull vertex lies on it
        changed = False
        for k in list(active):
            n, d, _ = planes[k]
            dist = np.abs(pts @ n + d)
            on = pts[dist < 1e-7 * scale]
            if len(on) < 3:
                active.remove(k)          # not a facet: redundant
                changed = True
                continue
            c = on.mean(0)
            a = pat(V, c + eps * scale * n)
            b = pat(V, c - eps * scale * n)
            if a == b:
                active.remove(k)
                changed = True
                break                       # rebuild before testing more
        if not changed:
            return dict(volume=hull.volume, vertices=pts, pattern=target,
                        planes=[planes[k][2] for k in active], H=H)
    return None


def check(V, z, rng, n=20000):
    """fraction of random points of the polytope that have the zone's pattern"""
    pts = z["vertices"]
    lo, hi = pts.min(0), pts.max(0)
    x = lo + (hi - lo) * rng.random((n * 8, 3))
    H = z["H"]
    inside = np.all(x @ H[:, :3].T + H[:, 3] <= 0, axis=1)
    x = x[inside][:n]
    S = successors(V, x)
    tgt = np.array(z["pattern"])
    return np.mean(np.all(S == tgt, axis=1)), len(x)
