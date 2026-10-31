#!/usr/bin/env python3
# Jam check at LINK_WIDTH 1.0, the Earth standard, trot, as each build is run (own frames and guides at trot; diag with
# outside V braces and held pendants), 30 s on flat, waves 6 (bump 11), logs 4 (bump 11), steps 4 (bump 15), seed 2,
# forward: how often its own parts touch each other (by kind), and the body on the ground (linkprobe3.lua). Resumable.
import subprocess, os, re, sys, json
from concurrent.futures import ThreadPoolExecutor
D = "/home/claude/bpp/demo/WyomingWill/WalkerRoom"; OUT = os.environ.get("JAM_OUT", "/home/claude/work/jamW"); os.makedirs(OUT, exist_ok=True)
EXTRA = os.environ.get("JAM_EXTRA", "LINK_WIDTH=1.0")
STD = 'GRAVITY=981; FIXED=1/3840; YAW_DAMP=1; ANKLE_SPRING={stiffness=42000, damping=4200}; TRACK_SECS=30; SELF_AT=1920'
own = ["Jansen", "Klann", "Spears 4-bar"]
guides = ["Chebyshev", "Chebyshev-Spears", "Hoecken 4-bar", "Hoecken slider", "Hoecken-Spears slider", "Hoecken-Spears 4-bar", "Hoecken-Spears 4-bar duty 85", "Chebyshev-Spears lift 51", "Chebyshev-Spears lift 62"]
diag = ["Chebyshev diag", "Chebyshev-Spears diag", "Hoecken 4-bar diag", "Hoecken-Spears 4-bar diag", "Hoecken-Spears 4-bar duty 85 diag", "Chebyshev-Spears lift 51 diag", "Chebyshev-Spears lift 62 diag"]
conds = [c for c in [(0, 22, "waves"), (6, 11, "waves"), (4, 11, "logs"), (4, 15, "steps")] if os.environ.get("JAM_CONDS", "all") == "all" or f"{c[2]}{c[0]}" in os.environ["JAM_CONDS"].split(",")]
def setting(n):
    if n in diag: return "DIAG_OUTSIDE=true; OUTSIDE_V=true; PENDANT_HOLD=true"
    if n in guides: return "UNBRACED=true; GAIT={0,180,180,0}"
    return "GAIT={0,180,180,0}"
def run(a):
    n, (amp, bump, ter) = a
    tag = f"{n.replace(' ', '_')}_{ter}{amp}"
    out = f"{OUT}/{tag}.txt"
    if os.path.exists(out) and "SELF" in open(out).read(): return
    f = f"{D}/_jw_{abs(hash(a))}.lua"
    open(f, "w").write(f'dofile("trotting-walkers.lua"); dofile("spears-lift-walkers.lua"); ONLY="{n}"; {STD}; {EXTRA}; {setting(n)}; AMP={amp}; BUMP={bump}; TERRAIN="{ter}"; SEED=2\ndofile("/home/claude/work/linkprobe3_at.lua")\n')
    o = subprocess.run(["/home/claude/build/release/bpp", "-f", os.path.basename(f), "-n", "1925"], cwd=D, capture_output=True, text=True, env=dict(os.environ, QT_QPA_PLATFORM="offscreen")).stdout
    os.remove(f)
    open(out, "w").write("\n".join(l for l in o.splitlines() if l.startswith(("SELF", "TRACK"))) + "\n")
jobs = [(n, c) for n in own + guides + diag for c in conds]
with ThreadPoolExecutor(2) as ex: list(ex.map(run, jobs))
print("JAMW_DONE")
