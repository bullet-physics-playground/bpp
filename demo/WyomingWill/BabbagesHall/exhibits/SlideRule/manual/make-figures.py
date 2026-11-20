"""The slide rule manual's figures (Babbage's Hall).

    python3 manual/make-figures.py      (from the exhibit's folder; Pillow)

Every face is drawn by make-scales.py's own marks(), the same lines the
simulation's textures and the printed scales come from; the slide and the
cursor are set where the manual says a person sets them, by the same
arithmetic as rule.lua (a number v on D at 250 log v mm). Only the arrows,
the labels and the shading are added. Writes manual/fig-*.png."""
import importlib.util, math, os
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location("scales", os.path.join(HERE, "..", "make-scales.py"))
SC = importlib.util.module_from_spec(spec)
spec.loader.exec_module(SC)
L, X0, X1, FACES = SC.L, SC.X0, SC.X1, SC.FACES
FONTS = SC.FONTS
WOOD, EDGE, RED, BLUE, GREY = (150, 112, 70), (90, 64, 40), (200, 30, 26), (30, 70, 170), (120, 120, 120)
lg = math.log10


def D(v): return L * lg(v)              # (a number's place on C or D, from the index)
def A(v): return L / 2 * lg(v)
def font(h, bold=False): return ImageFont.truetype(FONTS + ("DejaVuSans-Bold.ttf" if bold else "DejaVuSans.ttf"), int(h))


class Fig:
    """a picture of the rule: x from xa to xb (mm), px pixels a mm, with
    room above and below for labels"""
    def __init__(s, xa, xb, px, top=14, bottom=14, ya=-30.5, yb=22.5):
        s.xa, s.xb, s.px, s.top, s.ya, s.yb = xa, xb, px, top, ya, yb
        s.W = int((xb - xa) * px)
        s.H = int((yb - ya + top + bottom) * px)
        s.im = Image.new("RGB", (s.W, s.H), (252, 250, 245))
        s.g = ImageDraw.Draw(s.im)

    def P(s, x, y): return ((x - s.xa) * s.px, (s.yb + s.top - y) * s.px)

    def face(s, name, dx=0.0, x0=X0, x1=X1):
        y0, y1 = FACES[name]
        a, b = s.P(x0 + dx, y1), s.P(x1 + dx, y0)
        s.g.rectangle([a, b], fill=SC.FACE, outline=EDGE, width=max(1, int(s.px * 0.25)))
        lines, words = SC.marks(name)
        for xa_, ya_, xb_, yb_, w, col in lines:
            (u0, v0), (u1, v1) = s.P(xa_ + dx, ya_), s.P(xb_ + dx, yb_)
            if max(u0, u1) < 0 or min(u0, u1) > s.W: continue
            s.g.line([(u0, v0), (u1, v1)], fill=col, width=max(1, int(round(w * s.px))))
        for x, y, t, h, col, anchor in words:
            u, v = s.P(x + dx, y)
            if u < -50 or u > s.W + 50: continue
            s.g.text((u, v), t, font=font(h * s.px * 1.3, h >= 2.3), fill=col, anchor=anchor)

    def rule(s, slide=0.0, cursor=None, ghosts=()):
        """the stock, the slide set slide mm right, the cursor's hairline at
        cursor mm (or none); ghosts: other hairline places, drawn faint"""
        # (the stock's edges, then its faces; the slide over its channel)
        s.g.rectangle([s.P(X0, 19.6), s.P(X1, -27.6)], fill=WOOD)
        s.face("upper"); s.face("lower")
        s.g.rectangle([s.P(X0, 9), s.P(X1, -9)], fill=(110, 80, 50))     # (the channel, where the slide isn't)
        s.face("slide", dx=slide)
        for gx in ghosts:
            s.g.line([s.P(gx, 21.5), s.P(gx, -29.5)], fill=(225, 120, 110), width=max(1, int(s.px * 0.3)))
        if cursor is not None:
            c = cursor
            frame = Image.new("RGBA", s.im.size, (0, 0, 0, 0))
            fg = ImageDraw.Draw(frame)
            fg.rectangle([s.P(c - 15, 21.5), s.P(c + 15, -29.5)], fill=(90, 96, 104, 120))
            fg.rectangle([s.P(c - 11, 18.9), s.P(c + 11, -26.9)], fill=(0, 0, 0, 0))
            fg.rectangle([s.P(c - 11, 18.9), s.P(c + 11, -26.9)], fill=(200, 230, 235, 40))
            s.im.paste(Image.alpha_composite(s.im.convert("RGBA"), frame).convert("RGB"))
            s.g = ImageDraw.Draw(s.im)
            s.g.line([s.P(c, 21.5), s.P(c, -29.5)], fill=RED, width=max(2, int(s.px * 0.3)))

    def label(s, x, y, text, col=BLUE, size=3.2, anchor="mm", bold=False):
        s.g.text(s.P(x, y), text, font=font(size * s.px, bold), fill=col, anchor=anchor)

    def arrow(s, x0, y0, x1, y1, col=BLUE, text=None, size=3.2, anchor=None):
        (a, b), (c, d) = s.P(x0, y0), s.P(x1, y1)
        w = max(2, int(s.px * 0.35))
        s.g.line([(a, b), (c, d)], fill=col, width=w)
        ang = math.atan2(d - b, c - a)
        h = s.px * 1.6
        pts = [(c, d), (c - h * math.cos(ang - 0.4), d - h * math.sin(ang - 0.4)),
               (c - h * math.cos(ang + 0.4), d - h * math.sin(ang + 0.4))]
        s.g.polygon(pts, fill=col)
        if text:
            anc = anchor or ("md" if y0 > y1 else "ma")
            s.g.text((a, b + (-s.px * 0.6 if y0 > y1 else s.px * 0.6)), text, font=font(size * s.px), fill=col, anchor=anc)

    def callout(s, x, y, text, col=BLUE, above=True, side="r", size=5.2):
        """a short arrow straight down (or up) from the margin to (x, y),
        its words beside its tail, to the right (or left)"""
        tail = (TOP + 8 + (size - 5.2)) if above else (BOT - 8 - (size - 5.2))
        s.arrow(x, tail, x, y + (0.6 if above else -0.6), col=col)
        u, v = s.P(x, tail)
        off = s.px * 1.2
        s.g.text((u + off if side == "r" else u - off, v), text, font=font(size * s.px), fill=col,
                 anchor="lm" if side == "r" else "rm")

    def save(s, name):
        s.im.save(os.path.join(HERE, name), optimize=True)
        print("  manual/" + name, s.im.size)


def stack(name, figs, gap=10):
    W = max(f.im.width for f in figs)
    H = sum(f.im.height for f in figs) + gap * (len(figs) - 1)
    out = Image.new("RGB", (W, H), (255, 255, 255))
    y = 0
    for f in figs:
        out.paste(f.im, (0, y)); y += f.im.height + gap
    out.save(os.path.join(HERE, name), optimize=True)
    print("  manual/" + name, out.size)


TOP, BOT = 21.5, -29.5          # (just above and below the cursor)

# 1. the whole rule, its parts named
f = Fig(-34, 284, 5, top=17, bottom=17)
f.rule(cursor=D(2.5))
f.callout(40, 15, "the stock: A on its upper part")
f.callout(190, 3, "the slide: B, CI and C")
f.callout(170, -20, "the stock: D, K and L below it", above=False)
f.callout(D(2.5), -27, "the cursor's red hairline", col=RED, above=False, side="l")
f.save("fig-rule.png")

# 2. reading D: from 1 to 2 a mark every 0.01; from 4 to 10, every 0.05
def strip(xa, xb, marks):
    g = Fig(xa, xb, 14, top=8, bottom=8, ya=-15.4, yb=-8.5)          # (D alone)
    g.face("lower", x0=xa, x1=xb)
    g.g.rectangle([g.P(xa - 1, -15.4), g.P(xb + 1, -40)], fill=(252, 250, 245))    # (K and L below it, hidden)
    g.g.line([g.P(xa, -15.4), g.P(xb, -15.4)], fill=EDGE, width=2)
    for v, t, below in marks:
        x = D(v)
        g.g.line([g.P(x, -8.5), g.P(x, -15.4)], fill=RED, width=3)
        ty, hy = (-21.5, -15.0) if below else (-2.5, -8.9)
        g.arrow(x, ty, x, hy, col=RED)
        u, w = g.P(x, ty)
        g.g.text((u + 14, w), t, font=font(2.4 * g.px), fill=RED, anchor="lm")
    return g
stack("fig-reading.png", [
    strip(-3, 92, [(1.414, "1.414: four tenths from 1.41 to 1.42", False)]),
    strip(150, 245, [(4.47, "4.47: just short of half way from 4.45 to 4.50", False), (7.85, "7.85: on a mark", True)])], gap=24)

# 3. multiplying 2.5 x 3.2, step by step
s25 = D(2.5)
c3 = s25 + D(3.2)
panels = []
for n, (slide, cur, notes) in enumerate([
        (0, s25, [(s25, -9, "the cursor to 2.5 on D", BLUE, True)]),
        (s25, s25, [(s25, -9 + 3.2, "the slide: C's 1 under the hairline", BLUE, True)]),
        (s25, c3, [(c3, -9 + 3.2, "the cursor to 3.2 on C ...", BLUE, True),
                   (c3, -12.5, "... and D reads 8.00", RED, False)])], 1):
    p_ = Fig(-34, 284, 4, top=15, bottom=15 if n == 3 else 3)
    p_.rule(slide=slide, cursor=cur)
    p_.label(-31, TOP + 6, str(n), col=RED, size=6, bold=True, anchor="lm")
    for x, y, t, col, above in notes:
        p_.callout(x, y, t, col=col, above=above, side="r" if x < 200 else "l")
    panels.append(p_)
stack("fig-multiply.png", panels)

# 4. off the end: 3 x 4 by C's right index
s = D(3) - L
f = Fig(s - 26, 284, 3.4, top=21, bottom=21)
f.rule(slide=s, cursor=s + D(4), ghosts=(D(3),))
f.callout(D(3), -9 + 3.2, "C's 10 over 3 on D", size=7.5, side="l")
f.callout(s + D(4), -12.5, "4 on C, over 1.200 on D", col=RED, above=False, size=7.5)
f.callout(s + 40, 3, "the slide stands out to the left", col=GREY, size=7.5)
f.save("fig-right-index.png")

# 5. dividing 7.5 / 2.5
s = D(7.5) - D(2.5)
f = Fig(-34, 284, 4, top=17, bottom=17)
f.rule(slide=s, cursor=s, ghosts=(D(7.5),))
f.callout(D(7.5), -9 + 3.2, "2.5 on C, over 7.5 on D", side="l")
f.callout(s, -12.5, "under C's 1, D reads 3.00", col=RED, above=False)
f.save("fig-divide.png")

# 6. a table at one setting: 1.609 x 2, 3, 5
s = D(1.609)
f = Fig(-34, 284, 4, top=17, bottom=17)
f.rule(slide=s, cursor=s + D(5), ghosts=(s + D(2), s + D(3)))
f.callout(s, -9 + 3.2, "C's 1 over 1.609 (a mile in km)")
f.callout(s + D(2), -12.5, "2: 3.22", col=RED, above=False)
f.callout(s + D(3), -12.5, "3: 4.83", col=RED, above=False)
f.callout(s + D(5), -12.5, "5: 8.05", col=RED, above=False)
f.save("fig-table.png")

# 7. square roots: which half of A
f = Fig(-34, 284, 4, top=17, bottom=17)
f.rule(cursor=A(20), ghosts=(A(2),))
f.callout(A(2), 12.5, "2 on A's left half ...")
f.callout(A(2), -12.5, "... over 1.414 on D", col=RED, above=False)
f.callout(A(20), 12.5, "20 on A's right half ...")
f.callout(A(20), -12.5, "... over 4.47 on D", col=RED, above=False)
f.save("fig-roots.png")

# 8. cubes, reciprocals, logarithms
f = Fig(-34, 284, 4, top=17, bottom=17)
f.rule(cursor=D(4), ghosts=(D(2),))
f.callout(D(2), -27, "2 on D: 8 on K, .301 on L", col=RED, above=False)
f.callout(D(4), 0, "4 on C: 2.5 on CI, so 1/4 = 0.25", side="l")
f.save("fig-powers.png")
