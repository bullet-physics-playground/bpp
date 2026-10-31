#!/bin/bash
# si-warm on rough ground (30 October): 40 iterations at 1/3840 and at 1/1920 s, against the ranking's runs (si, 200,
# 1/3840): 4 builds, waves 4, logs 7, steps 7, seeds 1-3, 20 s.
cd /home/claude/bpp/demo/WyomingWill/WalkerRoom
mkdir -p /home/claude/work/wsr
br() { case "$1" in Jansen|Klann|"Spears 4-bar") echo "XX=1";; *diag) echo "DIAG_OUTSIDE=true; PENDANT_HOLD=true";; *) echo "UNBRACED=true";; esac; }
one() { out=/home/claude/work/wsr/$6.txt; grep -q '^TQ' $out 2>/dev/null && return; f=$(mktemp ./_wr_XXXX.lua)
  printf 'v:setSolver("%s"); v:setSolverInfo("residual", 0.01); SOLVER_ITERATIONS=%s; MOTOR_STRENGTH=2; dofile("trotting-walkers.lua"); dofile("spears-lift-walkers.lua"); ONLY="%s"; %s; BUMP=15; GRAVITY=981; FIXED=%s; YAW_DAMP=1; ANKLE_SPRING={stiffness=42000, damping=4200}; LINK_WIDTH=1.0; GAIT={0,180,180,0}; %s; TQ_FROM=2; TQ_TO=20; dofile("/home/claude/work/torqueprobe.lua")\n' "$1" "$2" "$3" "$7" "$4" "$5" > $f
  QT_QPA_PLATFORM=offscreen timeout 900 /home/claude/build/release/bpp -f $(basename $f) -n 1210 2>&1 | grep -E "^(TQ|STALL|TRACK)|rror" | grep -v ALSA > $out.tmp; mv $out.tmp $out; rm -f $f; }
J=()
for c in "si-warm|40|1/3840" "si-warm|40|1/1920"; do IFS='|' read k it fx <<< "$c"
  for s in 1 2 3; do for t in waves:4 logs:7 steps:7; do T="TERRAIN=\"${t%%:*}\"; AMP=${t##*:}; SEED=$s"; tg="${t%%:*}${t##*:}_s$s"
    for n in "Chebyshev-Spears lift 51" "Chebyshev-Spears diag" "Hoecken-Spears slider diag" "Jansen"; do J+=("$k|$it|$n|$fx|$(br "$n")|${n// /_}_${fx#1/}_${tg}|$T"); done; done; done; done
i=0; for j in "${J[@]}"; do IFS='|' read k it n fx x t T <<< "$j"; one "$k" "$it" "$n" "$fx" "$x" "$t" "$T" & i=$((i+1)); [ $((i % 2)) = 0 ] && wait; done; wait
echo WSR_DONE
