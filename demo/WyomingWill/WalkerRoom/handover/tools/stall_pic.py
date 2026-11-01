import matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Polygon
def load(p):
    parts, ground, head = [], [], ""
    for l in open(p):
        if l.startswith("SNAP"): head = l.split(); bx = float(head[3]); by = float(head[4])
        elif l.startswith("PART"):
            k, z, pts = l[5:].strip().split("|")
            parts.append((k, float(z), [tuple(map(float, q.split(","))) for q in pts.split(";")]))
        elif l.startswith("GROUND"):
            ground = [tuple(map(float, q.split(","))) for q in l.split()[1].split(";")]
    return float(head[1]), bx, parts, ground
fig, axs = plt.subplots(1, 2, figsize=(15, 5.6))
for ax, (f, title) in zip(axs, [("snap_g.txt", "duty 85, guides: stalled (seed 1, steps 7, 2.25 s)"), ("snap_d.txt", "duty 85 diag: climbing the same step (seed 1, 3.0 s)")]):
    t, bx, parts, ground = load(f)
    gx = [x - bx for x, _ in ground]; gy = [y for _, y in ground]
    ax.fill_between(gx, gy, -2, color="#c8b89a", step=None, zorder=0); ax.plot(gx, gy, color="#6b5a3a", lw=1)
    for k, z, pts in sorted(parts, key=lambda p: -p[1]):   # far side first
        near = z > 0.5
        col = {"body": "#E5007E", "buildFoot": "#333"}.get(k, "#888" if near else "#bbb")
        if "Crossbar" in k: col = "#E5007E"
        ax.add_patch(Polygon([(x - bx, y) for x, y in pts], closed=True, fc=col, ec="#222" if near else "#999", lw=0.6, alpha=1 if near else 0.55, zorder=3 if near else 2))
    ax.set_xlim(-45, 45); ax.set_ylim(-1, 30); ax.set_aspect("equal"); ax.set_title(title, fontsize=11)
    ax.set_xlabel("cm along the walk from the body's centre (walking to the right)"); ax.set_ylabel("cm up")
fig.suptitle("Side view, to scale: near-side parts dark, far side light; the ground is the smooth step shape (the mesh's faces are 68° ramps)", fontsize=10.5)
fig.tight_layout(rect=(0, 0, 1, 0.93)); fig.savefig("duty85_stall.png", dpi=100)
