#!/usr/bin/env python3
"""Statics of a Gomboc-C hull file, as Bullet sees it (points as 32-bit floats).

  python3 statics.py gomboc-hull.lua [more.lua ...]

For each file: the resting faces (faces whose centre-of-mass foot lies inside
them), how deep each is (the least lift of the centre of mass to roll off it),
and where a rolling-resistance moment delta*m*g can hold the body: everywhere
the horizontal distance from the contact to the centre of mass (gravity's
lever) is under delta. Along the trough (tilt about body x) this is scanned
every 0.002 deg out to 40 deg, at 75, 100 and 125% (a size s divides delta by
s), and compared with the smooth CAD cylinder. (Every other tilt: holdmap.py.)
"""
import re
import sys
import numpy as np
from scipy.spatial import ConvexHull

# the bottom cylinder of the CAD model, in body cm (gen_hull.py prints these)
RHO = 3.6
D_AXIS = 0.1147105      # axis height above the centre of mass (exact COM)


def load(path):
    s = open(path, encoding="utf-8").read()
    body = s[s.index("points = {") + 10:]
    body = body[:body.index("}")]
    v = np.array([float(x) for x in re.findall(r"-?\d+\.\d+(?:e-?\d+)?", body)])
    return v.reshape(-1, 3).astype(np.float32).astype(np.float64)


def resting_faces(P):
    P = np.asarray(P, np.float64)
    H = ConvexHull(P)
    groups = {}
    for i, e in enumerate(H.equations):
        groups.setdefault(tuple(np.round(e, 12)), []).append(i)
    out = []
    for key, idx in groups.items():
        n = np.array(key[:3])
        h = -key[3]
        vid = np.unique(H.simplices[idx].ravel())
        V = P[vid]
        e1 = np.cross(n, [1.0, 0, 0])
        if np.linalg.norm(e1) < 0.1:
            e1 = np.cross(n, [0, 0, 1.0])
        e1 /= np.linalg.norm(e1)
        e2 = np.cross(n, e1)
        Q = np.c_[V @ e1, V @ e2]
        if len(vid) == 3:
            hv = np.arange(3)
            a, b = Q[1] - Q[0], Q[2] - Q[0]
            if a[0] * b[1] - a[1] * b[0] < 0:
                hv = hv[::-1]
        else:
            hv = ConvexHull(Q).vertices          # counter-clockwise
        Pv, Qv = V[hv], Q[hv]
        m = len(hv)
        foot = 1e9
        lift = 1e9
        for i in range(m):
            a, b = Qv[i], Qv[(i + 1) % m]
            ab = b - a
            inn = np.array([-ab[1], ab[0]]) / np.linalg.norm(ab)
            foot = min(foot, (-a) @ inn)
            A, B = Pv[i], Pv[(i + 1) % m]
            u = (B - A) / np.linalg.norm(B - A)
            lift = min(lift, np.linalg.norm(-A - ((-A) @ u) * u) - h)
        if foot >= 0:
            out.append(dict(tilt=np.degrees(np.arccos(np.clip(-n[1], -1, 1))), foot_um=foot * 1e4,
                            lift_um=lift * 1e4, az=np.degrees(np.arctan2(n[2], n[0])), m=m, h=h))
    out.sort(key=lambda f: f["tilt"])
    return out


def smooth_bound(s, delta):
    """largest tilt about x at which the smooth cylinder can be held (deg)"""
    return np.degrees(np.arcsin(delta / (s * D_AXIS)))


def trough_scan(P, step=0.002, lim=40.0):
    """tilt about x (theta > 0: the down direction toward +z); gravity's lever
    along the tilt (signed: > 0 turns it back toward smaller theta)"""
    th = np.radians(np.arange(-lim, lim + 1e-9, step))
    n = np.stack([0 * th, -np.cos(th), np.sin(th)], 1)
    t = np.stack([0 * th, np.sin(th), np.cos(th)], 1)
    lev = np.empty(len(th))
    for i0 in range(0, len(th), 2000):
        sl = slice(i0, i0 + 2000)
        k = (P @ n[sl].T).argmax(0)
        lev[sl] = np.einsum("ij,ij->i", P[k], t[sl])
    return np.degrees(th), lev


def bands(deg, lev, s, delta):
    hold = np.abs(lev) <= delta / s
    out = []
    i = 0
    while i < len(deg):
        if hold[i]:
            j = i
            while j + 1 < len(deg) and hold[j + 1]:
                j += 1
            out.append((deg[i], deg[j]))
            i = j + 1
        else:
            i += 1
    return out


def report(path, delta=0.015):
    P = load(path)
    print("== %s: %d points (as float32)" % (path, len(P)))
    rf = resting_faces(P)
    print("resting faces: %d, out to %.3f deg; deepest needs a %.4f micron lift (at %.2f deg)"
          % (len(rf), max(f["tilt"] for f in rf), max(f["lift_um"] for f in rf),
             max(rf, key=lambda f: f["lift_um"])["tilt"]))
    for f in rf:
        if f["tilt"] > 1.0 or f["lift_um"] > 0.1:
            print("   tilt %7.3f  az %6.1f  %d-gon  foot inside %6.2f um  lift to leave %.4f um"
                  % (f["tilt"], f["az"], f["m"], f["foot_um"], f["lift_um"]))
    deg, lev = trough_scan(P)
    for s in (0.75, 1.0, 1.25):
        b = bands(deg, lev, s, delta)
        sm = smooth_bound(s, delta)
        far = [x for x in b if max(abs(x[0]), abs(x[1])) > sm + 0.01]
        hi = max(max(abs(x[0]), abs(x[1])) for x in b)
        cont = [x for x in b if x[0] <= 0 <= x[1]][0]
        print("size %3.0f%%: smooth cylinder holds out to %.2f deg; hull: continuous %.2f..%.2f, "
              "furthest hold %.2f deg, %d bands beyond the smooth bound%s"
              % (s * 100, sm, cont[0], cont[1], hi, len(far),
                 (": " + ", ".join("%.2f..%.2f" % x for x in far[:12]) + (" ..." if len(far) > 12 else "")) if far else ""))
    return rf


if __name__ == "__main__":
    for p in sys.argv[1:]:
        report(p)
