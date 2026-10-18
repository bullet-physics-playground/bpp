## The Tippe Top

**What it shows** — A ball with a short stem, its centre of mass a little below the ball's centre. Spun on its ball, stem up, it turns itself over within a few seconds and spins on its stem, raising its centre of mass; sliding friction at the table does the work. Three tops: red, spun fast (40 turns/s), turns over and stands on its stem; blue, the same top spun slowly (15 turns/s), only gets as far as lying on ball and stem; green, with its centre of mass almost at the ball's centre, never turns over. All end stem up again as they slow.

**Model**
- Top: one Bullet rigid body, 15 g, hollow ball R = 1.5 cm; I3 = 2/3 m R^2 = 0.0225 kg cm^2 about the stem, I1 = 0.9 I3 across. Centre of mass a = 0.45 cm below the ball's centre (alpha = a/R = 0.3); green top a = 0.06 cm (alpha = 0.04).
- Contact shape: Bullet compound of a true sphere (the ball) and a capsule (the stem, round tip radius 0.6 cm standing 0.6 cm out). Sliding friction 0.2 (Bullet), restitution 0, contact processing threshold 0.001.
- Bullet's gyroscopic term is off; before every physics step the script advances the body-frame angular velocity by Euler's equations with RK4 (as in the rattleback exhibit).
- Script-applied losses: "spin friction", a deceleration 0.5 rad/s^2 of the spin component about the vertical; rolling resistance, a constant moment delta*m*g against the horizontal angular velocity, delta = 30 microns, with the matching linear-velocity change about the contact.
- 4800 physics steps/s (80 per 1/60 s frame), no damping, g = 981 cm/s^2. Initial state: stem up tilted 12 deg (random azimuth), spin about the stem.

**Theory checks**

| Quantity | Theory (formula / source) | Simulation (this run) | Agreement |
|---|---|---|---|
| Inversion possible, red/blue (alpha = 0.3) | 1 - alpha < I1/I3 < 1 + alpha: 0.7 < 0.9 < 1.3 (README) | red inverts (on its side 2.5 s, up on its stem 3.5 s); blue reaches 124-127 deg (ball and stem) | qualitative, agrees |
| Inversion impossible, green (alpha = 0.04) | 0.9 outside 0.96-1.04 (README) | max tilt 1 deg (2 s), 0 deg thereafter; never turns over in 120 s | agrees |
| Centre-of-mass height, start | R - a cos(12 deg) = 1.06 cm | 1.057 cm (TT_LOG) | agrees |
| CoM height standing on stem | stem-tip contact 2.55 cm below the CoM: 2.55 cm | max 2.545 cm, 2.49 cm at 10 s (tilt 166 deg) | agrees (CoM rises ~1.5 cm) |
| Green top CoM height | R - a = 1.44 cm | 1.441 -> 1.440 cm | agrees |
| Time to turn over (red) | README now: "about 3.5 seconds", example "Left   up on its stem at   3.5 s" (fixed 15 Oct 2026; was "about 3", "3.3 s") | on its side 2.5 s, up on its stem 3.5 s (re-run identical) | matches |
| Spin needed to stand on the stem | README/lua now: "about 80 rad/s or more" with the rule's bounds (fixed 15 Oct 2026; was "about 100"). w > 2 sqrt(I1' m g d)/I3, d = 1.95 cm: 68 rad/s with I1' about the CoM (tip sliding freely); 132 (I about the tip-sphere centre) to 163 rad/s (I about the contact) for a tip that can't slide | TT_LOG: up on its stem with ~91 rad/s; steady (tilt 171-173 deg) while >= 83 rad/s; tilt first below 170 deg at 24.0 s with 81.8 rad/s; onto ball and stem at 38.7 s; blue never above 44 rad/s after 8.3 s, never stood | between the bounds, nearer the slippery one |
| Red returns stem up | README: sinks back "twenty-odd seconds later"; all three stem up in ~1.5 min | sinking from ~24-26 s; ball+stem 38.7 s, on ball 66.6 s, 0 deg by 92 s; blue 0 deg by 76 s | agrees |
| Without spin friction | README: red "spins on its stem for ever" | TT_SPINF=0: 175 deg, 14.7 t/s still at 60 s | agrees (60 s run) |
| Rolling resistance, effect (TT_ROLL sweep, 15 Oct 2026) | README/lua now give the measured effect (fixed; was "100 microns stops the top turning over at all") | red up on its stem at 3.4-3.7 s for every value 0-300 µm; back onto ball and stem at 47.0 s (0), 22.4 (10), 38.7 (30), 37.1 (50), 33.8 (75), 30.0 (100), 23.1 (150), 12.8 s (300). Blue: reaches ball and stem at 30 µm (and 10), stays within 8 deg (2-s reports) at 50-300. At 0 nothing settles: blue rocks 16-65 deg, green's tilt grows from ~40 s to 71 deg at 78 s with its spin collapsing (36 -> 0.4 t/s) | documented |
| Determinism | (repeat run) | identical event times on a second run | reproducible |

No conservation check is printed by the exhibit; Jellett's integral (the quantity conserved during sliding on the ball) was not logged and was not checked here.

**Run used**
```
cd demo/WyomingWill/EulersGallery/exhibits/TippeTop
HOLD_S=0 bpp -f tippe-top.lua -n 7200            # main run, 120 s
HOLD_S=0 TT_LOG=tt.csv bpp ... -n 600            # CoM heights
HOLD_S=0 TT_ROLL=100 bpp ... -n 1200             HOLD_S=0 TT_SPINF=0 bpp ... -n 3600
# 15 Oct 2026: HOLD_S=0 TT_LOG=tt.csv bpp ... -n 7200 (same events as above);
#   TT_ROLL={0,10,50,75,100} -n 4800; TT_ROLL={150,300} -n 1800
```
```
  Left   on its side at   2.5 s (stem 83 deg from up)
  Left   up on its stem at   3.5 s (stem 156 deg from up)
t=  4.0s  stem from up, spin: Left 161 deg 14.6 t/s | Middle  10 deg 13.9 t/s | Right   1 deg 37.2 t/s
  Middle on its ball and stem at   8.3 s (stem 124 deg from up)
t= 26.0s  stem from up, spin: Left 160 deg 12.6 t/s | Middle 113 deg  5.0 t/s | Right   0 deg 35.4 t/s
  Left   on its ball and stem at  38.7 s (stem 127 deg from up)
  Middle spinning on its ball at  49.5 s (stem 59 deg from up)
  Left   spinning on its ball at  66.6 s (stem 59 deg from up)
t= 92.0s  stem from up, spin: Left   0 deg  1.2 t/s | Middle   0 deg  0.1 t/s | Right   0 deg 30.0 t/s
  Left   up on its stem at   3.4 s (stem 179 deg from up)        [TT_ROLL=100]
```

**Known departures and honest caveats**
- Several parameters were tuned to make the exhibit work (README): a hollow ball (a solid 2/5 m R^2 ball turned over but never stood up), a short round-ended stem (a long thin one stuck leaning), rolling resistance 30 microns (to settle the tops), spin friction 0.5 rad/s^2 (otherwise the red top never comes down).
- Spin friction and rolling resistance are phenomenological torques applied by the script, not contact physics; contact friction is Bullet's (Coulomb, 0.2).
- Event times depend on the random tilt direction (math.random); two runs here gave identical times, but other builds/Lua versions may differ.
- The stand-on-stem threshold is not a sharp prediction; the stem tip is a 6 mm sphere, and contact friction makes the effective criterion lie between the slippery and fixed-point bounds I estimated (68-132 rad/s).
- Fixed 15 Oct 2026: README and lua said 100 microns of rolling resistance stops the (red) top turning over; it does not, at any value tried up to 300 µm. They now say what it does: settles the tops (with none they rock on), brings the red one down off its stem sooner (not monotonically: 10 µm 22 s), and from 50 µm keeps the slow blue one from turning over. Also fixed: the README's console example (3.3 s -> 3.5 s), "about 3 seconds" -> 3.5, the stem threshold "about 100 rad/s" -> about 80 with the run and the rule's bounds, and the header's env-var list (TT_SPINF, TT_ROLL added).
- Open: with no rolling resistance the green (centred) top, which cannot invert, starts rocking after ~40 s and loses its spin within ~10 s (25.6 -> 3.2 t/s between 38 and 46 s; the spin friction alone would take 0.6 t/s), far faster than the spin friction (0.5 rad/s^2) allows. Not investigated; likely a contact-solver effect that the rolling resistance otherwise damps. The README says it hasn't been looked into.
- Text only; physics and console unchanged (hall vs standalone IDENTICAL, 900 frames).
- The green "centred" top spins on for a long time (27.7 t/s at 120 s), slowed only by spin friction; it is "stem up" throughout.
- The state labels (on its side, on ball and stem, up on its stem) come from tilt and height thresholds held for 0.33 s; reported times lag the actual change by that much.
- Fixed 17 Oct 2026: **the start pause changed the console.** The `t=` lines every 2 s were printed on bpp's frame count (`N % 120`), which counts the pause's frames too, so with the pause they came at t = 1.5, 3.5, ... s instead of 2.0, 4.0, .... tippe-top.lua now counts only the frames it runs (the same for the log file). With HOLD_S=0 the output is byte-identical to before (1800 frames); HOLD_S=0 for 1800 frames is now a prefix of the default for 1830 (also at 900 and 2400); hall against standalone (cmp2.sh, 1800 frames): IDENTICAL (19 run lines).

**References** — None cited in the README or code (the lua header mentions Bohr and Pauli watching one). The inversion condition 1 - alpha < I1/I3 < 1 + alpha is the standard result from the tippe-top literature, not referenced in the exhibit.
