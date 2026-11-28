"""make-alphabet.py -- alphabet.lua, the linkages that write's letters,
from synthesis/alphabet.json (synthesis/final2.py's picks).

For every letter and slider position: its pens, and for each pen its
linkage posed at the start of the turn, in the letter's units (the letter 1
tall, y up): the bodies (each a list of its pin points: the crank O2-A, the
coupler A-B-P0, the rocker B-O4, then per dyad its link5 P-C-P' and link6
C-O), the hinges between them (or to the board, "ground"), the pen's body
and point, the crank's pivot and pin, k (the crank's turns a cycle, +1 or
-1), and the stroke it draws (the pen's own path, out and back), with how
far the pen strays from it as computed (h). Also each letter's reach over
the whole turn, so the exhibit can centre it.

  python3 make-alphabet.py          (numpy; synthesis/linkage_synthesis.py, scipy)
"""
import json, math, os, sys
import numpy as np
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "synthesis"))
import linkage_synthesis as ls
import letters as LT

A = json.load(open(os.path.join(HERE, "synthesis", "alphabet.json")))
LEVELS = ["sloppy", "ok", "very good"]

def f(x): return "%.5f" % x
def pt(q): return "{" + f(q[0]) + ", " + f(q[1]) + "}"

out = ["-- alphabet.lua: made by make-alphabet.py from synthesis/alphabet.json; do not edit",
       "-- (letters' units: the letter 1 tall, y up)", "return {"]
for c in sorted(A):
    out.append("  %s = {" % c)
    for li, lev in enumerate(LEVELS):
        pens = A[c][lev]
        if not pens: continue
        xs, ys = [], []
        P = []
        for z in pens:
            p, D = np.array(z["params"]), z["D"]
            mech = ls.unpack(p, D)
            T = dict(R=np.array(z["tf"]["R"]), scale=z["tf"]["scale"], mu_p=np.array(z["tf"]["mu_p"]), mu_t=np.array(z["tf"]["mu_t"]))
            def W(q): return ls.apply_transform(np.array(q, float), T)
            chain, P0, dy, Pf = ls._mechanism_joint_chain(mech, 0.0)
            O2, A_, B, O4 = chain
            bodies = [("crank", [O2, A_]), ("coupler", [A_, B, P0]), ("rocker", [B, O4])]
            hinges = [("ground", O2, "crank"), ("crank", A_, "coupler"), ("coupler", B, "rocker"), ("rocker", O4, "ground")]
            prev = "coupler"
            for i, d in enumerate(dy):
                bodies += [("l5_%d" % i, [d["prevP"], d["C"], d["P_out"]]), ("l6_%d" % i, [d["C"], d["O"]])]
                hinges += [(prev, d["prevP"], "l5_%d" % i), ("l5_%d" % i, d["C"], "l6_%d" % i), ("l6_%d" % i, d["O"], "ground")]
                prev = "l5_%d" % i
            bb = ls._mechanism_bbox_over_time(mech, np.linspace(0, 2 * math.pi, 72, endpoint=False), T)
            xs += [bb[0], bb[1]]; ys += [bb[2], bb[3]]
            stroke = np.array(LT.walk(z["strokes"]), float)
            s = ["    {"]
            s.append("      k = %d, D = %d, h = %s," % (int(mech.k), D, f(z["h"])))
            s.append("      bodies = { " + ", ".join('{ name = "%s", pts = { %s } }' % (n, ", ".join(pt(W(q)) for q in pts)) for n, pts in bodies) + " },")
            s.append("      hinges = { " + ", ".join('{ a = "%s", p = %s, b = "%s" }' % (a, pt(W(q)), b) for a, q, b in hinges) + " },")
            s.append('      pen = { body = "%s", p = %s }, crankO = %s, crankA = %s,' % (prev, pt(W(Pf)), pt(W(O2)), pt(W(A_))))
            s.append("      stroke = { " + ", ".join(pt(q) for q in stroke) + " },")
            s.append("    },")
            P.append("\n".join(s))
        bars = sum(4 + 2 * z["D"] for z in pens)
        worst = max(z["h"] for z in pens)
        out.append('   [%d] = { bars = %d, worst = %s, box = { %s, %s, %s, %s }, pens = {' % (li + 1, bars, f(worst), f(min(xs)), f(max(xs)), f(min(ys)), f(max(ys))))
        out += P
        out.append("   } },")
    out.append("  },")
out.append("}")
open(os.path.join(HERE, "alphabet.lua"), "w").write("\n".join(out) + "\n")
print("wrote alphabet.lua:", len(A), "letters")
