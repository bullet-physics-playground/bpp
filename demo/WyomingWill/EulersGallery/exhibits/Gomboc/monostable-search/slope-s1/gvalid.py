"""Validate a gsearch genome against F2: printed hulls (al/sy/sz) through prescreen (stall) and both slope measures;
writes shapes/<tag>.npz (design mesh, for PyBullet) and <tag>.obj (F2 frame, cm like gomboc_F2.obj).
  GS_L=8 python3 gvalid.py TAG genome.npy"""
import sys, os, numpy as np
sys.path[:0] = ['/home/claude/mono/monostable-search', '/home/claude/cal']
import gsearch, slope, smooth, build, prescreen as ps, printhull as ph
from scipy.spatial import ConvexHull, cKDTree
U = smooth.icosphere(6)[0]


def measures(Y36):
    """Y36: printed hull, mm at 36. support-point and face weak shares (mu 0.05 + h tan 1.5), worst over nothing"""
    X = Y36 / 0.4; P = ps.prep(X); d = P['down']; far = U @ d < np.cos(np.radians(25)); thr = lambda h: 0.05 + h * np.tan(np.radians(1.5))
    V = Y36[ConvexHull(Y36).vertices]; s = np.concatenate([np.argmax(U[i:i + 1000] @ V.T, 1) for i in range(0, len(U), 1000)])
    x = V[s]; hs = (x * U).sum(1); lev = np.linalg.norm(x - hs[:, None] * U, axis=1); sp = (far & (lev < thr(hs))).mean()
    st = cKDTree(P['n']).query(U)[1]; fc = (far & (0.4 * P['lam'][st] < thr(0.4 * P['h'][st]))).mean()
    return sp, fc, ps.stall(P, (0.05, 0.15, 0.3)), len(ps.extra_rests(P))


if __name__ == '__main__':
    tag = sys.argv[1]; c = np.load(sys.argv[2]); c = np.r_[c, np.zeros(gsearch.B.shape[1] - len(c))]
    for nm, cc in (('F2', np.zeros_like(c)), (tag, c)):
        X = gsearch.body(cc); F = build.outward(X, ConvexHull(X).simplices); P = ps.prep(X)
        np.savez(f'shapes/{nm}d.npz', X=X, F=F, down=P['down'])
        if nm == tag:
            Vcm = X / 90.0 * np.ptp(slope.load_obj('/home/claude/f2zip/gomboc_F2.obj'), 0).max()   # same size as F2's file
            open(f'{tag}.obj', 'w').write(f'# slope-tolerant F2 variant ({tag}), same units and frame as gomboc_F2.obj, centre of mass at origin, upright = +y\n'
                                          + ''.join('v %.6f %.6f %.6f\n' % tuple(q) for q in Vcm) + ''.join('f %d %d %d\n' % tuple(t + 1) for t in F))
        hv = ph.layered(ph.to_frame(X)); print(f'{nm}: design counts (2um) {slope.counts(X, P)} (20um) {slope.counts(X, P, 0.02)}', flush=True)
        for case in ('al', 'sy', 'sz'):
            Y = ph.printed(ph.to_frame(X), case, halves=hv)
            sp, fc, st, er = measures(Y)
            print(f'   printed {case}: support-point weak {100*sp:4.1f}%  face weak {100*fc:4.1f}%  predicted stall at 0.05/0.15/0.3 mm {np.round(100*st,1)}  extra rests {er}', flush=True)
