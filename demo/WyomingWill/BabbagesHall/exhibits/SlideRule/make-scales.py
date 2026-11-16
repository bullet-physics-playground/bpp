"""The slide rule's scales (Babbage's Hall): drawn once, written twice.

    python3 make-scales.py          (from this folder; Pillow, DejaVu fonts;
                                     playwright for the PDF)

  scales/face-upper.png, face-slide.png, face-lower.png
      the three faces as the simulation shows them (textures, 10 px a mm,
      the whole face: x from -20 to 270 mm, as parts/slide-rule.scad has it)
  scales.pdf
      the same scales at full size, on an A4 page, to print at 100% (no
      "fit to page"), cut out and glue onto the printed stock and slide.
      The strips run from 12 mm before the left index to 12 mm past the
      right one (274 mm); a 100 mm bar checks the printer's scale.
      (Drawn as SVG first, in mm, and printed to PDF by Chromium; with
      --svg the SVG is kept as scales.svg.)

The rule's frame is the parts file's: x along the rule, 0 at the left
index (1 on C and D), L = 250 mm at the right one; y across the face, the
slide's middle 0, the A side up. Every scale is a function from a number
to a place: C and D x = L log v; A and B x = (L / 2) log v; K x = (L / 3)
log v; CI x = L (1 - log v); L x = L v."""
import math, os, sys, tempfile
from PIL import Image, ImageDraw, ImageFont

L = 250.0
X0, X1 = -20.0, 270.0           # a face's ends (the stock's and the slide's)
PX = 10                         # texture pixels a mm
PAPER_X0, PAPER_X1 = -12.0, 262.0
FONTS = "/usr/share/fonts/truetype/dejavu/"
INK, RED, FACE = (24, 20, 16), (176, 30, 26), (246, 242, 228)
HERE = os.path.dirname(os.path.abspath(__file__))

# the faces, across (y, mm): their edges
FACES = {"upper": (9.0, 19.0), "slide": (-9.0, 9.0), "lower": (-27.0, -9.0)}
TICK = {"major": 3.2, "half": 2.5, "mid": 1.9, "minor": 1.3}     # tick lengths, mm


def ticks_log(decades, plan):
    """ticks of a log scale of so many decades over L: plan is a list of
    (from, to, step, [(every, kind)...]) for one decade, from 1 to 10"""
    out = []
    for d in range(decades):
        m = 10 ** d
        for a, b, step, kinds in plan:
            n = int(round((b - a) / step))
            for i in range(n + (1 if (b == 10 and d == decades - 1) else 0)):
                v = a + i * step
                kind = "minor"
                for every, k in kinds:
                    q = v / every
                    if abs(q - round(q)) < 1e-6:
                        kind = k
                        break
                out.append((v * m, kind))
    return out


CD_PLAN = [(1, 2, 0.01, [(1, "major"), (0.1, "half"), (0.05, "mid")]),
           (2, 4, 0.02, [(1, "major"), (0.5, "half"), (0.1, "mid")]),
           (4, 10, 0.05, [(1, "major"), (0.5, "half"), (0.1, "mid")])]
AB_PLAN = [(1, 2, 0.02, [(1, "major"), (0.5, "half"), (0.1, "mid")]),
           (2, 5, 0.05, [(1, "major"), (0.5, "half"), (0.1, "mid")]),
           (5, 10, 0.1, [(1, "major"), (0.5, "half")])]
K_PLAN = [(1, 3, 0.1, [(1, "major"), (0.5, "half")]),
          (3, 6, 0.2, [(1, "major")]),
          (6, 10, 0.5, [(1, "major")])]


def fmt(v):
    return ("%g" % v)


class Scale:
    """one scale: where on the face (base, the line its ticks stand on, and
    dir, which way they go), its marks and its numbers"""
    def __init__(s, name, face, base, dir, place, ticks, labels, col=INK, small=None):
        s.name, s.face, s.base, s.dir, s.place = name, face, base, dir, place
        s.ticks, s.labels, s.col, s.small = ticks, labels, col, small or []


def logx(dec):
    return lambda v: L / dec * math.log10(v)


cd = ticks_log(1, CD_PLAN)
ab = ticks_log(2, AB_PLAN)
kk = ticks_log(3, K_PLAN)
ll = [(i / 500.0, "major" if i % 50 == 0 else "half" if i % 25 == 0 else "mid" if i % 5 == 0 else "minor")
      for i in range(501)]
CD_LABELS = [(v, fmt(v)) for v in range(1, 10)] + [(10, "1")]
CD_SMALL = [(1 + k / 10, str(k)) for k in range(1, 10)] + [(2.5, ""), (math.pi, "π")]
AB_LABELS = [(v, fmt(v)) for v in range(1, 10)] + [(10 * v, fmt(10 * v)) for v in range(1, 11)]
K_LABELS = [(v, fmt(v)) for v in range(1, 10)] + [(10 * v, fmt(10 * v)) for v in range(1, 10)] + \
           [(100 * v, fmt(100 * v)) for v in (1, 2, 3, 4, 5, 6, 8)] + [(1000, "1000")]
SCALES = [
    Scale("A", "upper", 9.0, +1, logx(2), ab, AB_LABELS),
    Scale("B", "slide", 9.0, -1, logx(2), ab, AB_LABELS),
    Scale("CI", "slide", -3.0, +1, lambda v: L * (1 - math.log10(v)), cd, CD_LABELS, col=RED, small=CD_SMALL[:-2]),
    Scale("C", "slide", -9.0, +1, logx(1), cd, CD_LABELS, small=CD_SMALL),
    Scale("D", "lower", -9.0, -1, logx(1), cd, CD_LABELS, small=CD_SMALL),
    Scale("K", "lower", -15.0, -1, logx(3), kk, K_LABELS),
    Scale("L", "lower", -21.0, -1, lambda v: L * v, ll,
          [(i / 10, "0" if i == 0 else "1" if i == 10 else ".%d" % i) for i in range(11)]),
]
BIG, SMALL = 2.0, 1.45          # number heights, mm


def marks(face):
    """everything drawn on a face: lines (x0, y0, x1, y1, width, colour) and
    words (x, y, text, height, colour, anchor), in mm, the rule's frame"""
    lines, words = [], []
    y0, y1 = FACES[face]
    for s in SCALES:
        if s.face != face:
            continue
        for v, kind in s.ticks:
            x = s.place(v)
            ln = TICK[kind]
            w = 0.16 if kind in ("major", "half") else 0.12
            lines.append((x, s.base, x, s.base + s.dir * ln, w, s.col))
        ny = s.base + s.dir * (TICK["major"] + 0.25 + BIG / 2)
        last = -1e9
        for v, t in s.labels:
            x = s.place(v)
            words.append((x, ny, t, BIG, s.col, "mm"))
        sy = s.base + s.dir * (TICK["half"] + 0.2 + SMALL / 2)
        for v, t in s.small:
            if t:
                x = s.place(v)
                words.append((x + 0.35 * (1 if s.name != "CI" else -1), sy, t, SMALL, s.col,
                              "lm" if s.name != "CI" else "rm"))
        # (the scale's name at each end)
        words.append((-7.0, s.base + s.dir * 1.9, s.name, 2.4, s.col, "mm"))
        words.append((L + 7.0, s.base + s.dir * 1.9, s.name, 2.4, s.col, "mm"))
        # (the base line, the index to the index)
        lo, hi = sorted((s.place(s.ticks[0][0]), s.place(s.ticks[-1][0])))
        lines.append((lo, s.base + s.dir * 0.08, hi, s.base + s.dir * 0.08, 0.16, s.col))
    return lines, words


# -------------------------------------------------------------------------
# the textures
# -------------------------------------------------------------------------
def texture(face):
    y0, y1 = FACES[face]
    W, H = int((X1 - X0) * PX), int((y1 - y0) * PX)
    im = Image.new("RGB", (W, H), FACE)
    d = ImageDraw.Draw(im)
    def P(x, y): return ((x - X0) * PX, (y1 - y) * PX)
    lines, words = marks(face)
    for x0, ya, x1, yb, w, col in lines:
        # (at least 1.5 px wide: the texture is drawn smaller on the screen)
        wpx = max(1.5, w * PX)
        (u0, v0), (u1, v1) = P(x0, ya), P(x1, yb)
        if abs(u0 - u1) < 1e-6:
            d.rectangle([u0 - wpx / 2, min(v0, v1), u0 + wpx / 2, max(v0, v1)], fill=col)
        else:
            d.rectangle([min(u0, u1), v0 - wpx / 2, max(u0, u1), v0 + wpx / 2], fill=col)
    for x, y, t, h, col, anchor in words:
        f = ImageFont.truetype(FONTS + ("DejaVuSans-Bold.ttf" if h >= 2.3 else "DejaVuSans.ttf"), int(h * PX * 1.3))
        d.text(P(x, y), t, font=f, fill=col, anchor=anchor)
    os.makedirs(os.path.join(HERE, "scales"), exist_ok=True)
    im.save(os.path.join(HERE, "scales", f"face-{face}.png"), optimize=True)
    return im


# -------------------------------------------------------------------------
# the sheet to print: SVG in mm, A4 landscape
# -------------------------------------------------------------------------
def svg_sheet():
    out = ['<svg xmlns="http://www.w3.org/2000/svg" width="297mm" height="210mm" viewBox="0 0 297 210">',
           '<style>text{font-family:"DejaVu Sans",sans-serif}</style>']
    left = (297 - (PAPER_X1 - PAPER_X0)) / 2 - PAPER_X0      # the page's x of the rule's 0
    top = 30.0
    out.append(f'<text x="{left + PAPER_X0}" y="14" font-size="5" font-weight="bold">THE SLIDE RULE: its scales, full size</text>')
    out.append(f'<text x="{left + PAPER_X0}" y="21" font-size="3">Print at 100% (actual size, no scaling). '
               'Check the bar below is 100 mm. Cut on the grey lines; glue each strip on its face, '
               'its index lines over the rule\'s.</text>')
    for face, title in (("upper", "the upper stator (A)"), ("slide", "the slide (B, CI, C)"),
                        ("lower", "the lower stator (D, K, L)")):
        y0, y1 = FACES[face]
        h = y1 - y0
        def P(x, y): return (left + x, top + (y1 - y))
        out.append(f'<text x="{left + PAPER_X0}" y="{top - 1.5}" font-size="2.6" fill="#555">{title}</text>')
        out.append(f'<rect x="{left + PAPER_X0}" y="{top}" width="{PAPER_X1 - PAPER_X0}" height="{h}" '
                   'fill="none" stroke="#999" stroke-width="0.1"/>')
        lines, words = marks(face)
        for x0, ya, x1, yb, w, col in lines:
            (a, b), (c, e) = P(x0, ya), P(x1, yb)
            out.append(f'<line x1="{a:.3f}" y1="{b:.3f}" x2="{c:.3f}" y2="{e:.3f}" stroke="rgb{col}" stroke-width="{w}"/>')
        for x, y, t, hh, col, anchor in words:
            a, b = P(x, y)
            ta = {"m": "middle", "l": "start", "r": "end"}[anchor[0]]
            wt = ' font-weight="bold"' if hh >= 2.3 else ""
            t = t.replace("&", "&amp;")
            out.append(f'<text x="{a:.3f}" y="{b:.3f}" font-size="{hh * 1.3:.2f}" fill="rgb{col}" '
                       f'text-anchor="{ta}" dominant-baseline="central"{wt}>{t}</text>')
        top += h + 12
    # (the check bar)
    out.append(f'<rect x="{left}" y="{top}" width="100" height="3" fill="black"/>')
    out.append(f'<text x="{left + 103}" y="{top + 2.6}" font-size="3">100 mm</text>')
    out.append("</svg>")
    path = os.path.join(HERE, "scales.svg") if "--svg" in sys.argv else \
        os.path.join(tempfile.mkdtemp(), "scales.svg")
    open(path, "w").write("\n".join(out) + "\n")
    return path


def pdf(svg):
    try:
        from playwright.sync_api import sync_playwright
    except ImportError:
        print("  (no playwright: scales.pdf not made)")
        return
    html = f'<html><body style="margin:0">{open(svg).read()}</body></html>'
    with sync_playwright() as p:
        b = p.chromium.launch()
        pg = b.new_page()
        pg.set_content(html)
        pg.pdf(path=os.path.join(HERE, "scales.pdf"), width="297mm", height="210mm",
               margin={"top": "0", "bottom": "0", "left": "0", "right": "0"}, print_background=True)
        b.close()


if __name__ == "__main__":
    for f in FACES:
        texture(f)
    pdf(svg_sheet())
    print("scales/face-*.png, scales.pdf" + (", scales.svg" if "--svg" in sys.argv else ""))
