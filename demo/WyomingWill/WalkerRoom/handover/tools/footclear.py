# Per walker: the closest any link of its own side comes to a foot (side view),
# and the closest two links in the same plane come -- from sweep2.
import glob, collections, math, sys
from shapely.geometry import Polygon
from shapely.ops import unary_union
def load(path):
    L, S, joins = {}, collections.defaultdict(list), []
    for l in open(path):
        if l.startswith("WALKER"): name = l.split("|")[0][7:]
        elif l.startswith("LINK"):
            f = l.strip().split("|"); i = int(f[0].split()[1])
            L[i] = dict(z=float(f[1].split()[1]), kind=f[4].split()[1])
        elif l.startswith("JOIN"): p = l.split(); joins.append((int(p[1]), int(p[2]), p[3]))
        elif l.startswith("S "):
            p = l.split(); S[int(p[1])].append(Polygon([tuple(map(float, q.split(","))) for q in p[2].split(";")]).buffer(0))
    return name, L, S, joins
out = {}
for path in sorted(glob.glob("/home/claude/work/sweep2/*.txt")):
    name, L, S, joins = load(path)
    comp = {i: i for i in L}
    def root(i):
        while comp[i] != i: i = comp[i]
        return i
    for a, b, k in joins: comp[root(a)] = root(b)
    joined = {frozenset((a, b)) for a, b, k in joins}
    sw = {i: unary_union(S[i]) for i in L}
    def dist(a, b):
        if root(a) == root(b): return min(S[a][k].distance(S[b][k]) for k in range(len(S[a])))
        return sw[a].distance(sw[b])
    feet = [i for i in L if L[i]["kind"] == "buildFoot"]
    links = [i for i in L if L[i]["kind"] != "buildFoot"]
    fmin = min(dist(f, l) for f in feet for l in links if (L[f]["z"] > 0) == (L[l]["z"] > 0) and frozenset((f, l)) not in joined)
    pmin = 99
    for a in links:
        for b in links:
            if a < b and abs(L[a]["z"] - L[b]["z"]) < 0.05 and frozenset((a, b)) not in joined:
                pmin = min(pmin, dist(a, b))
    planes = len({round(abs(L[i]["z"]), 2) for i in links})
    out[name] = (fmin, pmin, planes)
    print(f"{name:32s} planes {planes}  closest link to a foot {fmin:5.2f} cm  closest two links sharing a plane {pmin:5.2f} cm", flush=True)
