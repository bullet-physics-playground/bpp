#!/bin/bash
# The overnight run (29 October): seeds 4-5 for the top builds (seeds 1-3 are in ft2/), the nine rough terrains, and
# the Hoecken-Spears slider guides build with its toes (seeds 1-5), and toe versions of four builds that leaned toward
# them (seeds 1-5; logs 7 and steps 7 seeds 1-3 are in toes/). 20 s, the ft2 standard. Resumable: n5/<build>[_toes]_<terrain>_s<seed>.txt
cd /home/claude/bpp/demo/WyomingWill/WalkerRoom
mkdir -p /home/claude/work/n5
one() { out=/home/claude/work/n5/$4.txt; grep -q '^\(TQ\|HUNG\)' $out 2>/dev/null && return; f=$(mktemp ./_n5_XXXX.lua)
  printf 'v:setSolverInfo("residual", 0.01); SOLVER_ITERATIONS=200; MOTOR_STRENGTH=2; dofile("trotting-walkers.lua"); dofile("spears-lift-walkers.lua"); ONLY="%s"; %s; BUMP=15; GRAVITY=981; FIXED=1/3840; YAW_DAMP=1; ANKLE_SPRING={stiffness=42000, damping=4200}; LINK_WIDTH=1.0; GAIT={0,180,180,0}; %s; TQ_FROM=2; TQ_TO=20; dofile("/home/claude/work/torqueprobe.lua")\n' "$1" "$2" "$3" > $f
  QT_QPA_PLATFORM=offscreen timeout 900 /home/claude/build/release/bpp -f $(basename $f) -n 1210 > $out.raw 2>&1; rc=$?
  grep -E "^(TQ|STALL|TRACK)|rror" $out.raw | grep -v ALSA > $out.tmp; [ $rc = 124 ] && echo "HUNG over 900 s" >> $out.tmp; mv $out.tmp $out; rm -f $f $out.raw; }
br() { case "$1" in Jansen|Klann|"Spears 4-bar") echo "XX=1";; *diag) echo "DIAG_OUTSIDE=true; PENDANT_HOLD=true";; *) echo "UNBRACED=true";; esac; }
TER="waves:2 waves:4 waves:6 logs:3 logs:5 logs:7 steps:3 steps:5 steps:7"
TOP=("Chebyshev-Spears lift 51" "Chebyshev-Spears lift 51 diag" "Chebyshev-Spears lift 62" "Hoecken-Spears 4-bar diag" "Chebyshev-Spears lift 62 diag" "Chebyshev-Spears diag" "Hoecken-Spears 4-bar duty 85 diag" "Hoecken-Spears slider diag" "Hoecken-Spears 4-bar" "Jansen" "Klann" "Hoecken-Spears 4-bar duty 85")
LEAN=("Chebyshev-Spears lift 62 diag" "Hoecken-Spears 4-bar duty 85" "Jansen" "Chebyshev-Spears diag")
J=()
for s in 4 5; do for t in $TER; do T="TERRAIN=\"${t%%:*}\"; AMP=${t##*:}; SEED=$s"; tg="${t%%:*}${t##*:}_s$s"
  for n in "${TOP[@]}"; do J+=("$n|$T|$(br "$n")|${n// /_}_$tg"); done; done; done
for s in 1 2 3 4 5; do for t in $TER; do T="TERRAIN=\"${t%%:*}\"; AMP=${t##*:}; SEED=$s"; tg="${t%%:*}${t##*:}_s$s"
  J+=("Hoecken-Spears slider|$T|UNBRACED=true|Hoecken-Spears_slider_toes_$tg")
  for n in "${LEAN[@]}"; do
    if [ $s -le 3 ] && { [ ${t%%:*}${t##*:} = logs7 ] || [ ${t%%:*}${t##*:} = steps7 ]; }; then continue; fi
    J+=("$n|$T|$(br "$n"); FOOT_TIPS={length=1.0, angle=30}|${n// /_}_toes_$tg"); done; done; done
echo "jobs ${#J[@]}"
i=0; for j in "${J[@]}"; do IFS='|' read n T x t <<< "$j"; one "$n" "$T" "$x" "$t" & i=$((i+1)); [ $((i % 2)) = 0 ] && wait; done; wait
echo N5_DONE
