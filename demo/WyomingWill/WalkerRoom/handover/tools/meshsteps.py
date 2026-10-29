#!/usr/bin/env python3
# The steps as the walkers meet them: the room's ground mesh (2.73 cm cells, each split on one diagonal) sampled from
# sharp-edged ledges AMP high, at random angles up to 15 degrees. Along each ledge's edge: how far across the edge
# the mesh takes to rise from 10% to 90% of the step (the face's run), the face's angle from that, and whether the top
# reaches full height within 1 cm and 3 cm of where the sharp edge would be.
import math, random
import numpy as np
AMP, BUMP = 7.0, 15.0
CELL = BUMP / 5.5
X0, Z0 = -500.0, -400.0
def ledge(x, z, u, th):   # one up-step: 0 before, AMP after (across the edge, the way it walks)
    return np.where((x - u) * math.cos(th) + z * math.sin(th) > 0, AMP, 0.0)
def mesh(x, z, u, th):
    i = np.floor((x - X0) / CELL); j = np.floor((z - Z0) / CELL)
    xa, za = X0 + i * CELL, Z0 + j * CELL; xb, zb = xa + CELL, za + CELL
    s, t = (x - xa) / CELL, (z - za) / CELL
    haa, hab, hba, hbb = ledge(xa, za, u, th), ledge(xa, zb, u, th), ledge(xb, za, u, th), ledge(xb, zb, u, th)
    h1 = haa + s * (hba - haa) + t * (hab - haa)
    h2 = hbb + (1 - s) * (hab - hbb) + (1 - t) * (hba - hbb)
    return np.where(s + t <= 1, h1, h2)
rng = random.Random(1)
runs, ang, low1, low3 = [], [], [], []
for k in range(400):
    th = math.radians(rng.uniform(-15, 15)); u = rng.uniform(-200, 200)
    for z in np.arange(-30, 30, 0.5):
        d = np.linspace(-6, 6, 1201)   # across the edge, cm (0: the sharp edge)
        x = u + (d - z * math.sin(th)) / math.cos(th)
        h = mesh(x, np.full_like(x, z), u, th)
        a = d[np.argmax(h > 0.1 * AMP)]; b = d[np.argmax(h > 0.9 * AMP)]
        runs.append(b - a); ang.append(math.degrees(math.atan2(0.8 * AMP, max(b - a, 1e-6))))
        low1.append(h[np.searchsorted(d, 1.0)]); low3.append(h[np.searchsorted(d, 3.0)])
runs, ang, low1, low3 = map(np.array, (runs, ang, low1, low3))
print(f"face run (10% to 90% of the 7 cm): mean {runs.mean():.2f} cm, 10% {np.percentile(runs, 10):.2f}, 90% {np.percentile(runs, 90):.2f}, longest {runs.max():.2f}")
print(f"face angle: mean {ang.mean():.0f} deg, 10% {np.percentile(ang, 10):.0f}, 90% {np.percentile(ang, 90):.0f}, least steep {ang.min():.0f}")
print(f"height 1 cm past the sharp edge: mean {low1.mean():.2f} cm, lowest {low1.min():.2f}; 3 cm past: mean {low3.mean():.2f}, lowest {low3.min():.2f}")
print(f"the plateau's top: {AMP:.1f} cm everywhere past {np.percentile(runs, 100):.1f} cm (a mesh point is on it)")
