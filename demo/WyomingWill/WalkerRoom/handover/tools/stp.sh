#!/bin/bash
# Longer physics steps (30 October): 1/960 and 1/1920 s against the 1/3840 s runs (ft2/), 200 iterations, 4 builds,
# flat, waves 4, logs 7, seeds 1-2, 20 s. Timed. torqueprobe.lua.
cd /home/claude/bpp/demo/WyomingWill/WalkerRoom
mkdir -p /home/claude/work/stp
br() { case "$1" in Jansen|Klann|"Spears 4-bar") echo "XX=1";; *diag) echo "DIAG_OUTSIDE=true; PENDANT_HOLD=true";; *) echo "UNBRACED=true";; esac; }
one() { out=/home/claude/work/stp/$5.txt; grep -q '^TQ' $out 2>/dev/null && return; f=$(mktemp ./_st_XXXX.lua)
  printf 'v:setSolverInfo("residual", 0.01); SOLVER_ITERATIONS=200; MOTOR_STRENGTH=2; dofile("trotting-walkers.lua"); dofile("spears-lift-walkers.lua"); ONLY="%s"; %s; BUMP=15; GRAVITY=981; FIXED=%s; YAW_DAMP=1; ANKLE_SPRING={stiffness=42000, damping=4200}; LINK_WIDTH=1.0; GAIT={0,180,180,0}; %s; TQ_FROM=2; TQ_TO=20; dofile("/home/claude/work/torqueprobe.lua")\n' "$1" "$2" "$4" "$3" > $f
  s=$(date +%s.%N); QT_QPA_PLATFORM=offscreen timeout 900 /home/claude/build/release/bpp -f $(basename $f) -n 1210 2>&1 | grep -E "^(TQ|STALL|TRACK)|rror" | grep -v ALSA > $out.tmp; e=$(date +%s.%N)
  echo "TIME $(echo "$e - $s" | bc)" >> $out.tmp; mv $out.tmp $out; rm -f $f; }
J=()
for st in "1/960|960" "1/1920|1920"; do IFS='|' read fx fn <<< "$st"
  for s in 1 2; do for t in waves:0 waves:4 logs:7; do T="TERRAIN=\"${t%%:*}\"; AMP=${t##*:}; SEED=$s"; tg="${t%%:*}${t##*:}_s$s"; [ $t = waves:0 ] && tg="flat_s$s"
    for n in "Spears lift 44" "Chebyshev-Spears diag" "Hoecken-Spears slider diag" "Jansen"; do J+=("$n|$T|$(br "$n")|$fx|${n// /_}_${fn}_$tg"); done; done; done; done
i=0; for j in "${J[@]}"; do IFS='|' read n T x fx t <<< "$j"; one "$n" "$T" "$x" "$fx" "$t" & i=$((i+1)); [ $((i % 2)) = 0 ] && wait; done; wait
echo STP_DONE
