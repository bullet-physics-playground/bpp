"""Build guide PDF for the weighted 37-corner monostable polyhedron (reportlab,
DejaVu fonts as report/build.py). Reads the numbers from final/ (summaries, props,
robustness logs, simulation tallies, extra.json from make_extra.py) and runs/materials.json,
and the figures and slicer checks from final/ or, if not there, ../../print/w37/.
usage (from this folder): python3 make_extra.py && python3 build_guide.py
  ->  ../../print/w37/w37-build-guide.pdf"""
import json, re, os, glob
from reportlab.lib.pagesizes import letter
from reportlab.lib.units import inch, mm
from reportlab.lib import colors
from reportlab.lib.styles import ParagraphStyle
from reportlab.platypus import (BaseDocTemplate, PageTemplate, Frame, Paragraph, Spacer, Table, TableStyle,
                                Image, PageBreak, KeepTogether, NextPageTemplate, CondPageBreak)
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfbase.pdfmetrics import registerFontFamily

FD = "/usr/share/fonts/truetype/dejavu/"
pdfmetrics.registerFont(TTFont("Sans", FD + "DejaVuSans.ttf"))
pdfmetrics.registerFont(TTFont("Sans-Bold", FD + "DejaVuSans-Bold.ttf"))
pdfmetrics.registerFont(TTFont("Sans-Oblique", FD + "DejaVuSans-Oblique.ttf"))
pdfmetrics.registerFont(TTFont("Sans-BoldOblique", FD + "DejaVuSans-BoldOblique.ttf"))
pdfmetrics.registerFont(TTFont("Mono", FD + "DejaVuSansMono.ttf"))
registerFontFamily("Sans", normal="Sans", bold="Sans-Bold", italic="Sans-Oblique", boldItalic="Sans-BoldOblique")

INK = colors.HexColor("#1f2328"); MUTED = colors.HexColor("#57606a"); ACCENT = colors.HexColor("#7a4a24")
RULE = colors.HexColor("#d0d7de"); HEAD_BG = colors.HexColor("#f3ede4"); NOTE_BG = colors.HexColor("#f6f8fa")
WARN_BG = colors.HexColor("#fff4e5"); WARN = colors.HexColor("#9a3d00"); GOOD = colors.HexColor("#1a7f37")
S = {
    "title": ParagraphStyle("title", fontName="Sans-Bold", fontSize=23, leading=29, textColor=INK, spaceAfter=8),
    "subtitle": ParagraphStyle("subtitle", fontName="Sans", fontSize=12, leading=17, textColor=MUTED, spaceAfter=4),
    "h1": ParagraphStyle("h1", fontName="Sans-Bold", fontSize=16, leading=21, textColor=ACCENT, spaceBefore=4, spaceAfter=7),
    "h2": ParagraphStyle("h2", fontName="Sans-Bold", fontSize=12, leading=16, textColor=INK, spaceBefore=9, spaceAfter=4),
    "body": ParagraphStyle("body", fontName="Sans", fontSize=9.2, leading=13.2, textColor=INK, spaceAfter=5),
    "bullet": ParagraphStyle("bullet", fontName="Sans", fontSize=9.2, leading=12.8, textColor=INK, leftIndent=13, bulletIndent=3, spaceAfter=2.5),
    "step": ParagraphStyle("step", fontName="Sans", fontSize=9.2, leading=12.8, textColor=INK, leftIndent=20, bulletIndent=0, spaceAfter=4),
    "cell": ParagraphStyle("cell", fontName="Sans", fontSize=7.7, leading=9.8, textColor=INK),
    "cellb": ParagraphStyle("cellb", fontName="Sans-Bold", fontSize=7.7, leading=9.8, textColor=INK),
    "small": ParagraphStyle("small", fontName="Sans", fontSize=7.8, leading=10.4, textColor=MUTED, spaceAfter=4),
    "cap": ParagraphStyle("cap", fontName="Sans-Oblique", fontSize=7.8, leading=10.4, textColor=MUTED, spaceAfter=8),
    "key": ParagraphStyle("key", fontName="Sans-Bold", fontSize=17, leading=20, textColor=ACCENT),
    "keyl": ParagraphStyle("keyl", fontName="Sans", fontSize=7.8, leading=10, textColor=MUTED),
}
W_TXT = 6.9 * inch

class Doc(BaseDocTemplate):
    def __init__(self, fn, **kw):
        super().__init__(fn, pagesize=letter, leftMargin=0.8 * inch, rightMargin=0.8 * inch, topMargin=0.75 * inch,
                         bottomMargin=0.75 * inch, title="Weighted 37-corner monostable polyhedron: build guide",
                         author="Euler's Gallery", subject="FDM build of a discrete Gömböc with corner weights", **kw)
        fr = Frame(self.leftMargin, self.bottomMargin, self.width, self.height, id="f")
        self.addPageTemplates([PageTemplate(id="cover", frames=[fr], onPage=self.foot),
                               PageTemplate(id="body", frames=[fr], onPage=self.decorate)])
    def foot(self, c, d):
        pass
    def decorate(self, c, d):
        c.saveState(); c.setFont("Sans", 7.5); c.setFillColor(MUTED)
        c.drawString(self.leftMargin, 0.45 * inch, "Weighted 37-corner monostable polyhedron · build guide")
        c.drawRightString(self.leftMargin + self.width, 0.45 * inch, "page %d" % d.page)
        c.setStrokeColor(RULE); c.line(self.leftMargin, 0.6 * inch, self.leftMargin + self.width, 0.6 * inch)
        c.restoreState()

def P(t, st="body"): return Paragraph(t, S[st])
def B(t): return Paragraph(t, S["bullet"], bulletText="•")
def step(n, t): return Paragraph(t, S["step"], bulletText=f"{n}.")

def table(rows, widths, head=True, zebra=False, align_right=()):
    data = [[Paragraph(str(c), S["cellb" if (head and i == 0) else "cell"]) for c in r] for i, r in enumerate(rows)]
    t = Table(data, colWidths=[w * W_TXT for w in widths], repeatRows=1 if head else 0)
    st = [("LINEBELOW", (0, 1), (-1, -1), 0.25, RULE), ("VALIGN", (0, 0), (-1, -1), "TOP"),
          ("LEFTPADDING", (0, 0), (-1, -1), 3.5), ("RIGHTPADDING", (0, 0), (-1, -1), 3.5),
          ("TOPPADDING", (0, 0), (-1, -1), 2.6), ("BOTTOMPADDING", (0, 0), (-1, -1), 2.6)]
    if head: st += [("BACKGROUND", (0, 0), (-1, 0), HEAD_BG), ("LINEBELOW", (0, 0), (-1, 0), 0.6, ACCENT)]
    t.setStyle(TableStyle(st)); return t

def box(flows, bg=NOTE_BG, border=RULE):
    t = Table([[flows]], colWidths=[W_TXT])
    t.setStyle(TableStyle([("BACKGROUND", (0, 0), (-1, -1), bg), ("BOX", (0, 0), (-1, -1), 0.5, border),
                           ("LEFTPADDING", (0, 0), (-1, -1), 8), ("RIGHTPADDING", (0, 0), (-1, -1), 8),
                           ("TOPPADDING", (0, 0), (-1, -1), 6), ("BOTTOMPADDING", (0, 0), (-1, -1), 4)]))
    return t

def img(fn, width, maxh=None):
    from PIL import Image as PI
    w, h = PI.open(fn).size
    hh = width * h / w
    if maxh and hh > maxh: width = width * maxh / hh; hh = maxh
    return Image(fn, width=width, height=hh)

# ------------------------------------------------------------------ data
F = "final"
PR = "../../print/w37"          # the published print files (STL, PDF, figures, slicer checks)
def src(fn):
    """a design output: final/ (where finalize.sh writes it) or ../../print/w37/ (where it is published)"""
    return f"{F}/{fn}" if os.path.exists(f"{F}/{fn}") else f"{PR}/{fn}"
def J(fn): return json.load(open(fn))
REC = J(f"{F}/w37-W-summary.json"); ALT = J(f"{F}/w37-St-summary.json")
MAT = J("runs/materials.json")
SLC = J(src("w37-W.gcode.check.json")); SLC2 = J(src("w37-St.gcode.check.json")) if os.path.exists(src("w37-St.gcode.check.json")) else None
SIM = J(f"{F}/sim-tally.json") if os.path.exists(f"{F}/sim-tally.json") else None
EXTRA = J(f"{F}/extra.json")

def robust_rows(fn):
    rows = []
    for line in open(fn):
        m = re.match(r"(.{28}) +([\d.]+)% +([\d.]+)% +([\d.]+)% +([\d.]+)% +([-\d.na]+)", line)
        if m: rows.append([m.group(1).strip(), m.group(2), m.group(3), m.group(4), m.group(5), m.group(6)])
    return rows
RR = robust_rows(f"{F}/robust-W.log"); RA = robust_rows(f"{F}/robust-St.log")
def rget(rows, name):
    for r in rows:
        if r[0] == name: return r
    return None
def f1(x): return f"{x:.1f}"
def f2(x): return f"{x:.2f}"

def build():
    doc = Doc(f"{PR}/w37-build-guide.pdf")
    st = []
    WR = EXTRA["W"]; WA = EXTRA["St"]
    # ============================================================ cover
    st.append(Spacer(1, 4))
    st.append(P("Euler's Gallery · build guide", "subtitle"))
    st.append(P("A weighted 37-corner monostable polyhedron, printed in PLA", "title"))
    st.append(P(f"An apex above six regular hexagons (a Conway (6,6)-spiral after Domokos &amp; Kovács, 2023), "
                f"{REC['H']:.0f} mm tall, with a tungsten weight sealed into every one of its 37 corners. "
                "Set down on any face, it tips band by band onto its base; it has one stable face and one unstable corner.", "subtitle"))
    st.append(Spacer(1, 6))
    keys = [(f"{REC['H']:.0f}&nbsp;mm", "tall; fits a 220 × 220 mm bed, needs ≥ 205 mm of Z"),
            (f"{REC['M']:.0f} g", f"37 × {WR['wm']:.2f} g tungsten + {REC['m_pla']:.0f} g PLA"),
            (f"{min(REC['face'], REC['vert']):.1f}&nbsp;mm", "smallest margin (how far the centre of mass could move before a second rest face or balance point appears)"),
            (f"{WR['p2']}%", "of simulated builds with every face independently 0.2 mm off still rest on one face only; 100% under a layer-by-layer FDM error model")]
    kt = Table([[Paragraph(k, S["key"]), Paragraph(l, S["keyl"])] for k, l in keys], colWidths=[1.25 * inch, 2.35 * inch])
    kt.setStyle(TableStyle([("VALIGN", (0, 0), (-1, -1), "MIDDLE"), ("LINEBELOW", (0, 0), (-1, -2), 0.25, RULE),
                            ("TOPPADDING", (0, 0), (-1, -1), 5), ("BOTTOMPADDING", (0, 0), (-1, -1), 5)]))
    cov = Table([[kt, img(src("w37-W-cutaway3d.png"), 3.2 * inch, 3.9 * inch)]], colWidths=[3.6 * inch, 3.3 * inch])
    cov.setStyle(TableStyle([("VALIGN", (0, 0), (-1, -1), "MIDDLE"), ("LEFTPADDING", (0, 0), (-1, -1), 0)]))
    st.append(cov)
    st.append(Spacer(1, 6))
    st.append(box([P("<b>Short answer to “could anything else be put in place of tungsten?”</b>", "body"),
                   P(EXTRA["answer"], "body")], bg=HEAD_BG, border=ACCENT))
    st.append(Spacer(1, 6))
    st.append(P("<b>Contents</b> 1 What it is and why it works · 2 What can replace tungsten · 3 Bill of materials · "
                "4 Printer and slicer settings · 5 Print and assembly, step by step · 6 Checks and fixes · 7 Safety · "
                "8 How sure are we: robustness, dynamics, uncertainties · 9 Files and references", "small"))
    st.append(NextPageTemplate("body")); st.append(PageBreak())

    # ============================================================ 1
    st.append(P("1  What it is and why it works", "h1"))
    for t in EXTRA["sec1"]: st.append(P(t))
    st.append(P("The theory in plain words", "h2"))
    for t in EXTRA["theory"]: st.append(B(t))
    st.append(P("Why a real build is harder than the mathematics", "h2"))
    for t in EXTRA["real"]: st.append(B(t))
    st.append(CondPageBreak(6.5 * inch))
    st.append(img(src("w37-W-section.png"), 5.6 * inch, 6.2 * inch))
    st.append(P(EXTRA["cap_section"], "cap"))
    st.append(box([P("<b>If you only want a polyhedron that always rights itself</b>", "body"), P(EXTRA["ppla_note"], "body")]))

    # ============================================================ 2
    st.append(PageBreak())
    st.append(P("2  What can replace tungsten", "h1"))
    for t in EXTRA["sec2"]: st.append(P(t))
    st.append(table(EXTRA["mat_table"], [0.25, 0.11, 0.1, 0.09, 0.1, 0.1, 0.25]))
    st.append(P(EXTRA["mat_note"], "small"))
    st.append(img(src("materials.png"), 6.3 * inch))
    st.append(P(EXTRA["cap_mat"], "cap"))
    for t in EXTRA["sec2b"]: st.append(B(t))

    # ============================================================ 3
    st.append(CondPageBreak(4 * inch))
    st.append(P("3  Bill of materials", "h1"))
    st.append(P("Recommended build (tungsten)", "h2"))
    st.append(table(EXTRA["bom_W"], [0.24, 0.1, 0.4, 0.26]))
    st.append(Spacer(1, 4))
    st.append(P("Cheapest option that works: hardened steel dowel pins (fragile: read Section 8 first)", "h2"))
    st.append(table(EXTRA["bom_St"], [0.24, 0.1, 0.4, 0.26]))
    st.append(Spacer(1, 4))
    for t in EXTRA["bom_notes"]: st.append(B(t))

    # ============================================================ 4
    st.append(P("4  Printer and slicer settings", "h1"))
    st.append(table(EXTRA["settings"], [0.27, 0.27, 0.46]))
    st.append(Spacer(1, 4))
    for t in EXTRA["slicer_notes"]: st.append(B(t))

    # ============================================================ 5
    st.append(CondPageBreak(5 * inch))
    st.append(P("5  Print and assembly, step by step", "h1"))
    st.append(P(EXTRA["sec5"]))
    st.append(P("Pause heights (recommended build, 0.2 mm layers)", "h2"))
    st.append(table(EXTRA["pause_W"], [0.13, 0.09, 0.17, 0.17, 0.17, 0.27]))
    st.append(P(EXTRA["pause_note"], "small"))
    st.append(P("Steps", "h2"))
    for i, t in enumerate(EXTRA["steps"], 1): st.append(step(i, t))
    st.append(Spacer(1, 4))
    st.append(img(src("w37-W-bottom.png"), 6.6 * inch))
    st.append(P(EXTRA["cap_bottom"], "cap"))
    st.append(P("Pause heights (steel-dowel build)", "h2"))
    st.append(table(EXTRA["pause_St"], [0.13, 0.09, 0.17, 0.17, 0.17, 0.27]))

    # ============================================================ 6
    st.append(CondPageBreak(4 * inch))
    st.append(P("6  Checks and fixes", "h1"))
    st.append(table(EXTRA["checks"], [0.24, 0.38, 0.38]))
    st.append(Spacer(1, 6))
    st.append(P("What failure looks like, and what to do", "h2"))
    for t in EXTRA["fixes"]: st.append(B(t))

    # ============================================================ 7
    st.append(P("7  Safety", "h1"))
    st.append(box([B(t) for t in EXTRA["safety"]], bg=WARN_BG, border=WARN))

    # ============================================================ 8
    st.append(PageBreak())
    st.append(P("8  How sure are we", "h1"))
    st.append(P(EXTRA["sec8"]))
    st.append(P("Robustness: 300 random builds per row, exact mass model each time", "h2"))
    rows = [["error model", "tungsten build: <b>one rest face</b> / one balance point / strict", "steel-dowel build: <b>one rest face</b> / one balance point / strict"]]
    def fmt(r):
        return f"<b>{float(r[1]):.0f}</b> / {float(r[3]):.0f} / {float(r[4]):.0f} %" if r else "–"
    for r in RR:
        rows.append([r[0], fmt(r), fmt(rget(RA, r[0]))])
    st.append(table(rows, [0.36, 0.32, 0.32]))
    st.append(P(EXTRA["robust_note"], "small"))
    st.append(P("Dynamics: dropped and set down in the gallery's physics harness", "h2"))
    for t in EXTRA["dyn"]: st.append(B(t))
    st.append(P("What is uncertain", "h2"))
    for t in EXTRA["unc"]: st.append(B(t))

    # ============================================================ 9
    st.append(CondPageBreak(3.5 * inch))
    st.append(P("9  Files and references", "h1"))
    st.append(table(EXTRA["files"], [0.36, 0.64]))
    st.append(P("References", "h2"))
    for t in EXTRA["refs"]: st.append(B(t))
    doc.build(st)

if __name__ == "__main__":
    build(); print("written", f"{PR}/w37-build-guide.pdf")
