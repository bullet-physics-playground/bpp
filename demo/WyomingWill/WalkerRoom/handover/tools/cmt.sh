#!/bin/bash
# CoM test (28 October): Hoecken-Spears slider diag with its body's load 2.66 cm lower (BODY_LOAD), so its CoM is as
# high over its feet as Chebyshev-Spears diag's (11.29 cm); logs 7 and steps 7, seeds 1-3, the ft2 standard.
cd /home/claude/bpp/demo/WyomingWill/WalkerRoom
mkdir -p /home/claude/work/cmt
one() { out=/home/claude/work/cmt/$4.txt; grep -q '^TQ' $out 2>/dev/null && return; f=$(mktemp ./_cmt_XXXX.lua)
  printf 'v:setSolverInfo("residual", 0.01); SOLVER_ITERATIONS=200; MOTOR_STRENGTH=2; dofile("trotting-walkers.lua"); dofile("spears-lift-walkers.lua"); ONLY="%s"; %s; BUMP=15; GRAVITY=981; FIXED=1/3840; YAW_DAMP=1; ANKLE_SPRING={stiffness=42000, damping=4200}; LINK_WIDTH=1.0; GAIT={0,180,180,0}; %s; TQ_FROM=2; TQ_TO=20; dofile("/home/claude/work/torqueprobe.lua")\n' "$1" "$2" "$3" > $f
  QT_QPA_PLATFORM=offscreen timeout 900 /home/claude/build/release/bpp -f $(basename $f) -n 1210 2>&1 | grep -E "^(TQ|STALL|TRACK)|rror" | grep -v ALSA > $out; rm -f $f; }
J=()
for s in 1 2 3; do for t in logs:7 steps:7; do
  J+=("Hoecken-Spears slider diag|TERRAIN=\"${t%%:*}\"; AMP=${t##*:}; SEED=$s|DIAG_OUTSIDE=true; PENDANT_HOLD=true; BODY_LOAD={dy=-2.66}|HSsd_low_${t%%:*}${t##*:}_s$s"); done; done
i=0; for j in "${J[@]}"; do IFS='|' read n T x t <<< "$j"; one "$n" "$T" "$x" "$t" & i=$((i+1)); [ $((i % 2)) = 0 ] && wait; done; wait
echo CMT_DONE
