#!/usr/bin/env python3
# Weight, CoM height, tip angle, roll, pitch for the "outside" braces (outz.py fits), at the build pose.
# Both pairs' pendants at guides' length (neither brace needs the extensions). Bars 0.18 per cm.
import json, math, sys
sys.argv = ["x"]
exec(open("/home/claude/work/dump/stab_calc.py").read().split("for name, df, gf in")[0])
import numpy as np
sys.path.insert(0, "/home/claude/work"); import topz, outz
DENS, ZS, H = 0.18, outz.ZS, outz.H
def tensor(q): R = np.array(rot(*q["t"])); return R @ np.diag(q["I"]) @ R.T
def rod(m, a, b):
    a, b = np.array(a, float), np.array(b, float); u = b - a; L = np.linalg.norm(u); u = u / L
    return dict(m=m, p=list((a + b) / 2), T=m * L * L / 12 * (np.eye(3) - np.outer(u, u)))
def stats3(P, bottom):
    M = sum(q["m"] for q in P); c = sum(q["m"] * np.array(q["p"]) for q in P) / M
    I = np.zeros((3, 3))
    for q in P: d = np.array(q["p"]) - c; I += q["T"] + q["m"] * (d @ d * np.eye(3) - np.outer(d, d))
    h = c[1] - bottom; return dict(M=M, h=h, tip=math.degrees(math.atan(3.5 / h)), roll=I[0, 0], pitch=I[2, 2], yaw=I[1, 1])
R = json.load(open("/home/claude/work/outz.json"))
SW = {"CS": "Chebyshev-Spears_diag", "HS4": "Hoecken-Spears_4-bar_diag"}
for k, dumpf, gf in (("CS", "CS_low.txt", "CS_guides.txt"), ("HS4", "HS4_low.txt", "HS4_guides.txt")):
    D, G = load(dumpf), load(gf); W = topz.setup(SW[k]); r = R[SW[k]]
    bottom = min(q["p"][1] - q["half"][1] for q in D if q["kind"] == "buildFoot")
    sg = stats3([dict(q, T=tensor(q)) for q in G], min(q["p"][1] - q["half"][1] for q in G if q["kind"] == "buildFoot"))
    pd = pendants(D); gp = pendants(G)[0]
    lft = [q for q in pd if q["p"][2] > 0]; rgt = [q for q in pd if q["p"][2] < 0]
    top = {"L": max(lft, key=lambda q: q["p"][0]), "R": min(rgt, key=lambda q: q["p"][0])}
    bot = {"L": min(lft, key=lambda q: q["p"][0]), "R": max(rgt, key=lambda q: q["p"][0])}
    lo = {id(q): q["p"][1] - q["half"][0] for q in pd}
    def sw(pairname, side):
        ids = W["top"] if pairname == "top" else W["bot"]
        i = [j for j in ids if (W["L"][j]["z"] > 0) == (side == "L")][0]; s = W["S"][i][0]; return s.centroid.x, s.bounds[1]
    def to_dump(pairname, side, x, y):
        ref = (top if pairname == "top" else bot)[side]; sx, sb = sw(pairname, side)
        return x - sx + ref["p"][0], y - sb + lo[id(ref)]
    def pend(q):
        L = 2 * gp["half"][0]; base = lo[id(q)]
        q = dict(q, m=gp["m"], p=[q["p"][0], base + L / 2, q["p"][2]], I=gp["I"], half=gp["half"]); q["T"] = tensor(q); return q
    def outside(pairname, x1, x2, kw):
        f = r[pairname]; yc = f["yb"] + H / 2
        pl = (top if pairname == "top" else bot)
        a1 = to_dump(pairname, "L", x1, yc); a2 = to_dump(pairname, "R", x2, yc)
        pts = [(pl["L"]["p"][0], a1[1], ZS), (a1[0], a1[1], ZS), (a2[0], a2[1], -ZS), (pl["R"]["p"][0], a2[1], -ZS)]
        out = []
        for p0, p1 in zip(pts, pts[1:]):
            L = math.dist(p0, p1)
            if L > 1e-6: out.append(rod(DENS * L * kw, p0, p1))
        return out
    def build(tk, bk, kw):
        P = [dict(q, T=tensor(q)) for q in D if "Crossbar" not in q["kind"] and not any(q is p for p in pd)]
        P += [pend(q) for q in pd]
        for pairname, kind in (("top", tk), ("bottom", bk)):
            f = r[pairname]
            if kind == "across": x1 = x2 = sum(f["straight"]) / 2
            else: _, x1, x2 = f["best"]
            P += outside(pairname, x1, x2, kw)
        return P
    print(f"\n{k}")
    row = lambda lab, s: print(f"  {lab:44s} weight {s['M']:6.1f}  CoM {s['h']:5.2f}  tip {s['tip']:4.1f}  roll {s['roll'] / sg['roll']:.2f}x  pitch {s['pitch'] / sg['pitch']:.2f}x  yaw {s['yaw'] / sg['yaw']:.2f}x")
    row("guides", sg)
    row("diag as built now", stats3([dict(q, T=tensor(q)) for q in load(dumpf.replace("_low", "_diag"))], bottom))
    for tk, bk in (("across", "across"), ("diagonal", "diagonal"), ("diagonal", "across"), ("across", "diagonal")):
        for kw in (1, 0.5, 0.25):
            row(f"top {tk:8s} bottom {bk:8s} braces x{kw}", stats3(build(tk, bk, kw), bottom))
