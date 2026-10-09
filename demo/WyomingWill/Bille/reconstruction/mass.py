"""Mass design for the reconstructed Bille.

Frame: 6 carbon-fibre tubes along the edges, OD 1 mm, ID 0.5 mm, 1.36 g/cm^3.
Heavy part: tungsten carbide (14.15 g/cm^3) filling the part of the tetrahedron
on one side of a plane (the "planar interface"); here the wedge along edge BC.
Optional glue at the four joints.
Choose the plane so that the total mass is ~120 g and the combined centre of
mass lies as deep as possible inside the face-D loading zone.
"""
import itertools
import numpy as np
from scipy.spatial import HalfspaceIntersection, ConvexHull
from scipy.optimize import brentq, minimize
from zones import tetra_halfspaces

RHO_CF, RHO_WC, RHO_GLUE = 1.36e-3, 14.15e-3, 1.3e-3      # g/mm^3
TUBE_AREA = np.pi / 4 * (1.0**2 - 0.5**2)                   # mm^2
EDGES = list(itertools.combinations(range(4), 2))


def poly_mass_props(pts):
    """volume, centroid and inertia tensor about the origin (unit density) of a convex polytope"""
    hull = ConvexHull(pts)
    c0 = pts.mean(0)
    vol = 0.0; mom = np.zeros(3); II = np.zeros((3, 3))
    for s in hull.simplices:
        a, b, c = pts[s]
        # tetra (c0, a, b, c)
        v = abs(np.dot(a - c0, np.cross(b - c0, c - c0))) / 6
        P = np.array([c0, a, b, c])
        cen = P.mean(0)
        # second moment of a tetra: (v/20) * (sum_i p_i p_i^T + (sum p)(sum p)^T)
        S = P.sum(0)
        M2 = v / 20 * (P.T @ P + np.outer(S, S))
        vol += v; mom += v * cen; II += M2
    return vol, mom / vol, II


def heavy_part(V, n, c):
    """polytope {x in tetra : n.x >= c}"""
    T = tetra_halfspaces(V)
    H = np.vstack([T, np.r_[-n, c]])
    # interior point: centroid of vertices on the heavy side plus a bit
    side = V[(V @ n) >= c]
    if len(side) == 0:
        return None
    ip = None
    for w in np.linspace(0.02, 0.5, 25):
        cand = (1 - w) * side.mean(0) + w * V.mean(0)
        if np.all(H[:, :3] @ cand + H[:, 3] < -1e-9):
            ip = cand; break
    if ip is None:
        return None
    try:
        hs = HalfspaceIntersection(H, ip)
    except Exception:
        return None
    return hs.intersections


def frame_props(V, glue=0.0, heavy=None):
    """mass, centre of mass and inertia (about origin) of tubes (+ glue at vertices)"""
    m_tot = 0.0; mom = np.zeros(3); II = np.zeros((3, 3))
    lam = RHO_CF * TUBE_AREA
    for i, j in EDGES:
        a, b = V[i], V[j]
        L = np.linalg.norm(b - a)
        m = lam * L
        mid = (a + b) / 2
        d = b - a
        # thin rod: integral of x x^T = m (mid mid^T + d d^T / 12)
        II += m * (np.outer(mid, mid) + np.outer(d, d) / 12)
        m_tot += m; mom += m * mid
    for p in V:
        II += glue * np.outer(p, p); m_tot += glue; mom += glue * p
    return m_tot, mom / m_tot, II


def design(V, normal, wc_volume, glue=0.0):
    """for a plane normal, find offset c giving the requested WC volume"""
    n = normal / np.linalg.norm(normal)
    proj = V @ n
    def f(c):
        pts = heavy_part(V, n, c)
        if pts is None:
            return -wc_volume
        return poly_mass_props(pts)[0] - wc_volume
    lo, hi = proj.min() + 1e-6, proj.max() - 1e-6
    try:
        c = brentq(f, lo, hi, xtol=1e-9)
    except ValueError:
        return None
    pts = heavy_part(V, n, c)
    vol, cen, I2 = poly_mass_props(pts)
    m_wc = RHO_WC * vol
    m_fr, c_fr, I_fr = frame_props(V, glue)
    M = m_wc + m_fr
    com = (m_wc * cen + m_fr * c_fr) / M
    I2_tot = RHO_WC * I2 + I_fr                     # second moments about origin
    # inertia tensor about the COM
    S = I2_tot - M * np.outer(com, com)
    I_com = np.trace(S) * np.eye(3) - S
    return dict(n=n, c=c, pts=pts, wc_volume=vol, m_wc=m_wc, m_frame=m_fr, M=M, com=com,
                I=I_com, wc_centroid=cen)


def depth_in(Z_H, x):
    """signed distance of x inside a polytope given as halfspaces A x + b <= 0 (unit normals)"""
    A, b = Z_H[:, :3], Z_H[:, 3]
    nrm = np.linalg.norm(A, axis=1)
    return np.min(-(A @ x + b) / nrm)
