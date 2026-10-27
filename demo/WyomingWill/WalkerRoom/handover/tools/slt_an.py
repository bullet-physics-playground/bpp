#!/usr/bin/env python3
# slt.sh's results: per walker and test, speed (flat; waves 4 seeds 1, 2 and their mean), the feet's jitter and the
# pendants' rocking (flat, waves 4 mean), and the slider joint's errors (waves 4 mean of the two runs).
import re, glob, collections, statistics as st
R = collections.defaultdict(dict)
for f in glob.glob("/home/claude/work/slt/*.txt"):
    t = open(f).read(); w, c, ter = re.match(r"(\w+?)_(\w+?)_(flat_s1|waves4_s\d)\.txt$", f.split("/")[-1]).groups()
    sp = re.search(r"\|([-\d.]+) cm/s", t); vib = re.search(r"jitter ([\d.]+) cm/s.*pend ([\d.]+) deg/s", t)
    sl = re.search(r"off mean ([\d.]+) max ([\d.]+)\|twist mean ([\d.]+) max ([\d.]+)\|drift mean ([\d.]+) max ([\d.]+)", t)
    R[(w, c)][ter] = dict(v=float(sp.group(1)), jit=float(vib.group(1)), pend=float(vib.group(2)), sl=tuple(map(float, sl.groups())) if sl else None)
NAME = {"HSS": "Hoecken-Spears slider", "HS": "Hoecken slider", "CS": "Chebyshev-Spears"}
TEST = {"base": "as run", "it200": "200 solver iterations", "6dof": "6-dof joint", "barhalf": "bar at half mass", "nodamp": "links undamped"}
print("| Walker | Test | Flat | Waves 4 s1 / s2 | Waves 4 mean | Feet jitter flat / waves 4 | Pendant rocking flat / waves 4 | Joint off (cm) / twist (deg), waves 4 mean, max |")
print("|---|---|---|---|---|---|---|---|")
for w in ("HSS", "HS", "CS"):
    for c in TEST:
        r = R.get((w, c))
        if not r: continue
        g = lambda k, f: f"{r[k][f]:.2f}" if k in r else "–"
        wv = [r[k]["v"] for k in ("waves4_s1", "waves4_s2") if k in r]
        wj = [r[k]["jit"] for k in ("waves4_s1", "waves4_s2") if k in r]; wp = [r[k]["pend"] for k in ("waves4_s1", "waves4_s2") if k in r]
        sls = [r[k]["sl"] for k in ("waves4_s1", "waves4_s2") if k in r and r[k]["sl"]]
        j = (f"{st.mean(s[0] for s in sls):.3f} ({max(s[1] for s in sls):.3f}) / {st.mean(s[2] for s in sls):.3f} ({max(s[3] for s in sls):.3f})") if sls else "–"
        print(f"| {NAME[w]} | {TEST[c]} | {g('flat_s1', 'v')} | {g('waves4_s1', 'v')} / {g('waves4_s2', 'v')} | {st.mean(wv):.2f} | "
              f"{g('flat_s1', 'jit')} / {st.mean(wj):.2f} | {g('flat_s1', 'pend')} / {st.mean(wp):.2f} | {j} |" if wv else f"| {NAME[w]} | {TEST[c]} | {g('flat_s1', 'v')} | – | – | – | – | – |")
