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
| Wheel speeds | 0, or 0.1–0.5 m/s either way | book (Fig. 13.7's minimum-speed gap) |
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
  u ± Ω r_diff; a wheel asked for less than 0.1 m/s does not turn.
- **Two rules the physics check found** (`../checks/vehicle_physics.lua`):
  - *No wheel faster than the speed AP asks for:* Ω ≤ |u_d| / r_diff.
    Without it, a robot asked to creep spun on the spot at the full
    0.4 rad/s, back and forth.
  - *A pivot stays within Ω_max:* when one wheel falls in the gap it stops,
    and the robot pivots on it; the other wheel is then held to
    2 r_diff Ω_max. Without it, pivots reached 0.56 rad/s.
- **Not modelled:** the book's particle offset from the rotation centre
  (the sensed point is the centre), skid-steer scrub of the four-wheeled
  P3-AT, sensing noise.

`../checks/vehicle_physics.lua` (in `../checks/vehicles.sh`) holds it to
this: top speed 0.500 m/s on a straight line, peak turn 0.400 rad/s ending
3° off the target, and a 4 cm move asked over 1 s not made at all.

## Formation (benchmark task 1)

50 robots from the compact launch cluster (1 m apart), 2D triangle, no
obstacles or goal, 180 s, seeds 1–3, with `../probes/settle_drones.lua`
(*formed*: bonds ≥ 0.97 D and speed < 0.01 m/s to the end; *bond*: mean
pair length within 1.2 D, over D; *bond CV*: its spread; *crossings*: pairs
changing side of D, per robot per minute):

| Law | Formed | Bond | Bond CV | Crossings | Final speed | Touches |
| --- | --- | --- | --- | --- | --- | --- |
| Lennard-Jones | 31.7 s | 0.98–0.99 | 0.068–0.074 | 0 | 10⁻⁶ m/s (still) | 0–13 |
| Newtonian (η, the default) | never | 0.89 | 0.19–0.21 | 0 | 10⁻⁶ m/s (still) | 0 |
| Newtonian without η | never | 0.93 | 0.17–0.18 | 141–151 | 0.09 m/s | 0 |

The ideal particles, drones and boats are in `../BENCHMARK.md`: they all
form at 1.00 D, and so do these robots with the minimum speed set to 0
(LJ in 38–39 s, CV 0.03; Newtonian in 96–134 s), so the minimum speed is
the whole difference.

- **The robots freeze where the forces fall into the minimum-speed gap.**
  AP's command speed is (AP velocity) × timeStep × metersPerUnit × apHz,
  and AP's velocity settles at F / friction, so a robot moves only while
  the force on it exceeds friction × 0.1 m/s / (0.06 × 5) = 0.2 AP units.
  Below that every wheel is in the gap and the robot stands still, exactly
  still. This is the book's prediction for the Pioneer's reachable space
  (Fig. 13.7, PDF 452–453: "agents get stuck in low-energy formations
  because the forces are too small to move them; the minimum step sets the
  achievable lattice quality"). Lennard-Jones is stiff enough at D that
  this happens within 1–2% of D. The split Newtonian law is not: its force
  at D is only 0.28, and η, which removes its jitter on drones and boats,
  damps it below 0.2 out to 0.14 D from D, so the robots stop at 0.89 D in
  an irregular lattice.
- **Without η the plain law dithers at the minimum speed**, as the book
  says the Pioneers did before static friction (E11d): every robot keeps
  crossing D at 0.09 m/s.
- **Ch. 13's remedies, measured** (the same runs, 3 seeds; none kept):

  | Newtonian robots | Bond | Bond CV | Crossings |
  | --- | --- | --- | --- |
  | η, band 0.2 D (default) | 0.89 | 0.19–0.21 | 0 |
  | no η, adaptive friction 0.5 / 0.02 (Eq. 13.23) | 0.91 | 0.20 | 44–47 |
  | the same + static friction at the book's scale (Eq. 13.25, g′ = 0.098 F(D)) | 0.91 | 0.19–0.20 | 38–56 |
  | the same with g′ = F(D) | 0.93 | 0.18–0.20 | 75–85 |
  | η, band 0.05 D | 0.93 | 0.16–0.18 | 0 |
  | η, band 0.2 D, range 1.25 D | 0.94 | 0.12–0.14 | 0 |

  Adaptive friction cuts the dither by two thirds but does not stop it;
  static friction cannot, because the book scales its threshold to ~10%
  of the force at D while this dither is driven by the full step at D.
  None forms the lattice, so none is kept (HANDOFF §2). Range 1.25 D,
  which keeps second neighbours out, gives the best Newtonian lattice on
  robots, as on drones in M1 (F45).

## Goal through obstacles (benchmark task 2)

The default scene: the obstacle field, the goal on after 20 s and crossing
it at 0.2 m/s, 960 s, seeds 1–3. *Through*: 90% of the robots past the
field's far edge.

| Law | Through | Past the field at 960 s | Within 4 D of the goal | Column hits |
| --- | --- | --- | --- | --- |
| Lennard-Jones | never | 60–70% | 52–62% | 0 |
| Newtonian (η) | never | 68–80% | 54–70% | 0 |
| either, no minimum speed | 616–680 s (LJ), 694–778 s | 98–100% | 98–100% | 0 |

The robots that stop behind columns stay there for good: where the
goal's pull and the columns' and neighbours' pushes nearly balance, the
net force is under 0.2 and every wheel is in the gap, while particles,
drones and boats creep out (all of them get 90% through in 590–760 s). A
robot is also slower in the open: it must turn before it can follow a
sideways command. No robot touched a column, so the adaptive speed cap
(Eq. 13.24) has nothing to prevent here.

## Limitations

- Flat ground only; the world generator's streets (`toBPP(v, { contact =
  true })`) are the next terrain.
- Perfect sensing, no sonar or laser ranging, so Ch. 13's adaptive speed
  cap (Eq. 13.24), which reads ranges, is not wired in.
- No dumbbell (Eq. 13.19–13.22) or torque law: the robot follows AP's
  point-mass velocity through the guidance above, which the book calls
  point-mass control of a wheeled robot (§13.2.2).
