#!/usr/bin/env python3
# forceprobe.lua's output: frames where a front foot is pushed back by the ground (the step face: fx < -0.2 x weight /4
# and more back than up, or just back), and what the walker does then: crank speeds (slowest of the four, as a share of
# the target), the force on that foot (fx back, fy up, in weights), body pitch, and the other parts' forces.
import sys, collections, statistics as st
for path in sys.argv[1:]:
    P, F = {}, collections.defaultdict(dict); W = None
    for l in open(path):
        if l.startswith("WEIGHT"): W = float(l.split()[1].split("|")[0])
        elif l.startswith("P "):
            f = l.strip().split("|"); t = float(f[0][2:])
            cr = [float(x) for x in f[3].split()[1:]]; P[t] = dict(pitch=float(f[1].split()[1]), vy=float(f[2].split()[1]), cr=cr, tg=float(f[4].split()[1]))
        elif l.startswith("F "):
            f = l.strip().split("|"); t = float(f[0][2:])
            F[t][f[1] + " " + f[2]] = (float(f[3].split()[1]) / W, float(f[4].split()[1]) / W, int(f[5].split()[1]))
    blocked, free = [], []
    for t in sorted(P):
        if t < 3.5 or not P[t]["cr"]: continue
        fr = F.get(t, {})
        fe = [(k, v) for k, v in fr.items() if k.startswith("buildFoot F") and v[0] < -0.05]
        (blocked if fe else free).append((t, fe, fr))
    def crs(rows): return [min(P[t]["cr"]) / P[t]["tg"] for t, *_ in rows]
    def mcr(rows): return [st.mean(P[t]["cr"]) / P[t]["tg"] for t, *_ in rows]
    name = path.split("fp2_")[-1][:-4]
    print(f"{name}: {len(blocked)} frames with a front foot pushed back, {len(free)} without (from 3.5 s)")
    if blocked:
        fx = [min(v[0] for k, v in fe) for t, fe, fr in blocked]; fy = [max(v[1] for k, v in fe) for t, fe, fr in blocked]
        print(f"   front foot pushed back: median {-st.median(fx):.2f} weights (max {-min(fx):.2f}); held up by the ground there: median {st.median(fy):.2f}")
        print(f"   cranks then: slowest at {100*st.median(crs(blocked)):.0f}% of target (lowest {100*min(crs(blocked)):.0f}%), mean of four {100*st.median(mcr(blocked)):.0f}%; without: slowest {100*st.median(crs(free)):.0f}%")
        print(f"   body pitch then: median {st.median(P[t]['pitch'] for t, *_ in blocked):.1f} deg (front up +); without: {st.median(P[t]['pitch'] for t, *_ in free):.1f}")
        oth = collections.Counter()
        for t, fe, fr in blocked:
            for k, v in fr.items():
                if not k.startswith("buildFoot"): oth[k] += 1
        print(f"   other parts on the ground in those frames: {dict(oth.most_common(5))}")
