"""The splitter board manual's figures (Babbage's Hall).

    python3 manual/make-figures-splitter.py      (from the exhibit's folder; Pillow)

fig-splitter-tooth.png: two rows of splitters, drawn to splitter-geometry.lua's
sizes (a 30 mm pitch, necks 8 mm wide and 10 long, the teeth 29.05 mm from
pin to neck foot, the foot 8 mm above the next pin), with a ball's way.
fig-splitter-walls.png: the five walls, each the chance of a ball being at
each place after each row, worked exactly (fair, independent coins: what the
gold lines show), a dot's area its chance; the balls a wall takes in red.
fig-splitter-screenshot crops are made by hand from the simulation."""
import math, os
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
FONTS = "/usr/share/fonts/truetype/dejavu/"
def font(px, bold=False): return ImageFont.truetype(FONTS + ("DejaVuSans-Bold.ttf" if bold else "DejaVuSans.ttf"), int(px))
INK, BLUE, RED, GREY = (30, 30, 30), (40, 90, 190), (200, 40, 30), (160, 160, 160)


def save(im, name, width=None):
    if width and im.width != width:
        im = im.resize((width, round(im.height * width / im.width)), Image.LANCZOS)
    im.save(os.path.join(HERE, name), optimize=True)
    print("  manual/" + name, im.size)


# 1. two rows of splitters, and a ball's way
S, NECK_W, NECK_L, TOTAL, PIN_D, FOOT, BALL = 30.0, 8.0, 10.0, 29.05, 4.0, 8.0, 6.0
HW, TH = S / 2 - NECK_W / 2, TOTAL - NECK_L
V = TOTAL + FOOT
SC = 9
Wd, Hd = int(4.4 * S * SC), int((2 * V + 14) * SC)
im = Image.new("RGB", (Wd, Hd), (255, 255, 255))
g = ImageDraw.Draw(im)
X0, Y0 = Wd * 0.47, 10 * SC
def P(x, y): return (X0 + x * SC, Y0 - y * SC)          # (mm: x right, y up from the top pin)
TOOTH = (143, 134, 214)
def tooth(cx, cy):
    """a pin at (cx, cy), its wedge's apex on it, the sides sloping into necks"""
    g.polygon([P(cx, cy), P(cx + HW, cy - TH), P(cx + HW, cy - TOTAL), P(cx - HW, cy - TOTAL), P(cx - HW, cy - TH)], fill=TOOTH, outline=(90, 80, 160))
    g.ellipse([*P(cx - PIN_D / 2, cy + PIN_D / 2), *P(cx + PIN_D / 2, cy - PIN_D / 2)], fill=(120, 120, 130), outline=(60, 60, 70))
for r, xs in ((0, [0]), (1, [-S / 2, S / 2]), (2, [-S, 0, S])):
    for cx in xs: tooth(cx, -r * V)
# (a ball's way: onto the top pin, down its right slope, into the neck, onto the pin below and left)
path = [(0, PIN_D / 2 + BALL / 2 + 0.3), (HW * 0.25, -TH * 0.25 + 3.2), (HW * 0.7, -TH * 0.7 + 3.2), (S / 2, -TH - 2),
        (S / 2, -TOTAL), (S / 2, -V + PIN_D / 2 + BALL / 2 + 0.3)]
path2 = [(S / 2, -V + PIN_D / 2 + BALL / 2 + 0.3), (S / 2 - HW * 0.5, -V - TH * 0.5 + 3.2), (0, -V - TH - 2), (0, -V - TOTAL), (0, -2 * V + PIN_D / 2 + BALL / 2 + 0.3)]
for pts in (path, path2):
    g.line([P(*p) for p in pts], fill=RED, width=3)
for p in (path[0], path[3], path2[0], path2[2]):
    g.ellipse([*P(p[0] - BALL / 2, p[1] + BALL / 2), *P(p[0] + BALL / 2, p[1] - BALL / 2)], outline=RED, width=3)
def note(text, at, to, anchor="lm"):
    g.line([P(*at), P(*to)], fill=BLUE, width=2)
    g.text((P(*to)[0] + (6 if anchor[0] == "l" else -6), P(*to)[1]), text, font=font(20), fill=BLUE, anchor=anchor)
note("a steel pin", (-S / 2, -V + PIN_D / 2), (-S - 8, -V + 8), "rm")
note("its tooth: a wedge\nsloping both ways", (-S / 2 - HW * 0.55, -V - TH * 0.55), (-S - 8, -V - 14), "rm")
note("a neck, 8 mm wide,\n10 mm long", (0, -V - TOTAL + 4), (-S - 8, -V - TOTAL - 2), "rm")
note("the ball rolls down a slope,\ndrops straight down the neck,\nand lands on the next pin:\nleft or right afresh", (S / 2 + 1, -TOTAL - 5), (S / 2 + 8, -TOTAL + 4), "lm")
save(im, "fig-splitter-tooth.png", 520)


# 2. the five walls, worked exactly
def walk(rows, absorb=(), reflect=(), start=0):
    """the chance at each place after each row; and what each absorbing place took, row by row"""
    dist = [{start: 1.0}]
    taken = []
    for r in range(rows):
        nxt, took = {}, {}
        for u, p in dist[-1].items():
            moves = [(u - 1, 0.5), (u + 1, 0.5)]
            if u in reflect: moves = [(u + (1 if u < start else -1), 1.0)]
            for v, q in moves:
                if v in absorb: took[v] = took.get(v, 0) + p * q
                else: nxt[v] = nxt.get(v, 0) + p * q
        dist.append(nxt); taken.append(took)
    return dist, taken
MODES = [("first passage", dict(absorb=(-2,)), "a wall that swallows, 2 places left"),
         ("gambler's ruin", dict(absorb=(-1, 3)), "two walls that swallow, 4 apart"),
         ("a wall that\nsends balls back", dict(reflect=(-3,)), "a reflecting wall, 3 places left"),
         ("the pile goes flat", dict(reflect=(-3, 3)), "reflecting walls, 3 either side"),
         ("no walls", dict(), "the binomial")]
R = 12
cell = 26
panels = []
for title, kw, sub in MODES:
    dist, taken = walk(R, **kw)
    lo, hi = -13, 13
    Wd = int((hi - lo + 1) * cell * 0.5) + 30
    Hd = int((R + 1) * cell) + 120
    im = Image.new("RGB", (Wd, Hd), (255, 255, 255))
    g = ImageDraw.Draw(im)
    def XY(u, r): return (15 + (u - lo) * cell * 0.5, 75 + r * cell)
    g.multiline_text((Wd / 2, 8), title, font=font(19, True), fill=INK, anchor="ma", align="center", spacing=2)
    for w in kw.get("absorb", ()):
        x = XY(w, 0)[0]
        g.line([(x, XY(0, 0)[1] - 10), (x, XY(0, R)[1] + 10)], fill=RED, width=3)
    for w in kw.get("reflect", ()):
        x = XY(w + (-0.6 if w < 0 else 0.6), 0)[0]
        g.line([(x, XY(0, 0)[1] - 10), (x, XY(0, R)[1] + 10)], fill=INK, width=4)
    for r, d in enumerate(dist):
        for u, p in d.items():
            x, y = XY(u, r)
            rad = 11 * math.sqrt(p)
            if rad > 0.6: g.ellipse([x - rad, y - rad, x + rad, y + rad], fill=BLUE)
    for r, took in enumerate(taken, 1):
        for u, p in took.items():
            x, y = XY(u, r)
            rad = 11 * math.sqrt(p)
            if rad > 0.6: g.ellipse([x - rad, y - rad, x + rad, y + rad], fill=RED)
    caught = sum(sum(t.values()) for t in taken)
    line = f"of 150: {150 * caught:.0f} taken, {150 * (1 - caught):.0f} through" if caught > 0 else "of 150: all through"
    g.text((Wd / 2, Hd - 30), line, font=font(16), fill=INK, anchor="mm")
    panels.append(im)
gap = 16
PW, PH = panels[0].size
out = Image.new("RGB", (3 * PW + 2 * gap, 2 * PH + gap), (255, 255, 255))
for i, p in enumerate(panels):
    r, c = divmod(i, 3)
    x = c * (PW + gap) if r == 0 else int((c + 0.5) * (PW + gap))
    out.paste(p, (x, r * (PH + gap)))
save(out, "fig-splitter-walls.png", 1000)

# (the exact counts the text gives, for 150 balls)
for title, kw, sub in MODES:
    dist, taken = walk(R, **kw)
    t = [round(150 * sum(tk.values()), 1) for tk in taken if tk]
    b = sorted(dist[-1].items())
    print(" ", title.replace("\n", " "), "| taken by row:", [round(150 * sum(tk.values()), 1) for tk in taken],
          "| bins:", [(u, round(150 * p, 1)) for u, p in b])

# 3. the board as the simulation ran it (manual/screenshot-splitter.png), its parts named
shot = Image.open(os.path.join(HERE, "screenshot-splitter.png")).convert("RGB")
W, H = shot.size
pad = 260
im = Image.new("RGB", (W + pad, H), (255, 255, 255))
im.paste(shot, (0, 0))
g = ImageDraw.Draw(im)
for text, (px, py), ty in (("the Galton board's hopper,\nwheels and crank", (0.44, 0.15), 0.08),
                           ("twelve rows of splitters", (0.60, 0.40), 0.26),
                           ("the wall: an exit block\nwhere a ball is caught", (0.415, 0.42), 0.40),
                           ("a ramp to its tube", (0.32, 0.47), 0.53),
                           ("a tube for each row\na ball is caught at", (0.25, 0.86), 0.66),
                           ("the bins, for the survivors", (0.52, 0.88), 0.80),
                           ("the sign: caught, the first\ntube, the survivors", (0.85, 0.82), 0.95)):
    x, y = px * W, py * H
    g.line([(x, y), (W + 10, ty * H)], fill=BLUE, width=2)
    g.ellipse([x - 4, y - 4, x + 4, y + 4], fill=BLUE)
    g.multiline_text((W + 16, ty * H), text, font=font(16), fill=BLUE, anchor="lm" if "\n" not in text else "ld", spacing=3)
save(im, "fig-splitter-board.png", 560)
