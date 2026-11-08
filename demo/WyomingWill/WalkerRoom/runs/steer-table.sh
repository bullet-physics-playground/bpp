#!/bin/bash
# The steering runs (handover/STEERING.md, 8 November 2026): each bias (STEER in walker-room.lua) on the left
# and on the right, against no bias, every run with YAW_DAMP=0 (no damping of the body's turning at all:
# YAW_DAMP=false would leave each file's own damping, 1.0, which holds it as straight). Each variant is a
# run-table.sh table of its own, with steerprobe.lua; runs/steer.py makes the table and the paths.
#
#   cd demo/WyomingWill/WalkerRoom
#   BPP=../../../release/bpp runs/steer-table.sh
#   python3 runs/steer.py runs/out-steer
#
# Environment: as run-table.sh (BPP, JOBS, SEEDS (default 1 2), TERRAINS (default waves:0 waves:2), RUN_SECS),
# OUT (default runs/out-steer), STAGE (default 1: foot friction, pair and side slowing).
set -u
cd "$(dirname "$0")/.."
OUT=${OUT:-runs/out-steer}; STAGE=${STAGE:-1}
export SEEDS=${SEEDS:-"1 2"} TERRAINS=${TERRAINS:-"waves:0 waves:2"} PROBE=runs/steerprobe.lua
B=$(mktemp); J=$(mktemp)
echo "Chebyshev-Spears lift 51 diag" > "$J"; echo "Jansen" >> "$J"   # (every variant: both builds)
echo "Jansen" > "$B"                                               # (side slowing: Jansen only, no braces)
run() {   # variant name, builds file, STEER (or none)
  OUT="$OUT/$1" BUILDS="$2" EXTRA="YAW_DAMP=0${3:+; STEER=$3}" runs/run-table.sh > /dev/null
  echo "done $1"
}
case "$STAGE" in
1)
  run base "$J" ""
  for s in L R; do
    for k in 0.75 0.5 0.05; do run "friction-$s-$k" "$J" "{mech=\"friction\", side=\"$s\", amount=$k}"; done
    for k in 0.8 0.6; do run "pair-$s-$k" "$J" "{mech=\"pair\", side=\"$s\", amount=$k}"; done
    for k in 0.8 0.6; do run "side-$s-$k" "$B" "{mech=\"side\", side=\"$s\", amount=$k}"; done
  done
  run pair-L-1 "$J" '{mech="pair", side="L", amount=1}'   # (the loosened lock alone)
  ;;
esac
rm -f "$B" "$J"
