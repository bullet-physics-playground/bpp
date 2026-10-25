#!/usr/bin/env python3
"""Summarise headstand-times.sh: per seed, each size's time to come upright
("upright after", the exhibit's rule: within 15 deg for 2 s) and to come to
rest; then the median, quartiles and range per size.
usage: headstand-times.py DIR [DIR2]  (DIR2: a second set, e.g. the study-era script)"""
import re, sys, glob, statistics as st

SIZES = (("Green", "75%"), ("Red", "100%"), ("Yellow", "125%"))

def read(d):
    up = {k: {} for k, _ in SIZES}; rest = {k: {} for k, _ in SIZES}; bad = []
    for f in glob.glob(d + "/s*.out"):
        seed = int(re.search(r"s(\d+)\.out$", f).group(1))
        txt = open(f).read()
        for m in re.finditer(r"^\s+(Red|Green|Yellow)\s+upright after\s+([\d.]+) s", txt, re.M):
            up[m.group(1)].setdefault(seed, float(m.group(2)))
        for m in re.finditer(r"^\s+(Red|Green|Yellow)\s+at rest after\s+([\d.]+) s, ([\d.]+) deg(.*)$", txt, re.M):
            rest[m.group(1)][seed] = float(m.group(2))     # (the last report: a re-reported rest)
            if "NOT UPRIGHT" in m.group(4) or "touching" in m.group(4): bad.append((seed, m.group(1), m.group(4).strip()))
    return up, rest, bad

def q(x, p): return x[int(p * (len(x) - 1))]

for d in sys.argv[1:]:
    up, rest, bad = read(d)
    print("==", d)
    seeds = sorted(set().union(*[set(up[k]) for k, _ in SIZES]))
    print("seed  " + "  ".join("%-6s up / rest" % lab for _, lab in SIZES))
    for s in seeds:
        print("%4d  " % s + "  ".join("%6.2f / %6.2f   " % (up[k].get(s, float("nan")), rest[k].get(s, float("nan"))) for k, _ in SIZES).rstrip())
    for k, lab in SIZES:
        a, b = sorted(up[k].values()), sorted(rest[k].values())
        print("%-5s upright: n=%d median %.2f (quartiles %.2f-%.2f, range %.2f-%.2f); at rest: median %.2f (range %.2f-%.2f)"
              % (lab, len(a), st.median(a), q(a, .25), q(a, .75), a[0], a[-1], st.median(b), b[0], b[-1]))
    print("not upright or touching at rest:", bad or "none")
