#!/bin/bash
# Upturned toes (FOOT_TIPS 1.0 cm at 30 degrees) on every build but the two sliders' diag builds (done: tips10/,
# hst/), logs 7 and steps 7, seeds 1-3, 20 s, the ft2 standard (29 October). Against ft2/'s flat feet.
cd /home/claude/bpp/demo/WyomingWill/WalkerRoom
mkdir -p /home/claude/work/toes
one() { out=/home/claude/work/toes/$4.txt; grep -q '^\(TQ\|HUNG\)' $out 2>/dev/null && return; f=$(mktemp ./_to_XXXX.lua)
  printf 'v:setSolverInfo("residual", 0.01); SOLVER_ITERATIONS=200; MOTOR_STRENGTH=2; dofile("trotting-walkers.lua"); dofile("spears-lift-walkers.lua"); ONLY="%s"; %s; BUMP=15; GRAVITY=981; FIXED=1/3840; YAW_DAMP=1; ANKLE_SPRING={stiffness=42000, damping=4200}; LINK_WIDTH=1.0; GAIT={0,180,180,0}; FOOT_TIPS={length=1.0, angle=30}; %s; TQ_FROM=2; TQ_TO=20; dofile("/home/claude/work/torqueprobe.lua")\n' "$1" "$2" "$3" > $f
  QT_QPA_PLATFORM=offscreen timeout 900 /home/claude/build/release/bpp -f $(basename $f) -n 1210 > $out.raw 2>&1; rc=$?
  grep -E "^(TQ|STALL|TRACK)|rror" $out.raw | grep -v ALSA > $out.tmp; [ $rc = 124 ] && echo "HUNG over 900 s" >> $out.tmp; mv $out.tmp $out; rm -f $f $out.raw; }
OWN=("Jansen" "Klann" "Spears 4-bar")
GUIDES=("Chebyshev" "Chebyshev-Spears" "Hoecken 4-bar" "Hoecken slider" "Hoecken-Spears slider" "Hoecken-Spears 4-bar" "Hoecken-Spears long-stance" "Spears lift 44" "Spears lift 53")
DIAG=("Chebyshev diag" "Chebyshev-Spears diag" "Hoecken 4-bar diag" "Hoecken-Spears 4-bar diag" "Hoecken-Spears long-stance diag" "Spears lift 44 diag" "Spears lift 53 diag")
J=()
for s in 1 2 3; do for t in logs:7 steps:7; do
  T="TERRAIN=\"${t%%:*}\"; AMP=${t##*:}; SEED=$s"; tg="${t%%:*}${t##*:}_s$s"
  for n in "${OWN[@]}"; do J+=("$n|$T|XX=1|${n// /_}_$tg"); done
  for n in "${GUIDES[@]}"; do J+=("$n|$T|UNBRACED=true|${n// /_}_$tg"); done
  for n in "${DIAG[@]}"; do J+=("$n|$T|DIAG_OUTSIDE=true; PENDANT_HOLD=true|${n// /_}_$tg"); done
done; done
echo "jobs ${#J[@]}"
i=0; for j in "${J[@]}"; do IFS='|' read n T x t <<< "$j"; one "$n" "$T" "$x" "$t" & i=$((i+1)); [ $((i % 2)) = 0 ] && wait; done; wait
echo TOES_DONE
