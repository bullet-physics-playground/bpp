#!/bin/bash
# Steps 7 seeds 1-2, Chebyshev-Spears and Hoecken-Spears slider, at SOLVER_ITERATIONS 1000 with residual 0.01 (sequential
# impulse, converged), to compare with the exact solver (dz/). Resumable.
cd /home/claude/bpp/demo/WyomingWill/WalkerRoom
one() { out=/home/claude/work/si1k/$3.txt; grep -q '^TRACK' $out 2>/dev/null && return; f=$(mktemp ./_s1k_XXXX.lua)
  printf 'v:setSolverInfo("residual", 0.01); SOLVER_ITERATIONS=1000; dofile("trotting-walkers.lua"); dofile("spears-lift-walkers.lua"); ONLY="%s"; BUMP=15; GRAVITY=981; FIXED=1/3840; YAW_DAMP=1; ANKLE_SPRING={stiffness=42000, damping=4200}; LINK_WIDTH=1.0; GAIT={0,180,180,0}; UNBRACED=true; %s; dofile("/home/claude/work/stallprobe.lua")\n' "$1" "$2" > $f
  QT_QPA_PLATFORM=offscreen timeout 6000 /home/claude/build/release/bpp -f $(basename $f) -n 3700 2>&1 | grep -E "^(STALL|TRACK)|rror" | grep -v ALSA > $out.tmp && mv $out.tmp $out; rm -f $f; }
J=()
for s in 1 2; do for n in "Chebyshev-Spears" "Hoecken-Spears slider"; do J+=("$n|TERRAIN=\"steps\"; AMP=7; SEED=$s|${n// /_}_steps7_s$s"); done; done
i=0; for j in "${J[@]}"; do IFS='|' read n x t <<< "$j"; one "$n" "$x" "$t" & i=$((i+1)); [ $((i % 2)) = 0 ] && wait; done; wait
echo SI1K_DONE
