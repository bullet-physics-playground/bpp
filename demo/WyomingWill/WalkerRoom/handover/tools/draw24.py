#!/usr/bin/env python3
# Picture for patch 24: for each fixed diag build, top views of its guides cousin, the diag
# build as it was, and as fixed; and one foot's path (side view) for the three.
import collections, matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Polygon as Poly
from shapely.geometry import Polygon
def plans(fn):
    W = collections.OrderedDict()
    for l in open(fn):
        _, rest = l.rstrip("\n").split(" ", 1)
        name, kind, pts = rest.split("|")
        W.setdefault(name, []).append((kind, [tuple(map(float, p.split(","))) for p in pts.split(";")]))
    return W
def hull(P):
    P = sorted(set(P))
    if len(P) < 3: return P
    cr = lambda o, a, b: (a[0]-o[0])*(b[1]-o[1]) - (a[1]-o[1])*(b[0]-o[0])
    lo, up = [], []
    for p in P:
        while len(lo) >= 2 and cr(lo[-2], lo[-1], p) <= 0: lo.pop()
        lo.append(p)
    for p in reversed(P):
        while len(up) >= 2 and cr(up[-2], up[-1], p) <= 0: up.pop()
        up.append(p)
    return lo[:-1] + up[:-1]
STY = {"load": ("#d62728", "#7a0000", 7), "body": ("#7cc47c", "#2e6b2e", 1), "buildFoot": ("#555555", "#222222", 3), "link": ("#b8b8b8", "#555555", 4), "brace": ("#e0a030", "#8a5a00", 5)}
def top(ax, bodies, title):
    body = [P for k, P in bodies if k == "body"][0]
    cx = sum(p[0] for p in body) / 8; cz = sum(p[2] for p in body) / 8
    fz = [p[2] for k, P in bodies if k == "buildFoot" for p in P]
    for kind, P in sorted(bodies, key=lambda kb: STY["brace" if "Crossbar" in kb[0] else (kb[0] if kb[0] in STY else "link")][2]):
        k = "brace" if "Crossbar" in kind else (kind if kind in STY else "link")
        fc, ec, z = STY[k]
        ax.add_patch(Poly(hull([(p[0] - cx, p[2] - cz) for p in P]), closed=True, fc=fc, ec=ec, lw=0.6, alpha=0.85, zorder=z))
    for zz in (-19, 19): ax.axhline(zz, color="#c0392b", lw=0.8, ls="--", zorder=6)
    ax.set_xlim(-32, 32); ax.set_ylim(-24, 24); ax.set_aspect("equal"); ax.set_xticks([]); ax.set_yticks([])
    ax.set_title(f"{title}\nstance {max(fz) - min(fz):.1f} cm", fontsize=10)
def path(fn):
    L, S, feet = {}, collections.defaultdict(list), []
    for l in open(fn):
        if l.startswith("LINK") and "buildFoot" in l: feet.append(int(l.split()[1].split("|")[0]))
        elif l.startswith("S "):
            p = l.split(); k = int(p[1])
            if k in feet: S[k].append([tuple(map(float, q.split(","))) for q in p[2].split(";")])
    k = feet[0]
    xs = [Polygon(P).centroid.x for P in S[k]]; ys = [min(y for _, y in P) for P in S[k]]
    mx, my = (max(xs) + min(xs)) / 2, min(ys)
    return [x - mx for x in xs] + [xs[0] - mx], [y - my for y in ys] + [ys[0] - my]
old, new = plans("/home/claude/work/plan_old.txt"), plans("/home/claude/work/plan_new.txt")
pairs = [("Chebyshev", "Chebyshev diag"), ("Chebyshev-Spears", "Chebyshev-Spears diag"),
         ("Hoecken 4-bar", "Hoecken 4-bar diag"), ("Hoecken-Spears 4-bar", "Hoecken-Spears 4-bar diag")]
fig, A = plt.subplots(4, 4, figsize=(17, 15.5), gridspec_kw={"width_ratios": [1, 1, 1, 1.15]})
for r, (g, d) in enumerate(pairs):
    top(A[r][0], new[g], f"{g} (guides)")
    top(A[r][1], old[d], f"{d}, as it was")
    top(A[r][2], new[d], f"{d}, fixed")
    ax = A[r][3]
    for fn, lab, col, ls in ((f"/home/claude/work/sweep2/{g.replace(' ', '_')}.txt", "guides", "#2e6b2e", "-"),
                             (f"/home/claude/work/old_sweep/{d.replace(' ', '_')}.txt", "diag, as it was", "#c0392b", "--"),
                             (f"/home/claude/work/sweep2/{d.replace(' ', '_')}.txt", "diag, fixed", "#1f5fbf", ":")):
        x, y = path(fn)
        ax.plot(x, y, color=col, ls=ls, lw=2, label=f"{lab}: {max(x) - min(x):.1f} long, {max(y):.1f} high")
    ax.set_xlim(-9, 9); ax.set_ylim(-0.5, 6.5); ax.set_aspect("equal"); ax.grid(alpha=0.3)
    ax.set_title("one foot's path, side view (cm)", fontsize=10); ax.legend(fontsize=8.5, loc="upper center")
fig.suptitle("Patch 24: four diag builds brought to the 15 cm stride. Top views at one moment of the stride (same scale): links grey, braces orange, body green, "
             "load red, feet dark; red dashes the 38 cm stance.\nRight: one foot's path over a crank turn, body held still. The fixed diag paths lie on their guides cousins'.", fontsize=11)
fig.tight_layout(rect=(0, 0, 1, 0.95))
fig.savefig("/home/claude/work/diag_stride_fix.png", dpi=100)
print("ok")
