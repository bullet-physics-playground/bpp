"""The slate for Napier's bones: the pictures it shows, as PNGs in slate/
(Babbage's Hall). Run from this folder: python3 make-slate.py (Pillow,
DejaVu fonts). As the slide rule's: chalk on slate, swapped in by the
script; numbers are rows of glyphs, each step a picture of two lines. Also
writes slate/says.lua, the steps' words for the script to print."""
import os
from PIL import Image, ImageDraw, ImageFont

OUT = "slate"
FONTS = "/usr/share/fonts/truetype/dejavu/"
SLATE, CHALK, DIM = (34, 40, 42), (236, 232, 214), (150, 150, 140)
os.makedirs(OUT, exist_ok=True)
serif = lambda n: ImageFont.truetype(FONTS + "DejaVuSerif.ttf", n)
bold = lambda n: ImageFont.truetype(FONTS + "DejaVuSerif-Bold.ttf", n)


def tile(name, w, h, lines, fonts, fill=CHALK, align="center"):
    im = Image.new("RGB", (w, h), SLATE)
    d = ImageDraw.Draw(im)
    n = len(lines)
    for i, (line, f) in enumerate(zip(lines, fonts)):
        y = h * (i + 0.5) / n
        if align == "center": d.text((w / 2, y), line, font=f, fill=fill, anchor="mm")
        else: d.text((20, y), line, font=f, fill=fill, anchor="lm")
    im.quantize(colors=8).save(f"{OUT}/{name}.png", optimize=True)


# the glyphs: wide ones 85 x 130 px, narrow ones 45 x 130 (the script draws
# them 0.85 and 0.45 cm wide)
for k in range(10):
    tile(f"g-{k}", 85, 130, [str(k)], [bold(100)])
for name, ch in {"times": "×", "plus": "+", "eq": "="}.items():
    tile(f"g-{name}", 85, 130, [ch], [bold(96)])
for name, ch in {"slash": "/", "blank": "", "point": "."}.items():
    tile(f"g-{name}", 45, 130, [ch], [bold(90)])

# the labels at the rows' left
LABELS = [("napier", "NAPIER'S BONES"), ("genaille", "GENAILLE'S RODS"), ("none", ""),
          ("diagonals", "along the diagonals"), ("triangles", "the triangles lead to"),
          ("gives", "so the row gives"), ("total", "added up")]
LABELS += [(f"row{k}", f"row {k} reads") for k in range(1, 10)]
for key, text in LABELS:
    tile(f"label-{key}", 460, 80, [text], [bold(42) if text.isupper() else serif(42)], align="left",
         fill=CHALK if text.isupper() else DIM)

SAYS = [
    ("lay", "The rods for the number, laid on the board", "each turned to show its digit, the first beside the index"),
    ("row", "Read the row beside the index's digit", "each rod's cell: its tens above the diagonal, its units below"),
    ("diag", "Add along each diagonal, from the right", "a units digit and the next rod's tens; carry any ten left"),
    ("next", "The multiplier's next digit: its row", "a place further left than the row before"),
    ("add", "Add the rows up", "each row moved a place left of the one after it"),
    ("grow", "The row's top number on the last rod", "the carry into the last place is always 0"),
    ("gfollow", "Follow each triangle to the next rod", "it points at the number the carry selects; no adding"),
    ("gone", "Times 1: the number itself", "Genaille's rods have no row for 1"),
    ("clear", "The rods back in their tray", "turned back to their first faces"),
    ("cannot", "The set can't lay this number", "it needs one digit on more rods than carry it"),
]
lua = ["-- the slate's steps, in words (made by make-slate.py)", "return {"]
for key, l1, l2 in SAYS:
    tile(f"say-{key}", 1600, 160, [l1, l2], [bold(56), serif(46)])
    lua.append(f'  ["{key}"] = {{ "{l1}", "{l2}" }},')
for way in ("napier", "genaille"):
    tile(f"say-ready-{way}", 1600, 160, ["Type a number, X, a multiplier, and Return",
                                         "C clears the board; M, close to the rods; T, the tour"],
         [serif(52), serif(44)], fill=DIM)
tile("say-right", 1600, 160, ["Right", "the product, as plain arithmetic has it"], [bold(56), serif(46)])
tile("say-wrong", 1600, 160, ["Not right", "the rods as they lie give another number (the console has both)"],
     [bold(56), serif(46)])
lua.append("}")
open(f"{OUT}/says.lua", "w").write("\n".join(lua) + "\n")
print(len(os.listdir(OUT)), "files in", OUT)
