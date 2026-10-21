#!/usr/bin/env python3
# Body damping test: 6 walkers as built (+ Klann and Jansen trotting), soft feet,
# body angular damping 1.0 (files') / 0.1 every axis / yaw only, on flat and four
# bumpy terrains (AMP 2/4/6, BUMP 15, seeds 1-2). Resumable. Lines: setting|config|terrain|TRACK...|TILT...
import os, subprocess, tempfile
from concurrent.futures import ThreadPoolExecutor
ROOM = "/home/claude/bpp/demo/WyomingWill/WalkerRoom"
BPP = "/home/claude/build/release/bpp"
OUT = "/home/claude/work/damp6.txt"
SOFT = "ANKLE_SPRING={stiffness=3000, damping=300}"
CONFIGS = {   # name: (walker, extra)
    "Spears lift 44 (plates, sides)": ("Spears lift 44", ""),
    "Spears lift 44 diag (diag, trot)": ("Spears lift 44 diag", ""),
    "Klann (own, sides)": ("Klann", ""),
    "Klann (own, trot)": ("Klann", "GAIT={0,180,180,0}"),
    "Jansen (own, sides)": ("Jansen", ""),
    "Jansen (own, trot)": ("Jansen", "GAIT={0,180,180,0}"),
    "Chebyshev-Spears (plates, sides)": ("Chebyshev-Spears", ""),
    "Spears 4-bar (own, its own timing)": ("Spears 4-bar", ""),
}
SETTINGS = {"damp 1.0": "", "damp 0.1": "BODY_ANG_DAMP=0.1", "yaw only": "YAW_DAMP=1"}
jobs = []
for st in SETTINGS:
    for c in CONFIGS:
        for s in (1, 2): jobs.append((st, c, "flat", 0, s))
        for t in ("waves", "random", "logs", "steps"):
            for a in (2, 4, 6):
                for s in (1, 2): jobs.append((st, c, t, a, s))
done = open(OUT).read() if os.path.exists(OUT) else ""
key = lambda j: f"{j[0]}|{j[1]}|{j[2]}|TRACK {CONFIGS[j[1]][0]}|height {j[3]:.2f}|length 15.0|seed {j[4]}|"
jobs = [j for j in jobs if key(j) not in done]
print(len(jobs), "to run", flush=True)
def run(j):
    st, c, t, a, s = j
    walker, extra = CONFIGS[c]
    parts = ['dofile("trotting-walkers.lua")', 'dofile("spears-lift-walkers.lua")', f'ONLY="{walker}"',
             f'TERRAIN="{"waves" if t == "flat" else t}"', f'AMP={a}', 'BUMP=15', f'SEED={s}', SOFT] + [x for x in (extra, SETTINGS[st]) if x]
    code = "; ".join(parts) + '\ndofile("/home/claude/work/tiltprobe.lua")\n'
    fd, p = tempfile.mkstemp(suffix=".lua", prefix="_dm_", dir=ROOM); os.write(fd, code.encode()); os.close(fd)
    try:
        out = subprocess.run([BPP, "-f", os.path.basename(p), "-n", "3700"], cwd=ROOM, capture_output=True, text=True,
                             env=dict(os.environ, QT_QPA_PLATFORM="offscreen")).stdout
    finally: os.remove(p)
    tr = [l for l in out.splitlines() if l.startswith("TRACK ")]; ti = [l for l in out.splitlines() if l.startswith("TILT ")]
    return f"{st}|{c}|{t}|" + (tr[0] + "|" + (ti[0] if ti else "TILT ?") if tr else f"FAILED {walker} {a} {s}")
with open(OUT, "a") as f, ThreadPoolExecutor(2) as pool:
    for line in pool.map(run, jobs):
        f.write(line + "\n"); f.flush()
print("DAMP DONE", flush=True)
