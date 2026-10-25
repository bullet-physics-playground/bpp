# The cross-vehicle benchmark

Ch. 13's central claim is that physicomimetics only decides where each
agent should go, and each vehicle's own controller works out how to get
there, so the method should not depend on the vehicle. This file tests
that claim directly (`BOOK.md` §6): the same tasks, the same force laws
with the same settings (`lib/laws.lua`), on every vehicle behind the
vehicle interface (`lib/swarm.lua`, G18). It is the scientific result of
the capstone's benchmark matrix; this is its first part (milestone M2:
2 tasks × 4 vehicles × 2 laws, 3 seeds each).

| Vehicle | Folder | Moves | Limits that matter here |
| --- | --- | --- | --- |
| Ideal particles | `lib/ideal.lua` | exactly where AP says | none (the reference: the original particle demos) |
| Quadcopters | `quadcopter/` | holonomic, in 3D | 35° tilt, ~2.7 s for a 10 m step, motor and controller lag |
| Ground robots (Pioneer 3-AT) | `ground/` | forwards, backwards and turning only | 0.5 m/s, 0.4 rad/s, **no wheel slower than 0.1 m/s** (a smaller command turns it at 0.1, F72) |
| Surface boats (Ch. 6 ASV) | `boat/` | holonomic, on the surface | 12 N thrust (0.79 m/s), 0.3 s thrust lag, water drag |

All four take the same command: reach a point by the next AP tick (5 Hz).
Scale and law are shared: 6 cm per AP unit, spacing D = 3 m, 50 agents
from the same compact launch cluster (1 m apart), 2D triangle; the split
Newtonian law with Ch. 13's η (band 0.2 D, the default) and Lennard-Jones.

**Measures** (`probes/settle_drones.lua`, Ch. 16.9's): *formed*, the time
after AP engages from which the bonds are ≥ 0.97 D and the mean speed
< 0.01 m/s to the end; *bond*, mean pair length within 1.2 D, over D;
*bond CV*, its spread; *gap*, the suggested-position difference
|position − the point AP asked for one tick before| (cm); *crossings*,
pairs changing side of D per agent per minute; *lost*, crashed (only
drones break); *touches*, agent–agent contacts. In task 2: *through*, the
time at which 90% of the swarm is past the field's far edge; *past* and
*near goal*, the shares past it and within 4 D of the goal (Ch. 14's
"reached", Eq. 14.5) at the end. Ranges are over seeds 1–3.

Reproduce: `bash probes/benchmark.sh` (about 90 min on two cores; arguments
choose vehicles, laws and tasks).

## Task 1: formation

From the launch cluster, no obstacles or goal, 180 s.

**Lennard-Jones**

| Vehicle | Formed (s) | Bond | Bond CV | Gap (cm) | Crossings | Lost | Touches |
| --- | --- | --- | --- | --- | --- | --- | --- |
| ideal particles | 31–38 | 1.00–1.01 | 0.000–0.037 | 0 | 0.0–1.5 | 0 | 0 |
| quadcopters | 30–35 | 1.00–1.01 | 0.023–0.034 | 0.002–0.003 | 0.0–0.4 | 6 | 3–9 |
| ground robots | 106–175 | 1.00 | 0.021–0.023 | 0.06–0.15 | 3.0–9.0 | 0 | 5–11 |
| *ground robots before F72 (wheels below 0.1 m/s stopped)* | 32 | 0.98–0.99 | 0.067–0.073 | 1.1 | 0 | 0 | 0–13 |
| boats | 36–42 | 1.00–1.01 | 0.025–0.030 | 0.002–0.008 | 0.4–2.2 | 0 | 0–4 |
| *ground robots without the 0.1 m/s minimum* | 38–39 | 1.00–1.01 | 0.029–0.035 | 0.08–0.11 | 1.5–3.4 | 0 | 2–22 |

**Newtonian with η**

| Vehicle | Formed (s) | Bond | Bond CV | Gap (cm) | Crossings | Lost | Touches |
| --- | --- | --- | --- | --- | --- | --- | --- |
| ideal particles | 72–116 | 0.99 | 0.061–0.074 | 0 | 0.0–2.2 | 0 | 0 |
| quadcopters | 76–96 | 0.99–1.00 | 0.065–0.083 | 0.002–0.03 | 0.0–0.7 | 0 | 0 |
| ground robots | 113–159 | 0.99–1.00 | 0.053–0.076 | 0.04–0.08 | 0.0–1.5 | 0 | 0 |
| *ground robots before F72* | never | 0.89–0.90 | 0.189–0.205 | 1.1 | 0 | 0 | 0 |
| boats | 78–98 | 0.99–1.00 | 0.057–0.065 | 0.003–0.017 | 0.0–1.1 | 0 | 0 |
| *ground robots without the 0.1 m/s minimum* | 96–134 | 1.00 | 0.059–0.074 | 0.12–0.17 | 0.0–1.1 | 0 | 0 |

**3D** (only the drones can): the drones form the LJ lattice in 51–64 s
and the Newtonian one in 45–50 s, at 1.00–1.02 D (bond CV 0.04–0.07),
nothing lost; they take off in thirds, so nothing forms before the last
wave joins ~30 s after AP engages. The ideal particles, all placed at
once, form in 37–46 s and 23–42 s at the same lattices.

## Task 2: goal through obstacles

The default scene (Ch. 3.6 on drones, `quadcopter/README.md`): ~32 columns
over a 36 × 36 m field; 20 s after AP engages the goal switches on and
crosses the field at 0.2 m/s, stopping in the clear 16 m beyond it
(~290 s); runs of 960 s.

| Vehicle | LJ through (s) | LJ past / near goal at 960 s | Newtonian through (s) | Newtonian past / near goal |
| --- | --- | --- | --- | --- |
| ideal particles | 591–666 | 98–100% / 96–98% | 688–763 | 98–100% / 98–100% |
| quadcopters | 601–638 | 100% / 100% | 679–745 | 100% / 100% |
| ground robots | 590–673 | 98–100% / 98% | 632–666 | 98–100% / 98–100% |
| *ground robots before F72* | never | 60–70% / 52–62% | never | 68–80% / 54–70% |
| boats | 698–763 | 98–100% / 86–90% | 688–744 | 98–100% / 98–100% |
| *ground robots without the 0.1 m/s minimum* | 616–680 | 98–100% / 98–100% | 694–778 | 98–100% / 98–100% |

No vehicle touched a column in any run (the margin rule of
`quadcopter/README.md`), and the only losses were the drones' six at the 2D
LJ launch (F59), before the field.

## What it shows

- **The claim holds for the holonomic vehicles.** Quadcopters and boats
  land inside or next to the ideal particles' seed spread in every cell
  of both tasks, with the same lattices; the boats, with a fifth of a
  drone's authority and no tilt to brake with, are at most ~100 s slower
  through the field (LJ). AP's commands are gentle enough (≤ ~1.5 m/s at
  the launch, 0.1–0.2 m/s in the field) for both to follow within
  hundredths of a millimetre to a few tenths of a millimetre per tick.
- **It holds for the ground robots too, once a small move is made at the
  minimum wheel speed rather than not at all.** With the book's 0.1 m/s
  minimum (Fig. 13.7) read as "a slower command stops the wheel", a robot
  stood still whenever the force on it was below
  friction × 0.1 m/s / (metersPerUnit × apHz) = 0.2 AP units, so the
  lattice froze where the forces fell below that (within 1–2% of D for
  LJ, at 0.89 D for the split Newtonian law), and robots caught behind
  columns stayed there (F66, F68). Read as "a slower command turns the
  wheel at 0.1 m/s" (William, F72), the robots reach the particles'
  lattices and get through the field as fast as the ideal particles;
  they count as formed later (106–175 s) because their last corrections
  are made at 0.1 m/s. The one robot left in the field in two of six
  runs is held between two columns 2.6 m apart whose repulsion zones
  overlap, a stable equilibrium of AP itself (the ideal particles are
  held at the same two points; `ground/README.md`).
- **Ch. 13's mechanisms, on the vehicles they were written for.** η is
  what the split law needs on the drones and the boats. On the robots,
  adaptive friction (Eq. 13.23) and static friction (Eq. 13.25) do not get
  the Newtonian lattice to D (F66), and the adaptive speed cap (Eq. 13.24)
  has no collisions to prevent here. None is kept.

## Open

- Tasks 3 and 4 (uniform coverage, chains), and the fixed-wing and
  underwater vehicles, complete the matrix (`BOOK.md` §6).
