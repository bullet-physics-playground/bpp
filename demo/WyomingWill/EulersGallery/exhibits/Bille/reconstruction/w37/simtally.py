"""Tally the bpp runs (sim/logs): every 'at rest on face X' line is one rest.
usage: python3 simtally.py sim/logs out.json"""
import re, sys, glob, json, os, collections
d = sys.argv[1]
res = {}
for f in sorted(glob.glob(os.path.join(d, "*.txt"))):
    rests = []; setd = []; times = []
    for line in open(f):
        m = re.match(r"\s+(\w+)\s+at rest on face (\S+) after\s+([\d.]+) s; faces it lay on: (.*?) --", line)
        if m: rests.append((m.group(1), m.group(2), m.group(4))); times.append(float(m.group(3)))
        m = re.match(r"\s+(\w+)\s+set down on (\S+); predicted: (.*)", line)
        if m: setd.append((m.group(1), m.group(2), m.group(3).strip()))
    if not rests and not setd: continue
    faces = collections.Counter(r[1] for r in rests)
    res[os.path.basename(f)] = dict(rests=len(rests), on_base=faces.get('base', 0), faces=dict(faces),
                                    set_down_on=sorted(set(s[1] for s in setd)),
                                    median_time=sorted(times)[len(times) // 2] if times else None,
                                    paths=collections.Counter(r[2] for r in rests).most_common(6))
tot = sum(v['rests'] for v in res.values()); base = sum(v['on_base'] for v in res.values())
drops = {k: v for k, v in res.items() if k.startswith('drop')}; sets = {k: v for k, v in res.items() if k.startswith('setdown')}
out = dict(files=res, total=tot, on_base=base,
           drops=(sum(v['rests'] for v in drops.values()), sum(v['on_base'] for v in drops.values())),
           setdowns=(sum(v['rests'] for v in sets.values()), sum(v['on_base'] for v in sets.values())),
           bands_set_down=sorted(set(b for v in sets.values() for b in v['set_down_on'])))
print(json.dumps({k: v for k, v in out.items() if k != 'files'}, indent=1))
for k, v in res.items(): print(f"  {k:28s} {v['on_base']}/{v['rests']} on base; other faces {dict((a,b) for a,b in v['faces'].items() if a!='base')}; median time to rest {v['median_time']}")
if len(sys.argv) > 2: json.dump(out, open(sys.argv[2], "w"), indent=1)
