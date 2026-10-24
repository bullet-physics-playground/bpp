#!/usr/bin/env python3
# Outside braces for every diag build: outz.py's fit (and its rules) generalised from CS and HS4 to all seven.
# Sweeps from sweep5.sh (sweep4/<build>.txt: body held, one crank turn, pendants at guides' length and held).
# Pairs read from the joins: top = the pair welded to the build's top brace (linkages 2-3), bottom = linkages 1-4.
# Rules, as outz.py: top brace's bottom 0.3 over the body's top or its raised letters at its lowest; bottom brace
# as high as it goes, 0.3 under the body at its highest; runs outside the pendants (z = +-13.3), the shortest
# diagonal between them that clears every link and foot (12 wide) by 0.3 through the whole turn.
# Writes outz5.json and prints the OUTSIDE_FIT entries (yRel above the front pendant's lower end; runs from
# each pendant toward the other, front = the end it walks toward, +x here).
import json, math, collections, sys
sys.path.insert(0, "/home/claude/work")
import topz, outz
M, H, T, ZS = outz.M, outz.H, outz.T, outz.ZS
BUILDS = ["Chebyshev-Spears_diag", "Hoecken-Spears_4-bar_diag", "Chebyshev_diag", "Hoecken_4-bar_diag",
          "Hoecken-Spears_long-stance_diag", "Spears_lift_44_diag", "Spears_lift_53_diag"]
LETTERS = {"Chebyshev-Spears_diag": 1.45, "Hoecken-Spears_4-bar_diag": 1.50, "Chebyshev_diag": 2.77, "Hoecken_4-bar_diag": 2.85,
           "Hoecken-Spears_long-stance_diag": 1.72, "Spears_lift_44_diag": 2.00, "Spears_lift_53_diag": 2.31}
SWEEPS = "sweep4"
def setup(b):
    path = f"/home/claude/work/{SWEEPS}/{b}.txt"
    name, L, S, bb, hz = topz.load(path)
    joins = [l.split() for l in open(path) if l.startswith("JOIN")]
    n = min(len(S[i]) for i in L)
    feet = [i for i in L if L[i]["kind"] == "buildFoot"]
    braces = [i for i in L if "Crossbar" in L[i]["kind"]]
    welded = collections.defaultdict(set)      # brace kind (or height group) -> pendants welded to it
    for j in joins:
        a, c = int(j[1]), int(j[2])
        for x, y in ((a, c), (c, a)):
            if x in braces and L[y]["kind"] == "makeLink":
                k = L[x]["kind"]
                if k == "buildOutsideCrossbar": k = "top" if S[x][0].centroid.y > -2 else "bottom"
                welded[{"buildDiagonalCrossbar": "top", "buildArchedCrossbar": "bottom"}.get(k, k)].add(y)
    top, bot = sorted(welded["top"]), sorted(welded["bottom"])
    assert len(top) == 2 and len(bot) == 2, (b, dict(welded))
    def shift(pair):
        r = pair[0]
        return [(S[r][k].centroid.x - S[r][0].centroid.x, S[r][k].centroid.y - S[r][0].centroid.y) for k in range(n)]
    links = [i for i in L if i not in feet and i not in braces]
    return dict(name=name, L=L, S=S, n=n, bb=bb, hz=hz, top=top, bot=bot, dT=shift(top), dB=shift(bot), links=links,
                feet=feet, fb0=min(S[i][0].bounds[1] for i in feet))
def checks(W):
    """pendants: length, and how far each turns and how far the two of a pair part through the turn (0 = a pure shift)"""
    out = {}
    for nm, pair in (("top", W["top"]), ("bottom", W["bot"])):
        ang, part = 0, 0
        for i in pair:
            for k in range(W["n"]):
                c = list(W["S"][i][k].exterior.coords)
                # longest edge direction
                e = max(((c[q], c[q + 1]) for q in range(len(c) - 1)), key=lambda e: math.dist(*e))
                a = math.degrees(math.atan2(e[1][1] - e[0][1], e[1][0] - e[0][0])) % 180
                if k == 0: a0 = a
                ang = max(ang, abs((a - a0 + 90) % 180 - 90))
        i, j = pair
        for k in range(W["n"]):
            dxi = W["S"][i][k].centroid.x - W["S"][i][0].centroid.x; dyi = W["S"][i][k].centroid.y - W["S"][i][0].centroid.y
            dxj = W["S"][j][k].centroid.x - W["S"][j][0].centroid.x; dyj = W["S"][j][k].centroid.y - W["S"][j][0].centroid.y
            part = max(part, math.hypot(dxi - dxj, dyi - dyj))
        b0 = W["S"][pair[0]][0].bounds
        out[nm] = dict(turn=ang, part=part, length=b0[3] - b0[1], bottom=b0[1], top=b0[3])
    return out
def fit(b):
    W = setup(b); r = {"checks": checks(W)}
    x0, x1b, y0, y1 = W["bb"]
    liftB = max(d[1] for d in W["dB"]) - min(d[1] for d in W["dB"])
    liftT = max(d[1] for d in W["dT"]) - min(d[1] for d in W["dT"])
    ybT = max(y1, LETTERS[b]) + M - min(d[1] for d in W["dT"])
    ybB = (y0 - M) - (H + max(d[1] for d in W["dB"]) - W["dB"][0][1])
    r["lift"] = dict(top=liftT, bottom=liftB)
    for nm, pair, d, yb in (("top", W["top"], W["dT"], ybT), ("bottom", W["bot"], W["dB"], ybB)):
        s = outz.solve(W, pair, d, yb)
        bfeet = [i for i in W["feet"] if any(abs(W["S"][i][0].centroid.x - W["S"][p][0].centroid.x) < 1.5 and W["L"][i]["z"] == W["L"][p]["z"] for p in pair)]
        fb = min(W["S"][i][0].bounds[1] for i in bfeet)
        low = d[0][1] - min(q[1] for q in d)            # how far over its lowest the pair is at moment 0
        left = [i for i in pair if W["L"][i]["z"] > 0][0]; right = [i for i in pair if W["L"][i]["z"] < 0][0]
        pl, pr = W["S"][left][0].bounds[1], W["S"][right][0].bounds[1]
        e = dict(yb=yb, xl=s["xl"], xr=s["xr"], straight=s["straight"], straightL=s["straightL"], best=s["best"],
                 above_feet_stance=yb - low - (fb - low), feet_bottom=fb, pend_low=(pl, pr), pend_top=(W["S"][left][0].bounds[3], W["S"][right][0].bounds[3]))
        if s["best"]:
            L, xa, xb = s["best"]
            front_left = s["xl"] > s["xr"]                # front: the larger x (the way the track walks)
            xf, xfe, xbk, xbe = (s["xl"], xa, s["xr"], xb) if front_left else (s["xr"], xb, s["xl"], xa)
            e["runFront"], e["runBack"] = abs(xfe - xf), abs(xbe - xbk)
            e["toward"] = ((xfe - xf) * (xbk - xf) >= 0 or abs(xfe - xf) < 1e-9) and ((xbe - xbk) * (xf - xbk) >= 0 or abs(xbe - xbk) < 1e-9)
            e["yRel"] = yb - (pl if front_left else pr)
        r[nm] = e
    return W, r
if __name__ == "__main__":
    # options: --sweeps DIR (sweep6: with the outside braces built), --links M (margin to links and feet, cm; 0.3)
    args = sys.argv[1:]
    if "--sweeps" in args: i = args.index("--sweeps"); SWEEPS = args[i + 1]; del args[i:i + 2]
    if "--links" in args: i = args.index("--links"); outz.M = float(args[i + 1]); del args[i:i + 2]
    only = args or BUILDS
    res = {}
    for b in only:
        W, r = fit(b); res[b] = r
        c = r["checks"]
        print(f"\n== {W['name']}: body y {W['bb'][2]:.2f}..{W['bb'][3]:.2f}, letters {LETTERS[b]:.2f}; lift top pair {r['lift']['top']:.2f}, bottom {r['lift']['bottom']:.2f}")
        for nm in ("top", "bottom"):
            e = r[nm]; k = c[nm]
            print(f"  {nm:6s} pendants {k['length']:.2f} long, turn {k['turn']:.2f} deg, part {k['part']:.3f} cm; brace bottom {e['yb']:.2f} (pendant {e['pend_low'][0]:.2f}..{e['pend_top'][0]:.2f})")
            if e["best"]:
                print(f"         shortest diagonal {e['best'][0]:.1f} cm: yRel {e['yRel']:.2f}, runFront {e['runFront']:.2f}, runBack {e['runBack']:.2f}, runs toward each other: {e['toward']}")
            else:
                print("         NO diagonal fits")
            print(f"         straight across: {e['straight']}")
    json.dump(res, open(f"/home/claude/work/outz5_{SWEEPS}_{outz.M}.json", "w"), indent=1, default=str)
