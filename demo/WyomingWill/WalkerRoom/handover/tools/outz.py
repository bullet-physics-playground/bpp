#!/usr/bin/env python3
# "Outside" braces: a side run along x outside each of its pair's pendants (z = +-13.3), joined by one cross
# piece -- straight across (x1 = x2) or diagonal (x1 on the left side, x2 on the right) -- all at one height.
# The top one just over the body, the bottom one at the foot lift above its own feet. Checked through a whole
# crank turn (sweep4) against every link and foot (feet are 12 wide across: z +-6 about their plane) and the
# body, margin M; the brace moves with its pair's pendants (held, so a pure shift).
# Method: for every part and moment, the x places a short piece of brace (T wide, H tall, at the brace's height)
# can't be, mapped back to moment 0; a brace fits if no piece of it, where it passes through that part's
# z-slab, lands in a forbidden place.
import math, json, collections, sys
sys.path.insert(0, "/home/claude/work"); import topz
from shapely.geometry import box
M, H, T = 0.3, 1.074, 0.3
ZS = 13 + 0.15 + T / 2
def forbidden(W, d, own, yb, half):
    F = {}
    for i in list(W["links"]) + list(W["feet"]):
        if i in own: continue
        iv = []
        for k in range(W["n"]):
            dx, dy = d[k]
            band = box(-999, yb + dy - M, 999, yb + H + dy + M)
            q = W["S"][i][k].intersection(band)
            if q.is_empty: continue
            a, _, b, _ = q.bounds
            iv.append((a - dx - T / 2 - M, b - dx + T / 2 + M))
        iv.sort(); merged = []
        for a, b in iv:
            if merged and a <= merged[-1][1]: merged[-1][1] = max(merged[-1][1], b)
            else: merged.append([a, b])
        F[i] = (W["L"][i]["z"], half(i), merged)
    return F
def hits(F, segs):
    """segs: list of (x_at_zA, zA, x_at_zB, zB) straight pieces (a side run has zA == zB). Returns hit parts."""
    out = set()
    for i, (z, t, iv) in F.items():
        lo, hi = z - t - T / 2 - M, z + t + T / 2 + M
        for xa, za, xb, zb in segs:
            if za == zb:
                if not (lo < za < hi): continue
                u, v = min(xa, xb), max(xa, xb)
            else:
                z0, z1 = max(lo, min(za, zb)), min(hi, max(za, zb))
                if z0 >= z1: continue
                f = lambda zz: xa + (xb - xa) * (zz - za) / (zb - za)
                u, v = min(f(z0), f(z1)), max(f(z0), f(z1))
            if any(a < v and u < b for a, b in iv): out.add(i)
    return out
def brace(xp_left, xp_right, x1, x2):
    """side runs from each pendant (moment-0 x) to x1 (left, z>0) / x2 (right), cross piece x1 -> x2"""
    segs = [(xp_left, ZS, x1, ZS), (xp_right, -ZS, x2, -ZS), (x1, ZS, x2, -ZS) if x1 != x2 else (x1, ZS, x1, -ZS)]
    L = abs(xp_left - x1) + abs(xp_right - x2) + math.hypot(x1 - x2, 2 * ZS)
    return segs, L
def solve(W, pair, d, yb):
    half = lambda i: 6.0 if i in W["feet"] else 0.15
    F = forbidden(W, d, pair, yb, half)          # for the runs: welded to their own pendants
    Fx = forbidden(W, d, (), yb, half)           # for the cross piece: its own pendants too (it isn't welded to them)
    left = [i for i in pair if W["L"][i]["z"] > 0][0]; right = [i for i in pair if W["L"][i]["z"] < 0][0]
    xl, xr = W["S"][left][0].centroid.x, W["S"][right][0].centroid.x
    grid = [x / 4 for x in range(-120, 141)]
    ok = lambda segs: not hits(F, segs[:2]) and not hits(Fx, segs[2:])
    straight = [x for x in grid if ok(brace(xl, xr, x, x)[0])]
    best = None
    for x1 in grid:
        if hits(F, [(xl, ZS, x1, ZS)]): continue
        for x2 in grid:
            if hits(F, [(xr, -ZS, x2, -ZS)]): continue
            segs, L = brace(xl, xr, x1, x2)
            if best and L >= best[0]: continue
            if ok(segs): best = (L, x1, x2)
    return dict(xl=xl, xr=xr, straight=[min(straight), max(straight)] if straight else None,
                straightL=brace(xl, xr, (min(straight) + max(straight)) / 2, (min(straight) + max(straight)) / 2)[1] if straight else None,
                best=best, F=F)
if __name__ == "__main__":
    res = {}
    for b in ("Chebyshev-Spears_diag", "Hoecken-Spears_4-bar_diag"):
        W = topz.setup(b); r = res[b] = {}
        x0, x1b, y0, y1 = W["bb"]
        liftB = max(d[1] for d in W["dB"]) - min(d[1] for d in W["dB"])
        # top: lowest over the body
        # (over the body's top: its raised letters, look-only in the simulation but real on a machine -- their top, from boxprobe.lua)
        LETTERS = {"Chebyshev-Spears_diag": 1.45, "Hoecken-Spears_4-bar_diag": 1.50}
        ybT = max(y1, LETTERS[b]) + M - min(d[1] for d in W["dT"])
        # bottom: its bottom the foot lift + 0.2 above its own feet's bottoms (moment 0 is a stance moment for both pairs)
        bfeet = [i for i in W["feet"] if any(abs(W["S"][i][0].centroid.x - W["S"][p][0].centroid.x) < 1.5 and W["L"][i]["z"] == W["L"][p]["z"] for p in W["bot"])]
        fb = min(W["S"][i][0].bounds[1] for i in bfeet)
        ybB = fb + liftB + 0.2
        under = (y0 - M) - (ybB + H + max(d[1] for d in W["dB"]) - W["dB"][0][1])
        ybB += under; under = 0.0        # (raised as far as it goes: 0.3 cm under the body at its highest)
        print(f"\n== {W['name']}")
        for nm, pair, d, yb in (("top", W["top"], W["dT"], ybT), ("bottom", W["bot"], W["dB"], ybB)):
            s = solve(W, pair, d, yb)
            r[nm] = dict(yb=yb, xl=s["xl"], xr=s["xr"], straight=s["straight"], straightL=s["straightL"], best=s["best"])
            st = f"straight across fits for x {s['straight'][0]:.2f}..{s['straight'][1]:.2f} ({s['straightL']:.1f} cm of bar)" if s["straight"] else "straight across: no place"
            bs = f"shortest diagonal: left end x {s['best'][1]:.2f}, right end x {s['best'][2]:.2f}, {s['best'][0]:.1f} cm of bar" if s["best"] else "no diagonal fits"
            extra = f"  (under the body by {under:.2f} at its highest)" if nm == "bottom" else f"  (bottom {yb:.2f}; body top {y1:.2f})"
            print(f"  {nm:6s} pendants at x {s['xl']:.2f} (left) / {s['xr']:.2f} (right) at moment 0{extra}\n         {st}\n         {bs}")
    json.dump(res, open("/home/claude/work/outz.json", "w"), indent=1)
