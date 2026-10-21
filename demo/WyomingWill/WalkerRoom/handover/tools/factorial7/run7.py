#!/usr/bin/env python3
# Factorial runs at the Earth standard (HANDOVER.md section 6):
#   gravity 981, step 1/3840, body free to pitch and roll (YAW_DAMP=1),
#   soft-spring ankles scaled x14. No sides gaits.
#
#   python3 run7.py list            the configurations and run counts, runs nothing
#   python3 run7.py screen [part]   stage A: calibrate on flat, then 4 screening runs per config
#   python3 run7.py pick            choose stage B's configs from stage A (writes picks.json)
#   python3 run7.py full [part]     stage B: the full terrain set for the picked configs
#
# Resumable: finished runs are skipped. 2 runs at once (2 CPUs).
# Lines written: <terrain>|TRACK ...|TILT ...
import json, os, re, subprocess, sys, tempfile
from concurrent.futures import ThreadPoolExecutor
ROOM = "/home/claude/bpp/demo/WyomingWill/WalkerRoom"
BPP = "/home/claude/build/release/bpp"
PROBE = "/home/claude/work/tiltprobe.lua"     # test-track.lua plus a TILT line (largest pitch and roll)
D = "/home/claude/work/fac7"
os.makedirs(D, exist_ok=True)
EARTH = ["GRAVITY=981", "FIXED=1/3840", "YAW_DAMP=1", "ANKLE_SPRING={stiffness=42000, damping=4200}"]
HL = 'dofile("spears-lift-walkers.lua")'
TW = 'dofile("trotting-walkers.lua")'

# Leg order in GAIT: side A leg 1, side A leg 2, side B leg 1, side B leg 2.
TROT = (0, 180, 180, 0)
GAITS = {"trot": TROT, "bound": (0, 180, 0, 180)}
# The 4-beat walks: of the six orders of 90/180/270, two pairs are the same
# walk with the sides swapped (0/90/270/180 = 0/270/90/180, 0/180/90/270 =
# 0/180/270/90), so one of each pair; the other two are their own mirrors.
for p in ((90, 180, 270), (270, 180, 90), (90, 270, 180), (180, 90, 270)):
    GAITS["walk " + "-".join(str(x) for x in (0,) + p)] = (0,) + p
OWN_S4 = (0, 225, 180, 225)                                  # Spears 4-bar as built
def G(t): return "GAIT={%d,%d,%d,%d}" % t
def U(n): return 'UNBRACED={["%s"]=true}' % n

configs = []   # (id, linkage, bracing, timing, direction, walker, extra list)
def add(link, brace, timing, walker, extra):
    for d in ("fwd", "rev"):
        e = extra + (["REVERSE=true"] if d == "rev" else [])
        cid = re.sub(r"[^A-Za-z0-9]+", "_", f"{link}_{brace}_{timing}_{d}")
        configs.append((cid, link, brace, timing, d, walker, e))
# Own-frame walkers: free gaits.
for n in ("Jansen", "Klann", "Spears 4-bar"):
    for g, t in GAITS.items(): add(n, "own", g, n, [G(t)])
add("Spears 4-bar", "own", "its own", "Spears 4-bar", [])
# Plated builds: plates force sides (dropped). Diag braces trot; guides trot.
# (every run loads trotting-walkers.lua and spears-lift-walkers.lua, which hold the diag and lift builds)
for n, diag in (("Chebyshev", "Chebyshev diag"), ("Chebyshev-Spears", "Chebyshev-Spears diag"),
                ("Hoecken 4-bar", "Hoecken 4-bar diag"), ("Hoecken-Spears 4-bar", "Hoecken-Spears 4-bar diag"),
                ("Hoecken-Spears long-stance", "Hoecken-Spears long-stance diag"),
                ("Hoecken slider", None), ("Hoecken-Spears slider", None),
                ("Spears lift 44", "Spears lift 44 diag"), ("Spears lift 53", "Spears lift 53 diag")):
    if diag: add(n, "diag", "trot", diag, [])
    add(n, "guides", "trot", n, [U(n), G(TROT)])

CAL = (0, 22)                                    # flat: waves AMP 0, BUMP 22, seeds 1 and 2
SCREEN = [("waves", 4), ("random", 4), ("logs", 5), ("steps", 4)]   # seed 1
FULL = [(t, a) for t in ("waves", "random", "steps") for a in (2, 4, 6)] + [("logs", h) for h in (4, 5, 6, 7, 8)]
BUMP = 15
SEEDS = (1, 2)

def run(walker, extra, terrain, amp, bump, seed, scale):
    parts = [TW, HL, f'ONLY="{walker}"', f'TERRAIN="{terrain}"', f"AMP={amp}", f"BUMP={bump}", f"SEED={seed}",
             f"CRANK_SCALE={scale}"] + EARTH + [x for x in extra if x]
    code = "; ".join(parts) + f'\ndofile("{PROBE}")\n'     # (Lua 5.1: no empty statements)
    fd, p = tempfile.mkstemp(suffix=".lua", prefix="_f7_", dir=ROOM); os.write(fd, code.encode()); os.close(fd)
    try:
        out = subprocess.run([BPP, "-f", os.path.basename(p), "-n", "3700"], cwd=ROOM, capture_output=True, text=True,
                             timeout=3600, env=dict(os.environ, QT_QPA_PLATFORM="offscreen")).stdout
    except subprocess.TimeoutExpired:
        out = ""
    finally:
        os.remove(p)
    tr = [l for l in out.splitlines() if l.startswith("TRACK ")]
    ti = [l for l in out.splitlines() if l.startswith("TILT ")]
    return (tr[0] + "|" + (ti[0] if ti else "TILT ?")) if tr else f"TRACK {walker}|height {amp:.2f}|length {bump:.1f}|seed {seed}|FAILED"
def speed(line):
    m = re.search(r"\|([-\d.]+) cm/s", line); return float(m.group(1)) if m else float("nan")

pool = ThreadPoolExecutor(2)
calf = f"{D}/cal.json"
cal = json.load(open(calf)) if os.path.exists(calf) else {}

def calibrate(cid, walker, extra):
    if cid in cal: return cal[cid]["k"]
    k, hist = 1.0, []
    for _ in range(3):
        v = sum(speed(l) for l in pool.map(lambda s: run(walker, extra, "waves", CAL[0], CAL[1], s, k), SEEDS)) / 2
        hist.append((round(k, 4), v))
        if v <= 0.5 or v != v or abs(v - 9) < 0.15: break
        nk = min(1.0, k * 9 / v)          # cap: never faster than the walker's own crank speed
        if nk == k: break
        k = nk
    cal[cid] = {"k": k, "hist": hist}
    json.dump(cal, open(calf, "w"), indent=1)
    print(cid, hist, flush=True)
    return k

def do(cid, walker, extra, k, todo, of):
    done = open(of).read() if os.path.exists(of) else ""
    todo = [(t, a, s) for t, a, s in todo if f"{t}|TRACK {walker}|height {a:.2f}|length {BUMP:.1f}|seed {s}|" not in done]
    with open(of, "a") as f:
        for (t, a, s), line in zip(todo, pool.map(lambda x: run(walker, extra, x[0], x[1], BUMP, x[2], k), todo)):
            f.write(f"{t}|{line}\n"); f.flush()

def score(of):     # mean speed over the file's runs
    v = [speed(l) for l in open(of)] if os.path.exists(of) else []
    v = [x for x in v if x == x]
    return sum(v) / len(v) if v else float("nan")

mode = sys.argv[1] if len(sys.argv) > 1 else "list"
part = sys.argv[2:]          # optional: only configs whose id contains one of these
sel = [c for c in configs if not part or any(o in c[0] for o in part)]
if mode == "list":
    for c in configs: print(c[0], "|", c[5], "|", "; ".join(c[6]))
    n = len(configs)
    print(f"\n{n} configs. Screen: {n} x (4 calibration + {len(SCREEN)}) = {n * (4 + len(SCREEN))} runs (calibration is 2-6).")
    print(f"Full: per picked config {len(FULL) * len(SEEDS)} runs.")
elif mode == "screen":
    for cid, link, brace, timing, d, walker, extra in sel:
        k = calibrate(cid, walker, extra)
        do(cid, walker, extra, k, [(t, a, 1) for t, a in SCREEN], f"{D}/A_{cid}.txt")
    print("SCREEN DONE", flush=True)
elif mode == "pick":
    # Per linkage: its 2 best screened configs, plus its trot on guides (own frame for
    # Jansen, Klann, Spears 4-bar) both ways, for the everyone-at-trot table.
    picks = []
    for link in dict.fromkeys(c[1] for c in configs):
        mine = [c for c in configs if c[1] == link]
        best = sorted(mine, key=lambda c: -score(f"{D}/A_{c[0]}.txt"))[:2]
        ctrl = [c for c in mine if c[3] == "trot" and c[2] in ("guides", "own")]
        for c in best + ctrl:
            if c[0] not in picks: picks.append(c[0])
        print(link, [(c[0], round(score(f"{D}/A_{c[0]}.txt"), 2)) for c in best])
    json.dump(picks, open(f"{D}/picks.json", "w"), indent=1)
    print(len(picks), "picked;", len(picks) * len(FULL) * len(SEEDS), "full runs")
elif mode == "full":
    picks = json.load(open(f"{D}/picks.json"))
    for cid, link, brace, timing, d, walker, extra in sel:
        if cid not in picks: continue
        do(cid, walker, extra, cal[cid]["k"], [(t, a, s) for t, a in FULL for s in SEEDS], f"{D}/B_{cid}.txt")
    print("FULL DONE", flush=True)
