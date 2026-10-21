#!/usr/bin/env python3
# Spears 4-bar: its own timing, sides and trot, forward and reversed, flat 8 cm feet,
# on flat ground and the four bumpy terrains (AMP 2/4/6, BUMP 15, seeds 1-2). Resumable.
import os, subprocess, tempfile
from concurrent.futures import ThreadPoolExecutor
ROOM = "/home/claude/bpp/demo/WyomingWill/WalkerRoom"
BPP = "/home/claude/build/release/bpp"
OUT = "/home/claude/work/gaits_s4.txt"
GAITS = {"own": "", "sides": "GAIT={0,0,180,180}", "trot": "GAIT={0,180,180,0}"}
jobs = []
for g in GAITS:
    for d in ("fwd", "rev"):
        for s in (1, 2): jobs.append((g, d, "flat", 0, s))
        for t in ("waves", "random", "logs", "steps"):
            for a in (2, 4, 6):
                for s in (1, 2): jobs.append((g, d, t, a, s))
done = open(OUT).read() if os.path.exists(OUT) else ""
key = lambda j: f"{j[0]}|{j[1]}|{j[2]}|TRACK Spears 4-bar|height {j[3]:.2f}|length 15.0|seed {j[4]}|"
jobs = [j for j in jobs if key(j) not in done]
print(len(jobs), "to run", flush=True)
def run(j):
    g, d, t, a, s = j
    extra = "; ".join(x for x in (GAITS[g], "REVERSE=true" if d == "rev" else "") if x)
    code = (f'ONLY="Spears 4-bar"; TERRAIN="{"waves" if t == "flat" else t}"; AMP={a}; BUMP=15; SEED={s}; {extra}\n'
            'dofile("test-track.lua")\n')
    fd, p = tempfile.mkstemp(suffix=".lua", prefix="_g4_", dir=ROOM); os.write(fd, code.encode()); os.close(fd)
    try:
        out = subprocess.run([BPP, "-f", os.path.basename(p), "-n", "3700"], cwd=ROOM, capture_output=True, text=True,
                             env=dict(os.environ, QT_QPA_PLATFORM="offscreen")).stdout
    finally: os.remove(p)
    m = [l for l in out.splitlines() if l.startswith("TRACK ")]
    return f"{g}|{d}|{t}|" + (m[0] if m else f"FAILED {a}|{s}")
with open(OUT, "a") as f, ThreadPoolExecutor(2) as pool:
    for line in pool.map(run, jobs):
        f.write(line + "\n"); f.flush()
print("GAITS DONE", flush=True)
