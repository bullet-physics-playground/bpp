#!/bin/bash
cd /home/claude/bpp/demo/WyomingWill/WalkerRoom
one() { f=$(mktemp ./_rv_XXXX.lua)
  printf 'v:setSolverInfo("residual", 0.01); SOLVER_ITERATIONS=1000; MOTOR_STRENGTH=2; JOINT_FRICTION={mu=0.1, pin=0.25}; dofile("trotting-walkers.lua"); dofile("spears-lift-walkers.lua"); ONLY="%s"; TERRAIN="waves"; AMP=0; SEED=1; BUMP=15; GRAVITY=981; FIXED=1/3840; YAW_DAMP=1; ANKLE_SPRING={stiffness=42000, damping=4200}; LINK_WIDTH=1.0; GAIT={0,180,180,0}; %s; RV_FROM=2; RV_TO=20; RV_OUT="/home/claude/work/rv/%s.txt"; dofile("/home/claude/work/revprobe.lua")\n' "$1" "$2" "$3" > $f
  QT_QPA_PLATFORM=offscreen timeout 3000 /home/claude/build/release/bpp -f $(basename $f) -n 1210 2>&1 | grep -E "rror" | grep -v ALSA; rm -f $f; }
mkdir -p /home/claude/work/rv
one "Klann" "XX=1" Klann & one "Spears 4-bar" "XX=1" Spears4 & one "Jansen" "XX=1" Jansen & wait; echo RV_DONE
