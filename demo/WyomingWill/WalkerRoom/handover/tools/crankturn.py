# How far each sweep's crank turned in its window: the most any link hinged to the body turned (unwrapped).
import sys, math, collections, glob
sys.path.insert(0, "/home/claude/work"); import topz
def turned(path):
    name, L, S, bb, hz = topz.load(path)
    G = [int(l.split()[1]) for l in open(path) if l.startswith("GROUND") and "Hinge" in l]
    n = min(len(S[i]) for i in L)
    best = 0
    for i in G:
        tot, prev = 0, None
        for k in range(n):
            c = list(S[i][k].exterior.coords)
            e = max(((c[q], c[q + 1]) for q in range(len(c) - 1)), key=lambda e: math.dist(*e))
            a = math.degrees(math.atan2(e[1][1] - e[0][1], e[1][0] - e[0][0]))
            if prev is not None: tot += (a - prev + 90) % 180 - 90
            prev = a
        best = max(best, abs(tot))
    return name, best
if __name__ == "__main__":
    for p in sorted(sys.argv[1:]):
        nm, t = turned(p); print(f"{nm:32s} crank turned {t:6.1f} deg")
