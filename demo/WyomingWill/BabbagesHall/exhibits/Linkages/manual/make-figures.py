"""The linkages' manual figures (Babbage's Hall). Run from the exhibit's
folder: python3 manual/make-figures.py (matplotlib).

Drawn with the exhibit's sizes (linkages.lua, cm): the long arms 15.052,
the rhombus's sides 11.25 (their squares differ by 100); the crank 3.5,
pivoted at O + 3.5; the multiplier's b carriage at 6 from its O, rising
0.75 b, and the bridge at 4 a.

  fig-cell.png      the inverter: O, A, B, P, Q and the two right triangles
  fig-line.png      the straight line: P on a circle through O, Q on a line
  fig-multiply.png  the multiplier's similar triangles
  fig-kempe.png     Kempe's reversor (8 and 4; 4 and 2) and the adder (6, 3),
                    with the limacon its pen draws
(fig-exhibit.png is a screenshot of the exhibit.)
"""
import math, os
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Circle

HERE = os.path.dirname(os.path.abspath(__file__))
L, S, K2 = 15.052, 11.25, 15.052 ** 2 - 11.25 ** 2
ARM, SIDE, INK, RED, GREY, BLUE = "#8a5a2b", "#c08a4a", "#2b1e14", "#c0392b", "#9a9a9a", "#2f5f8a"


def cell(p):
    """O at 0, P at p along x: A, B and Q (y up)."""
    # (A is L from O and S from P)
    a = (L * L - S * S + p * p) / (2 * p)
    h = math.sqrt(L * L - a * a)
    return (a, h), (a, -h), (K2 / p, 0)


def pin(ax, x, y, name, col=INK, dx=0.3, dy=0.35):
    ax.add_patch(Circle((x, y), 0.18, color=col, zorder=5))
    ax.text(x + dx, y + dy, name, fontsize=13, color=col, zorder=6)


def bars(ax, pts, col, lw):
    for (x1, y1), (x2, y2) in pts:
        ax.plot([x1, x2], [y1, y2], color=col, lw=lw, solid_capstyle="round", zorder=3)


def fig_cell():
    fig, ax = plt.subplots(figsize=(8, 10))
    p = 6.25
    A, B, Q = cell(p)
    P = (p, 0)
    M = (A[0], 0)
    ax.plot([-0.5, 18], [0, 0], color=GREY, lw=0.8, ls="--", zorder=1)
    bars(ax, [((0, 0), A), ((0, 0), B)], ARM, 7)
    bars(ax, [(P, A), (P, B), (Q, A), (Q, B)], SIDE, 5)
    ax.plot([A[0], B[0]], [A[1], B[1]], color=BLUE, lw=1.2, ls=":", zorder=2)
    ax.plot([M[0] - 0.4, M[0] - 0.4, M[0]], [0, 0.4, 0.4], color=BLUE, lw=1, zorder=2)
    pin(ax, 0, 0, "O", dx=-0.7, dy=0.3)
    pin(ax, *A, "A"); pin(ax, *B, "B", dy=-0.8)
    pin(ax, *P, "P", dx=-0.2, dy=-0.9)
    pin(ax, *Q, "Q", col=RED, dx=0.2, dy=-0.9)
    ax.text(M[0] + 0.2, -0.8, "M", fontsize=12, color=BLUE)
    ax.text(2.6, 4.6, "OA = 15.05", fontsize=11, color=ARM, rotation=math.degrees(math.atan2(A[1], A[0])))
    ax.text(13.6, 6.0, "PA = QA = 11.25", fontsize=11, color=SIDE)
    ax.text(-0.3, -12.4, "OP = %.2f    OQ = %.2f    OP x OQ = %.1f" % (p, Q[0], p * Q[0]), fontsize=12, color=INK)
    ax.set_xlim(-1.5, 18.5); ax.set_ylim(-13, 11.8); ax.set_aspect("equal"); ax.axis("off")
    fig.savefig(os.path.join(HERE, "fig-cell.png"), dpi=110, bbox_inches="tight"); plt.close(fig)


def fig_line():
    fig, ax = plt.subplots(figsize=(8, 10))
    C = 3.5
    xl = K2 / (2 * C)
    ax.add_patch(Circle((C, 0), C, fill=False, color=GREY, lw=1.2, ls="--"))
    ax.plot([xl, xl], [-13, 13], color=RED, lw=1.5, ls="--")
    ax.plot([-0.5, 17], [0, 0], color=GREY, lw=0.6, ls=":")
    for t, alpha in ((-35, 1.0),):
        P = (C + C * math.cos(math.radians(t)), C * math.sin(math.radians(t)))
        r = math.hypot(*P); u = (P[0] / r, P[1] / r)
        # (the cell along the direction of P)
        a = (L * L - S * S + r * r) / (2 * r); h = math.sqrt(L * L - a * a)
        n = (-u[1], u[0])
        A = (u[0] * a + n[0] * h, u[1] * a + n[1] * h); B = (u[0] * a - n[0] * h, u[1] * a - n[1] * h)
        Q = (u[0] * K2 / r, u[1] * K2 / r)
        for (x1, y1), (x2, y2), col, lw in (((0, 0), A, ARM, 6), ((0, 0), B, ARM, 6), (P, A, SIDE, 4), (P, B, SIDE, 4),
                                            (Q, A, SIDE, 4), (Q, B, SIDE, 4), ((C, 0), P, BLUE, 5)):
            ax.plot([x1, x2], [y1, y2], color=col, lw=lw, alpha=alpha, solid_capstyle="round")
        if alpha == 1.0:
            pin(ax, *P, "P", dx=0.25, dy=-0.9); pin(ax, *Q, "Q", col=RED, dx=0.3, dy=-0.2)
    pin(ax, 0, 0, "O", dx=-0.8, dy=0.2); pin(ax, C, 0, "", col=BLUE)
    ax.text(C - 0.3, 0.45, "crank", fontsize=10, color=BLUE)
    ax.text(xl + 0.3, 12.0, "x = 100 / 7 = 14.29", fontsize=11, color=RED)
    ax.text(-0.5, -13.6, "P on a circle through O; Q on a straight line", fontsize=12, color=INK)
    ax.set_xlim(-1.5, 20); ax.set_ylim(-14.2, 13); ax.set_aspect("equal"); ax.axis("off")
    fig.savefig(os.path.join(HERE, "fig-line.png"), dpi=110, bbox_inches="tight"); plt.close(fig)


def fig_multiply():
    fig, ax = plt.subplots(figsize=(8, 4.4))
    a, b = 2.5, 4
    D, Y, X = 6.0, 0.75 * b, 4 * a
    Z = X * Y / D
    ax.plot([0, 13.5], [0, 13.5 * Y / D], color=ARM, lw=9, solid_capstyle="round", alpha=0.85)
    ax.plot([0, 13.5], [0, 13.5 * Y / D], color="#f3dfb8", lw=2.5)
    ax.plot([-0.5, 14], [0, 0], color=GREY, lw=0.8, ls="--")
    ax.plot([D, D], [-1, 6.5], color=BLUE, lw=1, ls=":"); ax.plot([X, X], [-1, 6.5], color=RED, lw=1, ls=":")
    ax.plot([D, D], [0, Y], color=BLUE, lw=2.5); ax.plot([X, X], [0, Z], color=RED, lw=2.5)
    pin(ax, 0, 0, "O", dx=-0.8, dy=0.2)
    pin(ax, D, Y, "the b carriage", col=BLUE, dx=-3.2, dy=0.5)
    pin(ax, X, Z, "the cross carriage", col=RED, dx=-1.0, dy=0.7)
    ax.text(D + 0.15, Y / 2 - 0.2, "0.75 b", fontsize=11, color=BLUE)
    ax.text(X + 0.15, Z / 2 - 0.2, "Z", fontsize=11, color=RED)
    ax.text(D - 0.15, -1.0, "6", fontsize=11, color=BLUE, ha="right")
    ax.text(X + 0.15, -1.0, "4 a (on the bridge)", fontsize=11, color=RED, ha="left")
    ax.text(-0.5, -2.0, "Z / 4a = 0.75 b / 6, so Z = a b / 2: the scale reads a x b  (here 2.5 x 4 = 10)", fontsize=11, color=INK)
    ax.set_xlim(-1.5, 14.5); ax.set_ylim(-2.4, 7.5); ax.set_aspect("equal"); ax.axis("off")
    fig.savefig(os.path.join(HERE, "fig-multiply.png"), dpi=110, bbox_inches="tight"); plt.close(fig)


def fig_kempe():
    """Kempe's reversor at th = 60: the crossed parallelograms O-X-B-P (8, 4)
    and O-P-C-Q (4, 2), the adder O-A-S-E, and the whole limacon."""
    Lk, sk, A, Bk = 8.0, 4.0, 6.0, 3.0
    r = sk * sk / Lk
    th = math.radians(60)
    def circ(p0, r0, p1, r1):
        dx, dy = p1[0] - p0[0], p1[1] - p0[1]; d = math.hypot(dx, dy)
        a = (r0 * r0 - r1 * r1 + d * d) / (2 * d); h = math.sqrt(max(0, r0 * r0 - a * a))
        mx, my = p0[0] + a * dx / d, p0[1] + a * dy / d
        return (mx + h * dy / d, my - h * dx / d), (mx - h * dy / d, my + h * dx / d)
    O, X = (0, 0), (Lk, 0)
    P = (sk * math.cos(th), sk * math.sin(th))
    un = (X[0] + P[0], X[1] + P[1])
    B = max(circ(X, sk, P, Lk), key=lambda q: math.hypot(q[0] - un[0], q[1] - un[1]))
    C = (P[0] + r * (B[0] - P[0]) / Lk, P[1] + r * (B[1] - P[1]) / Lk)
    Q = (r * math.cos(2 * th), r * math.sin(2 * th))
    Ap = (A * math.cos(th), A * math.sin(th)); E = (Bk * math.cos(2 * th), Bk * math.sin(2 * th))
    Sp = (Ap[0] + E[0], Ap[1] + E[1])
    fig, ax = plt.subplots(figsize=(8, 7.8))
    ts = [2 * math.pi * i / 400 for i in range(401)]
    ax.plot([A * math.cos(t) + Bk * math.cos(2 * t) for t in ts], [A * math.sin(t) + Bk * math.sin(2 * t) for t in ts],
            color=GREY, lw=1, ls="--")
    tw = [math.radians(20 + 140 * i / 200) for i in range(201)]
    ax.plot([A * math.cos(t) + Bk * math.cos(2 * t) for t in tw], [A * math.sin(t) + Bk * math.sin(2 * t) for t in tw],
            color=INK, lw=2.2)
    ax.plot([-1, Lk + 1], [0, 0], color=GREY, lw=0.8, ls=":")
    bars(ax, [(O, X)], GREY, 7)
    bars(ax, [(X, B), (P, B)], SIDE, 6)
    bars(ax, [(C, Q)], BLUE, 5)
    bars(ax, [(O, Ap)], ARM, 7)
    bars(ax, [(O, E)], RED, 6)
    bars(ax, [(Ap, Sp), (E, Sp)], "#7a8a3a", 4)
    pin(ax, *O, "O", dx=-0.7, dy=-0.6); pin(ax, *X, "X", dx=0.3, dy=-0.6)
    pin(ax, *P, "P"); pin(ax, *B, "B"); pin(ax, *C, "C", col=BLUE); pin(ax, *Q, "Q", col=BLUE, dx=-0.9, dy=-0.8)
    pin(ax, *Ap, "A", col=ARM); pin(ax, *E, "E", col=RED, dx=-0.7); pin(ax, *Sp, "S, the pen", dx=-2.6, dy=0.4)
    ax.text(1.0, 0.25, "th", fontsize=12, color=ARM)
    ax.text(-6.6, -8.9, "The crank O-A at th turns the arm O-E to 2 th: OXBP (8, 4) and OPCQ (4, 2) are crossed\n"
            "parallelograms of one shape. S = A + E draws 6 e^(i th) + 3 e^(2 i th): solid, the crank from 20 to 160.",
            fontsize=10.5, color=INK)
    ax.set_xlim(-7, 10); ax.set_ylim(-9.5, 9.5); ax.set_aspect("equal"); ax.axis("off")
    fig.savefig(os.path.join(HERE, "fig-kempe.png"), dpi=110, bbox_inches="tight"); plt.close(fig)


fig_cell(); fig_line(); fig_multiply(); fig_kempe()
print("wrote fig-cell.png, fig-line.png, fig-multiply.png")
