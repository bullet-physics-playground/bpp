#!/bin/bash
# Test 1: both diag builds with braces that touch nothing, logs 7. Test 2: Chebyshev-Spears diag with its roll damped
# (angular factor 0.25 about the walk), logs 7 and steps 7. Seeds 1-3, 20 s, the ft2 standard.
cd /home/claude/bpp/demo/WyomingWill/WalkerRoom
mkdir -p /home/claude/work/t12
one() { out=/home/claude/work/t12/$4.txt; grep -q '^WB' $out 2>/dev/null && return; f=$(mktemp ./_t12_XXXX.lua)
  printf 'v:setSolverInfo("residual", 0.01); SOLVER_ITERATIONS=200; MOTOR_STRENGTH=2; dofile("trotting-walkers.lua"); dofile("spears-lift-walkers.lua"); ONLY="%s"; %s; BUMP=15; GRAVITY=981; FIXED=1/3840; YAW_DAMP=1; ANKLE_SPRING={stiffness=42000, damping=4200}; LINK_WIDTH=1.0; GAIT={0,180,180,0}; DIAG_OUTSIDE=true; PENDANT_HOLD=true; %s; WB_FROM=3; WB_TO=20; dofile("/home/claude/work/t12probe.lua")\n' "$1" "$2" "$3" > $f
  QT_QPA_PLATFORM=offscreen timeout 900 /home/claude/build/release/bpp -f $(basename $f) -n 1210 2>&1 | grep -aE "^(WB|STALL|GHOST|ROLL)|rror" | grep -v ALSA > $out; rm -f $f; }
J=()
for s in 1 2 3; do
  for t in logs:7 steps:7; do J+=("Chebyshev-Spears diag|TERRAIN=\"${t%%:*}\"; AMP=${t##*:}; SEED=$s|ROLL_DAMP=0.9|rd9_Chebyshev-Spears_diag_${t%%:*}${t##*:}_s$s"); done
done
i=0; for j in "${J[@]}"; do IFS='|' read n T x t <<< "$j"; one "$n" "$T" "$x" "$t" & i=$((i+1)); [ $((i % 2)) = 0 ] && wait; done; wait
echo T2B_DONE
