# The fewest link planes each walker needs, from its links' swept outlines.
import sys, math, itertools, collections, json, glob, os
from shapely.geometry import Polygon, LineString, Point
from shapely.ops import unary_union
GAP, CLEAR, PIN_R = 0.7, 0.2, 0.15   # (GAP: the room's PLANE_GAP since patch 13; this file had 0.5)
PINS_CHECKED = False   # (the simulation has no pins: its joints pass through other planes freely)
ROLES = {"Jansen": "crank=1, rodJ=2, triG=3, rodK=4, rodC=5, rodF=6, triJ4=7", "Klann": "crank=1, triA=2, rockerLower=3, triB=4, rockerUpper=5",
         "Hoecken slider": "crank=1, coupler=2, pendant=3", "Hoecken-Spears slider": "crank=1, coupler=2, pendant=3"}
DEF = "crank=1, coupler=2, rocker=3, pendant=4"
def parse(path):
    L, joins, grounds, S = {}, [], [], collections.defaultdict(list)
    for l in open(path):
        if l.startswith("WALKER"):
            f = l.strip().split("|"); name = f[0][7:]; bhz = float(f[2].split()[1])
        elif l.startswith("LINK"):
            f = l.strip().split("|"); i = int(f[0].split()[1]); z = float(f[1].split()[1])
            poly = [tuple(map(float, p.split(","))) for p in f[3][5:].split(";")]
            L[i] = dict(z=z, poly=poly)
        elif l.startswith("JOIN"):
            p = l.split(); joins.append((int(p[1]), int(p[2]), p[3], None if p[4] == "-" else tuple(map(float, p[4].split(",")))))
        elif l.startswith("GROUND"):
            p = l.split(); grounds.append((int(p[1]), p[2], None if p[3] == "-" else tuple(map(float, p[3].split(",")))))
        elif l.startswith("S "):
            p = l.split(); S[int(p[1])].append([tuple(map(float, q.split(","))) for q in p[2].split(";")])
    # (links only: feet, plates and braces don't get planes)
    kind = {}
    for l in open(path):
        if l.startswith("LINK"):
            f = l.strip().split("|"); kind[int(f[0].split()[1])] = f[4].split()[1]
    keep = {i for i in L if kind.get(i) in ("makeLink", "buildLinkage", "?")}
    L = {i: d for i, d in L.items() if i in keep}
    joins = [j for j in joins if j[0] in keep and j[1] in keep]
    grounds = [g for g in grounds if g[0] in keep]
    S = {i: v for i, v in S.items() if i in keep}
    return name, bhz, L, joins, grounds, S
def xform(local, world):
    # 2D rigid transform taking local polygon to the sampled world polygon (from vertices 0 and 1)
    (a0, a1), (b0, b1) = local[0], local[1]
    (A0, A1), (B0, B1) = world[0], world[1]
    ang = math.atan2(B1 - A1, B0 - A0) - math.atan2(b1 - a1, b0 - a0)
    c, s = math.cos(ang), math.sin(ang)
    tx, ty = A0 - (c * a0 - s * a1), A1 - (s * a0 + c * a1)
    return lambda p: (c * p[0] - s * p[1] + tx, s * p[0] + c * p[1] + ty)
def analyse(path):
    name, bhz, L, joins, grounds, S = parse(path)
    roles = dict((kv.split("=")[1].strip(), kv.split("=")[0].strip()) for kv in ROLES.get(name, DEF).split(","))
    roles = {int(k): v for k, v in roles.items()}
    for i, d in L.items():
        n = round((abs(d["z"]) - bhz) / GAP); d["role"] = roles.get(n, f"?{n}"); d["side"] = 1 if d["z"] > 0 else -1
        d["swept"] = unary_union([Polygon(p).buffer(0) for p in S[i]])
    rl = sorted({d["role"] for d in L.values()}, key=lambda r: min(k for k, v in roles.items() if v == r) if r in roles.values() else 99)
    # welds (no relative motion) and real sliders, among joins
    rigid = set(); slide = set(); hinge = []
    for a, b, kind, piv in joins:
        if kind == "btHingeConstraint": hinge.append((a, b, piv)); continue
        d = [math.dist(S[a][k][0], S[b][k][0]) for k in range(len(S[a]))]
        (rigid if max(d) - min(d) < 0.05 else slide).add(frozenset((a, b)))
    ok_pairs = rigid | slide
    comp = {i: i for i in L}
    def root(i):
        while comp[i] != i: i = comp[i]
        return i
    for a, b, *_ in joins: comp[root(a)] = root(b)
    leg = {i: root(i) for i in L}
    P = {i: [Polygon(p).buffer(0) for p in S[i]] for i in L}
    def touch(a, b):
        # same leg: at the same moment; different legs: anywhere they sweep
        if leg[a] == leg[b]:
            return any(P[a][k].distance(P[b][k]) < CLEAR for k in range(len(P[a])))
        return L[a]["swept"].distance(L[b]["swept"]) < CLEAR
    must_differ, overlap = set(), set()
    for a, b, piv in hinge: must_differ.add(frozenset((L[a]["role"], L[b]["role"])))
    ids = sorted(L)
    for a, b in itertools.combinations(ids, 2):
        if L[a]["side"] != L[b]["side"] or frozenset((a, b)) in ok_pairs: continue
        if touch(a, b):
            ra, rb = L[a]["role"], L[b]["role"]
            if ra == rb: overlap.add(("SAME", ra))
            else: overlap.add(frozenset((ra, rb)))
    # pins: each hinge's swept pin path, and which roles it sweeps near
    pins = []
    for a, b, piv in hinge:
        if piv is None: continue
        path = [xform(L[a]["poly"], S[a][k])(piv) for k in range(len(S[a]))]
        geom = LineString(path) if len(set(path)) > 1 else Point(path[0])
        def pnear(c):
            if leg[c] == leg[a]: return any(P[c][k].distance(Point(path[k])) < PIN_R + CLEAR for k in range(len(path)))
            return L[c]["swept"].distance(geom) < PIN_R + CLEAR
        near = {L[c]["role"] for c in ids if L[c]["side"] == L[a]["side"] and c not in (a, b) and pnear(c)}
        pins.append((L[a]["role"], L[b]["role"], near))
    for c, kind, piv in grounds:
        if piv is None or kind != "btHingeConstraint": continue
        pt = xform(L[c]["poly"], S[c][0])(piv)
        near = {L[d]["role"] for d in ids if L[d]["side"] == L[c]["side"] and d != c and L[d]["swept"].distance(Point(pt)) < PIN_R + CLEAR}
        pins.append((None, L[c]["role"], near))
    outer = "pendant" if "pendant" in rl and name not in ("Jansen", "Klann", "Spears 4-bar") else None
    conflicts = {p for p in must_differ | overlap if not (isinstance(p, tuple))}
    def valid(asg):
        for p in conflicts:
            x, y = tuple(p) if len(p) == 2 else (list(p)[0],) * 2
            if asg[x] == asg[y]: return False
        if PINS_CHECKED:
            for ra, rb, near in pins:
                lo_, hi_ = sorted((0 if ra is None else asg[ra], asg[rb]))
                for r in near:
                    if lo_ < asg[r] < hi_: return False
        if outer and asg[outer] != max(asg.values()): return False
        return True
    best = None
    for K in range(1, len(rl) + 1):
        for combo in itertools.product(range(1, K + 1), repeat=len(rl)):
            if max(combo) != K: continue
            asg = dict(zip(rl, combo))
            if not valid(asg): continue
            cost = sum(abs((0 if ra is None else asg[ra]) - asg[rb]) for ra, rb, _ in pins) / 8
            if best is None or cost < best[0]: best = (cost, asg)
        if best: break
    cur = {r: n for n, r in roles.items()}
    filePlanes = {}
    return dict(name=name, roles=rl, conflicts=sorted("-".join(sorted(p)) for p in conflicts), same_role_overlap=sorted(r for t, r in overlap if isinstance((t, r), tuple) and t == "SAME") if any(isinstance(p, tuple) for p in overlap) else [],
                welded=len(rigid), sliding=len(slide), K=max(best[1].values()) if best else None, assign=best[1] if best else None, pinlen=best[0] if best else None)
if __name__ == "__main__":
    res = []
    for f in sorted(glob.glob(f"/home/claude/work/{sys.argv[1]}/*.txt")):
        r = analyse(f); res.append(r)
        print(f"{r['name']:32s} planes {r['K']}  {r['assign']}  pin length {r['pinlen']}  | must differ / overlap: {r['conflicts']}  same-role overlaps {r['same_role_overlap']}", flush=True)
    json.dump(res, open(f"/home/claude/work/planes_{sys.argv[1]}.json", "w"), indent=1)
