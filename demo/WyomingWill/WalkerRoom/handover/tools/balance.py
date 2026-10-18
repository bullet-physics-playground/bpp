# Front-to-back balance: whole walker's centre of mass (body 40 at its centre, links,
# feet; braces left out) averaged over a crank turn, against the middle of the four
# feet's paths. From sweep2 (body held still; x along the walk, relative to the body).
import glob, collections
from shapely.geometry import Polygon
rows = []
for path in sorted(glob.glob("/home/claude/work/sweep2/*.txt")):
    L, S = {}, collections.defaultdict(list)
    for l in open(path):
        if l.startswith("WALKER"): name = l.split("|")[0][7:]
        elif l.startswith("LINK"):
            f = l.strip().split("|"); i = int(f[0].split()[1])
            L[i] = dict(mass=float(f[2].split()[1]), kind=f[4].split()[1])
        elif l.startswith("S "):
            p = l.split(); S[int(p[1])].append(Polygon([tuple(map(float, q.split(","))) for q in p[2].split(";")]).buffer(0).centroid.x)
    n = len(next(iter(S.values())))
    BODY = 40.0
    com = []
    for k in range(n):
        m = BODY; mx = 0.0
        for i, d in L.items(): m += d["mass"]; mx += d["mass"] * S[i][k]
        com.append(mx / m)
    com = sum(com) / n
    feet = [i for i in L if L[i]["kind"] == "buildFoot"]
    mids = sorted((min(S[i]) + max(S[i])) / 2 for i in feet)
    support = sum(mids) / len(mids)
    base = (mids[-1] + mids[-2]) / 2 - (mids[0] + mids[1]) / 2
    mt = BODY + sum(d["mass"] for d in L.values())
    rows.append((name, com - support, -support, base, mt))
    print(f"{name:32s} whole walker's centre of mass {com - support:+5.2f} cm from the middle of its support; body centre {-support:+5.2f} cm; feet path middles {[round(x,1) for x in mids]} (base {base:.1f})")

import json
json.dump({r[0]: {"offset": r[1], "mtot": r[4]} for r in rows}, open("/home/claude/work/balance.json", "w"), indent=1)
