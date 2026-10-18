"""(6-fold) ring stack whose apex is cut by a 3-plane cap through it, so the
apex is a vertex of exactly 3 faces (stays ONE vertex under small face errors).
usage: python3 opt4.py SPEC capphase_deg t_mm Hmax Dmax seeds out.npy x0.npy
x = [R_0..R_{n-1}, Z_1..Z_{n-1}, H, zs, beta]  (beta = cap faces' tilt from horizontal, rad)"""
import numpy as np, sys, warnings, os
from scipy.optimize import minimize
from core import *
from opt3 import parse, verts, OVH
warnings.filterwarnings('ignore')
EPS = float(os.getenv("CAP_EPS", "0.05"))   # strictness of the degree-3 apex (see below)

def build(x, rings, psi):
    n = len(rings); R = x[:n]; Z = np.r_[0.0, x[n:2 * n - 1]]; H = x[2 * n - 1]; zs = x[2 * n]; beta = x[2 * n + 1]
    V = verts(rings, R, Z, H); A = V[0]
    f0, _ = faces_of(V)
    caps = []
    for j in range(3):
        a = psi + 2 * np.pi * j / 3
        nn = np.array([np.sin(np.pi / 2 - beta) * 0 + np.cos(np.pi / 2 - beta) * 0 + np.sin(beta) * np.cos(a) * 0 + np.cos(beta) * 0, 0, 0])
        nn = np.array([np.sin(beta) * np.cos(a), np.sin(beta) * np.sin(a), np.cos(beta)])
        caps.append((nn, -nn @ A))
    Aall = np.array([f[0] for f in f0] + [c[0] for c in caps]); ball = np.array([f[1] for f in f0] + [c[1] for c in caps])
    Vo = halfspace_poly(Aall, ball)
    Vo = np.unique(np.round(Vo, 9), axis=0)
    # degree-3 test: the cap cone's 3 edges must point strictly into every other face's halfspace at A
    worst = -1
    for j in range(3):
        e = np.cross(caps[j][0], caps[(j + 1) % 3][0])
        if e[2] > 0: e = -e
        e /= np.linalg.norm(e)
        for (m, d, idx) in f0:
            if abs(m @ A + d) < 1e-9: worst = max(worst, m @ e)
    return Vo, A, R, Z, H, zs, beta, worst

def evaluate(x, rings, psi, t, Hmax, Dmax, full=False):
    n = len(rings)
    try:
        Vo, A, R, Z, H, zs, beta, worst = build(x, rings, psi)
        faces, _ = faces_of(Vo)
    except Exception:
        return 1e3, None
    if np.any(R < 0.2) or np.any(np.diff(Z) < 0.01): return 1e3, None
    pen = 100 * max(0, H - Hmax) + 100 * max(0, 2 * R.max() - Dmax) + 100 * max(0, 0.15 - zs)
    pen += 50 * max(0, worst + EPS)
    base = [i for i, f in enumerate(faces) if f[0][2] < -0.999999]
    if len(base) != 1: return 1e3, None
    base = base[0]
    for i, (nn, d, idx) in enumerate(faces):
        if i == base: continue
        if nn[2] > OVH: pen += 50 * (nn[2] - OVH)
        if nn[2] < -OVH: pen += 50 * (-OVH - nn[2])
    ai = int(np.argmin(np.linalg.norm(Vo - A, axis=1)))
    try:
        mp = mass_props(Vo, faces, t, zs)
    except Exception:
        return 1e3, None
    if mp['void'] is None: return 1e3, None
    c = mp['com']
    if not (0 < c[2] < H): return 1e3, None
    sm = summary_margin(Vo, faces, c, base, ai)
    m = min(sm['face'], sm['vert']) * 10
    if not sm['apex_is_eq']: m = min(m, -1.0)
    sc = -m + pen
    if full: return sc, dict(V=Vo, faces=faces, base=base, apex=ai, mp=mp, sm=sm, worst=worst)
    return sc, None

if __name__ == "__main__":
    rings = parse(sys.argv[1]); psi = np.radians(float(sys.argv[2])); t = float(sys.argv[3]) / 10
    Hmax, Dmax, seeds = float(sys.argv[4]), float(sys.argv[5]), int(sys.argv[6])
    x0 = np.load(sys.argv[8]); rng = np.random.default_rng(3)
    f = lambda x: evaluate(x, rings, psi, t, Hmax, Dmax)[0]
    best = None
    for s in range(seeds):
        xs = x0.copy() if s == 0 else x0 * (1 + 0.03 * rng.standard_normal(len(x0)))
        r = None
        for rep in range(3):
            r = minimize(f, xs if r is None else r.x, method='Nelder-Mead',
                         options=dict(maxiter=2500 * len(rings), maxfev=2500 * len(rings), xatol=1e-8, fatol=1e-10, adaptive=True))
        if best is None or r.fun < best.fun:
            best = r; np.save(sys.argv[7], r.x); print(f"  seed {s}: score {-r.fun:.3f}", flush=True)
    sc, I = evaluate(best.x, rings, psi, t, Hmax, Dmax, full=True)
    st, un = equilibria(I['V'], I['faces'], I['mp']['com'])
    deg = sum(1 for ff in I['faces'] if I['apex'] in ff[2])
    print(f"RESULT cap phase {sys.argv[2]}: margin {-sc:.3f} mm (face {I['sm']['face']*10:.3f} vert {I['sm']['vert']*10:.3f}) stable {len(st)} "
          f"unstable {len(un)} apex degree {deg} faces {len(I['faces'])} mass {I['mp']['M']:.0f} g zc {I['mp']['com'][2]:.3f} beta {np.degrees(best.x[-1]):.1f} worst {I['worst']:.3f}", flush=True)
