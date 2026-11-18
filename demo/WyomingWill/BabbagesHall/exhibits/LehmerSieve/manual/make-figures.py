"""Lehmer's number sieve manual's figures (Babbage's Hall).

    python3 manual/make-figures.py      (from the exhibit's folder; Pillow,
                                         OpenSCAD, xvfb-run, ImageMagick)

fig-machine.png and fig-geneva.png are OpenSCAD's drawings of the printed
parts (manual/views.scad), the wheels turned to x = 45 and pegged for
N = 1241 by the exhibit's own rule (x mod m open where x*x - N is a square
mod m: openHoles in lehmer-sieve.lua). fig-tour.png is the tour as the
simulation printed it (manual/tour.txt: LS_LOG=1 bpp -f lehmer-sieve.lua).
fig-exhibit.png is a screenshot of the simulation."""
import os, re, subprocess, tempfile
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
FONTS = "/usr/share/fonts/truetype/dejavu/"
def font(px, bold=False): return ImageFont.truetype(FONTS + ("DejaVuSans-Bold.ttf" if bold else "DejaVuSans.ttf"), int(px))
INK, BLUE, GREEN, RED, GREY = (30, 30, 30), (30, 70, 170), (60, 150, 70), (190, 40, 30), (150, 150, 150)
MODS = [9, 8, 7, 5]
N, X = 1241, 45


def pegged(N, m):
    sq = {k * k % m for k in range(m)}
    return [r for r in range(m) if (r * r - N) % m not in sq]
PEGS = "[" + ",".join("[" + ",".join(str(r) for r in pegged(N, m)) + "]" for m in MODS) + "]"


def render(view, camera, size=(1600, 1200), ortho=False):
    with tempfile.TemporaryDirectory() as d:
        raw, out = os.path.join(d, "raw.png"), os.path.join(d, "out.png")
        args = ["xvfb-run", "-a", "openscad", "-o", raw, "-D", f'VIEW="{view}"', "-D", f"X={X}", "-D", "SIGN=-1",
                "-D", f"PEGS={PEGS}", f"--imgsize={size[0]},{size[1]}", f"--camera={camera}", "--viewall", "--autocenter",
                "--colorscheme=Tomorrow", os.path.join(HERE, "views.scad")]
        if ortho: args.insert(-1, "--projection=o")
        subprocess.run(args, check=True, capture_output=True)
        subprocess.run(["convert", raw, "-fuzz", "3%", "-trim", "+repage", "-bordercolor", "#f8f8f8", "-border", "20", out], check=True)
        return Image.open(out).convert("RGB")


def labelled(im, labels, size=24, pad_r=0, pad_l=0):
    out = Image.new("RGB", (im.width + pad_l + pad_r, im.height), (248, 248, 248))
    out.paste(im, (pad_l, 0))
    g = ImageDraw.Draw(out)
    for text, (px, py), (tx, ty), anchor in labels:
        px, py, tx, ty = pad_l + px * im.width, py * im.height, pad_l + tx * im.width, ty * im.height
        g.line([(px, py), (tx, ty)], fill=BLUE, width=3)
        g.ellipse([px - 5, py - 5, px + 5, py + 5], fill=BLUE)
        g.multiline_text((tx + (8 if anchor[0] == "l" else -8 if anchor[0] == "r" else 0), ty), text, font=font(size), fill=BLUE,
                         anchor=anchor, spacing=3)
    return out


def save(im, name, width=None):
    if width and im.width != width:
        im = im.resize((width, round(im.height * width / im.width)), Image.LANCZOS)
    im.save(os.path.join(HERE, name), optimize=True)
    print("  manual/" + name, im.size)


# 1. the machine (the pixel places are this camera's)
im = render("machine", "0,0,0,-25,-35,0,0")
save(labelled(im, [
    ("the probe, in its arm", (0.40, 0.33), (0.10, 0.06), "lm"),
    ("the cam, which lifts it", (0.68, 0.30), (0.56, 0.02), "rm"),
    ("the handle", (0.75, 0.04), (0.82, 0.12), "lm"),
    ("four wheels, 9, 8, 7 and 5\nplaces, the 5 on top", (0.38, 0.64), (0.05, 0.88), "lm"),
    ("the drive: a crank and a\nlocking disc for each wheel", (0.70, 0.58), (0.63, 0.86), "lm"),
    ("a detent", (0.25, 0.58), (0.02, 0.48), "lm"),
], size=26), "fig-machine.png", 600)

# 2. one level from above: the star, its crank and pin, its locking disc
im = render("geneva", "0,0,0,-90,0,0,0", size=(1400, 1000), ortho=True)
save(labelled(im, [
    ("the probe's hole: x mod 9 = 0, open", (0.27, 0.495), (0.02, 0.06), "lm"),
    ("a pegged hole", (0.36, 0.34), (0.32, 0.06), "lm") if False else ("a pegged hole", (0.39, 0.65), (0.10, 0.95), "lm"),
    ("a slot of the star", (0.56, 0.10), (0.65, 0.04), "lm"),
    ("the locking disc", (0.80, 0.62), (0.70, 0.95), "lm"),
], size=24), "fig-geneva.png", 480)

# 3. the tour, as the simulation printed it
rows = []
for l in open(os.path.join(HERE, "tour.txt")):
    m = re.match(r"\s*x = (\d+)\s+(.*)-> the probe through (\d) of 4", l)
    if m:
        cells = re.findall(r"mod (\d): (\d) (open|pegged)", m.group(2))
        rows.append((int(m.group(1)), {int(a): (int(b), c == "open") for a, b, c in cells}, int(m.group(3))))
ORDER = [5, 7, 8, 9]                     # (top to bottom, as the probe meets them)
cw, ch, x0, y0 = 120, 46, 110, 70
im = Image.new("RGB", (x0 + cw * 4 + 300, y0 + ch * len(rows) + 20), (255, 255, 255))
g = ImageDraw.Draw(im)
g.text((x0 / 2, y0 - 30), "x", font=font(24, True), fill=INK, anchor="mm")
for j, m in enumerate(ORDER):
    g.text((x0 + (j + 0.5) * cw, y0 - 30), f"mod {m}", font=font(22, True), fill=INK, anchor="mm")
g.text((x0 + 4 * cw + 125, y0 - 30), "the probe goes through", font=font(20, True), fill=INK, anchor="mm")
for i, (x, cells, depth) in enumerate(rows):
    y = y0 + i * ch
    stop = depth == 4
    if stop: g.rectangle([4, y + 2, im.width - 4, y + ch - 2], outline=(200, 160, 30), width=4)
    g.text((x0 / 2, y + ch / 2), str(x), font=font(24, True), fill=INK, anchor="mm")
    for j, m in enumerate(ORDER):
        r, ok = cells[m]
        xa = x0 + j * cw
        g.rectangle([xa + 8, y + 6, xa + cw - 8, y + ch - 6], fill=GREEN if ok else RED)
        g.text((xa + cw / 2, y + ch / 2), str(r), font=font(22, True), fill=(255, 255, 255), anchor="mm")
    bx = x0 + 4 * cw + 20
    for k in range(4):
        g.rectangle([bx + k * 52, y + 12, bx + k * 52 + 44, y + ch - 12], fill=(70, 70, 70) if k < depth else (225, 225, 225))
save(im, "fig-tour.png", 620)
