"""Printed-hull drop cases for BPP (printing chat, Nov 2026).

  python3 printed_hull.py shape.obj [--size 36] [--offset 0] [--step 0.1] [--out cases] [--name NAME]

shape.obj: convex body, any units, centre of mass anywhere, upright (resting point) = -Y, so +Y is up.
It is scaled so its longest extent is --size mm, cut across: the plane through the centre of mass whose
normal is the longest principal axis made perpendicular to Y (moved by --offset mm along that normal).
Each half is built as printed: layers stacked outward from the cut, 0.2 mm first then 0.12 mm; per layer
the section at mid-height as a vertical wall, with points every 0.1 mm around it at mid-height and on the
contour inset by half a layer at the layer's top and bottom (the rounded bead). No chamfer, pins or seam.

Writes three BPP case folders, each with gomboc-meshes/gomboc-hull.lua (+ gomboc.obj for display):
  NAME_al  halves aligned
  NAME_sz  the half on the +n side moved 0.1 mm sideways (n x up)
  NAME_sy  that half moved 0.1 mm up
The centre of mass moves by the slip x (fraction of hull points on the moved side), about half the slip.
Also saves NAME_<case>.npy (hull vertices, mm, centre of mass at the origin, in the build frame:
+y up, +x = cut normal). Run the drops with run.sh."""
import argparse, os, numpy as np, trimesh
from shapely.geometry import Polygon

def printed_points(m, n, offset, first=0.2, layer=0.12, step=0.1):
    R = trimesh.geometry.align_vectors(n, [0, 0, 1])[:3, :3]
    g = m.copy(); g.apply_transform(np.r_[np.c_[R, np.zeros(3)], [[0, 0, 0, 1]]]); pts = []
    for sgn in (1, -1):
        zmax = (sgn * (g.vertices[:, 2] - offset)).max(); b = [0.0, first]
        while b[-1] + layer <= zmax + 1e-9: b.append(b[-1] + layer)
        for z0, z1 in zip(b[:-1], b[1:]):
            h = z1 - z0; zc = offset + sgn * (z0 + z1) / 2
            sec = g.section([0, 0, 1], [0, 0, zc])
            if sec is None: continue
            polys = [Polygon(e[:, :2]) for e in sec.discrete if len(e) > 3]
            if not polys: continue
            poly = max(polys, key=lambda p: p.area).buffer(0)
            for dz, inset in [(0.0, 0.0), (h / 2, h / 2), (-h / 2, h / 2)]:
                p = poly.buffer(-inset, join_style=1) if inset else poly
                for gg in getattr(p, 'geoms', [p]):
                    ring = gg.exterior; L = ring.length; k = max(8, int(L / step))
                    xy = np.array([ring.interpolate(t * L).coords[0] for t in np.linspace(0, 1, k, endpoint=False)])
                    pts.append(np.c_[xy, np.full(len(xy), zc + sgn * dz)])
    return np.vstack(pts) @ R              # back to the body frame

def write_case(folder, V_mm):
    """V_mm: hull points, mm, centre of mass at the origin, +y up -> BPP case in cm"""
    V = V_mm / 10.0; h = trimesh.convex.convex_hull(V); c = h.center_mass; P = h.vertices - c; h.apply_translation(-c)
    k2 = np.diag(h.moment_inertia / h.volume); os.makedirs(f'{folder}/gomboc-meshes', exist_ok=True)
    h.export(f'{folder}/gomboc-meshes/gomboc.obj')
    with open(f'{folder}/gomboc-meshes/gomboc-hull.lua', 'w') as f:
        f.write(f'-- printed hull ({os.path.basename(folder)}), from printed_hull.py\nreturn {{\n'
                f'  size = {np.ptp(P, 0).max():.4f}, volume = {h.volume:.6f},\n'
                f'  restHeight = {-P[:, 1].min():.6f}, topHeight = {P[:, 1].max():.6f},\n'
                f'  inertia = {{ {k2[0]:.6f}, {k2[1]:.6f}, {k2[2]:.6f} }},\n  points = {{\n')
        f.write(''.join('    %.7f,%.7f,%.7f,\n' % tuple(p) for p in P) + '  },\n}\n')

if __name__ == '__main__':
    ap = argparse.ArgumentParser(); ap.add_argument('obj'); ap.add_argument('--size', type=float, default=36)
    ap.add_argument('--offset', type=float, default=0.0); ap.add_argument('--out', default='cases'); ap.add_argument('--name')
    ap.add_argument('--step', type=float, default=0.1, help='point spacing on each contour, mm (0.2 halves the hull size; Bullet runs faster)')
    a = ap.parse_args(); name = a.name or os.path.splitext(os.path.basename(a.obj))[0]; os.makedirs(a.out, exist_ok=True)
    m = trimesh.load(a.obj, force='mesh'); m.apply_translation(-m.center_mass); m.apply_scale(a.size / m.extents.max())
    w, Rp = np.linalg.eigh(m.moment_inertia); ax = Rp[:, 0].copy(); ax[1] = 0; n = ax / np.linalg.norm(ax)
    if n[0] < 0: n = -n
    up = np.array([0, 1.0, 0]); side = np.cross(n, up); B = np.vstack([n, up, side])   # build frame rows
    P0 = printed_points(m, n, a.offset, step=a.step) @ B.T                     # x = cut normal, y = up, z = side
    for case, v in [('al', None), ('sz', np.array([0, 0, 0.1])), ('sy', np.array([0, 0.1, 0]))]:
        P = P0.copy(); com = np.zeros(3)
        if v is not None: moved = P[:, 0] > a.offset; P[moved] += v; com = v * moved.mean()
        V = trimesh.convex.convex_hull(P).vertices - com
        np.save(f'{a.out}/{name}_{case}.npy', V)
        write_case(f'{a.out}/{name}_{case}', V)
        print(f'{name}_{case}: {len(V)} hull points, rest height {-V[:, 1].min():.3f} mm')
