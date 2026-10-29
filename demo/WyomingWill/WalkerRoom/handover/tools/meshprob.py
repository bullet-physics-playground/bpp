#!/usr/bin/env python3
# The logs as the walkers meet them: the room's ground is a triangle mesh (cells 15/5.5 = 2.73 cm, each split along
# one diagonal) sampled from the smooth ridges, so a log's top, where it runs between the mesh's points, is lower than
# 7 cm, by an amount that changes along the log when the log runs at an angle to the mesh. (1) How high the mesh's
# logs are along their length. (2) For a diag build's bottom brace (from its held-body sweep, at its lowest in the
# turn, body level, ground flat): how often a log is higher than the brace somewhere under it, and how often that
# happens when both of the brace's own feet could clear the log where they cross it (the mesh lower than the foot
# path's lift across each foot's width).
import sys, math, random
sys.path.insert(0, "/home/claude/work")
import numpy as np
import braceprob
AMP, BUMP = 7.0, 15.0
CELL = BUMP / 5.5
X0, Z0 = -500.0, -400.0
def ridge(x, z, u, th):
    d = ((x - u) * math.cos(th) + z * math.sin(th)) / BUMP
    return np.where(np.abs(d) < 0.25, AMP * np.cos(d * 2 * math.pi) ** 2, 0.0)
def mesh(x, z, u, th):
    i = np.floor((x - X0) / CELL); j = np.floor((z - Z0) / CELL)
    xa, za = X0 + i * CELL, Z0 + j * CELL; xb, zb = xa + CELL, za + CELL
    s, t = (x - xa) / CELL, (z - za) / CELL   # 0..1 in the cell
    haa, hab, hba, hbb = ridge(xa, za, u, th), ridge(xa, zb, u, th), ridge(xb, za, u, th), ridge(xb, zb, u, th)
    lower = s + t <= 1   # triangle (xa,za),(xa,zb),(xb,za)
    h1 = haa + s * (hba - haa) + t * (hab - haa)
    h2 = hbb + (1 - s) * (hab - hbb) + (1 - t) * (hba - hbb)
    return np.where(lower, h1, h2)
rng = random.Random(1)
# (1) the logs' tops along their length
tops = []
for k in range(400):
    th = math.radians(rng.uniform(-15, 15)); u = rng.uniform(-200, 200)
    for z in np.arange(-30, 30, 0.5):
        dd = np.linspace(-3.75, 3.75, 151)
        xs = u + (dd - z * math.sin(th)) / math.cos(th)
        tops.append(mesh(xs, np.full_like(xs, z), u, th).max())
tops = np.array(tops)
print(f"(1) a mesh log's top along its length: mean {tops.mean():.2f} cm, lowest {tops.min():.2f}, 10% {np.percentile(tops, 10):.2f}, "
      f"90% {np.percentile(tops, 90):.2f}; under 6 cm {100 * (tops < 6).mean():.0f}% of its length, under 5.5 {100 * (tops < 5.5).mean():.0f}%")
def lowest_brace(path):
    name, M = braceprob.brace_points(path)
    k = min(range(len(M)), key=lambda m: min(y for _, _, y, _ in M[m]))
    return M[k]
def analyse(path, lift, label, N=6000):
    pts = lowest_brace(path)
    bx = np.array([p[0] for p in pts]); bz = np.array([p[1] for p in pts]); by = np.array([p[2] for p in pts])
    runz = sorted({round(p[1], 2) for p in pts if p[3] == "run"})
    x0, x1 = bx.min(), bx.max()
    hit = clear = hit_clear = 0
    for n in range(N):
        th = math.radians(rng.uniform(-15, 15)); u = rng.uniform(x0, x1)
        gx, gz = rng.uniform(0, CELL), rng.uniform(0, CELL)   # where the walker stands on the mesh
        hb = mesh(bx + gx, bz + gz, u + gx, th)   # (shifting the walker and the log together over the mesh)
        h = bool((hb > by).any())
        ok = True
        for zc in runz:   # the brace's own two feet: 12 cm wide bands centred on its runs' z (the pendants)
            zz = np.linspace(zc - 6, zc + 6, 25)
            best = 0
            for z in zz:
                dd = np.linspace(-3.75, 3.75, 61)
                xs = u + (dd - z * math.sin(th)) / math.cos(th)
                best = max(best, mesh(xs + gx, np.full_like(xs, z + gz), u + gx, th).max())
            if best >= lift: ok = False
        hit += h; clear += ok; hit_clear += (h and ok)
    print(f"(2) {label:44s} brace {by.min():.2f} cm up at its lowest: a log under it higher than it {hit / N:.3f}; "
          f"its feet could clear {clear / N:.3f}; brace hits when they could {hit_clear / max(clear, 1):.3f}")
analyse("sweep6W/Chebyshev-Spears_diag.txt", 4.65, "Chebyshev-Spears diag (zig-zag)")
analyse("sweepSD2/Hoecken-Spears_slider_diag.txt", 4.89, "Hoecken-Spears slider diag (diagonal)")
analyse("sweepBX/Hoecken-Spears_slider_diag_shape.txt", 4.89, "H-S slider diag with CS's zig-zag")
