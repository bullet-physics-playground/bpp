"""Watertight print mesh of a w37 design (manifold3d booleans), in mm, base on z = 0.
solid = (Outer - Inner) U (union of bosses Inner & B_v) [U floor slab] - pockets
Pockets: vertical cylinders with NSEG sides, CIRCUMSCRIBED about the design circle
(so the printed hole is never smaller than designed), or square prisms."""
import numpy as np
import manifold3d as mf
from scipy.spatial import ConvexHull
from core import halfspace_poly
from w37 import boss_halfspaces

NSEG = 96

def hull_manifold(P):
    return mf.Manifold.hull_points([tuple(map(float, p)) for p in P])

def pocket_manifold(W, c):
    if W.prism:
        s = 2 * W.a
        m = mf.Manifold.cube((s, s, W.L), center=True)
        ph = np.degrees(np.arctan2(c[1], c[0]))
        m = m.rotate((0.0, 0.0, float(ph)))
    else:
        r = W.a / np.cos(np.pi / NSEG)             # circumscribed polygon
        m = mf.Manifold.cylinder(W.L, r, r, NSEG, center=True)
    return m.translate(tuple(map(float, c)))

def build(B, with_pockets=True):
    """B: w37.Body (nominal). returns (manifold solid, parts dict)"""
    W = B.W; t = B.t
    A0 = np.array([f[0] for f in B.faces]); b0 = np.array([f[1] for f in B.faces])
    outer = hull_manifold(B.V)
    iA = np.r_[A0, [[0, 0, -1.0]]]; ib = np.r_[b0 + t, t]
    inner = hull_manifold(halfspace_poly(iA, ib))
    solid = outer - inner
    bosses = []
    # bosses for the MESH: B_v & (outer offset by t/2) instead of B_v & Inner, so that
    # every boss overlaps the wall by t/2 (same solid; no coincident faces). Lateral
    # box planes of different rings are nudged by 0.3-2 um so that no two coincide.
    mA = np.r_[A0, [[0, 0, -1.0]]]; mb = np.r_[b0 + t / 2, t / 2]
    for k, (A, b) in enumerate(B.regions):
        b = b.copy()
        if len(b) == 6: b[2:4] -= 0.0003 * (1 + (k - 1) // 6)
        P = halfspace_poly(np.r_[mA, A], np.r_[mb, b])
        if P is None or len(P) < 4: continue
        bosses.append(hull_manifold(P))
    if bosses:
        solid = mf.Manifold.batch_boolean([solid] + bosses, mf.OpType.Add)
    pk = [pocket_manifold(W, c) for c in B.P] if with_pockets else []
    if pk:
        solid = solid - mf.Manifold.batch_boolean(pk, mf.OpType.Add)
    return solid, dict(outer=outer, inner=inner, bosses=bosses, pockets=pk)

def to_trimesh(m):
    import trimesh
    mesh = m.to_mesh()
    V = np.asarray(mesh.vert_properties)[:, :3]; F = np.asarray(mesh.tri_verts)
    return trimesh.Trimesh(V, F, process=True)
