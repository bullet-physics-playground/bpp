#!/usr/bin/env python3
"""Typeset one of the hall's Markdown files as a PDF beside it.

Usage, from demo/WyomingWill/BabbagesHall:
  python3 tools/md2pdf.py exhibits/Pascaline/README.md \
      --sub "West bay 3: Pascal's adding machine" [--break "Printing and building"]
  ./make-pdfs.sh            (every .md file in the hall)

Every .md file in the hall has a .pdf beside it, rebuilt whenever the .md
changes; make-pdfs.sh does them all.

Needs: pip install markdown playwright (Chromium; in the cloud workspace it is
preinstalled under /opt/pw-browsers). Uses the DejaVu fonts if Google Fonts
can't be reached.

--break starts the section whose heading begins with that text on a new page.
"""
import argparse, base64, datetime, os, re, sys
import markdown
from playwright.sync_api import sync_playwright

CSS = """
@page { size: Letter; margin: 0.65in 0.65in 0.7in 0.65in; }
:root { --ink:#231c15; --muted:#6b5d4f; --rule:#d8cbb6; --accent:#7a2a1d; --brass:#a67c2e; --band:#f6efe2; }
body { font-family:'Libre Baskerville','DejaVu Serif',Georgia,serif; color:var(--ink); font-size:9.4pt; line-height:1.5; }
.hall { font-family:'Inter','DejaVu Sans',Arial,sans-serif; font-size:7.6pt; letter-spacing:2.4pt; text-transform:uppercase; color:var(--brass); margin-bottom:3pt; }
h1.title { font-size:22pt; margin:0 0 2pt; font-weight:700; }
.sub { color:var(--muted); font-size:10pt; font-style:italic; margin-bottom:14pt; padding-bottom:8pt;
       border-bottom:3px double var(--brass); }
h2 { font-size:13.5pt; color:var(--accent); margin:18pt 0 6pt; break-after:avoid; }
h3 { font-size:11pt; margin:13pt 0 4pt; break-after:avoid; }
p { margin:4pt 0 6pt; } li p { margin:2pt 0 4pt; }
ul, ol { margin:3pt 0 6pt; padding-left:18pt; } li { margin:1.5pt 0; }
hr { border:0; border-top:1px solid var(--rule); margin:14pt 0; }
code { font-family:'JetBrains Mono','DejaVu Sans Mono',monospace; font-size:8.1pt; background:var(--band); padding:0 2pt; border-radius:2pt; }
pre { background:var(--band); padding:6pt 8pt; border-left:2px solid var(--brass); white-space:pre-wrap; }
pre code { padding:0; background:none; }
table { border-collapse:collapse; width:100%; margin:4pt 0 10pt; font-size:8pt; line-height:1.35;
        font-family:'Inter','DejaVu Sans',Arial,sans-serif; }
th { text-align:left; background:var(--band); border-bottom:1.5px solid var(--brass); padding:3pt 4pt; font-weight:600; }
td { border-bottom:1px solid var(--rule); padding:2.6pt 4pt; vertical-align:top; }
tr { break-inside:avoid; }
img { max-width:100%; max-height:6.0in; display:block; margin:6pt auto 3pt; }
figure { margin:6pt 0 10pt; break-inside:avoid; }
figcaption { font-size:8pt; font-style:italic; color:var(--muted); text-align:center; margin:0 0.4in; }
"""

def embed_images(body, base):
    """images given by a path relative to the .md file go into the page itself (the page has no folder)"""
    def one(m):
        src = m.group(2)
        path = os.path.join(base, src)
        if re.match(r"[a-z]+:", src) or not os.path.exists(path):
            return m.group(0)
        kind = {"png": "png", "jpg": "jpeg", "jpeg": "jpeg", "svg": "svg+xml"}.get(src.rsplit(".", 1)[-1].lower(), "png")
        data = base64.b64encode(open(path, "rb").read()).decode()
        return f'{m.group(1)}data:image/{kind};base64,{data}{m.group(3)}'
    body = re.sub(r'(<img[^>]*?src=")([^"]+)(")', one, body)
    # (an image alone in its paragraph is a figure, its alt text the caption)
    return re.sub(r'<p>(<img[^>]*?alt="([^"]*)"[^>]*>)</p>', r'<figure>\1<figcaption>\2</figcaption></figure>', body)

def to_html(md, title, sub, breaks, base="."):
    md = re.sub(r"\A# (.*)\n", "", md, count=1)                    # the file's own title (shown above)
    md = re.sub(r"(?m)^`[^`]+\.pdf` beside this file is a typeset copy of it\.\n\n?", "", md)
    body = embed_images(markdown.markdown(md, extensions=["tables", "sane_lists", "fenced_code"]), base)
    for b in breaks:
        body = body.replace(f"<h2>{b}", f'<h2 style="break-before:page">{b}', 1)
    return f"""<!doctype html><html><head><meta charset="utf-8">
<link href="https://fonts.googleapis.com/css2?family=Libre+Baskerville:ital,wght@0,400;0,700;1,400&family=Inter:wght@400;600&family=JetBrains+Mono&display=swap" rel="stylesheet">
<style>{CSS}</style></head><body>
<div class="hall">Babbage's Hall &middot; Engines of Calculation</div>
<h1 class="title">{title}</h1><div class="sub">{sub}</div>
{body}</body></html>"""

def main():
    a = argparse.ArgumentParser()
    a.add_argument("src")
    a.add_argument("out", nargs="?")
    a.add_argument("--sub", default="")
    a.add_argument("--break", dest="breaks", action="append", default=[])
    o = a.parse_args()
    out = o.out or os.path.splitext(o.src)[0] + ".pdf"
    md = open(o.src, encoding="utf-8").read()
    m = re.match(r"# (.*)", md)
    title = m.group(1) if m else os.path.basename(o.src)
    date = datetime.date.today().strftime("%-d %B %Y")
    html = to_html(md, title, f"{o.sub} &middot; {date}" if o.sub else date, o.breaks, os.path.dirname(os.path.abspath(o.src)))
    footer = ('<div style="font-family:Georgia,serif;font-size:7.5pt;color:#6b5d4f;width:100%;padding:0 0.65in;'
              'display:flex;justify-content:space-between"><span>Babbage\'s Hall &middot; ' + title +
              '</span><span><span class="pageNumber"></span> / <span class="totalPages"></span></span></div>')
    with sync_playwright() as p:
        b = p.chromium.launch(); pg = b.new_page()
        pg.set_content(html)
        try: pg.wait_for_load_state("networkidle", timeout=8000)
        except Exception: pass
        pg.pdf(path=out, format="Letter", print_background=True, prefer_css_page_size=True,
               display_header_footer=True, header_template="<span></span>", footer_template=footer)
        b.close()
    print("wrote", out)

if __name__ == "__main__":
    sys.exit(main())
