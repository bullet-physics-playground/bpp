# Threads in bpp (1-4 November 2026)

## Done (patches 70-75)

**Answer first.** bpp can now solve the walkers in a room side by side on
several threads, all in one world, so they still touch each other. It needs
bpp built with its own Bullet, built with threads, as an option; the default
build and the packages keep the system Bullet and are unchanged. Any number of
threads gives exactly the same room, move for move. One walker (the test track,
the tables) walks exactly as without threads, to the last digit (patch 75). In
a room of several the one difference is that each walker's solve stops when it
has settled, not when its group of two or three has (Bullet's one-thread world
solves them in groups). The body marks had cost more than threads could win:
they are look-only, but Bullet worked out their contacts every step, more than
half the room's time; patch 73 took them out. On William's machine (8 cores)
the room of four went from 0.14x real time to 0.57x with patch 73, and 0.77x
with 8 threads.

**How to use it.**

```
cd ~/bpp && scripts/bullet-threads.sh        # Bullet 3.24 with threads, into lib/ (git ignores it)
mkdir -p ~/build-mt && cd ~/build-mt
qmake CONFIG+=bundled_bullet ~/bpp/bpp.pro && make -j16
```

Then `v:setThreads(n)` after `v:setSolver(...)` (`room-four.lua`: set
`THREADS = 8` before opening it, or in a launcher). `setThreads(0)` is the
world as before. With the system Bullet, `setThreads` says it has no threads
and does nothing.

**How it works** (`src/viewer.cpp`: `BppWorld`, `Viewer::setThreads`).

- bpp's worlds are now `BppWorld`, Bullet's soft body world with one change:
  with threads on it solves its islands (groups of bodies joined by joints or
  touching: one walker, or two that touch) as Bullet's
  `btDiscreteDynamicsWorldMt` does, with its threaded island manager and its
  pool of solvers (`btConstraintSolverPoolMt`), on Bullet's own thread pool.
  Soft bodies stay. Collisions, integration, soft bodies and Lua stay on one
  thread.
- Bullet's threaded island manager joins islands of under 32 bodies into
  batches, and merges small islands until a batch costs 1024; both are off, so
  each walker is its own job (4 walkers: 4 islands a step, measured).
- **si-warm's cache with the pool.** The pool gives an island to whichever
  solver is free, so a walker can land on a different solver each step. So the
  pool's solvers share one cache, kept by the world: before the islands are
  solved, on one thread, every joint gets an entry; while they are solved each
  joint's entry is read and written only by the thread solving its island
  (a joint is in one island), and no entry is added or removed; afterwards,
  on one thread, entries not solved in the step are dropped.
- **The same order as without threads** (patch 75). Bullet's one-thread world
  sorts the joints and the contacts by island before solving them; its
  threaded island manager does not, and keeps the order the world stores them
  in. With 40 iterations the order changes the answer a little, and a run
  differed move for move. Now the world hands the threaded manager the joints
  sorted by Bullet's own sort, and the manager sorts the contacts as Bullet's
  one-thread world does before handing them to the islands, so each island
  gets them in exactly the same order.
- Not used: Bullet's solver that splits one island over several threads
  (`btSequentialImpulseConstraintSolverMt`). It would change results and
  bypass si-warm, and an island is one walker.

**Same results.**

| Check | Bracing | Timing | Direction | Result |
| --- | --- | --- | --- | --- |
| One walker on the track, threads off against threads 1 and 2 (Klann logs 5 and steps 7, Hoecken-Spears slider steps 7, Chebyshev-Spears lift 51 steps 7, Chebyshev-Spears diag logs 7, Jansen logs 7; seed 1) | as built | trot | forward | identical (patch 75) |
| Room of 4, 20 s: 1 thread against 2 and 4 | mixed | trot | forward | identical |
| Room of 21, 5 s: 1 thread against 2 | mixed | trot | forward | identical |
| room-four.lua, 9 s with F, Tab, Shift+Tab, Tab, key 3 (logs), Tab: 1 thread against 2 | mixed | trot | forward | identical |
| Room of 4, 20 s: threads off, but solving one walker at a time (a probe build), against threads 1 | mixed | trot | forward | identical |
| Room of 4, 20 s: threads off (as before) against threads 1 | mixed | trot | forward | different, as expected (groups of walkers) |
| Threads off: the bundled Bullet (3.24) against the system Bullet (3.24 here: 3 builds on the track, room of 4; 3.06 on William's machine, which pkg-config calls 3.05: Chebyshev-Spears diag logs 7, -0.327 cm/s both, 24 s both, and the seven builds patch 73 could not change, identical in all 315 runs of the two tables below) | as built | trot | forward | identical |
| The system build asked for 4 threads, against before | mixed | trot | forward | identical (it runs on one) |

The fifth and sixth rows: the only difference left in a room is the grouping.
Bullet's one-thread world solves two or three walkers' joints together (its
minimum batch, 128 joints and contacts), and with `residual` 0.01 the group
stops iterating when the whole group has settled; with threads each walker is
its own job and stops when it has settled. So the room with threads walks
differently from the room without, move for move; a table cannot measure this
(one walker a run).

**The tables on William's machine** (warm40fast, 13 builds, nine rough
grounds, 5 seeds, 585 runs each, 4 November):

- Patch 73 (the marks out of collision detection), threads off, against
  `runs/out-damp`: mean change -0.01 cm/s, typical change 0.03, rank
  correlation 0.98, no build past its ±. Seven builds the same to the last
  digit in every cell; the two sliders (look-only foot tips) and the
  Chebyshev-Spears lift builds moved, within their ± (largest: lift 62 diag
  -0.16 ± 0.23). `runs/out-marks`.
- The threaded world before patch 75 (`EXTRA='v:setThreads(1)'`), against
  patch 73's table: mean change +0.08, typical 0.14, rank correlation about
  0.97, top four and last the same, but four builds past their ± (Klann +0.44
  ± 0.30, Hoecken-Spears slider +0.30 ± 0.26, Hoecken-Spears 4-bar duty 85 diag
  +0.20 ± 0.19, Chebyshev-Spears lift 51 -0.16 ± 0.12). That led to patch 75.
  After it, threaded runs are the same runs as `runs/out-marks`, so there is no
  table to rerun.

**Found and fixed on the way.**

- Patch 70: si-warm's cache threw away nearly all entries in rooms of more
  than about ten walkers (HANDOVER.md 4q).
- Patch 72: a joint taken out of the world (Tab swapping a walker) kept its
  cache entry until the end of the next step, so a new joint made at the same
  address could start from the old joint's forces. Now its entry goes when it
  is removed. This changes the one-thread room after a Tab too; nothing without
  swaps (checked: room of 4, track runs).
- Patch 75: the threaded world solved joints and contacts in another order
  than Bullet's one-thread world (above).
- `tools/roomtime.lua` timed with `os.clock()`, the processor time of all
  bpp's threads together: right with one thread, wrong with several. Now wall
  time (`v:getTime()`), as `tools/roomdump.lua`.

**Speed** (this 2-CPU container, not William's machine; wall time, fast
setting, the room's default ground; 5 simulated s; threads 0 is the world as
before):

| Walkers | Bracing | Timing | Direction | Marks | Threads 0 | Threads 1 | Threads 2 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 4 (Klann, Jansen, Chebyshev-Spears lift 51 diag, Chebyshev-Spears diag) | mixed | trot | forward | on | 0.31x | 0.30x | 0.33x |
| the same 4 | mixed | trot | forward | off | 0.68x | 0.68x | 0.88x |
| all 21 | mixed | trot | forward | on | 0.05x | 0.06x | 0.06x |
| all 21 | mixed | trot | forward | off | 0.12x | 0.12x | 0.15x |

Where the time goes (room of 4, threads 1, a probe build): with the marks on,
collisions 70-80% of each physics step and the solve about 25%; with them off,
collisions 0.54 s and the solve 0.85 s per simulated second. On 2 threads the
solve took 0.54 s instead of 0.85. So the solve is the part threads help; with
the marks on, the marks' collisions swamp it.

**The marks** (patch 73). They are kinematic with no contact response, so
they push nothing, but Bullet still paired them with everything near them and
worked out the contacts (GImpact meshes, the slowest kind). Now walker-room.lua
uses bpp's `o.collides = false` for them and for the look-only foot tips, which
keeps them out of collision detection entirely; they are still drawn and still
ride on their walkers (checked: each mark kept its distance to its body to
0.001 cm while the walkers walked 40-100 cm). Mouse hover is unaffected (bpp's
hover ray ignores collision groups). Room of 4 here, marks on: 0.31x before,
0.72x after; 0.96x with 2 threads -- the same as with `MARKS = false`. On the
test track the marks are not moved during a run, so they seldom met anything:
of three runs (Chebyshev-Spears diag logs 7, Klann waves 4, Hoecken-Spears
slider logs 7) two came out the same to the last digit and one moved slightly
(1.890 to 1.903 cm/s). A table checks it (below).

**William's machine** (Ryzen 7 3700X, `runs/room-speed.sh`, the room of four
in room-four.lua):

| Walkers | Bracing | Timing | Direction | Marks | Threads 0 | Threads 8 |
| --- | --- | --- | --- | --- | --- | --- |
| 4 (Klann, Jansen, Chebyshev-Spears lift 51 diag, lift 62 diag) | mixed | trot | forward | on, before patch 73 | 0.14x | 0.18x |
| the same 4 | mixed | trot | forward | off, before patch 73 | 0.36x | 0.57x |
| the same 4 | mixed | trot | forward | on, patch 73 | 0.57x | 0.77x |
| the same 4 | mixed | trot | forward | off, patch 73 | 0.58x | 0.79x |

(Single 5 s runs. The first two rows may have run while another job was using
most of the machine; the last two with it idle.) Eight threads gain about 1.35
times here: four walkers are four islands, so at most four threads have work,
and only the solve is threaded: roughly a third of the room's time now, from these figures. Per run,
this container is a little faster than William's machine (the same track run:
18 s here, 24 s there), not slower (the guess below, "2-3 times as fast", was
wrong).

**Limits.**

- Only the solve is threaded. Collisions could be threaded too (Bullet's
  `btCollisionDispatcherMt`), but new contact manifolds would then be made in
  an order that depends on the threads, so runs might no longer repeat (not
  tried).
- One global counter in Bullet's solver (`gNumSplitImpulseRecoveries`, a
  statistic nothing reads) is written from several threads. Harmless.
- Bullet's thread pool is global; its size is the last `setThreads` (at most
  the machine's hardware threads).
- Tried on Linux only. `scripts/bullet-threads.sh` needs git and cmake.

**William's speed table** (6 November, `runs/room-speed.sh`, patches 70-76,
machine otherwise idle; single 5 s runs; marks on, marks off within 0.02):

| Walkers | Bracing | Timing | Direction | Threads 0 | 1 | 2 | 4 | 8 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 (Chebyshev-Spears lift 51 diag) | diag | trot | forward | 2.52x | 2.52x | 2.55x | 2.51x | 2.51x |
| 4 (Klann, Jansen, Chebyshev-Spears lift 51 diag, lift 62 diag) | mixed | trot | forward | 0.58x | 0.58x | 0.76x | 0.73x | 0.78x |
| all 21 | mixed | trot | forward | 0.11x | 0.11x | 0.13x | 0.15x | 0.17x |

One walker gains nothing (one island). Four gain 1.3 times, all of it at 2
threads; 21 gain 1.55 times and keep gaining to 8. Likely (not measured): one
walker's solve at 1920 steps a second is so short that waking the threads and
waiting for them costs about what they save, so more walkers a step gain more.

**The soak** (William's machine, 6 November: `tools/roomsoak.lua`, 8 threads,
`AMP = 4`, Tab every 20 s, a new ground every 15 minutes). 70 simulated
minutes and 212 swaps went cleanly; at minute 71 Chebyshev-Spears lift 62 diag
was 12 m outside the 10 m room and 135 m below the floor: it left the room
(there is no floor outside) in the last 5 s or so. Not yet known whether it
walked over the wall (20 cm blocks sunk by `AMP`, so on waves of 4 cm a crest
can come within about 12 cm of the top; lift 62 raises its feet highest;
William has seen walkers go over the wall) or the linkage blew apart. The run
could not be replayed here: it repeats exactly on one machine with any number
of threads, but not on another (here GCC 13, Lua 5.1 and another C library;
his GCC 12 and Lua 5.2), where the odd last digit differs and over minutes
the walk. (A 20 s track run did match on both.) `tools/roomsoak.lua` now
checks every walker every 0.1 s and, on a loss, prints its last 5 s
(patch 78).

**To do on William's machine.** The soak again with the same settings (it
replays his run and should lose the same walker at about minute 71, now with
its last 5 s), and then the fix that its trace points to.

## Before (the handover of 1 November, kept as written)

For a future session: can bpp run physics on more than one core, using the
walkers as the test? Nothing here has been tried yet. Read `HANDOVER.md`
sections 4i (speed) and 4l (several walkers) first.

### The answer so far

- **The Bullet bpp links today cannot run threads.** bpp uses the system
  Bullet (`bpp.pro`, `PKGCONFIG += bullet`; here Ubuntu's
  libbullet 3.24+dfsg). It is built without `BT_THREADSAFE`: its task
  schedulers (`btCreateDefaultTaskScheduler`, `btGetOpenMPTaskScheduler`,
  `btGetTBBTaskScheduler`) are present but are stubs, so
  `btDiscreteDynamicsWorldMt` would run on one thread.
- **So Bullet's own threading needs bpp to bundle its own Bullet**, built
  with threads (Bullet's CMake: `BULLET2_MULTITHREADING=ON`, plus one of
  OpenMP, TBB or PPL). It cannot use both the system Bullet and its own.
- **One walker gains little from Bullet's threads.** A walker is one
  island (all its parts joined), and Bullet's threaded solver works island
  by island. The gain would be in rooms with several walkers.

### What there is to beat

From `tools/roomtime.lua` (fast setting, flat room, marks and steering on;
this machine, not William's Ryzen 7 3700X, which is perhaps 2-3 times as
fast, not measured). Times are simulated time over wall time.

| Walkers | Bracing | Timing | Direction | Speed |
| --- | --- | --- | --- | --- |
| 1 | as built | trot | forward | 0.48x |
| Klann alone | own frame | trot | forward | 0.76x |
| Jansen alone | own frame | trot | forward | 0.83x |
| 4 (Klann, Jansen, Chebyshev-Spears lift 51 diag, Chebyshev-Spears diag) | mixed | trot | forward | 0.15x |
| all 21 | mixed | trot | forward | 0.03x |

The cost adds up walker by walker; nothing is shared. Four walkers are four
separate problems, so in principle four cores could run them at about
one walker's speed. With one walker, about two-thirds of the time is solver
iterations and a third the 64 physics steps a frame (4i).

### Three ways to do it

#### 1. Bundle Bullet, built with threads, and use its threaded world

- Add Bullet 3.24 (or newer) to the repo, or as a submodule, built by
  `bpp.pro` (or a script) with `BT_THREADSAFE`.
- Use `btDiscreteDynamicsWorldMt` with `btConstraintSolverPoolMt` and set a
  task scheduler (`btSetTaskScheduler`).
- Walkers in one world, so they can still touch each other.
- **Problems:**
  - bpp's worlds are `btSoftRigidDynamicsWorld` (soft bodies). The threaded
    world has no soft bodies, so it would be a separate kind of world, chosen
    by the script.
  - `si-warm` (`WarmJointSolver`, viewer.cpp) keeps a cache of each joint's
    last impulses inside the solver object. The solver pool holds several
    solvers, and an island can go to a different one each step, so it would
    lose its warm start. The cache would need to be shared and safe to use
    from several threads (for example, one cache keyed by joint, written
    only by the thread solving that joint's island).
  - The packaging changes for every platform (Linux, macOS via Homebrew,
    Windows via MSYS2, the Debian package).

#### 2. The same, as an optional build

As 1, but the bundled threaded Bullet only when asked for
(`qmake CONFIG+=bundled_bullet`, say); the system Bullet stays the default.
Less risk to the other demos and packages; two builds to keep working.

#### 3. A world per walker, each stepped on its own thread

bpp already has several worlds (`v:newWorld()`, `v:useWorld()`;
viewer.cpp around line 960). Each walker could have its own world and
ground, and each frame the worlds stepped side by side on separate threads,
then joined before the Lua hooks run.

- **No bundled Bullet needed** if Bullet's globals turn out to be safe.
- **Lua stays on one thread:** `preSim` and `postSim` run once a frame, not
  inside the physics steps, so the threads would run only between them.
- **Problems:**
  - Walkers in separate worlds cannot touch each other. In the room they
    would pass through each other. For tables (one walker a run) it changes
    nothing.
  - Each world needs its own copy of the ground (the 8 m track is 214,000
    triangles; start-up 14 s for one).
  - Globals to check before trusting it: Bullet's global counters and
    callbacks (`gContactAddedCallback` and the like), the profiler (here its
    zones look like no-ops, `BT_NO_PROFILE`, but check), `g_jointWarmstart`
    (read only, fine), `bppGyroPreTick` (works on its own world, likely fine),
    `RestSkippingDispatcher`, and anything in viewer.cpp that keeps one
    shared list for all worlds (`_aabbSeen`, `reapRemoved`).
  - A crash from a race may be rare; a long soak test is needed.

### How to test

1. **Same results.** A threaded run must walk as the single-threaded one.
   Rerun the standard table (`runs/run-table.sh`, warm40fast, nine rough
   grounds, 5 seeds) and compare with `runs/table.py`: mean change near 0,
   rank correlation about 0.96 or better, no build past its ± (as the checks
   in 4i-4k). Expect runs to differ move for move if the order of work
   changes; only the table should match.
2. **Speed.** `tools/roomtime.lua` with 1, 4 and 21 walkers; and the room
   (`room-four.lua`) watched in the window.
3. **Swapping.** In `room-four.lua`, Tab and Shift+Tab take a walker out and
   put another in while the others walk on (4o). This must still work with
   threads.
4. **Soak.** Hours of the room on rough ground with no crash.

### Suggested order

Try 3 first on the test track's table runs: it needs no new Bullet and can
be dropped if a global gets in the way. If the room needs walkers that
touch, or 3 hits a global, go to 2 (the optional bundled Bullet) and keep the
system Bullet as the default.
