# analyse.py: what monitor.lua's logs say (run it where they are): the red
# bead's trips (top above 14 cm, bottom below 7) and where it goes down and
# up; the big bead's height by 30 s; its turn's rate, left and right of the
# middle; the layers' height change in the middle and by the walls
import csv, glob, math, statistics as st, os, sys
if len(sys.argv) > 1: os.chdir(sys.argv[1])
def load(f): return [{k: float(v) for k, v in r.items()} for r in csv.DictReader(open(f))]
for box in ['rough', 'smooth']:
    print('=====', box)
    for s in [7, 8, 1, 2]:
        P = load(f'{box}-s{s}-path.csv')
        P = [r for r in P if r['t'] > 0]
        # tracer: zones by height (bed 20 cm at rest): bottom < 7, top > 14
        zone, events, last = None, [], None
        for r in P:
            z = 'B' if r['ty'] < 7 else ('T' if r['ty'] > 14 else None)
            if z and z != zone:
                events.append((r['t'], z, r['tx'])); zone = z
        downs = [e for e in events if e[1] == 'B']; ups = [e for e in events if e[1] == 'T']
        # loops: T -> B -> T
        loops = []
        seq = [e for e in events]
        for i in range(len(seq) - 2):
            if seq[i][1] == 'T' and seq[i + 1][1] == 'B' and seq[i + 2][1] == 'T':
                loops.append(seq[i + 2][0] - seq[i][0])
        # where it goes down and up: |x| while moving (1 s windows)
        dn, upx = [], []
        for i in range(10, len(P), 10):
            dy = P[i]['ty'] - P[i - 10]['ty']; x = abs(P[i]['tx'])
            if dy < -0.5: dn.append(x)
            elif dy > 0.5: upx.append(x)
        topfrac = sum(1 for r in P if r['ty'] > 14) / len(P)
        # big bead height by window
        def win(a, b): return [r['by'] for r in P if a < r['t'] <= b]
        hb = [st.mean(win(a, a + 30)) for a in range(0, 180, 30)]
        # band: angular velocity, 1 s differences
        om = [((P[i]['angle'] - P[i - 10]['angle']) / (P[i]['t'] - P[i - 10]['t']), P[i]['bx'], P[i]['by']) for i in range(10, len(P), 10)]
        late = [o for o in om if o[2] > 0]
        left = [o[0] for o in om if o[1] < -1]; right = [o[0] for o in om if o[1] > 1]
        turns = (P[-1]['angle'] - P[0]['angle']) / (2 * math.pi)
        print(f's{s}: tracer: {len(downs)} times to the bottom, {len(ups)} to the top; loops (top-bottom-top) {len(loops)}: {[round(l) for l in loops]} s; '
              f'|x| going down {st.mean(dn) if dn else -1:.1f}, going up {st.mean(upx) if upx else -1:.1f} cm; top fraction {topfrac:.2f}')
        print(f'     big bead mean height by 30 s: {[round(h, 1) for h in hb]}')
        print(f'     band: net {turns:+.1f} turns in 180 s; spin rad/s: mean {st.mean(o[0] for o in om):+.2f}, |mean| {st.mean(abs(o[0]) for o in om):.2f}; '
              f'left of middle {st.mean(left) if left else 0:+.2f} (n {len(left)}), right {st.mean(right) if right else 0:+.2f} (n {len(right)})')
    # layers: the mean height change, middle minus walls, over 0-30 s
    for s in [7, 8, 1, 2]:
        Lr = load(f'{box}-s{s}-layers.csv')
        out = []
        for L in range(1, 6):
            rows = [r for r in Lr if int(r['layer']) == L]
            r0 = rows[0]
            def at(T): return min(rows, key=lambda r: abs(r['t'] - T))
            ch = []
            for T in (10, 20, 30):
                r = at(T)
                ch.append(((r['mid_y'] - r0['mid_y']) if r['mid_n'] and r0['mid_n'] else float('nan'), (r['wall_y'] - r0['wall_y']) if r['wall_n'] and r0['wall_n'] else float('nan')))
            out.append(f'L{L}: ' + ' '.join(f'{a:+.1f}/{b:+.1f}' for a, b in ch))
        print(f'  layers s{s} (mid/wall height change at 10, 20, 30 s): ' + '; '.join(out))
