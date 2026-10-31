#!/bin/bash
# ch07/corridor_ground_sweep.sh -- Ch. 7's corridor sweep (Figs.
# 7.11-7.13) on BPP's ground robots (ch07/Corridor-Ground.lua: Kerr's
# controllers on the Pioneer, his geometry x 3.28, one step a second),
# against the port's sweep (F101). His code (no switches) with the
# robots' back-off on (backOff: without it robots jam on obstacles' corners
# and runs do not end, F102); one run per course, so 10 runs per setting
# (his 10 courses, run 0: seed 100 + 10 k). Exp. 1: 25 robots at 0-40%
# obstacles; Exp. 2: 5-30 robots at 20%.
#
# COST (measured, F102): 8.7 simulated seconds per wall second per core
# with 25 robots, so a KT run at 20% (~18,000-22,000 steps) is ~35-40
# minutes, Ant's ~65,000 steps about 2 hours, Default at 40% (often the
# 150,000-step limit) up to 5 hours. About 290 CPU-hours in all, if the
# robots take the port's steps; the runs go in this order, so what is
# done first answers most:
#   1. KT, Exp. 1 (0-40%)                         ~37 CPU-h
#   2. Ant at 20%, 25 robots (the book's KT-vs-Ant comparison)  ~21
#   3. Default, Exp. 1                            ~43
#   4. KT, Exp. 2 (N 5-30 at 20%; N 25 is Exp. 1's 20%)  ~20
#   5. Default, Exp. 2                            ~12
#   6. Ant, the rest of Exp. 1 and Exp. 2         ~160
#
# Resumable: runs already in the output are skipped, so stop it (Ctrl-C,
# then kill any bpp left by PID) and start it again at will. Each run
# appends one line (Kerr's log line plus Bumps, RobotBumps, WallBumps,
# Moved, BackOff, BackOffs, Wall) to ch07/corridor_ground_runs.txt;
#   luajit ch07/kerr2005_figs.lua ch07/corridor_ground_runs.txt
# prints the figures against his logs ("code" is the robots). Run from the
# ArtificialPhysics folder:
#   bash ch07/corridor_ground_sweep.sh [JOBS]      (default: nproc)
# BPP: $BPP, else the newer of ../../../release/bpp and ../../../debug/bpp.
set -eu
cd "$(dirname "$0")/.."
JOBS=${1:-$(nproc)}
BPP=${BPP:-}
if [ -z "$BPP" ]; then
  for b in ../../../release/bpp ../../../debug/bpp; do
    [ -x "$b" ] && { [ -z "$BPP" ] || [ "$b" -nt "$BPP" ]; } && BPP=$b
  done
fi
[ -n "$BPP" ] || { echo "no BPP: build it or set BPP="; exit 1; }
export BPP SDL_AUDIODRIVER=${SDL_AUDIODRIVER:-dummy} QT_QPA_PLATFORM=${QT_QPA_PLATFORM:-offscreen}
export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/tmp/rt-corridor}; mkdir -p "$XDG_RUNTIME_DIR"; chmod 700 "$XDG_RUNTIME_DIR"
OUT=ch07/corridor_ground_runs.txt
touch "$OUT"
# CONTROLLER N PCT COURSE (run 0), in the order above
exp1() { for p in 40 30 20 10 0; do for k in 0 1 2 3 4 5 6 7 8 9; do echo "$1 25 $p $k"; done; done; }
exp2() { for n in 5 10 15 20 30; do for k in 0 1 2 3 4 5 6 7 8 9; do echo "$1 $n 20 $k"; done; done; }
list() {
  exp1 KT
  for k in 0 1 2 3 4 5 6 7 8 9; do echo "Ant 25 20 $k"; done
  exp1 Default
  exp2 KT
  exp2 Default
  exp1 Ant | grep -v '^Ant 25 20 '
  exp2 Ant
}
# drop the runs already done (key: controller N pct course)
todo=$(list | awk -v out="$OUT" 'BEGIN { name["KTRobot"] = "KT"; name["AntRobot"] = "Ant"; name["Simple2"] = "Default"
           while ((getline l < out) > 0) { n = split(l, f, " ")
             if (n >= 17) done[name[f[1]]" "f[5]" "f[7]" "f[9]] = 1 } }
         !(($1" "$2" "$3" "$4) in done)')
total=$(list | wc -l); left=$(printf '%s' "$todo" | grep -c . || true)
echo "corridor on ground robots: $((total - left)) of $total runs done, $left to go, $JOBS at a time ($BPP)"
run() { # CONTROLLER N PCT COURSE: one run, its result line appended
  KERR_CTL=$1 KERR_N=$2 KERR_PCT=$3 KERR_COURSE=$4 KERR_RUN=0 KERR_BACKOFF=1 KERR_EXIT=1 \
    "$BPP" -f ch07/Corridor-Ground.lua -n 5000000 2>/dev/null | grep -E '^(KTRobot|AntRobot|Simple2) ' >> "$OUT" || true
}
export -f run; export OUT
[ "$left" -eq 0 ] || printf '%s\n' "$todo" | xargs -P "$JOBS" -L 1 bash -c 'run "$@"' _
echo "corridor on ground robots: $(awk 'NF >= 17 { print $1, $5, $7, $9 }' "$OUT" | sort -u | wc -l) of $total runs in $OUT"
