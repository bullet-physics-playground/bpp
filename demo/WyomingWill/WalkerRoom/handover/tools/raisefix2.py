# Re-tune every walker's bodyRaise so its body rides TARGET cm above flat ground (chassisprobe2's clearance).
import re, subprocess, os, sys
from concurrent.futures import ThreadPoolExecutor
TARGETS = {"Spears lift 44": 12.46, "Spears lift 44 diag": 13.13, "Spears lift 53": 14.33, "Spears lift 53 diag": 15.2}
TGT = lambda n: TARGETS.get(n, 12.0)
R = "/home/claude/bpp/demo/WyomingWill/WalkerRoom/"
FILES = ("walker-room.lua", "trotting-walkers.lua", "spears-lift-walkers.lua")
names = ["Jansen", "Klann", "Spears 4-bar", "Chebyshev", "Chebyshev diag", "Chebyshev-Spears", "Chebyshev-Spears diag", "Hoecken 4-bar", "Hoecken 4-bar diag", "Hoecken slider", "Hoecken-Spears slider", "Hoecken-Spears 4-bar", "Hoecken-Spears 4-bar diag", "Hoecken-Spears long-stance", "Hoecken-Spears long-stance diag", "Spears lift 44", "Spears lift 44 diag", "Spears lift 53", "Spears lift 53 diag"]
def clear(n):
    f = f"{R}_rf_{abs(hash(n))}.lua"
    open(f, "w").write(f'dofile("trotting-walkers.lua"); dofile("spears-lift-walkers.lua"); ONLY="{n}"; AMP=0; SEED=1\ndofile("/home/claude/work/chassisprobe2.lua")\n')
    o = subprocess.run(["/home/claude/build/release/bpp", "-f", os.path.basename(f), "-n", "610"], cwd=R, capture_output=True, text=True, env=dict(os.environ, QT_QPA_PLATFORM="offscreen")).stdout
    os.remove(f)
    m = re.search(r"\|clear ([\d.-]+)\|base ([\d.]+)\|track ([\d.]+)\|scale ([\d.]+)", o)
    return n, float(m.group(1)), float(m.group(4))
def update(n, delta_units):
    for fn in FILES:
        s = open(R + fn).read()
        m = re.search(r'\{ name = "%s",.*' % re.escape(n), s)
        if not m: continue
        line = m.group(0)
        old = float(re.search(r'bodyRaise = ([-\d.]+)', line).group(1))
        s = s.replace(line, re.sub(r"bodyRaise = [-\d.]+", f"bodyRaise = {old + delta_units:.3f}", line, count=1))
        open(R + fn, "w").write(s); return old, old + delta_units
for rnd in range(4):
    with ThreadPoolExecutor(2) as ex: res = list(ex.map(clear, names))
    worst = 0
    for n, c, S in res:
        worst = max(worst, abs(c - TGT(n)))
        if abs(c - TGT(n)) > 0.05: update(n, (TGT(n) - c) / S)
    print(f"round {rnd}: " + ", ".join(f"{n} {c:.2f}" for n, c, S in res), flush=True)
    if worst <= 0.05: break
