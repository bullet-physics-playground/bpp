"""Fast exact evaluator for k-fold symmetric ring stacks (aligned regular k-gon
rings + apex on the axis), used inside the optimiser.  Everything reduces to
the 2D 'apothem profile' (faces' normals lie in the meridian planes through
the face midlines).  Cross-sections are regular k-gons with apothem a(z):
area = k a^2 tan(pi/k).  Outer and void apothem profiles are piecewise linear,
so the volume integrals are exact (Simpson is exact for the cubic z*a^2).
Margins: face = 2D foot distance in the meridian (exact for a trapezoid when
the foot is on the midline); vertex = 3D distance from the COM to the
equilibrium cone of a ring vertex (NNLS), one vertex per ring by symmetry.
The full 3D code in core.py is used to verify every result."""
import numpy as np
from scipy.optimize import nnls

RHO = 1.24

def profile(R, Z, H, k):
    a = np.asarray(R) * np.cos(np.pi / k)
    P = np.c_[np.r_[0.0, a, 0.0], np.r_[Z[0], Z, H]]   # (0,0)->(a0,0)->...->(0,H)
    return P

def seg_lines(P):
    """side segments i: from P[i] to P[i+1] for i=1..n (ring i-1 -> ring i / apex)
    returns outward unit normals (nr, nz) and offsets d with nr*a+nz*z+d<=0 inside"""
    out = []
    for i in range(1, len(P) - 1):
        p, q = P[i], P[i + 1]
        t = q - p; nrm = np.array([t[1], -t[0]]); nrm /= np.linalg.norm(nrm)
        # outward: away from axis interior point
        d = -nrm @ p
        out.append((nrm, d))
    return out

def convex_ok(P):
    """profile polygon (closed with the axis) strictly convex with ccw turn"""
    Q = np.r_[P, [[0.0, P[-1][1]]]][:-1]
    n = len(P)
    for i in range(1, n - 1):
        u = P[i] - P[i - 1]; w = P[i + 1] - P[i]
        if u[0] * w[1] - u[1] * w[0] <= 1e-9: return False
    return True

def _int_poly(z0, z1, a_fun):
    """exact integrals of a(z)^2 and z a(z)^2 for linear a on [z0,z1] (Simpson)"""
    zm = (z0 + z1) / 2; h = z1 - z0
    f = lambda z: a_fun(z) ** 2
    A2 = h / 6 * (f(z0) + 4 * f(zm) + f(z1))
    g = lambda z: z * a_fun(z) ** 2
    ZA2 = h / 6 * (g(z0) + 4 * g(zm) + g(z1))
    h2 = lambda z: z * z * a_fun(z) ** 2
    # z^2 a^2 is quartic: use 3-point Gauss-Legendre (exact to degree 5)
    xg = np.array([-np.sqrt(3 / 5), 0, np.sqrt(3 / 5)]); wg = np.array([5, 8, 5]) / 9
    zz = zm + h / 2 * xg
    Z2A2 = h / 2 * np.sum(wg * zz * zz * np.array([a_fun(q) ** 2 for q in zz]))
    a4 = lambda z: a_fun(z) ** 4
    A4 = h / 2 * np.sum(wg * np.array([a4(q) for q in zz]))   # quartic, exact
    return A2, ZA2, Z2A2, A4

def lines_min_profile(lines, t, zlo, zhi):
    """void apothem a_v(z) = min_f ( -(d_f + t) - nz_f z ) / nr_f over side faces
    with nr_f > 0; returns breakpoints and a callable on [zlo, zhi]"""
    L = [((-(d + t)) / nr, -nz / nr) for (nr, nz), d in [(l[0], l[1]) for l in lines] if nr > 1e-12]
    # also faces with nr<=0 (overhang below?) cannot occur for a convex profile above the base
    def a_fun(z): return min(c0 + c1 * z for c0, c1 in L)
    bps = [zlo, zhi]
    for i in range(len(L)):
        for j in range(i + 1, len(L)):
            if abs(L[i][1] - L[j][1]) > 1e-15:
                zz = (L[j][0] - L[i][0]) / (L[i][1] - L[j][1])
                if zlo < zz < zhi: bps.append(zz)
    # where a_v crosses 0 (top of void)
    bps = sorted(set(bps))
    # find top: last z where a_fun >= 0
    out = [bps[0]]
    for z in bps[1:]:
        if a_fun(z) < 0:
            # root between out[-1] and z on a linear piece
            z0 = out[-1]; f0 = a_fun(z0); f1 = a_fun(z)
            if f0 > 0: out.append(z0 + (z - z0) * f0 / (f0 - f1))
            break
        out.append(z)
    return out, a_fun

def outer_fun(P):
    zs = P[1:, 1]; as_ = P[1:, 0]
    def a_fun(z): return np.interp(z, zs, as_)
    return list(zs), a_fun

def integrals(bps, a_fun):
    I = np.zeros(4)
    for z0, z1 in zip(bps[:-1], bps[1:]):
        if z1 > z0: I += _int_poly(z0, z1, a_fun)
    return I

def mass_z(R, Z, H, k, t, zs, rho=RHO, voids=True):
    """mass (g), COM height (cm), Izz and Ixx about COM (g cm^2)"""
    P = profile(R, Z, H, k)
    K = k * np.tan(np.pi / k)              # area = K a^2
    bo, fo = outer_fun(P)
    Io = integrals(bo, fo)
    if voids:
        lines = seg_lines(P)
        bv, fv = lines_min_profile(lines, t, zs, H)
        Iv = integrals(bv, fv) if len(bv) > 1 else np.zeros(4)
    else:
        Iv = np.zeros(4)
    I = Io - Iv
    vol = K * I[0]; zc = K * I[1] / vol
    M = rho * vol
    # polar moment of a regular k-gon with apothem a about its centre: J = A*(a^2/... ) :
    # J = (k/6) * ... use: for regular k-gon with circumradius r: J = (A r^2/6)(2+cos(2pi/k))... with
    # r = a / cos(pi/k).  Area A = K a^2 -> J = K a^4 (2+cos(2pi/k)) / (6 cos^2(pi/k))
    cJ = K * (2 + np.cos(2 * np.pi / k)) / (6 * np.cos(np.pi / k) ** 2)
    Izz = rho * cJ * I[3]
    Ixx = rho * (cJ / 2 * I[3] + K * I[2]) - M * zc ** 2
    return M, zc, Izz, Ixx, vol, K * Iv[0]

def face_margins(P, zc):
    """2D signed foot distances for each side segment (positive = outside)"""
    C = np.array([0.0, zc]); out = []
    for i in range(1, len(P) - 1):
        p, q = P[i], P[i + 1]; u = q - p; L = np.linalg.norm(u); u /= L
        s = (C - p) @ u
        if s < 0: out.append(-s)
        elif s > L: out.append(s - L)
        else: out.append(-min(s, L - s))
    return np.array(out)

def vertex_margins(R, Z, H, k, zc):
    """distance from COM to the equilibrium cone of the ring vertex at azimuth 0"""
    P = profile(R, Z, H, k)
    lines = seg_lines(P)          # lines[i]: segment ring i-1 -> ring i (i=0: base ring -> ring 1 ... last: top ring -> apex)
    c = np.array([0, 0, zc]); out = []
    n = len(R)
    for i in range(n):
        v = np.array([R[i], 0, Z[i]])
        ns = []
        for li in ([i - 1] if i > 0 else []) + [i]:
            (nr, nz), _ = lines[li]
            for ph in (np.pi / k, -np.pi / k):
                ns.append([nr * np.cos(ph), nr * np.sin(ph), nz])
        if i == 0: ns.append([0, 0, -1.0])
        _, r = nnls(np.array(ns).T, v - c)
        out.append(r)
    return np.array(out)
