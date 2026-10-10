"""The cabinet's gilt lettering and the armillary sphere's ring, as OBJ files
in cabinet-meshes/, and labels.lua with each placard's size. Run from this
folder: python3 make-labels.py (needs Pillow, NumPy and the DejaVu fonts).

Raised lettering as an OBJ: text rasterised with a TrueType font, filled
pixels merged into rectangles (runs in a row, then identical runs stacked
down the rows), each rectangle a box. x along the text, y up, z out."""
import math
import numpy as np
from PIL import Image, ImageDraw, ImageFont
def text_obj(text, path, height_cm, depth_cm, font, px=48):
    f = ImageFont.truetype(font, px)
    l, t, r, b = f.getbbox(text)
    W, H = r - l + 4, b - t + 4
    im = Image.new("L", (W, H), 0); ImageDraw.Draw(im).text((2 - l, 2 - t), text, font=f, fill=255)
    a = np.asarray(im) > 127
    s = height_cm / H
    open_ = {}          # (x0,x1) -> top row
    rects = []
    for y in range(H + 1):
        runs = set()
        if y < H:
            row = a[y]; x = 0
            while x < W:
                if row[x]:
                    x0 = x
                    while x < W and row[x]: x += 1
                    runs.add((x0, x))
                else: x += 1
        for k in list(open_):
            if k not in runs:
                rects.append((k[0], k[1], open_.pop(k), y))
        for k in runs:
            if k not in open_: open_[k] = y
    V = []; F = []
    for x0, x1, y0, y1 in rects:
        X0, X1 = x0 * s - W * s / 2, x1 * s - W * s / 2
        Y0, Y1 = (H - y1) * s, (H - y0) * s
        o = len(V)
        for z in (0, depth_cm):
            V.extend([(X0, Y0, z), (X1, Y0, z), (X1, Y1, z), (X0, Y1, z)])
        for q in [(4, 5, 6, 7), (0, 4, 7, 3), (1, 2, 6, 5), (3, 7, 6, 2), (0, 1, 5, 4)]:   # (no back face)
            F.append((o + q[0], o + q[1], o + q[2])); F.append((o + q[0], o + q[2], o + q[3]))
    with open(path, "w") as fo:
        fo.write(f"# lettering: {text}\n")
        for v in V: fo.write("v %.3f %.3f %.3f\n" % v)
        for t in F: fo.write("f %d %d %d\n" % (t[0] + 1, t[1] + 1, t[2] + 1))
    return W * s, H * s, len(F)

def torus(path, R, r, n=48, m=10):
    V=[];F=[]
    for i in range(n):
        a=2*math.pi*i/n
        for j in range(m):
            b=2*math.pi*j/m
            V.append(((R+r*math.cos(b))*math.cos(a), r*math.sin(b), (R+r*math.cos(b))*math.sin(a)))
    for i in range(n):
        for j in range(m):
            p=i*m+j; q=((i+1)%n)*m+j; p2=i*m+(j+1)%m; q2=((i+1)%n)*m+(j+1)%m
            F.append((p,p2,q2)); F.append((p,q2,q))
    with open(path,"w") as f:
        f.write("# ring R=%g r=%g (in the x-z plane)\n"%(R,r))
        for v in V: f.write("v %.3f %.3f %.3f\n"%v)
        for t in F: f.write("f %d %d %d\n"%(t[0]+1,t[1]+1,t[2]+1))


OUT = "cabinet-meshes"
SERIF = "/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf"
jobs = [
 ("title", "EULER’S CABINET OF CURIOSITIES", 22, 2),
 ("gomboc-drop-c", "GÖMBÖC DROP C", 4.2, 0.5),
 ("gomboc-variety", "GÖMBÖC VARIETY", 4.2, 0.5),
 ("bille", "BILLE & POLYHEDRA", 4.2, 0.5),
 ("dzhanibekov", "DZHANIBEKOV EFFECT", 4.2, 0.5),
 ("rattleback", "RATTLEBACK", 4.2, 0.5),
 ("tippe-top", "TIPPE TOP", 4.2, 0.5),
 ("chain-fountain", "CHAIN FOUNTAIN", 4.2, 0.5),
 ("spinning-egg", "SPINNING EGG", 4.2, 0.5),
 ("double-cone", "DOUBLE CONE", 4.2, 0.5),
 ("oloid", "OLOID & SPHERICON", 4.2, 0.5),
 ("slinky", "FALLING SLINKY", 4.2, 0.5),
 ("brazil-nut", "BRAZIL-NUT EFFECT", 4.2, 0.5),
 ("newtons-cradle", "NEWTON’S CRADLE", 4.2, 0.5),
 ("reserved", "RESERVED", 4.2, 0.5),
 ("in-preparation", "IN PREPARATION", 2.4, 0.4),
]
lines = ["-- label meshes: file, width and height in cm (made by labels.py)", "return {"]
for key, text, h, d in jobs:
    w, hh, n = text_obj(text, f"{OUT}/label-{key}.obj", h, d, font=SERIF, px=48)
    lines.append(f'  ["{key}"] = {{ file = "label-{key}.obj", w = {w:.2f}, h = {hh:.2f} }},')
    print(key, round(w,1), n)
lines.append("}")
open(f"{OUT}/labels.lua", "w").write("\n".join(lines) + "\n")

torus(OUT + "/ring.obj", 30, 0.9)
