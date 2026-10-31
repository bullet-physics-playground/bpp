#!/usr/bin/env python3
# Each build's lift as a share of its stride, from sweeps (body held still, one slow crank turn, trot):
#   stride  each foot's centre's travel along the walk, mean over the feet
#   lift    each foot's lowest point, highest minus lowest over the turn, mean over the feet
# python3 liftpct.py <sweep dir>
import glob, sys, collections, os
from shapely.geometry import Polygon
def one(path):
    L, S = {}, collections.defaultdict(list); name = os.path.basename(path)
    for l in open(path):
        if l.startswith("WALKER"): name = l.split("|")[0][7:]
        elif l.startswith("LINK"):
            f = l.strip().split("|"); L[int(f[0].split()[1])] = f[4].split()[1]
        elif l.startswith("S "):
            p = l.split(); S[int(p[1])].append([tuple(map(float, q.split(","))) for q in p[2].split(";")])
    feet = [i for i in L if L[i] == "buildFoot"]
    n = min(len(S[i]) for i in feet)
    cx = {i: [Polygon(S[i][k]).buffer(0).centroid.x for k in range(n)] for i in feet}
    bot = {i: [min(y for _, y in S[i][k]) for k in range(n)] for i in feet}
    stride = sum(max(cx[i]) - min(cx[i]) for i in feet) / len(feet)
    lift = sum(max(bot[i]) - min(bot[i]) for i in feet) / len(feet)
    return name, stride, lift, n
rows = [one(f) for f in sorted(glob.glob(os.path.join(sys.argv[1], "*.txt")))]
for name, s, l, n in sorted(rows, key=lambda r: -r[2] / r[1]):
    print(f"{name:34s} stride {s:6.2f}  lift {l:5.2f}  lift/stride {100 * l / s:5.1f}%  ({n} samples)")
