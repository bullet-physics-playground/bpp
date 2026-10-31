#!/bin/bash
# The fresh table again at the new standard (William, 28 October): all 19 run builds (own frames and guides at trot;
# diag with outside braces and held pendants), 200 solver iterations (early stop at residual 0.01), motor 0.25 per crank
# in effect (MOTOR_STRENGTH 2), no joint friction, LINK_WIDTH 1.0, forward, Earth standard, 8 m track, bump 15, normal
# ground; 20 s runs, speed from 5 to 20 s. Flat; waves 2/4/6; logs 3/5/7; steps 3/5/7; seeds 1-3 (seed by seed).
# torqueprobe over stallprobe. Resumable: ft2/<build>_<terrain>_s<seed>.txt
cd /home/claude/bpp/demo/WyomingWill/WalkerRoom
one() { out=/home/claude/work/ft2/$4.txt; grep -q '^\(TQ\|HUNG\)' $out 2>/dev/null && return; f=$(mktemp ./_ft2_XXXX.lua)
  printf 'v:setSolverInfo("residual", 0.01); SOLVER_ITERATIONS=200; MOTOR_STRENGTH=2; dofile("trotting-walkers.lua"); dofile("spears-lift-walkers.lua"); ONLY="%s"; %s; BUMP=15; GRAVITY=981; FIXED=1/3840; YAW_DAMP=1; ANKLE_SPRING={stiffness=42000, damping=4200}; LINK_WIDTH=1.0; GAIT={0,180,180,0}; %s; TQ_FROM=2; TQ_TO=20; dofile("/home/claude/work/torqueprobe.lua")\n' "$1" "$2" "$3" > $f
  QT_QPA_PLATFORM=offscreen timeout 900 /home/claude/build/release/bpp -f $(basename $f) -n 1210 > $out.raw 2>&1; rc=$?
  grep -E "^(TQ|STALL|TRACK)|rror" $out.raw | grep -v ALSA > $out.tmp; [ $rc = 124 ] && echo "HUNG over 900 s" >> $out.tmp; mv $out.tmp $out; rm -f $f $out.raw; }   # (a run over 15 min is stopped and marked)
mkdir -p /home/claude/work/ft2
OWN=("Jansen" "Klann" "Spears 4-bar")
GUIDES=("Chebyshev" "Chebyshev-Spears" "Hoecken 4-bar" "Hoecken slider" "Hoecken-Spears slider" "Hoecken-Spears 4-bar" "Hoecken-Spears 4-bar duty 85" "Chebyshev-Spears lift 51" "Chebyshev-Spears lift 62")
DIAG=("Chebyshev diag" "Chebyshev-Spears diag" "Hoecken 4-bar diag" "Hoecken-Spears 4-bar diag" "Hoecken-Spears 4-bar duty 85 diag" "Chebyshev-Spears lift 51 diag" "Chebyshev-Spears lift 62 diag")
J=()
for s in 1 2 3; do
  for t in waves:0 waves:2 waves:4 waves:6 logs:3 logs:5 logs:7 steps:3 steps:5 steps:7; do
    T="TERRAIN=\"${t%%:*}\"; AMP=${t##*:}; SEED=$s"; tg="${t%%:*}${t##*:}_s$s"; [ $t = waves:0 ] && tg="flat_s$s"
    for n in "${OWN[@]}"; do J+=("$n|$T|XX=1|${n// /_}_$tg"); done
    for n in "${GUIDES[@]}"; do J+=("$n|$T|UNBRACED=true|${n// /_}_$tg"); done
    for n in "${DIAG[@]}"; do J+=("$n|$T|DIAG_OUTSIDE=true; PENDANT_HOLD=true|${n// /_}_$tg"); done
  done; done
echo "jobs ${#J[@]}"
i=0; for j in "${J[@]}"; do IFS='|' read n T x t <<< "$j"; one "$n" "$T" "$x" "$t" & i=$((i+1)); [ $((i % 2)) = 0 ] && wait; done; wait
echo FT2_DONE
