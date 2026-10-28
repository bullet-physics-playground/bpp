#!/usr/bin/env python3
# rv/*.txt: per crank, its normal turning direction (median spin sign); "reverse" frames = spin against it.
# Per foot, dx/dtheta from geometry: fit x against crank angle over frames when the crank turns normally (binned by
# angle, 5 deg). "Backward" = the sign of dx/dtheta most common while the foot is on the ground (the push stroke).
# Reports: the foot's sim mono (share of ground frames moving backward), and at reverse frames, which planted feet
# were in their forward-moving part of the path.
import sys, collections, math
for path in sys.argv[1:]:
    R = collections.defaultdict(list)
    for l in open(path):
        p = l.strip().split("|"); t = float(p[0][2:])
        R[int(p[1].split()[1])].append(dict(t=t, c=int(p[2].split()[1]), a=float(p[3].split()[1]), s=float(p[4].split()[1]),
                                            x=float(p[5].split()[1]), y=float(p[6].split()[1]), g=int(p[7].split()[1])))
    name = path.split("/")[-1][:-4]
    feet = sorted(R)
    sgn, sgs = {}, {}   # sgn: the way the measured angle normally runs; sgs: the way the spin normally reads
    for f in feet:
        c = R[f][0]["c"]; ss = sorted(r["s"] for r in R[f]); sgs[c] = 1 if ss[len(ss)//2] > 0 else -1
        dd = sorted((b["a"] - a["a"] + 180) % 360 - 180 for a, b in zip(R[f], R[f][1:])); sgn[c] = 1 if dd[len(dd)//2] > 0 else -1
    # dx/dtheta per foot, binned by crank angle in its turning direction
    prof = {}
    for f in feet:
        c = R[f][0]["c"]; rs = R[f]; bins = collections.defaultdict(list)
        for a, b in zip(rs, rs[1:]):
            da = (b["a"] - a["a"] + 180) % 360 - 180
            if da * sgn[c] > 0.05:
                th = (a["a"] * sgn[c]) % 360; bins[int(th // 5)].append((b["x"] - a["x"]) / (da * sgn[c]))
        prof[f] = {k: sorted(v)[len(v)//2] for k, v in bins.items()}
    # backward sign: dominant sign of dx/dtheta while on the ground
    back = {}; mono = {}
    for f in feet:
        n = collections.Counter()
        for r in R[f]:
            if r["g"]:
                k = int(((r["a"] * sgn[r["c"]]) % 360) // 5); d = prof[f].get(k)
                if d is not None: n[d > 0] += 1
        back[f] = n.most_common(1)[0][0] if n else True
        tot = sum(n.values()); mono[f] = n[back[f]] / tot if tot else float("nan")
    band = {}
    for f in feet:   # the report's mono: stance = foot in the lowest 15% of its height range (body frame)
        ys = [r["y"] for r in R[f]]; lo, hi = min(ys), max(ys); n = collections.Counter()
        for r in R[f]:
            if r["y"] <= lo + 0.15 * (hi - lo):
                k = int(((r["a"] * sgn[r["c"]]) % 360) // 5); d = prof[f].get(k)
                if d is not None: n[d > 0] += 1
        tot = sum(n.values()); band[f] = max(n.values()) / tot if tot else float("nan")
    print(f"== {name}: feet {len(feet)}, cranks {len(sgn)}, foot->crank {[R[f][0]['c'] for f in feet]}")
    print("  band mono (lowest 15% of height, as the report): " + "  ".join(f"foot{f} {band[f]:.3f}" for f in feet))
    print("  sim mono (share of ground frames the foot moves backward): " + "  ".join(f"foot{f} {mono[f]:.3f}" for f in feet))
    # reverse events
    nf = len(R[feet[0]]); rev = 0; withfwd = 0; ex = []
    for i in range(nf):
        rv = [f for f in feet if R[f][i]["s"] * sgs[R[f][i]["c"]] < 0]
        if not rv: continue
        rev += 1
        fwd = []
        for f in feet:
            r = R[f][i]
            if r["g"]:
                k = int(((r["a"] * sgn[r["c"]]) % 360) // 5); d = prof[f].get(k)
                if d is not None and (d > 0) != back[f]: fwd.append(f)
        if fwd: withfwd += 1
        if len(ex) < 12 and (not ex or R[feet[0]][i]["t"] - ex[-1][0] > 0.3):
            ex.append((R[feet[0]][i]["t"], rv, fwd, {f: round((R[f][i]["a"] * sgn[R[f][i]["c"]]) % 360) for f in rv}))
    # baseline: share of all frames with some planted foot moving forward
    base = 0
    for i in range(nf):
        for f in feet:
            r = R[f][i]
            if r["g"]:
                k = int(((r["a"] * sgn[r["c"]]) % 360) // 5); d = prof[f].get(k)
                if d is not None and (d > 0) != back[f]: base += 1; break
    print(f"  frames with a crank turning backwards: {rev} of {nf} ({100*rev/nf:.1f}%); of those, with a planted foot in its forward-moving part: {withfwd} ({100*withfwd/max(rev,1):.0f}%)")
    print(f"  all frames with a planted foot in its forward-moving part: {base} ({100*base/nf:.1f}%)")
    for t, rv, fwd, an in ex: print(f"   t {t:6.2f}: backwards feet' cranks {rv} at {an}; planted feet moving forward {fwd}")
