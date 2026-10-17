#!/usr/bin/env python3
"""Typeset BOOK.md, WORKFLOW.md (or any plan file here) as a PDF.

Usage, from demo/WyomingWill/ArtificialPhysics:
  python3 tools/md2pdf.py BOOK.md BOOK.pdf \
      --sub "The whole book in Bullet Physics Playground: the plan" \
      --footer "Physicomimetics in 3D with real vehicles: the plan" \
      --break "2. Shared groundwork" --break "8. Build order"
  python3 tools/md2pdf.py WORKFLOW.md WORKFLOW.pdf \
      --sub "How the work is organised" \
      --footer "Physicomimetics in 3D with real vehicles: how the work is organised"

Needs: pip install markdown playwright (Chromium; in the cloud workspace it is
preinstalled under /opt/pw-browsers). Fonts load from Google Fonts, so it needs
network access; without it the page falls back to system fonts.

--break starts the section whose heading begins with that text on a new page.
After building, look at the pages: move or drop breaks so no page is left
nearly empty and the build-order table stays on one page.
"""
import argparse, datetime, re, sys
import markdown
from playwright.sync_api import sync_playwright

CSS = """
@page { size: Letter; margin: 0.65in 0.6in 0.7in 0.6in; }
:root { --ink:#1d2430; --muted:#5b6575; --rule:#d9dee6; --accent:#1f6f8b; --band:#f3f6f9; }
body { font-family:'Inter','Helvetica Neue',Arial,sans-serif; color:var(--ink); font-size:9.3pt; line-height:1.45; }
h1.title { font-size:21pt; margin:0 0 2pt; letter-spacing:-0.2pt; }
.sub { color:var(--muted); font-size:10pt; margin-bottom:14pt; border-bottom:2px solid var(--accent); padding-bottom:8pt; }
h2 { font-size:14pt; color:var(--accent); margin:20pt 0 6pt; break-after:avoid; }
h3 { font-size:11pt; margin:14pt 0 4pt; break-after:avoid; }
p { margin:4pt 0 6pt; } li p { margin:2pt 0 4pt; }
ul, ol { margin:3pt 0 6pt; padding-left:18pt; } li { margin:1.5pt 0; }
hr { border:0; border-top:1px solid var(--rule); margin:14pt 0; }
code { font-family:'JetBrains Mono','DejaVu Sans Mono',monospace; font-size:8.3pt; background:var(--band); padding:0 2pt; border-radius:2pt; }
table { border-collapse:collapse; width:100%; margin:4pt 0 10pt; font-size:7.9pt; line-height:1.3; }
th { text-align:left; background:var(--band); border-bottom:1.5px solid var(--accent); padding:3pt 4pt; font-weight:600; }
td { border-bottom:1px solid var(--rule); padding:2.6pt 4pt; vertical-align:top; }
tr { break-inside:avoid; }
td.st { white-space:nowrap; }
.chip { display:inline-block; padding:0.5pt 4pt; border-radius:6pt; font-size:7.2pt; font-weight:600; }
.chip.done { background:#dff2e3; color:#1e6b34; } .chip.partly { background:#fff1d6; color:#8a5a00; }
.chip.plan { background:#e1eef7; color:#1f5f86; } .chip.new { background:#efe5f7; color:#6a3b8f; }
"""

def to_html(md, title, sub, breaks):
    md = re.sub(r"\A# .*\n", "", md, count=1)                      # the file's own title
    md = re.sub(r"`[A-Z]+\.pdf` beside this file is a typeset copy of it\.\n\n", "", md)
    md = re.sub(r" `[A-Z]+\.pdf` beside\nit is a typeset copy\.", "", md)
    md = re.sub(r"(?m)^ {3}(?=\S)", "    ", md)                     # 3-space list indents
    md = re.sub(r"(?m)^(?=\d+\. \*\*)", "\n", md)                   # blank line before numbered items
    md = re.sub(r"(?m)^(\d+\. .*)\n(?= {4}- )", r"\1\n\n", md)
    body = markdown.markdown(md, extensions=["tables", "sane_lists"])

    def chip(m):                                                   # status chips in Status columns
        t = m.group(1); key = t.split()[0].strip("()").lower()
        if key not in ("done", "partly", "plan", "new") or len(t) > 40: return m.group(0)
        return f'<td class="st"><span class="chip {key}">{t}</span></td>'
    parts = re.split(r"(<table>.*?</table>)", body, flags=re.S)
    body = "".join(re.sub(r"<td>((?:done|partly|plan|new)[^<]*)</td>(?=\s*</tr>)", chip, x)
                   if x.startswith("<table>") and "<th>Status</th>" in x else x for x in parts)
    for b in breaks:
        body = body.replace(f"<h2>{b}", f'<h2 style="break-before:page">{b}', 1)
    return f"""<!doctype html><html><head><meta charset="utf-8">
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&family=JetBrains+Mono:wght@400&display=swap" rel="stylesheet">
<style>{CSS}</style></head><body>
<h1 class="title">{title}</h1><div class="sub">{sub}</div>
{body}</body></html>"""

def main():
    a = argparse.ArgumentParser()
    a.add_argument("src"); a.add_argument("out")
    a.add_argument("--title", default="Physicomimetics in 3D with real vehicles")
    a.add_argument("--sub", default="")
    a.add_argument("--footer", default="Physicomimetics in 3D with real vehicles")
    a.add_argument("--break", dest="breaks", action="append", default=[])
    o = a.parse_args()
    date = datetime.date.today().strftime("%-d %B %Y")
    html = to_html(open(o.src).read(), o.title, f"{o.sub} · {date}" if o.sub else date, o.breaks)
    footer = ('<div style="font-family:Arial;font-size:7.5pt;color:#5b6575;width:100%;padding:0 0.6in;'
              'display:flex;justify-content:space-between"><span>' + o.footer +
              '</span><span><span class="pageNumber"></span> / <span class="totalPages"></span></span></div>')
    with sync_playwright() as p:
        b = p.chromium.launch(); pg = b.new_page()
        pg.set_content(html)
        try: pg.wait_for_load_state("networkidle", timeout=15000)
        except Exception: pass
        pg.pdf(path=o.out, format="Letter", print_background=True, prefer_css_page_size=True,
               display_header_footer=True, header_template="<span></span>", footer_template=footer)
        b.close()
    print("wrote", o.out)

if __name__ == "__main__":
    sys.exit(main())
