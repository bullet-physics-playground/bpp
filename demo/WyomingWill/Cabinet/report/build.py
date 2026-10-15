#!/usr/bin/env python3
import os, re, sys
from reportlab.lib.pagesizes import letter
from reportlab.lib.units import inch
from reportlab.lib import colors
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.enums import TA_LEFT, TA_CENTER
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (BaseDocTemplate, PageTemplate, Frame, Paragraph, Spacer, Table, TableStyle,
                                PageBreak, KeepTogether, Preformatted, NextPageTemplate, CondPageBreak)
from reportlab.platypus.tableofcontents import TableOfContents

sys.path.insert(0, os.path.dirname(__file__))
import front as F

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "physics-fidelity-report.pdf")

FD = "/usr/share/fonts/truetype/dejavu/"
pdfmetrics.registerFont(TTFont("Sans", FD + "DejaVuSans.ttf"))
pdfmetrics.registerFont(TTFont("Sans-Bold", FD + "DejaVuSans-Bold.ttf"))
pdfmetrics.registerFont(TTFont("Sans-Oblique", FD + "DejaVuSans-Oblique.ttf"))
pdfmetrics.registerFont(TTFont("Sans-BoldOblique", FD + "DejaVuSans-BoldOblique.ttf"))
pdfmetrics.registerFont(TTFont("Mono", FD + "DejaVuSansMono.ttf"))
from reportlab.pdfbase.pdfmetrics import registerFontFamily
registerFontFamily("Sans", normal="Sans", bold="Sans-Bold", italic="Sans-Oblique", boldItalic="Sans-BoldOblique")

INK = colors.HexColor("#1f2328")
MUTED = colors.HexColor("#57606a")
ACCENT = colors.HexColor("#7a4a24")       # walnut
RULE = colors.HexColor("#d0d7de")
HEAD_BG = colors.HexColor("#f3ede4")
OKC, DOCC, CAVC, ISSC = colors.HexColor("#1a7f37"), colors.HexColor("#9a6700"), colors.HexColor("#bc4c00"), colors.HexColor("#cf222e")
COL = {"OK": OKC, "DOC": DOCC, "CAVEAT": CAVC, "ISSUE": ISSC}
SHORT = {"OK": "Agrees", "DOC": "Agrees; text to fix", "CAVEAT": "Agrees, with caveats", "ISSUE": "Problem found"}
LONG = {"OK": "Agrees with theory", "DOC": "Agrees with theory; documentation to correct",
        "CAVEAT": "Agrees with theory, with a numerical or open caveat", "ISSUE": "Problem found"}

S = {
    "title": ParagraphStyle("title", fontName="Sans-Bold", fontSize=24, leading=30, textColor=INK, spaceAfter=10),
    "subtitle": ParagraphStyle("subtitle", fontName="Sans", fontSize=13, leading=18, textColor=MUTED, spaceAfter=4),
    "h1": ParagraphStyle("h1", fontName="Sans-Bold", fontSize=17, leading=22, textColor=ACCENT, spaceBefore=6, spaceAfter=8),
    "h2": ParagraphStyle("h2", fontName="Sans-Bold", fontSize=13, leading=17, textColor=INK, spaceBefore=10, spaceAfter=5),
    "h3": ParagraphStyle("h3", fontName="Sans-Bold", fontSize=10.5, leading=14, textColor=ACCENT, spaceBefore=8, spaceAfter=3),
    "body": ParagraphStyle("body", fontName="Sans", fontSize=9.2, leading=13, textColor=INK, spaceAfter=5),
    "bullet": ParagraphStyle("bullet", fontName="Sans", fontSize=9.2, leading=12.6, textColor=INK, leftIndent=12,
                             bulletIndent=2, spaceAfter=2.5),
    "cell": ParagraphStyle("cell", fontName="Sans", fontSize=7.6, leading=9.6, textColor=INK),
    "cellb": ParagraphStyle("cellb", fontName="Sans-Bold", fontSize=7.6, leading=9.6, textColor=INK),
    "code": ParagraphStyle("code", fontName="Mono", fontSize=6.6, leading=8.2, textColor=INK),
    "small": ParagraphStyle("small", fontName="Sans", fontSize=8, leading=10.5, textColor=MUTED),
    "toc1": ParagraphStyle("toc1", fontName="Sans-Bold", fontSize=10, leading=15, leftIndent=0),
    "toc2": ParagraphStyle("toc2", fontName="Sans", fontSize=9, leading=13, leftIndent=14),
}

def esc(t):
    return t.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")

def inline(t):
    """markdown inline -> reportlab markup"""
    t = esc(t)
    t = re.sub(r"\*\*(.+?)\*\*", r"<b>\1</b>", t)
    t = re.sub(r"(?<![\w*])\*(?!\s)(.+?)(?<!\s)\*(?![\w*])", r"<i>\1</i>", t)
    t = re.sub(r"`([^`]+)`", r'<font face="Mono" size="8">\1</font>', t)
    # x^2 style: superscripts for simple exponents
    t = re.sub(r"\^\(([^()]{1,12})\)", r"<super>\1</super>", t)
    t = re.sub(r"\^(-?[0-9.]+|[a-zA-Z])", r"<super>\1</super>", t)
    return t

class Doc(BaseDocTemplate):
    def __init__(self, fn, **kw):
        super().__init__(fn, pagesize=letter, leftMargin=0.8 * inch, rightMargin=0.8 * inch,
                         topMargin=0.8 * inch, bottomMargin=0.75 * inch,
                         title="Euler's Cabinet of Curiosities: physics fidelity report",
                         author="Claude, for WyomingWill", subject="How each exhibit was tested against theory", **kw)
        fr = Frame(self.leftMargin, self.bottomMargin, self.width, self.height, id="f")
        self.addPageTemplates([PageTemplate(id="cover", frames=[fr], onPage=lambda c, d: None),
                               PageTemplate(id="body", frames=[fr], onPage=self.decorate)])
    def decorate(self, c, d):
        c.saveState()
        c.setFont("Sans", 7.5)
        c.setFillColor(MUTED)
        c.drawString(self.leftMargin, 0.45 * inch, "Euler's Cabinet of Curiosities: physics fidelity report")
        c.drawRightString(self.leftMargin + self.width, 0.45 * inch, "page %d" % d.page)
        c.setStrokeColor(RULE)
        c.line(self.leftMargin, 0.6 * inch, self.leftMargin + self.width, 0.6 * inch)
        c.restoreState()
    def afterFlowable(self, fl):
        if isinstance(fl, Paragraph) and getattr(fl, "toc_level", None) is not None:
            self.notify("TOCEntry", (fl.toc_level, fl.getPlainText(), self.page, getattr(fl, "toc_key", None)))

def heading(text, style, level=None, key=None):
    p = Paragraph(text, S[style])
    if level is not None:
        p.toc_level = level
        if key:
            p.toc_key = key
            p = Paragraph('<a name="%s"/>%s' % (key, text), S[style])
            p.toc_level, p.toc_key = level, key
    return p

def mdtable(rows, widths=None):
    def cells_of(r):
        r = r.strip().replace("\\|", "\x00").strip("|")
        return [c.strip().replace("\x00", "|") for c in r.split("|")]
    hdr = cells_of(rows[0])
    body = []
    for r in rows[2:]:
        cells = cells_of(r)
        cells += [""] * (len(hdr) - len(cells))
        body.append(cells[: len(hdr)])
    n = len(hdr)
    W = 6.9 * inch
    if not widths:
        if n == 4:
            widths = [0.2, 0.32, 0.3, 0.18]
        else:
            lens = [max(len(r[i]) for r in [hdr] + body) + 4 for i in range(n)]
            tot = sum(lens)
            widths = [max(0.08, l / tot) for l in lens]
            s = sum(widths)
            widths = [w / s for w in widths]
    data = [[Paragraph(inline(h), S["cellb"]) for h in hdr]] + [[Paragraph(inline(c), S["cell"]) for c in r] for r in body]
    t = Table(data, colWidths=[w * W for w in widths], repeatRows=1)
    t.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), HEAD_BG),
        ("LINEBELOW", (0, 0), (-1, 0), 0.6, ACCENT),
        ("LINEBELOW", (0, 1), (-1, -1), 0.25, RULE),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 3.5), ("RIGHTPADDING", (0, 0), (-1, -1), 3.5),
        ("TOPPADDING", (0, 0), (-1, -1), 2.5), ("BOTTOMPADDING", (0, 0), (-1, -1), 2.5),
    ]))
    return t

def code(lines):
    out = []
    for ln in lines:
        ln = ln.rstrip("\n")
        while len(ln) > 118:
            cut = ln.rfind(" ", 60, 118)
            cut = cut if cut > 0 else 118
            out.append(ln[:cut]); ln = "    " + ln[cut:].lstrip()
        out.append(ln)
    p = Preformatted("\n".join(out), S["code"])
    t = Table([[p]], colWidths=[6.9 * inch])
    t.setStyle(TableStyle([("BACKGROUND", (0, 0), (-1, -1), colors.HexColor("#f6f8fa")),
                           ("BOX", (0, 0), (-1, -1), 0.4, RULE),
                           ("LEFTPADDING", (0, 0), (-1, -1), 5), ("TOPPADDING", (0, 0), (-1, -1), 4),
                           ("BOTTOMPADDING", (0, 0), (-1, -1), 4)]))
    return t

SECTION_LABELS = ("What it shows", "Model", "Theory checks", "Run used", "Known departures and honest caveats", "References")

def dossier(folder, num):
    lines = open(os.path.join(HERE, "dossiers", folder + ".md"), encoding="utf-8").read().splitlines()
    flow = []
    i = 0
    para = []
    def flush():
        if para:
            flow.append(Paragraph(inline(" ".join(para)), S["body"]))
            para.clear()
    while i < len(lines):
        ln = lines[i]
        st = ln.strip()
        if st.startswith("## "):
            flush()
            i += 1
            continue                                    # (the title comes from the report)
        m = re.match(r"^\*\*(%s)\*\*\s*(?:\(([^)]*)\))?\s*(?:—|-|:)?\s*(.*)$" % "|".join(re.escape(s) for s in SECTION_LABELS), st)
        if m:
            flush()
            label, note, rest = m.group(1), m.group(2), m.group(3)
            flow.append(Paragraph(label + (' <font size="8" color="#57606a">(%s)</font>' % esc(note) if note else ""), S["h3"]))
            if rest:
                para.append(rest)
            i += 1
            continue
        if st.startswith("```"):
            flush()
            j = i + 1
            block = []
            while j < len(lines) and not lines[j].strip().startswith("```"):
                block.append(lines[j]); j += 1
            flow.append(code(block))
            flow.append(Spacer(1, 4))
            i = j + 1
            continue
        if st.startswith("|"):
            flush()
            rows = []
            while i < len(lines) and lines[i].strip().startswith("|"):
                rows.append(lines[i]); i += 1
            flow.append(mdtable(rows))
            flow.append(Spacer(1, 5))
            continue
        bm = re.match(r"^(\s*)[-*] (.*)$", ln)
        if bm:
            flush()
            indent = len(bm.group(1))
            txt = bm.group(2)
            j = i + 1
            while j < len(lines) and lines[j].strip() and not re.match(r"^\s*[-*] ", lines[j]) and not lines[j].strip().startswith(("|", "```", "**")) and lines[j].startswith(" "):
                txt += " " + lines[j].strip(); j += 1
            st2 = ParagraphStyle("b%d" % indent, parent=S["bullet"], leftIndent=12 + indent * 5, bulletIndent=2 + indent * 5)
            flow.append(Paragraph(inline(txt), st2, bulletText="•" if indent == 0 else "◦"))
            i = j
            continue
        if not st:
            flush(); i += 1; continue
        para.append(st)
        i += 1
    flush()
    return flow

def count_checks(folder):
    t, n = False, 0
    for ln in open(os.path.join(HERE, "dossiers", folder + ".md"), encoding="utf-8"):
        if ln.startswith("**Theory checks"):
            t = True; continue
        if t and ln.startswith("**Run used"):
            break
        if t and ln.strip().startswith("|"):
            n += 1
    return max(0, n - 2)

def status_cell(code_):
    col, txt = COL[code_], SHORT[code_]
    return Paragraph('<font color="%s"><b>%s</b></font>' % (col.hexval().replace("0x", "#"), txt), S["cell"])

story = []
# ---- cover
story += [Spacer(1, 1.6 * inch),
          Paragraph("Euler's Cabinet of Curiosities", S["title"]),
          Paragraph("Physics fidelity report: how each of the 21 exhibits is simulated, and how it was tested against theory", S["subtitle"]),
          Spacer(1, 18),
          Paragraph("Bullet Physics Playground (bpp), demo/WyomingWill", S["body"]),
          Paragraph("Every exhibit run afresh on %s, and run again after the fixes described in section 2" % F.DATE, S["body"]),
          Spacer(1, 30)]
allchecks = sum(count_checks(f) for _, fs in F.ORDER for f in fs)
counts = {"OK": 0, "DOC": 0, "CAVEAT": 0, "ISSUE": 0}
for k, (c, _) in F.SUMMARY.items():
    counts[c] += 1
def cnt(c, txt): return Paragraph('<font color="%s"><b>%d</b></font> %s' % (COL[c].hexval().replace("0x", "#"), counts[c], txt), S["body"])
cells = [cnt(c, t) for c, t in [("OK", "agree"), ("DOC", "agree; their documentation needs correcting"),
                                 ("CAVEAT", "agree, with a numerical or open caveat"),
                                 ("ISSUE", "with a problem in the simulation or its checks")] if counts[c]]
if len(cells) % 2: cells.append(Paragraph("", S["body"]))
box = Table([[Paragraph("<b>%d</b> exhibits" % 21, S["body"]), Paragraph("<b>%d</b> checks against theory, tabulated" % allchecks, S["body"])]]
            + [cells[i:i + 2] for i in range(0, len(cells), 2)],
            colWidths=[3.2 * inch, 3.7 * inch])
box.setStyle(TableStyle([("BOX", (0, 0), (-1, -1), 0.6, ACCENT), ("BACKGROUND", (0, 0), (-1, -1), colors.HexColor("#fbf8f3")),
                         ("LEFTPADDING", (0, 0), (-1, -1), 8), ("TOPPADDING", (0, 0), (-1, -1), 6), ("BOTTOMPADDING", (0, 0), (-1, -1), 4)]))
story += [box, NextPageTemplate("body"), PageBreak()]

# ---- contents
story.append(Paragraph("Contents", S["h1"]))
toc = TableOfContents()
toc.levelStyles = [S["toc1"], S["toc2"]]
story += [toc, PageBreak()]

# ---- 1. summary
story.append(heading("1. Summary", "h1", 0))
for t in F.INTRO:
    story.append(Paragraph(inline(t), S["body"]))
story.append(Spacer(1, 6))
for wing, fs in F.ORDER:
    rows = [[Paragraph("<b>Exhibit</b>", S["cellb"]), Paragraph("<b>Checks</b>", S["cellb"]),
             Paragraph("<b>Headline result</b>", S["cellb"]), Paragraph("<b>Status</b>", S["cellb"])]]
    for f in fs:
        c, txt = F.SUMMARY[f]
        rows.append([Paragraph(F.NAMES[f], S["cell"]), Paragraph(str(count_checks(f)), S["cell"]),
                     Paragraph(inline(txt), S["cell"]), status_cell(c)])
    t = Table(rows, colWidths=[1.25 * inch, 0.62 * inch, 4.03 * inch, 1.0 * inch], repeatRows=1)
    t.setStyle(TableStyle([("BACKGROUND", (0, 0), (-1, 0), HEAD_BG), ("LINEBELOW", (0, 0), (-1, 0), 0.6, ACCENT),
          ("LINEBELOW", (0, 1), (-1, -1), 0.25, RULE), ("VALIGN", (0, 0), (-1, -1), "TOP"),
          ("LEFTPADDING", (0, 0), (-1, -1), 3.5), ("RIGHTPADDING", (0, 0), (-1, -1), 3.5),
          ("TOPPADDING", (0, 0), (-1, -1), 2.5), ("BOTTOMPADDING", (0, 0), (-1, -1), 2.5)]))
    story += [CondPageBreak(2.2 * inch), Paragraph(wing, S["h3"]), t, Spacer(1, 6)]
story += [PageBreak()]

# ---- 2. findings
story.append(heading("2. What was found, and what was done", "h1", 0))
story.append(Paragraph("A first pass of this report, earlier on 15 October 2026, ran every exhibit afresh and read its output against its README and code. What it found was fixed the same day, and the exhibits that changed were run again; the numbers in sections 4 and 5 are from those runs. First the fixes to simulations and their checks, then to the documentation, then what is still open.", S["body"]))
for title, items in (("2.1 Fixed: the simulations and their checks", F.FIXED_SIM),
                     ("2.2 Fixed: the documentation", F.FIXED_DOC),
                     ("2.3 Still open", F.OPEN)):
    story.append(heading(title, "h2", 1))
    for who, txt in items:
        story.append(Paragraph("<b>%s.</b> %s" % (esc(who), inline(txt)), S["bullet"], bulletText="•"))
story.append(PageBreak())

# ---- 3. methods
story.append(heading("3. How the gallery is simulated and checked", "h1", 0))
for title, txt in F.METHODS:
    story.append(Paragraph(esc(title), S["h3"]))
    story.append(Paragraph(inline(txt), S["body"]))
story.append(PageBreak())

# ---- 4/5. exhibits
sec = 4
for wing, fs in F.ORDER:
    story.append(heading("%d. %s" % (sec, wing), "h1", 0))
    for k, f in enumerate(fs, 1):
        if k > 1:
            story.append(CondPageBreak(2.5 * inch))
        c, txt = F.SUMMARY[f]
        story.append(heading("%d.%d %s" % (sec, k, F.NAMES[f]), "h2", 1, key=f))
        col, lab = COL[c], LONG[c]
        story.append(Paragraph('<font color="%s"><b>%s.</b></font> %s' % (col.hexval().replace("0x", "#"), lab, inline(txt)), S["small"]))
        story.append(Paragraph('<font size="7.5" color="#57606a">Folder: demo/WyomingWill/%s/</font>' % f, S["small"]))
        story += dossier(f, k)
        story.append(Spacer(1, 8))
    sec += 1
    story.append(PageBreak())

doc = Doc(OUT)
doc.multiBuild(story)
print("wrote", OUT)
