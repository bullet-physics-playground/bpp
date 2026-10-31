# The body marks as walker-room.lua now makes them (layout from bpp: layout.txt), seen from above, letters upright
import matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle, Polygon, PathPatch
from matplotlib.textpath import TextPath
from matplotlib.font_manager import FontProperties
from matplotlib.transforms import Affine2D
FP = FontProperties(family="Liberation Sans", weight="bold")
GOLD = "#FFC300"
def ink(c):
    r, g, b = (int(c[i:i + 2], 16) / 255 for i in (1, 3, 5))
    return "#111111" if 0.2126 * r + 0.7152 * g + 0.0722 * b > 0.5 else "#FFFFFF"
def text(ax, t, size, x, y, h, v, col):
    p = TextPath((0, 0), t, size=size / 0.72, prop=FP)   # (OpenSCAD's size is about the capitals' height)
    bb = p.get_extents(); w, hh = bb.width, size
    dx = {"left": -bb.x0, "center": -bb.x0 - w / 2, "right": -bb.x0 - w}[h]
    dy = {"top": -hh, "center": -hh / 2, "bottom": 0}[v]
    ax.add_patch(PathPatch(Affine2D().translate(x + dx, y + dy).transform_path(p), fc=col, ec="none"))
rows = [l.strip().split("|") for l in open("layout.txt")]
fig, axs = plt.subplots(2, 3, figsize=(14, 6.4))
for ax, (name, X, Z, letters, links, lift, diag, g, col, spears) in zip(axs.flat, rows):
    X, Z = float(X), float(Z); k = ink(col)
    ax.add_patch(Rectangle((-X / 2, -Z / 2), X, Z, fc=col, ec="#333", lw=1))
    r = max(0.07 * min(X, Z), 0.8)
    if spears == "true":
        for (x, y, w, h) in [(-X / 2, Z / 2 - r, X, r), (-X / 2, -Z / 2, X, r), (-X / 2, -Z / 2, r, Z), (X / 2 - r, -Z / 2, r, Z)]:
            ax.add_patch(Rectangle((x, y), w, h, fc=GOLD, ec="none"))
    inset = (r if spears == "true" else 0) + 0.6; Xi, Zi = X - 2 * inset, Z - 2 * inset; cs = 0.2 * Zi
    size = min(0.75 * Zi, (Xi - 5 * cs - 2) / (0.75 * len(letters)))
    text(ax, letters, size, 0, 0, "center", "center", k)
    xl, xr, yt, yb = -X / 2 + inset, X / 2 - inset, Z / 2 - inset, -Z / 2 + inset   # (image up = the letters' up)
    text(ax, links, cs, xl, yt, "left", "top", k)
    if lift != "nil": text(ax, lift + "%", cs, xr, yt, "right", "top", k)
    if diag == "true":
        t = 1.5 * cs; ax.add_patch(Polygon([[xl, yb], [xl + t, yb], [xl, yb + t]], closed=True, fc=k, ec="none"))
    if g == "true": text(ax, "G", cs, xr, yb, "right", "bottom", k)
    ax.set_title(name + ("  (guides)" if g == "true" else ""), fontsize=11)
    ax.set_xlim(-31, 31); ax.set_ylim(-13.5, 13.5); ax.set_aspect("equal"); ax.axis("off")
fig.suptitle("The new body marks, from above, to scale (cm), as walker-room.lua makes them: letters in the middle; links top left; lift (% of stride) top right;\n"
             "a triangle bottom left on diag builds; G bottom right on builds held by guides (Hoecken-Spears slider here, the guides version)", fontsize=10.5)
fig.tight_layout(rect=(0, 0, 1, 0.9)); fig.savefig("body_marks_real.png", dpi=100)
