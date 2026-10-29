import statistics as st, os
exec(open("/home/claude/work/tips_an.py").read().split("def row")[0])
names = ["Jansen", "Klann", "Spears 4-bar", "Chebyshev", "Chebyshev-Spears", "Hoecken 4-bar", "Hoecken slider", "Hoecken-Spears slider",
         "Hoecken-Spears 4-bar", "Hoecken-Spears long-stance", "Spears lift 44", "Spears lift 53", "Chebyshev diag", "Chebyshev-Spears diag",
         "Hoecken 4-bar diag", "Hoecken-Spears 4-bar diag", "Hoecken-Spears long-stance diag", "Spears lift 44 diag", "Spears lift 53 diag"]
def m(d, n, t):
    v = [sp(f"/home/claude/work/{d}/{n.replace(' ', '_')}_{t}_s{s}.txt") for s in (1, 2, 3)]; v = [x[0] for x in v if x]
    return (st.mean(v), v) if len(v) == 3 else (None, v)
print("| Walker | Bracing | Logs 7 flat | Logs 7 toes | Steps 7 flat | Steps 7 toes | Change, mean of the two |")
print("|---|---|---|---|---|---|---|")
for n in names:
    b = "own" if n in ("Jansen", "Klann", "Spears 4-bar") else ("outside, held" if n.endswith("diag") else "guides")
    lf, lt, sf, stt = m("ft2", n, "logs7")[0], m("toes", n, "logs7")[0], m("ft2", n, "steps7")[0], m("toes", n, "steps7")[0]
    if None in (lf, lt, sf, stt): print(f"| {n} | {b} | (not done) |"); continue
    print(f"| {n} | {b} | {lf:.2f} | {lt:.2f} | {sf:.2f} | {stt:.2f} | {((lt - lf) + (stt - sf)) / 2:+.2f} |")
