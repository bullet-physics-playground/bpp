#!/usr/bin/env python3
# The two diag builds' foot paths (held-body sweeps, the body's frame; the way it walks to the right), coloured by
# the direction the foot moves (up from the walking direction), and that direction at heights through the swing.
import sys, math; sys.path.insert(0, "/home/claude/work")
import topz, numpy as np
import matplotlib; matplotlib.use("Agg"); import matplotlib.pyplot as plt
from matplotlib.collections import LineCollection
B = [("sweep6W/Chebyshev-Spears_diag.txt", "Chebyshev-Spears diag", 1), ("sweepSD2/Hoecken-Spears_slider_diag.txt", "Hoecken-Spears slider diag", 1)]
fig, axs = plt.subplots(2, 1, figsize=(9, 7.5))
for ax, (p, lab, fwd) in zip(axs, B):
    name, L, S, bb, hz = topz.load(p)
    feet = [i for i in L if L[i]["kind"] == "buildFoot"]; n = min(len(S[i]) for i in L)
    f = feet[0]
    x = np.array([fwd * S[f][k].centroid.x for k in range(n)]); y = np.array([S[f][k].bounds[1] for k in range(n)])
    x -= (x.max() + x.min()) / 2; y -= y.min()
    dx, dy = np.gradient(x), np.gradient(y)
    ang = np.degrees(np.arctan2(dy, dx))
    pts = np.array([x, y]).T.reshape(-1, 1, 2); segs = np.concatenate([pts[:-1], pts[1:]], axis=1)
    lc = LineCollection(segs, cmap="coolwarm", norm=plt.Normalize(-90, 90), lw=3); lc.set_array(ang[:-1]); ax.add_collection(lc)
    ax.set_xlim(-10, 10); ax.set_ylim(-0.5, 6); ax.set_aspect("equal"); ax.grid(alpha=0.3)
    ax.set_title(f"{lab}: foot path in the body's frame (walks to the right), coloured by direction of motion", fontsize=9, loc="left")
    # the forward swing (moving forward, dx > 0) rising part: direction at heights
    ax.annotate("front: the foot comes down", (7.5, 1.5), fontsize=8); ax.annotate("back: the foot lifts", (-9.8, 3.0), fontsize=8)
    # the end of the swing (the front third, moving forward): how far it rises again after first coming down
    fr = [k for k in range(n) if x[k] > 3 and dx[k] > 0.01]
    if fr:
        ys = [y[k] for k in fr]; lo = min(ys); k0 = fr[ys.index(lo)]
        after = [y[k] for k in fr if x[k] > x[k0]]
        print(f"{lab:28s} lift {y.max():.2f}; front of the swing: comes down to {lo:.2f} cm at x {x[k0]:+.1f}, then rises again to {max(after) if after else lo:.2f}")
cb = fig.colorbar(lc, ax=axs, shrink=0.6); cb.set_label("direction of motion, degrees up from the walking direction (body frame)")
fig.savefig("/home/claude/out/foot_path_direction.png", dpi=110)
