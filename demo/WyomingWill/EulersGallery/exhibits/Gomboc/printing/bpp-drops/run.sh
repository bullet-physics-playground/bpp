#!/bin/bash
# usage: run.sh CASE_FOLDER ROLL_UM SLOPE_DEG SEED FRAMES      (logs to CASE_FOLDER.log)
#   ROLL_UM  rolling-resistance length in microns (BPP GC_ROLL; measured on PLA: glass 20-30, butcher block 50-70)
#   SLOPE_DEG table tilt (gravity tilted toward +x); 0 = level
#   FRAMES   simulation frames at 60 per second (5400 = 90 s; 6 bodies at a time, each re-dropped 5 s after it rests)
# Set BPP to the bpp binary (default: bpp on PATH). Run from anywhere.
here=$(cd "$(dirname "$0")" && pwd); repo=$(cd "$here/../../../../../../.." && pwd)
case_dir=$(cd "$1" && pwd)
export LUA_PATH="$repo/demo/module/?.lua;$repo/demo/?.lua;;"
cd "$case_dir" && GC_SLOPE=$3 GC_SEED=$4 GC_COUNT=6 GC_REDROP=5 GC_ROLL=$2 \
  "${BPP:-bpp}" -n "$5" -f "$here/gomboc-drop-slope.lua" > "$case_dir.r$2_a$3_s$4.log" 2>&1
echo "$1 roll $2 slope $3 seed $4 exit $?"
