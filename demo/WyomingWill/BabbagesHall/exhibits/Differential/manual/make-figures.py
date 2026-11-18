"""The Differential manual's figures (Babbage's Hall).

    python3 manual/make-figures.py      (from the exhibit's folder; Pillow,
                                         OpenSCAD, xvfb-run, ImageMagick)

fig-machine.png and fig-gears.png are OpenSCAD's pictures of the printed
parts, put together as in parts/differential.scad (manual/views.scad), with
labels added. fig-racks.png is the idea drawn flat: a gear between two
racks, its centre at the average of theirs, worked for each case.
fig-exhibit.png is a screenshot of the simulation."""
import math, os, subprocess, tempfile
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
EX = os.path.dirname(HERE)
FONTS = "/usr/share/fonts/truetype/dejavu/"
def font(px, bold=False): return ImageFont.truetype(FONTS + ("DejaVuSans-Bold.ttf" if bold else "DejaVuSans.ttf"), int(px))
INK, BLUE, RED = (30, 30, 30), (30, 70, 170), (200, 30, 26)


def render(view):
    with tempfile.TemporaryDirectory() as d:
        raw, out = os.path.join(d, "raw.png"), os.path.join(d, "out.png")
        subprocess.run(["xvfb-run", "-a", "openscad", "-o", raw, "-D", f'VIEW="{view}"', "--imgsize=2000,1400",
                        "--camera=0,0,0,20,-30,0,0", "--viewall", "--autocenter", "--colorscheme=Tomorrow",
                        os.path.join(HERE, "views.scad")], check=True, capture_output=True)
        subprocess.run(["convert", raw, "-fuzz", "3%", "-trim", "+repage", "-bordercolor", "#f8f8f8", "-border", "30", out], check=True)
        return Image.open(out).convert("RGB")


def labelled(im, labels, pad_l=0, pad_r=0, size=22):
    """labels: (text, (x, y) pointed at, (x, y) of the text, anchor), in the image's pixels"""
    out = Image.new("RGB", (im.width + pad_l + pad_r, im.height), (248, 248, 248))
    out.paste(im, (pad_l, 0))
    g = ImageDraw.Draw(out)
    for text, (px, py), (tx, ty), anchor in labels:
        g.line([(pad_l + px, py), (pad_l + tx, ty)], fill=BLUE, width=2)
        g.ellipse([pad_l + px - 4, py - 4, pad_l + px + 4, py + 4], fill=BLUE)
        g.text((pad_l + tx + (6 if anchor[0] == "l" else -6), ty), text, font=font(size), fill=BLUE, anchor=anchor)
    return out


def save(im, name, width=None):
    if width and im.width != width:
        im = im.resize((width, round(im.height * width / im.width)), Image.LANCZOS)
    im.save(os.path.join(HERE, name), optimize=True)
    print("  manual/" + name, im.size)


# 1. the machine, and its gears alone (the pixel places are this camera's)
im = render("all")
W, H = im.size
save(labelled(im, [
    ("input A's crank", (0.18 * W, 0.24 * H), (0.02 * W, 0.04 * H), "lm"),
    ("A's drum (0-9)", (0.31 * W, 0.33 * H), (0.01 * W, 0.47 * H), "lm"),
    ("the carrier's ring (0-19)", (0.57 * W, 0.09 * H), (0.64 * W, 0.03 * H), "lm"),
    ("B's drum (0-9)", (0.72 * W, 0.42 * H), (0.80 * W, 0.12 * H), "lm"),
    ("the frame, with a pointer at each counter", (0.40 * W, 0.70 * H), (0.46 * W, 0.93 * H), "lm"),
], size=24), "fig-machine.png", 560)

im = render("gears")
W, H = im.size
save(labelled(im, [
    ("side gear A", (0.40 * W, 0.50 * H), (0.12 * W, 0.90 * H), "lm"),
    ("side gear B", (0.62 * W, 0.45 * H), (0.80 * W, 0.90 * H), "lm"),
    ("a spider", (0.55 * W, 0.15 * H), (0.72 * W, 0.06 * H), "lm"),
    ("the cross pin (in the carrier)", (0.525 * W, 0.42 * H), (0.30 * W, 0.06 * H), "rm"),
], pad_l=60, pad_r=100, size=20), "fig-gears.png", 560)


# 2. flat: a gear rolling between two racks (A above, B below); its centre,
#    where the carrier holds it, goes (a + b) / 2
P = 30          # (pixels a tooth)
def racks(a, b, title):
    """the racks moved a and b teeth (to the right +), the gear rolled between"""
    c = (a + b) / 2                                   # (the carrier: the gear's centre)
    spin = (a - b) / 2                                # (its turn, in teeth at its rim)
    Wd, Hd, R = 15 * P, 9 * P, 2.0 * P
    im = Image.new("RGB", (Wd, Hd + 70), (255, 255, 255))
    g = ImageDraw.Draw(im)
    x0, yc = 4.5 * P, Hd / 2
    def rack(dx, y, down, col, name):
        """a rack whose teeth start at y: its body above y and teeth down (down), or below and up"""
        if down: g.rectangle([0, y - 0.6 * P, Wd, y], fill=col)
        else: g.rectangle([0, y, Wd, y + 0.6 * P], fill=col)
        for k in range(-6, 20):
            x = (k + dx) * P
            tip = y + (0.45 * P if down else -0.45 * P)
            g.polygon([(x - 0.3 * P, y), (x + 0.3 * P, y), (x + 0.12 * P, tip), (x - 0.12 * P, tip)], fill=col)
    top, bot = yc - R - 0.45 * P, yc + R + 0.45 * P
    # (ghosts: where everything was)
    g.line([(x0, top - 0.6 * P), (x0, bot + 0.6 * P)], fill=(200, 200, 200), width=2)
    rack(a, top, True, (201, 160, 106), "")
    rack(b, bot, False, (201, 160, 106), "")
    cx = x0 + c * P
    nt = 12
    pts = []
    for k in range(nt * 2):
        ang = math.pi * k / nt + spin * P / R      # (rolled: the rim moves spin teeth)
        r = R + (0.45 * P if k % 2 == 0 else -0.05 * P)
        pts.append((cx + r * math.sin(ang), yc - r * math.cos(ang)))
    g.polygon(pts, fill=(184, 134, 43), outline=(110, 80, 20))
    g.ellipse([cx - 7, yc - 7, cx + 7, yc + 7], fill=(60, 60, 60))
    m = spin * P / R
    g.line([(cx + R * 0.8 * math.sin(m), yc - R * 0.8 * math.cos(m)), (cx, yc)], fill=(90, 60, 15), width=4)   # (a mark on the gear, to see it turn)
    def arrow(xa, xb, y, col):
        if abs(xb - xa) < 1: return
        g.line([(xa, y), (xb, y)], fill=col, width=4)
        s = 12 if xb > xa else -12
        g.polygon([(xb, y), (xb - s, y - 7), (xb - s, y + 7)], fill=col)
    arrow(x0, x0 + a * P, top - 0.6 * P - 16, RED)
    arrow(x0, x0 + b * P, bot + 0.6 * P + 16, RED)
    arrow(x0, cx, yc + R + 0.1 * P - 0.0, BLUE) if False else arrow(x0, cx, yc, BLUE)
    g.text((Wd - 8, top - 0.6 * P - 16), f"A: {a:+g}", font=font(20, True), fill=RED, anchor="rm")
    g.text((Wd - 8, bot + 0.6 * P + 16), f"B: {b:+g}", font=font(20, True), fill=RED, anchor="rm")
    g.text((Wd - 8, yc), f"centre: {c:+g}", font=font(20, True), fill=BLUE, anchor="rm")
    g.text((Wd / 2, Hd + 30), title, font=font(22, True), fill=INK, anchor="mm")
    return im
panels = [racks(4, 0, "A alone: the centre goes half as far"),
          racks(4, 4, "both together: no turning, all as one"),
          racks(4, -4, "opposite ways: the centre stays")]
gap = 30
out = Image.new("RGB", (sum(p.width for p in panels) + gap * 2, panels[0].height), (255, 255, 255))
x = 0
for p in panels: out.paste(p, (x, 0)); x += p.width + gap
save(out, "fig-racks.png", 1200)
