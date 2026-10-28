#!/usr/bin/env python3
# st.sh's single-step tests: per walker and step height, how many of the 12 starts got a front foot on top, all four on
# top (within 20 s), the median time to get all four up, and the pushback after first touching the step.
import re, glob, collections, statistics as st
R = collections.defaultdict(list)
for f in glob.glob("/home/claude/work/st/*.txt"):
    t = open(f).read(); m = re.search(r"STEP ([^|]+)\|gap ([\d.]+)\|h ([\d.]+)\|first touch ([-\d.]+)\|a front foot on top ([-\d.]+)\|all four on top ([-\d.]+)\|pushed back ([\d.]+)\|body x end ([-\d.]+)", t)
    if not m: continue
    n, g, h, ft, fo, ao, pb, bx = m.groups()
    R[(n, h)].append((float(g), fo, ao, float(pb), float(bx)))
print("| Walker | Step | Starts | A front foot got on top | All four got on top | Median time, all four (s) | Pushed back after touching, median (cm) |")
print("|---|---|---|---|---|---|---|")
for (n, h), rows in sorted(R.items(), key=lambda kv: (kv[0][1], kv[0][0])):
    fo = sum(r[1] != "-" for r in rows); ao = [float(r[2]) for r in rows if r[2] != "-"]
    print(f"| {n} | {h} cm | {len(rows)} | {fo} | {len(ao)} | {st.median(ao):.1f} | {st.median(r[3] for r in rows):.1f} |" if ao else
          f"| {n} | {h} cm | {len(rows)} | {fo} | 0 | – | {st.median(r[3] for r in rows):.1f} |")
