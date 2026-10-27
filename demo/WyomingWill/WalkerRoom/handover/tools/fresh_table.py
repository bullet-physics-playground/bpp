#!/usr/bin/env python3
# The fresh table (fresh.sh) with the two sliders from fresh6d.sh (SLIDER_6DOF): mean of seeds 1-2, cm/s, sorted by
# the mean over the nine rough terrains (flat left out). Markdown on stdout.
import re, glob, collections, statistics as st
R = collections.defaultdict(list)
for d in ("fresh", "fresh6d"):
    for f in glob.glob(f"/home/claude/work/{d}/*.txt"):
        m = re.search(r"\|([-\d.]+) cm/s", open(f).read())
        n, t, s = re.match(r"(.+)_(flat|waves\d|logs\d|steps\d)_s(\d)\.txt$", f.split("/")[-1]).groups()
        n = n.replace("_", " ")
        if d == "fresh" and "slider" in n: continue
        R[(n, t)].append(float(m.group(1)))
TER = ["flat", "waves2", "waves4", "waves6", "logs3", "logs5", "logs7", "steps3", "steps5", "steps7"]
OWN = ["Jansen", "Klann", "Spears 4-bar"]
rows = []
for n in {k[0] for k in R}:
    c = [st.mean(R[(n, t)]) for t in TER]
    br = "own" if n in OWN else ("outside, held" if "diag" in n else "guides")
    rows.append((st.mean(c[1:]), n, br, c))
print("| Walker | Bracing | Timing | Direction | Flat | Waves 2 | Waves 4 | Waves 6 | Logs 3 | Logs 5 | Logs 7 | Steps 3 | Steps 5 | Steps 7 | Mean |")
print("|---|---|---|---|" + "---|" * 11)
for m, n, br, c in sorted(rows, reverse=True):
    print(f"| {n} | {br} | trot | forward | " + " | ".join(f"{x:.2f}" for x in c) + f" | {m:.2f} |")
