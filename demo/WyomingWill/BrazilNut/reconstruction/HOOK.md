# The exhibit's beads: bead-bed.c inside bpp (DemBed)

The exhibit is simulated by `bead-bed.c`, the reference model of FINDINGS.md
and GLASS-DESIGN.md, moved into bpp:

- `src/demcore.h`, `src/demcore.cpp`: **DemCore**, the model as a C++ class.
  Everything from `bead-bed.c`'s helpers to its pour and its validation tests
  is `bead-bed.c`'s own code, lifted mechanically by `port/port.py`:
  - its globals become members, its functions member functions;
  - its `printf()`s become the tests' output;
  - each body stays unchanged, character for character.

  The frame loop (`init`, `stepTo`, `substep`, `afterFrame`) is `bead-bed.c`'s
  `main` loop cut into steps, so a run is the same however the time is handed
  out. `port/gen.py` writes both files from `bead-bed.c` and the two
  hand-written templates `port/demcore.h.in` and `port/demcore.cpp.in`:

  ```
  cd port && python3 port.py ../bead-bed.c && python3 gen.py ../../../../..
  ```

  So a change to the physics is made in `bead-bed.c` and carried over by
  rerunning this, never by editing `src/demcore.cpp` by hand.
- **Added for the exhibit**, all off by default and outside `bead-bed.c`'s
  code:
  - a gentle opening (`GAMMA0` for `TG` s, then the amplitude ramped to
    `GAMMA`'s over `TR` s) with its own push window (`GW1`, `GW2`), and the
    hard window's shakes (`WATCH1`, `WATCH2`, 4 and 32 by default as in
    `bead-bed.c`);
  - the wall height `H`, a tracer bead `TRACER`, and the big bead's rise
    times (`RISE1`, `RISE2`, over `RISEW` s);
  - its late height windows (`LATE0`, `LATE1`; `LATEB0`, `LATEB1`);
  - the highest any bead's top reaches (`topMax`), and how often a bead is
    above `TOPCHK`;
  - the big bead's turn, its spin integrated, for drawing only (`angle`).

  The lid (`LID`, a flat ceiling met like the walls) is physics, so it was
  added to `bead-bed.c` itself, with its test `TEST=lid`, and carried over
  by the port. The port cuts `bead-bed.c` at its own section comments.
- `src/dembed.h`, `src/dembed.cpp`: **DemBed**, DemCore for Lua, registered
  in `viewer.cpp`. Its API:
  - `set(key, value)`: `bead-bed.c`'s keys, with `BOX` 0, 1 or 2;
  - `init()`;
  - `step(t)`, or `start(t)` and `finish()`, which run one thread per box;
  - `get(name)`: parameters and measurements, listed in `demcore.cpp`;
  - `x(i)`, `y(i)`, `r(i)`, `boxY()`, `gluedCount`, `gluedX`, `gluedY`;
  - `attach(i, obj)` (several objects per bead; each keeps its own
    orientation and turns with the bead), `attachGlued(wall, k, obj)` and
    `sync(ox, oy, oz)`, which move display-only bpp objects; `angle(i)`;
  - `cpu()`, `test(name)`, and the global `demWallClock()`.

  A box shares nothing with another, so threads can't change its numbers.

## Checks (17 Oct 2026)

- **DemCore outside bpp.** `dembed-check.cpp` takes `bead-bed.c`'s arguments
  and prints its result lines:

  ```
  g++ -O2 -I../../../../src -o dembed-check dembed-check.cpp ../../../../src/demcore.cpp
  ```

  Against `bead-bed` (`gcc -O2`), the settle, push, roll and final result
  lines are **bit for bit the same** (cpu time aside) for:
  - the linear law (set a);
  - Hertz glass in the right box (tracer trips);
  - Hertz e 0.1;
  - glued-bead walls with a hollow big bead;
  - P60 grit on a lined floor;
  - plates (the 3-D contact path);
  - rolling resistance;
  - the restitution threshold `ETH`;
  - the linear law at TC 0.3 ms to 6 s, which covers the push report,
    "reaches the top" and the late window.

  The runs are 4 to 6 s, each from the pour, with `bead-bed`'s
  `CONVSTART=1`. They are reproduced in the scratch `compare.sh`:

  ```
  ./bead-bed ARGS ; ./dembed-check ARGS     # then compare their RESULT lines
  ```
- **The exhibit.** Its own console numbers (`BN_SEED` 7) equal
  `dembed-check`'s on the same settings, with the opening, the windows and
  `H` 44:
  - the big bead's rise, 10.633 s;
  - the rolls, +6.14 / -11.75 mm/s (right box +0.36 / +3.98);
  - its late height, 15.73 cm.

  So the hook in bpp, two threads and the frame clock change nothing.
- **The lid** (18 Oct 2026). `TEST=lid` gives the same lines in `bead-bed`
  and `dembed-check`: e = 0.9500-0.9504 from 1 to 200 cm/s, as the floor
  gives. A 4 s design run with a low lid (`LID=22`, which the beads hit) is
  the same bit for bit. Adding the lid left the defaults bit for bit as
  before.
- **DemBed inside bpp** (`hook-check.lua`):
  - `bead-bed.c`'s validation tests run through the hook give the same 100
    lines as `bead-bed TEST=...`: drop and pair (Hertz e 0.95, linear e 0.1),
    incline (Hertz mu 0.64, linear mu 0.1), gdrop and ghollow (glued
    spheres, the left wall), and lid.
  - A 4 s run of the design (280 beads, 5 Hz, glued walls, 6.3 GPa) gives
    `bead-bed`'s settle, rolls (+14.68 / -16.93 mm/s) and overlaps exactly.
  - bpp is built with `-O3` and `bead-bed` with `-O2`. Neither contracts
    multiply-adds on plain x86-64, so they agree.

```
CHECK=tests ../../../../release/bpp -f hook-check.lua -n 2
CHECK=bed CHECK_ARGS="BOX=middle MODEL=1 YM=6.3e9 NS=80 E=0.95 MUB=0.1 MUW=0.1 ROUGH=1 RG=0.5 SG=1 MUG=0.1 N=280 F=5 SEED=7 TEND=4.05 CONVSTART=1 CONVEND=4" \
  ../../../../release/bpp -f hook-check.lua -n 2
```
