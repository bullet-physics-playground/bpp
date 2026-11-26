"""The slide adder's pictures, as PNGs in slate/ (Babbage's Hall). Run from
this folder: python3 make-slate.py (Pillow, DejaVu fonts).

The slate beside the adder shows what the windows read (read from the
bands, live), the number being added or subtracted (or typed), and what
the hand is doing: chalk on slate. Also the adder's own printing: the
digits on each band (0 at the bottom, a step apart), the labels beside
each slot (the digits to add, going up, on the right; the digits to
subtract, going down, on the left, in red), and the lines over the slots
and under the windows. Those are printed on paper and glued on (README)."""
import os
from PIL import Image, ImageDraw, ImageFont

OUT = "slate"
FONTS = "/usr/share/fonts/truetype/dejavu/"
SLATE, CHALK, DIM = (34, 40, 42), (236, 232, 214), (150, 150, 140)
GREEN = (150, 214, 150)
COVER, INK, RED = (47, 58, 64), (236, 232, 214), (232, 96, 80)
os.makedirs(OUT, exist_ok=True)
bold = lambda n: ImageFont.truetype(FONTS + "DejaVuSerif-Bold.ttf", n)
italic = lambda n: ImageFont.truetype(FONTS + "DejaVuSerif-Italic.ttf", n)
sans = lambda n: ImageFont.truetype(FONTS + "DejaVuSans-Bold.ttf", n)


def tile(name, w, h, lines, fonts, fill=CHALK, align="center", bg=SLATE):
    im = Image.new("RGB", (w, h), bg)
    d = ImageDraw.Draw(im)
    fills = fill if isinstance(fill, list) else [fill] * len(lines)
    n = len(lines)
    for i, (line, f) in enumerate(zip(lines, fonts)):
        y = h * (i + 0.5) / n
        if align == "center": d.text((w / 2, y), line, font=f, fill=fills[i], anchor="mm")
        else: d.text((24, y), line, font=f, fill=fills[i], anchor="lm")
    im.save(f"{OUT}/{name}.png")


def fit(make, n, text, w):
    # the largest size up to n at which the text fits w
    while n > 20 and make(n).getlength(text) > w: n -= 2
    return make(n)


# the slate
for k in range(10):
    tile(f"digit-{k}", 100, 130, [str(k)], [bold(104)])
    tile(f"digit-{k}-green", 100, 130, [str(k)], [bold(104)], fill=GREEN)
tile("digit-blank", 100, 130, [""], [bold(104)])
tile("digit-plus", 100, 130, ["+"], [bold(104)])
tile("digit-minus", 100, 130, ["−"], [bold(104)])
for name, text in [("register", "THE WINDOWS READ"), ("typed", "TYPED"),
                   ("adding", "ADDING"), ("subtracting", "SUBTRACTING")]:
    tile(f"label-{name}", 1400, 75, [text], [bold(44)], align="left")

SAYS = {
    "ready": ("Type a number; Return puts it on the adder",
              "+ adds it, − subtracts it, C puts every band to 0"),
    "zeroing": ("The bar lifts every band to 0",
                "its tab is at the right; then it goes down again"),
    "entering": ("Putting the first number on, by adding it",
                 "the adder subtracts from what its windows read"),
    "adding": ("Down from the digit to the bottom of the slot",
               "the band goes down that many steps: its window shows that many more"),
    "carry": ("The gap is red: up to the top, over the hook, one step down",
              "up 10 − d steps shows d more, less ten; the step down carries the ten"),
    "chain": ("The next column shows 9: the stylus won't go down",
              "so add one there, from its 1 up to the top, and carry again"),
    "full": ("No column to carry into: the adder is full",
             "the sum has more figures than it has columns"),
    "subtracting": ("Up from the digit on the left to the top of the slot",
                    "the band goes up that many steps: its window shows that many fewer"),
    "borrow": ("The gap isn't red: down to the bottom, along, one step up",
               "down 10 − d steps shows d fewer, plus ten; the step up borrows the ten"),
    "chain-borrow": ("The next column shows 0: the stylus won't go up",
                     "so take one there, from its 1 down to the bottom, and borrow again"),
    "negative": ("No column to borrow from: less than nothing",
                 "the windows show 1000000 less the answer"),
    "done": ("Done: the windows read the answer",
             "each column carried (or borrowed) by the hook, by hand"),
    "negative-done": ("Done, less than nothing: the windows show its complement",
                      "1000000 less the answer, as an Addiator does"),
    "wrong": ("The windows don't read the answer",
              "see the console"),
}
for k, (a, b) in SAYS.items():
    tile(f"say-{k}", 2600, 340, [a, b], [fit(bold, 92, a, 2480), fit(italic, 72, b, 2480)], fill=[CHALK, DIM])

# the adder's own printing: 40 px a millimetre's... (10 px a mm)
PX = 10                                  # pixels a millimetre
STEP = 8 * PX                            # a step


def strip(name, w_mm, digits, colour, bg, size):
    # digits[i] at the i-th step from the bottom (the strip is 10 steps tall
    # for the bands, 9 for the labels)
    n = len(digits)
    im = Image.new("RGB", (w_mm * PX, n * STEP), bg)
    d = ImageDraw.Draw(im)
    for i, t in enumerate(digits):
        y = (n - i - 0.5) * STEP
        d.text((w_mm * PX / 2, y), t, font=sans(size), fill=colour, anchor="mm")
    im.save(f"{OUT}/{name}.png")


strip("band-digits", 9, [str(k) for k in range(10)], (30, 30, 30), (232, 220, 192), 62)
strip("labels-add", 5, [str(k) for k in range(1, 10)], INK, COVER, 40)
strip("labels-sub", 5, [str(k) for k in range(9, 0, -1)], RED, COVER, 40)
TOP = "← CARRY ALONG THE TOP     ADD: DOWN ↓     SUBTRACT: UP ↑     BORROW ALONG THE BOTTOM ←"
tile("cover-top", 1240, 70, [TOP], [fit(sans, 30, TOP, 1200)], fill=INK, bg=COVER)
for j, t in enumerate(["1s", "10s", "100s", "1000s", "10 000s", "100 000s"], 1):
    tile(f"window-{j}", 160, 40, [t], [fit(sans, 26, t, 152)], fill=INK, bg=COVER)
print(f"{len(os.listdir(OUT))} files in {OUT}")
