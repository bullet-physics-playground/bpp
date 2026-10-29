#!/bin/bash
# Hoecken-Spears slider diag with stiffer ankle springs (x2, x4), logs 7, seeds 1-3, 20 s; footprobe.lua.
cd /home/claude/bpp/demo/WyomingWill/WalkerRoom
mkdir -p /home/claude/work/ank
one() { out=/home/claude/work/ank/$3.txt; f=$(mktemp ./_ak_XXXX.lua)
  printf 'v:setSolverInfo("residual", 0.01); SOLVER_ITERATIONS=200; MOTOR_STRENGTH=2; dofile("trotting-walkers.lua"); dofile("spears-lift-walkers.lua"); ONLY="Hoecken-Spears slider diag"; TERRAIN="logs"; AMP=7; SEED=%s; BUMP=15; GRAVITY=981; FIXED=1/3840; YAW_DAMP=1; ANKLE_SPRING=%s; LINK_WIDTH=1.0; GAIT={0,180,180,0}; DIAG_OUTSIDE=true; PENDANT_HOLD=true; FP_FROM=2; FP_TO=20; dofile("/home/claude/work/footprobe.lua")\n' "$1" "$2" > $f
  QT_QPA_PLATFORM=offscreen timeout 900 /home/claude/build/release/bpp -f $(basename $f) -n 1210 2>&1 | grep -aE "^(FP|STALL)|rror" | grep -v ALSA > $out; rm -f $f; }
for s in 1 2 3; do one $s "{stiffness=84000, damping=8400}" x2_s$s & one $s "{stiffness=168000, damping=16800}" x4_s$s; wait; done
echo ANK_DONE
