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
- Keep `FIXES.md` (items 1–41 so far) and the task READMEs up to date.
- **Keep `FINDINGS.md` up to date** in every patch that finds something: each
  confirmation of the book, new result, book error, divergence between
  implementations, and our own mistakes once corrected (F1–F56 so far), and
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
| `Formations-*.lua`, `quadcopter/` | Particle formations, and the same flown by quadcopters (`quadcopter/README.md` has the measurements) |
| `Uniform_Coverage.lua` | Mean-free-path coverage, with the neighbour-cone and dead-end fixes (its random number generator is now `lib/rng.lua`) |
| `FIXES.md` | Fixes 1–41 |
| `FINDINGS.md`, `FINDINGS.pdf` | The running record of experiments: confirmations, new results, errors (ours and the book's) |
| `ch02/` | Ch. 2's springs and solar system, plus our spring3D: BPP scenes and checks (`ch02/README.md`) |
| `netlogo/` | William's original NetLogo models (NetLogo 6; all but `lopf.nlogo`), the reference for every port (`netlogo/README.md` maps them to chapters) |
| `ch11/` | The mean free path in 2D and 3D, exact and simulated (`ch11/README.md`) |
| `lib/` | Shared code: `rng.lua`, `batch.py`/`batch.lua`, `monitors.lua`, `world.lua`, `status.lua`, `lattice.lua` (Ch. 16.9 lattice quality), `ch13.lua` (Ch. 13's mechanisms) so far (`lib/README.md`) |
| `Worlds.lua` | Viewer for the world generator's book presets |
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
- **Before sending a patch:** `bash checks/run_all.sh` (all must pass).
- **Headless run:** from this folder,
  `SDL_AUDIODRIVER=dummy XDG_RUNTIME_DIR=/tmp/rt QT_QPA_PLATFORM=offscreen ~/bpp/release/bpp -f Formations-Lennard-Jones-Quadcopter.lua -n 1500`
  (`mkdir -p /tmp/rt` first). 5400 frames ≈ 180 s of flight, about a minute of
  wall time for 50 drones. Append a probe with `-l`.
- **Batches:** `python3 lib/batch.py SCRIPT --seeds 1-3 --set name=a,b --probe FILE --out x.csv`
  runs seeds × settings two at a time into one CSV, with `delayMs` 0 and
  `SEED` set (`lib/README.md`). Prefer it to hand-written sweep scripts.
- **GUI under a virtual display:** `Xvfb :99 -screen 0 1600x1000x24 +extension GLX &`,
  `DISPLAY=:99`; screenshot with `import -window root`; keys with `xdotool`.
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
  `python3 tools/md2pdf.py BOOK.md BOOK.pdf --sub "The whole book in Bullet Physics Playground: the plan" --footer "Physicomimetics in 3D with real vehicles: the plan" --break "2. Shared groundwork" --break "8. Build order"`
  and `python3 tools/md2pdf.py WORKFLOW.md WORKFLOW.pdf --sub "How the work is organised" --footer "Physicomimetics in 3D with real vehicles: how the work is organised"`
  and `python3 tools/md2pdf.py FINDINGS.md FINDINGS.pdf --title "Findings: experiments, confirmations and errors" --sub "Physicomimetics in BPP: what the conversion has found, kept up to date" --footer "Physicomimetics in 3D with real vehicles: findings"`. Look at the last pages: if one is nearly empty, a `--break "<section heading>"` can rebalance them (none needed at present).
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
- **Ch. 13's AR damping η settles the Newtonian drones** (M1 step 1,
  `quadcopter/README.md` "Ch. 13 on the drones", FINDINGS F43–F47): with
  `etaPower` 1 they settle as fast as LJ or faster, in every formation,
  without crashes; the plain law dithers across D even as particles. In 2D
  at range 1.5 D η settles the lattice at ~0.8 D (second neighbours come
  into range); range 1.25 D keeps it at D. Power 1 beats the law's own
  power. Switched on once the plain law has spread the swarm to D (~150 s
  in 2D, ~60 s in 3D), η forms the most regular Newtonian lattice ~7 s
  later (F52; settling is timed by `formed`, not the acceleration test,
  FIXES 41): annealing, with η as
  the cooling (F49, William). Better still, η in a band of width
  0.2 D round D (`etaWidth`, William's idea) settles at D from the launch,
  in 2D and 3D, with a stiffer lattice; narrower bands jitter again (the
  drones tolerate a slope of ~0.04 per AP unit at D; F50). The stop rule
  does nothing without η. η's lattice is a quarter to
  a third as stiff as LJ's at D, so it compresses under the goal's pull.
- The full quadcopter findings are in `quadcopter/README.md` and `FIXES.md`.

## 7. Where things stand and what's next

- **Done: milestone M0** (build step 0), all on `master`:
  1. `lib/rng.lua`: the shared multiply-with-carry generator, seeded from
     `SEED`, the `seed` slider (0–1000) or the clock; every demo and probe
     uses it (FIXES 34).
  2. `lib/batch.py` + `lib/batch.lua`: seeds × settings, two at a time, one
     CSV; `--match` reads a script's own `key=value` lines.
  3. `lib/monitors.lua`: COM drift, momentum, angular momentum, energy, and
     the book's integrator with a chosen Δt.
  4. `lib/world.lua` + `Worlds.lua`: the generator's core and the book
     presets (Ch. 3 discs, Ch. 4 box, Ch. 7 corridor); `writeCPT` for
     Zarzhitsky's tools.
  5. `ch02/`: the three Ch. 2 models as scenes and checks.
  6. `checks/run_all.sh`: every check, about 1 min 40 s (`checks/README.md`).
- **Also done in the M0 chat:** Ch. 11.7, the mean free path in 3D, exact
  and simulated (`ch11/`); the Uniform Coverage measurements and the wall-rule
  decision (FIXES 36); the realistic generator's design (`BOOK.md` §6);
  `FINDINGS.md`/`.pdf`, the running record (F1–F42); the one-line status
  design (`lib/status.lua`, BPP's fixed-pitch status font); William's NetLogo
  models in `netlogo/`, with Ch. 2 and Ch. 3's world checked against them
  (F15, F40, F41); Listing 11.4 run on the book's own generator
  (`ch11/listing_11_4.lua`, F14); `ch02/Spring3D.lua` (F42).
- **In progress: milestone M1** (build step 1), Ch. 13's four mechanisms
  on the drones, one patch each, each a slider off at 0:
  1. **Done: AR damping η + the stop rule** (`lib/ch13.lua`; sliders
     `etaPower`, `stopForce` (since removed); metrics in `quadcopter/swarm.lua` and
     `probes/settle_drones.lua`; lattice quality in `lib/lattice.lua`;
     checks `ch13`, `lattice`). Answer to M1's main question: yes, η alone
     makes them settle like LJ (see §6).
  1b. **Done: η's band tied to D** (`etaWidth`, F50; replaces a cooling
     schedule, which would need tuning per task). Open: whether the slope
     limit follows from the lag and apHz.
  2. **Done: adaptive friction** (Eq. 13.23; sliders `muMore`, `muLess`, since removed;
     F51). The ratio > 10 holds; it damps the dither but cannot stop it,
     and alone it freezes the swarm (μ stuck at 0.8–0.9); with η it adds
     little.
  3. **Done: static friction** (Eq. 13.25, g from the book's own scale;
     F54) and 4. **the adaptive speed cap** (Eq. 13.24; F55): neither helps
     the drones, so their switches were taken out again; both are in
     `lib/ch13.lua` for M2. A per-drone automatic η switch was tried and
     removed (F53).
  **M1's answer:** on these drones only η is needed, in a band of 0.2 D
  in 2D and 0.5 D in 3D (the defaults), or switched on by hand once the plain
  law has spread the swarm (F49, F52). `quadcopter/README.md` has the table
  of where each mechanism belongs. William's decision (2026-10-18): the
  drones keep only `etaPower` and `etaWidth`, on by default in the
  Newtonian scene so it works out of the box (etaPower 1; etaWidth 0.2 in
  2D, 0.5 in 3D, from the slope limit and the 2D trap, F56); the adaptive
  friction and stop-rule sliders were taken off too (in the lib for M2).
  **Next:** the M1 summary here, then (William's choice) the 3D spring
  lattice, the realistic world generator, or M2.
  Then the 3D spring lattice (below) and the M1 summary here.
- **After M1, William's choice between** the realistic world generator
  (`BOOK.md` §6, option A: terrain and water first, then zones, streets,
  lots and buildings, vegetation, mission features; presets rural,
  suburban, city centre, industrial port, harbour town) and M2 (the vehicle
  interface, ground robot and surface boat).
- **Ideas William liked (2026-10-18), to do when there is room:** truly 3D
  spring models, since two bodies always stay in one plane (spring3D, done,
  looks like spring2D tilted): **a spring tetrahedron** (four masses, six
  springs, spun about a tilted axis; tumbles and wobbles with |L| and E
  constant) and **a small 3D spring lattice** (a cube of masses on springs;
  the first step of the Ch. 3 formations in 3D, so it fits M1's 3D work).
  Details in `ch02/README.md`, "Not done yet".
- **Check every port against its `.nlogo` first** (`netlogo/`): doing so for
  Ch. 2 and Ch. 3 found two guessed starts and the wrong Ch. 3 world frame
  (FINDINGS F40, F41). `formation_newton.nlogo`'s law matches the Newtonian
  ports (its defaults differ, F48); the honeycomb and Uniform Coverage ports
  and the other formation models have not been checked yet.
- **Open loose ends:** `probes/cube_orig.lua` no longer runs (FIXES 35); the
  Android app still has the two Uniform Coverage bugs fixed in BPP (FIXES 4–5;
  its wall rule is kept, FIXES 36); FIXES item 27 is documented, not fixed; an
  Info pane for BPP; the Ch. 2 drone and remaining 3D variants (`ch02/README.md`).
- **Sources for the next chat:** attach `CPT.zip` again for any plume work
  (it is not in the repo), the book PDF for chapters beyond the notes, and
  `ap.zip` / `Android_AP.zip` to compare with the app.

## 8. Opening message for the next chat

> Clone github.com/bullet-physics-playground/bpp and read
> demo/WyomingWill/ArtificialPhysics/HANDOFF.md, then BOOK.md and
> WORKFLOW.md. Build BPP as described there, run checks/run_all.sh, and
> continue with the next step in HANDOFF.md §7: [milestone M1, step 2 |
> the realistic world generator]. Deliver each step as a patch with git
> commands.

Attach the book PDF if the chat will need chapters beyond the notes,
`ap.zip` if it will compare with the Android app, and `CPT.zip` for plume
work.
