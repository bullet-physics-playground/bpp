#!/usr/bin/env python3
"""How two sets of ranking boards compare (11 November: the boards without wheels and with, SHOES):
  python3 runs/compare-boards.py before.lua after.lua
Each a boards file (runs/boards.py's output). For each ground both have: the rank correlation of the two orders
(Spearman's rho: 1 = the same order), the walkers that moved and how far, and the mean speed change. Then each
walker's mean rank and speed change over all grounds, and the order by mean rank before and after."""
import sys, re, statistics as st

def load(path):
    boards, key = {}, None
    for line in open(path):
        m = re.match(r'\s*\["(.*)"\] = \{', line)
        if m:
            key = m.group(1); boards[key] = []; continue
        m = re.match(r'\s*\{ "(.*?)", ([-\d.]+), ([-\d.]+), (\d+) \},', line)
        if m and key: boards[key].append((m.group(1), float(m.group(2))))
    return boards

def ranks(rows):
    order = sorted(rows, key=lambda r: -r[1])
    return {n: i + 1 for i, (n, _) in enumerate(order)}, dict(rows)

def spearman(a, b):
    names = sorted(set(a) & set(b)); n = len(names)
    if n < 3: return float("nan")
    d2 = sum((a[k] - b[k]) ** 2 for k in names)
    return 1 - 6 * d2 / (n * (n * n - 1))

if len(sys.argv) != 3: sys.exit(__doc__)
A, B = load(sys.argv[1]), load(sys.argv[2])
keys = [k for k in A if k in B]
print(f"| Ground | Rank correlation | Moved 2 or more places | Mean speed change |\n| --- | --- | --- | --- |")
per = {}
rhos = []
for k in keys:
    ra, sa = ranks(A[k]); rb, sb = ranks(B[k])
    names = sorted(set(ra) & set(rb))
    rho = spearman({n: ra[n] for n in names}, {n: rb[n] for n in names}); rhos.append(rho)
    moved = sorted(((rb[n] - ra[n], n) for n in names if abs(rb[n] - ra[n]) >= 2), key=lambda m: -abs(m[0]))
    dv = st.mean(sb[n] - sa[n] for n in names)
    for n in names:
        p = per.setdefault(n, [[], [], [], []]); p[0].append(ra[n]); p[1].append(rb[n]); p[2].append(sb[n] - sa[n]); p[3].append(sa[n])
    mv = ", ".join(f"{n} {ra[n]}→{rb[n]}" for _, n in moved) or "none"
    print(f"| {k} | {rho:.2f} | {mv} | {dv:+.2f} cm/s |")
print(f"\nMean rank correlation over {len(keys)} grounds: {st.mean(rhos):.2f} (lowest {min(rhos):.2f})\n")
print("| Walker | Mean rank before | Mean rank after | Mean speed before | Mean speed change |\n| --- | --- | --- | --- | --- |")
for n, (a, b, d, s) in sorted(per.items(), key=lambda kv: st.mean(kv[1][0])):
    print(f"| {n} | {st.mean(a):.1f} | {st.mean(b):.1f} | {st.mean(s):.2f} | {st.mean(d):+.2f} |")
before = [n for n, _ in sorted(per.items(), key=lambda kv: st.mean(kv[1][0]))]
after = [n for n, _ in sorted(per.items(), key=lambda kv: st.mean(kv[1][1]))]
print("\nOrder by mean rank, before: " + ", ".join(before))
print("Order by mean rank, after:  " + ", ".join(after))
