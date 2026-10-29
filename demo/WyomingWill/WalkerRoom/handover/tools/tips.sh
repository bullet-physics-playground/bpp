#!/bin/bash
# Upturned toes (FOOT_TIPS 1.5 cm at 30 degrees): Hoecken-Spears slider diag on all 10 terrains, and Chebyshev-Spears
# diag on logs 7 and steps 7; seeds 1-3, 20 s, the ft2 standard (29 October). torqueprobe.lua.
cd /home/claude/bpp/demo/WyomingWill/WalkerRoom
mkdir -p /home/claude/work/tips
one() { out=/home/claude/work/tips/$4.txt; grep -q '^TQ' $out 2>/dev/null && return; f=$(mktemp ./_tp_XXXX.lua)
  printf 'v:setSolverInfo("residual", 0.01); SOLVER_ITERATIONS=200; MOTOR_STRENGTH=2; dofile("trotting-walkers.lua"); dofile("spears-lift-walkers.lua"); ONLY="%s"; %s; BUMP=15; GRAVITY=981; FIXED=1/3840; YAW_DAMP=1; ANKLE_SPRING={stiffness=42000, damping=4200}; LINK_WIDTH=1.0; GAIT={0,180,180,0}; DIAG_OUTSIDE=true; PENDANT_HOLD=true; FOOT_TIPS={length=1.5, angle=30}; %s; TQ_FROM=2; TQ_TO=20; dofile("/home/claude/work/torqueprobe.lua")\n' "$1" "$2" "$3" > $f
  QT_QPA_PLATFORM=offscreen timeout 900 /home/claude/build/release/bpp -f $(basename $f) -n 1210 2>&1 | grep -E "^(TQ|STALL|TRACK)|rror" | grep -v ALSA > $out; rm -f $f; }
J=()
for s in 1 2 3; do
  for t in waves:0 waves:2 waves:4 waves:6 logs:3 logs:5 logs:7 steps:3 steps:5 steps:7; do
    T="TERRAIN=\"${t%%:*}\"; AMP=${t##*:}; SEED=$s"; tg="${t%%:*}${t##*:}_s$s"; [ $t = waves:0 ] && tg="flat_s$s"
    J+=("Hoecken-Spears slider diag|$T|XX=1|HSsd_$tg"); done
  for t in logs:7 steps:7; do J+=("Chebyshev-Spears diag|TERRAIN=\"${t%%:*}\"; AMP=${t##*:}; SEED=$s|XX=1|CSd_${t%%:*}${t##*:}_s$s"); done
done
i=0; for j in "${J[@]}"; do IFS='|' read n T x t <<< "$j"; one "$n" "$T" "$x" "$t" & i=$((i+1)); [ $((i % 2)) = 0 ] && wait; done; wait
echo TIPS_DONE
