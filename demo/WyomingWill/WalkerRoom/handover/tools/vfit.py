#!/usr/bin/env python3
# V-shaped bottom braces (OUTSIDE_V; William, 25 October). From sweep6/ (outside braces built, body held, one turn):
#   middle piece: at the bottom brace's height now (it passes under the body), from (x1, +13.3) to (x2, -13.3) across;
#                 of all that fit, the one reaching least along the walk (|x1 - x2|; straight across where it fits),
#                 then the shortest runs
#   runs:         from each pendant (its x, outside it at z = +-13.3) down to the middle piece's end, their ends at the
#                 pendants raised by RISE = half the room between the brace's bottom (at its lowest) and the body's bottom
# Every piece, at every moment (it moves with its pair's pendants: a shift), at least M from every link, foot (12 wide)
# and the top brace's pieces whose slab across comes within M of its own; runs skip their own pendant (welded to it),
# the middle piece doesn't. Writes vfit.json and prints the OUTSIDE_FIT bottom entries.
import sys, math, json, collections
sys.path.insert(0, "/home/claude/work")
import topz
from shapely.geometry import Polygon, box
from shapely import affinity
M, H, T, ZS = 0.3, 1.074, 0.3, 13 + 0.15 + 0.15
BUILDS = ["Chebyshev-Spears_diag", "Hoecken-Spears_4-bar_diag", "Chebyshev_diag", "Hoecken_4-bar_diag",
          "Hoecken-Spears_long-stance_diag", "Spears_lift_44_diag", "Spears_lift_53_diag"]
def load(b, d=__import__("os").environ.get("SWEEP6", "sweep6")):
    path = f"/home/claude/work/{d}/{b}.txt"
    name, L, S, bb, hz = topz.load(path)
    J = [l.split() for l in open(path) if l.startswith("JOIN")]
    n = min(len(S[i]) for i in L)
    pcs = [i for i in L if L[i]["kind"] == "buildOutsideCrossbar"]
    nbr, weld = collections.defaultdict(set), {}
    for j in J:
        a, c = int(j[1]), int(j[2])
        if a in pcs and c in pcs: nbr[a].add(c); nbr[c].add(a)
        elif a in pcs: weld[a] = c
        elif c in pcs: weld[c] = a
    groups, seen = [], set()
    for i in pcs:
        if i in seen: continue
        g, st = set(), [i]
        while st:
            k = st.pop()
            if k not in g: g.add(k); st += list(nbr[k])
        seen |= g; groups.append(g)
    y0 = lambda g: min(S[i][0].bounds[1] for i in g)
    bottom, top = sorted(groups, key=y0)
    pend = {L[weld[i]]["z"] > 0: weld[i] for i in bottom if i in weld}
    return dict(name=name, L=L, S=S, bb=bb, hz=hz, n=n, bottom=bottom, top=top, pend=pend,
                feet=[i for i in L if L[i]["kind"] == "buildFoot"])
def parts(W):   # what the bottom brace must clear: links, feet, the top brace (not the old bottom brace)
    return [i for i in W["L"] if i not in W["bottom"]]
def half(W, i): return 6.0 if i in W["feet"] else 0.15
def run_poly(xp, yp, xq, yq):
    """the bar from centre-line point (xp, yp) to (xq, yq), H tall across its line"""
    dx, dy = xq - xp, yq - yp; L = math.hypot(dx, dy); nx, ny = -dy / L * H / 2, dx / L * H / 2
    return Polygon([(xp + nx, yp + ny), (xq + nx, yq + ny), (xq - nx, yq - ny), (xp - nx, yp - ny)])
def pieces(W, x1, x2, ymid, rise):
    """[(zlo, zhi, polygon at moment 0, kind)], ymid: the middle piece's centre-line height"""
    xl, xr = W["S"][W["pend"][True]][0].centroid.x, W["S"][W["pend"][False]][0].centroid.x
    out = [(ZS - T / 2, ZS + T / 2, run_poly(xl, ymid + rise, x1, ymid), "runL"),
           (-ZS - T / 2, -ZS + T / 2, run_poly(xr, ymid + rise, x2, ymid), "runR")]
    N = 60
    for s in range(N):
        t0, t1 = s / N, (s + 1) / N
        a, b = x1 + (x2 - x1) * t0, x1 + (x2 - x1) * t1
        z0, z1 = ZS - 2 * ZS * t0, ZS - 2 * ZS * t1
        out.append((min(z0, z1) - T / 2, max(z0, z1) + T / 2, box(min(a, b) - T / 2, ymid - H / 2, max(a, b) + T / 2, ymid + H / 2), "mid"))
    return out
def worst(W, P, d, stop=None):
    best = (99, None)
    for k in range(W["n"]):
        dx, dy = d[k]
        for zlo, zhi, poly, kind in P:
            q = affinity.translate(poly, dx, dy)
            for i in parts(W):
                if kind == "runL" and i == W["pend"][True] or kind == "runR" and i == W["pend"][False]: continue
                z, t = W["L"][i]["z"], half(W, i)
                if z - t - M >= zhi or z + t + M <= zlo: continue
                g = q.distance(W["S"][i][k])
                if g < best[0]:
                    best = (g, (W["L"][i]["kind"], round(z, 1), kind, k))
                    if stop is not None and g < stop: return best
    return best
def fit(b):
    W = load(b)
    S, L = W["S"], W["L"]
    p = W["pend"][True]
    d = [(S[p][k].centroid.x - S[p][0].centroid.x, S[p][k].centroid.y - S[p][0].centroid.y) for k in range(W["n"])]
    ymid = sum(S[i][0].bounds[1] for i in W["bottom"]) / len(W["bottom"]) + H / 2   # (the old pieces' centre line)
    lowest = ymid - H / 2 + min(q[1] for q in d)
    room = W["bb"][2] - lowest                  # the body's bottom minus the brace's bottom at its lowest
    rise = room / 2
    xl, xr = S[W["pend"][True]][0].centroid.x, S[W["pend"][False]][0].centroid.x
    grid = [x / 4 for x in range(int(min(xl, xr) * 4), int(max(xl, xr) * 4) + 1)]
    # (runs and middle checked apart: a run depends only on its own end)
    okL = {x for x in grid if worst(W, [q for q in pieces(W, x, x, ymid, rise) if q[3] == "runL"], d, stop=M)[0] >= M}
    okR = {x for x in grid if worst(W, [q for q in pieces(W, x, x, ymid, rise) if q[3] == "runR"], d, stop=M)[0] >= M}
    cands = sorted(((abs(x1 - x2), abs(xl - x1) + abs(xr - x2), x1, x2) for x1 in okL for x2 in okR))
    for span, runs, x1, x2 in cands:
        if worst(W, [q for q in pieces(W, x1, x2, ymid, rise) if q[3] == "mid"], d, stop=M)[0] < M: continue
        w, who = worst(W, pieces(W, x1, x2, ymid, rise), d)
        if w >= M:
            return W, dict(x1=x1, x2=x2, ymid=ymid, rise=rise, room=room, span=span, worst=w, who=who, xl=xl, xr=xr,
                           ground=lowest - min(S[f][k].bounds[1] for f in W["feet"] for k in range(W["n"])))
    return W, None
if __name__ == "__main__":
    res = {}
    for b in (sys.argv[1:] or BUILDS):
        W, r = fit(b)
        if not r: print(b, "NOTHING FITS"); continue
        # (front: the larger x, the way the track walks, as outz5.py; runFront/runBack: from each pendant to the middle's end)
        front_left = r["xl"] > r["xr"]
        rf, rb = (abs(r["x1"] - r["xl"]), abs(r["x2"] - r["xr"])) if front_left else (abs(r["x2"] - r["xr"]), abs(r["x1"] - r["xl"]))
        r.update(runFront=rf, runBack=rb); res[b] = r
        print(f'{W["name"]:32s} middle reaches {r["span"]:5.2f} cm along the walk; runs {rf:5.2f} (front) {rb:5.2f} (back); '
              f'room {r["room"]:5.2f}, ends raised {r["rise"]:5.2f}; brace bottom {r["ground"]:.2f} above the ground at its lowest; '
              f'closest part {r["worst"]:.2f} {r["who"]}')
        print(f'    bottom = {{ yRel = (as now), runFront = {rf:.2f}, runBack = {rb:.2f}, rise = {r["rise"]:.2f} }}')
    json.dump(res, open("/home/claude/work/vfit_" + __import__("os").environ.get("SWEEP6", "sweep6") + ".json", "w"), indent=1, default=str)
