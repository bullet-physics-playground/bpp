"""The suanpan manual's figures (Babbage's Hall).

    python3 manual/make-figures.py      (from the exhibit's folder; Pillow, lua)

The states come from manual/states.lua, which works every example with
plan.lua, the exhibit's own rules; the abacus is drawn to the proportions
in parts/suanpan.scad. A bead that has just moved is orange, with an arrow
for the way it went. Writes manual/fig-*.png (all but fig-exhibit.png, a
screenshot of the simulation)."""
import os, subprocess
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
EX = os.path.dirname(HERE)
FONTS = "/usr/share/fonts/truetype/dejavu/"
def font(px, bold=False): return ImageFont.truetype(FONTS + ("DejaVuSans-Bold.ttf" if bold else "DejaVuSans.ttf"), int(px))

# (as parts/suanpan.scad, mm)
PITCH, BEAD_D, BEAD_T, BEAD_END, BAR_W, BEAM_W = 24, 20, 12, 8, 12, 8
HEAVEN_L, EARTH_L = 2 * BEAD_T + 14, 5 * BEAD_T + 14
NAMES = "ABCDEFG"
WOOD, DARK, BEAD, MOVED, ROD, INK, BLUE, RED = (150, 104, 60), (96, 64, 36), (60, 34, 24), (232, 128, 30), (170, 170, 175), (30, 30, 30), (30, 70, 170), (200, 30, 26)

# the states, from plan.lua
out = subprocess.run(["lua", "manual/states.lua"], cwd=EX, capture_output=True, text=True, check=True).stdout
STATES = {}
for line in out.strip().splitlines():
    ex, cap, ds, mv = line.split("|")
    moves = [tuple(m.split(",")) for m in mv.split(";") if m]
    STATES.setdefault(ex, []).append((cap, [int(x) for x in ds.split(",")], [(int(r), dk, int(c)) for r, dk, c in moves]))


def abacus(digits, rods=None, prev=None, px=3.2, names=True, value=False, labels=None):
    """an abacus showing digits (one a rod), only the rods listed (1-based,
    default all); beads that differ from prev are orange, with arrows"""
    rods = rods or list(range(1, len(digits) + 1))
    n = len(rods)
    W = (n * PITCH + 2 * BAR_W) * px
    Hm = (2 * BAR_W + HEAVEN_L + BEAM_W + EARTH_L) * px
    top_pad = 4 * px
    bot = (12 if names else 3) * px + (max(24, 9 * px) if value or labels else 0)
    im = Image.new("RGB", (int(W), int(Hm + top_pad + bot)), (255, 255, 255))
    g = ImageDraw.Draw(im)
    y0 = top_pad
    def Y(mm): return y0 + mm * px
    g.rectangle([0, Y(0), W - 1, Y(2 * BAR_W + HEAVEN_L + BEAM_W + EARTH_L)], fill=WOOD, outline=DARK, width=max(1, int(px * 0.6)))
    inner = (BAR_W * px, Y(BAR_W), W - BAR_W * px, Y(BAR_W + HEAVEN_L + BEAM_W + EARTH_L))
    g.rectangle(inner, fill=(245, 238, 222))
    beamTop, beamBot = BAR_W + HEAVEN_L, BAR_W + HEAVEN_L + BEAM_W
    g.rectangle([BAR_W * px, Y(beamTop), W - BAR_W * px, Y(beamBot)], fill=WOOD)
    for i, r in enumerate(rods):
        cx = (BAR_W + (i + 0.5) * PITCH) * px
        g.line([(cx, Y(BAR_W)), (cx, Y(BAR_W + HEAVEN_L + BEAM_W + EARTH_L))], fill=ROD, width=max(1, int(px * 0.9)))
        d = digits[r - 1]
        h, e = (1 if d >= 5 else 0), d % 5
        ph, pe = h, e
        if prev is not None:
            pd = prev[r - 1]; ph, pe = (1 if pd >= 5 else 0), pd % 5
        centres = []
        # heaven: the h nearest the beam at it, the rest at the top bar
        for k in range(2):                       # (k = 0 nearest the beam)
            at = k < h
            c = beamTop - (k + 0.5) * BEAD_T if at else BAR_W + (1 - k + 0.5) * BEAD_T
            moved = prev is not None and ((k < h) != (k < ph))
            centres.append((c, moved))
        for k in range(5):                       # earth: the e nearest the beam at it
            at = k < e
            c = beamBot + (k + 0.5) * BEAD_T if at else BAR_W + HEAVEN_L + BEAM_W + EARTH_L - (4 - k + 0.5) * BEAD_T
            moved = prev is not None and ((k < e) != (k < pe))
            centres.append((c, moved))
        for c, moved in centres:
            a, b = BEAD_D / 2 * px, BEAD_T / 2 * px
            e_ = BEAD_END / 2 * px
            yc = Y(c)
            pts = [(cx - a, yc), (cx - e_, yc - b), (cx + e_, yc - b), (cx + a, yc), (cx + e_, yc + b), (cx - e_, yc + b)]
            g.polygon(pts, fill=MOVED if moved else BEAD, outline=(20, 12, 8))
        # (arrows for the moves: down for heaven beads to the beam, up for earth beads to it)
        if prev is not None:
            ax = cx + BEAD_D / 2 * px + 1.2 * px
            for deck, now, was in (("heaven", h, ph), ("earth", e, pe)):
                if now == was: continue
                toward = now > was
                if deck == "heaven":
                    ya, yb = (BAR_W + 4, beamTop - 4) if toward else (beamTop - 4, BAR_W + 4)
                else:
                    ya, yb = (beamBot + EARTH_L - 4, beamBot + 4) if toward else (beamBot + 4, beamBot + EARTH_L - 4)
                ya, yb = Y(ya), Y(yb)
                g.line([(ax, ya), (ax, yb)], fill=RED, width=max(3, int(px * 0.8)))
                hl, hw = max(8, 1.8 * px), max(5, 1.2 * px)
                s = hl * (1 if yb > ya else -1)
                g.polygon([(ax, yb), (ax - hw, yb - s), (ax + hw, yb - s)], fill=RED)
        if names:
            g.text((cx, Y(2 * BAR_W + HEAVEN_L + BEAM_W + EARTH_L) + 5 * px), NAMES[r - 1] if labels is None else "",
                   font=font(max(15, 5 * px), True), fill=(110, 110, 110), anchor="mm")
        if labels is not None:
            g.text((cx, Y(2 * BAR_W + HEAVEN_L + BEAM_W + EARTH_L) + 6 * px), str(labels[i]), font=font(6.5 * px, True), fill=INK, anchor="mm")
    if value:
        v = int("".join(str(digits[r - 1]) for r in rods))
        g.text((W / 2, Y(2 * BAR_W + HEAVEN_L + BEAM_W + EARTH_L) + 10 * px + max(10, 3 * px)), f"{v}", font=font(max(18, 6.5 * px), True), fill=INK, anchor="mm")
    return im


def caption(im, text, width=None, size=None):
    width = width or im.width
    size = size or max(14, im.width // 16)
    f = font(size)
    # (wrap to the width)
    words, lines, cur = text.split(), [], ""
    g0 = ImageDraw.Draw(im)
    for w in words:
        t = (cur + " " + w).strip()
        if g0.textlength(t, font=f) > width - 8 and cur: lines.append(cur); cur = w
        else: cur = t
    lines.append(cur)
    h = int(len(lines) * size * 1.25 + size * 0.6)
    out = Image.new("RGB", (im.width, im.height + h), (255, 255, 255))
    out.paste(im, (0, 0))
    g = ImageDraw.Draw(out)
    for i, l in enumerate(lines):
        g.text((im.width / 2, im.height + size * 0.4 + i * size * 1.25), l, font=f, fill=INK, anchor="ma")
    return out


def row(ims, gap=26, arrow=True, pad=10):
    H = max(i.height for i in ims)
    W = sum(i.width for i in ims) + gap * (len(ims) - 1) + 2 * pad
    out = Image.new("RGB", (W, H + 2 * pad), (255, 255, 255))
    g = ImageDraw.Draw(out)
    x = pad
    for k, im in enumerate(ims):
        out.paste(im, (x, pad))
        x += im.width
        if arrow and k < len(ims) - 1:
            yc = pad + H * 0.4
            g.line([(x + 5, yc), (x + gap - 7, yc)], fill=(120, 120, 120), width=3)
            g.polygon([(x + gap - 3, yc), (x + gap - 11, yc - 6), (x + gap - 11, yc + 6)], fill=(120, 120, 120))
        x += gap
    return out


def column(ims, gap=18):
    W = max(i.width for i in ims)
    out = Image.new("RGB", (W, sum(i.height for i in ims) + gap * (len(ims) - 1)), (255, 255, 255))
    y = 0
    for im in ims:
        out.paste(im, ((W - im.width) // 2, y)); y += im.height + gap
    return out


def save(im, name):
    im.save(os.path.join(HERE, name), optimize=True)
    print("  manual/" + name, im.size)


def label_parts(im, px):
    """the whole abacus with its parts named, to its right"""
    W = im.width + int(130 * px)
    out = Image.new("RGB", (W, im.height), (255, 255, 255))
    out.paste(im, (0, 0))
    g = ImageDraw.Draw(out)
    f = font(5.4 * px)
    top = 4 * px
    def Y(mm): return top + mm * px
    x0 = im.width + 4 * px
    for ymm, text in ((BAR_W + HEAVEN_L / 2, "heaven beads: 5 each, counted at the beam"),
                      (BAR_W + HEAVEN_L + BEAM_W / 2, "the beam (reckoning bar)"),
                      (BAR_W + HEAVEN_L + BEAM_W + EARTH_L / 2, "earth beads: 1 each, counted at the beam")):
        g.line([(im.width - BAR_W * px * 0.5, Y(ymm)), (x0 + 2 * px, Y(ymm))], fill=BLUE, width=2)
        g.text((x0 + 4 * px, Y(ymm)), text, font=f, fill=BLUE, anchor="lm")
    g.text((x0 + 4 * px, Y(2 * BAR_W + HEAVEN_L + BEAM_W + EARTH_L) + 5 * px), "rods A to G: G is the units", font=f, fill=(110, 110, 110), anchor="lm")
    return out


# 1. the parts: 1972
px = 3.2
cap, d, _ = STATES["parts"][0]
save(label_parts(abacus(d, px=px), px), "fig-parts.png")

# 2. the ten digits on one rod each
digits10 = list(range(10))
save(abacus(digits10, rods=list(range(1, 11)), px=1.6, names=False, labels=digits10), "fig-digits.png")

# 3. the rules: one figure each, the two rods it uses, a picture a move
def rule_row(ex, rods=(6, 7)):
    ims, prev = [], None
    for cap, d, mv in STATES[ex]:
        ims.append(abacus(d, rods=list(rods), prev=prev, px=1.25))
        prev = d
    return row(ims)
for ex in ("direct", "direct5", "five", "ten", "tenfive", "sdirect", "sfive", "sten"):
    save(rule_row(ex), f"fig-rule-{ex}.png")

# 4. a whole addition, a whole borrow, a multiplication
def sequence(ex, rods, px_, size=22, per_row=None, value=True):
    sts = STATES[ex]
    ims, prev = [], None
    for cap, d, mv in sts:
        ims.append(caption(abacus(d, rods=rods, prev=prev, px=px_, value=value), cap, size=size))
        prev = d
    if per_row:
        rows = [row(ims[i:i + per_row]) for i in range(0, len(ims), per_row)]
        return column(rows, gap=20)
    return row(ims)
save(sequence("add", [5, 6, 7], 2.0), "fig-add.png")
save(sequence("borrow", [4, 5, 6, 7], 1.7, size=20), "fig-borrow.png")
save(sequence("multiply", list(range(1, 8)), 1.5, size=20, per_row=4, value=False), "fig-multiply.png")
