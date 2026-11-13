"""Babbage's Hall's lectern labels: the card on the lectern in front of an
exhibit, as a PNG in hall-meshes/ (lectern-<key>.png, the key its placard's).
Run from this folder: python3 make-lecterns.py [key ...] (needs Pillow and
the DejaVu fonts). The hall puts the card on a lectern before the exhibit's
table when the file is there.

A museum label: the name, a line saying what and whose, and a few
sentences, dark on a cream card, 36 x 24 cm."""
import sys
from PIL import Image, ImageDraw, ImageFont

OUT = "hall-meshes"
FONTS = "/usr/share/fonts/truetype/dejavu/"
W, H = 1440, 960                  # px: the card, 36 x 24 cm at 40 px a cm
INK, CARD, RULE = (43, 30, 20), (239, 230, 207), (150, 110, 50)

LABELS = {
    "differential": (
        "THE DIFFERENTIAL",
        "Bevel gears that add",
        "Turn input A and the small gears on the cross pin roll round input B, "
        "carrying the ring round the middle half as far. The ring always turns "
        "(A~+~B)~/~2; with twice as many numbers as the inputs, it reads A~+~B. "
        "Turn one input backward and it subtracts.\n"
        "The same gears let a car's wheels turn at different speeds on a bend. "
        "Fire-control computers and Bush's Differential Analyser used them to add.",
    ),
    "pascaline": (
        "THE PASCALINE",
        "Blaise Pascal's adding machine, 1642",
        "Pascal built it at nineteen to help his father, a tax official, with "
        "his sums. Each dial turns a wheel of ten places; dial in a number and "
        "it is added to what the wheels show.\n"
        "The carry is the clever part: a wheel passing 9 lifts a weighted "
        "lever, the sautoir, which drops as it goes on to 0 and kicks the next "
        "wheel on by one. Watch 99~+~1 ripple to 100.",
    ),
    "lehmer": (
        "LEHMER'S NUMBER SIEVE",
        "Wheels that find factors, 1926",
        "Each wheel has as many places as its number: 9, 8, 7 and 5. Every "
        "turn of the handle moves them all on one place. Pegs close the holes "
        "of the numbers that fail a test; where every wheel shows an open "
        "hole at once, the probe falls right through, and the machine stops.\n"
        "Lehmer built his first of bicycle chains, his second of gears, light "
        "and a photocell. This one factors a number by Fermat's way.",
    ),
    "domino-adder": (                 # (Matt Parker: think-maths.co.uk, the Domino Computer, Oct. 2012)
        "THE DOMINO HALF ADDER",
        "Falling dominoes that add",
        "268 dominoes add two one-bit numbers, A and B, and show the answer "
        "as two tiles, CARRY and SUM, which fall to show a 1: so 1~+~1 makes "
        "binary 10.\n"
        "Three tricks are enough. Waves meeting head-on stop each other; a "
        "branch is taken only by a wave running toward it; and a wave can cut "
        "across another line. From these come the gates XOR and AND. In 2012 "
        "Matt Parker's team built one of 10,000 dominoes that adds two "
        "four-bit numbers.",
    ),
    "galton": (                       # (Tisley and Spiller made Galton's in 1873: UCL, LDUGC-063)
        "THE GALTON BOARD",
        "Francis Galton's quincunx, 1873",
        "A ball falling through twelve rows of pins goes left or right at "
        "each; the bin it ends in counts the times it went right. Where one "
        "ball goes is chance, yet 150 of them pile up in the same bell, close "
        "to the gold lines fair coins would give: the binomial distribution, "
        "which for many rows becomes the normal curve.\n"
        "Galton's, made for him in London, ran on lead shot. Here two "
        "mirror-image wheels under the hopper let the balls in one at a time.",
    ),
    "digicomp": (
        "THE DIGI-COMP II",
        "A computer of rolling balls, 1965",
        "Designed by John Godfrey and sold by E.S.R. Inc. as a toy, it counts, "
        "adds, subtracts, multiplies and divides in binary, run by nothing but "
        "balls rolling down a tilted board.\n"
        "Each rocker is a flip-flop, a bit that a passing ball tips over. "
        "Thirteen of them hold the numbers; four switches are its memory. Its "
        "programs are lines of settings, shown on the board behind it.",
    ),
}


def wrap(draw, text, font, width):
    lines = []
    for para in text.split("\n"):
        line = ""
        for word in para.split(" "):          # ("~" keeps words together: a space that doesn't break)
            word = word.replace("~", " ")
            t = (line + " " + word).strip(" ")
            if draw.textlength(t, font=font) <= width: line = t
            else: lines.append(line); line = word
        lines.append(line)
        lines.append(None)            # (a paragraph's end: a little space)
    return lines[:-1]


def card(key, title, sub, body):
    im = Image.new("RGB", (W, H), CARD)
    d = ImageDraw.Draw(im)
    d.rectangle([24, 24, W - 25, H - 25], outline=RULE, width=6)
    d.rectangle([40, 40, W - 41, H - 41], outline=RULE, width=2)
    def fit(face, size, text):          # (the largest size up to this that fits across)
        while True:
            f = ImageFont.truetype(FONTS + face, size)
            if d.textlength(text, font=f) <= W - 160 or size <= 24: return f
            size -= 2
    fT = fit("DejaVuSerif-Bold.ttf", 96, title)
    fS = fit("DejaVuSerif-Italic.ttf", 56, sub)
    fB = ImageFont.truetype(FONTS + "DejaVuSerif.ttf", 46)
    m = 100
    y = 80
    d.text((W / 2, y), title, font=fT, fill=INK, anchor="ma"); y += 120
    d.text((W / 2, y), sub, font=fS, fill=INK, anchor="ma"); y += 90
    d.line([(W / 2 - 220, y), (W / 2 + 220, y)], fill=RULE, width=4); y += 40
    for line in wrap(d, body, fB, W - 2 * m):
        if line is None: y += 24; continue
        d.text((m, y), line, font=fB, fill=INK); y += 60
    if y > H - 60: print(f"  {key}: the text runs off the card (to y {y}): shorten it")
    path = f"{OUT}/lectern-{key}.png"
    im.save(path)
    print("wrote", path)


for key in (sys.argv[1:] or LABELS):
    card(key, *LABELS[key])
