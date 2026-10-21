# Artificial Physics formations sailed by surface boats

`../Formations-Newtonian-Boat.lua` and `../Formations-Lennard-Jones-Boat.lua`
are the quadcopter scenes' formations, with the same laws and settings
(`../lib/laws.lua`), on round holonomic surface boats: the book's Ch. 6 ASV
(BOOK.md G11, milestone M2). AP senses the boats' real positions five times
a second and hands each one the point to reach by the next tick
(`../lib/swarm.lua`, the vehicle interface G18); the boat's thrust
controller gets it there.

    bpp -f Formations-Lennard-Jones-Boat.lua -n 3000

The keys are the quadcopter scenes' (`../quadcopter/README.md`), except
that boats stay in 2D and cannot leave the formation (`[`).

## The boat (`vehicle.lua`)

| Quantity | Value | Source |
| --- | --- | --- |
| Hull | round, 0.46 m across, 0.15 m deep | book (Ch. 6.5, PDF 218–222: 18 × 6 in) |
| Propulsion | two Voith–Schneider propellers: thrust in any horizontal direction, no torque | book |
| Mass | 12 kg (draft 7.2 cm) | chosen |
| Thrust | ≤ 12 N, following its command with a 0.3 s lag | chosen |
| Drag | 2 N per m/s + ½ ρ C_d (0.46 m × draft) v², C_d = 1 | chosen |
| Top speed | 0.79 m/s (the drag balance at 12 N) | follows |
| Added mass | the displaced mass (coefficient 1, a vertical cylinder) | standard |

- **Physics.** BPP has no fluid simulation (G19), so the water is forces
  computed each 4 ms step on one Bullet rigid body over a seabed 3 m down:
  buoyancy at 9 points over the bottom (so it floats level and rights
  itself), half-critical heave damping at the same points, horizontal drag
  and yaw damping, and the thrust. Horizontal forces act on mass plus added
  mass. Still water: no waves, wind or current.
- **From AP's point to thrust.** As the robot: the leg's velocity plus
  1/s × the distance from the leg's point gives the desired velocity u_d;
  the thrust command is the drag at u_d plus (mass + added mass) × 2/s ×
  (u_d − v), capped at 12 N. The boat is holonomic like a quadcopter but
  slower, with less authority, and nothing like a 35° tilt to brake with.
- **Not given by the book:** mass, thrust, speed and drag. The values above
  are chosen and stated; the hull's size is the book's.

`../checks/vehicle_physics.lua` (in `../checks/vehicles.sh`) holds it to
this: afloat at its draft (centre within 2 mm), top speed 0.79 m/s, upright
again within 4 s from a 20° heel, and moving sideways 6.8 m in 10 s
without turning.

## Formation (benchmark task 1)

50 boats from the compact launch cluster, 2D triangle, no obstacles or
goal, 180 s, seeds 1–3, `../probes/settle_drones.lua` (definitions in
`../ground/README.md`):

| Law | Formed | Bond | Bond CV | Crossings | Touches |
| --- | --- | --- | --- | --- | --- |
| Lennard-Jones | 36–42 s | 1.00–1.01 | 0.025–0.030 | 0.4–2.2 | 0–4 |
| Newtonian (η, the default) | 78–98 s | 0.99–1.00 | 0.057–0.065 | 0–1.1 | 0 |

Within a few seconds of the ideal particles' times (LJ 31–38 s, Newtonian
72–116 s) and with the same lattice: a holonomic vehicle with no minimum
speed follows AP's point mass closely, as the drones do.

## Goal through obstacles (benchmark task 2)

The default scene (the obstacle field: here pilings from the seabed; the
goal on after 20 s, crossing at 0.2 m/s), 960 s, seeds 1–3. *Through*: 90%
of the boats past the field's far edge.

| Law | Through | Past the field at 960 s | Within 4 D of the goal | Pile hits |
| --- | --- | --- | --- | --- |
| Lennard-Jones | 698–763 s | 98–100% | 86–90% | 0 |
| Newtonian (η) | 688–744 s | 98–100% | 98–100% | 0 |

The ideal particles take 591–666 s (LJ) and 688–763 s; the boats are as
fast with the Newtonian law and up to ~100 s slower with LJ.

## Limitations

- Still water; waves, wind and currents are G19 (later).
- Perfect sensing (GPS and the book's RF hyperbolic localisation are not
  modelled).
- The thrust acts at the centre, so it does not heel the hull.
