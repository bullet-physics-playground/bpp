#!/usr/bin/env python3
"""A swallowing wall against the exact formulas (SPLITTERS.md).

    SP_ROWS=12 SP_WALL_L=2 SP_CAUGHT=/tmp/c.txt SP_PATHS=/tmp/p.txt \\
        SP_BALLS=3000 bpp -f splitter-test.lua -n 112000
    python3 walls.py /tmp/c.txt /tmp/p.txt 2 12

For independent fair pins and a wall a places to the left of the start:
a ball is first caught after n rows (n = a, a+2, ...) with probability
(a/n) C(n, (n+a)/2) / 2^n (first passage), and a ball that survives all N
rows ends at place u with probability [C(N, (N+u)/2) - C(N, (N+u+2a)/2)] / 2^N
(the reflection principle: the paths that touched the wall are the mirror
images of paths ending at -2a-u). Prints the counts against these, and a
chi-square over both (cells under 5 expected pooled).
"""
import sys
from math import comb

CHI1 = [6.6, 9.2, 11.3, 13.3, 15.1, 16.8, 18.5, 20.1, 21.7, 23.2, 24.7, 26.2,
        27.7, 29.1, 30.6, 32.0, 33.4, 34.8, 36.2, 37.6]   # chi-square, 1% level, 1-20 df


def nearest(u, parity):
    n = round(u)
    if n % 2 != parity % 2:
        n += 1 if u > n else -1
    return n


def main(caught, paths, a, N):
    C = [int(l.split()[0]) for l in open(caught) if l.strip()]
    F = []
    for l in open(paths):
        if l.strip():
            us = [nearest(float(u), k) for k, u in enumerate(l.split(), 1)]
            F.append(us[-1])
    n = len(C) + len(F)
    fp = {k: a / k * comb(k, (k + a) // 2) / 2 ** k for k in range(a, N + 1, 2)}
    pile = {}
    for u in range(-a + 2, N + 1, 2):
        km = (N + u + 2 * a) // 2
        pile[u] = (comb(N, (N + u) // 2) - (comb(N, km) if 0 <= km <= N else 0)) / 2 ** N
    print(f"{n} balls; wall {a} places left of the start; {N} rows")
    print(f"  caught {len(C)} (exact {n * sum(fp.values()):.0f}), survived {len(F)} (exact {n * (1 - sum(fp.values())):.0f})")
    cells = []
    for k, p in fp.items():
        cells.append((f"row {k}", C.count(k), n * p))
    big = [(u, p) for u, p in pile.items() if n * p >= 5]
    small = [u for u, p in pile.items() if n * p < 5]
    for u, p in big:
        cells.append((f"place {u}", F.count(u), n * p))
    if small:
        cells.append((f"place {small[0]}+", sum(F.count(u) for u in small), n * sum(pile[u] for u in small)))
    print("  caught at:  " + "  ".join(f"{c[0][4:]}: {c[1]} ({c[2]:.0f})" for c in cells if c[0].startswith("row")))
    print("  survivors:  " + "  ".join(f"{c[0][6:]}: {c[1]} ({c[2]:.0f})" for c in cells if c[0].startswith("place")))
    chi = sum((o - e) ** 2 / e for _, o, e in cells)
    df = len(cells) - 1
    print(f"  chi-square {chi:.1f} on {df} degrees of freedom (1% level {CHI1[df - 1] if df <= 20 else '?'})")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4]))
