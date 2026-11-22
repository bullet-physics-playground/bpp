"""The Pascaline manual's figures (Babbage's Hall).

    python3 manual/make-figures.py      (from the exhibit's folder; Pillow,
                                         OpenSCAD, xvfb-run, ImageMagick)

Every picture is OpenSCAD's drawing of the printed parts, put together as in
parts/pascaline.scad (manual/views.scad) and set to a state. The works are
set to the angles the simulation reported for the sautoirs and pawls at the
end of each step of its tour (PA_DEBUG=1), kept below. fig-exhibit.png is a
screenshot of the simulation."""
import os, subprocess, tempfile
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
FONTS = "/usr/share/fonts/truetype/dejavu/"
def font(px, bold=False): return ImageFont.truetype(FONTS + ("DejaVuSans-Bold.ttf" if bold else "DejaVuSans.ttf"), int(px))
INK, BLUE = (30, 30, 30), (30, 70, 170)
STEP, STOP_A = 36, 126                     # (as pascaline-geometry.lua)

# the tour's states, as the simulation reported them (PA_DEBUG=1):
#   digits (h t u), sautoir0, pawl0, sautoir1, pawl1
TOUR = {"007": ([0, 0, 7], [6.9, -0.1], [-18.9, 0.0]),
        "015": ([0, 1, 15], [4.9, 0.9], [-23.8, 0.0]),
        "099": ([0, 8.98, 19], [8.9, 8.9], [0.0, 0.0]),
        "100": ([1, 10, 20], [-0.1, -0.1], [0.0, -19.1])}


def render(view, v, lev=(0, 0), pawl=(0, 0), sty=(-1, 0), camera="-130,10,0,0,0,0,600", size=(1800, 900), trim=True):
    with tempfile.TemporaryDirectory() as d:
        raw, out = os.path.join(d, "raw.png"), os.path.join(d, "out.png")
        args = ["xvfb-run", "-a", "openscad", "-o", raw, "-D", f'VIEW="{view}"', "-D", f"V=[{v[0]},{v[1]},{v[2]}]",
                "-D", f"LEV=[{lev[0]},{lev[1]}]", "-D", f"PAWL=[{pawl[0]},{pawl[1]}]", "-D", f"STY=[{sty[0]},{sty[1]}]",
                f"--imgsize={size[0]},{size[1]}", f"--camera={camera}", "--colorscheme=Tomorrow", os.path.join(HERE, "views.scad")]
        subprocess.run(args, check=True, capture_output=True)
        if trim: subprocess.run(["convert", raw, "-fuzz", "3%", "-trim", "+repage", "-bordercolor", "#f8f8f8", "-border", "20", out], check=True)
        else: subprocess.run(["cp", raw, out], check=True)
        return Image.open(out).convert("RGB")


def caption(im, text, size=40):
    out = Image.new("RGB", (im.width, im.height + int(size * 1.9)), (255, 255, 255))
    out.paste(im, (0, 0))
    ImageDraw.Draw(out).text((im.width / 2, im.height + size * 0.4), text, font=font(size, True), fill=INK, anchor="ma")
    return out


def labelled(im, labels, size=24, pad_r=0, pad_b=0):
    out = Image.new("RGB", (im.width + pad_r, im.height + pad_b), (248, 248, 248))
    out.paste(im, (0, 0))
    g = ImageDraw.Draw(out)
    for text, (px, py), (tx, ty), anchor in labels:
        g.line([(px, py), (tx, ty)], fill=BLUE, width=3)
        g.ellipse([px - 5, py - 5, px + 5, py + 5], fill=BLUE)
        g.text((tx + (8 if anchor[0] == "l" else -8 if anchor[0] == "r" else 0), ty), text, font=font(size), fill=BLUE, anchor=anchor)
    return out


def row(ims, gap=24):
    H = max(i.height for i in ims)
    out = Image.new("RGB", (sum(i.width for i in ims) + gap * (len(ims) - 1), H), (255, 255, 255))
    x = 0
    for i in ims: out.paste(i, (x, (H - i.height) // 2)); x += i.width + gap
    return out


def save(im, name, width=None):
    if width and im.width != width:
        im = im.resize((width, round(im.height * width / im.width)), Image.LANCZOS)
    im.save(os.path.join(HERE, name), optimize=True)
    print("  manual/" + name, im.size)


# 1. the front, at 000 (straight on; the box is this camera's)
im = render("front", [0, 0, 0], trim=False)
im = im.crop((60, 200, 1800, 860))
W, H = im.size
save(labelled(im, [
    ("a hole for the stylus", (0.729 * W, 0.245 * H), (0.22 * W, 1.10 * H), "mm"),
    ("the pointer", (0.771 * W, 0.13 * H), (0.45 * W, 1.20 * H), "mm"),
    ("the dial's numbers", (0.824 * W, 0.29 * H), (0.62 * W, 1.10 * H), "mm"),
    ("the finger stop", (0.855 * W, 0.71 * H), (0.80 * W, 1.20 * H), "mm"),
    ("the plate's numbers", (0.885 * W, 0.49 * H), (0.99 * W, 1.10 * H), "rm"),
], size=30, pad_b=int(0.26 * H)), "fig-front.png", 620)

# 2. adding 7 to the units when they show 5: the stylus in the hole by the
#    plate's 7, then turned clockwise to the stop: 12, the tens carried
cam = "-55,10,0,0,0,0,330"
a = render("front", [0, 0, 5], sty=(0, STOP_A - 7 * STEP), camera=cam, size=(1300, 800))
b = render("front", [0, 1, 12], sty=(0, STOP_A), camera=cam, size=(1300, 800))
save(row([caption(a, "05: the stylus in the hole by the plate's 7"),
          caption(b, "turned to the stop: 12, the tens carried")]), "fig-stylus.png", 1200)

# 3. the works, at three steps of the tour
ims = []
for key, text in (("007", "007: the units' cam has lifted the sautoir"),
                  ("099", "099: both sautoirs lifted, near the top"),
                  ("100", "100: both dropped; each kicked the next digit on")):
    v, lev, pawl = TOUR[key]
    ims.append(caption(render("works", v, lev, pawl, camera="-140,5,0,12,0,0,520", size=(1800, 800)), text, 30))
W, H = ims[0].size
ims[0] = labelled(ims[0], [
    ("a sautoir", (0.468 * W, 0.40 * H), (0.30 * W, 0.08 * H), "mm"),
    ("its pawl", (0.677 * W, 0.19 * H), (0.55 * W, 0.05 * H), "mm"),
    ("the units' snail cam", (0.774 * W, 0.24 * H), (0.98 * W, 0.05 * H), "rm"),
    ("a wheel of ten pins", (0.903 * W, 0.56 * H), (0.98 * W, 0.80 * H), "rm"),
], size=28)
out = Image.new("RGB", (max(i.width for i in ims), sum(i.height for i in ims) + 30 * 2), (255, 255, 255))
y = 0
for i in ims: out.paste(i, ((out.width - i.width) // 2, y)); y += i.height + 30
save(out, "fig-works.png", 620)
