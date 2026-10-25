#!/usr/bin/env python3
# Check runs (chk36.sh): per build, mean speed over seeds 1-4 on normal and mirrored ground, the spread, sideways drift
# at the end, and the farthest it got from the track's middle line (walls at 300 cm).
import re, glob, statistics as st
D = "/home/claude/work/chk36"
def one(f):
    t = open(f).read()
    tr = re.search(r"^TRACK .*", t, re.M)
    if not tr: return None
    v = float(re.search(r"\|([-\d.]+) cm/s", tr.group(0)).group(1))
    side = float(re.search(r"sideways ([-\d.]+) cm", tr.group(0)).group(1))
    zs = [float(re.search(r"\|z ([-\d.]+)", l).group(1)) for l in t.splitlines() if l.startswith("STALL")]
    return dict(v=v, side=side, far=max(abs(z) for z in zs) if zs else 0)
print("| Walker | Bracing | Timing | Direction | Normal ground, seeds 1-4 (cm/s) | Mirrored | Mean normal / mirrored / both | Sideways at end, normal / mirrored (cm) | Farthest from middle (cm) |")
print("|---|---|---|---|---|---|---|---|---|")
for w, nm in (("CS", "Chebyshev-Spears"), ("HS4", "Hoecken-Spears 4-bar")):
    for k, lab in (("guides", "guides"), ("outside", "diag, outside braces, held pendants")):
        R = {m: [one(f) for f in sorted(glob.glob(f"{D}/{w}_{k}_s[1-4]_{m}.txt"))] for m in ("normal", "mirrored")}
        R = {m: [r for r in R[m] if r] for m in R}
        if not R["normal"] and not R["mirrored"]: continue
        sp = lambda m: " ".join(f"{r['v']:.2f}" for r in R[m])
        mean = lambda m: st.mean(r["v"] for r in R[m]) if R[m] else float("nan")
        allv = [r["v"] for m in R for r in R[m]]
        side = lambda m: " ".join(f"{r['side']:+.0f}" for r in R[m])
        far = max(r["far"] for m in R for r in R[m])
        print(f"| {nm} | {lab} | trot | forward | {sp('normal')} | {sp('mirrored')} | {mean('normal'):.2f} / {mean('mirrored'):.2f} / {st.mean(allv):.2f} (sd {st.stdev(allv) if len(allv) > 1 else 0:.2f}, {len(allv)} runs) | {side('normal')} / {side('mirrored')} | {far:.0f} |")
