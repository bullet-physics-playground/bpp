#!/bin/bash
# Hoecken-Spears slider diag with Chebyshev-Spears diag's bottom-brace shape (runs 4.60 / 8.67 cm, its own height
# 5.51; OUTSIDE_FIT_TEST), logs 7, steps 7, waves 6, seeds 1-3, the ft2 standard (28-29 October).
cd /home/claude/bpp/demo/WyomingWill/WalkerRoom
mkdir -p /home/claude/work/bx
FIT='{ ["Hoecken-Spears slider diag"] = { bar = 1.074, top = { yRel = 15.19, runFront = 9.70, runBack = 9.76 }, bottom = { yRel = 5.51, runFront = 4.60, runBack = 8.67 } } }'
one() { out=/home/claude/work/bx/$3.txt; grep -q '^TQ' $out 2>/dev/null && return; f=$(mktemp ./_bx_XXXX.lua)
  printf 'v:setSolverInfo("residual", 0.01); SOLVER_ITERATIONS=200; MOTOR_STRENGTH=2; dofile("trotting-walkers.lua"); dofile("spears-lift-walkers.lua"); ONLY="%s"; %s; BUMP=15; GRAVITY=981; FIXED=1/3840; YAW_DAMP=1; ANKLE_SPRING={stiffness=42000, damping=4200}; LINK_WIDTH=1.0; GAIT={0,180,180,0}; DIAG_OUTSIDE=true; PENDANT_HOLD=true; OUTSIDE_FIT_TEST=%s; TQ_FROM=2; TQ_TO=20; dofile("/home/claude/work/torqueprobe.lua")\n' "$1" "$2" "$FIT" > $f
  QT_QPA_PLATFORM=offscreen timeout 900 /home/claude/build/release/bpp -f $(basename $f) -n 1210 2>&1 | grep -E "^(TQ|STALL|TRACK)|rror" | grep -v ALSA > $out; rm -f $f; }
J=()
for s in 1 2 3; do for t in logs:7 steps:7 waves:6; do J+=("Hoecken-Spears slider diag|TERRAIN=\"${t%%:*}\"; AMP=${t##*:}; SEED=$s|${t%%:*}${t##*:}_s$s"); done; done
i=0; for j in "${J[@]}"; do IFS='|' read n T t <<< "$j"; one "$n" "$T" "$t" & i=$((i+1)); [ $((i % 2)) = 0 ] && wait; done; wait
echo BX_DONE
