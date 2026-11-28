"""final2.py: the alphabet for the linkages that write. Every letter has
ways to split it among pens (one pen; split at the junctions; split into
single strokes, lines and arcs), every pen a choice of linkage sizes, each
measured as drawn, in the letter's units (1 tall). For each slider
position, the cheapest split (fewest bars, then fewest pens) whose every
pen is within the position's tolerance."""
import glob, math, json, sys, numpy as np
import linkage_synthesis as ls, letters as LT, multi as MU
from letters import arc
from final import seg_dist
LEVELS = [("sloppy", 0.08), ("ok", 0.04), ("very good", 0.02)]
# (a linkage may reach no more than this many letter heights, over a turn,
# so a letter's linkages fit a board: the synthesizer's bounds allow arms
# eight cranks long, and a small crank under a big letter reaches far)
MAXSPAN = float(__import__("os").environ.get("MAXSPAN", "4"))
# (and no pin may move more than this many cranks a radian of the crank: a
# linkage that whips a bar round fast drew 1% off at a 4-second turn)
MAXSPEED = float(__import__("os").environ.get("MAXSPEED", "20"))
B_TOP = MU.B_TOP

# the canonical shapes (one line, one half circle, the two halves of the S),
# each found once and placed on every stroke like it: their ends
CANON = {"cur/c-line-*.out": ("cur/c-line.txt", (0, 0), (1, 0)), "cur/c-semi-*.out": ("cur/c-semi.txt", (-1, 0), (1, 0))}
def target_of(strokes, source=None):
    """the stroke's timed samples, as the synthesizer saw its own: for a
    canonical shape, its own samples carried onto this stroke (a similarity:
    end to end), so the timing is the same"""
    canon = next((k for k in CANON if source.split("/")[-1] == k.split("/")[-1]), None)
    if canon:
        f, z0, z1 = CANON[canon]
        T = np.loadtxt(f, skiprows=1)
        W = LT.walk(strokes)
        ends = [q for q in (strokes[0][0], strokes[0][-1])]
        a, b = complex(*ends[0]), complex(*ends[1])
        # (a half circle's stroke is listed counterclockwise, as the
        # canonical's, so its first end is the canonical's first: the bulge
        # on the same side)
        z = T[:, 1] + 1j * T[:, 2]
        A, B = complex(*z0), complex(*z1)
        w = a + (z - A) * (b - a) / (B - A)
        return T[:, 0], np.c_[w.real, w.imag]
    pts = LT.timed(LT.walk(strokes), 100)
    return np.linspace(0, 2 * math.pi, 100, endpoint=False), pts

def candidates(files):
    """every (D, params) in the runs, best per D by the synthesizer's error"""
    best = {}
    for f in files:
        for line in open(f):
            if not line.startswith("DRESULT"): continue
            r = dict(t.split("=", 1) for t in line.split()[1:])
            if r["constructible"] != "1": continue
            D, e = int(r["D"]), float(r["rel_error"])
            if D not in best or e < best[D][0]: best[D] = (e, np.array([float(v) for v in r["params"].split(",")]))
    return {D: v[1] for D, v in best.items()}

CACHE = {}
def sizes(source, strokes):
    """[(D, h, params, transform)] for a pen drawing these strokes with
    linkages from source (a glob of runs)"""
    key = (source, json.dumps(strokes))
    if key in CACHE: return CACHE[key]
    t, tgt = target_of(strokes, source)
    W = np.array(LT.walk(strokes), float)
    s = np.r_[0, np.cumsum(np.hypot(*np.diff(W, axis=0).T))]
    probe = np.c_[np.interp(np.linspace(0, s[-1], 300), s, W[:, 0]), np.interp(np.linspace(0, s[-1], 300), s, W[:, 1])]
    out = []
    for D, p in sorted(candidates(glob.glob(source)).items()):
        tr = ls.trace_curve(p, D, t)
        dense = ls.trace_curve(p, D, np.linspace(0, 2 * math.pi, 600, endpoint=False))
        if tr is None or dense is None: continue
        tf = ls.compute_procrustes_transform(tr, tgt)
        d = ls.apply_transform(dense, tf)
        h = max(seg_dist(d, W[:-1], W[1:]).max(), seg_dist(probe, d[:-1], d[1:]).max())
        bb = ls._mechanism_bbox_over_time(ls.unpack(p, D), np.linspace(0, 2 * math.pi, 48, endpoint=False), tf)
        if bb is None: continue
        span = max(bb[1] - bb[0], bb[3] - bb[2])     # the linkage's reach, over a turn, in letter heights
        from speed import speedratio
        sr = speedratio(p.tolist(), D, 360)     # the fastest a pin moves, in cranks a radian of the crank
        out.append(dict(D=D, h=float(h), span=float(span), speed=float(sr), params=p.tolist(),
                        tf=dict(R=tf["R"].tolist(), scale=float(tf["scale"]), mu_p=tf["mu_p"].tolist(), mu_t=tf["mu_t"].tolist())))
    CACHE[key] = out
    return out

def L(a, b): return ("b3/c-line-*.out", [[a, b]])      # (the compact runs: arms at most three cranks)
SEMI = "b3/c-semi-*.out"
SPLITS = {c: [[(f"runs4/{c}-slow-*.out", LT.LETTERS[c])], [(f"b3/{c}-slow-*.out", LT.LETTERS[c])]] for c in LT.LETTERS}     # one pen (two searches)
for c, pens in MU.MULTI.items():
    pre = "n" if c in "EFKZ" else "m"
    SPLITS[c].append([(f"cur/{pre}-{c}{i}-*.out", [st]) for i, st in enumerate(pens)])
    SPLITS[c].append([(f"b3/{pre}-{c}{i}-*.out", [st]) for i, st in enumerate(pens)])
FINE = {
 "A": [L((0, 0), (.35, 1)), L((.35, 1), (.7, 0)), L((.1225, .35), (.5775, .35))],
 "E": [L((0, 0), (0, 1)), L((0, 1), (.6, 1)), L((0, .5), (.45, .5)), L((0, 0), (.6, 0))],
 "J": [L((.6, 1), (.6, .3)), (SEMI, [arc(.3, .3, .3, .3, 180, 360, 24)])],
 "L": [L((0, 1), (0, 0)), L((0, 0), (.6, 0))],
 "M": [L((0, 0), (0, 1)), L((0, 1), (.4, .3)), L((.4, .3), (.8, 1)), L((.8, 1), (.8, 0))],
 "N": [L((0, 0), (0, 1)), L((0, 1), (.7, 0)), L((.7, 0), (.7, 1))],
 "P": [L((0, 0), (0, 1)), ("cur/m-B1-*.out", [B_TOP])],
 "S": [("cur/c-Stop-*.out", [arc(.32, .75, .28, .25, 20, 270, 24)]), ("cur/c-Sbot-*.out", [arc(.32, .25, .28, .25, 90, -160, 24)])],
 "T": [L((0, 1), (.7, 1)), L((.35, 1), (.35, 0))],
 "U": [L((0, 1), (0, .3)), (SEMI, [arc(.3, .3, .3, .3, 180, 360, 24)]), L((.6, .3), (.6, 1))],
 "V": [L((0, 1), (.35, 0)), L((.35, 0), (.7, 1))],
 "W": [L((0, 1), (.2, 0)), L((.2, 0), (.45, .7)), L((.45, .7), (.7, 0)), L((.7, 0), (.9, 1))],
 "Y": [L((0, 1), (.35, .5)), L((.35, .5), (.7, 1)), L((.35, .5), (.35, 0))],
 "X": [L((0, 0), (.7, 1)), L((0, 1), (.7, 0))],
 "Z": [L((0, 1), (.7, 1)), L((.7, 1), (0, 0)), L((0, 0), (.7, 0))],
 "D": [L((0, 0), (0, 1)), L((0, 1), (.25, 1)), ("b3/c-semi-*.out", [arc(.25, .5, .5, .5, -90, 90, 24)]), L((.25, 0), (0, 0))],
}
def bowl(x, yc, r=.25):
    """a bowl of B, P, R: in from the stem, a half circle, back to the stem"""
    return [L((0, yc + r), (x, yc + r)), (SEMI, [arc(x, yc, r, r, -90, 90, 24)]), L((x, yc - r), (0, yc - r))]
FINE["B"] = [L((0, 0), (0, 1))] + bowl(.35, .75) + bowl(.4, .25)
FINE["P"] = [L((0, 0), (0, 1))] + bowl(.35, .75)
FINE["R"] = [L((0, 0), (0, 1))] + bowl(.35, .75) + [L((.2, .5), (.6, 0))]
for c, f in FINE.items(): SPLITS[c].append(f)
# (the S's halves, found again with compact arms)
SPLITS["S"].append([("b3/c-Stop-*.out", [arc(.32, .75, .28, .25, 20, 270, 24)]), ("b3/c-Sbot-*.out", [arc(.32, .25, .28, .25, 90, -160, 24)])])

def pick(c, tol):
    best = None
    for split in SPLITS[c]:
        chosen = []
        for source, strokes in split:
            ok = [z for z in sizes(source, strokes) if z["h"] <= tol and z["span"] <= MAXSPAN and z["speed"] <= MAXSPEED]
            if not ok: chosen = None; break
            chosen.append(dict(min(ok, key=lambda z: z["D"]), strokes=strokes, source=source))
        if chosen is None: continue
        cost = (sum(4 + 2 * z["D"] for z in chosen), len(chosen))
        if best is None or cost < best[0]: best = (cost, chosen)
    return best

if __name__ == "__main__":
    out = {}
    for c in sorted(SPLITS):
        out[c] = {}
        row = []
        for name, tol in LEVELS:
            b = pick(c, tol)
            if b is None: row.append(f"{name}: --"); out[c][name] = None; continue
            out[c][name] = b[1]
            row.append(f"{name}: {b[0][1]} pen{'s' if b[0][1] > 1 else ''}, {b[0][0]} bars")
        print(c, " | ".join(row))
    json.dump(out, open("alphabet.json", "w"))
