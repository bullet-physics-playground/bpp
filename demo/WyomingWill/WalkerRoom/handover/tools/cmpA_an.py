#!/usr/bin/env python3
# Option A's results (cmpA.sh): per build and terrain, mean speed over the runs done (seeds x normal/mirrored) for each
# config, the change from base, and contacts that matter (slider crank against guide block, a body against links).
import re, glob, collections, statistics as st, sys
D = "/home/claude/work/cmpA"
R = collections.defaultdict(list); C = collections.defaultdict(set)
for f in glob.glob(f"{D}/*.txt"):
    t = open(f).read(); m = re.search(r"\|([-\d.]+) cm/s", t)
    if not m: continue
    b = f.split("/")[-1][:-4]
    name, cfg, ter, seed, ground = re.match(r"(.+)_(base|V|width|both)_(waves4|logs5)_s(\d)_(normal|mirrored)$", b).groups()
    R[(name, cfg, ter)].append(float(m.group(1)))
    c = re.search(r"CONTACTS [^|]*\|(.*)", t)
    if c:
        for p in c.group(1).split(", "):
            k = p.rsplit(" ", 1)[0]
            if "buildLinkage" in k or "body" in k: C[(name, cfg)].add(p)
names = sorted({k[0] for k in R}, key=lambda n: (("diag" in n), n))
for ter in ("waves4", "logs5"):
    print(f"\n{ter}: mean cm/s (runs); change from base")
    print("| Walker | Base | V | Width | Both |")
    print("|---|---|---|---|---|")
    for n in names:
        b = R.get((n, "base", ter))
        if not b: continue
        cells = [f"{st.mean(b):.2f} ({len(b)})"]
        for cfg in ("V", "width", "both"):
            r = R.get((n, cfg, ter))
            cells.append(f"{st.mean(r):.2f} ({len(r)}), {st.mean(r) - st.mean(b):+.2f}" if r else "–")
        print(f"| {n.replace('_', ' ')} | " + " | ".join(cells) + " |")
    for cfg in ("V", "width", "both"):
        d = [st.mean(R[(n, cfg, ter)]) - st.mean(R[(n, 'base', ter)]) for n in names if R.get((n, cfg, ter)) and R.get((n, 'base', ter))]
        if d: print(f"  {cfg}: mean change {st.mean(d):+.2f} over {len(d)} builds; better in {sum(x > 0 for x in d)}, worse in {sum(x < 0 for x in d)}")
if C:
    print("\nContacts to watch (slider guide block, body):")
    for k, v in sorted(C.items()): print(" ", k, sorted(v))
