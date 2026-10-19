"""Slice the print STL with PrusaSlicer (CLI) and check the G-code:
 - every pocket is OPEN (no extrusion inside it) in every layer from its floor to
   the pause layer, and CLOSED (bridged) in the layer after the pause;
 - the big inner void is not filled (no extrusion near the axis at mid height);
 - filament mass vs the design's PLA mass.
usage: python3 slicecheck.py design.npy WEIGHT model.stl out.gcode"""
import numpy as np, sys, re, subprocess, os, json
from w37 import Body
from materials import CAT
from export import pause_table

def slice_(stl, gcode, ini):
    cmd = ["prusa-slicer", "--export-gcode", "--load", ini, "--center", "110,110", "-o", gcode, stl]
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0: print(r.stdout[-2000:], r.stderr[-2000:]); raise SystemExit("slicing failed")

def parse(gcode):
    layers = {}; z = None; x = y = 0.0; typ = None; meta = {}
    for line in open(gcode):
        if line.startswith(';Z:'):
            z = round(float(line[3:]), 3); layers.setdefault(z, [])
        elif line.startswith(';TYPE:'): typ = line[6:].strip()
        elif line.startswith('G1') or line.startswith('G0'):
            mx = re.search(r'X([-\d.]+)', line); my = re.search(r'Y([-\d.]+)', line); me = re.search(r'E([-\d.]+)', line)
            nx = float(mx.group(1)) if mx else x; ny = float(my.group(1)) if my else y
            if me and float(me.group(1)) > 0 and z is not None and (mx or my):
                layers[z].append((x, y, nx, ny, typ))
            x, y = nx, ny
        elif line.startswith('; filament used [g]'): meta['g'] = float(line.split('=')[1])
        elif line.startswith('; filament used [cm3]'): meta['cm3'] = float(line.split('=')[1])
        elif line.startswith('; estimated printing time (normal mode)'): meta['time'] = line.split('=')[1].strip()
    return layers, meta

def seg_min_dist(segs, p):
    if not segs: return np.inf
    S = np.array([s[:4] for s in segs]); a = S[:, :2]; b = S[:, 2:]
    ab = b - a; L2 = (ab * ab).sum(1); L2[L2 == 0] = 1e-12
    t = np.clip(((p - a) * ab).sum(1) / L2, 0, 1)
    d = np.linalg.norm(a + t[:, None] * ab - p, axis=1)
    return d.min()

def main(fx, wname, stl, gcode, ini="slicer/w37-pla.ini"):
    x = np.load(fx); W = CAT[wname]; B = Body(x, W)
    slice_(stl, gcode, ini)
    layers, meta = parse(gcode)
    zs = np.array(sorted(layers))
    off = np.array([110.0, 110.0])
    pt = pause_table(B)
    groups = {"apex": [0]}; groups.update({f"ring {i}": list(range(1 + 6 * i, 7 + 6 * i)) for i in range(6)})
    rep = []; ok_all = True
    for r in pt:
        idx = groups[r['name']]; zp = r['pause_after']
        zopen = zs[(zs - 0.1 > r['floor'] - 1e-6) & (zs <= zp + 1e-6)]     # layers whose middle is inside the pocket
        znext = zs[zs > zp + 1e-6][0]
        worst_open = np.inf; worst_close = 0.0
        for i in idx:
            c = B.P[i][:2] + off
            for z in zopen: worst_open = min(worst_open, seg_min_dist(layers[z], c))
            worst_close = max(worst_close, seg_min_dist(layers[znext], c))
        ok = worst_open > W.a - 0.05 and worst_close < W.a / 2
        ok_all &= ok
        rep.append(dict(group=r['name'], pause_after_z=zp, open_layers=len(zopen), first_open=float(zopen.min()) if len(zopen) else None,
                        closest_extrusion_to_pocket_centre_while_open=float(worst_open), pocket_radius=W.a,
                        next_layer=float(znext), closest_extrusion_in_next_layer=float(worst_close), ok=bool(ok)))
    # the void: no extrusion within 15 mm of the axis between 30% and 60% height
    H = x[-1]; vz = zs[(zs > 0.3 * H) & (zs < 0.6 * H)]
    void_min = min(seg_min_dist(layers[z], off) for z in vz)
    out = dict(meta=meta, pla_design_g=B.m_pla, pockets=rep, void_closest_extrusion_to_axis_mm=float(void_min),
               layers=len(zs), all_pockets_ok=bool(ok_all))
    print(json.dumps(out, indent=1))
    return out

if __name__ == "__main__":
    a = sys.argv; r = main(a[1], a[2], a[3], a[4])
    json.dump(r, open(a[4] + ".check.json", "w"), indent=1)
