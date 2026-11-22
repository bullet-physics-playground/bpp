"""The bead sort's slate: the pictures it shows, as PNGs in slate/ (Babbage's
Hall). Run from this folder: python3 make-slate.py (Pillow, DejaVu fonts).

The slate behind the frame shows the numbers as they were laid (the first
in the bottom row), the rows as they are now (counted from the beads,
live), and what the hand is doing. The small digits beside the frame's
rows are the same pictures. Chalk on slate."""
import os
from PIL import Image, ImageDraw, ImageFont

OUT = "slate"
FONTS = "/usr/share/fonts/truetype/dejavu/"
SLATE, CHALK, DIM = (34, 40, 42), (236, 232, 214), (150, 150, 140)
GREEN = (150, 214, 150)
os.makedirs(OUT, exist_ok=True)
serif = lambda n: ImageFont.truetype(FONTS + "DejaVuSerif.ttf", n)
bold = lambda n: ImageFont.truetype(FONTS + "DejaVuSerif-Bold.ttf", n)
italic = lambda n: ImageFont.truetype(FONTS + "DejaVuSerif-Italic.ttf", n)


def tile(name, w, h, lines, fonts, fill=CHALK, align="center"):
    im = Image.new("RGB", (w, h), SLATE)
    d = ImageDraw.Draw(im)
    fills = fill if isinstance(fill, list) else [fill] * len(lines)
    n = len(lines)
    for i, (line, f) in enumerate(zip(lines, fonts)):
        y = h * (i + 0.5) / n
        if align == "center": d.text((w / 2, y), line, font=f, fill=fills[i], anchor="mm")
        else: d.text((24, y), line, font=f, fill=fills[i], anchor="lm")
    im.save(f"{OUT}/{name}.png")


for k in range(10):
    tile(f"digit-{k}", 100, 130, [str(k)], [bold(104)])
    tile(f"digit-{k}-green", 100, 130, [str(k)], [bold(104)], fill=GREEN)
tile("digit-blank", 100, 130, [""], [bold(104)])
tile("label-laid", 1500, 80, ["LAID, THE FIRST IN THE BOTTOM ROW"], [bold(42)], align="left")
tile("label-rows", 1500, 80, ["THE ROWS NOW, FROM THE BOTTOM"], [bold(42)], align="left")

# what the hand is doing (two lines: what, and why)
SAYS = {
    "ready": ("Type up to eight numbers, 0 to 9; Return sorts them",
              "each is laid as a row of beads, from the left"),
    "laying": ("Laying the numbers: one row of beads each",
               "a number n is a bead on each of rods 1 to n"),
    "tipping": ("Turning the frame upright",
                "each bead slides down its rod as far as the beads below let it"),
    "settled": ("The beads have settled: read the rows",
                "each row now holds one of the numbers, the largest at the bottom"),
    "sorted": ("Sorted: the rows are the numbers, largest at the bottom",
               "but the colours are mixed: the beads moved, not the numbers"),
    "wrong": ("The rows are not the numbers sorted",
              "a bead has stuck on its rod: see the console"),
    "clearing": ("Laying the frame down and taking the beads off",
                 ""),
}
def fit(make, n, text, w):
    # the largest size up to n at which the text fits w
    while n > 20 and make(n).getlength(text) > w: n -= 2
    return make(n)


for k, (a, b) in SAYS.items():
    tile(f"say-{k}", 2600, 220, [a, b], [fit(bold, 78, a, 2480), fit(italic, 62, b, 2480)],
         fill=[CHALK, DIM])
print(f"{len(os.listdir(OUT))} files in {OUT}")
