#!/bin/bash
# Is Chebyshev-Spears diag less steady than Hoecken-Spears slider diag, and do its feet rise higher? Flat (seed 1) and
# logs 7 / steps 7 (seeds 1-3), 20 s, the ft2 standard. wobprobe.lua.
cd /home/claude/bpp/demo/WyomingWill/WalkerRoom
mkdir -p /home/claude/work/wob
one() { out=/home/claude/work/wob/$4.txt; grep -q '^WB' $out 2>/dev/null && return; f=$(mktemp ./_wb_XXXX.lua)
  printf 'v:setSolverInfo("residual", 0.01); SOLVER_ITERATIONS=200; MOTOR_STRENGTH=2; dofile("trotting-walkers.lua"); dofile("spears-lift-walkers.lua"); ONLY="%s"; %s; BUMP=15; GRAVITY=981; FIXED=1/3840; YAW_DAMP=1; ANKLE_SPRING={stiffness=42000, damping=4200}; LINK_WIDTH=1.0; GAIT={0,180,180,0}; %s; WB_FROM=3; WB_TO=20; dofile("/home/claude/work/wobprobe.lua")\n' "$1" "$2" "$3" > $f
  QT_QPA_PLATFORM=offscreen timeout 900 /home/claude/build/release/bpp -f $(basename $f) -n 1210 2>&1 | grep -E "^(WB|STALL)|rror" | grep -v ALSA > $out; rm -f $f; }
J=()
for t in "waves:0:1" "logs:7:1" "logs:7:2" "logs:7:3" "steps:7:1" "steps:7:2" "steps:7:3"; do IFS=: read tn a s <<< "$t"
  T="TERRAIN=\"$tn\"; AMP=$a; SEED=$s"; tg="$tn${a}_s$s"
  for n in "Chebyshev-Spears diag" "Hoecken-Spears slider diag"; do J+=("$n|$T|DIAG_OUTSIDE=true; PENDANT_HOLD=true|${n// /_}_$tg"); done; done
i=0; for j in "${J[@]}"; do IFS='|' read n T x t <<< "$j"; one "$n" "$T" "$x" "$t" & i=$((i+1)); [ $((i % 2)) = 0 ] && wait; done; wait
echo WOB_DONE
