"""General 3D co-design optimiser (core.py, exact): rings with their own k and
phase, so e.g. a 6-fold body can end in a 3-face cap (apex of degree 3, which
stays ONE vertex under any small error of the faces).
usage: python3 opt3.py SPEC t_mm Hmax Dmax supportless seeds out.npy [x0.npy]
SPEC e.g. "6:0,6:0,6:0,6:0,3:30"  (k:phase_deg per ring, bottom to top)
x = [R_0..R_{n-1}, Z_1..Z_{n-1}, H, zs]"""
import numpy as np, sys, warnings
from scipy.optimize import minimize
from core import *
warnings.filterwarnings('ignore')
OVH = np.cos(np.radians(45)) + 1e-4
import os
CAP_P = float(os.getenv("CAP_P", "0"))   # cm; set > 0 to force a 3-face cap (apex of degree 3)

def parse(spec):
    return [(int(a.split(':')[0]), np.radians(float(a.split(':')[1]))) for a in spec.split(',')]

def verts(rings, R, Z, H):
    V = [(0.0, 0.0, H)]
    for (k, ph0), r, z in zip(rings, R, Z):
        for j in range(k):
            ph = ph0 + 2 * np.pi * j / k
            V.append((r * np.cos(ph), r * np.sin(ph), z))
    return np.array(V)

def unpack(x, n):
    return x[:n], np.r_[0.0, x[n:2 * n - 1]], x[2 * n - 1], x[2 * n]

def evaluate(x, rings, t, Hmax, Dmax, sl, full=False, minfloor=0.15):
    n = len(rings); R, Z, H, zs = unpack(x, n)
    if np.any(R < 0.2) or np.any(np.diff(Z) < 0.01) or H < Z[-1] + 0.05: return 1e3, None
    pen = 100 * max(0, H - Hmax) + 100 * max(0, 2 * R.max() - Dmax) + 100 * max(0, minfloor - zs)
    V = verts(rings, R, Z, H)
    try:
        faces, hull = faces_of(V)
    except Exception:
        return 1e3, None
    if len(hull.vertices) != len(V): pen += 5 * (len(V) - len(hull.vertices))
    base = [i for i, f in enumerate(faces) if f[0][2] < -0.999999]
    if len(base) != 1: return 1e3, None
    base = base[0]
    for i, (nn, d, idx) in enumerate(faces):
        if i == base: continue
        if nn[2] > OVH: pen += 50 * (nn[2] - OVH)
        if sl and nn[2] < -OVH: pen += 50 * (-OVH - nn[2])
    if CAP_P and rings[-1][0] == 3:
        # 3-face cap: every other vertex must lie >= CAP_P inside the planes
        # (apex, t_i, t_i+1), so that the apex is a vertex of exactly 3 faces
        k3 = len(V) - 3
        T = V[k3:]; A = V[0]; others = V[1:k3]
        for i in range(3):
            nrm = np.cross(T[i] - A, T[(i + 1) % 3] - A); nrm /= np.linalg.norm(nrm)
            if nrm @ (A - np.array([0, 0, H / 2])) < 0: nrm = -nrm
            worst = np.max((others - A) @ nrm)
            pen += 50 * max(0, worst + CAP_P)
    try:
        mp = mass_props(V, faces, t, zs)
    except Exception:
        return 1e3, None
    if mp['void'] is None: return 1e3, None
    c = mp['com']
    if not (0 < c[2] < H): return 1e3, None
    sm = summary_margin(V, faces, c, base, 0)
    m = min(sm['face'], sm['vert']) * 10
    if not sm['apex_is_eq']: m = min(m, -1.0)
    sc = -m + pen
    if full: return sc, dict(V=V, faces=faces, base=base, mp=mp, sm=sm, R=R, Z=Z, H=H, zs=zs)
    return sc, None

def run(rings, t, Hmax, Dmax, sl, seeds, x0, seed=1, verbose=True, save=None):
    rng = np.random.default_rng(seed); best = None
    f = lambda x: evaluate(x, rings, t, Hmax, Dmax, sl)[0]
    for s in range(seeds):
        xs = x0.copy() if s == 0 else x0 * (1 + 0.04 * rng.standard_normal(len(x0)))
        if f(xs) > 100: continue
        r = None
        for rep in range(3):
            r = minimize(f, xs if r is None else r.x, method='Nelder-Mead',
                         options=dict(maxiter=3000 * len(rings), maxfev=3000 * len(rings), xatol=1e-8, fatol=1e-10, adaptive=True))
        if best is None or r.fun < best.fun:
            best = r
            if verbose: print(f"  seed {s}: margin {-r.fun:.3f} mm", flush=True)
            if save: np.save(save, r.x)
    return best

if __name__ == "__main__":
    rings = parse(sys.argv[1]); t = float(sys.argv[2]) / 10
    Hmax, Dmax, sl, seeds = float(sys.argv[3]), float(sys.argv[4]), int(sys.argv[5]), int(sys.argv[6])
    x0 = np.load(sys.argv[8])
    b = run(rings, t, Hmax, Dmax, sl, seeds, x0, save=sys.argv[7])
    sc, I = evaluate(b.x, rings, t, Hmax, Dmax, sl, full=True)
    st, un = equilibria(I['V'], I['faces'], I['mp']['com'])
    print(f"RESULT {sys.argv[1]} t={t*10:.1f}: margin {-sc:.3f} mm (face {I['sm']['face']*10:.3f} vert {I['sm']['vert']*10:.3f}) "
          f"stable {len(st)} unstable {len(un)} faces {len(I['faces'])} mass {I['mp']['M']:.0f} g zc {I['mp']['com'][2]:.3f} zs {I['zs']:.3f} H {I['H']:.2f}", flush=True)
    np.save(sys.argv[7], b.x)
