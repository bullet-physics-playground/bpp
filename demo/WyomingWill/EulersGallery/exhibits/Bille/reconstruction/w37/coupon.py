"""Fit-test coupon: a small block with three pockets exactly like the body's
(same radius, height and clearance), printed with the same settings and one pause,
to check the weights fit before the 16-hour print.
usage: python3 coupon.py WEIGHT out.stl"""
import sys, numpy as np
import manifold3d as mf
import trimesh
from materials import CAT
from meshbuild import pocket_manifold

def main(wname, out):
    W = CAT[wname]
    floor = 1.2; top = 1.2
    Hc = floor + W.L + top
    s = 2 * W.a + 2 * 1.6
    n = 3
    block = mf.Manifold.cube((n * s, s, Hc))
    pk = [pocket_manifold(W, np.array([s / 2 + i * s, s / 2, floor + W.L / 2])) for i in range(n)]
    solid = block - mf.Manifold.batch_boolean(pk, mf.OpType.Add)
    m = solid.to_mesh()
    tm = trimesh.Trimesh(np.asarray(m.vert_properties)[:, :3], np.asarray(m.tri_verts), process=False)
    tm.export(out)
    zt = floor + W.L
    # pause: after the last layer whose middle is below the pocket top (0.2 mm layers)
    k = int(np.ceil((zt + 0.1) / 0.2 - 1e-9)) - 1   # last layer whose middle (0.2k - 0.1) is below the pocket top
    print(f"coupon {out}: {n*s:.1f} x {s:.1f} x {Hc:.2f} mm, watertight {tm.is_watertight}; pocket top {zt:.2f} mm; "
          f"PAUSE after the layer ending at Z = {0.2*k:.2f} mm")
    return 0.2 * k

if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
