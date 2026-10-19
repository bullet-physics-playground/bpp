# Ch. 2 — NetLogo and physics: the three verification models

`BOOK.md` entries 2.1–2.3 (PDF 58–85, `book/ch02.md`). The book's three
two-body models, `spring1D`, `spring2D` and `solar_system`, on the book's own
integrator (`lib/monitors.lua`: friction first, every force from one snapshot,
semi-implicit Euler, a chosen Δt). They are the integrator and monitor tests
every later port stands on.

| File | What |
| --- | --- |
| `models.lua` | The three models as plain Lua, with the book's slider defaults |
| `Tetrahedron.lua` | Ours: four masses (1–4) on six springs, spinning about a chosen principal axis; about the middle one it flips over and over (the tennis-racket effect) |
| `Planets.lua` | Ours: a sun and 1–6 planets on elliptical, slightly tilted orbits, solar_system's law without caps; spacing and Δt follow two rules that keep it stable |
| `SpringLattice.lua` | Ours: a cube of 8, 27 or 64 masses on springs (edges and face diagonals), springs coloured by strain (blue compressed, white at rest, red stretched) and masses by layer; spins and rings, settles with friction |
| `Spring3D.lua` | Ours, not in the book: spring2D with a third axis, seen at an angle. Each particle starts in a random direction on the sphere; Angular_Motion_Z adds z velocity. The status line shows \|L\| and the tilt of L from its start instead of L |
| `Spring1D.lua`, `Spring2D.lua`, `SolarSystem.lua` | BPP scenes with the NetLogo sliders (same names; the solar system's caps get tick boxes instead of the book's huge "off" values), seen from above; the status line shows t, separation, \|P\|, L, KE, PE and E. They run as soon as they load; R resets, S stops and restarts |
| `scene.lua` | Their shared drawing and running |
| `../checks/ch02.lua` | The book's results and our 3D models as 47 numeric checks, about 8 s |

## The book's results and ours

All 47 checks pass (`lua5.1 checks/ch02.lua`).

**2.1 spring1D** (k 10, D 50, Δt 0.001)
- Momentum stays exactly 0 (|P| = 0, not just small).
- The separation oscillates symmetrically about D (27.000 to 73.000).
- Energy is constant: no drift (2×10⁻⁵ over 20 time units). Within each
  cycle it swings by 0.45%, as semi-implicit Euler does (about Δt·ω).
- k 1 gives a √10 longer period (1.405 and 4.443), as Hooke's law says.
- Mass ratio 10: the centre of mass sits beside the heavy mass.
- Friction 0.001 drains the energy (2641 to 0.016) and the separation
  settles at D.
- A larger Δt (0.01) gives ten times the swing (4.5%), still with no drift.
- Changing D mid-run moves the energy to a new constant level (2641 to 998).

**2.2 spring2D** (AM 200, mass ratio 10, k 10, D 50, Δt 0.001)
- Linear momentum 0 (3×10⁻¹²); angular momentum constant to 2×10⁻¹⁴.
- Mean separation 77.8, above D; the maximum exceeds 2D = 100 for every seed
  tried (111–118).

**2.3 solar_system** (sun 100 at the origin, planet at 15, G 20)
- **a.** Δt 0.1: AM 15 reaches 87 and AM 10 15 (its start is the far
  point). A lighter sun (95) gives a larger orbit, much more for AM 15
  (87 to 133) than AM 10. Momentum 0, L constant, E without drift; E swings
  16% at the closest approach, where the planet moves 1.5 units a step.
- **b.** Δt 0.1: AM 5 escapes (E goes from −121 to +111); AM 0 is nonsense
  (E from −133 to 448,804).
- **c.** Δt 0.001: AM 5 orbits properly (passes 1.57 from the sun, no
  drift); AM 0 still shoots off left (x = −36,312).
- **d.** Velocity caps: Vmax 12 keeps AM 15 bound with a small momentum
  change (|P| up to 3.0), but the orbit shrinks to nearly circular (15–18
  instead of 15–87), which the book does not describe; the cap cuts the
  starting speed from 15 to 12 (FINDINGS F15). Vmax 9 drops the planet
  into the sun (ends 1.1 away, |P| up to 891). AM 0 with any cap: |P| up to
  1188. Velocity capping fails, as the book concludes.
- **e.** Force cap Fmax 1: every orbit stays bound, with energy and momentum
  conserved; AM 4 precesses 112° per orbit (a rosette); AM 0 swings through
  the sun, 0 to 15.6 away.
- **The peak speeds the book prints, "5.6, 5, 4 and 9" for AM 0, 1, 4, 9,
  are right** (`book/ch02.md` had flagged them as odd): we get 5.50, 4.97,
  4.00, 9.00. For AM 4 and 9 the start is the closest point, so the peak is
  the starting speed; AM 0 falls straight through, and AM 1 nearly does.

## spring3D (ours)

Two bodies on a spring always move in the plane through their centre of mass
perpendicular to L, so in 3D the spinning spring picks a tilted plane at
random and stays in it. `checks/ch02.lua`, 5 seeds × Angular_Motion_Z 0 and
120, 20 time units each: |P| ≤ 4×10⁻¹², |L| constant to 4×10⁻¹⁴, L's
direction to 2×10⁻¹² degrees, the light mass within 3×10⁻¹² of the plane,
energy drift ≤ 0.04%, mean separation 77–88 (above D = 50, as in 2D).

## Where the book is silent: the .nlogo models decide

Checked against `spring1D.nlogo`, `spring2D.nlogo` and `solar_system.nlogo`
(from the book website, 2026-10-18):

- **spring1D's start:** particle 0 (mass 1) moves 1 + random(D/2) right of the
  origin, particle 1 (Mass_Ratio) as far left.
- **spring2D's start:** each particle takes a random heading (0–359°) and
  moves 1 + random(D) from the origin; particle 0 gets vx = Angular_Motion,
  particle 1 −AM/Mass_Ratio. (Our first port guessed "apart along y"; the
  book's results hold either way, FINDINGS F3.)
- **The velocity cap** scales the velocity down to Vmax, keeping its
  direction (`if (v > VMAX) [set vx (VMAX * vx / v) ...]`). Clipping each
  component instead (`speedCapPerAxis`, an experiment) gives the same
  picture: 14.9–18.4 at Vmax 12 (`checks/ch02.lua`).
- **Order of updates:** every particle computes its force (`ask turtles
  [ap]`) before any moves (`ask turtles [move]`), friction first, as ours.
- **The potential with a force cap** matches the capped force, as the model's:
  −G m₁m₂/r outside rc = √(G m₁m₂/Fmax), and Fmax(r − rc) − G m₁m₂/rc inside.
  NetLogo puts the zero at contact instead of at infinity (its PE is ours
  plus 2G m₁m₂/rc), so its energy monitor reads higher by that constant
  (about 89,000 with the cap off at 10⁶); changes in E are the same.
  With Fmax 1 the cap covers r < 44.7, the whole orbit, so the energy monitor
  would be meaningless with the plain −G m₁m₂/r.
- **"Constant energy"** is tested as no drift between the first and last tenth
  of a run, with the swing within a cycle reported separately.
- **The toroidal world** of NetLogo (the D = 500 artefact, Fig. 2.7) does not
  exist in BPP and is not reproduced.

## Truly 3D: three or more bodies (ours)

Two bodies on a spring always move in one plane (spring3D). These three
need three or more bodies, and are 3D in earnest (FINDINGS F57). All three
keep |P| at 0 and L fixed to rounding, and their energy does not drift.

**Tetrahedron** (`Tetrahedron.lua`; masses 1, 2, 3, 4, edges 50, k 10).
Unequal masses make an asymmetric top: principal moments about 4390, 5840
and 7270. Started spinning at 0.5 a few degrees off one principal axis:
about the smallest or largest axis the spin is steady (the axis stays
within 3–4° of L for 48 turns); about the middle axis it flips over
again and again, 0° to 180° and back, 7 times in 48 turns, whatever the
tilt (0.5–5°) or spin (0.3–0.5) or spring constant (10, 40) — the
tennis-racket (Dzhanibekov) effect, in a body that is only springs.
Equal masses would make a spherical top, which never tumbles.

**Planets** (`Planets.lua`; G 20 and sun 100 as in solar_system, no
caps; planets at 15 × 1.8ⁱ⁻¹ on circular starts in planes tilted up to
10°). Light planets (each 1/1000 of the sun, about Jupiter's share) are
stable: every radius within 1–3% for 150 orbits of the outermost planet,
3 seeds, also at 3/1000; the planes' tilts drift slowly as the planets
tug on each other. Each 1/100 of the sun: stable for 30 orbits but radii
swing ±30%, and one of three seeds broke up by 150. Each 3/100, or spaced
only 1.3× apart: a planet is thrown out. What makes a system stable, in
order: light planets, wide spacing, a time step of a few hundred per inner
orbit, the sun given its share of momentum, the right starting speeds, and
no force or velocity cap.

**Elliptical orbits** (F58; `Eccentricity`, default 0.3). Circles were
never the hard part; ellipses are, for two reasons, and the scene applies a
rule for each on every R:
- *Spacing:* an ellipse reaches from a(1 − e) to a(1 + e). Keep the `Gap`
  — the outer orbit's nearest point over the inner one's farthest — at 1.8,
  as for circles; the semi-major axes then grow by 1.8 (1 + e)/(1 − e).
  Every run held at e 0.3–0.7; at Gap 1 (orbits touching) heavy planets
  broke up in 11 of 12 runs.
- *Time step:* the nearest-point pass takes about √(rp³/GM), rp = a(1 − e).
  `Time_Step` is set to give about 50 steps across it (0.026 for circles,
  0.009 at e 0.5, 0.0008 at e 0.9), and `stepsPerFrame` to keep the same
  pace on screen. With 4 steps (e 0.9 at 0.01) the energy swings 88% at
  each pass and the orbit turns.

Lower `Gap` or raise `Time_Step` after R to watch each rule matter.

**Spring lattice** (`SpringLattice.lua`; 3 × 3 × 3 unit masses, spacing
50, k 10; springs coloured by strain, full blue or red at 5%). Springs join every pair closer than 1.5 × 50: the 54 edges and
72 face diagonals (126). Edges alone would let the cube shear flat, as a
truss without braces. Displaced at random by up to 10% and spun, it turns
and rings for ever (strain 5.8% to 4.3% after 30 time units, energy within
3×10⁻⁴); with friction 0.002 it settles into the perfect cube (strain
10⁻⁸). The book's friction slows every velocity, so the spin stops too.
The springs are fixed bonds; the Ch. 3 formations choose their neighbours
by distance instead, the next step toward them in 3D.

**An inclined orbit** (one planet in a tilted plane) is only the same
ellipse tipped over, as spring3D is; tilt matters only between planets,
so it is covered by `Planets.lua`.

## Not done yet

The other 3D variant planned earlier, two planets, is covered by
`Planets.lua`. The drone versions of these models (two drones on a virtual
spring; one drone orbiting under a capped 1/r² law) are dropped (William,
2026-10-18).
