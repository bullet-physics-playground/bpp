#!/usr/bin/env python3
"""ch11/plot_mfp_sweep.py -- the figures for Maxim's 12 environments

    python3 ch11/plot_mfp_sweep.py          (from ArtificialPhysics/; needs matplotlib)

Writes two figures next to this script:
  environments.png   each environment's walls and cells at cell size 20
                     (ch11/maxim/<name>.environment/environment_20.ini)
  mfp_sweep.png      for each environment, the KL against f after 4 x 10^7
                     and after 1.6 x 10^8 steps (the 3x3: 3.2 x 10^8), from
                     ch11/mfp_sweep_counts.txt (ch11/README.md has the runs)

DEFINITIONS:
  f    the mean free path in cell widths: the robot turns after K steps
       without a wall, f = K / 20 (cell size 20)
  KL   sum over the C cells of p_i ln(p_i C), p_i the share of the steps
       spent in cell i (Sec. 11.2.3); 0 is uniform; log scale
  0.65 the theory's upper bound on f (Sec. 11.3; Ch. 4.3), dashed
  0.001 the book's KL target in simulation (Sec. 11.2.3), dotted
"""
import math
import os
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

HERE = os.path.dirname(os.path.abspath(__file__))
ENVS = [("3x1", "3x1"), ("4cell.L", "4cellL"), ("4cell.roll", "4cellRoll"), ("7cell.dumbbell", "7cell"),
        ("3x3", "3x3"), ("15cell", "15cell"), ("22cell", "22cell"), ("35cell", "35cell"),
        ("6x6", "6x6"), ("10x10", "10x10"), ("spiral82", "82cell"), ("84cell", "84cell")]
# the reference palette (dataviz skill): surface, ink, two categorical slots, muted reference lines
SURFACE, INK, INK2, MUTED = "#fcfcfb", "#0b0b0b", "#52514e", "#8a8984"
LATE, EARLY = "#2a78d6", "#eb6834"   # slot 1 (the longer run), slot 2 (4 x 10^7)
plt.rcParams.update({"font.size": 9, "axes.edgecolor": MUTED, "axes.labelcolor": INK2, "xtick.color": INK2,
                     "ytick.color": INK2, "text.color": INK, "figure.facecolor": SURFACE, "axes.facecolor": SURFACE})


def read_env(name):
    tok = [l.split() for l in open(f"{HERE}/maxim/{name}.environment/environment_20.ini") if l.split()]
    q, walls, cells = 0, [], []
    nv = int(tok[q][1]); q += 1
    for _ in range(nv): walls.append((float(tok[q][0]), float(tok[q][1]))); q += 1
    nc = int(tok[q][1]); q += 1
    for _ in range(nc): cells.append((float(tok[q][0]), float(tok[q][1]))); q += 1
    return walls, cells, float(tok[q][1])


def read_counts():
    data = {}
    for line in open(f"{HERE}/mfp_sweep_counts.txt"):
        w = line.split()
        env, k, t = w[0], int(w[2]), int(w[3])
        c = list(map(int, w[4:])); tot = sum(c); n = len(c)
        kl = sum((x / tot) * math.log(x / tot * n) for x in c if x > 0)
        data.setdefault(env, {}).setdefault(t, {})[k] = kl
    return data


# environments
fig, axs = plt.subplots(3, 4, figsize=(12, 9))
for ax, (d, label) in zip(axs.flat, ENVS):
    walls, cells, size = read_env(d)
    for (x, y) in cells:
        ax.add_patch(plt.Rectangle((x, y), size, size, fill=True, facecolor="#e8eef8", edgecolor="#9db7dd", lw=0.6))
    xs = [p[0] for p in walls] + [walls[0][0]]; ys = [p[1] for p in walls] + [walls[0][1]]
    ax.plot(xs, ys, color=INK, lw=1.5)
    ax.set_aspect("equal"); ax.set_xticks([]); ax.set_yticks([])
    for s in ax.spines.values(): s.set_visible(False)
    ax.set_title(f"{label}  ({len(cells)} cells)", fontsize=10)
fig.suptitle("Maxim's 12 environments at cell size 20: walls (black) and cells", fontsize=12)
fig.tight_layout()
fig.savefig(f"{HERE}/environments.png", dpi=110)

# the sweep
data = read_counts()
fig, axs = plt.subplots(3, 4, figsize=(13, 9.5), sharex=True)
for ax, (d, label) in zip(axs.flat, ENVS):
    runs = data[d]
    late = max(runs)
    for t, col, lab in ((4 * 10**7, EARLY, "4 × 10⁷ steps"), (late, LATE, f"{late / 1e8:.1f} × 10⁸ steps")):
        ks = sorted(runs[t])
        ax.plot([k / 20 for k in ks], [runs[t][k] for k in ks], color=col, lw=2, marker="o", ms=3, label=lab)
    ax.set_yscale("log"); ax.set_ylim(4e-6, 2e-2); ax.set_xlim(0, 4.1)
    ax.axvline(0.65, color=MUTED, ls="--", lw=1)
    ax.axhline(0.001, color=MUTED, ls=":", lw=1)
    ax.grid(True, which="major", color="#e6e5e1", lw=0.6)
    ax.set_title(label, fontsize=10)
    ax.legend(loc="lower right", fontsize=7, frameon=False)
for ax in axs[-1]: ax.set_xlabel("f = mean free path ÷ cell width")
for ax in axs[:, 0]: ax.set_ylabel("KL")
fig.suptitle("One robot in Maxim's simulator (with the F81 fix, seed 1): KL against the mean free path.\n"
             "Dashed: the theory's bound f = 0.65.  Dotted: the book's target KL 0.001.", fontsize=11)
fig.tight_layout()
fig.savefig(f"{HERE}/mfp_sweep.png", dpi=110)
print("wrote", f"{HERE}/environments.png", f"{HERE}/mfp_sweep.png")
