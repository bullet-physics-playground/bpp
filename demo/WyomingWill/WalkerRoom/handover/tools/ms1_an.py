#!/usr/bin/env python3
# ms1/: per build, flat speed from the STALL lines (x from 5 s to 20 s), and the torque line.
import re, glob
for f in sorted(glob.glob("/home/claude/work/ms1/*.txt")):
    t = open(f).read(); xs = {}
    for l in t.splitlines():
        if l.startswith("STALL"):
            p = l.split("|"); xs[int(p[0].split()[1])] = float(p[1].split()[1])
    sp = (xs[20] - xs[5]) / 15 if 20 in xs and 5 in xs else float("nan")
    m = re.search(r"torque median ([\d.]+) p95 ([\d.]+) max ([\d.]+)\|motor max [\d.]+\|speed ([-\d.]+)-([-\d.]+)", t)
    print(f"{f.split('/')[-1][:-4]:36s} speed {sp:5.2f} cm/s | torque median {m.group(1)} p95 {m.group(2)} max {m.group(3)} | cranks {m.group(4)}..{m.group(5)}" if m else f.split('/')[-1])
