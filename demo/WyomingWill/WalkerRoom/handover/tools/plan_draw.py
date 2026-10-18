import collections, matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Polygon
W = collections.OrderedDict()
for l in open("plan.txt"):
    _, rest = l.rstrip("\n").split(" ", 1)
    name, kind, pts = rest.split("|")
    W.setdefault(name, []).append((kind, [tuple(map(float, p.split(","))) for p in pts.split(";")]))
def hull(P):
    P = sorted(set(P))
    if len(P) < 3: return P
    def cr(o, a, b): return (a[0]-o[0])*(b[1]-o[1]) - (a[1]-o[1])*(b[0]-o[0])
    lo, up = [], []
    for p in P:
        while len(lo) >= 2 and cr(lo[-2], lo[-1], p) <= 0: lo.pop()
        lo.append(p)
    for p in reversed(P):
        while len(up) >= 2 and cr(up[-2], up[-1], p) <= 0: up.pop()
        up.append(p)
    return lo[:-1] + up[:-1]
STY = {"load": ("#d62728", "#7a0000", 7), "body": ("#7cc47c", "#2e6b2e", 1), "buildFoot": ("#555555", "#222222", 3), "link": ("#b8b8b8", "#555555", 4), "brace": ("#e0a030", "#8a5a00", 5)}
names = list(W)
cols = 5; rows = (len(names) + cols - 1) // cols
fig, axes = plt.subplots(rows, cols, figsize=(cols * 4.2, rows * 4.6))
for ax in axes.flat: ax.axis("off")
for ax, name in zip(axes.flat, names):
    bodies = W[name]
    body = [P for k, P in bodies if k == "body"][0]
    cx = sum(p[0] for p in body) / 8; cz = sum(p[2] for p in body) / 8
    bw = max(p[2] for p in body) - min(p[2] for p in body)
    bl = max(p[0] for p in body) - min(p[0] for p in body)
    # draw lowest first so the body sits under links? body under, then feet, links, braces
    order = sorted(bodies, key=lambda kb: STY["brace" if "Crossbar" in kb[0] else (kb[0] if kb[0] in STY else "link")][2])
    for kind, P in order:
        k = "brace" if "Crossbar" in kind else (kind if kind in STY else "link")
        fc, ec, z = STY[k]
        pts = hull([(p[0] - cx, p[2] - cz) for p in P])
        ax.add_patch(Polygon(pts, closed=True, fc=fc, ec=ec, lw=0.6, alpha=0.9 if k != "body" else 0.8, zorder=z))
    for zz in (-19, 19):
        ax.axhline(zz, color="#c0392b", lw=0.8, ls="--", zorder=6)
    ax.set_xlim(-55, 55); ax.set_ylim(-24, 24); ax.set_aspect("equal")
    ax.set_title(f"{name}\nbody {bl:.1f} long, {bw:.1f} wide (cm)", fontsize=11)
import textwrap
fig.suptitle(textwrap.fill("Every walker from above, as the room now builds it -- same scale, walking left-right. Feet (dark) centred under each leg; links (grey) 0.3 cm thick in planes 0.7 cm apart, as few planes as keep them from touching; braces orange; body green, a frame spanning its leg mounts (3 cm past the first and last); red square: its 40 kg load, where the walker balances over its feet. Red dashes: the 38 cm stance. Feet shown where they are at one moment of the stride.", 150), fontsize=11)
fig.tight_layout(rect=(0, 0, 1, 0.95))
fig.savefig("walkers_from_above.png", dpi=110)
