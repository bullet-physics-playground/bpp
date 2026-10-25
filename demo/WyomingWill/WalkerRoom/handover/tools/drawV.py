#!/usr/bin/env python3
# Patch 33's pictures: the five diag builds given outside braces, old braces (sweep_old/) against new (sweep6/).
# Top view (x along the walk, the way it walks to the right; z across) and side view (x, y), one moment of the turn;
# in the side view the braces' highest and lowest places through the turn dashed, the body's letters dotted.
import sys, collections
sys.path.insert(0, "/home/claude/work")
import topz
import matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle, Polygon as MPoly
BUILDS = [("Chebyshev-Spears_diag", "Chebyshev-Spears diag"), ("Hoecken-Spears_4-bar_diag", "Hoecken-Spears 4-bar diag"),
          ("Chebyshev_diag", "Chebyshev diag"), ("Hoecken_4-bar_diag", "Hoecken 4-bar diag"),
          ("Hoecken-Spears_long-stance_diag", "Hoecken-Spears long-stance diag"),
          ("Spears_lift_44_diag", "Spears lift 44 diag"), ("Spears_lift_53_diag", "Spears lift 53 diag")]
LETTERS = {"Chebyshev-Spears_diag": 1.45, "Hoecken-Spears_4-bar_diag": 1.50, "Chebyshev_diag": 2.77, "Hoecken_4-bar_diag": 2.85, "Hoecken-Spears_long-stance_diag": 1.72,
           "Spears_lift_44_diag": 2.00, "Spears_lift_53_diag": 2.31}
TOPC, BOTC, PENDC, LINKC, FOOTC = "#b22222", "#4a55b5", "#c9a227", "#8a96a8", "#5a5a5a"
RAW = {}
def load(d, b):
    path = f"/home/claude/work/{d}/{b}.txt"
    name, L, S, bb, hz = topz.load(path)
    joins = [l.split() for l in open(path) if l.startswith("JOIN")]
    W = dict(L=L, S=S, bb=bb, hz=hz, joins=joins, n=min(len(S[i]) for i in L))
    R = collections.defaultdict(list)
    for l in open(path):
        if l.startswith("S "):
            p = l.split(); R[int(p[1])].append([tuple(map(float, q.split(","))) for q in p[2].split(";")])
    RAW[id(W)] = R
    return W
def braces(W):
    """[(colour, list of top-view segments ((x0, z0), (x1, z1)), piece ids)] for the top and bottom brace"""
    L, S, J = W["L"], W["S"], W["joins"]
    pcs = [i for i in L if "Crossbar" in L[i]["kind"]]
    nbr, weld = collections.defaultdict(set), collections.defaultdict(set)
    for j in J:
        a, c = int(j[1]), int(j[2])
        if a in pcs and c in pcs: nbr[a].add(c); nbr[c].add(a)
        elif a in pcs: weld[a].add(c)
        elif c in pcs: weld[c].add(a)
    seen, out = set(), []
    for i in pcs:
        if i in seen: continue
        grp, st = set(), [i]
        while st:
            k = st.pop()
            if k in grp: continue
            grp.add(k); st += list(nbr[k])
        seen |= grp
        pends = sorted({p for k in grp for p in weld[k]}, key=lambda p: -L[p]["z"])
        y = sum(sum(p[1] for p in RAW[id(W)][k][0]) / 4 for k in grp) / len(grp)
        kinds = {L[k]["kind"] for k in grp}
        top = (y > -2) if "buildOutsideCrossbar" in kinds else ("buildDiagonalCrossbar" in kinds)
        segs = []
        if "buildOutsideCrossbar" in kinds:
            runs = [k for k in grp if abs(L[k]["z"]) > 1]; diag = [k for k in grp if abs(L[k]["z"]) <= 1]
            ends = []
            for r in sorted(runs, key=lambda r: -L[r]["z"]):
                a, c = min(p[0] for p in RAW[id(W)][r][0]), max(p[0] for p in RAW[id(W)][r][0]); px = S[list(weld[r])[0]][0].centroid.x
                inner = a if abs(a - px) > abs(c - px) else c
                segs.append(((a, L[r]["z"]), (c, L[r]["z"]))); ends.append((inner, L[r]["z"]))
            segs.append((ends[0], ends[1]))
        else:   # old: straight or arched, pendant to pendant
            a, c = pends
            segs.append(((S[a][0].centroid.x, L[a]["z"]), (S[c][0].centroid.x, L[c]["z"])))
        out.append((TOPC if top else BOTC, segs, grp, pends))
    return out
def topview(ax, W, b, title):
    L, S = W["L"], W["S"]
    x0, x1, y0, y1 = W["bb"]
    ax.add_patch(Rectangle((x0, -W["hz"]), x1 - x0, 2 * W["hz"], fc="#e8e8e8", ec="#999999", lw=0.8))
    pend = {p for _, _, _, ps in braces(W) for p in ps}
    for i in L:
        k = L[i]["kind"]
        if "Crossbar" in k: continue
        a, _, c, _ = S[i][0].bounds; z = L[i]["z"]
        if k == "buildFoot":
            ax.add_patch(Rectangle((a, z - 6), c - a, 12, fc="none", ec=FOOTC, lw=0.8))
        else:
            ax.add_patch(Rectangle((a, z - 0.15), c - a, 0.3, fc=PENDC if i in pend else LINKC, ec="none"))
    for col, segs, _, _ in braces(W):
        for (xa, za), (xb, zb) in segs: ax.plot([xa, xb], [za, zb], color=col, lw=2.2, solid_capstyle="butt")
    ax.set_title(title, fontsize=9); ax.set_aspect("equal")
    ax.set_xlim(x0 - 14, x1 + 14); ax.set_ylim(-21, 21)
    ax.tick_params(labelsize=7)
def sideview(ax, W, b, title, ytop=None):
    L, S = W["L"], W["S"]
    x0, x1, y0, y1 = W["bb"]
    fb = min(S[i][0].bounds[1] for i in L if L[i]["kind"] == "buildFoot")
    ax.axhline(fb, color="#777777", lw=0.8)
    ax.add_patch(Rectangle((x0, y0), x1 - x0, y1 - y0, fc="#e8e8e8", ec="#999999", lw=0.8, zorder=1))
    ax.plot([x0, x1], [LETTERS[b]] * 2, ls=":", color="#555555", lw=1)
    bl = braces(W); pend = {p for _, _, _, ps in bl for p in ps}
    for i in L:
        k = L[i]["kind"]
        if "Crossbar" in k: continue
        p = S[i][0]
        ax.add_patch(MPoly(list(p.exterior.coords), closed=True, fc=FOOTC if k == "buildFoot" else (PENDC if i in pend else LINKC), ec="none", alpha=0.85, zorder=2))
    for col, _, grp, _ in bl:
        r = next(iter(grp)); ys = [S[r][k].centroid.y - S[r][0].centroid.y for k in range(W["n"])]
        kl, kh = ys.index(min(ys)), ys.index(max(ys))
        for g in grp:
            for kk, solid in ((0, True), (kl, False), (kh, False)):
                c = list(RAW[id(W)][g][kk]); xs = [p[0] for p in c]; ys = [p[1] for p in c]
                if max(xs) - min(xs) < 0.3:   # (straight across: seen end-on)
                    xm = (max(xs) + min(xs)) / 2; c = [(xm - 0.15, min(ys)), (xm + 0.15, min(ys)), (xm + 0.15, max(ys)), (xm - 0.15, max(ys))]
                ax.add_patch(MPoly(c, closed=True, fc=col if solid else "none", ec="none" if solid else col, ls="--", lw=0.7, zorder=3))
    ax.set_title(title, fontsize=9); ax.set_aspect("equal")
    ax.set_xlim(x0 - 14, x1 + 14); ax.set_ylim(fb - 1.5, ytop if ytop else fb + 38)
    ax.tick_params(labelsize=7)
for view, fn, out in (("top", topview, "v_braces_top.png"), ("side", sideview, "v_braces_side.png")):
    fig, axs = plt.subplots(len(BUILDS), 2, figsize=(11, 3.1 * len(BUILDS)) if view == "top" else (11, 3.9 * len(BUILDS)))
    for r, (b, nm) in enumerate(BUILDS):
        Wo, Wn = load("sweep6", b), load("sweepV", b)
        if view == "side":
            top = max(max(p.bounds[3] for p in W["S"][i]) for W in (Wo, Wn) for i in W["L"]) + 1.5
            fn(axs[r][0], Wo, b, f"{nm}: outside braces, flat bottom", top); fn(axs[r][1], Wn, b, f"{nm}: V bottom brace", top)
        else:
            fn(axs[r][0], Wo, b, f"{nm}: outside braces, flat bottom"); fn(axs[r][1], Wn, b, f"{nm}: V bottom brace")
    fig.suptitle(("From above (walks to the right; z across, cm). " if view == "top" else "From the side (walks to the right; cm). Dashed: each brace at its lowest and highest in the turn;\ndotted: top of the letters; line: the feet's bottoms. ")
                 + "\nRed: top brace, blue: bottom brace, gold: pendants, grey: other links, " + ("boxes: feet (12 wide), " if view == "top" else "dark: feet, ") + "shaded: body.", fontsize=9)
    fig.tight_layout(rect=(0, 0, 1, 0.965))
    fig.savefig(f"/home/claude/work/{out}", dpi=110)
    print(out)
