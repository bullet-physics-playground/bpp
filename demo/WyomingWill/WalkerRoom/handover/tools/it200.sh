#!/bin/bash
# Chebyshev-Spears and Hoecken-Spears slider (guides) at SOLVER_ITERATIONS 200 (else as the fresh table): steps 7 seeds
# 1-8, steps 5 seeds 1-4, waves 4 seeds 1-2. Resumable.
cd /home/claude/bpp/demo/WyomingWill/WalkerRoom
one() { out=/home/claude/work/it/$3.txt; grep -q '^TRACK' $out 2>/dev/null && return; f=$(mktemp ./_it_XXXX.lua)
  printf 'dofile("trotting-walkers.lua"); dofile("spears-lift-walkers.lua"); ONLY="%s"; %s; BUMP=15; GRAVITY=981; FIXED=1/3840; YAW_DAMP=1; ANKLE_SPRING={stiffness=42000, damping=4200}; LINK_WIDTH=1.0; GAIT={0,180,180,0}; UNBRACED=true; SOLVER_ITERATIONS=200\ndofile("/home/claude/work/stallprobe.lua")\n' "$1" "$2" > $f
  QT_QPA_PLATFORM=offscreen timeout 3000 /home/claude/build/release/bpp -f $(basename $f) -n 3700 2>&1 | grep -E "^(TRACK|STALL)|rror" | grep -v ALSA > $out.tmp && mv $out.tmp $out; rm -f $f; }
J=()
for t in steps:7:1 steps:7:2 steps:7:3 steps:7:4 steps:5:1 steps:5:2 waves:4:1 waves:4:2 steps:7:5 steps:7:6 steps:7:7 steps:7:8 steps:5:3 steps:5:4; do IFS=: read ter a s <<< "$t"
  for n in "Chebyshev-Spears" "Hoecken-Spears slider"; do J+=("$n|TERRAIN=\"$ter\"; AMP=$a; SEED=$s|${n// /_}_it200_${ter}${a}_s$s"); done; done
i=0; for j in "${J[@]}"; do IFS='|' read n T t <<< "$j"; one "$n" "$T" "$t" & i=$((i+1)); [ $((i % 2)) = 0 ] && wait; done; wait
echo IT200_DONE
