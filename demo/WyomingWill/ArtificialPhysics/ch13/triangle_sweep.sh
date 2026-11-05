#!/bin/bash
# ch13/triangle_sweep.sh -- Ch. 13's triangle of death on the Pioneer
# (ch13/Triangle-Ground.lua): the particle 0-0.4 m ahead of the rotation
# centre x the pull turned -30, -10, 0, 10, 30 deg from robot 3's axle x
# pulls of 10-16, 20, 25 and 50 N, wheels below the minimum speed rounded
# up (the default, F72), with the book's stop threshold (5 N); pulls of
# 25 and 50 N with them stopped (roundDown); and pulls of 2, 5 and 10 N
# with no stop threshold. 120 s each, 375 runs.
#
# COST (measured): a run takes ~1.7 wall s, so the sweep is ~11 CPU-minutes.
#
# Resumable: runs already in the output are skipped. Each run appends the
# scene's result line to ch13/triangle_runs.txt; at the end the table
# (ch13/README.md has it) is printed: per wheel rule, stop threshold
# and pull, for each
# offset, the runs in which robot 3 escaped (moved 1 m toward the pull's
# point) out of the five angles. Run from the ArtificialPhysics folder:
#   bash ch13/triangle_sweep.sh [JOBS]      (default: nproc)
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
export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/tmp/rt-triangle}; mkdir -p "$XDG_RUNTIME_DIR"; chmod 700 "$XDG_RUNTIME_DIR"
OUT=ch13/triangle_runs.txt
touch "$OUT"
list() {
  for p in 10 11 12 13 14 15 16 20 25 50; do for off in 0 0.1 0.2 0.3 0.4; do for a in -30 -10 0 10 30; do
    echo "$off $a $p 0 5"
  done; done; done
  for p in 25 50; do for off in 0 0.1 0.2 0.3 0.4; do for a in -30 -10 0 10 30; do
    echo "$off $a $p 1 5"
  done; done; done
  for p in 2 5 10; do for off in 0 0.1 0.2 0.3 0.4; do for a in -30 -10 0 10 30; do
    echo "$off $a $p 0 0"
  done; done; done
}
# drop the runs already done (key: offset angle pull roundDown stop)
todo=$(list | awk -v out="$OUT" 'BEGIN { while ((getline l < out) > 0) { n = split(l, f, " ")
           if (n >= 25) done[f[3]" "f[5]" "f[7]" "f[9]" "f[11]] = 1 } }
         !(($1" "$2" "$3" "$4" "$5) in done)')
total=$(list | wc -l); left=$(printf '%s' "$todo" | grep -c . || true)
echo "triangle of death: $((total - left)) of $total runs done, $left to go, $JOBS at a time ($BPP)"
run() { # OFFSET ANGLE PULL DOWN STOP: one run, its result line appended
  TRI_OFFSET=$1 TRI_ANGLE=$2 TRI_PULL=$3 TRI_DOWN=$4 TRI_STOP=$5 TRI_EXIT=1 \
    "$BPP" -f ch13/Triangle-Ground.lua -n 1000000 2>/dev/null | grep '^Triangle ' >> "$OUT" || true
}
export -f run; export OUT
[ "$left" -eq 0 ] || printf '%s\n' "$todo" | xargs -P "$JOBS" -L 1 bash -c 'run "$@"' _
awk 'NF >= 25 { for (i = 1; i < NF; i++) v[$i] = $(i + 1)
       k = v["roundDown"] " " v["stop"] " " v["pull"] " " v["offset"]; c[k]++; if (v["Escaped"] >= 0) e[k]++ }
     END { printf "robot 3 escaped, of 5 angles, by the particle offset (m)\n%-9s %4s %5s %5s %5s %5s %5s %5s\n",
             "wheels", "stop", "pull", "0", "0.1", "0.2", "0.3", "0.4"
           n = split("0 5 10|0 5 11|0 5 12|0 5 13|0 5 14|0 5 15|0 5 16|0 5 20|0 5 25|0 5 50|1 5 25|1 5 50|0 0 2|0 0 5|0 0 10", R, "|")
           split("0 0.1 0.2 0.3 0.4", O, " ")
           for (j = 1; j <= n; j++) {
             split(R[j], r, " "); if (!c[R[j] " 0"]) continue
             printf "%-9s %4s %5s", r[1] ? "stop" : "round up", r[2], r[3]
             for (l = 1; l <= 5; l++) printf " %5d", e[R[j] " " O[l]]
             printf "\n" } }' "$OUT"
