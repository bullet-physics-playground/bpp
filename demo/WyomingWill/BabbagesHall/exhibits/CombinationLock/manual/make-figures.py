"""The combination lock manual's figures (Babbage's Hall).

    python3 manual/make-figures.py      (from the exhibit's folder; lua, matplotlib, openscad, xvfb-run)

Everything is drawn from the exhibit's own lock.lua: the wheels' and the
cam's outlines are its convex pieces' (the same the simulation's bodies are
made of), the gates are where it cuts them for 31-72-46, and the chart of
the wheels turning is its model, turned as the dialling rules say. The
pictures of the lock are OpenSCAD's drawings of the printed parts
(parts/combination-lock.scad). Only labels, arrows and colours are added.
Writes manual/fig-*.png (fig-exhibit.png is a screenshot, not made here)."""
import json, os, subprocess, tempfile
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Polygon, Circle

HERE = os.path.dirname(os.path.abspath(__file__))
TOP = os.path.dirname(HERE)
LUA = next(l for l in ("lua5.2", "lua5.1", "lua") if subprocess.run(["which", l], capture_output=True).returncode == 0)
BRASS, CAM, STEEL, RED, INK, GREY = "#c9a24a", "#9a7434", "#8f959b", "#c0161a", "#2b1e14", "#9a9a9a"
COLS = ["#3b6ea8", "#b5542d", "#4e8a3e"]          # wheel 1, 2, 3 in the chart

# ---------------------------------------------------------------------
# the data, from lock.lua
# ---------------------------------------------------------------------
DATA_LUA = r'''
local L = dofile("@LOCK@")
local G = L.G
local function J(v)
  if type(v) == "table" then
    local n, parts = #v, {}
    if n > 0 then for i = 1, n do parts[i] = J(v[i]) end; return "[" .. table.concat(parts, ",") .. "]" end
    for k, x in pairs(v) do parts[#parts + 1] = string.format("%q:%s", k, J(x)) end
    return "{" .. table.concat(parts, ",") .. "}"
  elseif type(v) == "number" then return string.format("%.5f", v)
  elseif type(v) == "boolean" then return tostring(v)
  else return string.format("%q", v) end
end
local a, b, c = 31, 72, 46
local gates = L.gates(a, b, c)
local out = { G = G, delta = L.DELTA, top = L.TOP, gates = gates, pull = L.PULL, hook = L.HOOK_DROP }
out.cam = L.camOutline()
out.wheel = {}
for i = 1, 3 do out.wheel[i] = L.wheelPieces(gates[i] * L.DEG) end
-- the dialling, from a scrambled start: the dial's travel and each gate's place, a point a number
local s = L.new(0, { 13, 58, 91 })
local plan = L.plan(s.D, a, b, c)
local trace, travel = {}, 0
local function rec() local e = L.gateOffsets(s, gates); trace[#trace + 1] = { travel, L.wrap(s.D), e[1], e[2], e[3] } end
rec()
local marks = {}
for k, m in ipairs(plan) do
  local d = m.to - s.D
  local n = math.ceil(math.abs(d) * 4)
  for i = 1, n do L.turn(s, d / n); travel = travel + math.abs(d / n); rec() end
  marks[k] = travel
end
local d = L.toOpen(s.D) - s.D
local n = math.ceil(math.abs(d) * 4)
for i = 1, n do L.turn(s, d / n); travel = travel + math.abs(d / n); rec() end
marks[4] = travel
out.trace, out.marks = trace, marks
-- the fence's fall against one wheel, its gate e numbers off
local wp = L.wheelPieces(90)
local fall = {}
for e = -2.5, 2.501, 0.02 do fall[#fall + 1] = { e, L.fall(wp, e * L.DEG, 8) } end
out.fall = fall
print(J(out))
'''
code = DATA_LUA.replace("@LOCK@", os.path.join(TOP, "lock.lua"))
D = json.loads(subprocess.run([LUA, "-e", code], capture_output=True, text=True, check=True).stdout)
G = D["G"]
DEG = 3.6


def save(fig, name):
    fig.savefig(os.path.join(HERE, name), dpi=150, bbox_inches="tight", facecolor="white")
    plt.close(fig)
    print("  manual/" + name)


# ---------------------------------------------------------------------
# fig-wheels: the three wheels and the cam, face on, set to 31-72-46 (each
# gate under the fence), the pins where the last moves left them
# ---------------------------------------------------------------------
def draw_part(ax, pieces, cx, col, turn=0, outline=None):
    import math
    c, s = math.cos(math.radians(turn)), math.sin(math.radians(turn))
    rot = lambda p: (cx + c * p[0] - s * p[1], c * p[1] + s * p[0])
    if outline:
        ax.add_patch(Polygon([rot(p) for p in outline], closed=True, fc=col, ec=INK, lw=0.8))
    else:
        for p in pieces:
            ax.add_patch(Polygon([rot(q) for q in p], closed=True, fc=col, ec=col, lw=0.3))
    ax.add_patch(Circle((cx, 0), G["HUB_R"], fc="white", ec=INK, lw=0.6))


def pin_at(turn):
    import math
    a = math.radians(G["PIN_AT"] + turn)
    return (G["PIN_R"] * math.cos(a), G["PIN_R"] * math.sin(a))


fig, ax = plt.subplots(figsize=(11, 3.4))
gap = 2 * G["R_W"] + 18
names = ["wheel 1 (31)", "wheel 2 (72)", "wheel 3 (46)", "the cam"]
# (the last state: the dial on 46, wheels 1 and 2 set; wheel 3 set by the last move)
last = D["trace"][-1]
for i in range(3):
    cx = i * gap
    turn = (D["top"] - D["gates"][i]) * DEG                 # (its gate at the top)
    draw_part(ax, D["wheel"][i], cx, BRASS, turn)
    px, py = pin_at(turn)
    ax.add_patch(Circle((cx + px, py), G["PIN_D"] / 2, fc=STEEL, ec=INK, lw=0.6))
    ax.text(cx, -G["R_W"] - 9, names[i], ha="center", va="top", fontsize=10)
    ax.add_patch(Circle((cx, G["ROD_Y"]), G["ROD_D"] / 2, fc="#d0d4d8", ec=INK, lw=0.8))
cx = 3 * gap
dial = 46
draw_part(ax, None, cx, CAM, dial * DEG, outline=D["cam"])
px, py = pin_at(dial * DEG)
ax.add_patch(Circle((cx + px, py), G["PIN_D"] / 2, fc=STEEL, ec=INK, lw=0.6))
ax.add_patch(Circle((cx, G["ROD_Y"]), G["ROD_D"] / 2, fc="#d0d4d8", ec=INK, lw=0.8))
ax.text(cx, -G["R_W"] - 9, "the cam (dial on 46)", ha="center", va="top", fontsize=10)
ax.annotate("the fence, over every rim", xy=(0, G["ROD_Y"] + 2), xytext=(-G["R_W"] - 10, G["R_W"] + 16), fontsize=9,
            arrowprops=dict(arrowstyle="-", lw=0.6))
ax.annotate("the gate", xy=(gap, G["R_W"] - 3), xytext=(gap + 26, G["R_W"] + 14), fontsize=9, arrowprops=dict(arrowstyle="-", lw=0.6))
ax.annotate("its pin", xy=(gap + pin_at((D["top"] - D["gates"][1]) * DEG)[0], pin_at((D["top"] - D["gates"][1]) * DEG)[1]),
            xytext=(gap + 30, -G["R_W"] + 4), fontsize=9, arrowprops=dict(arrowstyle="-", lw=0.6))
ax.annotate("the notch", xy=(cx + 39 * __import__("math").cos(__import__("math").radians(90 + dial * DEG + 0)),
                              39 * __import__("math").sin(__import__("math").radians(90 + dial * DEG))),
            xytext=(cx + 18, -G["R_W"] - 6), fontsize=9, arrowprops=dict(arrowstyle="-", lw=0.6))
ax.set_aspect("equal"); ax.axis("off")
ax.set_xlim(-G["R_W"] - 14, 3 * gap + G["R_W"] + 8); ax.set_ylim(-G["R_W"] - 20, G["R_W"] + 22)
save(fig, "fig-wheels.png")

# ---------------------------------------------------------------------
# fig-dialling: each gate's distance from the fence as the dial turns
# through the four moves, from a scrambled start
# ---------------------------------------------------------------------
tr = D["trace"]
x = [t[0] for t in tr]
fig, ax = plt.subplots(figsize=(11, 4.2))
marks = [0] + D["marks"]
labels = ["1. left four times to 31", "2. right three times to 72", "3. left twice to 46", "4. right"]
for k in range(4):
    if k % 2 == 0: ax.axvspan(marks[k], marks[k + 1], color="#f3ecd9", lw=0)
    ax.text((marks[k] + marks[k + 1]) / 2, 54, labels[k], ha="center", va="bottom", fontsize=9)
for i in range(3):
    y = [t[2 + i] for t in tr]
    xs, ys = [x[0]], [y[0]]
    for j in range(1, len(y)):                       # (break the line where it wraps round)
        if abs(y[j] - y[j - 1]) > 50:
            ax.plot(xs, ys, color=COLS[i], lw=1.6); xs, ys = [], []
        xs.append(x[j]); ys.append(y[j])
    ax.plot(xs, ys, color=COLS[i], lw=1.6, label=f"wheel {i + 1}")
ax.axhline(0, color=INK, lw=0.8)
ax.set_ylim(-52, 62); ax.set_xlim(0, x[-1])
ax.set_xlabel("numbers turned (100 a turn)")
ax.set_ylabel("its gate from under the fence")
ax.legend(loc="lower left", fontsize=9, ncol=3, frameon=False)
for s in ("top", "right"): ax.spines[s].set_visible(False)
save(fig, "fig-dialling.png")

# ---------------------------------------------------------------------
# fig-notch: the fence over the cam's notch, three ways
# ---------------------------------------------------------------------
import math
def turned(poly, deg):
    c, s = math.cos(math.radians(deg)), math.sin(math.radians(deg))
    return [(c * p[0] - s * p[1], s * p[0] + c * p[1]) for p in poly]
def rim(r, a0, a1):
    return [(r * math.cos(math.radians(a)), r * math.sin(math.radians(a))) for a in [a0 + (a1 - a0) * i / 60 for i in range(61)]]

fig, axs = plt.subplots(1, 3, figsize=(11, 3.6))
cases = [(6.0, 0, "the notch away: the fence\nrests on the cam"),
         (0.0, 0.4, "the notch under it, a gate not:\n0.4 mm, onto the wheels' rims"),
         (0.0, 4.0, "the notch and every gate under it:\nthe fence falls in, and is hooked")]
for ax, (dialAt, fall, title) in zip(axs, cases):
    cam = turned(D["cam"], dialAt * DEG)
    ax.add_patch(Polygon(cam, closed=True, fc=CAM, ec=INK, lw=0.8, alpha=0.9))
    w = rim(G["R_W"], 60, 120) + rim(G["R_W"] - 8, 120, 60)
    if fall < 1:
        ax.add_patch(Polygon(w, closed=True, fc="none", ec=COLS[0], lw=1.2, ls="--"))
    else:
        g = D["wheel"][0]
        tw = (D["top"] - D["gates"][0]) * DEG
        for p in g:
            ax.add_patch(Polygon(turned(p, tw), closed=True, fc="none", ec=COLS[0], lw=0.5, ls="--"))
    ax.add_patch(Circle((0, G["ROD_Y"] - fall), G["ROD_D"] / 2, fc="#d0d4d8", ec=INK, lw=1))
    ax.set_xlim(-11, 11); ax.set_ylim(33.5, 46); ax.set_aspect("equal"); ax.axis("off")
    ax.set_title(title, fontsize=9)
axs[1].annotate("chamfer: lifts it out", xy=(-2.9, 40.2), xytext=(-10.5, 44.3), fontsize=8, arrowprops=dict(arrowstyle="-", lw=0.6))
axs[2].annotate("steep wall: pulls it, turning right", xy=(-2.6, 37.5), xytext=(-10.5, 44.3), fontsize=8, arrowprops=dict(arrowstyle="-", lw=0.6))
save(fig, "fig-notch.png")

# ---------------------------------------------------------------------
# fig-tolerance: how far the fence can fall, against a gate's distance
# ---------------------------------------------------------------------
fall = D["fall"]
fig, ax = plt.subplots(figsize=(8, 3.4))
ax.plot([f[0] for f in fall], [min(f[1], G["ROD_Y"] - G["NOTCH_R"] - G["ROD_D"] / 2) for f in fall], color=INK, lw=1.6)
ax.axhline(D["hook"], color=RED, lw=0.8, ls="--")
ax.text(-2.45, D["hook"] + 0.12, "hooked by the notch's steep wall", color=RED, fontsize=8)
ax.axvspan(-1.5, 1.8, color="#dbe9d4", lw=0, zorder=0)
ax.text(0, 0.5, "opened, in the simulation\n(1.5 below to 1.8 above)", ha="center", fontsize=8)
ax.set_xlabel("the gate from under the fence (numbers)")
ax.set_ylabel("the fence's fall (mm)")
ax.set_xlim(-2.5, 2.5); ax.set_ylim(0, 4.6)
for s in ("top", "right"): ax.spines[s].set_visible(False)
save(fig, "fig-tolerance.png")

# ---------------------------------------------------------------------
# the lock, and the wheel pack taken apart: OpenSCAD's drawings
# ---------------------------------------------------------------------
SCAD = os.path.join(TOP, "parts", "combination-lock.scad")
VIEWS = {
    "fig-lock.png": ("rotate([90, 0, 0]) assembly();", "--camera=0,0,0,58,0,-28,500", "1400,1000"),
    "fig-pack.png": ("""rotate([90, 0, 0]) {
        for (i = [0 : 2]) translate([0, 0, Z_W[i] + T_W / 2 + 34 * i]) { color("#c9a24a") wheel(GATES[i], i + 1);
          color("#8f959b") rotate([0, 0, PIN_AT]) translate([PIN_R, 0, 0]) pin(); color("#c0161a") gateMark(GATES[i]); }
        translate([0, 0, CAM_MID + 102]) { color("#9a7434") cam(); color("#8f959b") camPin(); }
        translate([PIVOT_X, ROD_Y + 30, 0]) scale([1, 1, 2.6]) { color("#3d4a42") lever(); color("#d0d4d8") rod(); }
      }""", "--camera=0,0,0,66,0,-62,500", "1400,900"),
}
with tempfile.TemporaryDirectory() as tmp:
    for name, (body, cam, size) in VIEWS.items():
        f = os.path.join(tmp, "v.scad")
        open(f, "w").write(f"include <{SCAD}>\n{body}\n")
        subprocess.run(["xvfb-run", "-a", "openscad", "-o", os.path.join(HERE, name), cam, "--imgsize=" + size,
                        "--colorscheme=Tomorrow", "--projection=p", "--viewall", "--autocenter", f], capture_output=True, check=True)
        from PIL import Image, ImageChops
        im = Image.open(os.path.join(HERE, name)).convert("RGB")
        bg = Image.new("RGB", im.size, im.getpixel((0, 0)))
        box = ImageChops.difference(im, bg).getbbox()
        if box: im.crop((max(0, box[0] - 30), max(0, box[1] - 30), min(im.width, box[2] + 30), min(im.height, box[3] + 30))).save(os.path.join(HERE, name))
        print("  manual/" + name)
