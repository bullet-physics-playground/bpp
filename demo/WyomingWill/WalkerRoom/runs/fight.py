#!/usr/bin/env python3
"""The FIGHT lines of runs/fightprobe.lua runs (run-table.sh with PROBE=runs/fightprobe.lua), per build: means over
its runs, and over the hardest three terrains (waves 6, logs 7, steps 7). Handover section 4y.

  python3 runs/fight.py runs/out-fight/warm40fast
"""
import glob, os, re, sys
from collections import defaultdict

HARD = {"waves6", "logs7", "steps7"}
rows = defaultdict(list)
for f in glob.glob(os.path.join(sys.argv[1], "*.txt")):
    m = re.match(r"(.+)_([a-z]+\d+)_s(\d+)\.txt$", os.path.basename(f))
    if not m:
        continue
    name, ter = m.group(1).replace("_", " "), m.group(2)
    txt = open(f).read()
    r = re.search(r"^RUN .*\|speed ([-\d.]+)", txt, re.M)
    g = re.search(r"^FIGHT [^|]*\|opposed ([\d.]+)\|fight mean ([\d.]+) p95 ([\d.]+)\|pair mean ([\d.]+)\|work \+ ([\d.]+) - ([\d.]+)"
                  r"\|capped ([\d.]+)\|fight when capped ([\d.]+) of the cap \((\d+)\)\|nudge gap ([\d.]+)\|angle gap ([-\d.]+)\.\.([-\d.]+)", txt, re.M)
    if not (r and g):
        continue
    v = [float(x) for x in g.groups()]
    rows[name].append(dict(ter=ter, speed=float(r.group(1)), opp=v[0], fm=v[1], f95=v[2], pair=v[3], cap=v[6],
                           fcap=v[7], ncap=v[8], gap=max(abs(v[10]), abs(v[11]))))

def mean(xs):
    return sum(xs) / len(xs) if xs else float("nan")

print("| Walker | Bracing | Timing | Direction | Runs | Opposed | Fight / pair torque (all) | (hardest three) | Fight p95 / cap | Motor at cap | Fight when at cap / cap | Pair's cranks apart, most (deg) |")
print("|---|---|---|---|---|---|---|---|---|---|---|---|")
for name in sorted(rows, key=lambda n: -mean([r["speed"] for r in rows[n]])):
    rs = rows[name]
    hs = [r for r in rs if r["ter"] in HARD]
    ratio = lambda xs: sum(r["fm"] for r in xs) / max(1e-12, sum(r["pair"] for r in xs))
    nc = sum(r["ncap"] for r in rs)
    fcap = sum(r["fcap"] * r["ncap"] for r in rs) / nc if nc else 0
    print(f"| {name} | outside, held | trot | forward | {len(rs)} | {mean([r['opp'] for r in rs]):.1%} | {ratio(rs):.1%} | {ratio(hs):.1%} "
          f"| {mean([r['f95'] for r in rs]) / 0.5:.1%} | {mean([r['cap'] for r in rs]):.1%} | {fcap:.1%} | {max(r['gap'] for r in rs):.1f} |")
