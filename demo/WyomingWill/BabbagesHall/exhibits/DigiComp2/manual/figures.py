#!/usr/bin/env python3
"""figures.py -- the Digi-Comp II manual's figures, drawn from the machine's own geometry.

    ./make-figures.sh            (in this folder: needs lua5.2 or lua5.1, python3, matplotlib)

Every wall, hole, peg, rocker and flap in these pictures is read from
digicomp2-geometry.lua (through dump-geometry.lua), the same numbers the
simulation and the printed parts use. Only the arrows (where a ball goes)
and the labels are drawn by hand here.
"""
import json, math, sys, os
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Polygon, Circle, Rectangle, FancyArrowPatch

D = json.load(open(sys.argv[1]))
OUT = sys.argv[2]
DPI = 160

PLATE, LOWER_C, WALL, LWALL, HOLE = "#d6e0e8", "#efe8d8", "#3b3b3b", "#4f9a70", "#ffffff"
ROCK = {"A": "#e7b04b", "D": "#7aa7cf", "MQ": "#d98a74"}
FLAP = "#b5543c"
INK, MUTED = "#231c15", "#6b5d4f"
PATH = ["#c0392b", "#2471a3", "#1e8449", "#8e44ad", "#b9770e", "#555555"]

R, OX, OUT_, FL = D["R"], D["sw"]["OX"], D["sw"]["OUT"], D["sw"]["FL"]
RUNTOP, DX, DZ = D["runtop"], D["DX"], D["DZ"]
J3, J4 = D["JOIN"][2], D["JOIN"][3]
ROCKER = {r["name"]: r for r in D["rockers"]}
SWITCH = {s["name"]: s for s in D["switches"]}


def rot(pts, a, cx=0.0, cz=0.0):
    c, s = math.cos(a), math.sin(a)
    return [(cx + x * c + z * s, cz - x * s + z * c) for x, z in pts]


SHUT = "#5d6d7e"


def board(ax, state=None, flaps=None, lower=True, upper=True, dim=False, marks=False, region=None, comp=False):
    """the board seen from above: z down the page. state: rocker name -> 0/1; flaps: switch name -> True (ball goes
    left); comp: COMPLEMENT on (the shutters over the done holes)"""
    state = state or {}
    flaps = flaps or {}
    b, l = D["board"], D["lower"]
    ax.add_patch(Rectangle((l[0], l[2]), l[1] - l[0], l[3] - l[2], fc=LOWER_C, ec="none", zorder=0))
    if upper:
        ax.add_patch(Rectangle((b[0], b[2]), b[1] - b[0], b[3] - b[2], fc=PLATE, ec="#9aa5ad", lw=0.6, zorder=0.5, alpha=0.85))
    a = 0.35 if dim else 1.0
    if lower:
        for w in D["lwalls"]:
            ax.plot([w[0], w[2]], [w[1], w[3]], color=LWALL, lw=1.0, ls=(0, (3, 2)), alpha=a, zorder=1)
    for h in D["holes"]:
        ax.add_patch(Rectangle((h[0], h[2]), h[1] - h[0], h[3] - h[2], fc=HOLE, ec="#8a8a8a", lw=0.4, zorder=1.5))
    if upper:
        for w in D["walls"]:
            ax.plot([w[0], w[2]], [w[1], w[3]], color=WALL, lw=1.5, solid_capstyle="projecting", alpha=a, zorder=2)
        for p in D["pegs"]:
            ax.add_patch(Circle((p[0], p[1]), p[2], fc="#8d939a", ec="none", alpha=a, zorder=2))
        al = math.radians(D["flip"]["alpha"])
        for r in D["rockers"]:
            st = state.get(r["name"], 0)
            ang = -al if st == 1 else al
            for pc in D["flip"]["pieces"]:
                ax.add_patch(Polygon(rot(pc, ang, r["x"], r["z"]), fc=ROCK[r["kind"]], ec="none", alpha=a, zorder=3))
        sa = math.radians(D["sw"]["ANG"] - 0.5)
        for s in D["switches"]:
            left = flaps.get(s["name"], False)
            ang = -sa if left else sa
            p = rot([(-0.15, -FL), (0.15, -FL), (0.15, 0), (-0.15, 0)], ang, s["x"], s["z"])
            ax.add_patch(Polygon(p, fc=FLAP, ec="none", alpha=a, zorder=3))
            ax.add_patch(Circle((s["x"], s["z"]), 0.18, fc="#333", zorder=3.5))
        w = D["wheel"]
        for pc in D["wheelPieces"]:
            ax.add_patch(Polygon([(w[0] + x, w[1] + z) for x, z in pc], fc="#c9a14a", ec="none", alpha=a, zorder=3))
        # COMPLEMENT: the shutters (on: over the holes; off: to the right), their pins, the bar over them
        sh = D["shutter"]
        dx = 0 if comp else sh["travel"]
        for t in D["shutters"]:
            ax.add_patch(Polygon([(x + dx, z) for x, z in t["piece"]], fc=SHUT, ec="none", alpha=0.8 * a, zorder=1.7))
            ax.add_patch(Circle((t["pin"][0] + dx, t["pin"][1]), sh["pinR"] * 1.6, fc="#2c3e50", ec="none", alpha=a, zorder=3.6))
        ax.add_patch(Polygon([(x + dx, z) for x, z in sh["bar"]], fc=SHUT, ec="none", alpha=0.45 * a, zorder=3.5))
        ax.add_patch(Circle((sh["knob"][0] + dx, sh["knob"][1]), sh["knobR"], fc="#2c3e50", ec="none", alpha=a, zorder=3.6))
    if marks:
        for m in D["marks"]:
            ax.text(m[1], m[2], m[0], ha="center", va="center", fontsize=m[3] * 0.75, color="#1f3b4d", zorder=4, clip_on=True)
    ax.set_aspect("equal")
    ax.invert_yaxis()
    ax.axis("off")
    if region:
        x0, x1, z0, z1 = region
        ax.set_xlim(x0, x1)
        ax.set_ylim(z1, z0)


def path(ax, pts, col, lw=2.2, every=1, label=None, ls="-", z=6):
    xs, zs = [p[0] for p in pts], [p[1] for p in pts]
    ax.plot(xs, zs, color=col, lw=lw, ls=ls, alpha=0.9, zorder=z, solid_capstyle="round", label=label)
    # arrowheads along the way
    for i in range(0, len(pts) - 1, every):
        (x0, z0), (x1, z1) = pts[i], pts[i + 1]
        if math.hypot(x1 - x0, z1 - z0) < 1.2:
            continue
        mx, mz = (x0 + x1) / 2, (z0 + z1) / 2
        ax.add_patch(FancyArrowPatch((x0 + (mx - x0) * 0.8, z0 + (mz - z0) * 0.8), (mx, mz), arrowstyle="-|>",
                                     mutation_scale=11, color=col, lw=0, zorder=z + 0.1))
    ax.add_patch(Circle(pts[-1], 0.45, fc=col, ec="white", lw=0.8, zorder=z + 0.2))


# ---- where a ball goes: points along its way ----
def top(s): return (s["x"], s["top"])
def pin(s): return (s["x"], s["z"] - 0.4)
def outl(s, side): return (s["x"] + side * OX, s["z"] + OUT_)
def throat(r): return (r["x"], r["z"] - RUNTOP)
def apex(r): return (r["x"], r["z"] - D["flip"]["A"] - R * 0.5)
def exitp(r, side): return (r["x"] + side * 2.3, r["z"] + 0.2)
def catch(r, side): return (r["x"] + side * DX, r["z"] + DZ - RUNTOP)
def done(r): return tuple(r["done"])
def lane(name): return [tuple(p) for p in D["lanes"][name]]
def joinend(t, side): return (t[0] + side * J3, t[1] - J4)
def wheel_out():
    w = D["wheel"]
    return [(w[0], w[1] - w[3]), (w[0] + w[3], w[1]), (w[0], w[1] + w[3])]

S, Rk = SWITCH, ROCKER
def into(r): return [throat(r), apex(r)]
HEAD = wheel_out() + [top(S["MULTIPLY"]), pin(S["MULTIPLY"])]


def p_count():
    return (HEAD + [outl(S["MULTIPLY"], 1)] + lane("MULTIPLY off")[1:] + [pin(S["CLEAR"]), outl(S["CLEAR"], -1),
            pin(S["COUNT"]), outl(S["COUNT"], -1), throat(Rk["A1"]), apex(Rk["A1"])])


def p_mult(k):
    """the k-th ball of a cycle (1: through the MQ to M4; 2: M1; 3: M3; 4: M2), to the accumulator"""
    p = HEAD + [outl(S["MULTIPLY"], -1)] + into(Rk["D1"])
    if k in (1, 3):
        p += [exitp(Rk["D1"], -1)] + into(Rk["D2"])
        if k == 1:
            p += [exitp(Rk["D2"], -1)] + into(Rk["MQ1"]) + [exitp(Rk["MQ1"], 1)]
            p += lane("MQ1 on") + [catch(Rk["MQ2"], 1)] + lane("MQ2 on")[1:] + [catch(Rk["MQ3"], 1)]
            p += lane("MQ to M4")[1:]
            m = "M4"
        else:
            p += [exitp(Rk["D2"], 1)] + lane("D2 to M3")
            m = "M3"
    else:
        p += [exitp(Rk["D1"], 1)] + lane("D1 to D3") + into(Rk["D3"])
        if k == 2:
            p += [exitp(Rk["D3"], 1)] + lane("D3 to M1")
            m = "M1"
        else:
            p += [exitp(Rk["D3"], -1)] + lane("D3 to M2")
            m = "M2"
    a = Rk["A" + m[1]]
    return p + [pin(S[m]), outl(S[m], 1), throat(a), apex(a)]


def p_stop():
    p = HEAD + [outl(S["MULTIPLY"], -1)] + into(Rk["D1"]) + [exitp(Rk["D1"], -1)] + into(Rk["D2"])
    p += [exitp(Rk["D2"], -1)] + into(Rk["MQ1"]) + [exitp(Rk["MQ1"], -1)] + into(Rk["MQ2"])
    p += [exitp(Rk["MQ2"], -1)] + into(Rk["MQ3"]) + [exitp(Rk["MQ3"], -1), tuple(D["stop"])]
    return p


def save(fig, name):
    fig.savefig(os.path.join(OUT, name), dpi=DPI, bbox_inches="tight", facecolor="white")
    plt.close(fig)
    print("  " + name)


def label(ax, x, z, t, size=9, col=INK, ha="center", weight="bold", bg=True):
    ax.text(x, z, t, ha=ha, va="center", fontsize=size, color=col, weight=weight, zorder=8, clip_on=True,
            bbox=dict(boxstyle="round,pad=0.25", fc="white", ec="none", alpha=0.85) if bg else None)


# ---- 1: the whole board ----
def fig_board():
    fig, ax = plt.subplots(figsize=(6.2, 17))
    board(ax)
    b = D["board"]
    w = D["wheel"]
    L = b[0] - 1.0
    Rr = b[1] + 1.0
    def tag(x, z, t, side, tx=None, tz=None):
        tx = tx if tx is not None else (L if side < 0 else Rr)
        ax.annotate(t, xy=(x, z), xytext=(tx, z if tz is None else tz), ha="right" if side < 0 else "left", va="center", fontsize=9,
                    weight="bold", color=INK, arrowprops=dict(arrowstyle="-", color=MUTED, lw=0.7), zorder=9)
    tag(w[0], w[4] + 3, "INPUT (the balls)", 1)
    tag(w[0] + w[2], w[1], "START (the feeder wheel)", 1)
    tag(S["MULTIPLY"]["x"], S["MULTIPLY"]["z"], "MULTIPLY switch", -1)
    tag(Rk["D1"]["x"] - 1, Rk["D1"]["z"], "DISTRIBUTOR  D1", -1)
    tag(Rk["D2"]["x"] - 1, Rk["D2"]["z"], "D2", -1)
    tag(Rk["D3"]["x"] + 2, Rk["D3"]["z"], "D3", 1)
    for k in (1, 2, 3):
        tag(Rk["MQ%d" % k]["x"] - 2, Rk["MQ%d" % k]["z"] - 1.6, "MQ%d" % k + ("  (the MQ)" if k == 1 else ""), -1)
    tag(D["stop"][0] - 0.7, D["stop"][1] + 1.6, "STOP", -1)
    for k in (1, 2, 3, 4):
        s = S["M%d" % k]
        tag(s["x"] - 2.5, s["z"] + 1.4, "M%d" % k + ("  (the MEMORY)" if k == 1 else ""), -1)
    tag(S["CLEAR"]["x"] + 2, S["CLEAR"]["z"], "CLEAR switch", 1)
    tag(S["COUNT"]["x"] + 2, S["COUNT"]["z"], "COUNT switch", 1)
    for k in range(1, 8):
        r = Rk["A%d" % k]
        tag(r["x"] + 2.2, r["z"] - 0.5, "A%d  (%ds)" % (k, 2 ** (k - 1)) + ("  the ACCUMULATOR" if k == 1 else ""), 1)
    tag(D["overflow"][0], D["overflow"][1], "OVERFLOW", -1)
    sh = D["shutter"]
    tag(sh["knob"][0] + sh["travel"], sh["knob"][1], "COMPLEMENT (its handle: off)", 1, tz=sh["knob"][1] - 3.2)
    t3 = D["shutters"][2]
    tag(t3["pin"][0] + sh["travel"], t3["pin"][1], "a done hole's shutter (open)", 1)
    l3 = lane("done 3")
    tag((l3[1][0] + l3[2][0]) / 2, (l3[1][1] + l3[2][1]) / 2, "a done lane", 1, tx=D["board"][1] + 1.0)
    tag(D["clearLane"][-1][0] + 1, D["clearLane"][-1][1], "clear lane (lower level)", 1)
    tag(D["XRET"], D["ZCOL"] - 8, "return lane (lower level)", -1)
    tag((b[0] + b[1]) / 2, D["ZCOL"] + 1.2, "COLLECTOR", 1)
    # (AUTO: the anchor at rest, the trip lever, the thread between them)
    T, A = D["trip"], D["anchor"]
    c, s_ = math.cos(A["rest"]), math.sin(A["rest"])
    def ap(px, pz): return (A["x"] + c * px + s_ * pz, A["z"] - s_ * px + c * pz)
    arm = [ap(0, -A["arm"]), ap(0, 0)]
    ax.plot([p[0] for p in arm], [p[1] for p in arm], color="#6b6f75", lw=2.2, solid_capstyle="round", zorder=6)
    th = [(T["dx"], T["zp"]), (T["ex"], T["ez"]), (T["hx"], T["hz"])]
    ax.plot([p[0] for p in th], [p[1] for p in th], color="#8a6d2a", lw=0.9, zorder=6)
    ax.plot([T["xc"], T["dx"]], [T["zp"], T["zp"]], color="#6b6f75", lw=1.2, zorder=6)
    ax.add_patch(Rectangle((T["xc"] - T["W"] / 2, T["zp"]), T["W"], T["A"], fc="#c9a14a", ec=INK, lw=0.5, zorder=7))
    tag(A["x"] - 1.0, A["z"] - A["arm"] / 2, "ANCHOR, its arm the START lever", -1)
    tag(T["ex"], T["ez"] + 60, "thread (AUTO), beside the board", 1)
    tag(T["ex"], T["ez"], "the thread's eye; across to the START lever", 1, tz=T["ez"] - 4)
    tag(T["xc"], T["zp"] + T["A"] / 2, "TRIP LEVER (AUTO)", 1, tz=T["zp"] + 2.2)
    tag(b[0] + 6, T["ZB"] + 0.4, "the store", -1)
    save(fig, "fig-board.png")


# ---- 2: the flip-flop ----
def fig_flipflop():
    fig, axs = plt.subplots(1, 2, figsize=(7.2, 3.6))
    F = D["flip"]
    al = math.radians(F["alpha"])
    for ax, st in zip(axs, (0, 1)):
        rb = -F["A"] - 1.4 - R
        rt = rb - F["run"]
        C = D["CHAN"] / 2 + 0.15
        for x in (-C, C):
            ax.plot([x, x], [rt, rb], color=WALL, lw=2.5)
        for s in (-1, 1):
            ax.add_patch(Circle((s * F["pegX"], F["pegZ"]), F["pegR"], fc="#8d939a"))
        ang = -al if st == 1 else al
        for pc in F["pieces"]:
            ax.add_patch(Polygon(rot(pc, ang), fc=ROCK["A"], ec="#9c7322", lw=0.6))
        ax.add_patch(Circle((0, F["weightZ"]), F["weightR"], fc="#9aa0a8", ec="#666", lw=0.5))
        ax.add_patch(Circle((0, 0), 0.15, fc="#333"))
        side = 1 if st == 0 else -1
        # the ball's way: down the run, onto the raised side, into its cup, out over the lip
        p = [(0, rt + 0.2), (0, -F["A"] - 0.8), (side * 0.9, -0.9), (side * 1.9, -0.35), (side * 3.0, 0.5), (side * 3.6, 2.2)]
        path(ax, p, PATH[0])
        ax.add_patch(Circle((0, rt + 0.2), R, fc="#c8ccd2", ec="#666", lw=0.6, zorder=7))
        ax.text(-1.7 if st == 0 else 1.7, -2.6, str(st), ha="center", fontsize=13, weight="bold", color=PATH[1])
        ax.text(0, 3.4, ["Found at 0 (apex left): the ball rolls into the right cup,\ntips the rocker to 1, and leaves to the RIGHT",
                         "Found at 1 (apex right): the ball rolls into the left cup,\ntips the rocker to 0, and leaves to the LEFT"][st],
                ha="center", va="top", fontsize=8.5, color=INK)
        ax.set_xlim(-4.6, 4.6); ax.set_ylim(5.6, rt - 0.5); ax.set_aspect("equal"); ax.axis("off")
    save(fig, "fig-flipflop.png")


# ---- 3: a switch ----
def fig_switch():
    fig, axs = plt.subplots(1, 2, figsize=(6.4, 3.6))
    sw = D["sw"]
    for ax, left in zip(axs, (True, False)):
        CI = sw["IW"] / 2 + 0.15
        OC = D["CHAN"] / 2 + 0.15
        top_ = -sw["FL"] - sw["DROP"]
        segs = [((-CI, top_), (-CI, -sw["FL"] + 0.2)), ((CI, top_), (CI, -sw["FL"] + 0.2))]
        for s in (-1, 1):
            ox = s * OX
            segs += [((s * CI, -sw["FL"] + 0.2), (ox + s * OC, 0.6)), ((0, 0.55), (ox - s * OC, 1.8)),
                     ((ox + s * OC, 0.6), (ox + s * OC, sw["OUT"])), ((ox - s * OC, 1.8), (ox - s * OC, sw["OUT"]))]
        for (a, b) in segs:
            ax.plot([a[0], b[0]], [a[1], b[1]], color=WALL, lw=2.5)
        sa = math.radians(sw["ANG"] - 0.5)
        ang = -sa if left else sa
        ax.add_patch(Polygon(rot([(-0.15, -sw["FL"]), (0.15, -sw["FL"]), (0.15, 0), (-0.15, 0)], ang), fc=FLAP))
        ax.add_patch(Circle((0, 0), 0.15, fc="#333"))
        s = -1 if left else 1
        p = [(0, top_ + 0.3), (s * 0.45, -1.2), (s * 0.95, 0.9), (s * OX, sw["OUT"] + 0.6)]
        path(ax, p, PATH[1])
        ax.text(0, sw["OUT"] + 1.6, "flap against the right wall:\nthe ball leaves LEFT" if left else
                "flap against the left wall:\nthe ball leaves RIGHT", ha="center", va="top", fontsize=8.5)
        ax.set_xlim(-3.6, 3.6); ax.set_ylim(sw["OUT"] + 3.4, top_ - 0.5); ax.set_aspect("equal"); ax.axis("off")
    save(fig, "fig-switch.png")


# ---- 4: counting, and a carry ----
def fig_count():
    fig, ax = plt.subplots(figsize=(6.6, 10.5))
    st = {"A1": 1, "A2": 1, "A3": 1}
    board(ax, state=st, flaps={"MULTIPLY": False, "CLEAR": True, "COUNT": True}, marks=True,
          region=(-15, 19, -30, 50))
    p = p_count()
    a = [Rk["A%d" % k] for k in range(1, 5)]
    p += [exitp(a[0], -1)] + into(a[1]) + [exitp(a[1], -1)] + into(a[2]) + [exitp(a[2], -1)] + into(a[3]) + [exitp(a[3], 1), done(a[3])]
    path(ax, [q for q in p if q[1] > -30.5], PATH[0])
    label(ax, -14.5, -27, "COUNT on: 7 (0000111) and one ball", 9, ha="left")
    for k, t in enumerate(("A1: 1 -> 0, carry", "A2: 1 -> 0, carry", "A3: 1 -> 0, carry", "A4: 0 -> 1, done")):
        r = a[k]
        label(ax, r["x"] + 6.4, r["z"] - 1.6, t, 8, ha="left", weight="normal")
    label(ax, -14.5, 49, "the result: 8 (0001000)", 9, ha="left")
    save(fig, "fig-count.png")


# ---- 5: clearing ----
def fig_clear():
    fig, ax = plt.subplots(figsize=(5.6, 12.5))
    st = {"A2": 1, "A4": 1, "A5": 1, "A7": 1}
    board(ax, state=st, flaps={"MULTIPLY": False, "CLEAR": False}, upper=True, dim=True, region=(-26, 11, -20, 96))
    d = D["clearDrop"]
    p = [(S["CLEAR"]["x"], S["CLEAR"]["top"]), pin(S["CLEAR"]), outl(S["CLEAR"], 1), tuple(d)] + [tuple(q) for q in D["clearLane"][1:]]
    path(ax, p, PATH[2])
    label(ax, -25, -16, "CLEAR on, the accumulator at 90 (1011010):\nthe ball drops through CLEAR's hole to the\nlower level and runs down the clear lane", 8.5, ha="left")
    label(ax, -25, 14, "Each rocker of A at 1 has its foot's\nwedge in the lane: the ball pushes\nit out, which turns the rocker to 0.\nRockers at 0 are passed by.", 8.5, ha="left", weight="normal")
    save(fig, "fig-clear.png")


# ---- 6: multiplying: one cycle of four balls, and STOP ----
def fig_multiply():
    fig, ax = plt.subplots(figsize=(7.0, 12.6))
    st = {"D1": 1, "D2": 1, "D3": 0, "MQ1": 0, "MQ2": 1, "MQ3": 1}
    board(ax, state=st, flaps={"MULTIPLY": True, "M1": False, "M2": False, "M3": False, "M4": False}, dim=False,
          region=(-34, 10, -52, 48))
    names = ["ball 1: D1, D2, the MQ (one less), M4 -> A4",
             "ball 2: D1, D3, M1 -> A1",
             "ball 3: D1, D2, M3 -> A3",
             "ball 4: D1, D3, M2 -> A2"]
    for k in (1, 2, 3, 4):
        path(ax, p_mult(k), PATH[k - 1], lw=2.0, label=names[k - 1], z=6 + k * 0.01)
    path(ax, p_stop(), PATH[5], lw=1.6, ls=(0, (2, 1.5)), label="the MQ at 0: the ball borrows out through STOP")
    ax.legend(loc="lower left", fontsize=8, frameon=True, framealpha=0.95)
    save(fig, "fig-multiply.png")


# ---- 7: the complement: one ball through all seven ----
def fig_complement():
    fig, ax = plt.subplots(figsize=(7.0, 14.0))
    n = 25
    bits = [(n >> k) & 1 for k in range(7)]
    st = {"A%d" % (k + 1): bits[k] for k in range(7)}
    board(ax, state=st, flaps={"MULTIPLY": False, "CLEAR": True, "COUNT": True}, marks=True, comp=True,
          region=(-26, 26, -14, 103))
    p = p_count()[-2:]
    for k in range(1, 8):
        r = Rk["A%d" % k]
        if k > 1:
            p += into(r)
        if bits[k - 1] == 0:
            p += [exitp(r, 1)]
            if k < 7:
                p += [done(r)] + lane("done %d" % k)[1:]
            else:
                p += [done(r)]
        else:
            p += [exitp(r, -1)]
            if k == 7:
                p += [tuple(D["overflow"])]
    path(ax, p, PATH[3])
    for k in range(1, 8):
        r = Rk["A%d" % k]
        b = bits[k - 1]
        t = "A%d: %d -> %d, %s" % (k, b, 1 - b, ("its hole covered:\non down its lane" if k < 7 else "done") if b == 0
                                   else ("carry" if k < 7 else "over"))
        label(ax, r["x"] + 4.8, r["z"] + (4.5 if b == 0 else 3.0), t, 7.5, ha="left", weight="normal")
    label(ax, -25, -11, "COMPLEMENT on (the shutters left, over\nthe done holes), COUNT on: 25 (0011001)\nand one ball",
          8.5, ha="left")
    label(ax, -25, 100, "the result: 102 (1100110), every bit\nturned over. COMPLEMENT off and one more\nball: 103, the complement",
          8.5, ha="left")
    save(fig, "fig-complement.png")


# ---- 8: which parts each operation uses ----
def fig_parts():
    fig, ax = plt.subplots(figsize=(6.4, 17))
    board(ax, dim=True)
    ALL, CC, AM, CM = "#9a7413", "#2e7d32", "#b03a2e", "#6c3483"
    def blob(x, z, r, col):
        ax.add_patch(Circle((x, z), r, fc=col, ec=col, alpha=0.28, lw=1.2, zorder=4))
    def line(pts, col, lw=7):
        ax.plot([p[0] for p in pts], [p[1] for p in pts], color=col, lw=lw, alpha=0.35, solid_capstyle="round", zorder=4)
    w = D["wheel"]
    blob(w[0], w[1], w[2] + 0.8, ALL)
    line([(w[0], w[4]), (w[0], w[5])], ALL)
    blob(S["MULTIPLY"]["x"], S["MULTIPLY"]["z"] - 1, 3.0, ALL)
    for k in range(1, 8):
        r = Rk["A%d" % k]
        blob(r["x"], r["z"] - 2.0, 3.2, ALL)
    line([(D["lower"][0], D["ZCOL"] - 1), (D["lower"][1], D["ZCOL"] + 1)], ALL)
    line(lane("MULTIPLY off"), CC)
    for n in ("CLEAR", "COUNT"):
        blob(S[n]["x"], S[n]["z"] - 1, 3.0, CC)
    line([tuple(p) for p in D["clearLane"]], CC, lw=4)
    for n in ("D1", "D2", "D3", "MQ1", "MQ2", "MQ3"):
        blob(Rk[n]["x"], Rk[n]["z"] - 2.0, 3.2, AM)
    for k in (1, 2, 3, 4):
        blob(S["M%d" % k]["x"], S["M%d" % k]["z"] - 1, 3.0, AM)
    for n, p in D["lanes"].items():
        if n != "MULTIPLY off" and not n.startswith("done"):
            line([tuple(q) for q in p], AM)
    for r in D["returns"]:
        line([(r[0], r[1]), (r[2], r[3])], AM, lw=4)
    line([(D["XRET"], D["stop"][1]), (D["XRET"], D["ZCOL"] - 1.5)], AM, lw=4)
    blob(D["stop"][0], D["stop"][1], 1.6, AM)
    for k in range(1, 7):
        line(lane("done %d" % k), CM, lw=5)
    sh = D["shutter"]
    tv = sh["travel"]
    line([(sh["knob"][0] + tv, sh["knob"][1]), (sh["bar"][1][0] + tv, sh["bar"][1][1])], CM, lw=4)
    blob(D["overflow"][0], D["overflow"][1], 1.6, CM)
    from matplotlib.lines import Line2D
    h = [Line2D([], [], color=c, lw=8, alpha=0.5) for c in (ALL, CC, AM, CM)]
    ax.legend(h, ["used by every operation: the feeder, MULTIPLY\n(on or off), the accumulator, the collector",
                  "count and clear: MULTIPLY's lane down,\nCLEAR, COUNT, the clear lane and A's feet",
                  "add and multiply: the distributor, the MQ,\nthe memory, STOP and the return lane",
                  "complement (subtract, divide): the shutters,\ntheir bar, the done lanes; OVERFLOW watched"],
              loc="upper center", fontsize=8, framealpha=0.95, bbox_to_anchor=(0.5, 0.0))
    save(fig, "fig-parts.png")


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    fig_board(); fig_flipflop(); fig_switch(); fig_count(); fig_clear(); fig_multiply(); fig_complement(); fig_parts()
