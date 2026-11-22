"""The bead sort's manual figures (Babbage's Hall). Run from the exhibit's
folder: python3 manual/make-figures.py (matplotlib).

Drawn with the exhibit's sizes and colours (bead-sort.lua, parts/bead-sort.scad):
nine rods 26 mm apart, beads 20 mm across and 12 mm along the rod, each
number's beads in its own colour. The sort is the machine's rule: on each
rod the beads fall to the bottom, in the order they were (a bead can't pass
the one below it).

  fig-laid.png     the numbers laid: rows of beads from the left
  fig-sorted.png   after the frame is turned upright: the same beads, sorted
  fig-counts.png   why: rod k holds a bead for every number of k or more
"""
import os
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch, Rectangle

HERE = os.path.dirname(os.path.abspath(__file__))
NROD, PITCH, NROW = 9, 26, 8
BEAD_D, BEAD_T = 20, 12
BAR_W = 12
COLOURS = ["#c0392b", "#e67e22", "#f1c40f", "#27ae60", "#16a085", "#2980b9", "#8e44ad", "#e8e2d0"]
WOOD, STEEL, INK = "#b98a52", "#9aa0a6", "#2b1e14"
NUMS = [3, 7, 1, 9, 4, 2, 6, 5]          # (the tour's first list)


def rodx(i): return (i - (NROD + 1) / 2) * PITCH


def rows_y(r): return BAR_W + (r - 0.5) * BEAD_T


def sort_beads(nums):
    """the machine's rule: each rod's beads fall, keeping their order"""
    rods = {i: [k for k, n in enumerate(nums) if n >= i] for i in range(1, NROD + 1)}
    return {(i, j + 1): k for i, ks in rods.items() for j, k in enumerate(ks)}   # (rod, row) -> number's index


def frame(ax, nums, beads, title, counts=None, note=None):
    W = NROD * PITCH + 2 * BAR_W
    L = NROW * BEAD_T + 4 + 2 * BAR_W
    ax.add_patch(Rectangle((-W / 2, 0), W, BAR_W, color=WOOD))
    ax.add_patch(Rectangle((-W / 2, L - BAR_W), W, BAR_W, color=WOOD))
    for e in (-1, 1):
        ax.add_patch(Rectangle((e > 0 and W / 2 - BAR_W or -W / 2, 0), BAR_W, L, color=WOOD))
    for i in range(1, NROD + 1):
        ax.plot([rodx(i)] * 2, [BAR_W, L - BAR_W], color=STEEL, lw=1.6, zorder=1)
        ax.text(rodx(i), -9, str(i), ha="center", va="center", fontsize=9, color=INK)
    for (i, r), k in beads.items():
        ax.add_patch(FancyBboxPatch((rodx(i) - BEAD_D / 2 + 1.5, rows_y(r) - BEAD_T / 2 + 0.6), BEAD_D - 3, BEAD_T - 1.2,
                                    boxstyle="round,pad=1.4", fc=COLOURS[k], ec="#3a2a1a", lw=0.6, zorder=2))
    if counts:
        for r, c in enumerate(counts, 1):
            ax.text(-W / 2 - 9, rows_y(r), str(c), ha="center", va="center", fontsize=10, weight="bold", color=INK)
    ax.text(0, L + 9, title, ha="center", va="center", fontsize=11, weight="bold", color=INK)
    if note:
        ax.text(0, -22, note, ha="center", va="center", fontsize=9, style="italic", color=INK)
    ax.set_xlim(-W / 2 - 20, W / 2 + 6)
    ax.set_ylim(-30, L + 18)
    ax.set_aspect("equal")
    ax.axis("off")


def save(fig, name):
    fig.savefig(os.path.join(HERE, name), dpi=170, bbox_inches="tight", facecolor="white")
    plt.close(fig)
    print("  manual/" + name)


laid = {(i, r): r - 1 for r, n in enumerate(NUMS, 1) for i in range(1, n + 1)}
after = sort_beads(NUMS)
srt = sorted(NUMS, reverse=True)

fig, ax = plt.subplots(figsize=(4.6, 3.4))
frame(ax, NUMS, laid, "Laid: " + "  ".join(map(str, NUMS)), counts=NUMS, note="(the frame flat; the first number is the bottom row)")
save(fig, "fig-laid.png")

fig, ax = plt.subplots(figsize=(4.6, 3.4))
frame(ax, NUMS, after, "Upright: " + "  ".join(map(str, srt)), counts=srt, note="(each bead has fallen onto the one below)")
save(fig, "fig-sorted.png")

# why: a rod's beads are its count of numbers at least that big
fig, ax = plt.subplots(figsize=(6.4, 2.6))
xs = range(1, NROD + 1)
cnt = [sum(1 for n in NUMS if n >= i) for i in xs]
ax.bar(xs, cnt, color=STEEL, width=0.6)
for i, c in zip(xs, cnt):
    ax.text(i, c + 0.15, str(c), ha="center", va="bottom", fontsize=9, color=INK)
ax.set_xticks(list(xs))
ax.set_xlabel("rod k")
ax.set_ylabel("beads on rod k")
ax.set_title("Rod k keeps a bead for each number of k or more (" + " ".join(map(str, NUMS)) + ")", fontsize=10)
ax.set_ylim(0, NROW + 1)
for sp in ("top", "right"):
    ax.spines[sp].set_visible(False)
save(fig, "fig-counts.png")
