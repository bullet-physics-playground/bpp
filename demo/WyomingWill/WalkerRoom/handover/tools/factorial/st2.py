# Stage 2: top 2 configurations per linkage (waves) on random, logs and steps.
import os, sys, json
D = "/home/claude/work/fac5"
src = open(f"{D}/run.py").read()
exec(src.split("pool = ThreadPoolExecutor")[0])   # configs, run, speed
from concurrent.futures import ThreadPoolExecutor
pool = ThreadPoolExecutor(2)
cal = json.load(open(f"{D}/cal.json"))
import subprocess
rows = json.loads(subprocess.run([sys.executable, f"{D}/an.py", "json"], capture_output=True, text=True).stdout)
pick = {}
for r in sorted(rows, key=lambda r: -r["bump"]):
    pick.setdefault(r["link"], [])
    if len(pick[r["link"]]) < 2: pick[r["link"]].append(r["cid"])
chosen = [c for L in pick for c in pick[L]]
json.dump(pick, open(f"{D}/st2_pick.json", "w"), indent=1)
CONDS2 = [(2, 11), (2, 22), (4, 11), (4, 22), (6, 11), (6, 22)]
for t in ("random", "logs", "steps"):
    for cid, link, brace, timing, d, walker, extra in configs:
        if cid not in chosen: continue
        k = cal[cid]["k"]; e = "; ".join(x for x in (extra, f'TERRAIN="{t}"') if x)
        of = f"{D}/t_{t}_{cid}.txt"
        done = open(of).read() if os.path.exists(of) else ""
        todo = [(a, b, s) for a, b in CONDS2 for s in (1, 2) if f"|height {a:.2f}|length {b:.1f}|seed {s}|" not in done]
        with open(of, "a") as f:
            for line in pool.map(lambda x: run(walker, e, x[0], x[1], x[2], k), todo):
                f.write(line + "\n"); f.flush()
print("ST2 DONE", flush=True)
