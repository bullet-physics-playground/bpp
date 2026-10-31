import matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt, numpy as np
from matplotlib.patches import Polygon
def rect(cx, cy, L, T, ang):
    c, s = np.cos(ang), np.sin(ang)
    pts = np.array([[-L/2,-T/2],[L/2,-T/2],[L/2,T/2],[-L/2,T/2]])
    return pts @ np.array([[c,-s],[s,c]]).T + [cx, cy]
w, g = 0.5, 0.5 / np.tan(np.radians(30))
fig, axs = plt.subplots(1, 4, figsize=(13, 5))
cases = [(90, "As built: 90°", "#4a7fb5"), (30, "At one stop: 30°\n(foot meets the link's corner)", "#4a7fb5"),
         (150, "At the other: 150°", "#4a7fb5"), (10, "My first try, 10°:\nthe foot inside the leg", "#d9534f")]
for ax, (a, title, col) in zip(axs, cases):
    ax.add_patch(Polygon(rect(0, g + 6, 12, 2 * w, np.pi / 2), closed=True, fc="#c9a227", ec="k", lw=0.8))
    ax.add_patch(Polygon(np.array([[-0.35, -0.05], [0.35, -0.05], [0.35, g + 0.4], [-0.35, g + 0.4]]), closed=True, fc="#999", ec="k", lw=0.6, alpha=0.6))
    ang = np.radians(a - 90); c, s = np.cos(ang), np.sin(ang)
    ax.add_patch(Polygon(rect(0.25 * s, -0.25 * c, 8, 0.5, ang), closed=True, fc=col, ec="k", lw=0.8, alpha=0.9))
    ax.plot(0, 0, "ko", ms=4)
    ax.set_title(title, fontsize=10.5); ax.set_aspect("equal"); ax.set_xlim(-6, 6); ax.set_ylim(-5, 9); ax.axis("off")
fig.suptitle("A buildable ankle stop, to scale: 8 × 0.5 cm foot (blue), 1 cm leg link (gold), the pin %.2f cm below the link's end (grey tongue).\n"
             "The foot turns from 30° to 150° against the link (±60° from square)." % g, fontsize=10.5)
fig.tight_layout(rect=(0, 0, 1, 0.85)); fig.savefig("ankle_stop.png", dpi=110)
