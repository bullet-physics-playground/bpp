#!/usr/bin/env python3
# Check of the V bottom braces as built (sweepV/: OUTSIDE_V, body held, one turn), apart from the fitter: the runs from
# their swept outlines, each middle piece (bottom and top) from one of its runs' ends to the other's, cut across the walk,
# against every link, foot (12 wide) and the top brace's pieces, every moment; runs skip their own pendants.
# Also: the middle piece under the body, the runs' ends against the pendants' tops, the brace's lowest above the ground.
import sys, math, collections
sys.path.insert(0, "/home/claude/work")
import topz
from shapely.geometry import box, Polygon
M, T, ZS = 0.3, 0.3, 13.3
def raw(path):
    R = collections.defaultdict(list)
    for l in open(path):
        if l.startswith("S "):
            p = l.split(); R[int(p[1])].append([tuple(map(float, q.split(","))) for q in p[2].split(";")])
    return R
def run(b):
    path = f"/home/claude/work/sweepV/{b}.txt"
    name, L, S, bb, hz = topz.load(path); R = raw(path)
    J = [l.split() for l in open(path) if l.startswith("JOIN")]
    n = min(len(R[i]) for i in L)
    pcs = [i for i in L if L[i]["kind"] == "buildOutsideCrossbar"]
    weld = {}
    for j in J:
        a, c = int(j[1]), int(j[2])
        if a in pcs and c not in pcs: weld[a] = c
        elif c in pcs and a not in pcs: weld[c] = a
    ylo = lambda i: min(y for _, y in R[i][0])
    mids = [i for i in pcs if abs(L[i]["z"]) < 1]
    bmid = min(mids, key=ylo); tmid = max(mids, key=ylo)
    bruns = [i for i in pcs if i in weld and abs(L[i]["z"]) > 1 and ylo(i) < ylo(tmid) - 3]
    feet = [i for i in L if L[i]["kind"] == "buildFoot"]
    others = [i for i in L if i not in bruns and i != bmid]
    truns = [i for i in pcs if i in weld and abs(L[i]["z"]) > 1 and i not in bruns]
    def inner(r, k):   # a run's end away from its pendant: the middle of its two corners farthest from the pendant
        px = sum(x for x, _ in R[weld[r]][k]) / len(R[weld[r]][k])
        c = sorted(R[r][k], key=lambda q: -abs(q[0] - px))[:2]
        return (c[0][0] + c[1][0]) / 2
    def mid_slices(m, runs, k):   # the middle piece from one run's end to the other's, cut across the walk
        ends = {L[r]["z"] > 0: inner(r, k) for r in runs}
        ys = [y for _, y in R[m][k]]; out = []; N = 60
        for s in range(N):
            t0, t1 = s / N, (s + 1) / N
            a, c = ends[True] + (ends[False] - ends[True]) * t0, ends[True] + (ends[False] - ends[True]) * t1
            z0, z1 = ZS - 2 * ZS * t0, ZS - 2 * ZS * t1
            out.append((min(z0, z1) - T / 2, max(z0, z1) + T / 2, box(min(a, c) - T / 2, min(ys), max(a, c) + T / 2, max(ys))))
        return out
    def items(i, k):   # [(zlo, zhi, shape)] of a part
        if i == tmid: return mid_slices(tmid, truns, k)
        t = 6.0 if i in feet else 0.15
        return [(L[i]["z"] - t, L[i]["z"] + t, Polygon(R[i][k]).buffer(0))]
    worst = {}
    for piece in bruns + [bmid]:
        best = (99, None)
        for k in range(n):
            mine = mid_slices(bmid, bruns, k) if piece == bmid else [(L[piece]["z"] - T / 2, L[piece]["z"] + T / 2, Polygon(R[piece][k]).buffer(0))]
            for i in others:
                if piece in weld and i == weld[piece]: continue
                for zlo, zhi, P in mine:
                    for a, c, Q in items(i, k):
                        if a - M >= zhi or c + M <= zlo: continue
                        g = P.distance(Q)
                        if g < best[0]: best = (g, (L[i]["kind"], round(L[i]["z"], 1), k))
        worst["middle" if piece == bmid else f"run z{L[piece]['z']:+.1f}"] = best
    under = min(bb[2] - max(y for _, y in R[bmid][k]) for k in range(n))
    ground = min(min(y for _, y in R[bmid][k]) for k in range(n)) - min(min(y for _, y in R[f][k]) for f in feet for k in range(n))
    endtop = max(max(max(y for _, y in R[r][k]) - max(y for _, y in R[weld[r]][k]) for k in range(n)) for r in bruns)
    span = max(max(x for x, _ in R[bmid][k]) - min(x for x, _ in R[bmid][k]) for k in range(n))
    return name, worst, under, ground, endtop, span
if __name__ == "__main__":
    for b in (sys.argv[1:] or ["Chebyshev-Spears_diag", "Hoecken-Spears_4-bar_diag", "Chebyshev_diag", "Hoecken_4-bar_diag",
                              "Hoecken-Spears_long-stance_diag", "Spears_lift_44_diag", "Spears_lift_53_diag"]):
        name, worst, under, ground, endtop, span = run(b)
        w = "; ".join(f"{k} {v[0]:.2f} {v[1]}" for k, v in sorted(worst.items()))
        print(f"{name:32s} closest: {w}\n{'':32s} middle under the body by {under:.2f}, {span:.2f} along the walk, its bottom {ground:.2f} above the ground at its lowest; runs' tops {endtop:+.2f} against their pendants' tops")
