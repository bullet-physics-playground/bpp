"""
linkage_synthesis.py
=====================

Formulates *planar linkage path synthesis* as a numerical optimization
problem, and searches over increasing mechanism complexity (four-bar,
six-bar, eight-bar, ...) to find the mechanism with the FEWEST links whose
coupler/tracer point follows a user-supplied trajectory x(t), y(t) to
within a given tolerance.

-----------------------------------------------------------------------
MODELING APPROACH
-----------------------------------------------------------------------
A single-degree-of-freedom planar linkage is built as a chain of RR
("revolute-revolute") dyads driven by one input crank:

    Stage 0 (four-bar core):
        O2 --r2--> A --r3--> B --r4--> O4      (O2, O4 fixed pivots)
        A is driven directly by crank angle theta = k*t + theta0
        B is found as a circle/circle intersection (loop closure)
        P0 = rigid point attached to link AB (local offset u0, v0)

    Stage i = 1..D (each stage adds ONE extra dyad = TWO extra links):
        P(i-1) --r5_i--> C_i --r6_i--> O_i     (O_i fixed pivot)
        C_i is found as a circle/circle intersection
        P_i = rigid point attached to link P(i-1)-C_i (offset u_i, v_i)

    The final P_D is the traced ("coupler") point.

    Number of links  = 4 + 2*D   (D = 0 -> four-bar, D = 1 -> six-bar, ...)

This is exactly the classical dyad-decomposition used in kinematics
(Freudenstein/Sandor-style synthesis): any single-dof pin-jointed
mechanism assembled from RR dyads on a driven crank can be represented
this way, which covers four-bars and the common Watt/Stephenson-type
six-bars, eight-bars, etc. used in path-generation problems.

-----------------------------------------------------------------------
OPTIMIZATION FORMULATION
-----------------------------------------------------------------------
Design variables (continuous):
    Ground pivot locations, link lengths, local coupler-point offsets,
    an input angular phase theta0, an integer crank-speed ratio k (see
    below), and one "branch" variable per dyad (continuous relaxation of
    the +/- circle-intersection sign, so a global optimizer can choose an
    assembly mode).

    k is snapped to the nearest nonzero integer (see snap_k()): since
    theta = k*t + theta0 drives the crank directly from the trajectory
    parameter t, a non-integer k would mean the crank does not return to
    its starting angle after one trajectory period -- the motion would not
    be truly periodic, which shows up as a visible "seam"/jump when a
    looping animation restarts. An integer k guarantees the crank
    completes exactly |k| full, continuous revolutions per trajectory
    period and the whole mechanism's motion is exactly periodic.

    In mode="shape" (fit is scored after a best-fit rotation + uniform
    scale + translation), translating the whole mechanism, rotating it, or
    uniformly scaling every length in it changes nothing about the
    achievable curve SHAPE -- 4 genuinely redundant degrees of freedom (2
    translation + 1 rotation + 1 scale). build_bounds() removes them with
    zero loss of expressiveness by fixing O2=(0,0), constraining O4 to the
    +x axis, and fixing r2=NORMALIZED_R2. In mode="exact" none of this
    reduction is valid (absolute position/orientation/size genuinely
    matter), so O2, O4, and r2 stay fully free there.

Objective:
    Sample the target curve at M parameter values t_i, sample the
    mechanism's traced point at theta_i = k*t_i + theta0, and minimize
    mean squared Euclidean error (optionally after a Procrustes shape
    alignment if the user only cares about matching shape, not exact
    position/scale/orientation).

    If the mechanism cannot be assembled at some theta_i (no real
    circle-circle intersection -> that geometry is infeasible), a large
    penalty is returned, which drives the optimizer away from
    non-assemblable/locking designs.

Search:
    We optimize (via scipy.optimize.differential_evolution, a global,
    derivative-free optimizer well suited to this multi-modal, branchy
    landscape) at D = 0, 1, 2, ... and stop at the first D whose best
    solution meets the error tolerance -- that is the minimum-link
    mechanism found.

-----------------------------------------------------------------------
LIMITATIONS (please read)
-----------------------------------------------------------------------
* This is a heuristic numerical search, not a proof of the theoretical
  minimum link count -- a smaller mechanism may exist that this search
  fails to find (global optimization is hard), and a larger D always
  has at least as much representational power as smaller D.
* The crank is assumed to be the sole input and to parametrize the
  target curve's parameter t affinely (theta = k*t + theta0). This is
  the standard "prescribed timing" path-synthesis assumption.
* Grashof/assemblability is enforced implicitly through the penalty on
  infeasible frames, not through explicit inequality constraints.
* Increase `n_samples`, `maxiter`, and `popsize` for higher-quality
  results; the defaults favor speed.
"""

from __future__ import annotations

import math
import warnings
from dataclasses import dataclass, field
from typing import Callable, List, Optional, Sequence, Tuple

import numpy as np
from scipy.optimize import differential_evolution


# =========================================================================
# Geometry primitives
# =========================================================================

def circle_circle_intersections(
    p0: np.ndarray, r0: float, p1: np.ndarray, r1: float, eps: float = 1e-9
) -> Optional[Tuple[np.ndarray, np.ndarray]]:
    """Intersect two circles. Returns (pointA, pointB) or None if no real
    intersection exists (circles too far apart, one inside the other, or
    coincident centers)."""
    x0, y0 = p0
    x1, y1 = p1
    dx, dy = x1 - x0, y1 - y0
    d = math.hypot(dx, dy)

    if d < eps:
        return None
    if d > r0 + r1 + eps:
        return None
    if d < abs(r0 - r1) - eps:
        return None

    # Clamp for numerical robustness near tangency
    d_clamped = min(max(d, abs(r0 - r1)), r0 + r1)
    a = (r0 ** 2 - r1 ** 2 + d_clamped ** 2) / (2 * d_clamped)
    h2 = r0 ** 2 - a ** 2
    h = math.sqrt(h2) if h2 > 0 else 0.0

    xm = x0 + a * dx / d
    ym = y0 + a * dy / d

    s1 = np.array([xm + h * dy / d, ym - h * dx / d])
    s2 = np.array([xm - h * dy / d, ym + h * dx / d])
    return s1, s2


def pick_branch(sol: Tuple[np.ndarray, np.ndarray], p0: np.ndarray,
                 p1: np.ndarray, sign: float) -> np.ndarray:
    """Deterministically choose one of the two circle-intersection points
    based on the sign of a continuous design variable `sign`. Using the
    sign of a cross product (rather than 'closest to previous frame') keeps
    the mapping from parameters -> geometry continuous almost everywhere,
    which is friendlier to the optimizer than a history-dependent branch."""
    s1, s2 = sol
    dx, dy = p1[0] - p0[0], p1[1] - p0[1]

    def cross(pt):
        return dx * (pt[1] - p0[1]) - dy * (pt[0] - p0[0])

    want_positive = sign >= 0
    return s1 if (cross(s1) >= 0) == want_positive else s2


def rigid_point(A: np.ndarray, B: np.ndarray, u: float, v: float) -> Optional[np.ndarray]:
    """Point rigidly attached to link AB, expressed in the local frame
    where A is the origin and B lies on the local +x axis. u,v are free
    real numbers (the point need not lie between A and B)."""
    d = B - A
    L = math.hypot(d[0], d[1])
    if L < 1e-9:
        return None
    e1 = d / L
    e2 = np.array([-e1[1], e1[0]])
    return A + u * e1 + v * e2


def loop_margin(p0: np.ndarray, r0: float, p1: np.ndarray, r1: float) -> float:
    """Signed 'room to spare' for a circle-circle loop closure: positive
    means the two circles intersect with that much clearance before
    becoming tangent (either from pulling apart or from one swallowing the
    other); negative means no real intersection exists (the loop cannot
    close -- geometrically impossible / mechanism cannot be assembled).
    Used both as a feasibility test and as a continuous measure of how
    close a configuration is to a locking/singular position."""
    d = math.hypot(p1[0] - p0[0], p1[1] - p0[1])
    return min(r0 + r1 - d, d - abs(r0 - r1))


def grashof_check(ground_len: float, r2: float, r3: float, r4: float):
    """Classical Grashof criterion applied to the four-bar core, checking
    specifically whether the CRANK (r2, the link directly driven by the
    input angle) is able to complete a full, continuous 360-degree
    rotation relative to the ground link without ever locking up.

    This requires two things:
      1. r2 is the shortest of the four link lengths (ground, r2, r3, r4)
         -- a link can only rotate fully relative to its neighbor if it is
         the shortest link adjacent to the reference (ground) link.
      2. Grashof's inequality holds: shortest + longest <= sum of the
         other two -- otherwise NONE of the links can fully rotate (a
         "triple rocker", which cannot be driven by a continuously
         rotating crank at all).

    Returns
    -------
    is_crank_rocker : bool -- True iff the crank can complete a full
        rotation, i.e. this is a physically buildable crank-driven linkage.
    grashof_margin : float -- (sum of the two middle lengths) - (shortest +
        longest); must be >= 0 for Grashof's inequality to hold. Larger is
        further from the singular "change point" boundary case.
    shortest_gap : float -- r2 minus the true shortest length; must be 0
        (r2 IS the shortest) for the crank itself to be the fully-rotating
        link.
    """
    lengths = [ground_len, r2, r3, r4]
    s, l = min(lengths), max(lengths)
    pq_sum = sum(lengths) - s - l
    grashof_margin = pq_sum - (s + l)
    shortest_gap = r2 - s
    is_crank_rocker = (shortest_gap <= 1e-9) and (grashof_margin >= 0)
    return is_crank_rocker, grashof_margin, shortest_gap


# =========================================================================
# Mechanism parameter (un)packing
# =========================================================================

BASE_NPARAMS = 12  # x2,y2,x4,y4, r2,r3,r4, u,v, theta0, k, branch0
DYAD_NPARAMS = 7   # x6,y6, r5,r6, u,v, branch


def n_params(extra_dyads: int) -> int:
    return BASE_NPARAMS + DYAD_NPARAMS * extra_dyads


def n_links(extra_dyads: int) -> int:
    return 4 + 2 * extra_dyads


@dataclass
class Mechanism:
    O2: np.ndarray
    O4: np.ndarray
    r2: float
    r3: float
    r4: float
    u0: float
    v0: float
    theta0: float
    k: float
    branch0: float
    dyads: List[dict] = field(default_factory=list)  # each: O, r5, r6, u, v, branch


def snap_k(k_raw: float) -> float:
    """Snap the crank-speed ratio k to the nearest nonzero integer.

    theta = k*t + theta0 drives the crank directly from the trajectory
    parameter t. If k is not an exact integer, sweeping t over one full
    trajectory period (t_range) does NOT bring the crank back to its
    starting angle -- the motion is not truly periodic. In an animation
    this shows up as a visible "seam": the loop cuts from the final frame
    (crank at some in-between angle) back to the first frame (crank at
    theta0), which looks like a small extra rotation, often in the
    opposite direction, right where the GIF restarts. Restricting k to
    integers guarantees exact periodicity -- the crank completes exactly
    |k| full, continuous revolutions per trajectory period and lands
    exactly back on its starting angle, so the animation loops seamlessly.
    """
    k_int = int(round(k_raw))
    if k_int == 0:
        k_int = 1 if k_raw >= 0 else -1
    return float(k_int)


def unpack(params: np.ndarray, extra_dyads: int) -> Mechanism:
    p = params
    mech = Mechanism(
        O2=np.array([p[0], p[1]]),
        O4=np.array([p[2], p[3]]),
        r2=p[4], r3=p[5], r4=p[6],
        u0=p[7], v0=p[8],
        theta0=p[9], k=snap_k(p[10]), branch0=p[11],
        dyads=[],
    )
    idx = BASE_NPARAMS
    for _ in range(extra_dyads):
        chunk = p[idx: idx + DYAD_NPARAMS]
        mech.dyads.append(dict(
            O=np.array([chunk[0], chunk[1]]),
            r5=chunk[2], r6=chunk[3],
            u=chunk[4], v=chunk[5],
            branch=chunk[6],
        ))
        idx += DYAD_NPARAMS
    return mech


# =========================================================================
# Kinematic position analysis
# =========================================================================

def solve_frame(mech: Mechanism, t: float) -> Optional[np.ndarray]:
    """Given the mechanism design and a trajectory parameter t, solve the
    loop-closure equations and return the traced point, or None if the
    mechanism cannot be assembled at this configuration."""
    theta = mech.k * t + mech.theta0
    A = mech.O2 + mech.r2 * np.array([math.cos(theta), math.sin(theta)])

    sol = circle_circle_intersections(A, mech.r3, mech.O4, mech.r4)
    if sol is None:
        return None
    B = pick_branch(sol, A, mech.O4, mech.branch0)

    P = rigid_point(A, B, mech.u0, mech.v0)
    if P is None:
        return None

    for dyad in mech.dyads:
        sol2 = circle_circle_intersections(P, dyad["r5"], dyad["O"], dyad["r6"])
        if sol2 is None:
            return None
        C = pick_branch(sol2, P, dyad["O"], dyad["branch"])
        P_next = rigid_point(P, C, dyad["u"], dyad["v"])
        if P_next is None:
            return None
        P = P_next

    return P


def solve_frame_with_margin(mech: Mechanism, t: float):
    """Like solve_frame, but also returns the minimum loop_margin seen
    across the main four-bar loop and every dyad loop at this frame. Used
    by the optimizer to both reject infeasible assemblies (margin < 0) and
    steer away from near-singular ones (margin close to 0)."""
    theta = mech.k * t + mech.theta0
    A = mech.O2 + mech.r2 * np.array([math.cos(theta), math.sin(theta)])

    margin = loop_margin(A, mech.r3, mech.O4, mech.r4)
    if margin < 0:
        return None, margin
    sol = circle_circle_intersections(A, mech.r3, mech.O4, mech.r4)
    if sol is None:
        return None, margin
    B = pick_branch(sol, A, mech.O4, mech.branch0)

    P = rigid_point(A, B, mech.u0, mech.v0)
    if P is None:
        return None, margin

    min_margin = margin
    for dyad in mech.dyads:
        m = loop_margin(P, dyad["r5"], dyad["O"], dyad["r6"])
        min_margin = min(min_margin, m)
        if m < 0:
            return None, min_margin
        sol2 = circle_circle_intersections(P, dyad["r5"], dyad["O"], dyad["r6"])
        if sol2 is None:
            return None, min_margin
        C = pick_branch(sol2, P, dyad["O"], dyad["branch"])
        P_next = rigid_point(P, C, dyad["u"], dyad["v"])
        if P_next is None:
            return None, min_margin
        P = P_next

    return P, min_margin


def trace_curve(params: np.ndarray, extra_dyads: int, t_values: np.ndarray) -> Optional[np.ndarray]:
    """Trace the full curve; returns None if ANY frame is infeasible."""
    mech = unpack(params, extra_dyads)
    pts = np.empty((len(t_values), 2))
    for i, t in enumerate(t_values):
        p = solve_frame(mech, t)
        if p is None:
            return None
        pts[i] = p
    return pts


# =========================================================================
# Curve comparison
# =========================================================================

def compute_procrustes_transform(pts: np.ndarray, target: np.ndarray):
    """Fit a similarity transform (rotation + uniform scale + translation,
    no reflection) mapping `pts` onto `target`. Returns a dict describing
    the transform so it can be re-applied consistently to OTHER point sets
    (e.g. individual mechanism joints in an animation), not just `pts`.

    Uses a direct 2D closed form rather than a general n-dimensional SVD:
    for M = P0^T @ T0 = [[Sxx, Sxy], [Syx, Syy]], the rotation angle
    maximizing trace(R^T M) over PROPER rotations only (parametrized by a
    single angle, so reflections are never representable in the first
    place) is theta = atan2(Syx - Sxy, Sxx + Syy), with optimal scale
    sqrt(A^2+B^2)/norm(P0)^2 where A = Sxx+Syy, B = Syx-Sxy. This was
    verified against a 200,000-point brute-force grid search over
    (theta, scale) -- it reproduces the exact global optimum.

    NOTE: an earlier version of this function used np.linalg.svd(M) and
    forced det(R) >= 0 by flipping a column of U when needed, but kept
    scale = S.sum() / norm(P0)^2 (the singular values from BEFORE that
    flip). That scale is only correct when no flip was needed; whenever
    the best-fit orientation actually required the reflection-correction
    (common -- it happened in 2 of 5 random test cases), the reported
    scale was wrong. The closed form here never allows reflections to
    begin with, so this issue cannot arise.
    """
    mu_p, mu_t = pts.mean(axis=0), target.mean(axis=0)
    P0, T0 = pts - mu_p, target - mu_t
    norm_p_sq = np.sum(P0 ** 2)
    if norm_p_sq < 1e-24:
        return dict(mu_p=mu_p, mu_t=mu_t, R=np.eye(2), scale=1.0)
    Sxx = np.sum(P0[:, 0] * T0[:, 0]); Sxy = np.sum(P0[:, 0] * T0[:, 1])
    Syx = np.sum(P0[:, 1] * T0[:, 0]); Syy = np.sum(P0[:, 1] * T0[:, 1])
    A = Sxx + Syy
    B = Syx - Sxy
    theta = math.atan2(B, A)
    c, s = math.cos(theta), math.sin(theta)
    R = np.array([[c, -s], [s, c]])
    scale = math.hypot(A, B) / norm_p_sq
    return dict(mu_p=mu_p, mu_t=mu_t, R=R, scale=scale)


def apply_transform(pts: np.ndarray, transform: dict) -> np.ndarray:
    """Apply a transform produced by compute_procrustes_transform to an
    arbitrary set of points (works for a single (2,) point too)."""
    pts = np.asarray(pts)
    single = pts.ndim == 1
    pts2 = np.atleast_2d(pts)
    out = transform["scale"] * ((pts2 - transform["mu_p"]) @ transform["R"]) + transform["mu_t"]
    return out[0] if single else out


def procrustes_align(pts: np.ndarray, target: np.ndarray) -> np.ndarray:
    """Best-fit similarity transform (rotation + uniform scale +
    translation, no reflection) mapping `pts` onto `target`."""
    transform = compute_procrustes_transform(pts, target)
    return apply_transform(pts, transform)


PENALTY = 1.0e6


def objective(params: np.ndarray, target_pts: np.ndarray, t_values: np.ndarray,
              extra_dyads: int, mode: str, margin_scale: float,
              min_margin_frac: float, enforce_grashof: bool) -> float:
    """margin_scale must be in the SAME units as the mechanism's own raw
    lengths (r2, r3, r4, ...), since it's only used to turn the assembly
    clearance margins (themselves raw lengths) into a fraction. In
    mode="exact" the mechanism's raw lengths ARE in the target's physical
    units, so margin_scale = the target curve's own scale. In mode="shape"
    the mechanism is solved in its own normalized frame (r2 fixed to
    NORMALIZED_R2, see build_bounds) which has nothing to do with the
    target's absolute size, so margin_scale must be NORMALIZED_R2 instead
    -- using the target's scale here would silently make the margin
    requirement arbitrarily too strict or too loose depending on how big
    the target curve happens to be."""
    mech = unpack(params, extra_dyads)

    if enforce_grashof:
        ground_len = math.hypot(mech.O2[0] - mech.O4[0], mech.O2[1] - mech.O4[1])
        is_crank_rocker, grashof_margin, shortest_gap = grashof_check(
            ground_len, mech.r2, mech.r3, mech.r4)
        if not is_crank_rocker:
            # Hard-gate: a mechanism whose crank cannot physically complete
            # a full rotation is not buildable as a crank-driven linkage.
            # Return a graded penalty (still >= PENALTY) so the optimizer
            # has a gradient-free "downhill" direction toward feasibility.
            violation = max(0.0, shortest_gap) + max(0.0, -grashof_margin)
            return PENALTY + 1.0e3 * violation / margin_scale

    pts = np.empty((len(t_values), 2))
    min_margin = math.inf
    for i, t in enumerate(t_values):
        p, m = solve_frame_with_margin(mech, t)
        min_margin = min(min_margin, m)
        if p is None:
            return PENALTY + 1.0e3 * max(0.0, -m) / margin_scale
        pts[i] = p

    if mode == "shape":
        pts = procrustes_align(pts, target_pts)
    err = float(np.mean(np.sum((pts - target_pts) ** 2, axis=1)))

    # Soft penalty for hugging a locking/singular configuration: even if
    # every sampled frame technically assembles, a design that stays close
    # to the tangency boundary is fragile (may lock between samples, or in
    # the presence of any real-world manufacturing tolerance). Push the
    # optimizer toward a healthy clearance margin.
    margin_threshold = min_margin_frac * margin_scale
    if min_margin < margin_threshold:
        deficit_frac = (margin_threshold - min_margin) / margin_scale
        err += (deficit_frac ** 2) * (margin_scale ** 2) * 2.0

    return err


# =========================================================================
# Bounds construction
# =========================================================================

NORMALIZED_R2 = 1.0  # fixed crank length used to anchor scale in mode="shape"


def build_bounds(target_pts: np.ndarray, extra_dyads: int, mode: str) -> List[Tuple[float, float]]:
    """Construct DE bounds for the parameter vector.

    In mode="shape", the fit is scored after a best-fit rotation + uniform
    scale + translation (Procrustes) is applied -- so translating the
    WHOLE mechanism, rotating it, or uniformly scaling every length in it
    changes nothing about the achievable curve SHAPE. That's 4 genuinely
    redundant degrees of freedom (2 translation + 1 rotation + 1 scale)
    out of the 12 base parameters, which the optimizer would otherwise
    waste effort re-discovering equivalent solutions across. We remove
    them with zero loss of expressiveness by fixing:
        O2 = (0, 0)             -- removes translation (2 DOF)
        O4 on the +x axis (y4=0) -- removes rotation (1 DOF): any O2->O4
                                    direction can be rotated onto the +x
                                    axis without needing a reflection
        r2 = NORMALIZED_R2       -- removes scale (1 DOF): all other
                                    lengths are then expressed relative to
                                    the crank length
    Every other free parameter keeps its full range relative to this
    fixed, normalized frame.

    In mode="exact" the mechanism's absolute position, orientation, and
    size all genuinely matter (no transform is applied before scoring),
    so none of this reduction is valid there -- O2, O4, and r2 stay fully
    free, with bounds sized from the target curve's own absolute scale.
    """
    if mode == "shape":
        R = NORMALIZED_R2
        fixed0 = (0.0, 0.0)
        pos_b = (-8.0 * R, 8.0 * R)
        len_small = (R, R)                 # r2 fixed
        len_big = (0.03 * R, 8.0 * R)
        off_b = (-8.0 * R, 8.0 * R)

        bounds = [
            fixed0, fixed0,          # O2 = (0, 0)
            (0.03 * R, 8.0 * R), fixed0,   # O4 = (x4 > 0, 0)  -- on the +x axis
            len_small,               # r2 fixed = R
            len_big,                 # r3
            len_big,                 # r4
            off_b, off_b,            # u0, v0
            (0.0, 2 * math.pi),      # theta0
            (-4.0, 4.0),             # k
            (-1.0, 1.0),             # branch0
        ]
        for _ in range(extra_dyads):
            bounds += [
                pos_b, pos_b,         # O_i (still fully free -- only the
                                      # GLOBAL frame's symmetry was removed,
                                      # not each dyad's own placement)
                len_big, len_big,    # r5, r6
                off_b, off_b,        # u, v
                (-1.0, 1.0),          # branch
            ]
        return bounds

    # mode == "exact": absolute position/orientation/scale genuinely
    # matter, so nothing can be fixed away -- bounds sized from the
    # target curve's own absolute scale, as before.
    center = target_pts.mean(axis=0)
    span = target_pts.max(axis=0) - target_pts.min(axis=0)
    S = max(float(np.linalg.norm(span)), 1e-6)

    cx, cy = center
    pos_b = (cx - 2 * S, cx + 2 * S)
    pos_b_y = (cy - 2 * S, cy + 2 * S)
    len_small = (0.03 * S, 1.5 * S)
    len_big = (0.03 * S, 2.5 * S)
    off_b = (-2.5 * S, 2.5 * S)

    bounds = [
        pos_b, pos_b_y,          # O2
        pos_b, pos_b_y,          # O4
        len_small,               # r2
        len_big,                 # r3
        len_big,                 # r4
        off_b, off_b,            # u0, v0
        (0.0, 2 * math.pi),      # theta0
        (-4.0, 4.0),             # k
        (-1.0, 1.0),             # branch0
    ]
    for _ in range(extra_dyads):
        bounds += [
            pos_b, pos_b_y,       # O_i
            len_big, len_big,     # r5, r6
            off_b, off_b,         # u, v
            (-1.0, 1.0),          # branch
        ]
    return bounds


def mechanism_diagnostics(params: np.ndarray, extra_dyads: int, t_range: Tuple[float, float],
                           margin_scale: float, n_verify: int = 360) -> dict:
    """Independent, fine-grained verification that a candidate mechanism is
    actually constructible: re-checks the Grashof crank-rocker condition
    analytically, and re-samples the full rotation at much higher
    resolution than is typically used during optimization to confirm every
    dyad loop stays assemblable (and with reasonable clearance) everywhere,
    not just at the coarse sample points the optimizer saw.

    margin_scale must be in the mechanism's own raw length units -- pass
    NORMALIZED_R2 for mode="shape" results, or the target's own scale for
    mode="exact" results (see objective()'s docstring for why)."""
    mech = unpack(params, extra_dyads)
    ground_len = math.hypot(mech.O2[0] - mech.O4[0], mech.O2[1] - mech.O4[1])
    is_crank_rocker, grashof_margin, shortest_gap = grashof_check(
        ground_len, mech.r2, mech.r3, mech.r4)

    t_verify = np.linspace(t_range[0], t_range[1], n_verify, endpoint=False)
    min_margin = math.inf
    fully_assembles = True
    for t in t_verify:
        p, m = solve_frame_with_margin(mech, t)
        min_margin = min(min_margin, m)
        if p is None:
            fully_assembles = False
            break

    return dict(
        is_grashof=is_crank_rocker,
        grashof_margin=grashof_margin,
        shortest_gap=shortest_gap,
        ground_len=ground_len,
        fully_assembles=fully_assembles,
        min_assembly_margin=min_margin,
        min_assembly_margin_frac=(min_margin / margin_scale if math.isfinite(min_margin) else float("-inf")),
    )


# =========================================================================
# Search driver
# =========================================================================

@dataclass
class SynthesisResult:
    extra_dyads: int
    links: int
    params: np.ndarray
    rms_error: float          # sqrt(mean squared error), same units as trajectory
    rel_error: float          # rms_error / trajectory scale
    meets_tolerance: bool
    mode: str
    is_grashof: bool = True
    fully_assembles: bool = True
    min_assembly_margin_frac: float = float("nan")
    constructible: bool = True


def search_minimum_link_mechanism(
    traj_func: Callable[[float], Tuple[float, float]],
    t_range: Tuple[float, float] = (0.0, 2 * math.pi),
    n_samples: int = 50,
    max_extra_dyads: int = 2,
    tol: float = 0.02,
    mode: str = "exact",
    popsize: int = 20,
    maxiter: int = 150,
    seed: Optional[int] = 0,
    workers: int = 1,
    verbose: bool = True,
    enforce_grashof: bool = True,
    min_assembly_margin_frac: float = 0.05,
    verify_n: int = 360,
) -> SynthesisResult:
    """Search over D = 0, 1, ..., max_extra_dyads extra dyads (i.e. 4, 6,
    8, ... bar mechanisms) for the smallest mechanism whose traced point
    matches `traj_func` to within relative RMS error `tol`.

    Parameters
    ----------
    traj_func : callable t -> (x, y)
        The target trajectory, as an arbitrary equation of one parameter.
    mode : "exact" or "shape"
        "exact"  -- match position, scale and orientation as given.
        "shape"  -- match curve shape only (best-fit similarity transform).
    tol : float
        Stop as soon as rel_error = rms_error / trajectory_scale < tol.
    enforce_grashof : bool
        If True (default), only accept mechanisms whose crank can complete
        a full, continuous 360-degree rotation without locking (the
        classical Grashof condition) -- i.e. only physically buildable,
        continuously-drivable mechanisms. Turning this off allows
        "rocker-rocker" solutions that may fit the curve better but cannot
        be driven by a simple continuously-rotating motor/crank.
    min_assembly_margin_frac : float
        Minimum required clearance (as a fraction of the trajectory's
        size) between every loop-closure circle pair and tangency, at
        every sampled configuration. Values very close to 0 assemble but
        sit right at a locking/singular configuration -- fragile in
        practice. Raise this for more robust, "loose" mechanisms; lower it
        (e.g. 0.0) if you need the search to accept tighter designs.
    verify_n : int
        Number of frames used in the fine-grained post-optimization
        constructibility check (independent of, and denser than,
        n_samples). A candidate is only accepted as meeting tolerance if
        it also passes this check.

    Returns
    -------
    SynthesisResult with the best mechanism found (of minimal link count
    that met tolerance AND passed constructibility verification, or
    otherwise the best of all sizes tried).
    """
    t_values = np.linspace(t_range[0], t_range[1], n_samples, endpoint=False)
    target_pts = np.array([traj_func(t) for t in t_values])
    scale = max(float(np.linalg.norm(target_pts.max(axis=0) - target_pts.min(axis=0))), 1e-6)

    # margin_scale must be in the mechanism's OWN raw length units (see
    # objective()'s docstring). In mode="shape" those units are the
    # normalized frame fixed by build_bounds (r2 = NORMALIZED_R2), which
    # has nothing to do with the target curve's absolute size -- using
    # `scale` there would make the margin requirement arbitrarily too
    # strict or too loose depending on the target's absolute size. In
    # mode="exact" the mechanism's raw units ARE the target's physical
    # units, so `scale` is the correct reference.
    margin_scale = NORMALIZED_R2 if mode == "shape" else scale

    best: Optional[SynthesisResult] = None

    for D in range(0, max_extra_dyads + 1):
        bounds = build_bounds(target_pts, D, mode)
        res = differential_evolution(
            objective, bounds,
            args=(target_pts, t_values, D, mode, margin_scale, min_assembly_margin_frac, enforce_grashof),
            maxiter=maxiter, popsize=popsize, tol=1e-10,
            mutation=(0.4, 1.5), recombination=0.8,
            seed=seed, polish=True, workers=workers, updating="deferred",
        )
        rms_err = math.sqrt(max(min(res.fun, PENALTY), 0.0))
        rel_err = rms_err / scale

        diag = mechanism_diagnostics(res.x, D, t_range, margin_scale, n_verify=verify_n)
        constructible = diag["fully_assembles"] and (diag["is_grashof"] or not enforce_grashof)
        meets = (rel_err < tol) and constructible

        if verbose:
            links = n_links(D)
            status = "MEETS TOLERANCE" if meets else "above tolerance"
            build_note = "constructible" if constructible else "NOT constructible (fails verification)"
            print(f"[D={D}, links={links}] best rms error = {rms_err:.5g} "
                  f"(relative = {rel_err:.4%}) -> {status}; {build_note}"
                  f" [Grashof crank-rocker: {diag['is_grashof']}, "
                  f"min margin = {diag['min_assembly_margin_frac']:.2%}]")

        candidate = SynthesisResult(
            extra_dyads=D, links=n_links(D), params=res.x,
            rms_error=rms_err, rel_error=rel_err,
            meets_tolerance=meets, mode=mode,
            is_grashof=diag["is_grashof"], fully_assembles=diag["fully_assembles"],
            min_assembly_margin_frac=diag["min_assembly_margin_frac"],
            constructible=constructible,
        )
        if best is None or (candidate.constructible and not best.constructible) or (
            candidate.constructible == best.constructible and candidate.rms_error < best.rms_error
        ):
            best = candidate
        if meets:
            return candidate

    warnings.warn(
        f"No mechanism up to {max_extra_dyads} extra dyads met tolerance "
        f"{tol:.3%} with a verified-constructible design; returning the "
        f"best mechanism found (relative error {best.rel_error:.3%}, "
        f"constructible={best.constructible})."
    )
    return best


# =========================================================================
# Reporting / visualization
# =========================================================================

DYAD_COLOR_PALETTE = ["c", "y", "tab:brown", "tab:pink", "tab:olive", "tab:red", "tab:purple"]
ARM_COLOR = "darkorange"


def link_color_plan(extra_dyads: int) -> List[Tuple[str, str]]:
    """Single source of truth for which color draws which link, used by
    plot_result(), animate_mechanism(), and the terminal legend so they can
    never drift out of sync with each other. Returns an ordered list of
    (label, color) pairs for the primary (solid) links."""
    plan = [
        ("crank  O2\u2013A", "b"),
        ("coupler  A\u2013B", "g"),
        ("rocker  B\u2013O4", "m"),
    ]
    for j in range(extra_dyads):
        c1 = DYAD_COLOR_PALETTE[(2 * j) % len(DYAD_COLOR_PALETTE)]
        c2 = DYAD_COLOR_PALETTE[(2 * j + 1) % len(DYAD_COLOR_PALETTE)]
        # NOTE: dyad ground pivots are named "Og{j+1}", NOT "O{j+1}" --
        # "O2"/"O4" are already taken by the four-bar core's ground pivots,
        # and for a second (or later) dyad "O2" would otherwise collide.
        plan.append((f"dyad {j + 1} link 5  P{j}\u2013C{j + 1}", c1))
        plan.append((f"dyad {j + 1} link 6  C{j + 1}\u2013Og{j + 1}", c2))
    return plan


def point_and_link_names(extra_dyads: int) -> dict:
    """Single source of truth for the short on-plot labels used by
    animate_mechanism() (and reusable elsewhere): names for every pivot
    (ground and moving) and a short name for every primary link, in the
    same order as _mechanism_joint_chain's output and link_color_plan."""
    ground_names = ["O2", "O4"] + [f"Og{j + 1}" for j in range(extra_dyads)]
    # moving pivots, in the order they become available while solving:
    # A, B, P0 (coupler point), then per dyad: C_j, P_j (its output point)
    moving_names = ["A", "B", "P0"]
    for j in range(extra_dyads):
        moving_names += [f"C{j + 1}", f"P{j + 1}"]
    # short labels for the primary (solid) links, matching link_color_plan
    link_names = ["crank", "coupler", "rocker"]
    for j in range(extra_dyads):
        link_names += [f"d{j + 1}L5", f"d{j + 1}L6"]
    return dict(ground=ground_names, moving=moving_names, links=link_names)


def print_link_color_legend(result: SynthesisResult) -> str:
    """Terminal-friendly legend mapping each link to the color it's drawn
    in, in linkage_result.png and linkage_animation.gif."""
    plan = link_color_plan(result.extra_dyads)
    width = max(len(label) for label, _ in plan)
    lines = ["Link color legend (matches linkage_result.png / linkage_animation.gif):"]
    for label, color in plan:
        lines.append(f"    {label.ljust(width)}  ->  {color}")
    lines.append(f"    {'rigid coupler/tracer arm(s)'.ljust(width)}  ->  {ARM_COLOR} (dashed; "
                  f"structural, connects an offset point to its parent link -- not itself a "
                  f"moving pin-jointed link)")
    lines.append(f"    {'ground pivots (fixed)'.ljust(width)}  ->  black squares")
    lines.append(f"    {'traced point + its path'.ljust(width)}  ->  red")
    return "\n".join(lines)


def _fit_display_transform(result: SynthesisResult, traj_func: Callable[[float], Tuple[float, float]],
                            t_range: Tuple[float, float] = (0.0, 2 * math.pi), n_dense: int = 400):
    """Fit the same similarity transform (rotation + uniform scale +
    translation) that plot_result() and animate_mechanism() use to align
    the traced curve with the target when mode == 'shape'. Returns None
    for mode == 'exact' (no transform applied) or if the mechanism fails
    to assemble densely."""
    if result.mode != "shape":
        return None
    t_dense = np.linspace(t_range[0], t_range[1], n_dense, endpoint=False)
    target_pts = np.array([traj_func(t) for t in t_dense])
    traced_dense = trace_curve(result.params, result.extra_dyads, t_dense)
    if traced_dense is None:
        return None
    return compute_procrustes_transform(traced_dense, target_pts)


def describe_display_geometry(result: SynthesisResult, traj_func: Callable[[float], Tuple[float, float]],
                               t_range: Tuple[float, float] = (0.0, 2 * math.pi)) -> str:
    """Report mechanism geometry in the SAME coordinates/scale that
    plot_result() and animate_mechanism() actually draw.

    describe() always prints the mechanism's native design parameters --
    the raw numbers the optimizer searched over. When mode == 'shape',
    those are NOT what appears in linkage_result.png / linkage_animation
    .gif: the plots additionally apply a best-fit rotation + uniform scale
    + translation to line the traced curve up with your target trajectory,
    so every drawn coordinate (ground pivots, etc.) AND every drawn link
    length is transformed. This function applies that same transform and
    reports what you'll actually see on screen, so the two never look like
    they disagree."""
    mech = unpack(result.params, result.extra_dyads)
    transform = _fit_display_transform(result, traj_func, t_range)

    if transform is None:
        note = (
            "mode='exact': no alignment transform is applied for display -- "
            "the coordinates below match describe() exactly."
            if result.mode == "exact" else
            "Could not fit a display transform (mechanism failed to assemble "
            "densely); showing native coordinates."
        )
        O2_d, O4_d, scale = mech.O2, mech.O4, 1.0
    else:
        O2_d = apply_transform(mech.O2, transform)
        O4_d = apply_transform(mech.O4, transform)
        scale = transform["scale"]
        note = (
            "mode='shape': plot_result()/animate_mechanism() apply a best-fit rotation + "
            f"uniform scale (x{scale:.4f}) + translation to align the traced curve with your "
            "target trajectory. The coordinates AND lengths below are what's actually drawn -- "
            "they will differ from describe()'s native design parameters by exactly this "
            "transform, which is expected, not a bug."
        )

    lines = [note, ""]
    lines.append(f"  Displayed ground pivot O2 = ({O2_d[0]:.4f}, {O2_d[1]:.4f})")
    lines.append(f"  Displayed ground pivot O4 = ({O4_d[0]:.4f}, {O4_d[1]:.4f})")
    lines.append(f"  Displayed crank length r2   = {mech.r2 * scale:.4f}")
    lines.append(f"  Displayed coupler length r3 = {mech.r3 * scale:.4f}")
    lines.append(f"  Displayed rocker length r4  = {mech.r4 * scale:.4f}")
    for i, dy in enumerate(mech.dyads, start=1):
        O_d = apply_transform(dy["O"], transform) if transform is not None else dy["O"]
        lines.append(
            f"  Dyad {i}: displayed ground O = ({O_d[0]:.4f}, {O_d[1]:.4f}), "
            f"displayed r5 = {dy['r5'] * scale:.4f}, displayed r6 = {dy['r6'] * scale:.4f}"
        )
    return "\n".join(lines)


def describe(result: SynthesisResult) -> str:
    mech = unpack(result.params, result.extra_dyads)
    lines = [
        f"Mechanism: {result.links}-bar linkage "
        f"(four-bar core + {result.extra_dyads} extra dyad(s))",
        f"  Ground pivot O2 = ({mech.O2[0]:.4f}, {mech.O2[1]:.4f}),  crank r2 = {mech.r2:.4f}",
        f"  Ground pivot O4 = ({mech.O4[0]:.4f}, {mech.O4[1]:.4f}),  rocker r4 = {mech.r4:.4f}",
        f"  Coupler r3 = {mech.r3:.4f},  coupler-point offset (u0,v0) = ({mech.u0:.4f}, {mech.v0:.4f})",
        f"  Input timing: theta = {mech.k:+.0f} * t + {mech.theta0:.4f}  "
        f"({abs(mech.k):.0f} full crank revolution(s) per trajectory period, "
        f"{'clockwise' if mech.k < 0 else 'counter-clockwise'})",
    ]
    for i, dy in enumerate(mech.dyads, start=1):
        lines.append(
            f"  Dyad {i}: ground O = ({dy['O'][0]:.4f}, {dy['O'][1]:.4f}), "
            f"r5 = {dy['r5']:.4f}, r6 = {dy['r6']:.4f}, "
            f"point offset (u,v) = ({dy['u']:.4f}, {dy['v']:.4f})"
        )
    lines.append(f"RMS error = {result.rms_error:.5g}  (relative {result.rel_error:.4%})")
    if result.mode == "shape":
        lines.append(
            "NOTE: mode='shape' -- the coordinates and lengths above are the mechanism's native "
            "design parameters, NOT what's drawn in the plot/animation (which additionally apply "
            "a best-fit rotation/scale/translation to align with your target curve). Call "
            "describe_display_geometry(result, traj_func) for the as-displayed coordinates."
        )
    lines.append("")
    lines.append("Constructibility:")
    lines.append(
        f"  Grashof crank-rocker (crank can complete a full 360 deg rotation): "
        f"{'YES' if result.is_grashof else 'NO'}"
    )
    lines.append(
        f"  Fully assembles across a full rotation (fine-grained check): "
        f"{'YES' if result.fully_assembles else 'NO'}"
    )
    if math.isfinite(result.min_assembly_margin_frac):
        lines.append(
            f"  Minimum assembly clearance margin: {result.min_assembly_margin_frac:.2%} "
            f"of trajectory scale (larger = more robust, further from locking)"
        )
    lines.append(f"  Overall constructible: {'YES' if result.constructible else 'NO'}")
    if not result.constructible:
        lines.append(
            "  WARNING: this mechanism did NOT pass the constructibility check -- it may "
            "lock or fail to assemble somewhere in the rotation. Consider raising "
            "max_extra_dyads, popsize, or maxiter, or relaxing tol."
        )
    return "\n".join(lines)


def plot_result(result: SynthesisResult, traj_func: Callable[[float], Tuple[float, float]],
                 t_range: Tuple[float, float] = (0.0, 2 * math.pi),
                 n_samples: int = 300, save_path: Optional[str] = None,
                 n_poses: int = 8):
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    t_values = np.linspace(t_range[0], t_range[1], n_samples, endpoint=False)
    target_pts = np.array([traj_func(t) for t in t_values])
    traced = trace_curve(result.params, result.extra_dyads, t_values)

    if result.mode == "shape" and traced is not None:
        traced_plot = procrustes_align(traced, target_pts)
    else:
        traced_plot = traced

    mech = unpack(result.params, result.extra_dyads)

    fig, axes = plt.subplots(1, 2, figsize=(12, 6))

    ax = axes[0]
    ax.plot(target_pts[:, 0], target_pts[:, 1], "k--", lw=2, label="target trajectory")
    if traced_plot is not None:
        ax.plot(traced_plot[:, 0], traced_plot[:, 1], "r-", lw=1.5, label="mechanism trace")
    ax.set_aspect("equal", adjustable="datalim")
    ax.legend()
    ax.set_title(f"Path match ({result.links}-bar, rel. err {result.rel_error:.2%})")

    ax = axes[1]
    ax.plot(target_pts[:, 0], target_pts[:, 1], "k--", lw=1, alpha=0.4)
    pose_t = np.linspace(t_range[0], t_range[1], n_poses, endpoint=False)
    color_plan = link_color_plan(result.extra_dyads)
    primary_colors = [c for _, c in color_plan]
    for t in pose_t:
        solved = _mechanism_joint_chain(mech, t)
        if solved is None:
            continue
        chain, P0, dyad_info, P_final = solved
        O2, A, B, O4 = chain
        ax.plot([O2[0], A[0]], [O2[1], A[1]], "-", color=primary_colors[0], lw=1)
        ax.plot([A[0], B[0]], [A[1], B[1]], "-", color=primary_colors[1], lw=1)
        ax.plot([B[0], O4[0]], [B[1], O4[1]], "-", color=primary_colors[2], lw=1)
        # rigid coupler arms connecting the offset coupler point P0 to its
        # parent link -- without these, P0 (and dyad output points) would
        # appear to float disconnected from the rest of the mechanism.
        ax.plot([A[0], P0[0]], [A[1], P0[1]], "--", color=ARM_COLOR, lw=0.8, alpha=0.8)
        ax.plot([B[0], P0[0]], [B[1], P0[1]], "--", color=ARM_COLOR, lw=0.8, alpha=0.8)
        for j, dy in enumerate(dyad_info):
            c1 = primary_colors[3 + 2 * j]
            c2 = primary_colors[3 + 2 * j + 1]
            ax.plot([dy["prevP"][0], dy["C"][0]], [dy["prevP"][1], dy["C"][1]], "-", color=c1, lw=1)
            ax.plot([dy["C"][0], dy["O"][0]], [dy["C"][1], dy["O"][1]], "-", color=c2, lw=1)
            ax.plot([dy["prevP"][0], dy["P_out"][0]], [dy["prevP"][1], dy["P_out"][1]],
                    "--", color="darkorange", lw=0.8, alpha=0.8)
            ax.plot([dy["C"][0], dy["P_out"][0]], [dy["C"][1], dy["P_out"][1]],
                    "--", color="darkorange", lw=0.8, alpha=0.8)
        ax.plot(P_final[0], P_final[1], "r.", ms=6)
    ax.plot(mech.O2[0], mech.O2[1], "ks", ms=8)
    ax.plot(mech.O4[0], mech.O4[1], "ks", ms=8)
    for dy in mech.dyads:
        ax.plot(dy["O"][0], dy["O"][1], "ks", ms=8)
    ax.set_aspect("equal", adjustable="datalim")
    ax.set_title("Mechanism poses through one cycle")

    fig.tight_layout()
    if save_path:
        fig.savefig(save_path, dpi=150)
        print(f"Saved figure to {save_path}")
    return fig


def _mechanism_joint_chain(mech: Mechanism, t: float):
    """Return the full solved geometry needed to DRAW the mechanism at
    parameter t:
        chain      -- [O2, A, B, O4]
        P0         -- the coupler point rigidly attached to link A-B
                       (this is the traced point itself when there are no
                       extra dyads)
        dyad_info  -- list of dicts, one per extra dyad, each with keys
                       'prevP' (the point driving this dyad -- P0 for the
                       first dyad, the previous dyad's P_out otherwise),
                       'C' (the dyad's solved joint), 'O' (its ground
                       pivot), and 'P_out' (the point rigidly attached to
                       link prevP-C -- this dyad's output point)
        P_final    -- the overall traced point (== P0 if no dyads, else
                       the last dyad's P_out)
    Returns None if the mechanism can't be assembled at this t.

    Note this exposes P0 / P_out explicitly (not just the joints A,B,C)
    because these offset points are NOT generally on the line between
    their two parent joints -- they are rigidly attached via a triangular
    extension, and that extension must be drawn or the point appears to
    float disconnected from the rest of the linkage.
    """
    theta = mech.k * t + mech.theta0
    A = mech.O2 + mech.r2 * np.array([math.cos(theta), math.sin(theta)])
    sol = circle_circle_intersections(A, mech.r3, mech.O4, mech.r4)
    if sol is None:
        return None
    B = pick_branch(sol, A, mech.O4, mech.branch0)
    P0 = rigid_point(A, B, mech.u0, mech.v0)
    if P0 is None:
        return None

    chain = [mech.O2, A, B, mech.O4]
    dyad_info = []
    prev = P0
    for dy in mech.dyads:
        sol2 = circle_circle_intersections(prev, dy["r5"], dy["O"], dy["r6"])
        if sol2 is None:
            return None
        C = pick_branch(sol2, prev, dy["O"], dy["branch"])
        P_next = rigid_point(prev, C, dy["u"], dy["v"])
        if P_next is None:
            return None
        dyad_info.append(dict(prevP=prev, C=C, O=dy["O"], P_out=P_next))
        prev = P_next
    return chain, P0, dyad_info, prev


def _mechanism_bbox_over_time(mech: Mechanism, t_values: np.ndarray, transform: Optional[dict] = None):
    """Bounding box (xmin, xmax, ymin, ymax) of every joint AND every rigid
    attachment point in the mechanism (ground pivots, crank pin, coupler
    joints and coupler point, all dyad joints and dyad output points)
    across every frame in t_values -- NOT just the traced point's path.
    Returns None if the mechanism never assembles across all of t_values."""
    xs: List[np.ndarray] = []
    ys: List[np.ndarray] = []
    for t in t_values:
        solved = _mechanism_joint_chain(mech, t)
        if solved is None:
            continue
        chain, P0, dyad_info, P_final = solved
        pts = list(chain) + [P0]
        for dy in dyad_info:
            pts += [dy["C"], dy["O"], dy["P_out"]]
        pts_arr = np.array(pts)
        if transform is not None:
            pts_arr = apply_transform(pts_arr, transform)
        xs.append(pts_arr[:, 0])
        ys.append(pts_arr[:, 1])
    if not xs:
        return None
    xs = np.concatenate(xs)
    ys = np.concatenate(ys)
    return float(xs.min()), float(xs.max()), float(ys.min()), float(ys.max())


def animate_mechanism(
    result: SynthesisResult,
    traj_func: Callable[[float], Tuple[float, float]],
    t_range: Tuple[float, float] = (0.0, 2 * math.pi),
    n_frames: int = 72,
    fps: int = 20,
    trail: bool = True,
    save_path: str = "linkage_animation.gif",
):
    """Render an animated GIF of the linkage moving through one full crank
    rotation (t_range), with the target trajectory drawn for reference and
    the traced point's path building up ("trail") as it goes."""
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    from matplotlib.animation import FuncAnimation, PillowWriter

    mech = unpack(result.params, result.extra_dyads)

    # Dense reference curves
    t_dense = np.linspace(t_range[0], t_range[1], 400, endpoint=False)
    target_pts = np.array([traj_func(t) for t in t_dense])
    traced_dense = trace_curve(result.params, result.extra_dyads, t_dense)

    # If we're in "shape" mode, fit ONE alignment transform (from the full
    # traced curve to the target) and reuse it for every joint, every frame,
    # so the animation doesn't jitter/re-fit per frame.
    if result.mode == "shape" and traced_dense is not None:
        transform = compute_procrustes_transform(traced_dense, target_pts)
    else:
        transform = None

    def tr(pts):
        return apply_transform(pts, transform) if transform is not None else pts

    t_frames = np.linspace(t_range[0], t_range[1], n_frames, endpoint=False)

    fig, ax = plt.subplots(figsize=(7, 7))
    ax.plot(target_pts[:, 0], target_pts[:, 1], "k--", lw=1.5, alpha=0.6, label="target trajectory")

    # ground pivots (static, drawn once)
    ground_points = [mech.O2, mech.O4] + [dy["O"] for dy in mech.dyads]
    ground_arr = tr(np.array(ground_points))
    ax.plot(ground_arr[:, 0], ground_arr[:, 1], "ks", ms=8, zorder=5)

    names = point_and_link_names(len(mech.dyads))
    for name, (gx, gy) in zip(names["ground"], ground_arr):
        ax.annotate(name, xy=(gx, gy), xytext=(6, 6), textcoords="offset points",
                    fontsize=8, fontweight="bold", color="black", zorder=7,
                    bbox=dict(boxstyle="round,pad=0.12", fc="white", ec="none", alpha=0.75))

    link_lines = []
    n_primary = 3 + 2 * len(mech.dyads)  # O2-A, A-B, B-O4, then (prevP-C, C-O) per dyad
    primary_colors = [c for _, c in link_color_plan(len(mech.dyads))]
    for i in range(n_primary):
        ln, = ax.plot([], [], "-", lw=2.2, color=primary_colors[i], zorder=3)
        link_lines.append(ln)

    # "Arm" lines: the rigid triangular attachment from each stage's two
    # parent joints out to its offset point (coupler point P0, or a dyad's
    # output point). Without drawing these, offset points appear to float
    # disconnected from the rest of the mechanism.
    n_arms = 2 * (1 + len(mech.dyads))  # (A-P0, B-P0), then (prevP-P_out, C-P_out) per dyad
    arm_lines = []
    for i in range(n_arms):
        ln, = ax.plot([], [], "--", lw=1.2, color="darkorange", alpha=0.85, zorder=2)
        arm_lines.append(ln)
    # dummy handle for the legend (the individual arm_lines above are unlabeled)
    ax.plot([], [], "--", lw=1.2, color="darkorange", alpha=0.85, label="rigid coupler/tracer arm")

    joint_dots, = ax.plot([], [], "o", ms=4, color="black", zorder=4)  # intermediate P_i (if any)
    trace_line, = ax.plot([], [], "r-", lw=1.5, label="traced point path")
    tracer_dot, = ax.plot([], [], "ro", ms=7, zorder=6, label="traced point")

    # Moving pivot labels (A, B, P0, and each dyad's C_j/P_j) -- created
    # once with a placeholder position, moved every frame in update().
    pivot_label_artists = [
        ax.annotate(name, xy=(0, 0), xytext=(6, 6), textcoords="offset points",
                    fontsize=7.5, color="black", zorder=7,
                    bbox=dict(boxstyle="round,pad=0.1", fc="white", ec="none", alpha=0.7))
        for name in names["moving"]
    ]
    # Link labels (crank, coupler, rocker, d1L5, d1L6, ...), placed at each
    # primary link's midpoint every frame.
    link_label_artists = [
        ax.annotate(name, xy=(0, 0), xytext=(0, 5), textcoords="offset points",
                    fontsize=7.5, style="italic", color="dimgray", ha="center", zorder=7,
                    bbox=dict(boxstyle="round,pad=0.1", fc="white", ec="none", alpha=0.6))
        for name in names["links"]
    ]

    all_ref = np.vstack([target_pts, traced_dense if traced_dense is not None else target_pts])
    xmin, xmax = all_ref[:, 0].min(), all_ref[:, 0].max()
    ymin, ymax = all_ref[:, 1].min(), all_ref[:, 1].max()

    # Critical: the physical linkage (ground pivots, crank, coupler, dyad
    # links) can extend well outside the traced curve's own bounding box.
    # Scan every frame's joint positions and grow the view to include them
    # all, or links will be clipped out of the animation.
    mech_bbox = _mechanism_bbox_over_time(mech, t_frames, transform)
    if mech_bbox is not None:
        mxmin, mxmax, mymin, mymax = mech_bbox
        xmin, xmax = min(xmin, mxmin), max(xmax, mxmax)
        ymin, ymax = min(ymin, mymin), max(ymax, mymax)
    else:
        warnings.warn(
            "animate_mechanism: the mechanism failed to assemble at every "
            "sampled frame; the animation may show a frozen/incomplete "
            "linkage for those frames. Consider re-running the search with "
            "enforce_grashof=True and a larger min_assembly_margin_frac."
        )

    pad = 0.08 * max(xmax - xmin, ymax - ymin, 1e-6)
    ax.set_xlim(xmin - pad, xmax + pad)
    ax.set_ylim(ymin - pad, ymax + pad)
    ax.set_aspect("equal", adjustable="box")
    ax.legend(loc="upper right", fontsize=8)
    title = ax.set_title(f"{result.links}-bar linkage")

    trail_xs: List[float] = []
    trail_ys: List[float] = []

    def update(frame_idx):
        t = t_frames[frame_idx]
        solved = _mechanism_joint_chain(mech, t)
        if solved is None:
            return (link_lines + arm_lines + [joint_dots, trace_line, tracer_dot, title]
                    + pivot_label_artists + link_label_artists)
        chain, P0, dyad_info, P_final = solved
        chain_t = tr(np.array(chain))
        P0_t = tr(P0)

        segs = [(chain_t[0], chain_t[1]), (chain_t[1], chain_t[2]), (chain_t[2], chain_t[3])]
        arm_segs = [(chain_t[1], P0_t), (chain_t[2], P0_t)]  # A-P0, B-P0
        intermediate_xy = []
        moving_pts = [chain_t[1], chain_t[2], P0_t]  # A, B, P0
        for dy in dyad_info:
            prevP_t, C_t, O_t, Pout_t = tr(dy["prevP"]), tr(dy["C"]), tr(dy["O"]), tr(dy["P_out"])
            segs.append((prevP_t, C_t))
            segs.append((C_t, O_t))
            arm_segs.append((prevP_t, Pout_t))
            arm_segs.append((C_t, Pout_t))
            intermediate_xy.append(Pout_t)
            moving_pts += [C_t, Pout_t]

        for ln, (p0, p1) in zip(link_lines, segs):
            ln.set_data([p0[0], p1[0]], [p0[1], p1[1]])
        for ln, (p0, p1) in zip(arm_lines, arm_segs):
            ln.set_data([p0[0], p1[0]], [p0[1], p1[1]])

        # move the pivot labels (A, B, P0, C_j, P_j) to their new positions
        for ann, (px, py) in zip(pivot_label_artists, moving_pts):
            ann.xy = (px, py)
        # move the link labels to each primary link's current midpoint
        for ann, (p0, p1) in zip(link_label_artists, segs):
            ann.xy = ((p0[0] + p1[0]) / 2.0, (p0[1] + p1[1]) / 2.0)

        # mark every intermediate rigid-body point (P0, and each dyad's
        # P_out except the very last, which IS the tracer point drawn
        # separately below as the big red dot)
        mid_pts = ([P0_t] + intermediate_xy[:-1]) if dyad_info else []
        if mid_pts:
            mid_arr = np.array(mid_pts)
            joint_dots.set_data(mid_arr[:, 0], mid_arr[:, 1])
        else:
            joint_dots.set_data([], [])

        P_t = tr(P_final)
        if trail:
            trail_xs.append(P_t[0])
            trail_ys.append(P_t[1])
            trace_line.set_data(trail_xs, trail_ys)
        tracer_dot.set_data([P_t[0]], [P_t[1]])
        title.set_text(f"{result.links}-bar linkage  (t index {frame_idx + 1}/{n_frames})")
        return (link_lines + arm_lines + [joint_dots, trace_line, tracer_dot, title]
                + pivot_label_artists + link_label_artists)

    anim = FuncAnimation(fig, update, frames=n_frames, blit=False, interval=1000 / fps)
    anim.save(save_path, writer=PillowWriter(fps=fps))
    plt.close(fig)
    print(f"Saved animation to {save_path}")
    return save_path


# =========================================================================
# Demo
# =========================================================================

if __name__ == "__main__":
    # -------------------------------------------------------------------
    # >>> EDIT YOUR TARGET TRAJECTORY HERE <<<
    # This is the only thing you normally need to change: any function of
    # one parameter t that returns an (x, y) tuple. t is swept over
    # `t_range` below (default one full period, 0 to 2*pi).
    # -------------------------------------------------------------------
    def target_trajectory(t: float) -> Tuple[float, float]:
        # Example: an asymmetric "peanut/figure-eight-ish" curve that a
        # plain four-bar coupler curve generally can't reproduce well, so
        # the search should escalate to a six-bar.
        x = math.cos(t) + 0.35 * math.cos(2 * t)
        y = math.sin(t) - 0.35 * math.sin(3 * t)
        return (x, y)

        # Other examples you can swap in:
        # Ellipse:            return (2*math.cos(t), 1*math.sin(t))
        # Astroid:            return (math.cos(t)**3, math.sin(t)**3)
        # Limacon:            r = 1 + 2*math.cos(t); return (r*math.cos(t), r*math.sin(t))

    print("Searching for minimum-link mechanism...\n")
    result = search_minimum_link_mechanism(
        target_trajectory,
        n_samples=80,
        max_extra_dyads=3,   # try four-bar, six-bar, eight-bar, ten-bar
        tol=0.03,
        mode="shape",        # match curve shape (scale/rotation/translation free)
        popsize=40,
        maxiter=400,
        seed=1,
        workers=-1,          # use all CPU cores
        verbose=True,
    )

    print()
    print(describe(result))
    print()
    print(print_link_color_legend(result))
    print()
    print("As shown in the plot/animation:")
    print(describe_display_geometry(result, target_trajectory))

    plot_result(result, target_trajectory, save_path="linkage_result.png")

    animate_mechanism(
        result, target_trajectory,
        n_frames=72, fps=20, trail=True,
        save_path="linkage_animation.gif",
    )
