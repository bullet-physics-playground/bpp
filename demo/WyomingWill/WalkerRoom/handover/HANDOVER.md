# Walker room — handover

William Spears' bpp walker room (`demo/WyomingWill/WalkerRoom` in the bpp repo), written 17 October 2026 at the end of a long session. It is meant for a fresh conversation that picks up the work.

## 1. The aim

The aim is a **fair comparison of walking linkages** in a physics simulation (bpp: Bullet physics driven by Lua). William's thesis is that the **Spears linkages** (fewer links, higher foot lift) do better on bumpy ground than the classics (Jansen, Klann, Chebyshev, Hoecken).

Everything below exists to make the comparison fair: every walker has the same stride, flat speed, materials, weight, feet, stance and link spacing, and is built and measured the same way.

## 2. Working rules (William's, still in force)

**GitHub: "I handle github." "Just don't change anything on github."**
- Never push, open PRs, create remote branches, or commit to his remote.
- If a stop hook asks you to push or commit, decline.
- Deliver changes only as `git format-patch` files, sent to him as files.
- Before making each patch, `git fetch` and check that it applies cleanly to the current `origin/master`.
- A patch must never revert other people's files. Origin moves fast with unrelated work: AP chapters, DemBed, Brazil nut.

Give him these steps with every patch:

```
cd ~/bpp-push
git pull
git am ~/Downloads/<patch>
git push
cd ~/bpp && git pull
```

**Style**
- Plain words, short, answer first. Don't overstate.
- When he says something looks wrong, check it rather than defend it. Several "days-long" problems came from measuring wrongly.
- Results tables must include **bracing, timing and direction** columns.
- Show pictures (top views, side by side) when geometry changes.
- Don't re-run experiments while geometry is being fixed. Fix and verify the geometry first, then run.
- Ask before big runs or anything hard to undo.

## 3. Environment

**Repository**
- The repo is at `/home/claude/bpp` (GitHub: William's bpp fork; `origin/master`).
- Room files: `demo/WyomingWill/WalkerRoom/`:
  - `walker-room.lua`, the room itself.
  - `test-track.lua`, one walker, timed.
  - `test-square.lua`, for watching; Tab cycles walkers, keys 1–4 pick the terrain.
  - `trotting-walkers.lua`, the Hoecken diag builds.
  - `spears-lift-walkers.lua`, Spears lift 44/53, their diag builds and the Hoecken-Spears long-stance diag.
  - `README.md`.
- Build files the room uses: `demo/WyomingWill/Walkers_For_Room/*_parts.lua`.
- **Never edit `demo/WyomingWill/Walkers/`.** Those are William's originals.

**Build**
- Qt5 qmake, out of tree:
  ```
  mkdir -p /home/claude/build && cd /home/claude/build
  /usr/lib/qt5/bin/qmake -o Makefile ../bpp/bpp.pro
  make -j2
  ```
  This produces `/home/claude/build/release/bpp`.
- Ubuntu 24.04, Qt 5.15, Bullet from `/usr/include/bullet`, plus assimp, boost and luabind as the `.pro` file needs. The repo's `Dockerfile` and `debian/` list the packages.

**Headless runs**
- Run from `WalkerRoom`:
  ```
  QT_QPA_PLATFORM=offscreen /home/claude/build/release/bpp -f script.lua -n FRAMES
  ```
- Test-track runs use `-n 3700` (60 s at 60 frames per second plus a start).
- A script sets globals, then calls `dofile("test-track.lua")`, for example:
  ```lua
  dofile("trotting-walkers.lua"); dofile("spears-lift-walkers.lua")
  ONLY="Spears lift 44"; AMP=4; BUMP=15; TERRAIN="steps"; SEED=2; REVERSE=true; GAIT={0,180,180,0}
  dofile("test-track.lua")
  ```
- The output line looks like:
  ```
  TRACK <name>|height A|length B|seed S|forward X cm|V cm/s|sideways Y cm|stood up N|air P%
  ```
  `air` is the share of frames in which the whole walker is more than 0.5 cm off the ground.
- The ALSA errors in the output are harmless.

**Container**
- The container has 2 CPUs. Run 2 jobs at once.
- It is reclaimed when idle, so start long jobs with `setsid nohup … &`. Poll at intervals of 5 minutes or less, or use a Monitor/background wait.
- **Gotcha:** `pgrep -f jamcheck2.py` inside a wait loop matches the loop's own command line, so the loop never ends. Wait on the output instead, for example a row count, or `pgrep -f "bpp -f"`.

**Patches**
- Patches 8–12 are on GitHub. The last walker commit there is "Walker room: diag walkers' braces both over the body, one arched".
- **Patch 13**, `walker-room-13-geometry.patch`, holds all the geometry work described below, plus this handover. It lives in `demo/WyomingWill/WalkerRoom/handover/` with the top-view picture and the tools. If you can read this in the repo, the patch is pushed.
- Copy the tools to the work folder before use: `mkdir -p /home/claude/work/fac5 && cp demo/WyomingWill/WalkerRoom/handover/tools/*.* /home/claude/work/ && cp demo/WyomingWill/WalkerRoom/handover/tools/factorial/*.py /home/claude/work/fac5/`. The factorial scripts find each other and write their results in `/home/claude/work/fac5`; run them as `python3 /home/claude/work/fac5/run.py`, then `st2.py`.

## 4. What the room does (settings in walker-room.lua, defaults)

| Setting | Default | What it does |
|---|---|---|
| STRIDE | 15 cm | Every walker is scaled so its foot path is 15 cm long. |
| FLAT_SPEED | 9 cm/s | Sets each walker's crank speed. CRANK_SCALE multiplies it. |
| GRAVITY | 70 cm/s² | The same for every walker. |
| FIXED | 1/960 s | Physics step. SOLVER_ITERATIONS 40, MOTOR_STRENGTH 10, LOCK_CRANKS on. |
| BAR_MASS | {density 0.18 per cm, bolt 0.15 per joint end} | Every bar weighed by one rule. |
| SAME_BODY | on | Body mass is BODY_MASS 40. Its turning inertia is that of a BODY_BOX of 40 × 3 × 30 cm, the same for every walker. **Total mass varies**: 40 plus the legs, about 90–115. |
| SAME_FEET | on | Every foot is 8 × 12 × 0.5 cm, mass 1.5, **centred under its leg**. |
| WIDE | on | Every walker is 38.0 cm between the outer foot edges (`wide.cube_d` per spec). |
| LINK_THICK | 0.3 cm | Every link's thickness. |
| PLANE_GAP | 0.7 cm | Centre-to-centre spacing of link planes, leaving a 0.4 cm gap between faces. At 0.2 cm, neighbouring links rubbed up to 10% of the time. |
| spec.planes | — | Each link's plane, as few planes as keep links from touching (section 5). |
| BALANCE | on | Body slid to balance; body built as a frame plus a load (section 5). |
| DIAG_ARCH | on | On diag walkers both diagonal braces run over the body; the second arches up by spec.brace.rise cm. |
| DIAG_GIVE | 0 | Diag braces are rigid. |
| BRACE_CLEARANCE | 7 | Cuts or raises brace plates for clearance. |
| ANKLES | false | Hinged feet off. |
| REVERSE, GAIT, UNBRACED | — | Direction, timing (TROT = {0,180,180,0}) and bracing (guides instead of plates). |
| MARKS | on | Colours, gold trim (Spears), diagonal line (diag) and code letters on the body. These are decorations with no contact response. |

## 5. The geometry rework (patch 13)

All of this is new since the last factorial runs, so **every earlier result is void.**

1. **Links uniform.** Every link is 0.3 cm thick, in planes 0.7 cm apart.

2. **Fewest planes.** Each walker uses as few planes as keep its links from touching (`spec.planes`, link → plane, counted out from the body face). The test was made by sweeping every link through a full crank turn:
   - Links of the same leg may share a plane if they are never in the same place at the same moment (with 0.2 cm spare).
   - Links of different legs may share only if the areas they sweep never meet, whatever the gait.
   - Hinged pairs must be in different planes. Welded pairs may share.
   - The pendant is outermost where there are braces.
   - Pins aren't checked (the simulation has none).

   Result:

   | Walker | Planes |
   |---|---|
   | Jansen (was 7) | 3 |
   | Klann (was 5) | 3 |
   | Spears 4-bar | 2 |
   | Most 4-bars | 3 |
   | Chebyshev-Spears diag, Hoecken-Spears long-stance and its diag | 4 |
   | Both sliders | 2, their own layout (reassigning their planes made them jam) |

3. **Feet centred under the leg.** `foot_center_z = zp`; Jansen and Klann lost their offset.

4. **Stance exactly 38.0 cm** between outer foot edges, measured from the static geometry at build, in the body frame. The old measure used world bounding-box maxima while walking, which was wrong; it caused days of trouble.

5. **Body height.** The body is at 12 cm, or higher if needed to leave 1 cm between the top of a foot and the lowest link (`chassis.bodyRaise`):

   | Walker | Body height (cm) |
   |---|---|
   | Spears lift 44 | 12.46 |
   | Spears lift 44 diag | 13.13 |
   | Spears lift 53 | 14.33 |
   | Spears lift 53 diag | 15.2 |
   | All others | 12 |

6. **Balance (BALANCE, spec.bodyShift).**
   - Most files mounted their legs off the body's middle; Klann put 77% of its weight on one pair of feet. Each walker's 40 kg load is now slid along the walk so that the whole walker's centre of mass, averaged over a crank turn, sits midway between its front and back feet's path middles. Every walker is now within 0.01 cm.
   - The slides, in cm, in each file's own frame:

     | Walker | Slide | Walker | Slide |
     |---|---|---|---|
     | Klann | −29.44 | Spears 4-bar | +19.44 |
     | Spears lift 53 | 17.77 | Spears lift 53 diag | 18.07 |
     | Spears lift 44 | 12.77 | Spears lift 44 diag | 12.99 |
     | Jansen | −5.94 | 4-bars and diag builds | 2.9–5.5 |
     | Sliders | about −0.3 | | |

   - **Sign trap:** walkers with `forward = -1` are turned 180° in the room, so a file-frame x is the negative of world x.
   - The motive was William's remark that "reverse is better" showed up suspiciously often, though most foot paths are symmetric. Imbalance may have been the cause. The rerun will tell.

7. **Frame plus load (spec.frame = { length, x }).**
   - The body is one rigid body. Its centre of mass (the load) sits at the balance point. Its box, a `btCompoundShape` child that is drawn and can collide, spans the leg mounts, from 3 cm before the first to 3 cm past the last, and is offset `x` cm from the load in the file frame.
   - Lengths:

     | Walker | Length (cm) |
     |---|---|
     | Most | 41–50 |
     | Spears 4-bar | 59.9 (its mounts are 54 cm apart) |

   - Klann's load sits 0.2 cm off the back end of its frame.
   - Implementation:
     - `opts.bodyFrame(cube)` is defined in `addWalker`. Each `_parts.lua` calls it right after the bodyShift line: `if opts.bodyFrame then cube = opts.bodyFrame(cube) end`.
     - It returns a new tiny Cube whose body is the compound.
     - The visible frame is a decor box, and the marks shift by `frame.x` in `decor()`.
     - `placeMarks` now runs every frame, whatever MARKS is.
   - The new body copies the old one's damping, friction and restitution. Without the damping, which some files set before the swap, Chebyshev-Spears and others slowed to 2–4 cm/s.
   - An earlier attempt lengthened the box symmetrically about the load. That gave bodies up to 100 cm long, and William rightly objected.

8. **Bug fixed — body inertia.**
   - The room set `w.cube.body:setMassProps(m, BODY_BOX inertia)` and then `w.cube.mass = m`. In bpp, setting `.mass` recomputes inertia from the object's own shape, so BODY_BOX never took effect. Every earlier run had each walker's own body-box inertia.
   - The order is now swapped, and each body's turning inertia is BODY_BOX's (3030 / 8333 / 5363).
   - **This is another reason all earlier results are void.**
   - `setBarMasses` uses the same set-then-assign pattern for bars. It is harmless there, because shape inertia scales with mass.

### Verified after the rework

- **Mounts.** Every frame spans its leg mounts with 2.95–3 cm to spare (`tools/mount_all.sh` → `mounts3.txt`).
- **Touching check** (`tools/jamcheck2.py`): flat, 6 cm waves, 4 cm logs and 4 cm steps, seed 2, 60 s each:
  - No jams.
  - Links touch each other at most 0.2% of the time.
  - The body never touches the ground.
  - The numbers after the frame change are in section 9.
- **Top views.** `walkers_from_above.png`, next to this file, (`tools/plan_all.sh` then `tools/plan_draw.py`). The red square marks the load.

## 6. The factorial runs (to redo)

- **Configurations: 80.**
  - Each linkage × bracing (own frame for Jansen, Klann and Spears 4-bar; plates; diag braces; guides = UNBRACED) × timing (sides; trot) × direction (forward; reversed).
  - Plates force sides; diag forces trot; guides take either. The sliders have no diag build.
  - The list is in `tools/factorial/run.py`.
- **Calibration.** Find the crank scale `k` that gives 9 cm/s on flat (waves, AMP 0, BUMP 22, seeds 1 and 2). **Cap `k` at 1**: a crank never turns faster than its own speed. Without the cap, Spears lift 44 and 53 needed cranks 38–43% faster, bounded off the ground 33–39% of the time, and were faster on bumps than on flat. `run.py` now enforces the cap.
- **Stage 1.** Waves at 10 settings: (0,22) (2,11) (2,15) (2,22) (4,11) (4,15) (4,22) (6,11) (6,15) (6,22). The pairs are (AMP, BUMP) in cm, seeds 1 and 2.
- **Stage 2** (`st2.py`). The top 2 configurations per linkage go on to random, logs and steps at (2,11) (2,22) (4,11) (4,22) (6,11) (6,22), seeds 1 and 2.
- **Analysis.** `an.py` (stage 1) and `st2an.py` (stage 2).
- **Run time.** About 80 × (cal + 20 runs) at about 75 s per run on 2 CPUs, many hours. Run it in the background with `setsid nohup`.
- **Folder.** Results go to `/home/claude/work/fac5` (set in the scripts).

The previous best configurations (old geometry, now void) are in README "The factorial runs" and in `test-square.lua`'s VIEWS list. After the rerun, both must be updated: the README tables and the VIEWS order, labels and crank values.

## 7. Still to do, in order

1. Check patch 13 is pushed. If not, apply it locally.
2. **Update README.md** for the new geometry. It still says the body is at 12 cm everywhere, says nothing about planes, centred feet, the 38 cm static stance, balance, the frame, or the inertia fix, and holds the old factorial tables. Send it as its own patch.
3. **Rerun the factorial runs** (section 6). Report best per linkage on waves and on the other terrains, with bracing, timing and direction columns. Note whether "reversed is better" still dominates now that the walkers are balanced.
4. Update `test-square.lua` VIEWS to the new best configurations. Update README "The factorial runs", "The best version of each walker" and "Other terrains".
5. Patch, check it against origin, send, with the steps in section 2.

## 8. Tools (`handover/tools/`, copied to /home/claude/work)

All of these assume `/home/claude/bpp`, `/home/claude/build/release/bpp` and `/home/claude/work`. Edit the paths if they differ.

**Probes and checks**

| File | What it does |
|---|---|
| `mountprobe.lua`, `mount_all.sh [out]` | Each walker's frame ends and leg mount range, x from the load (world frame). |
| `planprobe.lua`, `plan_all.sh OUT` (absolute path!), `plan_draw.py` | Top-view picture of all 19 builds. Reads `plan.txt` in the cwd. |
| `sweepprobe.lua`, `sweep_all.sh` (→ `sweep2/`), `sweep_roles.sh` (→ `sweep/`, every link in its own plane) | Holds the walker 200 cm up, cranks it one turn, and logs every link outline. |
| `planes.py` | Fewest planes from `sweep/`, written to `planes.json`. |
| `balance.py` | Centre of mass against the support middle, from `sweep2/`, written to `balance.json`. |
| `footclear.py`, `raisefix2.py` | Foot-to-link clearance and body height. |
| `stancefix.py`, `plan_an.py` | Static stance. |
| `jamcheck2.py ["extra lua"]` with `linkprobe3.lua` | Self-contact and body-on-ground (decorations excluded) on 4 terrains, plus speed. |
| `bodyhit.lua` | What the body is touching. |

**Factorial**

| File | What it does |
|---|---|
| `factorial/run.py` | Calibration, then stage 1. |
| `factorial/st2.py` | Stage 2. |
| `factorial/an.py`, `factorial/st2an.py` | Analysis. |

## 9. Last check (frame plus load, inertia fixed)

`jamcheck2.py` after the frame change and the inertia fix, with damping carried over. Seed 2, one 60 s run each, so these are a sanity check, not results.

| Walker | Links touching (max) | Body on ground | Flat | Waves 6 | Logs 4 | Steps 4 (cm/s) |
|---|---|---|---|---|---|---|
| Jansen | 0.0% | 0 | 10.33 | 6.57 | 0.26 | 6.19 |
| Klann | 0.0% | 0 | 9.53 | 7.90 | 6.91 | 8.34 |
| Spears 4-bar | 0.0% | 0 | 8.87 | 5.84 | 5.22 | 1.30 |
| Chebyshev | 0.0% | 0 | 8.28 | 6.74 | 0.33 | 0.46 |
| Chebyshev diag | 0.0% | 0 | 9.20 | 7.65 | 0.09 | 0.48 |
| Chebyshev-Spears | 0.3% | 0 | 8.42 | 8.23 | 0.23 | 6.16 |
| Chebyshev-Spears diag | 0.7% | 0 | 8.66 | 8.65 | 0.22 | 0.45 |
| Hoecken 4-bar | 0.0% | 0 | 8.39 | 7.19 | 0.18 | 0.45 |
| Hoecken 4-bar diag | 0.0% | 0 | 8.59 | 7.28 | 0.33 | 0.52 |
| Hoecken slider | 0.0% | 0 | 8.23 | 6.76 | 0.25 | 5.75 |
| Hoecken-Spears slider | 0.0% | 0 | 7.79 | 7.96 | 1.90 | 4.44 |
| Hoecken-Spears 4-bar | 0.1% | 0 | 8.00 | 7.97 | 0.33 | 6.17 |
| Hoecken-Spears 4-bar diag | 0.0% | 0 | 8.71 | 8.13 | 3.17 | 2.85 |
| Hoecken-Spears long-stance | 0.0% | 0 | 8.50 | 8.19 | 0.36 | 0.48 |
| Hoecken-Spears long-stance diag | 0.0% | 0 | 8.05 | 8.04 | 0.13 | 2.87 |
| Spears lift 44 | 0.0% | 0 | 7.97 | 7.84 | 7.39 | 7.17 |
| Spears lift 44 diag | 0.0% | 0 | 7.35 | 7.99 | 7.19 | 6.80 |
| Spears lift 53 | 0.0% | 0 | 7.63 | 7.17 | 6.86 | 6.45 |
| Spears lift 53 diag | 0.0% | 0 | 7.70 | 8.78 | 6.42 | 6.01 |

How the check was run:
- Default build for each walker: no GAIT; REVERSE except lift 44, lift 44 diag and lift 53.
- Crank at its own speed, not calibrated.
- "Body on ground" excludes the body's own decorations. An earlier version of the check counted them by mistake.

What it shows:
- No jams.
- Links touch at most 0.7% of the time (Chebyshev-Spears diag, brief brushes).
- The body never touches the ground.
- Only Klann and the Spears lift walkers keep going on 4 cm logs.

## 10. Lessons from this project

- Measure geometry statically, in the body frame. Never use world bounding boxes while walking.
- Check each new measuring script against something known before reporting from it. A body-on-ground count once reported up to 39% because it counted decorations.
- Look at pictures from above after every geometry change.
- In bpp, setting `obj.mass` resets inertia from the object's shape.
- Swapping an object's body loses anything set on the old body.
- `plan_all.sh` needs an absolute output path.
- Don't change the slider walkers' plane layout; they jam.

