#!/usr/bin/env python3
# Side views from framedump.lua dumps: each walker's boxes (body grey; links on the near side solid, far side pale;
# feet dark; the slider blocks orange), the ground under its near and far feet (solid / dashed). Panels stacked,
# each following its own body. python3 drawfd.py OUT.mp4 FPS dumpA labelA dumpB labelB ...  (or OUT.png T1,T2,...
# for a sheet of moments: rows = times, columns = walkers)
import sys, math, os, subprocess, tempfile
import matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Polygon
def hull(p):
    p = sorted(set(p))
    if len(p) < 3: return p
    def cr(o, a, b): return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])
    lo, up = [], []
    for q in p:
        while len(lo) >= 2 and cr(lo[-2], lo[-1], q) <= 0: lo.pop()
        lo.append(q)
    for q in reversed(p):
        while len(up) >= 2 and cr(up[-2], up[-1], q) <= 0: up.pop()
        up.append(q)
    return lo[:-1] + up[:-1]
def load(path):
    F = []
    for l in open(path):
        if l.startswith("T "):
            f = l.strip().split("|"); F.append(dict(t=float(f[0][2:]), x=float(f[1].split()[2]), B=[], G=[]))
        elif l.startswith("B "):
            k, zc, pts = l[2:].strip().split("|")
            F[-1]["B"].append((k, float(zc), hull([tuple(map(float, q.split(","))) for q in pts.split(";")])))
        elif l.startswith("S "):
            a, b = l[2:].strip().split("|"); F[-1]["S"] = (float(a), float(b))
        elif l.startswith("G "):
            z, x0, dx, hs = l[2:].strip().split("|")
            F[-1]["G"].append((float(z), float(x0.split()[1]), float(dx.split()[1]), list(map(float, hs.split(",")))))
    return F
def draw(ax, fr, label, pitch=None):
    ax.clear(); x = fr["x"]
    for i, (z, x0, dx, hs) in enumerate(fr["G"]):
        xs = [x0 + j * dx for j in range(len(hs))]
        ax.plot(xs, hs, color="#6b4f2a", lw=2.2 if z > 0 else 1.2, ls="-" if z > 0 else "--", zorder=1)
    if fr.get("S"):
        fx, fh = fr["S"]; ax.add_patch(Polygon([(fx, 0), (fx, fh), (fx + 60, fh), (fx + 60, 0)], closed=True, fc="#c8bfae", ec="#6b4f2a", lw=1.5, zorder=1))
    order = sorted(fr["B"], key=lambda b: b[1])   # far side first
    for k, zc, poly in order:
        near = zc > 0
        if k == "body": fc, ec, a, zo = "#9aa0a6", "#3c4043", 0.85, 3
        elif k == "buildFoot": fc, ec, a, zo = ("#202124", "#000000", 1.0, 5) if near else ("#80868b", "#5f6368", 0.6, 2)
        elif "Crossbar" in k: fc, ec, a, zo = ("#b22222", "#7a1010", 1.0, 5) if near else ("#f0a0a0", "#b22222", 0.6, 2)
        elif k == "buildLinkage": fc, ec, a, zo = ("#e8710a", "#a04b00", 1.0, 5) if near else ("#fbc58c", "#e8710a", 0.6, 2)
        else: fc, ec, a, zo = ("#1a73e8", "#0b3d91", 1.0, 4) if near else ("#a8c7fa", "#1a73e8", 0.55, 2)
        ax.add_patch(Polygon(poly, closed=True, fc=fc, ec=ec, lw=0.6, alpha=a, zorder=zo))
    ax.set_xlim(x - 38, x + 38); ax.set_ylim(-2, 40); ax.set_aspect("equal")
    ax.set_title(f"{label}   t = {fr['t']:.2f} s", fontsize=10, loc="left")
    ax.tick_params(labelsize=7)
if __name__ == "__main__":
    out = sys.argv[1]; arg = sys.argv[2]; rest = sys.argv[3:]
    runs = [(load(rest[i]), rest[i + 1]) for i in range(0, len(rest), 2)]
    if out.endswith(".png"):
        times = [float(t) for t in arg.split(",")]
        fig, axs = plt.subplots(len(times), len(runs), figsize=(6.2 * len(runs), 2.9 * len(times)), squeeze=False)
        for r, t in enumerate(times):
            for c, (F, lab) in enumerate(runs):
                fr = min(F, key=lambda f: abs(f["t"] - t)); draw(axs[r][c], fr, lab)
        fig.tight_layout(); fig.savefig(out, dpi=95)
    else:
        fps = float(arg); n = min(len(F) for F, _ in runs)
        d = tempfile.mkdtemp(dir=os.path.dirname(out))
        fig, axs = plt.subplots(len(runs), 1, figsize=(8, 3.4 * len(runs)), squeeze=False)
        for i in range(n):
            for c, (F, lab) in enumerate(runs): draw(axs[c][0], F[i], lab)
            fig.tight_layout(); fig.savefig(f"{d}/{i:05d}.png", dpi=90)
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-framerate", str(fps), "-i", f"{d}/%05d.png", "-vf", "scale=trunc(iw/2)*2:trunc(ih/2)*2",
                        "-c:v", "libx264", "-preset", "veryfast", "-crf", "23", "-pix_fmt", "yuv420p", out], check=True)
        for f in os.listdir(d): os.remove(f"{d}/{f}")
        os.rmdir(d)
