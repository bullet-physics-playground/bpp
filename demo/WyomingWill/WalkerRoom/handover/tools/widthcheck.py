#!/usr/bin/env python3
# Pre-pass for one link width for every walker: from trot sweeps (sweepT/; three diag builds from their free-pendant
# sweeps), every pair of bars in the same plane that no joint joins: the least distance between their centre lines over
# the crank turn. Bars of width w (each w/2 either side of its line) then clear each other by (that distance - w).
# Bars only (Cubes: rectangles); Jansen's and Klann's triangles and the feet keep their shapes (a triangle against a
# bar: the triangle's outline against the bar's line, so the gap is (that distance - w/2)).
import sys, math, collections, glob
sys.path.insert(0, "/home/claude/work")
from shapely.geometry import LineString, Polygon
FILES = {"Chebyshev-Spears diag": "nohold_CS", "Hoecken-Spears 4-bar diag": "nohold_HS4", "Hoecken-Spears 4-bar duty 85 diag": "nohold_HSLS"}
def load(path):
    L, S, J = {}, collections.defaultdict(list), set()
    for l in open(path):
        if l.startswith("WALKER"): name = l.split("|")[0][7:]
        elif l.startswith("LINK"):
            f = l.strip().split("|"); i = int(f[0].split()[1])
            L[i] = dict(z=round(float(f[1].split()[1]), 2), kind=f[4].split()[1], n=len(f[3].split()[1].split(";")))
        elif l.startswith("S "):
            p = l.split(); S[int(p[1])].append([tuple(map(float, q.split(","))) for q in p[2].split(";")])
        elif l.startswith("JOIN"):
            p = l.split(); J.add(frozenset((int(p[1]), int(p[2]))))
    return name, L, S, J
def centre(c):   # a rectangle's centre line: the midpoints of its two short sides
    e = [(c[i], c[(i + 1) % 4]) for i in range(4)]
    short = sorted(e, key=lambda s: math.dist(*s))[:2]
    m = [((a[0] + b[0]) / 2, (a[1] + b[1]) / 2) for a, b in short]
    return LineString(m), min(math.dist(*s) for s in e)
def check(path):
    name, L, S, J = load(path)
    n = min(len(S[i]) for i in L)
    bars = [i for i in L if L[i]["kind"] in ("makeLink", "buildLinkage") and L[i]["n"] == 4]
    tris = [i for i in L if L[i]["kind"] in ("makeLink", "buildLinkage") and L[i]["n"] != 4]
    width = {i: centre(S[i][0])[1] for i in bars}
    out = []
    for a in bars + tris:
        for b in bars:
            if a >= b and a in bars or a == b: continue
            if L[a]["z"] != L[b]["z"] or frozenset((a, b)) in J: continue
            dmin, now = 1e9, 1e9
            for k in range(n):
                lb = centre(S[b][k])[0]
                ga = centre(S[a][k])[0] if a in bars else Polygon(S[a][k]).buffer(0)
                dmin = min(dmin, ga.distance(lb))
                now = min(now, Polygon(S[a][k]).buffer(0).distance(Polygon(S[b][k]).buffer(0)))
            out.append((dmin, now, a, b, a in tris))
    return name, out, width, n
if __name__ == "__main__":
    W = float(sys.argv[1]) if len(sys.argv) > 1 else 1.0
    files = sorted(glob.glob("/home/claude/work/sweepT/*.txt"))
    files = [f for f in files if "nohold" not in f]
    for f in files:
        name, out, width, n = check(f)
        if name in FILES: name, out, width, n = check(f"/home/claude/work/sweepT/{FILES[name]}.txt")
        if not out: print(f"{name:32s} no two bars share a plane unjoined"); continue
        # the tightest pair at width W, and the widest every bar could be with a 0.2 cm gap
        g = [(d - (W / 2 if tri else W), now, a, b) for d, now, a, b, tri in out]
        worst = min(g)
        wmax = min((d - 0.2) * (2 if tri else 1) for d, now, a, b, tri in out)
        nowmin = min(now for d, now, a, b, tri in out)
        print(f"{name:32s} {len(out):3d} same-plane pairs; closest now {nowmin:5.2f} cm; at width {W:.2f}: closest {worst[0]:+5.2f} cm (links {worst[2]}-{worst[3]}); widest for 0.2 cm everywhere: {wmax:5.2f} cm; bars now {min(width.values()):.2f}-{max(width.values()):.2f}")
