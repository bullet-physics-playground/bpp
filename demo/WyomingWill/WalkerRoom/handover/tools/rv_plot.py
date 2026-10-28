import collections, matplotlib; matplotlib.use("Agg"); import matplotlib.pyplot as plt
fig, axs = plt.subplots(1, 3, figsize=(15, 4.2))
for ax, (nm, lab, ft) in zip(axs, [("Jansen", "Jansen (report mono 0.986)", 1), ("Klann", "Klann (0.860)", 4), ("Spears4", "Spears 4-bar (0.724)", 1)]):
    R = [l.strip().split("|") for l in open(f"rv/{nm}.txt") if f"|foot {ft}|" in l]
    A = [float(p[3].split()[1]) for p in R]; X = [float(p[5].split()[1]) for p in R]; G = [int(p[7].split()[1]) for p in R]; S = [float(p[4].split()[1]) for p in R]
    dd = sorted((b - a + 180) % 360 - 180 for a, b in zip(A, A[1:])); sg = 1 if dd[len(dd)//2] > 0 else -1
    ss = sorted(S); sgs = 1 if ss[len(ss)//2] > 0 else -1
    th = [(a * sg) % 360 for a in A]
    xs = [x - sum(X)/len(X) for x in X]
    ax.scatter([t for t, g in zip(th, G) if not g], [x for x, g in zip(xs, G) if not g], s=3, c="#a8c7fa", label="foot in the air")
    ax.scatter([t for t, g in zip(th, G) if g], [x for x, g in zip(xs, G) if g], s=3, c="#202124", label="foot on the ground")
    rv = [(t, x) for t, x, s in zip(th, xs, S) if s * sgs < 0]
    if rv: ax.scatter(*zip(*rv), s=60, facecolors="none", edgecolors="#d93025", lw=2, label="its crank turning backwards")
    ax.set_title(lab, loc="left", fontsize=11); ax.set_xlabel("crank angle (deg, in its turning direction)"); ax.set_xlim(0, 360)
    ax.grid(alpha=0.3)
axs[0].set_ylabel("foot x relative to the body (cm)")
axs[2].legend(fontsize=8, loc="best")
fig.suptitle("One foot per walker, 18 s on flat. Backward crank moments (red) fall where the planted foot's path runs forward.", fontsize=11)
fig.tight_layout(); fig.savefig("/home/claude/out/crank-reversal-vs-foot-path.png", dpi=95)
