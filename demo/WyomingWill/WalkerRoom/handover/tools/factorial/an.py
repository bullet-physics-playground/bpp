# Factorial summary: per configuration, flat speed, mean speed on the 9 bump settings, share kept.
import re, glob, os, json, sys, collections
D = "/home/claude/work/fac5"
exec(open(f"{D}/run.py").read().split("def run(")[0])
cal = json.load(open(f"{D}/cal.json"))
rows = []
for cid, link, brace, timing, d, walker, extra in configs:
    f = f"{D}/{cid}.txt"
    if not os.path.exists(f): continue
    flat, bumps, seeds, fails = [], [], set(), 0
    airf, airb = [], []
    for l in open(f):
        if "FAILED" in l: fails += 1; continue
        m = re.search(r"\|height ([\d.]+)\|length ([\d.]+)\|seed (\d+)\|.*?\|(-?[\d.]+) cm/s", l)
        if not m: continue
        h, v = float(m.group(1)), float(m.group(4)); seeds.add(int(m.group(3)))
        (flat if h == 0 else bumps).append(v)
        a = re.search(r"\|air ([\d.]+)%", l)
        if a: (airf if h == 0 else airb).append(float(a.group(1)))
    if len(bumps) < 9: continue
    fl, bu = sum(flat) / len(flat), sum(bumps) / len(bumps)
    rows.append(dict(cid=cid, link=link, brace=brace, timing=timing, dir=d, flat=fl, bump=bu, share=100 * bu / fl, n=len(bumps), seeds=len(seeds), k=cal.get(cid, {}).get("k", float("nan")), fails=fails, airf=sum(airf)/len(airf) if airf else None, airb=sum(airb)/len(airb) if airb else None, flat1=cal.get(cid, {}).get("hist", [[1, float('nan')]])[0][1]))
mode = sys.argv[1] if len(sys.argv) > 1 else "all"
if mode == "json":
    print(json.dumps(rows))
elif mode == "all":
    by = collections.defaultdict(list)
    for r in rows: by[r["link"]].append(r)
    order = sorted(by, key=lambda L: -max(r["bump"] for r in by[L]))
    for L in order:
        print(f"\n{L}")
        print(f"  {'bracing':8s} {'timing':6s} {'dir':4s} {'crank x':>7s} {'flat':>5s} {'bumps':>6s} {'kept':>5s}  runs")
        for r in sorted(by[L], key=lambda r: -r["bump"]):
            print(f"  {r['brace']:8s} {r['timing']:6s} {r['dir']:4s} {r['k']:7.3f} {r['flat']:5.2f} {r['bump']:6.2f} {r['share']:4.0f}%  {r['n']}" + (f" FAILED {r['fails']}" if r['fails'] else ""))
else:
    best = {}
    for r in rows:
        if r["link"] not in best or r["bump"] > best[r["link"]]["bump"]: best[r["link"]] = r
    for r in sorted(best.values(), key=lambda r: -r["bump"]):
        print(f"{r['link']:28s} {r['brace']:7s} {r['timing']:6s} {r['dir']:4s} flat {r['flat']:5.2f} bumps {r['bump']:5.2f} kept {r['share']:3.0f}%")
