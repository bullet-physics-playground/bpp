#!/usr/bin/env python3
# Factorial runs: per configuration, calibrate crank so flat speed = 9, then the waves set.
import json, os, re, subprocess, sys, tempfile
from concurrent.futures import ThreadPoolExecutor
ROOM = "/home/claude/bpp/demo/WyomingWill/WalkerRoom"
BPP = "/home/claude/build/release/bpp"
D = "/home/claude/work/fac5"   # (a fresh folder: every earlier result used the old geometry)
os.makedirs(D, exist_ok=True)
HL = 'dofile("spears-lift-walkers.lua")'
TW = 'dofile("trotting-walkers.lua")'
D2 = 'dofile("spears-lift-walkers.lua")'
TROT = "GAIT={0,180,180,0}"
def U(n): return 'UNBRACED={["%s"]=true}' % n
configs = []   # (id, linkage, bracing, timing, direction, walker, extra)
def add(link, brace, timing, walker, extra):
    for d in ("fwd", "rev"):
        e = extra + (["REVERSE=true"] if d == "rev" else [])
        cid = re.sub(r"[^A-Za-z0-9]+", "_", f"{link}_{brace}_{timing}_{d}")
        configs.append((cid, link, brace, timing, d, walker, "; ".join(e)))
for n in ("Jansen", "Klann", "Spears 4-bar"):
    add(n, "own", "sides", n, []); add(n, "own", "trot", n, [TROT])
for n, diag, ex in (("Chebyshev", "Chebyshev diag", []), ("Chebyshev-Spears", "Chebyshev-Spears diag", []),
                    ("Hoecken 4-bar", "Hoecken 4-bar diag", [TW]), ("Hoecken-Spears 4-bar", "Hoecken-Spears 4-bar diag", [TW]),
                    ("Hoecken-Spears long-stance", "Hoecken-Spears long-stance diag", [D2]), ("Hoecken slider", None, []), ("Hoecken-Spears slider", None, []),
                    ("Spears lift 44", "Spears lift 44 diag", [D2]), ("Spears lift 53", "Spears lift 53 diag", [D2])):
    base = [HL] if n.startswith("Spears lift") else []
    add(n, "plates", "sides", n, base)
    if diag: add(n, "diag", "trot", diag, ex)
    add(n, "guides", "sides", n, base + [U(n)])
    add(n, "guides", "trot", n, base + [U(n), TROT])

def run(walker, extra, amp, bump, seed, scale):
    code = f'ONLY="{walker}"; AMP={amp}; BUMP={bump}; SEED={seed}; CRANK_SCALE={scale}; {extra}\ndofile("test-track.lua")\n'
    fd, p = tempfile.mkstemp(suffix=".lua", prefix="_fac_", dir=ROOM); os.write(fd, code.encode()); os.close(fd)
    try:
        out = subprocess.run([BPP, "-f", os.path.basename(p), "-n", "3700"], cwd=ROOM, capture_output=True, text=True,
                             env=dict(os.environ, QT_QPA_PLATFORM="offscreen")).stdout
    finally: os.remove(p)
    m = [l for l in out.splitlines() if l.startswith("TRACK ")]
    return m[0] if m else f"TRACK {walker}|FAILED"
def speed(line):
    m = re.search(r"\|([-\d.]+) cm/s", line); return float(m.group(1)) if m else float("nan")

pool = ThreadPoolExecutor(2)
calf = f"{D}/cal.json"
cal = json.load(open(calf)) if os.path.exists(calf) else {}
only = sys.argv[1:]
CONDS = [(0, 22), (2, 11), (2, 15), (2, 22), (4, 11), (4, 15), (4, 22), (6, 11), (6, 15), (6, 22)]
for SEEDS in ([1, 2],):
  for cid, link, brace, timing, d, walker, extra in configs:
      if only and not any(o in cid for o in only): continue
      if cid not in cal:
          k, hist = 1.0, []
          for it in range(3):
              v = sum(speed(l) for l in pool.map(lambda s: run(walker, extra, 0, 22, s, k), (1, 2))) / 2
              hist.append((round(k, 4), v))
              if v <= 0.5 or v != v: break
              if abs(v - 9) < 0.15: break
              nk = min(1.0, k * 9 / v)   # never faster than the walker's own crank speed (README, The factorial runs)
              if nk == k: break
              k = nk
          cal[cid] = {"k": k, "hist": hist}
          json.dump(cal, open(calf, "w"), indent=1)
          print(cid, hist, flush=True)
      k = cal[cid]["k"]
      of = f"{D}/{cid}.txt"
      done = open(of).read() if os.path.exists(of) else ""
      todo = [(a, b, s) for a, b in CONDS for s in SEEDS if f"|height {a:.2f}|length {b:.1f}|seed {s}|" not in done]
      with open(of, "a") as f:
          for line in pool.map(lambda t: run(walker, extra, t[0], t[1], t[2], k), todo):
              f.write(line + "\n"); f.flush()
print("ALL DONE", flush=True)
