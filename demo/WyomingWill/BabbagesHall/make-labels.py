"""Babbage's Hall's cast lettering, as OBJ files in hall-meshes/, and
labels.lua with each one's size. Run from this folder: python3 make-labels.py
(needs Pillow, NumPy and the DejaVu fonts). python3 make-labels.py title
[key ...] remakes only those labels (and their lines in labels.lua).

Raised lettering as an OBJ: text rasterised with a TrueType font, filled
pixels merged into rectangles (runs in a row, then identical runs stacked
down the rows), each rectangle a box. x along the text, y up, z out.
(The method of Euler's Gallery's make-labels.py.)"""
import re, sys
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


OUT = "hall-meshes"
SERIF = "/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf"
jobs = [
 ("title", "BABBAGE’S HALL", 24, 2),
 ("subtitle", "ENGINES OF CALCULATION", 8, 1.0),
 ("domino-adder", "THE DOMINO HALF ADDER", 4.2, 0.5),
 ("differential", "THE DIFFERENTIAL", 4.2, 0.5),
 ("pascaline", "THE PASCALINE", 4.2, 0.5),
 ("difference-engine", "THE DIFFERENCE ENGINE", 4.2, 0.5),
 ("tide-predictor", "KELVIN’S TIDE PREDICTOR", 4.2, 0.5),
 ("differential-analyser", "THE DIFFERENTIAL ANALYSER", 4.2, 0.5),
 ("digicomp", "DIGI-COMP II", 4.2, 0.5),
 ("lehmer", "LEHMER’S NUMBER SIEVE", 4.2, 0.5),
 ("reserved", "RESERVED", 4.2, 0.5),
 ("in-preparation", "IN PREPARATION", 2.4, 0.4),
]
only = set(sys.argv[1:])
unknown = only - {j[0] for j in jobs}
if unknown: sys.exit("no such label: " + ", ".join(sorted(unknown)))
lines = ["-- label meshes: file, width and height in cm (made by make-labels.py)", "return {"]
for key, text, h, d in jobs:
    if only and key not in only: continue
    w, hh, n = text_obj(text, f"{OUT}/label-{key}.obj", h, d, font=SERIF, px=48)
    lines.append(f'  ["{key}"] = {{ file = "label-{key}.obj", w = {w:.2f}, h = {hh:.2f} }},')
    print(key, round(w,1), n)
lines.append("}")
if only:
    old = open(f"{OUT}/labels.lua").read()
    for ln in lines[2:-1]:
        key = re.match(r'  \["([^"]+)"\]', ln).group(1)
        old, k = re.subn(r'(?m)^  \["%s"\] = .*$' % re.escape(key), lambda m: ln, old)
        if k != 1: sys.exit("labels.lua has no line for " + key)
    open(f"{OUT}/labels.lua", "w").write(old)
else:
    open(f"{OUT}/labels.lua", "w").write("\n".join(lines) + "\n")
