"""Can the gallery's p26/p37 'shell + tungsten' build exist? (cm units internally)
usage (from this folder):  python3 fitcheck.py [variety-reconstruction dir] [dir with core.py]
  defaults: ../../../Gomboc/variety-reconstruction and this folder  ->  runs/fitcheck.log
Weight model as stated in genshell.py: 5.2 g tungsten, centre 3 mm from the corner
towards the vertex mean, 0.5 mm polycarbonate shell. Checks: weight size (W 19.25 g/cm3),
centre-to-centre spacing vs the weight's size, clearance of the weight centre from every
face plane (the shell's inner surface is 0.5 mm in), corner-to-corner spacing, mass,
margins (gallery measure and centre-of-mass-distance measure)."""
import sys, os, numpy as np
HERE = os.path.dirname(os.path.abspath(__file__))
G = os.path.abspath(sys.argv[1]) if len(sys.argv) > 1 else os.path.join(HERE, "../../../Gomboc/variety-reconstruction")
CORE = os.path.abspath(sys.argv[2]) if len(sys.argv) > 2 else HERE   # core.py (same as reconstruction/pla/core.py)
sys.path.insert(0, G); sys.path.insert(0, CORE)
os.chdir(G)
from optnk import make_verts
import opt21s as o
import core
from eq import equilibria
RHO_W = 19.25
m = 5.2
d_ball = (6 * m / RHO_W / np.pi) ** (1 / 3) * 10       # mm
a_cube = (m / RHO_W) ** (1 / 3) * 10
print(f"5.2 g pure tungsten (19.25 g/cm3): ball {d_ball:.2f} mm, cube {a_cube:.2f} mm "
      f"(cube half-diagonal {a_cube*np.sqrt(3)/2:.2f} mm); W heavy alloy 18.0: ball {(6*m/18/np.pi)**(1/3)*10:.2f} mm")
for name, (n, k, f) in {"p26": (5, 5, "shell_5_5.npy"), "p37": (6, 6, "shell_6_6.npy")}.items():
    o.T_MM, o.M_CORNER, o.INSET = 0.5, 0.0052, 0.3
    p = np.load(f); V = make_verts(n, k)(p); V = V * 9.0 / np.ptp(V, axis=0).max()
    pts, ms, c, H, F = o.mass_model(V)
    cen = V.mean(0); d = cen - V; d /= np.linalg.norm(d, axis=1)[:, None]; P = V + 0.3 * d
    mg = o.margins_c(V, c)
    faces, _ = core.faces_of(V)
    base_i = [i for i, (nn, dd, idx) in enumerate(faces) if nn[2] < -0.999][0]
    sm = core.summary_margin(V, faces, c, base_i, 0)
    st, un = core.equilibria(V, faces, c)
    print(f"\n{name}: mass {ms.sum()*1e3:.2f} g ({len(V)} x 5.2 = {len(V)*5.2:.1f} g weights), "
          f"height {np.ptp(V[:,2])*10:.2f} mm, stable {len(st)} unstable {len(un)}")
    print(f"  margins, gallery measure (opt21s.margins_c): face {mg['face']*10:.2f}  vert {mg['vert']*10:.2f}  "
          f"bottom {mg['bottom']*10:.2f}  top {mg['top']*10:.2f} mm -> min {min(mg.values())*10:.2f}")
    print(f"  margins, COM distance (core.summary_margin): face {sm['face']*10:.2f}  vertex {sm['vert']*10:.2f} mm; base foot {sm['base']*10:.2f} mm inside")
    # spacing
    D = np.linalg.norm(P[:, None] - P[None], axis=2) * 10; np.fill_diagonal(D, np.inf)
    C = np.linalg.norm(V[:, None] - V[None], axis=2) * 10; np.fill_diagonal(C, np.inf)
    # per-corner: clearance of weight centre from face planes (only faces through that corner matter most)
    A = np.array([ff[0] for ff in faces]); b = np.array([ff[1] for ff in faces])
    clr = -(P @ A.T + b) * 10          # distance inside each outer face plane (mm)
    inner = clr.min(1) - 0.5           # to the shell's inner surface
    print(f"  weight centre -> nearest outer face plane: min {clr.min(1).min():.2f}  max {clr.min(1).max():.2f} mm "
          f"(inner shell surface {inner.min():.2f}..{inner.max():.2f} mm); a {d_ball:.2f} mm ball needs {d_ball/2:.2f} mm")
    print(f"  weight centre-to-centre: min {D.min():.2f} mm (ball needs {d_ball:.2f}); pairs closer than {d_ball:.2f} mm: {int((D<d_ball).sum()/2)}")
    nr = n
    print("  rings numbered from the top (0) to the base ring; z = height above the base")
    for r in range(nr):
        idx = 1 + r * k + np.arange(k)
        within = C[idx[0], idx[1]]
        nxt = C[idx][:, 1 + (r + 1) * k + np.arange(k)].min() if r + 1 < nr else np.nan
        wwithin = D[idx[0], idx[1]]
        wnxt = D[idx][:, 1 + (r + 1) * k + np.arange(k)].min() if r + 1 < nr else np.nan
        print(f"  ring {r} (z {V[idx[0],2]*10- V[:,2].min()*10:6.2f} mm, r {np.hypot(*V[idx[0],:2])*10:6.2f}): "
              f"corner spacing in ring {within:6.2f}, to next ring {nxt:6.2f} mm | weight centres in ring {wwithin:6.2f}, to next ring {wnxt:6.2f}"
              f" | centre->face plane {clr[idx].min(1).min():.2f} mm")
