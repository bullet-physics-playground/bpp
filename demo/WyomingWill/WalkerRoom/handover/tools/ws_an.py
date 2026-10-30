import re, glob, os, statistics as st
exec(open("/home/claude/work/tips_an.py").read().split("def row")[0])
def info(f):
    t = q = None
    for l in open(f):
        if l.startswith("TIME"): t = float(l.split()[1])
        if l.startswith("TQ"):
            m = re.search(r"torque median ([\d.]+) p95 ([\d.]+).*speed ([-\d.]+)-([-\d.]+)", l); q = m.groups()
    return t, q
print(f"{'walker':24s} {'solver':8s} {'it':>4s} {'step':>6s} {'speed':>6s} {'cranks':>12s} {'torque p95':>10s} {'time s':>7s}")
for f in sorted(glob.glob("/home/claude/work/ws/*.txt")):
    b = os.path.basename(f)[:-4]; parts = b.split("_"); fx = parts[-1]; it = parts[-2]; k = parts[-3]; n = " ".join(parts[:-3])
    t, q = info(f); s = sp(f)
    if q and s: print(f"{n:24s} {k:8s} {it:>4s} 1/{fx:>4s} {s[0]:6.2f} {q[2]+'..'+q[3]:>12s} {q[1]:>10s} {t:7.0f}")
