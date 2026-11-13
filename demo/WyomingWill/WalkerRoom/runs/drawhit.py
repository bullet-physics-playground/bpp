#!/usr/bin/env python3
"""One hit drawn frame by frame (13 November; handover section 4f): runs/hitprobe.lua's dumps, side views.
  python3 runs/drawhit.py OUT.png HIT_TIME DUMP [HIT_TIME DUMP ...]
Each dump: a row of side views from 2 frames before HIT_TIME (s) on, every STEP frames (default 2), COLS of them
(default 8); the parts on the hit foot's side drawn solid, the far side's faint, the ground along that foot's line,
and each contact's normal force as an arrow (1 W, the walker's weight, = ARROW cm, default 8). Then OUT's -forces.png:
for each, the body's x (from the hit) and height, the face's push back on the hit foot, the weight on the
other feet and how many parts touch the ground, frame by frame. Friction isn't in the arrows (the contacts give
only their normal impulse)."""
import sys, os, collections
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Polygon

STEP, COLS, ARROW = int(os.environ.get("STEP", 2)), int(os.environ.get("COLS", 8)), float(os.environ.get("ARROW", 8))

def load(path):
    frames, name = [], None
    for line in open(path):
        p = line.split()
        if p[0] == "WALKER": name = line[7:].split("|")[0]
        elif p[0] == "FRAME": frames.append({"t": float(p[1]), "parts": [], "ground": {}, "contacts": []})
        elif p[0] == "BODY": frames[-1]["body"] = list(map(float, p[1:]))
        elif p[0] == "PART":
            pts = [tuple(map(float, q.split(","))) for q in p[4].split(";")]
            frames[-1]["parts"].append((int(p[1]), p[2], float(p[3]), pts))
        elif p[0] == "GROUND":
            frames[-1]["ground"][int(p[1])] = (float(p[2]), float(p[3]), list(map(float, p[4].split(","))))
        elif p[0] == "CONTACT":
            frames[-1]["contacts"].append((int(p[1]), *map(float, p[2:])))
    return name, frames

def hitfoot(frames, k):
    """the foot of the hit: the one the ground pushes back hardest in the next 10 frames"""
    push = collections.Counter()
    for f in frames[k:k + 10]:
        for c in f["contacts"]: push[c[0]] += max(0, -c[4])
    i = push.most_common(1)[0][0]
    z = next(z for j, kind, z, pts in frames[k]["parts"] if j == i and kind == "buildFoot")
    return i, z

out, args = sys.argv[1], sys.argv[2:]
runs = [(float(args[i]), args[i + 1]) for i in range(0, len(args), 2)]
fig, axes = plt.subplots(len(runs), COLS, figsize=(3.4 * COLS, 2.9 * len(runs)), squeeze=False)
series = []
for r, (th, path) in enumerate(runs):
    name, frames = load(path)
    k0 = min(range(len(frames)), key=lambda k: abs(frames[k]["t"] - th))
    foot, fz = hitfoot(frames, k0)
    near = lambda z: (z < 0) == (fz < 0)
    x0 = frames[k0]["body"][0]
    fx0 = max(x for i, kind, z, pts in frames[k0]["parts"] if i == foot and kind in ("buildFoot", "tip") for x, _ in pts)
    for c in range(COLS):
        k = k0 - 2 + c * STEP
        ax = axes[r][c]
        if k >= len(frames): ax.axis("off"); continue
        f = frames[k]
        zg, xg, g = f["ground"][foot]
        ax.fill_between([xg + 0.5 * j for j in range(len(g))], [-3] * len(g), g, color="#c9b48a", lw=0)
        b = f["body"]
        for i, kind, z, pts in sorted(f["parts"], key=lambda p: near(p[2])):
            solid = near(z)
            col = {"buildFoot": "#333333", "tip": "#333333", "buildOutsideCrossbar": "#d08000"}.get(kind, "#1aa3b5")
            if i == foot and kind in ("buildFoot", "tip"): col = "#d01010"
            ax.add_patch(Polygon(pts, closed=True, fc=col, ec="none", alpha=1.0 if solid else 0.18))
        ax.add_patch(Polygon([(b[0], b[1]), (b[2], b[1]), (b[2], b[3]), (b[0], b[3])], closed=True, fc="#5b6cff", ec="none", alpha=0.35))
        for i, px, py, pz, ffx, ffy in f["contacts"]:
            if not near(pz) and i != foot: continue
            ax.annotate("", xy=(px + ARROW * ffx, py + ARROW * ffy), xytext=(px, py),
                        arrowprops=dict(arrowstyle="->", color="#e00000" if i == foot else "#008000", lw=1.2))
        ax.set_xlim(fx0 - 48, fx0 + 8); ax.set_ylim(-1, 25); ax.set_aspect("equal"); ax.set_xticks([]); ax.set_yticks([])
        ms = 1000 * (f["t"] - frames[k0]["t"])
        ax.set_title(f"{ms:+.0f} ms   body {b[0] - x0:+.1f} cm", fontsize=9)
        if c == 0: ax.set_ylabel(name, fontsize=9)
    # the forces, frame by frame
    S = collections.defaultdict(list)
    for f in frames:
        S["t"].append(1000 * (f["t"] - frames[k0]["t"]))
        S["x"].append(f["body"][0] - x0); S["y"].append(f["body"][1] - frames[k0]["body"][1])
        S["push"].append(-sum(c[4] for c in f["contacts"] if c[0] == foot))
        S["others"].append(sum(c[5] for c in f["contacts"] if c[0] != foot))
        S["feet"].append(len({c[0] for c in f["contacts"] if c[5] > 0.02}))
    series.append((name, S))
fig.suptitle(f"A front foot (red) meets a 7 cm step's face; arrows: the ground's push on the walker ({ARROW:g} cm = its weight); faint: the far side", fontsize=10)
fig.tight_layout()
fig.savefig(out, dpi=110)
fig2, ax2 = plt.subplots(5, 1, figsize=(9, 10.5), sharex=True)
for name, S in series:
    ax2[0].plot(S["t"], S["x"], label=name); ax2[1].plot(S["t"], S["y"], label=name)
    ax2[2].plot(S["t"], S["push"], label=name); ax2[3].plot(S["t"], S["others"], label=name)
    ax2[4].step(S["t"], S["feet"], where="mid", label=name)
for a, l in zip(ax2, ["body x from the hit, cm", "body height from the hit, cm", "face's push back on the foot, x weight", "weight on the other parts, x weight", "parts on the ground"]):
    a.set_ylabel(l, fontsize=8); a.axvline(0, color="grey", lw=0.6); a.grid(alpha=0.3)
ax2[0].legend(fontsize=8); ax2[4].set_xlabel("ms from the hit"); ax2[4].set_xlim(-170, 400)
fig2.tight_layout()
fig2.savefig(out.replace(".png", "-forces.png"), dpi=110)
print(out, out.replace(".png", "-forces.png"))
