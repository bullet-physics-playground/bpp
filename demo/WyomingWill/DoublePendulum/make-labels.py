"""The double pendulum's lettering, as OBJ files in dp-meshes/: the names
under the pure swings and on the shakers. Run from this folder:
python3 make-labels.py (needs Pillow, NumPy and the DejaVu fonts).
Raised lettering: text rasterised, filled pixels merged into boxes; x along
the text, y up, z out (toward you)."""
import numpy as np
from PIL import Image, ImageDraw, ImageFont
SERIF = "/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf"
def text_obj(text, path, height_cm, depth_cm, px=48):
    f = ImageFont.truetype(SERIF, px)
    l, t, r, b = f.getbbox(text)
    W, H = r - l + 4, b - t + 4
    im = Image.new("L", (W, H), 0)
    ImageDraw.Draw(im).text((2 - l, 2 - t), text, font=f, fill=255)
    a = np.asarray(im) > 127
    s = height_cm / H
    open_, rects = {}, []
    for y in range(H + 1):
        runs = set()
        if y < H:
            row, x = a[y], 0
            while x < W:
                if row[x]:
                    x0 = x
                    while x < W and row[x]:
                        x += 1
                    runs.add((x0, x))
                else:
                    x += 1
        for k in list(open_):
            if k not in runs:
                rects.append((k[0], k[1], open_.pop(k), y))
        for k in runs:
            if k not in open_:
                open_[k] = y
    V, F = [], []
    for x0, x1, y0, y1 in rects:
        X0, X1 = x0 * s - W * s / 2, x1 * s - W * s / 2
        Y0, Y1 = (H - y1) * s, (H - y0) * s
        o = len(V)
        for z in (0, depth_cm):
            V.extend([(X0, Y0, z), (X1, Y0, z), (X1, Y1, z), (X0, Y1, z)])
        for q in [(4, 5, 6, 7), (0, 4, 7, 3), (1, 2, 6, 5), (3, 7, 6, 2), (0, 1, 5, 4)]:
            F.append((o + q[0], o + q[1], o + q[2]))
            F.append((o + q[0], o + q[2], o + q[3]))
    with open(path, "w") as fo:
        fo.write("# lettering: %s\n" % text)
        for v in V:
            fo.write("v %.3f %.3f %.3f\n" % v)
        for t_ in F:
            fo.write("f %d %d %d\n" % (t_[0] + 1, t_[1] + 1, t_[2] + 1))
    return W * s
for key, text, h in [("together", "BOTH RODS TOGETHER", 1.3), ("opposed", "RODS OPPOSED", 1.3), ("mixed", "A MIX OF THE TWO", 1.3),
                     ("gentle", "TOO GENTLE", 1.0), ("right", "JUST RIGHT", 1.0), ("hard", "TOO HARD", 1.0)]:
    print(key, round(text_obj(text, "dp-meshes/%s.obj" % key, h, 0.3), 1))
