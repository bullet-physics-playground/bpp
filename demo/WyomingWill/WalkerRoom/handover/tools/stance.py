#!/usr/bin/env python3
# From sweepT/ (trot sweeps, body held, one crank turn): per build, each foot's lift (bottom, highest minus lowest)
# and its share of the turn within 0.25 / 0.5 cm of its lowest (time it could be on flat ground). Mean over feet.
import glob, collections
for f in sorted(glob.glob("/home/claude/work/sweepT/*.txt")):
    if "nohold" in f or "diag" in f: continue
    feet, seq, name = set(), collections.defaultdict(list), None
    for l in open(f):
        if l.startswith("WALKER "): name = l[7:].split("|")[0]
        elif l.startswith("LINK ") and "buildFoot" in l: feet.add(int(l.split()[1].split("|")[0]))
        elif l.startswith("S "):
            _, k, pts = l.split(" ", 2); k = int(k)
            if k in feet: seq[k].append(min(float(q.split(",")[1]) for q in pts.strip().split(";")))
    lifts, st = [], {0.25: [], 0.5: []}
    for k, b in seq.items():
        lo = min(b); lifts.append(max(b) - lo)
        for t in st: st[t].append(sum(y - lo <= t for y in b) / len(b))
    n = len(next(iter(seq.values())))
    print(f"{name:28s} lift {sum(lifts)/len(lifts):5.2f}  within 0.25 {100*sum(st[0.25])/len(st[0.25]):4.0f}%  within 0.5 {100*sum(st[0.5])/len(st[0.5]):4.0f}%  frames {n}")
