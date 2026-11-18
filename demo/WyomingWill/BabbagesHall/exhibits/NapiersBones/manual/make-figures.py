"""Napier's bones manual's figures (Babbage's Hall).

    python3 manual/make-figures.py      (from the exhibit's folder; Pillow, lua)

The rods are the simulation's own faces (faces/*.png, from make-faces.py,
the same pictures that are printed to wrap the rods), laid side by side.
The sums along the diagonals and Genaille's path come from bones.lua, the
exhibit's own arithmetic (run with lua). Only the red strip, the tints, the
path and the labels are added. Writes manual/fig-*.png (all but
fig-exhibit.png, a screenshot of the simulation)."""
import os, subprocess, sys
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
EX = os.path.dirname(HERE)
sys.path.insert(0, EX)
FONTS = "/usr/share/fonts/truetype/dejavu/"
def font(px, bold=False): return ImageFont.truetype(FONTS + ("DejaVuSans-Bold.ttf" if bold else "DejaVuSans.ttf"), int(px))

# (as make-faces.py: mm, y up from the bottom; 8 px a mm)
W, H, CELL, BOTTOM, PX = 16.0, 176.0, 16.0, 10.0, 8
TOP_CELL = BOTTOM + 9 * CELL
E = 9 * CELL / 44
INK, RED, BLUE = (30, 24, 18), (200, 30, 26), (30, 70, 170)
def napier_row(k): y0 = BOTTOM + (9 - k) * CELL; return y0, y0 + CELL
def genaille_row(m):
    top = TOP_CELL
    for r in range(2, m): top -= r * E
    return top - m * E, top
def py(ymm): return (H - ymm) * PX                     # (mm up -> pixels down)
FW = int(W * PX)


def lua(expr):
    """a value worked by bones.lua"""
    code = 'local B = dofile("bones.lua"); ' + expr
    return subprocess.run(["lua", "-e", code], cwd=EX, capture_output=True, text=True, check=True).stdout.strip()


def board(kind, digits):
    """the index rod and the rods for digits side by side, as on the board"""
    faces = [Image.open(os.path.join(EX, "faces", f"{kind}-index.png")).convert("RGB")]
    faces += [Image.open(os.path.join(EX, "faces", f"{kind}-{d}.png")).convert("RGB") for d in digits]
    im = Image.new("RGB", (FW * len(faces), faces[0].height), (255, 255, 255))
    for i, f in enumerate(faces): im.paste(f, (i * FW, 0))
    g = ImageDraw.Draw(im)
    for i in range(1, len(faces)): g.line([(i * FW, 0), (i * FW, im.height)], fill=(120, 110, 95), width=3)
    g.rectangle([0, 0, im.width - 1, im.height - 1], outline=(120, 110, 95), width=3)
    return im


def tint(im, poly, col, alpha=90):
    over = Image.new("RGBA", im.size, (0, 0, 0, 0))
    ImageDraw.Draw(over).polygon(poly, fill=col + (alpha,))
    return Image.alpha_composite(im.convert("RGBA"), over).convert("RGB")


def strip(im, y0, y1, alpha=70):
    """the red strip across a row, as the exhibit marks it"""
    return tint(im, [(0, py(y1)), (im.width, py(y1)), (im.width, py(y0)), (0, py(y0))], RED, alpha)


def pad(im, l=0, t=0, r=0, b=0):
    out = Image.new("RGB", (im.width + l + r, im.height + t + b), (255, 255, 255))
    out.paste(im, (l, t)); return out


def save(im, name, width=None):
    if width and im.width != width:
        im = im.resize((width, round(im.height * width / im.width)), Image.LANCZOS)
    im.save(os.path.join(HERE, name), optimize=True)
    print("  manual/" + name, im.size)


# 1. one rod: its four faces (rod 1 of the set: 0, 1, 9, 8), and the index
faces = [Image.open(os.path.join(EX, "faces", f"napier-{d}.png")).convert("RGB") for d in ("index", 0, 1, 9, 8)]
gap = 40
im = Image.new("RGB", (5 * FW + 4 * gap + 3 * gap, faces[0].height + 90), (255, 255, 255))
g = ImageDraw.Draw(im)
xs = []
for i, f in enumerate(faces):
    x = gap + i * (FW + gap) + (gap if i > 0 else 0)
    xs.append(x)
    im.paste(f, (x, 0))
    g.rectangle([x, 0, x + FW - 1, f.height - 1], outline=(120, 110, 95), width=3)
g.text((xs[0] + FW / 2, faces[0].height + 30), "the index", font=font(30, True), fill=INK, anchor="mm")
g.text(((xs[1] + xs[4] + FW) / 2, faces[0].height + 30), "the four faces of one rod (0, 1, 9, 8)", font=font(30, True), fill=INK, anchor="mm")
g.line([(xs[1], faces[0].height + 60), (xs[4] + FW, faces[0].height + 60)], fill=INK, width=3)
save(im, "fig-rod.png", 330)

# 2. one cell, large: the tens above the diagonal, the units below
f = Image.open(os.path.join(EX, "faces", "napier-7.png")).convert("RGB")
y0, y1 = napier_row(8)
cell = f.crop((0, int(py(y1)), FW, int(py(y0)))).resize((FW * 3, FW * 3), Image.LANCZOS)
im = pad(cell, 20, 20, 460, 20)
g = ImageDraw.Draw(im)
g.rectangle([20, 20, 20 + cell.width, 20 + cell.height], outline=(120, 110, 95), width=3)
for (x, y), text in (((20 + cell.width * 0.29, 20 + cell.height * 0.29), "the tens: 5"), ((20 + cell.width * 0.71, 20 + cell.height * 0.71), "the units: 6")):
    g.line([(x + 30, y), (20 + cell.width + 40, y)], fill=BLUE, width=3)
    g.text((20 + cell.width + 50, y), text, font=font(34), fill=BLUE, anchor="lm")
g.text((20 + cell.width + 50, 20 + cell.height / 2), "7 × 8 = 56", font=font(40, True), fill=INK, anchor="lm")
save(im, "fig-cell.png", 430)

# 3. 4138 laid on the board, row 6 marked
digits = [4, 1, 3, 8]
im = board("napier", digits)
y0, y1 = napier_row(6)
im = strip(im, y0, y1)
save(im, "fig-board.png", 270)

# 4. row 6, large: the diagonals tinted, their sums under them (bones.lua's)
out = lua('local c = {} for _, d in ipairs({4,1,3,8}) do c[#c+1] = B.cell(d, 6) end '
          'local s, k, p = B.diagonals(c) print(table.concat(s, ",") .. "|" .. table.concat(k, ",") .. "|" .. p)')
sums, carries, product = out.split("|")
sums = [int(x) for x in sums.split(",")]; carries = [int(x) for x in carries.split(",")]
row = im.crop((0, int(py(y1)), im.width, int(py(y0))))
row = board("napier", digits).crop((0, int(py(y1)), im.width, int(py(y0))))
n = len(digits)
S = 2                                                  # (shown twice the size)
row = row.resize((row.width * S, row.height * S), Image.LANCZOS)
c = FW * S; top, bot = 0, row.height
inset = 0.6 * PX * S
TINTS = [(70, 140, 220), (240, 160, 40)]
# (band i: from rod i's diagonal to rod i+1's: rod i's units and rod i+1's tens)
for i in range(n + 1):
    xl = (i) * c + c                                   # (the left edge of rod i's face; i = 0 the first rod's tens alone)
    if i == 0:
        poly = [(c, bot), (c, top), (2 * c, top)]      # (the first rod's upper-left triangle)
    elif i == n:
        poly = [(n * c, bot), ((n + 1) * c, bot), ((n + 1) * c, top)]
    else:
        poly = [(i * c, bot), ((i + 1) * c, bot), ((i + 2) * c, top), ((i + 1) * c, top)]
    row = tint(row, poly, TINTS[i % 2], 60)
L = 70
im = pad(row, 10, 10, 10, 230)
g = ImageDraw.Draw(im)
g.text((10 + c / 2, 10 + bot / 2), "", font=font(30), fill=INK)
for i in range(n + 1):
    # (under each band's bottom: rod i's units are at the bottom right of rod i's cell)
    xc = 10 + (i + 1) * c - (c * 0.25 if i < n else -0.0) + (c * 0.25 if i == 0 else 0)
    xc = 10 + (i + 0.5) * c + c * 0.5 if i > 0 else 10 + c * 1.25
    if i == n: xc = 10 + (n + 0.75) * c
    g.text((xc, 10 + bot + 40), str(sums[i]), font=font(44, True), fill=TINTS[i % 2], anchor="mm")
g.text((10 + c / 2, 10 + bot + 40), "sums", font=font(30), fill=INK, anchor="mm")
# (from the right: the carry each sends left, then the digit written)
written = []
carry = 0
for i in range(n, -1, -1):
    v = sums[i] + carry
    written.append((i, v % 10, v // 10))
    carry = v // 10
for i, dgt, cy in written:
    xc = 10 + (i + 0.5) * c + c * 0.5 if i > 0 else 10 + c * 1.25
    if i == n: xc = 10 + (n + 0.75) * c
    if cy:
        g.text((xc - c * 0.5, 10 + bot + 95), f"\u2190 carry {cy}", font=font(26), fill=RED, anchor="mm")
    g.text((xc, 10 + bot + 160), str(dgt), font=font(52, True), fill=INK, anchor="mm")
g.text((10 + c / 2, 10 + bot + 160), "row 6", font=font(30), fill=INK, anchor="mm")
save(im, "fig-row.png", 560)
print("   (4138 x 6:", product, ")")

# 5. Genaille's rods: 874, row 7, the path (bones.lua's) followed from the right
gd = [8, 7, 4]
out = lua('local s, p = B.genaille({8,7,4}, 7) local t = {} for _, x in ipairs(p) do t[#t+1] = x[1] .. ":" .. x[2] end print(s .. "|" .. table.concat(t, ","))')
gprod, path = out.split("|")
path = [tuple(int(v) for v in x.split(":")) for x in path.split(",")]
im = board("genaille", gd)
m = 7
y0, y1 = genaille_row(m)
im = strip(im, y0, y1, 45)
# (crop to the rows around 7, then draw the path, twice the size)
ca, cb = int(py(genaille_row(9)[1] + 2)), int(py(genaille_row(6)[0] - 2))
ca, cb = int(py(y1 + 6)), int(py(y0 - 6))
crop = im.crop((0, ca, im.width, cb))
S = 2
crop = crop.resize((crop.width * S, crop.height * S), Image.LANCZOS)
g = ImageDraw.Draw(crop)
def entry_xy(place, c):
    yc = y1 - (c + 0.5) * E
    x = place * FW + (W - 3.0) * PX if place > 0 else FW - 2.6 * PX
    return x * S, (py(yc) - ca) * S
pts = [entry_xy(p, c) for p, c in path]
for k in range(len(pts) - 1):
    (xa, ya), (xb, yb) = pts[k], pts[k + 1]
    # (along the triangle: from beside the entry to its tip on the next rod's left edge, then across)
    tipx = path[k][0] * FW * S
    g.line([(xa - 3.5 * PX * S, ya), (tipx, yb), (xb + 2.2 * PX * S, yb)], fill=RED, width=5)
for (x, y) in pts:
    g.ellipse([x - 2.6 * PX * S / 2 - 6, y - 2.6 * PX * S / 2 - 6, x + 2.6 * PX * S / 2 + 6, y + 2.6 * PX * S / 2 + 6], outline=RED, width=5)
im = pad(crop, 10, 10, 10, 120)
g = ImageDraw.Draw(im)
for (x, y), (p, c) in zip(pts, path):
    pass
digits_read = list(gprod)
xs = [x for x, y in pts][::-1]
for x, d in zip(xs, digits_read):
    g.text((10 + x, 10 + crop.height + 55), d, font=font(56, True), fill=INK, anchor="mm")
g.text((10 + 8, 10 + crop.height + 105), "", font=font(20), fill=INK)
save(im, "fig-genaille.png", 520)
print("   (874 x 7:", gprod, path, ")")

# 6. the whole Genaille board for 874, the row marked
im = board("genaille", gd)
im = strip(im, y0, y1, 60)
save(im, "fig-genaille-board.png", 270)
