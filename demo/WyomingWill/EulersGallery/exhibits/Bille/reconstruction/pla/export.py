"""Write the print and simulation files for a design.
usage: python3 export.py design.npy SPEC t_mm NAME outdir
  NAME.stl        print file, mm, base on z = 0: outer surface + the void as an
                  inner shell (inward-facing triangles) -> one watertight solid
  NAME.obj        display mesh (outer surface), cm, centre of mass at origin
  NAME-data.lua   p26.lua-style data: cm, kg, body frame = principal axes,
                  COM at origin, faces with COM heights and tipping targets
  NAME-cutaway.png  cutaway (3D half + meridian section with the margins)
  NAME-props.txt  exact mass properties and margins
"""
import numpy as np, sys, os, warnings
from core import *
from opt3 import unpack, verts, parse
warnings.filterwarnings('ignore')

def polys_to_tris(V, faces):
    T = []
    for n, d, idx in faces:
        for j in range(1, len(idx) - 1):
            a, b, c = idx[0], idx[j], idx[j + 1]
            if np.cross(V[b] - V[a], V[c] - V[a]) @ n < 0: b, c = c, b
            T.append((a, b, c))
    return np.array(T)

def write_stl(fn, tris_list, name):
    with open(fn, 'w') as f:
        f.write(f"solid {name}\n")
        for V, T, flip in tris_list:
            for a, b, c in T:
                if flip: b, c = c, b
                p, q, r = V[a], V[b], V[c]
                nn = np.cross(q - p, r - p); nn /= np.linalg.norm(nn)
                f.write(f"  facet normal {nn[0]:.6e} {nn[1]:.6e} {nn[2]:.6e}\n    outer loop\n")
                for v in (p, q, r): f.write(f"      vertex {v[0]:.6f} {v[1]:.6f} {v[2]:.6f}\n")
                f.write("    endloop\n  endfacet\n")
        f.write(f"endsolid {name}\n")

def section(Vpoly, faces, axis_dir):
    """polygon of the polytope cut by the plane through the z axis containing axis_dir"""
    nrm = np.cross(axis_dir, [0, 0, 1.0]); nrm /= np.linalg.norm(nrm)
    pts = []
    for n, d, idx in faces:
        P = Vpoly[idx]
        for i in range(len(P)):
            a, b = P[i], P[(i + 1) % len(P)]
            sa, sb = a @ nrm, b @ nrm
            if abs(sa) < 1e-12: pts.append(a)
            if sa * sb < 0: pts.append(a + (b - a) * sa / (sa - sb))
    pts = np.array(pts); q = np.c_[pts @ axis_dir, pts[:, 2]]
    h = ConvexHull(q); return q[h.vertices]

def main(fx, spec, t_mm, name, out):
    x = np.load(fx); rings = parse(spec); t = t_mm / 10
    R, Z, H, zs = unpack(x, len(rings))
    V = verts(rings, R, Z, H)
    faces, _ = faces_of(V)
    mp = mass_props(V, faces, t, zs)
    c = mp['com']; M = mp['M']; I = mp['I']
    base = int(np.argmin([f[0][2] for f in faces]))
    sm = summary_margin(V, faces, c, base, 0)
    st, un = equilibria(V, faces, c)
    void = mp['void']; vfaces, _ = faces_of(void)
    os.makedirs(out, exist_ok=True)
    # ---------- STL (mm, base on z=0)
    Vmm = V * 10; Wmm = void * 10
    write_stl(f"{out}/{name}.stl", [(Vmm, polys_to_tris(Vmm, faces), False), (Wmm, polys_to_tris(Wmm, vfaces), True)], name)
    # ---------- body frame: COM at origin (principal axes: z by symmetry, x/y degenerate)
    ev = np.linalg.eigvalsh(I)
    assert abs(I[0, 1]) < 1e-6 * ev.max() and abs(I[0, 2]) < 1e-6 * ev.max() and abs(I[1, 2]) < 1e-6 * ev.max()
    Vc = V - c
    K2 = np.diag(I) / M   # cm^2
    # ---------- faces: names by band (sorted by normal z), tipping targets
    keyset = sorted(set(round(f[0][2], 5) for i, f in enumerate(faces) if i != base))
    bandname = {kz: f"S{j+1}" for j, kz in enumerate(keyset)}
    fname = ["base" if i == base else bandname[round(f[0][2], 5)] for i, f in enumerate(faces)]
    edgeface = {}
    for i, (n, d, idx) in enumerate(faces):
        for j in range(len(idx)):
            e = tuple(sorted((idx[j], idx[(j + 1) % len(idx)]))); edgeface.setdefault(e, []).append(i)
    nxt = []
    for i, (n, d, idx) in enumerate(faces):
        if i == base: nxt.append(None); continue
        p = c - (n @ c + d) * n; P = V[idx]; best = None
        for j in range(len(idx)):
            a, b = P[j], P[(j + 1) % len(idx)]
            out_n = np.cross(b - a, n); out_n /= np.linalg.norm(out_n)
            s = (p - a) @ out_n
            if best is None or s > best[0]: best = (s, tuple(sorted((idx[j], idx[(j + 1) % len(idx)]))))
        other = [q for q in edgeface[best[1]] if q != i][0]
        nxt.append(fname[other])
    # ---------- OBJ (cm, COM origin), flat faces
    with open(f"{out}/{name}.obj", "w") as f:
        f.write(f"# {name}: PLA-only monostable polyhedron, outer surface, cm, centre of mass at the origin, z up\n")
        k = 0
        for n, d, idx in faces:
            P = Vc[idx]
            for v in P: f.write("v %.5f %.5f %.5f\n" % tuple(v))
            for j in range(1, len(idx) - 1):
                a, b, cc = 0, j, j + 1
                if np.cross(P[b] - P[a], P[cc] - P[a]) @ n < 0: b, cc = cc, b
                f.write("f %d %d %d\n" % (k + a + 1, k + b + 1, k + cc + 1))
            k += len(idx)
    # ---------- Lua data
    fm, vm = margins(V, faces, c, base, 0)
    hts = [-(f[0] @ c + f[1]) for f in faces]
    with open(f"{out}/{name}-data.lua", "w") as f:
        f.write(f"""-- {name}: a monostable polyhedron printed in PLA ONLY (no added weights).
-- Rings (bottom to top, k:phase): {spec}; apex on the axis. {len(faces)} faces, {len(V)} vertices.
-- Interior: {t_mm:.1f} mm walls everywhere, solid PLA below z = {zs*10:.2f} mm (above the base),
-- one closed air void above it (the inner offset of the faces). PLA 1.24 g/cm^3.
-- Exact polyhedral mass properties (scripts in poly-pla/). Equilibria with this
-- centre of mass: {len(st)} stable face (the base), {len(un)} unstable vertex (the apex).
-- Smallest margin: every other face's COM foot lies >= {sm['face']*10:.2f} mm outside it;
-- the COM is >= {sm['vert']*10:.2f} mm from making any other corner an equilibrium.
-- Units cm, kg. Body frame: z up through the apex, origin at the centre of mass;
-- x, y, z are principal axes (k-fold symmetry).
return {{
  size = {H:.4f}, mass = {M/1000:.6f}, margin = 0.04, rings = "{spec}", wall = {t:.3f}, solidTo = {zs:.5f},
  inertia = {{ {K2[0]:.6f}, {K2[1]:.6f}, {K2[2]:.6f} }},   -- squared radii of gyration, cm^2
  down = {{ 0, 0, -1 }}, top = {{ {Vc[0][0]:.6f}, {Vc[0][1]:.6f}, {Vc[0][2]:.6f} }},
  restHeight = {-(Vc[:,2].min()):.5f}, topHeight = {Vc[0][2]:.5f},
  vertices = {{
""")
        for v in Vc: f.write("    %.5f,%.5f,%.5f,\n" % tuple(v))
        f.write("  },\n  -- faces: outward normal, centre-of-mass height above it (cm), band, the band it tips onto, margin (cm, foot outside the face)\n  faces = {\n")
        order = [base] + [i for i in np.argsort([f[0][2] for f in faces]) if i != base]
        for i in order:
            n = faces[i][0]
            nx = "nil" if nxt[i] is None else f'"{nxt[i]}"'
            f.write(f'    {{ n = {{ {n[0]:.6f}, {n[1]:.6f}, {n[2]:.6f} }}, h = {hts[i]:.5f}, name = "{fname[i]}", next = {nx}, out = {fm[i]:.4f} }},\n')
        f.write("  },\n}\n")
    # ---------- props
    with open(f"{out}/{name}-props.txt", "w") as f:
        f.write(f"rings {spec}; wall {t_mm} mm; solid below {zs*10:.3f} mm; height {H*10:.2f} mm; max vertex diameter {2*R.max()*10:.2f} mm\n")
        f.write(f"outer volume {mp['outer_vol']:.4f} cm^3, void {mp['void_vol']:.4f} cm^3, PLA {mp['vol']:.4f} cm^3\n")
        f.write(f"mass {M:.3f} g; COM height above base {c[2]*10:.4f} mm (x,y = {c[0]:.1e}, {c[1]:.1e})\n")
        f.write(f"inertia about COM (g cm^2): Ixx {I[0,0]:.3f} Iyy {I[1,1]:.3f} Izz {I[2,2]:.3f}\n")
        f.write(f"equilibria: stable {len(st)} {['base' if s==base else s for s in st]}, unstable {len(un)} {['apex' if u==0 else u for u in un]}\n")
        f.write(f"smallest margin: faces {sm['face']*10:.3f} mm, vertices {sm['vert']*10:.3f} mm; base: foot {sm['base']*10:.2f} mm inside\n")
        rows = {}
        for i in order:
            r = f"  face {fname[i]:5s} n_z {faces[i][0][2]:+.4f} h {hts[i]*10:8.3f} mm  foot {'outside' if fm[i]>0 else 'INSIDE '} by {abs(fm[i])*10:6.2f} mm  -> {nxt[i]}"
            rows[r] = rows.get(r, 0) + 1
        for r, cnt in rows.items(): f.write(f"{r}   (x{cnt})\n")
        rows = {}
        for j in sorted(vm, key=lambda j: V[j][2]):
            r = f"  vertex z {V[j][2]*10:7.2f} mm r {np.hypot(*V[j][:2])*10:6.2f} mm  COM distance to its equilibrium cone {vm[j]*10:6.2f} mm{'  (UNSTABLE EQUILIBRIUM)' if vm[j]<1e-12 else ''}"
            rows[r] = rows.get(r, 0) + 1
        for r, cnt in rows.items(): f.write(f"{r}   (x{cnt})\n")
    # ---------- cutaway
    import matplotlib; matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    from mpl_toolkits.mplot3d.art3d import Poly3DCollection
    fig = plt.figure(figsize=(13, 6.5))
    ax = fig.add_subplot(1, 2, 1, projection='3d')
    # outer: show only the faces with a vertex at y>=0 side cut away: draw back half (y>0) outer, and void
    def cut_half(Vp, fcs, keep_neg=True):
        polys = []
        for n, d, idx in fcs:
            P = Vp[idx]
            # clip polygon to y >= 0 (the far half; the cut faces the viewer)
            out = []
            for i in range(len(P)):
                a, b = P[i], P[(i + 1) % len(P)]
                ia, ib = a[1] >= -1e-9, b[1] >= -1e-9
                if ia: out.append(a)
                if ia != ib: out.append(a + (b - a) * (a[1]) / (a[1] - b[1]))
            if len(out) >= 3: polys.append(np.array(out) * 10)
        return polys
    ax.add_collection3d(Poly3DCollection(cut_half(V, faces), facecolor='#e8a33d', edgecolor='#6b4512', alpha=0.35, linewidths=0.6))
    ax.add_collection3d(Poly3DCollection(cut_half(void, vfaces), facecolor='#9cc3e6', edgecolor='#2a5b8a', alpha=0.9, linewidths=0.5))
    # the cut face (section y=0): solid = outer section minus void section
    so = section(V, faces, np.array([1.0, 0, 0])); sv = section(void, vfaces, np.array([1.0, 0, 0]))
    # solid slab in the cut plane (convex: outer section below the void floor)
    sl = so[so[:, 1] <= zs + 1e-9]
    edge = []
    for i in range(len(so)):
        a, b = so[i], so[(i + 1) % len(so)]
        if (a[1] - zs) * (b[1] - zs) < 0: edge.append(a + (b - a) * (zs - a[1]) / (b[1] - a[1]))
    sl = np.r_[sl, edge]; sl = sl[ConvexHull(sl).vertices]
    ax.add_collection3d(Poly3DCollection([np.c_[sl[:, 0], np.zeros(len(sl)), sl[:, 1]] * 10], facecolor='#c0661c', edgecolor='#6b4512', alpha=1.0))
    for sec, col in ((so, '#6b4512'), (sv, '#2a5b8a')):
        q = np.r_[sec, sec[:1]] * 10
        ax.plot(q[:, 0], np.zeros(len(q)) - 0.2, q[:, 1], color=col, lw=1.5)
    ax.scatter([c[0] * 10], [-1.0], [c[2] * 10], color='k', s=30, depthshade=False)
    L = max(H, 2 * R.max()) * 10 / 2
    ax.set_xlim(-L, L); ax.set_ylim(-L, L); ax.set_zlim(0, 2 * L)
    ax.set_box_aspect((1, 1, 1)); ax.view_init(elev=14, azim=-62)
    ax.set_xlabel('x mm'); ax.set_ylabel('y mm'); ax.set_zlabel('z mm')
    ax.set_title(f"{name}: half cut away (orange PLA, blue = closed air void)", fontsize=10)
    ax2 = fig.add_subplot(1, 2, 2)
    # meridian through face midlines (apothem section) -- the margins live here
    phi_mid = rings[0][1] + np.pi / rings[0][0]
    dirm = np.array([np.cos(phi_mid), np.sin(phi_mid), 0])
    so = section(V, faces, dirm) * 10; sv = section(void, vfaces, dirm) * 10
    ax2.fill(so[:, 0], so[:, 1], color='#e8a33d', label='solid PLA (100% infill)')
    ax2.fill(sv[:, 0], sv[:, 1], color='#ffffff', ec='#2a5b8a', lw=0.8, label='closed air void')
    ax2.plot(*np.r_[so, so[:1]].T, color='#6b4512', lw=1)
    C2 = np.array([0, c[2] * 10]); ax2.plot(*C2, 'ko', ms=5, label='centre of mass')
    # perpendicular feet onto the right-hand profile edges
    for i, (n, d, idx) in enumerate(faces):
        if abs(np.arctan2(n[1], n[0]) - phi_mid) % (2 * np.pi) > 1e-3 or i == base: continue
        nr = n @ dirm; nz = n[2]; dd = -(n @ c + d) * 10
        foot = C2 + dd * np.array([nr, nz])
        ax2.plot([C2[0], foot[0]], [C2[1], foot[1]], color='#555', lw=0.6, ls='--')
        ax2.plot(*foot, 'x', color='#b00', ms=6)
    ax2.set_aspect('equal'); ax2.grid(alpha=0.3)
    ax2.set_xlabel('distance from axis, through the face midlines (mm)'); ax2.set_ylabel('height above base (mm)')
    ax2.set_title(f"section: {M:.0f} g, COM {c[2]*10:.1f} mm up; red x = COM feet\n(all outside their faces by >= {min(sm['face'],sm['vert'])*10:.1f} mm)", fontsize=10)
    ax2.legend(loc='upper right', fontsize=8)
    fig.tight_layout(); fig.savefig(f"{out}/{name}-cutaway.png", dpi=130)
    # ---------- verify STL with trimesh
    import trimesh
    m = trimesh.load(f"{out}/{name}.stl", process=True)
    m.merge_vertices()
    parts = m.split(only_watertight=False)
    rep = (f"trimesh: watertight {m.is_watertight}, winding consistent {m.is_winding_consistent}, is_volume {m.is_volume}, "
           f"bodies {len(parts)}, volume {m.volume/1000:.4f} cm^3 (exact {mp['vol']:.4f}), "
           f"mass at 1.24 {m.volume/1000*1.24:.3f} g, COM z {m.center_mass[2]:.4f} mm (exact {c[2]*10:.4f}), "
           f"extents {np.round(m.extents,2)} mm")
    print(rep)
    with open(f"{out}/{name}-props.txt", "a") as f: f.write(rep + "\n")
    print(open(f"{out}/{name}-props.txt").read())

if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], float(sys.argv[3]), sys.argv[4], sys.argv[5])
