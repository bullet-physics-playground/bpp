# From sweepP/: in a held-body crank turn, how far each pendant (the link hinged to a foot) turns against the body,
# whether each side's two pendants move as one (they must, to be welded to one plate), and the foot path's stride,
# with and without PENDANT_HOLD (if the hold fought the linkage, the path would change or the crank would stall).
import sys, math, collections
sys.path.insert(0, "/home/claude/work"); import topz
def ang(poly):
    c = list(poly.exterior.coords)
    e = max(((c[q], c[q + 1]) for q in range(len(c) - 1)), key=lambda e: math.dist(*e))
    return math.degrees(math.atan2(e[1][1] - e[0][1], e[1][0] - e[0][0])) % 180
def look(path):
    name, L, S, bb, hz = topz.load(path)
    J = [l.split() for l in open(path) if l.startswith("JOIN")]
    n = min(len(S[i]) for i in L)
    feet = [i for i in L if L[i]["kind"] == "buildFoot"]
    pend = sorted({(int(j[2]) if int(j[1]) in feet else int(j[1])) for j in J if j[3] == "btHingeConstraint" and (int(j[1]) in feet) != (int(j[2]) in feet)})
    turn = 0
    for i in pend:
        a0 = ang(S[i][0]); turn = max(turn, max(abs((ang(S[i][k]) - a0 + 90) % 180 - 90) for k in range(n)))
    side = collections.defaultdict(list)
    for i in pend: side[L[i]["z"] > 0].append(i)
    part = 0
    for ps in side.values():
        i, j = ps
        for k in range(n):
            d = lambda q: (S[q][k].centroid.x - S[q][0].centroid.x, S[q][k].centroid.y - S[q][0].centroid.y)
            part = max(part, math.dist(d(i), d(j)))
    xs = [S[feet[0]][k].centroid.x for k in range(n)]
    return name, len(pend), turn, part, max(xs) - min(xs), n
for b in ["Chebyshev", "Chebyshev-Spears", "Hoecken_4-bar", "Hoecken_slider", "Hoecken-Spears_slider", "Hoecken-Spears_4-bar", "Hoecken-Spears_4-bar_duty_85", "Chebyshev-Spears_lift_51", "Chebyshev-Spears_lift_62"]:
    a = look(f"sweepP/{b}.txt"); h = look(f"sweepP/{b}_hold.txt")
    print(f"{a[0]:28s} pendants {a[1]}  turn {a[2]:5.2f} / {h[2]:5.2f} deg  pair apart {a[3]:.3f} / {h[3]:.3f} cm  foot travel {a[4]:6.2f} / {h[4]:6.2f} cm  ({a[5]}/{h[5]} moments)  [as built / held]")
