#!/usr/bin/env python3
# Foot lift from sweep2/: each foot's bottom over one crank turn, body held still.
#   lift: highest bottom minus lowest bottom (cm)
#   front: the foot's lowest point as it comes forward over the front fifth
#          of its travel, above its lowest (cm): how high the foot is where
#          it would meet an obstacle ahead
import glob, os, re, json
out = {}
for f in sorted(glob.glob("/home/claude/work/sweep2/*.txt")):
    name, feet, seq = None, set(), {}
    for l in open(f):
        if l.startswith("WALKER "): name = l[7:].split("|")[0]
        elif l.startswith("LINK ") and "buildFoot" in l: feet.add(int(l.split()[1].split("|")[0]))
        elif l.startswith("S "):
            _, k, pts = l.split(" ", 2)
            k = int(k)
            if k in feet:
                p = [tuple(map(float, q.split(","))) for q in pts.strip().split(";")]
                seq.setdefault(k, []).append(p)
    lifts, fronts = [], []
    for k, frames in seq.items():
        bot = [min(y for _, y in p) for p in frames]
        cx = [sum(x for x, _ in p) / len(p) for p in frames]
        lo, hi = min(bot), max(bot)
        x0, x1 = min(cx), max(cx)
        fr = [bot[i] - lo for i in range(1, len(cx)) if cx[i] > cx[i - 1] and cx[i] > x1 - 0.2 * (x1 - x0)]
        lifts.append(hi - lo); fronts.append(min(fr) if fr else 0.0)
    out[name] = dict(lift=sum(lifts) / len(lifts), front=sum(fronts) / len(fronts))
json.dump(out, open("/home/claude/work/footlift.json", "w"), indent=1)
for n, d in sorted(out.items(), key=lambda kv: -kv[1]["lift"]):
    print(f"{n:32s} lift {d['lift']:5.2f} cm  front {d['front']:5.2f} cm")
