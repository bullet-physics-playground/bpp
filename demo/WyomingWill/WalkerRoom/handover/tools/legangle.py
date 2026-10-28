#!/usr/bin/env python3
# From sweepT/ (trot sweeps, body held, one crank turn): for one foot of each build, the link it hangs from (its
# pendant) through the turn: its lean from vertical (bottom ahead of top = +, toward the walk) against where the foot
# is along its path. The walk is toward +x in the sweeps (geo.py's convention: front = larger x). Writes legangle.png.
import sys, math, collections
import matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt
def load(path):
    L, S = {}, collections.defaultdict(list)
    for l in open(path):
        if l.startswith("LINK"):
            p = l.strip().split("|"); L[int(p[0].split()[1])] = dict(kind=p[4].split()[1], z=float(p[1].split()[1]))
        elif l.startswith("S "):
            _, k, pts = l.split(" ", 2); S[int(k)].append([tuple(map(float, q.split(","))) for q in pts.strip().split(";")])
    return L, S
def ends(poly):
    best = (0, None)
    for i in range(len(poly)):
        for j in range(i + 1, len(poly)):
            d = math.dist(poly[i], poly[j])
            if d > best[0]: best = (d, (poly[i], poly[j]))
    return best[1]
B = sys.argv[1:] or ["Chebyshev-Spears", "Hoecken-Spears_slider", "Chebyshev", "Hoecken_slider"]
fig, axs = plt.subplots(1, 2, figsize=(12, 4.6))
for b in B:
    L, S = load(f"/home/claude/work/sweepT/{b}.txt")
    feet = [i for i in L if L[i]["kind"] == "buildFoot"]
    f = max(feet, key=lambda i: (L[i]["z"], S[i][0][0][0]))   # a near-side foot
    n = len(S[f])
    fc = lambda k: (sum(p[0] for p in S[f][k]) / len(S[f][k]), sum(p[1] for p in S[f][k]) / len(S[f][k]))
    links = [i for i in L if L[i]["kind"] in ("makeLink",)]
    # the pendant: the link with an end nearest the foot over the turn
    pend = min(links, key=lambda i: sum(min(math.dist(p, fc(k)) for p in S[i][k]) for k in range(0, n, 10)))
    X, Y, A = [], [], []
    for k in range(n):
        a, c = ends(S[pend][k]); lo, hi = (a, c) if a[1] < c[1] else (c, a)
        A.append(math.degrees(math.atan2(lo[0] - hi[0], hi[1] - lo[1])))
        x, y = fc(k); X.append(x); Y.append(min(p[1] for p in S[f][k]))
    x0 = min(X); ymin = min(Y)
    X = [x - x0 for x in X]; Y = [y - ymin for y in Y]
    front = [A[k] for k in range(n) if X[k] > max(X) - 2.5 and Y[k] < 3]
    print(f"{b:24s} pendant lean through the turn {min(A):6.1f} to {max(A):6.1f} deg; near the front of the path (last 2.5 cm, under 3 cm up): {min(front):.1f} to {max(front):.1f}" if front else b)
    axs[0].plot(X, A, label=b.replace("_", " "), lw=1.6 if "Spears" in b else 1.1, ls="-" if "Spears" in b else "--")
    sc = axs[1].plot(X, Y, label=b.replace("_", " "), lw=1.6 if "Spears" in b else 1.1, ls="-" if "Spears" in b else "--")
axs[0].axhline(0, color="#999", lw=0.8)
axs[0].set_xlabel("foot along its path (cm; walking toward +)"); axs[0].set_ylabel("foot link's lean from vertical (deg; bottom ahead +)")
axs[0].set_title("How the foot link leans, by where the foot is", fontsize=10); axs[0].legend(fontsize=8)
axs[1].set_xlabel("foot along its path (cm)"); axs[1].set_ylabel("foot bottom height (cm)"); axs[1].set_aspect("equal")
axs[1].set_title("The foot's path as built (body held)", fontsize=10)
fig.tight_layout(); fig.savefig("/home/claude/work/legangle.png", dpi=100)
