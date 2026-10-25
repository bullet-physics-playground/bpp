#!/bin/bash
# Gomboc-C righting from a headstand: 30 seeds, three bodies a run (75%,
# 100%, 125%: GV_SHAPES=1 GV_COUNT=3, 27 cm apart), re-drop off, 80 s each.
# Run from exhibits/Gomboc. BPP: the bpp binary (default: bpp on the PATH).
# OUT: where the consoles go (default /tmp/gv-headstand). Then:
#   python3 variety-reconstruction/headstand-times.py $OUT
# The study-era script (findings PDF, 9 Oct 2026), for comparison: the same
# with gomboc-variety.lua from commit c3d7bee
#   (git show c3d7bee:demo/WyomingWill/Gomboc/gomboc-variety.lua, run in a
#   checkout of c3d7bee, demo/WyomingWill/Gomboc/).
BPP=${BPP:-bpp}
OUT=${OUT:-/tmp/gv-headstand}
mkdir -p "$OUT"
for s in $(seq 1 30); do
  GV_SEED=$s GV_START=headstand GV_REDROP=0 HOLD_S=0 GV_SHAPES=1 GV_COUNT=3 \
    "$BPP" -f gomboc-variety.lua -n 4800 > "$OUT/s$s.out" 2>&1
done
