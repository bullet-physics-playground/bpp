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
P = 30          # (pixels a tooth: the racks' pitch, and the gear's along its pitch circle)
NT = 12         # (the gear's teeth)
MOD = P / math.pi                                     # (the module: teeth 20 degrees, addendum 1, dedendum 1.25)
PA = math.radians(20)
RP = NT * P / (2 * math.pi)                           # (the gear's pitch circle, which rolls on the racks' pitch lines)
def inv(al): return math.tan(al) - al
def gear_outline(cx, cy, turn):
    """an involute gear of NT teeth, turned by turn (radians, clockwise on the page)"""
    rb, ra, rf = RP * math.cos(PA), RP + MOD, RP - 1.25 * MOD
    half = math.pi / (2 * NT) + inv(PA)               # (half a tooth's angle, at the base circle)
    def flank(sign, t0):
        out = []
        for i in range(13):                           # (from the base circle to the tip)
            r = rb + (ra - rb) * i / 12
            psi = half - inv(math.acos(rb / r))
            out.append((r, t0 + sign * psi))
        return out
    pts = []
    for k in range(NT):
        t0 = 2 * math.pi * k / NT
        left = flank(-1, t0)
        right = flank(1, t0)
        pts.append((rf, t0 - half - 0.02))            # (up from the root, radially, to the base circle)
        pts += left
        tl, tr = left[-1][1], right[-1][1]
        pts += [(ra, tl + (tr - tl) * j / 4) for j in range(1, 4)]   # (the tip, an arc)
        pts += right[::-1]
        pts.append((rf, t0 + half + 0.02))
        t1 = t0 + 2 * math.pi / NT                    # (the root, an arc, to the next tooth)
        pts += [(rf, (t0 + half + 0.02) + ((t1 - half - 0.02) - (t0 + half + 0.02)) * j / 4) for j in range(1, 4)]
    return [(cx + r * math.sin(t + turn), cy - r * math.cos(t + turn)) for r, t in pts]
def racks(a, b, title):
    """the racks moved a and b teeth (to the right +), the gear rolled between"""
    c = (a + b) / 2                                   # (the carrier: the gear's centre)
    spin = (a - b) / 2                                # (its turn, in teeth along its pitch circle)
    Wd, Hd = 15 * P, 9 * P
    im = Image.new("RGB", (Wd, Hd + 70), (255, 255, 255))
    g = ImageDraw.Draw(im)
    x0, yc = 4.5 * P, Hd / 2
    def rack(dx, yp, down, col):
        """a rack with its pitch line at yp, its teeth toward the gear: down (A, above) or up (B, below)"""
        s = 1 if down else -1                         # (toward the gear)
        root, tip = yp - s * 1.25 * MOD, yp + s * MOD
        body = root - s * 0.6 * P
        g.rectangle([0, min(root, body), Wd, max(root, body)], fill=col)
        wr = P / 2 + 2 * 1.25 * MOD * math.tan(PA)    # (a tooth's width at its root and at its tip)
        wt = P / 2 - 2 * MOD * math.tan(PA)
        for k in range(-6, 20):
            x = (k + dx) * P                          # (a tooth at each whole pitch; at x0, a gap)
            g.polygon([(x - wr / 2, root), (x + wr / 2, root), (x + wt / 2, tip), (x - wt / 2, tip)], fill=col)
        return body
    top, bot = yc - RP, yc + RP                       # (the racks' pitch lines, touching the gear's pitch circle)
    # (ghost: where the centre was)
    g.line([(x0, top), (x0, bot)], fill=(200, 200, 200), width=2)
    topBody = rack(a, top, True, (201, 160, 106))
    botBody = rack(b, bot, False, (201, 160, 106))
    cx = x0 + c * P
    turn = spin * P / RP                              # (rolled: its pitch circle moves spin teeth)
    g.polygon(gear_outline(cx, yc, turn), fill=(184, 134, 43), outline=(110, 80, 20))
    g.ellipse([cx - 7, yc - 7, cx + 7, yc + 7], fill=(60, 60, 60))
    g.line([(cx + RP * 0.75 * math.sin(turn), yc - RP * 0.75 * math.cos(turn)), (cx, yc)], fill=(90, 60, 15), width=4)   # (a mark on the gear, to see it turn)
    top, bot = topBody, botBody                       # (the arrows and labels go outside the racks)
    def arrow(xa, xb, y, col):
        if abs(xb - xa) < 1: return
        g.line([(xa, y), (xb, y)], fill=col, width=4)
        s = 12 if xb > xa else -12
        g.polygon([(xb, y), (xb - s, y - 7), (xb - s, y + 7)], fill=col)
    arrow(x0, x0 + a * P, top - 16, RED)
    arrow(x0, x0 + b * P, bot + 16, RED)
    arrow(x0, cx, yc, BLUE)
    g.text((Wd - 8, top - 16), f"A: {a:+g}", font=font(20, True), fill=RED, anchor="rm")
    g.text((Wd - 8, bot + 16), f"B: {b:+g}", font=font(20, True), fill=RED, anchor="rm")
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
