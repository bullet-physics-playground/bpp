import statistics as st, os
T = ["flat", "waves2", "waves4", "waves6", "logs3", "logs5", "logs7", "steps3", "steps5", "steps7"]
def sp(f):
    xs, slip = {}, []
    if not os.path.exists(f): return None
    for l in open(f):
        if l.startswith("STALL"):
            p = l.split("|"); xs[int(p[0].split()[1])] = float(p[1].split()[1])
            for q in p:
                if q.startswith("slip"): slip.append(float(q.split()[1]))
    if 20 not in xs or 5 not in xs: return None
    return (xs[20] - xs[5]) / 15, st.mean(slip[3:]) if len(slip) > 3 else float("nan")
def row(pref, d):
    out = []
    for t in T:
        v = [sp(f"/home/claude/work/{d}/{pref}_{t}_s{s}.txt") for s in (1, 2, 3)]; v = [x for x in v if x]
        out.append((st.mean(x[0] for x in v), st.mean(x[1] for x in v)) if v else None)
    return out
new = row("HSsd", "tips"); old = row("Hoecken-Spears_slider_diag", "ft2"); cs = row("Chebyshev-Spears_diag", "ft2")
csn = {t: [sp(f"/home/claude/work/tips/CSd_{t}_s{s}.txt") for s in (1, 2, 3)] for t in ("logs7", "steps7")}
print("terrain   slider flat feet  slider toes up   (slip flat / toes)   CS diag")
for t, a, b, c in zip(T, old, new, cs):
    if a and b: print(f"{t:8s}  {a[0]:6.2f}          {b[0]:6.2f}          ({a[1]:.2f} / {b[1]:.2f})          {c[0]:.2f}")
r = lambda r: st.mean(x[0] for x in r[1:] if x)
if all(new): print(f"mean of nine rough: slider flat feet {r(old):.2f}, toes up {r(new):.2f}; CS diag {r(cs):.2f}")
for t in ("logs7", "steps7"):
    v = [x for x in csn[t] if x]
    if v: print(f"CS diag with toes up, {t}: {st.mean(x[0] for x in v):.2f} ({' '.join('%.2f' % x[0] for x in v)})")
