# Artificial Physics formations driven by ground robots

`../Formations-Newtonian-Ground.lua` and `../Formations-Lennard-Jones-Ground.lua`
are the quadcopter scenes' formations, with the same laws and settings
(`../lib/laws.lua`), on differential-drive ground robots: the book's Pioneer
3-AT as Ch. 13 describes it (BOOK.md G10, milestone M2). AP senses the
robots' real positions five times a second and hands each one the point to
reach by the next tick (`../lib/swarm.lua`, the vehicle interface G18); the
robot turns toward it and drives.

    bpp -f Formations-Lennard-Jones-Ground.lua -n 3000

Open either in the GUI (from the `ArtificialPhysics` folder) to watch. The
keys are the quadcopter scenes' (`../quadcopter/README.md`), except that
robots stay in 2D and cannot leave the formation (`[`).

## The robot (`vehicle.lua`)

| Quantity | Value | Source |
| --- | --- | --- |
| Body | 12 kg box, 0.51 × 0.28 × 0.50 m | Pioneer 3-AT datasheet |
| Half-track r_diff | 0.3 m | book (Fig. 13.6–13.7) |
| Wheel speeds | 0, or 0.1–0.5 m/s either way; a smaller command turns the wheel at 0.1 m/s | book (Fig. 13.7's minimum speed); rounding up: William (F72) |
| Forward speed cap u_max | 0.5 m/s, less while turning (Eq. 13.6) | book |
| Turn-rate cap Ω_max | 0.4 rad/s | book (E11c) |
| Wheel acceleration | ≤ 1 m/s² | chosen |
| Tyres | traction 240 N per m/s of slip per side, sideways grip the same, both capped at μ = 0.8 | chosen |

- **Physics.** Bullet moves one rigid body and handles every contact; the
  body itself is frictionless and all traction comes from the tyre forces
  computed each 4 ms step, so a robot pushing a column spins its wheels and
  one pushed sideways skids.
- **From AP's point to wheel speeds** (book Eqs. 13.4–13.6). AP's command
  is a straight-line leg: be at w by the next tick. The robot wants the
  velocity u_d = (the leg's velocity) + 1/s × (its distance from the leg's
  point). It drives forwards, or backwards when u_d points behind it (with
  20° of hysteresis), turning at Ω = 2/s × the heading error, and at
  forward speed |u_d| cos(error) (Eq. 13.6's cap). Each wheel is
  u ± Ω r_diff; a wheel asked for less than 0.1 m/s (but not 0) turns at
  0.1 m/s, since it cannot turn slower: a small correction is made at the
  minimum speed instead of not at all (F72). Until 2026-10-25 such a
  wheel stood still, and the robots froze (below).
- **Three rules the physics check found** (`../checks/vehicle_physics.lua`):
  - *No wheel faster than the speed AP asks for:* Ω ≤ |u_d| / r_diff.
    Without it, a robot asked to creep spun on the spot at the full
    0.4 rad/s, back and forth.
  - *A pivot stays within Ω_max:* a wheel asked for exactly 0 stops, and
    the robot pivots on it; the other wheel is then held to
    2 r_diff Ω_max. Without it, pivots reached 0.56 rad/s.
  - *Rounding up stays within Ω_max:* a wheel rounded up to 0.1 m/s
    against the other's direction would turn the robot at up to 0.56
    rad/s, so the faster wheel is eased until (v_r − v_l) / 2 r_diff is
    Ω_max.
- **Not modelled:** the book's particle offset from the rotation centre
  (the sensed point is the centre), skid-steer scrub of the four-wheeled
  P3-AT, sensing noise.

`../checks/vehicle_physics.lua` (in `../checks/vehicles.sh`) holds it to
this: top speed 0.500 m/s on a straight line, peak turn 0.400 rad/s ending
3° off the target, and a 4 cm move asked over 1 s made at the minimum
speed (4.0 cm).

## Formation (benchmark task 1)

50 robots from the compact launch cluster (1 m apart), 2D triangle, no
obstacles or goal, 180 s, seeds 1–3, with `../probes/settle_drones.lua`
(*formed*: bonds ≥ 0.97 D and speed < 0.01 m/s to the end; *bond*: mean
pair length within 1.2 D, over D; *bond CV*: its spread; *crossings*: pairs
changing side of D, per robot per minute):

| Law | Formed | Bond | Bond CV | Crossings | Touches |
| --- | --- | --- | --- | --- | --- |
| Lennard-Jones | 106–175 s | 1.00 | 0.021–0.023 | 3.0–9.0 | 5–11 |
| Newtonian (η, the default) | 113–159 s | 0.99–1.00 | 0.053–0.076 | 0.0–1.5 | 0 |
| *before F72: Lennard-Jones, wheels below 0.1 m/s stopped* | 31.7 s | 0.98–0.99 | 0.068–0.074 | 0 | 0–13 |
| *before F72: Newtonian* | never | 0.89 | 0.19–0.21 | 0 | 0 |

The ideal particles, drones and boats are in `../BENCHMARK.md`: the robots
now reach the same lattices (LJ 1.00 D, CV 0.02; Newtonian 0.99–1.00 D, CV
0.05–0.08). They take longer to count as *formed* (106–175 s for LJ,
against the particles' 31–38 s) because the last corrections are made at
0.1 m/s, and the mean speed takes that long to fall below 0.01 m/s.

- **Before F72 the robots froze where the forces fell into the
  minimum-speed gap.** A wheel asked for less than 0.1 m/s stood still.
  AP's command speed is (AP velocity) × timeStep × metersPerUnit × apHz,
  and AP's velocity settles at F / friction, so a robot moved only while
  the force on it exceeded friction × 0.1 m/s / (0.06 × 5) = 0.2 AP units.
  Lennard-Jones froze within 1–2% of D; the split Newtonian law, whose
  force at D is only 0.28 and less under η, at 0.89 D in an irregular
  lattice (F66). The book reads Fig. 13.7 that way ("agents get stuck in
  low-energy formations because the forces are too small to move them",
  PDF 452–453); William's rounding up (F72) is the other reading of a
  minimum speed: the robot moves, at its slowest.
- **Ch. 13's remedies, measured before F72** (the same runs, 3 seeds; none
  kept):

  | Newtonian robots | Bond | Bond CV | Crossings |
  | --- | --- | --- | --- |
  | η, band 0.2 D (default) | 0.89 | 0.19–0.21 | 0 |
  | no η | 0.93 | 0.17–0.18 | 141–151 |
  | no η, adaptive friction 0.5 / 0.02 (Eq. 13.23) | 0.91 | 0.20 | 44–47 |
  | the same + static friction at the book's scale (Eq. 13.25, g′ = 0.098 F(D)) | 0.91 | 0.19–0.20 | 38–56 |
  | the same with g′ = F(D) | 0.93 | 0.18–0.20 | 75–85 |
  | η, band 0.05 D | 0.93 | 0.16–0.18 | 0 |
  | η, band 0.2 D, range 1.25 D | 0.94 | 0.12–0.14 | 0 |

  Without η the plain law dithered at the minimum speed, as the book says
  the Pioneers did before static friction (E11d). Adaptive friction cut
  the dither by two thirds; static friction could not stop it, because
  the book scales its threshold to ~10% of the force at D while this
  dither was driven by the full step at D.

## Goal through obstacles (benchmark task 2)

The default scene: the obstacle field, the goal on after 20 s and crossing
it at 0.2 m/s, 960 s, seeds 1–3. *Through*: 90% of the robots past the
field's far edge. `../probes/stuck_robots.lua` lists every robot left in
the field at the end and the columns around it.

| Law | Through | Past the field at 960 s | Within 4 D of the goal | Stuck | Column hits |
| --- | --- | --- | --- | --- | --- |
| Lennard-Jones | 590–673 s | 98–100% | 98% | 1 robot (seed 1) | 0 |
| Newtonian (η) | 632–666 s | 98–100% | 98–100% | 1 robot (seed 3) | 0 |
| *before F72: Lennard-Jones* | never | 60–70% | 52–62% | | 0 |
| *before F72: Newtonian* | never | 68–80% | 54–70% | | 0 |

**No robot stays behind a single column.** Behind a round column the
goal's pull and the repulsion balance only on the line through the
column's centre, an unstable equilibrium: a robot that keeps moving (as
it now does) slides off to one side and around. Before F72 the robots
there stood still, their net force under the 0.2 threshold.

**The two robots still left are each in a gap the repulsion closes.** Each
sits between two columns 2.61–2.65 m apart surface to surface: wide
enough for the 0.5 m robot, but each column repels out to 1.6 m past its
surface, so the two repulsion zones overlap by 0.55–0.59 m and push the
robot back from both sides. There the goal's pull and the two repulsions
balance in a stable equilibrium, and AP itself asks for no motion: the
robot stands still (0.000 m/s over the last 120 s). The gaps are
(−9.9, −2.6)–(−7.4, −4.7) in seed 1's field and (−29.2, −4.0)–(−27.2,
−8.0) in seed 3's; every robot left behind in any variant we ran (F72)
was in one of these two. The ideal particles (`lib/ideal.lua`, perfect
tracking) are held at the same two points to the centimetre (LJ seeds 1
and 3, Newtonian seed 3), so this is AP's equilibrium, not the robot's:
no vehicle that follows AP exactly gets out. The field keeps columns at
least 2.5 m apart surface to surface (`lib/swarm.lua`, FIELD_MIN_GAP), so
a pair 2.5–3.2 m apart is open to a robot but can hold an agent by AP's
repulsion alone.
No robot touched a column.

## Limitations

- Flat ground only; the world generator's streets (`toBPP(v, { contact =
  true })`) are the next terrain.
- Perfect sensing, no sonar or laser ranging, so Ch. 13's adaptive speed
  cap (Eq. 13.24), which reads ranges, is not wired in.
- No dumbbell (Eq. 13.19–13.22) or torque law: the robot follows AP's
  point-mass velocity through the guidance above, which the book calls
  point-mass control of a wheeled robot (§13.2.2).
