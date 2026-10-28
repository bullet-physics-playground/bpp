#!/bin/bash
# Steps 5, seeds 1-5: 4 walkers x friction on/off x 1000, 400, 200 iterations (FIXED 1/3840). 20 s, MOTOR_STRENGTH 2.
# Seed 1 copied from st4. Resumable: st5/<walker>_steps5_<fric>_<it>_3840_s<seed>.txt
cd /home/claude/bpp/demo/WyomingWill/WalkerRoom
one() { out=/home/claude/work/st5/$5.txt; grep -q '^TQ' $out 2>/dev/null && return; f=$(mktemp ./_s5_XXXX.lua)
  printf 'v:setSolverInfo("residual", 0.01); SOLVER_ITERATIONS=%s; MOTOR_STRENGTH=2; JOINT_FRICTION=%s; dofile("trotting-walkers.lua"); dofile("spears-lift-walkers.lua"); ONLY="%s"; TERRAIN="steps"; AMP=5; SEED=%s; BUMP=15; GRAVITY=981; FIXED=1/3840; YAW_DAMP=1; ANKLE_SPRING={stiffness=42000, damping=4200}; LINK_WIDTH=1.0; GAIT={0,180,180,0}; UNBRACED=true; TQ_FROM=2; TQ_TO=20; dofile("/home/claude/work/torqueprobe.lua")\n' "$4" "$3" "$1" "$2" > $f
  QT_QPA_PLATFORM=offscreen timeout 6000 /home/claude/build/release/bpp -f $(basename $f) -n 1210 2>&1 | grep -E "^(TQ|STALL|TRACK)|rror" | grep -v ALSA > $out.tmp && mv $out.tmp $out; rm -f $f; }
J=()
for it in 200 400 1000; do for seed in 2 3 4 5; do for n in "Chebyshev" "Chebyshev-Spears" "Hoecken slider" "Hoecken-Spears slider"; do
  for fr in "on|{mu=0.1, pin=0.25}" "off|false"; do IFS='|' read frn frv <<< "$fr"
    J+=("$n|$seed|$frv|$it|${n// /_}_steps5_${frn}_${it}_3840_s${seed}"); done; done; done; done
i=0; for j in "${J[@]}"; do IFS='|' read n s fr it tag <<< "$j"; one "$n" "$s" "$fr" "$it" "$tag" & i=$((i+1)); [ $((i % 2)) = 0 ] && wait; done; wait
echo ST5_DONE
