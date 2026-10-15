## Huygens' Clocks

**What it shows** — Two pendulum clocks hang from one beam that can slide a little on a spring. Started out of step (60, then 300, then 120 degrees apart, four minutes each), within about half a minute they swing in exact opposition and the beam stops: Huygens' 1665 "odd kind of sympathy". In opposition their pushes on the beam cancel, so the beam's friction takes no energy; any in-phase part is damped away.

**Model** — Bullet. The beam (1.5 kg including the clock cases) is a rigid body restricted to slide along x (linear factor (1,0,0), no rotation, no gravity). Each pendulum is one rigid body (brass bob 3.5 cm diameter, 191 g, plus a light aluminium rod; bob centre 25 cm from the pivot) on a `btHingeConstraint` to the beam. Done by the script before every physics step, as velocity changes: the beam's spring (k from 1.5 Hz with the beam alone) and friction (5 kg/s); each pendulum's air drag (a torque proportional to angular rate, Q = 150 alone); and the escapement, an angular-velocity kick at each zero crossing, sized to replace exactly the air loss over half a swing at 8 degrees. Bullet's own damping 0, solver iterations 40, 2400 physics steps/s (Bullet's semi-implicit Euler with the hinge solver). Clock hands advance by each clock's own swing count.

**Theory checks**

| Quantity | Theory (formula / source) | Simulation (this run) | Agreement |
|---|---|---|---|
| Anti-phase normal mode (no escapement, no friction) | w^2 = m g d / I (beam still): 0.9996 Hz | not run as a free mode; used as reference | (my own 3x3 eigen-solve: 0.99964 Hz) |
| In-phase normal mode | root of det[k - (M+2m)w^2, -2md w^2; -md w^2, mgd - I w^2] = 0: 0.9179 Hz | not compared with a simulated mode | (my eigen-solve: 0.91787 Hz) |
| Anti-phase at 8 deg amplitude | 0.9996 Hz x pi / (2 K(sin(4 deg))): 0.9984 Hz | settled clock frequency 0.9987 Hz (start 60 deg), 0.9988 (300 deg), 0.9985 (120 deg) | +0.03%, +0.04%, +0.01% (README: escapement kicks account for the rest) |
| Final phase difference | 180 deg (anti-phase locking, Bennett et al. 2002) | 180.0 deg at t = 60 s for all three starts | exact to 0.1 deg |
| Beam amplitude decays | beam stops in anti-phase | 5.335 -> 0.544 -> 0.062 -> 0.008 mm at 15/30/45/60 s (start 60 deg) | ~x10 per 15 s; to 0.008 mm |
| Time to lock | README: "within a minute" | within 0.5 deg of 180 by 30 s for all three starts | consistent |
| Step-size check (my run, HC_STEPS=9600) | should not depend on step | 161.9 / 179.5 / 180.1 deg; 1.0063 / 1.0005 / 0.9990 Hz; beam 5.338 / 0.543 / 0.062 mm | agrees with 2400 /s to 1e-4 Hz and 0.003 mm |
| README console listing | README t = 15..60 s lines | identical to this run, digit for digit | matches |

No energy or momentum conservation check is performed by the exhibit (the system is driven and damped by design).

**Run used**

```
cd demo/WyomingWill/HuygensClocks && HOLD_S=0 timeout 1500 ../../../release/bpp -f huygens-clocks.lua -n 3600 | grep -v ALSA
  (also HC_PHASE=60, 300, 120 with -n 3700 to reach the t=60 s line; HC_STEPS=9600 -n 3600)

  stopped, they'd swing in opposition at 0.9996 Hz (the beam still), or together at 0.9179 Hz (the beam swinging against them)
  in opposition, swinging 8 degrees (a pendulum's slower, the further it swings: the elliptic integral): 0.9984 Hz
  t=   15 s  the clocks 161.9 degrees apart (in opposition: 180); swinging at 1.0063 Hz; the beam moving up to 5.335 mm
  t=   30 s  the clocks 179.5 degrees apart (in opposition: 180); swinging at 1.0004 Hz; the beam moving up to 0.544 mm
  t=   45 s  the clocks 180.1 degrees apart (in opposition: 180); swinging at 0.9989 Hz; the beam moving up to 0.062 mm
  t=   60 s  the clocks 180.0 degrees apart (in opposition: 180); swinging at 0.9987 Hz; the beam moving up to 0.008 mm
  [HC_PHASE=300] t=   60 s  the clocks 180.0 degrees apart ...; swinging at 0.9988 Hz; the beam moving up to 0.008 mm
  [HC_PHASE=120] t=   60 s  the clocks 180.0 degrees apart ...; swinging at 0.9985 Hz; the beam moving up to 0.004 mm
```

**Known departures and honest caveats**
- Locks in about 30 s, against Huygens' "within half an hour". The beam parameters (1.5 kg, 1.5 Hz spring, 5 kg/s friction) are chosen for a fast, visible demonstration, not to match Huygens' chairs and beam.
- The escapement is an idealised impulse at the bottom of each swing, sized exactly to the linear air loss at 8 degrees; real escapements (and Bennett et al.'s model) differ. The 0.03% excess of the settled frequency over the free anti-phase mode is put down to the kicks (README), not separately verified.
- Pendulums are confined to the plane (hinges); the beam only slides (no rocking).
- The in-phase mode frequency (0.9179 Hz) is printed but never compared against a simulated in-phase swing.
- Fixed on 15 Oct 2026: the lua header used to call the "together" mode "faster"; it now says "slower", matching its own console value (0.9179 Hz against 0.9996 Hz) and the README. Comment only; the console output is unchanged.
- A third normal mode (mostly the beam on its spring, about 1.63 Hz by my eigen-solve) exists and is not mentioned.
- The 15 s report window's "swinging at" frequency is the last single period of clock 1, so early values (1.0063 Hz) reflect the transient.

**References**
- C. Huygens, 1665 observation ("an odd kind of sympathy") — README.
- M. Bennett, M. F. Schatz, H. Rockwood and K. Wiesenfeld, Proc. R. Soc. A (2002) — README and lua header (title not given there).
