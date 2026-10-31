#!/usr/bin/env python3
# Every build, as built, on logs: AMP 2/4/6, BUMP 15, seeds 1 and 2. Writes /home/claude/work/logs/results.txt
import os, subprocess, tempfile
from concurrent.futures import ThreadPoolExecutor
ROOM = "/home/claude/bpp/demo/WyomingWill/WalkerRoom"
BPP = "/home/claude/build/release/bpp"
OUT = os.environ.get("OUT", "/home/claude/work/logs/results.txt")
EXTRA = os.environ.get("EXTRA", "")
os.makedirs(os.path.dirname(OUT), exist_ok=True)
NAMES = ["Jansen", "Klann", "Spears 4-bar", "Chebyshev", "Chebyshev diag", "Chebyshev-Spears", "Chebyshev-Spears diag",
         "Hoecken 4-bar", "Hoecken 4-bar diag", "Hoecken slider", "Hoecken-Spears slider", "Hoecken-Spears 4-bar",
         "Hoecken-Spears 4-bar diag", "Hoecken-Spears 4-bar duty 85", "Hoecken-Spears 4-bar duty 85 diag",
         "Chebyshev-Spears lift 51", "Chebyshev-Spears lift 51 diag", "Chebyshev-Spears lift 62", "Chebyshev-Spears lift 62 diag"]
jobs = [(n, a, s) for n in NAMES for a in (2, 4, 6) for s in (1, 2)]
done = open(OUT).read() if os.path.exists(OUT) else ""
jobs = [j for j in jobs if f"LOGS {j[0]}|amp {j[1]}|bump 15|seed {j[2]}|" not in done]
print(len(jobs), "to run", flush=True)
def run(j):
    n, a, s = j
    code = (f'dofile("trotting-walkers.lua"); dofile("spears-lift-walkers.lua")\n'
            f'ONLY="{n}"; TERRAIN="logs"; AMP={a}; BUMP=15; SEED={s}; {EXTRA}\ndofile("/home/claude/work/logprobe.lua")\n')
    fd, p = tempfile.mkstemp(suffix=".lua", prefix="_lg_", dir=ROOM); os.write(fd, code.encode()); os.close(fd)
    try:
        out = subprocess.run([BPP, "-f", os.path.basename(p), "-n", "3730"], cwd=ROOM, capture_output=True, text=True,
                             env=dict(os.environ, QT_QPA_PLATFORM="offscreen")).stdout
    finally: os.remove(p)
    keep = [l for l in out.splitlines() if l.startswith(("TRACK ", "LOGS "))]
    return "\n".join(keep) if keep else f"FAILED {n}|{a}|{s}"
with open(OUT, "a") as f, ThreadPoolExecutor(2) as pool:
    for r in pool.map(run, jobs):
        f.write(r + "\n"); f.flush()
print("LOGS DONE")
