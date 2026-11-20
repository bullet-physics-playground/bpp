"""Levers (mm at 36) around the two tips of the long axis of a smooth genome."""
import sys, numpy as np
import os; G = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'); sys.path.insert(0, G)
import smooth
c = np.load(sys.argv[1]); L = next(L for L in range(2, 20) if (L + 1) ** 2 - 4 == len(c)); S = smooth.Sphere(L, level=6)
B = S.body(c); N = S.N; R = B['x'] - B['G']; d = np.linalg.norm(R, axis=1); s = 90.0 / (2 * d.max())
lev = 0.4 * s * np.linalg.norm(R - (R * N).sum(1)[:, None] * N, axis=1)
mn, mx = S.equilibria(B['hG']); i0, i1 = mn[0][1], mx[0][1]
w, V = np.linalg.eigh(np.cov(R.T)); ax = V[:, 2]
for sgn in (1, -1):
    k = np.argmax(sgn * R @ ax); tipn = N[k]
    tilt = np.degrees(np.arccos(np.clip(tipn @ N[i0], -1, 1)))
    print(f"tip {'+' if sgn > 0 else '-'}: {d[k] * s * 2 * 45 / 45:.1f} mm from G (at 90)  tilt from rest {tilt:.1f} deg  "
          f"from top {np.degrees(np.arccos(np.clip(tipn @ R[i1] / d[i1], -1, 1))):.0f} deg")
    for rad in (3, 6, 10, 15):
        m = N @ tipn > np.cos(np.radians(rad)); print(f"   within {rad:2d} deg: lever min {lev[m].min():.3f}  median {np.median(lev[m]):.3f} mm at 36")
np.save('tipdir.npy', np.array([N[np.argmax(R @ ax)], N[np.argmax(-R @ ax)]]))
for sgn in (1, -1):
    a = sgn * ax; print(f"axis {'+' if sgn > 0 else '-'} direction: tilt from rest {np.degrees(np.arccos(np.clip(a @ N[i0], -1, 1))):.1f} deg")
    for rad in (3, 6, 10):
        m = N @ a > np.cos(np.radians(rad)); t = np.degrees(np.arccos(np.clip(N[m] @ N[i0], -1, 1)))
        print(f"   normals within {rad:2d} deg of axis: lever min {lev[m].min():.3f} median {np.median(lev[m]):.3f}  tilts {t.min():.0f}-{t.max():.0f}")
n0 = N[i0]; P = R - (R @ n0)[:, None] * n0                      # horizontal (at rest) parts
w2, V2 = np.linalg.eigh(np.cov(P.T)); hx = V2[:, 2]; hx -= (hx @ n0) * n0; hx /= np.linalg.norm(hx)
tilt = np.degrees(np.arccos(np.clip(N @ n0, -1, 1)))
for sgn in (1, -1):
    a = sgn * hx; ext = (R @ a).max() * s
    az = np.degrees(np.arccos(np.clip((N - (N @ n0)[:, None] * n0) @ a / np.linalg.norm(N - (N @ n0)[:, None] * n0, axis=1), -1, 1)))
    m = (tilt > 80) & (tilt < 92) & (az < 10)
    print(f"horizontal {'+' if sgn > 0 else '-'}: tip {ext:.1f} mm from G (at 90)   normals tilt 80-92, azimuth < 10: "
          f"lever min {lev[m].min():.3f} median {np.median(lev[m]):.3f}  (n {m.sum()})")
    for lo in range(80, 92, 2):
        mm = m & (tilt >= lo) & (tilt < lo + 2); print(f"     tilt {lo}-{lo+2}: min {lev[mm].min():.3f} median {np.median(lev[mm]):.3f}")
np.save('hx.npy', np.r_[hx, n0])
