"""Lower a smooth (1,1) body's lever shortfall in the families chat's score (fam.py: mean over directions > 25 deg
from the rest and > 10 deg from the top of max(0, 0.45 - lever at 36 mm)), by trust-region linear-programme steps.
A step is kept only if the level-6 grid still counts 1/1 at 0.5 um, the least radius of curvature stays >= 0.2 mm (linearised in the step as >= 0.25),
no grid lever (anywhere beyond 2 deg of the rest and top) falls below min(its value, 0.1 mm; 1.2 mm within 25 deg of upright) in the linearised step, and the shortfall falls; every 5th kept step (and the last) must pass the exact count (smooth_check), else back up.
  python3 gdeficit.py in.npy out.npy MINUTES"""
import sys, time, numpy as np
from scipy.optimize import linprog
import os; G = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..') + '/'
sys.path.insert(0, G + 'monostable-search')
import smooth, smooth_check as v

c = np.load(sys.argv[1]); OUT = sys.argv[2]; TL = 60 * float(sys.argv[3]); T = 0.45; FLOOR = 0.1; BOWL = 1.2
L = next(L for L in range(2, 20) if (L + 1) ** 2 - 4 == len(c)); S = smooth.Sphere(L, level=6); N = S.N


def ev(c):
    B = S.body(c); R = B['x'] - B['G']; d = np.linalg.norm(R, axis=1); s = 90.0 / (2 * d.max())
    lev = 0.4 * s * np.linalg.norm(R - (R * N).sum(1)[:, None] * N, axis=1)
    mn, mx = S.equilibria(B['hG']); i0, i1 = mn[0][1], mx[0][1]
    m = (N @ N[i0] < np.cos(np.radians(25))) & (N @ (R[i1] / d[i1]) < np.cos(np.radians(10)))
    global TILT; TILT = np.degrees(np.arccos(np.clip(N @ N[i0], -1, 1)))
    global near; near = (N @ N[i0] < np.cos(np.radians(2))) & (N @ (R[i1] / d[i1]) < np.cos(np.radians(2)))
    cnt = lambda E: sum(1 for x, _ in E if x * B['s'] > 0.0005)
    global RAD; RAD = B['rad'].min(1) * B['s']                  # least principal radius per direction, mm at 90
    return lev, m, (cnt(mn), cnt(mx)), RAD.min()


def deficit(lev, m): return np.maximum(0, T - lev[m]).mean()


def exact(c):
    out, r = v.run(c); k = r['kind']
    return (k == 'rest').sum() == 1 and (k == 'balance').sum() == 1 and (k == 'saddle').sum() == 0


lev, m, cn, rad = ev(c); f = deficit(lev, m); good = c.copy(); r = 0.0005; kept = 0; Jc = None; t0 = time.time()
print(f'start deficit {f:.4f}  below {100 * (lev[m] < T).mean():.1f}%  min {lev[m].min():.3f}  counts {cn}  radius {rad:.2f}', flush=True)
while time.time() - t0 < TL and r > 1e-5:
    if Jc is None or not (Jc[0] == c).all():                     # Jacobian reused until a step is kept
        ev(c); bowl = near & ~m & (TILT < 25)                    # the upright bowl, which the shortfall ignores
        idx = np.where(m & (lev < T + 0.1))[0]                   # directions that are short or close to it
        idx = np.union1d(idx, np.where(near & (lev < FLOOR + 0.05))[0])   # weak levers anywhere but at rest and top
        idx = np.union1d(idx, np.where(bowl & (lev < BOWL + 0.2))[0])
        fl = np.minimum(lev[idx], np.where(bowl[idx], BOWL, FLOOR))   # no lever below min(now, floor of its region)
        r0 = RAD.copy(); ir = np.where(r0 < 3.0)[0]             # radii that could reach the 0.25 mm floor
        J = np.zeros((len(idx), len(c))); Jr = np.zeros((len(ir), len(c))); h = 1e-4
        for j in range(len(c)):
            e = np.zeros(len(c)); e[j] = h; J[:, j] = (ev(c + e)[0][idx] - lev[idx]) / h; Jr[:, j] = (RAD[ir] - r0[ir]) / h
        ev(c); Jc = (c.copy(), J, Jr, ir, r0, idx, fl)
    J, Jr, ir, r0, idx, fl = Jc[1:]
    n = len(c); k = len(idx)                                     # variables: dc (n), t (k); min mean t, t >= T - lev - J dc
    w = m[idx].astype(float); w /= max(w.sum(), 1)
    res = linprog(np.r_[np.zeros(n), w], A_ub=np.r_[np.c_[-J, -np.eye(k)], np.c_[-J, np.zeros((k, k))],
                             np.c_[-Jr, np.zeros((len(ir), k))]],
                  b_ub=np.r_[lev[idx] - T, lev[idx] - fl, r0[ir] - 0.25],
                  bounds=[(-r, r)] * n + [(0, None)] * k, method='highs')
    if res.status != 0: r /= 2; continue
    cn2 = c + res.x[:n]; lev2, m2, cn_, rad2 = ev(cn2); f2 = deficit(lev2, m2)
    if cn_ == (1, 1) and rad2 >= 0.2 and f2 < f:
        c, lev, m, f = cn2, lev2, m2, f2; kept += 1; r *= 1.5
        if kept % 5 == 0:
            if exact(c): good = c.copy(); np.save(OUT, good)
            else: c = good.copy(); lev, m, _, _ = ev(c); f = deficit(lev, m); r /= 4; print('  exact failed: back up', flush=True)
        print(f'{time.time() - t0:5.0f}s kept {kept}  deficit {f:.4f}  below {100 * (lev[m] < T).mean():.1f}%  '
              f'min {lev[m].min():.3f}  radius {rad2:.2f}  r {r:.4f}', flush=True)
    else:
        r /= 2; print(f'  reject: counts {cn_} radius {rad2:.3f} deficit {f2:.4f} (now {f:.4f})', flush=True)
if not (c == good).all():
    if exact(c): good = c
np.save(OUT, good); lev, m, cn, rad = ev(good)
print(f'FINAL deficit {deficit(lev, m):.4f}  below {100 * (lev[m] < T).mean():.1f}%  min {lev[m].min():.3f}  radius {rad:.2f}', flush=True)
