"""Fit a tetrahedron to Bille's published numbers.

Known (arXiv:2506.19244 and Quanta): longest edge 500 mm, volume 668.624 cm^3,
loading-zone volumes (Table 1):
    B->A->D<-C  (A->D, B->A, C->D, D stable)  1.4318 cm^3
    C->D->A<-B  (A stable, B->A, C->D, D->A)  0.5716
    B->A->D->C  (A->D, B->A, C stable, D->C)  0.0199
    C->D->A->B  (A->B, B stable, C->D, D->A)  0.0067
Shape: A=(0,0,0), D=(1,0,0), B=(bx,0,bz), C=(cx,cy,cz), then scaled so the
longest edge is 500 mm. 5 unknowns, 5 targets.
"""
import sys, itertools
import numpy as np
from scipy.optimize import least_squares
from tetra import successors, volume, sample_in_tetra
from zones import zone

TARGET_VOL = 668.624e3            # mm^3
ZONES = {(3, 0, 3, -1): 1.4318e3,
         (-1, 0, 3, 0): 0.5716e3,
         (3, 0, -1, 2): 0.0199e3,
         (1, -1, 3, 0): 0.0067e3}
KEYS = list(ZONES)

def build(p):
    bx, bz, cx, cy, cz = p
    V = np.array([(0, 0, 0), (bx, 0, bz), (cx, cy, cz), (1, 0, 0)], float)
    L = max(np.linalg.norm(V[i] - V[j]) for i, j in itertools.combinations(range(4), 2))
    return V * 500 / L

_seeds = {}
def zone_volumes(V, rng=None):
    out = {}
    for k in KEYS:
        z = None
        s = _seeds.get(k)
        if s is not None and tuple(successors(V, s[None])[0]) == k:
            z = zone(V, s)
        if z is None:
            rng = rng or np.random.default_rng(0)
            O = sample_in_tetra(V, 3_000_000, rng)
            S = successors(V, O)
            m = np.all(S == np.array(k), 1)
            if m.sum() == 0:
                out[k] = None
                continue
            z = zone(V, O[m].mean(0))
        if z is None:
            out[k] = None
            continue
        _seeds[k] = z["vertices"].mean(0)
        out[k] = z["volume"]
    return out

def residuals(p):
    V = build(p)
    vol = volume(V)
    if vol <= 0:
        return np.full(5, 10.0)
    zv = zone_volumes(V)
    r = [np.log(vol / TARGET_VOL)]
    for k in KEYS:
        r.append(np.log(zv[k] / ZONES[k]) if zv[k] else 5.0)
    return np.array(r)

if __name__ == "__main__":
    rng = np.random.default_rng(int(sys.argv[1]) if len(sys.argv) > 1 else 0)
    # relabelled published example: A(-20,0,0) B(1,1,10) C(-1,-1,10) D(20,0,0) -> A at 0, D at 1
    base = np.array([0.525, 0.25124689, 0.475, -0.04975186, 0.2462717])
    base_rot = None
    best = []
    for trial in range(int(sys.argv[2]) if len(sys.argv) > 2 else 12):
        _seeds.clear()
        p0 = base * (1 + 0.6 * rng.standard_normal(5)) if trial else base.copy()
        # put B in the xz plane: rotate example about AD so that B has y = 0
        try:
            r = least_squares(residuals, p0, diff_step=1e-4, xtol=1e-12, ftol=1e-12, max_nfev=400)
        except Exception as e:
            print("trial", trial, "error", e); continue
        cost = np.abs(r.fun).max()
        print(f"trial {trial}: max |log error| {cost:.2e}  params {np.round(r.x, 5)}", flush=True)
        best.append((cost, r.x))
    best.sort(key=lambda b: b[0])
    np.save("fits.npy", np.array([np.r_[c, x] for c, x in best]))
