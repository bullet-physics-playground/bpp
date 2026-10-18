"""How often plane errors split the apex into two unstable vertices, how far apart they are,
and how much their distances from the centre of mass differ (robust.py trials, seed 1).
usage (in this folder): python3 apexsplit.py > runs/apexsplit.log"""
import sys; sys.path.insert(0, '.')
import numpy as np, robust
from core import faces_of, equilibria
x = np.load('runs/a_6_6_t10.npy'); rings = robust.parse('6:0,6:0,6:0,6:0,6:0,6:0'); D = robust.Design(x, rings, 0.1)
orig = robust.count
for s in (0.1, 0.2, 0.3, 0.5):
    rng = np.random.default_rng(1)
    rec = []
    def grab(V, c, merge=0.1):
        faces, _ = faces_of(V, tol=1e-7); st, un = equilibria(V, faces, c)
        P = V[un]; r = np.linalg.norm(P - c, axis=1)
        spread = max((np.linalg.norm(p - q) for p in P for q in P), default=0)
        rec.append((len(un), spread * 10, (r.max() - r.min()) * 1e4, len(st)))
        return orig(V, c, merge)
    robust.count = grab
    for i in range(300): robust.trial(D, rng, s_planes=s)
    robust.count = orig
    o = np.array(rec); m = o[o[:, 0] > 1]
    print(f"planes {s} mm: one unstable vertex {100*np.mean(o[:,0]==1):.1f}%; two+ {100*np.mean(o[:,0]>1):.1f}% "
          f"(max count {o[:,0].max():.0f}); split: spread median {np.median(m[:,1]) if len(m) else 0:.2f} max {m[:,1].max() if len(m) else 0:.2f} mm; "
          f"distance-to-COM difference max {m[:,2].max() if len(m) else 0:.1f} um; one stable face {100*np.mean(o[:,3]==1):.1f}%", flush=True)
