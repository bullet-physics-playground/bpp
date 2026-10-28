#!/bin/bash
# Step 4: which solver setting matches 1000 iterations. 4 walkers x (flat, steps 5) x (joint friction on, off) at
# 1000, 400, 200, 100, 40 iterations (FIXED 1/3840), and 1000 at FIXED 1/1920. 20 s, seed 1, MOTOR_STRENGTH 2 (0.25 in
# effect per crank). torqueprobe.lua. Resumable: st4/<walker>_<terrain>_<fric>_<it>_<fixed>.txt
cd /home/claude/bpp/demo/WyomingWill/WalkerRoom
one() { out=/home/claude/work/st4/$6.txt; grep -q '^TQ' $out 2>/dev/null && return; f=$(mktemp ./_s4_XXXX.lua)
  printf 'v:setSolverInfo("residual", 0.01); SOLVER_ITERATIONS=%s; MOTOR_STRENGTH=2; JOINT_FRICTION=%s; dofile("trotting-walkers.lua"); dofile("spears-lift-walkers.lua"); ONLY="%s"; %s; BUMP=15; GRAVITY=981; FIXED=%s; YAW_DAMP=1; ANKLE_SPRING={stiffness=42000, damping=4200}; LINK_WIDTH=1.0; GAIT={0,180,180,0}; UNBRACED=true; TQ_FROM=2; TQ_TO=20; dofile("/home/claude/work/torqueprobe.lua")\n' "$4" "$3" "$1" "$2" "$5" > $f
  QT_QPA_PLATFORM=offscreen timeout 6000 /home/claude/build/release/bpp -f $(basename $f) -n 1210 2>&1 | grep -E "^(TQ|STALL|TRACK)|rror" | grep -v ALSA > $out.tmp && mv $out.tmp $out; rm -f $f; }
mkdir -p /home/claude/work/st4
J=()
for s in "1000|1/3840|3840" "1000|1/1920|1920" "400|1/3840|3840" "200|1/3840|3840" "100|1/3840|3840" "40|1/3840|3840"; do IFS='|' read it fx fn <<< "$s"
  for n in "Chebyshev" "Chebyshev-Spears" "Hoecken slider" "Hoecken-Spears slider"; do
    for t in 'flat|TERRAIN="waves"; AMP=0; SEED=1' 'steps5|TERRAIN="steps"; AMP=5; SEED=1'; do IFS='|' read tn tv <<< "$t"
      for fr in "on|{mu=0.1, pin=0.25}" "off|false"; do IFS='|' read frn frv <<< "$fr"
        J+=("$n|$tv|$frv|$it|$fx|${n// /_}_${tn}_${frn}_${it}_${fn}"); done; done; done; done
i=0; for j in "${J[@]}"; do IFS='|' read n T fr it fx tag <<< "$j"; one "$n" "$T" "$fr" "$it" "$fx" "$tag" & i=$((i+1)); [ $((i % 2)) = 0 ] && wait; done; wait
echo ST4_DONE
