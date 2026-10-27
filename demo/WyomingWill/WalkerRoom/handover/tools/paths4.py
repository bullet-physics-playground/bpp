#!/usr/bin/env python3
# The four ideal foot paths from Walking_Linkages.lua (Chebyshev, Chebyshev-Spears, Hoecken slider, Hoecken-Spears
# slider), each scaled to stride 15 cm. Per path: stride, lift, duty (Walking_Linkages' measure: below 15% of the
# height), within 0.5 cm of the lowest, and how the link carrying the foot turns (its swing over a turn, and its
# fastest turning in degrees per crank degree); for the sliders also how far the bar slides through its pivot.
# Writes paths4.png.
import math
import matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt
def ci(p1, r1, p2, r2, br):
    dx, dy = p2[0] - p1[0], p2[1] - p1[1]; d = math.hypot(dx, dy)
    a = (r1 * r1 - r2 * r2 + d * d) / (2 * d); h = math.sqrt(max(r1 * r1 - a * a, 0))
    mx, my = p1[0] + a * dx / d, p1[1] + a * dy / d
    return (mx + br * h * -dy / d, my + br * h * dx / d)
def cheb_spears(t):
    O2 = (48 * math.cos(math.pi / 4), 48 * math.sin(math.pi / 4)); A = (36 * math.cos(t), 36 * math.sin(t))
    B = ci(A, 110, O2, 110, 1); ux, uy = (B[0] - A[0]) / 110, (B[1] - A[1]) / 110
    lx, ly = uy, -ux            # -90 deg from the coupler
    return (B[0] + 110 * lx, B[1] + 110 * ly), math.atan2(ly, lx), None
def cheb(t):
    A = (math.cos(t), math.sin(t)); B = ci(A, 2.5, (2, 0), 2.5, 1); ux, uy = (B[0] - A[0]) / 2.5, (B[1] - A[1]) / 2.5
    return (A[0] + 5 * ux, A[1] + 5 * uy), math.atan2(uy, ux), None
def slider(c, g, L):
    def f(t):
        A = (c * math.cos(t), c * math.sin(t)); dx, dy = -A[0], g - A[1]; d = math.hypot(dx, dy)
        return (A[0] + L * dx / d, A[1] + L * dy / d), math.atan2(dy, dx), d
    return f
M = [("Chebyshev", cheb), ("Chebyshev-Spears", cheb_spears), ("Hoecken slider", slider(1, 2, 10)),
     ("Hoecken-Spears slider", slider(36, 46.95, 168.98))]
N = 3600
fig, ax = plt.subplots(figsize=(9, 4.5))
for name, f in M:
    P = [f(2 * math.pi * i / N) for i in range(N)]
    X = [p[0][0] for p in P]; Y = [p[0][1] for p in P]
    # stance at the bottom: flip so the foot path's low side is down (for each, the side with the flat run)
    lo, hi = min(Y), max(Y)
    if sum(y < lo + 0.15 * (hi - lo) for y in Y) < sum(y > hi - 0.15 * (hi - lo) for y in Y): Y = [-y for y in Y]; lo, hi = min(Y), max(Y)
    th = lo + 0.15 * (hi - lo)
    sx = [x for x, y in zip(X, Y) if y < th]; s = 15 / (max(sx) - min(sx))
    Xs = [(x - min(sx)) * s for x in X]; Ys = [(y - lo) * s for y in Y]
    lift = max(Ys); duty = 100 * sum(y < th for y in Y) / N; flat = 100 * sum(y <= 0.5 for y in Ys) / N
    ang = [p[1] for p in P]; un = [ang[0]]
    for a in ang[1:]:
        d = a - un[-1]; d -= 2 * math.pi * round(d / (2 * math.pi)); un.append(un[-1] + d)
    swing = math.degrees(max(un) - min(un))
    rate = max(abs(un[(i + 1) % N] - un[i] - 2 * math.pi * round((un[(i + 1) % N] - un[i]) / (2 * math.pi))) for i in range(N)) / (2 * math.pi / N)
    sl = f"; bar slides {(max(p[2] for p in P) - min(p[2] for p in P)) * s:.1f} cm through its pivot" if P[0][2] else ""
    print(f"{name:22s} lift {lift:5.2f} cm; duty {duty:4.1f}%; within 0.5 cm {flat:4.1f}%; foot link swings {swing:5.1f} deg, fastest {rate:4.2f} deg per crank deg{sl}")
    ax.plot(Xs, Ys, label=name, lw=1.8 if "Spears" in name else 1.2, ls="-" if "Spears" in name else "--")
ax.set_aspect("equal"); ax.set_xlabel("along the walk (cm), each scaled to stride 15"); ax.set_ylabel("height (cm)")
ax.legend(fontsize=8); ax.set_title("Ideal foot paths (Walking_Linkages.lua)")
fig.tight_layout(); fig.savefig("/home/claude/work/paths4.png", dpi=110)
