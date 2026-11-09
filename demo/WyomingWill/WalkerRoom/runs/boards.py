#!/usr/bin/env python3
"""The viewer's ranking boards from run-table.sh's runs: python3 runs/boards.py runs/out-damp/warm40fast > lib/boards.lua
One board for each terrain and height (rounded to the cm; flat ground is "flat 0"): every build run there, best first,
its mean speed (cm/s, 5 s to 20 s) over its seeds, the standard error of that mean, and how many runs. Only builds named
on the command line after the folder, if any (default: every build found).
More folders before the names: each one's builds replace those builds' runs from the folders before it (9 November:
Klann and Spears 4-bar reversed, handover section 4w):
  python3 runs/boards.py runs/out-damp/warm40fast runs/out-reversed/warm40fast > lib/boards.lua"""
import sys, os, glob, re, math, statistics as st, collections
OLD_NAMES = {"Spears lift 44": "Chebyshev-Spears lift 51", "Spears lift 53": "Chebyshev-Spears lift 62",
             "Hoecken-Spears long-stance": "Hoecken-Spears 4-bar duty 85"}
def newName(n):
    for a, b in OLD_NAMES.items():
        if n == a or n == a + " diag": return b + n[len(a):]
    return n
dirs = [a for a in sys.argv[1:] if os.path.isdir(a)]
d, only = dirs[0], set(a for a in sys.argv[1:] if not os.path.isdir(a))
D = collections.defaultdict(lambda: collections.defaultdict(list))
for folder in dirs:
    runs = collections.defaultdict(lambda: collections.defaultdict(list))
    for f in glob.glob(os.path.join(folder, "*.txt")):
        m = re.search(r"^RUN (.*?)\|speed ([-\d.]+)", open(f).read(), re.M)
        if not m: continue
        name = newName(m.group(1))
        if only and name not in only: continue
        ter = os.path.basename(f)[:-4].rsplit("_", 2)[1]
        t = re.match(r"([a-z]+)([\d.]+)", ter); key = f"{t.group(1)} {round(float(t.group(2)))}"
        runs[key][name].append(float(m.group(2)))
    replaced = set(n for k in runs for n in runs[k])   # (this folder's builds: their runs from earlier folders go)
    for k in D:
        for n in replaced: D[k].pop(n, None)
    for k in runs:
        for n, v in runs[k].items(): D[k][n] = v
print("-- The viewer's ranking boards (made by runs/boards.py from " + ", then ".join(os.path.basename(os.path.dirname(x.rstrip('/'))) + "/" + os.path.basename(x.rstrip('/')) for x in dirs) + ":")
print("-- the fast setting, the 8 m track, normal ground, seeds 1-5; mean speed from 5 s to 20 s, cm/s)")
print("BOARDS = {")
for key in sorted(D, key=lambda k: (["flat", "waves", "random", "logs", "steps"].index(k.split()[0]), int(k.split()[1]))):
    rows = []
    for n, v in D[key].items():
        rows.append((st.mean(v), n, st.stdev(v) / math.sqrt(len(v)) if len(v) > 1 else 0.0, len(v)))
    rows.sort(reverse=True)
    print(f'  ["{key}"] = {{')
    for m, n, se, k in rows: print(f'    {{ "{n}", {m:.2f}, {se:.2f}, {k} }},')
    print("  },")
print("}")
