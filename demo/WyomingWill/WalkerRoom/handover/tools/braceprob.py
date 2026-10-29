#!/usr/bin/env python3
# How likely a diag build's bottom brace is to be inside a 7 cm log, from a held-body sweep (one crank turn), with the
# body level and the ground flat at the feet's lowest point: at each moment, for log angles uniform in -15..15 degrees,
# the share of log positions (logs as the room makes them: cos^2 ridges 7 cm high, 7.5 cm across, mean spacing 41.25 cm)
# that put some part of the brace's underside below the log's surface. Also by piece (the two runs and the diagonal).
import sys, math, collections
sys.path.insert(0, "/home/claude/work")
import topz
AMP, BUMP, SPACING = 7.0, 15.0, 2.75 * 15.0
def halfw(y):   # half the width of the part of a log higher than y
    if y >= AMP: return 0.0
    if y <= 0: return BUMP / 4
    return math.acos(math.sqrt(y / AMP)) / (2 * math.pi) * BUMP
def brace_points(path, which="bottom"):
    name, L, S, bb, hz = topz.load(path)
    joins = [l.split() for l in open(path) if l.startswith("JOIN")]
    n = min(len(S[i]) for i in L)
    pcs = [i for i in L if L[i]["kind"] == "buildOutsideCrossbar"]
    nbr = collections.defaultdict(set)
    for j in joins:
        a, c = int(j[1]), int(j[2])
        if a in pcs and c in pcs: nbr[a].add(c); nbr[c].add(a)
    groups, seen = [], set()
    for i in pcs:
        if i in seen: continue
        g, st = set(), [i]
        while st:
            k = st.pop()
            if k in g: continue
            g.add(k); st += list(nbr[k])
        seen |= g; groups.append(g)
    bot = min(groups, key=lambda g: sum(S[k][0].centroid.y for k in g))
    if which == "top": bot = max(groups, key=lambda g: sum(S[k][0].centroid.y for k in g))
    feet = [i for i in L if L[i]["kind"] == "buildFoot"]
    runs = sorted([k for k in bot if abs(L[k]["z"]) > 1], key=lambda k: L[k]["z"]); diag = [k for k in bot if abs(L[k]["z"]) <= 1]
    moments = []
    for m in range(n):
        ground = min(S[f][m].bounds[1] for f in feet)
        pts = []   # (x, z, y above ground, piece)
        ends = []
        for r in runs:
            x0, y0, x1, y1 = S[r][m].bounds
            for t in range(21):
                pts.append((x0 + (x1 - x0) * t / 20, L[r]["z"], y0 - ground, "run"))
            # the run's end toward the middle: the end nearer the other run's x
            ends.append((x0, x1, L[r]["z"]))
        for d in diag:
            x0, y0, x1, y1 = S[d][m].bounds
            # its z goes from one run's z to the other's along x: the run at the diagonal's low-x end
            (a0, a1, za), (b0, b1, zb) = ends
            za_x = min(abs(a0 - x0), abs(a1 - x0)); zb_x = min(abs(b0 - x0), abs(b1 - x0))
            z0, z1 = (za, zb) if za_x < zb_x else (zb, za)
            for t in range(41):
                pts.append((x0 + (x1 - x0) * t / 40, z0 + (z1 - z0) * t / 40, y0 - ground, "diag"))
        moments.append(pts)
    return name, moments
def prob(moments, only=None):
    tot = 0; cnt = 0
    for pts in moments:
        for ai in range(31):
            th = math.radians(-15 + ai)
            iv = []
            for x, z, y, k in pts:
                if only and k != only: continue
                w = halfw(y)
                if w > 0:
                    d = x * math.cos(th) + z * math.sin(th); iv.append((d - w, d + w))
            iv.sort(); meas = 0; cur = None
            for a, b in iv:
                if cur is None or a > cur[1]:
                    if cur: meas += cur[1] - cur[0]
                    cur = [a, b]
                else: cur[1] = max(cur[1], b)
            if cur: meas += cur[1] - cur[0]
            tot += min(1.0, meas / SPACING); cnt += 1
    return tot / cnt
if __name__ == "__main__":
    for path, label in [(a.split("=")[0], a.split("=")[1]) for a in sys.argv[1:]]:
        name, M = brace_points(path)
        ys = [y for pts in M for (_, _, y, _) in pts]
        lo = min(min(y for _, _, y, _ in pts) for pts in M); hi = max(min(y for _, _, y, _ in pts) for pts in M)
        print(f"{label:42s} underside over the ground: lowest {lo:.2f} cm, highest-lowest {hi:.2f}; "
              f"P(in a log) all {prob(M):.3f}, runs {prob(M, 'run'):.3f}, diagonal {prob(M, 'diag'):.3f}")
