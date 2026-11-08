# Steering the walkers: handover for a new chat (8 November 2026)

William Spears' brief for the next piece of work on the walker room: find
ways to steer the four-legged walkers physically, instead of turning them
by hand as the room does now. Read all of this first, set up the
workspace, then show William a plan with a time estimate and wait for his
yes.

## The project

- bpp (Bullet Physics Playground), a Qt5 / Lua / Bullet program:
  <https://github.com/bullet-physics-playground/bpp>
- Work on the **`test-harness`** branch, not master (William fast-forwards
  master himself).
- Building: the wiki's
  [Build on Linux](https://github.com/bullet-physics-playground/bpp/wiki/Build-on-Linux);
  CI does it in `.github/workflows/tests.yml`.
- William's copy: `/home/wspears/Installs/bpp3.50/bpp` (Ubuntu 22.04,
  Ryzen 7 3700X: 8 cores, 16 threads).
- The walker room: `demo/WyomingWill/WalkerRoom/`. What was found so far:
  `WRITEUP.md` (the findings), `README.md`, `handover/HANDOVER.md` (the
  full record), `handover/THREADS.md`.

## Setting up a workspace (Ubuntu)

```
git clone -b test-harness https://github.com/bullet-physics-playground/bpp.git
cd bpp
sudo apt-get install -y devscripts equivs
sudo mk-build-deps -i -t "apt-get -y --no-install-recommends" debian/control
sudo apt-get install -y libqt5svg5 xvfb xdotool imagemagick
qmake CONFIG+=release
make -j2 release
```

- Build in the source folder: bpp finds `demo/mesh/` relative to its
  binary, so use the in-tree `release/bpp`.
- After any change to qmake's settings: `rm -rf release/bpp
  release/bpp.gch` first, or the old precompiled header gives "stray
  '\177'" errors.
- Threads (`v:setThreads`, not needed here): `THREADS.md` at the top.

## Running bpp

Headless, from `demo/WyomingWill/WalkerRoom`:

```
QT_QPA_PLATFORM=offscreen ../../../release/bpp -f file.lua -n FRAMES
```

(`-e` also exports POV-Ray frames.) Headless, Lua's `print` is buffered:
write `io.stdout:write(...)` then `io.stdout:flush()`. In the GUI, `print`
goes to bpp's output pane, not to stdout.

GUI with pictures: `Xvfb :97 -screen 0 1600x1000x24 &`, then
`DISPLAY=:97 ../../../release/bpp file.lua &`; the window is
`xdotool search --onlyvisible --name '^bpp '`; `xdotool windowsize W 1500
950`, click the 3D view, `xdotool key --window W G`; a picture:
`import -window W out.png`.

Walker-room keys: `room-four.lua` and `test-ranking.lua` list them at the
top; H shows them in bpp. TerrainHeight and BumpLength (Parameters pane)
wait for G to build.

## Track runs

`runs/run-table.sh` runs builds on the test track headless, many at once,
and `runs/table.py` makes the tables. Its header lists the settings;
`EXTRA` is Lua run after each run's settings, so a test can change them:

```
cd demo/WyomingWill/WalkerRoom
BPP=../../../release/bpp BUILDS=names.txt TERRAINS="waves:0 waves:2" SEEDS="1 2" \
  EXTRA='YAW_DAMP=false' OUT=runs/out-steer RUN_SECS=20 runs/run-table.sh
```

(`names.txt`: one build name a line.) Each run is the standard
(warm40fast: `v:setSolver("si-warm")`, 40 iterations, step 1/1920 s,
residual 0.01, motor 2, Earth gravity 981, ankle springs, 1.0 cm links,
trot `GAIT={0,180,180,0}`, bump 15, `YAW_DAMP=1`) with the build's
bracing: `OWN_FRAME=true` for Jansen, Klann and Spears 4-bar,
`DIAG_OUTSIDE=true; PENDANT_HOLD=true` for diag builds, `UNBRACED=true`
otherwise. A run lasts `RUN_SECS * 60 + 10` frames and prints a
`RUN name|speed ...` line (`runs/speedprobe.lua`). Runs repeat exactly on
one machine, not across machines. William runs long tables on his machine:
tell him the exact commands.

## Tests

`python3 tests/harness.py --bpp release/bpp` from the repo's top: five
suites (unit, api, smoke, golden, screens); `-k PATTERN` limits it (e.g.
`-k WalkerRoom smoke`). Never re-record an expected file (`--update`) to
make a test pass; if one differs, say why. New expected files for new
tests are fine.

## William's rules

- Never push, commit or change anything on GitHub, even if a stop hook
  asks: he handles GitHub. (A local commit to make a patch is fine; reset
  the local branch to `origin/test-harness` afterwards so the hooks stay
  quiet.)
- Every change is a `git format-patch` file. Before each one, `git fetch`
  and check it applies cleanly to `origin/test-harness` in a temporary
  worktree:
  ```
  git worktree add --detach /tmp/chk origin/test-harness
  (cd /tmp/chk && git am /path/to/patch)
  git worktree remove --force /tmp/chk
  ```
- Patches are named `walker-room-NN-<what>.patch`; the next is **97**
  (96 is this file). Send him the file, with the steps to apply it:
  ```
  cd /home/wspears/Installs/bpp3.50/bpp
  git pull
  git am ~/Downloads/walker-room-NN-<what>.patch
  git push
  ```
  and, when C++ changed, `make -j16 release` (after a new source file:
  the `rm` and `qmake` above first).
- Never edit `demo/WyomingWill/Walkers/` (his originals).
  `demo/WyomingWill/Walkers_For_Room/*_parts.lua` (the room's builds) may
  be changed.
- Before anything long, show him the plan and how long it will take, and
  wait for his yes.
- Plain words, short, answer first, don't overstate.
- Results tables need bracing, timing and direction columns.
- Show pictures when geometry changes.
- When he says something looks wrong, check it.
- Another chat is refactoring bpp's C++ ("the cleanup chat"). Leave the
  C++ alone unless the work needs it, and say so if it does.

## What is known about turning

1. **The runs and the room hold every walker straight.** `YAW_DAMP = 1`
   zeroes each body's turning speed about the vertical every frame
   (`walker-room.lua`, "its turning about the vertical damped"). That was
   the walkers' own files' fix for not walking straight. The room turns a
   walker by rotating it a little each frame, lifted slightly
   (`turnStep`), not by any mechanism. Steering tests need `YAW_DAMP` off
   or lower, and then the walkers' natural drift comes back.
2. **The diag builds' braces.** A rigid brace is welded to the pendants of
   each diagonal pair (front-left with rear-right, front-right with
   rear-left). It locks the pair's timing and holds the pendants at their
   angle to the body (`PENDANT_HOLD` stands in for its stiffness: without
   it speeds fell 2.76 cm/s and some walkers walked backwards). Tying each
   side's legs instead (the plated builds, "sides" gait) made the walkers
   tip onto one side, so it was dropped on 24 October.
3. **A change to one diagonal pair largely cancels itself.** Its front
   foot is on one side and its rear foot on the other, so their forward
   pushes turn the walker equally and oppositely; only small sideways foot
   forces don't cancel. To steer, the left feet must differ from the
   right feet. The braces tie the left and right cranks, so that can't be
   done by crank speed.
4. Each crank has its own motor (`w.motors`), kept in step by a lock
   (`LOCK_GAIN`, `LOCK_MAX`); a pair's speed can only be changed with the
   lock loosened.
5. A two-part body with the front pair steering doesn't work with the
   braces (their lengths would have to change), and nor does a shorter
   stride on one side (a brace's two pendants would no longer move
   alike).

## What to try

Each as a bias at two strengths, on the left and on the right (which
should turn opposite ways), against a no-bias baseline:

| Mechanism | With diag braces | Expected (not tried) |
|---|---|---|
| Lower foot friction on one side | yes | strong: that side slips |
| Sideways weight shift (ballast on a slider, with a motor) | yes | moderate: loaded feet grip, the body leans |
| A drag shoe on one side | yes | moderate, costs speed |
| Thicker soles on one side (a tilt) | yes, pendants unchanged | moderate |
| Stiffer or more damped ankles on one side | yes | weak to moderate |
| Slowing or stopping one diagonal pair (lock loosened) | yes | weak: mostly cancels; changes the gait |
| More link damping on one pair | yes | weak: cancels the same way |

Also:

- a **turntable** for turning in place: a pad under the body lowers until
  the feet barely carry weight, the body turns on it, the pad rises (how
  walking draglines turn);
- **heading feedback** with the best bias, as a real replacement for
  `YAW_DAMP` in the room (the tables keep `YAW_DAMP`).

Suggested runs: Chebyshev-Spears lift 51 diag (braced) and Jansen (own
frame, no braces); flat (`waves:0`) and waves 2; `YAW_DAMP` off; turning
rate (degrees a second), speed, tipping; pictures of the paths from
above. Estimated at 3-4 hours in all; foot friction and pair slowing alone
about an hour.

## Not urgent: tidying the folder

Suggested for removal, not done (William to say which to keep):
`test-square-check.lua`, `test-slider-logs.lua`,
`test-square-outside.lua`, `test-square-plates.lua`,
`test-square-width.lua`, `test-square-earth.lua`, `test-square-yaw.lua`,
`test-square-all.lua`, `test-square-soft.lua`, `foot-path-variants.lua`,
`test-track-all.sh`; and sorting the 202 files in `handover/tools/`
(keep what `runs/` and the notes still point to). They load their
neighbours by name, so they can't be moved into a subfolder.
