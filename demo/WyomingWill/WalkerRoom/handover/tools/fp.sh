#!/bin/bash
# Back feet meeting the logs' sides: Chebyshev-Spears diag and Hoecken-Spears slider diag, logs 7, seeds 1-3, 20 s.
cd /home/claude/bpp/demo/WyomingWill/WalkerRoom
mkdir -p /home/claude/work/fp
one() { out=/home/claude/work/fp/$3.txt; f=$(mktemp ./_fp_XXXX.lua)
  printf 'v:setSolverInfo("residual", 0.01); SOLVER_ITERATIONS=200; MOTOR_STRENGTH=2; dofile("trotting-walkers.lua"); dofile("spears-lift-walkers.lua"); ONLY="%s"; %s; BUMP=15; GRAVITY=981; FIXED=1/3840; YAW_DAMP=1; ANKLE_SPRING={stiffness=42000, damping=4200}; LINK_WIDTH=1.0; GAIT={0,180,180,0}; DIAG_OUTSIDE=true; PENDANT_HOLD=true; FP_FROM=2; FP_TO=20; dofile("/home/claude/work/footprobe.lua")\n' "$1" "$2" > $f
  QT_QPA_PLATFORM=offscreen timeout 900 /home/claude/build/release/bpp -f $(basename $f) -n 1210 2>&1 | grep -aE "^(FP|STALL)|rror" | grep -v ALSA > $out; rm -f $f; }
for s in 1 2 3; do one "Chebyshev-Spears diag" "TERRAIN=\"logs\"; AMP=7; SEED=$s" CS_s$s & one "Hoecken-Spears slider diag" "TERRAIN=\"logs\"; AMP=7; SEED=$s" HS_s$s; wait; done
echo FP_DONE
