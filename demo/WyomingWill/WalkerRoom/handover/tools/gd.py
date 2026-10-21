#!/usr/bin/env python3
# Guides against diag braces, trot, forward, Earth standard, own crank speed (k=1), seed 1. Resumable.
import os, subprocess, tempfile
from concurrent.futures import ThreadPoolExecutor
ROOM = "/home/claude/bpp/demo/WyomingWill/WalkerRoom"; BPP = "/home/claude/build/release/bpp"
OUT = "/home/claude/work/gd/gd.txt"
EARTH = 'GRAVITY=981; FIXED=1/3840; YAW_DAMP=1; ANKLE_SPRING={stiffness=42000, damping=4200}'
PAIRS = ["Chebyshev", "Chebyshev-Spears", "Hoecken 4-bar", "Hoecken-Spears 4-bar",
         "Hoecken-Spears long-stance", "Spears lift 44", "Spears lift 53"]
CFG = []
for n in PAIRS:
    CFG.append(("guides", n, n, 'UNBRACED={["%s"]=true}; GAIT={0,180,180,0}' % n))
    CFG.append(("diag", n, n + " diag", ""))
TERR = [("flat", "waves", 0, 22), ("waves", "waves", 4, 15), ("logs", "logs", 5, 15), ("steps", "steps", 4, 15)]
jobs = [(c, t) for c in CFG for t in TERR]
done = open(OUT).read() if os.path.exists(OUT) else ""
jobs = [j for j in jobs if f"{j[0][0]}|{j[0][1]}|{j[1][0]}|" not in done]
print(len(jobs), "to run", flush=True)
def run(j):
    (br, link, walker, extra), (tn, terrain, amp, bump) = j
    parts = ['dofile("trotting-walkers.lua")', 'dofile("spears-lift-walkers.lua")', f'ONLY="{walker}"',
             f'TERRAIN="{terrain}"', f'AMP={amp}', f'BUMP={bump}', 'SEED=1', EARTH] + ([extra] if extra else [])
    code = "; ".join(parts) + '\ndofile("/home/claude/work/tiltprobe.lua")\n'
    fd, p = tempfile.mkstemp(suffix=".lua", prefix="_gd_", dir=ROOM); os.write(fd, code.encode()); os.close(fd)
    try:
        out = subprocess.run([BPP, "-f", os.path.basename(p), "-n", "3700"], cwd=ROOM, capture_output=True, text=True,
                             timeout=3600, env=dict(os.environ, QT_QPA_PLATFORM="offscreen")).stdout
    finally: os.remove(p)
    tr = [l for l in out.splitlines() if l.startswith("TRACK ")]; ti = [l for l in out.splitlines() if l.startswith("TILT ")]
    return f"{br}|{link}|{tn}|" + ((tr[0] + "|" + (ti[0] if ti else "TILT ?")) if tr else "FAILED")
with open(OUT, "a") as f, ThreadPoolExecutor(2) as pool:
    for line in pool.map(run, jobs): f.write(line + "\n"); f.flush()
print("GD DONE", flush=True)
