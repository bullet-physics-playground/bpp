#!/usr/bin/env python3
"""Are a Galton board ball's choices independent?  (FINDINGS section 6)

    GB_PATHS=/tmp/p.txt GB_RUNS=4 bpp -f galton.lua -n 17400
    python3 paths.py /tmp/p.txt [more files ...]

Each line of a paths file is one ball: the gap it passed at each of the 12
levels halfway below a row of decisions, in half-pitches from the middle
(u = 2x/S). Below the k-th row a gap's u has the parity of k. A decision is
the change of u from one level to the next (u = 0 above the first row): +1
right, -1 left; +-3 a jumped pin.

For each file: the balls; P(same way as at the last pin), over all rows, at
the first pair alone and from the third row on; the correlation of decisions
1, 2 and 3 rows apart; the jumps; the mean bin and spread of the paths; and
the spread built up from its parts (the steps alone, then adding the first
pair's covariance, the later neighbours', and the farther ones'); and row
by row P(right) and the memory, P(right | right at the last pin) - P(right |
left at it), which is 0 for independent pins even where a pin favours a
side (pooled correlations mistake a row-to-row change in what pins favour
for memory).
Independent fair coins: 0.5, 0, 0, 0, no jumps, 6, 1.732.
"""
import math
import sys


def nearest(u, parity):
    n = round(u)
    if n % 2 != parity % 2:
        n += 1 if u > n else -1
    return n


def decisions(path):
    us = [0] + [nearest(u, k) for k, u in enumerate(path, 1)]
    return [us[k] - us[k - 1] for k in range(1, len(us))]


def corr(D, lag):
    xs = [(d[k - lag], d[k]) for d in D for k in range(lag, len(d))
          if abs(d[k - lag]) == 1 and abs(d[k]) == 1]
    ma = sum(a for a, _ in xs) / len(xs)
    mb = sum(b for _, b in xs) / len(xs)
    va = sum((a - ma) ** 2 for a, _ in xs) / len(xs)
    vb = sum((b - mb) ** 2 for _, b in xs) / len(xs)
    return sum((a - ma) * (b - mb) for a, b in xs) / len(xs) / math.sqrt(va * vb)


def report(name):
    D = [decisions(list(map(float, l.split()))) for l in open(name) if l.strip()]
    if not D:
        print(f"{name}: no paths")
        return
    n, R = len(D), len(D[0])
    same = sum(d[k] == d[k - 1] for d in D for k in range(1, R)) / (n * (R - 1))
    first = sum(d[1] == d[0] for d in D) / n
    later = sum(d[k] == d[k - 1] for d in D for k in range(2, R)) / (n * (R - 2))
    jumps = sum(abs(x) != 1 for d in D for x in d) / (n * R)
    fin = [sum(d) / 2 + R / 2 for d in D]
    m = sum(fin) / n
    mu = [sum(d[k] for d in D) / n for k in range(R)]
    C = [[sum((d[i] - mu[i]) * (d[j] - mu[j]) for d in D) / n for j in range(R)] for i in range(R)]
    steps = sum(C[i][i] for i in range(R))
    pair = 2 * C[0][1]
    near = 2 * sum(C[i][i + 1] for i in range(1, R - 1))
    total = sum(map(sum, C))
    sd = lambda v: math.sqrt(max(v, 0)) / 2
    print(f"{name}: {n} balls")
    print(f"  P(same way as at the last pin) {same:.3f} (+-{0.5 / math.sqrt(n * (R - 1)):.3f});"
          f" first pair {first:.2f}, from the third row {later:.3f}")
    print(f"  correlation 1, 2, 3 rows apart: {corr(D, 1):+.3f} {corr(D, 2):+.3f} {corr(D, 3):+.3f}"
          f" (+-{1 / math.sqrt(n * (R - 1)):.3f}); jumped pins {100 * jumps:.2f}%")
    # row by row: P(right), and the memory, P(right | right before) - P(right | left before),
    # which is 0 for independent pins whatever each one favours
    pr, mem = [], []
    for k in range(R):
        pr.append(sum(d[k] > 0 for d in D) / n)
        if k:
            a = [d[k] > 0 for d in D if d[k - 1] > 0]
            b = [d[k] > 0 for d in D if d[k - 1] < 0]
            if a and b:
                mem.append(sum(a) / len(a) - sum(b) / len(b))
    print("  P(right) row by row " + " ".join(f"{x:.2f}" for x in pr))
    print(f"  memory row by row (P(right | right) - P(right | left)) " + " ".join(f"{x:+.2f}" for x in mem)
          + f"; mean {sum(mem) / len(mem):+.3f} (+-{2 / math.sqrt(n * len(mem)):.3f})")
    print(f"  mean bin {m:.2f}, spread {sd(total):.3f}: the steps alone {sd(steps):.3f},"
          f" + the first pair {sd(steps + pair):.3f}, + later neighbours {sd(steps + pair + near):.3f},"
          f" + farther {sd(total):.3f}")


for f in sys.argv[1:]:
    report(f)
