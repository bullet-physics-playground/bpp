#!/bin/bash
# The steering runs (handover/STEERING.md): the wheels (SHOES in walker-room.lua), one braked on the left and on the
# right, against none, every run with YAW_DAMP=0 (no damping of the body's turning at all); then both free on the nine
# rough terrains with the yaw damping on, what having them costs. Each variant is a run-table.sh table of its own,
# with steerprobe.lua (or speedprobe.lua); runs/steer.py makes the turning table and the paths.
#
#   cd demo/WyomingWill/WalkerRoom
#   BPP=../../../release/bpp runs/steer-table.sh
#   python3 runs/steer.py runs/out-steer
#
# Environment: as run-table.sh (BPP, JOBS, SEEDS (default 1 2), TERRAINS (default waves:0 waves:2), RUN_SECS),
# OUT (default runs/out-steer). (Stages 1 and 2, the steering tests before the wheels -- foot friction, pair and side
# slowing, ballast, drag shoe, soles, ankles, link damping: STEER in walker-room.lua -- were removed on 11 November;
# their results are in STEERING.md, their code at commit 6a1bcb22.)
set -u
cd "$(dirname "$0")/.."
OUT=${OUT:-runs/out-steer}
export SEEDS=${SEEDS:-"1 2"} TERRAINS=${TERRAINS:-"waves:0 waves:2"} PROBE=runs/steerprobe.lua
J=$(mktemp)
echo "Chebyshev-Spears lift 51 diag" > "$J"; echo "Jansen" >> "$J"   # (every variant: both builds)
run() {   # variant name, SHOES (or none)
  OUT="$OUT/$1" BUILDS="$J" EXTRA="YAW_DAMP=0${2:+; SHOES=$2}" runs/run-table.sh > /dev/null
  echo "done $1"
}
run base ""
run wheels-free-0.15 "{}"
for s in L R; do run "wheels-$s-0.15" "{down=\"$s\"}"; done
rough() { OUT="$OUT/$1" BUILDS="$J" SEEDS="1 2 3 4 5" TERRAINS="waves:2 waves:4 waves:6 logs:3 logs:5 logs:7 steps:3 steps:5 steps:7" \
  PROBE=runs/speedprobe.lua EXTRA="$2" runs/run-table.sh > /dev/null; echo "done $1"; }
rough rough-none ""
rough rough-wheels "SHOES={}"
rm -f "$J"
