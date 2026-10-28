#!/usr/bin/env python3
# st5: per walker x friction x iterations over seeds: mean speed (5-20 s), range, runs stuck (< 1 cm/s), seeds done.
import glob, os, collections, statistics as st
D = collections.defaultdict(dict)
for f in glob.glob("/home/claude/work/st5/*.txt"):
    b = os.path.basename(f)[:-4]; w, terr, fr, it, fx, s = b.rsplit("_", 5)
    xs = {}
    for l in open(f):
        if l.startswith("STALL"): p = l.split("|"); xs[int(p[0].split()[1])] = float(p[1].split()[1])
    if 20 in xs and 5 in xs: D[(w.replace("_", " "), fr, int(it))][int(s[1:])] = (xs[20] - xs[5]) / 15
for k in sorted(D, key=lambda k: (k[0], k[1], -k[2])):
    v = list(D[k].values())
    print(f"{k[0]:22s} friction {k[1]:3s} it {k[2]:4d}: seeds {len(v)}  mean {st.mean(v):5.2f}  range {min(v):5.2f}..{max(v):5.2f}  stuck {sum(x < 1 for x in v)}  | " + " ".join(f"s{s}:{D[k][s]:.2f}" for s in sorted(D[k])))
