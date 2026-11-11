# Threads in bpp

bpp can solve the physics of separate things -- walkers, chains, anything not
joined or touching -- side by side on several cores: `v:setThreads(n)`. It
needs bpp built with its own copy of Bullet built with threads (the Bullet in
Linux packages has none). The normal build is unchanged and has no threads.

## Building bpp with threads

In bpp's folder:

```
scripts/bullet-threads.sh
qmake CONFIG+=bundled_bullet
rm -rf release/bpp release/bpp.gch
make -j8
```

- `scripts/bullet-threads.sh` downloads Bullet 3.24 and builds it with
  threads into `lib/` (git ignores it): about a minute. Needs git and cmake.
- `qmake` should print "Using Bullet with threads from .../lib/bullet-mt".
  Add whatever else you pass to qmake.
- The `rm` is needed whenever qmake's settings change: otherwise the old
  precompiled header (named after the program) no longer fits, and the
  compiler stops with "stray '\177'" errors.

Without `setThreads`, this build runs exactly as the normal one (the test
harness gives the same results), so it can be the only bpp you use.

Back to the normal build: the same, with `qmake` without
`CONFIG+=bundled_bullet`.

## Trying it

```
cd demo/WyomingWill
../../release/bpp Testing_Threads.lua
```

32 swinging chains; the Threads slider sets `v:setThreads` while it runs.
The status bar (and the terminal) shows how many times faster the physics
runs than with no threads.

## In a script

`v:setThreads(n)` after `v:setSolver(...)`; `v:setThreads(0)` is the world as
before. It returns the threads in use (0 with the normal build, which says so
and carries on). Any number of threads gives the same run, move for move, and
one thing alone (one walker) runs exactly as without threads. The solving
and, since 10 November 2026, the collision detection are shared out (the
collisions only in a step with 128 pairs of touching boxes or more, about
two walkers' worth: fewer cost more to share than they save); the scripts
and the drawing stay on one thread, so the gain depends on how much of the
work is solving and colliding.

Details, measurements and how it works:
`demo/WyomingWill/WalkerRoom/handover/THREADS.md`; the code is in
`src/bppworld.cpp`.
