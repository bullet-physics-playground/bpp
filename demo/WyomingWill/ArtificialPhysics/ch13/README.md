# Ch. 13 — Motion control of physically constrained agents

Apker and Potter's chapter (PDF 444–471; notes in `../book/ch13.md`): a
vehicle can only do what its *reachable space* allows, and point-mass
physicomimetics asks for things it cannot do. The motion-control
mechanisms of §13.2.2 and §13.4.1 (η, adaptive and static friction, the
adaptive speed cap) are in `../lib/ch13.lua` and were measured on the drones
(M1) and the ground robots (M2; `../ground/README.md`). This folder holds the
chapter's own experiments with constrained vehicles: the fixed-wing UAV
and the dumbbell agent on the Pioneer.

## The fixed-wing UAV (§13.2.3, §13.3, §13.4.2)

`../fixedwing/model.lua`: the book's aircraft as a kinematic model. The
inner loop holds speed and height and limits the bank to 20°; the 10 Hz
outer loop can only command a turn rate.

| Quantity | Value | Source |
| --- | --- | --- |
| Speed | 13 m/s, fixed: it cannot stop, slow or reverse | book |
| Bank limit Φ_max | 20° | book |
| Turn-rate limit Ω_max | g sin Φ_max / (2v) = 0.1290 rad/s (Eq. 13.14) | book |
| Smallest turn radius | v / Ω_max = 100.7 m | from Eq. 13.14; matches Fig. 13.16's ~100 m loops |
| Outer loop | 10 Hz | book |

A coordinated turn would allow g tan Φ / v = 0.275 rad/s (47 m). The book's
factor 2 is unexplained, but its figures use it, so we do (FINDINGS F76).

Two laws steer it (`uav.lua`; θ is the bearing of a particle relative to
the heading, in (−π, π], 0 dead ahead):

- **Gravity (point-mass) law.** Targets attract with G/r², UAVs within 50 m
  repel with G/r²; with the speed fixed only the turning equation acts
  (Eq. 13.8): Ω_new = (Ω_old + ΣF·n̂/m) μ, clipped to Ω_max.
- **Torque law** (Eqs. 13.15–13.18). A torsion spring to each particle:
  κθ toward a target, κθ′ away from a UAV within 50 m (θ′ = θ + π wrapped,
  the direction straight away from it), Ω_new = Ω_old + Στ Δt/I, clipped
  to Ω_max, with κΔt/I = Ω_max/π: no single pair can command more than the
  turn limit, the book's rule (PDF 466).

### One UAV, one attractor (Fig. 13.13; `UAV-Attractor.lua`)

The UAV starts at the origin heading east. Its two smallest turn circles,
centred 100.7 m to either side, are the book's "unreachable zones".

| Case | Book | Gravity law, measured | Torque law |
| --- | --- | --- | --- |
| 1. attractor 200 m directly behind | flies away for ever (no sideways force) | 1760 m away after 120 s | turns round, 12 passes within 10 m in 600 s (closest 5.3 m) |
| 2. outside the zones, (150, 150) | overflies it in a continuous loop | 12 passes, closest 0.04 m | the same (closest 5.6 m) |
| 3. inside the left zone, (0, 50) | orbits for ever at the closest reachable distance | closest 50.00 m = 101 − 51, for ever | the same, 50.00 m |

All three of the book's outcomes are reproduced for the gravity law. Case
1 is where the torque law differs: its spring is strongest straight
behind, so it turns round.

### Five UAVs over ten targets (Fig. 13.16; `UAV-Targets.lua`)

10 targets uniform in a 60 × 80 m rectangle at the origin, 5 UAVs starting
on a 400 m circle heading for it (±30°), measured from 120 to 600 s, seeds
1–20 (identical on Lua 5.1–5.4):

| | Gravity law | Torque law | Book (one run each, from the figure) |
| --- | --- | --- | --- |
| Time over the targets' rectangle | 7.8% (4.7–10.0) | **12.2%** (11.0–14.2) | higher with the torque law |
| Spread (RMS distance from the targets' centroid) | 147 m (136–155) | **137 m** (131–172) | loops within ~±250 m vs ~±200 m |
| Mean \|Ω\| | 0.127 rad/s | 0.129 rad/s | lower with the torque law |
| Least distance between two UAVs | 0.2–6.8 m | 0.06–5.2 m | not reported |

- **Reproduced:** the torque law settles into overlapping loops that cross
  the target area once per orbit, and spends 1.6 times as long over it,
  in a tighter cluster.
- **Not reproduced:** the book's lower turning. Both laws turn at nearly
  the limit all the time: the smallest loop already takes the whole turn
  rate, and a loop is what both laws fly. A gentler torque law (κ divided
  among the targets, and no memory: Ω = κΔt/I Σθ) turns at half the
  limit, 0.065 rad/s, but settles into a circle ~205 m round the targets
  that never crosses them (0% over).
- **Collisions:** the UAVs fly in one plane, and pairs come within a metre
  of each other in most runs under both laws; the 50 m repulsion is
  outweighed by ten targets' pull. The book does not mention it. Real
  aircraft would need height separation.

## The dumbbell agent on the Pioneer (§13.4, §13.4.1.2)

`dumbbell.lua`: the agent of Eqs. 13.19–13.23 (and 13.25, off by
default), plain Lua; `Ring-Ground.lua` drives it on BPP's Pioneer 3-AT
(`../ground/vehicle.lua`, Bullet physics, its new `drive(u, Ω)`). Two
particles on the heading axis, the front one (the camera) 0.25 m ahead of
the rotation centre, the back one 0.25 m behind; ten times a second

- F = ΣF_front + ΣF_back (13.19); M = T + r_f × ΣF_front + r_b × ΣF_back
  (13.20), T the torque-law torques;
- u_new = (u + F·t̂/m)(1 − μ_u) (13.21), Ω_new = (Ω + M/I)(1 − μ_Ω)
  (13.22), m = I = 1 (the book's 1 : 1), clipped to 0.5 m/s and 0.4 rad/s;
- each μ by Eq. 13.23 (k_more 0.25, k_less 0.02: ratio 12.5 > 10), used
  from the next tick;
- the wheels (u ± Ω r_diff, Eqs. 13.4–13.6) turn at 0 or 0.1–0.5 m/s, a
  smaller command rounded up to 0.1 (F72).

The camera ring (the book gives none of its numbers; our choices):

| Part | Law | Values |
| --- | --- | --- |
| Ring | the attractor pulls the camera to a circle: Fig. 13.8's split law with η (Eq. 13.9), f = G/r η, repelling inside R | R = 2 m, G = 5 |
| Pointing | a torsion spring from the heading to the attractor (Eq. 13.15) | κ = 0.4/π (no spring asks for more than Ω_max a tick, the book's rule, PDF 466) |
| Spacing | each camera repels the others' cameras, Gr/r² | Gr = 0.3, range 5 m |
| Spreading (`spread`, off by default) | a weak pointing spring for the first `spread` s | κ = 0.01 for 60 s |
| Static friction (Eq. 13.25, off by default) | a channel moves only if μ m g < its force | g = 0.05 |

### The three-point turn (`Ring-Ground.lua`, case 1)

One robot heading +x, the attractor 5 m dead astern (or turned off it by
`behind`); 60 s on the Pioneer in Bullet:

| Attractor | Travel | Camera on the ring, pointing in | Camera's largest distance from the straight line |
| --- | --- | --- | --- |
| dead astern | backs 4.4 s while turning, then forwards | 11.0 s (point 1.4°) | 0.73 m |
| 30° off astern | backs 3.2 s, then forwards | 10.8 s | 0.78 m |
| 90° (to the left) | forwards at once | 9.2 s | 0.55 m |
| dead astern, no pointing spring (κ 0) | backs straight to it | never: 180° off | 0 |
| dead astern, no adaptive friction (k_more 0) | swings for ever | never (0.19 m, 24° at 60 s) | 0.73 m |

- **Reproduced:** the book's emergent three-point turn (PDF 464): the
  robot backs while it turns, then drives forwards, and arrives pointing
  in. Nothing in the agent asks for it.
- The pointing spring matters only near dead astern: there the forces on
  the camera have no moment, so without it the robot backs straight in
  and ends facing away; 30° or more off, the force law alone turns it.
- Without adaptive friction the agent swings round its target for ever
  (Eqs. 13.21–13.22 are integrators).
- After arriving the robot creeps back and forth at the minimum wheel
  speed for ever (~2 changes of direction a second): its commands decay
  geometrically but never reach 0, and a wheel asked for any speed turns
  at 0.1 m/s. Static friction (Eq. 13.25, g = 0.05) cuts that to 7–9
  passes in all instead of 124–145, and the robot stands still (dead
  astern and 30° off; at 90° it still makes an occasional move), as the
  book says it did on its robots (PDF 465). The kinematic check makes 4.

### The camera ring (`Ring-Ground.lua`, case 0; `ring_sweep.sh`)

3–5 robots, seeds 1–10, two starts (each at a random bearing 5–8 m out;
a line 1 m apart 10 m out on one side), 300 s; means over the 20 runs of
each row (`ring_runs.txt`; gap is the largest gap between neighbours on
the ring over the even gap, 1 = even; point and radius the worst robot's):

| Setting | n | Radius (m) | Point (°) | Gap | Robots moving at the end | Passes per robot | Robot contacts |
| --- | --- | --- | --- | --- | --- | --- | --- |
| plain | 3 | 0.130 | 25.5 | 2.00 | 3.0 | 742 | 0.2 |
| plain | 4 | 0.112 | 24.7 | 1.78 | 4.0 | 760 | 0.5 |
| plain | 5 | 0.162 | 32.5 | 1.75 | 5.0 | 742 | 1.1 |
| spread 60 s | 3 | 0.043 | 2.3 | 1.24 | 3.0 | 740 | 0.2 |
| spread 60 s | 4 | 0.066 | 3.7 | 1.27 | 4.0 | 721 | 0.2 |
| spread 60 s | 5 | 0.093 | 5.0 | 1.29 | 5.0 | 725 | 0.8 |
| spread + static | 3 | 0.039 | 2.6 | 1.23 | 0.5 | 30 | 0.2 |
| spread + static | 4 | 0.062 | 4.3 | 1.27 | 0.3 | 31 | 0.2 |
| spread + static | 5 | 0.091 | 5.5 | 1.25 | 1.1 | 31 | 0.9 |

- **A robot on the ring cannot move along it.** Pointing in, its axle
  lies along the ring, so a neighbour's push is sideways: it has no
  component along the heading to drive, and on the two particles its
  moments nearly cancel (the triangle of death's geometry, E6). The robots
  stay at the bearings they arrived at: from a line on one side all of
  them arrive together (gap 1.93, the worst 2.7), and crowded neighbours
  tilt each other's cameras 21–34° off. Stronger or longer repulsion
  (Gr to 1, range to 10 m) only pushed the robots off the ring; repelling
  both particles instead of the cameras did not spread them either.
  Brockett's condition (1983) suggests why: no smooth feedback that does
  not change with time can bring a vehicle that cannot move sideways to a
  pose (here the camera's place on the ring and its heading), and a fixed
  force-and-torque law is such a feedback.
- **Spreading first, then pointing, does both** (`spread` 60 s, William's
  annealing applied to the pointing spring, F49): with a weak spring the
  robots turn along the ring and spread (gap 1.24–1.29, the worst 1.46,
  from either start); then the full spring turns each in place to point
  in (2–5° off, cameras within 0.04–0.09 m of the ring). With the weak
  spring alone the ring spreads (gap 1.2) but the cameras stay ~40° off
  (kinematic model). 60 s was as good as 100 or 150.
- **The book's advice, explained:** "performance is best if they arrive at
  their correct points in the proper orientation" (PDF 464); a robot on
  the ring can turn but not slide.
- Static friction again stops the creeping (robots moving at the end
  0.3–1.1 of 3–5, 30 passes in 300 s against ~740), at about 0.5° more
  pointing error.
- Cost: 300 simulated s take 3–5 wall s with 3–5 robots, so the 180 runs
  of `ring_sweep.sh` are ~11 CPU-minutes.

## Choices where the book is silent (the fixed-wing UAV)

The book gives no numbers for G, μ, κ, I, the repulsion range, the
targets' layout, the starts or the run length (`../book/ch13.md` E12):

- G = 20,000 (m = 1): a target 400 m away already asks for about Ω_max, so
  the gravity law is the bang–bang controller the book describes.
- μ = 0.5 (gravity law's retention factor); the torque law has no friction
  (Eq. 13.18 as printed). With any friction on Ω (Eq. 13.22's (1 − μ_Ω),
  μ_Ω = 0.01–0.05), a UAV that leaves with the targets straight behind it
  stays on that course in 3–4 runs in 20: the springs to the targets just
  left and just right of its tail cancel, and the balance is stable.
- Repulsion between UAVs within 50 m, half a turn radius, in both laws;
  the torque law's repulsion turns away from the neighbour (the printed
  "+κθ" is zero for a neighbour dead ahead).
- κΔt/I = Ω_max/π for every pair, the book's rule, with no division among
  the targets.

## Files

- `../fixedwing/model.lua`: the aircraft (plain Lua).
- `uav.lua`: the two laws, worlds and measures (plain Lua).
- `uavscene.lua`, `UAV-Targets.lua`, `UAV-Attractor.lua`: the scenes. Open
  them in BPP's GUI (sliders `law`, `seed`, `case`, `ticksPerFrame`; R
  restarts). The status line shows the measures above.
- `../checks/fixedwing.lua`: the turn limit, the three single-attractor
  outcomes, and the torque law's advantage over the targets (7 tests,
  ~4 s).
- `dumbbell.lua`: the dumbbell agent, the ring's forces and torques, its
  measures, and a kinematic Pioneer for checks (plain Lua).
- `Ring-Ground.lua`: the dumbbell on BPP's Pioneers, the camera ring
  (case 0) and the three-point turn (case 1); sliders `case`, `robots`,
  `seed`, `start`, `spread`, `behind`; R restarts. Headless:
  `RING_N=4 RING_SEED=1 RING_SPREAD=60 RING_EXIT=1 bpp -f ch13/Ring-Ground.lua -n 100000`.
- `ring_sweep.sh`: the ring table above (180 runs, resumable, parallel;
  `ring_runs.txt`).
- `../checks/dumbbell.lua`: the equations, the three-point turn, what
  each part does, and the ring plain against spread (6 tests, ~2 s).
