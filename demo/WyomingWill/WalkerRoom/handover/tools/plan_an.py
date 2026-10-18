import collections
W = collections.OrderedDict()
for l in open("plan.txt"):
    _, rest = l.rstrip("\n").split(" ", 1)
    name, kind, pts = rest.split("|")
    P = [tuple(map(float, p.split(","))) for p in pts.split(";")]
    W.setdefault(name, []).append((kind, P))
def rng(P, i): return min(p[i] for p in P), max(p[i] for p in P)
rows = {}
for name, bodies in W.items():
    body = [P for k, P in bodies if k == "body"][0]
    bx = sum(p[0] for p in body)/8; bz = sum(p[2] for p in body)/8
    z0, z1 = rng(body, 2); bodyW = z1 - z0
    feet = [P for k, P in bodies if k == "buildFoot"]
    links = [P for k, P in bodies if k not in ("body", "buildFoot") and "Crossbar" not in k]
    fz = [rng(P, 2) for P in feet]
    stance = max(b for a, b in fz) - min(a for a, b in fz)
    offs = []
    for P in feet:
        (fx0, fx1), (fy0, fy1), (fzz0, fzz1) = rng(P, 0), rng(P, 1), rng(P, 2)
        fc = (fzz0 + fzz1)/2
        # the link reaching lowest over this foot: its z where it meets the foot
        best = None
        for L in links:
            lx0, lx1 = rng(L, 0); ly0, _ = rng(L, 1); lz0, lz1 = rng(L, 2)
            if lx1 < fx0 - 1 or lx0 > fx1 + 1 or lz1 < fzz0 - 1 or lz0 > fzz1 + 1: continue
            if best is None or ly0 < best[0]: best = (ly0, (lz0 + lz1)/2)
        side = 1 if fc > bz else -1
        offs.append(((best[1] - fc) * side if best else None, fzz1 - fzz0, best[1] if best else None, fc))
    # outer extent of legs (links) from body centre
    lz = max(max(abs(p[2] - bz) for p in L) for L in links)
    rows[name] = (bodyW, stance, offs, lz)
    print(f"{name:32s} body {bodyW:5.1f} cm  stance {stance:5.1f}  links reach {lz:5.1f} from centre  leg-on-foot (cm outward of foot centre): {[round(o[0],1) if o[0] is not None else None for o in offs]}")
