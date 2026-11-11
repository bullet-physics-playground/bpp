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
sudo apt-get install -y libqt5svg5 xvfb xdotool imagemagick openscad fonts-liberation fonts-dejavu-core
qmake CONFIG+=release
make -j2 release
```

- OpenSCAD is needed: without it Jansen and Klann can't be built and the
  other bodies lose their marks (which changes their runs too). CI
  installs it; `debian/control` only recommends it.
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
  EXTRA='YAW_DAMP=0' OUT=runs/out-steer RUN_SECS=20 runs/run-table.sh
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
   (`turnStep`), not by any mechanism. Steering tests need `YAW_DAMP=0`,
   not `false`: `false` leaves each file's own body damping, 1.0, which
   holds the walker straight just the same (found 8 November).
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

Removed on 9 November (patch 100, William agreed):
`test-square.lua`, `test-square-all.lua`, `test-square-soft.lua`,
`test-square-yaw.lua`, `test-square-earth.lua`, `test-square-plates.lua`,
`test-square-outside.lua`, `test-square-check.lua`, `test-square-width.lua`,
`test-slider-logs.lua`, `foot-path-variants.lua`, `test-track-all.sh`.
`test-track.lua` stays, moved into `lib/` (patch 102: test-ranking.lua,
drag-shoe.lua and every table run load it). Still to do: sorting the 202 files in `handover/tools/` (keep
what `runs/` and the notes still point to).

## Stage 1 results: foot friction, pair and side slowing (8 November)

Patch 97. `STEER = { mech, side, amount }` in `walker-room.lua` puts a
bias on one side; `runs/steer-table.sh` runs the variants
(`run-table.sh` with `PROBE=runs/steerprobe.lua`, `YAW_DAMP=0`) and
`runs/steer.py` makes the table and `handover/steer_paths1.png`. Turn:
°/s from 5 s to 20 s, to the walker's own left positive. Speed: straight
distance from 5 s to 20 s. Two seeds, flat and waves 2, on this container
(2 cores): one run in about 10 s.

Split = the bias on the left's turn less the same bias on the right's (it
cancels the walker's own drift), °/s, flat / waves 2:

| Walker | Bracing | Bias | Timing | Direction | ×0.75 / ×0.8 | ×0.5 / ×0.6 | ×0.05 | Speed at the stronger (no bias 8.9 flat) |
|---|---|---|---|---|---|---|---|---|
| C-S lift 51 diag | outside, held | foot friction | trot | forward | +0.01 / +0.02 | +0.01 / −1.12 | +0.66 / +0.51 | 8.8–8.9 |
| C-S lift 51 diag | outside, held | pair crank speed | trot, pairs free | forward | +0.16 / −0.13 | +0.14 / +1.65 | — | 4.6–5.3 |
| Jansen | own frame | foot friction | trot | forward | −0.03 / +0.30 | +0.01 / +0.25 | +0.03 / +1.13 | 8.9 |
| Jansen | own frame | pair crank speed | trot, pairs free | forward | −0.06 / −0.86 | −0.06 / −0.67 | — | 4.6–5.2 |
| Jansen | own frame | side crank speed | trot, sides free | forward | +1.12 / +1.55 | +4.34 / +2.83 | — | 4.9–5.1 |

- **Nothing much turns them.** With the body's damping off altogether
  the walkers still hold their heading: flat, no bias, 0.00 and −0.02
  °/s; on waves 2 lift 51 diag drifts −1.4 °/s (two seeds), Jansen 0.0.
  The grip of the wide flat feet (8 × 12 cm, 26 cm apart) holds them: a
  57 °/s spin given to every body was gone within a frame. No hidden
  damping: every body's angular damping is 0 in these runs.
- **Foot friction is weak.** Halving one side's changed nothing on flat;
  even ×0.05 (nearly ice) gave 0.3–0.4 °/s on lift 51 diag and almost
  nothing on Jansen, at no cost in speed. The other side's feet simply
  do all the pushing. On waves 2 the numbers are within the seed noise.
- **Pair slowing** (one diagonal pair's cranks at ×0.8 or ×0.6, the lock
  holding each pair only to itself) turns little and inconsistently, as
  expected, and costs about half the speed: the pairs drift out of the
  trot (lift 51 diag's tilt 12–16° on flat, against 1°). The loosened
  lock alone (×1) costs nothing.
- **Side slowing turns Jansen** (no braces), toward the slow side: ×0.6
  gives +2.4 (left) and −1.9 (right) °/s on flat, a split of 4.3; but it
  too costs about half the speed, as the sides drift out of the trot.
  Lift 51 diag can't do it: each brace ties a left crank to a right one.
- Seeds differ by up to 0.4–1.2 °/s on waves 2; two seeds are too few
  there. Nothing tipped (tilt 60°).

So far crank speed is the only lever that really turns a walker, and the
braces forbid it on the diag builds. A steady difference in crank speed
must break the trot. Open: a difference within each turn only (one
side's cranks faster in stance and slower in swing, the same average),
which would keep the timing.

## Stage 2 results: ballast, drag shoe, soles, ankles, link damping (8 November)

Patch 98. New `STEER` mechanisms (`walker-room.lua`): `ballast` (a
quarter of the walker's weight, inside its body, pushed k cm to one side
by a motor on a slider), `drag` (a 1.5 cm ball, k of the walker's weight,
3 cm out beyond that side's feet on a vertical slider: it slides, it
can't roll), `sole` (a slab k cm thick welded under that side's feet),
`stiff` and `damp` (that side's ankle springs k times as stiff, or as
damped), `linkdamp` (one diagonal pair's links damped k). Pictures:
`handover/steer_parts2.png` (the shoe and the soles), paths
`handover/steer_paths2.png`. Run with `STAGE=2 runs/steer-table.sh`.
`steerSetup` now runs after the ankle springs, link damping and braces
(it changes them); stage 1's runs are the same to the last digit.

Split (bias on the left − the same on the right), °/s, flat / waves 2;
speed at the stronger amount, flat (no bias 8.9):

| Walker | Bracing | Bias | Timing | Direction | Weaker | Stronger | Speed |
|---|---|---|---|---|---|---|---|
| C-S lift 51 diag | outside, held | drag shoe, 0.1 / 0.25 of its weight | trot | forward | +1.16 / +2.53 | +3.06 / +6.05 | 8.2–8.3 |
| Jansen | own frame | drag shoe, 0.1 / 0.25 | trot | forward | +1.43 / +1.25 | +3.70 / +6.14 | 8.1–8.2 |
| C-S lift 51 diag | outside, held | ballast moved 4 / 8 cm | trot | forward | −0.02 / +2.49 | −0.52 / +2.06 | 8.9 |
| Jansen | own frame | ballast moved 4 / 8 cm | trot | forward | +0.01 / +0.35 | +0.03 / +1.59 | 8.9 |
| C-S lift 51 diag | outside, held | soles 0.5 / 1.5 cm thicker | trot | forward | +0.68 / +0.99 | +0.81 / −0.31 | 8.7–8.9 |
| Jansen | own frame | soles 0.5 / 1.5 cm thicker | trot | forward | +1.19 / +0.77 | +8.76 / +0.40 | 1.6–2.7 |
| both | | ankle stiffness ×3 / ×10 | trot | forward | ±0.02 / within noise | ±0.01 / within noise | 8.9 |
| both | | ankle damping ×2 / ×5 (×10 unstable) | trot | forward | 0.00 / within noise | ±0.02 / within noise | 8.9 |
| both | | pair's link damping 0.5 / 0.95 | trot | forward | ±0.02 / within noise | ±0.03 / within noise | 8.9 |

- **The drag shoe steers.** Both walkers turn toward the shoe, on flat
  and on waves 2, in clean arcs, with the seeds agreeing (±0.0–0.3 °/s).
  At a quarter of the walker's weight: about 1.5 °/s each way on lift 51
  diag and 1.9 °/s on Jansen on flat, about twice that on waves; speed
  falls 7–9 % (flat) to 15–20 % (waves). The braces don't matter to it.
  It is the best lever so far.
- **The ballast** does nothing on flat (the feet grip regardless of
  load; lift 51 diag's −0.52 at 8 cm is one seed, rocked to 19.5° tilt,
  the other 0.02) and turns toward the ballast on waves 2, where the
  feet slip.
- **Corrected 8 November, evening:** the shoe and the ballast were first
  sized before the room sets the body's weight (`SAME_BODY`), from the
  build file's own lighter body: on lift 51 diag "0.25" was 0.18 of its
  weight (Jansen's was right, 34.4 against 34.0 g). Fixed in
  `steerSetup`; the shoe and ballast rows above are the rerun.
- **Thicker soles** are erratic: lift 51 diag jolts now and then (body
  1–3° off level, then 19° for a moment in a traced run, cause not
  pinned down); Jansen at 1.5 cm rocks onto the thick side (8–14°) and
  back about every 5 s and nearly stops, and its big left turn comes with
  that. Not usable as it is.
- **Ankle stiffness and damping, and one pair's link damping**: no
  effect beyond the seed noise. Ankle damping ×10 (42 000) goes unstable
  at this time step.
- The drag shoe sits clear of every leg: across 8 runs the nearest part
  (a foot) came no closer than 1.4 cm (lift 51 diag) and 0.9 cm (Jansen),
  measured on the parts' bounding boxes.
- Jansen's runs shifted very slightly with the new bpp build (no bias,
  flat, seed 1: 8.960 → 8.957 cm/s); the steering code is not the cause.

For heading feedback (stage 4), a shoe on each side, lowered on the side
to turn toward, is the obvious candidate. (Stage A, below: a pair of
shoes fails on waves; a braked wheel on each side works.)

## Stage A results: a wheel on each side (9 November)

Patch 105. `SHOES` (`walker-room.lua`): a wheel on each side of every
walker, braked on one side to turn toward it. Each wheel is a ball,
0.15 of the walker's weight, radius 1.5 cm, 5 cm out beyond that side's
feet (`SHOES = { mass =, radius =, out =, down = }`). It sits on a joint
to the body that leaves it free only up and down and rolling along the
walk, so it always rests on the ground by its own weight and the walker
never carries it. `room.setShoe(w, "L" | "R" | nil)` brakes that side's
wheel (a motor on the roll with no target speed and unlimited force) and
frees the other. `YAW_DAMP = 0` is still needed. Picture:
`handover/steer_wheels.png`. Run with `STAGE=A runs/steer-table.sh`.
With `SHOES` off the runs are the same to the last digit as before.

Turn (°/s, mean of 2 seeds) and speed (cm/s), flat / waves 2:

| Walker | Bracing | Wheels | Timing | Direction | Turn, flat | Turn, waves 2 | Speed, flat | Speed, waves 2 |
|---|---|---|---|---|---|---|---|---|
| C-S lift 51 diag | outside, held | none | trot | forward | −0.00 | −1.41 | 8.91 | 8.45 |
| C-S lift 51 diag | outside, held | both free | trot | forward | −0.01 | −1.40 | 8.93 | 8.43 |
| C-S lift 51 diag | outside, held | left braked | trot | forward | +0.91 | +1.60 | 8.52 | 7.65 |
| C-S lift 51 diag | outside, held | right braked | trot | forward | −0.89 | −2.61 | 8.54 | 7.71 |
| Jansen | own frame | none | trot | forward | −0.02 | +0.03 | 8.94 | 8.20 |
| Jansen | own frame | both free | trot | forward | −0.01 | +0.04 | 8.95 | 8.36 |
| Jansen | own frame | left braked | trot | forward | +1.20 | +1.65 | 8.48 | 8.01 |
| Jansen | own frame | right braked | trot | forward | −1.13 | −1.52 | 8.52 | 7.81 |

Split (left braked − right braked): lift 51 diag +1.80 flat, +4.22
waves 2; Jansen +2.33 flat, +3.17 waves 2. (Lift 51 diag drifts right
on waves 2 with nothing braked, −1.4 °/s, seed 1 −1.1, seed 2 −1.7;
braking either side still moves its turn about 1.2–3 °/s that way.)

What having the wheels costs on rough ground, both free, yaw damping
on as in the tables (nine rough terrains, 5 seeds, mean speed cm/s;
the paired difference ± its standard error):

| Walker | Bracing | Timing | Direction | Without | With wheels | Difference | logs 7 | steps 7 |
|---|---|---|---|---|---|---|---|---|
| C-S lift 51 diag | outside, held | trot | forward | 7.75 | 7.12 | −0.63 ± 0.22 | 6.97 → 4.64 | 7.74 → 5.17 |
| Jansen | own frame | trot | forward | 5.85 | 6.03 | +0.19 ± 0.21 | 1.33 → 2.77 | 4.07 → 3.61 |

- **It steers on waves as well as flat**, both ways, and a free wheel
  costs nothing on flat or waves 2. The wheels catch on the logs and
  steps for lift 51 diag; they steady Jansen on logs 7.
- **Clearance:** on logs 7 (12 s, 2 seeds, left braked, right braked and
  neither), across all 11 walkers in `test-ranking.lua`'s directions, no
  wheel touched any part of its walker (`v:eachContact`: not one contact
  point between them). Bounding boxes said otherwise for Spears 4-bar
  and Hoecken-Spears slider diag: a slanted frame's box is much bigger
  than the frame.
- **Size:** radius 3 cm hurts lift 51 diag less on the hardest three
  terrains (waves 6, logs 7, steps 7: 6.07 against 5.31 at 1.5, 6.78
  without) but Jansen more (3.52 against 3.95, 3.51 without), and at 5 cm
  out it overlaps the frame boxes of most walkers. 3 cm out (the first
  try, radius 1.5) steered and cost about the same, but the boxes
  overlapped for lift 62 diag and Klann on logs 7 (not checked by
  contacts); 5 cm leaves a margin.

Designs tried first, all dropped:

- **A pair of shoes on sliders, one pressed down** (the stage 2 shoe on
  each side, 0.1 of the walker's weight, the raised one 9 cm up): turns
  toward the pressed shoe on flat (1.1–1.5 °/s) but the wrong way on
  waves 2. Heavier (0.15) is no better (0.9–1.3 °/s flat, wrong way on
  waves) and costs lift 51 diag 0.4–0.5 cm/s on rough ground. The cause
  is the raised shoe: carried out at the side, it leans the walker, and
  on waves the lean turns it away. One shoe alone (stage 2) has nothing
  on the other side and steers on waves.
- **The shoes stowed at the centre and swung out to press**: can't work
  in Bullet. A slider or 6dof joint pushes at its own frame's origin, so
  a shoe set out to the side along a free axis loses its turning effect.
- In a `btGeneric6DofSpring2Constraint` the angular motor's sign is the
  reverse of what its axis suggests (a shoe's "up" needed a negative
  speed): worth knowing for anything else built on it.

## Stage B: the arrow keys (9 November)

Patch 106. In `test-ranking.lua`, `room-four.lua` and `walker-room.lua`
opened on its own, every walker has the wheels (`SHOES = {}` unless set
before: `SHOES = false` takes them off). The Left and Right arrow keys
brake the left or right wheel of the walker followed (on the track, the
walker); the same key again frees it, and the other key switches sides.
The status line and the output pane say which is braked. In the room,
follow a walker first (Tab; F in `room-four.lua`).

The views keep `YAW_DAMP = 1`, so a walker with both wheels free walks
straight as before. While one of its wheels is braked, that walker's yaw
damping is off (`walker-room.lua`'s preSim) so it turns; freed, the
damping holds it on its new heading. Headless, on flat ground: lift 51
diag turned +0.9 °/s while braked left, held 9° when freed, then −0.9 °/s
braked right. In the room, Jansen turned while lift 51 diag walked on
straight. The room still turns walkers rigidly at walls, braked or not.
That is about 1 °/s, so a quarter turn takes over a minute. (Since
10 November the wheel grips three times as hard and turns about 5 °/s:
"A grippier wheel", below.)

The keys 1-4 (waves, random, logs, steps) now pick the ground in every
room, `walker-room.lua` on its own too; they rebuild it with the same
walkers, wheels free. The test track's "off the ground" measure leaves
out the wheels, which are always down. `drag-shoe.lua` is gone: the
arrow keys replace it.

## A grippier wheel (10 November)

At 0.9–1.2 °/s and 8.5 cm/s a walker's turning radius was 4–5 m,
about half the 10 m room, too wide for the room to steer
walkers by their wheels (stage C). `SHOES.grip` (new) is the wheel's
friction as a multiple of the feet's; its default is now 3 (it was 1).

Turn with the left wheel braked (°/s, mean of 2 seeds, `YAW_DAMP = 0`),
speed (cm/s) and turning radius (speed ÷ turn), flat / waves 2:

| Walker | Bracing | Wheel (weight, grip) | Timing | Direction | Turn | Speed | Radius |
|---|---|---|---|---|---|---|---|
| C-S lift 51 diag | outside, held | 0.15, 1 (before) | trot | forward | +0.91 / +1.60 | 8.53 / 7.64 | 5.4 / 2.7 m |
| C-S lift 51 diag | outside, held | 0.25, 1 | trot | forward | +1.73 / +2.33 | 8.14 / 7.00 | 2.7 / 1.7 m |
| C-S lift 51 diag | outside, held | 0.15, 2 | trot | forward | +2.34 / +3.29 | 7.85 / 6.65 | 1.9 / 1.2 m |
| C-S lift 51 diag | outside, held | 0.4, 1 | trot | forward | +4.02 / +4.55 | 7.01 / 5.76 | 1.0 / 0.7 m |
| C-S lift 51 diag | outside, held | **0.15, 3 (now)** | trot | forward | **+4.87 / +5.85** | 6.59 / 5.66 | **0.8 / 0.6 m** |
| C-S lift 51 diag | outside, held | 0.25, 2 | trot | forward | +6.18 / +6.04 | 5.91 / 5.07 | 0.5 / 0.5 m |
| C-S lift 51 diag | outside, held | 0.25, 3 | trot | forward | +10.36 / +8.59 | 3.51 / 4.35 | 0.2 / 0.3 m |
| C-S lift 51 diag | outside, held | 0.4, 2 | trot | forward | +10.48 / +7.46 | 3.46 / 4.12 | 0.2 / 0.3 m |
| C-S lift 51 diag | outside, held | 0.4, 3 | trot | forward | +10.56 / +7.74 | 3.43 / 3.79 | 0.2 / 0.3 m |
| Jansen | own frame | 0.15, 1 (before) | trot | forward | +1.20 / +1.65 | 8.48 / 8.02 | 4.0 / 2.8 m |
| Jansen | own frame | 0.25, 1 | trot | forward | +2.09 / +2.74 | 8.10 / 6.80 | 2.2 / 1.4 m |
| Jansen | own frame | 0.15, 2 | trot | forward | +2.58 / +4.43 | 7.88 / 6.30 | 1.8 / 0.8 m |
| Jansen | own frame | 0.4, 1 | trot | forward | +4.24 / +5.64 | 7.18 / 5.69 | 1.0 / 0.6 m |
| Jansen | own frame | **0.15, 3 (now)** | trot | forward | **+5.12 / +7.64** | 6.76 / 4.77 | **0.8 / 0.4 m** |
| Jansen | own frame | 0.25, 2 | trot | forward | +6.38 / +7.67 | 6.11 / 4.75 | 0.5 / 0.4 m |
| Jansen | own frame | 0.25, 3 | trot | forward | +11.04 / +8.02 | 3.65 / 4.17 | 0.2 / 0.3 m |
| Jansen | own frame | 0.4, 2 | trot | forward | +11.29 / +8.26 | 3.54 / 4.03 | 0.2 / 0.3 m |
| Jansen | own frame | 0.4, 3 | trot | forward | +10.92 / +8.82 | 3.52 / 3.93 | 0.2 / 0.3 m |

Nothing tipped. Grip turns faster than weight (three times the grip at
the same weight: five times the turn). Past about 10 °/s the walker pivots
on its braked wheel at half speed. It walks slower only while a wheel is
braked.

What having them costs on rough ground, both free, yaw damping on (nine
rough terrains, 5 seeds, mean speed cm/s; the paired difference ± its
standard error):

| Walker | Bracing | Wheel (weight, grip) | Timing | Direction | With wheels | Difference | logs 7 | steps 7 |
|---|---|---|---|---|---|---|---|---|
| C-S lift 51 diag | outside, held | none | trot | forward | 7.75 | — | 6.97 | 7.74 |
| C-S lift 51 diag | outside, held | 0.15, 1 (before) | trot | forward | 7.12 | −0.63 ± 0.22 | 4.64 | 5.17 |
| C-S lift 51 diag | outside, held | **0.15, 3 (now)** | trot | forward | 7.22 | −0.53 ± 0.21 | 4.48 | 5.65 |
| C-S lift 51 diag | outside, held | 0.25, 2 | trot | forward | 5.23 | −2.52 ± 0.47 | 1.68 | 1.15 |
| Jansen | own frame | none | trot | forward | 5.85 | — | 1.33 | 4.07 |
| Jansen | own frame | 0.15, 1 (before) | trot | forward | 6.03 | +0.19 ± 0.21 | 2.77 | 3.61 |
| Jansen | own frame | **0.15, 3 (now)** | trot | forward | 5.96 | +0.11 ± 0.20 | 2.88 | 3.10 |
| Jansen | own frame | 0.25, 2 | trot | forward | 4.89 | −0.96 ± 0.31 | 1.20 | 0.87 |

The grippier wheel costs the same as before (within the noise); the
heavier one catches on the logs and steps. Same size and place, so the
clearance (stage A) is unchanged. The arrow keys turn about 5 °/s now: a
quarter turn in about 18 s.

## Stage C: the room steers by the wheels (10 November)

Before, when a wall or another walker was ahead (within 40 cm, or on a
crossing course), the room picked the best of 12 random turns of 60-180°
and swung the walker through it rigidly in a second. Now a walker with
wheels turns itself, by its wheels, and walks straight the rest of the
time. `ROOM_STEER` picks how:

- **`"backup"` (the default): a three-point turn.** It backs up 4 s
  (`BACKUP_PHASE`) with the wheel on the far side braked, then walks on
  4 s with the near one braked; both turn it the same way, and it repeats
  until it has turned. A cycle turns 50-90° on flat (the 11 walkers on the
  track, below) and ends about where it began, so the room still looks
  only 40 cm ahead and picks the turn as on the spot. A look behind (10 cm)
  ends a backing phase early. William's idea.
- **`"arcs"`:** it walks on with the near wheel braked until it has
  turned, on a circle about 80 cm in radius, so the room looks 120 cm
  ahead (`WHEEL_GAP`) and traces each candidate turn along its arc, clear
  of the walls and of where the other walkers will be by then.
- **`"rigid"`:** the old turns (checked: the same room, to the last digit,
  as before stage C).

Either wheel turn that takes over 60 s, or an arc that still comes within
10 cm of a wall or a walker, is finished rigidly (a rescue,
`room.rescues`). While a wheel is braked by hand (the arrow keys) the room
leaves that walker alone.

`room.setReverse(w, on)` runs a walker's cranks backward. They ease
through a stop over `REVERSE_EASE` s (1): switched at once, lift 62 diag
tipped 22° on flat; eased over 1 s, 2.3° (2 s: no better, and it turns
less). Backing up, Klann and Spears 4-bar rock more than walking (17.7°
and 11-12° against 8.8° and 3.2° on flat): backing is their worse way,
the one the ranking reverses them out of. Nothing came near tipping.

**The back-up turn on the track** (forward to 6 s, backing with the right
wheel braked 6-14 s, forward with the left braked 14-22 s, then free;
eased 1 s; left counts up):

| Walker | Bracing | Timing | Direction | Cycle's turn, flat | Waves 2 | Tilt max, flat |
|---|---|---|---|---|---|---|
| C-S lift 51 diag | outside, held | trot | forward | +80° | +88° | 2.4° |
| C-S lift 62 diag | outside, held | trot | forward | +70° | +57° | 2.3° |
| Klann | own frame | trot | reversed | +51° | +50° | 17.7° |
| Chebyshev-Spears diag | outside, held | trot | forward | +89° | +120° | 0.3° |
| Hoecken-Spears 4-bar diag | outside, held | trot | forward | +71° | +109° | 0.2° |
| Hoecken-Spears slider diag | outside, held | trot | forward | +58° | +92° | 0.1° |
| Jansen | own frame | trot | forward | +74° | +98° | 1.5° |
| Spears 4-bar | own frame | trot | reversed | +88° | +52° | 12.4° |
| Hoecken slider diag | outside, held | trot | forward | +81° | +101° | 0.5° |
| Hoecken 4-bar diag | outside, held | trot | forward | +80° | +108° | 0.3° |
| Chebyshev diag | outside, held | trot | forward | +72° | +111° | 0.5° |

**In the room** (`room-four.lua`, 4 minutes, threads 1; distance each
walker went):

| Steering | Room | Ground | Walkers | Bracing | Timing | Direction | Turns | Rescues | Turning (braked) | Distance |
|---|---|---|---|---|---|---|---|---|---|---|
| rigid (before) | 10 m | flat | 4 | mixed | trot | as the ranking | 21 | — | — | 20.4-20.9 m |
| arcs, first try (40 cm, on-the-spot choice) | 10 m | flat | 4 | mixed | trot | as the ranking | 28 | 7 (walls) | 25-42% | 19.3-20.2 m |
| arcs | 10 m | flat | 4 | mixed | trot | as the ranking | 35 | 4 | 38-55% | 18.9-19.6 m |
| arcs | 10 m | waves 2 | 4 | mixed | trot | as the ranking | 43 | 6 | 28-70% | 14.5-17.9 m |
| backup | 10 m | flat | 4 | mixed | trot | as the ranking | 14 | 0 | 30-37% | 15.1-15.9 m |
| backup | 10 m | waves 2 | 4 | mixed | trot | as the ranking | 19 | 0 | 37-63% | 10.2-13.4 m |
| **backup** | **15 m** | flat | 4 | mixed | trot | as the ranking | 10 | 0 | 20-39% | 14.8-17.8 m |
| **backup** | **15 m** | waves 2 | 4 | mixed | trot | as the ranking | 10 | 0 | 14-28% | 15.6-16.1 m |

No walker fell. A wheel turn takes 20-40 s (most need 90-180° to clear a
wall head-on, at about 5 °/s), against a crossing of the 10 m room in about
110 s, so in that room walkers spent a third or more of the time turning.
Preferring smaller back-up turns (tried) did not help. So `room-four.lua`
and `walker-room.lua` on its own are now 15 m across (`ARENA = 1500`;
walker-room.lua's own default stays 1000): the physics costs the same (25
ms a frame with 2 threads either way; Bullet only looks at the ground under
each walker), and the walkers turn about a fifth of the time.

## After stage C (11 November)

- **Down** backs up the walker followed (on the track, the walker), and
  again walks it on: `room.setReverse`, eased over 1 s. Backing with a
  wheel braked turns it the other way (checked on the track: Jansen backing
  with the left braked turned to -26°, walking on with it braked came back
  to -8°, and held it when freed), so Down and an arrow make a three-point
  turn by hand. While it is backing by hand, as while a wheel is braked by
  hand, the room leaves that walker alone.
- **`runs/room-steer.sh`** runs a room headless (default the 11,
  `walker-room.lua` on its own; `ROOM=room-four.lua`) for `MINUTES` (4) on
  each ground in `TERRAINS` and prints the turns, rescues, walkers stood up
  again and each walker's share of the time turning and backing
  (`runs/roomlog.lua`). The 11 are too slow to run here (0.17x real time);
  on William's machine, about 8 minutes a ground at 4 threads.

## The 11-walker room, and turning by the angle (11 November)

**William's machine, `runs/room-steer.sh`** (walker-room.lua on its own:
the 11, 15 m, back-up turns, 4 minutes, threads 4):

| Ground | Walkers | Bracing | Timing | Direction | Turns (walls, walkers) | Rescues | Fell | Turning, each |
|---|---|---|---|---|---|---|---|---|
| flat | 11 | mixed | trot | as the ranking | 42 (14, 28) | 0 | 0 | 17-67%, about 40% |
| waves 2 | 11 | mixed | trot | as the ranking | 44 (20, 24) | 0 | 0 | 20-44%, about 30% |

Safe, but crowded: two thirds of the turns on flat are walkers turning
away from each other, and two walkers meeting probably both turn.

Two options (both off by default):

- **`ROOM_STEER = "curve"`** (William's idea: the angle, not the
  distance). It looks 40 cm ahead as `"backup"`, but then traces the arcs
  first: coming in at a slant needs only a small turn (30° on the 80 cm
  circle uses about 11 cm of the gap), so if an arc clears the walls and
  where the other walkers will be, it curves away walking on; head on, or
  with no clear arc, a three-point turn.
- **`ROOM_YIELD = true`:** right of way to the walker on the right. A
  walker on a crossing course from the left (more than 15° left of
  straight ahead) is left to give way; that one, by the same rule from its
  side, sees this one on its right and turns. Each decides from what it
  sees -- no word between them (the room already lets every walker see the
  others' positions and velocities). A walker within 40 cm ahead is still
  turned from, whichever side.

`room-four.lua`, 15 m, 4 minutes, threads 1 (this container):

| Steering | Ground | Walkers | Bracing | Timing | Direction | Turns (arcs, back-up) | Rescues | Turning, mean | Distance, mean |
|---|---|---|---|---|---|---|---|---|---|
| backup | flat | 4 | mixed | trot | as the ranking | 10 (0, 10) | 0 | 25.5% | 17.0 m |
| backup, yield | flat | 4 | mixed | trot | as the ranking | 9 (0, 9) | 0 | 27.7% | 16.6 m |
| curve | flat | 4 | mixed | trot | as the ranking | 12 (4, 8) | 0 | 30.2% | 16.8 m |
| curve, yield | flat | 4 | mixed | trot | as the ranking | 14 (6, 8) | 4 | 30.7% | 16.8 m |
| backup | waves 2 | 4 | mixed | trot | as the ranking | 10 (0, 10) | 0 | 21.4% | 15.8 m |
| curve | waves 2 | 4 | mixed | trot | as the ranking | 15 (10, 5) | 0 | 20.9% | 17.2 m |

(With yield on waves 2: the same runs, as no two walkers met.) Curving
works as meant -- a third to two thirds of the turns were arcs -- and on
waves 2 the walkers went 9% further for the same time turning; on flat no
clear difference. Four walkers in 15 m meet too seldom (0-5 times) to
judge right of way: the 11-walker room is the test,
`ROOM_STEER=curve ROOM_YIELD=true runs/room-steer.sh` and the other three.

**The 11-walker room, all four** (William's machine, `runs/room-steer.sh`,
4 minutes, threads 4; means over the 11 walkers):

| Steering | Ground | Walkers | Bracing | Timing | Direction | Turns (between walkers) | Rescues | Fell | Turning | Distance | Worst walker turning |
|---|---|---|---|---|---|---|---|---|---|---|---|
| backup | flat | 11 | mixed | trot | as the ranking | 42 (28) | 0 | 0 | 40.3% | 14.5 m | 67% |
| backup, yield | flat | 11 | mixed | trot | as the ranking | 34 (18) | 0 | 0 | 32.9% | 15.8 m | 59% |
| **curve** | flat | 11 | mixed | trot | as the ranking | 41 (21; 19 arcs) | 3 | 0 | **27.0%** | **17.8 m** | 49% |
| curve, yield | flat | 11 | mixed | trot | as the ranking | 47 (28; 18 arcs) | 7 | 0 | 33.6% | 16.7 m | 61% |
| backup | waves 2 | 11 | mixed | trot | as the ranking | 44 (24) | 0 | 0 | 30.3% | 14.2 m | 44% |
| backup, yield | waves 2 | 11 | mixed | trot | as the ranking | 42 (20) | 0 | 0 | 32.5% | 14.2 m | 67% |
| **curve** | waves 2 | 11 | mixed | trot | as the ranking | 55 (26; 28 arcs) | 3 | 0 | **27.2%** | **15.7 m** | 41% |
| curve, yield | waves 2 | 11 | mixed | trot | as the ranking | 51 (23; 29 arcs) | 1 | 0 | 27.3% | 16.0 m | 62% |

**Curving is the default now** (`ROOM_STEER = "curve"`): about half its
turns are arcs, which keep the walker moving, so walkers turn about a
quarter of the time, not a third or more, and go 11-23% further, at the
cost of about 3 rescues (a brief rigid swing) in 4 minutes among 11
walkers. Right of way helped once (back-up turns on flat: 28 turns between
walkers to 18) and not otherwise; with curving it made more turns and
rescues. One run each, so rough; `ROOM_YIELD` stays, off.

## Watching: the launcher must start from test-ranking.lua (8 November)

`walker-room.lua`'s own defaults are the old builds: the plated walkers
with their side plates, the diag builds with the old braces (both over
the body, high). The current ones need `DIAG_OUTSIDE = true` and the held
pendants for every diag build, and no guides builds. A launcher that
names one walker and then opens `lib/test-track.lua` gets old builds as soon
as Tab brings in another (William saw this). Start from
`test-ranking.lua` instead (its `VIEWS`: the 11 buildable builds, set up
as now; `VIEW` picks the first), as `drag-shoe.lua` (8 November) does:

    VIEW = 7; YAW_DAMP = 0; ARENA_Z = 800
    STEER = { mech = "drag", side = "L", amount = 0.25 }
    dofile("test-ranking.lua")

(`ARENA_Z = 800`: test-ranking's fast setting makes the strip 3 m wide,
and a curving walker reaches its wall.) `run-table.sh` sets each build's
bracing itself, so the tables were right.
