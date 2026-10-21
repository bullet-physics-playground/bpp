# Handoff: Euler's Gallery

`HANDOFF.pdf` beside this file is a typeset copy of it.

Read this first in a new chat. It says how William likes to work, where
everything is, how to build and test, what has been learned about Bullet
along the way, and what to do next. The gallery itself is described in
`README.md`; the physics, exhibit by exhibit, in
`report/physics-fidelity-report.pdf`. Update this file whenever a chat ends.

## 1. What this is

- **Euler's Gallery** (`demo/WyomingWill/EulersGallery/`), an 18th-century
  walnut gallery in the Bullet Physics Playground (bpp,
  **github.com/bullet-physics-playground/bpp**, branch `master`), holding
  21 exhibits of classical rigid-body mechanics, one bay each, walked with
  Tab. Only the exhibit you stand at runs; each also runs on its own from
  its folder, and must print exactly the same there as in the hall.
- **The standard is physics faithfulness.** "Getting the physics right is
  imperative." Every exhibit is checked against theory, published
  experiments or reference data (JPL for the solar system), the numbers are
  in its dossier, and anything idealised, reconstructed or uncertain is said
  so in the code, the README and the report. Never tune a parameter to hit
  a result; find the cause, with evidence.
- William M. Spears (`williammspears@gmail.com`) owns the WyomingWill
  demos; Jakob (koppi) wrote bpp. Other chats own **ArtificialPhysics**
  (`BOOK.md`), **WalkerRoom / Walkers** (`WalkerRoom/handover/`),
  **Clocks**, **Babbage's Hall** (`../BabbagesHall/HANDOFF.md`) and the
  **Rec Room**. Don't edit their files; report stale references instead.

## 2. How William likes to work

**Deliver every change as a patch plus the git commands**, made against
the current `origin/master` (`git fetch` first, and test-apply it on a fresh
worktree of origin before sending). Give the full commands:

    cd ~/path/to/bpp
    git pull
    git am ~/Downloads/<name>.patch
    git push
    git log --oneline -2

Add `qmake && make` when the patch touches C++ (`src/`): William commits
bpp's C++ too, through these patches. If a patch fails: `git am --abort`;
if branches diverged: `git pull --rebase`.

- **Every patch carries its documents**: the exhibit's README/FINDINGS, its
  dossier (`report/dossiers/<Folder>.md`), `report/front.py` when a verdict or
  open item changes, and the rebuilt `report/physics-fidelity-report.pdf`.
  Building the report rewrites the tracked
  `report/__pycache__/front.cpython-313.pyc`: restore it
  (`git checkout -- demo/WyomingWill/EulersGallery/report/__pycache__`)
  before committing. PDFs, STLs and PNGs are binary (`.gitattributes`); make
  patches with `git format-patch --binary --full-index`.
- Commits are authored `William M. Spears <williammspears@gmail.com>` with
  the Co-Authored-By trailer for Claude; write messages to a file and use
  `git commit -F` (quoting in `-m` has mangled messages before).
- He runs the GUI and reports what he sees: reproduce his reports before
  answering, and measure when screenshots don't settle it. He wants to know
  plainly what is real physics and what is a numerical or modelling
  artefact.
- Large investigations go well as background agents, each in its own git
  worktree, then merged and checked by the main chat.

## 3. Where everything is

| Path | What |
|---|---|
| `gallery.lua` | the hall: bays, lights, walking, separate worlds per exhibit (`v:newWorld`), onEnter/onLeave, the start pause |
| `exhibits/<Folder>/` | one folder per exhibit: script(s), README, meshes, `reconstruction/` (scripts and logs behind every number) |
| `report/dossiers/<Folder>.md` | per exhibit: model, theory-check table, runs, caveats, dated changes |
| `report/front.py`, `report/build.py` | the report's summary, statuses, fixes and OPEN list; the PDF builder |
| `report/cmp2.sh` | hall-identity check |
| `report/gyro-free-test.lua`, `gyro-probe.lua` | checks of Bullet's gyroscopic term |
| `../../module/rolling.lua` (`demo/module/`) | shared rolling resistance and static-friction anchor (used by the gömböcs) |
| `../../../tests/` | bpp's test scripts (`09-gyro.lua` tests `body.gyroSolved`) |
| `exhibits/Bille/print/` | printable bodies: the PLA "faceted Weeble" (`ppla37`) and the tungsten-weighted 37-corner polyhedron (`w37/`, with its build guide PDF) |

Exhibit folders: Gomboc, Bille, GalileoRamp, DoubleCone, Oloid, EulersDisk,
Rattleback, SpinningEgg, TippeTop, Dzhanibekov, Gyroscope, BicycleWheel,
NewtonsCradle, HuygensClocks, Kapitza, DoublePendulum, PendulumsTwist,
ChainFountain, Slinky, BrazilNut, SolarSystem.

## 4. Build and test

- **Build bpp** (Qt5, Lua 5.1 + luabind, Bullet 3.24 single precision,
  SDL2_mixer): `qmake && make` (in the cloud workspace:
  `/usr/lib/qt5/bin/qmake -o Makefile bpp.pro && make -f Makefile.Release -j2`;
  new source files need qmake re-run).
- **Headless run:** `xvfb-run -a release/bpp -f file.lua -n FRAMES` from the
  exhibit's folder. Exhibits read their settings from environment variables
  (seeds, rates, counts: see each script's header and dossier). Seed with
  the exhibit's variable when comparing runs; clock-seeded runs differ.
- **Hall identity** (every changed exhibit): from the exhibit folder,
  `BPP=<bpp> xvfb-run -a bash ../../report/cmp2.sh <Start> <Folder> <file> <frames> <tag>`
  prints IDENTICAL when the hall and the stand-alone run print the same.
- **Pause prefix:** `HOLD_S=0` for n frames must be a line-for-line prefix
  of the default (half-second pause) run for n+30 frames.
- **Before/after:** for a change meant not to alter results, the seeded
  console must be byte-identical before and after; for a physics change,
  re-run every check in the exhibit's dossier and flag any verdict change.
- **GUI checks:** under `xvfb-run` with `xdotool` and `import` for
  screenshots; look at them.
- **Whole-repo regression** (any C++ change): run every `demo/**/*.lua` for
  300 frames on the old and new binaries, compare outputs, pin the clock for
  clock-seeded demos (21 Oct 2026: all 276 demos unchanged by
  `body.gyroSolved`). Feed the script list on a separate file descriptor:
  bpp reads stdin.

## 5. What has been learned about Bullet and bpp (keep using these)

- **Bullet's friction ignores `applyTorque`.** In Bullet 3.24 the friction
  rows include a body's external force but not its external torque, so a
  steady torque on a body held by friction makes it slide at h·C·Δt/I.
  Give torques as `applyTorqueImpulse(C·dt)` before the step (gömböcs,
  gyroscope fixed 20 Oct 2026).
- **One friction direction at rest:** below about 3.5 µm/s of slip Bullet
  falls back to a single world direction; slow slips the other way and slow
  turns about the vertical go unresisted. `rolling.anchor` adds a
  Coulomb-limited static-friction impulse.
- **Rolling resistance must act in the same solve as gravity**, not as a
  speed cut before the step (that creeps at gravity's increment per step):
  `demo/module/rolling.lua`.
- **Bullet's gyroscopic term** (default flag 8, implicit body frame) is
  skipped silently when the inertia's determinant is below FLT_EPSILON
  (1.19e-7 in the exhibit's units: small bodies in kg and cm), and it
  dissipates on tumbling bodies (negligible in every exhibit, measured).
  For small or jointed spinning bodies use bpp's `body.gyroSolved = true`
  (solved inside the step; added 20 Oct 2026). Never add a gyroscopic
  torque from Lua before the step to a jointed chain: it goes unstable.
- **Line contacts are noisy:** on long flat contacts Bullet's points sit off
  the true contact and share the load differently each step.
- **ERP 0.2 position correction acts on velocities** for overlaps under the
  0.4 mm split-impulse threshold (cm units) and can add energy.
- **Hulls of tessellated CAD surfaces** create false resting faces; refine
  where the body rests (the gömböc's hull is rebuilt from its STEP by
  `exhibits/Gomboc/hull-reconstruction/gen_hull.py`).

## 6. Where things stand (21 Oct 2026)

14 exhibits OK, 7 with caveats (see the report's section 1). Recent work:
asteroid and ring data checked against JPL SBDB and NASA NSSDC; Holst
movement starts set by silencedetect near William's own listening; the
attendant now pulls the old body away and drops a new one; a PLA-only
monostable polyhedron and a printable tungsten-weighted 37-corner one;
the gömböc's hull refined and its CAD credit confirmed (Kiss Attila, 2013,
published on GrabCAD by Istenes József, 2024); rolling resistance that holds
and no sliding at rest; the gyroscope's friction fix; the chain fountain's
links solved with their gyroscopic term in bpp.

## 7. Next: open physics items, in order

1. **Tippe top, green top's spin collapse.** With no rolling resistance the
   centred (green) top, which cannot invert, starts rocking after about 40 s
   and its spin falls from 25.6 to 3.2 turns a second between 38 and 46 s;
   spin friction alone would take off 0.6. Not investigated. Suspects: the
   Bullet friction/torque issues of section 5 (the exhibit integrates
   Euler's equations itself and sets velocities), contact on the ball near
   the stem, step size. Dossier `TippeTop.md`.
2. **Gömböc headstand times.** Righting from a headstand, 75 / 100 / 125%:
   the earlier study 8.8 / 13.2 / 14.3 s; the report run 8.75 / 13.03 s; but
   seeded runs (`GV_SEED=1 GV_START=headstand GV_REDROP=0`) give 9.25 / 8.43
   / 24.30 s with the new hull (old hull 9.58 / 7.37 / 18.92). Find which is
   representative (statistics over seeds and nudges, the study's protocol),
   and whether the study's numbers are reproducible. Dossier `Gomboc.md`.
3. **Chain fountain speed.** Height agrees (h2/h1 0.133 every link, 0.143
   the exhibit, against 0.12-0.14), but the chain runs at 0.79-0.85
   √(2gh₁) against 0.70 measured, and with every link simulated the speed
   rises with the step (0.79 → 0.84 from 1800 to 7200 steps a second) while
   the height does not: not step-converged. Air drag is missing but can't
   explain the step dependence. Also: the live zone reads about 0.01 high at
   3600-7200; at 1800 steps a second a long-hanging spinning chain shakes
   slowly with the solved term. `FINDINGS.md` sections 12-15.
4. **Bicycle wheel NaN.** Seen once in the GUI, cause unknown; a guard now
   recovers and writes a diagnostic. Needs a reproduction.
5. Lower: the double pendulum's throw-over time isn't converged; the Brazil
   nut's beads are 1/100 as stiff as glass (checked at 1/10) and it runs
   about 0.8 of nominal speed; the Slinky keeps a 0.4% step error; the
   jumping egg's fall-back spreads 25.8-27.2 s with the step; the gömböc's
   hull still has false holding spots off the resting trough; the Sloan
   shapes rest on small samples.
6. Real-world tests: none of William's printed bodies (Gömböc, faceted
   Weeble, w37) has been reported on yet; their results would test the
   simulations.
