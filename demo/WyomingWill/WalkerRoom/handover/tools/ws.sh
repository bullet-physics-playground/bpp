#!/bin/bash
# Joint warm-starting ("si-warm", 30 October) against Bullet's solver: flat, seed 1, 20 s; speed, crank range, time.
cd /home/claude/bpp/demo/WyomingWill/WalkerRoom
mkdir -p /home/claude/work/ws
br() { case "$1" in Jansen|Klann|"Spears 4-bar") echo "XX=1";; *diag) echo "DIAG_OUTSIDE=true; PENDANT_HOLD=true";; *) echo "UNBRACED=true";; esac; }
one() { out=/home/claude/work/ws/$6.txt; grep -q '^TQ' $out 2>/dev/null && return; f=$(mktemp ./_ws_XXXX.lua)
  printf 'v:setSolver("%s"); v:setSolverInfo("residual", 0.01); SOLVER_ITERATIONS=%s; MOTOR_STRENGTH=2; dofile("trotting-walkers.lua"); dofile("spears-lift-walkers.lua"); ONLY="%s"; %s; BUMP=15; GRAVITY=981; FIXED=%s; YAW_DAMP=1; ANKLE_SPRING={stiffness=42000, damping=4200}; LINK_WIDTH=1.0; GAIT={0,180,180,0}; %s; TQ_FROM=2; TQ_TO=20; dofile("/home/claude/work/torqueprobe.lua")\n' "$1" "$2" "$3" "$7" "$4" "$5" > $f
  s=$(date +%s.%N); QT_QPA_PLATFORM=offscreen timeout 900 /home/claude/build/release/bpp -f $(basename $f) -n 1210 2>&1 | grep -E "^(TQ|STALL|TRACK)|rror" | grep -v ALSA > $out.tmp; e=$(date +%s.%N)
  echo "TIME $(echo "$e - $s" | bc)" >> $out.tmp; mv $out.tmp $out; rm -f $f; }
J=()
for c in "si|200|1/3840" "si|40|1/3840" "si-warm|40|1/3840" "si-warm|100|1/3840" "si|40|1/1920" "si-warm|40|1/1920" "si-warm|100|1/1920"; do IFS='|' read k it fx <<< "$c"
  for n in "Chebyshev-Spears diag" "Spears lift 44" "Jansen"; do J+=("$k|$it|$n|$fx|$(br "$n")|${n// /_}_${k}_${it}_${fx#1/}|TERRAIN=\"waves\"; AMP=0; SEED=1"); done; done
i=0; for j in "${J[@]}"; do IFS='|' read k it n fx x t T <<< "$j"; one "$k" "$it" "$n" "$fx" "$x" "$t" "$T" & i=$((i+1)); [ $((i % 2)) = 0 ] && wait; done; wait
echo WS_DONE
