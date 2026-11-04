#!/bin/bash
# ch13/ring_sweep.sh -- the camera ring of Ch. 13's dumbbell agents on the
# Pioneer (ch13/Ring-Ground.lua, case 0): three settings x 3-5 robots x
# seeds 1-10 x both starts (random bearings 5-8 m out; a line 10 m out),
# 300 s each, 180 runs:
#   plain    the ring's law as it is (spread 0, no static friction)
#   spread   a weak pointing spring for the first 60 s (spread 60)
#   static   spread 60 and static friction, Eq. 13.25, g = 0.05
#
# COST (measured): 300 simulated s with 4 robots take ~3.5 wall s per
# core, so the sweep is ~11 CPU-minutes (~1.5 min at 8 jobs).
#
# Resumable: runs already in the output are skipped. Each run appends
# "<setting> <the scene's result line>" to ch13/ring_runs.txt; at the end
# the table (means over the runs; ch13/README.md has it) is printed. Run
# from the ArtificialPhysics folder:
#   bash ch13/ring_sweep.sh [JOBS]      (default: nproc)
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
export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/tmp/rt-ring}; mkdir -p "$XDG_RUNTIME_DIR"; chmod 700 "$XDG_RUNTIME_DIR"
OUT=ch13/ring_runs.txt
touch "$OUT"
list() {
  for set in plain spread static; do for n in 3 4 5; do for s in 1 2 3 4 5 6 7 8 9 10; do for st in 0 1; do
    echo "$set $n $s $st"
  done; done; done; done
}
# drop the runs already done (key: setting n seed start)
todo=$(list | awk -v out="$OUT" 'BEGIN { while ((getline l < out) > 0) { n = split(l, f, " ")
           if (n >= 30) done[f[1]" "f[6]" "f[8]" "f[10]] = 1 } }
         !(($1" "$2" "$3" "$4) in done)')
total=$(list | wc -l); left=$(printf '%s' "$todo" | grep -c . || true)
echo "camera ring: $((total - left)) of $total runs done, $left to go, $JOBS at a time ($BPP)"
run() { # SETTING N SEED START: one run, its result line appended
  local spread=60 g=0
  [ "$1" = plain ] && spread=0
  [ "$1" = static ] && g=0.05
  RING_N=$2 RING_SEED=$3 RING_START=$4 RING_SPREAD=$spread RING_SET="g=$g" RING_EXIT=1 \
    "$BPP" -f ch13/Ring-Ground.lua -n 1000000 2>/dev/null | grep '^Ring ' | sed "s/^/$1 /" >> "$OUT" || true
}
export -f run; export OUT
[ "$left" -eq 0 ] || printf '%s\n' "$todo" | xargs -P "$JOBS" -L 1 bash -c 'run "$@"' _
# the table: per setting and n, means over seeds and starts
awk 'NF >= 30 { for (i = 2; i < NF; i++) v[$i] = $(i + 1)
       k = $1 " " v["n"]; c[k]++; r[k] += v["Radius"]; p[k] += v["Point"]; g[k] += v["Gap"]
       m[k] += v["Moving"]; ps[k] += v["Passes"] / v["n"]; b[k] += v["Bumps"]; if (v["Formed"] >= 0) f[k]++ }
     END { printf "%-7s %2s %5s %7s %6s %5s %7s %8s %6s %7s\n", "setting", "n", "runs", "radius", "point", "gap", "moving", "passes", "bumps", "formed"
           split("plain spread static", S, " ")
           for (i = 1; i <= 3; i++) for (n = 3; n <= 5; n++) { k = S[i] " " n; if (c[k])
             printf "%-7s %2d %5d %7.3f %6.1f %5.2f %7.1f %8.0f %6.1f %7d\n", S[i], n, c[k], r[k] / c[k], p[k] / c[k],
               g[k] / c[k], m[k] / c[k], ps[k] / c[k], b[k] / c[k], f[k] } }' "$OUT"
