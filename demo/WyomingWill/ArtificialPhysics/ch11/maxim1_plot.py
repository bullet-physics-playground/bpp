#!/usr/bin/env python3
"""ch11/maxim1_plot.py -- draw the runs of ch11/maxim1_sweep.sh

    python3 ch11/maxim1_plot.py [kl|dev]      (from ArtificialPhysics/; needs matplotlib)

Reads ch11/runs/ENV_K.txt and writes ch11/runs/maxim1_sweep.png: one panel
per environment, the KL (or deviation) against f at every checkpoint of the
runs, light for the early ones and dark for the last, so how far each f
still improves with time can be seen.

DEFINITIONS (as in maxim1.c):
  f     K / 20, the mean free path in cell widths; dashed: the bound 0.65
  KL    sum over the C cells of p_i ln(p_i C); dotted: the book's target 0.001
  dev   sqrt(sum (p_i - 1/C)^2), Eq. 4.1
"""
import glob
import os
import re
import sys
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

HERE = os.path.dirname(os.path.abspath(__file__))
what = sys.argv[1] if len(sys.argv) > 1 else "kl"
col = 1 if what == "kl" else 2
ENVS = [("3x1", "3x1"), ("4cell.L", "4cellL"), ("4cell.roll", "4cellRoll"), ("7cell.dumbbell", "7cell"),
        ("3x3", "3x3"), ("15cell", "15cell"), ("22cell", "22cell"), ("35cell", "35cell"),
        ("6x6", "6x6"), ("10x10", "10x10"), ("spiral82", "82cell"), ("84cell", "84cell")]
SURFACE, INK2, MUTED = "#fcfcfb", "#52514e", "#8a8984"
plt.rcParams.update({"font.size": 9, "axes.edgecolor": MUTED, "axes.labelcolor": INK2, "xtick.color": INK2,
                     "ytick.color": INK2, "figure.facecolor": SURFACE, "axes.facecolor": SURFACE})

fig, axs = plt.subplots(3, 4, figsize=(13, 9.5), sharex=True)
for ax, (d, label) in zip(axs.flat, ENVS):
    by_t = {}
    for f in glob.glob(f"{HERE}/runs/{d}_*.txt"):
        k = int(re.search(r"_(\d+)\.txt$", f).group(1))
        for line in open(f):
            if line.startswith("#"): continue
            p = line.split()
            by_t.setdefault(int(p[0]), {})[k] = float(p[col])
    ts = sorted(by_t)
    for i, t in enumerate(ts):
        pts = sorted(by_t[t].items())
        if len(pts) < 2: continue
        shade = 0.25 + 0.75 * (i + 1) / len(ts)
        ax.plot([k / 20 for k, _ in pts], [v for _, v in pts], color=(0.16, 0.47, 0.84, shade),
                lw=2 if i == len(ts) - 1 else 1, label=f"{t:.0e} steps" if i in (0, len(ts) - 1) else None)
    ax.set_yscale("log"); ax.set_xlim(0, 4.1)
    ax.axvline(0.65, color=MUTED, ls="--", lw=1)
    if what == "kl": ax.axhline(0.001, color=MUTED, ls=":", lw=1)
    ax.grid(True, color="#e6e5e1", lw=0.6)
    ax.set_title(label, fontsize=10)
    ax.legend(loc="lower right", fontsize=7, frameon=False)
for ax in axs[-1]: ax.set_xlabel("f = mean free path ÷ cell width")
for ax in axs[:, 0]: ax.set_ylabel("KL" if what == "kl" else "deviation")
fig.suptitle("maxim1: one robot, seed 1, cell 20 - every checkpoint (light: early, dark: last)", fontsize=11)
fig.tight_layout()
out = f"{HERE}/runs/maxim1_sweep.png"
fig.savefig(out, dpi=110)
print("wrote", out)
