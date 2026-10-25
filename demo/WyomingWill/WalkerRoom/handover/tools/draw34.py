#!/usr/bin/env python3
# Side views of the nine plated builds: plates as built (sweepP/) against low plates (PLATE_LOW, sweepL/), one moment;
# dashed: each plate at its lowest and highest in the turn; line: the ground (the feet's lowest).
import sys; sys.path.insert(0, "/home/claude/work")
import topz
import matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle, Polygon as MPoly
B = [("Chebyshev", "Chebyshev"), ("Chebyshev-Spears", "Chebyshev-Spears"), ("Hoecken_4-bar", "Hoecken 4-bar"),
     ("Hoecken-Spears_4-bar", "Hoecken-Spears 4-bar"), ("Hoecken-Spears_long-stance", "Hoecken-Spears long-stance"),
     ("Spears_lift_44", "Spears lift 44"), ("Spears_lift_53", "Spears lift 53"), ("Hoecken_slider", "Hoecken slider"),
     ("Hoecken-Spears_slider", "Hoecken-Spears slider")]
def load(d, b):
    name, L, S, bb, hz = topz.load(f"/home/claude/work/{d}/{b}.txt")
    return dict(L=L, S=S, bb=bb, n=min(len(S[i]) for i in L))
def draw(ax, W, title, ytop):
    L, S, bb = W["L"], W["S"], W["bb"]
    feet = [i for i in L if L[i]["kind"] == "buildFoot"]
    g = min(S[f][k].bounds[1] for f in feet for k in range(W["n"]))
    ax.axhline(g, color="#777777", lw=0.8)
    ax.add_patch(Rectangle((bb[0], bb[2]), bb[1] - bb[0], bb[3] - bb[2], fc="#e8e8e8", ec="#999999", lw=0.8, zorder=1))
    for i in L:
        k = L[i]["kind"]
        if k == "buildCrossbar" or L[i]["z"] < 0: continue   # (near side only, so the far side's links don't hide the plate)
        ax.add_patch(MPoly(list(S[i][0].exterior.coords), closed=True, fc="#5a5a5a" if k == "buildFoot" else "#8a96a8", ec="none", alpha=0.85, zorder=2))
    for i in L:
        if L[i]["kind"] != "buildCrossbar" or L[i]["z"] < 0: continue
        ys = [S[i][k].bounds[1] for k in range(W["n"])]
        ax.add_patch(MPoly(list(S[i][0].exterior.coords), closed=True, fc="#4a55b5", ec="none", alpha=0.75, zorder=3))
        for kk in (ys.index(min(ys)), ys.index(max(ys))):
            ax.add_patch(MPoly(list(S[i][kk].exterior.coords), closed=True, fc="none", ec="#4a55b5", ls="--", lw=0.7, zorder=3))
        ax.text(0.02, 0.92, f"plate bottom at its lowest {min(ys) - g:.2f} cm above the ground", transform=ax.transAxes, fontsize=7)
    ax.set_title(title, fontsize=9); ax.set_aspect("equal")
    ax.set_xlim(bb[0] - 12, bb[1] + 12); ax.set_ylim(g - 1.5, ytop); ax.tick_params(labelsize=7)
fig, axs = plt.subplots(len(B), 2, figsize=(11, 3.4 * len(B)))
for r, (b, nm) in enumerate(B):
    Wo, Wn = load("sweepP", b), load("sweepL", b)
    top = max(max(p.bounds[3] for p in W["S"][i]) for W in (Wo, Wn) for i in W["L"]) + 1.5
    draw(axs[r][0], Wo, f"{nm}: plates as built", top); draw(axs[r][1], Wn, f"{nm}: low plates (1.074 cm bar)", top)
fig.suptitle("Plated builds from the side (walks to the right; cm; near side only). Blue: the side plate (dashed: at its lowest and\nhighest in the turn); grey: links; dark: feet; shaded: body; line: the ground.", fontsize=9)
fig.tight_layout(rect=(0, 0, 1, 0.975)); fig.savefig("/home/claude/work/low_plates_side.png", dpi=105); print("ok")
