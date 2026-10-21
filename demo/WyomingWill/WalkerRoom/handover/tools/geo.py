#!/usr/bin/env python3
# From sweep2/<name>.txt (body held still, one slow crank turn; x along the walk, cm):
#   stride   each foot's travel along the walk, mean over feet (target STRIDE 15)
#   lift     each foot's bottom, highest minus lowest, mean over feet
#   base     middle of the front feet's paths minus middle of the back feet's (target BASE 35)
#   offset   centre of mass (body 40 at its centre + every part), averaged over the turn,
#            minus the middle of the four feet's paths (balance.py's measure; target 0)
#   advance  how far it would go per crank turn with no slip: at each sample the lowest
#            foot stands, and the body moves as fast as that foot sweeps back
# python3 geo.py [name ...]   (no names: every sweep file)
import glob, sys, collections
from shapely.geometry import Polygon
def one(path):
    L, S = {}, collections.defaultdict(list)
    for l in open(path):
        if l.startswith("WALKER"): name = l.split("|")[0][7:]
        elif l.startswith("LINK"):
            f = l.strip().split("|"); i = int(f[0].split()[1])
            L[i] = dict(mass=float(f[2].split()[1]), kind=f[4].split()[1])
        elif l.startswith("S "):
            p = l.split(); S[int(p[1])].append([tuple(map(float, q.split(","))) for q in p[2].split(";")])
    feet = [i for i in L if L[i]["kind"] == "buildFoot"]
    n = min(len(S[i]) for i in L)
    cx = {i: [Polygon(S[i][k]).buffer(0).centroid.x for k in range(n)] for i in L}
    bot = {i: [min(y for _, y in S[i][k]) for k in range(n)] for i in feet}
    stride = sum(max(cx[i]) - min(cx[i]) for i in feet) / len(feet)
    lift = sum(max(bot[i]) - min(bot[i]) for i in feet) / len(feet)
    mids = sorted((min(cx[i]) + max(cx[i])) / 2 for i in feet)
    base = (mids[-1] + mids[-2]) / 2 - (mids[0] + mids[1]) / 2
    BODY = 40.0
    com = sum((sum(L[i]["mass"] * cx[i][k] for i in L)) / (BODY + sum(L[i]["mass"] for i in L)) for k in range(n)) / n
    offset = com - sum(mids) / len(mids)
    adv = 0.0
    for k in range(1, n):
        f = min(feet, key=lambda i: bot[i][k])
        adv += cx[f][k - 1] - cx[f][k]
    return name, stride, lift, base, offset, abs(adv)
if __name__ == "__main__":
  names = sys.argv[1:]
  files = [f"/home/claude/work/sweep2/{x.replace(' ', '_')}.txt" for x in names] if names else sorted(glob.glob("/home/claude/work/sweep2/*.txt"))
  for p in files:
    nm, s, l, b, o, a = one(p)
    print(f"{nm:32s} stride {s:6.2f}  lift {l:5.2f}  base {b:6.2f}  offset {o:+6.2f}  advance {a:6.2f}")
