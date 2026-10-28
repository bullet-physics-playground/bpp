# Handoff: Physicomimetics in BPP

Read this first in a new chat. It says who William is, how he likes to work,
where everything is, how to build and measure, and what to do next. The plan
is `BOOK.md` (what to build, in what order) and `WORKFLOW.md` (how). This file
is updated at the end of every milestone.

## 1. Who and what

- William M. Spears, co-author of *Physicomimetics: Physics-Based Swarm
  Intelligence* (Springer 2011). Artificial Physics (AP) is his research.
- Repository: **github.com/bullet-physics-playground/bpp** (BPP), branch
  `master`. Qt5, QGLViewer, Bullet, Lua 5.1 or 5.2 (by build) + luabind, SDL2_mixer.
- This folder, `demo/WyomingWill/ArtificialPhysics/`, holds the AP work.
- **The aim of the research:** large-swarm results with few agents. Prefer
  metrics that show it, such as time to a target quality against N (agents
  that are nearly independent should scale as 1/N).
- **The goal:** convert the whole book into BPP simulations, first as 2D
  particle replicas that reproduce the book's numbers, then on physically
  modelled vehicles, then in 3D, ending in a capstone mission flown by five
  kinds of vehicle (`BOOK.md` §6).

## 2. How William likes to work

- **Simplicity and elegance are part of the project** (William,
  2026-10-18; in the spirit of Edward Teller, *The Pursuit of Simplicity*,
  Pepperdine University Press, 1980: science as the search for the simple,
  elegant description underneath). Physicomimetics exists because the alternative did not
  scale: before AP, groups used complex control theory and reached about
  three robots. A simulation with too many variables and controls has given
  up simplicity; we want the simplest way to do a thing well. William's
  chain formations once had more than 20 variables; the method used now has
  a handful, and it works better. So:
  - Add a tool (a slider, a mechanism, a rule) only when a measurement shows
    it is needed, and say *where and when* it is needed (which vehicle,
    which sensing, which task). Off by default, and never all of them on at
    once just because they exist.
  - Prefer a rule that follows from the physics or the geometry to a knob
    to tune (e.g. η's band set from the law and the spacing, F50); prefer
    one switch to several; fix a constant and state it rather than expose
    it.
  - When a tool turns out not to help, say so in `FINDINGS.md` and leave it
    off, or take it out.
- **Deliver changes as a patch plus the full git commands**
  (`git am ~/Downloads/<name>.patch`, then build if C++ changed, then
  `git push origin master`). He applies and pushes them himself. Fetch first
  and check every patch applies cleanly to the current `origin/master`; master
  moves. If an earlier patch hasn't been applied yet, fold it into the new one
  and say so.
- **Read the full diff of every commit before making it**, and stage only
  the files you changed. Another session can edit the same checkout; a
  "changed on disk" notice on a file is a warning (FINDINGS F39).
- Say whether a rebuild is needed. Lua-only patches need none. New C++ files
  need `qmake` re-run (the .pro globs `src/*.cpp` at qmake time). He builds the
  **debug** config (`debug/.obj`), so give `rm -rf debug/bpp.gch release/bpp.gch`
  when qmake is re-run.
- Commits are authored as `William M. Spears <williammspears@gmail.com>` with a
  `Co-Authored-By` trailer for Claude.
- **Measure before claiming.** Several seeds, like compared with like, and
  correct earlier claims when new measurements disagree.
- When he asks for an analysis ("no code yet"), give analysis only.
- Experiments that change behaviour are switchable, with the old behaviour at 0.
- **Every script states its definitions near the top:** each quantity it
  shows or prints (status line, output columns, sliders), with its formula,
  units and sign convention, so a reader never has to search the code for
  what a number means (William, 2026-10-17).
- No text drawn on the graphics pane. **Design decision (William,
  2026-10-17): every simulation shows its most important information on the
  status line at the bottom of the window** (`v.statusText`), one line where
  only the numbers change, built with `lib/status.lua`: `label=value` with
  the padding *after* the value (units with the number), fixed-width fields
  separated by ` | `, parts that come and go last (BPP shows the line in a
  fixed-pitch font; FIXES 37). Console output stays for logs and
  `lib/batch.py`. Cameras
  start at a useful view and are never locked.
- Lennard-Jones should stay more fluid than Newtonian, even in formation.
- **When `BOOK.md` or `WORKFLOW.md` changes, rebuild its PDF** with
  `tools/md2pdf.py` (§5) and include the PDF in the same patch. Look at the
  pages before sending: no nearly empty pages, build order on one page.
- Keep `FIXES.md` (items 1–43 so far) and the task READMEs up to date.
- **Keep `FINDINGS.md` up to date** in every patch that finds something: each
  confirmation of the book, new result, book error, divergence between
  implementations, and our own mistakes once corrected (F1–F91 so far), and
  rebuild `FINDINGS.pdf` (§5).

## 3. Where everything is

| Path | What |
| --- | --- |
| `BOOK.md`, `BOOK.pdf` | The map of all 182 book entries, ideas, groundwork G1–G21, the capstone, the chain-fountain escape, the build order. Also the progress tracker |
| `WORKFLOW.md`, `WORKFLOW.pdf` | Folders, the steps every task goes through, milestones |
| `book/ch01.md` … `ch20-appendix.md` | Notes per chapter: algorithms, parameters, results to reproduce with page refs, decisions the book leaves open |
| `book/theses/` | Digests of the seven theses (Heil, Hettiarachchi, Kerr, Kunkel, Maxim, Rebguns, Zarzhitsky) |
| `probes/` | Measurement probes from the quadcopter work (set `PROBES` to this folder); `settle_drones.lua` measures settling with the Ch. 16.9 metrics for `lib/batch.py` |
| `tools/md2pdf.py` | Typesets the plan files as PDFs |
| `tools/worldprint.lua` | Prints a generated world in full (every layer's data, every drawn triangle), in any Lua 5.1-5.4 without BPP: compare prints before and after a change to the generator (FIXES 42) |
| `src/geo.cpp` (BPP's, at the repository root) | BPP's compiled helpers for the world generator (the Lua table `geo`: noise, zone lookup, the ground's and the woods' meshes), the Lua's arithmetic operation for operation; `checks/geo.lua` compares the two (FIXES 43, F71) |
| `Formations-*.lua`, `quadcopter/` | Particle formations, and the same flown by quadcopters (`quadcopter/README.md` has the measurements) |
| `Formations-*-Ground.lua`, `ground/`; `Formations-*-Boat.lua`, `boat/` | The same formations on the Pioneer 3-AT ground robot and the Ch. 6 surface boat (each folder's README has the vehicle and its measurements) |
| `ch13/`, `fixedwing/` | Ch. 13's constrained vehicles: the fixed-wing UAV (kinematic, 13 m/s, 101 m turns) with the point-mass and torque laws (`UAV-Attractor.lua`, `UAV-Targets.lua`; F76) |
| `BENCHMARK.md` | The cross-vehicle benchmark: the same tasks and laws on ideal particles, drones, ground robots and boats (reproduce with `probes/benchmark.sh`) |
| `Uniform_Coverage.lua` | Mean-free-path coverage, with the neighbour-cone and dead-end fixes (its random number generator is now `lib/rng.lua`) |
| `FIXES.md` | Fixes 1–43 |
| `FINDINGS.md`, `FINDINGS.pdf` | The running record of experiments: confirmations, new results, errors (ours and the book's) |
| `ch02/` | Ch. 2's springs and solar system, plus our spring3D, tetrahedron, planets and spring lattice: BPP scenes and checks (`ch02/README.md`) |
| `ch03/` | Ch. 3's formation models (`formation_newton`, `formation_hooke`, `formation_goal_obs`) line for line in plain Lua, with the book's results checked (`checks/ch03.lua`, `ch03/README.md`) |
| `ch04/` | Ch. 4.1's perfect formations (`formation_perfect`) and Ch. 4.3's coverage models (`uniform`, `uniform_mfpl`) line for line in plain Lua, the sweep and William's NetLogo/Android runs (`uniform_data.txt`), with the book's results checked (`checks/ch04_perfect.lua`, `checks/ch04.lua`, `ch04/README.md`) |
| `netlogo/` | William's original NetLogo models (NetLogo 6; all but `lopf.nlogo`), the reference for every port (`netlogo/README.md` maps them to chapters) |
| `ch11/` | Table 11.1 on Maxim's simulator (`maxim/`, his C and environments; `maxim.lua`, an exact Lua copy; the counts behind the table) and the mean free path in 2D and 3D, exact and simulated (`ch11/README.md`) |
| `lib/` | Shared code: `swarm.lua` (the formation harness for every vehicle, behind one interface, G18), `laws.lua` (the two laws, shared by every vehicle's scenes), `ideal.lua` (the perfect-tracking reference vehicle; `VEHICLE=lib.ideal` runs any scene on it), `pointmass.lua` (G5, the point mass with the drone's limits; `VEHICLE=lib.pointmass`), `rng.lua`, `batch.py`/`batch.lua`, `monitors.lua`, `world.lua`, `terrain.lua`, `town.lua`, `buildings.lua`, `features.lua`, `vegetation.lua` and `places.lua` (the realistic world generator's layers and its five presets), `status.lua`, `lattice.lua` (Ch. 16.9 lattice quality), `ch13.lua` (Ch. 13's mechanisms) so far (`lib/README.md`) |
| `Worlds.lua` | Viewer for the world generator's presets: the book's (1–4) and the five realistic ones (5–9: rural, suburban, city centre, industrial port, harbour town) |
| `checks/` | One check per port and `run_all.sh`, which runs them all (`checks/README.md`) |

Related elsewhere in the repo: `demo/WyomingWill/ChainFountain/` (the Mould
effect; the basis of `BOOK.md` §7) and `demo/WyomingWill/Cabinet/`.

## 4. Sources that are not in the repo

Attach these to a chat that needs them; they are not William's to publish, or
live in their own projects.

| Source | Needed for |
| --- | --- |
| The book, `apbook1.pdf` (674 pages; page refs in `BOOK.md` are PDF pages, book page = PDF − 31) | Anything the chapter notes don't settle |
| The Android app, `ap.zip` (Kotlin; 10 simulations, all with book counterparts) | Step 1 of every task: mostly built from the `.nlogo` files, sometimes improved, sometimes wrong |
| Zarzhitsky's CPT code, `CPT.zip` (PlumeGen, TraceGen, viewer; C/GTK2) | Ch. 8–9: the plume and robot constants the book omits. **Its map makers (`MakeMap.c` for Textron, `MapGen.c`) are not used**: our own 3D world generator (`BOOK.md` §6) builds every world. `lib/world.lua` writes his map format (`writeCPT`) so PlumeGen and TraceGen can run on our worlds as a check; PlumeGen builds from `PlumeGen.c` + `MapUtils.c` with glib only. The app's version changes the plume generator |
| `lopf.nlogo` (Ch. 5) | The only model not in `netlogo/` (it did not convert to NetLogo 6); its NetLogo 5 version is on the book website, sites.google.com/view/artificialphysics, page `/netlogo-simulations` |
| The thesis PDFs | Only to check a detail the digests don't cover |

## 5. Building, running, measuring

```
git clone https://github.com/bullet-physics-playground/bpp ~/bpp && cd ~/bpp
apt-get update   # needed first in a fresh cloud workspace
apt-get install -y libbullet-dev libluabind-dev liblua5.1-0-dev liblua5.2-dev \
  libqglviewer-dev-qt5 libsdl2-mixer-dev libassimp-dev qtbase5-dev libglew-dev \
  xvfb xdotool imagemagick lua5.1   # lua5.1 optional: checks run inside BPP
qmake bpp.pro CONFIG+=release && rm -rf release/bpp.gch
nohup make -j2 > /tmp/make.log 2>&1 &     # a few minutes to over ten
```

- **Precompiled-header pitfall (FIXES 27):** after re-running qmake, or on a
  new day, `rm -rf release/bpp.gch` before `make`.
- **Before sending a patch:** `bash checks/run_all.sh` (all must pass; the
  script is not executable, so run it with `bash`).
- **Saved Lua path pitfall (F65):** if a check fails with
  `module 'common' not found`, BPP is using a `[lua] path=` saved in
  `~/.config/bullet-physics-playground.github.io/bpp.conf`, often from
  another checkout; delete that line (or clear the field in Preferences).
- **Headless run:** from this folder,
  `SDL_AUDIODRIVER=dummy XDG_RUNTIME_DIR=/tmp/rt QT_QPA_PLATFORM=offscreen ~/bpp/release/bpp -f Formations-Lennard-Jones-Quadcopter.lua -n 1500`
  (`mkdir -p /tmp/rt` first). 5400 frames ≈ 180 s of flight, about a minute of
  wall time for 50 drones. Append a probe with `-l`.
- **Batches:** `python3 lib/batch.py SCRIPT --seeds 1-3 --set name=a,b --probe FILE --out x.csv`
  runs seeds × settings two at a time into one CSV, with `delayMs` 0 and
  `SEED` set (`lib/README.md`). Prefer it to hand-written sweep scripts.
- **GUI under a virtual display:** `Xvfb :99 -screen 0 1600x1000x24 +extension GLX &`,
  `DISPLAY=:99`; screenshot with `import -window root`; keys with `xdotool`.
  Open a scene in the GUI by naming it without `-f` (`bpp Formations-Lennard-Jones-Boat.lua`);
  `-f` always runs without the GUI. The window starts small: `xdotool
  windowsize` it. Software GL renders ~8 frames a second.
- **Which Lua:** BPP links Lua 5.1 or 5.2 depending on the build (`bpp.pro`
  picks 5.2 on some Ubuntu releases; William's build is 5.2, the cloud
  workspace's 5.1); ask it with
  `bpp -l 'print(_VERSION)' -n 1`. A standalone `lua` on the path may be a
  different version. All our Lua (`lib/`, `checks/`, `ch*/`) runs on 5.1–5.4;
  write new code the same way (no `math.atan2` without a fallback, no
  `unpack`, `loadstring`, `setfenv`). `checks/run_all.sh` runs the checks
  inside BPP when one is built.
- **PDFs:** `pip install markdown playwright` if missing (Chromium is
  preinstalled in the cloud workspace), then for example
  `python3 tools/md2pdf.py BOOK.md BOOK.pdf --sub "The whole book in Bullet Physics Playground: the plan" --footer "Physicomimetics in 3D with real vehicles: the plan" --break "6. The capstone: one mission, five kinds of vehicle" --break "8. Build order"` (2026-10-28; breaks act only on `##` headings, and as rows are added the best set changes: try a few and keep the one whose emptiest page is fullest)
  and `python3 tools/md2pdf.py WORKFLOW.md WORKFLOW.pdf --sub "How the work is organised" --footer "Physicomimetics in 3D with real vehicles: how the work is organised"`
  and `python3 tools/md2pdf.py FINDINGS.md FINDINGS.pdf --title "Findings: experiments, confirmations and errors" --sub "Physicomimetics in BPP: what the conversion has found, kept up to date" --footer "Physicomimetics in 3D with real vehicles: findings"` (2026-10-27: no break; the one before "6. How BPP behaves" left a nearly empty page). Look at the last pages: if one is nearly empty, add a `--break "<heading>"` before a section (or drop one) to rebalance them.
- Don't `pkill -f` a pattern that matches your own shell; kill by PID.

## 6. Facts established so far

- **Random numbers:** BPP's `math.random` (Lua 5.1 and 5.2 alike) is glibc
  `random()`, the generator the book's appendix warns about. Run inside Lua 5.1 or 5.2 with the
  appendix's sampling (S extra calls per accepted point in the disk, 10⁶ points,
  36 bins), it fails at S = 25 (χ² 321), 26 (223) and 27 (409) against a 99.9%
  cut of 66.6. The multiply-with-carry generator passes at every S (χ² 26–47).
  It is now `lib/rng.lua`, used by every demo here and by the probes, seeded
  from the `SEED` environment variable, else the `seed` parameter, else the
  clock (FIXES 34). Use `SEED` for every measurement; the seed is printed.
- **Drones:** Lennard-Jones settles on quadcopters; split-Newtonian keeps
  jostling. Ch. 13 explains why (the force flips sign at D) and gives four
  remedies, cheapest first: AR damping η, adaptive friction, static friction,
  an adaptive speed cap (`BOOK.md` §1, `book/ch13.md`).
- **Clustering is not the 2D cause:** the 2D Newtonian defaults sit below the
  Eq. 3.4/3.5 threshold (G 1500 against G_t 2368 triangle, 1699 square). The 3D
  square (G 7500) is above the 2D formula's 5492; the 3D threshold must be
  measured.
- **Uniform Coverage** (FIXES 36): BPP and Android agree; their wall rule
  differs from NetLogo's and is kept deliberately. Deviation converges to a
  seed-independent limit (the walk is an ergodic Markov chain): at MFP 50 /
  100 the limits are 0.0158 / 0.0368 (1 agent) and 0.0131 / 0.0347 (10
  agents); at MFP ≤ 17 they are below ~0.002 and not resolved at 5×10⁷
  visits. At equal total visits one agent covers as evenly as ten.
- **Uniform Coverage with 100 agents** (same 5×10⁷ visits): at MFP 30 / 50
  the limits drop to 0.00087 / 0.0035, 4–5× below 1 or 10 agents, because
  crowding adds turns (shorter effective free path), as Fig. 4.19 shows.
  Agents are near-independent only when they rarely meet.
- **Ch. 2 reproduced** (`ch02/README.md`): every result of the three models,
  including the book's peak speeds 5.6 / 5 / 4 / 9 under the force cap (we
  get 5.50 / 4.97 / 4.00 / 9.00). Energy with the book's integrator swings
  within a cycle (0.45% for the spring, up to 16% at a close orbital pass at
  Δt 0.1) but does not drift.
- **The NetLogo models decide where the book is silent** (`netlogo/`):
  solar_system caps speed by scaling the velocity (F15); spring2D starts at
  random headings (F41); formation_goal_obs's world is 701 × 401 patches with
  the goal at (−175.25, 0), and the book's figure panels are ~305-patch crops
  of it (F40). The book's 0.6517 for Listing 11.4 comes from an entry at
  x₂ = 1, not the printed 1.001 (F14).
- **Mean free path in 3D:** 0.7720 × cube edge (0.7138 with a 5% buffer),
  with a closed form found by PSLQ (`ch11/README.md`).
- **Ch. 13 on the drones (M1; `quadcopter/README.md` "Ch. 13 on the
  drones", FINDINGS F43–F56, F59):** the split-Newtonian drones jitter because
  the point mass dithers across the sign flip at D (the particle replica
  does it too). AR damping η alone settles them as fast as LJ or faster,
  in every formation, without crashes. η's band matters: the book's (r < 2D)
  traps a 2D launch at ~0.8 D, because second neighbours come into range;
  a band of 0.2 D round D (William's idea) avoids the trap, and the damped
  force's slope at D must stay below ~0.035 per AP unit or the drones'
  lag brings the jitter back, so 3D needs 0.5 D. These are the Newtonian
  scene's defaults. Switching η on by hand once the plain law has spread
  the swarm gives the most regular lattice (annealing, William, F49, F52).
  From a pile (William's wartime case: dropped from a truck, the default
  1 m launch) η from the launch is still the best found: 2D formed in
  76–96 s, 3D in 45–50 s. Waves, one-at-a-time take-off and per-drone
  switches (latched, or two-way as local annealing) were slower, more
  ragged or lost drones, and were not kept (F53, F59).
  Adaptive friction, static friction and the adaptive speed cap do not
  help the drones (F51, F54, F55) and stay in `lib/ch13.lua` for M2. With
  η the lattice is a quarter to a half as stiff as LJ's at D, so it
  compresses under the goal's pull.
- **Ch. 2 in 3D (F57, F58):** a spring tetrahedron with unequal masses
  flips about its middle axis (the tennis-racket effect); several planets
  stay stable on elliptical orbits with a gap of 1.8 between orbits (outer
  nearest point / inner farthest point) and ~50 steps per nearest-point
  pass; a 3 × 3 × 3 spring lattice rings for ever and settles with
  friction.
- **Settling is timed by `formed`** (bonds ≥ 0.97 of the spacing and speed
  < 0.01 m/s to the end of the run), not by the acceleration test, which a
  slow outward creep passes (FIXES 41).
- The full quadcopter findings are in `quadcopter/README.md` and `FIXES.md`.
- **The realistic world generator (G21, F60–F63):** `World.preset(name,
  { seed = n })` for `rural`, `suburban`, `city-centre`,
  `industrial-port`, `harbour-town` builds terrain and water, zones and
  streets, lots and buildings, mission features and vegetation in
  0.6–2.7 s (Lua 5.1; drawing 0.8–2.9 s more), identically on Lua
  5.1–5.4 (F69). Each layer is a few
  stated rules: one slope rule (≤ 15% along the grid) keeps the land
  drivable and shapes valleys and banks; rivers follow Ferguson's
  disturbed periodic model (irregular meanders, sinuosity 1.4, neck
  cutoffs; F64); density falls exponentially from centres
  (Clark) into Local Climate Zones; every street connects to the
  arterials; the gap rule (touch or ≥ 3 m). Building fraction and mean
  height land inside Stewart and Oke's published ranges for every built
  zone (≥ 3% of a preset, seeds 1–3); the city's skyline is heavy-tailed
  and falls outward. The harbour town carries the capstone's ship (leak
  at `w.leak`), piers, a container yard with dead-end pockets, warehouses
  with doorways, a storm drain whose last 35 m lie below sea level, and
  launch pads. The woods are trees (300 a hectare, crowns from half
  their height, so drones fly between the trunks; F70). Inside BPP the
  noise, the zone lookups and the biggest meshes run compiled (`geo`,
  `src/geo.cpp`), with the same worlds to the bit (FIXES 43, F71). Buildings, trees
  and features are World pieces, so
  `blocked`, `blockedAt`, `writeCPT`, `raster`, `sight` and `traps` see
  them; each layer draws as one mesh.

- **The vehicle interface (G18, M2):** `lib/swarm.lua` is the harness for
  every vehicle (it was `quadcopter/swarm.lua`, now an alias). AP senses,
  runs the law and hands each agent one command: reach a point by the next
  AP tick. A vehicle module (`quadcopter/vehicle.lua`, `ground/vehicle.lua`,
  `boat/vehicle.lua`, `lib/ideal.lua`) does the rest; its fields are listed
  in `lib/swarm.lua`'s header. The drones are bit for bit what they were.
  New scenes: `Formations-<law>-<Vehicle>.lua` with `lib/laws.lua`.
- **Ground robots and boats (M2; `BENCHMARK.md`, F66–F68):** the boats
  (holonomic, 0.79 m/s) form and cross the field like the ideal particles
  and the drones. The Pioneer robots (book: 0.5 m/s, 0.4 rad/s, wheels 0 or
  ≥ 0.1 m/s) freeze where the force falls under friction × 0.1 m/s /
  (metersPerUnit × apHz) = 0.2 AP units: LJ at 0.98–0.99 D, the split law
  with η at 0.89 D (never formed), and in the field those caught behind
  columns stay there (60–80% through). With the minimum set to 0 they match
  the boats, so the minimum speed is the whole difference. Without η the
  split law dithers at the minimum speed; Ch. 13's adaptive and static
  friction do not get it to D (static friction's book scale is ~10% of
  F(D), the dither is driven by the full step), and no vehicle touched a
  column, so the speed cap has nothing to do. None was kept.
- **Small moves at the minimum speed (F72, 2026-10-25):** a wheel asked
  for less than 0.1 m/s now turns at 0.1 m/s instead of stopping
  (William's rounding up; the faster wheel is eased so turns stay within
  0.4 rad/s). The robots then reach the particles' lattices (LJ 1.00 D,
  Newtonian 0.99–1.00 D, both formed) and get 98–100% through the field
  in 590–673 s (LJ) and 632–666 s (Newtonian). Behind a single column
  nobody stays (an unstable balance); the one robot left in two of six
  runs sits between two columns 2.6 m apart whose 1.6 m repulsion zones
  overlap, a stable balance of AP itself: the ideal particles stop at the
  same two points (`probes/stuck_robots.lua`).

- **Kinetic theory (M3 step 4, 2026-10-27/28; F85–F91):** `kt.nlogo`'s
  walls re-draw a particle every tick it stays near them, which heats the
  gas (slope 1–2.5% above V/6, v̄ 1.36√T); Kerr's simulator thermalises
  once, at a wall crossing (Garcia's DSMC), which gives the book's
  Fig. 4.23 and, at 30–300 particles, Eq. 4.6: that is now the default
  (`inward`). V/6 holds to a few percent and moves with density and
  temperature. On vehicles (velocity commands, G4): the profile survives
  lag if KT keeps its own velocities (colliding sensed ones freezes the
  gas); a vehicle follows KT only if its lag is shorter than a KT tick;
  drones collide in mid-air unless collisions separate (F90) and KT runs
  at ~1 Hz (F91). KT is not flown on drones in the plan; the capstone's
  sweep is by ground robots, where contacts are bumps.

## 7. Where things stand and what's next

- **Done: milestone M0** (build step 0): `lib/rng.lua`, `lib/batch.py` +
  `lib/batch.lua`, `lib/monitors.lua`, `lib/world.lua` + `Worlds.lua` with
  the book presets, `ch02/` (Ch. 2's three models), `checks/run_all.sh`;
  plus Ch. 11.7's mean free path in 3D (`ch11/`), the Uniform Coverage
  measurements (FIXES 36), the realistic generator's design (`BOOK.md` §6),
  `FINDINGS.md`, the one-line status (`lib/status.lua`), William's NetLogo
  models (`netlogo/`) and `ch02/Spring3D.lua`.
- **Done: milestone M1** (build step 1, 2026-10-18), Ch. 13 on the drones.
  - **Built:** `lib/ch13.lua` (η with its band, the stop rule, adaptive
    friction, static friction, the adaptive speed cap, each tested in
    `checks/ch13.lua`); `lib/lattice.lua` (Ch. 16.9's Delaunay CV, bond
    and nearest-neighbour CV; `checks/lattice.lua`); per-tick metrics in
    `quadcopter/swarm.lua` and `probes/settle_drones.lua` (settling as
    `formed`, crossings of D, suggested-position gap, `SWITCH_AT` to move a
    slider mid-run); optional bonds in `lib/monitors.lua`.
  - **Answer to M1's question** (does η alone make the Newtonian drones
    settle like LJ?): **yes** (§6). Only η is needed on these drones; it is
    on by default in `Formations-Newtonian-Quadcopter.lua` (`etaPower` 1,
    `etaWidth` 0.2 in 2D and 0.5 in 3D). Every other Ch. 13 mechanism was
    measured, found not to help, and taken off the drones (William's
    decision; `quadcopter/README.md` has the table of where each belongs:
    static friction and the speed cap for vehicles with a minimum speed or
    real ranging, and for sensor noise).
  - **Also in the M1 chat:** the simplicity principle (§2, William); Ch. 2
    in 3D: `ch02/Tetrahedron.lua`, `ch02/Planets.lua` (elliptical orbits),
    `ch02/SpringLattice.lua` (F57, F58); `formation_newton.nlogo` checked
    against the ports (F48); FINDINGS F43–F59, FIXES 39–41.
  - **Open from M1:** a faster 2D lattice from a pile (LJ forms in
    30–35 s, so look at the force law's shape near D, not a switch; F59);
    whether the drones' slope limit at D (~0.035 per AP
    unit) follows from their lag and AP rate, and moves with `apHz`; a 3D
    G_t for the cube (`BOOK.md` §1 item 9).
- **Done: the realistic world generator** (`BOOK.md` §6, 2026-10-20), in
  five patches:
  1. terrain and water (`lib/terrain.lua`, the five presets in
     `lib/places.lua`, `Worlds.lua` presets 5–9, `checks/terrain.lua`;
     F60);
  2. zones and streets (`lib/town.lua`, `checks/town.lua`; F61, which
     also corrected two LCZ numbers in `BOOK.md`);
  3. lots and buildings (`lib/buildings.lua`, `checks/buildings.lua`;
     F62), calibrated to the LCZ ranges;
  4. mission features and vegetation (`lib/features.lua`,
     `lib/vegetation.lua`), the outputs (`World:raster`, `writeRaster`,
     `sight`, `traps`), `checks/features.lua` (F63);
  5. irregular rivers (William: the sine-generated ones were far too
     periodic): Ferguson's disturbed periodic model with neck cutoffs
     (F64).
  - **Open from it:** wind with height and currents (`BOOK.md` §6
    "Later"); importing real places (OpenStreetMap, elevation, charts);
    trees and hedges are solid to `blockedAt` and must be treated as
    porous by the plume (G14); the drain's manholes are drawn, not open
    shafts; generation and drawing take up to 3.6 s inside BPP (F71), so a
    viewer slider rebuild is not instant (it is built once per frame while
    dragging). The next costs (F71): Bullet's BVH for meshes that are only
    drawn (~1.1 s of rural's 2.9 s; a BPP change), then the woods'
    placement in Lua (0.9 s).
- **Done: milestone M2** (build step 2, 2026-10-21), in four patches:
  1. the vehicle interface (`lib/swarm.lua`, `quadcopter/vehicle.lua`,
     `lib/ideal.lua`, `checks/vehicles.sh`);
  2. the ground robot (`ground/`, `lib/laws.lua`, the probe's contact and
     field measures, `checks/vehicle_physics.lua`; F66);
  3. the surface boat (`boat/`; F67);
  4. the benchmark (`BENCHMARK.md`, `probes/benchmark.sh`; F68).
  - **Answer to M2's question** (is the method vehicle-independent?):
    **yes for the holonomic vehicles; for ground robots once a small move
    is made at the minimum wheel speed rather than not at all** (§6, F72).
  - **Open from M2:** gaps that AP's column repulsion closes though a
    robot fits (two columns 2.5–3.2 m apart; F72); the robot on the
    generator's streets (`toBPP(v, { contact = true })`) and the boat on its water (`waterAt`)
    instead of flat ground and a still sea; the Maxelbot (skid-steer,
    G10); Ch. 13's dumbbell and the triangle of death (E6) on the robot;
    benchmark tasks 3–4 and the other vehicles (`BOOK.md` §6).
- **Now: M3** (William, 2026-10-25: "Let's do 1, 2, 3, 4"; build steps
  3–5, `WORKFLOW.md` §5), one patch per step:
  1. Ch. 3 fidelity checks: the split Newtonian and Hooke models, goal,
     obstacles and Disable One (**done**, `ch03/`, `checks/ch03.lua`,
     F73–F75: G_t and its hysteresis confirmed, G_t in 3D = G_t/√2,
     Eq. 3.5 fits the Java/BPP force direction but not the `.nlogo`'s,
     Disable One's threshold is a bound); the honeycomb (**done**, F77:
     the centres trap particles, the model's switching mixes the two
     rules per pair);
  2. Ch. 4.3 coverage against Table 4.2, Fig. 4.19 and William's NetLogo
     and Android runs (**done**, `ch04/`, F78: reproduced at MFP ≥ 17,
     noise-limited below it); Table 11.1 on Maxim's own simulator and
     environments (**done**, `ch11/`, F79–F81: every entry from his files,
     one misprint; rerun 40–160M steps, the small environments settle and
     the large ones' KL keeps falling with run length; his robot can stick
     on a wall); the mean free path's bound (0.65 × cell) confirmed on
     the Android rule run long and on all 12 of Maxim's environments
     (F84);
  3. Ch. 4.1's perfect formations (**done**, `ch04/perfect.lua`,
     `checks/ch04_perfect.lua`, F82–F83: both lattices form perfectly with
     the book's momentum signature; Toggle Formation rebuilds them turned
     11–15° off the compass; question (a) answered: the third law can be
     kept, at 5–12 times the formation time);
  4. velocity commands (G4), the point-mass vehicle (G5) and kinetic
     theory (Ch. 4.4, Ch. 7); the vehicle interface makes the point mass
     (G5) one more vehicle module. William, 2026-10-27: Couette flow
     first, then G5, then G4.
     - **Couette flow (done,** `ch04/couette.lua`, `ch04/couette1.c`,
       `checks/ch04_couette.lua`, F85–F86): the linear profile and
       momenta reproduced; `kt.nlogo`'s walls emit hotter than the
       Rayleigh they draw (a particle still in the wall zone is drawn
       again), so its slope is 1–2.5% above V/6 and v̄ = 1.36√T; walls
       thermalising only incoming particles (`inward`, Kerr's rule, the default since 2026-10-28)
       give the book's Fig. 4.23, and its Fig. 4.24 at N ≤ 300.
     - **The point-mass vehicle, G5 (done,** `lib/pointmass.lua`,
       `probes/step_response.lua`, F87): top speed, top acceleration and
       lag as sliders, the drone's by default (6 m/s, 6.87 m/s², 0.45 s
       fitted); on the benchmark it matches the drones at a quarter to a
       third of the cost (`VEHICLE=lib.pointmass`). Past ~100 agents the
       harness's all-pairs AP step, not the vehicle, is the cost.
     - **Velocity commands, G4 (done,** `velocity()` in the vehicle
       interface for the ideal vehicle, point mass, quad and boat;
       `checks/velocity.lua`; `ch04/Couette-Vehicles.lua`, F88–F89):
       Couette flow on vehicles. The profile survives lag (point masses,
       lag to 0.9 s) when KT keeps its own velocities; colliding the
       sensed velocities freezes the gas. The drones collide in mid-air
       (40 of 100 down by 300 s): KT needs collision avoidance under it,
       which Kerr assumes but does not give.
     - **Separating collisions (option C, William 2026-10-28; F90):**
       `couette.lua`'s `separate` and `range` (Lua only; defaults are the
       model). At range 5 units (2.5 m, from the drone's lag) 100 drones
       keep 92% of the ideal profile and lose 8–10 in 2,000 s (40 in
       300 s before).
     - **The bumper and the KT rate (F91):** a bumper under KT did not
       help and was taken out. The rule that did: a vehicle follows KT
       only if its lag is shorter than a KT tick; drones at 1 Hz (scale
       2.5 m/unit, the same speeds in m/s) track their commands, carry
       93–95% of the ideal profile and lose 2–5 per 4,000 s, about a
       fifth of the 5 Hz rate. Losses to zero would need a range of at
       least closing speed × tick or avoidance inside the flight
       controller (Kerr assumes one); **not pursued** (William,
       2026-10-28): KT is not flown on drones in the plan. The
       capstone's KT sweep is by ground robots, for which a contact is
       a bump, not a loss, and occasional losses are what a swarm is
       for (robustness). **Needed for it:** `velocity()` on the ground
       robot (`ground/vehicle.lua`), and KT on robots that touch and
       carry on.
- **The seven theses** (Heil, Hettiarachchi, Kerr, Kunkel, Maxim,
  Rebguns, Zarzhitsky) were attached by William on 2026-10-28; they stay
  out of the repo (§4). Kerr's was checked for F85 (the wall rule is
  Garcia's crossing rule, i.e. `inward`) and F89 (collision avoidance is
  assumed, not given).
- **Next, the last of M3: Ch. 7's theory checks** (`BOOK.md` 7.1–7.4,
  `book/ch07.md`, Kerr's thesis, which William attaches): the KT
  controller of Ch. 7 (both walls moving the same way, obstacles, the
  corridor, `World.preset("ch07-corridor")` in `lib/world.lua`), on particles first,
  reusing `ch04/couette.lua`'s step where it fits (Kerr's wall is now its
  default); then uniform density at rest (book: error < 10%), mean speed
  against T (< 2%), and the profiles with one moving wall (linear) and
  two (flat) against obstacle density, deciding one- or two-sided
  explicitly. The chapter note lists the listing bugs (speed `max(…, 6)`
  should be `min`; Listing 7.3 draws collision angles from a half-circle
  only). Then close M3 here (its answers, as for M1 and M2) and go on to
  Ch. 13's constrained vehicles.
- **Then: Ch. 13's constrained vehicles,** one patch each: (1) the
  fixed-wing UAV with the point-mass and torque laws (**done** before M3,
  `ch13/`, `fixedwing/`, F76); (2) the dumbbell agent on the Pioneer and
  the camera ring (§13.4, E10–E11b); (3) the triangle of death (E6); (4) a
  torpedo-shaped AUV that cannot hover or move sideways (G11); (5) ★
  rotating formations for MAVs (William, 2026-10-28; `BOOK.md` Ch. 13
  table, ★ row): agents fly toward another agent instead of circling
  alone, in three versions (cyclic pursuit with IDs; ID-free pursuit of
  the nearest agent in a forward sector; LJ with the torque law, to see if
  it mills by itself), against the book's lone circles, with the
  n D ≥ 2π R_min limit stated and the surveillance, relay and
  stay-in-region measures.
- **Keep it simple** (§2): add a control only when a measurement shows it
  is needed, off by default, with notes on where it is needed.
- **Check every port against its `.nlogo` first** (`netlogo/`): it found
  two guessed starts and the wrong Ch. 3 world frame (F40, F41).
  `formation_newton.nlogo`, `formation_hooke.nlogo` and
  `formation_goal_obs.nlogo`, `honeycomb.nlogo`, `uniform.nlogo` and
  `uniform_mfpl.nlogo` and `formation_perfect.nlogo` are checked line for
  line (`ch03/`, `ch04/`, F48, F74, F77, F78, F82); the other models are
  not yet.
- **Open loose ends:** `probes/cube_orig.lua` no longer runs (FIXES 35); the
  Android app still has the two Uniform Coverage bugs fixed in BPP (FIXES
  4–5; its wall rule is kept, FIXES 36); FIXES item 27 is documented, not
  fixed; an Info pane for BPP.
- **Sources for the next chat:** the book PDF (`apbook1.pdf`; William
  attaches it — read pages with the PDF tool, PDF page = book page + 31);
  `CPT.zip` for plume work and `ap.zip` / `Android_AP.zip` to compare with
  the app (neither is in the repo).

## 8. Opening message for the next chat

> Clone github.com/bullet-physics-playground/bpp and read
> demo/WyomingWill/ArtificialPhysics/HANDOFF.md, then BOOK.md and
> WORKFLOW.md. Build BPP as described there, run bash checks/run_all.sh,
> and continue with the next step in HANDOFF.md §7: the last step of
> milestone M3, Ch. 7's theory checks. Deliver each step as a patch with
> git commands.

Attach the book PDF and Kerr's thesis (Ch. 7 is built on it);
`Android_AP.zip` if it will compare with the Android app (its
`kinetic/` simulation is Ch. 4.4's), and `CPT.zip` for plume work.
