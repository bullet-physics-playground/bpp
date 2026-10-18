# The Brazil-nut bed: an independent DEM reference (17 Oct 2026)

## Where things stand

- **Bullet at the exhibit's default 2400 steps/s is numerically wrong by about
  2x.** Its convection rolls run about twice as fast as its own converged
  answer, and the big bead comes up several times sooner. Bullet converges by
  9600 steps/s (19200 agrees within the pour-to-pour scatter), and converged it
  equals a converged linear-spring DEM with the same materials. The lift-off
  phase converges to about 40 degrees in every model; the bed has landed by
  then (38-42 degrees).
- **Converged, the convection still depends on the contact law.** Elastic
  glass contacts (Hertz-Mindlin, converged in stiffness and step) give rolls
  2-4x slower than converged Bullet with the exhibit's materials. Rigid-impulse
  Bullet and the usual linear-spring DEM share a contact compliance that
  elastic glass doesn't have.
- **The exhibit's materials are not glass** (bounce 0.01 against 0.95;
  friction 0.64 / 0.8 against about 0.1). With real glass, in this geometry
  the rolls reverse (down in the middle, up at the walls) and the big bead never
  rises (0 of 8 runs within 60 s). Normal rolls come back only with side-wall
  friction of about 0.3 or more: the exhibit's high wall friction is what makes
  the demonstration work.
- **Faithful numbers, exhibit's materials, Hertz-Mindlin** (spread between
  pours): middle box rise in the middle 0.7 +/- 0.5 mm/s, fall at the walls
  2.3 +/- 0.8; the big bead reached the top in 2 of 4 runs within 180 s (41 s,
  77 s), then spent only 45-51% of the time in the upper half. Right box
  2.2 +/- 0.6 / 3.8 +/- 0.7; the coloured bead comes up in 6-36 s when it
  does. The exhibit's default shows 5.5 / 10.1 mm/s, a 6.3 s rise, and 77-95%
  of the time in the upper half.
- **Cost:** the converged reference is 9-40x over the exhibit's frame budget,
  so it can't drive the exhibit live.

All runs were made on 17 Oct 2026 on a shared 2-core Xeon (2.1 GHz). "+/-" is
the standard deviation between pours (seeds), not the error of the mean.

## 1. Question

The exhibit's convection is not step-converged in Bullet. In the middle box the
rise in the middle is 5.5, 3.2 and 2.4 mm/s at 2400, 4800 and 9600 steps/s,
and the big bead's rise time is 6.3, 11.9 and 43.6 s.

This note builds a soft-sphere DEM reference of the same bed outside Bullet,
`bead-bed.c`, validates each ingredient, and separates two questions: are
Bullet's numerics wrong, and are the exhibit's materials wrong?

## 2. Model

**Taken from brazil-nut.lua:**
- Box and shaking: 15 cm wide inside. The floor and side walls move together as
  y = A sin(wt) from t = 0, at rest before. f = 7 Hz, A = Gamma g / w^2
  (15.21 mm at Gamma = 3, 4.06 mm at 0.8), g = 981 cm/s^2.
- Beads: 140 small beads of radius 0.5 x (0.95 + 0.1 x ((37 i) mod 100)/99) cm;
  a big bead (1.5 cm) or a coloured small one (0.5 cm), at the bottom in the
  middle; density 2.5 g/cm^3.
- Pour: the lua's loose rows and its Lua-double random-number generator, drawn
  through the three boxes in turn. `SEED=n` here is the same pour as
  `BN_SEED=n`. 0.5 s to settle.
- Degrees of freedom: spheres held to the plane, spinning about its normal,
  with no front or back plate, as in the exhibit. `PLATES=1` frees the beads in
  3-D between frictional plates `GAP` apart (right box only; a 3 cm bead can't
  sit in a one-bead slot).

**Contacts:**
- Linear normal law (`MODEL=0`): a spring-dashpot clamped at zero. k is the same
  for all contacts, set by `TC`, the undamped half-period of two average small
  beads. The damping ratio is bisected from a simulated two-body collision so
  that it returns e exactly (with the clamp, e < 0.135 needs a damping ratio
  above 1; e = 0.01 needs 4.8).
- Hertz normal law (`MODEL=1`): K d^1.5, with K = 4/3 E* sqrt(R_eff) and
  E* = E / 2(1 - nu^2); E = 63 GPa and nu = 0.22 (from memory). Tsuji's damping
  alpha sqrt(m_eff K) d^(1/4) d', with alpha bisected the same way.
- Tangential: a Cundall-Strack spring and dashpot, kept in the tangent plane and
  capped by Coulomb's law at mu F_n. kt/kn is 2/7 for the linear law by default
  and Mindlin's 2(1 - nu)/(2 - nu) = 0.876 for Hertz.
- Rolling resistance: optional, off.

**Integration:** velocity Verlet with predicted velocities in the damping
terms, and a cell list.

**Measurements,** identical to the lua's:
- floor push from the bed's momentum change, shakes 5-32, in 2-degree bins;
- lift-off at < 0.1 W; landing when the centre of mass stops approaching the
  floor;
- top reached when the special bead's top is within 0.3 cm of the mean of the
  highest tenth of beads plus 0.5 cm;
- convection: rise rates every 0.5 s from 5 to 60 s, for |x| < 3 cm ("middle")
  and |x| > 5 cm ("walls");
- trips of the coloured bead, and the big bead's time in the upper half.

**Not modelled:** air, cohesion, electrostatics, a velocity-dependent e, the
shaker's compliance.

## 3. Validation

**Restitution: drop on the floor and head-on pair, closing at 1-200 cm/s**

| law, step | nominal e | floor | pair | contact time |
|---|---|---|---|---|
| linear, TC/40 | 0.95 | 0.9501-0.9508 | 0.9493-0.9518 | 0.14 ms (TC 0.1 ms) |
| linear, TC/40 | 0.1 | 0.1009-0.1064 | - | 0.20 ms |
| linear, TC/160 | 0.01 | 0.0099-0.0106 | 0.0106-0.0108 | 0.48 ms |
| Hertz glass, TC/40 | 0.95 | 0.9500-0.9504 | 0.9499-0.9505 | 91 us at 1 cm/s, 31 us at 200 cm/s |
| Hertz glass, TC/60 | 0.1 | 0.0997-0.1024 | 0.0994-0.1027 | 0.16 to 0.06 ms |
| Hertz glass, TC/40 | 0.01 | 0.0103-0.0116 | 0.0100-0.0117 | 0.51 to 0.17 ms |

**Incline, mu = 0.64 and 0.1, both laws.**
- Spin locked: sticks at tan(theta) = 0.99 mu, slides at 1.01 mu, with
  a = g (sin theta - mu cos theta) to 5 significant figures.
- Free: rolls without slip at a = (5/7) g sin(theta) up to 3.45 mu, and slips
  from 3.55 mu (theory: 3.5 mu).

**Damping stability.** Explicitly integrated overdamped dashpots blow up on
beads with several contacts; the settled bed's overlaps and kinetic energy,
printed at t = 0, are the check. Stable settings:
- linear: NS >= 40 at e >= 0.1 (NS 20 blew up in shaking: 50% overlaps);
  NS >= 200 at e = 0.01;
- Hertz: NS >= 60 at e = 0.1 (NS 30 blew up); NS >= 40 at e = 0.95, with 80
  needed for the glass right box's convection;
- Hertz at e = 0.01 blew up in shaking even at NS 200; those runs are
  discarded, and the exhibit's e = 0.01 is represented by e = 0.1, checked
  against e = 0.3.

**Gamma = 0.8: least floor push over 0-90 degrees**

| | least push (W) |
|---|---|
| rigid bed, theory | 0.200 |
| Hertz-Mindlin glass, sets (a) and (b) | 0.1999-0.2000 |
| linear, TC 0.1 ms | 0.1994-0.1996 |
| linear, TC 0.3 ms | 0.195-0.198 |
| Bullet, 2400/s | 0.18-0.19 |

**2-D path.** The in-plane contact routine reproduces the 3-D routine's
validation exactly; bed runs differ at rounding level, which grows chaotically.

## 4. Convergence

**4.1 Linear law, exhibit's materials (mu 0.64 / 0.8, e = 0.1), NS = 40.**
Seeds 1, 2, 7, 8 unless noted. Rise and wall columns in mm/s; "overlap" is the
peak overlap over R_eff.

| TC (s) | box | rise in middle | walls | top reached (s) | lift-off deg | landed deg | overlap | CPU s per sim s |
|---|---|---|---|---|---|---|---|---|
| 1e-3 | middle | 10.0+/-0.5 | -15.9+/-1.3 | 3.4, 2.0, 3.3, 3.1 | 76 | 52 | 0.54 | 0.44 |
| 3e-4 | middle | 5.9+/-1.6 | -9.3+/-1.8 | 20.4, 7.5, 12.2, 9.1 | 51 | 42 | 0.16 | 1.27 |
| 1e-4 | middle | 2.5+/-0.8 | -5.8+/-0.8 | >60, >60, >60, 11.2 | 42 | 40 | 0.062 | 3.2 |
| 3e-5 (seeds 7, 8) | middle | 2.6+/-0.9 | -6.0+/-1.2 | 13.3, >60 | 38 | 39 | 0.017 | 9.7 |
| 1e-3 | right | 11.6+/-0.9 | -18.1+/-0.9 | 8.2, 6.8, 6.3, 5.3 | 72 | 52 | 0.38 | 0.42 |
| 3e-4 | right | 6.0+/-0.7 | -9.9+/-0.7 | 12.6, 14.9, 10.3, 24.9 | 46 | 42 | 0.11 | 1.23 |
| 1e-4 | right | 4.0+/-0.4 | -7.0+/-0.3 | 24.3, 28.1, 44.3, 21.0 | 40 | 40 | 0.033 | 2.9 |
| 3e-5 (seeds 7, 8) | right | 3.9+/-0.8 | -6.9+/-0.1 | 32.5, 33.4 | 39 | 40 | 0.007 | 9.4 |

Linear step at TC 1e-4, seeds 7 and 8: NS 40 gives middle 1.7 and 3.5 mm/s,
right 3.7 and 3.9; NS 80 gives middle 1.8 and 1.7, right 5.0 and 4.5. These
differ only within the scatter. Linear restitution e = 0.3 gives 2.2 / -6.1
(middle) and 4.0 / -7.5 (right), the same as e = 0.1.

**4.2 Hertz-Mindlin (the faithful law)**

| case | box | rise in middle / walls (mm/s) | top reached (s) | lift-off / landed deg |
|---|---|---|---|---|
| (a) 63 GPa, NS 60, seeds 7, 8 | middle | 0.0+/-1.2 / -1.2+/-1.1 | >60, >60 | 40 / 41 |
| (a) 6.3 GPa, NS 60, seeds 1, 2, 7, 8 | middle | 0.7+/-0.5 / -2.3+/-0.8 | 40.6, none in 180 s, none in 180 s, 77.4 | 40 / 41 |
| (a) 6.3 GPa, NS 120, seeds 7, 8 | middle | 0.7+/-0.9 / -2.0+/-1.1 | 22.9, >60 | 44 / 41 |
| (a) 63 GPa | right | 1.7+/-0.4 / -3.1+/-1.4 | 10.8, 36.7 | 40 / 41 |
| (a) 6.3 GPa, seeds 1, 2, 7, 8 | right | 2.2+/-0.6 / -3.8+/-0.7 | 6.1, >60, 23.6, >60 | 40 / 41 |
| (a) 6.3 GPa, NS 120 | right | 3.1+/-0.0 / -4.5+/-0.4 | 45.2, 24.9 | 39 / 40 |
| (b) 63 GPa | middle | -3.7+/-2.4 / +3.9+/-2.1 | >60, >60 | 66 / 54 |
| (b) 6.3 GPa, seeds 1, 2, 7, 8 | middle | -2.9+/-0.5 / +3.4+/-0.8 | all >60 | 68 / 54 |
| (b) 6.3 GPa, NS 80 | middle | -3.0+/-0.5 / +3.8+/-0.7 | >60, >60 | 66 / 54 |
| (b) 63 GPa | right | -1.2+/-0.3 / +2.5+/-0.8 | 20.4, 37.1 | 69 / 54 |
| (b) 6.3 GPa, NS 80, 4 seeds | right | -2.9+/-1.0 / +3.4+/-1.2 | 19-25 | 68 / 54 |
| (b) 6.3 GPa, NS 160, seeds 7, 8 | right | -2.2+/-0.6 / +1.9+/-0.3 | 22.7, 7.6 | 67 / 54 |

- Stiffness: dividing the modulus by 10 changes nothing beyond the scatter.
- Step: NS 40 is slightly weak for the glass right box; NS >= 80 has converged.
- Restitution, set (a) materials: e = 0.3 gives 1.0 / -3.3 (middle) and
  2.9 / -4.9 (right), mildly above e = 0.1.
- The big bead after reaching the top: 45-51% of the time in the upper half,
  against 85% for the linear law and 77-95% in the exhibit.

**4.3 Why the two laws differ: tangential compliance**

| law | KT | middle box, rise in middle / walls (mm/s) |
|---|---|---|
| linear, TC 1e-4, seed 7 | 0.1 | 2.3 / -5.4 |
| linear, TC 1e-4, seed 7 | 2/7 | 1.7 / -4.7 |
| linear, TC 1e-4, seed 7 | 1.0 | 0.9 / -3.9 |
| Hertz, seeds 7, 8 | 2/7 | about 0 / -0.9 |
| Hertz, seeds 7, 8 | 0.876 (Mindlin) | 0.0 / -1.2 |

A stiffer tangential spring gives slower rolls. Hertz at KT 2/7 also gives about
half the linear value in the right box (2.2-2.6 against 4.0). So the converged
convection depends on contact-level compliance by a factor of 2-4. Mindlin's
no-slip value is the physical elastic one for glass. Bullet has no tangential
compliance; its friction acts through impulses with error-correction drift.

## 5. Reference against Bullet, set (a) (BN_SEED 1, 2, 7, 8)

| Bullet | box | rise in middle / walls (mm/s) | top reached (s) | lift-off deg | landed deg | trips |
|---|---|---|---|---|---|---|
| 2400 | middle | 5.4+/-0.5 / -10.3+/-0.7 | 4.2, 20.4, 6.3, 21.4 | 48+/-4 | 40 | - |
| 4800 | middle | 3.3+/-1.5 / -7.4+/-1.5 | 15.5, 8.8, 11.9, >60 | 40+/-3 | 40 | - |
| 9600 | middle | 2.4+/-0.4 / -5.9+/-0.2 | >60, >60, 43.6, >60 | 42+/-3 | 39 | - |
| 19200 (seeds 7, 8) | middle | 2.8+/-0.3 / -6.8+/-0.1 | >60, >60 | 40+/-3 | 40 | - |
| 2400 | right | 7.1+/-0.7 / -11.9+/-1.0 | 15.9, 13.3, 11.6, 12.7 | 45 | 41 | 3.5 |
| 4800 | right | 5.3+/-0.5 / -9.5+/-0.4 | 35.8, 9.0, 19.3, 13.6 | 40 | 40 | 1.8 |
| 9600 | right | 4.8+/-0.6 / -8.5+/-0.6 | 20.9, 43.9, 31.9, 21.3 | 40 | 41 | 1.0 |
| 19200 (seeds 7, 8) | right | 5.1+/-0.2 / -9.0+/-0.8 | 24.7, 26.2 | 38 | 40 | 1.0 |

- Bullet 2400 behaves like the linear law at TC 0.3 ms; Bullet at 9600 and
  above like TC 0.1 ms or less.
- Converged Bullet against converged linear: the same in the middle box, Bullet
  20-25% faster in the right box.
- Against Hertz-Mindlin: 2-4x faster.
- Bullet's seed 7 at 2400 reproduces the README's numbers exactly.

## 6. Real glass (set b: e = 0.95, mu = 0.1 / 0.1)

**Material values** (Cornell impact table, read 17 Oct 2026): glass on glass,
e = 0.97 and mu = 0.092 (soda-lime, 3.18 mm); 0.922 / 0.048 (fresh);
0.972 / 0.177 (spent). Glass spheres on flat plates: mu = 0.12-0.14, but
against aluminium, a bead or acrylic; there is no glass-on-glass-plate row.

**Findings:**
- The rolls reverse, with both laws (linear TC 1e-4: -2.8 / +3.6) and with or
  without plates. The big bead never rises (0 of 8 runs within 60 s); the
  coloured bead still rises along the walls.
- The bed lands late, at 54 degrees, and lifts off at 66-69.
- In the linear law, softness changes the strength (-1.6 to -3.9 mm/s) but not
  the direction.
- Bullet can't run this set: glass-like bounce fluidises the bed (see the
  exhibit's README).

## 7. Wall friction, Gamma, front and back plates (right box, Hertz-Mindlin 6.3 GPa, seeds 7, 8)

| case | rise in middle / walls (mm/s) |
|---|---|
| set (a), mu_w 0 | 1.1 / -0.8 |
| set (a), mu_w 0.3 (seed 7 only) | 1.5 / -1.5 |
| set (a), mu_w 0.8 | 2.2 / -3.8 |
| set (b), mu_w 0.1 | -1.5 / +1.9 (reversed) |
| set (b), mu_w 0.3 (seed 7 only) | 0.3 / -0.8 |
| set (b), mu_w 0.8 (seed 7 only) | 0.1 / -1.7 |
| set (a), Gamma 2 | 0.6 / -1.5 (lift-off 28 deg) |
| set (a), Gamma 3 | 2.2 / -3.8 |
| set (a), Gamma 4 | 3.2 / -5.4 (lift-off 76 deg) |
| set (b), Gamma 2 | 0.3 / -0.4 |
| set (b), Gamma 4 | -5.1 / +5.0 |
| plates, gap 1.1 cm, set (a), mu_p 0.8 (seed 7 only) | 2.2 / -3.9 |
| plates, gap 1.1 cm, set (b), mu_p 0.1 (seed 7 only) | -1.7 / +2.3 |

Side-wall friction drives the rolls and sets their direction. Front and back
plates add nothing, because gravity lies in the plane and nothing presses the
beads onto them.

## 8. Literature

- **Mechanism, confirmed.**
  - Knight, Jaeger and Nagel, PRL 70, 3728 (1993): a convection cycle "rising in
    the middle and dropping in a thin stream along the walls"; particles larger
    than the downward stream are trapped at the top.
  - Gallas, Herrmann and Sokolowski, PRL 69, 1371 (1992), 2-D molecular
    dynamics: "the direction of the motion relative to the walls depends on
    shear friction". This matches the reversal at low wall friction here.
  - Lee, cond-mat/9301004 (1993), 2-D molecular dynamics: convection needs wall
    friction above a threshold.
  - Pastor et al., Physica D 232, 128 (2007): wall friction is the proposed
    mechanism; the drift grows with Gamma. Above Gamma of about 3 the collision
    lasts about as long as the layer stays on the plate, consistent with
    lift-off equal to landing (about 40 degrees) here.
- **Speeds and rise times: no quantitative target for this box exists.**
  - Hejmady et al., arXiv:1111.4484 (quasi-2D, mustard seeds 1.5-2 mm,
    sandpaper walls) fit tau = 13000 cm^2/s x (v - v_c)^-2, with v = A w and
    v_c of about 15-18 cm/s. Here v = 66.9 cm/s gives 4.8-5.4 s, but their
    walls are rough, their grains 5-7x smaller, and their rise height specific
    to their cell.
  - Then, Sekiguchi and Okumura, arXiv:2008.01958 (one layer of 1 mm alumina
    between plates 1.2 mm apart, W/d = 55-105, walls tilted 5 degrees): the
    downflow band is a few grains wide and attributed to wall friction.
    Extrapolating their law to W/d = 15 gives 84 mm/s, which is not credible.
  - Yamada and Katsuragi, arXiv:1404.0136 (3-D): v depends on
    S = (A w)^2/(g d) (4.6 here), not on Gamma alone.
  - Knight et al., PRE 54, 5726 (1996) and Ehrichs et al. (1995) were not read;
    their Gamma dependence is quoted only through Hejmady: tau proportional to
    (Gamma - 1.2)^-2.5.
- **Consistent qualitatively:** convection grows with Gamma and with wall
  friction and appears only above Gamma of about 1-2; every experiment that
  shows normal rolls uses rough or high-friction walls.

## 9. Conclusion

- **Bullet's numerics at the default 2400 steps/s** are about 2x too fast in
  convection and several times too early in the big bead's rise; the lift-off
  is about 6 degrees late (48 against 40), and the least push at Gamma = 0.8 is
  0.01-0.02 W low. At 9600 steps/s and above Bullet has converged, and equals a
  converged linear-spring DEM with the same materials.
- **Rigid-impulse Bullet and the 2/7 linear law share one assumption:** a
  contact compliance that elastic glass (Hertz-Mindlin) doesn't have. With
  physical contacts the exhibit's materials give 0.7 / -2.3 mm/s (middle box)
  and 2.2 / -3.8 (right box). The big bead rises erratically: half the pours
  within 3 minutes, and then without staying up.
- **The exhibit's materials are not glass.** With real glass in this plate-less
  geometry the rolls reverse and there is no Brazil-nut rise; normal rolls come
  back only with wall friction of about 0.3 or more. The exhibit's high wall
  friction is what makes the demonstration work.
- **Recommendations:** quote the converged numbers in the README with their
  dependence on the contact law; say that the exhibit's lively rise is a
  product of soft numerics on high-friction (rough) walls; and that real glass
  beads need rough walls.

## 10. Cost, and what driving the exhibit with it would need

About 7.4 us per step for one 141-bead box.

| model | CPU s per simulated second, per box |
|---|---|
| linear, TC 0.1 ms | 2.9 |
| linear, TC 0.03 ms | 9.5 |
| Hertz-Mindlin, 6.3 GPa | 5.3 (set a) / 3.1 (set b) |
| Hertz-Mindlin, 63 GPa | 13 / 8 |

The exhibit runs at BN_SPEED 1 and 60 fps: a frame has 16.7 ms for three boxes,
or at most 0.33 s of CPU per simulated second per box. The converged reference
is 9-40x over; even 3 threads and 2-3x from SIMD would leave it several times
over. For comparison, Bullet at 9600 steps/s costs about 4-5x its default, which
itself takes about 35 ms a frame on this machine.

**The hook it would need (not written):** a C++ class (e.g. `DemBed`) registered
via luabind next to `lua_bullet_*.cpp`, with a constructor taking the parameters
and the pour; `step(nsteps, dt, boxY(t), boxV(t))`, called from `v:preSim`,
running the contact loop natively, one worker thread per box; `sync()`, writing
bead transforms into display-only Sphere objects (`collides = false`, mass 0),
or `getPos(i)` and `getSpin(i)`; and the push, convection and rise measurements
accumulated in C++ and read with getters.

## 11. Still open

- The physical tangential compliance: Mindlin micro-slip, roughness, and whether
  real glass beads behave nearer KT 0.88 or softer. This sets a factor of 2-4.
- Sustained-sliding friction of glass beads on glass and wooden walls; the roll
  direction flips between mu_w 0.1 and 0.3.
- The rise-time distribution beyond 180 s, with more seeds.
- Hertz at e = 0.01, which needs a finer step or implicit damping.
- A velocity-dependent e for glass, and the big bead as a disc in a real
  one-bead-thick box.
- Knight et al. (1996) and Ehrichs et al. (1995), not read.

## 12. Files and how to run

```
gcc -O2 -o bead-bed bead-bed.c -lm
./bead-bed BOX=middle|right|gentle SEED=7 MODEL=1 YM=6.3e9 NS=60 E=0.1   # faithful, set (a)
./bead-bed BOX=middle MODEL=1 YM=6.3e9 NS=80 E=0.95 MUB=0.1 MUW=0.1       # real glass
./bead-bed BOX=middle TC=1e-4 E=0.1                                       # linear, converged
./bead-bed TEST=drop|pair|incline ...                                     # validation
```

Options: `PLATES=1 GAP=1.1 MUP=`, `GAMMA=`, `KT=`, `TEND=`, `LOG=file.csv`
(writes `file.csv.phase` too).
