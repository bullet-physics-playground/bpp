"""python3 tally.py LOG... -> per log: rests on the flat table, upright (< 15 deg), and where the rest stopped."""
import re, sys, collections, statistics as st
for f in sys.argv[1:]:
    R = re.findall(r'at rest after\s+([\d.]+) s, ([\d.]+) deg off upright(?:\s+pos \S+ \S+ on (\w+))?', open(f, errors='ignore').read())
    T = [float(g) for t, g, w in R if w != 'RAMP']; ramp = sum(w == 'RAMP' for _, _, w in R)
    if not T: print(f, 'no rests yet'); continue
    up = sum(t < 15 for t in T); stops = collections.Counter(5 * round(t / 5) for t in T if t >= 15)
    print(f'{f}: {up}/{len(T)} upright ({100 * up / len(T):.0f}%), stopped at {dict(sorted(stops.items()))} (deg),'
          f' median time {st.median(float(t) for t, g, w in R):.1f} s' + (f', +{ramp} on the edge ramp' if ramp else ''))
