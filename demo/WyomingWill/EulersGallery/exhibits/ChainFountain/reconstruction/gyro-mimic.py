"""A stand-in for Bullet's step on a hanging chain of spinning links (ball joints, sequential
impulses with Baumgarte ERP, exp-map orientation update), to see which way of adding the
gyroscopic term is stable. Units cm, kg, s, as the exhibit.
usage: mimic.py scheme steps N T  (scheme: none | pre | mid | implicit_solve)
  pre:   exact rotation of w_perp about the axis before the step (the exhibit's)
  mid:   the same rotation, applied after the solve and before the positions move
  implicit_solve: the solve itself uses the gyroscopic step, linearised and implicit
"""
import sys, math, random
import numpy as np

scheme = sys.argv[1]; STEPS = int(sys.argv[2]); N = int(sys.argv[3]); T = float(sys.argv[4])
S0 = float(sys.argv[5]) if len(sys.argv) > 5 else 300.0
DT = 1.0 / STEPS
G = 981.0
M = 0.0005 * 0.65 / 1.5
RL, L = 0.225, 0.65
IP, IA = M * (L * L / 4 + 0.4 * RL * RL), 0.4 * M * RL * RL
K = (IP - IA) / IP
ERP, ITERS = 0.5, 20
random.seed(1)

def qmul(a, b):
    ax, ay, az, aw = a; bx, by, bz, bw = b
    return np.array([aw*bx + ax*bw + ay*bz - az*by, aw*by - ax*bz + ay*bw + az*bx,
                     aw*bz + ax*by - ay*bx + az*bw, aw*bw - ax*bx - ay*by - az*bz])
def qrotm(q):
    x, y, z, w = q
    return np.array([[1-2*(y*y+z*z), 2*(x*y-w*z), 2*(x*z+w*y)],
                     [2*(x*y+w*z), 1-2*(x*x+z*z), 2*(y*z-w*x)],
                     [2*(x*z-w*y), 2*(y*z+w*x), 1-2*(x*x+y*y)]])
def qexp(w, dt):
    n = np.linalg.norm(w)
    if n * dt < 1e-14: return np.array([0, 0, 0, 1.0])
    h = 0.5 * n * dt
    return np.concatenate([w * math.sin(h) / n, [math.cos(h)]])
def skew(a):
    return np.array([[0, -a[2], a[1]], [a[2], 0, -a[0]], [-a[1], a[0], 0]])

# links hanging straight down from (0,100,0): body x along -y
qd = np.array([0, 0, math.sin(-math.pi/4), math.cos(-math.pi/4)])
c = np.array([[0.0, 100 - (i + 0.5) * L, 0.0] for i in range(N)])
q = np.array([qd.copy() for i in range(N)])
v = np.zeros((N, 3))
w = np.array([[5 * (random.random() - .5), -S0, 5 * (random.random() - .5)] for i in range(N)])
anchor = np.array([0.0, 100.0, 0.0])
Ib = np.array([IA, IP, IP])

def gyro_rot(i, wv, dt):
    e = qrotm(q[i])[:, 0]
    s = wv @ e
    p = wv - s * e
    cx = np.cross(e, p)
    th = -K * s * dt
    return s * e + math.cos(th) * p + math.sin(th) * cx

def energy():
    E = 0
    for i in range(N):
        R = qrotm(q[i]); wb = R.T @ w[i]
        E += 0.5 * M * v[i] @ v[i] + 0.5 * (Ib * wb * wb).sum() + M * G * c[i][1]
    return E

def across():
    t = 0
    for i in range(N):
        e = qrotm(q[i])[:, 0]; s = w[i] @ e; t += w[i] @ w[i] - s * s
    return math.sqrt(t / N)

E0 = energy(); KS = N * 0.5 * IA * S0 * S0
nsteps = int(round(T * STEPS))
for n in range(nsteps):
    if scheme == "pre":
        for i in range(N): w[i] = gyro_rot(i, w[i], DT)
    eold = [qrotm(q[i])[:, 0] for i in range(N)]
    v[:, 1] -= G * DT
    Rs = [qrotm(q[i]) for i in range(N)]
    Iinv = [R @ np.diag(1 / Ib) @ R.T for R in Rs]
    if scheme in ("implicit_solve", "midpoint_solve"):
        # body response to an angular impulse through the linearised implicit gyroscopic step:
        # (I + dt * Jg) dw = impulse, Jg = d(w x I w)/dw at w (world), and the free part of the step
        Aw = []
        for i in range(N):
            Iw = Rs[i] @ np.diag(Ib) @ Rs[i].T
            Jg = skew(w[i]) @ Iw - skew(Iw @ w[i])
            A = Iw + (DT if scheme == "implicit_solve" else DT / 2) * Jg
            Ainv = np.linalg.inv(A)
            # free step: solve A dw = -dt w x I w (one Newton step of backward Euler: Bullet's formula)
            w[i] = w[i] + Ainv @ (-DT * np.cross(w[i], Iw @ w[i]))
            Aw.append(Ainv)
        Iinv = Aw
    # joints: j=0 anchor-link0(-L/2); j>=1 link j-1 (+L/2) to link j (-L/2)
    for it in range(ITERS):
        for j in range(N):
            b = j
            rb = Rs[b] @ np.array([-L / 2, 0, 0])
            if j == 0:
                a = None; pa = anchor
            else:
                a = j - 1; ra = Rs[a] @ np.array([L / 2, 0, 0]); pa = c[a] + ra
            pb = c[b] + rb
            Cerr = pa - pb
            for k in range(3):
                n_ = np.zeros(3); n_[k] = 1
                # relative velocity along n: (va + wa x ra - vb - wb x rb) . n
                rel = -(v[b] + np.cross(w[b], rb))[k]
                Kd = 1 / M + (np.cross(Iinv[b] @ np.cross(rb, n_), rb)) @ n_
                if a is not None:
                    rel += (v[a] + np.cross(w[a], ra))[k]
                    Kd += 1 / M + (np.cross(Iinv[a] @ np.cross(ra, n_), ra)) @ n_
                rhs = -ERP / DT * Cerr[k] - rel
                lam = rhs / Kd
                # impulse +lam n on a, -lam n on b
                v[b] -= lam * n_ / M; w[b] -= Iinv[b] @ np.cross(rb, lam * n_)
                if a is not None:
                    v[a] += lam * n_ / M; w[a] += Iinv[a] @ np.cross(ra, lam * n_)
    if scheme == "mid":
        for i in range(N): w[i] = gyro_rot(i, w[i], DT)
    for i in range(N):
        c[i] = c[i] + v[i] * DT
        q[i] = qmul(qexp(w[i], DT), q[i]); q[i] /= np.linalg.norm(q[i])
    if scheme == "transport":
        # a free symmetric link has w = L/IP + k s e: so w moves by k s (e_new - e_old)
        for i in range(N):
            en = qrotm(q[i])[:, 0]
            sp = w[i] @ eold[i]
            w[i] = w[i] + K * sp * (en - eold[i])
    if (n + 1) % (STEPS // 4) == 0:
        print(f"t={(n+1)*DT:5.2f} {scheme:15s} {STEPS} N={N} across {across():8.2f} rad/s  (E-E0)/KEspin {(energy()-E0)/KS:+9.4f}", flush=True)
