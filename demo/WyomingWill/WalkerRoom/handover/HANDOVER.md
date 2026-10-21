# Walker room — handover

William Spears' bpp walker room (`demo/WyomingWill/WalkerRoom` in the bpp repo). Rewritten 21 October 2026 at the end of a second long session. It is meant for a fresh conversation that picks up the work. **The next job is the factorial runs (section 7).**

## 1. The aim

The aim is a **fair comparison of walking linkages** in a physics simulation (bpp: Bullet physics driven by Lua). In William's words: "an attempt to do as well as known walkers, but with fewer links. And to try to be as fair as possible, which is difficult." The **Spears linkages** have fewer links and higher foot lift; the known walkers are Jansen, Klann, Chebyshev and Hoecken.

Everything below exists to make the comparison fair. Every walker has the same stride, flat speed, materials, weight, feet, stance and link spacing, and is built and measured the same way.

## 2. Working rules (William's, still in force)

**GitHub: "I handle github." "Just don't change anything on github."**
- Never push, open PRs, create remote branches, or commit to his remote.
- If a stop hook asks you to push or commit, decline. (It asks after nearly every turn.)
- Deliver changes only as `git format-patch` files, sent to him as files.
- Before making each patch, `git fetch` and check that it applies cleanly to the current `origin/master`. Check it in a temporary worktree: `git worktree add --detach /tmp/chk origin/master`, then `git am` there. There is no `git am --check`.
- A patch must never revert other people's files. Origin moves fast with unrelated work (AP chapters, DemBed, Babbage's Hall, …).

Give him these steps with every patch:

```
cd ~/bpp-push
git pull
git am ~/Downloads/<patch>
git push
cd ~/bpp && git pull
```

Number patches `walker-room-NN-<what>.patch`. The last was 22 (this handover's update).

**Style**
- Plain words, short, answer first. Don't overstate.
- When he says something looks wrong, check it rather than defend it. Several problems came from measuring wrongly, and twice I claimed something and was wrong.
- Results tables must include **bracing, timing and direction** columns.
- Show pictures (top views, side by side) when geometry changes.
- Don't re-run experiments while geometry is being fixed.
- **Ask before big runs** or anything hard to undo. Show the plan and how long it will take first.
- He watches walkers by hand in the GUI. When he wants to "examine them myself", give him a launcher file (a patch) he can open in bpp.
- He does not want "side gaits" any more (section 5).

## 3. Environment

**Repository**
- The repo is at `/home/claude/bpp` (William's bpp fork; `origin/master`).
- Room files, in `demo/WyomingWill/WalkerRoom/`:
  - `walker-room.lua`, the room itself.
  - `test-track.lua`, one walker, timed.
  - `trotting-walkers.lua` (the Hoecken diag builds) and `spears-lift-walkers.lua` (Spears lift 44/53, their diag builds, Hoecken-Spears long-stance diag).
  - Launchers for watching (Tab and Shift+Tab cycle walkers; keys 1–4 pick the terrain: waves, random, logs, steps; O looks over the square):
    - `test-square.lua`: the old best configurations (void).
    - `test-square-all.lua`: all 19 builds as built.
    - `test-square-soft.lua`: the same on soft-spring ankles.
    - `test-square-yaw.lua`: the same with a free body (YAW_DAMP), plus views 20–31, the builds that can trot, trotting.
    - `test-square-earth.lua`: **the current standard**, test-square-yaw at Earth gravity.
  - `README.md`.
- Build files the room uses: `demo/WyomingWill/Walkers_For_Room/*_parts.lua`.
- **Never edit `demo/WyomingWill/Walkers/`.** Those are William's originals.
- `view-all.lua` may sit untracked in the room folder. It isn't ours; leave it.

**Build**
- Packages (Ubuntu 24.04): see the repo's `Dockerfile` and `debian/`. Also install `xvfb imagemagick lua5.1` (luac, for checking generated Lua).
- Qt5 qmake, out of tree:
  ```
  mkdir -p /home/claude/build && cd /home/claude/build
  /usr/lib/qt5/bin/qmake -o Makefile ../bpp/bpp.pro
  make -j2
  ```
  This produces `/home/claude/build/release/bpp`.

**Headless runs**
- Run from `WalkerRoom`:
  ```
  QT_QPA_PLATFORM=offscreen /home/claude/build/release/bpp -f script.lua -n 3700
  ```
  `-f` means no GUI; a bare filename opens the GUI. `-n 3700` is 60 s at 60 frames per second plus a start.
- A script sets globals, then calls `dofile("test-track.lua")`, for example (the current standard):
  ```lua
  dofile("trotting-walkers.lua"); dofile("spears-lift-walkers.lua")
  ONLY="Klann"; TERRAIN="logs"; AMP=4; BUMP=15; SEED=1; GAIT={0,180,180,0}; REVERSE=true
  GRAVITY=981; FIXED=1/3840; YAW_DAMP=1; ANKLE_SPRING={stiffness=42000, damping=4200}
  dofile("test-track.lua")
  ```
- **Lua 5.1: no empty statements.** `a=1; ; b=2` fails. Join non-empty parts only.
- The output line:
  ```
  TRACK <name>|height A|length B|seed S|forward X cm|V cm/s|sideways Y cm|stood up N|air P%
  ```
  `air` is the share of frames in which the whole walker is more than 0.5 cm off the ground. Running `tools/tiltprobe.lua` in place of `test-track.lua` adds `TILT <name>|pitch max|roll max|heading`.
- In the GUI, `print` goes to bpp's console, not to a terminal. Probes write files instead.
- The ALSA errors in the output are harmless.
- **One run at the current standard takes about 2 minutes** (127 s measured; Klann, logs 4). Two at once on 2 CPUs gives about 65 s per run.

**Container**
- 2 CPUs: run 2 jobs at once.
- It is reclaimed when idle, and it restarted several times in the last session, killing batches. Start long jobs with `setsid nohup … > log 2>&1 &`, make them resumable (all the drivers here are), and check every 4–5 minutes or wait on output with a background until-loop.
- **Gotcha:** `pgrep -f name.py` inside a wait loop matches the loop's own command line. Wait on the output (a row count) or `pgrep -f "bpp -f"`.
- Bash `read` splits names at spaces; use `IFS=$'\t'`.

**Tools**
- Copy the tools before use:
  ```
  cd /home/claude/bpp/demo/WyomingWill/WalkerRoom/handover
  mkdir -p /home/claude/work/fac7
  cp tools/*.* /home/claude/work/
  ```
  The factorial scripts stay where they are (`tools/factorial7/`) and write to `/home/claude/work/fac7`. They read `/home/claude/work/tiltprobe.lua` and `/home/claude/work/footlift.json`.
- `data/` holds the raw results of the last session (section 6).

## 4. The current standard (agreed 21 October 2026)

| Setting | Value | Where |
|---|---|---|
| STRIDE | 15 cm. **The** fairness standard (William: "stick with stride as the standard"). Hip height was tried and rejected; total bar length was considered and not used. | walker-room.lua default |
| FLAT_SPEED | 9 cm/s, crank scale k calibrated per configuration, **capped at 1** (never faster than the walker's own crank) | run7.py |
| GRAVITY | **981** cm/s² (Earth). The room default is still 70, the old value. William: 981 "looks more realistic". | set per run |
| FIXED | **1/3840 s**. Timescales shrink by √(981/70) ≈ 3.7 at Earth gravity, so the step must be about 4× shorter than the old 1/960. At 1/960 the joints gave, the feet sank and cranks jammed. That was an error of the step, not physics. | set per run |
| YAW_DAMP | **1**. The body is free to pitch and roll; only its turning about the vertical is damped (in preSim). The walkers' own files set angular damping 1.0 every way (a "straight-line fix"), which held up walkers standing on one side's feet. | set per run |
| ANKLE_SPRING | **{stiffness = 42000, damping = 4200}**. Soft-spring ankles: each foot hinged to its leg and held level to the body by a soft spring, so it lands level and can rock on a bump. ×14 the value at gravity 70 (3000/300), to match. William: "I like the soft feet. It looks natural." | set per run |
| SAME_BODY, SAME_FEET, WIDE, LINK_THICK, PLANE_GAP, BALANCE, BAR_MASS, SOLVER_ITERATIONS 40, LOCK_CRANKS | as patch 13 (section 8) | walker-room.lua defaults |
| Gaits | **No sides gaits.** Trot, bound, four 4-beat walks (the other two are mirror images), and Spears 4-bar's own timing. | run7.py |

`test-square-earth.lua` is this standard for watching.

## 5. What was found in the last session (17–21 October)

**Logs and foot tilt.** On the log terrain only a few walkers moved forward. William's reading, confirmed: if a foot can't rise over the log, its front hits the log and kicks the walker back, often into the air. Lift is necessary but not sufficient. The feet were welded to the legs and tilted with them, so the toe dug in. That led to the ankle work.

**GUI speed** (patch 17, `src/objects/terrain.cpp/.h`). The terrain was drawn triangle by triangle every frame, which was slow and kept the CPU at 100% even when nothing moved. It now uses OpenGL display lists in chunks of 4096 triangles, re-recorded only when a chunk's colours change. Tab no longer rebuilds the terrain (patch 16: `replaceWalker`, `rebuildTrack`).

**Feet** (patch 18: ANKLE_SPRING, ANKLES, FOOT_TIPS, FOOT_ROD, FOOT_POINT in walker-room.lua). Mean speed over the four bumpy terrains, as built, forward, gravity 70, cm/s:

| Feet | Mean |
|---|---|
| Soft spring | 5.97 |
| Flat 8 × 12 cm, welded | 5.87 |
| Point (ski-pole tip, no foot) | 5.11 |

By terrain (soft / flat / point): waves 7.52 / 7.68 / 5.37, random 7.73 / 7.51 / 6.88, logs 4.22 / 3.81 / 4.14, steps 4.39 / 4.49 / 4.06. The soft spring's gain is mostly on logs. It was chosen. Rods (FOOT_ROD) and toe tips (FOOT_TIPS) were tried on logs only: rod 4.07, tips 3.80, tips with the spring 3.95, against soft 4.22. Raw data: `data/feet_*.txt` (waves, random, steps; logs for point) and `data/logs_*.txt` (logs, AMP 2/4/6).

**Leg size.** At the 15 cm stride the leg heights are Spears lift 44 27.4 cm, Klann 31.0, Jansen 31.9. The Spears lift walkers don't win by being bigger.

**Body damping** (patch 19, BODY_ANG_DAMP and YAW_DAMP). The walkers' files damp body rotation at 1.0, which kills pitch and roll and props up the sides gait. With the body free (yaw only), sides walkers tip over and stall, and trotting ones are fine. Gravity 70, soft feet, mean of 26 runs (flat, and the four terrains at AMP 2/4/6, seeds 1–2), cm/s:

| Walker | Bracing | Timing | Damping 1.0 | Damping 0.1 | Yaw only |
|---|---|---|---|---|---|
| Klann | own | sides | 7.01 | 0.39 | 0.39 |
| Jansen | own | sides | 6.44 | 0.25 | 0.24 |
| Chebyshev-Spears | plates | sides | 6.45 | 1.31 | 1.83 |
| Spears lift 44 | plates | sides | 7.78 | 3.36 | 3.34 |
| Spears 4-bar | own | its own (0/225/180/225) | 4.58 | 0.78 | 1.71 |
| Klann | own | trot | 7.47 | 5.78 | 5.53 |
| Jansen | own | trot | 7.17 | 6.06 | 6.33 |
| Spears lift 44 diag | diag | trot | 7.68 | 6.84 | 7.59 |

All forward. Raw data: `data/damp6.txt`. Freeing the body costs every walker something, trotting ones least. Spears 4-bar's own timing fails too, which is why its gaits get searched. **So the sides gaits were dropped** (William: "Just not 'side gaits'"). Plated builds force sides, so the plated configurations are gone too.

**Gravity** (patch 20). Gravity 70 let walkers jump and float down slowly. At 981 with step 1/3840: Jansen trot 10.00 cm/s on flat, roll about 1°. Step check (`data/conv.txt`): halving the step changes speeds by 0.21 cm/s on average at 70 (1/960 → 1/1920) and 0.32 at 981 (1/3840 → 1/7680); the largest change was Chebyshev on logs (3.03 → 5.22), likely chance on one start. At 981, obstacles go better, especially for Klann (logs 4 cm: 5.52 → 8.07) and Jansen (5.03 → 7.38), against Spears lift 44 diag's 8.19 (`data/grav.txt`).

**Spears 4-bar gaits** (`data/gaits_s4.txt`, old standard, now void): with damping 1.0 and welded feet, sides reversed was best at 7.00. Not valid under the free body.

**Guides are not diag braces** (21 October, `data/gd.txt`, `tools/gd.py`). Guides (UNBRACED) are an ideal, weightless joint holding each leg at its angle to the body; diag braces are real bars, weighed like the rest, welded leg to leg across the body. Both trot. Earth standard, forward, own crank speed, seed 1, cm/s, guides / diag:

| Linkage | Flat | Waves 4 | Logs 5 | Steps 4 |
|---|---|---|---|---|
| Chebyshev | 9.04 / 9.11 | 4.73 / 2.11 | 4.02 / 0.59 | 6.76 / 5.78 |
| Chebyshev-Spears | 9.40 / 9.45 | 7.40 / 2.11 | 7.22 / 4.59 | 8.48 / 8.31 |
| Hoecken 4-bar | 9.01 / 8.55 | 6.61 / 2.22 | 1.52 / 2.19 | 6.83 / 5.76 |
| Hoecken-Spears 4-bar | 9.20 / 8.90 | 7.73 / 2.75 | 6.63 / 5.26 | 8.27 / 7.97 |
| Hoecken-Spears long-stance | 9.51 / 8.84 | 8.39 / 5.49 | 2.21 / 2.18 | 8.33 / 7.70 |
| Spears lift 44 | 8.92 / 8.82 | 6.95 / 2.27 | 7.92 / 8.16 | 8.37 / 8.15 |
| Spears lift 53 | 8.89 / 8.90 | 5.48 / 0.63 | 7.45 / 7.22 | 7.92 / 7.95 |

Same on flat; on waves every diag build is far slower (and turns: headings 270–335° at the end, against about 0° on guides); closer on logs and steps. One seed, so single numbers are noisy, but the waves gap is in all seven. The cause is not known yet; worth watching a diag build on waves in the GUI. **So both bracings stay in the factorial**, and the tables show what the bracing costs.

**The body now counts, not just the linkage** (21 October). William, watching at the new standard: "Now that the body can pitch, and the gravity has increased, the body can dip on one side, raising the feet on the other side. Some walkers can now clear logs of height 7." Agreed, after some discussion:
- The **free-body result is the main result**. A real build rocks too.
- The **linkage alone** is measured by the foot's lift from the geometry (`tools/footlift.py` → `footlift.json`; the "lift" values). It's cleaner than any locked-body run, because a damped body is neither the real machine nor the linkage alone.
- The **body's share** is the log height cleared minus the lift.
- With the standards held, rocking differences come from the linkage (hip height, foot path, landing, leg mass) except for **gait and bracing**, which are choices. They are table columns, so they stay visible.
- Report **two tables**: everyone at trot (same gait; guides, or the own frame for Jansen, Klann and Spears 4-bar), the controlled comparison; and the best of each linkage, where each gets its own best gait and bracing. They can disagree.

## 6. Raw data from the last session (`data/`)

| File | What it is |
|---|---|
| `feet_soft.txt`, `feet_flat8.txt`, `feet_point.txt` | Feet comparison (terrains.py), gravity 70 |
| `damp6.txt` | Damping test (damp6.py): damping 1.0 / 0.1 / yaw only |
| `grav.txt` | Gravity 70 against 981 (981 lines here are at the old step and invalid; the valid 981 check is in `conv.txt`) |
| `conv.txt` | Step-size check at 70 and 981, with SINK (foot depth) |
| `gaits_s4.txt` | Spears 4-bar's gaits, old standard |
| `gd.txt` | Guides against diag braces, Earth standard (tools/gd.py) |
| `logs_flat8.txt`, `logs_soft.txt`, `logs_rod.txt`, `logs_tips.txt`, `logs_tips_soft.txt` | Every build as built on logs, AMP 2/4/6, gravity 70, by foot (logs_all3.py); LOGS lines count face hits and kick-backs |

All but `gd.txt` come before the current standard and are for the record, not results.

## 7. Next: the factorial runs

This is the original task's step 2, never yet done on the new geometry. William approved doing it; **he has not yet seen the timing below. Show it to him and get a yes before starting.**

**Configurations: 70** (`tools/factorial7/run7.py list` prints them).
- Jansen, Klann and Spears 4-bar on their own frames: trot, bound, and four 4-beat walks (6 gaits; Spears 4-bar adds its own 0/225/180/225 for 7). Of the six orders of 90/180/270, two pairs are the same walk with the sides swapped, so one of each pair is run (William: "That is safe.").
- The other nine linkages (Chebyshev, Chebyshev-Spears, Hoecken 4-bar, Hoecken slider, Hoecken-Spears slider, Hoecken-Spears 4-bar, Hoecken-Spears long-stance, Spears lift 44, Spears lift 53): trot on diag braces (not the sliders) and trot on guides.
- Each both forward and reversed.
- Leg order in GAIT: side A leg 1, side A leg 2, side B leg 1, side B leg 2. Trot is {0,180,180,0}, bound {0,180,0,180}, sides (dropped) {0,0,180,180}.

**Stages**
1. **Smoke test** first: `python3 run7.py screen Klann_own_trot_fwd`. Check that `cal.json` and `A_Klann_own_trot_fwd.txt` look right (TRACK and TILT on each line). If the calibrated flat speed is well below 9 with k at its cap of 1, note it; at gravity 981 some walkers may be slower.
2. **Screen (stage A)**: `run7.py screen`. Calibrate on flat (waves AMP 0, BUMP 22, seeds 1–2, up to 3 iterations), then 4 runs at seed 1: waves 4, random 4, logs 5, steps 4. Writes `A_<id>.txt`.
3. **Pick**: `run7.py pick`. Per linkage, the 2 best screened configurations, plus its trot on guides or its own frame both ways (for the everyone-at-trot table). Writes `picks.json`. **Show William the picks** before stage B.
4. **Full (stage B)**: `run7.py full`. Waves, random and steps at AMP 2/4/6, plus logs at 4/5/6/7/8 cm, BUMP 15, seeds 1–2: 28 runs per picked config. Writes `B_<id>.txt`.
5. **Analysis**: `python3 an7.py` prints the two tables (with bracing, timing, direction, each terrain, the highest log cleared, the foot lift, and "body adds"), then forward against reversed for every pair. "Clears" is the highest log height with a mean of at least 2 cm/s.

Run each stage with `setsid nohup python3 /home/claude/bpp/demo/WyomingWill/WalkerRoom/handover/tools/factorial7/run7.py screen > /home/claude/work/fac7/screen.log 2>&1 &`. Every stage resumes where it stopped if rerun.

**Time** (at about 65 s per run, two at once):

| Stage | Runs | Time |
|---|---|---|
| Screen | 70 × (2–6 calibration + 4), about 470–550 | about 8.5–10 hours |
| Full | about 36 picked × 28, about 1000 | about 18 hours |
| Total | | **about 27 hours** |

Ways to cut, if he wants:
- Full at seed 1 only: halves stage B (about 9 hours), but one start is noisy (see the step check).
- Test direction at trot only, and run the gait search in the better direction: drops about 22 configurations. Risk: the best direction may depend on the gait.
- Pick 1 best per linkage instead of 2, and its trot in the better direction only: stage B from about 36 to about 24 configurations (about 12 hours). Risk: a runner-up that would do better on the full set never gets there.
- **Not** guides: they run differently from diag braces (section 5), so both stay.
- Shorter logs sweep (5, 6, 7 cm): saves about 15% of stage B.

**Report to William**
- The best of each linkage, with bracing, timing and direction columns.
- Everyone at trot.
- Foot lift against log height cleared, and how much the body adds.
- Whether "reversed is better" still shows up now that the walkers are balanced and the body is free. (Old runs showed it suspiciously often, though most foot paths are symmetric; the balance fix in patch 13 was aimed at that.)
- One start is noisy; say so where differences are small.

**Then**
1. Make a launcher (or update `test-square-earth.lua`'s VIEWS) with the best configuration of each linkage, so William can watch them, with crank values from `cal.json`.
2. Update the README: "The factorial runs", "The best version of each walker" and "Other terrains" still hold the old, void results. Describe the current standard (section 4) as the measuring conditions.
3. Patch, check against origin, send, with the steps in section 2.

## 8. The geometry rework (patch 13, still in force)

All of this came before the last session's work. Every result before it is void.

1. **Links uniform.** Every link is 0.3 cm thick, in planes 0.7 cm apart (0.4 cm gap between faces).
2. **Fewest planes** per walker (`spec.planes`), from sweeping every link through a full crank turn: Jansen 3 (was 7), Klann 3 (was 5), Spears 4-bar 2, most 4-bars 3, Chebyshev-Spears diag and Hoecken-Spears long-stance (and its diag) 4. Both sliders keep their own 2-plane layout: **don't change the sliders' planes**; they jam.
3. **Feet centred under the leg.**
4. **Stance exactly 38.0 cm** between outer foot edges, measured from the static geometry at build, in the body frame. (FOOT_POINT keeps it by widening the body.)
5. **Body height** 12 cm, or higher to leave 1 cm between a foot's top and the lowest link: Spears lift 44 12.46, 44 diag 13.13, 53 14.33, 53 diag 15.2.
6. **Balance.** Each walker's 40 kg load is slid along the walk so the centre of mass, averaged over a crank turn, sits midway between front and back feet (within 0.01 cm). Walkers with `forward = -1` are turned 180° in the room, so a file-frame x is the negative of world x.
7. **Frame plus load.** The body is one rigid body: load at the balance point, a box (compound child) spanning the leg mounts 3 cm past each end. `opts.bodyFrame(cube)` in `addWalker`; each `_parts.lua` calls it after its bodyShift line. The new body copies the old one's damping, friction and restitution.
8. **Body inertia fix.** Inertia is BODY_BOX's (40 × 3 × 30 cm) for every walker. In bpp, setting `obj.mass` recomputes inertia from the shape, so set the mass before `setMassProps`.

Checks after the rework: no jams; links touch at most 0.7% of the time; the body never touches the ground. Top views: `walkers_from_above.png`.

## 9. Tools (`handover/tools/`)

All of them assume `/home/claude/bpp`, `/home/claude/build/release/bpp` and `/home/claude/work`.

**Factorial (`tools/factorial7/`)**

| File | What it does |
|---|---|
| `run7.py list / screen / pick / full [id part]` | The factorial at the current standard (section 7) |
| `an7.py` | Its tables |

The older `tools/factorial/` (run.py, st2.py, an.py, st2an.py) is the previous design, kept for reference.

**Probes** (each runs `test-track.lua` and adds a line)

| File | Adds |
|---|---|
| `tiltprobe.lua` | `TILT`: largest pitch and roll, heading change |
| `standprobe.lua` | Body height (mean, lowest), roll, how far joints pull apart |
| `sinkprobe.lua` | `SINK`: how deep feet go into the ground |
| `linkprobe3.lua` with `jamcheck2.py ["extra lua"]` | Links touching, body on ground, on four terrains |
| `bodyhit.lua` | What the body touches |

**Geometry**

| File | What it does |
|---|---|
| `footlift.py` → `footlift.json` | Foot lift over the path from `sweep2/` (made by `sweep_all.sh`). The json was made 18 October, after patch 13; an7.py uses its "lift" values. The sweeps themselves were lost in a container restart, so rerun `sweep_all.sh` before regenerating. |
| `mountprobe.lua`, `mount_all.sh` | Frame ends and leg mounts |
| `planprobe.lua`, `plan_all.sh OUT` (absolute path), `plan_draw.py` | Top-view picture of all builds |
| `sweepprobe.lua`, `sweep_all.sh`, `sweep_roles.sh`, `planes.py` | Link sweeps and fewest planes |
| `balance.py`, `footclear.py`, `raisefix2.py`, `stancefix.py`, `plan_an.py` | Balance, foot clearance, body height, stance |

**Older drivers** (resumable; paths and settings at the top): `gd.py` (guides against diag), `terrains.py` (feet), `damp6.py` (damping), `gaits_s4.py` (Spears 4-bar gaits), `logs_all3.py` (every build on logs).

## 10. Lessons

- Measure geometry statically, in the body frame. Never use world bounding boxes while walking.
- Check each new measuring script against something known before reporting from it.
- When changing gravity, scale the step (and springs) with it. Check by halving the step.
- Don't blame physics before checking the step. (I claimed a large roll at 981 was real; it was the step.)
- Don't drop a contender from a comparison without saying why. (I left the soft spring out of one feet comparison; William caught it.)
- In bpp: setting `obj.mass` resets inertia; swapping an object's body loses what was set on the old one; `btTransform` has no `*` in Lua (use `inverseTimes`); `getOrigin` isn't bound (use `getCenterOfMassPosition`); constraint setters need their full argument lists.
- Look at pictures from above after every geometry change.
