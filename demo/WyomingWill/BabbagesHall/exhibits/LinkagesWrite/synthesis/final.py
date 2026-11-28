"""final.py: the alphabet's pens, every size's best linkage, measured in
the letter's own units (the letter 1 tall): how far the pen's drawn curve
strays from its stroke, both ways (the larger of: the farthest the pen
gets from the stroke, the farthest a point of the stroke is from the pen)."""
import glob, math, json, numpy as np
import linkage_synthesis as ls, letters as LT, multi as MU
SINGLE = "CDJLOPSTUV"
def seg_dist(P, A, B):
    AB = B - A; L2 = (AB ** 2).sum(1); L2[L2 == 0] = 1e-12
    t = np.clip(((P[:, None, :] - A[None]) * AB[None]).sum(2) / L2[None], 0, 1)
    Q = A[None] + t[..., None] * AB[None]
    return np.sqrt(((P[:, None, :] - Q) ** 2).sum(2)).min(1)
def pens():
    out = {}
    for c in "ABCDEFGHIJKLMNOPQRSTUVWXYZ":
        if c in SINGLE:
            out[c] = [dict(strokes=LT.LETTERS[c], runs=[(f"t-{c}-{k}.txt", f) for k in ("slow", "even") for f in glob.glob(f"runs4/{c}-{k}-*.out")])]
        else:
            pre = "n" if c in "EFKZ" else "m"
            out[c] = [dict(strokes=[st], runs=[(f"cur/{pre}-{c}{i}.txt", f) for f in glob.glob(f"cur/{pre}-{c}{i}-*.out")]) for i, st in enumerate(MU.MULTI[c])]
    return out
def measure(target, D, p, strokes):
    T = np.loadtxt(target, skiprows=1)
    tr = ls.trace_curve(p, D, T[:, 0])
    if tr is None: return None
    tf = ls.compute_procrustes_transform(tr, T[:, 1:])
    dense = ls.trace_curve(p, D, np.linspace(0, 2 * math.pi, 600, endpoint=False))
    if dense is None: return None
    dense = ls.apply_transform(dense, tf)
    W = np.array(LT.walk(strokes), float)
    s = np.r_[0, np.cumsum(np.hypot(*np.diff(W, axis=0).T))]
    probe = np.c_[np.interp(np.linspace(0, s[-1], 300), s, W[:, 0]), np.interp(np.linspace(0, s[-1], 300), s, W[:, 1])]
    h = max(seg_dist(dense, W[:-1], W[1:]).max(), seg_dist(probe, dense[:-1], dense[1:]).max())
    return h, tf
if __name__ == "__main__":
    P = pens(); table = {}
    for c, plist in P.items():
        table[c] = []
        for pen in plist:
            best = {}
            for target, f in pen["runs"]:
                for line in open(f):
                    if not line.startswith("DRESULT"): continue
                    r = dict(t.split("=", 1) for t in line.split()[1:])
                    if r["constructible"] != "1": continue
                    D = int(r["D"]); p = np.array([float(v) for v in r["params"].split(",")])
                    m = measure(target, D, p, pen["strokes"])
                    if m is None: continue
                    if D not in best or m[0] < best[D]["h"]:
                        best[D] = dict(D=D, h=m[0], target=target, params=p.tolist(),
                                       tf=dict(R=m[1]["R"].tolist(), scale=m[1]["scale"], mu_p=m[1]["mu_p"].tolist(), mu_t=m[1]["mu_t"].tolist()))
            table[c].append(dict(strokes=pen["strokes"], sizes=[best[D] for D in sorted(best)]))
        print(c, " | ".join(" ".join(f"{4+2*v['D']}:{100*v['h']:.1f}" for v in pen["sizes"]) for pen in table[c]))
    json.dump(table, open("alphabet.json", "w"))
