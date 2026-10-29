#!/bin/bash
# Hoecken-Spears slider diag tweaks (29 October): upturned toes (FOOT_TIPS 1.5 cm at 30 degrees) and softer ankle
# springs (x0.5, x0.25), logs 7, seeds 1-3, 20 s; footprobe.lua.
cd /home/claude/bpp/demo/WyomingWill/WalkerRoom
mkdir -p /home/claude/work/tw
one() { out=/home/claude/work/tw/$3.txt; f=$(mktemp ./_tw_XXXX.lua)
  printf 'v:setSolverInfo("residual", 0.01); SOLVER_ITERATIONS=200; MOTOR_STRENGTH=2; dofile("trotting-walkers.lua"); dofile("spears-lift-walkers.lua"); ONLY="Hoecken-Spears slider diag"; TERRAIN="logs"; AMP=7; SEED=%s; BUMP=15; GRAVITY=981; FIXED=1/3840; YAW_DAMP=1; ANKLE_SPRING={stiffness=42000, damping=4200}; LINK_WIDTH=1.0; GAIT={0,180,180,0}; DIAG_OUTSIDE=true; PENDANT_HOLD=true; %s; FP_FROM=2; FP_TO=20; dofile("/home/claude/work/footprobe.lua")\n' "$1" "$2" > $f
  QT_QPA_PLATFORM=offscreen timeout 900 /home/claude/build/release/bpp -f $(basename $f) -n 1210 2>&1 | grep -aE "^(FP|STALL)|rror" | grep -v ALSA > $out; rm -f $f; }
J=()
for s in 1 2 3; do
  J+=("$s|FOOT_TIPS={length=1.5, angle=30}|tips_s$s" "$s|ANKLE_SPRING={stiffness=21000, damping=2100}|half_s$s" "$s|ANKLE_SPRING={stiffness=10500, damping=1050}|quarter_s$s"); done
i=0; for j in "${J[@]}"; do IFS='|' read s x t <<< "$j"; one "$s" "$x" "$t" & i=$((i+1)); [ $((i % 2)) = 0 ] && wait; done; wait
echo TW_DONE
