"""The suanpan's slate: the pictures it shows, as PNGs in slate/ (Babbage's
Hall). Run from this folder: python3 make-slate.py (Pillow, DejaVu fonts).

The slate beside the abacus shows the number on it, the number being added,
which rod the hand is at, and the rule it is using. Each is a picture the
script swaps in (a digit, a rod's name, a rule): chalk on slate. Also
writes slate/rules.lua, the rules' words for the script to print."""
import os
from PIL import Image, ImageDraw, ImageFont

OUT = "slate"
FONTS = "/usr/share/fonts/truetype/dejavu/"
SLATE, CHALK, DIM = (34, 40, 42), (236, 232, 214), (150, 150, 140)
os.makedirs(OUT, exist_ok=True)
serif = lambda n: ImageFont.truetype(FONTS + "DejaVuSerif.ttf", n)
bold = lambda n: ImageFont.truetype(FONTS + "DejaVuSerif-Bold.ttf", n)
WORDS = ["", "one", "two", "three", "four"]
PLACES = ["units", "tens", "hundreds", "thousands", "ten thousands", "hundred thousands", "millions"]


def tile(name, w, h, lines, fonts, fill=CHALK, align="center"):
    im = Image.new("RGB", (w, h), SLATE)
    d = ImageDraw.Draw(im)
    n = len(lines)
    for i, (line, f) in enumerate(zip(lines, fonts)):
        y = h * (i + 0.5) / n
        if align == "center": d.text((w / 2, y), line, font=f, fill=fill, anchor="mm")
        else: d.text((24, y), line, font=f, fill=fill, anchor="lm")
    im.save(f"{OUT}/{name}.png")


for k in range(10):
    tile(f"digit-{k}", 100, 130, [str(k)], [bold(104)])
tile("digit-blank", 100, 130, [""], [bold(104)])
tile("label-abacus", 460, 80, ["ON THE ABACUS"], [bold(44)], align="left")
tile("label-adding", 460, 80, ["ADDING"], [bold(44)], align="left")
tile("place-none", 1300, 80, [""], [serif(46)])
for i, p in enumerate(PLACES, 1):
    tile(f"place-{i}", 1300, 80, [f"at the {p} rod"], [serif(48)], align="left")
    tile(f"place-{i}-carry", 1300, 80, [f"at the {p} rod: the carry"], [serif(48)], align="left")


def rule(r, a):
    """the rule's two lines: what is added, and how the beads move"""
    c = 10 - a
    if r == "direct":
        return f"+{a}", f"{WORDS[a]} earth bead{'s' if a > 1 else ''} up"
    if r == "direct5":
        if a == 5: return "+5", "the heaven bead down"
        return f"+{a} = 5 + {a - 5}", f"heaven bead down, {WORDS[a - 5]} earth up"
    if r == "five":
        return f"+{a} = 5 − {5 - a}", f"heaven bead down, {WORDS[5 - a]} earth down"
    if r == "ten":
        return f"+{a} = 10 − {c}", f"{WORDS[c]} earth down, carry 1 to the left"
    if r == "tenfive":
        return f"+{a} = 10 − {c},  −{c} = −5 + {5 - c}", f"{WORDS[5 - c]} earth up, heaven up, carry 1"
    if r == "ten5":
        if a == 5: return "+5 = 10 − 5", "heaven bead up, carry 1 to the left"
        return f"+{a} = 10 − {c},  −{c} = −5 − {c - 5}", f"heaven up, {WORDS[c - 5]} earth down, carry 1"


# which (rule, a) can happen: direct a 1-4; direct5 a 5-9; five a 1-4;
# ten a 6-9 (10 - a < 5, enough earth); tenfive a 6-9; ten5 a 1-5
CASES = [("direct", a) for a in range(1, 5)] + [("direct5", a) for a in range(5, 10)] + \
        [("five", a) for a in range(1, 5)] + [("ten", a) for a in range(6, 10)] + \
        [("tenfive", a) for a in range(6, 10)] + [("ten5", a) for a in range(1, 6)]
lua = ["-- the slate's rules, in words (made by make-slate.py)", "return {"]
for r, a in CASES:
    l1, l2 = rule(r, a)
    tile(f"rule-{r}-{a}", 1300, 200, [l1, l2], [bold(64), serif(54)])
    lua.append(f'  ["{r}-{a}"] = {{ "{l1}", "{l2}" }},')
tile("rule-none", 1300, 200, ["", ""], [bold(64), serif(54)])
tile("rule-ready", 1300, 200, ["Type a number, Enter adds it", "C clears the abacus; T, the tour"], [serif(54), serif(48)], fill=DIM)
tile("rule-clear", 1300, 200, ["Clearing", "heaven beads up, earth beads down"], [bold(64), serif(54)])
lua.append("}")
open(f"{OUT}/rules.lua", "w").write("\n".join(lua) + "\n")
print(len(os.listdir(OUT)), "files in", OUT)
