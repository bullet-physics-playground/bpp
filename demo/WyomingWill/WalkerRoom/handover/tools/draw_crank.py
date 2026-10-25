#!/usr/bin/env python3
# Crank turning, held pendants (PENDANT_HOLD) against free: (top) the held-body sweeps (body pinned 200 cm up, crank
# driven at 0.6 rad/s for one turn's time), (bottom) walking 20 s on flat and waves 4 (Earth standard, outside braces).
import sys, math, re
sys.path.insert(0, "/home/claude/work"); import topz
import matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt
B = [("Chebyshev-Spears_diag", "CS", "Chebyshev-Spears diag"), ("Hoecken-Spears_4-bar_diag", "HS4", "Hoecken-Spears 4-bar diag"),
     ("Hoecken-Spears_long-stance_diag", "HSLS", "Hoecken-Spears long-stance diag")]
ADV = {"CS": 18.46, "HS4": 19.57, "HSLS": 17.02}     # (the advances the room used in these runs)
HELD, FREE = "#b22222", "#4a55b5"
def crank_angle(path):
    name, L, S, bb, hz = topz.load(path)
    G = [int(l.split()[1]) for l in open(path) if l.startswith("GROUND") and "Hinge" in l]
    n = min(len(S[i]) for i in L); best = None
    for i in G:
        if L[i]["kind"] != "makeLink": continue
        tot, prev, ser = 0, None, [0.0]
        for k in range(n):
            c = list(S[i][k].exterior.coords)
            e = max(((c[q], c[q + 1]) for q in range(len(c) - 1)), key=lambda e: math.dist(*e))
            a = math.degrees(math.atan2(e[1][1] - e[0][1], e[1][0] - e[0][0]))
            if prev is not None: tot += (a - prev + 90) % 180 - 90; ser.append(abs(tot))
            prev = a
        if abs(tot) < 420 and (best is None or ser[-1] > best[-1]): best = ser
    return best
fig, axs = plt.subplots(2, 3, figsize=(13, 7.5))
for c, (f, t, nm) in enumerate(B):
    ax = axs[0][c]
    for path, col, lab in ((f"sweepT/{f}.txt", HELD, "pendants held"), (f"sweepT/nohold_{t}.txt", FREE, "pendants free")):
        s = crank_angle(path); tt = [k * 3 / 60 for k in range(len(s))]
        ax.plot(tt, s, color=col, lw=1.6, label=f"{lab}: {s[-1]:.0f}°")
    T = 2 * math.pi / 0.6
    ax.plot([0, T], [0, 360], color="#888888", ls="--", lw=1, label="driven speed: 360°")
    ax.set_title(f"{nm}\nsweep: body pinned in the air", fontsize=9); ax.set_xlabel("s", fontsize=8); ax.set_ylabel("crank turned (°)", fontsize=8)
    ax.legend(fontsize=7, loc="upper left"); ax.tick_params(labelsize=7)
    ax = axs[1][c]
    want = 9 / ADV[t]
    for amp, ls in (("0", "-"), ("4", ":")):
        for v, col in (("hold", HELD), ("free", FREE)):
            L = open(f"crankw/{t}_a{amp}_{v}.txt").read().splitlines()
            tr = [float(re.search(r"turns ([0-9.]+)", l).group(1)) for l in L if l.startswith("STALL")]
            sp = [l for l in L if l.startswith("TRACK")][0].split("|")[5]
            ax.plot(range(1, len(tr) + 1), tr, color=col, ls=ls, lw=1.4,
                    label=f"{'flat' if amp == '0' else 'waves 4'}, {'held' if v == 'hold' else 'free'}: mean {sum(tr) / len(tr):.2f}, {sp}")
    ax.axhline(want, color="#888888", ls="--", lw=1, label=f"driven speed {want:.2f}")
    ax.set_ylim(0, want * 1.4); ax.set_title("walking, trot, forward, 20 s", fontsize=9)
    ax.set_xlabel("s", fontsize=8); ax.set_ylabel("crank turns that second", fontsize=8); ax.legend(fontsize=6.5, loc="lower right"); ax.tick_params(labelsize=7)
fig.suptitle("Crank turning with the pendants held (red) and free (blue), outside braces. Top: the advance sweeps. Bottom: walking.", fontsize=10)
fig.tight_layout(rect=(0, 0, 1, 0.95)); fig.savefig("/home/claude/work/crank_hold.png", dpi=105); print("ok")
