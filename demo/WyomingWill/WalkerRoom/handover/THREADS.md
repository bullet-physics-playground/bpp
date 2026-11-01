# Threads in bpp: a handover (1 November 2026)

For a future session: can bpp run physics on more than one core, using the
walkers as the test? Nothing here has been tried yet. Read `HANDOVER.md`
sections 4i (speed) and 4l (several walkers) first.

## The answer so far

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

## What there is to beat

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

## Three ways to do it

### 1. Bundle Bullet, built with threads, and use its threaded world

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

### 2. The same, as an optional build

As 1, but the bundled threaded Bullet only when asked for
(`qmake CONFIG+=bundled_bullet`, say); the system Bullet stays the default.
Less risk to the other demos and packages; two builds to keep working.

### 3. A world per walker, each stepped on its own thread

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

## How to test

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

## Suggested order

Try 3 first on the test track's table runs: it needs no new Bullet and can
be dropped if a global gets in the way. If the room needs walkers that
touch, or 3 hits a global, go to 2 (the optional bundled Bullet) and keep the
system Bullet as the default.
