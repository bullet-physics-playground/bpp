"""The Galton board manual's figures (Babbage's Hall).

    python3 manual/make-figures.py      (from the exhibit's folder; Pillow)

fig-board.png is a screenshot of the simulation (manual/screenshot.png, at
the end of the tour's first run) with the parts named. fig-routes.png
counts the routes to each pin (Pascal's triangle), on the board's own pin
lattice (galton-geometry.lua: 12 mm apart, rows V apart). fig-runs.png is
the simulation's two tour runs (manual/runs.txt, as the console printed
them: bpp -f galton.lua -n 9000) against fair coins."""
import math, os, re
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
FONTS = "/usr/share/fonts/truetype/dejavu/"
def font(px, bold=False): return ImageFont.truetype(FONTS + ("DejaVuSans-Bold.ttf" if bold else "DejaVuSans.ttf"), int(px))
INK, BLUE, GOLD, GREY = (30, 30, 30), (30, 70, 170), (190, 150, 30), (150, 150, 150)
ROWS = 12


def save(im, name, width=None):
    if width and im.width != width:
        im = im.resize((width, round(im.height * width / im.width)), Image.LANCZOS)
    im.save(os.path.join(HERE, name), optimize=True)
    print("  manual/" + name, im.size)


# 1. the board, its parts named (the screenshot's own pixel places)
shot = Image.open(os.path.join(HERE, "screenshot.png")).convert("RGB")
W, H = shot.size
pad = 250
im = Image.new("RGB", (W + pad, H), (255, 255, 255))
im.paste(shot, (0, 0))
g = ImageDraw.Draw(im)
for text, (px, py), ty in (("the hopper", (0.45, 0.13), 0.06), ("two metering wheels,\nturned by the crank", (0.50, 0.26), 0.18),
                           ("twelve rows of pins", (0.57, 0.45), 0.42), ("thirteen bins; a gold line\nin each: fair coins' share", (0.56, 0.66), 0.56),
                           ("the slide, and the\ndrawer under it", (0.50, 0.87), 0.97)):
    x, y = px * W, py * H
    g.line([(x, y), (W - 140, y), (W + 10, ty * H)], fill=BLUE, width=2) if False else g.line([(x, y), (W + 10, ty * H)], fill=BLUE, width=2)
    g.ellipse([x - 4, y - 4, x + 4, y + 4], fill=BLUE)
    g.multiline_text((W + 16, ty * H), text, font=font(17), fill=BLUE, anchor="lm" if "\n" not in text else "ld", spacing=3)
save(im, "fig-board.png", 560)


# 2. the routes to each pin: the board's lattice, the count of ways at each
S, V = 12.0, 12.0 * math.sqrt(3) / 2         # (mm: the pins' spacing and the rows', as galton-geometry.lua)
SC = 9                                        # (pixels a mm)
N = 7                                         # (rows drawn: 0 to 6, then the 12th written below)
Wd = int((N + 1) * S * SC); Hd = int((N + 0.8) * V * SC + 40)
im = Image.new("RGB", (Wd, Hd + 105), (255, 255, 255))
g = ImageDraw.Draw(im)
cx = Wd / 2
for r in range(N):
    for k in range(r + 1):
        x = cx + (k - r / 2) * S * SC
        y = 30 + r * V * SC
        n = math.comb(r, k)
        g.ellipse([x - 2 * SC, y - 2 * SC, x + 2 * SC, y + 2 * SC], fill=(235, 200, 90), outline=(150, 110, 20))
        g.text((x, y), str(n), font=font(20 if n < 100 else 16, True), fill=INK, anchor="mm")
        if r < N - 1:
            for dk in (0, 1):
                x2 = cx + (k + dk - (r + 1) / 2) * S * SC
                y2 = 30 + (r + 1) * V * SC
                g.line([(x + (x2 - x) * 0.32, y + (y2 - y) * 0.32), (x + (x2 - x) * 0.68, y + (y2 - y) * 0.68)], fill=GREY, width=2)
yb = 30 + (N - 0.4) * V * SC
g.text((cx, yb + 10), "⋮", font=font(30), fill=GREY, anchor="mt")
row12 = [math.comb(ROWS, k) for k in range(ROWS + 1)]
bw = Wd / (ROWS + 1)
for k, n in enumerate(row12):
    g.text(((k + 0.5) * bw, yb + 70), str(n), font=font(19, True), fill=INK, anchor="mm")
    g.text(((k + 0.5) * bw, yb + 105), f"bin {k}", font=font(13), fill=GREY, anchor="mm")
g.text((cx, yb + 145), "after 12 rows: 4096 routes in all", font=font(20), fill=INK, anchor="mm")
save(im, "fig-routes.png", 520)


# 3. the simulation's two runs against fair coins
runs = []
for l in open(os.path.join(HERE, "runs.txt")):
    m = re.search(r"bins:((?: \d+)+)", l)
    if m: runs.append([int(x) for x in m.group(1).split()])
fair = [150 * c / 4096 for c in row12]
Wd, Hd = 1100, 460
im = Image.new("RGB", (Wd, Hd), (255, 255, 255))
g = ImageDraw.Draw(im)
x0, y0, y1 = 70, Hd - 70, 40
top = 45
def Y(v): return y0 - (y0 - y1) * v / top
for v in range(0, top + 1, 10):
    g.line([(x0, Y(v)), (Wd - 20, Y(v))], fill=(230, 230, 230), width=1)
    g.text((x0 - 8, Y(v)), str(v), font=font(16), fill=GREY, anchor="rm")
bw = (Wd - 20 - x0) / (ROWS + 1)
COLS = [(70, 120, 200), (230, 140, 50)]
for k in range(ROWS + 1):
    for j, run in enumerate(runs):
        xa = x0 + k * bw + bw * (0.14 + 0.36 * j)
        g.rectangle([xa, Y(run[k]), xa + bw * 0.34, y0], fill=COLS[j])
    g.line([(x0 + k * bw + bw * 0.06, Y(fair[k])), (x0 + (k + 1) * bw - bw * 0.06, Y(fair[k]))], fill=GOLD, width=4)
    g.text((x0 + (k + 0.5) * bw, y0 + 18), str(k), font=font(17), fill=INK, anchor="mm")
g.text((x0 + (ROWS + 1) * bw / 2, y0 + 48), "bin (how many times the ball went right)", font=font(17), fill=INK, anchor="mm")
g.text((x0 - 50, y1 - 22), "balls", font=font(16), fill=GREY, anchor="lm")
lx = Wd - 360
for j, (col, text) in enumerate(((COLS[0], "the tour's first run"), (COLS[1], "its second run"), (GOLD, "fair coins (the gold lines)"))):
    yy = y1 + 8 + j * 28
    if j < 2: g.rectangle([lx, yy - 9, lx + 24, yy + 9], fill=col)
    else: g.line([(lx, yy), (lx + 24, yy)], fill=col, width=4)
    g.text((lx + 34, yy), text, font=font(17), fill=INK, anchor="lm")
save(im, "fig-runs.png", 900)
