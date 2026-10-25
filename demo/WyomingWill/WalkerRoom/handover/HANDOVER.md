# Walker room — handover

William Spears' bpp walker room (`demo/WyomingWill/WalkerRoom` in the bpp repo). Rewritten 21 October 2026 at the end of a second long session; section 4a added 24 October after a third. It is meant for a fresh conversation that picks up the work. **Read section 4a first: the diag builds are fixed, and the test track needs changing before the factorial runs (section 7).**

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

Number patches `walker-room-NN-<what>.patch`. The last was 34 (launcher for the plated builds, held pendants on them; section 4b). 33: outside braces on the other five diag builds. 32 was the previous handover update and two terrain test switches; 28–31: section 4a; 27: Hoecken-Spears 4-bar's base to 35 cm; 26: Hoecken-Spears slider and Spears lift 53 diag brought to the 15 cm stride; 25: both Hoecken-Spears long-stance builds; 24: four diag builds, and what was found about diag on waves).

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
- Packages (Ubuntu 24.04): see the repo's `Dockerfile` and `debian/`. Also install `xvfb imagemagick lua5.1` (luac, for checking generated Lua), **`openscad`** and `pip install --break-system-packages shapely matplotlib`. Without OpenSCAD the body letters aren't made; they are look-only, but the missing objects change a chaotic run (CS diag, waves 4, seed 1: 1.77 against 2.11 with them), so runs don't repeat earlier ones.
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

## 4a. The third session (22–24 October): the diag builds fixed

**Answer first:** Chebyshev-Spears diag and Hoecken-Spears 4-bar diag, rebuilt with **outside braces** and **held pendants**, now walk as well as their guides cousins (the "ghost guides" ideal) within the noise of 4 seeds. Brace weight barely matters any more.

**Why the old diag builds were slow** (in order of size):
- *Wrong size* (patches 24–27): four diag builds were 9–19% too small. Every build is now stride 14.96–15.01, base 34.94–35.02.
- *Pendant swing*: the long chain of joints let each pendant rock, shaking the feet. `PENDANT_HOLD` holds each pendant at its angle to the body (free to move), as a rigid build's braces would.
- *High weight*: the high braces and the pendants' upward extensions raised the CoM 3 cm above guides' (14.4 against 11.5 cm), shrinking the safe tilt on two feet (the base is then the strip between two foot pads) from 17° to 13.7° (`stabprobe.lua`: CoM over the base of support, every frame).
- *Weight out of proportion*: 17 extra on the body costs guides about 1.2 cm/s even with motors and springs scaled; the same weight spread over every part in proportion costs nothing (tested both ways, ×0.79 on diag and ×1.204 on guides). Bullet is scale-invariant here.
- *Unequal cranks* (patch 31): each pair's recorded advances differed, so the diags' cranks turned 2.2% (CS) and 4.4% (HS4) slower. Measured again in trot (geo.py on a trot sweep), each pair agrees to 0.4%; both now use the mean (18.46, 19.57).

**The outside braces** (William's design; patches 28–30; `DIAG_OUTSIDE`, `OUTSIDE_FIT` in walker-room.lua, `buildOutsideCrossbar` in Chebyshev_Spears_diag_parts.lua): each brace is a *run* along the walk on the outside face of each of its two pendants and a *diagonal* across between the runs' ends, all at one height. Outside the pendants nothing of the walker moves, so the runs can't hit links; the diagonal crosses where nothing reaches at its height. Top brace 0.3 cm over the body's raised letters (look-only in the simulation but real on a machine), bottom brace 0.3 cm under the body (6.0 and 5.9 cm above its feet). Pendants at guides' length on both pairs. Fitted by `outz.py` (whole crank turn, every link, foot at its full 12 cm width, the body, margin 0.3; the diagonal also clear of its own pendants), checked by `verify_outz.py` and in the simulation (no contacts; `letterprobe.lua` for the letters). Total weight 101.6 / 103.3 against 85.4 / 87.0; CoM 11.32 below guides' 11.48; roll, pitch, yaw inertia 1.15×, 1.10×, 1.11× (`combos2.py`). `test-square-outside.lua` shows both next to their guides cousins.

**Results** (`data/outside_braces.txt`; waves 4 with straight troughs, 6 m track, 60 s, Earth standard, trot, forward, equal cranks, springs scaled to weight, 4 seeds):

| Walker | Bracing | Mean | Mirrored ground |
|---|---|---|---|
| CS | diag, outside braces ×1 / ×0.5 / ×0.02 | 7.36 / 7.38 / 7.32 | 7.26 (×1) |
| CS | guides | 7.23 | |
| HS4 | diag, outside braces ×1 / ×0.5 / ×0.02 | 6.96 / 7.01 / 7.13 | 7.50 (×1) |
| HS4 | guides | 7.48 | |

**The test track must change before the factorial runs:**
- *Side walls*: the track is 2 m wide; nearly every run drifted 70–85 cm sideways and rubbed a wall (the probes count walls as ground). Every earlier track result has this, the old factorial results too. Use `ARENA_Z = 600`.
- *Tilted waves*: the second of the waves' three sine terms has troughs 14° off the walk; walkers follow them. `TERRAIN_STRAIGHT` (patch 32, a test) turns the waves so those troughs run straight ahead (guides then go straight), `TERRAIN_MIRROR` mirrors the ground left for right. The diags still veer 0.4–0.8 m on straight-trough waves, and the veer flips with the mirror: it is the terrain (the other two terms), not the brace layout (a 0.9 balance weight that centred the CoM, 0.12 cm off, changed nothing). For a fair ground: all three terms aligned with the walk, or every run on normal and mirrored ground.
- *All advances*: re-measure every build's advance the same way (trot sweep, geo.py); they are 0–4% off.

**For later** (William's list):
- Why the diags follow tilted ground more than guides. Candidates: the braces tying each diagonal pair's feet together; for their weight they turn about 8% more easily (yaw inertia 1.11× against weight 1.20×). Their measured pitch and roll swings equal guides'.
- **The plated builds** (side plates): do the same. William: the plates are outside, so they can never hit anything else on the walker; to be fair, their bottoms go at the same ground clearance as their diag cousins' bottom braces. Measure first, from build dumps: each plated build's CoM against its guides cousin's, plate weight and height, any pendant extensions the plates need.
- Outside braces for the other diag builds (long-stance, lift 44, lift 53).
- Then the factorial runs (section 7), with the plan, timing and William's yes first.

**bpp notes from this session:** the GUI steps a fixed simulated time per drawn frame, so a build that just misses the 60 Hz refresh plays at half speed (the diag costs about 30% more per frame; simulated speeds are unaffected). Setting `o.mass` after `setMassProps` recomputes inertia from the shape (it broke a mass-scaling test; harmless for simple boxes). The terrain is one object, so it is drawn whole whenever any of it is in view.

## 4b. Fourth session (24 October): outside braces on every diag build

**Answer first:** Chebyshev diag, Hoecken 4-bar diag, Hoecken-Spears long-stance diag, Spears lift 44 diag and Spears lift 53 diag now have outside braces too (patch 33; `DIAG_OUTSIDE` covers all seven diag builds). No speed runs yet. Pictures: `outside_braces_top.png`, `outside_braces_side.png` (old braces against new). Data: `data/outside5.txt`, `data/outz5.json`.

**How:** `outz5.py` is `outz.py` generalised (pairs read from the joins; letters per build). Checked first against the recorded CS and HS4 fits: same to 0.01 cm in height, 0.07 in run length. Same rules: top brace 0.3 over the body or its letters at its lowest, bottom brace 0.3 under the body at its highest, runs outside the pendants, the shortest diagonal clear of every link and foot (12 wide) through a whole turn. The five new fits use 0.4 cm against links and feet (fitted on sweeps with the braces built, `sweep6.sh`), because the independent check (`verify5.py`: the braces as built, diagonals cut into slices) found the 0.3-cm fits came out at 0.21–0.27 on some. Bars 1.074 cm tall (`bar` in OUTSIDE_FIT). Chebyshev_diag_parts.lua got `buildOutsideCrossbar` (copied), `opts.extUp` and B in each linkage.

**Pendant extensions:** long-stance's and lift 53's top braces reach 0.73 cm above their pendants' tops, so their pendants go 0.8 cm higher (`extUp` in OUTSIDE_FIT, cm). The others need none.

**Checks** (geometry, whole turn; simulation 20 s on flat and waves 4, trot, Earth standard):

| Build | Closest link or foot (top / bottom brace) | Under body | Over letters (sim) | Contacts in sim |
|---|---|---|---|---|
| Chebyshev diag | 0.45 / 0.48 | 0.28 | 0.30 | none |
| Hoecken 4-bar diag | 0.52 / 0.44 | 0.29 | 0.30 | none |
| H-S long-stance diag | 0.55 / 0.55 | 0.29 | 0.31 | none |
| Spears lift 44 diag | 0.54 / 0.48 | 0.30 | 0.30 | waves: one incident, a foot flipped 86° on its ankle into the bottom run (0.5% of frames), then the bottom diagonal grazed a crest (0.7%) |
| Spears lift 53 diag | 0.49 / 0.45 | 0.30 | 0.30 | none |
| (CS, HS4 diag, patch 28–30, for reference) | 0.31 / 0.34, 0.25 / 0.31 | 0.29, 0.25 | 0.29, 0.29 | |

Pendant–ground and foot–link contacts occur on the guides cousins too (data/outside5.txt), so they are the legs and feet, not the braces.

**Weight and CoM** (dumps at build, CoM above the feet's bottoms, cm):

| Build | Weight outside / old / guides | Braces outside / old | CoM outside / old / guides | Roll, pitch, yaw inertia vs guides |
|---|---|---|---|---|
| Chebyshev diag | 111.4 / 120.7 / 93.9 | 17.6 / 17.4 | 15.68 / 21.42 / 16.13 | 1.13, 1.10, 1.11 |
| Hoecken 4-bar diag | 113.0 / 122.6 / 94.6 | 17.6 / 17.4 | 15.95 / 21.86 / 15.86 | 1.17, 1.13, 1.13 |
| H-S long-stance diag | 94.2 / 100.9 / 76.9 | 16.9 / 17.4 | 10.72 / 13.74 / 10.75 | 1.19, 1.13, 1.13 |
| Spears lift 44 diag | 113.2 / 122.0 / 95.2 | 17.7 / 18.4 | 13.03 / 16.91 / 12.80 | 1.18, 1.09, 1.10 |
| Spears lift 53 diag | 119.1 / 129.2 / 100.2 | 17.9 / 19.0 | 14.96 / 19.52 / 14.57 | 1.18, 1.10, 1.10 |

The old builds were heavier for their long pendants (extended up for the old braces).

**Things to know:**
- **Bottom braces' heights above the ground** (lowest / highest in a turn, body held level, cm; patch 33's message and an earlier draft of this note gave 3.7 and 4.3 for lift 44 and 53, which was wrong): Chebyshev diag 7.97 / 10.84, Hoecken 4-bar diag 7.87 / 10.92, CS diag 5.99 / 10.63, HS4 diag 5.88 / 10.74, long-stance diag 5.53 / 10.70, lift 44 diag 4.23 / 11.93, lift 53 diag 4.77 / 14.07. Every one is under the 8 cm logs. A brace rises and falls with its pair's feet, so the more a walker lifts, the lower its bottom brace sits in stance. **William (24 October): no floor, keep the rule** (both braces over the body, or raised bodies, were the other choices).
- Pendants are not quite the guides cousins' length: Hoecken 4-bar diag +1.0 cm, long-stance +0.6 (plus the 0.8 extension), lift 44 +0.4, lift 53 +0.5 (plus 0.8); CS and HS4 −0.1 and −0.2. These are differences between the build files (where B sits), not the braces.
- HS4 diag's outside bars are 1.12 cm tall (0.75 of its own units), not the 1.074 its fit assumed, so its bottom brace is 0.25 under the body rather than 0.3. Left as it is.
- The handover's CS and HS4 outside weights (101.6, 103.3) were estimates; the dumps say 102.2 and 103.9.
- `letterprobe.lua` compared the letters' box in world axes with the brace in the body's axes; for walkers turned 180° with off-centre bodies (lift 44, 53) that is wrong. `letterprobe2.lua` fixes it; CS and HS4 still measure 0.29.
- Contacts with the look-only letters show up in the contact lists of every outside build (CS too, 4–11% of frames) with points outside the letters. They are how Bullet reports look-only parts; `vibprobe.lua` already leaves them out, and the letters' real clearance is measured by `letterprobe2.lua`.
- Long-stance's pendants turn up to 2.8° in the held-body sweep (the others 0.5° or less); its braces clear by 0.55, so it doesn't matter here.

**Sweeps without ankles:** `sweep5.sh` and `sweep6.sh` set PENDANT_HOLD but no ANKLE_SPRING; the hold finds pendants by their ankle hinges, so it was not on in those sweeps (the fits and checks used the bare chain of joints: pendants turned 1.3° or less, long-stance 2.8°). Every walking check had ankles and the hold. Sweep with ANKLE_SPRING from now on (`sweepP.sh` does).

**Held pendants on the plated builds** (William: yes, as on the diag builds, to stand in for a real build's stiffness; patch 34). `sweepP.sh` + `platecheck.py`: held, the seven 4-bar plated builds keep their foot paths (stride within 0.03 cm). Walking (`plsw.sh`, 20 s, waves 4, seed 1, Earth standard, sides as built, forward), the pendants' turning against the body (vibprobe `pend`) drops from 2.6–10.7 to 0.2–2.6 °/s. **The two sliders jam when held** with their plates on: in a held-body turn the crank gets 289–295° in the window a free one turns 360°, and the feet lift 0.1 (Hoecken-Spears slider, against 4.9) and 0.8 cm (Hoecken slider, against 3.7); walking, Hoecken slider's crank was down to 0.08 turns/s (0.36 free). Not the plate and hold both fixing the in-plane angle (holding only the twist jams too); held without plates, or at SOLVER_ITERATIONS 200, they turn. Open: what to do about it.

**The plated builds don't walk with a free body** (data/plates_hold.txt): at sides, every one is between −1.2 and +0.5 cm/s on waves 4, held or not; they tip onto one side's feet. With the body damped every way (BODY_ANG_DAMP = 1, the old standard) plated CS walks 7.02 cm/s, 7.58 held. Open: keep them (on a damped body?) or set them aside. `test-square-plates.lua` (patch 34) shows all nine, unheld then held; views take `hold =` (walker-room.lua's setView).

**The plated builds** (measured 24 October): each side plate is welded to both pendants on its side, so those two legs must be in phase: no trot; the room builds them at sides (sidePhase 180). The plates add 13.8 on every build (the weight rule counts a plate as a bar its length long, so height adds nothing); CoM 0.0–0.3 cm above guides; pendants at guides' length (0.15 heavier, the weld bolt); plate bottoms now at 7.0–7.2 cm above the feet in stance (BRACE_CLEARANCE).

**New tools** (`tools/`): `sweepP.sh`, `platecheck.py` (plated builds held / not, with ankles), `plsw.sh` (plated builds walking, held / not), `sweep5.sh`, `sweep6.sh`, `sweep_old.sh` (sweeps of the seven diag builds: pendants at guides' length / outside braces built / old braces), `outz5.py` (fit; `--sweeps`, `--links`), `verify5.py` (check as built), `contacts5.sh`, `contacts5b.sh`, `vibprobe_at.lua` (contacts reported at `CONTACT_AT`), `bracehit.lua` (what each brace piece touches), `letterprobe2.lua`, `draw33.py` (the pictures).

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

Same on flat; on waves every diag build is far slower (and turns: headings 270–335° at the end, against about 0° on guides); closer on logs and steps. One seed, so single numbers are noisy, but the waves gap is in all seven. Watching on waves 4, William saw Chebyshev-Spears diag run fine and then get stuck, its guides build not; Hoecken-Spears 4-bar diag looked like its guides build but slipped more. **Why diag is slower is only partly understood: see 'Diag braces: what was found' below and the open issues in section 7.**

**The body now counts, not just the linkage** (21 October). William, watching at the new standard: "Now that the body can pitch, and the gravity has increased, the body can dip on one side, raising the feet on the other side. Some walkers can now clear logs of height 7." Agreed, after some discussion:
- The **free-body result is the main result**. A real build rocks too.
- The **linkage alone** is measured by the foot's lift from the geometry (`tools/footlift.py` → `footlift.json`; the "lift" values). It's cleaner than any locked-body run, because a damped body is neither the real machine nor the linkage alone.
- The **body's share** is the log height cleared minus the lift.
- With the standards held, rocking differences come from the linkage (hip height, foot path, landing, leg mass) except for **gait and bracing**, which are choices. They are table columns, so they stay visible.
- Report **two tables**: everyone at trot (same gait; guides, or the own frame for Jansen, Klann and Spears 4-bar), the controlled comparison; and the best of each linkage, where each gets its own best gait and bracing. They can disagree.

**Diag braces: what was found** (21 October, waves 4, Earth standard, `tools/diagprobe.lua`, `tools/diag_runs.sh`, `data/diag.txt`, `data/com.txt`). Chebyshev-Spears is "CS", Hoecken-Spears 4-bar "HS4"; cm/s, seed 1 unless said:

| Build | Speed | What the probe showed |
|---|---|---|
| CS guides | 7.40 (seed 2: 7.57) | legs' pendants held within 0.4° of the body; links touch ground 3–4% |
| CS diag | 2.11 (seed 2: 1.89) | cranks turn fully, never stall; welds give ≤0.04 cm, ≤1.3°; parts touch each other ≤0.8%; **pendants and braces swing up to 5–12° against the body**; links touch ground 10–20%, the body 3–5% |
| CS diag, braces weightless (DIAG_LIGHT=0.05) | 1.14 | worse, but the welds went soft (0.36 cm) with the light bars, so not a clean test |
| CS diag, low brace (DIAG_ARCH=false) | 2.59 | barely better; links touch ground 4.6% |
| CS diag, SOLVER_ITERATIONS 200 | 4.37 | swing down to ≤1.9°; twice as fast, still far below guides |
| HS4 guides | 7.73 | |
| HS4 diag | 2.75 | |
| HS4 diag, SOLVER_ITERATIONS 200 | 2.39 | swing ≤2.6°; no faster |

- **Centre of mass** (`tools/comprobe.lua`, at build, above the feet's bottoms): the braces add 19–29 mass units (20–30%), all high, raising the centre of mass 2.5–4.9 cm (e.g. CS 11.5 → 14.0 cm, Hoecken 4-bar 15.9 → 20.0). William's reason for once putting one brace below the body.
- **The swing:** each leg is a 4-bar hinged to the body, with a pendant on its coupler. Guides hold the pendant's angle to the body. Diag braces weld pendant to pendant across the body, which holds the pendants only through the hinges' resistance to twisting off their axes; in Bullet that stiffness comes from the solver, so at 40 iterations the leg assemblies swing. A real build's bearings would not. **This is a simulation artefact that handicaps the diag builds.** More iterations mostly remove it, but cost 1.6× the time (200 s a run against 127) and don't close the gap.
- **Ruled out:** weld flex, link collisions, stalled cranks. **Not settled:** the weight and height (the weightless test was spoiled by soft welds), and what is left of the gap at 200 iterations.
- **The low brace** (DIAG_ARCH=false, picture `cs_diag_braces.png`): the bottom brace lifted to 7 cm (BRACE_CLEARANCE), under the body. At that height it crosses the circles the cranks turn in, so the room turns off its contact with the walker's own parts (a real one would jam); it still meets the ground. It flatters the build a little.

**Four diag builds were built too small** (patch 24, 21 October; picture `diag_stride_fix.png`). Chebyshev diag, Chebyshev-Spears diag, Hoecken 4-bar diag and Hoecken-Spears 4-bar diag had their `stride` recorded 10–24% too long, so the room built them 9–19% too small: foot travel 12.1, 13.6, 12.8 and 13.5 cm instead of 15, lift 2.31, 4.22, 2.60, 4.39 against their guides cousins' 2.86, 4.65, 3.05, 4.88. For CS and HS4 diag every link was 0.90 of its guides cousin's (crank, coupler), so it was size, not a different path; Chebyshev and Hoecken 4-bar diag use different files from their cousins, so only their paths were compared. (Lift 44 and lift 53 diag were right.) **Patch 25:** both Hoecken-Spears long-stance builds, guides and diag, were 2% short (14.69 and 14.70 cm; base 35.16 and 34.93); refitted the same way (native stride 8.368 and 8.3745, spacing 19.525 and 19.541; lift 5.08 → 5.18 and 5.17; each kept its body clearance), picture `long_stance_stride_fix.png`. No links touch, body never on the ground, every link >4 cm from the feet. **Patch 26:** Hoecken-Spears slider (14.51 cm, 3.3% short; base 36.18 at the fixed stride) and Spears lift 53 diag (14.90) refitted the same way, picture `slider_l53d_stride_fix.png`. Slider: native stride 8.4291, spacing 19.641, lift 4.73 → 4.90, its own 3 planes kept (closest same-plane links 0.22 cm, was 0.21), plate gap 3.11 → 3.02. Lift 53 diag: native stride 5.8273 against Spears lift 53's 5.8290, lift 9.22 → 9.28, body clearance kept, so a foot's top still clears the lowest link by 1.01 cm (was 1.05); brace gap 2.63 → 2.67 (gaps shifted by the change clearprobe measured, old against new, since clearprobe reads about 0.1 cm high). No links touch, body never on the ground, no jams. **Every build's stride is now 14.96–15.01 cm** (geo.py). **Patch 27:** Hoecken-Spears 4-bar's base 35.28 → 35.00 cm (and stride 14.96 → 15.00); native stride 10.0334 and spacing 23.411 against its diag cousin's 10.0390 and 23.426; body clearance, planes and foot clearances unchanged; picture `hs4_base_fix.png`. **Every build is now at stride 14.96–15.01 cm and base 34.94–35.02 cm.** Fixed by fitting, with the sweep: stride to 15.00 cm, `linkageSpacing` to base 35.00, `bodyShift` to balance within 0.01 cm (frame.x = −bodyShift), frame to the leg mounts ±3 cm, `bodyRaise` to the guides cousin's body clearance, `wide.cube_d` to the 38 cm stance (stancefix.py), `brace.gap` measured, and `advance` scaled by the measured change. CS diag and HS4 diag fitted to their cousins' own stride and spacing (10.4745 against 10.473, 24.441 against 24.436), as they should for the same linkage. Each fixed foot path lies on its cousin's. Checks: links touch ≤0.3%, body never on the ground, no jams (jamcheck2 on four terrains); every link >4 cm from the feet. **So every guides-against-diag number above for those four builds compared unequal walkers and is void** (`gd.txt`, `diag.txt`, `com.txt`); the patterns below are what to re-check.

**Diag on waves, what else was found** (same day, before the size fix, waves 4, Earth standard; tools `stallprobe.lua`, `pathprobe.lua`):
- Not the 2 m track's walls: CS diag stalls 50 cm from the wall; on a 20 m wide track it still stalls. Diag veers right from the first second; guides don't.
- In a stall the cranks turn at full speed, the feet slide (8 cm/s against 4 on guides) and a leg's link drags on the ground (front-right, 14% against 3%).
- Holding each brace piece at its angle to the body (as guides hold the legs; `HOLD_BRACES=true` in stallprobe.lua) roughly doubled speed (CS 2.53 → 4.15, 3 seeds; HS4 2.75 → 5.17; lift 44 diag, which was full size, 2.27 → 5.96 against 6.95 on guides) and cut CS's stuck time from 19 s to 4 s: the twisting is a large part. Held and nearly weightless (DIAG_LIGHT=0.05), CS 6.09 against 6.94 on guides; HS4 5.37 against 7.75, the rest then unexplained; possibly its size, now fixed, but untested.

## 6. Raw data from the last session (`data/`)

| File | What it is |
|---|---|
| `feet_soft.txt`, `feet_flat8.txt`, `feet_point.txt` | Feet comparison (terrains.py), gravity 70 |
| `damp6.txt` | Damping test (damp6.py): damping 1.0 / 0.1 / yaw only |
| `grav.txt` | Gravity 70 against 981 (981 lines here are at the old step and invalid; the valid 981 check is in `conv.txt`) |
| `conv.txt` | Step-size check at 70 and 981, with SINK (foot depth) |
| `gaits_s4.txt` | Spears 4-bar's gaits, old standard |
| `gd.txt` | Guides against diag braces, Earth standard (tools/gd.py) |
| `diag.txt` | The diag diagnosis runs (diag_runs.sh, then 200 iterations and the FRAME lines) |
| `com.txt` | Mass and centre-of-mass height, guides against diag (comprobe.lua) |
| `logs_flat8.txt`, `logs_soft.txt`, `logs_rod.txt`, `logs_tips.txt`, `logs_tips_soft.txt` | Every build as built on logs, AMP 2/4/6, gravity 70, by foot (logs_all3.py); LOGS lines count face hits and kick-backs |

All but `gd.txt`, `diag.txt` and `com.txt` come before the current standard and are for the record, not results. In those three, the rows for Chebyshev, Chebyshev-Spears, Hoecken 4-bar and Hoecken-Spears 4-bar diag are void too (built too small; patch 24).

## 7. Next: the factorial runs

This is the original task's step 2, never yet done on the new geometry. William approved doing it; **he has not yet seen the timing below. Show it to him and get a yes before starting.**

**Section 4a settles open issues 1–3** (the diag builds and the low brace), and adds three test-track changes to make first.

**Open issues to settle with William first** (they change what the factorial measures; 1–3 are superseded by section 4a):

1. **Diag builds and solver iterations.** At SOLVER_ITERATIONS 40 the diag builds' legs swing against the body (section 5), a simulation artefact that slows them. Choices: (a) everyone at 200 iterations: fair and equal, factorial about 1.6× longer (about 43 hours instead of 27); (b) only the diag builds at 200: cheaper but unequal settings; (c) keep 40 and say in the results that diag builds are handicapped by the simulation. Check first whether 200 changes the guides and own-frame builds at all (a few runs); if not, (b) is equal in effect.
2. **What else makes diag slow.** Even at 200 iterations, CS diag 4.37 and HS4 diag 2.39 against about 7.5 on guides. Next tests (about 6 runs, 10 minutes, waves 4): weightless braces at 200 iterations (separates weight and height from the swing); both bracings at 200 on random, logs and steps. Watch a diag build in the GUI for the moment it sticks (William saw CS diag run fine, then stick).
3. **The low brace.** William once put one brace below the body to lower the centre of mass; it was hard for some walkers (it crosses the crank circles). The room's version (DIAG_ARCH=false) passes through the cranks, which a real build can't. Decide whether to make a buildable low brace (under the crank circles), or leave the arched braces.
4. **Cuts still open:** testing direction at trot only, and picking 1 best per linkage instead of 2 (below). Mirror-image walks are already cut.

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
- **Not** guides: they run differently from diag braces (section 5), so both stay. (If diag ends up handicapped by the simulation, guides are the fair stand-in for a braced build: see open issue 1.)
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
| `stallprobe.lua` | `STALL` each second: x, z, heading, tilt, crank turns, feet down (FL/FR/BL/BR), foot slide, other parts on the ground. `HOLD_BRACES=true` also holds each diag brace piece at its angle to the body |
| `pathprobe.lua` | `PATH` each second: x, z, heading |
| `clearprobe.lua` with `clear.sh` | `CLEAR`: body's clearance on flat (mean, lowest), feet, low brace. Reads about 0.1 cm above the lost chassisprobe2, so match builds to each other with it, not to 12 |
| `diagprobe.lua` with `diag_runs.sh` | `TILT`, `CRANK` (turns, stalls), `WELD` (brace weld drift), `SELF` (parts touching, by pair), `GROUND` (non-foot parts on the ground), `FRAME` (parts turning least against the body). Needs `w.joints`, which walker-room.lua keeps since patch 23 |
| `comprobe.lua` | Mass and centre-of-mass height at build (env `COM_OUT`, global `LABEL`) |
| `lowshot.lua` | Screenshot of the test-track walker at frame SHOT_AT, camera CAM = {dx, y, dz, look y} from the body. Run under `xvfb-run -a -s "-screen 0 1600x1000x24" bpp -geometry 1600x1000+0+0 file.lua` with env SHOT_OUT; needs xwd and convert |
| `standprobe.lua` | Body height (mean, lowest), roll, how far joints pull apart |
| `sinkprobe.lua` | `SINK`: how deep feet go into the ground |
| `linkprobe3.lua` with `jamcheck2.py ["extra lua"]` | Links touching, body on ground, on four terrains |
| `bodyhit.lua` | What the body touches |

**Third session** (section 4a; probes chain: `VIB_BASE`, `STAB_BASE`, `LETTER_BASE` point the outer probe at `stallprobe.lua`)

| File | What it does |
|---|---|
| `stallprobe.lua` (updated) | Adds test switches: `PENDANT_GUIDES`, `GUIDES_FOR_BRACES`, `EXTRA_BLOCKS={{m,x,y,z},...}`, `EXTRA_WEIGHT`, `MASS_SCALE`, `PENDANT_MASS`, `GHOST_BRACES` |
| `vibprobe.lua` | Foot shaking (`VIB`), and every contact by the kinds of parts (`CONTACTS`) |
| `stabprobe.lua` | CoM over the base of support every frame: margin, CoM height, tip angle (env `STAB_OUT`) |
| `comzprobe.lua`, `letterprobe.lua`, `boxprobe.lua`, `dumpprobe.lua` | CoM across the walk; top brace over the letters; the body's box; every body and joint (env `DUMP_OUT`) |
| `sweepprobe.lua` (updated) | Also records the body's box |
| `topz.py`, `outz.py`, `verify_outz.py` | Fit and check braces against every link, foot and the body through a whole turn (`outz.json`, copied to `data/`) |
| `stab_calc.py`, `combos2.py` | Weight, CoM height, tip angle, roll, pitch, yaw from dumps |
| `comside.py` | CoM against the stance line, walking in the air |
| `outb_run.sh`, `wt_an.py` | Run one walker with the probes; the weight-test table |

**Geometry**

| File | What it does |
|---|---|
| `geo.py` | From a sweep: stride, lift, base, balance offset, advance (advance within 0–4% of the recorded values) |
| `fit.py`, `fitraise.py` | Fit one build's stride, linkageSpacing, bodyShift (and frame.x, advance); its bodyRaise to a clearance. Patch 24 |
| `draw24.py` | Patch 24's picture |
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
- A clearance check must include everything a part can meet: its own pendants (a diagonal not welded to them), the body's look-only letters, the feet at their full width.
- Check what a test track can do to a result: walls in reach and tilted bumps both steered these walkers.
