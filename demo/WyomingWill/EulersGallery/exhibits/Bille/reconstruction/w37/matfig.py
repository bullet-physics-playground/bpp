"""Material comparison figure: best refitted margin per stock weight (runs/materials.json)."""
import json, numpy as np
import matplotlib; matplotlib.use('Agg')
import matplotlib.pyplot as plt
from materials import CAT

LABEL = {
 'W-cyl-3/8x.44': 'tungsten cylinder 3/8" x 0.44" (0.5 oz)', 'W-ball-12': 'tungsten-alloy ball 12 mm', 'W-ball-10': 'tungsten-alloy ball 10 mm',
 'W-cube-1/4': 'tungsten cube 1/4"', 'Wputty-cyl-10x12': 'tungsten putty, 9.9 g plug', 'Pb-cyl-3/8x.6': 'lead rod 3/8" x 0.6"',
 'Pb-ball-.440': 'lead round ball .440"', 'Pb-ball-.535': 'lead round ball .535"', 'Pb-ball-.570': 'lead round ball .570"',
 'St-dowel-10x16': 'steel dowel pin 10 x 16 mm', 'St-dowel-10x20': 'steel dowel pin 10 x 20 mm', 'St-dowel-10x24': 'steel dowel pin 10 x 24 mm',
 'St-dowel-8x24': 'steel dowel pin 8 x 24 mm', 'St-ball-7/16': 'steel ball 7/16"', 'St-ball-1/2': 'steel ball 1/2"', 'St-ball-9/16': 'steel ball 9/16"',
 'St-ball-5/8': 'steel ball 5/8"', 'St-ball-3/4': 'steel ball 3/4"', 'Bi-cyl-10x12': 'bismuth cylinder 10 x 12 mm'}
COL = {'W': '#3b5b7a', 'Wp': '#7d9bb8', 'Pb': '#8a6d3b', 'St': '#9aa3ad', 'Bi': '#b07aa1'}
def fam(w): return 'Wp' if w.startswith('Wputty') else w.split('-')[0]

def main(out="../../print/w37/materials.png"):
    M = json.load(open("runs/materials.json"))
    best = {}
    for d in M:
        if d['weight'] not in best or d['margin'] > best[d['weight']]['margin']: best[d['weight']] = d
    items = sorted(best.values(), key=lambda d: d['margin'])
    fig, ax = plt.subplots(figsize=(8.4, 0.32 * len(items) + 1.2))
    y = np.arange(len(items))
    for i, d in enumerate(items):
        c = COL[fam(d['weight'])]
        ax.barh(i, d['margin'], color=c, height=0.62)
        W = CAT[d['weight']]
        txt = f"{d['margin']:+.1f} mm   ({d['H']} mm tall, {W.m:.1f} g each)"
        x = d['margin']
        ax.text(max(x, 0) + 0.25, i, txt, va='center', ha='left', fontsize=7.5, color='#1f2328')
    ax.set_yticks(y); ax.set_yticklabels([LABEL.get(d['weight'], d['weight']) for d in items], fontsize=8)
    ax.axvline(0, color='#1f2328', lw=0.8)
    lo = min(d['margin'] for d in items); hi = max(d['margin'] for d in items)
    ax.set_xlim(lo - 0.8, hi + 11)
    ax.set_xlabel("smallest margin after refitting the shape (mm); below 0 = not monostable", fontsize=8.5)
    for s in ('top', 'right', 'left'): ax.spines[s].set_visible(False)
    ax.tick_params(axis='y', length=0); ax.tick_params(axis='x', labelsize=8)
    ax.grid(axis='x', color='#d0d7de', lw=0.5); ax.set_axisbelow(True)
    fig.tight_layout(); fig.savefig(out, dpi=170); plt.close(fig)

if __name__ == "__main__":
    import os; os.makedirs("../../print/w37", exist_ok=True); main()
