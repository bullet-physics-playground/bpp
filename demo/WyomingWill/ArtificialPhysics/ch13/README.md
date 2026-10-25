# Ch. 13 — Motion control of physically constrained agents

Apker and Potter's chapter (PDF 444–471; notes in `../book/ch13.md`): a
vehicle can only do what its *reachable space* allows, and point-mass
physicomimetics asks for things it cannot do. The motion-control
mechanisms of §13.2.2 and §13.4.1 (η, adaptive and static friction, the
adaptive speed cap) are in `../lib/ch13.lua` and were measured on the drones
(M1) and the ground robots (M2; `../ground/README.md`). This folder holds the
chapter's own experiments with constrained vehicles.

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

## Choices where the book is silent

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
