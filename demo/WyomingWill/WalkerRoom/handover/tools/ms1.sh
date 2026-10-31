#!/bin/bash
# MOTOR_STRENGTH 2 (0.5 nominal, 0.25 in effect: the hinge motors reach half their set torque; x weight x stride per crank) with joint friction (mu 0.1, pin 0.25 cm), 1000 iterations
# (early stop at residual 0.01): every run build on flat, 20 s, seed 1 (speed check), plus Chebyshev-Spears on steps 5
# (where the cap bites). torqueprobe.lua. Resumable.
cd /home/claude/bpp/demo/WyomingWill/WalkerRoom
one() { out=/home/claude/work/ms1/$4.txt; grep -q '^TQ' $out 2>/dev/null && return; f=$(mktemp ./_m1_XXXX.lua)
  printf 'v:setSolverInfo("residual", 0.01); SOLVER_ITERATIONS=1000; MOTOR_STRENGTH=2; JOINT_FRICTION={mu=0.1, pin=0.25}; dofile("trotting-walkers.lua"); dofile("spears-lift-walkers.lua"); ONLY="%s"; %s; BUMP=15; GRAVITY=981; FIXED=1/3840; YAW_DAMP=1; ANKLE_SPRING={stiffness=42000, damping=4200}; LINK_WIDTH=1.0; GAIT={0,180,180,0}; %s; TQ_FROM=2; TQ_TO=20; dofile("/home/claude/work/torqueprobe.lua")\n' "$1" "$2" "$3" > $f
  QT_QPA_PLATFORM=offscreen timeout 6000 /home/claude/build/release/bpp -f $(basename $f) -n 1210 2>&1 | grep -E "^(TQ|STALL|TRACK)|rror" | grep -v ALSA > $out.tmp && mv $out.tmp $out; rm -f $f; }
J=("Chebyshev-Spears|TERRAIN=\"steps\"; AMP=5; SEED=1|UNBRACED=true|Chebyshev-Spears_steps5")
FLAT='TERRAIN="waves"; AMP=0; SEED=1'
for n in "Jansen" "Klann" "Spears 4-bar"; do J+=("$n|$FLAT|XX=1|${n// /_}_flat"); done
for n in "Chebyshev" "Chebyshev-Spears" "Hoecken 4-bar" "Hoecken slider" "Hoecken-Spears slider" "Hoecken-Spears 4-bar" "Hoecken-Spears 4-bar duty 85" "Chebyshev-Spears lift 51" "Chebyshev-Spears lift 62"; do J+=("$n|$FLAT|UNBRACED=true|${n// /_}_flat"); done
for n in "Chebyshev diag" "Chebyshev-Spears diag" "Hoecken 4-bar diag" "Hoecken-Spears 4-bar diag" "Hoecken-Spears 4-bar duty 85 diag" "Chebyshev-Spears lift 51 diag" "Chebyshev-Spears lift 62 diag"; do J+=("$n|$FLAT|DIAG_OUTSIDE=true; PENDANT_HOLD=true|${n// /_}_flat"); done
i=0; for j in "${J[@]}"; do IFS='|' read n T x t <<< "$j"; one "$n" "$T" "$x" "$t" & i=$((i+1)); [ $((i % 2)) = 0 ] && wait; done; wait
echo MS1_DONE
