#!/usr/bin/env python3
"""Swallowing walls against the exact mathematics (SPLITTERS.md).

    SP_ROWS=12 SP_WALL_L=2 SP_WALL_R=4 SP_CAUGHT=/tmp/c.txt SP_PATHS=/tmp/p.txt \\
        SP_BALLS=2000 bpp -f splitter-test.lua -n 76000
    python3 walls.py /tmp/c.txt /tmp/p.txt 12 2 [4]

Walls a places left and b places right of the start (b left out or 0: no
right wall). For independent fair pins the exact chances follow row by row
(each row, every place's chance splits half and half to its neighbours;
what reaches a wall is caught there). With one wall they are the classical
formulas: a ball is first caught after n rows with probability
(a/n) C(n, (n+a)/2) / 2^n (first passage), and a survivor of all N rows ends
at place u with probability [C(N, (N+u)/2) - C(N, (N+u+2a)/2)] / 2^N (the
reflection principle). With two, in the long run a ball leaves by the right
wall with probability a/(a+b) (gambler's ruin), after a*b rows on average.

Prints the counts against the exact ones, and a chi-square over the caught
rows on each side and the survivors' places (cells under 5 expected pooled).
"""
import sys

CHI1 = [6.6, 9.2, 11.3, 13.3, 15.1, 16.8, 18.5, 20.1, 21.7, 23.2, 24.7, 26.2,
        27.7, 29.1, 30.6, 32.0, 33.4, 34.8, 36.2, 37.6, 38.9, 40.3, 41.6, 43.0]


def nearest(u, parity):
    n = round(u)
    if n % 2 != parity % 2:
        n += 1 if u > n else -1
    return n


def exact(N, a, b):
    """Chances of being caught at each row on each side, and of each place after N rows."""
    p = {0: 1.0}
    left, right = {}, {}
    for n in range(1, N + 1):
        q = {}
        for u, w in p.items():
            for v in (u - 1, u + 1):
                q[v] = q.get(v, 0) + w / 2
        if a:
            left[n] = sum(w for v, w in q.items() if v <= -a)
        if b:
            right[n] = sum(w for v, w in q.items() if v >= b)
        p = {v: w for v, w in q.items() if (not a or v > -a) and (not b or v < b)}
    return left, right, p


def pooled(cells):
    """Merge cells under 5 expected into their neighbours, in order."""
    out, acc = [], None
    for lab, o, e in cells:
        if acc:
            acc = (acc[0] if "+" in acc[0] else acc[0] + "+", acc[1] + o, acc[2] + e)
        else:
            acc = (lab, o, e)
        if acc[2] >= 5:
            out.append(acc)
            acc = None
    if acc:
        if out:
            l, o, e = out.pop()
            out.append((l if "+" in l else l + "+", o + acc[1], e + acc[2]))
        else:
            out.append(acc)
    return out


def main(caught, paths, N, a, b=0):
    C = [tuple(map(int, l.split()[:2])) for l in open(caught) if l.strip()]
    F = []
    for l in open(paths):
        if l.strip():
            us = [nearest(float(u), k) for k, u in enumerate(l.split(), 1)]
            F.append(us[-1])
    n = len(C) + len(F)
    left, right, pile = exact(N, a, b)
    cl = [r for r, s in C if s < 0]
    cr = [r for r, s in C if s > 0]
    print(f"{n} balls; {N} rows; walls {a} places left" + (f" and {b} right" if b else "") + " of the start")
    sL, sR = sum(left.values()), sum(right.values())
    line = f"  caught left {len(cl)} (exact {n * sL:.0f})"
    if b:
        line += f", right {len(cr)} (exact {n * sR:.0f})"
    print(line + f", survived {len(F)} (exact {n * (1 - sL - sR):.0f})")
    if b:
        print(f"  of those caught, right: {len(cr) / max(1, len(C)):.3f} (exact {sR / (sL + sR):.3f} in {N} rows;"
              f" {a / (a + b):.3f} in the long run)")
    groups = []
    groups.append(("caught left at row", pooled([(str(k), cl.count(k), n * w) for k, w in sorted(left.items()) if w > 0])))
    if b:
        groups.append(("caught right at row", pooled([(str(k), cr.count(k), n * w) for k, w in sorted(right.items()) if w > 0])))
    groups.append(("survivors at place", pooled([(str(u), F.count(u), n * w) for u, w in sorted(pile.items()) if w > 0])))
    chi, df = 0, -1
    for name, cells in groups:
        print(f"  {name}: " + "  ".join(f"{l}: {o} ({e:.0f})" for l, o, e in cells))
        chi += sum((o - e) ** 2 / e for _, o, e in cells)
        df += len(cells)
    print(f"  chi-square {chi:.1f} on {df} degrees of freedom (1% level {CHI1[df - 1] if 0 < df <= len(CHI1) else '?'})")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4]), int(sys.argv[5]) if len(sys.argv) > 5 else 0)
