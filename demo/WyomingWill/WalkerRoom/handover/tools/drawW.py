#!/usr/bin/env python3
# Every run build from the side at one moment (near side only): today's bars outlined (sweepT/), 1.0 cm bars filled
# (sweepTW2/, LINK_WIDTH 1.0 with its refits: lift bodies, CS diag on 3 planes, outside V braces).
import sys, glob, collections, math
import matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Polygon as MPoly, Rectangle
def load(path):
    L, R, bb = {}, collections.defaultdict(list), None
    for l in open(path):
        if l.startswith("WALKER"):
            f = l.strip().split("|"); name = f[0][7:]; bb = [float(x) for x in f[3].split()[1:]]
        elif l.startswith("LINK"):
            f = l.strip().split("|"); L[int(f[0].split()[1])] = dict(z=float(f[1].split()[1]), kind=f[4].split()[1])
        elif l.startswith("S "):
            p = l.split(); R[int(p[1])].append([tuple(map(float, q.split(","))) for q in p[2].split(";")])
    return name, L, R, bb
files = sorted(glob.glob("/home/claude/work/sweepTW2/*.txt"))
fig, axs = plt.subplots(5, 4, figsize=(15, 17)); axs = axs.ravel()
for ax, f in zip(axs, files):
    name, L, R, bb = load(f); _, L0, R0, bb0 = load(f.replace("sweepTW2", "sweepT"))
    g = min(min(y for _, y in R[i][0]) for i in L if L[i]["kind"] == "buildFoot")
    ax.add_patch(Rectangle((bb[0], bb[2]), bb[1] - bb[0], bb[3] - bb[2], fc="#e8e8e8", ec="#999999", lw=0.7))
    for i in L:
        if L[i]["z"] < 0: continue
        k = L[i]["kind"]; c = R[i][0]
        if k == "buildFoot": col = "#5a5a5a"
        elif "Crossbar" in k: col = "#b22222" if sum(y for _, y in c) / len(c) > -2 else "#4a55b5"
        else: col = "#8a96a8"
        xs = [p[0] for p in c]
        if max(xs) - min(xs) < 0.3: continue    # (a brace piece seen end on)
        ax.add_patch(MPoly(c, closed=True, fc=col, ec="none", alpha=0.8))
    g0 = min(min(y for _, y in R0[i][0]) for i in L0 if L0[i]["kind"] == "buildFoot")
    for i in L0:
        if L0[i]["z"] < 0 or L0[i]["kind"] not in ("makeLink", "buildLinkage", "?"): continue
        c = [(x, y - g0 + g) for x, y in R0[i][0]]
        ax.add_patch(MPoly(c, closed=True, fc="none", ec="black", lw=0.6, ls="--"))
    ax.axhline(g, color="#777777", lw=0.6)
    ax.set_title(name, fontsize=9); ax.set_aspect("equal"); ax.autoscale_view(); ax.tick_params(labelsize=6)
    ax.set_xlim(bb[0] - 14, bb[1] + 14)
for ax in axs[len(files):]: ax.axis("off")
fig.suptitle("Every run build from the side, near side, one moment (cm). Filled: bars 1.0 cm wide (LINK_WIDTH), with the refits;\ndashed: today's bars (drawn from the same ground line). Red/blue: top/bottom outside brace; dark: feet; shaded: body.", fontsize=10)
fig.tight_layout(rect=(0, 0, 1, 0.965)); fig.savefig("/home/claude/work/link_width.png", dpi=95); print("ok")
