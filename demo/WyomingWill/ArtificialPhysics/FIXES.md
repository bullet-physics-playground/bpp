# Artificial Physics demos — fixes list

Issues found while building and examining the demos in this folder
(identical copies live in `demo/WyomingWillJakob/ArtificialPhysics/`).
Items 4 and 5 have been applied to `Uniform_Coverage.lua` in this folder
(not to the WyomingWillJakob copy); none of the others have.

## Behaviour

1. **Headless (CLI) runs do almost nothing** — all three files.
   The `delayMs` throttle in `postSim` compares against `os.clock()`. A CLI
   run (`bpp -f … -n 1500`) finishes in about 0.1 s of CPU, so only a handful
   of ticks pass the throttle and no stats are ever printed.
   *Fix:* skip the throttle when running without a GUI, or default `delayMs`
   to 0 there. Workaround today: append
   `-l 'v:addParam("delayMs",0,0,100,1,"x")'`.

2. **3D Newtonian triangle formation collapses particle pairs** —
   `Formations-Newtonian.lua`, default mode (3D, triangle).
   On every seed tried (1–4), 11–13 pairs end up closer than 0.5·rad, several
   essentially on top of each other; 2D and 3D-square do not. Likely cause:
   repulsion is clamped at `forceMax` = 1.5 while up to ~12 neighbours pull
   inward in 3D, so the summed attraction overpowers a capped repulsion.
   Lennard-Jones never does this. Worth a look at `forceMax`/`G`/`power` for
   3D, or an uncapped (or higher-capped) repulsive branch.

3. **Newtonian swarm never comes to rest.** Mean speed stays ≈ 0.6 (LJ:
   ≈ 0.002). Expected from the split law — |F| flips sign at `rad` instead of
   vanishing — so this is a property of the law, not a bug; noted because it
   matters for anything that follows the particles (e.g. robots).

4. **Uniform Coverage neighbour check is one-sided** — `shouldTurn()`.
   `diff = (angleToOther - heading) % 360; if diff < 30` only looks 0–30°
   counter-clockwise of the heading. Ported verbatim from the Kotlin, so the
   original app has it too.
   **APPLIED as a centred cone of the same width:** `diff < 15 or diff > 345`.
   The first proposal, `diff < 30 or diff > 330` (±30°), was rejected by the
   benchmark below: it doubles the cone, so agents turn away from neighbours
   twice as often, and at 25 agents / MFP 60 that is 13% worse (20 seeds,
   t = 2.4; extra turns shift coverage from the centre to the corners).

5. **Uniform Coverage turn loop drops a valid move** — `moveAgent()`.
   After the 9th heading re-pick `tries` reaches 10 and the loop exits without
   re-testing, so the agent skips its step (and its cell count) even when the
   last heading was clear. Also verbatim from the original.
   **APPLIED:** still at most 9 re-picks, but the last one is tested. Stalled
   moves drop from ~5.5e-5 to ~3e-5 of all moves (the rest are genuinely
   boxed-in agents).

   **Benchmark** (headless, the script's own `setup`/`moveAgent`/
   `uniformityDeviation`, no drawing). Agents {1, 5, 10, 25, 50, 100} ×
   MFP {1, 5, 10, 17, 30, 60, 120}, 5 seeds each, equal budgets (2M
   agent-steps up to 10 agents, 1M at 25, 0.5M at 50/100). Deviation of the
   variant relative to the verbatim code:

   | Variant | Geometric-mean ratio | Significantly better (t < −2) | Significantly worse (t > 2) |
   | --- | --- | --- | --- |
   | dead-end fix only | 0.981 | 3 of 42 | none |
   | **dead-end fix + ±15° cone (applied)** | **0.974** | 1 of 35 | **none** |
   | dead-end fix + ±30° cone | 0.934 | 5 of 42 | 25/60 on retest |

   Configurations that looked worse at 5 seeds were rerun with 20 seeds.
   At 25 agents / MFP 60 the ratios were: dead-end only 0.98, ±15° 1.02
   (t = 0.4), ±30° 1.13 (t = 2.4). With 1 agent the cone cannot matter, so
   that row isolates the dead-end fix: identical to within 0.3%. Long runs
   at 10 agents / MFP 17 (4M ticks, 3 seeds) were all within noise, at
   0.0016–0.0022 and still falling roughly as 1/√ticks. The ±30° cone is the
   better choice on average (up to 33% better, e.g. 25 agents / MFP 5), if
   one loss is acceptable.

6. **Uniform Coverage statistics are slightly off-normalised.** `setup()`
   calls `monitorAgent()` once per agent, and stalled agents (item 5) are not
   counted, so `sum(cellCounts) ≠ ticks · #agents`. Negligible after a few
   hundred ticks.

## Comments / docs

7. Headers in both Formations files refer to `ap-newtonian.lua` /
   `ap-lennardjones.lua`, which no longer exist (now
   `Formations-Newtonian.lua` / `Formations-Lennard-Jones.lua`).
8. `Formations-Newtonian.lua` says `applyDefaults()` is "called once at load";
   it only runs on a dimension (2/3) or formation (F) toggle. Harmless — the
   initial `setParam` values equal the 3D-triangle defaults.
9. `Formations-Newtonian.lua` lines 302–307 repeat the same comment twice.
10. `Uniform_Coverage.lua`: the `numParticles` slider comment still mentions
    the removed R shortcut; `categorySpread()` computes an unused `mean`; the
    header's CLI example names `uniform-coverage.lua`.
11. `demo/README.md` describes `WyomingWill/` only as linkage walkers and
    does not mention `ArtificialPhysics/`; `demo/WyomingWill/README.md` does
    not list these three files.

## Usability

12. The formation spawns at x ≈ +233 (`WORLD_WIDTH/3`) while the camera
    looks at the origin, so the lattice sits in a corner of the view.
13. Particle spheres have radius 1 against a spacing of 50, so in the GUI you
    mostly see neighbour lines rather than particles.
14. `Uniform_Coverage.lua` does not call `v:setHelpText()`, so the Shortcuts
    panel stays empty (the Formations files fill it).

## Performance

15. **Visual-only objects should leave collision entirely.** The demos mark
    markers, cursor gizmos and neighbour-line cylinders with
    `CF_NO_CONTACT_RESPONSE`, but Bullet still pairs and narrow-phase tests
    such objects every step (no response is not no test). Setting
    `obj.collides = false` *before* `v:add(obj)` takes them out of every
    collision group instead. Measured while building the quadcopter version:
    a GImpact mesh riding on a box hull cost ~1.5 ms per step with
    `NO_CONTACT_RESPONSE`, ~1.5 µs with `collides = false`. For the primitive
    spheres/cylinders in these files the saving is smaller but the same fix
    applies (`noCollideStatic`, `noCollideKinematic`).

## BPP itself (outside this folder)

16. **`btCylinderShape` (Y axis) has no Lua constructor.** In
    `src/lua_bullet_2.cpp` the `btCylinderShape` class is bound without a
    `.def(constructor<const btVector3 &>())`, while `btCylinderShapeX` and
    `btCylinderShapeZ` have one, so `btCylinderShape(btVector3(...))` fails
    with "attempt to call a nil value". The quadcopter hull uses a box
    instead. *Fix:* add the constructor line to the `btCylinderShape` block.

## Findings from the quadcopter version (not bugs; worth knowing)

Measured with `Formations-*-Quadcopter.lua` (each AP particle replaced by a
physically modelled quadcopter; see `quadcopter/README.md`).

17. **The split Newtonian law does not crystallise on real drones.** With
    perfect tracking the quadcopter coupling reproduces the original exactly
    (2D triangle: bonds 1.000R, sd 0.007R after ~2600 AP ticks). With the
    flight dynamics in the loop the 2D lattice stays at sd ≈ 0.07–0.10R and
    the drones never stop (0.3–0.5 m/s), because the force flips sign at
    `rad` and the drones' ~0.1–0.2 s response keeps overshooting across it.
    Stiffer flight-controller gains do not help (sd 0.098R, more tilt); a
    slower AP rate does (5 Hz: 0.069R). Lennard-Jones is unaffected
    (2D: 1.000R, sd 0.003R on real drones).
18. **…but real drones remove the 3D Newtonian collapse** (item 2): with
    flight dynamics no pair ends up closer than 0.5·rad, versus 3–13 pairs
    with ideal tracking or in the original.
19. **AP's obstacle repulsion margin must exceed a drone's stopping
    distance.** AP particles stop instantly; a 1.5 kg quad at 2 m/s needs
    ~0.5 m. With the solid obstacle at half the repulsion radius, drones flew
    into poles; at a third, none did.
20. **Strong goal attraction beats capped repulsion.** At `goalForce` 0.6
    the swarm squeezing past obstacles drives pairs into contact even with
    perfect tracking (49 of 51 drones lost to prop strikes) — the original
    particles would simply overlap. At the default 0.25 with AP at 10 Hz,
    6 drones were lost to flight lag; at 5 Hz, none.
21. **A compact launch costs a few drones in 2D, and it is AP's doing.**
    The quadcopter demos now start like the originals: a compact random
    cluster, drones at least 1 m apart. (The first version launched from a
    3 m grid, which is already nearly the final lattice and made the 3D cube
    come out far too spread out, with 41 bonds instead of 80.) In 3D no
    drones collide. In 2D, AP's first expansion pushes some pairs within a
    drone's width 1.5–5 s after AP engages. Repulsion is capped at
    `forceMax`/`forceMaximum`, and neighbours behind can outpush it.
    - With ideal drones (perfect tracking) the same pairs still collide
      (LJ 2D: 4 and 6 strikes), so the original particles overlap there too.
    - Over 3 seeds, 2 min, 150 drones per cell:

      | Variant | LJ triangle lost | LJ square lost | Newtonian square lost |
      | --- | --- | --- | --- |
      | 1.0 m spacing | 12 | 13 | 11 |
      | 1.5 m spacing | 2 | 8 | 0 |
      | 1.0 m, repulsion cap 3 | 20 | 34 | — |

    Possible fixes, not applied: a looser start, or a short-range collision
    avoidance layer beneath AP (as real drones carry).

22. **The first quadcopter version launched with striped spins.** On a pad
    grid with an even number of columns, numbered row by row, id % 2
    alternates along rows but each drone's vertical neighbour has the same
    spin. In square formation same-spin pairs want √2·R, so the grid had to
    tear itself apart and re-sort. The random-cluster launch removes this.

23. **Square formations sort out slowly, drones or not.** From a random
    cluster the spin checkerboard has to form by rearrangement. LJ 2D
    square on drones keeps moving for 30–40 s, then settles to 0.01 m/s,
    with defects annealing over minutes (bonds 43 → 62 over 3 min). The
    original particles behave the same way:

    | AP ticks | sd | particles with all 4 square neighbours (of 50) |
    | --- | --- | --- |
    | 150 | 0.052 R | 6 |
    | 600 | 0.027 R | 14 |
    | 2000 | 0.028 R | 18 |

## BPP additions made for the quadcopter demos

24. `src/objects/cam.cpp` / `cam.h`: `v.cam.dir`, the live view direction
    (read-only; `v.cam.look` only returns what a script last set), and
    `v.cam.pivot`, the point mouse orbiting turns around (read/write). The
    quadcopter camera follows the swarm by translation only, so the user's
    mouse angle is kept, and moves the pivot with it. The demos run without
    these; orbiting then turns around the world origin.
25. `src/viewer.*`, `src/gui.*`: `v.statusText`, a one-line script status
    in the status bar beside the frame counter. It is a permanent label, so
    BPP's own status messages don't cover it. It is hidden when a script
    never sets it, ignores repeats of the same text, and is cleared when a
    new script loads. The quadcopter demos show their mode there, so the
    Shortcuts pane keeps a static key list. A separate "Info" dock for
    several lines of live state is an idea for later.
