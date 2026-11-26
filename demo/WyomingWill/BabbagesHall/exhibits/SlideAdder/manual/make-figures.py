"""The slide adder's manual figures (Babbage's Hall). Run from the
exhibit's folder: python3 manual/make-figures.py (matplotlib).

Drawn with the exhibit's sizes (parts/slide-adder.scad): pegs 4 mm across,
a step (8 mm) apart; slots 24 mm apart; the digits to add on each slot's
right, going up, and to subtract on its left, in red, going down; the
window 16 mm below the slot's bottom. A band that reads v is v steps down;
the gap beside the add digit d is then gap d + v of the band, red from 10
on. The moves are the operator's, as the exhibit makes them.

  fig-add.png      adding 4 to a column that reads 3: down to the bottom
  fig-carry.png    adding 5 to a column that reads 7: up, along, one down
  fig-borrow.png   taking 5 from a column that reads 3: down, along, one up
"""
import os
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle, Circle, FancyArrowPatch

HERE = os.path.dirname(os.path.abspath(__file__))
P, RP, W, S = 8, 2, 24, 4
Y0 = 0                                  # (the slot's bottom, here)
YT = Y0 + 10 * P
YW = Y0 - 16
COVER, BAND, RED, INK, PEG = "#2f3a40", "#e8dcc0", "#c0392b", "#2b1e14", "#b9a77f"
LABEL, LABEL_SUB = "#ece8d6", "#e86050"


def column(ax, x, v, active=None):
    """A column at x whose band reads v: the slot (and what shows in it),
    the labels, the window."""
    # what shows through the slot: the band, red behind the gaps 10 and on
    ax.add_patch(Rectangle((x - S / 2, Y0 - S / 2), S, YT - Y0 + S, color=BAND, zorder=1))
    for k in range(0, 11):
        gap = k + v                       # (the band's gap here)
        if gap >= 10:
            ax.add_patch(Rectangle((x - S / 2, Y0 + k * P - P / 2), S, P, color=RED, zorder=1.5))
    for i in range(-1, 12):
        y = Y0 + (i - 0.5) * P
        if Y0 - S / 2 - RP < y < YT + S / 2 + RP:
            ax.add_patch(Circle((x, y), RP, color=PEG, ec="#6b5a3a", lw=0.5, zorder=2))
    for d in range(1, 10):
        ax.text(x + 5.5, Y0 + d * P, str(d), ha="center", va="center", fontsize=7.5, color=LABEL,
                weight="bold", zorder=3)
        ax.text(x - 5.5, Y0 + (10 - d) * P, str(d), ha="center", va="center", fontsize=7.5, color=LABEL_SUB,
                weight="bold", zorder=3)
    # the window, showing the band's digit
    ax.add_patch(Rectangle((x + 10 - 4.5, YW - 3.5), 9, 7, color=BAND, zorder=1))
    ax.text(x + 10, YW, str(v % 10), ha="center", va="center", fontsize=11, weight="bold", color=INK, zorder=3)


def board(cols, title, moves, caption, name, notes=()):
    """cols: [(x, v, active)], the columns to draw; moves: a list of
    points the stylus goes through, drawn as arrows; notes: (x, y, text)."""
    n = len(cols)
    x0, x1 = min(c[0] for c in cols) - 14, max(c[0] for c in cols) + 18
    fig, ax = plt.subplots(figsize=(1.6 + 1.25 * n, 4.3))
    ax.add_patch(Rectangle((x0, YW - 9), x1 - x0, YT - YW + 18, color=COVER, zorder=0))
    # the channels along the top and the bottom
    for y in (Y0, YT):
        ax.add_patch(Rectangle((min(c[0] for c in cols) - S / 2, y - S / 2), max(c[0] for c in cols) - min(c[0] for c in cols) + S,
                               S, color=BAND, zorder=0.5))
    for c in cols:
        column(ax, *c)
    for i in range(len(moves) - 1):
        a, b = moves[i], moves[i + 1]
        ax.add_patch(FancyArrowPatch(a, b, arrowstyle="-|>", mutation_scale=11, color="#f5d142", lw=2.2, zorder=5,
                                     shrinkA=0, shrinkB=0))
    ax.add_patch(Circle(moves[0], 1.8, color="#f5d142", zorder=6))
    for (x, y, t) in notes:
        ax.text(x, y, t, ha="left", va="center", fontsize=7.5, color="white", zorder=6, style="italic")
    ax.text((x0 + x1) / 2, YT + 13, title, ha="center", va="center", fontsize=10, weight="bold", color=INK)
    ax.text((x0 + x1) / 2, YW - 15, caption, ha="center", va="center", fontsize=8, style="italic", color=INK)
    ax.set_xlim(x0 - 2, x1 + 2)
    ax.set_ylim(YW - 20, YT + 18)
    ax.set_aspect("equal")
    ax.axis("off")
    fig.savefig(os.path.join(HERE, name), dpi=170, bbox_inches="tight", facecolor="white")
    plt.close(fig)
    print("  manual/" + name)


# adding 4 to a column at 3: the gap beside 4 is the band's 7: not red
board([(0, 3, 4)], "Adding 4 to 3", [(0, Y0 + 4 * P), (0, Y0)],
      "down from the 4 to the bottom: the window goes from 3 to 7", "fig-add.png")
# adding 5 to the units at 7: the gap beside 5 is the band's 12: red
board([(-W, 2, None), (0, 7, 5)], "Adding 5 to 27: a carry",
      [(0, Y0 + 5 * P), (0, YT), (-W, YT), (-W, YT - P)],
      "red beside the 5: up to the top (7 becomes 2), along, one down in the tens (2 becomes 3)",
      "fig-carry.png")
# taking 5 from the units at 3: the gap beside the red 5 is the band's 8: not red
board([(-W, 4, None), (0, 3, None)], "Taking 5 from 43: a borrow",
      [(0, Y0 + 5 * P), (0, Y0), (-W, Y0), (-W, Y0 + P)],
      "not red beside the red 5: down to the bottom (3 becomes 8), along, one up in the tens (4 becomes 3)",
      "fig-borrow.png")
