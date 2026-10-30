import re, statistics as st, os
exec(open("/home/claude/work/tips_an.py").read().split("def row")[0])
B = ["Spears lift 44", "Chebyshev-Spears diag", "Hoecken-Spears slider diag", "Jansen"]
def ref(b, t, s):
    if b == "Hoecken-Spears slider diag": return f"/home/claude/work/tips10/HSsd_{t}_s{s}.txt"
    return f"/home/claude/work/ft2/{b.replace(' ', '_')}_{t}_s{s}.txt"
def crank(f):
    for l in open(f):
        if l.startswith("TQ"): m = re.search(r"speed ([-\d.]+)-([-\d.]+)", l); return float(m.group(1)), float(m.group(2))
print("| Walker | Terrain | Plain 200, 1/3840 (seeds 1-3) | Warm 40, 1/3840 | Warm 40, 1/1920 |")
print("|---|---|---|---|---|")
D = {"3840": [], "1920": []}; M = {"ref": [], "3840": [], "1920": []}
for b in B:
    for t in ("waves4", "logs7", "steps7"):
        r = [sp(ref(b, t, s))[0] for s in (1, 2, 3)]; M["ref"].append(st.mean(r)); row = [f"{st.mean(r):.2f} ({' '.join('%.2f' % x for x in r)})"]
        for fx in ("3840", "1920"):
            fs = [f"/home/claude/work/wsr/{b.replace(' ', '_')}_{fx}_{t}_s{s}.txt" for s in (1, 2, 3)]
            if not all(os.path.exists(f) for f in fs): row.append("-"); continue
            v = [sp(f)[0] for f in fs]; M[fx].append(st.mean(v)); D[fx] += [st.mean(v) - st.mean(r)]
            row.append(f"{st.mean(v):.2f} ({' '.join('%.2f' % x for x in v)})")
        print(f"| {b} | {t} | " + " | ".join(row) + " |")
for fx in ("3840", "1920"):
    if D[fx]: print(f"warm 40 at 1/{fx}: mean change of cell means {st.mean(D[fx]):+.2f}, mean |change| {st.mean(abs(x) for x in D[fx]):.2f}; overall means ref {st.mean(M['ref'][:len(M[fx])]):.2f} vs {st.mean(M[fx]):.2f}")
