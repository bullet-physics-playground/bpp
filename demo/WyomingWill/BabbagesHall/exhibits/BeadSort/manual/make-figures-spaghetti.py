"""The spaghetti sort's manual figures (Babbage's Hall: the bead sort's
second way). Run from the exhibit's folder:
python3 manual/make-figures-spaghetti.py (matplotlib).

Drawn with the exhibit's sizes and colours (spaghetti-sort.lua,
parts/spaghetti-sort.scad): eight slots 26 mm apart, rods 8 mm across, a
number n cut 30 + 12 n mm long, standing on a 6 mm base; each rod in the
colour of its slot, as in the exhibit. The order is the machine's rule:
the palm, coming down, meets the tallest rod left.

  fig-sp-stood.png   the rods stood in the rack, and where the palm meets each
  fig-sp-taken.png   the rods laid in the order the palm took them
"""
import os
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle, FancyBboxPatch

HERE = os.path.dirname(os.path.abspath(__file__))
NSLOT, PITCH, ROD_D, BASE_T = 8, 26, 8, 6
COLOURS = ["#c0392b", "#e67e22", "#f1c40f", "#27ae60", "#16a085", "#2980b9", "#8e44ad", "#e8e2d0"]
WOOD, DARK, INK, PALM = "#b98a52", "#7a5a3a", "#2b1e14", "#c9a06a"
NUMS = [3, 7, 1, 9, 4, 2, 6, 5]          # (the tour's first list)
ORD = ["1st", "2nd", "3rd", "4th", "5th", "6th", "7th", "8th"]


def rodL(n): return 30 + 12 * n
def slotx(k): return (k - (NSLOT + 1) / 2) * PITCH


def save(fig, name):
    fig.savefig(os.path.join(HERE, name), dpi=170, bbox_inches="tight", facecolor="white")
    plt.close(fig)
    print("  manual/" + name)


# the order the palm meets them: tallest first (equal ones together, the
# left one taken first, as the exhibit does)
order = sorted(range(NSLOT), key=lambda k: (-NUMS[k], k))

fig, ax = plt.subplots(figsize=(6.2, 4.2))
W = NSLOT * PITCH
ax.add_patch(Rectangle((-W / 2 - 14, 0), W + 28, BASE_T, color=DARK))
ax.add_patch(Rectangle((-W / 2 - 8, 20), W + 16, 6, color=WOOD, alpha=0.55, zorder=3))      # the comb
for k, n in enumerate(NUMS):
    x, top = slotx(k + 1), BASE_T + rodL(n)
    ax.add_patch(FancyBboxPatch((x - ROD_D / 2, BASE_T), ROD_D, rodL(n), boxstyle="round,pad=0,rounding_size=1.2",
                                fc=COLOURS[k], ec="#3a2a1a", lw=0.6, zorder=2))
    ax.text(x, -8, str(n), ha="center", va="center", fontsize=10, weight="bold", color=INK)
for i, k in enumerate(order):
    top = BASE_T + rodL(NUMS[k])
    ax.plot([-W / 2 - 14, 128], [top, top], color=INK, lw=0.5, ls=(0, (3, 3)), zorder=1)
    ax.text(132, top, f"{ORD[i]}: {NUMS[k]}", ha="left", va="center", fontsize=8, color=INK)
# the palm, come down onto the tallest
tall = BASE_T + rodL(max(NUMS))
ax.add_patch(Rectangle((-125, tall), 250, 6, color=PALM, ec="#5a4020", lw=0.6, zorder=4))
ax.annotate("the palm, lowered: it meets the 9 first", (-60, tall + 6), (-110, tall + 30), fontsize=8.5,
            color=INK, arrowprops=dict(arrowstyle="->", color=INK, lw=0.7))
ax.text(0, -22, "(the rods stood in the rack, their feet level on its base; front view)",
        ha="center", va="center", fontsize=8.5, style="italic", color=INK)
ax.set_xlim(-140, 175)
ax.set_ylim(-30, tall + 40)
ax.set_aspect("equal")
ax.axis("off")
save(fig, "fig-sp-stood.png")

fig, ax = plt.subplots(figsize=(5.0, 3.0))
for i, k in enumerate(order):
    n = NUMS[k]
    y = -i * 12
    ax.add_patch(FancyBboxPatch((0, y - ROD_D / 2), rodL(n), ROD_D, boxstyle="round,pad=0,rounding_size=1.2",
                                fc=COLOURS[k], ec="#3a2a1a", lw=0.6))
    ax.text(-8, y, str(n), ha="center", va="center", fontsize=10, weight="bold", color=INK)
ax.text(rodL(9) / 2, 16, "Taken: " + "  ".join(str(NUMS[k]) for k in order), ha="center", va="center",
        fontsize=11, weight="bold", color=INK)
ax.text(rodL(9) / 2, -7 * 12 - 16, "(laid down in the order the palm met them; each rod keeps its colour)",
        ha="center", va="center", fontsize=8.5, style="italic", color=INK)
ax.set_xlim(-18, rodL(9) + 6)
ax.set_ylim(-7 * 12 - 24, 24)
ax.set_aspect("equal")
ax.axis("off")
save(fig, "fig-sp-taken.png")
