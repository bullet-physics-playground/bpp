#!/bin/bash
# Shake check for the slider diag builds (28 October): diag and guides, flat and waves 4, seed 1, 20 s, the ft2 standard.
cd /home/claude/bpp/demo/WyomingWill/WalkerRoom
mkdir -p /home/claude/work/shk
one() { out=/home/claude/work/shk/$4.txt; f=$(mktemp ./_sh_XXXX.lua)
  printf 'v:setSolverInfo("residual", 0.01); SOLVER_ITERATIONS=200; MOTOR_STRENGTH=2; dofile("trotting-walkers.lua"); dofile("spears-lift-walkers.lua"); ONLY="%s"; %s; BUMP=15; GRAVITY=981; FIXED=1/3840; YAW_DAMP=1; ANKLE_SPRING={stiffness=42000, damping=4200}; LINK_WIDTH=1.0; GAIT={0,180,180,0}; %s; TQ_FROM=2; TQ_TO=20; VIB_END=1200; VIB_BASE="/home/claude/work/torqueprobe.lua"\ndofile("/home/claude/work/vibprobe20.lua")\n' "$1" "$2" "$3" > $f
  QT_QPA_PLATFORM=offscreen timeout 1500 /home/claude/build/release/bpp -f $(basename $f) -n 1210 2>&1 | grep -E "^(TQ|STALL|VIB|CONTACTS)|rror" | grep -v ALSA > $out; rm -f $f; }
for t in 'flat|TERRAIN="waves"; AMP=0; SEED=1' 'waves4|TERRAIN="waves"; AMP=4; SEED=1'; do IFS='|' read tn tv <<< "$t"
  one "Hoecken slider diag" "$tv" "DIAG_OUTSIDE=true; PENDANT_HOLD=true" Hoecken_slider_diag_$tn & one "Hoecken-Spears slider diag" "$tv" "DIAG_OUTSIDE=true; PENDANT_HOLD=true" Hoecken-Spears_slider_diag_$tn; wait
  one "Hoecken slider" "$tv" "UNBRACED=true" Hoecken_slider_$tn & one "Hoecken-Spears slider" "$tv" "UNBRACED=true" Hoecken-Spears_slider_$tn; wait
done; echo SHK_DONE
