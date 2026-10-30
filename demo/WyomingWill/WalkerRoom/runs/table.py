#!/usr/bin/env python3
"""The tables from run-table.sh's runs: python3 runs/table.py runs/out/<setting> [runs/out/<setting> ...]
For each setting: every build's mean speed (cm/s) on each terrain over its seeds, the mean over the terrains, its
standard error (from the spread between seeds in each cell) and the mean over the hardest three (waves 6, logs 7,
steps 7), best first; then, with two settings or more, each build's change against the first and how the order
compares (rank correlation), and the time a run took."""
import sys, os, glob, re, math, statistics as st
OWN = {"Jansen", "Klann", "Spears 4-bar"}
def bracing(n): return "own" if n in OWN else ("outside, held" if n.endswith("diag") else "guides")
def load(d):
    D, times = {}, []
    for f in glob.glob(os.path.join(d, "*.txt")):
        txt = open(f).read(); m = re.search(r"^RUN (.*?)\|speed ([-\d.]+)", txt, re.M)
        t = re.search(r"^TIME (\d+)", txt, re.M)
        if t: times.append(int(t.group(1)))
        if not m: continue
        base = os.path.basename(f)[:-4]; build, ter, seed = base.rsplit("_", 2)
        D.setdefault(m.group(1), {}).setdefault(ter, []).append(float(m.group(2)))
    return D, times
def summary(D):
    terrains = sorted({t for b in D.values() for t in b}, key=lambda t: (["waves", "logs", "steps"].index(re.match(r"[a-z]+", t).group()), t))
    rows = []
    for n, cells in D.items():
        means = [st.mean(cells[t]) if t in cells else float("nan") for t in terrains]
        se = math.sqrt(sum(st.stdev(cells[t]) ** 2 / len(cells[t]) for t in terrains if t in cells and len(cells[t]) > 1)) / len(terrains)
        hard = [st.mean(cells[t]) for t in ("waves6", "logs7", "steps7") if t in cells]
        runs = sum(len(v) for v in cells.values())
        rows.append((st.mean([m for m in means if m == m]), n, means, se, st.mean(hard) if hard else float("nan"), runs))
    rows.sort(reverse=True)
    return terrains, rows
dirs = sys.argv[1:] or sorted(glob.glob("runs/out/*"))
res = []
for d in dirs:
    D, times = load(d); terrains, rows = summary(D); res.append((os.path.basename(d.rstrip("/")), rows, times))
    print(f"\n## {os.path.basename(d.rstrip('/'))}  ({sum(r[5] for r in rows)} runs; a run took {st.mean(times):.0f} s on average)\n" if times else f"\n## {d}\n")
    print("| Rank | Walker | Bracing | Timing | Direction | " + " | ".join(terrains) + " | Mean | ± | Hardest three | Runs |")
    print("|---|---|---|---|---|" + "---|" * (len(terrains) + 4))
    for k, (mean, n, means, se, hard, runs) in enumerate(rows, 1):
        print(f"| {k} | {n} | {bracing(n)} | trot | forward | " + " | ".join(f"{m:.2f}" for m in means) + f" | {mean:.2f} | {se:.2f} | {hard:.2f} | {runs} |")
if len(res) > 1:
    name0, rows0, _ = res[0]; ref = {r[1]: r for r in rows0}; rank0 = {r[1]: k for k, r in enumerate(rows0)}
    for name, rows, _ in res[1:]:
        print(f"\n## {name} against {name0}\n")
        print("| Walker | " + name0 + " | " + name + " | Change | ± (both) |"); print("|---|---|---|---|---|")
        ch = []
        for r in rows:
            if r[1] in ref:
                a = ref[r[1]]; d = r[0] - a[0]; ch.append(d)
                print(f"| {r[1]} | {a[0]:.2f} | {r[0]:.2f} | {d:+.2f} | {math.hypot(a[3], r[3]):.2f} |")
        common = [r[1] for r in rows if r[1] in rank0]
        if len(common) > 2:
            ra = {n: k for k, n in enumerate(sorted(common, key=lambda n: -ref[n][0]))}
            rb = {n: k for k, n in enumerate(sorted(common, key=lambda n: -[r for r in rows if r[1] == n][0][0]))}
            m = len(common); rho = 1 - 6 * sum((ra[n] - rb[n]) ** 2 for n in common) / (m * (m * m - 1))
            print(f"\nmean change {st.mean(ch):+.2f} cm/s, mean |change| {st.mean(abs(x) for x in ch):.2f}; rank correlation {rho:.2f}")
