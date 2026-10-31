#!/usr/bin/env python3
# ft2/: the table (mean of seeds, speed 5-20 s) per build x terrain, sorted by the mean over the nine rough terrains;
# then, over the best build of each of the 12 walkers, the correlation of lift with speed per terrain.
import glob, os, collections, statistics as st
D = collections.defaultdict(lambda: collections.defaultdict(dict))
for f in glob.glob("/home/claude/work/ft2/*.txt"):
    b = os.path.basename(f)[:-4]; name, terr, s = b.rsplit("_", 2); name = name.replace("_", " ")
    xs = {}
    for l in open(f):
        if l.startswith("STALL"): p = l.split("|"); xs[int(p[0].split()[1])] = float(p[1].split()[1])
    if 20 in xs and 5 in xs: D[name][terr][int(s[1:])] = (xs[20] - xs[5]) / 15
T = ["flat", "waves2", "waves4", "waves6", "logs3", "logs5", "logs7", "steps3", "steps5", "steps7"]
OWN = {"Jansen", "Klann", "Spears 4-bar"}
def brace(n): return "own" if n in OWN else ("outside, held" if n.endswith("diag") else "guides")
def m(n, t): v = D[n].get(t, {}); return st.mean(v.values()) if v else None
rows = []
for n in D:
    ms = [m(n, t) for t in T]; rough = [x for x in ms[1:] if x is not None]
    rows.append((st.mean(rough) if rough else -9, n, ms, sum(len(D[n].get(t, {})) for t in T)))
rows.sort(reverse=True)
print("| Walker | Bracing | Timing | Direction | " + " | ".join(T) + " | Mean | Runs |")
print("|---|---|---|---|" + "---|" * (len(T) + 2))
for mean, n, ms, k in rows:
    print(f"| {n} | {brace(n)} | trot | forward | " + " | ".join("–" if x is None else f"{x:.2f}" for x in ms) + f" | {mean:.2f} | {k} |")
# spread between seeds
sp = [max(v.values()) - min(v.values()) for n in D for t in T for v in [D[n].get(t, {})] if len(v) > 1]
if sp: print(f"\nseed spread (max - min within a cell): mean {st.mean(sp):.2f}, max {max(sp):.2f}")

# best build of each walker (higher rough mean of its guides / diag builds)
LIFT = {"Chebyshev": (2.86, 73), "Chebyshev-Spears": (4.65, 82), "Hoecken slider": (3.70, 69), "Hoecken-Spears slider": (4.89, 82),
        "Hoecken 4-bar": (3.05, 68), "Hoecken-Spears 4-bar": (4.89, 76), "Jansen": (4.94, 54), "Klann": (7.84, 31), "Spears 4-bar": (5.58, 58),
        "Hoecken-Spears 4-bar duty 85": (5.18, 48), "Chebyshev-Spears lift 51": (7.71, 47), "Chebyshev-Spears lift 62": (9.28, 38)}
mean_of = {n: mean for mean, n, ms, k in rows}
best = {}
for w in LIFT:
    c = [n for n in (w, w + " diag") if n in mean_of]; best[w] = max(c, key=lambda n: mean_of[n])
def r(a, b):
    ma, mb = st.mean(a), st.mean(b); return sum((x - ma) * (y - mb) for x, y in zip(a, b)) / (sum((x - ma) ** 2 for x in a) * sum((y - mb) ** 2 for y in b)) ** .5
W = list(LIFT); L = [LIFT[w][0] for w in W]; Du = [LIFT[w][1] for w in W]
print("\nBest build of each walker: " + ", ".join(f"{w}: {best[w]}" for w in W))
print("\n| Terrain | Lift vs speed | Time flat vs speed |\n|---|---|---|")
for t in T[1:]:
    y = [m(best[w], t) for w in W]; print(f"| {t} | {r(L, y):.2f} | {r(Du, y):.2f} |")
hard = [st.mean([m(best[w], t) for t in ("waves6", "logs7", "steps7")]) for w in W]
rough = [mean_of[best[w]] for w in W]
print(f"| hardest three (waves 6, logs 7, steps 7) | {r(L, hard):.2f} | {r(Du, hard):.2f} |")
print(f"| mean of nine rough | {r(L, rough):.2f} | {r(Du, rough):.2f} |")
print("\nPairs (best build each): original -> Spears, mean of nine rough / hardest three")
for a, b in [("Chebyshev", "Chebyshev-Spears"), ("Hoecken slider", "Hoecken-Spears slider"), ("Hoecken 4-bar", "Hoecken-Spears 4-bar")]:
    ha = st.mean([m(best[a], t) for t in ("waves6", "logs7", "steps7")]); hb = st.mean([m(best[b], t) for t in ("waves6", "logs7", "steps7")])
    print(f"  {best[a]} {mean_of[best[a]]:.2f} / {ha:.2f} -> {best[b]} {mean_of[best[b]]:.2f} / {hb:.2f}")
