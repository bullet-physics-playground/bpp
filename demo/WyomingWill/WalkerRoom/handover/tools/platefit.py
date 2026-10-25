#!/usr/bin/env python3
# Low side plates (PLATE_LOW): fit and check, from held-body crank-turn sweeps with ankles.
#   python3 platefit.py fit    (sweepL/ made with every drop 0: the plate's middle at the pendants' middles)
#   python3 platefit.py check  (sweepL/ made with the fitted drops)
# Height above the ground = above the lowest foot bottom over the turn (the body held level).
# Targets: the diag cousin's bottom brace's lowest (patch 33, sweep6), and for the sliders the diag braces'
# rule: the plate's top 0.3 under the body at its highest.
import sys, math
sys.path.insert(0, "/home/claude/work")
import topz
from shapely.geometry import box
M = 0.3
COUSIN = {"Chebyshev": 7.97, "Chebyshev-Spears": 5.99, "Hoecken_4-bar": 7.87, "Hoecken-Spears_4-bar": 5.88,
          "Hoecken-Spears_long-stance": 5.53, "Spears_lift_44": 4.23, "Spears_lift_53": 4.77}
BUILDS = list(COUSIN) + ["Hoecken_slider", "Hoecken-Spears_slider"]
def load(b):
    path = f"/home/claude/work/sweepL/{b}.txt"
    name, L, S, bb, hz = topz.load(path)
    J = [l.split() for l in open(path) if l.startswith("JOIN")]
    n = min(len(S[i]) for i in L)
    feet = [i for i in L if L[i]["kind"] == "buildFoot"]
    plates = [i for i in L if L[i]["kind"] == "buildCrossbar"]
    own = {p: {int(j[2]) if int(j[1]) == p else int(j[1]) for j in J if p in (int(j[1]), int(j[2]))} for p in plates}
    ground = min(S[f][k].bounds[1] for f in feet for k in range(n))
    return name, L, S, bb, hz, n, feet, plates, own, ground
def measure(b):
    name, L, S, bb, hz, n, feet, plates, own, ground = load(b)
    out = []
    for p in plates:
        lo = min(S[p][k].bounds[1] for k in range(n)) - ground
        hi = max(S[p][k].bounds[3] for k in range(n))
        under = bb[2] - hi                      # body bottom minus the plate's highest top
        # on its pendants: the plate's height band within each pendant's, at its ends, every moment
        onp = min(min(S[q][k].bounds[3] - S[p][k].bounds[3], S[p][k].bounds[1] - S[q][k].bounds[1]) for q in own[p] for k in range(n))
        # every link and foot whose slab across comes within M of the plate's (feet 12 wide), not its own pendants
        zp = L[p]["z"]; worst, who = 99, None
        for i in L:
            if i == p or i in own[p]: continue
            t = 6.0 if i in feet else 0.15
            if abs(L[i]["z"] - zp) >= t + 0.15 + M: continue
            for k in range(n):
                g = S[p][k].distance(S[i][k])
                if g < worst: worst, who = g, (L[i]["kind"], round(L[i]["z"], 1))
        out.append(dict(z=zp, lo=lo, under=under, onp=onp, worst=worst, who=who, lift=max(S[p][k].bounds[1] for k in range(n)) - min(S[p][k].bounds[1] for k in range(n)), h=S[p][0].bounds[3] - S[p][0].bounds[1]))
    return name, bb, out
if __name__ == "__main__":
    mode = sys.argv[1]
    for b in BUILDS:
        name, bb, out = measure(b)
        if mode == "fit":
            lo = max(o["lo"] for o in out)          # (both plates alike; take the higher, so neither ends below its target)
            if b in COUSIN:
                drop = lo - COUSIN[b]; why = f"diag cousin {COUSIN[b]:.2f}"
            else:
                drop = -min(o["under"] for o in out) + M; why = "0.3 under the body"
            print(f'  ["{name}"] = {{ drop = {drop:.2f} }},   -- {why}; plates now {", ".join(f"{o["lo"]:.2f}" for o in out)} at their lowest')
        else:
            for o in out:
                tgt = f"target {COUSIN[b]:.2f}" if b in COUSIN else "target: 0.3 under the body"
                print(f"{name:28s} plate z {o['z']:+5.1f}: {o['h']:.3f} tall, bottom at its lowest {o['lo']:5.2f} ({tgt}), lift {o['lift']:5.2f}; top under the body by {o['under']:5.2f}; "
                      f"inside its pendants by {o['onp']:5.2f}; closest other part {o['worst']:5.2f} {o['who']}")
