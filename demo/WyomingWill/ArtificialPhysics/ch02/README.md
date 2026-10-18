# Ch. 2 — NetLogo and physics: the three verification models

`BOOK.md` entries 2.1–2.3 (PDF 58–85, `book/ch02.md`). The book's three
two-body models, `spring1D`, `spring2D` and `solar_system`, on the book's own
integrator (`lib/monitors.lua`: friction first, every force from one snapshot,
semi-implicit Euler, a chosen Δt). They are the integrator and monitor tests
every later port stands on.

| File | What |
| --- | --- |
| `models.lua` | The three models as plain Lua, with the book's slider defaults |
| `Spring3D.lua` | Ours, not in the book: spring2D with a third axis, seen at an angle. Each particle starts in a random direction on the sphere; Angular_Motion_Z adds z velocity. The status line shows \|L\| and the tilt of L from its start instead of L |
| `Spring1D.lua`, `Spring2D.lua`, `SolarSystem.lua` | BPP scenes with the NetLogo sliders (same names; the solar system's caps get tick boxes instead of the book's huge "off" values), seen from above; the status line shows t, separation, \|P\|, L, KE, PE and E. They run as soon as they load; R resets, S stops and restarts |
| `scene.lua` | Their shared drawing and running |
| `../checks/ch02.lua` | The book's results as 27 numeric checks, about 2 s |

## The book's results and ours

All 27 checks pass (`lua5.1 checks/ch02.lua`).

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

## Not done yet

★ The drone versions (two drones on a virtual spring; one drone orbiting under
a capped 1/r² law, where the drone's speed limit is a velocity cap), and the
other 3D variants (an inclined orbit, two planets). The off-plane spin is
spring3D.

★ **William liked these (2026-10-18), next for 3D springs.** Two bodies always
stay in one plane, so spring3D looks like spring2D tilted. These need three or
more masses and are truly 3D:
- **A spring tetrahedron:** four masses on six springs, started spinning about
  a tilted axis. It tumbles, wobbles and breathes, with |L| and E constant: a
  3D integrator test no 2D model gives.
- **A small 3D spring lattice:** a cube of masses on springs, the first step
  of the Ch. 3 formations in 3D (counts toward M1's 3D work).
