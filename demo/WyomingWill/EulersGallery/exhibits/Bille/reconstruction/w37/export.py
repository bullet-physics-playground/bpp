"""Export a w37 design: print STL (mm, base on z=0), bpp mesh/data (cm, kg, COM
origin), properties + pocket/pause table, cutaway figure.
usage: python3 export.py design.npy WEIGHT name outdir [t_mm] [layer_mm]"""
import numpy as np, sys, os, json
from w37 import *
from materials import CAT
from meshbuild import build
import trimesh

def bands(B):
    faces = B.faces; base = B.base
    keyset = sorted(set(round(f[0][2], 5) for i, f in enumerate(faces) if i != base))
    bandname = {kz: f"S{j+1}" for j, kz in enumerate(keyset)}
    return ["base" if i == base else bandname[round(f[0][2], 5)] for i, f in enumerate(faces)]

def tip_targets(B, fname):
    V, faces, c = B.V, B.faces, B.com
    edgeface = {}
    for i, (n, d, idx) in enumerate(faces):
        for j in range(len(idx)):
            e = tuple(sorted((idx[j], idx[(j + 1) % len(idx)]))); edgeface.setdefault(e, []).append(i)
    nxt = []
    for i, (n, d, idx) in enumerate(faces):
        if i == B.base: nxt.append(None); continue
        p = c - (n @ c + d) * n; P = V[idx]; best = None
        for j in range(len(idx)):
            a, b = P[j], P[(j + 1) % len(idx)]
            on = np.cross(b - a, n); on /= np.linalg.norm(on)
            s = (p - a) @ on
            if best is None or s > best[0]: best = (s, tuple(sorted((idx[j], idx[(j + 1) % len(idx)]))))
        other = [q for q in edgeface[best[1]] if q != i][0]
        nxt.append(fname[other])
    return nxt

def pause_table(B, layer=0.2, first=0.2):
    """per pocket group (ring): pocket floor / top, weight top, and the pause:
    PrusaSlicer slices each layer at its middle, so the pocket is open in every
    layer whose middle lies inside it; the first layer whose middle lies above
    the pocket top closes it (bridge). Pause BEFORE that layer."""
    W = B.W; rows = []
    groups = [(0, "apex", [0])] + [(i + 1, f"ring {i}", list(range(1 + 6 * i, 7 + 6 * i))) for i in range(6)]
    for gi, name, idx in groups:
        p = B.P[idx[0]]
        zf = p[2] - W.L / 2; zt = p[2] + W.L / 2
        tops = np.r_[first, first + layer * np.arange(1, 3000)]   # layer tops
        mids = tops - np.r_[first, np.full(2999, layer)] / 2
        open_ = np.where((mids > zf) & (mids < zt))[0]
        k_last = open_.max(); k_close = k_last + 1
        floor_print = tops[open_.min()] - (first if open_.min() == 0 else layer)   # bottom of the first open layer
        rows.append(dict(name=name, n=len(idx), r=np.hypot(p[0], p[1]), z=p[2], floor=zf, top=zt,
                         wtop=zf + W.h, pause_after=tops[k_last], close_layer=k_close + 1,
                         printed_floor=floor_print, printed_wtop=floor_print + W.h))
    return rows

def main(fx, wname, name, out, t=0.8, layer=0.2):
    x = np.load(fx); W = CAT[wname]
    B = Body(x, W, t=t)
    os.makedirs(out, exist_ok=True)
    m = B.margins(); st, un = B.count()
    fname = bands(B); nxt = tip_targets(B, fname)
    # ---------------- STL
    solid, parts = build(B)
    mesh = solid.to_mesh()
    Vm = np.asarray(mesh.vert_properties)[:, :3]; Fm = np.asarray(mesh.tri_verts)
    tm = trimesh.Trimesh(Vm, Fm, process=False)
    tm.export(f"{out}/{name}.stl")
    chk = trimesh.load(f"{out}/{name}.stl", process=True)   # STL stores loose triangles: merge vertices
    rep = dict(watertight=bool(chk.is_watertight), winding=bool(chk.is_winding_consistent), volume=float(chk.volume),
               exact_volume=float(B.vol_pla), com_z=float(chk.center_mass[2]), exact_pla_com_z=float(B.m1_pla[2] / B.vol_pla),
               extents=chk.extents.tolist(), shells=len(solid.decompose()), positive_shells=sum(1 for c_ in solid.decompose() if c_.volume() > 0), genus=int(solid.genus()),
               dup_positions=int(len(Vm) - len(np.unique(Vm.round(6), axis=0))))
    # ---------------- bpp mesh + data (cm, kg, COM at origin)
    c = B.com; Vc = (B.V - c) / 10
    with open(f"{out}/{name}.obj", "w") as f:
        f.write(f"# {name}: weighted 37-corner monostable polyhedron, outer surface, cm, centre of mass at the origin, z up\n")
        k = 0
        for n, d, idx in B.faces:
            P = Vc[idx]
            for v in P: f.write("v %.5f %.5f %.5f\n" % tuple(v))
            for j in range(1, len(idx) - 1):
                a, b, cc = 0, j, j + 1
                if np.cross(P[b] - P[a], P[cc] - P[a]) @ n < 0: b, cc = cc, b
                f.write("f %d %d %d\n" % (k + a + 1, k + b + 1, k + cc + 1))
            k += len(idx)
    I = B.I; K2 = np.diag(I) / B.M / 100     # cm^2
    hts = [-(f[0] @ c + f[1]) / 10 for f in B.faces]
    fm, vm = m['fm'], m['vm']
    H = B.V[:, 2].max()
    with open(f"{out}/{name}-data.lua", "w") as f:
        f.write(f"""-- {name}: weighted 37-corner monostable polyhedron (Conway (6,6)-spiral after
-- Domokos & Kovacs 2023), the FDM build: PLA shell {t:.1f} mm, a {W.name} weight
-- ({W.m:.2f} g) in a pocket at every corner. Exact mass model (exhibits/Bille/reconstruction/w37/w37.py).
-- Equilibria: {len(st)} stable face (the base), {len(un)} unstable vertex (the apex).
-- Smallest margins: faces {m['face']:.2f} mm, corners {m['vert']:.2f} mm.
-- Units cm, kg. Body frame: z up through the apex, origin at the centre of mass.
return {{
  size = {H/10:.4f}, mass = {B.M/1000:.6f}, margin = 0.04,
  inertia = {{ {K2[0]:.6f}, {K2[1]:.6f}, {K2[2]:.6f} }},   -- squared radii of gyration, cm^2
  down = {{ 0, 0, -1 }}, top = {{ {Vc[0][0]:.6f}, {Vc[0][1]:.6f}, {Vc[0][2]:.6f} }},
  restHeight = {-(Vc[:,2].min()):.5f}, topHeight = {Vc[0][2]:.5f},
  vertices = {{
""")
        for v in Vc: f.write("    %.5f,%.5f,%.5f,\n" % tuple(v))
        f.write("  },\n  -- faces: outward normal, centre-of-mass height above it (cm), band, the band it tips onto, margin (cm, foot outside the face)\n  faces = {\n")
        order = [B.base] + [i for i in np.argsort([f[0][2] for f in B.faces]) if i != B.base]
        for i in order:
            n = B.faces[i][0]; nx = "nil" if nxt[i] is None else f'"{nxt[i]}"'
            f.write(f'    {{ n = {{ {n[0]:.6f}, {n[1]:.6f}, {n[2]:.6f} }}, h = {hts[i]:.5f}, name = "{fname[i]}", next = {nx}, out = {fm[i]/10:.4f} }},\n')
        f.write("  },\n}\n")
    # ---------------- properties
    pt = pause_table(B, layer)
    L = []
    L.append(f"design {fx}: weight {W.name} ({W.kind} {W.dims} mm, {W.m:.3f} g), wall {t} mm, boss wall {B.tb} mm, glue {B.gm[0]} g/pocket")
    L.append("x (R0..R5, Z1..Z5, H; mm) = " + json.dumps(np.round(x, 4).tolist()))
    L.append(f"height {H:.2f} mm, vertex circle diameter {2*x[:6].max():.2f} mm, base hexagon circumradius {x[0]:.2f} mm")
    L.append(f"volumes (mm^3): outer {B.vol_outer:.1f}, shell {B.vol_shell:.1f}, bosses (union, incl. pockets) {B.vol_boss:.1f}, pockets {B.vol_pockets:.1f}, PLA {B.vol_pla:.1f}")
    L.append(f"mass: PLA {B.m_pla:.2f} g + weights {B.wm.sum():.2f} g + glue {B.gm.sum():.2f} g = {B.M:.2f} g")
    L.append(f"COM height above base {c[2]:.3f} mm; inertia about COM (g mm^2) Ixx {I[0,0]:.0f} Iyy {I[1,1]:.0f} Izz {I[2,2]:.0f}")
    L.append(f"equilibria: stable {len(st)} {['base' if s_==B.base else s_ for s_ in st]}, unstable {len(un)} {['apex' if u==0 else int(u) for u in un]}")
    L.append(f"smallest margin: faces {m['face']:.3f} mm, vertices {m['vert']:.3f} mm; base: foot {m['base']:.2f} mm inside")
    rows = {}
    for i in order:
        n = B.faces[i][0]; ovh = np.degrees(np.arcsin(max(0, -n[2]))) if fname[i] != 'base' else 0
        r = f"  face {fname[i]:5s} n_z {n[2]:+.4f} (overhang {ovh:4.1f} deg from vertical)  h {hts[i]*10:8.3f} mm  foot {'outside' if fm[i]>0 else 'INSIDE '} by {abs(fm[i]):6.2f} mm  -> {nxt[i]}"
        rows[r] = rows.get(r, 0) + 1
    for r, cnt in rows.items(): L.append(f"{r}   (x{cnt})")
    rows = {}
    for j in sorted(vm, key=lambda j: B.V[j][2]):
        r = f"  vertex z {B.V[j][2]:7.2f} mm r {np.hypot(*B.V[j][:2]):6.2f} mm  COM distance to its equilibrium cone {vm[j]:6.2f} mm{'  (UNSTABLE EQUILIBRIUM)' if vm[j]<1e-9 else ''}"
        rows[r] = rows.get(r, 0) + 1
    for r, cnt in rows.items(): L.append(f"{r}   (x{cnt})")
    gap, sep = pocket_clearance(B.P, W)
    L.append(f"pockets: {W.kind} pocket radius/half-side {W.a:.2f} mm, height {W.L:.2f} mm; smallest wall between two pockets {gap:.2f} mm")
    L.append(f"layer {layer} mm (first {layer} mm); PrusaSlicer slices at mid-layer")
    for r in pt:
        d = np.linalg.norm(B.P[[0, 1, 7, 13, 19, 25, 31][["apex","ring 0","ring 1","ring 2","ring 3","ring 4","ring 5"].index(r['name'])]] -
                           B.V[[0, 1, 7, 13, 19, 25, 31][["apex","ring 0","ring 1","ring 2","ring 3","ring 4","ring 5"].index(r['name'])]])
        L.append(f"  {r['name']:7s} x{r['n']}: pocket centre r {r['r']:6.2f} z {r['z']:6.2f} (corner {d:5.2f} mm away); floor {r['floor']:6.2f} top {r['top']:6.2f}; "
                 f"PAUSE after the layer ending at Z = {r['pause_after']:.2f} mm (weight top as printed {r['printed_wtop']:.2f} mm)")
    L.append("STL check: " + json.dumps(rep))
    open(f"{out}/{name}-props.txt", "w").write("\n".join(L) + "\n")
    print("\n".join(L))
    json.dump(dict(x=x.tolist(), H=float(H), weight=wname, t=t, M=B.M, m_pla=B.m_pla, com=c.tolist(), face=m['face'], vert=m['vert'],
                   base=m['base'], pauses=pt, stl=rep, gap=gap), open(f"{out}/{name}-summary.json", "w"), indent=1, default=float)
    return B, pt

if __name__ == "__main__":
    a = sys.argv
    main(a[1], a[2], a[3], a[4], float(a[5]) if len(a) > 5 else 0.8, float(a[6]) if len(a) > 6 else 0.2)
