# Artificial Physics formations flown by quadcopters

`../Formations-Newtonian-Quadcopter.lua` and
`../Formations-Lennard-Jones-Quadcopter.lua` are the two Formations demos
with every particle replaced by a physically modelled quadcopter.
Artificial Physics (AP) no longer moves anything itself: it senses where the
drones actually are, computes the same force law as the original files, and
hands each drone its next **waypoint**. The drone's own flight controller then
has to fly there.

Open either file in the GUI, or run it headless **from the
`ArtificialPhysics` folder** (meshes and modules load by relative path):

    bpp -f Formations-Lennard-Jones-Quadcopter.lua -n 3000

The scene starts with the drones on a launch grid. They take off, and AP
engages once all of them are at altitude.

## Files

| File | What it is |
| --- | --- |
| `flight.lua` | One quadcopter: rigid body, rotors, motors, air, flight controller |
| `swarm.lua` | The AP formation harness: sensing, force laws, waypoints, launch/land, obstacles, wind, downwash, prop strikes, camera, stats, keys |
| `meshes/*.obj` | Frame, front arms (red), prop discs. Regenerate with `python3 gen-meshes.py meshes` |

## The quadcopter (`flight.lua`)

- **Airframe:** a generic 450 mm X quad. All-up mass 1.5 kg, 10" props, and
  inertia 0.015 / 0.028 / 0.015 kg m² (roll / yaw / pitch). The hull is a
  flat box covering the props and legs.
- **Rotors:** each gives thrust kT·ω² and reaction torque kQ·ω². The two
  diagonal pairs spin opposite ways, so yaw comes only from the speed
  difference between the pairs. Each motor follows its command with a 40 ms
  lag, between an armed idle speed and its maximum. Hover is at 3.68 N per
  motor and full thrust is 9.0 N per motor, a thrust-to-weight ratio of
  about 2.4.
- **Air:** air-relative velocity includes wind, gusts, and downwash from
  drones above.
  - axial-inflow thrust loss, about 1.35 N per m/s at hover
  - in-plane rotor drag
  - quadratic body drag
  - ground effect
  - light rotational damping
- **Flight controller:** a PX4-style cascade, recomputed every 4 ms (250 Hz):
  1. position P, plus velocity feed-forward from the trajectory
  2. velocity PI
  3. thrust vector, limited to a 35° tilt and to the available thrust
     (vertical first)
  4. geometric (SO(3)) attitude error
  5. body-rate P with gyroscopic feed-forward
  6. motor mixer: keeps roll/pitch, sacrifices yaw first, shifts the
     collective to fit the motor limits
- **Tilt failsafe:** past 65° for 0.25 s, the motors are cut.
- **Measured single-drone response:**
  - a 10 m sideways step rises in about 2.7 s with about 2% overshoot,
    peaking at 5.2 m/s and the 35° tilt limit
  - in an 8 m/s crosswind it leans about 15° and recovers its position

## How AP drives the drones (`swarm.lua`)

At `apHz` (default 5 Hz) each AP tick runs these steps:

1. Every drone senses every airborne drone's **actual** position, converted
   to AP units (1 unit = `metersPerUnit`, default 6 cm, so `rad` /
   `desiredSeparation` = 50 is a 3 m lattice).
2. The original force law, square-formation spin trick, goal and obstacle
   terms, friction and F = m·a update run unchanged.
3. The waypoint is the sensed position plus `timeStep`·v. The drone gets a
   straight-line trajectory to it that arrives at the next tick.

In 2D everyone flies at `altitude`; in 3D, AP's y is height around it. A
geofence keeps waypoints between 2 m and 60 m.

With perfect tracking this reduces exactly to the original particle demo.
That was checked by swapping in an ideal drone: the lattices match the
originals.

## Keys

| Key | Action |
| --- | --- |
| S | start/stop |
| R | new launch |
| 2 / 3 | 2D / 3D |
| ] | launch one more drone; it climbs into the formation |
| [ | a drone leaves the formation and lands |
| D | a drone holds position (the original's "disable") |
| F | square formation |
| G | goal |
| C | clear obstacles |
| arrows / IJKL / YH | move the cursor |
| O | obstacle at the cursor: a pole in 2D, a sphere in 3D; both solid |
| V | neighbour lines |
| W | waypoint markers |
| T | follow camera on/off |
| P | overview / top-down / close-up on one drone |
| = / - | simSpeed |

**Colours:**

- white / yellow: spin 0 / 1
- violet: holding position
- red: crashed
- grey: landed

**Sliders** beyond the originals': `numDrones`, `metersPerUnit`, `apHz`,
`altitude`, `windSpeed`, `gust`, `downwash`, `padSpacing`, `simSpeed`, and
the `propStrikes` checkbox.

**Prop strikes:** Bullet's own contact points are checked every frame.
Drones that touch each other, an obstacle, or (while flying) the ground lose
their props and fall, and can take down drones below them. Untick
`propStrikes` to let hulls just bounce.

## What the drones change (3-minute runs, 50 drones, default settings)

| Mode | Lattice (bond length, sd) | Drones lost |
| --- | --- | --- |
| Lennard-Jones 2D triangle | 1.000 R, sd 0.003: identical to the original | 0 |
| Lennard-Jones 3D triangle | 1.006 R, sd 0.030 | 0 |
| Lennard-Jones 3D square | peaks at 1.0 R and √2 R | 0 |
| Newtonian 2D triangle | 1.019 R, sd 0.069; still moving at 0.3 m/s | 0 |
| Newtonian 3D triangle | 1.013 R, sd 0.106, no collapsed pairs | 0 |

- **The split Newtonian law never settles on real drones.** It flips sign at
  `rad`, and the drones' response lag keeps overshooting across the switch.
- **The defaults are chosen to keep the swarm flyable:**
  - **AP at 5 Hz:** at 10 Hz the commanded speeds outrun the airframe.
  - **Launch grid at 3 m:** at 1.5 m, AP's first expansion causes
    collisions.
  - **Solid obstacle at a third of the repulsion radius:** a drone needs
    about 0.5 m to stop from 2 m/s.

  Each of these was measured; see `../FIXES.md` items 17–21.

## Limitations

- **Sensing is perfect.** The controller and AP see true positions and
  velocities, with no sensor noise, GPS error or communication delay.
- **Yaw is held at 0.** The drones never turn to face their direction of
  travel.
- **Simplified aerodynamics:**
  - downwash is a simple widening-jet model
  - no blade-element rotor model
  - no vortex-ring state
  - no battery sag
- **CPU cost:** about 12 µs per drone per physics step. Headless, 50 drones
  run at about 4–5× real time on one core.
