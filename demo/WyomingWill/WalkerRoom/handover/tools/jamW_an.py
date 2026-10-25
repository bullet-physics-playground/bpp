#!/usr/bin/env python3
# jamW.py's results: per build, the most its own parts touched each other (share of frames, worst of the four grounds),
# by which kinds, the body on the ground, and the slider crank against its guide block (makeLink-buildLinkage).
import glob, re, sys, collections
D = sys.argv[1] if len(sys.argv) > 1 else "/home/claude/work/jamW"
R = collections.defaultdict(list)
for f in sorted(glob.glob(f"{D}/*.txt")):
    t = open(f).read(); m = re.search(r"SELF ([^|]+)\|amp \S+\|touching ([\d.]+)% of frames\|impulse [\d.]+\|(.*)\|bodyground ([\d.]+)%", t)
    s = re.search(r"\|([-\d.]+) cm/s", t)
    if not m: R[f.split("/")[-1]].append(None); continue
    R[m.group(1)].append((f.split("_")[-1][:-4], float(m.group(2)), m.group(3), float(m.group(4)), float(s.group(1)) if s else None))
for n, rows in R.items():
    rows = [r for r in rows if r]
    worst = max(rows, key=lambda r: r[1])
    pairs = collections.Counter()
    for r in rows:
        for p in r[2].split(", "):
            if p.strip(): k, c = p.rsplit(" ", 1); pairs[k] += int(c)
    print(f"{n:32s} touching up to {worst[1]:4.1f}% ({worst[0]}); body on ground up to {max(r[3] for r in rows):4.1f}%; "
          f"speeds {' '.join(f'{r[0]} {r[4]:.2f}' for r in rows)}; pairs (frames) {dict(pairs.most_common(4))}")
