#!/usr/bin/env python3
"""Where rolling resistance can hold a hull, over every tilt, against the CAD body.

  python3 holdmap.py cadlever.npz gomboc-hull.lua [more.lua ...]

Every direction on a 0.1 deg (tilt from upright) x 0.25 deg (azimuth) grid
is taken as "down"; the hull's lowest point there gives gravity's lever (its
horizontal distance from the centre of mass). The hull can be held where the
lever is at most delta/s (delta = 150 microns; size s = 75, 100, 125%). Each
such direction is checked against the CAD body's lever map (cadlever.py): the
least CAD lever among CAD normals within 0.3 deg. If that is over delta/s the
hold is false (made by the facets). Cells are counted by tilt band. Only point
contacts are seen here: lying along the trough's straight lines (a line
contact) the lever is the distance to the line, which statics.py scans.
-v also lists the false-hold regions.
"""
import sys
import numpy as np
from scipy.spatial import cKDTree

sys.path.insert(0, __file__.rsplit("/", 1)[0])
import statics

DELTA = 0.015
VERBOSE = False


def hull_levers(P, dth=0.1, dph=0.25):
    TH = np.radians(np.arange(dth / 2, 180, dth))
    PH = np.radians(np.arange(0, 360, dph))
    T, F = np.meshgrid(TH, PH, indexing="ij")
    T, F = T.ravel(), F.ravel()
    n = np.stack([np.sin(T) * np.cos(F), -np.cos(T), np.sin(T) * np.sin(F)], 1)
    lev = np.empty(len(T))
    P32 = P.astype(np.float64)
    for i0 in range(0, len(T), 20000):
        sl = slice(i0, i0 + 20000)
        k = (P32 @ n[sl].T).argmax(0)
        p = P32[k]
        lev[sl] = np.linalg.norm(p - np.einsum("ij,ij->i", p, n[sl])[:, None] * n[sl], axis=1)
    return np.degrees(T), np.degrees(F), n, lev


def clusters(th, az, mask):
    """group held grid cells into regions (by tilt and azimuth, 1 deg)"""
    pts = sorted(zip(np.round(th[mask], 2), np.round(az[mask], 2)))
    out = []
    for t, a in pts:
        for c in out:
            if abs(c["t1"] - t) <= 1.0 and min(abs(((a - b + 180) % 360) - 180) for b in c["az"][-20:]) <= 1.0:
                c["t1"] = max(c["t1"], t); c["t0"] = min(c["t0"], t); c["az"].append(a); c["n"] += 1
                break
        else:
            out.append(dict(t0=t, t1=t, az=[a], n=1))
    return out


def report(cad, path):
    P = statics.load(path)
    th, az, n, lev = hull_levers(P)
    tree, CL = cad
    print("== %s (%d points)" % (path, len(P)))
    for s in (0.75, 1.0, 1.25):
        d = DELTA / s
        held = lev <= d
        idx = np.where(held)[0]
        cadmin = np.full(len(th), np.inf)
        for i, nb in zip(idx, tree.query_ball_point(n[idx], 2 * np.sin(np.radians(0.3) / 2))):
            if nb:
                cadmin[i] = CL[nb].min()
        false = held & (cadmin > d)
        real = held & ~false
        cl = clusters(th, az, false) if VERBOSE else []
        cl.sort(key=lambda c: -c["t1"])
        print("size %3.0f%%: held cells %d (genuine %d, false %d); false out to %.1f deg"
              % (s * 100, held.sum(), real.sum(), false.sum(), th[false].max() if false.any() else 0))
        hist = np.histogram(th[real], bins=[0, 30, 60, 90, 120, 150, 180])[0]
        print("     genuine cells by tilt 0-30-60-90-120-150-180 deg: %s" % " ".join(str(x) for x in hist))
        hist = np.histogram(th[false], bins=[0, 30, 60, 90, 120, 150, 180])[0]
        print("     false cells by tilt 0-30-60-90-120-150-180 deg: %s" % " ".join(str(x) for x in hist))
        if VERBOSE:
            print("     false holds in %d regions; the furthest from upright:" % len(cl))
            for c in cl[:8]:
                a = np.array(c["az"])
                print("     tilt %5.1f..%5.1f  azimuth %6.1f..%6.1f  %d cells" % (c["t0"], c["t1"], a.min(), a.max(), c["n"]))


if __name__ == "__main__":
    args = sys.argv[1:]
    if args[0] == "-v":
        VERBOSE = True
        args = args[1:]
    z = np.load(args[0])
    cad = (cKDTree(z["n"]), z["L"])
    for p in args[1:]:
        report(cad, p)
