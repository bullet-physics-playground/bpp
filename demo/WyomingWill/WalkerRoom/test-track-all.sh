#!/bin/bash
# Runs every walker on the test track (test-track.lua) in every condition,
# headless, and collects the TRACK lines in test-track-results.txt.
#
#   ./test-track-all.sh [path/to/bpp]
#
# Conditions: flat ground, and bump heights 2, 4 and 6 cm at bump lengths
# 11, 15 and 22 cm, each from 4 starts (seeds), 60 s per run. JOBS (default
# 2) runs that many at once. With 2 that is about half an hour.

BPP=${1:-bpp}
JOBS=${JOBS:-2}
cd "$(dirname "$0")"
OUT=${OUT:-test-track-results.txt}
: > "$OUT"

WALKERS=("Jansen" "Klann" "Chebyshev" "Chebyshev diag" "Chebyshev-Spears"
         "Chebyshev-Spears diag" "Hoecken 4-bar" "Hoecken slider" "Hoecken-Spears slider"
         "Spears 4-bar" "Hoecken-Spears 4-bar" "Hoecken-Spears 4-bar duty 85")   # (the 2-leg Spears too, with TWO_LEGS=true in EXTRA, if added here)
CONDITIONS=("0 22")
for h in 2 4 6; do for l in 11 15 22; do CONDITIONS+=("$h $l"); done; done

run() {   # walker height length seed
  local f
  f=$(mktemp ./_track_XXXXXX.lua)
  printf 'ONLY="%s"; AMP=%s; BUMP=%s; SEED=%s; '"$EXTRA"'\ndofile("test-track.lua")\n' "$1" "$2" "$3" "$4" > "$f"
  QT_QPA_PLATFORM=offscreen "$BPP" -f "$(basename "$f")" -n 3700 2>&1 | grep "^TRACK "
  rm -f "$f"
}
export -f run
export BPP EXTRA

for w in "${WALKERS[@]}"; do
  for c in "${CONDITIONS[@]}"; do
    for seed in 1 2 3 4; do
      printf '%s\t%s\t%s\n' "$w" "$c" "$seed"
    done
  done
done | while IFS=$'\t' read -r w c seed; do
  set -- $c
  printf '%s\0%s\0%s\0%s\0' "$w" "$1" "$2" "$seed"
done | xargs -0 -n 4 -P "$JOBS" bash -c 'run "$@"' _ >> "$OUT"

echo "done: $(wc -l < "$OUT") runs in $OUT"
