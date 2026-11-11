"""Strengthen the weakest restoring lever of a (1,1) smooth body by trust-region steps.
lever field L(n) = |g(n)| / sin(angle to the nearer of rest and top), mm per radian at 90 mm, g the tangential
part of x(n) - G. Q = min L. Each step: the local minima of L ("weak spots") within 3x of Q (at most 80), their gradients
(x is linear in c; dG/dc by finite differences), then the step dc (|dc_j| <= r) maximising the least
linearised weak-spot value (a linear programme). Kept only if the exact count is still (1,1), the least
radius of curvature >= 0.2 mm, and Q rose; otherwise r is halved.
  python3 improve.py in.npy out.npy STEPS"""
import sys, time
import numpy as np
from scipy.optimize import linprog
import smooth, smooth_check as v

c = np.load(sys.argv[1]); OUT = sys.argv[2]; STEPS = int(sys.argv[3])
L = next(L for L in range(2, 20) if (L + 1) ** 2 - 4 == len(c)); NP = len(c)
S = smooth.Sphere(L, level=6)


def field(c, rest, top):
    B = S.body(c); N, G, s = S.N, B['G'], B['s']
    d = B['x'] - G; gt = d - (d * N).sum(1)[:, None] * N; gn = np.linalg.norm(gt, axis=1)
    sn = np.sqrt(np.maximum(1 - np.maximum(N @ rest, N @ top) ** 2, 1e-12))
    return B, gt, gn, sn, gn / sn * s


def exact(c):
    out, r = v.run(c); k = r['kind']
    ok = (k == 'rest').sum() == 1 and (k == 'balance').sum() == 1 and (k == 'saddle').sum() == 0
    return ok, r, out


ok, r, out = exact(c); assert ok, out
rest, top = r['crit'][r['kind'] == 'rest'][0], r['crit'][r['kind'] == 'balance'][0]
B, gt, gn, sn, Lf = field(c, rest, top); Q = Lf.min()
print(f'start Q {Q:.4f} mm/rad  ({out.split(";")[0]})', flush=True)
rad = 0.002; t0 = time.time()
for step in range(STEPS):
    N, E = S.N, S.E
    far = np.minimum(np.degrees(np.arccos(np.clip(N @ rest, -1, 1))), np.degrees(np.arccos(np.clip(N @ top, -1, 1)))) > 8
    nb = np.full(len(N), np.inf); np.minimum.at(nb, E[:, 0], Lf[E[:, 1]]); np.minimum.at(nb, E[:, 1], Lf[E[:, 0]])
    spots = np.where((Lf <= nb) & far & (Lf < 3 * Q + 0.05))[0]
    spots = spots[np.argsort(Lf[spots])][:80]
    # dG/dc by finite differences
    eps = 1e-6; G0 = B['G']
    JG = np.array([(S.body(c + eps * e)['G'] - G0) / eps for e in np.eye(NP)]).T        # 3 x NP
    s = B['s']; grads = []
    for i in spots:
        n = N[i]; P = np.eye(3) - np.outer(n, n); u = gt[i] / gn[i]
        dg = P @ (S.g[i].T - JG)                                                        # 3 x NP
        grads.append(u @ dg * s / sn[i])
    grads = np.array(grads); vals = Lf[spots]
    # maximise t: vals + grads dc >= t, |dc_j| <= rad  (variables dc, t)
    res = linprog(np.r_[np.zeros(NP), -1.0], A_ub=np.c_[-grads, np.ones(len(spots))], b_ub=vals,
                  bounds=[(-rad, rad)] * NP + [(None, None)], method='highs')
    dc = res.x[:NP]; pred = res.x[NP]
    c2 = c + dc; ok, r2, out2 = exact(c2)
    B2 = S.body(c2); good = ok and B2['rad'].min() * B2['s'] >= 0.2
    if good:
        rest2, top2 = r2['crit'][r2['kind'] == 'rest'][0], r2['crit'][r2['kind'] == 'balance'][0]
        B2, gt2, gn2, sn2, Lf2 = field(c2, rest2, top2); good = Lf2.min() > Q
    if good:
        c, rest, top, B, gt, gn, sn, Lf = c2, rest2, top2, B2, gt2, gn2, sn2, Lf2
        Q = Lf.min(); np.save(OUT, c); rad *= 1.5
        w = N[np.argmin(Lf)]
        print(f'step {step} t={time.time() - t0:.0f}s  Q {Q:.4f} (predicted {pred:.4f})  weakest at '
              f'{np.degrees(np.arccos(np.clip(w @ rest, -1, 1))):.0f} deg from rest  spots {len(spots)}  r {rad:.4f}', flush=True)
    else:
        rad /= 2
        why = 'count ' + out2.split(';')[0].split(':')[1] if not ok else 'convexity or Q fell'
        print(f'step {step} rejected ({why}), r -> {rad:.5f}', flush=True)
        if rad < 1e-7: break
print('FINAL', exact(c)[2], flush=True)
