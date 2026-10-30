#!/bin/bash
# The walker room's table runs, on any machine (30 October 2026). Each run: one build on the test track, one
# terrain and seed, RUN_SECS (20) s, offscreen; speedprobe.lua prints its RUN line. Resumable: a finished run's
# file is kept and not run again.
#
#   cd demo/WyomingWill/WalkerRoom
#   BPP=~/bpp/release/bpp runs/run-table.sh                 # the standard, warm40fast (no setting named)
#   BPP=~/bpp/release/bpp runs/run-table.sh warm40          # one setting
#   BPP=... JOBS=6 SEEDS="1 2 3 4 5" runs/run-table.sh warm40 warm40fast
#   python3 runs/table.py runs/out/warm40 runs/out/warm40fast   # the tables, and how they compare
#
# Settings (the solver, its iterations and the physics step; everything else is the 28 October standard: motor
# 0.25 a crank, Earth gravity, ankle springs, 1.0 cm links, trot, forward, the 8 m track, bump 15):
#   plain200    Bullet's solver, 200 iterations, step 1/3840 s  (the 29 October ranking)
#   warm40      joint warm-starting (v:setSolver("si-warm")), 40 iterations, 1/3840 s
#   warm40fast  joint warm-starting, 40 iterations, 1/1920 s  (the standard for runs since 30 October: it gave
#               the ranking's results within the noise, at under half warm40's time; handover section 4i)
# Environment: BPP (default: bpp on the PATH), JOBS (default: the number of cores), SEEDS (default 1 2 3 4 5),
# TERRAINS (default the nine rough ones), BUILDS (default the ranking's 13; a file, one name a line), OUT (default
# runs/out), RUN_SECS (20).
set -u
cd "$(dirname "$0")/.."
BPP=${BPP:-bpp}; JOBS=${JOBS:-$(nproc)}; SEEDS=${SEEDS:-"1 2 3 4 5"}; OUT=${OUT:-runs/out}; RUN_SECS=${RUN_SECS:-20}
TERRAINS=${TERRAINS:-"waves:2 waves:4 waves:6 logs:3 logs:5 logs:7 steps:3 steps:5 steps:7"}
if [ -n "${BUILDS:-}" ]; then mapfile -t NAMES < "$BUILDS"; else NAMES=(
  "Spears lift 44" "Spears lift 44 diag" "Spears lift 53" "Chebyshev-Spears diag" "Hoecken-Spears 4-bar diag"
  "Spears lift 53 diag" "Hoecken-Spears long-stance diag" "Hoecken-Spears slider diag" "Hoecken-Spears slider"
  "Hoecken-Spears 4-bar" "Klann" "Jansen" "Hoecken-Spears long-stance"); fi
[ $# -ge 1 ] || set -- warm40fast   # (no setting named: the standard)
command -v "$BPP" > /dev/null || { echo "bpp not found: set BPP to the bpp program"; exit 1; }
bracing() { case "$1" in Jansen|Klann|"Spears 4-bar") echo "OWN_FRAME=true";; *diag) echo "DIAG_OUTSIDE=true; PENDANT_HOLD=true";; *) echo "UNBRACED=true";; esac; }
setting() { case "$1" in
  plain200)   echo 'v:setSolver("si"); SOLVER_ITERATIONS=200; FIXED=1/3840';;
  warm40)     echo 'v:setSolver("si-warm"); SOLVER_ITERATIONS=40; FIXED=1/3840';;
  warm40fast) echo 'v:setSolver("si-warm"); SOLVER_ITERATIONS=40; FIXED=1/1920';;
  *) echo "";; esac; }
JOBLIST=$(mktemp)
for S in "$@"; do
  [ -n "$(setting "$S")" ] || { echo "unknown setting $S"; rm -f "$JOBLIST"; exit 1; }
  mkdir -p "$OUT/$S"
  for seed in $SEEDS; do for t in $TERRAINS; do for n in "${NAMES[@]}"; do
    out="$OUT/$S/${n// /_}_${t%%:*}${t##*:}_s$seed.txt"
    grep -q '^RUN' "$out" 2>/dev/null && continue
    echo "$S|$n|${t%%:*}|${t##*:}|$seed|$out" >> "$JOBLIST"
  done; done; done
done
echo "$(wc -l < "$JOBLIST") runs to do, $JOBS at a time"
export BPP RUN_SECS
one() {
  IFS='|' read -r S n ter amp seed out <<< "$1"
  f=$(mktemp ./_rt_XXXXXX.lua)
  printf '%s; v:setSolverInfo("residual", 0.01); MOTOR_STRENGTH=2; dofile("trotting-walkers.lua"); dofile("spears-lift-walkers.lua"); ONLY="%s"; TERRAIN="%s"; AMP=%s; SEED=%s; BUMP=15; GRAVITY=981; YAW_DAMP=1; ANKLE_SPRING={stiffness=42000, damping=4200}; LINK_WIDTH=1.0; GAIT={0,180,180,0}; %s; RUN_SECS=%s\ndofile("runs/speedprobe.lua")\n' \
    "$(setting "$S")" "$n" "$ter" "$amp" "$seed" "$(bracing "$n")" "$RUN_SECS" > "$f"
  start=$(date +%s)
  QT_QPA_PLATFORM=offscreen timeout 1800 "$BPP" -f "$(basename "$f")" -n $((RUN_SECS * 60 + 10)) 2>&1 | grep -aE '^RUN|rror' | grep -v ALSA > "$out.tmp"
  echo "TIME $(( $(date +%s) - start ))" >> "$out.tmp"; mv "$out.tmp" "$out"; rm -f "$f"
  echo "done $(basename "$out") $(grep -o 'speed [-0-9.]*' "$out")"
}
export -f one bracing setting
xargs -a "$JOBLIST" -d '\n' -P "$JOBS" -I{} bash -c 'one "$@"' _ {}
rm -f "$JOBLIST"
echo "ALL DONE"
