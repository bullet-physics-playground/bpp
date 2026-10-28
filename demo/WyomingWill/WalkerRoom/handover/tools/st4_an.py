#!/usr/bin/env python3
import re, glob, os, collections
rows = collections.defaultdict(dict)
files = sorted(glob.glob("/home/claude/work/st4/*.txt"), key=os.path.getmtime)
prev = None; tm = {}
for f in files:   # wall time per run: two run at once, so each pair's finish minus the previous pair's
    m = os.path.getmtime(f); tm[f] = m
for f in files:
    tag = os.path.basename(f)[:-4]; w, terr, fr, it, fx = tag.rsplit("_", 4)
    t = open(f).read(); xs = {}
    for l in t.splitlines():
        if l.startswith("STALL"): p = l.split("|"); xs[int(p[0].split()[1])] = float(p[1].split()[1])
    m = re.search(r"torque median ([\d.]+) p95 ([\d.]+) max ([\d.]+)\|motor max [\d.]+\|speed ([-\d.]+)-([-\d.]+)", t)
    sp = (xs.get(20, float("nan")) - xs.get(5, float("nan"))) / 15
    rows[(w, terr, fr)][(int(it), fx)] = (sp, xs.get(20, float("nan")), m.groups() if m else None)
order = [(1000, "3840"), (1000, "1920"), (400, "3840"), (200, "3840"), (100, "3840"), (40, "3840")]
for k in sorted(rows):
    print(f"\n{k[0].replace('_',' ')} | {k[1]} | friction {k[2]}")
    for o in order:
        if o in rows[k]:
            sp, x, g = rows[k][o]
            print(f"  it {o[0]:4d} step 1/{o[1]}: speed {sp:5.2f} cm/s  x20 {x:6.1f}  torque p95 {g[1] if g else '-'} max {g[2] if g else '-'}  cranks {g[3]+'..'+g[4] if g else '-'}")
