# A Brazil-nut bed of real glass: a design study (17 Oct 2026)

(Built the same day as the exhibit: the deep 5 Hz design with glued-bead
walls beside its smooth-walled control, run by bpp's DemBed, the model below
moved into bpp. The exhibit adds a 2 s gentle opening and closes the boxes
with a lid 44 cm up: in an open box beads fly up to 84 cm. Its
README gives its numbers; HOOK.md describes the move.)

Can the exhibit be rebuilt with realistic materials (real glass beads, e about
0.95 and mu about 0.1, in a box whose walls are made rough the way laboratories
make them) and still show the Brazil-nut effect, live in bpp, within a
visitor's attention span? This note answers that with the independent DEM
reference (`bead-bed.c`, see FINDINGS.md), extended here with physically
modelled rough walls, and with tests of Bullet inside the real bpp binary.
Nothing in the exhibit was changed.

## Answer in brief

**Yes, with a deep bed and glued-bead walls, shaken at 5 Hz.** The design:
- **beads:** 280 real glass beads, 0.95-1.05 cm (e 0.95, mu 0.1), in a box
  15 cm wide, so the bed is 20 cm deep packed;
- **walls:** both side walls lined with a row of the same 1-cm glass beads,
  glued touching and half-embedded;
- **big bead:** solid glass, 3 cm;
- **shaking:** 5 Hz at Gamma 3 (amplitude 29.8 mm).

What it does:
- **The rolls are normal:** +5.1 +/- 0.1 mm/s up the middle and
  -13.9 +/- 0.5 down the walls (4 pours).
- **The big bead rises about 10 cm in 4-8 s** (from 1.5 cm at rest to a
  12 cm centre height), in 9 of 9 pours across three stiffnesses
  (0.63, 6.3 and 63 GPa).
- **It stays up.** Over the last 20 s of 90 its centre averages 14.5-15.6 cm
  and never drops below 10.3 cm; its top sits about 4 cm below the packed
  surface (20.2 cm).
- **The walls are doing it.** With flat glass walls the same bed's rolls
  reverse (-1.1 / +2.0) and the big bead stays low. It is bounced about at
  7-10 cm (late mean), never in the upper half over the last 20 s, in 5 of 5
  pours (§3.5).

The route there:

- **Rough walls give the rolls.** Glued glass beads the size of the bed's own
  turn real glass's reversed rolls (-3.0 / +3.8 mm/s, middle / walls, in the
  exhibit's 140-bead box) into normal ones (+1.5 / -6.0). Smaller glued beads
  (0.5 cm), P60 sandpaper (mu 0.8 plus grit) and a flat wall of mu 0.8 don't:
  the roughness has to be on the scale of the beads.
- **The bed has to be deep.** In the exhibit's 140-bead bed (10 layers) a
  solid glass big bead never rises: 0 of 32 pours over 17 designs (wall types,
  Gamma 2-5, 5-10 Hz, width, depth, size ratio, rough floor, rolling
  resistance), 60 s, and still nothing after 180 s. Real glass is bouncy and
  slippery, and a shallow bed of it is fluidised: its top tenth of beads flies
  at 18-19.5 cm against 10.8 cm packed. That is the regime where heavy
  intruders don't rise (Hong, Quinn and Luding 2001; Breu et al. 2003).
  Doubling the depth calms the bed (lift-off at 36-44 degrees and landing at
  44-48, against 52-72 and 50-54 at Gamma 3), and the rolls then carry
  the bead up.
- **5 Hz rather than 7 Hz.** At Gamma 3 and 7 Hz the deep bed's rolls are
  +1.4 / -5.4 and the bead takes 24-37 s to reach 12 cm, too slow for a
  visitor. At 5 Hz (the same Gamma, 1.4x the shaking speed A w) it takes
  4-8 s.
- **A light big bead is not the answer.** A hollow ball (0.3 g/cm^3) rises in
  seconds even in the shallow bed, but just as fast between flat walls with
  reversed rolls: that is density segregation, not the convective effect.
- **Bullet can't run real glass at all.** With bead-bead restitution 0.95 the
  unshaken bed boils (kinetic energy 10^6-10^7 times the reference's) at every
  step rate up to 38400/s, with 100 iterations, and with Bullet's restitution
  threshold raised to 5 cm/s, set through gdb in the real binary. A
  threshold of 20 cm/s or more calms it, but that switches off the bounce of
  most collisions in the shaken bed. No C++ binding of a solver parameter
  fixes this. At low bounce (e 0.1), Bullet at 9600 steps/s does reproduce
  the reference with glass friction and glued walls.
- **The reference model can run it live.** At 0.63 GPa and NS 40 it gives
  the same rise (4-7 s to 12 cm, same plateau) and rolls about 10% faster.
  That costs 3.6 CPU-s per simulated second for the 281-bead box: real time needs
  3.6 cores (or a 3.6x faster loop); 1/4 slow motion fits on one core.
- **Recommendation:** build it as a new real-glass box, run by the reference
  model (a `DemBed` hook), at 1/4 speed to start with. Keep the existing
  boxes, with the README saying their materials are not glass (§6).

## 1. What laboratories do

| source | walls | grains, cell | what it says (read 17 Oct 2026 unless marked) |
|---|---|---|---|
| Knight, Jaeger and Nagel, PRL 70, 3728 (1993) | (abstract only) | glass bead in a vibrated cylinder | convection "rising in the middle and falling in a thin stream along the walls"; beads wider than the stream are trapped at the top. Outward-sloping walls reverse the rolls and the intruder sinks (via Kudrolli's review and Wikipedia) |
| Kudrolli, arXiv:cond-mat/0402205 (review; Rep. Prog. Phys. 67, 209 (2004), from memory) | MRI experiments (its refs. 33 and 65; Ehrichs et al. 1995 and Knight et al. 1996, from memory) glued a layer of the same grains (poppy seeds) to the walls "to obtain a rough boundary condition" | | frictional interaction with the side walls sets up convection; "when convection was absent (by decreasing friction at the side walls)" the particles stayed put |
| Hejmady et al., arXiv:1111.4484 | P-100 sandpaper on the narrow side walls | mustard seeds 1.5-2 mm, acrylic quasi-2-D cell 13 x 25 cm, gap 6 mm; acrylic disc intruder 1.7 cm, density ratio 0.3-2.3; 20-50 Hz, Gamma 2.5-25 | "For smooth walls ... the convection patterns were irreproducible and often the system would jam"; rise time tau = 13000 cm^2/s (v - v_c)^-2, v_c 15-18 cm/s, independent of density |
| Garcimartín et al., arXiv:cond-mat/0102015; Pastor et al., arXiv:cond-mat/0402040 | polycarbonate or glass cylinder, untreated | glass beads 0.5 mm, 110 Hz | downward flow at the wall, attributed to wall friction |
| Talbot and Viot, arXiv:cond-mat/0111237 (simulating Wildman et al.'s glass beads) | wall restitution 0.68 vs 1.0 | glass beads e = 0.91 | with elastic walls the roll is about 10x weaker and reversed |
| Eshuis et al., arXiv:physics/0608283 | perspex quasi-2-D, 5 grains deep | glass 1 mm, e about 0.95 | rolls start near a side wall, from "the friction with the walls"; regimes set by S = (A w)^2 / (g d) and the number of layers |
| Breu et al., PRL 90, 014302 (2003) | perspex cylinder | glass and other spheres 2-22 mm, 3-D | intruders rise when (diameter ratio) < 1 / (density ratio), else sink, in 82% of 178 pairs; the crossover depends on the driving |
| Hong, Quinn and Luding, PRL 86, 3423 (2001), arXiv:cond-mat/0010459 | (simulation) | e = 0.9999 | heavy large grains "condense" at the bottom of a fluidised bed: the reverse Brazil-nut effect |
| Gallas et al. 1992; Lee 1993 (via FINDINGS §8) | | 2-D MD | roll direction depends on wall friction; convection needs wall friction above a threshold |
| Knight et al., PRE 54, 5726 (1996) | not read (the APS page could not be fetched) | | |

So the laboratory recipes for rough walls are a glued layer of the bed's own
grains and sandpaper. Both are modelled below.

**Glass values used** (FINDINGS §6, Cornell impact table, Foerster et al.,
Phys. Fluids 6, 1108 (1994)): bead-bead e = 0.95, mu = 0.1 (0.048-0.18
measured); glued glass beads the same. Young's modulus 63 GPa and Poisson 0.22
(from memory; 6.3 GPa used for the survey, as in FINDINGS, and checked against
63 GPa below). Rolling resistance of glass on glass: no measured value found;
DEM calibrations use a dimensionless 0.001-0.01 (from memory), and 0.01 is
tested below. Glass on sandpaper: mu 0.8 assumed (from memory, typical of
0.5-1); Hejmady's grit, P-100, is about 0.16 mm and P60 about 0.27 mm (FEPA
sizes, from memory).

## 2. The rough walls in the reference

`bead-bed.c` now takes (all off by default; the default runs are bit-for-bit
the same as before, checked on a 4 s run):

- `ROUGH=1`: the side walls lined with fixed glued spheres of radius `RG`,
  centres `SG` apart along the wall, embedded `GEMB` of their diameter (0.5:
  half-embedded, centres on the wall's face), jittered by up to `GJIT`/2 of
  `SG` along and of `RG` into the wall (a fixed hashed pattern), with friction
  `MUG` and restitution `EG` against a bead; the flat face behind keeps `MUW`.
  `ROUGHF=1` lines the floor too. They move with the box. A bead-glued contact
  is the full Hertz-Mindlin contact with m_eff = the bead's mass and R_eff =
  r RG / (r + RG). The beads are poured inside the lining.
- `RHOB` (big bead's density), `RB`, `W` (box width), `N`, `GAMMA`, `F` as
  design variables.
- `ETH`/`ELOW`: Bullet's restitution threshold emulated (a contact closing
  slower than `ETH` at first touch gets `ELOW`), planar path only. Built,
  not validated and not used: Bullet's problem turned out not to be the
  threshold (§4).
- Measured besides the old outputs: `up20`, the fraction of the last 20 s
  the special bead spends in the bed's upper half; `top20`, at the top;
  `h20`, its mean height (0 bottom, 1 top, the top as the lua defines it);
  `hc20`, its centre's height over twice the bed's centre of mass. That last
  one is not thrown by the few beads that fly high off a lively bed: a bead
  resting on the floor gives about 0.15-0.35, one at the surface about 1.

**Validation** (the same tests FINDINGS §3 applied to the other contacts;
Hertz-Mindlin, 6.3 GPa, NS 80):

- `TEST=gdrop`, a bead closing head-on on a glued sphere, no gravity:
  - RG 0.5: e = 0.9500-0.9502 from 1 to 200 cm/s; contact time 262 to 90.5
    us, matching Hertz's 2.868 (m^2 / (R E*^2 v))^(1/5) to 1%; no sideways
    drift.
  - RG 0.02 (grit): e = 0.950 up to 20 cm/s. At 67 and 200 cm/s it is 0.92
    and 0.91 with a shorter contact, because the overlap (about 0.01 cm)
    reaches half the grit radius and the bead touches the neighbouring grits:
    a real multi-grit contact, outside Hertz's small-strain range. At 63 GPa
    the overlap is 2.5x smaller.
  - EG 0.5: e = 0.501.
- `TEST=ghollow`, a bead seated in the hollow between two glued spheres, then
  gravity tilted along the surface:
  - Free to spin, it must roll out at alpha = asin(SG / 2 / (r + RG)): the two
    tangential forces must cancel in torque, which leaves them only a force
    along the hollow's axis, while mu < cot alpha.
  - With its spin locked it must hold until alpha + atan(mu).
  - Tested on the floor (RG 0.5, SG 1.0: alpha 30 deg; RG 0.25, SG 0.6:
    23.6 deg; mu 0.1 and 0.3) and on the left and right walls (`TW=0, 1`):
    held at 0.90 and 0.98 of the critical angle and out at 1.02 and 1.10, in
    all 32 cases.
  - The seat height matched the geometry to 2e-5 cm, which is the Hertz
    compression.
  - On P60 grit (RG 0.0135, SG 0.03, mu 0.8) alpha is only 1.7 deg. The
    bead held at 0.9 alpha and came out at 0.98 alpha (the slow tilt's
    dynamics, at a 0.07 deg margin). Fine grit gives a rolling bead almost
    no geometric hold, so sandpaper acts on beads through its sliding
    friction alone.

## 3. The survey

Middle box (140 beads of 0.95-1.05 cm, 15 cm wide, big bead 3 cm at the
bottom), Hertz-Mindlin, real glass: e 0.95, mu 0.1 bead-bead and on every
wall unless stated, YM 6.3 GPa, NS 80, 60 s. The rise in the middle (|x| <
3 cm) and at the walls (|x| > 5 cm) is averaged from 5 to 60 s, in mm/s, and
"+/-" is the spread between pours. Seeds are 7 and 8 unless marked; the
lift-off is given in degrees for each seed. The bead "at top" times are by
seed, with ">60" meaning it never got there.

**3.1 Wall type (Gamma 3, 7 Hz)**

| walls | middle / walls | big bead at top | h20 | lift-off / landed |
|---|---|---|---|---|
| flat glass, mu 0.1 | -3.0 +/- 0.5 / +3.8 +/- 0.7 (reversed) | >60, >60 | 0.16, 0.17 | 66/54 |
| glued glass beads RG 0.5, SG 1.0 (touching) | **+1.5 +/- 0.3 / -6.0 +/- 0.4** | >60, >60 | 0.17, 0.18 | 56/52 |
| glued glass beads RG 0.25, SG 0.5 | -1.7 +/- 0.9 / +0.1 +/- 0.7 | >60, >60 | 0.16, 0.17 | 62-64/52-54 |
| P60 sandpaper: mu 0.8 + grit RG 0.0135, SG 0.03, jitter 0.5 | -1.2 +/- 0.1 / -0.6 +/- 0.0 | >60, >60 | 0.17, 0.17 | 58-62/52 |
| flat, mu 0.8 | -0.7 +/- 0.1 / +0.4 +/- 1.1 | >60, >60 | 0.17, 0.16 | 60-72/52-54 |

Only the bead-sized lining gives clear normal rolls; it holds the wall layer
back geometrically, through the bead's spin, rather than through friction.
The FINDINGS run "set (b), mu_w 0.8, seed 7: 0.1 / -1.7" is consistent with
the flat-0.8 row's scatter.

**3.2 Design variables, glued-bead walls (RG 0.5, SG 1.0)**

| design | middle / walls | big bead at top | hc20 (seed 8) | lift-off / landed |
|---|---|---|---|---|
| Gamma 3, 7 Hz (base) | +1.5 +/- 0.3 / -6.0 +/- 0.4 | >60, >60 | - | 56/52 |
| Gamma 2 | -0.4 +/- 0.1 / +0.1 +/- 0.3 | >60, >60 | 0.15 | 44-48/34-36 |
| Gamma 2.5 | -0.1 +/- 0.8 / -2.4 +/- 0.3 | >60, >60 | 0.23 | 50-52/44-46 |
| Gamma 4 | +1.7 +/- 0.4 / -8.5 +/- 0.8 | >60, >60 | - | 62/60 |
| Gamma 5 | +4.7 +/- 2.1 / -11.2 +/- 2.8 | >60, >60 | - | 70-72/64-66 |
| Gamma 3, 5 Hz (A 29.8 mm) | +4.1 +/- 1.4 / -9.5 +/- 1.5 | >60, >60 | - | 52-56/50 |
| Gamma 3, 10 Hz (A 7.5 mm) | -1.3 +/- 0.2 / -0.5 +/- 0.0 | >60, >60 | - | 58-60/54 |
| floor lined too | +3.8 +/- 0.9 / -9.0 +/- 0.7 | >60, >60 | 0.36 | 48-56/52 |
| big bead 2 cm (RB 1.0) | +2.8 +/- 0.6 / -7.6 +/- 0.1 | >60, >60 | 0.34 | 54-60/52 |
| box 10 cm wide, 90 beads | +2.3 +/- 0.2 / -4.8 +/- 0.5 | >60, >60 | 0.31 | 46-52/50 |
| 90 beads (shallower) | +0.3 +/- 0.1 / -1.7 +/- 0.9 | >60, >60 | 0.27 | 66-72/54 |
| 140 beads, floor lined, 180 s | +3.2 / -8.6 (seed 7) | not in 180 s; centre 5.2-7.5 cm throughout | 0.36 | 48/52 |
| glass rolling resistance 0.01 R Fn (seed 7) | +2.1 / -7.6 | >60 | 0.26 | 58/54 |

Normal rolls get stronger with the shaking speed A w (Gamma 3 at 5 Hz,
Gamma 5) and with a lined floor, much as Hejmady and Yamada-Katsuragi find for
v = A w. But the glass big bead stays at the bottom in every design.

**3.3 Why the solid bead stays down in the shallow bed: restitution, friction, and the intruder's density**
(glued-bead walls, Gamma 3, 7 Hz)

| case | middle / walls | big bead at top | h20 | hc20 | up20 |
|---|---|---|---|---|---|
| glass big bead (2.5 g/cm^3), e 0.95 | +1.5 / -6.0 | >60, >60 | 0.17, 0.18 | (about 0.15-0.3) | 0, 0 |
| e 0.5 (not glass) | +1.8 +/- 0.2 / -8.3 +/- 0.9 | >60, >60 | 0.38, 0.35 | 0.39, 0.36 | 0.13, 0.11 |
| e 0.1 (not glass) | +2.4 +/- 0.6 / -8.5 +/- 1.1 | >60, >60 | 0.36, 0.39 | 0.37, 0.39 | 0.13, 0.14 |
| acrylic big bead, 1.19 g/cm^3 (seed 7) | +2.5 / -6.2 | >60 | 0.26 | - | 0.01 |
| polypropylene, 0.9 g/cm^3 | +3.4 +/- 0.3 / -8.3 +/- 0.5 | >60, >60 | 0.32, 0.34 | 0.40, 0.43 | 0.04, 0 |
| 0.6 g/cm^3 (wood, from memory 0.5-0.75) | +3.2 +/- 0.3 / -7.4 +/- 0.7 | >60, 28.8 | 0.57, 0.59 | 0.66, 0.69 | 0.67, 0.83 |
| **hollow, 0.3 g/cm^3, seeds 1, 2, 7, 8** | **+3.2 +/- 0.9 / -8.1 +/- 1.2** | **5.7, 6.8, 10.5, 5.6** | 0.86-0.91 | 0.93-0.97 | **1.00 (all)** |
| hollow, **flat glass walls**, seeds 1, 2, 7, 8 | -1.0 +/- 0.4 / +1.4 +/- 0.5 (reversed) | 6.6, 7.8, 4.5, 5.8 | 0.88-0.91 | 0.94-0.97 | 1.00 (all) |
| hollow, e 0.1 | +4.0 +/- 1.2 / -9.3 +/- 0.8 | 6.6, 6.2 | - | 1.00, 0.99 | 1.00, 1.00 |

- The outcome is set by the intruder's density. It crosses over between 0.6
  and 0.3 g/cm^3 (density ratio 0.24 to 0.12, size ratio 3). Breu et al.'s
  3-D rule (rise if 3 < 1 / ratio, i.e. ratio < 0.33) places the crossover
  in roughly that range.
- The walls don't matter for the light ball: it rises as fast against reversed
  rolls. So the demonstrable rise is density segregation in a fluidised
  bed, not the convective Brazil-nut effect.
- The bed of real glass at Gamma 3 is lively. The top tenth of the beads
  stands at 18-19.5 cm against about 10 cm packed (logs of the acrylic and
  polypropylene runs), and S = (A w)^2 / (g d) = 4.6 is in Eshuis et al.'s
  range for convection and the Leidenfrost state. The bed lands late
  (52-54 degrees).
- Low restitution alone doesn't bring the solid bead up (e 0.1: 0.37 of the
  depth). The exhibit's bead-bead friction of 0.64, against glass's 0.1, is
  the other half of why the exhibit works.

**3.4 The hollow ball's stiffness and step (shallow bed, glued walls)**

| YM, NS | middle / walls | at top (s) | hc20 | CPU s per sim s |
|---|---|---|---|---|
| 63 GPa (real glass), NS 80 | +2.9 +/- 0.1 / -7.7 +/- 0.6 | 5.0, 10.9 | 0.99, 0.90 | 17.6 |
| 6.3 GPa, NS 80 (4 seeds) | +3.2 +/- 0.9 / -8.1 +/- 1.2 | 5.6-10.5 | 0.93-0.97 | 7.2 |
| 6.3 GPa, NS 40 | +3.7 +/- 0.1 / -8.7 +/- 0.0 | 10.9, 7.9 | 0.96, 0.99 | 3.5 |
| 0.63 GPa, NS 40 (4 seeds) | +4.1 +/- 0.4 / -9.3 +/- 0.6 | 5.8, 3.1, 6.6, 4.9 | 0.90-0.99 | 1.5 |

(CPU per simulated second: -O3 -march=native on a shared 2-core Xeon at
2.1 GHz with 2-4 jobs running; CPU time, not wall time.)

**3.5 The deep bed: the design**

Glued-bead walls (RG 0.5, SG 1.0), solid glass big bead, real glass
everywhere, 90 s. t10 and t12 are the first times the big bead's centre
reaches 10 and 12 cm (it rests at 1.5 cm; the bed is 20.2 cm deep packed).
"Late" is its centre's mean and minimum over the last 20 s. up20 is the
fraction of the last 20 s in the bed's upper half as the lua defines it; the
"top" there is the mean of the highest tenth, about 24 cm at 7 Hz and 28 cm
at 5 Hz, because the shaken surface is lively. The lua's "reaches the top"
criterion is never met in the deep bed, for the same reason.

| design | YM, NS, seeds | middle / walls | t10 (s) | t12 (s) | late mean (min), cm | up20 | lift-off / landed | CPU s/s |
|---|---|---|---|---|---|---|---|---|
| **280 beads, 5 Hz, Gamma 3** | 6.3 GPa, 80; 1, 2, 7, 8 | **+5.1 +/- 0.1 / -13.9 +/- 0.5** | **5, 4, 3, 3** | **6, 8, 8, 7** | 14.6 (10.9), 15.6 (11.8), 15.1 (11.4), 14.5 (10.3) | 0.74, 0.90, 0.83, 0.69 | 38-42/46 | 16.8 |
| same | 63 GPa (glass), 80; 7 (45 s) | +4.9 / -10.1 | 4 | 7 | 15.5 (11.9) | 0.90 | 40/48 | 40.8 |
| same | 0.63 GPa, 40; 1, 2, 7, 8 | +5.8 +/- 0.5 / -15.0 +/- 0.4 | 6, 4, 4, 2 | 7, 5, 5, 4 | 15.5 (11.8), 15.4 (11.3), 15.2 (10.4), 14.9 (10.6) | 0.86, 0.84, 0.81, 0.77 | 36-42/46 | 3.6 |
| same, **flat glass walls** (control) | 6.3 GPa, 80; 7 | -1.1 / +2.0 (reversed) | 49 | 71 | 9.7 (6.6) | 0.00 | 42/44 | 14.0 |
| same, **flat glass walls** (control) | 0.63 GPa, 40; 1, 2, 7, 8 | -1.8 +/- 0.4 / +2.6 +/- 0.7 (reversed) | 0, 4, 20, 22 | 5, 9, 29, 24 | 8.6 (5.7), 9.0 (5.1), 7.1 (3.3), 9.5 (5.9) | 0, 0, 0, 0 | 42-44/44-46 | 3.0 |
| 280 beads, 7 Hz, Gamma 3 | 6.3 GPa, 80; 1, 2, 7, 8 | +1.4 +/- 0.3 / -5.4 +/- 0.4 | 17, 21, 27, 18 | 35, 31, 37, 24 | 14.3 (12.0), 13.5 (11.2), 13.5 (11.4), 13.6 (10.4) | 1.00, 0.96, 0.97, 0.90 | 38-44/46 | 16.7 |
| same | 0.63 GPa, 40; 1, 2, 7, 8 | +2.1 +/- 0.5 / -6.3 +/- 0.4 | 15, 6, 15, 32 | 20, 17, 24, 45 | 13.5, 13.3, 12.6, 13.2 | 0.90, 0.91, 0.56, 0.77 | 40-44/44-46 | 3.4 |
| 280 beads, 7 Hz, **flat glass walls** | 6.3 GPa, 80; 7 | -1.0 / +1.9 (reversed) | 22 | >90 | 4.4 (2.4) | 0.00 | 48/46 | 15.0 |
| 10 cm box, 190 beads (as deep), 7 Hz | 6.3 GPa, 80; 7, 8 | +0.9 +/- 0.1 / -1.6 +/- 0.2 | 70, 21 | 74, 25 | 13.4 (8.7), 17.1 (14.1) | 0.62, 1.00 | 38-40/44-46 | 11.4 |

- **Every pour rises, and quickly.** At 5 Hz the solid glass bead is up in
  4-8 s in all 9 pours, at every stiffness, including real glass's 63 GPa.
  It then stays in the upper part of the bed, wandering between about 10 and
  18 cm (centre). The bed's upper 4-5 cm stays lively and the bead does not
  enter it; visitors see it rise from the floor to the upper part of the bed
  and stay there.
- **The rough walls are what does it.** With flat glass walls the deep bed's
  rolls reverse. The bead is thrown about in the lower half (late mean
  7-10 cm against 14.5-15.6; up20 0 against 0.69-0.90) and passes 12 cm
  only in brief excursions. So t12 alone doesn't tell the two apart; the
  late height and up20 do.
- **Why depth matters:** a deeper bed dissipates the bounce of real glass in
  more collisions. It lands and leaves the floor at about 40-46 degrees, as
  the exhibit's dead beads do, instead of flying (52-72 degrees).
- **Stiffness:** from 0.63 to 63 GPa the rise times and the plateau don't
  change beyond the scatter; the rolls run 8-14% faster at 0.63 GPa than at
  6.3 GPa, and at 63 GPa they agree in the middle (4.9 against 5.1) but are
  slower at the walls (-10.1 against -13.9, one seed).

**3.6 The right box (coloured bead, no big bead), shallow, glued walls,
Gamma 3, 7 Hz** (seeds 7, 8): rolls +3.6 +/- 0.3 / -8.0 +/- 0.1. The
coloured bead reaches the top at 24.4 and 13.8 s and goes round once in the
minute (trips 1, 1). Going up it was 2.8 and 3.3 cm from the middle, going
down 2.6 and 3.9 cm.

## 4. Bullet (bpp, Bullet 3.24)

**What bpp exposes.** To Lua, `v:setTau`, `setErp`, `setErp2`, `setCfm` and
`setSolverIterations` (src/viewer.cpp, binding at lines 320-325, setters at
781 and 968-981), and per body `setFriction` and `setRestitution`
(lua_bullet_3.cpp 282-285), combined by product. `eachContact` reads
contacts but can't change them. Nothing reaches
`btContactSolverInfo::m_restitutionVelocityThreshold` (default 0.2, here
cm/s), `m_splitImpulse*`, `m_warmstartingFactor` or `m_solverMode`.

**Testing the threshold without touching src/.** In the release binary, the
world's solver info sits at world+0x98: `Viewer::setTau` stores at 0x98,
`setCfm` at 0xcc, and `setSolverIterations` at 0xac. That puts
m_restitutionVelocityThreshold at world+0x108 and m_warmstartingFactor at
world+0xe8. `bn-glass/bullet/rvt.sh` sets them through gdb at the script's
own `setSolverIterations` call, and reads back the default 0.2. The scene
is `bn-glass/bullet/glass-bn.lua`, a scratch copy of the exhibit:
- only the boxes named in BN_BOXES are built, while the other boxes still
  draw their random numbers, so each pour is the exhibit's;
- side walls can be lined with glued spheres, as children of the box
  compound;
- it takes a big-bead density and the box's own restitution;
- it prints a settle report 1/60 s before the shaking, and RESULTB at 60 s.

**The unshaken bed after 0.5 s (middle box, seed 7, bead-bead mu 0.1).** The
measure is kinetic energy per bead over m g d, with the bed's top in cm (about
9.8 packed). The reference gives 5e-8 at e 0.95.

| Bullet case | KE / (m g d) | top |
|---|---|---|
| e 0.1, 2400/s | 1.3e-5 | 9.74 |
| e 0.5 | 1.4e-4 | 9.78 |
| e 0.8 | 5.9e-3 | 9.59 |
| e 0.95, 2400/s | 0.38 | 12.04 |
| e 0.95, 9600/s | 0.28 | 11.32 |
| e 0.95, 38400/s | 0.18 | 10.68 |
| e 0.95, 9600/s, 100 iterations, threshold 2 | 0.29 | 11.01 |
| e 0.95, threshold 2 / 5 cm/s (2400/s) | 0.54 / 0.54 | 11.8 / 11.6 |
| e 0.95, threshold 2 / 5 (9600/s) | 0.27 / 0.24 | 11.2 / 11.0 |
| e 0.95, threshold 2 / 5 (38400/s) | 0.22 / 0.17 | 10.8 / 11.0 |
| e 0.95, threshold 20 cm/s | 9.4e-3 | 9.83 |
| e 0.95, threshold 1000 (no bounce) | 6.3e-6 | 9.77 |
| e 0.95, warm-starting factor 0 | 0.38 (unchanged) | 12.04 |
| bead-bead 0.95, box (walls, floor) 0 | 0.22 | 10.94 |
| bead-bead 0.1, box 0.95 | 3.0e-6 | 9.73 |

- **The pump is bead-bead restitution in a packed bed.** Bullet sets each
  contact's target bounce from the closing speed before the solve,
  `restitutionCurve()` in btSequentialImpulseConstraintSolver.cpp. In a
  packed column the sequential impulses leave closing speeds that it then
  bounces back at 95%, every step.
- **Finer steps and more iterations reduce the pump only slowly.** At
  38400/s the bed is still boiling.
- **Warm-starting plays no part.** A factor of 0 changes nothing, consistent
  with the sphere-sphere algorithm rebuilding its manifold every step
  (CLEAR_MANIFOLD, from memory).
- **A threshold below 20 cm/s doesn't help.** At 20 cm/s and above it would
  remove the bounce from most collisions in the shaken bed (the bed lands at
  about 20-25 cm/s: vdown19).

**So no binding makes Bullet faithful to real glass here.** A binding
`v:setRestitutionVelocityThreshold(x)`, setting
`dynamicsWorld->getSolverInfo().m_restitutionVelocityThreshold`, would be
three lines next to `setCfm` in viewer.cpp/.h. It doesn't fix this bed.

**Where Bullet does converge: low bounce, glass friction, glued walls**
(middle box; bead-bead and walls mu 0.1 = 0.3162^2; e 0.1 = 0.3162^2;
RG 0.5, SG 1). The wall column is the wall time for 61 s of simulation, with
3-4 jobs on 2 cores.

| | middle / walls (seeds 7, 8) | big bead at top (s) | hc20 | wall time per 61 s |
|---|---|---|---|---|
| hollow 0.3 g/cm^3, Bullet 2400/s | +5.9, +7.2 / -13.0, -14.4 | 3.9, 5.5 | 1.00, 1.00 | 54 s |
| ditto 4800/s | +5.0, +5.3 / -11.6, -12.8 | 5.9, 8.0 | 1.00, 1.00 | 96 s |
| ditto 9600/s | +5.0, +5.5 / -11.3, -11.6 | 7.9, 13.7 | 0.99, 1.00 | 179 s |
| ditto, reference (e 0.1, 6.3 GPa, NS 80) | +4.0 +/- 1.2 / -9.3 +/- 0.8 | 6.6, 6.2 | 1.00, 0.99 | - |
| glass 2.5 g/cm^3, Bullet 2400/s | +6.2, +5.4 / -13.4, -12.4 | >60, >60 | 0.49, 0.47 | 37 s |
| ditto 9600/s | +3.0, +1.9 / -8.4, -7.7 | >60, >60 | 0.36, 0.38 | 116 s |
| ditto, reference | +2.4 +/- 0.6 / -8.5 +/- 1.1 | >60, >60 | 0.37, 0.39 | - |

- **Bullet converges by 4800-9600 steps/s.** At 2400 (the exhibit's) its rolls
  are 25% (hollow) to 140% (glass bead) faster, and it lifts the glass bead
  halfway.
- **Converged, it agrees with the Hertz-Mindlin reference.** For the glass
  bead it matches within the scatter; for the hollow ball the rolls run
  about 25% faster, the rigid-contact excess FINDINGS §4.3 found.
- **So Bullet could show glued-bead walls faithfully, but only with dead
  beads (e 0.1), not glass.** It costs 9600 steps/s, about 1.5-3x real time
  for one box on this machine.

## 5. Running the reference live

The cost is about 7.4 us per step per 141-bead box (FINDINGS §10), and it
scales with the number of beads. At 60 fps a frame has 16.7 ms: 1 CPU-s per
simulated second on one core.

| setting | CPU s per sim s | one box, real time | one box, 1/4 slow motion |
|---|---|---|---|
| deep design, 63 GPa, NS 80 | 40.8 | 41 cores | 10 cores |
| deep design, 6.3 GPa, NS 80 | 16.8 | 17 cores | 4.2 cores |
| deep design, 0.63 GPa, NS 40 (same results, §3.5) | 3.6 | 3.6 cores | 0.9 core: fits |
| shallow box, 0.63 GPa, NS 40 (hollow ball, §3.4) | 1.5 | 1.5 cores | 0.4 core |

- **Real time needs about 3.6x more speed.** The loop is plain C with no
  SIMD. A float structure-of-arrays rewrite with SIMD and two threads (one
  per half of the cell list) might get there; that is not tried.
- **1/4 slow motion fits now on one core.** The exhibit already has a slow
  motion key (Z).
- **Softening is acceptable here.** At 0.63 GPa (1/100 of glass) the peak
  overlap is 0.08-0.12 R_eff in the deep bed, against 0.019 at 63 GPa. The
  rise and the plateau are unchanged and the rolls run about 10% faster; quote
  the 6.3-63 GPa numbers in any text.
- **The hook** would be the `DemBed` class sketched in FINDINGS §10:
  - its parameters gain the rough-wall keys (`ROUGH`, `RG`, `SG`) and `N`;
  - the glued spheres are drawn as fixed display spheres that move with the
    box;
  - `step()` is called from `v:preSim`, `sync()` writes the bead
    transforms.

## 6. Recommendation

1. **A faithful real-glass Brazil-nut box exists.** Build it as described
   below, all real materials and buildable.
   - **Box:** 15 cm wide inside.
   - **Beads:** 280 soda-lime glass beads, 0.95-1.05 cm (e 0.95, mu 0.1,
     2.5 g/cm^3), 20 cm deep.
   - **Walls:** both side walls lined with a row of the same 1-cm glass
     beads, glued touching and half-embedded (in an experiment, epoxy).
   - **Big bead:** solid glass, 3 cm (27 times a small bead's mass).
   - **Shaking:** 5 Hz, Gamma 3: amplitude 29.8 mm, peak speed 94 cm/s.

   What a visitor sees: normal rolls (+5 mm/s up the middle, -14 down the
   walls), and the heavy big bead rising about 10 cm from the floor in 4-8 s
   and staying in the upper part of the bed.
2. **Pair it with a flat-walled twin** (same beads, plain glass walls) as the
   control: rolls reversed, big bead stays down. This shows what the
   laboratories found, that the walls drive it. It doubles the cost.
3. **Run it on the reference model,** not Bullet, which can't run e 0.95
   (§4).
   - Use a `DemBed` C++ hook at 0.63 GPa and NS 40.
   - Start at 1/4 speed (which fits one core per box), and aim for real time
     after optimising the loop by about 3.6x.
   - The rise at 1/4 speed takes 16-32 s of a visitor's time, which is
     still within the minute.
4. **The existing exhibit:**
   - keep it;
   - say in the README that its materials (mu 0.64 / 0.8, e 0.01) are not
     glass, and that with real glass the shallow bed's rolls reverse and the
     big bead stays down;
   - point to the real-glass box as the faithful version.

## 7. Still open

- **Real panes.** The reference has no front and back panes, no air and no
  pane friction. In a real one-bead-thick cell these add dissipation.
  FINDINGS found that panes don't change the rolls in set (b). Their effect
  on the deep design is untested, and would likely calm the bed further.
- **Glued-bead restitution:** an epoxy-backed glued bead probably bounces
  less than 0.95. EG was not varied in the bed.
- **Measurements not found:** glass-on-sandpaper friction, glass's rolling
  resistance (0.01 R Fn changed nothing in one run), and glass-on-glass
  sliding friction beyond the Cornell 0.05-0.18.
- **Spread:** the deep design has 4 seeds at 6.3 and 0.63 GPa, and one 45 s
  run at 63 GPa. The design space around it (Gamma 2.5-4 at 5 Hz, 4-6 Hz,
  220-350 beads, other widths) is unexplored. The 7 Hz deep bed works but
  is slow (24-37 s).
- **Experiment:** no experiment with 1-cm glass beads in a one-bead-thick
  cell was found to compare with. Hejmady's rise-time law (tau = 13000
  cm^2/s (v - v_c)^-2 with v_c about 16 cm/s) predicts 2.2 s at 5 Hz
  (v = 93.6 cm/s) and 5.0 s at 7 Hz (v = 66.9), a ratio of 2.3. The
  reference's ratio of t12 between the two (about 4.5) is steeper. Their grains, cell and rise
  height differ.
- **Knight et al. (1996)** was not read; the claims about it rest on
  secondary sources.

## 8. Files and how to run

- `bead-bed.c`: the reference, with the new keys `ROUGH ROUGHF RG SG GEMB
  GJIT MUG EG RHOB RB W ETH ELOW` and `TEST=gdrop|ghollow` (with `TW=0|1|2`).
- Scratch, not in the repo:
  `/tmp/claude-0/-home-claude/27345db2-594b-591b-b841-2c308bf66463/scratchpad/bn-glass/`.
  It holds the runs (`runs/*.out`, logs), job files `jobs*.txt`, `agg.py`,
  `tup.py`, and `bullet/` (`glass-bn.lua`, `rvt.sh`, `rvtw.sh`, `runb.sh`, `out/`).

```
gcc -O2 -o bead-bed bead-bed.c -lm        # (survey runs used -O3 -march=native)
G="MODEL=1 YM=6.3e9 NS=80 E=0.95 MUB=0.1 MUW=0.1"
R="ROUGH=1 RG=0.5 SG=1.0 MUG=0.1"
./bead-bed BOX=middle $G $R N=280 F=5 TEND=90.05 CONVEND=90 SEED=7 LOG=d.csv   # the design
./bead-bed BOX=middle $G N=280 F=5 TEND=90.05 CONVEND=90 SEED=7                # its flat-walled control
./bead-bed BOX=middle MODEL=1 YM=6.3e8 NS=40 E=0.95 MUB=0.1 MUW=0.1 $R N=280 F=5 SEED=7   # the live setting
./bead-bed BOX=middle $G $R SEED=7                    # the exhibit's shallow bed: solid bead stays down
./bead-bed TEST=ghollow ROUGH=1 ROUGHF=1 MODEL=1 YM=6.3e9 E=0.95 NS=80 RG=0.5 SG=1.0 MUW=0.1 TW=0
./bead-bed TEST=gdrop ROUGH=1 ROUGHF=1 MODEL=1 YM=6.3e9 E=0.95 NS=80 RG=0.5 SG=1.0
```
