# The alphabet's search

How the linkages that write got their linkages. `alphabet.json` is the
result; `../make-alphabet.py` turns it into `../alphabet.lua`.

## The synthesizer

`linkage_synthesis.py`, `linkage_native.c` and `linkage_core.h` are
William Spears's planar linkage synthesizer: a four-bar (ground pivots O2
and O4, crank, coupler, rocker, a point on the coupler) with RR dyads hung
on it, each a pair of bars from the last point to a new ground pivot,
carrying a new point; the last point is the pen. Differential evolution
searches the lengths, pivots and offsets for each size (4, 6, 8, ... bars)
for the curve nearest the target in shape (a best-fit rotation, scale and
shift), the crank's turns snapped to a whole number, with a Grashof gate
(the crank goes all the way round) and assembly margins (no loop near
toggle).

Three additions in `linkage_native.c`, marked "added for the hall's
alphabet":

- a warm start: each size starts from the best smaller linkage, its new
  dyad hung where it draws nothing new, so more bars never do worse;
- a `DRESULT` line for every size, with its parameters;
- `LK_BOUND`, how many cranks long an arm or offset may be (8 by default;
  3 keeps a linkage compact).

Every search here used `--min_margin_frac 0.6`: at the default 0.05 the
linkages ran their loops within a twentieth of a crank of toggle, and in
bpp a dyad snapped to its other assembly halfway round (`../FINDINGS.md`).

## The letters

- `letters.py`: the 26 capitals as strokes, height 1; each made one closed
  pen walk (the strokes a graph, its odd points paired by their shortest
  connections, an Euler circuit: the Chinese postman's tour), timed so the
  pen slows at corners, and sampled at 100 steps.
- `multi.py`: the letters split at their junctions, a pen to each stroke.
- `final2.py`: every split of every letter (one pen; split at the
  junctions; single lines and arcs, the lines and half circles all drawn
  by one canonical linkage each, carried onto each stroke), every pen's
  best linkage at every size, measured as drawn (the farthest the pen gets
  from its stroke, or a point of the stroke from the pen, in the letter's
  heights), and for each slider position the cheapest split (fewest bars,
  then fewest pens) whose every pen is within it: 8%, 4%, 2%; a linkage
  may reach no more than four letter heights over a turn (`MAXSPAN`), and
  no pin may move faster than 20 cranks a radian of the crank (`MAXSPEED`,
  `speed.py`).
- `final.py`: the measure (and an older table).

## Again

    tar xJf runs.tar.xz                       # the runs as made (runs4/, cur/, b3/)
    MAXSPAN=4 python3 final2.py               # -> alphabet.json, and the picks
    cd .. && python3 make-alphabet.py         # -> alphabet.lua

or, to search again from nothing, `THREADS=16 ./search.sh` (hours on 2
cores), then the last two lines.
