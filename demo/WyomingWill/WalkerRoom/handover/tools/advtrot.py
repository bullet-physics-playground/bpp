#!/usr/bin/env python3
# Advances in trot (24 October): from sweepT/ (sweepT.sh; three diag builds again with pendants free: nohold_*.txt),
# geo.py's advance scaled to exactly one crank turn (the sweep window's crank falls a little short of a turn).
import sys, math, glob, re
sys.path.insert(0, "/home/claude/work"); import geo, topz
def turned(path):
    name, L, S, bb, hz = topz.load(path)
    G = [int(l.split()[1]) for l in open(path) if l.startswith("GROUND") and "Hinge" in l]
    n = min(len(S[i]) for i in L); out = []
    for i in G:
        if L[i]["kind"] != "makeLink": continue
        tot, prev = 0, None
        for k in range(n):
            c = list(S[i][k].exterior.coords)
            e = max(((c[q], c[q + 1]) for q in range(len(c) - 1)), key=lambda e: math.dist(*e))
            a = math.degrees(math.atan2(e[1][1] - e[0][1], e[1][0] - e[0][0]))
            if prev is not None: tot += (a - prev + 90) % 180 - 90
            prev = a
        out.append(abs(tot))
    return max(t for t in out if t < 420)
for p in sorted(glob.glob("/home/claude/work/sweepT/*.txt")):
    nm, s, l, b, o, a = geo.one(p); t = turned(p)
    print(f"{p.split('/')[-1]:44s} {nm:32s} crank {t:5.1f} deg  advance per turn {a * 360 / t:6.2f}  stride {s:5.2f}  lift {l:4.2f}")
