#!/bin/bash
# ch07/sweep.sh -- the runs behind ch07/README.md and FINDINGS F92-F95, on
# ch07/theory.lua (Kerr's simulator as ch07/kerr.lua, his fixes switched on
# or off). Writes ch07/theory_runs.txt, one line per run. Run from the
# ArtificialPhysics folder; PART picks a part (speed, density, profile, or
# fig75, flow, or all), JOBS the parallel runs:
#   bash ch07/sweep.sh [PART] [JOBS]
# Times on one core: speed ~5 min, profile ~20 min, density ~1 h.
set -eu
cd "$(dirname "$0")/.."
PART=${1:-all}; JOBS=${2:-2}
OUT=ch07/theory_runs.txt
runs() {
  # speed: his temperatures and the book's range, each fix alone and all
  if [ "$PART" = all ] || [ "$PART" = speed ]; then
    for T in 25 273 350; do for f in none iso walls garcia iso,walls,garcia; do
      for s in 1 2 3; do echo "speed $T $s $f"; done; done; done
  fi
  # profile: one-sided at his Mach numbers and the book's 1-8, in his window
  # (steps 1-2,000), from his start and from rest, and settled (steps
  # 5,001-10,000); two-sided (both walls the same way, Fig. 7.8 right)
  if [ "$PART" = all ] || [ "$PART" = profile ]; then
    for M in 0.65 1.2 1.792 1 2 3 4 5 6 7 8; do for s in 1 2 3; do
      echo "profile one $M $s none 2000 1"; echo "profile one $M $s rest 2000 1"
      echo "profile one $M $s none 10000 5001"; done; done
    for M in 1 2 4 8; do for s in 1 2 3; do
      echo "profile two $M $s none 2000 1"; echo "profile two $M $s none 10000 5001"; done; done
  fi
  # density: his N and 30,000 steps, each fix alone and all; then the
  # book's N (Fig. 7.5), 5,000 steps, as his code is and with its walls at
  # y put right
  if [ "$PART" = all ] || [ "$PART" = density ]; then
    for f in none walls iso iso,walls,garcia; do for s in 1 2; do
      echo "density 10000 $s $f 30000"; done; done
  fi
  # flow (ours): Fig. 7.8's setting, V = 4, obstacles by Kerr's 2005
  # generator at 10-50%, each face rule; seed s lays out course s
  if [ "$PART" = all ] || [ "$PART" = flow ]; then
    for sides in one two; do for s in 1 2 3; do
      echo "flow $sides 4 0 none $s $s"
      for p in 0.1 0.2 0.3 0.4 0.5; do for r in rest couette specular; do
        echo "flow $sides 4 $p $r $s $s"; done; done; done; done
  fi
  if [ "$PART" = all ] || [ "$PART" = density ] || [ "$PART" = fig75 ]; then
    for N in 100 200 300 400 500 600 700 800; do for f in none walls; do for s in 1 2 3; do
      echo "density $N $s $f 5000"; done; done; done
  fi
}
runs | xargs -P "$JOBS" -L 1 lua5.1 ch07/theory.lua >> "$OUT"
echo "appended to $OUT"
