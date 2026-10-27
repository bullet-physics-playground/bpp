#!/bin/bash
# Slider tests (William, 27 October): Hoecken-Spears slider, Hoecken slider and Chebyshev-Spears (guides), as in the
# fresh table (trot, forward, Earth standard, 1.0 cm links, 8 m track, 60 s, bump 15), against: 200 solver iterations,
# the slider joint as a generic 6-dof joint, the slider bar at half mass, the links' own damping off (slidertest.lua).
# Flat seed 1, waves 4 seeds 1-2. Resumable.
cd /home/claude/bpp/demo/WyomingWill/WalkerRoom
one() { out=/home/claude/work/slt/$4.txt; grep -q '^TRACK' $out 2>/dev/null && return; f=$(mktemp ./_sl_XXXX.lua)
  printf 'dofile("trotting-walkers.lua"); dofile("spears-lift-walkers.lua"); ONLY="%s"; %s; BUMP=15; GRAVITY=981; FIXED=1/3840; YAW_DAMP=1; ANKLE_SPRING={stiffness=42000, damping=4200}; LINK_WIDTH=1.0; GAIT={0,180,180,0}; UNBRACED=true; VIB_BASE="/home/claude/work/slidertest.lua"; %s\ndofile("/home/claude/work/vibprobe.lua")\n' "$1" "$2" "$3" > $f
  QT_QPA_PLATFORM=offscreen timeout 1500 /home/claude/build/release/bpp -f $(basename $f) -n 3700 2>&1 | grep -E "^(TRACK|STALL|CONTACTS|VIB |SLIDER)|rror" | grep -v ALSA > $out.tmp && mv $out.tmp $out; rm -f $f; }
J=()
for t in flat:0:1 waves:4:1 waves:4:2; do IFS=: read ter a s <<< "$t"; T="TERRAIN=\"waves\"; AMP=$a; SEED=$s"; tg="${ter}_s$s"; [ $ter = waves ] && tg="waves4_s$s"
  for c in base:"" it200:"SOLVER_ITERATIONS=200" 6dof:"SL_6DOF=true" barhalf:"SL_BAR_HALF=true" nodamp:"SL_NODAMP=true"; do J+=("Hoecken-Spears slider|$T|${c#*:}|HSS_${c%%:*}_$tg"); done
  for c in base:"" it200:"SOLVER_ITERATIONS=200" 6dof:"SL_6DOF=true" nodamp:"SL_NODAMP=true"; do J+=("Hoecken slider|$T|${c#*:}|HS_${c%%:*}_$tg"); done
  for c in base:"" it200:"SOLVER_ITERATIONS=200"; do J+=("Chebyshev-Spears|$T|${c#*:}|CS_${c%%:*}_$tg"); done
done
echo "jobs ${#J[@]}"
i=0; for j in "${J[@]}"; do IFS='|' read n T x t <<< "$j"; one "$n" "$T" "$x" "$t" & i=$((i+1)); [ $((i % 2)) = 0 ] && wait; done; wait
echo SLT_DONE
