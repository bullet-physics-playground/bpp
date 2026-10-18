import json, re, os, subprocess
D = "/home/claude/work/fac5"
pick = json.load(open(f"{D}/st2_pick.json"))
rows = {r["cid"]: r for r in json.loads(subprocess.run(["python3", f"{D}/an.py", "json"], capture_output=True, text=True).stdout)}
def mean(cid, t):
    f = f"{D}/t_{t}_{cid}.txt"
    if not os.path.exists(f): return None, None, 0
    v, a = [], []
    for l in open(f):
        m = re.search(r"\|([-\d.]+) cm/s", l)
        if m: v.append(float(m.group(1)))
        m = re.search(r"\|air ([\d.]+)%", l)
        if m: a.append(float(m.group(1)))
    return (sum(v) / len(v) if v else None), (sum(a) / len(a) if a else None), len(v)
out = []
for L, cids in pick.items():
    for cid in cids:
        r = rows[cid]; vals = [r["bump"]]; s = []
        for t in ("random", "logs", "steps"):
            m, a, n = mean(cid, t); vals.append(m); s.append((m, a, n))
        out.append((L, r, s, vals))
fmt = lambda x: "  -  " if x is None else f"{x:5.2f}"
for L, r, s, vals in sorted(out, key=lambda o: -sum(v for v in o[3] if v) / max(1, sum(1 for v in o[3] if v))):
    ok = [v for v in vals if v is not None]
    print(f"{L:27s} {r['brace']:6s} {r['timing']:5s} {r['dir']:3s} waves {fmt(r['bump'])} random {fmt(s[0][0])} logs {fmt(s[1][0])} steps {fmt(s[2][0])} mean {sum(ok)/len(ok):5.2f} n{[x[2] for x in s]} air {[None if x[1] is None else round(x[1]) for x in s]}")
