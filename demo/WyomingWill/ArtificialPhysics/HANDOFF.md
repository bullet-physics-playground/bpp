# Handoff: Physicomimetics in BPP

Read this first in a new chat. It says who William is, how he likes to work,
where everything is, how to build and measure, and what to do next. The plan
is `BOOK.md` (what to build, in what order) and `WORKFLOW.md` (how). This file
is updated at the end of every milestone.

## 1. Who and what

- William M. Spears, co-author of *Physicomimetics: Physics-Based Swarm
  Intelligence* (Springer 2011). Artificial Physics (AP) is his research.
- Repository: **github.com/bullet-physics-playground/bpp** (BPP), branch
  `master`. Qt5, QGLViewer, Bullet, Lua 5.1 + luabind, SDL2_mixer.
- This folder, `demo/WyomingWill/ArtificialPhysics/`, holds the AP work.
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
- No text drawn on the graphics pane; status goes in `v.statusText`. Cameras
  start at a useful view and are never locked.
- Lennard-Jones should stay more fluid than Newtonian, even in formation.
- **When `BOOK.md` or `WORKFLOW.md` changes, rebuild its PDF** with
  `tools/md2pdf.py` (§5) and include the PDF in the same patch. Look at the
  pages before sending: no nearly empty pages, build order on one page.
- Keep `FIXES.md` (items 1–35 so far) and the task READMEs up to date.

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
| `FIXES.md` | Fixes 1–35 |
| `lib/` | Shared code: `rng.lua`, `batch.py`/`batch.lua`, `monitors.lua` so far (`lib/README.md`) |
| `checks/` | One check script per port; `rng_appendix.lua`, `batch_repeat.sh`, `monitors.lua` so far |

Related elsewhere in the repo: `demo/WyomingWill/ChainFountain/` (the Mould
effect; the basis of `BOOK.md` §7) and `demo/WyomingWill/Cabinet/`.

## 4. Sources that are not in the repo

Attach these to a chat that needs them; they are not William's to publish, or
live in their own projects.

| Source | Needed for |
| --- | --- |
| The book, `apbook1.pdf` (674 pages; page refs in `BOOK.md` are PDF pages, book page = PDF − 31) | Anything the chapter notes don't settle |
| The Android app, `ap.zip` (Kotlin; 10 simulations, all with book counterparts) | Step 1 of every task: mostly built from the `.nlogo` files, sometimes improved, sometimes wrong |
| Zarzhitsky's CPT code, `CPT.zip` (PlumeGen, TraceGen, viewer; C/GTK2) | Ch. 8–9: the plume and robot constants the book omits. Its Textron map maker (`MakeMap.c`) is replaced by our world generator (G21). The app's version changes the plume generator |
| The original NetLogo models | The book website, sites.google.com/view/artificialphysics, page `/netlogo-simulations` (Dropbox links; the cloud shell usually can't reach Dropbox, so ask William to attach them) |
| The thesis PDFs | Only to check a detail the digests don't cover |

## 5. Building, running, measuring

```
git clone https://github.com/bullet-physics-playground/bpp ~/bpp && cd ~/bpp
apt-get update   # needed first in a fresh cloud workspace
apt-get install -y libbullet-dev libluabind-dev liblua5.1-0-dev liblua5.2-dev \
  libqglviewer-dev-qt5 libsdl2-mixer-dev libassimp-dev qtbase5-dev libglew-dev \
  xvfb xdotool imagemagick lua5.1
qmake bpp.pro CONFIG+=release && rm -rf release/bpp.gch
nohup make -j2 > /tmp/make.log 2>&1 &     # a few minutes to over ten
```

- **Precompiled-header pitfall (FIXES 27):** after re-running qmake, or on a
  new day, `rm -rf release/bpp.gch` before `make`.
- **Headless run:** from this folder,
  `SDL_AUDIODRIVER=dummy XDG_RUNTIME_DIR=/tmp/rt QT_QPA_PLATFORM=offscreen ~/bpp/release/bpp -f Formations-Lennard-Jones-Quadcopter.lua -n 1500`
  (`mkdir -p /tmp/rt` first). 5400 frames ≈ 180 s of flight, about a minute of
  wall time for 50 drones. Append a probe with `-l`.
- **Batches:** `python3 lib/batch.py SCRIPT --seeds 1-3 --set name=a,b --probe FILE --out x.csv`
  runs seeds × settings two at a time into one CSV, with `delayMs` 0 and
  `SEED` set (`lib/README.md`). Prefer it to hand-written sweep scripts.
- **GUI under a virtual display:** `Xvfb :99 -screen 0 1600x1000x24 +extension GLX &`,
  `DISPLAY=:99`; screenshot with `import -window root`; keys with `xdotool`.
- **Plain Lua 5.1** (`lua5.1`) is handy for testing pure-Lua code such as the
  random number generator outside BPP.
- **PDFs:** `pip install markdown playwright` if missing (Chromium is
  preinstalled in the cloud workspace), then for example
  `python3 tools/md2pdf.py BOOK.md BOOK.pdf --sub "The whole book in Bullet Physics Playground: the plan" --footer "Physicomimetics in 3D with real vehicles: the plan" --break "2. Shared groundwork" --break "8. Build order"`
  and `python3 tools/md2pdf.py WORKFLOW.md WORKFLOW.pdf --sub "How the work is organised" --footer "Physicomimetics in 3D with real vehicles: how the work is organised"`.
- Don't `pkill -f` a pattern that matches your own shell; kill by PID.

## 6. Facts established so far

- **Random numbers:** BPP's Lua 5.1 `math.random` is glibc `random()`, the
  generator the book's appendix warns about. Run inside Lua 5.1 with the
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
- The full quadcopter findings are in `quadcopter/README.md` and `FIXES.md`.

## 7. Where things stand and what's next

- **Done:** the map, the workflow, the world-generator design, and this handoff
  with the probes, thesis digests and PDF tool now in the repo.
- **Next: milestone M0** (build step 0 in `BOOK.md`, details in `WORKFLOW.md`):
  1. **Done:** `lib/rng.lua`: move the multiply-with-carry generator out of
     `Uniform_Coverage.lua` into a shared module with a seed setting (not
     `os.time()`); point `Uniform_Coverage.lua`, the formations and
     `quadcopter/swarm.lua` at it; keep the appendix test as a check script.
     Check that Uniform Coverage gives identical results with the same seed.
  2. **Done:** `lib/batch`: a headless runner over seeds × settings writing CSV, two jobs
     in parallel.
  3. **Done:** `lib/monitors.lua`: centre-of-mass drift, linear and angular momentum,
     energy, and a Lua integrator with a controllable time step.
  4. `lib/world.lua`: the world generator's core (G21, `BOOK.md` §6), seeded,
     with the first book presets: Ch. 3's wall of 12 discs, Ch. 4's 84×84
     coverage box, Ch. 7's corridor with an obstacle percentage.
  5. `ch02/`: the three Ch. 2 models (spring1D, spring2D, solar system) as BPP
     scenes with check scripts against `book/ch02.md`.
  6. The `checks/` folder and a script that runs every check.
- **After M0:** M1, Ch. 13's four fixes on the drones, each switchable,
  measured on Newtonian 2D and 3D with the Ch. 16.9 metrics.
- **Open loose ends:** `probes/cube_orig.lua` no longer runs (FIXES 35);
  the Android app still has the two Uniform Coverage bugs
  fixed in BPP; FIXES item 27 is documented, not fixed; an Info pane for BPP.

## 8. Opening message for the next chat

> Clone github.com/bullet-physics-playground/bpp and read
> demo/WyomingWill/ArtificialPhysics/HANDOFF.md, then BOOK.md and
> WORKFLOW.md. Build BPP as described there and start milestone M0. Deliver
> each step as a patch with git commands.

Attach the book PDF if the chat will need chapters beyond the notes, and
`ap.zip` if it will compare with the Android app.
