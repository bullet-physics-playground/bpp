#!/usr/bin/env python3
"""The steering runs' table and paths (runs/steer-table.sh; handover/STEERING.md).

    python3 runs/steer.py runs/out-steer [paths.png]

Turn: degrees a second from 5 s to the end, a turn to the walker's own left counting up; mean of the seeds, and
± half their spread. Split: the left bias's turn less the right bias's, which cancels the walker's own drift (positive: a
bias on the left turns it more to the left than the same bias on the right does). Speed: straight from where it was at 5 s to where it ends, cm/s.
"""
import glob, os, re, sys
from collections import defaultdict

root = sys.argv[1]
png = sys.argv[2] if len(sys.argv) > 2 else None
runs = defaultdict(list)          # (variant, build, ground) -> [(seed, turn, speed, tilt, tipped)]
paths = {}                        # (variant, build, ground, seed) -> [(x, z)]
for f in glob.glob(os.path.join(root, "*", "warm40fast", "*.txt")):
    variant = f.split(os.sep)[-3]
    m = re.match(r"(.*)_(waves|logs|steps|random)(\d+)_s(\d+)\.txt$", os.path.basename(f))
    ground, seed = f"{m.group(2)} {m.group(3)}", int(m.group(4))
    pts = []
    for line in open(f, errors="replace"):
        if line.startswith("STEER "):
            name, rest = line[6:].split("|", 1)
            kv = dict(p.rsplit(" ", 1) for p in rest.strip().split("|"))
            runs[(variant, name, ground)].append((seed, float(kv["turn"]), float(kv["speed"]), float(kv["tilt max"]), int(kv["tipped"])))
        elif line.startswith("PATH "):
            kv = dict(p.rsplit(" ", 1) for p in line[5:].strip().split("|")[1:])
            pts.append((int(kv["t"]), float(kv["x"]), float(kv["z"])))
            pname = line[5:].split("|", 1)[0]
    if pts:
        paths[(variant, pname, ground, seed)] = [(x, z) for _, x, z in pts]
        a, e = [p for p in pts if p[0] == 5][0], pts[-1]   # (speed: straight from 5 s to the end, as steerprobe.lua now)
        runs[(variant, pname, ground)][-1] = runs[(variant, pname, ground)][-1][:2] + (((e[1] - a[1]) ** 2 + (e[2] - a[2]) ** 2) ** 0.5 / (e[0] - 5),) + runs[(variant, pname, ground)][-1][3:]

def mean(v): return sum(v) / len(v)
def spread(v): return (max(v) - min(v)) / 2
def bracing(n): return "own frame" if n in ("Jansen", "Klann", "Spears 4-bar") else "outside, held" if n.endswith("diag") else "guides"
def bias(v):
    if v == "base": return "none", "", ""
    mech, side, k = v.split("-")
    return NAMES[mech][0], side, k + NAMES[mech][1]
NAMES = {   # (mech: what it is, the amount's unit; STEER in walker-room.lua)
    "friction": ("foot friction ×", ""), "pair": ("pair crank speed ×", ""), "side": ("side crank speed ×", ""),
    "ballast": ("ballast (¼ its weight) moved", " cm"), "drag": ("drag shoe, of its weight", ""),
    "sole": ("soles thicker", " cm"), "stiff": ("ankle stiffness ×", ""), "damp": ("ankle damping ×", ""),
    "linkdamp": ("pair's link damping", ""), "wheels": ("wheel braked, of its weight", "")}
STRONG = {"friction": "0.05", "pair": "0.6", "side": "0.6", "ballast": "8", "drag": "0.25", "sole": "1.5",
          "stiff": "10", "damp": "5", "linkdamp": "0.95", "wheels": "0.15"}   # (the paths drawn: each bias at its stronger amount)
def timing(v):   # (pair and side slowing: the crank lock holds each pair, or side, only to itself)
    return "trot, pairs free" if v.startswith("pair") else "trot, sides free" if v.startswith("side") else "trot"

order = lambda v: (v != "base", v.split("-")[0], v.split("-")[-1:], v)
builds = sorted({k[1] for k in runs})
grounds = sorted({k[2] for k in runs})
for b in builds:
    print(f"\n### {b} ({bracing(b)})\n")
    print("| Bias | Side | Amount | Bracing | Timing | Direction | " + " | ".join(f"{g}: turn °/s | ± | speed | tilt" for g in grounds) + " | Tipped |")
    print("|" + "---|" * (7 + 4 * len(grounds)))
    for v in sorted({k[0] for k in runs if k[1] == b}, key=order):
        mech, side, k = bias(v)
        cells, tipped = [], 0
        for g in grounds:
            r = runs.get((v, b, g), [])
            if not r: cells += ["", "", "", ""]; continue
            cells += [f"{mean([x[1] for x in r]):+.2f}", f"{spread([x[1] for x in r]):.2f}", f"{mean([x[2] for x in r]):.2f}", f"{max(x[3] for x in r):.1f}"]
            tipped += sum(x[4] for x in r)
        print(f"| {mech} | {side} | {k} | {bracing(b)} | {timing(v)} | forward | " + " | ".join(cells) + f" | {tipped} |")
    print(f"\nSplit (left bias's turn − right bias's, °/s), {b}:\n")
    print("| Bias | Amount | " + " | ".join(grounds) + " |")
    print("|---|---|" + "---|" * len(grounds))
    for v in sorted({k[0] for k in runs if k[1] == b and k[0].split("-")[1:2] == ["L"] and (k[0].replace("-L-", "-R-"), b, k[2]) in runs}, key=order):
        rv = v.replace("-L-", "-R-")
        cells = []
        for g in grounds:
            L, R = runs.get((v, b, g)), runs.get((rv, b, g))
            cells.append(f"{mean([x[1] for x in L]) - mean([x[1] for x in R]):+.2f}" if L and R else "")
        print(f"| {bias(v)[0]} | {bias(v)[2]} | " + " | ".join(cells) + " |")

if png:
    import matplotlib; matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    show = [("base", "no bias", "#555555", "-")]
    colours = ["#1f77b4", "#d62728", "#2ca02c", "#9467bd", "#ff7f0e", "#8c564b", "#e377c2", "#17becf", "#bcbd22"]
    mechs = [m for m in NAMES if any(k[0].startswith(m + "-") for k in runs)]
    for m, c in zip(mechs, colours):
        lab = f"{NAMES[m][0]} {STRONG[m]}{NAMES[m][1]}".replace("× ", "×")
        show += [(f"{m}-L-{STRONG[m]}", lab + ", left", c, "-"), (f"{m}-R-{STRONG[m]}", lab + ", right", c, "--")]
    fig, axes = plt.subplots(len(builds), len(grounds), figsize=(6.5 * len(grounds), 4.2 * len(builds)), squeeze=False)
    for i, b in enumerate(builds):
        for j, g in enumerate(grounds):
            ax = axes[i][j]
            for v, lab, c, ls in show:
                p = paths.get((v, b, g, 1))
                if not p: continue
                x0, z0 = p[0]
                ax.plot([x - x0 for x, _ in p], [-(z - z0) for _, z in p], ls, color=c, label=lab, lw=1.4)
            ax.set_title(f"{b}, {g}, seed 1 (20 s)")
            ax.set_xlabel("along the track, cm"); ax.set_ylabel("to the walker's left, cm")
            ax.set_aspect("equal", adjustable="datalim"); ax.grid(alpha=0.3)
    axes[0][-1].legend(fontsize=7, loc="upper left", bbox_to_anchor=(1.02, 1))
    fig.suptitle("Steering biases: paths from above (YAW_DAMP 0; solid: bias on the left, dashed: on the right)")
    fig.tight_layout(); fig.savefig(png, dpi=110)
    print(f"\npaths: {png}")
