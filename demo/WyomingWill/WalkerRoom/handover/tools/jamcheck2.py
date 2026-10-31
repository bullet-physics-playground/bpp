import subprocess, os, re, sys
EXTRA = sys.argv[1] if len(sys.argv) > 1 else ""
from concurrent.futures import ThreadPoolExecutor
D = "/home/claude/bpp/demo/WyomingWill/WalkerRoom"
names = ["Jansen", "Klann", "Spears 4-bar", "Chebyshev", "Chebyshev diag", "Chebyshev-Spears", "Chebyshev-Spears diag", "Hoecken 4-bar", "Hoecken 4-bar diag", "Hoecken slider", "Hoecken-Spears slider", "Hoecken-Spears 4-bar", "Hoecken-Spears 4-bar diag", "Hoecken-Spears 4-bar duty 85", "Hoecken-Spears 4-bar duty 85 diag", "Chebyshev-Spears lift 51", "Chebyshev-Spears lift 51 diag", "Chebyshev-Spears lift 62", "Chebyshev-Spears lift 62 diag"]
fwd = {"Chebyshev-Spears lift 51", "Chebyshev-Spears lift 51 diag", "Chebyshev-Spears lift 62"}
conds = [(0, 22, "waves"), (6, 11, "waves"), (4, 11, "logs"), (4, 15, "steps")]
def run(a):
    n, (amp, bump, ter) = a
    f = f"{D}/_j_{abs(hash(a))}.lua"
    open(f, "w").write(f'dofile("trotting-walkers.lua"); dofile("spears-lift-walkers.lua"); ONLY="{n}"; {EXTRA} AMP={amp}; BUMP={bump}; TERRAIN="{ter}"; SEED=2; REVERSE={"false" if n in fwd else "true"}\ndofile("/home/claude/work/linkprobe3.lua")\n')
    o = subprocess.run(["/home/claude/build/release/bpp", "-f", os.path.basename(f), "-n", "3700"], cwd=D, capture_output=True, text=True, env=dict(os.environ, QT_QPA_PLATFORM="offscreen")).stdout
    os.remove(f)
    m = re.search(r"touching ([\d.]+)%.*?\|impulse [\d.]+\|(.*)\|bodyground ([\d.]+)%", o); t = re.search(r"\|([-\d.]+) cm/s", o)
    return n, ter, amp, (float(m.group(1)) if m else -1), (m.group(2)[:70] if m else o[-200:]), (float(t.group(1)) if t else None), (float(m.group(3)) if m else -1), re.search(r"hitx (\S+ \S+)", o).group(1) if m else ""
jobs = [(n, c) for n in names for c in conds]
with ThreadPoolExecutor(int(os.environ.get('J','2'))) as ex:
    res = list(ex.map(run, jobs))
for n in names:
    r = [x for x in res if x[0] == n]
    print(f"{n:32s} touching {max(x[3] for x in r):5.1f}%  body-on-ground {max(x[6] for x in r):5.1f}%  speeds flat/waves6/logs/steps {[x[5] for x in r]}  {[x[4] for x in r if x[3] > 0]}", flush=True)

for x in res: print("ROW", x[0], x[1], x[2], "bodyground", x[6], "hitx", x[7], "speed", x[5])
