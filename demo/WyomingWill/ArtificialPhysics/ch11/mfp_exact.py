#!/usr/bin/env python3
"""ch11/mfp_exact.py -- the mean free path integrals of Sec. 11.3, 2D and 3D.

The mean free path is the mean distance from a robot uniform in a unit cell
to an entry point uniform on the side (2D) or face (3D) it shares with the
next cell (Eq. 11.2 in 2D). With u = 1 - x1 uniform and the lateral
differences y1 - y2, z1 - z2 triangular on [-1, 1], the inner integral over
u has a closed form and what is left is a 1D (2D case) or 2D (3D case)
integral of smooth functions, evaluated here to 60 digits with mpmath.

An integer-relation search (PSLQ) then finds closed forms:

    2D:  12 E = 2 + sqrt2 + 5 ln(1 + sqrt2)                       = 0.651756791456...
    3D:  90 E = 4 + 17 sqrt2 - 6 sqrt3 - 7 pi
                + 21 ln(1 + sqrt2) + 42 ln(2 + sqrt3)             = 0.771991712645...

The 2D form equals the book's Eq. 11.3-11.4 (0.651757). Both hold to 50
digits at 60-digit precision with small coefficients, which is very strong
evidence; they were found by search, not proved. The 3D form uses the same
constants as Robbins' closed form for the mean distance between two random
points in a unit cube.

Also printed: the 5% buffer variant of Sec. 11.3 (robot x1 in [0.05, 1],
lateral coordinates in [0.05, 0.95]; book: 0.6079), and the values with the
entry at x2 = 1.001 as in Listing 11.4, which a simulation should match.

    pip install mpmath   (if missing)
    python3 ch11/mfp_exact.py          (about 30 s)
"""

from mpmath import mp, mpf, sqrt, log, quad, pi, pslq

mp.dps = 60


def F(c, u):
    """Antiderivative in u of sqrt(u^2 + c^2)."""
    s = sqrt(u * u + c * c)
    return u * s / 2 + (c * c / 2 * log(u + s) if c > 0 else 0)


def mean_free_path(dim, L=1, W=1, eps=0):
    """Mean distance. The robot is uniform over a depth L of the cell
    (u = x2 - x1 uniform on [eps, L + eps]); lateral coordinates are uniform
    over a width W, so each difference is triangular on [-W, W]."""
    def g(c):
        return (F(c, L + eps) - F(c, eps)) / L
    if dim == 2:
        return 2 * quad(lambda a: (W - a) / W ** 2 * g(a), [0, W])
    return 4 * quad(lambda a, b: (W - a) * (W - b) / W ** 4 * g(sqrt(a * a + b * b)),
                    [0, W], [0, W])


def main():
    s2, s3 = sqrt(2), sqrt(3)
    e2, e3 = mean_free_path(2), mean_free_path(3)
    print("mean free path / cell size, entry exactly on the shared side or face:")
    print("  2D", mp.nstr(e2, 40))
    print("  3D", mp.nstr(e3, 40))

    closed2 = (2 + s2 + 5 * log(1 + s2)) / 12
    closed3 = (4 + 17 * s2 - 6 * s3 - 7 * pi + 21 * log(1 + s2) + 42 * log(2 + s3)) / 90
    print("closed forms, residual against the integrals:")
    print("  2D (2 + sqrt2 + 5 ln(1+sqrt2)) / 12:", mp.nstr(closed2 - e2, 3))
    print("  3D (4 + 17 sqrt2 - 6 sqrt3 - 7 pi + 21 ln(1+sqrt2) + 42 ln(2+sqrt3)) / 90:",
          mp.nstr(closed3 - e3, 3))

    mp.dps = 55
    basis = [e3, 1, s2, s3, pi, log(1 + s2), log(2 + s3), s2 * log(1 + s2), s3 * log(2 + s3)]
    rel = pslq(basis, maxcoeff=10 ** 7, maxsteps=10 ** 7)
    print("PSLQ on [E3, 1, sqrt2, sqrt3, pi, ln(1+sqrt2), ln(2+sqrt3), sqrt2 ln(1+sqrt2), sqrt3 ln(2+sqrt3)]:")
    print("  ", rel)
    mp.dps = 30

    b = (mpf("0.95"), mpf("0.9"))
    print("with the 5% buffer (book: 0.6079 in 2D):")
    print("  2D", mp.nstr(mean_free_path(2, *b), 15))
    print("  3D", mp.nstr(mean_free_path(3, *b), 15))
    e = mpf("0.001")
    print("with the entry at x2 = 1.001, as in Listing 11.4:")
    print("  2D", mp.nstr(mean_free_path(2, eps=e), 15), "  2D buffer", mp.nstr(mean_free_path(2, *b, eps=e), 15))
    print("  3D", mp.nstr(mean_free_path(3, eps=e), 15), "  3D buffer", mp.nstr(mean_free_path(3, *b, eps=e), 15))


if __name__ == "__main__":
    main()
