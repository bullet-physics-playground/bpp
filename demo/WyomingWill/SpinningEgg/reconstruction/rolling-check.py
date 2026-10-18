"""Independent check of the standing egg: spinning-egg.lua's spheroid rolling
without slipping on a level table (Chaplygin's rolling body of revolution),
with the exhibit's spin friction (a moment kappa N against the turning about
the upright) and rolling resistance (delta N against the level part of the
turning). Integrated with scipy's DOP853 (rtol = atol = 1e-11), from the left
egg's state as the exhibit writes it:

  cd .. && HOLD_S=0 EG_STATE=1.0:/tmp/egg-state.txt bpp -f spinning-egg.lua -n 61
  python3 rolling-check.py /tmp/egg-state.txt [kappa_um delta_um t_end]

(kappa, delta in microns: default 100 100; t_end default 26 s; it stops when the
egg is back at 60 degrees). Prints tilt, spin about the upright, energy, J and
the friction needed over what it could give (|F_h| / mu N, mu 0.3: rolling is
only right while that stays below 1), and when it passes 15 and 60 degrees,
counted as the console counts (a state that has lasted 0.25 s, on frames of
1/60 s). Units: cm, kg, s.

  m dv/dt = F + m g,   d(I w)/dt = r x F + N tau,   v + w x r = 0
(r: the lowest point from the centre; tau: the two moments per unit push). The
contact force F comes from the rolling condition, differentiated once.
"""
import sys
import numpy as np
from scipy.integrate import solve_ivp

G, A, B, M = 981.0, 2.85, 2.15, 0.058
IA, IC = M * (A * A + B * B) / 5, 2 * M * B * B / 5
MU = 0.3
KAP = (float(sys.argv[2]) if len(sys.argv) > 2 else 100) * 1e-4
DLT = (float(sys.argv[3]) if len(sys.argv) > 3 else 100) * 1e-4
T1 = float(sys.argv[4]) if len(sys.argv) > 4 else 26
DOWN = np.array([0, -1.0, 0])
KK = A * A - B * B


def cross(a):
    return np.array([[0, -a[2], a[1]], [a[2], 0, -a[0]], [-a[1], a[0], 0]])


def lowest(p, pd):
    """the lowest point (from the centre) for long axis p, and its rate as p turns at pd"""
    d2 = p @ DOWN
    n = np.sqrt(B * B * (1 - d2 * d2) + A * A * d2 * d2)
    r = (B * B * DOWN + KK * d2 * p) / n
    d2d = DOWN @ pd
    nd = KK * d2 * d2d / n
    return r, KK * (d2d * p + d2 * pd) / n - r * nd / n


def solve(y):
    v, w, c = y[3:6], y[6:9], y[9:18].reshape(3, 3)
    I = IA * np.outer(c[0], c[0]) + IC * np.outer(c[1], c[1]) + IA * np.outer(c[2], c[2])
    r, rd = lowest(c[1], np.cross(w, c[1]))
    tv = np.zeros(3)
    tv[1] = -KAP * np.sign(w[1])
    wh = np.array([w[0], 0, w[2]])
    if np.linalg.norm(wh) > 1e-12:
        tv -= DLT * wh / np.linalg.norm(wh)
    K = np.zeros((9, 9))
    rhs = np.zeros(9)
    K[0:3, 0:3], K[0:3, 6:9], rhs[0:3] = M * np.eye(3), -np.eye(3), [0, -M * G, 0]
    K[3:6, 3:6], K[3:6, 6:9], rhs[3:6] = I, -cross(r), -np.cross(w, I @ w)
    K[3:6, 7] -= tv
    K[6:9, 0:3], K[6:9, 3:6], rhs[6:9] = np.eye(3), -cross(r), -np.cross(w, rd)
    s = np.linalg.solve(K, rhs)
    return s[0:3], s[3:6], s[6:9], r, I


def f(t, y):
    a, al, _, _, _ = solve(y)
    w, c = y[6:9], y[9:18].reshape(3, 3)
    return np.concatenate([y[3:6], a, al, np.array([np.cross(w, ci) for ci in c]).ravel()])


def tilt(y):
    return np.degrees(np.arccos(min(1.0, abs(y[13]))))


z = np.array([float(x) for x in open(sys.argv[1]).read().split()])
t0, y0 = z[0], z[1:19].copy()
# start exactly on the table and rolling (the exhibit's state is in floats)
c = y0[9:18].reshape(3, 3)
e1 = c[0] / np.linalg.norm(c[0])
e2 = c[1] - e1 * (e1 @ c[1])
e2 /= np.linalg.norm(e2)
y0[9:18] = np.concatenate([e1, e2, np.cross(e1, e2)])
r0, _ = lowest(e2, np.zeros(3))
y0[1], y0[3:6] = -r0[1], -np.cross(y0[6:9], r0)

t0 = round(t0 * 60) / 60          # (a frame's time, as the exhibit wrote it)
ts = np.arange(t0, T1, 1 / 60)
back = lambda t, y: tilt(y) - 60
back.terminal = True
sol = solve_ivp(f, (t0, T1), y0, method="DOP853", rtol=1e-11, atol=1e-11, t_eval=ts, events=back)

rows = []
for t, y in zip(sol.t, sol.y.T):
    a, al, F, r, I = solve(y)
    w = y[6:9]
    E = 0.5 * M * y[3:6] @ y[3:6] + 0.5 * w @ I @ w + M * G * y[1]
    rows.append((t, tilt(y), w[1] / (2 * np.pi), E / 10, -(I @ w) @ r, np.hypot(F[0], F[2]) / (MU * F[1])))
print("   t     tilt  spin (turns/s)  E (microJ)     J   |F_h|/mu N")
for row in rows:
    if abs(row[0] * 2 - round(row[0] * 2)) < 1e-6 or row is rows[-1]:
        print("%6.2f %8.3f %10.3f %12.3f %9.3f %8.3f" % row)


def passes(th0):
    since = None
    for t, th, sp, *_ in rows:
        if th >= th0:
            since = since if since is not None else (t, sp)
            if t - since[0] >= 0.25 - 1e-9:
                return since
        else:
            since = None
    return None


for th0 in (15, 30):
    p = passes(th0)
    print("past %d deg (as the console counts): %s" % (th0, "%.2f s, spinning %.1f turns/s" % p if p else "not yet"))
if sol.t_events[0].size:
    print("back at 60 deg at %.2f s" % sol.t_events[0][0])
print("most friction needed: %.3f of mu N" % max(row[5] for row in rows))
