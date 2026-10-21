#!/usr/bin/env python3
# bodyRaise of one build -> its body's mean clearance (clearprobe) = target. python3 fitraise.py "<name>" target
import re, subprocess, sys
R = "/home/claude/bpp/demo/WyomingWill/WalkerRoom/"
FILES = ("walker-room.lua", "trotting-walkers.lua", "spears-lift-walkers.lua")
name, target = sys.argv[1], float(sys.argv[2])
def where():
    for fn in FILES:
        s = open(R + fn).read(); m = re.search(r'\{ name = "%s",.*' % re.escape(name), s)
        if m: return fn, s, m.group(0)
def get(): return float(re.search(r"bodyRaise = ([-\d.]+)", where()[2]).group(1))
def put(v):
    fn, s, line = where(); open(R + fn, "w").write(s.replace(line, re.sub(r"bodyRaise = [-\d.]+", f"bodyRaise = {v:.3f}", line, count=1)))
def clear():
    o = subprocess.run(["/home/claude/work/clear.sh", name], capture_output=True, text=True).stdout
    return float(re.search(r"mean ([-\d.]+)", o).group(1))
x0, y0 = get(), clear(); print(name, x0, y0, flush=True)
x1 = x0 + (target - y0) / 1.5          # (a first guess: the scale is about 1.5-3 cm per unit)
for _ in range(6):
    if abs(y0 - target) <= 0.02: break
    put(x1); y1 = clear(); print(" ", round(x1, 3), y1, flush=True)
    if abs(y1 - target) <= 0.02: break
    x0, y0, x1 = x1, y1, x1 + (target - y1) * (x1 - x0) / (y1 - y0)
print("DONE", name, get(), flush=True)
