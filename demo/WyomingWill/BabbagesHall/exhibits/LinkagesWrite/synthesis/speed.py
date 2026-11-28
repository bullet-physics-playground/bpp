import json, math, numpy as np, linkage_synthesis as ls
def speedratio(params, D, n=720):
    """the fastest any joint moves, in cranks per radian of the crank, over a turn"""
    m = ls.unpack(np.array(params), D); best = 0; prev = None
    for t in np.linspace(0, 2 * math.pi, n + 1):
        J = ls._mechanism_joint_chain(m, t)
        if J is None: return 1e9
        chain, P0, dy, Pf = J
        pts = np.array(list(chain) + [P0] + [q for d in dy for q in (d["C"], d["P_out"])])
        if prev is not None:
            v = np.abs(pts - prev).max() / (2 * math.pi / n) / m.r2
            best = max(best, v)
        prev = pts
    return best
if __name__ == "__main__":
    A = json.load(open("alphabet.json"))
    rows = []
    for c, L in A.items():
        for lev, pens in L.items():
            for i, z in enumerate(pens): rows.append((speedratio(z["params"], z["D"]), c, lev, i + 1, 4 + 2 * z["D"]))
    rows.sort(reverse=True)
    for r in rows[:12]: print("%.1f" % r[0], r[1:])
    print("median", np.median([r[0] for r in rows]))
