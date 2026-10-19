"""Refit the ring radii/heights of the (6,6) spiral for a real PLA print with
stock weights in corner pockets (the analogue of the gallery's optshell.py, with
the exact mass model of w37.py).
usage: python3 opt.py WEIGHT H_mm [t_mm] [seeds] [Dmax] [gapmin] [zs]
maximises min(face margin, vertex margin) (mm, distances of the COM from making
any other face / corner an equilibrium), subject to: pocket gaps >= gapmin,
vertex circle <= Dmax, rings ordered; height fixed."""
import numpy as np, sys, warnings, time, json
from scipy.optimize import minimize
from w37 import *
from materials import CAT
from from_gallery import gallery_x
warnings.filterwarnings('ignore')
wname = sys.argv[1]; H = float(sys.argv[2]); t = float(sys.argv[3]) if len(sys.argv) > 3 else 0.8
seeds = int(sys.argv[4]) if len(sys.argv) > 4 else 4; Dmax = float(sys.argv[5]) if len(sys.argv) > 5 else 210.0
gapmin = float(sys.argv[6]) if len(sys.argv) > 6 else 0.8
ZS = float(sys.argv[7]) if len(sys.argv) > 7 and sys.argv[7] != 'none' else None
X0F = sys.argv[8] if len(sys.argv) > 8 else None
W = CAT[wname]
import os
OVH = float(os.getenv("OVH", "0"))      # >0: max overhang (deg from vertical) of downward faces reaching above OVH_Z mm
OVH_Z = float(os.getenv("OVH_Z", "1.0"))
def full(y):
    return np.r_[y, H]
def score(y, info=False):
    R = y[:6]; Z = np.r_[0, y[6:11]]
    if np.any(R < 2) or np.any(np.diff(Z) < 0.05) or Z[-1] > H - 5: return 1e3
    pen = 10 * max(0, 2 * R.max() - Dmax)
    r = fast_margin(full(y), W, t=t, zs=ZS)
    if r is None: return 1e3
    pen += 10 * max(0, gapmin - r['gap'])
    if OVH:
        lim = -np.sin(np.radians(OVH))
        for (nn, dd, idx) in r['faces']:
            if nn[2] < -0.9999999: continue        # the base
            if nn[2] < lim and r['V'][idx, 2].max() > OVH_Z: pen += 50 * (lim - nn[2])
    m = min(r['face'], r['vert'])
    if info: return r
    return -m + pen
x0 = gallery_x(H)[:11]
if X0F:
    xx = np.load(X0F); x0 = xx[:11] * H / xx[11]
rng = np.random.default_rng(1); best = None; t0 = time.time()
out = f"runs/opt_{wname.replace('/','_')}_H{H:.0f}_t{t:.1f}" + ("" if ZS is None else f"_zs{ZS:.1f}") + ("" if not OVH else f"_ovh{OVH:.0f}")
for s in range(seeds):
    y = x0.copy() if s == 0 else (best.x if s % 2 else x0) * (1 + 0.05 * rng.standard_normal(11))
    r = None
    for rep in range(3):
        r = minimize(score, y if r is None else r.x, method='Nelder-Mead',
                     options=dict(maxiter=3000, maxfev=3000, xatol=1e-6, fatol=1e-7, adaptive=True))
    if best is None or r.fun < best.fun:
        best = r; np.save(out + ".npy", full(r.x))
    print(f"seed {s}: score {r.fun:.3f}  best {best.fun:.3f}  ({time.time()-t0:.0f} s)", flush=True)
I = score(best.x, info=True)
print(f"RESULT {wname} H={H:.0f} t={t}: margin {-best.fun:.3f} mm (face {I['face']:.3f} vert {I['vert']:.3f}, base {I['base']:.2f}) "
      f"gap {I['gap']:.2f} mass {I['M']:.1f} g (PLA {I['m_pla']:.1f}, weights {W.m*37:.1f}) zc {I['com'][2]:.2f} D {2*best.x[:6].max():.1f}", flush=True)
print("x =", json.dumps(full(best.x).round(4).tolist()))
