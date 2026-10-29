# The overnight table: 5 seeds (ft2/ seeds 1-3 + n5/ seeds 4-5; toe versions from tips10/, toes/, n5/), nine rough.
import statistics as st, os, math
exec(open("/home/claude/work/tips_an.py").read().split("def row")[0])
TER = ["waves2", "waves4", "waves6", "logs3", "logs5", "logs7", "steps3", "steps5", "steps7"]
def fn(n): return n.replace(" ", "_")
def get(build, toes, t, s):
    cands = []
    if not toes: cands = [f"ft2/{fn(build)}_{t}_s{s}.txt", f"n5/{fn(build)}_{t}_s{s}.txt"]
    elif build == "Hoecken-Spears slider diag": cands = [f"tips10/HSsd_{t}_s{s}.txt", f"n5/{fn(build)}_{t}_s{s}.txt"]
    elif build == "Hoecken-Spears slider": cands = [f"n5/Hoecken-Spears_slider_toes_{t}_s{s}.txt"]
    else: cands = [f"toes/{fn(build)}_{t}_s{s}.txt", f"n5/{fn(build)}_toes_{t}_s{s}.txt"]
    for c in cands:
        r = sp("/home/claude/work/" + c)
        if r: return r[0]
    return None
ROWS = [("Spears lift 44", 0), ("Spears lift 44 diag", 0), ("Spears lift 53", 0), ("Hoecken-Spears 4-bar diag", 0), ("Spears lift 53 diag", 0),
        ("Spears lift 53 diag", 1), ("Chebyshev-Spears diag", 0), ("Chebyshev-Spears diag", 1), ("Hoecken-Spears long-stance diag", 0),
        ("Hoecken-Spears slider diag", 1), ("Hoecken-Spears slider", 1), ("Hoecken-Spears 4-bar", 0), ("Jansen", 0), ("Jansen", 1), ("Klann", 0),
        ("Hoecken-Spears long-stance", 0), ("Hoecken-Spears long-stance", 1)]
OWN = {"Jansen", "Klann", "Spears 4-bar"}
out = []
for b, toes in ROWS:
    cells = []; runs = 0; allv = []
    for t in TER:
        v = [get(b, toes, t, s) for s in range(1, 6)]; v = [x for x in v if x is not None]; runs += len(v)
        cells.append(st.mean(v) if v else float("nan")); allv.append(v)
    mean = st.mean(cells)
    # standard error of the nine-terrain mean: from the seed spread in each cell
    se = math.sqrt(sum((st.stdev(v) ** 2 / len(v)) if len(v) > 1 else 0 for v in allv)) / len(TER)
    hard = st.mean([cells[2], cells[5], cells[8]])
    out.append((mean, b, toes, cells, runs, se, hard))
out.sort(reverse=True)
print("| Rank | Walker | Bracing | Timing | Direction | Feet | " + " | ".join(TER) + " | Nine rough | ± | Hardest three | Runs |")
print("|---|---|---|---|---|---|" + "---|" * (len(TER) + 4))
for k, (mean, b, toes, cells, runs, se, hard) in enumerate(out, 1):
    br = "own" if b in OWN else ("outside, held" if b.endswith("diag") else "guides")
    print(f"| {k} | {b} | {br} | trot | forward | {'toes 1.0 cm' if toes else 'flat'} | " + " | ".join(f"{c:.2f}" for c in cells) + f" | {mean:.2f} | {se:.2f} | {hard:.2f} | {runs} |")
