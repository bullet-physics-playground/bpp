"""Collect the optimiser results (runs/scan_*.log RESULT lines): best margin per
weight and size -> runs/materials.json"""
import re, glob, json
rows = {}
for f in glob.glob("runs/scan_*.log") + glob.glob("runs/refine_*.log"):
    for line in open(f):
        m = re.match(r"RESULT (\S+) H=(\d+) t=([\d.]+): margin ([-\d.]+) mm \(face ([-\d.]+) vert ([-\d.]+), base ([-\d.]+)\) gap ([-\d.]+) mass ([\d.]+) g \(PLA ([\d.]+), weights ([\d.]+)\) zc ([\d.]+) D ([\d.]+)", line)
        if not m: continue
        w, H = m.group(1), int(m.group(2))
        d = dict(weight=w, H=H, margin=float(m.group(4)), face=float(m.group(5)), vert=float(m.group(6)), base=float(m.group(7)),
                 gap=float(m.group(8)), mass=float(m.group(9)), pla=float(m.group(10)), wsum=float(m.group(11)), zc=float(m.group(12)),
                 D=float(m.group(13)), log=f)
        k = (w, H)
        if k not in rows or d['margin'] > rows[k]['margin']: rows[k] = d
out = sorted(rows.values(), key=lambda d: (d['weight'], d['H']))
json.dump(out, open("runs/materials.json", "w"), indent=1)
for d in out: print(f"{d['weight']:18s} H {d['H']:3d}  margin {d['margin']:7.2f}  mass {d['mass']:7.1f}  PLA {d['pla']:6.1f}  PLA share {100*d['pla']/d['mass']:4.1f}%  gap {d['gap']:.2f}  ({d['log']})")
