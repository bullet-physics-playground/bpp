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
| P | aim the camera: overview / top-down / close-up (starts behind one drone, looking past it toward the goal; then turn it with the mouse) |
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

**Sliders** beyond the originals': `etaPower` and `etaWidth` (Ch. 13, below), `layerGain`, `numDrones`, `metersPerUnit`, `apHz`,
`altitude`, `windSpeed`, `gust`, `downwash`, `padSpacing`, `fieldDensity`,
`goalSpeed`, `goalDelay`, `launchOrder`, `launchGap`, `lineTransparency` (neighbour lines, 0 = solid, default 0.6), `simSpeed`, `soundVolume`, `soundEmphasis`, and the `obstacleField` and
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

## Ch. 13 on the drones (milestone M1)

Ch. 13 (Apker and Potter) explains why the split-Newtonian swarm never
settles and gives four remedies (`book/ch13.md`). All four were built in
`../lib/ch13.lua` and measured on the drones (below). Only one is needed
here, so only one is on the drones, **on by default in the Newtonian
scene**; the others stay in the library for the ground robots of M2.

| Slider | What it does | Newtonian default | LJ default |
| --- | --- | --- | --- |
| `etaPower` | **AR damping η** (Eq. 13.9–13.10): every drone–drone force is multiplied by η = (\|D − r\|/(etaWidth·D))^etaPower within etaWidth·D of D, 1 outside, so it goes smoothly through 0 at D (r is the spin-modified distance the law uses). 0 = the original law | 1 | 0 (off) |
| `etaWidth` | η's band, as a fraction of D (1 = the book's Eq. 13.9, r < 2D) | 0.2 in 2D, 0.5 in 3D | — |

The status line shows η at the end while it is on (`eta p=1.0 w=0.20`).
The band is set per mode (F56): wide enough that the damped force's slope
at D stays below about 0.035 per AP unit, or the drones jitter again, and
in 2D narrow enough (< 0.26) that second neighbours cannot stall the
expansion at 0.8 D. Out of the box the 2D triangle forms in 76–96 s, the
2D square in 53–170 s, the 3D triangle in 45–50 s and the cube in
80–128 s, all at D, and the default scene crosses the field with no drones
lost.
The tables below record every mechanism measured; the sliders for
adaptive friction (`muMore`, `muLess`) and the stop rule (`stopForce`),
and the switches for static friction and the speed cap, were on the drones
while they were measured and were then taken off (FINDINGS F51, F54, F55;
in the history).

**How it was measured.** `../probes/settle_drones.lua` with `lib/batch.py`:
50 drones, compact launch, no obstacle field, no goal, 5600 frames (about
170 s after AP engages), seeds 1–3. Every quantity is defined at the top of
the probe; briefly: *settles* = the time after which the swarm's mean scalar
acceleration (Ch. 16.9) stays below 0.1 m/s² (sampled every ~1.9 s in these runs, FIXES 40), *speed* and *gap* (the
suggested-position difference, |position − last waypoint|) are means over
the last 29 s, *crossings* are drone pairs changing side of D, per drone per
minute, *bond* is the mean length of pairs closer than 1.2 × the spacing,
and *Delaunay CV* is Ch. 16.9's lattice quality (2D only). Means of 3 seeds.

**Triangle, 2D** (Newtonian defaults: range 1.5 D):

| Law and switches | Settles | Speed | Crossings | Gap | Bond | Delaunay CV | Crashed |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Newtonian | never | 0.27 m/s | 190 | 6.3 cm | 1.01 | 0.112 | 2, 2, 2 |
| + η, power 1 | 6 s | 0.001 m/s | 0 | 0.03 mm | **0.83** | 0.104 | 0 |
| + η, power 2.2 | 4 s | 0.001 m/s | 0 | 0.03 mm | **0.805** | 0.097 | 0 |
| + η 1 + stop 0.03 | 6 s | 0.00007 m/s | 0 | 0.01 mm | 0.83 | 0.106 | 0 |
| + stop 0.03 only | never | 0.27 m/s | 187 | 6.1 cm | 1.01 | 0.117 | 2, 2, 2 |
| Newtonian, range 1.25 | never | 0.28 m/s | 194 | 6.4 cm | 1.01 | 0.109 | 0 |
| range 1.25 + η, power 1 | 6 s | 0.003 m/s | 0.6 | 0.03 mm | 0.986 | **0.069** | 0 |
| range 1.25 + η, power 2.2 | 4 s | 0.004 m/s | 0.1 | 0.03 mm | 0.87 | 0.113 | 0 |
| Lennard-Jones | 20 s | 0.002 m/s | 0.3 | 0.03 mm | 1.00 | 0.092 | 6, 6, 6 |

**Triangle, 3D** (range 1.25 D; launched in thirds, so nothing settles
before the last wave joins, about 28 s after AP engages):

| Law and switches | Settles | Speed | Crossings | Gap | Bond | Bond CV | Crashed |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Newtonian | never | 0.47 m/s | 324 | 10.9 cm | 1.02 | 0.083 | 0 |
| + η, power 1 | 29 s | 0.003 m/s | 1.0 | 0.09 mm | 1.01 | 0.063 | 0 |
| + η, power 2.5 | 28–29 s | 0.001 m/s | 0 | 0.04 mm | 0.99 | 0.114 | 0 |
| + η 1 + stop 0.03 | 29 s | 10⁻⁹ m/s | 0 | 0 | 1.00 | 0.075 | 0 |
| + stop 0.03 only | never | 0.49 m/s | 320 | 11.1 cm | 1.02 | 0.084 | 0 |
| Lennard-Jones | 31–33 s | 0.005 m/s | 2.7 | 0.11 mm | 1.01 | 0.044 | 0 |

**Square and cube** (η power 1): the 2D square settles in 6 s (LJ 23–25 s)
at 0.92–0.96 D, the cube in 27 s (LJ 33 s) at 0.98–1.01 D; without η they
jitter at 0.33 and 0.63 m/s. LJ's cube is the more regular (bond CV
0.007–0.03 against 0.07–0.09).

**Switching η on after the lattice has formed** (William's finding, F49):
with η off until 60 s after AP engages, then 1, the swarm settles within
about 2 s and stays at D — 0.96–0.97 D in 2D (against 0.83 D with η on
from the launch), 1.00–1.01 D in 3D with bond CV 0.035–0.055, as regular
as LJ. η from the launch is a quench; jitter first, then η, is annealing,
with η as the cooling. In the GUI: start without η, wait until the
lattice has spread, then move `etaPower` to 1 without pressing R.
(`--env SWITCH_AT=60 --env SWITCH_SET=etaPower=1` in a batch.)

**η in a band tied to D** (`etaWidth`, William's idea, F50): η ramps to 0
only within |D − r| < etaWidth × D and leaves the force alone outside;
1 is the book's band. From the launch (R pressed with η on), 3 seeds:

| etaWidth | 2D bond | 2D Delaunay CV | 3D |
| --- | --- | --- | --- |
| 1 (book) | 0.83 | 0.104 | settles, bond 1.01 |
| 0.5 | 0.85 | 0.121 | settles, bond 1.01 |
| 0.25 | 0.98 | 0.108 | settles, bond CV 0.056 |
| **0.2** | **0.994** | **0.077** | **settles, bond 1.01, CV 0.054** |
| 0.15 | 0.999 | 0.064 | jitters in 2 of 3 runs |
| 0.1 | 0.994, 4 crashed | 0.089 | jitters (0.32 m/s) |

Too narrow a band makes the force too steep at D for the drones' lag:
the edge is a slope F(D)/(w D) of about 0.04–0.05 per AP unit in both
dimensions, so w ≈ F(D)/(0.04 D) — 0.14 in 2D, 0.21 in 3D. **Use
etaPower 1 with etaWidth 0.2** in both. Crossing the obstacle field it
holds its bonds (0.93–0.94 D in 2D, 1.00 D in 3D, against 0.85–0.95 with
the book's band) but moves no faster than the plain law (swarm centre at
632 s: −43 m; LJ −50 m).

**Adaptive friction** (Eq. 13.23, F51), plain law, from the launch, 3 seeds
(crossings per drone per minute; centre = swarm centre at 632 s of the
obstacle-field crossing, 2 seeds):

| muMore / muLess | 2D | 3D |
| --- | --- | --- |
| 0.05 / 0.02 | 0.12 m/s, 161 crossings | 0.22 m/s, 282 crossings |
| 0.2 / 0.02 | 0.04 m/s, 125 crossings | 0.08 m/s, 298 crossings, bond CV 0.023 |
| 0.5 / 0.02 | 0.014 m/s, 104 crossings; centre +4.5 m | 0.023 m/s, 220 crossings; centre +8.3 m |
| 0.5 / 0.02 with η (w 0.2) | settles 5 s, 0.993 D; centre −40 m | settles 29–30 s, 1.01 D; centre −38 m |

The book's ratio condition (> 10) holds, and adaptive friction removes
most of the motion, but the drones still dither across D, as the book says
before it adds static friction (PDF 465). On its own it freezes the swarm:
the dither keeps μ at 0.8–0.9, which also damps the goal's pull. With η
the dither is gone, μ decays to ~0.1, and it adds little to η.

**Static friction and the adaptive speed cap** (Eq. 13.25, 13.24; F54,
F55) were measured on the drones with two switches, `staticFriction` and
`speedCap` (in the history: commit "AP M1 steps 3–4"), and then taken out
of the drones again, since neither helped; both stay in `../lib/ch13.lua`
for the ground robots. Static friction, with g set by the book's own scale
(g′ = 0.098 F(D)) and even at 10× that, does not stop the dither: 123–367
crossings per drone per minute, never formed, and the swarm stays frozen
in the crossing, as with adaptive friction alone. The cap, crossing a field
twice as dense after a goal twice as fast, changes nothing: no drone hits
a column with or without it, because AP's commands (0.1–0.2 m/s) never
reach it. A per-drone automatic η switch was tried too (F53) and does not
work with a simple local rule.

**Where each Ch. 13 mechanism belongs** (simplicity: `../HANDOFF.md` §2):

| Mechanism | On these drones | Where it is needed |
| --- | --- | --- |
| η, Eq. 13.9 (`etaPower` 1, `etaWidth` 0.2 in 2D, 0.5 in 3D; the default) | **Yes**: the one that settles the split-Newtonian law | Any law with a step at D; not LJ, which is smooth at D already |
| Stop rule | Only holds a settled η swarm still (slider removed) | Vehicles that must not creep (sensor noise, power) |
| Adaptive friction, Eq. 13.23 | No: damps but cannot stop the dither, and alone freezes the swarm (sliders removed) | The book's Pioneers, with static friction; ground robots (M2) |
| Static friction, Eq. 13.25 | No (switch removed) | A minimum speed (Pioneer, Maxelbot) or noisy positions (G7) |
| Adaptive speed cap, Eq. 13.24 | No (switch removed) | Faster vehicles, ranging that sees obstacles late, ground robots |
| Per-drone automatic η switch | Does not work (removed, F53) | — |

**When is the lattice formed?** (F52, FIXES 41). The *Settles* times above
come from the acceleration test, which a lattice still slowly growing
passes. Timed as *formed* (bonds ≥ 0.97 of the spacing and speed below
0.01 m/s to the end; the probe's `formed` column), seconds after AP
engages, 3 seeds:

| | 2D formed | 2D bond CV | 3D formed | 3D bond CV |
| --- | --- | --- | --- | --- |
| η (book band) from the launch | never (0.83 D) | — | 42–57 | 0.063 |
| η, etaWidth 0.2, from the launch | 76–96 | 0.066 | 66–154 | 0.053 |
| etaWidth 0.2 + adaptive friction | 91–117 | 0.066 | 76–85 | 0.053 |
| η (book) switched on at 60 s | never (0.96 D) | — | 68 | 0.044 |
| **η (book) switched on at 150 s** | **157** | **0.046** | **158** | **0.020** |
| etaWidth 0.2 switched on at 60 s | 88–106 | 0.063 | 72–79 | 0.047 |
| Lennard-Jones | 30–35 | 0.023 | 51–64 | 0.015 |

The most regular Newtonian lattice comes from William's way: run the plain
law until the swarm has spread to D (about 150 s in 2D, 60 s in 3D), then
move `etaPower` to 1 without pressing R; it forms about 7 s later. LJ
forms fastest.

**From a pile** (F59; William: in wartime the drones are dropped as a
pile from a truck). The default launch is that pile (1 m apart), and the
defaults are already the best way found: η from the launch forms the 2D
lattice in 76–96 s and the 3D one in 45–50 s, losing no drones. Taking
off in waves, one at a time, or a per-drone switch that turns η on (or on
and off) by its own neighbours' spacing is slower, more ragged, or loses
drones; none was kept. LJ forms from the same pile in 30–35 s.

**What this shows** (`../FINDINGS.md` F43–F47, F49–F55):

- **η alone makes the Newtonian drones settle**, as fast as Lennard-Jones
  or faster, in every formation, without crashes. The plain law's endless
  jitter is the point mass's dither across the sign flip at D (the particle
  replica does it too, at 0.55 AP units per tick), turned into flight.
- **In 2D at range 1.5 D, η shrinks the lattice to ~0.8 D.** It damps the
  nearest neighbours' repulsion near D more than the second neighbours'
  attraction, which comes into range once the lattice shrinks. A balance
  over an infinite lattice predicts 0.800 D (power 1); range 1.25 D keeps
  the second neighbours out and the spacing at D, with the best lattice
  measured. The 3D default range is already 1.25 D.
- **Use η's power 1, not the law's power.** Power 2.2 makes a wide, nearly
  flat zone round D; it settles no sooner and leaves the lattice smaller.
- **The stop rule needs η.** On its own it almost never fires; with η it
  holds the settled swarm still and does not freeze it early.
- **The cost is stiffness.** Through the obstacle field after the moving
  goal (640 s, 2 seeds), η's drones fly smoothly and lose none, and get a
  little farther than the plain law (swarm centre at 632 s: −46 m against
  −43 m in 2D; −47 against −41 m in 3D) but not as far as LJ (−50, −51 m).
  Under the goal's pull their bonds shrink to 0.85–0.92 D (2D) and
  0.94–0.95 D (3D), where LJ's hold 0.97–1.0 D: with η the law's slope at
  D is a quarter to a third of LJ's.

Reproduce, from the `ArtificialPhysics` folder:

    python3 lib/batch.py Formations-Newtonian-Quadcopter.lua \
      --probe probes/settle_drones.lua --env DIM=2 --seeds 1-3 \
      --set obstacleField=false --set goalDelay=0 \
      --set etaPower=0,1,2.2 --frames 5600 --out eta2d.csv --summary settleA

(`--env DIM=3` for 3D, `--env SQUARE=1` for the square or cube, `--set
range=1.25`; for the crossing, drop the two
`obstacleField`/`goalDelay` settings and use `--frames 20000 --env
EVERY=3000`.) About 45 s per pair of runs.

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
