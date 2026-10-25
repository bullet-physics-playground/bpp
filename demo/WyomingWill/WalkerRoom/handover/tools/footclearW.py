# footclear.py's foot measure on two sweep sets: the closest any link (bars and triangles only) of its own side comes to
# a foot, seen from the side (same leg: same moment; other legs: anywhere they sweep), links joined to the foot left out.
import glob, collections, sys
from shapely.geometry import Polygon
from shapely.ops import unary_union
def one(path):
    L, S, joins = {}, collections.defaultdict(list), []
    for l in open(path):
        if l.startswith("WALKER"): name = l.split("|")[0][7:]
        elif l.startswith("LINK"):
            f = l.strip().split("|"); L[int(f[0].split()[1])] = dict(z=float(f[1].split()[1]), kind=f[4].split()[1])
        elif l.startswith("JOIN"): p = l.split(); joins.append((int(p[1]), int(p[2])))
        elif l.startswith("S "):
            p = l.split(); S[int(p[1])].append(Polygon([tuple(map(float, q.split(","))) for q in p[2].split(";")]).buffer(0))
    comp = {i: i for i in L}
    def root(i):
        while comp[i] != i: i = comp[i]
        return i
    for a, b in joins: comp[root(a)] = root(b)
    joined = {frozenset(j) for j in joins}
    feet = [i for i in L if L[i]["kind"] == "buildFoot"]
    links = [i for i in L if L[i]["kind"] in ("makeLink", "buildLinkage", "?")]
    best = (99, None)
    for f in feet:
        for l in links:
            if (L[f]["z"] > 0) != (L[l]["z"] > 0) or frozenset((f, l)) in joined: continue
            d = min(S[f][k].distance(S[l][k]) for k in range(len(S[f]))) if root(f) == root(l) else unary_union(S[f]).distance(unary_union(S[l]))
            if d < best[0]: best = (d, l)
    return name, best
A, B = sys.argv[1], sys.argv[2]
for p in sorted(glob.glob(f"/home/claude/work/{A}/*.txt")):
    n, a = one(p); _, b = one(p.replace(f"/{A}/", f"/{B}/"))
    print(f"{n:32s} closest link to a foot: {A} {a[0]:5.2f}  {B} {b[0]:5.2f}  change {b[0] - a[0]:+5.2f}")
