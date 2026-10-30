import re, statistics as st, os
exec(open("/home/claude/work/tips_an.py").read().split("def row")[0])
B = ["Spears lift 44", "Chebyshev-Spears diag", "Hoecken-Spears slider diag", "Jansen"]
def ref(b, t, s):
    if b == "Hoecken-Spears slider diag": return f"tips10/HSsd_{t}_s{s}.txt"
    return f"ft2/{b.replace(' ', '_')}_{t}_s{s}.txt"
def tq(f):
    for l in open(f):
        if l.startswith("TQ"):
            m = re.search(r"speed ([-\d.]+)-([-\d.]+)", l); return float(m.group(1)), float(m.group(2))
def tm(f):
    for l in open(f):
        if l.startswith("TIME"): return float(l.split()[1])
print("| Walker | Terrain | 1/3840 s (seeds 1, 2) | 1/1920 s | 1/960 s | crank speed 3840 / 1920 / 960 |")
print("|---|---|---|---|---|---|")
dif = {"1920": [], "960": []}; T = {"1920": [], "960": []}
for b in B:
    for t in ("flat", "waves4", "logs7"):
        r = [sp("/home/claude/work/" + ref(b, t, s)) for s in (1, 2)]
        row = [f"{r[0][0]:.2f}, {r[1][0]:.2f}"]; cr = [tq("/home/claude/work/" + ref(b, t, 1))]
        for fn in ("1920", "960"):
            fs = [f"/home/claude/work/stp/{b.replace(' ', '_')}_{fn}_{t}_s{s}.txt" for s in (1, 2)]
            if not all(os.path.exists(f) for f in fs): row.append("-"); cr.append(None); continue
            v = [sp(f) for f in fs]; row.append(f"{v[0][0]:.2f}, {v[1][0]:.2f}"); cr.append(tq(fs[0]))
            dif[fn] += [v[i][0] - r[i][0] for i in (0, 1)]; T[fn] += [tm(f) for f in fs]
        print(f"| {b} | {t} | " + " | ".join(row) + " | " + " / ".join(f"{c[0]:.2f}-{c[1]:.2f}" if c else "-" for c in cr) + " |")
for fn in ("1920", "960"):
    if dif[fn]: print(f"1/{fn}: mean change {st.mean(dif[fn]):+.2f} cm/s, mean |change| {st.mean(abs(x) for x in dif[fn]):.2f}; time per 20 s run {st.mean(T[fn]):.0f} s")
