"""Slope-tolerant gomboc scoring (printing chat's request, 17 Nov 2026). Body X: hull points, centre of mass at the
origin, mm at 90 (longest extent 90); levers reported in mm at 36 (x 0.4).
  weak(P)    share of landing directions (icosphere level 5, nearest face normal) more than 25 deg from upright whose
             face lever is below MU + h tan(1.5 deg), h the centre-of-mass height on that face (all mm at 36)
  margin(X)  least support-point lever over the ring 20 deg from upright (mm at 36): the upright margin
  counts(X)  (resting points, balancing points) deeper than 2 um at 90 mm: resting by extra_rests (edge passes),
             balancing by persistence of the distance from the centre of mass over the hull's vertex graph
  score(X)   worst weak share over aligned and the 0.1 mm vertical half-slip both ways (variety_map.slipped)"""
import sys, numpy as np
sys.path[:0] = ['/home/claude/mono/monostable-search']
from scipy.spatial import ConvexHull, cKDTree
import prescreen as ps, smooth, variety_map as vm
MU, ALPHA = 0.05, np.radians(1.5)
U5 = smooth.icosphere(5)[0]


def weak(P):
    n, d = P['n'], P['down']; st = cKDTree(n).query(U5)[1]
    far = n[st] @ d < np.cos(np.radians(25))
    return (far & (0.4 * P['lam'][st] < MU + 0.4 * P['h'][st] * np.tan(ALPHA))).mean()


def margin(X, d, ring=20.0, k=360):
    e = np.cross(d, [0, 0, 1.0]) if abs(d[2]) < 0.9 else np.cross(d, [1.0, 0, 0]); e /= np.linalg.norm(e); f = np.cross(d, e)
    t = np.linspace(0, 2 * np.pi, k, endpoint=False); a = np.radians(ring)
    U = np.cos(a) * d + np.sin(a) * (np.cos(t)[:, None] * e + np.sin(t)[:, None] * f)
    V = X[ConvexHull(X).vertices]; x = V[np.argmax(U @ V.T, 1)]; hs = (x * U).sum(1)
    return 0.4 * np.linalg.norm(x - hs[:, None] * U, axis=1).min()


def counts(X, P=None, tb=0.002):
    P = ps.prep(X) if P is None else P
    H = ConvexHull(X); dv = np.linalg.norm(X, axis=1)
    Ev = np.unique(np.sort(H.simplices[:, [0, 1, 1, 2, 2, 0]].reshape(-1, 2), 1), axis=0)
    mx = smooth._persist(-dv, Ev); top = [i for dd, i in mx if dd > tb]
    return 1 + len(ps.extra_rests(P)), max(len(top), 1)


def score(X, P=None):
    P = ps.prep(X) if P is None else P; w = [weak(P)]
    for sg in (1, -1): w.append(weak(ps.prep(vm.slipped(X, P['down'], 'vertical', sg))))
    return max(w), w


def load_obj(fn):
    V = np.array([l.split()[1:4] for l in open(fn) if l.startswith('v ')], float)
    return V


def normal_form(V):
    """recentre on the centre of mass and scale to longest extent 90, keeping the mesh's own frame"""
    import build
    H = ConvexHull(V); X = V[H.vertices]; F = build.outward(X, ConvexHull(X).simplices); vol, com, I = ps.mass(X, F)
    X = X - com; return X * 90.0 / np.ptp(X, 0).max()


if __name__ == '__main__':
    for fn in sys.argv[1:]:
        if fn.endswith('.obj'): X = normal_form(load_obj(fn))
        else: X = normal_form(np.load(fn))
        P = ps.prep(X); s, w = score(X, P)
        print(f'{fn.split("/")[-1]:24s} counts {counts(X, P)}  weak aligned {100*w[0]:.1f}%  slip+ {100*w[1]:.1f}%  slip- {100*w[2]:.1f}%'
              f'  margin@20 {margin(X, P["down"]):.2f} mm  rest h {0.4*P["h"].min():.1f} mm  verts {len(X)}', flush=True)
