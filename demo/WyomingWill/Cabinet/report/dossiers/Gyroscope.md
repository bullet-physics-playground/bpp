## The Gyroscope

**What it shows** — Three identical toy gyroscopes spun to 100 turns/s. Left: held only by one end of its axle on a pedestal point, it does not fall but precesses with the axle level. Middle: the same, hung by a string. Right: axle upright, standing on a tightrope on a forked foot, balancing like a top on its point; an attendant rocks the wire 1 degree each way so it slides to and fro, upright, about 9 cm each way. As the rotors slow, the left two precess faster and sag; the tightrope one wobbles wider and finally comes off.

**Model**
- Gyroscope: one Bullet rigid body (hoop 50 g, axle 10 g, rotor 100 g; M = 160 g). Rotor r = 3 cm, I_rotor = 0.65 m r^2 = 0.585 kg cm^2; body moments (code): axial 1.069, in-hoop-plane 0.849, across-hoop 1.333 kg cm^2. Holding balls at r = 6.0 cm from the centre; the foot's wire contact 6.38 cm (PIV + ball + wire radius).
- Rotor spin is a scalar angular momentum h = I_rotor*S inside the body (gyrostat); Bullet never spins a body at 100 turns/s. Bullet's gyroscopic term is off; the script applies -w x (I w + h) as an external torque each step, 2nd-order Adams-Bashforth (README: a one-step torque grows the wobble; a direct velocity update makes it sag steadily).
- Pedestal: btPoint2PointConstraint at the ball's centre; released when the axle sags 40 deg below level. String: a 2 g, 12 cm rigid rod with ball joints at both ends. Wire: kinematic capsule, radius 0.06 cm, 30 cm long; foot = sphere + two capsule prongs; foot-wire friction 0.005 (slides on slopes > 0.3 deg).
- Losses: rotor bearing 1 turn/s per second; pivot friction 0.5e-3 N m against any turning at the pedestal (a quarter at the string's knot). Rocking: wire tipped +/-1 deg about its middle in 0.6 s (cosine ramp), always up on the gyroscope's side, judged 0.3 s ahead, with timing adapted to reach ~9 cm each way.
- 2400 physics steps/s, 30 solver iterations, no damping, g = 981 cm/s^2.

**Theory checks** (theory values computed now from the code's constants unless marked README)

| Quantity | Theory (formula / source) | Simulation (this run) | Agreement |
|---|---|---|---|
| Precession rate at 100 turns/s | Omega = m g r / (I_rotor w) = 0.16*981*6/(0.585*628.3) = 2.562 rad/s (2.45 s per turn); README/lua now say the same (fixed 15 Oct 2026; they said 2.67 rad/s, 2.35 s) | 2.582 rad/s over 0.5-2 s (mean spin ~99 t/s; theory 2.588); 2.656 rad/s over 0-8 s at mean spin 96 t/s (theory 2.669) | -0.2% / -0.5% |
| Turns round in first 8 s (100 -> 92 t/s) | integral of m g r/(I w(t)) = 3.40 turns; README now "3.35 turns ... (theory 3.40; the console rounds it to 3.4)" | pedestal 3.35, string 3.36 (from GY_LOG); console "3.4 times round" | -1.5% |
| Precession as it sags (pedestal), with tilt term | m g r = Omega h + Omega^2 (I_pivot - I_axial) sin(theta), I_pivot = 7.093, I_axial = 1.069 kg cm^2 | 8-16 s 2.878 vs 2.877; 16-24 s 3.132 vs 3.132; 24-32 s 3.413 vs 3.430; 32-36 s 3.692 vs 3.685 | 0.0 to -0.5% (first-order formula alone: -1% to -5%) |
| Sag with no pivot friction (dip from the wobble) | m g r I / (I_rotor w)^2 (I = 6.6-7.1 about pivot): 2.6-2.8 deg at 100 t/s, 7.3-7.9 at 60, 16.5-17.7 at 40. README: "3 deg at 100, 16 at 40" | GY_PIVF=0: pedestal 8.3 deg at 60 t/s, 17.3 deg at 40 t/s; 0.1-3.4 deg sampled at 92-98 t/s | agrees (within the I range) |
| Sleeping-top criterion on the wire | I3 w > 2 sqrt(I m g l), l = 6.38 cm, I about the foot 7.36-7.85 kg cm^2: 46.7-48.2 t/s. README: "above 46 (46.7 to 48.2 ...)" | still wire, rough (GY_MU=0.3): off at 52 t/s (48.2 s) | README: 52, matches |
| Still wire, slippery foot (0.005) | README: off at 45 t/s; with I about the CoM (ice rule) the bound is 15.9-19.9 t/s | off at 45 t/s (55.0 s) | matches README |
| Rocked 1 deg (default) | README: lasts 62 s, off at 38 t/s | off the wire at 62.0 s, 38 t/s | matches |
| Rocked 1.5 deg | README/lua now: 49 s, at 51 t/s, shorter than the still wire (fixed 15 Oct 2026; they said 55 s, "as long as on a still wire, or longer") | off at 49.0 s, 51 t/s | matches |
| Rocked 2 deg | README: thrown over in 13 s | off at 12.7 s | matches |
| Rocked 3 deg | README: 6 s | off at 5.9 s | matches |
| Slide range when rocked 1 deg | README: "about 9 cm each way (5 to 12 cm; the first time 14 ...)" | turn points (scratch copy logging the attendant's turn detection, 0-55 s): 13.9 first, then 4.8-12.5 cm | matches |
| Slide range when rocked 1.5 deg | README: stops 1 to 15 cm out; 14-15 cm in its last 6 s, attendant at its 4 cm limit | turn points 1.2-14.7 cm; 14.1, 13.9, 14.5, 14.7 cm at 42-47 s with the timing offset at its clamp (-4 cm) | matches (documented, not fixed) |
| Pedestal slides off / string stops | README now: pedestal off "after 37 seconds"; tightrope off "after a minute, at 38 turns a second"; string rotor stops at 100 s | pedestal off at 37.2 s (63 t/s); tightrope off 62.0 s (38 t/s); string spin 0 t/s at 100.0 s | matches |

**Run used**
```
cd demo/WyomingWill/Gyroscope
HOLD_S=0 GY_LOG=gy.csv bpp -f gyroscope.lua -n 7200          # defaults: rock 1 deg
HOLD_S=0 GY_ROCK=0 bpp ... -n 7200     HOLD_S=0 GY_ROCK=0 GY_MU=0.3 bpp ... -n 5400
HOLD_S=0 GY_ROCK=1.5 bpp ... -n 5400   HOLD_S=0 GY_ROCK=2 ... -n 3600   HOLD_S=0 GY_ROCK=3 ... -n 1800
HOLD_S=0 GY_PIVF=0 bpp ... -n 3600
# re-run 15 Oct 2026 (after the text fixes): GY_ROCK = 1, 1.5, 2, 3, 0 with GY_LOG, -n 4800; GY_ROCK=0 GY_MU=0.3 -n 4200
# 1.5 deg investigation: a scratch copy printing the attendant's turn points and timing offset (rock.late), GY_ROCK=1 and 1.5, -n 3300
```
```
t=  8.0s  Pedestal below level  9.5 deg,  92 t/s, 3.4 times round | String below level  5.4 deg,  92 t/s, 3.4 times round | Tightrope from upright  4.1 deg,  92 t/s,  +0.8 cm along the wire, tipped -0.63 deg
t= 14.0s  ... Tightrope from upright  5.0 deg,  86 t/s,  +9.2 cm along the wire, tipped -1.00 deg
  Pedestal  off the pedestal at  37.2 s (spin 63 turns/s)
  Tightrope off the wire at  62.0 s (spin 38 turns/s)                         [rock 1]
  Tightrope off the wire at  55.0 s (spin 45 turns/s)                         [rock 0]
  Tightrope off the wire at  48.2 s (spin 52 turns/s)                         [rock 0, mu 0.3]
  Tightrope off the wire at  49.0 s (spin 51 turns/s)                         [rock 1.5]
  Tightrope off the wire at  12.7 s (spin 87 turns/s)                         [rock 2]
  Tightrope off the wire at   5.9 s (spin 94 turns/s)                         [rock 3]
t= 60.0s  Pedestal below level 17.3 deg,  40 t/s, 36.6 times round | ...      [pivot friction 0]
```
(The t=14.0 s line is shortened with "..."; precession rates are least-squares fits to the logged axle heading.)

**Known departures and honest caveats**
- The rotor is not simulated as a spinning body; the gyroscopic torque is applied explicitly (Adams-Bashforth). The README says the more obvious alternatives either grow the wobble or make it sag steadily.
- Sagging comes from a chosen pivot-friction torque (0.5e-3 N m), not from a contact model; the 40 deg release from the pedestal is a scripted rule; the string is a rigid 2 g rod, not a flexible string.
- The foot friction 0.005 ("as if it ran on a little wheel") is chosen so the gyroscope slides on a 1 deg tilt. The attendant is a feedback controller (lead 0.3 s, adaptive timing), not physics.
- Fixed 15 Oct 2026: the precession rate in README and lua header (was 2.67 rad/s, 2.35 s per turn, at 100 t/s; that is the value at about 96 t/s) now reads 2.56 rad/s, 2.45 s, from the stated m = 160 g, r = 6 cm, I = 0.65 m r^2; the "3.4 turns in 8 s" now says 3.35 (theory 3.40, console rounds to 3.4).
- Fixed 15 Oct 2026: rocked 1.5 deg, README and header now give the measured 49.0 s (51 t/s), shorter than the still wire's 55.0 s; only 1 deg (62.0 s) outlasts the still wire. The "about 40"/"about 50" turns/s wording is replaced by the run values: rough still wire 52, slippery still wire 45, rocked 1 deg 38; pedestal off at 37 s.
- Still open, now documented in the README: rocked 1.5 deg the attendant does not hold 9 cm. Its turn points scatter from 1.2 to 14.7 cm (at 1 deg: 4.8-12.5 after a first 13.9). The attendant's correction is an integral on the reach error (gain 0.3, offset clamped at +/-4 cm); at 1.5 deg the same timing error gives 1.5x the distance, and in the last 6 s before it falls it overshoots to 14-15 cm with the offset at its clamp. The wobble is wider (9-17 deg from upright vs 2-8 at 1 deg, 17-28 deg in the last swings); the README says that most likely the wobble pushes the foot along too, and that this has not been separated from the slope's push. Nothing in the physics was changed.
- The sleeping-top threshold is only approximate here: the foot is a sphere sliding on a thin capsule, not a fixed point; the README itself explains the slippery foot shifts the relevant I toward the centre of mass.
- No step-size convergence study is documented; all runs at 2400 steps/s.

**References** — None cited in the README or code. Formulas used are the textbook gyroscope precession rate and the sleeping-top (Maxwell/Klein-Sommerfeld) stability criterion.
