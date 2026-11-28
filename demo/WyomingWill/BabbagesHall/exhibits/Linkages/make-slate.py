"""The linkages' pictures, as PNGs in slate/ (Babbage's Hall). Run from
this folder: python3 make-slate.py (Pillow, DejaVu fonts).

The slate behind the board shows three labelled numbers (what is set,
what is read, what it should be) and a line of what the hand is doing:
chalk on slate. Also the board's own printing, at 10 pixels a millimetre
(print it at that size and glue it on): the inverter's scale, the
multiplier's three scales (a along the board, b across it, a x b along the
bridge), and the straight line's rule."""
import os
from PIL import Image, ImageDraw, ImageFont

OUT = "slate"
FONTS = "/usr/share/fonts/truetype/dejavu/"
SLATE, CHALK, DIM, GREEN = (34, 40, 42), (236, 232, 214), (150, 150, 140), (150, 214, 150)
PAPER, INK, RED = (244, 238, 220), (30, 26, 20), (180, 40, 30)
os.makedirs(OUT, exist_ok=True)
bold = lambda n: ImageFont.truetype(FONTS + "DejaVuSerif-Bold.ttf", n)
italic = lambda n: ImageFont.truetype(FONTS + "DejaVuSerif-Italic.ttf", n)
sans = lambda n: ImageFont.truetype(FONTS + "DejaVuSans.ttf", n)
sansb = lambda n: ImageFont.truetype(FONTS + "DejaVuSans-Bold.ttf", n)


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


# the slate: characters, labels, what the hand is doing
for c, name in [(str(k), str(k)) for k in range(10)] + [(".", "dot"), ("−", "minus")]:
    tile(f"ch-{name}", 100, 140, [c], [bold(110)])
    tile(f"ch-{name}-green", 100, 140, [c], [bold(110)], fill=GREEN)
tile("ch-blank", 100, 140, [""], [bold(110)])
for name, text in [("blank", ""), ("x", "P SET AT x ="), ("q", "Q STOPS AT"), ("worked", "100 / x, WORKED OUT"),
                   ("crank", "THE CRANK, DEGREES"), ("off", "THE PEN OFF THE LINE, mm"),
                   ("worst", "AT MOST, SO FAR, mm"),
                   ("a", "THE BRIDGE AT a ="), ("b", "THE b CARRIAGE AT b ="), ("ab", "THE CROSS CARRIAGE READS a × b")]:
    tile(f"label-{name}", 1200, 80, [text], [fit(bold, 50, text, 1160)], align="left")

SAYS = {
    "inverter": {
        "ready": ("Type x, from 5 to 9, and press Return",
                  "the hand sets P at x; Q stops at 100 / x"),
        "setting": ("The hand moves P along the scale",
                    "the rhombus changes shape; OP × OQ stays 100"),
        "reading": ("Reading where Q stops", "its distance from O, on the scale"),
        "done": ("Q stops at 100 / x", "the inverse, by bars and pins alone"),
        "wrong": ("Q is not at 100 / x", "see the console"),
    },
    "line": {
        "ready": ("Return turns the crank across and back",
                  "P goes round a circle through O: watch Q's pen"),
        "turning": ("The hand turns the crank: P goes round its circle",
                    "and Q, its inverse, goes along a straight line"),
        "done": ("A straight line, by bars and pins alone",
                 "Peaucellier, 1864: what Watt's linkage could only come near"),
        "wrong": ("The pen left the line", "see the console"),
    },
    "multiply": {
        "ready": ("Type a (2 to 5), Space, b (−5 to 5), Return",
                  "a = b squares"),
        "setting": ("The hand sets the bridge at a and the carriage at b",
                    "the lever tilts by b; the cross carriage follows it"),
        "reading": ("Reading the cross carriage on the bridge's scale", "its height is a × b"),
        "done": ("The cross carriage stands at a × b",
                 "similar triangles: across at a is a over D times across at D"),
        "wrong": ("The cross carriage is not at a × b", "see the console"),
    },
}
for way, says in SAYS.items():
    for k, (a, b) in says.items():
        tile(f"say-{way}-{k}", 2600, 250, [a, b], [fit(bold, 96, a, 2480), fit(italic, 72, b, 2480)], fill=[CHALK, DIM])

# the board's printing, 10 px a millimetre
PX = 10


def scale(name, w_mm, h_mm, marks, horizontal=True, ticks_left=False):
    """marks: (position mm from the strip's start, label or None, length):
    along the board from its left, across it from its back"""
    W, H = (w_mm * PX, h_mm * PX) if horizontal else (w_mm * PX, h_mm * PX)
    im = Image.new("RGB", (W, H), PAPER)
    d = ImageDraw.Draw(im)
    for pos, lab, ln in marks:
        if horizontal:
            x = pos * PX
            d.line([(x, 0), (x, ln * PX)], fill=INK, width=3 if lab else 2)
            if lab: d.text((x, ln * PX + 4), lab, font=sansb(52), fill=INK, anchor="mt")
        else:
            # (across the board: the strip lies with its top away from you,
            # and a carriage moves toward you for larger numbers, so they
            # go down the strip)
            y = pos * PX
            if ticks_left:
                d.line([(0, y), (ln * PX, y)], fill=INK, width=3 if lab else 2)
                if lab: d.text((ln * PX + 8, y), lab, font=sansb(60), fill=INK, anchor="lm")
            else:
                d.line([(W - ln * PX, y), (W, y)], fill=INK, width=3 if lab else 2)
                if lab: d.text((W - ln * PX - 8, y), lab, font=sansb(52), fill=INK, anchor="rm")
    im.save(f"{OUT}/{name}.png")


# the inverter: a strip 210 mm from O + 40 mm; x from 5 to 9 (input), 11 to 20 (output)
marks = []
for t in range(45, 95):                   # tenths of a cm, 4.5 .. 9.4: every 1 mm
    marks.append(((t - 40) * 1.0, str(t // 10) if t % 10 == 0 else None, 6 if t % 10 == 0 else (4 if t % 5 == 0 else 2.5)))
for t in range(105, 205):
    marks.append(((t - 40) * 1.0, str(t // 10) if t % 10 == 0 else None, 6 if t % 10 == 0 else (4 if t % 5 == 0 else 2.5)))
scale("scale-inverter", 210, 16, marks)
# the multiplier's a: along the board, 148 mm from O + 70 mm; a at 40 a mm from O
marks = []
for t in range(20, 51):                   # a in tenths, 2.0 .. 5.0
    marks.append((t * 4.0 - 70, f"{t // 10}" if t % 10 == 0 else ("½" if t % 10 == 5 else None), 6 if t % 10 == 0 else (4 if t % 5 == 0 else 2.5)))
scale("scale-a", 148, 16, marks)
# its b: across, 86 mm long, b at 7.5 b mm from the axis, -5 .. 5 (the strip's middle the axis)
marks = []
for t in range(-50, 51):
    if t % 5: continue
    marks.append((43 + t * 0.75, (f"{t // 10}" if t >= 0 else f"−{-t // 10}") if t % 10 == 0 else None, 6 if t % 10 == 0 else 3.5))
scale("scale-b", 16, 86, marks, horizontal=False)
# the product: fixed across the board at its right edge, 260 mm, a x b at
# 5 mm a unit, -25 .. 25; the ticks on its left, where the cross carriage's
# index rod comes to them
marks = []
for t in range(-25, 26):
    marks.append((130 + t * 5.0, (f"{t}" if t >= 0 else f"−{-t}") if t % 5 == 0 else None, 6 if t % 5 == 0 else 3))
scale("scale-product", 20, 260, marks, horizontal=False, ticks_left=True)
# the straight line's rule, and its label
im = Image.new("RGB", (8, 2600), RED); im.save(f"{OUT}/rule.png")
tile("label-the-line", 500, 90, ["the straight line"], [italic(56)], fill=RED, bg=PAPER)
print(f"{len(os.listdir(OUT))} files in {OUT}")
