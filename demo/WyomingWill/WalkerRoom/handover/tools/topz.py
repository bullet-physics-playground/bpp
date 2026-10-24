#!/usr/bin/env python3
# Brace shapes for the diag builds, checked against everything they could hit through a whole crank turn.
# From sweep4/<build>.txt (body held still, one crank turn; body frame: x along the walk, y up, z across;
# every link's outline per moment, its plane z; the body's box). Each brace is welded to its pair's two
# pendants (held at their angle), so it moves with them: a pure shift, the same for both.
#   top Z   (top pair FL+BR): a side run along x outside each pendant (z = +-13.3), from the pendant to x_c,
#           and a cross piece across at x_c, all at one height, just over the body. Pendants at guides' length.
#   top V   (top pair): straight arms from each pendant's top (where the straight brace is welded now)
#           down to a low middle over the body, (x_m, y_m, 0). Pendants extended as now.
#   bottom Z (bottom pair BL+FR): across from each pendant to the middle, along the middle; the room's
#           DIAG_LOW build, bottom at the foot lift above the feet's bottoms.
#   bottom straight (bottom pair): one bar from pendant to pendant at the same height.
# Bars 1.074 tall, 0.3 thick (the room's brace bar); margin M to anything.
import math, sys, collections
from shapely.geometry import Polygon, box
M, H, T = 0.3, 1.074, 0.3
def load(path):
    L, S = {}, collections.defaultdict(list)
    for l in open(path):
        if l.startswith("WALKER"):
            f = l.strip().split("|"); name = f[0][7:]
            bb = [float(x) for x in f[3].split()[1:]]
            hz = float(f[2].split()[1])
        elif l.startswith("LINK"):
            f = l.strip().split("|"); L[int(f[0].split()[1])] = dict(z=float(f[1].split()[1]), m=float(f[2].split()[1]), kind=f[4].split()[1])
        elif l.startswith("S "):
            p = l.split(); S[int(p[1])].append(Polygon([tuple(map(float, q.split(","))) for q in p[2].split(";")]).buffer(0))
    return name, L, S, bb, hz
def setup(b):
    name, L, S, bb, hz = load(f"/home/claude/work/sweep4/{b}.txt")
    n = min(len(S[i]) for i in L)
    pend = [i for i in L if L[i]["kind"] == "makeLink" and abs(abs(L[i]["z"]) - 13) < 0.05]
    feet = [i for i in L if L[i]["kind"] == "buildFoot"]
    braces = [i for i in L if "Crossbar" in L[i]["kind"]]
    cx = {i: S[i][0].centroid.x for i in pend}
    side = lambda i: (1 if cx[i] > -2 else -1) * (1 if L[i]["z"] > 0 else -1)
    top = [i for i in pend if side(i) > 0]; bot = [i for i in pend if side(i) < 0]
    def shift(pair):
        r = pair[0]
        return [(S[r][k].centroid.x - S[r][0].centroid.x, S[r][k].centroid.y - S[r][0].centroid.y) for k in range(n)]
    links = [i for i in L if i not in feet and i not in braces]
    footBottom0 = min(S[i][0].bounds[1] for i in feet)
    return dict(name=name, L=L, S=S, n=n, bb=bb, hz=hz, top=top, bot=bot, dT=shift(top), dB=shift(bot), links=links, feet=feet, fb0=footBottom0)
def pieces_hit(W, pieces, d, own, skip_self_planes=()):
    """pieces: list of (zlo, zhi, polygon-in-xy at moment 0). Returns list of (link, moment, gap) hits within M."""
    hits = []
    for k in range(W["n"]):
        dx, dy = d[k]
        for zlo, zhi, poly in pieces:
            from shapely import affinity
            p = affinity.translate(poly, dx, dy)
            for i in W["links"]:
                if i in own: continue
                z = W["L"][i]["z"]
                if z + 0.15 + M <= zlo or z - 0.15 - M >= zhi: continue
                g = p.distance(W["S"][i][k])
                if g < M: hits.append((i, k, g))
    return hits
def body_gap(W, pieces, d):
    """smallest gap between the pieces (where over the body: |z| < body half width) and the body's top or bottom"""
    x0, x1, y0, y1 = W["bb"]
    worst = 1e9
    for k in range(W["n"]):
        dx, dy = d[k]
        for zlo, zhi, poly in pieces:
            if zhi <= -W["hz"] or zlo >= W["hz"]: continue
            a, b, c, e = poly.bounds
            if c + dx < x0 or a + dx > x1: continue
            worst = min(worst, (b + dy) - y1 if b + dy > 0 else y0 - (e + dy))
    return worst
# ---------- top Z ----------
def topZ(W, xc, yb):
    fl = [i for i in W["top"] if W["L"][i]["z"] > 0][0]; br = [i for i in W["top"] if W["L"][i]["z"] < 0][0]
    xf, xb = W["S"][fl][0].centroid.x, W["S"][br][0].centroid.x
    zs = 13 + 0.15 + T / 2
    run = lambda xa, xb_: box(min(xa, xb_), yb, max(xa, xb_), yb + H)
    return [(zs - T / 2, zs + T / 2, run(xf, xc)), (-zs - T / 2, -zs + T / 2, run(xb, xc)), (-zs - T / 2, zs + T / 2, box(xc - T / 2, yb, xc + T / 2, yb + H))], (abs(xf - xc) + abs(xb - xc) + 2 * zs)
def topV(W, xm, ym, ye):
    fl = [i for i in W["top"] if W["L"][i]["z"] > 0][0]; br = [i for i in W["top"] if W["L"][i]["z"] < 0][0]
    xf, xb = W["S"][fl][0].centroid.x, W["S"][br][0].centroid.x
    out, length = [], 0
    for (xa, za) in ((xf, 13.0), (xb, -13.0)):
        length += math.dist((xa, ye, za), (xm, ym, 0))
        N = 60
        for s in range(N):   # thin slices along the arm (each a short box in its own z range)
            t0, t1 = s / N, (s + 1) / N
            P = lambda t: (xa + (xm - xa) * t, ye + (ym - ye) * t, za * (1 - t))
            p0, p1 = P(t0), P(t1)
            out.append((min(p0[2], p1[2]) - T / 2, max(p0[2], p1[2]) + T / 2,
                        box(min(p0[0], p1[0]) - T / 2, min(p0[1], p1[1]) - H / 2, max(p0[0], p1[0]) + T / 2, max(p0[1], p1[1]) + H / 2)))
    return out, length
def lowZ(W, yb):
    bl = [i for i in W["bot"] if W["L"][i]["z"] > 0][0]; fr = [i for i in W["bot"] if W["L"][i]["z"] < 0][0]
    xl, xr = W["S"][bl][0].centroid.x, W["S"][fr][0].centroid.x
    zp = 13 - 0.15
    return [(0, zp, box(xl - T / 2, yb, xl + T / 2, yb + H)), (-zp, 0, box(xr - T / 2, yb, xr + T / 2, yb + H)), (-T / 2, T / 2, box(min(xl, xr), yb, max(xl, xr), yb + H))], 2 * 13 + abs(xl - xr)
def lowStraight(W, yb):
    bl = [i for i in W["bot"] if W["L"][i]["z"] > 0][0]; fr = [i for i in W["bot"] if W["L"][i]["z"] < 0][0]
    xl, xr = W["S"][bl][0].centroid.x, W["S"][fr][0].centroid.x
    out = []; N = 80; zp = 13 - 0.15
    for s in range(N):
        t0, t1 = s / N, (s + 1) / N
        x0, x1 = xl + (xr - xl) * t0, xl + (xr - xl) * t1
        z0, z1 = zp - 2 * zp * t0, zp - 2 * zp * t1
        out.append((min(z0, z1) - T / 2, max(z0, z1) + T / 2, box(min(x0, x1) - T / 2, yb, max(x0, x1) + T / 2, yb + H)))
    return out, math.hypot(xl - xr, 2 * zp)
if __name__ == "__main__":
    import json
    res = {}
    for b in ("Chebyshev-Spears_diag", "Hoecken-Spears_4-bar_diag"):
        W = setup(b); r = res[b] = {}
        lift = max(d[1] for d in W["dB"]) - min(d[1] for d in W["dB"])
        bodyTop = W["bb"][3]
        print(f"\n== {W['name']}  body top {bodyTop:.2f}, body x {W['bb'][0]:.2f}..{W['bb'][1]:.2f}; top pair links {W['top']}, bottom pair {W['bot']}; foot lift {lift:.2f}")
        # trimmed pendant top at moment 0 (guides' length 18.656 cm x scale ratio: guides pendant half 9.328 at CS scale)
        pl = 2 * 9.328 * (1 if "Chebyshev" in b else 1.49417 / 1.43205)
        pbot = min(W["S"][i][0].bounds[1] for i in W["top"])
        ptop = pbot + pl
        mindy = min(d[1] for d in W["dT"])
        ylo = bodyTop + M - mindy
        print(f"  top Z: lowest height (moment 0, its bottom) {ylo:.2f}; trimmed pendant top {ptop:.2f}: room for the side runs on it {ptop - ylo - H:+.2f}")
        best = None
        for yb in [ylo + 0.1 * j for j in range(0, 40)]:
            ok = []
            for xc10 in range(-120, 160, 2):
                xc = xc10 / 10
                P, length = topZ(W, xc, yb)
                h = pieces_hit(W, P, W["dT"], W["top"])
                if not h and body_gap(W, P, W["dT"]) >= M: ok.append(xc)
            if ok:
                best = (yb, ok, length); break
        if best:
            yb, ok, _ = best
            xc = (min(ok) + max(ok)) / 2
            P, length = topZ(W, xc, yb)
            r["topZ"] = dict(xc=xc, yb=yb, length=length, window=[min(ok), max(ok)], ptop=ptop)
            print(f"  top Z FITS: bottom at {yb:.2f} (body top {bodyTop:.2f}), cross piece anywhere x {min(ok):.1f}..{max(ok):.1f} -> at {xc:.1f}; bar {length:.1f} cm; on the trimmed pendant: {'yes' if yb + H <= ptop else 'NO, needs ' + format(yb + H - ptop, '.2f') + ' cm more pendant'}")
        else:
            print("  top Z: no clear place found")
        # top V: ends where the straight brace is welded now (its centre height at moment 0)
        ye = None
        for i in W["L"]:
            if W["L"][i]["kind"] == "buildDiagonalCrossbar": ye = W["S"][i][0].centroid.y
        for xm in (None,):
            pass
        fl = [i for i in W["top"] if W["L"][i]["z"] > 0][0]; brr = [i for i in W["top"] if W["L"][i]["z"] < 0][0]
        xm = (W["S"][fl][0].centroid.x + W["S"][brr][0].centroid.x) / 2
        found = None
        for j in range(0, 200):
            ym = (bodyTop + M - mindy + H / 2) + 0.05 * j
            if ym > ye: break
            P, length = topV(W, xm, ym, ye)
            h = pieces_hit(W, P, W["dT"], W["top"])
            if not h and body_gap(W, P, W["dT"]) >= M - 1e-6: found = (ym, length); break
        if found:
            r["topV"] = dict(xm=xm, ym=found[0], ye=ye, length=found[1])
            print(f"  top V FITS: ends at {ye:.2f} (as now), middle (centre) down to {found[0]:.2f} at x {xm:.1f}; bar {found[1]:.1f} cm")
        else:
            print("  top V: middle can't come down (arms hit)")
        # bottom: its bottom at the foot lift + M above the feet's bottoms (moment 0 is a stance moment for the bottom pair?)
        pb = min(W["S"][i][0].bounds[1] for i in W["feet"] if i in [])  if False else None
        # the bottom pair's feet at moment 0
        bfeet = [i for i in W["feet"] if any(abs(W["S"][i][0].centroid.x - W["S"][p][0].centroid.x) < 1 and W["L"][i]["z"] == W["L"][p]["z"] for p in W["bot"])]
        fb = min(W["S"][i][0].bounds[1] for i in bfeet)
        dyb = W["dB"][0][1] - min(d[1] for d in W["dB"])     # how far above its lowest the pair is at moment 0
        yb = fb + lift + 0.2
        for nm, fn in (("bottom Z", lowZ), ("bottom straight", lowStraight)):
            P, length = fn(W, yb)
            h = pieces_hit(W, P, W["dB"], W["bot"])
            bg = body_gap(W, P, W["dB"])
            worst = min((g for _, _, g in h), default=None)
            cnt = collections.Counter(i for i, _, _ in h)
            r[nm] = dict(yb=yb, length=length, hits=len(h))
            print(f"  {nm}: bottom {yb - fb:.2f} above its feet's bottoms, bar {length:.1f} cm, under the body by {bg:.2f}; " + (f"within {M} cm of links {dict(cnt)} in {len(set(k for _, k, _ in h))} of {W['n']} moments, closest {worst:.2f}" if h else "clear of every link"))
    json.dump(res, open("/home/claude/work/topz.json", "w"), indent=1)
