# Artificial Physics demos — fixes list

Issues found while building and examining the demos in this folder
(identical copies live in `demo/WyomingWillJakob/ArtificialPhysics/`).
None of these have been applied to the original files yet.

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
   counter-clockwise of the heading, not ±30°. Ported verbatim from the
   Kotlin, so the original app has it too. *Fix:* `if diff < 30 or diff > 330`.

5. **Uniform Coverage turn loop drops a valid move** — `moveAgent()`.
   After the 9th heading re-pick `tries` reaches 10 and the loop exits without
   re-testing, so the agent skips its step (and its cell count) even when the
   last heading was clear. Also verbatim from the original.

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
21. **Launching from a dense grid is dangerous.** From a 1.5 m pad grid,
    AP's first expansion caused 5–8 collisions within 4 s; from a 3 m (= R)
    grid, none.
