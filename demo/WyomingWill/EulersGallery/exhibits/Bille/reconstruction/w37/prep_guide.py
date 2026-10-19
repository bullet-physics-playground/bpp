"""Small JSON inputs for the guide: coupon pause heights, simulation summary text.
Writes the coupons to ../../print/w37/ and final/coupons.json, final/sim-tally.json."""
import json, subprocess, re, glob
from coupon import main as coupon
from materials import CAT
S = json.load(open("final/w37-W-summary.json")); A = json.load(open("final/w37-St-summary.json"))
PR = "../../print/w37"
c = {"W": coupon(S['weight'], f"{PR}/coupon-W.stl"), "St": coupon(A['weight'], f"{PR}/coupon-St.stl")}
json.dump(c, open("final/coupons.json", "w"))
TW = json.load(open("final/sim-tally-W.json")); TA = json.load(open("final/sim-tally-St.json"))
def med(T, pre):
    t = [v['median_time'] for k, v in T['files'].items() if k.startswith(pre) and v['median_time']]
    return min(t), max(t)
def ups(d):
    n = u = 0
    for f in glob.glob(f"sim-{d}/logs/setdown*.txt"):
        for line in open(f):
            m = re.search(r"faces it lay on: (.*?) --", line)
            if not m: continue
            idx = [0 if s.strip("()") == "base" else int(s.strip("()")[1:]) for s in m.group(1).split(" -> ")]
            n += 1; u += max(idx[1:] + [0]) >= 2 and any(b > a for a, b in zip(idx, idx[1:]))
    return u, n
uw = ups("W")
text = [
 f"<b>Recommended build:</b> {TW['drops'][1]} of {TW['drops'][0]} random drops ended on the base (3 runs × 6 bodies, each re-dropped 1 s after coming to rest), "
 f"and {TW['setdowns'][1]} of {TW['setdowns'][0]} set-downs ended on the base: each of the 36 wrong faces once (6 per band, S1…S6). Time to rest: median {med(TW,'drop')[0]:.1f}–{med(TW,'drop')[1]:.1f} s per drop run.",
 f"<b>Steel-dowel build:</b> {TA['drops'][1]} of {TA['drops'][0]} drops and {TA['setdowns'][1]} of {TA['setdowns'][0]} set-downs ended on the base.",
 "<b>How it moves.</b> From a high band it tips band by band to the base, then <i>rocks back up</i> through the low bands (in the simulation, at most up to S5 after "
 "a set-down on S6) with decreasing swings, and settles after 5–10 s. It does not stop on any band on the way. That is what a low centre of mass and nearly flat "
 "bottom bands give: a faceted Weeble. Real PLA damps the impacts more than the simulation's restitution, so expect a quicker settle.",
 "Run at the real size (PP_SCALE = 1), 1/1200 s steps, in a copy of the gallery's Bille Drop harness (exhibits/Bille/reconstruction/w37/sim/w37-drop.lua, "
 "made via reconstruction/pla/sim/pla-drop.lua) with only the body list and its label changed. Contact, losses and detection are unchanged, and nothing was tuned."]
json.dump(dict(text=text), open("final/sim-tally.json", "w"), indent=1)
print(c)
