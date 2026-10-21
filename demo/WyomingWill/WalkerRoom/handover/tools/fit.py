#!/usr/bin/env python3
# Fit one build's spec in the room files to the standard, one value at a time, by
# re-sweeping (sweepprobe.lua) and measuring (geo.py):
#   stride          -> foot travel 15 cm
#   linkageSpacing  -> base 35 cm (chassis)
#   bodyShift       -> balance offset 0 (and frame.x = -bodyShift)
# python3 fit.py "<name>"
import re, subprocess, os, sys, importlib.util
R = "/home/claude/bpp/demo/WyomingWill/WalkerRoom/"
FILES = ("walker-room.lua", "trotting-walkers.lua", "spears-lift-walkers.lua")
spec_ = importlib.util.spec_from_file_location("geo", "/home/claude/work/geo.py")
geo = importlib.util.module_from_spec(spec_); spec_.loader.exec_module(geo)
name = sys.argv[1]
def where():
    for fn in FILES:
        s = open(R + fn).read()
        m = re.search(r'\{ name = "%s",.*' % re.escape(name), s)
        if m: return fn, s, m.group(0)
def get(pat):
    fn, s, line = where(); return float(re.search(pat, line).group(1))
def put(pat, fmt, val):
    fn, s, line = where()
    new = re.sub(pat, lambda m: m.group(0).replace(m.group(1), fmt % val), line, count=1)
    open(R + fn, "w").write(s.replace(line, new))
STRIDE, LS, SHIFT = r"stride = ([-\d.]+)", r"linkageSpacing = ([-\d.]+)", r"bodyShift = ([-\d.]+)"
def sweep():
    out = f"/home/claude/work/sweep2/{name.replace(' ', '_')}.txt"
    f = R + "_fit_%d.lua" % os.getpid()
    open(f, "w").write(f'dofile("trotting-walkers.lua"); dofile("spears-lift-walkers.lua"); ONLY="{name}"; CRANK=0.6\ndofile("/home/claude/work/sweepprobe.lua")\n')
    subprocess.run(["/home/claude/build/release/bpp", "-f", os.path.basename(f), "-n", "950"], cwd=R, capture_output=True,
                   env=dict(os.environ, QT_QPA_PLATFORM="offscreen", SWEEP_OUT=out))
    os.remove(f)
    return geo.one(out)
def fit(pat, fmt, idx, target, tol, scale_guess=None):
    x0 = get(pat); m = sweep(); y0 = m[idx]
    print(f"  {pat.split()[0]} {x0} -> {['','stride','lift','base','offset','advance'][idx]} {y0:.3f}", flush=True)
    if abs(y0 - target) <= tol: return m
    x1 = scale_guess(x0, y0) if scale_guess else x0 + (target - y0)
    for _ in range(6):
        put(pat, fmt, x1); m = sweep(); y1 = m[idx]
        print(f"  {pat.split()[0]} {x1:.4f} -> {y1:.3f}", flush=True)
        if abs(y1 - target) <= tol: return m
        if y1 == y0: break
        x0, y0, x1 = x1, y1, x1 + (target - y1) * (x1 - x0) / (y1 - y0)
    return m
print(name)
adv_old_m = sweep()[5]; adv_old = get(r"advance = ([-\d.]+)")
# stride: travel scales as old/new, so new = old * travel / 15
fit(STRIDE, "%.4f", 1, 15.0, 0.02, scale_guess=lambda x, y: x * y / 15.0)
fit(LS, "%.3f", 3, 35.0, 0.05)
m = fit(SHIFT, "%.2f", 4, 0.0, 0.01)
put(r"frame = \{ length = [-\d.]+, x = ([-\d.]+) \}", "%.2f", -get(SHIFT))
put(r"advance = ([-\d.]+)", "%.3f", adv_old * m[5] / adv_old_m)
print(f"DONE {name}: stride {m[1]:.2f} lift {m[2]:.2f} base {m[3]:.2f} offset {m[4]:+.3f} advance {adv_old:.3f} -> {get(r'advance = ([-\d.]+)'):.3f}", flush=True)
