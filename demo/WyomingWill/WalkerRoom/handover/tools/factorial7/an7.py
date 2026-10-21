#!/usr/bin/env python3
# Analysis of run7.py's stage B (HANDOVER.md section 6). Prints, as markdown:
#   1. everyone at trot (guides, or own frame for Jansen, Klann, Spears 4-bar), the better direction
#   2. the best of each linkage
#   3. forward against reversed, for every picked config pair
# Speeds are means over seeds 1-2 (cm/s). "Clears" is the highest log height at
# which the walker averages at least 2 cm/s (a fifth of flat speed, ~120 cm in 60 s).
# Lift is the foot's rise over its path from the geometry (footlift.json, from
# tools/footlift.py); "body adds" = clears - lift, what rocking and dipping found.
import json, os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.argv = [sys.argv[0], "none"]
import run7
D = run7.D
LIFT = json.load(open("/home/claude/work/footlift.json"))
def rows(of):
    r = {}
    if not os.path.exists(of): return r
    for l in open(of):
        t = l.split("|")[0]
        m = re.search(r"height ([\d.]+)\|.*\|([-\d.]+) cm/s", l)
        if not m: continue
        r.setdefault((t, float(m.group(1))), []).append(float(m.group(2)))
    return {k: sum(v) / len(v) for k, v in r.items()}
def summary(c):
    cid, link, brace, timing, d, walker, extra = c
    r = rows(f"{D}/B_{cid}.txt")
    if not r: return None
    def mean(t):
        v = [x for (tt, _), x in r.items() if tt == t]
        return sum(v) / len(v) if v else float("nan")
    logs = sorted((h, v) for (t, h), v in r.items() if t == "logs")
    clears = max([h for h, v in logs if v >= 2] or [0])
    flat = run7.cal.get(cid, {}).get("hist", [(0, float("nan"))])[-1][1]
    allm = sum(r.values()) / len(r)
    return dict(c=c, flat=flat, waves=mean("waves"), random=mean("random"), steps=mean("steps"),
                logs=mean("logs"), clears=clears, lift=LIFT.get(walker, {}).get("lift", float("nan")), all=allm)
S = {c[0]: summary(c) for c in run7.configs}
S = {k: v for k, v in S.items() if v}
H = "| Linkage | Bracing | Timing | Direction | Flat | Waves | Random | Steps | Logs | Clears (cm) | Lift (cm) | Body adds | Mean |"
def line(s):
    cid, link, brace, timing, d, walker, extra = s["c"]
    return (f"| {link} | {brace} | {timing} | {'reversed' if d == 'rev' else 'forward'} | {s['flat']:.2f} | {s['waves']:.2f} | "
            f"{s['random']:.2f} | {s['steps']:.2f} | {s['logs']:.2f} | {s['clears']:g} | {s['lift']:.1f} | "
            f"{s['clears'] - s['lift']:+.1f} | {s['all']:.2f} |")
links = list(dict.fromkeys(c[1] for c in run7.configs))
print("## Everyone at trot\n\n" + H + "\n" + "|---" * 13 + "|")
for L in links:
    t = [s for s in S.values() if s["c"][1] == L and s["c"][3] == "trot" and s["c"][2] in ("guides", "own")]
    if t: print(line(max(t, key=lambda s: s["all"])))
print("\n## Best of each linkage\n\n" + H + "\n" + "|---" * 13 + "|")
for L in sorted(links, key=lambda L: -max([s["all"] for s in S.values() if s["c"][1] == L] or [0])):
    t = [s for s in S.values() if s["c"][1] == L]
    if t: print(line(max(t, key=lambda s: s["all"])))
print("\n## Forward against reversed\n\n| Linkage | Bracing | Timing | Forward | Reversed | Better |\n|---|---|---|---|---|---|")
for k, s in S.items():
    if not k.endswith("_fwd") or k[:-4] + "_rev" not in S: continue
    r = S[k[:-4] + "_rev"]; c = s["c"]
    print(f"| {c[1]} | {c[2]} | {c[3]} | {s['all']:.2f} | {r['all']:.2f} | {'reversed' if r['all'] > s['all'] else 'forward'} |")
