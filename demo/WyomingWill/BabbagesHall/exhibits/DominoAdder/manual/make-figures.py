"""The Domino Half Adder manual's figures (Babbage's Hall).

    python3 manual/make-figures.py          (from the exhibit's folder; Pillow, lua)
    python3 manual/make-figures.py --run    (first runs the four sums in bpp, ~10 min)

The plan is the exhibit's own layout (domino-layout.lua, through
manual/layout.lua), every domino drawn where the simulation stands it. Which
dominoes fell in each of the four sums is what the simulation reported
(DA_DEBUG=2), kept in manual/fell.txt; --run makes it again. Writes
manual/fig-*.png (all but fig-exhibit.png, a screenshot of the simulation)."""
import math, os, subprocess, sys
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
EX = os.path.dirname(HERE)
TOP = os.path.abspath(os.path.join(EX, "../../../../.."))
FONTS = "/usr/share/fonts/truetype/dejavu/"
def font(px, bold=False): return ImageFont.truetype(FONTS + ("DejaVuSans-Bold.ttf" if bold else "DejaVuSans.ttf"), int(px))

CASES = [("", "0 + 0"), ("B", "0 + 1"), ("A", "1 + 0"), ("AB", "1 + 1")]
ORDER = ["GO", "Ain", "Bin", "A", "B", "C", "Tl", "Tr", "SUM", "INH", "A3"]

if "--run" in sys.argv:
    with open(os.path.join(HERE, "fell.txt"), "w") as out:
        for ins, name in CASES:
            env = dict(os.environ, DA_IN=ins, DA_TOUR="0", DA_DEBUG="2")
            r = subprocess.run(["build/release/bpp", "-f", "demo/WyomingWill/BabbagesHall/exhibits/DominoAdder/domino-adder.lua",
                                "-n", "700"], cwd=TOP, env=env, capture_output=True, text=True)
            line = [l for l in r.stdout.splitlines() if "fell:" in l][0]
            out.write(f"{ins or '-'}|{line.split('fell:')[1].strip()}\n")
            print(" ", name, "run")

# the layout
lay = subprocess.run(["lua", "manual/layout.lua"], cwd=EX, capture_output=True, text=True, check=True).stdout
LINES, SWITCH, TELL = {n: [] for n in ORDER}, {}, {}
for l in lay.strip().splitlines():
    f = l.split("|")
    if f[0] == "switch": SWITCH.setdefault(f[1], []).append(int(f[2]))
    elif f[0] == "tell": TELL[f[1]] = tuple(float(v) for v in f[2:])
    elif f[0] == "dims": DW, DH, DT = (float(v) for v in f[1:])
    else: LINES[f[0]].append(tuple(float(v) for v in f[1:]))
# which fell, in each sum
FELL = {}
for l in open(os.path.join(HERE, "fell.txt")).read().strip().splitlines():
    ins, rest = l.split("|", 1)
    st = {}
    for part in rest.split(" | "):
        n, k, s = (part.split(" ") + [""])[:3]
        st[n] = [c == "x" for c in s]
    FELL["" if ins == "-" else ins] = st

COL = {"GO": (200, 40, 30), "Ain": (200, 90, 30), "A": (200, 90, 30), "Bin": (130, 60, 170), "B": (130, 60, 170),
       "C": (40, 40, 40), "Tl": (40, 110, 210), "Tr": (40, 110, 210), "SUM": (40, 110, 210), "INH": (40, 110, 210),
       "A3": (30, 140, 60)}
GREY, LIGHT = (175, 170, 160), (238, 235, 228)
xs = [p[0] for n in ORDER for p in LINES[n]] + [t[0] for t in TELL.values()]
zs = [p[1] for n in ORDER for p in LINES[n]] + [t[1] for t in TELL.values()]
X0, X1, Z0, Z1 = min(xs) - 6, max(xs) + 6, min(zs) - 6, max(zs) + 8


def plan(s, state=None, ins=None, labels=False, box=None, mark=None):
    """the board from above, s px a cm; state: which fell (None: all coloured)"""
    x0, x1, z0, z1 = box or (X0, X1, Z0, Z1)
    im = Image.new("RGB", (int((x1 - x0) * s), int((z1 - z0) * s)), (255, 255, 255))
    g = ImageDraw.Draw(im)
    P = lambda x, z: ((x - x0) * s, (z1 - z) * s)
    def domino(x, z, h, fill, outline, w=DW, t=DT, dashed=False):
        ux, uz = math.sin(h), math.cos(h)            # (along the heading)
        vx, vz = math.cos(h), -math.sin(h)           # (across it)
        pts = [P(x + a * ux * t / 2 + b * vx * w / 2, z + a * uz * t / 2 + b * vz * w / 2) for a, b in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
        if dashed:
            for i in range(4):
                (ax, ay), (bx, by) = pts[i], pts[(i + 1) % 4]
                for k in range(0, 10, 2):
                    g.line([(ax + (bx - ax) * k / 10, ay + (by - ay) * k / 10), (ax + (bx - ax) * (k + 1) / 10, ay + (by - ay) * (k + 1) / 10)], fill=outline, width=1)
        else:
            g.polygon(pts, fill=fill, outline=outline)
    for n in ORDER:
        for i, (x, z, h) in enumerate(LINES[n]):
            sw = n in SWITCH and (i + 1) in SWITCH[n]
            out = sw and ins is not None and ((n == "Ain" and "A" not in ins) or (n == "Bin" and "B" not in ins))
            if out:
                domino(x, z, h, None, (150, 150, 150), dashed=True); continue
            if state is None: fill = COL[n]
            else: fill = COL[n] if state[n][i] else LIGHT
            edge = (60, 50, 40) if (sw and state is None) else ((90, 90, 90) if state is not None and not state[n][i] else fill)
            if sw and state is None: fill = (215, 170, 40)          # (brass, as in the exhibit)
            domino(x, z, h, fill, edge)
            if sw and state is None:
                domino(x, z, h, None, (0, 0, 0), w=DW + 1.0, t=DT + 1.0)
    for name, (x, z, h) in TELL.items():
        fallen = state is not None and ((name == "SUM" and state["SUM"][-1]) or (name == "CARRY" and state["A3"][-1]))
        if state is not None and fallen:
            domino(x, z + 3, 0, (255, 230, 120), (120, 100, 30), w=4.0, t=6.0)
        else:
            domino(x, z, h, (255, 230, 120), (120, 100, 30), w=4.0, t=0.6)
    return im, P, g


def save(im, name, width=None):
    if width and im.width > width:
        im = im.resize((width, round(im.height * width / im.width)), Image.LANCZOS)
    im.save(os.path.join(HERE, name), optimize=True)
    print("  manual/" + name, im.size)


# 1. the plan, every line named
S = 6
im, P, g = plan(S, labels=True)
def label(text, x, z, col, anchor="mm", size=15):
    g.text(P(x, z), text, font=font(size * S / 5, True), fill=col, anchor=anchor)
def at(n, i): return LINES[n][i if i >= 0 else len(LINES[n]) + i]
x, z, _ = at("GO", 0); label("GO", x, z - 4, COL["GO"], "mt")
x, z, _ = at("Ain", 8); label("switch A", x, z - 3.5, COL["A"], "mt", 12)
x, z, _ = at("Bin", 8); label("switch B", x, z - 3.5, COL["B"], "mt", 12)
x, z, _ = at("A", 7); label("A", x + 3, z - 1, COL["A"], "lt")
x, z, _ = at("B", 7); label("B", x - 3, z - 1, COL["B"], "rt")
x, z, _ = at("C", 5); label("collision line", x, z - 3, COL["C"], "mt", 12)
x, z, _ = at("Tr", 10); label("tap", x + 3, z, COL["SUM"], "lm", 12)
x, z, _ = at("Tl", 10); label("tap", x - 3, z, COL["SUM"], "rm", 12)
x, z, _ = at("SUM", 18); label("SUM", x + 3, z, COL["SUM"], "lm")
x, z, _ = at("INH", -1); label("the cut", x + 3, z + 2.5, COL["SUM"], "lb", 12)
zi = LINES["INH"][-1][1]
top = max((p for p in LINES["A3"] if p[1] < zi - 8 and abs(abs(p[2]) - math.pi / 2) < 0.2), key=lambda p: (round(p[1]), -p[0]))
xs_top = [p[0] for p in LINES["A3"] if abs(p[1] - top[1]) < 0.5]
label("A's delay line", (min(xs_top) + max(xs_top)) / 2, top[1] + 2.5, COL["A3"], "mb", 12)
x, z, _ = at("A3", -12); label("CARRY", x - 3, z, COL["A3"], "rm")
for name, (x, z, h) in TELL.items():
    label("tell-tale", x, z - 3, (120, 100, 30), "mt", 10)
save(im, "fig-plan.png", 640)

# 2. the four sums, as they ended
ims = []
for ins, name in CASES:
    im, P, g = plan(2.6, FELL[ins], ins)
    c = 1 if FELL[ins]["A3"][-1] else 0; sm = 1 if FELL[ins]["SUM"][-1] else 0
    cap = Image.new("RGB", (im.width, 60), (255, 255, 255))
    gc = ImageDraw.Draw(cap)
    gc.text((im.width / 2, 8), f"{name} = {c}{sm}", font=font(26, True), fill=(30, 30, 30), anchor="mt")
    full = Image.new("RGB", (im.width, im.height + 60), (255, 255, 255)); full.paste(im, (0, 0)); full.paste(cap, (0, im.height))
    ims.append(full)
gap = 18
out = Image.new("RGB", (sum(i.width for i in ims) + gap * 3, ims[0].height), (255, 255, 255))
x = 0
for i in ims: out.paste(i, (x, 0)); x += i.width + gap
save(out, "fig-sums.png", 1300)

# 3. close-ups: the collision line in 1 + 1, the taps in 1 + 0, the cut in 0 + 1 and 1 + 0
def bbox(names, pad=6, idx=None):
    pts = []
    for n in names:
        L = LINES[n] if idx is None or n not in idx else [LINES[n][i] for i in idx[n]]
        pts += [(p[0], p[1]) for p in L]
    return (min(p[0] for p in pts) - pad, max(p[0] for p in pts) + pad, min(p[1] for p in pts) - pad, max(p[1] for p in pts) + pad)
def captioned(im, text, size=22):
    full = Image.new("RGB", (im.width, im.height + 44), (255, 255, 255)); full.paste(im, (0, 0))
    ImageDraw.Draw(full).text((im.width / 2, im.height + 8), text, font=font(size, True), fill=(30, 30, 30), anchor="mt")
    ImageDraw.Draw(full).rectangle([0, 0, im.width - 1, im.height - 1], outline=(200, 195, 185), width=2)
    return full
box = bbox(["C", "Tl", "Tr"], pad=4)
row = [captioned(plan(8, FELL[ins], ins, box=box)[0], f"{name}: {'A' if 'A' in ins else ''}{' and ' if ins == 'AB' else ''}{'B' if 'B' in ins else ''} came") for ins, name in CASES[1:]]
out = Image.new("RGB", (sum(i.width for i in row) + 20 * 2, row[0].height), (255, 255, 255))
x = 0
for i in row: out.paste(i, (x, 0)); x += i.width + 20
save(out, "fig-xor.png", 1300)
# (the cut: where INH meets A3)
n = len(LINES["A3"])
near = [i for i, p in enumerate(LINES["A3"]) if abs(p[1] - LINES["INH"][-1][1]) < 14 and abs(p[0] - LINES["INH"][-1][0]) < 14]
box = bbox(["INH"], pad=5, idx=None)
box = (min(box[0], min(LINES["A3"][i][0] for i in near) - 5), max(box[1], max(LINES["A3"][i][0] for i in near) + 5),
       min(box[2], min(LINES["A3"][i][1] for i in near) - 3), max(box[3], max(LINES["A3"][i][1] for i in near) + 3))
xi, zi_ = LINES["INH"][-1][0], LINES["INH"][-1][1]
cut = min(range(n), key=lambda k: (LINES["A3"][k][0] - xi) ** 2 * 4 + (LINES["A3"][k][1] - zi_) ** 2 if abs(LINES["A3"][k][2]) < 0.1 else 1e9)
box = (box[0], box[1], box[2], box[3] + 8)
row = []
for (ins, name), text in ((CASES[2], "1 + 0: the carry cut"), (CASES[3], "1 + 1: the carry runs on")):
    im, P, g = plan(9, FELL[ins], ins, box=box)
    cx, cz, _ = LINES["A3"][cut]
    (px, pz) = P(cx, cz)
    g.ellipse([px - 22, pz - 14, px + 22, pz + 14], outline=(200, 30, 26), width=3)
    row.append(captioned(im, text, 17))
out = Image.new("RGB", (sum(i.width for i in row) + 24, row[0].height), (255, 255, 255))
x = 0
for i in row: out.paste(i, (x, 0)); x += i.width + 24
save(out, "fig-cut.png", 900)
