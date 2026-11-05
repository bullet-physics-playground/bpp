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
    fT = ImageFont.truetype(FONTS + "DejaVuSerif-Bold.ttf", 96)
    fS = ImageFont.truetype(FONTS + "DejaVuSerif-Italic.ttf", 56)
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
