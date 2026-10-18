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
- Keep `FIXES.md` (items 1–38 so far) and the task READMEs up to date.
- **Keep `FINDINGS.md` up to date** in every patch that finds something: each
  confirmation of the book, new result, book error, divergence between
  implementations, and our own mistakes once corrected (F1–F40 so far), and
  rebuild `FINDINGS.pdf` (§5).

## 3. Where everything is

| Path | What |
| --- | --- |
| `BOOK.md`, `BOOK.pdf` | The map of all 182 book entries, ideas, groundwork G1–G21, the capstone, the chain-fountain escape, the build order. Also the progress tracker |
| `WORKFLOW.md`, `WORKFLOW.pdf` | Folders, the steps every task goes through, milestones |
| `book/ch01.md` … `ch20-appendix.md` | Notes per chapter: algorithms, parameters, results to reproduce with page refs, decisions the book leaves open |
| `book/theses/` | Digests of the seven theses (Heil, Hettiarachchi, Kerr, Kunkel, Maxim, Rebguns, Zarzhitsky) |
| `probes/` | Measurement probes from the quadcopter work (set `PROBES` to this folder) |
| `tools/md2pdf.py` | Typesets the plan files as PDFs |
| `Formations-*.lua`, `quadcopter/` | Particle formations, and the same flown by quadcopters (`quadcopter/README.md` has the measurements) |
| `Uniform_Coverage.lua` | Mean-free-path coverage, with the neighbour-cone and dead-end fixes (its random number generator is now `lib/rng.lua`) |
| `FIXES.md` | Fixes 1–38 |
| `FINDINGS.md`, `FINDINGS.pdf` | The running record of experiments: confirmations, new results, errors (ours and the book's) |
| `ch02/` | Ch. 2's springs and solar system, plus our spring3D: BPP scenes and checks (`ch02/README.md`) |
| `netlogo/` | William's original NetLogo models (NetLogo 6; all but `lopf.nlogo`), the reference for every port (`netlogo/README.md` maps them to chapters) |
| `ch11/` | The mean free path in 2D and 3D, exact and simulated (`ch11/README.md`) |
| `lib/` | Shared code: `rng.lua`, `batch.py`/`batch.lua`, `monitors.lua`, `world.lua` so far (`lib/README.md`) |
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
  and `python3 tools/md2pdf.py FINDINGS.md FINDINGS.pdf --title "Findings: experiments, confirmations and errors" --sub "Physicomimetics in BPP: what the conversion has found, kept up to date" --footer "Physicomimetics in 3D with real vehicles: findings"`.
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
- **Mean free path in 3D:** 0.7720 × cube edge (0.7138 with a 5% buffer),
  with a closed form found by PSLQ (`ch11/README.md`).
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
  decision (FIXES 36); the realistic generator's design (`BOOK.md` §6).
- **Next, William's choice between:**
  - **The realistic world generator** (`BOOK.md` §6, option A): terrain and
    water first, then zones, streets, lots and buildings, vegetation, mission
    features; presets rural, suburban, city centre, industrial port, harbour
    town. Real places (OSM, elevation, depth charts) are future work.
  - **M1:** Ch. 13's four fixes on the drones, each switchable, measured on
    Newtonian 2D and 3D with the Ch. 16.9 metrics, using `lib/batch.py` and
    `probes/batch_drones.lua`.
- **Ideas William liked (2026-10-18), to do when there is room:** truly 3D
  spring models, since two bodies always stay in one plane (spring3D, done,
  looks like spring2D tilted): **a spring tetrahedron** (four masses, six
  springs, spun about a tilted axis; tumbles and wobbles with |L| and E
  constant) and **a small 3D spring lattice** (a cube of masses on springs;
  the first step of the Ch. 3 formations in 3D, so it fits M1's 3D work).
  Details in `ch02/README.md`, "Not done yet".
- **Check every port against its `.nlogo` first** (`netlogo/`): doing so for
  Ch. 2 and Ch. 3 found two guessed starts and the wrong Ch. 3 world frame
  (FINDINGS F40, F41). The formation, honeycomb and Uniform Coverage ports have
  not been checked against their models yet.
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
> continue with the next step in HANDOFF.md §7: [the realistic world
> generator | milestone M1]. Deliver each step as a patch with git commands.

Attach the book PDF if the chat will need chapters beyond the notes,
`ap.zip` if it will compare with the Android app, and `CPT.zip` for plume
work.
