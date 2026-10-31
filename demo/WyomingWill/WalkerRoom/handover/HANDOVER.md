# Walker room — handover

William Spears' bpp walker room (`demo/WyomingWill/WalkerRoom` in the bpp repo). Rewritten 21 October 2026 at the end of a second long session; section 4a added 24 October after a third. It is meant for a fresh conversation that picks up the work. **Read sections 4d, 4e, 4g, 4h and 4i first: how the work got here, the standard the runs use now (200 solver iterations, the motor at 0.25 a crank), and the table at it.**

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

Number patches `walker-room-NN-<what>.patch`. The last was 48 (joint warm-starting, the launchers' QUALITY, runs/ for any machine; section 4i). 47: test-ranking.lua, the ranking's builds to watch. 46: the 5-seed ranking, toes for both Hoecken-Spears sliders (section 4h). 45: the uneven logs, Hoecken-Spears slider diag's upturned toes (section 4g). 44: the slider against Chebyshev-Spears on high obstacles (section 4f; test-slider-logs.lua). 43: the sliders' diag builds, the 28 October table (section 4e). 42: the solver switch, joint forces, joint friction (section 4d). 41: the sliders' 6-dof joint, the fresh table (section 4c). 40: 8 m track, the V left off, option A's results. 39: one link width (`LINK_WIDTH`). 38: V-shaped bottom braces (`OUTSIDE_V`). 37: `test-square-check.lua`, M and N keys. 36: 6 m track, mirrored ground, advances in trot (section 4b). 35: low side plates (PLATE_LOW). 34: launcher for the plated builds, held pendants on them. 33: outside braces on the other five diag builds. 32 was the previous handover update and two terrain test switches; 28–31: section 4a; 27: Hoecken-Spears 4-bar's base to 35 cm; 26: Hoecken-Spears slider and Chebyshev-Spears lift 62 diag brought to the 15 cm stride; 25: both Hoecken-Spears 4-bar duty 85 builds; 24: four diag builds, and what was found about diag on waves).

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
  - `trotting-walkers.lua` (the Hoecken diag builds) and `spears-lift-walkers.lua` (Chebyshev-Spears lift 51/62, their diag builds, Hoecken-Spears 4-bar duty 85 diag).
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
- Outside braces for the other diag builds (duty 85, lift 51, lift 62).
- Then the factorial runs (section 7), with the plan, timing and William's yes first.

**bpp notes from this session:** the GUI steps a fixed simulated time per drawn frame, so a build that just misses the 60 Hz refresh plays at half speed (the diag costs about 30% more per frame; simulated speeds are unaffected). Setting `o.mass` after `setMassProps` recomputes inertia from the shape (it broke a mass-scaling test; harmless for simple boxes). The terrain is one object, so it is drawn whole whenever any of it is in view.

## 4b. Fourth session (24 October): outside braces on every diag build

**Answer first:** Chebyshev diag, Hoecken 4-bar diag, Hoecken-Spears 4-bar duty 85 diag, Chebyshev-Spears lift 51 diag and Chebyshev-Spears lift 62 diag now have outside braces too (patch 33; `DIAG_OUTSIDE` covers all seven diag builds). No speed runs yet. Pictures: `outside_braces_top.png`, `outside_braces_side.png` (old braces against new). Data: `data/outside5.txt`, `data/outz5.json`.

**How:** `outz5.py` is `outz.py` generalised (pairs read from the joins; letters per build). Checked first against the recorded CS and HS4 fits: same to 0.01 cm in height, 0.07 in run length. Same rules: top brace 0.3 over the body or its letters at its lowest, bottom brace 0.3 under the body at its highest, runs outside the pendants, the shortest diagonal clear of every link and foot (12 wide) through a whole turn. The five new fits use 0.4 cm against links and feet (fitted on sweeps with the braces built, `sweep6.sh`), because the independent check (`verify5.py`: the braces as built, diagonals cut into slices) found the 0.3-cm fits came out at 0.21–0.27 on some. Bars 1.074 cm tall (`bar` in OUTSIDE_FIT). Chebyshev_diag_parts.lua got `buildOutsideCrossbar` (copied), `opts.extUp` and B in each linkage.

**Pendant extensions:** duty 85's and lift 62's top braces reach 0.73 cm above their pendants' tops, so their pendants go 0.8 cm higher (`extUp` in OUTSIDE_FIT, cm). The others need none.

**Checks** (geometry, whole turn; simulation 20 s on flat and waves 4, trot, Earth standard):

| Build | Closest link or foot (top / bottom brace) | Under body | Over letters (sim) | Contacts in sim |
|---|---|---|---|---|
| Chebyshev diag | 0.45 / 0.48 | 0.28 | 0.30 | none |
| Hoecken 4-bar diag | 0.52 / 0.44 | 0.29 | 0.30 | none |
| H-S duty 85 diag | 0.55 / 0.55 | 0.29 | 0.31 | none |
| Chebyshev-Spears lift 51 diag | 0.54 / 0.48 | 0.30 | 0.30 | waves: one incident, a foot flipped 86° on its ankle into the bottom run (0.5% of frames), then the bottom diagonal grazed a crest (0.7%) |
| Chebyshev-Spears lift 62 diag | 0.49 / 0.45 | 0.30 | 0.30 | none |
| (CS, HS4 diag, patch 28–30, for reference) | 0.31 / 0.34, 0.25 / 0.31 | 0.29, 0.25 | 0.29, 0.29 | |

Pendant–ground and foot–link contacts occur on the guides cousins too (data/outside5.txt), so they are the legs and feet, not the braces.

**Weight and CoM** (dumps at build, CoM above the feet's bottoms, cm):

| Build | Weight outside / old / guides | Braces outside / old | CoM outside / old / guides | Roll, pitch, yaw inertia vs guides |
|---|---|---|---|---|
| Chebyshev diag | 111.4 / 120.7 / 93.9 | 17.6 / 17.4 | 15.68 / 21.42 / 16.13 | 1.13, 1.10, 1.11 |
| Hoecken 4-bar diag | 113.0 / 122.6 / 94.6 | 17.6 / 17.4 | 15.95 / 21.86 / 15.86 | 1.17, 1.13, 1.13 |
| H-S duty 85 diag | 94.2 / 100.9 / 76.9 | 16.9 / 17.4 | 10.72 / 13.74 / 10.75 | 1.19, 1.13, 1.13 |
| Chebyshev-Spears lift 51 diag | 113.2 / 122.0 / 95.2 | 17.7 / 18.4 | 13.03 / 16.91 / 12.80 | 1.18, 1.09, 1.10 |
| Chebyshev-Spears lift 62 diag | 119.1 / 129.2 / 100.2 | 17.9 / 19.0 | 14.96 / 19.52 / 14.57 | 1.18, 1.10, 1.10 |

The old builds were heavier for their long pendants (extended up for the old braces).

**Things to know:**
- **Bottom braces' heights above the ground** (lowest / highest in a turn, body held level, cm; patch 33's message and an earlier draft of this note gave 3.7 and 4.3 for lift 51 and 62, which was wrong): Chebyshev diag 7.97 / 10.84, Hoecken 4-bar diag 7.87 / 10.92, CS diag 5.99 / 10.63, HS4 diag 5.88 / 10.74, duty 85 diag 5.53 / 10.70, lift 51 diag 4.23 / 11.93, lift 62 diag 4.77 / 14.07. Every one is under the 8 cm logs. A brace rises and falls with its pair's feet, so the more a walker lifts, the lower its bottom brace sits in stance. **William (24 October): no floor, keep the rule** (both braces over the body, or raised bodies, were the other choices).
- Pendants are not quite the guides cousins' length: Hoecken 4-bar diag +1.0 cm, duty 85 +0.6 (plus the 0.8 extension), lift 51 +0.4, lift 62 +0.5 (plus 0.8); CS and HS4 −0.1 and −0.2. These are differences between the build files (where B sits), not the braces.
- HS4 diag's outside bars are 1.12 cm tall (0.75 of its own units), not the 1.074 its fit assumed, so its bottom brace is 0.25 under the body rather than 0.3. Left as it is.
- The handover's CS and HS4 outside weights (101.6, 103.3) were estimates; the dumps say 102.2 and 103.9.
- `letterprobe.lua` compared the letters' box in world axes with the brace in the body's axes; for walkers turned 180° with off-centre bodies (lift 51, 62) that is wrong. `letterprobe2.lua` fixes it; CS and HS4 still measure 0.29.
- Contacts with the look-only letters show up in the contact lists of every outside build (CS too, 4–11% of frames) with points outside the letters. They are how Bullet reports look-only parts; `vibprobe.lua` already leaves them out, and the letters' real clearance is measured by `letterprobe2.lua`.
- Long-stance's pendants turn up to 2.8° in the held-body sweep (the others 0.5° or less); its braces clear by 0.55, so it doesn't matter here.

**Sweeps without ankles:** `sweep5.sh` and `sweep6.sh` set PENDANT_HOLD but no ANKLE_SPRING; the hold finds pendants by their ankle hinges, so it was not on in those sweeps (the fits and checks used the bare chain of joints: pendants turned 1.3° or less, duty 85 2.8°). Every walking check had ankles and the hold. Sweep with ANKLE_SPRING from now on (`sweepP.sh` does).

**Held pendants on the plated builds** (William: yes, as on the diag builds, to stand in for a real build's stiffness; patch 34). `sweepP.sh` + `platecheck.py`: held, the seven 4-bar plated builds keep their foot paths (stride within 0.03 cm). Walking (`plsw.sh`, 20 s, waves 4, seed 1, Earth standard, sides as built, forward), the pendants' turning against the body (vibprobe `pend`) drops from 2.6–10.7 to 0.2–2.6 °/s. **The sliders, held** (corrected 24 October; William, watching: no binding). In a held-body sweep (body pinned in the air, crank driven slowly) the held sliders' cranks fall behind (289–295° in a free one's 360°) and the feet barely lift, but that setup is artificial. Walking over whole runs (`sljam`, data/plates_hold.txt; low plates, waves 4, seed 1, 30 s): with the body damped, where they walk, the hold makes no clear difference (Hoecken-Spears slider crank 0.47 held / 0.44 free turns/s, 7.07 / 7.42 cm/s; Hoecken slider labours on waves either way, 0.19 / 0.16); with the body free (tipped over) held cranks run at half to two-thirds speed but keep turning. So: slowing, not binding; the sliders can be held like the others. The same sweep artefact hits held diag builds (section 4b, advances): **don't measure with held pendants in a pinned-body sweep.**

**The plated builds don't walk with a free body** (data/plates_hold.txt): at sides, every one is between −1.2 and +0.5 cm/s on waves 4, held or not; they tip onto one side's feet. With the body damped every way (BODY_ANG_DAMP = 1, the old standard) plated CS walks 7.02 cm/s, 7.58 held. **William (24 October): keep the plated builds (low plates), but leave them out of the runs.** `test-square-plates.lua` (patch 34) shows all nine, unheld then held; views take `hold =` (walker-room.lua's setView).

**Wider track, mirrored ground, new advances** (patch 36). `test-track.lua`: ARENA_Z 600 (was 200). **Fair ground (William's choice 2c): every run on normal and on mirrored ground** (TERRAIN_MIRROR, every terrain; on mirrored ground the start is mirrored too, so a mirrored run meets exactly its normal run's ground left for right; TRACK lines end `|ground mirrored`). Run7.py doesn't do this yet (for the factorial). **Advances re-measured in trot** (`sweepT.sh`, `advtrot.py`; picture `crank_hold.png`): a slow held-body turn falls a little short of 360° in its window (329–359°), so each advance is scaled to exactly one turn; three held diag builds (CS, HS4, duty 85) fell far short, so they were swept with pendants free (the geometry is the same). Guides and diag agree within 0.7% in every pair and share the mean. New / old: Chebyshev 25.46 (25.10, diag 24.79), CS 18.60 (18.46), Hoecken 4-bar 25.67 (25.37, diag 26.86), HS4 19.68 (19.57), duty 85 17.21 (16.06, diag 17.02), lift 51 20.27 (20.30 / 20.27), lift 62 21.15 (21.21 / 20.95), Hoecken slider 24.67 (25.21), Hoecken-Spears slider 18.31 (17.72), **Jansen 27.97 (25.31)**, Klann 29.71 (29.54), **Spears 4-bar 26.58 (29.02)**. Jansen was cranked about 10% fast for 9 cm/s, Spears 4-bar about 9% slow. The plated builds share the guides builds' names, so their advances changed too (they aren't run).

**Check on the new track** (`chk36.sh`, `chk36_an.py`, data/chk36.txt; waves 4, BUMP 15, 60 s, Earth standard with the standard ankle springs, trot, forward, seeds 1–4 on normal and mirrored ground, cm/s):

| Walker | Bracing | Timing | Direction | Normal (seeds 1–4) | Mirrored (seeds 1–4) | Mean normal / mirrored / both | Sideways at end, normal / mirrored (cm) |
|---|---|---|---|---|---|---|---|
| Chebyshev-Spears | guides | trot | forward | 6.54 7.13 6.07 7.30 | 5.05 6.49 5.49 5.74 | 6.76 / 5.69 / 6.23 | −89 +76 −124 +104 / −271 −142 −251 −201 |
| Chebyshev-Spears | diag, outside, held | trot | forward | 7.55 6.74 7.37 6.45 | 6.62 7.06 6.23 7.33 | 7.03 / 6.81 / 6.92 | +100 +138 +66 +165 / −152 −141 −148 −70 |
| Hoecken-Spears 4-bar | guides | trot | forward | 7.64 7.55 7.23 7.52 | 6.35 6.06 5.46 6.23 | 7.48 / 6.03 / 6.75 | +101 +102 +114 +104 / −138 −145 −249 −163 |
| Hoecken-Spears 4-bar | diag, outside, held | trot | forward | 7.21 7.20 7.40 6.81 | 7.68 6.93 6.45 7.17 | 7.16 / 7.06 / 7.11 | +150 +129 +144 +169 / −131 −98 −153 −89 |

- Mirrored ground matters: both guides builds are 1.1–1.5 cm/s slower on it; the diag builds 0.1–0.2. A walker isn't its own mirror image (its trot puts different legs together), so the two grounds are not the same test. Every walker drifts the other way on mirrored ground.
- Over both grounds the diag builds are as fast as their guides cousins or faster (6.92 against 6.23; 7.11 against 6.75), with less spread. Not comparable to section 4a's numbers (straight-trough waves, springs scaled to weight, old advances).
- `test-square-check.lua` (patch 37) shows these four builds on the same track; on the test track, M mirrors the ground and N steps the seed 1–4 (both rebuild the track, as 1–4 do). Checked headless: it reproduces the check runs exactly (CS diag mirrored seed 1 6.62, HS4 guides seed 2 7.55).
- Walls: no walker touched one, but CS guides on mirrored seed 1 ended 276 cm from the middle (its feet reach about 19 cm out; walls at 300). Logs and steps may drift farther: a wider track (ARENA_Z 800) or shorter runs may be needed for the factorial.

**V-shaped bottom braces** (patch 38, `OUTSIDE_V`, default off; `test-square-outside.lua` turns it on; pictures `v_braces_top.png`, `v_braces_side.png`; data/v_braces.txt). William, 25 October: to keep less bar near the ground, the bottom brace's middle piece goes straight across under the body, and its runs rise from there to their pendants (a V seen from the side). Rules (his): the middle piece at the bottom brace's height (it passes under the body), as nearly straight across as fits (every build: straight; lift 62's reaches 0.25 cm along the walk); the runs' ends at the pendants raised by half the room between the brace's bottom at its lowest and the body's bottom (2.1–5.3 cm: more for the walkers that lift more). Fitted by `vfit.py` on sweep6; checked as built by `verifyV.py` on `sweepV.sh` sweeps (each middle piece followed end to end): 0.30 cm or more from every link, foot and the top brace through a whole turn; the middle 0.24–0.30 under the body (as before; HS4's bars are 1.12 tall). Weight +2.4–3.0 (the runs are longer), CoM −0.13 to +0.02 cm (the extra bar is low). On straight-across middles a top-view picture shows bottom and top braces meeting; they are at different heights.

Bottom brace on the ground, flat against V (`vgc.sh`; logs 6, 20 s, seed 1, trot, forward, held): HS4 5.0% → 2.4% of frames, duty 85 8.8 → 4.6, lift 51 13.6 → 9.3, lift 62 5.0 → 6.3; Chebyshev, Hoecken 4-bar and CS none either way. On waves 4 almost none either way. One seed: lift 62's rise may be chance.

| Build | Bracing | Weight V / flat / guides | CoM V / flat / guides | Roll, pitch, yaw vs guides (V) |
|---|---|---|---|---|
| Chebyshev diag | outside, V | 114.4 / 111.4 / 93.9 | 15.55 / 15.68 / 16.13 | 1.18, 1.10, 1.14 |
| Chebyshev-Spears diag | outside, V | 104.9 / 102.2 / 85.4 | 11.28 / 11.31 / 11.48 | 1.20, 1.09, 1.12 |
| Hoecken 4-bar diag | outside, V | 116.0 / 113.0 / 94.6 | 15.82 / 15.95 / 15.86 | 1.22, 1.13, 1.15 |
| Hoecken-Spears 4-bar diag | outside, V | 106.5 / 103.9 / 87.0 | 11.37 / 11.40 / 11.62 | 1.20, 1.09, 1.12 |
| H-S duty 85 diag | outside, V | 96.9 / 94.2 / 76.9 | 10.70 / 10.72 / 10.75 | 1.25, 1.12, 1.15 |
| Chebyshev-Spears lift 51 diag | outside, V | 115.6 / 113.2 / 95.2 | 13.04 / 13.03 / 12.80 | 1.21, 1.09, 1.11 |
| Chebyshev-Spears lift 62 diag | outside, V | 121.4 / 119.1 / 100.2 | 14.98 / 14.96 / 14.57 | 1.21, 1.10, 1.12 |

**One link width** (patch 39, `LINK_WIDTH`, default off; `test-square-width.lua`, `test-square-outside.lua` and `test-square-plates.lua` turn it on at 1.0; picture `link_width.png`; data/link_width.txt). Bar widths came from each file times the room's scale: 0.43–3.18 cm on the guides builds, up to 4.28 on the diag builds (wider than their guides cousins'). William, 25 October: every bar 1.0 cm (about Jansen's and Klann's), "with the option that we can change our minds if this affects behavior adversely". Weight unchanged (bars are weighed by length).
- In the room's `Cube` wrapper: whatever `makeLink` makes gets width LINK_WIDTH (every parts file makes its bars there). Triangles, slider guide blocks, braces, plates and feet keep their shapes.
- Fewest planes (patch 13's rule, `planesW.py`; `planes.py` had a stale 0.5 cm plane gap, fixed to 0.7; at today's widths it reproduces the room's planes exactly): at 1.0 every build keeps its planes, and Chebyshev-Spears diag can drop from 4 to 3, the same layout as its guides cousin (William: yes). Its body widened to keep the 38.0 cm stance; its planes are then exactly its cousin's (11.6–13.0 cm). My first pre-pass (`widthcheck.py`) said Chebyshev-Spears and Hoecken-Spears 4-bar guides would clash at 1.0; that was wrong (it took centre-line distance minus width, ignoring the bars' square ends): the real gap is 0.22 cm.
- Hoecken-Spears slider: its crank comes within 0.12 cm of its guide block at 1.0 (0.24 before). William: accept, but **watch for crank–block contact in the real runs**, under stress. None in the jam checks.
- 1 cm between a foot's top and the lowest link (the Spears lifts' bodies): lift 51 +0.04 cm, lift 62 −0.04, lift 51 diag −0.39, lift 62 diag −0.52 (`footclearW.py`; all now 1.00–1.01).
- Refits at 1.0 (tables used only when LINK_WIDTH is on, so LINK_WIDTH = false gives the builds as before): `WIDTH_FIT` (bodyRaise, cube_d, planes, bodyShift), `OUTSIDE_FIT_W` (every build's bars 1.074; lift 51's and 53's top braces 0.07 higher to clear the letters by 0.31), `OUTSIDE_V_FIT_W`, `PLATE_FIT_W` (targets: the diag cousins' new bottom braces). Checked as built: every brace piece 0.30 cm or more from every link, foot and the top brace; plates on target, on their pendants, 3.3 cm or more from anything.
- Advances: unchanged (the width and the body raises don't change the foot paths' shapes).
- Jam checks (`jamW.py`, 30 s, seed 2, Earth standard, trot, forward, as run): no body on the ground anywhere; parts touching on waves 6, today → 1.0: lift 51 15.0 → 12.1%, lift 51 diag 9.9 → 0.6, CS diag 2.1 → 0, lift 62 diag 2.2 → 4.1, lift 62 1.3 → 1.7 (all feet against links: rocking feet on 6 cm waves), **Spears 4-bar 0 → 3.3% (its links against its body)**: its links are 0.63 cm outside the body across the walk at both widths, so they touch it only when a leg twists, and a 1.0 cm bar's corner reaches further than its 0.54 cm bar did. Own-frame walkers have no hold. Watch it.
- **Balance** (still to do, William agreed after the width): the rule balances along the walk with braces left out; diag builds' braces now put the CoM up to 0.25 cm off along and 0.42 across, and the sliders and lifts read 0.1–0.3 off by the trot-sweep measure. Rebalance, including the braces and across, is the next step.

**Option A: each change against patch 37's walkers** (patch 40; `cmpA.sh`, `cmpA_an.py`, data/option_a.txt; 416 runs: every run build as run, trot, forward, 60 s, Earth standard, 6 m track, waves 4 and logs 5, seeds 1–2 on normal and mirrored ground; base = flat outside braces and each file's own widths). Mean change over builds (cm/s):

| Change | Builds | Waves 4 | Logs 5 | Both | Worse in |
|---|---|---|---|---|---|
| V | 7 diag | −0.31 | −0.15 | −0.23 (se 0.08) | 12 of 14 |
| Width 1.0 | 19 | +0.04 | +0.04 | +0.04 (se 0.08) | 19 of 38 |
| Both | 7 diag | −0.18 | +0.11 | −0.03 (se 0.15) | 8 of 14 |

The 4 runs of a cell spread about 0.5 cm/s (se of one build's change about 0.34). Largest single width changes: Chebyshev-Spears lift 62 diag on waves 4 −1.26 (se 1.05; one run stuck), Hoecken slider +1.04, Hoecken-Spears slider −0.81 / +0.80. Lift 53 diag was also slower at 1.0 on waves 6 (`l53.sh`, seeds 1–4: 2.35 against 3.34, guides 3.56 against 3.35); its body is 0.52 cm lower at 1.0 (the foot rule; I lowered it as part of the width refits without pointing it out, and it's the main suspect). Not yet tested: lift 62 diag at 1.0 with its old body height. Contacts: the slider crank never touched its guide block; Spears 4-bar's legs against its body 0–0.8% of frames at 1.0; bodies on the ground at most 1.4% (base too).

**William (25 October): leave the V off** (`OUTSIDE_V` stays a switch, off; the launchers no longer turn it on).

**Item 4 (diags following tilted ground) is answered:** in option A's base runs guides and diag drift sideways alike (waves 4: mean 140 cm against 144 after 60 s; logs 5: 55 against 53; 28 runs each), both with the ground and the other way on mirrored ground. Section 4a's straight-going guides were on straight-trough waves.

**Track 8 m wide** (patch 40; `test-track.lua` ARENA_Z 800). Lift 53 guides ended 262–264 cm from the middle on 6 m (walls at 300). A different track width changes runs a little, as another start would: the check runs come out 7.20 and 7.30 on 8 m against 7.55 and 6.62 on 6 m (on 6 m they still reproduce exactly). Not the grid (tried anchoring it at the middle line: no change), most likely the engine's indexing of the ground mesh by its size. So 8 m results compare with 6 m ones over many runs, not run for run; `test-square-check.lua` needs ARENA_Z = 600 to repeat the check runs.

**What the hold costs while walking** (`crankw`, picture `crank_hold.png` bottom row; outside braces, trot, forward, seed 1, 20 s): held cranks run up to about 7% below the driven speed on waves 4 (dips at crests), 2% or less on flat; the held builds still go farther on waves (CS 7.61 / 5.75 cm/s held / free, HS4 7.33 / 4.03, duty 85 6.93 / 6.51). A small drag the hold adds in the simulation, far smaller than the swing it removes.

**Low side plates** (patch 35, `PLATE_LOW`, default off; `test-square-plates.lua` turns it on). William: the plates can be much less tall, lowering the CoM. Each plate is now a bar 1.074 cm tall (the outside braces' bars), its bottom at its lowest in a turn at the diag cousin's bottom brace's clearance (William's rule); the sliders (no diag cousin) by the diag braces' rule, top 0.3 under the body's bottom at its highest (the plates are outside the body across the walk, so it is only the rule, not a clash). `opts.plate = { height, drop }` in the five plated parts files; drops in PLATE_FIT, fitted by `platefit.py` from `sweepL.sh` sweeps (with ankles). Weight unchanged (the rule weighs a plate by its length). Checks: every plate on its target to 0.01 cm, 3.9 cm or more inside its pendants' height (it can be bolted on), 3.7 cm or more from every other part; walking 20 s on flat and waves 4 (body damped, held pendants but the sliders), no plate touches anything (`lowc.sh`). Picture: `low_plates_side.png`.

| Build | Bracing | Plate bottom (cm above ground, lowest) | Weight low / tall / guides | CoM low / tall / guides / outside diag | Roll, pitch, yaw vs guides |
|---|---|---|---|---|---|
| Chebyshev | low plates | 7.97 | 107.7 / 107.7 / 93.9 | 15.20 / 16.46 / 16.13 / 15.68 | 1.20, 1.10, 1.13 |
| Chebyshev-Spears | low plates | 5.99 | 99.2 / 99.2 / 85.4 | 10.81 / 11.62 / 11.48 / 11.31 | 1.24, 1.10, 1.15 |
| Hoecken 4-bar | low plates | 7.87 | 108.4 / 108.4 / 94.6 | 14.96 / 16.07 / 15.86 / 15.95 | 1.20, 1.10, 1.13 |
| Hoecken-Spears 4-bar | low plates | 5.88 | 100.8 / 100.8 / 87.0 | 10.93 / 11.78 / 11.62 / 11.40 | 1.24, 1.10, 1.14 |
| H-S duty 85 | low plates | 5.53 | 90.7 / 90.7 / 76.9 | 10.06 / 10.79 / 10.75 / 10.72 | 1.28, 1.11, 1.17 |
| Chebyshev-Spears lift 51 | low plates | 4.23 | 109.0 / 109.0 / 95.2 | 11.96 / 12.90 / 12.80 / 13.03 | 1.23, 1.08, 1.11 |
| Chebyshev-Spears lift 62 | low plates | 4.77 | 114.0 / 114.0 / 100.2 | 13.66 / 14.53 / 14.57 / 14.96 | 1.22, 1.07, 1.09 |
| Hoecken slider | low plates | 7.36 | 102.4 / 102.4 / 88.6 | 13.79 / 14.76 / 14.66 / – | 1.21, 1.10, 1.14 |
| Hoecken-Spears slider | low plates | 5.85 | 92.9 / 92.9 / 79.1 | 11.79 / 12.82 / 12.69 / – | 1.26, 1.11, 1.16 |

**The plated builds** (measured 24 October): each side plate is welded to both pendants on its side, so those two legs must be in phase: no trot; the room builds them at sides (sidePhase 180). The plates add 13.8 on every build (the weight rule counts a plate as a bar its length long, so height adds nothing); CoM 0.0–0.3 cm above guides; pendants at guides' length (0.15 heavier, the weld bolt); plate bottoms now at 7.0–7.2 cm above the feet in stance (BRACE_CLEARANCE).

**New tools** (`tools/`): `widthcheck.py` (the wrong pre-pass, kept for the record), `planesW.py`, `sweep_roles_R0.sh`, `sweep_roles_W1.sh`, `sweep_roles_W2.sh`, `footclearW.py`, `sweepTW.sh`, `sweepTW2.sh`, `sweep4W.sh`, `sweep6W.sh`, `sweepVW.sh`, `sweepLW.sh` (width sweeps), `jamW.py`, `jamW_an.py`, `linkprobe3_at.lua` (jam checks), `drawW.py`; `verify5.py` (env SWEEP6), `verifyV.py` (env SWEEPV), `vfit.py` (env SWEEP6), `verifyV.py`, `sweepV.sh`, `vgc.sh`, `drawV.py` (the V braces), `sweepL.sh`, `platefit.py` (fit / check the low plates), `lowc.sh` (their contacts walking), `draw34.py` (the picture), `sweepP.sh`, `platecheck.py` (plated builds held / not, with ankles), `plsw.sh` (plated builds walking, held / not), `sweep5.sh`, `sweep6.sh`, `sweep_old.sh` (sweeps of the seven diag builds: pendants at guides' length / outside braces built / old braces), `outz5.py` (fit; `--sweeps`, `--links`), `verify5.py` (check as built), `contacts5.sh`, `contacts5b.sh`, `vibprobe_at.lua` (contacts reported at `CONTACT_AT`), `bracehit.lua` (what each brace piece touches), `letterprobe2.lua`, `draw33.py` (the pictures).

## 4c. Fifth session (25–27 October): a fresh table, and the sliders' joint

**Answer first:** every run build on 10 terrains (the first full table since the outside braces, held pendants, 8 m track and 1.0 cm links). The Spears builds average 6.22 cm/s over the nine rough terrains, the others 4.74 (old slider joint). The two sliders were held back by Bullet's slider joint, which let the bar twist up to 10–15° against its pivot block; `SLIDER_6DOF` (patch 41, default on) makes that pivot a generic 6-dof joint, free only along the bar.

**Width rule** (William, 25 October): 1.0 cm links everywhere (`LINK_WIDTH = 1.0` in the runs; the room default is still false). Option A's data: footing lost by the foot-carrying link at 1.0 doesn't go with speed lost (correlation −0.05 over 38 build-terrains); only Chebyshev-Spears lift 62 diag consistently pays (waves, and logs 7 in the table below). Bodies by the foot rule. `WIDTH_REFITS_OFF` (a table of names) and `LINK_WIDTH_KEEP_OVER` (cm) are test switches from that work.

**The fresh table** (`data/fresh_table.md`, `data/fresh.txt`, `data/fresh6d.txt`; `tools/fresh.sh`, `fresh6d.sh`, `fresh_table.py`): trot, forward, Earth standard, 1.0 cm links, no V, diag builds with outside braces and held pendants, guides `UNBRACED`, 8 m track, 60 s, bump 15, normal ground only (William: no mirroring), seeds 1–2. Flat; waves 2/4/6; logs 3/5/7; steps 3/5/7 (William's set; random left out). The sliders here are with `SLIDER_6DOF`. Mean cm/s; the last column is the mean over the nine rough terrains.

| Walker | Bracing | Timing | Direction | Flat | Waves 2 | Waves 4 | Waves 6 | Logs 3 | Logs 5 | Logs 7 | Steps 3 | Steps 5 | Steps 7 | Mean |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Chebyshev-Spears lift 51 | guides | trot | forward | 8.94 | 7.92 | 6.89 | 5.81 | 8.57 | 8.19 | 7.23 | 8.63 | 8.18 | 6.86 | 7.59 |
| Chebyshev-Spears lift 51 diag | outside, held | trot | forward | 8.89 | 7.48 | 6.25 | 5.43 | 8.52 | 8.05 | 6.04 | 8.54 | 7.99 | 6.97 | 7.25 |
| Hoecken-Spears 4-bar diag | outside, held | trot | forward | 8.79 | 8.13 | 6.75 | 4.89 | 8.19 | 7.12 | 3.07 | 8.28 | 7.52 | 5.54 | 6.61 |
| Hoecken-Spears 4-bar duty 85 diag | outside, held | trot | forward | 8.97 | 7.95 | 6.54 | 5.70 | 8.04 | 7.06 | 2.23 | 8.32 | 7.25 | 5.91 | 6.55 |
| Hoecken-Spears 4-bar | guides | trot | forward | 8.89 | 8.27 | 7.56 | 4.33 | 8.14 | 6.83 | 3.04 | 8.30 | 7.53 | 4.32 | 6.48 |
| Chebyshev-Spears lift 62 | guides | trot | forward | 8.93 | 7.12 | 4.88 | 2.57 | 8.16 | 7.50 | 5.25 | 8.35 | 7.72 | 6.51 | 6.45 |
| Chebyshev-Spears diag | outside, held | trot | forward | 8.87 | 8.18 | 7.04 | 5.37 | 8.19 | 7.02 | 2.50 | 8.26 | 7.45 | 3.61 | 6.40 |
| Chebyshev-Spears | guides | trot | forward | 8.95 | 8.31 | 6.71 | 6.26 | 8.21 | 6.23 | 0.21 | 8.41 | 7.22 | 5.04 | 6.29 |
| Klann | own | trot | forward | 9.03 | 7.67 | 7.08 | 4.97 | 7.92 | 6.66 | 3.30 | 8.60 | 6.90 | 2.85 | 6.22 |
| Hoecken-Spears 4-bar duty 85 | guides | trot | forward | 8.94 | 7.98 | 7.38 | 6.79 | 8.16 | 4.69 | 0.73 | 8.39 | 7.59 | 3.79 | 6.17 |
| Chebyshev-Spears lift 62 diag | outside, held | trot | forward | 8.89 | 7.17 | 4.49 | 1.10 | 8.08 | 7.68 | 1.90 | 8.36 | 7.79 | 6.19 | 5.86 |
| Jansen | own | trot | forward | 9.07 | 8.18 | 7.04 | 5.68 | 7.38 | 5.10 | 0.10 | 8.02 | 6.42 | 4.84 | 5.86 |
| Hoecken-Spears slider | guides | trot | forward | 9.01 | 8.00 | 6.67 | 3.75 | 8.27 | 6.43 | 1.15 | 8.39 | 5.39 | 0.59 | 5.41 |
| Hoecken slider | guides | trot | forward | 9.09 | 8.22 | 6.97 | 3.74 | 7.72 | 4.76 | 0.28 | 7.86 | 6.52 | 1.29 | 5.26 |
| Hoecken 4-bar | guides | trot | forward | 8.91 | 8.19 | 6.53 | 2.07 | 7.32 | 4.70 | 0.19 | 7.58 | 2.94 | 0.58 | 4.46 |
| Chebyshev diag | outside, held | trot | forward | 8.96 | 7.95 | 5.74 | 3.67 | 6.72 | 2.56 | 0.23 | 7.13 | 3.91 | 0.52 | 4.27 |
| Chebyshev | guides | trot | forward | 8.90 | 7.63 | 5.62 | 1.07 | 6.70 | 3.97 | 0.27 | 7.15 | 2.06 | 0.57 | 3.89 |
| Spears 4-bar | own | trot | forward | 9.21 | 7.54 | 4.56 | 2.48 | 7.29 | 3.12 | 0.99 | 7.75 | 0.50 | 0.44 | 3.85 |
| Hoecken 4-bar diag | outside, held | trot | forward | 9.01 | 8.08 | 6.37 | 1.97 | 7.19 | 0.99 | 0.17 | 7.59 | 1.56 | 0.55 | 3.83 |

The two seeds of a cell differ by 0.68 cm/s on average, at times 4–5 (high logs and steps most). Contacts under stress (vibprobe): the slider crank never touched its guide block; Spears 4-bar's legs touched its body in 0.6–1.1% of frames (waves 4 and 6); bodies on the ground at most 1.1% (Klann, steps 7). Runs here must be started as a background job the session tracks (Bash `run_in_background`, at most 2 hours; restart to resume): a detached job (`setsid nohup`) is stopped a few minutes after a reply ends, which lost a night's runs.

**Spears against the originals.** Lift and time flat on the ground (within 0.5 cm of the lowest) from the trot sweeps (`tools/stance.py`, sweepT/, body held, one turn), and from the ideal paths in `Walking_Linkages.lua` (`tools/paths4.py`, picture `paths4.png`, each scaled to stride 15):

| Walker | Lift (cm) | Flat on the ground | Duty (Walking_Linkages' measure) | Foot link's swing, fastest (x crank speed) |
|---|---|---|---|---|
| Chebyshev | 2.86 | 73% | 72% | 65°, 1.0 |
| Chebyshev-Spears | 4.65 | 82% | 83% | 99°, 3.0 |
| Hoecken slider | 3.70 | 69% | 69% | 60°, 1.0 |
| Hoecken-Spears slider | 4.89 | 82% | 84% | 100°, 3.3 |
| Hoecken 4-bar | 3.05 | 68% | – | – |
| Hoecken-Spears 4-bar | 4.89 | 76% | – | – |
| Jansen / Klann | 4.94 / 7.84 | 54% / 31% | – | – |
| Spears 4-bar | 5.58 | 58% | – | – |
| H-S duty 85 | 5.18 | 48% | – | – |
| Chebyshev-Spears lift 51 / 62 | 7.71 / 9.28 | 47% / 38% | – | – |

(Names, then: Spears lift 44 and 53, now Chebyshev-Spears lift 51 and 62 -- the hill-climb's foot lift, 44% and 53% by its measure, where Chebyshev-Spears is 26%; Hoecken-Spears long-stance, now Hoecken-Spears 4-bar duty 85, named for its 85% duty, its stance long but not flat to 0.5 cm. Renamed 31 October, section 4l.)

**The sliders' joint** (`tools/slidertest.lua`, `slt.sh`, `slt_an.py`; `data/slider_tests.md`, `data/slt.txt`). William: the Hoecken slider's path is close to Chebyshev's and the two Spears paths are nearly the same, so the slider's Spears gain should be like Chebyshev's; it was +0.5 against +2.4. The Spears slider's feet shook twice as much as Chebyshev-Spears' even on flat (foot jitter, frame to frame, 4.95 against 2.61 cm/s). Tests on flat (seed 1) and waves 4 (seeds 1–2), guides, as the table:

| Walker | Test | Waves 4 (mean of 2) | Foot jitter flat / waves 4 (cm/s) | Bar twist against its block, waves 4, mean / max (°) |
|---|---|---|---|---|
| Hoecken-Spears slider | as run | 4.87 | 4.95 / 6.46 | 0.25 / 9.97 |
| Hoecken-Spears slider | 200 solver iterations | 5.57 | 2.92 / 5.27 | 0.05 / 2.68 |
| Hoecken-Spears slider | 6-dof joint | 7.37 | 2.71 / 4.11 | 0.01 / 0.74 |
| Hoecken-Spears slider | bar at half mass | 5.04 | 5.45 / 6.55 | 0.40 / 14.6 |
| Hoecken-Spears slider | links undamped | 5.19 | 5.00 / 6.11 | 0.23 / 8.85 |
| Hoecken slider | as run | 6.50 | 1.06 / 4.79 | 0.30 / 13.2 |
| Hoecken slider | 200 solver iterations | 7.07 | 0.86 / 3.30 | 0.05 / 2.19 |
| Hoecken slider | 6-dof joint | 6.92 | 0.85 / 2.63 | 0.01 / 0.27 |
| Chebyshev-Spears | as run | 6.71 | 2.61 / 4.32 | – |
| Chebyshev-Spears | 200 solver iterations | 6.96 | 2.60 / 4.29 | – |

Bullet's slider constraint gives under load (a pin through a hole would not); the faster-swinging Spears bar loads it more. With `SLIDER_6DOF` on all 10 terrains (2 seeds; old joint → 6-dof): Hoecken-Spears slider 5.17 → 5.41 (waves 2/4/6 7.25 → 8.00, 4.87 → 6.67, 2.00 → 3.75; logs 7 0.22 → 1.15; but steps 5 7.18 → 5.39 and steps 7 1.74 → 0.59, seeds 6.61 / 4.18 and 0.63 / 0.56), Hoecken slider 4.66 → 5.26. The twist now stays under 1.3°. On steps 7 the Spears slider is still far behind Chebyshev-Spears (0.59 against 5.04): not yet explained. (The 6-dof test inside `slidertest.lua` added the joint after the build, outside the room's addConstraint; built in the file, waves 4 came out 6.67 rather than 7.37.)

**Link damping differs between files** (not yet changed): the sliders damp bar, block and pendant (0.1–0.3), Chebyshev-Spears and the Spears lifts nothing, Chebyshev and Hoecken 4-bar their braces (0.15), Jansen and Klann 0.05. Turning it off didn't change the sliders' speed (above). It should be one rule for all (0 is simplest); William: later.

**New tools**: `fresh.sh`, `fresh6d.sh`, `fresh_an.py`, `fresh_table.py` (the table), `stance.py` (lift and time flat from sweeps), `paths4.py` (ideal paths), `slidertest.lua` (slider joint errors; `SL_6DOF`, `SL_BAR_HALF`, `SL_NODAMP`), `slt.sh`, `slt_an.py`.

## 4d. Sixth session (27–28 October): the solver, the motors, friction, and back to the main question

**Answer first.** The aim (William, 28 October): walkers whose linkages lift the foot higher (and maybe stay longer on the ground) should do better on ground with higher obstacles. The fresh table (section 4c) already says yes for lift: over the 12 run walkers as built, lift goes with speed on logs 7 (correlation 0.82) and steps 7 (0.66), not on waves 6 (0.25). Duty can't be told apart from lift with these walkers: across linkages more lift comes with less time flat on the ground (Klann, Chebyshev-Spears lift 51 and 62), so duty alone even goes against speed (−0.5); within each pair the Spears version raises both and is faster. But the fresh table ran at 40 solver iterations, and this session found that 40 is unfair to exactly the high-lift Spears linkages (below). It was run again at 200 (section 4e).

**How we got here** (the commits, in order):

1. 10–13 October: a fair room (65423bd … 3b0e8ad): the same stride, crank speed, weight, motors, feet and chassis for every walker; gravity raised (fa281a1) because the high-lift walkers had no foot down up to 31% of the time. Important: without it there is no fair comparison.
2. 14 October: solver iterations 10 → 40 (0c2e093). At 10 the engine held the low-lift Chebyshev and Hoecken walkers back, which had made lift look decisive on waves (correlation 0.74–0.84); at 40 it fell to 0.10. Important: the first time an engine setting changed the answer.
3. 15 October: logs and steps (3ed943f). Waves don't need lift (feet ride over them); separate obstacles do: a foot that rises less than the obstacle stops dead. Important: this is the terrain that tests the idea.
4. 16–21 October: the same materials, Earth gravity, the diag builds slow (the solver let their legs swing), the factorial plan. Mostly needed, but long.
5. 22–25 October: fairness details: outside braces, held pendants, track widths, the V brace, link width (option A, 416 runs). Effects about 0.2 cm/s. Less important: the walkers had to be built some way, but none of it moved the answer much.
6. 25–27 October: the fresh table and the sliders' joint (c546965, patch 41). Bullet's slider joint let the bar twist 10–15°, holding the sliders back. Important.
7. 27–28 October (this section, patch 42): William asked why Hoecken-Spears slider gains less from the Spears change than Chebyshev-Spears does. That found that the solver doesn't converge for linkages near their smallest transmission angle, which are the high-lift ones: 40 iterations is unfair to the Spears linkages. Important. The rest checked whether that changes the set-up: the motor limit (0.25 per crank is fine), joint friction (no measurable effect), mono (explains brief backward cranks on Klann and Spears 4-bar, a small effect), the iteration count (200 is close enough to 1000 at half the cost).

**The solver doesn't converge at 40 iterations near the smallest transmission angle.** When a linkage's coupler and rocker come within about 6–9° of in line, Bullet's sequential-impulse solver doesn't settle the joints in 40 iterations: the cranks surge and lag (0.55–1.94 of driven speed) whatever the motor strength, and the error is gone by about 1000. (A dead point, William: crank and coupler in line. The smallest transmission angle comes with more lift in the linkages here; it is close to, not the same as, how near a linkage is to the Grashof limit.) A single 5 cm step, all four feet up (`tools/steptest.lua`, `st.sh`, `st_it.sh`; `data/s6_st.txt`, `s6_it.txt`, `s6_si1k.txt`, `s6_dz.txt`):

| Solver | Chebyshev-Spears | Hoecken-Spears slider |
|---|---|---|
| 40 iterations | 11 of 12 | 4 of 12 |
| 200 iterations | 6 of 12 | 12 of 12 |
| 1000 iterations | 6 of 6 | 6 of 6 (faster) |
| MLCP (Dantzig) | 0 of 6 | 0 of 6 |

So Chebyshev-Spears' lead over the slider at 40 was the solver locking it at its smallest transmission angle. On waves 4 with the joints solved, the slider beats Chebyshev-Spears (1000 iterations 8.38 against 6.03, MLCP 8.02 against 6.99; `data/s6_cmp2.txt`). MLCP needs `v:setCfm(1e-8)` or it falls back every step, takes about 5 minutes a 60 s run, and treats contacts differently from sequential impulse (the step results above); not adopted. NNCG went to NaN under every setting tried.

**The motors reach half their set torque** (wrong, found 30 October: they reach all of it; the measure read half, section 4j). At MOTOR_STRENGTH 10 the cap is 2.5 a crank nominal (weight × stride units) and peaks were about 1.24; at 1 the cap is 0.25 and peaks about 0.13. Cause not known. William chose 0.25 a crank as a realistic limit, so the runs set MOTOR_STRENGTH 2. With it (1000 iterations, joint friction on; `tools/ms1.sh`, `torqueprobe.lua`; `data/s6_motor_cap.txt`, `s6_ms1.txt`), every build still walks 8.8–9.3 cm/s on flat. Reaching the cap: both Hoecken-Spears 4-bar duty 85 builds (the diag one at it most of the time, cranks 0.78–1.64), Klann, Spears 4-bar (peak 0.32, above the cap: a one-frame spike in the measure, not checked), Chebyshev-Spears lift 51 (0.24), and Chebyshev-Spears on steps 5 (stalls briefly, 8.05 cm/s). Chebyshev, Hoecken 4-bar and both sliders peak under 0.13. Torque demand at 95% is 0.017–0.113 per crank (`tools/tq.sh`, `data/s6_tq.txt`).

**Backward cranks and mono** (William's report: mono, the share of the stance in which the foot keeps moving one way; `tools/revprobe.lua`, `rv.sh`, `rv_an.py`, `rv_plot.py`; `data/s6_crank_reversal.txt`; picture `crank_reversal.png`). Every time a crank turned backwards (7 of 7 on Klann, 4 of 4 on Spears 4-bar, on flat), its own foot was on the ground while its path still carried it forward: the foot lands before its forward swing ends, the ground holds it, and with the motor at its cap the foot pushes the crank back. Always at the same crank angle (Klann 307–308°, Spears 4-bar 167–170°). Jansen's feet never land moving forward and its cranks never turned back. Measured in the simulation by the report's rule (lowest 15% of the foot's height), mono comes out as the report has it: Jansen 0.97 (0.986), Klann 0.84 (0.860), Spears 4-bar 0.72 (0.724). Small in practice: 0.5% of frames, 2 of each walker's 4 cranks.

**Joint friction** (`JOINT_FRICTION = { mu, pin }`, a test, off): every pin resists turning with mu × the force on it × the pin radius, read each step from bpp's new joint forces; a crank's pin takes it off its motor. At mu 0.1, pin 0.25 cm it adds 5–20% to the torque. On steps 5 over 5 seeds it makes no steady difference (below).

**Which iteration count** (`tools/st4.sh`, `st4_an.py`, `st5.sh`, `st5_an.py`; `data/s6_solver_settings.txt`, `s6_st4.txt`, `s6_steps5_seeds.txt`, `s6_st5.txt`). On flat every setting from 40 to 1000 walks within 0.1 cm/s; only the crank surging grows as the count drops (Chebyshev-Spears 0.99–1.02 at 1000, 0.95–1.10 at 200, 0.80–1.56 at 40). Single runs on steps swing a lot from any small change (even the step size alone: Chebyshev 6.21 → −0.34 cm/s), so steps need several seeds. Steps 5, 5 seeds, guides, trot, forward, 20 s, motor 0.25 (mean, range; cm/s):

| Walker | Bracing | Timing | Direction | Friction | 1000 | 400 | 200 |
|---|---|---|---|---|---|---|---|
| Chebyshev | guides | trot | forward | off | 4.20 (1.68–6.21) | 4.81 (1.90–6.48) | 3.69 (−0.45–6.64) |
| Chebyshev | guides | trot | forward | on | 4.17 (1.79–6.61) | 4.49 (1.77–6.47) | 4.42 (1.83–5.44) |
| Chebyshev-Spears | guides | trot | forward | off | 7.33 (6.14–8.13) | 6.94 (4.35–8.03) | 7.10 (4.43–8.03) |
| Chebyshev-Spears | guides | trot | forward | on | 6.84 (4.31–8.05) | 7.05 (5.14–8.16) | 7.04 (4.67–8.21) |
| Hoecken slider | guides | trot | forward | off | 6.33 (3.73–7.48) | 6.69 (5.83–7.19) | 6.36 (5.00–7.25) |
| Hoecken slider | guides | trot | forward | on | 5.85 (4.25–7.31) | 6.39 (5.17–7.52) | 6.52 (5.91–7.22) |
| Hoecken-Spears slider | guides | trot | forward | off | 6.78 (3.65–7.80) | 7.19 (5.40–7.93) | 7.70 (7.31–7.99) |
| Hoecken-Spears slider | guides | trot | forward | on | 7.50 (7.18–7.78) | 7.57 (7.11–7.91) | 7.59 (6.91–7.91) |

The settings and friction differ by up to about 1 cm/s, inside the 2–4 cm/s spread between seeds; the ground (seed) matters more than either. Each Spears version beats its original at every setting. Time a 20 s run (minutes): 1000 3.4, 1000 at step 1/1920 2.3, 400 2.3, 200 1.75, 100 1.1, 40 0.8.

**The standard for the runs now** (set per run; the room's defaults are unchanged): `SOLVER_ITERATIONS = 200` with `v:setSolverInfo("residual", 0.01)` (stops early once settled, about 15% faster), `MOTOR_STRENGTH = 2` (0.25 a crank in effect), no joint friction, the rest as section 4c.

**New in bpp (C++)**: `v:setSolver(kind)` ("si", "nncg", "nncg-joints", "mlcp-dantzig", "mlcp-pgs", "mlcp-lemke"), `v.solver`, `v.solverFallbacks`, `v:setSolverInfo(name, value)` ("residual", "sor", "warmstarting", "splitImpulse", "randomOrder", "iterations"); on every constraint `enableForces()`, `forceA()`, `torqueA()`, `forceB()`, `torqueB()` (Bullet's joint feedback; checked on a pendulum: its hinge reads the bar's weight); on `btGeneric6DofConstraint` `setLinearMotor(axis, enable, targetVelocity, maxForce)`.

**Not yet done**: Klann's torque spikes on flat at 1000 iterations (0.76–0.85 of driven speed: probably its early touchdown, above); why the motors reach half their set torque (answered 30 October: they do not, section 4j); one rule for link damping (section 4c; done 31 October, section 4k); new names for duty 85 and lift 51 / 62 (William; lift remeasured 31 October, section 4l).

**New tools**: `angprobe.lua`, `bentsplit.lua`, `crankprobe.lua`, `forceprobe.lua`, `fp_an.py`, `fp_an2.py`, `framedump.lua` and `drawfd.py` (side views), `ghostlinks.lua`, `jointprobe.lua`, `kickprobe.lua`, `legangle.py`, `steptest.lua`, `steplog.lua`, `st.sh`, `st_an.py`, `st_it.sh`, `stit_an.py`, `it200.sh`, `si1k.sh`, `dz.sh`, `cmp2.sh`, `torqueprobe.lua`, `tq.sh`, `ms1.sh`, `ms1_an.py`, `revprobe.lua`, `rv.sh`, `rv_an.py`, `rv_plot.py`, `st4.sh`, `st4_an.py`, `st5.sh`, `st5_an.py`, `ft2.sh`. Data files are the key lines of each run (`s6_*.txt`).

## 4e. The 28 October table, and diag builds for the sliders

**Answer first.** At the new standard (section 4d: 200 solver iterations, motor 0.25 a crank), lift goes with speed over high obstacles, more the higher they are: over the best build of each of the 12 walkers, lift's correlation with speed is 0.67 on waves 6, 0.77 on logs 7, 0.42 on steps 7 (−0.36 and −0.21 on waves 2 and 4: on low waves extra lift costs a little), as in the 40-iteration table. Duty can't be told apart from lift with these walkers (they go against each other, correlation −0.77): fitting speed over the hardest three terrains to both, lift +1.72 ± 0.67 cm/s per standard deviation, time flat on the ground +0.72 ± 0.67, so more duty may help at equal lift, but it is inside the error. The Spears versions of Chebyshev and Hoecken 4-bar gain a lot; the Spears slider still gains little (below).

**The table** (`tools/ft2.sh`, `ft3.sh`, `ft2_an.py`; `data/ft2_table.md`, `data/ft2_keylines.txt`): all 21 builds, the new standard, 20 s runs (speed from 5 to 20 s), seeds 1–3, trot, forward, Earth standard, 1.0 cm links, 8 m track, bump 15, normal ground. Mean cm/s; Mean is over the nine rough terrains. The seeds of a cell differ by 1.3 cm/s on average (up to 7), so differences under about 1 cm/s between two builds aren't reliable. Two runs stopped once for no reason found (over 20 minutes; run again, they took the usual 2): `ft2.sh` now stops a run after 15 minutes and marks it HUNG (none were).

| Walker | Bracing | Timing | Direction | flat | waves2 | waves4 | waves6 | logs3 | logs5 | logs7 | steps3 | steps5 | steps7 | Mean | Runs |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Chebyshev-Spears lift 51 | guides | trot | forward | 8.88 | 8.26 | 7.52 | 6.62 | 8.69 | 8.18 | 6.27 | 8.72 | 8.60 | 7.59 | 7.83 | 30 |
| Chebyshev-Spears lift 51 diag | outside, held | trot | forward | 8.88 | 8.29 | 7.28 | 5.02 | 8.71 | 8.14 | 5.30 | 8.69 | 8.49 | 7.40 | 7.48 | 30 |
| Chebyshev-Spears lift 62 | guides | trot | forward | 8.86 | 7.46 | 5.38 | 5.86 | 8.05 | 7.60 | 6.52 | 8.32 | 7.95 | 6.08 | 7.03 | 30 |
| Hoecken-Spears 4-bar diag | outside, held | trot | forward | 8.96 | 8.32 | 7.09 | 5.75 | 8.37 | 6.92 | 4.86 | 8.44 | 7.89 | 4.59 | 6.91 | 30 |
| Chebyshev-Spears lift 62 diag | outside, held | trot | forward | 8.82 | 8.02 | 5.86 | 5.14 | 8.12 | 7.56 | 4.89 | 8.34 | 7.77 | 6.02 | 6.86 | 30 |
| Chebyshev-Spears diag | outside, held | trot | forward | 9.03 | 8.34 | 6.80 | 5.43 | 8.51 | 6.92 | 3.19 | 8.65 | 7.50 | 6.28 | 6.85 | 30 |
| Hoecken-Spears 4-bar duty 85 diag | outside, held | trot | forward | 9.10 | 8.00 | 7.56 | 5.68 | 8.04 | 6.95 | 3.34 | 8.40 | 7.02 | 6.14 | 6.79 | 30 |
| Hoecken-Spears 4-bar | guides | trot | forward | 8.95 | 8.42 | 7.68 | 4.68 | 8.34 | 6.68 | 2.30 | 8.41 | 7.91 | 2.61 | 6.34 | 30 |
| Jansen | own | trot | forward | 9.13 | 8.08 | 7.63 | 5.73 | 7.51 | 6.51 | 1.00 | 7.77 | 6.82 | 4.92 | 6.22 | 30 |
| Hoecken-Spears slider diag | outside, held | trot | forward | 9.02 | 8.45 | 7.71 | 5.40 | 8.28 | 6.79 | 0.49 | 8.43 | 7.13 | 3.05 | 6.19 | 30 |
| Klann | own | trot | forward | 9.25 | 7.63 | 7.90 | 5.39 | 8.36 | 6.49 | 2.36 | 8.72 | 7.31 | 0.58 | 6.08 | 30 |
| Hoecken-Spears slider | guides | trot | forward | 9.02 | 8.32 | 7.70 | 4.36 | 8.29 | 6.46 | 0.39 | 8.44 | 7.58 | 3.11 | 6.07 | 30 |
| Chebyshev-Spears | guides | trot | forward | 9.01 | 8.48 | 7.84 | 2.14 | 8.48 | 6.63 | 0.66 | 8.59 | 6.68 | 3.02 | 5.83 | 30 |
| Hoecken slider | guides | trot | forward | 9.08 | 8.33 | 6.91 | 4.28 | 7.50 | 5.64 | 0.22 | 8.16 | 6.31 | 2.38 | 5.53 | 30 |
| Hoecken-Spears 4-bar duty 85 | guides | trot | forward | 8.98 | 8.36 | 8.22 | 3.73 | 8.25 | 3.63 | -0.04 | 8.42 | 6.36 | 1.81 | 5.42 | 30 |
| Hoecken slider diag | outside, held | trot | forward | 9.07 | 8.50 | 7.19 | 4.63 | 7.51 | 5.54 | 0.08 | 8.17 | 6.38 | 0.04 | 5.34 | 30 |
| Hoecken 4-bar | guides | trot | forward | 8.92 | 8.34 | 7.04 | 4.02 | 6.89 | 4.77 | -0.25 | 7.95 | 5.00 | 0.83 | 4.95 | 30 |
| Hoecken 4-bar diag | outside, held | trot | forward | 9.01 | 8.38 | 5.99 | 3.78 | 6.87 | 3.10 | -0.33 | 7.93 | 2.20 | 0.70 | 4.29 | 30 |
| Chebyshev | guides | trot | forward | 8.92 | 7.38 | 6.85 | 3.54 | 6.76 | 3.23 | -0.40 | 7.07 | 3.48 | 0.67 | 4.29 | 30 |
| Chebyshev diag | outside, held | trot | forward | 8.95 | 7.59 | 6.51 | 4.08 | 6.68 | 2.53 | -0.28 | 7.00 | 3.77 | 0.65 | 4.28 | 30 |
| Spears 4-bar | own | trot | forward | 9.41 | 7.85 | 6.22 | 3.94 | 7.45 | 2.73 | 1.10 | 7.64 | 0.53 | 0.75 | 4.25 | 30 |

**Without the guides builds** (William), by the mean over the nine rough terrains (and over the hardest three, waves 6, logs 7, steps 7): Chebyshev-Spears lift 51 diag 7.48 (5.91), Hoecken-Spears 4-bar diag 6.91 (5.07), Chebyshev-Spears lift 62 diag 6.86 (5.35), Chebyshev-Spears diag 6.85 (4.97), Hoecken-Spears 4-bar duty 85 diag 6.79 (5.05), Jansen 6.22 (3.88), Hoecken-Spears slider diag 6.19 (2.98), Klann 6.08 (2.78), Hoecken slider diag 5.34 (1.58), Hoecken 4-bar diag 4.29 (1.39), Chebyshev diag 4.28 (1.48), Spears 4-bar 4.25 (1.93). Places 2–5 are within 0.12 cm/s: a tie.

**Spears against the original** (better bracing of each; nine rough / hardest three): Chebyshev 4.29 / 1.27 → Chebyshev-Spears diag 6.85 / 4.97; Hoecken 4-bar 4.95 / 1.53 → Hoecken-Spears 4-bar diag 6.91 / 5.07; Hoecken slider 5.53 / 2.29 → Hoecken-Spears slider diag 6.19 / 2.98. Why the slider gains so little is still open (logs 7: 0.49 against Chebyshev-Spears diag's 3.19).

**Bracing**: diag better for Chebyshev-Spears, Hoecken-Spears 4-bar and duty 85 (0.6–1.4 cm/s); guides better for Chebyshev-Spears lift 51 and 62 and Hoecken 4-bar; about the same for Chebyshev and both sliders (Hoecken-Spears slider 6.19 diag / 6.07 guides, Hoecken slider 5.34 / 5.53).

**Diag builds for the sliders** (patch 43; William: the sliders had none). Bars across the sliders were tried in October and dropped (they shook the walker, 2.4–14.6 cm/s); that was with Bullet's old slider joint and 40 iterations. Now: `opts.outside` in `Hoecken_slider_parts.lua` and `Hoecken_Spears_slider_parts.lua` (one file for both builds, so their linkage can't differ) times the diagonal legs together (phases 0, 180, 180, 0) and builds two outside braces as the other diag builds (`buildOutsideCrossbar`, copied from Chebyshev-Spears diag's file): top, front-right to back-left, just over the body; bottom, front-left to back-right, just under it. Specs `Hoecken slider diag` and `Hoecken-Spears slider diag` in `trotting-walkers.lua`, chassis, balance and advance as their guides builds (the same linkage); `OUTSIDE_FIT` / `OUTSIDE_FIT_W` entries. Picture: `slider_diag_builds.png`.

- Fitting: braces put anywhere first jammed the cranks (they hit links; with them touching nothing the walker walks normally), so the fitting sweeps use `GHOST_BRACES` (a test: the brace pieces touch nothing). `tools/sdfit.py` (outz5.py, 0.4 cm from links); the top braces then raised 0.15 cm to clear the body's letters by 0.3 walking (`letterprobe.lua`: 0.33, 0.35).
- Checks (held-body turn with the braces as built; `verify5.py`): lift 3.70 and 4.89 cm, as the guides builds; braces 0.45–0.70 cm from the nearest link, 0.33 or more from the body. In that turn (no ankles, so nothing holds the pendants) one diagonal pair's pendants swing ±4.4° on Hoecken-Spears slider diag (±1° on Hoecken slider diag; Chebyshev-Spears diag about ±1°).
- Shake check (`tools/shk.sh`, `vibprobe20.lua`; `data/slider_diag_shake.txt`; 20 s, seed 1, flat and waves 4, held pendants): diag and guides alike. Flat 9.07 / 9.07 and 9.03 / 9.01 cm/s; waves 4 7.14 / 7.06 and 7.80 / 7.75; foot jitter within 0.15 cm/s; pendants turning 0.1–0.4 °/s (the hold stops the swing); no parts touching. On waves the diag cranks never ran backwards (0.46–1.03 against the guides Spears slider's −1.42–1.12).

## 4f. Why Hoecken-Spears slider diag does worse than Chebyshev-Spears diag on high obstacles (28 October, open)

William: their foot paths are nearly the same, so they should do about as well. They do, except on logs 7 (3.19 against 0.49 cm/s) and steps 7 (6.28 against 3.05); elsewhere within 1 cm/s, the slider ahead on waves 4. On guides the slider is slightly ahead (6.07 against 5.83 over the nine rough terrains): Chebyshev-Spears gains 1.0 from its diag build, the slider nothing. Tried (3 seeds each, the 28 October standard; tools below, data `data/s4f_*.txt`):

- **Centre of mass** (`cmprobe.lua`, walking on flat): the slider's is 1.1 cm higher over its feet (12.41 against 11.29 cm) and 7 lighter in all (95 against 102: lighter links); along the walk the two sit within 0.1 cm of their feet's middle. Lowering the slider's to Chebyshev-Spears' height (`BODY_LOAD = { dy = -2.66 }`, a test: the body's load moved, its box left in place; `cmt.sh`): logs 7 1.09, steps 7 0.87 (were 0.49, 3.05). Not it.
- **Steadiness** (`wobprobe.lua`, `wob.sh`): Chebyshev-Spears diag rolls about twice as much (spread 3.7–4.1° against 1.9–2.1°, largest 14–17° against 7–8°); the slider pitches 2–3 times faster and moves up and down twice as fast (it jolts). On logs 7 Chebyshev-Spears' highest swings (top 10%) reach 9.8 cm against the slider's 8.2 (5.5–6.5 in two seeds, under the 7 cm log); on steps 7 both 10.9.
- **The slider's bottom brace on the logs** (in 45 of 57 seconds against 19): with braces that pass through everything (`t12probe.lua`, `T12_GHOST`), logs 7 0.25 (slider) and 3.16 (Chebyshev-Spears). Not it.
- **Damping Chebyshev-Spears' roll** (`ROLL_DAMP`, a test: its turning about the walk damped each frame, as YAW_DAMP; `t2b.sh` 0.5, `t2c.sh` 0.9): the roll hardly changes (spread 3.2–4.7°), so it is not a free sway but set by where its feet stand; speeds 3.67 / 5.92 and 3.46 / 4.17 (logs 7 / steps 7). This test can't say whether the rocking helps. (`T12_ROLL`, the body's angular factor, did nothing at all.)
- **Side views** (`framedump.lua`, `drawfd.py`; picture `logs7_slider_cycle.png`, logs 7, seed 1): the log sits under the walkers' back halves from about 3 s. The slider's near back foot swings forward at about 5 cm, meets the log's side every turn and slides back; its body stays level and it walks in place (body x within 1.2 cm from 3 to 15 s). Chebyshev-Spears' back foot meets the log's side too, but its body tips and it works its way over (at about 12 s). Its motors work harder there (95% torque 0.12–0.24 against the slider's 0.08–0.12): its foot pushes on the log's side where the slider's slides off. Neither foot path clears a 7 cm log (lift 4.65 and 4.89 cm).

**To look at it:** `test-slider-logs.lua` (the two diag builds, Hoecken slider diag and both guides builds; logs 7, seed 1).

**Next ideas** (not done): what the foot does on the log's side (its angle, the ankle spring, the friction; how steeply each path comes down at the front of the swing), and why Chebyshev-Spears' diag braces help it and the slider's don't.

## 4g. The logs are uneven; the slider's toes (29 October)

**Answer first.** Hoecken-Spears slider diag's back feet come down early at the front of their swing and travel the last 2–3 cm low, so on logs 7 a flat toe runs into the log's side and is tipped toe-down (56% of hits, against Chebyshev-Spears diag's 12%), and the walker is pushed back. Its feet's ends turned up 1.0 cm at 30° (`spec.footTips`, a builder's tweak for this walker; William: fair, as a builder would) take it from 0.49 to 2.76 cm/s on logs 7 and from 6.19 to 6.57 over the nine rough terrains, with nothing lost on flat or waves 4.

**The logs aren't even** (William, from watching; `tools/meshprob.py`). The ground is a mesh of 2.73 cm cells (BUMP / 5.5) sampled from the smooth ridges, so a log's top, between the mesh's points, is lower: along a log, mean 6.26 cm, lowest 4.95, a third of its length under 6 (logs 7). Where a log runs at an angle to the mesh, its height changes along it, so a walker can find a low place. William: keep them (more natural; a blind walker finding a sweet spot is interesting). `groundAt` (and the tools that use it) gives the smooth height, not the mesh's.

**The bottom braces** (`braceprob.py` on the smooth logs, `meshprob.py` on the mesh; `OUTSIDE_FIT_TEST`, a test, puts a build's braces elsewhere; `bx.sh`): Chebyshev-Spears diag's top brace doesn't fit on the slider (it meets a link); its bottom brace's shape (long runs in line with the feet, a short diagonal) fits at the slider's own height. On the mesh, a level walker's bottom brace is in a log 0.60 of the time (Chebyshev-Spears, 5.99 cm up), 0.66 (slider, 5.76), 0.69 (slider with the zig-zag); when the brace's own feet cross a low place (lowest 10%), 0.34, 0.44 and 0.51. So the zig-zag doesn't help (its diagonal still meets the higher parts); the 0.23 cm of height does a little. Run (3 seeds): slider with the zig-zag logs 7 0.22, steps 7 1.08, waves 6 5.79 (own brace 0.49, 3.05, 5.40). Not it.

**The back feet** (`footprobe.lua`, `fp.sh`; logs 7, 3 seeds): each back-foot hit on a log's rising side (slope over 20°, foot swinging into it). Chebyshev-Spears diag: 16 hits, the foot moving level (−4°) when it hits, toe up +20.8° 0.1 s later, takes half the log's slope or more in 50%, toe down in 12%. Hoecken-Spears slider diag: 52 hits (stuck at the same log), moving up at +44°, −9.8°, 4%, 56%. Both are pushed back after nearly every hit (body −11.8 and −15.7 cm/s over the next 0.3 s). **The foot paths** (`pathdir.py`, picture `foot_path_direction.png`): Chebyshev-Spears' foot comes nearly straight down at the front of its swing; the slider's comes down to about 1 cm two-thirds of the way along and travels the rest low.

**Tweaks tried on the slider** (logs 7, 3 seeds, cm/s; `ank.sh`, `tw.sh`): ankle springs ×2 0.18, ×4 0.22 (less toe-down, 46% and 31%, but the foot stays flat: 4% and 8% take the slope), ×0.5 2.11 (one seed 5.31), ×0.25 0.56; toes up 1.5 cm at 30° 2.63 (takes the slope 40%, toe down 30%). All 10 terrains (`tips.sh`, `tips10.sh`, `tips_an.py`; data `s4g_*.txt`):

| Walker | Bracing | Timing | Direction | Feet | Flat | W2 | W4 | W6 | L3 | L5 | L7 | S3 | S5 | S7 | Nine rough | Hardest three |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Hoecken-Spears slider diag | outside, held | trot | forward | flat | 9.02 | 8.45 | 7.71 | 5.40 | 8.28 | 6.79 | 0.49 | 8.43 | 7.13 | 3.05 | 6.19 | 2.98 |
| Hoecken-Spears slider diag | outside, held | trot | forward | toes 1.5 cm, 30° | 9.02 | 8.24 | 6.69 | 4.95 | 8.31 | 6.50 | 2.63 | 8.42 | 7.20 | 3.70 | 6.29 | 3.76 |
| Hoecken-Spears slider diag | outside, held | trot | forward | **toes 1.0 cm, 30°** | 9.02 | 8.39 | 7.73 | 4.78 | 8.31 | 7.02 | 2.76 | 8.49 | 7.70 | 3.97 | **6.57** | 3.84 |
| Hoecken slider diag | outside, held | trot | forward | flat | 9.07 | 8.50 | 7.19 | 4.63 | 7.51 | 5.54 | 0.08 | 8.17 | 6.38 | 0.04 | 5.34 | 1.58 |
| Hoecken slider diag | outside, held | trot | forward | toes 1.0 cm, 30° | 9.07 | 8.36 | 7.10 | 4.06 | 7.66 | 5.53 | 0.20 | 8.16 | 6.15 | 0.09 | 5.26 | 1.45 |
| Chebyshev-Spears diag | outside, held | trot | forward | flat | 9.03 | 8.34 | 6.80 | 5.43 | 8.51 | 6.92 | 3.19 | 8.65 | 7.50 | 6.28 | 6.85 | 4.97 |

Toes 1.5 cm on Chebyshev-Spears diag (logs 7, steps 7): 0.20 and 4.07 — much worse, so toes are not for every walker. The 1.0 cm toes on the Hoecken slider diag change nothing (its foot rises 3.7 cm, too low for 7 cm logs either way), so only Hoecken-Spears slider diag has them (`footTips` in its spec, `trotting-walkers.lua`; the room's `FOOT_TIPS` still gives every walker tips; `FOOT_TIPS_OFF`, a test, leaves a spec's off). Checked: the spec's toes give exactly the global setting's result (logs 7, seed 1: 4.73 both). The 28 October table's row for it (section 4e) is with flat feet. Slip with the toes is a little higher on waves (waves 4: 2.56 against 2.35). Hoecken-Spears slider guides was not tried with toes.

## 4h. The 5-seed ranking (29 October)

**Answer first.** Over the nine rough terrains with 5 seeds, the Spears builds hold the top seven places: Chebyshev-Spears lift 51 (7.84 ± 0.08 cm/s) and its diag build (7.59) clearly first and second, Chebyshev-Spears lift 62 third (7.04), then four diag builds tied within 0.09 (Chebyshev-Spears, Hoecken-Spears 4-bar, Chebyshev-Spears lift 62, Hoecken-Spears 4-bar duty 85: 6.81–6.90). Then the Hoecken-Spears sliders with their toes (6.43, 6.35), Hoecken-Spears 4-bar guides (6.30), Klann (6.22) and Jansen (6.18), close together. ± is the standard error of the nine-terrain mean from the seed spread in each cell (so two builds about 0.3 apart or less are not told apart).

**Toes for everyone?** (`tall.sh`, `toes_an.py`, data `toes_logs7_steps7.md`: every build with 1.0 cm toes at 30°, logs 7 and steps 7, 3 seeds.) Only the Hoecken-Spears slider gains clearly (guides: logs 7 0.39 → 3.14), as its diag build did; Hoecken-Spears 4-bar guides loses (steps 7 2.61 → 0.75); the rest within the noise. William: both Hoecken-Spears slider builds get the toes (the same linkage, the same gain; `footTips` in both specs), everyone else flat feet. The four that leaned toward toes, at 5 seeds over the nine rough terrains: Chebyshev-Spears lift 62 diag 6.83 → 6.93, Hoecken-Spears 4-bar duty 85 5.23 → 5.28, Jansen 6.18 → 6.39, Chebyshev-Spears diag 6.90 → 6.65 — none clear (Jansen's +0.21 against about ±0.16), so they keep flat feet.

**To watch them:** `test-ranking.lua` (every build of the ranking, best first, then the originals, at the ranking's standard; starts on logs 7, seed 1).

**The steps on the mesh** (`meshsteps.py`): unlike the logs, the steps keep their full 7 cm (a mesh point is always on the top); the mesh makes each edge a ramp about 2.2 cm wide (about 68°; up to 4.9 cm, 49°, where a cell's diagonal runs along the edge), its top rounded for about 3 cm. So steps 7 remains a test of lift; the logs are where the mesh gives luck.

**The table** (`n5.sh`, `n5_an.py`, `data/n5_table.md`, `data/s4h_*.txt`; seeds 1–3 from section 4e's runs, 4–5 new; 20 s, the 28 October standard):

| Rank | Walker | Bracing | Timing | Direction | Feet | waves2 | waves4 | waves6 | logs3 | logs5 | logs7 | steps3 | steps5 | steps7 | Nine rough | ± | Hardest three | Runs |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Chebyshev-Spears lift 51 | guides | trot | forward | flat | 8.20 | 7.43 | 6.44 | 8.63 | 8.25 | 6.94 | 8.69 | 8.50 | 7.47 | 7.84 | 0.08 | 6.95 | 45 |
| 2 | Chebyshev-Spears lift 51 diag | outside, held | trot | forward | flat | 8.13 | 7.16 | 5.48 | 8.63 | 8.26 | 6.30 | 8.63 | 8.41 | 7.34 | 7.59 | 0.12 | 6.37 | 45 |
| 3 | Chebyshev-Spears lift 62 | guides | trot | forward | flat | 7.46 | 5.48 | 5.65 | 8.03 | 7.78 | 6.55 | 8.39 | 7.82 | 6.20 | 7.04 | 0.10 | 6.13 | 45 |
| 4 | Chebyshev-Spears lift 62 diag | outside, held | trot | forward | toes 1.0 cm | 7.96 | 4.46 | 4.99 | 8.08 | 7.80 | 6.08 | 8.43 | 7.77 | 6.84 | 6.93 | 0.15 | 5.97 | 45 |
| 5 | Chebyshev-Spears diag | outside, held | trot | forward | flat | 8.35 | 6.70 | 5.73 | 8.55 | 7.01 | 3.12 | 8.60 | 7.71 | 6.32 | 6.90 | 0.12 | 5.06 | 45 |
| 6 | Hoecken-Spears 4-bar diag | outside, held | trot | forward | flat | 8.30 | 7.23 | 5.28 | 8.41 | 7.15 | 4.89 | 8.44 | 7.75 | 4.31 | 6.86 | 0.12 | 4.83 | 45 |
| 7 | Chebyshev-Spears lift 62 diag | outside, held | trot | forward | flat | 7.81 | 5.75 | 4.93 | 8.09 | 7.81 | 5.08 | 8.37 | 7.17 | 6.42 | 6.83 | 0.14 | 5.48 | 45 |
| 8 | Hoecken-Spears 4-bar duty 85 diag | outside, held | trot | forward | flat | 7.86 | 7.44 | 6.05 | 8.15 | 7.10 | 2.99 | 8.38 | 7.32 | 6.01 | 6.81 | 0.18 | 5.02 | 45 |
| 9 | Chebyshev-Spears diag | outside, held | trot | forward | toes 1.0 cm | 8.30 | 6.44 | 5.21 | 8.41 | 6.76 | 3.75 | 8.56 | 8.03 | 4.38 | 6.65 | 0.14 | 4.45 | 45 |
| 10 | Hoecken-Spears slider diag | outside, held | trot | forward | toes 1.0 cm | 8.34 | 7.66 | 4.71 | 8.27 | 7.05 | 2.12 | 8.50 | 7.81 | 3.44 | 6.43 | 0.20 | 3.42 | 45 |
| 11 | Jansen | own | trot | forward | toes 1.0 cm | 8.29 | 7.02 | 6.06 | 7.50 | 6.39 | 2.45 | 7.96 | 6.56 | 5.25 | 6.39 | 0.12 | 4.58 | 45 |
| 12 | Hoecken-Spears slider | guides | trot | forward | toes 1.0 cm | 8.47 | 7.46 | 4.19 | 8.25 | 6.95 | 2.42 | 8.45 | 7.75 | 3.23 | 6.35 | 0.19 | 3.28 | 45 |
| 13 | Hoecken-Spears 4-bar | guides | trot | forward | flat | 8.36 | 7.65 | 4.17 | 8.38 | 6.89 | 2.17 | 8.42 | 7.86 | 2.77 | 6.30 | 0.21 | 3.04 | 45 |
| 14 | Klann | own | trot | forward | flat | 7.65 | 7.87 | 5.43 | 8.55 | 6.66 | 2.79 | 8.74 | 7.06 | 1.28 | 6.22 | 0.13 | 3.16 | 45 |
| 15 | Jansen | own | trot | forward | flat | 8.23 | 7.58 | 5.82 | 7.37 | 6.09 | 1.20 | 7.82 | 6.84 | 4.69 | 6.18 | 0.10 | 3.90 | 45 |
| 16 | Hoecken-Spears 4-bar duty 85 | guides | trot | forward | toes 1.0 cm | 8.36 | 7.65 | 3.48 | 8.12 | 3.03 | -0.19 | 8.45 | 6.23 | 2.39 | 5.28 | 0.22 | 1.89 | 45 |
| 17 | Hoecken-Spears 4-bar duty 85 | guides | trot | forward | flat | 8.40 | 8.14 | 3.00 | 8.30 | 4.75 | -0.07 | 8.39 | 4.65 | 1.53 | 5.23 | 0.26 | 1.49 | 45 |

Klann's triangles (William: they show it has fewer links than it looks; straight links if they cause trouble): its torque spikes and brief backward cranks go with its feet landing while still moving forward (mono 0.84, section 4d), its linkage's path, not the triangles; left as they are.

## 4i. Speed: joint warm-starting, and a quality setting (30 October)

**Answer first.** Bullet's solver starts every joint from zero force at each physics step (only foot contacts carry their forces over). `v:setSolver("si-warm")` (bpp, `WarmJointSolver` in viewer.cpp) keeps each joint row's final impulse and starts the next step from 0.85 of it (`setSolverInfo("jointWarmstart", f)`). With it, 40 iterations hold the linkages as well as 200 without it, at 2–5 times the speed. The launchers now have `QUALITY = "fast"` (the default, to watch: si-warm, 40 iterations, step 1/1920 s, a 3 m track; about 3.5 times as fast with start-up) or `"accurate"` (as the ranking: Bullet's solver, 200, 1/3840 s, the 8 m track).

**Where the time went** (one walker, logs 7, offscreen): start-up 14 s (the 8 m × 10 m ground: 214,000 triangles; a 2 m track starts in 4 s); then 58 ms a frame at the ranking's standard (0.29 times real time). About two-thirds solver iterations, a third the 64 physics steps a frame. Bullet 3.24 here is built without threads (its task scheduler is a stub), and a walker is one connected group, which Bullet's threaded solver could hardly split; so threads were not pursued.

**Longer steps alone** (`stp.sh`, `stp_an.py`, `data/s4i_step_size.md`; 4 builds, flat / waves 4 / logs 7, seeds 1–2): 1/960 s loses 15–33% of the flat speed for three of the four (the joints give, cranks run backwards) — not usable; 1/1920 s keeps the flat speed and changes the rough-ground runs by about the seed spread (mean −0.38 cm/s).

**Joint warm-starting** (`ws.sh`, `ws_an.py`, `data/s4i_warm_flat.txt`; flat, seed 1): crank speed range (share of driven speed) for Chebyshev-Spears diag: Bullet 200 iterations 0.91–1.17, warm 40 0.93–1.13, Bullet 40 0.70–1.82 (Chebyshev-Spears lift 51 and Jansen alike); flat speeds within 0.2 cm/s. On rough ground (`wsr.sh`, `wsr_an.py`, `data/s4i_warm_rough.md`; 4 builds, waves 4, logs 7, steps 7, seeds 1–3): warm 40 at 1/3840 s 5.43 cm/s over the 12 cells against 5.47 (cells differ by 0.47 on average), warm 40 at 1/1920 s 5.58 (0.63); both within the seed spread. Time, Chebyshev-Spears diag on logs 7 (simulated ÷ wall time): Bullet 200 at 1/3840 0.22×, warm 40 at 1/3840 0.46×, warm 40 at 1/1920 0.85×.

**Runs on any machine:** `runs/run-table.sh` (bash; the settings `plain200`, `warm40`, `warm40fast`; `BPP`, `JOBS`, `SEEDS`, `TERRAINS`, `BUILDS`, `OUT`; resumable), `runs/speedprobe.lua` (one run's RUN line), `runs/table.py` (the tables, and how two settings compare). speedprobe measures as the earlier probes did and gives the same numbers (Hoecken-Spears slider diag, logs 7, seed 1: 4.74 against 4.73). Like them it does not run the room's drawing hook (it moves the look-only body marks); with that hook a run comes out differently, as any small change does — so a run watched in the window will not repeat a table's run move for move.

**The check, and the standard since** (`data/s4i_validation.md`, mostly run on William's machine; the 13 ranked builds, nine rough terrains, 5 seeds, 585 runs a setting, against the ranking's `plain200`): `warm40` mean change +0.08 cm/s, typical change 0.14, rank correlation 0.97, 3 of 13 builds moved more than their ± (about one standard error; noise alone would move about 4); `warm40fast` mean change 0.00, typical 0.13, rank correlation 0.96, none past its ±. A run took 42 s at warm40 and 23 s at warm40fast. Under warm40fast the top four keep their order (Chebyshev-Spears lift 51, lift 51 diag, lift 62, Chebyshev-Spears diag) and Hoecken-Spears 4-bar duty 85 stays last; only builds within about 0.1 of each other in the ranking swap. warm40 put both Hoecken-Spears sliders up 0.34 and 0.45 (past their ±); warm40fast did not, so taken as noise (not tested). **`warm40fast` is the standard for runs from here on** (`runs/run-table.sh` with no setting named). Do not mix settings within one comparison: rerun anything to be set beside the 29 October ranking.

## 4j. The motors' real torque, a buildable ankle stop, Spears 4-bar's welds (30 October)

**The motors reach their full set torque; the measure read half.** Bullet's joint feedback (`torqueB`) gives the torque on the crank about its centre of mass. A crank is driven at one end, so the pivot's push takes back half the motor's torque about the middle. Tests (`tools/motor_flywheel_test.lua`, `tools/crank_torque_test.lua`): a cube spun about its own centre reads its full 1000 at 1/3840, 1/1920 and 1/960 s; a stalled bar driven at one end reads 500 about its middle, 1000 about its pivot. So MOTOR_STRENGTH 2 has always been **0.5 a crank**, not 0.25 (William chose 0.25 believing the motors gave half; open: keep 2, or 1 for a true 0.25). No run's speed changes; every torque column before this reads half. bpp: `hinge:motorTorque()` (lua_bullet_4.cpp), the torque the hinge passes to body B about its own axis at its pivot; `runs/speedprobe.lua` now reports it (the ranked builds' cap reads 0.50).

**Ankle stop** (William: a foot passed through its leg, Hoecken-Spears 4-bar duty 85 on high bumps). With ANKLE_SPRING the ankle hinge had no limit (its files' +-90 degrees, counted from the leg link, sat at a square foot's built angle, so it was taken off). Measured (`tools/ankleprobe.lua`; fast setting, waves 6): one foot turned 152 degrees from square (seed 1), another 92 (seed 2) -- through the leg. Now `ANKLE_STOP` (default 30): the hinge limited to 30-150 degrees against the link, for every build: where the foot's top meets the corner of a 1 cm link with the pin 0.87 cm below the link's end in a clevis (`ankle_stop.png`, `tools/ankle_stop_pic.py`). Built angles: 90 for the Hoecken, Chebyshev and Spears-lift families; Klann 75/105, Jansen 50/109, Spears 4-bar 84/66 (so Jansen's 50 degree feet have 20 degrees toward their rods). With the stop the same runs reach 80 at most (the stop). `ANKLE_STOP = false`: as before. A first try at 10 degrees put the foot's upper half inside the leg (the picture's red foot).

**Spears 4-bar under joint warm-starting** (William: on bumpy terrain 2.2 it twitched and leapt). At warm40 and warm40fast its cranks ran at up to +-88 times their driven speed; at plain200, and at Bullet 40 without warm-starting, it walked normally. Not one joint (switching warm-starting off for single joints or groups fixed it only sometimes, different ones each time), not rows changing meaning (checked against each joint's rows a step earlier: none did), not its linkage passing its dead point (its stopped hinge stayed at 92-173 degrees). What happens: after walking normally (16 s on flat), an oscillation of about 300 Hz builds in the twisting rows of the rocker-to-body hinges, the crank-to-coupler hinges and the leg welds, fed by each step starting from 0.85 of the last step's force, until a leg kicks a crank backward. Solver changes tried, none good for every build: carrying the smaller or the mean of the last two steps, linear rows only, nothing for a row that just changed direction, 0.5 instead of 0.85 (fixes Spears 4-bar, loosens Chebyshev-Spears diag's cranks to 0.69-1.84 like Bullet 40). The cause was its build: each leg's coupler and leg-arm were welded by a slider locked at 0 (William recalled welds misbehaving before). Welded by Bullet's fixed joint instead (`btFixedConstraint`, every direction locked; same shape and weight -- the room counts its bolts as a slider weld's), it walks at warm40fast as at plain200 (flat 9.26 cm/s, cranks -0.83..1.12; random 2.2 seeds 1-2, waves 2 seed 2: 7.5-8.5, cranks within -0.98..1.19). `LEG_WELD_SLIDER = true`: the slider, as before. Nine-terrain check (`data/s4j_spears4bar_weld.md`; seeds 1-3, ankle stop on): plain200 old weld 4.18 ± 0.18, new weld 3.98 ± 0.24 (change −0.20 ± 0.29), new weld at warm40fast 4.03 ± 0.19 (−0.15 ± 0.26 against the old at plain200): the same walk, and the fast setting now fits it. No run blew up. (Spears 4-bar is slow on high obstacles, about 4 cm/s over the nine; not ranked.) Other builds' slider welds (feet without ankles, Hoecken's bar welds, Chebyshev-Spears' drawing-only coupler piece) were left: the 13 ranked builds pass at warm40fast.

**The ankle stop on the 13 ranked builds** (William's machine, `data/s4j_ankle_stop.md`; warm40fast, nine terrains, 5 seeds, without and with the stop): mean change −0.03 cm/s, typical 0.12, rank correlation 0.98; the top four the same builds (lift 62 diag and Chebyshev-Spears diag swap 4th and 5th); Hoecken-Spears 4-bar duty 85, whose foot went through its leg, unchanged (4.90, 4.92). Only Jansen moved past its ±: −0.32 ± 0.22, mostly logs 7 (2.70 to 1.14). Its feet are not badly mounted -- 50 and 109 degrees is where the trot's crank angles left them when built; walking on flat its ankles swing 49-115 degrees (Klann 69-111), well inside the stop -- but on logs 7 without the stop one foot folded to 4 degrees from its rod (through it); with the stop they halt at 30, which is what costs it there (single runs, `tools/ankleprobe.lua`). Left as it is: the loss is what a buildable ankle costs on high logs.

**Motor strength** (William, 30 October): MOTOR_STRENGTH stays 2, now known to be 0.5 a crank -- no ground truth for a different value. `runs/run-table.sh` has `EXTRA` (Lua run before each run's settings, e.g. `EXTRA='LEG_WELD_SLIDER=true'`); `runs/table.py` labels two folders of the same name by their parent too (`out-nostop/warm40fast` against `out-stop/warm40fast`).

## 4k. One rule for link damping (31 October)

Bullet's damping is a drag on each body's own motion (like thick air), not friction in its joints, so damped links cost their walker speed. As run before (read from the bodies, `tools/dampprobe.lua`): no damping on the links of Chebyshev-Spears lift 51 and 62, Chebyshev-Spears, Hoecken-Spears 4-bar and duty 85; 0.05 turning on every Klann and Jansen link; on both Hoecken-Spears sliders 4 links at 0, 8 at 0.10 moving / 0.15 turning, 4 at 0.20 / 0.30; Spears 4-bar 12 at 0.10 / 0.15 (its file: "mostly just aids solver stability"; William: not needed now its welds are fixed, 4j); the diag builds' outside braces 0.15 turning -- welded to the body, so for diag builds alone a damping of the body's pitch and roll. Feet 0.1 moving (the room's, every build); the body its own (YAW_DAMP).

Now `LINK_DAMP` (default 0): every link's and brace's damping set to it, moving and turning, for every walker; feet and body as before. `LINK_DAMP = false`: each file's own. Check (`data/s4k_link_damp.md`; the six builds it changes, warm40fast, flat, logs 7, waves 6, seed 1): no blow-ups; on flat the same (speeds within 0.1 cm/s, cranks the same); rough single runs scatter both ways, as single seeds do. Its effect on the ranking (William's machine, `data/s4k_damp_table.md`; warm40fast, 13 builds, nine terrains, 5 seeds): mean change 0.00 cm/s, typical 0.05, rank correlation 0.99, no build past its ±; the four builds the rule left alone (Chebyshev-Spears lift 51 and 62, Hoecken-Spears 4-bar and duty 85, guides) came out the same to the last digit. **`runs/out-damp` is the table to rank from**: every build now under the same solver, motors, ankles and damping.

## 4l. Lift measured the same way for every build; new body marks; the room's speed (31 October)

**Lift** (`data/s4l_lift.md`; `tools/sweepLift.sh`, `tools/liftpct.py`): each build swept with its body held still through one slow crank turn at trot, as run; lift is each foot's lowest point, highest minus lowest, as a share of its stride (its centre's travel along the walk, 15 cm for every build), the mean over the feet. Chebyshev-Spears lift 62: 62%; Klann 52; Chebyshev-Spears lift 51: 51; Spears 4-bar 37; Hoecken-Spears 4-bar duty 85: 34; Jansen, Hoecken-Spears slider and 4-bar 33; Chebyshev-Spears 31; Hoecken slider 25; Hoecken 4-bar 20; Chebyshev 19 (each diag build within 0.1 of its twin). The hill-climb behind the two lift builds had reported 44% and 53% (their old names, Spears lift 44 and 53) against Chebyshev-Spears' 26%; the README's foot-path calculation (in each linkage's own units) gives Chebyshev-Spears 26.4%, Hoecken-Spears 4-bar 27.7%, duty 85 28.7%: each about 1.18 times smaller than the measure here (31, 33, 34), so 44 and 53 were most likely that older measure.

**Body marks** (William: option A of three drawn, with C's triangle; `body_marks.png`, drawn from bpp's own layout, `tools/layoutprobe.lua`, `tools/body_marks_pic.py`): the letters in the middle (the linkage's family: C, C-S, H, H-S, J, K, S; the code's number moved out; Chebyshev-Spears lift 51 and 62 are C-S, hill-climbed from Chebyshev-Spears -- "S+" until 31 October -- and duty 85 stays H-S, found searching the Hoecken-Spears family, William's choice), and in the corners as the letters read: links top left ("4", "2S" for the sliders, "6" Klann, "8" Jansen -- from each code; duty 85 was "4L" until its rename), lift top right (`LIFT_PCT` in walker-room.lua, the numbers above), a triangle bottom left on diag builds (the line from corner to corner is gone), and G bottom right on a build held by guides -- they are not really there, so not for demos. The gold rim (the Spears family) is thinner, 7% of the body's width instead of 20%, to leave the corners room; the letters are sized to fit between the corner marks. The marks weigh nothing and push nothing (kinematic, no contact response); moving them each frame in the window is what makes a watched run differ in detail from a table run.

**Hidden helpers still in every run** (William asked whether every non-G build is "O", its own frame): no guides, but the ankle springs (every build: a foot held level to the body, as a parallel link would), the pendant holds (diag builds: each pendant's angle to the body, as rigid braces would without the give of a long chain of joints) and yaw damping (every body) are there and not visible.

**Duty 85 (long-stance) left out of the views** (William, 31 October: it adds little -- lift about Hoecken-Spears 4-bar's, 34% against 33%; its difference is duty, 85% against 79%; in `out-damp` its diag build 5th of the non-guide builds, its guides build last of all): `test-ranking.lua` no longer shows either; both stay in the repo and in `run-table.sh`'s list.

**New names** (William, 31 October, to match the marks): Spears lift 44 → **Chebyshev-Spears lift 51**, Spears lift 53 → **Chebyshev-Spears lift 62** (their family and their lift as measured here), Hoecken-Spears long-stance → **Hoecken-Spears 4-bar duty 85** (what sets it apart), each with its diag build; its mark's links "4L" → "4". Changed everywhere outside `data/`: the builds, launchers, run scripts, tools and these notes (earlier sections too, so a number may read oddly beside its old context: "lift 51" was "lift 44"). `data/` keeps the names its runs printed; `runs/table.py` reads the old names as the new (`OLD_NAMES`), so old results still compare with new runs.

**Several walkers at once** (`tools/roomtime.lua`; fast setting, flat room, marks and steering on, here): one walker 0.48× real time (Klann 0.76, Jansen 0.83), Klann + Jansen + Chebyshev-Spears lift 51 diag + Chebyshev-Spears diag 0.15×, all 21 0.03× (start-up 2 s). The cost adds up walker by walker, nothing shared: four walkers are four separate problems, which threads could run side by side (Bullet here is built without them). William's Ryzen 7 3700X is perhaps 2–3× this machine (not measured). `ONLY` can now name several builds (`ONLY = { ["Klann"] = true, ... }`) for a small room. Open (William): a room of four -- Klann, Jansen and two non-G builds chosen with Tab; then threads or recorded playback.

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

**Leg size.** At the 15 cm stride the leg heights are Chebyshev-Spears lift 51 27.4 cm, Klann 31.0, Jansen 31.9. The Spears lift walkers don't win by being bigger.

**Body damping** (patch 19, BODY_ANG_DAMP and YAW_DAMP). The walkers' files damp body rotation at 1.0, which kills pitch and roll and props up the sides gait. With the body free (yaw only), sides walkers tip over and stall, and trotting ones are fine. Gravity 70, soft feet, mean of 26 runs (flat, and the four terrains at AMP 2/4/6, seeds 1–2), cm/s:

| Walker | Bracing | Timing | Damping 1.0 | Damping 0.1 | Yaw only |
|---|---|---|---|---|---|
| Klann | own | sides | 7.01 | 0.39 | 0.39 |
| Jansen | own | sides | 6.44 | 0.25 | 0.24 |
| Chebyshev-Spears | plates | sides | 6.45 | 1.31 | 1.83 |
| Chebyshev-Spears lift 51 | plates | sides | 7.78 | 3.36 | 3.34 |
| Spears 4-bar | own | its own (0/225/180/225) | 4.58 | 0.78 | 1.71 |
| Klann | own | trot | 7.47 | 5.78 | 5.53 |
| Jansen | own | trot | 7.17 | 6.06 | 6.33 |
| Chebyshev-Spears lift 51 diag | diag | trot | 7.68 | 6.84 | 7.59 |

All forward. Raw data: `data/damp6.txt`. Freeing the body costs every walker something, trotting ones least. Spears 4-bar's own timing fails too, which is why its gaits get searched. **So the sides gaits were dropped** (William: "Just not 'side gaits'"). Plated builds force sides, so the plated configurations are gone too.

**Gravity** (patch 20). Gravity 70 let walkers jump and float down slowly. At 981 with step 1/3840: Jansen trot 10.00 cm/s on flat, roll about 1°. Step check (`data/conv.txt`): halving the step changes speeds by 0.21 cm/s on average at 70 (1/960 → 1/1920) and 0.32 at 981 (1/3840 → 1/7680); the largest change was Chebyshev on logs (3.03 → 5.22), likely chance on one start. At 981, obstacles go better, especially for Klann (logs 4 cm: 5.52 → 8.07) and Jansen (5.03 → 7.38), against Chebyshev-Spears lift 51 diag's 8.19 (`data/grav.txt`).

**Spears 4-bar gaits** (`data/gaits_s4.txt`, old standard, now void): with damping 1.0 and welded feet, sides reversed was best at 7.00. Not valid under the free body.

**Guides are not diag braces** (21 October, `data/gd.txt`, `tools/gd.py`). Guides (UNBRACED) are an ideal, weightless joint holding each leg at its angle to the body; diag braces are real bars, weighed like the rest, welded leg to leg across the body. Both trot. Earth standard, forward, own crank speed, seed 1, cm/s, guides / diag:

| Linkage | Flat | Waves 4 | Logs 5 | Steps 4 |
|---|---|---|---|---|
| Chebyshev | 9.04 / 9.11 | 4.73 / 2.11 | 4.02 / 0.59 | 6.76 / 5.78 |
| Chebyshev-Spears | 9.40 / 9.45 | 7.40 / 2.11 | 7.22 / 4.59 | 8.48 / 8.31 |
| Hoecken 4-bar | 9.01 / 8.55 | 6.61 / 2.22 | 1.52 / 2.19 | 6.83 / 5.76 |
| Hoecken-Spears 4-bar | 9.20 / 8.90 | 7.73 / 2.75 | 6.63 / 5.26 | 8.27 / 7.97 |
| Hoecken-Spears 4-bar duty 85 | 9.51 / 8.84 | 8.39 / 5.49 | 2.21 / 2.18 | 8.33 / 7.70 |
| Chebyshev-Spears lift 51 | 8.92 / 8.82 | 6.95 / 2.27 | 7.92 / 8.16 | 8.37 / 8.15 |
| Chebyshev-Spears lift 62 | 8.89 / 8.90 | 5.48 / 0.63 | 7.45 / 7.22 | 7.92 / 7.95 |

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

**Four diag builds were built too small** (patch 24, 21 October; picture `diag_stride_fix.png`). Chebyshev diag, Chebyshev-Spears diag, Hoecken 4-bar diag and Hoecken-Spears 4-bar diag had their `stride` recorded 10–24% too long, so the room built them 9–19% too small: foot travel 12.1, 13.6, 12.8 and 13.5 cm instead of 15, lift 2.31, 4.22, 2.60, 4.39 against their guides cousins' 2.86, 4.65, 3.05, 4.88. For CS and HS4 diag every link was 0.90 of its guides cousin's (crank, coupler), so it was size, not a different path; Chebyshev and Hoecken 4-bar diag use different files from their cousins, so only their paths were compared. (Lift 44 and lift 62 diag were right.) **Patch 25:** both Hoecken-Spears 4-bar duty 85 builds, guides and diag, were 2% short (14.69 and 14.70 cm; base 35.16 and 34.93); refitted the same way (native stride 8.368 and 8.3745, spacing 19.525 and 19.541; lift 5.08 → 5.18 and 5.17; each kept its body clearance), picture `long_stance_stride_fix.png`. No links touch, body never on the ground, every link >4 cm from the feet. **Patch 26:** Hoecken-Spears slider (14.51 cm, 3.3% short; base 36.18 at the fixed stride) and Chebyshev-Spears lift 62 diag (14.90) refitted the same way, picture `slider_l53d_stride_fix.png`. Slider: native stride 8.4291, spacing 19.641, lift 4.73 → 4.90, its own 3 planes kept (closest same-plane links 0.22 cm, was 0.21), plate gap 3.11 → 3.02. Lift 53 diag: native stride 5.8273 against Chebyshev-Spears lift 62's 5.8290, lift 9.22 → 9.28, body clearance kept, so a foot's top still clears the lowest link by 1.01 cm (was 1.05); brace gap 2.63 → 2.67 (gaps shifted by the change clearprobe measured, old against new, since clearprobe reads about 0.1 cm high). No links touch, body never on the ground, no jams. **Every build's stride is now 14.96–15.01 cm** (geo.py). **Patch 27:** Hoecken-Spears 4-bar's base 35.28 → 35.00 cm (and stride 14.96 → 15.00); native stride 10.0334 and spacing 23.411 against its diag cousin's 10.0390 and 23.426; body clearance, planes and foot clearances unchanged; picture `hs4_base_fix.png`. **Every build is now at stride 14.96–15.01 cm and base 34.94–35.02 cm.** Fixed by fitting, with the sweep: stride to 15.00 cm, `linkageSpacing` to base 35.00, `bodyShift` to balance within 0.01 cm (frame.x = −bodyShift), frame to the leg mounts ±3 cm, `bodyRaise` to the guides cousin's body clearance, `wide.cube_d` to the 38 cm stance (stancefix.py), `brace.gap` measured, and `advance` scaled by the measured change. CS diag and HS4 diag fitted to their cousins' own stride and spacing (10.4745 against 10.473, 24.441 against 24.436), as they should for the same linkage. Each fixed foot path lies on its cousin's. Checks: links touch ≤0.3%, body never on the ground, no jams (jamcheck2 on four terrains); every link >4 cm from the feet. **So every guides-against-diag number above for those four builds compared unequal walkers and is void** (`gd.txt`, `diag.txt`, `com.txt`); the patterns below are what to re-check.

**Diag on waves, what else was found** (same day, before the size fix, waves 4, Earth standard; tools `stallprobe.lua`, `pathprobe.lua`):
- Not the 2 m track's walls: CS diag stalls 50 cm from the wall; on a 20 m wide track it still stalls. Diag veers right from the first second; guides don't.
- In a stall the cranks turn at full speed, the feet slide (8 cm/s against 4 on guides) and a leg's link drags on the ground (front-right, 14% against 3%).
- Holding each brace piece at its angle to the body (as guides hold the legs; `HOLD_BRACES=true` in stallprobe.lua) roughly doubled speed (CS 2.53 → 4.15, 3 seeds; HS4 2.75 → 5.17; lift 51 diag, which was full size, 2.27 → 5.96 against 6.95 on guides) and cut CS's stuck time from 19 s to 4 s: the twisting is a large part. Held and nearly weightless (DIAG_LIGHT=0.05), CS 6.09 against 6.94 on guides; HS4 5.37 against 7.75, the rest then unexplained; possibly its size, now fixed, but untested.

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
- The other nine linkages (Chebyshev, Chebyshev-Spears, Hoecken 4-bar, Hoecken slider, Hoecken-Spears slider, Hoecken-Spears 4-bar, Hoecken-Spears 4-bar duty 85, Chebyshev-Spears lift 51, Chebyshev-Spears lift 62): trot on diag braces (not the sliders) and trot on guides.
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
2. **Fewest planes** per walker (`spec.planes`), from sweeping every link through a full crank turn: Jansen 3 (was 7), Klann 3 (was 5), Spears 4-bar 2, most 4-bars 3, Chebyshev-Spears diag and Hoecken-Spears 4-bar duty 85 (and its diag) 4. Both sliders keep their own 2-plane layout: **don't change the sliders' planes**; they jam.
3. **Feet centred under the leg.**
4. **Stance exactly 38.0 cm** between outer foot edges, measured from the static geometry at build, in the body frame. (FOOT_POINT keeps it by widening the body.)
5. **Body height** 12 cm, or higher to leave 1 cm between a foot's top and the lowest link: Chebyshev-Spears lift 51 12.46, 44 diag 13.13, 53 14.33, 53 diag 15.2.
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
- Bullet's solver gives at a linkage's smallest transmission angle: when a crank surges or a walker is held back, check the result at 200–1000 iterations before explaining it.
- One run on logs or steps is close to a coin toss: compare means over several seeds.
- bpp's Lua is 5.1: `math.atan(y, x)` ignores x; use `math.atan2`. Quaternions have no `*`.
- Never `pkill -f` or `pgrep -f` with a pattern that matches your own command line; kill by PID.
