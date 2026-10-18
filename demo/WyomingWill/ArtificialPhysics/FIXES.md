# Artificial Physics demos — fixes list

Issues found while building and examining the demos in this folder
(identical copies live in `demo/WyomingWillJakob/ArtificialPhysics/`).
Items 4 and 5 have been applied to `Uniform_Coverage.lua` and items 2 and 8
to `Formations-Newtonian.lua` in this folder (not to the WyomingWillJakob
copies); the others are not applied unless marked.

## Behaviour

1. **Headless (CLI) runs do almost nothing** — all three files.
   The `delayMs` throttle in `postSim` compares against `os.clock()`. A CLI
   run (`bpp -f … -n 1500`) finishes in about 0.1 s of CPU, so only a handful
   of ticks pass the throttle and no stats are ever printed.
   *Fix:* skip the throttle when running without a GUI, or default `delayMs`
   to 0 there. Workaround today: append
   `-l 'v:addParam("delayMs",0,0,100,1,"x")'`.
   `lib/batch.py` does this for every run.

2. **3D Newtonian triangle formation collapses particle pairs** —
   `Formations-Newtonian.lua`, default mode (3D, triangle).
   On every seed tried (1–4), 11–13 pairs end up closer than 0.5·rad, several
   essentially on top of each other; 2D and 3D-square do not. Likely cause:
   repulsion is clamped at `forceMax` = 1.5 while up to ~12 neighbours pull
   inward in 3D, so the summed attraction overpowers a capped repulsion.
   Lennard-Jones never does this.
   **APPLIED (item 30):** the 3D-triangle defaults are now range 1.25 and
   forceMax 5. The cause is two-fold. The 3D triangle lattice is close
   packing, whose second neighbour shell is at √2·rad = 1.41 rad, inside
   the old range of 1.5, so it was pulled in. And a cap of 1.5 can't hold
   off 12+ neighbours pulling at once. Collapsed pairs 16/12/13 → 0/0/0.

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
   **APPLIED:** it now runs at load, so the 3D-triangle defaults of item 30
   take effect without pressing 2/3 or F.
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
26. **Sliders missing after switching scripts (fixed in `src/viewer.cpp`).**
    `v:showParams(prefix)` makes the Parameters pane show only sliders whose
    names start with `prefix`. The Cabinet uses it ("Cabinet: ", then each
    exhibit's prefix). The filter was never reset when another script was
    loaded, so after visiting the Cabinet every script opened later in the
    same session showed an empty Parameters pane. The sliders existed but
    were filtered out, until BPP was restarted. Now `clearParams()` and
    `clear()` (every load, reload and restart) reset the filter and the old
    script's slider ranges. The Cabinet is unaffected: it sets its filter
    again when it starts, including after Restart.
27. **Rebuilding on another day can make gcc read the executable as C++.**
    (Not fixed.) `bpp.pro` passes `BUILDDATE`/`BUILDTIME` as `-D` flags to
    every file, and the precompiled header `release/bpp.gch` is rebuilt only
    when `src/pch.h` changes. After re-running `qmake` on a different day,
    gcc rejects the old precompiled header ("not used because `BUILDDATE'
    defined as ..."). It then falls back to `-include release/bpp`, and on
    Linux that is the bpp executable. The result is hundreds of thousands
    of "stray '\177'" errors and a log growing by gigabytes. Workaround:
    `rm -rf release/bpp.gch` before `make`, or `make clean`. Possible fixes:
    give the macros to `gui.cpp` alone (the About box is their only use),
    or make the precompiled header depend on the Makefile.
28. **The Open/Save dialog sometimes appeared behind the BPP window (fixed in
    `src/code.cpp`).** The script dialogs were owned by the script editor
    widget, so their owner window was whichever window held the editor.
    That is the main window normally, but it is the separate window of the
    "LUA Script" pane once that pane has been undocked. A dialog owned by
    the floating pane is kept in front of that pane only, so it could slip
    behind the main window as soon as the main window came forward. Checked
    on X11 (`WM_TRANSIENT_FOR`): docked, the dialog belonged to the main
    window; floating, to the "LUA Script" window. The dialogs now always
    belong to the main window. Two other things can still put a window in
    front of a dialog: a floating Parameters pane is deliberately set to
    stay on top, and on some Windows/OpenGL drivers a full-screen BPP window
    (View → Fullscreen, remembered between sessions) is drawn over popups.
29. **Obstacle field for the quadcopter demos, and a gentler obstacle
    law.** `quadcopter/swarm.lua` can now scatter random columns (radius
    0.3–1.4 m, `fieldDensity` per 100 m², at least 2.5 m apart) between the
    launch area and the goal. The goal switches on by itself `goalDelay` s
    after AP engages, travels through the field at `goalSpeed`, and stops
    beyond it. Untick `obstacleField` for the old empty sky.
    - **The originals' obstacle law is too stiff for drones.** `size − r`
      in AP units, with field-sized columns (repulsion 30–50 units deep at
      6 cm per unit), gave forces of 20–40 against a drone-to-drone cap of
      1–1.5. AP commanded 4–7 m/s, and drones arriving at 2.9 m/s hit
      columns and each other. That cost 12–21 of 50 drones per crossing,
      in all four law/dimension combinations.
    - **The fix:** force = 2 units per metre of penetration, capped at 4.
      Losses in the field dropped to 0 over 7 crossings (LJ 2D ×3, LJ 3D
      ×2, Newtonian 2D ×2, including square). The 2D losses that remain
      (2–6) all happen 9–12 s in, during the launch expansion (item 21),
      before the goal is on.
    - **Newtonian 3D** still loses 2–12. It does so with no field too, and
      even with no goal (0 and 3 on two seeds over 3 min). That is item 2's
      3D collapse; an earlier "0 lost" for that mode came from one seed.
30. **3D triangle: collapse fixed, and optional flight levels.**
    `Formations-Newtonian.lua`, `Formations-Lennard-Jones.lua`, and the
    quadcopter versions.

    **Geometry.** The 3D relative of the triangular lattice is close
    packing: flat triangular layers stacked √(2/3)·R ≈ 0.82 R apart, each in
    the hollows of the one below. That gives 12 neighbours at R; the next
    shell is at √2·R = 1.41 R. In 2D the hexagon works because range 1.5 R
    sits between the first shell (R) and the second (1.73 R). In 3D, range
    1.5 R reaches the √2 shell.

    **Newtonian 3D triangle defaults: range 1.25, forceMax 5.** Original
    particles, 3 seeds, 4000 ticks:

    | Setting | Collapsed pairs (< R/2) | Most neighbours within 1.2 R |
    | --- | --- | --- |
    | range 1.5, forceMax 1.5 (old) | 16 / 12 / 13 | 25 (impossible; 12 can touch) |
    | range 1.25 | 1 / 0 / 1 | 15 |
    | forceMax 5 | 0 / 0 / 0 | 20 |
    | range 1.25 + forceMax 5 (new) | 0 / 0 / 0 | 13 |

    Lennard-Jones doesn't collapse, so its force law and cap are unchanged.

    **Flight levels (`layerGain`, 3D triangle only).** Even without
    collapse, the 3D "triangle" froze as a glass, with no tiling. Nearest-
    neighbour forces can't choose between the two close-packed stackings,
    50 particles is too few for a crystal (small Lennard-Jones clusters
    prefer icosahedra), and nothing shakes the swarm out of its first
    arrangement. Flight levels add a soft vertical pull toward horizontal
    levels √(2/3)·R apart, `layerGain` × the distance. The levels' height
    offset is taken from the swarm itself (circular mean of height modulo
    the spacing), so there's no fixed altitude. The ordinary force law
    then makes a triangular lattice within each level, and puts each level
    over the hollows of the next. Original particles, 3 seeds:
    - **Newtonian, layerGain 0.1:** 49–50 of 50 on 4–5 levels (old
      defaults: 19–22). In-level second neighbours at √3·R rose to up to
      3.7 per particle (3 = a perfect sheet).
    - **Lennard-Jones, layerGain 0.05:** 50 of 50 on 5 levels, √3 pairs
      3.7–4.0 per particle.

    **Lennard-Jones stays fluid.** Rearrangement over 500 ticks while the
    goal pulls the swarm (3 seeds each):

    | Setting | Mobility |
    | --- | --- |
    | Lennard-Jones, no levels | 0.15 R |
    | Lennard-Jones, levels 0.05 / 0.1 | 0.10 / 0.13 R |
    | Newtonian, new defaults / with levels | 0.06 / 0.05 R |

    **Defaults:** levels on in 3D triangle for both laws: 0.1 for
    Newtonian, 0.05 for Lennard-Jones. At 0.05 Lennard-Jones rearranged a
    little less under the goal's pull (0.10 vs 0.15 R, within the
    seed-to-seed spread) but stayed 2–3 times as mobile as Newtonian.
    Set `layerGain` to 0 for the old behaviour.

    **On drones** (quadcopter demos, same defaults):
    - **Newtonian 3D triangle, no field, goal on, 3 seeds:** 0 / 0 / 0
      lost (before: 2 and 6 on seeds 1 and 2), all 50 on levels.
    - **Newtonian 3D, field crossing, 2 seeds:** 1 / 0 lost (before: 12).
    - **Lennard-Jones 3D, levels 0.05, field crossing, 2 seeds:** 0 / 0
      lost, all on levels. 42 and 45 drones were through the field at
      570 s, at least as fast as without levels.

31. **Drone sound: synthesised voices in BPP (`src/synth.h/.cpp`, `src/viewer.cpp`).**
    BPP could only play one-shot sound files (`loadSound`/`playSound`), with
    no pitch control and no looping. A rotor's pitch and loudness change
    every frame, so BPP now has up to 24 continuous synthesised voices,
    set from Lua:

    - `v:setTone(voice, freq, amp [, pan])`: voice 1..24, Hz, 0..1, -1..1.
    - `v:setToneTimbre(voice, brightness, noise)`: 0 = pure sine .. 1 =
      buzzy; level of a whooshing noise band chopped at the pitch.
    - `v:silenceTones()`.

    Each voice glides to new settings over ~30 ms, so updates once a frame
    don't click. The voices are mixed after SDL_mixer's own channels
    (`Mix_SetPostMix`), so `playSound()` effects still play on top. They
    hush while the simulation is stopped and when a new script loads. They
    are also written into the exported `.wav`. With no audio device they
    are silent no-ops.

    `quadcopter/sound.lua` drives them from the motor speeds (see the
    quadcopter README). Checked from exported tracks:

    - **Hover:** 179–185 Hz, against ~181 Hz expected.
    - **Takeoff climb:** 192–198 Hz, and louder than hover.
    - **Levels:** −18 dBFS RMS at a close-up camera, peaks 0.6. Clipping
      can't happen: the output passes a soft limiter.

    **Follow-ups:**

    - **Pause:** the voices kept humming while the simulation was paused.
      The gate followed the viewer's animation timer, but BPP's pause (S,
      the toolbar button) leaves that timer running and clears the
      simulate flag instead. The gate now follows
      `simulationStateChanged`. Checked by capturing the live output with
      SDL's disk audio driver: the output drops to silence while paused
      and returns on resume.
    - **Emphasis** (`soundEmphasis`): drones that stand out from the
      swarm get their own voices and are up to 12 dB louder, and a
      settled swarm drops to a hum. See the quadcopter README.

32. **3D cube: no recognisable lattice, with drones or particles. Fixed
    with flight levels one spacing apart.**
    The binary-spin cube does form, but slowly, and it settles at an
    arbitrary tilt with defects. Measured as the share of angles between
    neighbours that are square (90° or 180°), 50 members, three seeds per
    law:

    - **Particles, after 750 ticks:** Newtonian 71 / 74 / 80%,
      Lennard-Jones 88 / 79 / 79%. Some seeds never finish: Newtonian
      seed 2 still 71% at 3,000 ticks.
    - **Drones:** no worse than the particles at the same tick count. At
      5 AP ticks a second, 750 ticks is 150 s, and the goal switches on at
      20 s, long before the cube has formed.
    - **Downwash:** not the cause. Turning it off didn't help.

    **Fix:** the flight levels of item 30, spaced one spacing apart in
    cube mode. Each level forms a 2D square lattice (which works well)
    and the levels stack straight up. `layerGain` 0.05 for both laws
    (Newtonian's `DEFAULTS_BY_MODE` 3DSquare, both quadcopter demos):

    - **Particles at 750 ticks:** Newtonian 95 / 78 / 98%, Lennard-Jones
      96 / 97 / 93%.
    - **Drones, Lennard-Jones:** 95% at 150 s with no goal (was 87%),
      96–98% at 90–120 s with the goal and obstacle field (was 76–80%).
    - **Drones, Newtonian:** 85% with no goal, 72–80% with the goal (was
      59–67%). It never stops jostling.
    - **Gain 0.1:** no better, and it over-packs Newtonian.

    **Still to note:** the cube's orientation about the vertical is
    arbitrary, so from above the grid sits at a random angle. One Lennard-
    Jones drone run flattened into two full levels of about 20 with a few
    drones above and below, rather than a 4×4×3 block.

33. **3D launches: launch order matters. Thirds, top level first, is now
    the 3D default.**
    The initial setup decides a lot. A new `launchOrder` setting
    (quadcopter demos) launches:

    - all at once (the original);
    - in thirds, `launchGap` (15) s apart: top level first, bottom level
      first, or each third to random heights;
    - one drone at a time, over the same total time.

    AP starts when the first group is up, and later drones join as they
    arrive. `goalDelay` now counts from when the last drone joined.

    50 drones, 3 seeds per order per law, flight levels on (items 30 and
    32). At 150 s: the cube's share of square angles between neighbours,
    and the triangle's share of triangle angles (60°, 120°, 180°) within a
    level. "Lost" counts all three runs together.

    **No goal:**

    | Order | Cube, Lennard-Jones | Cube, Newtonian | Triangle, Lennard-Jones | Triangle, Newtonian |
    | --- | --- | --- | --- | --- |
    | all at once | 99 / 91 / 97% | 82 / 93 / 70% | 88 / 98 / 98% | 90 / 79 / 76% |
    | thirds, top first | 91 / 88 / 94% | 90 / 95 / 95% | 95 / 96 / 73% | 81 / 79 / 89% |
    | thirds, bottom first | 87 / 83 / 93%, 5 lost | 75 / 91 / 91%, 4 lost | 65 / 68 / 77%, 8 lost | 64 / 60 / 84% |
    | thirds, random heights | 99 / 86 / 91% | 77 / 75 / 95%, 2 lost | 78 / 97 / 96%, 4 lost | 96 / 95 / 84% |
    | one at a time | 93 / 92 / 88%, 4 lost | 65 / 89 / 83%, 4 lost | 83 / 86 / 89%, 8 lost | 78 / 85 / 63% |

    **Goal and obstacle field on.** The goal starts later after a staged
    launch, so top first at 150 s is compared with all at once at 120 s.
    Both have then been under the goal for about 90 s:

    | Order | Cube, Lennard-Jones | Cube, Newtonian | Triangle, Lennard-Jones | Triangle, Newtonian |
    | --- | --- | --- | --- | --- |
    | all at once | 97 / 81 / 69% | 71 / 69 / 61% | 92 / 85 / 75% | 91 / 78 / 70% |
    | thirds, top first | 86 / 88 / 90% | 76 / 100 / 89% | 89 / 84 / 95% | 87 / 73 / 86% |

    **Conclusions:**

    - **Shape:** top first is the only order that gives three even levels
      every time (16 / 17 / 17), in both formations. All at once makes
      lopsided stacks such as 2 / 19 / 25 / 4.
    - **Safety:** top first never lost a drone.
    - **Lattice quality:** about the same as all at once overall, but
      without the bad runs. The exception is the Newtonian cube, where top
      first is clearly better.
    - **Bottom first and one at a time:** later drones climb up through
      the levels already formed and lose drones.

    Default `launchOrder` 1 in 3D, 0 in 2D (set on 2/3 and F; press R to
    relaunch).

## Shared code (milestone M0)

34. **Every demo now draws from one seedable generator (`lib/rng.lua`).**
    The formations and `quadcopter/swarm.lua` called `math.random`, which in
    BPP's Lua 5.1 is glibc `rand()`, the generator the book's appendix shows
    to be biased, and every script seeded from `os.time()`, so no run could
    be repeated (and the probes' `math.randomseed` came after the launch had
    already drawn its positions). The multiply-with-carry generator from
    `Uniform_Coverage.lua` is now `lib/rng.lua`, used by Uniform Coverage,
    both formations, the quadcopter harness and the probes.
    - **Seed:** the `SEED` environment variable, else a new `seed` parameter,
      else the clock. 0 (the default) keeps the old behaviour: a new seed
      each load. The seed used is printed (`rng: MWC seed=…`).
    - **Setup (R)** restarts the stream from a fixed seed, so it repeats the
      same start; with seed 0 it carries on as before. Moving the seed
      slider restarts the scene from the new seed at once.
    - **The seed slider runs 0–1000.** It first ran to 2³¹ − 1 and would not
      move: BPP keeps parameter ranges as floats and turns them into an
      integer slider, so that maximum overflowed it. Larger seeds still
      work through `SEED`.
    - **Uniform Coverage now binds R** to a new scatter with the current
      settings, as the formations do. Before, R was BPP's own reload, which
      resets every slider to its default. BPP's toolbar restart, which
      restores the sliders after reloading, also restarts from the seed.
    - **Measured:** Uniform Coverage at seed 12345 prints exactly what the
      old code printed with `mwcSeed(12345)` over 3000 ticks. Same seed, same
      result for Uniform Coverage, both particle formations (1500 ticks) and
      both drone swarms (900 frames, Bullet included); a different seed
      gives a different run.
    - `checks/rng_appendix.lua` keeps Listing A.1 as a test: the shared
      generator stays under the 99.9% cut (66.6) at every S (χ² 26–47);
      `math.random` fails at S = 3 (70), 25 (321), 26 (223) and 27 (409).
    - Drone results in `quadcopter/README.md` were measured with
      `math.random`; they are statistics over seeds and should hold, but
      the individual runs will not repeat bit for bit.

35. **`probes/cube_orig.lua` no longer runs** (documented, not fixed). It
    reads a global `PARAM_INFO` that the particle formations now keep local
    (`attempt to index global 'PARAM_INFO'`). Not caused by item 34; it
    fails the same way on the code before it.

36. **Uniform Coverage senses walls differently from NetLogo, and keeps
    doing so (decision, not a bug).** NetLogo's `uniform_mfpl.nlogo` turns
    when the patch 1 ahead, or either patch 2 away at ±45°, is wall (the
    yellow ring at 42), so robots turn up to ~2 units early and also when
    gliding obliquely near a wall. The Android app, and BPP from it, looks
    0.0001 ahead and turns only on touching the boundary at 40.
    - **Measured** (1 agent, 10⁷ ticks, 2 seeds; converged, seeds within 1%):
      with NetLogo's rule BPP gives 0.0074 / 0.0227 / 0.0271 at MFP 30 / 50
      / 100, reproducing NetLogo's own 0.0072 / 0.023 / 0.026. The Android
      rule gives 0.0035 / 0.0158 / 0.0368: better at every useful MFP (the
      theory value is 17⅓), worse only at 100.
    - This is a far larger effect than items 4 and 5, which together move
      deviation by ~3%; that is why BPP and Android agree closely.
    - **Decision (William, 2026-10-17):** NetLogo is not maintained; keep
      the Android/BPP rule.

37. **Status-line numbers shifted left and right as they changed** (found by
    William). Two causes: numbers changed length (`%.4g` gives 5 to 9
    characters), and the line used a proportional font.
    - `src/gui.cpp`: the script status label (`v.statusText`) uses the
      system's fixed-pitch font. Needs a rebuild (no qmake).
    - `ch02/scene.lua`: every number in a fixed-width field
      (`scene.fixed`): plain decimals while they fit, scientific notation
      only when too small or too large to show; signed only where a value
      can change sign.
    - `quadcopter/swarm.lua`: counts and statistics padded to fixed widths,
      the goal state padded, and the bond statistics moved before the parts
      that appear and disappear (drone states, wind, flags), with a
      same-width placeholder before the first statistics arrive.
