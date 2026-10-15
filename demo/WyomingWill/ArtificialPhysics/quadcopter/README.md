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

The scene starts, as the originals do, with a compact random cluster: the
drones stand at random on the ground, no closer than `padSpacing` (1 m), in
a square about 10 m across. They climb straight up (2D: all to `altitude`;
3D: each to a random height in a 6 m band), and AP engages once all of them
are at altitude and spreads them into the lattice.

The **status bar**, beside the frame counter, shows the current mode on
one line: law, 2D/3D and formation, goal, obstacles, AP state, drone
counts, wind and camera, plus the lattice's bond length and speed once AP
runs. It updates on every change and about once a second. This uses
`v.statusText`, a small BPP addition (`src/viewer.*`, `src/gui.*`); on an
older BPP the mode changes are printed to the console instead. The
Shortcuts pane holds just the keys.

## Files

| File | What it is |
| --- | --- |
| `flight.lua` | One quadcopter: rigid body, rotors, motors, air, flight controller |
| `swarm.lua` | The AP formation harness: sensing, force laws, waypoints, launch/land, obstacles, wind, downwash, prop strikes, camera, stats, keys |
| `sound.lua` | Rotor sound: drives BPP's synthesised voices from the motor speeds, heard from the camera |
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

**Obstacles** are solid columns from the ground up past the formation. AP
repels inside each column's repulsion radius, measured horizontally from its
axis, in 3D as well as 2D. The originals' 3D obstacle was a sphere; a column
needs a column-shaped repulsion.

**The obstacle field** (on by default; untick `obstacleField` and press R to
go back to an empty sky):

- **Layout:** each Setup (R) scatters columns of random radius (0.3–1.4 m)
  over a 36 m × 36 m field between the launch area and the goal, at
  `fieldDensity` per 100 m² (default 2.5, about 32 columns). Columns are
  never closer than 2.5 m surface to surface, so a drone can always fit
  between two of them.
- **Repulsion:** each column repels out to 1.6 m past its surface.
  Obstacles placed with O keep the `obstacleSize` slider.
- **The run:** the formation assembles in the clear. `goalDelay` seconds
  after AP engages (default 20; 0 = only with G), the goal switches on. It
  starts at the field's near edge, moves through the field at `goalSpeed`
  (0.2 m/s), and stops in the clear on the far side. The swarm follows it,
  finds its way between the columns, and reassembles around it.
- **Timing:** a crossing takes about 9–10 minutes of flight. Use = (simSpeed)
  to fast-forward.

**Obstacle repulsion is gentler than the originals'.** The originals'
`size − r` law in AP units is far too stiff at 6 cm per unit: a metre inside
a column's zone gave about 17 times the drone-to-drone force cap. AP turned
that into several m/s, and drones were flung across gaps into columns and
each other; the first field version lost 12–21 of 50 drones per crossing.
The force now grows at 2 units per metre into the zone, capped at 4, and no
drone has been lost to the field since (7 crossings).

**Camera:** the mouse always controls the angle and zoom. With follow on
(T), the camera is only *translated* each frame by however far the swarm's
centre moved. Your angle and distance are kept, and the orbit point moves
with the swarm, so dragging orbits around it. P aims from a preset view.
Orbiting around the swarm uses `v.cam.pivot`, which needs the two small
additions to `src/objects/cam.cpp` and `cam.h` (`v.cam.dir`,
`v.cam.pivot`). Without them, following still works but orbiting turns
around the world origin.

With perfect tracking this reduces exactly to the original particle demo.
That was checked by swapping in an ideal drone: the lattices match the
originals.

## Keys

| Key | Action |
| --- | --- |
| S | start/stop |
| R | new launch (in the order `launchOrder` says; 3D: in thirds, top level first) |
| 2 / 3 | 2D / 3D |
| ] | launch one more drone; it climbs into the formation |
| [ | a drone leaves the formation and lands |
| D | a drone holds position (the original's "disable") |
| F | square formation |
| G | goal on/off (with the field, the goal also travels; it switches on by itself after `goalDelay` s) |
| C | clear obstacles |
| arrows / IJKL / YH | move the cursor |
| O | an extra obstacle at the cursor: a solid column, in 2D and 3D |
| V | neighbour lines |
| W | waypoint markers |
| T | follow the swarm on/off |
| P | aim the camera: overview / top-down / close-up (behind one drone, looking past it toward the goal; T frees it) |
| mouse | drag to orbit, wheel to zoom; following keeps your angle |
| = / - | simSpeed |
| M | sound on/off (`soundVolume`) |

**Colours:**

- white / yellow: spin 0 / 1
- violet: holding position
- red: crashed
- grey: landed

**Flight levels** (`layerGain`, 3D): a gentle vertical pull toward
horizontal levels.

- **3D triangle:** levels √(2/3) × the spacing apart, so the swarm stacks
  into flat triangular layers (close packing) instead of a jumble. On by
  default: 0.1 for Newtonian, a softer 0.05 for Lennard-Jones, which keeps
  it fluid. Lennard-Jones still crossed the obstacle field as fast as
  without levels, and stayed 2–3 times as mobile as Newtonian.
- **3D cube:** levels one spacing apart, so each level is a 2D square
  lattice and the levels stack straight up. Without them the cube forms
  slowly, tilted at an arbitrary angle and full of defects, and looks like
  a tangle. Default 0.05 for both laws.

Set it to 0 to turn the levels off. See `../FIXES.md` items 30 and 32.

**Sliders** beyond the originals': `layerGain`, `numDrones`, `metersPerUnit`, `apHz`,
`altitude`, `windSpeed`, `gust`, `downwash`, `padSpacing`, `fieldDensity`,
`goalSpeed`, `goalDelay`, `launchOrder`, `launchGap`, `simSpeed`, `soundVolume`, `soundEmphasis`, and the `obstacleField` and
`propStrikes` checkboxes.

**Prop strikes:** Bullet's own contact points are checked every frame.
Drones that touch each other, an obstacle, or (while flying) the ground lose
their props and fall, and can take down drones below them. Untick
`propStrikes` to let hulls just bounce.

**Launch order** (`launchOrder`, used by the next R):

| Value | Order |
| --- | --- |
| 0 | all at once, each drone to a random height in a band around `altitude` (the originals' cube; 2D default) |
| 1 | in thirds, `launchGap` s apart, top level first, then the middle, then the bottom (3D default) |
| 2 | in thirds, bottom level first |
| 3 | in thirds, each to random heights |
| 4 | one drone at a time, over the same total time |

AP starts once the first group is up, and later drones join as they
reach their height. The goal's `goalDelay` counts from when the last
drone has joined.

Measured on 50 drones, 3 seeds per order and law:

- **Shape:** top first is the only order that builds three even levels
  every time (16 / 17 / 17 drones), in both the cube and the triangle.
  All at once makes lopsided stacks such as 2 / 19 / 25 / 4.
- **Safety:** top first never crashed. Bottom first and one at a time
  lose drones, because later ones climb up through the levels already
  formed.
- **Lattice quality:** after the same time under the goal (about 90 s,
  goal and field on), top first:
  - **Cube:** clearly better for Newtonian (square angles 76 / 100 / 89%
    against 71 / 69 / 61%). Mixed for Lennard-Jones (86 / 88 / 90%
    against 97 / 81 / 69%).
  - **Triangle:** roughly a tie (in-level triangle angles 89 / 84 / 95% and
    87 / 73 / 86%, against 92 / 85 / 75% and 91 / 78 / 70%).

  Top first has no bad runs; all at once sometimes does.

See `../FIXES.md` item 33 for every order.

**Sound** (`sound.lua`, `soundVolume`, M mutes): you hear the swarm from
the camera. Every rotor buzzes at its blade-passing frequency (2 blades ×
rev/s): about 38 Hz at idle, 181 Hz in hover, 283 Hz flat out. Its
loudness rises as (rpm / max)^2.5, so climbs and hard manoeuvres are much
louder than hover. When a drone tilts or turns, its four motors run at
different speeds, and their tones beat against each other: that warble is
the steering you can hear.

- **Nearest 3 drones:** four voices each (one a rotor), plus a quiet
  motor whine at 7 × rev/s.
- **The rest:** one blended "crowd" voice; their sound powers add, at
  their mean pitch.
- **Distance:** loudness falls as 1/distance, and far drones lose their
  overtones and sound duller. Doppler raises the pitch of an approaching
  drone.
- **Pan:** follows the camera, left of the view in the left speaker.

**Emphasis** (`soundEmphasis`, default 0.7; 0 = the physical sound): makes
a drone that's doing something louder than the rest. Each drone gets an
activity score from three things:

- how far its four rotor speeds pull apart, which is the drone tilting
  (pitch or roll) or turning;
- how fast its overall rotor speed changes, which is the sound's pitch
  rising or falling;
- its speed relative to the swarm, so the whole swarm drifting after the
  goal doesn't count.

A drone that stands out from the swarm's median:

- gets its own voices (picked by activity as well as nearness, and kept at
  least 1 s so they don't flicker);
- is up to about 12 dB louder;
- is heard from farther away (distance counts for less).

A settled swarm drops to a low hum, and the many calm drones are scaled
back so they don't drown out the busy few.

Measured with Lennard-Jones at 0.7 from a close camera:

- **Takeoff:** loud.
- **Settled lattice:** a hum, 9 dB below the physical sound.
- **Weaving through the obstacle field:** swells about 10 dB.

Newtonian never settles and every drone is about equally busy, so it stays
near its physical level with smaller swells.

The voices hush while the simulation is stopped. They also go into the
`.wav` of a POV-Ray export. A bpp without `v:setTone()` just runs silent.

## What the drones change (2-minute runs, 50 drones, default settings, compact launch)

| Mode | Lattice (bond length, sd) | Drones lost |
| --- | --- | --- |
| Lennard-Jones 2D triangle | 1.000 R, sd 0.002 | 4 (AP's first expansion) |
| Lennard-Jones 2D square | 1.011 R, sd 0.043 | 4 (AP's first expansion) |
| Lennard-Jones 3D triangle | 1.012 R, sd 0.047 | 0 |
| Lennard-Jones 3D square | 1.011 R, sd 0.045, compact (80 bonds) | 0 |
| Newtonian 2D triangle | 0.992 R, sd 0.092; still moving at 0.2 m/s | 0 |
| Newtonian 2D square | 0.980 R, sd 0.105 | 7 |
| Newtonian 3D triangle | 0.997 R, sd 0.112, no collapsed pairs (old defaults) | 0 on this seed; 0–3 in 3 min on others with the old defaults; 0 on 3 seeds with the new ones (see below) |
| Newtonian 3D square | 1.016 R, sd 0.118 | 0 |

- **Newtonian 3D triangle used to lose a few drones, field or no field.**
  This was the originals' 3D Newtonian collapse (`../FIXES.md` items 2 and
  30), and it's fixed by the new 3D-triangle defaults (range 1.25, forceMax
  5, flight levels).
  - **Old defaults:** with no field and no goal, 0 and 3 lost on two
    seeds; with the goal on, 2 and 6; crossing the field, 12.
  - **New defaults:** with the goal on, 0 / 0 / 0 on three seeds; crossing
    the field, 1 / 0 on two.
- **2D launches lose a few drones to AP itself.** In 2D every drone is at
  the same height, so AP's first violent expansion from the compact cluster
  can push a pair within a drone's width. The repulsion is capped at
  `forceMax`/`forceMaximum`, and neighbours behind can outpush it. Ideal
  drones (perfect tracking) collide just the same, so particles in the
  original overlap here too, invisibly. In 3D the drones are spread over
  6 m of height and none collide.
  - Over 3 seeds: 1 m spacing lost 12 / 13 / 11 drones (LJ triangle /
    LJ square / Newtonian square, of 150 each).
  - At `padSpacing` 1.5 m that falls to 2 / 8 / 0.
  - A higher repulsion cap makes it worse (20 / 34).
  - Untick `propStrikes` to watch the original behaviour, with drones
    bouncing instead.
- **The split Newtonian law never settles on real drones.** It flips sign at
  `rad`, and the drones' response lag keeps overshooting across the switch.
- **Square formations sort out slowly.** The spin trick needs spins (id % 2)
  in a checkerboard. From a random cluster the lattice has to sort itself
  into one, so for the first 30–40 s it keeps reorganising, then settles to
  0.01 m/s with defects that anneal out over minutes. The original particles
  do the same: only 14 of 50 have all four square neighbours after 600
  ticks, 18 after 2000.
- **AP at 5 Hz:** at 10 Hz the commanded speeds outrun the airframe.
- **Solid obstacle at a third of the repulsion radius:** a drone needs about
  0.5 m to stop from 2 m/s.

The measurements behind these are in `../FIXES.md`, items 17–23.

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
