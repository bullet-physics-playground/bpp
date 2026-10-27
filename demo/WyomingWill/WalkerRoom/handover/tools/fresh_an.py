#!/usr/bin/env python3
# fresh.sh's table: mean cm/s per build and terrain (runs so far), highest log and step cleared (mean >= 2 cm/s).
import re, glob, collections, statistics as st
R = collections.defaultdict(list)
for f in glob.glob("/home/claude/work/fresh/*.txt"):
    m = re.search(r"\|([-\d.]+) cm/s", open(f).read())
    if not m: continue
    name, ter, s = re.match(r"(.+)_(flat|waves\d|logs\d|steps\d)_s(\d)\.txt$", f.split("/")[-1]).groups()
    R[(name.replace("_", " "), ter)].append(float(m.group(1)))
TER = ["flat", "waves2", "waves4", "waves6", "logs3", "logs5", "logs7", "steps3", "steps5", "steps7"]
OWN = ["Jansen", "Klann", "Spears 4-bar"]
names = sorted({k[0] for k in R}, key=lambda n: (n not in OWN, n.replace(" diag", ""), "diag" in n))
print("| Walker | Bracing | Timing | Direction | Flat | Waves 2 | Waves 4 | Waves 6 | Logs 3 | Logs 5 | Logs 7 | Steps 3 | Steps 5 | Steps 7 | Mean (no flat) |")
print("|---|---|---|---|" + "---|" * 11)
for n in names:
    br = "own" if n in OWN else ("outside, held" if "diag" in n else "guides")
    c, ms = [], []
    for t in TER:
        r = R.get((n, t))
        if r: c.append(f"{st.mean(r):.2f}" + ("" if len(r) == 2 else f" ({len(r)})")); ms += [st.mean(r)] if t != "flat" else []
        else: c.append("–")
    print(f"| {n} | {br} | trot | forward | " + " | ".join(c) + (f" | {st.mean(ms):.2f} |" if ms else " | – |"))
print(f"\n{sum(len(v) for v in R.values())} of 380 runs")
