"""The slide rule's slate: the pictures it shows, as PNGs in slate/ (Babbage's
Hall). Run from this folder: python3 make-slate.py (Pillow, DejaVu fonts).

As the suanpan's: chalk on slate, each picture swapped in by the script.
The problem and the numbers are rows of glyphs (a digit, a point, a sign);
each step of working the rule is a picture of its own, two lines. Also
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
        else: d.text((24, y), line, font=f, fill=fill, anchor="lm")
    im.quantize(colors=8).save(f"{OUT}/{name}.png", optimize=True)


# the glyphs: one character of the slate's text each (rule.lua's codes)
GLYPHS = {str(k): str(k) for k in range(10)}
GLYPHS.update({"point": ".", "times": "×", "div": "÷", "eq": "=", "approx": "≈",
               "sq": "²", "cube": "³", "root": "√", "slash": "/", "minus": "−",
               "blank": ""})
for name, ch in GLYPHS.items():
    if name in ("sq", "cube"):          # (narrow, raised: 60 px; the script draws them narrow)
        im = Image.new("RGB", (60, 130), SLATE)
        ImageDraw.Draw(im).text((30, 38), ch, font=bold(110), fill=CHALK, anchor="mm")
        im.quantize(colors=8).save(f"{OUT}/g-{name}.png", optimize=True)
    elif name == "point":
        tile(f"g-{name}", 60, 130, [ch], [bold(104)])
    else:
        tile(f"g-{name}", 100, 130, [ch], [bold(104)])
tile("g-log", 100, 130, ["log"], [bold(50)])

# the labels at the rows' left
for key, text in [("multiply", "MULTIPLYING"), ("divide", "DIVIDING"), ("table", "A TABLE"),
                  ("square", "SQUARING"), ("root", "SQUARE ROOT"), ("cube", "CUBING"),
                  ("recip", "RECIPROCAL"), ("log", "LOGARITHM"), ("none", ""),
                  ("reads", "the rule reads"), ("answer", "so the answer is")]:
    tile(f"label-{key}", 460, 80, [text], [bold(44) if text.isupper() else serif(44)], align="left",
         fill=CHALK if text.isupper() else DIM)

tile("label-about", 200, 80, ["about"], [serif(44)], align="left", fill=DIM)
tile("label-about-none", 200, 80, [""], [serif(44)])

# the steps of working the rule
SAYS = [
    ("m1", "1. The cursor to the first number on D", "its hairline over it"),
    ("m2", "2. The slide: C's 1 under the hairline", "its left index over the first number"),
    ("m2r", "2. The slide: C's 10 under the hairline", "from the 1, the second number would run off the end"),
    ("m3", "3. The cursor to the second number on C", "the slide stays where it is"),
    ("m4", "4. Read the product on D, under the hairline", "the rule gives the figures; an estimate the point"),
    ("mt", "The cursor to the next number on C", "the slide stays: at one setting, a whole table"),
    ("d1", "1. The cursor to the dividend on D", "its hairline over it"),
    ("d2", "2. The slide: the divisor on C under the hairline", "the two numbers face each other"),
    ("d3", "3. The cursor to C's 1", "the slide's left index"),
    ("d3r", "3. The cursor to C's 10", "the slide's right index: its 1 is off the rule"),
    ("d4", "4. Read the quotient on D, under the hairline", "the rule gives the figures; an estimate the point"),
    ("close", "The slide closed", "C over D again: the scales on the stock line up"),
    ("s1", "1. The cursor to the number on D", "its hairline over it"),
    ("s2", "2. Read its square on A, under the hairline", "A has two halves: 1 to 10, then 10 to 100"),
    ("r1a", "1. The cursor to the number on A's left half", "an odd number of figures before the point"),
    ("r1b", "1. The cursor to the number on A's right half", "an even number of figures before the point"),
    ("r2", "2. Read the square root on D, under the hairline", "D's 1 to 10 is A's 1 to 100"),
    ("k1", "1. The cursor to the number on D", "its hairline over it"),
    ("k2", "2. Read its cube on K, under the hairline", "K has three thirds: to 10, to 100, to 1000"),
    ("i1", "1. The cursor to the number on C", "with the slide closed, D shows it too"),
    ("i2", "2. Read its reciprocal on CI", "CI, in red, is C backward"),
    ("l1", "1. The cursor to the number on D", "its hairline over it"),
    ("l2", "2. Read the logarithm's figures on L", "the whole number before them: where the point is"),
]
lua = ["-- the slate's steps, in words (made by make-slate.py)", "return {"]
for key, l1, l2 in SAYS:
    tile(f"say-{key}", 1600, 160, [l1, l2], [bold(56), serif(46)])
    lua.append(f'  ["{key}"] = {{ "{l1}", "{l2}" }},')
tile("say-none", 1600, 160, ["", ""], [bold(56), serif(46)])
tile("say-ready-multiply", 1600, 160, ["Type 2.5 X 3.2, or 7.5 / 2.5", "Enter works it; C closes the rule; T, the tour"],
     [serif(52), serif(44)], fill=DIM)
tile("say-ready-powers", 1600, 160, ["Type a number, then S, R, K, I or L",
                                     "square, root, cube, reciprocal, log; T, the tour"],
     [serif(52), serif(44)], fill=DIM)
tile("say-right", 1600, 160, ["Right, to the figures read", "the true answer, to as many figures as the rule gives"], [bold(56), serif(46)])
tile("say-wrong", 1600, 160, ["Not right: the true answer differs", "in a figure read (the console has both)"], [bold(56), serif(46)])
lua.append("}")
open(f"{OUT}/says.lua", "w").write("\n".join(lua) + "\n")
print(len(os.listdir(OUT)), "files in", OUT)
