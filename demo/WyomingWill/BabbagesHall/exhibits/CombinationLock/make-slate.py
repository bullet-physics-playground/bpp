"""The combination lock's slate: the pictures it shows, as PNGs in slate/
(Babbage's Hall). Run from this folder: python3 make-slate.py (Pillow,
DejaVu fonts).

As the slide rule's: chalk on slate, each picture swapped in by the script.
The combinations, the dial's reading and the gates' places are rows of
glyphs; each step is a picture of its own, two lines. Also writes
slate/says.lua, the steps' words for the script to print."""
import os
from PIL import Image, ImageDraw, ImageFont

OUT = "slate"
FONTS = "/usr/share/fonts/truetype/dejavu/"
SLATE, CHALK, DIM = (34, 40, 42), (236, 232, 214), (150, 150, 140)
GREEN, RED = (150, 214, 150), (236, 140, 120)
os.makedirs(OUT, exist_ok=True)
serif = lambda n: ImageFont.truetype(FONTS + "DejaVuSerif.ttf", n)
bold = lambda n: ImageFont.truetype(FONTS + "DejaVuSerif-Bold.ttf", n)


def fit(d, line, f, w):
    """the font, made smaller until the line fits the tile's width"""
    while f.size > 20 and d.textlength(line, font=f) > w:
        f = ImageFont.truetype(f.path, f.size - 2)
    return f


def tile(name, w, h, lines, fonts, fill=CHALK, align="center", shrink=True):
    im = Image.new("RGB", (w, h), SLATE)
    d = ImageDraw.Draw(im)
    n = len(lines)
    fills = fill if isinstance(fill, list) else [fill] * n
    for i, (line, f) in enumerate(zip(lines, fonts)):
        if shrink: f = fit(d, line, f, w - 60)
        y = h * (i + 0.5) / n
        if align == "center": d.text((w / 2, y), line, font=f, fill=fills[i], anchor="mm")
        else: d.text((20, y), line, font=f, fill=fills[i], anchor="lm")
    im.quantize(colors=8).save(f"{OUT}/{name}.png", optimize=True)


# the glyphs (85 x 110 px; the point 45 wide): the script's codes
GLYPHS = {str(k): str(k) for k in range(10)}
GLYPHS.update({"dash": "–", "plus": "+", "minus": "−", "point": ".", "blank": "", "under": "_", "q": "?"})
for name, ch in GLYPHS.items():
    tile(f"g-{name}", 45 if name == "point" else 85, 110, [ch], [bold(88)],
         fill=DIM if name == "under" else CHALK, shrink=False)

# the labels at the rows' left
for key, text in [("set", "SET TO"), ("try", "TRYING"), ("dial", "DIAL"), ("found", "FOUND"),
                  ("low", "LOW"), ("high", "HIGH"), ("gap", "GAP")]:
    tile(f"label-{key}", 560, 110, [text], [bold(64)], align="left")
tile("label-gates", 1600, 110, ["the gates, from under the fence (numbers):"], [serif(58)], fill=DIM, align="left")
for i in (1, 2, 3):
    tile(f"label-wheel{i}", 260, 110, [f"wheel {i}"], [serif(54)], fill=DIM, align="left")
tile("foot", 3200, 100, ["Turning left brings higher numbers to the index. Each wheel's gate is the notch with the red line."],
     [serif(52)], fill=DIM)

# the safecracker's graph: its title, and its axis (0 to 100 across 2050 px)
tile("label-graph", 2050, 80, ["the gap between the contact points, the wheels parked on each number"], [serif(46)], fill=DIM)
im = Image.new("RGB", (2050, 70), SLATE)
d = ImageDraw.Draw(im)
d.line([(0, 6), (2049, 6)], fill=DIM, width=3)
for n in range(0, 101, 5):
    x = min(2048, int(n / 100 * 2049))
    d.line([(x, 6), (x, 22 if n % 25 else 30)], fill=DIM, width=3)
    if n % 25 == 0:
        d.text((min(max(x, 30), 2020), 50), str(n), font=serif(34), fill=DIM, anchor="mm")
im.quantize(colors=8).save(f"{OUT}/axis.png", optimize=True)

# the lock's state
tile("state-locked", 1100, 260, ["LOCKED", "the bolt is out"], [bold(110), serif(56)], fill=[RED, DIM])
tile("state-open", 1100, 260, ["OPEN", "the bolt is drawn back"], [bold(110), serif(56)], fill=[GREEN, DIM])
tile("state-moving", 1100, 260, ["...", "the bolt is moving"], [bold(110), serif(56)], fill=[CHALK, DIM])

# the steps
SAYS = [
    ("left4", "1. Left, passing the first number three times; stop on it the fourth",
     "the cam picks up all three wheels; wheel 1, at the back, is left there"),
    ("right3", "2. Right, passing the second number twice; stop on it the third",
     "wheel 1 stays where it is; wheels 3 and 2 come round, and 2 is left there"),
    ("left2", "3. Left, passing the third number once; stop on it the second",
     "wheels 1 and 2 stay; wheel 3 is left on the third number"),
    ("open", "4. Right, until the dial stops",
     "the cam's notch comes round under the fence"),
    ("opened", "The fence fell into the gates: the bolt is drawn back",
     "every gate was under it, and the cam's notch caught it and pulled"),
    ("locked", "The dial turns on: the bolt stays out",
     "a wheel's rim holds the fence up, out of the cam's notch"),
    ("close", "Left, two turns: the bolt thrown, the wheels scrambled",
     "the cam pushes the fence back, then lifts it out of the gates"),
    ("t-own", "The lock's own combination",
     "watch each wheel's gate come round under the fence and stay"),
    ("t-wrong", "The last number five off",
     "wheel 3's gate will stop five numbers from the fence"),
    ("t-near", "Every number one off",
     "a gate one number from the fence still lets it fall"),
    ("warn-12", "The second number is too close above the first",
     "wheel 2, setting it, will come round to wheel 1 and carry it off"),
    ("warn-23", "The third number is too close below the second",
     "wheel 3, setting it, will come round to wheel 2 and carry it off"),
    ("warn-zone", "The last number is in the forbidden zone (90 to 99)",
     "turning right, the cam will carry wheel 3 off before it can draw the bolt"),
    # the safecracker's way
    ("s-intro", "The safecracker's way: the lock is set to a combination we aren't told",
     "the wheels aren't quite alike, and the dial tells which one holds the fence up"),
    ("s-graph1", "1. Park all three wheels together on each number, and feel the contact points",
     "left to the number; right to the notch; then gently, each way, until the dial stops"),
    ("s-fine1", "Narrower at one number: find its two edges, a half number at a time",
     "a gate under the wheel that held the fence up: it drops a hair onto the next"),
    ("s-graph2", "2. Leave wheel 1 there; park wheels 2 and 3 together, number by number",
     "turning right, from just below wheel 1's number round to just above it"),
    ("s-fine2", "Narrower again: find its two edges",
     "wheel 2's gate: the fence drops onto wheel 3, the smallest"),
    ("s-last", "3. The last wheel: try every second number, turning right to open",
     "a number one off still opens it"),
    ("s-opened", "Open: the combination read off the lock, never told",
     "the wheels' small differences leaked it; locks since are made to leak less"),
    ("s-nodip", "No narrowing to be felt", "the wheels too nearly alike: the safecracker gives up"),
]
lua = ["-- the slate's steps, in words (made by make-slate.py)", "return {"]
for key, l1, l2 in SAYS:
    tile(f"say-{key}", 3200, 300, [l1, l2], [bold(92), serif(76)])
    lua.append(f'  ["{key}"] = {{ "{l1}", "{l2}" }},')
tile("say-ready-safe", 3200, 300, ["T: the safecracker's tour;  F: feel the contact points where the wheels are",
                                   "L, R: the dial a number;  Space: right until it stops;  C: close"],
     [serif(88), serif(70)], fill=DIM)
tile("say-ready", 3200, 300, ["Type six figures (31 72 46) and press Return",
                              "L, R: the dial a number;  Space: right until it stops;  C: close;  T: the tour"],
     [serif(88), serif(70)], fill=DIM)
lua.append("}")
open(f"{OUT}/says.lua", "w").write("\n".join(lua) + "\n")
print(len(os.listdir(OUT)), "files in", OUT)
