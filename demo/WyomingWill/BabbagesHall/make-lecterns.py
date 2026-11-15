"""Babbage's Hall's lectern labels: the card on the lectern in front of an
exhibit, as a PNG in hall-meshes/ (lectern-<key>.png, the key its placard's).
Run from this folder: python3 make-lecterns.py [key ...] (needs Pillow and
the DejaVu fonts). The hall puts the card on a lectern before the exhibit's
table when the file is there.

A museum label: the name, a line saying what and whose, and a few
sentences, dark on a cream card, 36 x 24 cm.

A label can have pages: a list of cards instead of one. The first is
lectern-<key>.png, the next lectern-<key>-2.png and so on; each says which
page it is, and all but the last "PgDn: more". In the hall PgDn and PgUp
turn them. An exhibit with ways of its own (hall.lua's modes) has a label
for each way, named in its mode's card."""
import sys
from PIL import Image, ImageDraw, ImageFont

OUT = "hall-meshes"
FONTS = "/usr/share/fonts/truetype/dejavu/"
W, H = 1440, 960                  # px: the card, 36 x 24 cm at 40 px a cm
INK, CARD, RULE = (43, 30, 20), (239, 230, 207), (150, 110, 50)

# (the splitter board's last page, whichever way it is shown)
READING = (
    "FURTHER READING",
    "Fair coins and random walks",
    "William Feller, An Introduction to Probability Theory and Its "
    "Applications, vol.~1 (1968): chapters III and XIV.\n"
    "Charles Grinstead and J.~Laurie Snell, Introduction to Probability "
    "(1997), chapter 12. Free online.\n"
    "Remco van der Hofstad and Michael Keane, An elementary proof of the "
    "hitting time theorem, Amer. Math. Monthly 115 (2008).",
)

LABELS = {
    "suanpan": [(                    # (Matsuzaki and Wood: Kojima, The Japanese Abacus, 1954; Computer History Museum)
        "THE SUANPAN",
        "The Chinese abacus",
        "Each rod holds a digit, the units on the right. A heaven bead above "
        "the beam counts five and an earth bead below it counts one, when "
        "pushed to the beam.\n"
        "Type a number and press Return: the finger adds it rod by rod from "
        "the left, as it is done by hand, and the slate shows each rule it uses.",
    ), (
        "THE RULES",
        "Fives and tens",
        "Nobody works out 7~+~8 on an abacus. A pupil learned three moves by "
        "heart. If there is room, beads to the beam. If not, use five: "
        "+3~=~5~\u2212~2, the heaven bead down and two earth beads away. Past "
        "nine, use ten: +8~=~10~\u2212~2, two away and carry one to the rod on "
        "the left.\n"
        "The hand never needs more than that.",
    ), (
        "BEADS AGAINST A MACHINE",
        "From China to Japan, and Tokyo, 1946",
        "The bead abacus was in wide use in China by the 1300s. It reached "
        "Japan in the late 1500s and became the soroban, one heaven bead and "
        "four earth beads to a rod.\n"
        "On 12~November 1946 in Tokyo, Kiyoshi Matsuzaki with a soroban raced "
        "Private Thomas Nathan Wood with an electric calculator. The abacus "
        "won four rounds of five, losing only at multiplication.",
    )],
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
    "splitter": [(
        "THE SPLITTER BOARD",
        "Fair coins, made exact",
        "On the Galton board opposite, each pin is fair, but a ball keeps "
        "moving sideways and goes the same way at the next pin two times in "
        "three. Here every pin is a splitter: a neck drops each ball straight "
        "onto it, and the choice it makes is a fresh coin.\n"
        "Tab steps on through its five ways, with walls that catch balls or "
        "send them back.",
    ), (
        "A WALL THAT CATCHES BALLS",
        "First passage",
        "Count each ball's steps: +1 when a pin sends it right, \u22121 when "
        "left. The wall is at \u22122: a ball is caught the first time it has "
        "gone left twice more than right, like a gambler with two dollars "
        "going broke.\n"
        "It rolls down a ramp into the tube for its row: a quarter of the "
        "balls in the first, then a long thin tail. On a board without end "
        "every ball would be caught, yet the average wait would be infinite.",
    ), (
        "THE MATHEMATICS",
        "The reflection principle",
        "The chance of first reaching \u2212a at step n is a/n times the "
        "chance of being at \u2212a then: 1/4, 1/8, 5/64 ... for the tubes. "
        "The chance of not yet being caught falls only as 1/\u221an, too "
        "slowly for an average.\n"
        "The balls that survive pile up away from the wall: in each bin, the "
        "bell curve's count less its mirror image's in the wall. Flip a path "
        "that touched the wall after it touched, and it ends at the mirror place.",
    ), READING],
    "splitter-ruin": [(
        "GAMBLER'S RUIN",
        "Two walls that catch balls",
        "Walls on both sides, four places apart, the balls starting one place "
        "from the left one. Almost every ball is caught within the twelve "
        "rows, by one wall or the other, into the tube for its side and row.\n"
        "A gambler with one dollar plays one with three, a dollar a toss, "
        "until one is broke. The chance of winning is your share of the "
        "money: a quarter of the balls go out on the right.",
    ), (
        "THE MATHEMATICS",
        "A fair game stays fair",
        "With walls a places to the left and b to the right, a ball goes out "
        "on the right with chance a/(a~+~b), after a\u00b7b steps on average: "
        "here a quarter, after three steps.\n"
        "Why: in a fair game the winnings you expect stay nothing, to the "
        "end. If p is the chance of winning b, the rest losing a, then "
        "p\u00b7b~=~(1~\u2212~p)\u00b7a, and so p~=~a/(a~+~b).",
    ), READING],
    "splitter-reflect": [(
        "A WALL THAT SENDS BALLS BACK",
        "The reflection principle, the other way",
        "Three places left of the start, a half tooth on the wall sends every "
        "ball that reaches it back inward, rolling off its pin just as a ball "
        "rolls off any splitter.\n"
        "No ball is lost, and each bin fills with the bell curve's count plus "
        "its mirror image's in the wall: of 150, 47, 42, 31, 19, 8 and 2 from "
        "the wall out. The wall that catches balls takes the mirror image "
        "away; this one adds it.",
    ), (
        "THE HALF TOOTH",
        "Built, and measured",
        "The first half tooth was a bare slope. A ball dropped onto it kept "
        "its speed, crossed the next neck and went back to the wall three "
        "times in four, and the walls hoarded balls.\n"
        "Kept on its pin, a ball lands on the pin's shoulder as it does on "
        "any splitter, and after the wall it goes on inward half the time, "
        "as a fair coin should. Two thousand balls a test were counted.",
    ), READING],
    "splitter-flat": [(
        "THE PILE GOES FLAT",
        "Two walls that send balls back",
        "With a bouncing wall on each side, three places from the start, the "
        "balls wander back and forth between them and forget where they "
        "began: by the sixth row each of the three bins is as likely as the "
        "others, and 150 balls fill them 50, 50, 50.\n"
        "Wider walls take longer: the rows needed grow as the square of the "
        "width. Five bins wide, twelve rows still leave 26, 31, 35, 31, 26.",
    ), READING],
    "splitter-none": [(
        "NO WALLS",
        "The binomial, exactly",
        "Twelve fair coins for each ball: its bin counts its heads. Of 4,096 "
        "equally likely ways down, 924 end in the middle bin, so for 150 balls "
        "the gold lines stand at 34 in the middle, then 29, 18, 8 and 2 either side.\n"
        "The Galton board opposite comes close to this. Here the pins really "
        "are fair coins, and the pile matches the lines as closely as chance allows.",
    ), READING],
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


def card(key, title, sub, body, page=1, pages=1):
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
    if pages > 1:                       # (which page, and that there are more)
        fP = ImageFont.truetype(FONTS + "DejaVuSerif-Italic.ttf", 34)
        d.text((W - 70, H - 62), f"{page} / {pages}", font=fP, fill=RULE, anchor="rs")
        if page < pages: d.text((70, H - 62), "PgDn: more", font=fP, fill=RULE, anchor="ls")
        y += 20
    if y > H - 60: print(f"  {key}: the text runs off the card (to y {y}): shorten it")
    path = f"{OUT}/lectern-{key}.png" if page == 1 else f"{OUT}/lectern-{key}-{page}.png"
    im.save(path)
    print("wrote", path)


for key in (sys.argv[1:] or LABELS):
    L = LABELS[key]
    pages = L if isinstance(L, list) else [L]
    for n, p in enumerate(pages, 1):
        card(key, *p, page=n, pages=len(pages))
