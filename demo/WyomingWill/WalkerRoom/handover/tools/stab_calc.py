#!/usr/bin/env python3
# Before running: what brace / pendant weights would give diag the same static stability as its guides cousin?
# From the build dumps (body frame: x along the walk, y up, z across). CoM height above the feet's bottoms,
# the two-feet tip angle atan(3.5 / height) (3.5 cm: the measured median margin on flat), and roll / pitch
# inertia about the CoM (each part's own inertia turned into the body frame, plus parallel axes).
import math, re, sys
def rot(ax, ay, az):
    a, b, c = map(math.radians, (ax, ay, az))
    Rx = [[1, 0, 0], [0, math.cos(a), -math.sin(a)], [0, math.sin(a), math.cos(a)]]
    Ry = [[math.cos(b), 0, math.sin(b)], [0, 1, 0], [-math.sin(b), 0, math.cos(b)]]
    Rz = [[math.cos(c), -math.sin(c), 0], [math.sin(c), math.cos(c), 0], [0, 0, 1]]
    mm = lambda A, B: [[sum(A[i][k] * B[k][j] for k in range(3)) for j in range(3)] for i in range(3)]
    return mm(Rz, mm(Ry, Rx))
def load(f):
    P = []
    for l in open(f):
        if not l.startswith("BODY"): continue
        s = l.strip().split("|")
        kind = s[0].split()[1]
        g = lambda tag: [float(x) if x != "-" else 0.0 for x in next(t for t in s if t.startswith(tag)).split()[1:]]
        P.append(dict(kind=kind, m=g("mass")[0], I=g("inertia"), half=g("half"), p=g("pos"), t=g("turn")))
    return P
def pendants(P):   # the link whose x, z match a foot's and is the heaviest there
    feet = [q for q in P if q["kind"] == "buildFoot"]
    out = []
    for f in feet:
        c = [q for q in P if q["kind"] == "makeLink" and abs(q["p"][0] - f["p"][0]) < 0.3 and abs(q["p"][2] - f["p"][2]) < 0.3]
        out.append(max(c, key=lambda q: q["m"]))
    return out
def stats(P):
    feet = [q for q in P if q["kind"] == "buildFoot"]
    bottom = min(q["p"][1] - q["half"][1] for q in feet)
    M = sum(q["m"] for q in P)
    c = [sum(q["m"] * q["p"][i] for q in P) / M for i in range(3)]
    I = [[0] * 3 for _ in range(3)]
    for q in P:
        R = rot(*q["t"])
        for i in range(3):
            for j in range(3):
                I[i][j] += sum(R[i][k] * q["I"][k] * R[j][k] for k in range(3))
        d = [q["p"][i] - c[i] for i in range(3)]; dd = sum(x * x for x in d)
        for i in range(3):
            for j in range(3): I[i][j] += q["m"] * ((dd if i == j else 0) - d[i] * d[j])
    h = c[1] - bottom
    return dict(M=M, h=h, tip=math.degrees(math.atan(3.5 / h)), roll=I[0][0], pitch=I[2][2])
def variant(D, G, kb=1.0, trim=False, kp=None):
    P = []
    pd = pendants(D); pg = pendants(G)
    for q in D:
        q = dict(q)
        if "Crossbar" in q["kind"]: q["m"] *= kb; q["I"] = [x * kb for x in q["I"]]
        if any(q is p or (q["p"] == p["p"] and q["m"] == p["m"]) for p in pd):
            if trim:   # the guides cousin's pendant at the same foot instead
                g = min(pg, key=lambda r: abs(r["p"][0] - q["p"][0]) + abs(r["p"][2] - q["p"][2]))
                q = dict(g)
        P.append(q)
    return P
for name, df, gf in (("Chebyshev-Spears", "CS_diag.txt", "CS_guides.txt"), ("Hoecken-Spears 4-bar", "HS4_diag.txt", "HS4_guides.txt")):
    D, G = load(df), load(gf)
    sg = stats(G)
    print(f"\n{name}")
    row = lambda lab, s: print(f"  {lab:46s} mass {s['M']:6.1f}  CoM {s['h']:5.2f} cm  tip {s['tip']:4.1f} deg  roll {s['roll']:6.0f} ({s['roll'] / sg['roll']:.2f}x)  pitch {s['pitch']:6.0f} ({s['pitch'] / sg['pitch']:.2f}x)")
    row("guides", sg)
    for kb in (1.0, 0.5, 0.25, 0.02):
        row(f"diag, braces x{kb}", stats(variant(D, G, kb)))
    for kb in (1.0, 0.5, 0.25, 0.02, 0.0):
        row(f"diag, braces x{kb}, pendants as guides'", stats(variant(D, G, kb, trim=True)))
    # brace factor that matches the guides' CoM height, with trimmed pendants
    for trim in (False, True):
        lo, hi = 0.0, 1.0
        if stats(variant(D, G, 0.0, trim))["h"] > sg["h"]:
            print(f"  (pendants {'as guides' if trim else 'as built'}): even weightless braces leave the CoM {stats(variant(D, G, 0.0, trim))['h'] - sg['h']:+.2f} cm above guides'")
            continue
        for _ in range(40):
            mid = (lo + hi) / 2
            if stats(variant(D, G, mid, trim))["h"] > sg["h"]: hi = mid
            else: lo = mid
        row(f"diag, braces x{lo:.3f} (same CoM), pendants {'as guides' if trim else 'built'}", stats(variant(D, G, lo, trim)))
# the arched brace moved under the body (its three pieces' centres at 4 cm above the feet's bottoms), straight brace as built
LOWC = {"Chebyshev-Spears": 4.85 + 0.54, "Hoecken-Spears 4-bar": 5.08 + 0.54}
print()
for name, df, gf in (("Chebyshev-Spears", "CS_diag.txt", "CS_guides.txt"), ("Hoecken-Spears 4-bar", "HS4_diag.txt", "HS4_guides.txt")):
    D, G = load(df), load(gf); sg = stats(G)
    bottom = min(q["p"][1] - q["half"][1] for q in D if q["kind"] == "buildFoot")
    for kb in (1.0, 0.5):
        P = [dict(q) for q in variant(D, G, kb)]
        for q in P:
            if q["kind"] == "buildArchedCrossbar": q["p"] = [q["p"][0], bottom + LOWC[name], q["p"][2]]
        s = stats(P)
        print(f"{name:22s} arched brace low, both braces x{kb}: mass {s['M']:6.1f}  CoM {s['h']:5.2f} (guides {sg['h']:.2f})  tip {s['tip']:4.1f} (guides {sg['tip']:.1f})  roll {s['roll'] / sg['roll']:.2f}x  pitch {s['pitch'] / sg['pitch']:.2f}x")
