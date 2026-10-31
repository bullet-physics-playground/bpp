#!/usr/bin/env python3
# Flat feet vs point feet (38 cm stance) on every terrain; resumable.
# Writes /home/claude/work/terr/<foot>.txt (TRACK lines, prefixed with the terrain).
import os, subprocess, tempfile
from concurrent.futures import ThreadPoolExecutor
ROOM = "/home/claude/bpp/demo/WyomingWill/WalkerRoom"
BPP = "/home/claude/build/release/bpp"
D = "/home/claude/work/terr"; os.makedirs(D, exist_ok=True)
NAMES = ["Jansen", "Klann", "Spears 4-bar", "Chebyshev", "Chebyshev diag", "Chebyshev-Spears", "Chebyshev-Spears diag",
         "Hoecken 4-bar", "Hoecken 4-bar diag", "Hoecken slider", "Hoecken-Spears slider", "Hoecken-Spears 4-bar",
         "Hoecken-Spears 4-bar diag", "Hoecken-Spears 4-bar duty 85", "Hoecken-Spears 4-bar duty 85 diag",
         "Chebyshev-Spears lift 51", "Chebyshev-Spears lift 51 diag", "Chebyshev-Spears lift 62", "Chebyshev-Spears lift 62 diag"]
FEET = {"flat8": "", "point": "FOOT_POINT=0.3", "soft": "ANKLE_SPRING={stiffness=3000, damping=300}"}
jobs = []
for foot in FEET:
    for n in NAMES:
        for s in (1, 2): jobs.append((foot, n, "flat", 0, s))
        for t in ("waves", "random", "steps") + (("logs",) if foot == "point" else ()):
            for a in (2, 4, 6):
                for s in (1, 2): jobs.append((foot, n, t, a, s))
def key(j): return f"{j[2]}|TRACK {j[1]}|height {j[3]:.2f}|length 15.0|seed {j[4]}|"
done = {f: (open(f"{D}/{f}.txt").read() if os.path.exists(f"{D}/{f}.txt") else "") for f in FEET}
jobs = [j for j in jobs if key(j) not in done[j[0]]]
print(len(jobs), "to run", flush=True)
def run(j):
    foot, n, t, a, s = j
    terr = "waves" if t == "flat" else t
    code = (f'dofile("trotting-walkers.lua"); dofile("spears-lift-walkers.lua")\n'
            f'ONLY="{n}"; TERRAIN="{terr}"; AMP={a}; BUMP=15; SEED={s}; {FEET[foot]}\ndofile("test-track.lua")\n')
    fd, p = tempfile.mkstemp(suffix=".lua", prefix="_tr_", dir=ROOM); os.write(fd, code.encode()); os.close(fd)
    try:
        out = subprocess.run([BPP, "-f", os.path.basename(p), "-n", "3700"], cwd=ROOM, capture_output=True, text=True,
                             env=dict(os.environ, QT_QPA_PLATFORM="offscreen")).stdout
    finally: os.remove(p)
    m = [l for l in out.splitlines() if l.startswith("TRACK ")]
    return foot, (f"{t}|" + m[0]) if m else f"{t}|FAILED {n}|{a}|{s}"
files = {f: open(f"{D}/{f}.txt", "a") for f in FEET}
with ThreadPoolExecutor(2) as pool:
    for foot, line in pool.map(run, jobs):
        files[foot].write(line + "\n"); files[foot].flush()
print("TERRAINS DONE", flush=True)
