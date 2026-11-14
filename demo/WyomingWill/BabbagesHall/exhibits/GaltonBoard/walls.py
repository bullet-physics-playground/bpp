#!/usr/bin/env python3
"""Swallowing walls against the exact mathematics (SPLITTERS.md).

    SP_ROWS=12 SP_WALL_L=2 SP_WALL_R=4 SP_CAUGHT=/tmp/c.txt SP_PATHS=/tmp/p.txt \\
        SP_BALLS=2000 bpp -f splitter-test.lua -n 76000
    python3 walls.py /tmp/c.txt /tmp/p.txt 12 2 [4]

    SP_ROWS=12 SP_REFL_L=3 SP_REFL_R=3 SP_PATHS=/tmp/p.txt ... bpp -f splitter-test.lua ...
    python3 walls.py - /tmp/p.txt 12 3r [3r]

Walls a places left and b places right of the start (b left out or 0: no
right wall). For independent fair pins the exact chances follow row by row
(each row, every place's chance splits half and half to its neighbours;
what reaches a wall is caught there). With one wall they are the classical
formulas: a ball is first caught after n rows with probability
(a/n) C(n, (n+a)/2) / 2^n (first passage), and a survivor of all N rows ends
at place u with probability [C(N, (N+u)/2) - C(N, (N+u+2a)/2)] / 2^N (the
reflection principle). With two, in the long run a ball leaves by the right
wall with probability a/(a+b) (gambler's ruin), after a*b rows on average.

A wall written with an r ("3r") reflects instead: a is then the outermost
place a ball can reach, and a ball there goes back inward for certain. No
ball is caught (the caught file may be "-"). With one reflecting wall at an
odd place, every survivor's place has its free binomial count plus its
mirror image's in the wall (the reflection principle the other way round);
with two, the pile goes flat as the rows go on. For reflecting walls it
also prints what balls did at the splitter after the wall: they should go
on inward half the time, as anywhere else.

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


def exact(N, a, b, ra=False, rb=False):
    """Chances of being caught at each row on each side, and of each place after N rows.
    ra, rb: the left, right wall reflects (a ball at -a, or b, goes back inward)."""
    p = {0: 1.0}
    left, right = {}, {}
    for n in range(1, N + 1):
        q = {}
        for u, w in p.items():
            if ra and a and u == -a:
                q[u + 1] = q.get(u + 1, 0) + w
                continue
            if rb and b and u == b:
                q[u - 1] = q.get(u - 1, 0) + w
                continue
            for v in (u - 1, u + 1):
                q[v] = q.get(v, 0) + w / 2
        if ra or rb:
            p = q
            continue
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


def wall(w):
    w = str(w)
    return (int(w[:-1]), True) if w.endswith("r") else (int(w), False)


def reflecting(paths, N, a, b):
    P = []
    for l in open(paths):
        if l.strip():
            P.append([nearest(float(u), k) for k, u in enumerate(l.split(), 1)])
    F = [us[-1] for us in P]
    n = len(F)
    _, _, pile = exact(N, a, b, bool(a), bool(b))
    print(f"{n} balls; {N} rows; reflecting walls at place " + (f"{-a}" if a else "") +
          (" and " if a and b else "") + (f"{b}" if b else "") + " (a ball there goes back)")
    bad = 0
    for us in P:
        prev = 0
        for u in us:
            if abs(u - prev) != 1 or (a and u < -a) or (b and u > b) or \
               (a and prev == -a and u != prev + 1) or (b and prev == b and u != prev - 1):
                bad += 1
                break
            prev = u
    print(f"  paths that broke the rules (a jump, past a wall, or not sent back): {bad}")
    # at the splitter after a wall: on inward, or back to the wall?
    for side, w in ((-1, a), (1, b)):
        if not w:
            continue
        c = side * w
        on = back = 0
        for us in P:
            path = [0] + us
            for k in range(len(path) - 2):
                if path[k] == c:
                    if path[k + 2] == c:
                        back += 1
                    else:
                        on += 1
        if on + back:
            print(f"  after the {'left' if side < 0 else 'right'} wall, at the next splitter: on inward {on}, back {back}"
                  f" ({on / (on + back):.3f} on; fair 0.5, +-{0.5 / (on + back) ** 0.5:.3f})")
    # every row's distribution against the exact one (a chi-square per row; the last is the pile)
    print("  survivors at place: " + "  ".join(f"{u}: {F.count(u)} ({n * w:.1f})" for u, w in sorted(pile.items()) if w > 0))
    cells = pooled([(str(u), F.count(u), n * w) for u, w in sorted(pile.items()) if w > 0])
    chi = sum((o - e) ** 2 / e for _, o, e in cells)
    df = len(cells) - 1
    print(f"  chi-square {chi:.1f} on {df} degrees of freedom (1% level {CHI1[df - 1] if 0 < df <= len(CHI1) else '?'})")
    tot, tdf = 0, 0
    for r in range(1, N + 1):
        _, _, pr = exact(r, a, b, bool(a), bool(b))
        cs = pooled([(str(u), sum(1 for us in P if us[r - 1] == u), n * w) for u, w in sorted(pr.items()) if w > 0])
        tot += sum((o - e) ** 2 / e for _, o, e in cs)
        tdf += len(cs) - 1
    print(f"  every row's places against the exact (summed, not independent): chi-square {tot:.1f} on {tdf}")


def main(caught, paths, N, a, b=0):
    (a, ra), (b, rb) = wall(a), wall(b)
    if ra or rb:
        assert (ra or not a) and (rb or not b), "walls.py: both walls reflect, or neither"
        return reflecting(paths, N, a, b)
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
    main(sys.argv[1], sys.argv[2], int(sys.argv[3]), sys.argv[4], sys.argv[5] if len(sys.argv) > 5 else 0)
