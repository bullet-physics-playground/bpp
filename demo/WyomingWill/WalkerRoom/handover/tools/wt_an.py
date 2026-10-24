#!/usr/bin/env python3
import re, glob, math, statistics as st
D = "/home/claude/work/outb"; import sys; P = sys.argv[1] if len(sys.argv) > 1 else "W"
def one(f):
    t = open(f).read()
    m = re.search(r"\|([-\d.]+) cm/s", t)
    if not m: return None
    S = [l.split("|") for l in t.splitlines() if l.startswith("STALL")]
    xs = [float(s[1].split()[1]) for s in S]; zs = [float(s[2].split()[1]) for s in S]
    stuck = sum(1 for i in range(1, len(S)) if math.hypot(xs[i] - xs[i-1], zs[i] - zs[i-1]) < 2)
    slip = sum(float(s[8].split()[1]) for s in S[1:]) / max(1, len(S) - 1)
    pitch = sum(float(s[4].split()[1]) for s in S[1:]) / max(1, len(S) - 1)
    roll = sum(float(s[5].split()[1]) for s in S[1:]) / max(1, len(S) - 1)
    turns = sum(float(s[6].split()[1]) for s in S[1:]) / max(1, len(S) - 1)
    v = re.search(r"spin (\d+) deg/s\|>200 ([\d.]+)%\|jitter ([\d.]+) cm/s\|bounce ([\d.]+) cm/s", t)
    c = re.search(r"CONTACTS [^|]*\|(.*)", t)
    sd_ = re.search(r"sideways ([-\d.]+) cm", t)
    return dict(side=float(sd_.group(1)) if sd_ else 0, v=float(m.group(1)), stuck=stuck, slip=slip, pitch=pitch, roll=roll, turns=turns, spin=float(v.group(1)) if v else 0, jit=float(v.group(3)) if v else 0, contacts=c.group(1) if c else "")
print("WEIGHT TEST (waves 4, bump 15, 60 s, Earth standard, trot, forward; equal cranks; springs scaled to weight)")
print(f"{'':34s} {'speed per seed':>24s} {'mean':>5s} {'sd':>4s} | {'stuck':>5s} {'slip':>4s} {'turns/s':>7s} | {'pitch':>5s} {'roll':>5s} | {'spin':>4s} {'jit':>4s}")
for w, nm in (("CS", "Chebyshev-Spears"), ("H4", "Hoecken-Spears 4-bar")):
    for k, lab in (("full", "diag, outside braces x1"), ("half", "diag, outside braces x0.5"), ("ghost", "diag, outside braces x0.02"), ("guides", "guides")):
        R = [r for r in (one(f) for f in sorted(glob.glob(f"{D}/{P}_{w}_{k}_[1-4].txt"))) if r]
        if not R: continue
        sp = [r["v"] for r in R]; m = st.mean(sp); sd = st.stdev(sp) if len(sp) > 1 else 0
        a = lambda q: st.mean(r[q] for r in R)
        print(f"{nm + ' ' + lab:34s}"[:34] + f" {' '.join(f'{x:5.2f}' for x in sp):>24s} {m:5.2f} {sd:4.2f} | {a('stuck'):5.1f} {a('slip'):4.1f} {a('turns'):7.3f} | {a('pitch'):5.1f} {a('roll'):5.1f} | {a('spin'):4.0f} {a('jit'):4.1f} | sideways {' '.join(f"{r['side']:+.0f}" for r in R)}")
        cs = set(r["contacts"] for r in R)
        print(f"{'':34s} contacts: {' / '.join(cs)}")
