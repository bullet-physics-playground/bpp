#!/usr/bin/env python3
# forceprobe.lua (with V lines): when a front foot is pushed back by the ground, how the linkage is moving that foot
# relative to the body (vx along the walk, vy up, cm/s) and where it is (x ahead of the body's centre, y below it).
import sys, collections, statistics as st
for path in sys.argv[1:]:
    P, F, V = {}, collections.defaultdict(dict), collections.defaultdict(dict); W = None
    for l in open(path):
        if l.startswith("WEIGHT"): W = float(l.split()[1].split("|")[0])
        elif l.startswith("P "):
            f = l.strip().split("|"); t = float(f[0][2:]); cr = [float(x) for x in f[3].split()[1:]]
            P[t] = dict(cr=cr, tg=float(f[4].split()[1]))
        elif l.startswith("F "):
            f = l.strip().split("|"); t = float(f[0][2:])
            if f[1] == "buildFoot": F[t][f[2]] = (float(f[3].split()[1]) / W, float(f[4].split()[1]) / W)
        elif l.startswith("V "):
            f = l.strip().split("|"); t = float(f[0][2:])
            V[t][f[1]] = tuple(float(x.split()[1]) for x in f[2:])
    rows = []
    for t in sorted(F):
        if t < 3.5 or not P.get(t, {}).get("cr"): continue
        for k, (fx, fy) in F[t].items():
            if k[0] == "F" and fx < -0.05 and k in V[t]:
                x, y, vx, vy = V[t][k]; rows.append((t, k, fx, fy, x, y, vx, vy, min(P[t]["cr"]) / P[t]["tg"]))
    name = path.split("fp2_")[-1][:-4]
    print(f"{name}: {len(rows)} foot-frames blocked")
    if not rows: continue
    q = lambda i: (st.median(r[i] for r in rows), st.quantiles([r[i] for r in rows], n=4))
    for i, lab in ((6, "linkage drives the foot along the walk (cm/s)"), (7, "... and up (cm/s)"), (5, "foot centre below the body's centre (cm)"), (4, "foot ahead of the body's centre (cm)")):
        m, qq = q(i); print(f"   {lab}: median {m:.1f}, quartiles {qq[0]:.1f} / {qq[2]:.1f}")
    # split: foot driven forward (into the face) vs not
    fwd = [r for r in rows if r[6] > 3]; down = [r for r in rows if r[6] <= 3 and r[7] < -3]; other = [r for r in rows if r not in fwd and r not in down]
    for lab, rr in (("driven forward (vx > 3)", fwd), ("driven down, not forward", down), ("other", other)):
        if rr: print(f"   {lab}: {len(rr)} frames; push back median {-st.median(r[2] for r in rr):.2f} W; slowest crank {100*st.median(r[8] for r in rr):.0f}%")
