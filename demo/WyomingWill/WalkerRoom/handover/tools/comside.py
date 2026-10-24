#!/usr/bin/env python3
# Walking in the air (sweep5: body held, cranks turned slowly, trot): the whole walker's centre of mass,
# across the walk (z), and how far it sits to either side of the diagonal line through the standing feet.
import collections, statistics as st
from shapely.geometry import Polygon
def load(p):
    L, S = {}, collections.defaultdict(list)
    for l in open(p):
        if l.startswith("LINK"):
            f = l.strip().split("|"); L[int(f[0].split()[1])] = dict(z=float(f[1].split()[1]), m=float(f[2].split()[1]), kind=f[4].split()[1])
        elif l.startswith("S "):
            q = l.split(); S[int(q[1])].append(Polygon([tuple(map(float, a.split(","))) for a in q[2].split(";")]).buffer(0))
    return L, S
BODY = 40.0
for b in ("Chebyshev-Spears_diag", "Chebyshev-Spears", "Hoecken-Spears_4-bar_diag", "Hoecken-Spears_4-bar"):
    L, S = load(f"/home/claude/work/sweep5/{b}.txt")
    n = min(len(S[i]) for i in L)
    feet = [i for i in L if L[i]["kind"] == "buildFoot"]
    M = BODY + sum(L[i]["m"] for i in L)
    zc = sum(L[i]["m"] * L[i]["z"] for i in L) / M
    side, lat = [], []
    left_m = sum(L[i]["m"] for i in L if L[i]["z"] > 0.01); right_m = sum(L[i]["m"] for i in L if L[i]["z"] < -0.01)
    for k in range(n):
        xc = sum(L[i]["m"] * S[i][k].centroid.x for i in L) / M
        bot = {i: S[i][k].bounds[1] for i in feet}
        low = sorted(feet, key=lambda i: bot[i])[:2]          # the two lowest feet stand
        (x1, z1), (x2, z2) = [(S[i][k].centroid.x, L[i]["z"]) for i in low]
        if z1 * z2 > 0 or abs(x2 - x1) < 15: continue                               # (not a diagonal pair this moment)
        # signed distance of (xc, zc) from the line through the two feet, + toward +z
        dx, dz = x2 - x1, z2 - z1
        d = ((xc - x1) * dz - (zc - z1) * dx) / (dx * dx + dz * dz) ** 0.5
        if dx * 1 < 0: d = -d                                  # (sign: + means toward +z of the line, whatever its order)
        zl = z1 + (z2 - z1) * (xc - x1) / dx if dx else z1     # the line's z at the CoM's x
        lat.append(zc - zl)
    print(f"{b:28s} CoM z {zc:+.3f} cm (left {left_m:.2f}, right {right_m:.2f})  CoM minus stance line's z at the CoM: mean {st.mean(lat):+.2f} cm, median {st.median(lat):+.2f}, over the turn {min(lat):+.2f}..{max(lat):+.2f} ({len(lat)} moments)")
