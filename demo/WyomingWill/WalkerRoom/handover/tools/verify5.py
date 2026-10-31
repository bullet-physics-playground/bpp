#!/usr/bin/env python3
# Independent check of the built outside braces, from sweep6/ (sweep6.sh: DIAG_OUTSIDE built, body held, one crank
# turn). Uses the brace pieces as built and as they moved (not the fit's numbers): the runs as swept, each diagonal
# rebuilt between its runs' inner ends and cut into thin slices. Every piece against every link and foot (12 wide)
# at every moment, with the fitter's rule (a piece within 0.3 of a part's slab across must be 0.3 from it in the
# plane; a run is welded to its own pendant, so that pair is skipped); the body's box (pieces over or under it); the
# top brace over the letters; each run's height within its pendant (where it is bolted).
import collections, math, sys
sys.path.insert(0, "/home/claude/work")
import topz
from shapely.geometry import box, Polygon
from shapely import affinity
M, T = 0.3, 0.3
LETTERS = {"Chebyshev-Spears_diag": 1.45, "Hoecken-Spears_4-bar_diag": 1.50, "Chebyshev_diag": 2.77, "Hoecken_4-bar_diag": 2.85,
           "Hoecken-Spears_4-bar_duty_85_diag": 1.72, "Chebyshev-Spears_lift_51_diag": 2.00, "Chebyshev-Spears_lift_62_diag": 2.31}
def run(b):
    path = f"/home/claude/work/{__import__('os').environ.get('SWEEP6', 'sweep6')}/{b}.txt"
    name, L, S, bb, hz = topz.load(path)
    joins = [l.split() for l in open(path) if l.startswith("JOIN")]
    n = min(len(S[i]) for i in L)
    feet = [i for i in L if L[i]["kind"] == "buildFoot"]
    pieces = [i for i in L if L[i]["kind"] == "buildOutsideCrossbar"]
    parts = [i for i in L if i not in pieces]
    weldP = {}                     # run piece -> its pendant
    nbr = collections.defaultdict(set)
    for j in joins:
        a, c = int(j[1]), int(j[2])
        if a in pieces and c in pieces: nbr[a].add(c); nbr[c].add(a)
        elif a in pieces: weldP[a] = c
        elif c in pieces: weldP[c] = a
    diags = [i for i in pieces if abs(L[i]["z"]) < 0.01]
    out = []
    for d in diags:
        runs = sorted(nbr[d], key=lambda i: -L[i]["z"])
        assert len(runs) == 2 and all(r in weldP for r in runs), (b, d, runs)
        y0 = S[runs[0]][0].bounds[1]
        which = "top" if y0 > -2 else "bottom"
        own = {weldP[r] for r in runs}
        worst = (99, None); bodyg = 99; letg = 99
        ymin_r, ymax_r = 1e9, -1e9
        for k in range(n):
            segs = []
            ends = []
            for r in runs:
                p = S[r][k]; pend = S[weldP[r]][k]
                px = pend.centroid.x
                a, yb, c, yt = p.bounds
                inner = a if abs(a - px) > abs(c - px) else c          # the run's end away from its pendant
                ends.append((inner, L[r]["z"]))   # (the diagonal starts where the run ends: both are built to that point)
                segs.append(("run", r, L[r]["z"] - T / 2, L[r]["z"] + T / 2, p))
            (xa, za), (xb, zb) = ends
            N = 120
            for s in range(N):
                t0, t1 = s / N, (s + 1) / N
                x0, x1 = xa + (xb - xa) * t0, xa + (xb - xa) * t1
                z0, z1 = za + (zb - za) * t0, za + (zb - za) * t1
                segs.append(("diag", d, min(z0, z1) - T / 2, max(z0, z1) + T / 2, box(min(x0, x1) - T / 2, yb, max(x0, x1) + T / 2, yt)))
            for kind, pid, zlo, zhi, poly in segs:
                for i in parts:
                    if kind == "run" and i == weldP[pid]: continue
                    t = 6.0 if i in feet else 0.15
                    z = L[i]["z"]
                    if z - t - M >= zhi or z + t + M <= zlo: continue
                    g = poly.distance(S[i][k])
                    if g < worst[0]: worst = (g, (i, L[i]["kind"], "own pendant" if i in own else "", kind, k))
                # body box, for pieces passing over or under it
                if zhi > -hz and zlo < hz:
                    a, y_lo, c, y_hi = poly.bounds
                    if c > bb[0] and a < bb[1]:
                        g = (y_lo - bb[3]) if y_lo > 0 else (bb[2] - y_hi)
                        bodyg = min(bodyg, g)
                        if which == "top": letg = min(letg, y_lo - LETTERS[b])
            # runs within their pendants' height (bolted to them)
            for r in runs:
                pb = S[weldP[r]][k].bounds; rb = S[r][k].bounds
                ymin_r = min(ymin_r, rb[1] - pb[1]); ymax_r = max(ymax_r, rb[3] - pb[3])
        out.append((which, worst, bodyg, letg, ymin_r, ymax_r, S[runs[0]][0].bounds))
    return name, n, out
if __name__ == "__main__":
    bs = sys.argv[1:] or list(LETTERS)
    for b in bs:
        name, n, out = run(b)
        for which, worst, bodyg, letg, ylo, yhi, rb in sorted(out, key=lambda o: o[0] != "top"):
            g, who = worst
            lt = f", over letters {letg:.2f}" if which == "top" else ""
            print(f"{name:32s} {which:6s} closest part {g:5.2f} cm {who}; body {'over' if which == 'top' else 'under'} by {bodyg:.2f}{lt}; run bottom {ylo:+.2f} above pendant end, run top {yhi:+.2f} vs pendant top ({n} moments)")
