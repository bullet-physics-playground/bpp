"""The linkages that write's manual figures (Babbage's Hall). Run from the
exhibit's folder: python3 manual/make-figures.py (matplotlib, numpy, scipy).

  fig-anatomy.png    one pen's linkage: the four-bar and its dyads, the pen
  fig-sloppy.png, fig-ok.png, fig-good.png
                     the alphabet at each slider position: every pen in its
                     own colour over the letter
(fig-exhibit.png is a screenshot of the exhibit.)
"""
import json, math, os, sys
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "synthesis"))
import linkage_synthesis as ls
import letters as LT
A = json.load(open(os.path.join(HERE, "..", "synthesis", "alphabet.json")))
COL = ["#c0392b", "#2471a3", "#1e8449", "#8e44ad", "#d35400", "#16a085", "#7f8c8d"]

def T(z): return dict(R=np.array(z["tf"]["R"]), scale=z["tf"]["scale"], mu_p=np.array(z["tf"]["mu_p"]), mu_t=np.array(z["tf"]["mu_t"]))

def alphabet(lev, name, tol):
    fig, axs = plt.subplots(3, 9, figsize=(18, 7.6))
    for a, c in zip(axs.flat, sorted(A)):
        W = np.array(LT.walk(LT.LETTERS[c])); a.plot(W[:, 0], W[:, 1], '-', color='0.86', lw=7)
        pens = A[c][lev]; bars = 0
        for i, z in enumerate(pens):
            d = ls.apply_transform(ls.trace_curve(np.array(z["params"]), z["D"], np.linspace(0, 2 * math.pi, 600)), T(z))
            a.plot(d[:, 0], d[:, 1], '-', color=COL[i % 7], lw=1.5); bars += 4 + 2 * z["D"]
        a.set_title(f"{c}: {len(pens)} pen{'s' if len(pens) > 1 else ''}, {bars} bars", fontsize=12)
        a.set_aspect('equal'); a.axis('off'); a.set_xlim(-.15, 1.1); a.set_ylim(-.2, 1.1)
    axs.flat[-1].axis('off')
    fig.suptitle(f"{lev}: every pen within {tol}% of the letter's height", fontsize=15)
    fig.tight_layout(); fig.savefig(os.path.join(HERE, name), dpi=60); plt.close(fig)

def anatomy():
    z = A["C"]["very good"][0]
    p, D = np.array(z["params"]), z["D"]; mech = ls.unpack(p, D); tf = T(z)
    fig, ax = plt.subplots(figsize=(8, 7))
    d = ls.apply_transform(ls.trace_curve(p, D, np.linspace(0, 2 * math.pi, 600)), tf)
    W = np.array(LT.walk(LT.LETTERS["C"])); ax.plot(W[:, 0], W[:, 1], '-', color='0.86', lw=9)
    ax.plot(d[:, 0], d[:, 1], '-', color="#c0392b", lw=1.5)
    chain, P0, dy, Pf = ls._mechanism_joint_chain(mech, 0.9)
    tr = lambda q: ls.apply_transform(np.array(q, float), tf)
    O2, A_, B, O4 = [tr(q) for q in chain]; P0 = tr(P0)
    def bar(a, b, col, lw=5, ls_="-"): ax.plot([a[0], b[0]], [a[1], b[1]], ls_, color=col, lw=lw, solid_capstyle="round")
    bar(O2, A_, "#2471a3"); bar(A_, B, "#1e8449"); bar(B, O4, "#8e44ad"); bar(A_, P0, "#1e8449", 2.5); bar(B, P0, "#1e8449", 2.5)
    prev = P0
    for i, q in enumerate(dy):
        C, Og, Po = tr(q["C"]), tr(q["O"]), tr(q["P_out"])
        bar(prev, C, "#d35400"); bar(C, Og, "#7f8c8d"); bar(prev, Po, "#d35400", 2.5); bar(C, Po, "#d35400", 2.5)
        ax.plot(*Og, "ks", ms=9)
        prev = Po
    for g in (O2, O4): ax.plot(*g, "ks", ms=9)
    ax.plot(*prev, "o", color="#c0392b", ms=9)
    ax.annotate("crank (the motor)", O2, xytext=(15, -20), textcoords="offset points", fontsize=11, color="#2471a3")
    ax.annotate("coupler", (A_ + B) / 2, xytext=(8, 8), textcoords="offset points", fontsize=11, color="#1e8449")
    ax.annotate("rocker", (B + O4) / 2, xytext=(8, 0), textcoords="offset points", fontsize=11, color="#8e44ad")
    ax.annotate("the pen", prev, xytext=(10, 10), textcoords="offset points", fontsize=11, color="#c0392b")
    ax.set_title(f"C, very good: a four-bar and {D} dyads ({4 + 2 * D} bars); squares: fixed pivots", fontsize=12)
    ax.set_aspect('equal'); ax.axis('off')
    fig.tight_layout(); fig.savefig(os.path.join(HERE, "fig-anatomy.png"), dpi=80); plt.close(fig)

anatomy()
alphabet("sloppy", "fig-sloppy.png", 8); alphabet("ok", "fig-ok.png", 4); alphabet("very good", "fig-good.png", 2)
print("wrote fig-anatomy.png, fig-sloppy.png, fig-ok.png, fig-good.png")
