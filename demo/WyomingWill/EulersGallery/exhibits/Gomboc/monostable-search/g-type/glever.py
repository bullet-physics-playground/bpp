"""Face lever in the families chat's units (fam.face_lever: mm at 36 mm, size = twice the largest distance from the
centre of mass), over directions > 25 deg from the rest normal and > 10 deg from the top.
  python3 glever.py   (mono-g1/g2/g3 smooth genomes, f0_best_b edged genome for comparison)"""
import sys, numpy as np
import os; G = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..') + '/'
sys.path[:0] = [G + 'monostable-search', G + 'families/common']
import smooth, fam

def smooth_lever(c):
    L = next(L for L in range(2, 20) if (L + 1) ** 2 - 4 == len(c)); S = smooth.Sphere(L, level=6)
    B = S.body(c); N = S.N; R = B['x'] - B['G']; d = np.linalg.norm(R, axis=1); s = 90.0 / (2 * d.max())
    lev = np.linalg.norm(R - (R * N).sum(1)[:, None] * N, axis=1) * s
    mn, mx = S.equilibria(B['hG']); i0, i1 = mn[0][1], mx[0][1]
    tilt = np.degrees(np.arccos(np.clip(N @ N[i0], -1, 1)))
    from_top = np.degrees(np.arccos(np.clip(N @ (R[i1] / d[i1]), -1, 1)))
    return lev, tilt, from_top

def show(nm, lev, tilt, from_top):
    m = (tilt > 25) & (from_top > 10); l36 = 0.4 * lev[m]
    print(f"{nm:10s} min {l36.min():.3f} mm at {tilt[m][np.argmin(l36)]:5.1f} deg   below 0.45: {100*(l36<0.45).mean():4.1f}%"
          f"   below 0.20: {100*(l36<0.2).mean():4.1f}%   deficit {np.maximum(0, 0.45 - l36).mean():.4f}")

for g in ('mono-g1', 'mono-g2', 'mono-g3'):
    show(g, *smooth_lever(np.load(G + f'monostable-search/genomes/{g}.npy')))
a = np.load(G + 'families/family0/f0_best_b.npy'); A = a.reshape(3, -1)
lev, tilt, rr, ang, ft = fam.face_lever(A); show('f0_best_b', lev, tilt, ft)
