import re, sys, importlib.util
spec = importlib.util.spec_from_file_location("pa", "/home/claude/work/plan_an.py")
import io, contextlib
buf = io.StringIO()
with contextlib.redirect_stdout(buf):
    pa = importlib.util.module_from_spec(spec); spec.loader.exec_module(pa)
TARGET = 38.0
R = "/home/claude/bpp/demo/WyomingWill/WalkerRoom/"
for f in ("walker-room.lua", "trotting-walkers.lua", "spears-lift-walkers.lua"):
    s = open(R + f).read()
    def fix(m):
        line = m.group(0)
        name = re.search(r'name = "([^"]+)"', line).group(1)
        if name not in pa.rows: return line
        stance = pa.rows[name][1]
        stride = float(re.search(r'stride = ([\d.]+)', line).group(1))
        S = 15.0 / stride
        old = float(re.search(r'wide = \{ cube_d = ([-\d.]+) \}', line).group(1))
        new = old + (TARGET - stance) / S
        print(f"{name:32s} stance {stance:5.2f} -> cube_d {old:8.3f} -> {new:8.3f}")
        return re.sub(r'wide = \{ cube_d = [-\d.]+ \}', f'wide = {{ cube_d = {new:.3f} }}', line)
    s = re.sub(r'\{ name = "[^"]+".*', fix, s)
    open(R + f, "w").write(s)
