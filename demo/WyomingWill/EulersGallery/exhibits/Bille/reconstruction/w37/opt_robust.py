"""Second-stage refit for robustness to face-plane errors (the dominant failure
mode found by robust.py): maximise the 10th percentile, over a FIXED set of random
plane perturbations (common random numbers), of the second-smallest face margin
(the smallest margin among the faces that are not the one rest face), keeping the
nominal margin >= MFLOOR mm and the pocket constraints of opt.py.
usage: python3 opt_robust.py WEIGHT design.npy s_mm nsamp MFLOOR out.npy [maxfev]
Only the outer hull is perturbed here (COM from the exact nominal mass model);
the full check (inner walls perturbed too, exact mass each trial) is robust.py."""
import numpy as np, sys, time, json, warnings
from scipy.optimize import minimize
from w37 import *
from materials import CAT
from core import faces_of, face_margin, halfspace_poly
warnings.filterwarnings('ignore')
W = CAT[sys.argv[1]]; x0 = np.load(sys.argv[2]); s = float(sys.argv[3]); NS = int(sys.argv[4])
MFLOOR = float(sys.argv[5]); OUT = sys.argv[6]; MAXFEV = int(sys.argv[7]) if len(sys.argv) > 7 else 2500
H = x0[-1]; Dmax = 210.0; gapmin = 0.8
rng = np.random.default_rng(12345)
# per sample, per face (37): offset N(0,1), tilt angle N(0,1) (scaled by s/rad), tilt axis angle U(0, 2pi)
OFF = rng.standard_normal((NS, 37)); TIL = rng.standard_normal((NS, 37)); AX = rng.uniform(0, 2 * np.pi, (NS, 37))

from scipy.spatial import HalfspaceIntersection
def face_margins_hs(A, b, c, interior):
    """signed COM-foot margins of every face of {A x + b <= 0} (+ outside, - inside),
    straight from the halfspace intersection's dual facets (fast)"""
    hs = HalfspaceIntersection(np.c_[A, b], interior)
    P = hs.intersections; DF = hs.dual_facets
    onface = [[] for _ in range(len(A))]
    for vi, fs in enumerate(DF):
        for f in fs: onface[f].append(vi)
    out = []
    for i, idx in enumerate(onface):
        if len(idx) < 3: continue
        n = A[i]; Q = P[idx]
        u = np.cross(n, [1, 0, 0]);
        if np.linalg.norm(u) < 1e-6: u = np.cross(n, [0, 1, 0])
        u /= np.linalg.norm(u); w = np.cross(n, u)
        q = np.c_[Q @ u, Q @ w]; cq = q.mean(0)
        q = q[np.argsort(np.arctan2(q[:, 1] - cq[1], q[:, 0] - cq[0]))]
        foot = c - (n @ c + b[i]) * n; f2 = np.array([foot @ u, foot @ w])
        e = np.roll(q, -1, 0) - q; L = np.linalg.norm(e, axis=1); keep = L > 1e-9
        qq, e, L = q[keep], e[keep], L[keep]
        cr = e[:, 0] * (f2[1] - qq[:, 1]) - e[:, 1] * (f2[0] - qq[:, 0])
        t = np.clip(((f2 - qq) * e).sum(1) / (L * L), 0, 1)
        d = np.linalg.norm(qq + t[:, None] * e - f2, axis=1).min()
        out.append(-d if np.all(cr >= 0) else d)
    return np.array(out)

def perturbed_q(V, faces, c):
    A = np.array([f[0] for f in faces]); b = np.array([f[1] for f in faces])
    cen = np.array([V[f[2]].mean(0) for f in faces])
    rad = np.array([np.max(np.linalg.norm(V[f[2]] - V[f[2]].mean(0), axis=1)) for f in faces])
    # face frames
    U = []; Wv = []
    for n in A:
        u = np.cross(n, [1, 0, 0]);
        if np.linalg.norm(u) < 1e-6: u = np.cross(n, [0, 1, 0])
        u /= np.linalg.norm(u); U.append(u); Wv.append(np.cross(n, u))
    U = np.array(U); Wv = np.array(Wv)
    vals = []
    for k in range(NS):
        ax = np.cos(AX[k])[:, None] * U + np.sin(AX[k])[:, None] * Wv
        ang = TIL[k] * s / np.maximum(rad, 1e-3)
        n2 = A * np.cos(ang)[:, None] + np.cross(ax, A) * np.sin(ang)[:, None]
        p = cen - A * ((A * cen).sum(1) + b)[:, None] + A * (OFF[k] * s)[:, None]
        b2 = -(n2 * p).sum(1)
        try:
            ms = np.sort(face_margins_hs(n2, b2, c, np.array([0, 0, H / 4])))
        except Exception:
            vals.append(-50.0); continue
        # exactly one face must have the foot inside: second-smallest margin is the robustness
        vals.append(ms[1] if ms[0] < 0 else -50.0)
    return np.percentile(vals, 10), np.mean(np.array(vals) > 0)

def score(y, info=False):
    x = np.r_[y, H]
    R = y[:6]; Z = np.r_[0, y[6:11]]
    if np.any(R < 2) or np.any(np.diff(Z) < 0.05): return 1e3
    r = fast_margin(x, W)
    if r is None: return 1e3
    m = min(r['face'], r['vert'])
    pen = 10 * max(0, gapmin - r['gap']) + 10 * max(0, 2 * R.max() - Dmax) + 10 * max(0, MFLOOR - m)
    q, frac = perturbed_q(r['V'], r['faces'], r['com'])
    if info: return dict(q=q, frac=frac, margin=m, face=r['face'], vert=r['vert'], gap=r['gap'], M=r['M'], m_pla=r['m_pla'])
    return -q + pen

t0 = time.time()
i0 = score(x0[:11], info=True); print("start", json.dumps({k: round(float(v), 3) for k, v in i0.items()}), flush=True)
best = None; y = x0[:11].copy()
for rep in range(3):
    r = minimize(score, y if best is None else best.x, method='Nelder-Mead',
                 options=dict(maxfev=MAXFEV, xatol=1e-5, fatol=1e-6, adaptive=True,
                              initial_simplex=None if rep == 0 else None))
    if best is None or r.fun < best.fun: best = r
    np.save(OUT, np.r_[best.x, H])
    ii = score(best.x, info=True)
    print(f"rep {rep}: {json.dumps({k: round(float(v), 3) for k, v in ii.items()})} ({time.time()-t0:.0f} s)", flush=True)
print("x =", json.dumps(np.r_[best.x, H].round(4).tolist()))
