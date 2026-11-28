"""The linkages that write's pictures, as PNGs in slate/ (Babbage's Hall).
Run from this folder: python3 make-slate.py (Pillow, DejaVu fonts).

The slate behind the board: the letter, the slider's position, how many
pens and bars the letter took, and how close its worst pen came; and a
line of what is happening. Chalk on slate."""
import os
from PIL import Image, ImageDraw, ImageFont

OUT = "slate"
FONTS = "/usr/share/fonts/truetype/dejavu/"
SLATE, CHALK, DIM, GREEN, RED = (34, 40, 42), (236, 232, 214), (150, 150, 140), (150, 214, 150), (230, 120, 100)
os.makedirs(OUT, exist_ok=True)
bold = lambda n: ImageFont.truetype(FONTS + "DejaVuSerif-Bold.ttf", n)
italic = lambda n: ImageFont.truetype(FONTS + "DejaVuSerif-Italic.ttf", n)


def tile(name, w, h, lines, fonts, fill=CHALK, align="center", bg=SLATE):
    im = Image.new("RGB", (w, h), bg)
    d = ImageDraw.Draw(im)
    fills = fill if isinstance(fill, list) else [fill] * len(lines)
    for i, (line, f) in enumerate(zip(lines, fonts)):
        y = h * (i + 0.5) / len(lines)
        if align == "center": d.text((w / 2, y), line, font=f, fill=fills[i], anchor="mm")
        else: d.text((20, y), line, font=f, fill=fills[i], anchor="lm")
    im.save(f"{OUT}/{name}.png")


def fit(make, n, text, w):
    while n > 18 and make(n).getlength(text) > w: n -= 2
    return make(n)


chars = [(str(k), str(k)) for k in range(10)] + [(".", "dot"), ("%", "pct")] + [(chr(65 + i), chr(65 + i)) for i in range(26)]
for c, name in chars:
    tile(f"ch-{name}", 100, 140, [c], [bold(110)])
    tile(f"ch-{name}-green", 100, 140, [c], [bold(110)], fill=GREEN)
tile("ch-blank", 100, 140, [""], [bold(110)])
for name, text in [("blank", ""), ("letter", "THE LETTER"), ("pens", "PENS, EACH ITS OWN LINKAGE"),
                   ("bars", "BARS, ALL TOLD"), ("worst", "THE WORST PEN, % OF THE LETTER'S HEIGHT")]:
    tile(f"label-{name}", 1200, 80, [text], [fit(bold, 50, text, 1160)], align="left")
for name, text in [("sloppy", "SLOPPY: every pen within 8%"), ("ok", "OK: every pen within 4%"),
                   ("good", "VERY GOOD: every pen within 2%")]:
    tile(f"level-{name}", 1200, 90, [text], [fit(italic, 60, text, 1160)], fill=GREEN)

SAYS = {
    "ready": ("Type a letter", "1, 2, 3: sloppy, ok, very good; Space draws it again"),
    "building": ("The linkages for the letter go on the board",
                 "each pen its own linkage, found in advance by a search"),
    "drawing": ("One crank turns once", "the other cranks are geared to it; every pen draws its stroke"),
    "done": ("Drawn by bars and pins alone", "a better letter takes more bars, and more pens"),
    "wrong": ("A pen strayed from its stroke", "see the console"),
}
for k, (a, b) in SAYS.items():
    tile(f"say-{k}", 2600, 250, [a, b], [fit(bold, 96, a, 2480), fit(italic, 72, b, 2480)], fill=[CHALK, DIM])
print(f"{len(os.listdir(OUT))} files in {OUT}")
