"""Figures for a w37 design: cutaway section through two opposite corners (the
y = 0 mirror plane), with weights drawn in; pause-height diagram; 3D half-cutaway.
usage: python3 figs.py design.npy WEIGHT name outdir"""
import numpy as np, sys, os
import matplotlib; matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import Polygon, Circle, Rectangle
from mpl_toolkits.mplot3d.art3d import Poly3DCollection
from w37 import *
from materials import CAT
from meshbuild import build
from export import pause_table

INK = '#1f2328'; PLA = '#9fb7d0'; PLA_E = '#4a6a8a'; WCOL = {'cube': '#5b5b66', 'sphere': '#7a7f88'}
GOLD = '#c8792a'

def section(solid):
    m = solid.rotate((90.0, 0.0, 0.0))        # (x, y, z) -> (x, -z, y): y=0 plane -> slice height 0
    cs = m.slice(0.0)
    polys = cs.to_polygons()
    # rotated coords: x stays, new y = -z_old? check by bounds; return as (x, z_old)
    out = []
    for p in polys:
        p = np.asarray(p)
        out.append(p)
    return out, m

def draw_section(ax, B, solid, pt=None, title=None):
    polys, m = section(solid)
    # figure out mapping: the rotated manifold's y equals -z or +z of the original
    zmax = B.V[:, 2].max()
    allp = np.vstack(polys)
    sgn = 1.0 if allp[:, 1].max() > zmax * 0.5 else -1.0
    from matplotlib.path import Path
    from matplotlib.patches import PathPatch
    verts = []; codes = []
    for p in polys:
        q = np.c_[p[:, 0], sgn * p[:, 1]]
        verts += q.tolist() + [q[0].tolist()]
        codes += [Path.MOVETO] + [Path.LINETO] * (len(q) - 1) + [Path.CLOSEPOLY]
    ax.add_patch(PathPatch(Path(verts, codes), facecolor=PLA, edgecolor=PLA_E, lw=0.6))
    W = B.W
    for i in range(len(B.P)):
        p = B.Wpos[i]
        if abs(p[1]) > 1e-6: continue
        if W.kind == 'sphere':
            ax.add_patch(Circle((p[0], p[2]), W.dims[0] / 2, facecolor=WCOL['sphere'], edgecolor=INK, lw=0.6))
        elif W.kind == 'cube':
            s = W.dims[0]; ax.add_patch(Rectangle((p[0] - s / 2, p[2] - s / 2), s, s, facecolor=WCOL['cube'], edgecolor=INK, lw=0.6))
        else:
            d, l = W.dims; ax.add_patch(Rectangle((p[0] - d / 2, p[2] - l / 2), d, l, facecolor=WCOL['sphere'], edgecolor=INK, lw=0.6))
    ax.plot([0], [B.com[2]], marker='+', color=GOLD, ms=12, mew=2)
    ax.annotate(f"centre of mass\n{B.com[2]:.1f} mm up", (0, B.com[2]), (8, B.com[2] + 14), fontsize=8, color=GOLD,
                arrowprops=dict(arrowstyle='-', color=GOLD, lw=0.8))
    if pt is not None:
        xr = B.V[:, 0].max()
        last = -1e9
        for r in sorted(pt, key=lambda r: r['pause_after']):
            z = r['pause_after']
            ax.axhline(z, color=GOLD, lw=0.6, ls=(0, (4, 3)))
            zt = max(z, last + 4.5); last = zt
            ax.text(xr + 3, zt, f"pause {z:.2f} ({r['name']})", fontsize=7, va='center', color=GOLD, bbox=dict(fc='white', ec='none', pad=0.6))
    ax.set_aspect('equal'); ax.set_xlabel('x (mm)'); ax.set_ylabel('z (mm, above the bed)')
    lo = B.V[:, 0].min(); hi = B.V[:, 0].max()
    ax.set_xlim(lo - 5, hi + (45 if pt is not None else 5)); ax.set_ylim(-3, B.V[:, 2].max() + 4)
    ax.spines[['top', 'right']].set_visible(False)
    if title: ax.set_title(title, fontsize=10, loc='left')

def draw_bottom_zoom(ax, B, solid, pt=None):
    draw_section(ax, B, solid, pt)
    xr = B.V[:, 0].max()
    zt = B.P[1 + 6 * 3, 2] + B.W.L / 2 + 3
    ax.set_xlim(-xr - 3, xr + 3); ax.set_ylim(-1, zt)
    for t in list(ax.texts): t.remove()       # pause labels / COM note belong to the full view
    if pt is not None:
        for r in pt:
            if r['pause_after'] < zt:
                ax.text(xr + 4, r['pause_after'], f"{r['pause_after']:.2f}", fontsize=7, va='center', color=GOLD, clip_on=False)

def draw_3d(ax, solid, B):
    import trimesh
    half = solid.trim_by_plane((0.0, -1.0, 0.0), 0.0)     # keep y <= 0
    mesh = half.to_mesh(); V = np.asarray(mesh.vert_properties)[:, :3]; F = np.asarray(mesh.tri_verts)
    tri = V[F]
    n = np.cross(tri[:, 1] - tri[:, 0], tri[:, 2] - tri[:, 0]); n /= np.linalg.norm(n, axis=1)[:, None] + 1e-12
    light = np.array([0.4, -0.7, 0.6]); light /= np.linalg.norm(light)
    sh = 0.45 + 0.5 * np.clip(n @ light, 0, 1)
    base = np.array(matplotlib.colors.to_rgb(PLA))
    cols = np.clip(base[None, :] * sh[:, None] + 0.05, 0, 1)
    cut = np.abs(n[:, 1] - 1) < 1e-6
    cols[cut] = np.array(matplotlib.colors.to_rgb('#d9e3ee'))
    pc = Poly3DCollection(tri, facecolors=cols, edgecolors='none', linewidths=0)
    ax.add_collection3d(pc)
    W = B.W
    u, v = np.mgrid[0:2 * np.pi:16j, 0:np.pi:9j]
    for p in B.Wpos:
        if p[1] > 1e-6: continue
        r = W.dims[0] / 2 if W.kind == 'sphere' else W.dims[0] / 2
        ax.plot_surface(p[0] + r * np.cos(u) * np.sin(v), p[1] + r * np.sin(u) * np.sin(v), p[2] + r * np.cos(v),
                        color='#5b5b66', linewidth=0, shade=True)
    R = B.V[:, 0].max(); H = B.V[:, 2].max()
    ax.set_xlim(-R, R); ax.set_ylim(-R, R); ax.set_zlim(0, H)
    ax.set_box_aspect((2 * R, 2 * R, H)); ax.view_init(elev=14, azim=-90 + 25); ax.set_axis_off()

def main(fx, wname, name, out, t=0.8):
    x = np.load(fx); W = CAT[wname]; B = Body(x, W, t=t)
    solid, _ = build(B)
    pt = pause_table(B)
    os.makedirs(out, exist_ok=True)
    fig, ax = plt.subplots(figsize=(6.2, 6.6))
    draw_section(ax, B, solid, pt, title=f"Section through two opposite corners: PLA (blue), weights (grey)")
    fig.tight_layout(); fig.savefig(f"{out}/{name}-section.png", dpi=170); plt.close(fig)
    fig, ax = plt.subplots(figsize=(9.0, 3.0))
    draw_bottom_zoom(ax, B, solid, pt); ax.set_title("Bottom rings 0-3, close up (same section); dashed: pause heights (mm)", fontsize=9, loc='left')
    fig.tight_layout(); fig.savefig(f"{out}/{name}-bottom.png", dpi=170); plt.close(fig)
    fig = plt.figure(figsize=(7, 7.5)); ax = fig.add_subplot(projection='3d')
    draw_3d(ax, solid, B); fig.tight_layout(); fig.savefig(f"{out}/{name}-cutaway3d.png", dpi=150); plt.close(fig)
    print("figures written", out)

if __name__ == "__main__":
    a = sys.argv; main(a[1], a[2], a[3], a[4], float(a[5]) if len(a) > 5 else 0.8)
