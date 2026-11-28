"""letters.py -- the alphabet as closed pen paths, for linkage synthesis.

Each capital is a few strokes (polylines and arcs, height 1). A linkage's
pen never lifts, so each letter becomes ONE closed walk over its strokes:
the strokes form a graph, the odd-degree points are paired by their
shortest connections, those are drawn twice (the pen goes back over them),
and an Euler circuit gives the walk (the "Chinese postman" tour). The walk
is then timed: the pen slows at corners (a linkage cannot turn a sharp
corner fast), and it is sampled at N equal steps of time.

  python3 letters.py A [N]   -> N lines "t x y" (t from 0 to 2 pi), as the
                                synthesizer's targets file wants
"""
import math, sys, heapq, itertools
import numpy as np

def arc(cx, cy, rx, ry, a0, a1, n=24):
    return [(cx + rx * math.cos(math.radians(a)), cy + ry * math.sin(math.radians(a)))
            for a in np.linspace(a0, a1, n)]

def ell(cx, cy, rx, ry, extra=(), n=48):
    """a closed ellipse, as a polyline through the angles given in extra too"""
    angs = sorted(set([360.0 * i / n for i in range(n)] + [a % 360 for a in extra]))
    pts = [(cx + rx * math.cos(math.radians(a)), cy + ry * math.sin(math.radians(a))) for a in angs]
    return pts + [pts[0]]

def ept(cx, cy, rx, ry, a):
    return (cx + rx * math.cos(math.radians(a)), cy + ry * math.sin(math.radians(a)))

QA = -50
LETTERS = {
 "A": [[(0, 0), (.1225, .35), (.35, 1)], [(.35, 1), (.5775, .35), (.7, 0)], [(.1225, .35), (.5775, .35)]],
 "B": [[(0, 0), (0, .5), (0, 1)], [(0, 1), (.35, 1)] + arc(.35, .75, .25, .25, 90, -90)[1:] + [(0, .5)],
       [(0, .5), (.4, .5)] + arc(.4, .25, .25, .25, 90, -90)[1:] + [(0, 0)]],
 "C": [arc(.5, .5, .5, .5, 45, 315, 40)],
 "D": [[(0, 0), (0, 1)], [(0, 1), (.25, 1)] + arc(.25, .5, .5, .5, 90, -90, 32)[1:] + [(0, 0)]],
 "E": [[(0, 0), (0, .5), (0, 1)], [(0, 1), (.6, 1)], [(0, .5), (.45, .5)], [(0, 0), (.6, 0)]],
 "F": [[(0, 0), (0, .5), (0, 1)], [(0, 1), (.6, 1)], [(0, .5), (.45, .5)]],
 "G": [arc(.5, .5, .5, .5, 45, 360, 44), [(1.0, .5), (.55, .5)]],
 "H": [[(0, 0), (0, .5), (0, 1)], [(.7, 0), (.7, .5), (.7, 1)], [(0, .5), (.7, .5)]],
 "I": [[(0, 1), (.2, 1), (.4, 1)], [(.2, 1), (.2, 0)], [(0, 0), (.2, 0), (.4, 0)]],
 "J": [[(.6, 1), (.6, .3)] + arc(.3, .3, .3, .3, 0, -180, 24)[1:]],
 "K": [[(0, 0), (0, .4), (0, 1)], [(.6, 1), (.15, .55), (0, .4)], [(.15, .55), (.6, 0)]],
 "L": [[(0, 1), (0, 0), (.6, 0)]],
 "M": [[(0, 0), (0, 1), (.4, .3), (.8, 1), (.8, 0)]],
 "N": [[(0, 0), (0, 1), (.7, 0), (.7, 1)]],
 "O": [ell(.4, .5, .4, .5)],
 "P": [[(0, 0), (0, .5), (0, 1)], [(0, 1), (.35, 1)] + arc(.35, .75, .25, .25, 90, -90)[1:] + [(0, .5)]],
 "Q": [ell(.4, .5, .4, .5, extra=[QA]), [(.5, .3), ept(.4, .5, .4, .5, QA), (.85, -.1)]],
 "R": [[(0, 0), (0, .5), (0, 1)], [(0, 1), (.35, 1)] + arc(.35, .75, .25, .25, 90, -90)[1:] + [(.2, .5), (0, .5)],
       [(.2, .5), (.6, 0)]],
 "S": [arc(.32, .75, .28, .25, 20, 270, 24) + arc(.32, .25, .28, .25, 90, -160, 24)[1:]],
 "T": [[(0, 1), (.35, 1), (.7, 1)], [(.35, 1), (.35, 0)]],
 "U": [[(0, 1), (0, .3)] + arc(.3, .3, .3, .3, 180, 360, 24)[1:] + [(.6, 1)]],
 "V": [[(0, 1), (.35, 0), (.7, 1)]],
 "W": [[(0, 1), (.2, 0), (.45, .7), (.7, 0), (.9, 1)]],
 "X": [[(0, 0), (.35, .5), (.7, 1)], [(0, 1), (.35, .5), (.7, 0)]],
 "Y": [[(0, 1), (.35, .5), (.7, 1)], [(.35, .5), (.35, 0)]],
 "Z": [[(0, 1), (.7, 1), (0, 0), (.7, 0)]],
}

def key(p): return (round(p[0], 4), round(p[1], 4))

def walk(strokes):
    """the closed pen walk over the strokes, as a list of points"""
    adj = {}                       # node -> list of (node, length)
    edges = []
    for s in strokes:
        for a, b in zip(s, s[1:]):
            ka, kb = key(a), key(b)
            if ka == kb: continue
            L = math.dist(ka, kb)
            edges.append((ka, kb)); adj.setdefault(ka, []).append((kb, L)); adj.setdefault(kb, []).append((ka, L))
    def dijkstra(src):
        d = {src: 0.0}; prev = {}; q = [(0.0, src)]
        while q:
            du, u = heapq.heappop(q)
            if du > d[u]: continue
            for w, L in adj[u]:
                if du + L < d.get(w, 1e18): d[w] = du + L; prev[w] = u; heapq.heappush(q, (du + L, w))
        return d, prev
    odd = [n for n in adj if len(adj[n]) % 2]
    sp = {n: dijkstra(n) for n in odd}
    def pairings(ns):
        if not ns: yield []; return
        a = ns[0]
        for i in range(1, len(ns)):
            for rest in pairings(ns[1:i] + ns[i + 1:]): yield [(a, ns[i])] + rest
    best = min(pairings(odd), key=lambda P: sum(sp[a][0][b] for a, b in P)) if odd else []
    multi = list(edges)
    for a, b in best:                 # the pen goes back over the shortest way from a to b
        prev = sp[a][1]; n = b
        while n != a: multi.append((prev[n], n)); n = prev[n]
    g = {}
    for i, (a, b) in enumerate(multi): g.setdefault(a, []).append((b, i)); g.setdefault(b, []).append((a, i))
    used = set(); start = min(g, key=lambda n: (n[0] + n[1], n[0]))   # lower left
    stack, circ = [start], []
    while stack:
        u = stack[-1]
        while g[u] and g[u][-1][1] in used: g[u].pop()
        if g[u]:
            w, i = g[u].pop(); used.add(i); stack.append(w)
        else: circ.append(stack.pop())
    return circ[::-1]

def timed(path, n, slow=0.06, k=6.0):
    """n points at equal steps of time; the pen slows near corners: the time
    spent per unit length is 1 + k * (the turn's angle / pi) within slow
    of a corner"""
    P = np.array(path, float)
    seg = np.hypot(*np.diff(P, axis=0).T); s = np.r_[0, np.cumsum(seg)]
    corners = []
    for i in range(1, len(P) - 1):
        u, w = P[i] - P[i - 1], P[i + 1] - P[i]
        if np.hypot(*u) < 1e-9 or np.hypot(*w) < 1e-9: continue
        a = math.acos(max(-1, min(1, np.dot(u, w) / np.hypot(*u) / np.hypot(*w))))
        if a > math.radians(25): corners.append((s[i], a))
    u, w = P[1] - P[0], P[-1] - P[-2]           # (the closing corner)
    a = math.acos(max(-1, min(1, np.dot(w, u) / np.hypot(*u) / np.hypot(*w))))
    if a > math.radians(25): corners += [(0.0, a), (s[-1], a)]
    fine = np.linspace(0, s[-1], 20000)
    dens = np.ones_like(fine)
    for sc, a in corners: dens += k * (a / math.pi) * np.exp(-0.5 * ((fine - sc) / slow) ** 2)
    T = np.r_[0, np.cumsum((dens[1:] + dens[:-1]) / 2 * np.diff(fine))]
    tq = np.linspace(0, T[-1], n, endpoint=False)
    sq = np.interp(tq, T, fine)
    return np.c_[np.interp(sq, s, P[:, 0]), np.interp(sq, s, P[:, 1])]

if __name__ == "__main__":
    L = sys.argv[1]; n = int(sys.argv[2]) if len(sys.argv) > 2 else 120
    pts = timed(walk(LETTERS[L]), n)
    print(n)
    for t, (x, y) in zip(np.linspace(0, 2 * math.pi, n, endpoint=False), pts):
        print(repr(float(t)), repr(float(x)), repr(float(y)))
