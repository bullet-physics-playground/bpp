"""Count drop-log BODIES, not rest events (families chat, 20 Nov 2026).
  python3 recount.py LOG ...
BPP prints "at rest" again each time a slowly creeping body settles anew, and printing/bpp-drops/tally.py
counts those lines. Here each body (colour + #n) is decided by its last "at rest" line, upright if < 10 deg."""
import re, sys, os
pat = re.compile(r'^\s+(\S+(?: #\d+)?)\s+at rest after\s+([\d.]+) s, ([\d.]+) deg off upright')
for f in sys.argv[1:]:
    last, events, up_ev = {}, 0, 0
    for l in open(f, errors='ignore'):
        m = pat.match(l)
        if m:
            last[m.group(1)] = float(m.group(3)); events += 1; up_ev += float(m.group(3)) < 10
    up = sum(t < 10 for t in last.values()); n = len(last)
    stops = sorted(round(t) for t in last.values() if t >= 10)
    print(f'{os.path.basename(f):40s} bodies {up}/{n} ({100 * up / max(n, 1):.0f}%)   events {up_ev}/{events}   stops {stops}')
