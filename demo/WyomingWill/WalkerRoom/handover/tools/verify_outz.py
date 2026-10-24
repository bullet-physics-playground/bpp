# Direct check of outz.py's fits: the brace cut into thin slices, every slice against every link and foot, every moment.
import json, math, topz, outz
from shapely.geometry import box
from shapely import affinity
R = json.load(open("/home/claude/work/outz.json"))
M, H, T, ZS = outz.M, outz.H, outz.T, outz.ZS
def slices(segs, yb, N=120):
    out = []
    for xa, za, xb, zb in segs:
        for s in range(N):
            t0, t1 = s / N, (s + 1) / N
            x0, x1 = xa + (xb - xa) * t0, xa + (xb - xa) * t1
            z0, z1 = za + (zb - za) * t0, za + (zb - za) * t1
            out.append((min(z0, z1) - T / 2, max(z0, z1) + T / 2, box(min(x0, x1) - T / 2, yb, max(x0, x1) + T / 2, yb + H)))
    return out
for b in R:
    W = topz.setup(b)
    for nm, pair, d in (("top", W["top"], W["dT"]), ("bottom", W["bot"], W["dB"])):
        r = R[b][nm]
        for kind in ("straight", "diagonal"):
            if kind == "straight": x1 = x2 = sum(r["straight"]) / 2
            else: _, x1, x2 = r["best"]
            segs, L = outz.brace(r["xl"], r["xr"], x1, x2)
            P = slices(segs, r["yb"])
            worst, who = 99, None
            for k in range(W["n"]):
                dx, dy = d[k]
                for zlo, zhi, poly in P:
                    p = affinity.translate(poly, dx, dy)
                    for i in list(W["links"]) + list(W["feet"]):
                        if i in pair and zhi - zlo < 0.31 + 1e-9 and abs(abs(zlo + T / 2) - ZS) < 1e-6: continue   # (a run slice, welded to its own pendant)
                        t = 6.0 if i in W["feet"] else 0.15
                        z = W["L"][i]["z"]
                        if z + t <= zlo or z - t >= zhi: continue
                        g = p.distance(W["S"][i][k])
                        if g < worst: worst, who = g, (i, W["L"][i]["kind"], k)
            bg = topz.body_gap(W, P, d)
            print(f"{b[:16]:16s} {nm:6s} {kind:8s} x1 {x1:6.2f} x2 {x2:6.2f}  {L:5.1f} cm  closest part {worst:5.2f} cm {who}  body gap {bg:.2f}")
