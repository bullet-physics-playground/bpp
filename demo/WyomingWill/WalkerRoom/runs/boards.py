#!/usr/bin/env python3
"""The viewer's ranking boards from run-table.sh's runs: python3 runs/boards.py runs/out-damp/warm40fast > lib/boards.lua
One board for each terrain and height (rounded to the cm; flat ground is "flat 0"): every build run there, best first,
its mean speed (cm/s, 5 s to 20 s) over its seeds, the standard error of that mean, and how many runs. Only builds named
on the command line after the folders, if any (default: every build found).
More folders: each one's builds replace those builds' rows from what came before it (9 November: Klann and Spears
4-bar reversed, handover section 4w). What comes first may also be an earlier boards file (a .lua), so a few builds can
be run again without the rest (write to another file first: the shell empties the target before this reads it):
  python3 runs/boards.py lib/boards.lua runs/out-reversed/warm40fast > /tmp/boards.lua && mv /tmp/boards.lua lib/boards.lua
A folder or file that isn't there, or boards that come out empty, stop it with an error (and nothing on stdout)."""
import sys, os, glob, re, math, statistics as st, collections
OLD_NAMES = {"Spears lift 44": "Chebyshev-Spears lift 51", "Spears lift 53": "Chebyshev-Spears lift 62",
             "Hoecken-Spears long-stance": "Hoecken-Spears 4-bar duty 85"}
def newName(n):
    for a, b in OLD_NAMES.items():
        if n == a or n == a + " diag": return b + n[len(a):]
    return n
def fail(msg):
    sys.stderr.write("boards.py: " + msg + "\n"); sys.exit(1)
sources, only = [], set()
for a in sys.argv[1:]:
    if os.path.isdir(a) or (a.endswith(".lua") and os.path.isfile(a)): sources.append(a)
    elif "/" in a or a.endswith(".lua"): fail(f"no such folder or file: {a}")
    else: only.add(a)
if not sources: fail("give a folder of runs (or a boards .lua file) first")
rows = collections.defaultdict(dict)   # board -> build -> (mean, se, runs)
seeds_seen = set()                     # (the runs' seeds, for the header)
for src in sources:
    new = collections.defaultdict(dict)
    if src.endswith(".lua"):   # (an earlier boards file: its rows as they are)
        key = None
        for line in open(src):
            m = re.match(r'\s*\["(.*)"\] = \{', line)
            if m: key = m.group(1); continue
            m = re.match(r'\s*\{ "(.*?)", ([-\d.]+), ([-\d.]+), (\d+) \},', line)
            if m and key and (not only or m.group(1) in only):
                new[key][m.group(1)] = (float(m.group(2)), float(m.group(3)), int(m.group(4)))
    else:
        speeds = collections.defaultdict(lambda: collections.defaultdict(list))
        for f in glob.glob(os.path.join(src, "*.txt")):
            m = re.search(r"^RUN (.*?)\|speed ([-\d.]+)", open(f).read(), re.M)
            if not m: continue
            name = newName(m.group(1))
            if only and name not in only: continue
            ter, seed = os.path.basename(f)[:-4].rsplit("_", 2)[1:]
            seeds_seen.add(int(seed[1:]))
            t = re.match(r"([a-z]+)([\d.]+)", ter); key = f"{t.group(1)} {round(float(t.group(2)))}"
            speeds[key][name].append(float(m.group(2)))
        for key in speeds:
            for n, v in speeds[key].items():
                new[key][n] = (st.mean(v), st.stdev(v) / math.sqrt(len(v)) if len(v) > 1 else 0.0, len(v))
    if not new: fail(f"nothing found in {src}")
    replaced = set(n for k in new for n in new[k])   # (this source's builds: their rows from before go)
    for k in rows:
        for n in replaced: rows[k].pop(n, None)
    for k in new:
        rows[k].update(new[k])
if not any(rows.values()): fail("the boards came out empty")
def label(s):
    s = s.rstrip("/")
    return os.path.basename(s) if s.endswith(".lua") else os.path.basename(os.path.dirname(s)) + "/" + os.path.basename(s)
print("-- The viewer's ranking boards (made by runs/boards.py from " + ", then ".join(label(s) for s in sources) + ":")
def seed_list(ss):   # 1 2 3 5 -> "1-3, 5"
    out, run = [], []
    for x in sorted(ss):
        if run and x == run[-1] + 1: run.append(x)
        else:
            if run: out.append(f"{run[0]}-{run[-1]}" if len(run) > 1 else str(run[0]))
            run = [x]
    if run: out.append(f"{run[0]}-{run[-1]}" if len(run) > 1 else str(run[0]))
    return ", ".join(out)
seeds_text = ("seeds " + seed_list(seeds_seen)) if seeds_seen else "the seeds of the file it started from"
print("-- the fast setting, the 8 m track, normal ground, " + seeds_text + "; mean speed from 5 s to 20 s, cm/s)")
print("BOARDS = {")
for key in sorted(rows, key=lambda k: (["flat", "waves", "random", "logs", "steps"].index(k.split()[0]), int(k.split()[1]))):
    if not rows[key]: continue
    print(f'  ["{key}"] = {{')
    for n, (m, se, k) in sorted(rows[key].items(), key=lambda r: -r[1][0]):
        print(f'    {{ "{n}", {m:.2f}, {se:.2f}, {k} }},')
    print("  },")
print("}")
