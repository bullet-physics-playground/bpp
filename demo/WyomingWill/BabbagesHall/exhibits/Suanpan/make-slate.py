"""The suanpan's slate: the pictures it shows, as PNGs in slate/ (Babbage's
Hall). Run from this folder: python3 make-slate.py (Pillow, DejaVu fonts).

The slate beside the abacus shows the number on it, the number being added
(taken away, multiplied), which rod the hand is at, and the rule it is using. Each is a picture the
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


def tile(name, w, h, lines, fonts, fill=CHALK, align="center", small=False):
    im = Image.new("RGB", (w, h), SLATE)
    d = ImageDraw.Draw(im)
    n = len(lines)
    for i, (line, f) in enumerate(zip(lines, fonts)):
        y = h * (i + 0.5) / n
        if align == "center": d.text((w / 2, y), line, font=f, fill=fill, anchor="mm")
        else: d.text((24, y), line, font=f, fill=fill, anchor="lm")
    if small: im.quantize(colors=8).save(f"{OUT}/{name}.png", optimize=True)   # (a palette: a third the size)
    else: im.save(f"{OUT}/{name}.png")


for k in range(10):
    tile(f"digit-{k}", 100, 130, [str(k)], [bold(104)])
tile("digit-blank", 100, 130, [""], [bold(104)])
tile("digit-times", 100, 130, ["\u00d7"], [bold(96)], small=True)
tile("label-abacus", 460, 80, ["ON THE ABACUS"], [bold(44)], align="left")
tile("label-adding", 460, 80, ["ADDING"], [bold(44)], align="left")
tile("label-subtracting", 460, 80, ["TAKING AWAY"], [bold(44)], align="left", small=True)
tile("label-multiplying", 460, 80, ["MULTIPLYING"], [bold(44)], align="left", small=True)
tile("place-none", 1300, 80, [""], [serif(46)])
for i, p in enumerate(PLACES, 1):
    tile(f"place-{i}", 1300, 80, [f"at the {p} rod"], [serif(48)], align="left")
    tile(f"place-{i}-carry", 1300, 80, [f"at the {p} rod: the carry"], [serif(48)], align="left")
    tile(f"place-{i}-borrow", 1300, 80, [f"at the {p} rod: the borrow"], [serif(48)], align="left", small=True)
# (multiplying: the rods by letter, A the leftmost, as abacus books name them)
ORD = ["first", "second", "third", "fourth", "fifth", "sixth", "seventh"]
for i in range(1, 8):
    L = "ABCDEFG"[i - 1]
    tile(f"rod-{i}", 1300, 80, [f"at rod {L}, the {ORD[i - 1]} from the left"], [serif(48)], align="left", small=True)
    tile(f"rod-{i}-carry", 1300, 80, [f"at rod {L}: the carry"], [serif(48)], align="left", small=True)


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


def srule(r, a):
    """taking away: the rule's two lines"""
    c = 10 - a
    if r == "sdirect":
        return f"\u2212{a}", f"{WORDS[a]} earth bead{'s' if a > 1 else ''} down"
    if r == "sdirect5":
        if a == 5: return "\u22125", "the heaven bead up"
        return f"\u2212{a} = \u22125 \u2212 {a - 5}", f"heaven bead up, {WORDS[a - 5]} earth down"
    if r == "sfive":
        return f"\u2212{a} = \u22125 + {5 - a}", f"heaven bead up, {WORDS[5 - a]} earth up"
    if r == "sten":
        return f"\u2212{a} = \u221210 + {c}", f"{WORDS[c]} earth up, borrow 1 from the left"
    if r == "stenfive":
        return f"\u2212{a} = \u221210 + {c},  +{c} = 5 \u2212 {5 - c}", f"heaven down, {WORDS[5 - c]} earth down, borrow 1"
    if r == "sten5":
        if a == 5: return "\u22125 = \u221210 + 5", "heaven bead down, borrow 1 from the left"
        return f"\u2212{a} = \u221210 + {c},  +{c} = 5 + {c - 5}", f"heaven down, {WORDS[c - 5]} earth up, borrow 1"


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
# taking away: the same cases, backward
for r, a in CASES:
    l1, l2 = srule("s" + r, a)
    tile(f"rule-s{r}-{a}", 1300, 200, [l1, l2], [bold(64), serif(54)], small=True)
    lua.append(f'  ["s{r}-{a}"] = {{ "{l1}", "{l2}" }},')
# multiplying: the times table, each product two digits; the steps around it
for a in range(1, 10):
    for b in range(1, 10):
        q = a * b
        l1 = f"{a} \u00d7 {b} = {q:02d}"
        l2 = "its tens on the rod shown, its units on the next" if q >= 10 else \
             f"no tens: the {q} on the rod after the one shown"
        tile(f"rule-times-{a}-{b}", 1300, 200, [l1, l2], [bold(64), serif(50)], small=True)
        lua.append(f'  ["times-{a}-{b}"] = {{ "{l1}", "{l2}" }},')
for key, l1, l2 in [("mset", "Setting the multiplier", "on the rods at the left"),
                    ("aset", "Setting the multiplicand", "to its right, with room for the product"),
                    ("mclear", "The multiplier cleared", "the product is left on the rods at the right")]:
    tile(f"rule-{key}", 1300, 200, [l1, l2], [bold(64), serif(54)], small=True)
    lua.append(f'  ["{key}"] = {{ "{l1}", "{l2}" }},')
for d in range(1, 10):
    l1, l2 = f"The {d} is used", "its rod cleared; then the next digit to its left"
    tile(f"rule-mdone-{d}", 1300, 200, [l1, l2], [bold(64), serif(54)], small=True)
    lua.append(f'  ["mdone-{d}"] = {{ "{l1}", "{l2}" }},')
tile("rule-none", 1300, 200, ["", ""], [bold(64), serif(54)])
tile("rule-ready", 1300, 200, ["Type a number, Enter adds it", "C clears the abacus; T, the tour"], [serif(54), serif(48)], fill=DIM)
tile("rule-ready-subtract", 1300, 200, ["Type a number, Enter takes it away", "A adds it instead; C clears; T, the tour"],
     [serif(54), serif(48)], fill=DIM, small=True)
tile("rule-ready-multiply", 1300, 200, ["Type 36, X, 4: Enter multiplies", "C clears the abacus; T, the tour"],
     [serif(54), serif(48)], fill=DIM, small=True)
tile("rule-clear", 1300, 200, ["Clearing", "heaven beads up, earth beads down"], [bold(64), serif(54)])
lua.append("}")
open(f"{OUT}/rules.lua", "w").write("\n".join(lua) + "\n")
print(len(os.listdir(OUT)), "files in", OUT)
