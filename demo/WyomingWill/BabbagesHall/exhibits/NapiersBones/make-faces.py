"""The faces of Napier's bones and of Genaille's rods (Babbage's Hall): drawn
once, written twice.

    python3 make-faces.py        (from this folder; Pillow, DejaVu fonts;
                                  playwright for the PDFs)

  faces/napier-<d>.png, faces/napier-index.png      the textures (8 px a mm)
  faces/genaille-<d>.png, faces/genaille-index.png
  faces/blank.png
  napier-faces.pdf, genaille-faces.pdf
      A4 pages to print at 100%: one strip for each rod, its four faces side
      by side (64 x 176 mm), to fold around a printed rod and glue; and the
      index rod's strip. A 100 mm bar checks the printer's scale.

A face is 16 mm wide and 176 mm long, its top (the digit) up. From the
bottom: a 10 mm margin, then nine cells of 16 mm (on a Napier face the
multiples x 9 at the bottom up to x 1), the 16 mm cell with the digit, 6 mm.
A Genaille face has rows for 2 to 9 in the same 144 mm, the row for m
holding m entries (3.27 mm each): the units of d x m + c for each carry c
(0 at the top), and on the left a triangle for each tens digit among them,
its base over those entries, its tip at the left edge level with the entry
on the next rod that the tens select. bones.lua has the arithmetic, and
napiers-bones.lua the same layout (keep them together)."""
import os, sys, tempfile
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
FONTS = "/usr/share/fonts/truetype/dejavu/"
W, H = 16.0, 176.0
CELL, BOTTOM = 16.0, 10.0
TOP_CELL = BOTTOM + 9 * CELL                  # 154: the digit's cell from here to 170
E = 9 * CELL / 44                             # a Genaille entry's height
PX = 8
INK, FACE, RED, GREY = (30, 24, 18), (244, 236, 214), (160, 36, 28), (150, 140, 120)


def napier_row(k):                            # (the y range of the cell for x k)
    y0 = BOTTOM + (9 - k) * CELL
    return y0, y0 + CELL


def genaille_row(m):                          # (rows 2 to 9 from the top down)
    top = TOP_CELL
    for r in range(2, m):
        top -= r * E
    return top - m * E, top


def face(kind, d):
    """lines (x0, y0, x1, y1, width, colour), polygons ([(x, y)...], colour),
    words (x, y, text, height, colour, bold), in mm, y up from the bottom"""
    lines, polys, words = [], [], []
    for y in (TOP_CELL, TOP_CELL + CELL):
        lines.append((0, y, W, y, 0.3, INK))
    if kind == "napier":
        if d == "index":
            words.append((W / 2, TOP_CELL + CELL / 2, "×", 9, INK, True))
        else:
            words.append((W / 2, TOP_CELL + CELL / 2, str(d), 10, INK, True))
        for k in range(1, 10):
            y0, y1 = napier_row(k)
            lines.append((0, y0, W, y0, 0.3, INK))
            if d == "index":
                words.append((W / 2, (y0 + y1) / 2, str(k), 9, INK, True))
            else:
                v = d * k
                lines.append((0.6, y0 + 0.6, W - 0.6, y1 - 0.6, 0.25, INK))      # the diagonal
                words.append((4.6, y1 - 4.6, str(v // 10), 6.0, INK, False))   # tens, above it
                words.append((W - 4.6, y0 + 4.6, str(v % 10), 6.0, INK, False))  # units, below
    else:
        if d == "index":
            words.append((W / 2, TOP_CELL + CELL / 2, "×", 9, INK, True))
        else:
            words.append((W / 2, TOP_CELL + CELL / 2, str(d), 10, INK, True))
        for m in range(2, 10):
            y0, y1 = genaille_row(m)
            lines.append((0, y0, W, y0, 0.35, INK))
            if d == "index":
                words.append((5.0, (y0 + y1) / 2, str(m), min(8, m * E * 0.8), INK, True))
                for c in range(m):                       # the last carry: the product's first digit
                    yc = y1 - (c + 0.5) * E
                    words.append((W - 2.6, yc, str(c), 2.5, GREY if c == 0 else RED, True))
                continue
            vals = [d * m + c for c in range(m)]
            for c, v in enumerate(vals):
                yc = y1 - (c + 0.5) * E
                words.append((W - 3.0, yc, str(v % 10), 2.6, INK, True))
            # a triangle for each tens digit: base on the entries with it,
            # tip at the left edge, level with entry (tens) on the next rod
            for t in sorted(set(v // 10 for v in vals)):
                cs = [c for c, v in enumerate(vals) if v // 10 == t]
                ya, yb = y1 - cs[0] * E - 0.25, y1 - (cs[-1] + 1) * E + 0.25
                tip = y1 - (t + 0.5) * E
                polys.append(([(W - 5.6, ya), (W - 5.6, yb), (0.25, tip)], (90, 84, 76)))
    return lines, polys, words


def texture(kind, d, name):
    im = Image.new("RGB", (int(W * PX), int(H * PX)), FACE)
    g = ImageDraw.Draw(im)
    P = lambda x, y: (x * PX, (H - y) * PX)
    lines, polys, words = face(kind, d) if d != "blank" else ([], [], [])
    for pts, col in polys:
        g.polygon([P(x, y) for x, y in pts], fill=col)
    for x0, y0, x1, y1, w, col in lines:
        g.line([P(x0, y0), P(x1, y1)], fill=col, width=max(2, int(round(w * PX))))
    for x, y, t, h, col, b in words:
        f = ImageFont.truetype(FONTS + ("DejaVuSans-Bold.ttf" if b else "DejaVuSans.ttf"), int(h * PX))
        g.text(P(x, y), t, font=f, fill=col, anchor="mm")
    im.save(os.path.join(HERE, "faces", name + ".png"), optimize=True)


RODS = [(0, 1, 9, 8), (0, 2, 9, 7), (0, 3, 9, 6), (0, 4, 9, 5), (1, 2, 8, 7),
        (1, 3, 8, 6), (1, 4, 8, 5), (2, 3, 7, 6), (2, 4, 7, 5), (3, 4, 6, 5)]     # (as bones.lua)


def sheet(kind, title):
    """the strips to print: three to a row, two rows to a page"""
    strips = [(f"rod {r + 1}", RODS[r]) for r in range(10)] + [("the index rod", ("index", "blank", "blank", "blank"))]
    pages, out = [], None
    for i, (label, faces) in enumerate(strips):
        if i % 6 == 0:
            if out: pages.append(out)
            out = ['<svg xmlns="http://www.w3.org/2000/svg" width="210mm" height="297mm" viewBox="0 0 210 297">',
                   '<style>text{font-family:"DejaVu Sans",sans-serif}</style>',
                   f'<text x="12" y="10" font-size="4" font-weight="bold">{title}</text>',
                   '<text x="12" y="15" font-size="2.6">Print at 100% (actual size). Check the bar is 100 mm. Cut on the grey lines, '
                   'fold on the faint ones, and wrap each strip round its rod, the digits at the top end.</text>',
                   '<rect x="12" y="285" width="100" height="2.5" fill="black"/>',
                   '<text x="115" y="287.3" font-size="2.6">100 mm</text>']
        col, row = i % 3, (i % 6) // 3
        ox, oy = 12 + col * 64 + col * 4, 22 + row * (H + 6)
        out.append(f'<rect x="{ox}" y="{oy}" width="64" height="{H}" fill="none" stroke="#999" stroke-width="0.15"/>')
        for f, d in enumerate(faces):
            fx = ox + f * W
            if f:
                out.append(f'<line x1="{fx}" y1="{oy}" x2="{fx}" y2="{oy + H}" stroke="#ccc" stroke-width="0.1"/>')
            if d == "blank":
                continue
            lines, polys, words = face(kind, d)
            P = lambda x, y: (fx + x, oy + H - y)
            for pts, c in polys:
                pp = " ".join(f"{P(x, y)[0]:.3f},{P(x, y)[1]:.3f}" for x, y in pts)
                out.append(f'<polygon points="{pp}" fill="rgb{c}"/>')
            for x0, y0, x1, y1, w, c in lines:
                (a, b), (cc, e) = P(x0, y0), P(x1, y1)
                out.append(f'<line x1="{a:.3f}" y1="{b:.3f}" x2="{cc:.3f}" y2="{e:.3f}" stroke="rgb{c}" stroke-width="{w}"/>')
            for x, y, t, h, c, bo in words:
                a, b = P(x, y)
                wt = ' font-weight="bold"' if bo else ""
                out.append(f'<text x="{a:.3f}" y="{b:.3f}" font-size="{h:.2f}" fill="rgb{c}" text-anchor="middle" '
                           f'dominant-baseline="central"{wt}>{t}</text>')
        out.append(f'<text x="{ox + 32}" y="{oy + H - 3}" font-size="2.2" fill="#888" text-anchor="middle">{label}</text>')
    pages.append(out)
    return ["\n".join(p + ["</svg>"]) for p in pages]


def pdf(pages, path):
    from playwright.sync_api import sync_playwright
    html = "<html><body style='margin:0'>" + "".join(
        f"<div style='page-break-after:always;width:210mm;height:297mm'>{p}</div>" for p in pages) + "</body></html>"
    with sync_playwright() as p:
        b = p.chromium.launch()
        pg = b.new_page()
        pg.set_content(html)
        pg.pdf(path=path, width="210mm", height="297mm", margin={"top": "0", "bottom": "0", "left": "0", "right": "0"},
               print_background=True)
        b.close()


if __name__ == "__main__":
    os.makedirs(os.path.join(HERE, "faces"), exist_ok=True)
    for kind in ("napier", "genaille"):
        for d in range(10):
            texture(kind, d, f"{kind}-{d}")
        texture(kind, "index", f"{kind}-index")
    texture("napier", "blank", "blank")
    pdf(sheet("napier", "NAPIER'S BONES: the faces, full size"), os.path.join(HERE, "napier-faces.pdf"))
    pdf(sheet("genaille", "GENAILLE'S RODS: the faces, full size"), os.path.join(HERE, "genaille-faces.pdf"))
    print("faces/*.png, napier-faces.pdf, genaille-faces.pdf")
