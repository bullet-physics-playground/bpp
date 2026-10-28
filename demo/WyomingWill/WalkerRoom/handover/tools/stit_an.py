import re,glob,collections,statistics as st
R=collections.defaultdict(list)
for f in glob.glob("/home/claude/work/st/*.txt"):
    b=f.split("/")[-1][:-4]
    m=re.match(r"(Chebyshev-Spears|Hoecken-Spears_slider)_(?:(it\d+)_)?h5_g([\d.]+)$",b)
    if not m: continue
    t=open(f).read(); s=re.search(r"all four on top ([-\d.]+)\|pushed back ([\d.]+)",t)
    if not s: continue
    R[(m.group(1),m.group(2) or "it40")].append((float(m.group(3)),s.group(1),float(s.group(2))))
for k in sorted(R):
    rows=sorted(R[k]); ok=[float(r[1]) for r in rows if r[1]!="-"]
    print(k, f"{len(ok)}/{len(rows)} got up", f"median time {st.median(ok):.1f}" if ok else "", f"pushback median {st.median(r[2] for r in rows):.1f}", " ".join(f"g{r[0]}:{r[1]}" for r in rows))
